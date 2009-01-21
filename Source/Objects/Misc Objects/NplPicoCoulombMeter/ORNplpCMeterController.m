//
//  ORHPNplpCMeterController.m
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORNplpCMeterController.h"
#import "ORNplpCMeterModel.h"

@implementation ORNplpCMeterController
- (id) init
{
    self = [ super initWithWindowNibName: @"NplpCMeter" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORNplpCMeterIpAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isConnectedChanged:)
                         name : ORNplpCMeterIsConnectedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(frameErrorChanged:)
                         name : ORNplpCMeterFrameError
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(averageChanged:)
                         name : ORNplpCMeterAverageChanged
						object: model];
						
    [notifyCenter addObserver : self
                     selector : @selector(receiveCountChanged:)
                         name : ORNplpCMeterReceiveCountChanged
						object: model];


    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORNplpCMeterLock
                        object: nil];

}


- (void) updateWindow
{
    [ super updateWindow ];
    
    [self settingsLockChanged:nil];
	[self ipAddressChanged:nil];
	[self isConnectedChanged:nil];
	[self frameErrorChanged:nil];
	[self averageChanged:nil];
	[self receiveCountChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORNplpCMeterLock to:secure];
    [dialogLock setEnabled:secure];
}

- (void) receiveCountChanged:(NSNotification*)aNote
{
	[receiveCountField setIntValue: [model receiveCount]];
}

#pragma mark •••Notifications
- (void) isConnectedChanged:(NSNotification*)aNote
{
	[ipConnectedTextField setStringValue: [model isConnected]?@"Connected":@"Not Connected"];
	[ipConnectButton setTitle:[model isConnected]?@"Disconnect":@"Connect"];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
}

- (void) frameErrorChanged:(NSNotification*)aNote
{
	[frameErrorField setIntValue: [model frameError]];
}

- (void) averageChanged:(NSNotification*)aNote
{
	if(!aNote){
		int chan;
		for(chan=0;chan<kNplpCNumChannels;chan++){
			[[averageValueMatrix cellWithTag:chan] setFloatValue:0];
		}
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[averageValueMatrix cellWithTag:chan] setFloatValue:12*[model meterAverage:chan]/1048576.0]; //12 pC/20bits full scale
	}
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL locked			= [gSecurity isLocked:ORNplpCMeterLock];

	[ipConnectButton setEnabled:!locked];
	[ipAddressTextField setEnabled:!locked];

    [dialogLock setState: locked];

}

#pragma mark •••Actions
- (IBAction) ipAddressTextFieldAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

- (IBAction) connectAction:(id)sender
{
	[self endEditing];
	[model setFrameError:0];
	[model connect];
}

- (IBAction) dialogLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORNplpCMeterLock to:[sender intValue] forWindow:[self window]];
}

@end
