//
//  nTPCController.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 15 2007.
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
#import "nTPCController.h"
#import "nTPCModel.h"
#import "nTPCConstants.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORDetectorSegment.h"
#import "ORSegmentGroup.h"
#import "ORDetectorView.h"
#import "OR1DHistoPlot.h"
#import "ORPlotView.h"

#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
@interface nTPCController (private)
- (void) readSecondaryMapFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveSecondaryMapFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) readTertiaryMapFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveTertiaryMapFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end
#endif

@implementation nTPCController
#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"nTPC"];
    return self;
}

- (void) loadSegmentGroups
{
	//primary group 
	if(!segmentGroups)segmentGroups = [[NSMutableArray array] retain];
	ORSegmentGroup* aGroup = [model segmentGroup:0];
	if(![segmentGroups containsObject:aGroup]){
		[segmentGroups addObject:aGroup];
	}
	//secondary group 
	aGroup = [model segmentGroup:1];
	if(![segmentGroups containsObject:aGroup]){
		[segmentGroups addObject:aGroup];
		secondaryGroup = aGroup;
	}
	//tertiary group 
	aGroup = [model segmentGroup:2];
	if(![segmentGroups containsObject:aGroup]){
		[segmentGroups addObject:aGroup];
		tertiaryGroup = aGroup;
	}
}

- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/PadPlane0WireMap";
}
- (NSString*) defaultSecondaryMapFilePath
{
	return @"~/PadPlane1WireMap";
}
- (NSString*) defaultTertiaryMapFilePath
{
	return @"~/PadPlane2WireMap";
}


-(void) awakeFromNib
{
	OR1DHistoPlot* aPlot1 = [[OR1DHistoPlot alloc] initWithTag:12 andDataSource:self];
	[valueHistogramsPlot addPlot: aPlot1];
	[aPlot1 release];
	
	[self populateClassNamePopup:secondaryAdcClassNamePopup];
	[self populateClassNamePopup:tertiaryAdcClassNamePopup];
    [super awakeFromNib];
	[xAxis setOppositePosition:YES];
	[colorAxis setOppositePosition:YES];
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    

    [notifyCenter addObserver : self
                     selector : @selector(secondaryAdcClassNameChanged:)
                         name : ORSegmentGroupAdcClassNameChanged
						object: secondaryGroup];


    [notifyCenter addObserver : self
                     selector : @selector(secondaryMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
						object: secondaryGroup];

    [notifyCenter addObserver : self
                     selector : @selector(tertiaryAdcClassNameChanged:)
                         name : ORSegmentGroupAdcClassNameChanged
						object: tertiaryGroup];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(tertiaryMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
						object: tertiaryGroup];
	
    [notifyCenter addObserver : self
                     selector : @selector(planeMaskChanged:)
                         name : nTPCModelPlaneMaskChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];
	
	//hw map
	[self secondaryMapFileChanged:nil];
	[self secondaryAdcClassNameChanged:nil];

	[self tertiaryMapFileChanged:nil];
	[self tertiaryAdcClassNameChanged:nil];

	//details
	[secondaryValuesView reloadData];
	[tertiaryValuesView reloadData];
	[self planeMaskChanged:nil];
}

#pragma mark ¥¥¥HW Map Actions

- (IBAction) planeMaskAction:(id)sender
{

	unsigned short aMask = [model planeMask];
	int i = [[sender selectedCell] tag];
	int value = [sender intValue];
	if(value)aMask |= (1<<i);
	else aMask &= ~(1<<i);
	[model setPlaneMask:aMask];	
}

- (IBAction) clrSelectionAction:(id)sender
{
	[detectorView clrSelection];
}

- (IBAction) viewDialogAction:(id)sender
{
	[detectorView showSelectedDialog];
}


- (IBAction) secondaryAdcClassNameAction:(id)sender
{
	[secondaryGroup setAdcClassName:[sender titleOfSelectedItem]];	
}

- (IBAction) readSecondaryMapFileAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[secondaryGroup mapFile] stringByExpandingTildeInPath];
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
            [secondaryGroup setMapFile:[[[[openPanel URLs] objectAtIndex:0]path] stringByAbbreviatingWithTildeInPath]];
            [secondaryGroup readMap];
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
    
	NSString* fullPath = [[secondaryGroup mapFile] stringByExpandingTildeInPath];
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
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [secondaryGroup saveMapFileAs:[[savePanel URL]path]];
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

- (IBAction) tertiaryAdcClassNameAction:(id)sender
{
	[tertiaryGroup setAdcClassName:[sender titleOfSelectedItem]];	
}

- (IBAction) readTertiaryMapFileAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[tertiaryGroup mapFile] stringByExpandingTildeInPath];
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
            [tertiaryGroup setMapFile:[[[[openPanel URLs] objectAtIndex:0]path] stringByAbbreviatingWithTildeInPath]];
            [tertiaryGroup readMap];
            [tertiaryTableView reloadData];
        }
    }];
#else 	 
    [openPanel beginSheetForDirectory:startingDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(readTertiaryMapFilePanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
#endif
}

- (IBAction) saveTertiaryMapFileAction:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[tertiaryGroup mapFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = [self defaultTertiaryMapFilePath];
        
    }
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [tertiaryGroup saveMapFileAs:[[savePanel URL]path]];
        }
    }];
#else 	
    [savePanel beginSheetForDirectory:startingDir
                                 file:defaultFile
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(saveTertiaryMapFilePanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
#endif
}


#pragma mark ¥¥¥Interface Management

- (void) planeMaskChanged:(NSNotification*)aNote
{
	short i;
	unsigned char theMask = [model planeMask];
	for(i=0;i<3;i++){
		BOOL bitSet = (theMask&(1<<i))>0;
		if(bitSet != [[planeMaskMatrix cellWithTag:i] intValue]){
			[[planeMaskMatrix cellWithTag:i] setState:bitSet];
		}
	}
}

- (void) specialUpdate:(NSNotification*)aNote
{
	[super specialUpdate:aNote];
	[secondaryValuesView reloadData];
	[tertiaryValuesView reloadData];
}

- (void) setDetectorTitle
{	
	switch([model displayType]){
		case kDisplayEvents:		[detectorTitle setStringValue:@"Displaying Events"];			break;
		case kDisplayRates:			[detectorTitle setStringValue:@"Displaying Detector Rate"];		break;
		case kDisplayThresholds:	[detectorTitle setStringValue:@"Displaying Thresholds"];		break;
		case kDisplayGains:			[detectorTitle setStringValue:@"Displaying Gains"];				break;
		default: break;
	}
}

- (void) newTotalRateAvailable:(NSNotification*)aNotification
{
	[super newTotalRateAvailable:aNotification];
	[secondaryRateField setFloatValue:[secondaryGroup rate]];
	[tertiaryRateField setFloatValue:[tertiaryGroup rate]];
}

#pragma mark ¥¥¥HW Map Interface Management
- (void) selectionChanged:(NSNotification*)aNote
{
	[clrSelectionButton setEnabled:[model somethingSelected]];

	if([[[model segmentGroup:[detectorView selectedSet]] segment:[detectorView selectedPath]] hardwarePresent]){
		[showDialogButton setEnabled:[model somethingSelected]];
	}
	else [showDialogButton setEnabled:NO];
}

- (void) secondaryAdcClassNameChanged:(NSNotification*)aNote
{
	[secondaryAdcClassNamePopup selectItemWithTitle: [secondaryGroup adcClassName]];
}

- (void) secondaryMapFileChanged:(NSNotification*)aNote
{
	NSString* s = [secondaryGroup mapFile];
	if(!s) s = @"--";
	[secondaryMapFileTextField setStringValue: s];
}

- (void) tertiaryAdcClassNameChanged:(NSNotification*)aNote
{
	[tertiaryAdcClassNamePopup selectItemWithTitle: [tertiaryGroup adcClassName]];
}

- (void) tertiaryMapFileChanged:(NSNotification*)aNote
{
	NSString* s = [tertiaryGroup mapFile];
	if(!s) s = @"--";
	[tertiaryMapFileTextField setStringValue: s];
}


- (void) mapFileRead:(NSNotification*)aNote
{
	[super mapFileRead:aNote];
    if(aNote == nil || [aNote object] == model){
        [secondaryTableView reloadData];
        [secondaryValuesView reloadData];
        [tertiaryTableView reloadData];
        [tertiaryValuesView reloadData];
    }
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
		[tertiaryTableView deselectAll:self];
	}
    [readSecondaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
    [saveSecondaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
	[secondaryAdcClassNamePopup setEnabled:!lockedOrRunningMaintenance]; 
    [readTertiaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
    [saveTertiaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
	[tertiaryAdcClassNamePopup setEnabled:!lockedOrRunningMaintenance]; 
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
		[tertiaryValuesView deselectAll:self];
	}

}

#pragma mark ¥¥¥Table Data Source
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
	if(tableView == secondaryTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == secondaryValuesView){
		return ![gSecurity isLocked:[model experimentDetailsLock]];
	}
	else if(tableView == tertiaryTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == tertiaryValuesView){
		return ![gSecurity isLocked:[model experimentDetailsLock]];
	}
	else return [super tableView:tableView shouldSelectRow:row];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if(aTableView == secondaryTableView || aTableView == secondaryValuesView){
		return [secondaryGroup segment:rowIndex objectForKey:[aTableColumn identifier]];
	}
	else if(aTableView == tertiaryTableView || aTableView == tertiaryValuesView){
		return [tertiaryGroup segment:rowIndex objectForKey:[aTableColumn identifier]];
	}
	else return [[segmentGroups objectAtIndex:0] segment:rowIndex objectForKey:[aTableColumn identifier]];
}

// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if( aTableView == secondaryTableView || 
		aTableView == secondaryValuesView)	return [secondaryGroup numSegments];
	else if( aTableView == tertiaryTableView || 
	   aTableView == tertiaryValuesView)	return [tertiaryGroup numSegments];
	else								return [super numberOfRowsInTableView:aTableView];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	ORDetectorSegment* aSegment;
	if(aTableView == secondaryTableView){
		aSegment = [secondaryGroup segment:rowIndex];
		[aSegment setObject:anObject forKey:[aTableColumn identifier]];
		[secondaryGroup configurationChanged:nil];
	}
	else if(aTableView == secondaryValuesView){
		aSegment = [secondaryGroup segment:rowIndex];
		if([[aTableColumn identifier] isEqualToString:@"threshold"]){
			[aSegment setThreshold:anObject];
		}
		else if([[aTableColumn identifier] isEqualToString:@"gain"]){
			[aSegment setGain:anObject];
		}
	}
	else if(aTableView == tertiaryTableView){
		aSegment = [tertiaryGroup segment:rowIndex];
		[aSegment setObject:anObject forKey:[aTableColumn identifier]];
		[tertiaryGroup configurationChanged:nil];
	}
	else if(aTableView == tertiaryValuesView){
		aSegment = [tertiaryGroup segment:rowIndex];
		if([[aTableColumn identifier] isEqualToString:@"threshold"]){
			[aSegment setThreshold:anObject];
		}
		else if([[aTableColumn identifier] isEqualToString:@"gain"]){
			[aSegment setGain:anObject];
		}
	}
	else [super tableView:aTableView setObjectValue:anObject forTableColumn:aTableColumn row:rowIndex];
}

- (void) tableView:(NSTableView*)tv didClickTableColumn:(NSTableColumn *)tableColumn
{
//    NSImage *sortOrderImage = [tv indicatorImageInTableColumn:tableColumn];
//    NSString *columnKey = [tableColumn identifier];
    // If the user clicked the column which already has the sort indicator
    // then just flip the sort order.
    
//    if (sortOrderImage || columnKey == [[Prespectrometer sharedInstance] sortColumn]) {
//        [[Prespectrometer sharedInstance] setSortIsDescending:![[Prespectrometer sharedInstance] sortIsDescending]];
//    }
//    else {
///        [[Prespectrometer sharedInstance] setSortColumn:columnKey];
//    }
  //  [self updateTableHeaderToMatchCurrentSort];
    // now do it - doc calls us back when done
//    [[Prespectrometer sharedInstance] sort];
//    [tv reloadData];
}

//- (void) updateTableHeaderToMatchCurrentSort
//{
//    BOOL isDescending = [[Prespectrometer sharedInstance] sortIsDescending];
//    NSString *key = [[Prespectrometer sharedInstance] sortColumn];
//    NSArray *a = [focalPlaneTableView tableColumns];
//    NSTableColumn *column = [focalPlaneTableView tableColumnWithIdentifier:key];
//    unsigned i = [a count];
    
//    while (i-- > 0) [focalPlaneTableView setIndicatorImage:nil inTableColumn:[a objectAtIndex:i]];
    
//    if (key) {
//        [focalPlaneTableView setIndicatorImage:(isDescending ? ascendingSortingImage:descendingSortingImage) inTableColumn:column];
        
//        [focalPlaneTableView setHighlightedTableColumn:column];
//    }
//    else {
//        [focalPlaneTableView setHighlightedTableColumn:nil];
//    }
//}


- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    int index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.nTPCController.selectedtab"];
}

@end

#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
@implementation nTPCController (Private)
- (void)readSecondaryMapFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [secondaryGroup setMapFile:[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath]];
		[secondaryGroup readMap];
		[secondaryTableView reloadData];

    }
}
- (void)saveSecondaryMapFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [secondaryGroup saveMapFileAs:[sheet filename]];
    }
}
- (void)readTertiaryMapFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [tertiaryGroup setMapFile:[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath]];
		[tertiaryGroup readMap];
		[tertiaryTableView reloadData];
    }
}

- (void)saveTertiaryMapFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [tertiaryGroup saveMapFileAs:[sheet filename]];
    }
}
@end
#endif