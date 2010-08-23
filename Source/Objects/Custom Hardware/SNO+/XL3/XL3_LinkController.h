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
	IBOutlet NSButton*		lockButton;
	//basic
	IBOutlet NSPopUpButton*		selectedRegisterPU;
	IBOutlet NSButton*		basicReadButton;
	IBOutlet NSButton*		basicWriteButton;
	IBOutlet NSButton*		basicStopButton;
	IBOutlet NSButton*		basicStatusButton;
	IBOutlet NSProgressIndicator*	basicOpsRunningIndicator;
	IBOutlet NSButton*		autoIncrementCB;
	IBOutlet NSTextField*		repeatDelayField;
	IBOutlet NSStepper*		repeatDelayStepper;
	IBOutlet NSTextField*		repeatCountField;
	IBOutlet NSStepper*		repeatCountStepper;
	IBOutlet NSTextField*		writeValueField;
	IBOutlet NSStepper*		writeValueStepper;
	//composite
	IBOutlet NSProgressIndicator*	deselectCompositeRunningIndicator;
	IBOutlet NSMatrix*		compositeSlotMaskMatrix;
	IBOutlet NSTextField*		compositeSlotMaskField;
	IBOutlet NSPopUpButton*		compositeXl3ModePU;
	IBOutlet NSButton*		compositeSetXl3ModeButton;
	IBOutlet NSProgressIndicator*	compositeXl3ModeRunningIndicator;

	//connection
	IBOutlet NSButton*		toggleConnectButton;
	IBOutlet NSPopUpButton*		errorTimeOutPU;
}	

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;
- (void) setModel:(id)aModel;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) xl3LockChanged:(NSNotification*)aNotification;
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
- (void) compositeDeselectRunningChanged:(NSNotification*)aNote;
//ip connection
- (void) connectStateChanged:(NSNotification*)aNote;
- (void) ipNumberChanged:(NSNotification*)aNote;
- (void) linkConnectionChanged:(NSNotification*)aNote;
- (void) errorTimeOutChanged:(NSNotification*)aNote;

#pragma mark •••Helper
- (void) populatePullDown;

#pragma mark •••Actions
- (IBAction) lockAction:(id)sender;
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
- (IBAction) compositeSlotMaskAction:(id) sender;
- (IBAction) compositeSlotMaskFieldAction:(id) sender;
- (IBAction) compositeSlotMaskSelectAction:(id) sender;
- (IBAction) compositeSlotMaskDeselectAction:(id) sender;
- (IBAction) compositeSlotMaskPresentAction:(id) sender;
- (IBAction) compositeDeselectAction:(id) sender;
- (IBAction) compositeXl3ModeAction:(id) sender;
- (IBAction) compositeXl3ModeSetAction:(id) sender;
//connection
- (IBAction) toggleConnectAction:(id)sender;
- (IBAction) errorTimeOutAction:(id)sender;

@end
