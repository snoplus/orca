//
//  ORGateKeyController.m
//  Orca
//
//  Created by Mark Howe on 1/24/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORGateKeyController.h"
#import "ORGateKey.h"
#import "ORGateKeeper.h"


@implementation ORGateKeyController

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(lowValueChanged:)
                         name : ORGateLowValueChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(highValueChanged:)
                         name : ORGateHighValueChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(acceptTypeChanged:)
                         name : ORGateAcceptTypeChangedNotification
                       object : model];

}

#pragma mark ***Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self lowValueChanged:nil];
    [self highValueChanged:nil];
    [self acceptTypeChanged:nil];    
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    [super settingsLockChanged:aNotification];
    
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGateKeeperSettingsLock];
    
    [lowValueField setEnabled:!lockedOrRunningMaintenance && !ignore];
    [highValueField setEnabled:!lockedOrRunningMaintenance && !ignore];
    [acceptenceMatrix setEnabled:!lockedOrRunningMaintenance && !ignore];
}

- (void) lowValueChanged:(NSNotification*)aNote
{
	[lowValueField setIntValue:[model lowAcceptValue]];
}

- (void) highValueChanged:(NSNotification*)aNote
{
	[highValueField setIntValue:[model highAcceptValue]];
}

- (void) acceptTypeChanged:(NSNotification*)aNote
{
	[acceptenceMatrix selectCellWithTag:[model acceptType]];
}

#pragma mark ***Actions
- (IBAction) lowValueAction:(id)sender
{
    [model setLowAcceptValue:[sender intValue]];
}

- (IBAction) highValueAction:(id)sender
{
    [model setHighAcceptValue:[sender intValue]];
}

- (IBAction) acceptTypeAction:(id)sender
{
    [model setAcceptType:[[sender selectedCell] tag]];
}


@end
