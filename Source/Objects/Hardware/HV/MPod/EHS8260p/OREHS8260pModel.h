//
//  OREHS8260pModel.h
//  Orca
//
//  Created by Mark Howe on Tues Feb 1,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files

#import "ORiSeg8ChanHV.h"

@interface OREHS8260pModel : ORiSeg8ChanHV
{
  @private
    short		tripTime[8];
    short		currentTripBehavior[8];
    short		outputFailureBehavior[8];
}

#pragma mark ***Initialization
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (short)		outputFailureBehavior:(short)chan;
- (void)	setOutputFailureBehavior:(short)chan withValue:(short)aValue;
- (short)		currentTripBehavior:(short)chan;
- (void)	setCurrentTripBehavior:(short)chan withValue:(short)aValue;
- (short)	tripTime:(short)chan;
- (void)	setTripTime:(short)chan withValue:(short)aValue;
- (NSString*) settingsLock;
- (NSString*) name;
- (NSString*) behaviourString:(int)channel;

#pragma mark •••Hardware Access
- (void) writeTripTime:(int)channel;
- (void) writeTripTimes;
- (void) writeSupervisorBehaviours;
- (void) writeSupervisorBehaviour:(int)channel;
- (void) loadAllValues;

#pragma mark •••Hardware Wizard
- (NSArray*) wizardSelections;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
@end

extern NSString* OREHS8260pModelOutputFailureBehaviorChanged;
extern NSString* OREHS8260pModelCurrentTripBehaviorChanged;
extern NSString* OREHS8260pModelSupervisorMaskChanged;
extern NSString* OREHS8260pModelTripTimeChanged;
extern NSString* OREHS8260pSettingsLock;
