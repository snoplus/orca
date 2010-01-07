//
//  ORExperimentModel.h
//  Orca
//
//  Created by Mark Howe on 12/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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

@class ORSegmentGroup;
@class ORAlarm;

@interface ORExperimentModel : OrcaObject {
	NSMutableArray* segmentGroups;
	int				hardwareCheck;
	int				cardCheck;
	NSDate*			captureDate;
	NSMutableArray* problemArray;
	ORAlarm*		failedHardwareCheckAlarm;
	ORAlarm*		failedCardCheckAlarm;
	BOOL			replayMode;
	NSString*		selectionString;
	BOOL			somethingSelected;
	int				displayType;
	BOOL			scheduledToHistogram;
    BOOL showNames;
}

- (id) init;
- (void) registerNotificationObservers;
- (NSMutableArray*) initMapEntries:(int)index;

#pragma mark •••Accessors
- (BOOL) showNames;
- (void) setShowNames:(BOOL)aShowNames;
- (int) displayType;
- (void) setDisplayType:(int)aDisplayType;
- (NSString*) selectionString;
- (void) setSelectionString:(NSString*)aSelectionString;
- (BOOL) replayMode;
- (void) setReplayMode:(BOOL)aReplayMode;
- (void) collectRates;
- (NSDate *) captureDate;
- (void) setCaptureDate: (NSDate *) aCaptureDate;
- (int) hardwareCheck;
- (void) setHardwareCheck: (int) HardwareCheck;
- (int) cardCheck;
- (void) setCardCheck: (int) cardCheck;
- (void) setCardCheckFailed;
- (void) setHardwareCheckFailed;
- (int) numberOfSegmentGroups;
- (ORSegmentGroup*) segmentGroup:(int)aSet;
- (BOOL) somethingSelected;
- (void) setSomethingSelected:(BOOL)aFlag;
- (void) clearTotalCounts;

#pragma mark •••Convience Methods
- (void) clearAlarm:(NSString*)aName;
- (void) postAlarm:(NSString*)aName;
- (void) postAlarm:(NSString*)aName severity:(int)aSeverity;
- (void) postAlarm:(NSString*)aName severity:(int)aSeverity reason:(NSString*)aReason;

#pragma mark •••Work Methods
- (void) compileHistograms;
- (BOOL) preRunChecks;
- (void) printProblemSummary;
- (NSString*) crateKey:(NSDictionary*)aDicionary;

#pragma mark •••Subclass Responsibility
- (void) makeSegmentGroups;
- (int)  maxNumSegments;

#pragma mark •••Group Methods
- (void) addGroup:(ORSegmentGroup*)aGroup;
- (void) selectedSet:(int)aSet segment:(int)index;
- (void) registerForRates;
- (void) collectRatesFromAllGroups;
- (ORSegmentGroup*) segmentGroup:(int)aSet;
- (void) showDialogForSet:(int)setIndex segment:(int)index;
- (void) showDataSetForSet:(int)aSet segment:(int)index;
- (void) setSegmentErrorClassName:(NSString*)aClassName card:(int)card channel:(int)channel;
- (void) histogram;
- (void) initHardware;

#pragma mark •••Specific Dialog Lock Methods
- (NSString*) experimentMapLock;
- (NSString*) experimentDetectorLock;
- (NSString*) experimentDetailsLock;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) captureState;
- (NSString*) capturePListsFile;

@end

extern NSString* ORExperimentModelShowNamesChanged;
extern NSString* ExperimentModelDisplayTypeChanged;
extern NSString* ExperimentModelSelectionStringChanged;
extern NSString* ExperimentHardwareCheckChangedNotification;
extern NSString* ExperimentCardCheckChangedNotification;
extern NSString* ExperimentCaptureDateChangedNotification;
extern NSString* ExperimentDisplayUpdatedNeeded;
extern NSString* ExperimentCollectedRates;
extern NSString* ExperimentDisplayHistogramsUpdated;
extern NSString* ExperimentModelSelectionChanged;

