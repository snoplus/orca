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
@class ORFecPmtsView;
@class ORGroupView;

@interface ORFec32Controller : OrcaObjectController  {
    IBOutlet ORGroupView*	groupView;
	IBOutlet NSButton*		showVoltsCB;
	IBOutlet NSTextField*	commentsTextField;
    IBOutlet ORFecPmtsView* pmtView;
    IBOutlet NSTextField*	vResField;
    IBOutlet NSTextField*	hvRefField;
    IBOutlet NSMatrix*		cmosMatrix;
    IBOutlet NSButton*		lockButton;
	IBOutlet NSTextField*   lockDocField;
	IBOutlet NSTextField*	crateNumberField;
	IBOutlet NSTextField*   fecNumberField;
	IBOutlet NSMatrix*		pmtImages0;
	IBOutlet NSMatrix*		onlineSwitches0;
	IBOutlet NSMatrix*		onlineSwitches1;
	IBOutlet NSMatrix*		onlineSwitches2;
	IBOutlet NSMatrix*		onlineSwitches3;
	IBOutlet NSMatrix*		pmtImages1;
	IBOutlet NSMatrix*		pmtImages2;
	IBOutlet NSMatrix*		pmtImages3;
	IBOutlet NSTextField*	boardIdField;
    IBOutlet NSButton*		initButton;
	IBOutlet NSButton*		autoInitButton;
	IBOutlet NSButton*		readVoltagesButton;
	IBOutlet NSMatrix*		monitorValueLabelsMatrix;
	IBOutlet NSMatrix*		monitorValuesMatrix;
	IBOutlet NSMatrix*		monitorValueUnitsMatrix;
	NSNumberFormatter*		cmosFormatter;

	//cache some stuff to make things easier
	NSMatrix* onlineSwitches[4];
	NSMatrix* pmtImages[4];
	NSImage* onlineStateImage[4][2];
}

#pragma mark •••Accessors
- (ORGroupView *)groupView;

#pragma mark •••Notifications
- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) adcStatusChanged:(NSNotification*)aNote;
- (void) loadAdcStatus:(int)i;
- (void) enablePmtGroup:(short)enabled groupNumber:(short)group;
- (void) onlineMaskChanged:(NSNotification*)aNote;
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
- (void) boardIdChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) initAction:(id)sender;
- (IBAction) probeAction:(id)sender;
- (IBAction) onlineMaskAction:(id)sender;
- (IBAction) incCardAction:(id)sender;
- (IBAction) decCardAction:(id)sender;
- (IBAction) showVoltsAction:(id)sender;
- (IBAction) commentsTextFieldAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) vResAction:(id)sender;
- (IBAction) hvRefAction:(id)sender;
- (IBAction) cmosAction:(id)sender;
- (IBAction) autoInitAction:(id)sender;
- (IBAction) readVoltagesAction:(id)sender;

@end
