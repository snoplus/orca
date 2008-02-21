//
//  ORIP320Controller.h
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
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
#import "ORIP320Model.h"

@interface ORIP320Controller : OrcaObjectController  {
    @private
        IBOutlet NSTabView*   tabView;
        IBOutlet NSTableView* valueTable1;
        IBOutlet NSTableView* valueTable2;
        IBOutlet NSTableView* calibrationTable1;
        IBOutlet NSTableView* calibrationTable2;
        IBOutlet NSTableView* alarmTable1;
        IBOutlet NSTableView* alarmTable2;
        IBOutlet NSPopUpButton* pollingButton;
        IBOutlet NSButton*		displayRawCB;
    
        NSView *blankView;
        NSSize adcValueSize;
        NSSize calibrationSize;
        NSSize alarmSize;
		BOOL   scheduledToUpdate;

}

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

#pragma mark ***Interface Management
- (void) displayRawChanged:(NSNotification*)aNote;
- (void) pollingStateChanged:(NSNotification*)aNotification;
- (void) valuesChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) displayRawAction:(id)sender;
- (IBAction) readAll:(id)sender;
- (IBAction) setPollingAction:(id)sender;
- (IBAction) enablePollAllAction:(id)sender;
- (IBAction) enablePollNoneAction:(id)sender;
- (IBAction) enableAlarmAllAction:(id)sender;
- (IBAction) enableAlarmNoneAction:(id)sender;

@end

