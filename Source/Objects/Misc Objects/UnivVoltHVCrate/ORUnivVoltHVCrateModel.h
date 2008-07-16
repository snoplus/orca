//
//  ORUnivVoltHVCrateModel.h
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

#import "ORCrate.h"
#define kUnivVoltHVCratePort 1090
#define kUnivVoltHVAddress 192.168.1.10

#pragma mark •••Forward Declarations
@class ORConnector;
@class NetSocket;

@interface ORUnivVoltHVCrateModel : ORCrate  {
	NSLock*		localLock;
    NSString*	ipAddress;
    BOOL		isConnected;
	NetSocket*	socket;
}

#pragma mark •••Accessors
- (NSString*) ipAddress;
- (void) setIpAddress: (NSString *) anIpAddress;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (NetSocket*) socket;
- (void) setSocket: (NetSocket*) aSocket;
- (BOOL) isConnected;
- (void) setIsConnected: (BOOL) aFlag;

#pragma mark ***Crate actions
- (NSString *) obtainHVStatus;
- (void) hvOn;
- (void) hvOff;
- (void) hvPanic;
- (void) connect;

#pragma mark ***Utilities
//- (void) connect;

@end


NSString* ORUnivVoltHVCrateIsConnectedChanged;
NSString* ORUnivVoltHVCrateIpAddressChanged;
NSString* ORUnivVoltHVCrateHVStatusChanged;

