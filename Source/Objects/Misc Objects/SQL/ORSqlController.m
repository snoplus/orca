//
//  ORSqlController.m
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


#import "ORSqlController.h"
#import "ORSqlModel.h"

@implementation ORSqlController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Sql"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

-(void) awakeFromNib
{
	[super awakeFromNib];
}


#pragma mark ¥¥¥Registration
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(hostNameChanged:)
                         name : ORSqlHostNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(userNameChanged:)
                         name : ORSqlUserNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(passwordChanged:)
                         name : ORSqlPasswordChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataBaseNameChanged:)
                         name : ORSqlDataBaseNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(sqlLockChanged:)
                         name : ORSqlLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(sqlLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(connectionValidChanged:)
                         name : ORSqlConnectionValidChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(stealthModeChanged:)
                         name : ORSqlModelStealthModeChanged
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

- (void) stealthModeChanged:(NSNotification*)aNote
{
	[stealthModeButton setIntValue: [model stealthMode]];
}

- (void) connectionValidChanged:(NSNotification*)aNote
{
	[connectionValidField setStringValue:[model connectionValid]?@"Valid":@"?"];
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
    BOOL locked = [gSecurity isLocked:ORSqlLock];
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
    [gSecurity setLock:ORSqlLock to:secure];
    [sqlLockButton setEnabled: secure];
}

#pragma mark ¥¥¥Actions
- (IBAction) stealthModeAction:(id)sender
{
	[model setStealthMode:[sender intValue]];	
}

- (IBAction) sqlLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORSqlLock to:[sender intValue] forWindow:[self window]];
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

- (IBAction) removeEntryAction:(id)sender
{
	[model removeEntry];
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
                      nil,@"If the database and tables already exist, this operation will do no harm.");
	
}

- (void) createActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	if(returnCode == NSAlertAlternateReturn){		
		[model createDatabase];
	}
}
@end
