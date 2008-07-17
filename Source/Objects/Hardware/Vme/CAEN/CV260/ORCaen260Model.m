/*
 *  ORCaen260Model.cpp
 *  Orca
 *
 *  Created by Mark Howe on 12/7/07
 *  Copyright (c) 2002 CENPA,University of Washington. All rights reserved.
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
//University of Washington,or U.S. Government make any warranty,
//express or implied,or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark •••Imported Files
#import "ORCaen260Model.h"

#import "ORVmeCrateModel.h"
#import "ORDataTypeAssigner.h"
#include "VME_HW_Definitions.h"

#pragma mark •••Static Declarations
static RegisterNamesStruct reg[kNumberOfV260Registers] = {
	{@"Version",			0,0,0, 0xFE, kReadOnly,0}, 
	{@"Modual Type",		0,0,0, 0xFC, kReadOnly,0},
	{@"Fixed Code",			0,0,0, 0xFA, kReadOnly,0}, 
	{@"Interrupt Jumpers",	0,0,0, 0x58, kReadOnly,0},
	{@"Scaler Increase",	0,0,0, 0x56, kReadWrite,0},
	{@"Inhibite Reset",		0,0,0, 0x54, kReadWrite,0},
	{@"Inhibite Set",		0,0,0, 0x52, kReadWrite,0},
	{@"Clear",				0,0,0, 0x50, kReadWrite,0},
	{@"Counter 0",			0,0,0, 0x10, kReadOnly,0},
	{@"Counter 1",			0,0,0, 0x14, kReadOnly,0},
	{@"Counter 2",			0,0,0, 0x18, kReadOnly,0},
	{@"Counter 3",			0,0,0, 0x1C, kReadOnly,0},
	{@"Counter 4",			0,0,0, 0x20, kReadOnly,0},
	{@"Counter 5",			0,0,0, 0x24, kReadOnly,0},
	{@"Counter 6",			0,0,0, 0x2C, kReadOnly,0},
	{@"Counter 7",			0,0,0, 0x30, kReadOnly,0},
	{@"Counter 8",			0,0,0, 0x32, kReadOnly,0},
	{@"Counter 9",			0,0,0, 0x34, kReadOnly,0},
	{@"Counter 10",			0,0,0, 0x3C, kReadOnly,0},
	{@"Counter 11",			0,0,0, 0x40, kReadOnly,0},
	{@"Counter 12",			0,0,0, 0x42, kReadOnly,0},
	{@"Counter 13",			0,0,0, 0x44, kReadOnly,0},
	{@"Counter 14",			0,0,0, 0x48, kReadOnly,0},
	{@"Counter 15",			0,0,0, 0x4C, kReadOnly,0},
	{@"Clear VME Interrupt",0,0,0, 0x0C, kReadWrite,0},
	{@"Disable VME Interrupt",	0,0,0, 0xA, kReadWrite,0},
	{@"Enable VME Interrupt",	0,0,0, 0x08, kReadWrite,0},
	{@"Interrupt Level",		0,0,0, 0x06, kWriteOnly,0},
	{@"Interrupt Vector",		0,0,0, 0x04, kReadOnly,0},
};



#pragma mark •••Notification Strings
NSString* ORCaen260ModelSuppressZerosChanged = @"ORCaen260ModelSuppressZerosChanged";
NSString* ORCaen260ModelEnabledMaskChanged	 = @"ORCaen260ModelEnabledMaskChanged";
NSString* ORCaen260SettingsLock				 = @"ORCaen260SettingsLock";

@implementation ORCaen260Model

- (id) init //designated initializer
{
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];
		
    [[self undoManager] enableUndoRegistration];
    
    [self setAddressModifier:0x39];
	
    return self;
}

- (void) dealloc
{    
    [super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"CV260Card"]];	
}


- (void) makeMainController
{
    [self linkToController:@"ORCaen260Controller"];
}


#pragma mark •••Accessors
#pragma mark ***Register - General routines
- (short)          getNumberRegisters	{ return kNumberOfV260Registers; }

#pragma mark ***Register - Register specific routines
- (NSString*)     getRegisterName:(short) anIndex	{ return reg[anIndex].regName; }
- (unsigned long) getAddressOffset:(short) anIndex	{ return(reg[anIndex].addressOffset); }
- (short)		  getAccessType:(short) anIndex		{ return reg[anIndex].accessType; }
- (short)         getAccessSize:(short) anIndex		{ return reg[anIndex].size; }
- (BOOL)          dataReset:(short) anIndex			{ return reg[anIndex].dataReset; }
- (BOOL)          swReset:(short) anIndex			{ return reg[anIndex].softwareReset; }
- (BOOL)          hwReset:(short) anIndex			{ return reg[anIndex].hwReset; }
- (NSString*)	  basicLockName						{ return @"ORCaen270BasicLock"; }

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 260 (Slot %d) ",[self slot]];
}

- (BOOL) suppressZeros
{
    return suppressZeros;
}

- (void) setSuppressZeros:(BOOL)aSuppressZeros
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSuppressZeros:suppressZeros];
    
    suppressZeros = aSuppressZeros;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen260ModelSuppressZerosChanged object:self];
}

- (unsigned short) enabledMask
{
    return enabledMask;
}

- (void) setEnabledMask:(unsigned short)aEnabledMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabledMask:enabledMask];
    
    enabledMask = aEnabledMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen260ModelEnabledMaskChanged object:self];
}

- (unsigned long) dataId { return dataId; }

- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (void) setDataIds:(id)assigner
{
    dataId = [assigner assignDataIds:kShortForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCaen260
{
    [self setDataId:[anotherCaen260 dataId]];
}

#pragma mark •••Hardware Access
- (void) initBoard
{
	unsigned short aValue = 0; //anything value will do
    [[self adapter] writeWordBlock:&aValue
						atAddress:[self baseAddress]+[self getAddressOffset:kClear]
						numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
}


- (unsigned short) 	readBoardID
{
    unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+[self getAddressOffset:kVersion]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
    return aValue;
}

- (unsigned short) 	readBoardVersion
{
    unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+[self getAddressOffset:kVersion]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
    return aValue;
}

- (unsigned short) 	readFixedCode
{
    unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+[self getAddressOffset:kFixedCode]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
    return aValue;
}

- (void) trigger
{
//	unsigned short aValue = 0;
//    [[self adapter] writeWordBlock:&aValue
//						atAddress:[self baseAddress]+[self getAddressOffset:kGateGeneration]
//						numToWrite:1
//					   withAddMod:[self addressModifier]
//					usingAddSpace:0x01];
}


- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORCaen260DecoderForAdc",			@"decoder",
        [NSNumber numberWithLong:dataId],	@"dataId",
        [NSNumber numberWithBool:NO],		@"variable",
        [NSNumber numberWithLong:IsShortForm(dataId)?1:3],@"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Caen260"];
    
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							@"Adc",				@"name",
							[NSNumber numberWithLong:dataId],@"dataId",
							[NSNumber numberWithLong:8],@"maxChannels",
								nil];
		
	[anEventDictionary setObject:aDictionary forKey:@"Caen260"];
}


- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	
    if(![[self adapter] controllerCard]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORCaen260Model"];    
    
    //----------------------------------------------------------------------------------------
    controller = [self adapter]; //cache the controller for alittle bit more speed.
//	statusAddress = [self baseAddress]+register_offsets[kStatusControl];
//	fifoAddress   = [self baseAddress]+register_offsets[kDataRegister];
	location      =  (([self crateNumber]&0xf)<<21) | (([self slot]& 0x0000001f)<<16); //doesn't change so do it here.
	usingShortForm = IsShortForm(dataId);
    //usingShortForm = dataId & 0x80000000;
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
					   withAddMod:[ self addressModifier]
					usingAddSpace:0x01];
					
		if(statusValue & 0x8000){
			unsigned short dataValue;
			[controller readWordBlock:&dataValue
								atAddress:fifoAddress
								numToRead:1
							   withAddMod:[self addressModifier]
							usingAddSpace:0x01];
			short chan = (dataValue >> 13) & 0x7;
			if(enabledMask & (1L<<chan)){
				if(!(suppressZeros && (dataValue & 0xfff)==0)){
					if(usingShortForm){
						unsigned long dataWord = dataId | location | (dataValue & 0x7fff);
						[aDataPacket addLongsToFrameBuffer:&dataWord length:1];
					}
					else {
						//unlikely we have been assigned the long form,but just in case....
						unsigned long dataRecord[2];
						dataRecord[0] = dataId | 2;
						dataRecord[1] = location | dataValue & 0x7fff;
						[aDataPacket addLongsToFrameBuffer:dataRecord length:2];
					}
				}
			}
		}
		
	NS_HANDLER
		NSLogError(@"",@"Caen260 Card Error",nil);
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
	configStruct->card_info[index].hw_type_id = kCaen260; //should be unique
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
    
    [self setAddressModifier:0x39];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
}

/*- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [encoder encodeBool:suppressZeros forKey:@"ORCaen260ModelSuppressZeros"];
    [encoder encodeInt:enabledMask forKey:@"ORCaen260ModelEnabledMask"];
    [objDictionary setObject:thresholds forKey:@"thresholds"];
        
	return objDictionary;
}
*/


- (BOOL) partOfEvent:(unsigned short)aChannel
{
	//included to satisfy the protocal... change if needed
	return NO;
}
@end
