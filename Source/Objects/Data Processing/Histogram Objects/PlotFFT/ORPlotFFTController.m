//
//  ORPlotFFTController.m
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
#import "ORPlotFFTController.h"
#import "ORPlotFFT.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORCurve1D.h"

@implementation ORPlotFFTController

#pragma mark ¥¥¥Initialization

-(id)init
{
    self = [super initWithWindowNibName:@"PlotFFT"];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [[plotter yScale] setRngLimitsLow:0 withHigh:5E9 withMinRng:25];
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
    
     [notifyCenter addObserver : self
                     selector : @selector(showChanged:)
                         name : ORPlotFFTShowChanged
                       object : model];

}

- (void) updateWindow
{
	[super updateWindow];
	[self showChanged:nil];
	[self mousePositionChanged:nil];
}

- (void) showChanged:(NSNotification*) aNote
{
	[[showMatrix cellWithTag:0] setIntValue:[model showReal]];
	[[showMatrix cellWithTag:1] setIntValue:[model showImaginary]];
	[[showMatrix cellWithTag:2] setIntValue:[model showPowerSpectrum]];
	[plotter setNeedsDisplay:YES];
}

- (void) mousePositionChanged:(NSNotification*) aNote
{
    if([aNote userInfo]){
        NSDictionary* info = [aNote userInfo];
        int x = [[info objectForKey:@"x"] intValue];
        float y = [[info objectForKey:@"y"] floatValue];
        [positionField setStringValue:[NSString stringWithFormat:@"x: %d  y: %.0f",x,y]];
    }
    else {
        [positionField setStringValue:@""];
    }
}

- (IBAction) showAction:(id)sender
{
	if([[sender selectedCell] tag] == 0) [model setShowReal:[[sender selectedCell] intValue]];
	else if([[sender selectedCell] tag] == 1) [model setShowImaginary:[[sender selectedCell] intValue]];
	else [model setShowPowerSpectrum:[[sender selectedCell] intValue]];
}

- (BOOL) useDataObject:(id)aPlotter  dataSet:(int)set
{
	return NO;
}
- (BOOL)   	willSupplyColors
{
    return YES;
}

- (NSColor*) colorForDataSet:(int)set
{
    return [model colorForDataSet:set];
}

- (int) numberOfDataSetsInPlot:(id)aPlotter
{
	return [model numberOfDataSetsInPlot:aPlotter];
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
    return [model numberOfPointsInPlot:aPlotter dataSet:set];
}

- (float) plotter:(id) aPlotter  dataSet:(int)set dataValue:(int) x
{
    return [model plotter:aPlotter dataSet:set dataValue:x];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [model numberChans];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if([[tableColumn identifier] isEqualToString:@"Real"]){
		return [NSNumber numberWithFloat:[model plotter:nil dataSet:0 dataValue:row]];
	}
	else if([[tableColumn identifier] isEqualToString:@"Imaginary"]){
		return [NSNumber numberWithFloat:[model plotter:nil dataSet:1 dataValue:row]];
	}
	else if([[tableColumn identifier] isEqualToString:@"PowerSpectrum"]){
		return [NSNumber numberWithFloat:[model plotter:nil dataSet:2 dataValue:row]];
	}
	else return [NSNumber numberWithInt:row];
}

@end
