/*
 *  MJD.h
 *  Orca
 *
 *  Created by Mark Howe on 08/27/13.
 *  Copyright 2013 ENAP, University of North Carolina. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina at the Experimental Nuclear and Astroparticle Physics
//(ENAP) group sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//----------------------------------------------------------------


#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <dlfcn.h>

extern "C" {
#include "HW_Readout.h"
#include "MJD.h"
#include "MJDCmds.h"
#include "SBC_Config.h"
#include "VME_HW_Definitions.h"
}

#include "universe_api.h"
#include "ORMTCReadout.hh"
#include <errno.h>

extern char			needToSwap;

void processMJDCommand(SBC_Packet* aPacket)
{
	switch(aPacket->cmdHeader.cmdID){		
		case kMJDReadPreamps: readPreAmpAdcs(aPacket);	break;
        case kMJDSingleAuxIO: singleAuxIO(aPacket);     break;
	}
}

void singleAuxIO(SBC_Packet* aPacket)
{
    //create the packet that will be returned    
	GRETINA4_SingleAuxIOStruct* p    = (GRETINA4_SingleAuxIOStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));

    uint32_t baseAddress = p->baseAddress;
    p->spiData = writeAuxIOSPI(baseAddress,p->spiData);

    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    if (writeBuffer(aPacket) < 0) {
        LogError("SingleAuxIO Error: %s", strerror(errno));
    }
}


void readPreAmpAdcs(SBC_Packet* aPacket)
{
    //create the packet that will be returned
	GRETINA4_PreAmpReadStruct* p    = (GRETINA4_PreAmpReadStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    
    uint32_t baseAddress = p->baseAddress;
    
    uint32_t i;
    for(i=0;i<16;i++){
        if(p->readEnabledMask & (0x1<<i)){
            //don't like it, but have to do this four times
            p->adc[i] = writeAuxIOSPI(baseAddress,p->adc[i]);
            p->adc[i] = writeAuxIOSPI(baseAddress,p->adc[i]);
            p->adc[i] = writeAuxIOSPI(baseAddress,p->adc[i]);
            p->adc[i] = writeAuxIOSPI(baseAddress,p->adc[i]);
        }
        else p->adc[i]=0;
    }
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    if (writeBuffer(aPacket) < 0) {
        LogError("PreAmp Error: %s", strerror(errno));
    }
}


uint32_t writeAuxIOSPI(uint32_t baseAddress,uint32_t spiData)
{
#define kSPIData	    0x2
#define kSPIClock	    0x4
#define kSPIChipSelect	0x8
#define kSPIRead        0x10
    TUVMEDevice* device = get_new_device(baseAddress, 0x09, 4, 0x0);
    uint32_t readBack = 0;
    if(device!=0){
        
        uint32_t auxIORead   = /*baseAddress +*/ 0x800;
        uint32_t auxIOWrite  = /*baseAddress +*/  0x804;
        uint32_t auxIOConfig = /*baseAddress +*/  0x808;
        
        // Set AuxIO to mode 3 and set bits 0-3 to OUT (bit 0 is under FPGA control)
        uint32_t valueToWrite = 0x3025;
        printf("write 0x%08x to 0x%08x\n",0x3025,auxIOConfig);
        write_device(device, (char*)(&valueToWrite), 4, auxIOConfig);

        // Read kAuxIOWrite to preserve bit 0, and zero bits used in SPI protocol
        uint32_t spiBase;
        printf("read 0x%08x\n",auxIOWrite);
       read_device(device,(char*)(&spiBase),4,auxIOWrite);
        
        spiBase = spiBase & ~(kSPIData | kSPIClock | kSPIChipSelect);
        
        uint32_t valueRead;
        
        // set kSPIChipSelect to signify that we are starting
        valueToWrite = kSPIChipSelect | kSPIClock | kSPIData;
        printf("write 0x%08x to 0x%08x\n",valueToWrite,auxIOWrite);
       write_device(device, (char*)(&valueToWrite), 4, auxIOWrite);
        
        // now write spiData starting from MSB on kSPIData, pulsing kSPIClock
        // each iteration
        int i;
        for(i=0; i<32; i++) {
            uint32_t rawValueToWrite = spiBase | kSPIChipSelect | kSPIData;
            if( (spiData & 0x80000000) != 0) rawValueToWrite &= (~kSPIData);
            //toggle the kSPIClock bit
            valueToWrite = rawValueToWrite | kSPIClock;
            printf("write 0x%08x to 0x%08x\n",valueToWrite,auxIOWrite);
            write_device(device, (char*)(&valueToWrite), 4, auxIOWrite);
            printf("write 0x%08x to 0x%08x\n",rawValueToWrite,auxIOWrite);
           write_device(device, (char*)(&rawValueToWrite), 4, auxIOWrite);
            
            printf("read 0x%08x\n",auxIORead);
            read_device(device,(char*)(&valueRead),4,auxIORead);
           
            readBack |= ((valueRead & kSPIRead) > 0) << (31-i);
            spiData = spiData << 1;
        }
        // unset kSPIChipSelect to signify that we are done
        valueToWrite = kSPIClock | kSPIData;
        printf("write 0x%08x to 0x%08x\n",valueToWrite,auxIOWrite);
        write_device(device, (char*)(&valueToWrite), 4, auxIOWrite);
        close_device(device);
    }
    return readBack;
}
