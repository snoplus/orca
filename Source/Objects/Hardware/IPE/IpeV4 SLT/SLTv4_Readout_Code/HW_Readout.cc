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

#define USE_PBUS 0


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

#if PMC_COMPILE_IN_SIMULATION_MODE
    #warning MESSAGE: HW_Readout: PMC_COMPILE_IN_SIMULATION_MODE is 1
#else
    #warning MESSAGE: HW_Readout: PMC_COMPILE_IN_SIMULATION_MODE is 0
#endif


#if USE_PBUS
#ifdef __cplusplus
extern "C" {
#endif
#include "pbusinterface.h"
#ifdef __cplusplus
}
#endif
#endif


#if PMC_COMPILE_IN_SIMULATION_MODE
    //# warning MESSAGE: PMC_COMPILE_IN_SIMULATION_MODE is 1
#else
    //# warning MESSAGE: PMC_COMPILE_IN_SIMULATION_MODE is 0
	#include "hw4/baseregister.h"
	#include "katrinhw4/subrackkatrin.h"
	#include "katrinhw4/sltkatrin.h"
	#include "katrinhw4/fltkatrin.h"
#endif

#include "HW_Readout.h"


void SwapLongBlock(void* p, int32_t n);
void SwapShortBlock(void* p, int32_t n);
int32_t writeBuffer(SBC_Packet* aPacket);

extern char needToSwap;
extern int32_t  dataIndex;
extern int32_t* data;

hw4::SubrackKatrin* get_sub_rack() { return srack; }

void processHWCommand(SBC_Packet* aPacket)
{
    /*look at the first word to get the destination*/
    int32_t aCmdID = aPacket->cmdHeader.cmdID;
    
    switch(aCmdID){
            //        default:              processUnknownCommand(aPacket); break;
    }
}

void FindHardware(void)
{
    //open device driver(s), get device driver handles
    const char* name = "FE.ini";
#if USE_PBUS
    pbusInit((char*)name);
#else
#endif
    //TODO: check here blocking semaphores? -tb-
    srack = new hw4::SubrackKatrin((char*)name,0);
    srack->checkSlot(); //check for available slots (init for isPresent(slot)); is necessary to prepare readout loop! -tb-
    pbus = srack->theSlt->version; //all registers inherit from Pbus, we choose "version" as it shall exist for all FPGA configurations
    if(!pbus) fprintf(stdout,"HW_Readout.cc (IPE DAQ V4): ERROR: could not connect to Pbus!\n");
    // test/force the C++ link to fdhwlib -tb-
    if(0){
        printf("Try to create a BaseRegister object -tb-\n");
        fflush(stdout);
        hw4::BaseRegister *reg;
        reg = new hw4::BaseRegister("dummy",3,7,1,1);
        printf("  ->register name is %s, addr 0x%08lx\n", reg->getName(),reg->getAddr());
        fflush(stdout);
    }
}

void ReleaseHardware(void)
{
    //release / close device driver(s)
#if USE_PBUS
    pbusFree();
#else
    pbus = 0;
    delete srack;
#endif
}

void doWriteBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_IPEv4WriteBlockStruct* p = (SBC_IPEv4WriteBlockStruct*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_IPEv4WriteBlockStruct)/sizeof(int32_t));
    
    uint32_t startAddress   = p->address;
    uint32_t numItems       = p->numItems;
    
    p++;                                /*point to the data*/
    int32_t* lptr = (int32_t*)p;        /*cast to the data type*/ 
    if(needToSwap) SwapLongBlock(lptr,numItems);
    
    //**** use device driver call to write data to HW
    int32_t perr = 0;
#if USE_PBUS
    if (numItems == 1)    perr = pbusWrite(startAddress, *lptr);
    else                perr = pbusWriteBlock(startAddress, (unsigned long *) lptr, numItems);
#else
    try{
        if (numItems == 1)  pbus->write(startAddress, *lptr);
        else                pbus->writeBlock(startAddress, (unsigned long *) lptr, numItems);
    }catch(PbusError &e){
        perr = 1;
    }
#endif
    
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
    
    if (numItems*sizeof(uint32_t) > kSBC_MaxPayloadSizeBytes) {
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
#if USE_PBUS
    if (numItems == 1)  perr = pbusRead(startAddress, lPtr);
    else                perr = pbusReadBlock(startAddress, lPtr, numItems);
    //TODO: -tb- printf("perr: %d\n",perr);
#else
    try{
        if (numItems == 1)  *lPtr = pbus->read(startAddress);
        else                pbus->readBlock(startAddress, (unsigned long *) lPtr, numItems);
    }catch(PbusError &e){
        perr = 1;
    }
#endif
     
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


