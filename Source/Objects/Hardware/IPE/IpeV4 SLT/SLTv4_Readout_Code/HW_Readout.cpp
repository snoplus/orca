//
//  HW_Readout.cpp
//  Orca
//
//  Created by Mark Howe on Mon Mar 10, 2008
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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
#include <string.h>
#include <sys/types.h>
#include <time.h>
#include <errno.h>


#ifdef __cplusplus
extern "C" {
#endif
#include "SBC_Cmds.h"
#include "SBC_Config.h"
#include "SBC_Readout.h"
#include "CircularBuffer.h"
#include "SLTv4_HW_Definitions.h"
#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
extern "C" {
#endif
#include "pbusinterface.h"
#ifdef __cplusplus
}
#endif

#include "hw4/baseregister.h"
#include "katrinhw4/subrackkatrin.h"
#include "katrinhw4/sltkatrin.h"
#include "katrinhw4/fltkatrin.h"

#include "HW_Readout.h"

static hw4::SubrackKatrin *srack=0;
#define USE_PBUS 0

void SwapLongBlock(void* p, int32_t n);
void SwapShortBlock(void* p, int32_t n);
int32_t writeBuffer(SBC_Packet* aPacket);

extern char needToSwap;
extern int32_t  dataIndex;
extern int32_t* data;

//replace with whatever device driver handle(s) you have
//TUVMEDevice* vmeAM29Handle = NULL;
//TUVMEDevice* controlHandle = NULL;
//TUVMEDevice* vmeAM39Handle = NULL;
//TUVMEDevice* vmeAM9Handle = NULL;




void processHWCommand(SBC_Packet* aPacket)
{
    /*look at the first word to get the destination*/
    int32_t destination = aPacket->cmdHeader.destination;

    switch(destination){
//        default:              processUnknownCommand(aPacket); break;
    }
}

void startHWRun (SBC_crate_config* config)
{    
    int32_t index = 0;
    while(1){
        switch(config->card_info[index].hw_type_id){
            default:     index =  -1; break;
        }
        if(index>=config->total_cards || index<0)break;
    }
}

void stopHWRun (SBC_crate_config* config)
{
    int32_t index = 0;
    while(1){
        switch(config->card_info[index].hw_type_id){
            default:     index =  -1; break;
        }
        if(index>=config->total_cards || index<0)break;
    }
}

void FindHardware(void)
{
	//open device driver(s), get device driver handles
		const char* name = "FE.ini";
        #if USE_PBUS
        pbusInit((char*)name);
        #else
        srack = new hw4::SubrackKatrin((char*)name,0);
        srack->checkSlot(); //check for available slots (init for isPresent(slot)); is necessary to prepare readout loop! -tb-

        #endif
        // testing the C++ link to fdhwlib -tb-
        if(0){
            printf("Try to create a BaseRegister object -tb-\n");
            fflush(stdout);
            hw4::BaseRegister *reg;
            reg = new hw4::BaseRegister("dummy",3,7,1,1);
            printf("  ->register name is %s, addr 0x%08lx\n", reg->getName(),reg->getAddr());
        }
}

void ReleaseHardware(void)
{
	//release / close device driver(s)
    #if USE_PBUS
    pbusFree();
    #else
    delete srack;
    #endif
}

void doWriteBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_IPEv4WriteBlockStruct* p = (SBC_IPEv4WriteBlockStruct*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_IPEv4WriteBlockStruct)/sizeof(int32_t));

    uint32_t startAddress   = p->address;
    uint32_t numItems       = p->numItems;
    
    p++;								/*point to the data*/
	int32_t* lptr = (int32_t*)p;		/*cast to the data type*/ 
	if(needToSwap) SwapLongBlock(lptr,numItems);
    
	//**** use device driver call to write data to HW
	int32_t perr = 0;
    if (numItems == 1)	perr = pbusWrite(startAddress, *lptr);
	else				perr = pbusWriteBlock(startAddress, (unsigned long *) lptr, numItems);
	    
    /* echo the structure back with the error code*/
    /* 0 == no Error*/
    /* non-0 means an error*/
    SBC_IPEv4WriteBlockStruct* returnDataPtr = (SBC_IPEv4WriteBlockStruct*)aPacket->payload;
    returnDataPtr->address         = startAddress;
    returnDataPtr->numItems        = 0;

	//assuming that the device driver returns the number of bytes read
	if(perr == 0){
        returnDataPtr->errorCode = 0;
    }
    else {
        aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_IPEv4WriteBlockStruct);
        returnDataPtr->errorCode = perr;        
    }

    lptr = (int32_t*)returnDataPtr;
    if(needToSwap)SwapLongBlock(lptr,numItems);

	//send back to ORCA
    if(reply)writeBuffer(aPacket);    
	
}

void doReadBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_IPEv4ReadBlockStruct* p = (SBC_IPEv4ReadBlockStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p,sizeof(SBC_IPEv4ReadBlockStruct)/sizeof(int32_t));
    
    uint32_t startAddress   = p->address;
    int32_t numItems        = p->numItems;
	//TODO: -tb- debug printf("starting read: %08x %d\n",startAddress,numItems);

    if (numItems*sizeof(uint32_t) > kSBC_MaxPayloadSize) {
        sprintf(aPacket->message,"error: requested greater than payload size.");
        p->errorCode = -1;
        if(reply)writeBuffer(aPacket);
        return;
    }
 
    /*OK, got address and # to read, set up the response and go get the data*/
    aPacket->cmdHeader.destination = kSBC_Process;
    aPacket->cmdHeader.cmdID       = kSBC_ReadBlock;
    aPacket->cmdHeader.numberBytesinPayload    = sizeof(SBC_IPEv4ReadBlockStruct) + numItems*sizeof(uint32_t);

    SBC_IPEv4ReadBlockStruct* returnDataPtr = (SBC_IPEv4ReadBlockStruct*)aPacket->payload;
    char* returnPayload = (char*)(returnDataPtr+1);
    unsigned long *lPtr = (unsigned long *) returnPayload;
	
	int32_t perr   = 0;
    if (numItems == 1)  perr = pbusRead(startAddress, lPtr);
    else				perr = pbusReadBlock(startAddress, lPtr, numItems);
	//TODO: -tb- printf("perr: %d\n",perr);
 	
    returnDataPtr->address         = startAddress;
    returnDataPtr->numItems        = numItems;
    if(perr == 0){
        returnDataPtr->errorCode = 0;
		if(needToSwap) SwapLongBlock((int32_t*)returnPayload,numItems);
    }
    else {
        //TODO: -tb- sprintf(aPacket->message,"error: %d %d : %s\n",perr,(int32_t)errno,strerror(errno));
        aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_IPEv4ReadBlockStruct);
        returnDataPtr->numItems  = 0;
        returnDataPtr->errorCode = perr;        
    }

    if(needToSwap) SwapLongBlock(returnDataPtr,sizeof(SBC_IPEv4ReadBlockStruct)/sizeof(int32_t));
    if(reply)writeBuffer(aPacket);
}

/*************************************************************/
/*  All HW Readout code follows here.						 */
/*                                                           */
/*  Readout_CARD() function returns the index of the next    */
/*   card to read out                                        */
/*************************************************************/
int32_t readHW(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    if(index<config->total_cards && index>=0) {
        switch(config->card_info[index].hw_type_id){
            case kSLTv4:       index = Readout_Sltv4(config,index,lamData);       break;
            case kFLTv4:       index = Readout_Fltv4(config,index,lamData);       break;
            default:            index = -1;                                       break;
        }
        return index;
    }
    else return -1;
}

/*************************************************************/
/*             Reads out									 */
/*************************************************************/
int32_t Readout_Sltv4(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
	/* -----  example from the old shaper readout ---------
	//data that is to be shipped is just put into the data[] array, incrementing the dataIndex each time
	//note: don't initialize or reset the dataIndex, if you need the possiblity of discarding a record, then
	//save the dataIndex at the start of the creation of a record and reset to that point if the record is to
	//be discarded.
	//the data record format is the same as the normal ORCA-side format
	
    uint32_t baseAddress            = config->card_info[index].base_add;
    uint32_t conversionRegOffset    = config->card_info[index].deviceSpecificData[1];
    
    char theConversionMask;
    int32_t result    = read_device(vmeAM29Handle,&theConversionMask,1,baseAddress+conversionRegOffset); //byte access, the conversion mask
    if(result == 1 && theConversionMask != 0){

        uint32_t dataId            = config->card_info[index].hw_mask[0];
        uint32_t slot              = config->card_info[index].slot;
        uint32_t crate             = config->card_info[index].crate;
        uint32_t locationMask      = ((crate & 0x01e)<<21) | ((slot & 0x0000001f)<<16);
        uint32_t onlineMask        = config->card_info[index].deviceSpecificData[0];
        uint32_t firstAdcRegOffset = config->card_info[index].deviceSpecificData[2];

        int16_t channel;
        for (channel=0; channel<8; ++channel) {
            if(onlineMask & theConversionMask & (1L<<channel)){
                uint16_t aValue;
                result    = read_device(vmeAM29Handle,(char*)&aValue,2,baseAddress+firstAdcRegOffset+2*channel); //short access, the adc Value
                if(result == 2){
                    if(((dataId) & 0x80000000)){ //short form
                        data[dataIndex++] = dataId | locationMask | ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);
                    }
                    else { //long form
                        data[dataIndex++] = dataId | 2;
                        data[dataIndex++] = locationMask | ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);
                    }
                }
                else if (result < 0)LogBusError("Rd Err: Shaper 0x%04x %s",baseAddress,strerror(errno));                
            }
        }
    }
    else if (result < 0)LogBusError("Rd Err: Shaper 0x%04x %s",baseAddress,strerror(errno));                
*/

    //"counter" for debugging
        static int currentSec=0;
        static int currentUSec=0;
        static int lastSec=0;
        static int lastUSec=0;
        //static long int counter=0;
        static long int secCounter=0;
        
        struct timeval t;//    struct timezone tz; is obsolete ... -tb-
        //timing
        gettimeofday(&t,NULL);
        currentSec = t.tv_sec;  
        currentUSec = t.tv_usec;  
        double diffTime = (double)(currentSec  - lastSec) +
		((double)(currentUSec - lastUSec)) * 0.000001;
        
        if(diffTime >1.0){
            secCounter++;
            printf("PrPMC sec %ld: 1 sec is over, ship data ...\n",secCounter);
            fflush(stdout);
            //remember for next call
            lastSec      = currentSec; 
            lastUSec     = currentUSec; 
        }else{
            // skip shipping data record
            return config->card_info[index].next_Card_Index;
        }
    //==============================================================================
    //TEST READOUT LOOP --------- BEGIN    
        #if 1
        int col; // col is number of FLT (0..23)
        unsigned long int fstatus,f1,f2,f3,f4,chmap,energy,pagenr,writeptr,readptr,
                          diff,evsec,evsubsec;
        uint32_t status;
        int fifoempty,status_ef;
        
        for(col=0; col<20;col++){
            fflush(stdout);
            if(srack->theFlt[col]->isPresent()){
  //fprintf(stdout,"Flt %i ->status has address %p  \n",col,srack->theFlt[col]->status );
            //hw4::FltKatrinStatus* st=srack->theFlt[col]->status;
                status = srack->theFlt[col]->status->read();
                status_ef = (status & 0x1000000) >> 24;
                //printf("  FLT %i status 0x%0x:  fifoEmpty:%i  \n",col,status, status_ef);
                //printf("Fifo FLT %i: ",col);
                {
                    fstatus = srack->theFlt[col]->eventFIFOStatus->read();
                    writeptr = fstatus & 0x3ff;
                    readptr = (fstatus >>16) & 0x3ff;
                    diff = (writeptr-readptr+1024) % 512;
                    printf(" fstatus: (0x%0lx)   writeptr %lu (0x%lx) readptr %lu ... diff %i\n",
                           fstatus,            writeptr,writeptr,  readptr, diff );
                           fflush(stdout);
                }
                if(diff>1){
                    while(diff>1)
                    {
                        f1 = srack->theFlt[col]->eventFIFO1->read();
                        chmap = f1 >> 8;
                        //printf("   channelmap: (0x%0lx) \n",chmap);
                        //fflush(stdout);
                        f2 = srack->theFlt[col]->eventFIFO2->read();
                        //check channel map
                        int eventchan;
                        for(eventchan=0;eventchan<24;eventchan++){
                            if(chmap & (0x1 << eventchan)){
                                printf("  -->EVENT FLT %2i, chan %2i: ",col,eventchan);
                                f3 = srack->theFlt[col]->eventFIFO3->read(eventchan);
                                f4 = srack->theFlt[col]->eventFIFO4->read(eventchan);
                                pagenr = f3;
                                energy = f4 ;
                                evsec = ( (f1 & 0xff) <<5 )  |  (f2 >>27);  //13 bit
                                evsubsec = (f2 >> 2) & 0x1ffffff; // 25 bit
                                printf("  sec %10lu subsec %9lu   ", evsec,evsubsec );
                                printf("  energy %lu page# %lu  ", energy,pagenr );
                                printf(" ... \n" );
                                fflush(stdout);fflush(stderr);
                                //for(row=0; row<24;row++){
                                //    int hitrate = srack->theFlt[col]->hitrate->read(row);
                                //    if(row<5) printf(" %i(0x%x),",hitrate,hitrate);
                                //}
                                //printf(" ...\n");
                        
                                //debug fstatus = srack->theFlt[col]->eventFIFOStatus->read();
                                //debug writeptr = fstatus & 0x3ff;
                                //debug readptr = (fstatus >>16) & 0x3ff;
                                //debug printf(" fstatus: (0x%0lx)   writeptr %lu (0x%lx) readptr %lu ...\n",
                                //debug    fstatus,            writeptr,writeptr,  readptr );
                            }
                            fstatus = srack->theFlt[col]->eventFIFOStatus->read();
                            writeptr = fstatus & 0x3ff;
                            readptr = (fstatus >>16) & 0x3ff;
                            diff = (writeptr-readptr+1024) % 512;
                        }
                    }
                }
                else{
                    printf("Fifo is EMPTY ...\n");
                    fflush(stdout);
                }
            }
        }
        printf(" ...\n");
        #endif
    
    //TEST READOUT LOOP --------- END
    //==============================================================================
    

    uint32_t dataId            = config->card_info[index].hw_mask[0];
    uint32_t stationNumber     = config->card_info[index].slot;
    uint32_t crate             = config->card_info[index].crate;
    data[dataIndex++] = dataId | 5;
    data[dataIndex++] =  ((stationNumber & 0x0000001f) << 16) | (crate & 0x0f) <<21;
    data[dataIndex++] = 6;
    data[dataIndex++] = 8;
    data[dataIndex++] = 15;
    return config->card_info[index].next_Card_Index;
}            

int32_t Readout_Fltv4(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
	/*
    uint32_t baseAddress            = config->card_info[index].base_add;
    uint32_t conversionRegOffset    = config->card_info[index].deviceSpecificData[1];
	*/
    printf("this is  Readout_Fltv4\n");
    return config->card_info[index].next_Card_Index;
}


