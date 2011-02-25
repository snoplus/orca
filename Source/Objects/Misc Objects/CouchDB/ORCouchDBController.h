//
//  ORCouchDBController.h
//  Orca
//
//  Created by Mark Howe on 10/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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
#import "ORValueBar.h"

@interface ORCouchDBController : OrcaObjectController 
{	
	IBOutlet NSTextField* hostNameField;
	IBOutlet NSTextField* userNameField;
	IBOutlet NSTextField* passwordField;
	IBOutlet NSTextField* dataBaseNameField;
    IBOutlet NSButton*    couchDBLockButton;
    IBOutlet ORValueBar*  queueValueBar;
	IBOutlet NSButton*	  stealthModeButton;
	IBOutlet NSTextField* dbSizeField;
	double queueCount;
}

#pragma mark ***Interface Management
- (void) registerNotificationObservers;
- (void) stealthModeChanged:(NSNotification*)aNote;
- (void) hostNameChanged:(NSNotification*)aNote;
- (void) userNameChanged:(NSNotification*)aNote;
- (void) passwordChanged:(NSNotification*)aNote;
- (void) dataBaseNameChanged:(NSNotification*)aNote;
- (void) couchDBLockChanged:(NSNotification*)aNote;
- (void) setQueCount:(NSNumber*)n;
- (void) dataBaseInfoChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) stealthModeAction:(id)sender;
- (IBAction) hostNameAction:(id)sender;
- (IBAction) userNameAction:(id)sender;
- (IBAction) passwordAction:(id)sender;
- (IBAction) couchDBLockAction:(id)sender;
- (IBAction) createAction:(id)sender;
- (IBAction) deleteAction:(id)sender;
- (IBAction) listAction:(id)sender;
- (IBAction) infoAction:(id)sender;
- (IBAction) compactAction:(id)sender;

- (IBAction) testAction:(id)sender;


@end
