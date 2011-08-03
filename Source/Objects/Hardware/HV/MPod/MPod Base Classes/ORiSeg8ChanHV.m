//
//  ORiSeg8ChanHV.m
//  Orca
//
//  Created by Mark Howe on Wed Feb 2,2011
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


#import "ORiSeg8ChanHV.h"
#import "ORDataTypeAssigner.h"
#import "ORMPodProtocol.h"
#import "ORTimeRate.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"

NSString* ORiSeg8ChanHVShipRecordsChanged		= @"ORiSeg8ChanHVShipRecordsChanged";
NSString* ORiSeg8ChanHVMaxCurrentChanged		= @"ORiSeg8ChanHVMaxCurrentChanged";
NSString* ORiSeg8ChanHVSelectedChannelChanged	= @"ORiSeg8ChanHVSelectedChannelChanged";
NSString* ORiSeg8ChanHVSettingsLock				= @"ORiSeg8ChanHVSettingsLock";
NSString* ORiSeg8ChanHVHwGoalChanged			= @"ORiSeg8ChanHVHwGoalChanged";
NSString* ORiSeg8ChanHVTargetChanged			= @"ORiSeg8ChanHVTargetChanged";
NSString* ORiSeg8ChanHVCurrentChanged			= @"ORiSeg8ChanHVCurrentChanged";
NSString* ORiSeg8ChanHVOutputSwitchChanged		= @"ORiSeg8ChanHVOutputSwitchChanged";
NSString* ORiSeg8ChanHVRiseRateChanged			= @"ORiSeg8ChanHVRiseRateChanged";
NSString* ORiSeg8ChanHVChannelReadParamsChanged = @"ORiSeg8ChanHVChannelReadParamsChanged";

@implementation ORiSeg8ChanHV

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
	for(i=0;i<8;i++){
		[voltageHistory[i] release];
		[currentHistory[i] release];
	}
     [super dealloc];
}


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"iSeg8ChanHV"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORiSeg8ChanHVController"];
}

- (NSString*) settingsLock
{
	return @"";  //subclasses should override
}

- (NSString*) name
{
	return @"??"; //subclasses should override
}

- (BOOL) polarity
{
	return kPositivePolarity;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiSeg8ChanHVShipRecordsChanged object:self];
}

- (BOOL) channelInBounds:(int)aChan
{
	if(aChan>=0 && aChan<8)return YES;
	else return NO;
}

- (int) selectedChannel
{
    return selectedChannel;
}

- (void) setSelectedChannel:(int)aSelectedChannel
{
    selectedChannel = aSelectedChannel;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORiSeg8ChanHVSelectedChannelChanged object:self];
}

- (int) channel:(int)i readParamAsInt:(NSString*)name
{
	if([self channelInBounds:i]){
		return [[[rdParams[i] objectForKey:name] objectForKey:@"Value"] intValue];
	}
	else return 0;
}

- (float) channel:(int)i readParamAsFloat:(NSString*)name
{
	if([self channelInBounds:i]){
		return [[[rdParams[i] objectForKey:name] objectForKey:@"Value"] floatValue];
	}
	else return 0;
}

- (id) channel:(int)i readParamAsValue:(NSString*)name
{
	if([self channelInBounds:i]){
		return [[rdParams[i] objectForKey:name] objectForKey:@"Value"];
	}
	else return nil;
}

- (id) channel:(int)i readParamAsObject:(NSString*)name
{
	if([self channelInBounds:i]){
		return [rdParams[i] objectForKey:name];
	}
	else return @"";
}


- (NSArray*) channelUpdateList
{
	return nil; //subclasses should override
}

- (NSArray*) commonChannelUpdateList
{
	return nil; //subclasses should override
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
		for(i=0;i<8;i++){
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
	NSArray* updateRequests = [self channelUpdateList];
	updateRequests = [updateRequests arrayByAddingObjectsFromArray:[self commonChannelUpdateList]];
	[[self adapter] getValues: updateRequests  target:self selector:@selector(processReadResponseArray:)];
	if(shipRecords) [self shipDataRecords];
}

- (void) processReadResponseArray:(NSArray*)response
{
	
	[super processReadResponseArray:response];
	
	for(id anEntry in response){
		NSString* anError = [anEntry objectForKey:@"Error"];
		if([anError length]){
			if([anError rangeOfString:@"Timeout"].location != NSNotFound){
				NSLogError(@"TimeOut",[NSString stringWithFormat:@"MPod Crate %d\n",[self crateNumber]],[NSString stringWithFormat:@"HV Card %d\n",[self slot]],nil);
				break;
			}
		}
		else {
			//make sure the slot matches: if not then ignore this Entry
			int theSlot = [[anEntry objectForKey:@"Slot"] intValue];
			if(theSlot == [self slot]){
				if([anEntry objectForKey:@"Channel"]){
					int theChannel = [[anEntry objectForKey:@"Channel"] intValue];
					NSString* name = [anEntry objectForKey:@"Name"];
					if([self channelInBounds:theChannel]){
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
			for(i=0;i<8;i++){
				[rdParams[i] removeAllObjects];
			}
		}
	}
	
	int i;
	for(i=0;i<8;i++){
		if(voltageHistory[i] == nil) voltageHistory[i] = [[ORTimeRate alloc] init];
		if(currentHistory[i] == nil) currentHistory[i] = [[ORTimeRate alloc] init];
		[voltageHistory[i] addDataToTimeAverage:[self channel:i readParamAsFloat:@"outputMeasurementSenseVoltage"]];
		[currentHistory[i] addDataToTimeAverage:[self channel:i readParamAsFloat:@"outputMeasurementCurrent"]];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORiSeg8ChanHVChannelReadParamsChanged object:self];
	

}

- (void) processWriteResponseArray:(NSArray*)response
{
	[super processWriteResponseArray:response];
	for(id anEntry in response){
		NSString* anError = [anEntry objectForKey:@"Error"];
		if([anError length]){
			if([anError rangeOfString:@"Timeout"].location != NSNotFound){
				NSLogError(@"TimeOut",[NSString stringWithFormat:@"MPod Crate %d\n",[self crateNumber]],[NSString stringWithFormat:@"HV Card %d\n",[self slot]],nil);
				break;
			}
		}
		else {
		}
	}
}

- (int) numberChannelsOn
{
	int count = 0;
	int i;
	for(i=0;i<8;i++){
		int state = [self channel:i readParamAsInt:@"outputSwitch"];
		if(state == kiSeg8ChanHVOutputOn)count++;
	}
	return count;
}
- (unsigned long) channelStateMask
{
	unsigned long mask = 0x0;
	int i;
	for(i=0;i<8;i++){
		int state = [self channel:i readParamAsInt:@"outputSwitch"];
		mask |= (1L<<state);
	}
	return mask;
}

- (BOOL) channelIsRamping:(int)chan
{
	int state = [self channel:chan readParamAsInt:@"outputStatus"];
	if(state & outputOnMask){
		if(state & outputRampUpMask)return YES;
		else if(state & outputRampDownMask)return YES;
	}
	return NO;
}

- (int) numberChannelsRamping
{
	int count = 0;
	int i;
	for(i=0;i<8;i++){
		if([self channelIsRamping:i])count++;
	}
	return count;
}

- (int) numberChannelsWithNonZeroVoltage
{
	int count = 0;
	int i;
	for(i=0;i<8;i++){
		float voltage	= [self channel:i readParamAsFloat:@"outputMeasurementSenseVoltage"];
		if(voltage > 0)count++;
	}
	return count;
}

- (int) numberChannelsWithNonZeroHwGoal
{
	int count = 0;
	int i;
	for(i=0;i<8;i++){
		if(hwGoal[i] > 0)count++;
	}
	return count;
}

- (void)  commitTargetsToHwGoals
{
	int i;
	for(i=0;i<8;i++){
		[self commitTargetToHwGoal:i];
	}
}

- (void) commitTargetToHwGoal:(int)channel
{
	if([self channelInBounds:channel]){
		hwGoal[channel] = target[channel];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORiSeg8ChanHVChannelReadParamsChanged object:self];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORiSeg8ChanHVHwGoalChanged object:self];
	}
}
- (void) loadValues:(int)channel
{
	if([self channelInBounds:channel]){
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
	if([self channelInBounds:channel]){
		NSString* cmd = [NSString stringWithFormat:@"outputVoltage.u%d F %f",[self slotChannelValue:channel],(float)hwGoal[channel]];
		[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
	}
}

- (void) writeMaxCurrent:(int)channel
{    
	if([self channelInBounds:channel]){
		NSString* cmd = [NSString stringWithFormat:@"outputCurrent.u%d F %f",[self slotChannelValue:channel],maxCurrent[channel]/1000.];
		[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
	}
}

- (void) setPowerOn:(int)channel withValue:(BOOL)aValue
{
	if(aValue) [self turnChannelOn:channel];
	else [self turnChannelOff:channel];
}

- (void) turnChannelOn:(int)channel
{    
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kiSeg8ChanHVOutputOn];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
}

- (void) turnChannelOff:(int)channel
{    
	[self setHwGoal:channel withValue:0];
	[self writeVoltage:channel];
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kiSeg8ChanHVOutputOff];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
}

- (void) panicChannel:(int)channel
{    
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kiSeg8ChanHVOutputSetEmergencyOff];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
}

- (void) clearPanicChannel:(int)channel
{    
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kiSeg8ChanHVOutputResetEmergencyOff];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
}

- (void) clearEventsChannel:(int)channel
{    
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kiSeg8ChanHVOutputClearEvents];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
}

- (void) stopRamping:(int)channel
{
	if([self channelInBounds:channel]){
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
	if([self channelInBounds:channel]){
		[self setHwGoal:channel withValue:0];
		[self writeVoltage:channel];
	}
}

- (void) panic:(int)channel
{
	if([self channelInBounds:channel]){
		[self setHwGoal:channel withValue:0];
		[self writeVoltage:channel];
		[self panicChannel:channel];
	}
}

- (BOOL) isOn:(int)aChannel
{
	if([self channelInBounds:aChannel]){
		int outputSwitch = [self channel:aChannel readParamAsInt:@"outputSwitch"];
		return outputSwitch==kiSeg8ChanHVOutputOn;
	}
	else return NO;
}

- (void) turnAllChannelsOn
{
	int i;
	for(i=0;i<8;i++)[self turnChannelOn:i];
}

- (void) turnAllChannelsOff
{
	int i;
	for(i=0;i<8;i++){
		[self turnChannelOff:i];
	}
}

- (void) panicAllChannels
{
	int i;
	for(i=0;i<8;i++)[self panic:i];
}

- (void) clearAllPanicChannels
{
	int i;
	for(i=0;i<8;i++)[self clearPanicChannel:i];
}

- (void) clearAllEventsChannels
{
	int i;
	for(i=0;i<8;i++)[self clearEventsChannel:i];	
}

- (void) stopAllRamping
{
	int i;
	for(i=0;i<8;i++)[self stopRamping:i];
}

- (void) rampAllToZero
{
	int i;
	for(i=0;i<8;i++)[self rampToZero:i];
}

- (void) panicAll
{
	int i;
	for(i=0;i<8;i++)[self panic:i];
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
	for(i=0;i<8;i++){
		failEvents |= [self failureEvents:i];
	}
	return failEvents;
}

- (NSString*) channelState:(int)channel
{ 
	int outputSwitch = [self channel:channel readParamAsInt:@"outputSwitch"];
	int outputStatus = [self channel:channel readParamAsInt:@"outputStatus"];
	if(outputSwitch == kiSeg8ChanHVOutputSetEmergencyOff)	return @"PANICKED";
	else {
		if(outputStatus & kiSeg8ChanHVProblemMask)			return @"PROBLEM";
		else if(outputStatus & outputRampUpMask)		return @"RAMP UP";
		else if(outputStatus & outputRampDownMask)		return @"RAMP DN";
		else {
			switch(outputSwitch){
				case kiSeg8ChanHVOutputOff:				return @"OFF";
				case kiSeg8ChanHVOutputOn:					return @"ON";
				case kiSeg8ChanHVOutputResetEmergencyOff:  return @"PANIC CLR";
				case kiSeg8ChanHVOutputSetEmergencyOff:	return @"PANICKED";
				case kiSeg8ChanHVOutputClearEvents:		return @"EVENT CLR";
				default: return @"?";
			}
		}
	}
}

- (void) processSyncResponseArray:(NSArray*)response
{
	[super processSyncResponseArray:response];
	for(id anEntry in response){
		NSString* anError = [anEntry objectForKey:@"Error"];
		if([anError length]){
			if([anError rangeOfString:@"Timeout"].location != NSNotFound){
				NSLogError(@"TimeOut",[NSString stringWithFormat:@"MPod Crate %d\n",[self crateNumber]],[NSString stringWithFormat:@"HV Card %d\n",[self slot]],nil);
				break;
			}
		}
		else {			
			int theChannel = [[anEntry objectForKey:@"Channel"] intValue];
			if(theChannel>=0 && theChannel<8){
				NSString* name = [anEntry objectForKey:@"Name"];
				if([name isEqualToString:@"outputMeasurementSenseVoltage"])	[self setTarget:theChannel withValue:[[anEntry objectForKey:@"Value"] intValue]];
			}
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
	[[NSNotificationCenter defaultCenter] postNotificationName:ORiSeg8ChanHVRiseRateChanged object:self];
}

- (int) hwGoal:(short)chan	
{ 
	if([self channelInBounds:chan])return hwGoal[chan]; 
	else return 0;
}
- (void) setHwGoal:(short)chan withValue:(int)aValue 
{ 
	if([self channelInBounds:chan]){
		if(aValue<0)aValue=0;
		else if(aValue>kMaxVoltage)aValue = kMaxVoltage;
		hwGoal[chan] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORiSeg8ChanHVHwGoalChanged object:self];
	}
}
- (float) maxCurrent:(short)chan 
{ 
	if([self channelInBounds:chan])return maxCurrent[chan]; 
	else return 0;
}

- (void) setMaxCurrent:(short)chan withValue:(float)aValue
{
	if([self channelInBounds:chan]){
		if(aValue<1)aValue=1;
		else if(aValue>kMaxCurrent)aValue = kMaxCurrent;
		[[[self undoManager] prepareWithInvocationTarget:self] setMaxCurrent:chan withValue:maxCurrent[chan]];
		maxCurrent[chan] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORiSeg8ChanHVMaxCurrentChanged object:self];
	}
}

- (int) target:(short)chan	
{ 
	if([self channelInBounds:chan])return target[chan]; 
	else return 0;
}
- (void) setTarget:(short)chan withValue:(int)aValue 
{ 
	if([self channelInBounds:chan]){
		if(aValue<0)aValue=0;
		else if(aValue>kMaxVoltage)aValue = kMaxVoltage;
		[[[self undoManager] prepareWithInvocationTarget:self] setTarget:chan withValue:target[chan]];
		target[chan] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORiSeg8ChanHVTargetChanged object:self];
	}
}


#pragma mark ¥¥¥Hardware Access
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
	for(i=0;i<8;i++){
		[self writeVoltage:i];
	}
}

- (void) writeMaxCurrents
{
	int i;
	for(i=0;i<8;i++){
		[self writeMaxCurrent:i];
	}
}

#pragma mark ¥¥¥Data Taker
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
								 @"ORiSeg8ChanHVDecoderForHV",          @"decoder",
								 [NSNumber numberWithLong:dataId],      @"dataId",
								 [NSNumber numberWithBool:NO],          @"variable",
								 [NSNumber numberWithLong:21],			@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Waveform"];
    
    return dataDictionary;
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
		
    [self setShipRecords:		[decoder decodeBoolForKey:@"shipRecords"]];
    [self setSelectedChannel:	[decoder decodeIntForKey:	@"selectedChannel"]];
	[self setRiseRate:			[decoder decodeFloatForKey:	@"riseRate"]];
	int i;
	for(i=0;i<8;i++){
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
 	for(i=0;i<8;i++){
		//[encoder encodeInt:hwGoal[i] forKey:[@"hwGoal" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:target[i] forKey:[@"target" stringByAppendingFormat:@"%d",i]];
		[encoder encodeFloat:maxCurrent[i] forKey:[@"maxCurrent" stringByAppendingFormat:@"%d",i]];
	}
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[self addCurrentState:objDictionary cIntArray:target forKey:@"targets"];
	[self addCurrentState:objDictionary cFloatArray:maxCurrent forKey:@"maxCurrents"];
    [objDictionary setObject:[NSNumber numberWithFloat:riseRate] forKey:@"riseRate"];
	
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cIntArray:(short*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<8;i++){
		[ar addObject:[NSNumber numberWithInt:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cBoolArray:(BOOL*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<8;i++){
		[ar addObject:[NSNumber numberWithBool:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cFloatArray:(float*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<8;i++){
		[ar addObject:[NSNumber numberWithFloat:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

#pragma mark ¥¥¥Trends
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
		data[1] = (([self crateNumber] & 0xf) << 20) | (([self slot]&0xf)<<16) | ([self polarity] & 0x1);
		data[2] = 0x0; //spare
		data[3] = 0x0; //spare
		data[4] = ut_Time;
		
		union {
			float asFloat;
			unsigned long asLong;
		}theData;
			
		for(i=0;i<8;i++){
			theData.asFloat = [self channel:i readParamAsFloat:@"outputMeasurementSenseVoltage"];
			data[5+i] = theData.asLong;
			
			theData.asFloat = [self channel:i readParamAsFloat:@"outputMeasurementCurrent"];
			data[6+i] = theData.asLong;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(long)*21]];
		}
	}	
}
#pragma mark ¥¥¥Convenience Methods
- (float) voltage:(int)aChannel
{
	if([self channelInBounds:aChannel]){
		return [self channel:aChannel readParamAsFloat:@"outputMeasurementSenseVoltage"];
	}
	else return 0;
}

- (float) current:(int)aChannel
{
	if([self channelInBounds:aChannel]){
		return [self channel:aChannel readParamAsFloat:@"outputMeasurementCurrent"];
	}
	else return 0;
}

#pragma mark ¥¥¥HW Wizard

- (int) numberOfChannels
{
    return 8;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
		
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Turn On"];
    [p setUseValue:NO];
    [p setSetMethod:@selector(turnChannelOn:) getMethod:nil];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Turn Off"];
    [p setUseValue:NO];
    [p setSetMethod:@selector(turnChannelOff:) getMethod:nil];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clear Events"];
    [p setUseValue:NO];
    [p setSetMethod:@selector(clearEventsChannel:) getMethod:nil];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Target Voltage"];
    [p setFormat:@"##0" upperLimit:6000 lowerLimit:0 stepSize:1 units:[NSString stringWithFormat:@"%cV",[self polarity]?'+':'-']];
    [p setSetMethod:@selector(setTarget:withValue:) getMethod:@selector(target:)];
	[p setInitMethodSelector:@selector(loadAllValues)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Max Current"];
    [p setFormat:@"##0" upperLimit:1000 lowerLimit:1 stepSize:1 units:@"mA"];
    [p setSetMethod:@selector(setMaxCurrent:withValue:) getMethod:@selector(maxCurrent:)];
	[p setInitMethodSelector:@selector(loadAllValues)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Ramp Rate"];
    [p setFormat:@"##0" upperLimit:500 lowerLimit:2 stepSize:1 units:[NSString stringWithFormat:@"%cV",[self polarity]?'+':'-']];
    [p setSetMethod:@selector(setRiseRate:) getMethod:@selector(riseRate)];
	[p setInitMethodSelector:@selector(loadAllValues)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Load & Ramp"];
    [p setSetMethodSelector:@selector(loadAllValues)];
    [a addObject:p];
    
    return a;
}



- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:@"Target Voltage"])return [[cardDictionary objectForKey:@"targets"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Max Current"]) return [cardDictionary objectForKey:@"maxCurrents"];
    else if([param isEqualToString:@"Ramp Rate"]) return [cardDictionary objectForKey:@"riseRate"];
    else return nil;
}
- (NSArray*) wizardSelections
{
    return nil; //subclasses MUST override
}

@end
