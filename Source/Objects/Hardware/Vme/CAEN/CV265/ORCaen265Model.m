/*
 *  ORCaen265Model.cpp
 *  Orca
 *
 *  Created by Mark Howe on 12/7/07
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#pragma mark •••Imported Files
#import "ORCaen265Model.h"

#import "ORVmeCrateModel.h"
#import "ORDataTypeAssigner.h"
#include "VME_HW_Definitions.h"

#pragma mark •••Definitions
#define kDefaultAddressModifier			0x29
#define kDefaultBaseAddress				0x00008000

#pragma mark •••Static Declarations
//offsets from the base address (kDefaultBaseAddress)
static unsigned long register_offsets[kNumberOfV265Registers] = {
    0x00,		// [0]  kStatusControl
    0x02,		// [1]	kClear
    0x04,		// [2]  kDAC
    0x06,		// [3]  kGateGeneration
    0x08,		// [3]  kDataRegister
    0xFA,		// [4]  kFixedCode
    0xFC,		// [5]  kBoardID
    0xFE,		// [6]	kVersion
};

#pragma mark •••Notification Strings
NSString* ORCaen265SettingsLock			= @"ORCaen265SettingsLock";

@implementation ORCaen265Model

- (id) init //designated initializer
{
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];
		
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) dealloc
{    
    [super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"Caen265Card"]];	
}


- (void) makeMainController
{
    [self linkToController:@"ORCaen265Controller"];
}


#pragma mark •••Accessors
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}


#pragma mark •••Hardware Access
- (void) initBoard
{
	unsigned short aValue = 0; //anything value will do
    [[self adapter] writeWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kClear]
						numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
}


- (unsigned short) 	readBoardID
{
    unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kBoardID]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
    return aValue;
}

- (unsigned short) 	readBoardVersion
{
    unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kVersion]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
    return aValue;
}

- (unsigned short) 	readFixedCode
{
    unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kFixedCode]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
    return aValue;
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORCaen265DecoderForAdc",							@"decoder",
        [NSNumber numberWithLong:dataId],					@"dataId",
        [NSNumber numberWithBool:NO],						@"variable",
        [NSNumber numberWithLong:IsShortForm(dataId)?1:2],	@"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Caen265"];
    
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							@"Adc",								@"name",
							[NSNumber numberWithLong:dataId],   @"dataId",
							[NSNumber numberWithLong:8],		@"maxChannels",
								nil];
		
	[anEventDictionary setObject:aDictionary forKey:@"Caen265"];
}


- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	
    if(![[self adapter] controllerCard]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORCaen265Model"];    
    
    //----------------------------------------------------------------------------------------
    controller = [self adapter]; //cache the controller for alittle bit more speed.
	statusAddress = [self baseAddress]+register_offsets[kStatusControl];
	fifoAddress   = [self baseAddress]+register_offsets[kDataRegister];
	location      =  (([self crateNumber]&0xf)<<21) | (([self slot]& 0x0000001f)<<16); //doesn't change so do it here.

    [self clearExceptionCount];
	
	[self initBoard];
	isRunning = NO;

}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	isRunning = YES;
    NS_DURING
		unsigned short statusValue = 0;
		[controller readWordBlock:&statusValue
						atAddress:statusAddress
						numToRead:1
					   withAddMod:0x29
					usingAddSpace:0x01];
		if(statusValue & 0x8000){
			//FIFO is ready  ???do we have to continually poll the status reg for each value, or is the following OK????
			int i;
			unsigned long dataBuffer[18];
			for(i=0;i<16;i++){
				[controller readWordBlock:(unsigned short*)(&dataBuffer[i+2])
								atAddress:fifoAddress
								numToRead:1
							   withAddMod:0x29
							usingAddSpace:0x01];
			}
			dataBuffer[0] = dataId | 18;
			dataBuffer[1] = location;
			[aDataPacket addLongsToFrameBuffer:dataBuffer length:18];
		}
		
	NS_HANDLER
		NSLogError(@"",@"Caen265 Card Error",nil);
		[self incExceptionCount];
		[localException raise];
	NS_ENDHANDLER
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	isRunning = NO;
}


- (void) reset
{
	[self initBoard]; 
    
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
/*	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id = kCaen265; //should be unique
	configStruct->card_info[index].hw_mask[0] 	 = dataId; //better be unique
	configStruct->card_info[index].slot 	 = [self slot];
	configStruct->card_info[index].crate 	 = [self crateNumber];
	configStruct->card_info[index].add_mod 	 = [self addressModifier];
	configStruct->card_info[index].base_add  = [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0] = onlineMask;
	configStruct->card_info[index].deviceSpecificData[1] = register_offsets[kConversionStatusRegister];
	configStruct->card_info[index].deviceSpecificData[2] = register_offsets[kADC1OutputRegister];
	configStruct->card_info[index].num_Trigger_Indexes = 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
*/	
	return index+1;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
}

/*- (NSMutableDictionary*) captureCurrentState:(NSMutableDictionary*)dictionary
{
    
    NSMutableDictionary* objDictionary = [super captureCurrentState:dictionary];
    [objDictionary setObject:thresholds forKey:@"thresholds"];
        
	return objDictionary;
}
*/

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kShortForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCaen265
{
    [self setDataId:[anotherCaen265 dataId]];
}

- (BOOL) partOfEvent:(unsigned short)aChannel
{
	//included to satisfy the protocal... change if needed
	return NO;
}
@end
