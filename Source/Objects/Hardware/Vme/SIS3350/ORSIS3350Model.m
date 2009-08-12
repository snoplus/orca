//-------------------------------------------------------------------------
//  ORSIS3350Model.h
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

#pragma mark ***Imported Files
#import "ORSIS3350Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"

NSString* ORSIS3350ModelMemoryWrapLengthChanged			= @"ORSIS3350ModelMemoryWrapLengthChanged";
NSString* ORSIS3350ModelEndAddressThresholdChanged		= @"ORSIS3350ModelEndAddressThresholdChanged";
NSString* ORSIS3350ModelRingBufferPreDelayChanged		= @"ORSIS3350ModelRingBufferPreDelayChanged";
NSString* ORSIS3350ModelRingBufferLenChanged			= @"ORSIS3350ModelRingBufferLenChanged";
NSString* ORSIS3350ModelGateSyncExtendLengthChanged		= @"ORSIS3350ModelGateSyncExtendLengthChanged";
NSString* ORSIS3350ModelGateSyncLimitLengthChanged		= @"ORSIS3350ModelGateSyncLimitLengthChanged";
NSString* ORSIS3350ModelMaxNumEventsChanged				= @"ORSIS3350ModelMaxNumEventsChanged";
NSString* ORSIS3350ModelFreqNChanged					= @"ORSIS3350ModelFreqNChanged";
NSString* ORSIS3350ModelFreqMChanged					= @"ORSIS3350ModelFreqMChanged";
NSString* ORSIS3350ModelMemoryStartModeLengthChanged	= @"ORSIS3350ModelMemoryStartModeLengthChanged";
NSString* ORSIS3350ModelMemoryTriggerDelayChanged		= @"ORSIS3350ModelMemoryTriggerDelayChanged";
NSString* ORSIS3350ModelInvertLemoChanged		= @"ORSIS3350ModelInvertLemoChanged";
NSString* ORSIS3350ModelMultiEventChanged		= @"ORSIS3350ModelMultiEventChanged";
NSString* ORSIS3350ModelTriggerMaskChanged		= @"ORSIS3350ModelTriggerMaskChanged";
NSString* ORSIS3350ModelClockSourceChanged		= @"ORSIS3350ModelClockSourceChanged";
NSString* ORSIS3350ModelOperationModeChanged	= @"ORSIS3350ModelOperationModeChanged";
NSString* ORSIS3350ModelStopTriggerChanged		= @"ORSIS3350ModelStopTriggerChanged";
NSString* ORSIS3350RateGroupChangedNotification	= @"ORSIS3350RateGroupChangedNotification";
NSString* ORSIS3350SettingsLock					= @"ORSIS3350SettingsLock";

NSString* ORSIS3350ModelTriggerModeChanged		= @"ORSIS3350ModelTriggerModeChanged";
NSString* ORSIS3350ModelThresholdChanged		= @"ORSIS3350ModelThresholdChanged";
NSString* ORSIS3350ModelThresholdOffChanged		= @"ORSIS3350ModelThresholdOffChanged";
NSString* ORSIS3350ModelTrigPulseLenChanged		= @"ORSIS3350ModelTrigPulseLenChanged";
NSString* ORSIS3350ModelSumGChanged				= @"ORSIS3350ModelSumGChanged";
NSString* ORSIS3350ModelPeakingTimeChanged		= @"ORSIS3350ModelPeakingTimeChanged";
NSString* ORSIS3350ModelIDChanged				= @"ORSIS3350ModelIDChanged";


//general register offsets
#define kControlStatus                      0x00	  /* read/write*/
#define kModuleIDReg                        0x04	  /* read only*/
#define kAcquisitionControlReg				0x10	  /* read/write*/
#define kDirectMemTriggerDelayReg			0x14	  /* read/write*/
#define kDirectMemStartModeLengthReg		0x18	  /* read/write*/
#define kFrequencySynthReg					0x1C	  /* read/write*/
#define kMaxNumEventsReg					0x20	  /* read/write*/
#define kEventCounterReg					0x24	  /* read/write*/
#define kGateSyncLimitLengthReg				0x28	  /* read/write*/
#define kGateSyncExtendLengthReg			0x2C	  /* read/write*/
#define kAdcMemoryPageRegister				0x34	  /*read/write*/
#define kTemperatureRegister				0x70	  /*read only*/

#define kResetRegister						0x0400   /*write only*/
#define kArmSamplingLogicRegister			0x0410   /*write only*/
#define kDisarmSamplingLogicRegister		0x0414   /*write only*/
#define kVMETriggerRegister					0x0418   /*write only*/
#define kTimeStampClearRegister				0x041C	 /*write only*/

#define kRingbufferLengthRegisterAll		0x01000020
#define kRingbufferPreDelayRegisterAll		0x01000024
#define kSampleStartAddressAll				0x01000008
#define kEndAddressThresholdAllDAC			0x01000028	  

#define kADC12DacControlStatus				0x02000050
#define kADC34DacControlStatus				0x03000050

#define kFirTriggerMode						0x01000000
#define kTriggerGtMode						0x02000000
#define kTriggerEnabled						0x04000000

#define kMaxNumEvents	powf(2.0,19)

#define isAcqBusy(A)				((A >> 17) & 0x1)
#define isSamplingLogicArmed(A)		((A >> 16) & 0x1)
#define endAddressThresholdFlag(A)	((A >> 19) & 0x1)

#define kAcqStatusEndAddressFlag	       		0x00080000
#define kAcqStatusBusyFlag	        			0x00020000
#define kAcqStatusArmedFlag	        			0x00010000
#define kMaxAdcBufferLength						0x400000

static unsigned long thresholdRegOffsets[4]={
	0x02000034,
	0x0200003C,
	0x03000034,
	0x0300003C
};
static unsigned long triggerPulseRegOffsets[4]={
	0x02000030,
	0x02000038,
	0x03000030,
	0x03000038
};

static unsigned long actualSampleAddressOffsets[4]={
	0x02000010,
	0x02000014,
	0x03000010,
	0x03000014
};

static unsigned long adcOffsets[4]={
	0x04000000,
	0x05000000,
	0x06000000,
	0x07000000
};

static unsigned long adcGainOffsets[4]={
	0x02000048,
	0x0200004C,
	0x03000048,
	0x0300004C,
};

#define kMaxNumberWords		 0x1000000   // 64MByte
#define kMaxPageSampleLength 0x800000    // 8 MSample / 16 MByte	  
#define kMaxSampleLength	 0x8000000	 // 128 MSample / 256 MByte

unsigned long rblt_data[kMaxNumberWords] ;

@interface ORSIS3350Model (private)
- (void) runTaskStartedRingbufferSynchMode:(ORDataPacket*)aDataPacket	userInfo:(id)userInfo;
- (void) runTaskStartedRingbufferASynchMode:(ORDataPacket*)aDataPacket	userInfo:(id)userInfo;
- (void) runTaskStartedDirectMemoryGateASyncMode:(ORDataPacket*)aDataPacket	userInfo:(id)userInfo;
- (void) runTaskStartedDirectMemoryGateSyncMode:(ORDataPacket*)aDataPacket	userInfo:(id)userInfo;
- (void) runTaskStartedDirectMemoryStartMode:(ORDataPacket*)aDataPacket	userInfo:(id)userInfo;
- (void) runTaskStartedDirectMemoryStopMode:(ORDataPacket*)aDataPacket	userInfo:(id)userInfo;

- (void) takeDataRingbufferSynchMode:(ORDataPacket*)aDataPacket			userInfo:(id)userInfo;
- (void) takeDataRingbufferASynchMode:(ORDataPacket*)aDataPacket		userInfo:(id)userInfo;
- (void) takeDataDirectMemoryGateASyncMode:(ORDataPacket*)aDataPacket		userInfo:(id)userInfo;
- (void) takeDataDirectMemoryGateSyncMode:(ORDataPacket*)aDataPacket		userInfo:(id)userInfo;
- (void) takeDataDirectMemoryStartMode:(ORDataPacket*)aDataPacket		userInfo:(id)userInfo;
- (void) takeDataDirectMemoryStopMode:(ORDataPacket*)aDataPacket		userInfo:(id)userInfo;

- (void) readAndShip:(ORDataPacket*)aDataPacket
			 channel: (unsigned int) aChannel 
  sampleStartAddress:(unsigned int) aBufferSampleStartAddress 
		sampleLength:(unsigned int) aBufferSampleLength;
@end

@implementation ORSIS3350Model

#pragma mark •••Static Declarations

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x10000000];

    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
	[thresholds release];
	[thresholdOffs release];
	[triggerModes release];
	[sumGs release];
	[peakingTimes release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3350Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3350Controller"];
}

- (NSString*) helpURL
{
	//return @"VME/SIS330x.html";
	return nil;
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x7FFFFFF);
}

#pragma mark ***Accessors

- (long) memoryWrapLength
{
    return memoryWrapLength;
}

- (void) setMemoryWrapLength:(long)aMemoryWrapLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMemoryWrapLength:memoryWrapLength];
    memoryWrapLength = aMemoryWrapLength;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelMemoryWrapLengthChanged object:self];
}

- (int) endAddressThreshold
{
    return endAddressThreshold;
}

- (void) setEndAddressThreshold:(int)aEndAddressThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEndAddressThreshold:endAddressThreshold];
    endAddressThreshold = aEndAddressThreshold;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelEndAddressThresholdChanged object:self];
}

- (int) ringBufferPreDelay
{
    return ringBufferPreDelay;
}

- (void) setRingBufferPreDelay:(int)aRingBufferPreDelay
{
	if(aRingBufferPreDelay<0)			aRingBufferPreDelay = 0;
	else if(aRingBufferPreDelay>0x1fff)	aRingBufferPreDelay = 0x1fff;
	aRingBufferPreDelay &= 0x1fffe;
    [[[self undoManager] prepareWithInvocationTarget:self] setRingBufferPreDelay:ringBufferPreDelay];
    ringBufferPreDelay = aRingBufferPreDelay;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelRingBufferPreDelayChanged object:self];
}

- (int) ringBufferLen
{
    return ringBufferLen;
}

- (void) setRingBufferLen:(int)aRingBufferLen
{
	if(aRingBufferLen<0)			aRingBufferLen = 0;
	else if(aRingBufferLen>0xffff)	aRingBufferLen = 0xffff;
	aRingBufferLen &= 0xfff8;
    [[[self undoManager] prepareWithInvocationTarget:self] setRingBufferLen:ringBufferLen];
    ringBufferLen = aRingBufferLen;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelRingBufferLenChanged object:self];
}

- (int) gateSyncExtendLength
{
    return gateSyncExtendLength;
}

- (void) setGateSyncExtendLength:(int)aGateSyncExtendLength
{
	if(aGateSyncExtendLength<0)			aGateSyncExtendLength = 0;
	else if(aGateSyncExtendLength > 248)	aGateSyncExtendLength = 248;
    [[[self undoManager] prepareWithInvocationTarget:self] setGateSyncExtendLength:gateSyncExtendLength];
    gateSyncExtendLength = aGateSyncExtendLength;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelGateSyncExtendLengthChanged object:self];
}

- (int) gateSyncLimitLength
{
    return gateSyncLimitLength;
}

- (void) setGateSyncLimitLength:(int)aGateSyncLimitLength
{
	if(aGateSyncLimitLength<0)						aGateSyncLimitLength = 0;
	else if(aGateSyncLimitLength > powf(2.0,25)-8)	aGateSyncLimitLength = pow(2.0,25)-8;
    [[[self undoManager] prepareWithInvocationTarget:self] setGateSyncLimitLength:gateSyncLimitLength];
    gateSyncLimitLength = aGateSyncLimitLength;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelGateSyncLimitLengthChanged object:self];
}

- (long) maxNumEvents
{
    return maxNumEvents;
}

- (void) setMaxNumEvents:(long)aMaxNumEvents
{
	if(aMaxNumEvents<0)aMaxNumEvents=0;
	else if(aMaxNumEvents>kMaxNumEvents)aMaxNumEvents = kMaxNumEvents;
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxNumEvents:maxNumEvents];
    maxNumEvents = aMaxNumEvents;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelMaxNumEventsChanged object:self];
}

- (int) freqN;
{
    return freqN;
}

- (void) setFreqN:(int)aFreqN
{
	if(aFreqN < 0)   aFreqN = 0;
	else if(aFreqN>5)aFreqN = 5;
    [[[self undoManager] prepareWithInvocationTarget:self] setFreqN:freqN];
    freqN = aFreqN;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelFreqNChanged object:self];
}

- (int) freqM
{
    return freqM;
}

- (void) setFreqM:(int)aFreqM
{
	if(aFreqM < 0)   aFreqM = 0;
	else if(aFreqM>255)aFreqM = 255;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setFreqM:freqM];
    freqM = aFreqM;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelFreqMChanged object:self];
}

- (long) memoryStartModeLength
{
    return memoryStartModeLength;
}

- (void) setMemoryStartModeLength:(long)aMemoryStartModeLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMemoryStartModeLength:memoryStartModeLength];
    memoryStartModeLength = aMemoryStartModeLength;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelMemoryStartModeLengthChanged object:self];
}

- (long) memoryTriggerDelay
{
    return memoryTriggerDelay;
}

- (void) setMemoryTriggerDelay:(long)aMemoryTriggerDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMemoryTriggerDelay:memoryTriggerDelay];
    memoryTriggerDelay = aMemoryTriggerDelay;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelMemoryTriggerDelayChanged object:self];
}

- (BOOL) invertLemo
{
    return invertLemo;
}

- (void) setInvertLemo:(BOOL)aInvertLemo
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInvertLemo:invertLemo];
    invertLemo = aInvertLemo;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelInvertLemoChanged object:self];
}

- (BOOL) multiEvent
{
    return multiEvent;
}

- (void) setMultiEvent:(BOOL)aMultiEvent
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMultiEvent:multiEvent];
    multiEvent = aMultiEvent;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelMultiEventChanged object:self];
}

- (int) triggerMask
{
    return triggerMask;
}

- (void) setTriggerMask:(int)aTriggerMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerMask:triggerMask];
    triggerMask = aTriggerMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelTriggerMaskChanged object:self];
}

- (int) clockSource
{
    return clockSource;
}

- (void) setClockSource:(int)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = aClockSource;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelClockSourceChanged object:self];
}

- (int) operationMode
{
    return operationMode;
}

- (void) setOperationMode:(int)aOperationMode
{
	if(aOperationMode>=0 && aOperationMode<6){
		[[[self undoManager] prepareWithInvocationTarget:self] setOperationMode:operationMode];
		operationMode = aOperationMode;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelOperationModeChanged object:self];
	}
}

- (unsigned short) moduleID;
{
	return moduleID;
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
	 postNotificationName:ORSIS3350RateGroupChangedNotification
	 object:self];    
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
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
		if(counterTag>=0 && counterTag<kNumSIS3350Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

- (int) triggerMode:(short)chan	
{ 
	if(!triggerModes){
		triggerModes = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[triggerModes addObject:[NSNumber numberWithInt:0]];
    }
	return [[triggerModes objectAtIndex:chan] intValue]; 
}

- (void) setTriggerMode:(short)aChan withValue:(long)aValue	
{ 
	if(!triggerModes){
		triggerModes = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[triggerModes addObject:[NSNumber numberWithInt:0]];
    }
	if(aValue<0)aValue = 0;
	if(aValue>4)aValue = 4;
	[[[self undoManager] prepareWithInvocationTarget:self] setTriggerMode:aChan withValue:[self triggerMode:aChan]];
	[triggerModes replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelTriggerModeChanged object:self userInfo:userInfo];	
}

- (int) threshold:(short)aChan
{
	if(!thresholds){
		thresholds = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[thresholds addObject:[NSNumber numberWithInt:0]];
    }
    return [[thresholds objectAtIndex:aChan] intValue];
}

- (void) setThreshold:(short)aChan withValue:(int)aValue 
{ 
	if(!thresholds){
		thresholds = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[thresholds addObject:[NSNumber numberWithInt:0]];
    }
	if(aValue<0)aValue = 0;
	if(aValue>0x3FFF)aValue = 0x3FFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelThresholdChanged object:self userInfo:userInfo];
}

- (int) thresholdOff:(short)aChan
{
	if(!thresholdOffs){
		thresholdOffs = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[thresholdOffs addObject:[NSNumber numberWithInt:0]];
    }
    return [[thresholdOffs objectAtIndex:aChan] intValue];
}

- (void) setThresholdOff:(short)aChan withValue:(int)aValue 
{ 
	if(!thresholdOffs){
		thresholdOffs = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[thresholdOffs addObject:[NSNumber numberWithInt:0]];
    }
	if(aValue<0)aValue = 0;
	if(aValue>0x3FFF)aValue = 0x3FFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setThresholdOff:aChan withValue:[self thresholdOff:aChan]];
    [thresholdOffs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelThresholdOffChanged object:self userInfo:userInfo];
}


- (int) trigPulseLen:(short)aChan
{
	if(!trigPulseLens){
		trigPulseLens = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[trigPulseLens addObject:[NSNumber numberWithInt:0]];
    }
    return [[trigPulseLens objectAtIndex:aChan] intValue];
}

- (void) setTrigPulseLen:(short)aChan withValue:(int)aValue 
{ 
	if(!trigPulseLens){
		trigPulseLens = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[trigPulseLens addObject:[NSNumber numberWithInt:0]];
	}
	if(aValue<0)aValue = 0;
	if(aValue>0xff)aValue = 0xff;
	[[[self undoManager] prepareWithInvocationTarget:self] setTrigPulseLen:aChan withValue:[self trigPulseLen:aChan]];
	[trigPulseLens replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelTrigPulseLenChanged object:self userInfo:userInfo];
}

- (int) sumG:(short)aChan
{
	if(!sumGs)return 0;
    return [[sumGs objectAtIndex:aChan] intValue];
}

- (void) setSumG:(short)aChan withValue:(int)aValue
{
	if(!sumGs){
		sumGs = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[sumGs addObject:[NSNumber numberWithInt:0]];
	}
	if(aValue<0)aValue = 0;
	if(aValue>16)aValue = 16;
	[[[self undoManager] prepareWithInvocationTarget:self] setSumG:aChan withValue:[self sumG:aChan]];
	[sumGs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelSumGChanged object:self userInfo:userInfo];
}

- (int) peakingTime:(short)aChan
{
	if(!peakingTimes)return 0;
    return [[peakingTimes objectAtIndex:aChan] intValue];
}

- (void) setPeakingTime:(short)aChan withValue:(int)aValue
{
	if(!peakingTimes){
		peakingTimes = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[peakingTimes addObject:[NSNumber numberWithInt:0]];
	}
	if(aValue<0)aValue = 0;
	if(aValue>16)aValue = 16;
	[[[self undoManager] prepareWithInvocationTarget:self] setPeakingTime:aChan withValue:[self peakingTime:aChan]];
	[peakingTimes replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelPeakingTimeChanged object:self userInfo:userInfo];
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
	moduleID = result >> 16;
	unsigned short majorRev = (result >> 8) & 0xff;
	unsigned short minorRev = result & 0xff;
	if(verbose)NSLog(@"SIS3350 ID: %x  Firmware:%x.%x\n",moduleID,majorRev,minorRev);
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelIDChanged object:self];
}

- (float) readTemperature:(BOOL)verbose
{	
	unsigned long result = 0;
	[[self adapter] readLongBlock:&result
						atAddress:[self baseAddress] + kTemperatureRegister
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	float temperature = (float) ( ((result*9)/5) / 4.0)  ; 
	
	if(verbose)NSLog(@"SIS3350 Temperature:%.0f\n",temperature);
	return temperature;
}

- (void) initBoard
{  
	[self writeThresholds:NO];
	[self writeAdcMemoryPage:0];
	[self writeControlStatusRegister];
	[self writeAcquisitionRegister];
	[self writeFreqSynthRegister];
	[self writeValue:memoryTriggerDelay    offset:kDirectMemTriggerDelayReg];
	[self writeValue:memoryStartModeLength offset:kDirectMemStartModeLengthReg];
	[self writeValue:gateSyncLimitLength   offset:kGateSyncLimitLengthReg];
	[self writeValue:gateSyncExtendLength  offset:kGateSyncExtendLengthReg];
	[self writeValue:maxNumEvents          offset:kMaxNumEventsReg];
	[self writeRingBufferParams];
	[self writeValue:endAddressThreshold offset:kEndAddressThresholdAllDAC];
	[self writeTriggerSetupRegisters];
}


- (void) writeControlStatusRegister
{
	// The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.	
	unsigned long aMask = 0x0;
	
	aMask |= (invertLemo & 0x1)<<4;  //Invert Lemo trigger input
	aMask |= (ledOn		 & 0x1);
	//put the inverse in the top bits to turn off everything else
	aMask = ((~aMask & 0x0000ffff)<<16) | aMask;
	aMask &= ~0xffeeffee; //just leave the reserved bits zero
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeAcquisitionRegister
{
	// The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.	
	unsigned long aMask = 0x0;
	
	aMask |= (operationMode & 0x7);
	aMask |= (multiEvent    & 0x1)<<5;  //Multi-Event Mode
	aMask |= (triggerMask   & 0x1)<<6;  //internal trigger
	aMask |= (triggerMask   & 0x2)<<8;  //Lemo trigger
	aMask |= (triggerMask   & 0x4)<<9;  //LDVS trigger
	aMask |= (clockSource   & 0x3)<<12;
	
	
	//put the inverse in the top bits to turn off everything else
	aMask = ((~aMask & 0x0000ffff)<<16) | aMask;
	aMask &= ~~0xcc98cc98; //just leave the reserved bits zero
	
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kAcquisitionControlReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeFreqSynthRegister
{
	unsigned long aMask = 0x0;
	aMask |= (freqM & 0x1FF);
	aMask |= (freqN & 0x3) << 9;  
	
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kFrequencySynthReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (unsigned long) readAcqRegister
{
	unsigned long aValue;
	[[self adapter] readLongBlock:&aValue
                         atAddress:[self baseAddress] + kAcquisitionControlReg
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	return aValue;
}

- (unsigned long) readEventCounter
{
	unsigned long aValue;
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] + kEventCounterReg
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	return aValue;
}


- (void) writeAdcMemoryPage:(unsigned long)aPage
{
	[[self adapter] writeLongBlock:&aPage
						 atAddress:[self baseAddress] + kAdcMemoryPageRegister
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (long) gain:(int)aChannel
{
	//TDB 
	return 10;
}
- (long) dacValue:(int)aChannel
{
	//TDB 
	return 0;
}

- (void) writeGains
{
	int i;
	for(i=0;i<kNumSIS3350Channels;i++){
		unsigned long aGain = [self gain:i];
		[[self adapter] writeLongBlock:&aGain
							 atAddress:[self baseAddress] + adcGainOffsets[i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}	
}

- (void) writeDacOffsets
{
	unsigned long data, addr;
	unsigned int max_timeout, timeout_cnt;
	int i;
	for(i=0;i<kNumSIS3350Channels;i++){
		unsigned int dac_select_no = i%2;
		unsigned long module_dac_control_status_addr = baseAddress + (i<=1 ? kADC12DacControlStatus : kADC34DacControlStatus);
		data =  [self dacValue:i];
		addr = module_dac_control_status_addr + 4 ; // DAC_DATA
		[[self adapter] writeLongBlock:&data
							 atAddress:addr
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
		
		data =  1 + (dac_select_no << 4); // write to DAC Register
		addr = module_dac_control_status_addr ;
		[[self adapter] writeLongBlock:&data
							 atAddress:addr
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
		
		max_timeout = 5000 ;
		timeout_cnt = 0 ;
		addr = module_dac_control_status_addr  ;
		do {
			[[self adapter] readLongBlock:&data
								 atAddress:addr
								numToRead:1
								withAddMod:[self addressModifier]
							 usingAddSpace:0x01];
			timeout_cnt++;
		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"SIS3350 Failed programing the DAC offset for channel %d\n",i); 
			continue;
		}
		
		data =  2 + (dac_select_no << 4); // Load DACs 
		addr = module_dac_control_status_addr  ;
		[[self adapter] writeLongBlock:&data
							 atAddress:addr
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
		timeout_cnt = 0 ;
		addr = module_dac_control_status_addr  ;
		do {
			[[self adapter] readLongBlock:&data
								atAddress:addr
								numToRead:1
							   withAddMod:[self addressModifier]
							usingAddSpace:0x01];
			timeout_cnt++;
		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"SIS3350 Failed programing the DAC offset for channel %d\n",i); 
			continue;
		}
	}
}

- (void) writeSampleStartAddress:(unsigned long)aValue
{
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSampleStartAddressAll
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) writeValue:(unsigned long)aValue offset:(long)anOffset
{
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + anOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeRingBufferParams
{
	unsigned long aValue = ringBufferLen;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kRingbufferLengthRegisterAll
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	aValue = ringBufferPreDelay;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kRingbufferPreDelayRegisterAll
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}


- (void) writeTriggerSetupRegisters
{
	int i;
	for(i=0;i<kNumSIS3350Channels;i++){
		unsigned long aMask = 0x0;
		unsigned long triggerModeMask = 0x0;
		int triggerMode = [[triggerModes objectAtIndex:i]intValue];
		if (triggerMode == 0) {  triggerModeMask = 0 ; }
		if (triggerMode == 1) {  triggerModeMask = kTriggerEnabled ; }
		if (triggerMode == 2) {  triggerModeMask = kTriggerEnabled + kTriggerGtMode ; }
		if (triggerMode == 3) {  triggerModeMask = kTriggerEnabled + kFirTriggerMode ; }
		if (triggerMode == 4) {  triggerModeMask = kTriggerEnabled + kFirTriggerMode  + kTriggerGtMode; }
		aMask |= triggerMode;
		aMask |= ([self trigPulseLen:i] & 0xFF) << 16;
		aMask |= ([self sumG:i]         & 0x1F) <<  8;
		aMask |= ([self peakingTime:i]  & 0x1F) <<  0;
		
		[[self adapter] writeLongBlock:&aMask
							 atAddress:[self baseAddress] + triggerPulseRegOffsets[i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (unsigned long) readAcquisitionRegister
{
	unsigned long aValue = 0x0;
	[[self adapter] readLongBlock:&aValue
                         atAddress:[self baseAddress] + kAcquisitionControlReg
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	return aValue;
}

- (void) writeThresholds:(BOOL)verbose
{   
	int i;
	if(verbose) NSLog(@"Writing Thresholds:\n");
	for(i = 0; i < 4; i++) {
		unsigned long thresValue = (([[thresholdOffs objectAtIndex:i] longValue] & 0xfff) << 16) | ([[thresholds objectAtIndex:i] longValue] &0xfff);
		if(verbose) NSLog(@"%d: 0x%04x \n",i, thresValue );
		[[self adapter] writeLongBlock:&thresValue
							 atAddress:[self baseAddress] + thresholdRegOffsets[i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
		
	}
}

- (void) checkEventStatus
{
	unsigned long acqStatus = [self readAcqRegister];
	NSLog(@"Acq Busy: %@\n",((acqStatus&kAcqStatusBusyFlag)==kAcqStatusBusyFlag)?@"YES":@"NO");
	NSLog(@"End Address Threshold Flag: %@\n",((acqStatus&kAcqStatusEndAddressFlag)==kAcqStatusEndAddressFlag)?@"Set":@"Clear");
	NSLog(@"Armed: %@\n",((acqStatus&kAcqStatusArmedFlag)==kAcqStatusArmedFlag)?@"YES":@"NO");
	int i;
	for(i=0;i<4;i++){
		unsigned long aValue;
		[[self adapter] readLongBlock: &aValue
							atAddress: [self baseAddress] + actualSampleAddressOffsets[i]
							numToRead: 1
						   withAddMod: [self addressModifier]
						usingAddSpace: 0x01];
		
		NSLog(@"Address Counter %d: 0x%08x\n",i,aValue );
	}
}

- (void) printReport
{   
	NSLog(@"----------------------------\n");
	NSLog(@"Chan Thresholds   Thresholds\n");
	NSLog(@"               OFF               ON   \n");
	int i;
	for(i =0; i < 4; i++) {
		unsigned long aThreshold;
		[[self adapter] readLongBlock: &aThreshold
							atAddress: [self baseAddress] + thresholdRegOffsets[i]
							numToRead: 1
						   withAddMod: [self addressModifier]
						usingAddSpace: 0x01];
		
		NSLog(@"%d           0x%04x         0x%04x\n",i,(aThreshold&0x0fff0000)>>16, aThreshold&0x0fff);
	}
	NSLog(@"----------------------------\n");
	unsigned long aValue = [self readAcqRegister];;
	NSLog(@"Status Mode: 0x%x\n",aValue & 0x7);
	NSLog(@"MultiEvent: 0x%x\n",(aValue>>5) & 0x1);
	NSLog(@"Internal Triggers: 0x%x\n",(aValue>>6) & 0x1);
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
								 @"ORSIS3350WaveformDecoder",            @"decoder",
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
    return kNumSIS3350Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
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
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORSIS3350Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORSIS3350Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:@"Threshold"])return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else return nil;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3350Model"];    
        
    [self startRates];
	//cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
	ledOn = YES;
	firstTime = NO;
	switch(operationMode){
		case kOperationRingBufferAsync:			[self runTaskStartedRingbufferASynchMode:aDataPacket		userInfo:userInfo];	break;
		case kOperationRingBufferSync:			[self runTaskStartedRingbufferSynchMode:aDataPacket			userInfo:userInfo];	break;
		case kOperationDirectMemoryGateAsync:	[self runTaskStartedDirectMemoryGateASyncMode:aDataPacket	userInfo:userInfo];	break;
		case kOperationDirectMemoryGateSync:	[self runTaskStartedDirectMemoryGateSyncMode:aDataPacket	userInfo:userInfo];	break;
		case kOperationDirectMemoryStop:		[self runTaskStartedDirectMemoryStopMode:aDataPacket		userInfo:userInfo];	break;
		case kOperationDirectMemoryStart:		[self runTaskStartedDirectMemoryStartMode:aDataPacket		userInfo:userInfo];	break;
	}
	
	
	if(!moduleID)[self readModuleID:NO];
		
	//test....
	[self writeSampleStartAddress:0x0];
	[self armSamplingLogic];

	
	isRunning = NO;
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    @try {	
		switch(operationMode){
			case kOperationRingBufferAsync:			[self takeDataRingbufferASynchMode:(ORDataPacket*)aDataPacket		userInfo:(id)userInfo];	break;
			case kOperationRingBufferSync:			[self takeDataRingbufferSynchMode:(ORDataPacket*)aDataPacket		userInfo:(id)userInfo];	break;
			case kOperationDirectMemoryGateAsync:	[self takeDataDirectMemoryGateASyncMode:(ORDataPacket*)aDataPacket	userInfo:(id)userInfo];	break;
			case kOperationDirectMemoryGateSync:	[self takeDataDirectMemoryGateSyncMode:(ORDataPacket*)aDataPacket	userInfo:(id)userInfo];	break;
			case kOperationDirectMemoryStop:		[self takeDataDirectMemoryStopMode:(ORDataPacket*)aDataPacket		userInfo:(id)userInfo];	break;
			case kOperationDirectMemoryStart:		[self takeDataDirectMemoryStartMode:(ORDataPacket*)aDataPacket		userInfo:(id)userInfo];	break;
		}
	}
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	ledOn = NO;
	[self writeControlStatusRegister];
	
	[self disarmSamplingLogic];
	isRunning = NO;
    [waveFormRateGroup stop];
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kSIS3350; //should be unique
	configStruct->card_info[index].hw_mask[0]				= dataId; //better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= [self addressModifier];
	configStruct->card_info[index].base_add					= [self baseAddress];
    //configStruct->card_info[index].deviceSpecificData[0]	= bankSwitchMode;
    //configStruct->card_info[index].deviceSpecificData[1]	= [self numberOfSamples];
	configStruct->card_info[index].deviceSpecificData[2]	= moduleID;
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

- (void) reset
{
	unsigned long aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						atAddress: [self baseAddress] + kResetRegister
						numToWrite: 1
					   withAddMod: [self addressModifier]
					usingAddSpace: 0x01];
	
}

- (void) armSamplingLogic
{
	unsigned long aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						atAddress: [self baseAddress] + kArmSamplingLogicRegister
						numToWrite: 1
					   withAddMod: [self addressModifier]
					usingAddSpace: 0x01];
	
}

- (void) disarmSamplingLogic
{
	unsigned long aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						atAddress: [self baseAddress] + kDisarmSamplingLogicRegister
						numToWrite: 1
					   withAddMod: [self addressModifier]
					usingAddSpace: 0x01];
	
}

- (void) fireTrigger
{
	unsigned long aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						atAddress: [self baseAddress] + kVMETriggerRegister
						numToWrite: 1
					   withAddMod: [self addressModifier]
					usingAddSpace: 0x01];
	
}

- (void) clearTimeStamps;
{
	unsigned long aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						atAddress: [self baseAddress] + kTimeStampClearRegister
						numToWrite: 1
					   withAddMod: [self addressModifier]
					usingAddSpace: 0x01];
	
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
    for(i=0;i<kNumSIS3350Channels;i++){
        waveFormCount[i]=0;
    }
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setMemoryWrapLength:		[decoder decodeInt32ForKey:@"memoryWrapLength"]];
    [self setEndAddressThreshold:	[decoder decodeIntForKey:@"endAddressThreshold"]];
    [self setRingBufferPreDelay:	[decoder decodeIntForKey:@"ringBufferPreDelay"]];
    [self setRingBufferLen:			[decoder decodeIntForKey:@"ringBufferLen"]];
    [self setGateSyncExtendLength:[decoder decodeIntForKey:@"gateSyncExtendLength"]];
    [self setGateSyncLimitLength:	[decoder decodeIntForKey:@"gateSyncLimitLength"]];
    [self setMaxNumEvents:			[decoder decodeInt32ForKey:@"maxNumEvents"]];
    [self setFreqN:					[decoder decodeIntForKey:@"freqN"]];
    [self setFreqM:					[decoder decodeIntForKey:@"freqM"]];
    [self setMemoryStartModeLength:	[decoder decodeInt32ForKey:@"memoryStartModeLength"]];
    [self setMemoryTriggerDelay:	[decoder decodeInt32ForKey:@"memoryTriggerDelay"]];
    [self setInvertLemo:			[decoder decodeBoolForKey:@"invertLemo"]];
    [self setMultiEvent:			[decoder decodeBoolForKey:@"multiEvent"]];
    [self setTriggerMask:			[decoder decodeIntForKey:@"triggerMask"]];
    [self setClockSource:			[decoder decodeIntForKey:@"clockSource"]];
    [self setOperationMode:			[decoder decodeIntForKey:@"operationMode"]];
 	
	triggerModes	= [[decoder decodeObjectForKey:@"triggerMode"] retain];
	peakingTimes	= [[decoder decodeObjectForKey:@"peakingTimes"] retain];
	thresholds		= [[decoder decodeObjectForKey:@"thresholds"] retain];
	thresholdOffs	= [[decoder decodeObjectForKey:@"thresholdOffs"] retain];
	sumGs			= [[decoder decodeObjectForKey:@"sumGs"] retain];
	trigPulseLens	= [[decoder decodeObjectForKey:@"trigPulseLens"] retain];
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt32:memoryWrapLength		forKey:@"memoryWrapLength"];
    [encoder encodeInt:endAddressThreshold		forKey:@"endAddressThreshold"];
    [encoder encodeInt:ringBufferPreDelay		forKey:@"ringBufferPreDelay"];
    [encoder encodeInt:ringBufferLen			forKey:@"ringBufferLen"];
    [encoder encodeInt:gateSyncExtendLength	forKey:@"gateSyncExtendLength"];
    [encoder encodeInt:gateSyncLimitLength	forKey:@"gateSyncLimitLength"];
    [encoder encodeInt32:maxNumEvents			forKey:@"maxNumEvents"];
    [encoder encodeInt:freqN					forKey:@"freqN"];
    [encoder encodeInt:freqM					forKey:@"freqM"];
    [encoder encodeInt32:memoryStartModeLength	forKey:@"memoryStartModeLength"];
    [encoder encodeInt32:memoryTriggerDelay		forKey:@"memoryTriggerDelay"];
    [encoder encodeBool:invertLemo				forKey:@"invertLemo"];
    [encoder encodeBool:multiEvent				forKey:@"multiEvent"];
    [encoder encodeInt:triggerMask				forKey:@"triggerMask"];
    [encoder encodeInt:clockSource				forKey:@"clockSource"];
    [encoder encodeInt:operationMode			forKey:@"operationMode"];
    [encoder encodeObject:thresholds			forKey:@"thresholds"];
    [encoder encodeObject:thresholdOffs			forKey:@"thresholdOffs"];
    [encoder encodeObject:peakingTimes			forKey:@"peakingTimes"];
    [encoder encodeObject:sumGs					forKey:@"sumGs"];
    [encoder encodeObject:trigPulseLens			forKey:@"trigPulseLens"];
    [encoder encodeObject:triggerModes			forKey:@"triggerMode"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:thresholds			forKey:@"thresholds"];	
    [objDictionary setObject:thresholdOffs		forKey:@"thresholdOffs"];	
    return objDictionary;
}

@end
@implementation ORSIS3350Model (private)
- (void) runTaskStartedRingbufferSynchMode:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[self reset];
	[self initBoard];
}

- (void) takeDataRingbufferSynchMode:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if(!firstTime){
		unsigned long status = [self readAcqRegister];
		if((status & kAcqStatusArmedFlag) != kAcqStatusArmedFlag){
			
			// Read Stop Sample (Address) Counters
			unsigned long stop_next_sample_addr[kNumSIS3350Channels] ;
			int i;
			for(i=0;i<kNumSIS3350Channels;i++){
				[[self adapter] readLongBlock:&stop_next_sample_addr[i]
									atAddress:[self baseAddress] + actualSampleAddressOffsets[i]
									numToRead:1
								   withAddMod:[self addressModifier]
								usingAddSpace:0x01];
			
				if (stop_next_sample_addr[i] > (2*kMaxAdcBufferLength))  {
					NSLogError(@"SIS3350 Exception",@"Data Read_out",@"Sample size too large",nil);
					return;
				}
				if (stop_next_sample_addr[i] != 0) {
					[self readAndShip:aDataPacket channel:i sampleStartAddress:0x0 sampleLength:stop_next_sample_addr[i]];
					 
				}
			}
			[self armSamplingLogic];
		}
	}
	else {
		firstTime = NO;
		[self armSamplingLogic];
	}
} 

- (void) runTaskStartedRingbufferASynchMode:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[self reset];
	[self initBoard];
}

- (void) takeDataRingbufferASynchMode:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if(!firstTime){
		unsigned long status = [self readAcqRegister];
		if((status & kAcqStatusEndAddressFlag) == kAcqStatusEndAddressFlag){
			[self disarmSamplingLogic];
			int i;
			for(i=0;i<kNumSIS3350Channels;i++){
				unsigned long stop_next_sample_addr[kNumSIS3350Channels] ;
				[[self adapter] readLongBlock:&stop_next_sample_addr[i]
									atAddress:[self baseAddress] + actualSampleAddressOffsets[i]
									numToRead:1
								   withAddMod:[self addressModifier]
								usingAddSpace:0x01];
				
				if (stop_next_sample_addr[i] > (2*kMaxAdcBufferLength))  {
					NSLogError(@"SIS3350 Exception",@"Data Read_out",@"Sample size too large",nil);
					return;
				}
				//if (stop_next_sample_addr[i] != 0) {
					[self readAndShip:aDataPacket channel:i sampleStartAddress:0x0 sampleLength:10000];
				//}
			}
			[self armSamplingLogic];
		}
	}
	else {
		firstTime = NO;
		[self clearTimeStamps];
		[self armSamplingLogic];
	}
	
}

- (void) runTaskStartedDirectMemoryGateASyncMode:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[self reset];
	[self initBoard];
}

- (void) takeDataDirectMemoryGateASyncMode:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if(!firstTime){
		unsigned long status = [self readAcqRegister];
		if((status & kAcqStatusEndAddressFlag) == kAcqStatusEndAddressFlag){
			[self disarmSamplingLogic];
			int i;
			for(i=0;i<kNumSIS3350Channels;i++){
				unsigned long stop_next_sample_addr[kNumSIS3350Channels] ;
				[[self adapter] readLongBlock:&stop_next_sample_addr[i]
									atAddress:[self baseAddress] + actualSampleAddressOffsets[i]
									numToRead:1
								   withAddMod:[self addressModifier]
								usingAddSpace:0x01];
				
				if (stop_next_sample_addr[i] > (2*kMaxAdcBufferLength))  {
					NSLogError(@"SIS3350 Exception",@"Data Read_out",@"Sample size too large",nil);
					return;
				}
				if (stop_next_sample_addr[i] != 0) {
					[self readAndShip:aDataPacket channel:i sampleStartAddress:0x0 sampleLength:stop_next_sample_addr[i]];
				}
			}
		}
	}
	else {
		firstTime = NO;
		[self clearTimeStamps];
		[self armSamplingLogic];
	}
}

- (void) runTaskStartedDirectMemoryGateSyncMode:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[self reset];
	[self initBoard];
}

- (void) takeDataDirectMemoryGateSyncMode:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if(!firstTime){
		unsigned long status = [self readAcqRegister];
		if((status & kAcqStatusArmedFlag) != kAcqStatusArmedFlag){
			[self disarmSamplingLogic];
			int i;
			for(i=0;i<kNumSIS3350Channels;i++){
				unsigned long stop_next_sample_addr[kNumSIS3350Channels] ;
				[[self adapter] readLongBlock:&stop_next_sample_addr[i]
									atAddress:[self baseAddress] + actualSampleAddressOffsets[i]
									numToRead:1
								   withAddMod:[self addressModifier]
								usingAddSpace:0x01];
				
				if (stop_next_sample_addr[i] > (2*kMaxAdcBufferLength))  {
					NSLogError(@"SIS3350 Exception",@"Data Read_out",@"Sample size too large",nil);
					return;
				}
				if (stop_next_sample_addr[i] != 0) {
					[self readAndShip:aDataPacket channel:i sampleStartAddress:0x0 sampleLength:stop_next_sample_addr[i]];
				}
			}
			[self armSamplingLogic];
		}
	}
	else {
		firstTime = NO;
		[self clearTimeStamps];
		[self armSamplingLogic];
	}
}
- (void) runTaskStartedDirectMemoryStartMode:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[self reset];
	[self initBoard];
}

- (void) takeDataDirectMemoryStartMode:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if(!firstTime){
		unsigned long status = [self readAcqRegister];
		if((status & kAcqStatusArmedFlag) != kAcqStatusArmedFlag){
			int i;
			for(i=0;i<kNumSIS3350Channels;i++){
				unsigned long stop_next_sample_addr[kNumSIS3350Channels] ;
				[[self adapter] readLongBlock:&stop_next_sample_addr[i]
									atAddress:[self baseAddress] + actualSampleAddressOffsets[i]
									numToRead:1
								   withAddMod:[self addressModifier]
								usingAddSpace:0x01];
				
				if (stop_next_sample_addr[i] > (2*kMaxAdcBufferLength))  {
					NSLogError(@"SIS3350 Exception",@"Data Read_out",@"Sample size too large",nil);
					return;
				}
				if (stop_next_sample_addr[i] != 0) {
					[self readAndShip:aDataPacket channel:i sampleStartAddress:0x0 sampleLength:stop_next_sample_addr[i]];
				}
			}
			[self armSamplingLogic];
		}
	}
	else {
		firstTime = NO;
		[self clearTimeStamps];
		[self armSamplingLogic];
	}
}

- (void) runTaskStartedDirectMemoryStopMode:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[self reset];
	[self initBoard];
}

- (void) takeDataDirectMemoryStopMode:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if(!firstTime){
		unsigned long status = [self readAcqRegister];
		if((status & kAcqStatusArmedFlag) != kAcqStatusArmedFlag){
			[self disarmSamplingLogic];
			int i;
			for(i=0;i<kNumSIS3350Channels;i++){
				unsigned long stop_next_sample_addr[kNumSIS3350Channels] ;
				[[self adapter] readLongBlock:&stop_next_sample_addr[i]
									atAddress:[self baseAddress] + actualSampleAddressOffsets[i]
									numToRead:1
								   withAddMod:[self addressModifier]
								usingAddSpace:0x01];
				
				if (stop_next_sample_addr[i] > (2*kMaxAdcBufferLength))  {
					NSLogError(@"SIS3350 Exception",@"Data Read_out",@"Sample size too large",nil);
					return;
				}
				unsigned int nof_events = [self readEventCounter];
				unsigned int calculated_stop_next_sample_address = nof_events   * (memoryWrapLength + 8) ;
				if (stop_next_sample_addr[i] != calculated_stop_next_sample_address) {
					[self readAndShip:aDataPacket channel:i sampleStartAddress:0x0 sampleLength:stop_next_sample_addr[i]];
				}
			}
		}
	}
	else {
		firstTime = NO;
		[self clearTimeStamps];
		[self armSamplingLogic];
	}
}


- (void) readAndShip:(ORDataPacket*)aDataPacket
			 channel:(unsigned int) aChannel 
			 sampleStartAddress:(unsigned int) aBufferSampleStartAddress 
				   sampleLength:(unsigned int) aBufferSampleLength
{
	
	unsigned int max_page_sample_length       = kMaxPageSampleLength ; // 0x800000 ;	  // 8 MSample , 16 MByte		VME: 0x0 - 0x0100 0000
	unsigned int page_sample_length_mask      = max_page_sample_length - 1 ;
	unsigned int next_event_sample_start_addr =  (aBufferSampleStartAddress &  0x07fffffc); // max 128 MSample  256MByte
	unsigned int rest_event_sample_length     =  (aBufferSampleLength & 0xfffffffc);
	
	if (rest_event_sample_length  >= kMaxSampleLength) {
		rest_event_sample_length =  kMaxSampleLength;
	}    // 0x8000000 max 128 MSample  
		
	unsigned int sub_event_sample_addr      =  (next_event_sample_start_addr & page_sample_length_mask) ;
	unsigned int sub_max_page_sample_length =  max_page_sample_length - sub_event_sample_addr ;
	
	unsigned int sub_event_sample_length ;
	if (rest_event_sample_length >= sub_max_page_sample_length) sub_event_sample_length = sub_max_page_sample_length;
	else														sub_event_sample_length = rest_event_sample_length; //sub_event_sample_addr

	unsigned int sub_page_addr_offset       =  (next_event_sample_start_addr >> 23) & 0xf ;
	unsigned int dma_request_nof_lwords     =  sub_event_sample_length/2;	// Lwords
	unsigned int dma_adc_addr_offset_bytes  =  sub_event_sample_addr*2;		// Bytes
	
	[self writeAdcMemoryPage:sub_page_addr_offset];   // set page
		
	unsigned int req_nof_lwords = dma_request_nof_lwords ; //   
	NSMutableData* theData = [NSMutableData dataWithLength:req_nof_lwords*sizeof(long) + 4 + 4]; //data + ORCA header
	unsigned long* dataPtr = (unsigned long*)[theData bytes];
	dataPtr[0] = dataId | req_nof_lwords + 2;
	dataPtr[1] = location | aChannel;
		
	[theController readLongBlock:&dataPtr[2]
						atAddress: baseAddress + adcOffsets[aChannel] + dma_adc_addr_offset_bytes
						numToRead:req_nof_lwords
					   withAddMod:0x09
					usingAddSpace:0x01];
	[aDataPacket addData:theData];
			
}
@end
