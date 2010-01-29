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

#pragma mark ***Imported Files
#import "ORSIS3302Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORVmeTests.h"

NSString* ORSIS3302ModelEnergyGateLengthChanged =		@"ORSIS3302ModelEnergyGateLengthChanged";
NSString* ORSIS3302ModelRunModeChanged					= @"ORSIS3302ModelRunModeChanged";
NSString* ORSIS3302ModelEndAddressThresholdChanged		= @"ORSIS3302ModelEndAddressThresholdChanged";
NSString* ORSIS3302ModelEnergySampleStartIndex3Changed	= @"ORSIS3302ModelEnergySampleStartIndex3Changed";
NSString* ORSIS3302ModelEnergyTauFactorChanged			= @"ORSIS3302ModelEnergyTauFactorChanged";
NSString* ORSIS3302ModelEnergySampleStartIndex2Changed	= @"ORSIS3302ModelEnergySampleStartIndex2Changed";
NSString* ORSIS3302ModelEnergySampleStartIndex1Changed	= @"ORSIS3302ModelEnergySampleStartIndex1Changed";
NSString* ORSIS3302ModelEnergySampleLengthChanged		= @"ORSIS3302ModelEnergySampleLengthChanged";
NSString* ORSIS3302ModelEnergyGapTimeChanged	 = @"ORSIS3302ModelEnergyGapTimeChanged";
NSString* ORSIS3302ModelEnergyPeakingTimeChanged = @"ORSIS3302ModelEnergyPeakingTimeChanged";
NSString* ORSIS3302ModelTriggerGateLengthChanged = @"ORSIS3302ModelTriggerGateLengthChanged";
NSString* ORSIS3302ModelPreTriggerDelayChanged  = @"ORSIS3302ModelPreTriggerDelayChanged";
NSString* ORSIS3302SampleStartIndexChanged		= @"ORSIS3302SampleStartIndexChanged";
NSString* ORSIS3302SampleLengthChanged			= @"ORSIS3302SampleLengthChanged";
NSString* ORSIS3302DacOffsetChanged				= @"ORSIS3302DacOffsetChanged";
NSString* ORSIS3302LemoInModeChanged			= @"ORSIS3302LemoInModeChanged";
NSString* ORSIS3302LemoOutModeChanged			= @"ORSIS3302LemoOutModeChanged";
NSString* ORSIS3302AcqRegEnableMaskChanged		= @"ORSIS3302AcqRegEnableMaskChanged";
NSString* ORSIS3302CSRRegChanged				= @"ORSIS3302CSRRegChanged";
NSString* ORSIS3302AcqRegChanged				= @"ORSIS3302AcqRegChanged";
NSString* ORSIS3302EventConfigChanged			= @"ORSIS3302EventConfigChanged";

NSString* ORSIS3302ClockSourceChanged			= @"ORSIS3302ClockSourceChanged";

NSString* ORSIS3302RateGroupChangedNotification	= @"ORSIS3302RateGroupChangedNotification";
NSString* ORSIS3302SettingsLock					= @"ORSIS3302SettingsLock";

NSString* ORSIS3302EnabledChanged				= @"ORSIS3302EnabledChanged";
NSString* ORSIS3302ThresholdChanged				= @"ORSIS3302ThresholdChanged";
NSString* ORSIS3302ThresholdArrayChanged		= @"ORSIS3302ThresholdArrayChanged";
NSString* ORSIS3302GtChanged					= @"ORSIS3302GtChanged";
NSString* ORSIS3302SampleDone					= @"ORSIS3302SampleDone";
NSString* ORSIS3302IDChanged					= @"ORSIS3302IDChanged";
NSString* ORSIS3302GateLengthChanged			= @"ORSIS3302GateLengthChanged";
NSString* ORSIS3302PulseLengthChanged			= @"ORSIS3302PulseLengthChanged";
NSString* ORSIS3302SumGChanged					= @"ORSIS3302SumGChanged";
NSString* ORSIS3302PeakingTimeChanged			= @"ORSIS3302PeakingTimeChanged";
NSString* ORSIS3302InternalTriggerDelayChanged	= @"ORSIS3302InternalTriggerDelayChanged";
NSString* ORSIS3302TriggerDecimationChanged		= @"ORSIS3302TriggerDecimationChanged";
NSString* ORSIS3302EnergyDecimationChanged		= @"ORSIS3302EnergyDecimationChanged";


@interface ORSIS3302Model (private)
- (void) writeDacOffsets;
- (void) setUpArrays;
@end

@implementation ORSIS3302Model

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x08000000];
    [self initParams];

    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
	[gateLengths release];
	[pulseLengths release];
	[sumGs release];
	[peakingTimes release];
	[internalTriggerDelays release];
	
 	[thresholds release];
	[waveFormRateGroup release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3302Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3302Controller"];
}

- (NSString*) helpURL
{
	return @"VME/SIS330x.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x00780000+0x80000);
}

#pragma mark ***Accessors

- (int) energyGateLength { return energyGateLength; }
- (void) setEnergyGateLength:(int)aEnergyGateLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyGateLength:energyGateLength];
    energyGateLength = aEnergyGateLength;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ModelEnergyGateLengthChanged object:self];
}

- (int) runMode { return runMode; }
- (void) setRunMode:(int)aRunMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunMode:runMode];
    runMode = aRunMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ModelRunModeChanged object:self];
	[self calculateSampleValues];
}

- (int) endAddressThreshold { return endAddressThreshold; }
- (void) setEndAddressThreshold:(int)aEndAddressThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEndAddressThreshold:endAddressThreshold];
    endAddressThreshold = aEndAddressThreshold;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ModelEndAddressThresholdChanged object:self];
}

- (int) energyTauFactor { return energyTauFactor; }
- (void) setEnergyTauFactor:(int)aEnergyTauFactor
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyTauFactor:energyTauFactor];
    energyTauFactor = [self limitIntValue:aEnergyTauFactor min:0 max:0x3f];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ModelEnergyTauFactorChanged object:self];
}

- (int) energySampleStartIndex3 { return energySampleStartIndex3; }
- (void) setEnergySampleStartIndex3:(int)aEnergySampleStartIndex3
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergySampleStartIndex3:energySampleStartIndex3];
    energySampleStartIndex3 = aEnergySampleStartIndex3;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ModelEnergySampleStartIndex3Changed object:self];
}

- (int) energySampleStartIndex2 { return energySampleStartIndex2; }
- (void) setEnergySampleStartIndex2:(int)aEnergySampleStartIndex2
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergySampleStartIndex2:energySampleStartIndex2];
    energySampleStartIndex2 = aEnergySampleStartIndex2;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ModelEnergySampleStartIndex2Changed object:self];
}

- (int) energySampleStartIndex1 { return energySampleStartIndex1; }
- (void) setEnergySampleStartIndex1:(int)aEnergySampleStartIndex1
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergySampleStartIndex1:energySampleStartIndex1];
    energySampleStartIndex1 = aEnergySampleStartIndex1;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ModelEnergySampleStartIndex1Changed object:self];
}

- (int) energySampleLength { return energySampleLength; }
- (void) setEnergySampleLength:(int)aEnergySampleLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergySampleLength:energySampleLength];
    energySampleLength = [self limitIntValue:aEnergySampleLength min:0 max:510] & 0x3fe;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ModelEnergySampleLengthChanged object:self];
	[self calculateSampleValues];
}

- (int) energyGapTime { return energyGapTime; }
- (void) setEnergyGapTime:(int)aEnergyGapTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyGapTime:energyGapTime];
    energyGapTime = [self limitIntValue:aEnergyGapTime min:0 max:0xff];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ModelEnergyGapTimeChanged object:self];
}

- (int) energyPeakingTime { return energyPeakingTime; }
- (void) setEnergyPeakingTime:(int)aEnergyPeakingTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyPeakingTime:energyPeakingTime];
    energyPeakingTime = [self limitIntValue:aEnergyPeakingTime min:0 max:0x3ff];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ModelEnergyPeakingTimeChanged object:self];
}

- (int) triggerGateLength { return triggerGateLength; }
- (void) setTriggerGateLength:(int)aTriggerGateLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerGateLength:triggerGateLength];
    triggerGateLength = [self limitIntValue:aTriggerGateLength min:0 max:65535];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ModelTriggerGateLengthChanged object:self];
}

- (int) preTriggerDelay { return preTriggerDelay; }
- (void) setPreTriggerDelay:(int)aPreTriggerDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPreTriggerDelay:preTriggerDelay];
    preTriggerDelay = [self limitIntValue:aPreTriggerDelay min:0 max:1023];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ModelPreTriggerDelayChanged object:self];
}

- (unsigned short) sampleStartIndex{ return sampleStartIndex; }
- (void) setSampleStartIndex:(unsigned short)aSampleStartIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleStartIndex:sampleStartIndex];
    sampleStartIndex = aSampleStartIndex & 0xfffe;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302SampleStartIndexChanged object:self];
}

- (unsigned short) sampleLength { return sampleLength; }
- (void) setSampleLength:(unsigned short)aSampleLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleLength:sampleLength];
    sampleLength = aSampleLength & 0xfffc;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302SampleLengthChanged object:self];
	[self calculateSampleValues];
}

- (short) lemoInMode { return lemoInMode; }
- (void) setLemoInMode:(short)aLemoInMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoInMode:lemoInMode];
    lemoInMode = aLemoInMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302LemoInModeChanged object:self];
}

- (NSString*) lemoInAssignments
{
	if(runMode != 0){
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302LemoOutModeChanged object:self];
}
- (NSString*) lemoOutAssignments
{
	if(runMode != 0){
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
- (short) acqRegEnableMask { return acqRegEnableMask; }
- (void) setAcqRegEnableMask:(short)aAcqRegEnableMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAcqRegEnableMask:acqRegEnableMask];
    acqRegEnableMask = aAcqRegEnableMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302AcqRegEnableMaskChanged object:self];
}

- (void) setDefaults
{
	int i;
	for(i=0;i<8;i++){
		[self setThreshold:i withValue:0x1300];
		[self setEnabledBit:i withValue:YES];
		[self setPeakingTime:i withValue:150];
		[self setSumG:i withValue:50];
		[self setGateLength:i withValue:256];
		[self setInternalTriggerDelay:i withValue:128];
	}
	
	[self setSampleLength:8*1024];
	[self setSampleStartIndex:0];
	[self setEnergyPeakingTime:150];
	[self setEnergyGapTime:50];
	[self setTriggerDecimation:0];
	[self setEnergyDecimation:0];
	[self setPreTriggerDelay:128];
	[self setTriggerGateLength:256];
	[self setSampleLength:510];
	[self setSampleStartIndex:0];
	[self setGtMask:0xff];
	[self setEnabledMask:0x0];
	
	[self setEnableInternalRouting:YES];
}

- (BOOL) bankFullTo3
{
    return bankFullTo3;
}

- (void) setBankFullTo3:(BOOL)aBankFullTo3
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBankFullTo3:bankFullTo3];
    bankFullTo3 = aBankFullTo3;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302CSRRegChanged object:self];
}

- (BOOL) bankFullTo2
{
    return bankFullTo2;
}

- (void) setBankFullTo2:(BOOL)aBankFullTo2
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBankFullTo2:bankFullTo2];
    bankFullTo2 = aBankFullTo2;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302CSRRegChanged object:self];
}

- (BOOL) bankFullTo1
{
    return bankFullTo1;
}

- (void) setBankFullTo1:(BOOL)aBankFullTo1
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBankFullTo1:bankFullTo1];
    bankFullTo1 = aBankFullTo1;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302CSRRegChanged object:self];
}
- (BOOL) enableInternalRouting
{
    return enableInternalRouting;
}

- (void) setEnableInternalRouting:(BOOL)aEnableInternalRouting
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableInternalRouting:enableInternalRouting];
    enableInternalRouting = aEnableInternalRouting;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302CSRRegChanged object:self];
}

- (BOOL) activateTriggerOnArmed
{
    return activateTriggerOnArmed;
}

- (void) setActivateTriggerOnArmed:(BOOL)aActivateTriggerOnArmed
{
    [[[self undoManager] prepareWithInvocationTarget:self] setActivateTriggerOnArmed:activateTriggerOnArmed];
    activateTriggerOnArmed = aActivateTriggerOnArmed;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302CSRRegChanged object:self];
}

- (BOOL) invertTrigger
{
    return invertTrigger;
}

- (void) setInvertTrigger:(BOOL)aInvertTrigger
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInvertTrigger:invertTrigger];
    invertTrigger = aInvertTrigger;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302CSRRegChanged object:self];
}


- (int) clockSource
{
    return clockSource;
}

- (void) setClockSource:(int)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = aClockSource;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ClockSourceChanged object:self];
}


//Event configuration

- (BOOL) gateChaining
{
    return gateChaining;
}

- (void) setGateChaining:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGateChaining:gateChaining];
    gateChaining = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302EventConfigChanged object:self];
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
	 postNotificationName:ORSIS3302RateGroupChangedNotification
	 object:self];    
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) initParams
{
	[self setUpArrays];
	[self setDefaults];
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
		if(counterTag>=0 && counterTag<kNumSIS3302Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

- (short) enabledMask
{
	return enabledMask;
}

- (BOOL) enabled:(short)chan	
{ 
	return enabledMask & (1<<chan); 
}

- (void) setEnabledMask:(short)aMask	
{ 
	[[[self undoManager] prepareWithInvocationTarget:self] setEnabledMask:enabledMask];
	enabledMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302EnabledChanged object:self];
}

- (void) setEnabledBit:(short)chan withValue:(BOOL)aValue		
{ 
	unsigned char aMask = enabledMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setEnabledMask:aMask];
}

- (short) gtMask
{
	return gtMask;
}

- (BOOL) gt:(short)chan	
{ 
	return gtMask & (1<<chan); 
}

- (void) setGtMask:(long)aMask	
{ 
	[[[self undoManager] prepareWithInvocationTarget:self] setGtMask:gtMask];
	gtMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GtChanged object:self];
}

- (void) setGtBit:(short)chan withValue:(BOOL)aValue		
{ 
	unsigned char aMask = gtMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setGtMask:aMask];
}

- (int) limitIntValue:(int)aValue min:(int)aMin max:(int)aMax
{
	if(aValue<aMin)return aMin;
	else if(aValue>aMax)return aMax;
	else return aValue;
}

- (int) threshold:(short)aChan { return [[thresholds objectAtIndex:aChan]intValue]; }
- (void) setThreshold:(short)aChan withValue:(int)aValue 
{ 
	aValue = [self limitIntValue:aValue min:0 max:0x1FFFF];
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302ThresholdChanged object:self];
}

- (unsigned short) dacOffset:(short)aChan { return [[dacOffsets objectAtIndex:aChan]intValue]; }
- (void) setDacOffset:(short)aChan withValue:(int)aValue 
{
	aValue = [self limitIntValue:aValue min:0 max:0xffff];
    [[[self undoManager] prepareWithInvocationTarget:self] setDacOffset:aChan withValue:[self dacOffset:aChan]];
    [dacOffsets replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302DacOffsetChanged object:self];
}

- (short) gateLength:(short)aChan { return [[gateLengths objectAtIndex:aChan] shortValue]; }
- (void) setGateLength:(short)aChan withValue:(short)aValue 
{ 
	aValue = [self limitIntValue:aValue min:0 max:0x3f];
    [[[self undoManager] prepareWithInvocationTarget:self] setGateLength:aChan withValue:[self gateLength:aChan]];
    [gateLengths replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GateLengthChanged object:self];
}

- (short) pulseLength:(short)aChan { return [[pulseLengths objectAtIndex:aChan] shortValue]; }
- (void) setPulseLength:(short)aChan withValue:(short)aValue 
{ 
	aValue = [self limitIntValue:aValue min:0 max:0xff];
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseLength:aChan withValue:[self pulseLength:aChan]];
    [pulseLengths replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302PulseLengthChanged object:self];
}

- (short) sumG:(short)aChan { return [[sumGs objectAtIndex:aChan] shortValue]; }
- (void) setSumG:(short)aChan withValue:(short)aValue 
{ 
	aValue = [self limitIntValue:aValue min:0 max:0x3ff];
    [[[self undoManager] prepareWithInvocationTarget:self] setSumG:aChan withValue:[self sumG:aChan]];
    [sumGs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302SumGChanged object:self];
}

- (short) peakingTime:(short)aChan { return [[peakingTimes objectAtIndex:aChan] shortValue]; }
- (void) setPeakingTime:(short)aChan withValue:(short)aValue 
{ 
	aValue = [self limitIntValue:aValue min:0 max:0x3ff];
    [[[self undoManager] prepareWithInvocationTarget:self] setPeakingTime:aChan withValue:[self peakingTime:aChan]];
    [peakingTimes replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302PeakingTimeChanged object:self];
}


- (short) internalTriggerDelay:(short)aChan { return [[internalTriggerDelays objectAtIndex:aChan] shortValue]; }
- (void) setInternalTriggerDelay:(short)aChan withValue:(short)aValue 
{ 
	aValue = [self limitIntValue:aValue min:0 max:0x1f];
    [[[self undoManager] prepareWithInvocationTarget:self] setInternalTriggerDelay:aChan withValue:[self internalTriggerDelay:aChan]];
    [internalTriggerDelays replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302InternalTriggerDelayChanged object:self];
}

- (short) energyDecimation { return energyDecimation; }
- (void) setEnergyDecimation:(short)aValue 
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyDecimation:energyDecimation];
    energyDecimation = [self limitIntValue:aValue min:0 max:0x3];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302EnergyDecimationChanged object:self];
}

- (short) triggerDecimation { return triggerDecimation; }
- (void) setTriggerDecimation:(short)aValue 
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerDecimation:triggerDecimation];
    triggerDecimation = [self limitIntValue:aValue min:0 max:0x3];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302TriggerDecimationChanged object:self];
}

- (void) calculateSampleValues
{
	if(runMode      == 0)   return;
	if(runMode      == 1)	numEnergyValues = 510;					//Energy Trapezoidal 510 values + Max and Min
	else if(runMode == 2)   numEnergyValues = 0;					//No Energy
	else if(runMode == 3)   numEnergyValues = 3*energySampleLength;	//3 parts of Energy Trapezoidal (3x170 = 510 values) + Max/Min
	else if(runMode == 4)	numEnergyValues = energySampleLength;   //valid only if only one start address is defined

	if(numEnergyValues > 510){
		NSLogColor([NSColor redColor],@"Number of energy values is to high (max = 510) ; actual = %d \n",numEnergyValues);
		NSLogColor([NSColor redColor],@"Value forced to 510\n");
		numEnergyValues = 510;
	}

	numRawDataLongWords = ([self sampleLength]>>1);
	rawDataIndex  = 2 ;
	
	energyIndex    = 2 + numRawDataLongWords ;
	energyMaxIndex = 2 + numEnergyValues + numRawDataLongWords ;
	
	eventLengthLongWords = 2 + 4  ; // Timestamp/Header, MAX, MIN, Trigger-FLags, Trailer
	eventLengthLongWords = eventLengthLongWords + numRawDataLongWords  ;  
	eventLengthLongWords = eventLengthLongWords + numEnergyValues  ;   

    [self setEndAddressThreshold:eventLengthLongWords];
}

#pragma mark •••Hardware Access
- (void) readModuleID:(BOOL)verbose
{	
	unsigned long result = 0;
	[[self adapter] readLongBlock:&result
                         atAddress:[self baseAddress] + kSIS3302ModID
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	unsigned long moduleID = result >> 16;
	unsigned short majorRev = (result >> 8) & 0xff;
	unsigned short minorRev = result & 0xff;
	if(verbose)NSLog(@"SIS3302 ID: %x  Firmware:%x.%x\n",moduleID,majorRev,minorRev);
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302IDChanged object:self];
}

- (void) writeAcquistionRegister
{
	// The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.	
	unsigned long aMask = 0x0;
	BOOL mcaMode = (runMode == 0);
	aMask |= ((clockSource & 0x7)<< 12);
	aMask |= acqRegEnableMask;
	aMask |= (lemoOutMode & 0x3) << 4;
	aMask |= (mcaMode&0x1)       << 3;
	aMask |= (lemoInMode & 0x7)  << 0;
	
	//put the inverse in the top bits to turn off everything else
	aMask = ((~aMask & 0x0000ffff)<<16) | aMask;
	
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kSIS3302AcquisitionControl
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) setLed:(BOOL)state
{
	unsigned long aValue = CSRMask(state,kSISLed);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3302ControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) forceTrigger
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3302KeyTrigger
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) clearTimeStamp
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3302KeyTimestampClear
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (int) dataWord:(int)chan index:(int)index
{
	if([self enabled:chan]){	
		unsigned long dataMask = 0x3fff;
		unsigned long theValue = dataWord[chan/2][index];
		if((chan%2)==0)	return (theValue>>16) & dataMask; 
		else			return theValue & dataMask; 
	}
	else return 0;
}

- (unsigned long) acqReg
{
 	unsigned long aValue = 0;
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] + kSIS3302AcquisitionControl
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	return aValue;
}

- (void) writeThresholds
{   
	int i;
	unsigned long thresholdMask;
	for(i = 0; i < 8; i++) {
		thresholdMask = 0;
		BOOL enabled   = [self enabled:i];
		BOOL gtEnabled = [self gt:i];
		if(!enabled)	thresholdMask |= (1<<26); //logic is inverted on the hw
		if(gtEnabled)	thresholdMask |= (1<<25);
		thresholdMask |= (0x00010000 | [self threshold:i]);
		
		[[self adapter] writeLongBlock:&thresholdMask
							 atAddress:[self baseAddress] + [self getThresholdRegOffsets:i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (void) writeEventConfiguration
{
	//temp hard coded value.........
	long i;
	for(i=0;i<4;i++){
		// Only the ADCx internal enable bit.
		unsigned long aValueMask = ((i+1)<<19) | 0x00000404;
		[[self adapter] writeLongBlock:&aValueMask
							 atAddress:[self baseAddress] + [self getEventConfigAdcOffsets:i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
	
}

- (void) writePreTriggerDelayAndTriggerGateDelay
{
	unsigned long aValue = (([self preTriggerDelay]&0x01ff)<<16) | [self triggerGateLength];
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSIS3302PretriggerDelayTriggerGateLengthAllAdc
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
}

- (void) writeEnergyGP
{
	unsigned long peakingTimeHi = ([self energyPeakingTime] >> 8) & 0x3;
	unsigned long peakingTimeLo = [self energyPeakingTime] & 0xff; 
	
	unsigned long aValueMask = (([self energyDecimation]  & 0x3)<<28) | 
								(peakingTimeHi <<16)				   | 
								(([self energyGapTime]     & 0xff)<<8) | 
								peakingTimeLo;
	
	[[self adapter] writeLongBlock:&aValueMask
						 atAddress:[self baseAddress] + kSIS3302EnergySetupGPAllAdc
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	[self resetSamplingLogic];
}

- (void) writeEndAddressThreshold
{
	unsigned long aValue = 0x1c0;//endAddressThreshold;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSIS3302EndAddressThresholdAllAdc
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) writeEnergyGateLength
{
	unsigned long aValue = energyGateLength;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSIS3302EnergyGateLengthAllAdc
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) writeEnergyTauFactor
{
	unsigned long 	aValue = energyTauFactor;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSIS3302EnergyTauFactorAdc1357
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSIS3302EnergyTauFactorAdc2468
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) writeEnergySampleLength
{
	unsigned long aValue = energySampleLength;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSIS3302EnergySampleLengthAllAdc
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) writeEnergySampleStartIndexes
{	
	unsigned long aValue = energySampleStartIndex1;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSIS3302EnergySampleStartIndex1AllAdc
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	aValue = energySampleStartIndex2;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSIS3302EnergySampleStartIndex2AllAdc
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	aValue = energySampleStartIndex3;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSIS3302EnergySampleStartIndex3AllAdc
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
}
	
- (void) writeTriggerSetups
{
	int i;
	for(i = 0; i < 8; i++) {
		unsigned long aExtValueMask = (([self internalTriggerDelay:i] & 0x00ffL) << 24) | 
									  (([self triggerDecimation]      & 0x0003L) << 16) | 
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
	unsigned long aValueMask = ((sampleLength & 0xfffc)<<16) | (sampleStartIndex & 0xfffe);
	
	[[self adapter] writeLongBlock:&aValueMask
						 atAddress:[self baseAddress] + kSIS3302RawDataBufferConfigAllAdc
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
}

- (void) readThresholds:(BOOL)verbose
{   
	int i;
	if(verbose) NSLog(@"Reading Thresholds:\n");
	
	for(i =0; i < kNumSIS3302Channels; i++) {
		unsigned long aValue;
		[[self adapter] readLongBlock: &aValue
							atAddress: [self baseAddress] + [self getThresholdRegOffsets:i]
							numToRead: 1
						   withAddMod: [self addressModifier]
						usingAddSpace: 0x01];
		
		if(verbose){
			unsigned short thresh = (aValue&0xffff);
			BOOL triggerDisabled  = (aValue>>26) & 0x1;
			BOOL triggerModeGT    = (aValue>>25) & 0x1;
			NSLog(@"%d: %8s %2s 0x%4x\n",i, triggerDisabled ? "Disabled": "Enabled",  triggerModeGT?"GT":"  " ,thresh);
		}
	}
}

- (void) report
{
	[self readThresholds:YES];
}

- (void) initBoard
{  
	[self reset];							//reset the card
	[self writeAcquistionRegister];			//set up the Acquisition Register
	[self writeEventConfiguration];
	[self writeEndAddressThreshold];
	[self writePreTriggerDelayAndTriggerGateDelay];
	[self writeEnergyGateLength];
	[self writeEnergyGP];
	[self writeEnergyTauFactor];
	[self writeRawDataBufferConfiguration];
	[self writeEnergySampleLength];
	[self writeEnergySampleStartIndexes];
	[self writeTriggerSetups];
	[self writeThresholds];
	[self writeDacOffsets];
	[self resetSamplingLogic];
}

- (unsigned long) getPreviousBankSampleRegisterOffset:(int) channel 
{
    switch (channel) {
        case 0: return 0x02000018;
        case 1: return 0x0200001c;
        case 2: return 0x02800018;
        case 3: return 0x0280001c;
        case 4: return 0x03000018;
        case 5: return 0x0300001c;
        case 6: return 0x03800018;
        case 7: return 0x0380001c;
    }
    return (unsigned long)-1;
}

- (unsigned long) getADCBufferRegisterOffset:(int) channel 
{
    switch (channel) {
        case 0: return kSIS3302Adc1Offset;
        case 1: return kSIS3302Adc2Offset;
        case 2: return kSIS3302Adc3Offset;
        case 3: return kSIS3302Adc4Offset;
        case 4: return kSIS3302Adc5Offset;
        case 5: return kSIS3302Adc6Offset;
        case 6: return kSIS3302Adc7Offset;
        case 7: return kSIS3302Adc8Offset;
    }
    return (unsigned long) -1;
}

#pragma mark •••Static Declarations
- (unsigned long) getThresholdRegOffsets:(int) channel 
{
    switch (channel) {
        case 0: return 	kSIS3302TriggerThresholdAdc1;
		case 1: return 	kSIS3302TriggerThresholdAdc2;
		case 2: return 	kSIS3302TriggerThresholdAdc3;
		case 3: return 	kSIS3302TriggerThresholdAdc4;
		case 4:	return 	kSIS3302TriggerThresholdAdc5;
		case 5: return 	kSIS3302TriggerThresholdAdc6;
		case 6: return 	kSIS3302TriggerThresholdAdc7;
		case 7: return 	kSIS3302TriggerThresholdAdc8;
    }
    return (unsigned long) -1;
}

- (unsigned long) getTriggerSetupRegOffsets:(int) channel 
{
    switch (channel) {
		case 0: return 	kSIS3302TriggerSetupAdc1;
		case 1: return 	kSIS3302TriggerSetupAdc2;
		case 2: return 	kSIS3302TriggerSetupAdc3;
		case 3: return 	kSIS3302TriggerSetupAdc4;
		case 4: return 	kSIS3302TriggerSetupAdc5;
		case 5: return 	kSIS3302TriggerSetupAdc6;
		case 6: return 	kSIS3302TriggerSetupAdc7;
		case 7: return 	kSIS3302TriggerSetupAdc8;
    }
    return (unsigned long) -1;
}

- (unsigned long) getTriggerExtSetupRegOffsets:(int)channel
{
    switch (channel) {	
		case 0: return 	kSIS3302TriggerExtendedSetupAdc1;
		case 1: return 	kSIS3302TriggerExtendedSetupAdc2;
		case 2: return 	kSIS3302TriggerExtendedSetupAdc3;
		case 3: return 	kSIS3302TriggerExtendedSetupAdc4;
		case 4: return 	kSIS3302TriggerExtendedSetupAdc5;
		case 5: return 	kSIS3302TriggerExtendedSetupAdc6;
		case 6: return 	kSIS3302TriggerExtendedSetupAdc7;
		case 7: return 	kSIS3302TriggerExtendedSetupAdc8;
	}
    return (unsigned long) -1;	
}


- (unsigned long) getEndThresholdRegOffsets:(int)group
{
	switch (group) {	
		case 0: return 	 kSIS3302EndAddressThresholdAdc12;
		case 1: return 	 kSIS3302EndAddressThresholdAdc34;
		case 2: return 	 kSIS3302EndAddressThresholdAdc56;
		case 3: return 	 kSIS3302EndAddressThresholdAdc78;
	}
	return (unsigned long) -1;	 
}
 
- (unsigned long) getSampleAddress:(int)channel
{
    switch (channel) {
		case 0: return 	kSIS3302ActualSampleAddressAdc1;
		case 1: return 	kSIS3302ActualSampleAddressAdc2;
		case 2: return 	kSIS3302ActualSampleAddressAdc3;
		case 3: return 	kSIS3302ActualSampleAddressAdc4;
		case 4: return 	kSIS3302ActualSampleAddressAdc5;
		case 5: return 	kSIS3302ActualSampleAddressAdc6;
		case 6: return 	kSIS3302ActualSampleAddressAdc7;
		case 7: return 	kSIS3302ActualSampleAddressAdc8;
 	}
	return (unsigned long) -1;	 
}
		 
- (unsigned long) getEventConfigAdcOffsets:(int)group
{
	 switch (group) {
		 case 0: return kSIS3302EventConfigAdc12;
		 case 1: return kSIS3302EventConfigAdc34;
		 case 2: return kSIS3302EventConfigAdc56;
		 case 3: return kSIS3302EventConfigAdc78;
	 }
	return (unsigned long) -1;	 
}
		 
- (unsigned long) getAdcMemory:(int)channel
{
    switch (channel) {			
		case 0: return 	kSIS3302Adc1Offset;
		case 1: return 	kSIS3302Adc2Offset;
		case 2: return 	kSIS3302Adc3Offset;
		case 3: return 	kSIS3302Adc4Offset;
		case 4: return 	kSIS3302Adc5Offset;
		case 5: return 	kSIS3302Adc6Offset;
		case 6: return 	kSIS3302Adc7Offset;
		case 7: return 	kSIS3302Adc8Offset;
 	}
   return (unsigned long) -1;	 
}

- (BOOL) isEvent
{
	unsigned long data_rd = 0;
	[[self adapter] readLongBlock:&data_rd
						atAddress:[self baseAddress] + kSIS3302AcquisitionControl
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];

	if ((data_rd & 0x80000) != 0x80000)return NO;
	else return YES;
}

- (void) readOutEvents 
{
	// Try disarm current bank and arm the next one
	[self disarmAndArmBank:0];
	
	if(![self isEvent]) return;
	
 	NSLog(@"****Event\n");
	[self disarmSampleLogic];
	
    // Try disarm current bank and arm the next one
    //[self disarmAndArmNextBank];
	
	if(bankOneArmed)[self writePageRegister:0x0];
	else			[self writePageRegister:0x4];
	
    // We've selected a particular page to readout for each channel
	int i = 0;
    for( i=0;i<kNumSIS3302Channels;i++) {
        [self readOutChannel:i];
    }
}

- (void) readOutChannel:(int) channel
{
	unsigned long endSampleAddress = 0;
	[[self adapter] readLongBlock:&endSampleAddress
						atAddress:[self baseAddress] +  [self getPreviousBankSampleRegisterOffset:channel]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
    endSampleAddress &= 0xffffff ; // mask bank2 address bit (bit 24)
	
    if (endSampleAddress > 0x3fffff) {   // more than 1 page memory buffer is used
        // Warning?
    }
	
    // readout	   	
    if (endSampleAddress != 0) {
		NSLog(@"************Channel %d\n",channel);
		NSLog(@"end_sample_address: 0x%08x\n",endSampleAddress);
		
		//check a bunch of addresses -- not sure which one is relevent
		unsigned long EventConfig = 0;
		[[self adapter] readLongBlock:&EventConfig
							atAddress:[self baseAddress] +kSIS3302EventConfigAdc12
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		NSLog(@"EventConfig: 0x%08x\n",EventConfig);
		
		
		unsigned long pretrigger = 0;
		[[self adapter] readLongBlock:&pretrigger
							atAddress:[self baseAddress] + kSIS3302PreTriggerDelayTriggerGateLengthAdc12
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		
		NSLog(@"pretrigger: 0x%08x\n",pretrigger);
		
		unsigned long rawDataBufferConfig = 0;
		[[self adapter] readLongBlock:&rawDataBufferConfig
							atAddress:[self baseAddress] + kSIS3302RawDataBufferConfigAdc12
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		
		NSLog(@"rawDataBufferConfig: 0x%08x\n",rawDataBufferConfig);
		
		unsigned long actualNextSampleAddress1 = 0;
		[[self adapter] readLongBlock:&actualNextSampleAddress1
							atAddress:[self baseAddress] + kSIS3302ActualSampleAddressAdc1
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		
		NSLog(@"actualNextSampleAddress1: 0x%08x\n",actualNextSampleAddress1);
		
		unsigned long actualNextSampleAddress2 = 0;
		[[self adapter] readLongBlock:&actualNextSampleAddress2
							atAddress:[self baseAddress] + kSIS3302ActualSampleAddressAdc2
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		
		NSLog(@"actualNextSampleAddress2: 0x%08x\n",actualNextSampleAddress2);
		
		unsigned long prevNextSampleAddress1 = 0;
		[[self adapter] readLongBlock:&prevNextSampleAddress1
							atAddress:[self baseAddress] + kSIS3302PreviousBankSampleAddressAdc1
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		
		NSLog(@"prevNextSampleAddress1: 0x%08x\n",prevNextSampleAddress1);
		
		unsigned long prevNextSampleAddress2 = 0;
		[[self adapter] readLongBlock:&prevNextSampleAddress2
							atAddress:[self baseAddress] + kSIS3302PreviousBankSampleAddressAdc2
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		
		NSLog(@"prevNextSampleAddress2: 0x%08x\n",prevNextSampleAddress2);
		
		unsigned long triggerSetup1 = 0;
		[[self adapter] readLongBlock:&triggerSetup1
							atAddress:[self baseAddress] + kSIS3302TriggerSetupAdc1
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		
		NSLog(@"triggerSetup1: 0x%08x\n",triggerSetup1);
		
		unsigned long triggerSetup2 = 0;
		[[self adapter] readLongBlock:&triggerSetup2
							atAddress:[self baseAddress] + kSIS3302TriggerSetupAdc2
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		
		NSLog(@"triggerSetup2: 0x%08x\n",triggerSetup2);
		
		unsigned long energySetupGP = 0;
		[[self adapter] readLongBlock:&energySetupGP
							atAddress:[self baseAddress] + kSIS3302EnergySetupGPAdc12
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		
		NSLog(@"energySetupGP: 0x%08x\n",energySetupGP);
		
		unsigned long EnergyGateLen = 0;
		[[self adapter] readLongBlock:&EnergyGateLen
							atAddress:[self baseAddress] + kSIS3302EnergyGateLengthAdc12
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		
		NSLog(@"EnergyGateLen: 0x%08x\n",EnergyGateLen);
		
		unsigned long EnergySampleLen = 0;
		[[self adapter] readLongBlock:&EnergySampleLen
							atAddress:[self baseAddress] + kSIS3302EnergySampleLengthAdc12
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		
		NSLog(@"EnergySampleLen: 0x%08x\n",EnergySampleLen);
		
		unsigned long EnergySampleStartIndex = 0;
		[[self adapter] readLongBlock:&EnergySampleStartIndex
							atAddress:[self baseAddress] + kSIS3302EnergySampleStartIndex1Adc12
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		
		NSLog(@"EnergySampleStartIndex: 0x%08x\n",EnergySampleStartIndex);
		
		
		
		// check if bank address flag is valid
		if (((endSampleAddress >> 24) & 0x1) != ((bankOneArmed) ? 0x1 : 0x0) ) {   
			// in this case -> poll right arm flag or implement a delay
		}
		
		endSampleAddress = endSampleAddress & 0xffffff;
		
		
		unsigned int  uint_max_event_use , uint_max_event_saved ;
		unsigned int gl_uint_CountOfNotProcessedTriggerCount;
		// check buffer address
		if (endSampleAddress > 0x3fffff) {   // more than 1 page memory buffer is used
			uint_max_event_saved =  endSampleAddress / eventLengthLongWords ;
			
			endSampleAddress = 2 * (1 * eventLengthLongWords) ; // max 8Mbyte (inside one page) **only one event in this test code
			uint_max_event_use =  endSampleAddress / eventLengthLongWords ;
			gl_uint_CountOfNotProcessedTriggerCount = gl_uint_CountOfNotProcessedTriggerCount + (uint_max_event_saved - uint_max_event_use) ;
		}
		
		unsigned long numToRead = (endSampleAddress & 0x3ffffc)/2;
		NSLog(@"channel %d should read %d longs\n",channel,numToRead);
		int n;
		int c = 0;
		/*
		for(n=0;n<numToRead;n+=4){
			unsigned long adc_Memory1 = 0;
			
			//****TO DO read block....
			[[self adapter] readLongBlock:&adc_Memory1
								atAddress:[self baseAddress] + [self getADCBufferRegisterOffset:channel] + n
								numToRead:1
							   withAddMod: [self addressModifier]
							usingAddSpace:0x01];
			//NSLog(@"%d: 0x%08x\n",n,adc_Memory1);
			//NSLog(@"%d: %d\n",n,adc_Memory1&0xffff);
			if(adc_Memory1 == 0xdeadbeef){
				NSLog(@"%d: 0x%08x\n",n,adc_Memory1);
				c++;
				if(c>2)break;
			}
			//int32_t error = DMARead(addr, (uint32_t)0x08, 
			//						(uint32_t)8, buffer,  
			//						num_bytes_to_read);
		}*/
	}
	
}

- (void) disarmSampleLogic
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSIS3302KeyDisarm
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) disarmAndArmBank:(int) bank 
{
    if (bank==0) bankOneArmed = YES;
    else		 bankOneArmed = NO;
	
    unsigned long addr = [self baseAddress] + ((bank == 0) ? kSIS3302KeyDisarmAndArmBank1 : kSIS3302KeyDisarmAndArmBank2);
	unsigned long aValue= 0;
	[[self adapter] writeLongBlock:&aValue
						atAddress:addr
						numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];	
}

- (void) disarmAndArmNextBank
{ 
	return (bankOneArmed) ? [self disarmAndArmBank:0] : [self disarmAndArmBank:1]; 
}

- (void) writePageRegister:(int) aPage 
{	
	unsigned long aValue = aPage & 0xf;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSIS3302AdcMemoryPageRegister
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];	
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
								 @"ORSIS3302WaveformDecoder",            @"decoder",
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
    return kNumSIS3302Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    		
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
    [p setName:@"P Bit"];
    [p setFormat:@"##0" upperLimit:0x3ff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPeakingTime:withValue:) getMethod:@selector(peakingTime:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Peaking Times"];
    [p setFormat:@"##0" upperLimit:0x3ff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPeakingTime:withValue:) getMethod:@selector(peakingTime:)];
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
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORSIS3302Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORSIS3302Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:@"Threshold"])return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"GateLength"])return [[cardDictionary objectForKey:@"gateLengths"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"PulseLength"])return [[cardDictionary objectForKey:@"pulseLengths"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"SumG"])return [[cardDictionary objectForKey:@"sumGs"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"PeakingTime"])return [[cardDictionary objectForKey:@"peakingTime"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"InternalTriggerDelay"])return [[cardDictionary objectForKey:@"internalTriggerDelay"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"TriggerDecimation"])return [cardDictionary objectForKey:@"triggerDecimation"];
	else if([param isEqualToString:@"EnergyDecimation"])return [cardDictionary objectForKey:@"energyDecimation"];
    else if([param isEqualToString:@"Enabled"]) return [cardDictionary objectForKey:@"enabledMask"];
    else if([param isEqualToString:@"Clock Source"]) return [cardDictionary objectForKey:@"clockSource"];
    else return nil;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3302"];    
    
    //cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
    
    [self startRates];
	[self reset];
    [self initBoard];
		
	currentBank = 0;
	//[self clearBankFullFlag:currentBank];
	//[self arm:currentBank];
	//[self startSampling];
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
    @try {
		isRunning = YES;
		
/*		unsigned long data_rd;
		[[self adapter] readLongBlock:&data_rd
							atAddress:[self baseAddress] + kSIS3302AcquistionControl
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		if((data_rd & 0x80000) == 0x80000){	
		}
 */
		sleep(1);
		unsigned long dataValue;
		[[self adapter] readLongBlock:&dataValue
							atAddress:[self baseAddress] + 0x02000020
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];	
		NSLog(@"%d %d\n",(dataValue&0xffff0000)>>16,dataValue&0xFFFF);
	}
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	//[self stopSampling];
	//[self stopBankSwitching];
    isRunning = NO;
    [waveFormRateGroup stop];
	[self setLed:NO];
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kSIS3302; //should be unique
	configStruct->card_info[index].hw_mask[0]				= dataId; //better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= [self addressModifier];
	configStruct->card_info[index].base_add					= [self baseAddress];
    //configStruct->card_info[index].deviceSpecificData[1]	= [self numberOfSamples];
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

- (void) reset
{
 	unsigned long aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3302KeyReset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) resetSamplingLogic
{
 	unsigned long aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3302KeySampleLogicReset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

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
    for(i=0;i<kNumSIS3302Channels;i++){
        waveFormCount[i]=0;
    }
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	
    [self setEnergyGateLength:			[decoder decodeIntForKey:@"energyGateLength"]];
    [self setRunMode:					[decoder decodeIntForKey:@"runMode"]];
    [self setEndAddressThreshold:		[decoder decodeIntForKey:@"endAddressThreshold"]];
    [self setEnergySampleStartIndex3:	[decoder decodeIntForKey:@"energySampleStartIndex3"]];
    [self setEnergyTauFactor:			[decoder decodeIntForKey:@"energyTauFactor"]];
    [self setEnergySampleStartIndex2:	[decoder decodeIntForKey:@"energySampleStartIndex2"]];
    [self setEnergySampleStartIndex1:	[decoder decodeIntForKey:@"energySampleStartIndex1"]];
    [self setEnergySampleLength:		[decoder decodeIntForKey:@"energySampleLength"]];
	[self setEnergyGapTime:			[decoder decodeIntForKey:@"energyGapTime"]];
    [self setEnergyPeakingTime:		[decoder decodeIntForKey:@"energyPeakingTime"]];
    [self setTriggerGateLength:		[decoder decodeIntForKey:@"triggerGateLength"]];
    [self setPreTriggerDelay:		[decoder decodeIntForKey:@"preTriggerDelay"]];
    [self setSampleStartIndex:		[decoder decodeIntForKey:@"sampleStartIndex"]];
    [self setSampleLength:			[decoder decodeIntForKey:@"sampleLength"]];
    [self setLemoInMode:			[decoder decodeIntForKey:@"lemoInMode"]];
    [self setLemoOutMode:			[decoder decodeIntForKey:@"lemoOutMode"]];
    [self setAcqRegEnableMask:		[decoder decodeIntForKey:@"acqRegEnableMask"]];
	thresholds  =					[[decoder decodeObjectForKey:@"thresholds"] retain];
    dacOffsets  =				    [[decoder decodeObjectForKey:@"dacOffsets"] retain];
	gateLengths =					[[decoder decodeObjectForKey:@"gateLengths"] retain];
	pulseLengths =					[[decoder decodeObjectForKey:@"pulseLengths"] retain];
	sumGs =							[[decoder decodeObjectForKey:@"sumGs"] retain];
	peakingTimes =					[[decoder decodeObjectForKey:@"peakingTime"] retain];
	internalTriggerDelays =			[[decoder decodeObjectForKey:@"internalTriggerDelays"] retain];
	triggerDecimation =			    [decoder decodeIntForKey:   @"triggerDecimation"];
	energyDecimation =			    [decoder decodeIntForKey:   @"energyDecimation"];

	//csr
	[self setBankFullTo3:			[decoder decodeBoolForKey:@"bankFullTo3"]];
    [self setBankFullTo2:			[decoder decodeBoolForKey:@"bankFullTo2"]];
    [self setBankFullTo1:			[decoder decodeBoolForKey:@"bankFullTo1"]];
	[self setEnableInternalRouting:	[decoder decodeBoolForKey:@"enableInternalRouting"]];
    [self setActivateTriggerOnArmed:[decoder decodeBoolForKey:@"activateTriggerOnArmed"]];
    [self setInvertTrigger:			[decoder decodeBoolForKey:@"invertTrigger"]];
	
    [self setClockSource:			[decoder decodeIntForKey:@"clockSource"]];
    [self setEnabledMask:			[decoder decodeInt32ForKey:@"enabledMask"]];
	[self setGtMask:				[decoder decodeIntForKey:@"gtMask"]];
		
    [self setWaveFormRateGroup:[decoder decodeObjectForKey:@"waveFormRateGroup"]];

    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3302Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	[self setUpArrays];

	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
	[encoder encodeInt:energyGateLength			forKey:@"energyGateLength"];
	[encoder encodeInt:runMode					forKey:@"runMode"];
	[encoder encodeInt:endAddressThreshold		forKey:@"endAddressThreshold"];
	[encoder encodeInt:energySampleStartIndex3	forKey:@"energySampleStartIndex3"];
	[encoder encodeInt:energyTauFactor			forKey:@"energyTauFactor"];
	[encoder encodeInt:energySampleStartIndex2	forKey:@"energySampleStartIndex2"];
	[encoder encodeInt:energySampleStartIndex1	forKey:@"energySampleStartIndex1"];
	[encoder encodeInt:energySampleLength		forKey:@"energySampleLength"];
	[encoder encodeInt:energyGapTime			forKey:@"energyGapTime"];
	[encoder encodeInt:energyPeakingTime		forKey:@"energyPeakingTime"];
	[encoder encodeInt:triggerGateLength		forKey:@"triggerGateLength"];
	[encoder encodeInt:preTriggerDelay			forKey:@"preTriggerDelay"];
	[encoder encodeInt:sampleStartIndex			forKey:@"sampleStartIndex"];
	[encoder encodeInt:sampleLength				forKey:@"sampleLength"];
	[encoder encodeInt:lemoInMode				forKey:@"lemoInMode"];
	[encoder encodeInt:lemoOutMode				forKey:@"lemoOutMode"];
	[encoder encodeInt:acqRegEnableMask			forKey:@"acqRegEnableMask"];
	[encoder encodeObject:thresholds			forKey:@"thresholds"];
	[encoder encodeObject:dacOffsets			forKey:@"dacOffsets"];
	[encoder encodeObject:gateLengths			forKey:@"gateLengths"];
	[encoder encodeObject:pulseLengths			forKey:@"pulseLengths"];
	[encoder encodeObject:sumGs					forKey:@"sumGs"];
	[encoder encodeObject:peakingTimes			forKey:@"peakingTimes"];
	[encoder encodeObject:internalTriggerDelays	forKey:@"internalTriggerDelays"];
	[encoder encodeInt:triggerDecimation		forKey:@"triggerDecimation"];
	[encoder encodeInt:energyDecimation			forKey:@"energyDecimation"];

	//csr
    [encoder encodeBool:bankFullTo3				forKey:@"bankFullTo3"];
    [encoder encodeBool:bankFullTo2				forKey:@"bankFullTo2"];
    [encoder encodeBool:bankFullTo1				forKey:@"bankFullTo1"];
    [encoder encodeBool:enableInternalRouting	forKey:@"enableInternalRouting"];
    [encoder encodeBool:activateTriggerOnArmed	forKey:@"activateTriggerOnArmed"];
    [encoder encodeBool:invertTrigger			forKey:@"invertTrigger"];

    [encoder encodeInt:clockSource				forKey:@"clockSource"];
	[encoder encodeInt32:enabledMask			forKey:@"enabledMask"];
    [encoder encodeInt:gtMask					forKey:@"gtMask"];
	
    [encoder encodeObject:waveFormRateGroup forKey:@"waveFormRateGroup"];
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	//csr
	[objDictionary setObject: [NSNumber numberWithBool:bankFullTo3]			  forKey:@"bankFullTo3"];
	[objDictionary setObject: [NSNumber numberWithBool:bankFullTo2]			  forKey:@"bankFullTo2"];
	[objDictionary setObject: [NSNumber numberWithBool:bankFullTo1]			  forKey:@"bankFullTo1"];
	[objDictionary setObject: [NSNumber numberWithBool:enableInternalRouting] forKey:@"enableInternalRouting"];
	[objDictionary setObject: [NSNumber numberWithBool:activateTriggerOnArmed] forKey:@"activateTriggerOnArmed"];
	[objDictionary setObject: [NSNumber numberWithBool:invertTrigger]		   forKey:@"invertTrigger"];
	

 	//clocks
	[objDictionary setObject: [NSNumber numberWithInt:clockSource]			forKey:@"clockSource"];

	[objDictionary setObject: [NSNumber numberWithLong:enabledMask]			forKey:@"enabledMask"];
    [objDictionary setObject: thresholds									forKey:@"thresholds"];	
    [objDictionary setObject: gateLengths									forKey:@"gateLengths"];	
    [objDictionary setObject: pulseLengths									forKey:@"pulseLengths"];	
    [objDictionary setObject: sumGs											forKey:@"sumGs"];	
    [objDictionary setObject: peakingTimes									forKey:@"peakingTimes"];	
    [objDictionary setObject: internalTriggerDelays							forKey:@"internalTriggerDelays"];	
    [objDictionary setObject: [NSNumber numberWithInt:triggerDecimation]	forKey:@"triggerDecimation"];	
    [objDictionary setObject: [NSNumber numberWithInt:energyDecimation]	forKey:@"energyDecimation"];	
    [objDictionary setObject: [NSNumber numberWithLong:gtMask]				forKey:@"gtMask"];	
	
    return objDictionary;
}

- (NSArray*) autoTests 
{
	NSMutableArray* myTests = [NSMutableArray array];
	[myTests addObject:[ORVmeReadOnlyTest test:kSIS3302AcquisitionControl wordSize:4 name:@"Acquistion Reg"]];
	[myTests addObject:[ORVmeWriteOnlyTest test:kSIS3302KeyReset wordSize:4 name:@"Reset"]];
	//[myTests addObject:[ORVmeWriteOnlyTest test:kStartSampling wordSize:4 name:@"Start Sampling"]];
	//[myTests addObject:[ORVmeWriteOnlyTest test:kStopSampling wordSize:4 name:@"Stop Sampling"]];
	//[myTests addObject:[ORVmeWriteOnlyTest test:kStartAutoBankSwitch wordSize:4 name:@"Stop Auto Bank Switch"]];
	//[myTests addObject:[ORVmeWriteOnlyTest test:kStopAutoBankSwitch wordSize:4 name:@"Start Auto Bank Switch"]];
	//[myTests addObject:[ORVmeWriteOnlyTest test:kClearBank1FullFlag wordSize:4 name:@"Clear Bank1 Full"]];
	//[myTests addObject:[ORVmeWriteOnlyTest test:kClearBank2FullFlag wordSize:4 name:@"Clear Bank2 Full"]];
	
	int i;
	for(i=0;i<8;i++){
		[myTests addObject:[ORVmeReadWriteTest test:[self getThresholdRegOffsets:i] wordSize:4 validMask:0xffff name:@"Threshold"]];
		//[myTests addObject:[ORVmeReadOnlyTest test:adcMemory[i] length:64*1024 wordSize:4 name:@"Adc Memory"]];
	}
	return myTests;
}
@end

@implementation ORSIS3302Model (private)
- (void) setUpArrays
{
	int i;
	if(!thresholds){
		thresholds = [[NSMutableArray arrayWithCapacity:kNumSIS3302Channels] retain];
		for(i=0;i<kNumSIS3302Channels;i++)[thresholds addObject:[NSNumber numberWithInt:0]];
	}
	
	if(!dacOffsets){
		dacOffsets = [[NSMutableArray arrayWithCapacity:kNumSIS3302Channels] retain];
		for(i=0;i<kNumSIS3302Channels;i++)[dacOffsets addObject:[NSNumber numberWithInt:0]];
	}
	
	if(!gateLengths){
		gateLengths = [[NSMutableArray arrayWithCapacity:kNumSIS3302Channels] retain];
		for(i=0;i<kNumSIS3302Channels;i++)[gateLengths addObject:[NSNumber numberWithInt:0]];
	}
	
	if(!pulseLengths){
		pulseLengths = [[NSMutableArray arrayWithCapacity:kNumSIS3302Channels] retain];
		for(i=0;i<kNumSIS3302Channels;i++)[pulseLengths addObject:[NSNumber numberWithInt:0]];
	}
	
	if(!sumGs){
		sumGs = [[NSMutableArray arrayWithCapacity:kNumSIS3302Channels] retain];
		for(i=0;i<kNumSIS3302Channels;i++)[sumGs addObject:[NSNumber numberWithInt:0]];
	}
	
	if(!peakingTimes){
		peakingTimes = [[NSMutableArray arrayWithCapacity:kNumSIS3302Channels] retain];
		for(i=0;i<kNumSIS3302Channels;i++)[peakingTimes addObject:[NSNumber numberWithInt:0]];
	}
	
	if(!internalTriggerDelays){
		internalTriggerDelays = [[NSMutableArray arrayWithCapacity:kNumSIS3302Channels] retain];
		for(i=0;i<kNumSIS3302Channels;i++)[internalTriggerDelays addObject:[NSNumber numberWithInt:0]];
	}
}

- (void) writeDacOffsets
{
	
	unsigned int max_timeout, timeout_cnt;
	
	int i;
	for (i=0;i<kNumSIS3302Channels;i++) {
		unsigned long data =  [self dacOffset:i];
		unsigned long addr = [self baseAddress] + kSIS3302DacData  ;
		
		// Set the Data in the DAC Register
		[[self adapter] writeLongBlock:&data
							 atAddress:addr
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
	
		
		data =  1 + (i << 4); // write to DAC Register
		addr = [self baseAddress] + kSIS3302DacControlStatus  ;
		// Tell card to set the DAC shift Register
		[[self adapter] writeLongBlock:&data
							 atAddress:addr
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		max_timeout = 5000 ;
		timeout_cnt = 0 ;
		addr = [self baseAddress] + kSIS3302DacControlStatus  ;
		// Wait until done.
		do {
			[[self adapter] readLongBlock:&data
								 atAddress:addr
								numToRead:1
								withAddMod:addressModifier
							 usingAddSpace:0x01];
			
			timeout_cnt++;
		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
			return;
		}
		
		[[self adapter] writeLongBlock:&data
							atAddress:addr
							numToWrite:1
						   withAddMod:addressModifier
						usingAddSpace:0x01];
		
		
		data =  2 + (i << 4); // Load DACs 
		addr = [self baseAddress] + kSIS3302DacControlStatus  ;
		[[self adapter] writeLongBlock:&data
							 atAddress:addr
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];

		timeout_cnt = 0 ;
		addr = [self baseAddress] + kSIS3302DacControlStatus  ;
		do {
			[[self adapter] readLongBlock:&data
								atAddress:addr
								numToRead:1
							   withAddMod:addressModifier
							usingAddSpace:0x01];
			timeout_cnt++;
		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
			return;
		}
	}
}
@end
