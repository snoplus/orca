//-------------------------------------------------------------------------
//  HaloSentry.h
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

@class NetSocket;
@class ORRunModel;


enum  eHaloSentryState {
    eIdle,
    eStarting,
    eStopping,
    eCheckRemoteMachine,
    eConnectToRemoteOrca,
    eGetRunState,
    eCheckRunState,
    eWaitForPing,
    eGetSecondaryState,
    eWaitForLocalRunStop,
    eWaitForRemoteRunStop,
    eWaitForLocalRunStart,
    eWaitForRemoteRunStart,
    eKillCrates,
    eKillCrateWait,
    eStartCrates,
    eStartCrateWait,
    eStartRun,
    eCheckRun,
    eBootCrates,
    eWaitForBoot,
    ePingCrates,
} eHaloSentryState;

enum eHaloSentryType {
    eNeither,
    ePrimary,
    eSecondary,
    eHealthyToggle,
    eTakeOver,
}eHaloSentryType;

enum eHaloStatus {
    eOK             = 0,
    eYES            = 0,
    eRunning        = 0,
    eBad            = 1,
    eNO             = 1,
    eBeingChecked   = 2,
    eUnknown        = 3
} eHaloStatus;

#define kMaxHungCount 2

@interface HaloSentry : NSObject
{
  @private
    enum eHaloSentryType sentryType;
    enum eHaloSentryState state;
    enum eHaloSentryState nextState;
    NSTimeInterval stepTime;    
    BOOL    sentryIsRunning;
    short   missedHeartbeatCount;
    BOOL    wasRunning;
    float   loopTime;
    NSString*   ipNumber1;
    NSString*   ipNumber2;;
    NSString*   otherSystemIP;
    BOOL        stealthMode1;
    BOOL        stealthMode2;
    BOOL        otherSystemStealthMode;
    BOOL        ignoreRunStates;
    BOOL        triedBooting;
    BOOL        wasLocalRun;
    
	NSTask*     pingTask;
    NetSocket*  socket;
    BOOL        isConnected;
   
    enum eHaloStatus remoteMachineReachable;
    enum eHaloStatus remoteORCARunning;
    enum eHaloStatus remoteRunInProgress;
    
    ORAlarm* pingFailedAlarm;
    ORAlarm* noConnectionAlarm;
    ORAlarm* orcaHungAlarm;
    ORAlarm* noRemoteSentryAlarm;
    ORAlarm* runProblemAlarm;
    ORAlarm* listModAlarm;
    
    ORRunModel* runControl;
    NSArray* sbcs;
    NSArray* shapers;
    NSString* sbcRootPwd;
    NSMutableDictionary* sbcPingTasks;
    NSMutableArray* unPingableSBCs;
    NSMutableArray* sentryLog;
}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;
- (NSUndoManager*) undoManager;
- (void) awakeAfterDocumentLoaded;
- (void) registerNotificationObservers;
- (void) setOtherIP;
- (enum eHaloStatus) remoteMachineReachable;
- (void) setRemoteMachineReachable:(enum eHaloStatus)aState;
- (enum eHaloStatus) remoteORCARunning;
- (void) setRemoteORCARunning:(enum eHaloStatus)aState;
- (enum eHaloStatus) remoteRunInProgress;
- (void) setRemoteRunInProgress:(enum eHaloStatus)aState;
- (BOOL) stealthMode2;
- (void) setStealthMode2:(BOOL)aStealthMode2;
- (BOOL) stealthMode1;
- (void) setStealthMode1:(BOOL)aStealthMode1;
- (BOOL) otherSystemStealthMode;
- (BOOL) sentryIsRunning;
- (void) setSentryIsRunning:(BOOL)aState;
- (BOOL) isConnected;
- (NSString*)sbcRootPwd;
- (void) setSbcRootPwd:(NSString*)aString;


#pragma mark ***Notifications
- (void) objectsChanged:(NSNotification*)aNote;
- (void) runStarted:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;
- (void) collectObjects;

#pragma mark ***Accessors
- (NSString*) ipNumber2;
- (void) setIpNumber2:(NSString*)aIpNumber2;
- (NSString*) ipNumber1;
- (void) setIpNumber1:(NSString*)aIpNumber1;
- (enum eHaloSentryType) sentryType;
- (void) setSentryType:(enum eHaloSentryType)aType;
- (enum eHaloSentryState) state;
- (void) setNextState:(enum eHaloSentryState)aState stepTime:(NSTimeInterval)aTime;
- (void) takeOverRunning;
- (void) takeOverRunning:(BOOL)quiet;
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
- (void) updateRemoteMachine;
- (void) toggleSystems;
- (void) startHeartbeatTimeout;
- (void) cancelHeartbeatTimeout;
- (void) missedHeartBeat;
- (short) missedHeartBeatCount;
- (NSString*) remoteMachineStatusString;
- (NSString*) connectionStatusString;
- (NSString*) remoteORCArunStateString;
- (BOOL) runIsInProgress;
- (void) appendToSentryLog:(NSString*)aString;
- (void) flushSentryLog;

#pragma mark ***Alarms
- (void) postPingAlarm;
- (void) clearPingAlarm;
- (void) postConnectionAlarm;
- (void) clearConnectionAlarm;
- (void) postOrcaHungAlarm;
- (void) clearOrcaHungAlarm;
- (void) postNoRemoteSentryAlarm;
- (void) clearNoRemoteSentryAlarm;
- (void) postRunProblemAlarm:(NSString*)aTitle;
- (void) clearRunProblemAlarm;
- (void) postListModAlarm;
- (void) clearListModAlarm;
@end

extern NSString* HaloSentryStealthMode2Changed;
extern NSString* HaloSentryStealthMode1Changed;
extern NSString* HaloSentryIpNumber2Changed;
extern NSString* HaloSentryIpNumber1Changed;
extern NSString* HaloSentryIsPrimaryChanged;
extern NSString* HaloSentryIsRunningChanged;
extern NSString* HaloSentryStateChanged;
extern NSString* HaloSentryTypeChanged;
extern NSString* HaloSentryIsConnectedChanged;
extern NSString* HaloSentryRemoteStateChanged;
extern NSString* HaloSentryMissedHeartbeat;
extern NSString* HaloSentrySbcRootPwdChanged;
