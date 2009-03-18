//
//  ORZupController.m
//  Orca
//
//  Created by Mark Howe on Monday March 16,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORZupController.h"
#import "ORZupModel.h"

@implementation ORZupController
- (id) init
{
    self = [ super initWithWindowNibName: @"Zup" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    basicOpsSize	= NSMakeSize(320,320);
    rampOpsSize		= NSMakeSize(570,710);
    blankView		= [[NSView alloc] init];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORZup%d.selectedtab",[model uniqueIdNumber]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];

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
						 name : ORZupLock
						object: nil];
}


- (void) updateWindow
{
    [ super updateWindow ];
    
    [self lockChanged:nil];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:basicOpsSize];    break;
		case  1: [self resizeWindowToSize:rampOpsSize];	    break;
    }
    [[self window] setContentView:totalView];
            
    NSString* key = [NSString stringWithFormat: @"orca.ORZup%d.selectedtab",[model uniqueIdNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORZupLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self setButtonStates];
}

- (void) updateButtons
{
}




#pragma mark •••Notifications

- (void) setButtonStates
{
    //BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORZupLock];
	int  ramping		= [model runningCount]>0;

    [lockButton setState: locked];
	[sendButton setEnabled:!locked && !ramping];
	[super setButtonStates];
}

- (NSString*) windowNibName
{
	return @"Zup";
}

- (NSString*) rampItemNibFileName
{
	//subclasses can specify a differant RampItem nib file if needed.
	return @"HVRampItem";
}

#pragma mark •••Actions

- (IBAction) sendCmdAction:(id)sender
{
	[self endEditing];
	[model sendCmd];
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORZupLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) version:(id)sender
{
	[model revision];
}

- (IBAction) initBoard:(id) sender
{
	[model initBoard];
}

@end
