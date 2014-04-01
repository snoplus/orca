//
//  ORHeartbeatCheckerModel.h
//  Orca
//
//  Created by Mark Howe on Tues April 1, 2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "ORProcessElementModel.h"
#import "ORRemoteSocketModel.h"

@interface ORHeartbeatCheckerModel :  ORProcessElementModel
{
    NSTimeInterval t0;
    NSTimeInterval cycleTime;
	BOOL timerState;
	SimpleCocoaConnection*	c;
	NSString*				remoteHost;
	int						remotePort;
	BOOL					isConnected;
	int						connectionTimeout;
	NSStringEncoding		defaultStringEncoding;
	NSMutableDictionary*	responseDictionary;
}

#pragma mark •••Initialization
- (void) setUpImage;
- (void) makeMainController;
- (void) processIsStarting;
- (id) eval;

#pragma mark •••Accessors
- (NSTimeInterval) cycleTime;
- (void) setCycleTime:(NSTimeInterval)aCycleTime;
- (BOOL)		isConnected;

- (NSString*)	remoteHost;
- (void)		setRemoteHost:(NSString*)newHost;
- (int)			remotePort;
- (void)		setRemotePort:(int)newPort;
- (int)			connectionTimeout;
- (void)		setConnectionTimeout:(int)newTimeout;
- (NSStringEncoding) defaultStringEncoding;
- (void)		setDefaultStringEncoding:(NSStringEncoding)encoding;
#pragma mark ***Socket Methods
- (SCCInit) connect;
- (void)	disconnect;
- (BOOL)	sendData:(NSData*)data;
- (BOOL)	sendString:(NSString*)string;
- (BOOL)	sendString:(NSString*)string withEncoding:(NSStringEncoding)encoding;
- (void)		removeResponseForKey:(NSString*)aKey;
- (id)		responseForKey:(NSString*)aKey;
- (BOOL)	responseExistsForKey:(NSString*)aKey;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORHeartbeatCheckerCycleTimeChanged;
extern NSString* ORHeartbeatCheckerLock;
extern NSString* ORHeartbeatCheckerPortChanged;
extern NSString* ORHeartbeatCheckerHostChanged;

