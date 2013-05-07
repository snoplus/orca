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

NSString* ORLakeShore336HeaterResistanceChanged       = @"ORLakeShore336HeaterResistanceChanged";
NSString* ORLakeShore336HeaterMaxCurrentChanged       = @"ORLakeShore336HeaterMaxCurrentChanged";
NSString* ORLakeShore336HeaterMaxUserCurrentChanged   = @"ORLakeShore336HeaterMaxUserCurrentChanged";
NSString* ORLakeShore336HeaterCurrentOrPowerChanged   = @"ORLakeShore336HeaterCurrentOrPowerChanged";

@implementation ORLakeShore336Heater

@synthesize resistance, maxCurrent, maxUserCurrent, currentOrPower;

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

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [self setResistance:        [decoder decodeIntForKey:   @"resistance"]];
	[self setMaxCurrent:        [decoder decodeBoolForKey:  @"maxCurrent"]];
    [self setMaxUserCurrent:    [decoder decodeIntForKey:   @"maxUserCurrent"]];
    [self setCurrentOrPower:    [decoder decodeBoolForKey:  @"currentOrPower"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt:resistance       forKey:@"resistance"];
    [encoder encodeBool:maxCurrent      forKey:@"maxCurrent"];
    [encoder encodeInt:maxUserCurrent   forKey:@"maxUserCurrent"];
    [encoder encodeBool:currentOrPower  forKey:@"currentOrPower"];
}

@end
