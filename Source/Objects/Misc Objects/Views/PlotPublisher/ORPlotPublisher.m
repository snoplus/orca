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

@interface ORPlotPublisher (private)
- (void) _publishingDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (void) dumpToPDF;
@end

@implementation ORPlotPublisher

+ (void) publishPlot:(id)aPlot 
{
	if([aPlot respondsToSelector:@selector(viewForPDF)]){
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
	[super dealloc];
}

- (void) awakeFromNib
{
}

- (void) loadUI:(ORPlotPublisher*) aCalibration
{
}

- (void) beginSheet
{
	oldAttributes = [[plotter attributes] mutableCopy];
	[plotter setBackgroundColor:[NSColor whiteColor]];
	[plotter setGridColor:[NSColor whiteColor]];
	[plotter setUseGradient:NO];
	
    [NSApp beginSheet:[self window] modalForWindow:[plotter window] modalDelegate:self didEndSelector:@selector(_publishingDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void) publishPlot
{
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}
}

- (IBAction) publish:(id)sender
{	
	[self publishPlot];
	[[self window] orderOut:self];
    [NSApp endSheet:[self window] returnCode:NSOKButton];

}

- (IBAction) cancel:(id)sender
{
    [[self window] orderOut:self];
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
}

@end



@implementation ORPlotPublisher (private)

- (void) _publishingDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	[[plotter viewForPDF] setNeedsDisplay:YES];
	if(returnCode == NSOKButton){
		[self dumpToPDF];
	}
	//arghh... to eliminate some compiler warnings
	[plotter setAttributes:oldAttributes];
	
	[self autorelease];
}

- (void) dumpToPDF
{
	NSData* pdfData = [[plotter viewForPDF] dataWithPDFInsideRect: [[plotter viewForPDF] bounds]];
	[pdfData writeToFile:[@"~/plotPDF.pdf" stringByExpandingTildeInPath] atomically:NO];
}
@end
