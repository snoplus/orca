//
//  ORHeartbeatCheckerController.h
//  Orca
//
//  Created by Mark Howe on Tues April 1, 2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
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


#pragma mark •••Imported Files

#import "ORProcessElementController.h"

@interface ORHeartbeatCheckerController : ORProcessElementController 
{
    IBOutlet NSTextField* cycleTimeField; 
    IBOutlet NSButton*    pulserLockButton;
	IBOutlet NSTextField* remoteHostField;
	IBOutlet NSTextField* remotePortField;
}

#pragma mark •••Initialization
- (void) registerNotificationObservers;

#pragma mark •••Actions
- (void) cycleTimeAction:(id)sender;
- (IBAction) pulserLockAction:(id)sender;


#pragma mark •••Interface Management
- (void) cycleTimeChanged:(NSNotification*)aNote;
- (void) pulserLockChanged:(NSNotification *)notification;
- (void) remoteHostNameChanged:(NSNotification*)aNote;
- (void) remotePortChanged:(NSNotification*)aNote;
- (IBAction) remoteHostNameAction:(id)sender;
- (IBAction) remotePortAction:(id)sender;

@end
