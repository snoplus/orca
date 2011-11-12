//
//  ORTTCPX400DPController.h
//  Orca
//
//  Created by Michael Marino on Saturday 12 Nov 2011
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

#import "ORTTCPX400DPController.h"
#import "ORTTCPX400DPModel.h"

@implementation ORTTCPX400DPController
- (id) init
{
    self = [ super initWithWindowNibName: @"TTCPX400DP" ];
    return self;
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"TT CPX400DP  %@",[model serialNumber]]];
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
						 name : ORTTCPX400DPModelLock
						object: nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(ipChanged:)
						 name : ORTTCPX400DPIpHasChanged
						object: nil];    
}

- (void) awakeFromNib
{
	[super awakeFromNib];
//	[ipNumberComboBox reloadData];
}

- (void) updateWindow
{
    [ super updateWindow ];
    [self lockChanged:nil];
    [self ipChanged:nil];
}

#pragma mark •••Notifications
- (void) lockChanged:(NSNotification*)aNote
{   
    BOOL locked = [gSecurity isLocked:ORTTCPX400DPModelLock];
    [lockButton setState: locked];
}

- (void) ipChanged:(NSNotification*)aNote
{   
    [ipAddressBox setStringValue:[model ipAddress]];
}


#pragma mark •••Actions
- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORTTCPX400DPModelLock to:[sender intValue] forWindow:[self window]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORTTCPX400DPModelLock to:secure];
    [lockButton setEnabled:secure];
	//[self updateButtons];
}

@end


