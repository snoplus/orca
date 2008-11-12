//
//  ORBaseDecoder.h
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

#import "ORDataTypeAssigner.h"

@class ORDataSet;
@class ORGateElement;

@interface ORBaseDecoder : NSObject {
    @protected 
        BOOL gatesInstalled;				//at least one gate installed.
        NSMutableArray* gates;
		NSMutableDictionary* cachedObjects;	//decoder can cache info here
}

- (NSString*) getChannelKey:(unsigned short)aChan;
- (NSString*) getCardKey:(unsigned short)aChan;
- (NSString*) getCrateKey:(unsigned short)aCrate;

- (void) addGate: (ORGateElement *) aGate;

- (BOOL) prepareData:(ORDataSet*)aDataSet 
                  crate:(unsigned short)aCrate 
                   card:(unsigned short)aCard 
                channel:(unsigned short)aChannel
                  value:(unsigned long)aValue;

- (void) swapData:(void*)someData;

- (void) registerNotifications;
- (void) runStarted:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;
- (id)   objectForNestedKey:(id)firstKey,...;				//nil terminated list of keys
- (void) setObject:(id)obj forNestedKey:(id)firstKey,...; //nil terminated list of keys
- (BOOL) cacheSetUp;
- (void) setUpCacheUsingHeader:(NSDictionary*)aHeader;
- (void) cacheCardLevelObject:(id)aKey fromHeader:(NSDictionary*)aHeader;

@end