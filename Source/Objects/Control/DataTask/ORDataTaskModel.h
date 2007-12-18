//
//  ORDataTaskModel.h
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
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


#pragma mark ¥¥¥Imported Files
#import "ORSafeQueue.h"
#import "ORDataChainObject.h"

#pragma mark ¥¥¥Forward Declarations
@class ORDataPacket;
@class ORReadOutList;
@class ORDataSet;
@class ORTimer;
@class ORGateGroup;

#define kDataTaskAutoCollect 	0
#define kDataTaskManualCollect 	1
#define kTimeHistoSize 4000

@class ORAlarm;

@interface ORDataTaskModel : ORDataChainObject  {
    ORReadOutList*  readOutList;
    id              nextObject;     //cache for alittle bit more speed.
    NSArray*        dataTakers;     //cache of data takers.
    BOOL            collectMode;
    unsigned long   queueCount;
    
    ORDataPacket*   transferDataPacket;
    ORSafeQueue*    transferQueue;
    
    ORAlarm*	    queueFullAlarm;
    NSString*       lastFile;
    ORSafeQueue*	recordsPending;
	BOOL			areRecordsPending;
    
    ORTimer* dataTimer;
    ORTimer* mainTimer;
    unsigned long dataTimeHist[kTimeHistoSize];
    unsigned long processingTimeHist[kTimeHistoSize];
     
    clock_t			runStartTime;
	struct tms		runStartTmsTime;
	short			timeScaler;
	BOOL			enableTimer;
	unsigned long	cycleCount;
	unsigned long	cycleRate;
    unsigned long   cachedNumberDataTakers;
	id*				cachedDataTakers;
	
    BOOL timeToStopProcessThread;
	BOOL processThreadRunning;
	
    NSLock*			 timerLock;
    BOOL            doGateProcessing;
    ORGateGroup*    cachedGateGroup; 
	
	//hints
	unsigned long queAddCount;
	unsigned long lastqueAddCount;
}

#pragma mark ¥¥¥Accessors
- (ORReadOutList*) readOutList;
- (void) setReadOutList:(ORReadOutList*)someDataTakers;
- (BOOL) collectMode;
- (void) setCollectMode:(BOOL)newMode;
- (unsigned long)queueCount;
- (void)setQueueCount:(unsigned long)aQueueCount;
- (unsigned long) queueMaxSize;
- (NSString *)lastFile;
- (void)setLastFile:(NSString *)aLastFile;
- (unsigned long) dataTimeHist:(int)index;
- (unsigned long) processingTimeHist:(int)index;
- (short) timeScaler;
- (void) setTimeScaler:(short)aValue;
- (void) clearTimeHistogram;
- (void) setEnableTimer:(int)aState;
- (unsigned long)cycleRate;
- (void) setCycleRate:(unsigned long)aRate;

#pragma mark ¥¥¥Run Management
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (BOOL) doneTakingData;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) processData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) putDataInQueue:(ORDataPacket*)aDataPacket force:(BOOL)forceAdd;
- (void) queueRecordForShipping:(NSNotification*)aNote;
- (void) closeOutRun:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) doCycleRate;

#pragma mark ¥¥¥Save/Restore
- (void) saveReadOutListTo:(NSString*)fileName;
- (void) loadReadOutListFrom:(NSString*)fileName;
@end

extern NSString* ORDataTakerAdded;
extern NSString* ORDataTakerRemoved;
extern NSString* ORDataTaskCollectModeChangedNotification;
extern NSString* ORDataTaskQueueCountChangedNotification;
extern NSString* ORDataTaskListLock;
extern NSString* ORDataTaskTimeScalerChangedNotification;
extern NSString* ORDataTaskCycleRateChangedNotification;


