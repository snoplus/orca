//
//  OR1DHistoController.m
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
#import "OR1DHisto.h"
#import "OR1DHistoController.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORCurve1D.h"

@implementation OR1DHistoController

#pragma mark ¥¥¥Initialization

-(id)init
{
    self = [super initWithWindowNibName:@"OneDHisto"];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
	[plotter setUseGradient:YES];
    [[plotter yScale] setRngLimitsLow:0 withHigh:5E9 withMinRng:25];
	[self rebinChanged:nil];
	[self rebinNumberChanged:nil];

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
                     selector : @selector(rebinChanged:)
                         name : OR1DHisotRebinChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rebinNumberChanged:)
                         name : OR1DHisotRebinNumberChanged
                       object : model];

}

- (void) rebinNumberChanged:(NSNotification*) aNote
{
	[rebinNumberTextField setIntValue:[model rebinNumber]];
    [plotter setNeedsDisplay:YES];
}

- (void) rebinChanged:(NSNotification*) aNote
{
	[rebinCB setIntValue:[model rebin]];
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


#pragma mark ¥¥¥Actions
- (IBAction) copy:(id)sender
{
	[plotter copy:sender];
}

- (IBAction) rebinAction:(id)sender
{
	[model setRebin:[sender intValue]];
}

- (IBAction) rebinNumberAction:(id)sender
{
	[model setRebinNumber:[sender intValue]];
}

#pragma mark ¥¥¥Data Source
- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
    return [model numberOfPointsInPlot:aPlotter dataSet:set];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [model numberBins];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if([[tableColumn identifier] isEqualToString:@"Value"])return [NSNumber numberWithInt:[model value:row]];
	else return [NSNumber numberWithInt:row];
}

@end
