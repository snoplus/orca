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
#import "ORDetectorRamper.h"

NSString* OREHS8260pModelOutputFailureBehaviorChanged = @"OREHS8260pModelOutputFailureBehaviorChanged";
NSString* OREHS8260pModelCurrentTripBehaviorChanged = @"OREHS8260pModelCurrentTripBehaviorChanged";
NSString* OREHS8260pModelSupervisorMaskChanged	= @"OREHS8260pModelSupervisorMaskChanged";
NSString* OREHS8260pModelTripTimeChanged		= @"OREHS8260pModelTripTimeChanged";
NSString* OREHS8260pSettingsLock				= @"OREHS8260pSettingsLock";

@implementation OREHS8260pModel
#pragma mark ***Initialization
- (void) dealloc
{
    int i;
    for(i=0;i<8;i++)[ramper[i] release];
    [super dealloc];
}

- (void) sleep
{
    int i;
    for(i=0;i<8;i++)[ramper[i] stopRamping];
    [super sleep];
}

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

- (NSString*) helpURL
{
	return @"MPod/EHS8260p.html";
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

- (void) startStagedRamp:(int)i
{
    if(i>=0 && i<8) [ramper[i] startRamping];
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
	//[self writeTripTime:channel];
	//[self writeSupervisorBehaviour:channel];
}

- (void) makeRampers
{
    [[self undoManager] disableUndoRegistration];
 	int i;
	for(i=0;i<8;i++){
        if(!ramper[i]){
            
            ramper[i] = [[ORDetectorRamper alloc] initWithDelegate:self channel:i];
            
            //defaults
            ramper[i].maxVoltage    = 3300;
            ramper[i].minVoltage    = 0;
            ramper[i].voltageStep   = 150;
            ramper[i].stepWait      = 10;
            
            ramper[i].lowVoltageThreshold   = 500;
            ramper[i].lowVoltageStep        = 75;
            ramper[i].lowVoltageWait        = 30;
        }
    }   
	[[self undoManager] enableUndoRegistration];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self makeRampers];
	int i;
	for(i=0;i<8;i++){
		[self setTripTime:i withValue:[decoder decodeIntForKey: [@"tripTime" stringByAppendingFormat:@"%d",i]]];
		[self setOutputFailureBehavior:i withValue:[decoder decodeIntForKey: [@"outputFailureBehavior" stringByAppendingFormat:@"%d",i]]];
		[self setCurrentTripBehavior:i withValue:[decoder decodeIntForKey: [@"currentTripBehavior" stringByAppendingFormat:@"%d",i]]];
        [ramper[i] initWithCoder:decoder];
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
        [ramper[i] encodeWithCoder:encoder];
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

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Step Wait"];
    [p setFormat:@"##0" upperLimit:100 lowerLimit:1 stepSize:1 units:@"s"];
    [p setSetMethod:@selector(setStepWait:withValue:) getMethod:@selector(stepWait:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Low Voltage Wait"];
    [p setFormat:@"##0" upperLimit:100 lowerLimit:1 stepSize:1 units:@"s"];
    [p setSetMethod:@selector(setLowVoltageWait:withValue:) getMethod:@selector(lowVoltageWait:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Low Voltage Threshold"];
    [p setFormat:@"##0" upperLimit:5000 lowerLimit:1 stepSize:1 units:@"s"];
    [p setSetMethod:@selector(setLowVoltageThreshold:withValue:) getMethod:@selector(lowVoltageThreshold:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Low Voltage Step"];
    [p setFormat:@"##0" upperLimit:500 lowerLimit:1 stepSize:1 units:@"s"];
    [p setSetMethod:@selector(setLowVoltageStep:withValue:) getMethod:@selector(lowVoltageStep)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Voltage Step"];
    [p setFormat:@"##0" upperLimit:500 lowerLimit:1 stepSize:1 units:@"s"];
    [p setSetMethod:@selector(setVoltageStep:withValue:) getMethod:@selector(voltageStep)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Max Voltage"];
    [p setFormat:@"##0" upperLimit:500 lowerLimit:1 stepSize:1 units:@"s"];
    [p setSetMethod:@selector(setMaxVoltage:withValue:) getMethod:@selector(maxVoltage)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Min Voltage"];
    [p setFormat:@"##0" upperLimit:3300 lowerLimit:1 stepSize:1 units:@"s"];
    [p setSetMethod:@selector(setMinVoltage:withValue:) getMethod:@selector(minVoltage)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Step Ramp Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setStepRampEnabled:withValue:) getMethod:@selector(stepRampEnabled:)];
    [a addObject:p];

    
    return [a autorelease];
}

//----------------------------------------------------------------------------------------------
//call thrus just for using the wizard.
- (void) setStepWait:(int)i withValue:(int)aValue { ramper[i].stepWait = aValue; }
- (int) stepWait:(int)i { return ramper[i].stepWait; }
- (void) setLowVoltageWait:(int)i withValue:(int)aValue { ramper[i].lowVoltageWait = aValue; }
- (int) lowVoltageWait:(int)i { return ramper[i].lowVoltageWait; }
- (void) setLowVoltageThreshold:(int)i withValue:(int)aValue { ramper[i].lowVoltageThreshold = aValue; }
- (int) lowVoltageThreshold:(int)i { return ramper[i].lowVoltageThreshold; }
- (void) setLowVoltageStep:(int)i withValue:(int)aValue { ramper[i].lowVoltageStep = aValue; }
- (int) lowVoltagestep:(int)i { return ramper[i].lowVoltageStep; }
- (void) setVoltageStep:(int)i withValue:(int)aValue { ramper[i].voltageStep = aValue; }
- (int) voltagestep:(int)i { return ramper[i].voltageStep; }
- (void) setMaxVoltage:(int)i withValue:(int)aValue { ramper[i].maxVoltage = aValue; }
- (int) maxVoltage:(int)i { return ramper[i].maxVoltage; }
- (void) setMinVoltage:(int)i withValue:(int)aValue { ramper[i].minVoltage = aValue; }
- (int) minVoltage:(int)i { return ramper[i].minVoltage; }
- (void) setStepRampEnabled:(int)i withValue:(int)aValue { ramper[i].enabled = aValue; }
- (int) stepRampEnabled:(int)i { return ramper[i].enabled; }
//----------------------------------------------------------------------------------------------

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
