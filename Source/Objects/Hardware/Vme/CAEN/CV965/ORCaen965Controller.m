/*
 *  ORCaen965Controller.m
 *  Orca
 *
 *  Created by Mark Howe on Thurs May 29 2008.
 *  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
 *
 */
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

#import "ORCaen965Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCaen965Model.h"

@implementation ORCaen965Controller

#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"Caen965" ];
    return self;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [ super registerNotificationObservers ];
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(cardTypeChanged:)
                         name : ORCaen965ModelCardTypeChanged
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(onlineMaskChanged:)
						 name : ORCaen965ModelOnlineMaskChanged
					   object : model];
}

#pragma mark ***Interface Management
- (void) updateWindow
{
	[super updateWindow ];
	[self cardTypeChanged:nil];
    [self onlineMaskChanged:nil];
}

- (void) thresholdLockChanged:(NSNotification*)aNotification
{
	[super thresholdLockChanged:aNotification];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self thresholdLockName]];
    [onlineMaskMatrix setEnabled:!lockedOrRunningMaintenance];
	
}
- (void) cardTypeChanged:(NSNotification*)aNote
{
	[cardTypePU selectItemAtIndex: [model cardType]];
}

- (void) onlineMaskChanged:(NSNotification*)aNotification
{
	short i;
	unsigned short theMask = [model onlineMask];
	for(i=0;i<[model numberOfChannels];i++){
		[[onlineMaskMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
}

#pragma mark ***Interface Management - Module specific
- (NSString*) thresholdLockName {return @"ORCaen965ThresholdLock";}
- (NSString*) basicLockName     {return @"ORCaen965BasicLock";}

#pragma mark •••Actions
- (IBAction) cardTypePUAction:(id)sender
{
	[model setCardType:[sender indexOfSelectedItem]];	
}

- (IBAction) onlineAction:(id)sender
{
	if([sender intValue] != [model onlineMaskBit:[[sender selectedCell] tag]]){
		[model setOnlineMaskBit:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
@end
