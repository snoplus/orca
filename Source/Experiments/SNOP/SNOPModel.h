//
//  SNOPModel.h
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


#pragma mark ¥¥¥Imported Files
#import "ORExperimentModel.h"
@class ORCouchDB;

#define kUseTubeView	0
#define kUseCrateView	1
#define kUsePSUPView	2
#define kNumTubes	20 //XL3s

@interface SNOPModel: ORExperimentModel
{
	int viewType;

    NSString* _orcaDBUserName;
    NSString* _orcaDBPassword;
    NSString* _orcaDBName;
    unsigned int _orcaDBPort;
    NSString* _orcaDBIPAddress;
    NSMutableArray* _orcaDBConnectionHistory;
    NSUInteger _orcaDBIPNumberIndex;
    NSTask*	_orcaDBPingTask;
    
    NSString* _debugDBUserName;
    NSString* _debugDBPassword;
    NSString* _debugDBName;
    unsigned int _debugDBPort;
    NSString* _debugDBIPAddress;
    NSMutableArray* _debugDBConnectionHistory;
    NSUInteger _debugDBIPNumberIndex;
    NSTask*	_debugDBPingTask;
}

@property (nonatomic,copy) NSString* orcaDBUserName;
@property (nonatomic,copy) NSString* orcaDBPassword;
@property (nonatomic,copy) NSString* orcaDBName;
@property (nonatomic,assign) unsigned int orcaDBPort;
@property (nonatomic,copy) NSString* orcaDBIPAddress;
@property (nonatomic,retain) NSMutableArray* orcaDBConnectionHistory;
@property (nonatomic,assign) NSUInteger orcaDBIPNumberIndex;
@property (nonatomic,retain) NSTask* orcaDBPingTask;

@property (nonatomic,copy) NSString* debugDBUserName;
@property (nonatomic,copy) NSString* debugDBPassword;
@property (nonatomic,copy) NSString* debugDBName;
@property (nonatomic,assign) unsigned int debugDBPort;
@property (nonatomic,copy) NSString* debugDBIPAddress;
@property (nonatomic,retain) NSMutableArray* debugDBConnectionHistory;
@property (nonatomic,assign) NSUInteger debugDBIPNumberIndex;
@property (nonatomic,retain) NSTask* debugDBPingTask;

- (void) initOrcaDBConnectionHistory;
- (void) clearOrcaDBConnectionHistory;
- (id) orcaDBConnectionHistoryItem:(unsigned int)index;
- (void) orcaDBPing;

- (void) initDebugDBConnectionHistory;
- (void) clearDebugDBConnectionHistory;
- (id) debugDBConnectionHistoryItem:(unsigned int)index;
- (void) debugDBPing;

- (void) taskFinished:(NSTask*)aTask;
- (ORCouchDB*) orcaDBRef;
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) runStateChanged:(NSNotification*)aNote;
- (void) subRunStarted:(NSNotification*)aNote;
- (void) subRunEnded:(NSNotification*)aNote;
- (void) runStarted:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;

#pragma mark ¥¥¥Accessors
- (void) setViewType:(int)aViewType;
- (int) viewType;

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups;

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock;
- (NSString*) experimentDetectorLock;
- (NSString*) experimentDetailsLock;
@end

extern NSString* ORSNOPModelViewTypeChanged;
extern NSString* ORSNOPModelOrcaDBIPAddressChanged;
extern NSString* ORSNOPModelDebugDBIPAddressChanged;
