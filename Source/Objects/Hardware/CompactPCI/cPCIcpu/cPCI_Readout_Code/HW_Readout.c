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
#include "SBC_Config.h"
#include "AcqirisDC440.h"

extern char needToSwap;

void processHWCommand(SBC_Packet* aPacket)
{
	/*look at the first word to get the destination*/
	long destination = aPacket->cmdHeader.destination;
	switch(destination){
		case kAcqirisDC440:	 processAcquirisDC440Command(aPacket); break;
		default:			 break;
	}
}

void startHWRun (SBC_crate_config* config)
{	
	long index = 0;
	while(1){
		switch(config->card_info[index].hw_type_id){
			case kAcqirisDC440: index = Start_AqirisDC440(index, config); break; /*Acqiris DC440 Digitizer*/
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
			case kAcqirisDC440: index = Stop_AqirisDC440(index, config); break; /*Acqiris DC440 Digitizer*/
			default:     index =  -1; break;
		}
		if(index>=config->total_cards || index<0)break;
	}
}

void readHW(SBC_crate_config* config)
{
	long index = 0;
	while(1){
		switch(config->card_info[index].hw_type_id){
			case kAcqirisDC440:														//Acqiris DC440 Digitizer
				Readout_DC440( config->card_info[index].base_add,					//the address
							   config->card_info[index].deviceSpecificData[0],		//the number of Samples
							   config->card_info[index].deviceSpecificData[1],		//enable Mask
							   config->card_info[index].hw_mask[0],					//the dataID
							   ((config->card_info[index].crate & 0x0f) << 21) |
							   ((config->card_info[index].slot  & 0x1f) << 16),		//the location (crate,card)
								1,													//restart == YES
								1);													//use Circular Buffer == YES
				index = config->card_info[index].next_Card_Index;
			break;												
			default:			index =  -1; break;
		}
		if(index>=config->total_cards || index<0)break;
	}
}

void FindHardware(void)
{
	ClearAcqirisInitFlag();
	FindAcqirisDC440s();
}

void ReleaseHardware(void)
{
	ReleaseAcqirisDC440s();
}

void doWriteBlock(SBC_Packet* aPacket)
{
	SBC_WriteBlockStruct* p = (SBC_WriteBlockStruct*)aPacket->payload;
	if(needToSwap)SwapLongBlock(p,sizeof(SBC_WriteBlockStruct)/sizeof(long));
	long startAddress = p->address;
	long num = p->numLongs;
	p++;
	int i;
	long* dataToRead = (long*)p;
	if(needToSwap)SwapLongBlock(dataToRead,num);
	for(i=0;i<num;i++){
		writeAddress(startAddress+i,dataToRead[i]);
	}
}

void doReadBlock(SBC_Packet* aPacket)
{
	//what to read?
	SBC_ReadBlockStruct* p = (SBC_ReadBlockStruct*)aPacket->payload;
	if(needToSwap)SwapLongBlock(p,sizeof(SBC_ReadBlockStruct)/sizeof(long));
	int numLongs = p->numLongs;
	int address  = p->address;

	//OK, got address and # to read, set up the response and go get the data
	aPacket->cmdHeader.destination	= kSBC_Process;
	aPacket->cmdHeader.cmdID		= kSBC_ReadBlock;
	aPacket->cmdHeader.numberBytesinPayload	= sizeof(SBC_ReadBlockStruct) + numLongs*sizeof(long);
	
	SBC_ReadBlockStruct* optionPtr = (SBC_ReadBlockStruct*)aPacket->payload;
	optionPtr->numLongs = numLongs;
	optionPtr->address  = address;
	if(needToSwap)SwapLongBlock(optionPtr,sizeof(SBC_ReadBlockStruct)/sizeof(long));
	optionPtr++;
	
	long* lPtr		= (long*)optionPtr;
	long* startPtr	= lPtr;
	int i;
	for(i=0;i<numLongs;i++)*lPtr++ = readAddress(address+i);    //read from hardware addresses
	if(needToSwap)SwapLongBlock(startPtr,numLongs/sizeof(long));

	writeBuffer(aPacket);
	
}

//--------------------------------------------------------
//this stuff will be replaced with SBC HW access routines when we figure out how to do it.
long testBuffer[] = {10,11,12,13,14,15};

long readAddress(long address)
{
	if(address<6)return testBuffer[address];
	else return 0;
}

void writeAddress(long address,long value)
{
	testBuffer[address] = value;
}
//--------------------------------------------------------


