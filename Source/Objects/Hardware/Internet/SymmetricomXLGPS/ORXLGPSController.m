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
/*
	basicSize	= NSMakeSize(452,290);
	compositeSize	= NSMakeSize(452,510);
	blankView = [[NSView alloc] init];
	[self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
*/
	[super awakeFromNib];

/*
	NSString* key = [NSString stringWithFormat: @"orca.ORXL3%d.selectedtab",[model crateNumber]]; //uniqueIdNumber?
	int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
	if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;

	[tabView selectTabViewItemAtIndex: index];
	[self populateOps];
	[self populatePullDown];
*/
	[self updateWindow];
}	

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
//	if(aModel) [[self window] setTitle:[model shortName]];
	//[self setDriverInfo];
}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
//	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];

/*
	[notifyCenter addObserver : self
			 selector : @selector(linkConnectionChanged:)
			     name : XL3_LinkConnectionChanged
			    object: [model xl3Link]];
*/
}

- (void) updateWindow
{
	[super updateWindow];
}

- (void) checkGlobalSecurity
{
//	BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
//	[gSecurity setLock:[model gpsLockName] to:secure];
//	[lockButton setEnabled:secure];
}

/*
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
	if([tabView indexOfTabViewItem:item] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:basicSize];
		[[self window] setContentView:tabView];
	}
	else if([tabView indexOfTabViewItem:item] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:compositeSize];
		[[self window] setContentView:tabView];
	}
	else if([tabView indexOfTabViewItem:item] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:basicSize];
		[[self window] setContentView:tabView];
	}
	else if([tabView indexOfTabViewItem:item] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:basicSize];
		[[self window] setContentView:tabView];
	}

 NSString* key = [NSString stringWithFormat: @"orca.ORXL3%d.selectedtab",[model crateNumber]];
	int index = [tabView indexOfTabViewItem:item];
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
}
*/

#pragma mark •••Interface Management
@end
