//
//  ORMJDSource.h
//  Orca
//
//  Created by Mark Howe on Sept 8, 2015.
//  Copyright (c) 2015  University of North Carolina. All rights reserved.
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
#import "ORRemoteCommander.h"

@class MajoranaModel;
@class ORRemoteSocketModel;
@class ORAlarm;

//do NOT change this list without changing the StateInfo array in the .m file
enum {
    kMJDSource_Idle,
    
    kMJDSource_StartArduino,
    kMJDSource_OpenGV,
    kMJDSource_OpenGV1,
    kMJDSource_OpenGV2,
    kMJDSource_GetGVOpenPosition,
    kMJDSource_VerifyGVOpen,
    
    kMJDSource_StartDeployment,
    kMJDSource_QueryMotion,
    
    kMJDSource_VerifyMotion,
    kMJDSource_MonitorDeployment,
    
    kMJDSource_StartRetraction,
    kMJDSource_MonitorRetraction,
    
    kMJDSource_StopMotion,
    kMJDSource_VerifyStopped,
    kMJDSource_StopArduino,
    
    //special (for now)
    kMJDSource_StartCloseGVSequence,
    kMJDSource_GetMirrorTrack,
    kMJDSource_VerifyInMirrorTrack,
    kMJDSource_CloseGV,
    kMJDSource_CloseGV1,
    kMJDSource_CloseGV2,
    kMJDSource_GetGVClosePosition,
    kMJDSource_VerifyGVClosed,
    kMJDSource_MirrorTrackError,
    //--------
    
    kMJDSource_GVOpenError,
    kMJDSource_GVCloseError,
    kMJDSource_ConnectionError,
    kMJDSource_NumStates //must be last
};

enum {
    kMJDSource_Unknown,
    kMJDSource_True,
    kMJDSource_False
};

typedef struct {
    int state;
    NSString* name;
} MJDSourceStateInfo;

@interface ORMJDSource : ORRemoteCommander
{
    MajoranaModel*      delegate;
    int                 slot;
    BOOL                isDeploying;
    BOOL                isRetracting;
    int                 gateValveIsOpen;
    int                 sourceIsIn;
    int                 isMoving;
    int                 isConnected;
    int                 currentState;
    NSMutableArray*     stateStatus;
    ORAlarm*            interlockFailureAlarm;
    int                 counter;
    BOOL                firstTime;
    int                 stateAOld;
    int                 stateBOld;
    int                 stateCOld;
    int                 stateA;
    int                 stateB;
    int                 stateC;
    float               runningTime;
    NSMutableString*    order;
    BOOL                oneTimeGVVerbose;
    float               elapsedTime;
}

- (id)          initWithDelegate:(MajoranaModel*)aDelegate slot:(int)aSlot;
- (void)        dealloc;
- (void)        startDeployment;
- (void)        startRetraction;
- (void)        stopSource;
- (NSString*)   stateName:(int)anIndex;
- (void)        setupStateArray;
- (NSString*)   stateStatus:(int)aStateIndex;
- (int)         numStates;
- (void)        step;
- (void)        setState:(int)currentState status:(NSString*)aString color:(NSColor*)aColor;
- (void)        postInterlockFailureAlarm:(NSString*)reason;
- (void)        clearInterlockFailureAlarm;
- (void)        setIsMoving:(int)aState;
- (int)         isMoving;
- (void)        setIsConnected:(int)aState;
- (int)         isConnected;
- (NSString*)   movingState;
- (NSString*)   connectedState;
- (NSString*)   modeString;
- (NSString*)   currentStateName;
- (void)        resetFlags;
- (void)        setGateValveIsOpen:(int)aState;
- (NSString*)   sourceIsInState;

#pragma mark ***Remote Commands
- (void)        sendDeploymentCommand;
- (void)        sendRetractionCommand;
- (void)        queryMotion;
- (void)        stopMotion;
- (void)        startArduino;
- (void)        stopArduino;
- (void)        readArduino;
- (NSString*)   gateValveState;
- (void)        checkGateValve;
- (void)        turnOffGVPower;
- (void)        turnOnGVPower;
- (void)        openGateValveStepOne;
- (void)        openGateValveStepTwo;
- (void)        closeGateValve;
- (void)        closeGateValveStepOne;
- (void)        closeGateValveStepTwo;

#pragma mark ***Remote Responses
- (NSNumber*)   sourceMovingResponse;

@property (assign,nonatomic) MajoranaModel*   delegate;
@property (assign,nonatomic) BOOL             isDeploying;
@property (assign,nonatomic) BOOL             isRetracting;
@property (assign,nonatomic) BOOL             firstTime;
@property (assign,nonatomic) int              gateValveIsOpen;
@property (assign,nonatomic) int              sourceIsIn;
@property (assign,nonatomic) int              slot;
@property (assign,nonatomic) int              currentState;
@property (assign,nonatomic) float            runningTime;
@property (retain,nonatomic) NSMutableString* order;
@property (retain,nonatomic) NSMutableArray*  stateStatus;

@end

extern NSString* ORMJDSourceModeChanged;
extern NSString* ORMJDSourceStateChanged;
extern NSString* ORMJDSourceIsMovingChanged;
extern NSString* ORMJDSourceIsConnectedChanged;
extern NSString* ORMJDSourcePatternChanged;
extern NSString* ORMJDSourceGateValveChanged;
extern NSString* ORMJDSourceIsInChanged;
