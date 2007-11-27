/*---------------------------------------------------------------------------
/	SBC_Readout.c
/
/	09/09/07 Mark A. Howe
/	CENPA, University of Washington. All rights reserved.
/	ORCA project
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
#include <sys/types.h>
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
char startRun (void);
void stopRun (void);
void sendRunInfo(void);
void sendCBRecord(void);


/*----globals----*/
char				timeToExit;
SBC_crate_config	crate_config;
SBC_info_struct	run_info;
time_t				lastTime;

pthread_t			readoutThreadId;
pthread_mutex_t     runInfoMutex;
int	 workingSocket;
char needToSwap;
/*---------------*/

void sigchld_handler(int s)
{
    while(waitpid(-1, NULL, WNOHANG) > 0);
}

int main(int argc, char *argv[])
{
    int sockfd;				// listen on sock_fd, new connection on workingSocket
    struct sockaddr_in my_addr;		// my address information
    struct sockaddr_in their_addr;	// connector's address information
    socklen_t sin_size;
    struct sigaction sa;
    int yes=1;
	timeToExit = 0;
	
    if (argc != 2) {
        exit(1);
    }
	
	int thePort = atoi(argv[1]);
	while(1){
		if ((sockfd = socket(PF_INET, SOCK_STREAM, 0)) == -1) {
			exit(1);
		}
		
		if (setsockopt(sockfd,SOL_SOCKET,SO_REUSEADDR,&yes,sizeof(int)) == -1) {
			exit(1);
		}
		
		my_addr.sin_family = AF_INET;         // host byte order
		my_addr.sin_port = htons(thePort);     // short, network byte order
		my_addr.sin_addr.s_addr = INADDR_ANY; // automatically fill with my IP
		memset(my_addr.sin_zero, '\0', sizeof my_addr.sin_zero);
		
		if (bind(sockfd, (struct sockaddr *)&my_addr, sizeof(struct sockaddr))== -1) {
			exit(1);
		}
		
		if (listen(sockfd, BACKLOG) == -1) {
			exit(1);
		}
		
		sa.sa_handler = sigchld_handler; // reap all dead processes
		sigemptyset(&sa.sa_mask);
		sa.sa_flags = SA_RESTART;
		if (sigaction(SIGCHLD, &sa, NULL) == -1) {
			exit(1);
		}
		FindHardware();
	
		sin_size = sizeof(struct sockaddr_in);
		if ((workingSocket = accept(sockfd, (struct sockaddr *)&their_addr,
							 &sin_size)) == -1) {
			exit(1);
		}
		
		//don't need this socket anymore
		close(sockfd);
	
		//the first word sent is a test word to determine endian-ness
		long testWord;
		needToSwap = FALSE;
		int n = read(workingSocket,&testWord, 4);
		if(n == 0)	return 0 ; //disconnected -- exit
		if(testWord == 0xBADC0000)needToSwap = TRUE;
		//end of swap test

		//Note that we don't fork, only one connection is allowed.
		/*-------------------------------*/
		/*initialize our global variables*/
		pthread_mutex_init(&runInfoMutex, NULL);
		pthread_mutex_lock (&runInfoMutex);  //begin critical section
		run_info.statusBits		&= ~kSBC_ConfigLoadedMask; //clr bit
		run_info.statusBits		&= ~kSBC_RunningMask;		//clr bit
		run_info.readCycles		= 0;
		pthread_mutex_unlock (&runInfoMutex);//end critical section
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
	long destination = aPacket->cmdHeader.destination;

	switch(destination){
		case kSBC_Process:	 processSBCCommand(aPacket);			 break;
		default:			 processHWCommand(aPacket); break;
	}
}

void processSBCCommand(SBC_Packet* aPacket)
{
	switch(aPacket->cmdHeader.cmdID){
		case kSBC_WriteBlock:		
		case kSBC_VmeWriteBlock:
			pthread_mutex_lock (&runInfoMutex);							//begin critical section
			doWriteBlock(aPacket); 
			pthread_mutex_unlock (&runInfoMutex);						//end critical section
		break;
		
		case kSBC_ReadBlock:
		case kSBC_VmeReadBlock:		
			pthread_mutex_lock (&runInfoMutex);							//begin critical section
			doReadBlock(aPacket);  
			pthread_mutex_unlock (&runInfoMutex);						//end critical section
		break;
			
		case kSBC_LoadConfig:
			if(needToSwap)SwapLongBlock(aPacket->payload,sizeof(SBC_crate_config)/sizeof(long));
			memcpy(&crate_config, aPacket->payload, sizeof(SBC_crate_config));
			run_info.statusBits	|= kSBC_ConfigLoadedMask;
		break;
					
		case kSBC_StartRun:			doRunCommand(aPacket); break;
		case kSBC_StopRun:			doRunCommand(aPacket); break;
							
		case kSBC_RunInfoRequest:	sendRunInfo(); break;
		case kSBC_CBRead:			sendCBRecord(); break;
		case kSBC_Exit:				timeToExit = 1; break;
	}
}

void doRunCommand(SBC_Packet* aPacket)
{
	//future options will be decoded here, are not any so far so the code is commented out
	//SBC_CmdOptionStruct* p = (SBC_CmdOptionStruct*)aPacket->payload;
	//if(needToSwap)SwapLongBlock(p,sizeof(SBC_CmdOptionStruct)/sizeof(long));
	// option1 = p->option[0];
	// option2 = p->option[1];
	//....

	long result = 0;
	if(aPacket->cmdHeader.cmdID == kSBC_StartRun)  result = startRun();
	else if(aPacket->cmdHeader.cmdID == kSBC_StopRun) stopRun();

	SBC_CmdOptionStruct* op = (SBC_CmdOptionStruct*)aPacket->payload;
	op->option[0] = result;
	if(needToSwap)SwapLongBlock(op,sizeof(SBC_CmdOptionStruct)/sizeof(long));
	sendResponse(aPacket);
}


void sendResponse(SBC_Packet* aPacket)
{
	aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_CmdOptionStruct);
	
	SBC_CmdOptionStruct* p = (SBC_CmdOptionStruct*)aPacket->payload;		
	if(needToSwap)SwapLongBlock(p,sizeof(SBC_CmdOptionStruct)/sizeof(long));
	writeBuffer(aPacket);
}

void sendRunInfo(void)
{
	SBC_Packet aPacket;
	aPacket.cmdHeader.destination	= kSBC_Process;
	aPacket.cmdHeader.cmdID			= kSBC_RunInfoRequest;
	aPacket.cmdHeader.numberBytesinPayload	= sizeof(SBC_info_struct);
	
	SBC_info_struct* runInfoPtr = (SBC_info_struct*)aPacket.payload;

	pthread_mutex_lock (&runInfoMutex);							//begin critical section
	memcpy(runInfoPtr, &run_info, sizeof(SBC_info_struct));	//make copy
	pthread_mutex_unlock (&runInfoMutex);						//end critical section

	BufferInfo cbInfo;
	CB_getBufferInfo(&cbInfo);
	runInfoPtr->readIndex      = cbInfo.readIndex;
	runInfoPtr->writeIndex     = cbInfo.writeIndex;
	runInfoPtr->lostByteCount  = cbInfo.lostByteCount;
	runInfoPtr->amountInBuffer = cbInfo.amountInBuffer;
	runInfoPtr->wrapArounds    = cbInfo.wrapArounds;
			
	if(needToSwap)SwapLongBlock(runInfoPtr,sizeof(SBC_info_struct)/sizeof(long));
	writeBuffer(&aPacket);
}

void sendCBRecord(void)
{
	//create an empty packet
	SBC_Packet aPacket;
	aPacket.cmdHeader.destination			= kSBC_Process;
	aPacket.cmdHeader.cmdID					= kSBC_CBBlock;
	aPacket.message[0] = '\0';
	aPacket.cmdHeader.numberBytesinPayload	= 0;

	//point to the payload
	long* dataPtr = (long*)aPacket.payload;	
	
	long recordCount = 0;
	//put data from the circular buffer into the payload until either, 1)the payload is full, or 2)the CB is empty.
	do {
		long nextBlockSize = CB_nextBlockSize();
		if(nextBlockSize == 0)break;
		if((aPacket.cmdHeader.numberBytesinPayload + nextBlockSize*sizeof(long)) < (kSBC_MaxPayloadSize-32)){
			long maxToRead		= (kSBC_MaxPayloadSize - aPacket.cmdHeader.numberBytesinPayload)/sizeof(long);
			if(!CB_readNextDataBlock(dataPtr,maxToRead)) break;
			aPacket.cmdHeader.numberBytesinPayload	+= nextBlockSize*sizeof(long);
			dataPtr += nextBlockSize;
			recordCount++;
		}
		else break;
	} while (1);
	
	pthread_mutex_lock (&runInfoMutex);  //begin critical section
	run_info.recordsTransfered		+= recordCount;
	pthread_mutex_unlock (&runInfoMutex);  //end critical section

	writeBuffer(&aPacket);
}

int readBuffer(SBC_Packet* aPacket)
{ 
	long numberBytesinPacket;
	int bytesRead = read(workingSocket, &numberBytesinPacket, sizeof(long));
	if(bytesRead==0)return 0; //disconnected
	if(needToSwap)SwapLongBlock(&numberBytesinPacket,1);	
        aPacket->numBytes = numberBytesinPacket;
	numberBytesinPacket-= sizeof(long);
	int returnValue		= numberBytesinPacket;
	char* p = (char*)&aPacket->cmdHeader;
	while(numberBytesinPacket){
		bytesRead = read(workingSocket, p, numberBytesinPacket);
		if(bytesRead == 0) return 0;	//connection disconnected.
		p += bytesRead;
		numberBytesinPacket -= bytesRead;
	}
	aPacket->message[0] = '\0';
	if(needToSwap){
		//only swap the size and the header struct
		//the payload will be swapped by the user routines as needed.
		SwapLongBlock((long*)&(aPacket->cmdHeader),sizeof(SBC_CommandHeader)/sizeof(long));
	}

	return returnValue;
}

int writeBuffer(SBC_Packet* aPacket)
{ 
	if(!workingSocket)return 0;
	aPacket->numBytes =  sizeof(long) + sizeof(SBC_CommandHeader) + kSBC_MaxMessageSize + aPacket->cmdHeader.numberBytesinPayload; 
	int numBytesToSend = aPacket->numBytes; 
	if(needToSwap)SwapLongBlock(aPacket,sizeof(SBC_CommandHeader)/sizeof(long)+1);
	char* p = (char*)aPacket;
    while (numBytesToSend) {       
		int bytesWritten = write(workingSocket,p,numBytesToSend);
		if (bytesWritten > 0) {
			p += bytesWritten;
			numBytesToSend -= bytesWritten;
		}
		else break;
    }
	return numBytesToSend;
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
	run_info.bufferSize				= kCBBufferSize;
	run_info.readCycles				= 0;
	run_info.recordsTransfered		= 0;
	run_info.wrapArounds			= 0;
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
	run_info.statusBits		&= ~kSBC_RunningMask;		//clr bit
	run_info.statusBits		&= ~kSBC_ConfigLoadedMask; //clr bit
	run_info.readCycles		= 0;
	pthread_mutex_unlock (&runInfoMutex);  //end critical section

	stopHWRun(&crate_config);

	memset(&crate_config,0,sizeof(SBC_crate_config));
	CB_cleanup();
}

/*-------------------------------------------------------------
  Readout thread
-------------------------------------------------------------*/
void* readoutThread (void* p)
{

	pthread_mutex_lock (&runInfoMutex);			//begin critical section
	run_info.statusBits |= kSBC_RunningMask;	//set bit
	pthread_mutex_unlock (&runInfoMutex);		//end critical section

	while(run_info.statusBits & kSBC_RunningMask) {
		pthread_mutex_lock (&runInfoMutex);  //begin critical section
		run_info.readCycles++;
        
		readHW(&crate_config);
		
		pthread_mutex_unlock (&runInfoMutex);  //end critical section
	}

	return NULL;
}

void SwapLongBlock(void* p, long n)
{
	long* lp = (long*)p;
	int i;
	for(i=0;i<n;i++){
		long x = *lp;
		*lp =  (((x) & 0x000000FF) << 24) |	
				(((x) & 0x0000FF00) <<  8) |	
				(((x) & 0x00FF0000) >>  8) |	
				(((x) & 0xFF000000) >> 24);
		lp++;
	}
}
void SwapShortBlock(void* p, long n)
{
	short* sp = (short*)p;
	int i;
	for(i=0;i<n;i++){
		short x = *sp;
		*sp =  ((x) << 8) |	
			   ((x) >> 8) ;
		sp++;
	}
}


