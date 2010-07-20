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
	IBOutlet NSButton*	lockButton;
	//basic
	IBOutlet NSPopUpButton* selectedRegisterPU;

	//composite

	//connection
	IBOutlet NSButton*      toggleConnectButton;

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
- (void) connectStateChanged:(NSNotification*)aNote;
- (void) selectedRegisterChanged:(NSNotification*)aNote;
- (void) ipNumberChanged:(NSNotification*)aNote;
- (void) linkConnectionChanged:(NSNotification*)aNote;

#pragma mark •••Helper
- (void) populatePullDown;

#pragma mark •••Actions
- (IBAction) lockAction:(id)sender;
//basic
- (IBAction) basicSelectedRegisterAction:(id)sender;
//composite
//connection
- (IBAction) toggleConnectAction:(id)sender;

@end
