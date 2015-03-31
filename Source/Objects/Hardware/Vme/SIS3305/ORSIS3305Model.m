//-------------------------------------------------------------------------
//  ORSIS3305.h
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

#pragma mark - Imported Files
#import "ORSIS3305Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORVmeTests.h"
#import "ORVmeReadWriteCommand.h"
#import "ORCommandList.h"

NSString* ORSIS3305ModelTDCMeasurementEnabledChanged    = @"ORSIS3305ModelTDCMeasurementEnabledChanged";
NSString* ORSIS3305ModelPulseModeChanged				= @"ORSIS3305ModelPulseModeChanged";
NSString* ORSIS3305ModelFirmwareVersionChanged			= @"ORSIS3305ModelFirmwareVersionChanged";
NSString* ORSIS3305ModelBufferWrapEnabledChanged		= @"ORSIS3305ModelBufferWrapEnabledChanged";
//NSString* ORSIS3305ModelCfdControlChanged				= @"ORSIS3305ModelCfdControlChanged";
NSString* ORSIS3305ModelShipTimeRecordAlsoChanged		= @"ORSIS3305ModelShipTimeRecordAlsoChanged";
NSString* ORSIS3305ModelMcaUseEnergyCalculationChanged  = @"ORSIS3305ModelMcaUseEnergyCalculationChanged";
NSString* ORSIS3305ModelMcaEnergyOffsetChanged			= @"ORSIS3305ModelMcaEnergyOffsetChanged";
NSString* ORSIS3305ModelMcaEnergyMultiplierChanged		= @"ORSIS3305ModelMcaEnergyMultiplierChanged";
NSString* ORSIS3305ModelMcaEnergyDividerChanged			= @"ORSIS3305ModelMcaEnergyDividerChanged";
NSString* ORSIS3305ModelMcaModeChanged					= @"ORSIS3305ModelMcaModeChanged";
NSString* ORSIS3305ModelMcaPileupEnabledChanged			= @"ORSIS3305ModelMcaPileupEnabledChanged";
NSString* ORSIS3305ModelMcaHistoSizeChanged				= @"ORSIS3305ModelMcaHistoSizeChanged";
NSString* ORSIS3305ModelMcaNofScansPresetChanged		= @"ORSIS3305ModelMcaNofScansPresetChanged";
NSString* ORSIS3305ModelMcaAutoClearChanged				= @"ORSIS3305ModelMcaAutoClearChanged";
NSString* ORSIS3305ModelMcaPrescaleFactorChanged		= @"ORSIS3305ModelMcaPrescaleFactorChanged";
NSString* ORSIS3305ModelMcaLNESetupChanged				= @"ORSIS3305ModelMcaLNESetupChanged";
NSString* ORSIS3305ModelMcaNofHistoPresetChanged		= @"ORSIS3305ModelMcaNofHistoPresetChanged";

NSString* ORSIS3305ModelInternalExternalTriggersOredChanged = @"ORSIS3305ModelInternalExternalTriggersOredChanged";
NSString* ORSIS3305ModelLemoInEnabledMaskChanged		= @"ORSIS3305ModelLemoInEnabledMaskChanged";
NSString* ORSIS3305ModelEnergyGateLengthChanged			= @"ORSIS3305ModelEnergyGateLengthChanged";
NSString* ORSIS3305ModelRunModeChanged					= @"ORSIS3305ModelRunModeChanged";
NSString* ORSIS3305ModelEndAddressThresholdChanged		= @"ORSIS3305ModelEndAddressThresholdChanged";
NSString* ORSIS3305ModelEnergySampleStartIndex3Changed	= @"ORSIS3305ModelEnergySampleStartIndex3Changed";
NSString* ORSIS3305ModelEnergyTauFactorChanged			= @"ORSIS3305ModelEnergyTauFactorChanged";
NSString* ORSIS3305ModelEnergySampleStartIndex2Changed	= @"ORSIS3305ModelEnergySampleStartIndex2Changed";
NSString* ORSIS3305ModelEnergySampleStartIndex1Changed	= @"ORSIS3305ModelEnergySampleStartIndex1Changed";
NSString* ORSIS3305ModelEnergyNumberToSumChanged		= @"ORSIS3305ModelEnergyNumberToSumChanged";
NSString* ORSIS3305ModelEnergySampleLengthChanged		= @"ORSIS3305ModelEnergySampleLengthChanged";
NSString* ORSIS3305ModelEnergyGapTimeChanged	 = @"ORSIS3305ModelEnergyGapTimeChanged";
NSString* ORSIS3305ModelEnergyPeakingTimeChanged = @"ORSIS3305ModelEnergyPeakingTimeChanged";
NSString* ORSIS3305ModelTriggerGateLengthChanged = @"ORSIS3305ModelTriggerGateLengthChanged";
NSString* ORSIS3305ModelPreTriggerDelayChanged  = @"ORSIS3305ModelPreTriggerDelayChanged";
NSString* ORSIS3305SampleStartIndexChanged		= @"ORSIS3305SampleStartIndexChanged";
NSString* ORSIS3305SampleLengthChanged			= @"ORSIS3305SampleLengthChanged";
NSString* ORSIS3305DacOffsetChanged				= @"ORSIS3305DacOffsetChanged";
NSString* ORSIS3305LemoInModeChanged			= @"ORSIS3305LemoInModeChanged";
NSString* ORSIS3305LemoOutModeChanged			= @"ORSIS3305LemoOutModeChanged";
NSString* ORSIS3305AcqRegChanged				= @"ORSIS3305AcqRegChanged";
NSString* ORSIS3305EventConfigChanged			= @"ORSIS3305EventConfigChanged";
NSString* ORSIS3305InputInvertedChanged			= @"ORSIS3305InputInvertedChanged";
NSString* ORSIS3305InternalTriggerEnabledChanged = @"ORSIS3305InternalTriggerEnabledChanged";
NSString* ORSIS3305ExternalTriggerEnabledChanged = @"ORSIS3305ExternalTriggerEnabledChanged";
NSString* ORSIS3305InternalGateEnabledChanged	= @"ORSIS3305InternalGateEnabledChanged";
NSString* ORSIS3305ExternalGateEnabledChanged	= @"ORSIS3305ExternalGateEnabledChanged";
NSString* ORSIS3305ExtendedThresholdEnabledChanged = @"ORSIS3305ExtendedThresholdEnabledChanged";

NSString* ORSIS3305ClockSourceChanged			= @"ORSIS3305ClockSourceChanged";
NSString* ORSIS3305EventSavingModeChanged		= @"ORSIS3305EventSavingModeChanged";
NSString* ORSIS3305ChannelEnabledChanged		= @"ORSIS3305ChannelEnabledChanged";

NSString* ORSIS3305RateGroupChangedNotification	= @"ORSIS3305RateGroupChangedNotification";
NSString* ORSIS3305SettingsLock					= @"ORSIS3305SettingsLock";

NSString* ORSIS3305TriggerOutEnabledChanged		= @"ORSIS3305TriggerOutEnabledChanged";
NSString* ORSIS3305HighEnergySuppressChanged	= @"ORSIS3305HighEnergySuppressChanged";
NSString* ORSIS3305ThresholdChanged				= @"ORSIS3305ThresholdChanged";

NSString* ORSIS3305ThresholdModeChanged         = @"ORSIS3305ThresholdModeChanged";

NSString* ORSIS3305GTThresholdOnChanged         = @"ORSIS3305GTThresholdOnChanged";
NSString* ORSIS3305GTThresholdOffChanged        = @"ORSIS3305GTThresholdOffChanged";
NSString* ORSIS3305LTThresholdOnChanged         = @"ORSIS3305LTThresholdOnChanged";
NSString* ORSIS3305LTThresholdOffChanged        = @"ORSIS3305LTThresholdOffChanged";

NSString* ORSIS3305ThresholdArrayChanged		= @"ORSIS3305ThresholdArrayChanged";
//NSString* ORSIS3305HighThresholdChanged			= @"ORSIS3305HighThresholdChanged";
//NSString* ORSIS3305HighThresholdArrayChanged	= @"ORSIS3305HighThresholdArrayChanged";

NSString* ORSIS3305LTThresholdEnabledChanged    = @"ORSIS3305LTThresholdEnabledChanged";
NSString* ORSIS3305GTThresholdEnabledChanged    = @"ORSIS3305GTThresholdEnabledChanged";

//NSString* ORSIS3305LtChanged					= @"ORSIS3305LtChanged";
//NSString* ORSIS3305GtChanged					= @"ORSIS3305GtChanged";
NSString* ORSIS3305SampleDone					= @"ORSIS3305SampleDone";
NSString* ORSIS3305IDChanged					= @"ORSIS3305IDChanged";
NSString* ORSIS3305GateLengthChanged			= @"ORSIS3305GateLengthChanged";
NSString* ORSIS3305PulseLengthChanged			= @"ORSIS3305PulseLengthChanged";
NSString* ORSIS3305SumGChanged					= @"ORSIS3305SumGChanged";
NSString* ORSIS3305PeakingTimeChanged			= @"ORSIS3305PeakingTimeChanged";
NSString* ORSIS3305InternalTriggerDelayChanged	= @"ORSIS3305InternalTriggerDelayChanged";
NSString* ORSIS3305TriggerDecimationChanged		= @"ORSIS3305TriggerDecimationChanged";
NSString* ORSIS3305EnergyDecimationChanged		= @"ORSIS3305EnergyDecimationChanged";
NSString* ORSIS3305SetShipWaveformChanged		= @"ORSIS3305SetShipWaveformChanged";
NSString* ORSIS3305SetShipSummedWaveformChanged	= @"ORSIS3305SetShipSummedWaveformChanged";
NSString* ORSIS3305Adc50KTriggerEnabledChanged	= @"ORSIS3305Adc50KTriggerEnabledChanged";
NSString* ORSIS3305McaStatusChanged				= @"ORSIS3305McaStatusChanged";
NSString* ORSIS3305CardInited					= @"ORSIS3305CardInited";

@interface ORSIS3305Model (private)
//- (void) writeDacOffsets;
- (void) setUpArrays;
//- (void) pollMcaStatus;
- (NSMutableArray*) arrayOfLength:(int)len;
@end

@implementation ORSIS3305Model

#pragma mark - Static Declarations
//offsets from the base address
typedef struct {
	unsigned long offset;
	NSString* name;
} SIS3305GammaRegisterInformation;

#define kNumSIS3305ReadRegs 92

static SIS3305GammaRegisterInformation register_information[kNumSIS3305ReadRegs] = {
	{0x00000,  @"Control/Status"},
	{0x00004,  @"Module Id. and Firmware Revision"},
	{0x00008,  @"Interrupt configuration"},
	{0x0000C,  @"Interrupt control"},
    
    {0x00010,  @"Acquisition control/status"},
    {0x00014,  @"Veto Length"},
    {0x00018,  @"Veto Delay"},
    
    {0x00020,  @"TDC Test Register"},
    {0x00014,  @"TDC Test Register"},
    {0x00028,  @"EEPROM 93C56 Control"},
    {0x0002C,  @"EEPROM DS2430 Onewire Control"},
    
	{0x00030,  @"Broadcast Setup register"},
    {0x00040,  @"LEMO Trigger Out Select"},
    {0x0004C,  @"External Trigger In Counter"},
    {0x00050,  @"TDC Write Cmd / TDC Status"},
    {0x00054,  @"TDC Read Cmd / TDC Read Value"},
    {0x00058,  @"TDC Start/Stop Enable"},
    {0x0005C,  @"TDC FSM Reg4 Value"},
    {0x00060,  @"XILINX JTAG_TEST/JTAG_DATA_IN"},
    {0x00070,  @"Temperature and Temperature Supervisor"},
    {0x00074,  @"ADC Serial Interface (SPI)"},

    {0x000C0,  @"ADC1 ch1-ch4 FPGA Data Transfer Control"},
    {0x000C4,  @"ADC2 ch5-ch8 FPGA Data Transfer Control"},
    {0x000C8,  @"ADC1 ch1-ch4 FPGA Data Transfer Status"},
    {0x000CC,  @"ADC2 ch5-ch8 FPGA Data Transfer Status"},

    {0x000D0,  @"Aurora Protocol Status"},
    {0x000D4,  @"Aurora Data Status"},
    {0x000D8,  @"Aurora Data Pending Request Counter Status"},
    
    
    // Key address registers
    {0x00400,  @"General Reset"},
    {0x00410,  @"Arm Sample Logic"},
    {0x00414,  @"Disarm/Disable Sample Logic"},
    {0x00418,  @"Trigger"},
    {0x0041C,  @"Enable Sample Logic"},

    {0x00420,  @"Set Veto"},
    {0x00424,  @"Clear Veto"},

    {0x00430,  @"ADC Clock Synchronization"},
    {0x00434,  @"Rest ADC-FPGA-Logic"},

    {0x0043C,  @"Trigger Out pulse"},

    
	//group 1
	{0x02000,  @"Event configuration (ADC1 ch1-ch4)"},
	{0x02004,  @"Sample Memory Start Address (ADC1 ch1-ch4)"},
	{0x02008,  @"Sample/Extended Block Length (ADC1 ch1-ch4)"},
	{0x0200C,  @"Direct Memory Pretrigger Block Length register (ADC1 ch1-ch4)"},
    
	{0x02010,  @"Ringbuffer Pretrigger Delay (ADC1 ch1-ch2)"},
	{0x02014,  @"Ringbuffer Pretrigger Delay (ADC1 ch3-ch4)"},
	{0x02018,  @"Direct Memory Max N of Events (ADC1 ch1-ch4)"},
	{0x0201C,  @"End Address Threshold"},
    
	{0x02020,  @"Trigger/Gate GT Threshold (ADC1 ch1)"},
	{0x02024,  @"Trigger/Gate LT Threshold (ADC1 ch1)"},
	{0x02028,  @"Trigger/Gate GT Threshold (ADC1 ch2)"},
	{0x0202C,  @"Trigger/Gate LT Threshold (ADC1 ch2)"},
	{0x02030,  @"Trigger/Gate GT Threshold (ADC1 ch3)"},
	{0x02034,  @"Trigger/Gate LT Threshold (ADC1 ch3)"},
	{0x02038,  @"Trigger/Gate GT Threshold (ADC1 ch4)"},
	{0x0203C,  @"Trigger/Gate LT Threshold (ADC1 ch4)"},

    {0x02040,  @"Sampling Status (ADC1 ch1-ch4)"},
	{0x02044,  @"Actual Sample Address (ADC1 ch1-ch4)"},
	{0x02048,  @"Direct Memory Event Counter (ADC1 ch1-ch4)"},
	{0x0204C,  @"Direct Memory Actual Event Start Address (ADC1 ch1-ch4)"},
    
	{0x02050,  @"Actual Sample Value (ADC1 ch1-ch2)"},
	{0x02054,  @"Actual Sample Value (ADC1 ch3-ch4)"},
    
	{0x02058,  @"Aurora Protocol/Data Status (ADC1)"},
	{0x0205C,  @"Internal Status (ADC1)"},
    
	{0x02060,  @"Aurora Protocol TX Live counter (ADC1)"},
    
	{0x02070,  @"Individual Channel Select/Set Veto (ADC1 ch1-ch4)"},
 
    {0x02400,  @"Input Tap Delay (ADC1 ch1-ch4)"},
	
    
	//group 2
	{0x03000,  @"Event configuration (ADC2 ch5-ch8)"},
    {0x03004,  @"Sample Memory Start Address (ADC2 ch5-ch8)"},
    {0x03008,  @"Sample/Extended Block Length (ADC2 ch5-ch8)"},
    {0x0300C,  @"Direct Memory Pretrigger Block Length register (ADC2 ch5-ch8)"},
    
    {0x03010,  @"Ringbuffer Pretrigger Delay (ADC2 ch5-ch8)"},
    {0x03014,  @"Ringbuffer Pretrigger Delay (ADC2 ch5-ch8)"},
    {0x03018,  @"Direct Memory Max N of Events (ADC2 ch5-ch8)"},
    {0x0301C,  @"End Address Threshold"},
    
    {0x03020,  @"Trigger/Gate GT Threshold (ADC2 ch5)"},
    {0x03024,  @"Trigger/Gate LT Threshold (ADC2 ch5)"},
    {0x03028,  @"Trigger/Gate GT Threshold (ADC2 ch6)"},
    {0x0302C,  @"Trigger/Gate LT Threshold (ADC2 ch6)"},
    {0x03030,  @"Trigger/Gate GT Threshold (ADC2 ch7)"},
    {0x03034,  @"Trigger/Gate LT Threshold (ADC2 ch7)"},
    {0x03038,  @"Trigger/Gate GT Threshold (ADC2 ch8)"},
    {0x0303C,  @"Trigger/Gate LT Threshold (ADC2 ch8)"},
    
    {0x03040,  @"Sampling Status (ADC2 ch5-ch8)"},
    {0x03044,  @"Next Sample Address (ADC2 ch5-ch8)"},
    {0x03048,  @"Direct Memory Event Counter (ADC2 ch5-ch8)"},
    {0x0304C,  @"Direct Memory Actual Event Start Address (ADC2 ch5-ch8)"},
    
    {0x03050,  @"Actual Sample Value (ADC2 ch5-ch6)"},
    {0x03054,  @"Actual Sample Value (ADC2 ch7-ch8)"},
    
    {0x03058,  @"Aurora Protocol/Data Status (ADC2)"},
    {0x0305C,  @"Internal Status (ADC2)"},
    
    {0x03060,  @"Aurora Protocol TX Live counter (ADC2)"},
    
    {0x03070,  @"Individual Channel Select/Set Veto (ADC2 ch5-ch8)"},
    
    {0x03400,  @"Input Tap Delay (ADC2 ch5-ch8)"},
    
};

#pragma mark - Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x41000000];
    [self initParams];
	
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[gateLengths release];
	[pulseLengths release];
	[peakingTimes release];
	[internalTriggerDelays release];
	[endAddressThresholds release];
 	[thresholds release];
//	[highThresholds release];
	
//	[cfdControls release];
    [dacOffsets release];
	[sumGs release];
	[sampleLengths release];
    [sampleStartIndexes release];
    [preTriggerDelays release];
    [triggerGateLengths release];
	[triggerDecimations release];
    [energyGateLengths release];
	[energyPeakingTimes release];
    [energyGapTimes release];
    [energyTauFactors release];
	[energyDecimations release];
	
	[waveFormRateGroup release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3305Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3305Controller"];
}

- (NSString*) helpURL
{
	return @"VME/SIS3305_(Gamma).html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress, 0x00780000 + (8*0x1024*0x1024));
}

#pragma mark - Accessors

#pragma mark -- Board Settings

- (int) clockSource
{
    return clockSource;
}

- (void) setClockSource:(int)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = [self limitIntValue:aClockSource min:0 max:1];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ClockSourceChanged object:self];
}

- (short) eventSavingMode:(short)aGroup
{
    return eventSavingMode[aGroup];
}

- (void) setEventSavingModeOf:(short)aGroup toValue:(short)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEventSavingModeOf:aGroup toValue:aMode];
    eventSavingMode[aGroup] = [self limitIntValue:aMode min:0 max:3];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305EventSavingModeChanged object:self];
}


- (BOOL) TDCMeasurementEnabled {
    return TDCMeasurementEnabled;
}

- (void) setTDCMeasurementEnabled: (BOOL)aState {
    
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseMode:TDCMeasurementEnabled];
    
    TDCMeasurementEnabled = aState;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelTDCMeasurementEnabledChanged object:self];
}

- (float) firmwareVersion
{
    return firmwareVersion;
}

- (void) setFirmwareVersion:(float)aFirmwareVersion
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFirmwareVersion:firmwareVersion];
    
    firmwareVersion = aFirmwareVersion;
    if(firmwareVersion >= 15.0  && runMode == kMcaRunMode)[self setRunMode:kEnergyRunMode];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelFirmwareVersionChanged object:self];
}


- (BOOL) shipTimeRecordAlso
{
    return shipTimeRecordAlso;
}

- (void) setShipTimeRecordAlso:(BOOL)aShipTimeRecordAlso
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipTimeRecordAlso:shipTimeRecordAlso];
    
    shipTimeRecordAlso = aShipTimeRecordAlso;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelShipTimeRecordAlsoChanged object:self];
}


#pragma mark -- Group settings
/*
 Internal trigger enabling
 
 The internal trigger enable mask is 8-bits, each representing a channel
 
 */
//- (short) internalTriggerEnabledMask { return internalTriggerEnabledMask; }
/*
 Internal trigger enabling
 
 The internal trigger enable mask is 8-bits, each representing a channel
 
 
 */

- (void) setInternalTriggerEnabled:(short)chan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInternalTriggerEnabled:chan withValue:internalTriggerEnabled[chan]];
    internalTriggerEnabled[chan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305InternalTriggerEnabledChanged object:self];
}
- (BOOL) internalTriggerEnabled:(short)chan { return internalTriggerEnabled[chan]; }

- (short) externalTriggerEnabledMask { return externalTriggerEnabledMask; }



#pragma mark -- Channel settings

- (BOOL) enabled:(short)chan{
    return enabled[chan];
}

- (void) setEnabled:(short)chan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:chan withValue:enabled[chan]];
    enabled[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ChannelEnabledChanged object:self userInfo:userInfo];
}

//- (BOOL) LTThresholdEnabled:(short)aChan;
//- (BOOL) GTThresholdEnabled:(short)aChan;
//- (void) setLTThresholdEnabled:(short)aChan withValue:(BOOL)aValue;
//- (void) setGTThresholdEnabled:(short)aChan withValue:(BOOL)aValue;

- (BOOL) LTThresholdEnabled:(short)aChan{    return LTThresholdEnabled[aChan];}
- (BOOL) GTThresholdEnabled:(short)aChan{    return GTThresholdEnabled[aChan];}

- (void) setLTThresholdEnabled:(short)aChan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLTThresholdEnabled:aChan withValue:aValue];
    LTThresholdEnabled[aChan] = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LTThresholdEnabledChanged object:self];
//    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ThresholdModeChanged object:self];

}

- (void) setGTThresholdEnabled:(short)aChan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGTThresholdEnabled:aChan withValue:aValue];

    if (aValue<=3 && aValue>=0) {
        GTThresholdEnabled[aChan] = aValue;
    }
    else
        NSLog(@"That wasn't supposed to happen...");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305GTThresholdEnabledChanged object:self];
//    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ThresholdModeChanged object:self];

}


//- (short) ltMask { return ltMask; }
//- (BOOL) lt:(short)chan	 { return ltMask & (1<<chan); }
//- (void) setLtMask:(long)aMask
//{
//    [[[self undoManager] prepareWithInvocationTarget:self] setLtMask:ltMask];
//    ltMask = aMask;
//    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LtChanged object:self];
//}
//
//- (void) setLtBit:(short)chan withValue:(BOOL)aValue
//{
//    unsigned char aMask = ltMask;
//    if(aValue)aMask |= (1<<chan);
//    else aMask &= ~(1<<chan);
//    [self setLtMask:aMask];
//}
//
//- (short) gtMask { return gtMask; }
//- (BOOL) gt:(short)chan	 { return gtMask & (1<<chan); }
//- (void) setGtMask:(long)aMask
//{
//    [[[self undoManager] prepareWithInvocationTarget:self] setGtMask:gtMask];
//    gtMask = aMask;
//    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305GtChanged object:self];
//}
//
//- (void) setGtBit:(short)chan withValue:(BOOL)aValue
//{
//    unsigned char aMask = gtMask;
//    if(aValue)aMask |= (1<<chan);
//    else aMask &= ~(1<<chan);
//    [self setGtMask:aMask];
//}

- (int) limitIntValue:(int)aValue min:(int)aMin max:(int)aMax
{
    if(aValue<aMin)return aMin;
    else if(aValue>aMax)return aMax;
    else return aValue;
}

//- (int) threshold:(short)aChan { return [[thresholds objectAtIndex:aChan]intValue]; }


//- (void) setThreshold:(short)aChan withValue:(int)aValue
//{
//    aValue = [self limitIntValue:aValue min:0 max:0x1FFFF];
//    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
//    
//    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
//
//    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ThresholdChanged object:self];
//    //ORAdcInfoProviding protocol requirement
//    [self postAdcInfoProvidingValueChanged];
//}


/* 
    A note on the way threshod modes are implemented
    threshold mode (thresholdMode) is a composite of which thresholds are enabled (GT, LT, GT&LT, !(GT||LT) ).
    You may want to set individually which of these is true, or you may just want to set the mode. 
    In order to encode this correctly for saving,
 
 */

- (short) thresholdMode:(short)chan
{
    /*
        0: Disabled
        1: GT
        2: LT
        3: GT AND LT
     */
    
    BOOL gt = [self GTThresholdEnabled:chan];
    BOOL lt = [self LTThresholdEnabled:chan];
    short mode = -1;

    mode = gt + 2*lt;
    
//    if (!gt && !lt)
//        mode = 0;
//    else if (gt && !lt)
//        mode = 1;
//    else if (!gt && lt)
//        mode = 2;
//    else if (gt && lt)
//        mode = 3;
//    else
//        mode = -1;
    
    
//    WARNING: THIS MAY NOT WORK RIGHT YET - SJM
//    if (mode !=thresholdMode[chan]) {
//        [self setThresholdMode:chan withValue:mode];
//    }
    
    return mode;
}

- (void) setThresholdMode:(short)chan withValue:(short)aValue
{
//    [[[self undoManager] prepareWithInvocationTarget:self] setGTThresholdEnabled:chan withValue:[self GTThresholdEnabled:chan]];
//    [[[self undoManager] prepareWithInvocationTarget:self] setLTThresholdEnabled:chan withValue:[self LTThresholdEnabled:chan]];
    [[[self undoManager] prepareWithInvocationTarget:self] setThresholdMode:chan withValue:[self thresholdMode:chan]];
    
    thresholdMode[chan] = aValue;
    switch (aValue) {
        case 0:
            [self setGTThresholdEnabled:chan withValue:NO];
            [self setLTThresholdEnabled:chan withValue:NO];
            break;
        case 1:
            [self setGTThresholdEnabled:chan withValue:YES];
            [self setLTThresholdEnabled:chan withValue:NO];
            break;
        case 2:
            [self setGTThresholdEnabled:chan withValue:NO];
            [self setLTThresholdEnabled:chan withValue:YES];
            break;
        case 3:
            [self setGTThresholdEnabled:chan withValue:YES];
            [self setLTThresholdEnabled:chan withValue:YES];
            break;
        default:    // I make the default case to enable both, but we shouldn't get here -SJM
            [self setGTThresholdEnabled:chan withValue:YES];
            [self setLTThresholdEnabled:chan withValue:YES];
            NSLog(@"Threshold mode was somehow set to %d, please report this error!",aValue);
            break;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ThresholdModeChanged object:self];

    //ORAdcInfoProviding protocol requirement ?
    //[self postAdcInfoProvidingValueChanged];
    
}



- (int) LTThresholdOn:(short)aChan { return LTThresholdOn[aChan]; }
- (void) setLTThresholdOn:(short)aChan withValue:(int)aValue
{
    aValue = [self limitIntValue:aValue min:0 max:0x3FF];
    [[[self undoManager] prepareWithInvocationTarget:self] setLTThresholdOn:aChan withValue:[self LTThresholdOn:aChan]];
    
    LTThresholdOn[aChan] = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LTThresholdOnChanged object:self];
    //ORAdcInfoProviding protocol requirement
    //[self postAdcInfoProvidingValueChanged];
}

- (int) LTThresholdOff:(short)aChan { return LTThresholdOff[aChan]; }
- (void) setLTThresholdOff:(short)aChan withValue:(int)aValue
{
    aValue = [self limitIntValue:aValue min:0 max:0x3FF];
    [[[self undoManager] prepareWithInvocationTarget:self] setLTThresholdOff:aChan withValue:[self LTThresholdOff:aChan]];
    
    LTThresholdOff[aChan] = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LTThresholdOffChanged object:self];
    //ORAdcInfoProviding protocol requirement
    //[self postAdcInfoProvidingValueChanged];
}

- (int) GTThresholdOn:(short)aChan { return GTThresholdOn[aChan]; }
- (void) setGTThresholdOn:(short)aChan withValue:(int)aValue
{
    aValue = [self limitIntValue:aValue min:0 max:0x3FF];
    [[[self undoManager] prepareWithInvocationTarget:self] setGTThresholdOn:aChan withValue:[self GTThresholdOn:aChan]];
    
    GTThresholdOn[aChan] = aValue;
//    [GTThresholdOn replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305GTThresholdOnChanged object:self];
    //ORAdcInfoProviding protocol requirement
    //[self postAdcInfoProvidingValueChanged];
}

- (int) GTThresholdOff:(short)aChan { return GTThresholdOff[aChan]; }
- (void) setGTThresholdOff:(short)aChan withValue:(int)aValue
{
    aValue = [self limitIntValue:aValue min:0 max:0x3FF];
    [[[self undoManager] prepareWithInvocationTarget:self] setGTThresholdOff:aChan withValue:[self GTThresholdOff:aChan]];
    
    GTThresholdOff[aChan] = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305GTThresholdOffChanged object:self];
    //ORAdcInfoProviding protocol requirement
    //[self postAdcInfoProvidingValueChanged];
}

//- (int) highThreshold:(short)aChan { return [[highThresholds objectAtIndex:aChan]intValue]; }
//- (void) setHighThreshold:(short)aChan withValue:(int)aValue
//{
//    aValue = [self limitIntValue:aValue min:0 max:0x1FFFF];
//    [[[self undoManager] prepareWithInvocationTarget:self] setHighThreshold:aChan withValue:[self highThreshold:aChan]];
//    [highThresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
//    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305HighThresholdChanged object:self];
//    //ORAdcInfoProviding protocol requirement
//    [self postAdcInfoProvidingValueChanged];
//}

- (unsigned short) gain:(unsigned short) aChan
{
    return 0;
}
- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain
{
}
//- (BOOL) partOfEvent:(unsigned short)chan
//{
////    return (gtMask & (1L<<chan)) != 0;
//}

//- (BOOL)onlineMaskBit:(int)bit
//{
//    //translate back to the triggerEnabled Bit
////    return (gtMask & (1L<<bit)) != 0;
//}

- (unsigned short) sampleLength:(short)aChan {
    return [[sampleLengths objectAtIndex:aChan] unsignedShortValue];
}

- (void) setSampleLength:(short)aChan withValue:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleLength:aChan withValue:[self sampleLength:aChan]];
    aValue = [self limitIntValue:aValue min:4 max:0xfffc];
    aValue = (aValue/4)*4;
    [sampleLengths replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [self calculateSampleValues];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305SampleLengthChanged object:self];
}

- (unsigned short) dacOffset:(short)aChan { return [[dacOffsets objectAtIndex:aChan]intValue]; }
- (void) setDacOffset:(short)aChan withValue:(int)aValue
{
    aValue = [self limitIntValue:aValue min:0 max:0xffff];
    [[[self undoManager] prepareWithInvocationTarget:self] setDacOffset:aChan withValue:[self dacOffset:aChan]];
    [dacOffsets replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305DacOffsetChanged object:self];
}

- (short) gateLength:(short)aChan { return [[gateLengths objectAtIndex:aChan] shortValue]; }
- (void) setGateLength:(short)aChan withValue:(short)aValue
{
    aValue = [self limitIntValue:aValue min:0 max:0x3f];
    [[[self undoManager] prepareWithInvocationTarget:self] setGateLength:aChan withValue:[self gateLength:aChan]];
    [gateLengths replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305GateLengthChanged object:self];
}

- (short) pulseLength:(short)aChan { return [[pulseLengths objectAtIndex:aChan] shortValue]; }
- (void) setPulseLength:(short)aChan withValue:(short)aValue
{
    aValue = [self limitIntValue:aValue min:0 max:0xff];
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseLength:aChan withValue:[self pulseLength:aChan]];
    [pulseLengths replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305PulseLengthChanged object:self];
}

- (short) sumG:(short)aChan { return [[sumGs objectAtIndex:aChan] shortValue]; }
- (void) setSumG:(short)aChan withValue:(short)aValue
{
    short temp = [self peakingTime:aChan];
    aValue = [self limitIntValue:aValue min:0 max:0x3ff];
    [[[self undoManager] prepareWithInvocationTarget:self] setSumG:aChan withValue:[self sumG:aChan]];
    if (aValue < temp) aValue = temp;
    [sumGs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305SumGChanged object:self];
}

- (short) peakingTime:(short)aChan { return [[peakingTimes objectAtIndex:aChan] shortValue]; }
- (void) setPeakingTime:(short)aChan withValue:(short)aValue
{
    short temp = [self sumG:aChan];
    aValue = [self limitIntValue:aValue min:0 max:0x3ff];
    [[[self undoManager] prepareWithInvocationTarget:self] setPeakingTime:aChan withValue:[self peakingTime:aChan]];
    if (temp < aValue) [self setSumG:aChan withValue:aValue];
    [peakingTimes replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305PeakingTimeChanged object:self];
}


- (short) internalTriggerDelay:(short)aChan { return [[internalTriggerDelays objectAtIndex:aChan] shortValue]; }
- (void) setInternalTriggerDelay:(short)aChan withValue:(short)aValue
{
    aValue = [self limitIntValue:aValue min:0 max:firmwareVersion<15?63:255];
    [[[self undoManager] prepareWithInvocationTarget:self] setInternalTriggerDelay:aChan withValue:[self internalTriggerDelay:aChan]];
    
    
    [internalTriggerDelays replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305InternalTriggerDelayChanged object:self];
    
    //force a constraint check by reloading the pretrigger delay
    [self setPreTriggerDelay:aChan/2 withValue:[self preTriggerDelay:aChan/2]];
}






#pragma mark -- Unsorted 
- (BOOL) pulseMode
{
    return pulseMode;
}

- (void) setPulseMode:(BOOL)aPulseMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseMode:pulseMode];
    
    pulseMode = aPulseMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelPulseModeChanged object:self];
}


- (BOOL) internalExternalTriggersOred {
    return internalExternalTriggersOred;
}

- (void) setInternalExternalTriggersOred:(BOOL)aInternalExternalTriggersOred
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInternalExternalTriggersOred:internalExternalTriggersOred];
    internalExternalTriggersOred = aInternalExternalTriggersOred;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelInternalExternalTriggersOredChanged object:self];
}

- (unsigned short) lemoInEnabledMask {
    return lemoInEnabledMask;
}

- (void) setLemoInEnabledMask:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoInEnabledMask:lemoInEnabledMask];
    lemoInEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelLemoInEnabledMaskChanged object:self];
}

- (BOOL) lemoInEnabled:(unsigned short)aBit {
    return lemoInEnabledMask & (1<<aBit);
}

- (void) setLemoInEnabled:(unsigned short)aBit withValue:(BOOL)aState
{
	unsigned short aMask = [self lemoInEnabledMask];
	if(aState)	aMask |= (1<<aBit);
	else		aMask &= ~(1<<aBit);
	[self setLemoInEnabledMask:aMask];
}

- (int) runMode {
    return runMode;
}

- (void) setRunMode:(int)aRunMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunMode:runMode];
    runMode = aRunMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelRunModeChanged object:self];
	[self calculateSampleValues];
}

- (int) energySampleStartIndex3 {
    return energySampleStartIndex3;
}

- (void) setEnergySampleStartIndex3:(int)aEnergySampleStartIndex3
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergySampleStartIndex3:energySampleStartIndex3];
    energySampleStartIndex3 = aEnergySampleStartIndex3;
	[self calculateSampleValues];
	[self calculateEnergyGateLength];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergySampleStartIndex3Changed object:self];
}

- (int) energySampleStartIndex2 {
    return energySampleStartIndex2;
}

- (void) setEnergySampleStartIndex2:(int)aEnergySampleStartIndex2
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergySampleStartIndex2:energySampleStartIndex2];
    energySampleStartIndex2 = aEnergySampleStartIndex2;
	[self calculateSampleValues];
	[self calculateEnergyGateLength];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergySampleStartIndex2Changed object:self];
}

- (int) energySampleStartIndex1 {
    return energySampleStartIndex1;
}

- (void) setEnergySampleStartIndex1:(int)aEnergySampleStartIndex1
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergySampleStartIndex1:energySampleStartIndex1];
    energySampleStartIndex1 = aEnergySampleStartIndex1;
	[self calculateSampleValues];
	[self calculateEnergyGateLength];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergySampleStartIndex1Changed object:self];
}

- (int) energyNumberToSum {
    return energyNumberToSum;
}

- (void) setEnergyNumberToSum:(int)aNumberToSum
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyNumberToSum:energyNumberToSum];
    energyNumberToSum = [self limitIntValue:aNumberToSum min:4 max:256];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergyNumberToSumChanged object:self];
}	

- (int) energySampleLength {
    return energySampleLength;
}

- (void) setEnergySampleLength:(int)aEnergySampleLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergySampleLength:energySampleLength];
    energySampleLength = [self limitIntValue:aEnergySampleLength min:0 max:kSIS3305MaxEnergyWaveform];
	[self calculateSampleValues];
	[self calculateEnergyGateLength];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergySampleLengthChanged object:self];
}

- (int) energyTauFactor:(short)aChannel 
{ 
	if(aChannel>=kNumSIS3305Channels)return 0;
	return [[energyTauFactors objectAtIndex:aChannel] intValue];
}
- (void) setEnergyTauFactor:(short)aChannel withValue:(int)aValue
{
	if(aChannel>=kNumSIS3305Channels)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyTauFactor:aChannel withValue:[self energyTauFactor:aChannel]];
    int energyTauFactor = [self limitIntValue:aValue min:0 max:0x3f];
	[energyTauFactors replaceObjectAtIndex:aChannel withObject:[NSNumber numberWithInt:energyTauFactor]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergyTauFactorChanged object:self];
}
- (int) energyGapTime:(short)aGroup 
{ 
	if(aGroup>=kNumSIS3305Groups)return 0;
	return [[energyGapTimes objectAtIndex:aGroup] intValue]; 
}
- (void) setEnergyGapTime:(short)aGroup withValue:(int)aValue
{
	if(aGroup>=kNumSIS3305Groups)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyGapTime:aGroup withValue:[self energyGapTime:aGroup]];
    aValue = [self limitIntValue:aValue min:0 max:0xff];
	[energyGapTimes replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergyGapTimeChanged object:self];
	[self calculateEnergyGateLength];
}

- (int) energyPeakingTime:(short)aGroup 
{ 
	if(aGroup>=kNumSIS3305Groups)return 0;
	return [[energyPeakingTimes objectAtIndex:aGroup] intValue]; 
}
- (void) setEnergyPeakingTime:(short)aGroup withValue:(int)aValue
{
	if(aGroup>=kNumSIS3305Groups)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyPeakingTime:aGroup withValue:[self energyPeakingTime:aGroup]];
    int energyPeakingTime = [self limitIntValue:aValue min:0 max:0x3ff];
	[energyPeakingTimes replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:energyPeakingTime]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergyPeakingTimeChanged object:self];
	[self calculateEnergyGateLength];
}

- (int) energyGateLength:(short)aGroup 
{ 
	if(aGroup>=kNumSIS3305Groups)return 0;
	return [[energyGateLengths objectAtIndex:aGroup] intValue]; 
}
- (void) setEnergyGateLength:(short)aGroup withValue:(int)aEnergyGateLength
{
	if(aGroup>=kNumSIS3305Groups)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyGateLength:aGroup withValue:[self energyGateLength:aGroup]];
	
	if([self bufferWrapEnabled:aGroup]){
		unsigned long checkValue = [self sampleLength:aGroup] - [self sampleStartIndex:aGroup];
		//unsigned long maxValue = firmwareVersion>=15?255:63;
		if(aEnergyGateLength < checkValue)	aEnergyGateLength = checkValue;
		//if(aEnergyGateLength > maxValue)	aEnergyGateLength = maxValue;
	}
	
	[energyGateLengths replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:aEnergyGateLength]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergyGateLengthChanged object:self];
}

- (int) triggerGateLength:(short)aGroup 
{
	if(aGroup>=kNumSIS3305Groups)return 0;
	return [[triggerGateLengths objectAtIndex:aGroup] intValue]; 
}
- (void) setTriggerGateLength:(short)aGroup withValue:(int)aTriggerGateLength
{
	if(aGroup>=kNumSIS3305Groups)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerGateLength:aGroup withValue:[self triggerGateLength:aGroup]];
	if (aTriggerGateLength < [self sampleLength:aGroup]) aTriggerGateLength = [self sampleLength:aGroup];
    int triggerGateLength = [self limitIntValue:aTriggerGateLength min:0 max:65535];
	[triggerGateLengths replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:triggerGateLength]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelTriggerGateLengthChanged object:self];
}

- (int) preTriggerDelay:(short)aGroup 
{ 
	if(aGroup>=kNumSIS3305Groups)return 0;
	return [[preTriggerDelays objectAtIndex:aGroup]intValue]; 
}

- (void) setPreTriggerDelay:(short)aGroup withValue:(int)aPreTriggerDelay
{
	if(aGroup>=kNumSIS3305Groups)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setPreTriggerDelay:aGroup withValue:[self preTriggerDelay:aGroup]];
    int preTriggerDelay = [self limitIntValue:aPreTriggerDelay min:1 max:1023];
	
	short maxInternalTrigDelay = MAX([self internalTriggerDelay:aGroup*2],[self internalTriggerDelay:aGroup*2+1]);
	short decimation = powf(2.,(float)[self triggerDecimation:aGroup]);
	if(preTriggerDelay< (decimation + maxInternalTrigDelay)){
		preTriggerDelay = decimation + maxInternalTrigDelay;
		NSLogColor([NSColor redColor], @"SIS3305: Increased the pretrigger delay (group %d) to be >= decimation+triggerDelay\n",aGroup);
	}
	
	[preTriggerDelays replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:preTriggerDelay]];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelPreTriggerDelayChanged object:self];
	[self calculateEnergyGateLength];
}

- (int) sampleStartIndex:(int)aGroup 
{ 
	if(aGroup>=kNumSIS3305Groups)return 0;
	return [[sampleStartIndexes objectAtIndex:aGroup] intValue];
}
- (void) setSampleStartIndex:(int)aGroup withValue:(unsigned short)aSampleStartIndex
{
	if(aGroup>=kNumSIS3305Groups)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleStartIndex:aGroup withValue:[self sampleStartIndex:aGroup]];
    int sampleStartIndex = aSampleStartIndex & 0xfffe;
	[sampleStartIndexes replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:sampleStartIndex]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305SampleStartIndexChanged object:self];
}

- (short) lemoInMode { return lemoInMode; }
- (void) setLemoInMode:(short)aLemoInMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoInMode:lemoInMode];
    lemoInMode = aLemoInMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoInModeChanged object:self];
}

- (NSString*) lemoInAssignments
{
	if(runMode == kEnergyRunMode){
		if(lemoInMode == 0)      return @"3:Trigger\n2:TimeStamp Clr\n1:Veto";
		else if(lemoInMode == 1) return @"3:Trigger\n2:TimeStamp Clr\n1:Gate";
		else if(lemoInMode == 2) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else if(lemoInMode == 3) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else if(lemoInMode == 4) return @"3:N+1 Trig/Gate In\n2:Trigger\n1:N-1 Trig/Gate In";
		else if(lemoInMode == 5) return @"3:N+1 Trig/Gate In\n2:TimeStamp Clr\n1:N-1 Trig/Gate In";
		else if(lemoInMode == 6) return @"3:N+1 Trig/Gate In\n2:Veto\n1:N-1 Trig/Gate In";
		else if(lemoInMode == 7) return @"3:N+1 Trig/Gate In\n2:Gate\n1:N-1 Trig/Gate In";
		else return @"Undefined";
	} 
	else {
		if(lemoInMode == 0)      return @"3:Reserved\n2:Ext MCA Start\n1:Ext Next Pulse";
		else if(lemoInMode == 1) return @"3:Trigger\n2:Ext MCA Start\n1:Ext Next Pulse";
		else if(lemoInMode == 2) return @"3:Veto\n2:Ext MCA Start\n1:Ext Next Pulse";
		else if(lemoInMode == 3) return @"3:Gate\n2:Ext MCA Start\n1:Ext Next Pulse";
		else if(lemoInMode == 4) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else if(lemoInMode == 5) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else if(lemoInMode == 6) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else if(lemoInMode == 7) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else return @"Undefined";
	}
}

- (short) lemoOutMode { return lemoOutMode; }
- (void) setLemoOutMode:(short)aLemoOutMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutMode:lemoOutMode];
    lemoOutMode = aLemoOutMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305LemoOutModeChanged object:self];
}
- (NSString*) lemoOutAssignments
{
	if(runMode == kEnergyRunMode){
		if(lemoOutMode == 0)      return @"3:Sample logic armed\n2:Busy\n1:Trigger output";
		else if(lemoOutMode == 1) return @"3:Sample logic armed\n2:Busy or Veto\n1:Trigger output";
		else if(lemoOutMode == 2) return @"3:N+1 Trig/Gate Out\n2:Trigger output\n1:N-1 Trig/Gate Out";
		else if(lemoOutMode == 3) return @"3:N+1 Trig/Gate Out\n2:Busy or Veto\n1:N-1 Trig/Gate Out";
		else return @"Undefined";
	} 
	else {
		if(lemoOutMode == 0)      return @"3:Sample logic armed\n2:Busy\n1:Trigger output";
		else if(lemoOutMode == 1) return @"3:First Scan Signal\n2:LNE\n1:Scan Enable";
		else if(lemoOutMode == 2) return @"3:Scan Enable\n2:LNE\n1:Trigger Output";
		else if(lemoOutMode == 3) return @"3:Reserved\n2:Reserved\n1:Reserved";
		else return @"Undefined";
	}
}

- (void) setDefaults
{
	[self setRunMode:kEnergyRunMode];
	int i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[self setThreshold:i withValue:0x64];
//		[self setHighThreshold:i withValue:0x0];
		[self setPeakingTime:i withValue:250];
		[self setSumG:i withValue:263];
		[self setInternalTriggerDelay:i withValue:0];
		[self setDacOffset:i withValue:30000];
        [self setLTThresholdEnabled:i withValue:YES];
        [self setGTThresholdEnabled:i withValue:YES];
        [self setLTThresholdOff:i withValue:1023];
        [self setLTThresholdOn:i withValue:1023];
        [self setGTThresholdOff:i withValue:1023];
        [self setGTThresholdOn:i withValue:1023];
	}
	for(i=0;i<kNumSIS3305Groups;i++){
		[self setSampleLength:i withValue:2048];
		[self setPreTriggerDelay:i withValue:1];
		[self setTriggerGateLength:i withValue:2048];
		[self setTriggerDecimation:i withValue:0];
		[self setEnergyDecimation:i withValue:0];
		[self setSampleStartIndex:i withValue:0];
		[self setEnergyPeakingTime:i withValue:100];
		[self setEnergyGapTime:i withValue:25];
        [self setInternalTriggerEnabled:i withValue:YES];
	}
	
	[self setShipEnergyWaveform:NO];
	[self setShipSummedWaveform:NO];
	[self setTriggerOutEnabledMask:0x0];
	[self setHighEnergySuppressMask:0x0];
	[self setInputInvertedMask:0x0];
	[self setAdc50KTriggerEnabledMask:0x00];
	[self setInternalGateEnabledMask:0xff];
	[self setExternalGateEnabledMask:0x00];
	[self setExtendedThresholdEnabledMask:0x00];
	
	[self setBufferWrapEnabledMask:0x0];
	[self setExternalTriggerEnabledMask:0x0];
	
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
	 postNotificationName:ORSIS3305RateGroupChangedNotification
	 object:self];    
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) initParams
{
	[self setUpArrays];
//	[self setDefaults];
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumSIS3305Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

- (short) bufferWrapEnabledMask { return bufferWrapEnabledMask; }
- (void) setBufferWrapEnabledMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setBufferWrapEnabledMask:bufferWrapEnabledMask];
	bufferWrapEnabledMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelBufferWrapEnabledChanged object:self];
}

- (BOOL) bufferWrapEnabled:(short)group 
{ 
	if(group>=0 && group<kNumSIS3305Groups) return bufferWrapEnabledMask & (1<<group); 
	else return NO;
}
- (void) setBufferWrapEnabled:(short)group withValue:(BOOL)aValue
{
	if(group>=0 && group<kNumSIS3305Groups){
		unsigned char aMask = bufferWrapEnabledMask;
		if(aValue)aMask |= (1<<group);
		else aMask &= ~(1<<group);
		[self setBufferWrapEnabledMask:aMask];
	}
}


- (void) setExternalTriggerEnabledMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setExternalTriggerEnabledMask:externalTriggerEnabledMask];
	externalTriggerEnabledMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ExternalTriggerEnabledChanged object:self];
}

- (BOOL) externalTriggerEnabled:(short)chan { return externalTriggerEnabledMask & (1<<chan); }
- (void) setExternalTriggerEnabled:(short)chan withValue:(BOOL)aValue
{
	unsigned char aMask = externalTriggerEnabledMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setExternalTriggerEnabledMask:aMask];
}

- (short) internalGateEnabledMask { return internalGateEnabledMask; }
- (void) setInternalGateEnabledMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setInternalGateEnabledMask:internalGateEnabledMask];
	internalGateEnabledMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305InternalGateEnabledChanged object:self];
}

- (BOOL) internalGateEnabled:(short)chan { return internalGateEnabledMask & (1<<chan); }
- (void) setInternalGateEnabled:(short)chan withValue:(BOOL)aValue
{
	unsigned char aMask = internalGateEnabledMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setInternalGateEnabledMask:aMask];
}

- (short) externalGateEnabledMask { return externalGateEnabledMask; }
- (void) setExternalGateEnabledMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setExternalGateEnabledMask:externalGateEnabledMask];
	externalGateEnabledMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ExternalGateEnabledChanged object:self];
}

- (BOOL) externalGateEnabled:(short)chan { return externalGateEnabledMask & (1<<chan); }
- (void) setExternalGateEnabled:(short)chan withValue:(BOOL)aValue
{
	unsigned char aMask = externalGateEnabledMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setExternalGateEnabledMask:aMask];
}

- (short) extendedThresholdEnabledMask { return extendedThresholdEnabledMask; }
- (void) setExtendedThresholdEnabledMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setExtendedThresholdEnabledMask:extendedThresholdEnabledMask];
	extendedThresholdEnabledMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ExtendedThresholdEnabledChanged object:self];
}

- (BOOL) extendedThresholdEnabled:(short)chan { return extendedThresholdEnabledMask & (1<<chan); }
- (void) setExtendedThresholdEnabled:(short)chan withValue:(BOOL)aValue
{
	unsigned char aMask = extendedThresholdEnabledMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setExtendedThresholdEnabledMask:aMask];
}


- (short) inputInvertedMask { return inputInvertedMask; }
- (void) setInputInvertedMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setInputInvertedMask:inputInvertedMask];
	inputInvertedMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305InputInvertedChanged object:self];
}

- (BOOL) inputInverted:(short)chan { return inputInvertedMask & (1<<chan); }
- (void) setInputInverted:(short)chan withValue:(BOOL)aValue
{
	unsigned char aMask = inputInvertedMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setInputInvertedMask:aMask];
}

- (short) triggerOutEnabledMask { return triggerOutEnabledMask; }
- (void) setTriggerOutEnabledMask:(short)aMask	
{ 
	[[[self undoManager] prepareWithInvocationTarget:self] setTriggerOutEnabledMask:triggerOutEnabledMask];
	triggerOutEnabledMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305TriggerOutEnabledChanged object:self];
}

- (BOOL) triggerOutEnabled:(short)chan { return triggerOutEnabledMask & (1<<chan); }
- (void) setTriggerOutEnabled:(short)chan withValue:(BOOL)aValue		
{ 
	unsigned char aMask = triggerOutEnabledMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setTriggerOutEnabledMask:aMask];
}

- (short) highEnergySuppressMask { return highEnergySuppressMask; }
- (void) setHighEnergySuppressMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setHighEnergySuppressMask:highEnergySuppressMask];
	highEnergySuppressMask= aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305HighEnergySuppressChanged object:self];
}	
- (BOOL) highEnergySuppress:(short)chan { return highEnergySuppressMask & (1<<chan); }
- (void) setHighEnergySuppress:(short)chan withValue:(BOOL)aValue
{
	unsigned char aMask = highEnergySuppressMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setHighEnergySuppressMask:aMask];
}

- (short) adc50KTriggerEnabledMask { return adc50KTriggerEnabledMask; }

- (void) setAdc50KTriggerEnabledMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setAdc50KTriggerEnabledMask:adc50KTriggerEnabledMask];
	adc50KTriggerEnabledMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305Adc50KTriggerEnabledChanged object:self];
}

- (BOOL) adc50KTriggerEnabled:(short)chan { return adc50KTriggerEnabledMask & (1<<chan); }
- (void) setAdc50KTriggerEnabled:(short)chan withValue:(BOOL)aValue
{
	unsigned char aMask = adc50KTriggerEnabledMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setAdc50KTriggerEnabledMask:aMask];
}

- (BOOL) shipEnergyWaveform { return shipEnergyWaveform;}
- (void) setShipEnergyWaveform:(BOOL)aState
{ 
	[[[self undoManager] prepareWithInvocationTarget:self] setShipEnergyWaveform:shipEnergyWaveform];
	shipEnergyWaveform = aState;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305SetShipWaveformChanged object:self];
	if (!shipEnergyWaveform && ![self shipSummedWaveform]) {
		[self setEnergySampleLength:0];		
	} 
	else {
		[self setEnergySampleLength:kSIS3305MaxEnergyWaveform];
		// The following forces the start indices to calculate automatically.
		// This could avoid some confusion about the special cases of 
		// start indices 2 and 3 being 0.  This forces them to be
		// at least span the max sample length.  (There's a check 
		// in calculateSampleValues.)
		[self setEnergySampleStartIndex2:1];
	}
}

- (BOOL) shipSummedWaveform { return shipSummedWaveform;}
- (void) setShipSummedWaveform:(BOOL)aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setShipSummedWaveform:shipSummedWaveform];
	shipSummedWaveform = aState;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305SetShipSummedWaveformChanged object:self];
	if (!shipSummedWaveform && ![self shipEnergyWaveform]) {
		[self setEnergySampleLength:0];
	} 
	else {
		[self setEnergySampleLength:kSIS3305MaxEnergyWaveform];
		[self setEnergySampleStartIndex2:0];
		[self setEnergySampleStartIndex3:0];
		
		// The following forces the start indices to calculate automatically.
		// This could avoid some confusion about the special cases of 
		// start indices 2 and 3 being 0.  This forces them to be
		// at least span the max sample length.  (There's a check 
		// in calculateSampleValues.)
		//[self setEnergySampleStartIndex2:1];
	}
}
- (NSString*) energyBufferAssignment
{
	if(shipSummedWaveform == YES){
		return @"Post-Trig Samples:";
	}
	else {
		return @"Start Indexes:";
	}
}




//- (short) cfdControl:(short)aChannel 
//{ 
//	if(aChannel>=kNumSIS3305Channels)return 0;
//	return [[cfdControls objectAtIndex:aChannel] intValue]; 
//}
//- (void) setCfdControl:(short)aChannel withValue:(short)aValue 
//{ 
// 	if(aChannel>=kNumSIS3305Channels)return;
//	[[[self undoManager] prepareWithInvocationTarget:self] setCfdControl:aChannel withValue:[self cfdControl:aChannel]];
//    int cfd = [self limitIntValue:aValue min:0 max:0x3];
//	[cfdControls replaceObjectAtIndex:aChannel withObject:[NSNumber numberWithInt:cfd]];
//	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelCfdControlChanged object:self];
//}
//

- (short) energyDecimation:(short)aGroup 
{ 
	if(aGroup>=kNumSIS3305Groups)return 0;
	return [[energyDecimations objectAtIndex:aGroup] intValue]; 
}

- (void) setEnergyDecimation:(short)aGroup withValue:(short)aValue 
{ 
 	if(aGroup>=kNumSIS3305Groups)return;
	[[[self undoManager] prepareWithInvocationTarget:self] setEnergyDecimation:aGroup withValue:[self energyDecimation:aGroup]];
    int energyDecimation = [self limitIntValue:aValue min:0 max:0x3];
	[energyDecimations replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:energyDecimation]];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305EnergyDecimationChanged object:self];
	[self calculateEnergyGateLength];
}

- (unsigned long) endAddressThreshold:(short)aGroup  
{ 
	if(aGroup>=kNumSIS3305Groups)return 0;
	return [[endAddressThresholds objectAtIndex:aGroup] intValue]; 
}

- (void) setEndAddressThreshold:(short)aGroup withValue:(unsigned long)aValue 
{
	[[[self undoManager] prepareWithInvocationTarget:self] setEndAddressThreshold:aGroup withValue:[self endAddressThreshold:aGroup]];
	[endAddressThresholds replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:aValue]];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEndAddressThresholdChanged object:self];
}

- (int) triggerDecimation:(short)aGroup 
{ 
	if(aGroup>=kNumSIS3305Groups)return 0;
	return [[triggerDecimations objectAtIndex:aGroup] intValue]; 
}
- (void) setTriggerDecimation:(short)aGroup withValue:(short)aValue 
{ 
	if(aGroup>=kNumSIS3305Groups)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerDecimation:aGroup withValue:[self triggerDecimation:aGroup]];
    int triggerDecimation = [self limitIntValue:aValue min:0 max:0x3];
		
	[triggerDecimations replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:triggerDecimation]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305TriggerDecimationChanged object:self];
	
	//force a constraint check by reloading the pretrigger delay
	[self setPreTriggerDelay:aGroup withValue:[self preTriggerDelay:aGroup]];

}


- (void) calculateSampleValues
{
//	if(runMode == kMcaRunMode)   return;
//	else {
		numEnergyValues = energySampleLength;
		
		if(numEnergyValues > kSIS3305MaxEnergyWaveform){
			// This should never be happen in the current implementation since we 
			// handle this value internally, but checking nonetheless in case 
			// in the future we modify this.  
			NSLogColor([NSColor redColor],@"Number of energy values is to high (max = %d) ; actual = %d \n",
					   kSIS3305MaxEnergyWaveform, numEnergyValues);
			NSLogColor([NSColor redColor],@"Value forced to %d\n", kSIS3305MaxEnergyWaveform);
			numEnergyValues = kSIS3305MaxEnergyWaveform;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergySampleLengthChanged object:self];
//		}
		
		int group;
		for(group=0;group<kNumSIS3305Groups;group++){
			numRawDataLongWords = [self sampleLength:group]/2;
			rawDataIndex  = 2 ;
			
			eventLengthLongWords = 2 + 4  ; // Timestamp/Header, MAX, MIN, Trigger-FLags, Trailer
			if(bufferWrapEnabledMask && firmwareVersion>15)eventLengthLongWords+=2; //1510 added two words to the header 
			eventLengthLongWords = eventLengthLongWords + numRawDataLongWords  ;  
			eventLengthLongWords = eventLengthLongWords + numEnergyValues  ;   
			
			unsigned long maxEvents = (0x200000 / eventLengthLongWords)/2;
			//unsigned long maxEvents = 1;
			[self setEndAddressThreshold:group withValue:maxEvents*eventLengthLongWords];
			// Check the sample indices
			// Don't call setEnergy* from in here!  Cause stack overflow...
			if (numEnergyValues == 0) {
				// Set all indices to 0
				energySampleStartIndex1 = 1;
				energySampleStartIndex2 = 0;
				energySampleStartIndex3 = 0;
			} 
			else if (energySampleStartIndex2 != 0 || energySampleStartIndex3 != 0) {
				// Means we are requesting different pieces of the waveform.
				// Make sure they are correct.
				if (energySampleStartIndex2 < energySampleStartIndex1 + energySampleLength/3 + 1) {
					int aValue = energySampleLength/3 + energySampleStartIndex1 + 1;
					energySampleStartIndex2 = aValue;
					if (energySampleStartIndex3 == 0) {
						// This forces us to also reset the third index if it is set to 0.
						energySampleStartIndex3 = 0;
					}
				}
				
				if (energySampleStartIndex2 == 0 && energySampleStartIndex3 != 0) {
					energySampleStartIndex3 = 0;
				} 
				else if (energySampleStartIndex2 != 0 && 
						 energySampleStartIndex3 < energySampleStartIndex2 + energySampleLength/3 + 1) {
					int aValue = energySampleLength/3 + energySampleStartIndex2 + 1;
					energySampleStartIndex3 = aValue;
				}
			}			
			[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergySampleStartIndex1Changed object:self];
			[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergySampleStartIndex2Changed object:self];
			[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305ModelEnergySampleStartIndex3Changed object:self];
			
			// Finally check the trigger gate length to make sure it is big enough
			if ([self triggerGateLength:group] < [self sampleLength:group]) {
				[self setTriggerGateLength:group withValue:[self sampleLength:group]];
			}
		}
	}
}

- (void) calculateEnergyGateLength
{
	// Make sure the gate is set appropriately.
	// The Pre-trigger and and Trigger Gate are both in
	// 100 MHz clock ticks, but everything else is in 
	// Decimation clock ticks.  Convert this down to the correct
	// decimation.
	int group;
	for(group=0;group<kNumSIS3305Groups;group++){
		int preTriggerDelay = [self preTriggerDelay:group];
		unsigned int delayInDecimationClockTicks = preTriggerDelay >> [self energyDecimation:group];
		if (energySampleLength == 0) {
			// Means that we are not shipping an energy waveform.
			// Make sure the gate length is long enough
			//[self setEnergyGateLength:group withValue:delayInDecimationClockTicks + 600];
			int theValue = delayInDecimationClockTicks + 2 * [self energyPeakingTime:group] + [self energyGapTime:group] + 20; //perhaps the '20' should be user setable
			[self setEnergyGateLength:group withValue:theValue];
		} 
		else {
			//[self setEnergyGateLength:group withValue:(delayInDecimationClockTicks +
			//									   2*[self energyPeakingTime:group] +
			//									   [self energyGapTime:group] + 120)]; // Add the 20 ticks for safety
			
			int value1 = [self energySampleStartIndex3]+ delayInDecimationClockTicks + 20;
			int value2 = 2 * [self energyPeakingTime:group] + [self energyGapTime:group] + delayInDecimationClockTicks + 20; //perhaps the '20' should be user setable
			int value3 = [self energySampleStartIndex1]+ delayInDecimationClockTicks + 20; //handle the case where the summed waveform is shipped

			int tempValue = MAX(value1,value2);
			int theValue = MAX(tempValue,value3);
			[self setEnergyGateLength:group withValue:theValue];

		}
	}
}


#pragma mark - Reg Declarations
- (unsigned long) getPreviousBankSampleRegisterOffset:(int) channel 
{
//    switch (channel) {
//        case 0: return kSIS3305PreviousBankSampleAddressAdc1;
//        case 1: return kSIS3305PreviousBankSampleAddressAdc2;
//        case 2: return kSIS3305PreviousBankSampleAddressAdc3;
//        case 3: return kSIS3305PreviousBankSampleAddressAdc4;
//        case 4: return kSIS3305PreviousBankSampleAddressAdc5;
//        case 5: return kSIS3305PreviousBankSampleAddressAdc6;
//        case 6: return kSIS3305PreviousBankSampleAddressAdc7;
//        case 7: return kSIS3305PreviousBankSampleAddressAdc8;
//    }
    return (unsigned long)-1;
}

- (unsigned long) getEnergyTauFactorOffset:(int) channel 
{
//    switch (channel) {
//        case 0: return kSIS3305EnergyTauFactorAdc1;
//        case 1: return kSIS3305EnergyTauFactorAdc2;
//        case 2: return kSIS3305EnergyTauFactorAdc3;
//        case 3: return kSIS3305EnergyTauFactorAdc4;
//        case 4: return kSIS3305EnergyTauFactorAdc5;
//        case 5: return kSIS3305EnergyTauFactorAdc6;
//        case 6: return kSIS3305EnergyTauFactorAdc7;
//        case 7: return kSIS3305EnergyTauFactorAdc8;
//    }
    return (unsigned long)-1;
}

- (unsigned long) getBufferControlOffset:(int) aGroup 
{
//    switch (aGroup) {
//        case 0: return kSIS3305BufferControlModeAdc12;
//        case 1: return kSIS3305BufferControlModeAdc34;
//        case 2: return kSIS3305BufferControlModeAdc56;
//        case 3: return kSIS3305BufferControlModeAdc78;
//    }
    return (unsigned long)-1;
}

- (unsigned long) getPreTriggerDelayTriggerGateLengthOffset:(int) aGroup 
{
//    switch (aGroup) {
//        case 0: return kSIS3305PreTriggerDelayTriggerGateLengthAdc12;
//        case 1: return kSIS3305PreTriggerDelayTriggerGateLengthAdc34;
//        case 2: return kSIS3305PreTriggerDelayTriggerGateLengthAdc56;
//        case 3: return kSIS3305PreTriggerDelayTriggerGateLengthAdc78;
//    }
    return (unsigned long)-1;
}

- (unsigned long) getADCBufferRegisterOffset:(int) channel 
{
//    switch (channel) {
//        case 0: return kSIS3305Adc1Offset;
//        case 1: return kSIS3305Adc2Offset;
//        case 2: return kSIS3305Adc3Offset;
//        case 3: return kSIS3305Adc4Offset;
//        case 4: return kSIS3305Adc5Offset;
//        case 5: return kSIS3305Adc6Offset;
//        case 6: return kSIS3305Adc7Offset;
//        case 7: return kSIS3305Adc8Offset;
//    }
    return (unsigned long) -1;
}

- (unsigned long) getGTThresholdRegOffsets:(int) channel
{
//    "Greater than"-threshold registers
    switch (channel) {
        case 0: return 	kSIS3305TriggerGateGTThresholdsADC1;
        case 1: return 	kSIS3305TriggerGateGTThresholdsADC2;
        case 2: return 	kSIS3305TriggerGateGTThresholdsADC3;
        case 3: return 	kSIS3305TriggerGateGTThresholdsADC4;
        case 4:	return 	kSIS3305TriggerGateGTThresholdsADC5;
        case 5: return 	kSIS3305TriggerGateGTThresholdsADC6;
        case 6: return 	kSIS3305TriggerGateGTThresholdsADC7;
        case 7: return 	kSIS3305TriggerGateGTThresholdsADC8;
    }
    return (unsigned long) -1;
}

- (unsigned long) getLTThresholdRegOffsets:(int) channel
{
//  "Less than"-threshold registers
    switch (channel) {
        case 0: return 	kSIS3305TriggerGateLTThresholdsADC1;
        case 1: return 	kSIS3305TriggerGateLTThresholdsADC2;
        case 2: return 	kSIS3305TriggerGateLTThresholdsADC3;
        case 3: return 	kSIS3305TriggerGateLTThresholdsADC4;
        case 4:	return 	kSIS3305TriggerGateLTThresholdsADC5;
        case 5: return 	kSIS3305TriggerGateLTThresholdsADC6;
        case 6: return 	kSIS3305TriggerGateLTThresholdsADC7;
        case 7: return 	kSIS3305TriggerGateLTThresholdsADC8;
    }
    return (unsigned long) -1;
}

//- (unsigned long) getHighThresholdRegOffsets:(int) channel 
//{
//    switch (channel) {
//        case 0: return 	kSIS3305HighEnergyThresholdAdc1;
//		case 1: return 	kSIS3305HighEnergyThresholdAdc2;
//		case 2: return 	kSIS3305HighEnergyThresholdAdc3;
//		case 3: return 	kSIS3305HighEnergyThresholdAdc4;
//		case 4:	return 	kSIS3305HighEnergyThresholdAdc5;
//		case 5: return 	kSIS3305HighEnergyThresholdAdc6;
//		case 6: return 	kSIS3305HighEnergyThresholdAdc7;
//		case 7: return 	kSIS3305HighEnergyThresholdAdc8;
//    }
//    return (unsigned long) -1;
//}

- (unsigned long) getExtendedThresholdRegOffsets:(int) channel 
{
//    switch (channel) {
//        case 0: return 	kSIS3305TriggerExtendedThresholdAdc1;
//		case 1: return 	kSIS3305TriggerExtendedThresholdAdc2;
//		case 2: return 	kSIS3305TriggerExtendedThresholdAdc3;
//		case 3: return 	kSIS3305TriggerExtendedThresholdAdc4;
//		case 4:	return 	kSIS3305TriggerExtendedThresholdAdc5;
//		case 5: return 	kSIS3305TriggerExtendedThresholdAdc6;
//		case 6: return 	kSIS3305TriggerExtendedThresholdAdc7;
//		case 7: return 	kSIS3305TriggerExtendedThresholdAdc8;
//    }
    return (unsigned long) -1;
}

- (unsigned long) getTriggerSetupRegOffsets:(int) channel 
{
//    switch (channel) {
//		case 0: return 	kSIS3305TriggerSetupAdc1;
//		case 1: return 	kSIS3305TriggerSetupAdc2;
//		case 2: return 	kSIS3305TriggerSetupAdc3;
//		case 3: return 	kSIS3305TriggerSetupAdc4;
//		case 4: return 	kSIS3305TriggerSetupAdc5;
//		case 5: return 	kSIS3305TriggerSetupAdc6;
//		case 6: return 	kSIS3305TriggerSetupAdc7;
//		case 7: return 	kSIS3305TriggerSetupAdc8;
//    }
    return (unsigned long) -1;
}

- (unsigned long) getTriggerExtSetupRegOffsets:(int)channel
{
//    switch (channel) {	
//		case 0: return 	kSIS3305TriggerExtendedSetupAdc1;
//		case 1: return 	kSIS3305TriggerExtendedSetupAdc2;
//		case 2: return 	kSIS3305TriggerExtendedSetupAdc3;
//		case 3: return 	kSIS3305TriggerExtendedSetupAdc4;
//		case 4: return 	kSIS3305TriggerExtendedSetupAdc5;
//		case 5: return 	kSIS3305TriggerExtendedSetupAdc6;
//		case 6: return 	kSIS3305TriggerExtendedSetupAdc7;
//		case 7: return 	kSIS3305TriggerExtendedSetupAdc8;
//	}
    return (unsigned long) -1;
}


- (unsigned long) getEndThresholdRegOffsets:(int)group
{
//	switch (group) {	
//		case 0: return 	 kSIS3305EndAddressThresholdAdc12;
//		case 1: return 	 kSIS3305EndAddressThresholdAdc34;
//		case 2: return 	 kSIS3305EndAddressThresholdAdc56;
//		case 3: return 	 kSIS3305EndAddressThresholdAdc78;
//	}
	return (unsigned long) -1;
}

- (unsigned long) getRawDataBufferConfigOffsets:(int) channel 
{
//    switch (channel) {
//        case 0: return kSIS3305RawDataBufferConfigAdc12;
//        case 1: return kSIS3305RawDataBufferConfigAdc34;
//        case 2: return kSIS3305RawDataBufferConfigAdc56;
//        case 3: return kSIS3305RawDataBufferConfigAdc78;
//    }
    return (unsigned long)-1;
}

- (unsigned long) getSampleAddress:(int)channel
{
//    switch (channel) {
//		case 0: return 	kSIS3305ActualSampleAddressAdc1;
//		case 1: return 	kSIS3305ActualSampleAddressAdc2;
//		case 2: return 	kSIS3305ActualSampleAddressAdc3;
//		case 3: return 	kSIS3305ActualSampleAddressAdc4;
//		case 4: return 	kSIS3305ActualSampleAddressAdc5;
//		case 5: return 	kSIS3305ActualSampleAddressAdc6;
//		case 6: return 	kSIS3305ActualSampleAddressAdc7;
//		case 7: return 	kSIS3305ActualSampleAddressAdc8;
// 	}
	return (unsigned long) -1;
}

- (unsigned long) getEventConfigOffsets:(int)group
{
	switch (group) {
		case 0: return kSIS3305EventConfigADC14;
		case 1: return kSIS3305EventConfigADC58;
	}
	return (unsigned long) -1;
}

- (unsigned long) getEnergyGateLengthOffsets:(int)group
{
//	switch (group) {
//		case 0: return kSIS3305EnergyGateLengthAdc12;
//		case 1: return kSIS3305EnergyGateLengthAdc34;
//		case 2: return kSIS3305EnergyGateLengthAdc56;
//		case 3: return kSIS3305EnergyGateLengthAdc78;
//	}
	return (unsigned long) -1;
}

- (unsigned long) getExtendedEventConfigOffsets:(int)group
{
//	switch (group) {
//		case 0: return kSIS3305EventExtendedConfigAdc12;
//		case 1: return kSIS3305EventExtendedConfigAdc34;
//		case 2: return kSIS3305EventExtendedConfigAdc56;
//		case 3: return kSIS3305EventExtendedConfigAdc78;
//	}
	return (unsigned long) -1;
}

- (unsigned long) getAdcMemory:(int)channel
{
//    switch (channel) {			
//		case 0: return 	kSIS3305Adc1Offset;
//		case 1: return 	kSIS3305Adc2Offset;
//		case 2: return 	kSIS3305Adc3Offset;
//		case 3: return 	kSIS3305Adc4Offset;
//		case 4: return 	kSIS3305Adc5Offset;
//		case 5: return 	kSIS3305Adc6Offset;
//		case 6: return 	kSIS3305Adc7Offset;
//		case 7: return 	kSIS3305Adc8Offset;
// 	}
	return (unsigned long) -1;
}

- (unsigned long) getEnergySetupGPOffset:(int)group
{
//	switch (group) {
//		case 0: return kSIS3305EnergySetupGPAdc12;
//		case 1: return kSIS3305EnergySetupGPAdc34;
//		case 2: return kSIS3305EnergySetupGPAdc56;
//		case 3: return kSIS3305EnergySetupGPAdc78;
//	}
	return (unsigned long) -1;
}

#pragma mark - - Hardware Access

#pragma mark Read
- (void) readModuleID:(BOOL)verbose
{	
	unsigned long result = 0;
	[[self adapter] readLongBlock:&result
						atAddress:[self baseAddress] + kSIS3305ModID
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	unsigned long moduleID = result >> 16;
	unsigned short majorRev = (result >> 8) & 0xff;
	unsigned short minorRev = result & 0xff;
	NSString* s = [NSString stringWithFormat:@"%x.%x",majorRev,minorRev];
	[self setFirmwareVersion:[s floatValue]];
	if(verbose){
		NSLog(@"SIS3305 ID: %x  Firmware:%.2f\n",moduleID,firmwareVersion);
		if(moduleID != 0x3305)NSLogColor([NSColor redColor], @"Warning: HW mismatch. 3305 object is 0x%x HW\n",moduleID);
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305IDChanged object:self];
}

- (unsigned long) acqReg
{
    unsigned long aValue = 0;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + kSIS3305AcquisitionControl
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return aValue;
}

- (void) readLTThresholds:(BOOL)verbose
{
    int i;
    if(verbose) NSLog(@"Reading LT Thresholds:\n");
    
    for(i =0; i < kNumSIS3305Channels; i++) {
        unsigned long aValue;
        [[self adapter] readLongBlock: &aValue
                            atAddress: [self baseAddress] + [self getLTThresholdRegOffsets:i]
                            numToRead: 1
                           withAddMod: [self addressModifier]
                        usingAddSpace: 0x01];
        
        if(verbose){
            unsigned short onThresh     = (aValue & 0x3FF);
            unsigned short offThresh    = ((aValue>>16) & 0x3FF);
            BOOL triggerModeLT          = (aValue>>31) & 0x1;
            
            //              NSLog(@"%d: %8s %2s 0x%4x\n",
//            NSLog(@"LT(%d): 0x%04x  == ",i,aValue);
//            NSLog(@"%d: %2s 0x%04x\n",
//                  //                                        triggerDisabled ? "Trig Out Disabled"   : "Trig Out Enabled",
//                  triggerModeLT   ? "GT enabled"            : "  " ,
//                  onThresh,
//                  offThresh);
            NSLog(@"%d: %2s On:0x%04x Off:0x%04x\n",
                  i,
                  triggerModeLT   ? "LT enabled"            : "LT disabled" ,
                  onThresh,
                  offThresh);
        }
    }
}

- (void) readGTThresholds:(BOOL)verbose
{
    int i;
    if(verbose) NSLog(@"Reading GT Thresholds:\n");
    
    for(i =0; i < kNumSIS3305Channels; i++) {
        unsigned long aValue;
        [[self adapter] readLongBlock: &aValue
                            atAddress: [self baseAddress] + [self getGTThresholdRegOffsets:i]
                            numToRead: 1
                           withAddMod: [self addressModifier]
                        usingAddSpace: 0x01];
        
        if(verbose){
            unsigned short onThresh = (aValue       & 0x3FF);
            unsigned short offThresh= ((aValue>>16) & 0x3FF);
            
            BOOL triggerModeGT    = (aValue>>31) & 0x1;
            //              NSLog(@"%d: %8s %2s 0x%4x\n",
            NSLog(@"%d: %2s On:0x%04x Off:0x%04x\n",
                  i,
                  triggerModeGT   ? "GT enabled"            : "GT disabled" ,
                  onThresh,
                  offThresh);
        }
    }
}

- (void) readThresholds:(BOOL)verbose
{
    [self readLTThresholds:verbose];
    [self readGTThresholds:verbose];
    
    return;
}

//- (void) readHighThresholds:(BOOL)verbose
//{
//    int i;
//    if(verbose) NSLog(@"Reading High Thresholds:\n");
//    
//    for(i = 0; i < kNumSIS3305Channels; i++) {
//        unsigned long aValue;
//        [[self adapter] readLongBlock: &aValue
//                            atAddress: [self baseAddress] + [self getHighThresholdRegOffsets:i]
//                            numToRead: 1
//                           withAddMod: [self addressModifier]
//                        usingAddSpace: 0x01];
//        if(verbose){
//            unsigned short thresh = (aValue&0xffff);
//            NSLog(@"%d: 0x%4x\n",i,thresh);
//        }
//    }
//}

- (void) regDump
{
    @try {
        NSFont* font = [NSFont fontWithName:@"Monaco" size:11];
        NSLogFont(font,@"Reg Dump for SIS3305 (Slot %d)\n",[self slot]);
        NSLogFont(font,@"-----------------------------------\n");
        NSLogFont(font,@"[Add Offset]   Value        Name\n");
        NSLogFont(font,@"-----------------------------------\n");
        
        ORCommandList* aList = [ORCommandList commandList];
        int i;
        for(i=0;i<kNumSIS3305ReadRegs;i++){
            [aList addCommand: [ORVmeReadWriteCommand readLongBlockAtAddress: [self baseAddress] + register_information[i].offset
                                                                   numToRead: 1
                                                                  withAddMod: [self addressModifier]
                                                               usingAddSpace: 0x01]];
        }
        [self executeCommandList:aList];
        
        //if we get here, the results can retrieved in the same order as sent
        for(i=0;i<kNumSIS3305ReadRegs;i++){
            NSLogFont(font, @"[0x%08x] 0x%08x    %@\n",register_information[i].offset,[aList longValueForCmd:i],register_information[i].name);
        }
        
    }
    @catch(NSException* localException) {
        NSLog(@"SIS3305 Reg Dump FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3305 Reg Dump FAILED", @"OK", nil, nil,
                        localException);
    }
}

- (void) briefReport
{
    NSLog(@"Brief Report\n");

    [self readThresholds:YES];
    //	[self readHighThresholds:YES];
    unsigned long eventConfig = 0;
    [[self adapter] readLongBlock:&eventConfig
                        atAddress:[self baseAddress] + kSIS3305EventConfigADC14
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    NSLog(@"EventConfig: 0x%08x\n",eventConfig);
    
    //	unsigned long pretrigger = 0;
    //	[[self adapter] readLongBlock:&pretrigger
    //						atAddress:[self baseAddress] + kSIS3305PreTriggerDelayTriggerGateLengthAdc14
    //						numToRead:1
    //					   withAddMod:[self addressModifier]
    //					usingAddSpace:0x01];
    //
    //	NSLog(@"pretrigger: 0x%08x\n",pretrigger);
    
    //	unsigned long rawDataBufferConfig = 0;
    //	[[self adapter] readLongBlock:&rawDataBufferConfig
    //						atAddress:[self baseAddress] + kSIS3305RawDataBufferConfigAdc12
    //						numToRead:1
    //					   withAddMod:[self addressModifier]
    //					usingAddSpace:0x01];
    //
    //	NSLog(@"rawDataBufferConfig: 0x%08x\n",rawDataBufferConfig);
    
    unsigned long actualNextSampleAddress1 = 0;
    [[self adapter] readLongBlock:&actualNextSampleAddress1
                        atAddress:[self baseAddress] + kSIS3305ActualSampleAddressADC14
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    NSLog(@"actualNextSampleAddress1: 0x%08x\n",actualNextSampleAddress1);
    
    unsigned long actualNextSampleAddress2 = 0;
    [[self adapter] readLongBlock:&actualNextSampleAddress2
                        atAddress:[self baseAddress] + kSIS3305ActualSampleAddressADC58
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    NSLog(@"actualNextSampleAddress2: 0x%08x\n",actualNextSampleAddress2);
    
    //	unsigned long prevNextSampleAddress1 = 0;
    //	[[self adapter] readLongBlock:&prevNextSampleAddress1
    //						atAddress:[self baseAddress] + kSIS3305PreviousBankSampleAddressA
    //						numToRead:1
    //					   withAddMod:[self addressModifier]
    //					usingAddSpace:0x01];
    //
    //	NSLog(@"prevNextSampleAddress1: 0x%08x\n",prevNextSampleAddress1);
    
    //	unsigned long prevNextSampleAddress2 = 0;
    //	[[self adapter] readLongBlock:&prevNextSampleAddress2
    //						atAddress:[self baseAddress] + kSIS3305PreviousBankSampleAddressAdc2
    //						numToRead:1
    //					   withAddMod:[self addressModifier]
    //					usingAddSpace:0x01];
    //
    //	NSLog(@"prevNextSampleAddress2: 0x%08x\n",prevNextSampleAddress2);
    
    //	unsigned long triggerSetup1 = 0;
    //	[[self adapter] readLongBlock:&triggerSetup1
    //						atAddress:[self baseAddress] + kSIS3305TriggerSetupAdc1
    //						numToRead:1
    //					   withAddMod:[self addressModifier]
    //					usingAddSpace:0x01];
    //
    //	NSLog(@"triggerSetup1: 0x%08x\n",triggerSetup1);
    
    //	unsigned long triggerSetup2 = 0;
    //	[[self adapter] readLongBlock:&triggerSetup2
    //						atAddress:[self baseAddress] + kSIS3305TriggerSetupAdc2
    //						numToRead:1
    //					   withAddMod:[self addressModifier]
    //					usingAddSpace:0x01];
    //
    //	NSLog(@"triggerSetup2: 0x%08x\n",triggerSetup2);
    
    //	unsigned long energySetupGP = 0;
    //	[[self adapter] readLongBlock:&energySetupGP
    //						atAddress:[self baseAddress] + kSIS3305EnergySetupGPAdc12
    //						numToRead:1
    //					   withAddMod:[self addressModifier]
    //					usingAddSpace:0x01];
    
    //	NSLog(@"energySetupGP: 0x%08x\n",energySetupGP);
    
    //	unsigned long EnergyGateLen = 0;
    //	[[self adapter] readLongBlock:&EnergyGateLen
    //						atAddress:[self baseAddress] + kSIS3305EnergyGateLengthAdc12
    //						numToRead:1
    //					   withAddMod:[self addressModifier]
    //					usingAddSpace:0x01];
    
    //	NSLog(@"EnergyGateLen: 0x%08x\n",EnergyGateLen);
    
    //	unsigned long EnergySampleLen = 0;
    //	[[self adapter] readLongBlock:&EnergySampleLen
    //						atAddress:[self baseAddress] + kSIS3305EnergySampleLengthAdc12
    //						numToRead:1
    //					   withAddMod:[self addressModifier]
    //					usingAddSpace:0x01];
    
    //	NSLog(@"EnergySampleLen: 0x%08x\n",EnergySampleLen);
    
    //	unsigned long EnergySampleStartIndex = 0;
    //	[[self adapter] readLongBlock:&EnergySampleStartIndex
    //						atAddress:[self baseAddress] + kSIS3305EnergySampleStartIndex1Adc12
    //						numToRead:1
    //					   withAddMod:[self addressModifier]
    //					usingAddSpace:0x01];
    
    //	NSLog(@"EnergySampleStartIndex: 0x%08x\n",EnergySampleStartIndex);
}


//- (void) readMcaStatus
//{
//	static unsigned long mcaStatusAddress[kNumMcaStatusRequests] = {
//		//order is important here....
//		kSIS3305AcquisitionControl,
//		kSIS3305McaScanHistogramCounter,
//		kSIS3305McaMultiScanScanCounter,
//
//		kSIS3305McaTriggerStartCounterAdc1,
//		kSIS3305McaPileupCounterAdc1,
//		kSIS3305McaEnergy2LowCounterAdc1,
//		kSIS3305McaEnergy2HighCounterAdc1,
//
//		kSIS3305McaTriggerStartCounterAdc2,
//		kSIS3305McaPileupCounterAdc2,
//		kSIS3305McaEnergy2LowCounterAdc2,
//		kSIS3305McaEnergy2HighCounterAdc2,
//
//		kSIS3305McaTriggerStartCounterAdc3,
//		kSIS3305McaPileupCounterAdc3,
//		kSIS3305McaEnergy2LowCounterAdc3,
//		kSIS3305McaEnergy2HighCounterAdc3,
//
//		kSIS3305McaTriggerStartCounterAdc4,
//		kSIS3305McaPileupCounterAdc4,
//		kSIS3305McaEnergy2LowCounterAdc4,
//		kSIS3305McaEnergy2HighCounterAdc4,
//
//		kSIS3305McaTriggerStartCounterAdc5,
//		kSIS3305McaPileupCounterAdc5,
//		kSIS3305McaEnergy2LowCounterAdc5,
//		kSIS3305McaEnergy2HighCounterAdc5,
//
//		kSIS3305McaTriggerStartCounterAdc6,
//		kSIS3305McaPileupCounterAdc6,
//		kSIS3305McaEnergy2LowCounterAdc6,
//		kSIS3305McaEnergy2HighCounterAdc6,
//
//		kSIS3305McaTriggerStartCounterAdc7,
//		kSIS3305McaPileupCounterAdc7,
//		kSIS3305McaEnergy2LowCounterAdc7,
//		kSIS3305McaEnergy2HighCounterAdc7,
//
//		kSIS3305McaTriggerStartCounterAdc8,
//		kSIS3305McaPileupCounterAdc8,
//		kSIS3305McaEnergy2LowCounterAdc8,
//		kSIS3305McaEnergy2HighCounterAdc8
//		//order is important here....
//	};
//	
//	ORCommandList* aList = [ORCommandList commandList];
//	int i;
//	for(i=0;i<kNumMcaStatusRequests;i++){
//		[aList addCommand: [ORVmeReadWriteCommand readLongBlockAtAddress: [self baseAddress] + mcaStatusAddress[i]
//															   numToRead: 1
//															  withAddMod: [self addressModifier]
//														   usingAddSpace: 0x01]];
//	}
//	[self executeCommandList:aList];
//	
//	//if we get here, the results can retrieved in the same order as sent
//	for(i=0;i<kNumMcaStatusRequests;i++){
//		mcaStatusResults[i] = [aList longValueForCmd:i];
//	}
//	
//	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305McaStatusChanged object:self];
//} 

//- (unsigned long) mcaStatusResult:(int)index
//{
//	if(index>=0 && index<kNumMcaStatusRequests){
//		return mcaStatusResults[index];
//	}
//	else return 0;
//}


#pragma mark Write

- (void) writeAcquistionRegister
{
	/*
        The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.
        Set is 15:0, clear is 31:16.
     
        clock source:
            0 = internal
            1 = external
            The higher bit (13) is never used (always = 0) since there are only two possible sources
            The lower bit (12) is equal to clockSource.
     
        trigger-in TDC measurement logic:
            writing to bit 4 enables,
            writing to bit 20 disables
     
     
        Power up default reads 0x0.
     
     */
    
	unsigned long aMask = 0x0;
    
    aMask |= ((clockSource & 0x1)<< 12);
    aMask |= ((TDCMeasurementEnabled & 0x1) << 4);
	
	//put the inverse in the top bits to turn off everything else
	aMask = ((~aMask & 0x0000ffff)<<16) | aMask;
	
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kSIS3305AcquisitionControl
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) setLed1:(BOOL)state
{
    state = state << 0;
	unsigned long aValue = CSRMask(state,kSISLed1);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305ControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) setLed:(short)ledNum to:(BOOL)state;
{
    state = state << 1;
    unsigned long aValue = CSRMask(state,kSISLed2);
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305ControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) setLedApplicationMode:(BOOL)state
{
    unsigned long aValue = CSRMask(state,kSISLed3);
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305ControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) forceTrigger
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305KeyTrigger
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];

    NSLog(@"SIS3305 Trigger forced");
    return;
}


- (void) writeThresholds
{
    [self writeLTThresholds];
    [self writeGTThresholds];
}

- (void) writeLTThresholds
{
	ORCommandList* aList = [ORCommandList commandList];
	int i;
	unsigned long thresholdMask;
	for(i = 0; i < kNumSIS3305Channels; i++)
    {
		thresholdMask = 0;

        thresholdMask |= ([self LTThresholdOn:i]    & 0x3ff)    <<0;
        thresholdMask |= ([self LTThresholdOff:i]   & 0x3ff)    <<16;
        thresholdMask |= ([self LTThresholdEnabled:i]&0x1)      <<31;
        
        [aList addCommand: [ORVmeReadWriteCommand writeLongBlock: &thresholdMask
                                                       atAddress: [self baseAddress] + [self getLTThresholdRegOffsets:i]
                                                      numToWrite: 1
                                                      withAddMod: [self addressModifier]
                                                   usingAddSpace: 0x01]];
    }
    
	[self executeCommandList:aList];
}
- (void) writeGTThresholds
{
    ORCommandList* aList = [ORCommandList commandList];
    int i;
    unsigned long thresholdMask;
    for(i = 0; i < kNumSIS3305Channels; i++)
    {
        thresholdMask = 0;
        
        thresholdMask |= ([self GTThresholdOn:i]    & 0x3ff)    <<0;
        thresholdMask |= ([self GTThresholdOff:i]   & 0x3ff)    <<16;
        thresholdMask |= ([self GTThresholdEnabled:i]&0x1)      <<31;

        [aList addCommand: [ORVmeReadWriteCommand writeLongBlock: &thresholdMask
                                                       atAddress: [self baseAddress] + [self getGTThresholdRegOffsets:i]
                                                      numToWrite: 1
                                                      withAddMod: [self addressModifier]
                                                   usingAddSpace: 0x01]];
    }
    
    [self executeCommandList:aList];
}

//-(void) writeHighThresholds
//{
//	ORCommandList* aList = [ORCommandList commandList];
//	int i;
//	for(i = 0; i < kNumSIS3305Channels; i++) {
//		if(![self extendedThresholdEnabled:i]){
//		unsigned long aThresholdValue = [self highThreshold:i]+0x10000;
//		[aList addCommand: [ORVmeReadWriteCommand writeLongBlock: &aThresholdValue
//													   atAddress: [self baseAddress] + [self getHighThresholdRegOffsets:i]
//													  numToWrite: 1
//													  withAddMod: [self addressModifier]
//												   usingAddSpace: 0x01]];
//		}
//		if([self extendedThresholdEnabled:i]){
//		unsigned long aThresholdValue = [self highThreshold:i]+0x2000000;
//		[aList addCommand: [ORVmeReadWriteCommand writeLongBlock: &aThresholdValue
//													   atAddress: [self baseAddress] + [self getHighThresholdRegOffsets:i]
//													  numToWrite: 1
//													  withAddMod: [self addressModifier]
//												   usingAddSpace: 0x01]];
//		}
//	}
//	[self executeCommandList:aList];
//}

- (void) writeEventConfiguration
{
	//******?the extern/internal gates seem to have an inverted logic, so the extern/internal gate matrixes in IB are swapped.
    /* 
        The are two event config registers, one for each channel group. They control the following:
        [2:0]   - Event saving mode
        3       unused
        4       - ADC Gate mode (else trigger mode)
        5       - Enable global trigger/Gate (synchronous mode)
        6       - Enable internal trigger/gate (asynchronous mode)
        7       unused
        8       - Enable ADC event sampling with next external trigger (TDC) (else with enable)
        9       - Enable "timestamp clear with sample enable" bit
        10      - Disable timestamp clear
        11      unused
        12      - Grey code enable
        [14:13] unused
        15      - ADC memory write via VME test enable
        16      - Disable "direct memory header" bit
        17      unused (and apparently Enable "direct memory TDC measurement" bit?)
        18      - Enable "Direct memory stop arm for trigger after pretrigger delay" bit
        19      unused
        [23:20] - ADC event header programmable info bits
        [31:24] - ADC event header programmable ID bits
                    24: reads as 0= ADC chip 1, 1= ADC chip 2
    */
    
	int i;
//	unsigned long tempIntGateMask  = internalGateEnabledMask;
//	unsigned long tempExtGateMask  = externalGateEnabledMask;
    
	ORCommandList* aList = [ORCommandList commandList];
	for(i=0;i<kNumSIS3305Groups;i++){
		unsigned long aValueMask = 0x0;
        
        aValueMask |= (eventSavingMode[i]               & 0x7)    << 0;
        // bit 3: unused
        // bit 4 ADC Gate Mode (ERROR: should implement)
        aValueMask |= (globalTriggerEnabled[i]          & 0x1)    << 5;
        aValueMask |= ([self internalTriggerEnabled:i]  &0x1)     << 6;
		// bit 7: unused
        // bit 8: enable "ADC event sampling with next external trigger" (ERROR: should implement)
        // bit 9: enable timestamp clear with sample enable (ERROR: should implement)
        // bit 10: disable timestamp clear (ERROR: should implement)
        // bit 11: unused
        // bit 12: Gray code enable (ERROR: should implement)
        // bit 13,14: unused
        // bit 15: ADC Memory write via VME Test Enable (ERROR: should implement)
        // bit 16: Disable "direct memory header" bit (ERROR: should implement)
        // bit 17: unused
        // bit 18: Enable "direct memory stop arm for trigger after pretrigger delay" (ERROR: should implement)
        // bit 19: unused
        // bit 20-23: ADC event header programmable info bits 0-3
        // bit 24-31: ADC event header programmable ID bits 0-7
        
		[aList addCommand: [ORVmeReadWriteCommand writeLongBlock: &aValueMask
													   atAddress: [self baseAddress] + [self getEventConfigOffsets:i]
													  numToWrite: 1
													  withAddMod: [self addressModifier]
												   usingAddSpace: 0x01]];
	}
	//extended event config reg
	for(i=0;i<kNumSIS3305Channels/2;i++){
		unsigned long aValueMask = 0x0;
		aValueMask |= ((adc50KTriggerEnabledMask & (1<<i*2))!=0)      << 0;
		aValueMask |= ((adc50KTriggerEnabledMask & (1<<((i*2)+1)))!=0)<< 8;
		[aList addCommand: [ORVmeReadWriteCommand writeLongBlock: &aValueMask
													   atAddress: [self baseAddress] + [self getExtendedEventConfigOffsets:i]
													  numToWrite: 1
													  withAddMod: [self addressModifier]
												   usingAddSpace: 0x01]];
	}
	[self executeCommandList:aList];
	
}


- (void) writePreTriggerDelayAndTriggerGateDelay
{
	int i;
	for(i=0;i<kNumSIS3305Channels/2;i++){
		
		int triggerValueToWrite = [self preTriggerDelay:i];
		triggerValueToWrite += 2;
		if(triggerValueToWrite == 0x1022)	  triggerValueToWrite = 0;
		else if(triggerValueToWrite == 0x1023)triggerValueToWrite = 1;
		
		int triggerGateToWrite = [self triggerGateLength:i];
		//triggerGateToWrite -= 1;
		
		unsigned long aValue = ((triggerValueToWrite&0x3ff)<<16) | triggerGateToWrite;
		[[self adapter] writeLongBlock:&aValue
							 atAddress:[self baseAddress] + [self getPreTriggerDelayTriggerGateLengthOffset:i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}	
}
- (void) writeBufferControl
{
	int i;
	for(i=0;i<kNumSIS3305Channels/2;i++){
		unsigned long aValueMask = 0;
		if(bufferWrapEnabledMask & (1<<i))aValueMask = 0x80000000;
		[[self adapter] writeLongBlock:&aValueMask
							 atAddress:[self baseAddress] + [self getBufferControlOffset:i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (void) writeEnergyGP
{
	int i;
	for(i=0;i<kNumSIS3305Channels/2;i++){
		unsigned long peakingTimeHi = ([self energyPeakingTime:i] >> 8) & 0x3;
		unsigned long peakingTimeLo = [self energyPeakingTime:i] & 0xff; 
		
		unsigned long aValueMask = (([self energyDecimation:i]  & 0x3)<<28) | 
		(peakingTimeHi <<16)				   | 
		(([self energyGapTime:i]     & 0xff)<<8) | 
		peakingTimeLo;
		
		[[self adapter] writeLongBlock:&aValueMask
							 atAddress:[self baseAddress] + [self getEnergySetupGPOffset:i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
	
//	[self resetSamplingLogic];
}

- (void) writeEndAddressThresholds
{
	int i;
	for(i=0;i<kNumSIS3305Channels/2;i++){
		[self writeEndAddressThreshold:i];
	}
}

- (void) writeEndAddressThreshold:(int)aGroup
{
	if(aGroup>=0 && aGroup<kNumSIS3305Groups){
		unsigned long aValue = [self endAddressThreshold:aGroup];
		[[self adapter] writeLongBlock:&aValue
							 atAddress:[self baseAddress] + [self getEndThresholdRegOffsets:aGroup]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (void) writeEnergyGateLength
{
	int group;
	unsigned long energyGateMask;
	for(group=0;group<kNumSIS3305Groups;group++){
		energyGateMask = 0;
		//--------------------------------------------------------------
		//only firmware version >=1512
		BOOL shipSummed = [self shipSummedWaveform];
		if(shipSummed)					energyGateMask |= (0x3<<28);
		//--------------------------------------------------------------
		
		energyGateMask |= [self energyGateLength:group];
		
		[[self adapter] writeLongBlock:&energyGateMask
							 atAddress:[self baseAddress] + [self getEnergyGateLengthOffsets:group]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (void) writeEnergyTauFactor
{
	int i;
	for(i=0;i<kNumSIS3305Channels;i++){
		unsigned long 	aValue = [self energyTauFactor:i];
		[[self adapter] writeLongBlock:&aValue
							 atAddress:[self baseAddress] + [self getEnergyTauFactorOffset:i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
		
	}
}

- (void) writeEnergySampleLength
{
	unsigned long aValue = energySampleLength;
	if (energySampleStartIndex2 != 0 || energySampleStartIndex3 != 0) {
		// This means we have multiple registers, divide by three.
		aValue /= 3;
	}
//	[[self adapter] writeLongBlock:&aValue
//						 atAddress:[self baseAddress] + kSIS3305EnergySampleLengthAllAdc
//						numToWrite:1
//						withAddMod:[self addressModifier]
//					 usingAddSpace:0x01];
}

- (void) writeEnergySampleStartIndexes
{	
	unsigned long aValue = energySampleStartIndex1;
//	[[self adapter] writeLongBlock:&aValue
//						 atAddress:[self baseAddress] + kSIS3305EnergySampleStartIndex1AllAdc
//						numToWrite:1
//						withAddMod:[self addressModifier]
//					 usingAddSpace:0x01];
	
	aValue = energySampleStartIndex2;
//	[[self adapter] writeLongBlock:&aValue
//						 atAddress:[self baseAddress] + kSIS3305EnergySampleStartIndex2AllAdc
//						numToWrite:1
//						withAddMod:[self addressModifier]
//					 usingAddSpace:0x01];
	
	aValue = energySampleStartIndex3;
//	[[self adapter] writeLongBlock:&aValue
//						 atAddress:[self baseAddress] + kSIS3305EnergySampleStartIndex3AllAdc
//						numToWrite:1
//						withAddMod:[self addressModifier]
//					 usingAddSpace:0x01];
	
}

-(void) writeEnergyNumberToSum
{
	unsigned long aValue;
	aValue = (energyNumberToSum-1) << 16 | (energyNumberToSum-1);//the number of values summed over = number written to register + 1
	
//	[[self adapter] writeLongBlock:&aValue
//						 atAddress:[self baseAddress] + kSIS3305EnergyNumberToSumAllAdc
//						numToWrite:1
//						withAddMod:[self addressModifier]
//					 usingAddSpace:0x01];
}

- (void) writeTriggerSetups
{
	int i;
	int group;
	for(i = 0; i < kNumSIS3305Channels; i++) {
		group = i/2;
		unsigned long aExtValueMask = (([self internalTriggerDelay:i] & 0x00ffL) << 24) | 
		(([self triggerDecimation:group]      & 0x0003L) << 16) | 
		(([self sumG:i]                 & 0x0F00L)) | 
		(([self peakingTime:i]          & 0x0F00L) >> 8);
		
		[[self adapter] writeLongBlock:&aExtValueMask
							 atAddress:[self baseAddress] + [self getTriggerExtSetupRegOffsets:i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
		
		unsigned long aTriggerMask =(([self gateLength:i]  & 0xffL) << 24) | 
		(([self pulseLength:i] & 0xffL) << 16) | 
		(([self sumG:i]        & 0xffL) <<  8) | 
		([self peakingTime:i] & 0xffL);
		
		[[self adapter] writeLongBlock:&aTriggerMask
							 atAddress:[self baseAddress] + [self getTriggerSetupRegOffsets:i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (void) writeRawDataBufferConfiguration
{	
	int group;
	for(group=0;group<kNumSIS3305Groups;group++){
		unsigned long sampleLength	   = [self sampleLength:group];
		unsigned long sampleStartIndex = [self sampleStartIndex:group];
		if(![self bufferWrapEnabled:group])sampleStartIndex = 0;
		
		unsigned long aValueMask = ((sampleLength & 0xfffc)<<16) | (sampleStartIndex & 0xfffe);
		
		[[self adapter] writeLongBlock:&aValueMask
							 atAddress:[self baseAddress] + [self getRawDataBufferConfigOffsets:group]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}


- (void) executeCommandList:(ORCommandList*) aList
{
	[[self adapter] executeCommandList:aList];
}

- (void) initBoard
{  
	[self calculateSampleValues];
	[self readModuleID:NO];
	[self writeEventConfiguration];
	[self writeEndAddressThresholds];
	[self writePreTriggerDelayAndTriggerGateDelay];
	[self writeEnergyGateLength];
	[self writeEnergyGP];
	[self writeEnergyTauFactor];
	[self writeRawDataBufferConfiguration];
	[self writeEnergySampleLength];
	[self writeEnergySampleStartIndexes];
	[self writeEnergyNumberToSum];
	[self writeTriggerSetups];
	[self writeThresholds];
//	[self writeHighThresholds];
//	[self writeDacOffsets];
//	[self resetSamplingLogic];
	[self writeBufferControl];
	
	if(runMode == kMcaRunMode){
		[self writeHistogramParams];
//		[self writeMcaScanControl];
//		[self writeMcaNofHistoPreset];
//		[self writeMcaLNESetupAndPrescalFactor];
//		[self writeMcaNofHistoPreset];
//		[self writeMcaLNESetupAndPrescalFactor];
//		[self writeMcaMultiScanNofScansPreset];
//		[self writeMcaCalculationFactors];
	}
	[self writeAcquistionRegister];			//set up the Acquisition Register
	
	if([gOrcaGlobals runInProgress]){
//		if(runMode == kMcaRunMode){
////			[self writeMcaArmMode];
//		}
		//else {
		//	[self disarmAndArmBank:0];
		//}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3305CardInited object:self];
	
}

- (BOOL) isEvent
{
	unsigned long data_rd = 0;
	[[self adapter] readLongBlock:&data_rd
						atAddress:[self baseAddress] + kSIS3305AcquisitionControl
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	uint32_t bankMask = bankOneArmed?0x10000:0x20000;
	return ((data_rd & 0x80000) == 0x80000) && ((data_rd & bankMask) == bankMask);
}

- (void) setUpPageReg
{
//	if(bankOneArmed)[self writePageRegister:0x4]; //bank one is armed, so bank2 (page 4) has to be readout
//	else			[self writePageRegister:0x0]; //Bank2 is armed and Bank1 (page 0) has to be readout
}

- (void) disarmSampleLogic
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSIS3305KeyDisarmSampleLogic
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

//- (void) disarmAndArmBank:(int) bank 
//{
//    if (bank==0) bankOneArmed = YES;
//    else		 bankOneArmed = NO;
//	
//    unsigned long addr = [self baseAddress] + ((bank == 0) ? kSIS3305KeyDisarmAndArmBank1 : kSIS3305KeyDisarmAndArmBank2);
//	unsigned long aValue= 0;
//	[[self adapter] writeLongBlock:&aValue
//						 atAddress:addr
//						numToWrite:1
//						withAddMod:[self addressModifier]
//					 usingAddSpace:0x01];
//	time(&lastBankSwitchTime);
//	waitingForSomeChannels = YES;
//	channelsToReadMask = 0xff;
//	
//}

//- (void) disarmAndArmNextBank
//{ 
//	return (bankOneArmed) ? [self disarmAndArmBank:1] : [self disarmAndArmBank:0]; 
//}

//- (void) writePageRegister:(int) aPage 
//{	
//	unsigned long aValue = aPage & 0xf;
//	[[self adapter] writeLongBlock:&aValue
//						 atAddress:[self baseAddress] + kSIS3305AdcMemoryPageRegister
//						numToWrite:1
//						withAddMod:[self addressModifier]
//					 usingAddSpace:0x01];	
//}

- (unsigned long) getPreviousBankSampleRegister:(int)channel
{
	unsigned long aValue = 0;
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] +  [self getPreviousBankSampleRegisterOffset:channel]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	return aValue;
}

- (NSString*) runSummary
{
	NSString* summary;
//	if(runMode == kMcaRunMode){
//		return @"MCA Spectrum";
//	}
//	else {
		BOOL tracesShipped = ([self sampleLength:0] || [self sampleLength:1]);
		summary = @"Energy";
		if(tracesShipped) summary = [summary stringByAppendingString:@" + Traces"];
		if(shipEnergyWaveform) summary = [summary stringByAppendingString:@" + Energy Filter"];
		summary = [summary stringByAppendingString:@"\n"];
		if(shipSummedWaveform) summary = [summary stringByAppendingString:@" + Summed Raw Trace"];
		summary = [summary stringByAppendingString:@"\n"];
		if(tracesShipped){
			summary = [summary stringByAppendingFormat:@"Traces 0:%d  1:%d \n", [self sampleLength:0],[self sampleLength:1]];
		}
		if(shipEnergyWaveform) summary = [summary stringByAppendingFormat:@"Energy Filter: 510 values\n"];
		if(shipSummedWaveform) summary = [summary stringByAppendingFormat:@"Summed Raw Trace: 510 values\n"];		
		return summary;
//	}
}

- (void) writeHistogramParams
{
//	unsigned long aValue =   kSIS3305McaEnable2468 | kSIS3305McaEnable1357 | ((mcaPileupEnabled << 3) + mcaHistoSize);
//	[[self adapter] writeLongBlock:&aValue
//						 atAddress:[self baseAddress] + kSIS3305McaHistogramParamAllAdc
//						numToWrite:1
//						withAddMod:[self addressModifier]
//					 usingAddSpace:0x01];	
}

#pragma mark - Data Taker

- (unsigned long) mcaId { return mcaId; }
- (void) setMcaId: (unsigned long) anId
{
    mcaId = anId;
}
- (unsigned long) lostDataId { return lostDataId; }
- (void) setLostDataId: (unsigned long) anId
{
    lostDataId = anId;
}

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId   = [assigner assignDataIds:kLongForm];
    mcaId    = [assigner assignDataIds:kLongForm]; 
    lostDataId  = [assigner assignDataIds:kLongForm]; 
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
    [self setMcaId:[anotherCard mcaId]];
    [self setLostDataId:[anotherCard lostDataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	NSDictionary* aDictionary;
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORSIS3305DecoderForEnergy",				@"decoder",
				   [NSNumber numberWithLong:dataId],@"dataId",
				   [NSNumber numberWithBool:YES],   @"variable",
				   [NSNumber numberWithLong:-1],	@"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"Energy"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORSIS3305DecoderForMca",			@"decoder",
				   [NSNumber numberWithLong:mcaId], @"dataId",
				   [NSNumber numberWithBool:YES],   @"variable",
				   [NSNumber numberWithLong:-1],	@"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"MCA"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORSIS3305DecoderForLostData",			@"decoder",
				   [NSNumber numberWithLong:lostDataId],	@"dataId",
				   [NSNumber numberWithBool:NO],			@"variable",
				   [NSNumber numberWithLong:3],				@"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"LostData"];
	
    return dataDictionary;
}

#pragma mark - HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (int) numberOfChannels
{
    return kNumSIS3305Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
  	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Run Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setRunMode:) getMethod:@selector(runMode)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Extra Time Record"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setShipTimeRecordAlso:) getMethod:@selector(shipTimeRecordAlso)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"LTThresholdEnabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setLTThresholdEnabled:withValue:) getMethod:@selector(LTThresholdEnabled:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"GTThresholdEnabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setGTThresholdEnabled:withValue:) getMethod:@selector(GTThresholdEnabled:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"ADC50K Trigger"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setAdc50KTriggerEnabled:withValue:) getMethod:@selector(adc50KTriggerEnabled:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Input Inverted"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setInputInverted:withValue:) getMethod:@selector(inputInverted:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Buffer Wrap Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setBufferWrapEnabled:withValue:) getMethod:@selector(bufferWrapEnabled:)];
    [a addObject:p];
	
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Internal Trigger Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setInternalTriggerEnabled:withValue:) getMethod:@selector(internalTriggerEnabled:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"External Trigger Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setExternalTriggerEnabled:withValue:) getMethod:@selector(externalTriggerEnabled:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Internal Gate Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setInternalGateEnabled:withValue:) getMethod:@selector(internalGateEnabled:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"External Gate Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setExternalGateEnabled:withValue:) getMethod:@selector(externalGateEnabled:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Extended Threshold Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setExtendedThresholdEnabled:withValue:) getMethod:@selector(extendedThresholdEnabled:)];
    [a addObject:p];
	
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
//    p = [[[ORHWWizParam alloc] init] autorelease];
//    [p setName:@"CFD"];
//    [p setFormat:@"##0" upperLimit:0x2 lowerLimit:0 stepSize:1 units:@"Index"];
//    [p setSetMethod:@selector(setCfdControl:withValue:) getMethod:@selector(cfdControl:)];
//    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gate Length"];
    [p setFormat:@"##0" upperLimit:0x3f lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setGateLength:withValue:) getMethod:@selector(gateLength:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pulse Length"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPulseLength:withValue:) getMethod:@selector(pulseLength:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Sum G"];
    [p setFormat:@"##0" upperLimit:0x3ff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setSumG:withValue:) getMethod:@selector(sumG:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Peaking Time"];
    [p setFormat:@"##0" upperLimit:0x3ff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPeakingTime:withValue:) getMethod:@selector(peakingTime:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Dac Offset"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setDacOffset:withValue:) getMethod:@selector(dacOffset:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"InternalTriggerDelay"];
    [p setFormat:@"##0" upperLimit:(firmwareVersion<15?63:255) lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setInternalTriggerDelay:withValue:) getMethod:@selector(internalTriggerDelay:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Energy Decimation"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setEnergyDecimation:withValue:) getMethod:@selector(energyDecimation:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Decimation"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTriggerDecimation:withValue:) getMethod:@selector(triggerDecimation:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Sample Length"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:4 stepSize:1 units:@""];
    [p setSetMethod:@selector(setSampleLength:withValue:) getMethod:@selector(sampleLength:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pretrigger Delay"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:1 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPreTriggerDelay:withValue:) getMethod:@selector(preTriggerDelay:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Gate Length"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTriggerGateLength:withValue:) getMethod:@selector(triggerGateLength:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Energy Gate Length"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setEnergyGateLength:withValue:) getMethod:@selector(energyGateLength:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Energy Gap Time"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setEnergyGapTime:withValue:) getMethod:@selector(energyGapTime:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Energy Peaking Time"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setEnergyPeakingTime:withValue:) getMethod:@selector(energyPeakingTime:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Energy Sample Length"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setEnergySampleLength:) getMethod:@selector(energySampleLength)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Energy Tau Factor"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setEnergyTauFactor:withValue:) getMethod:@selector(energyTauFactor:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    return a;
}


- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORSIS3305Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORSIS3305Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:@"Threshold"])						return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
//	else if([param isEqualToString:@"highThreshold"])				return [[cardDictionary objectForKey:@"highThresholds"] objectAtIndex:aChannel];
//	else if([param isEqualToString:@"CFD"])							return [[cardDictionary objectForKey:@"cfdControls"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"GateLength"])					return [[cardDictionary objectForKey:@"gateLengths"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"PulseLength"])					return [[cardDictionary objectForKey:@"pulseLengths"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"SumG"])						return [[cardDictionary objectForKey:@"sumGs"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"PeakingTime"])					return [[cardDictionary objectForKey:@"peakingTimes"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"InternalTriggerDelay"])		return [[cardDictionary objectForKey:@"internalTriggerDelays"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"Dac Offset"])					return [[cardDictionary objectForKey:@"dacOffsets"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"TriggerDecimation"])			return [cardDictionary objectForKey:@"triggerDecimation"];
	else if([param isEqualToString:@"EnergyDecimation"])			return [cardDictionary objectForKey:@"energyDecimation"];
    else if([param isEqualToString:@"Clock Source"])				return [cardDictionary objectForKey:@"clockSource"];
    else if([param isEqualToString:@"Run Mode"])					return [cardDictionary objectForKey:@"runMode"];
    else if([param isEqualToString:@"Extra Time Record"])			return [cardDictionary objectForKey:@"shipTimeRecordAlso"];
    else if([param isEqualToString:@"GT"])							return [cardDictionary objectForKey:@"gtMask"];
    else if([param isEqualToString:@"ADC50K Trigger"])				return [cardDictionary objectForKey:@"adc50KtriggerEnabledMask"];
    else if([param isEqualToString:@"Input Inverted"])				return [cardDictionary objectForKey:@"inputInvertedMask"];
    else if([param isEqualToString:@"Buffer Wrap Enabled"])			return [cardDictionary objectForKey:@"bufferWrapEnabledMask"];
    else if([param isEqualToString:@"Internal Trigger Enabled"])	return [cardDictionary objectForKey:@"internalTriggerEnabledMask"];
    else if([param isEqualToString:@"External Trigger Enabled"])	return [cardDictionary objectForKey:@"externalTriggerEnabledMask"];
    else if([param isEqualToString:@"Internal Gate Enabled"])		return [cardDictionary objectForKey:@"internalGateEnabledMask"];
    else if([param isEqualToString:@"External Gate Enabled"])		return [cardDictionary objectForKey:@"externalGateEnabledMask"];
    else if([param isEqualToString:@"Trigger Decimation"])			return [cardDictionary objectForKey:@"triggerDecimation"];
    else if([param isEqualToString:@"Energy Decimation"])			return [cardDictionary objectForKey:@"energyDecimation"];
    else if([param isEqualToString:@"Energy Gate Length"])			return [cardDictionary objectForKey:@"energyGateLength"];
    else if([param isEqualToString:@"Energy Tau Factor"])			return [cardDictionary objectForKey:@"energyTauFactor"];
    else if([param isEqualToString:@"Energy Sample Length"])		return [cardDictionary objectForKey:@"energySampleLength"];
    else if([param isEqualToString:@"Energy Gap Time"])				return [cardDictionary objectForKey:@"energyGapTime"];
    else if([param isEqualToString:@"Energy Peaking Time"])			return [cardDictionary objectForKey:@"energyPeakingTime"];
    else if([param isEqualToString:@"Trigger Gate Delay"])			return [cardDictionary objectForKey:@"triggerGateLength"];
    else if([param isEqualToString:@"Pretrigger Delay"])			return [cardDictionary objectForKey:@"preTriggerDelay"];
    else if([param isEqualToString:@"Sample Length"])				return [cardDictionary objectForKey:@"sampleLength"];
    else if([param isEqualToString:@"Extended Threshold Enabled"])	return [cardDictionary objectForKey:@"extendedThresholdEnabledMask"];
	
	else return nil;
}

#pragma mark - DataTaking
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3305"];    
    
    //cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
    
	[self reset];
	[self initBoard];

	[self setLed1:YES];
//	[self clearTimeStamp];
	
	firstTime	= YES;
	currentBank = 0;
	isRunning	= NO;
	count=0;
	wrapMaskForRun = bufferWrapEnabledMask;
    [self startRates];
	
	int group;
	for(group=0;group<kNumSIS3305Groups;group++){
		dataRecord[group] = nil;
	}
	
//	if(runMode == kMcaRunMode){
//		mcaScanBank2Flag = NO;
//		[self writeMcaArmMode];
//		[self pollMcaStatus];
//	}
	
	if(pulseMode){
		NSLogColor([NSColor redColor], @"SIS3305 Slot %d is in special readout mode -- only one buffer will be read each time the SBC is unpaused\n",[self slot]);
	}
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	//reading events from the mac is very, very slow. If the buffer is filling up, it can take a long time to readout all events.
	//Because of this we limit the number of events from any one buffer read. The SBC should be used if possible.
    @try {
		if(runMode == kMcaRunMode){
			//do nothing.. read out mca spectrum at end
		}
		else {
			if(firstTime){
				int group;
				for(group=0;group<kNumSIS3305Groups;group++){
					long sisHeaderLength = 2;
					if(wrapMaskForRun & (1L<<group))	sisHeaderLength = 4;
					dataRecordlength[group] = 4+sisHeaderLength+[self sampleLength:group]/2+energySampleLength/2+4; //Orca header+sisheader+samples+energy+sistrailer
					dataRecord[group]		= malloc(dataRecordlength[group]*sizeof(unsigned long)+100);
				}
				isRunning = YES;
				firstTime = NO;
//				[self disarmAndArmBank:0];
//				[self disarmAndArmBank:1];
				waitingForSomeChannels = NO;
			}
			else {
				
				if(!waitingForSomeChannels){
					time_t theTime;
					time(&theTime);
					if(((theTime - lastBankSwitchTime) < 2) && ![self isEvent])	return; //not going to readout so return
//					[self disarmAndArmNextBank];
//					[self setUpPageReg];
					waitCount = 0;
				}
				
				//if we get here, there may be something to read out
				int i;
				for(i=0;i<kNumSIS3305Channels;i++) {
					if ( channelsToReadMask & (1<<i)){
						
						unsigned long endSampleAddress = [self getPreviousBankSampleRegister:i];
						if (((endSampleAddress >> 24) & 0x1) ==  (bankOneArmed ? 1:0)) { 
							channelsToReadMask &= ~(1<<i);
							
							unsigned long numberBytesToRead	= (endSampleAddress & 0xffffff) * 2;
							
							if(numberBytesToRead){
								unsigned long addrOffset = 0;
								int group				 = i/2;
								int eventCount			 = 0;
								do {
									BOOL wrapMode = (wrapMaskForRun & (1L<<group))!=0;
									int index = 0;
									dataRecord[group][index++] =   dataId | dataRecordlength[group];
									dataRecord[group][index++] =	(([self crateNumber]&0x0000000f)<<21) | 
																	(([self slot] & 0x0000001f)<<16)      |
																	((i & 0x000000ff)<<8)			      |
																	wrapMode;
									dataRecord[group][index++] = [self sampleLength:group]/2;
									dataRecord[group][index++] = energySampleLength;
									unsigned long* p = &dataRecord[group][index];
									[[self adapter] readLongBlock: p
														atAddress: [self baseAddress] + [self getADCBufferRegisterOffset:i] + addrOffset
														numToRead: dataRecordlength[group]
													   withAddMod: [self addressModifier]
													usingAddSpace: 0x01];
									
									if(dataRecord[group][dataRecordlength[group]-1] == 0xdeadbeef){
										[aDataPacket addLongsToFrameBuffer:dataRecord[group] length:dataRecordlength[group]];
									}
									else continue;
									
									addrOffset += (dataRecordlength[group]-4)*4;
									if(++eventCount > 25)break;
								} while (addrOffset < endSampleAddress);
							}
						}
					}
				}
				
				waitingForSomeChannels = (channelsToReadMask!=0);
				
				if(waitingForSomeChannels){
					//if we wait too long, do a logic reset
					waitCount++;
					if(waitCount > 10){						
						int index = 0;
						dataRecord[0][index++] = lostDataId | 3; 
						dataRecord[0][index++] = (([self crateNumber] & 0x0000000f) << 21)  | 
												 (([self slot]        & 0x0000001f) << 16)  | 1; //1 == reset event
						dataRecord[0][index++] = channelsToReadMask<<16;
						[aDataPacket addLongsToFrameBuffer:dataRecord[0] length:3];
//						[self resetSamplingLogic];
					}
				}
			}
		}
	}
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
}


- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	isRunning = NO;
	
//	if(runMode == kMcaRunMode){
//		unsigned long mcaLength;
//		switch (mcaHistoSize) {
//			case 0:  mcaLength = 1024; break;
//			case 1:  mcaLength = 2048; break;
//			case 2:  mcaLength = 4096; break;
//			case 3:  mcaLength = 8192; break;
//			default: mcaLength = 2048; break;
//		}
//		unsigned long pageOffset = 0x0;
//		if(mcaScanBank2Flag) pageOffset = 8 * 0x1024 * 0x1024;
		
//		int channel;
//		for(channel=0;channel<kNumSIS3305Channels;channel++){
//			if(gtMask & (1<<channel)){
////				NSMutableData* mcaData = [NSMutableData dataWithLength:(mcaLength + 2)*sizeof(long)];
//				unsigned long* mcaBytes = (unsigned long*)[mcaData bytes];
//				mcaBytes[0] = mcaId | (mcaLength+2);
//				mcaBytes[1] =	(([self crateNumber]&0x0000000f)<<21) | 
//								(([self slot] & 0x0000001f)<<16)      |
//								((channel & 0x000000ff)<<8);
				
//				[[self adapter] readLongBlock: &mcaBytes[2]
//									atAddress: [self baseAddress] + [self getADCBufferRegisterOffset:channel] + pageOffset
//									numToRead: mcaLength
//								   withAddMod: [self addressModifier]
//								usingAddSpace: 0x01];
//				[aDataPacket addData:mcaData];
//			}
//		}
//	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
//	if(runMode == kMcaRunMode){	
//		unsigned long aValue = 0;
//		[[self adapter] writeLongBlock:&aValue
//							 atAddress:[self baseAddress] + kSIS3305KeyMcaMultiScanDisable
//							numToWrite:1
//							withAddMod:[self addressModifier]
//						 usingAddSpace:0x01];	
//		
//		[[self adapter] writeLongBlock:&aValue
//							 atAddress:[self baseAddress] + kSIS3305KeyMcaScanStop
//							numToWrite:1
//							withAddMod:[self addressModifier]
//						 usingAddSpace:0x01];	
//		
//		[self readMcaStatus];
//	}
	
//	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollMcaStatus) object:nil];
	
	[self disarmSampleLogic];
    [waveFormRateGroup stop];
	[self setLed1:NO];
	
	int group;
	for(group=0;group<kNumSIS3305Groups;group++){
		if(dataRecord){
			free(dataRecord[group]);
			dataRecord[group] = nil;
		}
	}
	
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	if(runMode == kMcaRunMode){
		//in MCA mode there is nothing for the SBC to do... so don't ship any card config data to it.
		return index; 
	}
	else {
		configStruct->total_cards++;
		configStruct->card_info[index].hw_type_id				= kSIS3305; //should be unique
		configStruct->card_info[index].hw_mask[0]				= dataId;	//better be unique
		configStruct->card_info[index].hw_mask[1]				= lostDataId;	//better be unique
		configStruct->card_info[index].slot						= [self slot];
		configStruct->card_info[index].crate					= [self crateNumber];
		configStruct->card_info[index].add_mod					= [self addressModifier];
		configStruct->card_info[index].base_add					= [self baseAddress];
		configStruct->card_info[index].deviceSpecificData[0]	= [self sampleLength:0]/2;
		configStruct->card_info[index].deviceSpecificData[1]	= [self sampleLength:1]/2;
		configStruct->card_info[index].deviceSpecificData[2]	= [self sampleLength:2]/2;
		configStruct->card_info[index].deviceSpecificData[3]	= [self sampleLength:3]/2;
		configStruct->card_info[index].deviceSpecificData[4]	= [self energySampleLength];
		configStruct->card_info[index].deviceSpecificData[5]	= [self bufferWrapEnabledMask];
		configStruct->card_info[index].deviceSpecificData[6]	= [self pulseMode];
		
		configStruct->card_info[index].num_Trigger_Indexes		= 0;
		
		configStruct->card_info[index].next_Card_Index 	= index+1;	
		
		return index+1;
	}
}

- (void) reset
{
 	unsigned long aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3305KeyReset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

//- (void) resetSamplingLogic
//{
// 	unsigned long aValue = 0; //value doesn't matter 
//	[[self adapter] writeLongBlock:&aValue
//                         atAddress:[self baseAddress] + kSIS3305KeySampleLogicReset
//                        numToWrite:1
//                        withAddMod:[self addressModifier]
//                     usingAddSpace:0x01];
//}

- (BOOL) bumpRateFromDecodeStage:(short)channel
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
    for(i=0;i<kNumSIS3305Channels;i++){
        waveFormCount[i]=0;
    }
}

#pragma mark - Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    /*
        These are all the parameters that are saved when a configuration file is saved
     */
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	
    [self setPulseMode:                 [decoder decodeBoolForKey:@"pulseMode"]];
    [self setFirmwareVersion:			[decoder decodeFloatForKey:@"firmwareVersion"]];
    [self setShipTimeRecordAlso:		[decoder decodeBoolForKey:@"shipTimeRecordAlso"]];
	
    [self setRunMode:					[decoder decodeIntForKey:@"runMode"]];
    [self setInternalExternalTriggersOred:[decoder decodeBoolForKey:@"internalExternalTriggersOred"]];
    [self setLemoInEnabledMask:			[decoder decodeIntForKey:@"lemoInEnabledMask"]];
    [self setEnergySampleStartIndex3:	[decoder decodeIntForKey:@"energySampleStartIndex3"]];
    [self setEnergySampleStartIndex2:	[decoder decodeIntForKey:@"energySampleStartIndex2"]];
    [self setEnergySampleStartIndex1:	[decoder decodeIntForKey:@"energySampleStartIndex1"]];
	[self setEnergyNumberToSum:			[decoder decodeIntForKey:@"energyNumberToSum"]];
    [self setEnergySampleLength:		[decoder decodeIntForKey:@"energySampleLength"]];
    [self setLemoInMode:				[decoder decodeIntForKey:@"lemoInMode"]];
    [self setLemoOutMode:				[decoder decodeIntForKey:@"lemoOutMode"]];
	
    [self setClockSource:				[decoder decodeIntForKey:@"clockSource"]];
    [self setTriggerOutEnabledMask:		[decoder decodeInt32ForKey:@"triggerOutEnabledMask"]];
	[self setHighEnergySuppressMask:	[decoder decodeInt32ForKey:@"highEnergySuppressMask"]];
    [self setInputInvertedMask:			[decoder decodeInt32ForKey:@"inputInvertedMask"]];
    
    int i;
    for (i=0; i<kNumSIS3305Groups; i++) {
        [self setInternalTriggerEnabled:i       withValue:[decoder decodeInt32ForKey:@"internalTriggerEnabled"]];
    }
    [self setExternalTriggerEnabledMask:[decoder decodeInt32ForKey:@"externalTriggerEnabledMask"]];
    [self setExtendedThresholdEnabledMask:[decoder decodeInt32ForKey:@"extendedThresholdEnabledMask"]];
    [self setInternalGateEnabledMask:	[decoder decodeInt32ForKey:@"internalGateEnabledMask"]];
    [self setExternalGateEnabledMask:	[decoder decodeInt32ForKey:@"externalGateEnabledMask"]];
    [self setAdc50KTriggerEnabledMask:	[decoder decodeInt32ForKey:@"adc50KtriggerEnabledMask"]];
//	[self setGtMask:					[decoder decodeIntForKey:@"gtMask"]];
	[self setShipEnergyWaveform:		[decoder decodeBoolForKey:@"shipEnergyWaveform"]];
	[self setShipSummedWaveform:		[decoder decodeBoolForKey:@"shipSummedWaveform"]];
    [self setWaveFormRateGroup:			[decoder decodeObjectForKey:@"waveFormRateGroup"]];
	
    // becauase these are set up as c-arrays, we have to step through them
    int chan;
    for (chan = 0; chan<kNumSIS3305Channels; chan++)
    {
        //threshold mode can't be set directly, since we store the individual LT ang GT enabled with the encoder
        [self setLTThresholdEnabled:chan    withValue:[decoder decodeIntForKey:[@"LTThresholdEnabled"	    stringByAppendingFormat:@"%d",chan]]];
        [self setGTThresholdEnabled:chan    withValue:[decoder decodeIntForKey:[@"GTThresholdEnabled"	    stringByAppendingFormat:@"%d",chan]]];
        [self setLTThresholdOn:chan         withValue:[decoder decodeIntForKey:[@"LTThresholdOn"            stringByAppendingFormat:@"%d",chan]]];
        [self setLTThresholdOff:chan        withValue:[decoder decodeIntForKey:[@"LTThresholdOff"            stringByAppendingFormat:@"%d",chan]]];
        [self setGTThresholdOn:chan         withValue:[decoder decodeIntForKey:[@"GTThresholdOn"            stringByAppendingFormat:@"%d",chan]]];
        [self setGTThresholdOff:chan        withValue:[decoder decodeIntForKey:[@"GTThresholdOff"            stringByAppendingFormat:@"%d",chan]]];
    }
    
    sampleLengths = 			[[decoder decodeObjectForKey:@"sampleLengths"]retain];
	thresholds  =				[[decoder decodeObjectForKey:@"thresholds"] retain];
//	highThresholds =			[[decoder decodeObjectForKey:@"highThresholds"] retain];
    dacOffsets  =				[[decoder decodeObjectForKey:@"dacOffsets"] retain];
	gateLengths =				[[decoder decodeObjectForKey:@"gateLengths"] retain];
	pulseLengths =				[[decoder decodeObjectForKey:@"pulseLengths"] retain];
	sumGs =						[[decoder decodeObjectForKey:@"sumGs"] retain];
	peakingTimes =				[[decoder decodeObjectForKey:@"peakingTimes"] retain];
	internalTriggerDelays =		[[decoder decodeObjectForKey:@"internalTriggerDelays"] retain];
	triggerDecimations = 		[[decoder decodeObjectForKey:@"triggerDecimations"] retain];
    triggerGateLengths =		[[decoder decodeObjectForKey:@"triggerGateLengths"] retain];
    sampleStartIndexes =		[[decoder decodeObjectForKey:@"sampleStartIndexes"] retain];
    energyTauFactors =			[[decoder decodeObjectForKey:@"energyTauFactors"] retain];
	energyDecimations=			[[decoder decodeObjectForKey:@"energyDecimations"]retain];
	energyGapTimes = 			[[decoder decodeObjectForKey:@"energyGapTimes"]retain];
    energyPeakingTimes =		[[decoder decodeObjectForKey:@"energyPeakingTimes"]retain];
    preTriggerDelays =			[[decoder decodeObjectForKey:@"preTriggerDelays"] retain];
	
	//force a constraint check by reloading the pretrigger delays
	int aGroup;
	for(aGroup=0;aGroup<kNumSIS3305Groups;aGroup++){
		[self setPreTriggerDelay:aGroup withValue:[self preTriggerDelay:aGroup]];
	}
	
//    int aChan;
//    for (aChan = 0; aChan<kNumSIS3305Channels; aChan++) {
////        [self setLTThresholdEnabled:aChan withValue:[decoder]]

//    }
    
	//firmware 15xx
//    cfdControls =					[[decoder decodeObjectForKey:@"cfdControls"] retain];
    [self setBufferWrapEnabledMask:	[decoder decodeInt32ForKey:@"bufferWrapEnabledMask"]];
	
	if(!waveFormRateGroup){
		[self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3305Channels groupTag:0] autorelease]];
	    [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	[self setUpArrays];
	
	[self calculateEnergyGateLength];
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    /*
        This takes all the things that have been initialized in initWithCoder and writes values to them
        This should be called when a configuration is saved.
    */
    [super encodeWithCoder:encoder];
	
	[encoder encodeBool:pulseMode               forKey:@"pulseMode"];
	[encoder encodeFloat:firmwareVersion		forKey:@"firmwareVersion"];
	[encoder encodeBool:shipTimeRecordAlso		forKey:@"shipTimeRecordAlso"];
//	[encoder encodeBool:mcaUseEnergyCalculation forKey:@"mcaUseEnergyCalculation"];
//	[encoder encodeInt:mcaEnergyOffset			forKey:@"mcaEnergyOffset"];
//	[encoder encodeInt:mcaEnergyMultiplier		forKey:@"mcaEnergyMultiplier"];
//	[encoder encodeInt:mcaEnergyDivider			forKey:@"mcaEnergyDivider"];
//	[encoder encodeInt:mcaMode					forKey:@"mcaMode"];
//	[encoder encodeBool:mcaPileupEnabled		forKey:@"mcaPileupEnabled"];
//	[encoder encodeInt:mcaHistoSize				forKey:@"mcaHistoSize"];
//	[encoder encodeInt32:mcaNofScansPreset		forKey:@"mcaNofScansPreset"];
//	[encoder encodeBool:mcaAutoClear			forKey:@"mcaAutoClear"];
//	[encoder encodeInt32:mcaPrescaleFactor		forKey:@"mcaPrescaleFactor"];
//	[encoder encodeBool:mcaLNESetup				forKey:@"mcaLNESetup"];
//	[encoder encodeInt32:mcaNofHistoPreset		forKey:@"mcaNofHistoPreset"];
	
    //channel-level c-arrays:
    int chan;
    for (chan=0; chan<kNumSIS3305Channels; chan++) {
        [encoder encodeInt:LTThresholdEnabled[chan]		forKey:[@"LTThresholdEnabled"	stringByAppendingFormat:@"%d",chan]];
        [encoder encodeInt:GTThresholdEnabled[chan]		forKey:[@"GTThresholdEnabled"	stringByAppendingFormat:@"%d",chan]];
        [encoder encodeInt:LTThresholdOn[chan]          forKey:[@"LTThresholdOn"		stringByAppendingFormat:@"%d",chan]];
        [encoder encodeInt:LTThresholdOff[chan]         forKey:[@"LTThresholdOff"		stringByAppendingFormat:@"%d",chan]];
        [encoder encodeInt:GTThresholdOn[chan]          forKey:[@"GTThresholdOn"		stringByAppendingFormat:@"%d",chan]];
        [encoder encodeInt:GTThresholdOff[chan]         forKey:[@"GTThresholdOff"		stringByAppendingFormat:@"%d",chan]];

    }
    
    [encoder encodeInt:runMode					forKey:@"runMode"];
    [encoder encodeInt:clockSource				forKey:@"clockSource"];
	[encoder encodeInt:lemoInEnabledMask		forKey:@"lemoInEnabledMask"];
	[encoder encodeInt:energySampleStartIndex3	forKey:@"energySampleStartIndex3"];
	[encoder encodeInt:energySampleStartIndex2	forKey:@"energySampleStartIndex2"];
	[encoder encodeInt:energySampleStartIndex1	forKey:@"energySampleStartIndex1"];
	[encoder encodeInt:energyNumberToSum		forKey:@"energyNumberToSum"];
	[encoder encodeInt:energySampleLength		forKey:@"energySampleLength"];
	[encoder encodeInt:lemoInMode				forKey:@"lemoInMode"];
	[encoder encodeInt:lemoOutMode				forKey:@"lemoOutMode"];
	[encoder encodeBool:shipEnergyWaveform		forKey:@"shipEnergyWaveform"];
	[encoder encodeBool:shipSummedWaveform		forKey:@"shipSummedWaveform"];
	
	[encoder encodeBool:internalExternalTriggersOred	forKey:@"internalExternalTriggersOred"];
	[encoder encodeInt32:triggerOutEnabledMask			forKey:@"triggerOutEnabledMask"];
	[encoder encodeInt32:highEnergySuppressMask			forKey:@"highEnergySuppressMask"];
	[encoder encodeInt32:inputInvertedMask				forKey:@"inputInvertedMask"];
	[encoder encodeInt32:internalTriggerEnabledMask		forKey:@"internalTriggerEnabledMask"];
	[encoder encodeInt32:externalTriggerEnabledMask		forKey:@"externalTriggerEnabledMask"];
	[encoder encodeInt32:extendedThresholdEnabledMask	forKey:@"extendedThresholdEnabledMask"];
	[encoder encodeInt32:internalGateEnabledMask		forKey:@"internalGateEnabledMask"];
	[encoder encodeInt32:externalGateEnabledMask		forKey:@"externalGateEnabledMask"];
	[encoder encodeInt32:adc50KTriggerEnabledMask		forKey:@"adc50KtriggerEnabledMask"];
	
	[encoder encodeObject:energyDecimations		forKey:@"energyDecimations"];
	[encoder encodeObject:energyGapTimes		forKey:@"energyGapTimes"];
	[encoder encodeObject:energyPeakingTimes	forKey:@"energyPeakingTimes"];
    [encoder encodeObject:waveFormRateGroup		forKey:@"waveFormRateGroup"];
	[encoder encodeObject:sampleLengths			forKey:@"sampleLengths"];
	[encoder encodeObject:thresholds			forKey:@"thresholds"];
	[encoder encodeObject:dacOffsets			forKey:@"dacOffsets"];
	[encoder encodeObject:gateLengths			forKey:@"gateLengths"];
	[encoder encodeObject:pulseLengths			forKey:@"pulseLengths"];
	[encoder encodeObject:sumGs					forKey:@"sumGs"];
	[encoder encodeObject:peakingTimes			forKey:@"peakingTimes"];
	[encoder encodeObject:internalTriggerDelays	forKey:@"internalTriggerDelays"];
	[encoder encodeObject:triggerGateLengths	forKey:@"triggerGateLengths"];
	[encoder encodeObject:preTriggerDelays		forKey:@"preTriggerDelays"];
	[encoder encodeObject:sampleStartIndexes	forKey:@"sampleStartIndexes"];
	[encoder encodeObject:triggerDecimations	forKey:@"triggerDecimations"];
	[encoder encodeObject:energyTauFactors		forKey:@"energyTauFactors"];
	//firmware 15xx
//	[encoder encodeObject:cfdControls			forKey:@"cfdControls"];
    [encoder encodeInt32:bufferWrapEnabledMask	forKey:@"bufferWrapEnabledMask"];

	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    /* 
        This dictionary is what gets written to the header of each run data file.
        The parameters must be included below for the values to show up there.
     */
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	
    [objDictionary setObject: [NSNumber numberWithLong:LTThresholdEnabled]			forKey:@"LTThresholdEnabled"];
    [objDictionary setObject: [NSNumber numberWithLong:GTThresholdEnabled]			forKey:@"GTThresholdEnabled"];
	[objDictionary setObject: [NSNumber numberWithInt:clockSource]					forKey:@"clockSource"];
	[objDictionary setObject: [NSNumber numberWithLong:adc50KTriggerEnabledMask]	forKey:@"adc50KtriggerEnabledMask"];
	[objDictionary setObject: [NSNumber numberWithLong:triggerOutEnabledMask]		forKey:@"triggerOutEnabledMask"];
	[objDictionary setObject: [NSNumber numberWithLong:highEnergySuppressMask]		forKey:@"highEnergySuppressMask"];
	[objDictionary setObject: [NSNumber numberWithLong:inputInvertedMask]			forKey:@"inputInvertedMask"];
	[objDictionary setObject: [NSNumber numberWithLong:internalTriggerEnabledMask]	forKey:@"internalTriggerEnabledMask"];
	[objDictionary setObject: [NSNumber numberWithLong:externalTriggerEnabledMask]	forKey:@"externalTriggerEnabledMask"];
	[objDictionary setObject: [NSNumber numberWithLong:internalGateEnabledMask]		forKey:@"internalGateEnabledMask"];
	[objDictionary setObject: [NSNumber numberWithLong:externalGateEnabledMask]		forKey:@"externalGateEnabledMask"];
	[objDictionary setObject: [NSNumber numberWithLong:extendedThresholdEnabledMask]	forKey:@"extendedThresholdEnabledMask"];
 	
	[objDictionary setObject:[NSNumber numberWithInt:runMode]						forKey:@"runMode"];
	[objDictionary setObject:[NSNumber numberWithInt:shipTimeRecordAlso]			forKey:@"shipTimeRecordAlso"];
	
	[objDictionary setObject:[NSNumber numberWithInt:lemoInEnabledMask]				forKey:@"lemoInEnabledMask"];
	[objDictionary setObject:[NSNumber numberWithInt:energySampleStartIndex3]		forKey:@"energySampleStartIndex3"];
	[objDictionary setObject:[NSNumber numberWithInt:energySampleStartIndex2]		forKey:@"energySampleStartIndex2"];
	[objDictionary setObject:[NSNumber numberWithInt:energySampleStartIndex1]		forKey:@"energySampleStartIndex1"];
	[objDictionary setObject:[NSNumber numberWithInt:energyNumberToSum]				forKey:@"energyNumberToSum"];
	[objDictionary setObject:[NSNumber numberWithInt:energySampleLength]			forKey:@"energySampleLength"];
	[objDictionary setObject:[NSNumber numberWithInt:lemoInMode]					forKey:@"lemoInMode"];
	[objDictionary setObject:[NSNumber numberWithInt:lemoOutMode]					forKey:@"lemoOutMode"];
	[objDictionary setObject:[NSNumber numberWithBool:shipEnergyWaveform]			forKey:@"shipEnergyWaveform"];
	[objDictionary setObject:[NSNumber numberWithBool:shipSummedWaveform]			forKey:@"shipSummedWaveform"];
	[objDictionary setObject:[NSNumber numberWithBool:internalExternalTriggersOred]	forKey:@"internalExternalTriggersOred"];
	[objDictionary setObject:[NSNumber numberWithBool:pulseMode]					forKey:@"pulseMode"];
	
	[objDictionary setObject: internalTriggerDelays	forKey:@"internalTriggerDelays"];	
    [objDictionary setObject: energyDecimations	forKey:@"energyDecimations"];	
	[objDictionary setObject:energyTauFactors	forKey:@"energyTauFactors"];
	[objDictionary setObject:energyGapTimes		forKey:@"energyGapTimes"];
	[objDictionary setObject:energyPeakingTimes	forKey:@"energyPeakingTimes"];
	[objDictionary setObject:sampleLengths		forKey:@"sampleLengths"];
	[objDictionary setObject: dacOffsets		forKey:@"dacOffsets"];
    [objDictionary setObject: thresholds		forKey:@"thresholds"];	
    [objDictionary setObject: gateLengths		forKey:@"gateLengths"];	
    [objDictionary setObject: pulseLengths		forKey:@"pulseLengths"];	
    [objDictionary setObject: sumGs				forKey:@"sumGs"];	
    [objDictionary setObject: peakingTimes		forKey:@"peakingTimes"];	
	[objDictionary setObject: triggerGateLengths	forKey:@"triggerGateLengths"];
	[objDictionary setObject: preTriggerDelays		forKey:@"preTriggerDelays"];
	[objDictionary setObject: sampleStartIndexes	forKey:@"sampleStartIndexes"];
    [objDictionary setObject: triggerDecimations	forKey:@"triggerDecimations"];	
	[objDictionary setObject: energyGateLengths		forKey:@"energyGateLengths"];
	
	//firmware 15xx
//	[objDictionary setObject: cfdControls		forKey:@"cfdControls"];	
	[objDictionary setObject: [NSNumber numberWithLong:bufferWrapEnabledMask]		forKey:@"bufferWrapEnabledMask"];
	
    return objDictionary;
}

- (NSArray*) autoTests 
{
	NSMutableArray* myTests = [NSMutableArray array];
	[myTests addObject:[ORVmeReadOnlyTest test:kSIS3305AcquisitionControl wordSize:4 name:@"Acquistion Reg"]];
	[myTests addObject:[ORVmeWriteOnlyTest test:kSIS3305KeyReset wordSize:4 name:@"Reset"]];
	//TO DO.. add more tests
	
//	int i;
//	for(i=0;i<kNumSIS3305Channels;i++){
//		[myTests addObject:[ORVmeReadWriteTest test:[self getThresholdRegOffsets:i] wordSize:4 validMask:0x1ffff name:@"Threshold"]];
//	}
	return myTests;
}

//ORAdcInfoProviding protocol requirement
//- (void) postAdcInfoProvidingValueChanged
//{
//	[[NSNotificationCenter defaultCenter]
//	 postNotificationName:ORAdcInfoProvidingValueChanged
//	 object:self
//	 userInfo: nil];
//}
//for adcProvidingProtocol... but not used for now
- (unsigned long) eventCount:(int)channel
{
	return 0;
}
- (void) clearEventCounts
{
}
- (unsigned long) thresholdForDisplay:(unsigned short) aChan
{
	return [self threshold:aChan];
}
- (unsigned short) gainForDisplay:(unsigned short) aChan
{
	return [self gain:aChan];
}
@end

@implementation ORSIS3305Model (private)
- (NSMutableArray*) arrayOfLength:(int)len
{
	int i;
	NSMutableArray* anArray = [NSMutableArray arrayWithCapacity:kNumSIS3305Channels];
	for(i=0;i<len;i++)[anArray addObject:[NSNumber numberWithInt:0]];
	return anArray;
}

- (void) setUpArrays
{
    /*
        This method allocates memory to these arrays, in case they haven't been allocated yet. 
        Should be called by initWithCoder
     */
	if(!thresholds)				thresholds			  = [[self arrayOfLength:kNumSIS3305Channels] retain];
//	if(!highThresholds)			highThresholds			  = [[self arrayOfLength:kNumSIS3305Channels] retain];
	if(!dacOffsets)				dacOffsets			  = [[self arrayOfLength:kNumSIS3305Channels] retain];
	if(!gateLengths)			gateLengths			  = [[self arrayOfLength:kNumSIS3305Channels] retain];
	if(!pulseLengths)			pulseLengths		  = [[self arrayOfLength:kNumSIS3305Channels] retain];
	if(!sumGs)					sumGs				  = [[self arrayOfLength:kNumSIS3305Channels] retain];
	if(!peakingTimes)			peakingTimes		  = [[self arrayOfLength:kNumSIS3305Channels] retain];
	if(!internalTriggerDelays)	internalTriggerDelays = [[self arrayOfLength:kNumSIS3305Channels] retain];
	if(!energyTauFactors)		energyTauFactors	  = [[self arrayOfLength:kNumSIS3305Channels] retain];
//	if(!cfdControls)			cfdControls		      = [[self arrayOfLength:kNumSIS3305Channels] retain];
	
	if(!sampleLengths)		sampleLengths		= [[self arrayOfLength:kNumSIS3305Groups] retain];
	if(!preTriggerDelays)	preTriggerDelays	= [[self arrayOfLength:kNumSIS3305Groups] retain];
	if(!triggerGateLengths)	triggerGateLengths	= [[self arrayOfLength:kNumSIS3305Groups] retain];
	if(!triggerDecimations)	triggerDecimations	= [[self arrayOfLength:kNumSIS3305Groups] retain];
	if(!energyGateLengths)	energyGateLengths	= [[self arrayOfLength:kNumSIS3305Groups] retain];
	if(!energyPeakingTimes)	energyPeakingTimes	= [[self arrayOfLength:kNumSIS3305Groups] retain];
	if(!energyDecimations)	energyDecimations	= [[self arrayOfLength:kNumSIS3305Groups] retain];
	if(!energyGapTimes)		energyGapTimes		= [[self arrayOfLength:kNumSIS3305Groups] retain];
	if(!sampleStartIndexes)	sampleStartIndexes	= [[self arrayOfLength:kNumSIS3305Groups] retain];
	if(!endAddressThresholds)endAddressThresholds	= [[self arrayOfLength:kNumSIS3305Groups] retain];
	
	if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3305Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
	
}

//- (void) writeDacOffsets
//{
//	
//	unsigned int max_timeout, timeout_cnt;
//	
//	int i;
//	for (i=0;i<kNumSIS3305Channels;i++) {
//		unsigned long data =  [self dacOffset:i];
//		unsigned long addr = [self baseAddress] + kSIS3305DacData  ;
//		
//		// Set the Data in the DAC Register
//		[[self adapter] writeLongBlock:&data
//							 atAddress:addr
//							numToWrite:1
//							withAddMod:addressModifier
//						 usingAddSpace:0x01];
//		
//		
//		data =  1 + (i << 4); // write to DAC Register
//		addr = [self baseAddress] + kSIS3305DacControlStatus  ;
//		// Tell card to set the DAC shift Register
//		[[self adapter] writeLongBlock:&data
//							 atAddress:addr
//							numToWrite:1
//							withAddMod:addressModifier
//						 usingAddSpace:0x01];
//		
//		max_timeout = 5000 ;
//		timeout_cnt = 0 ;
//		addr = [self baseAddress] + kSIS3305DacControlStatus  ;
//		// Wait until done.
//		do {
//			[[self adapter] readLongBlock:&data
//								atAddress:addr
//								numToRead:1
//							   withAddMod:addressModifier
//							usingAddSpace:0x01];
//			
//			timeout_cnt++;
//		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
//		
//		if (timeout_cnt >=  max_timeout) {
//			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
//			return;
//		}
//		
//		[[self adapter] writeLongBlock:&data
//							 atAddress:addr
//							numToWrite:1
//							withAddMod:addressModifier
//						 usingAddSpace:0x01];
//		
//		
//		data =  2 + (i << 4); // Load DACs 
//		addr = [self baseAddress] + kSIS3305DacControlStatus  ;
//		[[self adapter] writeLongBlock:&data
//							 atAddress:addr
//							numToWrite:1
//							withAddMod:addressModifier
//						 usingAddSpace:0x01];
//		
//		timeout_cnt = 0 ;
//		addr = [self baseAddress] + kSIS3305DacControlStatus  ;
//		do {
//			[[self adapter] readLongBlock:&data
//								atAddress:addr
//								numToRead:1
//							   withAddMod:addressModifier
//							usingAddSpace:0x01];
//			timeout_cnt++;
//		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
//		
//		if (timeout_cnt >=  max_timeout) {
//			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
//			return;
//		}
//	}
//}

//- (void) pollMcaStatus
//{
//	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollMcaStatus) object:nil];
//	if([gOrcaGlobals runInProgress]){
//		[self readMcaStatus];
//		[self performSelector:@selector(pollMcaStatus) withObject:self afterDelay:2];
//	}
//}

@end
