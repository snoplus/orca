
//
//  ORUnivVoltHVCrateController.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORUnivVoltHVCrateController.h"
#import "ORUnivVoltHVCrateModel.h"
//#import "ORUnivVoltHVBusProtocol.h"
#import "ORUnivVoltHVCrateExceptions.h"

//NSString* ORUnivVoltHVCrateIsConnectedChangedNotification = @"ORUnivVoltHVCrateIsConnectedChangedNotification";
//NSString* ORUnivVoltHVCrateIpAddressChangedNotification = @"ORUnivVoltHVCrateIpAddressChangedNotification";


@implementation ORUnivVoltHVCrateController

- (id) init
{
    self = [super initWithWindowNibName:@"UnivVoltHVCrate"];
    return self;
}

- (void) setCrateTitle
{
	[[self window] setTitle:[NSString stringWithFormat:@"CAMAC crate %d",[model uniqueIdNumber]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    [notifyCenter addObserver : self
                     selector : @selector( isConnectedChanged: )
                         name : ORUnivVoltHVCrateIsConnectedChangedNotification
                       object : model];
					   
					
    [notifyCenter addObserver : self
                     selector : @selector( ipAddressChanged: )
                         name : ORUnivVoltHVCrateIpAddressChangedNotification
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector( displayHVStatus: )
                         name : ORUnivVoltHVStatusAvailableNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector( displayConfig: )
                         name : ORConfigAvailableNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector( displayEnet: )
                         name : OREnetAvailableNotification
                       object : model];
}

- (void) updateWindow
{
    [ super updateWindow ];
    
//    [self settingsLockChanged:nil];
	[self ipAddressChanged: nil];
	[self isConnectedChanged: nil];
}

- (void) ipAddressChanged: (NSNotification*) aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
}

- (void) isConnectedChanged: (NSNotification *) aNote
{
	[ipConnectedTextField setStringValue: [model isConnected] ? @"Connected" : @"Disconnected"];
	[ethernetConnectButton setTitle: [model isConnected] ? @"Disconnect" : @"Connect"];
//	[model isConnected] ? [model disconnect] : [model connect];
}

#pragma mark •••Interface Management


#pragma mark •••Actions
- (IBAction) ipAddressTextFieldAction: (id) aSender
{
	[model setIpAddress: [aSender stringValue]];	
}

- (IBAction) connectAction: (id) aSender
{
	if ( [model isConnected] ) {
		[model disconnect];
	}
	else {	
		[model setIpAddress: [ipAddressTextField stringValue]];
		[model connect];
	}
}

- (IBAction) getEthernetParamAction: (id) aSender
{
	if ( [model isConnected] ) {
		[model obtainEthernetConfig];
	}
}

- (IBAction) getConfigParamAction: (id) aSender
{
	if ( [model isConnected] ) {
		[model obtainConfig];
	}
}

- (IBAction) hvOnAction: (id) aSender
{
}

- (IBAction) hvOffAction: (id) aSender
{
}

- (IBAction) panicOffAction: (id) aSender
{
}


- (void) showError:(NSException*)anException name:(NSString*)name
{
    NSLog(@"Failed Cmd: %@ \n",name);
    if([[anException name] isEqualToString: OExceptionNoUnivVoltHVCratePower]) {
        [model  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@",name]];
    }
    else {
        NSRunAlertPanel([anException name], @"%@\n%@", @"OK", nil, nil,
                        [anException name],name);
    }
}

- (IBAction) showHVStatusAction: (id) aSender
{
	[model obtainHVStatus];
}

- (void) displayHVStatus
{
	[hvStatusField setStringValue: [model hvStatus]];
}

- (void) displayConfig
{
	[outputArea setString: [model config]];
}

- (void) displayEnet
{
	[outputArea setString: [model ethernetConfig]];
}

@end
