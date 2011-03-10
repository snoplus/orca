//
//  ORXLGPSController.h
//  ORCA
//
//  Created by Jarek Kaspar on November 2, 2010.
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

@interface ORXLGPSController : OrcaObjectController
{
	IBOutlet NSButton*		lockButton;
	//telnet
	IBOutlet NSComboBox*		ipNumberComboBox;
	IBOutlet NSButton*		clrHistoryButton;
	IBOutlet NSTextField*		userField;
	IBOutlet NSSecureTextField*	passwordField;
	IBOutlet NSButton*		telnetPingButton;	
	IBOutlet NSProgressIndicator*	telnetPingPI;
	IBOutlet NSButton*		telnetTestButton;	
	IBOutlet NSProgressIndicator*	telnetTestPI;
	IBOutlet NSPopUpButton*		timeOutPU;
	//basic
	//ppo	
}	

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;
- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) updateWindow;
- (void) checkGlobalSecurity;
- (void) lockChanged:(NSNotification*)aNote;
- (void) updateButtons;
- (void) ipNumberChanged:(NSNotification*)aNote;
- (void) userChanged:(NSNotification*)aNote;
- (void) passwordChanged:(NSNotification*)aNote;
- (void) timeOutChanged:(NSNotification*)aNote;

#pragma mark •••Helper

#pragma mark •••Actions
- (IBAction) lockAction:(id) sender;
- (IBAction) opsAction:(id) sender;
//telnet
- (IBAction) ipNumberAction:(id)sender;
- (IBAction) clearHistoryAction:(id)sender;
- (IBAction) userFieldAction:(id)sender;
- (IBAction) passwordFieldAction:(id)sender;
- (IBAction) timeOutAction:(id)sender;
//basic
//ppo
@end
