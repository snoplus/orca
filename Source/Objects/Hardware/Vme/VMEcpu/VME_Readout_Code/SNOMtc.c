/*
 *  VME_Trigger32.c
 *  OrcaIntel
 *
 *  Created by Mark Howe on 1/8/08.
 *  Copyright 2008 CENPA, University of Washington. All rights reserved.
 *
 */
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

#include <unistd.h>
#include <string.h>
#include "SBC_Readout.h"
#include "SNOMtcCmds.h"
#include "universe_api.h"
#include "SBC_Config.h"
#include "VME_HW_Definitions.h"
#include "HW_Readout.h"
#include "SNOMtc.h"

extern int32_t		dataIndex;
extern int32_t*		data;
extern char			needToSwap;

void processMTCCommand(SBC_Packet* aPacket)
{
	switch(aPacket->cmdHeader.cmdID){		
		case kSNOMtcLoadXilinx:
			loadXilinx(aPacket);
			break;
	}
}

void loadXilinx(SBC_Packet* aPacket)
{
	SNOMtc_XilinxLoadStruct* p = (SNOMtc_XilinxLoadStruct*)aPacket->payload;
	//swap if needed, but note that we don't swap the data file part
	if(needToSwap) SwapLongBlock(p,sizeof(SNOMtc_XilinxLoadStruct)/sizeof(int32_t));
	
	//pull the addresses and offsets from the payload
	uint32_t baseAddress    = p->baseAddress;
	int32_t addressModifier = p->addressModifier;
	int32_t programReg      = baseAddress + p->programRegOffset;
	int32_t fileSize        = p->fileSize;
	int32_t lastByte		= fileSize;
	uint8_t* charData		= (uint8_t*)p;			//recast p so we can treat it like a char ptr.
	charData += sizeof(SNOMtc_XilinxLoadStruct);	//point to the file data
	
	//--------------------------- The file format as of 1/7/97 -------------------------------------
	//
	// 1st field: Beginning of the comment block -- /
	//			  If no backslash then you will get an error message and Xilinx load will abort
	// Now include your comment.
	// The comment block is delimited by another backslash.
	// If no backslash at the end of the comment block then you will get error message.
	//
	// After the comment block include the data in ACSII binary.
	// No spaces or other characters in between data. It will complain otherwise.
	//
	//----------------------------------------------------------------------------------------------
	
	uint32_t result;
	uint32_t bitCount	= 0UL;
	uint32_t readValue	= 0UL;
	uint32_t aValue		= 0UL;
	uint8_t  firstPass	= 1;
	uint8_t  errorFlag	= 0;
	char  errorMessage[80];
	uint32_t byte = 0;
	strcpy(errorMessage,"\0");		

	const uint32_t DATA_HIGH_CLOCK_LOW = 0x00000001; 	 // bit 0 high and bit 1 low
	const uint32_t DATA_LOW_CLOCK_LOW  = 0x00000000;  	 // bit 0 low and bit 1 low
	
	TUVMEDevice* device = get_new_device(0x0, addressModifier, 4, 0x10000);
	if(device != 0){
		aValue = 0x00000008;				// set  all bits, except bit 3[PROG_EN], low -- new step 1/16/97
		result = write_device(device, (char*)(&aValue), 4, programReg);
		if(result == 4){
			aValue = 0x00000002;			// set  all bits, except bit 1[CCLK], low				
			result = write_device(device, (char*)(&aValue), 4, programReg);
			usleep(100000);					// 100 msec delay
		}
		
		if(result != 4){
			strcpy(errorMessage,"Error writing to program register.");		
			errorFlag = 1;	//early exit
		}
				
		if(!errorFlag) for (byte=0; byte<lastByte; byte++){
			if ( firstPass && (*charData != '/') ){
				strcpy(errorMessage,"Invalid first character in Xilinx file.");		
				errorFlag = 2;	//early exit
				break;
			}
			
			if (firstPass){
			
				firstPass = 0;
			
				charData++;							// for the first slash
				byte++;  							// need to keep track of i
			
				while(*charData++ != '/'){
					byte++;
					if ( byte>lastByte ){			
						strcpy(errorMessage,"Comment block not delimited by a backslash..");		
						errorFlag = 3;
						break;		//early exit
					}
				}
				byte++;
			}
			
			if(errorFlag)break;		//early exit
			
			// strip carriage return, tabs
			if ( ((*charData =='\r') || (*charData =='\n') || (*charData =='\t' )) && (!firstPass) ){		
				charData++;
			}
			else {
				
				bitCount++;
				if (      *charData == '1' ) aValue = DATA_HIGH_CLOCK_LOW;	// bit 0 high and bit 1 low
				else if ( *charData == '0' ) aValue = DATA_LOW_CLOCK_LOW;	// bit 0 low and bit 1 low
				else {
					strcpy(errorMessage,"Invalid character in Xilinx file.");		
					errorFlag = 4;
					break; //early exit
				}
				charData++;

				result = write_device(device, (char*)(&aValue), 4, programReg);
				if(result == 4){
					aValue |= (1UL << 1);	 // perform bitwise OR to set the bit 1 high[toggle clock high]	
					
					result = write_device(device, (char*)(&aValue), 4, programReg);
					if(result != 4)errorFlag = 6;
				}
				else errorFlag = 5;
				
				if(errorFlag){
					strcpy(errorMessage,"Xilinx load failed. Unable to toggle mtc clock.");		
					errorFlag = 7;
					break; //early exit
				}
			}
		}
		
	}
	else {
		errorFlag = 1;
		strcpy(errorMessage,"XUnable to get device.");		
	}
	if(!errorFlag){
		
		usleep(100000); // 10 msec delay
		// check to see if the Xilinx was loaded properly 
		// read the bit 2, this should be high if the Xilinx was loaded
		result = read_device(device,(char*)(&readValue),4,programReg);
		
		if ((result != 4) | !(readValue & 0x000000010)){	// bit 4, PROGRAM*, should be high for Xilinx success		
			if(result!=4)strcpy(errorMessage,"Xilinx load failed for the MTC/D! (final check failed)");		
			else strcpy(errorMessage,"Xilinx load failed for the MTC/D! (PROGRAM*, bit 4 not high at end)");		
			errorFlag |= 0x80000000;
		}
	}
	/* echo the structure back with the error code*/
	/* 0 == no Error*/
	/* non-0 means an error*/
	SNOMtc_XilinxLoadStruct* returnDataPtr = (SNOMtc_XilinxLoadStruct*)aPacket->payload;
	uint32_t errLen = strlen(errorMessage);
	if(errLen >= kSBC_MaxMessageSize-1){
		errLen = kSBC_MaxMessageSize-1;
		aPacket->message[kSBC_MaxMessageSize-1] = '\0';	
	}
	strncpy(aPacket->message,errorMessage,errLen);
	
	returnDataPtr->baseAddress      = baseAddress;
	returnDataPtr->programRegOffset = programReg;
	returnDataPtr->addressModifier  = addressModifier;
	returnDataPtr->errorCode		= errorFlag;
	returnDataPtr->fileSize         = byte;
	
	int32_t* lptr = (int32_t*)returnDataPtr;
	if(needToSwap) SwapLongBlock(lptr,sizeof(SNOMtc_XilinxLoadStruct)/sizeof(int32_t));
	
	writeBuffer(aPacket);  
	close_device(device);

}
