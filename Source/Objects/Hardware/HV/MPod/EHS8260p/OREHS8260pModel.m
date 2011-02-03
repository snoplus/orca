//
//  OREHS8260pModel.m
//  Orca
//
//  Created by Mark Howe on Tues Feb 1,2011
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
#import "OREHS8260pModel.h"
#import "ORMPodProtocol.h"
#import "ORTimeRate.h"
#import "ORHWWizSelection.h"
#import "ORHWWizParam.h"

NSString* OREHS8260pModelOutputFailureBehaviorChanged = @"OREHS8260pModelOutputFailureBehaviorChanged";
NSString* OREHS8260pModelCurrentTripBehaviorChanged = @"OREHS8260pModelCurrentTripBehaviorChanged";
NSString* OREHS8260pModelSupervisorMaskChanged	= @"OREHS8260pModelSupervisorMaskChanged";
NSString* OREHS8260pModelTripTimeChanged		= @"OREHS8260pModelTripTimeChanged";
NSString* OREHS8260pSettingsLock				= @"OREHS8260pSettingsLock";

@implementation OREHS8260pModel
#pragma mark ***Initialization

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"EHS8260p"]];	
}

- (void) makeMainController
{
    [self linkToController:@"OREHS8260pController"];
}
- (NSString*) settingsLock
{
	 return OREHS8260pSettingsLock;
}

- (NSString*) name
{
	 return @"EHS8260p";
}

#pragma mark ***Accessors

- (short) outputFailureBehavior:(short)chan
{
	if([self channelInBounds:chan]){
		return outputFailureBehavior[chan];
	}
	else return 0;
}

- (void) setOutputFailureBehavior:(short)chan withValue:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOutputFailureBehavior:chan withValue: outputFailureBehavior[chan]];
    outputFailureBehavior[chan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREHS8260pModelOutputFailureBehaviorChanged object:self];
}

- (short) currentTripBehavior:(short)chan
{
	if([self channelInBounds:chan]) {
		return currentTripBehavior[chan];
	}
	else return 0;
}

- (void) setCurrentTripBehavior:(short)chan withValue:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCurrentTripBehavior:chan withValue:currentTripBehavior[chan]];
    currentTripBehavior[chan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREHS8260pModelCurrentTripBehaviorChanged object:self];
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
		@"outputSupervisionBehavior",
		@"outputTripTimeMaxCurrent",
		//@"outputSupervisionMinSenseVoltage",
		//@"outputSupervisionMaxSenseVoltage",
		//@"outputSupervisionMaxTerminalVoltage",	
		//@"outputSupervisionMaxCurrent",
		//@"outputSupervisionMaxTemperature",	
		//@"outputConfigMaxSenseVoltage",
		//@"outputConfigMaxTerminalVoltage",	
		//@"outputConfigMaxCurrent",
		//@"outputConfigMaxPower",
		nil];
	NSArray* cmds = [self addChannelNumbersToParams:channelReadParams];
	return cmds;
}

- (NSArray*) commonChannelUpdateList
{
	NSArray* channelReadParams = [NSArray arrayWithObjects:
								  @"outputVoltageRiseRate",
								  @"outputMeasurementTemperature",	
								  nil];
	NSArray* cmds = [self addChannel:0 toParams:channelReadParams];
	return cmds;
}

- (void) writeTripTimes
{  
	int i;
	for(i=0;i<8;i++){
		[self writeTripTime:i];
	}
}

- (void) writeTripTime:(int)channel
{    
	if([self channelInBounds:channel]){
		NSString* cmd = [NSString stringWithFormat:@"outputTripTimeMaxCurrent.u%d i %d",[self slotChannelValue:channel],tripTime[channel]];
		[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
	}
}
- (void) writeSupervisorBehaviours
{  
	int i;
	for(i=0;i<8;i++){
		[self writeSupervisorBehaviour:i];
	}
}

- (void) writeSupervisorBehaviour:(int)channel
{    
	if([self channelInBounds:channel]){
		short aValue = ((currentTripBehavior[channel] & 0x3)<<6) | ((outputFailureBehavior[channel] & 0x3)<<12);
		NSString* cmd = [NSString stringWithFormat:@"outputSupervisionBehavior.u%d i %d",[self slotChannelValue:channel],aValue];
		[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
	}
}

- (short) tripTime:(short)chan	
{ 
	if([self channelInBounds:chan])return tripTime[chan]; 
	else return 0;
}
- (void) setTripTime:(short)chan withValue:(short)aValue 
{
	if([self channelInBounds:chan]){
		if(aValue<16)		 aValue = 16;
		else if(aValue>4000) aValue = 4000;
	
		[[[self undoManager] prepareWithInvocationTarget:self] setTripTime:chan withValue:tripTime[chan]];
		tripTime[chan] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:OREHS8260pModelTripTimeChanged object:self];
	}
}

- (NSString*) behaviourString:(int)channel
{
	if([self channelInBounds:channel]){
		NSString* options[4] = {
			@"Ig",		//0
			@"RDn",		//1
			@"SwOff",	//2
			@"BdOff"	//3
		};
		
		short i = currentTripBehavior[channel];
		NSString* s1;
		if(i<4)s1 = options[i];
		else   s1 = @"?";
		
		i = outputFailureBehavior[channel];
		NSString* s2;
		if(i<4)s2 = options[i];
		else   s2 = @"?";
		return [NSString stringWithFormat:@"%@:%@",s1,s2];
	}
	else return @"--";
}

#pragma mark •••Hardware Access
- (void) loadAllValues
{
	[super loadAllValues];
	[self writeTripTimes];
	[self writeSupervisorBehaviours];
}

- (void) loadValues:(int)channel
{
	[super loadValues:channel];
	[self writeTripTime:channel];
	[self writeSupervisorBehaviour:channel];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	int i;
	for(i=0;i<8;i++){
		[self setTripTime:i withValue:[decoder decodeIntForKey: [@"tripTime" stringByAppendingFormat:@"%d",i]]];
		[self setOutputFailureBehavior:i withValue:[decoder decodeIntForKey: [@"outputFailureBehavior" stringByAppendingFormat:@"%d",i]]];
		[self setCurrentTripBehavior:i withValue:[decoder decodeIntForKey: [@"currentTripBehavior" stringByAppendingFormat:@"%d",i]]];
	}
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	int i;
 	for(i=0;i<8;i++){
		[encoder encodeInt:tripTime[i]		forKey:[@"tripTime" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:outputFailureBehavior[i]		forKey:[@"outputFailureBehavior" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:currentTripBehavior[i]		forKey:[@"currentTripBehavior" stringByAppendingFormat:@"%d",i]];
	}
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
	[super addParametersToDictionary:dictionary];
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[self addCurrentState:objDictionary cIntArray:tripTime forKey:@"tripTime"];
	[self addCurrentState:objDictionary cIntArray:outputFailureBehavior forKey:@"outputFailureBehavior"];
	[self addCurrentState:objDictionary cIntArray:currentTripBehavior forKey:@"currentTripBehavior"];
	
    return objDictionary;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORMPodCrate"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"OREHS8260pModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"OREHS8260pModel"]];
    return a;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [[super wizardParameters] mutableCopy];
    ORHWWizParam* p;
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trip Time"];
    [p setFormat:@"##0" upperLimit:4000 lowerLimit:16 stepSize:1 units:@"mA"];
    [p setSetMethod:@selector(setTripTime:withValue:) getMethod:@selector(tripTime:)];
	[p setInitMethodSelector:@selector(loadAllValues)];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"I Trip Behavior"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@"mA"];
    [p setSetMethod:@selector(setCurrentTripBehavior:withValue:) getMethod:@selector(currentTripBehavior:)];
	[p setInitMethodSelector:@selector(loadAllValues)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Failure Behavior"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@"mA"];
    [p setSetMethod:@selector(setOutputFailureBehavior:withValue:) getMethod:@selector(outputFailureBehavior:)];
	[p setInitMethodSelector:@selector(loadAllValues)];
    [a addObject:p];

    return [a autorelease];
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSNumber* value= [super extractParam:param from:fileHeader forChannel:aChannel];
	if(value)return value;
	else {
		NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
		if([param isEqualToString:@"Trip Time"])			return [[cardDictionary objectForKey:@"tripTime"] objectAtIndex:aChannel];
		else if([param isEqualToString:@"I Trip Behavior"]) return [[cardDictionary objectForKey:@"currentTripBehavior"] objectAtIndex:aChannel];
		else if([param isEqualToString:@"Failure Behavior"])return [[cardDictionary objectForKey:@"outputFailureBehavior"] objectAtIndex:aChannel];
		else return nil;
	}
}
@end
