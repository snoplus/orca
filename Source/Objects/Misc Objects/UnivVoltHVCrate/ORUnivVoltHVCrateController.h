//
//  ORUnivVoltHVCrateController.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files

#import "ORCrateController.h"

#pragma mark •••Forward Declarations
@class ORGroup;
@class ORGroupView;

@interface ORUnivVoltHVCrateController : ORCrateController
{
    IBOutlet NSButton*		ethernetConnectButton;
	IBOutlet NSScrollView*	outputArea;
	IBOutlet NSTextField*	ipAddress;
	IBOutlet NSTextField*	hvStatusField;
}

#pragma mark *Accessors

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) isConnectedChanged: (NSNotification *) aNote;

#pragma mark •••Actions
- (IBAction) connectAction: (id) aSender;
//- (IBAction) hvOn: (id) aSender;
//- (IBAction) hvOff: (id) aSender;
//- (IBAction) panicOff: (id) aSender;
//- (IBAction) setInhibitOffAction:(id)sender;
//- (IBAction) showConfig: (id) aSender;
- (IBAction) showHVStatusAction: (id) aSender;
- (void) showError: (NSException*) anException name: (NSString*)name;
@end
