//-------------------------------------------------------------------------
//  ORSIS3316Model.m
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
#import "ORSIS3316Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORVmeTests.h"

NSString* ORSIS3316EnabledChanged                   = @"ORSIS3316EnabledChanged";
NSString* ORSIS3316AcquisitionControlChanged        = @"ORSIS3316AcquisitionControlChanged";
NSString* ORSIS3316NIMControlStatusChanged          = @"ORSIS3316NIMControlStatusChanged";
NSString* ORSIS3316HistogramsEnabledChanged         = @"ORSIS3316HistogramsEnabledChanged";

NSString* ORSIS3316PileUpEnabledChanged             = @"ORSIS3316PileUpEnabledChanged";
NSString* ORSIS3316ClrHistogramWithTSChanged        = @"ORSIS3316ClrHistogramWithTSChanged";
NSString* ORSIS3316WriteHitsIntoEventMemoryChanged  = @"ORSIS3316WriteHitsIntoEventMemoryChanged";

NSString* ORSIS3316ThresholdChanged                 = @"ORSIS3316ThresholdChanged";
NSString* ORSIS3316ThresholdSumChanged              = @"ORSIS3316ThresholdSumChanged";
NSString* ORSIS3316HeSuppressTrigModeChanged        = @"ORSIS3316HeSuppressTrigModeChanged";
NSString* ORSIS3316CfdControlBitsChanged            = @"ORSIS3316CfdControlBitsChanged";

NSString* ORSIS3316EventConfigChanged               = @"ORSIS3316EventConfigChanged";
NSString* ORSIS3316ExtendedEventConfigChanged       = @"ORSIS3316ExtendedEventConfigChanged";
NSString* ORSIS3316EndAddressSuppressionChanged     = @"ORSIS3316EndAddressSuppressionChanged";
NSString* ORSIS3316EndAddressChanged                = @"ORSIS3316EndAddressChanged";

NSString* ORSIS3316TriggerDelayChanged              = @"ORSIS3316TriggerDelayChanged";
NSString* ORSIS3316TriggerDelayTwoChanged           = @"ORSIS3316TriggerDelayTwoChanged";
NSString* ORSIS3316TriggerDelay3Changed             = @"ORSIS3316TriggerDelay3Changed";
NSString* ORSIS3316TriggerDelay4Changed             = @"ORSIS3316TriggerDelay4Changed";

NSString* ORSIS3316EnergyDividerChanged             = @"ORSIS3316EnergyDividerChanged";
NSString* ORSIS3316EnergySubtractorChanged          = @"ORSIS3316EnergySubtractorChanged";
NSString* ORSIS3316TauFactorChanged                 = @"ORSIS3316TauFactorChanged";
NSString* ORSIS3316ExtraFilterBitsChanged           = @"ORSIS3316ExtraFilterBitsChanged";
NSString* ORSIS3316TauTableBitsChanged              = @"ORSIS3316TauTableBitsChanged";
NSString* ORSIS3316PeakingTimeChanged               = @"ORSIS3316PeakingTimeChanged";
NSString* ORSIS3316GapTimeChanged                   = @"ORSIS3316GapTimeChanged";
NSString* ORSIS3316HeTrigThresholdChanged           = @"ORSIS3316HeTrigThresholdChanged";
NSString* ORSIS3316HeTrigThresholdSumChanged        = @"ORSIS3316HeTrigThresholdSumChanged";
NSString* ORSIS3316TrigBothEdgesChanged             = @"ORSIS3316TrigBothEdgesChanged";
NSString* ORSIS3316IntHeTrigOutPulseChanged         = @"ORSIS3316IntHeTrigOutPulseChanged";
NSString* ORSIS3316IntTrigOutPulseBitsChanged       = @"ORSIS3316IntTrigOutPulseBitsChanged";

NSString* ORSIS3316ActiveTrigGateWindowLenChanged   = @"ORSIS3316ActiveTrigGateWindowLenChanged";
NSString* ORSIS3316PreTriggerDelayChanged           = @"ORSIS3316PreTriggerDelayChanged";
NSString* ORSIS3316RawDataBufferLenChanged          = @"ORSIS3316RawDataBufferLenChanged";
NSString* ORSIS3316RawDataBufferStartChanged        = @"ORSIS3316RawDataBufferStartChanged";

NSString* ORSIS3316AccumulatorGateStartChanged      = @"ORSIS3316AccumulatorGateStartChanged";
NSString* ORSIS3316AccumulatorGateLengthChanged     = @"ORSIS3316AccumulatorGateLengthChanged";

NSString* ORSIS3316AccGate1LenChanged               = @"ORSIS3316AccGate1LenChanged";
NSString* ORSIS3316AccGate1StartChanged             = @"ORSIS3316AccGate1StartChanged";
NSString* ORSIS3316AccGate2LenChanged               = @"ORSIS3316AccGate2LenChanged";
NSString* ORSIS3316AccGate2StartChanged             = @"ORSIS3316AccGate2StartChanged";
NSString* ORSIS3316AccGate3LenChanged               = @"ORSIS3316AccGate3LenChanged";
NSString* ORSIS3316AccGate3StartChanged             = @"ORSIS3316AccGate3StartChanged";
NSString* ORSIS3316AccGate4LenChanged               = @"ORSIS3316AccGate4LenChanged";
NSString* ORSIS3316AccGate4StartChanged             = @"ORSIS3316AccGate4StartChanged";
NSString* ORSIS3316AccGate5LenChanged               = @"ORSIS3316AccGate5LenChanged";
NSString* ORSIS3316AccGate5StartChanged             = @"ORSIS3316AccGate5StartChanged";
NSString* ORSIS3316AccGate6LenChanged               = @"ORSIS3316AccGate6LenChanged";
NSString* ORSIS3316AccGate6StartChanged             = @"ORSIS3316AccGate6StartChanged";
NSString* ORSIS3316AccGate7LenChanged               = @"ORSIS3316AccGate7LenChanged";
NSString* ORSIS3316AccGate7StartChanged             = @"ORSIS3316AccGate7StartChanged";
NSString* ORSIS3316AccGate8LenChanged               = @"ORSIS3316AccGate8LenChanged";
NSString* ORSIS3316AccGate8StartChanged             = @"ORSIS3316AccGate8StartChanged";

//NSString* ORSIS3316CSRRegChanged                    = @"ORSIS3316CSRRegChanged";
NSString* ORSIS3316AcqRegChanged                    = @"ORSIS3316AcqRegChanged";
NSString* ORSIS3316PageSizeChanged                  = @"ORSIS3316PageSizeChanged";

NSString* ORSIS3316ClockSourceChanged               = @"ORSIS3316ClockSourceChanged";
NSString* ORSIS3316RandomClockChanged               = @"ORSIS3316RandomClockChanged";

NSString* ORSIS3316StopTriggerChanged               = @"ORSIS3316StopTriggerChanged";
NSString* ORSIS3316RateGroupChangedNotification     = @"ORSIS3316RateGroupChangedNotification";
NSString* ORSIS3316SettingsLock                     = @"ORSIS3316SettingsLock";

NSString* ORSIS3316SampleDone                       = @"ORSIS3316SampleDone";
NSString* ORSIS3316SerialNumberChanged              = @"ORSIS3316SerialNumberChanged";
NSString* ORSIS3316IDChanged                        = @"ORSIS3316IDChanged";
NSString* ORSIS3316TemperatureChanged               = @"ORSIS3316TemperatureChanged";
NSString* ORSIS3316HWVersionChanged                 = @"ORSIS3316HWVersionChanged";
NSString* ORSIS3316ModelGainChanged                 = @"ORSIS3316ModelGainChanged";
NSString* ORSIS3316ModelTerminationChanged          = @"ORSIS3316ModelTerminationChanged";
NSString* ORSIS3316DacOffsetChanged                 = @"ORSIS3316DacOffsetChanged";

NSString* ORSIS3316EnableSumChanged                 = @"ORSIS3316EnableSumChanged";
NSString* ORSIS3316RiseTimeSumChanged               = @"ORSIS3316RiseTimeSumChanged";
NSString* ORSIS3316GapTimeSumChanged                = @"ORSIS3316GapTimeSumChanged";
NSString* ORSIS3316CfdControlBitsSumChanged         = @"ORSIS3316CfdControlBitsSumChanged";
NSString* ORSIS3316SharingChanged                   = @"ORSIS3316SharingChanged";

NSString* ORSIS3316LemoCoMaskChanged                = @"ORSIS3316LemoCoMaskChanged";
NSString* ORSIS3316LemoUoMaskChanged                = @"ORSIS3316LemoUoMaskChanged";
NSString* ORSIS3316LemoToMaskChanged                = @"ORSIS3316LemoToMaskChanged";

#pragma mark - Static Declerations
typedef struct {
    unsigned long offset;
    NSString* name;
    BOOL canRead;
    BOOL canWrite;
    BOOL hasChannels;
    unsigned short enumId;
} ORSIS3316RegisterInformation;

//VME FPGA interface registers
static ORSIS3316RegisterInformation singleRegister[kNumberSingleRegs] = {
    {0x00000000,    @"Control/Status",                          YES,    YES,    NO,   kControlStatusReg},
    {0x00000004,    @"Module ID",                               YES,    NO,     NO,   kModuleIDReg},
    {0x00000008,    @"Interrupt Configuration",                 YES,    YES,    NO,   kInterruptConfigReg},
    {0x0000000C,    @"Interrupt Control",                       YES,    YES,    NO,   kInterruptControlReg},
    
    {0x00000010,    @"Interface Access",                        YES,    YES,    NO,   kInterfacArbCntrStatusReg},
    {0x00000014,    @"CBLT/Broadcast Setup",                    YES,    YES,    NO,   kCBLTSetupReg},
    {0x00000018,    @"Internal Test",                           YES,    YES,    NO,   kInternalTestReg},
    {0x0000001C,    @"Hardware Version",                        YES,    YES,    NO,   kHWVersionReg},

    {0x00000020,    @"Temperature",                             YES,    NO,     NO,   kTemperatureReg},
    {0x00000024,    @"Onewire EEPROM",                          YES,    YES,    NO,   k1WireEEPROMcontrolReg},
    {0x00000028,    @"Serial Number",                           YES,    NO,     NO,   kSerialNumberReg},
    {0x0000002C,    @"Internal Data Transfer Speed",            YES,    YES,    NO,   kDataTransferSpdSettingReg},
    
    {0x00000030,    @"ADC FPGAs BOOT Controller",               YES,    YES,    NO,   kAdcFPGAsBootControllerReg},
    {0x00000034,    @"SPI FLASH CONTROL/Status",                YES,    YES,    NO,   kSpiFlashControlStatusReg},
    {0x00000038,    @"SPI Flash Data",                          YES,    YES,    NO,   kSpiFlashData},
    {0x0000003C,    @"External Veto/Gate Delay",                YES,    YES,    NO,   kReservedforPROMReg},
    
    {0x00000040,    @"ADC Clock",                               YES,    YES,    NO,   kAdcClockI2CReg},
    {0x00000044,    @"MGT1 Clock",                              YES,    YES,    NO,   kMgt1ClockI2CReg},
    {0x00000048,    @" MGT2 CLock",                             YES,    YES,    NO,   kMgt2ClockI2CReg},
    {0x0000004C,    @"DDR3 Clock",                              YES,    YES,    NO,   kDDR3ClockI2CReg},
    
    {0x00000050,    @"ADC Sample CLock distribution control",   YES,    YES,    NO,   kAdcSampleClockDistReg},
    {0x00000054,    @"External NIM Clock Multiplier",           YES,    YES,    NO,   kExtNIMClockMulSpiReg},
    {0x00000058,    @"FP-Bus control ",                         YES,    YES,    NO,   kFPBusControlReg},
    {0x0000005C,    @"NIM-IN Control/status",                   YES,    YES,    NO,   kNimInControlReg},
    
    {0x00000060,    @"Acquisition control/status",              YES,    YES,    NO,   kAcqControlStatusReg},
    {0x00000064,    @"TCLT Control",                            YES,    YES,    NO,   kTrigCoinLUTControlReg},
    {0x00000068,    @"TCLT Address",                            YES,    YES,    NO,   kTrigCoinLUTAddReg},
    {0x0000006C,    @"TCLT Data",                               YES,    YES,    NO,   kTrigCoinLUTDataReg},
    
    {0x00000070,    @"LEMO Out CO",                             YES,    YES,    NO,   kLemoOutCOSelectReg},
    {0x00000074,    @"LMEO Out TO",                             YES,    YES,    NO,   kLemoOutTOSelectReg},
    {0x00000078,    @"LEMO Out UO",                             YES,    YES,    NO,   kLemoOutUOSelectReg},
    {0x0000007C,    @"Internal Trigger Feedback Select",        YES,    YES,    NO,   kIntTrigFeedBackSelReg},
    
    {0x00000080,    @"ADC ch1-ch4 Data Transfer Control",       YES,    YES,    YES,  kAdcCh1_Ch4DataCntrReg},
    {0x00000084,    @"ADC ch5-ch8 Data Transfer Control",       YES,    YES,    YES,  kAdcCh5_Ch8DataCntrReg},
    {0x00000088,    @"ADC ch9-ch12 Data Transfer Control",      YES,    YES,    YES,  kAdcCh9_Ch12DataCntrReg},
    {0x0000008C,    @"ADC ch13-ch16 Data Transfer Control",     YES,    YES,    YES,  kAdcCh13_Ch16DataCntrReg},
    
    {0x00000090,    @"ADC ch1-ch4 Data Transfer STatus",        YES,    NO,     YES,  kAdcCh1_Ch4DataStatusReg},
    {0x00000094,    @"ADC ch5-ch8 Data Transfer STatus",        YES,    NO,     YES,  kAdcCh5_Ch8DataStatusReg},
    {0x00000098,    @"ADC ch9-ch12 Data Transfer STatus",       YES,    NO,     YES,  kAdcCh9_Ch12DataStatusReg},
    {0x0000009C,    @"ADC ch13-ch16 Data Transfer STatus",      YES,    NO,     YES,  kAdcCh13_Ch16DataStatusReg},
    
    {0x000000A0,    @"ADC Data Link Status",                    YES,    YES,    NO,   kAdcDataLinkStatusReg},
    {0x000000A4,    @"ADC SPI Busy Status",                     YES,    YES,    NO,   kAdcSpiBusyStatusReg},
    {0x000000B8,    @"Prescaler output pulse divider",          YES,    YES,    NO,   kPrescalerOutDivReg},
    {0x000000BC,    @"Prescaler output pulse length",           YES,    YES,    NO,   kPrescalerOutLenReg},
    
    {0x000000C0,    @"Channel 1 Internal Trigger Counter",      YES,    NO,     YES,    kChan1TrigCounterReg},
    {0x000000C4,    @"Channel 2 Internal Trigger Counter",      YES,    NO,     YES,    kChan2TrigCounterReg},
    {0x000000C8,    @"Channel 3 Internal Trigger Counter",      YES,    NO,     YES,    kChan3TrigCounterReg},
    {0x000000CC,    @"Channel 4 Internal Trigger Counter",      YES,    NO,     YES,    kChan4TrigCounterReg},
    
    {0x000000D0,    @"Channel 5 Internal Trigger Counter",      YES,    NO,     YES,    kChan5TrigCounterReg},
    {0x000000D4,    @"Channel 6 Internal Trigger Counter",      YES,    NO,     YES,    kChan6TrigCounterReg},
    {0x000000D8,    @"Channel 7 Internal Trigger Counter",      YES,    NO,     YES,    kChan7TrigCounterReg},
    {0x000000DC,    @"Channel 8 Internal Trigger Counter",      YES,    NO,     YES,    kChan8TrigCounterReg},
    
    {0x000000E0,    @"Channel 9 Internal Trigger Counter",      YES,    NO,     YES,    kChan9TrigCounterReg},
    {0x000000E4,    @"Channel 10 Internal Trigger Counter",     YES,    NO,     YES,    kChan10TrigCounterReg},
    {0x000000E8,    @"Channel 11 Internal Trigger Counter",     YES,    NO,     YES,    kChan11TrigCounterReg},
    {0x000000EC,    @"Channel 12 Internal Trigger Counter",     YES,    NO,     YES,    kChan12TrigCounterReg},

    {0x000000F0,    @"Channel 13 Internal Trigger Counter",     YES,    NO,     YES,    kChan13TrigCounterReg},
    {0x000000F4,    @"Channel 14 Internal Trigger Counter",     YES,    NO,     YES,    kChan14TrigCounterReg},
    {0x000000F8,    @"Channel 15 Internal Trigger Counter",     YES,    NO,     YES,    kChan15TrigCounterReg},
    {0x000000FC,    @"Channel 16 Internal Trigger Counter",     YES,    NO,     YES,    kChan16TrigCounterReg},
    
    {0x00000400,    @"Key Register Reset",                      NO,    YES,     NO,     kKeyResetReg},
    {0x00000404,    @"Key User Function",                       NO,    YES,     NO,     kKeyUserFuncReg},
    
    {0x00000410,    @"Key Arm Sample Logic",                    NO,    YES,     NO,     kKeyArmSampleLogicReg},
    {0x00000414,    @"Key Disarm Sample Logic",                 NO,    YES,     NO,     kKeyDisarmSampleLogicReg},
    {0x00000418,    @"Key Trigger",                             NO,    YES,     NO,     kKeyTriggerReg},
    {0x0000041C,    @"Key Timestamp Clear",                     NO,    YES,     NO,     kKeyTimeStampClrReg},
    {0x00000420,    @"Key Dusarm Bankx and Arm Bank1",          NO,    YES,     NO,     kKeyDisarmXArmBank1Reg},
    {0x00000424,    @"Key Dusarm Bankx and Arm Bank2",          NO,    YES,     NO,     kKeyDisarmXArmBank2Reg},
    {0x00000428,    @"Key Enable Bank Swap",                    NO,    YES,     NO,     kKeyEnableBankSwapNimReg},
    {0x0000042C,    @"Key Disable Prescaler Logic",             NO,    YES,     NO,     kKeyDisablePrescalerLogReg},
    
    {0x00000430,    @"Key PPS latch bit clear",                 NO,    YES,     NO,     kKeyPPSLatchBitClrReg},
    {0x00000434,    @"Key Reset ADC-FPGA-Logic",                NO,    YES,     NO,     kKeyResetAdcLogicReg},
    {0x00000438,    @"Key ADC Clock DCM/PLL Reset",             NO,    YES,     NO,     kKeyAdcClockPllResetReg},
};
    

//ADC Group registers Add 0x1000 for each group

static ORSIS3316RegisterInformation groupRegister[kADCGroupRegisters] = {
  
    {0x00001000,    @"ADC Input Tap Delay",                     YES,    YES,    YES,   kAdcInputTapDelayReg},
    {0x00001004,    @"ADC Gain/Termination Control",            YES,    YES,    YES,   kAdcGainTermCntrlReg},
    {0x00001008,    @"ADC Offset Control",                      YES,    YES,    YES,   kAdcOffsetDacCntrlReg},
    {0x0000100C,    @"ADC SPI Control",                         YES,    YES,    YES,   kAdcSpiControlReg},
    
    {0x00001010,    @"Event Configureation",                    YES,    YES,    YES,   kEventConfigReg},
    {0x00001014,    @"Channel Header ID",                       YES,    YES,    YES,   kChanHeaderIdReg},
    {0x00001018,    @"End Address Threshold",                   YES,    YES,    YES,   kEndAddressThresholdReg},
    {0x0000101C,    @"Active Trigger Gate WIndow Length",       YES,    YES,    YES,   kActTriggerGateWindowLenReg},
    
    {0x00001020,    @"Raw Data Buffer COnfiguration",           YES,    YES,    YES,   kRawDataBufferConfigReg},
    {0x00001024,    @"Pileup Configuration",                    YES,    YES,    YES,   kPileupConfigReg},
    {0x00001028,    @"Pre Trigger Delay",                       YES,    YES,    YES,   kPreTriggerDelayReg},
    {0x0000102C,    @"Average Configuration",                   YES,    YES,    YES,   kAveConfigReg},
    
    {0x00001030,    @"Data Format Configuration",               YES,    YES,    YES,   kDataFormatConfigReg},
    {0x00001034,    @"MAW Test Buffer Configuration",           YES,    YES,    YES,   kMawTestBufferConfigReg},
    {0x00001038,    @"Internal Trigger Delay Configuration",    YES,    YES,    YES,   kInternalTrigDelayConfigReg},
    {0x0000103C,    @"Internal Gate Length Configuration",      YES,    YES,    YES,   kInternalGateLenConfigReg},
    
    {0x00001040,    @"FIR Trigger Setup",                       YES,    YES,    YES,   kFirTrigSetupCh1Reg},
    {0x00001044,    @"Trigger Threshold",                       YES,    YES,    YES,   kTrigThresholdCh1Reg},
    {0x00001048,    @"High Energy Trigger Threshold",           YES,    YES,    YES,   kHiEnergyTrigThresCh1Reg},
    
    {0x00001080,    @"FIR Trigger Setup Sum",                   YES,    YES,    YES,   kFirTrigSetupSumCh1Ch4Reg},
    {0x00001084,    @"Trigger Threshold Sum",                   YES,    YES,    YES,   kTrigThreholdSumCh1Ch4Reg},
    {0x00001088,    @"High Energy Trigger Threshold Sum",       YES,    YES,    YES,   kHiETrigThresSumCh1Ch4Reg},
    
    {0x00001090,    @"Trigger Statistic Counter Mode",          YES,    YES,    YES,   kTrigStatCounterModeCh1Ch4Reg},
    {0x00001094,    @"Peak/Charge Configuration",               YES,    YES,    YES,   kPeakChargeConfigReg},
    {0x00001098,    @"Extended Raw Data Buffer Configuration",  YES,    YES,    YES,   kExtRawDataBufConfigReg},
    {0x0000109C,    @"Extended Event Configuration",            YES,    YES,    YES,   kExtEventConfigCh1Ch4Reg},

    {0x000010A0,    @"Accumulator Gate 1 Configuration",        YES,    YES,    YES,   kAccGate1ConfigReg},
    {0x000010A4,    @"Accumulator Gate 2 Configuration",        YES,    YES,    YES,   kAccGate2ConfigReg},
    {0x000010A8,    @"Accumulator Gate 3 Configuration",        YES,    YES,    YES,   kAccGate3ConfigReg},
    {0x000010AC,    @"Accumulator Gate 4 Configuration",        YES,    YES,    YES,   kAccGate4ConfigReg},
    
    {0x000010B0,    @"Accumulator Gate 5 Configuration",        YES,    YES,    YES,   kAccGate5ConfigReg},
    {0x000010B4,    @"Accumulator Gate 6 Configuration",        YES,    YES,    YES,   kAccGate6ConfigReg},
    {0x000010B8,    @"Accumulator Gate 7 Configuration",        YES,    YES,    YES,   kAccGate7ConfigReg},
    {0x000010BC,    @"Accumulator Gate 8 Configuration",        YES,    YES,    YES,   kAccGate8ConfigReg},
    
    {0x000010C0,    @"FIR Energy Setup Ch1",                    YES,    YES,    YES,   kFirEnergySetupCh1Reg},
    {0x000010C4,    @"FIR Energy Setup Ch2",                    YES,    YES,    YES,   kFirEnergySetupCh2Reg},
    {0x000010C8,    @"FIR Energy Setup Ch3",                    YES,    YES,    YES,   kFirEnergySetupCh3Reg},
    {0x000010CC,    @"FIR Energy Setup Ch4",                    YES,    YES,    YES,   kFirEnergySetupCh4Reg},

    {0x000010D0,    @"Energy Histogram Configuration Ch1",      YES,    YES,    YES,   kEnergyHistoConfigCh1Reg},
    {0x000010D4,    @"Energy Histogram Configuration Ch2",      YES,    YES,    YES,   kEnergyHistoConfigCh2Reg},
    {0x000010D8,    @"Energy Histogram Configuration Ch3",      YES,    YES,    YES,   kEnergyHistoConfigCh3Reg},
    {0x000010DC,    @"Energy Histogram Configuration Ch4",      YES,    YES,    YES,   kEnergyHistoConfigCh4Reg},

    {0x000010E0,    @"MAW Start Index/Energy Pickup Config Ch1",YES,    YES,    YES,   kMawStartIndexConfigCh1Reg},
    {0x000010E4,    @"MAW Start Index/Energy Pickup Config Ch2",YES,    YES,    YES,   kMawStartIndexConfigCh2Reg},
    {0x000010E8,    @"MAW Start Index/Energy Pickup Config Ch3",YES,    YES,    YES,   kMawStartIndexConfigCh3Reg},
    {0x000010EC,    @"MAW Start Index/Energy Pickup Config Ch4",YES,    YES,    YES,   kMawStartIndexConfigCh4Reg},

    {0x00001100,    @"ADC FPGA Version",                        YES,    NO,    YES,   kAdcVersionReg},
    {0x00001104,    @"ADC FPGA Status",                         YES,    NO,    YES,   kAdcVStatusReg},
    {0x00001108,    @"ADC Offset (DAC) readback",               YES,    NO,    YES,   kAdcOffsetReadbackReg},
    {0x0000110C,    @"ADC SPI readback",                        YES,    NO,    YES,   kAdcSpiReadbackReg},

    {0x00001110,    @"Actual sample address Ch1",               YES,    NO,    YES,   kActualSampleCh1Reg},
    {0x00001114,    @"Actual sample address Ch2",               YES,    NO,    YES,   kActualSampleCh2Reg},
    {0x00001118,    @"Actual sample address Ch3",               YES,    NO,    YES,   kActualSampleCh3Reg},
    {0x0000111C,    @"Actual sample address Ch4",               YES,    NO,    YES,   kActualSampleCh4Reg},

    {0x00001120,    @"Previous Bank Sample Address Register Ch1",       YES,    NO,    YES,   kPreviousBankSampleCh1Reg},
    {0x00001124,    @"Previous Bank Sample Address Register Ch2",       YES,    NO,    YES,   kPreviousBankSampleCh2Reg},
    {0x00001128,    @"Previous Bank Sample Address Register Ch3",       YES,    NO,    YES,   kPreviousBankSampleCh3Reg},
    {0x0000112C,    @"Previous Bank Sample Address Register Ch4",       YES,    NO,    YES,   kPreviousBankSampleCh4Reg},

    {0x00001130,    @"PPS Timestamp (bits 47-32)",              YES,    NO,    YES,   kPPSTimeStampHiReg},
    {0x00001134,    @"PPS TImestamp (bits 31-0)",               YES,    NO,    YES,   kPPSTimeStampLoReg},
    {0x00001138,    @"Test:readback  0x01018",                  YES,    NO,    YES,   kTestReadback01018Reg},
    {0x0000113C,    @"Test: readback 0x0101C",                  YES,    NO,    YES,   kTestReadback0101CReg},
};

#define I2C_ACK             8
#define I2C_START			9
#define I2C_REP_START		10
#define I2C_STOP			11
#define I2C_WRITE			12
#define I2C_READ			13
#define I2C_BUSY			31
#define OSC_ADR             0x55

// frequency presets setup
unsigned char freqPreset62_5MHz[6] = {0x23,0xC2,0xBC,0x33,0xE4,0xF2};
unsigned char freqPreset125MHz[6]  = {0x21,0xC2,0xBC,0x33,0xE4,0xF2};
unsigned char freqPreset250MHz[6]  = {0x20,0xC2,0xBC,0x33,0xE4,0xF2};

//----------------------------------------------
//Control Status Register Bits
#define kLedUOnBit				(0x1<<0)
#define kLed1OnBit              (0x1<<1)
#define kLed2OnBit              (0x1<<2)
#define kLedUAppModeBit         (0x1<<4)
#define kLed1AppModeBit         (0x1<<5)
#define kLed2AppModeBitBit      (0x1<<6)
#define kRebootFPGA             (0x1<<15)

#define kLedUOffBit				(0x1<<0)
#define kLed1OffBit             (0x1<<1)
#define kLed2OffBit             (0x1<<2)
#define kLedUAppModeClrBit      (0x1<<4)
#define kLed1AppModeClrBit      (0x1<<5)
#define kLed2AppModeVlrBit      (0x1<<6)
#define kRebootFPGAClrBit       (0x1<<15)

@interface ORSIS3316Model (private)
//low level stuff that should never be called by scripts or other objects
- (int) si570FreezeDCO:(int) osc;
- (int) si570Divider:(int) osc values:(unsigned char*)data;
- (int) si570UnfreezeDCO:(int)osc;
- (int) si570NewFreq:(int) osc;
//- (int) i2cStop:(int) osc;
//- (int) i2cStart:(int) osc;
//- (int) i2cWriteByte:(int)osc data:(unsigned char) data ack:(char*)ack;
//- (int) i2cReadByte:(int) osc data:(unsigned char*) data ack:(char)ack;
- (void) addCurrentState:(NSMutableDictionary*)dictionary unsignedLongArray:(unsigned long*)anArray   size:(long)numItems forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary unsignedShortArray:(unsigned short*)anArray size:(long)numItems forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray                    size:(long)numItems forKey:(NSString*)aKey;
@end

@implementation ORSIS3316Model

#pragma mark •••Static Declarations
//static unsigned long bankMemory[4][2]={
//{0x00400000,0x00600000},
//{0x00480000,0x00680000},
//{0x00500000,0x00700000},
//{0x00580000,0x00780000},
//};

static unsigned long eventCountOffset[4][2]={ //group,bank
{0x00200010,0x00200014},
{0x00280010,0x00280014},
{0x00300010,0x00300014},
{0x00380010,0x00380014},
};

static unsigned long eventDirOffset[4][2]={ //group,bank
{0x00201000,0x00202000},
{0x00281000,0x00282000},
{0x00301000,0x00302000},
{0x00381000,0x00382000},
};

static unsigned long addressCounterOffset[4][2]={ //group,bank
{0x00200008,0x0020000C},
{0x00280008,0x0028000C},
{0x00300008,0x0030000C},
{0x00380008,0x0038000C},
};

#define kTriggerEvent1DirOffset 0x101000
#define kTriggerEvent2DirOffset 0x102000

#define kTriggerTime1Offset 0x1000
#define kTriggerTime2Offset 0x2000

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x01000000];
    [self setDefaults];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
    [waveFormRateGroup release];
    [revision release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3316Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3316Controller"];
}

//- (NSString*) helpURL
//{
//	return @"VME/SIS3316.html";
//}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x00780000+0x80000);
}
- (BOOL) checkRegList
{
    int i;
    for(i=0;i<kNumberSingleRegs;i++){
        if(singleRegister[i].enumId != i){
            NSLog(@"programmer bug in register list\n");
            NSLog(@"check line: %d\n",i);
            return NO;
        }
    }
    for(i=0;i<kADCGroupRegisters;i++){
        if(groupRegister[i].enumId != i){
            NSLog(@"programmer bug in group registers\n");
            NSLog(@"check line: %d\n",i);
            return NO;
        }
    }
    NSLog(@"Lists OK\n");
    return YES;
}

#pragma mark ***Accessors
- (void) setDefaults
{
    [self setNIMControlStatusMask:0x3];
    [self setLemoToMask:0x0];
    [self setLemoUoMask:0x0];
    [self setLemoCoMask:0x0];
    [self setAcquisitionControlMask:0x05]; //ext timestamp clear enable | ext trig enable
    
    int iadc;
    for(iadc =0; iadc<kNumSIS3316Groups; iadc++) {
        [self setActiveTrigGateWindowLen:iadc   withValue:1000];
        [self setPreTriggerDelay:iadc           withValue:300];
        [self setRawDataBufferLen:iadc          withValue:activeTrigGateWindowLen[iadc]];
        [self setRawDataBufferStart:iadc        withValue:0];
        [self setThreshold:iadc                 withValue:0x1000];
        [self setDacOffset:iadc                 withValue:0x8000];
        [self setEnableSum:iadc                 withValue:1];
        [self setRiseTimeSum:iadc               withValue:4];
        [self setGapTimeSum:iadc                withValue:4];
        [self setThresholdSum:iadc              withValue:1000];
        [self setCfdControlBitsSum:iadc         withValue:0x3]; //CFD at 50%
        [self setHeSuppressTriggerBit:iadc      withValue:0];
        [self setHeTrigThresholdSum:iadc        withValue:0];
        [self setTriggerDelay:iadc              withValue:0];
        
        //TBD ------ fill in the rest of the defaults-----------
//
//        internalGate1_block_channelEnableMask[iadc] = 0x0;
//        internalGate2_block_channelEnableMask[iadc] = 0x0;
//        internalCoincidence_block_width[iadc] = 0;
//        internalGate_block_length[iadc] = 0;
//
//        //        internal trigger delay
//        internalTriggerDelay_block[iadc] = 0x0;
//
//        for(int iqdc = 0; iqdc<SIS3316_QDC_PER_CHANNEL; iqdc++) {
//            qdcstart[iadc][iqdc]=100+iqdc*100;
//            qdclength[iadc][iqdc]=100;
//        }
    }
    //int ichan;
    //for(ichan =0; ichan<kNumSIS3316Channels; ichan++)
   // {
        
//        databuffer[ichan] = 0;
//        databuffersize[ichan] = 0;
//        databufferread[ichan]=0;
//
//        trigconf[ichan] = 0x5;
//
//        highenergythresh[ichan] = 0;
//        termination[ichan] = 1;
//        gain[ichan] = 1;
//
//        firenable[ichan] = 1;
//        firlength[ichan] = 4;
//        risetime[ichan] = 4;
//        gaptime[ichan] = 4;
//        fircfd[ichan] = 0x3; //CFD at 50%
//        firthresh[ichan] = 1000.0;
//
//        //        high energy trigger settings
//        highenergysuppress[ichan] = 0;
//        highenergythresh[ichan] = 0;
//        highenergytrig_trigOnBothEdges[ichan] = 0;
//        highenergytrig_HEstretchedTrigOut[ichan] = 0;
//
//        //        FIR energy settings
//        firenergy_taubits[ichan] = 0;
//        firenergy_extrafilter[ichan] = 0;
//        firenergy_gaptime[ichan] = 0;
//        firenergy_peakingtime[ichan] = 0;
//
        
 //   }
}

- (unsigned short) moduleID
{
	return moduleID;
}
- (float) temperature
{
    return temperature;
}


//---------------------------------------------------------------------------
//Energy Histogram Configuration


//---------------------------------------------------------------------------

//---------------------------------------------------------------------------


// **** bit 14 and 16-31 are reserved ****  //
// **** valid values are 0,2,4,6 to 2042/16.378 ****  //


//-----------------



//clocks and delays (Acquisition control reg)
- (BOOL) randomClock
{
    return randomClock;
}

- (void) setRandomClock:(BOOL)aRandomClock
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRandomClock:randomClock];
    randomClock = aRandomClock;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AcqRegChanged object:self];
}


- (BOOL) stopTrigger
{
    return stopTrigger;
}

- (void) setStopTrigger:(BOOL)aStopTrigger
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStopTrigger:stopTrigger];
    
    stopTrigger = aStopTrigger;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316StopTriggerChanged object:self];
}

- (int) pageSize
{
    return pageSize;
}

- (void) setPageSize:(int)aPageSize
{
	if(aPageSize<0)		aPageSize = 0;
	else if(aPageSize>7)aPageSize = 7;
    [[[self undoManager] prepareWithInvocationTarget:self] setPageSize:pageSize];
    pageSize = aPageSize;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316PageSizeChanged object:self];
}

- (int) numberOfSamples
{
	static unsigned long sampleSize[8]={
		0x20000,
		0x4000,
		0x1000,
		0x800,
		0x400,
		0x200,
		0x100,
		0x80
	};
	
	return sampleSize[pageSize];
}

- (ORRateGroup*) waveFormRateGroup
{
    return waveFormRateGroup;
}

- (void) setWaveFormRateGroup:(ORRateGroup*)newRateGroup
{
    [newRateGroup retain];
    [waveFormRateGroup release];
    waveFormRateGroup = newRateGroup;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSIS3316RateGroupChangedNotification
	 object:self];    
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) initParams
{
	enabledMask = 0xFFFFFFFF;
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

#pragma mark •••Rates
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumSIS3316Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}



#pragma mark •••Hardware Access
//Register Array
//comments denote the section from the manual
//------------------------------------------------------------
- (unsigned long) singleRegister: (unsigned long)aRegisterIndex
{
    return [self baseAddress] + singleRegister[aRegisterIndex].offset;
}

- (unsigned long) groupRegister:(unsigned long)aRegisterIndex group:(int)aGroup
{
    return [self baseAddress] + groupRegister[aRegisterIndex].offset + 0x1000*aGroup;
}

- (unsigned long) channelRegister:(unsigned long)aRegisterIndex channel:(int)aChannel
{
    return [self baseAddress] + groupRegister[aRegisterIndex].offset + (0x1000*(aChannel/4)) + (0x10*(aChannel%4));
}

- (unsigned long) channelRegisterVersionTwo:(unsigned long)aRegisterIndex channel:(int)aChannel
{
    return [self baseAddress] + groupRegister[aRegisterIndex].offset + (0x1000*(aChannel/4)) + (0x4*(aChannel%4));
}

- (unsigned long) accumulatorRegisters:(unsigned long)aRegisterIndex channel:(int)aChannel
{
    return [self baseAddress] + groupRegister[aRegisterIndex].offset + (0x1000*(aChannel/8)) + (0x4*(aChannel%2)) ;
}

//--------------------------------------------------------------

//6.1 Control/Status Register(0x0, write/read)

- (void) writeControlStatusReg:(unsigned long)aValue
{
    [self writeLong:aValue toAddress:[self singleRegister:kControlStatusReg]];
}

- (unsigned long) readControlStatusReg
{
    return [self readLongFromAddress:[self singleRegister:kControlStatusReg]];
}

- (void) setLed:(BOOL)state
{
    unsigned long aValue = state ? 0x1:(0x1<<16);
    [self writeLong:aValue toAddress:[self singleRegister:kControlStatusReg]];
}
//------------------------------------------------------------

//6.2 Module Id. and Firmware Revision Register

- (NSString*) revision
{
    if(revision)return revision;
    else        return nil;
}

- (void) setRevision:(NSString*)aString;

{
    [revision autorelease];
    revision = [aString copy];
}

- (unsigned short) majorRevision;
{
    return majorRev;
}

- (unsigned short) minorRevision;
{
    return minorRev;
}

- (void) readModuleID:(BOOL)verbose //*** readModuleID method ***//
{
    unsigned long result =  [self readLongFromAddress:[self singleRegister:kModuleIDReg]];
    
    moduleID = result >> 16;
    majorRev = (result >> 8) & 0xff;
    minorRev = result & 0xff;
    [self setRevision:[NSString stringWithFormat:@"%x.%x",majorRev,minorRev]];
    if(verbose)             NSLog(@"ModuleID Reg: 0x%08x\n",result);
    if(verbose)             NSLog(@"SIS3316 ID: %x  Firmware:%x\n",moduleID,revision);
    if(majorRev == 0x20)    NSLog(@"Gamma Revision\n");
    else                    NSLog(@"");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316IDChanged object:self]; //changes name if BOOL = true
}
//----------------------------------------------------------

//6.3 Intterupt Configureation register (0x8)

//6.4 Interrupt control register (0xC)

//6.5 Interface Access Arbitration Control Register

//6.6 Broadcast setup register

//6.7 Hardware Version Register
- (void) readHWVersion:(BOOL)verbose
{
    unsigned long result =  [self readLongFromAddress:[self singleRegister:kHWVersionReg]];
    result &= 0xf;
    if(verbose)NSLog(@"%@ HW Version: %d\n",[self fullID],result);
    hwVersion = result;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HWVersionChanged object:self];
}

- (unsigned short) hwVersion;
{
    return hwVersion;
}
//-----------------------------------------------------

//6.8 Temperature Register
- (void) readTemperature:(BOOL)verbose
{
    temperature =  [self readLongFromAddress:[self singleRegister:kTemperatureReg]]/4.0;

    if(verbose) NSLog(@"%@ Temp: %.1f\n",[self fullID],temperature);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316TemperatureChanged object:self];
}


//6.9 Onewire EEPROM Control register

//6.10 Serial Number register  (ethernet mac address)

- (void) readSerialNumber:(BOOL)verbose{
    unsigned long result =  [self readLongFromAddress:[self singleRegister:kSerialNumberReg]];
    BOOL isSerialNumberValid    = (result >> 16) & 0x1;
    serialNumber = result & 0xFFFF;  //gives serial number
   // unsigned short dhcpOption   = (result >> 24) & 0xFF; (checkbox?)
    //unsigned short megaByteMemoryFlag512    =   (result >> 23);
    
    if(verbose){
        if(isSerialNumberValid)NSLog(@"%@ Serial Number: 0x%0x\n",[self fullID],serialNumber);
        else NSLog(@"Serial Number is not valid\n");
       // if (megaByteMemoryFlag512)NSLog(@"512 MByte Memory Flag\n");
        
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316SerialNumberChanged object:self];
}

- (unsigned short) serialNumber
{
    return serialNumber;
}

//6.11 Internal Transfer Speed register(not often needed)

//6.12 ADC FPGA Boot control register

//6.13 SPI Flash Control/Status register

//6.14 6.14 SPI Flash Data register

//6.15 External Veto/Gate Delay register

//6.16 Programmable Clock I2C registers

- (int) i2cStart:(int) osc
{
    if(osc > 3)return -101;
    // start
    unsigned long aValue = 0x1<<I2C_START;
    [self writeLong:aValue toAddress:[self singleRegister:kAdcClockI2CReg] +  (4 * osc)];
    
    int i = 0;
    aValue = 0;
    do{
        // poll i2c fsm busy
        aValue =  [self readLongFromAddress:[self singleRegister:kAdcClockI2CReg] + (4 * osc)];
        i++;
    }while((aValue & (1UL<<I2C_BUSY)) && (i < 1000));
    
    // register access problem
    if(i == 1000){
        printf("i2cStart3 too many tries \n");
        return -100;
    }
    
    return 0;
}


- (int) i2cStop:(int) osc
{
    if(osc > 3)return -101;
    
    // stop
    usleep(20000);
    unsigned long aValue = 0x1<<I2C_STOP;
    [self writeLong:aValue toAddress:[self singleRegister:kAdcClockI2CReg] +  (4 * osc)];
    
    int i = 0;
    aValue = 0;
    do{
        // poll i2c fsm busy
        usleep(20000);
        aValue =  [self readLongFromAddress:[self singleRegister:kAdcClockI2CReg] + (4 * osc)];
    }while((aValue & (1UL<<I2C_BUSY)) && (++i < 1000));
    
    // register access problem
    if(i == 1000)return -100;
    
    return 0;
}
- (int) i2cWriteByte:(int)osc data:(unsigned char) data ack:(char*)ack
{
    int i;
    
    if(osc > 3)return -101;
    
    // write byte, receive ack
    unsigned long aValue = 0x1<<I2C_WRITE ^ data;
    [self writeLong:aValue toAddress:[self singleRegister:kAdcClockI2CReg] +  (4 * osc)];
    
    i = 0;
    unsigned long tmp = 0;
    do{
        // poll i2c fsm busy
        tmp =  [self readLongFromAddress:[self singleRegister:kAdcClockI2CReg] + (4 * osc)];
    }while((tmp & (1UL<<I2C_BUSY)) && (++i < 1000));
    
    // register access problem
    if(i == 1000)return -100;
    
    // return ack value?
    if(ack){
        // yup
        *ack = tmp & 0x1<<I2C_ACK ? 1 : 0;
    }
    
    return 0;
}

- (int) i2cReadByte:(int) osc data:(unsigned char*) data ack:(char)ack
{
    if(osc > 3)return -101;
    
    // read byte, put ack
    unsigned long aValue;
    aValue = 0x1<<I2C_READ;
    aValue |= ack ? 1UL<<I2C_ACK : 0;
    usleep(20000);
    [self writeLong:aValue toAddress:[self singleRegister:kAdcClockI2CReg] +  (4 * osc)];
    
    int i = 0;
    do {
        // poll i2c fsm busy
        usleep(20000);
        aValue =  [self readLongFromAddress:[self singleRegister:kAdcClockI2CReg] + (4 * osc)];
   } while((aValue & (1UL<<I2C_BUSY)) && (++i < 1000));
    
    // register access problem
    if(i == 1000)return -100;
    
    return 0;
}


//6.17 ADC Sample Clock distribution control register (0x50)

- (long) clockSource
{
    return clockSource;
}

- (void) setClockSource:(long)aClockSource
{
    if(aClockSource<0)aClockSource = 0;
    if(aClockSource>0x3)aClockSource = 0x3;
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = aClockSource;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ClockSourceChanged object:self];
}

- (void) writeClockSource
{
    unsigned long aValue = clockSource;
    [self writeLong:aValue toAddress:[self singleRegister:kAdcSampleClockDistReg]];
    if(clockSource==0)[ORTimer delay:10*1E-3]; //required to let clock stablize

}

- (void) readClockSource:(BOOL)verbose
{
    NSString* clockSourceString[4] = {
        @"Internal          ",
        @"VXS               ",
        @"External from LVDS",
        @"External from NIM "
    };

    if(verbose){
        NSLog(@"Reading Clock Source:\n");
    }
    unsigned long aValue =  [self readLongFromAddress:[self singleRegister:kAdcSampleClockDistReg]];
    if(verbose){
        unsigned long theClockSource  = (aValue & 0x3);
        NSLog(@"%@ \n",clockSourceString[theClockSource]);
    }
}

//6.18 External NIM Clock Multiplier SPI register





//6.19 FP-Bus control register

//6.20 NIM Input Control/Status register
- (long)  nimControlStatusMask                     {return nimControlStatusMask;         }

- (void) setNIMControlStatusMask:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNIMControlStatusMask:nimControlStatusMask];
    nimControlStatusMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316NIMControlStatusChanged object:self];
}

- (void) setNIMControlStatusBit:(unsigned long)aChan withValue:(BOOL)aValue
{
    long aMask                      = nimControlStatusMask;
    if(aValue)                      aMask |= (0x1<<aChan);
    else                            aMask &= ~(0x1<<aChan);
    [self setNIMControlStatusMask:aMask];
}

- (void) writeNIMControlStatus
{
    [self writeLong:nimControlStatusMask toAddress:[self singleRegister:kNimInControlReg]];
}

- (void) readNIMControlStatus:(BOOL)verbose
{
    NSString* nimControlStatusString[14] = {
        @"NIM Input CI Enable"              ,
        @"NIM Input CI Invert"              ,
        @"NIM Input CI Level sensitive"     ,
        @"Set NIM Input CI Function"        ,
        @"NIM Input TI as Trigger Enable"   ,
        @"NIM Input TI Invert"              ,
        @"NIM Input TI Level sensitive"     ,
        @"Set NIM Input TI Function"        ,
        @"NIM Input UI as Timestamp Clear"  ,
        @"NIM Input UI Invert"              ,
        @"NIM Input UI Level sensitive"     ,
        @"Set NIM Input UI Function"        ,
        @"NIM Input UI as Veto Enable "     ,
        @"NIM Input UI as PPS Enable "
    };
    
    int i;
    if(verbose){
        NSLog(@"Reading NIM Control Status Register:\n");
        NSLog(@" \n");
    }
    unsigned long aValue =  [self readLongFromAddress:[self singleRegister:kNimInControlReg]];
    
    if(verbose){
        for(i =0; i < 14; i++) {
            unsigned long theNIMControlStatus  = ((aValue >> (i)) & 0x1);
            NSLogFont([NSFont fontWithName:@"Monaco" size:12],@"%2d: %@ %@ \n",i, nimControlStatusString[i], theNIMControlStatus?@"YES":@" NO");
        }
    }
}

//6.21 Acquisition control/status register (0x60, read/write)

- (long)  acquisitionControlMask                     {return acquisitionControlMask;         }
- (void) setAcquisitionControlMask:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAcquisitionControlMask:acquisitionControlMask];
    acquisitionControlMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AcquisitionControlChanged object:self];
}

- (BOOL) addressThresholdFlag
{
    unsigned long aValue =  [self readLongFromAddress:[self singleRegister:kAcqControlStatusReg]];
    return (aValue & (0x1<<19)) != 0;
}

- (BOOL) sampleLogicIsBusy
{
    unsigned long aValue =  [self readLongFromAddress:[self singleRegister:kAcqControlStatusReg]];
    return (aValue & (0x1<<18)) != 0;
}

- (void) writeAcquisitionRegister
{   //******should be unsigned short (only 4-15 can write)******//
    int i;
    unsigned long valueToWrite = 0;
    for(i = 0; i < 12; i++) {
         valueToWrite |= (((acquisitionControlMask>>i) & 0x1) << (4 + i))  ;
     }
    [self writeLong:valueToWrite toAddress:[self singleRegister:kAcqControlStatusReg]];
}

- (void) readAcquisitionRegister:(BOOL)verbose
{
    NSString* acquisitionString[28] = {
        @"FP-Bus-In Ctrl 1 Trigger Enable                       ",
        @"FP-Bus-In Ctrl 1 Veto Enable                          ",
        @"FP-Bus-In Control 2 Enable                            ",
        @"FP-Bus-In Sample Control Enable                       ",
        @"External Trigger Enable                               ",
        @"External Trigger Veto                                 ",
        @"External Timestamp-Clear Enable                       ",
        @"Local Veto Function Veto Enable                       ",
        @"NIM TI Disarm Bankx Arm Bank                          ",
        @"NIM UI Disarm Bankx Arm Bank                          ",
        @"Internal Trigger as External Trigger Enable           ",
        @"External Trigger Disable with internal Busy select    ",
        @"ADC Sample Logic Armed                                ",
        @"ADC Sample Logic Armed On Bank2                       ",
        @"Sample Logic Busy (OR)                                ",
        @"Memory Address Threshold Flag (OR)                    ",
        @"FP-Bus-In Status 1: Sample Logic Busy                 ",
        @"FP-Bus-In Address Threshold Flag                      ",
        @"Smpl Bank Swap Cntrl NIM Input Logic Enabled          ",
        @"PPS Latch Bit                                         ",
        @"Sample logic Busy Ch 1-4                              ",
        @"Memory Address Threshold Flag Ch 1-4                  ",
        @"Sample logic Busy Ch 5-8                              ",
        @"Memory Address Threshold Flag Ch 15-8                 ",
        @"Sample logic Busy Ch 9-12                             ",
        @"Memory Address Threshold Flag Ch 9-12                 ",
        @"Sample logic Busy Ch 13-16                            ",
        @"Memory Address Threshold Flag Ch 13-16                ",
    };

    int i;
    if(verbose){
        NSLogFont([NSFont fontWithName:@"Monaco" size:12],@"Reading Acquisition Control Register:\n");
    }
    unsigned long aValue =  [self readLongFromAddress:[self singleRegister:kAcqControlStatusReg]];

    if(verbose){
        for(i =0; i < 28; i++) {
            unsigned long theAcquisitionControl  = ((aValue >> (i+4)) & 0x1);
            NSLogFont([NSFont fontWithName:@"Monaco" size:12], @"%2d: %@ %@ \n",i, acquisitionString[i], theAcquisitionControl?@"YES":@" NO");
        }
    }
}

//6.22 Trigger Coincidence Lookup Table Control register

//6.23 Trigger Coincidence Lookup Table Address register

//6.24 Trigger Coincidence Lookup Table Data register

//6.25 LEMO Out “CO” Select register
- (unsigned long) lemoCoMask { return lemoCoMask; }
- (void) setLemoCoMask:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoCoMask:lemoCoMask];
    lemoCoMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316LemoCoMaskChanged object:self];
}

- (void) writeLemoCoMask
{
    [self writeLong:lemoCoMask toAddress: [self singleRegister:kLemoOutCOSelectReg]];
}

//6.26 LEMO Out “TO” Select register
- (unsigned long) lemoToMask { return lemoToMask; }
- (void) setLemoToMask:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoToMask:lemoToMask];
    lemoToMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316LemoToMaskChanged object:self];
}

- (void) writeLemoToMask
{
    [self writeLong:lemoToMask toAddress: [self singleRegister:kLemoOutTOSelectReg]];
}

//6.27 LEMO Out “UO” Select register
- (unsigned long) lemoUoMask { return lemoUoMask; }
- (void) setLemoUoMask:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoUoMask:lemoUoMask];
    lemoUoMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316LemoUoMaskChanged object:self];
}

- (void) writeLemoUoMask
{
    [self writeLong:lemoUoMask toAddress: [self singleRegister:kLemoOutUOSelectReg]];
}

//6.28 Internal Trigger Feedback Select register

//6.29 ADC FPGA Data Transfer Control registers

//6.30 ADC FPGA Data Transfer Status registers

//pg 119 and on. section 2

//6.1 VME FPGA – ADC FPGA Data Link Status register (page 119 and on)

//6.2 ADC FPGA SPI BUSY Status register

//6.3 Prescaler Output Pulse Divider register

//6.4 Prescaler Output Pulse Length register

//6.5 Channel 1 to 16 Internal Trigger Counters

//6.6 ADC Input tap delay registers
- (void) setSharing:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSharing:sharing];
    sharing = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316SharingChanged object:self];
}
- (int) sharing
{
    return sharing;
}

- (void) setClockChoice:(int) clck_choice
{
    unsigned int iob_delay_value = 0 ;
    int return_code = 0;
    // set clock , wait 20ms in sis3316_adc1->set_frequency
    // reset DCM in sis3316_adc1->set_frequency
    switch (clck_choice) {
        case 0:
            return_code = [self setFrequency:0 values:freqPreset250MHz];
            iob_delay_value = 0x48 ;
            break;
        case 1:
            return_code = [self setFrequency:0 values:freqPreset125MHz];
            iob_delay_value = 0x48 ;
            break;
        case 2:
            return_code = [self setFrequency:0 values:freqPreset62_5MHz];
            iob_delay_value = 0x10 ;
            break;
        case 3:
            return_code = [self setFrequency:0 values:freqPreset125MHz];
            iob_delay_value = 0x48 ;
            break;
        case 4:
            return_code = [self setFrequency:0 values:freqPreset125MHz];
            iob_delay_value = 0x48 ;
            break;
        case 5:
            return_code = [self setFrequency:0 values:freqPreset125MHz];
            iob_delay_value = 0x48 ;
            break;
    }
    if(return_code){
        NSLog(@"%@:Error setting clock ERROR(%d)\n",[self fullID],return_code);
    }
    usleep(10000);
    int group;
    for(group=0;group<4;group++){
        unsigned long aValue = 0xf00;
        [self writeLong:aValue toAddress:[self groupRegister:kAdcInputTapDelayReg group:group]];
    }
    usleep(10000);
    for(group=0;group<4;group++){
        unsigned long aValue = 0x300 + iob_delay_value;
        [self writeLong:aValue toAddress:[self groupRegister:kAdcInputTapDelayReg group:group]];
    }
    usleep(10000) ;
    
// Setup clock sharing
    if(sharing == 2)        [self writeLong:0x11 toAddress:[self singleRegister:kFPBusControlReg]];   //master
    else if( sharing == 1 ) [self writeLong:0x0 toAddress:[self singleRegister:kFPBusControlReg]];    //slave

    if( sharing > 0 ){
        [self writeLong:0x02 toAddress:[self singleRegister:kAdcSampleClockDistReg]];
        usleep(20);
        [self writeLong:0x00 toAddress:[self singleRegister:kKeyAdcClockPllResetReg]];
    }
}

//6.7 ADC Gain and Termination Control register
- (unsigned short) gain
{
    return gain;
}

- (void) setGain:(unsigned short)aGain
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:gain];
    gain = aGain;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ModelGainChanged object:self];
}

- (unsigned short) termination
{
    return termination;
}

- (void) setTermination:(unsigned short)aTermination
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTermination:termination];
    termination = aTermination;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ModelTerminationChanged object:self];
}
- (void) writeGainAndTermination
{
    //for now use the same gain and termination for all channels
    unsigned long adata = 0;
    int iadc;
    for( iadc = 0; iadc<kNumSIS3316Groups; iadc++){
        adata = 0;
        for(int ic = 0; ic<kNumSIS3316ChansPerGroup; ic++){
            unsigned int         tdata = gain & 0x3;
            if(termination == 1) tdata = tdata | 0x4;
            adata = adata | (tdata<<(ic*8));
        }
        [self writeLong:adata toAddress:[self groupRegister:kAdcGainTermCntrlReg group:iadc]];
    }
}

//6.8 ADC Offset (DAC) Control registers
- (unsigned short) dacOffset:(unsigned short)aGroup
{
    if(aGroup>=kNumSIS3316Groups) return 0;
    else return dacOffsets[aGroup];
}

- (void) setDacOffset:(unsigned short)aGroup withValue:(int)aValue
{
    if(aGroup>=kNumSIS3316Groups) return;
    if(aValue<0)aValue      = 0;
    if(aValue>0xffff)aValue = 0xFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDacOffset:aGroup withValue:[self dacOffset:aGroup]];
    dacOffsets[aGroup] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316DacOffsetChanged object:self];
}

- (void) configureAnalogRegisters
{
    // set ADC chips via SPI
    int iadc;
    for (iadc=0;iadc<kNumSIS3316Groups;iadc++) {
        [self writeLong:0x81001404 toAddress:[self groupRegister:kAdcSpiControlReg group:iadc]]; // SPI (OE)  set binary
        usleep(1);
        [self writeLong:0x81401404 toAddress:[self groupRegister:kAdcSpiControlReg group:iadc]];// SPI (OE)  set binary
        usleep(1);
        [self writeLong:0x8100ff01 toAddress:[self groupRegister:kAdcSpiControlReg group:iadc]];// SPI (OE)  update
        usleep(1);
        [self writeLong:0x8140ff01 toAddress:[self groupRegister:kAdcSpiControlReg group:iadc]];// SPI (OE)  update
        usleep(1);
    }
    
    //  set ADC offsets (DAC)
    //dacoffset[iadc] = 0x8000; //2V Range: -1 to 1V 0x8000, -2V to 0V 13000
    for (iadc=0;iadc<kNumSIS3316Groups;iadc++) {
        [self writeLong:0x80000000 + 0x08000000 +  0x00f00000 + 0x1                         toAddress:[self groupRegister:kAdcOffsetDacCntrlReg group:iadc]]; // set internal Reference
        usleep(1);
        [self writeLong:0x80000000 + 0x02000000 +  0x00f00000 + ((dacOffsets[iadc] & 0xffff) << 4) toAddress:[self groupRegister:kAdcOffsetDacCntrlReg group:iadc]];// clear error Latch bits
        usleep(1);
        [self writeLong:0xC0000000                                                          toAddress:[self groupRegister:kAdcOffsetDacCntrlReg group:iadc]]; // clear error Latch bits
        usleep(1);
    }
}


//6.10 ADC SPI Control register

//6.11 ADC SPI Readback registers

//6.12 Event configuration registers


- (unsigned long) eventConfigMask             { return eventConfigMask;                        }
- (BOOL) eventConfig:(unsigned short)aGroup   { return (eventConfigMask & (0x1<<aGroup)) != 0; }

- (void) setEventConfigMask:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEventConfigMask:eventConfigMask];
    eventConfigMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EventConfigChanged object:self];
}

- (void) setEventConfigBit:(unsigned short)aGroup withValue:(BOOL)aValue
{
    long  aMask = eventConfigMask;
    if(aValue)      aMask |= (0x1<<aGroup);
    else            aMask &= ~(0x1<<aGroup);
    [self setEventConfigMask:aMask];
}

- (void) writeEventConfig
{
    int i;
    unsigned long valueToWrite = 0;
    for(i = 0; i < 4; i++) {
        valueToWrite |= eventConfigMask << (i*8);
    }
    
    for(i = 0; i < 4; i++) {
        [self writeLong:valueToWrite toAddress:[self groupRegister:kEventConfigReg group:i]];
    }
}
    
- (void) readEventConfig:(BOOL)verbose
{
    NSString* eventConfigString[8] = {
        @"Input Invert Bit     ",
        @"Internal SUM - Trigger ENable bit     ",
        @"Internal Trigger Enable bit           ",
        @"External Trigger Enable bit           ",
        @"Internal Gate 1 Enable bit            ",
        @"Internal Gate 2 Enable bit            ",
        @"External Gate Enable bit              ",
        @"External Veto Enable bit              ",
    };
    
    if(verbose){
        NSLog(@"Reading EventConfig:\n");
    }
    
    unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kEventConfigReg group:3]];

    int j;
    for(j =0; j < 8; j++) {
        
        if(verbose){
            unsigned long e1  = ((aValue >> j)   & 0x1);
            NSLog(@"%2d: %@ %@  \n",j, eventConfigString[j],e1?@"YES":@" NO");
        }
    }
    
}


//6.13 Extended Event configuration registers
- (BOOL) extendedEventConfigBit                 { return extendedEventConfigBit;}
- (void) setExtendedEventConfigBit:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setExtendedEventConfigBit:extendedEventConfigBit];
    extendedEventConfigBit = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ExtendedEventConfigChanged object:self];
}

- (void) writeExtendedEventConfig
{
    int i;
    unsigned long valueToWrite = 0;
    for(i = 0; i < 4; i++) {
        valueToWrite |= extendedEventConfigBit << (i*8);
    }
    
    for(i = 0; i < 4; i++) {
        [self writeLong:valueToWrite toAddress:[self groupRegister:kExtEventConfigCh1Ch4Reg group:i]];
     }
}

- (void) readExtendedEventConfig:(BOOL)verbose
{
    unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kExtEventConfigCh1Ch4Reg group:1]];
    
    if(verbose){
        unsigned long e1  = ((aValue >> 8)   & 0x1);
        NSLog(@"%2d: %@ \n",8, e1?@"Internal Pileup Trigger Enable     YES":@"Internal Pileup Trigger Enable     NO");
    }
}


//6.14 Channel Header ID registers

//6.15 End Address Threshold register

- (unsigned long) endAddress:(unsigned short)aGroup {if(aGroup<kNumSIS3316Groups)return endAddress[aGroup]; else return 0;}

- (void) setEndAddress:(unsigned short)aGroup withValue:(unsigned long)aValue
{
    if(aValue>0xFFFFFF)aValue = 0xFFFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setEndAddress:aGroup withValue:endAddress[aGroup]];
    endAddress[aGroup] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316EndAddressChanged object:self userInfo:userInfo];
}

- (unsigned long) endAddressSuppressionMask { return endAddressSuppressionMask; }

- (void) setEndAddressSuppressionMask:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEndAddressSuppressionMask:endAddressSuppressionMask];
    endAddressSuppressionMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EndAddressSuppressionChanged object:self];
}

- (void) setEndAddressSuppressionBit:(unsigned short)aGroup withValue:(BOOL)aValue
{
    long  aMask = endAddressSuppressionMask;
    if(aValue)      aMask |= (0x1<<aGroup);
    else            aMask &= ~(0x1<<aGroup);
    [self setEndAddressSuppressionMask:aMask];
}

- (void) writeEndAddress
{
    int i;
    for(i = 0; i <kNumSIS3316Groups; i++){
        unsigned long valueToWrite =    (endAddress[i]             & 0xFFFFFF) |
                                        (((endAddressSuppressionMask>>i) & 0x1) <<31);

        [self writeLong:valueToWrite toAddress:[self groupRegister:kEndAddressThresholdReg group:i]];
    }
}

- (void) readEndAddress:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading EndAddress:\n");
    }
    for(i = 0; i < kNumSIS3316Groups; i++){
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kEndAddressThresholdReg group:i]];
        if(verbose){
            unsigned long theEndAddress      = ((aValue)      & 0xFFFFFF) ;
            NSLog(@"%2d: 0x%06x\n ", i, theEndAddress);
        }
    }
}

//6.16 Active Trigger Gate Window Length registers
- (unsigned short) activeTrigGateWindowLen:(unsigned short)aGroup {
    if(aGroup<kNumSIS3316Groups)return activeTrigGateWindowLen[aGroup];
    else return 0;
}

- (void) setActiveTrigGateWindowLen:(unsigned short)aGroup withValue:(unsigned long)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue>0xffff)aValue = 0xffff;
    aValue &= ~0x0001;
    [[[self undoManager] prepareWithInvocationTarget:self] setActiveTrigGateWindowLen:aGroup withValue:[self activeTrigGateWindowLen:aGroup]];
    activeTrigGateWindowLen[aGroup] = aValue & 0xffff;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ActiveTrigGateWindowLenChanged object:self userInfo:userInfo];
}

- (void) writeActiveTrigGateWindowLen
{
    int i;
    for(i = 0; i < kNumSIS3316Groups; i++) {
        unsigned long valueToWrite = (activeTrigGateWindowLen[i] & 0xffff);
        [self writeLong:valueToWrite toAddress:[self groupRegister:kActTriggerGateWindowLenReg group:i]];
    }
}

- (void) readActiveTrigGateWindowLen:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading Active Trigger Gate Window Length:\n");
        NSLog(@"(bit 0 not used)\n");
    }
    for(i=0; i < kNumSIS3316Groups; i++){
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kActTriggerGateWindowLenReg group:i]];
        if(verbose){
            unsigned long gateLength = (aValue  & 0xffff) ;
            NSLog(@"%2d: 0x%08x\n", i, gateLength);
        }
    }
}

//6.17 Raw Data Buffer Configuration registers
- (unsigned long) rawDataBufferLen:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return rawDataBufferLen [aGroup];
}

- (void) setRawDataBufferLen:(unsigned short)aGroup withValue:(unsigned long)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue > 0xFFFF) aValue = 0xFFFF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setRawDataBufferLen:aGroup withValue:[self rawDataBufferLen:aGroup]];
    rawDataBufferLen[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316RawDataBufferLenChanged object:self userInfo:userInfo];
}

- (unsigned long) rawDataBufferStart:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return rawDataBufferStart[aGroup];
}

- (void) setRawDataBufferStart:(unsigned short)aGroup withValue:(unsigned long)aValue
{
    if(aGroup>kNumSIS3316Groups)  return;
    if(aValue > 0xFFFF) aValue = 0xFFFF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setRawDataBufferStart:aGroup withValue:[self rawDataBufferStart:aGroup]];
    rawDataBufferStart[aGroup]=aValue;
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316RawDataBufferStartChanged object:self userInfo:userInfo];
}

- (void) writeRawDataBufferConfig
{
    int i;
    for(i = 0; i < kNumSIS3316Groups; i++) {
        unsigned long valueToWrite =
                                        ([self rawDataBufferLen:i]      << 16)  |
                                        ([self rawDataBufferStart:i])   << 0    ;
        [self writeLong:valueToWrite toAddress:[self groupRegister:kRawDataBufferConfigReg group:i]];
    }
}

- (void) readRawDataBufferConfig:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading Raw Data Buffer Config Sum:\n");
        NSLog(@"rawDataLen rawDataStart:\n");
    }
    for(i = 0; i < kNumSIS3316Groups; i++){
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kRawDataBufferConfigReg group:i]];
        if(verbose){
            unsigned long rawDataLen   =    ((aValue >> 16) & 0xFFFF);
            unsigned long rawDataStart =    ((aValue >> 0 ) & 0xFFFF);
            NSLog(@"%2d: 0x%04x 0x%04x\n", i, rawDataLen, rawDataStart);
        }
    }
}

//6.18 Pileup Configuration registers

//6.19 Pre Trigger Delay registers
- (unsigned short) preTriggerDelay:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return preTriggerDelay[aGroup];
}

- (void) setPreTriggerDelay:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<2)aValue = 2;
    if(aValue> 0x7FA)aValue = 0x7FA;
    aValue &= ~0x0001;
    [[[self undoManager] prepareWithInvocationTarget:self] setPreTriggerDelay:aGroup withValue:[self preTriggerDelay:aGroup]];
    preTriggerDelay[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316PreTriggerDelayChanged object:self userInfo:userInfo];
}

- (void) writePreTriggerDelays
{
    unsigned long preTriggerDelayPGBit = 0x1; //hardcoded for now
    int i;
    for(i = 0; i < kNumSIS3316Groups; i++) {
        unsigned long valueToWrite = (preTriggerDelayPGBit << 15) | (([self preTriggerDelay:i] & 0x7FA) << 1) ;
        [self writeLong:valueToWrite toAddress:[self groupRegister:kPreTriggerDelayReg group:i]];
    }
}

- (void) readPreTriggerDelays:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading Pre Trigger Delays:\n");
    }
    for(i =0; i < kNumSIS3316Groups; i++) {
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kPreTriggerDelayReg group:i]];
         if(verbose){
            unsigned long thePreTriggerDelays   = ((aValue >> 0x1) & 0x7FA)  ;
            NSLog(@"%2d: 0x%08x\n",i, thePreTriggerDelays);
        }
    }
}

//6.20 Average Configuration registers

//6.21 Data Format Configuration registers
- (void) writeDataFormat
{
    int i;
    for(i=0;i<kNumSIS3316Groups;i++){
        unsigned long aValue = 0x05050505;//<<<<<<<---------hard coded for now---------------
        [self writeLong:aValue toAddress:[self groupRegister:kDataFormatConfigReg group:i]];
     }
}

//6.22 MAW Test Buffer Configuration registers

//6.23 Internal Trigger Delay Configuration registers
- (unsigned short) triggerDelay:(unsigned short)aChan {if(aChan<kNumSIS3316Channels)return triggerDelay[aChan]; else return 0;}


- (void) setTriggerDelay:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue>0xFF)aValue = 0xFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerDelay:aChan withValue:triggerDelay[aChan]];
    triggerDelay[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316TriggerDelayChanged object:self userInfo:userInfo];
}

- (void) writeTriggerDelay
{
    int i;
    for(i = 0; i <kNumSIS3316Groups; i++){
        unsigned long aValue =    (triggerDelay[i*4]     & 0xFF)          |
                                        ((triggerDelay[i*4+1]  & 0xFF) << 8 )   |
                                        ((triggerDelay[i*4+2]  & 0xFF) << 16)   |
                                        ((triggerDelay[i*4+3]  & 0xFF) << 24)   ;
        
        [self writeLong:aValue toAddress:[self groupRegister:kInternalTrigDelayConfigReg group:i]];
    }
}

- (void) readTriggerDelay:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading Trigger Delay:\n");
        NSLog(@"Ch 1-4     5-8     9-12    13-16:\n");
    }
    for(i = 0; i < kNumSIS3316Groups; i++){
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kInternalTrigDelayConfigReg group:i]];
        if(verbose){
            unsigned long theTriggerDelay    = ((aValue >> 0 ) & 0xFF);
            unsigned long theTriggerDelayTwo = ((aValue >> 8 ) & 0xFF);
            unsigned long theTriggerDelay3   = ((aValue >> 16) & 0xFF);
            unsigned long theTriggerDelay4   = ((aValue >> 24) & 0xFF);
            NSLog(@"%2d: 0x%03x 0x%03x 0x%03x 0x%03x\n", i, theTriggerDelay, theTriggerDelayTwo, theTriggerDelay3, theTriggerDelay4);
        }
    }
}

//6.24 Internal Gate Length Configuration registers



//6.26 Trigger Threshold registers

NSString* cfdCntrlString[4] = {
    @"Disabled     ",
    @"Disabled     ",
    @"Zero Crossing",
    @"50%          "
};

- (long) enabledMask                                { return enabledMask;                              }
- (BOOL) enabled:(unsigned short)chan               { return (enabledMask & (0x1<<chan)) != 0;           }
- (long) heSuppressTriggerMask                      { return heSuppressTriggerMask;                    }
- (BOOL) heSuppressTriggerBit:(unsigned short)chan  { return (heSuppressTriggerMask & (0x1<<chan)) != 0; }

- (unsigned short) cfdControlBits:(unsigned short)aChan       { if(aChan<kNumSIS3316Channels)return cfdControlBits[aChan]; else return 0; }

- (void) setCfdControlBits:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aValue>0x2)aValue = 0x2;
    [[[self undoManager] prepareWithInvocationTarget:self] setCfdControlBits:aChan withValue:[self cfdControlBits:aChan]];
    cfdControlBits[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316CfdControlBitsChanged object:self userInfo:userInfo];
}



- (long) threshold:(unsigned short)aChan            { if(aChan<kNumSIS3316Channels)return threshold[aChan];      else return 0;}
- (unsigned long) thresholdSum:(unsigned short)aGroup {if(aGroup<kNumSIS3316Groups)return thresholdSum[aGroup]; else return 0;}

- (void) setEnabledMask:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabledMask:enabledMask];
    enabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EnabledChanged object:self];
}

- (void) setEnabledBit:(unsigned short)chan withValue:(BOOL)aValue
{
    long  aMask = enabledMask;
    if(aValue) aMask |=  (0x1<<chan);
    else       aMask &= ~(0x1<<chan);
    [self setEnabledMask:aMask];
}

- (void) setHeSuppressTriggerMask:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHeSuppressTriggerMask:heSuppressTriggerMask];
    heSuppressTriggerMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HeSuppressTrigModeChanged object:self];
}

- (void) setHeSuppressTriggerBit:(unsigned short)chan withValue:(BOOL)aValue
{
    unsigned short aMask = heSuppressTriggerMask;
    if(aValue) aMask |= (0x1<<chan);
    else       aMask &= ~(0x1<<chan);
    [self setHeSuppressTriggerMask:aMask];
}

- (void) setThreshold:(unsigned short)aChan withValue:(long)aValue
{
    if(aValue<0)aValue = 0;
    if(aValue>0xFFFFFFF)aValue = 0xFFFFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:threshold[aChan]];
    threshold[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ThresholdChanged object:self userInfo:userInfo];
    
}

- (void) setThresholdSum:(unsigned short)aGroup withValue:(unsigned long)aValue
{
    if(aValue>0xFFFFFFFF)aValue = 0xFFFFFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setThresholdSum:aGroup withValue:thresholdSum[aGroup]];
    thresholdSum[aGroup] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316ThresholdSumChanged object:self userInfo:userInfo];
}


- (BOOL) enableSum:(unsigned short)aGroup
{
    if(aGroup < kNumSIS3316Groups){
        return enableSum[aGroup];
    }
    else return 0;
}

- (void) setEnableSum:(unsigned short)aGroup withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableSum:aGroup withValue:enableSum[aGroup]];
    enableSum[aGroup] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316EnableSumChanged object:self userInfo:userInfo];
}

- (unsigned long) riseTimeSum:(unsigned short)aGroup
{
    if(aGroup < kNumSIS3316Groups){
        return riseTimeSum[aGroup];
    }
    else return 0;
}

- (void) setRiseTimeSum:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aValue>0xFFF)aValue = 0xFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setRiseTimeSum:aGroup withValue:riseTimeSum[aGroup]];
    riseTimeSum[aGroup] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316RiseTimeSumChanged object:self userInfo:userInfo];
}

- (unsigned long) gapTimeSum:(unsigned short)aGroup
{
    if(aGroup < kNumSIS3316Groups){
        return gapTimeSum[aGroup];
    }
    else return 0;
}

- (void) setGapTimeSum:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aValue>0xFFF)aValue = 0xFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setGapTimeSum:aGroup withValue:gapTimeSum[aGroup]];
    gapTimeSum[aGroup] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316GapTimeSumChanged object:self userInfo:userInfo];
}

- (unsigned short) cfdControlBitsSum:(unsigned short)aGroup
{
    if(aGroup < kNumSIS3316Groups){
        return cfdControlBitsSum[aGroup];
    }
    else return 0;
}

- (void) setCfdControlBitsSum:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aValue>2)aValue = 0xFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setCfdControlBitsSum:aGroup withValue:cfdControlBitsSum[aGroup]];
    cfdControlBitsSum[aGroup] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORSIS3316CfdControlBitsSumChanged object:self userInfo:userInfo];
}

//Configure FIR
//peakingtime and gaptime
//6.25 FIR Trigger Setup registers
- (void) configureFIR
{
#define kSIS3316FpgaAdcRegOffset 0x1000

    unsigned int FIR_register_addresses[16] = { 0x1040, 0x1050, 0x1060, 0x1070,
                                                0x2040, 0x2050, 0x2060, 0x2070,
                                                0x3040, 0x3050, 0x3060, 0x3070,
                                                0x4040, 0x4050, 0x4060, 0x4070 };
    
    unsigned int high_energy_trigger_configuration_addresses[16] = { 0x1048, 0x1058, 0x1068, 0x1078,
                                                                     0x2048, 0x2058, 0x2068, 0x2078,
                                                                     0x3048, 0x3058, 0x3068, 0x3078,
                                                                     0x4048, 0x4058, 0x4068, 0x4078 };
    unsigned int addr;
    unsigned int data;
    // set FIR Trigger Setup
    int ichan;
    for (ichan=0;ichan<kNumSIS3316Channels;ichan++) {
        addr = [self baseAddress] + FIR_register_addresses[ichan];
        [self writeLong:0 toAddress:addr];
        [self writeLong:(riseTime[ichan]&0xFFF) | ((gapTime[ichan]&0xFFF) << 12) toAddress:addr];
        
        //FIR Thresh
        addr = [self baseAddress] + ((ichan/kNumSIS3316ChansPerGroup) + 1)*kSIS3316FpgaAdcRegOffset + 0x10*(ichan%kNumSIS3316ChansPerGroup) + 0x44;
        data=   ([self enabled:ichan] << 31)                |
                ([self heSuppressTriggerBit:ichan] << 30)   |
                ((0x3 & cfdControlBits[ichan]) << 28 )      |
                (0x08000000 +  threshold[ichan]);
        [self writeLong:data toAddress:addr];
        
        //High Energy Threshold
        addr = [self baseAddress] + high_energy_trigger_configuration_addresses[ichan];
        data = (((trigBothEdgesMask >> ichan) && 0x1) << 31) |
                ([self intHeTrigOutPulseBit:ichan] << 28)    |
                (0xFFFFFFF & heTrigThreshold[ichan]);
        [self writeLong:data toAddress:addr];
    }
    
    // set FIR Block Trigger Setup
    int iadc;
    for (iadc=0;iadc<kNumSIS3316Groups;iadc++) {
        // sum dir trigger setup
        addr = [self baseAddress] + (iadc + 1)*kSIS3316FpgaAdcRegOffset + 0x80;
        [self writeLong:0 toAddress:addr];
        [self writeLong:(riseTimeSum[iadc]&0xFFF) | ((gapTimeSum[iadc]&0xFFF) << 12) toAddress:addr];

        //FIR Thresh
        addr = [self baseAddress] + (iadc + 1)*kSIS3316FpgaAdcRegOffset + 0x84;
        data= ((0x1 & enableSum[iadc]) << 31)                   |
              ((0x1 & [self heSuppressTriggerBit:iadc]) << 30)  |
              ((0x3 & cfdControlBitsSum[iadc]) << 28 )          |
              (0x08000000 + (riseTimeSum[iadc] * thresholdSum[iadc]) );
        [self writeLong:data toAddress:addr];

        //High Energy Threshold
        addr = [self baseAddress] + (iadc + 1)*kSIS3316FpgaAdcRegOffset + 0x88;
        data = 0xFFF & heTrigThresholdSum[iadc];
        [self writeLong:data toAddress:addr];

//        addr = [self baseAddress]
//        + kSIS3316FpgaAdcRegOffset*iadc
//        + SIS3316_ADC_CH1_4_TRIGGER_STATISTIC_COUNTER_MODE_REG;
//        data=triggerstatmode_block[iadc];
//        [self writeLong:data toAddress:addr];
    }
    
    
}

- (void) writeFirTriggerSetup
{
    int i;
    for(i = 0; i < kNumSIS3316Channels; i++) {
        unsigned long aValue =  (([self gapTime:i] & 0xFFF) << 12) | ([self riseTime:i] & 0xFFF);
        [self writeLong:aValue toAddress:[self channelRegister:kFirTrigSetupCh1Reg channel:i]];
    }
}

- (void) writeThresholds
{
    int i;
    for(i = 0; i < kNumSIS3316Channels; i++) {
        unsigned long aValue =  ((unsigned long)((enabledMask>>i)           & 0x1) << 31)  |
                                (((heSuppressTriggerMask>>i) & 0x1) << 30)  |
                                ((cfdControlBits[i]+1        & 0x3) << 28)  |
                                (0x08000000 + (riseTime[i] * threshold[i]));
        [self writeLong:aValue toAddress:[self channelRegister:kTrigThresholdCh1Reg channel:i]];
    }
}

- (void) writeHeTrigThresholds
{
    int i;
    for(i = 0; i < kNumSIS3316Channels; i++) {
        unsigned long aValue  = ((unsigned long)((trigBothEdgesMask>>i)      & 0x1) << 31)  |
        //(((intHeTrigOutPulseMask>>i)  & 0x1) << 30)  |
        (([self intTrigOutPulseBit:i] & 0x3) << 28)  |
        ([self heTrigThreshold:i]     & 0xfffffff);
        [self writeLong:aValue toAddress:[self channelRegister:kHiEnergyTrigThresCh1Reg channel:i]];
    }
}

- (void) writeHeTrigThresholdSum
{
    int i;
    for( i = 0; i<kNumSIS3316Groups; i++){
        unsigned long aValue = ([self heTrigThresholdSum:i] & 0xFFF);
        [self writeLong:aValue toAddress:[self groupRegister:kHiETrigThresSumCh1Ch4Reg group:i]];
    }
}
//??????????
//-----------------------------

- (void) writeThresholdSum
{
    int i;
    for(i = 0; i <kNumSIS3316Groups; i++){
        unsigned long data= ((0x1 & enableSum[i]) << 31)                   |
                            ((0x1 & [self heSuppressTriggerBit:i]) << 30)  |
                            ((0x3 & cfdControlBitsSum[i]) << 28 )          |
                             (0x08000000 + (riseTimeSum[i] * thresholdSum[i]) );
        [self writeLong:data toAddress:[self groupRegister:kTrigThreholdSumCh1Ch4Reg group:i]];
    }
}

- (void) readThresholds:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading Thresholds:\n");
        NSLogFont([NSFont fontWithName:@"Monaco" size:12],@"Chan Enabled HESupp CFD Threshold \n");
    }
    for(i =0; i < kNumSIS3316Channels; i++) {
        unsigned long aValue =  [self readLongFromAddress:[self channelRegister:kTrigThresholdCh1Reg channel:i]];
         if(verbose){
            unsigned long thres  = (aValue & 0x0FFFFFFF);
            unsigned long cfdCnt = ((aValue>>28) & 0x3);
            unsigned long heSup  = ((aValue>>30) & 0x1);
            unsigned long enabl  = ((aValue>>31) & 0x1);
            NSLogFont([NSFont fontWithName:@"Monaco" size:12],@"%2d: %@ %@ %@ 0x%08x\n",i, enabl?@"YES":@" NO",heSup?@"YES":@" NO",cfdCntrlString[cfdCnt],thres);
        }
    }
}

- (void) readThresholdSum:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading Threshold Sum:\n");
    }
    for(i = 0; i < kNumSIS3316Groups; i++){
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kTrigThreholdSumCh1Ch4Reg group:i]];
        if(verbose){
            unsigned long threshSum = (aValue & 0xFFFFFFFF);
            NSLog(@"%2d: 0x%08x\n", i, threshSum);
        }
    }
}

//6.27 High Energy Trigger Threshold registers
NSString* intTrigOutPulseString[3] = {
    @"Internal    ",
    @"High Energy ",
    @"Pileup Pulse"
};

- (unsigned long) heTrigThreshold:(unsigned short)aChan      { return heTrigThreshold[aChan];                    }
- (unsigned long) heTrigThresholdSum:(unsigned short)aGroup  {if(aGroup<kNumSIS3316Groups)return heTrigThresholdSum[aGroup]; else return 0;}

- (long) trigBothEdgesMask                                   { return trigBothEdgesMask;                         }
- (BOOL) trigBothEdgesBit:(unsigned short)chan              { return (trigBothEdgesMask     & (0x1<<chan)) != 0;}

- (long) intHeTrigOutPulseMask                               { return intHeTrigOutPulseMask;                     }
- (BOOL) intHeTrigOutPulseBit:(unsigned short)chan          { return (intHeTrigOutPulseMask & (0x1<<chan)) != 0;}

- (unsigned short) intTrigOutPulseBit:(unsigned short)aChan  { return intTrigOutPulseBit[aChan];                 }

- (void) setHeTrigThreshold:(unsigned short)aChan withValue:(unsigned long)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue>0xFFFFFFF)aValue = 0xFFFFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setHeTrigThreshold:aChan withValue:[self heTrigThreshold:aChan]];
    heTrigThreshold[aChan] =aValue;
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HeTrigThresholdChanged object:self userInfo:userInfo];
}

- (void) setHeTrigThresholdSum:(unsigned short)aGroup withValue:(unsigned long)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue>0xFFFFFFFF)aValue = 0xFFFFFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setHeTrigThresholdSum:aGroup withValue:[self heTrigThresholdSum:aGroup]];
    heTrigThresholdSum[aGroup] = aValue;
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HeTrigThresholdSumChanged object:self userInfo:userInfo];
}

- (void) setTrigBothEdgesMask:(unsigned long)aMask
{
    if(trigBothEdgesMask == aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigBothEdgesMask:trigBothEdgesMask];
    trigBothEdgesMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316TrigBothEdgesChanged object:self];
    
}

- (void) setTrigBothEdgesBit:(unsigned short)aChan withValue:(BOOL)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    unsigned short  aMask  = trigBothEdgesMask;
    if(aValue)      aMask |= (0x1<<aChan);
    else            aMask &= ~(0x1<<aChan);
    [self setTrigBothEdgesMask:aMask];
}

- (void) setIntHeTrigOutPulseMask:(unsigned long)aMask
{
    if(intHeTrigOutPulseMask == aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setIntHeTrigOutPulseMask:intHeTrigOutPulseMask];
    intHeTrigOutPulseMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316IntHeTrigOutPulseChanged object:self];
}

- (void) setIntHeTrigOutPulseBit:(unsigned short)aChan withValue:(BOOL)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    unsigned short   aMask  = intHeTrigOutPulseMask;
    if(aValue)      aMask |= (0x1<<aChan);
    else            aMask &= ~(0x1<<aChan);
    [self setIntHeTrigOutPulseMask:aMask];
}

- (void) setIntTrigOutPulseBit:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    
    if(aValue>0x3)aValue = 0x3;
    if(intTrigOutPulseBit[aChan] == aValue)return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setIntTrigOutPulseBit:aChan withValue:[self intTrigOutPulseBit:aChan]];
    intTrigOutPulseBit[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316IntTrigOutPulseBitsChanged object:self userInfo:userInfo];
}

- (void) readHeTrigThresholds:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading High Energy Thresholds:\n");
        NSLog(@"Chan BothEdges IntHETrigOut IntTrigOut HEThreshold \n");
    }
    for(i =0; i < kNumSIS3316Channels; i++) {
        unsigned long aValue =  [self readLongFromAddress:[self channelRegister:kHiEnergyTrigThresCh1Reg channel:i]];
        if(verbose){
            unsigned long heThres  = (aValue & 0x0FFFFFFF);
            unsigned short intTrigOut = ((aValue>>28) & 0x3);
            unsigned short intHETrigOut  = ((aValue>>30) & 0x1);
            unsigned short both  = ((aValue>>31) & 0x1);
            if(intTrigOut>2)NSLogFont([NSFont fontWithName:@"Monaco" size:12],@"%2d: %@ %@ %@ 0x%08x\n",i, both?@"YES":@" NO",intHETrigOut?@"YES":@" NO",@"reserved",heThres);
            else NSLogFont([NSFont fontWithName:@"Monaco" size:12],@"%2d: %@ %@ %@ 0x%08x\n",i, both?@"YES":@" NO",intHETrigOut?@"YES":@" NO",intTrigOutPulseString[intTrigOut],heThres);
        }
    }
}

- (void) readHeTrigThresholdSum:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading High Energy Threshold Sum:\n");
    }
    for(i = 0; i < kNumSIS3316Groups; i++){
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kHiETrigThresSumCh1Ch4Reg group:i]];
        if(verbose){
            unsigned short heTrigThreshSum = (aValue & 0xFFFFFFFF);
            NSLog(@"%2d:  0x%08x\n",i, heTrigThreshSum);
        }
    }
}

//6.28 Trigger Statistic Counter Mode register

//6.29 Peak/Charge Configuration registers

//6.30 Extended Raw Data Buffer Configuration registers

//6.31 Accumulator Gate X Configuration registers
//----Accumlator gate1
- (unsigned short) accGate1Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate1Start[aGroup];
}

- (void) setAccGate1Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0x200)aValue = 0x200;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate1Start:aGroup withValue:[self accGate1Start:aGroup]];
    accGate1Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate1StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate1Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate1Len[aGroup];
}

- (void) setAccGate1Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate1Len:aGroup withValue:[self accGate1Len:aGroup]];
    accGate1Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate1LenChanged object:self userInfo:userInfo];
}

//----Accumlator gate2
- (unsigned short) accGate2Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate2Start[aGroup];
}

- (void) setAccGate2Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0x200)aValue = 0x200;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate2Start:aGroup withValue:[self accGate2Start:aGroup]];
    accGate2Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate2StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate2Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate2Len[aGroup];
}

- (void) setAccGate2Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate2Len:aGroup withValue:[self accGate2Len:aGroup]];
    accGate2Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate2LenChanged object:self userInfo:userInfo];
}

//----Accumlator gate3
- (unsigned short) accGate3Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate3Start[aGroup];
}

- (void) setAccGate3Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0x200)aValue = 0x200;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate3Start:aGroup withValue:[self accGate3Start:aGroup]];
    accGate3Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate3StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate3Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate3Len[aGroup];
}

- (void) setAccGate3Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate3Len:aGroup withValue:[self accGate3Len:aGroup]];
    accGate3Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate3LenChanged object:self userInfo:userInfo];
}

//----Accumlator gate4
- (unsigned short) accGate4Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate4Start[aGroup];
}

- (void) setAccGate4Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0x200)aValue = 0x200;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate4Start:aGroup withValue:[self accGate4Start:aGroup]];
    accGate4Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate4StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate4Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate4Len[aGroup];
}

- (void) setAccGate4Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate4Len:aGroup withValue:[self accGate4Len:aGroup]];
    accGate4Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate4LenChanged object:self userInfo:userInfo];
}

//----Accumlator gate5
- (unsigned short) accGate5Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate5Start[aGroup];
}

- (void) setAccGate5Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0x200)aValue = 0x200;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate5Start:aGroup withValue:[self accGate5Start:aGroup]];
    accGate5Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate5StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate5Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate5Len[aGroup];
}

- (void) setAccGate5Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate5Len:aGroup withValue:[self accGate5Len:aGroup]];
    accGate5Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate5LenChanged object:self userInfo:userInfo];
}

//----Accumlator gate6
- (unsigned short) accGate6Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate6Start[aGroup];
}

- (void) setAccGate6Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0x200)aValue = 0x200;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate6Start:aGroup withValue:[self accGate6Start:aGroup]];
    accGate6Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate6StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate6Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate6Len[aGroup];
}

- (void) setAccGate6Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate6Len:aGroup withValue:[self accGate6Len:aGroup]];
    accGate6Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate6LenChanged object:self userInfo:userInfo];
}

//----Accumlator gate7
- (unsigned short) accGate7Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate7Start[aGroup];
}

- (void) setAccGate7Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0x200)aValue = 0x200;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate7Start:aGroup withValue:[self accGate7Start:aGroup]];
    accGate7Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate7StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate7Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate7Len[aGroup];
}

- (void) setAccGate7Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate7Len:aGroup withValue:[self accGate7Len:aGroup]];
    accGate7Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate7LenChanged object:self userInfo:userInfo];
}

//----Accumlator gate8
- (unsigned short) accGate8Start:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate8Start[aGroup];
}

- (void) setAccGate8Start:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0x200)aValue = 0x200;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate8Start:aGroup withValue:[self accGate8Start:aGroup]];
    accGate8Start[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate8StartChanged object:self userInfo:userInfo];
}

- (unsigned short) accGate8Len:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accGate8Len[aGroup];
}

- (void) setAccGate8Len:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccGate8Len:aGroup withValue:[self accGate8Len:aGroup]];
    accGate8Len[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccGate8LenChanged object:self userInfo:userInfo];
}

//--------------------------------------------------------------
- (unsigned short) accumulatorGateStart:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accumulatorGateStart[aGroup];
}

- (void) setAccumulatorGateStart:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<1)aValue = 1;
    if(aValue>0x200)aValue = 0x200;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccumulatorGateStart:aGroup withValue:[self accumulatorGateStart:aGroup]];
    accumulatorGateStart[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccumulatorGateStartChanged object:self userInfo:userInfo];
}


- (unsigned short) accumulatorGateLength:(unsigned short)aGroup
{
    if(aGroup>kNumSIS3316Groups)return 0;
    else return accumulatorGateLength[aGroup];
}

- (void) setAccumulatorGateLength:(unsigned short)aGroup withValue:(unsigned short)aValue
{
    if(aGroup>kNumSIS3316Groups)return;
    if(aValue<0)aValue = 0;
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAccumulatorGateLength:aGroup withValue:[self accumulatorGateLength:aGroup]];
    accumulatorGateLength[aGroup]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aGroup] forKey:@"Group"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316AccumulatorGateLengthChanged object:self userInfo:userInfo];
}

- (void) writeAccumulatorGates
{
    int i;
    
    for(i = 0; i < kNumSIS3316Groups; i++) {
        unsigned long valueToWrite1 = (([self accGate1Len:i]     & 0x1FF) << 16 )     |
                                      (([self accGate1Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite1 toAddress:[self groupRegister:kAccGate1ConfigReg group:i]];
        
        unsigned long valueToWrite2 = (([self accGate2Len:i]     & 0x1FF) << 16 )     |
                                      (([self accGate2Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite2 toAddress:[self groupRegister:kAccGate2ConfigReg group:i]];
       
        unsigned long valueToWrite3 = (([self accGate3Len:i]     & 0x1FF) << 16 )     |
                                      (([self accGate3Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite3 toAddress:[self groupRegister:kAccGate3ConfigReg group:i]];
        
        unsigned long valueToWrite4 = (([self accGate4Len:i]     & 0x1FF) << 16 )     |
                                      (([self accGate4Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite4 toAddress:[self groupRegister:kAccGate4ConfigReg group:i]];

        unsigned long valueToWrite5 = (([self accGate5Len:i]     & 0x1FF) << 16 )     |
                                      (([self accGate5Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite5 toAddress:[self groupRegister:kAccGate5ConfigReg group:i]];
        
        unsigned long valueToWrite6 = (([self accGate6Len:i]     & 0x1FF) << 16 )     |
                                      (([self accGate6Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite6 toAddress:[self groupRegister:kAccGate6ConfigReg group:i]];
        
        unsigned long valueToWrite7 = (([self accGate7Len:i]     & 0x1FF) << 16 )     |
                                      (([self accGate7Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite7 toAddress:[self groupRegister:kAccGate7ConfigReg group:i]];
       
        unsigned long valueToWrite8 = (([self accGate8Len:i]     & 0x1FF) << 16 )     |
                                      (([self accGate8Start:i]   & 0xFFFF) << 0 );
        [self writeLong:valueToWrite8 toAddress:[self groupRegister:kAccGate8ConfigReg group:i]];
    }
}

- (void) readAccumulatorGates:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading Accumulator Gates Configuration:\n");
        NSLog(@"gate1Len gate1Start:\n");
    }
    for(i =0; i < kNumSIS3316Groups; i++) {
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kAccGate1ConfigReg group:i]];
        if(verbose){
            unsigned long gate1Len      = ((aValue >> 16) & 0x1FF)  ;
            unsigned long gate1Start    = ((aValue >> 0 ) & 0xFFFF)  ;
           
            NSLog(@"%2d: 0x%03x 0x%03x \n ",i, gate1Len, gate1Start)  ;
        }
    }
//---------------------------------------------------------------------
    if(verbose)NSLog(@"gate2Len gate2Start:\n");
    for(i =0; i < kNumSIS3316Groups; i++) {
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kAccGate2ConfigReg group:i]];
        if(verbose){
            unsigned long gate2Len      = ((aValue >> 16) & 0x1FF)  ;
            unsigned long gate2Start    = ((aValue >> 0 ) & 0xFFFF)  ;
            NSLog(@"%2d: 0x%03x 0x%03x \n ",i, gate2Len, gate2Start)  ;
        }
    }
//---------------------------------------------------------------------
    if(verbose)NSLog(@"gate3Len gate3Start:\n");
    for(i =0; i < kNumSIS3316Groups; i++) {
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kAccGate3ConfigReg group:i]];
        if(verbose){
            unsigned long gate3Len      = ((aValue >> 16) & 0x1FF)  ;
            unsigned long gate3Start    = ((aValue >> 0 ) & 0xFFFF)  ;
            NSLog(@"%2d: 0x%03x 0x%03x \n ",i, gate3Len, gate3Start)  ;
        }
    }
//--------------------------------------------------------------------
    if(verbose)NSLog(@"gate4Len gate4Start:\n");
    for(i =0; i < kNumSIS3316Groups; i++) {
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kAccGate4ConfigReg group:i]];
        if(verbose){
            unsigned long gate4Len      = ((aValue >> 16) & 0x1FF)  ;
            unsigned long gate4Start    = ((aValue >> 0 ) & 0xFFFF)  ;
            NSLog(@"%2d: 0x%03x 0x%03x \n ",i, gate4Len, gate4Start)  ;
        }
    }
//---------------------------------------------------------------------
    if(verbose)NSLog(@"gate5Len gate5Start:\n");
    for(i =0; i < kNumSIS3316Groups; i++) {
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kAccGate5ConfigReg group:i]];
          if(verbose){
             unsigned long gate5Len      = ((aValue >> 16) & 0x1FF)  ;
             unsigned long gate5Start    = ((aValue >> 0 ) & 0xFFFF)  ;
             NSLog(@"%2d: 0x%03x 0x%03x \n ",i, gate5Len, gate5Start)  ;
         }
    }
//--------------------------------------------------------------------
    if(verbose)NSLog(@"gate6Len gate6Start:\n");
    for(i =0; i < kNumSIS3316Groups; i++) {
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kAccGate6ConfigReg group:i]];
        if(verbose){
            unsigned long gate6Len      = ((aValue >> 16) & 0x1FF)  ;
            unsigned long gate6Start    = ((aValue >> 0 ) & 0xFFFF)  ;
            NSLog(@"%2d: 0x%03x 0x%03x \n ",i, gate6Len, gate6Start)  ;
        }
    }
//--------------------------------------------------------------------
    if(verbose)NSLog(@"gate7Len gate7Start:\n");
    for(i =0; i < kNumSIS3316Groups; i++) {
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kAccGate7ConfigReg group:i]];
        if(verbose){
            unsigned long gate7Len      = ((aValue >> 16) & 0x1FF)  ;
            unsigned long gate7Start    = ((aValue >> 0 ) & 0xFFFF)  ;
            NSLog(@"%2d: 0x%03x 0x%03x \n ",i, gate7Len, gate7Start)  ;
        }
    }
//---------------------------------------------------------------------
    if(verbose)NSLog(@"gate8Len gate8Start:\n");
    for(i =0; i < kNumSIS3316Groups; i++) {
        unsigned long aValue =  [self readLongFromAddress:[self groupRegister:kAccGate8ConfigReg group:i]];
       if(verbose){
           unsigned long gate8Len      = ((aValue >> 16) & 0x1FF)  ;
           unsigned long gate8Start    = ((aValue >> 0 ) & 0xFFFF)  ;
           NSLog(@"%2d: 0x%03x 0x%03x \n ",i, gate8Len, gate8Start)  ;
       }
    }
//--------------------------------------------------------------------
}

//6.32 FIR Energy Setup registers
NSString* extraFilter[4] = {
    @"None          ",
    @"Average of 4  ",
    @"Average of 8  ",
    @"Average of 16 "
};

NSString* tauTable[4] ={
    @"0",
    @"1",
    @"2",
    @"3",
};

- (long) extraFilterBits:(unsigned short)aChan       { if(aChan<kNumSIS3316Channels)return extraFilterBits[aChan]; else return 0; }

- (long) tauTableBits:(unsigned short)aChan       { if(aChan<kNumSIS3316Channels)return tauTableBits[aChan]; else return 0; };

- (void) setExtraFilterBits:(unsigned short)aChan withValue:(long)aValue
{
    if(aValue<0)aValue = 0;
    if(aValue>0x3)aValue = 0x3;
    [[[self undoManager] prepareWithInvocationTarget:self] setExtraFilterBits:aChan withValue:[self extraFilterBits:aChan]];
    extraFilterBits[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ExtraFilterBitsChanged object:self userInfo:userInfo];
}

- (void) setTauTableBits:(unsigned short)aChan withValue:(long)aValue
{
    if(aValue<0)aValue = 0;
    if(aValue>0x3)aValue = 0x3;
    [[[self undoManager] prepareWithInvocationTarget:self] setTauTableBits:aChan withValue:[self tauTableBits:aChan]];
    tauTableBits[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316TauTableBitsChanged object:self userInfo:userInfo];
}

- (unsigned short) tauFactor:(unsigned short)aChan
{
    if(aChan>kNumSIS3316Channels)return 0;
    else return tauFactor [aChan];
}

- (void) setTauFactor:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue>0x3f)aValue = 0x3f;
    [[[self undoManager] prepareWithInvocationTarget:self] setTauFactor:aChan withValue:[self tauFactor:aChan]];
    tauFactor[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316TauFactorChanged object:self userInfo:userInfo];
}

- (unsigned short) riseTime:(unsigned short)aChan
{
    if(aChan>kNumSIS3316Channels)return 0;
    else return riseTime[aChan];
}

- (void) setRiseTime:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue>0x7FC)aValue = 0xFFFF;
    if(aValue<4)aValue = 4;
    aValue &= ~0x0003;
    [[[self undoManager] prepareWithInvocationTarget:self] setRiseTime:aChan withValue:riseTime[aChan]];
    riseTime[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316PeakingTimeChanged object:self userInfo:userInfo];
}

- (unsigned short) gapTime:(unsigned short)aChan
{
    if(aChan>kNumSIS3316Channels)return 0;
    else return gapTime[aChan];
}

- (void) setGapTime:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue>0x1FE)aValue = 0x1FE;
    if(aValue<2)aValue = 2;
    aValue &= ~0x0001; //bit zero is always zero
    
    [[[self undoManager] prepareWithInvocationTarget:self] setGapTime:aChan withValue:[self gapTime:aChan]];
    gapTime[aChan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316GapTimeChanged object:self userInfo:userInfo];
}

- (void) writeFirEnergySetup
{
    int i;
    for(i = 0; i < kNumSIS3316Channels; i++) {
        unsigned long aValue = (([self tauFactor:i]        & 0x3f)<<24)        |
                               (([self gapTime:i]          & 0x1FE)<<12)       |
                               ([self riseTime:i]       & 0x7FC)            |
                               ((unsigned long)([self tauTableBits:i]     & 0x3) << 30)       |
                               (([self extraFilterBits:i]  & 0x3) << 22)       ;

        [self writeLong:0 toAddress:[self channelRegisterVersionTwo:kFirEnergySetupCh1Reg channel:i]];
        [self writeLong:aValue toAddress:[self channelRegisterVersionTwo:kFirEnergySetupCh1Reg channel:i]];
    }
}

- (void) readFirEnergySetup:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading FIR Energy Setup:\n");
        NSLogFont([NSFont fontWithName:@"Monaco" size:12],@"TauTable TauFactor GapTime PeakingTime  ExtraFilter \n");
    }
    for(i =0; i < kNumSIS3316Channels; i++) {
        unsigned long aValue =  [self readLongFromAddress:[self channelRegisterVersionTwo:kFirEnergySetupCh1Reg channel:i]];
        if(verbose){
            unsigned long theTauFactor   = ((aValue >> 24) & 0x3F)  ;
            unsigned long theTauTable    = ((aValue >> 30) & 0x3)   ;
            unsigned long theExtraFilter = ((aValue >> 22) & 0x3)   ;
            unsigned long theGapTime     = ((aValue >> 12) & 0x1FE) ;
            unsigned long thePeakTime    = ((aValue >> 0) & 0x7FC)  ;
            NSLogFont([NSFont fontWithName:@"Monaco" size:12],@"%2d: %@ 0x%08x 0x%08x 0x%08x %@\n",i, tauTable[theTauTable], theTauFactor , theGapTime, thePeakTime, extraFilter[theExtraFilter]);
        }
    }
}

//6.33 Energy Histogram Configuration registers
- (long) histogramsEnabledMask                       { return histogramsEnabledMask;                             }
- (BOOL) histogramsEnabled:(unsigned short)chan      { return (histogramsEnabledMask     & (0x1<<chan)) != 0;    }
- (long) pileupEnabledMask                           { return pileupEnabledMask;                                 }
- (BOOL) pileupEnabled:(unsigned short)chan          { return (pileupEnabledMask         & (0x1<<chan)) != 0;    }
- (long) clrHistogramsWithTSMask                     { return clrHistogramsWithTSMask;                           }
- (BOOL) clrHistogramsWithTS:(unsigned short)chan    { return (clrHistogramsWithTSMask   & (0x1<<chan)) != 0;    }
- (long) writeHitsToEventMemoryMask                  { return writeHitsToEventMemoryMask;                        }
- (BOOL) writeHitsToEventMemory:(unsigned short)chan { return (writeHitsToEventMemoryMask& (0x1<<chan)) != 0;    }

- (void) setHistogramsEnabledMask:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistogramsEnabledMask:histogramsEnabledMask];
    histogramsEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316HistogramsEnabledChanged object:self];
}

- (void) setHistogramsEnabled:(unsigned short)chan withValue:(BOOL)aValue
{
    long            aMask  = histogramsEnabledMask;
    if(aValue)      aMask |= (0x1<<chan);
    else            aMask &= ~(0x1<<chan);
    [self setHistogramsEnabledMask:aMask];
}

- (void) setPileupEnabledMask:(unsigned long)aMask
{
    if(pileupEnabledMask==aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setPileupEnabledMask:pileupEnabledMask];
    pileupEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316PileUpEnabledChanged object:self];
}

- (void) setPileupEnabled:(unsigned short)chan withValue:(BOOL)aValue
{
    long            aMask  = pileupEnabledMask;
    if(aValue)      aMask |= (0x1<<chan);
    else            aMask &= ~(0x1<<chan);
    [self setPileupEnabledMask:aMask];
}

- (void) setClrHistogramsWithTSMask:(unsigned long)aMask
{
    if(clrHistogramsWithTSMask==aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setClrHistogramsWithTSMask:clrHistogramsWithTSMask];
    clrHistogramsWithTSMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316ClrHistogramWithTSChanged object:self];
}

- (void) setClrHistogramsWithTS:(unsigned short)chan withValue:(BOOL)aValue
{
    long            aMask = clrHistogramsWithTSMask;
    if(aValue)      aMask |= (0x1<<chan);
    else            aMask &= ~(0x1<<chan);
    [self setClrHistogramsWithTSMask:aMask];
}

- (void) setWriteHitsToEventMemoryMask:(unsigned long)aMask
{
    if(writeHitsToEventMemoryMask==aMask)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteHitsToEventMemoryMask:writeHitsToEventMemoryMask];
    writeHitsToEventMemoryMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316WriteHitsIntoEventMemoryChanged object:self];
}

- (void) setWriteHitsToEventMemory:(unsigned short)chan withValue:(BOOL)aValue
{
    long            aMask = writeHitsToEventMemoryMask;
    if(aValue)      aMask |= (0x1<<chan);
    else            aMask &= ~(0x1<<chan);
    [self setWriteHitsToEventMemoryMask:aMask];
}

- (unsigned short) energyDivider:(unsigned short)aChan
{
    if(aChan>kNumSIS3316Channels)return 0;
    else return energyDivider[aChan];
}

- (void) setEnergyDivider:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue<1)aValue = 1;
    if(aValue>0xFFF)aValue = 0xfff;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyDivider:aChan withValue:[self energyDivider:aChan]];
    energyDivider[aChan]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EnergyDividerChanged object:self userInfo:userInfo];
}

- (unsigned short) energySubtractor:(unsigned short)aChan
{
    if(aChan>kNumSIS3316Channels)return 0;
    else return energySubtractor[aChan];
}

- (void) setEnergySubtractor:(unsigned short)aChan withValue:(unsigned short)aValue
{
    if(aChan>kNumSIS3316Channels)return;
    if(aValue>0xff)aValue = 0xff;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergySubtractor:aChan withValue:[self energySubtractor:aChan]];
    energySubtractor[aChan]=aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3316EnergySubtractorChanged object:self userInfo:userInfo];
}

- (void) writeHistogramConfiguration
{
    int i;
    for(i = 0; i < kNumSIS3316Channels; i++) {
        unsigned long aValue =  (((histogramsEnabledMask>>i)     & 0x1)     << 0 )  |
                                (((pileupEnabledMask>>i)         & 0x1)     << 1 )  |
                                ((energySubtractor[i]            & 0xFF)    << 8 )  |
                                ((energyDivider[i]               & 0xFFF)   << 16)  |
                                (((clrHistogramsWithTSMask>>i)   & 0x1)     << 30)  |
                                ((writeHitsToEventMemoryMask>>i  & 0x1)     << 31)  ;
        [self writeLong:aValue toAddress:[self channelRegisterVersionTwo:kEnergyHistoConfigCh1Reg channel:i]];
    }
}

- (void) readHistogramConfiguration:(BOOL)verbose
{
    int i;
    if(verbose){
        NSLog(@"Reading Histogram Configuration:\n");
        NSLog(@"Enabled PU ClrW/TS Hits division subtraction \n");
    }
    for(i =0; i < kNumSIS3316Channels; i++) {
        unsigned long aValue =  [self readLongFromAddress:[self channelRegisterVersionTwo:kEnergyHistoConfigCh1Reg channel:i]];
        if(verbose){
            BOOL theHistogramsEnabled           = ((aValue >> 0) & 0x1)     ;
            BOOL thePileupEnabled               = ((aValue >> 1) & 0x1)     ;
            BOOL theClrHistogramsWithTS         = ((aValue >> 30) & 0x1)    ;
            BOOL theWriteHitsToEventMemory      = ((aValue >> 31) & 0x1)    ;
            unsigned short theEnergyDivider     = ((aValue >> 16) & 0xFFF)  ;
            unsigned short theEnergySubtractor  = ((aValue >> 8 ) & 0xFF)   ;
            NSLog(@"%2d: %@ %@ %@ %@  0x%08x 0x%08x\n",i, theHistogramsEnabled?@"YES":@" NO ", thePileupEnabled?@"YES":@" NO ", theClrHistogramsWithTS?@"YES":@" NO ", theWriteHitsToEventMemory?@"YES":@" NO ", theEnergyDivider,theEnergySubtractor);
        }
    }
}

//6.34 MAW Start Index and Energy Pickup Configuration registers

//6.35 ADC FPGA Firmware Version Register

//6.36 ADC FPGA Status register

//6.37 Actual Sample address registers

//6.38 Previous Bank Sample address registers
//** under #pragma mark •••Data Taker **//

//6.39 Key addresses (0x400 – 0x43C write only)
//6.39.1 Key address: Register Reset
- (void) reset
{
    [self writeLong:0 toAddress:[self singleRegister:kKeyResetReg]];
}

//6.39.4 Key address: Disarm sample logic
- (void) disarmSampleLogic
{
    [self writeLong:1 toAddress:[self singleRegister:kKeyDisarmSampleLogicReg]];
}

//6.39.4 Key address: arm sample logic **** not implemented in the firmware yet....
- (void) armSampleLogic
{
    [self writeLong:1 toAddress:[self singleRegister:kKeyArmSampleLogicReg]];
}

//6.39.5Keyaddress: Trigger
- (void) trigger
{
    [self writeLong:1 toAddress:[self singleRegister:kKeyTriggerReg]];
}

//6.39.6 Key address: Timestamp Clear
- (void) clearTimeStamp
{
    [self writeLong:1 toAddress:[self singleRegister:kKeyTimeStampClrReg]];
}

//6.39.7 Key address: Disarm Bankx and Arm Bank1
- (void) armBank1
{
    [self writeLong:1 toAddress:[self singleRegister:kKeyDisarmXArmBank1Reg]];
    currentBank = 1;
}

//6.39.8 Key address: Disarm Bankx and Arm Bank2
- (void) armBank2
{
    [self writeLong:1 toAddress:[self singleRegister:kKeyDisarmXArmBank2Reg]];
    currentBank = 2;
}

//6.39.13 Key address: ADC Clock DCM/PLL Reset
- (void) resetADCClockDCM
{
    [self writeLong:1 toAddress:[self singleRegister:kKeyAdcClockPllResetReg]];
    [ORTimer delay:5*1E-3];//required wait for stablization
}

- (unsigned long) eventNumberGroup:(int)group bank:(int) bank
{
	//Note, here banks are 0,1,2,3 NOT 1,2,3,4
    return  [self readLongFromAddress:[self baseAddress] + eventCountOffset[group][bank]];
}

- (unsigned long) eventTriggerGroup:(int)group bank:(int) bank
{
	//Note, here banks are 0,1,2,3 NOT 1,2,3,4
    return  [self readLongFromAddress:[self baseAddress] + eventDirOffset[group][bank]];
}

- (void) readAddressCounts
{
	int i;
	for(i=0;i<4;i++){
        unsigned long aValue  = [self readLongFromAddress:[self baseAddress] + addressCounterOffset[i][0]];
        unsigned long aValue1 = [self readLongFromAddress:[self baseAddress] + addressCounterOffset[i][1]];
		NSLog(@"Group %d Address Counters:  0x%04x   0x%04x\n",i,aValue,aValue1);
	}
}

- (int) setFrequency:(int) osc values:(unsigned char*)values
{
    
    if(values == nil)     return -100;
    if(osc > 3 || osc < 0)return -100;
    
    int rc = [self si570FreezeDCO:osc];
    if(rc){
        NSLog(@"%@ : si570FreezeDCO Error(%d)\n",[self fullID],rc);
        return rc;
    }
    
    rc = [self si570Divider:osc values:values];
    if(rc){
        NSLog(@"%@ : si570Divider Error(%d)\n",[self fullID],rc);
        return rc;
    }

    rc = [self si570UnfreezeDCO:osc];
    if(rc){
        NSLog(@"%@ : si570UnfreezeDCO Error(%d)\n",[self fullID],rc);
        return rc;
    }
    
    rc = [self si570NewFreq:osc];
    if(rc){
        NSLog(@"%@ : si570NewFreq Error(%d)\n",[self fullID],rc);
        return rc;
    }
    
    // min. 10ms wait
    usleep(20000);
    
    [self resetADCClockDCM];

    return rc;
}

- (void) switchBanks
{
    if(currentBank == 1)    [self armBank2];
    else                    [self armBank1];
}

- (unsigned long) readTriggerTime:(int)bank index:(int)index
{   		
    return  [self readLongFromAddress:[self baseAddress] + (bank?kTriggerTime2Offset:kTriggerTime1Offset) + index*sizeof(long)];
}

- (unsigned long) readTriggerEventBank:(int)bank index:(int)index
{   		
    return  [self readLongFromAddress:[self baseAddress] + (bank?kTriggerEvent2DirOffset:kTriggerEvent1DirOffset) + index*sizeof(long)];
}

//- (void) configureEventRegisters
//{
//    
//    
//    unsigned int internalGateConfig_register_addresses[SIS3316_ADCGROUP_PER_CARD] = { SIS3316_ADC_CH1_4_INTERNAL_GATE_LENGTH_CONFIG_REG, SIS3316_ADC_CH5_8_INTERNAL_GATE_LENGTH_CONFIG_REG, SIS3316_ADC_CH9_12_INTERNAL_GATE_LENGTH_CONFIG_REG, SIS3316_ADC_CH13_16_INTERNAL_GATE_LENGTH_CONFIG_REG };
//    for( int groupNumber = 0; groupNumber < SIS3316_ADCGROUP_PER_CARD; groupNumber++ ) {
//        data = (0xF & internalGate2_block_channelEnableMask[groupNumber]) << 20 | (0xF & internalGate1_block_channelEnableMask[groupNumber] ) << 16 | (0xFF & internalGate_block_length[groupNumber] ) << 8 | (0xFF & internalCoincidence_block_width[groupNumber] );
//        return_code = vmei->vme_A32D32_write(baseaddress + internalGate Config_register_addresses[groupNumber], data );
//    }
//    
//    
//    unsigned int internalTriggerDelay_register_addresses[SIS3316_ADCGROUP_PER_CARD] = { SIS3316_ADC_CH1_4_INTERNAL_TRIGGER_DELAY_CONFIG_REG, SIS3316_ADC_CH5_8_INTERNAL_TRIGGER_DELAY_CONFIG_REG,
//        SIS3316_ADC_CH9_12_INTERNAL_TRIGGER_DELAY_CONFIG_REG, SIS3316_ADC_CH13_16_INTERNAL_TRIGGER_DELAY_CONFIG_REG };
//    for( int groupNumber = 0; groupNumber < SIS3316_ADCGROUP_PER_CARD; groupNumber++ ) {
//        data = 0xFFFFFFFF & internalTriggerDelay_block[groupNumber];
//        return_code = vmei->vme_A32D32_write(baseaddress + internalTriggerDelay_register_addresses[groupNumber], data );
//    }
//    
//    
//    
//}

- (void) initBoard
{
   // [self reset];
    [self resetADCClockDCM];
    [self setClockChoice:0];
    [self writeGainAndTermination];
    [self configureAnalogRegisters];
    [self writeActiveTrigGateWindowLen];
    [self writePreTriggerDelays];
    [self writeRawDataBufferConfig];
    [self writeDataFormat];
    [self writeEventConfig];
    [self writeAccumulatorGates];
    [self writeEndAddress];

    [self writeAcquisitionRegister];
    
    [self configureFIR];
    
    [self writeThresholdSum];
    [self writeFirEnergySetup];
    [self writeTriggerDelay];
    [self writeNIMControlStatus];
    [self writeHistogramConfiguration];
    [self writeExtendedEventConfig];
    [self writeLemoCoMask];
    [self writeLemoToMask];
    [self writeLemoUoMask];
}

#pragma mark •••Data Taker
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORSIS3316WaveformDecoder",            @"decoder",
								 [NSNumber numberWithLong:dataId],       @"dataId",
								 [NSNumber numberWithBool:YES],          @"variable",
								 [NSNumber numberWithLong:-1],			 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Waveform"];
    
    return dataDictionary;
}

#pragma mark •••HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (int) numberOfChannels
{
    return kNumSIS3316Channels;
}

- (NSArray*) wizardParameters   //*****IN ALPHABETICAL ORDER*****//
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;

//    [a addObject:[ORHWWizParam boolParamWithName:@"AutoStart"        setter:@selector(setAutoStart:)        getter:@selector(autoStart)]];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Both Edges"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTrigBothEdgesBit:withValue:) getMethod:@selector(trigBothEdgesBit:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"CFD Control Bits"];
    [p setFormat:@"##0" upperLimit:2 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setCfdControlBits:withValue:) getMethod:@selector(cfdControlBits:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
  //-=**
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setEnabledBit:withValue:) getMethod:@selector(enabled:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Extra Filter"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setExtraFilterBits:withValue:) getMethod:@selector(extraFilterBits:)];
    [p setCanBeRamped:YES];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"HE"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setHeSuppressTriggerBit:withValue:) getMethod:@selector(heSuppressTriggerBit:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"HE Trig Out"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setIntHeTrigOutPulseBit:withValue:) getMethod:@selector(intHeTrigOutPulseBit:)];
    [p setCanBeRamped:YES];
    [a addObject:p];

    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gap Time"];
    [p setFormat:@"##0" upperLimit:0x3f lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setGapTime:withValue:) getMethod:@selector(gapTime:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"HE Trig Threshold"];
    [p setFormat:@"##0" upperLimit:0xfffffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setHeTrigThreshold:withValue:) getMethod:@selector(heTrigThreshold:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Dac Offset"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setDacOffset:withValue:) getMethod:@selector(dacOffset:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Int Trig Out Pulse"];
    [p setFormat:@"##0" upperLimit:2 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setIntTrigOutPulseBit:withValue:) getMethod:@selector(intTrigOutPulseBit:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Page Size"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPageSize:) getMethod:@selector(pageSize)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Peaking Time"];
    [p setFormat:@"##0" upperLimit:0x3f lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setRiseTime:withValue:) getMethod:@selector(riseTime:)];
    [a addObject:p];
    
 //   [a addObject:[ORHWWizParam boolParamWithName:@"P2StartStop"      setter:@selector(setP2StartStop:)      getter:@selector(p2StartStop)]];
    
    [a addObject:[ORHWWizParam boolParamWithName:@"RandomClock"      setter:@selector(setRandomClock:)      getter:@selector(randomClock)]];
    

    [a addObject:[ORHWWizParam boolParamWithName:@"StopTrigger"      setter:@selector(setStopTrigger:)      getter:@selector(stopTrigger)]];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Tau Factor"];
    [p setFormat:@"##0" upperLimit:0x3f lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTauFactor:withValue:) getMethod:@selector(tauFactor:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Tau Table"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTauTableBits:withValue:) getMethod:@selector(tauTableBits:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0xfffffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
   
//    p = [[[ORHWWizParam alloc] init] autorelease];
//    [p setName:@"Threshold Sum"];
//    [p setFormat:@"##0" upperLimit:0xFFFFFFFF lowerLimit:0 stepSize:1 units:@""];
//    [p setSetMethod:@selector(setThresholdSum:withValue:) getMethod:@selector(thresholdSum:)];
//    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease]; //MUST BE LAST
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];

    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel  name:@"Crate"   className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel     name:@"Card"    className:@"ORSIS3316Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel    name:@"Channel" className:@"ORSIS3316Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:      @"Threshold"])          return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else if([param isEqualToString: @"Enabled"])            return [cardDictionary objectForKey: @"enabledMask"];
    else if([param isEqualToString: @"Histogram Enabled"])  return [cardDictionary objectForKey: @"histogramsEnabledMask"];
    else if([param isEqualToString: @"Page Size"])          return [cardDictionary objectForKey: @"pageSize"];
    else if([param isEqualToString: @"Clock Source"])       return [cardDictionary objectForKey: @"clockSource"];
    else if([param isEqualToString: @"PageWrap"])           return [cardDictionary objectForKey: @"pageWrap"];
    else if([param isEqualToString: @"StopTrigger"])        return [cardDictionary objectForKey: @"stopTrigger"];
    else if([param isEqualToString: @"P2StartStop"])        return [cardDictionary objectForKey: @"p2StartStop"];
    else if([param isEqualToString: @"LemoStartStop"])      return [cardDictionary objectForKey: @"lemoStartStop"];
    else if([param isEqualToString: @"RandomClock"])        return [cardDictionary objectForKey: @"randomClock"];
    else if([param isEqualToString: @"GateMode"])           return [cardDictionary objectForKey: @"gateMode"];
    else if([param isEqualToString: @"MultiEvent"])         return [cardDictionary objectForKey: @"multiEventMode"];
    else return nil;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3316Model"];    
    
    //cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
    
    if(!moduleID)[self readModuleID:NO];

    [self startRates];
    [self disarmSampleLogic];
    [self initBoard];
	[self armBank1];
	[self setLed:YES];
	isRunning = NO;
	count=0;
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
//     1 - 3 done in the initBoard method
//    1. Disarm or Reset command
//    2. Set address threshold registers
//    3. Disarm active Bank and arm Bank2 command (start with the second bank)
    
//    do {
//        4a. Poll on address threshold flag and wait until valid
//        (also possible to wait for a defined time)
//        5a. Disarm active Bank and arm Bank1 command
//        6a. check if the active Bank is swapped (also possible to wait for defined time,
//                                                 for example the length of time of one event )
//            7a. read “Previous Bank Sample address registers Ch1 to Ch16”
//            (bit 24 will be cleared if the address corresponds to theBank1 and will be set
//             if the address correspond to Bank2, means for checking whether the active
//             bank was swapped already)
//            8a. read sampled data from Ch1 to Ch16 (Memory Bank 2)
//            4b. Poll on address threshold flag and wait until valid
//            (also possible to wait for a defined time)
//            5b. Disarm active Bank and arm Bank2 command
//            6b. check if the active Bank is swapped
//                7b. read “Previous Bank Sample address registers Ch1 to Ch16”
//                8b. read sampled data from Ch1 to Ch16 (Memory Bank 1)
//                } (run == 1)
//    9. Disarm command
    
    @try {
        isRunning = YES;
		if([self addressThresholdFlag]){
//            int prevRunningBank = currentBank;
            [self switchBanks];
////
////            // Verify that the previous bank address is valid
//            unsigned long prevBankEndingAddress = 0;
//            int max_poll_counter = 1000;
//            int chan = 0;
//            BOOL timeout = NO;
//           do {
//                [[self adapter] readLongBlock: &prevBankEndingAddress
//                                    atAddress: [self channelRegister:kPreviousBankSampleCh1Reg channel:chan]                                      numToRead: 1
//                                    withAddMod: [self addressModifier]
//                                usingAddSpace: 0x01];
//
//                max_poll_counter--;
//               if (max_poll_counter == 0) {
//                    timeout = YES;
//                    break;
//               }
//            } while (((prevBankEndingAddress>>24) & 0x1)  != (prevRunningBank-1)); // previous Bank sample address is valid if bit 24 is equal bank2_read_flag
//
//            if(!timeout){
//                unsigned long data[10];
//                [[self adapter] readLongBlock: data
//                                    atAddress: [self baseAddress] + 0x00100000
//                                    numToRead: 10
//                                   withAddMod: [self addressModifier]
//                                usingAddSpace: 0x01];
//                int i;
//                for(i=0;i<10;i++){
//                    NSLog(@"%d : 0x%08x\n",i,data[i]);
//                }
//            }

            
        }
        
	}
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    isRunning = NO;
    [waveFormRateGroup stop];
	[self setLed:NO];
    [self disarmSampleLogic];
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kSIS3316; //should be unique
	configStruct->card_info[index].hw_mask[0]				= dataId; //better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= [self addressModifier];
	configStruct->card_info[index].base_add					= [self baseAddress];
    configStruct->card_info[index].deviceSpecificData[0]	= bankSwitchMode;
    configStruct->card_info[index].deviceSpecificData[1]	= [self numberOfSamples];
	configStruct->card_info[index].deviceSpecificData[2]	= moduleID;
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

- (BOOL) bumpRateFromDecodeStage:(unsigned short)channel
{
    if(isRunning)return NO;
    
    ++waveFormCount[channel];
    return YES;
}

- (unsigned long) waveFormCount:(int)aChannel
{
    return waveFormCount[aChannel];
}

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<kNumSIS3316Channels;i++){
        waveFormCount[i]=0;
    }
}
#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setEnabledMask:               [decoder decodeInt32ForKey: @"enabledMask"]];
    [self setEventConfigMask:           [decoder decodeInt32ForKey: @"eventConfigMask"]];
    [self setExtendedEventConfigBit:    [decoder decodeInt32ForKey: @"extendedEventConfigBit"]];
    [self setEndAddressSuppressionMask: [decoder decodeInt32ForKey: @"endAddressSuppressionMask"]];
    [self setHistogramsEnabledMask:     [decoder decodeInt32ForKey: @"histogramsEnabledMask"]];
    [self setHeSuppressTriggerMask:     [decoder decodeInt32ForKey: @"heSuppressTriggerMask"]];
    [self setGain:                      [decoder decodeIntForKey:   @"gain"]];
    [self setTermination:               [decoder decodeIntForKey:   @"termination"]];
    [self setTrigBothEdgesMask:         [decoder decodeInt32ForKey: @"trigBothEdgesMask"]];
    [self setIntHeTrigOutPulseMask:     [decoder decodeInt32ForKey: @"intHeTrigOutPulseMask"]];
    [self setLemoCoMask:                [decoder decodeInt32ForKey: @"lemoCoMask"]];
    [self setLemoUoMask:                [decoder decodeInt32ForKey: @"lemoUoMask"]];
    [self setLemoToMask:                [decoder decodeInt32ForKey: @"lemoToMask"]];
    [self setAcquisitionControlMask:    [decoder decodeInt32ForKey: @"acquisitionControlMask"]];
    [self setNIMControlStatusMask:      [decoder decodeInt32ForKey: @"nimControlStatusMask"]];
    
    //load up all the C Arrays
    [[decoder decodeObjectForKey: @"cfdControlBits"]    loadULongCArray:cfdControlBits      size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"threshold"]         loadULongCArray:threshold           size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"riseTime"]          loadULongCArray:riseTime            size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"gapTime"]           loadULongCArray:gapTime             size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"tauFactor"]         loadULongCArray:tauFactor           size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"extraFilterBits"]   loadULongCArray:extraFilterBits     size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"tauTableBits"]      loadULongCArray:tauTableBits        size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"intTrigOutPulseBit"]loadUShortCArray:intTrigOutPulseBit size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"heTrigThreshold"]   loadULongCArray:heTrigThreshold     size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"energySubtractors"] loadUShortCArray:energySubtractor   size:kNumSIS3316Channels];
    [[decoder decodeObjectForKey: @"energyDivider"]     loadUShortCArray:energyDivider      size:kNumSIS3316Channels];

    [[decoder decodeObjectForKey: @"dacOffsets"]                loadUShortCArray:dacOffsets                 size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"activeTrigGateWindowLen"]   loadUShortCArray:activeTrigGateWindowLen    size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"endAddress"]                loadULongCArray:endAddress                  size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"triggerDelay"]              loadUShortCArray:triggerDelay               size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"enableSum"]                 loadBoolCArray:enableSum                    size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"thresholdSum"]              loadULongCArray:thresholdSum                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"heTrigThresholdSum"]        loadULongCArray:heTrigThresholdSum          size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"gapTimeSum"]                loadULongCArray:gapTimeSum                  size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"riseTimeSum"]               loadULongCArray:riseTimeSum                 size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"cfdControlBitsSum"]         loadULongCArray:cfdControlBitsSum           size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"activeTrigGateWindowLen"]   loadUShortCArray:activeTrigGateWindowLen    size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"preTriggerDelay"]           loadUShortCArray:preTriggerDelay            size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"rawDataBufferLen"]          loadULongCArray:rawDataBufferLen            size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"rawDataBufferStart"]        loadULongCArray:rawDataBufferStart          size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accumulatorGateStart"]      loadUShortCArray:accumulatorGateStart       size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accumulatorGateLength"]     loadUShortCArray:accumulatorGateLength      size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate1Start"]             loadUShortCArray:accGate1Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate2Start"]             loadUShortCArray:accGate2Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate3Start"]             loadUShortCArray:accGate3Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate4Start"]             loadUShortCArray:accGate4Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate5Start"]             loadUShortCArray:accGate5Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate6Start"]             loadUShortCArray:accGate6Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate7Start"]             loadUShortCArray:accGate7Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate8Start"]             loadUShortCArray:accGate8Start              size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate1Len"]               loadUShortCArray:accGate1Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate2Len"]               loadUShortCArray:accGate2Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate3Len"]               loadUShortCArray:accGate3Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate4Len"]               loadUShortCArray:accGate4Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate5Len"]               loadUShortCArray:accGate5Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate6Len"]               loadUShortCArray:accGate6Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate7Len"]               loadUShortCArray:accGate7Len                size:kNumSIS3316Groups];
    [[decoder decodeObjectForKey: @"accGate8Len"]               loadUShortCArray:accGate8Len                size:kNumSIS3316Groups];

 
    
    //csr
		
	//acq
    //[self setBankSwitchMode:		[decoder decodeBoolForKey:@"bankSwitchMode"]];
    //[self setAutoStart:				[decoder decodeBoolForKey:@"autoStart"]];
    //[self setMultiEventMode:		[decoder decodeBoolForKey:@"multiEventMode"]];
    //[self setMultiplexerMode:		[decoder decodeBoolForKey:@"multiplexerMode"]];
    //[self setLemoStartStop:			[decoder decodeBoolForKey:@"lemoStartStop"]];
    //[self setP2StartStop:			[decoder decodeBoolForKey:@"p2StartStop"]];
    //[self setGateMode:				[decoder decodeBoolForKey:@"gateMode"]];
	
	//clocks
    [self setRandomClock:			[decoder decodeBoolForKey:@"randomClock"]];
    [self setClockSource:			[decoder decodeIntForKey:@"clockSource"]];
	
    [self setStopTrigger:			[decoder decodeBoolForKey:@"stopTrigger"]];
    [self setPageSize:				[decoder decodeIntForKey:@"pageSize"]];
		
    [self setWaveFormRateGroup:     [decoder decodeObjectForKey:@"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3316Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];


    [[self undoManager] enableUndoRegistration];
    
    return self;
}


- (void) setUpEmptyArray:(SEL)aSetter numItems:(int)n
{
    NSMutableArray* anArray = [NSMutableArray arrayWithCapacity:n];
    int i;
    for(i=0;i<n;i++)[anArray addObject:[NSNumber numberWithInt:0]];
    NSMethodSignature* signature = [[self class] instanceMethodSignatureForSelector:aSetter];
    NSInvocation* invocation     = [NSInvocation invocationWithMethodSignature: signature];
    [invocation setTarget:   self];
    [invocation setSelector: aSetter];
    [invocation setArgument: &anArray atIndex: 2];
    [invocation invoke];

}

- (void) setUpArray:(SEL)aSetter intValue:(int)aValue numItems:(int)n
{
    NSMutableArray* anArray = [NSMutableArray arrayWithCapacity:n];
    int i;
    for(i=0;i<n;i++)[anArray addObject:[NSNumber numberWithInt:aValue]];
    NSMethodSignature* signature = [[self class] instanceMethodSignatureForSelector:aSetter];
    NSInvocation* invocation     = [NSInvocation invocationWithMethodSignature: signature];
    [invocation setTarget:   self];
    [invocation setSelector: aSetter];
    [invocation setArgument: &anArray atIndex: 2];
    [invocation invoke];
    
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];

    [encoder encodeInt:   gain                       forKey:@"gain"];
    [encoder encodeInt:   termination                forKey:@"termination"];
    [encoder encodeInt32: enabledMask                forKey:@"enabledMask"];
    [encoder encodeInt32: eventConfigMask            forKey:@"eventConfigMask"];
    [encoder encodeInt32: extendedEventConfigBit     forKey:@"extendedEventConfigBit"];
    [encoder encodeInt32: endAddressSuppressionMask  forKey:@"endAddressSuppressionMask"];
    [encoder encodeInt32: histogramsEnabledMask      forKey:@"histogramsEnabledMask"];
    [encoder encodeInt32: pileupEnabledMask          forKey:@"pileupEnabledMask"];
    [encoder encodeInt32: clrHistogramsWithTSMask    forKey:@"clrHistogramsWithTSMask"];
    [encoder encodeInt32: writeHitsToEventMemoryMask forKey:@"writeHitsToEventMemoryMask"];
    [encoder encodeInt32: heSuppressTriggerMask      forKey:@"heSuppressTriggerMask"];
    [encoder encodeInt32: trigBothEdgesMask          forKey:@"trigBothEdgesMask"];
    [encoder encodeInt32: intHeTrigOutPulseMask      forKey:@"intHeTrigOutPulseMask"];
    [encoder encodeInt32: lemoToMask                 forKey:@"lemoToMask"];
    [encoder encodeInt32: lemoUoMask                 forKey:@"lemoUoMask"];
    [encoder encodeInt32: lemoCoMask                 forKey:@"lemoCoMask"];
    [encoder encodeInt32: acquisitionControlMask     forKey:@"acquisitionControlMask"];
    //clocks
    [encoder encodeBool:  randomClock                forKey:@"randomClock"];
    [encoder encodeInt:   clockSource                forKey:@"clockSource"];
    [encoder encodeBool:  pageWrap                   forKey:@"pageWrap"];
    [encoder encodeBool:  stopTrigger                forKey:@"stopTrigger"];
    [encoder encodeInt:   pageSize                   forKey:@"pageSize"];
    [encoder encodeObject:waveFormRateGroup          forKey:@"waveFormRateGroup"];
    [encoder encodeObject:nimControlStatusMask       forKey:@"nimControlStatusMask"];
    //handle all the C Arrays
    [encoder encodeObject: [NSArray arrayFromULongCArray:cfdControlBits             size:kNumSIS3316Channels] forKey:@"cfdControlBits"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:extraFilterBits            size:kNumSIS3316Channels] forKey:@"extraFilterBits"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:tauTableBits               size:kNumSIS3316Channels] forKey:@"tauTableBits"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:threshold                  size:kNumSIS3316Channels] forKey:@"threshold"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:riseTime                   size:kNumSIS3316Channels] forKey:@"riseTime"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:gapTime                    size:kNumSIS3316Channels] forKey:@"gapTime"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:tauFactor                  size:kNumSIS3316Channels] forKey:@"tauFactor"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:heTrigThreshold            size:kNumSIS3316Channels] forKey:@"heTrigThreshold"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:energySubtractor          size:kNumSIS3316Channels] forKey:@"energySubtractor"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:energyDivider             size:kNumSIS3316Channels] forKey:@"energyDivider"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:dacOffsets                size:kNumSIS3316Groups]   forKey:@"dacOffsets"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:endAddress                 size:kNumSIS3316Groups]   forKey:@"endAddress"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:triggerDelay              size:kNumSIS3316Groups]   forKey:@"triggerDelay"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:activeTrigGateWindowLen   size:kNumSIS3316Groups]   forKey:@"activeTrigGateWindowLen"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:preTriggerDelay           size:kNumSIS3316Groups]   forKey:@"preTriggerDelay"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:rawDataBufferLen           size:kNumSIS3316Groups]   forKey:@"rawDataBufferLen"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:rawDataBufferStart         size:kNumSIS3316Groups]   forKey:@"rawDataBufferStart"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accumulatorGateLength     size:kNumSIS3316Groups]   forKey:@"accumulatorGateLength"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accumulatorGateStart      size:kNumSIS3316Groups]   forKey:@"accumulatorGateStart"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate1Len               size:kNumSIS3316Groups]   forKey:@"accGate1Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate2Len               size:kNumSIS3316Groups]   forKey:@"accGate2Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate3Len               size:kNumSIS3316Groups]   forKey:@"accGate3Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate4Len               size:kNumSIS3316Groups]   forKey:@"accGate4Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate5Len               size:kNumSIS3316Groups]   forKey:@"accGate5Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate6Len               size:kNumSIS3316Groups]   forKey:@"accGate6Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate7Len               size:kNumSIS3316Groups]   forKey:@"accGate7Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate8Len               size:kNumSIS3316Groups]   forKey:@"accGate8Len"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate1Start             size:kNumSIS3316Groups]   forKey:@"accGate1Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate2Start             size:kNumSIS3316Groups]   forKey:@"accGate2Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate3Start             size:kNumSIS3316Groups]   forKey:@"accGate3Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate4Start             size:kNumSIS3316Groups]   forKey:@"accGate4Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate5Start             size:kNumSIS3316Groups]   forKey:@"accGate5Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate6Start             size:kNumSIS3316Groups]   forKey:@"accGate6Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate7Start             size:kNumSIS3316Groups]   forKey:@"accGate7Start"];
    [encoder encodeObject: [NSArray arrayFromUShortCArray:accGate8Start             size:kNumSIS3316Groups]   forKey:@"accGate8Start"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:thresholdSum               size:kNumSIS3316Groups]   forKey:@"thresholdSum"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:heTrigThresholdSum         size:kNumSIS3316Groups]   forKey:@"heTrigThresholdSum"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:gapTimeSum                 size:kNumSIS3316Groups]   forKey:@"gapTimeSum"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:riseTime                   size:kNumSIS3316Groups]   forKey:@"riseTime"];
    [encoder encodeObject: [NSArray arrayFromULongCArray:cfdControlBitsSum          size:kNumSIS3316Groups]   forKey:@"cfdControlBitsSum"];
    [encoder encodeObject: [NSArray arrayFromBoolCArray:enableSum                   size:kNumSIS3316Groups]   forKey:@"enableSum"];

	//acq
    //[encoder encodeBool:bankSwitchMode	    forKey:@"bankSwitchMode"];
    //[encoder encodeBool:autoStart				forKey:@"autoStart"];
    ///[encoder encodeBool:multiEventMode		forKey:@"multiEventMode"];
	//[encoder encodeBool:multiplexerMode		forKey:@"multiplexerMode"];
    //[encoder encodeBool:lemoStartStop			forKey:@"lemoStartStop"];
    //[encoder encodeBool:p2StartStop			forKey:@"p2StartStop"];
    //[encoder encodeBool:gateMode				forKey:@"gateMode"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];

    [objDictionary setObject: [NSNumber numberWithLong:enabledMask]                 forKey:@"enabledMask"];
    [objDictionary setObject: [NSNumber numberWithLong:eventConfigMask]             forKey:@"eventConfigMask"];
    [objDictionary setObject: [NSNumber numberWithLong:extendedEventConfigBit]      forKey:@"extendedEventConfigBit"];
    [objDictionary setObject: [NSNumber numberWithLong:endAddressSuppressionMask]   forKey:@"endAddressSuppressionMask"];

    [objDictionary setObject: [NSNumber numberWithLong:histogramsEnabledMask]       forKey:@"histogramsEnabledMask"];
    [objDictionary setObject: [NSNumber numberWithLong:pileupEnabledMask    ]       forKey:@"pileupEnabledMask"];
    [objDictionary setObject: [NSNumber numberWithLong:clrHistogramsWithTSMask]     forKey:@"clrHistogramsWithTSMask"];
    [objDictionary setObject: [NSNumber numberWithLong:writeHitsToEventMemoryMask]  forKey:@"writeHitsToEventMemoryMask"];
    [objDictionary setObject: [NSNumber numberWithLong:heSuppressTriggerMask]       forKey:@"heSuppressTriggerMask"];
    [objDictionary setObject: [NSNumber numberWithLong:trigBothEdgesMask]           forKey:@"trigBothEdgesMask"];
    [objDictionary setObject: [NSNumber numberWithLong:intHeTrigOutPulseMask]       forKey:@"intHeTrigOutPulseMask"];
    

    [self addCurrentState:objDictionary unsignedLongArray:cfdControlBits            size:kNumSIS3316Channels forKey:@"cfdControlBits"];
    [self addCurrentState:objDictionary unsignedLongArray:extraFilterBits           size:kNumSIS3316Channels forKey:@"extraFilterBits"];
    [self addCurrentState:objDictionary unsignedLongArray:tauTableBits              size:kNumSIS3316Channels forKey:@"tauTableBits"];
    [self addCurrentState:objDictionary unsignedLongArray:threshold                 size:kNumSIS3316Channels forKey:@"threshold"];
    [self addCurrentState:objDictionary unsignedLongArray:riseTime                  size:kNumSIS3316Channels forKey:@"riseTime"];
    [self addCurrentState:objDictionary unsignedLongArray:gapTime                   size:kNumSIS3316Channels forKey:@"gapTime"];
    [self addCurrentState:objDictionary unsignedLongArray:tauFactor                 size:kNumSIS3316Channels forKey:@"tauFactor"];
    [self addCurrentState:objDictionary unsignedShortArray:intTrigOutPulseBit       size:kNumSIS3316Channels forKey:@"intTrigOutPulseBit"];
    [self addCurrentState:objDictionary unsignedLongArray:heTrigThreshold           size:kNumSIS3316Channels forKey:@"heTrigThreshold"];
    [self addCurrentState:objDictionary unsignedShortArray:energyDivider            size:kNumSIS3316Channels forKey:@"energyDivider"];
    [self addCurrentState:objDictionary unsignedShortArray:energySubtractor         size:kNumSIS3316Channels forKey:@"energySubtractor"];
    [self addCurrentState:objDictionary unsignedShortArray:dacOffsets               size:kNumSIS3316Groups   forKey:@"daqOffsets"];

    [self addCurrentState:objDictionary unsignedShortArray:activeTrigGateWindowLen  size:kNumSIS3316Groups   forKey:@"activeTrigGateWindowLen" ];
    [self addCurrentState:objDictionary unsignedShortArray:preTriggerDelay          size:kNumSIS3316Groups   forKey:@"preTriggerDelay"];
    [self addCurrentState:objDictionary unsignedLongArray:rawDataBufferLen          size:kNumSIS3316Groups   forKey:@"rawDataBufferLen"];
    [self addCurrentState:objDictionary unsignedLongArray:rawDataBufferStart        size:kNumSIS3316Groups   forKey:@"rawDataBufferStart"];
    
    [self addCurrentState:objDictionary unsignedLongArray:heTrigThresholdSum        size:kNumSIS3316Groups   forKey:@"heTrigThresholdSum"];
    [self addCurrentState:objDictionary unsignedLongArray:thresholdSum              size:kNumSIS3316Groups   forKey:@"ThresholdSum"];

    [self addCurrentState:objDictionary unsignedShortArray:accumulatorGateStart     size:kNumSIS3316Groups   forKey:@"accumulatorGateStart"];
    [self addCurrentState:objDictionary unsignedShortArray:accumulatorGateLength    size:kNumSIS3316Groups   forKey:@"accumulatorGateLength"];
    
    [self addCurrentState:objDictionary unsignedShortArray:triggerDelay             size:kNumSIS3316Groups   forKey:@"triggerDelay"];

    [self addCurrentState:objDictionary unsignedShortArray:accGate1Start            size:kNumSIS3316Groups   forKey:@"accGate1Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate2Start            size:kNumSIS3316Groups   forKey:@"accGate2Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate3Start            size:kNumSIS3316Groups   forKey:@"accGate3Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate4Start            size:kNumSIS3316Groups   forKey:@"accGate4Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate5Start            size:kNumSIS3316Groups   forKey:@"accGate5Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate6Start            size:kNumSIS3316Groups   forKey:@"accGate6Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate7Start            size:kNumSIS3316Groups   forKey:@"accGate7Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate8Start            size:kNumSIS3316Groups   forKey:@"accGate8Start"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate1Len              size:kNumSIS3316Groups   forKey:@"accGate1Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate2Len              size:kNumSIS3316Groups   forKey:@"accGate2Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate3Len              size:kNumSIS3316Groups   forKey:@"accGate3Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate4Len              size:kNumSIS3316Groups   forKey:@"accGate4Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate5Len              size:kNumSIS3316Groups   forKey:@"accGate5Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate6Len              size:kNumSIS3316Groups   forKey:@"accGate6Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate7Len              size:kNumSIS3316Groups   forKey:@"accGate7Len"];
    [self addCurrentState:objDictionary unsignedShortArray:accGate8Len              size:kNumSIS3316Groups   forKey:@"accGate8Len"];

    //csr
	
	//acq
	[objDictionary setObject: [NSNumber numberWithBool:bankSwitchMode]		forKey:@"bankSwitchMode"];
	[objDictionary setObject: [NSNumber numberWithBool:autoStart]			forKey:@"autoStart"];
	[objDictionary setObject: [NSNumber numberWithBool:multiEventMode]		forKey:@"multiEventMode"];
	[objDictionary setObject: [NSNumber numberWithBool:multiplexerMode]		forKey:@"multiplexerMode"];
	[objDictionary setObject: [NSNumber numberWithBool:lemoStartStop]		forKey:@"lemoStartStop"];
	[objDictionary setObject: [NSNumber numberWithBool:p2StartStop]			forKey:@"p2StartStop"];
	[objDictionary setObject: [NSNumber numberWithBool:gateMode]			forKey:@"gateMode"];

 	//clocks
	[objDictionary setObject: [NSNumber numberWithBool:randomClock]			forKey:@"randomClock"];
	[objDictionary setObject: [NSNumber numberWithInt:clockSource]			forKey:@"clockSource"];

	[objDictionary setObject: [NSNumber numberWithInt:pageSize]				forKey:@"pageSize"];
	[objDictionary setObject: [NSNumber numberWithBool:pageWrap]			forKey:@"pageWrap"];
	[objDictionary setObject: [NSNumber numberWithBool:stopTrigger]			forKey:@"stopTrigger"];
	
    return objDictionary;
}

- (NSArray*) autoTests
{
	NSMutableArray* myTests = [NSMutableArray array];
//	[myTests addObject:[ORVmeReadOnlyTest test:kControlStatus wordSize:4 name:@"Control Status"]];
//	[myTests addObject:[ORVmeReadOnlyTest test:kModuleIDReg wordSize:4 name:@"Module ID"]];
//	[myTests addObject:[ORVmeReadOnlyTest test:kAcquisitionControlReg wordSize:4 name:@"Acquisition Reg"]];
//	[myTests addObject:[ORVmeReadWriteTest test:kStartDelay wordSize:4 validMask:0x000000ff name:@"Start Delay"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kGeneralReset wordSize:4 name:@"Reset"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kStartSampling wordSize:4 name:@"Start Sampling"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kStopSampling wordSize:4 name:@"Stop Sampling"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kStartAutoBankSwitch wordSize:4 name:@"Stop Auto Bank Switch"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kStopAutoBankSwitch wordSize:4 name:@"Start Auto Bank Switch"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kClearBank1FullFlag wordSize:4 name:@"Clear Bank1 Full"]];
//	[myTests addObject:[ORVmeWriteOnlyTest test:kClearBank2FullFlag wordSize:4 name:@"Clear Bank2 Full"]];
//	
//	int i;
//	for(i=0;i<4;i++){
//		[myTests addObject:[ORVmeReadWriteTest test:thresholdRegOffsets[i] wordSize:4 validMask:0xffffffff name:@"Threshold"]];
//		int j;
//		for(j=0;j<2;j++){
//			[myTests addObject:[ORVmeReadOnlyTest test:bankMemory[i][j] length:64*1024 wordSize:4 name:@"Adc Memory"]];
//		}
//	}
	return myTests;
}
- (void) writeLong:(unsigned long)aValue toAddress:(unsigned long)anAddress
{
    [[self adapter] writeLongBlock: &aValue
                         atAddress: anAddress
                        numToWrite: 1
                        withAddMod: [self addressModifier]
                     usingAddSpace: 0x01];
}
- (unsigned long) readLongFromAddress:(unsigned long)anAddress
{
    unsigned long aValue = 0;
    [[self adapter] readLongBlock:&aValue
                        atAddress:anAddress
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return aValue;
}

@end

@implementation ORSIS3316Model (private)
- (int) si570FreezeDCO:(int) osc
{
    char ack;
    
    // start
    int rc = [self i2cStart:osc];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    // address
    rc = [self i2cWriteByte:osc data:OSC_ADR<<1 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // register offset
    rc = [self i2cWriteByte:osc data:0x89 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // write data
    rc = [self i2cWriteByte:osc data:0x10 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // stop
    rc = [self i2cStop:osc];
    return rc;
}

- (int) si570Divider:(int) osc values:(unsigned char*)data
{
    int rc;
    char ack;
    int i;
    
    // start
    rc = [self i2cStart:osc];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    // address
    rc = [self i2cWriteByte:osc data:OSC_ADR<<1 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // register offset
    rc = [self i2cWriteByte:osc data:0x0D ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // write data
    for(i = 0;i < 2;i++){
        rc = [self i2cWriteByte:osc data:data[i] ack:&ack];
        if(rc){
            [self i2cStop:osc];
            return rc;
        }
        
        if(!ack){
            [self i2cStop:osc];
            return -101;
        }
    }
    
    // stop
    rc = [self i2cStop:osc];
    return rc;
}

- (int) si570UnfreezeDCO:(int)osc {
    int rc;
    char ack;
    
    // start
    rc = [self i2cStart:osc];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    // address
    rc = [self i2cWriteByte:osc data:OSC_ADR<<1 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // register offset
    
    rc = [self i2cWriteByte:osc data:0x89 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // write data
    rc = [self i2cWriteByte:osc data:0x00 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // stop
    rc = [self i2cStop:osc];
    return rc;
}

- (int) si570NewFreq:(int) osc {
    
    // start
    int rc = [self i2cStart:osc];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    // address
    char ack;
    rc = [self i2cWriteByte:osc data:OSC_ADR<<1 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // register offset
    rc = [self i2cWriteByte:osc data:0x87 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // write data
    rc = [self i2cWriteByte:osc data:0x40 ack:&ack];
    if(rc){
        [self i2cStop:osc];
        return rc;
    }
    
    if(!ack){
        [self i2cStop:osc];
        return -101;
    }
    
    // stop
    
    rc = [self i2cStop:osc];
    return rc;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary unsignedLongArray:(unsigned long*)anArray size:(long)numItems forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<numItems;i++){
        [ar addObject:[NSNumber numberWithLong:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary unsignedShortArray:(unsigned short*)anArray size:(long)numItems forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<numItems;i++){
        [ar addObject:[NSNumber numberWithUnsignedShort:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray size:(long)numItems forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<numItems;i++){
        [ar addObject:[NSNumber numberWithBool:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

@end
