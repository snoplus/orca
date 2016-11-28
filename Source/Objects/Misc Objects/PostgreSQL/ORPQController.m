//
//  ORPQController.m
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


#import "ORPQController.h"
#import "ORPQModel.h"
#import "ORPQConnection.h"
#import "ORValueBarGroupView.h"

@implementation ORPQController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"PostgreSQL"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
	[[[ORPQDBQueue sharedPQDBQueue] queue] removeObserver:self forKeyPath:@"operationCount"];
}

-(void) awakeFromNib
{
	[super awakeFromNib];
	[[[ORPQDBQueue sharedPQDBQueue]queue] addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
}


#pragma mark ¥¥¥Registration
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(hostNameChanged:)
                         name : ORPQHostNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(userNameChanged:)
                         name : ORPQUserNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(passwordChanged:)
                         name : ORPQPasswordChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataBaseNameChanged:)
                         name : ORPQDataBaseNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(sqlLockChanged:)
                         name : ORPQLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(sqlLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(connectionValidChanged:)
                         name : ORPQConnectionValidChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(stealthModeChanged:)
                         name : ORPQModelStealthModeChanged
						object: model];

}

- (void) updateWindow
{
	[super updateWindow];
	[self hostNameChanged:nil];
	[self userNameChanged:nil];
	[self passwordChanged:nil];
	[self dataBaseNameChanged:nil];
	[self connectionValidChanged:nil];
    [self sqlLockChanged:nil];
	[self stealthModeChanged:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
	NSOperationQueue* queue = [[ORPQDBQueue sharedPQDBQueue] queue];
    if (object == queue && [keyPath isEqual:@"operationCount"]) {
		NSNumber* n = [NSNumber numberWithInt:[[[ORPQDBQueue queue] operations] count]];
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

- (void) stealthModeChanged:(NSNotification*)aNote
{
	[stealthModeButton setIntValue: [model stealthMode]];
	[self updateConnectionValidField];
}

- (void) connectionValidChanged:(NSNotification*)aNote
{
	[self updateConnectionValidField];
}

- (void) updateConnectionValidField
{
	[connectionValidField setStringValue:[model stealthMode]?@"Disabled":[model connected]?@"Connected":@"NOT Connected"];
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
(void) sqlLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORPQLock];
    [sqlLockButton setState: locked];
    
    [hostNameField setEnabled:!locked];
    [userNameField setEnabled:!locked];
    [passwordField setEnabled:!locked];
    [dataBaseNameField setEnabled:!locked];
    [connectionButton setEnabled:!locked];
    
}
- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORPQLock to:secure];
    [sqlLockButton setEnabled: secure];
}

#pragma mark ¥¥¥Actions
- (IBAction) stealthModeAction:(id)sender
{
	[model setStealthMode:[sender intValue]];	
}

- (IBAction) sqlLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORPQLock to:[sender intValue] forWindow:[self window]];
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

- (IBAction) connectionAction:(id)sender
{
	[self endEditing];
	[model testConnection];
}

@end
