//
//  ORDetectorRamper.m
//  Orca
//
//  Created by Mark Howe on Friday May 25,2012
//  Copyright (c) 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORDetectorRamper.h"

NSString* ORDetectorRamperStepWaitChanged				= @"ORDetectorRamperStepWaitChanged";
NSString* ORDetectorRamperLowVoltageWaitChanged			= @"ORDetectorRamperLowVoltageWaitChanged";
NSString* ORDetectorRamperLowVoltageThresholdChanged	= @"ORDetectorRamperLowVoltageThresholdChanged";
NSString* ORDetectorRamperLowVoltageStepChanged			= @"ORDetectorRamperLowVoltageStepChanged";
NSString* ORDetectorRamperMaxVoltageChanged				= @"ORDetectorRamperMaxVoltageChanged";
NSString* ORDetectorRamperMinVoltageChanged				= @"ORDetectorRamperMinVoltageChanged";
NSString* ORDetectorRamperVoltageStepChanged			= @"ORDetectorRamperVoltageStepChanged";
NSString* ORDetectorRamperEnabledChanged				= @"ORDetectorRamperEnabledChanged";
NSString* ORDetectorRamperStateChanged					= @"ORDetectorRamperStateChanged";
NSString* ORDetectorRamperRunningChanged				= @"ORDetectorRamperRunningChanged";

@interface ORDetectorRamper (private)
- (void) setRunning:(BOOL)aValue;
- (void) execute;
- (void) setState:(int)aValue;
@end

@implementation ORDetectorRamper

@synthesize delegate, channel, stepWait, lowVoltageThreshold, enabled, state;
@synthesize voltageStep, lowVoltageWait, lowVoltageStep, maxVoltage, minVoltage;
@synthesize lastWaitTime, running, target;

#define kTolerance				1 //Volts

#define kDetRamperIdle                  0
#define kDetRamperStartRamp				1
#define kDetRamperEmergencyOff			2
#define kDetRamperStepWaitForVoltage	3
#define kDetRamperStepToNextVoltage		4
#define kDetRamperStepWait              5
#define kDetRamperDone                  6


- (id) initWithDelegate:(OrcaObject*)aDelegate channel:(int)aChannel
{
	self = [super init];
	if([aDelegate respondsToSelector:@selector(hwGoal:)]  &&
	   [aDelegate respondsToSelector:@selector(voltage:)] &&
	   [aDelegate respondsToSelector:@selector(isOn:)]){
			self.delegate = aDelegate;
	}
	self.channel = aChannel;
	return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	self.lastWaitTime = nil;
	[super dealloc];
}

- (NSUndoManager*) undoManager
{
    return [[NSApp delegate] undoManager];
}

- (void) setStepWait:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStepWait:stepWait];
	stepWait = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperStepWaitChanged object:self];
}

- (void) setLowVoltageWait:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowVoltageWait:lowVoltageWait];
	lowVoltageWait = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperLowVoltageWaitChanged object:self];
}

- (void) setLowVoltageThreshold:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowVoltageThreshold:lowVoltageThreshold];
	lowVoltageThreshold = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperLowVoltageThresholdChanged object:self];
}

- (void) setLowVoltageStep:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowVoltageStep:lowVoltageStep];
	lowVoltageStep = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperLowVoltageStepChanged object:self];
}

- (void) setMaxVoltage:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxVoltage:maxVoltage];
	maxVoltage = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperMaxVoltageChanged object:self];
}

- (void) setMinVoltage:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMinVoltage:minVoltage];
	minVoltage = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperMinVoltageChanged object:self];
}

- (void) setVoltageStep:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVoltageStep:voltageStep];
	voltageStep = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperVoltageStepChanged object:self];
}

- (void) setEnabled:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:enabled];
	enabled = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperEnabledChanged object:self];
}

- (void) setTarget:(float)aTarget    
{
    if(aTarget > maxVoltage)      target = maxVoltage;
    else if(aTarget < minVoltage) target = minVoltage;
    else                          target = aTarget;
}

- (BOOL) atIntermediateGoal
{
	return fabs([delegate voltage:channel] - [delegate hwGoal:channel]) < kTolerance;
}

- (BOOL) atTarget
{
	return fabs([delegate voltage:channel] - target) < kTolerance;
}

- (float) stepSize
{
    if([delegate voltage:channel]<lowVoltageThreshold)return lowVoltageStep;
    else return voltageStep;
}

- (short) timeToWait
{
    if([delegate voltage:channel]<lowVoltageThreshold)return lowVoltageWait;
    else return stepWait;    
}

- (float) nextVoltage
{
    if([delegate voltage:channel] < [delegate hwGoal:channel]){
        return MIN(maxVoltage,MAX(target+[self stepSize],target));  
    }
    else {
       return MAX(minVoltage,MIN(target-[self stepSize],target));
    }
}

- (void) startRamping
{
	if([self atTarget]){
		if(!running) {
			if([delegate isOn:channel]){
				[NSObject cancelPreviousPerformRequestsWithTarget:self];
				self.running = YES;
				self.state = kDetRamperStartRamp;
				[self performSelector:@selector(execute) withObject:nil afterDelay:1.0];
			}
			else NSLog(@"%@ channel %d not on. HV ramp not started.\n",[delegate fullID],channel);
		}
		else NSLog(@"%@ HV already ramping.\n",[delegate fullID]);
	}
	else NSLog(@"%@ HV already at %.2f.\n",[delegate fullID],[delegate voltage:channel]);

}

- (void) emergencyOff
{
	if([delegate isOn:channel]){
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		self.running = YES;
		self.state = kDetRamperEmergencyOff;
		[self performSelector:@selector(execute) withObject:nil afterDelay:1.0];
	}
    else NSLog(@"%@ channel %d not on. EmergencyOff not executed.\n",[delegate fullID],channel);

}

- (void) stopRamping
{
	self.state = kDetRamperDone;
    [self execute];
}

- (NSString*) stateString
{
    switch(state){
        case kDetRamperIdle:                return @"Idle";
        case kDetRamperStartRamp:           return @"Starting";
        case kDetRamperEmergencyOff:        return @"EmergencyOff";
        case kDetRamperStepWaitForVoltage:  return @"Waiting on Voltage";
        case kDetRamperStepToNextVoltage:   return @"Stepping";
        case kDetRamperStepWait:            return @"Waiting at Ste";
        case kDetRamperDone:                return @"Done";    
        default:                            return @"?";
    }
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
			
    //[self setStepWait:				[decoder decodeIntForKey:   @"stepWait"]];
   // [self setLowVoltageWait:		[decoder decodeIntForKey:   @"lowVoltageWait"]];
   // [self setLowVoltageThreshold:	[decoder decodeFloatForKey: @"lowVoltageThreshold"]];
   // [self setLowVoltageStep:		[decoder decodeFloatForKey: @"lowVoltageStep"]];
   // [self setMaxVoltage:			[decoder decodeFloatForKey: @"maxVoltage"]];
   // [self setMinVoltage:			[decoder decodeFloatForKey: @"minVoltage"]];
   // [self setVoltageStep:			[decoder decodeFloatForKey: @"voltageStep"]];
   // [self setEnabled:				[decoder decodeBoolForKey: @"enabled"]];
	
 	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{	
	[encoder encodeInt:stepWait                 forKey:@"stepWait"];
	[encoder encodeInt:lowVoltageWait			forKey:@"lowVoltageWait"];
	[encoder encodeFloat:lowVoltageThreshold	forKey:@"lowVoltageThreshold"];
	[encoder encodeFloat:lowVoltageStep			forKey:@"lowVoltageStep"];
	[encoder encodeFloat:maxVoltage				forKey:@"maxVoltage"];
	[encoder encodeFloat:minVoltage				forKey:@"minVoltage"];
	[encoder encodeFloat:voltageStep			forKey:@"voltageStep"];
	[encoder encodeBool:enabled					forKey:@"enabled"];
}
@end

@implementation ORDetectorRamper (private)

- (void) execute
{
	if(!enabled)                 return;	//must be enabled
	if(![delegate isOn:channel]) return;	//channel must be on
			
	switch (state) {
			
		case kDetRamperStartRamp:
            self.target = [delegate target:channel];
            self.state  = kDetRamperStepToNextVoltage;
        break;
			
		case kDetRamperEmergencyOff:
            self.target = 0;
            self.state  = kDetRamperStepToNextVoltage;			
		break;
												
		case kDetRamperStepToNextVoltage:
			[delegate setHwGoal:channel withValue:[self nextVoltage]];
			[delegate writeVoltage:channel];
			self.state = kDetRamperStepWaitForVoltage;	
        break;
            
        case kDetRamperStepWaitForVoltage:
            if([self atTarget])                self.state = kDetRamperDone;
			else if([self atIntermediateGoal]) self.state = kDetRamperStepWait;	
        break;

        case kDetRamperStepWait:
			if(lastWaitTime) {
				if([[NSDate date] timeIntervalSinceDate:lastWaitTime] >= [self timeToWait]){
					self.lastWaitTime = nil;
					self.state	      = kDetRamperStepToNextVoltage;
				}
			}
            else {
                self.lastWaitTime = [NSDate date];
                [self execute];
            }
        break;
            
		case kDetRamperDone:
			self.running = NO;
            self.lastWaitTime = nil;
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
        break;
	}
}

- (void) setRunning:(BOOL)aValue
{
	running = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperRunningChanged object:self];
}

- (void) setState:(int)aValue
{
	state = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperStateChanged object:self];
}
@end