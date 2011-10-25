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
#import "ORCompositePlotView.h"

#define kPlotPublisherDefaultFile @"orca.plotpublisher.defaultsavesetFile"

#define kPlotPublisherXLabelOption  0
#define kPlotPublisherYLabelOption  1
#define kPlotPublisherUseGridOption 2
#define kPlotPublisherUseTitleOption 3

#define kPlotPublisherXLabel  0
#define kPlotPublisherYLabel  1
#define kPlotPublisherTitle	  2


@interface ORPlotPublisher (private)
#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
- (void) _saveFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) _loadDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) _saveAsDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
#endif
- (void) dumpAndStore;
- (void) _publishingDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
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
	compositePlotView= aPlot;
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
	
	if([[[compositePlotView plotView] plot:0] isKindOfClass:NSClassFromString(@"OR2DHistoPlot")]){
		[dataSetField setEnabled:NO];
		[colorWell setEnabled:NO];
		[[optionMatrix cellWithTag:kPlotPublisherUseGridOption] setEnabled:NO];
	}

	else if([compositePlotView isKindOfClass:NSClassFromString(@"ORCompositeMultiPlotView")]){
		[[labelMatrix cellWithTag:2] setEnabled:NO];
		[[optionMatrix cellWithTag:3] setEnabled:NO];
	}
	
	[dataSetField setIntValue:0];
	[colorWell setColor:[[compositePlotView plot:0] lineColor]];

	[previewImage setImage: [[[NSImage alloc] initWithData: [compositePlotView plotAsPDFData]] autorelease]];
}

- (void) beginSheet
{
	[self retain];
	oldAttributes	= [[[compositePlotView plotView] attributes] mutableCopy];
	oldXLabel		= [[[compositePlotView xAxis] label] copy];
	oldYLabel		= [[[compositePlotView yAxis] label] copy];
	oldTitle		= [[[compositePlotView titleField] stringValue] copy];
	
	[compositePlotView setBackgroundColor:[NSColor whiteColor]];
	[compositePlotView setGridColor:[NSColor whiteColor]];
	
	[compositePlotView setUseGradient:NO];
	
    [NSApp beginSheet:[self window] modalForWindow:[compositePlotView window] modalDelegate:self didEndSelector:@selector(_publishingDidEnd:returnCode:contextInfo:) contextInfo:nil];
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
		NSString* s = [[labelMatrix cellWithTag:kPlotPublisherXLabel] stringValue];
		if([s length]==0)[compositePlotView setXTempLabel:@" "];
		else			 [compositePlotView setXTempLabel:s];
	}
	else [compositePlotView setXTempLabel:nil];
	
	if([[optionMatrix cellWithTag:kPlotPublisherYLabelOption] intValue]) {
		NSString* s = [[labelMatrix cellWithTag:kPlotPublisherYLabel] stringValue];
		if([s length]==0)[compositePlotView setYTempLabel:@" "];
		else			 [compositePlotView setYTempLabel:s];
	}
	else [compositePlotView setYTempLabel:nil];

	if([[optionMatrix cellWithTag:kPlotPublisherUseTitleOption] intValue]) {
		[compositePlotView setPlotTitle:[[labelMatrix cellWithTag:kPlotPublisherTitle] stringValue]];
	}
	else [compositePlotView setPlotTitle:@""];
	
	
	if([[optionMatrix cellWithTag:kPlotPublisherUseGridOption] intValue]) [compositePlotView setGridColor:[NSColor grayColor]];
	else [compositePlotView setGridColor:[NSColor whiteColor]];
	
	[previewImage setImage: [[[NSImage alloc] initWithData: [compositePlotView plotAsPDFData]] autorelease]];

}

- (IBAction) dataSetAction: (id) sender
{
	int i = [dataSetField intValue];
	int maxPlots = [compositePlotView numberOfPlots];
	if(i < 0) i = 0;
	else if(i>maxPlots-1)i = maxPlots-1;
	
	[dataSetField setIntValue:i];
	[colorWell setColor:[[compositePlotView plot:i] lineColor]];
}

- (IBAction) colorOptionsAction: (id) sender
{
	int i = [dataSetField intValue];
	[[compositePlotView plot:i] saveColor];
	[[compositePlotView plot:i] setLineColor:[colorWell color]];
	[compositePlotView setNeedsDisplay:YES];
	[previewImage setImage: [[[NSImage alloc] initWithData: [compositePlotView plotAsPDFData]] autorelease]];
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
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:startingFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [[NSUserDefaults standardUserDefaults] setObject:[[savePanel URL]path] forKey:kPlotPublisherDefaultFile];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [saveSetField setStringValue:[[[savePanel URL]path] stringByAbbreviatingWithTildeInPath]];
            [self storeNewAttributes];
            [newAttributes writeToFile:[[savePanel URL]path] atomically:NO];
        }
    }];
    
#else 	
    [savePanel beginSheetForDirectory:startingDir
								 file:startingFile
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(_saveAsDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
#endif
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

#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [newAttributes release];
            newAttributes = nil;
            newAttributes = [[NSMutableDictionary dictionaryWithContentsOfFile:[[openPanel URL]path]] retain];
            [self loadNewAttributes];
            [saveSetField setStringValue:[[[openPanel URL] path]stringByAbbreviatingWithTildeInPath]];
        }
    }];
#else 	
    [openPanel beginSheetForDirectory:startingDir
								 file:startingFile
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(_loadDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
#endif
}

@end

@implementation ORPlotPublisher (private)
#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
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
#endif

- (void) dumpAndStore
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save"];
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* savePath = [[savePanel URL]path];
            NSData* pdfData = [compositePlotView plotAsPDFData];
            [pdfData writeToFile:[savePath stringByExpandingTildeInPath] atomically:NO];
			[self finish];
       }
    }];
    
#else 	

    [savePanel beginSheetForDirectory:NSHomeDirectory()
								 file:@"Plot.pdf"
					   modalForWindow:[compositePlotView window]
						modalDelegate:self
					   didEndSelector:@selector(_saveFileDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
#endif
}

- (void) _publishingDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	if(returnCode == NSOKButton){
		[self dumpAndStore];
	}
	else [self finish];
	int maxPlots = [compositePlotView numberOfPlots];
	int i;
	for(i=0;i<maxPlots;i++){
		[[compositePlotView plot:i] restoreColor];
	}
}

#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
- (void) _saveFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* savePath = [sheet filename];
		NSData* pdfData = [compositePlotView plotAsPDFData];
		[pdfData writeToFile:[savePath stringByExpandingTildeInPath] atomically:NO];
    }
	[self finish];
}
#endif

- (void) finish
{
	[(ORPlotView*)[compositePlotView plotView] setAttributes: oldAttributes];
	[compositePlotView setXTempLabel:nil];
	[compositePlotView setYTempLabel:nil];
	[compositePlotView setPlotTitle:oldTitle];
	[compositePlotView setNeedsDisplay:YES];
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
	int n = [compositePlotView numberOfPlots];
	int i;
	for(i=0;i<n;i++){
		//id aColor = [NSArchiver archivedDataWithRootObject: [plotter colorForDataSet:i]];
		//[colorArray addObject:aColor];
	}
	[newAttributes setObject:colorArray forKey:@"colors"];
}
@end
