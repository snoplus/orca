//
//  ORGlobal.h
//  Orca
//
//  Created by Mark Howe on Wed Dec 24 2003.
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




@class ORAlarm;

typedef enum {
	kNormalRun,
	kOfflineRun
}eRunMode;
//--------------------------------------------------------
enum eRunState{
    eRunStopped,
    eRunInProgress,
    eRunStarting,
    eRunStopping,
    kNumRunStates //must be last
};

typedef enum eRunType {
    eMaintenanceRunType = (1 << 0),
    eCalibrationRunType = (1 << 1),
    eSourceRunType      = (1 << 2)
}eRunType;


extern NSString* runState[kNumRunStates];
//--------------------------------------------------------
//--------------------------------------------------------
typedef enum ORTaskState {
    eTaskStopped,
    eTaskRunning,
    eTaskWaiting,
    eMaxTaskState //must be last
}ORTaskState;

extern NSString* ORTaskStateName[eMaxTaskState];
//--------------------------------------------------------


@interface ORGlobal : NSObject  {
    BOOL	runInProgress;
    short       tasksRunning;
    short       tasksWaiting;
    eRunMode    runMode;
    ORAlarm*    runModeAlarm;
    unsigned long runType;
	NSMutableDictionary* runVetos;
}

+ (id) sharedInstance;
- (id) init;
- (BOOL) runInProgress;
- (BOOL) runStopped;
- (BOOL) runRunning;
- (void) setRunInProgress:(BOOL)state;
- (void) registerNotificationObservers;
- (void) runStatusChanged:(NSNotification*)aNotification;
- (void) taskStatusChanged:(NSNotification*)aNotification;
- (void) documentClosed:(NSNotification*)aNotification;
- (unsigned long)runType;
- (void)setRunType:(unsigned long)aRunType;

- (void) setRunMode:(eRunMode)aMode;
- (eRunMode) runMode;
- (NSString*) runModeString;
- (void) checkRunMode;
- (NSUndoManager*) undoManager;
- (void) addRunVeto:(NSString*)vetoName comment:(NSString*)aComment;
- (void) removeRunVeto:(NSString*)vetoName;
- (void) listVetoReasons;
- (BOOL) anyVetosInPlace;
- (int) vetoCount;

#pragma mark •••Archival
- (id)loadParams:(NSCoder*)decoder;
- (void)saveParams:(NSCoder*)encoder;

@end

#pragma mark •••External Definitions
extern NSString* ORNeedMoreTimeToStopRun;
extern NSString* ORRunStoppedNotification;
extern NSString* ORRunStatusChangedNotification;
extern NSString* ORRunStatusValue;
extern NSString* ORRunStatusString;
extern NSString* ORTaskStateChangedNotification;
extern NSString* ORRunModeChangedNotification;
extern ORGlobal* gOrcaGlobals;
extern NSString* ORRunTypeMask;
extern NSString* ORQueueRecordForShippingNotification;

extern NSString* ORRunAboutToStopNotification;
extern NSString* ORRunFinalCallNotification;
extern NSString* ORRunAboutToStartNotification;
extern NSString* ORRunStartedNotification;
extern NSString* ORRequestRunStop;
extern NSString* ORRequestRunHalt;
extern NSString* ORRunVetosChanged;

extern NSString* ORHardwareEnvironmentNoisy;
extern NSString* ORHardwareEnvironmentQuiet;

