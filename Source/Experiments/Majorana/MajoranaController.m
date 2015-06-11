//
//  MajoranaController.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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
#import "MajoranaController.h"
#import "MajoranaModel.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORDetectorSegment.h"
#import "ORSegmentGroup.h"
#import "ORTimeLinePlot.h"
#import "ORTimeAxis.h"
#import "OR1DHistoPlot.h"
#import "ORPlotView.h"
#import "ORCompositePlotView.h"
#import "ORiSegHVCard.h"
#import "ORMJDInterlocks.h"

@implementation MajoranaController
#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Majorana"];
    return self;
}
- (void) dealloc
{
    [blankView release];
    [super dealloc];
}

- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/MJDDetectorMap";
}

- (NSString*) defaultSecondaryMapFilePath
{
	return @"~/MJDVetoMap";
}

-(void) awakeFromNib
{
	detectorSize		 = NSMakeSize(770,770);
	detailsSize			 = NSMakeSize(560,600);
	subComponentViewSize = NSMakeSize(580,530);
	detectorMapViewSize	 = NSMakeSize(1050,565);
	vetoMapViewSize		 = NSMakeSize(460,565);
    [module1InterlockTable setFocusRingType:NSFocusRingTypeNone];
    [module2InterlockTable setFocusRingType:NSFocusRingTypeNone];
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	[subComponentsView setGroup:model];

    [super awakeFromNib];
	
    if([[model segmentGroup:1] colorAxisAttributes])[[secondaryColorScale colorAxis] setAttributes:[[[[model segmentGroup:1] colorAxisAttributes] mutableCopy] autorelease]];
    
	[[secondaryColorScale colorAxis] setRngLimitsLow:0 withHigh:128000000 withMinRng:5];
    [[secondaryColorScale colorAxis] setRngDefaultsLow:0 withHigh:128000000];
    [[secondaryColorScale colorAxis] setOppositePosition:YES];
	[[secondaryColorScale colorAxis] setNeedsDisplay:YES];
    
	[self populateClassNamePopup:secondaryAdcClassNamePopup];

    [primaryAdcClassNamePopup   selectItemAtIndex:1];
    [secondaryAdcClassNamePopup selectItemAtIndex:1];
    
    
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:1 andDataSource:self];
	[aPlot setLineColor:[NSColor blueColor]];
	[ratePlot addPlot: aPlot];
	[aPlot release];
	
	OR1DHistoPlot* aPlot1 = [[OR1DHistoPlot alloc] initWithTag:11 andDataSource:self];
	[aPlot1 setLineColor:[NSColor blueColor]];
    [aPlot1 setName:@"Veto"];
	[valueHistogramsPlot addPlot: aPlot1];
	[aPlot1 release];
    [(ORPlot*)[valueHistogramsPlot plotWithTag: 10] setName:@"Detectors"];
    [valueHistogramsPlot setShowLegend:YES];
    
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORMajoranaModelPollTimeChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(viewTypeChanged:)
                         name : ORMajoranaModelViewTypeChanged
						object: model];

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
                     selector : @selector(vetoMapLockChanged:)
                         name : [model vetoMapLock]
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(vetoMapLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(stringMapChanged:)
                         name : ORMJDAuxTablesChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(ignorePanicOnAChanged:)
                         name : MajoranaModelIgnorePanicOnAChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(ignorePanicOnBChanged:)
                         name : MajoranaModelIgnorePanicOnBChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateInterlockStates:)
                         name : ORMJDInterlocksStateChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateLastConstraintCheck:)
                         name : ORMajoranaModelLastConstraintCheckChanged
                        object: nil];
    
    
    
}

- (void) updateWindow
{
    [super updateWindow];
	[self pollTimeChanged:nil];
	[self viewTypeChanged:nil];
    //detector
    [self secondaryColorAxisAttributesChanged:nil];
    [self stringMapChanged:nil];

	//veto hw map
    [self vetoMapLockChanged:nil];
	[self secondaryMapFileChanged:nil];
	[self secondaryAdcClassNameChanged:nil];
    
	//details
	[secondaryValuesView reloadData];
	[self ignorePanicOnAChanged:nil];
	[self ignorePanicOnBChanged:nil];
    
    //interlocks
    [self groupChanged:nil];
    [module1InterlockTable reloadData];
    [module2InterlockTable reloadData];
    [self updateLastConstraintCheck:nil];
}
- (void) updateLastConstraintCheck:(NSNotification*)aNote
{
    if([model lastConstraintCheck]) [lastTimeCheckedField setStringValue:[[model lastConstraintCheck] stdDescription]];
    else [lastTimeCheckedField setStringValue:@"Never"];
}

- (void) updateInterlockStates:(NSNotification*)aNote
{
    if([aNote object] == [model mjdInterlocks:0]){
        [module1InterlockTable reloadData];
    }
    else {
        [module2InterlockTable setNeedsDisplay:YES];
   }
}

- (void) stringMapChanged:(NSNotification*)aNote
{
	[stringMapTableView reloadData];
	[detectorView makeAllSegments];
}

- (void) checkGlobalSecurity
{
    [super checkGlobalSecurity];
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:[model vetoMapLock] to:secure];
    [vetoMapLockButton setEnabled: secure];
}

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[subComponentsView setNeedsDisplay:YES];
	}
}
- (void) pollTimeChanged:(NSNotification*)aNotification
{
	[pollTimePopup selectItemAtIndex:[model pollTime]];
}

- (void) vetoMapLockChanged:(NSNotification*)aNotification
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model vetoMapLock]];
    //BOOL runningOrLocked = [gSecurity runInProgressOrIsLocked:ORPrespectrometerLock];
    BOOL locked = [gSecurity isLocked:[model vetoMapLock]];
    [vetoMapLockButton setState: locked];
    
    if(locked){
		[secondaryTableView deselectAll:self];
	}
    [readSecondaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
    [saveSecondaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
	[secondaryAdcClassNamePopup setEnabled:!lockedOrRunningMaintenance];
}

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

- (void) colorScaleTypeChanged:(NSNotification*)aNote
{
    [super colorScaleTypeChanged:aNote];
    [secondaryColorScale setUseRainBow:[model colorScaleType]==0];
    [secondaryColorScale setStartColor:[primaryColorScale startColor]];
    [secondaryColorScale setEndColor:[primaryColorScale endColor]];
}


- (void) viewTypeChanged:(NSNotification*)aNote
{
	[viewTypePU selectItemAtIndex:[model viewType]];
	[detectorView setViewType:[model viewType]];
	[detectorView makeAllSegments];	
}

#pragma mark ¥¥¥Interface Management

- (void) ignorePanicOnBChanged:(NSNotification*)aNote
{
	[ignorePanicOnBCB setIntValue: [model ignorePanicOnB]];
    [ignore2Field setStringValue: [model ignorePanicOnB]?@"HV Ramp will be IGNORED":@""];
}

- (void) ignorePanicOnAChanged:(NSNotification*)aNote
{
	[ignorePanicOnACB setIntValue: [model ignorePanicOnA]];
    [ignore1Field setStringValue: [model ignorePanicOnA]?@"HV Ramp will be IGNORED":@""];
}

- (void) specialUpdate:(NSNotification*)aNote
{
	[super specialUpdate:aNote];
	[secondaryTableView reloadData];
	[secondaryValuesView reloadData];
}

- (void) segmentGroupChanged:(NSNotification*)aNote
{
	[super segmentGroupChanged:aNote];
    [detectorView makeAllSegments];
}

- (void) setDetectorTitle
{	
	switch([model displayType]){
		case kDisplayRates:			[detectorTitle setStringValue:@"Detector Rate"];	break;
		case kDisplayThresholds:	[detectorTitle setStringValue:@"Thresholds"];		break;
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

- (void) mapFileRead:(NSNotification*)mapFileRead
{
	[super mapFileRead:mapFileRead];
	[self stringMapChanged:nil];
    int n = [[model segmentGroup:0] numSegments];
    int i;
    for(i=0;i<n;i++){
        [self forceHVUpdate:i];
    }
}

#pragma mark ¥¥¥Details Interface Management
- (void) refreshSegmentTables:(NSNotification*)aNote
{
	[super refreshSegmentTables:aNote];
	[secondaryTableView reloadData];
}

- (void) detailsLockChanged:(NSNotification*)aNotification
{
	[super detailsLockChanged:aNotification];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetailsLock]];
    BOOL locked = [gSecurity isLocked:[model experimentDetailsLock]];

	[detailsLockButton setState: locked];
    [initButton setEnabled: !lockedOrRunningMaintenance];

}
#pragma mark ***Actions
- (void) ignorePanicOnBAction:(id)sender
{
    [self confirmIgnoreForModule:1];
}
- (void) ignorePanicOnAAction:(id)sender
{
    [self confirmIgnoreForModule:0];
}

- (void) confirmIgnoreForModule:(int)module
{
	BOOL currentState;
    if(module == 0) currentState = [model ignorePanicOnA];
    else            currentState = [model ignorePanicOnB];
    
    NSString* s1 = [NSString stringWithFormat:@"Really Turn %@ Constraint Checking for Module %d HV?",!currentState?@"OFF":@"ON",module];
    if(!currentState)s1 = [s1 stringByAppendingFormat:@"\n\n(HV will NOT ramp down if vac is bad)"];
    else            s1 = [s1 stringByAppendingFormat:@"\n\n(HV will ramp down on next check if vac is bad)"];
    
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s1];
    [alert setInformativeText:@""];
    [alert addButtonWithTitle:[NSString stringWithFormat:@"YES/Turn %@ HV Checks",!currentState?@"OFF":@"ON"]];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if(result == NSAlertFirstButtonReturn){
            if(module == 0) [model setIgnorePanicOnA:!currentState];
            else            [model setIgnorePanicOnB:!currentState];
        }
        else {
            if(module == 0) [model setIgnorePanicOnA:currentState];
            else            [model setIgnorePanicOnB:currentState];
        }
    }];
#else
    NSDictionary* context = [[NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:module],@"module",
                              [NSNumber numberWithInt:currentState],@"currentState",
                              nil] retain]; //release in confirmDidFinish()
    NSBeginAlertSheet(s1,
                      [NSString stringWithFormat:@"YES/Turn %@ HV Checks",!currentState?@"OFF":@"ON"],
					  @"Cancel",
					  nil,[self window],
					  self,
					  @selector(confirmDidFinish:returnCode:contextInfo:),
					  nil,
					  context,
					  @"");
#endif
}


#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) confirmDidFinish:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
    int module = [[userInfo objectForKey:@"module"]intValue];
    BOOL currentState= [[userInfo objectForKey:@"currentState"]intValue];
    
	if(returnCode == NSAlertDefaultReturn){
        if(module == 0) [model setIgnorePanicOnA:!currentState];
        else            [model setIgnorePanicOnB:!currentState];
    }
    else {
        if(module == 0) [model setIgnorePanicOnA:currentState];
        else            [model setIgnorePanicOnB:currentState];
    }
    [userInfo release];
}
#endif


- (IBAction) resetInterLocksOnModule0:(id)sender
{
    [[model mjdInterlocks:0] reset:YES];
    [model setPollTime:[model pollTime]];
}

- (IBAction) resetInterLocksOnModule1:(id)sender
{
    [[model mjdInterlocks:1] reset:YES];
    [model setPollTime:[model pollTime]];
}

- (IBAction) pollTimeAction:(id)sender
{
    [[model mjdInterlocks:0] reset:YES];
    [[model mjdInterlocks:1] reset:YES];
	[model setPollTime:[sender indexOfSelectedItem]];
}
- (IBAction) viewTypeAction:(id)sender
{
	[model setViewType:[sender indexOfSelectedItem]];
}

- (IBAction) autoscaleSecondayColorScale:(id)sender
{
    int n = [[model segmentGroup:1] numSegments];
    int i;
    float maxValue = -99999;
    for(i=0;i<n;i++){
        float aValue = maxValue;
        switch([model displayType]){
            case kDisplayThresholds:	aValue = [[model segmentGroup:1] getThreshold:i];     break;
            case kDisplayRates:			aValue = [[model segmentGroup:1] getRate:i];		  break;
            case kDisplayTotalCounts:	aValue = [[model segmentGroup:1] getTotalCounts:i];   break;
            default:	break;
        }
        if(aValue>maxValue)maxValue = aValue;
    }
    if(maxValue != -99999){
        maxValue += (maxValue*.20);
        [[secondaryColorScale colorAxis] setRngLow:0 withHigh:maxValue];
    }
}

- (IBAction) secondaryAdcClassNameAction:(id)sender
{
	[[model segmentGroup:1] setAdcClassName:[sender titleOfSelectedItem]];
}

- (IBAction) vetoMapLockAction:(id)sender
{
    [gSecurity tryToSetLock:[model vetoMapLock] to:[sender intValue] forWindow:[self window]];
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
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [[model segmentGroup:1] readMap:[[openPanel URL] path]];
            [secondaryTableView reloadData];
        }
    }];

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
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [[model segmentGroup:1] saveMapFileAs:[[savePanel URL]path]];
        }
    }];
}

#pragma mark ¥¥¥Table Data Source
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detectorSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detailsSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:subComponentViewSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detectorMapViewSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 4){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:vetoMapViewSize];
		[[self window] setContentView:tabView];
    }
	int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.MajoranaController.selectedtab"];
}


- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    
	if(aTableView == primaryTableView){
        if([[aTableColumn identifier] isEqualToString:@"kChanLo"]){
           return [[model segmentGroup:0] segment:rowIndex*2 objectForKey:@"kChannel"];
        }
        else if([[aTableColumn identifier] isEqualToString:@"kChanHi"]){
           return [[model segmentGroup:0] segment:rowIndex*2+1 objectForKey:@"kChannel"];
        }
 
        else if([[aTableColumn identifier] isEqualToString:@"kSegmentNumber"]){
            return [NSNumber numberWithInt:rowIndex];
        }
        else {
            return [[model segmentGroup:0] segment:rowIndex*2 objectForKey:[aTableColumn identifier]];
        }
	}
    else if(aTableView == primaryValuesView){
        if([[aTableColumn identifier] isEqualToString:@"loThreshold"]){
            return [[model segmentGroup:0] segment:rowIndex*2 objectForKey:@"threshold"];
        }
        else if([[aTableColumn identifier] isEqualToString:@"hiThreshold"]){
            return [[model segmentGroup:0] segment:rowIndex*2+1 objectForKey:@"threshold"];
        }
        else {
            return [[model segmentGroup:0] segment:rowIndex*2 objectForKey:[aTableColumn identifier]];
        }
    }
    else if(aTableView == secondaryTableView || aTableView == secondaryValuesView){
        if([[aTableColumn identifier] isEqualToString:@"kSegmentNumber"]){
            return [NSNumber numberWithInt:rowIndex];
        }
		else return [[model segmentGroup:1] segment:rowIndex objectForKey:[aTableColumn identifier]];
	}
    
    else if(aTableView == stringMapTableView){
        if([[aTableColumn identifier] isEqualToString:@"kStringNum"]){
            int stringIndex = [[model stringMap:rowIndex objectForKey:[aTableColumn identifier]]intValue];
            NSString* stringId = [NSString stringWithFormat:@"%d",stringIndex];
            return stringId;
        }
		else return [model stringMap:rowIndex objectForKey:[aTableColumn identifier]];
	}
    else if(aTableView == module1InterlockTable){
        ORMJDInterlocks* mjdInterLocks = [model mjdInterlocks:0];
        
        if([[aTableColumn identifier] isEqualToString:@"name"]) return [mjdInterLocks stateName:rowIndex];
        else                                                    return [mjdInterLocks stateStatus:rowIndex];
    }
    else if(aTableView == module2InterlockTable){
        ORMJDInterlocks* mjdInterLocks = [model mjdInterlocks:1];
        if([[aTableColumn identifier] isEqualToString:@"name"]) return [mjdInterLocks stateName:rowIndex];
        else                                                    return [mjdInterLocks stateStatus:rowIndex];
    }

	else return nil;
}

- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if( aTableView == secondaryTableView ||
        aTableView == secondaryValuesView){
        return [[model segmentGroup:1] numSegments];
    }
    else if((aTableView == module1InterlockTable) || (aTableView == module2InterlockTable) ){
        int module;
        if(aTableView == module1InterlockTable) module = 0;
        else                                    module = 1;
        ORMJDInterlocks* mjdInterLocks = [model mjdInterlocks:module];
        return [mjdInterLocks numStates];
    }

    else if(aTableView == stringMapTableView)return kMaxNumStrings;


	else return [super numberOfRowsInTableView:aTableView]/2;
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if(!anObject)anObject= @"--";
    
	ORDetectorSegment* aSegment;
	if(aTableView == primaryTableView){
        if([[aTableColumn identifier] isEqualToString:@"kChanLo"]){
            aSegment = [[model segmentGroup:0] segment:rowIndex*2];
            [aSegment setObject:anObject forKey:@"kChannel"];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex*2] forKey:@"kSegmentNumber"];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex] forKey:@"kDetector"];
            [aSegment setObject:[NSNumber numberWithInt:0] forKey:@"kGainType"];
        }
        else if([[aTableColumn identifier] isEqualToString:@"kChanHi"]){
            aSegment = [[model segmentGroup:0] segment:rowIndex*2+1];
            [aSegment setObject:anObject forKey:@"kChannel"];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex*2+1] forKey:@"kSegmentNumber"];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex] forKey:@"kDetector"];
            [aSegment setObject:[NSNumber numberWithInt:1] forKey:@"kGainType"];
        }
        else {
            aSegment = [[model segmentGroup:0] segment:rowIndex*2];
            [aSegment setObject:anObject forKey:[aTableColumn identifier]];
            if([[aTableColumn identifier] isEqualToString:@"kMaxVoltage"]){
                [self forceHVUpdate:rowIndex*2];
            }
            [aSegment setObject:[NSNumber numberWithInt:rowIndex] forKey:@"kDetector"];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex*2] forKey:@"kSegmentNumber"];
          
            aSegment = [[model segmentGroup:0] segment:rowIndex*2+1];
            [aSegment setObject:anObject forKey:[aTableColumn identifier]];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex*2+1] forKey:@"kSegmentNumber"];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex] forKey:@"kDetector"];
        }
        [[model segmentGroup:0] configurationChanged:nil];
	}
    
    else if(aTableView == stringMapTableView){
		[model stringMap:rowIndex setObject:anObject forKey:[aTableColumn identifier]];
	}
    
	else if(aTableView == primaryValuesView){
        if([[aTableColumn identifier] isEqualToString:@"loThreshold"]){
            aSegment = [[model segmentGroup:0] segment:rowIndex*2];
 			[aSegment setThreshold:anObject];
        }
        else if([[aTableColumn identifier] isEqualToString:@"hiThreshold"]){
            aSegment = [[model segmentGroup:0] segment:rowIndex*2+1];
 			[aSegment setThreshold:anObject];
       }
  	}
    
    else if(aTableView == secondaryTableView){
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
}

- (void) forceHVUpdate:(int)segIndex
{
    ORDetectorSegment* aSegment = [[model segmentGroup:0] segment:segIndex];
    //find the HV card
    NSArray* hvCards = [[model document] collectObjectsOfClass:NSClassFromString(@"ORiSegHVCard")];
    for(ORiSegHVCard* aHVCard in hvCards){
        int crateNum  = [[[aSegment params] objectForKey:@"kHVCrate"] intValue];
		int cardNum   = [[[aSegment params] objectForKey:@"kHVCard"] intValue];
		int chanNum   = [[[aSegment params] objectForKey:@"kHVChan"] intValue];
        if([aHVCard crateNumber] != crateNum) continue;
        if([aHVCard slot]        != cardNum) continue;
        [aHVCard setMaxVoltage:chanNum withValue:[[[aSegment params] objectForKey:@"kMaxVoltage"] intValue] ];
        [aHVCard setChan:chanNum name:[[aSegment params] objectForKey:@"kDetectorName"]];
        break;
    }
}
@end
