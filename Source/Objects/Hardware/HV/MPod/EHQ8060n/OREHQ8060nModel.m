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
#import "ORTimeRate.h"

NSString* OREHQ8060nModelShipRecordsChanged		= @"OREHQ8060nModelShipRecordsChanged";
NSString* OREHQ8060nModelMaxCurrentChanged		= @"OREHQ8060nModelMaxCurrentChanged";
NSString* OREHQ8060nModelSelectedChannelChanged = @"OREHQ8060nModelSelectedChannelChanged";
NSString* OREHQ8060nSettingsLock				= @"OREHQ8060nSettingsLock";
NSString* OREHQ8060nModelHwGoalChanged			= @"OREHQ8060nModelHwGoalChanged";
NSString* OREHQ8060nModelTargetChanged			= @"OREHQ8060nModelTargetChanged";
NSString* OREHQ8060nModelCurrentChanged			= @"OREHQ8060nModelCurrentChanged";
NSString* OREHQ8060nModelOutputSwitchChanged	= @"OREHQ8060nModelOutputSwitchChanged";
NSString* OREHQ8060nModelRiseRateChanged		= @"OREHQ8060nModelRiseRateChanged";
NSString* OREHQ8060nModelChannelReadParamsChanged = @"OREHQ8060nModelChannelReadParamsChanged";

@implementation OREHQ8060nModel

#define kMaxVoltage 6000
#define kMaxCurrent 1000 

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    return self;
}

- (void) dealloc 
{
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		[voltageHistory[i] release];
		[currentHistory[i] release];
	}
     [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
}

- (void) sleep
{
    [super sleep];
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

- (BOOL) shipRecords
{
    return shipRecords;
}

- (void) setShipRecords:(BOOL)aShipRecords
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipRecords:shipRecords];
    shipRecords = aShipRecords;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelShipRecordsChanged object:self];
}

- (int) selectedChannel
{
    return selectedChannel;
}

- (void) setSelectedChannel:(int)aSelectedChannel
{
    selectedChannel = aSelectedChannel;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelSelectedChannelChanged object:self];
}

- (int) channel:(int)i readParamAsInt:(NSString*)name
{
	if(i>=0 && i<kNumEHQ8060nChannels) {
		return [[[rdParams[i] objectForKey:name] objectForKey:@"Value"] intValue];
	}
	else return 0;
}

- (float) channel:(int)i readParamAsFloat:(NSString*)name
{
	if(i>=0 && i<kNumEHQ8060nChannels) {
		return [[[rdParams[i] objectForKey:name] objectForKey:@"Value"] floatValue];
	}
	else return 0;
}

- (id) channel:(int)i readParamAsValue:(NSString*)name
{
	if(i>=0 && i<kNumEHQ8060nChannels) {
		return [[rdParams[i] objectForKey:name] objectForKey:@"Value"];
	}
	else return nil;
}

- (id) channel:(int)i readParamAsObject:(NSString*)name
{
	if(i>=0 && i<kNumEHQ8060nChannels) {
		return [rdParams[i] objectForKey:name];
	}
	else return @"";
}


- (NSArray*) channelUpdateList
{
	NSArray* channelReadParams = [NSArray arrayWithObjects:
		@"outputStatus",
		@"outputMeasurementSenseVoltage",	
		@"outputMeasurementCurrent",	
		@"outputSwitch",
		@"outputVoltage",
		@"outputCurrent",
		nil];
	NSArray* cmds = [self addChannelNumbersToParams:channelReadParams];
	return cmds;
}

- (NSArray*) commonChannelUpdateList
{
	NSArray* channelReadParams = [NSArray arrayWithObjects:
								  @"outputVoltageRiseRate",
								  @"outputMeasurementTemperature",	
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
	NSArray* cmds = [self addChannel:0 toParams:channelReadParams];
	return cmds;
}


- (void) syncDialog
{
	NSArray* syncParams = [NSArray arrayWithObjects:
						   @"outputMeasurementSenseVoltage",
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
		for(i=0;i<kNumEHQ8060nChannels;i++){
			[convertedArray addObject:[aParam stringByAppendingFormat:@".u%d",[self slotChannelValue:i]]];
		}
	}
	return convertedArray;
}

- (int) slotChannelValue:(int)aChannel
{
	return ([self slot]-1) * 100 + aChannel;
}

- (NSArray*) addChannel:(int)i toParams:(NSArray*)someChannelParams
{
	NSMutableArray* convertedArray = [NSMutableArray array];
	for(id aParam in someChannelParams){
		[convertedArray addObject:[aParam stringByAppendingFormat:@".u%d",[self slotChannelValue:i]]];
	}
	return convertedArray;
}

- (void) updateAllValues
{
	[[self adapter] getValues: [self channelUpdateList]  target:self selector:@selector(processReadResponseArray:)];
	if(shipRecords) [self shipDataRecords];
}

- (void) processReadResponseArray:(NSArray*)response
{
	
	[super processReadResponseArray:response];
	
	for(id anEntry in response){
		NSString* anError = [anEntry objectForKey:@"Error"];
		if([anError length]){
		}
		else {
			//make sure the slot matches: if not then ignore this Entry
			int theSlot = [[anEntry objectForKey:@"Slot"] intValue];
			if(theSlot == [self slot]){
				if([anEntry objectForKey:@"Channel"]){
					int theChannel = [[anEntry objectForKey:@"Channel"] intValue];
					NSString* name = [anEntry objectForKey:@"Name"];
					if(theChannel>=0 && theChannel<kNumEHQ8060nChannels){
						if(!rdParams[theChannel])rdParams[theChannel] = [[NSMutableDictionary dictionary] retain];
						if(name)[rdParams[theChannel] setObject:anEntry forKey:name];
					}
				}
			}
		}
	}
	if([[self adapter] respondsToSelector:@selector(power)]){
		if(![[self adapter] power]){
			int i;
			for(i=0;i<	kNumEHQ8060nChannels;i++){
				[rdParams[i] removeAllObjects];
			}
		}
	}
	
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		if(voltageHistory[i] == nil) voltageHistory[i] = [[ORTimeRate alloc] init];
		if(currentHistory[i] == nil) currentHistory[i] = [[ORTimeRate alloc] init];
		[voltageHistory[i] addDataToTimeAverage:[self channel:i readParamAsFloat:@"outputMeasurementSenseVoltage"]];
		[currentHistory[i] addDataToTimeAverage:[self channel:i readParamAsFloat:@"outputMeasurementCurrent"]];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelChannelReadParamsChanged object:self];
	

}

- (void) processWriteResponseArray:(NSArray*)response
{
	[super processWriteResponseArray:response];
	for(id anEntry in response){
		NSString* anError = [anEntry objectForKey:@"Error"];
		if([anError length]){
		}
		else {
		}
	}
}

- (int) numberChannelsOn
{
	int count = 0;
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		int state = [self channel:i readParamAsInt:@"outputSwitch"];
		if(state == kEHQ8060nOutputOn)count++;
	}
	return count;
}
- (unsigned long) channelStateMask
{
	unsigned long mask = 0x0;
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		int state = [self channel:i readParamAsInt:@"outputSwitch"];
		mask |= (1L<<state);
	}
	return mask;
}

- (int) numberChannelsRamping
{
	int count = 0;
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		float voltage = [self channel:i readParamAsFloat:@"outputMeasurementSenseVoltage"];
		float voltDiff = fabs(voltage - hwGoal[i]);
		if(voltDiff > 5)count++;
	}
	return count;
}

- (int) numberChannelsWithNonZeroVoltage
{
	int count = 0;
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		float voltage	= [self channel:i readParamAsFloat:@"outputMeasurementSenseVoltage"];
		if(voltage > 0)count++;
	}
	return count;
}

- (int) numberChannelsWithNonZeroHwGoal
{
	int count = 0;
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		if(hwGoal[i] > 0)count++;
	}
	return count;
}

- (void)  commitTargetsToHwGoals
{
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		[self commitTargetToHwGoal:i];
	}
}

- (void) commitTargetToHwGoal:(int)channel
{
	if(channel>=0 && channel<kNumEHQ8060nChannels){
		hwGoal[channel] = target[channel];
		[[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelChannelReadParamsChanged object:self];
	}
}
- (void) loadValues:(int)channel
{
	if(channel>=0 && channel<kNumEHQ8060nChannels){
		[self commitTargetToHwGoal:selectedChannel];
		[self writeRiseTime];
		[self writeVoltage:channel];
		[self writeMaxCurrent:channel];
	}
}

- (void) writeRiseTime
{  
	[self writeRiseTime:riseRate];
}

- (void) writeRiseTime:(float)aValue
{    
	int channel = 0; //in this firmware version all the risetimes and falltimes get set to this value. So no need to send for all channels.
	NSString* cmd = [NSString stringWithFormat:@"outputVoltageRiseRate.u%d F %f",[self slotChannelValue:channel],aValue];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
}

- (void) writeVoltage:(int)channel
{    
	if(channel>=0 && channel<kNumEHQ8060nChannels){
		NSString* cmd = [NSString stringWithFormat:@"outputVoltage.u%d F %f",[self slotChannelValue:channel],(float)hwGoal[channel]];
		[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
	}
}

- (void) writeSupervisorBehaviour:(int)channel value:(int)aValue
{    
	if(channel>=0 && channel<kNumEHQ8060nChannels){
		NSString* cmd = [NSString stringWithFormat:@"outputSupervisionBehavior.u%d i %f",[self slotChannelValue:channel],aValue];
		[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
	}
}

- (void) writeMaxCurrent:(int)channel
{    
	if(channel>=0 && channel<kNumEHQ8060nChannels){
		NSString* cmd = [NSString stringWithFormat:@"outputCurrent.u%d F %f",[self slotChannelValue:channel],maxCurrent[channel]/1000.];
		[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
	}
}

- (void) turnChannelOn:(int)channel
{    
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kEHQ8060nOutputOn];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
}

- (void) turnChannelOff:(int)channel
{    
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kEHQ8060nOutputOff];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
}

- (void) panicChannel:(int)channel
{    
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kEHQ8060nOutputSetEmergencyOff];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
}

- (void) clearPanicChannel:(int)channel
{    
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kEHQ8060nOutputResetEmergencyOff];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
}

- (void) clearEventsChannel:(int)channel
{    
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kEHQ8060nOutputClearEvents];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
}

- (void) stopRamping:(int)channel
{
	if(channel>=0 && channel<kNumEHQ8060nChannels){
		//the only way to stop a ramp is to change the hwGoal to be the actual voltage
		float voltageNow = [self channel:channel readParamAsFloat:@"outputMeasurementSenseVoltage"];
		if(fabs(voltageNow-(float)hwGoal[channel])>5){
			[self setHwGoal:channel withValue:voltageNow];
			[self writeVoltage:channel];
		}
	}
}

- (void) rampToZero:(int)channel
{
	if(channel>=0 && channel<kNumEHQ8060nChannels){
		[self setHwGoal:channel withValue:0];
		[self writeVoltage:channel];
	}
}

- (void) panic:(int)channel
{
	if(channel>=0 && channel<kNumEHQ8060nChannels){
		[self setHwGoal:channel withValue:0];
		[self panicChannel:channel];
	}
}

- (BOOL) isOn:(int)aChannel
{
	if(aChannel>=0 && aChannel<8){
		int outputSwitch = [self channel:aChannel readParamAsInt:@"outputSwitch"];
		return outputSwitch==kEHQ8060nOutputOn;
	}
	else return NO;
}

- (void) turnAllChannelsOn
{
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++)[self turnChannelOn:i];
}

- (void) turnAllChannelsOff
{
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++)[self turnChannelOff:i];
}

- (void) panicAllChannels
{
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++)[self panic:i];
}

- (void) clearAllPanicChannels
{
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++)[self clearPanicChannel:i];
}

- (void) clearAllEventsChannels
{
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++)[self clearEventsChannel:i];	
}

- (void) stopAllRamping
{
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++)[self stopRamping:i];
}

- (void) rampAllToZero
{
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++)[self rampToZero:i];
}

- (void) panicAll
{
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++)[self panic:i];
}

- (unsigned long) failureEvents:(int)channel
{
	int events = [self channel:selectedChannel readParamAsInt:@"outputStatus"];
	events &= (outputFailureMinSenseVoltageMask    | outputFailureMaxSenseVoltageMask | 
			   outputFailureMaxTerminalVoltageMask | outputFailureMaxCurrentMask | 
			   outputFailureMaxTemperatureMask     | outputFailureMaxPowerMask |
			   outputFailureTimeoutMask            | outputCurrentLimitedMask |
			   outputEmergencyOffMask);
	return events;
}

- (unsigned long) failureEvents
{
	unsigned long failEvents = 0;
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		failEvents |= [self failureEvents:i];
	}
	return failEvents;
}

- (NSString*) channelState:(int)channel
{ 
	int outputSwitch = [self channel:channel readParamAsInt:@"outputSwitch"];
	int outputStatus = [self channel:channel readParamAsInt:@"outputStatus"];
	if(outputSwitch == kEHQ8060nOutputSetEmergencyOff)	return @"PANICKED";
	else {
		if(outputStatus & kEHQ8060nProblemMask)			return @"PROBLEM";
		else if(outputStatus & outputRampUpMask)		return @"RAMP UP";
		else if(outputStatus & outputRampDownMask)		return @"RAMP DN";
		else {
			switch(outputSwitch){
				case kEHQ8060nOutputOff:				return @"OFF";
				case kEHQ8060nOutputOn:					return @"ON";
				case kEHQ8060nOutputResetEmergencyOff:  return @"PANIC CLR";
				case kEHQ8060nOutputSetEmergencyOff:	return @"PANICKED";
				case kEHQ8060nOutputClearEvents:		return @"EVENT CLR";
				default: return @"?";
			}
		}
	}
}

- (void) processSyncResponseArray:(NSArray*)response
{
	[super processSyncResponseArray:response];
	for(id anEntry in response){
		int theChannel = [[anEntry objectForKey:@"Channel"] intValue];
		if(theChannel>=0 && theChannel<kNumEHQ8060nChannels){
			NSString* name = [anEntry objectForKey:@"Name"];
			if([name isEqualToString:@"outputMeasurementSenseVoltage"])	[self setTarget:theChannel withValue:[[anEntry objectForKey:@"Value"] intValue]];
		}
	}
}

- (float) riseRate{ return riseRate; }
- (void) setRiseRate:(float)aValue 
{ 
	if(aValue<2)aValue=2;
	else if(aValue>1200)aValue=1200; //20% of max
    [[[self undoManager] prepareWithInvocationTarget:self] setRiseRate:riseRate];
	riseRate = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelRiseRateChanged object:self];
}

- (int) hwGoal:(short)chan	{ return hwGoal[chan]; }
- (void) setHwGoal:(short)chan withValue:(int)aValue 
{ 
	if(aValue<0)aValue=0;
	else if(aValue>kMaxVoltage)aValue = kMaxVoltage;
	hwGoal[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelHwGoalChanged object:self];
}
- (float) maxCurrent:(short)chan { return maxCurrent[chan]; }

- (void) setMaxCurrent:(short)chan withValue:(float)aValue
{
 	if(aValue<1)aValue=1;
	else if(aValue>kMaxCurrent)aValue = kMaxCurrent;
	[[[self undoManager] prepareWithInvocationTarget:self] setMaxCurrent:chan withValue:maxCurrent[chan]];
    maxCurrent[chan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelMaxCurrentChanged object:self];
}

- (int) target:(short)chan	{ return target[chan]; }
- (void) setTarget:(short)chan withValue:(int)aValue 
{ 
	if(aValue<0)aValue=0;
	else if(aValue>kMaxVoltage)aValue = kMaxVoltage;
    [[[self undoManager] prepareWithInvocationTarget:self] setTarget:chan withValue:target[chan]];
	target[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:OREHQ8060nModelTargetChanged object:self];
}


#pragma mark •••Hardware Access
- (void) loadAllValues
{
	[self commitTargetsToHwGoals];
	[self writeRiseTime];
	[self writeVoltages];
	[self writeMaxCurrents];
}

- (void) writeVoltages
{
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		[self writeVoltage:i];
	}
}

- (void) writeMaxCurrents
{
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		[self writeMaxCurrent:i];
	}
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
								 @"OREHQ8060nDecoderForHV",          @"decoder",
								 [NSNumber numberWithLong:dataId],        @"dataId",
								 [NSNumber numberWithBool:NO],           @"variable",
								 [NSNumber numberWithLong:21],			  @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Waveform"];
    
    return dataDictionary;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
		
    [self setShipRecords:		[decoder decodeBoolForKey:@"shipRecords"]];
    [self setSelectedChannel:	[decoder decodeIntForKey:	@"selectedChannel"]];
	[self setRiseRate:			[decoder decodeFloatForKey:	@"riseRate"]];
	int i;
	for(i=0;i<kNumEHQ8060nChannels;i++){
		//[self setHwGoal:i withValue: [decoder decodeIntForKey:   [@"hwGoal" stringByAppendingFormat:@"%d",i]]];
		[self setTarget:i withValue: [decoder decodeIntForKey:   [@"target" stringByAppendingFormat:@"%d",i]]];
		[self setMaxCurrent:i withValue:[decoder decodeFloatForKey: [@"maxCurrent" stringByAppendingFormat:@"%d",i]]];
	}
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];

	[encoder encodeBool:shipRecords		forKey:@"shipRecords"];
	[encoder encodeInt:selectedChannel	forKey:@"selectedChannel"];
	[encoder encodeFloat:riseRate		forKey:@"riseRate"];
	int i;
 	for(i=0;i<kNumEHQ8060nChannels;i++){
		//[encoder encodeInt:hwGoal[i] forKey:[@"hwGoal" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:target[i] forKey:[@"target" stringByAppendingFormat:@"%d",i]];
		[encoder encodeFloat:maxCurrent[i] forKey:[@"maxCurrent" stringByAppendingFormat:@"%d",i]];
	}
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[self addCurrentState:objDictionary cIntArray:target forKey:@"target"];
	[self addCurrentState:objDictionary cFloatArray:maxCurrent forKey:@"maxCurrent"];
    [objDictionary setObject:[NSNumber numberWithFloat:riseRate] forKey:@"riseRate"];
	
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

#pragma mark •••Trends
- (ORTimeRate*) voltageHistory:(int)index
{
	return voltageHistory[index];
}

- (ORTimeRate*) currentHistory:(int)index
{
	return currentHistory[index];
}


- (void) shipDataRecords;
{
	if([[ORGlobal sharedGlobal] runInProgress]){
		//get the time(UT!)
		time_t	ut_Time;
		time(&ut_Time);
		
		int i;
		unsigned long data[21];
		data[0] = dataId | 21;
		data[1] = (([self crateNumber] & 0xf) << 20) | (([self slot]&0xf)<<16);
		data[2] = 0x0; //spare
		data[3] = 0x0; //spare
		data[4] = ut_Time;
		
		union {
			float asFloat;
			unsigned long asLong;
		}theData;
			
		for(i=0;i<kNumEHQ8060nChannels;i++){
			theData.asFloat = [self channel:i readParamAsFloat:@"outputMeasurementSenseVoltage"];
			data[5+i] = theData.asLong;
			
			theData.asFloat = [self channel:i readParamAsFloat:@"outputMeasurementCurrent"];
			data[6+i] = theData.asLong;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(long)*21]];
		}
	}	
}
#pragma mark •••Convenience Methods
- (float) voltage:(int)aChannel
{
	if(aChannel>-0 && aChannel<8){
		return [self channel:aChannel readParamAsFloat:@"outputMeasurementSenseVoltage"];
	}
	else return 0;
}

- (float) current:(int)aChannel
{
	if(aChannel>-0 && aChannel<8){
		return [self channel:aChannel readParamAsFloat:@"outputMeasurementCurrent"];
	}
	else return 0;
}
@end
