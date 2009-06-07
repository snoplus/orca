//
//  ORGateKey.h
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



#import "ORGateElement.h"

@interface ORGateKey : ORGateElement {
	unsigned long  lowAcceptValue;
	unsigned long highAcceptValue;
	BOOL acceptType;
}
+ (id) gateKey;

+ (id) gateKeyWithCrate:(unsigned short)aCrate 
                card:(unsigned short)aCard 
             channel:(unsigned short)aChannel 
            lowValue:(unsigned long)aLowValue
           highValue:(unsigned long)aHighValue
            acceptType:(gateAcceptType)anAcceptType;

- (id) initWithCrate:(unsigned short)aCrate 
                card:(unsigned short)aCard 
             channel:(unsigned short)aChannel 
            lowValue:(unsigned long)aLowValue
           highValue:(unsigned long)aHighValue
           acceptType:(gateAcceptType)anAcceptType;
           
- (unsigned long ) lowAcceptValue;
- (void) setLowAcceptValue:(unsigned long )aNewLowAcceptValue;
- (unsigned long) highAcceptValue;
- (void) setHighAcceptValue:(unsigned long)aNewHighAcceptValue;
- (BOOL) acceptType;
- (void) setAcceptType:(BOOL)aNewAcceptType;
- (BOOL) dataOpensGate:(NSData*)someData;

@end

extern NSString* ORGateLowValueChangedNotification;
extern NSString* ORGateHighValueChangedNotification;
extern NSString* ORGateAcceptTypeChangedNotification;

