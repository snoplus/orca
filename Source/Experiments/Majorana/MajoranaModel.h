//
//  MajoranaModel.h
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
#import "OROrderedObjHolding.h"

#define kUseDetectorView    0
#define kUseCrateView       1
#define kNumDetectors       2*35*2 //2 cryostats of 35 detectors * 2 (low and hi channels)
#define kNumVetoSegments    32
#define kMaxNumStrings      14

//component tag numbers
#define kVacAComponent			0
#define kVacBComponent			1

@class ORRemoteSocketModel;
@class OROpSequence;
@class ORAlarm;

@interface MajoranaModel :  ORExperimentModel <OROrderedObjHolding>
{
	int             viewType;
    int             pollTime;
    OROpSequence*   scriptModel[2];
    NSMutableArray* stringMap;
    ORAlarm*        rampHVAlarm[2];
    BOOL            ignorePanicOnA;
    BOOL            ignorePanicOnB;
}

#pragma mark ¥¥¥Accessors
- (BOOL) ignorePanicOnB;
- (void) setIgnorePanicOnB:(BOOL)aIgnorePanicOnB;
- (BOOL) ignorePanicOnA;
- (void) setIgnorePanicOnA:(BOOL)aIgnorePanicOnA;
- (int)  pollTime;
- (void) setPollTime:(int)aPollTime;
- (void) setViewType:(int)aViewType;
- (int) viewType;
- (ORRemoteSocketModel*) remoteSocket:(int)aVMECrate;
- (BOOL) anyHvOnVMECrate:(int)aVMECrate;
- (void) setVmeCrateHVConstraint:(int)aCrate state:(BOOL)aState;
- (void) rampDownHV:(int)aCrate vac:(int)aVacSystem;
- (id) scriptModel:(int)index;
- (NSArray*) scriptSteps:(int)index;
- (void) hvInfoRequest:(NSNotification*)aNote;
- (void) updateAllowedToRunStates;

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups;
- (NSString*) getValueForPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts;
- (id)   stringMap:(int)i objectForKey:(id)aKey;
- (void) stringMap:(int)i setObject:(id)anObject forKey:(id)aKey;
- (NSString*) mapFileAsString;

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock;
- (NSString*) vetoMapLock;
- (NSString*) experimentDetectorLock;
- (NSString*) experimentDetailsLock;

#pragma mark ¥¥¥OROrderedObjHolding Protocol
- (int) maxNumberOfObjects;
- (int) objWidth;
- (int) groupSeparation;
- (NSString*) nameForSlot:(int)aSlot;
- (NSRange) legalSlotsForObj:(id)anObj;
- (int) slotAtPoint:(NSPoint)aPoint;
- (NSPoint) pointForSlot:(int)aSlot;
- (void) place:(id)anObj intoSlot:(int)aSlot;
- (int) slotForObj:(id)anObj;
- (int) numberSlotsNeededFor:(id)anObj;

#pragma mark ¥¥¥Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;


@end

extern NSString* MajoranaModelIgnorePanicOnBChanged;
extern NSString* MajoranaModelIgnorePanicOnAChanged;
extern NSString* ORMajoranaModelViewTypeChanged;
extern NSString* ORMajoranaModelPollTimeChanged;
extern NSString* ORMJDAuxTablesChanged;

