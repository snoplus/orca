//-------------------------------------------------------------------------
//  ORXYCom200Controller.h
//
//  Created by Mark A. Howe on Wednesday 9/18/2008.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
#import "OrcaObjectController.h";
#import "ORXYCom200Model.h"

@interface ORXYCom200Controller : OrcaObjectController 
{	
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;
    IBOutlet NSButton*      settingLockButton;
	
    // Register Box
    IBOutlet NSStepper* 	addressStepper;
    IBOutlet NSTextField* 	addressTextField;
    IBOutlet NSStepper* 	writeValueStepper;
    IBOutlet NSTextField* 	writeValueTextField;
    IBOutlet NSPopUpButton*	registerAddressPopUp;
    IBOutlet NSButton*		basicWriteButton;
    IBOutlet NSButton*		basicReadButton;
	IBOutlet NSTextField*	registerOffsetField;
	IBOutlet NSTextField*   regNameField;
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) populatePullDown;

#pragma mark •••Interface Management
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) writeValueChanged: (NSNotification*) aNotification;
- (void) selectedRegIndexChanged: (NSNotification*) aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) updateRegisterDescription:(short) aRegisterIndex;

#pragma mark •••Actions
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) writeValueAction: (id) aSender;
- (IBAction) selectRegisterAction: (id) aSender;

- (IBAction) read: (id) pSender;
- (IBAction) write: (id) pSender;

@end
