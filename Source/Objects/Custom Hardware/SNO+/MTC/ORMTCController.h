//
//  ORMTCController.h
//  Orca
//
//Created by Mark Howe on Fri, May 2, 2008
//Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

@interface ORMTCController : OrcaObjectController {

    IBOutlet NSTabView*		tabView;
	IBOutlet NSProgressIndicator* basicOpsRunningIndicator;
	IBOutlet NSButton*		autoIncrementCB;
	IBOutlet NSMatrix*		useMemoryMatrix;
	IBOutlet NSTextField*	repeatDelayTextField;
	IBOutlet NSStepper*		repeatDelayStepper;
	IBOutlet NSTextField*	repeatCountTextField;
	IBOutlet NSStepper*		repeatCountStepper;
	IBOutlet NSTextField*	writeValueTextField;
	IBOutlet NSStepper*		writeValueStepper;
	IBOutlet NSTextField*	memoryOffsetTextField;
	IBOutlet NSStepper*		memoryOffsetStepper;
	IBOutlet NSPopUpButton* selectedRegisterPU;
	IBOutlet NSTextField*	loadFilePathField;
    IBOutlet NSTextField*   slotField;
    IBOutlet NSStepper* 	regBaseAddressStepper;
    IBOutlet NSTextField* 	regBaseAddressText;
    IBOutlet NSStepper* 	memBaseAddressStepper;
    IBOutlet NSTextField* 	memBaseAddressText;
	IBOutlet NSButton*		settingLockButton;
 }

- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) basicOpsRunningChanged:(NSNotification*)aNote;
- (void) autoIncrementChanged:(NSNotification*)aNote;
- (void) useMemoryChanged:(NSNotification*)aNote;
- (void) repeatDelayChanged:(NSNotification*)aNote;
- (void) repeatCountChanged:(NSNotification*)aNote;
- (void) writeValueChanged:(NSNotification*)aNote;
- (void) memoryOffsetChanged:(NSNotification*)aNote;
- (void) selectedRegisterChanged:(NSNotification*)aNote;
- (void) loadFilePathChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) regBaseAddressChanged:(NSNotification*)aNotification;
- (void) memBaseAddressChanged:(NSNotification*)aNotification;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item;


#pragma mark •••Actions
- (IBAction) autoIncrementAction:(id)sender;
- (IBAction) useMemoryAction:(id)sender;
- (IBAction) repeatDelayTextFieldAction:(id)sender;
- (IBAction) repeatCountTextFieldAction:(id)sender;
- (IBAction) writeValueTextFieldAction:(id)sender;
- (IBAction) memoryOffsetTextFieldAction:(id)sender;
- (IBAction) selectedRegisterAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) readAction:(id) sender;
- (IBAction) writeAction:(id) sender;
- (IBAction) stopAction:(id) sender;
- (IBAction) statusReportAction:(id) sender;

#pragma mark •••Helper
- (void) populatePullDown;

@end
