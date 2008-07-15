//
//  ORHP4405AController.m
//  Orca
//
//  Created by J. A. Formaggio on Tue Jul 15 2008.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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

#import "ORHP4405AController.h"
#import "ORHP4405AModel.h"

@implementation ORHP4405AController

#pragma mark ¥¥¥Initialization
//--------------------------------------------------------------------------------
/*!\method  init
 * \brief	Top level initialization routine.  Calls inherited class initWith-
 *			WindowNibName that makes sure that correct nib is used for controller.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) init
{
    self = [ super initWithWindowNibName: @"ORHP4405A" ];
    return self;
}



//--------------------------------------------------------------------------------
/*!\method  registerNotificationObservers
 * \brief	Registers following messages: 
 *				1) Change primary address.
 *				2) Change secondary address.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
          
    [ notifyCenter addObserver: self
                      selector: @selector( lockChanged: )
                          name: ORRunStatusChangedNotification
                        object: nil];
    
     [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORHP4405ALock
                        object: model];

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

//--------------------------------------------------------------------------------
/*!\method  settingsLockName
 * \brief	Returns the lock name for this controller.
 * \note	
 */
//--------------------------------------------------------------------------------
- (NSString*) settingsLockName
{
    return ORHP4405ALock;
}

//--------------------------------------------------------------------------------
/*!\method  gpibLockName
 * \brief	Returns the GPIB lock name for this controller.
 * \note	
 */
//--------------------------------------------------------------------------------
- (NSString*) gpibLockName
{
    return ORHP4405AGpibLock;
}

- (IBAction)attenutation:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)burstType:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)calWideband:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)centerFreq:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)channelTCS:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)delay:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)detFormat:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)freqUnit:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)iqInvert:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)measType:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)modeType:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)opt10MHz:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)optFreq:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)refFilter:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)refLevel:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)refUnit:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)scaleLevel:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)scaleUnit:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)searchLengthUnit:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)searchLengthValue:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)searchThreshUnit:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)searchThreshValue:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)startFreq:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)stopFreq:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)symbolRate:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)symbolUnit:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)timeSlot:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)traceMode:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)triggerPolarity:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction)triggerType:(id)sender
{
	NS_DURING
		[model doNothing];

	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

@end
