//
//  ORTristanFLTModel.h
//  Orca
//
//  Created by Mark Howe on 1/23/18.
//  Copyright 2018, University of North Carolina. All rights reserved.
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


#pragma mark ***Imported Files
#import "ORIpeCard.h"
#import "ORHWWizard.h"
#import "ORDataTaker.h"
#import "SBC_Config.h"

#pragma mark ***Forward Definitions
@class ORDataPacket;
@class ORTimeRate;
@class ORRateGroup;

#define kNumTristanFLTChannels         8

@interface ORTristanFLTModel : ORIpeCard <ORDataTaker,ORHWWizard>
{
    unsigned short shapingLength;
    unsigned short gapLength;
    unsigned short postTriggerTime;
    ORTimeRate*     totalRate;
    BOOL            enabled[kNumTristanFLTChannels];
    unsigned long   threshold[kNumTristanFLTChannels];
    unsigned long   dataId;
    unsigned long   eventCount[kNumTristanFLTChannels];
  }

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) sleep;
- (void) wakeUp;
- (void) setUpImage;
- (void) makeMainController;
- (Class) guardianClass;
- (int) stationNumber;
- (ORTimeRate*) totalRate;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) runIsAboutToStop:(NSNotification*)aNote;
- (void) runIsAboutToChangeState:(NSNotification*)aNote;
- (void) reset;

#pragma mark ***Accessors
- (unsigned short) shapingLength;
- (void) setShapingLength:(unsigned short)aValue;
- (int) gapLength;
- (void) setGapLength:(int)aGapLength;
- (unsigned short) postTriggerTime;
- (void) setPostTriggerTime:(unsigned short)aPostTriggerTime;
-(BOOL) enabled:(unsigned short) aChan;
-(void) setEnabled:(unsigned short) aChan withValue:(BOOL) aState;
- (unsigned long) threshold:(unsigned short)aChan;
-(void) setThreshold:(unsigned short) aChan withValue:(unsigned long) aValue;
- (void) setTotalRate:(ORTimeRate*)newTimeRate;
- (void) setToDefaults;
- (void) initBoard;

#pragma mark ***HW Access
- (void) loadThresholds;

#pragma mark ***Data Taking
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) aDataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;
- (NSDictionary*) dataRecordDescription;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (BOOL) bumpRateFromDecodeStage:(short)channel;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

#pragma mark ***HW Wizard
- (BOOL) hasParmetersToRamp;
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

#pragma mark ***archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORTristanFLTModelEnabledChanged;
extern NSString* ORTristanFLTModelShapingLengthChanged;
extern NSString* ORTristanFLTModelGapLengthChanged;
extern NSString* ORTristanFLTModelThresholdsChanged;
extern NSString* ORTristanFLTModelPostTriggerTimeChanged;
extern NSString* ORTristanFLTModelFrameSizeChanged;
extern NSString* ORTristanFLTSettingsLock;

