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
#include "VME_Trigger32.h"
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

void startHWRun (SBC_crate_config* config)
{    
    int32_t index = 0;
	while(1){
        switch(config->card_info[index].hw_type_id){
            default:     index =  -1; break;
        }
        if(index>=config->total_cards || index<0)break;
    }
	int32_t i;
	for(i=0;i<32;i++)sis3300CurrentBank[i]=0;
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

int32_t readHW(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    if(index<config->total_cards && index>=0) {
        switch(config->card_info[index].hw_type_id){
            case kDataGen:       index = Readout_DataGen(config,index,lamData);      break;
            case kShaper:       index = Readout_Shaper(config,index,lamData);       break;
            case kGretina:      index = Readout_Gretina(config,index,lamData);      break;
            case kTrigger32:    index = Readout_TR32_Data(config,index,lamData);    break;
            case kCaen:         index = Readout_CAEN(config,index,lamData);         break;
            case kSBCLAM:       index = Readout_LAM_Data(config,index,lamData);     break;
            case kCaen1720:     index = Readout_CAEN1720(config,index,lamData);		break;
            case kMtc:			index = Readout_MTC(config,index,lamData);			break;
            case kFec:			index = Readout_Fec(config,index,lamData);			break;
            case kSIS3300:		index = Readout_SIS3300(config,index,lamData);		break;
            case kCaen419:      index = Readout_CAEN419(config,index,lamData);      break;
            case kSIS3350:      index = Readout_SIS3350(config,index,lamData);      break;
            default:            index = -1;                                         break;
        }
        return index;
    }
    else return -1;
}

/*************************************************************/
/*             Reads out Test Data Generator.                       */
/*************************************************************/
int32_t Readout_DataGen(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
	uint32_t dataId1D             = config->card_info[index].hw_mask[0];
	uint32_t dataId2D             = config->card_info[index].hw_mask[1];
	uint32_t dataIdWaveform		  = config->card_info[index].hw_mask[2];
	
	if(random()%500 > 495 ){
		
		uint32_t card = random()%2;
		uint32_t chan = random()%8;
		uint32_t aValue = (100*chan) + ((random()%500 + random()%500 + random()%500)/3);
		if(card==0 && chan ==0)aValue = 100;
		data[dataIndex++] = dataId1D | 2;
		data[dataIndex++] = (card<<16) | (chan << 12) | (aValue & 0x0fff);
		
		data[dataIndex++] = dataId2D | 3;
		aValue = 64 + ((random()%128 + random()%128 + random()%128)/3);
		data[dataIndex++] = (aValue & 0x0fff); //card 0, chan 0
		aValue = 64 + ((random()%64 + random()%64 + random()%64)/3);
		data[dataIndex++] = (aValue & 0x0fff);
	}
	
	if(random()%20000 > 19998 ){
		data[dataIndex++] = dataIdWaveform | (2048+2);
		data[dataIndex++] = 0x00001000; //card 0, chan 1
		float radians = 0;
		float delta = 2*3.141592/360.;
		int32_t i;
		for(i=0;i<2048;i++){
			data[dataIndex++] = (int32_t)(2*sin(4*radians));
			radians += delta;
		}	
		
		data[dataIndex++] = dataIdWaveform | (2048+2);
		data[dataIndex++] = 0; //card 0, chan 0
		int32_t a1 = (random()%20);
		int32_t a2 = (random()%20);
		for(i=0;i<2048;i++){
			data[dataIndex++] = (int32_t)((a1*sin(radians)) + (a2*sin(2*radians)));
			radians += delta;
		}
	}
	
    return config->card_info[index].next_Card_Index;
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
/*             Reads out SIS3300 cards.                       */
/*************************************************************/
int32_t Readout_SIS3300(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
	
#define kSISBank1ClockStatus	0x00000001
#define kSISBank2ClockStatus	0x00000002
#define kSISBank1BusyStatus		0x00100000
#define kSISBank2BusyStatus		0x00400000
#define kTriggerEvent1DirOffset 0x101000
#define kTriggerEvent2DirOffset 0x102000
#define kTriggerTime1Offset		0x1000
#define kTriggerTime2Offset		0x2000
#define kSISAcqReg				0x10		// [] Acquistion Reg
#define kStartSampling			0x30		// [] Start Sampling
#define kClearBank1FullFlag		0x48		// [] Clear Bank 1 Full Flag
#define kClearBank2FullFlag		0x4C		// [] Clear Bank 2 Full Flag
#define kSISSampleBank1			0x0001L
#define kSISSampleBank2			0x0002L

	static uint32_t eventCountOffset[4][2]={ //group,bank
			{0x00200010,0x00200014},
			{0x00280010,0x00280014},
			{0x00300010,0x00300014},
			{0x00380010,0x00380014},
		};
		
	static uint32_t bankMemory[4][2]={
			{0x00400000,0x00600000},
			{0x00480000,0x00680000},
			{0x00500000,0x00700000},
			{0x00580000,0x00780000},
		};	

    uint32_t baseAddress       = config->card_info[index].base_add;
    uint32_t theMod			   = config->card_info[index].add_mod;
	uint32_t dataId            = config->card_info[index].hw_mask[0];
	uint32_t slot              = config->card_info[index].slot;
	uint32_t crate             = config->card_info[index].crate;
	uint32_t locationMask      = ((crate & 0x0000000f)<<21) | ((slot & 0x0000001f)<<16);
	uint32_t bankSwitchMode	   = config->card_info[index].deviceSpecificData[0];
	uint32_t numberOfSamples   = config->card_info[index].deviceSpecificData[1];
	uint32_t moduleID		   = config->card_info[index].deviceSpecificData[2];
	int32_t result;

    TUVMEDevice* vmeReadOutHandle = get_new_device(baseAddress, theMod, 4, 0);
	if ( vmeReadOutHandle == NULL ) {
		LogBusError("No vmeAM9Handle: %s 0x%08x",strerror(errno),baseAddress);
		return config->card_info[index].next_Card_Index;
	}
	uint32_t currentBank = sis3300CurrentBank[crate];
	
	uint32_t mask;
	
	//read the acq register and decode the bank full and bank busy bits
	uint32_t theValue;
	result = read_device(vmeReadOutHandle,(char*)&theValue,4,kSISAcqReg); 
	if (result < 4){
		LogBusError("Rd Err0: SIS3300 0x%04x %s",kSISAcqReg,strerror(errno));
		close_device(vmeReadOutHandle);
		return config->card_info[index].next_Card_Index;
	}
	mask = (currentBank?kSISBank2ClockStatus : kSISBank1ClockStatus);
	uint32_t bankIsFull = ((theValue & mask) == 0);
	
	mask =  (currentBank?kSISBank2BusyStatus : kSISBank1BusyStatus);
	uint32_t bankIsBusy = ((theValue & mask) != 0);
	
	if(bankIsFull && !bankIsBusy) {
		int bankToUse = currentBank;
		//read the number of events
		int numEvents;
		result = read_device(vmeReadOutHandle,(char*)&numEvents,4,eventCountOffset[bankToUse][0]); 
		if (result < 4){
			LogBusError("Rd Err1: SIS3300 0x%04x %s",eventCountOffset[bankToUse][0],strerror(errno));
			close_device(vmeReadOutHandle);
			return config->card_info[index].next_Card_Index;
		}
		uint32_t event,group;
		for(event=0;event<numEvents;event++){
			
			//read the trigger Event Directory
			uint32_t triggerEventBankReg = (bankToUse?kTriggerEvent2DirOffset:kTriggerEvent1DirOffset) + (event*sizeof(uint32_t));
			uint32_t triggerEventDir;
			result = read_device(vmeReadOutHandle,(char*)&triggerEventDir,4,triggerEventBankReg); 
			if (result < 4){
				LogBusError("Rd Err2: SIS3300 0x%04x %s",triggerEventBankReg,strerror(errno));
				close_device(vmeReadOutHandle);
				return config->card_info[index].next_Card_Index;
			}
			
			uint32_t startOffset = (triggerEventDir&0x1ffff) & (numberOfSamples-1);
			
			uint32_t triggerTime;
			uint32_t triggerTriggerReg = (bankToUse?kTriggerTime2Offset:kTriggerTime1Offset) + event*sizeof(long);
			result = read_device(vmeReadOutHandle,(char*)&triggerTime,4,triggerTriggerReg); 
			if (result < 4){
				LogBusError("Rd Err3: SIS3300 0x%04x %s",triggerTriggerReg,strerror(errno));
				close_device(vmeReadOutHandle);
				return config->card_info[index].next_Card_Index;
			}
			
			for(group=0;group<4;group++){
				uint32_t channelMask = triggerEventDir & (0xC0000000 >> (group*2));
				if(channelMask==0)continue;
				
				//only read the channels that have trigger info
				uint32_t totalNumLongs = numberOfSamples + 4;
				uint32_t startIndex = dataIndex;
				data[dataIndex++] = dataId | totalNumLongs; //but we are going to write over this below
				data[dataIndex++] = locationMask | ((moduleID==0x3301) ? 1:0);
				
				data[dataIndex++] = triggerEventDir & (channelMask | 0x00FFFFFF);
				data[dataIndex++] = ((event&0xFF)<<24) | (triggerTime & 0xFFFFFF);
			
				// The first read is from startOffset -> nPagesize.
				uint32_t nLongsToRead = numberOfSamples - startOffset;	
				if(nLongsToRead>0){
					TUVMEDevice* sis3300DMADevice = get_dma_device(baseAddress+bankMemory[group][bankToUse] + 4*startOffset, theMod, 4, true);
					if (sis3300DMADevice == NULL) {
						LogBusError("DMA1: SIS3300 Rd Error: %s",strerror(errno));
						dataIndex = startIndex; //dump the record
						close_device(vmeReadOutHandle);
						release_dma_device();
						return config->card_info[index].next_Card_Index;
					}
					result = read_device(sis3300DMADevice,(char*)&data[dataIndex],nLongsToRead*4, 0); 
					//result = read_device(vmeReadOutHandle,(char*)&data[dataIndex],nLongsToRead*4, bankMemory[group][bankToUse] + 4*startOffset); 
					if (result < nLongsToRead*4){
						dataIndex = startIndex; //dump the record
						LogBusError("DMA2: SIS3300 Rd Error: %s",strerror(errno));
						close_device(vmeReadOutHandle);
						release_dma_device();
						return config->card_info[index].next_Card_Index;
					}
					
					dataIndex +=  nLongsToRead;
					release_dma_device();
				}
				
				// The second read, if necessary, is from 0 ->nEventEnd-1.
				if(startOffset>0) {
					TUVMEDevice* sis3300DMADevice = get_dma_device(baseAddress+bankMemory[group][bankToUse], theMod, 4, true);
					if (sis3300DMADevice == NULL) {
						dataIndex = startIndex; //dump the record
						close_device(vmeReadOutHandle);
						release_dma_device();
						return config->card_info[index].next_Card_Index;
					}
					result = read_device(sis3300DMADevice,(char*)&data[dataIndex],startOffset*4, 0); 
					//result = read_device(vmeReadOutHandle,(char*)&data[dataIndex],startOffset*4, bankMemory[group][bankToUse]); 
				
					if (result < startOffset*4){
						dataIndex = startIndex; //dump the record
						LogBusError("Rd Err5: SIS3300 0x%04x %s",bankMemory[group][bankToUse],strerror(errno));
						close_device(vmeReadOutHandle);
						release_dma_device();
						return config->card_info[index].next_Card_Index;
					}
					dataIndex +=  startOffset;
					release_dma_device();
				}
				data[startIndex] = dataId | dataIndex;
				//we ship from here to prevent putting too much data into the data array
				if(dataIndex>0){
					if(needToSwap)SwapLongBlock(data, dataIndex);
					CB_writeDataBlock(data,dataIndex);
					dataIndex = 0;
				}
				index = 0;
				
			}
			 
		}
		
		uint32_t clearBankReg = (currentBank?kClearBank2FullFlag:kClearBank1FullFlag);
		uint32_t dummy = 0;
		result = write_device(vmeReadOutHandle,(char*)&dummy,4,clearBankReg);
		if (result < 4){
			LogBusError("Rd Err6: SIS3300 0x%04x %s",clearBankReg,strerror(errno));
			close_device(vmeReadOutHandle);
			release_dma_device();
			return config->card_info[index].next_Card_Index;
		}		
		if(bankSwitchMode) {
			currentBank= (currentBank+1)%2;
			sis3300CurrentBank[crate] = currentBank;
		}
				
		//Arm the current Bank
		uint32_t armBit = (currentBank?kSISSampleBank2:kSISSampleBank1);
		result = write_device(vmeReadOutHandle,(char*)&armBit,4,kSISAcqReg);
		if (result < 4){
			LogBusError("Rd Err7: SIS3300 0x%04x %s",kSISAcqReg,strerror(errno));
			close_device(vmeReadOutHandle);
			release_dma_device();
			return config->card_info[index].next_Card_Index;
		}		
		//Start Sampling
		result = write_device(vmeReadOutHandle,(char*)&dummy,4,kStartSampling);
		if (result < 4){
			LogBusError("Rd Err8: SIS3300 0x%04x %s",kStartSampling,strerror(errno));
			close_device(vmeReadOutHandle);
			release_dma_device();
			return config->card_info[index].next_Card_Index;
		}
	}
	
	close_device(vmeReadOutHandle);
	
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
/*             Reads out Caen419 cards.                       */
/*************************************************************/
int32_t Readout_CAEN419(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    uint32_t baseAddress        = config->card_info[index].base_add;
	uint32_t dataId             = config->card_info[index].hw_mask[0];
	uint32_t slot               = config->card_info[index].slot;
	uint32_t crate              = config->card_info[index].crate;
	uint32_t locationMask       = ((crate & 0x01e)<<21) | ((slot & 0x0000001f)<<16);
    uint32_t enabledMask		= config->card_info[index].deviceSpecificData[0];
	uint32_t firstStatusRegOffset = config->card_info[index].deviceSpecificData[1];
 	uint32_t firstAdcRegOffset  = config->card_info[index].deviceSpecificData[2];
   
    lock_device(vmeAM39Handle);
	int chan;
	for(chan=0;chan<4;chan++){
		if(enabledMask & (1<<chan)){
			uint16_t theStatusReg;
			int32_t result = read_device(vmeAM39Handle,(char*)&theStatusReg,sizeof(theStatusReg),baseAddress+firstStatusRegOffset+(chan*4));
			if(result == sizeof(theStatusReg) && (theStatusReg&0x8000)){
				uint16_t aValue;
				result  = read_device(vmeAM39Handle,(char*)&aValue,sizeof(aValue),baseAddress+firstAdcRegOffset+(chan*4));
				if(result == sizeof(aValue)){
					if(((dataId) & 0x80000000)){ //short form
						data[dataIndex++] = dataId | locationMask | ((chan & 0x0000000f) << 12) | (aValue & 0x0fff);
					} 
					else { //long form
						data[dataIndex++] = dataId | 2;
						data[dataIndex++] = locationMask | ((chan & 0x0000000f) << 12) | (aValue & 0x0fff);
					}
				} 
				else if (result < 0)LogBusError("Rd Err: Shaper 0x%04x %s",baseAddress,strerror(errno));                
			} 
			else if (result < 0)LogBusError("Rd Err: Shaper 0x%04x %s",baseAddress,strerror(errno));   
		}
	}
    unlock_device(vmeAM39Handle);
	
    return config->card_info[index].next_Card_Index;
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

/*************************************************************/
/*             Reads out SIS3350 cards.                       */
/*************************************************************/
int32_t Readout_SIS3350(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
	//static uint32_t actualSampleAddressOffsets[4] = {0x02000010, 0x02000014, 0x03000010, 0x03000014};	
	static uint32_t adcOffsets[4]		= {0x04000000, 0x05000000, 0x06000000, 0x07000000};
	static uint32_t channelOffsets[4]	= {0x02000000, 0x02000000, 0x03000000, 0x03000000};	
	static uint32_t endOfEventOffset[4] = {0x10, 0x14, 0x10, 0x14};	
	
    uint32_t baseAddress    = config->card_info[index].base_add;
    uint32_t theMod			= config->card_info[index].add_mod;
	uint32_t dataId         = config->card_info[index].hw_mask[0];
	uint32_t slot           = config->card_info[index].slot;
	uint32_t crate          = config->card_info[index].crate;
    uint32_t operationMode	= config->card_info[index].deviceSpecificData[0];
	uint32_t wrapLength	= config->card_info[index].deviceSpecificData[1];
	uint32_t locationMask   = ((crate & 0x0000000f)<<21) | ((slot & 0x0000001f)<<16);
	
	TUVMEDevice* baseAddressHandle = get_new_device(baseAddress, theMod, 4, 0x2000000);
	if ( baseAddressHandle != NULL ) {
		uint32_t status = 0;
		if(read_device(baseAddressHandle,(char*)&status,4,0x10) == 4) {	//Check Acq Control Reg
			char thereWasAnEvent = 0;
			if(operationMode == 0 || operationMode == 2){
				if((status & 0x00080000) == 0x00080000)thereWasAnEvent = 1;
			}
			else {
				if((status & 0x00010000) != 0x00010000)thereWasAnEvent = 1;
			}
			if(thereWasAnEvent){					//check that the arm bit falls to zero
				if(operationMode == 0 || operationMode == 2){
					//if op mode is kOperationRingBufferAsync or kOperationDirectMemoryGateAsync -- must disarm sampling
					uint32_t disarmIt = 1; //rearm by writing anything to the sample arm register
					if(write_device(baseAddressHandle,(char*)&disarmIt,4,0x0414) != 4){ //sample disarm register
						LogBusError("SIS3350 VME Exception 1: %s 0x%08x",strerror(errno),baseAddress);
					}
				}
				uint16_t i;
				uint32_t stop_next_sample_addr[4] = {0,0,0,0};
				for(i=0;i<4;i++){
					//we have to be a little tricky here... apparently this device's memory map is too large so we have 
					//to get new devices from the driver at difference base addresses.
					TUVMEDevice* channelBaseReadoutHandle = get_new_device(baseAddress+channelOffsets[i] , theMod, 4, 0x2000000);
					if ( channelBaseReadoutHandle != NULL ) {
						//read out the endofSample Reg to see if a channel has data
						if(read_device(channelBaseReadoutHandle,(char*)&stop_next_sample_addr[i],4,endOfEventOffset[i]) == 4) {
							if (stop_next_sample_addr[i] != 0) {
								if (stop_next_sample_addr[i] > 65536){
									stop_next_sample_addr[i] = 65536;
								}
							}
						}
						close_device(channelBaseReadoutHandle);
					} else LogBusError("No SIS3350 VME Handle 2: %s 0x%08x",strerror(errno),baseAddress+channelOffsets[i]);
				}
					
				for(i=0;i<4;i++){
					if(stop_next_sample_addr[i] != 0){
						//we have to be a little tricky here... apparently this device's memory map is too large so we have 
						//to get new devices from the driver at difference base addresses.
						TUVMEDevice* adcBaseHandle = get_dma_device(baseAddress+adcOffsets[i], theMod, 4, true);
						if ( adcBaseHandle != NULL ) {
							unsigned long numLongWords = stop_next_sample_addr[i]/2;
							uint32_t startIndex = dataIndex;
							data[dataIndex++] = dataId | (numLongWords + 2);
							data[dataIndex++] = locationMask | i;
							
							if(read_device(adcBaseHandle,(char*)(&data[dataIndex]),numLongWords*4, 0) == (numLongWords*4)){
								dataIndex += numLongWords;	
								if(operationMode == 4){
									//the kOperationDirectMemoryStop mode requires the data to be reordered
									reOrderOneSIS3350Event(&data[startIndex],dataIndex-startIndex+1,wrapLength);
								}
							}
							else {
								LogBusError("SIS3350 VME Exception 3: %s 0x%08x",strerror(errno),baseAddress+adcOffsets[i]);
								dataIndex = startIndex; //dump the record
							}
							release_dma_device();
						} else LogBusError("No SIS3350 VME Handle 5: %s 0x%08x",strerror(errno),baseAddress+adcOffsets[i]);
					}
				} //end of readout for loop
				
				uint32_t armIt = 1; //rearm by writing anything to the sample arm register
				if(write_device(baseAddressHandle,(char*)&armIt,4,0x0410) != 4){ //sample arm register
					LogBusError("SIS3350 VME Exception 6: %s 0x%08x",strerror(errno),baseAddress);
				}
			}
		} //End Check Acq Control Reg
		close_device(baseAddressHandle);
	} else LogBusError("No SIS3350 VME Handle: %s 0x%08x",strerror(errno),baseAddress);
	
    return config->card_info[index].next_Card_Index;
}

void reOrderOneSIS3350Event(int32_t* inDataPtr, uint32_t dataLength, uint32_t wrapLength)
{
	unsigned long i;
	int32_t* outDataPtr = (int32_t*)malloc(dataLength*sizeof(uint32_t));
	unsigned long lword_length     = 0;
	unsigned long lword_stop_index = 0;
	unsigned long lword_wrap_index = 0;
	
	unsigned long wrapped	   = 0;
	unsigned long stopDelayCounter=0;
	
	unsigned long event_sample_length = wrapLength;
	
	if (dataLength != 0) {
		outDataPtr[0] = inDataPtr[0]; //copy ORCA header
		outDataPtr[1] = inDataPtr[1]; //copy ORCA header
		
		unsigned long index = 2;
		
		outDataPtr[index]   = inDataPtr[index];		// copy Timestamp	
		outDataPtr[index+1] = inDataPtr[index+1];	// copy Timestamp	    
		
		wrapped			 =   ((inDataPtr[4]  & 0x08000000) >> 27); 
		stopDelayCounter =   ((inDataPtr[4]  & 0x03000000) >> 24); 
		
		unsigned long stopAddress =   ((inDataPtr[index+2]  & 0x7) << 24)  
									+ ((inDataPtr[index+3]  & 0xfff0000 ) >> 4) 
									+  (inDataPtr[index+3]  & 0xfff);
		
		
		// write event length 
		outDataPtr[index+3] = (((event_sample_length) & 0xfff000) << 4)			// bit 23:12
							+ ((event_sample_length) & 0xfff);					// bit 11:0 
		
		outDataPtr[index+2] = (((event_sample_length) & 0x7000000) >> 24)		// bit 23:12
							+ (inDataPtr[index+2]  & 0x0F000000);				// Wrap arround flag and stopDelayCounter
		
		
		lword_length = event_sample_length/2;
		// stop delay correction
		if ((stopAddress/2) < stopDelayCounter) {
			lword_stop_index = lword_length + (stopAddress/2) - stopDelayCounter;
		}
		else {
			lword_stop_index = (stopAddress/2) - stopDelayCounter;
		}
		
		// rearange
		if (wrapped) { // all samples are vaild
			for (i=0;i<lword_length;i++){
				lword_wrap_index =   lword_stop_index + i;
				if  (lword_wrap_index >= lword_length) {
					lword_wrap_index = lword_wrap_index - lword_length; 
				} 
				outDataPtr[index+4+i] =  inDataPtr[index+4+lword_wrap_index]; 
			}
		}
		else { // only samples from "index" to "stopAddress" are valid
			for (i=0;i<lword_length-lword_stop_index;i++){
				lword_wrap_index =   lword_stop_index + i;
				if  (lword_wrap_index >= lword_length) {lword_wrap_index = lword_wrap_index - lword_length; } 
				outDataPtr[index+4+i] =  0; 
			}
			for (i=lword_length-lword_stop_index;i<lword_length;i++){
				lword_wrap_index =   lword_stop_index + i;
				if  (lword_wrap_index >= lword_length) {lword_wrap_index = lword_wrap_index - lword_length; } 
				outDataPtr[index+4+i] =  inDataPtr[index+4+lword_wrap_index]; 
			}
		}
	}
	memcpy(inDataPtr, outDataPtr, dataLength*sizeof(uint32_t));
	free(outDataPtr);
}

