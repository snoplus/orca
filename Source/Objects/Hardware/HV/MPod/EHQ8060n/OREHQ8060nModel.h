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

#import "ORMPodHVCard.h"
#import "SBC_Config.h"

@class ORAlarm;
@class TimedWorker;
@class ORTimeRate;

#define kNumEHQ8060nChannels   8
#define kMaxEHQ8060TrendValues 2000

enum {
	kEHQ8060nOutputOff				 = 0,
	kEHQ8060nOutputOn				 = 1,
	kEHQ8060nOutputResetEmergencyOff = 2,
	kEHQ8060nOutputSetEmergencyOff	 = 3,
	kEHQ8060nOutputClearEvents		 = 10,
};

enum {
	outputOnMask						= (0x1<<0), 
	outputInhibitMask					= (0x1<<1), 
	outputFailureMinSenseVoltageMask	= (0x1<<2),
	outputFailureMaxSenseVoltageMask	= (0x1<<3),
	
	outputFailureMaxTerminalVoltageMask = (0x1<<4),
	outputFailureMaxCurrentMask			= (0x1<<5),
	outputFailureMaxTemperatureMask		= (0x1<<6),
	outputFailureMaxPowerMask			= (0x1<<7),
	
	outputFailureTimeoutMask			= (0x1<<9),
	outputCurrentLimitedMask			= (0x1<<10), 
	outputRampUpMask					= (0x1<<11),
	outputRampDownMask					= (0x1<<12), 
	
	outputEnableKillMask				= (0x1<<13),
	outputEmergencyOffMask				= (0x1<<14)
};

@interface OREHQ8060nModel : ORMPodHVCard
{
  @private
	unsigned long   dataId;
    short			hwGoal[kNumEHQ8060nChannels];		//value to send to hw
    short			target[kNumEHQ8060nChannels];	//input by user
    float			riseRate;
	NSMutableDictionary* rdParams[kNumEHQ8060nChannels];
    int				selectedChannel;
    float			maxCurrent[kNumEHQ8060nChannels];
	
	ORTimeRate*		voltageHistory[kNumEHQ8060nChannels];
	ORTimeRate*		currentHistory[kNumEHQ8060nChannels];
    BOOL			shipRecords;
}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (BOOL)	shipRecords;
- (void)	setShipRecords:(BOOL)aShipRecords;
- (float)	maxCurrent:(short)chan;
- (void)	setMaxCurrent:(short)chan withValue:(float)aMaxCurrent;
- (int)		selectedChannel;
- (void)	setSelectedChannel:(int)aSelectedChannel;
- (int)		slotChannelValue:(int)aChannel;
- (int)		channel:(int)i readParamAsInt:(NSString*)name;
- (float)	channel:(int)i readParamAsFloat:(NSString*)name;
- (id)		channel:(int)i readParamAsObject:(NSString*)name;
- (id)		channel:(int)i readParamAsValue:(NSString*)name;
- (float)	riseRate;	
- (void)	setRiseRate:(float)aValue;
- (int)		hwGoal:(short)chan;	
- (void)	setHwGoal:(short)chan withValue:(int)aValue;
- (int)		target:(short)chan;	
- (void)	setTarget:(short)chan withValue:(int)aValue;
- (void)	syncDialog;
- (void)	commitTargetsToHwGoals;
- (void)	commitTargetToHwGoal:(int)channel;
- (NSString*) channelState:(int)channel;
- (int)		numberChannelsOn;
- (unsigned long) channelStateMask;
- (int)		numberChannelsRamping;
- (int)		numberChannelsWithNonZeroVoltage;
- (int)		numberChannelsWithNonZeroHwGoal;
- (unsigned long) failureEvents:(int)channel;
- (unsigned long) failureEvents;

#pragma mark •••Data Records
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;

#pragma mark ***Polling
- (void) updateAllValues;
- (NSArray*) channelUpdateList;
- (NSArray*) commonChannelUpdateList;
- (NSArray*) addChannelNumbersToParams:(NSArray*)someChannelParams;
- (NSArray*) addChannel:(int)i toParams:(NSArray*)someChannelParams;
- (void) processReadResponseArray:(NSArray*)response;
- (void) processSyncResponseArray:(NSArray*)response;
- (void) processWriteResponseArray:(NSArray*)response;

#pragma mark •••Hardware Access
- (void) loadValues:(int)channel;
- (void) writeVoltage:(int)channel;
- (void) writeVoltages;
- (void) writeMaxCurrents;
- (void) writeMaxCurrent:(int)channel;
- (void) writeSupervisorBehaviour:(int)channel value:(int)aValue; //test
- (void) writeRiseTime;
- (void) writeRiseTime:(float)aValue;
- (void) turnChannelOn:(int)channel;
- (void) turnChannelOff:(int)channel;
- (void) panicChannel:(int)channel;
- (void) clearPanicChannel:(int)channel;
- (void) clearEventsChannel:(int)channel;
- (void) stopRamping:(int)channel;
- (void) rampToZero:(int)channel;
- (void) panic:(int)channel;

- (void) loadAllValues;
- (void) turnAllChannelsOn;
- (void) turnAllChannelsOff;
- (void) panicAllChannels;
- (void) clearAllPanicChannels;
- (void) clearAllEventsChannels;
- (void) stopAllRamping;
- (void) rampAllToZero;
- (void) panicAll;

#pragma mark •••Trends
- (ORTimeRate*) voltageHistory:(int)index;
- (ORTimeRate*) currentHistory:(int)index;
- (void) shipDataRecords;


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cIntArray:(short*)anArray forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cFloatArray:(float*)anArray forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cBoolArray:(BOOL*)anArray forKey:(NSString*)aKey;
@end

extern NSString* OREHQ8060nModelShipRecordsChanged;
extern NSString* OREHQ8060nModelMaxCurrentChanged;
extern NSString* OREHQ8060nModelSelectedChannelChanged;
extern NSString* OREHQ8060nModelRiseRateChanged;
extern NSString* OREHQ8060nModelHwGoalChanged;
extern NSString* OREHQ8060nModelTargetChanged;
extern NSString* OREHQ8060nModelCurrentChanged;
extern NSString* OREHQ8060nSettingsLock;
extern NSString* OREHQ8060nModelOutputSwitchChanged;
extern NSString* OREHQ8060nModelChannelReadParamsChanged;
