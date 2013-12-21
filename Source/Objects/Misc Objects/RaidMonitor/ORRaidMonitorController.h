//-------------------------------------------------------------------------
//  ORRaidMonitorController.h
//
//  Created by Mark Howe on Saturday 12/21/2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h"

@interface ORRaidMonitorController : OrcaObjectController {
@private
	IBOutlet NSTextField*       userNameField;
	IBOutlet NSTextField*       resultStringField;
	IBOutlet NSTextField*       localPathField;
	IBOutlet NSTextField*       remotePathField;
	IBOutlet NSTextField*       ipAddressField;
	IBOutlet NSSecureTextField* passwordField;
    IBOutlet NSButton*          lockButton;

}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) resultStringChanged:(NSNotification*)aNote;
- (void) localPathChanged:(NSNotification*)aNote;
- (void) remotePathChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) passwordChanged:(NSNotification*)aNote;
- (void) userNameChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) testAction:(id)sender;
- (IBAction) localPathAction:(id)sender;
- (IBAction) remotePathAction:(id)sender;
- (IBAction) ipAddressAction:(id)sender;
- (IBAction) passwordAction:(id)sender;
- (IBAction) userNameAction:(id)sender;
- (IBAction) lockAction:(id)sender;

@end
