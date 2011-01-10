//
//  OREHQ8060nModel.h
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORMPodCard.h";
#import "SBC_Config.h"

@class ORAlarm;

#define kNumEHQ8060nChannels 8

@interface OREHQ8060nModel : ORMPodCard
{
  @private
	unsigned long   dataId;
    short			voltage[kNumEHQ8060nChannels];
    float			current[kNumEHQ8060nChannels];
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark •••specific accessors
- (int) voltage:(short)chan;	
- (void) setVoltage:(short)chan withValue:(int)aValue;
- (float) current:(short)chan;	
- (void) setCurrent:(short)chan withValue:(float)aValue;

#pragma mark •••Hardware Access
- (void) writeVoltage:(int)channel;

#pragma mark •••Data Records
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cIntArray:(short*)anArray forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cFloatArray:(float*)anArray forKey:(NSString*)aKey;
@end

extern NSString* OREHQ8060nModelVoltageChanged;
extern NSString* OREHQ8060nModelCurrentChanged;
extern NSString* OREHQ8060nSettingsLock;
