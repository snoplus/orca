//
//  ORPlotTimeSeriesController.m
//  Orca
//
//  Created by Mark Howe on Mon Jan 06 2003.
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
#import "ORPlotTimeSeriesController.h"
#import "ORPlotTimeSeries.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORCurve1D.h"
#import "ORTimeSeries.h"

@implementation ORPlotTimeSeriesController

#pragma mark ¥¥¥Initialization

-(id)init
{
    self = [super initWithWindowNibName:@"PlotTimeSeries"];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
	[[plotter yScale]  setInteger:NO];
    [[plotter yScale] setRngLimitsLow:-500 withHigh:5E9 withMinRng:.5];
    [[plotter yScale] setRngDefaultsLow:0 withHigh:500];
	[self updateWindow];

}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
     [notifyCenter addObserver : self
                     selector : @selector(mousePositionChanged:)
                         name : ORPlotter1DMousePosition
                       object : plotter];
    
}

- (void) updateWindow
{
	[super updateWindow];
	[self mousePositionChanged:nil];
}

- (void) mousePositionChanged:(NSNotification*) aNote
{
    if([aNote userInfo]){
        NSDictionary* info = [aNote userInfo];
        int y = [[info objectForKey:@"y"] intValue];
        NSTimeInterval t = [[info objectForKey:@"x"] floatValue];
		NSCalendarDate* theDate = [NSCalendarDate dateWithTimeIntervalSince1970:t];
		[theDate setCalendarFormat:@"%m/%d/%y %H:%M:%S"];
        [positionField setStringValue:[NSString stringWithFormat:@"time: %@  y: %.0f",theDate,y]];
    }
    else {
        [positionField setStringValue:@""];
    }
}

#pragma mark ¥¥¥Actions
- (IBAction) copy:(id)sender
{
	[plotter copy:sender];
}

#pragma mark ¥¥¥Data Source
- (int) numberOfDataSetsInPlot:(id)aPlotter
{
    return 1;
}

- (BOOL) useXYTimePlot
{
	return YES;
}

- (NSTimeInterval) plotterStartTime:(id)aPlotter
{
	return (NSTimeInterval)[[model timeSeries] startTime];
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	return [[model timeSeries] count];
}

- (float)  plotter:(id) aPlotter dataSet:(int)set dataValue:(int)i
{
	ORTimeSeries* ts = [model timeSeries];
	unsigned long theTime;
	float y;
	[ts index:i time:&theTime value:&y];
	return y;
}

- (void)  plotter:(id) aPlotter dataSet:(int)set index:(int)i time:(unsigned long*)x y:(float*)y
{
	[[model timeSeries] index:i time:x value:y];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[model timeSeries] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if([[tableColumn identifier] isEqualToString:@"Value"])return [NSNumber numberWithFloat:[[model timeSeries] valueAtIndex:row]];
	else return [NSDate dateWithTimeIntervalSince1970:[[model timeSeries] timeAtIndex:row]];
}


@end
