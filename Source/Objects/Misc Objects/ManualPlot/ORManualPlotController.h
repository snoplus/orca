//
//  ORManualPlotController.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright ¬© 2002 CENPA, University of Washington. All rights reserved.
//

@class ORPlotter1D;

@interface ORManualPlotController : OrcaObjectController
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
    IBOutlet ORPlotter1D* plotter;
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

#pragma mark •••Data Source
- (int) numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
@end
