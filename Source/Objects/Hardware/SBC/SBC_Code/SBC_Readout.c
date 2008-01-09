/*---------------------------------------------------------------------------
/    SBC_Readout.c
/
/    09/09/07 Mark A. Howe
/    CENPA, University of Washington. All rights reserved.
/    ORCA project
/  ---------------------------------------------------------------------------
*/
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/wait.h>
#include <signal.h>
#include "CircularBuffer.h"
#include <pthread.h>
#include "SBC_Readout.h"
#include "HW_Readout.h"

#define BACKLOG 1     // how many pending connections queue will hold
#ifndef TRUE
#define TRUE  1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#define kCBBufferSize 1024*1024*12

void* readoutThread (void* p);
void* irqAckThread (void* p);
char startRun (void);
void stopRun (void);
void sendRunInfo(void);
void sendCBRecord(void);


/*----globals----*/
char                timeToExit;
SBC_crate_config    crate_config;
SBC_info_struct     run_info;
SBC_LAM_info_struct lam_info[kMaxNumberLams];
time_t              lastTime;

pthread_t readoutThreadId;
pthread_t irqAckThreadId;
pthread_mutex_t runInfoMutex;
pthread_mutex_t lamInfoMutex;
int32_t  workingSocket;
int32_t  workingIRQSocket;
char needToSwap;
/*---------------*/

void sigchld_handler(int32_t s)
{
    while(waitpid(-1, NULL, WNOHANG) > 0);
}

int32_t main(int32_t argc, char *argv[])
{
    int32_t sockfd,irqfd;				// listen on sock_fd, new connection on workingSocket
    struct sockaddr_in my_addr;			// my address information
    struct sockaddr_in their_addr;		// connector's address information
    socklen_t sin_size;
    struct sigaction sa;
    int32_t yes=1;
    timeToExit = 0;
    
    if (argc != 2) {
        exit(1);
    }
    
    int32_t thePort = atoi(argv[1]);
    while(1){
        if ((sockfd = socket(PF_INET, SOCK_STREAM, 0)) == -1) exit(1);
        if ((irqfd  = socket(PF_INET, SOCK_STREAM, 0)) == -1) exit(1);
        
        if (setsockopt(sockfd,SOL_SOCKET,SO_REUSEADDR,&yes,sizeof(int)) == -1) exit(1);
        if (setsockopt(irqfd,SOL_SOCKET,SO_REUSEADDR,&yes,sizeof(int)) == -1)  exit(1);
        
        my_addr.sin_family = AF_INET;         // host byte order
        my_addr.sin_addr.s_addr = INADDR_ANY; // automatically fill with my IP
        memset(my_addr.sin_zero, '\0', sizeof my_addr.sin_zero);
        
        my_addr.sin_port = htons(thePort);     // short, network byte order
        if (bind(sockfd, (struct sockaddr *)&my_addr, sizeof(struct sockaddr))== -1) exit(1);

		my_addr.sin_port = htons(thePort+1);     // short, network byte order
		if (bind(irqfd, (struct sockaddr *)&my_addr, sizeof(struct sockaddr))== -1) exit(1);
        
        if (listen(sockfd, BACKLOG) == -1) exit(1);
        if (listen(irqfd, BACKLOG) == -1 )  exit(1);
        
        sa.sa_handler = sigchld_handler; // reap all dead processes
        sigemptyset(&sa.sa_mask);
        sa.sa_flags = SA_RESTART;
        if (sigaction(SIGCHLD, &sa, NULL) == -1) exit(1);

        FindHardware();
    
		//the order is important here... ORCA will connect with the regular socket first, -then- the irq socket
        sin_size = sizeof(struct sockaddr_in);
        if ((workingSocket    = accept(sockfd, (struct sockaddr *)&their_addr, &sin_size)) == -1) exit(1);
        if ((workingIRQSocket = accept(irqfd, (struct sockaddr *)&their_addr, &sin_size)) == -1) exit(1);
        
        //don't need this socket anymore
        close(sockfd);
        close(irqfd);
    
        //the first word sent is a test word to determine endian-ness
        int32_t testWord;
        needToSwap = FALSE;
        int32_t n = read(workingSocket,&testWord, 4);
        if(n == 0)    return 0 ; //disconnected -- exit
        if(testWord == 0xBADC0000)needToSwap = TRUE;
        //end of swap test

        //Note that we don't fork, only one connection is allowed.
        /*-------------------------------*/
        /*initialize our global variables*/
        pthread_mutex_init(&runInfoMutex, NULL);
        pthread_mutex_lock (&runInfoMutex);  //begin critical section
        run_info.statusBits        &= ~kSBC_ConfigLoadedMask; //clr bit
        run_info.statusBits        &= ~kSBC_RunningMask;        //clr bit
        run_info.readCycles        = 0;
        pthread_mutex_unlock (&runInfoMutex);//end critical section
		
		pthread_mutex_init(&lamInfoMutex, NULL);
        pthread_mutex_lock (&lamInfoMutex);  //begin critical section
		memset(&lam_info ,0,sizeof(SBC_LAM_info_struct)*kMaxNumberLams);
		pthread_mutex_unlock (&lamInfoMutex);//end critical section
       /*-------------------------------*/
		
        SBC_Packet aPacket;
        while(!timeToExit){
            if(readBuffer(&aPacket) == 0)break;
            processBuffer(&aPacket);
        }
        
        close(workingSocket);
        CB_cleanup();
        pthread_mutex_destroy(&runInfoMutex);

        ReleaseHardware();
        if(timeToExit)break;    
    }
    
    
    return 0;
} 

void processBuffer(SBC_Packet* aPacket)
{
    /*look at the first word to get the destination*/
    int32_t destination = aPacket->cmdHeader.destination;

    switch(destination){
        case kSBC_Process:   processSBCCommand(aPacket);             break;
        default:             processHWCommand(aPacket); break;
    }
}

void processSBCCommand(SBC_Packet* aPacket)
{
    switch(aPacket->cmdHeader.cmdID){
        case kSBC_WriteBlock:        
        case kSBC_VmeWriteBlock:
            pthread_mutex_lock (&runInfoMutex);                            //begin critical section
            doWriteBlock(aPacket); 
            pthread_mutex_unlock (&runInfoMutex);                        //end critical section
        break;
        
        case kSBC_ReadBlock:
        case kSBC_VmeReadBlock:        
            pthread_mutex_lock (&runInfoMutex);                            //begin critical section
            doReadBlock(aPacket);  
            pthread_mutex_unlock (&runInfoMutex);                        //end critical section
        break;
            
        case kSBC_LoadConfig:
            if(needToSwap)SwapLongBlock(aPacket->payload,sizeof(SBC_crate_config)/sizeof(int32_t));
            memcpy(&crate_config, aPacket->payload, sizeof(SBC_crate_config));
            run_info.statusBits    |= kSBC_ConfigLoadedMask;
        break;
                    
        case kSBC_StartRun:           
            doRunCommand(aPacket); 
		break;
			
        case kSBC_StopRun:            
            doRunCommand(aPacket); 
		break;
    
        case kSBC_RunInfoRequest:    
            sendRunInfo(); 
		break;
		
        case kSBC_CBRead:            
            sendCBRecord(); 
		break;
			
        case kSBC_Exit:              
            timeToExit = 1; 
		break;
    }
}

void doRunCommand(SBC_Packet* aPacket)
{
    //future options will be decoded here, are not any so far so the code is commented out
    //SBC_CmdOptionStruct* p = (SBC_CmdOptionStruct*)aPacket->payload;
    //if(needToSwap)SwapLongBlock(p,sizeof(SBC_CmdOptionStruct)/sizeof(int32_t));
    // option1 = p->option[0];
    // option2 = p->option[1];
    //....

    int32_t result = 0;
    if(aPacket->cmdHeader.cmdID == kSBC_StartRun)  result = startRun();
    else if(aPacket->cmdHeader.cmdID == kSBC_StopRun) stopRun();

    SBC_CmdOptionStruct* op = (SBC_CmdOptionStruct*)aPacket->payload;
    op->option[0] = result;
//    if(needToSwap)SwapLongBlock(op,sizeof(SBC_CmdOptionStruct)/sizeof(int32_t));
    sendResponse(aPacket);
}


void sendResponse(SBC_Packet* aPacket)
{
    aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_CmdOptionStruct);
    
    SBC_CmdOptionStruct* p = (SBC_CmdOptionStruct*)aPacket->payload;        
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_CmdOptionStruct)/sizeof(int32_t));
    writeBuffer(aPacket);
}

void sendRunInfo(void)
{
    SBC_Packet aPacket;
    aPacket.cmdHeader.destination		= kSBC_Process;
    aPacket.cmdHeader.cmdID				= kSBC_RunInfoRequest;
    aPacket.cmdHeader.numberBytesinPayload    = sizeof(SBC_info_struct);
    
    SBC_info_struct* runInfoPtr = (SBC_info_struct*)aPacket.payload;

    pthread_mutex_lock (&runInfoMutex);                        //begin critical section
    memcpy(runInfoPtr, &run_info, sizeof(SBC_info_struct));    //make copy
    pthread_mutex_unlock (&runInfoMutex);                     //end critical section

    BufferInfo cbInfo;
    CB_getBufferInfo(&cbInfo);
    runInfoPtr->readIndex      = cbInfo.readIndex;
    runInfoPtr->writeIndex     = cbInfo.writeIndex;
    runInfoPtr->lostByteCount  = cbInfo.lostByteCount;
    runInfoPtr->amountInBuffer = cbInfo.amountInBuffer;
    runInfoPtr->wrapArounds    = cbInfo.wrapArounds;
            
    if(needToSwap)SwapLongBlock(runInfoPtr,kSBC_NumRunInfoValuesToSwap);
    writeBuffer(&aPacket);
}

void sendCBRecord(void)
{
    //create an empty packet
    SBC_Packet aPacket;
    aPacket.cmdHeader.destination = kSBC_Process;
    aPacket.cmdHeader.cmdID       = kSBC_CBBlock;
    aPacket.message[0] = '\0';
    aPacket.cmdHeader.numberBytesinPayload    = 0;

    //point to the payload
    int32_t* dataPtr = (int32_t*)aPacket.payload;    
    
    int32_t recordCount = 0;
    //put data from the circular buffer into the payload until either, 1)the payload is full, or 2)the CB is empty.
    do {
        int32_t nextBlockSize = CB_nextBlockSize();
        if(nextBlockSize == 0)break;
        if((aPacket.cmdHeader.numberBytesinPayload + nextBlockSize*sizeof(int32_t)) < (kSBC_MaxPayloadSize-32)){
            int32_t maxToRead        = (kSBC_MaxPayloadSize - aPacket.cmdHeader.numberBytesinPayload)/sizeof(int32_t);
            if(!CB_readNextDataBlock(dataPtr,maxToRead)) break;
            aPacket.cmdHeader.numberBytesinPayload    += nextBlockSize*sizeof(int32_t);
            dataPtr += nextBlockSize;
            recordCount++;
        }
        else break;
    } while (1);
    
    pthread_mutex_lock (&runInfoMutex);  //begin critical section
    run_info.recordsTransfered        += recordCount;
    pthread_mutex_unlock (&runInfoMutex);  //end critical section

    writeBuffer(&aPacket);
}

int32_t readBuffer(SBC_Packet* aPacket)
{ 
    int32_t numberBytesinPacket;
    int32_t bytesRead = read(workingSocket, &numberBytesinPacket, sizeof(int32_t));
    if(bytesRead==0)return 0; //disconnected
    if(needToSwap)SwapLongBlock(&numberBytesinPacket,1);    
    aPacket->numBytes = numberBytesinPacket;
    numberBytesinPacket-= sizeof(int32_t);
    int32_t returnValue        = numberBytesinPacket;
    char* p = (char*)&aPacket->cmdHeader;
    while(numberBytesinPacket){
        bytesRead = read(workingSocket, p, numberBytesinPacket);
        if(bytesRead == 0) return 0;    //connection disconnected.
        p += bytesRead;
        numberBytesinPacket -= bytesRead;
    }
    aPacket->message[0] = '\0';
    if(needToSwap){
        //only swap the size and the header struct
        //the payload will be swapped by the user routines as needed.
        SwapLongBlock((int32_t*)&(aPacket->cmdHeader),sizeof(SBC_CommandHeader)/sizeof(int32_t));
    }

    return returnValue;
}

int32_t writeBuffer(SBC_Packet* aPacket)
{ 
    if(!workingSocket)return 0;
    aPacket->numBytes =  sizeof(int32_t) + sizeof(SBC_CommandHeader) + kSBC_MaxMessageSize + aPacket->cmdHeader.numberBytesinPayload; 
    int32_t numBytesToSend = aPacket->numBytes; 
    if(needToSwap)SwapLongBlock(aPacket,sizeof(SBC_CommandHeader)/sizeof(int32_t)+1);
    char* p = (char*)aPacket;
    while (numBytesToSend) {       
        int32_t bytesWritten = write(workingSocket,p,numBytesToSend);
        if (bytesWritten > 0) {
            p += bytesWritten;
            numBytesToSend -= bytesWritten;
        }
        else break;
    }
    return numBytesToSend;
}


int32_t writeIRQ(int n)
{ 
    if(!workingIRQSocket)        return 0;
	if(n<0 || n>=kMaxNumberLams) return 0;
	
	SBC_Packet* aPacket = &lam_info[n].lam_Packet;
    aPacket->numBytes =  sizeof(int32_t) + sizeof(SBC_CommandHeader) + kSBC_MaxMessageSize + aPacket->cmdHeader.numberBytesinPayload; 
    int32_t numBytesToSend = aPacket->numBytes; 
    if(needToSwap)SwapLongBlock(aPacket,sizeof(SBC_CommandHeader)/sizeof(int32_t)+1);
    char* p = (char*)aPacket;
    while (numBytesToSend) {       
        int32_t bytesWritten = write(workingIRQSocket,p,numBytesToSend);
        if (bytesWritten > 0) {
            p += bytesWritten;
            numBytesToSend -= bytesWritten;
        }
        else break;
    }
    return numBytesToSend;
}

int32_t readIRQ(SBC_Packet* aPacket)
{ 
    int32_t numberBytesinPacket;
    int32_t bytesRead = read(workingIRQSocket, &numberBytesinPacket, sizeof(int32_t));
    if(bytesRead==0)return 0; //disconnected
    if(needToSwap)SwapLongBlock(&numberBytesinPacket,1);    
    aPacket->numBytes = numberBytesinPacket;
    numberBytesinPacket -= sizeof(int32_t);
    int32_t returnValue = numberBytesinPacket;
    char* p = (char*)&aPacket->cmdHeader;
    while(numberBytesinPacket){
        bytesRead = read(workingIRQSocket, p, numberBytesinPacket);
        if(bytesRead == 0) return 0;    //connection disconnected.
        p += bytesRead;
        numberBytesinPacket -= bytesRead;
    }
    aPacket->message[0] = '\0';
    if(needToSwap){
        //only swap the size and the header struct
        //the payload will be swapped by the user routines as needed.
        SwapLongBlock((int32_t*)&(aPacket->cmdHeader),sizeof(SBC_CommandHeader)/sizeof(int32_t));
    }

    return returnValue;
}


char startRun (void)
{    
    /*---------------------------------*/
    /* setup the circular buffer       */
    /* and init our run Info struct    */
    /*---------------------------------*/
    CB_initialize(kCBBufferSize);
    time(&lastTime); 
    pthread_mutex_lock (&runInfoMutex);  //begin critical section
    run_info.bufferSize                = kCBBufferSize;
    run_info.readCycles                = 0;
    run_info.recordsTransfered        = 0;
    run_info.wrapArounds            = 0;
    pthread_mutex_unlock (&runInfoMutex);  //end critical section
    if(run_info.statusBits | kSBC_ConfigLoadedMask){

        startHWRun(&crate_config);

        if( pthread_create(&readoutThreadId,NULL, readoutThread, 0) == 0){
            return pthread_detach(readoutThreadId)==0;
        }
        else return 0;
        
    }
    else return 0;
}

void stopRun()
{
    pthread_mutex_lock (&runInfoMutex);  //begin critical section
    run_info.statusBits        &= ~kSBC_RunningMask;        //clr bit
    run_info.statusBits        &= ~kSBC_ConfigLoadedMask; //clr bit
    run_info.readCycles        = 0;
    pthread_mutex_unlock (&runInfoMutex);  //end critical section

    stopHWRun(&crate_config);

    memset(&crate_config,0,sizeof(SBC_crate_config));
    //CB_cleanup();
}

void postLAM(SBC_Packet* lamPacket)
{
	char needToRunAckThread = 0;
	pthread_mutex_lock (&lamInfoMutex);		//begin critical section
	SBC_LAM_Data* p = (SBC_LAM_Data*)(lamPacket->payload);
	int32_t n = p->lamNumber;
	if(!lam_info[n].isValid){
		if(needToSwap){
			SwapLongBlock((int32_t*)&(p->lamNumber),sizeof(int32_t));
			int32_t num = p->numFormatedWords;
			SwapLongBlock((int32_t*)&(p->numFormatedWords),sizeof(int32_t));
			int32_t i;
			for(i=0;i<num;i++)SwapLongBlock((int32_t*)&(p->formatedWords[i]),sizeof(int32_t));
			num = p->numberLabeledDataWords;
			SwapLongBlock((int32_t*)&(p->numberLabeledDataWords),sizeof(int32_t));
			for(i=0;i<num;i++)SwapLongBlock((int32_t*)&(p->labeledData[i].data),sizeof(int32_t));
		}
		memcpy(&lam_info[n].lam_Packet, &lamPacket, sizeof(SBC_Packet));
		lam_info[n].isValid = TRUE;
		needToRunAckThread = TRUE;
	}
	
    pthread_mutex_unlock (&lamInfoMutex);   //end critical section
	
	if(needToRunAckThread && irqAckThreadId==0){
        if( pthread_create(&irqAckThreadId,NULL, irqAckThread, 0) == 0){
            pthread_detach(irqAckThreadId);
        }
	}
}

void* readoutThread (void* p)
{

    size_t cycles = 0;
    pthread_mutex_lock (&runInfoMutex);            //begin critical section
    run_info.statusBits |= kSBC_RunningMask;    //set bit
    pthread_mutex_unlock (&runInfoMutex);        //end critical section

    while(run_info.statusBits & kSBC_RunningMask) {
        if (cycles % 10000 == 0 ) {
          pthread_mutex_lock (&runInfoMutex);  //begin critical section
          run_info.readCycles = cycles;
          pthread_mutex_unlock (&runInfoMutex);  //end critical section
        }
        
        readHW(&crate_config,0,0); //start at index 0, nil for the lam data
        cycles++; 
    }

    return NULL;
}

void* irqAckThread (void* p)
{
	int i;
	struct timeval tv;
	tv.tv_sec  = 0;
	tv.tv_usec = 1000;
	while(run_info.statusBits & kSBC_RunningMask){
		int busyCount = 0;
		for(i=0;i<kMaxNumberLams;i++){
			if(!lam_info[i].isWaitingForAck && lam_info[i].isValid){
				writeIRQ(i);
				lam_info[i].isWaitingForAck = TRUE;
			}
			if(lam_info[i].isWaitingForAck) busyCount++;
		}
		
		if(busyCount){
			fd_set fds;
			FD_ZERO(&fds);
			FD_SET(workingIRQSocket, &fds);
			
			/* wait until timeout or data received*/
			int  selectionResult = select(workingIRQSocket+1, &fds, NULL, NULL, &tv);
			if(selectionResult > 0){
				SBC_Packet lamAckPacket;
				if(readIRQ(&lamAckPacket)){
					SBC_LamAckStruct* p = (SBC_LamAckStruct*)lamAckPacket.payload;
					char numberToAck = p->numToAck; 
					char* lamPtr = (char*)p++;
					int n;
					pthread_mutex_lock (&lamInfoMutex);				//begin critical section
					for(n=0;n<numberToAck;n++){
						if(lamPtr[n]>=0 && lamPtr[n]<kMaxNumberLams){
							int index = lamPtr[n];
							lam_info[index].isWaitingForAck = FALSE;
							lam_info[index].isValid			= FALSE;
						}
					}
					pthread_mutex_unlock (&lamInfoMutex);			//end critical section
				}
			}
		}
		else {
			/*nothing waiting to be acked, so exit*/
			break;
		}
	}
	
	irqAckThreadId = 0;
	
	return NULL;
}

void LogMessage (const char *format,...)
{
	if(strlen(format) > kSBC_MaxStrSize*.75)return; //not a perfect check, but it will have to do....
	va_list ap;
	va_start (ap, template);
	pthread_mutex_lock (&runInfoMutex);  //begin critical section
	vfprintf (run_info.messageStrings[run_info.msg_buf_cnt], format, ap);
    run_info.msg_buf_cnt = (run_info.msg_buf_cnt + 1 ) % kSBC_MaxErrorBufferSize;
	pthread_mutex_unlock (&runInfoMutex);//end critical section
	va_end (ap);
}

void LogError (const char *format,...)
{
	if(strlen(format) > kSBC_MaxStrSize*.75)return; //not a perfect check, but it will have to do....
	va_list ap;
	va_start (ap, template);
	pthread_mutex_lock (&runInfoMutex);  //begin critical section
	vfprintf (run_info.errorStrings[run_info.err_buf_cnt], format, ap);
    run_info.err_buf_cnt = (run_info.err_buf_cnt + 1 ) % kSBC_MaxErrorBufferSize;
	pthread_mutex_unlock (&runInfoMutex);//end critical section
	va_end (ap);
}

/*---------------------------------*/
/*-------Helper Utilities----------*/
/*---------------------------------*/
void SwapLongBlock(void* p, int32_t n)
{
    int32_t* lp = (int32_t*)p;
    int32_t i;
    for(i=0;i<n;i++){
        int32_t x = *lp;
        *lp =  (((x) & 0x000000FF) << 24) |    
               (((x) & 0x0000FF00) <<  8) |    
               (((x) & 0x00FF0000) >>  8) |    
               (((x) & 0xFF000000) >> 24);
        lp++;
    }
}
void SwapShortBlock(void* p, int32_t n)
{
    int16_t* sp = (int16_t*)p;
    int32_t i;
    for(i=0;i<n;i++){
        int16_t x = *sp;
        *sp =  ((x & 0x00FF) << 8) |    
               ((x & 0xFF00) >> 8) ;
        sp++;
    }
}
