//
//  HW_Readout.m
//  Orca
//
//  Created by Mark Howe on Mon Sept 10, 2007
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <time.h>
#include <errno.h>
#include "SBC_Cmds.h"
#include "SBC_Config.h"
#include "HW_Readout.h"
#include "SBC_Readout.h"
#include "CircularBuffer.h"
#include "VME_HW_Definitions.h"
#include "SNO.h"
#include "universe_api.h"

#define kDMALowerLimit   0x100 //require 256 bytes
#define kControlSpace    0xFFFF
#define kPollSameAddress 0xFF


void SwapLongBlock(void* p, int32_t n);
void SwapShortBlock(void* p, int32_t n);
int32_t writeBuffer(SBC_Packet* aPacket);
int32_t sis3300CurrentBank[32];

extern char needToSwap;
extern int32_t  dataIndex;
extern int32_t* data;

TUVMEDevice* vmeAM29Handle = NULL;
TUVMEDevice* controlHandle = NULL;
TUVMEDevice* vmeAM39Handle = NULL;
TUVMEDevice* vmeAM9Handle = NULL;

void processHWCommand(SBC_Packet* aPacket)
{
	/*look at the first word to get the destination*/
	int32_t destination = aPacket->cmdHeader.destination;
	switch(destination){
		case kSNO:		processSNOCommand(aPacket); break;
		default:			break;
	}
}

void FindHardware(void)
{
    vmeAM29Handle = get_new_device(0x0, 0x29, 2, 0x10000); 
    if (vmeAM29Handle == NULL) LogBusError("Device vmeAM29Handle: %s",strerror(errno));
    
    controlHandle = get_ctl_device(); 
    if (controlHandle == NULL) LogBusError("Device controlHandle: %s",strerror(errno));
    
    vmeAM39Handle = get_new_device(0x0, 0x39, 4, 0x1000000);
    if (vmeAM39Handle == NULL) LogBusError("Device vmeAM39Handle: %s",strerror(errno));
    
    vmeAM9Handle = get_new_device(0x0, 0x9, 4, 0x2000000);
    if (vmeAM9Handle == NULL) LogBusError("Device vmeAM9Handle: %s",strerror(errno));
    /* The entire A16 (D16), A24 (D16), space is mapped. */
    /* The bottom of A32 (D32) is mapped up to 0x2000000. */
    /* We need to be careful!*/
  
    /* The following is particular to the concurrent boards. */
    set_hw_byte_swap(true);
}

void ReleaseHardware(void)
{
    if (vmeAM29Handle) close_device(vmeAM29Handle);    
    if (vmeAM39Handle) close_device(vmeAM39Handle);    
    if (vmeAM9Handle)  close_device(vmeAM9Handle);    
}


void doWriteBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_VmeWriteBlockStruct* p = (SBC_VmeWriteBlockStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p,sizeof(SBC_VmeWriteBlockStruct)/sizeof(int32_t));

    uint32_t startAddress   = p->address;
    uint32_t oldAddress     = p->address;
    int32_t addressModifier = p->addressModifier;
    int32_t addressSpace    = p->addressSpace;
    int32_t unitSize        = p->unitSize;
    int32_t numItems        = p->numItems;
    TUVMEDevice* memMapHandle;
    bool deleteHandle = false;
    bool useDMADevice = false;

    if (addressSpace == kControlSpace) {
        memMapHandle = controlHandle;
        if (unitSize != sizeof(uint32_t) && numItems != 1) {
            sprintf(aPacket->message,"error: size and number not correct");
            p->errorCode = -1;
            if(reply)writeBuffer(aPacket);
            return;
        }
    } else if(unitSize*numItems >= kDMALowerLimit) {
	useDMADevice = true;
        if (addressSpace == kPollSameAddress) { 
          memMapHandle = get_dma_device(oldAddress, addressModifier, unitSize, false);
        } else {
          memMapHandle = get_dma_device(oldAddress, addressModifier, unitSize, true);
        }
        addressSpace=0x1;
        startAddress = 0x0;
    } else if(addressModifier == 0x29 && unitSize == 2) {
        memMapHandle = vmeAM29Handle;
    } else if(addressModifier == 0x39 && unitSize == 4) {
        memMapHandle = vmeAM39Handle;
    } else if(addressModifier == 0x9 && unitSize == 4 && startAddress < 0x2000000) {
        memMapHandle = vmeAM9Handle;
    } else {
        /* The address must be byte-aligned */ 
        startAddress = p->address & 0xFFFF;
        p->address = p->address & 0xFFFF0000;
        memMapHandle = get_new_device(p->address, addressModifier, unitSize, 0); 
        if (memMapHandle == NULL) {
            sprintf(aPacket->message,"error: %d : %s\n",(int32_t)errno,strerror(errno));
            p->errorCode = errno;
            if(reply)writeBuffer(aPacket);
            return;
        }
        deleteHandle = true;
    }
    
    p++; /*point to the data*/
    int16_t *sptr;
    int32_t  *lptr;
    switch(unitSize){
        case 1: /*bytes*/
            /*no need to swap*/
        break;
        
        case 2: /*shorts*/
            sptr = (int16_t*)p; /* cast to the data type*/ 
            if(needToSwap) SwapShortBlock(sptr,numItems);
        break;
        
        case 4: /*longs*/
            lptr = (int32_t*)p; /* cast to the data type*/ 
            if(needToSwap) SwapLongBlock(lptr,numItems);
        break;
    }
    
    int32_t result = 0;
    if (!deleteHandle && !useDMADevice) lock_device(memMapHandle);
    if (addressSpace == kPollSameAddress) {
        /* We have to poll the same address. */
        uint32_t i = 0;
        for (i=0;i<numItems;i++) {
            result = 
                write_device(memMapHandle,
                    (char*)p + i*unitSize,unitSize,startAddress);
            if (result != unitSize) break;
        }
        if (result == unitSize) result = unitSize*numItems; 
    } else {
        result = write_device(memMapHandle,(char*)p,
                              numItems*unitSize,startAddress);
    }
    if (!deleteHandle && !useDMADevice) unlock_device(memMapHandle);
    if (useDMADevice) {
        release_dma_device();
    }
    
    /* echo the structure back with the error code*/
    /* 0 == no Error*/
    /* non-0 means an error*/
    SBC_VmeWriteBlockStruct* returnDataPtr = (SBC_VmeWriteBlockStruct*)aPacket->payload;

    returnDataPtr->address         = oldAddress;
    returnDataPtr->addressModifier = addressModifier;
    returnDataPtr->addressSpace    = addressSpace;
    returnDataPtr->unitSize        = unitSize;
    returnDataPtr->numItems        = 0;

    if(result == (numItems*unitSize)){
        returnDataPtr->errorCode = 0;
    } 
	else {
        aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_VmeWriteBlockStruct);
        returnDataPtr->errorCode = errno;        
    }

    lptr = (int32_t*)returnDataPtr;
    if(needToSwap) SwapLongBlock(lptr,numItems);

    if(reply)writeBuffer(aPacket);    

    if (deleteHandle) {
        close_device(memMapHandle);
    } 

}

void doReadBlock(SBC_Packet* aPacket,uint8_t reply)
{
    SBC_VmeReadBlockStruct* p = (SBC_VmeReadBlockStruct*)aPacket->payload;
    if(needToSwap) {
        SwapLongBlock(p,sizeof(SBC_VmeReadBlockStruct)/sizeof(int32_t));
    }
    uint32_t startAddress   = p->address;
    uint32_t oldAddress     = p->address;
    int32_t addressModifier = p->addressModifier;
    int32_t addressSpace    = p->addressSpace;
    int32_t unitSize        = p->unitSize;
    int32_t numItems        = p->numItems;
    TUVMEDevice* memMapHandle;
    bool deleteHandle = false;
    bool useDMADevice = false;

    if (numItems*unitSize > kSBC_MaxPayloadSize) {
        sprintf(aPacket->message,"error: requested greater than payload size.");
        p->errorCode = -1;
        if(reply)writeBuffer(aPacket);
        return;
    }
    if (addressSpace == kControlSpace) {
        memMapHandle = controlHandle;
        if (unitSize != sizeof(uint32_t) && numItems != 1) {
            sprintf(aPacket->message,"error: size and number not correct");
            p->errorCode = -1;
            if(reply) writeBuffer(aPacket);
            return;
         }
    } 
    else if(unitSize*numItems >= kDMALowerLimit) {
        // Use DMA access which is normally faster.
	useDMADevice = true;
        if (addressSpace == kPollSameAddress) {
            memMapHandle = get_dma_device(oldAddress, addressModifier, unitSize, false);
         } else {
            memMapHandle = get_dma_device(oldAddress, addressModifier, unitSize, true);
         }
        addressSpace =0x1; // reset this for the later call.
        startAddress = 0x0;
    }
    else if(addressModifier == 0x29 && unitSize == 2) {
        memMapHandle = vmeAM29Handle;
    } 
    else if(addressModifier == 0x39 && unitSize == 4) {
        memMapHandle = vmeAM39Handle;
    } 
    else if(addressModifier == 0x9 && unitSize == 4 && startAddress < 0x2000000) {
        memMapHandle = vmeAM9Handle;
    } 
    else {
        /* The address must be byte-aligned */ 
        startAddress = p->address & 0xFFFF;
        p->address   = p->address & 0xFFFF0000;
        
        memMapHandle = get_new_device(p->address, addressModifier, unitSize, 0); 
        if (memMapHandle == NULL) {
            sprintf(aPacket->message,"error: %d : %s\n",
                (int32_t)errno,strerror(errno));
            p->errorCode = errno;
            if(reply)writeBuffer(aPacket);
            return;
        }
        deleteHandle = true;
    }

    /*OK, got address and # to read, set up the response and go get the data*/
    aPacket->cmdHeader.destination = kSBC_Process;
    aPacket->cmdHeader.cmdID       = kSBC_ReadBlock;
    aPacket->cmdHeader.numberBytesinPayload    
        = sizeof(SBC_VmeReadBlockStruct) + numItems*unitSize;

    SBC_VmeReadBlockStruct* returnDataPtr = 
        (SBC_VmeReadBlockStruct*)aPacket->payload;
    char* returnPayload = (char*)(returnDataPtr+1);

    int32_t result = 0;
    
    if (!deleteHandle && !useDMADevice) lock_device(memMapHandle);
    if (addressSpace == kPollSameAddress) {
        /* We have to poll the same address. */
        uint32_t i = 0;
        for (i=0;i<numItems;i++) {
            result = read_device(memMapHandle, returnPayload + i*unitSize,unitSize,startAddress);
            if (result != unitSize) break;
        }
        if (result == unitSize) result = unitSize*numItems; 
    } else {
        result = read_device(memMapHandle,returnPayload,numItems*unitSize,startAddress);
    }
    if (!deleteHandle && !useDMADevice) unlock_device(memMapHandle);
    if (useDMADevice) {
        release_dma_device();
    }
    
    returnDataPtr->address         = oldAddress;
    returnDataPtr->addressModifier = addressModifier;
    returnDataPtr->addressSpace    = addressSpace;
    returnDataPtr->unitSize        = unitSize;
    returnDataPtr->numItems        = numItems;
    if(result == (numItems*unitSize)){
        returnDataPtr->errorCode = 0;
        switch(unitSize){
            case 1: /*bytes*/
                /*no need to swap*/
                break;
            case 2: /*shorts*/
                if(needToSwap) SwapShortBlock((int16_t*)returnPayload,numItems);
                break;
            case 4: /*longs*/
                if(needToSwap) SwapLongBlock((int32_t*)returnPayload,numItems);
                break;
        }
    } else {
        sprintf(aPacket->message,"error: %d %d : %s\n",
           (int32_t)result,(int32_t)errno,strerror(errno));
        aPacket->cmdHeader.numberBytesinPayload    
            = sizeof(SBC_VmeReadBlockStruct);
        returnDataPtr->numItems  = 0;
        returnDataPtr->errorCode = errno;        
    }

    if(needToSwap) {
        SwapLongBlock(returnDataPtr,
            sizeof(SBC_VmeReadBlockStruct)/sizeof(int32_t));
    }
    if(reply)writeBuffer(aPacket);
    if (deleteHandle) {
        close_device(memMapHandle);
    } 

}

/*************************************************************/
/*  All HW Readout code for VMEcpu follows here.             */
/*                                                           */
/*  Readout_CARD() function returns the index of the next    */
/*   card to read out                                        */
/*************************************************************/


