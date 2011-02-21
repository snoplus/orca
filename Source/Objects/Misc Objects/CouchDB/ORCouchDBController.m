//
//  ORCouchDBController.m
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


#import "ORCouchDBController.h"
#import "ORCouchDBModel.h"
#import "ORCouchDB.h"

@interface ORCouchDBController (private)
- (void) createActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (void) deleteActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
@end

@implementation ORCouchDBController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"CouchDB"];
    return self;
}

- (void) dealloc
{
	[[ORCouchDBQueue sharedCouchDBQueue] removeObserver:self forKeyPath:@"operations"];
	[super dealloc];
}

-(void) awakeFromNib
{
	[super awakeFromNib];
	[[ORCouchDBQueue queue] addObserver:self forKeyPath:@"operations" options:0 context:NULL];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
	NSOperationQueue* queue = [ORCouchDBQueue queue];
    if (object == queue && [keyPath isEqual:@"operations"]) {
		NSNumber* n = [NSNumber numberWithInt:[[[ORCouchDBQueue queue] operations] count]];
		[self performSelectorOnMainThread:@selector(setQueCount:) withObject:n waitUntilDone:NO];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) setQueCount:(NSNumber*)n
{
	queueCount = [n intValue];
	[queueValueBar setNeedsDisplay:YES];
}

- (double) doubleValue
{
	return queueCount;
}

#pragma mark •••Registration
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(hostNameChanged:)
                         name : ORCouchDBHostNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(userNameChanged:)
                         name : ORCouchDBUserNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(passwordChanged:)
                         name : ORCouchDBPasswordChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataBaseNameChanged:)
                         name : ORCouchDBDataBaseNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(couchDBLockChanged:)
                         name : ORCouchDBLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(couchDBLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(stealthModeChanged:)
                         name : ORCouchDBModelStealthModeChanged
						object: model];
}

- (void) updateWindow
{
	[super updateWindow];
	[self hostNameChanged:nil];
	[self userNameChanged:nil];
	[self passwordChanged:nil];
	[self dataBaseNameChanged:nil];
    [self couchDBLockChanged:nil];
	[self stealthModeChanged:nil];
}

- (void) stealthModeChanged:(NSNotification*)aNote
{
	[stealthModeButton setIntValue: [model stealthMode]];
}

- (void) hostNameChanged:(NSNotification*)aNote
{
	if([model hostName])[hostNameField setStringValue:[model hostName]];
}

- (void) userNameChanged:(NSNotification*)aNote
{
	if([model userName])[userNameField setStringValue:[model userName]];
}

- (void) passwordChanged:(NSNotification*)aNote
{
	if([model password])[passwordField setStringValue:[model password]];
}

- (void) dataBaseNameChanged:(NSNotification*)aNote
{
	if([model dataBaseName])[dataBaseNameField setStringValue:[model dataBaseName]];
}
- 
(void) couchDBLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORCouchDBLock];
    [couchDBLockButton setState: locked];
    
    [hostNameField setEnabled:!locked];
    [userNameField setEnabled:!locked];
    [passwordField setEnabled:!locked];
    [dataBaseNameField setEnabled:!locked];
    
}
- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORCouchDBLock to:secure];
    [couchDBLockButton setEnabled: secure];
}

#pragma mark •••Actions

- (IBAction) stealthModeAction:(id)sender
{
	[model setStealthMode:[sender intValue]];	
}

- (IBAction) couchDBLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORCouchDBLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) hostNameAction:(id)sender
{
	[model setHostName:[sender stringValue]];
}

- (IBAction) userNameAction:(id)sender
{
	[model setUserName:[sender stringValue]];
}

- (IBAction) passwordAction:(id)sender
{
	[model setPassword:[sender stringValue]];
}

- (IBAction) databaseNameAction:(id)sender
{
	[model setDataBaseName:[sender stringValue]];
}
- (IBAction) testAction:(id)sender
{
	[model updateFunction];
}


- (IBAction) createAction:(id)sender
{
	[self endEditing];
	NSString* s = [NSString stringWithFormat:@"Really try to create a database named %@ on %@?\n",[model dataBaseName],[model hostName]];
	NSBeginAlertSheet(s,
                      @"Cancel",
                      @"Yes, Create Database",
                      nil,[self window],
                      self,
                      @selector(createActionDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"If the database already exists, this operation will do no harm.");
	
}
- (IBAction) deleteAction:(id)sender
{
	[self endEditing];
	NSString* s = [NSString stringWithFormat:@"Really delete a database named %@ on %@?\n",[model dataBaseName],[model hostName]];
	NSBeginAlertSheet(s,
                      @"Cancel",
                      @"Yes, Delete Database",
                      nil,[self window],
                      self,
                      @selector(deleteActionDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"If the database doesn't exist, this operation will do no harm.");
	
}
- (IBAction) listAction:(id)sender
{
	[model listDatabases];
}

- (IBAction) infoAction:(id)sender
{
	[model databaseInfo];
}

@end

@implementation ORCouchDBController (private)
- (void) createActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	if(returnCode == NSAlertAlternateReturn){		
		[model createDatabase];
	}
}

- (void) deleteActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	if(returnCode == NSAlertAlternateReturn){		
		[model deleteDatabase];
	}
}

@end

