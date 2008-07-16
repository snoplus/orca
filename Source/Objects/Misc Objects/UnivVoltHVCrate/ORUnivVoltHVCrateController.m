
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

//ORUnivVoltHVCrateIsConnectedChanged = @"ORUnivVoltHVCrateIsConnectedChanged";


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
                         name : @"ORUnivVoltHVCrateIsConnectedChanged"
                       object : nil];
}

- (void) isConnectedChanged: (NSNotification *) aNote
{
	[ipAddress setStringValue: [model isConnected] ? @"Connected" : @"NotConnected"];
	[ethernetConnectButton setTitle: [model isConnected] ? @"Disconnect" : @"Connect"];
}

#pragma mark •••Interface Management


#pragma mark •••Actions
- (IBAction) connectAction: (id) aSender
{
	[model setIpAddress: [ipAddress stringValue]];
	[model connect];
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

- (IBAction) ipAddressTextFieldAction: (id)sender
{
	[model setIpAddress: [sender stringValue]];	
}


- (IBAction) showHVStatusAction: (id) aSender
{
//	NSString* testStr = [[NSString alloc] initWithFormat: @"HVOFF"];
//	[hvStatusField setStringValue: testStr];
	[hvStatusField setStringValue: [model obtainHVStatus]];
}

@end
