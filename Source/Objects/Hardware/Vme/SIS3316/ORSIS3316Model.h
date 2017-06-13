//-------------------------------------------------------------------------
//  ORSIS3316Model.h
//  Orca
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2015 CENPA. University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolinaponsored in part by the United States
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
#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "SBC_Config.h"
#import "AutoTesting.h"

@class ORRateGroup;
@class ORAlarm;

#define kNumSIS3316Channels			16
#define kNumSIS3316Groups			4
#define kNumSIS3316ChansPerGroup	4

enum {
    kControlStatusReg,
    kModuleIDReg,
    kInterruptConfigReg ,
    kInterruptControlReg,
    kInterfacArbCntrStatusReg,
    kCBLTSetupReg,
    kInternalTestReg,
    kHWVersionReg,
    
    kNumberOfVMEFPGAInterfaceRegisters //must be last
};
enum {
    kTemperatureReg,
    k1WireEEPROMcontrolReg,
    kSerialNumberReg,
    kDataTransferSpdSettingReg,
    
    kAdcFPGAsBootControllerReg,
    kSpiFlashControlStatusReg,
    kSpiFlashData,
    kReservedforPROMReg,
    
    kAdcClockI2CReg,
    kMgt1ClockI2CReg,
    kMgt2ClockI2CReg,
    kDDR3ClockI2CReg,
    
    kAdcSampleClockDistReg,
    kExtNIMClockMulSpiReg,
    kFPBusControlReg,
    kNimInControlReg,
    
    kAcqControlStatusReg,
    kTrigCoinLUTControlReg,
    kTrigCoinLUTAddReg,
    kTrigCoinLUTDataReg,
    
    kLemoOutCOSelectReg,
    kLemoOutTOSelectReg,
    kLemoOutUOSelectReg,
    kIntTrigFeedBackSelReg,
    
    kAdcCh1_Ch4DataCntrReg,
    kAdcCh5_Ch8DataCntrReg,
    kAdcCh9_Ch12DataCntrReg,
    kAdcCh13_Ch16DataCntrReg,
    
    kAdcCh1_Ch4DataStatusReg,
    kAdcCh5_Ch8DataStatusReg,
    kAdcCh9_Ch12DataStatusReg,
    kAdcCh13_Ch16DataStatusReg,
    
    kAdcDataLinkStatusReg,
    kAdcSpiBusyStatusReg,
    kPrescalerOutDivReg,
    kPrescalerOutLenReg,
    
    kChan1TrigCounterReg,
    kChan2TrigCounterReg,
    kChan3TrigCounterReg,
    kChan4TrigCounterReg,
    
    kChan5TrigCounterReg,
    kChan6TrigCounterReg,
    kChan7TrigCounterReg,
    kChan8TrigCounterReg,
    
    kChan9TrigCounterReg,
    kChan10TrigCounterReg,
    kChan11TrigCounterReg,
    kChan12TrigCounterReg,
    
    kChan13TrigCounterReg,
    kChan14TrigCounterReg,
    kChan15TrigCounterReg,
    kChan16TrigCounterReg,
    
    kNumberOfVMEFPGARegisters
};

enum{
    
    kKeyResetReg,
    kKeyUserFuncReg,
    
    kKeyArmSampleLogicReg,
    kKeyDisarmSampleLogicReg,
    kKeyTriggerReg,
    kKeyTimeStampClrReg,
    
    kKeyDisarmXArmBank1Reg,
    kKeyDisarmXArmBank2Reg,
    kKeyEnableBankSwapNimReg,
    kKeyDisablePrescalerLogReg,
    
    kKeyPPSLatchBitClrReg,
    kKeyResetAdcLogicReg,
    kKeyAdcClockPllResetReg,
    
    kKeyAddressRegisters
};

enum{
    
    kAdcInputTapDelayReg,
    kAdcGainTermCntrlReg,
    kAdcOffsetDacCntrlReg,
    kAdcSpiControlReg,
    
    kEventConfigReg,
    kChanHeaderIdReg,
    kEndAddressThresholdReg,
    kActTriggerGateWindowLenReg,
    
    kRawDataBufferConfigReg,
    kPileupConfigReg,
    kPreTriggerDelayReg,
    kAveConfigReg,
    
    kDataFormatConfigReg,
    kMawTestBufferConfigReg,
    kInternalTrigDelayConfigReg,
    kInternalGateLenConfigReg,
    
    kFirTrigSetupCh1Reg,
    kTrigThresholdCh1Reg,
    kHiEnergyTrigThresCh1Reg,
    
    
    kFirTrigSetupCh2Reg,
    kTrigThresholdCh2Reg,
    kHiEnergyTrigThresCh2Reg,
    
    
    kFirTrigSetupCh3Reg,
    kTrigThresholdCh3Reg,
    kHiEnergyTrigThresCh3Reg,
    
    
    kFirTrigSetupCh4Reg,
    kTrigThresholdCh4Reg,
    kHiEnergyTrigThresCh4Reg,
    
    kFirTrigSetupSumCh1Ch4Reg,
    kTrigThreholdSumCh1Ch4Reg,
    kHiETrigThresSumCh1Ch4Reg,
    
    kTrigStatCounterModeCh1Ch4Reg,
    kPeakChargeConfigReg,
    kExtRawDataBufConfigReg,
    kExtEventConfigCh1Ch4Reg,
    
    kAccGate1ConfigReg,
    kAccGate2ConfigReg,
    kAccGate3ConfigReg,
    kAccGate4ConfigReg,
    
    kAccGate5ConfigReg,
    kAccGate6ConfigReg,
    kAccGate7ConfigReg,
    kAccGate8ConfigReg,
    
    kFirEnergySetupCh1Reg,
    kFirEnergySetupCh2Reg,
    kFirEnergySetupCh3Reg,
    kFirEnergySetupCh4Reg,
    
    kEnergyHistoConfigCh1Reg,
    kEnergyHistoConfigCh2Reg,
    kEnergyHistoConfigCh3Reg,
    kEnergyHistoConfigCh4Reg,
    
    kMawStartIndexConfigCh1Reg,
    kMawStartIndexConfigCh2Reg,
    kMawStartIndexConfigCh3Reg,
    kMawStartIndexConfigCh4Reg,
    
    kAdcVersionReg,
    kAdcVStatusReg,
    kAdcOffsetReadbackReg,
    kAdcSpiReadbackReg,
    
    kActualSampleCh1Reg,
    kActualSampleCh2Reg,
    kActualSampleCh3Reg,
    kActualSampleCh4Reg,
    
    kPreviousBankSampleCh1Reg,
    kPreviousBankSampleCh2Reg,
    kPreviousBankSampleCh3Reg,
    kPreviousBankSampleCh4Reg,
    
    kPPSTimeStampHiReg,
    kPPSTimeStampLoReg,
    kTestReadback01018Reg,
    kTestReadback0101CReg,
    
    
    kADCGroupRegisters
};

//section 6-




@interface ORSIS3316Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping,AutoTesting>
{
  @private
    unsigned long   dataId;
    long			enabledMask;
    long            histogramsEnabledMask;
    long			pileupEnabledMask;
    long            clrHistogramsWithTSMask;
    long            writeHitsToEventMemoryMask;
    long			heSuppressTriggerMask;
    unsigned long  cfdControlBits[kNumSIS3316Channels];
    unsigned long  threshold[kNumSIS3316Channels];
    unsigned short peakingTime[kNumSIS3316Channels];
    unsigned short gapTime[kNumSIS3316Channels];
    unsigned short tauFactor[kNumSIS3316Channels];
    unsigned long  heTrigThreshold[kNumSIS3316Channels];
    unsigned short intTrigOutPulseBit[kNumSIS3316Channels];
    long            trigBothEdgesMask;
    long            intHeTrigOutPulseMask;
    
    unsigned short  activeTrigGateWindowLen[kNumSIS3316Groups];
    unsigned short  preTriggerDelay[kNumSIS3316Groups];
    
    unsigned long  rawDataBufferLen[kNumSIS3316Groups];
    unsigned long  rawDataBufferStart[kNumSIS3316Groups];
    unsigned short energyDivider[kNumSIS3316Channels];
    unsigned short energySubtractor[kNumSIS3316Channels];

    unsigned short accGate1Len[kNumSIS3316Groups];
    unsigned short accGate1Start[kNumSIS3316Groups];
    unsigned short accGate2Len[kNumSIS3316Groups];
    unsigned short accGate2Start[kNumSIS3316Groups];
    unsigned short accGate3Len[kNumSIS3316Groups];
    unsigned short accGate3Start[kNumSIS3316Groups];
    unsigned short accGate4Len[kNumSIS3316Groups];
    unsigned short accGate4Start[kNumSIS3316Groups];
    unsigned short accGate5Len[kNumSIS3316Groups];
    unsigned short accGate5Start[kNumSIS3316Groups];
    unsigned short accGate6Len[kNumSIS3316Groups];
    unsigned short accGate6Start[kNumSIS3316Groups];
    unsigned short accGate7Len[kNumSIS3316Groups];
    unsigned short accGate7Start[kNumSIS3316Groups];
    unsigned short accGate8Len[kNumSIS3316Groups];
    unsigned short accGate8Start[kNumSIS3316Groups];
    

    
    int             currentBank;
    int				pageSize;
	BOOL			isRunning;
 	
    BOOL			stopTrigger;
    BOOL			pageWrap;
    BOOL			gateChaining;
	unsigned short	moduleID;
    unsigned long   clockSource;
	
	//control status reg
    BOOL enableTriggerOutput;
    BOOL invertTrigger;
    BOOL activateTriggerOnArmed;
    BOOL enableInternalRouting;
    BOOL bankFullTo1;
    BOOL bankFullTo2;
    BOOL bankFullTo3;	
	
	//Acquisition control reg
	BOOL bankSwitchMode;
    BOOL autoStart;
    BOOL multiEventMode;    //this is all with the commented out code
	BOOL lemoStartStop;
    BOOL p2StartStop;
    BOOL gateMode;
    BOOL multiplexerMode;

	//clocks and delays (Acquisition control reg)
    BOOL stopDelayEnabled;
    BOOL randomClock;
    
    int	 startDelay;
    int	 stopDelay;
	
	
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumSIS3316Channels];

	//cach to speed takedata
    unsigned long* dataRecord[4];
	unsigned long location;
	id theController;
	long count;
    BOOL firstTime;
    BOOL waitingForSomeChannels;
    NSString* revision;
    unsigned short majorRev;        //6.2
    unsigned short minorRev;        //6.2
    unsigned short hwVersion;       //6.7
    float temperature;              //6.8
    unsigned short serialNumber;     //6.10  
    //
    
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (void) setDefaults;
- (unsigned short) moduleID;
- (unsigned short) hwVersion;
- (float) temperature;
- (NSString*) revision;
- (void) setRevision:(NSString*)aString;
- (unsigned short) majorRevision;

- (long) enabledMask;
- (void) setEnabledMask:(long)aMask;
- (BOOL) enabled:(short)chan;
- (void) setEnabledBit:(short)chan withValue:(BOOL)aValue;

//////
- (long) histogramsEnabledMask;
- (void) setHistogramsEnabledMask:(long)aMask;
- (BOOL) histogramsEnabled:(short)chan;
- (void) setHistogramsEnabled:(short)chan withValue:(BOOL)aValue;

- (long) pileupEnabledMask;
- (void) setPileupEnabledMask:(long)aMask;
- (BOOL) pileupEnabled:(short)chan;
- (void) setPileupEnabled:(short)chan withValue:(BOOL)aValue;

- (long) clrHistogramsWithTSMask;
- (void) setClrHistogramsWithTSMask:(long)aMask;
- (BOOL) clrHistogramsWithTS:(short)chan;
- (void) setClrHistogramsWithTS:(short)chan withValue:(BOOL)aValue;

- (long) writeHitsToEventMemoryMask;
- (void) setWriteHitsToEventMemoryMask:(long)aMask;
- (BOOL) writeHitsToEventMemory:(short)chan;
- (void) setWriteHitsToEventMemory:(short)chan withValue:(BOOL)aValue;
///////

- (long) heSuppressTriggerMask;
- (BOOL) heSuppressTriggerMask:(short)chan;
- (void) setHeSuppressTriggerMask:(long)aMask;
- (void) setHeSuppressTriggerBit:(short)chan withValue:(BOOL)aValue;

- (void) setThreshold:(short)chan withValue:(long)aValue;
- (long) threshold:(short)chan;

- (short)cfdControlBits:(short)aChan;
- (void) setCfdControlBits:(short)aChan withValue:(short)aValue;

- (unsigned short) energyDivider:(short) aChan;
- (void) setEnergyDivider:(short)aChan withValue:(unsigned short)aValue;

- (unsigned short) energySubtractor:(short) aChan;
- (void) setEnergySubtractor:(short)aChan withValue:(unsigned short)aValue;

- (void) setTauFactor:(short)chan withValue:(unsigned short)aValue;
- (unsigned short) tauFactor:(short)chan;

- (void) setGapTime:(short)chan withValue:(unsigned short)aValue;
- (unsigned short) gapTime:(short)chan;

- (void) setPeakingTime:(short)chan withValue:(unsigned short)aValue;
- (unsigned short) peakingTime:(short)chan;

- (void) setHeTrigThreshold:(short)chan withValue:(unsigned long)aValue;
- (unsigned long) heTrigThreshold:(short)chan;

- (long) trigBothEdgesMask;
- (BOOL) trigBothEdgesMask:(short)chan;
- (void) setTrigBothEdgesMask:(long)aMask;
- (void) setTrigBothEdgesBit:(short)chan withValue:(BOOL)aValue;

- (long) intHeTrigOutPulseMask;
- (BOOL) intHeTrigOutPulseMask:(short)chan;
- (void) setIntHeTrigOutPulseMask:(long)aMask;
- (void) setIntHeTrigOutPulseBit:(short)chan withValue:(BOOL)aValue;

- (unsigned short) intTrigOutPulseBit:(short)aChan;
- (void) setIntTrigOutPulseBit:(short)aChan withValue:(unsigned short)aValue;

- (unsigned short) activeTrigGateWindowLen:(short)aGroup;
- (void) setActiveTrigGateWindowLen:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  preTriggerDelay:(short)aGroup;
- (void)            setPreTriggerDelay:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned long)  rawDataBufferLen:(short) aGroup;
- (void)            setRawDataBufferLen:(short)aGroup withValue:(unsigned long)aValue;

- (unsigned long)  rawDataBufferStart:(short) aGroup;
- (void)           setRawDataBufferStart:(short)aGroup withValue:(unsigned long)aValue;

- (unsigned short)  accGate1Start:(short) aGroup;
- (void)            setAccGate1Start:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate1Len:(short) aGroup;
- (void)            setAccGate1Len:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate2Start:(short) aGroup;
- (void)            setAccGate2Start:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate2Len:(short) aGroup;
- (void)            setAccGate2Len:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate3Start:(short) aGroup;
- (void)            setAccGate3Start:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate3Len:(short) aGroup;
- (void)            setAccGate3Len:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate4Start:(short) aGroup;
- (void)            setAccGate4Start:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate4Len:(short) aGroup;
- (void)            setAccGate4Len:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate5Start:(short) aGroup;
- (void)            setAccGate5Start:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate5Len:(short) aGroup;
- (void)            setAccGate5Len:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate6Start:(short) aGroup;
- (void)            setAccGate6Start:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate6Len:(short) aGroup;
- (void)            setAccGate6Len:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate7Start:(short) aGroup;
- (void)            setAccGate7Start:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate7Len:(short) aGroup;
- (void)            setAccGate7Len:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate8Start:(short) aGroup;
- (void)            setAccGate8Start:(short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate8Len:(short) aGroup;
- (void)            setAccGate8Len:(short)aGroup withValue:(unsigned short)aValue;

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
- (BOOL) enableTriggerOutput;
- (void) setEnableTriggerOutput:(BOOL)aEnableTriggerOutput;

//Acquisition control reg
- (BOOL) bankSwitchMode;
- (void) setBankSwitchMode:(BOOL)aBankSwitchMode;
- (BOOL) autoStart;
- (void) setAutoStart:(BOOL)aAutoStart;
- (BOOL) multiEventMode;
- (void) setMultiEventMode:(BOOL)aMultiEventMode;
- (BOOL) multiplexerMode;
- (void) setMultiplexerMode:(BOOL)aMultiplexerMode;
- (BOOL) lemoStartStop;
- (void) setLemoStartStop:(BOOL)aLemoStartStop;
- (BOOL) p2StartStop;
- (void) setP2StartStop:(BOOL)aP2StartStop;
- (BOOL) gateMode;
- (void) setGateMode:(BOOL)aGateMode;

//clocks and delays (Acquisition control reg)
- (BOOL) stopDelayEnabled;
- (void) setStopDelayEnabled:(BOOL)aStopDelayEnabled;
- (BOOL) randomClock;
- (void) setRandomClock:(BOOL)aRandomClock;



- (int) clockSource;
- (void) setClockSource:(int)aClockSource;

//event configuration
- (BOOL) pageWrap;
- (void) setPageWrap:(BOOL)aPageWrap;
- (BOOL) gateChaining;
- (void) setGateChaining:(BOOL)aState;


- (BOOL) stopTrigger;
- (void) setStopTrigger:(BOOL)aStopTrigger;
- (int) stopDelay;
- (void) setStopDelay:(int)aStopDelay;
- (int) startDelay;
- (void) setStartDelay:(int)aStartDelay;
- (int) pageSize;
- (void) setPageSize:(int)aPageSize;

- (void) initParams;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;

- (int) numberOfSamples;
- (BOOL) checkRegList;
- (unsigned short) serialNumber;

#pragma mark •••Hardware Access
//Comments denote section of the manual (or parts of that section ie. 6.1')
- (unsigned long) interfaceRegister:(unsigned long)aRegisterIndex;
- (unsigned long) vmeRegister:(unsigned long)aRegisterIndex;
-(unsigned long) keyRegister:(unsigned long)aRegisterIndex;
- (unsigned long) groupRegister:(unsigned long)aRegisterIndex  group:(int)aGroup;
- (unsigned long) channelRegister:(unsigned long)aRegisterIndex channel:(int)aChannel;

- (unsigned long)readControlStatusReg;          //6.1               (complete) -not connected  
- (void) writeControlStatusReg:(unsigned long)aValue;
        //6.1               (complete)
- (void) setLed:(BOOL)state;                    //6.1'              (complete)
- (void) readModuleID:(BOOL)verbose;            //6.2               (complete)
- (void) readHWVersion:(BOOL)verbose;           //6.7               (complete)
- (unsigned short) hwVersion;                   //6.7'              (complete)
- (void) readTemperature:(BOOL)verbose;         //6.8               (complete)
- (void) readSerialNumber:(BOOL)verbose;        //6.10              (complete)
- (void) writeClockSource;                      //6.17              (complete)
- (void) writeAcquisitionRegister;              //6.21              (incomplete. No read)
- (BOOL) sampleLogicIsBusy;                     //6.21      none of 21 is connected to the nib
//pg 119 and on
- (void) writeRawDataBufferConfig;              //6.17 (section 2)
- (void) writePreTriggerDelays;                 //6.19 (section 2)  (Missing read and caps at 4 bits (I think))
- (void) writeDataFormat;                       //6.21 (section 2)  (complete)
- (void) writeActiveTrigeGateWindowLens;        //6.24 (section 2)
- (void) writeFirTriggerSetup;                  //6.25 (section 2)
- (void) initBoard;
- (void) writeThresholds;                       //6.26 (section 2)  
- (void) readThresholds:(BOOL)verbose;          //6.26 (section 2)
- (void) writeHeTrigThresholds;                 //6.27 (section 2)
- (void) readHeTrigThresholds:(BOOL)verbose;    //6.27 (section 2)
- (void) writeAccumulatorGates;                 //6.31 (section 2)

- (void) writeHistogramConfiguration;           //6.33 (section 2)
- (void) configureAnalogRegisters;

- (unsigned long) eventNumberGroup:(int)group bank:(int) bank;  //6.12 or 6.13 (S2) ????
- (unsigned long) eventTriggerGroup:(int)group bank:(int) bank; //6.12 or 6.13 (S2) ????
- (unsigned long) readTriggerTime:(int)bank index:(int)index;


- (void) clearTimeStamp;
- (void) trigger;
- (void) disarmSampleLogic;
- (void) switchBanks;
- (void) armBank1;
- (void) armBank2;
- (void) resetADCClockDCM;
- (void) setClockChoice:(int) clck_choice;
- (int) setFrequency:(int) osc values:(unsigned char*)values;

//some test functions
- (unsigned long) readTriggerEventBank:(int)bank index:(int)index;
- (void) readAddressCounts;

//- (int) dataWord:(int)chan index:(int)index;

- (void) testMemory;
//- (void) testEventRead;


#pragma mark •••Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) reset;
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
- (void) setUpEmptyArray:(SEL)aSetter numItems:(int)n;
- (void) setUpArray:(SEL)aSetter intValue:(int)aValue numItems:(int)n;

#pragma mark •••AutoTesting
- (NSArray*) autoTests; 
@end

extern NSString* ORSIS3316EnabledChanged;
extern NSString* ORSIS3316HistogramsEnabledChanged;
extern NSString* ORSIS3316PileUpEnabledChanged;
extern NSString* ORSIS3316ClrHistogramWithTSChanged;
extern NSString* ORSIS3316WriteHitsIntoEventMemoryChanged;

extern NSString* ORSIS3316ThresholdChanged;
extern NSString* ORSIS3316HeSuppressTrigModeChanged;
extern NSString* ORSIS3316CfdControlBitsChanged;
extern NSString* ORSIS3316EnergyDividerChanged ;
extern NSString* ORSIS3316EnergySubtractorChanged;
extern NSString* ORSIS3316TauFactorChanged;
extern NSString* ORSIS3316GapTimeChanged;
extern NSString* ORSIS3316PeakingTimeChanged;
extern NSString* ORSIS3316HeTrigThresholdChanged;
extern NSString* ORSIS3316TrigBothEdgesChanged;
extern NSString* ORSIS3316IntHeTrigOutPulseChanged;
extern NSString* ORSIS3316IntTrigOutPulseBitsChanged;
extern NSString* ORSIS3316ActiveTrigGateWindowLenChanged;
extern NSString* ORSIS3316PreTriggerDelayChanged;
extern NSString* ORSIS3316RawDataBufferLenChanged;
extern NSString* ORSIS3316RawDataBufferStartChanged;
extern NSString* ORSIS3316AccGate1LenChanged;
extern NSString* ORSIS3316AccGate1StartChanged;
extern NSString* ORSIS3316AccGate2LenChanged;
extern NSString* ORSIS3316AccGate2StartChanged;
extern NSString* ORSIS3316AccGate3LenChanged;
extern NSString* ORSIS3316AccGate3StartChanged;
extern NSString* ORSIS3316AccGate4LenChanged;
extern NSString* ORSIS3316AccGate4StartChanged;
extern NSString* ORSIS3316AccGate5LenChanged;
extern NSString* ORSIS3316AccGate5StartChanged;
extern NSString* ORSIS3316AccGate6LenChanged;
extern NSString* ORSIS3316AccGate6StartChanged;
extern NSString* ORSIS3316AccGate7LenChanged;
extern NSString* ORSIS3316AccGate7StartChanged;
extern NSString* ORSIS3316AccGate8LenChanged;
extern NSString* ORSIS3316AccGate8StartChanged;
extern NSString* ORSIS3316TemperatureChanged;

//CSR
extern NSString* ORSIS3316CSRRegChanged;
extern NSString* ORSIS3316AcqRegChanged;
extern NSString* ORSIS3316EventConfigChanged;

extern NSString* ORSIS3316StopTriggerChanged;
extern NSString* ORSIS3316RandomClockChanged;
extern NSString* ORSIS3316StopDelayChanged;
extern NSString* ORSIS3316StartDelayChanged;
extern NSString* ORSIS3316ClockSourceChanged;
extern NSString* ORSIS3316PageSizeChanged;

extern NSString* ORSIS3316SettingsLock;
extern NSString* ORSIS3316RateGroupChangedNotification;
extern NSString* ORSIS3316SampleDone;
extern NSString* ORSIS3316IDChanged;
extern NSString* ORSIS3316HWVersionChanged;
extern NSString* ORSIS3316SerialNumberChanged;

