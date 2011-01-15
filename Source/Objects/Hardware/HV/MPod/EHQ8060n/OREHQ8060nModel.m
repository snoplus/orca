//
//  OREHQ8060nModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "OREHQ8060nModel.h"
#import "ORDataTypeAssigner.h"
#import "TimedWorker.h"
#import "ORMPodProtocol.h"

NSString* OREHQ8060nSettingsLock				= @"OREHQ8060nSettingsLock";
NSString* OREHQ8060nModelTargetChanged			= @"OREHQ8060nModelTargetChanged";
NSString* OREHQ8060nModelVoltageChanged			= @"OREHQ8060nModelVoltageChanged";
NSString* OREHQ8060nModelCurrentChanged			= @"OREHQ8060nModelCurrentChanged";
NSString* OREHQ8060nModelOutputSwitchChanged	= @"OREHQ8060nModelOutputSwitchChanged";
NSString* OREHQ8060nModelOnlineMaskChanged		= @"OREHQ8060nModelOnlineMaskChanged";
NSString* OREHQ8060nModelRiseRateChanged		= @"OREHQ8060nModelRiseRateChanged";
NSString* OREHQ8060nModelChannelReadParamsChanged		= @"OREHQ8060nModelChannelReadParamsChanged";

@implementation OREHQ8060nModel

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [self makePoller:0];
    return self;
}

- (void) dealloc 
{
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		[rwParams[i] release];
	}
    [poller stop];
    [poller release];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
	[poller runWithTarget:self selector:@selector(updateAllValues)];
}

- (void) sleep
{
    [super sleep];
    [poller stop];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"EHQ8060n"]];	
}

- (void) makeMainController
{
    [self linkToController:@"OREHQ8060nController"];
}

#pragma mark ***Accessors
- (int) channel:(int)i readParamAsInt:(NSString*)name
{
	if(i>=0 && i<kNumEHQ8060nChannels) {
		return [[[rwParams[i] objectForKey:name] objectForKey:@"Value"] intValue];
	}
	else return 0;
}

- (float) channel:(int)i readParamAsFloat:(NSString*)name
{
	if(i>=0 && i<kNumEHQ8060nChannels) {
		return [[[rwParams[i] objectForKey:name] objectForKey:@"Value"] floatValue];
	}
	else return 0;
}

- (id) channel:(int)i readParamAsObject:(NSString*)name
{
	if(i>=0 && i<kNumEHQ8060nChannels) {
		return [[rwParams[i] objectForKey:name] objectForKey:@"Value"];
	}
	else return 0;
}

- (TimedWorker *) poller
{
    return poller; 
}

- (void) setPoller: (TimedWorker *) aPoller
{
    if(aPoller == nil){
        [poller stop];
    }
    [aPoller retain];
    [poller release];
    poller = aPoller;
}

- (void) setPollingInterval:(float)anInterval
{
    if(!poller){
        [self makePoller:(float)anInterval];
    }
    else [poller setTimeInterval:anInterval];
    
	[poller stop];
    [poller runWithTarget:self selector:@selector(updateAllValues)];
}

- (NSArray*) channelUpdateList
{
	NSArray* channelReadParams = [NSArray arrayWithObjects:
		@"outputStatus",
		@"outputMeasurementSenseVoltage",	
		@"outputMeasurementCurrent",	
		@"outputMeasurementTemperature",	
		@"outputSwitch",
		@"outputVoltage",
		@"outputCurrent",
		@"outputSupervisionBehavior",
		@"outputSupervisionMinSenseVoltage",
		@"outputSupervisionMaxSenseVoltage",
		@"outputSupervisionMaxTerminalVoltage",	
		@"outputSupervisionMaxCurrent",
		@"outputSupervisionMaxTemperature",	
		@"outputConfigMaxSenseVoltage",
		@"outputConfigMaxTerminalVoltage",	
		@"outputConfigMaxCurrent",
		@"outputConfigMaxPower",
		nil];
	NSArray* cmds = [self addChannelNumbersToParams:channelReadParams];
	return cmds;
}

- (NSArray*) commonChannelUpdateList
{
	NSArray* channelReadParams = [NSArray arrayWithObjects:
								  @"outputVoltageRiseRate",
								  nil];
	NSArray* cmds = [self addChannel:0 toParams:channelReadParams];
	return cmds;
}


- (void) syncDialog
{
	NSArray* syncParams = [NSArray arrayWithObjects:
						   @"outputVoltage",
						   nil];

	syncParams = [self addChannelNumbersToParams:syncParams];
	syncParams = [syncParams arrayByAddingObjectsFromArray:[self commonChannelUpdateList]];
	
	[[self adapter] getValues:syncParams target:self selector:@selector(processSyncResponseArray:)];
}

- (NSArray*) addChannelNumbersToParams:(NSArray*)someChannelParams
{
	NSMutableArray* convertedArray = [NSMutableArray array];
	for(id aParam in someChannelParams){
		int i;
		for(i=0;i<8;i++){
			[convertedArray addObject:[aParam stringByAppendingFormat:@".u%d",([self slot]-1) * 100 + i]];
		}
	}
	return convertedArray;
}


- (NSArray*) addChannel:(int)i toParams:(NSArray*)someChannelParams
{
	NSMutableArray* convertedArray = [NSMutableArray array];
	for(id aParam in someChannelParams){
		[convertedArray addObject:[aParam stringByAppendingFormat:@".u%d",([self slot]-1) * 100 + i]];
	}
	return convertedArray;
}

- (void) updateAllValues
{
	[[self adapter] getValues: [self channelUpdateList]  target:self selector:@selector(processRWResponseArray:)];
	[self writeVoltage:0]; ///test  remove!!!!!
}

- (void) processRWResponseArray:(NSArray*)response
{
	for(id anEntry in response){
		//make sure the slot matches: if not then ignore this Entry
		int theSlot = [[anEntry objectForKey:@"Slot"] intValue];
		if(theSlot == [self slot]){
			if([anEntry objectForKey:@"Channel"]){
				int theChannel = [[anEntry objectForKey:@"Channel"] intValue];
				NSString* name = [anEntry objectForKey:@"Name"];
				if(theChannel>=0 && theChannel<kNumEHQ8060nChannels){
					if(!rwParams[theChannel])rwParams[theChannel] = [[NSMutableDictionary dictionary] retain];
					if(name)[rwParams[theChannel] setObject:anEntry forKey:name];
				}
			}
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelChannelReadParamsChanged object:self];
}

- (void) writeVoltage:(int)channel
{    
	[[self adapter] writeValue:@"outputVoltageRiseRate.u0 F 5.4" target:nil selector:@selector(processRWResponseArray:)];
}

- (void) processSyncResponseArray:(NSArray*)response
{
	for(id anEntry in response){
		int theChannel = [[anEntry objectForKey:@"Channel"] intValue];
		if(theChannel>=0 && theChannel<kNumEHQ8060nChannels){
			NSString* name = [anEntry objectForKey:@"Name"];
			if([name isEqualToString:@"outputVoltage"])				 [self setTarget:theChannel withValue:[[anEntry objectForKey:@"Value"] floatValue]];
			else if([name isEqualToString:@"outputVoltageRiseRate"]) [self setRiseRate:[[anEntry objectForKey:@"Value"] floatValue]];
		}
	}
}

- (void) makePoller:(float)anInterval
{
    [self setPoller:[TimedWorker TimeWorkerWithInterval:anInterval]];
}

- (float) riseRate{ return riseRate; }
- (void) setRiseRate:(float)aValue 
{ 
	if(aValue<0)aValue=0;
    [[[self undoManager] prepareWithInvocationTarget:self] setRiseRate:riseRate];
	riseRate = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelRiseRateChanged object:self];
}

- (int) target:(short)chan	{ return target[chan]; }
- (void) setTarget:(short)chan withValue:(int)aValue 
{ 
	if(aValue<0)aValue=0;
	else if(aValue>0xfFFF)aValue = 0xfFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setTarget:chan withValue:target[chan]];
	target[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelTargetChanged object:self];
}

- (int) voltage:(short)chan	{ return voltage[chan]; }
- (void) setVoltage:(short)chan withValue:(int)aValue 
{ 
	if(aValue<0)aValue=0;
	else if(aValue>0xfFFF)aValue = 0xfFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setVoltage:chan withValue:voltage[chan]];
	voltage[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelVoltageChanged object:self];
}

- (float) current:(short)chan	{ return current[chan]; }
- (void) setCurrent:(short)chan withValue:(float)aValue 
{ 
	if(aValue<0)aValue=0;
    [[[self undoManager] prepareWithInvocationTarget:self] setCurrent:chan withValue:current[chan]];
	current[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelCurrentChanged object:self];
}

- (unsigned char) onlineMask { return onlineMask; }
- (void) setOnlineMask:(unsigned char)anOnlineMask {
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:[self onlineMask]];
    onlineMask = anOnlineMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelOnlineMaskChanged object:self];
}

- (BOOL)onlineMaskBit:(int)bit { return onlineMask&(1<<bit); }
- (void) setOnlineMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned char aMask = onlineMask;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setOnlineMask:aMask];
}

#pragma mark •••Data Taker
- (unsigned long) dataId { return dataId; }

- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"OREHQ8060nDecoderForWaveform",          @"decoder",
								 [NSNumber numberWithLong:dataId],        @"dataId",
								 [NSNumber numberWithBool:YES],           @"variable",
								 [NSNumber numberWithLong:-1],			  @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Waveform"];
    
    return dataDictionary;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		[self setTarget:i withValue:[decoder decodeIntForKey:[@"target" stringByAppendingFormat:@"%d",i]]];
		[self setVoltage:i withValue:[decoder decodeIntForKey:[@"voltage" stringByAppendingFormat:@"%d",i]]];
		[self setCurrent:i withValue:[decoder decodeFloatForKey:[@"current" stringByAppendingFormat:@"%d",i]]];
	}
	
	[self setRiseRate:	 [decoder decodeFloatForKey:@"riseRate"]];
	[self setPoller:	 [decoder decodeObjectForKey:@"Poller"]];
	[self setOnlineMask: [decoder decodeIntForKey:@"onlineMask"]];
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	int i;
 	for(i=0;i<kNumEHQ8060nChannels;i++){
		[encoder encodeInt:target[i] forKey:[@"target" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:voltage[i] forKey:[@"voltage" stringByAppendingFormat:@"%d",i]];
		[encoder encodeFloat:current[i] forKey:[@"current" stringByAppendingFormat:@"%d",i]];
	}
	[encoder encodeFloat:riseRate forKey:@"riseRate"];
	[encoder encodeObject:poller  forKey:@"Poller"];
    [encoder encodeInt:onlineMask forKey:@"onlineMask"];

}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
	int i;
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[self addCurrentState:objDictionary cIntArray:voltage forKey:[@"target" stringByAppendingFormat:@"%d",i]];
	[self addCurrentState:objDictionary cIntArray:voltage forKey:[@"voltage" stringByAppendingFormat:@"%d",i]];
	[self addCurrentState:objDictionary cFloatArray:current forKey:[@"current" stringByAppendingFormat:@"%d",i]];
    [objDictionary setObject:[NSNumber numberWithFloat:riseRate] forKey:@"riseRate"];
    [objDictionary setObject:[NSNumber numberWithInt:onlineMask] forKey:@"onlineMask"];
	
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cIntArray:(short*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		[ar addObject:[NSNumber numberWithInt:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cBoolArray:(BOOL*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		[ar addObject:[NSNumber numberWithBool:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cFloatArray:(float*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		[ar addObject:[NSNumber numberWithFloat:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

@end
