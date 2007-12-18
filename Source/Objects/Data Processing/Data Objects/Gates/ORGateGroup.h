//
//  ORGateGroup.h
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



#import "ORBaseDecoder.h"

@class ORGate;
@class ORDataPacket;
@class ORDataSet;

typedef struct gateData {
    unsigned short crate;
    unsigned short card;
    unsigned short channel;
    unsigned short filler;
    unsigned long  value;
}gateData;


@interface ORGateGroup : NSObject <NSCoding> {
    NSMutableArray* dataGates;
    unsigned long dataId;
    NSMutableData* dataStore;
    unsigned long dataIndex;
}

#pragma mark ***Accessors
- (NSMutableData*) dataStore;
- (void) setDataStore:(NSMutableData*)aDataStore;

+ (id) gateGroup;
- (id) init;
- (NSUndoManager *)undoManager;

- (ORGate*) gateWithName:(NSString*)aName;

- (NSMutableArray *) dataGates;
- (void) setDataGates: (NSMutableArray *) aDataGates;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;

- (id) objectAtIndex:(int)i;
- (unsigned) count;

- (void) installGates:(id)obj;

- (void) newDataGate;
- (void) deleteGate:(ORGate*)aGate;
- (void) undeleteGate:(ORGate*)aGate;

- (void) addProcessFlag:(ORDataPacket*)aDataPacket;

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) encodeWithCoder: (NSCoder *)coder; 
- (id) initWithCoder: (NSCoder *)coder;
- (BOOL) prepareData:(ORDataSet*)aDataSet
               crate:(unsigned short)aCrate 
                card:(unsigned short)aCard 
             channel:(unsigned short)aChannel 
               value:(unsigned long)aValue;
- (void) processEventIntoDataSet:(ORDataSet*)aDataSet;

@end

@interface ORGateGroupDecoderForEvent : ORBaseDecoder 
{
    ORGateGroup* gateGroup;
}
- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end



extern NSString* ORGateArrayChangedNotification;

