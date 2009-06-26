//  ORPlotPublisher.m
//  Orca
//
//  Created by Mark Howe on June 25, 2009.
//  Copyright 2009 UNC. All rights reserved.
//
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

#import "ORPlotPublisher.h"
#import "ORPlotter.h"
#import "ORPlotter1D.h"

@interface ORPlotPublisher (private)
- (void) dumpAndStore;
- (void) _publishingDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (void) _saveFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) finish;
@end

@implementation ORPlotPublisher

+ (void) publishPlot:(id)aPlot 
{
	if([aPlot respondsToSelector:@selector(plotAsPDFData)]){
		ORPlotPublisher* publisher = [[ORPlotPublisher alloc] initWithPlot:aPlot];
		[publisher beginSheet];
	}
}

- (id) initWithPlot:(id)aPlot 
{
    self = [super initWithWindowNibName:@"PlotPublisher"];
	plotter = aPlot;
	return self;
}

- (void) dealloc
{
	[oldAttributes release];
	[oldXLabel release];
	[oldYLabel release];
	
	[super dealloc];
}

- (void) awakeFromNib
{
	[dataSetField setIntValue:0];
	[color1 setColor:[plotter colorForDataSet:0]];
	[previewImage setImage: [[[NSImage alloc] initWithData: [plotter plotAsPDFData]] autorelease]];
}

- (void) beginSheet
{
	oldAttributes = [[plotter attributes] mutableCopy];
	oldXLabel = [[[plotter xScale] label] copy];
	oldYLabel = [[[plotter yScale] label] copy];
	
	[plotter setBackgroundColor:[NSColor whiteColor]];
	[plotter setGridColor:[NSColor whiteColor]];
	[plotter setUseGradient:NO];
	
    [NSApp beginSheet:[self window] modalForWindow:[plotter window] modalDelegate:self didEndSelector:@selector(_publishingDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction) publish:(id)sender
{	
	[[self window] orderOut:self];
    [NSApp endSheet:[self window] returnCode:NSOKButton];

}

- (IBAction) cancel:(id)sender
{
    [[self window] orderOut:self];
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
}

- (IBAction) labelingOptionsAction: (id) sender
{
	if([[optionMatrix cellWithTag:0] intValue]) {
		[[plotter xScale] setLabel:[[labelMatrix cellWithTag:0] stringValue]];
	}
	else [[plotter xScale] setLabel:@""];
	
	if([[optionMatrix cellWithTag:1] intValue]) {
		[[plotter yScale] setLabel:[[labelMatrix cellWithTag:1] stringValue]];
	}
	else [[plotter yScale] setLabel:@""];
	
	if([[optionMatrix cellWithTag:2] intValue]) [plotter setGridColor:[NSColor grayColor]];
	else [plotter setGridColor:[NSColor whiteColor]];
	
	[previewImage setImage: [[[NSImage alloc] initWithData: [plotter plotAsPDFData]] autorelease]];

}

- (IBAction) dataSetAction: (id) sender
{
	int dataSet = [dataSetField intValue];
	
	if(dataSet < 0) dataSet = 0;
	else if(dataSet>6)dataSet = 6;
	
	[dataSetField setIntValue:dataSet];
	[color1 setColor:[plotter colorForDataSet:dataSet]];
}

- (IBAction) colorOptionsAction: (id) sender
{
	int dataSet = [dataSetField intValue];
	[plotter setDataColor:[color1 color] dataSet:dataSet];

	//this notification is a work around to force the legend to be redrawn with the right colors
	[[NSNotificationCenter defaultCenter] postNotificationName: ORPlotter1DActiveCurveChanged object:plotter];
	[previewImage setImage: [[[NSImage alloc] initWithData: [plotter plotAsPDFData]] autorelease]];
}

@end

@implementation ORPlotPublisher (private)
- (void) dumpAndStore
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save"];
    [savePanel beginSheetForDirectory:NSHomeDirectory()
								 file:@"Plot.pdf"
					   modalForWindow:[plotter window]
						modalDelegate:self
					   didEndSelector:@selector(_saveFileDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}

- (void) _publishingDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	if(returnCode == NSOKButton){
		[self dumpAndStore];
	}
	else [self finish];
}

- (void) _saveFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* savePath = [[sheet filenames] objectAtIndex:0];
		NSData* pdfData = [plotter plotAsPDFData];
		[pdfData writeToFile:[savePath stringByExpandingTildeInPath] atomically:NO];
    }
	[self finish];
}

- (void) finish
{
	[plotter setAttributes:oldAttributes];
	[[plotter xScale] setLabel:oldXLabel];
	[[plotter yScale] setLabel:oldYLabel];
	[plotter setNeedsDisplay:YES];
	//this notification is a work around to force the legend to be redrawn with the right colors
	[[NSNotificationCenter defaultCenter] postNotificationName: ORPlotter1DActiveCurveChanged object:plotter];
	[self autorelease];
}
@end
