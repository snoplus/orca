//
//  ORFec32Controller.h
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORFec32Model.h"

#pragma mark •••Forward Declarations
@class ORFec32View;
@class ORFecPmtsView;

@interface ORFec32Controller : OrcaObjectController  {
    IBOutlet ORFec32View*	groupView;
	IBOutlet NSButton*		showVoltsCB;
	IBOutlet NSTextField*	commentsTextField;
    IBOutlet ORFecPmtsView* pmtView;
    IBOutlet NSTextField*	vResField;
    IBOutlet NSTextField*	hvRefField;
    IBOutlet NSMatrix*		cmosMatrix;
    IBOutlet NSButton*		lockButton;
	IBOutlet NSTextField*   lockDocField;
	IBOutlet NSTextField*   cardNumberField;
	
	NSNumberFormatter*		cmosFormatter;
}

#pragma mark •••Accessors
- (ORFec32View *)groupView;

#pragma mark •••Notifications
- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) showVoltsChanged:(NSNotification*)aNote;
- (void) commentsChanged:(NSNotification*)aNote;
- (void) updateButtons;
- (void) lockChanged:(NSNotification*)note;
- (void) groupChanged:(NSNotification*)note;
- (void) runStatusChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) vResChanged:(NSNotification*)aNote;
- (void) hvRefChanged:(NSNotification*)aNote;
- (void) cmosChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) incCardAction:(id)sender;
- (IBAction) decCardAction:(id)sender;
- (IBAction) showVoltsAction:(id)sender;
- (IBAction) commentsTextFieldAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) vResAction:(id)sender;
- (IBAction) hvRefAction:(id)sender;
- (IBAction) cmosAction:(id)sender;
@end
