//
//  ORProcessHWAccessor.h
//  Orca
//
//  Created by Mark Howe on Sat Dec 3,2005.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORProcessElementModel.h"
#import "ORBitProcessing.h"

@interface ORProcessHWAccessor : ORProcessElementModel
{
    NSString* hwName;
    id  hwObject;
    int bit;
	BOOL startOnce;
	BOOL stopOnce;
}

- (id) init;
- (void) dealloc;
- (void) awakeAfterDocumentLoaded;
- (void) registerNotificationObservers;
- (void) objectsRemoved:(NSNotification*) aNote;
- (void) objectsAdded:(NSNotification*) aNote;
- (void) slotChanged:(NSNotification*) aNote;

- (void) addOverLay;
- (NSString*) hwName;
- (void) setHwName:(NSString*) anObject;
- (void) setGuardian:(id)aGuardian;
- (void) processIsStarting;
- (void) processIsStopping;

- (id) hwObject;
- (void) setHwObject:(id) anObject;
- (int) bit;
- (void) setBit:(int)aBit;
- (NSArray*) validObjects;
- (void) useHWObjectWithName:(NSString*)aName;
- (void) viewSource;

@end

extern NSString* ORProcessHWAccessorHwObjectChangedNotification;
extern NSString* ORProcessHWAccessorBitChangedNotification;
extern NSString* ORProcessHWAccessorHwNameChangedNotification;
extern NSString* ORHWAccessLock;
