//
//  ORHeartbeatCheckerController.m
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
#import "ORHeartbeatCheckerController.h"
#import "ORHeartbeatCheckerModel.h"


@implementation ORHeartbeatCheckerController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"HeartbeatChecker"];
    return self;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(cycleTimeChanged:)
                         name : ORHeartbeatCheckerCycleTimeChanged
                       object : model];
    

    [notifyCenter addObserver: self
                     selector: @selector(pulserLockChanged:)
                         name: ORHeartbeatCheckerLock
                       object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(remoteHostNameChanged:)
                         name : ORHeartbeatCheckerHostChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(remotePortChanged:)
                         name : ORHeartbeatCheckerPortChanged
                       object : model];

}

#pragma mark •••Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self cycleTimeChanged:nil];
    [self pulserLockChanged:nil];
	[self remoteHostNameChanged:nil];
	[self remoteHostNameChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORHeartbeatCheckerLock to:secure];
    [pulserLockButton setEnabled:secure];
}

- (void) pulserLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORHeartbeatCheckerLock];
    [pulserLockButton setState: locked];
    [cycleTimeField setEnabled: !locked];
    [remoteHostField setEnabled:!locked];
    [remotePortField setEnabled:!locked];
}
- (void) remoteHostNameChanged:(NSNotification*)aNote
{
	[remoteHostField setStringValue:[model remoteHost]];
}

- (void) remotePortChanged:(NSNotification*)aNote
{
	[remotePortField setIntValue:[model remotePort]];
}

- (void) cycleTimeChanged:(NSNotification*)aNote;
{
	[cycleTimeField setFloatValue:[model cycleTime]];
}

#pragma mark •••Actions
- (void) cycleTimeAction:(id)sender
{
    [model setCycleTime:[sender floatValue]];
}

-(IBAction)pulserLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORHeartbeatCheckerLock to:[sender intValue] forWindow:[self window]];
}
- (IBAction) remoteHostNameAction:(id)sender
{
	[model setRemoteHost:[sender stringValue]];
}

- (IBAction) remotePortAction:(id)sender
{
	[model setRemotePort:[sender intValue]];
}


@end
