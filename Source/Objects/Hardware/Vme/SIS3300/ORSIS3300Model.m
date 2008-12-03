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
#import "ORSIS3300Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"

NSString* ORSIS3300ModelAutoStartChanged		= @"ORSIS3300ModelAutoStartChanged";
NSString* ORSIS3300ModelMultiEventModeChanged	= @"ORSIS3300ModelMultiEventModeChanged";
NSString* ORSIS3300ModelPageWrapChanged			= @"ORSIS3300ModelPageWrapChanged";
NSString* ORSIS3300ModelStopTriggerChanged		= @"ORSIS3300ModelStopTriggerChanged";
NSString* ORSIS3300ModelP2StartStopChanged		= @"ORSIS3300ModelP2StartStopChanged";
NSString* ORSIS3300ModelLemoStartStopChanged	= @"ORSIS3300ModelLemoStartStopChanged";
NSString* ORSIS3300ModelRandomClockChanged		= @"ORSIS3300ModelRandomClockChanged";
NSString* ORSIS3300ModelGateModeChanged			= @"ORSIS3300ModelGateModeChanged";
NSString* ORSIS3300ModelStartDelayEnabledChanged = @"ORSIS3300ModelStartDelayEnabledChanged";
NSString* ORSIS3300ModelStopDelayEnabledChanged = @"ORSIS3300ModelStopDelayEnabledChanged";
NSString* ORSIS3300ModelStopDelayChanged		= @"ORSIS3300ModelStopDelayChanged";
NSString* ORSIS3300ModelStartDelayChanged		= @"ORSIS3300ModelStartDelayChanged";
NSString* ORSIS3300ModelClockSourceChanged		= @"ORSIS3300ModelClockSourceChanged";
NSString* ORSIS3300ModelPageSizeChanged			= @"ORSIS3300ModelPageSizeChanged";
NSString* ORSIS3300RateGroupChangedNotification	= @"ORSIS3300RateGroupChangedNotification";
NSString* ORSIS3300SettingsLock					= @"ORSIS3300SettingsLock";

NSString* ORSIS3300ModelEnabledChanged			= @"ORSIS3300ModelEnabledChanged";
NSString* ORSIS3300ModelThresholdChanged		= @"ORSIS3300ModelThresholdChanged";
NSString* ORSIS3300ModelThresholdArrayChanged	= @"ORSIS3300ModelThresholdArrayChanged";
NSString* ORSIS3300ModelLtGtChanged				= @"ORSIS3300ModelLtGtChanged";

// Bits in the data acquisition control register:
//
#define kSISSampleBank1On        0x00000001
#define kSISSampleBank2On        0x00000002
#define kSISEnableHiRARCM        0x00000008
#define kSISAutostartOn          0x00000010
#define kSISMultiEventOn         0x00000020
#define kSISStopDelayOn          0x00000080
#define kSISStartDelayOn         0x00000040
#define kSISEnableLemoStartStop  0x00000100
#define kSISEnableP2StartStop    0x00000200
#define kSISEnableGateMode       0x00000400
#define kSISEnableRandomClock    0x00000800
#define kSISClockSetMask         0x00007000
#define kSISDisableHiRARCM       0x00080000
#define kSISClockSetShiftCount   12
#define kSISSampleBank1Off       0x00010000
#define kSISBusyStatus           0x00010000
#define kSISSampleBank2Off       0x00020000
#define kSISAutostartOff         0x00100000
#define kSISMultiEventOff        0x00200000
#define kSISStopDelayOff         0x00800000
#define kSISStartDelayOff        0x00400000
#define kSISDisableLemoStartStop 0x01000000
#define kSISDisableP2StartStop   0x02000000
#define kSISDisableGateMode      0x04000000
#define kSISDisableRandomClock   0x08000000
#define kSISClockClearMask       0x70000000
#define kSISCLockClearShiftCount 28

#define kSISLedStatus                    1
#define kSISUserOutputState              2
#define kSISTriggerOutputState           4 
#define kSISTriggerIsInverted     0x000010
#define kSISTriggerCondition      0x000020 //1: armed and started
#define kSISUserInputCondition    0x010000
#define kSISP2_TEST_IN            0x020000
#define kSISP2_RESET_IN           0x040000
#define kSISP2_SAMPLE_IN          0X080000

#define kSISLedOn                            1
#define kSISUserOutputOn                     2
#define kSISEnableTriggerOutput              4
#define kSISInvertTriggerOutput       0x000010
#define kSISTriggerOnArmedAndStarted  0x000020
#define kSISLedOff                    0x010000
#define kSISUserOutputOff             0x020000
#define kSISEnableUserOutput          0x040000
#define kSISNormalTriggerOutput       0x100000
#define kSISTriggerOnArmed            0x200000


// Bits in event register.
#define kSISPageSizeMask       7
#define kSISPageSizeShiftCount 0
#define kSISWrapMask           8
#define kSISWrapShiftCount     3
#define kSISRandomClock        (1 << 11)

//Bits and fields in the threshold register.
#define kSISTHRLt             0x8000
#define kSISTHRChannelShift    16

@implementation ORSIS3300Model

#pragma mark •••Static Declarations
//offsets from the base address
static unsigned long register_offsets[kNumberOfSIS3300Registers] = {
0x00, // [] Control/Status
0x10, // [] Acquistion Control 
0x14, // [] Start Delay Clocks
0x18, // [] Start Delay Clocks
0x20, // [] General Reset
0x30, // [] Start Sampling
0x34, // [] Stop Sampling
};

static unsigned long thresholdRegOffsets[4]={
0x00200004,
0x00280004,
0x00300004,
0x00380004
};

static unsigned long eventRegOffsets[4]={
0x00200008,
0x00280008,
0x00300008,
0x00380008
};

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self initParams];
    [self setAddressModifier:0x39];
    [self setThresholds:[NSMutableArray arrayWithCapacity:kNumSIS3300Channels]];
	int i;
    for(i=0;i<kNumSIS3300Channels;i++){
        [thresholds addObject:[NSNumber numberWithInt:0]];
    }
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
    [thresholds release];
    [waveFormRateGroup release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3300Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3300Controller"];
}

#pragma mark ***Accessors

- (BOOL) autoStart
{
    return autoStart;
}

- (void) setAutoStart:(BOOL)aAutoStart
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoStart:autoStart];
    
    autoStart = aAutoStart;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelAutoStartChanged object:self];
}

- (BOOL) multiEventMode
{
    return multiEventMode;
}

- (void) setMultiEventMode:(BOOL)aMultiEventMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMultiEventMode:multiEventMode];
    
    multiEventMode = aMultiEventMode;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelMultiEventModeChanged object:self];
}

- (BOOL) pageWrap
{
    return pageWrap;
}

- (void) setPageWrap:(BOOL)aPageWrap
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPageWrap:pageWrap];
    
    pageWrap = aPageWrap;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelPageWrapChanged object:self];
}

- (BOOL) stopTrigger
{
    return stopTrigger;
}

- (void) setStopTrigger:(BOOL)aStopTrigger
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStopTrigger:stopTrigger];
    
    stopTrigger = aStopTrigger;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelStopTriggerChanged object:self];
}

- (BOOL) p2StartStop
{
    return p2StartStop;
}

- (void) setP2StartStop:(BOOL)ap2StartStop
{
    [[[self undoManager] prepareWithInvocationTarget:self] setP2StartStop:p2StartStop];
    
    p2StartStop = ap2StartStop;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelP2StartStopChanged object:self];
}

- (BOOL) lemoStartStop
{
    return lemoStartStop;
}

- (void) setLemoStartStop:(BOOL)aLemoStartStop
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoStartStop:lemoStartStop];
    
    lemoStartStop = aLemoStartStop;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelLemoStartStopChanged object:self];
}

- (BOOL) randomClock
{
    return randomClock;
}

- (void) setRandomClock:(BOOL)aRandomClock
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRandomClock:randomClock];
    
    randomClock = aRandomClock;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelRandomClockChanged object:self];
}

- (BOOL) gateMode
{
    return gateMode;
}

- (void) setGateMode:(BOOL)aGateMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGateMode:gateMode];
    
    gateMode = aGateMode;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelGateModeChanged object:self];
}

- (BOOL) startDelayEnabled
{
    return startDelayEnabled;
}

- (void) setStartDelayEnabled:(BOOL)aStartDelayEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStartDelayEnabled:startDelayEnabled];
    
    startDelayEnabled = aStartDelayEnabled;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelStartDelayEnabledChanged object:self];
}

- (BOOL) stopDelayEnabled
{
    return stopDelayEnabled;
}

- (void) setStopDelayEnabled:(BOOL)aStopDelayEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStopDelayEnabled:stopDelayEnabled];
    
    stopDelayEnabled = aStopDelayEnabled;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelStopDelayEnabledChanged object:self];
}

- (int) stopDelay
{
    return stopDelay;
}

- (void) setStopDelay:(int)aStopDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStopDelay:stopDelay];
    
    stopDelay = aStopDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelStopDelayChanged object:self];
}

- (int) startDelay
{
    return startDelay;
}

- (void) setStartDelay:(int)aStartDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStartDelay:startDelay];
    
    startDelay = aStartDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelStartDelayChanged object:self];
}
- (int) clockSource
{
    return clockSource;
}

- (void) setClockSource:(int)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    
    clockSource = aClockSource;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelClockSourceChanged object:self];
}


- (int) pageSize
{
    return pageSize;
}

- (void) setPageSize:(int)aPageSize
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPageSize:pageSize];
    
    pageSize = aPageSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelPageSizeChanged object:self];
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
	 postNotificationName:ORSIS3300RateGroupChangedNotification
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
		if(counterTag>=0 && counterTag<kNumSIS3300Channels){
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
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelEnabledChanged object:self];
}

- (void) setEnabledBit:(short)chan withValue:(BOOL)aValue		
{ 
	unsigned char aMask = enabledMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setEnabledMask:aMask];
}

- (long) ltGtMask
{
	return ltGtMask;
}

- (BOOL) ltGt:(short)chan	
{ 
	return ltGtMask & (1<<chan); 
}

- (void) setLtGtMask:(long)aMask	
{ 
	[[[self undoManager] prepareWithInvocationTarget:self] setLtGtMask:ltGtMask];
	ltGtMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3300ModelLtGtChanged object:self];
}

- (void) setLtGtBit:(short)chan withValue:(BOOL)aValue		
{ 
	unsigned char aMask = ltGtMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setLtGtMask:aMask];
}


- (NSMutableArray*) thresholds
{
    return thresholds;
}

- (void) setThresholds:(NSMutableArray*)someThresholds
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThresholds:[self thresholds]];
	
    [someThresholds retain];
    [thresholds release];
    thresholds = someThresholds;
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSIS3300ModelThresholdArrayChanged
	 object:self];
}

- (int) threshold:(short)aChan
{
    return [[thresholds objectAtIndex:aChan] shortValue];
}

- (void) setThreshold:(short)aChan withValue:(int)aValue 
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSIS3300ModelThresholdChanged
	 object:self];
}




#pragma mark •••Hardware Access
- (void) writeControlStatusRegister
{
	//   LED off, Output is trigger. Trigger output is univerted.
	//   Trigger on armed if trigger is start, or armed and started if trigger
	//   is stop.
	unsigned long csrmask = kSISLedOff | kSISUserOutputOff | kSISEnableTriggerOutput | kSISNormalTriggerOutput;
	if(stopTrigger)	csrmask |= kSISTriggerOnArmedAndStarted;
	else				csrmask |= kSISTriggerOnArmed;
	
	[[self adapter] writeLongBlock:&csrmask
                         atAddress:[self baseAddress] + register_offsets[kControlStatus]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeAcquistionRegister
{
	// The acquition register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.
	// both bits must not be set at the same time, so we disable all functions first, then set the enable bits.
	
	unsigned long allFunctionsDisabled = 0xFFFF0000;
	[[self adapter] writeLongBlock:&allFunctionsDisabled
                         atAddress:[self baseAddress] + register_offsets[kAcquisitionControlReg]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
	unsigned long aMask = 0x0;
	
	aMask |= (clockSource << kSISClockSetShiftCount) ;			//set the clock source
	if(gateMode)			aMask |= kSISEnableGateMode;		//set Start/Stop or Gate mode
	if(p2StartStop)			aMask |= kSISEnableP2StartStop;		//set P2 External Start/Stop Enable
	if(lemoStartStop)		aMask |= kSISEnableLemoStartStop;	//set LEMO External Start/Stop Enable
	if(startDelayEnabled)	aMask |= kSISStartDelayOn;			//set Extern Stop Delay Enable
	if(stopDelayEnabled)	aMask |= kSISStopDelayOn;			//set Extern Start Delay Enable
	if(multiEventMode)		aMask |= kSISMultiEventOn;			//set MultiEvent Enable
	if(multiEventMode & autoStart)		aMask |= kSISAutostartOn;	//set AutoStart Enable (only if in multiEvent)
	
	if(randomClock)			aMask |= kSISEnableRandomClock;		//set Extern Random Clock Enable
	
	
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + register_offsets[kAcquisitionControlReg]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeEventConfigurationRegister
{
	unsigned long aMask = 0x0;
	aMask	= (pageSize << kSISPageSizeShiftCount);
	if(pageWrap)	aMask |= kSISWrapMask;
	if(randomClock) aMask |= kSISRandomClock;		//This must be set in both Acq Control and Event Config Registers
	
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + register_offsets[kAcquisitionControlReg]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeStartDelay
{
	unsigned long aValue = stopDelay;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kStartDelay]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeStopDelay
{
	unsigned long aValue = startDelay;
	
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kStopDelay]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) setLed:(BOOL)state
{
	unsigned long aValue = state?0x1:0x010000;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kControlStatus]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) enableUserOut:(BOOL)state
{
	unsigned long aValue = state?0x2:0x4;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kControlStatus]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) strobeUserOut
{
	unsigned long aValue = 0x02;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kControlStatus]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
	[ORTimer delay:.05];
	
	aValue = 0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kControlStatus]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}

- (void) startSampling
{
	unsigned long aValue = 0x0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kStartSampling]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) stopSampling
{
	unsigned long aValue = 0x0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kStopSampling]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (unsigned long) eventNumber:(int) bank
{
	//Note, here banks are 0,1,2,3 NOT 1,2,3,4
	unsigned long eventNumber = 0x0;   
	[[self adapter] readLongBlock:&eventNumber
						atAddress:[self baseAddress] + eventRegOffsets[bank]
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	
	return eventNumber;
}


- (void) clearDaq
{
 	unsigned long aValue = kSISSampleBank1On;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kAcquisitionControlReg]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) disArm1
{
 	unsigned long aValue = kSISSampleBank1Off;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kAcquisitionControlReg]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) disArm2
{
 	unsigned long aValue = kSISSampleBank2Off; 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kAcquisitionControlReg]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) arm1
{
 	unsigned long aValue = kSISSampleBank1On; 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kAcquisitionControlReg]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) arm2
{
 	unsigned long aValue = kSISSampleBank2On; 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kAcquisitionControlReg]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeThresholds
{   
	int tchan = 0;
	int i;
	for(i =0; i < 4; i++) {
		//the thresholds are packed even/odd into one long word with the Less/Greater Than bits
		unsigned long even_thresh = [self threshold:tchan];
		if([self ltGt:tchan]) even_thresh |= kSISTHRLt;
		tchan++;
		
		unsigned long odd_thresh = [self threshold:tchan];
		if([self ltGt:tchan]) odd_thresh |= kSISTHRLt;
		tchan++;
		
		unsigned long aValue = (odd_thresh << kSISTHRChannelShift) | even_thresh;
		
		[[self adapter] writeLongBlock:&aValue
							 atAddress:[self baseAddress] + thresholdRegOffsets[i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
		
	}
}

- (void) initBoard
{  
	[self reset];							//reset the card
	[self writeControlStatusRegister];		//set up Control/Status Register
	[self writeAcquistionRegister];			//set up the Acquisition Register
	[self writeEventConfigurationRegister];	//set up the Event Config Register
}




/*
 - (unsigned int) readAGroup(void*) pbuffer,
 volatile unsigned long* pAddressReg,
 unsigned long           nBase)
 {
 
 --------------------------------------------------------------
 Function to read a full event. This breaks into these cases:
 --pageWrap false. 
 In this case, the event directory entry determines the end of the event 
 as well as the number of samples. 
 Note that we assume that the wrap bit in the event directory allows us 
 to differentiate between 0 samples and 128Ksamples.
 
 --pageWrap true, but the event directory wrap bit is false. 
 Again, the number of samples is determined by the address pointer.
 
 --pageWrap true and event directory wrap bit is true. 
 In this case, a full m_nPagesize samples have been taken and the address pointer 
 indicates the start of event. The data procede circularly in the first m_nPagesize 
 words of the buffer memory since we don't support multi-event mode yet.
 --------------------------------------------------------------
 */
/*	unsigned long nPagesize(m_nPagesize); // Max conversion count.
 
 // Decode the event directory entry:
 
 unsigned long  AddressRegister = *pAddressReg;
 bool           fWrapped      = (*pAddressReg & EDIRWrapFlag ) != 0;
 unsigned long  nEventEnd     = (*pAddressReg & EDIREndEventMask);
 nEventEnd                   &= (nPagesize-1); // Wrap the pointer to pagesize
 
 unsigned long  nLongs(0);
 unsigned long* Samples((unsigned long*)pbuffer);
 
 // The three cases above break into two cases: fWrapped true or not.
 
 if(fWrapped) {
 //  Full set of samples... 
 
 nLongs = nPagesize;
 
 // Breaks down into two reads:
 
 // The first read is from nEventEnd -> nPagesize.
 
 int nReadSize = (nPagesize - nEventEnd);
 if(nReadSize > 0) {
 CVMEInterface::Read((void*)m_nFd,
 nBase + nEventEnd*sizeof(long),
 Samples,
 nReadSize*sizeof(long));
 }
 
 // The second read, if necessary, is from 0 ->nEventEnd-1.
 
 unsigned long nOffset =  nReadSize; // Offset into Samples where data goes.
 nReadSize = nPagesize - nReadSize;  // Size of remaining read.
 if(nReadSize > 0) {
 CVMEInterface::Read((void*)m_nFd,
 nBase,
 &(Samples[nOffset]),
 nReadSize*sizeof(long));
 }
 nLongs = nPagesize;
 }
 else {                        
 // Only 0 - nEventEnd to read...
 if(nEventEnd > 0) {
 CVMEInterface::Read((void*)m_nFd,
 nBase, Samples, 
 (nEventEnd*sizeof(long)));
 nLongs = nEventEnd;
 } 
 else {                      // nothing to read...
 nLongs = 0;
 }
 }
 
 return nLongs*sizeof(unsigned long)/sizeof(unsigned short);
 
 }
 */
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
								 @"ORSIS33004WaveformDecoder",            @"decoder",
								 [NSNumber numberWithLong:dataId],        @"dataId",
								 [NSNumber numberWithBool:YES],           @"variable",
								 [NSNumber numberWithLong:-1],			 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"SIS3300"];
    
    return dataDictionary;
}

#pragma mark •••HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (int) numberOfChannels
{
    return kNumSIS3300Channels;
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
    [p setName:@"Start Delay"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setStartDelay:) getMethod:@selector(startDelay)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Stop Delay"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setStopDelay:) getMethod:@selector(stopDelay)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
	
    [a addObject:[ORHWWizParam boolParamWithName:@"PageWrap" setter:@selector(setPageWrap:) getter:@selector(pageWrap)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"StopTrigger" setter:@selector(setStopTrigger:) getter:@selector(stopTrigger)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"P2StartStop" setter:@selector(setP2StartStop:) getter:@selector(p2StartStop)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"LemoStartStop" setter:@selector(setLemoStartStop:) getter:@selector(lemoStartStop)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"RandomClock" setter:@selector(setRandomClock:) getter:@selector(randomClock)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"GateMode" setter:@selector(setGateMode:) getter:@selector(gateMode)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"StartDelayEnabled" setter:@selector(setStartDelayEnabled:) getter:@selector(startDelayEnabled)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"StopDelayEnabled" setter:@selector(setStopDelayEnabled:) getter:@selector(stopDelayEnabled)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"MultiEvent" setter:@selector(setMultiEventMode:) getter:@selector(multiEventMode)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"AutoStart" setter:@selector(setAutoStart:) getter:@selector(autoStart)]];
	
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0x7fff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
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
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORSIS3300Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORSIS3300Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:@"Threshold"])return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Enabled"]) return [cardDictionary objectForKey:@"enabledMask"];
    else if([param isEqualToString:@"Page Size"]) return [cardDictionary objectForKey:@"pageSize"];
    else if([param isEqualToString:@"Start Delay"]) return [cardDictionary objectForKey:@"startDelay"];
    else if([param isEqualToString:@"Stop Delay"]) return [cardDictionary objectForKey:@"stopDelay"];
    else if([param isEqualToString:@"Clock Source"]) return [cardDictionary objectForKey:@"clockSource"];
    else if([param isEqualToString:@"PageWrap"]) return [cardDictionary objectForKey:@"pageWrap"];
    else if([param isEqualToString:@"StopTrigger"]) return [cardDictionary objectForKey:@"stopTrigger"];
    else if([param isEqualToString:@"P2StartStop"]) return [cardDictionary objectForKey:@"p2StartStop"];
    else if([param isEqualToString:@"LemoStartStop"]) return [cardDictionary objectForKey:@"lemoStartStop"];
    else if([param isEqualToString:@"RandomClock"]) return [cardDictionary objectForKey:@"randomClock"];
    else if([param isEqualToString:@"GateMode"]) return [cardDictionary objectForKey:@"gateMode"];
    else if([param isEqualToString:@"MultiEvent"]) return [cardDictionary objectForKey:@"multiEventMode"];
    else if([param isEqualToString:@"StartDelayEnabled"]) return [cardDictionary objectForKey:@"sartDelayEnabled"];
    else if([param isEqualToString:@"StopDelayEnabled"]) return [cardDictionary objectForKey:@"stopDelayEnabled"];
    else return nil;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3300Model"];    
    
    //cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    //theController   = [[self crate] controllerCard];
    theController   = [self adapter];
    
    [self startRates];
	
    [self initBoard];
	
	[self performSelector:@selector(checkFifoAlarm) withObject:nil afterDelay:1];
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    @try {
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
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	
    /* The current hardware specific data is:               *
     *                                                      *
     * 0: FIFO state address                                *
     * 1: FIFO empty state mask                             *
     * 2: FIFO address                                      *
     * 3: FIFO address AM                                   *
     * 4: FIFO size                                         */
    
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kSIS3300; //should be unique
	configStruct->card_info[index].hw_mask[0]				= dataId; //better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= [self addressModifier];
	configStruct->card_info[index].base_add					= [self baseAddress];
    configStruct->card_info[index].deviceSpecificData[1]	= kSIS3300FIFOEmpty;
    configStruct->card_info[index].deviceSpecificData[2]	= [self baseAddress] * 0x100;
    configStruct->card_info[index].deviceSpecificData[3]	= 0x39;
    configStruct->card_info[index].deviceSpecificData[4]	= 0x4000;
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

- (void) reset
{
 	unsigned long aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_offsets[kGeneralReset]
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
    for(i=0;i<kNumSIS3300Channels;i++){
        waveFormCount[i]=0;
    }
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setAutoStart:			[decoder decodeBoolForKey:@"autoStart"]];
    [self setMultiEventMode:	[decoder decodeBoolForKey:@"multiEventMode"]];
    [self setPageWrap:			[decoder decodeBoolForKey:@"pageWrap"]];
    [self setStopTrigger:		[decoder decodeBoolForKey:@"stopTrigger"]];
    [self setP2StartStop:		[decoder decodeBoolForKey:@"p2StartStop"]];
    [self setLemoStartStop:		[decoder decodeBoolForKey:@"lemoStartStop"]];
    [self setRandomClock:		[decoder decodeBoolForKey:@"randomClock"]];
    [self setGateMode:			[decoder decodeBoolForKey:@"gateMode"]];
    [self setStartDelayEnabled:	[decoder decodeBoolForKey:@"startDelayEnabled"]];
    [self setStopDelayEnabled:	[decoder decodeBoolForKey:@"stopDelayEnabled"]];
    [self setStopDelay:			[decoder decodeIntForKey:@"stopDelay"]];
    [self setStartDelay:		[decoder decodeIntForKey:@"startDelay"]];
    [self setClockSource:		[decoder decodeIntForKey:@"clockSource"]];
    [self setStopDelay:			[decoder decodeIntForKey:@"stopDelay"]];
    [self setPageSize:			[decoder decodeIntForKey:@"pageSize"]];
    [self setEnabledMask:		[decoder decodeInt32ForKey:@"enabledMask"]];
	[self setThresholds:		[decoder decodeObjectForKey:@"thresholds"]];
	
    [self setWaveFormRateGroup:[decoder decodeObjectForKey:@"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3300Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:autoStart			forKey:@"autoStart"];
    [encoder encodeBool:multiEventMode		forKey:@"multiEventMode"];
    [encoder encodeBool:pageWrap			forKey:@"stopTrigger"];
    [encoder encodeBool:stopTrigger			forKey:@"stopTrigger"];
    [encoder encodeBool:p2StartStop			forKey:@"p2StartStop"];
    [encoder encodeBool:lemoStartStop		forKey:@"lemoStartStop"];
    [encoder encodeBool:randomClock			forKey:@"randomClock"];
    [encoder encodeBool:gateMode			forKey:@"gateMode"];
    [encoder encodeBool:startDelayEnabled	forKey:@"startDelayEnabled"];
    [encoder encodeBool:stopDelayEnabled	forKey:@"stopDelayEnabled"];
    [encoder encodeInt:stopDelay			forKey:@"stopDelay"];
    [encoder encodeInt:startDelay			forKey:@"startDelay"];
    [encoder encodeInt:clockSource			forKey:@"clockSource"];
    [encoder encodeInt:pageSize				forKey:@"pageSize"];
    [encoder encodeInt32:enabledMask		forKey:@"enabledMask"];
    [encoder encodeObject:thresholds		forKey:@"thresholds"];
	
    [encoder encodeObject:waveFormRateGroup forKey:@"waveFormRateGroup"];
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[objDictionary setObject: [NSNumber numberWithInt:pageSize]				forKey:@"pageSize"];
	[objDictionary setObject: [NSNumber numberWithInt:stopDelay]			forKey:@"stopDelay"];
	[objDictionary setObject: [NSNumber numberWithInt:startDelay]			forKey:@"startDelay"];
	[objDictionary setObject: [NSNumber numberWithInt:clockSource]			forKey:@"clockSource"];
	[objDictionary setObject: [NSNumber numberWithBool:pageWrap]			forKey:@"pageWrap"];
	[objDictionary setObject: [NSNumber numberWithBool:stopTrigger]			forKey:@"stopTrigger"];
	[objDictionary setObject: [NSNumber numberWithBool:p2StartStop]			forKey:@"p2StartStop"];
	[objDictionary setObject: [NSNumber numberWithBool:lemoStartStop]		forKey:@"lemoStartStop"];
	[objDictionary setObject: [NSNumber numberWithBool:randomClock]			forKey:@"randomClock"];
	[objDictionary setObject: [NSNumber numberWithBool:gateMode]			forKey:@"gateMode"];
	[objDictionary setObject: [NSNumber numberWithBool:startDelayEnabled]	forKey:@"startDelayEnabled"];
	[objDictionary setObject: [NSNumber numberWithBool:stopDelayEnabled]	forKey:@"stopDelayEnabled"];
	[objDictionary setObject: [NSNumber numberWithBool:multiEventMode]		forKey:@"multiEventMode"];
	[objDictionary setObject: [NSNumber numberWithBool:autoStart]			forKey:@"autoStart"];
	[objDictionary setObject: [NSNumber numberWithLong:enabledMask]			forKey:@"enabledMask"];
    [objDictionary setObject:thresholds										forKey:@"thresholds"];	
	
    return objDictionary;
}

@end
