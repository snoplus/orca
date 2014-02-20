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
                    strcpy(errorMessage,"Done$No Errors Reported");
                    reloadMainFpgaFromFlash();
                    finalStatus = 1;
                }
                else {
                    if(sbc_job.killJobNow){
                        strcpy(errorMessage,"User Halted");
                    }
                    else strcpy(errorMessage,"Error");
                    finalStatus = 0;
                }
                if (munmap(map, FILESIZE) == -1) strcpy(errorMessage,"Error");
                
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


void blockEraseFlash()
{
    setJobStatus("Block Erase",0);
    /* We only erase the blocks currently used in the  specification. */
    
    // Set VPEN signal == 1
    writeDevice(kVMEGPControlReg, kFlashEnableWrite);
	
    // Erase [first quarter of] flash
    int32_t count = 0;
    int32_t end = (kFlashBlocks / 4) * kFlashBlockSize;
    for (int32_t addr = 0; addr < end; addr += kFlashBlockSize) {
        if(sbc_job.killJobNow)break;
        char str[255];
        sprintf(str,"Block Erase$%d of %d Blocks Erased",count++,kFlashBufferBytes);
        setJobStatus(str,100. * (count+1)/(float)kFlashBufferBytes);
        
        writeDevice(kFlashAddressReg, addr);
        writeDevice(kFlashCommandReg, kFlashBlockEraseCmd);
        writeDevice(kFlashCommandReg, kFlashConfirmCmd);
        
        uint32_t stat;
        readDevice(kMainFPGAStatusReg, &stat);
        while (stat & kFlashBusy) {
            if(sbc_job.killJobNow)break;
            readDevice(kMainFPGAStatusReg, &stat);
        }
    }
	   
    if(sbc_job.killJobNow){
        setJobStatus("User Halted",0);
    }
}

void programFlashBuffer(uint8_t* theData, uint32_t totalSize)
{
    char statusString[255];
    sprintf(statusString,"Programming");
    setJobStatus(statusString,0);
    
    writeDevice(kFlashAddressReg,0x0);
    writeDevice(kFlashCommandReg,kFlashReadArrayCmd);    //set to array mode
    
	uint32_t address = 0x0;
	while (address < totalSize ) {
        uint32_t numberBytesToWrite;
        if(totalSize-address >= kFlashBufferBytes)  numberBytesToWrite = kFlashBufferBytes;   //whole block
        else                                        numberBytesToWrite = totalSize - address; //near eof -- partial block
        
        programFlashBufferBlock(theData,address,numberBytesToWrite);
        
        address += numberBytesToWrite;
        if(sbc_job.killJobNow)break;
        
        if(address%(totalSize/1000) == 0){
            sprintf(statusString,"Programming$Flashed: %d/%d KB",address/1000,totalSize/1000);
            setJobStatus(statusString,100. * address/(float)totalSize);
        }
        if(sbc_job.killJobNow)break;;

	}
    if(sbc_job.killJobNow)return;
    writeDevice(kFlashAddressReg, 0x00);
    writeDevice(kFlashCommandReg, kFlashReadArrayCmd);    //set to array mode
    writeDevice(kVMEGPControlReg, 0x0);
    setJobStatus("Programming Done",0);
}

void programFlashBufferBlock(uint8_t* theData,uint32_t anAddress,uint32_t aNumber)
{
    uint32_t statusRegValue;

    //issue the set-up command at the starting address
    writeDevice(kFlashAddressReg,anAddress);
    writeDevice(kFlashCommandReg,kFlashWriteCmd);
    
	while(1) {
        if(sbc_job.killJobNow)return;
		
		// Checking status to make sure that flash is ready
        readDevice(kMainFPGAStatusReg,&statusRegValue);
		
		if ( (statusRegValue & kFlashBusy)  == kFlashBusy ) {
            //not ready, so re-issue the set-up command
            writeDevice(kFlashAddressReg,anAddress);
            writeDevice(kFlashCommandReg, kFlashWriteCmd);
		}
        else break;
	}
    
	//Set the word count. Max is 0xF.
	uint32_t valueToWrite = (aNumber/2) - 1;
    writeDevice(kFlashCommandReg,valueToWrite );
	
	// Loading all the words in
    /* Load the words into the bufferToWrite */
	uint32_t i;
	for ( i=0; i<aNumber; i+=4 ) {
        uint32_t* lPtr = (uint32_t*)&theData[anAddress+i];
        writeDevice(kFlashDataAutoIncReg, lPtr[0]);
	}
	
    // Confirm the write
    writeDevice(kFlashCommandReg, kFlashConfirmCmd);
    
    readDevice(kMainFPGAStatusReg,&statusRegValue);
    while(statusRegValue & kFlashBusy) {
        if(sbc_job.killJobNow)return;
        readDevice(kMainFPGAStatusReg,&statusRegValue);
    }

}


uint8_t verifyFlashBuffer(uint8_t* theData, uint32_t totalSize)
{
    char statusString[255];
    setJobStatus("Verifying",0);
	/* First reset to make sure it is read mode. */
    
    writeDevice(kFlashAddressReg,0x0);
    writeDevice(kFlashCommandReg,kFlashReadArrayCmd);    //set to array mode
    
    uint32_t errorCount =   0;
	uint32_t address    =   0;
	uint32_t valueToRead;
	uint32_t valueToCompare;
	while ( address < totalSize ) {
        readDevice(0x984,&valueToRead);

		/* Now compare to file*/
		if ( address + 3 < totalSize) {
            uint32_t* ptr = (uint32_t*)&theData[address];
            valueToCompare = ptr[0];
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
            errorCount++;
		}
		if(address%(totalSize/1000) == 0){
            sprintf(statusString,"Verifying$Verified: %d/%d KB Errors: %d",address/1000,totalSize/1000,errorCount);
			setJobStatus(statusString, 100. * address/(float)totalSize);
		}
		address += 4;
	}
    if(errorCount==0){
        setJobStatus("Done$No Errors", 0);
        return 1;
    }
    else {
        setJobStatus("Error$Comparision Error", 0);
        return 0;
    }
}
void reloadMainFpgaFromFlash(void)
{
    writeDevice(kMainFPGAControlReg,kResetMainFPGACmd);
    writeDevice(kMainFPGAControlReg,kReloadMainFPGACmd);
    setJobStatus("Finishing$Flash Memory-->FPGA", 0);
    //wait until done
    uint32_t statusRegValue;
    readDevice(kMainFPGAStatusReg,&statusRegValue);
    while(!(statusRegValue & kMainFPGAIsLoaded)) {
        if(sbc_job.killJobNow)return;
        readDevice(kMainFPGAStatusReg,&statusRegValue);
    }
}

void setJobStatus(const char* message,uint32_t progress)
{
	char  errorMessage[255];
    strcpy(errorMessage,message);
    pthread_mutex_lock (&jobInfoMutex);         //begin critical section
    strncpy(sbc_job.message,errorMessage,255);
    sbc_job.progress = progress;                //percent done
    pthread_mutex_unlock (&jobInfoMutex);       //end critical section
}

void readDevice(uint32_t address,uint32_t* retValue)
{
    uint32_t stat;
    read_device(fpgaDevice,(char*)(&stat),4,address);
    *retValue = stat;
}

void writeDevice(uint32_t address,uint32_t aValue)
{
    write_device(fpgaDevice,(char*)(&aValue),4,address);
}
