//
//ORCaen1720Controller.h
//Orca
//
//Created by Mark Howe on Mon Apr 14 2008.
//Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//
//-------------------------------------------------------------
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
#import "OrcaObjectController.h";

@interface ORCaen1720Controller : OrcaObjectController {
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


    IBOutlet NSMatrix*		thresholdMatrix;
    IBOutlet NSButton*		softwareTriggerButton;
	IBOutlet NSMatrix*		enabledMaskMatrix;
	IBOutlet NSTextField*	postTriggerSettingTextField;
	IBOutlet NSMatrix*		triggerSourceMaskMatrix;
	IBOutlet NSTextField*	coincidenceLevelTextField;
    IBOutlet NSMatrix*		dacMatrix;
	IBOutlet NSMatrix*		acquisitionModeMatrix;
	IBOutlet NSMatrix*		countAllTriggersMatrix;
	IBOutlet NSTextField*	customSizeTextField;
	IBOutlet NSMatrix*		channelConfigMaskMatrix;
    IBOutlet NSMatrix*		overUnderMatrix;

    IBOutlet NSButton*		basicLockButton;
    IBOutlet NSButton*		settingsLockButton;

    NSView *blankView;
    NSSize settingSize;
    NSSize thresholdSize;

}

#pragma mark ***Initialization
- (id)		init;
 	
#pragma mark •••Notifications
- (void) registerNotificationObservers;

#pragma mark ***Interface Management
- (void) updateWindow;
- (void) baseAddressChanged:(NSNotification*) aNote;
- (void) writeValueChanged: (NSNotification*) aNote;
- (void) selectedRegIndexChanged: (NSNotification*) aNote;
- (void) selectedRegChannelChanged:(NSNotification*) aNote;
- (void) enabledMaskChanged:(NSNotification*)aNote;
- (void) postTriggerSettingChanged:(NSNotification*)aNote;
- (void) triggerSourceMaskChanged:(NSNotification*)aNote;
- (void) coincidenceLevelChanged:(NSNotification*)aNote;
- (void) basicLockChanged:(NSNotification*)aNote;
- (void) acquisitionModeChanged:(NSNotification*)aNote;
- (void) countAllTriggersChanged:(NSNotification*)aNote;
- (void) customSizeChanged:(NSNotification*)aNote;
- (void) channelConfigMaskChanged:(NSNotification*)aNote;
- (void) dacChanged: (NSNotification*) aNote;
- (void) overUnderChanged: (NSNotification*) aNote;
- (void) basicLockChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) thresholdChanged: (NSNotification*) aNotification;

#pragma mark •••Actions
- (IBAction) baseAddressAction: (id) aSender;
- (IBAction) writeValueAction: (id) aSender;
- (IBAction) selectRegisterAction: (id) aSender;
- (IBAction) selectChannelAction: (id) aSender;

- (IBAction) read: (id) sender;
- (IBAction) write: (id) sender;
- (IBAction) basicLockAction:(id)sender;
- (IBAction) settingsLockAction:(id)sender;
- (IBAction) enabledMaskAction:(id)sender;
- (IBAction) postTriggerSettingTextFieldAction:(id)sender;
- (IBAction) triggerSourceMaskAction:(id)sender;
- (IBAction) coincidenceLevelTextFieldAction:(id)sender;
- (IBAction) generateTriggerAction:(id)sender;
- (IBAction) acquisitionModeAction:(id)sender;
- (IBAction) countAllTriggersAction:(id)sender;
- (IBAction) customSizeAction:(id)sender;
- (IBAction) channelConfigMaskAction:(id)sender;
- (IBAction) dacAction: (id) aSender;
- (IBAction) thresholdAction: (id) aSender;

#pragma mark •••Misc Helpers
- (void)    populatePullDown;
- (void)    updateRegisterDescription: (short) aRegisterIndex;
- (void)    tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;


@end
