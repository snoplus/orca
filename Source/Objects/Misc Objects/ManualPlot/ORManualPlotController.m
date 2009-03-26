
//
//  ORManualPlotController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright ¬© 2002 CENPA, University of Washington. All rights reserved.
//

#pragma mark •••Imported Files
#import "ORManualPlotController.h"
#import "ORManualPlotModel.h"
#import "ORPlotter1D.h"

@interface ORManualPlotController (private)
- (void) selectWriteFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

@implementation ORManualPlotController

#pragma mark •••Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"ManualPlot"];
    return self;
}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    
    [notifyCenter addObserver: self
                     selector: @selector(dataChanged:)
                         name: ORManualPlotDataChanged
                       object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(colKeyChanged:)
                         name : ORManualPlotModelColKeyChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(col0TitleChanged:)
                         name : ORManualPlotModelCol0TitleChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(col1TitleChanged:)
                         name : ORManualPlotModelCol1TitleChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(col2TitleChanged:)
                         name : ORManualPlotModelCol2TitleChanged
						object: model];
}

- (void) awakeFromNib
{
	[plotter setUseGradient:YES];
	[super awakeFromNib];
}

- (void) updateWindow
{
	[super updateWindow];
	[self col0TitleChanged:nil];
	[self col1TitleChanged:nil];
	[self col2TitleChanged:nil];
	[self colKeyChanged:nil];
}

#pragma mark •••Interface Management
- (void) colKeyChanged:(NSNotification*)aNote
{
	[col0KeyPU selectItemAtIndex: [model col0Key]];
	[col1KeyPU selectItemAtIndex: [model col1Key]];
	[col2KeyPU selectItemAtIndex: [model col2Key]];
	[self refreshPlot:nil];
}


- (void) col0TitleChanged:(NSNotification*)aNotification
{
	NSString* title = [model col0Title];
	if(!title)title = @"Col 0";
	[[[dataTableView tableColumnWithIdentifier:@"0"] headerCell] setTitle:title];
	[col0LabelField setStringValue:title];
	[dataTableView reloadData];
	[self refreshPlot:nil];
}

- (void) col1TitleChanged:(NSNotification*)aNotification
{
	NSString* title = [model col1Title];
	if(!title)title = @"Col 1";
	[[[dataTableView tableColumnWithIdentifier:@"1"] headerCell] setTitle:title];
	[col1LabelField setStringValue:title];
	[dataTableView reloadData];
	[self refreshPlot:nil];
}

- (void) col2TitleChanged:(NSNotification*)aNotification
{
	NSString* title = [model col2Title];
	if(!title)title = @"Col 2";
	[[[dataTableView tableColumnWithIdentifier:@"2"] headerCell] setTitle:title];
	[col2LabelField setStringValue:title];
		
	[dataTableView reloadData];
	[self refreshPlot:nil];
}

- (void) dataChanged:(NSNotification*)aNotification
{
	[dataTableView reloadData];
	[plotter setNeedsDisplay:YES];
}

#pragma mark •••Actions
- (IBAction) refreshPlot:(id)sender
{
	int col0Key = [model col0Key];
	NSString* title;
	if(col0Key > 2) title = @"Index";
	else title = [[[dataTableView tableColumnWithIdentifier:[NSString stringWithFormat:@"%d",col0Key]] headerCell] title];
	[[plotter xScale] setLabel:title];
	
	title = @"";
	int col1Key = [model col1Key];
	int col2Key = [model col2Key];
	[y1LengendField setStringValue:@""];
	[y2LengendField setStringValue:@""];
	if(col1Key <= 2) {
		NSString* s = [[[dataTableView tableColumnWithIdentifier:[NSString stringWithFormat:@"%d",col1Key]] headerCell] title];
		title = [title stringByAppendingString:s];
		[y1LengendField setStringValue:s];
	}
	if(col2Key <= 2) {
		if([title length])title = [title stringByAppendingString:@" , "];
		NSString* s = [[[dataTableView tableColumnWithIdentifier:[NSString stringWithFormat:@"%d",col2Key]] headerCell] title];
		title = [title stringByAppendingString:s];
		[y2LengendField setStringValue:s];
	}
	if([title length]==0)title = @"Index";
	
	
	[y1LengendField setTextColor:[self colorForDataSet:col1Key==1?0:1]];
	[y2LengendField setTextColor:[self colorForDataSet:col2Key==2?1:0]];

	[[plotter yScale] setLabel:title];
	[plotter setNeedsDisplay:YES];
}

- (IBAction) col2KeyAction:(id)sender
{
	[model setCol2Key:[sender indexOfSelectedItem]];	
}

- (IBAction) col1KeyAction:(id)sender
{
	[model setCol1Key:[sender indexOfSelectedItem]];	
}

- (IBAction) col0KeyAction:(id)sender
{
	[model setCol0Key:[sender indexOfSelectedItem]];	
}

- (IBAction) writeDataFileAction:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    [savePanel beginSheetForDirectory:NSHomeDirectory()
                                 file:@"Untitled"
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(selectWriteFileDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
	
}

#pragma mark •••Data Source
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [model numPoints];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return [model dataAtRow:row column:[[tableColumn identifier] intValue]];
}

- (BOOL) useXYPlot
{
	return YES;
}

- (int) numberOfDataSetsInPlot:(id)aPlotter
{
	return 2;
}

- (int) numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	return [model numPoints];
}
- (BOOL) plotter:(id)aPlotter dataSet:(int)set index:(unsigned long)index x:(float*)xValue y:(float*)yValue
{
	return [model dataSet:set index:index x:xValue y:yValue];
}

- (BOOL)   	willSupplyColors
{
    return YES;
}

- (NSColor*) colorForDataSet:(int)set
{
    switch(set){
        case 0:  return [NSColor redColor];
        case 1:  return [NSColor blueColor];
		default: return [NSColor colorWithCalibratedRed:10/255. green:90/255. blue:0 alpha:1];
    }
}
@end

@implementation ORManualPlotController (private)
- (void) selectWriteFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model writeDataToFile:[[sheet filenames] objectAtIndex:0]];
    }
}

@end

