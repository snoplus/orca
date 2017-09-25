//
//  ORKatrinV4FLTModel.m
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

#import "ORKatrinV4FLTModel.h"
#import "ORIpeV4SLTModel.h"
#import "ORKatrinV4SLTModel.h"
#import "ORIpeCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORDataTypeAssigner.h"
#import "ORTimeRate.h"
#import "ORTest.h"
#import "SBC_Config.h"
#import "ORCommandList.h"
#import "ORKatrinV4FLTRegisters.h"
#import "ORKatrinV4SLTRegisters.h"

NSString* ORKatrinV4FLTModelEnergyOffsetChanged             = @"ORKatrinV4FLTModelEnergyOffsetChanged";
NSString* ORKatrinV4FLTModelForceFLTReadoutChanged          = @"ORKatrinV4FLTModelForceFLTReadoutChanged";
NSString* ORKatrinV4FLTModelSkipFltEventReadoutChanged      = @"ORKatrinV4FLTModelSkipFltEventReadoutChanged";
NSString* ORKatrinV4FLTModelBipolarEnergyThreshTestChanged  = @"ORKatrinV4FLTModelBipolarEnergyThreshTestChanged";
NSString* ORKatrinV4FLTModelUseBipolarEnergyChanged         = @"ORKatrinV4FLTModelUseBipolarEnergyChanged";
NSString* ORKatrinV4FLTModelUseSLTtimeChanged               = @"ORKatrinV4FLTModelUseSLTtimeChanged";
NSString* ORKatrinV4FLTModelBoxcarLengthChanged             = @"ORKatrinV4FLTModelBoxcarLengthChanged";
NSString* ORKatrinV4FLTModelUseDmaBlockReadChanged          = @"ORKatrinV4FLTModelUseDmaBlockReadChanged";
NSString* ORKatrinV4FLTModelSyncWithRunControlChanged       = @"ORKatrinV4FLTModelSyncWithRunControlChanged";
NSString* ORKatrinV4FLTModelDecayTimeChanged                = @"ORKatrinV4FLTModelDecayTimeChanged";
NSString* ORKatrinV4FLTModelPoleZeroCorrectionChanged       = @"ORKatrinV4FLTModelPoleZeroCorrectionChanged";
NSString* ORKatrinV4FLTModelCustomVariableChanged           = @"ORKatrinV4FLTModelCustomVariableChanged";
NSString* ORKatrinV4FLTModelReceivedHistoCounterChanged     = @"ORKatrinV4FLTModelReceivedHistoCounterChanged";
NSString* ORKatrinV4FLTModelReceivedHistoChanMapChanged     = @"ORKatrinV4FLTModelReceivedHistoChanMapChanged";
NSString* ORKatrinV4FLTModelFifoLengthChanged               = @"ORKatrinV4FLTModelFifoLengthChanged";
NSString* ORKatrinV4FLTModelNfoldCoincidenceChanged         = @"ORKatrinV4FLTModelNfoldCoincidenceChanged";
NSString* ORKatrinV4FLTModelVetoOverlapTimeChanged          = @"ORKatrinV4FLTModelVetoOverlapTimeChanged";
NSString* ORKatrinV4FLTModelShipSumHistogramChanged         = @"ORKatrinV4FLTModelShipSumHistogramChanged";
NSString* ORKatrinV4FLTModelTargetRateChanged               = @"ORKatrinV4FLTModelTargetRateChanged";
NSString* ORKatrinV4FLTModelHistMaxEnergyChanged            = @"ORKatrinV4FLTModelHistMaxEnergyChanged";
NSString* ORKatrinV4FLTModelHistPageABChanged               = @"ORKatrinV4FLTModelHistPageABChanged";
NSString* ORKatrinV4FLTModelHistLastEntryChanged            = @"ORKatrinV4FLTModelHistLastEntryChanged";
NSString* ORKatrinV4FLTModelHistFirstEntryChanged           = @"ORKatrinV4FLTModelHistFirstEntryChanged";
NSString* ORKatrinV4FLTModelHistClrModeChanged              = @"ORKatrinV4FLTModelHistClrModeChanged";
NSString* ORKatrinV4FLTModelHistModeChanged                 = @"ORKatrinV4FLTModelHistModeChanged";
NSString* ORKatrinV4FLTModelHistEBinChanged                 = @"ORKatrinV4FLTModelHistEBinChanged";
NSString* ORKatrinV4FLTModelHistEMinChanged                 = @"ORKatrinV4FLTModelHistEMinChanged";
NSString* ORKatrinV4FLTModelStoreDataInRamChanged           = @"ORKatrinV4FLTModelStoreDataInRamChanged";
NSString* ORKatrinV4FLTModelFilterShapingLengthChanged		= @"ORKatrinV4FLTModelFilterShapingLengthChanged";
NSString* ORKatrinV4FLTModelGapLengthChanged                = @"ORKatrinV4FLTModelGapLengthChanged";
NSString* ORKatrinV4FLTModelHistNofMeasChanged              = @"ORKatrinV4FLTModelHistNofMeasChanged";
NSString* ORKatrinV4FLTModelHistMeasTimeChanged             = @"ORKatrinV4FLTModelHistMeasTimeChanged";
NSString* ORKatrinV4FLTModelHistRecTimeChanged              = @"ORKatrinV4FLTModelHistRecTimeChanged";
NSString* ORKatrinV4FLTModelPostTriggerTimeChanged          = @"ORKatrinV4FLTModelPostTriggerTimeChanged";
NSString* ORKatrinV4FLTModelFifoBehaviourChanged            = @"ORKatrinV4FLTModelFifoBehaviourChanged";
NSString* ORKatrinV4FLTModelAnalogOffsetChanged             = @"ORKatrinV4FLTModelAnalogOffsetChanged";
NSString* ORKatrinV4FLTModelLedOffChanged                   = @"ORKatrinV4FLTModelLedOffChanged";
NSString* ORKatrinV4FLTModelInterruptMaskChanged            = @"ORKatrinV4FLTModelInterruptMaskChanged";
NSString* ORKatrinV4FLTModelTModeChanged                    = @"ORKatrinV4FLTModelTModeChanged";
NSString* ORKatrinV4FLTModelHitRateLengthChanged            = @"ORKatrinV4FLTModelHitRateLengthChanged";
NSString* ORKatrinV4FLTModelTriggersEnabledChanged          = @"ORKatrinV4FLTModelTriggersEnabledChanged";
NSString* ORKatrinV4FLTModelGainsChanged                    = @"ORKatrinV4FLTModelGainsChanged";
NSString* ORKatrinV4FLTModelThresholdsChanged               = @"ORKatrinV4FLTModelThresholdsChanged";
NSString* ORKatrinV4FLTModelModeChanged                     = @"ORKatrinV4FLTModelModeChanged";
NSString* ORKatrinV4FLTSettingsLock                         = @"ORKatrinV4FLTSettingsLock";
NSString* ORKatrinV4FLTChan                                 = @"ORKatrinV4FLTChan";
NSString* ORKatrinV4FLTModelTestPatternsChanged             = @"ORKatrinV4FLTModelTestPatternsChanged";
NSString* ORKatrinV4FLTModelGainChanged                     = @"ORKatrinV4FLTModelGainChanged";
NSString* ORKatrinV4FLTModelThresholdChanged                = @"ORKatrinV4FLTModelThresholdChanged";
NSString* ORKatrinV4FLTModelTriggerEnabledMaskChanged       = @"ORKatrinV4FLTModelTriggerEnabledMaskChanged";
NSString* ORKatrinV4FLTModelHitRateEnabledMaskChanged       = @"ORKatrinV4FLTModelHitRateEnabledMaskChanged";
NSString* ORKatrinV4FLTModelHitRateChanged                  = @"ORKatrinV4FLTModelHitRateChanged";
NSString* ORKatrinV4FLTModelTestsRunningChanged             = @"ORKatrinV4FLTModelTestsRunningChanged";
NSString* ORKatrinV4FLTModelTestEnabledArrayChanged         = @"ORKatrinV4FLTModelTestEnabledChanged";
NSString* ORKatrinV4FLTModelTestStatusArrayChanged          = @"ORKatrinV4FLTModelTestStatusChanged";
NSString* ORKatrinV4FLTModelEventMaskChanged                = @"ORKatrinV4FLTModelEventMaskChanged";

NSString* ORKatrinV4FLTSelectedRegIndexChanged              = @"ORKatrinV4FLTSelectedRegIndexChanged";
NSString* ORKatrinV4FLTWriteValueChanged                    = @"ORKatrinV4FLTWriteValueChanged";
NSString* ORKatrinV4FLTSelectedChannelValueChanged          = @"ORKatrinV4FLTSelectedChannelValueChanged";
NSString* ORKatrinV4FLTNoiseFloorChanged                    = @"ORKatrinV4FLTNoiseFloorChanged";
NSString* ORKatrinV4FLTNoiseFloorOffsetChanged              = @"ORKatrinV4FLTNoiseFloorOffsetChanged";
NSString* ORKatrinV4FLTModelActivateDebuggingDisplaysChanged = @"ORKatrinV4FLTModelActivateDebuggingDisplaysChanged";
NSString* ORKatrinV4FLTModeFifoFlagsChanged                 = @"ORKatrinV4FLTModeFifoFlagsChanged";
NSString* ORKatrinV4FLTModelHitRateModeChanged              = @"ORKatrinV4FLTModelHitRateModeChanged";

static NSString* fltTestName[kNumKatrinV4FLTTests]= {
	@"Run Mode",
	@"Ram",
	@"Threshold/Gain",
	@"Speed",
	@"Event",
};



@interface ORKatrinV4FLTModel (private)
- (NSAttributedString*) test:(int)testName result:(NSString*)string color:(NSColor*)aColor;
- (void) enterTestMode;
- (void) leaveTestMode;
- (void) stepNoiseFloor;
@end

@implementation ORKatrinV4FLTModel

- (id) init
{
    self = [super init];
	ledOff = YES;
	histMeasTime = 5;
    [self registerNotificationObservers];
    return self;
}

- (void) dealloc
{
    [fltV4useDmaBlockReadAlarm clearAlarm];
    [fltV4useDmaBlockReadAlarm release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) sleep
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) wakeUp
{
    [super wakeUp];
    [self registerNotificationObservers];
    if(hitRateMode == kKatrinV4HitRunRateAlways){
        [self readHitRates];
    }
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"KatrinV4FLTCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORKatrinV4FLTController"];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORIpeV4CrateModel");
}

- (BOOL) partOfEvent:(short)chan
{
	return (eventMask & (1L<<chan)) != 0;
}

- (void) awakeAfterDocumentLoaded
{
    if(hitRateMode == kKatrinV4HitRunRateAlways){
        [self readHitRates];
    }
}

//'stationNumber' returns the logical number of the FLT (FLT#) (1...20),
//method 'slot' returns index (0...9,11-20) of the FLT, so it represents the position of the FLT in the crate. 
- (int) stationNumber
{
	//is it a minicrate?
	if([[[self crate] class]  isSubclassOfClass: NSClassFromString(@"ORIpeV4MiniCrateModel")]){
		if([self slot]<3)   return [self slot]+1;
		else                return [self slot]; //there is a gap at slot 3 (for the SLT) -tb-
	}
	//... or a full crate?
	if([[[self crate] class]  isSubclassOfClass: NSClassFromString(@"ORIpeV4CrateModel")]){
		if([self slot]<11)  return [self slot]+1;
		else                return [self slot]; //there is a gap at slot 11 (for the SLT) -tb-
	}
	//fallback
	return [self slot]+1;
}

- (ORTimeRate*) totalRate   { return totalRate; }
- (short) getNumberRegisters{ return [katrinV4FLTRegisters numRegisters]; }


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
 	[notifyCenter removeObserver:self]; //guard against a double register
   
    [notifyCenter addObserver : self
                     selector : @selector(runIsAboutToChangeState:)
                         name : ORRunAboutToChangeState
                       object : nil];
					   
    [notifyCenter addObserver : self
                     selector : @selector(runIsAboutToStop:)
                         name : ORRunAboutToStopNotification
                       object : nil];
}

- (void) runIsAboutToStop:(NSNotification*)aNote
{
	runControlState               = eRunStopping;
	syncWithRunControlCounterFlag = 0;
}

- (void) runIsAboutToChangeState:(NSNotification*)aNote
{
    int state = [[[aNote userInfo] objectForKey:@"State"] intValue];

    //is FLT  in data taker list of data task manager?
    if(![self isPartOfRun]) return;
    
    //from here: histogram mode sync option handling
    if(!syncWithRunControl) return;//nothing to care about ... Sync with run control not enabled in dialog ...
    if(syncWithRunControl && (runMode != kKatrinV4FLT_Histo_Mode)) return;//nothing to care about ... Sync with run control not enabled in dialog ...
	
	//we need to care about the following cases:
	// 1. no run active, system going to start run:
	//    do nothing
    //    (old state: eRunStopping/0  , new state: eRunStarting)
	// 2. run active, system going to change state:
	//    then start 'sync'ing' (=waiting until currently recording histograms finished)
	//    possible cases:
    //    old state: eRunStarting        , new state: eRunStopping ->stop run
    //    old state: eRunBetweenSubRuns  , new state: eRunStopping ->stop run (from 'between subruns')
    //    old state: eRunStarting        , new state: eRunBetweenSubRuns ->stop subrun, stay 'between subruns'
    //    old state: eRunBetweenSubRuns  , new state: eRunStarting ->start new subrun (from 'between subruns')
	//    
	//    sync'ing: set 'run wait' (use internal counter); clear histogram counter; wait for next 1 histogram(s); if received: set 'run wait done', reset flag/counter
    //
	//TODO:    WARNING: I observed that I receive 'eRunStarting' after the same state 'eRunStarting', seems to me to be a bug -tb- OK I think this is fixed?
	//    
	
    //NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    //NSLog(@"Called %@::%@   aNote:>>>%@<<<\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aNote);//DEBUG -tb-
	//aNote: >>>NSConcreteNotification 0x5a552d0 {name = ORRunAboutToChangeState; object = (ORRunModel,1) Decoders: ORRunDecoderForRun
    // Connectors: "Run Control Connector"  ; userInfo = {State = 4;}}<<<
	// states: 2,3,4: 2=starting, 3=stopping, 4=between subruns (0 = eRunStopped); see ORGlobal.h, enum 'eRunState'
      //moved to top: int state = [[[aNote userInfo] objectForKey:@"State"] intValue];
	/*
	id rc =  [aNote object];
    NSLog(@"Calling object %@\n",NSStringFromClass([rc class]));//DEBUG -tb-
	switch (state) {
		case eRunStarting://=2
            NSLog(@"   Notification: go to  %@\n",@"eRunStarting");//DEBUG -tb-
			break;
		case eRunBetweenSubRuns://=4
            NSLog(@"   Notification: go to  %@\n",@"eRunBetweenSubRuns");//DEBUG -tb-
			break;
		case eRunStopping://=3
            NSLog(@"   Notification: go to  %@\n",@"eRunStopping");//DEBUG -tb-
			break;
		default:
			break;
	}
	*/
	int lastState = runControlState;
	runControlState = state;
		//NSLog(@"   lastState: %i,   newState: %i\n",lastState,runControlState);//DEBUG -tb-
	if(runControlState==eRunStarting && (lastState==0 || lastState==eRunStopping)){
	    // case 1.
		//NSLog(@"   Case 1: do nothing\n");//DEBUG -tb-
		return;
	}
    else {
	    //catch errors
	    if(runControlState==eRunStarting && lastState==eRunStarting){//should not happen! bug? -tb-
		    NSLog(@" %@::%@   Case 2: ERROR - runControlState==eRunStarting && lastState==eRunStarting\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
		    return;
		}
	    if(syncWithRunControlCounterFlag>0){//should not happen! bug? -tb-
		    NSLog(@" %@::%@   Case 2: WARNING - syncWithRunControlCounterFlag>0 (%i) - did you send multiple stopRun commands?\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),syncWithRunControlCounterFlag);//DEBUG -tb-
		    return;
		}
        if(lastState==eRunBetweenSubRuns) isBetweenSubruns=1; else isBetweenSubruns=0;
	    // case 2. (all other cases)
		//NSLog(@"   Case 2: wait for 1 histogram\n");//DEBUG -tb-
        if([self receivedHistoChanMap]){
		    NSLog(@" %@::%@    WARNING - some of the single histograms already rceived, for others still awaiting: check that sum histograms all added the same amount of histograms. ([self receivedHistoChanMap]:%i) WARNING\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self receivedHistoChanMap]);//DEBUG -tb-
        }
		[self syncWithRunControlStart: 1];
	}
}

- (void) syncWithRunControlStart:(int)numHistograms
{
	[self clearReceivedHistoCounter];
	syncWithRunControlCounterFlag = numHistograms; //we set syncWithRunControlCounterFlag to the number of histograms we yet need to receive
	[self addRunWaitWithReason:@"FLTv4: wait for next histogram."];
}

- (void) syncWithRunControlCheckStopCondition
{
    if(syncWithRunControlCounterFlag >= receivedHistoCounter){//the notification 'runAboutToChangeState' seems to be called every second, if a wait is active, so we need to check for >= (not ==) -tb-
        //this is the sum histogram facility - see - (BOOL) setFromDecodeStageReceivedHistoForChan:(short)aChan
        [self shipSumHistograms];
        //clear waits for run control
	    [self releaseRunWait]; 
	    syncWithRunControlCounterFlag=0;
	}
}

#pragma mark •••Accessors

- (int) energyOffset
{
    return energyOffset;
}

- (void) setEnergyOffset:(int)aEnergyOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyOffset:energyOffset];
    energyOffset = [self restrictIntValue:aEnergyOffset min:0 max:0xfffff];
    //energyOffset = aEnergyOffset;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelEnergyOffsetChanged object:self];
}

- (BOOL) forceFLTReadout
{
    return forceFLTReadout;
}

- (void) setForceFLTReadout:(BOOL)aForceFLTReadout
{
    [[[self undoManager] prepareWithInvocationTarget:self] setForceFLTReadout:forceFLTReadout];
    forceFLTReadout = aForceFLTReadout;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelForceFLTReadoutChanged object:self];
}

- (int) skipFltEventReadout
{
    return skipFltEventReadout;
}

- (void) setSkipFltEventReadout:(int)aSkipFltEventReadout
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSkipFltEventReadout:skipFltEventReadout];
    if(aSkipFltEventReadout) skipFltEventReadout = 0x1;
    else  skipFltEventReadout = 0x0;
    //skipFltEventReadout = aSkipFltEventReadout;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelSkipFltEventReadoutChanged object:self];
}

- (unsigned long) bipolarEnergyThreshTest
{
    return bipolarEnergyThreshTest;
}

- (void) setBipolarEnergyThreshTest:(unsigned long)aBipolarEnergyThreshTest
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBipolarEnergyThreshTest:bipolarEnergyThreshTest];
    bipolarEnergyThreshTest = aBipolarEnergyThreshTest;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelBipolarEnergyThreshTestChanged object:self];
}

- (int) useBipolarEnergy
{
    return useBipolarEnergy;
}

- (void) setUseBipolarEnergy:(int)aUseBipolarEnergy
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseBipolarEnergy:useBipolarEnergy];
    if(aUseBipolarEnergy) useBipolarEnergy = 0x1;
    else  useBipolarEnergy = 0x0;
    //useBipolarEnergy = aUseBipolarEnergy;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelUseBipolarEnergyChanged object:self];
}

- (int) useSLTtime
{
    // return value: NO=0; YES=1; undef (no SLT present) = 2
	id slt = [[self crate] adapter];
	if(slt != nil){
	    if([slt  secondsSetSendToFLTs]) return 1;
        else return 0;
	}
    else return 2;

}

- (void) updateUseSLTtime
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelUseSLTtimeChanged object:self];
}

- (int) boxcarLength
{
    return boxcarLength;
}

- (void) setBoxcarLength:(int)aBoxcarLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBoxcarLength:boxcarLength];
    
    boxcarLength = aBoxcarLength;
	if(boxcarLength<0) boxcarLength=0;
	//if(boxcarLength>3) boxcarLength=3; new firmware 2016 -tb-
	if(boxcarLength>7) boxcarLength=7;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelBoxcarLengthChanged object:self];
}

- (int) useDmaBlockRead
{
    return useDmaBlockRead;
}

- (void) setUseDmaBlockRead:(int)aUseDmaBlockRead
{
    if((!useDmaBlockRead) && aUseDmaBlockRead){//at change from "no" to "yes" post alarm -tb-
            //
            if(!fltV4useDmaBlockReadAlarm){
			    fltV4useDmaBlockReadAlarm = [[ORAlarm alloc] initWithName:@"FLT V4: using DMA mode is still experimental." severity:kInformationAlarm];
			    [fltV4useDmaBlockReadAlarm setSticky:NO];
                [fltV4useDmaBlockReadAlarm setHelpString:@"See Status Log for details."];
		    }
            [fltV4useDmaBlockReadAlarm setAcknowledged:NO];
		    [fltV4useDmaBlockReadAlarm postAlarm];
            NSLog(@"%@::%@  ALARM: You selected to use DMA mode. This mode is still experimental. It is currently available for Energy+Trace (sync) mode only!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	}
    useDmaBlockRead = aUseDmaBlockRead;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelUseDmaBlockReadChanged object:self];
}

- (int) syncWithRunControl
{
    return syncWithRunControl;
}

- (void) setSyncWithRunControl:(int)aSyncWithRunControl
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSyncWithRunControl:syncWithRunControl];
    syncWithRunControl = aSyncWithRunControl;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelSyncWithRunControlChanged object:self];
}

- (double) decayTime
{
    return decayTime;
}

- (void) setDecayTime:(double)aDecayTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDecayTime:decayTime];
    
    decayTime = aDecayTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelDecayTimeChanged object:self];
}


/*
See FLT doc:
attenuation <> poleZeroCorrection settings
attenuation =  = (Decayzeit - Shapingzeit)/Decayzeit
Beispiel:
Decay-Zeit = 50us (so wie beim Monitorspektrometerdetektor)
Shaping-Zeit (halbe Filterlaenge) = 6us
=> X = (50-6)/50 = 44/50 = 0,88  => setting 6
Denis table:
settings attenuation coeff_x_128
15	0,695	89 
14	0,719	92 
13	0,734	94 
12	0,758	97 
11	0,773	99 
10	0,797	102
9	0,813	104 
8	0,836	107 
7	0,859	110 
6	0,875	112 
5	0,898	115 
4	0,914	117 
3	0,938	120 
2	0,953	122 
1	0,977	125 
0	1,000	128
none (default)
*/
- (int) poleZeroCorrection
{
    return poleZeroCorrection;
}

- (void) setPoleZeroCorrection:(int)aPoleZeroCorrection
{
    if(aPoleZeroCorrection<0 || aPoleZeroCorrection>15) aPoleZeroCorrection=0;//allowed range is 0..15, default: 0 -tb-
    [[[self undoManager] prepareWithInvocationTarget:self] setPoleZeroCorrection:poleZeroCorrection];
    
    poleZeroCorrection = aPoleZeroCorrection;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelPoleZeroCorrectionChanged object:self];
}

/*
See FLT doc:
attenuation <> poleZeroCorrection settings
attenuation =  = (Decayzeit - Shapingzeit)/Decayzeit
Beispiel:
Decay-Zeit = 50us (so wie beim Monitorspektrometerdetektor)
Shaping-Zeit (halbe Filterlaenge) = 6us
=> X = (50-6)/50 = 44/50 = 0,88  => setting 6
Denis table:
settings attenuation coeff_x_128
15	0,695	89 
14	0,719	92 
13	0,734	94 
12	0,758	97 
11	0,773	99 
10	0,797	102
9	0,813	104 
8	0,836	107 
7	0,859	110 
6	0,875	112 
5	0,898	115 
4	0,914	117 
3	0,938	120 
2	0,953	122 
1	0,977	125 
0	1,000	128
none (default)
*/
- (double) poleZeroCorrectionHint
{
    if(decayTime == 0.0 ) return 1.0;
	double shaping = (0x1 << filterShapingLength) * 50.0 / 1000.0;
	double pzch = (decayTime - shaping)/decayTime;
    return pzch;
}

- (int) poleZeroCorrectionSettingHint:(double)attenuation
{
static double table[32]={
15,	0.695	, 
14,	0.719	, 
13,	0.734	, 
12,	0.758	, 
11,	0.773	, 
10,	0.797	,
9,	0.813	, 
8,	0.836	, 
7,	0.859	, 
6,	0.875	, 
5,	0.898	, 
4,	0.914	, 
3,	0.938	, 
2,	0.953	, 
1,	0.977	, 
0,	1.000	
};
    int i,hint=0;
	double diff, mindiff=1.0;
	for(i=0;i<16;i++){
	    diff = fabs(attenuation - table[i*2+1]);
		if(diff<mindiff){ mindiff=diff; hint = table[i*2]; }
	}
    return hint;
}

- (int) hitRateMode
{
    return hitRateMode;
}

- (void) setHitRateMode:(int)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateMode:hitRateMode];
    
    hitRateMode = aMode;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHitRateModeChanged object:self];
    if(hitRateMode == kKatrinV4HitRunRateAlways){
        [self startReadingHitRates];
    }
    else {
        [self stopReadingHitRates];
    }
}
- (void) stopReadingHitRates
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
    [self clearHitRates];
}

- (void) clearHitRates
{
    int chan;
    for(chan=0;chan<kNumV4FLTChannels;chan++){
        hitRate[chan] = 0;
    }
    [self setHitRateTotal:0];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHitRateChanged object:self];
}

- (void) startReadingHitRates
{
    [self performSelector:@selector(readHitRates)
               withObject:nil
               afterDelay: 1];		//start reading out the rates
}

- (int) customVariable
{
    return customVariable;
}

- (void) setCustomVariable:(int)aCustomVariable
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCustomVariable:customVariable];
    
    customVariable = aCustomVariable;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelCustomVariableChanged object:self];
}

- (int) receivedHistoCounter
{
    return receivedHistoCounter;
}

- (void) setReceivedHistoCounter:(int)aReceivedHistoCounter
{
    //DEBUG                 NSLog(@"%@::%@   FLT #%i<------------- aReceivedHistoCounter: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self stationNumber],aReceivedHistoCounter);//DEBUG -tb-
    receivedHistoCounter = aReceivedHistoCounter;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelReceivedHistoCounterChanged object:self];
	if(syncWithRunControl && syncWithRunControlCounterFlag>0) [self syncWithRunControlCheckStopCondition];
}

- (void) clearReceivedHistoCounter
{
    [self setReceivedHistoCounter: 0];
}


- (int) receivedHistoChanMap
{
    return receivedHistoChanMap;
}

- (void) setReceivedHistoChanMap:(int)aReceivedHistoChanMap
{
    receivedHistoChanMap = aReceivedHistoChanMap;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelReceivedHistoChanMapChanged object:self];
}

- (BOOL) activateDebuggingDisplays {return activateDebuggingDisplays;}
- (void) setActivateDebuggingDisplays:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setActivateDebuggingDisplays:activateDebuggingDisplays];
    activateDebuggingDisplays = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelActivateDebuggingDisplaysChanged object:self];
}

- (int) fifoLength
{
    return fifoLength;
}

- (void) setFifoLength:(int)aFifoLength
{
	if(aFifoLength != kFifoLength512 && aFifoLength != kFifoLength64) aFifoLength = kFifoLength512;
    [[[self undoManager] prepareWithInvocationTarget:self] setFifoLength:fifoLength];
    fifoLength = aFifoLength;
	//NSLog(@"%@::%@: set setFifoLength to %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aFifoLength);//-tb-NSLog-tb-
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelFifoLengthChanged object:self];
}

- (int) nfoldCoincidence
{
    return nfoldCoincidence;
}

- (void) setNfoldCoincidence:(int)aNfoldCoincidence
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNfoldCoincidence:nfoldCoincidence];
    nfoldCoincidence = aNfoldCoincidence;
	if(nfoldCoincidence<0) nfoldCoincidence=0;
	if(nfoldCoincidence>6) nfoldCoincidence=6;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelNfoldCoincidenceChanged object:self];
}

- (int) vetoOverlapTime
{
    return vetoOverlapTime;
}

- (void) setVetoOverlapTime:(int)aVetoOverlapTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVetoOverlapTime:vetoOverlapTime];
    
    vetoOverlapTime = aVetoOverlapTime;
	if(vetoOverlapTime<0) vetoOverlapTime = 0;
	if(vetoOverlapTime>5) vetoOverlapTime = 5;//changed from 4 to 5 since FLTv4 FPGA 2.1.1.4 -tb-
        
	//NSLog(@"%@::%@: set vetoOverlapTime to %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),vetoOverlapTime);//-tb-NSLog-tb-

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelVetoOverlapTimeChanged object:self];
}

/** This is the setting of the 'Ship Sum Histogram' popup button; tag values are:
  * - 0 NO, don't ship sum histogram
  * - 1 YES, ship sum histogram
  * - 2 ship ONLY sum histogram (not yet implemented)
  */
- (int) shipSumHistogram 
{
    return shipSumHistogram;
}

- (void) setShipSumHistogram:(int)aShipSumHistogram
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipSumHistogram:shipSumHistogram];
    shipSumHistogram = aShipSumHistogram;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelShipSumHistogramChanged object:self];
}

- (int) targetRate { return targetRate; }
- (void) setTargetRate:(int)aTargetRate
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTargetRate:targetRate];
    targetRate = [self restrictIntValue:aTargetRate min:1 max:100];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelTargetRateChanged object:self];
}

- (int) histMaxEnergy { return histMaxEnergy; }
//!< A argument -1 will auto-recalculate the maximum energy which fits still into the histogram. -tb-
- (void) setHistMaxEnergy:(int)aHistMaxEnergy
{
    if(aHistMaxEnergy<0) histMaxEnergy = histEMin + 2048*(1<<histEBin);
    else histMaxEnergy = aHistMaxEnergy;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHistMaxEnergyChanged object:self];
}

- (int) histPageAB{ return histPageAB; }
- (void) setHistPageAB:(int)aHistPageAB
{
    histPageAB = aHistPageAB;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHistPageABChanged object:self];
}

//! runMode is the DAQ run mode.
- (int) runMode { return runMode; }
- (void) setRunMode:(int)aRunMode
{

    [[[self undoManager] prepareWithInvocationTarget:self] setRunMode:runMode];
    runMode = aRunMode;
		
	switch (runMode) {
		case kKatrinV4Flt_EnergyDaqMode:
			[self setFltRunMode:kKatrinV4FLT_Run_Mode];
            readWaveforms = NO;
			break;
            
        case kKatrinV4Flt_EnergyTraceDaqMode:
            [self setFltRunMode:kKatrinV4FLT_Run_Mode];
            readWaveforms = YES;
            break;
            
        case kKatrinV4Flt_Histogram_DaqMode:
            [self setFltRunMode:kKatrinV4FLT_Histo_Mode];
            //TODO: workaround - if set to kFifoStopOnFull the histogramming stops after some seconds - probably a FPGA bug? -tb-
            if(fifoBehaviour == kFifoStopOnFull){
                //NSLog(@"ORKatrinV4FLTModel message: due to a FPGA side effect histogramming mode should run with kFifoEnableOverFlow setting! -tb-\n");//TODO: fix it -tb-
                //    -> removed automatic settings of FIFO length (64) and FIFO behaviour (stop on full) 2013-05 -tb-
                NSLog(@"ORKatrinV4FLTModel  #%i WARNING: switched FIFO behaviour to kFifoEnableOverFlow (required for histogramming mode)\n", [self stationNumber]);//TODO: fix it -tb-
                [self setFifoBehaviour: kFifoEnableOverFlow];
            }
            readWaveforms = NO;
           break;
            
        case kKatrinV4Flt_VetoEnergyDaqMode:
            [self setFltRunMode:kKatrinV4FLT_Veto_Mode];
            break;
            
        case kKatrinV4Flt_VetoEnergyTraceDaqMode:
            [self setFltRunMode:kKatrinV4FLT_Veto_Mode];
            readWaveforms = YES;
            break;
            

		case kKatrinV4Flt_BipolarEnergyDaqMode:  //new since 2016-07 -tb-
			[self setFltRunMode:kKatrinV4FLT_Bipolar_Mode];
            readWaveforms = NO;
			break;
			
		case kKatrinV4Flt_BipolarEnergyTraceDaqMode:  //new since 2016-07 -tb-
			[self setFltRunMode:kKatrinV4FLT_Bipolar_Mode];
			readWaveforms = YES;
			break;
			
		default:
			NSLog(@"ORKatrinV4FLTModel WARNING: setRunMode: received a unknown DAQ run mode (%i)!\n",aRunMode);
			break;
	}
    //    -> removed automatic settings of FIFO length (64) and FIFO behaviour (stop on full) 2013-05 -tb-
	//-tb- 2013-05 [self setFifoLength: fifoLengthSetting];
}

- (BOOL) noiseFloorRunning { return noiseFloorRunning; }

- (int) noiseFloorOffset { return noiseFloorOffset; }
- (void) setNoiseFloorOffset:(int)aNoiseFloorOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseFloorOffset:noiseFloorOffset];
    noiseFloorOffset = aNoiseFloorOffset;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTNoiseFloorOffsetChanged object:self];
}

- (unsigned long) histLastEntry { return histLastEntry; }
- (void) setHistLastEntry:(unsigned long)aHistLastEntry
{
    histLastEntry = aHistLastEntry;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHistLastEntryChanged object:self];
}

- (unsigned long) histFirstEntry { return histFirstEntry; }
- (void) setHistFirstEntry:(unsigned long)aHistFirstEntry
{
    histFirstEntry = aHistFirstEntry;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHistFirstEntryChanged object:self];
}

- (int) histClrMode { return histClrMode; }
- (void) setHistClrMode:(int)aHistClrMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistClrMode:histClrMode];
    histClrMode = aHistClrMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHistClrModeChanged object:self];
}

- (int) histMode { return histMode; }
- (void) setHistMode:(int)aHistMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistMode:histMode];
    histMode = aHistMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHistModeChanged object:self];
}

- (unsigned long) histEBin { return histEBin; }
- (void) setHistEBin:(unsigned long)aHistEBin
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistEBin:histEBin];
    histEBin = aHistEBin;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHistEBinChanged object:self];
    
    //recalc max energy
    [self setHistMaxEnergy: -1];
}

- (unsigned long) histEMin { return histEMin;} 
- (void) setHistEMin:(unsigned long)aHistEMin
{
	[[[self undoManager] prepareWithInvocationTarget:self] setHistEMin:histEMin];
	histEMin = aHistEMin;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHistEMinChanged object:self];

    //recalc max energy
    [self setHistMaxEnergy: -1];
}

//! This is number of cycles (internal FLT counter)
- (unsigned long) histNofMeas { return histNofMeas; }
- (void) setHistNofMeas:(unsigned long)aHistNofMeas
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setHistNofMeas:histNofMeas];
    histNofMeas = aHistNofMeas;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHistNofMeasChanged object:self];
}

//! This is the time after which a intermediate histogram will be read out - in the GUI called "Refresh time".
- (unsigned long) histMeasTime { return histMeasTime; }
- (void) setHistMeasTime:(unsigned long)aHistMeasTime
{
	if(aHistMeasTime<2){
		NSLog(@"%@:: Warning: tried to set refresh time to %i (minimum is 2)\n",NSStringFromClass([self class]),aHistMeasTime); 
		aHistMeasTime=2;
	}
    histMeasTime = aHistMeasTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHistMeasTimeChanged object:self];
}

//! This timer counts from 0 to histMeasTime-1.
- (unsigned long) histRecTime { return histRecTime; }
- (void) setHistRecTime:(unsigned long)aHistRecTime
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setHistRecTime:histRecTime];
    histRecTime = aHistRecTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHistRecTimeChanged object:self];
}


- (BOOL) storeDataInRam { return storeDataInRam; }
- (void) setStoreDataInRam:(BOOL)aStoreDataInRam
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStoreDataInRam:storeDataInRam];
    storeDataInRam = aStoreDataInRam;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelStoreDataInRamChanged object:self];
}

- (int) filterShapingLength { return filterShapingLength; }
- (void) setFilterShapingLength:(int)aFilterShapingLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFilterShapingLength:filterShapingLength];
    int newValue = [self restrictIntValue:aFilterShapingLength min:2 max:8];
    if(filterShapingLength!=0 && newValue!=filterShapingLength){
        float old = 1<<filterShapingLength;
        float new = 1<<newValue;
        float ratio = new/old;
        int chan;
        for(chan=0;chan<kNumV4FLTChannels;chan++){
            unsigned long currentThreshold = [self threshold:chan];
            [self setThreshold:chan withValue:currentThreshold*ratio];
        }
    }
    filterShapingLength = newValue;
	if(filterShapingLength == 8 && gapLength>0){
		[self setGapLength:0];
		NSLog(@"Warning: setFilterShapingLength: FLTv4: maximum filter length allows only gap length of 0. Gap length reset to 0!\n");
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelFilterShapingLengthChanged object:self];
}

- (int) gapLength { return gapLength; }
- (void) setGapLength:(int)aGapLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGapLength:gapLength];
    gapLength = [self restrictIntValue:aGapLength min:0 max:7];
    if(filterShapingLength == 8 && gapLength>0){
		gapLength=0;
		NSLog(@"Warning: setGapLength: FLTv4: maximum filter length allows only gap length of 0. Gap length reset to 0!\n");
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelGapLengthChanged object:self];
}

- (unsigned long) postTriggerTime { return postTriggerTime; }
- (void) setPostTriggerTime:(unsigned long)aPostTriggerTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerTime:postTriggerTime];
    postTriggerTime = [self restrictIntValue:aPostTriggerTime min:6 max:2046];//min 6 is found 'experimental' -tb-
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelPostTriggerTimeChanged object:self];
}

- (int) fifoBehaviour { return fifoBehaviour; }
- (void) setFifoBehaviour:(int)aFifoBehaviour
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFifoBehaviour:fifoBehaviour];
    fifoBehaviour = [self restrictIntValue:aFifoBehaviour min:0 max:1];;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelFifoBehaviourChanged object:self];
}

- (unsigned long) eventMask { return eventMask; }
- (void) eventMask:(unsigned long)aMask
{
	eventMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelEventMaskChanged object:self];
}

- (int) analogOffset{ return analogOffset; }
- (void) setAnalogOffset:(int)aAnalogOffset
{
	
    [[[self undoManager] prepareWithInvocationTarget:self] setAnalogOffset:analogOffset];
    analogOffset = [self restrictIntValue:aAnalogOffset min:0 max:4095];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelAnalogOffsetChanged object:self];
}

- (BOOL) ledOff{ return ledOff; }
- (void) setLedOff:(BOOL)aState
{
    ledOff = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelLedOffChanged object:self];
}

- (unsigned long) interruptMask { return interruptMask; }
- (void) setInterruptMask:(unsigned long)aInterruptMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    interruptMask = aInterruptMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelInterruptMaskChanged object:self];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHitRateLengthChanged object:self];
}

- (unsigned long) triggerEnabledMask { return triggerEnabledMask; } 
- (void) setTriggerEnabledMask:(unsigned long)aMask
{
 	[[[self undoManager] prepareWithInvocationTarget:self] setTriggerEnabledMask:triggerEnabledMask];
	triggerEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelTriggerEnabledMaskChanged object:self];
}

- (unsigned long) hitRateEnabledMask { return hitRateEnabledMask; }
- (void) setHitRateEnabledMask:(unsigned long)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setHitRateEnabledMask:hitRateEnabledMask];
    hitRateEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHitRateEnabledMaskChanged object:self];
}

- (NSMutableArray*) gains { return gains; }
- (void) setGains:(NSMutableArray*)aGains
{
	[aGains retain];
	[gains release];
    gains = aGains;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelGainsChanged object:self];
}

- (NSMutableArray*) thresholds { return thresholds; }
- (void) setThresholds:(NSMutableArray*)aThresholds
{
	[aThresholds retain];
	[thresholds release];
    thresholds = aThresholds;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelThresholdsChanged object:self];
}

-(unsigned long) threshold:(unsigned short) aChan
{
    return [[thresholds objectAtIndex:aChan] intValue];
}

-(unsigned short) gain:(unsigned short) aChan
{
    return [[gains objectAtIndex:aChan] shortValue];
}

-(void) setThreshold:(unsigned short) aChan withValue:(unsigned long) aThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
	aThreshold = [self restrictIntValue:aThreshold min:0 max:0xfffff];
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aThreshold]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORKatrinV4FLTChan];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelThresholdChanged object:self userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain
{
	if(aGain>0xfff) aGain = 0xfff;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:aChan withValue:[self gain:aChan]];
	[gains replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aGain]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORKatrinV4FLTChan];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelGainChanged object:self userInfo: userInfo];
	
	[self postAdcInfoProvidingValueChanged];
}

- (unsigned long) thresholdForDisplay:(unsigned short) aChan
{
	return [self threshold:aChan];
}

- (unsigned short) gainForDisplay:(unsigned short) aChan
{
	return [self gain:aChan];
}

-(BOOL) triggerEnabled:(unsigned short) aChan
{
	if(aChan<kNumV4FLTChannels)return (triggerEnabledMask >> aChan) & 0x1;
	else return NO;
}

-(void) setTriggerEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerEnabled:aChan withValue:(triggerEnabledMask>>aChan)&0x1];
	if(aState) triggerEnabledMask |= (1L<<aChan);
	else triggerEnabledMask &= ~(1L<<aChan);
	
    [[NSNotificationCenter defaultCenter]postNotificationName:ORKatrinV4FLTModelTriggerEnabledMaskChanged object:self];
	[self postAdcInfoProvidingValueChanged];
}

- (BOOL) hitRateEnabled:(unsigned short) aChan
{
 	if(aChan<kNumV4FLTChannels)return (hitRateEnabledMask >> aChan) & 0x1;
	else return NO;
}

- (void) setHitRateEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateEnabled:aChan withValue:(hitRateEnabledMask>>aChan)&0x1];
	if(aState) hitRateEnabledMask |= (1L<<aChan);
	else hitRateEnabledMask &= ~(1L<<aChan);
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHitRateEnabledMaskChanged object:self];
}

- (int) fltRunMode { return fltRunMode; }
- (void) setFltRunMode:(int)aMode
{
    fltRunMode = aMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelModeChanged object:self];
}

- (void) enableAllHitRates:(BOOL)aState
{
	[self setHitRateEnabledMask:aState?0xffffff:0x0];
}

- (void) enableAllTriggers:(BOOL)aState
{
	[self setTriggerEnabledMask:aState?0xffffff:0x0];
	[self postAdcInfoProvidingValueChanged];
}

- (void) setHitRateTotal:(float)newTotalValue
{
	hitRateTotal = newTotalValue;
	if(!totalRate){
		[self setTotalRate:[[[ORTimeRate alloc] init] autorelease]];
	}
	[totalRate addDataToTimeAverage:hitRateTotal];
}

- (float) hitRateTotal 
{ 
	return hitRateTotal; 
}

- (float) hitRate:(unsigned short)aChan
{
	if(aChan<kNumV4FLTChannels) return hitRate[aChan];
	else                        return 0.0;
}



- (float) rate:(int)aChan { return [self hitRate:aChan]; }
- (BOOL) hitRateOverFlow:(unsigned short)aChan
{
	if(aChan<kNumV4FLTChannels)return hitRateOverFlow[aChan];
	else return NO;
}

- (unsigned short) selectedChannelValue { return selectedChannelValue; }
- (void) setSelectedChannelValue:(unsigned short) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedChannelValue:selectedChannelValue];
    selectedChannelValue = aValue;
    [[NSNotificationCenter defaultCenter]	 postNotificationName:ORKatrinV4FLTSelectedChannelValueChanged	 object:self];
}

- (unsigned short) selectedRegIndex { return selectedRegIndex; }
- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:selectedRegIndex];
    selectedRegIndex = anIndex;
    [[NSNotificationCenter defaultCenter]	 postNotificationName:ORKatrinV4FLTSelectedRegIndexChanged	 object:self];
}

- (unsigned long) writeValue { return writeValue; }
- (void) setWriteValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    writeValue = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTWriteValueChanged object:self];
}


- (void) setToDefaults
{
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		[self setThreshold:i withValue:17000];
		[self setGain:i withValue:0];
	}
	[self setGapLength:0];
	[self setFilterShapingLength:7];
	[self setFifoBehaviour:kFifoEnableOverFlow];// kFifoEnableOverFlow or kFifoStopOnFull
	[self setPostTriggerTime:1024]; // max. filter length should fit into the range -tb-
	
	[self setHistMeasTime:	5];
	
	[self setPoleZeroCorrection:0];
}


- (void) devTest1ButtonAction
{
    //NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	[self addRunWaitWithReason:@"A reason to delay"];
}

- (void) devTest2ButtonAction
{
	[self releaseRunWait]; 
}

//Testpulser tests -tb-
//SLT registers
static const uint32_t SLTTPTimingRam     = 0xc80000 >> 2;
static const uint32_t SLTTPShapeRam      = 0xc81000 >> 2;
static const uint32_t SLTControlReg      = 0xa80000 >> 2;
static const uint32_t SLTCommandReg      = 0xa80008 >> 2;

- (void) testButtonLowLevelConfigTP
{
    NSLog(@"n   configTPButton: Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	//[self releaseRunWait]; 
	
	//write TP shape ram (if constant step height: set only the first AND TPShape bit=0)
	int i=0;
	static uint32_t shape = 0x210;
	NSLog(@"shape is: 0x%x  (%i) ",shape,shape);
	[[[self crate] adapter] rawWriteReg: SLTTPShapeRam+i value: shape]; i++;
	
	//write TP timing ram
	i=0;
	[[[self crate] adapter] rawWriteReg: SLTTPTimingRam+i value: 0x164];  i++; // das gehoert zum FLT pattern mit index 1 (?)
	[[[self crate] adapter] rawWriteReg: SLTTPTimingRam+i value: 0x0];    i++; //0x64 = 100 (* 50/100 nanosec) //10 u sec;
	[[[self crate] adapter] rawWriteReg: SLTTPTimingRam+i value: 0x50];   i++;
	[[[self crate] adapter] rawWriteReg: SLTTPTimingRam+i value: 0x0];    i++;
		
	//reset FLT TP pointer kFLTV4CommandReg
	uint32_t anAddress = [self regAddress: kFLTV4CommandReg];
	uint32_t rstTp     = 0x10; //bit 4
	[[[self crate] adapter] rawWriteReg: anAddress value: rstTp];
	NSLog(@"Wrote: flt command reg (0x%x): 0x%x  \n",anAddress,rstTp);
    
	//write FLT test pattern ram
	anAddress = [self regAddress: kFLTV4TestPatternReg];
	uint32_t fltpattern = 0xffffff;
	
	[[[self crate] adapter] rawWriteReg: anAddress   value: 0x0];
	[[[self crate] adapter] rawWriteReg: anAddress+1 value: fltpattern];
	[[[self crate] adapter] rawWriteReg: anAddress+2 value: 0x2000000];
	[[[self crate] adapter] rawWriteReg: anAddress+3 value: fltpattern];
	[[[self crate] adapter] rawWriteReg: anAddress+4 value: 0x0];
	
	//set SLT control register
	uint32_t control=	[[[self crate] adapter] rawReadReg: SLTControlReg ];
	NSLog(@"control reg: 0x%x   ",control);
	control = control & ~(0x7<<11);
	NSLog(@"  -  after reset: control reg: 0x%x  \n",control);
	control = (control | (0x01<<11)); //0x1 oder 0x5
	// 0bXYZ is: TPShape X=0: constant DC level; X=1 shaped DC level; YZ= TP Enable: 00=no; 01=SW; 10=global(Lemo?); 11=FrontPanel
	[[[self crate] adapter] rawWriteReg: SLTControlReg value: control];
	NSLog(@"  -  after write: control reg: 0x%x  \n",control);
	
	//set FLT control register flag
	anAddress = [self regAddress: kFLTV4ControlReg];
	uint32_t fltcontrol=	[[[self crate] adapter] rawReadReg: anAddress ];
	NSLog(@"flt control reg: 0x%x   ",fltcontrol);
	fltcontrol = fltcontrol | (0x10);//bit 4
	[[[self crate] adapter] rawWriteReg: anAddress value: fltcontrol];
	NSLog(@"  -  after write: flt control reg: 0x%x  \n",fltcontrol);
}

- (void) testButtonLowLevelFireTP
{
        NSLog(@"   fireTPButton: Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
		
	//reset FLT TP pointer kFLTV4CommandReg
	uint32_t fltaddress = [self regAddress: kFLTV4CommandReg];
	uint32_t rstTp = 0x10; //bit 4 
	NSLog(@"flt kFLTV4CommandReg reg: 0x%x   ",fltaddress);
	[[[self crate] adapter] rawWriteReg: fltaddress value: rstTp];
	NSLog(@"  - wrote: flt command reg: 0x%x  \n",rstTp);
	
	//fire TP SLT command
	//[self releaseRunWait]; 
	//write FLT test pattern ram
	//uint32_t address = [self regAddress: kSLTV4CommandReg];
	[[[self crate] adapter] rawWriteReg: SLTCommandReg   value: 0x8];
}

- (void) testButtonLowLevelResetTP
{
    NSLog(@"   resetTPButton: Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	//[self releaseRunWait]; 
	uint32_t control=	[[[self crate] adapter] rawReadReg: SLTControlReg ];
	NSLog(@"control reg: 0x%x   ",control);
	control = control & ~(0x7<<11);
	NSLog(@"  -  after reset: control reg: 0x%x  \n",control);
	[[[self crate] adapter] rawWriteReg: SLTControlReg value: control];

	//reset FLT control register flag
	uint32_t fltaddress = [self regAddress: kFLTV4ControlReg];
	uint32_t fltcontrol=	[[[self crate] adapter] rawReadReg: fltaddress ];
	NSLog(@"flt control reg: 0x%x   ",fltcontrol);
	fltcontrol = fltcontrol & ~(0x10);//bit 4 to 0
	[[[self crate] adapter] rawWriteReg: fltaddress value: fltcontrol];
	NSLog(@"  -  after write: flt control reg: 0x%x  \n",fltcontrol);
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

- (void) setTimeToMacClock //TODO: for the database UTC should be used -tb-
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
	//use the command list to load all the thresholds and gains with one PMC command packet
	int i;
	ORCommandList* aList = [ORCommandList commandList];
	for(i=0;i<kNumV4FLTChannels;i++){
		unsigned long thres;
		if( !(triggerEnabledMask & (0x1<<i)) )	thres = 0xfffff;
		else									thres = [self threshold:i];
        //DEBUG: FOR TESTING!!! 2013-11-21 added for polar energy
		unsigned long threshPolar;
        threshPolar = bipolarEnergyThreshTest & 0xfff;
        thres = thres & 0xFFFFF;
		[aList addCommand: [self writeRegCmd:kFLTV4ThresholdReg channel:i value: ((threshPolar<<20) | thres)]];
		[aList addCommand: [self writeRegCmd:kFLTV4GainReg channel:i value:[self gain:i] & 0xFFF]];
	}
	[aList addCommand: [self writeRegCmd:kFLTV4CommandReg value:kIpeFlt_Cmd_LoadGains]];
	
	[self executeCommandList:aList];
    
    //TODO: now we should wait 180 usec or check the busy flag before other write/read accesses -tb-
    // (usually (but not guaranteed!) access via TCP/IP is slow enought to produce a 180 usec timeout)
}

- (int) restrictIntValue:(int)aValue min:(int)aMinValue max:(int)aMaxValue
{
	if(aValue<aMinValue)	  return aMinValue;
	else if(aValue>aMaxValue) return aMaxValue;
	else					  return aValue;
}

- (float) restrictFloatValue:(int)aValue min:(float)aMinValue max:(float)aMaxValue
{
	if(aValue<aMinValue)	  return aMinValue;
	else if(aValue>aMaxValue) return aMaxValue;
	else					  return aValue;
}

- (void) initBoard
{
    [self writeControlWithStandbyMode];     //standby mode so the HW is stable for the following writes
	[self writeReg: kFLTV4HrControlReg     value:hitRateLength];
	[self writeReg: kFLTV4PostTriggerReg      value:postTriggerTime];
	[self writeReg: kFLTV4EnergyOffsetReg  value:energyOffset];//new 2016-07 - is it OK for old firmware? -tb-
	[self loadThresholdsAndGains];
	[self writeReg:kFLTV4AnalogOffsetReg  value:analogOffset];
	[self writeTriggerControl];			//TODO:   (for v4 this needs to be implemented by DENIS)-tb- //set trigger mask
	[self writeHitRateMask];			//set hitRage control mask
	
	if(fltRunMode == kKatrinV4FLT_Histo_Mode){
		[self writeHistogramControl];
	}
    [self writeRunControl:YES];
    [self writeControl];                //come out of standby mode
}

- (unsigned long) readStatus
{
	return [self readReg: kFLTV4StatusReg ];
}

- (unsigned long) readControl
{
	return [self readReg: kFLTV4ControlReg];
}

//TODO: better use the STANDBY flag of the FLT -tb- 2010-01-xx     !!!!!!!!!!!!!!!!!
- (void) writeRunControl:(BOOL)startSampling
{
	unsigned long aValue = 
	(((boxcarLength)        & 0x7)<<28)	|		//boxcarLength is the register value and the popup item tag. extended to 3 bits in 2016, needed to be shifted to bit 28
    (((poleZeroCorrection)  & 0xf)<<24) |		//poleZeroCorrection is stored as the popup index -- NEW since 2011-06-09 -tb-
	(((nfoldCoincidence)    & 0xf)<<20) |		//nfoldCoincidence is stored as the popup index -- NEW since 2010-11-09 -tb-
	(((vetoOverlapTime)     & 0xf)<<16)	|		//vetoOverlapTime is stored as the popup index -- NEW since 2010-08-04 -tb-
	(((boxcarLength)        & 0x3)<<14)	|		//boxcarLength is the register value and the popup item tag -tb-
	(((filterShapingLength) & 0xf)<<8)	|		//filterShapingLength is the register value and the popup item tag -tb-
	((gapLength & 0xf)<<4)              |
	((startSampling & 0x1)<<3)          |		// run trigger unit
	((startSampling & 0x1)<<2)          |		// run filter unit
	((startSampling & 0x1)<<1)          |		// start ADC sampling
	 (startSampling & 0x1);                     // store data in QDRII RAM
	
	[self writeReg:kFLTV4RunControlReg value:aValue];					
}

- (void) writeControl
{
	
	//TODO: add fifo length -tb- <---------------------------------------------
	unsigned long aValue =	((fltRunMode & 0xf)<<16) | 
	//((useBipolarEnergy & 0x1)<<18) |
	((fifoLength       & 0x1)<<25) |
	((fifoBehaviour    & 0x1)<<24) |
	((ledOff & 0x1)<<1 );
    
    
    //TODO: force polar energy flag -tb-
    //aValue = aValue | 0x40000;
    
	[self writeReg: kFLTV4ControlReg value:aValue];
}

/** Possible values are (see SLTv4_HW_Definitions.h):
    kKatrinV4FLT_StandBy_Mode,
	kKatrinV4FLT_Run_Mode,
	kKatrinV4FLT_Histo_Mode,
	kKatrinV4FLT_Veto_Mode
  */
- (void) writeControlWithFltRunMode:(int)aMode
{
	//TODO: add fifo length -tb- <---------------------------------------------
	unsigned long aValue =  ((aMode         & 0xf)<<16)         |
                            ((fifoLength    & 0x1)<<25)    |
                            ((fifoBehaviour & 0x1)<<24) |
                            ((ledOff        & 0x1)<<1 );
	[self writeReg: kFLTV4ControlReg value:aValue];
}

//! Write FLTv4 control register with flt run mode 'Standby' (=0).
- (void) writeControlWithStandbyMode
{
	[self writeControlWithFltRunMode: kKatrinV4FLT_StandBy_Mode];
}

- (void) writeHistogramControl
{
	[self writeReg:kFLTV4HistMeasTimeReg value:histMeasTime];
	unsigned long aValue =  ((histClrMode & 0x1)<<29) |
                            ((histMode    & 0x1)<<28) |
                            ((histEBin    & 0xF)<<20) |
                            histEMin & 0xFFFFF;
	[self writeReg:kFLTV4HistgrSettingsReg value:aValue];
}

- (unsigned long) regAddress:(int)aReg channel:(int)aChannel
{
    return [katrinV4FLTRegisters addressForStation:[self stationNumber] registerIndex:aReg chan:aChannel];
}

- (unsigned long) regAddress:(int)aReg
{
    return [katrinV4FLTRegisters addressForStation:[self stationNumber] registerIndex:aReg ];
}

- (unsigned long) adcMemoryChannel:(int)aChannel page:(int)aPage
{
	//TODO:  replace by V4 code -tb-
    //adc access now is very different from v3 -tb-
	return 0;
    //TODO: obsolete (v3) -tb-
	return ([self slot] << 24) | (0x2 << kIpeFlt_AddressSpace) | (aChannel << kIpeFlt_ChannelAddress)	| (aPage << kIpeFlt_PageNumber);
}
- (int) accessTypeOfReg:(int)aReg
{
    return [katrinV4FLTRegisters accessType:aReg];
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

- (void) writeThreshold:(int)i value:(unsigned int)aValue
{
	aValue &= 0xfffff;
	[self writeReg: kFLTV4ThresholdReg channel:i value:aValue];
}

- (unsigned int) readThreshold:(int)i
{
	return [self readReg:kFLTV4ThresholdReg channel:i] & 0xfffff;
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
	[self writeNextPattern:0];
	int i;
	for(i=0;i<len;i++){
		[self writeNextPattern:mask[i]];
		NSLog(@"%d: %@\n",i,mask[i]?@".":@"-");
	}
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
	return [self readReg:kFLTV4HrMeasEnableReg] & 0xffffff;
}

- (void) writeInterruptMask
{
	[self writeReg:kFLTV4InterruptMaskReg value:interruptMask];
}

- (void) fireSoftwareTrigger
{
	//for TESTs: send a software trigger
	[self writeReg:kFLTV4CommandReg value:kIpeFlt_SW_Trigger];
}

//TODO: TBD after firmware update -tb- 2010-01-28
- (void) disableAllTriggers
{
	[self writeReg:kFLTV4PixelSettings1Reg value:0x0];
	[self writeReg:kFLTV4PixelSettings2Reg value:0xffffff];
}

- (void) disableAllTriggersIfInVetoMode
{
    if(runMode == kKatrinV4Flt_VetoEnergyDaqMode || runMode == kKatrinV4Flt_VetoEnergyTraceDaqMode){
        oldTriggerEnabledMask = triggerEnabledMask;
        [self setTriggerEnabledMask:0x0];
        [self postAdcInfoProvidingValueChanged];
    }
}

- (void) restoreTriggersIfInVetoMode
{
    if(runMode == kKatrinV4Flt_VetoEnergyDaqMode || runMode == kKatrinV4Flt_VetoEnergyTraceDaqMode){
        [self setTriggerEnabledMask:oldTriggerEnabledMask];
        [self postAdcInfoProvidingValueChanged];
    }
}

//TODO: TBD after firmware update -tb- 2010-01-28
- (void) writeTriggerControl  //TODO: must be handled by readout, single pixels cannot be disabled for KATRIN ; this is fixed now, remove workaround after all crates are updated -tb-
{
    //PixelSetting....
	//2,1:
	//0,0 Normal
	//0,1 test pattern
	//1,0 always 0
	//1,1 always 1
	[self writeReg:kFLTV4PixelSettings1Reg value:0]; //must be handled by readout, single pixels cannot be disabled for KATRIN - OK, FIRMWARE FIXED -tb-
	uint32_t mask = (~triggerEnabledMask) & 0xffffff;
	[self writeReg:kFLTV4PixelSettings2Reg value: mask];
}

- (void) readHitRates
{
    unsigned long sltSubSec     = 0;
    unsigned long sltSec        = 0;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
	@try {
        id slt      = [[self crate] adapter];
        if([slt sbcIsConnected]){
            
            if(hitRateLength != lastHitRateLength){
                lastHitRateLength = hitRateLength;
                if([self hitRateMode] == kKatrinV4HitRunRateAlways){
                    [self writeReg: kFLTV4HrControlReg value:hitRateLength];
                    [self clearHitRates];
                }
            }
            
            else {
                BOOL    oneChanged          = NO;
                int     hitRateLengthSec    = 1<<hitRateLength;
                float   freq                = 1.0/(float)hitRateLengthSec;
                        
                unsigned long location = (([self crateNumber]&0xf)<<21) | ([self stationNumber]& 0x0000001f)<<16;
                unsigned long data[5 + kNumV4FLTChannels + kNumV4FLTChannels];//2013-04-24 changed to ship full 32 bit counter; data format changed! see decoder -tb-
                
                //combine all the hitrate read commands into one command packet
                ORCommandList* aList = [[ORCommandList commandList] retain];
                
                int countHREnabledChans = 0;
                int chan;
                for(chan=0;chan<kNumV4FLTChannels;chan++){
                    if(hitRateEnabledMask & (1L<<chan)){
                        [aList addCommand: [self readRegCmd:kFLTV4HitRateReg channel:chan]];
                        countHREnabledChans++;
                    }
                }
                [self executeCommandList:aList];
                
                //pull out the result (same order as commands)
                float   newTotal  = 0;
                int     dataIndex = 0;
                for(chan=0;chan<kNumV4FLTChannels;chan++){
                    if(hitRateEnabledMask & (1L<<chan)){
                        unsigned long aValue32 = [aList longValueForCmd:dataIndex];
                        //BOOL overflow = (aValue >> 31) & 0x1;
                        unsigned long overflow              = 0;//2013-04-24 for legacy data we 'simulate' a 16 bit counter -> simulate a 16 bit overflow flag -tb-
                        if(aValue32 & 0xffff0000) overflow  = 0x1;//2013-04-24 for legacy data we 'simulate' a 16 bit counter -> simulate a 16 bit overflow flag -tb-
                        unsigned long overflow32            = (aValue32 >>23) & 0x1;//2013-04-24 for legacy data we 'simulate' a 16 bit counter -> simulate a 16 bit overflow flag -tb-
                        unsigned long aValue16              = aValue32 & 0xffff;
                        aValue32                            = aValue32 & 0x7fffff;

                        data[dataIndex + 5]                 = ((chan&0xff)<<20) | ((overflow&0x1)<<16) | aValue16;    // The 16 bit values
                        data[5 + dataIndex + countHREnabledChans] =  aValue32 * freq;                                       // The 32 bit values (new format);

                        //... = aValue32 & 0xff000000; this is the new (2013-11) overflow counter: what to do with it? -tb-
                        if(aValue32 != hitRate[chan] || overflow32 != hitRateOverFlow[chan]){
                            if (hitRateLengthSec!=0)	hitRate[chan] = aValue32 * freq;
                            else					    hitRate[chan] = 0;
                            
                            if(overflow32) hitRate[chan] = 0;
                            hitRateOverFlow[chan] = overflow32;
                            
                            oneChanged = YES;
                        }
                        if(!hitRateOverFlow[chan]){
                            newTotal += hitRate[chan];
                        }
                        dataIndex++;
                    }
                }
                [aList release];

                if(	dataIndex != countHREnabledChans){
                    NSLog(@"ERROR:  Shipping hitrates: FLT #%i:	dataIndex %i,  countHREnabledChans %i are not the same!!!\n",[self stationNumber],dataIndex , countHREnabledChans);	
                }
                
                sltSec      =  [slt getSeconds];
                sltSubSec   =  [slt readSubSecondsCounter];

                if(dataIndex>0 && [gOrcaGlobals runInProgress]){
                    time_t	ut_time;
                    time(&ut_time);

                    data[0] = hitRateId | (dataIndex + countHREnabledChans + 5); 
                    data[1] = location  | ((countHREnabledChans & 0x1f)<<8) | 0x1; //2013-04-24 version of record type: 0x1: shipping  32 bit hitrate registers  -tb-
                    data[2] = sltSec;
                    data[3] = hitRateLengthSec;	
                    data[4] = newTotal;

                    [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification
                                                                        object:[NSData dataWithBytes:data length:sizeof(long)*(dataIndex + 5 + countHREnabledChans)]];
                }
                
                [self setHitRateTotal:newTotal];
                
                if(oneChanged){
                    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHitRateChanged object:self];
                }
            }
            
        }
        else {
            [self clearHitRates];
        }
	}
	@catch(NSException* localException) {
        NSLogError(@"",@"Hit Rate Exception",[self fullID],nil);
	}

    //try to read always between two second strobes -> sec = fullSec+0.4
    double delay      = 1<<[self hitRateLength];
    double deltadelay = 0.4 - 0.00000005*sltSubSec;
    delay += deltadelay;
    [self performSelector:@selector(readHitRates) withObject:nil afterDelay:(delay)];
}

//------------------
//command Lists
- (void) executeCommandList:(ORCommandList*)aList
{
	[[[self crate] adapter] executeCommandList:aList];
}

- (id) readRegCmd:(unsigned long) aRegister channel:(short) aChannel
{
	unsigned long theAddress = [self regAddress:aRegister channel:aChannel];
	return [[[self crate] adapter] readHardwareRegisterCmd:theAddress];		
}

- (id) readRegCmd:(unsigned long) aRegister
{
	return [[[self crate] adapter] readHardwareRegisterCmd:[self regAddress:aRegister]];		
}

- (id) writeRegCmd:(unsigned long) aRegister channel:(short) aChannel value:(unsigned long)aValue
{
	unsigned long theAddress = [self regAddress:aRegister channel:aChannel];
	return [[[self crate] adapter] writeHardwareRegisterCmd:theAddress value:aValue];		
}

- (id) writeRegCmd:(unsigned long) aRegister value:(unsigned long)aValue
{
	return [[[self crate] adapter] writeHardwareRegisterCmd:[self regAddress:aRegister] value:aValue];
}

//------------------


- (void) readHistogrammingStatus
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHistogrammingStatus) object:nil];

    int histoUpdateRate = 1; // sec
    unsigned long recTime = [self readReg:kFLTV4HistRecTimeReg];
    unsigned long histoID = [self readReg:kFLTV4HistNumMeasReg];
    unsigned long pageAB  = ([self readReg:kFLTV4StatusReg] >>28) & 0x1;
    
    //DEBUG OUTPUT - NSLog(@"HistoStatus: recTime: %i  histoID: %i, pageAB: %i \n",recTime,histoID, pageAB);
    [self setHistRecTime: recTime];
    [self setHistNofMeas: histoID];
    [self setHistPageAB: pageAB];
    
	[self performSelector:@selector(readHistogrammingStatus) withObject:nil afterDelay:histoUpdateRate];
}

- (NSString*) rateNotification
{
	return ORKatrinV4FLTModelHitRateChanged;
}

#pragma mark •••archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];

    
    [[self undoManager] disableUndoRegistration];
	
    [self setEnergyOffset:              [decoder decodeIntForKey:   @"energyOffset"]];
    [self setSkipFltEventReadout:       [decoder decodeIntForKey:   @"skipFltEventReadout"]];
    [self setBipolarEnergyThreshTest:   [decoder decodeInt32ForKey: @"bipolarEnergyThreshTest"]];
    [self setBoxcarLength:              [decoder decodeIntForKey:   @"boxcarLength"]];
    [self setUseDmaBlockRead:           [decoder decodeIntForKey:   @"useDmaBlockRead"]];
    [self setSyncWithRunControl:        [decoder decodeIntForKey:   @"syncWithRunControl"]];
    [self setDecayTime:                 [decoder decodeDoubleForKey:@"decayTime"]];
    [self setPoleZeroCorrection:        [decoder decodeIntForKey:   @"poleZeroCorrection"]];
    [self setCustomVariable:            [decoder decodeIntForKey:   @"customVariable"]];
    [self setFifoLength:                [decoder decodeIntForKey:   @"fifoLength"]];
    [self setNfoldCoincidence:          [decoder decodeIntForKey:   @"nfoldCoincidence"]];
    [self setVetoOverlapTime:           [decoder decodeIntForKey:   @"vetoOverlapTime"]];
    [self setShipSumHistogram:          [decoder decodeIntForKey:   @"shipSumHistogram"]];
    [self setActivateDebuggingDisplays: [decoder decodeBoolForKey:  @"activateDebuggingDisplays"]];
    [self setHitRateMode:               [decoder decodeIntForKey:   @"hitRateMode"]];
    [self setForceFLTReadout:           [decoder decodeBoolForKey:@"forceFLTReadout"]];
    [self setFilterShapingLength:       [decoder decodeIntForKey:@"filterShapingLength"]];
	
	//TODO: many fields are  still in super class ORIpeV4FLTModel, some should move here (see ORIpeV4FLTModel::initWithCoder, see my comments in 2011-04-07-ORKatrinV4FLTModel.m) -tb-
    
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
    [encoder encodeInt:energyOffset                 forKey:@"energyOffset"];
    [encoder encodeBool:forceFLTReadout             forKey:@"forceFLTReadout"];
    [encoder encodeInt:skipFltEventReadout          forKey:@"skipFltEventReadout"];
    [encoder encodeInt32:bipolarEnergyThreshTest    forKey:@"bipolarEnergyThreshTest"];
    //[encoder encodeInt:useBipolarEnergy           forKey:@"useBipolarEnergy"];
    //[encoder encodeInt:useSLTtime                 forKey:@"useSLTtime"];
    [encoder encodeInt:boxcarLength                 forKey:@"boxcarLength"];
    [encoder encodeInt:useDmaBlockRead              forKey:@"useDmaBlockRead"];
    [encoder encodeInt:syncWithRunControl           forKey:@"syncWithRunControl"];
    [encoder encodeDouble:decayTime                 forKey:@"decayTime"];
    [encoder encodeInt:poleZeroCorrection           forKey:@"poleZeroCorrection"];
    [encoder encodeInt:customVariable               forKey:@"customVariable"];
    [encoder encodeInt:fifoLength                   forKey:@"fifoLength"];
    [encoder encodeInt:nfoldCoincidence             forKey:@"nfoldCoincidence"];
    [encoder encodeInt:vetoOverlapTime              forKey:@"vetoOverlapTime"];
    [encoder encodeInt:shipSumHistogram             forKey:@"shipSumHistogram"];
    [encoder encodeBool:activateDebuggingDisplays   forKey:@"activateDebuggingDisplays"];
    [encoder encodeInt:hitRateMode                  forKey:@"hitRateMode"];
    [encoder encodeInt:filterShapingLength          forKey:@"filterShapingLength"];
}

#pragma mark Data Taking
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) aDataId
{
    dataId = aDataId;
}

- (unsigned long) waveFormId { return waveFormId; }
- (void) setWaveFormId: (unsigned long) aWaveFormId
{
    waveFormId = aWaveFormId;
}

- (unsigned long) hitRateId { return hitRateId; }
- (void) setHitRateId: (unsigned long) aDataId
{
    hitRateId = aDataId;
}

- (unsigned long) histogramId { return histogramId; }
- (void) setHistogramId: (unsigned long) aDataId
{
    histogramId = aDataId;
}


- (void) setDataIds:(id)assigner
{
    dataId      = [assigner assignDataIds:kLongForm];
    hitRateId   = [assigner assignDataIds:kLongForm];
    waveFormId  = [assigner assignDataIds:kLongForm];
    histogramId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
    [self setHitRateId:[anotherCard hitRateId]];
    [self setWaveFormId:[anotherCard waveFormId]];
    [self setHistogramId:[anotherCard histogramId]];
}


- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORKatrinV4FLTDecoderForEnergy",		@"decoder",
								 [NSNumber numberWithLong:dataId],		@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:7],			@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"KatrinV4FLTEnergy"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"ORKatrinV4FLTDecoderForWaveForm",		@"decoder",
                               [NSNumber numberWithLong:waveFormId],	@"dataId",
                               [NSNumber numberWithBool:YES],			@"variable",
                               [NSNumber numberWithLong:-1],			@"length",
                               nil];
    [dataDictionary setObject:aDictionary forKey:@"KatrinV4FLTWaveForm"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"ORKatrinV4FLTDecoderForHitRate",		@"decoder",
                               [NSNumber numberWithLong:hitRateId],		@"dataId",
                               [NSNumber numberWithBool:YES],			@"variable",
                               [NSNumber numberWithLong:-1],			@"length",
                               nil];
    [dataDictionary setObject:aDictionary forKey:@"KatrinV4FLTHitRate"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"ORKatrinV4FLTDecoderForHistogram",		@"decoder",
                               [NSNumber numberWithLong:histogramId],	@"dataId",
                               [NSNumber numberWithBool:YES],			@"variable",
                               [NSNumber numberWithLong:-1],			@"length",
                               nil];
    [dataDictionary setObject:aDictionary forKey:@"KatrinV4FLTHistogram"];
	
	
    return dataDictionary;
}



//this goes to the Run header ...
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    //TO DO....other things need to be added here.....
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:thresholds										forKey:@"thresholds"];
    [objDictionary setObject:gains											forKey:@"gains"];
    [objDictionary setObject:[NSNumber numberWithInt:runMode]				forKey:@"runMode"];
    [objDictionary setObject:[NSNumber numberWithLong:hitRateEnabledMask]	forKey:@"hitRateEnabledMask"];
    [objDictionary setObject:[NSNumber numberWithLong:triggerEnabledMask]	forKey:@"triggerEnabledMask"];
    [objDictionary setObject:[NSNumber numberWithLong:postTriggerTime]		forKey:@"postTriggerTime"];
    [objDictionary setObject:[NSNumber numberWithLong:fifoBehaviour]		forKey:@"fifoBehaviour"];
    [objDictionary setObject:[NSNumber numberWithLong:analogOffset]			forKey:@"analogOffset"];
    [objDictionary setObject:[NSNumber numberWithLong:hitRateLength]		forKey:@"hitRateLength"];
    [objDictionary setObject:[NSNumber numberWithLong:gapLength]			forKey:@"gapLength"];
    [objDictionary setObject:[NSNumber numberWithLong:filterShapingLength]  forKey:@"filterShapingLength"];//this is the fpga register value -tb-
    [objDictionary setObject:[NSNumber numberWithInt:vetoOverlapTime]		forKey:@"vetoOverlapTime"];
    [objDictionary setObject:[NSNumber numberWithInt:nfoldCoincidence]		forKey:@"nfoldCoincidence"];
	
	//------------------
	//added MAH 11/09/11
	[objDictionary setObject:[NSNumber numberWithInt:histMeasTime]			forKey:@"histMeasTime"];
	[objDictionary setObject:[NSNumber numberWithInt:histEMin]				forKey:@"histEMin"];
	[objDictionary setObject:[NSNumber numberWithInt:shipSumHistogram]		forKey:@"shipSumHistogram"];
	[objDictionary setObject:[NSNumber numberWithInt:histMode]				forKey:@"histMode"];
	[objDictionary setObject:[NSNumber numberWithInt:histClrMode]			forKey:@"histClrMode"];
	[objDictionary setObject:[NSNumber numberWithInt:histEBin]				forKey:@"histEBin"];
	//------------------
	//added MAH 06/26/12	
	[objDictionary setObject:[NSNumber numberWithLong:[self readVersion]]				forKey:@"CFPGAFirmwareVersion"];
	[objDictionary setObject:[NSNumber numberWithLong:[self readpVersion]]				forKey:@"FPGA8FirmwareVersion"];
	//------------------
	//added -tb- 04/29/13	
	[objDictionary setObject:[NSNumber numberWithInt:boxcarLength]				forKey:@"BoxcarLength"];
	[objDictionary setObject:[NSNumber numberWithInt:useDmaBlockRead]		    forKey:@"UseDmaBlockRead"];//0=auto, 1=yes, 2=no
	[objDictionary setObject:[NSNumber numberWithInt:fifoLength]				forKey:@"FifoLength64"];
	//------------------
	
	return objDictionary;
}



// set the bit according to aChan in a channel map when received the according HW histogram (histogram mode);
// when all active channels sent the histogram, the histogram counter is incremented
// this way we can delay a subrun start until all histograms have been received   -tb-
- (BOOL) setFromDecodeStageReceivedHistoForChan:(short)aChan
{
    int map = receivedHistoChanMap;
    if(aChan>=0 && aChan<kNumV4FLTChannels){
		map |= 0x1<<aChan;
		[self setReceivedHistoChanMap:map];
		if(triggerEnabledMask == (map & triggerEnabledMask)){
		    //we got all histograms
            map=0;
			[self setReceivedHistoChanMap:map];
			[self setReceivedHistoCounter: receivedHistoCounter+1];
		}
	}
    return YES;
}

- (void) initSumHistogramBuffers
{
        //clear histogram buffers
        uint32_t crate = [self crateNumber];
        uint32_t station = [self stationNumber];
        int chan;
        for(chan=0; chan<kNumV4FLTChannels; chan++){
            if(triggerEnabledMask & (0x1<<chan)){//if this channel is active, clear histogram buffer(s)
                bzero(&(histoBuf[chan]), sizeof(katrinV4FltFullHistogramDataStruct));
                histoBuf[chan].orcaHeader = histogramId | (sizeof(katrinV4FltFullHistogramDataStruct)/sizeof(int32_t));
                histoBuf[chan].location =    ((crate & 0x01e)<<21) | (((station) & 0x1f)<<16) | ((boxcarLength & 0x3)<<4)  | (filterShapingLength & 0xf)      |    (chan<<8);
                histoBuf[chan].readoutSec      =  0;
                histoBuf[chan].refreshTimeSec  =  0;
                histoBuf[chan].firstBin        =  0;
                histoBuf[chan].lastBin         =   2047;
                histoBuf[chan].histogramLength =   2048;
                histoBuf[chan].maxHistogramLength =   2048;
                histoBuf[chan].binSize    =   histEBin;
                histoBuf[chan].offsetEMin =   histEMin;
				histoBuf[chan].histogramID    = 0;
				histoBuf[chan].histogramInfo  = 0x2;// bit1 means 'this is a sum histogram'
            }
        }
}


//2013: this is called from the decoder! -tb-
- (void) addToSumHistogram:(void*)someData
{

    if(!shipSumHistogram) return;
    
    unsigned long* ptr = (unsigned long*)someData;

	unsigned char chan = (ptr[1]>>8) & 0xff;
    
	katrinV4FltFullHistogramDataStruct* ePtr = (katrinV4FltFullHistogramDataStruct*) &ptr[2];
    
    uint32_t* histoData = ePtr->h;
    //ptr + (sizeof(katrinV4FltHistogramDataStruct)/sizeof(long));// points now to the histogram data -tb-
   	int isSumHistogram = ePtr->histogramInfo & 0x2; //the bit1 marks the Sum Histograms

    if(isSumHistogram){ //avoid adding the already shipped histograms
        return;
    }
    
    int i, firstBin = ePtr->firstBin;//first bin should always be 0 ... -tb-
    for(i=0; i<ePtr->histogramLength;i++){ 
        histoBuf[chan].h[firstBin+i] += histoData[i];
    }
    histoBuf[chan].refreshTimeSec += ePtr->refreshTimeSec;
    histoBuf[chan].readoutSec      =  ePtr->readoutSec;
}


- (void) shipSumHistograms
{
    if(shipSumHistogram){
    
        int chan;
        for(chan=0; chan<kNumV4FLTChannels; chan++){
            if(triggerEnabledMask & (0x1<<chan)){//if this channel is active, ship histogram, then clear
                //set the 'between subrun' flag
                if(isBetweenSubruns) histoBuf[chan].histogramInfo  |=  0x04; //set bit 2
                else                 histoBuf[chan].histogramInfo  &=  0xfffffffb; //set bit 2 so 0
                //ship
                [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:(void*)&(histoBuf[chan]) length:sizeof(katrinV4FltFullHistogramDataStruct)]];

                // ... TODO ...
                //clear histogram buffer
                histoBuf[chan].readoutSec      =  0;
                histoBuf[chan].refreshTimeSec  =  0;
                bzero(&(histoBuf[chan].h[0]), sizeof(uint32_t)*2048);
                /*
                histoBuf[chan].orcaHeader = histogramId | (sizeof(katrinV4FullHistogramDataStruct)/sizeof(int32_t));
                histoBuf[chan].location =    ((crate & 0x01e)<<21) | (((station) & 0x1f)<<16) | ((boxcarLength & 0x3)<<4)  | (filterShapingLength & 0xf)      |    (chan<<8);
                histoBuf[chan].firstBin =  0;
                histoBuf[chan].lastBin =   2048;
                histoBuf[chan].histogramLength =   2048;
                histoBuf[chan].maxHistogramLength =   2048;
                histoBuf[chan].binSize    =   histEBin;
                histoBuf[chan].offsetEMin =   histEMin;
                */
            }
        }
    }
}



- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(channel>=0 && channel<kNumV4FLTChannels){
		++eventCount[channel];
	}
    return YES;
}
- (BOOL) setFromDecodeStage:(short)aChan fifoFlags:(unsigned char)flags
{
    if(!activateDebuggingDisplays)return NO;
    
    if(aChan>=0 && aChan<kNumV4FLTChannels){
        [self setFifoFlags:aChan withValue:flags];
    }
    return YES;
}

- (unsigned char) fifoFlags:(short)aChan
{
    if(aChan>=0 && aChan<kNumV4FLTChannels){
        return fifoFlags[aChan];
    }
    else return 0;
}

- (NSString*) fifoFlagString:(short)aChan
{
	if(aChan>=0 && aChan<kNumV4FLTChannels){
		switch (fifoFlags[aChan]){
			case 0x8: return @"FF";
			case 0x4: return @"AF";
			case 0x2: return @"AE";
			case 0x1: return @"EF";
			default: return @" ";
		}
	}
	else return @" ";
}

- (void) setFifoFlags:(short)aChan withValue:(unsigned char)aValue
{
    if(aChan>=0 && aChan<kNumV4FLTChannels){
        fifoFlags[aChan] = aValue;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModeFifoFlagsChanged object:self userInfo:userInfo];
    }    
}


- (unsigned long) eventCount:(int)aChannel
{
    return eventCount[aChannel];
}

- (void) clearEventCounts
{
    int i;
    for(i=0;i<kNumV4FLTChannels;i++){
		eventCount[i]=0;
    }
}

//! Write 1 to all reset/clear flags of the FLTv4 command register.
- (void) reset 
{
	[self writeReg:kFLTV4CommandReg value:kIpeFlt_Reset_All];
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    
    if(histClrMode || histClrMode){
        NSLogColor([NSColor redColor],@"%@ WARNING: histogram readout is designed for continous and auto-clear mode only! Change your FLTv4 settings!\n",[self fullID]);
    }

    
    [self setIsPartOfRun: YES];

    //NOTE: during this function the whole crate is set to 'INHIBIT' by the SLT -tb-
	firstTime = YES;
	
    [self clearExceptionCount];
	[self clearEventCounts];
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORKatrinV4FLTModel"];    
    //----------------------------------------------------------------------------------------	
	
	//check which mode to use
	BOOL ratesEnabled = NO;
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		if([self hitRateEnabled:i]){
			ratesEnabled = YES;
			break;
		}
	}

    //TODO: see workaround in SLT: for hist mode: between standby and histo-mode there needs to be a second strobe 2013-05 -tb-
    //currently moved to SLT, as we need ONE second strobe wait for this workaround 
	//if(runMode == kKatrinV4Flt_Histogram_DaqMode){//FLTs in histogram mode always need to be set to standby mode (to restart the histogramming facility) -tb-
    //    [self writeControlWithStandbyMode];
	//}
    
    //if cold start (not 'quick start' in RunControl) ...
    [self setLedOff:NO];
    if([[userInfo objectForKey:@"doinit"]intValue]){
	    [self initBoard];           // writes control reg + hr control reg + PostTrigg + thresh+gains + offset + triggControl + hr mask + enab.statistics
	}
	
    [self reset];               // Write 1 to all reset/clear flags of the FLTv4 command register. (-> will 'clear' the event FIFO pointers)
    
	//moved 2013-04-29 to cold start section for non-histogram mode FLTs - see above  -tb- [self writeControl];

	if(![self useSLTtime])[self writeSeconds:0];//optionally write UTC/UNIX time of SLT (see SLT) -tb-

    //start timer functions for hitrate readout and/or histogram monitoring
	if(ratesEnabled){
        [self startReadingHitRates];
	}
		
	if(runMode == kKatrinV4Flt_Histogram_DaqMode){
        //clear histogram buffers
        [self initSumHistogramBuffers];
		//start polling histogramming mode status
		[self performSelector:@selector(readHistogrammingStatus) 
				   withObject:nil
				   afterDelay: 1];		//start reading out histogram timer and page toggle
	}
	
}


//**************************************************************************************
// Function:
// Description: Read data from a card. Should never call this method since the FLT
//
//***************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{	
	if(firstTime){
		firstTime = NO;
        NSLogColor([NSColor redColor],@"Readout List Error: FLT %d is NOT child of an SLT in the readout list\n",[self stationNumber]);
        NSLogColor([NSColor redColor],@"It will be ignored in this run\n");
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	//[self writeRunControl:NO];// let it run, see runTaskStarted ... -tb-
	//changed 2013-04-29 -tb- SLT will set inhibit anyway! for quick start we want to leave the current mode active (histogr. FLTs are restarted at runTaskStarted) [self writeControlWithStandbyMode];
	[self setLedOff:YES];
    if(hitRateMode == kKatrinV4HitRunRateWithRun){
        [self stopReadingHitRates];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHistogrammingStatus) object:nil];

	[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelHitRateChanged object:self];

    [self setIsPartOfRun: NO];

}

#pragma mark •••SBC readout control structure... Till, fill out as needed
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
    uint32_t versionCFPGA = [self readVersion];
    uint32_t versionFPGA8 = [self readpVersion];

    configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kFLTv4;					//unique identifier for readout hw
	configStruct->card_info[index].hw_mask[0] 	= dataId;					//record id for energies
	configStruct->card_info[index].hw_mask[1] 	= waveFormId;				//record id for the waveforms
	configStruct->card_info[index].hw_mask[2] 	= histogramId;				//record id for the histograms
	configStruct->card_info[index].slot			= [self stationNumber];		//PMC readout (fdhwlib) uses col 0->n-1; stationNumber is from 1->n (FLT register entry SlotID too)
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].deviceSpecificData[0] = postTriggerTime;	//needed to align the waveforms
	unsigned long eventTypeMask = 0;
	if(readWaveforms) eventTypeMask |= kReadWaveForms;
	configStruct->card_info[index].deviceSpecificData[1] = eventTypeMask;	
	configStruct->card_info[index].deviceSpecificData[2] = fltRunMode;	
	unsigned long runFlagsMask = 0;                                         //bit 16 = "first time" flag
    if(runMode == kKatrinV4Flt_EnergyDaqMode | runMode == kKatrinV4Flt_EnergyTraceDaqMode)
        runFlagsMask |= kSyncFltWithSltTimerFlag;                           //bit 17 = "sync flt with slt timer" flag
    if((shipSumHistogram == 1) && (!syncWithRunControl)) runFlagsMask |= kShipSumHistogramFlag;//bit 18 = "ship sum histogram" flag   //2013-06 added (!syncWithRunControl) - if syncWithRunControl is set, this 'facility' will produce sum histograms (using the decoder) -tb-
    if(forceFLTReadout || (runMode == kKatrinV4Flt_EnergyTraceDaqMode)){
        runFlagsMask |= kForceFltReadoutFlag;      
    }
    
	configStruct->card_info[index].deviceSpecificData[3] = runFlagsMask;	
	configStruct->card_info[index].deviceSpecificData[4] = triggerEnabledMask;
    configStruct->card_info[index].deviceSpecificData[5] = runMode;			//the daqRunMode
	if(versionCFPGA==0x1f000000){                                           //card not readable; assume simulation mode and assume KATRIN card -tb-
		versionCFPGA=0x20010200; versionFPGA8=0x20010203;
		NSLog(@"MESSAGE: are you in simulation mode? Assume firmware CFPGA,FPGA8:0x%8x,0x%8x: OK.\n",versionCFPGA,versionFPGA8);
	}
	if((versionCFPGA>0x20010100 && versionCFPGA<0x20010200) || (versionFPGA8>0x20010100  && versionFPGA8<0x20010103) ){
		NSLog(@"WARNING: you are using an old firmware (version CFPGA,FPGA8:0x%8x,0x%8x). Update! (See: http://fuzzy.fzk.de/ipedaq)\n",versionCFPGA,versionFPGA8);
	}
	configStruct->card_info[index].deviceSpecificData[7]  = versionCFPGA;               //CFPGA version 0xPDDDVVRR //P=project, D=doc revision
	configStruct->card_info[index].deviceSpecificData[8]  = versionFPGA8;               //FPGA8 version 0xPDDDVVRR //V=version, R=revision
	configStruct->card_info[index].deviceSpecificData[9]  = [self filterShapingLength];	//replaces filterLength -tb- 2011-04
	configStruct->card_info[index].deviceSpecificData[10] = [self useDmaBlockRead];		//enables DMA access //TODO: - no plausibility checks yet!!! -tb- 2012-03
	configStruct->card_info[index].deviceSpecificData[11] = [self boxcarLength];
    
	configStruct->card_info[index].num_Trigger_Indexes = 0;                             //we can't have children
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
    return kNumV4FLTChannels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Run Mode"];
    [p setFormat:@"##0" upperLimit:2 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setRunMode:) getMethod:@selector(runMode)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0xfffff lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gain"];
    [p setFormat:@"##0" upperLimit:0xfff lowerLimit:0 stepSize:1 units:@"raw"];
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
    [p setName:@"Post Trigger Delay"];
    [p setFormat:@"##0" upperLimit:2046 lowerLimit:0 stepSize:1 units:@"x50ns"];
    [p setSetMethod:@selector(setPostTriggerTime:) getMethod:@selector(postTriggerTime)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Fifo Behavior"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setFifoBehaviour:) getMethod:@selector(fifoBehaviour)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Analog Offset"];
    [p setFormat:@"##0" upperLimit:4095 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setAnalogOffset:) getMethod:@selector(analogOffset)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Hit Rate Length"];
    [p setFormat:@"##0" upperLimit:6 lowerLimit:0 stepSize:1 units:@"index"];
    [p setSetMethod:@selector(setHitRateLength:) getMethod:@selector(hitRateLength)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gap Length"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@"index"];//TODO: change it/add new class field! -tb-
    [p setSetMethod:@selector(setGapLength:) getMethod:@selector(gapLength)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Filter Shaping Length"];
    [p setFormat:@"##0" upperLimit:8 lowerLimit:2 stepSize:1 units:@""];
    [p setSetMethod:@selector(setFilterShapingLength:) getMethod:@selector(filterShapingLength)];
    [a addObject:p];			

	//----------------
	//added MAH 11/09/10
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Refresh Time"];
    [p setFormat:@"##0" upperLimit:60 lowerLimit:1 stepSize:1 units:@"s"];
    [p setSetMethod:@selector(setHistMeasTime:) getMethod:@selector(histMeasTime)];
    [a addObject:p];			

	//wasn't sure about the max value in this one....
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Energy Offset"];
    [p setFormat:@"##0" upperLimit:16777215. lowerLimit:0 stepSize:1 units:@"2^n"];
    [p setSetMethod:@selector(setHistEMin:) getMethod:@selector(histEMin)];
    [a addObject:p];			
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Bin Width"];
    [p setFormat:@"##0" upperLimit:15 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setHistEBin:) getMethod:@selector(histEBin)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Ship Sum Histo"];
    [p setFormat:@"##0" upperLimit:2 lowerLimit:0 stepSize:1 units:@"index"];
    [p setSetMethod:@selector(setShipSumHistogram:) getMethod:@selector(shipSumHistogram)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Histo Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"index"];
    [p setSetMethod:@selector(setHistMode:) getMethod:@selector(histMode)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Histo Clr Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"index"];
    [p setSetMethod:@selector(setHistClrMode:) getMethod:@selector(histClrMode)];
    [a addObject:p];			
	//----------------
	
	
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
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"ORKatrinV4FLTModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORKatrinV4FLTModel"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Threshold"])				return  [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Gain"])				return [[cardDictionary objectForKey:@"gains"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Trigger Enabled"])		return [[cardDictionary objectForKey:@"triggersEnabled"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"HitRate Enabled"])		return [[cardDictionary objectForKey:@"hitRatesEnabled"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Post Trigger Time"])	return [cardDictionary objectForKey:@"postTriggerTime"];
    else if([param isEqualToString:@"Run Mode"])			return [cardDictionary objectForKey:@"runMode"];
    else if([param isEqualToString:@"Fifo Behaviour"])		return [cardDictionary objectForKey:@"fifoBehaviour"];
    else if([param isEqualToString:@"Analog Offset"])		return [cardDictionary objectForKey:@"analogOffset"];
    else if([param isEqualToString:@"Hit Rate Length"])		return [cardDictionary objectForKey:@"hitRateLength"];
    else if([param isEqualToString:@"Gap Length"])			return [cardDictionary objectForKey:@"gapLength"];
    else if([param isEqualToString:@"Filter Shaping Length"])		return [cardDictionary objectForKey:@"filterShapingLength"];
	
	//------------------
	//added MAH 11/09/11
    else if([param isEqualToString:@"Refresh Time"])		return [cardDictionary objectForKey:@"histMeasTime"];
    else if([param isEqualToString:@"Energy Offset"])		return [cardDictionary objectForKey:@"histEMin"];
    else if([param isEqualToString:@"Bin Width"])			return [cardDictionary objectForKey:@"histEBin"];
    else if([param isEqualToString:@"Ship Sum Histo"])		return [cardDictionary objectForKey:@"sumHistogram"];
    else if([param isEqualToString:@"Histo Mode"])			return [cardDictionary objectForKey:@"histMode"];
    else if([param isEqualToString:@"Histo Clr Mode"])		return [cardDictionary objectForKey:@"histClrMode"];
	//------------------
	
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
- (void) testReadHisto
{
	unsigned long hControl = [self readReg:kFLTV4HistgrSettingsReg];
	unsigned long pStatusA = [self readReg:kFLTV4pStatusAReg];
	unsigned long pStatusB = [self readReg:kFLTV4pStatusBReg];
	unsigned long pStatusC = [self readReg:kFLTV4pStatusCReg];
	unsigned long f3	   = [self readReg:kFLTV4HistNumMeasReg];
	NSLog(@"EMin: 0x%08x\n",  hControl & 0x7FFFF);
	NSLog(@"EBin: 0x%08x\n",  (hControl>>20) & 0xF);
	NSLog(@"HM: %d\n",  (hControl>>28) & 0x1);
	NSLog(@"CM: %d\n",  (hControl>>29) & 0x1);
	NSLog(@"page Changes: 0x%08x\n",  f3 & 0x3F);
	NSLog(@"A: 0x%08x fid:%d hPg:%i\n", (pStatusA>>12) & 0xFF, pStatusA>>28, (pStatusA&0x10)>>4);
	NSLog(@"B: 0x%08x fid:%d hPg:%i\n", (pStatusB>>12) & 0xFF, pStatusB>>28, (pStatusB&0x10)>>4);
	NSLog(@"C: 0x%08x fid:%d hPg:%i\n", (pStatusC>>12) & 0xFF, pStatusC>>28, (pStatusC&0x10)>>4);
	NSLog(@"Meas Time: 0x%08x\n", [self readReg:kFLTV4HistMeasTimeReg]);
	NSLog(@"Rec Time : 0x%08x\n", [self readReg:kFLTV4HistRecTimeReg]);
	NSLog(@"Page Number : 0x%08x\n", [self readReg:kFLTV4HistPageNReg]);
	
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		unsigned long firstLast = [self readReg:kFLTV4HistLastFirstReg channel:i];
		unsigned long first = firstLast & 0xffff;
		unsigned long last = (firstLast >>16) & 0xffff;
		NSLog(@"%d: 0x%08x 0x%08x\n",i,first, last);
	}


}

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
		unsigned long channelMap = (eventFifo1>>10)&0xfffff;
		NSLog(@"Channel Map: 0x%0x\n",channelMap);
		
		unsigned long eventFifo2 = [self readReg: kFLTV4EventFifo2Reg];
		unsigned long sec =  ((eventFifo1&0x3ff)<<5) | ((eventFifo2>>27)&0x1f);
		NSLog(@"sec: %d %d\n",((eventFifo2>>27)&0x1f),eventFifo1&0x3ff);
		NSLog(@"Time: %d\n",sec);
		
		int i;
		for(i=0;i<kNumV4FLTChannels;i++){
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
	unsigned long pAData = [self readReg:kFLTV4pStatusAReg];
	unsigned long pBData = [self readReg:kFLTV4pStatusBReg];
	unsigned long pCData = [self readReg:kFLTV4pStatusCReg];
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
    //uint32_t versionCFPGA;
    //uint32_t versionFPGA8;
	data = [self readVersion];
	if(0x1f000000 == data){
		NSLogColor([NSColor redColor],@"FLTv4: Could not access hardware, no version register read!\n");
		return;
	}
	//versionCFPGA=data;
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"%@ versions:\n",[self fullID]);
	NSLogFont(aFont,@"CFPGA Version %u.%u.%u.%u\n",((data>>28)&0xf),((data>>16)&0xfff),((data>>8)&0xff),((data>>0)&0xff));
	data = [self readpVersion];
	NSLogFont(aFont,@"FPGA8 Version %u.%u.%u.%u\n",((data>>28)&0xf),((data>>16)&0xfff),((data>>8)&0xff),((data>>0)&0xff));
	//versionFPGA8=data;


	switch ( ((data>>28)&0xf) ) {
		case 1: //AUGER
			NSLogFont(aFont,@"    This is a Auger FLTv4 firmware configuration! (WARNING: You are using a KATRIN V4 FLT object!)\n");
			break;
		case 2: //KATRIN
			NSLogFont(aFont,@"    This is a KATRIN FLTv4 firmware configuration!\n");
			break;
		default:
			NSLogFont(aFont,@"    This is a Unknown FLTv4 firmware configuration!\n");
			break;
	}
	//NSLog(@"CFPGA,FPGA8:%8x,%8x\n",versionCFPGA,versionFPGA8);

	//print fdhwlib and readout code versions
	ORIpeV4SLTModel* slt = [[self crate] adapter];
	long fdhwlibVersion = [slt getFdhwlibVersion];
	int ver=(fdhwlibVersion>>16) & 0xff,maj =(fdhwlibVersion>>8) & 0xff,min = fdhwlibVersion & 0xff;
	//NSLogFont(aFont,@"%@ fdhwlib Library version: 0x%08x / %i.%i.%i\n",[self fullID], fdhwlibVersion,ver,maj,min);
	NSLogFont(aFont,@"SBC PrPMC running with fdhwlib version: %i.%i.%i (0x%08x)\n",ver,maj,min, fdhwlibVersion);
	NSLogFont(aFont,@"SBC PrPMC readout code version: %i \n", [slt getSBCCodeVersion]);
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
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,   @"chan | HitRate  | Gain | Threshold\n");
	NSLogFont(aFont,   @"----------------------------------\n");
	unsigned long aHitRateMask = [self readHitRateMask];

	//grab all the thresholds and gains using one command packet
	int i;
	ORCommandList* aList = [ORCommandList commandList];
	for(i=0;i<kNumV4FLTChannels;i++){
		[aList addCommand: [self readRegCmd:kFLTV4GainReg channel:i]];
		[aList addCommand: [self readRegCmd:kFLTV4ThresholdReg channel:i]];
	}
	
	[self executeCommandList:aList];
	
	for(i=0;i<kNumV4FLTChannels;i++){
		NSLogFont(aFont,@"%4d | %@ | %4d | %4d \n",i,(aHitRateMask>>i)&0x1 ? @" Enabled":@"Disabled",[aList longValueForCmd:i*2],[aList longValueForCmd:1+i*2]);
	}
	NSLogFont(aFont,   @"---------------------------------\n");
}

- (void) findNoiseFloors
{
	if(noiseFloorRunning){
		noiseFloorRunning = NO;
	}
	else {
		noiseFloorState = 0;
		noiseFloorRunning = YES;
		[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:0];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTNoiseFloorChanged object:self];
}

- (NSString*) noiseFloorStateString
{
	if(!noiseFloorRunning) return @"Idle";
	else switch(noiseFloorState){
		case 0: return @"Initializing"; 
		case 1: return @"Setting Thresholds";
		case 2: return @"Integrating";
		case 3: return @"Finishing";
		default: return @"?";
	}	
}
- (NSString*) getRegisterName: (short) anIndex
{
    return [[ORKatrinV4FLTRegisters sharedRegSet] registerName:anIndex];
}

- (unsigned long) getAddressOffset: (short) anIndex
{
    return [[ORKatrinV4FLTRegisters sharedRegSet] addressOffset:anIndex];
}

- (short) getAccessType: (short) anIndex
{
    return [[ORKatrinV4FLTRegisters sharedRegSet] accessType:anIndex];
}
@end

@implementation ORKatrinV4FLTModel (tests)
#pragma mark •••Accessors
- (BOOL) testsRunning { return testsRunning; }
- (void) setTestsRunning:(BOOL)aTestsRunning
{
    testsRunning = aTestsRunning;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelTestsRunningChanged object:self];
}

- (NSMutableArray*) testEnabledArray { return testEnabledArray; }
- (void) setTestEnabledArray:(NSMutableArray*)aTestEnabledArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestEnabledArray:testEnabledArray];
    
    [aTestEnabledArray retain];
    [testEnabledArray release];
    testEnabledArray = aTestEnabledArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelTestEnabledArrayChanged object:self];
}

- (NSMutableArray*) testStatusArray { return testStatusArray; }
- (void) setTestStatusArray:(NSMutableArray*)aTestStatusArray
{
    [aTestStatusArray retain];
    [testStatusArray release];
    testStatusArray = aTestStatusArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelTestStatusArrayChanged object:self];
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
			for(i=0;i<kNumKatrinV4FLTTests;i++){
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTModelTestStatusArrayChanged object:self];
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
				[self writeControl];
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
			for(chan=0;chan<kNumV4FLTChannels;chan++){
				[self writeThreshold:chan value:thePattern];
			}
			
			for(chan=0;chan<kNumV4FLTChannels;chan++){
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
				for(chan=0;chan<kNumV4FLTChannels;chan++){
					[self writeGain:chan value:thePattern];
				}
				
				for(chan=0;chan<kNumV4FLTChannels;chan++){
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
				[self writeReg:kFLTV4AnalogOffsetReg value:thePattern];
				unsigned short theValue = [self readReg:kFLTV4AnalogOffsetReg];
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
	ORTimer* aTimer = [[ORTimer alloc] init];
	[aTimer start];
	
	@try {
		BOOL passed = YES;
		int numLoops = 250;
		int numPatterns = 4;
		int j;
		for(j=0;j<numLoops;j++){
			unsigned long aPattern[4] = {0xfffffff,0x00000000,0xaaaaaaaa,0x55555555};
			int i;
			for(i=0;i<numPatterns;i++){
				[self writeReg:kFLTV4AccessTestReg value:aPattern[i]];
				unsigned long aValue = [self readReg:kFLTV4AccessTestReg];
				if(aValue!=aPattern[i]){
					NSLog(@"Error: Comm Check (pattern: 0x%0x!=0x%0x) FLT %d does not work\n",aPattern,aValue,[self stationNumber]);
					passed = NO;				
				}
			}
			if(!passed)break;
		}
		[aTimer stop];
		if(passed){
			int totalOps = numLoops*numPatterns*2;
			double secs = [aTimer seconds];
			[self test:testNumber result:[NSString stringWithFormat:@"%.2f/s",totalOps/secs] color:[NSColor passedColor]];
			NSLog(@"Speed Test For FLT %d : %d accesses in %.3f sec\n",[self stationNumber], totalOps,secs);
		}
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}	
	@finally {
		[aTimer release];
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
	unsigned int i, j;
	
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

@implementation ORKatrinV4FLTModel (private)

- (void) stepNoiseFloor
{
	[[self undoManager] disableUndoRegistration];
	int i;
	BOOL atLeastOne;
	unsigned long maxThreshold = 0xfffff;
    @try {
		switch(noiseFloorState){
			case 0:
				//disable all channels
				for(i=0;i<kNumV4FLTChannels;i++){
					oldEnabled[i]   = [self hitRateEnabled:i];
					oldThreshold[i] = [self threshold:i];
					[self setThreshold:i withValue:maxThreshold];
					newThreshold[i] = maxThreshold;
				}
				atLeastOne = NO;
				for(i=0;i<kNumV4FLTChannels;i++){
					if(oldEnabled[i]){
						noiseFloorLow[i]			= 0;
						noiseFloorHigh[i]		= maxThreshold;
						noiseFloorTestValue[i]	= maxThreshold/2;              //Initial probe position
						[self setThreshold:i withValue:noiseFloorHigh[i]];
						atLeastOne = YES;
					}
				}
				
				[self initBoard];
				[self writeControl];
				
				if(atLeastOne)	noiseFloorState = 1;
				else			noiseFloorState = 4; //nothing to do
			break;
				
			case 1:
				for(i=0;i<kNumV4FLTChannels;i++){
					if([self hitRateEnabled:i]){
						if(noiseFloorLow[i] <= noiseFloorHigh[i]) {
							[self setThreshold:i withValue:noiseFloorTestValue[i]];
							
						}
						else {
							newThreshold[i] = MAX(0,noiseFloorTestValue[i] + noiseFloorOffset);
							[self setThreshold:i withValue:maxThreshold];
							hitRateEnabledMask &= ~(1L<<i);
						}
					}
				}
				[self initBoard];
				[self writeControl];
				
				if(hitRateEnabledMask)	noiseFloorState = 2;	//go check for data
				else					noiseFloorState = 3;	//done
			break;
				
			case 2:
				//read the hitrates
				[self readHitRates];
				
				for(i=0;i<kNumV4FLTChannels;i++){
					if([self hitRateEnabled:i]){
						if([self hitRate:i] > targetRate){
							//the rate is too high, bump the threshold up
							[self setThreshold:i withValue:maxThreshold];
							noiseFloorLow[i] = noiseFloorTestValue[i] + 1;
						}
						else noiseFloorHigh[i] = noiseFloorTestValue[i] - 1;									//no data so continue lowering threshold
						noiseFloorTestValue[i] = noiseFloorLow[i]+((noiseFloorHigh[i]-noiseFloorLow[i])/2);     //Next probe position.
					}
				}
				
				[self initBoard];
				[self writeControl];
				
				noiseFloorState = 1;
				break;
								
			case 3: //finish up	
				//load new results
				for(i=0;i<kNumV4FLTChannels;i++){
					[self setHitRateEnabled:i withValue:oldEnabled[i]];
					[self setThreshold:i withValue:newThreshold[i]];
				}
				[self initBoard];
				[self writeControl];
				noiseFloorRunning = NO;
			break;
		}
		if(noiseFloorRunning){
			float timeToWait;
			if(noiseFloorState==2)	timeToWait = pow(2.,hitRateLength)* 1.5;
			else					timeToWait = 0.2;
			[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:timeToWait];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4FLTNoiseFloorChanged object:self];
    }
	@catch(NSException* localException) {
        int i;
        for(i=0;i<kNumV4FLTChannels;i++){
            [self setHitRateEnabled:i withValue:oldEnabled[i]];
            [self setThreshold:i withValue:oldThreshold[i]];
			//[self reset];
			[self initBoard];
			[self writeControl];
        }
		NSLog(@"FLT4 LED threshold finder quit because of exception\n");
    }
	[[self undoManager] enableUndoRegistration];
}


- (NSAttributedString*) test:(int)testIndex result:(NSString*)result color:(NSColor*)aColor
{
	NSLogColor(aColor,@"%@ test %@\n",fltTestName[testIndex],result);
	id theString = [[NSAttributedString alloc] initWithString:result 
												   attributes:[NSDictionary dictionaryWithObject: aColor forKey:NSForegroundColorAttributeName]];
	
	[self runningTest:testIndex status:theString];
	return [theString autorelease];
}

- (void) enterTestMode  //TODO: test tab deactivated for KATRIN v4; needs redesign 2010-08-02 -tb-
{
	//put into test mode
	savedMode = fltRunMode;
	fltRunMode = kKatrinV4FLT_StandBy_Mode; //TODO: test mode has changed for V4 -tb- kKatrinV4FLT_Test_Mode;
	[self writeControl];
	//if([self readMode] != kKatrinV4FLT_Test_Mode){
	if(1){//TODO: test mode has changed for V4 -tb-
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
