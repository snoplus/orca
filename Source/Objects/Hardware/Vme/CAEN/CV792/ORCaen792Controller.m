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
//--------------------------------------------------------------------------------
// CLASS:		ORCaen792Controller
// Purpose:		Handles the interaction between the user and the VC792 module.
//--------------------------------------------------------------------------------
#import "ORCaen792Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCaen792Model.h"


@implementation ORCaen792Controller
#pragma mark ***Initialization
//--------------------------------------------------------------------------------
/*!
 * \method	init
 * \brief	Initialize interface with hardware object.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) init
{
    self = [ super initWithWindowNibName: @"Caen792" ];
    return self;
}



#pragma mark ¥¥¥Notifications
//--------------------------------------------------------------------------------
/*!\method  registerNotificationObservers
 * \brief	Register notices that we want to receive.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) registerNotificationObservers
{
    [ super registerNotificationObservers ];
}

#pragma mark ***Interface Management
//--------------------------------------------------------------------------------
/*!\method  updateWindow
 * \brief	Sets all GUI values to current model values.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) updateWindow
{
   [ super updateWindow ];
}

#pragma mark ***Interface Management - Module specific
- (NSString*) thresholdLockName {return @"ORCaen792ThresholdLock";}
- (NSString*) basicLockName     {return @"ORCaen792BasicLock";}

#pragma mark ¥¥¥Actions
@end
