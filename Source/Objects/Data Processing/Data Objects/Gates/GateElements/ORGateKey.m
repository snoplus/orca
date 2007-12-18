//
//  ORGateKey.m
//  Orca
//
//  Created by Mark Howe on 1/24/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark ***Imported Files
#import "ORGateKey.h"
#import "ORGateGroup.h"

#pragma mark ***External Strings
NSString* ORGateLowValueChangedNotification  = @"ORGateLowValueChangedNotification";
NSString* ORGateHighValueChangedNotification = @"ORGateHighValueChangedNotification";
NSString* ORGateAcceptTypeChangedNotification= @"ORGateAcceptTypeChangedNotification";

@implementation ORGateKey

+ (id) gateKey
{
   ORGateKey* aGateKey = [[[ORGateKey alloc] initWithCrate:0 
                                                      card:0 
                                                   channel:0 
                                                  lowValue:0 
                                                 highValue:0
                                                 acceptType:kAcceptIfInGate] autorelease];
    return aGateKey;
}

+ (id) gateKeyWithCrate:(unsigned short)aCrate 
                card:(unsigned short)aCard 
             channel:(unsigned short)aChannel 
            lowValue:(unsigned long)aLowValue
           highValue:(unsigned long)aHighValue
            acceptType:(gateAcceptType)anAcceptType

{
    ORGateKey* aGateKey = [[[ORGateKey alloc] initWithCrate:aCrate 
                                                      card:aCard 
                                                   channel:aChannel 
                                                  lowValue:aLowValue 
                                                 highValue:aHighValue
                                                 acceptType:anAcceptType]autorelease];
    return aGateKey;
}

- (id) initWithCrate:(unsigned short)aCrate 
                card:(unsigned short)aCard 
             channel:(unsigned short)aChannel 
            lowValue:(unsigned long)aLowValue
           highValue:(unsigned long)aHighValue
           acceptType:(gateAcceptType)anAcceptType
{
    self = [super initWithCrate:aCrate card:aCard channel:aChannel];
    lowAcceptValue  = aLowValue;
    highAcceptValue = aHighValue;
    acceptType      = anAcceptType;
    return self;
}

- (id) viewControllerClassName
{
    return @"ORGateKeyView";
}

- (unsigned long ) lowAcceptValue
{
	return lowAcceptValue;
}
- (void) setLowAcceptValue:(unsigned long )aNewLowAcceptValue
{
	[[[self undoManager] prepareWithInvocationTarget:self] setLowAcceptValue:lowAcceptValue];

	lowAcceptValue = aNewLowAcceptValue;

	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORGateLowValueChangedNotification 
			object: self];
}

- (unsigned long) highAcceptValue
{
	return highAcceptValue;
}
- (void) setHighAcceptValue:(unsigned long)aNewHighAcceptValue
{
	[[[self undoManager] prepareWithInvocationTarget:self] setHighAcceptValue:highAcceptValue];

	highAcceptValue = aNewHighAcceptValue;

	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORGateHighValueChangedNotification 
			object: self];
}

- (BOOL) acceptType
{
	return acceptType;
}
- (void) setAcceptType:(BOOL)aNewAcceptType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setAcceptType:acceptType];

	acceptType = aNewAcceptType;

	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORGateAcceptTypeChangedNotification 
			object: self];
}



- (BOOL) dataOpensGate:(NSData*)someData
{
    gateData* theGateData = (gateData*)[someData bytes];
    gateData* end = (gateData*)([someData bytes] + [someData length]);
    while(theGateData<end) {
        if( (theGateData->crate == crateNumber) && (theGateData->card == card) && (theGateData->channel == channel)){
            long aValue = theGateData->value;
            if((aValue >= lowAcceptValue) && (aValue <= highAcceptValue)){
                if(acceptType == kAcceptIfInGate){
                    return YES;
                }
            }
            else if(acceptType == kAcceptIfOutsideGate){
                return YES;
            }
        }
        theGateData++;
    }
    return NO;
}



- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* gateDictionary = [NSMutableDictionary dictionary];
    gateDictionary = [super addParametersToDictionary:gateDictionary];
    
    [gateDictionary setObject:[NSNumber numberWithLong:lowAcceptValue] forKey:@"lowAcceptValue"];
    [gateDictionary setObject:[NSNumber numberWithLong:highAcceptValue] forKey:@"highAcceptValue"];
    
    [dictionary setObject:gateDictionary forKey:@"GateKey"];

    return dictionary;
}

#pragma mark ***Achival
- (void) encodeWithCoder: (NSCoder *)coder 
{
    [super encodeWithCoder:coder];
    [coder encodeInt: lowAcceptValue forKey: @"lowAcceptValue"];
    [coder encodeInt: highAcceptValue forKey:@"highAcceptValue"];
    [coder encodeInt: acceptType forKey:     @"acceptType"];
    
}

- (id) initWithCoder: (NSCoder *)coder 
{
    self = [super initWithCoder:coder];
    lowAcceptValue  = [coder decodeIntForKey: @"lowAcceptValue"];
    highAcceptValue = [coder decodeIntForKey: @"highAcceptValue"];
    acceptType      = [coder decodeIntForKey: @"acceptType"];
    return self;
}

@end
