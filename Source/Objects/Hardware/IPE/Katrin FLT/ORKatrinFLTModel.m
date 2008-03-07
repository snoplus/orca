//
//  ORKatrinFLTModel.m
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


#import "ORKatrinFltDefs.h"
#import "ORKatrinFLTModel.h"
#import "ORIpeSLTModel.h"
#import "ORIpeCrateModel.h"
#import "ORIpeFireWireCard.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORDataTypeAssigner.h"
#import "ORAxis.h"
#import "ORTimeRate.h"
#import "ORFireWireInterface.h"
#import "ORIpeFireWireCard.h"
#import "ORTest.h"

/** The hardware returns the product energy times filter length
  * Using the define energy shift will remove the filter length dependancy.
  * For a filter lenght shorter than 128 (maximum) the histogram will 
  * have whole as with a shorter filter length the resotution goes down. 
  * The mode might be useful for experiemts that need to change the filter lenght
  * and want to have the energy pulse and thresholds in the same range.  
  */
//#define USE_ENERGY_SHIFT

NSString* ORKatrinFLTModelCheckWaveFormEnabledChanged = @"ORKatrinFLTModelCheckWaveFormEnabledChanged";
NSString* ORKatrinFLTModelTestPatternCountChanged	 = @"ORKatrinFLTModelTestPatternCountChanged";
NSString* ORKatrinFLTModelTModeChanged				 = @"ORKatrinFLTModelTModeChanged";
NSString* ORKatrinFLTModelTestParamChanged			 = @"ORKatrinFLTModelTestParamChanged";
NSString* ORKatrinFLTModelBroadcastTimeChanged		 = @"ORKatrinFLTModelBroadcastTimeChanged";
NSString* ORKatrinFLTModelHitRateLengthChanged		 = @"ORKatrinFLTModelHitRateLengthChanged";
NSString* ORKatrinFLTModelShapingTimesChanged		 = @"ORKatrinFLTModelShapingTimesChanged";
NSString* ORKatrinFLTModelTriggersEnabledChanged	 = @"ORKatrinFLTModelTriggersEnabledChanged";
NSString* ORKatrinFLTModelGainsChanged				 = @"ORKatrinFLTModelGainsChanged";
NSString* ORKatrinFLTModelThresholdsChanged			 = @"ORKatrinFLTModelThresholdsChanged";
NSString* ORKatrinFLTModelFltRunModeChanged			 = @"ORKatrinFLTModelFltRunModeChanged";
NSString* ORKatrinFLTModelDaqRunModeChanged			 = @"ORKatrinFLTModelDaqRunModeChanged";
NSString* ORKatrinFLTSettingsLock					 = @"ORKatrinFLTSettingsLock";
NSString* ORKatrinFLTChan							 = @"ORKatrinFLTChan";
NSString* ORKatrinFLTModelTestPatternsChanged		 = @"ORKatrinFLTModelTestPatternsChanged";
NSString* ORKatrinFLTModelGainChanged				 = @"ORKatrinFLTModelGainChanged";
NSString* ORKatrinFLTModelThresholdChanged			 = @"ORKatrinFLTModelThresholdChanged";
NSString* ORKatrinFLTModelTriggerEnabledChanged		 = @"ORKatrinFLTModelTriggerEnabledChanged";
NSString* ORKatrinFLTModelShapingTimeChanged		 = @"ORKatrinFLTModelShapingTimeChanged";
NSString* ORKatrinFLTModelHitRateEnabledChanged		 = @"ORKatrinFLTModelHitRateEnabledChanged";
NSString* ORKatrinFLTModelHitRatesArrayChanged		 = @"ORKatrinFLTModelHitRatesArrayChanged";
NSString* ORKatrinFLTModelHitRateChanged			 = @"ORKatrinFLTModelHitRateChanged";
NSString* ORKatrinFLTModelTestsRunningChanged		 = @"ORKatrinFLTModelTestsRunningChanged";
NSString* ORKatrinFLTModelTestEnabledArrayChanged	 = @"ORKatrinFLTModelTestEnabledChanged";
NSString* ORKatrinFLTModelTestStatusArrayChanged	 = @"ORKatrinFLTModelTestStatusChanged";

NSString* ORKatrinFLTModelReadoutPagesChanged		 = @"ORKatrinFLTModelReadoutPagesChanged"; // ak, 2.7.07

//hardware histogramming -tb- 2008-02-08
NSString* ORKatrinFLTModelHistoBinWidthChanged		 = @"ORKatrinFLTModelHistoBinWidthChanged";
NSString* ORKatrinFLTModelHistoMinEnergyChanged      = @"ORKatrinFLTModelHistoMinEnergyChanged";
NSString* ORKatrinFLTModelHistoMaxEnergyChanged      = @"ORKatrinFLTModelHistoMaxEnergyChanged";
NSString* ORKatrinFLTModelHistoFirstBinChanged       = @"ORKatrinFLTModelHistoFirstBinChanged";
NSString* ORKatrinFLTModelHistoLastBinChanged        = @"ORKatrinFLTModelHistoLastBinChanged";
NSString* ORKatrinFLTModelHistoRunTimeChanged        = @"ORKatrinFLTModelHistoRunTimeChanged";
NSString* ORKatrinFLTModelHistoRecordingTimeChanged  = @"ORKatrinFLTModelHistoRecordingTimeChanged";
NSString* ORKatrinFLTModelHistoTestValuesChanged     = @"ORKatrinFLTModelHistoTestValuesChanged";
NSString* ORKatrinFLTModelHistoTestPlotterWantDisplay     = @"ORKatrinFLTModelHistoTestPlotterWantDisplay";
NSString* ORKatrinFLTModelHistoCalibrationChanChanged     = @"ORKatrinFLTModelHistoCalibrationChanChanged";

    
    
    
    
    
    

enum {
	kFLTControlRegCode			= 0x0L,
	kFLTTimeCounterCode			= 0x1L,
	kFLTTriggerControlCode		= 0x2L,
	kFLTThresholdCode			= 0x3L,
	kFLTHitRateSettingCode		= 0x4L,
	kFLTHitRateCode				= 0x4L,
	kFLTGainCode				= 0x4L,
	kFLTTestPatternCode			= 0x4L,
	kFLTTriggerDataCode			= 0x5L,
	kFLTTriggerEnergyCode		= 0x6L,
	kFLTAdcDataCode				= 0x7L
};

static int trigChanConvFLT[4][6]={
	{ 0,  2,  4,  6,  8, 10},	//FPG6-A
	{ 1,  3,  5,  7,  9, 11},	//FPG6-B
	{12, 14, 16, 18, 20, -1},	//FPG6-C
	{13, 15, 17, 19, 21, -1},	//FPG6-D
};

static NSString* fltTestName[kNumKatrinFLTTests]= {
	@"Run Mode",
	@"Ram",
	@"Pattern",
	@"Broadcast",
	@"Threshold/Gain",
	@"Speed",
	@"Event",
};

@interface ORKatrinFLTModel (private)
- (NSAttributedString*) test:(int)testName result:(NSString*)string color:(NSColor*)aColor;
- (void) enterTestMode;
- (void) leaveTestMode;
- (void) checkWaveform:(short*)waveFormPtr;
@end

@implementation ORKatrinFLTModel

- (id) init
{
    self = [super init];
    histogramDataUI = 0; // TODO: see histogramData -tb- 2008-03-07
    return self;
}

- (void) dealloc
{	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [testPatterns release];
    [testEnabledArray release];
    [testStatusArray release];
	[testSuit release];
    [shapingTimes release];
    [triggersEnabled release];
	[thresholds release];
	[gains release];
	[totalRate release];
    //[histogramData release]; //TODO: for HW histogram UP TO NOW UNUSED -tb-
    if(histogramDataUI) free(histogramDataUI);// for HW histogram -tb-
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"KatrinFLTCard"]];
}


- (void) makeMainController
{
    [self linkToController:@"ORKatrinFLTController"];
}


#pragma mark ¥¥¥Accessors

- (BOOL) checkWaveFormEnabled
{
    return checkWaveFormEnabled;
}

- (void) setCheckWaveFormEnabled:(BOOL)aCheckWaveFormEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCheckWaveFormEnabled:checkWaveFormEnabled];
    
    checkWaveFormEnabled = aCheckWaveFormEnabled;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelCheckWaveFormEnabledChanged object:self];
}

- (int) testPatternCount
{
    return testPatternCount;
}

- (void) setTestPatternCount:(int)aTestPatternCount
{
	if(aTestPatternCount<=0)     aTestPatternCount = 1;
	else if(aTestPatternCount>24)aTestPatternCount = 24;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setTestPatternCount:testPatternCount];
    
    testPatternCount = aTestPatternCount;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestPatternCountChanged object:self];
}

- (unsigned short) tMode
{
    return tMode;
}

- (void) setTMode:(unsigned short)aTMode
{
	aTMode &= 0x3;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setTMode:tMode];
    
    tMode = aTMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTModeChanged object:self];
}

- (int) page
{
    return page;
}

- (void) setPage:(int)aPage
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPage:page];
    
    page = aPage;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestParamChanged object:self];
}

- (int) iterations
{
    return iterations;
}

- (void) setIterations:(int)aIterations
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIterations:iterations];
    
    iterations = aIterations;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestParamChanged object:self];
}

- (int) endChan
{
    return endChan;
}

- (void) setEndChan:(int)aEndChan
{
	if(aEndChan>21)aEndChan = 21;
	if(aEndChan<0)aEndChan = 0;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setEndChan:endChan];
    
    endChan = aEndChan;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestParamChanged object:self];
}

- (int) startChan
{
    return startChan;
}

- (void) setStartChan:(int)aStartChan
{
	if(aStartChan>21)aStartChan = 21;
	if(aStartChan<0)aStartChan = 0;
    [[[self undoManager] prepareWithInvocationTarget:self] setStartChan:startChan];
    
    startChan = aStartChan;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestParamChanged object:self];
}

- (BOOL) broadcastTime
{
    return broadcastTime;
}

- (void) setBroadcastTime:(BOOL)aBroadcastTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBroadcastTime:broadcastTime];
    
    broadcastTime = aBroadcastTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelBroadcastTimeChanged object:self];
}

- (void) setTotalRate:(ORTimeRate*)newTimeRate
{
	[totalRate autorelease];
	totalRate=[newTimeRate retain];
}

- (ORTimeRate*) totalRate
{
	return totalRate;
}


- (unsigned short) hitRateLength
{
    return hitRateLength;
}

- (void) setHitRateLength:(unsigned short)aHitRateLength
{
	if(aHitRateLength<1)aHitRateLength = 1;
	else if(aHitRateLength>8)aHitRateLength = 8;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateLength:hitRateLength];
    
    hitRateLength = aHitRateLength;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHitRateLengthChanged object:self];
}

- (NSMutableArray*) shapingTimes
{
    return shapingTimes;
}

- (void) setShapingTimes:(NSMutableArray*)aShapingTimes
{
    [aShapingTimes retain];
    [shapingTimes release];
    shapingTimes = aShapingTimes;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelShapingTimesChanged object:self];
}


- (NSMutableArray*) triggersEnabled
{
    return triggersEnabled;
}

- (void) setTriggersEnabled:(NSMutableArray*)aTriggersEnabled
{
    [aTriggersEnabled retain];
    [triggersEnabled release];
    triggersEnabled = aTriggersEnabled;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTriggersEnabledChanged object:self];
}

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


- (unsigned long) hitRateId {
return hitRateId; 
}
- (void) setHitRateId: (unsigned long) aHitRateId
{
    hitRateId = aHitRateId;
}

- (unsigned long) thresholdScanId { return thresholdScanId; }
- (void) setThresholdScanId: (unsigned long) athresholdScanId
{
    thresholdScanId = athresholdScanId;
}

- (unsigned long) histogramId { return histogramId; }
- (void) setHistogramId: (unsigned long) aValue
{
    histogramId = aValue;
}

- (unsigned long) vetoId { return vetoId; }
- (void) setVetoId: (unsigned long) aValue
{
    vetoId = aValue;
}

/*! Assign the data IDs which are needed to identify the type of encoded data sets.
    They are needed in:
    the takeData methods
    - (NSDictionary*) dataRecordDescription
*/ //-tb- 2008-02-6
- (void) setDataIds:(id)assigner
{
    dataId            = [assigner assignDataIds:kLongForm];
    waveFormId        = [assigner assignDataIds:kLongForm];
	hitRateId         = [assigner assignDataIds:kLongForm]; // new ... -tb- 2008-01-29
	thresholdScanId   = [assigner assignDataIds:kLongForm];
	histogramId       = [assigner assignDataIds:kLongForm];
	vetoId            = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:     [anotherCard dataId]];
    [self setWaveFormId: [anotherCard waveFormId]];
	[self setHitRateId:  [anotherCard hitRateId]]; // new ... -tb- 2008-01-29
	[self setThresholdScanId: [anotherCard thresholdScanId]];
	[self setHistogramId: [anotherCard histogramId]];
	[self setVetoId:      [anotherCard vetoId]];
}

- (NSMutableArray*) hitRatesEnabled
{
    return hitRatesEnabled;
}

- (void) setHitRatesEnabled:(NSMutableArray*)anArray
{
	[anArray retain];
	[hitRatesEnabled release];
    hitRatesEnabled = anArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHitRatesArrayChanged object:self];
}

- (NSMutableArray*) gains
{
    return gains;
}

- (void) setGains:(NSMutableArray*)aGains
{
	[aGains retain];
	[gains release];
    gains = aGains;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelGainsChanged object:self];
}

- (NSMutableArray*) thresholds
{
    return thresholds;
}

- (void) setThresholds:(NSMutableArray*)aThresholds
{
	[aThresholds retain];
	[thresholds release];
    thresholds = aThresholds;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelThresholdsChanged object:self];
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
	//if(aThreshold>1200)aThreshold = 1200;
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aThreshold]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORKatrinFLTChan];
	
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORKatrinFLTModelThresholdChanged
						  object:self
						userInfo: userInfo];
						
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}


- (unsigned short)shapingTime:(unsigned short) aGroup
{
	if(aGroup < 4){
		return [[shapingTimes objectAtIndex:aGroup] shortValue];
	}
	else {
		return 0;
	}
}

- (void)setShapingTime:(unsigned short) aGroup withValue:(unsigned short)aShapingTime
{
	if(aGroup < 4){
		[[[self undoManager] prepareWithInvocationTarget:self] setShapingTime:aGroup withValue:[self shapingTime:aGroup]];
		[shapingTimes replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:aShapingTime]];
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:aGroup] forKey: ORKatrinFLTChan];
		
		[[NSNotificationCenter defaultCenter]
				postNotificationName:ORKatrinFLTModelShapingTimeChanged
							  object:self
							userInfo: userInfo];
	}
}

- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain
{
	if(aGain>255)aGain = 255;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:aChan withValue:[self gain:aChan]];
	[gains replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aGain]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORKatrinFLTChan];
	
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORKatrinFLTModelGainChanged
						  object:self
						userInfo: userInfo];
 
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

//ORAdcInfoProviding protocol requirement
- (void) postAdcInfoProvidingValueChanged
{
	[[NSNotificationCenter defaultCenter]
			postNotificationName:ORAdcInfoProvidingValueChanged
						  object:self
						userInfo: nil];
}


- (NSMutableArray*)testPatterns
{
	return testPatterns;
}

- (void) setTestPatterns:(NSMutableArray*) aPattern
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestPatterns:[self testPatterns]];
	[aPattern retain];
	[testPatterns release];
	testPatterns = aPattern;
		
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORKatrinFLTModelTestPatternsChanged
						  object:self
						userInfo: nil];
}



-(BOOL) triggerEnabled:(unsigned short) aChan
{
    return [[triggersEnabled objectAtIndex:aChan] boolValue];
}

//ORAdcInfoProviding protocol 
- (BOOL)onlineMaskBit:(int)bit
{
	//translate back to the triggerEnabled Bit
	return [self triggerEnabled:bit];
}

-(void) setTriggerEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerEnabled:aChan withValue:[self triggerEnabled:aChan]];
    [triggersEnabled replaceObjectAtIndex:aChan withObject:[NSNumber numberWithBool:aState]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORKatrinFLTChan];
	
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORKatrinFLTModelTriggerEnabledChanged
						  object:self
						userInfo: userInfo];
}

- (BOOL) hitRateEnabled:(unsigned short) aChan
{
    return [[hitRatesEnabled objectAtIndex:aChan] boolValue];
}


- (void) setHitRateEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateEnabled:aChan withValue:[self hitRateEnabled:aChan]];
    [hitRatesEnabled replaceObjectAtIndex:aChan withObject:[NSNumber numberWithBool:aState]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORKatrinFLTChan];
	
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORKatrinFLTModelHitRateEnabledChanged
						  object:self
						userInfo: userInfo];
}


- (int) fltRunMode
{
    return fltRunMode;
}

- (void) setFltRunMode:(int)aMode
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setDaqRunMode:daqRunMode];
    fltRunMode = aMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelFltRunModeChanged object:self];
}

- (int) daqRunMode
{
    return daqRunMode;
}

- (void) setDaqRunMode:(int)aMode
{

    [[[self undoManager] prepareWithInvocationTarget:self] setDaqRunMode:daqRunMode];
    daqRunMode = aMode;
	
    // daq mode --> hw mode
    switch(aMode){
      //TODO: replace by names -tb- 2008-02-04
      case kKatrinFlt_DaqEnergyTrace_Mode:    [self setFltRunMode:kKatrinFlt_Debug_Mode];  break;
      case kKatrinFlt_DaqEnergy_Mode:         [self setFltRunMode:kKatrinFlt_Run_Mode];  break;
      case kKatrinFlt_DaqHitrate_Mode:
      case kKatrinFlt_DaqThresholdScan_Mode:  [self setFltRunMode:kKatrinFlt_Measure_Mode];  break;
      case kKatrinFlt_DaqTest_Mode:           [self setFltRunMode:kKatrinFlt_Test_Mode];  break;
      case kKatrinFlt_DaqHistogram_Mode:      [self setFltRunMode:kKatrinFlt_Run_Mode];  break;
      //TODO: for VETO ... -tb- case kKatrinFlt_DaqVeto_Mode:           [self setFltRunMode:kKatrinFlt_Run_Mode];  break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelDaqRunModeChanged  object:self];
}


- (void) enableAllHitRates:(BOOL)aState
{
	int chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[self setHitRateEnabled:chan withValue:aState];
	}
}

- (void) setHitRateTotal:(float)newTotalValue
{
	hitRateTotal = newTotalValue;
	if(!totalRate){
		[self setTotalRate:[[ORTimeRate alloc] init]];
	}
	[totalRate addDataToTimeAverage:hitRateTotal];
}

- (float) hitRateTotal
{
	return hitRateTotal;
}

- (float) hitRate:(unsigned short)aChan
{
	if(aChan<kNumFLTChannels)return hitRate[aChan];
	else return 0;
}

- (float) rate:(int)aChan
{
	return [self hitRate:aChan];
}

- (BOOL) hitRateOverFlow:(unsigned short)aChan
{
	if(aChan<kNumFLTChannels)return hitRateOverFlow[aChan];
	else return NO;
}


// Added parameter for length of adc traces, ak 2.7.07

- (unsigned short) readoutPages
{
    return readoutPages;
}


- (void) setReadoutPages:(unsigned short)aReadoutPage
{
    // At maximum there are 64 pages
	if(aReadoutPage<1)aReadoutPage = 1;
	else if(aReadoutPage>64)aReadoutPage = 64;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setReadoutPages:readoutPages];
    
    readoutPages = aReadoutPage;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelReadoutPagesChanged object:self];
}



#pragma mark ¥¥¥HW Access
- (void) checkPresence
{
	NS_DURING
		[self readCardId];
		[self setPresent:YES];
	NS_HANDLER
		[self setPresent:NO];
	NS_ENDHANDLER
}

- (int)  readVersion
{	
	unsigned long data = [self readControlStatus];
	return (data >> kKatrinFlt_Cntl_Version_Shift) & kKatrinFlt_Cntl_Version_Mask; // 3bit
}

-(int) readFPGAVersion:(int) fpga
{
	unsigned long data = [self readTriggerControl:fpga];
	return((data >> 14) & 0x3); // 2bit
}


- (int)  readCardId
{
 	unsigned long data = [self readControlStatus];
	return (data >> kKatrinFlt_Cntrl_CardID_Shift) & kKatrinFlt_Cntrl_CardID_Mask; // 5bit
}

- (BOOL)  readHasData
{
 	unsigned long data = [self readControlStatus];
	return ((data >> kKatrinFlt_Cntrl_BufState_Shift) & 0x3 == 0x1);
}

- (BOOL)  readIsOverflow
{
 	unsigned long data = [self readControlStatus];
	return ((data >> kKatrinFlt_Cntrl_BufState_Shift) & 0x3 == 0x3);
}


- (int)  readMode
{
	unsigned long data = [self readControlStatus];
	[self setFltRunMode: (data >> kKatrinFlt_Cntrl_Mode_Shift) & kKatrinFlt_Cntrl_Mode_Mask]; // 4bit
    
    NSLog(@"readMode: hw=%d, daq=%d \n",fltRunMode,daqRunMode);//TODO: debug output -tb-
    
	return fltRunMode;
}

- (void)  writeMode:(int) aValue 
{
	//unsigned long buffer = [self readControlStatus];
	//buffer =(buffer & ~(kKatrinFlt_Cntrl_Mode_Mask<<kKatrinFlt_Cntrl_Mode_Shift) ) | (aValue << kKatrinFlt_Cntrl_Mode_Shift);
    [self writeControlStatus:(aValue&kKatrinFlt_Cntrl_Mode_Mask) << kKatrinFlt_Cntrl_Mode_Shift];
}

- (unsigned long)  getReadPointer
{
	unsigned long data = [self readControlStatus];
	return data & 0x1ff; // 9bit
}

- (unsigned long)  getWritePointer
{
	unsigned long data = [self readControlStatus];
	return (data >> 11) & 0x1ff; // 9bit
}


- (void)  reset
{
	//reset the W/R pointers
	unsigned long buffer = (fltRunMode << kKatrinFlt_Cntrl_Mode_Shift) | 0x1;
	[self writeControlStatus:buffer];
}


/** This is a test:
  * using 2 doxygen comments for the same method. It works! -tb-*/
- (void)  trigger
{
    //unsigned long addr;
	
	NSLog(@"Generating software trigger\n" );		

    generateTrigger = 1;
   	
	// Generate a software trigger
	//addr =  (21 << 24) | (0x1 << 18) | 0x0f12; // Slt Generate Software Trigger
    //[self write:addr value:0];
	

}


- (void) loadThresholdsAndGains
{
	int i;
	for(i=0;i<kNumFLTChannels;i++){
		[self writeThreshold:i value:[self threshold:i]];
		[self writeGain:i value:[self gain:i]]; 
	}
}


- (void) initBoard
{
	[self loadTime];					//set the time on the flts to mac time
	[self writeMode:fltRunMode];
	[self loadThresholdsAndGains];
	[self writeHitRateMask];			//set the hit rate masks
}

- (unsigned long) readControlStatus
{
	return  [self read: ([self slot] << 24) ];
}

- (void) writeControlStatus:(unsigned long)aValue
{
	[self write: ([self slot] << 24) value:aValue];
}

- (void) printStatusReg
{
	unsigned long status = [self readControlStatus];
	NSLog(@"FLT %d status Reg: 0x%08x\n",[self stationNumber],status);
	NSLog(@"Revision: %d\n",(status>>kKatrinFlt_Cntl_Version_Shift) & kKatrinFlt_Cntl_Version_Mask);
	NSLog(@"SlotID  : %d\n",(status>>kKatrinFlt_Cntrl_CardID_Shift) & kKatrinFlt_Cntrl_CardID_Mask);
	NSLog(@"Has Data: %@\n",((status>>kKatrinFlt_Cntrl_BufState_Shift) & kKatrinFlt_Cntrl_BufState_Mask == 0x1)?@"YES":@"NO");
	NSLog(@"OverFlow: %@\n",((status>>kKatrinFlt_Cntrl_BufState_Shift) & kKatrinFlt_Cntrl_BufState_Mask == 0x3)?@"YES":@"NO");
	NSLog(@"Mode    : %d\n",((status>>kKatrinFlt_Cntrl_Mode_Shift) & kKatrinFlt_Cntrl_Mode_Mask));
	NSLog(@"WritePtr: %d\n",((status>>kKatrinFlt_Cntrl_Write_Shift) & kKatrinFlt_Cntrl_Write_Mask));
	NSLog(@"ReadPtr : %d\n",((status>>kKatrinFlt_Cntrl_ReadPtr_Shift) & kKatrinFlt_Cntrl_ReadPtr_Mask));
}


- (void) writeThreshold:(int)i value:(unsigned short)aValue
{
#ifdef USE_ENERGY_SHIFT											
    // Calculate the energy shift due to the shapingTime
	int fpga = i%2 + 2 * (i/12);
    energyShift[i] = 7 - [[shapingTimes objectAtIndex:fpga] intValue] & 0x7;

	//[self write:([self slot] << 24) | (kFLTThresholdCode << FLT_ADDRSP) | ((i&0x01f)<<FLT_CHADDR) value:(aValue>>energyShift[i])]; // E : T = 1
	[self write:([self slot] << 24) | (kFLTThresholdCode << kKatrinFlt_AddressSpace) | ((i&0x01f)<<kKatrinFlt_ChannelAddress) value:(aValue>>energyShift[i])]; // E : T = 1
#else

    // Take ration between threshold and energy into account.
	// Changed to 1, ak 21.9.07
	//[self write:([self slot] << 24) | (kFLTThresholdCode << FLT_ADDRSP) | ((i&0x01f)<<FLT_CHADDR) value:(aValue>>1)];  // E : T = 2
	//[self write:([self slot] << 24) | (kFLTThresholdCode << FLT_ADDRSP) | ((i&0x01f)<<FLT_CHADDR) value:(aValue)]; // E : T = 1
	[self write:([self slot] << 24) | (kFLTThresholdCode << kKatrinFlt_AddressSpace) | ((i&0x01f)<<kKatrinFlt_ChannelAddress) value:(aValue)]; // E : T = 1
#endif	
}

- (unsigned short) readThreshold:(int)i
{
    // Calculate the energy shift due to the shapingTime
#ifdef USE_ENERGY_SHIFT											
	int fpga = i%2 + 2 * (i/12);
    energyShift[i] = 7 - [[shapingTimes objectAtIndex:fpga] intValue] & 0x7;

	//return [self read:([self slot] << 24) | (kFLTThresholdCode << FLT_ADDRSP) | ((i&0x01f)<<FLT_CHADDR)] << energyShift[i];	// E : T = 1
	return [self read:([self slot] << 24) | (kFLTThresholdCode << kKatrinFlt_AddressSpace) | ((i&0x01f)<<kKatrinFlt_ChannelAddress)] << energyShift[i];
#else
	
    // Take ration between threshold and energy into account.
	// Changed to 1, ak 21.9.07
	//return [self read:([self slot] << 24) | (kFLTThresholdCode << FLT_ADDRSP) | ((i&0x01f)<<FLT_CHADDR)] >> 1;	 // E : T = 2
	//return [self read:([self slot] << 24) | (kFLTThresholdCode << FLT_ADDRSP) | ((i&0x01f)<<FLT_CHADDR)];	// E : T = 1
	return [self read:([self slot] << 24) | (kFLTThresholdCode << kKatrinFlt_AddressSpace) | ((i&0x01f)<<kKatrinFlt_ChannelAddress)];
#endif	
}

- (void) writeGain:(int)i value:(unsigned short)aValue
{
     // invert the gain scale, ak 20.7.07
	[self write:([self slot] << 24) | (kFLTGainCode << kKatrinFlt_AddressSpace) | ((i&0x01f)<<kKatrinFlt_ChannelAddress) | 0x1 value:(255-aValue)]; 
}

- (void) clear:(int)aChan page:(int)aPage value:(unsigned short)aValue
{
	unsigned long aPattern;

	aPattern =  aValue;
	aPattern = ( aPattern << 16 ) + aValue;

	// While emulating the block transfer by a loop of single transfers
	// it is nec. to increment the address pointer by 2
	[self clearBlock:([self slot] << 24) | (kFLTAdcDataCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress)	| (aPage << kKatrinFlt_PageNumber) 
			 pattern:aPattern
			  length:kKatrinFlt_Page_Size / 2
		   increment:2];
}

- (void) broadcast:(int)aPage dataBuffer:(unsigned short*)aDataBuffer
{
	// While emulating the block transfer by a loop of single transfers
	// it is nec. to increment the address pointer by 2
	[self writeBlock:([self slot] << 24) | (kFLTAdcDataCode << kKatrinFlt_AddressSpace) | (kKatrinFlt_ChannelAddress_All << kKatrinFlt_ChannelAddress)	| (aPage << kKatrinFlt_PageNumber) 
		  dataBuffer:(unsigned long*) aDataBuffer
			  length:kKatrinFlt_Page_Size / 2
		   increment:2];
}

- (void) writeMemoryChan:(int)aChan page:(int)aPage value:(unsigned short)aValue
{
	[self write:([self slot] << 24) | (kFLTAdcDataCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress) | (aPage << kKatrinFlt_PageNumber) value:aValue];
}

- (void) writeMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{
		[self writeBlock: ([self slot] << 24) | (kFLTAdcDataCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress)	| (aPage << kKatrinFlt_PageNumber) 
			 dataBuffer: (unsigned long*)aPageBuffer
				 length: kKatrinFlt_Page_Size/2
			  increment: 2];
}

- (void) readMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{

		[self readBlock: ([self slot] << 24) |(kFLTAdcDataCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress) | (aPage << kKatrinFlt_PageNumber) 
			 dataBuffer: (unsigned long*)aPageBuffer
				 length: kKatrinFlt_Page_Size/2
			  increment: 2];
}

- (unsigned long) readMemoryChan:(int)aChan page:(int)aPage
{
	return [self read:([self slot] << 24) | (kFLTAdcDataCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress) | (aPage << kKatrinFlt_PageNumber)];
}

- (void) writeHitRateMask
{
	unsigned long hitRateEnabledMask = 0;
	int chan;
	for(chan = 0;chan<kNumFLTChannels;chan++){
		if([[hitRatesEnabled objectAtIndex:chan] intValue]){
			hitRateEnabledMask |= (0x1L<<chan);
		}
	}
	
	// Code from 0 to n --> 1sec to n+1 sec
	// ak, 15.6.07
	hitRateEnabledMask |= ((hitRateLength-1) &0xf)<<24;  
	
	[self write:([self slot] << 24) | (kFLTHitRateSettingCode << kKatrinFlt_AddressSpace) value:hitRateEnabledMask];
}



- (unsigned short) readGain:(int)i
{
    // invert the gain scale, ak 20.7.07
	return (255-[self read:([self slot] << 24) | (kFLTGainCode << kKatrinFlt_AddressSpace) | 0x1 | ((i&0x01f)<<kKatrinFlt_ChannelAddress)]);
}

- (void) writeTriggerControl
{
	unsigned long aValue = 0;
	int fpga;
	for(fpga=0;fpga<4;fpga++){
		aValue = [[shapingTimes objectAtIndex:fpga] intValue] & 0x7;	//fold in the shaping time
		int chan;
		for(chan = 0;chan<6;chan++){
			if(trigChanConvFLT[fpga][chan] >= 0 && trigChanConvFLT[fpga][chan]<22){
				if([[triggersEnabled objectAtIndex:trigChanConvFLT[fpga][chan]] intValue]){
					aValue |= (0x1L<<chan)<<8;								//fold in the trigger enabled bit.
				}
			}
		}
		
		[self write:([self slot] << 24) | (kFLTTriggerControlCode << kKatrinFlt_AddressSpace) | (trigChanConvFLT[fpga][0]<<kKatrinFlt_ChannelAddress)  value:aValue];
		unsigned long checkValue = [self read:([self slot] << 24) | (kFLTTriggerControlCode << kKatrinFlt_AddressSpace) | (trigChanConvFLT[fpga][0]<<kKatrinFlt_ChannelAddress)];
			
		aValue	   &= 0x3f07;
		checkValue &= 0x3f07;
		
        if (!usingPBusSimulation){	
		  if(aValue != checkValue)
		    NSLog(@"FLT %d FPGA %d Trigger control write/read mismatch <0x%08x:0x%08x>\n",
		          [self stationNumber],fpga,aValue,checkValue);
        }				  
	}
	
}


- (void) disableTrigger
{
	unsigned long aValue = 0;
	int fpga;
	for(fpga=0;fpga<4;fpga++){
		aValue = [[shapingTimes objectAtIndex:fpga] intValue] & 0x7;	//fold in the shaping time
		
		[self write:([self slot] << 24) | (kFLTTriggerControlCode << kKatrinFlt_AddressSpace) | (trigChanConvFLT[fpga][0]<<kKatrinFlt_ChannelAddress)  value:aValue];
		//unsigned long checkValue = [self read:([self slot] << 24) | (kFLTTriggerControlCode << kKatrinFlt_AddressSpace) | (trigChanConvFLT[fpga][0]<<kKatrinFlt_ChannelAddress)];
		//	
		//aValue	   &= 0x3f07;
		//checkValue &= 0x3f07;
		//
		//if(aValue != checkValue)NSLog(@"FLT %d FPGA %d Trigger control write/read mismatch <0x%08x:0x%08x>\n",[self stationNumber],fpga,aValue,checkValue);
	}
	
}


- (unsigned short) readTriggerControl:(int) fpga
{	
	return [self read:([self slot] << 24) | (kFLTTriggerControlCode << kKatrinFlt_AddressSpace) | (trigChanConvFLT[fpga][0]<<kKatrinFlt_ChannelAddress)];
}

- (void) loadTime:(unsigned long)aTime
{
	unsigned long addr = ([self slot] << 24) | (kFLTTimeCounterCode << kKatrinFlt_AddressSpace) ;
	if(broadcastTime){
		addr |= kKatrinFlt_Select_All_Slots;
	}
	[self write:addr value:aTime];
}

- (unsigned long) readTime
{
    if (usingPBusSimulation){
      return( (unsigned long)[NSDate timeIntervalSinceReferenceDate]);
    } 
	else {
	  return [self read:([self slot] << 24) | (kFLTTimeCounterCode << kKatrinFlt_AddressSpace)];
    }	
}

- (unsigned long) readTimeSubSec
{
   unsigned long addr;
   unsigned long raw;
   
   
   // TODO: Use Slt implementation [firewirecard readSubSecond]
   // ak 31.7.07
   addr = (21 << 24) | (0x1 << 18) | 0x0502; // Slt SubSecCounter 
   raw = [self read:addr];
   
   // Calculate the KATRIN subsecton counter from the auger one
   return (((raw >> 11) & 0x3fff) * 2000 + (raw & 0x7ff)) / 2;
   
}

- (void) readHitRates
{
	NS_DURING
		unsigned long aValue;
		float measurementAge;
		
		BOOL oneChanged = NO;
		float newTotal = 0;
		int chan;
		for(chan=0;chan<kNumFLTChannels;chan++){
			
			aValue = [self read:([self slot] << 24) | (kFLTHitRateCode << kKatrinFlt_AddressSpace) | (chan<<kKatrinFlt_ChannelAddress)];
			measurementAge = (aValue >> 28) & 0xf;
			aValue = aValue & 0x3fffff;
			hitRateOverFlow[chan] = (aValue >> 23) & 0x1;

			if(aValue != hitRate[chan]){

				// The hitrate counter has to be scaled by the counting time 
				// ak, 15.6.07
				if (hitRateLength!=0){  
				    hitRate[chan] = aValue/ (float) hitRateLength; 
				}
				else {
					hitRate[chan] = 0;
				}
				if(hitRateOverFlow[chan]){
					hitRate[chan] = 0;
				}
				
				oneChanged = YES;
			}
			if(!hitRateOverFlow[chan]){
				newTotal += hitRate[chan];
			}
		}
				
		[self setHitRateTotal:newTotal];
		
		if(oneChanged){
		    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHitRateChanged object:self];
		}
		NS_HANDLER
		NS_ENDHANDLER
		
		[self performSelector:@selector(readHitRates) withObject:nil afterDelay:[self hitRateLength]];
}

- (NSString*) rateNotification
{
	return ORKatrinFLTModelHitRateChanged;
}

- (BOOL) isInRunMode
{
	return [self readMode] == kKatrinFlt_Run_Mode;
}

- (BOOL) isInTestMode
{
	return [self readMode] == kKatrinFlt_Test_Mode;
}

- (BOOL) isInDebugMode
{
	return [self readMode] == kKatrinFlt_Debug_Mode;
}

- (void) loadTime
{
	//attempt to the load time as close as possible to a seconds boundary
	NSDate* then = [NSDate date];
	while(1){
		NSDate* now = [NSDate date];
		unsigned long delta = [now timeIntervalSinceDate:then];	
		if(delta >= 1){
			unsigned long timeToLoad = (unsigned long)[NSDate timeIntervalSinceReferenceDate];
			[self loadTime:timeToLoad];
			unsigned long timeLoaded = [self readTime];
			NSLog(@"loaded FLT %d with time:%@\n",[self stationNumber],[NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)timeLoaded]);
			if(timeToLoad == timeLoaded) NSLog(@"time read back OK\n");
			else						 NSLogColor([NSColor redColor],@"readBack mismatch. Time load FAILED.\n");
			break;
		}
	}
}

//testpattern stuff
- (void) rewindTP
{
	[self write:([self slot] << 24) | (kFLTTestPatternCode << kKatrinFlt_AddressSpace) | 0x2 
		  value:kKatrinFlt_TP_Control | 
				kKatrinFlt_TestPattern_Reset | 
				(tMode & 0x3)];
}

- (void) writeTestPatterns
{
	[self rewindTP];

	[self write:([self slot] << 24) | (kFLTTestPatternCode << kKatrinFlt_AddressSpace) | 0x2 
		  value:kKatrinFlt_TP_Control | kKatrinFlt_Ec2 | kKatrinFlt_Ec1 |(tMode & 0x3)];

	//write the mode and reset the r/w pointers
	[self write:([self slot] << 24) | (kFLTTestPatternCode << kKatrinFlt_AddressSpace) | 0x2 
		  value:kKatrinFlt_TP_Control | 
				kKatrinFlt_TestPattern_Reset | 
				(tMode & 0x3)];
				
	
	NSLog(@"Writing Test Patterns\n");
	int i;
	for(i= 0;i<testPatternCount;i++){
		int theValue = kKatrinFlt_PatternMask &  [[testPatterns objectAtIndex:i] intValue];
		if(i == testPatternCount-1)theValue |= kKatrinFlt_TP_End;

		[self write:([self slot] << 24) | (kFLTTestPatternCode << kKatrinFlt_AddressSpace) | ((i&0x01f)<<kKatrinFlt_ChannelAddress) | 0x2 
			  value:theValue];
		NSLog(@"%2d: 0x%x\n",i,theValue);
		if(i == testPatternCount-1)break;
	}
		
	[self rewindTP];
	
}



- (void) restartRun
{	
	// Disable trigger for the recording time
	// Q: Is the recording still active?
	[self disableTrigger]; 
	
	// Reset access pointers
	[self reset];
				  
	nextEventPage = 0;
	
	// Sleep for the recording interval
	// Times of 100us windows (max 6.4ms)
	usleep(100*readoutPages); 
	
	// Enable trigger again and wait
	[self writeTriggerControl];
	
	//NSLog(@"Reset  %x  - Pages: %d %d\n", aValue, page0, page1 ); 	
}

#pragma mark ¥¥¥¥hw histogram access
//hardware histogramming -tb- 2008-02-08
/** It serves as example of the general task  inserting new configuration variables to the model. 
  * You have to code 
  * - a new attribute in the class definition (interface)  in the model.h file
  * - a setter in the model (posting the notification with the according notification name string)
  * - a getter in the model
  * - a notification name string declaration in the model.h file
  * - the notification name string definition in the model.m file
  * - an entry in - (id)initWithCoder:(NSCoder*)decoder (for RW attributes only) (reading/writing to the .Orca file)
  * - an entry in  - (void)encodeWithCoder:(NSCoder*)encoder (for RW attributes only) (reading/writing to the .Orca file)
  * - a setter (changer) in controller.m/.h getting the current value from the model
  * - an entry in  - (void) registerNotificationObservers in controller.m
  * - an entry in - (void) updateWindow in controller.m (for the startup!)
  * - and the usual IBActions and outlets in the controller
  * - and the necessary connections in the interface builder
  * - finally RO attributs need a init section (in initWithCoder?)
  * - for the hardware wizard entries add define a section in - (NSArray*) wizardParameters
  * - for loading header parameters add a section in - (NSNumber*) extractParam
  * - for writing the variable to the XML header of the Orca data file add it to - (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
  * - ...
***/
- (int) histoBinWidth
{
    return histoBinWidth;
}

- (void) setHistoBinWidth:(int)aHistoBinWidth
{
NSLog(@"Calling setHistoBinWidth %i ...\n",aHistoBinWidth);

    [[[self undoManager] prepareWithInvocationTarget:self] setHistoBinWidth:histoBinWidth];
    histoBinWidth = aHistoBinWidth;

NSLog(@"Sending notification ...\n");
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoBinWidthChanged object:self];

    // compute max possible energy in histogram
    [self setHistoMaxEnergy: (histoMinEnergy+ ((1<<histoBinWidth)*1024))];  // temporary ? -tb- 2008-03-06
}


- (unsigned int) histoMinEnergy
{    return histoMinEnergy;    }

- (void) setHistoMinEnergy:(unsigned int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistoMinEnergy:histoMinEnergy];
    //if(aValue>=0 && aValue<=histoMaxEnergy ){    // for now histoMaxEnergy is unused -tb- 2008-03-06
    if(aValue>=0){
        histoMinEnergy = aValue;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoMinEnergyChanged object:self];

    // compute max possible energy in histogram
    [self setHistoMaxEnergy: (histoMinEnergy+ ((1<<histoBinWidth)*1024))];  // temporary ? -tb- 2008-03-06
}



- (unsigned int) histoMaxEnergy
{    return histoMaxEnergy;    }

- (void) setHistoMaxEnergy:(unsigned int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistoMaxEnergy:histoMaxEnergy];
    if(histoMinEnergy<=aValue ){
        histoMaxEnergy = aValue;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoMaxEnergyChanged object:self];
}

- (unsigned int) histoFirstBin
{    return histoFirstBin;    }

- (void) setHistoFirstBin:(unsigned int)aValue
{
    histoFirstBin = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoFirstBinChanged object:self];
}

- (unsigned int) histoLastBin
{    return histoLastBin;    }

- (void) setHistoLastBin:(unsigned int)aValue
{
    histoLastBin = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoLastBinChanged object:self];
}

- (unsigned int) histoRunTime
{    return histoRunTime;    }

- (void) setHistoRunTime:(unsigned int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistoRunTime:histoRunTime];
    histoRunTime = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoRunTimeChanged object:self];
}

- (unsigned int) histoRecordingTime
{    return histoRecordingTime;    }

- (void) setHistoRecordingTime:(unsigned int)aValue
{
    histoRecordingTime = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoRecordingTimeChanged object:self];
}

- (BOOL)   histoCalibrationIsRunning
{    return histoCalibrationIsRunning;    }

- (void)   setHistoCalibrationIsRunning: (BOOL)aValue
{
    histoCalibrationIsRunning = aValue;
}

- (double) histoTestElapsedTime
{    return histoTestElapsedTime;    }

- (void)   setHistoTestElapsedTime: (double)aTime
{
    histoTestElapsedTime=aTime;
}

- (unsigned int) histoCalibrationChan
{    return histoCalibrationChan;    }

- (void) setHistoCalibrationChan:(unsigned int)aValue
{
    histoCalibrationChan = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationChanChanged object:self];
}




- (NSMutableArray*) histogramData
{return histogramData;}

- (unsigned int*) histogramDataUI
{return histogramDataUI;}

- (unsigned int) getHistogramDataUI: (int) index
{   if(!histogramDataUI) return 200.0 + 100.0 * sin(0.01*index);   // testing: returns a sine wave
    return histogramDataUI[index];
}


- (unsigned int) readEMin
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x2; //0x2 is E_min
    unsigned int Pixel = 0; // we assume that all pixels have the same E_min, E_max, ...
    // debug output NSLog(@"readEMin: Pbus register is 0x%x\n", [self read:([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)]  ); 	

	return [self read: ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)];
    //-tb- slot 10, func b110, , E_min=0x2  is 	return [self read: 0x09c02000];

}

- (void) writeEMin:(unsigned int)EMin
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x2; //0x2 is E_min
    unsigned int Pixel = 0; // we assume that all pixels have the same E_min, E_max, ...
    // debug output NSLog(@"writeEMin: Pbus register is 0x%x, EMin is %i\n",
    // debug output    [self read:([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)], EMin  ); 	

	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: EMin];
    Pixel = 1;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: EMin];
    Pixel = 2;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: EMin];
    Pixel = 3;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: EMin];
//	[self write: 0x09c02000 value: EMin];
}

- (unsigned int) readEMax
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x3; //0x3 is E_max
    unsigned int Pixel = 0; // we assume that all pixels have the same E_min, E_max, ...
    // debug output NSLog(@"readEMax: Pbus register is 0x%x\n", [self read:([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)]  ); 	

	return [self read: ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)];
    //-tb- slot 10, func b110, , E_min=0x2  is 	return [self read: 0x09c02000];

}

- (void) writeEMax:(unsigned int)EMax
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x3; //0x3 is E_max
    unsigned int Pixel = 0; // we assume that all pixels have the same E_min, E_max, ...
    // debug output NSLog(@"writeEMax: Pbus register is %x, EMax is %i\n",
    // debug output   [self read: ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)], EMax  ); 	

	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: EMax];
    Pixel = 1;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: EMax];
    Pixel = 2;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: EMax];
    Pixel = 3;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: EMax];
//	[self write: 0x09c02000 value: EMin];
}

- (unsigned int) readTRun
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x4; //0x4 is TRun
    unsigned int Pixel = 0; // we assume that all pixels have the same E_min, E_max, ...
    // debug output NSLog(@"readTRun: Pbus register is 0x%x\n",[self read: ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) ] ); 	

	return [self read: ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)];
    //-tb- slot 10, func b110, , E_min=0x2  is 	return [self read: 0x09c02000];

}


- (void) writeTRun:(unsigned int)TRun
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x4; //0x4 is TRun
    unsigned int Pixel = 0; // we assume that all pixels have the same E_min, E_max, ...
    // debug output -tb- NSLog(@"writeEMax: Pbus register is 0x%x, TRun is %i\n",
    // debug output -tb-    [self read:([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)], TRun  ); 	

	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: TRun];
//	[self write: 0x09c02000 value: EMin];
    Pixel = 1;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: TRun];
    Pixel = 2;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: TRun];
    Pixel = 3;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: TRun];
}

/** Set the bin width and the start bit for hardware histogramming (all pixels).
  */  //-tb-
- (void) writeStartHistogram:(unsigned int)aHistoBinWidth
{
    //HistControlReg
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x1; //0x1 is Histogrm:ControlReg
    unsigned int Pixel = 0; // we assume that all pixels have the same E_min, E_max, ...
    unsigned int numBins = 0x3ff;         // N of Bins: 10 bit value, all to 1 => 0x3ff = 1023
    unsigned int eSample = aHistoBinWidth; // BW = E_Sample (observed energy is shifted by E_Sample:
                                          //                obsEnergy >> E_Sample, possible val. 0...8)
    unsigned int startBit = 0x1;
    unsigned int regVal= (numBins << 6) | (eSample << 2) | (startBit);
    
    
    //NSLog(@"readLastBinOfPixel:%i Pbus register is %x\n",aPixel, ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)  ); 	

    Pixel = 0;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: regVal];
    Pixel = 1;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: regVal];
    Pixel = 2;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: regVal];
    Pixel = 3;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: regVal];

}

/** Write the stop bit for hardware histogramming (all pixels). Reads the current register contents,
  * flips the stop bit and write it back (so all other settings stay unchanged).
  */  //-tb-
- (void) writeStopHistogram
{
    //stop histogramming
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x1; //0x1 is Histogrm:ControlReg
    unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12);
    unsigned int regVal;
    
    Pixel = 0; 
    adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12);
    regVal = [self read: adress];// read  HistogrmControlReg
    regVal &= 0xfffffffe;// set the start/stop bit to 0=stop   TODO: read current status, flip stop bit and write back -tb-
	[self write: adress value: regVal];
    
    Pixel = 1; 
    adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12);
    regVal = [self read: adress];// read  HistogrmControlReg
    regVal &= 0xfffffffe;// set the start/stop bit to 0=stop   TODO: read current status, flip stop bit and write back -tb-
	[self write: adress value: regVal];
    
    Pixel = 2; 
    adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12);
    regVal = [self read: adress];// read  HistogrmControlReg
    regVal &= 0xfffffffe;// set the start/stop bit to 0=stop   TODO: read current status, flip stop bit and write back -tb-
	[self write: adress value: regVal];

    Pixel = 3; 
    adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12);
    regVal = [self read: adress];// read  HistogrmControlReg
    regVal &= 0xfffffffe;// set the start/stop bit to 0=stop   TODO: read current status, flip stop bit and write back -tb-
	[self write: adress value: regVal];
    
}

- (unsigned int) readTRec
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x5; //0x5 is T_Rec
    unsigned int Pixel = 0; // we assume that all pixels have the same E_min, E_max, ...
    // debug output -tb- NSLog(@"readTRec: Pbus register is 0x%x\n", [self read:([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)  ]); 	

	return [self read: ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)];
}

- (unsigned int) readFirstBinOfPixel:(unsigned int)aPixel
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x6; //0x6 is FirstBin
    unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
    if(aPixel == 0) Pixel=0;
    if(aPixel == 1) Pixel=1;
    if(aPixel == 12) Pixel=2;
    if(aPixel == 13) Pixel=3;
    
    // debug output -tb- NSLog(@"readFirstBinOfPixel:%i Pbus register is 0x%x\n",aPixel,[self read: ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)]  ); 	

	return [self read: ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)];
	//return [self read: 0x09c06000];
}

- (unsigned int) readLastBinOfPixel:(unsigned int)aPixel
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x7; //0x7 is LastBin
    unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
    if(aPixel == 0) Pixel=0;
    if(aPixel == 1) Pixel=1;
    if(aPixel == 12) Pixel=2;
    if(aPixel == 13) Pixel=3;
    
    // debug output -tb- NSLog(@"readLastBinOfPixel:%i Pbus register is 0x%x\n",aPixel, [self read:([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)]  ); 	

	return [self read: ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)];
	//return [self read: 0x09c07000];
}

/** Start hardware histogramming test run ... usually called from GUI.
  *
  */ //-tb-
- (void) startHistogramOfPixel:(unsigned int)aPixel //TODO: rename to startCalibratingHistogramOfPixel -tb- 2008-03-05
{
	//check that we can actually run  TODO: do I need it here ? -tb-
    if(![[[self crate] adapter] serviceIsAlive]){
		[NSException raise:@"No FireWire Service" format:@"startHistogramOfPixel: Check Crate Power and FireWire Cable."]; 
    }
    
    //stop histogramming (maybe histogramming is still running from a previous run)
    [self writeHistogramControlRegisterOfPixel:aPixel value:([self readHistogramControlRegisterOfPixel:aPixel]&0xfffffffe)];

    //write configuration:
    //set gains, thresholds, shaping
	[self loadThresholdsAndGains];
    //writeTriggerControl: see below ...

    //set to energy mode (fltRunMode = 1)
    oldFltRunModeMode=fltRunMode;
    [self setFltRunMode: kKatrinFlt_Run_Mode]; //TODO: maybe better set daqEnergyMode ? -tb- 2008-02-15
    // or: stop the run when not in run mode ...
    [self writeMode: fltRunMode]; //TODO: HANDLE EXCEPTION -TB-
    NSLog(@"startHistogramOfPixel: WARNING: setFltRunMode to %x (was %x)\n",kKatrinFlt_Run_Mode,oldFltRunModeMode);
    
    //SLT: release SW inhibit
    sltmodel = [[self crate] adapter];
    [sltmodel releaseSwInhibit];
    

    { // this could be removed -tb-
    unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
    if(aPixel == 0) Pixel=0;
    if(aPixel == 1) Pixel=1;
    if(aPixel == 12) Pixel=2;
    if(aPixel == 13) Pixel=3;
    //aPixel should be == histoCalibrationChan

    //enable trigger - see - (void) writeTriggerControl
    [self writeTriggerControl];
    NSLog(@"startHistogramOfPixel: WARNING: triggerControl for current pixel is %i\n",
        [[triggersEnabled objectAtIndex:Pixel] intValue] );
    NSLog(@"startHistogramOfPixel: WARNING: triggerControl for current pixel is 0x%x\n",
        [self readTriggerControl: Pixel]);
    }
    
    
    //histogramming registers
    [self writeEMin:histoMinEnergy];
    [self writeEMax:histoMaxEnergy];
    [self writeTRun:histoRunTime];

    //start histogramming
    //HistControlReg
    #if 1
    [self writeStartHistogram:histoBinWidth];
    #else
    //TODO: obsolete, remove it
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x1; //0x1 is Histogrm:ControlReg
    unsigned int numBins = 0x3ff;         // N of Bins: 10 bit value, all to 1 => 0x3ff = 1023
    unsigned int eSample = histoBinWidth; // BW = E_Sample (observed energy is shifted by E_Sample:
                                          //                obsEnergy >> E_Sample, possible val. 0...8)
    unsigned int startBit = 0x1;
    unsigned int regVal= (numBins << 6) | (eSample << 2) | (startBit);
    
    
    //NSLog(@"readLastBinOfPixel:%i Pbus register is %x\n",aPixel, ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)  ); 	

	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12) value: regVal];
	//[self write: 0x09c01000 value: 0x0000ffc1]; //no E_Sample/shift
	//[self write: 0x09c01000 value: 0x0000ffc9];
    #endif
    
    //set vars
    histoTestElapsedTime = 0.0;
    histoCalibrationIsRunning = TRUE;
    //remember the start time TODO: work in progress -tb- 2008-02-18
    // there are (Auger) methods readTime and readTimeSubSec (from self), do they work for Katrin? -tb-
    struct timeval t;//    struct timezone tz; is obsolete ... -tb-
    gettimeofday(&t,NULL);
    histoStartTimeSec = t.tv_sec;  
    histoStartTimeUSec = t.tv_usec;  

    // send notification to GUI
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoTestValuesChanged object:self];

    // start delayed timing ...
    [self performSelector:@selector(checkHistogramTest) withObject:nil afterDelay:0.1 /*sec*/];

}


/** This implements the histogramming "test run loop".
  * Updates the GUI with the current histogramming parameters.
  * Check wether hardware histogramming still runs (histoTestIsRunning is TRUE)  ... if yes restart itself ...
  *
  */ //-tb-
- (void) checkHistogramTest
{
	//check that we can actually run  TODO: do I need it here ? -tb-
    if(![[[self crate] adapter] serviceIsAlive]){
        histoCalibrationIsRunning = FALSE;
		[NSException raise:@"No FireWire Service" format:@"checkHistogramOfPixel: Check Crate Power and FireWire Cable."]; 
    }
    
    
    unsigned int aPixel=0;   //TODO: for release version check all pixels ? -tb-

    //NSLog(@"This is checkHistogramOfPixel: \n"  ); 	
        //update time
        int histoCurrTimeSec; 
        int histoCurrTimeUSec; 
        struct timeval t;//    struct timezone tz; is obsolete ... -tb-
        gettimeofday(&t,NULL);
        histoCurrTimeSec = t.tv_sec;  
        histoCurrTimeUSec = t.tv_usec; 
        histoTestElapsedTime = (double)(histoCurrTimeSec - histoStartTimeSec) + 0.000001 * (double)(histoCurrTimeUSec - histoStartTimeUSec);
        //NSLog(@"This is checkHistogramOfPixel:       %20i %20i \n",  histoCurrTimeSec,histoCurrTimeUSec); 	
        //NSLog(@"This is checkHistogramOfPixel:       %20.12f \n",  histoTestElapsedTime); 	
        
        // recording time
        [self setHistoRecordingTime:[self readTRec]];
        [self setHistoFirstBin:[self readFirstBinOfPixel:aPixel]];
        [self setHistoLastBin:[self readLastBinOfPixel:aPixel]];
        
        // send notification to GUI
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoTestValuesChanged object:self];


    if(histoCalibrationIsRunning){
        //restart timing ...
        [self performSelector:@selector(checkHistogramTest) withObject:nil afterDelay:0.1 /*sec*/];
    }

}


/** Stop hardware histogramming test run ...
  *
  */ //-tb-
//write 09c01000 0000ffc0
- (void) stopHistogramOfPixel:(unsigned int)aPixel
{
    //set vars
    histoCalibrationIsRunning = FALSE;
    
    //stop histogramming
    #if 1
    [self writeStopHistogram];
    #else
    //TODO: obsolete -tb-
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x1; //0x1 is Histogrm:ControlReg
    unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
    if(aPixel == 0) Pixel=0;
    if(aPixel == 1) Pixel=1;
    if(aPixel == 12) Pixel=2;
    if(aPixel == 13) Pixel=3;
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12);

    // read  HistogrmControlReg
    unsigned int regVal;
    regVal = [self read: adress];
    // or     unsigned int regVal = [self  readHistogramControlRegisterOfPixel:aPixel];
    NSLog(@"stopHistogramOfPixel:%i HistogrmControlReg register is 0x%x\n",aPixel, regVal ); 	

    regVal &= 0xfffffffe;// set the start/stop bit to 0=stop   TODO: read current status, flip stop bit and write back -tb-
	[self write: adress value: regVal];
    #endif

    //TIMING
    //remember the stop time TODO: work in progress -tb- 2008-02-18
    // there are (Auger) methods readTime and readTimeSubSec (from self), do they work for Katrin? -tb-
    struct timeval t;//    struct timezone tz; is obsolete ... -tb-
    gettimeofday(&t,NULL);
    histoStopTimeSec = t.tv_sec;  
    histoStopTimeUSec = t.tv_usec;  
    histoTestElapsedTime = (histoStopTimeSec - histoStartTimeSec) + 0.000001 * (histoStopTimeUSec - histoStartTimeUSec);
    // send notification to GUI
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoTestValuesChanged object:self];
    
    //RESTORE LAST SETTINGS:
    //reset fltRunMode to previous value before startHistogramOfPixel
    [self setFltRunMode: oldFltRunModeMode];
    [self writeMode: fltRunMode]; //TODO: HANDLE EXCEPTION -TB-
    NSLog(@"stopHistogramOfPixel: WARNING: reset FltRunMode to %x \n",kKatrinFlt_Run_Mode);
    
    //SLT: set SW inhibit
    sltmodel = [[self crate] adapter];
    [sltmodel setSwInhibit];
    
    //wait one second (HW histogramming is every second strobe) then display histogram ...
    #if 0
    [self performSelector:@selector(oneSecAfterStopHistogramOfPixel) withObject:nil afterDelay:1.01 /*sec*/];
    #else
    usleep(1000001);
    [self checkHistogramTest];
    unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
    [self readHistogramDataOfPixel:Pixel];
    // send notification to GUI
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoTestPlotterWantDisplay object:self];
    #endif
}

// unused, could be removed in the future  -tb-
- (void) oneSecAfterStopHistogramOfPixel
{
    // send notification to GUI
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoTestValuesChanged object:self];

    [self readHistogramDataOfPixel:0]; //TODO: only for testing pixel 0 -tb- 2008-03-05

}

/** This is called at the end of a histogramming calibration run or when pressing the button
  * "Read Histogram Data".
  */
- (void) readHistogramDataOfPixel:(unsigned int)aPixel
{
    unsigned int i,firstBin, lastBin, currVal, sum;
    firstBin = [self readFirstBinOfPixel:aPixel];
    lastBin  = [self readLastBinOfPixel:aPixel];
    NSLog(@"readHistogramDataOfPixel  %u: has range %u ... %u \n",aPixel, firstBin , lastBin); 	

    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0xC; //0xC is Histogrm:HDATA
    unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
    if(aPixel == 0) Pixel=0;
    if(aPixel == 1) Pixel=1;
    if(aPixel == 12) Pixel=2;
    if(aPixel == 13) Pixel=3;
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12);

    for(i=0; i<1024; i++){
            histogramDataUI[i]= 0;
    }
    sum = 0;
    for(i=firstBin; i<=lastBin; i++){
        currVal =  [self read: adress | i];
        sum += currVal;
        NSLog(@"    bin %4u: %4u \n",i , currVal); 	
        //[[histogramData objectAtIndex:i] setIntValue:currVal];
        histogramDataUI[i]= currVal;
    }
    NSLog(@"sum: %4u \n",sum); 	
}

- (unsigned int) readHistogramDataOfPixel:(unsigned int)aPixel atBin:(unsigned int)aBin 
{
    unsigned int currVal;
    //unsigned int firstBin, lastBin ;
    //firstBin = [self readFirstBinOfPixel:aPixel];
    //lastBin  = [self readLastBinOfPixel:aPixel];
    //NSLog(@"readHistogramDataOfPixel  %u: has range %u ... %u \n",aPixel, firstBin , lastBin); 	

    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0xC; //0xC is Histogrm:HDATA
    unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
    if(aPixel == 0) Pixel=0;
    if(aPixel == 1) Pixel=1;
    if(aPixel == 12) Pixel=2;
    if(aPixel == 13) Pixel=3;
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12);

    currVal =  [self read: adress | aBin];
    
    return currVal;
}

/** Read out the current status and display it on Log Window.
  */
- (void) readCurrentStatusOfPixel:(unsigned int)aPixel  //TODO: rename to histogrammingIsRunning and return a BOOL? -tb- 2008-02-27
{
    NSLog(@"Current Status Of Histogramming Calibration Run: histoCalibrationIsRunning = %i \n",histoCalibrationIsRunning ); 
    // read  HistTriggControlReg
    unsigned int regVal = [self  readHistogramControlRegisterOfPixel:aPixel];
    NSLog(@"Current Status Of Pixel:%i HistTriggControlReg register is %x\n",aPixel, regVal ); 
    if(	regVal & 0x1 ) NSLog(@"  Hardware Histograming is: RUNNING\n");
    else NSLog(@"  Hardware Histograming is: STOPPED\n");
    NSLog(@"  E_Sample/BW is %u\n",(regVal & 0x3c) >> 2);
}

- (unsigned int) readHistogramControlRegisterOfPixel:(unsigned int)aPixel;
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x1; //0x1 is Histogrm:ControlReg
    unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
    if(aPixel == 0) Pixel=0;
    if(aPixel == 1) Pixel=1;
    if(aPixel == 12) Pixel=2;
    if(aPixel == 13) Pixel=3;
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12);

    // read  HistTriggControlReg
    unsigned int regVal;
    regVal = [self read: adress];
    return regVal;
}

- (void) writeHistogramControlRegisterOfPixel:(unsigned int)aPixel value:(unsigned int)aValue;
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x1; //0x1 is Histogrm:ControlReg
    unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
    if(aPixel == 0) Pixel=0;
    if(aPixel == 1) Pixel=1;
    if(aPixel == 12) Pixel=2;
    if(aPixel == 13) Pixel=3;
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12);

    // write  HistTriggControlReg
    [self write: adress value: aValue];
}



// veto stuff
- (void) setVetoEnable:(int)aState
{
    unsigned int func  = 0x0; // = b000
    unsigned int LAddr0 = 0x1; //0x1 is ControlStatusReg2
    unsigned int Pixel = 0; // TODO: for testing: ignored
    //if(aPixel == 0) Pixel=0;
    //if(aPixel == 1) Pixel=1;
    //if(aPixel == 12) Pixel=2;
    //if(aPixel == 13) Pixel=3;
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr0);
    
    //unsigned int enableBit = 0x1 ;
    unsigned int regVal= 0x1 & aState;
    
    
    //NSLog(@"readLastBinOfPixel:%i Pbus register is %x\n",aPixel, ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)  ); 	
    NSLog(@"  setVetoEnable: adress %8x, state %8x\n",adress,regVal  ); 	

	[self write:   adress value: regVal];

}

- (int) readVetoState
{
    unsigned int func  = 0x0; // = b000
    unsigned int LAddr0 = 0x1; //0x1 is ControlStatusReg2
    unsigned int Pixel = 0; // TODO: for testing: ignored
    //if(aPixel == 0) Pixel=0;
    //if(aPixel == 1) Pixel=1;
    //if(aPixel == 12) Pixel=2;
    //if(aPixel == 13) Pixel=3;
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr0);
    
    //unsigned int enableBit = 0x1 ;
    //unsigned int regVal= 0x1 & aState;
    unsigned int regVal ;
    
    
    //NSLog(@"readLastBinOfPixel:%i Pbus register is %x\n",aPixel, ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)  ); 	

	regVal = [self read:   adress ];
    NSLog(@"  vetoState: adress %8x, state %8x\n",adress,regVal  ); 	
    return regVal;

}

- (void) readVetoDataFrom:(int)fromIndex to:(int)toIndex
{
    static int max = 511; // 1024?
    if(fromIndex <0)    fromIndex =0;
    if(fromIndex >max)  fromIndex =max;
    if(toIndex <0)      toIndex   =0;
    if(toIndex >max)    toIndex   =max;
    if(fromIndex>toIndex) toIndex=fromIndex;
    unsigned int func  = 0x5; // = b101 = TriggerData
    unsigned int baseadress  = ([self slot] << 24) | (func << 21);
    unsigned int adress;
    
    unsigned int word00, word01, word10;
    int i;
    for(i=fromIndex; i<=toIndex; i++){
        adress = baseadress | (i << 2);
        word00 = [self read:   adress ];
        word01 = [self read:   adress | 1];
        word10 = [self read:   adress | 2];
        NSLog(@"    adresses: %10x, %10x, %10x\n", adress , adress |1, adress|2);
        NSLog(@"    values  : %10x, %10x, %10x\n", word00 , word01, word10);
        NSLog(@"  eventID %8i, channelmap %8x, sec:sub %8i:%8i\n",word00 & 0x3ff,word00 >>10,word10,word01  ); 	

    }
}






#pragma mark ¥¥¥Archival
/** Define here what to read from the .Orca file. These are e.g. state of check boxes, content of text fields (gains,
  * thresholds,...), internal state values (daqRunMode, ...),  etc. 
  *
  */ //-tb-
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setCheckWaveFormEnabled:[decoder decodeBoolForKey:@"ORKatrinFLTModelCheckWaveFormEnabled"]];
    [self setTestPatternCount:	[decoder decodeIntForKey:@"ORKatrinFLTModelTestPatternCount"]];
    [self setTMode:				[decoder decodeIntForKey:@"ORKatrinFLTModelTMode"]];
    [self setPage:				[decoder decodeIntForKey:@"ORKatrinFLTModelPage"]];
    [self setIterations:		[decoder decodeIntForKey:@"ORKatrinFLTModelIterations"]];
    [self setEndChan:			[decoder decodeIntForKey:@"ORKatrinFLTModelEndChan"]];
    [self setStartChan:			[decoder decodeIntForKey:@"ORKatrinFLTModelStartChan"]];
    [self setBroadcastTime:		[decoder decodeBoolForKey:@"ORKatrinFLTModelBroadcastTime"]];
    [self setHitRateLength:		[decoder decodeIntForKey:@"ORKatrinFLTModelHitRateLength"]];
    [self setShapingTimes:		[decoder decodeObjectForKey:@"ORKatrinFLTModelShapingTimes"]];
    [self setTriggersEnabled:	[decoder decodeObjectForKey:@"ORKatrinFLTModelTriggersEnabled"]];
    [self setTestPatterns:		[decoder decodeObjectForKey:@"testPatterns"]];
    [self setGains:				[decoder decodeObjectForKey:@"gains"]];
    [self setThresholds:		[decoder decodeObjectForKey:@"thresholds"]];
    [self setDaqRunMode:		[decoder decodeIntForKey:@"daqRunMode"]];// -tb- 2008-01-31   was daqMode
    [self setFltRunMode:		[decoder decodeIntForKey:@"mode"]];   // -tb- 2008-02-16  TODO: maybe fltRunMode is better?
    if(![decoder containsValueForKey:@"daqRunMode"]){// this is for backward compatibility for old files
        [self setDaqRunMode:fltRunMode];
    }
    [self setHitRatesEnabled:	[decoder decodeObjectForKey:@"hitRatesEnabled"]];
    [self setTotalRate:			[decoder decodeObjectForKey:@"totalRate"]];
	[self setTestEnabledArray:	[decoder decodeObjectForKey:@"testsEnabledArray"]];
	[self setTestStatusArray:	[decoder decodeObjectForKey:@"testsStatusArray"]];
    [self setReadoutPages:		[decoder decodeIntForKey:@"ORKatrinFLTModelReadoutPages"]];	// ak, 2.7.07
    //hardware histogram stuff -tb- 2008-02-08
    [self setHistoBinWidth:		[decoder decodeIntForKey:@"ORKatrinFLTModelHistoBinWidth"]];
    [self setHistoMinEnergy:		[decoder decodeIntForKey:@"ORKatrinFLTModelHistoMinEnergy"]];
    //[self setHistoMaxEnergy:		[decoder decodeIntForKey:@"ORKatrinFLTModelHistoMaxEnergy"]]; // for now: unused -tb- 2008-03-06
    //[self setHistoFirstBin:		[decoder decodeIntForKey:@"ORKatrinFLTModelHistoFirstBin"]];
    //[self setHistoLastBin:		[decoder decodeIntForKey:@"ORKatrinFLTModelHistoLastBin"]];
    [self setHistoRunTime:		[decoder decodeIntForKey:@"ORKatrinFLTModelHistoRunTime"]];
    [self setHistoCalibrationChan:		[decoder decodeIntForKey:@"ORKatrinFLTModelHistoCalibrationChan"]];
    //[self setHistoRecordingTime:		[decoder decodeIntForKey:@"ORKatrinFLTModelHistoRecordingTime"]];
    //NSLog(@"Decoding ORKatrinFLTModelHistoBinWidth is %i\n",[decoder decodeIntForKey:@"ORKatrinFLTModelHistoBinWidth"]);
    
	
	// TODO: Get reference to Slt model
	//sltmodel = [decoder decodeObjectForKey:@"ORKatrinFLTModel"]; //NO! when you need an slt reference do:
	//sltmodel = [[self crate] adapter];
	
	//make sure these objects exist and are populated with nil objects.
	int i;
	if(!shapingTimes){
		[self setShapingTimes: [NSMutableArray array]];
		for(i=0;i<4;i++)[shapingTimes addObject:[NSNumber numberWithInt:0]];
	}
	
	if(!triggersEnabled){
		[self setTriggersEnabled: [NSMutableArray array]];
		for(i=0;i<kNumFLTChannels;i++) [triggersEnabled addObject:[NSNumber numberWithBool:YES]];
	}
	
	if(!hitRatesEnabled){
		[self setHitRatesEnabled: [NSMutableArray array]];
		for(i=0;i<kNumFLTChannels;i++) [hitRatesEnabled addObject:[NSNumber numberWithBool:YES]];
	}
	
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
		for(i=0;i<kNumKatrinFLTTests;i++) [testStatusArray addObject:@"--"];
	}

	if(!testPatterns){
		[self setTestPatterns: [NSMutableArray array]];
		for(i=0;i<24;i++) [testPatterns addObject:[NSNumber numberWithInt:0]];
	}

	if(!testEnabledArray){
		[self setTestEnabledArray: [NSMutableArray array]];
		for(i=0;i<kNumKatrinFLTTests;i++) [testEnabledArray addObject:[NSNumber numberWithBool:YES]];
	}
    
    //startup values -tb- 2008-02-11
    [self setHistoFirstBin:	1023];
    [self setHistoLastBin:	0];
    [self setHistoRecordingTime:0];
    #if 0   //TODO: what is better:  unsigned int* or NSMutableArray* ??? -tb- 32008-02-11
	if(!histogramData){
		//[self setThresholds: [NSMutableArray array]];
        histogramData = [NSMutableArray arrayWithCapacity:1024];
		for(i=0;i<1024;i++) [histogramData addObject:[NSNumber numberWithInt:0]];
	}
    #endif
    //alloc unsigned int* histogramDataUI; .... see init ...
	if(!histogramDataUI){
		//[self setThresholds: [NSMutableArray array]];
        histogramDataUI =  (unsigned int*)malloc(1024*sizeof(unsigned int));
		for(i=0;i<1024;i++) histogramDataUI[i]=0;
	}

		

    [[self undoManager] enableUndoRegistration];
	
    return self;
}

/** Define here what to write to the .Orca file.
  */ //-tb-
- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
    [encoder encodeBool:checkWaveFormEnabled forKey:@"ORKatrinFLTModelCheckWaveFormEnabled"];
    [encoder encodeInt:testPatternCount     forKey:@"ORKatrinFLTModelTestPatternCount"];
    [encoder encodeInt:tMode				forKey:@"ORKatrinFLTModelTMode"];
    [encoder encodeInt:page					forKey:@"ORKatrinFLTModelPage"];
    [encoder encodeInt:iterations			forKey:@"ORKatrinFLTModelIterations"];
    [encoder encodeInt:endChan				forKey:@"ORKatrinFLTModelEndChan"];
    [encoder encodeInt:startChan			forKey:@"ORKatrinFLTModelStartChan"];
    [encoder encodeBool:broadcastTime		forKey:@"ORKatrinFLTModelBroadcastTime"];
    [encoder encodeInt:hitRateLength		forKey:@"ORKatrinFLTModelHitRateLength"];
    [encoder encodeObject:shapingTimes		forKey:@"ORKatrinFLTModelShapingTimes"];
    [encoder encodeObject:triggersEnabled	forKey:@"ORKatrinFLTModelTriggersEnabled"];
    [encoder encodeObject:testPatterns		forKey:@"testPatterns"];
    [encoder encodeObject:gains				forKey:@"gains"];
    [encoder encodeObject:thresholds		forKey:@"thresholds"];
    [encoder encodeObject:hitRatesEnabled	forKey:@"hitRatesEnabled"];
    [encoder encodeInt:daqRunMode			forKey:@"daqRunMode"];// -tb- 2008-01-31
    [encoder encodeInt:fltRunMode			forKey:@"mode"];
    [encoder encodeObject:totalRate			forKey:@"totalRate"];
    [encoder encodeObject:testEnabledArray	forKey:@"testEnabledArray"];
    [encoder encodeObject:testStatusArray	forKey:@"testStatusArray"];
    [encoder encodeInt:readoutPages  		forKey:@"ORKatrinFLTModelReadoutPages"];	
    //hardware histogram stuff -tb- 2008-02-08
    [encoder encodeInt:histoBinWidth  		forKey:@"ORKatrinFLTModelHistoBinWidth"];	
    [encoder encodeInt:histoMinEnergy  		forKey:@"ORKatrinFLTModelHistoMinEnergy"];	
    //[encoder encodeInt:histoMaxEnergy  		forKey:@"ORKatrinFLTModelHistoMaxEnergy"];	for now: unused -tb- 2008-03-06
    //[encoder encodeInt:histoFirstBin  		forKey:@"ORKatrinFLTModelHistoFirstBin"];	
    //[encoder encodeInt:histoLastBin  		forKey:@"ORKatrinFLTModelHistoLastBin"];	
    [encoder encodeInt:histoRunTime  		forKey:@"ORKatrinFLTModelHistoRunTime"];	
    //[encoder encodeInt:histoRecordingTime   forKey:@"ORKatrinFLTModelHistoRecordingTime"];	
    [encoder encodeInt:histoCalibrationChan  forKey:@"ORKatrinFLTModelHistoCalibrationChan"];	
    


    
    
    
    
    
    

}

/** Define here all types of data records. Define the decoder selector with \@"decoder".
  * The "dataID" is assigned by the assigner, see setDataIds or - (void) setDataIds:(id)assigner.
  * The decoders are defined in \file ORKatrinFLTDecoder.m
  *  
  * This will go to the XML header of the data file.
  */ //-tb- 2008-02-6
- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORKatrinFLTDecoderForEnergy",      @"decoder",
        [NSNumber numberWithLong:dataId],   @"dataId",
        [NSNumber numberWithBool:YES],      @"variable",
        [NSNumber numberWithLong:-1],		@"length",
        nil];

    [dataDictionary setObject:aDictionary forKey:@"KatrinFLT"];//TODO: rename to KatrinFLTEnergy? -tb-
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORKatrinFLTDecoderForWaveForm",		@"decoder",
        [NSNumber numberWithLong:waveFormId],   @"dataId",
        [NSNumber numberWithBool:YES],			@"variable",
        [NSNumber numberWithLong:-1],			@"length",
        nil];

    //debug output NSLog(@"waveFormID (KatrinFLTWaveForm) is %i\n",waveFormId); //TODO: remove it -tb-
    [dataDictionary setObject:aDictionary forKey:@"KatrinFLTWaveForm"];
	
    // -tb- 2008-02-01
    //daqRunMode = TODO: fill in the mode -tb-
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORKatrinFLTDecoderForHitRate",  		@"decoder",  //in ORKatrinFLTDecoder.h/.m
        [NSNumber numberWithLong:hitRateId],    @"dataId",
        [NSNumber numberWithBool:YES],			@"variable",
        [NSNumber numberWithLong:-1],			@"length",
        nil];

    [dataDictionary setObject:aDictionary forKey:@"KatrinFLTHitRate"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORKatrinFLTDecoderForThresholdScan",  @"decoder",  //renamed from ORKatrinFLTDecoderForHitRate-tb-
        [NSNumber numberWithLong:thresholdScanId],    @"dataId",
        [NSNumber numberWithBool:YES],			@"variable",
        [NSNumber numberWithLong:-1],			@"length",
        nil];

    [dataDictionary setObject:aDictionary forKey:@"KatrinFLTThresholdScan"];
    
    // for the hardware histogram
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORKatrinFLTDecoderForHistogram",  	@"decoder",
        [NSNumber numberWithLong:histogramId],  @"dataId",
        [NSNumber numberWithBool:YES],			@"variable",
        [NSNumber numberWithLong:-1],			@"length",
        nil];

    [dataDictionary setObject:aDictionary forKey:@"KatrinFLTHistogram"];
    
    // for the veto data
    #if 0
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORKatrinFLTDecoderForVeto",  		    @"decoder",  //TODO:  will be needed for VETO  -tb-
        [NSNumber numberWithLong:vetoId],       @"dataId",
        [NSNumber numberWithBool:YES],			@"variable",
        [NSNumber numberWithLong:-1],			@"length",
        nil];

    [dataDictionary setObject:aDictionary forKey:@"KatrinFLTVeto"];
    #endif
    
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithLong:dataId],				@"dataId",
		[NSNumber numberWithLong:kNumFLTChannels],		@"maxChannels",
								nil];
	
	[anEventDictionary setObject:aDictionary forKey:@"KatrinFLT"];
}

/** This will go to the XML header of the data file.
  */ //-tb- 2008-02-6
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:thresholds			forKey:@"thresholds"];
    [objDictionary setObject:gains				forKey:@"gains"];
    [objDictionary setObject:hitRatesEnabled	forKey:@"hitRatesEnabled"];
    [objDictionary setObject:triggersEnabled	forKey:@"triggersEnabled"];
    [objDictionary setObject:shapingTimes		forKey:@"shapingTimes"];
    [objDictionary setObject:[NSNumber numberWithInt:daqRunMode]    		forKey:@"daqRunMode"];
	//TODO: maybe a string is better?(!) or both? -tb- 2008-02-27
    
    
	return objDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{

	firstTime = YES;
    nLoops = 0; // Counter for the readout loops
    nEvents = 0;

    [self clearExceptionCount];
	
	//check that we can actually run
    if(![[[self crate] adapter] serviceIsAlive]){
		[NSException raise:@"No FireWire Service" format:@"Check Crate Power and FireWire Cable."]; 
    }

    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORKatrinFLTModel"];    
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
		
    //TODO: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //TODO: commented out since last update (r694) - why? -tb- 
    //TODO: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //if([[userInfo objectForKey:@"doinit"]intValue]){
	//	[self initBoard];					
	//}
	
	if(fltRunMode == kKatrinFlt_Debug_Mode)	[self restartRun]; //reset the trigger //TODO: we probably should check the daqRunMode instead of the fltMode -tb- 2008-02-29
	else                                    [self reset];      //reset the r/w pointer
	
	[self loadTime];					//set the time on the flts to mac time
	[self writeMode:fltRunMode];
	[self writeHitRateMask];			//set the hit rate masks
	[self writeTriggerControl];			//set trigger mask
	[self loadThresholdsAndGains];
	
	if(ratesEnabled){
		[self performSelector:@selector(readHitRates) 
				   withObject:nil 
				   afterDelay:[self hitRateLength]];		//start reading out the rates
	}
	
	//cache some addresses for speed in the dataTaking loop.
	unsigned long theSlotPart = [self slot]<<24;
	statusAddress			  = theSlotPart;
	triggerMemAddress		  = theSlotPart | (kFLTTriggerDataCode << kKatrinFlt_AddressSpace); 
	memoryAddress			  = theSlotPart | (kFLTAdcDataCode << kKatrinFlt_AddressSpace); 
	fireWireCard			  = [[self crate] adapter];
	locationWord			  = (([self crateNumber]&0x0f)<<21) | ([self stationNumber]& 0x0000001f)<<16;
  	usingPBusSimulation		  = [fireWireCard pBusSim];
	
    // Class member to store the last handled page, ak 15.6.07
	nextEventPage = 0; // Start with page 0
	lastEventId = 8888; // Unknown

	generateTrigger = 0;
	nMissingEvents = 0;
	nSkippedEvents = 0;
	overflowDetected = false;
	nBuffer = 0;

	// Information for measurement mode
    lastSec = 0; 
	activeChMap = 0;
	for (i=0;i<22;i++){
	  if([self hitRateEnabled:i] && [self triggerEnabled:i]) 
	    activeChMap = activeChMap | (0x1 << i);
	 
	  // Set initial thresholds
	  actualThreshold[i] = [self threshold:i]; 
	  savedThreshold[i]  = [self threshold:i]; 
	  lastThreshold[i]   = [self threshold:i]; 
	  stepThreshold[i]   = 2;
	  
	  maxHitrate[i]  = 0;
	  lastHitrate[i] = 0;
	  nNoChanges[i]  = 0;
	}
	
	if(fltRunMode == kKatrinFlt_Measure_Mode){	
	   // TODO: Set hitrate length always to one
	}

    if(usingPBusSimulation){
      activeChMap = 0x25; // Three testing channels
	} 
	 
 	//[self writeControlStatus:kKatrinFlt_Intack];

    // TODO: Check if reset counters are availabe
	//set to false for now so we can use ORCARoot MAH 7/20/07
	useResetTimestamp = true;
	//----------------

    NS_DURING
		resetSec = [self read:([self slot] << 24) | (kFLTTimeCounterCode << kKatrinFlt_AddressSpace) | 0x01 ] ;		
	NS_HANDLER
		useResetTimestamp = NO;
		NSLog(@"Warning: Old design - reset timestamps not available");
	NS_ENDHANDLER	
    
    // write the options for hardware histogramming and activate histogramming -tb- 2008-03-05
    if(daqRunMode == kKatrinFlt_DaqHistogram_Mode){	
        // write TRun, EMin, EMax, BinWidth
        //stop histogramming (maybe histogramming is still running from a previous run)
        unsigned int aPixel=0;
        [self writeHistogramControlRegisterOfPixel:aPixel value:([self readHistogramControlRegisterOfPixel:aPixel]&0xfffffffe)];
        aPixel=1;
        [self writeHistogramControlRegisterOfPixel:aPixel value:([self readHistogramControlRegisterOfPixel:aPixel]&0xfffffffe)];
        aPixel=2;
        [self writeHistogramControlRegisterOfPixel:aPixel value:([self readHistogramControlRegisterOfPixel:aPixel]&0xfffffffe)];
        aPixel=3;
        [self writeHistogramControlRegisterOfPixel:aPixel value:([self readHistogramControlRegisterOfPixel:aPixel]&0xfffffffe)];

        
        //TODO: the following is from startHistogramOfPixel and should be moved to a new method -tb- 2008-03-05
        //write histogramming registers (writes all pixels)
        [self writeEMin:histoMinEnergy];
        [self writeEMax:histoMaxEnergy];
        [self writeTRun:histoRunTime];
        //write HistControlReg to set bin width and to start histogramming
        [self writeStartHistogram:histoBinWidth];
    }
    
}


//**************************************************************************************
// Function:	

// Description: Read data from a card
//****************************g**********************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{	
    NS_DURING	
	   	
	if(!firstTime){
		if (generateTrigger > 0){
			/*			   
			// Set inhibit before generating the trigger
			// wait and release
			// Test of inhibit feature for Monitor Detector, ak 16.7.07
			addr =  (21 << 24) | (0x1 << 18) | 0x0f13;
			[self write:addr value:0];
			
			usleep(100); // Inhibit for 100us ?!
			addr =  (21 << 24) | (0x1 << 18) | 0x0f14;
			[self write:addr value:0];
			*/			
			
			int i;
			unsigned long addr =  (21 << 24) | (0x1 << 18) | 0x0105; // Set pages free
			for (i=0;i<63;i++) [self write:addr value:i];
			
			addr =  (21 << 24) | (0x1 << 18) | 0x0f12; // Slt Generate Software Trigger
			[self write:addr value:0];
			
			generateTrigger = 0;
		}
		
		switch(daqRunMode){ //was fltMode  -tb- 2008-02-12
			case kKatrinFlt_DaqHitrate_Mode: // new -tb-
				[self takeDataHitrateMode: aDataPacket];
			break;
			case kKatrinFlt_DaqThresholdScan_Mode: // was kKatrinFlt_Measure_Mode -tb-
				[self takeDataMeasureMode: aDataPacket];
			break;
			
			case kKatrinFlt_DaqEnergy_Mode: // was kKatrinFlt_Run_Mode or kKatrinFlt_Debug_Mode
			case kKatrinFlt_DaqEnergyTrace_Mode:	
				[self takeDataRunOrDebugMode: aDataPacket]; 
			break;
			case kKatrinFlt_DaqHistogram_Mode:  //new mode 2008-02-26 -tb-
				[self takeDataHistogramMode: aDataPacket];
			break;
			case kKatrinFlt_DaqVeto_Mode:  //new mode 2008-02-26 -tb-
				[self takeDataVetoMode: aDataPacket];
			break;
		}
	}
	else {
	
		firstTime = NO;
		
		// Read first second counter
		// The first hitrate will be taken from the first completely measured interval
		lastSec = [self readTime] + 1;  

		
		// Start dead time counting	
		unsigned long addr =  (21 << 24) | (0x1 << 18) | 0x0f11; // ResetDeadTimeCounters
		[self write:addr value:0];			
		
		// Release inhibit when DAq has started!
		addr =  (21 << 24) | (0x1 << 18) | 0x0f14; // SwRelInhibit
		[self write:addr value:0];
	}
	
	NS_HANDLER
	
        //TODO: CRASH: in case of exceptions and in trace mode we should stop he run (?) -tb- 2008-02-27
		NSLogError(@"",@"Katrin FLT Card Error",[NSString stringWithFormat:@"Card%d",[self stationNumber]],@"Data Readout",nil);
		[self incExceptionCount];
		[localException raise];
		
	NS_ENDHANDLER
}

- (void) takeDataRunOrDebugMode:(ORDataPacket*) aDataPacket
{
	nLoops++;
	
	unsigned long statusWord = [fireWireCard read:statusAddress];		//is there any data?
	
	// Determine the pages to be read
	// The eventlop (this class) stores the next page to be read in the
	// variable nextEventPage. The page number actually written is read from 
	// the status register.
	// ak 15.6.07
	int page0 = nextEventPage; // Next page to be read
	int page1 = (statusWord >> 11) & 0x1ff;	// Get write page pointer

	if(usingPBusSimulation){
		// In simulation mode generate a trigger from time to time...
		// ak 11.7.07
		page1 = nextEventPage;
		usleep(1);
		
		// Generate event every 2 sec
	    unsigned long sec = [self readTime];
	    if (sec > lastSec + 1) {
   		    lastSec = sec; // Store the  actual second counter		
			page1 = (nextEventPage + 1) % 512;
			//NSLog(@"Pages: %d %d (last %d, loops %d)\n", page0, page1, nextEventPage, nLoops);
			usleep(100); 
		}
	}    
	
	// Read the the trigger data of all events in one block. 
	// The energy value have to be read one by one. 
	// (Denis was not able to store all the data in the same place)
	// ak, 20.7.07
	unsigned long dataBuffer[2048];
	unsigned long *data;
	
	int nPages = (512 + page1 - page0) %512;			
	
	// Read the event data for a complete block of events
	if (nPages > 0){
		// Calculate the mean buffer hardware buffer load
		nBuffer = 0.95 * nBuffer + 0.05 * ((512+page1-page0)%512);
		
		// Don't wrap around the end of the buffer
		if (page1 < page0) {
			page1 = 0; 
			nPages = (512 + page1 - page0) %512; // Recalculate
		}	
		
		unsigned long pageAddress = triggerMemAddress + (page0<<2);				
		data = dataBuffer;
		[fireWireCard read:pageAddress data:data size:nPages*4*sizeof(long)];
	
	
	    // Determine the readout address for all ADC traces
		// The first trigger stops the recording of the ADC traces
		// 		
		// Calculate start bin
		// Note: The Flt uses a fixed post trigger time of 512 bin
		//       This time is different from the central nextpage delay used by the Slt
		//       ak, 29.2.08
		int firstEventSubSec = data[1];
		int startBin = firstEventSubSec - (512 + (readoutPages-1) * 1024);
		if(startBin < 0){
			startBin = 0x10000 + startBin;
		}
		
		
		if(checkWaveFormEnabled){
		  if (nPages > 1) 
		    NSLog(@"nEvents=%8d (%12d,%8d) nPages=%3d\n", nEvents+1, data[2], data[1], nPages);
		}
		
        int nPagesHandled = 0; 
		while(page0 != page1){
			katrinDebugDataStruct theDebugEvent;
			
			nEvents++;
			
			// Move the pointer to the next page	
			page0 = (page0 + 1) % 512;	// Go to the next page 
			nPages = (512 + page1 - page0) %512;				
			nextEventPage = page0; // Store the page pointer for the next readout call
			
			//read the event from the trigger memory and format into an event structure
			unsigned long channelMap = (data[0] >> 10)  & 0x3fffff;
			katrinEventDataStruct theEvent;
			theEvent.channelMap = channelMap;
			int eventId = data[0] & 0x3ff;
			theEvent.eventID	= (nPages << 16) | eventId;
			theEvent.subSec     = data[1];
			theEvent.sec        = data[2];
			
			// Go to the next data block
			data = data + 4;
			
			// Check for missing events
			// ak 19.7.07
			if (lastEventId < 8888) {
				int diffId = (1024 + eventId - lastEventId) % 1024; 
				if (diffId > 1){
					nMissingEvents = nMissingEvents + diffId;
					
					if (!overflowDetected){
						//NSLogError(@"",@"Katrin FLT Card Error",[NSString stringWithFormat:@"Card%d",[self stationNumber]],@"OverFlow",nil);
						//NSLog(@"Event %d  -  EventId check failed: %d - %d = %d\n", nEvents, eventId, lastEventId, diffId);
						//NSLog(@"Ev %6d ,page %4d / %4d, EventId %4d - %4d = %4d | err %6d\n", 
						//      nEvents, actualPage, page1-actualPage, lastEventId, eventId, diffId, nMissingEvents);
					}  
				}
			}  
			lastEventId = eventId;
			
			// Check for buffer overflow
			// 
			unsigned long bufState =  (statusWord >> kKatrinFlt_Cntrl_BufState_Shift) & 0x3;
			//NSLog(@"Buffer state :  %x\n", bufState);
			if(bufState == 0x3) overflowDetected = true;
						
			if(usingPBusSimulation){	
				// Test: Read a few channel?!		
				channelMap = 0x25;
				theEvent.eventID = nextEventPage; // increment the event id (only run mode)
			}		
			
			if(channelMap){
				int aChan;
				long readAddress = 0; 
				for(aChan=0;aChan<kNumFLTChannels;aChan++){
					if( (1L<<aChan) & channelMap){
						
						theEvent.channelMap =  (aChan << 24) | channelMap;
						
						locationWord &= 0xffff0000;
						locationWord |= (aChan&0xff)<<8; // New: There is a place for the channel in the header?!
						
						if(fltRunMode == kKatrinFlt_Run_Mode){
							readAddress = memoryAddress | (aChan << kKatrinFlt_ChannelAddress) | (theEvent.subSec & 0xffff);
							//the event energy address is computed from the subSec part of the trigger data
						} 
						else if (fltRunMode == kKatrinFlt_Debug_Mode){		
							// Read the energy from TriggerEnergy register
							readAddress = statusAddress | (kFLTTriggerEnergyCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress);
						}							
						
						// Extra information for debug mode
						// Reset / restart time stamp
						if(fltRunMode == kKatrinFlt_Debug_Mode){
							// Read the reset time
							if (useResetTimestamp){
								unsigned long addr = statusAddress | (kFLTTimeCounterCode << kKatrinFlt_AddressSpace) | 1;
								resetSec    = [fireWireCard read:addr ];
								addr = addr + 1;
								resetSubSec = [fireWireCard read:addr ];
								
								theDebugEvent.resetSec  = resetSec;
								theDebugEvent.resetSubSec = resetSubSec;
								
								// Check if the data is continuous
								// Recording time
								// t_ev - t_reset > readoutPages * 1024 * 100ns										
								long recTime = (theEvent.sec - theDebugEvent.resetSec) * 10000000 +
									(theEvent.subSec - theDebugEvent.resetSubSec);		// 100ns bins
								if (recTime < 1024 * 	readoutPages) {
									//NSLog(@"Event %d: The reording time is short than readout windows\n", nEvents);
									//NSLog(@"Recording time %d x 100ns <  %d x 100us\n", recTime, readoutPages);
								}		
								
								//NSLog(@"Reset (addr = %08x): %d, %d\n", addr, resetSec, resetSubSec);
							}
						}				
						
						// In debug and run mode the basic event information is transmitted 
						// to the data handler
						// ak 15.6.07							
						// The hardware returns the product of energy and filter length
						// The energy values are shifted to remove the effect of the filter length
						// ak 24.9.07	
#ifdef USE_ENERGYSHIFT											
						theEvent.energy	= ([fireWireCard read:readAddress] & 0xffff) << energyShift[aChan];
#else						
						theEvent.energy	= ([fireWireCard read:readAddress] & 0xffff);
#endif
						
						if((fltRunMode == kKatrinFlt_Run_Mode)){
							unsigned long totalLength = 2 + (sizeof(katrinEventDataStruct)/sizeof(long));
							NSMutableData* theEnergyData = [NSMutableData dataWithCapacity:totalLength*sizeof(long)];
							unsigned long header = dataId | totalLength;	//total event size + the two ORCA header words (in longs!).
							
							[theEnergyData appendBytes:&header length:4];							//ORCA header word
							[theEnergyData appendBytes:&locationWord length:4];						//which crate, which card info
							[theEnergyData appendBytes:&theEvent length:sizeof(katrinEventDataStruct)];
							[aDataPacket addData:theEnergyData];									//ship the energy record
						}
						
						// Readout of ADC-Traces available only in debug-mode
						// ak, 15.6.07												
						else if(fltRunMode == kKatrinFlt_Debug_Mode){
							
							unsigned long totalLength = (2 + (sizeof(katrinEventDataStruct)/sizeof(long)) 
														 + (sizeof(katrinDebugDataStruct)/sizeof(long))
														 + readoutPages*512);	// longs
							NSMutableData* theWaveFormData = [NSMutableData dataWithCapacity:totalLength*sizeof(long)];
							unsigned long header = waveFormId | totalLength;
							
							[theWaveFormData appendBytes:&header length:4];				           //ORCA header word
							[theWaveFormData appendBytes:&locationWord length:4];		           //which crate, which card info
							[theWaveFormData appendBytes:&theEvent length:sizeof(katrinEventDataStruct)];
							[theWaveFormData appendBytes:&theDebugEvent length:sizeof(katrinDebugDataStruct)];									
							
														
							// Use block read mode.
							// With every 32bit (long word) two 12bit ADC values are transmitted
							// ak 19.6.07
							[theWaveFormData setLength:totalLength*sizeof(long)]; //we're going to dump directly into the NSData object so
																				  //we have to set the total size first. (Note: different than 'Capacity')
							int j;
							unsigned long addr =  (startBin & 0xffff);
							short* waveFormPtr = ((short*)[theWaveFormData bytes]) + (4*sizeof(short))
								+ (sizeof(katrinEventDataStruct)/sizeof(short))
								+ (sizeof(katrinDebugDataStruct)/sizeof(short)); //point to start of waveform
								
							unsigned long *lPtr = (unsigned long *) waveFormPtr;
 							for (j=0;j<readoutPages;j++){
								
								readAddress =  memoryAddress | (aChan << kKatrinFlt_ChannelAddress) | addr;
								[fireWireCard read:readAddress data:lPtr size:512*sizeof(long)];														
								
								addr = (addr + 1024) % 0x10000;
								lPtr = lPtr + 512;
							}
							
							if(usingPBusSimulation){
								// Add trigger for simulation mode								  
								waveFormPtr[(readoutPages-1)*1024+510] = waveFormPtr[(readoutPages-1)*1024+510] | 0x8000;
							}   
							
							if(checkWaveFormEnabled){
								[self checkWaveform:waveFormPtr];
							}
														
							// Check if the data is completely in the buffer
							// In case of a second strobe the recording is not continuos at the 
							// end of the buffer.
							// TODO: Implement a more intelligent readout for traces in the beginning of the second, ak 29.2.08
							if (theEvent.subSec > 1024 * readoutPages){
								[aDataPacket addData:theWaveFormData]; //ship the waveform
							} 
							else {
								nSkippedEvents++;
								nEvents--;
							}
							
						}
						
					} // end of channel readout
				} // end of loop over all channel
				
			}
		
		    nPagesHandled +=1;
		} // end of while	
		
		// Reset after readout req. to start data aquisition in debug mode again	
		// ak, 15.6.07			
		// If the recording is stopped there can be even more than one event be 
		// available - all channels can trigger synchronously!
		// Give reset only if all events have be processed
		// ak, 21.9.07		
		if(fltRunMode ==  kKatrinFlt_Debug_Mode){
			[self restartRun];	//reset the trigger
		}				
		
		
	} // end of if pages available
}

/*!Read the  data and add it to the Orca data stream (i.e. to aDataPacket) in binary format.
   \param aDataPacket is passed from Orca data taking main loop.
   
   The kind and size of the added data packet is encoded in the first 4 bytes (the header).
   The data IDs (e.g. hitRateId, waveFormId, ...) are assigned in: - (void) setDataIds:(id)assigner
*/  //-tb- 2008-02-6
- (void) takeDataHitrateMode:(ORDataPacket*)aDataPacket;
{
    struct timeval t;
    struct timezone tz;
    unsigned long data;
	unsigned long hitrate[22];
    unsigned long threshold;

    threshold = 50;


	// Wait for the second strobe
	unsigned long sec = [self readTime];
	if (sec > lastSec) {
		lastSec = sec; // Store the  actual second counter
		
		// Found second counter
		//NSLog(@"Time %d\n", sec);
        
 		// Read thresholds
		int i;
		for (i=0;i<22;i++){
			if ((activeChMap >> i) & 0x1) {
				
				// Get the hitrate 
				data = ([fireWireCard read:([self slot] << 24) | (kFLTHitRateCode << kKatrinFlt_AddressSpace) | (i<<kKatrinFlt_ChannelAddress)]);					
				hitrate[i] = data & 0xffffff;					
				if (usingPBusSimulation){
			        hitrate[i] = 8256+i;					
				}   
				//NSLog(@"%2d: %04x, age=%d, len=%d\n", i, hitrate[i], (data >> 24) & 0xf, data >> 28);
       
     
 				// Save threshold and hitrate data

					// Save the data set
					// The saved thresholds are always in ascending order
					//  The intervals are not equally spaced but depend on the hitrate change
					// 
					katrinHitRateDataStruct theRates;
                    gettimeofday(&t,&tz);
					//theRates.sec = t.tv_sec;  
                    theRates.sec = sec;  
					theRates.hitrate = hitrate[i];	
                    if(hitrate[i]<=0) continue;
			
	    			NSLog(@"takeDataHitrateMode: ch/sec/h = rate%2d: %12d %04x\n", i, theRates.sec, theRates.hitrate);//TODO: remove it -tb-
                    		
					locationWord &= 0xffff0000;
					locationWord |= (i&0xff)<<8; // New: There is a place for the channel in the header?!
					
					unsigned long totalLength = 2 + (sizeof(katrinHitRateDataStruct)/sizeof(long));
					NSMutableData* thekatrinHitRateDataStruct = [NSMutableData dataWithCapacity:totalLength*sizeof(long)];
					unsigned long header = hitRateId | totalLength;	//total event size + the two ORCA header words (in longs!).
					
					[thekatrinHitRateDataStruct appendBytes:&header length:4];		//ORCA header word
					[thekatrinHitRateDataStruct appendBytes:&locationWord length:4];	//which crate, which card info
					[thekatrinHitRateDataStruct appendBytes:&theRates length:sizeof(katrinHitRateDataStruct)];
					
					[aDataPacket addData:thekatrinHitRateDataStruct];	//ship the hitrate record
                    
            }
        }
    }
		


}


- (void) takeDataMeasureMode:(ORDataPacket*)aDataPacket //TODO: rename it - maybe takeDataThresholdScanMode -tb-
{
	// Implementation of measure/histogram mode
	// Sweep through the threshold values and record the trigger rates
	// 24.7.07 ak
	
	unsigned long hitrate[22];
	bool saveData;
	
	// Wait for the second strobe
	unsigned long sec = [self readTime];
	if (sec > lastSec) {
		lastSec = sec; // Store the  actual second counter
		
		// Found second counter
		NSLog(@"Time %d\n", sec);
		
		// Read thresholds
		int i;
		for (i=0;i<22;i++){
			if ((activeChMap >> i) & 0x1) {
				saveData = true; 
				
				// Get the hitrate 
				hitrate[i] = ([fireWireCard read:([self slot] << 24) | (kFLTHitRateCode << kKatrinFlt_AddressSpace) | (i<<kKatrinFlt_ChannelAddress)] & 0xffffff);					
				if (usingPBusSimulation){
					if (actualThreshold[i] < 3920)		hitrate[i] = 8256;					
					else if (actualThreshold[i] > 3975)	hitrate[i] = 0;					
					else								hitrate[i] = 8256 - 8256 * (actualThreshold[i]-3920) / 55;
				}   
				NSLog(@"%2d: %04d, %04d -> %04x\n", i, actualThreshold[i], stepThreshold[i], hitrate[i]);
				
				// Start from the actual rate and increase by one?!
				// Find the maximum rate
				if (maxHitrate[i] == 0){
					maxHitrate[i] = hitrate[i];
					lastHitrate[i] = hitrate[i];
				}
				
				// Detect changes
				int diffHitrate = lastHitrate[i] - hitrate[i];	 	
				if (diffHitrate < 5)	nNoChanges[i] += 1;
				else					nNoChanges[i] = 0;
				
				// Automatically reduce the step size if a hitrate change is
				// detected
				if (stepThreshold[i] > 2){ 
					
					// Decrease step size, if necessary
					if (diffHitrate > 5){
						actualThreshold[i] = actualThreshold[i] - stepThreshold[i];	// Go back to the last threshold
						stepThreshold[i] = stepThreshold[i] / 10;					// Change go with the smaller  
						saveData = false;											// Do not send the data
					}
				}  
				
				// Increase step size if the frequency does not change
				if ((nNoChanges[i] > 5) && (hitrate[i] > 0)){	
					// Increase the step size									   
					if (stepThreshold[i] < 2000){
						stepThreshold[i] = stepThreshold[i] * 10;					// Change go with the smaller 
					}	  
					
				}
				
				// Reached the end of the frequency plot
				if ((nNoChanges[i] > 5) && (hitrate[i] == 0)){										   
					// Start again
					actualThreshold[i] = savedThreshold[i]-2000; // will be incremented at the end of the loop
					stepThreshold[i] = 2000;
					maxHitrate[i] = 0;
					
					// Stop, remove the flag from the channel mask
					//activeChMap = activeChMap ^ (0x1 << i);
					
					// Don't save this sample
					saveData = false;					   
				}

				// Save threshold and hitrate data
				if (saveData) {

					// Save the data set
					// The saved thresholds are always in ascending order
					//  The intervals are not equally spaced but depend on the hitrate change
					// 
					// TODO:
					// The energy and the thresholds does not fit perfectly?!
					// Find out the relation between threshold and energy
					//
					katrinThresholdScanDataStruct theRates;
					theRates.channelMap = (i << 24) | activeChMap;
					theRates.threshold = actualThreshold[i];  // << 1;  Adjust to energy scale ??
					theRates.hitrate = hitrate[i];			
					
					locationWord &= 0xffff0000;
					locationWord |= (i&0xff)<<8; // New: There is a place for the channel in the header?!
					
					unsigned long totalLength = 2 + (sizeof(katrinThresholdScanDataStruct)/sizeof(long));
					NSMutableData* thekatrinThresholdScanDataStruct = [NSMutableData dataWithCapacity:totalLength*sizeof(long)];
					unsigned long header = thresholdScanId | totalLength;	//total event size + the two ORCA header words (in longs!).
					
					[thekatrinThresholdScanDataStruct appendBytes:&header length:4];		//ORCA header word
					[thekatrinThresholdScanDataStruct appendBytes:&locationWord length:4];	//which crate, which card info
					[thekatrinThresholdScanDataStruct appendBytes:&theRates length:sizeof(katrinThresholdScanDataStruct)];
					
					[aDataPacket addData:thekatrinThresholdScanDataStruct];	//ship the hitrate record
					
					
					// Only store the hitrate, if the sample was used!
					lastHitrate[i] = hitrate[i];  
					lastThreshold[i] = actualThreshold[i];					    
				}
				
				// Go the the next threshold
				actualThreshold[i] += stepThreshold[i];
				
				[self writeThreshold:i value:actualThreshold[i]];   // Hw
				[self setThreshold:i withValue:actualThreshold[i]]; // GUI
				
				// TODO: Wait for more than one second
				lastSec = sec + 1; // Wait for one second
			}		  
		}
		//since notifications are delivered to the thread they are posted in, we'll pass this one back to the main thread.
		[self performSelectorOnMainThread:@selector(postHitRateChange) withObject:nil waitUntilDone:NO];
	}
}

/** @todo FPGA-Bug
  * In histogram mode: if TRun is set to a non zero value the run stops after that time (as it is supposed to do)
  * but the firstBin, lastBin and histogram data are reset to zero immediatly.
  * (This bug report is in ORKatrinFLTModel.m  -tb- 2008-02-29 )
  */ //-tb- 2008-02-29


/*!Read the FLT hardware histogram data and add it to the Orca data stream (i.e. to aDataPacket) in binary format.
   \param aDataPacket is passed from Orca data taking main loop.
   
   The kind and size of the added data packet is encoded in the first 4 bytes (the header).
   The data IDs (e.g. hitRateId, waveFormId, ...) are assigned in: - (void) setDataIds:(id)assigner
*/  //-tb- 2008-02-26
- (void) takeDataHistogramMode:(ORDataPacket*)aDataPacket;
{



//TODO: under construction -tb-
//TODO: under construction -tb-
#if 0    
    struct timeval t;
    struct timezone tz;
    unsigned long data;
	unsigned long hitrate[22];
    unsigned long threshold;

    threshold = 50;
#endif

	// Wait for the second strobe
	unsigned long sec = [self readTime];   //QUESTION is this the crate time? format? yes; full seconds -tb- 2008-02-26
	if ( (((sec+1) - lastSec)%4) == 0 ) {
NSLog(@"This is   takeDataHistogramMode heartbeat: %i\n",sec);
		lastSec = sec; // Store the  actual second counter
		
		// Found second counter
		//NSLog(@"Time %d\n", sec);
        
        
        #if 0
 		// 
		int i;
		for (i=0;i<22;i++){
			if ((activeChMap >> i) & 0x1) {
				
				// Get the hitrate 
				data = ([fireWireCard read:([self slot] << 24) | (kFLTHitRateCode << kKatrinFlt_AddressSpace) | (i<<kKatrinFlt_ChannelAddress)]);					
				hitrate[i] = data & 0xffffff;					
				if (usingPBusSimulation){
			        hitrate[i] = 8256+i;					
				}   
				//NSLog(@"%2d: %04x, age=%d, len=%d\n", i, hitrate[i], (data >> 24) & 0xf, data >> 28);
       
     
 				// Save threshold and hitrate data

					// Save the data set
					// The saved thresholds are always in ascending order
					//  The intervals are not equally spaced but depend on the hitrate change
					// 
					katrinHitRateDataStruct theRates;
                    gettimeofday(&t,&tz);
					//theRates.sec = t.tv_sec;  
                    theRates.sec = sec;  
					theRates.hitrate = hitrate[i];	
                    if(hitrate[i]<=0) continue;
			
	    			NSLog(@"takeDataHitrateMode: ch/sec/h = rate%2d: %12d %04x\n", i, theRates.sec, theRates.hitrate);//TODO: remove it -tb-
                    		
					locationWord &= 0xffff0000;
					locationWord |= (i&0xff)<<8; // New: There is a place for the channel in the header?!
					
					unsigned long totalLength = 2 + (sizeof(katrinHitRateDataStruct)/sizeof(long));
					NSMutableData* thekatrinHitRateDataStruct = [NSMutableData dataWithCapacity:totalLength*sizeof(long)];
					unsigned long header = hitRateId | totalLength;	//total event size + the two ORCA header words (in longs!).
					
					[thekatrinHitRateDataStruct appendBytes:&header length:4];		//ORCA header word
					[thekatrinHitRateDataStruct appendBytes:&locationWord length:4];	//which crate, which card info
					[thekatrinHitRateDataStruct appendBytes:&theRates length:sizeof(katrinHitRateDataStruct)];
					
					[aDataPacket addData:thekatrinHitRateDataStruct];	//ship the hitrate record
                    
            }
        }
        #endif
    }
		


}


/** Stop histogramming, read histogram from hardware and write it into Orca data stream.
  *
  *
  */ //-tb- 2008-03-05
- (void) pauseHistogrammingAndReadOutData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    NSLog(@"pauseHistogrammingAndReadOutData\n");
    katrinHistogramDataStruct theEventData;
	unsigned long stopsec = [self readTime];
	unsigned long sec ;
    // stop histogramming
    [self writeStopHistogram];
    //after stopping we have to wait for the second strobe ...
    sec = [self readTime];
    while(stopsec == sec){
        usleep(100);
        sec = [self readTime];
        //NSLog(@"pauseHistogrammingAndReadOutData usleep 100   stopsec %i sec %i\n",stopsec,sec);
    }
       //usleep(1000001);

    // now read out the histogram and write it to the Orca data stream
    theEventData.readoutSec = stopsec;
    theEventData.recordingTimeSec = [self readTRec];
    theEventData.firstBin  = [self readFirstBinOfPixel: 0];
    theEventData.lastBin   = [self readLastBinOfPixel:  0];
    theEventData.histogramLength = theEventData.lastBin - theEventData.firstBin +1;
    if(theEventData.histogramLength < 0){// we had no counts ...
        theEventData.histogramLength = 0;
    }
    //theEventData.binWidth  = histoBinWidth; // needed here? is already in the header!


    // the standard header
    int aPixel =0;
	locationWord &= 0xffff0000;
	locationWord |= (aPixel & 0xff)<<8; // New: There is a place for the channel in the header?!

    unsigned long totalLength = 2 + (sizeof(katrinHistogramDataStruct)/sizeof(long)) + theEventData.histogramLength;// 2 = header + locationWord
	NSMutableData* theData = [NSMutableData dataWithCapacity:totalLength*sizeof(long)];
	unsigned long header = histogramId | totalLength;	//total event size + the two ORCA header words (in longs!).

	[theData appendBytes:&header length:4];		//ORCA header word
	[theData appendBytes:&locationWord length:4];	//which crate, which card info
	[theData appendBytes:&theEventData length:sizeof(katrinHistogramDataStruct)];


    //this is mainly  from readHistogramDataOfPixel
    //unsigned int i,firstBin, lastBin, currVal, sum;
    if(theEventData.histogramLength>0){
        int sum=0;
        unsigned int func  = 0x6; // = b110
        unsigned int LAddr12 = 0xC; //0xC is Histogrm:HDATA
        unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
        if(aPixel == 0) Pixel=0;
        if(aPixel == 1) Pixel=1;
        if(aPixel == 12) Pixel=2;
        if(aPixel == 13) Pixel=3;
        unsigned int adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12);
        int i,currVal;
        for(i=theEventData.firstBin; i<=theEventData.lastBin; i++){
            currVal =  [self read: adress | i];
            sum += currVal;
            NSLog(@"    bin %4u: %4u \n",i , currVal); 	
            //[[histogramData objectAtIndex:i] setIntValue:currVal];
            //histogramDataUI[i]= currVal;
            [theData appendBytes:&currVal length:4];		//ORCA header word

        }
        NSLog(@"sum: %4u \n",sum); 	
    }
    //readHistogramDataOfPixel
    
    //if (usingPBusSimulation){
	//	 do something;				  //TODO: usingPBusSimulation for histogramming -tb-	
	//}  
    
      
	[aDataPacket addData:theData];	//ship the histogram record

}


/*!Read the data when in FLT veto mode and add it to the Orca data stream (i.e. to aDataPacket) in binary format.
   \param aDataPacket is passed from Orca data taking main loop.
   
   The kind and size of the added data packet is encoded in the first 4 bytes (the header).
   The data IDs (e.g. hitRateId, waveFormId, ...) are assigned in: - (void) setDataIds:(id)assigner
*/  //-tb- 2008-02-26
- (void) takeDataVetoMode:(ORDataPacket*)aDataPacket;
{
NSLog(@"This is   takeDataVetoMode\n");
#if 0
    struct timeval t;
    struct timezone tz;
    unsigned long data;
	unsigned long hitrate[22];
    unsigned long threshold;

    threshold = 50;


	// Wait for the second strobe
	unsigned long sec = [self readTime];   //TODO: QUESTION is this the crate time? format? -tb- 2008-02-26
	if (sec > lastSec) {
		lastSec = sec; // Store the  actual second counter
		
		// Found second counter
		//NSLog(@"Time %d\n", sec);
        
 		// Read thresholds
		int i;
		for (i=0;i<22;i++){
			if ((activeChMap >> i) & 0x1) {
				
				// Get the hitrate 
				data = ([fireWireCard read:([self slot] << 24) | (kFLTHitRateCode << kKatrinFlt_AddressSpace) | (i<<kKatrinFlt_ChannelAddress)]);					
				hitrate[i] = data & 0xffffff;					
				if (usingPBusSimulation){
			        hitrate[i] = 8256+i;					
				}   
				//NSLog(@"%2d: %04x, age=%d, len=%d\n", i, hitrate[i], (data >> 24) & 0xf, data >> 28);
       
     
 				// Save threshold and hitrate data

					// Save the data set
					// The saved thresholds are always in ascending order
					//  The intervals are not equally spaced but depend on the hitrate change
					// 
					katrinHitRateDataStruct theRates;
                    gettimeofday(&t,&tz);
					//theRates.sec = t.tv_sec;  
                    theRates.sec = sec;  
					theRates.hitrate = hitrate[i];	
                    if(hitrate[i]<=0) continue;
			
	    			NSLog(@"takeDataHitrateMode: ch/sec/h = rate%2d: %12d %04x\n", i, theRates.sec, theRates.hitrate);//TODO: remove it -tb-
                    		
					locationWord &= 0xffff0000;
					locationWord |= (i&0xff)<<8; // New: There is a place for the channel in the header?!
					
					unsigned long totalLength = 2 + (sizeof(katrinHitRateDataStruct)/sizeof(long));
					NSMutableData* thekatrinHitRateDataStruct = [NSMutableData dataWithCapacity:totalLength*sizeof(long)];
					unsigned long header = hitRateId | totalLength;	//total event size + the two ORCA header words (in longs!).
					
					[thekatrinHitRateDataStruct appendBytes:&header length:4];		//ORCA header word
					[thekatrinHitRateDataStruct appendBytes:&locationWord length:4];	//which crate, which card info
					[thekatrinHitRateDataStruct appendBytes:&theRates length:sizeof(katrinHitRateDataStruct)];
					
					[aDataPacket addData:thekatrinHitRateDataStruct];	//ship the hitrate record
                    
            }
        }
    }
		

#endif
}





- (void) postHitRateChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHitRateChanged object:self];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    // read the hardware histogram -tb- 2008-03-05
    if(daqRunMode == kKatrinFlt_DaqHistogram_Mode){	
        [self pauseHistogrammingAndReadOutData:aDataPacket userInfo:userInfo];
    }

    // Restore the saved threshold
	int i;
	
	if(fltRunMode == kKatrinFlt_Measure_Mode){	//TODO: better check for daqRunMode in thresholdScanMode -tb-
	  for (i=0;i<22;i++){
		[self setThreshold:i withValue:savedThreshold[i]];
      }
    }

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
	int chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		hitRate[chan] = 0;
	}
	[self setHitRateTotal:0];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHitRateChanged object:self];
	
	NSLog(@"----------------------------------------\n");
	NSLog(@"Katrin Crate:%d Card:%d\n",[self crateNumber], [self stationNumber]);
	NSLog(@"Record time    : %d\n", 0);
	NSLog(@"Events         : %d (readout loops %d)\n", nEvents, nLoops);
	NSLog(@"Trigger rate   : %d\n", 0);
	NSLog(@"Hw-Buffer      : %f\n", nBuffer);
    NSLog(@"Buffer overflow: %d\n", overflowDetected);
	NSLog(@"Missing events : %d\n", nMissingEvents);
	NSLog(@"Skipped events : %d\n", nSkippedEvents);
    NSLog(@"Maximal rate   : %d\n", 0);
}

#pragma mark ¥¥¥HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}

- (int) numberOfChannels
{
    return kNumFLTChannels;
}

/** Here all attributes are defined which are accessible via the hardware wizard.
  */ //-tb-
- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:1200 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gain"];
    [p setFormat:@"##0" upperLimit:255 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setGain:withValue:) getMethod:@selector(gain:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];  //TODO: needs to be tested -tb- 2008-02-26
    [p setName:@"Shaping Time"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setShapingTime:withValue:) getMethod:@selector(shapingTime:)];
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
    [p setName:@"Check Waveform"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setCheckWaveFormEnabled:) getMethod:@selector(checkWaveFormEnabled)];
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
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORKatrinCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"ORKatrinFLTModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORKatrinFLTModel"]];
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
    else if([param isEqualToString:@"ShapingTime"]){
		return [[cardDictionary objectForKey:@"shapingTimes"] objectAtIndex:aChannel];
	}
    else return nil;
}

- (BOOL) partOfEvent:(unsigned short)aChannel
{
	//included to satisfy the protocal... change if needed
	return NO;
}
@end

@implementation ORKatrinFLTModel (tests)
#pragma mark ¥¥¥Accessors
- (BOOL) testsRunning
{
    return testsRunning;
}

- (void) setTestsRunning:(BOOL)aTestsRunning
{
    testsRunning = aTestsRunning;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestsRunningChanged object:self];
}

- (NSMutableArray*) testEnabledArray
{
    return testEnabledArray;
}

- (void) setTestEnabledArray:(NSMutableArray*)aTestEnabledArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestEnabledArray:testEnabledArray];
    
    [aTestEnabledArray retain];
    [testEnabledArray release];
    testEnabledArray = aTestEnabledArray;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestEnabledArrayChanged object:self];
}

- (NSMutableArray*) testStatusArray
{
    return testStatusArray;
}

- (void) setTestStatusArray:(NSMutableArray*)aTestStatusArray
{
    [aTestStatusArray retain];
    [testStatusArray release];
    testStatusArray = aTestStatusArray;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestStatusArrayChanged object:self];
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
		NS_DURING
			[self setTestsRunning:YES];
			NSLog(@"Starting tests for FLT station %d\n",[self stationNumber]);

			//clear the status text array
			int i;
			for(i=0;i<kNumKatrinFLTTests;i++){
				[testStatusArray replaceObjectAtIndex:i withObject:@"--"];
			}
			
			//create the test suit
			if(testSuit)[testSuit release];
			testSuit = [[ORTestSuit alloc] init];
			if([self testEnabled:0]) [testSuit addTest:[ORTest testSelector:@selector(modeTest) tag:0]];
			if([self testEnabled:1]) [testSuit addTest:[ORTest testSelector:@selector(ramTest) tag:1]];
			if([self testEnabled:2]) [testSuit addTest:[ORTest testSelector:@selector(patternWriteTest) tag:2]];
			if([self testEnabled:3]) [testSuit addTest:[ORTest testSelector:@selector(broadcastTest) tag:3]];
			if([self testEnabled:4]) [testSuit addTest:[ORTest testSelector:@selector(thresholdGainTest) tag:4]];
			if([self testEnabled:5]) [testSuit addTest:[ORTest testSelector:@selector(speedTest) tag:5]];
			if([self testEnabled:6]) [testSuit addTest:[ORTest testSelector:@selector(eventTest) tag:6]];

			[testSuit runForObject:self];
		NS_HANDLER
		NS_ENDHANDLER
	}
	else {
		NSLog(@"Tests for FLT (station: %d) stopped manually\n",[self stationNumber]);
		[testSuit stopForObject:self];
	}
}

- (void) runningTest:(int)aTag status:(NSString*)theStatus
{
	[testStatusArray replaceObjectAtIndex:aTag withObject:theStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestStatusArrayChanged object:self];
}


#pragma mark ¥¥¥Tests
- (void) modeTest
{
	int testNumber = 0;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}

	savedMode = fltRunMode;
	NS_DURING
		BOOL passed = YES;
		int i;
		for(i=0;i<4;i++){
			[self writeMode:i];
			if([self readMode] != i){
				[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
				passed = NO;
				break;
			}
			if(passed){
				[self writeMode:savedMode];
				if([self readMode] != savedMode){
					[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
					passed = NO;
				}
			}
		}
		if(passed){
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
	NS_HANDLER
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	NS_ENDHANDLER
	
	[testSuit runForObject:self]; //do next test
}


- (void) ramTest
{
	int testNumber = 1;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}

	unsigned short pat1[kKatrinFlt_Page_Size],buf[kKatrinFlt_Page_Size];
	int i,chan;
	for(i=0;i<kKatrinFlt_Page_Size;i++)pat1[i]=i;

	NS_DURING
		[self enterTestMode];
		int aPage;
		// broadcast the test pattern to all channels + pages
		for(aPage=0;aPage<32;aPage++){
			[self broadcast:aPage dataBuffer:pat1];
		}
		
		int n_error = 0;
		for (chan=startChan;chan<=endChan;chan++) {
			for(aPage=0;aPage<32;aPage++) {
				[self readMemoryChan:chan page:aPage pageBuffer:buf];
								
				if ([self compareData:buf pattern:pat1 shift:0 n:kKatrinFlt_Page_Size] != kKatrinFlt_Page_Size) n_error++;
			}
		}
		if(n_error != 0){
			[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
			NSLog(@"Errors in %d pages found\n",n_error);
		}
		else {
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
		
		[self leaveTestMode];

	
	NS_HANDLER
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	NS_ENDHANDLER		

	[testSuit runForObject:self]; //do next test
		
}

- (void) patternWriteTest
{
	int testNumber = 2;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}

	unsigned short pat1[kKatrinFlt_Page_Size],buf[kKatrinFlt_Page_Size];

	NS_DURING
		[self enterTestMode];
		BOOL passed = YES;
		unsigned long patterns[4] = {0x1010,0x0101,0x1111,0x0000};
		int i,patternIndex;
		for(patternIndex=0;patternIndex<4;patternIndex++){
			for(i=0;i<kKatrinFlt_Page_Size;i++)pat1[i] = patterns[patternIndex];
			[self clear:startChan page:page value:patterns[patternIndex]];
			[self readMemoryChan:startChan page:page pageBuffer:buf];
			if ([self compareData:buf pattern:pat1 shift:0 n:kKatrinFlt_Page_Size] != kKatrinFlt_Page_Size){
				[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
				NSLog(@"Error: pattern set (0x%0x) for FLT %d chan %d, page %d does not work\n", patterns[i],[self stationNumber],startChan, page);
				passed = NO;
				break;
			}
		}
		
		if(passed) {
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
		
		[self leaveTestMode];

	NS_HANDLER
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	NS_ENDHANDLER		

	[testSuit runForObject:self]; //do next test
		
}

- (void) broadcastTest
{
	int testNumber = 3;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}

	unsigned short pat1[kKatrinFlt_Page_Size],buf[kKatrinFlt_Page_Size];

	NS_DURING
		[self enterTestMode];
		unsigned long pattern = 0x1010;
		int i,chan;
		int thePage = 15; //test page
		BOOL passed = YES;
		for(i=0;i<kKatrinFlt_Page_Size;i++)pat1[i] = pattern;
		for(chan=startChan;chan<=endChan;chan++){
			[self broadcast:thePage dataBuffer:pat1];
			[self readMemoryChan:chan page:thePage pageBuffer:buf];
			if ([self compareData:buf pattern:pat1 shift:0 n:kKatrinFlt_Page_Size] != kKatrinFlt_Page_Size){
				[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
				NSLog(@"Error: broadcast (pattern: 0x%0x) FLT %d chan %d, page %d does not work\n",pattern,[self stationNumber],startChan, thePage);
				passed = NO;
			}
		}
		if(passed) {
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
		
		[self leaveTestMode];

	NS_HANDLER
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	NS_ENDHANDLER		

	[testSuit runForObject:self]; //do next test
		
}

- (void) thresholdGainTest
{
	int testNumber = 4;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}

	NS_DURING
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
			unsigned long gainPattern[4] = {0xff,0x0,0xaa,0x55};

			//now gains
			for(testIndex = 0;testIndex<4;testIndex++){
				unsigned short thePattern = gainPattern[testIndex];
				for(chan=0;chan<kNumFLTChannels;chan++){
					[self writeGain:chan value:thePattern];
				}
				
				for(chan=0;chan<kNumFLTChannels;chan++){
					if([self readGain:chan] != thePattern){
						[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
						NSLog(@"Error: Gain (pattern: 0x%0x) FLT %d chan %d does not work\n",thePattern,[self stationNumber],chan);
						passed = NO;
						break;
					}
				}
			}
		}
		if(passed) {
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
		
		[self loadThresholdsAndGains];
		
		[self leaveTestMode];

	NS_HANDLER
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	NS_ENDHANDLER		

	[testSuit runForObject:self]; //do next test
		
}


- (void) speedTest
{
	int testNumber = 5;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}

	unsigned short buf[kKatrinFlt_Page_Size];
	ORTimer* timer = [[ORTimer alloc] init];
	[timer reset];
	
	NS_DURING
		[self enterTestMode];		
		[timer start];
		[self readMemoryChan:startChan page:page pageBuffer:buf];
		[timer stop];
		NSLog(@"FLT %d page readout: %.2f sec\n",[self stationNumber],[timer seconds]);
		int i;
		[timer start];
		for(i=0;i<10000;i++){
			[self readMemoryChan:1 page:15];
		}
		[timer stop];
		NSLog(@"FLT %d single memory address readout: %.2f ms\n",[self stationNumber],[timer seconds]/10.);
		
		
		[self runningTest:testNumber status:@"See StatusLog"];

		[self leaveTestMode];
	NS_HANDLER
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];

	NS_ENDHANDLER		
	[timer release];
	
	[testSuit runForObject:self]; //do next test
		
}

- (void) eventTest
{
	int testNumber = 6;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	NS_DURING
		//cache some addresses.
		unsigned long theSlotPart = [self slot]<<24;
		statusAddress		= theSlotPart;
		triggerMemAddress	= theSlotPart | (kFLTTriggerDataCode << kKatrinFlt_AddressSpace); 
		memoryAddress		= theSlotPart | (kFLTAdcDataCode << kKatrinFlt_AddressSpace); 
		
		//clear the pointers, put in run mode
		unsigned long aValue = (fltRunMode<<20) | 0x1;
		[self writeControlStatus:aValue];
		[ORTimer delay:1];
		//put into test mode
		savedMode = fltRunMode;
		[self writeMode:kKatrinFlt_Test_Mode];
		if([self readMode] != kKatrinFlt_Test_Mode){
			NSLogColor([NSColor redColor],@"Could not put FLT %d into test mode\n",[self stationNumber]);
			[NSException raise:@"Ram Test Failed" format:@"Could not put FLT %d into test mode\n",[self stationNumber]];
		}
		
		//[[[self crate] adapter] hw_configure];		
		[[[self crate] adapter] hw_config];

		
		//[[[self crate] adapter] runIsAboutToStart:nil];
		
		
		NSLog(@"FLT %d\n",[self stationNumber]);
		unsigned long statusWord = [self readControlStatus];	
		//there is some data, so get the read and write pointers
		int page0 = statusWord & 0x1ff;	//read page
		page0 = (page0 + 1) % 512;				
		int page1 = (statusWord >> 11) & 0x1ff;	//write page
		
		if(page0 != page1){

			NSLog(@"---Event Data---\n");
		
			unsigned long pageAddress = triggerMemAddress + (page0<<2);	
					
			//read the event from the trigger memory and format into an event structure
			katrinEventDataStruct theEvent;
			unsigned long data	= [self read:pageAddress | 0x0];
			unsigned long channelMap = (data >> 10)  & 0x3fffff;
			theEvent.eventID	= data & 0x3fff;
			theEvent.subSec		= [self read:pageAddress | 0x1];
			theEvent.sec		= [self read:pageAddress | 0x2];

			//the event energy address is computed from the subSec part of the trigger data
			unsigned long energyAddress = memoryAddress | (theEvent.subSec % 65536);
			if (energyAddress % 2 == 0 ) {  // even address
				theEvent.energy	= [self read:energyAddress] & 0x7fff;			//15bits??
			}
			else {
				theEvent.energy	= ([self read:energyAddress-1]>>16) & 0x7fff;	//15bits??
			}			

			NSCalendarDate* theDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)theEvent.sec];

			NSLog(@"ChannelMap: 0x%0x\n",channelMap);
			NSLog(@"EventID   : 0x%0x\n",theEvent.eventID);
			NSLog(@"Time      : %@.%d\n",[theDate descriptionWithCalendarFormat:@"%m:%d:%y %H:%M:%S"],theEvent.subSec);
			NSLog(@"Energy    : %d\n",theEvent.energy);

		}
		else NSLog(@"No Data\n");
		
		//[[[self crate] adapter] runIsStopped:nil];
		
		
		[self runningTest:testNumber status:@"See StatusLog"];

		[self setFltRunMode:savedMode];
		[self writeMode:savedMode];
	NS_HANDLER
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];

	NS_ENDHANDLER		
	
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

@implementation ORKatrinFLTModel (private)

- (void) checkWaveform:(short*)waveFormPtr
{
	// Check the ADC traces
	// Is the trigger flag in the right place - there should be not more
	// than one trigger flag!
	// ak 24.7.07									
	int nTrigger = 0;
	int j;
	for (j=0;j<readoutPages*1024;j++){
		if (waveFormPtr[j] >> 15) nTrigger += 1;
	}
	if (nTrigger>1){
		NSLogError(@"",@"Katrin FLT Card Error",[NSString stringWithFormat:@"Card%d",[self stationNumber]],@"Too many triggers",nil);
		//NSLog(@"Event %d: Too many trigger flags in waveform (n=%d)\n", nEvents, nTrigger); // DEBUG: comment out -tb-
	}
	
	nTrigger = 0;
	for (j=(readoutPages-1)*1024+500;j<(readoutPages-1)*1024+550;j++){
		if (waveFormPtr[j] >> 15) nTrigger += 1;
	}
	if (nTrigger == 0){
		NSLogError(@"",@"Katrin FLT Card Error",[NSString stringWithFormat:@"Card%d",[self stationNumber]],@"Trigger flag in wrong place",nil);
		//NSLog(@"Event %d: Trigger flag not found in right place\n", nEvents, nTrigger);								
	}																
}

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
	[self writeMode:kKatrinFlt_Test_Mode];
	if([self readMode] != kKatrinFlt_Test_Mode){
		NSLogColor([NSColor redColor],@"Could not put FLT %d into test mode\n",[self stationNumber]);
		[NSException raise:@"Ram Test Failed" format:@"Could not put FLT %d into test mode\n",[self stationNumber]];
	}
}

- (void) leaveTestMode
{
		[self writeMode:savedMode];
}
@end


