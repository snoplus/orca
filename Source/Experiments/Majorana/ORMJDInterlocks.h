//
//  ORMJDInterlocks.h
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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

@class MajoranaModel;
@class ORRemoteSocketModel;
@class ORAlarm;

//do NOT change this list without changing the StateInfo array in the .m file
enum {
    kMJDInterlocks_Idle,
    kMJDInterlocks_Ping,
    kMJDInterlocks_PingWait,
    kMJDInterlocks_CheckHVisOn,
    kMJDInterlocks_UpdateVacSystem,
    kMJDInterlocks_GetShouldUnBias,
    kMJDInterlocks_GetOKToBias,
    kMJDInterlocks_HVRampDown,
    kMJDInterlocks_HandleHVDialog,
    kMJDInterlocks_FinalState,
    kMJDInterlocks_NumStates //must be last
};

typedef struct {
    int state;
    NSString* name;
}MJDInterlocksStateInfo;

@interface ORMJDInterlocks : NSObject
{
    MajoranaModel*      delegate;
    int                 module;
    BOOL                isRunning;
    int                 currentState;
    int                 retryState;
    NSMutableArray*     stateStatus;
    NSMutableArray*     finalReport;
    NSTask*             pingTask;
    int                 retryCount;
    BOOL                printedErrorReport;
    BOOL                pingedSuccessfully;
    BOOL                hvIsOn;
    BOOL                okToBias;
    BOOL                shouldUnBias;
    BOOL                lockHVDialog;
    NSOperationQueue*   queue;
    NSDictionary*       remoteOpStatus;
    ORAlarm*            interlockFailureAlarm;
}

- (id)          initWithDelegate:(MajoranaModel*)aDelegate module:(int)aModule;
- (void)        dealloc;
- (void)        start;
- (void)        stop;
- (NSString*)   stateName:(int)anIndex;
- (void)        setupStateArray;
- (NSString*)   stateStatus:(int)aStateIndex;
- (int)         numStates;
- (void)        step;
- (void)        setState:(int)currentState status:(NSString*)aString color:(NSColor*)aColor;
- (void)        reset:(BOOL)continueRunning;
- (void)        addToReport:(NSString*)aString;
- (void)        postInterlockFailureAlarm:(NSString*)reason;
- (void)        clearInterlockFailureAlarm;

@property (assign) MajoranaModel*             delegate;
@property (assign,nonatomic) BOOL             isRunning;
@property (retain) NSDictionary*              remoteOpStatus;
@property (assign,nonatomic) int              currentState;
@property (assign,nonatomic) int              module;
@property (retain,nonatomic) NSMutableArray*  stateStatus;
@property (retain) NSMutableArray*            finalReport;

@end

@interface ORMJDInterlocks (Tasks)
- (void) ping;
- (BOOL) pingTaskRunning;
- (BOOL) pingedSuccessfully;
- (void) tasksCompleted:(id)sender;
- (void) taskFinished:(NSTask*)aTask;
- (void) sendCommand:(NSString*)aCmd;
- (void) sendCommands:(NSArray*)aCmds;
- (BOOL) sendCommandWithResponse:(NSString*)aCmd;
- (id) getResponseForKey:(NSString*)aKey
;
- (void) disconnect;

@end

extern NSString* ORMJDInterlocksIsRunningChanged;
extern NSString* ORMJDInterlocksStateChanged;


@interface ORResponseWaitOp : NSOperation
{
    ORMJDInterlocks*        delegate;
    NSArray*                cmds;
    ORRemoteSocketModel*    remObj;
    BOOL                    doneWithLoop;
}
- (id)   initWithRemoteObj:(ORRemoteSocketModel*)aRemObj commands:(NSArray*)aCmd delegate:(ORMJDInterlocks*)aDelegate;
- (void) main;
@property (assign) BOOL doneWithLoop;
@end
