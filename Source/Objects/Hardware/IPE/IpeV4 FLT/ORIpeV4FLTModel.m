//
//  ORIpeV4FLTModel.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORIpeV4FLTModel.h"
#import "ORIpeV4SLTModel.h"
#import "ORIpeCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORDataTypeAssigner.h"
#import "ORTimeRate.h"
#import "ORTest.h"
#import "SBC_Config.h"
#import "SLTv4_HW_Definitions.h"

NSString* ORIpeV4FLTModelRunBoxCarFilterChanged		= @"ORIpeV4FLTModelRunBoxCarFilterChanged";
NSString* ORIpeV4FLTModelStoreDataInRamChanged		= @"ORIpeV4FLTModelStoreDataInRamChanged";
NSString* ORIpeV4FLTModelFilterLengthChanged		= @"ORIpeV4FLTModelFilterLengthChanged";
NSString* ORIpeV4FLTModelGapLengthChanged			= @"ORIpeV4FLTModelGapLengthChanged";
NSString* ORIpeV4FLTModelHistNofMeasChanged			= @"ORIpeV4FLTModelHistNofMeasChanged";
NSString* ORIpeV4FLTModelHistMeasTimeChanged		= @"ORIpeV4FLTModelHistMeasTimeChanged";
NSString* ORIpeV4FLTModelHistRecTimeChanged			= @"ORIpeV4FLTModelHistRecTimeChanged";
NSString* ORIpeV4FLTModelPostTriggerTimeChanged		= @"ORIpeV4FLTModelPostTriggerTimeChanged";
NSString* ORIpeV4FLTModelFifoBehaviourChanged		= @"ORIpeV4FLTModelFifoBehaviourChanged";
NSString* ORIpeV4FLTModelAnalogOffsetChanged		= @"ORIpeV4FLTModelAnalogOffsetChanged";
NSString* ORIpeV4FLTModelLedOffChanged				= @"ORIpeV4FLTModelLedOffChanged";
NSString* ORIpeV4FLTModelInterruptMaskChanged		= @"ORIpeV4FLTModelInterruptMaskChanged";
NSString* ORIpeV4FLTModelTModeChanged				= @"ORIpeV4FLTModelTModeChanged";
NSString* ORIpeV4FLTModelHitRateLengthChanged		= @"ORIpeV4FLTModelHitRateLengthChanged";
NSString* ORIpeV4FLTModelTriggersEnabledChanged		= @"ORIpeV4FLTModelTriggersEnabledChanged";
NSString* ORIpeV4FLTModelGainsChanged				= @"ORIpeV4FLTModelGainsChanged";
NSString* ORIpeV4FLTModelThresholdsChanged			= @"ORIpeV4FLTModelThresholdsChanged";
NSString* ORIpeV4FLTModelModeChanged				= @"ORIpeV4FLTModelModeChanged";
NSString* ORIpeV4FLTSettingsLock					= @"ORIpeV4FLTSettingsLock";
NSString* ORIpeV4FLTChan							= @"ORIpeV4FLTChan";
NSString* ORIpeV4FLTModelTestPatternsChanged		= @"ORIpeV4FLTModelTestPatternsChanged";
NSString* ORIpeV4FLTModelGainChanged				= @"ORIpeV4FLTModelGainChanged";
NSString* ORIpeV4FLTModelThresholdChanged			= @"ORIpeV4FLTModelThresholdChanged";
NSString* ORIpeV4FLTModelTriggerEnabledMaskChanged	= @"ORIpeV4FLTModelTriggerEnabledMaskChanged";
NSString* ORIpeV4FLTModelHitRateEnabledMaskChanged	= @"ORIpeV4FLTModelHitRateEnabledMaskChanged";
NSString* ORIpeV4FLTModelHitRateChanged				= @"ORIpeV4FLTModelHitRateChanged";
NSString* ORIpeV4FLTModelTestsRunningChanged		= @"ORIpeV4FLTModelTestsRunningChanged";
NSString* ORIpeV4FLTModelTestEnabledArrayChanged	= @"ORIpeV4FLTModelTestEnabledChanged";
NSString* ORIpeV4FLTModelTestStatusArrayChanged		= @"ORIpeV4FLTModelTestStatusChanged";
NSString* ORIpeV4FLTModelEventMaskChanged			= @"ORIpeV4FLTModelEventMaskChanged";
NSString* ORIpeV4FLTModelReadoutPagesChanged		= @"ORIpeV4FLTModelReadoutPagesChanged"; // ak, 2.7.07

NSString* ORIpeV4FLTSelectedRegIndexChanged			= @"ORIpeV4FLTSelectedRegIndexChanged";
NSString* ORIpeV4FLTWriteValueChanged				= @"ORIpeV4FLTWriteValueChanged";
NSString* ORIpeV4FLTSelectedChannelValueChanged		= @"ORIpeV4FLTSelectedChannelValueChanged";

static NSString* fltTestName[kNumIpeV4FLTTests]= {
	@"Run Mode",
	@"Ram",
	@"Threshold/Gain",
	@"Speed",
	@"Event",
};

// data for low-level page (IPE V4 electronic definitions)
enum IpeFLTV4Enum{
	kFLTV4StatusReg,
	kFLTV4ControlReg,
	kFLTV4CommandReg,
	kFLTV4VersionReg,
	kFLTV4pVersionReg,
	kFLTV4BoardIDLsbReg,
	kFLTV4BoardIDMsbReg,
	kFLTV4InterruptMaskReg,
	kFLTV4HrMeasEnableReg,
	kFLTV4EventFifoStatusReg,
	kFLTV4PixelSettings1Reg,
	kFLTV4PixelSettings2Reg,
	kFLTV4RunControlReg,
	kFLTV4HistgrSettingsReg,
	kFLTV4AccessTestReg,
	kFLTV4SecondCounterReg,
	kFLTV4HrControlReg,
	kFLTV4HistMeasTimeReg,
	kFLTV4HistRecTimeReg,
	kFLTV4HistNumMeasReg,
	kFLTV4ThresholdReg,
	kFLTV4pStatusA,
	kFLTV4pStatusB,
	kFLTV4pStatusC,
	kFLTV4PostTrigger,
	kFLTV4AnalogOffset,
	kFLTV4GainReg,
	kFLTV4HitRateReg,
	kFLTV4EventFifo1Reg,
	kFLTV4EventFifo2Reg,
	kFLTV4EventFifo3Reg,
	kFLTV4EventFifo4Reg,
	kFLTV4NumRegs //must be last
};

static IpeRegisterNamesStruct regV4[kFLTV4NumRegs] = {
	//2nd column is PCI register address shifted 2 bits to right (the two rightmost bits are always zero) -tb-
	{@"Status",				0x000000>>2,		-1,				kIpeRegReadable},
	{@"Control",			0x000004>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"Command",			0x000008>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"CFPGAVersion",		0x00000c>>2,		-1,				kIpeRegReadable},
	{@"FPGA8Version",		0x000010>>2,		-1,				kIpeRegReadable},
	{@"BoardIDLSB",         0x000014>>2,		-1,				kIpeRegReadable},
	{@"BoardIDMSB",         0x000018>>2,		-1,				kIpeRegReadable},
	{@"InterruptMask",      0x00001C>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HrMeasEnable",       0x000024>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"EventFifoStatus",    0x00002C>>2,		-1,				kIpeRegReadable},
	{@"PixelSettings1",     0x000030>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"PixelSettings2",     0x000034>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"RunControl",         0x000038>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HistgrSettings",     0x00003c>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"AccessTest",         0x000040>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"SecondCounter",      0x000044>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HrControl",          0x000048>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HistMeasTime",       0x00004C>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HistRecTime",        0x000050>>2,		-1,				kIpeRegReadable},
	{@"HistNumMeas",         0x000054>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"Threshold",          0x002080>>2,		-1,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},
	{@"pStatusA",           0x002000>>2,		-1,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},
	{@"pStatusB",           0x00A000>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"pStatusC",           0x02A000>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"PostTrigger",		0x000058>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"Analog Offset",		0x001000>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"Gain",				0x001004>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"Hit Rate",			0x001100>>2,		-1,				kIpeRegReadable | kIpeRegNeedsChannel},
	{@"Event FIFO1",		0x001800>>2,		-1,				kIpeRegReadable},
	{@"Event FIFO2",		0x001804>>2,		-1,				kIpeRegReadable},
	{@"Event FIFO3",		0x001808>>2,		-1,				kIpeRegReadable},
	{@"Event FIFO4",		0x00180C>>2,		-1,				kIpeRegReadable},
};

@interface ORIpeV4FLTModel (private)
- (NSAttributedString*) test:(int)testName result:(NSString*)string color:(NSColor*)aColor;
- (void) enterTestMode;
- (void) leaveTestMode;
@end

@implementation ORIpeV4FLTModel

- (id) init
{
    self = [super init];
	ledOff = YES;
    return self;
}

- (void) dealloc
{	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [testEnabledArray release];
    [testStatusArray release];
	[testSuit release];
	[thresholds release];
	[gains release];
	[totalRate release];
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"IpeV4FLTCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORIpeV4FLTController"];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORIpeV4CrateModel");
}

- (BOOL) partOfEvent:(short)chan
{
	return (eventMask & (1L<<chan)) != 0;
}

- (ORTimeRate*) totalRate { return totalRate; }
- (short) getNumberRegisters{ return kFLTV4NumRegs; }

#pragma mark •••Accessors

- (BOOL) runBoxCarFilter { return runBoxCarFilter; }
- (void) setRunBoxCarFilter:(BOOL)aRunBoxCarFilter
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunBoxCarFilter:runBoxCarFilter];
    runBoxCarFilter = aRunBoxCarFilter;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelRunBoxCarFilterChanged object:self];
}

- (BOOL) storeDataInRam { return storeDataInRam; }
- (void) setStoreDataInRam:(BOOL)aStoreDataInRam
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStoreDataInRam:storeDataInRam];
    storeDataInRam = aStoreDataInRam;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelStoreDataInRamChanged object:self];
}

- (int) filterLength { return filterLength; }
- (void) setFilterLength:(int)aFilterLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFilterLength:filterLength];
    filterLength = [self restrictIntValue:aFilterLength min:2 max:15];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelFilterLengthChanged object:self];
}

- (int) gapLength { return gapLength; }
- (void) setGapLength:(int)aGapLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGapLength:gapLength];
    gapLength = [self restrictIntValue:aGapLength min:0 max:7];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelGapLengthChanged object:self];
}

- (unsigned long) histNofMeas { return histNofMeas; }
- (void) setHistNofMeas:(unsigned long)aHistNofMeas
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistNofMeas:histNofMeas];
    histNofMeas = aHistNofMeas;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistNofMeasChanged object:self];
}

- (unsigned long) histMeasTime { return histMeasTime; }
- (void) setHistMeasTime:(unsigned long)aHistMeasTime
{
    histMeasTime = aHistMeasTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistMeasTimeChanged object:self];
}

- (unsigned long) histRecTime { return histRecTime; }
- (void) setHistRecTime:(unsigned long)aHistRecTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistRecTime:histRecTime];
    histRecTime = aHistRecTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHistRecTimeChanged object:self];
}

- (unsigned long) postTriggerTime { return postTriggerTime; }
- (void) setPostTriggerTime:(unsigned long)aPostTriggerTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerTime:postTriggerTime];
    postTriggerTime = aPostTriggerTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelPostTriggerTimeChanged object:self];
}

- (int) fifoBehaviour { return fifoBehaviour; }
- (void) setFifoBehaviour:(int)aFifoBehaviour
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFifoBehaviour:fifoBehaviour];
    fifoBehaviour = aFifoBehaviour;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelFifoBehaviourChanged object:self];
}

- (unsigned long) eventMask { return eventMask; }
- (void) eventMask:(unsigned long)aMask
{
	eventMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelEventMaskChanged object:self];
}

- (int) analogOffset{ return analogOffset; }
- (void) setAnalogOffset:(int)aAnalogOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAnalogOffset:analogOffset];
    analogOffset = aAnalogOffset;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelAnalogOffsetChanged object:self];
}

- (BOOL) ledOff{ return ledOff; }
- (void) setLedOff:(BOOL)aState
{
    ledOff = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelLedOffChanged object:self];
}

- (unsigned long) interruptMask { return interruptMask; }
- (void) setInterruptMask:(unsigned long)aInterruptMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    interruptMask = aInterruptMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelInterruptMaskChanged object:self];
}

- (void) setTotalRate:(ORTimeRate*)newTimeRate
{
	[totalRate autorelease];
	totalRate=[newTimeRate retain];
}

- (unsigned short) hitRateLength { return hitRateLength; }
- (void) setHitRateLength:(unsigned short)aHitRateLength
{	
    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateLength:hitRateLength];
    hitRateLength = [self restrictIntValue:aHitRateLength min:0 max:6]; //0->1sec, 1->2, 2->4 .... 6->32sec
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHitRateLengthChanged object:self];
}

- (unsigned long) triggerEnabledMask { return triggerEnabledMask; } 
- (void) setTriggerEnabledMask:(unsigned long)aMask
{
    triggerEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelTriggerEnabledMaskChanged object:self];
}

- (unsigned long) hitRateEnabledMask { return hitRateEnabledMask; }
- (void) setHitRateEnabledMask:(unsigned long)aMask
{
    hitRateEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHitRateEnabledMaskChanged object:self];
}

- (NSMutableArray*) gains { return gains; }
- (void) setGains:(NSMutableArray*)aGains
{
	[aGains retain];
	[gains release];
    gains = aGains;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelGainsChanged object:self];
}

- (NSMutableArray*) thresholds { return thresholds; }
- (void) setThresholds:(NSMutableArray*)aThresholds
{
	[aThresholds retain];
	[thresholds release];
    thresholds = aThresholds;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelThresholdsChanged object:self];
}

-(unsigned short) threshold:(unsigned short) aChan
{
    return [[thresholds objectAtIndex:aChan] shortValue];
}

-(unsigned short) gain:(unsigned short) aChan
{
    return [[gains objectAtIndex:aChan] shortValue];
}

-(void) setThreshold:(unsigned short) aChan withValue:(unsigned short) aThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
	if(aThreshold>32000)aThreshold = 32000;
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aThreshold]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORIpeV4FLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIpeV4FLTModelThresholdChanged
	 object:self
	 userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain
{
	if(aGain>255)aGain = 255;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:aChan withValue:[self gain:aChan]];
	[gains replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aGain]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORIpeV4FLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIpeV4FLTModelGainChanged
	 object:self
	 userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

-(BOOL) triggerEnabled:(unsigned short) aChan
{
	if(aChan<22)return (triggerEnabledMask >> aChan) & 0x1;
	else return NO;
}

-(void) setTriggerEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerEnabled:aChan withValue:(triggerEnabledMask>>aChan)&0x1];
	if(aState) triggerEnabledMask |= (1<<aChan);
	else triggerEnabledMask &= ~(1<<aChan);
	
    [[NSNotificationCenter defaultCenter]postNotificationName:ORIpeV4FLTModelTriggerEnabledMaskChanged object:self];
}

- (BOOL) hitRateEnabled:(unsigned short) aChan
{
 	if(aChan<22)return (hitRateEnabledMask >> aChan) & 0x1;
	else return NO;
}

- (void) setHitRateEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateEnabled:aChan withValue:(hitRateEnabledMask>>aChan)&0x1];
	if(aState) hitRateEnabledMask |= (1<<aChan);
	else hitRateEnabledMask &= ~(1<<aChan);
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHitRateEnabledMaskChanged object:self];
}


- (int) fltRunMode { return fltRunMode; }
- (void) setFltRunMode:(int)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFltRunMode:fltRunMode];
    fltRunMode = aMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelModeChanged object:self];
}

- (void) enableAllHitRates:(BOOL)aState
{
	[self setHitRateEnabledMask:aState?0x3fffff:0x0];
}

- (void) enableAllTriggers:(BOOL)aState
{
	[self setTriggerEnabledMask:aState?0x3fffff:0x0];
}

- (void) setHitRateTotal:(float)newTotalValue
{
	hitRateTotal = newTotalValue;
	if(!totalRate){
		[self setTotalRate:[[ORTimeRate alloc] init]];
	}
	[totalRate addDataToTimeAverage:hitRateTotal];
}

- (float) hitRateTotal { return hitRateTotal; }
- (float) hitRate:(unsigned short)aChan
{
	if(aChan<kNumFLTChannels)return hitRate[aChan];
	else return 0;
}

- (float) rate:(int)aChan { return [self hitRate:aChan]; }
- (BOOL) hitRateOverFlow:(unsigned short)aChan
{
	if(aChan<kNumFLTChannels)return hitRateOverFlow[aChan];
	else return NO;
}

- (unsigned short) selectedChannelValue { return selectedChannelValue; }
- (void) setSelectedChannelValue:(unsigned short) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedChannelValue:selectedChannelValue];
    selectedChannelValue = aValue;
    [[NSNotificationCenter defaultCenter]	 postNotificationName:ORIpeV4FLTSelectedChannelValueChanged	 object:self];
}

- (unsigned short) selectedRegIndex { return selectedRegIndex; }
- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:selectedRegIndex];
    selectedRegIndex = anIndex;
    [[NSNotificationCenter defaultCenter]	 postNotificationName:ORIpeV4FLTSelectedRegIndexChanged	 object:self];
}

- (unsigned long) writeValue { return writeValue; }
- (void) setWriteValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    writeValue = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTWriteValueChanged object:self];
}

- (unsigned short) readoutPages { return readoutPages; }
- (void) setReadoutPages:(unsigned short)aReadoutPage
{
    // At maximum there are 64 pages
	if(aReadoutPage<1)aReadoutPage = 1;
	else if(aReadoutPage>64)aReadoutPage = 64;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setReadoutPages:readoutPages];
    readoutPages = aReadoutPage;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelReadoutPagesChanged object:self];
}

- (NSString*) getRegisterName: (short) anIndex
{
    return regV4[anIndex].regName;
}

- (unsigned long) getAddressOffset: (short) anIndex
{
    return( regV4[anIndex].addressOffset );
}

- (short) getAccessType: (short) anIndex
{
	return regV4[anIndex].accessType;
}

#pragma mark •••HW Access
- (unsigned long) readBoardIDLow
{
	unsigned long value = [self readReg:kFLTV4BoardIDLsbReg];
	return value;
}

- (unsigned long) readBoardIDHigh
{
	unsigned long value = [self readReg:kFLTV4BoardIDMsbReg];
	return value;
}

- (int) readSlot
{
	return ([self readReg:kFLTV4BoardIDMsbReg]>>24) & 0x1F;
}

- (unsigned long)  readVersion
{	
	return [self readReg: kFLTV4VersionReg];
}

- (unsigned long)  readpVersion
{	
	return [self readReg: kFLTV4pVersionReg];
}

- (unsigned long)  readSeconds
{	
	return [self readReg: kFLTV4SecondCounterReg];
}

- (void)  writeSeconds:(unsigned long)aValue
{	
	return [self writeReg: kFLTV4SecondCounterReg value:aValue];
}

- (void) setTimeToMacClock
{
	NSTimeInterval theTimeSince1970 = [NSDate timeIntervalSinceReferenceDate];
	[self writeSeconds:(unsigned long)theTimeSince1970];
}

- (int) readMode
{
	return ([self readControl]>>16) & 0xf;
}

- (void) loadThresholdsAndGains
{
	int i;
	for(i=0;i<kNumFLTChannels;i++){
		[self writeThreshold:i value:[self threshold:i]];
		[self writeGain:i value:[self gain:i]]; 
	}
}

- (int) restrictIntValue:(int)aValue min:(int)aMinValue max:(int)aMaxValue
{
	if(aValue<aMinValue)	  return aMinValue;
	else if(aValue>aMaxValue) return aMaxValue;
	else					  return aValue;
}

- (void) enableStatistics
{
#if (0)
    unsigned long aValue;
	bool enabled = true;
	unsigned long adc_guess = 150;			// This are parameter that work with the standard Auger-type boards
	unsigned long n = 65000;				// There is not really a need to make them variable. ak 7.10.07
	
    aValue =     (  ( (unsigned long) (enabled  &   0x1) ) << 31)
	| (  ( (unsigned long) (adc_guess   & 0x3ff) ) << 16)
	|    ( (unsigned long) ( (n-1)  & 0xffff) ) ; // 16 bit !
	
	// Broadcast to all channel	(pseudo channel 0x1f)     
	[self writeReg:kFLTStaticSetReg channel:0x1f value:aValue]; 
	
	// Save parameter for calculation of mean and variance
	statisticOffset = adc_guess;
	statisticN = n;
#endif
}


- (void) getStatistics:(int)aChannel mean:(double *)aMean  var:(double *)aVar 
{
#if (0)
    unsigned long data;
	signed long sum;
    unsigned long sumSq;
	
    // Read Statistic parameter
    data = [self  readReg:kFLTStaticSetReg channel:aChannel];
	statisticOffset = (data  >> 16) & 0x3ff;
	statisticN = (data & 0xffff) +1;
	
	
    // Read statistics
	// The sum is a 25bit signed number.
	sum = [self readReg:kFLTSumXReg channel:aChannel];
	// Move the sign
	sum = (sum & 0x01000000) ? (sum | 0xFE000000) : (sum & 0x00FFFFFF);
	
    // Read the sum of squares	
	sumSq = [self readReg:kFLTSumX2Reg channel:aChannel];
	
	//NSLog(@"data = %x Offset = %d, n = %d, sum = %08x, sum2 = %08x\n", data, statisticOffset, statisticN, sum, sumSq);
	
	// Calculate mean and variance
	if (statisticN > 0){
		*aMean = (double) sum / statisticN + statisticOffset;
		*aVar = (double) sumSq / statisticN 
		- (double) sum / statisticN * sum / statisticN;
    } else {
		*aMean = -1; 
		*aVar = -1;
	}
#endif
}


- (void) initBoard
{
	[self writeControl];
	[self writeReg:kFLTV4AnalogOffset  value:analogOffset];
	[self writeReg: kFLTV4HrControlReg value:hitRateLength];
	[self writeReg: kFLTV4PostTrigger  value:postTriggerTime];
	[self loadThresholdsAndGains];
	[self writeTriggerControl];			//set trigger mask
	[self writeHitRateMask];			//set hitRage control mask
	[self enableStatistics];			//enable hardware ADC statistics, ak 7.1.07
	
	if(fltRunMode == kIpeFlt_Histo_Mode){
		[self writeHistogramControl];
	}
}

- (unsigned long) readStatus
{
	return [self readReg: kFLTV4StatusReg ];
}

- (unsigned long) readControl
{
	return [self readReg: kFLTV4ControlReg];
}

- (void) writeRunControl:(BOOL)startSampling
{
	unsigned long aValue = 
		((filterLength<<8) & 0xf)		| 
		((gapLength<<4) & 0xf)			| 
		((runBoxCarFilter<<2) & 0x1)	|
		((startSampling<<1) & 0x1);
	
	[self writeReg:kFLTV4RunControlReg value:aValue];					
}

- (void) writeControl
{
	unsigned long aValue =	((fltRunMode & 0xf)<<16) | 
	((fifoBehaviour & 0x1)<<24) |
	((ledOff & 0x1)<<1 );
	[self writeReg: kFLTV4ControlReg value:aValue];
}

- (void) writeHistogramControl
{
	[self writeReg:kFLTV4HistMeasTimeReg value:histMeasTime];
	[self writeReg:kFLTV4HistNumMeasReg value:histNofMeas];
}

- (unsigned long) regAddress:(int)aReg channel:(int)aChannel
{
	return ([self stationNumber] << 17) | (aChannel << 12)   | regV4[aReg].addressOffset; //TODO: the channel ... -tb-   | ((aChannel&0x01f)<<kIpeFlt_ChannelAddress)
}

- (unsigned long) regAddress:(int)aReg
{
	
	return ([self stationNumber] << 17) |  regV4[aReg].addressOffset; //TODO: NEED <<17 !!! -tb-
}

- (unsigned long) adcMemoryChannel:(int)aChannel page:(int)aPage
{
	//TODO:  replace by V4 code -tb-
	return 0;
    //TODO: obsolete (v3) -tb-
	return ([self slot] << 24) | (0x2 << kIpeFlt_AddressSpace) | (aChannel << kIpeFlt_ChannelAddress)	| (aPage << kIpeFlt_PageNumber);
}

- (unsigned long) readReg:(int)aReg
{
	return [self read: [self regAddress:aReg]];
}

- (unsigned long) readReg:(int)aReg channel:(int)aChannel
{
	return [self read:[self regAddress:aReg channel:aChannel]];
}

- (void) writeReg:(int)aReg value:(unsigned long)aValue
{
	[self write:[self regAddress:aReg] value:aValue];
}

- (void) writeReg:(int)aReg channel:(int)aChannel value:(unsigned long)aValue
{
	[self write:[self regAddress:aReg channel:aChannel] value:aValue];
}

- (void) writeThreshold:(int)i value:(unsigned short)aValue
{
	aValue &= 0x1ffff;
	[self writeReg: kFLTV4ThresholdReg channel:i value:aValue];
}

- (unsigned short) readThreshold:(int)i
{
	return [self readReg:kFLTV4ThresholdReg channel:i] & 0x1ffff;
}

- (void) writeGain:(int)i value:(unsigned short)aValue
{
	aValue &= 0xfff;
	[self writeReg:kFLTV4GainReg channel:i value:aValue]; 
}

- (unsigned short) readGain:(int)i
{
	return [self readReg:kFLTV4GainReg channel:i] & 0xfff;
}

- (void) writeTestPattern:(unsigned long*)mask length:(int)len
{
	[self rewindTestPattern];
	[self writeNextPattern:0];
	int i;
	for(i=0;i<len;i++){
		[self writeNextPattern:mask[i]];
		NSLog(@"%d: %@\n",i,mask[i]?@".":@"-");
	}
	[self rewindTestPattern];
}

- (void) rewindTestPattern
{
#if (0)
    //TODO: obsolete (v3) -tb-
	[self writeReg:kFLTTestPulsMemReg value: kIpeFlt_TP_Control | kIpeFlt_TestPattern_Reset];
	
#endif
}

- (void) writeNextPattern:(unsigned long)aValue
{
#if (0)
    //TODO: obsolete (v3) -tb-
	[self writeReg:kFLTTestPulsMemReg value:aValue];
#endif
}

- (void) clear:(int)aChan page:(int)aPage value:(unsigned short)aValue
{
	unsigned long aPattern;
	
	aPattern =  aValue;
	aPattern = ( aPattern << 16 ) + aValue;
	
	// While emulating the block transfer by a loop of single transfers
	// it is nec. to increment the address pointer by 2
	[self clearBlock:[self adcMemoryChannel:aChan page:aPage]
			 pattern:aPattern
			  length:kIpeFlt_Page_Size / 2
		   increment:2];
}

- (void) writeMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{
	[self writeBlock: [self adcMemoryChannel:aChan page:aPage] 
		  dataBuffer: (unsigned long*)aPageBuffer
			  length: kIpeFlt_Page_Size/2
		   increment: 2];
}

- (void) readMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{
	
	[self readBlock: [self adcMemoryChannel:aChan page:aPage]
		 dataBuffer: (unsigned long*)aPageBuffer
			 length: kIpeFlt_Page_Size/2
		  increment: 2];
}

- (unsigned long) readMemoryChan:(int)aChan page:(int)aPage
{
	return [self read:[self adcMemoryChannel:aChan page:aPage]];
}

- (void) writeHitRateMask
{
	[self writeReg:kFLTV4HrMeasEnableReg value:hitRateEnabledMask];
}

- (unsigned long) readHitRateMask
{
	return [self readReg:kFLTV4HrMeasEnableReg] & 0x3fffff;
}

- (void) writeInterruptMask
{
	[self writeReg:kFLTV4InterruptMaskReg value:interruptMask];
}

- (void) disableAllTriggers
{
	[self writeReg:kFLTV4PixelSettings1Reg value:0x0];
	[self writeReg:kFLTV4PixelSettings2Reg value:0x3ffffff];
}

- (void) writeTriggerControl
{
	//0,0 Normal
	//0,1 test pattern
	//1,0 always 0
	//1,1 always 1
	[self writeReg:kFLTV4PixelSettings1Reg value:0x0];
	[self writeReg:kFLTV4PixelSettings2Reg value:~triggerEnabledMask];
}

- (void) readHitRates
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
	
	@try {
		unsigned long aValue;
		BOOL overflow;
		
		BOOL oneChanged = NO;
		float newTotal = 0;
		int chan;
		for(chan=0;chan<kNumFLTChannels;chan++){
			
			aValue = [self readReg:kFLTV4HitRateReg channel:chan];
			overflow = (aValue >> 17) & 0x1;
			aValue = aValue & 0xffff;
			
			if(aValue != hitRate[chan] || overflow != hitRateOverFlow[chan]){
				
				if (hitRateLength!=0)	hitRate[chan] = aValue/ (float) hitRateLength; 
				else					hitRate[chan] = 0;
				
				if(hitRateOverFlow[chan])hitRate[chan] = 0;
				hitRateOverFlow[chan] = overflow;
				
				oneChanged = YES;
			}
			if(!hitRateOverFlow[chan]){
				newTotal += hitRate[chan];
			}
		}
		
		[self setHitRateTotal:newTotal];
		
		if(oneChanged){
		    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHitRateChanged object:self];
		}
	}
	@catch(NSException* localException) {
	}
	
	[self performSelector:@selector(readHitRates) withObject:nil afterDelay:[self hitRateLength]];
}

- (NSString*) rateNotification
{
	return ORIpeV4FLTModelHitRateChanged;
}

- (BOOL) isInStandByMode
{
	return [self readMode] == kIpeFlt_StandBy_Mode;
}

- (BOOL) isInRunMode
{
	return [self readMode] == kIpeFlt_Run_Mode;
}

- (BOOL) isInHistoMode
{
	return [self readMode] == kIpeFlt_Histo_Mode;
}

- (BOOL) isInTestMode
{
	return [self readMode] == kIpeFlt_Test_Mode;
}

#pragma mark •••archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setRunBoxCarFilter:	[decoder decodeBoolForKey:@"runBoxCarFilter"]];
    [self setStoreDataInRam:	[decoder decodeBoolForKey:@"storeDataInRam"]];
    [self setFilterLength:		[decoder decodeIntForKey:@"filterLength"]];
    [self setGapLength:			[decoder decodeIntForKey:@"gapLength"]];
    [self setHistNofMeas:		[decoder decodeInt32ForKey:@"histNofMeas"]];
    [self setHistMeasTime:		[decoder decodeInt32ForKey:@"histMeasTime"]];
    [self setPostTriggerTime:	[decoder decodeInt32ForKey:@"postTriggerTime"]];
    [self setFifoBehaviour:		[decoder decodeIntForKey:@"fifoBehaviour"]];
    [self setAnalogOffset:		[decoder decodeIntForKey:@"analogOffset"]];
    [self setInterruptMask:		[decoder decodeInt32ForKey:@"interruptMask"]];
    [self setHitRateEnabledMask:[decoder decodeInt32ForKey:@"hitRateEnabledMask"]];
    [self setTriggerEnabledMask:[decoder decodeInt32ForKey:@"triggerEnabledMask"]];
    [self setHitRateLength:		[decoder decodeIntForKey:@"ORIpeV4FLTModelHitRateLength"]];
    [self setGains:				[decoder decodeObjectForKey:@"gains"]];
    [self setThresholds:		[decoder decodeObjectForKey:@"thresholds"]];
    [self setFltRunMode:		[decoder decodeIntForKey:@"mode"]];
    [self setTotalRate:			[decoder decodeObjectForKey:@"totalRate"]];
	[self setTestEnabledArray:	[decoder decodeObjectForKey:@"testsEnabledArray"]];
	[self setTestStatusArray:	[decoder decodeObjectForKey:@"testsStatusArray"]];
    [self setReadoutPages:		[decoder decodeIntForKey:@"readoutPages"]];
    [self setWriteValue:		[decoder decodeIntForKey:@"writeValue"]];
    [self setSelectedRegIndex:  [decoder decodeIntForKey:@"selectedRegIndex"]];
    [self setSelectedChannelValue:  [decoder decodeIntForKey:@"selectedChannelValue"]];
	
	int i;
	if(!thresholds){
		[self setThresholds: [NSMutableArray array]];
		for(i=0;i<kNumFLTChannels;i++) [thresholds addObject:[NSNumber numberWithInt:50]];
	}
	
	if(!gains){
		[self setGains: [NSMutableArray array]];
		for(i=0;i<kNumFLTChannels;i++) [gains addObject:[NSNumber numberWithInt:100]];
	}
	
	if(!testStatusArray){
		[self setTestStatusArray: [NSMutableArray array]];
		for(i=0;i<kNumIpeV4FLTTests;i++) [testStatusArray addObject:@"--"];
	}
	
	if(!testEnabledArray){
		[self setTestEnabledArray: [NSMutableArray array]];
		for(i=0;i<kNumIpeV4FLTTests;i++) [testEnabledArray addObject:[NSNumber numberWithBool:YES]];
	}
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
    [encoder encodeBool:runBoxCarFilter		forKey:@"runBoxCarFilter"];
    [encoder encodeBool:storeDataInRam		forKey:@"storeDataInRam"];
    [encoder encodeInt:filterLength			forKey:@"filterLength"];
    [encoder encodeInt:gapLength			forKey:@"gapLength"];
    [encoder encodeInt32:histNofMeas		forKey:@"histNofMeas"];
    [encoder encodeInt32:histMeasTime		forKey:@"histMeasTime"];
    [encoder encodeInt32:histRecTime		forKey:@"histRecTime"];
    [encoder encodeInt32:postTriggerTime	forKey:@"postTriggerTime"];
    [encoder encodeInt:fifoBehaviour		forKey:@"fifoBehaviour"];
    [encoder encodeInt:analogOffset			forKey:@"analogOffset"];
    [encoder encodeInt32:interruptMask		forKey:@"interruptMask"];
    [encoder encodeInt32:hitRateEnabledMask	forKey:@"hitRateEnabledMask"];
    [encoder encodeInt32:triggerEnabledMask	forKey:@"triggerEnabledMask"];
    [encoder encodeInt:hitRateLength		forKey:@"ORIpeV4FLTModelHitRateLength"];
    [encoder encodeObject:gains				forKey:@"gains"];
    [encoder encodeObject:thresholds		forKey:@"thresholds"];
    [encoder encodeInt:fltRunMode			forKey:@"mode"];
    [encoder encodeObject:totalRate			forKey:@"totalRate"];
    [encoder encodeObject:testEnabledArray	forKey:@"testEnabledArray"];
    [encoder encodeObject:testStatusArray	forKey:@"testStatusArray"];
    [encoder encodeInt:readoutPages  		forKey:@"readoutPages"];	
    [encoder encodeInt:writeValue           forKey:@"writeValue"];	
    [encoder encodeInt:selectedRegIndex  	forKey:@"selectedRegIndex"];	
    [encoder encodeInt:selectedChannelValue	forKey:@"selectedChannelValue"];	
}

#pragma mark Data Taking
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (unsigned long) waveFormId { return waveFormId; }
- (void) setWaveFormId: (unsigned long) aWaveFormId
{
    waveFormId = aWaveFormId;
}

- (void) setDataIds:(id)assigner
{
    dataId      = [assigner assignDataIds:kLongForm];
    waveFormId  = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
    [self setWaveFormId:[anotherCard waveFormId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORIpeV4FLTDecoderForEnergy",		@"decoder",
								 [NSNumber numberWithLong:dataId],   @"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:7],			@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeV4FLTEnergy"];
	
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   [NSNumber numberWithLong:dataId],				@"dataId",
				   [NSNumber numberWithLong:kNumFLTChannels],		@"maxChannels",
				   nil];
	
	[anEventDictionary setObject:aDictionary forKey:@"IpeV4FLT"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:thresholds			forKey:@"thresholds"];
    [objDictionary setObject:gains				forKey:@"gains"];
    [objDictionary setObject:[NSNumber numberWithLong:hitRateEnabledMask] forKey:@"hitRateEnabledMask"];
    [objDictionary setObject:[NSNumber numberWithLong:triggerEnabledMask] forKey:@"triggerEnabledMask"];
	
	return objDictionary;
}

- (void) reset
{
	[self writeReg:kFLTV4CommandReg value:kIpeFlt_Reset_All];
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{	
	firstTime = YES;
	
    [self clearExceptionCount];
	
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORIpeV4FLTModel"];    
    //----------------------------------------------------------------------------------------	
	
	//check which mode to use
	BOOL ratesEnabled = NO;
	int i;
	for(i=0;i<kNumFLTChannels;i++){
		if([self hitRateEnabled:i]){
			ratesEnabled = YES;
			break;
		}
	}
	
    //if([[userInfo objectForKey:@"doinit"]intValue]){
	[self setLedOff:NO];
	[self initBoard];					
	//}
	
	
	if(ratesEnabled){
		[self performSelector:@selector(readHitRates) 
				   withObject:nil
				   afterDelay:[self hitRateLength]];		//start reading out the rates
	}
	
	
	// TODO: For the auger FPGA set readoutPage always to 1
	// ak, 5.10.2007
	readoutPages = 1;
	
	//cache some addresses for speed in the dataTaking loop.
	unsigned long theSlotPart = [self slot]<<24;
	statusAddress			  = theSlotPart;
	//memoryAddress			  = theSlotPart | (ipeV4Reg[kFLTAdcMemory].space << kIpeFlt_AddressSpace); //TODO: V4 handling ... -tb-
	sltCard					  = [[self crate] adapter];
	locationWord			  = (([self crateNumber]&0x0f)<<21) | ([self stationNumber]& 0x0000001f)<<16;
	pageSize                  = [sltCard pageSize];  //us
	[self writeRunControl:YES];
}


//**************************************************************************************
// Function:	

// Description: Read data from a card
//***************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{	
	if(firstTime){
		firstTime = NO;
		[self writeControl];
	}
	else {
		unsigned long status = [self readReg: kFLTV4StatusReg];
		int fifoStatus = (status>>24) & 0xf;
		if(fifoStatus != 0x03){
			//unsigned long eventFifoStatus = [self readReg: kFLTV4EventFifo1Reg];
			//int readOffset = ((eventFifoStatus>>16) & 0x3ff)*2;
			
			unsigned long eventFifo1 = [self readReg: kFLTV4EventFifo1Reg];
			unsigned long channelMap = (eventFifo1>>10)&0x3ffff;
			int i;
			for(i=0;i<kNumFLTChannels;i++){
				if(channelMap & (1<<i)){
					unsigned long eventFifo3 = [self readReg: kFLTV4EventFifo3Reg channel:i];
					unsigned long energy     = [self readReg: kFLTV4EventFifo4Reg channel:i];
					
					unsigned long data[7];
					
					data[0] = dataId | 7;	
					data[1] = locationWord | i<<8;
					data[2] = 0; //sec
					data[3] = 0; //subsec
					data[4] = channelMap;
					data[5] = 0; //eventID
					data[6] = energy;
					[aDataPacket addLongsToFrameBuffer:data length:7];
					
				}
			}
		}
		
	}
#if 0
    @try {	
		
		//retrieve the parameters
		int fltPageStart = [[userInfo objectForKey:@"page"] intValue];
		int lStart		 = [[userInfo objectForKey:@"lStart"] intValue];
		unsigned long pixelList = [[userInfo objectForKey:@"pixelList"] intValue]; // ak, 5.10.2007
		unsigned long fltSize = pageSize * 5; // Size in long words
		
		//int eventCounter = [[userInfo objectForKey:@"eventCounter"] intValue];
		[self eventMask:pixelList];	
		
		//NSLog(@"Pixellist = %08x\n", pixelList);	
		
		int aChan;
		for(aChan=0;aChan<kNumFLTChannels;aChan++){	
		    if (( (pixelList >> aChan) & 0x1 == 0x1)) {	
			    //NSLog(@"Reading channel (%d,%d)\n", [self slot], aChan);
				
				locationWord &= 0xffff0000;
				locationWord |= (aChan&0xff)<<8;
				
				unsigned long totalLength = (2 + readoutPages * fltSize);	// longs
				//unsigned long totalLength = (2 + 500);	// longs
				NSMutableData* theWaveFormData = [NSMutableData dataWithCapacity:totalLength*sizeof(long)];
				unsigned long header = waveFormId | totalLength;
				
				[theWaveFormData appendBytes:&header length:4];				           //ORCA header word∂
				[theWaveFormData appendBytes:&locationWord length:4];		           //which crate, which card info
				
				[theWaveFormData setLength:totalLength*sizeof(long)]; //we're going to dump directly into the NSData object so
				//we have to set the total size first. (Note: different than 'Capacity')
				
				
				short* waveFormPtr = ((short*)[theWaveFormData bytes]) + (4*sizeof(short)); //point to start of waveform
				unsigned long* wPtr = (unsigned long*)waveFormPtr;
				
				int i;
				int j;
				long addr =  memoryAddress | (aChan << kIpeFlt_ChannelAddress) | (fltPageStart<<10) | lStart; // ak, 5.10.07
				for (j=0;j<readoutPages;j++){
					
					// Use block read mode.
					// With every 32bit (long word) two 12bit ADC values are transmitted
					// documentation says 1000 data words followed by 24 words not used
					[slt read:addr data:wPtr size:fltSize*sizeof(long)];	
					
					// Remove the flags
					// TODO: Add a control to enable or disable flags in the data
					//       Better: Improve the display, define a variable number of
					//               flags that can be defined and stored with the Orca settings.
					for (i=0;i<2*fltSize;i++)
						waveFormPtr[i] = waveFormPtr[i] & 0x0fff;					
					
					wPtr += fltSize;				
					addr = (addr + 1024) % 0x10000;
				}
				
				[aDataPacket addData:theWaveFormData]; //ship the waveform
				
			}
		} // end of loop over all channel
		
	}
	@catch(NSException* localException) {
		
		NSLogError(@"",@"Ipe FLT Card Error",[NSString stringWithFormat:@"Card%d",[self stationNumber]],@"Data Readout",nil);
		[self incExceptionCount];
		[localException raise];
		
	}
#endif
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[self writeRunControl:NO];
	[self setLedOff:YES];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
	int chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		hitRate[chan] = 0;
	}
	[self setHitRateTotal:0];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelHitRateChanged object:self];
}

#pragma mark •••SBC readout control structure... Till, fill out as needed
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kFLTv4;	//should be unique
	configStruct->card_info[index].hw_mask[0] 	= dataId;
	configStruct->card_info[index].hw_mask[1] 	= waveFormId;
	configStruct->card_info[index].slot			= [self stationNumber];
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].add_mod		= 0;		//not needed for this HW
	
	//use the following as needed to define base addresses and special data for use by the cpu to 
	//do the readout
	//configStruct->card_info[index].base_add		= [self baseAddress];
	//configStruct->card_info[index].deviceSpecificData[0] = onlineMask;
	//configStruct->card_info[index].deviceSpecificData[1] = register_offsets[kConversionStatusRegister];
	//configStruct->card_info[index].deviceSpecificData[2] = register_offsets[kADC1OutputRegister];
	
	configStruct->card_info[index].num_Trigger_Indexes = 0;
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

#pragma mark •••HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}

- (int) numberOfChannels
{
    return kNumFLTChannels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:32000 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gain"];
    [p setFormat:@"##0" upperLimit:255 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setGain:withValue:) getMethod:@selector(gain:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setTriggerEnabled:withValue:) getMethod:@selector(triggerEnabled:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"HitRate Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setHitRateEnabled:withValue:) getMethod:@selector(hitRateEnabled:)];
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
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORIpeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"ORIpeV4FLTModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORIpeV4FLTModel"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Threshold"]){
        return  [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    }
    else if([param isEqualToString:@"Gain"]){
		return [[cardDictionary objectForKey:@"gains"] objectAtIndex:aChannel];
	}
    else if([param isEqualToString:@"TriggerEnabled"]){
		return [[cardDictionary objectForKey:@"triggersEnabled"] objectAtIndex:aChannel];
	}
    else if([param isEqualToString:@"HitRateEnabled"]){
		return [[cardDictionary objectForKey:@"hitRatesEnabled"] objectAtIndex:aChannel];
	}
    else return nil;
}

#pragma mark •••AdcInfo Providing
- (void) postAdcInfoProvidingValueChanged
{
	//this notification is be picked up by high-level objects like the 
	//Katrin U/I that displays all the thresholds and gains in the system
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAdcInfoProvidingValueChanged object:self];
}

- (BOOL) onlineMaskBit:(int)bit
{
	return [self triggerEnabled:bit];
}

#pragma mark •••Reporting
- (void) printEventFIFOs
{
	unsigned long status = [self readReg: kFLTV4StatusReg];
	int fifoStatus = (status>>24) & 0xf;
	if(fifoStatus != 0x03){
		
		NSLog(@"fifoStatus: 0x%0x\n",(status>>24)&0xf);
		
		unsigned long aValue = [self readReg: kFLTV4EventFifoStatusReg];
		NSLog(@"aValue: 0x%0x\n", aValue);
		NSLog(@"Read: %d\n", (aValue>>16)&0x3ff);
		NSLog(@"Write: %d\n", (aValue>>0)&0x3ff);
		
		unsigned long eventFifo1 = [self readReg: kFLTV4EventFifo1Reg];
		unsigned long channelMap = (eventFifo1>>10)&0x3ffff;
		NSLog(@"Channel Map: 0x%0x\n",channelMap);
		
		unsigned long eventFifo2 = [self readReg: kFLTV4EventFifo2Reg];
		unsigned long sec =  ((eventFifo1&0x3ff)<<5) | ((eventFifo2>>27)&0x1f);
		NSLog(@"sec: %d %d\n",((eventFifo2>>27)&0x1f),eventFifo1&0x3ff);
		NSLog(@"Time: %d\n",sec);
		
		int i;
		for(i=0;i<kNumFLTChannels;i++){
			if(channelMap & (1<<i)){
				unsigned long eventFifo3 = [self readReg: kFLTV4EventFifo3Reg channel:i];
				unsigned long energy     = [self readReg: kFLTV4EventFifo4Reg channel:i];
				NSLog(@"channel: %d page: %d energy: %d\n\n",i, eventFifo3 & 0x3f, energy);
			}
		}
		NSLog(@"-------\n");
	}
	else NSLog(@"FIFO empty\n");
}

- (void) printPStatusRegs
{
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	unsigned long pAData = [self readReg:kFLTV4pStatusA];
	unsigned long pBData = [self readReg:kFLTV4pStatusB];
	unsigned long pCData = [self readReg:kFLTV4pStatusC];
	NSLogFont(aFont,@"----------------------------------------\n");
	NSLogFont(aFont,@"PStatus      A          B         C\n");
	NSLogFont(aFont,@"----------------------------------------\n");
	NSLogFont(aFont,@"Filter:  %@   %@   %@\n", (pAData>>2)&0x1 ? @" InValid": @"   OK   ",
			  (pBData>>2)&0x1 ? @" InValid": @"   OK   ",
			  (pCData>>2)&0x1 ? @" InValid": @"   OK   ");
	
	NSLogFont(aFont,@"PLL1  :  %@   %@   %@\n", (pAData>>8)&0x1 ? @"Unlocked": @"  Locked",
			  (pBData>>8)&0x1 ? @"Unlocked": @"  Locked",
			  (pCData>>8)&0x1 ? @"Unlocked": @"  Locked");
	
	NSLogFont(aFont,@"PLL2  :  %@   %@   %@\n", (pAData>>9)&0x1 ? @"Unlocked": @"  Locked",
			  (pBData>>9)&0x1 ? @"Unlocked": @"  Locked",
			  (pCData>>9)&0x1 ? @"Unlocked": @"  Locked");
	
	NSLogFont(aFont,@"QDR-II:  %@   %@   %@\n", (pAData>>10)&0x1 ? @"Unlocked": @"  Locked",
			  (pBData>>10)&0x1 ? @"Unlocked": @"  Locked",
			  (pCData>>10)&0x1 ? @"Unlocked": @"  Locked");
	
	NSLogFont(aFont,@"QDR-Er:  %@   %@   %@\n", (pAData>>11)&0x1 ? @"   Error": @"  Clear ",
			  (pBData>>11)&0x1 ? @"   Error": @"  Clear ",
			  (pCData>>11)&0x1 ? @"   Error": @"  Clear ");
	
	NSLogFont(aFont,@"----------------------------------------\n");
}

- (NSString*) boardTypeName:(int)aType
{
	switch(aType){
		case 0:  return @"FZK HEAT";	break;
		case 1:  return @"FZK KATRIN";	break;
		case 2:  return @"FZK USCT";	break;
		case 3:  return @"ITALY HEAT";	break;
		default: return @"UNKNOWN";		break;
	}
}
- (NSString*) fifoStatusString:(int)aType
{
	switch(aType){
		case 0x3:  return @"Empty";			break;
		case 0x2:  return @"Almost Empty";	break;
		case 0x4:  return @"Almost Full";	break;
		case 0xc:  return @"Full";			break;
		default:   return @"UNKNOWN";		break;
	}
}

- (void) printVersions
{
	unsigned long data;
	data = [self readVersion];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"CFPGA Version %u.%u.%u.%u\n",((data>>28)&0xf),((data>>16)&0xfff),((data>>8)&0xff),((data>>0)&0xff));
	data = [self readpVersion];
	NSLogFont(aFont,@"FPGA8 Version %u.%u.%u.%u\n",((data>>28)&0xf),((data>>16)&0xfff),((data>>8)&0xff),((data>>0)&0xff));
}

- (void) printStatusReg
{
	unsigned long status = [self readStatus];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"FLT %d status Reg (address:0x%08x): 0x%08x\n", [self stationNumber],[self regAddress:kFLTV4StatusReg],status);
	NSLogFont(aFont,@"Power           : %@\n",	((status>>0) & 0x1) ? @"FAILED":@"OK");
	NSLogFont(aFont,@"PLL1            : %@\n",	((status>>1) & 0x1) ? @"UNLOCKED":@"OK");
	NSLogFont(aFont,@"PLL2            : %@\n",	((status>>2) & 0x1) ? @"UNLOCKED":@"OK");
	NSLogFont(aFont,@"10MHz Phase     : %@\n",	((status>>3) & 0x1) ? @"UNLOCKED":@"OK");
	NSLogFont(aFont,@"Firmware Type   : %@\n",	[self boardTypeName:((status>>4) & 0x3)]);
	NSLogFont(aFont,@"Hardware Type   : %@\n",	[self boardTypeName:((status>>6) & 0x3)]);
	NSLogFont(aFont,@"Busy            : %@\n",	((status>>8) & 0x1) ? @"BUSY":@"IDLE");
	NSLogFont(aFont,@"Interrupt Srcs  : 0x%x\n",	(status>>16) &0xff);
	NSLogFont(aFont,@"FIFO Status     : %@\n",	[self fifoStatusString:((status>>24) & 0xf)]);
	NSLogFont(aFont,@"Histo Toggle Bit: %d\n",	((status>>28) & 0x1));
	NSLogFont(aFont,@"Histo Toggle Clr: %d\n",	((status>>29) & 0x1));
	NSLogFont(aFont,@"IRQ             : %d\n",	((status>>31) & 0x1));
}

- (void) printValueTable
{
	int i;
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,   @"chan | HitRate  | Gain | Threshold\n");
	NSLogFont(aFont,   @"----------------------------------\n");
	unsigned long aHitRateMask = [self readHitRateMask] ;
	for(i=0;i<kNumFLTChannels;i++){
		NSLogFont(aFont,@"%4d | %@ | %4d | %4d \n",i,(aHitRateMask>>i)&0x1 ? @" Enabled":@"Disabled",[self readGain:i],[self readThreshold:i]);
	}
	NSLogFont(aFont,   @"---------------------------------\n");
}

- (void) printStatistics
{
	//TODO:  replace by V4 code -tb-
	NSLog(@"FLTv4: printStatistics not implemented \n");//TODO: needs implementation -tb-
	return;
    int j;
	double mean;
	double var;
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
    NSLogFont(aFont,@"Statistics      :\n");
	for (j=0;j<kNumFLTChannels;j++){
		[self getStatistics:j mean:&mean var:&var];
		NSLogFont(aFont,@"  %2d -- %10.2f +/-  %10.2f\n", j, mean, var);
	}
}

@end

@implementation ORIpeV4FLTModel (tests)
#pragma mark •••Accessors
- (BOOL) testsRunning { return testsRunning; }
- (void) setTestsRunning:(BOOL)aTestsRunning
{
    testsRunning = aTestsRunning;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelTestsRunningChanged object:self];
}

- (NSMutableArray*) testEnabledArray { return testEnabledArray; }
- (void) setTestEnabledArray:(NSMutableArray*)aTestEnabledArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestEnabledArray:testEnabledArray];
    
    [aTestEnabledArray retain];
    [testEnabledArray release];
    testEnabledArray = aTestEnabledArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelTestEnabledArrayChanged object:self];
}

- (NSMutableArray*) testStatusArray { return testStatusArray; }
- (void) setTestStatusArray:(NSMutableArray*)aTestStatusArray
{
    [aTestStatusArray retain];
    [testStatusArray release];
    testStatusArray = aTestStatusArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelTestStatusArrayChanged object:self];
}

- (NSString*) testStatus:(int)index
{
	if(index<[testStatusArray count])return [testStatusArray objectAtIndex:index];
	else return @"---";
}

- (BOOL) testEnabled:(int)index
{
	if(index<[testEnabledArray count])return [[testEnabledArray objectAtIndex:index] boolValue];
	else return NO;
}

- (void) runTests
{
	if(!testsRunning){
		@try {
			[self setTestsRunning:YES];
			NSLog(@"Starting tests for FLT station %d\n",[self stationNumber]);
			
			//clear the status text array
			int i;
			for(i=0;i<kNumIpeV4FLTTests;i++){
				[testStatusArray replaceObjectAtIndex:i withObject:@"--"];
			}
			
			//create the test suit
			if(testSuit)[testSuit release];
			testSuit = [[ORTestSuit alloc] init];
			if([self testEnabled:0]) [testSuit addTest:[ORTest testSelector:@selector(modeTest) tag:0]];
			if([self testEnabled:1]) [testSuit addTest:[ORTest testSelector:@selector(ramTest) tag:1]];
			if([self testEnabled:2]) [testSuit addTest:[ORTest testSelector:@selector(thresholdGainTest) tag:2]];
			if([self testEnabled:3]) [testSuit addTest:[ORTest testSelector:@selector(speedTest) tag:3]];
			if([self testEnabled:4]) [testSuit addTest:[ORTest testSelector:@selector(eventTest) tag:4]];
			
			[testSuit runForObject:self];
		}
		@catch(NSException* localException) {
		}
	}
	else {
		NSLog(@"Tests for FLT (station: %d) stopped manually\n",[self stationNumber]);
		[testSuit stopForObject:self];
	}
}

- (void) runningTest:(int)aTag status:(NSString*)theStatus
{
	[testStatusArray replaceObjectAtIndex:aTag withObject:theStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4FLTModelTestStatusArrayChanged object:self];
}


#pragma mark •••Tests
- (void) modeTest
{
	int testNumber = 0;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	savedMode = fltRunMode;
	@try {
		BOOL passed = YES;
		int i;
		for(i=0;i<4;i++){
			fltRunMode = i;
			[self writeControl];
			if([self readMode] != i){
				[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
				passed = NO;
				break;
			}
			if(passed){
				fltRunMode = savedMode;
				if([self readMode] != savedMode){
					[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
					passed = NO;
				}
			}
		}
		if(passed){
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}
	
	[testSuit runForObject:self]; //do next test
}


- (void) ramTest
{
	int testNumber = 1;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	@try {
		[self test:testNumber result:@"TBD" color:[NSColor passedColor]];
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
}

- (void) thresholdGainTest
{
	int testNumber = 2;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	@try {
		[self enterTestMode];
		unsigned long aPattern[4] = {0x3fff,0x0,0x2aaa,0x1555};
		int chan;
		BOOL passed = YES;
		int testIndex;
		//thresholds first
		for(testIndex = 0;testIndex<4;testIndex++){
			unsigned short thePattern = aPattern[testIndex];
			for(chan=0;chan<kNumFLTChannels;chan++){
				[self writeThreshold:chan value:thePattern];
			}
			
			for(chan=0;chan<kNumFLTChannels;chan++){
				if([self readThreshold:chan] != thePattern){
					[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
					NSLog(@"Error: Threshold (pattern: 0x%0x) FLT %d chan %d does not work\n",thePattern,[self stationNumber],chan);
					passed = NO;
					break;
				}
			}
		}
		if(passed){		
			unsigned long gainPattern[4] = {0xfff,0x0,0xaaa,0x555};
			
			//now gains
			for(testIndex = 0;testIndex<4;testIndex++){
				unsigned short thePattern = gainPattern[testIndex];
				for(chan=0;chan<kNumFLTChannels;chan++){
					[self writeGain:chan value:thePattern];
				}
				
				for(chan=0;chan<kNumFLTChannels;chan++){
					unsigned short theValue = [self readGain:chan];
					if(theValue != thePattern){
						[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
						NSLog(@"Error: Gain (pattern: 0x%0x!=0x%0x) FLT %d chan %d does not work\n",thePattern,theValue,[self stationNumber],chan);
						passed = NO;
						break;
					}
				}
			}
		}
		if(passed){	
			unsigned long offsetPattern[4] = {0xfff,0x0,0xaaa,0x555};
			for(testIndex = 0;testIndex<4;testIndex++){
				unsigned short thePattern = offsetPattern[testIndex];
				[self writeReg:kFLTV4AnalogOffset value:thePattern];
				unsigned short theValue = [self readReg:kFLTV4AnalogOffset];
				if(theValue != thePattern){
					NSLog(@"Error: Offset (pattern: 0x%0x!=0x%0x) FLT %d does not work\n",thePattern,theValue,[self stationNumber]);
					passed = NO;
					break;
				}
			}
		}
		
		if(passed) [self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		
		[self loadThresholdsAndGains]; //put the old values back
		
		[self leaveTestMode];
		
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
}

- (void) speedTest
{
	int testNumber = 3;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
		
	@try {
		[self test:testNumber result:@"TBD" color:[NSColor passedColor]];
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
		
	}		
	
	[testSuit runForObject:self]; //do next test
}

- (void) eventTest
{
	int testNumber = 4;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	@try {
		[self test:testNumber result:@"TBD" color:[NSColor passedColor]];
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
		
	}		
	
	[testSuit runForObject:self]; //do next test
}

- (int) compareData:(unsigned short*) data
			pattern:(unsigned short*) pattern
			  shift:(int) shift
				  n:(int) n 
{
	int i, j;
	
	// Check for errors
	for (i=0;i<n;i++) {
		if (data[i]!=pattern[(i+shift)%n]) {
			for (j=(i/4);(j<i/4+3) && (j < n/4);j++){
				NSLog(@"%04x: %04x %04x %04x %04x - %04x %04x %04x %04x \n",j*4,
					  data[j*4],data[j*4+1],data[j*4+2],data[j*4+3],
					  pattern[(j*4+shift)%n],  pattern[(j*4+1+shift)%n],
					  pattern[(j*4+2+shift)%n],pattern[(j*4+3+shift)%n]  );
				return i; // check only for one error in every page!
			}
		}
	}
	
	return n;
}
@end

@implementation ORIpeV4FLTModel (private)

- (NSAttributedString*) test:(int)testIndex result:(NSString*)result color:(NSColor*)aColor
{
	NSLogColor(aColor,@"%@ test %@\n",fltTestName[testIndex],result);
	id theString = [[NSAttributedString alloc] initWithString:result 
												   attributes:[NSDictionary dictionaryWithObject: aColor forKey:NSForegroundColorAttributeName]];
	
	[self runningTest:testIndex status:theString];
	return [theString autorelease];
}

- (void) enterTestMode
{
	//put into test mode
	savedMode = fltRunMode;
	fltRunMode = kIpeFlt_Test_Mode;
	[self writeControl];
	if([self readMode] != kIpeFlt_Test_Mode){
		NSLogColor([NSColor redColor],@"Could not put FLT %d into test mode\n",[self stationNumber]);
		[NSException raise:@"Ram Test Failed" format:@"Could not put FLT %d into test mode\n",[self stationNumber]];
	}
}

- (void) leaveTestMode
{
	fltRunMode = savedMode;
	[self writeControl];
}
@end