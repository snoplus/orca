/*
 *  ORCV812Controller.h
 *  Orca
 *
 *  Created by Mark Howe on Tuesday, June 7, 2011.
 *  Copyright (c) 2011 CENPA, University of North Carolina. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sonsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark •••Imported Files

#import "ORCaenCardController.h"

// Definition of class.
@interface ORCV812Controller : ORCaenCardController {
	IBOutlet NSTextField* testPulseField;
	IBOutlet NSTextField* patternInhibitField;
	IBOutlet NSTextField* majorityThresholdField;
	IBOutlet NSTextField* deadTime0_7Field;
	IBOutlet NSTextField* deadTime8_15Field;
	IBOutlet NSTextField* outputWidth0_7Field;
	IBOutlet NSTextField* outputWidth8_15Field;
}

#pragma mark ***Initialization
- (id)		init;
 	
#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) testPulseChanged:(NSNotification*)aNote;
- (void) patternInhibitChanged:(NSNotification*)aNote;
- (void) majorityThresholdChanged:(NSNotification*)aNote;
- (void) deadTime0_7Changed:(NSNotification*)aNote;
- (void) deadTime8_15Changed:(NSNotification*)aNote;
- (void) outputWidth0_7Changed:(NSNotification*)aNote;
- (void) outputWidth8_15Changed:(NSNotification*)aNote;

#pragma mark ***Interface Management
- (void) updateWindow;
- (IBAction) testPulseAction:(id)sender;
- (IBAction) patternInhibitAction:(id)sender;
- (IBAction) majorityThresholdAction:(id)sender;
- (IBAction) deadTime0_7Action:(id)sender;
- (IBAction) deadTime8_15Action:(id)sender;
- (IBAction) outputWidth0_7Action:(id)sender;
- (IBAction) outputWidth8_15Action:(id)sender;

@end
