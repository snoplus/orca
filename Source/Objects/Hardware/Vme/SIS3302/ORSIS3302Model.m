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

NSString* ORSIS3302SampleStartIndexChanged		= @"ORSIS3302SampleStartIndexChanged";
NSString* ORSIS3302SampleLengthChanged			= @"ORSIS3302SampleLengthChanged";
NSString* ORSIS3302DacOffsetChanged				= @"ORSIS3302DacOffsetChanged";
NSString* ORSIS3302LemoInModeChanged			= @"ORSIS3302LemoInModeChanged";
NSString* ORSIS3302LemoOutModeChanged			= @"ORSIS3302LemoOutModeChanged";
NSString* ORSIS3302AcqRegEnableMaskChanged		= @"ORSIS3302AcqRegEnableMaskChanged";
NSString* ORSIS3302CSRRegChanged				= @"ORSIS3302CSRRegChanged";
NSString* ORSIS3302AcqRegChanged				= @"ORSIS3302AcqRegChanged";
NSString* ORSIS3302EventConfigChanged			= @"ORSIS3302EventConfigChanged";
NSString* ORSIS3302PageSizeChanged				= @"ORSIS3302PageSizeChanged";

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

//general register offsets
#define kControlStatus				0x00		// [] Control/Status
#define kModuleIDReg				0x04		// [] module ID
#define kAcquisitionControlReg		0x10		// [] Acquistion Control 
#define kADCDacControlStatus		0x50		// [] DAC Control/Status Reg
#define kGeneralReset				0x20		// [] General Reset
#define kStartSampling				0x30		// [] Start Sampling
#define kStopSampling				0x34		// [] Stop Sampling
#define kStartAutoBankSwitch		0x40		// [] Start Auto Bank Switching
#define kStopAutoBankSwitch			0x44		// [] Start Auto Bank Switching
#define kClearBank1FullFlag			0x48		// [] Clear Bank 1 Full Flag
#define kClearBank2FullFlag			0x4C		// [] Clear Bank 2 Full Flag
#define kEventConfigAll				0x00100000	// [] Event Config (ALL)
#define kTriggerSetupReg			0x100028
#define kTriggerSetupReg			0x100028
#define kTriggerFlagClrCounterReg	0x10001C
#define kMaxNumberEventsReg			0x10002C

// Bits in the data acquisition control register:
//defined state sets value, shift left 16 to clear
#define ACQMask(state,A) ((state)?(A):(A<<16))
#define kSISSampleBank1			0x0001L
#define kSISSampleBank2			0x0002L
#define kSISBankSwitch			0x0004L
#define kSISMultiEvent			0x0020L
#define kSISClockSrcBit1        0x1000L
#define kSISClockSrcBit2        0x2000L
#define kSISClockSrcBit3        0x4000L
#define kSISClockSetShiftCount  12
#define kSISBusyStatus			0x00010000
#define kSISBank1ClockStatus	0x00000001
#define kSISBank2ClockStatus	0x00000002
#define kSISBank1BusyStatus		0x00100000
#define kSISBank2BusyStatus		0x00400000

//Control Status Register Bits
//defined state sets value, shift left 16 to clear
#define CSRMask(state,A) ((state)?(A):(A<<16))
#define kSISLed							0x0001L
#define kSISUserOutput					0x0002L
#define kSISInvertTrigger				0x0010L
#define kSISTriggerOnArmedAndStarted	0x0020L
#define kSISInternalTriggerRouting		0x0040L
#define kSISBankFullTo1					0x0100L
#define kSISBankFullTo2					0x0200L
#define kSISBankFullTo3					0x0400L
#define kCSRReservedMask				0xF888L //reserved bits

// Bits in event register.
#define kSISPageSizeMask       0x00000007
#define kSISWrapMask           0x00000008

#define  kSISEventDirEndEventMask	0x1ffff
#define  kSISEventDirWrapFlag		0x80000

//Bits and fields in the threshold register.
#define kSISTHRLt             0x8000
#define kSISTHRChannelShift    16


@interface ORSIS3302Model (private)
- (void) writeDacOffsets;
@end

@implementation ORSIS3302Model

#pragma mark •••Static Declarations
static unsigned long thresholdRegOffsets[8]={
	0x02000034,
	0x0200003C,
	0x02800034,
	0x0280003C,
	0x03000034,
	0x0300003C,
	0x03800034,
	0x0380003C
};

static unsigned long triggerSetupRegOffsets[8]={
	0x02000030,
	0x02000038,
	0x02800030,
	0x02800038,
	0x03000030,
	0x03000038,
	0x03800030,
	0x03800038
};

static unsigned long triggerExtSetupRegOffsets[8]={
	0x02000030,
	0x02000038,
	0x02800030,
	0x02800038,
	0x03000030,
	0x03000038,
	0x03800030,
	0x03800038
};


static unsigned long endThresholdRegOffsets[4]={
	0x02000004,
	0x02800004,
	0x03000004,
	0x03800004
};

static unsigned long preTriggerDelayRegOffsets[4]={
	0x02000008,
	0x02800008,
	0x03000008,
	0x03800008
};


static unsigned long adcMemory[8]={
	0x04000000,
	0x04800000,
	0x05000000,
	0x05800000,
	0x06000000,
	0x06800000,
	0x07000000,
	0x07800000
};

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
    [self initParams];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x01000000];

	[self setDefaults];
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
	[triggerDecimations release];
	
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

- (unsigned short) sampleStartIndex{ return sampleStartIndex; }
- (void) setSampleStartIndex:(unsigned short)aSampleStartIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleStartIndex:sampleStartIndex];
    sampleStartIndex = aSampleStartIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302SampleStartIndexChanged object:self];
}

- (unsigned short) sampleLength { return sampleLength; }

- (void) setSampleLength:(unsigned short)aSampleLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleLength:sampleLength];
    sampleLength = aSampleLength;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302SampleLengthChanged object:self];
}

- (unsigned short) dacOffset { return dacOffset; }
- (void) setDacOffset:(unsigned short)aDacOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDacOffset:dacOffset];
    dacOffset = aDacOffset;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302DacOffsetChanged object:self];
}

- (short) lemoInMode { return lemoInMode; }
- (void) setLemoInMode:(short)aLemoInMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoInMode:lemoInMode];
    lemoInMode = aLemoInMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302LemoInModeChanged object:self];
}

- (short) lemoOutMode { return lemoOutMode; }
- (void) setLemoOutMode:(short)aLemoOutMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutMode:lemoOutMode];
    lemoOutMode = aLemoOutMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302LemoOutModeChanged object:self];
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
	}
	[self setEnableInternalRouting:YES];
	[self setPageWrap:YES];
	[self setPageSize:1];
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
- (BOOL) pageWrap
{
    return pageWrap;
}

- (void) setPageWrap:(BOOL)aPageWrap
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPageWrap:pageWrap];
    pageWrap = aPageWrap;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302EventConfigChanged object:self];
}

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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302PageSizeChanged object:self];
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
	 postNotificationName:ORSIS3302RateGroupChangedNotification
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
		if(counterTag>=0 && counterTag<kNumSIS3302Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

- (long) enabledMask
{
	return enabledMask;
}

- (BOOL) enabled:(short)chan	
{ 
	return enabledMask & (1<<chan); 
}

- (void) setEnabledMask:(long)aMask	
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

- (long) gtMask
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

- (short) triggerDecimation:(short)aChan { return [[triggerDecimations objectAtIndex:aChan] shortValue]; }
- (void) setTriggerDecimation:(short)aChan withValue:(short)aValue 
{ 
	aValue = [self limitIntValue:aValue min:0 max:0x1f];
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerDecimation:aChan withValue:[self triggerDecimation:aChan]];
    [triggerDecimations replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302TriggerDecimationChanged object:self];
}


#pragma mark •••Hardware Access
- (void) readModuleID:(BOOL)verbose
{	
	unsigned long result = 0;
	[[self adapter] readLongBlock:&result
                         atAddress:[self baseAddress] + kModuleIDReg
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	unsigned long moduleID = result >> 16;
	unsigned short majorRev = (result >> 8) & 0xff;
	unsigned short minorRev = result & 0xff;
	if(verbose)NSLog(@"SIS3302 ID: %x  Firmware:%x.%x\n",moduleID,majorRev,minorRev);
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302IDChanged object:self];
}

- (void) writeControlStatusRegister
{		
	//The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.
	unsigned long aMask = 0x0;	
	if(invertTrigger)			aMask |= kSISInvertTrigger;
	if(activateTriggerOnArmed)	aMask |= kSISTriggerOnArmedAndStarted;
	if(enableInternalRouting)	aMask |= kSISInternalTriggerRouting;
	if(bankFullTo1)				aMask |= kSISBankFullTo1;
	if(bankFullTo2)				aMask |= kSISBankFullTo2;
	if(bankFullTo3)				aMask |= kSISBankFullTo3;
	
	//put the inverse in the top bits to turn off everything else
	aMask = ((~aMask & 0x0000ffff)<<16) | aMask ;
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeAcquistionRegister
{
	// The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.	
	unsigned long aMask = 0x0;
	aMask |= ((clockSource & 0x7) << kSISClockSetShiftCount); /*clock src bits*/
	aMask |= acqRegEnableMask;
	aMask |= (lemoOutMode & 0x3) << 4;
	aMask |= (lemoInMode & 0x7)  << 0;
	
	//put the inverse in the top bits to turn off everything else
	aMask = ((~aMask & 0x0000ffff)<<16) | aMask;
	
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kAcquisitionControlReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeEventConfigurationRegister
{
	//enable/disable autostop at end of page
	//set pagesize
	unsigned long aMask = 0x0;
	aMask					  |= pageSize;
	if(pageWrap)		aMask |= kSISWrapMask;
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kEventConfigAll
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) setLed:(BOOL)state
{
	unsigned long aValue = CSRMask(state,kSISLed);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) enableUserOut:(BOOL)state
{
	unsigned long aValue = CSRMask(state,kSISUserOutput);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeTriggerClearValue:(unsigned long)aValue
{

	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kTriggerFlagClrCounterReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) setMaxNumberEvents:(unsigned long)aValue
{
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kMaxNumberEventsReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) startSampling
{
	unsigned long aValue = 0x0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kStartSampling
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) stopSampling
{
	unsigned long aValue = 0x0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kStopSampling
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) startBankSwitching
{
	unsigned long aValue = 0x0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kStartAutoBankSwitch
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) stopBankSwitching
{
	unsigned long aValue = 0x0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kStopAutoBankSwitch
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) clearBankFullFlag:(int)whichFlag
{
	unsigned long aValue = 0x0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + (whichFlag?kClearBank2FullFlag:kClearBank1FullFlag)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (unsigned long) eventNumberGroup:(int)group bank:(int) bank
{
	//Note, here banks are 0,1,2,3 NOT 1,2,3,4
	unsigned long eventNumber = 0x0;   
	[[self adapter] readLongBlock:&eventNumber
						atAddress:[self baseAddress] + eventCountOffset[group][bank]
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	
	return eventNumber;
}

- (unsigned long) eventTriggerGroup:(int)group bank:(int) bank
{
	//Note, here banks are 0,1,2,3 NOT 1,2,3,4
	unsigned long triggerWord = 0x0;   
	[[self adapter] readLongBlock:&triggerWord
						atAddress:[self baseAddress] + eventDirOffset[group][bank]
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	
	return triggerWord;
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

- (void) readAddressCounts
{
	unsigned long aValue;   
	unsigned long aValue1; 
	int i;
	for(i=0;i<4;i++){
		[[self adapter] readLongBlock:&aValue
							atAddress:[self baseAddress] + addressCounterOffset[i][0]
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		[[self adapter] readLongBlock:&aValue1
							atAddress:[self baseAddress] + addressCounterOffset[i][1]
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		NSLog(@"Group %d Address Counters:  0x%04x   0x%04x\n",i,aValue,aValue1);
	}
}

- (unsigned long) acqReg
{
 	unsigned long aValue = 0;
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] + kAcquisitionControlReg
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	return aValue;
}

- (unsigned long) configReg
{
 	unsigned long aValue = 0;
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] + kControlStatus
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	return aValue;
}

- (void) disArm:(int)bank
{
 	unsigned long aValue = ACQMask(FALSE,bank?kSISSampleBank2:kSISSampleBank1);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kAcquisitionControlReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) arm:(int)bank
{
 	unsigned long aValue = ACQMask(TRUE , bank?kSISSampleBank2:kSISSampleBank1);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kAcquisitionControlReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (BOOL) bankIsFull:(int)bank
{
	unsigned long aValue=0;
	[[self adapter] readLongBlock:&aValue
                         atAddress:[self baseAddress] + kAcquisitionControlReg
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	unsigned long mask = (bank?kSISBank2ClockStatus : kSISBank1ClockStatus);
	return (aValue & mask) == 0;
}

- (BOOL) bankIsBusy:(int)bank
{
	unsigned long aValue=0;
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] + kAcquisitionControlReg
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	unsigned long mask = (bank?kSISBank2BusyStatus : kSISBank1BusyStatus);
	return (aValue & mask) != 0;
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
		thresholdMask |= ([self threshold:i] & 0x1FFFF);
		
		[[self adapter] writeLongBlock:&thresholdMask
							 atAddress:[self baseAddress] + thresholdRegOffsets[i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
		
	}
}

- (void) writeTriggerSetups
{
	int i;
	unsigned long aValueMask;
	for(i = 0; i < 8; i++) {
		int sumGLower = [self sumG:i] & 0xff;
		int peakingTimeLower = [self peakingTime:i] & 0xff;
		aValueMask = ([self gateLength:i]<<24) | ([self pulseLength:i]<<16) | (sumGLower<<8) | peakingTimeLower;
		
		[[self adapter] writeLongBlock:&aValueMask
							 atAddress:[self baseAddress] + triggerSetupRegOffsets[i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];

		int sumGUpper = [self sumG:i]>>8;
		int peakingTimeUpper = [self peakingTime:i]>>8;
		int triggerDec = [self triggerDecimation:i] & 0x3;
		int triggerDelay = [self internalTriggerDelay:i] & 0x1f;
		aValueMask =  (triggerDelay<<24) | (triggerDec << 16) | (sumGUpper<<8) | peakingTimeUpper;
		
		[[self adapter] writeLongBlock:&aValueMask
							 atAddress:[self baseAddress] + triggerExtSetupRegOffsets[i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (void) readThresholds:(BOOL)verbose
{   
	int i;
	if(verbose) NSLog(@"Reading Thresholds:\n");
	
	for(i =0; i < kNumSIS3302Channels; i++) {
		unsigned long aValue;
		[[self adapter] readLongBlock: &aValue
							atAddress: [self baseAddress] + thresholdRegOffsets[i]
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

- (unsigned long) readTriggerTime:(int)bank index:(int)index
{   		
	unsigned long aValue;
	[[self adapter] readLongBlock: &aValue
						atAddress: [self baseAddress] + (bank?kTriggerTime2Offset:kTriggerTime1Offset) + index*sizeof(long)
						numToRead: 1
					   withAddMod: [self addressModifier]
					usingAddSpace: 0x01];
		
	return aValue;
}

- (unsigned long) readTriggerEventBank:(int)bank index:(int)index
{   		
	unsigned long aValue;
	[[self adapter] readLongBlock: &aValue
						atAddress: [self baseAddress] + (bank?kTriggerEvent2DirOffset:kTriggerEvent1DirOffset) + index*sizeof(long)
						numToRead: 1
					   withAddMod: [self addressModifier]
					usingAddSpace: 0x01];
	
	return aValue;
}

- (BOOL) isBusy
{
	
	unsigned long aValue = 0;
	[[self adapter] readLongBlock: &aValue
						atAddress: [self baseAddress] + kAcquisitionControlReg
						numToRead: 1
					   withAddMod: [self addressModifier]
					usingAddSpace: 0x01];

	return (aValue & kSISBusyStatus) != 0;
}

- (void) initBoard
{  
	//[self reset];							//reset the card
	[self writeAcquistionRegister];			//set up the Acquisition Register
	//[self writeEventConfigurationRegister];	//set up the Event Config Register
	[self writeThresholds];
	//[self writeControlStatusRegister];		//set up Control/Status Register
	[self writeTriggerSetups];
	//[self writeTriggerClearValue:[self numberOfSamples]+100];
	
}

- (void) testMemory
{
	long i;
	for(i=0;i<1024;i++){
		unsigned long aValue = i;
		[[self adapter] writeLongBlock: &aValue
							atAddress: [self baseAddress] + 0x00400000+i*4
							numToWrite: 1
						   withAddMod: [self addressModifier]
						usingAddSpace: 0x01];
	}
	long errorCount =0;
	for(i=0;i<1024;i++){
		unsigned long aValue;
		[[self adapter] readLongBlock: &aValue
							atAddress: [self baseAddress] + 0x00400000+i*4
							numToRead: 1
						   withAddMod: [self addressModifier]
						usingAddSpace: 0x01];
		if(aValue!=i)errorCount++;
	}
	if(errorCount)NSLog(@"Error R/W Bank memory: %d errors\n",errorCount);
	else NSLog(@"Memory Bank Test Passed\n");
}

- (void) testEventRead
{
	[self reset];
	[self initBoard];

	[self clearBankFullFlag:0];
	[self arm:0];
	[self startSampling];
	int totalTime = 0;
	BOOL timeout = NO;
	while(![self bankIsFull:0]){
		[ORTimer delay:.1];
		if(totalTime++ >= 10){
			timeout = YES;
			break;
		}
	}
	if(!timeout){
		int numEvents= [self eventNumberGroup:0 bank:0];
		NSLog(@"Number Events: %d\n",numEvents);
		unsigned long triggerEventDir;
		triggerEventDir = [self readTriggerEventBank:0 index:0];

		BOOL wrapped = ((triggerEventDir&0x80000) !=0);
		unsigned long startOffset = triggerEventDir & 0x1ffff;
		NSLog(@"address counter0:0x%0x wrapped: %d\n",startOffset,wrapped);
		[self readAddressCounts];
		//unsigned long nLongsToRead = [self numberOfSamples] - startOffset;
		int i;
		for(i=0;i<8;i++){
			if([self enabled:i]){
					[[self adapter] readLongBlock: dataWord[i]
										atAddress: [self baseAddress] + adcMemory[i]
										numToRead: [self numberOfSamples]
									   withAddMod: [self addressModifier]
									usingAddSpace: 0x01];
			}
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302SampleDone object:self];
	}
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
    [p setName:@"Page Size"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPageSize:) getMethod:@selector(pageSize)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
		
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
    [a addObject:[ORHWWizParam boolParamWithName:@"PageWrap" setter:@selector(setPageWrap:) getter:@selector(pageWrap)]];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0x7fff lowerLimit:0 stepSize:1 units:@""];
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
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORSIS3302"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORSIS3302"]];
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
	else if([param isEqualToString:@"TriggerDecimation"])return [[cardDictionary objectForKey:@"triggerDecimation"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Enabled"]) return [cardDictionary objectForKey:@"enabledMask"];
    else if([param isEqualToString:@"Page Size"]) return [cardDictionary objectForKey:@"pageSize"];
    else if([param isEqualToString:@"Clock Source"]) return [cardDictionary objectForKey:@"clockSource"];
    else if([param isEqualToString:@"PageWrap"]) return [cardDictionary objectForKey:@"pageWrap"];
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
	[self clearBankFullFlag:currentBank];
	[self arm:currentBank];
	[self startSampling];
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
		/*
		isRunning = YES;
		if([self bankIsFull:currentBank] && ![self bankIsBusy:currentBank]){
			int bankToUse = currentBank;
			
			int numEvents = [self eventNumberGroup:0 bank:bankToUse];
			int event,group;
			for(event=0;event<numEvents;event++){
				unsigned long triggerEventDir = [self readTriggerEventBank:bankToUse index:event];
				unsigned long startOffset = triggerEventDir&0x1ffff & ([self numberOfSamples]-1);
				unsigned long triggerTime = [self readTriggerTime:bankToUse index:event];
				
				for(group=0;group<4;group++){
					unsigned long channelMask = triggerEventDir & (0xC0000000 >> (group*2));
					if(channelMask==0)continue;
					
					if(triggerEventDir & (0x80000000 >> (group*2)))		++waveFormCount[(group*2)];
					if(triggerEventDir & (0x80000000 >> (group*2)+1))	++waveFormCount[(group*2)+1];
					
					
					//only read the channels that have trigger info
					unsigned long numLongs = 0;
					unsigned long totalNumLongs = [self numberOfSamples] + 4;
					
					NSMutableData* d = [NSMutableData dataWithLength:totalNumLongs*sizeof(long)];
					unsigned long* dataBuffer = (unsigned long*)[d bytes];
					dataBuffer[numLongs++] = dataId | totalNumLongs;
					dataBuffer[numLongs++] = location;

					dataBuffer[numLongs++] = triggerEventDir & (channelMask | 0x00FFFFFF);
					dataBuffer[numLongs++] = ((event&0xFF)<<24) | (triggerTime & 0xFFFFFF);
					

					// The first read is from startOffset -> nPagesize.
					unsigned long nLongsToRead = [self numberOfSamples] - startOffset;	
					if(nLongsToRead>0){
						[[self adapter] readLongBlock: &dataBuffer[numLongs]
											atAddress: [self baseAddress] +adcMemory[group][bankToUse] + 4*startOffset
											numToRead: nLongsToRead
										   withAddMod: [self addressModifier]
										usingAddSpace: 0x01];
						numLongs +=  nLongsToRead;
					}
					
					// The second read, if necessary, is from 0 ->nEventEnd-1.
					if(startOffset>0) {
						[[self adapter] readLongBlock: &dataBuffer[numLongs]
											atAddress: [self baseAddress] + bankMemory[group][bankToUse]
											numToRead: startOffset-1
										   withAddMod: [self addressModifier]
										usingAddSpace: 0x01];			
					}
			
					[aDataPacket addData:d];
				}
			}
			
			[self clearBankFullFlag:currentBank];
			[self arm:currentBank];
			[self startSampling];
			
		}
		 */
	}
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[self stopSampling];
	[self stopBankSwitching];
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
    configStruct->card_info[index].deviceSpecificData[1]	= [self numberOfSamples];
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

- (void) reset
{
 	unsigned long aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kGeneralReset
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
	
    [self setSampleStartIndex:		[decoder decodeIntForKey:@"sampleStartIndex"]];
    [self setSampleLength:			[decoder decodeIntForKey:@"sampleLength"]];
    [self setDacOffset:				[decoder decodeIntForKey:@"dacOffset"]];
    [self setLemoInMode:			[decoder decodeIntForKey:@"lemoInMode"]];
    [self setLemoOutMode:			[decoder decodeIntForKey:@"lemoOutMode"]];
    [self setAcqRegEnableMask:		[decoder decodeIntForKey:@"acqRegEnableMask"]];
	thresholds  =					[[decoder decodeObjectForKey:@"thresholds"] retain];
	gateLengths =					[[decoder decodeObjectForKey:@"gateLengths"] retain];
	pulseLengths =					[[decoder decodeObjectForKey:@"pulseLengths"] retain];
	sumGs =							[[decoder decodeObjectForKey:@"sumGs"] retain];
	peakingTimes =					[[decoder decodeObjectForKey:@"peakingTime"] retain];
	internalTriggerDelays =			[[decoder decodeObjectForKey:@"internalTriggerDelays"] retain];
	triggerDecimations =			[[decoder decodeObjectForKey:@"triggerDecimations"] retain];

	//csr
	[self setBankFullTo3:			[decoder decodeBoolForKey:@"bankFullTo3"]];
    [self setBankFullTo2:			[decoder decodeBoolForKey:@"bankFullTo2"]];
    [self setBankFullTo1:			[decoder decodeBoolForKey:@"bankFullTo1"]];
	[self setEnableInternalRouting:	[decoder decodeBoolForKey:@"enableInternalRouting"]];
    [self setActivateTriggerOnArmed:[decoder decodeBoolForKey:@"activateTriggerOnArmed"]];
    [self setInvertTrigger:			[decoder decodeBoolForKey:@"invertTrigger"]];
	
	//acq
    ;
	
	//clocks
    [self setClockSource:			[decoder decodeIntForKey:@"clockSource"]];
	
    [self setPageWrap:				[decoder decodeBoolForKey:@"pageWrap"]];
    [self setPageSize:				[decoder decodeIntForKey:@"pageSize"]];
    [self setEnabledMask:			[decoder decodeInt32ForKey:@"enabledMask"]];
	[self setGtMask:				[decoder decodeIntForKey:@"GtMask"]];
		
    [self setWaveFormRateGroup:[decoder decodeObjectForKey:@"waveFormRateGroup"]];

    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3302Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	int i;
	if(!thresholds){
		thresholds = [[NSMutableArray arrayWithCapacity:kNumSIS3302Channels] retain];
		for(i=0;i<kNumSIS3302Channels;i++)[thresholds addObject:[NSNumber numberWithInt:0]];
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
	
	if(!triggerDecimations){
		triggerDecimations = [[NSMutableArray arrayWithCapacity:kNumSIS3302Channels] retain];
		for(i=0;i<kNumSIS3302Channels;i++)[triggerDecimations addObject:[NSNumber numberWithInt:0]];
	}
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
	[encoder encodeInt:sampleStartIndex			forKey:@"sampleStartIndex"];
	[encoder encodeInt:sampleLength				forKey:@"sampleLength"];
	[encoder encodeInt:dacOffset				forKey:@"dacOffset"];
	[encoder encodeInt:lemoInMode				forKey:@"lemoInMode"];
	[encoder encodeInt:lemoOutMode				forKey:@"lemoOutMode"];
	[encoder encodeInt:acqRegEnableMask			forKey:@"acqRegEnableMask"];
	[encoder encodeObject:thresholds			forKey:@"thresholds"];
	[encoder encodeObject:gateLengths			forKey:@"gateLengths"];
	[encoder encodeObject:pulseLengths			forKey:@"pulseLengths"];
	[encoder encodeObject:sumGs					forKey:@"sumGs"];
	[encoder encodeObject:peakingTimes			forKey:@"peakingTimes"];
	[encoder encodeObject:internalTriggerDelays	forKey:@"internalTriggerDelays"];
	[encoder encodeObject:triggerDecimations	forKey:@"triggerDecimations"];

	//csr
    [encoder encodeBool:bankFullTo3				forKey:@"bankFullTo3"];
    [encoder encodeBool:bankFullTo2				forKey:@"bankFullTo2"];
    [encoder encodeBool:bankFullTo1				forKey:@"bankFullTo1"];
    [encoder encodeBool:enableInternalRouting	forKey:@"enableInternalRouting"];
    [encoder encodeBool:activateTriggerOnArmed	forKey:@"activateTriggerOnArmed"];
    [encoder encodeBool:invertTrigger			forKey:@"invertTrigger"];

	
 	//clocks
    [encoder encodeInt:clockSource				forKey:@"clockSource"];
	
    [encoder encodeBool:pageWrap				forKey:@"pageWrap"];

    [encoder encodeInt:pageSize					forKey:@"pageSize"];
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
	[objDictionary setObject: [NSNumber numberWithBool:invertTrigger]		forKey:@"invertTrigger"];
	

 	//clocks
	[objDictionary setObject: [NSNumber numberWithInt:clockSource]			forKey:@"clockSource"];

	[objDictionary setObject: [NSNumber numberWithInt:pageSize]				forKey:@"pageSize"];
	[objDictionary setObject: [NSNumber numberWithBool:pageWrap]			forKey:@"pageWrap"];
	[objDictionary setObject: [NSNumber numberWithLong:enabledMask]			forKey:@"enabledMask"];
    [objDictionary setObject: thresholds									forKey:@"thresholds"];	
    [objDictionary setObject: gateLengths									forKey:@"gateLengths"];	
    [objDictionary setObject: pulseLengths									forKey:@"pulseLengths"];	
    [objDictionary setObject: sumGs											forKey:@"sumGs"];	
    [objDictionary setObject: peakingTimes									forKey:@"peakingTimes"];	
    [objDictionary setObject: internalTriggerDelays							forKey:@"internalTriggerDelays"];	
    [objDictionary setObject: triggerDecimations							forKey:@"triggerDecimations"];	
    [objDictionary setObject: [NSNumber numberWithLong:gtMask]				forKey:@"gtMask"];	
	
    return objDictionary;
}

- (NSArray*) autoTests 
{
	NSMutableArray* myTests = [NSMutableArray array];
	[myTests addObject:[ORVmeReadOnlyTest test:kControlStatus wordSize:4 name:@"Control Status"]];
	[myTests addObject:[ORVmeReadOnlyTest test:kAcquisitionControlReg wordSize:4 name:@"Acquistion Reg"]];
	[myTests addObject:[ORVmeWriteOnlyTest test:kGeneralReset wordSize:4 name:@"Reset"]];
	[myTests addObject:[ORVmeWriteOnlyTest test:kStartSampling wordSize:4 name:@"Start Sampling"]];
	[myTests addObject:[ORVmeWriteOnlyTest test:kStopSampling wordSize:4 name:@"Stop Sampling"]];
	[myTests addObject:[ORVmeWriteOnlyTest test:kStartAutoBankSwitch wordSize:4 name:@"Stop Auto Bank Switch"]];
	[myTests addObject:[ORVmeWriteOnlyTest test:kStopAutoBankSwitch wordSize:4 name:@"Start Auto Bank Switch"]];
	[myTests addObject:[ORVmeWriteOnlyTest test:kClearBank1FullFlag wordSize:4 name:@"Clear Bank1 Full"]];
	[myTests addObject:[ORVmeWriteOnlyTest test:kClearBank2FullFlag wordSize:4 name:@"Clear Bank2 Full"]];
	
	int i;
	for(i=0;i<8;i++){
		[myTests addObject:[ORVmeReadWriteTest test:thresholdRegOffsets[i] wordSize:4 validMask:0xffff name:@"Threshold"]];
		//[myTests addObject:[ORVmeReadOnlyTest test:adcMemory[i] length:64*1024 wordSize:4 name:@"Adc Memory"]];
	}
	return myTests;
}
@end

@implementation ORSIS3302Model (private)
- (void) writeDacOffsets
{
	unsigned long data;
	unsigned long max_timeout, timeout_cnt;
	int i;
	for(i=0;i<kNumSIS3302Channels;i++){
		unsigned long dac_select_no = i%2;
		data =  [self dacOffset];
		[[self adapter] writeLongBlock:&data
							 atAddress:baseAddress + kADCDacControlStatus + 4 // DAC_DATA
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		data =  1 + (dac_select_no << 4); // write to DAC Register
		[[self adapter] writeLongBlock:&data
							 atAddress:baseAddress + kADCDacControlStatus
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		max_timeout = 5000;
		timeout_cnt = 0;
		do {
			[[self adapter] readLongBlock:&data
								atAddress:baseAddress + kADCDacControlStatus
								numToRead:1
							   withAddMod:addressModifier
							usingAddSpace:0x01];
			timeout_cnt++;
		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) );
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
			continue;
		}
		
		data =  2 + (dac_select_no << 4); // Load DACs 
		[[self adapter] writeLongBlock:&data
							 atAddress:baseAddress + kADCDacControlStatus
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		timeout_cnt = 0;
		do {
			[[self adapter] readLongBlock:&data
								atAddress:baseAddress + kADCDacControlStatus
								numToRead:1
							   withAddMod:addressModifier
							usingAddSpace:0x01];
			timeout_cnt++;
		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) );
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
			continue;
		}
	}
}
@end
