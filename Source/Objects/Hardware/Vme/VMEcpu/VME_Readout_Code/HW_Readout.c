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
#include "VME_Trigger32.h"
#include "SNO.h"
#include "universe_api.h"

#define kDMALowerLimit   0x100 //require 256 bytes
#define kControlSpace    0xFFFF
#define kPollSameAddress 0xFF


void SwapLongBlock(void* p, int32_t n);
void SwapShortBlock(void* p, int32_t n);
int32_t writeBuffer(SBC_Packet* aPacket);

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
            p->errorCode = -1;
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
    SBC_VmeWriteBlockStruct* returnDataPtr = 
        (SBC_VmeWriteBlockStruct*)aPacket->payload;

    returnDataPtr->address         = oldAddress;
    returnDataPtr->addressModifier = addressModifier;
    returnDataPtr->addressSpace    = addressSpace;
    returnDataPtr->unitSize        = unitSize;
    returnDataPtr->numItems        = 0;

    if(result == (numItems*unitSize)){
        returnDataPtr->errorCode = 0;
    } else {
        aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_VmeWriteBlockStruct);
        returnDataPtr->errorCode = result;        
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
            p->errorCode = -1;
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
        //printf("no read error\n");
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
        returnDataPtr->errorCode = result;        
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

int32_t readHW(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    if(index<config->total_cards && index>=0) {
        switch(config->card_info[index].hw_type_id){
            case kShaper:       index = Readout_Shaper(config,index,lamData);       break;
            case kGretina:      index = Readout_Gretina(config,index,lamData);      break;
            case kTrigger32:    index = Readout_TR32_Data(config,index,lamData);    break;
            case kCaen:         index = Readout_CAEN(config,index,lamData);         break;
            case kSBCLAM:       index = Readout_LAM_Data(config,index,lamData);     break;
            case kCaen1720:     index = Readout_CAEN1720(config,index,lamData);		break;
            case kMtc:			index = Readout_MTC(config,index,lamData);			break;
            case kFec:			index = Readout_Fec(config,index,lamData);			break;
            default:            index = -1;                                         break;
        }
        return index;
    }
    else return -1;
}

/*************************************************************/
/*             Reads out the Mtc card.                       */
/*************************************************************/
int32_t Readout_MTC(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    uint32_t leaf_index;
    //uint32_t baseAddress            = config->card_info[index].base_add;
	char triggered = 0;
    //uint32_t conversionRegOffset    = config->card_info[index].deviceSpecificData[1];
    
    lock_device(vmeAM29Handle);
	//add mtc read-out specifics.... TBD
	
	//check for trigger, if trigger exists, set triggered = 1
	
	if(triggered){
		//we have a trigger so read out the FECs for event
		leaf_index = config->card_info[index].next_Trigger_Index[0];
		while(leaf_index >= 0) {
			leaf_index = readHW(config,leaf_index,lamData);
		}
	}

    unlock_device(vmeAM29Handle);

    return config->card_info[index].next_Card_Index;
}

/*************************************************************/
/*             Reads out the Mtc card.                       */
/*************************************************************/
int32_t Readout_Fec(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    //uint32_t baseAddress            = config->card_info[index].base_add;
    //uint32_t conversionRegOffset    = config->card_info[index].deviceSpecificData[1];
    
    lock_device(vmeAM29Handle);
	//add fec read-out specifics.... TBD
	
    unlock_device(vmeAM29Handle);

    return config->card_info[index].next_Card_Index;
}

/*************************************************************/
/*             Reads out Shaper cards.                       */
/*************************************************************/
int32_t Readout_Shaper(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    uint32_t baseAddress            = config->card_info[index].base_add;
    uint32_t conversionRegOffset    = config->card_info[index].deviceSpecificData[1];
    
    char theConversionMask;
    lock_device(vmeAM29Handle);
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
                    } else { //long form
                        data[dataIndex++] = dataId | 2;
                        data[dataIndex++] = locationMask | ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);
                    }
                } else if (result < 0)LogBusError("Rd Err: Shaper 0x%04x %s",baseAddress,strerror(errno));                
            }
        }
    } else if (result < 0)LogBusError("Rd Err: Shaper 0x%04x %s",baseAddress,strerror(errno));                
    unlock_device(vmeAM29Handle);

    return config->card_info[index].next_Card_Index;
}
            
int32_t Readout_CAEN1720(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    uint32_t baseAddress        = config->card_info[index].base_add;
    uint32_t numEventsAvailReg  = config->card_info[index].deviceSpecificData[0];
    uint32_t eventSizeReg       = config->card_info[index].deviceSpecificData[1];
    uint32_t fifoBuffReg        = config->card_info[index].deviceSpecificData[2];
    uint32_t fifoAddressMod     = config->card_info[index].deviceSpecificData[3];
    uint32_t fifoBuffSize       = config->card_info[index].deviceSpecificData[4];
    uint32_t location           = config->card_info[index].deviceSpecificData[5];
    uint32_t numBLTEventsReg    = config->card_info[index].deviceSpecificData[7];
    uint32_t theMod             = config->card_info[index].add_mod;
    
    TUVMEDevice* caenDMADevice = 0;
    TUVMEDevice* memMapHandle = get_new_device(baseAddress, theMod, 4, 0);
    if ( memMapHandle == NULL ) return config->card_info[index].next_Card_Index; 

    uint32_t numEventsToReadout = 0;
    
    int32_t result = read_device(memMapHandle,(char*)&numEventsToReadout,sizeof(numEventsToReadout),numBLTEventsReg); 
    if ( result != sizeof(numEventsToReadout) ) { 
        LogBusError("CAEN 0x%0x Couldn't read register", numBLTEventsReg);
        close_device(memMapHandle);
        return config->card_info[index].next_Card_Index;
    }
    if ( numEventsToReadout == 0 ) {
        // We will have a problem, this needs to be set *before*
        // starting a run.
        LogError("CAEN: BLT Events register must be set BEFORE run start");
        close_device(memMapHandle);
        return config->card_info[index].next_Card_Index;
    }
    
    uint32_t numEventsAvail;    
    result = read_device(memMapHandle,(char*)&numEventsAvail,4,numEventsAvailReg);    //long access, the status reg
    if(result == sizeof(numEventsAvail) && (numEventsAvail > 0)){                    //if at least one event is ready
        uint32_t eventSize;
        result    = read_device(memMapHandle,(char*)&eventSize,4,eventSizeReg);        //long access, the event size 
        if(result == sizeof(eventSize) && eventSize>0){
            uint32_t startIndex = dataIndex;
            uint32_t dataId     = config->card_info[index].hw_mask[0];
            if ( numEventsToReadout*(eventSize+1) + 2> kMaxDataBufferSize-dataIndex ) {
                /* We can't read out. */ 
                LogError("Temp buffer too small, requested (%d) > available (%d)",
                          numEventsToReadout*(eventSize+1)+2, 
                          kMaxDataBufferSize-dataIndex);
                close_device( memMapHandle );
                return config->card_info[index].next_Card_Index;
            } 
            
            //load ORCA header info
            data[dataIndex++] = dataId | (2+numEventsToReadout*eventSize);
            data[dataIndex++] = location; //location = crate and card number
          
            caenDMADevice = get_dma_device(fifoBuffReg+baseAddress, fifoAddressMod, 8, true);
          
            if (caenDMADevice == NULL) {
                close_device( memMapHandle );
                return config->card_info[index].next_Card_Index;
            }
            uint32_t numBytesRead = 0;
            result = fifoBuffSize;
            while ( result == fifoBuffSize ) { 
                result = read_device(caenDMADevice,(char*)(data + dataIndex),
                                     fifoBuffSize, 0); 
                if ( result < 0 ) {
                    LogBusError("Error reading DMA for V1720: %s", strerror(errno));
                    dataIndex = startIndex;
                    close_device( memMapHandle );
                    release_dma_device();
                    return config->card_info[index].next_Card_Index;
                }
                dataIndex += result/4;
                if ( dataIndex + fifoBuffSize/4 > kMaxDataBufferSize ) {
                    /* Error checking, for some reason we will read past our buffer.*/
                    /* Reset to not do that. */
                    dataIndex = startIndex;
                    LogError("CAEN V1720: Error reading into buffer, trying to continue.");
                } 
                numBytesRead += result;
            }
            uint32_t numberOfEndWords = 0;         
            if ( data[dataIndex-1] == 0xFFFFFFFF ) numberOfEndWords = 1;
          
            if ( numBytesRead != numEventsToReadout*(eventSize+numberOfEndWords)*4 ) {
                dataIndex = startIndex; //just flush the event
                close_device( memMapHandle );
                release_dma_device();
                return config->card_info[index].next_Card_Index;
            }
            // Reading out with a BERR coudl leave an extra word on the end, get rid of it.
            dataIndex -= numberOfEndWords;
        } 
        else LogBusError("Rd Err: V1720 0x%04x %s",baseAddress,strerror(errno));                
    }

    release_dma_device();
    close_device( memMapHandle );
    return config->card_info[index].next_Card_Index;
}            



/*************************************************************/
/*             Reads out Gretina (Mark I) cards.             */
/*************************************************************/

int32_t Readout_Gretina(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{

#define kGretinaPacketSeparater 0xAAAAAAAA
#define kGretinaNumberWordsMask 0x07FF0000
	
    TUVMEDevice* vmeReadOutHandle = 0;
    TUVMEDevice* vmeFIFOStateReadOutHandle = 0;
    TUVMEDevice* vmeDMADevice = 0;
    uint32_t fifoState;

    uint32_t baseAddress      = config->card_info[index].base_add;
    uint32_t fifoStateAddress = config->card_info[index].deviceSpecificData[0];
    uint32_t fifoEmptyMask    = config->card_info[index].deviceSpecificData[1];
    uint32_t fifoAddress      = config->card_info[index].deviceSpecificData[2];
    uint32_t fifoAddressMod   = config->card_info[index].deviceSpecificData[3];
    uint32_t sizeOfFIFO       = config->card_info[index].deviceSpecificData[4];
    uint32_t dataId           = config->card_info[index].hw_mask[0];
    uint32_t slot             = config->card_info[index].slot;
    uint32_t crate            = config->card_info[index].crate;
    uint32_t location         = ((crate&0x0000000f)<<21) | ((slot& 0x0000001f)<<16);

    //read the fifo state
    int32_t result;
    fifoState = 0;

    if (config->card_info[index].add_mod == 0x29) {
        lock_device(vmeAM29Handle);
        result = read_device(vmeAM29Handle,(char*)&fifoState,2,fifoStateAddress); 
        unlock_device(vmeAM29Handle);
    } else {
        vmeFIFOStateReadOutHandle = vmeAM9Handle; 
        lock_device(vmeFIFOStateReadOutHandle);
        result = read_device(vmeFIFOStateReadOutHandle, (char*)&fifoState, 4, fifoStateAddress);
        unlock_device(vmeFIFOStateReadOutHandle);
    }
    
    if (result <= 0) {
        return config->card_info[index].next_Card_Index;
    }
     
    if ((fifoState & fifoEmptyMask) == 0 || (fifoAddressMod == 0x39 && (fifoState & fifoEmptyMask) != 0)) {
        if (fifoAddressMod == 0x39) {
            vmeReadOutHandle = vmeAM39Handle;
        } else {
            vmeReadOutHandle = vmeAM9Handle;
        }
       
        uint32_t numLongs = 3;
        int32_t savedIndex = dataIndex;
        data[dataIndex++] = dataId | 0; //we'll fill in the length later
        data[dataIndex++] = location;
        
        //read the first int32_tword which should be the packet separator: 0xAAAAAAAA
        uint32_t theValue;
        lock_device(vmeReadOutHandle);
        result = read_device(vmeReadOutHandle,(char*)&theValue,4,fifoAddress); 
        
        if (result == 4 && (theValue==kGretinaPacketSeparater)){
            //read the first word of actual data so we know how much to read
            result = read_device(vmeReadOutHandle,(char*)&theValue,4,fifoAddress); 
            unlock_device(vmeReadOutHandle);
            
            data[dataIndex++] = theValue;
            uint32_t numLongsLeft  = ((theValue & kGretinaNumberWordsMask)>>16)-1;
            int32_t totalNumLongs  = (numLongs + numLongsLeft);
             
       
            /* OK, now use dma access. */
            if (fifoAddressMod == 0x39) {
                /* Gretina I card */
                vmeDMADevice = get_dma_device(fifoAddress, fifoAddressMod, 4, false);
            } else {
                /* Gretina IV card */
                vmeDMADevice = get_dma_device(fifoAddress, fifoAddressMod, 4, true);
            }
       
            if (vmeDMADevice == NULL) {
                return config->card_info[index].next_Card_Index;
            }
            
            result = read_device(vmeDMADevice,(char*)(&data[dataIndex]),numLongsLeft*4, 0); 
            release_dma_device();
            dataIndex += numLongsLeft;
            
            if (result != numLongsLeft*4) {
                return config->card_info[index].next_Card_Index;
            }
            data[savedIndex] |= totalNumLongs; //see, we did fill it in...
       
        } else if(result < 0) {
            unlock_device(vmeReadOutHandle);
            LogBusError("Rd Err: Gretina 0x%04x %s",baseAddress,strerror(errno));
        } else {
            //oops... really bad -- the buffer read is out of sequence -- try to recover 
            LogError("Rd Err: Gretina 0x%04x Buffer out of sequence, trying to recover",baseAddress);
            uint32_t i = 0;
            while(i < sizeOfFIFO) {
                result = read_device(vmeReadOutHandle,(char*) (&theValue),4,fifoAddress); 
                if (result == 0) { // means the FIFO is empty
                    unlock_device(vmeReadOutHandle);
                    return config->card_info[index].next_Card_Index;
                } else if (result < 0) {
                    unlock_device(vmeReadOutHandle);
                    LogBusError("Rd Err: Gretina4 0x%04x %s",baseAddress,strerror(errno));
                    return config->card_info[index].next_Card_Index;
                }
                if (theValue == kGretinaPacketSeparater) break;
                i++;
            }
            //read the first word of actual data so we know how much to read
            //note that we are NOT going to save the data, but we do use the data buffer to hold the garbage
            //we'll reset the index to dump the data later....
            result = read_device(vmeReadOutHandle,(char*)&theValue,4,fifoAddress); 
            unlock_device(vmeReadOutHandle);
           
            if (result < 0) {
                LogBusError("Rd Err: Gretina4 0x%04x %s",baseAddress,strerror(errno));                
                return config->card_info[index].next_Card_Index;
            }
            uint32_t numLongsLeft  = ((theValue & kGretinaNumberWordsMask)>>16)-1;
             
            /* OK, now use dma access. */
            if (fifoAddressMod == 0x39) {
                /* Gretina I card */
                vmeDMADevice = get_dma_device(fifoAddress, fifoAddressMod, 4, false);
            } 
            else {
                /* Gretina IV card */
                vmeDMADevice = get_dma_device(fifoAddress, fifoAddressMod, 4, true);
            }
            if (vmeDMADevice == NULL) {
                LogBusError("Rd Err: Gretina4 0x%04x %s",baseAddress,strerror(errno));
                return config->card_info[index].next_Card_Index;
            }
            result = read_device(vmeDMADevice,(char*)(&data[dataIndex]),numLongsLeft*4, 0); 
            release_dma_device();
            if (result < 0) {
                LogBusError("Rd Err: Gretina4 0x%04x %s",baseAddress,strerror(errno));
                return config->card_info[index].next_Card_Index;
            }
            dataIndex = savedIndex; //DUMP the data by reseting the data Index back to where it was when we got it.
        }
    }
    return config->card_info[index].next_Card_Index;

}            

/*************************************************************/
/*             Reads out CAEN cards.                         */
/*************************************************************/

int32_t Readout_CAEN(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{

#define kCaen_Header               0x2
#define kCaen_ValidDatum           0x0
#define kCaen_EndOfBlock           0x4
#define kCaen_NotValidDatum        0x6    
#define kCaen_DataWordTypeMask     0x07000000
#define kCaen_DataWordTypeShift    24
#define kCaen_DataChannelCountMask 0x00003f00
#define kCaen_DataChannelCoutShift 8

#define isValidCaenData(x)       ((((x) & kCaen_DataWordTypeMask) >> kCaen_DataWordTypeShift) == kCaen_ValidDatum)
#define isNotValidCaenData(x)    ((((x) & kCaen_DataWordTypeMask) >> kCaen_DataWordTypeShift) == kCaen_NotValidDatum)
#define isCaenHeader(x)          ((((x) & kCaen_DataWordTypeMask) >> kCaen_DataWordTypeShift) == kCaen_Header)
#define isCaenEndOfBlock(x)      ((((x) & kCaen_DataWordTypeMask) >> kCaen_DataWordTypeShift) == kCaen_EndOfBlock)
#define caenDataChannelCount(x)  (((x) & kCaen_DataChannelCountMask) >> kCaen_DataChannelCoutShift)

  
    /* The deviceSpecificData is as follows:          */ 
    /* 0: statusOne register                          */
    /* 1: statusTwo register                          */
    /* 2: fifo buffer size (in longs)                 */
    /* 3: fifo buffer address                         */
    
    uint16_t statusOne, statusTwo;
    
    uint32_t baseAddress      = config->card_info[index].base_add;
    uint32_t statusOneAddress = baseAddress + config->card_info[index].deviceSpecificData[0];
    uint32_t statusTwoAddress = baseAddress + config->card_info[index].deviceSpecificData[1];
    uint32_t fifoAddress      = baseAddress + config->card_info[index].deviceSpecificData[3];
    
    uint32_t dataId      = config->card_info[index].hw_mask[0];
    uint32_t slot        = config->card_info[index].slot;
    uint32_t crate       = config->card_info[index].crate;
    int32_t result;

    //read the states
    lock_device(vmeAM39Handle);
    result = read_device(vmeAM39Handle,(char*)&statusOne,2,statusOneAddress); 
    if (result != 2) {
        unlock_device(vmeAM39Handle);
        LogBusError("CAEN 0x%0x status 1 read",baseAddress);
        return config->card_info[index].next_Card_Index;
    }

    result = read_device(vmeAM39Handle,(char*)&statusTwo,2,statusTwoAddress); 
    if (result != 2) {
        unlock_device(vmeAM39Handle);
        LogBusError("CAEN 0x%0x status 2 read",baseAddress);
        return config->card_info[index].next_Card_Index;
    }

    uint8_t bufferIsNotBusy =  !((statusOne & 0x0004) >> 2);
    uint8_t dataIsReady     =  statusOne & 0x0001;
    uint8_t bufferIsFull    =  (statusTwo & 0x0004) >> 2;

    if ((bufferIsNotBusy && dataIsReady) || bufferIsFull) {
    
        uint32_t dataValue;
        //read the first word, could be a header, or the buffer could be empty now
        result = read_device(vmeAM39Handle,(char*)&dataValue,4,fifoAddress); 
        if (result != 4) {
            unlock_device(vmeAM39Handle);
            LogBusError("CAEN 0x%0x FIFO header read",baseAddress);
            return config->card_info[index].next_Card_Index;
        }
                                
        if(!isNotValidCaenData(dataValue)) {
        
            //OK some data is apparently in the buffer and is valid
            uint32_t dataIndexStart = dataIndex; //save the start index in case we have to flush the data because of errors
            dataIndex += 2;                         //reserve two words for the ORCA header, we'll fill it in if we get valid data

            if(isCaenHeader(dataValue)) {
                //got a header, store it
                data[dataIndex++] = dataValue;
            } else {
                //error--flush buffer
                flush_CAEN_Fifo(config,index);
                unlock_device(vmeAM39Handle);
                return config->card_info[index].next_Card_Index;
            }
            
            //read out the channel count
            int32_t n = caenDataChannelCount(dataValue); //decode the channel from the data word
            int32_t i;
            for(i=0;i<n;i++){
                result = read_device(vmeAM39Handle,(char*)&dataValue,4,fifoAddress); 
                if (result != 4) {
                    unlock_device(vmeAM39Handle);
                    LogBusError("CAEN 0x%0x fifo read",baseAddress);
                    dataIndex = dataIndexStart; //don't allow this data out.
                    return config->card_info[index].next_Card_Index;
                }
            
                if(isValidCaenData(dataValue)){
                    data[dataIndex++] = dataValue;
                }
                else {
                    //oh-oh. big problems flush the buffer.
                    LogError("CAEN 0x%0x fifo flushed",baseAddress);
                    dataIndex = dataIndexStart; //don't allow this data out.
                    flush_CAEN_Fifo(config,index);
                    unlock_device(vmeAM39Handle);
                    return config->card_info[index].next_Card_Index;
                }
            }
                        
            //read the end of block
            result = read_device(vmeAM39Handle,(char*)&dataValue,4,fifoAddress); 
            if (result != 4) {
                LogBusError("CAEN 0x%0x EOB read",baseAddress);
                dataIndex = dataIndexStart; //don't allow this data out.
            }

            if(isCaenEndOfBlock(dataValue)){
                data[dataIndex++] = dataValue;
                //OK, it looks like this data block is valid, so fill in the header
                data[dataIndexStart] = dataId |  ((dataIndex-dataIndexStart) & 0x3ffff);
                data[dataIndexStart+1] = ((crate&0x0000000f)<<21) | ((slot& 0x0000001f)<<16);
            }
            else {
                //error...the end of block not where we expected it
                LogError("CAEN 0x%0x fifo flushed",baseAddress);
                dataIndex = dataIndexStart; //don't allow this data out.
                flush_CAEN_Fifo(config,index);
            }
        }
    }

    unlock_device(vmeAM39Handle);
    return config->card_info[index].next_Card_Index;
}

void flush_CAEN_Fifo(SBC_crate_config* config,int32_t index)
{
    /* The vmeAM39Handle device *must* be locked before calling this function. */
    uint32_t fifoSize    = config->card_info[index].deviceSpecificData[3];
    uint32_t fifoAddress = config->card_info[index].base_add + config->card_info[index].deviceSpecificData[4];
    
    int32_t i;
    uint32_t dataValue;
    for(i=0;i<fifoSize;i++){
        int32_t result = read_device(vmeAM39Handle,(char*)&dataValue,4,fifoAddress); 
        if (result != 4) {
            LogBusError("CAEN 0x%0x Couldn't flush fifo",config->card_info[index].base_add);
            break;
        }
    }
}

/*************************************************************/
/*             Readout_LAM_Data                                     */
/*************************************************************/
int32_t Readout_LAM_Data(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    //this is a pseudo object that doesn't read any hardware, it just passes information back to ORCA
    lamData->lamNumber = config->card_info[index].slot;

    SBC_Packet lamPacket;
    lamPacket.cmdHeader.destination           = kSBC_Process;
    lamPacket.cmdHeader.cmdID                 = kSBC_LAM;
    lamPacket.cmdHeader.numberBytesinPayload  = sizeof(SBC_LAM_Data);
    
    memcpy(&lamPacket.payload, lamData, sizeof(SBC_LAM_Data));
    postLAM(&lamPacket);
    
    return config->card_info[index].next_Card_Index;
}            

