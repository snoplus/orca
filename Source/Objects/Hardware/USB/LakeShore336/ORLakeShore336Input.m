//
//  ORLakeShore336Input.m
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

#import "ORLakeShore336Input.h"
#import "ORTimeRate.h"

NSString* ORLakeShore336InputSensorTypeChanged   = @"ORLakeShore336InputSensorTypeChanged";
NSString* ORLakeShore336InputAutoRangeChanged    = @"ORLakeShore336InputAutoRangeChanged";
NSString* ORLakeShore336InputRangeChanged        = @"ORLakeShore336InputRangeChanged";
NSString* ORLakeShore336InputCompensationChanged = @"ORLakeShore336InputCompensationChanged";
NSString* ORLakeShore336InputUnitsChanged        = @"ORLakeShore336InputUnitsChanged";
NSString* ORLakeShore336InputTemperatureChanged  = @"ORLakeShore336InputTemperatureChanged";

@implementation ORLakeShore336Input

@synthesize label,channel,temperature, sensorType, autoRange, range, compensation, units;
@synthesize lowLimit,highLimit,minValue,maxValue,timeRate,timeMeasured;
- (id) init
{
    self = [super init];
    lowLimit    = 0;
    highLimit   = 350;
    minValue    = 0;
    maxValue    = 350;
    return self;
}

- (void) dealloc
{
    [label release];
    [timeRate release];
    [super dealloc];
}

- (void) setTemperature:(float)aValue
{
    temperature = aValue;

    //get the time(UT!)
    time_t	ut_Time;
    time(&ut_Time);
    timeMeasured = ut_Time;

    if(timeRate == nil) self.timeRate = [[[ORTimeRate alloc] init] autorelease];
    [timeRate addDataToTimeAverage:aValue];

    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:channel] forKey:@"Index"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336InputTemperatureChanged object:self userInfo:userInfo];
}

- (void) setSensorType:(ls336SensorTypeEnum)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSensorType:sensorType];
    sensorType = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336InputSensorTypeChanged object:self];
}

- (void) setAutoRange:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoRange:autoRange];
    autoRange = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336InputAutoRangeChanged object:self];
}

- (void) setRange:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRange:range];
    range = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336InputRangeChanged object:self];
}

- (void) setCompensation:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCompensation:compensation];
    compensation = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336InputCompensationChanged object:self];
}

- (void) setUnits:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUnits:units];
    units = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336InputUnitsChanged object:self];
}

- (NSUndoManager*) undoManager
{
    return [[NSApp delegate] undoManager];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [self setChannel:       [decoder decodeIntForKey:   @"channel"]];
    [self setLabel:         [decoder decodeObjectForKey: @"label"]];
    [self setSensorType:    [decoder decodeIntForKey:   @"sensorType"]];
	[self setAutoRange:     [decoder decodeBoolForKey:  @"autoRange"]];
    [self setRange:         [decoder decodeIntForKey:   @"range"]];
    [self setCompensation:  [decoder decodeBoolForKey:  @"compensation"]];
    [self setUnits:         [decoder decodeIntForKey:   @"units"]];
    [self setLowLimit:      [decoder decodeFloatForKey: @"lowLimit"]];
    [self setHighLimit:      [decoder decodeFloatForKey: @"highLimit"]];
    [self setMinValue:      [decoder decodeFloatForKey: @"minValue"]];
    [self setMaxValue:      [decoder decodeFloatForKey: @"maxValue"]];

    if(lowLimit < 0.001 && highLimit < 0.001 && minValue < 0.001 && maxValue < 0.001){
        lowLimit = 0;
        highLimit = 350;
        minValue = 0;
        maxValue = 350;
    }
    
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt:channel          forKey:@"channel"];
    [encoder encodeObject:label         forKey:@"label"];
    [encoder encodeInt:sensorType       forKey:@"sensorType"];
    [encoder encodeBool:autoRange       forKey:@"autoRange"];
    [encoder encodeInt:range            forKey:@"range"];
    [encoder encodeBool:compensation    forKey:@"compensation"];
    [encoder encodeInt:units            forKey:@"units"];
    [encoder encodeFloat:lowLimit       forKey:@"lowLimit"];
    [encoder encodeFloat:highLimit      forKey:@"highLimit"];
    [encoder encodeFloat:minValue       forKey:@"minValue"];
    [encoder encodeFloat:maxValue       forKey:@"maxValue"];
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
