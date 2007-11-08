//
//  ORGate.m
//  Orca
//
//  Created by Mark Howe on 1/21/05.
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


#import "ORGate.h"
#import "ORDataSet.h"
#import "ORGateKey.h"
#import "ORGatedValue.h"


NSString* ORGateIgnoreKeyChangedNotification = @"ORGateIgnoreKeyChangedNotification";
NSString* ORGateTwoDSizeChangedNotification = @"ORGateTwoDSizeChangedNotification";
NSString* ORGatePreScaleChangedNotification = @"ORGatePreScaleChangedNotification";
NSString* ORGateNameChangedNotification = @"ORGateNameChangedNotification";
NSString* ORGateTwoDChangedNotification = @"ORGateTwoDChangedNotification";

@implementation ORGate
+ (id) gateWithName:(NSString*)aName
{
    return [[[ORGate alloc] initWithName:aName] autorelease];
}

- (id) initWithName:(NSString*)aName
{
    self = [super init];
    gateOpen = NO;
    
    [[self undoManager] disableUndoRegistration];
    
    [self setGateName:aName];
    [self setGateKey:[ORGateKey gateKey]];
    [self setGatedValue:[ORGatedValue gatedValue]];
    [self setGatedValueY:[ORGatedValue gatedValue]];
    
    [gateKey setGate:self];
    [gatedValue setGate:self];
    [gatedValueY setGate:self];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void) dealloc
{
    [gateKey release];
    [gatedValue release];
    [gatedValueY release];
    [gateName release];
    
    [super dealloc];
}

- (NSUndoManager *)undoManager
{
    return [[NSApp delegate] undoManager];
}

#pragma mark ¥¥¥Accessors
- (BOOL) ignoreKey
{
	return ignoreKey;
}
- (void) setIgnoreKey:(BOOL)aIgnoreKey
{
	[[[self undoManager] prepareWithInvocationTarget:self] setIgnoreKey:ignoreKey];
    
	ignoreKey = aIgnoreKey;
    
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORGateIgnoreKeyChangedNotification
                      object:self];
}
- (unsigned short) twoDSize
{
	return twoDSize;
}
- (void) setTwoDSize:(unsigned short)aTwoDSize
{
    if(aTwoDSize == 0)aTwoDSize = 256;
    if(aTwoDSize > 1024)aTwoDSize = 1024;
    
	[[[self undoManager] prepareWithInvocationTarget:self] setTwoDSize:twoDSize];
    
	twoDSize = aTwoDSize;
    
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORGateTwoDSizeChangedNotification
                      object:self];
}
- (unsigned short) preScale
{
	return preScale;
}
- (void) setPreScale:(unsigned short)aPreScale
{
    if(aPreScale == 0)aPreScale = 1;
    
	[[[self undoManager] prepareWithInvocationTarget:self] setPreScale:preScale];
    
	preScale = aPreScale;
    
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORGatePreScaleChangedNotification
                      object:self];
}
- (BOOL) twoD
{
    return twoD; 
}
- (void) setTwoD:(BOOL)aTwoD
{
	[[[self undoManager] prepareWithInvocationTarget:self] setTwoD:twoD];
    twoD = aTwoD;
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORGateTwoDChangedNotification 
                          object: self];
}

- (NSString *) gateName
{
    return gateName; 
}

- (void) setGateName: (NSString *) aName
{
	[[[self undoManager] prepareWithInvocationTarget:self] setGateName:gateName];
    NSString* oldName = [[gateName copy]autorelease];
    [gateName release];
    gateName = [aName copy];
    
	if(oldName)[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORGateNameChangedNotification 
                          object: self 
                        userInfo: [NSDictionary dictionaryWithObject:oldName forKey:@"oldGateName"]];
}

- (ORGateKey *) gateKey;
{
    return gateKey; 
}

- (void) setGateKey: (ORGateKey *) aGateKey;
{
    [aGateKey retain];
    [gateKey release];
    gateKey = aGateKey;
}

- (ORGatedValue *) gatedValue;
{
    return gatedValue; 
}

- (void) setGatedValue: (ORGatedValue *) aGatedValue;
{
    [aGatedValue retain];
    [gatedValue release];
    gatedValue = aGatedValue;
}

- (ORGatedValue *) gatedValueY;
{
    return gatedValueY; 
}

- (void) setGatedValueY: (ORGatedValue *) aGatedValue;
{
    [aGatedValue retain];
    [gatedValueY release];
    gatedValueY = aGatedValue;
}


- (void) valueAccepted:(unsigned long)aValue gate:(ORGateElement*)aGateElement dataSet:(ORDataSet*)aDataSet
{
    if(!twoD){
        /* 1D */
        if(gateOpen && (aGateElement == gatedValue)){
            [aDataSet histogram:aValue numBins:4096  sender:self  withKeys:@"Gated Histograms",@"1D",gateName,nil];
        }
    }
    else {
        /* 2D */
        if((ignoreKey || gateOpen) && (aGateElement == gatedValue)){
            gotX = YES;
            xValue = aValue/preScale;
        }
        else if((ignoreKey || gateOpen) && (aGateElement == gatedValueY)){
            gotY = YES;
            yValue = aValue/preScale;
        }
        if(gotX && gotY){
            [aDataSet histogram2DX:xValue y:yValue size:twoDSize  sender:self  withKeys:@"Gated Histograms",@"2D",gateName,nil];
        }
    }
}


- (void) installGates:(id)obj
{
    if(!ignoreKey)[gateKey installGates:obj];
    [gatedValue installGates:obj];
    if(twoD)[gatedValueY installGates:obj];
}

- (void) processEvent:(NSData*)someData intoDataSet:(ORDataSet*)aDataSet
{
    gateOpen = NO;
    
    if(!twoD){
        if([gateKey dataOpensGate:someData]){
            gateOpen = YES;
        }
		[gatedValue processData:someData intoDataSet:aDataSet];
    }
    else {
        if(!ignoreKey){
            if([gateKey dataOpensGate:someData]){
                gateOpen = YES;
            }
        }
        gotX = NO;
        gotY = NO;
        [gatedValue processData:someData intoDataSet:aDataSet];
        [gatedValueY processData:someData intoDataSet:aDataSet];
    }
}


- (NSMutableDictionary*) captureCurrentState:(NSMutableDictionary*)dictionary
{
    ////Note....twoD part not included.....TBD.......
    
    NSMutableDictionary* gateDictionary = [NSMutableDictionary dictionary];
    gateDictionary = [gateKey captureCurrentState:gateDictionary];
    gateDictionary = [gatedValue captureCurrentState:gateDictionary];
    
    [dictionary setObject:gateDictionary forKey:gateName];
    
    return dictionary;
}


- (void) encodeWithCoder: (NSCoder *)coder 
{
    [coder encodeObject: gateKey forKey: @"gateKey"];
    [coder encodeBool:ignoreKey forKey:@"IgnoreKey"];
    [coder encodeInt: twoDSize forKey:@"TwoDSize"];
    [coder encodeInt: preScale forKey:@"PreScale"];
    [coder encodeObject: gatedValue forKey: @"gatedValue"];
    [coder encodeObject: gatedValueY forKey: @"gatedValueY"];
    [coder encodeObject: gateName forKey: @"gateName"];
    [coder encodeBool: twoD forKey: @"isTwoD"];
}

- (id) initWithCoder: (NSCoder *)coder 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setGateKey:[coder decodeObjectForKey: @"gateKey"]];
    [self setIgnoreKey:[coder decodeBoolForKey:@"IgnoreKey"]];
    [self setTwoDSize:[coder decodeIntForKey:@"TwoDSize"]];
    [self setPreScale:[coder decodeIntForKey:@"PreScale"]];
    [self setGatedValue:[coder decodeObjectForKey: @"gatedValue"]];
    [self setGatedValueY:[coder decodeObjectForKey: @"gatedValueY"]];
    [self setGateName:[coder decodeObjectForKey: @"gateName"]];
    [self setTwoD: [coder decodeBoolForKey: @"isTwoD"]];
    
    if(!gatedValueY){
        [self setGatedValueY:[ORGatedValue gatedValue]];
    }
    [gatedValueY setGate:self];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

@end
