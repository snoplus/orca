//
//  ORMJDPumpCartController.h
//  Orca
//
//  Created by Mark Howe on Mon Aug 13, 2012.
//  Copyright ¬© 2012 CENPA, University of North Carolina. All rights reserved.
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
@class ORMJDPumpCartView;

@interface ORMJDPumpCartController : OrcaObjectController
{
    IBOutlet ORMJDPumpCartView*   vacuumView;
	IBOutlet NSButton*		setShowGridCB;
	IBOutlet NSTableView*   valueTableView;
	IBOutlet NSTableView*   statusTableView;
	IBOutlet NSTableView*   gvTableView;
	IBOutlet NSTextField*   gvHwObjectName;
    IBOutlet NSButton*      lockButton;
	IBOutlet ORGroupView*   subComponentsView;
	
    IBOutlet ORMJDPumpCartView*   testStand0;
    IBOutlet ORMJDPumpCartView*   testStand1;
    IBOutlet ORMJDPumpCartView*   testStand2;
    IBOutlet ORMJDPumpCartView*   testStand3;
    IBOutlet ORMJDPumpCartView*   testStand4;
    IBOutlet ORMJDPumpCartView*   testStand5;
    IBOutlet ORMJDPumpCartView*   testStand6;

	BOOL					updateScheduled;
}

- (id) init;
- (void) awakeFromNib;

#pragma mark *Accessors
- (BOOL) showGrid;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) showGridChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
-(void) groupChanged:(NSNotification*)aNote;
- (void) toggleGrid;

#pragma mark ***Interface Management
- (void) stateChanged:(NSNotification*)aNote;
- (void) delayedRefresh;

#pragma mark •••Actions
- (IBAction) showGridAction:(id)sender;
- (IBAction) lockAction:(id) sender;

#pragma mark •••Data Source For Tables
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn 
			 row:(int) rowIndex;

@end

