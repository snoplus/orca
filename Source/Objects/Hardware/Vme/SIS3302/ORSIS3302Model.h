//-------------------------------------------------------------------------
//  ORSIS3302.h
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
#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "SBC_Config.h"
#import "AutoTesting.h"

@class ORRateGroup;
@class ORAlarm;

#define kNumSIS3302Channels			8 

@interface ORSIS3302Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping,AutoTesting>
{
  @private
    int				pageSize;
	BOOL			isRunning;
 	
 	
    BOOL			pageWrap;
    BOOL			gateChaining;
	
	//control status reg
    BOOL invertTrigger;
    BOOL activateTriggerOnArmed;
    BOOL enableInternalRouting;
    BOOL bankFullTo1;
    BOOL bankFullTo2;
    BOOL bankFullTo3;	
	
	//clocks and delays (Acquistion control reg)
	int	 clockSource;
	
	unsigned long   dataId;

	long			enabledMask;
	long			gtMask;
	NSMutableArray* thresholds;
	NSMutableArray* gateLengths;
	NSMutableArray* pulseLengths;
	NSMutableArray* sumGs;
	NSMutableArray* peakingTimes;
	NSMutableArray* internalTriggerDelays;
	NSMutableArray* triggerDecimations;
	
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumSIS3302Channels];

	//cach to speed takedata
	unsigned long location;
	id theController;
	int currentBank;
	unsigned long dataWord[4][16*1024];					
	long count;
    short acqRegEnableMask;
    short lemoOutMode;
    short lemoInMode;
    unsigned short dacOffset;
    unsigned short sampleLength;
    unsigned short sampleStartIndex;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (unsigned short) sampleStartIndex;
- (void) setSampleStartIndex:(unsigned short)aSampleStartIndex;
- (unsigned short) sampleLength;
- (void) setSampleLength:(unsigned short)aSampleLength;
- (unsigned short) dacOffset;
- (void) setDacOffset:(unsigned short)aDacOffset;
- (short) lemoInMode;
- (void) setLemoInMode:(short)aLemoInMode;
- (short) lemoOutMode;
- (void) setLemoOutMode:(short)aLemoOutMode;
- (short) acqRegEnableMask;
- (void) setAcqRegEnableMask:(short)aAcqRegEnableMask;
- (void) setDefaults;
- (BOOL) bankFullTo3;
- (void) setBankFullTo3:(BOOL)aBankFullTo3;
- (BOOL) bankFullTo2;
- (void) setBankFullTo2:(BOOL)aBankFullTo2;
- (BOOL) bankFullTo1;
- (void) setBankFullTo1:(BOOL)aBankFullTo1;
- (BOOL) enableInternalRouting;
- (void) setEnableInternalRouting:(BOOL)aEnableInternalRouting;
- (BOOL) activateTriggerOnArmed;
- (void) setActivateTriggerOnArmed:(BOOL)aActivateTriggerOnArmed;
- (BOOL) invertTrigger;
- (void) setInvertTrigger:(BOOL)aInvertTrigger;

//clocks and delays (Acquistion control reg)
- (int) clockSource;
- (void) setClockSource:(int)aClockSource;

//event configuration
- (BOOL) pageWrap;
- (void) setPageWrap:(BOOL)aPageWrap;
- (BOOL) gateChaining;
- (void) setGateChaining:(BOOL)aState;

- (int) pageSize;
- (void) setPageSize:(int)aPageSize;

- (long) enabledMask;
- (BOOL) enabled:(short)chan;
- (void) setEnabledMask:(long)aMask;
- (void) setEnabledBit:(short)chan withValue:(BOOL)aValue;

- (long) gtMask;
- (void) setGtMask:(long)aMask;
- (BOOL) gt:(short)chan;
- (void) setGtBit:(short)chan withValue:(BOOL)aValue;
- (short) peakingTime:(short)chan;
- (void) setPeakingTime:(short)chan withValue:(short)aValue;
- (short) internalTriggerDelay:(short)chan;
- (void) setInternalTriggerDelay:(short)chan withValue:(short)aValue;
- (short) triggerDecimation:(short)aChan;
- (void) setTriggerDecimation:(short)aChan withValue:(short)aValue;

- (void) setThreshold:(short)chan withValue:(int)aValue;
- (int) threshold:(short)chan;
- (void) setPulseLength:(short)aChan withValue:(short)aValue;
- (short) pulseLength:(short)chan;
- (void) setGateLength:(short)aChan withValue:(short)aValue;
- (short) gateLength:(short)chan;
- (void) setSumG:(short)aChan withValue:(short)aValue;
- (short) sumG:(short)chan;
- (short) peakingTime:(short)aChan;
- (void) setPeakingTime:(short)aChan withValue:(short)aValue;

- (void) initParams;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;

- (int) numberOfSamples;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Hardware Access
- (int) limitIntValue:(int)aValue min:(int)aMin max:(int)aMax;
- (void) initBoard;
- (void) readModuleID:(BOOL)verbose;
- (void) writeControlStatusRegister;
- (void) writeAcquistionRegister;
- (void) writeEventConfigurationRegister;
- (void) writeThresholds;
- (void) readThresholds:(BOOL)verbose;
- (void) setLed:(BOOL)state;
- (void) enableUserOut:(BOOL)state;
- (void) startSampling;
- (void) stopSampling;
- (void) startBankSwitching;
- (void) stopBankSwitching;
- (void) clearBankFullFlag:(int)whichFlag;
- (unsigned long) eventNumberGroup:(int)group bank:(int) bank;
- (void) writeTriggerClearValue:(unsigned long)aValue;
- (void) setMaxNumberEvents:(unsigned long)aValue;
- (unsigned long) eventTriggerGroup:(int)group bank:(int) bank;
- (unsigned long) readTriggerTime:(int)bank index:(int)index;

- (void) disArm:(int)bank;
- (void) arm:(int)bank;
- (BOOL) bankIsFull:(int)bank;
- (void) writeTriggerSetups;

//some test functions
- (unsigned long) readTriggerEventBank:(int)bank index:(int)index;
- (void) readAddressCounts;

- (int) dataWord:(int)chan index:(int)index;

- (unsigned long) acqReg;
- (unsigned long) configReg;
- (void) testMemory;
- (void) testEventRead;


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

#pragma mark ‚Ä¢‚Ä¢‚Ä¢AutoTesting
- (NSArray*) autoTests; 
@end

//CSRg
extern NSString* ORSIS3302SampleStartIndexChanged;
extern NSString* ORSIS3302SampleLengthChanged;
extern NSString* ORSIS3302DacOffsetChanged;
extern NSString* ORSIS3302LemoInModeChanged;
extern NSString* ORSIS3302LemoOutModeChanged;
extern NSString* ORSIS3302AcqRegEnableMaskChanged;

extern NSString* ORSIS3302CSRRegChanged;
extern NSString* ORSIS3302AcqRegChanged;
extern NSString* ORSIS3302EventConfigChanged;

extern NSString* ORSIS3302ClockSourceChanged;
extern NSString* ORSIS3302PageSizeChanged;
extern NSString* ORSIS3302EnabledChanged;
extern NSString* ORSIS3302ThresholdChanged;
extern NSString* ORSIS3302ThresholdArrayChanged;
extern NSString* ORSIS3302GtChanged;

extern NSString* ORSIS3302SettingsLock;
extern NSString* ORSIS3302RateGroupChangedNotification;
extern NSString* ORSIS3302SampleDone;
extern NSString* ORSIS3302IDChanged;
extern NSString* ORSIS3302GateLengthChanged;
extern NSString* ORSIS3302PulseLengthChanged;
extern NSString* ORSIS3302SumGChanged;
extern NSString* ORSIS3302PeakingTimeChanged;
extern NSString* ORSIS3302InternalTriggerDelayChanged;
extern NSString* ORSIS3302TriggerDecimationChanged;


