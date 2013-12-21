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
#import "ORRaidMonitorController.h"
#import "ORRaidMonitorModel.h"

@implementation ORRaidMonitorController

-(id)init
{
    self = [super initWithWindowNibName:@"RaidMonitor"];
    
    return self;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(userNameChanged:)
                         name : ORRaidMonitorUserNameChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(passwordChanged:)
                         name : ORRaidMonitorPasswordChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORRaidMonitorIpAddressChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRaidMonitorLock
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(remotePathChanged:)
                         name : ORRaidMonitorModelRemotePathChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(localPathChanged:)
                         name : ORRaidMonitorModelLocalPathChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(resultStringChanged:)
                         name : ORRaidMonitorModelResultStringChanged
						object: model];

}

- (void) updateWindow
{
	[super updateWindow];
	[self userNameChanged:nil];
	[self passwordChanged:nil];
	[self ipAddressChanged:nil];
    [self lockChanged:nil];
	[self remotePathChanged:nil];
	[self localPathChanged:nil];
	[self resultStringChanged:nil];
}

#pragma mark •••Interface Management

- (void) resultStringChanged:(NSNotification*)aNote
{
	[resultStringField setStringValue: [model resultString]];
}

- (void) localPathChanged:(NSNotification*)aNote
{
	[localPathField setStringValue: [model localPath]];
}

- (void) remotePathChanged:(NSNotification*)aNote
{
	[remotePathField setStringValue: [model remotePath]];
}
- (void) lockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORRaidMonitorLock];
    [lockButton setState: locked];
    
    [userNameField setEnabled:!locked];
    [ipAddressField setEnabled:!locked];
    [passwordField setEnabled:!locked];
    
}
- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORRaidMonitorLock to:secure];
    [lockButton setEnabled: secure];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressField setStringValue: [model ipAddress]];
}

- (void) passwordChanged:(NSNotification*)aNote
{
	[passwordField setStringValue: [model password]];
}

- (void) userNameChanged:(NSNotification*)aNote
{
	[userNameField setStringValue: [model userName]];
}

#pragma mark •••Actions

- (IBAction) localPathAction:(id)sender
{
	[model setLocalPath:[sender stringValue]];	
}

- (IBAction) remotePathAction:(id)sender
{
	[model setRemotePath:[sender stringValue]];	
}
- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORRaidMonitorLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) ipAddressAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];
}

- (IBAction) passwordAction:(id)sender
{
	[model setPassword:[sender stringValue]];
}

- (IBAction) userNameAction:(id)sender
{
	[model setUserName:[sender stringValue]];
}
- (IBAction) testAction:(id)sender
{
    [model getStatus];
}

@end
