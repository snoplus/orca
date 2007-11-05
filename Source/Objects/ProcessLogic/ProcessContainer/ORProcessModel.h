//
//  ORContainerModel.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORContainerModel.h"

@class ORAlarm;

@interface ORProcessModel : ORContainerModel  
{
    BOOL		inTestMode;
    BOOL		processRunning;
    ORAlarm*	testModeAlarm;
    NSString*   comment;
    NSString*   shortName;
    float		sampleRate;
	NSDate*		lastSampleTime;
	BOOL		sampleGateOpen;
}

#pragma mark ***Accessors
- (void) startProcessCycle;
- (BOOL) sampleGateOpen;
- (void) endProcessCycle;

- (float) sampleRate;
- (void) setSampleRate:(float)aSampleRate;

- (NSString*) elementName;
- (id) stateValue;
- (NSString*) fullHwName;
- (BOOL) processRunning;
- (void) setProcessRunning:(BOOL)aState;
- (NSString*) comment;
- (void) setComment:(NSString*)aComment;
- (NSString*) shortName;
- (void) setShortName:(NSString*)aComment;
- (void) putInTestMode;
- (void) putInRunMode;

- (BOOL) inTestMode;
- (void) setInTestMode:(BOOL)aState;
- (void) postTestAlarm;
- (void) clearTestAlarm;

- (void) setUpImage;
- (void) makeMainController;
- (void) startRun;
- (void) stopRun;
- (void) startStopRun;
- (BOOL) changesAllowed;
- (int) compareStringTo:(id)anElement usingKey:(NSString*)aKey;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORProcessModelSampleRateChanged;
extern NSString* ORProcessModelShortNameChangedNotification;
extern NSString* ORProcessTestModeChangedNotification;
extern NSString* ORProcessRunningChangedNotification ;
extern NSString* ORProcessModelCommentChangedNotification;