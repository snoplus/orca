//
//  ORHPNplHVController.m
//  Orca
//
//  Created by Mark Howe on Thurs Dec 6 2007
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORNplHVController.h"
#import "ORNplHVModel.h"

@implementation ORNplHVController
- (id) init
{
    self = [ super initWithWindowNibName: @"NplHV" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORNplHVModelIpAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isConnectedChanged:)
                         name : ORNplHVModelIsConnectedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cmdStringChanged:)
                         name : ORNplHVModelCmdStringChanged
						object: model];

}


- (void) updateWindow
{
    [ super updateWindow ];
    
	[self ipAddressChanged:nil];
	[self isConnectedChanged:nil];
	[self cmdStringChanged:nil];
}

- (void) cmdStringChanged:(NSNotification*)aNote
{
	[cmdStringTextField setObjectValue: [model cmdString]];
}

#pragma mark •••Notifications
- (void) isConnectedChanged:(NSNotification*)aNote
{
	[ipConnectedTextField setStringValue: [model isConnected]?@"Connected":@"Not Connected"];
	[ipConnectButton setTitle:[model isConnected]?@"Disconnect":@"Connect"];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
}


- (void) setButtonStates
{

    BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:[model dialogLock]] || [model lockGUI];

	[ipConnectButton setEnabled:!runInProgress || !locked];
	[ipAddressTextField setEnabled:!locked];
}

#pragma mark •••Actions

- (void) cmdStringTextFieldAction:(id)sender
{
	[model setCmdString:[sender objectValue]];	
}

- (void) ipAddressTextFieldAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

- (IBAction) connectAction:(id)sender
{
	[model connect];
}

- (IBAction) sendCmdAction:(id)sender
{
	[model sendCmd:[model cmdString]];
}

@end
