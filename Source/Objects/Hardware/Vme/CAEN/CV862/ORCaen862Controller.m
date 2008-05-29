/*
 *  ORCaen862Controller.m
 *  Orca
 *
 *  Created by Mark Howe on Thurs May 29 2008.
 *  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
 *
 */
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

#import "ORCaen862Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCaen862Model.h"

@implementation ORCaen862Controller

#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"Caen862" ];
    return self;
}



#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [ super registerNotificationObservers ];
}

#pragma mark ***Interface Management
- (void) updateWindow
{
   [ super updateWindow ];
}

#pragma mark ***Interface Management - Module specific
- (NSString*) thresholdLockName {return @"ORCaen862ThresholdLock";}
- (NSString*) basicLockName     {return @"ORCaen862BasicLock";}

#pragma mark •••Actions
@end
