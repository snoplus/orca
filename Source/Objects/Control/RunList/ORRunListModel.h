//
//  ORRunListModel.h
//  Orca
//
//  Created by Mark Howe on Tues Feb 09 2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
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

@class TimedWorker;
@class ORRunModel;
@class ORScriptIDEModel;

enum eRunListStates {
	kStartup,
	kStartRun,
	kStartSubRun,
	kStartScript,
	kWaitForScript,
	kWaitForRunTime,
	kRunFinished,
	kFinishUp
}eRunListStates;

@interface ORRunListModel : OrcaObject  {
	NSMutableArray* items;
	TimedWorker* timedWorker;
	float totalExpectedTime;
	float accumulatedTime;
    int workingItemIndex;
	ORRunModel* runModel;
	ORScriptIDEModel* scriptModel;
	BOOL oldTimedRun;
	BOOL oldRepeatRun;
	int oldRepeatTime;
	int runListState;
	float runLength;
	NSMutableArray* orderArray;
    BOOL randomize;
	NSString* lastFile;
}

#pragma mark •••Accessors
- (NSString*) lastFile;
- (void) setLastFile:(NSString*)aLastFile;
- (float) totalExpectedTime;
- (float) accumulatedTime;
- (BOOL) randomize;
- (void) setRandomize:(BOOL)aRandomize;
- (int) workingItemIndex;
- (BOOL) isRunning;
- (void) startRunning;
- (void) stopRunning;
- (void) addItem;
- (void) removeItemAtIndex:(int) anIndex;
- (void) addItem:(id)anItem atIndex:(int)anIndex;
- (id) itemAtIndex:(int)anIndex;
- (unsigned long) itemCount;
- (TimedWorker*) timedWorker;
- (NSString*) runStateName;

#pragma mark •••Save/Restore
- (void) saveToFile:(NSString*)aPath;
- (void) restoreFromFile:(NSString*)aPath;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORRunListModelLastFileChanged;
extern NSString* ORRunListModelRandomizeChanged;
extern NSString* ORRunListModelWorkingItemIndexChanged;
extern NSString* ORRunListListLock;
extern NSString* ORRunListItemsAdded;
extern NSString* ORRunListItemsRemoved;
extern NSString* ORRunListRunStateChanged;
extern NSString* ORRunListModelReloadTable;


