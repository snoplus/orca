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
// CLASS:		ORCaen1720Controller
// Purpose:		Handles the interaction between the user and the VC792 module.
//--------------------------------------------------------------------------------
#import "ORCaen1720Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCaen1720Model.h"


@implementation ORCaen1720Controller
#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"Caen1720" ];
    return self;
}

- (NSSize) thresholdDialogSize
{
	return NSMakeSize(290,370);
}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [ super registerNotificationObservers ];
	
	[notifyCenter addObserver:self
					 selector:@selector(dacChanged:)
						 name:caenChnlDacChanged
					   object:model];
	
	
}

#pragma mark ***Interface Management
- (void) updateWindow
{
   [ super updateWindow ];
   [self dacChanged:nil];
}

- (void) dacChanged: (NSNotification*) aNotification
{
	if(aNotification){
		int chnl = [[[aNotification userInfo] objectForKey:caenChnl] intValue];
		[[dacMatrix cellWithTag:chnl] setFloatValue:[model convertDacToVolts:[model dac:chnl]]];
	}
	else {
		int i;
		for (i = 0; i < [model numberOfChannels]; i++){
			[[dacMatrix cellWithTag:i] setFloatValue:[model convertDacToVolts:[model dac:i]]];
		}
	}
}


#pragma mark ***Interface Management - Module specific
- (NSString*) thresholdLockName {return @"ORCaen1720ThresholdLock";}
- (NSString*) basicLockName     {return @"ORCaen1720BasicLock";}

#pragma mark •••Actions
- (IBAction) dacAction:(id) aSender
{
	[[[model document] undoManager] setActionName:@"Set dacs"]; // Set name of undo.
	[model setDac:[[aSender selectedCell] tag] withValue:[model convertVoltsToDac:[[aSender selectedCell] floatValue]]]; // Set new value
}
@end
