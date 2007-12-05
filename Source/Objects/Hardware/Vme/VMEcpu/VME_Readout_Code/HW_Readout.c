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
#include "SBC_Cmds.h"
#include "SBC_Config.h"
#include "vme_api.h"
#include "HW_Readout.h"
#include "SBC_Readout.h"
#include <errno.h>
#include "CircularBuffer.h"
#include "VME_HW_Definitions.h"

void SwapLongBlock(void* p, int32_t n);
void SwapShortBlock(void* p, int32_t n);
int32_t writeBuffer(SBC_Packet* aPacket);


extern char needToSwap;

static int32_t vmeAM29Handle;
static int32_t controlHandle;

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
    /* TBD **** MUST add some error checking here */

    vmeAM29Handle = vme_openDevice( "lsi1" );
    controlHandle = vme_openDevice( "ctl" );

    int32_t result;

    //VME_USER_AM userModifierCodes;
    //userModifierCodes.user1 = 0x20;
    //userModifierCodes.user2 = 0x39;
    
    //result = vme_setUserAmCodes( controlHandle, &userModifierCodes);   
    //printf("user code result: %d\n",result);
    //result = vme_setByteSwap(controlHandle,SWAP_MASTER | SWAP_SLAVE | SWAP_FAST);
    result = vme_setByteSwap(controlHandle, SWAP_MASTER);
    //printf("byte swap code result: %d\n",result);
    //result = vme_disableInterrupt(controlHandle,0);
    //printf("byte swap code result: %d\n",result);
   
    PCI_IMAGE_DATA idata;
    idata.pciAddress    = 0x0;            /* default -- let the cpu pick the address */
    idata.vmeAddress    = 0x0;            /* start at zero and map the ENTIRE short address space */
    idata.size            = 0x10000;        /* 64K, 16 bit address space */
    idata.dataWidth        = VME_D16;        /* 16 bit data */
    idata.addrSpace        = VME_A16;      /* address modifier 0x29 */
    //idata.addrSpace    = VME_USER1_AM; /* address modifier 0x29 */
    idata.postedWrites    = 0;
    idata.type            = LSI_DATA;     /* data AM code */
    idata.mode    = 0;            /* non-privileged */
    idata.vmeCycle        = 0;            /* no BLT's on VME bus */
    idata.pciBusSpace    = 0;            /* PCI bus memory space */
    idata.ioremap        = 1;            /* use ioremap */
    result = vme_enablePciImage( vmeAM29Handle, &idata );
    //printf("Pci image result: %d\n",result);
}

void ReleaseHardware(void)
{
    
    vme_closeDevice( vmeAM29Handle );
    vme_closeDevice( controlHandle );
}

int32_t openNewDevice(char* devName, SBC_VmeWriteBlockStruct* aPacket)
{
    /* Handles the opening of a new device and sets */
    /* First try to open the device. */
    static PCI_IMAGE_DATA imageData = { 0x0, 
                                        0x0, 
                                        0x10000, 
                                        0x0, 
                                        0x0, 
                                        0x0,
                                        0x0,
                                        0x0,
                                        0x0,
                                        0x0,
                                        0x1 };

    int32_t handler = vme_openDevice(devName);
    if (handler < 0) {
        return handler;
    } 
   
    /* Device is open, let's setup image. */
    imageData.vmeAddress = aPacket->address;

    uint8_t AM = aPacket->addressModifier;
    if ((AM & 0xF) <= 0x7) return -1;
    /* We are not equipped to handle other types of AMs.*/
    switch ((AM & 0x30) >> 4) { 
        case 3:
            imageData.addrSpace = VME_A24;
            break;
        case 2:
            imageData.addrSpace = VME_A16;
            break;
        case 1:
            /* User defined address space. */
            return -1;
            break;
        case 0:
            imageData.addrSpace = VME_A32;
            break;
    } 

    imageData.type = ((AM & 0x4) >> 2) ? LSI_SUPER : LSI_USER;
    imageData.vmeCycle = (((AM & 0x2) >> 1) ^ (AM & 0x1)) ? 0 : 1; 
      /* 1: BLT (Block Transfer)  */
      /* 0: Single-cycle transfer */
    imageData.type = (AM & 0x1) ? LSI_DATA : LSI_PGM; 
    if ((AM & 0x3) == 0x3) {
       imageData.dataWidth = VME_D64;
    } else {
        switch (aPacket->unitSize) {
            case 1:
                imageData.dataWidth = VME_D8; 
                break;
            case 2:
                imageData.dataWidth = VME_D16; 
                break;
            case 4:
                imageData.dataWidth = VME_D32; 
                break;
            case 8:
                imageData.dataWidth = VME_D64; 
                break;
        }
    }
    
   
    /* Now we create an image with the address as the base address. */
    int32_t result = vme_enablePciImage(handler, &imageData);
    if (result < 0) {
        return result;
    } 
    return handler; 
}

int32_t openNewDMADevice(SBC_VmeWriteBlockStruct* aPacket, uint32_t length)
{
    /* Handles the opening of a new device and sets */
    /* First try to open the device. */
    static VME_DIRECT_TXFER dmaData = { UNI_DMA_READ, 
                                        0x0, 
                                        0x0, 
                                        0x0, 
                                        {200, 0x0},
                                        {0x0, 0x0, 0x0, 0x0, 0x0}
                                        };

    int32_t handler = vme_openDevice("dma");
    if (handler < 0) {
        return handler;
    } 
   
    /* Device is open, let's setup image. */
    dmaData.vmeAddress = aPacket->address;

    uint8_t AM = aPacket->addressModifier;
    if ((AM & 0xF) <= 0x7) return -1;
    /* We are not equipped to handle other types of AMs.*/
    switch ((AM & 0x30) >> 4) { 
        case 3:
            dmaData.access.addrSpace = VME_A24;
            break;
        case 2:
            dmaData.access.addrSpace = VME_A16;
            break;
        case 1:
            /* User defined address space. */
            return -1;
            break;
        case 0:
            dmaData.access.addrSpace = VME_A32;
            break;
    } 

    dmaData.access.type = ((AM & 0x4) >> 2) ? LSI_SUPER : LSI_USER;
    dmaData.access.vmeCycle = (((AM & 0x2) >> 1) ^ (AM & 0x1)) ? 0 : 1; 
    dmaData.access.type = (AM & 0x1) ? LSI_DATA : LSI_PGM; 
    if ((AM & 0x3) == 0x3) {
       dmaData.access.dataWidth = VME_D64;
    } else {
        switch (aPacket->unitSize) {
            case 1:
                dmaData.access.dataWidth = VME_D8; 
                break;
            case 2:
                dmaData.access.dataWidth = VME_D16; 
                break;
            case 4:
                dmaData.access.dataWidth = VME_D32; 
                break;
            case 8:
                dmaData.access.dataWidth = VME_D64; 
                break;
        }
    }
    
    /* Now we create an image with the address as the base address. */
    dmaData.size = length;
    int32_t result = vme_allocDmaBuffer(handler, &(dmaData.size));
    if (result < 0) {
        return result;
    } 
    
    result = vme_dmaDirectTransfer(handler, &dmaData);
    if (result < 0) {
        return result;
    } 
    return handler;

}

int32_t closeDMADevice(int32_t deviceHandle)
{
  vme_freeDmaBuffer(deviceHandle);
  return vme_closeDevice(deviceHandle);
}



int32_t closeDevice(int32_t deviceHandle)
{
  vme_disablePciImage(deviceHandle);
  return vme_closeDevice(deviceHandle);
}


void doWriteBlock(SBC_Packet* aPacket)
{
    SBC_VmeWriteBlockStruct* p = (SBC_VmeWriteBlockStruct*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_VmeWriteBlockStruct)/sizeof(int32_t));

    uint32_t startAddress   = p->address;
    uint32_t oldAddress     = p->address;
    int32_t addressModifier = p->addressModifier;
    int32_t addressSpace    = p->addressSpace;
    int32_t unitSize        = p->unitSize;
    int32_t numItems        = p->numItems;
    int32_t memMapHandle;

    if (addressSpace == 0xFFFF) {
        memMapHandle = controlHandle;
        if (unitSize != sizeof(uint32_t) && numItems != 1) {
            sprintf(aPacket->message,"error: size and number not correct");
            p->errorCode = -1;
            writeBuffer(aPacket);
            return;
        }
    } else if(addressModifier == 0x29) {
        memMapHandle = vmeAM29Handle;
    } else {
        /* The address must be byte-aligned */ 
        startAddress = p->address & 0xFFFF;
        p->address = p->address & 0xFFFF0000;
        memMapHandle = openNewDevice("lsi2", p); 
        if (memMapHandle < 0) {
            sprintf(aPacket->message,"error: %d %d : %s\n",(int32_t)memMapHandle,(int32_t)errno,strerror(errno));
            p->errorCode = -1;
            writeBuffer(aPacket);
            return;
        }
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
    result = 
        vme_write(memMapHandle,startAddress,(uint8_t*)p,numItems*unitSize);
    
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
    }
    else {
        aPacket->cmdHeader.numberBytesinPayload    
          = sizeof(SBC_VmeWriteBlockStruct);
        returnDataPtr->errorCode = result;        
    }

    lptr = (int32_t*)returnDataPtr;
    if(needToSwap)SwapLongBlock(lptr,numItems);

    writeBuffer(aPacket);    
    if (memMapHandle != vmeAM29Handle && memMapHandle != controlHandle) {
        closeDevice(memMapHandle);
    } 
}

void doReadBlock(SBC_Packet* aPacket)
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
    int32_t memMapHandle;

    if (numItems*unitSize > kSBC_MaxPayloadSize) {
        sprintf(aPacket->message,"error: requested greater than payload size.");
        p->errorCode = -1;
        writeBuffer(aPacket);
        return;
    }
    if (addressSpace == 0xFFFF) {
        memMapHandle = controlHandle;
        if (unitSize != sizeof(uint32_t) && numItems != 1) {
            sprintf(aPacket->message,"error: size and number not correct");
            p->errorCode = -1;
            writeBuffer(aPacket);
            return;
         }
    } else if(addressModifier == 0x29) {
      memMapHandle = vmeAM29Handle;
    } else {
        /* The address must be byte-aligned */ 
        startAddress = p->address & 0xFFFF;
        p->address = p->address & 0xFFFF0000;
        
        memMapHandle = openNewDevice("lsi2", (SBC_VmeWriteBlockStruct*)p); 
        if (memMapHandle < 0) {
            sprintf(aPacket->message,"error: %d %d : %s\n",
                (int32_t)memMapHandle,(int32_t)errno,strerror(errno));
            p->errorCode = -1;
            writeBuffer(aPacket);
            return;
        }
    }

    /*OK, got address and # to read, set up the response and go get the data*/
    aPacket->cmdHeader.destination = kSBC_Process;
    aPacket->cmdHeader.cmdID       = kSBC_VmeReadBlock;
    aPacket->cmdHeader.numberBytesinPayload    
        = sizeof(SBC_VmeReadBlockStruct) + numItems*unitSize;

    SBC_VmeReadBlockStruct* returnDataPtr = 
        (SBC_VmeReadBlockStruct*)aPacket->payload;
    uint8_t* returnPayload = (uint8_t*)(returnDataPtr+1);

    int32_t result = 0;
	
    if (addressSpace == 0xFF) {
        /* We have to poll the same address. */
        uint32_t i = 0;
        for (i=0;i<numItems;i++) {
            result = 
                vme_read(memMapHandle,startAddress,
                    returnPayload + i*unitSize,unitSize);
            if (result != unitSize) break;
        }
        if (result == unitSize) result = unitSize*numItems; 
	} else {
        result = 
            vme_read(memMapHandle,startAddress,returnPayload,numItems*unitSize);
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
    }
    else {
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
    writeBuffer(aPacket);
    if (memMapHandle != vmeAM29Handle && memMapHandle != controlHandle) {
        closeDevice(memMapHandle);
    } 
}

/*************************************************************/
/*  All HW Readout code for VMEcpu follows here.             */
/*                                                           */
/*  Readout_CARD() function returns the index of the next    */
/*   card to read out                                        */
/*************************************************************/

void readHW(SBC_crate_config* config)
{
    int32_t index = 0;
    while(1){
        switch(config->card_info[index].hw_type_id){
            case kShaper:        
                index = Readout_Shaper(config,index);  
                break;
            case kGretina:       
                //index = -1;//Readout_Gretina(config,index);  
                index = Readout_Gretina(config,index);  
                break;
            default:            
                index =  -1; 
                break;
        }
        if(index>=config->total_cards || index<0)break;
    }
}

/*************************************************************/
/*             Reads out Shaper cards.                       */
/*************************************************************/

int32_t Readout_Shaper(SBC_crate_config* config,int32_t index)
{
    uint32_t baseAddress            = config->card_info[index].base_add;
    uint32_t conversionRegOffset    = config->card_info[index].deviceSpecificData[1];
    
    uint8_t theConversionMask;
    int32_t result    = vme_read(vmeAM29Handle,baseAddress+conversionRegOffset,&theConversionMask,1); //byte access, the conversion mask
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
                result    = vme_read(vmeAM29Handle,baseAddress+firstAdcRegOffset+2*channel,(uint8_t*)&aValue,2); //short access, the adc Value
                if(result == 2){
                    if(((dataId) & 0x80000000)){ //short form
                        int32_t data = dataId | locationMask | ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);
                        if(needToSwap)SwapLongBlock(&data,1);
                        CB_writeDataBlock(&data,1);
                    }
                    else { //long form
                        int32_t data[2];
                        data[0] = dataId | 2;
                        data[1] = locationMask | ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);
                        if(needToSwap)SwapLongBlock(data,2);
                        CB_writeDataBlock(data,2);
                    }
                }
            }
        }
    }
    return config->card_info[index].next_Card_Index;
}            

/*************************************************************/
/*             Reads out Gretina (Mark I) cards.             */
/*************************************************************/

int32_t Readout_Gretina(SBC_crate_config* config,int32_t index)
{

#define kGretinaFIFOEmpty       0x800
#define kGretinaFIFOAlmostEmpty 0x1000
#define kGretinaFIFOHalfFull    0x2000
#define kGretinaFIFOAllFull     0x4000
   
    static SBC_VmeWriteBlockStruct gretinaStruct = 
        {0x0, 0x39, 0x1, 0x4, 0x0, 0x0}; 
    static int32_t vmeAM39Handle = 0;
    static uint16_t fifoState;

    uint32_t baseAddress = config->card_info[index].base_add;
    uint32_t fifoStateAddress = 
        baseAddress + config->card_info[index].deviceSpecificData[0];
    uint32_t fifoAddress = baseAddress * 0x100;
    uint32_t dataId      = config->card_info[index].hw_mask[0];
    uint32_t slot        = config->card_info[index].slot;
    uint32_t crate       = config->card_info[index].crate;
    uint32_t location    = ((crate&0x0000000f)<<21) | ((slot& 0x0000001f)<<16);


    //read the fifo state
    int32_t result  = vme_read(vmeAM29Handle,fifoStateAddress,(uint8_t*)&fifoState,2); 
    int32_t dataBuffer[0xffff];
   
    gretinaStruct.address = fifoAddress; 
    vmeAM39Handle = openNewDevice("lsi2", &gretinaStruct); 

    if (vmeAM39Handle < 0) {
        return config->card_info[index].next_Card_Index;
    }

    if(result == 2 && ((fifoState & kGretinaFIFOEmpty) != 0)){
        uint32_t numLongs = 0;
        dataBuffer[numLongs++] = dataId | 0; //we'll fill in the length later
        dataBuffer[numLongs++] = location;
        
        //read the first int32_tword which should be the packet separator: 0xAAAAAAAA
        uint32_t theValue;
        result = vme_read(vmeAM39Handle,0x0,(uint8_t*)&theValue,4); 
        
        if(result == 4 && (theValue==0xAAAAAAAA)){
            
            //read the first word of actual data so we know how much to read
            result = vme_read(vmeAM39Handle,0x0,(uint8_t*)&theValue,4); 
            
            dataBuffer[numLongs++] = theValue;
                        
            uint32_t numLongsLeft  = ((theValue & 0xffff0000)>>16)-1;
            
            int32_t totalNumLongs = (numLongs + numLongsLeft);
             
            while (numLongs != totalNumLongs) {
                result = vme_read(vmeAM39Handle,0x0,(uint8_t*) (dataBuffer + numLongs),4); 
                if (result != 4) {
                    /* Error, FixME how to report this? */
                    return config->card_info[index].next_Card_Index;
                }
                numLongs++;
            }
                          
            /*result = vme_read(vmeAM39Handle,0x0,(uint8_t*) (dataBuffer + numLongs),4*numLongsLeft); 
            if (result != 4*numLongsLeft) {
                *//* something bad happened. */
                /*return config->card_info[index].next_Card_Index;
            }*/
            dataBuffer[0] |= totalNumLongs; //see, we did fill it in...
            /* Swap here?! */
            if (needToSwap) SwapLongBlock(dataBuffer, totalNumLongs);
            CB_writeDataBlock(dataBuffer,totalNumLongs);    
        }
        else {
            //oops... really bad -- the buffer read is out of sequence -- dump it all
            while(1){
                uint16_t val;
                //read the fifo state
               int32_t result = vme_read(vmeAM29Handle,fifoStateAddress,(uint8_t*)&val,2); 

                 if (result ==2 && (val & kGretinaFIFOEmpty) != 0) {
                    //read the first longword which should be the packet separator: 0xAAAAAAAA
                    uint32_t theValue;
                      result    = vme_read(vmeAM39Handle,0x0,(uint8_t*)&theValue,4); 
                     
                    if (result == 4 && theValue==0xAAAAAAAA) {
                        //read the first word of actual data so we know how much to read
                       result    = vme_read(vmeAM39Handle,0x0,(uint8_t*)&val,4); 
                       if(result != 4)break;
                       result    = vme_read(vmeAM39Handle,0x0,(uint8_t*)dataBuffer,4*((val & 0xffff0000)>>16)-1);                                                          
                        if(result != ((val & 0xffff0000)>>16)-1)break;
                    } else {
                        break;
                    }
                }
                else break;
             }
        }
    }
    closeDevice(vmeAM39Handle);
    return config->card_info[index].next_Card_Index;
}            

/*************************************************************/
/*             Reads out CAEN cards.                         */
/*************************************************************/

int32_t Readout_CAEN(SBC_crate_config* config,int32_t index)
{
  
    /* The deviceSpecificData is as follows:          */ 
    /* 0: statusOne register                          */
    /* 1: statusTwo register                          */
    /* 2: buffer                                      */
    /*
    static SBC_VmeWriteBlockStruct caenStruct = 
        {0x0, 0x39, 0x1, 0x4, 0x0, 0x0}; 
    static int32_t vmeAM39Handle = 0;
    static uint16_t statusOne, statusTwo;
    
    uint32_t baseAddress = config->card_info[index].base_add;
    uint32_t statusOneIndex = 
        baseAddress + config->card_info[index].deviceSpecificData[0];
    uint32_t statusTwoIndex = 
        baseAddress + config->card_info[index].deviceSpecificData[1];
    uint32_t fifoAddress = 
        baseAddress + config->card_info[index].deviceSpecificData[2];
    uint32_t dataId      = config->card_info[index].hw_mask[0];
    uint32_t slot        = config->card_info[index].slot;
    uint32_t crate       = config->card_info[index].crate;
    //uint32_t addMod      = config->card_info[index].add_mod;
    uint32_t location    = ((crate&0x0000000f)<<21) | ((slot& 0x0000001f)<<16);
    

    //read the states
    int32_t result  = vme_read(vmeAM29Handle,fifoAddress,(uint8_t*)&fifoState,2); 
    if (result != 2) {
        return config->card_info[index].next_Card_Index;
    }
    int32_t dataBuffer[0xffff];
   
    caenStruct.address = fifoAddress; 
    vmeAM39Handle = openNewDevice("lsi2", &caenStruct); 

    if (vmeAM39Handle < 0) {
        return config->card_info[index].next_Card_Index;
    }
    closeDevice(vmeAM39Handle);*/
    return config->card_info[index].next_Card_Index;
}
