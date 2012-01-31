//
//  XL3_LinkController.h
//  ORCA
//
//  Created by Jarek Kaspar on Sat, Jul 9, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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

#import "OrcaObjectController.h"

@interface XL3_LinkController : OrcaObjectController
{
	NSView* blankView;
    IBOutlet NSView* xl3View;
	NSSize  basicSize;
	NSSize  compositeSize;
	IBOutlet NSTabView*		tabView;
	IBOutlet NSButton*		lockButton;
	//basic
	IBOutlet NSButton*              basicLockButton;
	IBOutlet NSPopUpButton*         selectedRegisterPU;
	IBOutlet NSButton*              basicReadButton;
	IBOutlet NSButton*              basicWriteButton;
	IBOutlet NSButton*              basicStopButton;
	IBOutlet NSButton*              basicStatusButton;
	IBOutlet NSProgressIndicator*	basicOpsRunningIndicator;
	IBOutlet NSButton*		autoIncrementCB;
	IBOutlet NSTextField*		repeatDelayField;
	IBOutlet NSStepper*		repeatDelayStepper;
	IBOutlet NSTextField*		repeatCountField;
	IBOutlet NSStepper*		repeatCountStepper;
	IBOutlet NSTextField*		writeValueField;
	IBOutlet NSStepper*		writeValueStepper;
	//composite
	IBOutlet NSButton*              compositeLockButton;
	IBOutlet NSProgressIndicator*	deselectCompositeRunningIndicator;
	IBOutlet NSButton*              compositeDeselectButton;
	IBOutlet NSMatrix*              compositeSlotMaskMatrix;
	IBOutlet NSTextField*           compositeSlotMaskField;
	IBOutlet NSPopUpButton*         compositeXl3ModePU;
	IBOutlet NSButton*              compositeSetXl3ModeButton;
	IBOutlet NSProgressIndicator*	compositeXl3ModeRunningIndicator;
	IBOutlet NSTextField*           compositeXl3RWAddressValueField;
	IBOutlet NSPopUpButton*         compositeXl3RWModePU;
	IBOutlet NSPopUpButton*         compositeXl3RWSelectPU;
	IBOutlet NSPopUpButton*         compositeXl3RWRegisterPU;
	IBOutlet NSTextField*           compositeXl3RWDataValueField;	
	IBOutlet NSButton*              compositeXl3RWButton;	
	IBOutlet NSProgressIndicator*	compositeXl3RWRunningIndicator;
	IBOutlet NSButton*              compositeQuitButton;	
	IBOutlet NSProgressIndicator*	compositeQuitRunningIndicator;
	IBOutlet NSTextField*           compositeSetPedestalField;	
	IBOutlet NSButton*              compositeSetPedestalButton;	
	IBOutlet NSProgressIndicator*	compositeSetPedestalRunningIndicator;
	IBOutlet NSButton*              compositeBoardIDButton;	
	IBOutlet NSProgressIndicator*	compositeBoardIDRunningIndicator;
	IBOutlet NSButton*              compositeResetCrateButton;	
	IBOutlet NSProgressIndicator*	compositeResetCrateRunningIndicator;
	IBOutlet NSButton*              compositeResetCrateAndXilinXButton;	
	IBOutlet NSProgressIndicator*	compositeResetCrateAndXilinXRunningIndicator;
	IBOutlet NSButton*              compositeResetFIFOAndSequencerButton;	
	IBOutlet NSProgressIndicator*	compositeResetFIFOAndSequencerRunningIndicator;
	IBOutlet NSButton*              compositeResetXL3StateMachineButton;	
	IBOutlet NSProgressIndicator*	compositeResetXL3StateMachineRunningIndicator;
	IBOutlet NSTextField*           compositeChargeInjMaskField;
	IBOutlet NSTextField*           compositeChargeInjChargeField;
	IBOutlet NSButton*              compositeChargeInjButton;
	IBOutlet NSProgressIndicator*	compositeChargeRunningIndicator;
	//connection
	IBOutlet NSButton*              toggleConnectButton;
	IBOutlet NSPopUpButton*         errorTimeOutPU;
    IBOutlet NSTextField*           connectionIPAddressField;
    IBOutlet NSTextField*           connectionIPPortField;
    IBOutlet NSTextField*           connectionCrateNumberField;
    IBOutlet NSButton*              connectionAutoConnectButton;
    IBOutlet NSButton*              connectionAutoInitCrateButton;
}	

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;
- (void) setModel:(id)aModel;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) checkGlobalSecurity;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item;

#pragma mark •••Interface Management
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) xl3LockChanged:(NSNotification*)aNotification;
- (void) opsRunningChanged:(NSNotification*)aNote;
//basic ops
- (void) selectedRegisterChanged:(NSNotification*)aNote;
- (void) repeatCountChanged:(NSNotification*)aNote;
- (void) repeatDelayChanged:(NSNotification*)aNote;
- (void) autoIncrementChanged:(NSNotification*)aNote;
- (void) basicOpsRunningChanged:(NSNotification*)aNote;
- (void) writeValueChanged:(NSNotification*)aNote;
//composite
- (void) compositeXl3ModeRunningChanged:(NSNotification*)aNote;
- (void) compositeXl3ModeChanged:(NSNotification*)aNote;
- (void) compositeSlotMaskChanged:(NSNotification*)aNote;
- (void) compositeXl3RWAddressChanged:(NSNotification*)aNote;
- (void) compositeXL3RWDataChanged:(NSNotification*)aNote;
- (void) compositeXl3PedestalMaskChanged:(NSNotification*)aNote;
- (void) compositeXl3ChargeInjChanged:(NSNotification*)aNote;

//ip connection
- (void) connectStateChanged:(NSNotification*)aNote;
- (void) linkConnectionChanged:(NSNotification*)aNote;
- (void) errorTimeOutChanged:(NSNotification*)aNote;
- (void) connectionAutoConnectChanged:(NSNotification*)aNote;

#pragma mark •••Helper
- (void) populateOps;
- (void) populatePullDown;

#pragma mark •••Actions
- (IBAction) incXL3Action:(id)sender;
- (IBAction) decXL3Action:(id)sender;
- (IBAction) lockAction:(id)sender;
- (IBAction) opsAction:(id)sender;
//basic
- (IBAction) basicSelectedRegisterAction:(id)sender;
- (IBAction) basicReadAction:(id)sender;
- (IBAction) basicWriteAction:(id)sender;
- (IBAction) basicStopAction:(id)sender;
- (IBAction) basicStatusAction:(id) sender;
- (IBAction) repeatCountAction:(id) sender;
- (IBAction) repeatDelayAction:(id) sender;
- (IBAction) autoIncrementAction:(id) sender;
- (IBAction) writeValueAction:(id) sender;
//composite
- (IBAction) compositeSlotMaskAction:(id)sender;
- (IBAction) compositeSlotMaskFieldAction:(id)sender;
- (IBAction) compositeSlotMaskSelectAction:(id)sender;
- (IBAction) compositeSlotMaskDeselectAction:(id)sender;
- (IBAction) compositeSlotMaskPresentAction:(id)sender;
- (IBAction) compositeXl3ModeAction:(id)sender;
- (IBAction) compositeXl3ModeSetAction:(id)sender;
- (IBAction) compositeXl3RWAddressValueAction:(id)sender;
- (IBAction) compositeXl3RWModeAction:(id)sender;
- (IBAction) compositeXl3RWSelectAction:(id)sender;
- (IBAction) compositeXl3RWRegisterAction:(id)sender;
- (IBAction) compositeXl3RWDataValueAction:(id)sender;
- (IBAction) compositeSetPedestalValue:(id)sender;
- (IBAction) compositeXl3ChargeInjMaskAction:(id)sender;
- (IBAction) compositeXl3ChargeInjChargeAction:(id)sender;
//connection
- (IBAction) toggleConnectAction:(id)sender;
- (IBAction) errorTimeOutAction:(id)sender;
- (IBAction) connectionAutoConnectAction:(id)sender;

@end
