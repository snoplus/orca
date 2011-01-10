//
//  ORMPodCController.h
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORMPodCController.h"
#import "ORMPodCModel.h"

@implementation ORMPodCController
- (id) init
{
    self = [ super initWithWindowNibName: @"MPodC" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORMPodCModelLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(pingTaskChanged:)
						 name : ORMPodCPingTask
					   object : model];

	[notifyCenter addObserver : self
					 selector : @selector(ipNumberChanged:)
						 name : MPodCIPNumberChanged
					   object : model];
	
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[ipNumberComboBox reloadData];
}

- (void) updateWindow
{
    [ super updateWindow ];
	[self ipNumberChanged:nil];
    [self lockChanged:nil];
    [self pingTaskChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMPodCModelLock to:secure];
    [lockButton setEnabled:secure];
}

#pragma mark •••Notifications

- (void) lockChanged:(NSNotification*)aNote
{   
	BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL locked = [gSecurity isLocked:ORMPodCModelLock];
    [lockButton setState: locked];
	[pingButton setEnabled:!locked && !runInProgress];
    [ipNumberComboBox setEnabled:!locked];

}
- (void) pingTaskChanged:(NSNotification*)aNote
{
	BOOL pingRunning = [model pingTaskRunning];
	if(pingRunning)[pingTaskProgress startAnimation:self];
	else [pingTaskProgress stopAnimation:self];
	[pingButton setTitle:pingRunning?@"Stop":@"Send Ping"];
}

- (void) ipNumberChanged:(NSNotification*)aNote
{
	[ipNumberComboBox setStringValue:[model IPNumber]];
}

#pragma mark •••Actions

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORMPodCModelLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) ping:(id)sender
{
	@try {
		[model ping];
	}
	@catch (NSException* localException) {
	}
}

- (IBAction) ipNumberAction:(id)sender
{
	[model setIPNumber:[sender stringValue]];
}

- (IBAction) testAction:(id)sender
{
	[model openSession];
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