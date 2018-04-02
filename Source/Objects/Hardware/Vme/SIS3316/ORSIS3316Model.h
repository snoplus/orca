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
    
    kNumberSingleRegs //must be last
};

enum {
    
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
    
    kADCGroupRegisters //must be last
};

@interface ORSIS3316Model : ORVmeIOCard <ORDataTaker,ORHWWizard,AutoTesting>
{
  @private
    unsigned long   dataId;
    long			enabledMask;
    long            histogramsEnabledMask;
    long			pileupEnabledMask;
    long            acquisitionControlMask;
    long            nimControlStatusMask;
    long            clrHistogramsWithTSMask;
    long            writeHitsToEventMemoryMask;
    long			heSuppressTriggerMask;
    unsigned long   cfdControlBits[kNumSIS3316Channels];
    unsigned long   threshold[kNumSIS3316Channels];
    unsigned long   riseTime[kNumSIS3316Channels];
    unsigned long   gapTime[kNumSIS3316Channels];
    unsigned long   tauFactor[kNumSIS3316Channels];
    unsigned long   extraFilterBits[kNumSIS3316Channels];
    unsigned long   tauTableBits[kNumSIS3316Channels];
    unsigned long   heTrigThreshold[kNumSIS3316Channels];
    unsigned long   endAddress[kNumSIS3316Groups];
    unsigned short  intTrigOutPulseBit[kNumSIS3316Channels];
    unsigned short  triggerDelay[kNumSIS3316Channels];
    unsigned short  dacOffsets[kNumSIS3316Groups];
    long            trigBothEdgesMask;
    long            intHeTrigOutPulseMask;
    //long            heTrigOutputMask;
    
    
    unsigned long   eventConfigMask;
    BOOL            extendedEventConfigBit;
    unsigned long   endAddressSuppressionMask;
    unsigned short  activeTrigGateWindowLen[kNumSIS3316Groups];
    unsigned short  preTriggerDelay[kNumSIS3316Groups];
    
    unsigned long   rawDataBufferLen[kNumSIS3316Groups];
    unsigned long   rawDataBufferStart[kNumSIS3316Groups];
    unsigned short  energyDivider[kNumSIS3316Channels];
    unsigned short  energySubtractor[kNumSIS3316Channels];

    unsigned short  accumulatorGateStart[kNumSIS3316Groups];
    unsigned short  accumulatorGateLength[kNumSIS3316Groups];
    unsigned short  accGate1Len[kNumSIS3316Groups];
    unsigned short  accGate1Start[kNumSIS3316Groups];
    unsigned short  accGate2Len[kNumSIS3316Groups];
    unsigned short  accGate2Start[kNumSIS3316Groups];
    unsigned short  accGate3Len[kNumSIS3316Groups];
    unsigned short  accGate3Start[kNumSIS3316Groups];
    unsigned short  accGate4Len[kNumSIS3316Groups];
    unsigned short  accGate4Start[kNumSIS3316Groups];
    unsigned short  accGate5Len[kNumSIS3316Groups];
    unsigned short  accGate5Start[kNumSIS3316Groups];
    unsigned short  accGate6Len[kNumSIS3316Groups];
    unsigned short  accGate6Start[kNumSIS3316Groups];
    unsigned short  accGate7Len[kNumSIS3316Groups];
    unsigned short  accGate7Start[kNumSIS3316Groups];
    unsigned short  accGate8Len[kNumSIS3316Groups];
    unsigned short  accGate8Start[kNumSIS3316Groups];
    
    BOOL            enableSum[kNumSIS3316Groups];
    unsigned long   thresholdSum[kNumSIS3316Groups];
    unsigned long   heTrigThresholdSum[kNumSIS3316Groups];
    unsigned long   riseTimeSum[kNumSIS3316Groups];
    unsigned long   gapTimeSum[kNumSIS3316Groups];
    unsigned long   cfdControlBitsSum[kNumSIS3316Groups];


    
    int             currentBank;
    int				pageSize;
	BOOL			isRunning;
 	
    BOOL			stopTrigger;
    BOOL			pageWrap;
    //BOOL			gateChaining;
	unsigned short	moduleID;
    unsigned long   clockSource;
    unsigned short  gain;
    unsigned short  termination;
    int             sharing; //clock sharing
    
	//control status reg
 
	
	//Acquisition control reg
	BOOL bankSwitchMode;
    BOOL autoStart;
    BOOL multiEventMode;    //this is all with the commented out code
	BOOL lemoStartStop;
    BOOL p2StartStop;
    BOOL gateMode;
    BOOL multiplexerMode;

	//clocks and delays (Acquisition control reg)
    BOOL randomClock;
	
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumSIS3316Channels];

	
	unsigned long location; //cach to speed takedata
	id theController;       //cach to speed takedata
    unsigned short waitingOnChannelMask;
    unsigned short groupDataTransferedMask;

    NSString* revision;
    unsigned short  majorRev;
    unsigned short  minorRev;
    unsigned short  hwVersion;
    float           temperature;
    unsigned short  serialNumber;
    unsigned long   lemoCoMask;
    unsigned long   lemoUoMask;
    unsigned long   lemoToMask;
    unsigned long   internalGateLen[kNumSIS3316Groups];       //6.24
    unsigned long   internalCoinGateLen[kNumSIS3316Groups];   //6.24
    unsigned long  dataBuffer[4096];
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
- (unsigned short) gain;
- (void) setGain:(unsigned short)aGain;
- (unsigned short) termination;
- (void) setTermination:(unsigned short)aTermination;
- (void) setSharing:(int)aValue;
- (int) sharing;

//- (float) clockSource;
- (NSString*) revision;
- (void) setRevision:(NSString*)aString;
- (unsigned short) majorRevision;

- (long) enabledMask;
- (unsigned long) eventConfigMask;

- (void) setEventConfigMask:(unsigned long)aMask;
- (void) setEventConfigBit:(unsigned short)bit withValue:(BOOL)aValue;

- (BOOL) extendedEventConfigBit;
- (void) setExtendedEventConfigBit:(BOOL)aValue;

- (unsigned long) endAddressSuppressionMask;
- (void) setEndAddressSuppressionMask:(unsigned long)aMask;
- (void) setEndAddressSuppressionBit:(unsigned short)aGroup withValue:(BOOL)aValue;

- (void) setEnabledMask:(unsigned long)aMask;
- (BOOL) enabled:(unsigned short)chan;
- (void) setEnabledBit:(unsigned short)chan withValue:(BOOL)aValue;
///////
- (long) acquisitionControlMask;
- (void) setAcquisitionControlMask:(unsigned long)aMask;
//////
- (long) nimControlStatusMask;
- (void) setNIMControlStatusMask:(unsigned long)aMask;
- (void) setNIMControlStatusBit:(unsigned long)aChan withValue:(BOOL)aValue;
//////
- (long) histogramsEnabledMask;
- (void) setHistogramsEnabledMask:(unsigned long)aMask;
- (BOOL) histogramsEnabled:(unsigned short)chan;
- (void) setHistogramsEnabled:(unsigned short)chan withValue:(BOOL)aValue;

- (long) pileupEnabledMask;
- (void) setPileupEnabledMask:(unsigned long)aMask;
- (BOOL) pileupEnabled:(unsigned short)chan;
- (void) setPileupEnabled:(unsigned short)chan withValue:(BOOL)aValue;

- (long) clrHistogramsWithTSMask;
- (void) setClrHistogramsWithTSMask:(unsigned long)aMask;
- (BOOL) clrHistogramsWithTS:(unsigned short)chan;
- (void) setClrHistogramsWithTS:(unsigned short)chan withValue:(BOOL)aValue;

- (long) writeHitsToEventMemoryMask;
- (void) setWriteHitsToEventMemoryMask:(unsigned long)aMask;
- (BOOL) writeHitsToEventMemory:(unsigned short)chan;
- (void) setWriteHitsToEventMemory:(unsigned short)chan withValue:(BOOL)aValue;
///////
- (void) setTriggerDelay:(unsigned short)aChan withValue: (unsigned short)aValue;
- (unsigned short) triggerDelay: (unsigned short)aChan;

- (long) heSuppressTriggerMask;
- (void) setHeSuppressTriggerMask:(unsigned long)aMask;
- (BOOL) heSuppressTriggerBit:(unsigned short)chan;
- (void) setHeSuppressTriggerBit:(unsigned short)chan withValue:(BOOL)aValue;

- (void) setEndAddress:(unsigned short)aGroup withValue: (unsigned long)aValue;
- (unsigned long) endAddress: (unsigned short)aGroup;

- (void) setThreshold:(unsigned short)chan withValue:(long)aValue;
- (long) threshold:(unsigned short)chan;

- (unsigned short) cfdControlBits:(unsigned short)aChan;
- (void) setCfdControlBits:(unsigned short)aChan withValue:(unsigned short)aValue;


- (BOOL) enableSum:(unsigned short)aGroup;
- (void) setEnableSum:(unsigned short)aGroup withValue:(BOOL)aValue;

- (unsigned long) riseTimeSum:(unsigned short)aGroup;
- (void)          setRiseTimeSum:(unsigned short)aGroup withValue:(unsigned short)aValue;

- (unsigned long) gapTimeSum:(unsigned short)aGroup;
- (void)          setGapTimeSum:(unsigned short)aGroup withValue:(unsigned short)aValue;

- (void) setThresholdSum:(unsigned short)aGroup withValue: (unsigned long)aValue;
- (unsigned long) thresholdSum: (unsigned short)aGroup;

- (unsigned short) dacOffset:(unsigned short)aGroup;
- (void) setDacOffset:(unsigned short)aGroup withValue:(int)aValue;

- (unsigned short) cfdControlBitsSum:(unsigned short)aChan;
- (void) setCfdControlBitsSum:(unsigned short)aChan withValue:(unsigned short)aValue;

- (long)clockSource;
- (void) setClockSource:(long)aValue;

- (long)extraFilterBits:(unsigned short)aChan;
- (void) setExtraFilterBits:(unsigned short)aChan withValue:(long)aValue;

- (long)tauTableBits:(unsigned short)aChan;
- (void) setTauTableBits:(unsigned short)aChan withValue:(long)aValue;

- (unsigned short) energyDivider:(unsigned short)aChan;
- (void) setEnergyDivider:(unsigned short)aChan withValue:(unsigned short)aValue;

- (unsigned short) energySubtractor:(unsigned short)aChan;
- (void) setEnergySubtractor:(unsigned short)aChan withValue:(unsigned short)aValue;

- (void) setTauFactor:(unsigned short)chan withValue:(unsigned short)aValue;
- (unsigned short) tauFactor:(unsigned short)chan;

- (void) setGapTime:(unsigned short)chan withValue:(unsigned short)aValue;
- (unsigned short) gapTime:(unsigned short)chan;

- (void) setRiseTime:(unsigned short)chan withValue:(unsigned short)aValue;
- (unsigned short) riseTime:(unsigned short)chan;

- (void) setHeTrigThreshold:(unsigned short)chan withValue:(unsigned long)aValue;
- (unsigned long) heTrigThresholdSum:(unsigned short)aGroup;

- (void) setHeTrigThresholdSum:(unsigned short)aGroup withValue:(unsigned long)aValue;
- (unsigned long) heTrigThreshold:(unsigned short)chan;

- (long) trigBothEdgesMask;
- (void) setTrigBothEdgesMask:(unsigned long)aMask;
- (BOOL) trigBothEdgesBit:(unsigned short)chan;
- (void) setTrigBothEdgesBit:(unsigned short)chan withValue:(BOOL)aValue;

- (long) intHeTrigOutPulseMask;
- (void) setIntHeTrigOutPulseMask:(unsigned long)aMask;
- (BOOL) intHeTrigOutPulseBit:(unsigned short)chan;
- (void) setIntHeTrigOutPulseBit:(unsigned short)chan withValue:(BOOL)aValue;

- (unsigned short) intTrigOutPulseBit:(unsigned short)aChan;
- (void)           setIntTrigOutPulseBit:(unsigned short)aChan withValue:(unsigned short)aValue;

- (unsigned short) activeTrigGateWindowLen:(unsigned short)group;
- (void)           setActiveTrigGateWindowLen:(unsigned short)group withValue:(unsigned long)aValue;

- (unsigned short)  preTriggerDelay:(unsigned short)group;
- (void)            setPreTriggerDelay:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned long)  rawDataBufferLen:(unsigned short)aGroup;
- (void)            setRawDataBufferLen:(unsigned short)group withValue:(unsigned long)aValue;

- (unsigned long)  rawDataBufferStart:(unsigned short)aGroup;
- (void)           setRawDataBufferStart:(unsigned short)group withValue:(unsigned long)aValue;

- (unsigned short)  accumulatorGateStart:(unsigned short)aGroup;
- (void)            setAccumulatorGateStart:(unsigned short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accumulatorGateLength:(unsigned short)aGroup;
- (void)            setAccumulatorGateLength:(unsigned short)aGroup withValue:(unsigned short)aValue;

- (unsigned short)  accGate1Start:(unsigned short)aGroup;
- (void)            setAccGate1Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate1Len:(unsigned short)aGroup;
- (void)            setAccGate1Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate2Start:(unsigned short)aGroup;
- (void)            setAccGate2Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate2Len:(unsigned short)aGroup;
- (void)            setAccGate2Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate3Start:(unsigned short)aGroup;
- (void)            setAccGate3Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate3Len:(unsigned short)aGroup;
- (void)            setAccGate3Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate4Start:(unsigned short)aGroup;
- (void)            setAccGate4Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate4Len:(unsigned short)aGroup;
- (void)            setAccGate4Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate5Start:(unsigned short)aGroup;
- (void)            setAccGate5Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate5Len:(unsigned short)aGroup;
- (void)            setAccGate5Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate6Start:(unsigned short)aGroup;
- (void)            setAccGate6Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate6Len:(unsigned short)aGroup;
- (void)            setAccGate6Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate7Start:(unsigned short)aGroup;
- (void)            setAccGate7Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate7Len:(unsigned short)aGroup;
- (void)            setAccGate7Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate8Start:(unsigned short)aGroup;
- (void)            setAccGate8Start:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned short)  accGate8Len:(unsigned short)aGroup;
- (void)            setAccGate8Len:(unsigned short)group withValue:(unsigned short)aValue;

- (unsigned long)   lemoCoMask;
- (void)            setLemoCoMask:(unsigned long)aMask;
- (unsigned long)   lemoUoMask;
- (void)            setLemoUoMask:(unsigned long)aMask;
- (unsigned long)   lemoToMask;
- (void)             setLemoToMask:(unsigned long)aMask;

- (unsigned long) internalGateLen:(unsigned short)aGroup;
- (void) setInternalGateLen:(unsigned short)aGroup withValue:(unsigned long)aValue;

- (unsigned long) internalCoinGateLen:(unsigned short)aGroup;
- (void) setInternalCoinGateLen:(unsigned short)aGroup withValue:(unsigned long)aValue;


//Acquisition control reg
//- (BOOL) bankSwitchMode;
//- (void) setBankSwitchMode:(BOOL)aBankSwitchMode;
//- (BOOL) autoStart;
//- (void) setAutoStart:(BOOL)aAutoStart;
//- (BOOL) multiEventMode;
//- (void) setMultiEventMode:(BOOL)aMultiEventMode;
//- (BOOL) multiplexerMode;
//- (void) setMultiplexerMode:(BOOL)aMultiplexerMode;
//- (BOOL) lemoStartStop;
//- (void) setLemoStartStop:(BOOL)aLemoStartStop;
//- (BOOL) p2StartStop;
//- (void) setP2StartStop:(BOOL)aP2StartStop;
//- (BOOL) gateMode;
//- (void) setGateMode:(BOOL)aGateMode;

//clocks and delays (Acquisition control reg)
//- (BOOL) stopDelayEnabled;
//- (void) setStopDelayEnabled:(BOOL)aStopDelayEnabled;
- (BOOL) randomClock;
- (void) setRandomClock:(BOOL)aRandomClock;



//-=**- (int) clockSource;
//-=**- (void) setClockSource:(int)aClockSource;

//event configuration
//- (BOOL) gateChaining;
//- (void) setGateChaining:(BOOL)aState;


- (BOOL) stopTrigger;
- (void) setStopTrigger:(BOOL)aStopTrigger;
//- (int) stopDelay;
//- (void) setStopDelay:(int)aStopDelay;
//- (int) startDelay;
//- (void) setStartDelay:(int)aStartDelay;
- (int) pageSize;
- (void) setPageSize:(int)aPageSize;

- (void) initParams;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(unsigned short)channel;

- (int) numberOfSamples;
- (BOOL) checkRegList;
- (unsigned short) serialNumber;

#pragma mark •••Hardware Access
- (void) writeLong:(unsigned long)aValue toAddress:(unsigned long)anAddress;
- (unsigned long) readLongFromAddress:(unsigned long)anAddress;

//Comments denote section of the manual 
- (unsigned long) singleRegister:(unsigned long)aRegisterIndex;
- (unsigned long) groupRegister:(unsigned long)aRegisterIndex  group:(int)aGroup;
- (unsigned long) channelRegister:(unsigned long)aRegisterIndex channel:(int)aChannel;
- (unsigned long) channelRegisterVersionTwo:(unsigned long)aRegisterIndex channel:(int)aChannel;
- (unsigned long) accumulatorRegisters:(unsigned long)aRegisterIndex channel:(int)aChannel;
- (unsigned long)readControlStatusReg;          //6.1               (complete) -not connected  
- (void) writeControlStatusReg:(unsigned long)aValue;
        //6.1               (complete)
- (void) setLed:(BOOL)state;                    //6.1'
- (void) readModuleID:(BOOL)verbose;            //6.2
- (void) readHWVersion:(BOOL)verbose;           //6.7
- (unsigned short) hwVersion;                   //6.7'
- (void) readTemperature:(BOOL)verbose;         //6.8
- (void) readSerialNumber:(BOOL)verbose;        //6.10
- (void) writeClockSource;                      //6.17
- (void) readClockSource:(BOOL)verbose;
- (void) writeNIMControlStatus;                 //6.20
- (void) readNIMControlStatus:(BOOL)verbose;
- (void) writeAcquisitionRegister;              //6.21
- (unsigned long) readAcquisitionRegister:(BOOL)verbose;
- (BOOL) sampleLogicIsBusy;                     //6.21      //pg 119 and on
- (void) writeEventConfig;                      //6.12 (section 2)
- (void) readEventConfig:(BOOL)verbose;
- (void) writeExtendedEventConfig;              //6.13 (section 2)
- (void) readExtendedEventConfig:(BOOL)verbose;
- (void) writeEndAddress;                       //6.15 (section 2)
- (void) readEndAddress:(BOOL)verbose;
- (void) writeActiveTrigGateWindowLen;          //6.16 (section 2)
- (void) readActiveTrigGateWindowLen:(BOOL)verbose;
- (void) writeRawDataBufferConfig;              //6.17 (section 2)
- (void) readRawDataBufferConfig:(BOOL)verbose;
- (void) writePreTriggerDelays;                 //6.19 (section 2)
- (void) readPreTriggerDelays:(BOOL)verbose;
- (void) writeDataFormat;                       //6.21 (section 2)
- (void) writeTriggerDelay;                     //6.23 (section 2)
- (void) readTriggerDelay:(BOOL)verbose;
- (void) writeFirTriggerSetup;                  //6.25 (section 2)
- (void) initBoard;
- (void) writeThresholds;                       //6.26 (section 2)
- (void) writeThresholdSum;
- (void) readThresholds:(BOOL)verbose;          //6.26 (section 2)
- (void) readThresholdSum: (BOOL)verbose;
- (void) writeHeTrigThresholds;                 //6.27 (section 2)
- (void) writeHeTrigThresholdSum;
- (void) readHeTrigThresholds:(BOOL)verbose;    //6.27 (section 2)
- (void) readHeTrigThresholdSum:(BOOL)verbose;
- (void) writeAccumulatorGates;                 //6.31 (section 2)
- (void) readAccumulatorGates:(BOOL)verbose;
- (void) writeFirEnergySetup;                   //6.32 (section 2)
- (void) readFirEnergySetup:(BOOL)verbose;
- (void) writeHistogramConfiguration;           //6.33 (section 2)
- (void) readHistogramConfiguration:(BOOL)verbose;
- (void) writeGainAndTermination;               //6.7
- (void) configureAnalogRegisters;

- (unsigned long) eventNumberGroup:(int)group bank:(int) bank;
- (unsigned long) eventTriggerGroup:(int)group bank:(int) bank; 
- (unsigned long) readTriggerTime:(int)bank index:(int)index;


- (void) clearTimeStamp;
- (void) trigger;
- (void) armSampleLogic;
- (void) disarmSampleLogic;
- (void) switchBanks;
- (void) armBank1;
- (void) armBank2;
- (int) currentBank;
- (void) resetADCClockDCM;
- (void) setClockChoice:(int) clck_choice;
- (int) setFrequency:(int) osc values:(unsigned char*)values;

//some test functions
- (unsigned long) readTriggerEventBank:(int)bank index:(int)index;
- (void) readAddressCounts;

//- (int) dataWord:(int)chan index:(int)index;
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

#pragma mark •••Reporting
- (void) settingsTable;

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
extern NSString* ORSIS3316EventConfigChanged;
extern NSString* ORSIS3316ExtendedEventConfigChanged;
extern NSString* ORSIS3316AcquisitionControlChanged;
extern NSString* ORSIS3316NIMControlStatusChanged;
extern NSString* ORSIS3316HistogramsEnabledChanged;
extern NSString* ORSIS3316PileUpEnabledChanged;
extern NSString* ORSIS3316ClrHistogramWithTSChanged;
extern NSString* ORSIS3316WriteHitsIntoEventMemoryChanged;

extern NSString* ORSIS3316ThresholdChanged;
extern NSString* ORSIS3316ThresholdSumChanged;
extern NSString* ORSIS3316EndAddressSuppressionChanged;
extern NSString* ORSIS3316EndAddressChanged;
extern NSString* ORSIS3316TriggerDelayChanged;
extern NSString* ORSIS3316HeSuppressTrigModeChanged;
extern NSString* ORSIS3316CfdControlBitsChanged;
extern NSString* ORSIS3316ExtraFilterBitsChanged;
extern NSString* ORSIS3316TauTableBitsChanged;
extern NSString* ORSIS3316EnergyDividerChanged ;
extern NSString* ORSIS3316EnergySubtractorChanged;
extern NSString* ORSIS3316TauFactorChanged;
extern NSString* ORSIS3316GapTimeChanged;
extern NSString* ORSIS3316PeakingTimeChanged;
extern NSString* ORSIS3316HeTrigThresholdChanged;
extern NSString* ORSIS3316HeTrigThresholdSumChanged;
extern NSString* ORSIS3316TrigBothEdgesChanged;
extern NSString* ORSIS3316IntHeTrigOutPulseChanged;
extern NSString* ORSIS3316IntTrigOutPulseBitsChanged;
extern NSString* ORSIS3316ActiveTrigGateWindowLenChanged;
extern NSString* ORSIS3316PreTriggerDelayChanged;
extern NSString* ORSIS3316RawDataBufferLenChanged;
extern NSString* ORSIS3316RawDataBufferStartChanged;
extern NSString* ORSIS3316AccumulatorGateStartChanged;
extern NSString* ORSIS3316AccumulatorGateLengthChanged;
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

extern NSString* ORSIS3316StopTriggerChanged;
extern NSString* ORSIS3316RandomClockChanged;
//extern NSString* ORSIS3316StopDelayChanged;
//extern NSString* ORSIS3316StartDelayChanged;
extern NSString* ORSIS3316ClockSourceChanged;
extern NSString* ORSIS3316PageSizeChanged;

extern NSString* ORSIS3316SettingsLock;
extern NSString* ORSIS3316RateGroupChangedNotification;
extern NSString* ORSIS3316SampleDone;
extern NSString* ORSIS3316IDChanged;
extern NSString* ORSIS3316HWVersionChanged;
extern NSString* ORSIS3316SerialNumberChanged;
extern NSString* ORSIS3316ModelGainChanged;
extern NSString* ORSIS3316ModelTerminationChanged;
extern NSString* ORSIS3316DacOffsetChanged;

extern NSString* ORSIS3316EnableSumChanged;
extern NSString* ORSIS3316RiseTimeSumChanged;
extern NSString* ORSIS3316GapTimeSumChanged;
extern NSString* ORSIS3316CfdControlBitsSumChanged;
extern NSString* ORSIS3316SharingChanged;

extern NSString* ORSIS3316LemoCoMaskChanged;
extern NSString* ORSIS3316LemoUoMaskChanged;
extern NSString* ORSIS3316LemoToMaskChanged;

extern NSString* ORSIS3316InternalGateLenChanged;
extern NSString* ORSIS3316InternalCoinGateLenChanged;

