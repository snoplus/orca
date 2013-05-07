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

NSString* ORLakeShore336InputSensorTypeChanged   = @"ORLakeShore336InputSensorTypeChanged";
NSString* ORLakeShore336InputAutoRangeChanged    = @"ORLakeShore336InputAutoRangeChanged";
NSString* ORLakeShore336InputRangeChanged        = @"ORLakeShore336InputRangeChanged";
NSString* ORLakeShore336InputCompensationChanged = @"ORLakeShore336InputCompensationChanged";
NSString* ORLakeShore336InputUnitsChanged        = @"ORLakeShore336InputUnitsChanged";
NSString* ORLakeShore336InputTemperatureChanged  = @"ORLakeShore336InputTemperatureChanged";

@implementation ORLakeShore336Input

@synthesize channel,temperature, sensorType, autoRange, range, compensation, units;

- (void) setTemperature:(int)aValue
{
    temperature = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336InputTemperatureChanged object:self];
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
    [self setSensorType:    [decoder decodeIntForKey:   @"sensorType"]];
	[self setAutoRange:     [decoder decodeBoolForKey:  @"autoRange"]];
    [self setRange:         [decoder decodeIntForKey:   @"range"]];
    [self setCompensation:  [decoder decodeBoolForKey:  @"compensation"]];
    [self setUnits:         [decoder decodeIntForKey:   @"units"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt:channel          forKey:@"channel"];
    [encoder encodeInt:sensorType       forKey:@"sensorType"];
    [encoder encodeBool:autoRange       forKey:@"autoRange"];
    [encoder encodeInt:range            forKey:@"range"];
    [encoder encodeBool:compensation    forKey:@"compensation"];
    [encoder encodeInt:units            forKey:@"units"];
}

@end
