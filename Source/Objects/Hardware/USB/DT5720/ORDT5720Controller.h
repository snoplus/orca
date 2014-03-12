//
//  ORHPDT5720Controller.h
//  Orca
//
//  Created by Mark Howe on Wed Mar 12,2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina at the Center sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORHPPulserController.h"

@interface ORDT5720Controller : OrcaObjectController 
{
	IBOutlet NSPopUpButton* serialNumberPopup;
	IBOutlet NSButton*		lockButton;
}

#pragma mark •••Initialization
- (id) init;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) settingLockAction:(id) sender;
- (IBAction) serialNumberAction:(id)sender;

- (void) validateInterfacePopup;

@end


