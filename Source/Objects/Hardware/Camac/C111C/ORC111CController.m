/*
 *  ORC111CController.m
 *  Orca
 *
 *  Created by Mark Howe on Mon Dec 10, 2007.
 *  Copyright (c) 2007 CENPA, University of Washington. All rights reserved.
 *
 */
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
#import "ORC111CController.h"
#import "ORC111CModel.h"

@implementation ORC111CController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"C111C"];
    
    return self;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    

   [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORC111CIpAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isConnectedChanged:)
                         name : ORC111CConnectionChanged
						object: model];
}

#pragma mark •••Interface Management

- (void) updateWindow
{
    [super updateWindow];
	[self ipAddressChanged:nil];
	[self isConnectedChanged:nil];
}

- (void) setButtonStates
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    //BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model settingsLock]];
    BOOL locked = [gSecurity isLocked:[model settingsLock]];
    
	[super setButtonStates];

    [ipConnectButton setEnabled:!locked && !runInProgress];
    [ipAddressTextField setEnabled:!locked && !runInProgress];
}

- (void) isConnectedChanged:(NSNotification*)aNote
{
	[ipConnectedTextField setStringValue: [model isConnected]?@"Connected":@"Not Connected"];
	[ipConnectButton setTitle:[model isConnected]?@"Disconnect":@"Connect"];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
}

#pragma mark •••Actions
- (IBAction) ipAddressTextFieldAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

- (IBAction) connectAction:(id)sender
{
	NS_DURING
		if([model isConnected])[model disconnect];
		else [model connect];
	NS_HANDLER
		NSLog(@"%@\n",localException);
	NS_ENDHANDLER
}

@end



