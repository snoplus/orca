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
#import "ORPlot.h"
#import "ORPlotView.h"

#define kPlotPublisherDefaultFile @"orca.plotpublisher.defaultsavesetFile"

#define kPlotPublisherXLabelOption  0
#define kPlotPublisherYLabelOption  1
#define kPlotPublisherUseGridOption 2
#define kPlotPublisherUseTitleOption 3

#define kPlotPublisherXLabel  0
#define kPlotPublisherYLabel  1
#define kPlotPublisherTitle	  2


@interface ORPlotPublisher (private)
- (void) dumpAndStore;
- (void) _publishingDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (void) _saveFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) _loadDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) _saveAsDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) storeNewAttributes;
- (void) loadNewAttributes;
- (void) finish;
@end

@implementation ORPlotPublisher

+ (void) publishPlot:(id)aPlot 
{
	if([aPlot respondsToSelector:@selector(plotAsPDFData)]){
		ORPlotPublisher* publisher = [[[ORPlotPublisher alloc] initWithPlot:aPlot] autorelease];
		[publisher beginSheet];
	}
}

- (id) initWithPlot:(id)aPlot 
{
    self = [super initWithWindowNibName:@"PlotPublisher"];
	plotView = aPlot;
	return self;
}

- (void) dealloc
{
	[oldAttributes release];
	[oldXLabel release];
	[oldYLabel release];
	[oldTitle release];
	[newAttributes release];
	
	[super dealloc];
}

- (void) awakeFromNib
{
	NSString* filePath = [[NSUserDefaults standardUserDefaults] objectForKey: kPlotPublisherDefaultFile];
	NSString* startingFile = [filePath stringByAbbreviatingWithTildeInPath];
	
	newAttributes = [[NSMutableDictionary dictionaryWithContentsOfFile:filePath] retain];
	[self loadNewAttributes];
	
	if(!startingFile)startingFile = @"---";
	[saveSetField setStringValue:startingFile];
	
//	if([plotter isKindOfClass:NSClassFromString(@"ORPlotter2D")]){
//		[dataSetField setEnabled:NO];
//		[colorWell setEnabled:NO];
//		[[optionMatrix cellWithTag:kPlotPublisherUseGridOption] setEnabled:NO];
//	}
	[dataSetField setIntValue:0];
	[colorWell setColor:[[plotView plot:0] lineColor]];

	[previewImage setImage: [[[NSImage alloc] initWithData: [plotView plotAsPDFData]] autorelease]];
}

- (void) beginSheet
{
	[self retain];
	oldAttributes	= [[plotView attributes] mutableCopy];
	oldXLabel		= [[[plotView xScale] label] copy];
	oldYLabel		= [[[plotView yScale] label] copy];
	oldTitle		= [[[plotView titleField] stringValue] copy];
	
	[plotView setBackgroundColor:[NSColor whiteColor]];
	[plotView setGridColor:[NSColor whiteColor]];
	
	[plotView setUseGradient:NO];
	
    [NSApp beginSheet:[self window] modalForWindow:[plotView window] modalDelegate:self didEndSelector:@selector(_publishingDidEnd:returnCode:contextInfo:) contextInfo:nil];
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
	if([[optionMatrix cellWithTag:kPlotPublisherXLabelOption] intValue]) {
		[[plotView xScale] setLabel:[[labelMatrix cellWithTag:kPlotPublisherXLabel] stringValue]];
	}
	else [[plotView xScale] setLabel:@""];
	
	if([[optionMatrix cellWithTag:kPlotPublisherYLabelOption] intValue]) {
		[[plotView yScale] setLabel:[[labelMatrix cellWithTag:kPlotPublisherYLabel] stringValue]];
	}
	else [[plotView yScale] setLabel:@""];

	if([[optionMatrix cellWithTag:kPlotPublisherUseTitleOption] intValue]) {
		[[plotView titleField] setStringValue:[[labelMatrix cellWithTag:kPlotPublisherTitle] stringValue]];
	}
	else [[plotView titleField] setStringValue:@""];
	
	
	if([[optionMatrix cellWithTag:kPlotPublisherUseGridOption] intValue]) [plotView setGridColor:[NSColor grayColor]];
	else [plotView setGridColor:[NSColor whiteColor]];
	
	[previewImage setImage: [[[NSImage alloc] initWithData: [plotView plotAsPDFData]] autorelease]];

}

- (IBAction) dataSetAction: (id) sender
{
	int i = [dataSetField intValue];
	int maxPlots = [plotView numberOfPlots];
	if(i < 0) i = 0;
	else if(i>maxPlots-1)i = maxPlots-1;
	
	[dataSetField setIntValue:i];
	[colorWell setColor:[[plotView plot:i] lineColor]];
}

- (IBAction) colorOptionsAction: (id) sender
{
	int i = [dataSetField intValue];
	[[plotView plot:i] saveColor];
	[[plotView plot:i] setLineColor:[colorWell color]];
	[plotView setNeedsDisplay:YES];
	[previewImage setImage: [[[NSImage alloc] initWithData: [plotView plotAsPDFData]] autorelease]];
}

- (IBAction) saveSetAction:(id) sender
{
	NSString* startingPath = [[NSUserDefaults standardUserDefaults] objectForKey: kPlotPublisherDefaultFile];
	NSString* startingDir = [startingPath stringByDeletingLastPathComponent];
	if(!startingDir)startingDir = NSHomeDirectory();
	NSString* startingFile = [startingPath lastPathComponent];
	if(!startingFile)startingFile = @"PublisherSettings";

    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save Settings"];
    [savePanel beginSheetForDirectory:startingDir
								 file:startingFile
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(_saveAsDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
	
}

- (IBAction) loadSetAction:(id) sender
{
	NSString* startingPath = [[NSUserDefaults standardUserDefaults] objectForKey: kPlotPublisherDefaultFile];
	NSString* startingDir = [startingPath stringByDeletingLastPathComponent];
	if(!startingDir)startingDir = NSHomeDirectory();
	NSString* startingFile = [startingPath lastPathComponent];
	if(!startingFile)startingFile = @"PublisherSettings";
	
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setPrompt:@"Choose"];
    [openPanel beginSheetForDirectory:startingDir
								 file:startingFile
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(_loadDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
	
}

@end

@implementation ORPlotPublisher (private)
- (void) _loadDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if(returnCode == NSOKButton){
		[newAttributes release];
		newAttributes = nil;
		newAttributes = [[NSMutableDictionary dictionaryWithContentsOfFile:[sheet filename]] retain];
		[self loadNewAttributes];
		[saveSetField setStringValue:[[sheet filename] stringByAbbreviatingWithTildeInPath]];
	}
}
- (void) _saveAsDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if(returnCode == NSOKButton){
		[[NSUserDefaults standardUserDefaults] setObject:[sheet filename] forKey:kPlotPublisherDefaultFile];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[saveSetField setStringValue:[[sheet filename] stringByAbbreviatingWithTildeInPath]];
		[self storeNewAttributes];
		[newAttributes writeToFile:[sheet filename] atomically:NO];
	}
}

- (void) dumpAndStore
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save"];
    [savePanel beginSheetForDirectory:NSHomeDirectory()
								 file:@"Plot.pdf"
					   modalForWindow:[plotView window]
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
	int maxPlots = [plotView numberOfPlots];
	int i;
	for(i=0;i<maxPlots;i++){
		[[plotView plot:i] restoreColor];
	}
}

- (void) _saveFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* savePath = [sheet filename];
		NSData* pdfData = [plotView plotAsPDFData];
		[pdfData writeToFile:[savePath stringByExpandingTildeInPath] atomically:NO];
    }
	[self finish];
}

- (void) finish
{
	[plotView setAttributes:oldAttributes];
	[[plotView xScale] setLabel:oldXLabel];
	[[plotView yScale] setLabel:oldYLabel];
	[[plotView titleField] setStringValue:oldTitle];
	[plotView setNeedsDisplay:YES];
	if([NSColorPanel sharedColorPanelExists]){
		[[NSColorPanel sharedColorPanel] orderOut:self];
	}
	[self autorelease];
}

- (void) loadNewAttributes
{
	[[optionMatrix cellWithTag:kPlotPublisherUseGridOption] setIntValue:[[newAttributes objectForKey:@"useGradient"] intValue]];
	[[optionMatrix cellWithTag:kPlotPublisherXLabelOption] setIntValue:[[newAttributes objectForKey:@"useXLabel"] intValue]];
	[[optionMatrix cellWithTag:kPlotPublisherYLabelOption] setIntValue:[[newAttributes objectForKey:@"useYLabel"] intValue]];
	[[optionMatrix cellWithTag:kPlotPublisherUseTitleOption] setIntValue:[[newAttributes objectForKey:@"useTitle"] intValue]];
	[dataSetField setIntValue:[[newAttributes objectForKey:@"colorIndex"] intValue]];
	
	NSString* s = [newAttributes objectForKey:@"yLabel"];
	if(!s)s = @"";
	[[labelMatrix cellWithTag:kPlotPublisherYLabel] setStringValue:s];
	
	s = [newAttributes objectForKey:@"xLabel"];
	if(!s)s = @"";
	[[labelMatrix cellWithTag:kPlotPublisherXLabel] setStringValue:s];

	s = [newAttributes objectForKey:@"title"];
	if(!s)s = @"";
	[[labelMatrix cellWithTag:kPlotPublisherTitle] setStringValue:s];
	
	int i = [dataSetField intValue];
	NSArray* colors = [newAttributes objectForKey:@"colors"];
	if(i<[colors count]){
		NSColor* aColor = [NSUnarchiver unarchiveObjectWithData: [colors objectAtIndex:i]];
		[colorWell setColor:aColor];
	}
	else [colorWell setColor:[NSColor blackColor]];
		
	[self labelingOptionsAction:nil];
	[self colorOptionsAction:nil];
}

- (void) storeNewAttributes
{
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}	
	if(!newAttributes)newAttributes = [[NSMutableDictionary dictionary] retain];
	[newAttributes setObject:[NSNumber numberWithBool:[[optionMatrix cellWithTag:kPlotPublisherUseGridOption] intValue]] forKey:@"useGradient"];
	[newAttributes setObject:[NSNumber numberWithBool:[[optionMatrix cellWithTag:kPlotPublisherXLabelOption] intValue]] forKey:@"useXLabel"];
	[newAttributes setObject:[NSNumber numberWithBool:[[optionMatrix cellWithTag:kPlotPublisherYLabelOption] intValue]] forKey:@"useYLabel"];
	[newAttributes setObject:[NSNumber numberWithBool:[[optionMatrix cellWithTag:kPlotPublisherUseTitleOption] intValue]] forKey:@"useTitle"];
	[newAttributes setObject:[[labelMatrix cellWithTag:kPlotPublisherYLabel] stringValue] forKey:@"yLabel"];
	[newAttributes setObject:[[labelMatrix cellWithTag:kPlotPublisherXLabel] stringValue] forKey:@"xLabel"];
	
	[newAttributes setObject:[NSNumber numberWithInt:[dataSetField intValue]] forKey:@"colorIndex"];
	
	NSMutableArray* colorArray = [NSMutableArray array];
	int n = [plotView numberOfPlots];
	int i;
	for(i=0;i<n;i++){
		//id aColor = [NSArchiver archivedDataWithRootObject: [plotter colorForDataSet:i]];
		//[colorArray addObject:aColor];
	}
	[newAttributes setObject:colorArray forKey:@"colors"];
}
@end
