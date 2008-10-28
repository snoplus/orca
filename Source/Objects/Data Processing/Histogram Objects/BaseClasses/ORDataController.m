//
//  ORDataController.m
//  Orca
//
//  Created by Mark Howe on Tue Dec 09 2003.
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


#import "ORDataController.h"
#import "ORDataSetModel.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORHistoModel.h"
#import "ORCARootServiceDefs.h"

@implementation ORDataController

- (id) init
{
	self = [super init];
	if(kORCARootFitNames[0] != nil){} //just to get rid of stupid compiler warning
	if(kORCARootFFTNames[0] != nil){} //just to get rid of stupid compiler warning
	if(kORCARootFitShortNames[0] != nil){} //just to get rid of stupid compiler warning
	if(kORCARootFFTWindowNames[0] != nil){} //just to get rid of stupid compiler warning
	if(kORCARootFFTWindowOptions[0] != nil){} //just to get rid of stupid compiler warning

	return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void) awakeFromNib
{
    NSSize minSize = [[self window] minSize];
    minSize.height = 300;
    [[self window] setMinSize:minSize];
    
    [super awakeFromNib];
}
- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)flagsChanged:(NSEvent*)inEvent
{
	[[self window] resetCursorRects];
}
// this is needed too because the modifiers can change 
// when it's not main without it being told
- (void)windowDidBecomeMain:(NSNotification*)inNot
{
	[[self window] resetCursorRects];
}	

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(dataSetChanged:)
                         name : ORModelChangedNotification
                       object : self];
    
    [notifyCenter addObserver : self
                     selector : @selector(dataSetRemoved:)
                         name : ORDataSetModelRemoved
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(dataSetChanged:)
                         name : ORDataSetDataChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(drawerDidOpen:)
                         name : NSDrawerDidOpenNotification
                       object : analysisDrawer];
	
	[notifyCenter addObserver : self
                     selector : @selector(drawerDidClose:)
                         name : NSDrawerDidCloseNotification
                       object : analysisDrawer];
	
	[notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(serviceResponse:)
						 name : ORCARootServiceReponseNotification
					   object : plotter];

}

- (void) updateWindow
{
	[super updateWindow];
    [self dataSetChanged:nil];
    [self miscAttributesChanged:nil];
}

- (void) serviceResponse:(NSNotification*)aNotification
{
	NSMutableDictionary* reponseInfo = [[aNotification userInfo] objectForKey:ORCARootServiceResponseKey];
	[reponseInfo setObject:[[self window] title] forKey:ORCARootServiceTitleKey];
	[model processResponse:reponseInfo];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter xScale]){
		[model setMiscAttributes:[[plotter xScale]attributes] forKey:@"XAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter yScale]){
		[model setMiscAttributes:[[plotter yScale]attributes] forKey:@"YAttributes"];
	};
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes"];
		if(attrib){
			[[plotter xScale] setAttributes:attrib];
			[plotter setNeedsDisplay:YES];
			[[plotter xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes"];
		if(attrib){
			[[plotter yScale] setAttributes:attrib];
			[plotter setNeedsDisplay:YES];
			[[plotter yScale] setNeedsDisplay:YES];
		}
	}
}

- (void) dataSetChanged:(NSNotification*)aNotification
{
    if(!aNotification || [aNotification object] == model || [aNotification object] == self){
        [plotter setNeedsDisplay:YES];
        [[plotter xScale] setNeedsDisplay:YES];
		[rawDataTable reloadData];
    }
}

- (void) dataSetRemoved:(NSNotification*)aNote
{
    if([aNote object] == model){
        [[self window] close];
    }
}

- (void)drawerDidOpen:(NSNotification *)aNotification
{
    if([aNotification object] == analysisDrawer){
        [plotter setShowActiveGate:YES];    
    }
}

- (void)drawerDidClose:(NSNotification *)aNotification
{
    if([aNotification object] == analysisDrawer){
        [plotter setShowActiveGate:NO];
    }
}


- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    if([aModel fullName]){
        [[self window] setTitle:[aModel fullName]];
        [titleField setStringValue:[aModel fullNameWithRunNumber]];
    }
}

#pragma mark •••Accessors
- (id) plotter
{
	return plotter;
}
- (BOOL) useDataObject:(id)aPlotter  dataSet:(int)set
{
	return [model useDataObject:aPlotter dataSet:set];
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
    return [model numberBins];
}

- (BOOL) differentiate
{
	return [model differentiate];
}

- (float) plotter:(id) aPlotter  dataSet:(int)set dataValue:(int) x
{
    return [model value:x];
}

- (unsigned long) startingByteOffset:(id)aPlotter  dataSet:(int)set
{
	return [model startingByteOffset:aPlotter dataSet:set];
}

- (unsigned short) unitSize:(id)aPlotter  dataSet:(int)set
{
	return [model unitSize:aPlotter dataSet:set];
}

- (NSData*) plotter:(id) aPlotter dataSet:(int)set
{
	return [model plotter:aPlotter dataSet:set];
}

- (IBAction)logLin:(NSToolbarItem*)item 
{
	[[plotter yScale] setLog:![[plotter yScale] isLog]];
}

- (IBAction)autoScale:(NSToolbarItem*)item 
{
	[plotter autoScale:nil];
}


- (IBAction)clearROI:(NSToolbarItem*)item 
{
	[plotter clearActiveGate:self];
}

- (IBAction)clear:(NSToolbarItem*)item 
{
    NSBeginAlertSheet(@"Clear Counts",
                      @"Cancel",
                      @"Yes/Clear It",
                      nil,[self window],
                      self,
                      @selector(_clearSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Really Clear them? You will not be able to undo this.");
}


- (void)_clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
        [model clear];
        [plotter setNeedsDisplay:YES];
		[rawDataTable reloadData];
    }
}

- (IBAction) toggleRaw:(NSToolbarItem*)item
{
	int index = [rawDataTabView indexOfTabViewItem:[rawDataTabView selectedTabViewItem]];
	int maxIndex = [rawDataTabView numberOfTabViewItems];
	index++;
	if(index>=maxIndex)index = 0;
	[rawDataTabView selectTabViewItemAtIndex:index];
}

- (IBAction)doAnalysis:(NSToolbarItem*)item
{
	[analysisDrawer toggle:self];
	[plotter analyze:nil];
	[plotter setNeedsDisplay:YES];
}


- (IBAction) printDocument:(id)sender
{
	NSPrintInfo* printInfo = [NSPrintInfo sharedPrintInfo];
	NSPrintOperation* printOp = [NSPrintOperation printOperationWithView:plotterGroupView printInfo:printInfo];
	[printOp setShowPanels:YES];
	[printOp runOperation];
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
        aFrame.size.height += 85;
        minSize.height = 300;
    }
    else {
        aFrame.size.height -= 85;
        minSize.height = 300-85;
    }
    [[self window] setMinSize:minSize];
    [self resizeWindowToSize:aFrame.size];
    [containingView setAutoresizingMask:oldResizeMask];
    [plotter setIgnoreDoNotDrawFlag:NO];
	
}


@end

@implementation NSObject (ORDataController_Cat)
- (int) numberBins
{
    return 0;
}

- (long) value:(unsigned short)aChan;
{
    return 0;
}
@end

