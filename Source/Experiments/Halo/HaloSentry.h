//-------------------------------------------------------------------------
//  HaloSentryModel.h
//
//  Created by Mark Howe on Saturday 12/01/2012.
//  Copyright (c) 2012 University of North Carolina. All rights reserved.
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

#pragma mark ***Imported Files
enum  eHaloSentryState {
    eIdle,
    eStarting,
    eStopping,
    eCheckRemoteMachine,
    eConnectToRemoteOrca,
    eGetRunState,
    eCheckRunState,
    eWaitForPing,
} eHaloSentryState;

enum eHaloSentryType {
    eNeither,
    ePrimary,
    eSecondary
}eHaloSentryType;

@class NetSocket;
@class NSAlarm;
@class ORRunModel;

@interface HaloSentry : NSObject
{
  @private
    enum eHaloSentryType sentryType;
    BOOL disabled;
    BOOL isRunning;
    NSString* ipNumber1;
    NSString* ipNumber2;;
    NSString* primarySystemIP;
    NSString* secondarySystemIP;
    NSString* otherSystemIP;
    
    NSTimeInterval stepTime;
    enum eHaloSentryState state;
    enum eHaloSentryState nextState;
    NSArray* sbcArray;
	NSTask*	 pingTask;
    BOOL     remoteMachineRunning;
    BOOL     remoteORCARunning;
    BOOL     remoteRunInProgress;
    NetSocket* socket;
    BOOL    isConnected;
    ORAlarm* remoteMachineNotReachable;
    NSMutableDictionary* remoteRunParams;
    ORRunModel* runControl;
}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;
- (NSUndoManager*) undoManager;
- (void) registerNotificationObservers;
- (void) setOtherIP;
- (BOOL) remoteMachineRunning;
- (void) setRemoteMachineRunning:(BOOL)aState;
- (BOOL) remoteORCARunning;
- (void) setRemoteORCARunning:(BOOL)aState;
- (BOOL) remoteRunInProgress;
- (void) setRemoteRunInProgress:(BOOL)aState;

#pragma mark ***Notifications
- (void) objectsChanged:(NSNotification*)aNote;
- (void) runStarted:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;

#pragma mark ***Accessors
- (BOOL) disabled;
- (void) setDisabled:(BOOL)aDisabled;
- (NSString*) ipNumber2;
- (void) setIpNumber2:(NSString*)aIpNumber2;
- (NSString*) ipNumber1;
- (void) setIpNumber1:(NSString*)aIpNumber1;
- (enum eHaloSentryType) sentryType;
- (void) setSentryType:(enum eHaloSentryType)aType;
- (enum eHaloSentryState) state;
- (void) setNextState:(enum eHaloSentryState)aState stepTime:(NSTimeInterval)aTime;
- (void) takeOverRunning;
- (NSString*) sentryTypeName;
- (NSString*) stateName;

#pragma mark ***Run Stuff
- (void) start;
- (void) stop;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***Helpers
- (void) ping;
- (BOOL) pingTaskRunning;
- (void) tasksCompleted:(id)sender;
- (void) postMachineAlarm;
- (void) clearMachineAlarm;
- (void) askForRunStatus;
- (void) toggleSystems;
@end

extern NSString* HaloSentryIpNumber2Changed;
extern NSString* HaloSentryIpNumber1Changed;
extern NSString* HaloSentryIsPrimaryChanged;
extern NSString* HaloSentryIsRunningChanged;
extern NSString* HaloSentryStateChanged;
extern NSString* HaloSentryTypeChanged;
extern NSString* HaloSentryPingTask;
extern NSString* HaloSentryIsConnectedChanged;
extern NSString* HaloSentryRemoteStateChanged;
extern NSString* HaloSentryDisabledChanged;

