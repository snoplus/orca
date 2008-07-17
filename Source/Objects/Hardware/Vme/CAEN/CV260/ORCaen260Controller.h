//
//  ORCaen260Controller.h
//  Orca
//
//  Created by Mark Howe on 12/7/07
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nug Physics and 
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
#import "ORCaenCardController.h"

@interface ORCaen260Controller : ORCaenCardController {

	IBOutlet NSButton*		enableAllButton;
	IBOutlet NSButton*		disableAllButton;
	IBOutlet NSMatrix*		enabledMaskMatrix;
	IBOutlet NSMatrix*		channelLabelMatrix;
    IBOutlet NSTextField* 	addressText;
    IBOutlet NSButton*		initButton;
	IBOutlet NSButton*		probeButton;

	IBOutlet NSButton*		setInhibitButton;
	IBOutlet NSButton*		resetInhibitButton;

}

- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) enabledMaskChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNotification;

#pragma mark •••Actions
- (IBAction) enabledMaskAction:(id)sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) probeBoard:(id)sender;
- (IBAction) enableAllAction:(id)sender;
- (IBAction) disableAllAction:(id)sender;
- (IBAction) setInhibitAction:(id)sender;
- (IBAction) retsetInhibitAction:(id)sender;
@end
