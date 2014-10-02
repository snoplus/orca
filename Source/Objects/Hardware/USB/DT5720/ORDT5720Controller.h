//
//  ORDT5720Controller.h
//  Orca
//
//  Created by Mark Howe on Wed Mar 12,2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
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

@interface ORDT5720Controller : OrcaObjectController 
{
	IBOutlet NSPopUpButton* serialNumberPopup;
	IBOutlet NSMatrix*      ttlEnabledMatrix;
	IBOutlet NSButton*      gpoEnabledButton;
	IBOutlet NSButton*      fpSoftwareTrigEnabledButton;
	IBOutlet NSButton*      fpExternalTrigEnabledButton;
	IBOutlet NSButton*      externalTrigEnabledButton;
	IBOutlet NSButton*      softwareTrigEnabledButton;
	IBOutlet NSMatrix*      gpiRunModeMatrix;
	IBOutlet NSPopUpButton* clockSourcePU;
	IBOutlet NSMatrix*      trigOnUnderThresholdMatrix;
	IBOutlet NSButton*      testPatternEnabledButton;
	IBOutlet NSButton*      trigOverlapEnabledButton;
	IBOutlet NSPopUpButton* zsAlgorithmPU;
    IBOutlet NSMatrix*		thresholdMatrix;
    IBOutlet NSMatrix*		zsThresholdMatrix;
    IBOutlet NSMatrix*		nLbkMatrix;
    IBOutlet NSMatrix*		nLfwdMatrix;
    IBOutlet NSMatrix*		dacMatrix;

	IBOutlet NSMatrix*      logicTypeMatrix;
	IBOutlet NSButton*		lockButton;
    IBOutlet NSTabView* 	tabView;
    IBOutlet NSStepper* 	addressStepper;
    IBOutlet NSTextField* 	addressTextField;
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
    
    
    IBOutlet NSButton*		softwareTriggerButton;
	IBOutlet NSMatrix*		enabledMaskMatrix;
	IBOutlet NSMatrix*		chanTriggerMatrix;
	IBOutlet NSMatrix*		otherTriggerMatrix;
	IBOutlet NSMatrix*		chanTriggerOutMatrix;
	IBOutlet NSMatrix*		otherTriggerOutMatrix;
	IBOutlet NSButton*		fpIOGetButton;
	IBOutlet NSButton*		fpIOSetButton;
	IBOutlet NSTextField*	postTriggerSettingTextField;
	IBOutlet NSMatrix*		triggerSourceMaskMatrix;
	IBOutlet NSTextField*	coincidenceLevelTextField;
	IBOutlet NSMatrix*		countAllTriggersMatrix;
	IBOutlet NSTextField*	customSizeTextField;
	IBOutlet NSButton*      customSizeButton;
	IBOutlet NSButton*      fixedSizeButton;
    IBOutlet NSMatrix*		overUnderMatrix;
	IBOutlet NSPopUpButton* eventSizePopUp;
	IBOutlet NSTextField*	eventSizeTextField;
    IBOutlet NSTextField*	slotField;
    IBOutlet NSTextField*	slot1Field;
	
    IBOutlet NSButton*		initButton;
    IBOutlet NSButton*		reportButton;
    IBOutlet NSButton*		loadThresholdsButton;
	
	//rates page
	IBOutlet NSMatrix*      rateTextFields;
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;
    IBOutlet NSMatrix*      enabled2MaskMatrix;
    
    IBOutlet ORValueBarGroupView*    rate0;
    IBOutlet ORValueBarGroupView*    totalRate;
    IBOutlet NSButton*      rateLogCB;
    IBOutlet NSButton*      totalRateLogCB;
    IBOutlet ORCompositeTimeLineView*    timeRatePlot;
    IBOutlet NSButton*      timeRateLogCB;
    IBOutlet NSTextField*   bufferStateField;
    
	
    IBOutlet NSButton*		basicLockButton;
    IBOutlet NSButton*		settingsLockButton;
	IBOutlet NSTextField*   settingsLockDocField;
    
    
    NSView *blankView;
    NSSize basicSize;
    NSSize settingsSize;
    NSSize monitoringSize;
}

#pragma mark •••Initialization
- (id) init;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) ttlEnabledChanged:(NSNotification*)aNote;
- (void) gpoEnabledChanged:(NSNotification*)aNote;
- (void) fpSoftwareTrigEnabledChanged:(NSNotification*)aNote;
- (void) fpExternalTrigEnabledChanged:(NSNotification*)aNote;
- (void) externalTrigEnabledChanged:(NSNotification*)aNote;
- (void) softwareTrigEnabledChanged:(NSNotification*)aNote;
- (void) gpiRunModeChanged:(NSNotification*)aNote;
- (void) clockSourceChanged:(NSNotification*)aNote;
- (void) trigOnUnderThresholdChanged:(NSNotification*)aNote;
- (void) testPatternEnabledChanged:(NSNotification*)aNote;
- (void) trigOverlapEnabledChanged:(NSNotification*)aNote;
- (void) zsAlgorithmChanged:(NSNotification*)aNote;
- (void) logicTypeChanged:(NSNotification*)aNote;
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;

- (void) validateInterfacePopup;

#pragma mark ***Initialization
- (id)		init;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) registerRates;

#pragma mark ***Interface Management
- (void) eventSizeChanged:(NSNotification*)aNote;
- (void) updateWindow;
- (void) overUnderThresholdChanged: (NSNotification*) aNote;
- (void) zsThresholdChanged: (NSNotification*) aNote;
- (void) thresholdChanged: (NSNotification*) aNote;
- (void) nlfwdChanged:(NSNotification*) aNote;
- (void) dacChanged: (NSNotification*) aNote;


- (void) integrationChanged:(NSNotification*)aNote;
- (void) writeValueChanged: (NSNotification*) aNote;
- (void) selectedRegIndexChanged: (NSNotification*) aNote;
- (void) selectedRegChannelChanged:(NSNotification*) aNote;
- (void) enabledMaskChanged:(NSNotification*)aNote;
- (void) postTriggerSettingChanged:(NSNotification*)aNote;
- (void) triggerSourceMaskChanged:(NSNotification*)aNote;
- (void) triggerOutMaskChanged:(NSNotification*)aNote;
- (void) coincidenceLevelChanged:(NSNotification*)aNote;
- (void) basicLockChanged:(NSNotification*)aNote;
- (void) countAllTriggersChanged:(NSNotification*)aNote;
- (void) customSizeChanged:(NSNotification*)aNote;
- (void) isCustomSizeChanged:(NSNotification*)aNote;
- (void) basicLockChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;

- (void) setBufferStateLabel;

#pragma mark •••Actions
- (IBAction) ttlEnabledAction:(id)sender;
- (IBAction) gpoEnabledAction:(id)sender;
- (IBAction) fpSoftwareTrigEnabledAction:(id)sender;
- (IBAction) fpExternalTrigEnabledAction:(id)sender;
- (IBAction) externalTrigEnabledAction:(id)sender;
- (IBAction) softwareTrigEnabledAction:(id)sender;
- (IBAction) gpiRunModeAction:(id)sender;
- (IBAction) clockSourcePUAction:(id)sender;
- (IBAction) trigOnUnderThresholdAction:(id)sender;
- (IBAction) testPatternEnabledAction:(id)sender;
- (IBAction) trigOverlapEnabledAction:(id)sender;
- (IBAction) zsAlgorithmAction:(id)sender;
- (IBAction) logicTypeAction:(id)sender;
- (IBAction) thresholdAction: (id) sender;
- (IBAction) zsThresholdAction: (id) sender;
- (IBAction) nLbkAction: (id) sender;
- (IBAction) nLfwdAction: (id) sender;
- (IBAction) overUnderAction: (id) sender;
- (IBAction) dacAction: (id) sender;

- (IBAction) settingLockAction:(id) sender;
- (IBAction) serialNumberAction:(id)sender;
- (IBAction) eventSizeAction:(id)sender;
- (IBAction) integrationAction:(id)sender;
- (IBAction) writeValueAction: (id) sender;
- (IBAction) selectRegisterAction: (id) sender;
- (IBAction) selectChannelAction: (id) sender;

- (IBAction) basicReadAction: (id) sender;
- (IBAction) basicWriteAction: (id) sender;
- (IBAction) basicLockAction:(id)sender;
- (IBAction) settingsLockAction:(id)sender;

- (IBAction) reportAction: (id) sender;
- (IBAction) initBoardAction: (id) sender;
- (IBAction) loadThresholdsAction: (id) sender;
- (IBAction) enabledMaskAction:(id)sender;
- (IBAction) postTriggerSettingTextFieldAction:(id)sender;
- (IBAction) triggerSourceMaskAction:(id)sender;
- (IBAction) triggerOutMaskAction:(id)sender;
- (IBAction) fpIOGetAction:(id)sender;
- (IBAction) fpIOSetAction:(id)sender;
- (IBAction) coincidenceLevelTextFieldAction:(id)sender;
- (IBAction) generateTriggerAction:(id)sender;
- (IBAction) countAllTriggersAction:(id)sender;
- (IBAction) customSizeAction:(id)sender;
- (IBAction) isCustomSizeAction:(id)sender;
- (IBAction) countinuousRunsAction:(id)sender;

#pragma mark •••Misc Helpers
- (void)    populatePullDown;
- (void)    updateRegisterDescription: (short) aRegisterIndex;
- (void)    tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

#pragma mark •••Data Source
- (double) getBarValue:(int)tag;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end


