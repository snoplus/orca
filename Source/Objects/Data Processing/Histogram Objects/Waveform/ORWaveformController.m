//
//  ORWaveformController.m
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
#import "ORWaveformController.h"
#import "ORWaveform.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"

@implementation ORWaveformController

#pragma mark ¥¥¥Initialization


-(id)init
{
    self = [super initWithWindowNibName:@"Waveform"];
    return self;
}


- (void) awakeFromNib
{
    [super awakeFromNib];
	[self differentiateChanged:nil];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(differentiateChanged:)
                         name : ORPlotter1DDifferentiateChanged
                        object: [self plotter]];
	
    [notifyCenter addObserver : self
                     selector : @selector(averageWindowChanged:)
                         name : ORPlotter1DAverageWindowChanged
                        object: [self plotter]];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(integrateChanged:)
                         name : ORWaveformIntegrateChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(baselineValueChanged:)
                         name : ORWaveformBaselineValueChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(useUnsignedValuesChanged:)
                         name : ORWaveformUseUnsignedChanged
                        object: model];

}

- (void) updateWindow
{
	[super updateWindow];
	[self differentiateChanged:nil];
	[self averageWindowChanged:nil];
	[self integrateChanged:nil];
	[self baselineValueChanged:nil];
	[self useUnsignedValuesChanged:nil];
}

- (void) differentiateChanged:(NSNotification*)aNote
{
	[differentiateButton setState:[[self plotter] differentiate]];
	if([[self plotter] differentiate]){
		[differentiateText setStringValue:@"differentiated"];
	}
	else {
		[differentiateText setStringValue:@""];
	}
	//[[self plotter] autoScale:nil];
}

- (void) averageWindowChanged:(NSNotification*)aNote
{
	[averageWindowField setIntValue:[[self plotter] averageWindow]];
	//[[self plotter] autoScale:nil];
}

- (void) integrateChanged:(NSNotification*)aNote
{
	[integrateButton setState:[model integrate]];
	
	if([model integrate])[integratingText setStringValue:@"integrating"];
	else				 [integratingText setStringValue:@""];
	
	if([model integrate]){
		[[[self plotter] xScale] setRngLow:0 withHigh:65535];
	}
	else {
		[[[self plotter] xScale] setRngLow:0 withHigh:[model numberBins]];
	}
	//[[self plotter] autoScale:nil];
}

- (void) baselineValueChanged:(NSNotification*)aNote
{
	[baselineValueField setIntValue:[model baselineValue]];
}

- (void) useUnsignedValuesChanged:(NSNotification*)aNote;
{
	[useUnsignedValuesButton setState:[model useUnsignedValues]];
}

#pragma mark ¥¥¥Actions
- (IBAction) useUnsignedValuesAction:(id)sender
{
	[model setUseUnsignedValues:[sender state]];
	[[self plotter] setNeedsDisplay:YES];
	[[self plotter] autoScale:nil];
	[[self plotter] resetScales:nil];
}


- (IBAction) differentiateAction:(id)sender
{
	[[self plotter] setDifferentiate:[sender state]];
}

- (IBAction) averageWindowAction:(id)sender
{
	[[self plotter] setAverageWindow:[sender intValue]];
}

- (IBAction) integrateAction:(id)sender
{
	[self endEditing];
	[model setIntegrate:[sender intValue]];
}

- (IBAction) baselineValueAction:(id)sender
{
	[model setBaselineValue:[sender intValue]];	
}

#pragma mark ¥¥¥Actions
- (IBAction) copy:(id)sender
{
	[plotter copy:sender];
}

#pragma mark ¥¥¥Data Source
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [model numberBins];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if([[tableColumn identifier] isEqualToString:@"Value"]){
		return [NSNumber numberWithInt:[model value:row]];
	}
	else return [NSNumber numberWithInt:row];
}


- (BOOL) useUnsignedValues
{
	return [model useUnsignedValues];
}
- (BOOL) useDataObject:(id)aPlotter  dataSet:(int)set
{
	if([model integrate])return NO;
	else return [model useDataObject:aPlotter dataSet:set];
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	if([model integrate])return 65536;
	else return [model numberBins];
}

- (float) plotter:(id) aPlotter  dataSet:(int)set dataValue:(int) x
{
	if([model integrate]){
		return [model integratedValue:x];
	}
    else {
		return [model value:x];
	}
}

@end
