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
#include "VME_Trigger32.h"
#include "universe_api.h"
#include "SBC_Config.h"
#include "VME_HW_Definitions.h"
#include "HW_Readout.h"

extern TUVMEDevice* vmeAM29Handle;
extern int32_t  dataIndex;
extern int32_t* data;

int32_t Readout_TR32_Data(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
	//-------------------------------- local variables --------------------------//
    uint32_t baseAddress, low_word, high_word, statusReg;
    unsigned short placeHolderIndex;
    short leaf_index;
    SBC_LAM_Data localData;
    
    uint32_t kTrigger1EventMask                = 1L << 0;
    uint32_t kValidTrigger1GTClockMask         = 1L << 1;
    uint32_t kTrigger2EventMask                = 1L << 2;
    uint32_t kValidTrigger2GTClockMask         = 1L << 3;
    //uint32_t kCountErrorMask                   = 1L << 4;
    //uint32_t kTimeClockCounterEnabledMask      = 1L << 5;
    //uint32_t kTrigger2EventInputEnabledMask    = 1L << 6;
    //uint32_t kBusyOutputEnabledMask            = 1L << 7;
    //uint32_t kTrigger1GTOutputOREnabledMask    = 1L << 8;
    //uint32_t kTrigger2GTOutputOREnabledMask    = 1L << 9;
    uint32_t kMSamEventMask                    = 1L << 10;
    
    uint32_t  kTrigger2GTEventReset        = 0x0A;     //resets trigger2 adc event and trigger2 GT clock status bits
    uint32_t  kTrigger1GTEventReset        = 0x0C;     //reset muix event and valid trigger1 GT clock status bits
    uint32_t  kTestLatchTrigger2Time       = 0x12;     //latches the Time Clock into trigger2 Timer register
    uint32_t  kTestLatchTrigger1Time       = 0x16;     //latches the Time Clock into trigger1 Timer register
    uint32_t  kStatusRegOffset             = 0x14; 
    uint32_t  kReadTrigger2GTID            = 0x18;    //read the trigger2 GTID
    uint32_t  kReadTrigger1GTID            = 0x1C;    //read the trigger1 GTID
    uint32_t  kReadLowerTrigger2TimeReg    = 0x20;     
    uint32_t  kMSamEventReset              = 0x22;    //reset the M-SAM status bit.
    uint32_t  kReadUpperTrigger2TimeReg    = 0x24;     
    uint32_t  kReadLowerTrigger1TimeReg    = 0x28;	    
    uint32_t  kReadUpperTrigger1TimeReg    = 0x2C;	    
    uint32_t  kReadAuxGTIDReg              = 0x3C;	    
 
          
    uint32_t kShipEvt1ClkMask    = 1L<<0;
    uint32_t kShipEvt2ClkMask    = 1L<<1;
    uint32_t kUseSoftwareGtid    = 1L<<2;
    uint32_t kUseMSam            = 1L<<3;
    uint32_t savedIndex;
    uint32_t gtid;
    uint32_t gtidShortForm;
	uint32_t result;
	uint32_t lValue;
	uint16_t sValue;
    //--------------------------------------------------------------------------//

    if(index<0)return -1;
    
    //read the status register
	baseAddress = config->card_info[index].base_add;
	
	result    = read_device(vmeAM29Handle,(char*)&statusReg,4,baseAddress + kStatusRegOffset); //short access, the adc Value
    if (result!=kSBC_Success) {
		LogError("Rd Err: TR32 0x%04x Status",baseAddress);
        return config->card_info[index].next_Card_Index;
    }
    
 	//--------------------------------------------------------------------------------------------------------
	// Handle Trigger #1
	//--------------------------------------------------------------------------------------------------------
	//check for the event1 bit
    if(statusReg & kTrigger1EventMask){
        unsigned char gtBitSet = 0;

        gtidShortForm =  config->card_info[index].hw_mask[1] & 0x80000000L;
			
        //save the data word index in case we have to dump this event because of an error
        savedIndex = dataIndex;
        localData.numFormatedWords = 0;
        localData.numberLabeledDataWords = 0;
        
        if(config->card_info[index].deviceSpecificData[0]&kUseSoftwareGtid){
        
            //must latch the clock if in soft gtid mode
 			lValue = 0;
			result = write_device(vmeAM29Handle,(char*)&lValue,sizeof(uint32_t),baseAddress+kTestLatchTrigger1Time);
			
             if (result != kSBC_Success) {
				LogError("Wr Err: TR32 0x%04x Trig1 Latch",baseAddress);
				return config->card_info[index].next_Card_Index;
            }
           
			result    = read_device(vmeAM29Handle,(char*)&gtid,4,baseAddress + kStatusRegOffset); //short access, the adc Value
			if (result != kSBC_Success) {
				LogError("Rd Err: TR32 0x%04x Status",baseAddress);
				return config->card_info[index].next_Card_Index;
            }
            
            statusReg |= kValidTrigger1GTClockMask;
           
            gtBitSet = 1;
            
            ResetTR32(index,config,kTrigger1GTEventReset);
        }
        else {
            if(!(statusReg & kValidTrigger1GTClockMask)){
                //should have been a gt, try some more--but not too many times.
                int k;
                for(k=0;k<5;k++){
                    //read the status reg
  					result    = read_device(vmeAM29Handle,(char*)&statusReg,4,baseAddress + kStatusRegOffset); //short access, the adc Value
                  
                    if (result != kSBC_Success) {
					   LogError("Rd Err: TR32 0x%04x Status",baseAddress);
                       return config->card_info[index].next_Card_Index;
                    }
                    if(statusReg & kValidTrigger1GTClockMask)break;
                    else usleep(1);
                }
            }
            if(statusReg & kValidTrigger1GTClockMask){
                //read the gtid;
                if(!(config->card_info[index].deviceSpecificData[0]&kUseSoftwareGtid)){
					result    = read_device(vmeAM29Handle,(char*)&gtid,4,baseAddress + kReadTrigger1GTID); //short access, the adc Value
					if (result != kSBC_Success) {
						LogError("Rd Err: TR32 0x%04x Trig1 GTID",baseAddress);
						return config->card_info[index].next_Card_Index;
                    }
                }
                gtBitSet = 1;
            }
        }
        
        if(gtidShortForm){
            localData.formatedWords[localData.numFormatedWords++] = config->card_info[index].hw_mask[1] | (1L<<24) | (0x00ffffff&gtid);
        }
        else {
            localData.formatedWords[localData.numFormatedWords++] = config->card_info[index].hw_mask[1] | 2;
            localData.formatedWords[localData.numFormatedWords++] = (1L<<24) | (0x00ffffff&gtid);
        }
        if(config->card_info[index].deviceSpecificData[0]&kShipEvt1ClkMask){
            //read the time
			result    = read_device(vmeAM29Handle,(char*)&high_word,4,baseAddress + kReadUpperTrigger1TimeReg); //short access, the adc Value
			if (result != kSBC_Success) {
				LogError("Rd Err: TR32 0x%04x Upper Trig1",baseAddress);
                dataIndex = savedIndex; //dump the event back to the last marker
                return config->card_info[index].next_Card_Index;
            }
 			result    = read_device(vmeAM29Handle,(char*)&low_word,4,baseAddress + kReadLowerTrigger1TimeReg); //short access, the adc Value
			if (result != kSBC_Success) {
				LogError("Rd Err: TR32 0x%04x Low Trig1",baseAddress);
				dataIndex = savedIndex; //dump the event back to the last marker
                return config->card_info[index].next_Card_Index;
            }
            //clock data
            localData.formatedWords[localData.numFormatedWords++] = config->card_info[index].hw_mask[0] | 3;
            localData.formatedWords[localData.numFormatedWords++] = (1L<<24) | (high_word & 0x00ffffff);
            localData.formatedWords[localData.numFormatedWords++] = low_word;
        }
        

        //------labeled data that can be passed back to the mac---- 
        // "GTID"			gtid
        // "MSAMEvent"		isMSAM event
        // "MSAMPrescale"	MSAM prescale value
        //--------------------
		strcpy(localData.labeledData[localData.numberLabeledDataWords].label,"GTID");
        localData.labeledData[localData.numberLabeledDataWords].data = gtid;
		localData.numberLabeledDataWords++;
		 
		if(!gtBitSet){
            //the gt bit was NOT set, ditch the event and reset
            ResetTR32(index,config,kTrigger1GTEventReset);
        }
 
        //MSAM is a special bit that is set if a trigger 1 has occurred within 15 microseconds after a trigger2
        if(config->card_info[index].deviceSpecificData[0] & kUseMSam){
            unsigned short reReadStatusReg = statusReg;
            int i;
            for(i=0;i<15;i++){
                if((reReadStatusReg & kValidTrigger1GTClockMask) && !(reReadStatusReg & kMSamEventMask)){
                    usleep(1);
					result    = read_device(vmeAM29Handle,(char*)&reReadStatusReg,4,baseAddress + kStatusRegOffset); //short access, the adc Value
  
                    if (result != kSBC_Success) {
						LogError("Rd Err: TR32 0x%04x Status",baseAddress);
						return config->card_info[index].next_Card_Index;
                    }
                    
                    if(reReadStatusReg & kMSamEventMask) break;
                }
                else break;
				usleep(1);
            }                
  
			strcpy(localData.labeledData[localData.numberLabeledDataWords].label,"MSAMEvent");
			localData.labeledData[localData.numberLabeledDataWords].data = (reReadStatusReg & kMSamEventMask)!=0;
			localData.numberLabeledDataWords++;

			strcpy(localData.labeledData[localData.numberLabeledDataWords].label,"MSAMPrescale");
			localData.labeledData[localData.numberLabeledDataWords].data = config->card_info[index].deviceSpecificData[1];
			localData.numberLabeledDataWords++;
            
            sValue = 1;
			result = write_device(vmeAM29Handle,(char*)&sValue,sizeof(uint16_t),baseAddress+kMSamEventReset);
			if (result != kSBC_Success) {
				LogError("Wr Err: TR32 0x%04x SAM Reset",baseAddress);
			}
		}
        
        //read out the children for event 1
        leaf_index = config->card_info[index].next_Trigger_Index[0];
        while(leaf_index >= 0) {
			//if the next object is NOT a lam object, then we'll just put the formated data into the data stream
			if(config->card_info[leaf_index].hw_type_id != kSBCLAM){
				int j;
				for(j=0;j<localData.numFormatedWords;j++){
					data[dataIndex++] = localData.formatedWords[j];
				}
			}
			leaf_index = readHW(config,leaf_index,&localData);
		}
	}
    
    if(!(statusReg & kTrigger2EventMask)){
        //if the trigger 2 is NOT set at this point check the status word again in case an event 
        //happened while we were reading out the event 1.
		result    = read_device(vmeAM29Handle,(char*)&statusReg,4,baseAddress + kStatusRegOffset); //short access, the adc Value
        if (result != kSBC_Success) {
			LogError("Rd Err: TR32 0x%04x Status",baseAddress);
            return config->card_info[index].next_Card_Index;
        }
    }
    
	//--------------------------------------------------------------------------------------------------------
	//Handle Trigger #2
	//Note for debugging. EVERY variable in the following block should have a '2' in it if is referring to
    //an event, gtid, or placeholder.
 	//--------------------------------------------------------------------------------------------------------
   if(statusReg & kTrigger2EventMask){
        //event mask 2 is special and requires that the children's hw be readout BEFORE the GTID
        //word is read. Reading the GTID clears the event 2 bit in the status word and can cause
        //a lockout of the hw.
        gtidShortForm =  config->card_info[index].hw_mask[2] & 0x80000000L;

        if(config->card_info[index].deviceSpecificData[0]&kUseSoftwareGtid){
             //must latch the clock if in soft gtid mode
			lValue = 0;
			result = write_device(vmeAM29Handle,(char*)&lValue,sizeof(uint32_t),baseAddress+kTestLatchTrigger2Time);
			if (result != kSBC_Success) {
				LogError("Wr Err: TR32 0x%04x Latch Trig2",baseAddress);
				return config->card_info[index].next_Card_Index;
            }
			//soft gtid, so set the bit ourselves
            statusReg |= kValidTrigger2GTClockMask;
        }
        else if(!(statusReg & kValidTrigger2GTClockMask)){
            //should have been a gt, maybe we're too fast. try some more--but not too many times.
            int k;
            for(k=0;k<5;k++){
				result    = read_device(vmeAM29Handle,(char*)&statusReg,4,baseAddress + kStatusRegOffset); //short access, the adc Value
				if (result != kSBC_Success) {
					LogError("Rd Err: TR32 0x%04x Status",baseAddress);
					return config->card_info[index].next_Card_Index;
                }
                if(statusReg & kValidTrigger2GTClockMask)break;
                else  usleep(1);
            }
        }
        
        if(statusReg & kValidTrigger2GTClockMask){
            int32_t gtid;
            savedIndex = dataIndex;
            
            placeHolderIndex = dataIndex; //reserve space for the gtid and save the pointer so we can replace it later
                                          //load a dummy gtid--we'll replace it later if we can.
            if(gtidShortForm){
                data[dataIndex++] = config->card_info[index].hw_mask[2] | (1L<<25) | 0x00ffffff;
            }
            else {
                data[dataIndex++] = config->card_info[index].hw_mask[2] | 2;
                data[dataIndex++] = (1L<<25) | 0x00ffffff;
            }
            if(config->card_info[index].deviceSpecificData[0] & kShipEvt2ClkMask){
                //load a dummy time--we'll replace it later if we can.
                data[dataIndex++] = config->card_info[index].hw_mask[0] | 3;
                data[dataIndex++] = (1L<<25);
                data[dataIndex++] = 0;
            }        
            
            //read out the event2 children
            leaf_index = config->card_info[index].next_Trigger_Index[1];
            while(leaf_index >= 0)	leaf_index = readHW(config,leaf_index,&localData);

            
            if(!(config->card_info[index].deviceSpecificData[0]&kUseSoftwareGtid)){
				result    = read_device(vmeAM29Handle,(char*)&gtid,4,baseAddress + kReadTrigger2GTID); //short access, the adc Value
                if (result != kSBC_Success){
                    LogError("Rd Err: TR32 0x%04x Trig2 GTID",baseAddress);
                    dataIndex = savedIndex; //dump the event back to the last marker
                    return config->card_info[index].next_Card_Index;
                }
            }
            else {
  				result    = read_device(vmeAM29Handle,(char*)&gtid,4,baseAddress + kReadAuxGTIDReg); //short access, the adc Value
				if (result != kSBC_Success) {
					LogError("Rd Err: TR32 0x%04x AuxGTID",baseAddress);
                    return config->card_info[index].next_Card_Index;
                }
                ResetTR32(index,config,kTrigger2GTEventReset);
            }
            
            if(savedIndex != dataIndex){   //check if data was taken and is waiting in the que
                                           //OK there was some data so pack the gtid.
                if(gtidShortForm){
                    data[placeHolderIndex++] = config->card_info[index].hw_mask[2] | (1L<<25) | (0x00ffffff&gtid);
                }
                else {
                    data[placeHolderIndex++] = config->card_info[index].hw_mask[2] | 2;
                    data[placeHolderIndex++] = (1L<<25) | (0x00ffffff&gtid);
                }
                if((config->card_info[index].deviceSpecificData[0]&kShipEvt2ClkMask)!=0){
                    
                    //get the time
					result    = read_device(vmeAM29Handle,(char*)&high_word,4,baseAddress + kReadUpperTrigger2TimeReg); //short access, the adc Value
					if (result != kSBC_Success) {
						LogError("Rd Err: TR32 0x%04x Upper Trig2",baseAddress);
                       dataIndex = savedIndex; //dump the event back to the last marker
                        return config->card_info[index].next_Card_Index;
                    }
				
					result    = read_device(vmeAM29Handle,(char*)&low_word,4,baseAddress + kReadLowerTrigger2TimeReg); //short access, the adc Value
                    if (result != kSBC_Success) {
  						LogError("Rd Err: TR32 0x%04x LowerTrig2",baseAddress);
						dataIndex = savedIndex; //dump the event back to the last marker
                        return config->card_info[index].next_Card_Index;
                    }
                    
                    data[placeHolderIndex++] = config->card_info[index].hw_mask[0] | 3;
                    data[placeHolderIndex++] = (1L<<25) | (high_word & 0x00ffffff);
                    data[placeHolderIndex++] = low_word;
                }
            }
        }
    }
    
	return config->card_info[index].next_Card_Index;
    
}

void ResetTR32(int32_t index,SBC_crate_config* config,unsigned short offset)
{
    if(index>=0){
		uint16_t value = 1;
	    int32_t result = write_device(vmeAM29Handle,(char*)&value,sizeof(uint16_t),config->card_info[index].base_add+offset);
		if(result != kSBC_Success){
			LogError("Wr Err: TR32 0x%04x Reset",config->card_info[index].base_add);
		}
	}
}
