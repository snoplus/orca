//-------------------------------------------------------------------------
//  ORSIS3800Controller.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h"
#import "ORSIS3800Model.h"
@class ORValueBar;
@class ORPlotView;

@interface ORSIS3800Controller : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
	IBOutlet NSPopUpButton* lemoInModePU;
	IBOutlet NSMatrix*		countEnableMatrix0;
	IBOutlet NSMatrix*		countEnableMatrix1;
	IBOutlet NSMatrix*		countEnableMatrix2;
	IBOutlet NSMatrix*		countEnableMatrix3;

	IBOutlet NSMatrix*		countMatrix0;
	IBOutlet NSMatrix*		countMatrix1;
	IBOutlet NSMatrix*		countMatrix2;
	IBOutlet NSMatrix*		countMatrix3;
	
	//base address
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;
	
	IBOutlet NSTextField*	moduleIDField;
    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      initButton;
	IBOutlet NSTextField*	lemoInText;
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) lemoInModeChanged:(NSNotification*)aNote;
- (void) countEnableMaskChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) moduleIDChanged:(NSNotification*)aNote;
- (void) countersChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) lemoInModeAction:(id)sender;
- (IBAction) countEnableMask1Action:(id)sender;
- (IBAction) countEnableMask2Action:(id)sender;
- (IBAction) countEnableMask3Action:(id)sender;
- (IBAction) countEnableMask4Action:(id)sender;

- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) probeBoardAction:(id)sender;
- (IBAction) readNoClear:(id)sender;
- (IBAction) readAndClear:(id)sender;
- (IBAction) clearAll:(id)sender;

@end
