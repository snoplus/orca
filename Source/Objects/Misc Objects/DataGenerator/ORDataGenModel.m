//
//  ORDataGenModel.m
//  Orca
//
//  Created by Mark Howe on Thu Oct 02 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORDataGenModel.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"
#import "SBC_Config.h"
#import "VME_HW_Definitions.h"

@implementation ORDataGenModel

#pragma mark ¥¥¥Initialization

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"DataGen"]];
}


- (unsigned long) dataId1D { return dataId1D; }
- (void) setDataId1D: (unsigned long) aDataId
{
    dataId1D = aDataId;
}
- (unsigned long) dataId2D { return dataId2D; }
- (void) setDataId2D: (unsigned long) aDataId
{
    dataId2D = aDataId;
}

- (unsigned long) dataIdWaveform { return dataIdWaveform; }
- (void) setDataIdWaveform: (unsigned long) aDataId
{
    dataIdWaveform = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId1D       = [assigner assignDataIds:kLongForm];
    dataId2D       = [assigner assignDataIds:kLongForm];
	dataIdWaveform = [assigner assignDataIds:kLongForm];
}


- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId1D:[anotherObj dataId1D]];
    [self setDataId2D:[anotherObj dataId2D]];
    [self setDataIdWaveform:[anotherObj dataIdWaveform]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORDataGenDecoderForTestData1D",       @"decoder",
        [NSNumber numberWithLong:dataId1D],     @"dataId",
        [NSNumber numberWithBool:NO],           @"variable",
        [NSNumber numberWithLong:2],            @"length",
        [NSNumber numberWithBool:YES],          @"canBeGated",

        nil];
    [dataDictionary setObject:aDictionary forKey:@"TestData1D"];
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORDataGenDecoderForTestData2D",       @"decoder",
        [NSNumber numberWithLong:dataId2D],     @"dataId",
        [NSNumber numberWithBool:NO],           @"variable",
        [NSNumber numberWithLong:3],            @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"TestData2D"];
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORDataGenDecoderForTestDataWaveform",		@"decoder",
        [NSNumber numberWithLong:dataIdWaveform],   @"dataId",
        [NSNumber numberWithBool:NO],				@"variable",
        [NSNumber numberWithLong:2048+2],			@"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"TestDataWaveform"];
    return dataDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORDataGenModel"];  
	first = YES;  
}

//----------------------------------------------------------------------------
// Function:	TakeData
// Description: Read data from a card
//----------------------------------------------------------------------------

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
     if(random()%500 > 480 ){
        
        short card = random()%2;
        short chan = random()%8;
        unsigned long aValue = (100*chan) + ((random()%500 + random()%500 + random()%500+ random()%500)/4);
        if(card==0 && chan ==0)aValue = 100;
        unsigned long data[3];
        data[0] = dataId1D | 2;
        data[1] = (card<<16) | (chan << 12) | (aValue & 0x0fff);
        [aDataPacket addLongsToFrameBuffer:data length:2];

        data[0] = dataId2D | 3;
        aValue = 64 + ((random()%128 + random()%128 + random()%128)/3);
        data[1] = (aValue & 0x0fff); //card 0, chan 0
        aValue = 64 + ((random()%64 + random()%64 + random()%64)/3);
        data[2] = (aValue & 0x0fff);
        [aDataPacket addLongsToFrameBuffer:data length:3];
    }
	if(random()%500 > 495 ){
		 
		unsigned long data[2048];
        data[0] = dataIdWaveform | 2048+2;
        data[1] = 0; //card 0, chan 0
        [aDataPacket addLongsToFrameBuffer:data length:2];
		int i;
		float radians = 0;
		float delta = 2*3.141592/360.;
		 short a = random()%20;
		 short b = random()%20;
		for(i=0;i<2048;i++){
			data[i] = (long)(a*sinf(radians) + b*sinf(2*radians));
			radians += delta;
		}
        [aDataPacket addLongsToFrameBuffer:data length:2048];

        data[0] = dataIdWaveform | 2048+2;
        data[1] = 0x00001000; //card 0, chan 1
        [aDataPacket addLongsToFrameBuffer:data length:2];
		radians = 0;
		delta = 2*3.141592/360.;
		for(i=0;i<2048;i++){
			data[i] = (long)(a*sinf(4*radians));
			radians += delta;
		}
        [aDataPacket addLongsToFrameBuffer:data length:2048];

	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo  {}
- (void)reset  {}


- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id = kDataGen; 
	configStruct->card_info[index].hw_mask[0] = dataId1D; 
	configStruct->card_info[index].hw_mask[1] = dataId2D; 
	configStruct->card_info[index].hw_mask[2] = dataIdWaveform; 
	configStruct->card_info[index].num_Trigger_Indexes = 0;	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	return index+1;
}


#pragma mark ¥¥¥Bit Processing Protocol
- (void)processIsStarting
{
	adcValue = 0;
	theta = 0;
}

- (void)processIsStopping
{
}

//note that everything called by these routines MUST be threadsafe
- (void) startProcessCycle
{
	adcValue = 10.0*sinf(0.017453 * theta);
	theta = (theta+1)%360;
}

- (void) endProcessCycle
{
}

- (int) processValue:(int)channel
{
	return 0;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
    //nothing to do
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"Test Data %d",[self uniqueIdNumber]];
}

- (NSString*) processingTitle
{
    return @"Data Gen";
}

- (double) convertedValue:(int)channel
{
	return adcValue;
}

- (double) maxValueForChan:(int)channel
{
	return 10.0;
}
- (double) minValueForChan:(int)channel
{
	return -10.0;
}
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		*theLowLimit = -5.0;
		*theHighLimit = +5.0;
	}		
}

@end


