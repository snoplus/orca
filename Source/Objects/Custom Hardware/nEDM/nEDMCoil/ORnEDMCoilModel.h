//
//  ORnEDMCoilModel.h
//  Orca
//
//  Created by Michael Marino 15 Mar 2012 
//  Copyright © 2002 CENPA, University of Washington. All rights reserved
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
#import "OrcaObject.h"
#import "OROrderedObjHolding.h"

@interface ORnEDMCoilModel : ORGroup <OROrderedObjHolding> {
    NSMutableDictionary* objMap;
    BOOL isRunning;
    float pollingFrequency;
}

- (void) setUpImage;
- (void) makeMainController;
- (int) rackNumber;
- (BOOL) isRunning;
- (float) pollingFrequency;
- (void) setPollingFrequency:(float)aFrequency;
- (void) toggleRunState;

#pragma mark •••Notifications
- (void) registerNotificationObservers;

#pragma mark •••ORGroup
- (void) objectCountChanged;

#pragma mark •••OROrderedObjHolding Protocol
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
@end

extern NSString* ORnEDMCoilPollingActivityChanged;
extern NSString* ORnEDMCoilPollingFrequencyChanged;
