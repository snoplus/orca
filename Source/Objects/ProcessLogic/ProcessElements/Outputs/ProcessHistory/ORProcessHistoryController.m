//
//  ORProcessHistoryController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORProcessHistoryController.h"
#import "ORProcessHistoryModel.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORProcessThread.h"

@implementation ORProcessHistoryController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"ProcessHistory"];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[[plotter yScale] setRngLimitsLow:0 withHigh:20 withMinRng:5];
	[[plotter yScale] setRngDefaultsLow:0 withHigh:20];

	[[plotter xScale] setRngLimitsLow:0 withHigh:5000 withMinRng:10];

}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(dataChanged:)
                         name : ORHistoryElementDataChanged
                       object : model];
}

- (void) updateWindow
{
	[super updateWindow];
}


- (void) dataChanged:(NSNotification*)aNotification
{
    if(!scheduledToUpdate){
        [self performSelector:@selector(doUpdate) withObject:nil afterDelay:1.0];
        scheduledToUpdate = YES;
    }
}

- (void) doUpdate
{
    scheduledToUpdate = NO;
	[plotter setNeedsDisplay:YES];
}

#pragma mark ¥¥¥Plot Data Source
- (int) numberOfDataSetsInPlot:(id)aPlotter
{
	return [model numberOfDataSetsInPlot:aPlotter];
}

- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	return [model numberOfPointsInPlot:aPlotter dataSet:set];
}

- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
	 return [model plotter:aPlotter dataSet:set dataValue:x];

}
@end
