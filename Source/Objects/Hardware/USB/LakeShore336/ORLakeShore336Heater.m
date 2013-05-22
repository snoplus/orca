//
//  ORLakeShore336Heater.m
//  Orca
//
//  Created by Mark Howe on Mon, May 6, 2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
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

#import "ORLakeShore336Heater.h"
#import "ORTimeRate.h"

NSString* ORLakeShore336HeaterResistanceChanged       = @"ORLakeShore336HeaterResistanceChanged";
NSString* ORLakeShore336HeaterMaxCurrentChanged       = @"ORLakeShore336HeaterMaxCurrentChanged";
NSString* ORLakeShore336HeaterMaxUserCurrentChanged   = @"ORLakeShore336HeaterMaxUserCurrentChanged";
NSString* ORLakeShore336HeaterCurrentOrPowerChanged   = @"ORLakeShore336HeaterCurrentOrPowerChanged";
NSString* ORLakeShore336OutputChanged = @"ORLakeShore336OutputChanged";

@implementation ORLakeShore336Heater

@synthesize label,channel,output,resistance, maxCurrent, maxUserCurrent, currentOrPower;
@synthesize lowLimit,highLimit,minValue,maxValue,timeRate,timeMeasured;

- (id) init
{
    self = [super init];
    lowLimit    = 0;
    highLimit   = 100;
    minValue    = 0;
    maxValue    = 100;
    return self;
}

- (void) dealloc
{
    [label release];
    [timeRate release];
    [super dealloc];
}

- (void) setOutput:(float)aValue
{
    output = aValue;
    
    //get the time(UT!)
    time_t	ut_Time;
    time(&ut_Time);
    timeMeasured = ut_Time;
    
    if(timeRate == nil) self.timeRate = [[[ORTimeRate alloc] init] autorelease];
    [timeRate addDataToTimeAverage:aValue];
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:channel] forKey:@"Index"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336OutputChanged object:self userInfo:userInfo];
}

- (void) setResistance:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setResistance:resistance];
     resistance= aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336HeaterResistanceChanged object:self];
}

- (void) setMaxCurrent:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxCurrent:maxCurrent];
    maxCurrent = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336HeaterMaxCurrentChanged object:self];
}

- (void) setMaxUserCurrent:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxUserCurrent:maxUserCurrent];
    maxUserCurrent = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336HeaterMaxUserCurrentChanged object:self];
}

- (void) setCurrentOrPower:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCurrentOrPower:currentOrPower];
    currentOrPower = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336HeaterCurrentOrPowerChanged object:self];
}

- (NSUndoManager*) undoManager
{
    return [[NSApp delegate] undoManager];
}

- (BOOL) maxUserCurrentEnabled
{
    return (maxCurrent != 0);
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [self setChannel:       [decoder decodeIntForKey:   @"channel"]];
    [self setResistance:    [decoder decodeIntForKey:   @"resistance"]];
	[self setMaxCurrent:    [decoder decodeBoolForKey:  @"maxCurrent"]];
    [self setMaxUserCurrent:[decoder decodeIntForKey:   @"maxUserCurrent"]];
    [self setCurrentOrPower:[decoder decodeBoolForKey:  @"currentOrPower"]];
    [self setLowLimit:      [decoder decodeFloatForKey: @"lowLimit"]];
    [self setHighLimit:     [decoder decodeFloatForKey: @"highLimit"]];
    [self setMinValue:      [decoder decodeFloatForKey: @"minValue"]];
    [self setMaxValue:      [decoder decodeFloatForKey: @"maxValue"]];
    [self setLabel:         [decoder decodeObjectForKey: @"label"]];
    
    if(lowLimit < 0.001 && highLimit < 0.001 && minValue < 0.001 && maxValue < 0.001){
        lowLimit = 0;
        highLimit = 100;
        minValue = 0;
        maxValue = 100;
    }
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt:channel          forKey:@"channel"];
    [encoder encodeInt:resistance       forKey:@"resistance"];
    [encoder encodeBool:maxCurrent      forKey:@"maxCurrent"];
    [encoder encodeInt:maxUserCurrent   forKey:@"maxUserCurrent"];
    [encoder encodeBool:currentOrPower  forKey:@"currentOrPower"];
    [encoder encodeFloat:lowLimit       forKey:@"lowLimit"];
    [encoder encodeFloat:highLimit      forKey:@"highLimit"];
    [encoder encodeFloat:minValue       forKey:@"minValue"];
    [encoder encodeFloat:maxValue       forKey:@"maxValue"];
    [encoder encodeObject:label         forKey:@"label"];
}
- (int) numberPointsInTimeRate
{
    return [timeRate count];
}

- (void) timeRateAtIndex:(int)i x:(double*)xValue y:(double*)yValue
{
    int count   = [timeRate count];
    int index   = count-i-1;
    *xValue     = [timeRate timeSampledAtIndex:index];
    *yValue     = [timeRate valueAtIndex:index];
}

@end
