//
//  ORGate.h
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




@class ORDataSet;
@class ORGateKey;
@class ORGatedValue;
@class ORGateElement;

@interface ORGate : NSObject 
{
    @private
        NSString* gateName;
        BOOL gateOpen;
        ORGateKey* gateKey;
        ORGatedValue* gatedValue;
        ORGatedValue* gatedValueY;
        BOOL twoD;
        BOOL gotX;
        BOOL gotY;
        unsigned short xValue;
        unsigned short yValue;
        unsigned short preScale;
        unsigned short twoDSize;
	BOOL ignoreKey;
}

+ (id) gateWithName:(NSString*)aName;
- (id) initWithName:(NSString*)aName;
- (NSUndoManager *)undoManager;

#pragma mark ¥¥¥Accessors
- (BOOL) ignoreKey;
- (void) setIgnoreKey:(BOOL)aIgnoreKey;
- (unsigned short) twoDSize;
- (void) setTwoDSize:(unsigned short)aTwoDSize;
- (unsigned short) preScale;
- (void) setPreScale:(unsigned short)aPreScale;
- (BOOL) twoD;
- (void) setTwoD:(BOOL)aTwoD;
- (NSString *) gateName;
- (void) setGateName: (NSString *) aName;
- (ORGateKey *) gateKey;
- (void) setGateKey: (ORGateKey *) aGateKey;
- (ORGatedValue *) gatedValue;
- (void) setGatedValue: (ORGatedValue *) aGatedValue;
- (ORGatedValue *) gatedValueY;
- (void) setGatedValueY: (ORGatedValue *) aGatedValue;
- (void) valueAccepted:(unsigned long)aValue gate:(ORGateElement*)aGateElement dataSet:(ORDataSet*)aDataSet;
- (void) installGates:(id)obj;
- (NSMutableDictionary*) captureCurrentState:(NSMutableDictionary*)dictionary;
- (void) processEvent:(NSData*)someData intoDataSet:(ORDataSet*)aDataSet;


@end
extern NSString* ORGateNameChangedNotification;
extern NSString* ORGateTwoDChangedNotification;
extern NSString* ORGatePreScaleChangedNotification;
extern NSString* ORGateTwoDSizeChangedNotification;
extern NSString* ORGateIgnoreKeyChangedNotification;
