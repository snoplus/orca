//
//  ORMultiPlotController.m
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
#import "ORMultiPlotController.h"
#import "ORMultiPlot.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORDataSet.h"

@implementation ORMultiPlotController

#pragma mark ¥¥¥Initialization

-(id)init
{
    self = [super initWithWindowNibName:@"MultiPlot"];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(modelRemoved:)
                         name : ORMultiPlotRemovedNotification
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(modelRecached:)
                         name : ORMultiPlotReCachedNotification
                        object: model];


    [notifyCenter addObserver : self
                     selector : @selector(plotNameChanged:)
                         name : ORMultiPlotNameChangedNotification
                        object: model];

    int n = [model cachedCount];
    int i;
    for(i=0;i<n;i++){
        [notifyCenter addObserver : self
                         selector : @selector(dataChanged:)
                             name : ORDataSetDataChanged
                            object: [model cachedObjectAtIndex:i]];
    }
    
    [notifyCenter addObserver : self
                     selector : @selector(activePlotChanged:)
                         name : ORPlotter1DActiveCurveChanged
                        object: plotter];
    
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self activePlotChanged:nil];
    [self plotNameChanged:nil];
    [[plotter yScale] setRngLimitsLow:0 withHigh:5E9 withMinRng:25];
	[plotter setUseGradient:YES];

}

- (void) setModel:(id)aModel
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super setModel:aModel];
    [plotter setDataSource:model];
    [plotter initCurves];
    [self plotNameChanged:nil];
    [self activePlotChanged:nil];
    [self registerNotificationObservers];
}

- (void) setLegend
{
    int n = [model numberOfDataSetsInPlot:plotter];
    int maxn = [legendMatrix numberOfRows];
    int i;
    
    for(i=0;i<maxn;i++){
        [[legendMatrix cellWithTag:i] setStringValue:@""];
    }
    
    for(i=0;i<MIN(n,maxn);i++){
        if(i< [model count] && model && plotter){
            NSString* s = [NSString stringWithFormat:@"%@%@",i==[plotter activeCurveIndex]?@"-":@" ",[model objectAtIndex:i]];
            [[legendMatrix cellWithTag:i] setStringValue:s];
            [[legendMatrix cellWithTag:i]setTextColor:[plotter colorForDataSet:i]];
        }
        else {
            [[legendMatrix cellWithTag:i] setStringValue:@""];
        }
    }
    
}

- (void) plotNameChanged:(NSNotification*)aNote
{
	if(![model plotName])[model setPlotName:@"MultiPlot"];
	[plotNameField setStringValue:[model plotName]];
	[plotNameField resignFirstResponder];
	[[self window] setTitle:[model plotName]];
}

- (void) activePlotChanged:(NSNotification*)aNote
{
    if(aNote==nil || [aNote object] == plotter){
        [self setLegend];
    }
}

- (void) modelRemoved:(NSNotification*)aNote
{
    if([aNote object] == model){
        [[self window] close];
    }
}

- (void) modelRecached:(NSNotification*)aNote
{
    if([aNote object] == model){
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [plotter initCurves];
        [self activePlotChanged:nil];
        [self registerNotificationObservers];
    }
}

- (void) dataChanged:(NSNotification*)aNote
{
	if(!scheduledForUpdate){
        if([model dataSetInCache:[aNote object]]){
            scheduledForUpdate = YES;
            [self performSelector:@selector(postUpdate) withObject:nil afterDelay:1.0];
        }
	}
}

- (void) postUpdate
{
    [plotter setNeedsDisplay:YES];
	scheduledForUpdate = NO;
}

- (IBAction) plotNameAction:(id)sender;
{
    [model setPlotName:[sender stringValue]];
}


#pragma mark ¥¥¥Actions
- (IBAction) copy:(id)sender
{
	[plotter copy:sender];
}

#pragma mark ¥¥¥Data Source
- (int) numberOfDataSetsInPlot:(id)aPlotter
{
    return [model numberOfDataSetsInPlot:aPlotter];
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{     
    return [model numberOfPointsInPlot:aPlotter dataSet:set];
}

- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
    return [model plotter:aPlotter dataSet:set dataValue:x];
}

@end
