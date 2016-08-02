//
//  ORDT5725Controller.h
//  Orca
//
//  Created by Mark Howe on Wed Jun 29,2016.
//  Copyright (c) 2016 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina at the Center sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORHPPulserController.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;
@class ORSafeCircularBuffer;
@class ORQueueView;

@interface ORDT5725Controller : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
    
    //By Channel
    IBOutlet NSMatrix*      inputDynamicRangeMatrix;
    IBOutlet NSMatrix*      selfTrigPulseWidthMatrix;
    IBOutlet NSMatrix*		thresholdMatrix;
    IBOutlet NSMatrix*      selfTrigLogicMatrix;
    IBOutlet NSMatrix*      selfTrigPulseTypeMatrix;
    IBOutlet NSMatrix*      dcOffsetMatrix;

    IBOutlet NSMatrix*      trigOnUnderThresholdMatrix;
    IBOutlet NSButton*      testPatternEnabledButton;
    IBOutlet NSButton*      trigOverlapEnabledButton;

    IBOutlet NSTextField*	eventSizeTextField;

    IBOutlet NSPopUpButton* clockSourcePU;
    IBOutlet NSMatrix*		countAllTriggersMatrix;
	IBOutlet NSPopUpButton* startStopRunModePU; //sw, gpi, or firstTrig
    IBOutlet NSMatrix*      memFullModeMatrix;

	IBOutlet NSButton*      softwareTrigEnabledButton;
	IBOutlet NSButton*      externalTrigEnabledButton;
    IBOutlet NSTextField*   coincidenceWindowTextField;
    IBOutlet NSTextField*	coincidenceLevelTextField;
    IBOutlet NSMatrix*		triggerSourceEnableMaskMatrix;

    IBOutlet NSButton*      swTrigOutEnabledButton;
    IBOutlet NSButton*      extTrigOutEnabledButton;
    IBOutlet NSMatrix*		triggerOutMaskMatrix;
    IBOutlet NSPopUpButton* triggerOutLogicPU;
    IBOutlet NSTextField*   trigOutCoincidenceLevelTextField;

    IBOutlet NSTextField*	postTriggerSettingTextField;

    IBOutlet NSMatrix*      fpLogicTypeMatrix;
    IBOutlet NSButton*      fpTrigInSigEdgeDisableButton;
    IBOutlet NSButton*      fpTrigInToMezzaninesButton;
    IBOutlet NSButton*      fpForceTrigOutButton;
    IBOutlet NSPopUpButton* fpTrigOutModePU;
    IBOutlet NSPopUpButton* fpTrigOutModeSelectPU;
    IBOutlet NSPopUpButton* fpMBProbeSelectPU;
    IBOutlet NSButton*      fpBusyUnlockButton;
    IBOutlet NSMatrix*      fpHeaderPatternMatrix;

    IBOutlet NSMatrix*		enabledMaskMatrix;

    IBOutlet NSMatrix*      fanSpeedModeMatrix;
    IBOutlet NSTextField*   almostFullLevelTextField;
    IBOutlet NSTextField*   runDelayTextField;

    IBOutlet NSStepper* 	writeValueStepper;
    IBOutlet NSTextField* 	writeValueTextField;
    IBOutlet NSPopUpButton*	registerAddressPopUp;
    IBOutlet NSPopUpButton*	channelPopUp;
    IBOutlet NSTextField*   basicLockDocField;
    IBOutlet NSButton*		basicWriteButton;
    IBOutlet NSButton*		basicReadButton;
    
	IBOutlet NSTextField*	regNameField;
    IBOutlet NSTextField*	drTextField;
    IBOutlet NSTextField*	srTextField;
    IBOutlet NSTextField*	hrTextField;
    IBOutlet NSTextField*	registerOffsetTextField;
    IBOutlet NSTextField*	registerReadWriteTextField;
    
    IBOutlet NSMatrix*      adcTempMatrix;
    IBOutlet NSButton*      adcCalibrateButton;
    IBOutlet NSTextField*   adcCalibrateTextField;
    IBOutlet NSButton*		softwareTriggerButton;
    IBOutlet NSButton*      softwareResetButton;
    IBOutlet NSButton*      softwareClearButton;
    IBOutlet NSButton*      configReloadButton;
	
    IBOutlet NSButton*		initButton;
    IBOutlet NSButton*		reportButton;
	
	//rates page
	IBOutlet NSMatrix*      rateTextFields;
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;
    IBOutlet NSMatrix*      enabled2MaskMatrix;
    
    IBOutlet ORValueBarGroupView*     rate0;
    IBOutlet ORValueBarGroupView*     totalRate;
    IBOutlet NSButton*                rateLogCB;
    IBOutlet NSButton*                totalRateLogCB;
    IBOutlet ORCompositeTimeLineView* timeRatePlot;
    IBOutlet NSButton*                timeRateLogCB;
    IBOutlet NSTextField*             bufferStateField;
    IBOutlet NSTextField*             transferRateField;
    IBOutlet NSButton*		basicLockButton;
    IBOutlet NSButton*		lowLevelLockButton;
    IBOutlet ORQueueView*   queView;
    IBOutlet NSPopUpButton* serialNumberPopup;

    
    NSView *blankView;
    NSSize lowLevelSize;
    NSSize basicSize;
    NSSize monitoringSize;
}

#pragma mark •••Initialization
- (id) init;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) registerRates;
- (void) updateWindow;
- (void) validateInterfacePopup;

#pragma mark ***Interface Management
- (void) inputDynamicRangeChanged:(NSNotification*)aNote;
- (void) selfTrigPulseWidthChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) selfTrigLogicChanged:(NSNotification*)aNote;
- (void) selfTrigPulseTypeChanged:(NSNotification*)aNote;
- (void) dcOffsetChanged:(NSNotification*)aNote;
- (void) trigOnUnderThresholdChanged:(NSNotification*)aNote;
- (void) testPatternEnabledChanged:(NSNotification*)aNote;
- (void) trigOverlapEnabledChanged:(NSNotification*)aNote;
- (void) eventSizeChanged:(NSNotification*)aNote;
- (void) clockSourceChanged:(NSNotification*)aNote;
- (void) countAllTriggersChanged:(NSNotification*)aNote;
- (void) startStopRunModeChanged:(NSNotification*)aNote;
- (void) memFullModeChanged:(NSNotification*)aNote;
- (void) softwareTrigEnabledChanged:(NSNotification*)aNote;
- (void) externalTrigEnabledChanged:(NSNotification*)aNote;
- (void) coincidenceWindowChanged:(NSNotification*)aNote;
- (void) coincidenceLevelChanged:(NSNotification*)aNote;
- (void) triggerSourceEnableMaskChanged:(NSNotification*)aNote;
- (void) swTrigOutEnabledChanged:(NSNotification*)aNote;
- (void) extTrigOutEnabledChanged:(NSNotification*)aNote;
- (void) triggerOutMaskChanged:(NSNotification*)aNote;
- (void) triggerOutLogicChanged:(NSNotification*)aNote;
- (void) trigOutCoincidenceLevelChanged:(NSNotification*)aNote;
- (void) postTriggerSettingChanged:(NSNotification*)aNote;
- (void) fpLogicTypeChanged:(NSNotification*)aNote;
- (void) fpTrigInSigEdgeDisableChanged:(NSNotification*)aNote;
- (void) fpTrigInToMezzaninesChanged:(NSNotification*)aNote;
- (void) fpForceTrigOutChanged:(NSNotification*)aNote;
- (void) fpTrigOutModeChanged:(NSNotification*)aNote;
- (void) fpTrigOutModeSelectChanged:(NSNotification*)aNote;
- (void) fpMBProbeSelectChanged:(NSNotification*)aNote;
- (void) fpBusyUnlockSelectChanged:(NSNotification*)aNote;
- (void) fpHeaderPatternChanged:(NSNotification*)aNote;
- (void) enabledMaskChanged:(NSNotification*)aNote;
- (void) fanSpeedModeChanged:(NSNotification*)aNote;
- (void) almostFullLevelChanged:(NSNotification*)aNote;
- (void) runDelayChanged:(NSNotification*)aNote;

- (void) scaleAction:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;

- (void) writeValueChanged: (NSNotification*) aNote;
- (void) selectedRegIndexChanged: (NSNotification*) aNote;
- (void) selectedRegChannelChanged:(NSNotification*) aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;

- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) basicLockChanged:(NSNotification*)aNote;
- (void) lowLevelLockChanged:(NSNotification*)aNote;

- (void) setStatusStrings;

#pragma mark •••Actions
- (IBAction) serialNumberAction:(id)sender;
- (IBAction) inputDynamicRangeAction:(id)sender;
- (IBAction) selfTrigPulseWidthAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) selfTrigLogicAction:(id)sender;
- (IBAction) selfTrigPulseTypeAction:(id)sender;
- (IBAction) dcOffsetAction:(id)sender;
- (IBAction) trigOnUnderThresholdAction:(id)sender;
- (IBAction) testPatternEnabledAction:(id)sender;
- (IBAction) trigOverlapEnabledAction:(id)sender;
- (IBAction) eventSizeAction:(id)sender;
- (IBAction) clockSourceAction:(id)sender;
- (IBAction) countAllTriggersAction:(id)sender;
- (IBAction) startStopRunModeAction:(id)sender;
- (IBAction) memFullModeAction:(id)sender;
- (IBAction) softwareTrigEnabledAction:(id)sender;
- (IBAction) externalTrigEnabledAction:(id)sender;
- (IBAction) coincidenceWindowAction:(id)sender;
- (IBAction) coincidenceLevelAction:(id)sender;
- (IBAction) triggerSourceEnableMaskAction:(id)sender;
- (IBAction) swTrigOutEnabledAction:(id)sender;
- (IBAction) extTrigOutEnabledAction:(id)sender;
- (IBAction) triggerOutMaskAction:(id)sender;
- (IBAction) triggerOutLogicAction:(id)sender;
- (IBAction) trigOutCoincidenceLevelAction:(id)sender;
- (IBAction) postTriggerSettingAction:(id)sender;
- (IBAction) fpLogicTypeAction:(id)sender;
- (IBAction) fpTrigInSigEdgeDisableAction:(id)sender;
- (IBAction) fpTrigInToMezzaninesAction:(id)sender;
- (IBAction) fpForceTrigOutAction:(id)sender;
- (IBAction) fpTrigOutModeAction:(id)sender;
- (IBAction) fpTrigOutModeSelectAction:(id)sender;
- (IBAction) fpMBProbeSelectAction:(id)sender;
- (IBAction) fpBusyUnlockSelectAction:(id)sender;
- (IBAction) fpHeaderPatternAction:(id)sender;
- (IBAction) enabledMaskAction:(id)sender;
- (IBAction) fanSpeedModeAction:(id)sender;
- (IBAction) almostFullLevelAction:(id)sender;
- (IBAction) runDelayAction:(id)sender;

- (IBAction) writeValueAction: (id) sender;
- (IBAction) selectRegisterAction: (id) sender;
- (IBAction) selectChannelAction: (id) sender;
- (IBAction) basicReadAction: (id) sender;
- (IBAction) basicWriteAction: (id) sender;

- (IBAction) lowLevelLockAction:(id) sender;
- (IBAction) basicLockAction:(id)sender;

- (IBAction) reportAction: (id) sender;
- (IBAction) initBoardAction: (id) sender;
- (IBAction) adcCalibrateAction:(id)sender;
- (IBAction) generateTriggerAction:(id)sender;
- (IBAction) softwareResetAction:(id)sender;
- (IBAction) softwareClearAction:(id)sender;
- (IBAction) configReloadAction:(id)sender;
- (IBAction) integrationAction:(id)sender;

#pragma mark •••Misc Helpers
- (void)    populatePullDown;
- (void)    updateRegisterDescription: (short) aRegisterIndex;
- (void)    tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

#pragma mark •••Data Source
- (double) getBarValue:(int)tag;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

- (void) getQueMinValue:(unsigned long*)aMinValue maxValue:(unsigned long*)aMaxValue head:(unsigned long*)aHeadValue tail:(unsigned long*)aTailValue;

@end


