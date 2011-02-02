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
#import "ORDataTypeAssigner.h"
#import "TimedWorker.h"
#import "ORMPodProtocol.h"
#import "ORTimeRate.h"
#import "ORHWWizSelection.h"
#import "ORHWWizParam.h"

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

- (int) supervisorMask
{
    return supervisorMask;
}

- (void) setSupervisorMask:(int)aSupervisorMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSupervisorMask:supervisorMask];
    
    supervisorMask = aSupervisorMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREHS8260pModelSupervisorMaskChanged object:self];
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
	if(channel>=0 && channel<8){
		NSString* cmd = [NSString stringWithFormat:@"outputTripTimeMaxCurrent.u%d i %d",[self slotChannelValue:channel],tripTime[channel]];
		[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
	}
}

- (void) writeSupervisorBehaviour:(int)channel value:(int)aValue
{    
	if(channel>=0 && channel<8){
		NSString* cmd = [NSString stringWithFormat:@"outputSupervisionBehavior.u%d i %f",[self slotChannelValue:channel],aValue];
		[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:)];
	}
}

- (short) tripTime:(short)chan	{ return tripTime[chan]; }
- (void) setTripTime:(short)chan withValue:(short)aValue 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTripTime:chan withValue:tripTime[chan]];
    tripTime[chan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREHS8260pModelTripTimeChanged object:self];
}


#pragma mark •••Hardware Access
- (void) loadAllValues
{
	[super loadAllValues];
	[self writeTripTimes];
}

- (void) loadValues:(int)channel
{
	[super loadValues:channel];
	[self writeTripTimes];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
		
    [self setSupervisorMask:	[decoder decodeIntForKey:@"supervisorMask"]];
	int i;
	for(i=0;i<8;i++){
		[self setTripTime:i withValue:[decoder decodeIntForKey: [@"tripTime" stringByAppendingFormat:@"%d",i]]];
	}
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];

	[encoder encodeInt:supervisorMask	forKey:@"supervisorMask"];
	int i;
 	for(i=0;i<8;i++){
		[encoder encodeInt:tripTime[i]		forKey:[@"tripTime" stringByAppendingFormat:@"%d",i]];
	}
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
	[super addParametersToDictionary:dictionary];
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[self addCurrentState:objDictionary cIntArray:tripTime forKey:@"tripTime"];
    [objDictionary setObject:[NSNumber numberWithInt:supervisorMask] forKey:@"supervisorMask"];
	
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
    [p setFormat:@"##0" upperLimit:1000 lowerLimit:1 stepSize:1 units:@"mA"];
    [p setSetMethod:@selector(setTripTime:withValue:) getMethod:@selector(tripTime:)];
	[p setInitMethodSelector:@selector(loadAllValues)];
    [a addObject:p];
	
    return [a autorelease];
}

@end
