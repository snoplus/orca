//-------------------------------------------------------------------------
//  ORSIS3300Model.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORVmeIOCard.h";
#import "ORDataTaker.h";
#import "ORHWWizard.h";
#import "SBC_Config.h"

@class ORRateGroup;
@class ORAlarm;

#define kNumSIS3300Channels			8 
#define kNumSIS3300CardParams		6

#define kSIS3300FIFOEmpty		0x800
#define kSIS3300FIFOAlmostEmpty 0x1000
#define kSIS3300FIFOHalfFull	0x2000
#define kSIS3300FIFOAllFull		0x4000

#pragma mark •••Register Definitions
enum {
	kControlStatus,				// []
	kAcquisitionControlReg,		// [] 
	kStartDelay,				// []
	kStopDelay,					// []
	kGeneralReset,				// []
	kStartSampling,				// []
	kStopSampling,				// []
	kNumberOfSIS3300Registers	//must be last
};

enum SIS3300FIFOStates {
	kEmpty,
	kAlmostEmpty,	
	kHalfFull,
	kFull,
	kSome
};

@interface ORSIS3300Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping>
{
  @private
    int				pageSize;
    int				clockSource;
    int				startDelay;
    int				stopDelay;
    BOOL			stopDelayEnabled;
    BOOL			startDelayEnabled;
    BOOL			randomClock;
	
    BOOL			gateMode;
    BOOL			lemoStartStop;
    BOOL			p2StartStop;
	
    BOOL			stopTrigger;
    BOOL			pageWrap;
    BOOL			multiEventMode;
    BOOL			autoStart;


	unsigned long   dataId;

	long			enabledMask;
	long			ltGtMask;
	NSMutableArray* thresholds;
	
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumSIS3300Channels];
	BOOL isRunning;

	//cach to speed takedata
	unsigned long location;
	id theController;
	unsigned long fifoAddress;
	unsigned long fifoStateAddress;

}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (BOOL) autoStart;
- (void) setAutoStart:(BOOL)aAutoStart;
- (BOOL) multiEventMode;
- (void) setMultiEventMode:(BOOL)aMultiEventMode;
- (BOOL) pageWrap;
- (void) setPageWrap:(BOOL)aPageWrap;
- (BOOL) stopTrigger;
- (void) setStopTrigger:(BOOL)aStopTrigger;
- (BOOL) p2StartStop;
- (void) setP2StartStop:(BOOL)aP2StartStop;
- (BOOL) lemoStartStop;
- (void) setLemoStartStop:(BOOL)aLemoStartStop;
- (BOOL) randomClock;
- (void) setRandomClock:(BOOL)aRandomClock;
- (BOOL) gateMode;
- (void) setGateMode:(BOOL)aGateMode;
- (BOOL) startDelayEnabled;
- (void) setStartDelayEnabled:(BOOL)aStartDelayEnabled;
- (BOOL) stopDelayEnabled;
- (void) setStopDelayEnabled:(BOOL)aStopDelayEnabled;
- (int) stopDelay;
- (void) setStopDelay:(int)aStopDelay;
- (int) startDelay;
- (void) setStartDelay:(int)aStartDelay;
- (int) clockSource;
- (void) setClockSource:(int)aClockSource;
- (int) pageSize;
- (void) setPageSize:(int)aPageSize;

- (long) enabledMask;
- (BOOL) enabled:(short)chan;
- (void) setEnabledMask:(long)aMask;
- (void) setEnabledBit:(short)chan withValue:(BOOL)aValue;

- (long) ltGtMask;
- (void) setLtGtMask:(long)aMask;
- (BOOL) ltGt:(short)chan;
- (void) setLtGtBit:(short)chan withValue:(BOOL)aValue;


- (void) setThreshold:(short)chan withValue:(int)aValue;
- (int) threshold:(short)chan;
- (NSMutableArray*) thresholds;
- (void) setThresholds:(NSMutableArray*)someThresholds;

- (void) initParams;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;


#pragma mark •••Hardware Access
- (void) initBoard;
- (void) writeControlStatusRegister;
- (void) writeAcquistionRegister;
- (void) writeEventConfigurationRegister;
- (void) writeThresholds;
- (void) writeStartDelay;
- (void) writeStopDelay;
- (void) enableUserOut:(BOOL)state;
- (void) strobeUserOut;
- (void) startSampling;
- (void) stopSampling;
- (unsigned long) eventNumber:(int) bank;
- (void) clearDaq;
- (void) disArm1;
- (void) disArm2;
- (void) arm1;
- (void) arm2;

#pragma mark •••Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (unsigned long) waveFormCount:(int)aChannel;
- (void)   startRates;
- (void) clearWaveFormCounts;
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

#pragma mark •••HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
@end

extern NSString* ORSIS3300ModelAutoStartChanged;
extern NSString* ORSIS3300ModelMultiEventModeChanged;
extern NSString* ORSIS3300ModelPageWrapChanged;
extern NSString* ORSIS3300ModelStopTriggerChanged;
extern NSString* ORSIS3300ModelP2StartStopChanged;
extern NSString* ORSIS3300ModelLemoStartStopChanged;
extern NSString* ORSIS3300ModelRandomClockChanged;
extern NSString* ORSIS3300ModelGateModeChanged;
extern NSString* ORSIS3300ModelStartDelayEnabledChanged;
extern NSString* ORSIS3300ModelStopDelayEnabledChanged;
extern NSString* ORSIS3300ModelStopDelayChanged;
extern NSString* ORSIS3300ModelStartDelayChanged;
extern NSString* ORSIS3300ModelClockSourceChanged;
extern NSString* ORSIS3300ModelPageSizeChanged;
extern NSString* ORSIS3300ModelEnabledChanged;
extern NSString* ORSIS3300ModelThresholdChanged;
extern NSString* ORSIS3300ModelThresholdArrayChanged;
extern NSString* ORSIS3300ModelLtGtChanged;

extern NSString* ORSIS3300SettingsLock;
extern NSString* ORSIS3300RateGroupChangedNotification;
