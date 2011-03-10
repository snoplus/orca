//
//  ORXLGPSController.m
//  ORCA
//
//  Created by Jarek Kaspar on November 2, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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
#import "ORXLGPSController.h"
#import "ORXLGPSModel.h"

@implementation ORXLGPSController

#pragma mark •••Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"XLGPS"];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[ipNumberComboBox reloadData];
	[self updateWindow];
}	

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];

	[notifyCenter addObserver : self
			 selector : @selector(lockChanged:)
			     name : ORRunStatusChangedNotification
			   object : nil];
	
	[notifyCenter addObserver : self
			 selector : @selector(lockChanged:)
			     name : ORXLGPSModelLock
			    object: nil];
	
	[notifyCenter addObserver : self
			 selector : @selector(ipNumberChanged:)
			     name : ORXLGPSIPNumberChanged
			   object : model];
	
	[notifyCenter addObserver : self
			 selector : @selector(userChanged:)
			     name : ORXLGPSModelUserNameChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(passwordChanged:)
			     name : ORXLGPSModelPasswordChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(timeOutChanged:)
			     name : ORXLGPSModelTimeOutChanged
			   object : model];
}


#pragma mark •••Interface Management
- (void) updateWindow
{
	[super updateWindow];
	
	[self lockChanged:nil];
	[self ipNumberChanged:nil];
	[self userChanged:nil];
	[self passwordChanged:nil];
	[self timeOutChanged:nil];
}

- (void) checkGlobalSecurity
{
	BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
	[gSecurity setLock:ORXLGPSModelLock to:secure];
	[lockButton setEnabled:secure];
	[self updateButtons];
}

- (void) lockChanged:(NSNotification*)aNote
{   
	BOOL locked = [gSecurity isLocked:ORXLGPSModelLock];
	[lockButton setState: locked];
	[self updateButtons];
}

- (void) updateButtons
{
	BOOL locked	= [gSecurity isLocked:ORXLGPSModelLock];
	//BOOL busy	= NO; //[model isBusy];

	[ipNumberComboBox setEnabled: !locked];
	[clrHistoryButton setEnabled: !locked];
	[userField setEnabled: !locked];
	[passwordField setEnabled: !locked];
	[timeOutPU setEnabled: !locked];
	//[sendButton setEnabled: !locked && !busy];
}

- (void) ipNumberChanged:(NSNotification*)aNote
{
	[ipNumberComboBox setStringValue:[model IPNumber]];
}

- (void) userChanged:(NSNotification*)aNote
{
	[userField setStringValue: [model userName]];
}

- (void) passwordChanged:(NSNotification*)aNote
{
	[passwordField setStringValue: [model password]];
}

- (void) timeOutChanged:(NSNotification*)aNote
{
	[timeOutPU selectItemWithTag:[model timeOut]];
}


#pragma mark •••Actions
- (IBAction) lockAction:(id) sender
{
	[gSecurity tryToSetLock:ORXLGPSModelLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) opsAction:(id) sender
{
}

- (IBAction) ipNumberAction:(id)sender
{
	[model setIPNumber:[sender stringValue]];
}

- (IBAction) clearHistoryAction:(id)sender
{
	[model clearConnectionHistory];
}

- (IBAction) userFieldAction:(id)sender
{
	[model setUserName:[sender stringValue]];	
}

- (IBAction) passwordFieldAction:(id)sender
{
	[model setPassword:[sender stringValue]];	
}

- (IBAction) timeOutAction:(id)sender
{
	[model setTimeOut:[[sender selectedItem] tag]];
}

#pragma mark •••Data Source
- (NSInteger ) numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	return  [model connectionHistoryCount];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
	return [model connectionHistoryItem:index];
}

@end
