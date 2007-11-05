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

void SwapLongBlock(void* p, long n);
void SwapShortBlock(void* p, long n);


extern char needToSwap;

static int vmeAM29Handle;
static int vmeAM39Handle;
static int controlHandle;

void processHWCommand(SBC_Packet* aPacket)
{
	/*look at the first word to get the destination*/
	long destination = aPacket->cmdHeader.destination;

	switch(destination){
//		default:			  processUnknownCommand(aPacket); break;
	}
}

void startHWRun (SBC_crate_config* config)
{	
	long index = 0;
	while(1){
		switch(config->card_info[index].hw_type_id){
			default:     index =  -1; break;
		}
		if(index>=config->total_cards || index<0)break;
	}
}

void stopHWRun (SBC_crate_config* config)
{
	long index = 0;
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
    vmeAM39Handle = vme_openDevice( "lsi2" );
    controlHandle  = vme_openDevice( "ctl" );

	int result;

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
	idata.pciAddress	= 0x0;			/* default -- let the cpu pick the address */
	idata.vmeAddress	= 0x0;			/* start a zero and map the ENTIRE short address space */
	idata.size			= 0x10000;		/* 64K, 16 bit address space */
	idata.dataWidth		= VME_D16;		/* 16 bit data */
	idata.addrSpace		= VME_A16;      /* address modifier 0x29 */
	//idata.addrSpace	= VME_USER1_AM; /* address modifier 0x29 */
	idata.postedWrites	= 0;
	idata.type			= LSI_DATA;     /* data AM code */
	idata.mode			= 1;     /* non-privileged */
	idata.vmeCycle		= 0;			/* no BLT's on VME bus */
	idata.pciBusSpace	= 0;			/* PCI bus memory space */
	idata.ioremap		= 1;			/* use ioremap */
	result = vme_enablePciImage( vmeAM29Handle, &idata );
    //printf("Pci image result: %d\n",result);

	idata.pciAddress	= 0x0;			/* default -- let the cpu pick the address */
	idata.vmeAddress	= 0x0;			/* start a zero and map the ENTIRE short address space */
	idata.size			= 0x10000;		/* 64K, 16 bit address space */
	idata.dataWidth		= VME_D32;		/* 32 bit data */
	idata.addrSpace		= VME_A32;      /* address modifier 0x39 */
	//idata.addrSpace	= VME_USER1_AM; /* address modifier 0x29 */
	idata.postedWrites	= 0;
	idata.type			= LSI_DATA;     /* data AM code */
	idata.mode			= 1;            /* non-privileged */
	idata.vmeCycle		= 0;			/* no BLT's on VME bus */
	idata.pciBusSpace	= 0;			/* PCI bus memory space */
	idata.ioremap		= 1;			/* use ioremap */
	result = vme_enablePciImage( vmeAM39Handle, &idata );
	
}

void ReleaseHardware(void)
{
	vme_closeDevice( vmeAM29Handle );
	vme_closeDevice( vmeAM39Handle );
 	vme_closeDevice( controlHandle );
}


void doWriteBlock(SBC_Packet* aPacket)
{
	SBC_VmeWriteBlockStruct* p = (SBC_VmeWriteBlockStruct*)aPacket->payload;
	if(needToSwap)SwapLongBlock(p,sizeof(SBC_VmeWriteBlockStruct)/sizeof(long));

	unsigned long startAddress		= p->address;
	long addressModifier			= p->addressModifier;
	long addressSpace				= p->addressSpace;
	long unitSize					= p->unitSize;
	long numItems					= p->numItems;
	p++; /*point to the data*/
	short *sptr;
	long  *lptr;
	switch(unitSize){
		case 1: /*bytes*/
			/*no need to swap*/
		break;
		
		case 2: /*shorts*/
			sptr = (short*)p; /* cast to the data type*/ 
			if(needToSwap)SwapShortBlock(sptr,numItems);
		break;
		
		case 4: /*longs*/
			lptr = (long*)p; /* cast to the data type*/ 
			if(needToSwap)SwapLongBlock(lptr,numItems);
		break;
	}
	
	//printf("writing %lu bytes @ 0x%x\n",numItems*unitSize,(int)startAddress);
	int result = vme_write(vmeAM29Handle,startAddress,(unsigned char*)p,numItems*unitSize);
	//printf("write result: %d  (%ld, %ld)\n", result,numItems,unitSize);
	
	/* echo the structure back with the error code*/
	/* 0 == no Error*/
	/* non-0 means an error*/
	SBC_VmeWriteBlockStruct* returnDataPtr = (SBC_VmeWriteBlockStruct*)aPacket->payload;
	returnDataPtr->address			= startAddress;
	returnDataPtr->addressModifier	= addressModifier;
	returnDataPtr->addressSpace		= addressSpace;
	returnDataPtr->unitSize			= unitSize;
	returnDataPtr->numItems			= 0;

	if(result == (numItems*unitSize)){
		//printf("no write error\n");
		returnDataPtr->errorCode		= 0;
	}
	else {
		//printf("error: %d %d : %s\n",(int)result,(int)errno,strerror(errno));
		aPacket->cmdHeader.numberBytesinPayload	= sizeof(SBC_VmeWriteBlockStruct);
		returnDataPtr->errorCode		= result;		
	}

	lptr = (long*)returnDataPtr;
	if(needToSwap)SwapLongBlock(lptr,numItems);

	writeBuffer(aPacket);	
}

void doReadBlock(SBC_Packet* aPacket)
{
	SBC_VmeReadBlockStruct* p = (SBC_VmeReadBlockStruct*)aPacket->payload;
	if(needToSwap)SwapLongBlock(p,sizeof(SBC_VmeReadBlockStruct)/sizeof(long));
	unsigned long startAddress		= p->address;
	long addressModifier			= p->addressModifier;
	long addressSpace				= p->addressSpace;
	long unitSize					= p->unitSize;
	long numItems					= p->numItems;

	/*OK, got address and # to read, set up the response and go get the data*/
	aPacket->cmdHeader.destination	= kSBC_Process;
	aPacket->cmdHeader.cmdID		= kSBC_VmeReadBlock;
	aPacket->cmdHeader.numberBytesinPayload	= sizeof(SBC_VmeReadBlockStruct) + numItems*unitSize;

	SBC_VmeReadBlockStruct* returnDataPtr = (SBC_VmeReadBlockStruct*)aPacket->payload;
	returnDataPtr->address  = startAddress;
	if(needToSwap)SwapLongBlock(returnDataPtr,sizeof(SBC_VmeReadBlockStruct)/sizeof(long));
	unsigned char* returnPayload = (unsigned char*)(returnDataPtr+1);
	//printf("reading %ld bytes @ 0x%x\n",numItems*unitSize,(int)startAddress);

	int result	= vme_read(vmeAM29Handle,startAddress,returnPayload,numItems*unitSize);
	//printf("read result: %d\n",result);

	returnDataPtr->address			= startAddress;
	returnDataPtr->addressModifier	= addressModifier;
	returnDataPtr->addressSpace		= addressSpace;
	returnDataPtr->unitSize			= unitSize;
	returnDataPtr->numItems			= numItems;
	if(result == (numItems*unitSize)){
		//printf("no read error\n");
		returnDataPtr->errorCode		= 0;
		switch(unitSize){
			case 1: /*bytes*/
				/*no need to swap*/
			break;
			
			case 2: /*shorts*/
				if(needToSwap)SwapShortBlock((short*)returnPayload,numItems);
			break;
			
			case 4: /*longs*/
				if(needToSwap)SwapLongBlock((long*)returnPayload,numItems);
			break;
		}
	}
	else {
		//printf("error: %d %d : %s\n",(int)result,(int)errno,strerror(errno));
		aPacket->cmdHeader.numberBytesinPayload	= sizeof(SBC_VmeReadBlockStruct);
		returnDataPtr->numItems			= 0;
		returnDataPtr->errorCode		= result;		
	}

	writeBuffer(aPacket);
	
}

void readHW(SBC_crate_config* config)
{
	long index = 0;
	while(1){
		switch(config->card_info[index].hw_type_id){
			case kShaper:		index = Readout_Shaper(config,index);  break;
			case kGretina:		index = Readout_Gretina(config,index);  break;
			default:			index =  -1; break;
		}
		if(index>=config->total_cards || index<0)break;
	}
}

int Readout_Shaper(SBC_crate_config* config,int index)
{
	unsigned long baseAddress			= config->card_info[index].base_add;
	unsigned long conversionRegOffset	= config->card_info[index].deviceSpecificData[1];
	
	unsigned char theConversionMask;
	int result	= vme_read(vmeAM29Handle,baseAddress+conversionRegOffset,&theConversionMask,1); //byte access, the conversion mask
	if(result == 1 && theConversionMask != 0){

		unsigned long dataId				= config->card_info[index].hw_mask[0];
		unsigned long slot					= config->card_info[index].slot;
		unsigned long crate					= config->card_info[index].crate;
		unsigned long locationMask			= ((crate & 0x01e)<<21) | ((slot & 0x0000001f)<<16);
		unsigned long onlineMask			= config->card_info[index].deviceSpecificData[0];
		unsigned long firstAdcRegOffset		= config->card_info[index].deviceSpecificData[2];

		short channel;
		for (channel=0; channel<8; ++channel) {
			if(onlineMask & theConversionMask & (1L<<channel)){
				unsigned short aValue;
				result	= vme_read(vmeAM29Handle,baseAddress+firstAdcRegOffset+2*channel,(unsigned char*)&aValue,2); //short access, the adc Value
				if(result == 2){
					if(((dataId) & 0x80000000)){ //short form
						long data = dataId | locationMask | ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);
						if(needToSwap)SwapLongBlock(&data,1);
						CB_writeDataBlock(&data,1);
					}
					else { //long form
						long data[2];
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

int Readout_Gretina(SBC_crate_config* config,int index)
{

#define kGretinaFIFOEmpty		0x800
#define kGretinaFIFOAlmostEmpty 0x1000
#define kGretinaFIFOHalfFull	0x2000
#define kGretinaFIFOAllFull		0x4000

	unsigned long baseAddress			= config->card_info[index].base_add;
	unsigned long fifoStateAddress	    = baseAddress + config->card_info[index].deviceSpecificData[0];
	unsigned long fifoAddress	        = baseAddress * 0x100;
    unsigned long dataId				= config->card_info[index].hw_mask[0];
    unsigned long slot					= config->card_info[index].slot;
    unsigned long crate					= config->card_info[index].crate;
    unsigned long location              = ((crate&0x0000000f)<<21) | ((slot& 0x0000001f)<<16);

	unsigned short fifoState;
	//read the fifo state
	int result	= vme_read(vmeAM29Handle,fifoStateAddress,(unsigned char*)&fifoState,2); 
    long dataBuffer[0xffff];
	if(result == 2 && ((fifoState & kGretinaFIFOEmpty) != 0)){
		unsigned long numLongs = 0;
		dataBuffer[numLongs++] = dataId | 0; //we'll fill in the length later
        dataBuffer[numLongs++] = location;
		
		//read the first longword which should be the packet separator: 0xAAAAAAAA
		unsigned long theValue;
	    result	= vme_read(vmeAM39Handle,fifoAddress,(unsigned char*)&theValue,4); 
		
		if(result == 4 && (theValue==0xAAAAAAAA)){
			
            //read the first word of actual data so we know how much to read
	        result	= vme_read(vmeAM39Handle,fifoAddress,(unsigned char*)&theValue,4); 
			
			dataBuffer[numLongs++] = theValue;
						
			unsigned long numLongsLeft  = ((theValue & 0xffff0000)>>16)-1;
			
		    result	= vme_read(vmeAM39Handle,fifoAddress,(unsigned char*)&dataBuffer[numLongs],4*numLongsLeft); 
						  
			long totalNumLongs = (numLongs + numLongsLeft);
			dataBuffer[0] |= totalNumLongs; //see, we did fill it in...
            CB_writeDataBlock(dataBuffer,totalNumLongs);	
		}
		else {
			//oops... really bad -- the buffer read is out of sequence -- dump it all
            while(1){
                unsigned short val;
                //read the fifo state
	           int result	= vme_read(vmeAM29Handle,fifoStateAddress,(unsigned char*)&val,2); 

                 if(result ==2 && (val & kGretinaFIFOEmpty) != 0){
                    //read the first longword which should be the packet separator: 0xAAAAAAAA
                    unsigned long theValue;
  	                result	= vme_read(vmeAM39Handle,fifoAddress,(unsigned char*)&theValue,4); 
                     
                    if(result == 4 && theValue==0xAAAAAAAA){
                        //read the first word of actual data so we know how much to read
    	               result	= vme_read(vmeAM39Handle,fifoAddress,(unsigned char*)&val,4); 
    	               if(result != 4)break;
    	               result	= vme_read(vmeAM39Handle,fifoAddress,(unsigned char*)dataBuffer,4*((val & 0xffff0000)>>16)-1);                                                          
     	               if(result != ((val & 0xffff0000)>>16)-1)break;
                   }
                    else {
                        break;
                    }
                }
                else break;
             }
		}
	}
	return config->card_info[index].next_Card_Index;
}            
