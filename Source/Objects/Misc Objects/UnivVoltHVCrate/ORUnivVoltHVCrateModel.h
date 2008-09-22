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
#define kUnivVoltHVAddress "192.168.1.10"

// Commands
enum hveCommands {eUVNoCommand = 0, eUVHVStatus, eUVConfig, eUVEnet};
typedef enum hveCommands hveCommands;

#pragma mark •••Forward Declarations
@class ORConnector;
@class NetSocket;
@class ORQueue;

@interface ORUnivVoltHVCrateModel : ORCrate  {
	NSLock*			localLock;
    NSString*		ipAddress;
	NSString*		mReturnFromSocket;  // Used to get last return
	NSString*		mLastError;
//	hveCommands		mLastCommand;
    BOOL			mIsConnected;
	NetSocket*		mSocket;
	ORQueue*		mQueue;
}

#pragma mark •••Accessors
- (NSString*) ipAddress;
- (NSString*) hvStatus;
- (NSString*) ethernetConfig;
- (NSString*) config;
- (NetSocket*) socket;

#pragma mark •••Notifications
//- (void) registerNotificationObservers;
- (void) setIpAddress: (NSString *) anIpAddress;
- (void) setSocket: (NetSocket*) aSocket;
- (BOOL) isConnected;
- (void) setIsConnected: (BOOL) aFlag;

#pragma mark ***Crate actions
- (void) handleDataReturn: (NSData*) someData;
- (void) obtainHVStatus;
- (void) obtainEthernetConfig;
- (void) obtainConfig;
- (void) hvOn;
- (void) hvOff;
- (void) hvPanic;
- (void) connect;
- (void) sendGeneralCommand: (NSString*) aCommand;


#pragma mark ***Utilities
- (NSString *) interpretDataFromSocket: (NSData *) aSomeData;
- (void) sendCommand: (int) aCurrentUnit channel: (int) aCurrentChnl command: (NSString*) aCommand;


#pragma mark ***Archival
- (id)   initWithCoder: (NSCoder*) aDecoder;
- (void) encodeWithCoder: (NSCoder*) anEncoder;

@end

#pragma mark ***Notification string definitions.
extern NSString* ORUVHVCrateIsConnectedChangedNotification;
extern NSString* ORUVHVCrateIpAddressChangedNotification;
//extern NSString* ORUnivVoltHVCrateHVStatusChangedNotification;
extern NSString* ORUVHVCrateHVStatusAvailableNotification;
extern NSString* ORUVHVCrateConfigAvailableNotification;
extern NSString* ORUVHVCrateEnetAvailableNotification;

#pragma mark •••Constants for command queue
//extern NSString* UVkUnit;
//extern NSString* UVkChnl;
//extern NSString* UVkCommand;


