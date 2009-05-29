//
//  ORSubPlotController.m
//  Orca
//
//  Created by Mark Howe on Mon Nov 03 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORSubPlotController.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORDataSetModel.h"

@implementation ORSubPlotController

+ (ORSubPlotController*) panel
{
    return [[[ORSubPlotController alloc] init] autorelease];
}

// This method initializes a new instance of this class which loads in nibs and facilitates the communcation between the nib and the controller of the main window.
-(id)init 
{
    if(self = [super init]){
	[NSBundle loadNibNamed:@"PlotSubview" owner:self];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [view removeFromSuperview];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self registerNotificationObservers];
}

- (ORPlotter1D*) plotter
{
    return plotter;
}

- (void) setModel:(id)aModel
{
    [plotter setDataSource:aModel];
    [plotter setNeedsDisplay:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self registerNotificationObservers];
    [title setStringValue:[aModel shortName]];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
     
    [notifyCenter addObserver : self
                     selector : @selector(dataChanged:)
                         name : ORDataSetDataChanged
                       object : [plotter dataSource]];
}

- (void) dataChanged:(NSNotification*)aNotification
{
    [plotter setNeedsDisplay:YES];
}


// This method returns a pointer to the view in the nib loaded.
-(NSView*)view
{
	return view;
}


- (IBAction) centerOnPeak:(id)sender
{
   [plotter centerOnPeak:sender]; 
}

- (IBAction) autoScale:(id)sender
{
    [plotter resetScales:sender];
}

- (IBAction) toggleLog:(id)sender
{
    [[plotter yScale] setLog:![[plotter yScale] isLog]];
}


@end
