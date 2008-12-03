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
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)burstType:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)calWideband:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)centerFreq:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)channelTCS:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)delay:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)detFormat:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)freqUnit:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)iqInvert:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)measType:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)modeType:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)opt10MHz:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)optFreq:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)refFilter:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)refLevel:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)refUnit:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)scaleLevel:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)scaleUnit:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)searchLengthUnit:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)searchLengthValue:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)searchThreshUnit:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)searchThreshValue:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)startFreq:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)stopFreq:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)symbolRate:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)symbolUnit:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)timeSlot:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)traceMode:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)triggerPolarity:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction)triggerType:(id)sender
{
	@try {
		[model doNothing];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

@end
