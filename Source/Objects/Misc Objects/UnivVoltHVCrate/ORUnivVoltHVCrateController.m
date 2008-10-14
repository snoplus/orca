
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
#import "ORUnivVoltHVCrateExceptions.h"


@implementation ORUnivVoltHVCrateController

- (id) init
{
    self = [super initWithWindowNibName:@"UnivVoltHVCrate"];
	if ( self ) {
		[model setIpAddress: [[NSString alloc] initWithFormat: @"192.168.1.10"]];
	}
    return self;	
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	NSString* testString = [[NSString alloc] initWithString: @"See if anything appears in text view.\n"];
	NSLog( @" IPAddress: ",[model ipAddress] );
	[ipAddressTextField setStringValue: [model ipAddress]];
//	[mReturnStringFromSocket setString: testString];
//	[mReturnStringFromSocket appendString: testString1];
	NSString* returnStringFromSocket = [[NSString alloc] initWithFormat: @"%@", testString];
	[outputArea setString: returnStringFromSocket];	
}


- (void) setCrateTitle
{
	[[self window] setTitle:[NSString stringWithFormat:@"CAMAC crate %d",[model uniqueIdNumber]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    [notifyCenter addObserver : self
                     selector : @selector( isConnectedChanged: )
                         name : UVHVCrateIsConnectedChangedNotification
                       object : model];
					   
					
    [notifyCenter addObserver : self
                     selector : @selector( ipAddressChanged: )
                         name : UVHVCrateIpAddressChangedNotification
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector( displayHVStatus: )
                         name : UVHVCrateHVStatusAvailableNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector( displayConfig: )
                         name : UVHVCrateConfigAvailableNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector( displayEnet: )
                         name : UVHVCrateEnetAvailableNotification
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector( writeErrorMsg: )
                         name : UVHVSocketNotConnectedNotification
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

- (void) writeErrorMsg: (NSNotification*) aNote
{
	NSDictionary* errorDict = [aNote userInfo];
	NSLog( @"error: %@", [errorDict objectForKey: UVkErrorMsg] );
	[outputArea setString: [errorDict objectForKey: UVkErrorMsg]];
}


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
	NSLog( @"getEthernetParamAction" );
	if ( [model isConnected] ) {
		[model obtainEthernetConfig];
	}
}

- (IBAction) getConfigParamAction: (id) aSender
{
	NSLog( @"getConfigParamAction" );
	if ( [model isConnected] ) {
		[model obtainConfig];
	}
}

- (IBAction) hvOnAction: (id) aSender
{
	[model turnHVOn];
}

- (IBAction) hvOffAction: (id) aSender
{
	[model turnHVOff];
}

- (IBAction) panicAction: (id) aSender
{
	[model hvPanic];
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

#pragma mark ***Respond to notifications actions from model handleDataReturn
- (void) displayHVStatus
{
	NSLog( @"HVStatus display: %@", [model hvStatus]);
	[hvStatusField setStringValue: [model hvStatus]];
}

- (void) displayConfig
{
	NSLog( @"Config display: %@", [model config]);
	[outputArea setString: [model config]];
}

- (void) displayEnet
{
	NSLog( @"Ethernet display: %@", [model ethernetConfig]);
	[outputArea setString: [model ethernetConfig]];
}

@end
