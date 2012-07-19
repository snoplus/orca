//
//  ORKatrinV4FLTController.m
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

#pragma mark •••Imported Files
#import "ORKatrinV4FLTController.h"
#import "ORKatrinV4FLTModel.h"
#import "ORKatrinV4FLTDefs.h"
#import "SLTv4_HW_Definitions.h"
#import "ORFireWireInterface.h"
#import "ORPlotView.h"
#import "ORValueBarGroupView.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"
#import "ORTimeLinePlot.h"

@implementation ORKatrinV4FLTController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"KatrinV4FLT"];
    
    return self;
}

#pragma mark •••Initialization
- (void) dealloc
{
	[rateFormatter release];
	[blankView release];
    [super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	//TODO: DEBUG-REMOVE - -tb-
	//[[filterShapingLengthPU itemAtIndex:0] setHidden: YES];//TODO: remove this line to enable 100 nsec filter shaping length setting -tb-
	//[[filterShapingLengthPU itemAtIndex:0] setEnabled: NO];//TODO: remove this line to enable 100 nsec filter shaping length setting -tb-
	
    settingSize			= NSMakeSize(670,720);
    rateSize			= NSMakeSize(500,690);
    testSize			= NSMakeSize(610,510);
    lowlevelSize		= NSMakeSize(610,510);
	
	rateFormatter = [[NSNumberFormatter alloc] init];
	[rateFormatter setFormat:@"##0.00"];
	[totalHitRateField setFormatter:rateFormatter];
	[rateTextFields setFormatter:rateFormatter];
    blankView = [[NSView alloc] init];
    
    NSString* key = [NSString stringWithFormat: @"orca.ORKatrinV4FLT%d.selectedtab",[model stationNumber]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];

	[rate0 setNumber:24 height:10 spacing:6];

	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		[[fifoDisplayMatrix cellAtRow:i column:0] setTag:i];
	}
	[self populatePullDown];
	[self updateWindow];

}

#pragma mark •••Accessors

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORKatrinV4FLTSettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORIpeCardSlotChangedNotification
					   object : model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(modeChanged:)
                         name : ORKatrinV4FLTModelModeChanged
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(thresholdChanged:)
						 name : ORKatrinV4FLTModelThresholdChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(gainChanged:)
						 name : ORKatrinV4FLTModelGainChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(triggerEnabledChanged:)
						 name : ORKatrinV4FLTModelTriggerEnabledMaskChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(hitRateEnabledChanged:)
						 name : ORKatrinV4FLTModelHitRateEnabledMaskChanged
					   object : model];
		
	
    [notifyCenter addObserver : self
					 selector : @selector(gainArrayChanged:)
						 name : ORKatrinV4FLTModelGainsChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(thresholdArrayChanged:)
						 name : ORKatrinV4FLTModelThresholdsChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(hitRateLengthChanged:)
						 name : ORKatrinV4FLTModelHitRateLengthChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(hitRateChanged:)
						 name : ORKatrinV4FLTModelHitRateChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateAverageChangedNotification
					   object : [model totalRate]];
	
    [notifyCenter addObserver : self
                     selector : @selector(testEnabledArrayChanged:)
                         name : ORKatrinV4FLTModelTestEnabledArrayChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(testStatusArrayChanged:)
                         name : ORKatrinV4FLTModelTestStatusArrayChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORKatrinV4FLTModelTestsRunningChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(interruptMaskChanged:)
                         name : ORKatrinV4FLTModelInterruptMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(analogOffsetChanged:)
                         name : ORKatrinV4FLTModelAnalogOffsetChanged
						object: model];
		
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : ORKatrinV4FLTSelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : ORKatrinV4FLTWriteValueChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(selectedChannelValueChanged:)
						 name : ORKatrinV4FLTSelectedChannelValueChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(fifoBehaviourChanged:)
                         name : ORKatrinV4FLTModelFifoBehaviourChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(postTriggerTimeChanged:)
                         name : ORKatrinV4FLTModelPostTriggerTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histRecTimeChanged:)
                         name : ORKatrinV4FLTModelHistRecTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histMeasTimeChanged:)
                         name : ORKatrinV4FLTModelHistMeasTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histNofMeasChanged:)
                         name : ORKatrinV4FLTModelHistNofMeasChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(gapLengthChanged:)
                         name : ORKatrinV4FLTModelGapLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(filterShapingLengthChanged:)
                         name : ORKatrinV4FLTModelFilterShapingLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(storeDataInRamChanged:)
                         name : ORKatrinV4FLTModelStoreDataInRamChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histEMinChanged:)
                         name : ORKatrinV4FLTModelHistEMinChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histEBinChanged:)
                         name : ORKatrinV4FLTModelHistEBinChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histModeChanged:)
                         name : ORKatrinV4FLTModelHistModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histClrModeChanged:)
                         name : ORKatrinV4FLTModelHistClrModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histFirstEntryChanged:)
                         name : ORKatrinV4FLTModelHistFirstEntryChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histLastEntryChanged:)
                         name : ORKatrinV4FLTModelHistLastEntryChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorChanged:)
                         name : ORKatrinV4FLTNoiseFloorChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorOffsetChanged:)
                         name : ORKatrinV4FLTNoiseFloorOffsetChanged
                       object : model];
    [notifyCenter addObserver : self
                     selector : @selector(histPageABChanged:)
                         name : ORKatrinV4FLTModelHistPageABChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histMaxEnergyChanged:)
                         name : ORKatrinV4FLTModelHistMaxEnergyChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(targetRateChanged:)
                         name : ORKatrinV4FLTModelTargetRateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(shipSumHistogramChanged:)
                         name : ORKatrinV4FLTModelShipSumHistogramChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(vetoOverlapTimeChanged:)
                         name : ORKatrinV4FLTModelVetoOverlapTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(nfoldCoincidenceChanged:)
                         name : ORKatrinV4FLTModelNfoldCoincidenceChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fifoLengthChanged:)
                         name : ORKatrinV4FLTModelFifoLengthChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(activateDebuggerDisplaysChanged:)
                         name : ORKatrinV4FLTModelActivateDebuggingDisplaysChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(fifoFlagsChanged:)
                         name : ORKatrinV4FLTModeFifoFlagsChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(receivedHistoChanMapChanged:)
                         name : ORKatrinV4FLTModelReceivedHistoChanMapChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(receivedHistoCounterChanged:)
                         name : ORKatrinV4FLTModelReceivedHistoCounterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(customVariableChanged:)
                         name : ORKatrinV4FLTModelCustomVariableChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(poleZeroCorrectionChanged:)
                         name : ORKatrinV4FLTModelPoleZeroCorrectionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(decayTimeChanged:)
                         name : ORKatrinV4FLTModelDecayTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(syncWithRunControlChanged:)
                         name : ORKatrinV4FLTModelSyncWithRunControlChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useDmaBlockReadChanged:)
                         name : ORKatrinV4FLTModelUseDmaBlockReadChanged
						object: model];

}

#pragma mark •••Interface Management

- (void) useDmaBlockReadChanged:(NSNotification*)aNote
{
	[useDmaBlockReadButton setIntValue: [model useDmaBlockRead]];
}

- (void) syncWithRunControlChanged:(NSNotification*)aNote
{
	[syncWithRunControlButton setIntValue: [model syncWithRunControl]];
}

- (void) recommendedPZCChanged:(NSNotification*)aNote
{
    double att = [model poleZeroCorrectionHint];
	[recommendedPZCTextField setStringValue: [NSString stringWithFormat:@"%.3f -> %i",att,[model poleZeroCorrectionSettingHint:att]]];
}

- (void) decayTimeChanged:(NSNotification*)aNote
{
	[decayTimeTextField setDoubleValue: [model decayTime]];
	[self recommendedPZCChanged:nil];
}

- (void) poleZeroCorrectionChanged:(NSNotification*)aNote
{
	[poleZeroCorrectionPU selectItemAtIndex: [model poleZeroCorrection]];
}

- (void) customVariableChanged:(NSNotification*)aNote
{
	[customVariableTextField setIntValue: [model customVariable]];
}

- (void) receivedHistoCounterChanged:(NSNotification*)aNote
{
	[receivedHistoCounterTextField setIntValue: [model receivedHistoCounter]];
}

- (void) receivedHistoChanMapChanged:(NSNotification*)aNote
{
	[receivedHistoChanMapTextField setIntValue: [model receivedHistoChanMap]];
}
- (void) activateDebuggerDisplaysChanged:(NSNotification*)aNote
{
	[activateDebuggerCB setIntValue: [model activateDebuggingDisplays]];
	[fifoDisplayMatrix setHidden: ![model activateDebuggingDisplays]];
}
- (void) fifoLengthChanged:(NSNotification*)aNote
{
	//NSLog(@"%@::%@: fifoLength is %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[model fifoLength]);//-tb-NSLog-tb-
	[fifoLengthPU selectItemAtIndex: [model fifoLength]];
}

- (void) nfoldCoincidenceChanged:(NSNotification*)aNote
{
	[nfoldCoincidencePU selectItemAtIndex: [model nfoldCoincidence]];
	NSString* s = [NSString stringWithFormat:@">=%d",[model nfoldCoincidence]];
	[group1NFoldField setStringValue:s];
	[group2NFoldField setStringValue:s];
	[group3NFoldField setStringValue:s];
}

- (void) vetoOverlapTimeChanged:(NSNotification*)aNote
{
	[vetoOverlapTimePU selectItemAtIndex: [model vetoOverlapTime]];
}

- (void) shipSumHistogramChanged:(NSNotification*)aNote
{
	[shipSumHistogramPU selectItemWithTag: [model shipSumHistogram]];
}

- (void) targetRateChanged:(NSNotification*)aNote
{
	[targetRateField setIntValue: [model targetRate]];
}

- (void) histMaxEnergyChanged:(NSNotification*)aNote
{
	[histMaxEnergyTextField setIntValue: [model histMaxEnergy]];
}

- (void) histPageABChanged:(NSNotification*)aNote
{
	[histPageABTextField setStringValue: [model histPageAB]?@"B":@"A"];
	//[histPageABTextField setIntValue: [model histPageAB]];
}
- (void) histLastEntryChanged:(NSNotification*)aNote
{
	[histLastEntryField setIntValue: [model histLastEntry]];
}

- (void) histFirstEntryChanged:(NSNotification*)aNote
{
	[histFirstEntryField setIntValue: [model histFirstEntry]];
}

- (void) histClrModeChanged:(NSNotification*)aNote
{
	[histClrModePU selectItemAtIndex: [model histClrMode]];
}

- (void) histModeChanged:(NSNotification*)aNote
{
	[histModePU selectItemAtIndex: [model histMode]];
}

- (void) histEBinChanged:(NSNotification*)aNote
{
	[histEBinPU selectItemAtIndex: [model histEBin]];
}

- (void) histEMinChanged:(NSNotification*)aNote
{
	[histEMinTextField setIntValue: [model histEMin]];
}

- (void) storeDataInRamChanged:(NSNotification*)aNote
{
	[storeDataInRamCB setIntValue: [model storeDataInRam]];
}

- (void) filterShapingLengthChanged:(NSNotification*)aNote
{
	//[filterLengthPU selectItemAtIndex:[model filterLength]];
	[filterShapingLengthPU selectItemWithTag:[model filterShapingLength]];
	[self recommendedPZCChanged:nil];
}

- (void) gapLengthChanged:(NSNotification*)aNote
{
	[gapLengthPU selectItemAtIndex: [model gapLength]];
}

- (void) histNofMeasChanged:(NSNotification*)aNote
{
	[histNofMeasField setIntValue: [model histNofMeas]];
}

- (void) histMeasTimeChanged:(NSNotification*)aNote
{
	[histMeasTimeField setIntValue: [model histMeasTime]];
}

- (void) histRecTimeChanged:(NSNotification*)aNote
{
	[histRecTimeField setIntValue: [model histRecTime]];
}

- (void) postTriggerTimeChanged:(NSNotification*)aNote
{
	[postTriggerTimeField setIntValue: [model postTriggerTime]];
}

- (void) fifoBehaviourChanged:(NSNotification*)aNote
{
	[fifoBehaviourMatrix selectCellWithTag: [model fifoBehaviour]];
}

- (void) analogOffsetChanged:(NSNotification*)aNote
{
	[analogOffsetField setIntValue: [model analogOffset]];
}

- (void) interruptMaskChanged:(NSNotification*)aNote
{
	[interruptMaskField setIntValue: [model interruptMask]];
}

- (void) populatePullDown
{
    short	i;
	
	// Clear all the popup items.
    [registerPopUp removeAllItems];
    
	// Populate the register popup
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerPopUp insertItemWithTitle:[model getRegisterName:i] atIndex:i];
    }
    
    
	// Clear all the popup items.
    [channelPopUp removeAllItems];
    
	// Populate the register popup
	for(i=0;i<kNumV4FLTChannels;i++){
        [channelPopUp insertItemWithTitle: [NSString stringWithFormat: @"%i",i+1 ] atIndex:i];
        [[channelPopUp itemAtIndex:i] setTag: i];
    }
    [channelPopUp insertItemWithTitle: @"All" atIndex:i];
    [[channelPopUp itemAtIndex:i] setTag: 0x1f];// chan 31 = broadcast to all channels
}

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
	[self modeChanged:nil];
	[self gainArrayChanged:nil];
	[self thresholdArrayChanged:nil];
	[self triggersEnabledArrayChanged:nil];
	[self hitRatesEnabledArrayChanged:nil];
	[self hitRateLengthChanged:nil];
	[self hitRateChanged:nil];
    [self updateTimePlot:nil];
    [self totalRateChanged:nil];
	[self scaleAction:nil];
    [self testEnabledArrayChanged:nil];
	[self testStatusArrayChanged:nil];
    [self miscAttributesChanged:nil];
	[self interruptMaskChanged:nil];
	[self analogOffsetChanged:nil];
	[self selectedRegIndexChanged:nil];
	[self writeValueChanged:nil];
	[self selectedChannelValueChanged:nil];
	[self fifoBehaviourChanged:nil];
	[self postTriggerTimeChanged:nil];
	[self histRecTimeChanged:nil];
	[self histMeasTimeChanged:nil];
	[self histNofMeasChanged:nil];
    [self settingsLockChanged:nil];
	[self gapLengthChanged:nil];
	[self filterShapingLengthChanged:nil];
	[self storeDataInRamChanged:nil];
	[self histEMinChanged:nil];
	[self histEBinChanged:nil];
	[self histModeChanged:nil];
	[self histClrModeChanged:nil];
	[self histFirstEntryChanged:nil];
	[self histLastEntryChanged:nil];
	[self noiseFloorChanged:nil];
	[self noiseFloorOffsetChanged:nil];
	[self histPageABChanged:nil];
	[self histMaxEnergyChanged:nil];
	[self targetRateChanged:nil];
	[self shipSumHistogramChanged:nil];
	[self vetoOverlapTimeChanged:nil];
	[self nfoldCoincidenceChanged:nil];
	[self fifoLengthChanged:nil];
	[self activateDebuggerDisplaysChanged:nil];
	[self fifoFlagsChanged:nil];
	[self receivedHistoChanMapChanged:nil];
	[self receivedHistoCounterChanged:nil];
	[self customVariableChanged:nil];
	[self poleZeroCorrectionChanged:nil];
	[self decayTimeChanged:nil];
	[self recommendedPZCChanged:nil];
	[self syncWithRunControlChanged:nil];
	[self useDmaBlockReadChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORKatrinV4FLTSettingsLock to:secure];
    [settingLockButton setEnabled:secure];	
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) updateButtons
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORKatrinV4FLTSettingsLock];
    BOOL runInProgress    = [gOrcaGlobals runInProgress];
    BOOL locked           = [gSecurity isLocked:ORKatrinV4FLTSettingsLock];
	BOOL testsAreRunning  = [model testsRunning];
	BOOL testingOrRunning = testsAreRunning | runInProgress;
    
	if([model runMode] < 3 || [model runMode] > 6)	[modeTabView selectTabViewItemAtIndex:0];
	else											[modeTabView selectTabViewItemAtIndex:1];
	
	[gapLengthPU setEnabled:!lockedOrRunningMaintenance && (([model runMode]<3) || ([model runMode]>6))];
	[filterShapingLengthPU setEnabled:!lockedOrRunningMaintenance];
	
    [testEnabledMatrix setEnabled:!locked && !testingOrRunning];
    [settingLockButton setState: locked];
	[initBoardButton setEnabled:!lockedOrRunningMaintenance];
	[reportButton setEnabled:!lockedOrRunningMaintenance];
	[modeButton setEnabled:!lockedOrRunningMaintenance];
	[resetButton setEnabled:!lockedOrRunningMaintenance];
    [gainTextFields setEnabled:!lockedOrRunningMaintenance];
    [thresholdTextFields setEnabled:!lockedOrRunningMaintenance];
    [triggerEnabledCBs setEnabled:!lockedOrRunningMaintenance];
	[fireSoftwareTriggerButton  setEnabled: !lockedOrRunningMaintenance];
    [hitRateEnabledCBs setEnabled:!lockedOrRunningMaintenance];
    [vetoTriggerEnabledCBs setEnabled:!lockedOrRunningMaintenance];
    [vetoHitRateEnabledCBs setEnabled:!lockedOrRunningMaintenance];
    [vetoGainMatrix setEnabled:!lockedOrRunningMaintenance];
    [vetoThresholdMatrix setEnabled:!lockedOrRunningMaintenance];
	
	[versionButton setEnabled:!runInProgress];
	[testButton setEnabled:!runInProgress];
	[statusButton setEnabled:!runInProgress];
	
    [hitRateLengthPU setEnabled:!lockedOrRunningMaintenance];
    [hitRateAllButton setEnabled:!lockedOrRunningMaintenance];
    [hitRateNoneButton setEnabled:!lockedOrRunningMaintenance];
		
	if(testsAreRunning){
		[testButton setEnabled: YES];
		[testButton setTitle: @"Stop"];
	}
    else {
		[testButton setEnabled: !runInProgress];	
		[testButton setTitle: @"Test"];
	}
	
	int daqMode = [model runMode];
	//[histNofMeasField setEnabled: !locked & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[histMeasTimeField setEnabled: !lockedOrRunningMaintenance & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[histEMinTextField setEnabled: !lockedOrRunningMaintenance & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[histEBinPU setEnabled: !lockedOrRunningMaintenance & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[syncWithRunControlButton setEnabled: !runInProgress & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[shipSumHistogramPU setEnabled: !lockedOrRunningMaintenance & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[histModePU setEnabled: !lockedOrRunningMaintenance & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[histClrModePU setEnabled: !lockedOrRunningMaintenance & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[clearReceivedHistoCounterButton setEnabled: !lockedOrRunningMaintenance & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	
	[vetoActiveButton setState: !locked & ((daqMode == kIpeFltV4_VetoEnergyDaqMode)||(daqMode == kIpeFltV4_VetoEnergyTraceDaqMode))];

	[startNoiseFloorButton setEnabled: runInProgress || [model noiseFloorRunning]];
	
 	[self enableRegControls];
}

- (void) enableRegControls
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORKatrinV4FLTSettingsLock];
	short index = [model selectedRegIndex];
	BOOL readAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegReadable)>0;
	BOOL writeAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegWriteable)>0;
	BOOL needsChannel = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegNeedsChannel)>0;
	
	[regWriteButton setEnabled:writeAllowed];
	[regReadButton setEnabled:readAllowed];
	
	[regWriteValueStepper setEnabled:writeAllowed];
	[regWriteValueTextField setEnabled:writeAllowed];
    
    //TODO: extend the accesstype to "channel" and "block64" -tb-
    [channelPopUp setEnabled: needsChannel];
}

- (void) fifoFlagsChanged:(NSNotification*)aNote
{
	if(!aNote){
		int i;
		for(i=0;i<kNumV4FLTChannels;i++){
			[[fifoDisplayMatrix cellWithTag:i] setStringValue:[model fifoFlagString:i]];
		}
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[fifoDisplayMatrix cellWithTag:chan] setStringValue:[model fifoFlagString:chan]];
	}
}

- (void) noiseFloorChanged:(NSNotification*)aNote
{
	if([model noiseFloorRunning]){
		[noiseFloorProgress startAnimation:self];
		[startNoiseFloorButton setTitle:@"Stop"];
	}
	else {
		[noiseFloorProgress stopAnimation:self];
		[startNoiseFloorButton setTitle:@"Start"];
	}
	[noiseFloorStateField setStringValue:[model noiseFloorStateString]];
	[noiseFloorStateField2 setStringValue:[model noiseFloorStateString]];
}

- (void) noiseFloorOffsetChanged:(NSNotification*)aNote
{
	[noiseFloorOffsetField setIntValue:[model noiseFloorOffset]];
}


- (void) testEnabledArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumKatrinV4FLTTests;i++){
		[[testEnabledMatrix cellWithTag:i] setIntValue:[model testEnabled:i]];
	}    
}

- (void) testStatusArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumKatrinV4FLTTests;i++){
		[[testStatusMatrix cellWithTag:i] setStringValue:[model testStatus:i]];
	}
}


- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [rate0 xAxis]){
		[model setMiscAttributes:[[rate0 xAxis]attributes] forKey:@"RateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [totalRate xAxis]){
		[model setMiscAttributes:[[totalRate xAxis]attributes] forKey:@"TotalRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot xAxis]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot xAxis]attributes] forKey:@"TimeRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot yAxis]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot yAxis]attributes] forKey:@"TimeRateYAttributes"];
	};
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"RateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"RateXAttributes"];
		if(attrib){
			[[rate0 xAxis] setAttributes:attrib];
			[rate0 setNeedsDisplay:YES];
			[[rate0 xAxis] setNeedsDisplay:YES];
			[rateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TotalRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TotalRateXAttributes"];
		if(attrib){
			[[totalRate xAxis] setAttributes:attrib];
			[totalRate setNeedsDisplay:YES];
			[[totalRate xAxis] setNeedsDisplay:YES];
			[totalRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateXAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot xAxis] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateYAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot yAxis] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot yAxis] setNeedsDisplay:YES];
			[timeRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
}


- (void) updateTimePlot:(NSNotification*)aNote
{
	//if(!aNote || ([aNote object] == [[model adcRateGroup]timeRate])){
	//	[timeRatePlot setNeedsDisplay:YES];
	//}
}


- (void) gainChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORKatrinV4FLTChan] intValue];
	[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];
	[[vetoGainMatrix cellWithTag:chan] setIntValue: [model gain:chan]];
}

- (void) triggerEnabledChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		[[triggerEnabledCBs cellWithTag:i] setState: [model triggerEnabled:i]];
		[[vetoTriggerEnabledCBs cellWithTag:i] setState: [model triggerEnabled:i]];
	}
}

- (void) hitRateEnabledChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		[[hitRateEnabledCBs cellWithTag:i] setState: [model hitRateEnabled:i]];
		[[vetoHitRateEnabledCBs cellWithTag:i] setState: [model hitRateEnabled:i]];
	}
}

- (void) thresholdChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORKatrinV4FLTChan] intValue];
	[[thresholdTextFields cellWithTag:chan] setIntValue: [(ORKatrinV4FLTModel*)model threshold:chan]];
	[[vetoThresholdMatrix cellWithTag:chan] setIntValue: [(ORKatrinV4FLTModel*)model threshold:chan]];
}


- (void) slotChanged:(NSNotification*)aNotification
{
	// Set title of FLT configuration window, ak 15.6.07
	// for FLTv4 'slot' go from 0-9, 11-20 (SLTv4 has slot 10)
	[[self window] setTitle:[NSString stringWithFormat:@"IPE-DAQ V4 KATRIN FLT Card (Slot %d, FLT# %d)",[model slot]+1,[model stationNumber]]];
    [fltSlotNumTextField setStringValue: [NSString stringWithFormat:@"FLT# %d",[model stationNumber]]];
}

- (void) gainArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];
		[[vetoGainMatrix cellWithTag:chan] setIntValue: [model gain:chan]];
		
	}	
}

- (void) thresholdArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		[[thresholdTextFields cellWithTag:chan] setIntValue: [(ORKatrinV4FLTModel*)model threshold:chan]];
		[[vetoThresholdMatrix cellWithTag:chan] setIntValue: [(ORKatrinV4FLTModel*)model threshold:chan]];
	}
}

- (void) triggersEnabledArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		[[triggerEnabledCBs cellWithTag:chan] setIntValue: [model triggerEnabled:chan]];
		[[vetoTriggerEnabledCBs cellWithTag:chan] setIntValue: [model triggerEnabled:chan]];
		
	}
}

- (void) hitRatesEnabledArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		[[hitRateEnabledCBs cellWithTag:chan] setIntValue: [model hitRateEnabled:chan]];
		[[vetoHitRateEnabledCBs cellWithTag:chan] setIntValue: [model hitRateEnabled:chan]];
		
	}
}

- (void) modeChanged:(NSNotification*)aNote
{
	//[modeButton selectItemAtIndex:[model runMode]];
	// index is not the daq mode number any more -tb-
	[modeButton selectItemWithTag:[model runMode]];
	[self updateButtons];
}

- (void) hitRateLengthChanged:(NSNotification*)aNote
{
	[hitRateLengthPU selectItemWithTag:[model hitRateLength]];
}

- (void) hitRateChanged:(NSNotification*)aNote
{
	int chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		id theCell = [rateTextFields cellWithTag:chan];
		if([model hitRateOverFlow:chan]){
			[theCell setFormatter: nil];
			[theCell setTextColor:[NSColor redColor]];
			[theCell setObjectValue: @"OverFlow"];
		}
		else {
			[theCell setFormatter: rateFormatter];
			[theCell setTextColor:[NSColor blackColor]];
			[theCell setFloatValue: [model hitRate:chan]];
		}
	}
	[rate0 setNeedsDisplay:YES];
	[totalHitRateField setFloatValue:[model hitRateTotal]];
	[totalRate setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNote
{
	if(aNote==nil || [aNote object] == [model totalRate]){
		[timeRatePlot setNeedsDisplay:YES];
	}
}

- (void) selectedRegIndexChanged:(NSNotification*) aNote
{
	//	NSLog(@"This is v4FLT selectedRegIndexChanged\n" );
    //[registerPopUp selectItemAtIndex: [model selectedRegIndex]];
	[self updatePopUpButton:registerPopUp	 setting:[model selectedRegIndex]];
	
	[self enableRegControls];
}

- (void) writeValueChanged:(NSNotification*) aNote
{
    [regWriteValueTextField setIntValue: [model writeValue]];
}

- (void) selectedChannelValueChanged:(NSNotification*) aNote
{
    [channelPopUp selectItemWithTag: [model selectedChannelValue]];
	//[self updatePopUpButton:channelPopUp	 setting:[model selectedRegIndex]];
	
	[self enableRegControls];
}

- (void) tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:settingSize];		break;
		case  1: [self resizeWindowToSize:rateSize];	    break;
		case  2: [self resizeWindowToSize:testSize];        break;
		case  3: [self resizeWindowToSize:lowlevelSize];	break;
		default: [self resizeWindowToSize:testSize];	    break;
    }
    [[self window] setContentView:totalView];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORKatrinV4FLT%d.selectedtab",[model stationNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

#pragma mark •••Actions

- (void) useDmaBlockReadButtonAction:(id)sender
{
	[model setUseDmaBlockRead:[sender intValue]];	
}

- (void) syncWithRunControlButtonAction:(id)sender
{
	[model setSyncWithRunControl:[sender intValue]];	
}

- (void) decayTimeTextFieldAction:(id)sender
{
	[model setDecayTime:[sender doubleValue]];	
}

- (void) poleZeroCorrectionPUAction:(id)sender
{
	[model setPoleZeroCorrection:[poleZeroCorrectionPU indexOfSelectedItem]];	
}

- (void) customVariableTextFieldAction:(id)sender
{
	[model setCustomVariable:[sender intValue]];	
}

- (IBAction) clearHistoCounterButtonAction:(id)sender
{
	[model clearReceivedHistoCounter];	
}


- (void) receivedHistoCounterTextFieldAction:(id)sender
{
	[model setReceivedHistoCounter:[sender intValue]];	
}

- (void) receivedHistoChanMapTextFieldAction:(id)sender
{
	[model setReceivedHistoChanMap:[sender intValue]];	
}

- (IBAction) fifoLengthPUAction:(id)sender
{
	[model setFifoLength:[fifoLengthPU indexOfSelectedItem]];	
}

- (IBAction) nfoldCoincidencePUAction:(id)sender
{
	//NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model setNfoldCoincidence:[sender indexOfSelectedItem]];	
}


- (IBAction) vetoOverlapTimePUAction:(id)sender
{
	[model setVetoOverlapTime:[vetoOverlapTimePU indexOfSelectedItem]];	
}

- (IBAction) shipSumHistogramPUAction:(id)sender
{
	//[model setShipSumHistogram:[sender intValue]];	
	[model setShipSumHistogram:[[shipSumHistogramPU selectedItem] tag]];
}

- (IBAction) targetRateAction:(id)sender
{
	[model setTargetRate:[sender intValue]];	
}

- (IBAction) activateDebuggingDisplayAction:(id)sender
{
    [model setActivateDebuggingDisplays:[sender intValue]];
}


- (IBAction) openNoiseFloorPanel:(id)sender
{
	[self endEditing];
    [NSApp beginSheet:noiseFloorPanel modalForWindow:[self window]
		modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (IBAction) closeNoiseFloorPanel:(id)sender
{
    [noiseFloorPanel orderOut:nil];
    [NSApp endSheet:noiseFloorPanel];
}

- (IBAction) findNoiseFloors:(id)sender
{
	[noiseFloorPanel endEditingFor:nil];		
    @try {
        NSLog(@"IPE V4 FLT (slot %d) Finding Thresholds \n",[model slot]);
		[model findNoiseFloors];
    }
	@catch(NSException* localException) {
        NSLog(@"Threshold Finder for IPE V4 FLT Board FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed Threshold finder", @"OK", nil, nil,
                        localException);
    }
}
- (IBAction) noiseFloorOffsetAction:(id)sender
{
    if([sender intValue] != [model noiseFloorOffset]){
        [model setNoiseFloorOffset:[sender intValue]];
    }
}

- (IBAction) histClrModeAction:(id)sender
{
	[model setHistClrMode:[sender indexOfSelectedItem]];	
}

- (IBAction) histModeAction:(id)sender
{
	[model setHistMode:[sender indexOfSelectedItem]];	
}

- (IBAction) histEBinAction:(id)sender
{
	[model setHistEBin:[sender indexOfSelectedItem]];	
}

- (IBAction) histEMinAction:(id)sender
{
	[model setHistEMin:[sender intValue]];	
}


- (IBAction) storeDataInRamAction:(id)sender
{
	[model setStoreDataInRam:[sender intValue]];	
}

- (IBAction) filterShapingLengthAction:(id)sender
{
	//[model setFilterLength:[sender indexOfSelectedItem]];
	[model setFilterShapingLength:[[sender selectedCell] tag]];
}

- (IBAction) gapLengthAction:(id)sender
{
	[model setGapLength:[sender indexOfSelectedItem]];	
}

- (IBAction) histNofMeasAction:(id)sender
{
	[model setHistNofMeas:[sender intValue]];	
}

- (IBAction) histMeasTimeAction:(id)sender
{
	[model setHistMeasTime:[sender intValue]];	
}

- (IBAction) setTimeToMacClock:(id)sender
{
	@try {
		[model setTimeToMacClock];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT clock\n");
		NSRunAlertPanel([localException name], @"%@\nSetClock of FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}


- (IBAction) postTriggerTimeAction:(id)sender
{
	@try {
		[model setPostTriggerTime:[sender intValue]];	
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT post trigger time\n");
		NSRunAlertPanel([localException name], @"%@\nSet post trigger time of FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) fifoBehaviourAction:(id)sender
{
	@try {
		[model setFifoBehaviour:[[sender selectedCell]tag]];	
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT behavior\n");
		NSRunAlertPanel([localException name], @"%@\nSetting Behaviour of FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) analogOffsetAction:(id)sender
{
	@try {
		[model setAnalogOffset:[sender intValue]];	
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT analog offset\n");
		NSRunAlertPanel([localException name], @"%@\nSet analog offset FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) interruptMaskAction:(id)sender
{
	@try {
		[model setInterruptMask:[sender intValue]];	
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT interrupt mask\n");
		NSRunAlertPanel([localException name], @"%@\nSet of interrupt mask of FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) testEnabledAction:(id)sender
{
	NSMutableArray* anArray = [NSMutableArray array];
	int i;
	for(i=0;i<kNumKatrinV4FLTTests;i++){
		if([[testEnabledMatrix cellWithTag:i] intValue])[anArray addObject:[NSNumber numberWithBool:YES]];
		else [anArray addObject:[NSNumber numberWithBool:NO]];
	}
	[model setTestEnabledArray:anArray];
}

- (IBAction) setDefaultsAction: (id) sender
{
	@try {
		[model setToDefaults];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT default Values\n");
		NSRunAlertPanel([localException name], @"%@\nSet Defaults for FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) readThresholdsGains:(id)sender
{
	@try {
		int i;
		NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
		NSLogFont(aFont,   @"FLT (station %d)\n",[model stationNumber]); // ak, 5.10.07
		NSLogFont(aFont,   @"chan | Gain | Threshold\n");
		NSLogFont(aFont,   @"-----------------------\n");
		for(i=0;i<kNumV4FLTChannels;i++){
			NSLogFont(aFont,@"%4d | %4d | %4d \n",i,[model readGain:i],[model readThreshold:i]);
			//NSLog(@"%d: %d\n",i,[model readGain:i]);
		}
		NSLogFont(aFont,   @"-----------------------\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT gains and thresholds\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) writeThresholdsGains:(id)sender
{
	[self endEditing];
	@try {
		[model loadThresholdsAndGains];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception writing FLT gains and thresholds\n");
        NSRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) gainAction:(id)sender
{
	if([sender intValue] != [model gain:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Gain"];
		[model setGain:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) thresholdAction:(id)sender
{
	if([sender intValue] != [(ORKatrinV4FLTModel*)model threshold:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Threshold"];
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}


- (IBAction) triggerEnableAction:(id)sender
{
	[[self undoManager] setActionName: @"Set TriggerEnabled"];
	[model setTriggerEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) hitRateEnableAction:(id)sender
{
	[[self undoManager] setActionName: @"Set HitRate Enabled"];
	[model setHitRateEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}


- (IBAction) reportButtonAction:(id)sender
{
	[self endEditing];
	@try {
		[model printVersions];
		[model printStatusReg];
		[model printPStatusRegs];
		//[model printPixelRegs];
		[model printValueTable];
		//[model printStatistics];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT (%d) status\n",[model stationNumber]);
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) initBoardButtonAction:(id)sender
{
	[self endEditing];
	@try {
		[model initBoard];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception intitBoard FLT (%d) status\n",[model stationNumber]);
        NSRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORKatrinV4FLTSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) modeAction: (id) sender
{
	//[model setRunMode:[modeButton indexOfSelectedItem]];
	// index is not equal to daq mode any more, use tag instead -tb-
	[model setRunMode:[[modeButton selectedItem] tag]];
}

- (IBAction) versionAction: (id) sender
{
	@try {
		[model printVersions];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT HW Model Version\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) testAction: (id) sender
{
	@try {
		[model runTests];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT HW Model Test\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}


- (IBAction) resetAction: (id) sender
{
	@try {
		[model reset];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception during FLT reset\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) hitRateLengthAction: (id) sender
{
	if([sender indexOfSelectedItem] != [model hitRateLength]){
		[[self undoManager] setActionName: @"Set Hit Rate Length"]; 
		[model setHitRateLength:[[sender selectedItem] tag]];
	}
}

- (IBAction) hitRateAllAction: (id) sender
{
	[model enableAllHitRates:YES];
}

- (IBAction) hitRateNoneAction: (id) sender
{
	[model enableAllHitRates:NO];
}

- (IBAction) enableAllTriggersAction: (id) sender
{
	[model enableAllTriggers:YES];
}

- (IBAction) enableNoTriggersAction: (id) sender
{
	[model enableAllTriggers:NO];
}

- (IBAction) fireSoftwareTriggerAction: (id) sender
{
	NSLog(@"Fire Software Trigger!\n");
	@try {
	    [model fireSoftwareTrigger];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception during FLT read status\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}




- (IBAction) statusAction:(id)sender
{
	@try {
		[model printStatusReg];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception during FLT read status\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) selectRegisterAction:(id) aSender
{
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[model undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
    }
}

- (IBAction) selectChannelAction:(id) aSender
{
    if ([[aSender selectedItem] tag] != [model selectedChannelValue]){
	    [[model undoManager] setActionName:@"Select Channel Number"]; // Set undo name do it at model side -tb-
	    [model setSelectedChannelValue:[[aSender selectedItem] tag]]; // set new value
    }
}

- (IBAction) writeValueAction:(id) aSender
{
	[self endEditing];
    if ([aSender intValue] != [model writeValue]){
		[[model undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction) readRegAction: (id) sender
{
	int index = [model selectedRegIndex]; 
	@try {
		unsigned long value;
        if(([model getAccessType:index] & kIpeRegNeedsChannel)){
            int chan = [model selectedChannelValue];
		    value = [model readReg:index channel: chan ];
		    NSLog(@"FLTv4 reg: %@ for channel %i has value: 0x%x (%i)\n",[model getRegisterName:index], chan, value, value);
        }
		else {
		    value = [model readReg:index ];
		    NSLog(@"FLTv4 reg: %@ has value: 0x%x (%i)\n",[model getRegisterName:index],value, value);
        }
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT reg: %@\n",[model getRegisterName:index]);
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) writeRegAction: (id) sender
{
	[self endEditing];
	int index = [registerPopUp indexOfSelectedItem];
	@try {
		unsigned long val = [model writeValue];
        if(([model getAccessType:index] & kIpeRegNeedsChannel)){
            int chan = [model selectedChannelValue];
     		[model writeReg:index  channel: chan value: val];//TODO: allow hex values, e.g. 0x23 -tb-
    		NSLog(@"wrote 0x%x (%i) to FLTv4 reg: %@ channel %i\n", val, val, [model getRegisterName:index], chan);
        }
		else{
    		[model writeReg:index value: val];//TODO: allow hex values, e.g. 0x23 -tb-
    		NSLog(@"wrote 0x%x (%i) to FLTv4 reg: %@ \n",val,val,[model getRegisterName:index]);
        }
	}
	@catch(NSException* localException) {
		NSLog(@"Exception writing FLTv4 reg: %@\n",[model getRegisterName:index]);
        NSRunAlertPanel([localException name], @"%@\nFLTv4%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) testButtonAction: (id) sender //temp routine to hook up to any on a temp basis
{
	@try {
		[model testReadHisto];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception running FLT test code\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}


- (IBAction) devTest1ButtonAction: (id) sender
{
    NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	//ORRunAboutToChangeState
	[model devTest1ButtonAction];
}

- (IBAction) devTest2ButtonAction: (id) sender
{
    NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	[model devTest2ButtonAction];
}


- (IBAction) testButtonLowLevelAction: (id) sender
{
    NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    if(sender==configTPButton){
        NSLog(@"   configTPButton: Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	    [model testButtonLowLevelConfigTP];
	}

    if(sender==fireTPButton){
        NSLog(@"   fireTPButton: Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	    [model testButtonLowLevelFireTP];
	}

    if(sender==resetTPButton){
        NSLog(@"   resetTPButton: Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	    [model testButtonLowLevelResetTP];
	}

}



#pragma mark •••Plot DataSource
- (int) numberPointsInPlot:(id)aPlotter
{
	return [[model  totalRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int count = [[model totalRate]count];
	int index = count-i-1;
	*yValue =  [[model totalRate] valueAtIndex:index];
	*xValue =  [[model totalRate] timeSampledAtIndex:index];
}

@end



