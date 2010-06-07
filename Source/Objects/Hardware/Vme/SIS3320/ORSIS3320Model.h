//-------------------------------------------------------------------------
//  ORSIS3320Model.h
//
//  Created by Mark A. Howe on Thursday 8/6/09
//  Copyright (c) 2009 Universiy of North Carolina. All rights reserved.
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
#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "SBC_Config.h"
#import "AutoTesting.h"

@class ORRateGroup;
@class ORAlarm;

#define kNumSIS3320Channels			4 

#define kOperationRingBufferAsync 			0
#define kOperationRingBufferSync			1
#define kOperationDirectMemoryGateAsync		2
#define kOperationDirectMemoryGateSync		3
#define kOperationDirectMemoryStop			4
#define kOperationDirectMemoryStart			5

@interface ORSIS3320Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping,AutoTesting>
{
  @private
	BOOL			isRunning;
	BOOL			ledOn;
	unsigned short	moduleID;
	unsigned long   dataId;
	NSMutableArray*	triggerModes;
	NSMutableArray* gains;
	NSMutableArray* dacValues;
	NSMutableArray* thresholds;
	NSMutableArray* thresholdOffs;
	NSMutableArray* trigPulseLens;
	NSMutableArray* sumGs;
	NSMutableArray* peakingTimes;
	
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumSIS3320Channels];
    int				operationMode;
    int				clockSource;
    int				triggerMask;
    BOOL			multiEvent;
    BOOL			invertLemo;
    long			memoryTriggerDelay;
    long			memoryStartModeLength;
    int				freqM;
    int				freqN;
    long			maxNumEvents;
    int				gateSyncLimitLength;
    int				gateSyncExtendLength;
    int				ringBufferLen;
    int				ringBufferPreDelay;
    int				endAddressThreshold;
    long			memoryWrapLength;

	unsigned long	location;
	id				theController;
	int				runningOperationMode;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) setDefaults;

#pragma mark ***Accessors
- (long) memoryWrapLength;
- (void) setMemoryWrapLength:(long)aMemoryWrapLength;
- (int) endAddressThreshold;
- (void) setEndAddressThreshold:(int)aEndAddressThreshold;
- (int) ringBufferPreDelay;
- (void) setRingBufferPreDelay:(int)aRingBufferPreDelay;
- (int) ringBufferLen;
- (void) setRingBufferLen:(int)aRingBufferLen;
- (int) gateSyncExtendLength;
- (void) setGateSyncExtendLength:(int)aGateSyncExtendLength;
- (int) gateSyncLimitLength;
- (void) setGateSyncLimitLength:(int)aGateSyncLimitLength;
- (long) maxNumEvents;
- (void) setMaxNumEvents:(long)aMaxNumEvents;
- (int) freqN;
- (void) setFreqN:(int)aFreqN;;
- (int) freqM;
- (void) setFreqM:(int)aFreqM;;
- (long) memoryStartModeLength;
- (void) setMemoryStartModeLength:(long)aMemoryStartModeLength;
- (long) memoryTriggerDelay;
- (void) setMemoryTriggerDelay:(long)aMemoryTriggerDelay;
- (BOOL) invertLemo;
- (void) setInvertLemo:(BOOL)aInvertLemo;
- (BOOL) multiEvent;
- (void) setMultiEvent:(BOOL)aMultiEvent;
- (int) triggerMask;
- (void) setTriggerMask:(int)aTriggerMask;
- (int) clockSource;
- (void) setClockSource:(int)aClockSource;
- (NSString*) clockSourceName:(int)aValue;
- (int) operationMode;
- (void) setOperationMode:(int)aOperationMode;
- (NSString*) operationModeName:(int)aValue;
- (unsigned short) moduleID;


- (int) triggerMode:(short)chan;
- (void) setTriggerMode:(short)channel withValue:(long)aValue;

- (long) gain:(int)aChannel;
- (void) setGain:(int)aChannel withValue:(long)aValue;
- (long) dacValue:(int)aChannel;
- (void) setDacValue:(int)aChannel withValue:(long)aValue;

- (void) setThresholdOff:(short)chan withValue:(int)aValue;
- (int) thresholdOff:(short)chan;
- (void) setThreshold:(short)chan withValue:(int)aValue;
- (int) threshold:(short)chan;
- (int) trigPulseLen:(short)aChan;
- (void) setTrigPulseLen:(short)aChan withValue:(int)aValue;
- (int) sumG:(short)aChan;
- (void) setSumG:(short)aChan withValue:(int)aValue;
- (int) peakingTime:(short)aChan;
- (void) setPeakingTime:(short)aChan withValue:(int)aValue;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Hardware Access
- (void) printReport;
- (void) initBoard;
- (unsigned long) readEventCounter;
- (void) readModuleID:(BOOL)verbose;
- (float) readTemperature:(BOOL)verbose;
- (void) writeAcquisitionRegister;
- (unsigned long) readAcquisitionRegister;
- (void) writeControlStatusRegister;
- (void) writeValue:(unsigned long)aValue offset:(long)anOffset;
- (void) writeFreqSynthRegister;
- (void) writeTriggerSetupRegisters;
- (void) armSamplingLogic;
- (void) disarmSamplingLogic;
- (void) fireTrigger;
- (void) clearTimeStamps;
- (void) writeRingBufferParams;
- (unsigned long) readAcqRegister;
- (void) writeAdcMemoryPage:(unsigned long)aPage;
- (void) writeSampleStartAddress:(unsigned long)aValue;
- (void) clearTimeStamps;
- (void) writeGains;
- (void) writeDacOffsets;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Data Taker
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

#pragma mark ‚Ä¢‚Ä¢‚Ä¢HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
@end

extern NSString* ORSIS3320ModelMemoryWrapLengthChanged;
extern NSString* ORSIS3320ModelEndAddressThresholdChanged;
extern NSString* ORSIS3320ModelRingBufferPreDelayChanged;
extern NSString* ORSIS3320ModelRingBufferLenChanged;
extern NSString* ORSIS3320ModelGateSyncExtendLengthChanged;
extern NSString* ORSIS3320ModelGateSyncLimitLengthChanged;
extern NSString* ORSIS3320ModelMaxNumEventsChanged;
extern NSString* ORSIS3320ModelFreqNChanged;
extern NSString* ORSIS3320ModelFreqMChanged;
extern NSString* ORSIS3320ModelMemoryStartModeLengthChanged;
extern NSString* ORSIS3320ModelMemoryTriggerDelayChanged;
extern NSString* ORSIS3320ModelInvertLemoChanged;
extern NSString* ORSIS3320ModelMultiEventChanged;
extern NSString* ORSIS3320ModelTriggerMaskChanged;
extern NSString* ORSIS3320ModelClockSourceChanged;
extern NSString* ORSIS3320ModelOperationModeChanged;
extern NSString* ORSIS3320ModelTriggerModeChanged;
extern NSString* ORSIS3320ModelThresholdChanged;
extern NSString* ORSIS3320ModelThresholdOffChanged;
extern NSString* ORSIS3320ModelTrigPulseLenChanged;
extern NSString* ORSIS3320ModelSumGChanged;
extern NSString* ORSIS3320ModelPeakingTimeChanged;
extern NSString* ORSIS3320SettingsLock;
extern NSString* ORSIS3320RateGroupChangedNotification;
extern NSString* ORSIS3320ModelIDChanged;
extern NSString* ORSIS3320ModelGainChanged;
extern NSString* ORSIS3320ModelDacValueChanged;
