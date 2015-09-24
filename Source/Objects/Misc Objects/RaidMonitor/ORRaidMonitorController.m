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

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle: [NSString stringWithFormat:@"RAID %lu",[model uniqueIdNumber]]];
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
                     selector : @selector(resultDictionaryChanged:)
                         name : ORRaidMonitorModelResultDictionaryChanged
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
	[self resultDictionaryChanged:nil];
}

#pragma mark •••Interface Management
- (void) resultDictionaryChanged:(NSNotification*)aNote
{
    [self fillIn:lastCheckedField   with:@"lastChecked"];
    [self fillIn:scriptRanField     with:@"scriptRan"];
    
    [self fillIn:statusField        with:@"Status"       from:@"/Data/mjddata"];
    [self fillIn:usedField          with:@"Used"         from:@"/Data/mjddata"];
    [self fillIn:availableField     with:@"Available"    from:@"/Data/mjddata"];
    [self fillIn:usedPercentField   with:@"Used_percent" from:@"/Data/mjddata"];

    [self fillInDisk:disk0          index:0 with:@"raidDrive0"];
    [self fillInDisk:disk1          index:1 with:@"raidDrive1"];
    [self fillInDisk:disk2          index:2 with:@"raidDrive2"];
    [self fillInDisk:disk3          index:3 with:@"raidDrive3"];
    [self fillInDisk:disk4          index:4 with:@"raidDrive4"];
    [self fillInDisk:disk5          index:5 with:@"raidDrive5"];
    [self fillInDisk:disk6          index:6 with:@"raidDrive6"];
    [self fillInDisk:disk7          index:7 with:@"raidDrive7"];
    [self fillInDisk:disk8          index:8 with:@"raidDrive8"];
    [self fillInDisk:disk9          index:9 with:@"raidDrive9"];
    [self fillInDisk:disk10         index:10 with:@"raidDrive10"];
    [self fillInDisk:disk11         index:11 with:@"raidDrive11"];
}

- (void) fillInDisk:(NSTextField*)aField index:(int)anIndex with:(NSString*)aDiskKey
{
    NSDictionary* resultDict = [model resultDictionary];
    NSDictionary* diskDict = [resultDict objectForKey:aDiskKey];
    NSString* status    = [diskDict objectForKey:@"Status"];
    NSString* operation = [diskDict objectForKey:@"Operation"];
    if(!status)status = @"?";
    if(!operation)operation = @"?";
    
    NSString* s = [NSString stringWithFormat:@"%2d: %@/%@",anIndex,operation,status];
    NSColor* aColor = [NSColor blackColor];
    if([status isEqualToString:@"Offline"])aColor = [NSColor redColor];
    [aField setStringValue: s];
    [aField setTextColor:aColor];
}

- (void) fillIn:(NSTextField*)aField with:(NSString*)aString
{
    NSDictionary* resultDict = [model resultDictionary];
    NSString* s = [resultDict objectForKey:aString];
    if([s length]==0)s = @"?";
    [aField setStringValue: s];
}

- (void) fillIn:(NSTextField*)aField with:(NSString*)aString from:(NSString*)dictionaryKey
{
    NSDictionary* resultDict = [model resultDictionary];
    NSDictionary* subDictionary = [resultDict objectForKey:dictionaryKey];
    NSString* s = [subDictionary objectForKey:aString];
    if([s length]==0)s = @"?";
    [aField setStringValue: s];
 
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
