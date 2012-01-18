
//
//  MJDPreAmpController.m
//  Orca
//
//  Created by Mark Howe on Wed Jan 18 2012.
//  Copyright © 2012 University of North Carolina. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORMJDPreAmpController.h"
#import "ORMJDPreAmpModel.h"

@implementation ORMJDPreAmpController

- (id) init
{
    self = [super initWithWindowNibName:@"MJDPreAmp"];
    return self;
}


- (void) dealloc
{
    [super dealloc];
}

- (void)awakeFromNib
{
    [super  awakeFromNib];
	short chan;
	for(chan=0;chan<kMJDPreAmpChannels;chan++){
		[[gainsMatrix cellAtRow:chan column:0] setTag:chan];
	}
}


- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"PreAmp %d",[model uniqueIdNumber]]];
    [self settingsLockChanged:nil];
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
     
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : MJDPreAmpSettingsLock
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(gainArrayChanged:)
                         name : ORMJDPreAmpModelGainArrayChanged
						object: model];

    [notifyCenter addObserver : self
					 selector : @selector(gainChanged:)
						 name : ORMJDPreAmpGainChangedNotification
					   object : model];
}

- (void) updateWindow
{
    [super updateWindow];
    [self settingsLockChanged:nil];
	[self gainArrayChanged:nil];
}

#pragma mark ¥¥¥Interface Management
- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:MJDPreAmpSettingsLock to:secure];
    [settingsLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification *)notification
{
    BOOL locked = [gSecurity isLocked:MJDPreAmpSettingsLock];
    //BOOL runInProgress = [gOrcaGlobals runInProgress];
    //BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:MJDPreAmpSettingsLock];
    //BOOL lockedOrRunning = [gSecurity runInProgressOrIsLocked:MJDPreAmpSettingsLock];
    
    [settingsLockButton setState:locked];
}

- (void) gainChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
	[[gainsMatrix cellWithTag:chan] setIntValue: [model gain:chan]];
}
- (void) gainArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kMJDPreAmpChannels;chan++){
		[[gainsMatrix cellWithTag:chan] setIntValue: [model gain:chan]];
	}
}
#pragma mark ¥¥¥Actions

- (void) gainsAction:(id)sender
{
	[model setGain:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) settingsLockAction:(id)sender
{
    [gSecurity tryToSetLock:MJDPreAmpSettingsLock to:[sender intValue] forWindow:[self window]];
}

//test actions
- (IBAction) readAction:(id)sender
{
	[model readFromHW];
}

- (IBAction) writeAction:(id)sender
{
	[model writeToHW];

}

@end
