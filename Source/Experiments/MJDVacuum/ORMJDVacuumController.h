//
//  ORMJDVacuumController.h
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
//  Copyright © 2012 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Forward Declarations
@class ORMJDVacuumView;

@interface ORMJDVacuumController : OrcaObjectController
{
    IBOutlet ORMJDVacuumView*   groupView;
	IBOutlet NSButton*		setShowGridCB;
	IBOutlet NSPanel*		gvControlPanel;
	IBOutlet NSButton*      gvControlButton;
	IBOutlet NSTextField*   gvControlField;
	IBOutlet NSTextField*   gvControlValveState;
	IBOutlet NSTextField*   gvControlPressureSide1;
	IBOutlet NSTextField*   gvOpenToText1;
	IBOutlet NSTextField*   gvControlPressureSide2;
	IBOutlet NSTextField*   gvOpenToText2;
	IBOutlet NSTableView*   adcTableView;
	IBOutlet NSTableView*   gvTableView;
	IBOutlet NSTextField*   gvHwObjectName;
}

- (id) init;
- (void) awakeFromNib;

#pragma mark *Accessors
- (BOOL) showGrid;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) showGridChanged:(NSNotification*)aNote;
- (void) toggleGrid;

#pragma mark ***Interface Management
- (void) vetoMaskChanged:(NSNotification*)aNote;
- (void) stateChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) showGridAction:(id)sender;
- (IBAction) openGVControlPanel:(id)sender;
- (IBAction) closeGVChangePanel:(id)sender;
- (IBAction) changeGVAction:(id)sender;

#pragma mark •••Data Source For Tables
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn 
			 row:(int) rowIndex;

@end

