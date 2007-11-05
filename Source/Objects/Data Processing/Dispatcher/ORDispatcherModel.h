//
//  ORDispatcherModel.h
//  Orca
//
//  Created by Mark Howe on Mon Nov 18 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files

#pragma mark ¥¥¥Forward Declarations
@class NetSocket;
@class ORDataPacket;
@class ORDispatcherClient;

#define kORDispatcherPort 44666


@interface ORDispatcherModel :  OrcaObject 
{
    @private
	int             socketPort;
	NetSocket*      serverSocket;
	NSMutableArray*	clients;
	NSData*         dataHeader;
    BOOL        checkAllowed;
    BOOL        checkRefused;
	BOOL		_ignoreMode;
	BOOL		scheduledForUpdate;
    NSArray* allowedList;
    NSArray* refusedList;
}

- (void)serve;

#pragma mark ¥¥¥Accessors
- (int) socketPort;
- (void) setSocketPort:(int)aPort;
- (void) setClients:(NSMutableArray*)someClients;
- (NSArray*)clients;
- (BOOL) isAlreadyConnected:(ORDispatcherClient*)aNewClient;
- (BOOL) checkAllowed;
- (void) setCheckAllowed: (BOOL) flag;
- (BOOL) checkRefused;
- (void) setCheckRefused: (BOOL) flag;
- (NSArray *) allowedList;
- (void) setAllowedList: (NSArray *) AllowedList;
- (NSArray *) refusedList;
- (void) setRefusedList: (NSArray *) RefusedList;
- (void) parseAllowedList:(NSString*)aString;
- (void) parseRefusedList:(NSString*)aString;
- (BOOL) allowConnection:(ORDispatcherClient*)aNewClient;
- (BOOL) refuseConnection:(ORDispatcherClient*)aNewClient;
- (void) checkConnectedClients;
- (void) report;
- (int) clientCount;
- (void) scheduleUpdateOnMainThread;
- (void) postUpdateOnMainThread;
- (void) postUpdate;

#pragma mark ¥¥¥Data Handling
- (void) processData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) closeOutRun:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) clientDisconnected:(id)aClient;

#pragma mark ¥¥¥Delegate Methods
- (void) netsocket:(NetSocket*)inNetSocket connectionAccepted:(NetSocket*)inNewNetSocket;
- (void) clientChanged:(id)aClient;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) runModeChanged:(NSNotification*)aNotification;


@end

extern NSString* ORDispatcherPortChangedNotification;
extern NSString* ORDispatcherClientsChangedNotification;
extern NSString* ORDispatcherClientDataChangedNotification;
extern NSString* ORDispatcherCheckRefusedChangedNotification;
extern NSString* ORDispatcherCheckAllowedChangedNotification;
extern NSString* ORDispatcherLock;


