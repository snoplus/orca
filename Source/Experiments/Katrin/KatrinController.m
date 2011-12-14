//
//  KatrinController.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "KatrinController.h"
#import "KatrinModel.h"
#import "KatrinConstants.h"
#import "ORColorScale.h"
#import "ORTimeAxis.h"
#import "ORDetectorSegment.h"
#import "ORSegmentGroup.h"
#import "ORPlotView.h"
#import "ORTimeLinePlot.h"
#import "OR1DHistoPlot.h"

#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
@interface KatrinController (private)
- (void) readSecondaryMapFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveSecondaryMapFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end
#endif

@implementation KatrinController
#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Katrin"];
    return self;
}

- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/FocalPlaneMap";
}
- (NSString*) defaultSecondaryMapFilePath
{
	return @"~/VetoMap";
}


-(void) awakeFromNib
{
	
	detectorSize		= NSMakeSize(800,750);
	slowControlsSize    = NSMakeSize(525,157);
	detailsSize			= NSMakeSize(655,589);
	focalPlaneSize		= NSMakeSize(827,589);
	vetoSize			= NSMakeSize(463,589);
	
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

	[self populateClassNamePopup:secondaryAdcClassNamePopup];
	
    [super awakeFromNib];
	
	if([[model segmentGroup:1] colorAxisAttributes])[[secondaryColorScale colorAxis] setAttributes:[[[[model segmentGroup:1] colorAxisAttributes] mutableCopy] autorelease]];

	[[secondaryColorScale colorAxis] setRngLimitsLow:0 withHigh:128000000 withMinRng:5];
    [[secondaryColorScale colorAxis] setRngDefaultsLow:0 withHigh:128000000];
    [[secondaryColorScale colorAxis] setOppositePosition:YES];
	[[secondaryColorScale colorAxis] setNeedsDisplay:YES];

	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:1 andDataSource:self];
	[aPlot setLineColor:[NSColor blueColor]];
	[ratePlot addPlot: aPlot];
	[aPlot release];
	
	OR1DHistoPlot* aPlot1 = [[OR1DHistoPlot alloc] initWithTag:11 andDataSource:self];
	[valueHistogramsPlot addPlot: aPlot1];
	[aPlot1 release];
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
					   
    [notifyCenter addObserver : self
                     selector : @selector(secondaryColorAxisAttributesChanged:)
                         name : ORAxisRangeChangedNotification
                       object : [secondaryColorScale colorAxis]];
    

    [notifyCenter addObserver : self
                     selector : @selector(secondaryAdcClassNameChanged:)
                         name : ORSegmentGroupAdcClassNameChanged
						object: [model segmentGroup:1]];

    [notifyCenter addObserver : self
                     selector : @selector(secondaryMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
						object: [model segmentGroup:1]];
	
    [notifyCenter addObserver : self
                     selector : @selector(slowControlIsConnectedChanged:)
                         name : KatrinModelSlowControlIsConnectedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(slowControlNameChanged:)
                         name : KatrinModelSlowControlNameChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(viewTypeChanged:)
                         name : ORKatrinModelViewTypeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(snTablesChanged:)
                         name : ORKatrinModelSNTablesChanged
						object: model];
}

- (void) updateWindow
{
    [super updateWindow];

	//detector
    [self secondaryColorAxisAttributesChanged:nil];

	//hw map
	[self secondaryMapFileChanged:nil];
	[self secondaryAdcClassNameChanged:nil];

	//details
	[secondaryValuesView reloadData];
	
	[self slowControlIsConnectedChanged:nil];
	[self slowControlNameChanged:nil];
	[self viewTypeChanged:nil];
	[self snTablesChanged:nil];
}

- (void) primaryMapFileChanged:(NSNotification*)aNote
{
	[super primaryMapFileChanged:aNote];
	NSString* s = [[[model segmentGroup:0] mapFile] stringByAbbreviatingWithTildeInPath];
	if(s) {
		[fltOrbSNField	 setStringValue:[FLTORBSNFILE(s) lastPathComponent]];
		[osbSNField		 setStringValue:[OSBSNFILE(s) lastPathComponent]];
		[preampSNField	 setStringValue:[PREAMPSNFILE(s) lastPathComponent]];
		[sltWaferSNField setStringValue:[SLTWAFERSNFILE(s) lastPathComponent]];
	}
	else {
		[fltOrbSNField setStringValue:@"--"];	
		[osbSNField setStringValue:@"--"];	
		[preampSNField setStringValue:@"--"];	
		[sltWaferSNField setStringValue:@"--"];	
	}
}

- (void) refreshSegmentTables:(NSNotification*)aNote
{
	[super refreshSegmentTables:aNote];
	[secondaryTableView reloadData];
}

- (void) snTablesChanged:(NSNotification*)aNote
{
	[fltSNTableView reloadData];
	[preAmpSNTableView reloadData];
	[osbSNTableView reloadData];
	[otherSNTableView reloadData];
}

- (void) mapFileRead:(NSNotification*)mapFileRead
{
	[super mapFileRead:mapFileRead];
	[self snTablesChanged:nil];
}

- (void) viewTypeChanged:(NSNotification*)aNote
{
	[viewTypePU selectItemAtIndex:[model viewType]];
	[detectorView setViewType:[model viewType]];
	[detectorView makeAllSegments];	
}

#pragma mark ¥¥¥HW Map Actions

- (IBAction) slowControlNameAction:(id)sender
{
	[model setSlowControlName:[sender stringValue]];	
}

- (IBAction) secondaryAdcClassNameAction:(id)sender
{
	[[model segmentGroup:1] setAdcClassName:[sender titleOfSelectedItem]];	
}

- (IBAction) readSecondaryMapFileAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[[model segmentGroup:1] mapFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
    }
    
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [[model segmentGroup:1] readMap:[[openPanel URL] path]];
            [secondaryTableView reloadData];
        }
    }];
#else 	
    [openPanel beginSheetForDirectory:startingDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(readSecondaryMapFilePanelDidEnd:returnCode:contextInfo:)
                         contextInfo:NULL];
#endif
}

- (IBAction) saveSecondaryMapFileAction:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[[model segmentGroup:1] mapFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = [self defaultSecondaryMapFilePath];
        
    }
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [[model segmentGroup:1] saveMapFileAs:[[savePanel URL]path]];
        }
    }];
#else 
    [savePanel beginSheetForDirectory:startingDir
                                 file:defaultFile
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(saveSecondaryMapFilePanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
#endif
}

#pragma mark ¥¥¥Interface Management

- (IBAction) viewTypeAction:(id)sender
{
	[model setViewType:[sender indexOfSelectedItem]];
}

- (void) slowControlNameChanged:(NSNotification*)aNote
{
	[slowControlNameField setStringValue: [model slowControlName]];
}

- (void) slowControlIsConnectedChanged:(NSNotification*)aNote
{
	NSString* s;
	if([model slowControlIsConnected]){
		[slowControlIsConnectedField setTextColor:[NSColor blackColor]];
		[slowControlIsConnectedField1 setTextColor:[NSColor blackColor]];
		s = @"Connected";
	}
	else {
		s = @"NOT Connected";
		[slowControlIsConnectedField setTextColor:[NSColor redColor]];
		[slowControlIsConnectedField1 setTextColor:[NSColor redColor]];
	}	
	[slowControlIsConnectedField setStringValue:s];
	[slowControlIsConnectedField1 setStringValue:s];
}

- (void) specialUpdate:(NSNotification*)aNote
{
	[super specialUpdate:aNote];
	[secondaryTableView reloadData];
	[secondaryValuesView reloadData];
	//if([model viewType] == kUseCrateView){
		[detectorView makeAllSegments];
	//}
}

- (void) setDetectorTitle
{	
	switch([model displayType]){
		case kDisplayRates:			[detectorTitle setStringValue:@"Detector Rate"];	break;
		case kDisplayThresholds:	[detectorTitle setStringValue:@"Thresholds"];		break;
		case kDisplayGains:			[detectorTitle setStringValue:@"Gains"];			break;
		case kDisplayTotalCounts:	[detectorTitle setStringValue:@"Total Counts"];		break;
		default: break;
	}
}

- (void) newTotalRateAvailable:(NSNotification*)aNotification
{
	[super newTotalRateAvailable:aNotification];
	[secondaryRateField setFloatValue:[[model segmentGroup:1] rate]];
}

- (void) secondaryColorAxisAttributesChanged:(NSNotification*)aNotification
{
	BOOL isLog = [[secondaryColorScale colorAxis] isLog];
	[secondaryColorAxisLogCB setState:isLog];
	[[model segmentGroup:1] setColorAxisAttributes:[[secondaryColorScale colorAxis] attributes]];
}

#pragma mark ¥¥¥HW Map Interface Management
- (void) secondaryAdcClassNameChanged:(NSNotification*)aNote
{
	[secondaryAdcClassNamePopup selectItemWithTitle: [[model segmentGroup:1] adcClassName]];
}

- (void) secondaryMapFileChanged:(NSNotification*)aNote
{
	NSString* s = [[[model segmentGroup:1] mapFile]stringByAbbreviatingWithTildeInPath];
	if(!s) s = @"--";
	[secondaryMapFileTextField setStringValue: s];
}

- (void) mapLockChanged:(NSNotification*)aNotification
{
	[super mapLockChanged:aNotification];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetectorLock]];
    //BOOL runningOrLocked = [gSecurity runInProgressOrIsLocked:ORPrespectrometerLock];
    BOOL locked = [gSecurity isLocked:[model experimentMapLock]];
    [mapLockButton setState: locked];
    
    if(locked){
		[secondaryTableView deselectAll:self];
	}
    [readSecondaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
    [saveSecondaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
	[secondaryAdcClassNamePopup setEnabled:!lockedOrRunningMaintenance]; 
}

#pragma mark ¥¥¥Details Interface Management
- (void) detailsLockChanged:(NSNotification*)aNotification
{
	[super detailsLockChanged:aNotification];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetailsLock]];
    BOOL locked = [gSecurity isLocked:[model experimentDetailsLock]];

	[detailsLockButton setState: locked];
    [initButton setEnabled: !lockedOrRunningMaintenance];

	if(locked){
		[secondaryValuesView deselectAll:self];
	}
}

#pragma mark ¥¥¥Table Data Source
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
	if(tableView == secondaryTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == fltSNTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == preAmpSNTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == osbSNTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == otherSNTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == secondaryValuesView){
		return ![gSecurity isLocked:[model experimentDetailsLock]];
	}
	else return [super tableView:tableView shouldSelectRow:row];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if(aTableView == secondaryTableView || aTableView == secondaryValuesView){
		return [[model segmentGroup:1] segment:rowIndex objectForKey:[aTableColumn identifier]];
	}
	else if(aTableView == fltSNTableView){
		return [model fltSN:rowIndex objectForKey:[aTableColumn identifier]];
	}
	else if(aTableView == preAmpSNTableView){
		return [model preAmpSN:rowIndex objectForKey:[aTableColumn identifier]];
	}
	else if(aTableView == osbSNTableView){
		return [model osbSN:rowIndex objectForKey:[aTableColumn identifier]];
	}
	else if(aTableView == otherSNTableView){
		return [model otherSNForKey:[aTableColumn identifier]];
	}
	else return  [super tableView:aTableView objectValueForTableColumn:aTableColumn row:rowIndex];
}

// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if( aTableView == secondaryTableView || 
		aTableView == secondaryValuesView)    return [[model segmentGroup:1] numSegments];
	else if(aTableView == fltSNTableView)     return 8; 
	else if(aTableView == preAmpSNTableView)  return 24; 
	else if(aTableView == osbSNTableView)     return 4; 
	else if(aTableView == otherSNTableView)   return 1; 
	else								      return [super numberOfRowsInTableView:aTableView];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	ORDetectorSegment* aSegment;
	if(aTableView == secondaryTableView){
		aSegment = [[model segmentGroup:1] segment:rowIndex];
		[aSegment setObject:anObject forKey:[aTableColumn identifier]];
		[[model segmentGroup:1] configurationChanged:nil];
	}
	else if(aTableView == secondaryValuesView){
		aSegment = [[model segmentGroup:1] segment:rowIndex];
		if([[aTableColumn identifier] isEqualToString:@"threshold"]){
			[aSegment setThreshold:anObject];
		}
		else if([[aTableColumn identifier] isEqualToString:@"gain"]){
			[aSegment setGain:anObject];
		}
	}
	
	else if(aTableView == fltSNTableView){
		[model fltSN:rowIndex setObject:anObject forKey:[aTableColumn identifier]];
	}
	else if(aTableView == preAmpSNTableView){
		[model preAmpSN:rowIndex setObject:anObject forKey:[aTableColumn identifier]];
	}
	else if(aTableView == osbSNTableView){
		[model osbSN:rowIndex setObject:anObject forKey:[aTableColumn identifier]];
	}
	else if(aTableView == otherSNTableView){
		[model setOtherSNObject:anObject forKey:[aTableColumn identifier]];
	}
	else [super tableView:aTableView setObjectValue:anObject forTableColumn:aTableColumn row:rowIndex];
}


- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	float toolBarOffset = 0;
	BOOL toolBarVisible = [[[self window] toolbar] isVisible];
	if(toolBarVisible){
		switch([[[self window] toolbar] sizeMode]){
			case NSToolbarSizeModeRegular:	toolBarOffset = 60; break;
			case NSToolbarSizeModeSmall:	toolBarOffset = 50; break;
			default:						toolBarOffset = 60; break;
		}
	}
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		NSSize newSize = detectorSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		NSSize newSize = slowControlsSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		NSSize newSize = detailsSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		NSSize newSize = focalPlaneSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
	else if([tabView indexOfTabViewItem:tabViewItem] == 4){
		[[self window] setContentView:blankView];
		NSSize newSize = vetoSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
	int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.KatrinController.selectedtab"];
}

@end

#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
@implementation KatrinController (Private)
- (void) readSecondaryMapFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
		[[model segmentGroup:1] readMap:[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath]];
		[secondaryTableView reloadData];
    }
}

- (void) saveSecondaryMapFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [[model segmentGroup:1] saveMapFileAs:[sheet filename]];
    }
}
@end
#endif