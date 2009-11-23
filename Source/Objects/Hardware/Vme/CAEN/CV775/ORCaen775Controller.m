//--------------------------------------------------------------------------------
// CLASS:		ORCaen775Controller
// Purpose:		Handles the interaction between the user and the VC775 module.
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
#import "ORCaen775Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCaen775Model.h"


@implementation ORCaen775Controller
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
    self = [ super initWithWindowNibName: @"Caen775" ];
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
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(modelTypeChanged:)
                         name : ORCaen775ModelModelTypeChanged
						object: model];

}

#pragma mark ***Interface Management
- (void) modelTypeChanged:(NSNotification*)aNote
{
	[modelTypePU selectItemAtIndex: [model modelType]];
	if([model modelType] == kModel775){
		[thresholdB setEnabled:YES];
		[stepperB setEnabled:YES];
	}
	else {
		[thresholdB setEnabled:NO];
		[stepperB setEnabled:NO];
	}
}

- (void) updateWindow
{
   [ super updateWindow ];
	[self modelTypeChanged:nil];
}

#pragma mark ***Interface Management - Module specific
- (NSString*) thresholdLockName {return @"ORCaen775ThresholdLock";}
- (NSString*) basicLockName     {return @"ORCaen775BasicLock";}

#pragma mark ¥¥¥Actions
- (void) modelTypePUAction:(id)sender
{
	[model setModelType:[sender indexOfSelectedItem]];	
}
@end
