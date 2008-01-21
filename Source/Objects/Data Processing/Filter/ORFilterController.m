//
//  ORFilterController.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORFilterController.h"
#import "ORFilterModel.h"

@implementation ORFilterController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Filter"];
	return self;
}



#pragma mark •••Accessors

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
    
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORFilterLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
}

#pragma mark •••Actions
- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORFilterLock to:secure];
    [lockButton setEnabled:secure];
}
- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORFilterLock to:[sender intValue] forWindow:[self window]];
}


#pragma mark •••Interface Management
- (void) updateWindow
{
    [super updateWindow];
	
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORFilterLock];
    [lockButton setState: locked];
    
}

#pragma mark •••Data Source Methods

@end
