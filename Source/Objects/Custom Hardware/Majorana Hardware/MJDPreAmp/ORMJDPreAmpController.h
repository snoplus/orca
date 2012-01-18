//
//  MJDPreAmpController.h
//  Orca
//
//  Created by Mark Howe on Wed Jan 18 2012.
//  Copyright © 2012 University of North Carolina. All rights reserved.
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
#import "OrcaObjectController.h"

@interface ORMJDPreAmpController : OrcaObjectController
{
    @private
		IBOutlet NSButton*      settingsLockButton;
}

#pragma mark ¥¥¥Initialization
- (id)		init;
- (void)	dealloc;
- (void)	awakeFromNib;
- (void)	setModel:(id)aModel;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) updateWindow;
- (void) checkGlobalSecurity;
- (void) settingsLockChanged:(NSNotification *)notification;

#pragma mark ¥¥¥Actions
- (IBAction) settingsLockAction:(id)sender;
- (IBAction) readAction:(id)sender;
- (IBAction) writeAction:(id)sender;
@end
