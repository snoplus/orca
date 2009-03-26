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
    IBOutlet ORPlotter1D* plotter;
}

#pragma mark •••Initialization
- (id) init;

#pragma mark •••Interface Management
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) dataChanged:(NSNotification*)aNote;

#pragma mark •••Actions

#pragma mark •••Data Source
- (int) numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
@end
