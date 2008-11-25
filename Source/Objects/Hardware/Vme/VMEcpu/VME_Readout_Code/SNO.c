/*
 *  SNO.c
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
#include "SNOCmds.h"
#include "universe_api.h"
#include "SBC_Config.h"
#include "VME_HW_Definitions.h"
#include "HW_Readout.h"
#include "SNO.h"

extern int32_t		dataIndex;
extern int32_t*		data;
extern char			needToSwap;

void processSNOCommand(SBC_Packet* aPacket)
{
	switch(aPacket->cmdHeader.cmdID){		
		case kSNOMtcLoadXilinx: loadMtcXilinx(aPacket); break;
		case kSNOXL2LoadClocks: loadXL2Clocks(aPacket); break;
		case kSNOXL2LoadXilinx: loadXL2Xilinx(aPacket); break;
	}
}

void loadMtcXilinx(SBC_Packet* aPacket)
{
	SNOMtc_XilinxLoadStruct* p = (SNOMtc_XilinxLoadStruct*)aPacket->payload;
	//swap if needed, but note that we don't swap the data file part
	if(needToSwap) SwapLongBlock(p,sizeof(SNOMtc_XilinxLoadStruct)/sizeof(int32_t));
	
	//pull the addresses and offsets from the payload
	uint32_t baseAddress    = p->baseAddress;
	uint32_t addressModifier = p->addressModifier;
	uint32_t programReg      = baseAddress + p->programRegOffset;
	uint32_t fileSize        = p->fileSize;
	uint32_t lastByte		= fileSize;
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
	memset(errorMessage,'\0',80);		

	const uint32_t DATA_HIGH_CLOCK_LOW = 0x00000001; 	 // bit 0 high and bit 1 low
	const uint32_t DATA_LOW_CLOCK_LOW  = 0x00000000;  	 // bit 0 low and bit 1 low
	
	TUVMEDevice* device = get_new_device(0x0, addressModifier, 4, 0x10000);
	if(device != 0){
		aValue = 0x00000008;				// set  all bits, except bit 3[PROG_EN], low -- new step 1/16/97
		result = write_device(device, (char*)(&aValue), 4, programReg);
		if(result == 4){
			aValue = 0x00000002;			// set  all bits, except bit 1[CCLK], low				
			result = write_device(device, (char*)(&aValue), 4, programReg);
			usleep(10000);					// 100 msec delay
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
		
		if(!errorFlag){
			
			usleep(10000); // 10 msec delay
			// check to see if the Xilinx was loaded properly 
			// read the bit 2, this should be high if the Xilinx was loaded
			result = read_device(device,(char*)(&readValue),4,programReg);
			
			if ((result != 4) | !(readValue & 0x000000010)){	// bit 4, PROGRAM*, should be high for Xilinx success		
				if(result!=4)strcpy(errorMessage,"Xilinx load failed for the MTC/D! (final check failed)");		
				else strcpy(errorMessage,"Xilinx load failed for the MTC/D! (PROGRAM*, bit 4 not high at end)");		
				errorFlag |= 0x80000000;
			}
		}
	}
	else {
		errorFlag = 1;
		strcpy(errorMessage,"Unable to get device.");		
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

void loadXL2Clocks(SBC_Packet* aPacket)
{
	SNOXL2_ClockLoadStruct* p = (SNOXL2_ClockLoadStruct*)aPacket->payload;
	//swap if needed, but note that we don't swap the data file part
	if(needToSwap) SwapLongBlock(p,sizeof(SNOXL2_ClockLoadStruct)/sizeof(int32_t));
	
	//pull the addresses and offsets from the payload
	uint32_t addressModifier		= p->addressModifier;
	uint32_t xl2_select_reg			= p->xl2_select_reg;
	//uint32_t xl2_select_xl2			= p->xl2_select_xl2;
	uint32_t xl2_clock_cs_reg		= p->xl2_clock_cs_reg;
	uint32_t xl2_master_clk_en		= p->xl2_master_clk_en;
	uint32_t allClocksEnabled		= p->allClocksEnabled;
	uint8_t* charData				= (uint8_t*)p;			//recast p so we can treat it like a char ptr.
	charData += sizeof(SNOXL2_ClockLoadStruct);				//point to the clock file data

	uint8_t  errorFlag	= 0;
	char errorMessage[80];
	memset(errorMessage,'\0',80);		

	TUVMEDevice* device = get_new_device(0x0, addressModifier, 4, 0x10000);
	if(device != 0){
		//do the clock load
		//-------------- variables -----------------
		uint32_t result;
		uint32_t theOffset	= 0;	
		uint32_t writeValue;
		uint32_t bit17		= 0x20000;
		
		//result = write_device(device, (char*)(&xl2_select_xl2), 4, xl2_select_reg);			//select the XL2 --do we need to do this, the value is wiped next line
			
		//enable master clock
		result = write_device(device, (char*)(&bit17), 4, xl2_select_reg);					//xl2_clock_cs_reg requires bit 17 set
		if(result != 4){
			strcpy(errorMessage,"Error selecting clock reg.");		
			errorFlag = 1;	//early exit
		}
		else {
			result = write_device(device, (char*)(&xl2_master_clk_en), 4, xl2_clock_cs_reg);	//enable master clock
			if(result != 4){
				strcpy(errorMessage,"Error enabling master clock.");		
				errorFlag = 2;	//early exit
			}
		}
		if(!errorFlag){
			int j;
			for(j = 1; j<=3; j++){			// there are three clocks, Memory, Sequencer and ADC
				
				// skip the comment line
				while ( *charData != '\r' ) charData++;
				
				charData++;
				
				// the first field has to be a ONE or a ZERO
				if ( ( *charData != '1') && ( *charData != '0')) {
					strcpy(errorMessage,"Invalid first characer in clock file.");		
					errorFlag = 1;
					break; //early exit
				}
				int i;
				for (i = 1; i<=4; i++){		// there are four lines of data per clock
					while ( *charData != '\r' ){    
						
						writeValue = xl2_master_clk_en;	// keep the master clock enabled
						if( *charData == '1' ){
							writeValue |= (1UL<< (1 + theOffset));
						}
						charData++;
						
						result = write_device(device, (char*)(&writeValue), 4, xl2_clock_cs_reg);
						if(result != 4){
							strcpy(errorMessage,"Error loading clock bit.");		
							errorFlag = 2;	//early exit
							break;
						}
						
						if (theOffset == 0)	writeValue += 1;
						else				writeValue |= (1UL << theOffset);
						
						result = write_device(device, (char*)(&writeValue), 4, xl2_clock_cs_reg);
						if(result != 4){
							strcpy(errorMessage,"Error loading clock bit.");		
							errorFlag = 3;	//early exit
							break;
						}
						
					}
					
					charData++;
				}
				theOffset += 4;
			}
			
			// keep the master clock enabled and enable all three clocks
			writeValue = allClocksEnabled;	
			result = write_device(device, (char*)(&writeValue), 4, xl2_clock_cs_reg);
			if(result != 4){
				strcpy(errorMessage,"Error loading clock bit.");		
				errorFlag = 4;	//early exit
			}
			
		}
		if(!errorFlag){
			writeValue = 0;
			result = write_device(device, (char*)(&writeValue), 4, xl2_select_reg);			//deselect all
			if(result != 4){
				strcpy(errorMessage,"Error deselecting xl2.");		
				errorFlag = 5;	//early exit
			}
		}
	}
	else {
		errorFlag = 1;
		strcpy(errorMessage,"Unable to get device.");		
	}
	
	/* echo the structure back with the error code*/
	/* 0 == no Error*/
	/* non-0 means an error*/
	SNOXL2_ClockLoadStruct* returnDataPtr = (SNOXL2_ClockLoadStruct*)aPacket->payload;
	uint32_t errLen = strlen(errorMessage);
	if(errLen >= kSBC_MaxMessageSize-1){
		errLen = kSBC_MaxMessageSize-1;
		aPacket->message[kSBC_MaxMessageSize-1] = '\0';	
	}
	strncpy(aPacket->message,errorMessage,errLen);
	
	returnDataPtr->errorCode		= errorFlag;
	
	int32_t* lptr = (int32_t*)returnDataPtr;
	if(needToSwap) SwapLongBlock(lptr,sizeof(SNOXL2_ClockLoadStruct)/sizeof(int32_t));
	
	writeBuffer(aPacket);  
	close_device(device);
	
}

#define FATAL_ERROR(n,message) {strncpy(errorMessage,message,80);	errorFlag = n;	goto earlyExit;}

void loadXL2Xilinx(SBC_Packet* aPacket)
{
	SNOXL2_XilinixLoadStruct* p = (SNOXL2_XilinixLoadStruct*)aPacket->payload;
	//swap if needed, but note that we don't swap the data file part
	if(needToSwap) SwapLongBlock(p,sizeof(SNOXL2_XilinixLoadStruct)/sizeof(int32_t));
	
	//pull the addresses and other data from the payload
	uint32_t addressModifier		= p->addressModifier;
	uint32_t selectBits				= p->selectBits;
	uint32_t xl2_select_reg			= p->xl2_select_reg;
	uint32_t xl2_select_xl2			= p->xl2_select_xl2;
	uint32_t xl2_control_status_reg	= p->xl2_control_status_reg;
	uint32_t xl2_control_bit11		= p->xl2_control_bit11;
	uint32_t xl2_xilinx_user_control= p->xl2_xilinx_user_control;
	uint32_t xl2_xlpermit			= p->xl2_xlpermit;
	uint32_t xl2_enable_dp			= p->xl2_enable_dp;
	uint32_t xl2_disable_dp			= p->xl2_disable_dp;
	uint32_t xl2_control_clock		= p->xl2_control_clock;
	uint32_t xl2_control_data		= p->xl2_control_data;
	uint32_t xl2_control_done_prog	= p->xl2_control_done_prog;
	uint32_t length					= p->fileSize;
	uint8_t* charData				= (uint8_t*)p;			//recast p so we can treat it like a char ptr.
	charData += sizeof(SNOXL2_XilinixLoadStruct);				//point to the clock file data
	
	char  errorMessage[80];
	memset(errorMessage,'\0',80);		
	uint8_t  errorFlag		= 0;

	TUVMEDevice* device = get_new_device(0x0, addressModifier, 4, 0x10000);
	if(device != 0){
		//--------------------------- The file format as of 4/17/96 -------------------------------------
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
		
		uint32_t theDelay		= 40;	//mSec   ----- TBD -- this needs to be adjustable for each crate
		uint32_t bitCount		= 0UL;
		uint32_t writeValue		= 0UL;
		uint8_t  firstPass		= 1;
		uint32_t index			= length; 
		uint32_t result;

		//select the cards that will be inited
		result = write_device(device, (char*)(&selectBits), 4, xl2_select_reg);
		if(result!=4) FATAL_ERROR(3,"Write Error: select xl2");	

		// make sure that the XL2 DP bit is set low and bit 11 (xilinx active) is high -- this is not yet sent to the MB
		result = write_device(device, (char*)(&xl2_control_bit11), 4, xl2_control_status_reg);
		if(result!=4) FATAL_ERROR(3,"Write Error: Setting DP bit");	
		
		usleep(20000);	//200 ms
		
		// now toggle this on the MB and turn on the XL2 xilinx load permission bit
		// DO NOT USE CXL2_Secondary_Reg_Access here unless you retain the state
		// of the select bits in register zero!!!!		
		writeValue = xl2_xlpermit | xl2_enable_dp;
		result = write_device(device, (char*)(&writeValue), 4, xl2_xilinx_user_control);
		if(result!=4) FATAL_ERROR(3,"Write Error: xl2_xlpermit | xl2_enable_dp");	
		
		usleep(20000);	//200 ms
		
		// turn off the DP bit but keep 
		writeValue = xl2_xlpermit | xl2_disable_dp;
		result = write_device(device, (char*)(&writeValue), 4, xl2_xilinx_user_control);
		if(result!=4) FATAL_ERROR(3,"Write Error: xl2_xlpermit | xl2_disable_dp");	
		
		// set  bit 11 high, bit 10 high
		writeValue = xl2_control_bit11 | xl2_control_clock;
		result = write_device(device, (char*)(&writeValue), 4, xl2_control_status_reg);
		if(result!=4) FATAL_ERROR(3,"Write Error: xl2_control_bit11 | xl2_control_clock");	
		
		usleep(20000);	//200 ms
			
		uint32_t i;
		for (i = 1;i < index;i++){
			
			if ((firstPass) && (*charData != '/')) FATAL_ERROR(2,"Bad Xilinx File: Invalid first characer in xilinx file");
			
			if (firstPass){
				charData++;							// for the first backslash
				i++;  								// need to keep track of i
				while(*charData++ != '/'){
					
					i++;
					if (i>index) FATAL_ERROR(1,"Bad Xilinx File: Comment block not delimited by a backslash");
				}
			}
			firstPass = 0;
			
			// strip carriage return, tabs
			if ( ((*charData =='\r') || (*charData =='\n') || (*charData =='\t' )) && (!firstPass) )charData++;
			else {
				
				bitCount++;
				
				if      (*charData == '1')  writeValue = xl2_control_bit11 | xl2_control_data;	// bit set in data to load
				else if (*charData == '0')	writeValue = xl2_control_bit11;						// bit not set in data
				else						FATAL_ERROR(2,"Bad Xilinx File: Invalid character in Xilinx file");
				charData++;	
				
				int32_t val = writeValue | xl2_control_data;
				result = write_device(device, (char*)(&val), 4, xl2_control_status_reg); // changed PMT 1/17/98 to match Penn code
				if(result!=4)FATAL_ERROR(3,"Write Error: xl2_control_status_reg");
				usleep(theDelay);
				
				result = write_device(device, (char*)(&writeValue), 4, xl2_control_status_reg); // changed PMT 1/17/98 to match Penn code
				if(result!=4)FATAL_ERROR(4,"Write Error: xl2_control_status_reg");
				usleep(theDelay);
			}
		}

		usleep(20000);	//200 ms
		// QRA :5/31/97 -- do this before reading the DON_PROG bit. Xilinx Load on our
		// system now works. Why this should make any diferrence is a puzzle. 
		// More Changes, RGV, PW : turn off XLPERMIT & clear this register
		writeValue = 0UL;
		result = write_device(device, (char*)(&writeValue), 4, xl2_xilinx_user_control);
		if(result!=4)FATAL_ERROR(5,"Write Error: xl2_xilinx_user_control");
			
		usleep(20000);	//200 ms
		
		//check that the load was OK
		result = write_device(device, (char*)(&xl2_control_done_prog), 4, xl2_control_status_reg);	
		if(result!=4)FATAL_ERROR(6,"Write Error: xl2_control_status_reg");
		result = write_device(device, (char*)(&xl2_select_xl2), 4, xl2_select_reg);			
		if(result!=4)FATAL_ERROR(7,"Write Error: xl2_select_reg");

		result = write_device(device, (char*)(&xl2_control_bit11), 4, xl2_control_status_reg);
		if(result!=4)FATAL_ERROR(8,"Write Error: xl2_control_status_reg");
		uint32_t readValue = 0;
		result = read_device(device,(char*)(&readValue),4,xl2_control_status_reg);
		if(result!=4)FATAL_ERROR(9,"Write Error: xl2_control_status_reg");
							   
		if (!(readValue & xl2_control_done_prog)){	
			usleep(10000);
			result = read_device(device,(char*)(&readValue),4,xl2_control_status_reg);
			if(result!=4)FATAL_ERROR(10,"Write Error: Checking Prog Done");
			if (!(readValue & xl2_control_done_prog)){	
				if(result!=4)FATAL_ERROR(11,"Xilinx load failed XL2! (Status bit checked twice)");
			}
		}
					   
		result = write_device(device, (char*)(&xl2_control_done_prog), 4, xl2_control_status_reg);	//BLW 10/31/02-set bit 11 low, similar to previous version
		if(result!=4)FATAL_ERROR(12,"Write Error: xl2_control_status_reg");
		
	earlyExit:
		// now deselect all cards
		writeValue = 0;
		result = write_device(device, (char*)(&writeValue), 4, xl2_select_reg);
	}
	else {
		errorFlag = 1;
		strcpy(errorMessage,"Unable to get device.");		
	}

	/* echo the structure back with the error code*/
	/* 0 == no Error*/
	/* non-0 means an error*/
	SNOXL2_XilinixLoadStruct* returnDataPtr = (SNOXL2_XilinixLoadStruct*)aPacket->payload;
	uint32_t errLen = strlen(errorMessage);
	if(errLen >= kSBC_MaxMessageSize-1){
		errLen = kSBC_MaxMessageSize-1;
		aPacket->message[kSBC_MaxMessageSize-1] = '\0';	
	}
	strncpy(aPacket->message,errorMessage,errLen);
	
	returnDataPtr->errorCode		= errorFlag;
	
	int32_t* lptr = (int32_t*)returnDataPtr;
	if(needToSwap) SwapLongBlock(lptr,sizeof(SNOXL2_XilinixLoadStruct)/sizeof(int32_t));
	
	writeBuffer(aPacket);  
	close_device(device);
	
}



