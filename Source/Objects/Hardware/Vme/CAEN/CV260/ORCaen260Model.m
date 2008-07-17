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
	{@"Version",			0,0,0, 0xFE, kReadOnly,	kD16}, 
	{@"Modual Type",		0,0,0, 0xFC, kReadOnly,	kD16},
	{@"Fixed Code",			0,0,0, 0xFA, kReadOnly,	kD16}, 
	{@"Interrupt Jumpers",	0,0,0, 0x58, kReadOnly,	kD16},
	{@"Scaler Increase",	0,0,0, 0x56, kReadWrite,kD16},
	{@"Inhibite Reset",		0,0,0, 0x54, kReadWrite,kD16},
	{@"Inhibite Set",		0,0,0, 0x52, kReadWrite,kD16},
	{@"Clear",				0,0,0, 0x50, kReadWrite,kD16},
	{@"Counter 0",			0,0,0, 0x10, kReadOnly,	kD32},
	{@"Counter 1",			0,0,0, 0x14, kReadOnly,	kD32},
	{@"Counter 2",			0,0,0, 0x18, kReadOnly,	kD32},
	{@"Counter 3",			0,0,0, 0x1C, kReadOnly,	kD32},
	{@"Counter 4",			0,0,0, 0x20, kReadOnly,	kD32},
	{@"Counter 5",			0,0,0, 0x24, kReadOnly,	kD32},
	{@"Counter 6",			0,0,0, 0x28, kReadOnly,	kD32},
	{@"Counter 7",			0,0,0, 0x2C, kReadOnly,	kD32},
	{@"Counter 8",			0,0,0, 0x30, kReadOnly,	kD32},
	{@"Counter 9",			0,0,0, 0x34, kReadOnly,	kD32},
	{@"Counter 10",			0,0,0, 0x38, kReadOnly,	kD32},
	{@"Counter 11",			0,0,0, 0x3C, kReadOnly,	kD32},
	{@"Counter 12",			0,0,0, 0x40, kReadOnly,	kD32},
	{@"Counter 13",			0,0,0, 0x44, kReadOnly,	kD32},
	{@"Counter 14",			0,0,0, 0x48, kReadOnly,	kD32},
	{@"Counter 15",			0,0,0, 0x4C, kReadOnly,	kD32},
	{@"Clear VME Interrupt",0,0,0, 0x0C, kReadWrite,		kD16},
	{@"Disable VME Interrupt",	0,0,0, 0xA, kReadWrite,		kD16},
	{@"Enable VME Interrupt",	0,0,0, 0x08, kReadWrite,	kD16},
	{@"Interrupt Level",		0,0,0, 0x06, kWriteOnly,	kD16},
	{@"Interrupt Vector",		0,0,0, 0x04, kWriteOnly,	kD16},
};



#pragma mark •••Notification Strings
NSString* ORCaen260ModelEnabledMaskChanged	 = @"ORCaen260ModelEnabledMaskChanged";
NSString* ORCaen260ModelScalerValueChanged	 = @"ORCaen260ModelScalerValueChanged";
NSString* ORCaen260ModelPollingStateChanged	 = @"ORCaen260ModelPollingStateChanged";
NSString* ORCaen260ModelShipRecordsChanged	 = @"ORCaen260ModelShipRecordsChanged";

@interface ORCaen260Model (private)
- (void) _setUpPolling:(BOOL)verbose;
- (void) _stopPolling;
- (void) _startPolling;
- (void) _pollAllChannels;
- (void) _shipValues;
@end

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
	[self _stopPolling];
    [super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
        [self _setUpPolling:NO];
    }
    [super wakeUp];
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
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
- (NSString*)	  thresholdLockName					{ return @"ORCaen270ThresholdLock"; }

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 260 (Slot %d) ",[self slot]];
}

- (unsigned long) scalerValue:(int)index
{
	if(index<0)return 0;
	else if(index>kNumCaen260Channels)return 0;
	else return scalerValue[index];
}

- (void) setPollingState:(NSTimeInterval)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollingState:pollingState];
    
    pollingState = aState;
    
    [self performSelector:@selector(_startPolling) withObject:nil afterDelay:0.5];
    
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORCaen260ModelPollingStateChanged
                      object: self];
    
}

- (void) setScalerValue:(unsigned long)aValue index:(int)index
{
	if(index<0)return;
	else if(index>kNumCaen260Channels)return;
	scalerValue[index] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCaen260ModelScalerValueChanged 
		object:self
		userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:@"Channel"]];

}
- (BOOL) shipRecords
{
    return shipRecords;
}

- (void) setShipRecords:(BOOL)aShipRecords
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipRecords:shipRecords];
    
    shipRecords = aShipRecords;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen260ModelShipRecordsChanged object:self];
}

- (NSTimeInterval)	pollingState
{
    return pollingState;
}

- (void) _pollAllChannels
{
    NS_DURING 
        [self readScalers]; 
    NS_HANDLER 
		NSLogError(@"CV260",@"Polling Error",nil);
	NS_ENDHANDLER
	
	if(shipRecords){
		[self _shipValues]; 
	}
        
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
	if(pollingState!=0){
		[self performSelector:@selector(_pollAllChannels) withObject:nil afterDelay:pollingState];
	}
}

- (void) _shipValues
{
   BOOL runInProgress = [gOrcaGlobals runInProgress];

	if(runInProgress){
		unsigned long data[19];
		
		data[0] = dataId | 19;
		data[1] = (([self crateNumber]&0x01e)<<21) | ([self slot]& 0x0000001f)<<16  | (enabledMask & 0x0000ffff);
		data[2] = lastReadTime;	//seconds since 1970

		int index = 3;
		int i;
		for(i=0;i<kNumCaen260Channels;i++){
			data[index++] = scalerValue[i];
		}
		
		if(index>3){
			//the full record goes into the data stream via a notification
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
														object:[NSData dataWithBytes:data length:index*sizeof(long)]];
		}
	}

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
    dataId = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCaen260
{
    [self setDataId:[anotherCaen260 dataId]];
}
- (void) _stopPolling
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
	pollRunning = NO;
}

- (void) _startPolling
{
	[self _setUpPolling:YES];
}

- (void) _setUpPolling:(BOOL)verbose
{
    if(pollingState!=0){  
		pollRunning = YES;
        if(verbose)NSLog(@"Polling Caen260,%d,%d  every %.0f seconds.\n",[self crateNumber],[self slot],pollingState);
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
        [self performSelector:@selector(_pollAllChannels) withObject:self afterDelay:pollingState];
        [self _pollAllChannels];
    }
    else {
		pollRunning = NO;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
        if(verbose)NSLog(@"Not Polling Caen260,%d,%d\n",[self crateNumber],[self slot]);
    }
}

#pragma mark •••Hardware Access
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

- (void) setInhibit
{
	unsigned short aValue = 0;
    [[self adapter] writeWordBlock:&aValue
						atAddress:[self baseAddress]+[self getAddressOffset:kInhibitSet]
						numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
}

- (void) resetInhibit
{
	unsigned short aValue = 0;
    [[self adapter] writeWordBlock:&aValue
						atAddress:[self baseAddress]+[self getAddressOffset:kInhibitReset]
						numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
}

- (void) clearScalers
{
	unsigned short aValue = 0;
    [[self adapter] writeWordBlock:&aValue
						atAddress:[self baseAddress]+[self getAddressOffset:kClear]
						numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
					
}

- (void) readScalers
{
	int i;
	//get the time(UT!)
	time_t	theTime;
	time(&theTime);
	struct tm* theTimeGMTAsStruct = gmtime(&theTime);
	lastReadTime = mktime(theTimeGMTAsStruct);
	for(i=0;i<kNumCaen260Channels;i++){
		if(enabledMask & (0x1<<i)){
			unsigned long aValue = 0;
			[[self adapter] readLongBlock:&aValue
							atAddress:[self baseAddress]+[self getAddressOffset:kCounter0] + (i*0x04)
							numToRead:1
						withAddMod:[self addressModifier]
						usingAddSpace:0x01];
			[self setScalerValue:aValue index:i];
		}
		else [self setScalerValue:0 index:i];

	}
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORCaen260DecoderForScaler",		@"decoder",
        [NSNumber numberWithLong:dataId],	@"dataId",
        [NSNumber numberWithBool:NO],		@"variable",
        [NSNumber numberWithLong:19],		@"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Caen260"];
    
    return dataDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:NSStringFromClass([self class])]; 
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	[self setPollingState:[decoder decodeIntForKey:@"pollingState"]];
	
    [[self undoManager] enableUndoRegistration];
    
    [self setAddressModifier:0x39];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:[self pollingState] forKey:@"pollingState"];
	
}


- (BOOL) partOfEvent:(unsigned short)aChannel
{
	//included to satisfy the protocal... change if needed
	return NO;
}
@end
