
//
//  ORManualPlotController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright ¬© 2002 CENPA, University of Washington. All rights reserved.
//

#pragma mark •••Imported Files
#import "ORManualPlotController.h"
#import "ORManualPlotModel.h"
#import "ORPlotter1D.h"

@implementation ORManualPlotController

#pragma mark •••Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"ManualPlot"];
    return self;
}


#pragma mark •••Interface Management
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    
    [notifyCenter addObserver: self
                     selector: @selector(manualPlotLockChanged:)
                         name: ORManualPlotLock
                       object: model];

    [notifyCenter addObserver: self
                     selector: @selector(dataChanged:)
                         name: ORManualPlotDataChanged
                       object: model];

}

- (void) awakeFromNib
{
	[plotter setUseGradient:YES];
	[super awakeFromNib];
}

- (void) updateWindow
{
	[super updateWindow];
    [self manualPlotLockChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORManualPlotLock to:secure];
    [manualPlotLockButton setEnabled:secure];
}

- (void) dataChanged:(NSNotification*)aNotification
{
	[dataTableView reloadData];
	[plotter setNeedsDisplay:YES];
}

- (void) manualPlotLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORManualPlotLock];
    [manualPlotLockButton setState: locked];
}

#pragma mark •••Actions
- (IBAction)manualPlotLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORManualPlotLock to:[sender intValue] forWindow:[self window]];
}

#pragma mark •••Data Source
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [model numberBins];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if([[tableColumn identifier] isEqualToString:@"Value"])return [NSNumber numberWithInt:[model value:row]];
	else return [NSNumber numberWithInt:row];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if([[tableColumn identifier] isEqualToString:@"Value"]){
		[model setValue:[object intValue] channel:row];
	}
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
    return [model numberBins];
}

- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
    return [model value:x];
}

@end
