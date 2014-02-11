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
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>

extern "C" {
#include "HW_Readout.h"
#include "MJD.h"
#include "MJDCmds.h"
#include "SBC_Config.h"
#include "VME_HW_Definitions.h"
#include "SBC_Job.h"
}

#include "ORMTCReadout.hh"
#include "universe_api.h"
#include <errno.h>

extern char             needToSwap;
extern pthread_mutex_t  jobInfoMutex;
extern SBC_JOB          sbc_job;

TUVMEDevice* fpgaDevice = NULL;

#define kGretina4MFlashDisableWrite     0x0
#define kGretina4MFlashEnableWrite      0x10
#define kGretina4MFlashBlocks           128
#define kGretina4MUsedFlashBlocks       ( kGretina4MFlashBlocks / 4 )
#define kGretina4MFlashBlockEraseCmd	0x20
#define kGretina4MFlashConfirmCmd       0xD0
#define kGretina4MFlashReady			0x80
#define kGretina4MFlashClearSRCmd       0x50
#define kGretina4MFlashReadArrayCmd     0xFF
#define kGretina4MFlashBlockSize		( 128 * 1024 )
#define kGretina4MFlashBufferBytes      32
#define kGretina4MFlashWriteCmd         0xE8
#define kGretina4MResetMainFPGACmd      0x30
#define kGretina4MReloadMainFPGACmd     0x3
#define kGretina4MMainFPGAIsLoaded      0x41

#define kMainFPGAControl        0x900
#define kMainFPGAStatus         0x904
#define kVMEGPControl           0x910
#define kFlashAddress           0x980
#define kFlashData              0x988
#define kFlashCommandRegister   0x98C
#define kFlashDataWithAddrIncr  0x984

void processMJDCommand(SBC_Packet* aPacket)
{
	switch(aPacket->cmdHeader.cmdID){
		case kMJDReadPreamps:       readPreAmpAdcs(aPacket);             break;
        case kMJDSingleAuxIO:       singleAuxIO(aPacket);                break;
        case kMJDFlashGretinaFPGA:  startJob(&flashGretinaFPGA,aPacket); break;
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
    uint32_t chip        = p->chip;
    uint32_t enabledMask = p->readEnabledMask>>(chip*8); //mask comes for all channels. shift to get the part we care about.
    uint32_t i;
    for(i=0;i<8;i++){
        uint32_t rawValue = 0;
        if(enabledMask & (0x1<<i)){
            //don't like it, but have to do this four times
            rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
            rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
			rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
			rawValue = writeAuxIOSPI(baseAddress,p->adc[i]);
        }
        else rawValue=0;
        p->adc[i] = rawValue;
        
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
        uint32_t auxIOWrite  = /*baseAddress +*/ 0x804;
        uint32_t auxIOConfig = /*baseAddress +*/ 0x808;
        
        // Set AuxIO to mode 3 and set bits 0-3 to OUT (bit 0 is under FPGA control)
        uint32_t valueToWrite = 0x3025;
        write_device(device, (char*)(&valueToWrite), 4, auxIOConfig);

        // Read kAuxIOWrite to preserve bit 0, and zero bits used in SPI protocol
        uint32_t spiBase;
		read_device(device,(char*)(&spiBase),4,auxIOWrite);
        
        spiBase = spiBase & ~(kSPIData | kSPIClock | kSPIChipSelect);
        
        uint32_t valueRead;
        
        // set kSPIChipSelect to signify that we are starting
        valueToWrite = kSPIChipSelect | kSPIClock | kSPIData;
		write_device(device, (char*)(&valueToWrite), 4, auxIOWrite);
        
        // now write spiData starting from MSB on kSPIData, pulsing kSPIClock
        // each iteration
        uint32_t i;
        for(i=0; i<32; i++) {
            uint32_t rawValueToWrite = spiBase | kSPIChipSelect | kSPIData;
            if( (spiData & 0x80000000) != 0) rawValueToWrite &= (~kSPIData);
            //toggle the kSPIClock bit
            valueToWrite = rawValueToWrite | kSPIClock;
            write_device(device, (char*)(&valueToWrite),    4, auxIOWrite);
            write_device(device, (char*)(&rawValueToWrite), 4, auxIOWrite);
            
            read_device(device,(char*)(&valueRead),4,auxIORead);
           
            readBack |= ((valueRead & kSPIRead) > 0) << (31-i);
            spiData = spiData << 1;
        }
        
        // unset kSPIChipSelect to signify that we are done
        valueToWrite = kSPIClock | kSPIData;
        write_device(device, (char*)(&valueToWrite), 4, auxIOWrite);
        close_device(device);
    }
    return readBack;
}

void flashGretinaFPGA(SBC_Packet* aPacket)
{
#define FILEPATH "/home/daq/GretinaFPGA.bin"
#define NUMINTS  (1000)
#define FILESIZE (NUMINTS * sizeof(int))
    
    
	char  errorMessage[255];
	memset(errorMessage,'\0',80);
	uint8_t  finalStatus = 0; //assume failure
    
    MJDFlashGretinaFPGAStruct* p    = (MJDFlashGretinaFPGAStruct*)aPacket->payload;
    if(needToSwap) SwapLongBlock(p, aPacket->cmdHeader.numberBytesinPayload/sizeof(uint32_t));
    
    uint32_t baseAddress = p->baseAddress;

    fpgaDevice = get_new_device(baseAddress, 0x09, 4, 0x0);
    
    pthread_mutex_lock (&jobInfoMutex);     //begin critical section
    sbc_job.running = 1;
    pthread_mutex_unlock (&jobInfoMutex);   //end critical section
    
    
    if(fpgaDevice!=0){
        blockEraseFlash();
        //memory map the fpga file and get a pointer to it
        int32_t   fd;
        uint8_t* map;  /* mmapped array of int's */
        
        fd = open(FILEPATH, O_RDONLY);
        if (fd == -1) strcpy(errorMessage,"Error");
        else {
            struct stat sb;
            fstat(fd, &sb);

            map = (uint8_t*)mmap(0, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
            if (map == MAP_FAILED) {
                close(fd);
                strcpy(errorMessage,"Error");
            }
            else {
                programFlashBuffer(map,sb.st_size);
                if(verifyFlashBuffer(map,sb.st_size)&& !sbc_job.killJobNow){
                    reloadMainFPGAFromFlash();
                }
                else  strcpy(errorMessage,"Error");

                if (munmap(map, FILESIZE) == -1) strcpy(errorMessage,"Error");
                
                strcpy(errorMessage,"");
                finalStatus = 1;
            }
            close(fd);
        }
        close_device(fpgaDevice);
    }
    else {
		strcpy(errorMessage,"Unable to get device.");
    }
    
    pthread_mutex_lock (&jobInfoMutex);     //begin critical section
    sbc_job.progress    = 0;
    sbc_job.running     = 0;
    sbc_job.killJobNow  = 0;
    sbc_job.finalStatus = finalStatus;
    strncpy(sbc_job.message,errorMessage,255);
    sbc_job.message[255] = '\0';
    pthread_mutex_unlock (&jobInfoMutex);   //end critical section
}

void reloadMainFPGAFromFlash(void)
{
	int32_t valueToWrite = kGretina4MResetMainFPGACmd;
    write_device(fpgaDevice, (char*)(&valueToWrite), 4, kMainFPGAControl);

	
	valueToWrite = kGretina4MReloadMainFPGACmd;
    write_device(fpgaDevice, (char*)(&valueToWrite), 4, kMainFPGAControl);
	
	/* Now check if it is done reloading before releasing. */
    int32_t valueToRead;
    do {
        read_device(fpgaDevice, (char*)(&valueToRead), 4, kMainFPGAStatus);
    }while ( ( valueToRead & kGretina4MMainFPGAIsLoaded ) != kGretina4MMainFPGAIsLoaded );
}

void blockEraseFlash()
{
    setJobStatus("Block Erase",0);
    /* We only erase the blocks currently used in the Gretina4M specification. */
    
    //step 1 enable flashEraseWrite
    enableFlashEraseAndProg();

    //step 2 erase each block
	uint32_t blockNumber;
	for (blockNumber=0; blockNumber<kGretina4MUsedFlashBlocks; blockNumber++ ) {
		if(sbc_job.killJobNow)break;
        
        setJobStatus("Block Erase",100. * (blockNumber+1)/(float)kGretina4MUsedFlashBlocks);
        uint32_t valueToWrite = 0x0;
        write_device(fpgaDevice, (char*)(&valueToWrite), 4, kFlashAddress);

        valueToWrite = kGretina4MFlashBlockEraseCmd;
        write_device(fpgaDevice, (char*)(&valueToWrite), 4, kFlashCommandRegister);

        
        /* Now denote which block we're going to do. */
        valueToWrite = blockNumber*kGretina4MFlashBlockSize;
        write_device(fpgaDevice, (char*)(&valueToWrite), 4, kFlashAddress);
        
        /* And confirm. */
        valueToWrite = kGretina4MFlashConfirmCmd;
        write_device(fpgaDevice, (char*)(&valueToWrite), 4, kFlashCommandRegister);
 				 
        /* Now make sure that it finishes correctly. We don't need to issue the flash command to
         read the status register because the confirm command already sets that.  */
        uint32_t valueToRead;
        while(1) {
            if(sbc_job.killJobNow)break;
            
            // Checking status to make sure that flash is ready
            read_device(fpgaDevice,(char*)(&valueToRead),4,kFlashData);

            if ( (valueToRead & kGretina4MFlashReady) != 0 ) break;
		}

	}
    
    if(sbc_job.killJobNow)return;
    
    //step 3 disable the ability to erase
    disableFlashEraseAndProg();
    
    //step 4 reset
    resetFlash();
    setJobStatus("Block Erase",0);

}

void resetFlash(void)
{
    uint32_t valueToWrite = kGretina4MFlashClearSRCmd;
    write_device(fpgaDevice, (char*)(&valueToWrite), 4, kFlashCommandRegister);
	
	valueToWrite = kGretina4MFlashReadArrayCmd;
    write_device(fpgaDevice, (char*)(&valueToWrite), 4, kFlashCommandRegister);
	
	valueToWrite = 0x0;
    write_device(fpgaDevice, (char*)(&valueToWrite), 4, kFlashAddress);
}

void enableFlashEraseAndProg(void)
{
    uint32_t valueToWrite = kGretina4MFlashEnableWrite;
    write_device(fpgaDevice, (char*)(&valueToWrite), 4, kVMEGPControl);
}

void disableFlashEraseAndProg(void)
{
    uint32_t valueToWrite = kGretina4MFlashDisableWrite;
    write_device(fpgaDevice, (char*)(&valueToWrite), 4, kVMEGPControl);
}

void programFlashBuffer(uint8_t* theData, uint32_t totalSize)
{
    char statusString[255];
    sprintf(statusString,"Programming$FPGA File Size: %d",totalSize);
    setJobStatus(statusString,0);
	enableFlashEraseAndProg();
    
	uint32_t address = 0x0;
	while (address < totalSize ) {
        uint32_t numberBytesToWrite;
        if(totalSize-address >= kGretina4MFlashBufferBytes){
            numberBytesToWrite = kGretina4MFlashBufferBytes; //whole block
        }
        else {
            numberBytesToWrite = totalSize - address; //near eof, so partial block
        }
        
        programFlashBufferBlock(theData,address,numberBytesToWrite);
        
        address += numberBytesToWrite;
        if(sbc_job.killJobNow)break;
        
        if(address%(totalSize/1000) == 0){
            setJobStatus(statusString,100. * address/(float)totalSize);
        }
        if(sbc_job.killJobNow)break;;

	}
    if(sbc_job.killJobNow)return;
	disableFlashEraseAndProg();
    resetFlash();
    setJobStatus("Programming Done",0);
}

uint8_t verifyFlashBuffer(uint8_t* theData, uint32_t totalSize)
{
    setJobStatus("Verifying",0);
	/* First reset to make sure it is read mode. */
    resetFlash();
    
	uint32_t address = 0;
	uint32_t valueToRead;
	unsigned long valueToCompare;
	while ( address < totalSize ) {
        read_device(fpgaDevice,(char*)(&valueToRead),4,kFlashDataWithAddrIncr);

		/* Now compare to file*/
		if ( address + 3 < totalSize) {
			valueToCompare = (((unsigned long)theData[address]) & 0xFF) |
			(((unsigned long)(theData[address+1]) <<  8) & 0xFF00) |
			(((unsigned long)(theData[address+2]) << 16) & 0xFF0000)|
			(((unsigned long)(theData[address+3]) << 24) & 0xFF000000);
		}
        else {
            //less than four bytes left
			uint32_t numBytes = totalSize - address - 1;
			valueToCompare = 0;
			uint32_t i;
			for ( i=0;i<numBytes;i++) {
				valueToCompare += (((unsigned long)theData[address]) << i*8) & (0xFF << i*8);
			}
		}
		if ( valueToRead != valueToCompare ) {
            setJobStatus("Error$Comparision Error", 0);
            return 0;
		}
		if(address%(totalSize/1000) == 0){
			setJobStatus("Verifying", 100. * address/(float)totalSize);
		}
		address += 4;
	}
    setJobStatus("Done$No Errors", 0);
    return 1;
}

void programFlashBufferBlock(uint8_t* theData,uint32_t anAddress,uint32_t aNumber)
{
	uint32_t valueToWrite = anAddress;
    write_device(fpgaDevice, (char*)(&valueToWrite), 4, kFlashAddress);
	
	valueToWrite = kGretina4MFlashWriteCmd;
    write_device(fpgaDevice, (char*)(&valueToWrite), 4, kFlashCommandRegister);
    
	while(1) {
        if(sbc_job.killJobNow)return;
		
		// Checking status to make sure that flash is ready
		/* This is slightly different since we give another command if the status hasn't updated. */
        uint32_t valueToRead;
        read_device(fpgaDevice,(char*)(&valueToRead),4,kFlashData);
		
		if ( (valueToRead & kGretina4MFlashReady)  == 0 ) {
			valueToWrite = kGretina4MFlashWriteCmd;
            write_device(fpgaDevice, (char*)(&valueToWrite), 4, kFlashCommandRegister);
		}
        else break;
	}
    
	// Setting how many we are trying to write
	valueToWrite = (aNumber/2) - 1;
    write_device(fpgaDevice, (char*)(&valueToWrite), 4, kFlashCommandRegister);
	
	// Loading all the words in
    /* Load the words into the bufferToWrite */
	uint8_t* dataPtr = theData+anAddress;
    
	uint32_t i;
	for ( i=0; i<aNumber; i+=4 ) {
		valueToWrite =   (((uint32_t)dataPtr[i]) & 0xFF)                 |
                        (((uint32_t)(dataPtr[i+1]) <<  8) & 0xFF00)     |
                        (((uint32_t)(dataPtr[i+2]) << 16) & 0xFF0000)   |
                        (((uint32_t)(dataPtr[i+3]) << 24) & 0xFF000000);
        write_device(fpgaDevice, (char*)(&valueToWrite), 4, kFlashDataWithAddrIncr);
	}
	
	// Finishing the write
	valueToWrite = kGretina4MFlashConfirmCmd;
    write_device(fpgaDevice, (char*)(&valueToWrite), 4, kFlashCommandRegister);
	
	testFlashStatusRegisterWithNoFlashCmd();
}

void testFlashStatusRegisterWithNoFlashCmd(void)
{
    uint32_t valueToRead;
    while(1) {
        if(sbc_job.killJobNow)return;
        read_device(fpgaDevice,(char*)(&valueToRead),4,kFlashData);
		
        if ( (valueToRead & kGretina4MFlashReady) != 0 ) break;
    }
}

void setJobStatus(const char* message,uint32_t progress)
{
	char  errorMessage[255];
    strcpy(errorMessage,message);
    pthread_mutex_lock (&jobInfoMutex);     //begin critical section
    strncpy(sbc_job.message,errorMessage,255);
    sbc_job.progress = progress;                   //percent done
    pthread_mutex_unlock (&jobInfoMutex);   //end critical section
}


