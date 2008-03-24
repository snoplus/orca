//
//  OR1DHistoController.h
//  Orca
//
//  Created by Mark Howe on Mon Jan 06 2003.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORDataController.h"

@class ORCalibration;

@interface OR1DHistoController : ORDataController {
	IBOutlet NSButton*		rebinCB;
	IBOutlet NSTextField*	rebinNumberTextField;
	IBOutlet NSButton*		calibrateButton;
	ORCalibration*		calibration;
	id						calibrationPanel;
}
- (id) init;
- (void) awakeFromNib;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) mousePositionChanged:(NSNotification*) aNote;
- (void) rebinNumberChanged:(NSNotification*) aNote;
- (void) rebinChanged:(NSNotification*) aNote;

- (IBAction) rebinAction:(id)sender;
- (IBAction) rebinNumberAction:(id)sender;
- (IBAction) calibrate:(id)sender;

@end
