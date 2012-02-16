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

#define kUseTubeView	0
#define kUseCrateView	1
#define kUsePSUPView	2
#define kNumTubes	20 //XL3s

@interface SNOPModel :  ORExperimentModel
{
	int             viewType;
    NSString*       morcaUserName;
    NSString*       morcaPassword;
    NSString*       morcaDBName;
    unsigned int    morcaPort;
    NSString*       morcaIPAddress;
    unsigned int    morcaUpdateTime;
    BOOL            morcaIsVerbose;
    BOOL            morcaIsWithinRun;
    NSString*       morcaStatus;
    BOOL            morcaIsUpdating;
}

@property (copy)    NSString* morcaUserName;
@property (copy)    NSString* morcaPassword;
@property (copy)    NSString* morcaDBName;
@property (assign)  unsigned int morcaPort;
@property (copy)    NSString* morcaIPAddress;
@property (assign)  unsigned int morcaUpdateTime;
@property (assign)  BOOL morcaIsVerbose;
@property (assign)  BOOL morcaIsWithinRun;
@property (copy)    NSString* morcaStatus;
@property (assign)  BOOL morcaIsUpdating;

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
extern NSString* ORSNOPModelMorcaIsVerboseChanged;
extern NSString* ORSNOPModelMorcaIsWithinRunChanged;
extern NSString* ORSNOPModelMorcaUpdateTimeChanged;
extern NSString* ORSNOPModelMorcaPortChanged;
extern NSString* ORSNOPModelMorcaStatusChanged;
extern NSString* ORSNOPModelMorcaUserNameChanged;
extern NSString* ORSNOPModelMorcaPasswordChanged;
extern NSString* ORSNOPModelMorcaDBNameChanged;
extern NSString* ORSNOPModelMorcaIPAddressChanged;
extern NSString* ORSNOPModelMorcaIsUpdatingChanged;
