
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
	return [model numPoints];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return [model dataAtIndex:row key:[tableColumn identifier]];
}

- (BOOL) useXYPlot
{
	return YES;
}

- (int) 	numberOfDataSetsInPlot:(id)aPlotter
{
	return 2;
}

- (int) numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	return [model numPoints];
}
- (BOOL) plotter:(id)aPlotter dataSet:(int)set index:(unsigned long)index x:(float*)xValue y:(float*)yValue
{
	return [model dataSet:set index:index x:xValue y:yValue];
}

- (BOOL)   	willSupplyColors
{
    return YES;
}

- (NSColor*) colorForDataSet:(int)set
{
    switch(set){
        case 0:  return [NSColor redColor];
        case 1:  return [NSColor blueColor];
		default: return [NSColor colorWithCalibratedRed:10/255. green:90/255. blue:0 alpha:1];
    }
}
@end
