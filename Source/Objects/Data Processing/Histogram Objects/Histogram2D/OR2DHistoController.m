//
//  OR2DHistoController.m
//  Orca
//
//  Created by Mark Howe on Thurs Dec 23 2004.
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
#import "OR2DHisto.h"
#import "OR2DHistoController.h"
#import "ORPlotter2D.h"
#import "ORAxis.h"


@implementation OR2DHistoController

#pragma mark ¥¥¥Initialization

-(id)init
{
    self = [super initWithWindowNibName:@"TwoDHisto"];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [[plotter xScale] setRngLimitsLow:0 withHigh:1024 withMinRng:16];
    [[plotter yScale] setRngLimitsLow:0 withHigh:1024 withMinRng:16];
    [[plotter zScale] setRngLimitsLow:0 withHigh:0xffffffff withMinRng:16];
    [[plotter yScale] setLog:NO];
	
	[plotter setBackgroundColor:[NSColor colorWithCalibratedRed:1. green:1. blue:1. alpha:1]];
	[plotter setGridColor:[NSColor grayColor]];
	[plotter  setDrawWithGradient:YES];
	
    NSSize minSize = [[self window] minSize];
    minSize.width = 335;
    minSize.height = 335;
    [[self window] setMinSize:minSize];
	[titleField setStringValue:[model fullNameWithRunNumber]];
}

- (void) dataSetChanged:(NSNotification*)aNotification
{
	[titleField setStringValue:[model fullNameWithRunNumber]];
	[super dataSetChanged:aNotification];
}

- (IBAction)logLin:(NSToolbarItem*)item 
{
	[[plotter zScale] setLog:![[plotter zScale] isLog]];
}

- (IBAction) zoomIn:(id)sender      
{ 
    [[plotter xScale] zoomIn:sender];
    [[plotter yScale] zoomIn:sender];
}
- (IBAction) zoomOut:(id)sender     
{ 
    [[plotter xScale] zoomOut:sender];
    [[plotter yScale] zoomOut:sender];
}

- (IBAction) hideShowControls:(id)sender
{
    [plotter setIgnoreDoNotDrawFlag:YES];
    unsigned int oldResizeMask = [containingView autoresizingMask];
    [containingView setAutoresizingMask:NSViewMinYMargin];

    NSRect aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] 
                styleMask:[[self window] styleMask]];
    NSSize minSize = [[self window] minSize];
    if([hideShowButton state] == NSOnState){
        aFrame.size.height += 90;
        minSize.height = 335;
    }
    else {
        aFrame.size.height -= 90;
        minSize.height = 335-90;
    }
    [[self window] setMinSize:minSize];
    [self resizeWindowToSize:aFrame.size];
    [containingView setAutoresizingMask:oldResizeMask];
    [plotter setIgnoreDoNotDrawFlag:NO];

}


#pragma mark ¥¥¥Actions
- (IBAction) copy:(id)sender
{
	[plotter copy:sender];
}

#pragma mark ¥¥¥Data Source
- (unsigned long*) plotter:(id) aPlotter dataSet:(int)set numberBinsPerSide:(unsigned short*)xValue
{
    return [model getDataSetAndNumBinsPerSize:xValue];
}

- (void) plotter:(id) aPlotter dataSet:(int)set xMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY
{
    [model getXMin:aMinX xMax:aMaxX yMin:aMinY yMax:aMaxY];
}

@end
