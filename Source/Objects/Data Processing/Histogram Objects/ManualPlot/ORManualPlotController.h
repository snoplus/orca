//
//  ORManualPlotController.h
//  Orca
//
//  Created by Mark Howe on Fri Apr 27 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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
#import "ORDataController.h"

@interface ORManualPlotController : ORDataController
{
    IBOutlet NSTableView* dataTableView;
	IBOutlet NSPopUpButton* col2KeyPU;
	IBOutlet NSPopUpButton* col1KeyPU;
	IBOutlet NSPopUpButton* col0KeyPU;
	IBOutlet NSTextField*   col0LabelField;
	IBOutlet NSTextField*   col1LabelField;
	IBOutlet NSTextField*   col2LabelField;
	IBOutlet NSTextField*   y1LengendField;
	IBOutlet NSTextField*   y2LengendField;
	id						calibrationPanel;
}

#pragma mark •••Initialization
- (id) init;

#pragma mark •••Interface Management
- (void) col0TitleChanged:(NSNotification*)aNote;
- (void) col1TitleChanged:(NSNotification*)aNote;
- (void) col2TitleChanged:(NSNotification*)aNote;
- (void) colKeyChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) dataChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) refreshPlot:(id)sender;
- (IBAction) col2KeyAction:(id)sender;
- (IBAction) col1KeyAction:(id)sender;
- (IBAction) col0KeyAction:(id)sender;
- (IBAction) writeDataFileAction:(id)sender;
- (IBAction) calibrate:(id)sender;

#pragma mark •••Data Source
- (int) numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
@end
