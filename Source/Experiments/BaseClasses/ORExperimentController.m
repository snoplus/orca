//
//  ORExperimentController.m
//  Orca
//
//  Created by Mark Howe on 12/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORExperimentController.h"
#import "ORExperimentModel.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORPlotter1D.h"
#import "ORTimeRate.h"
#import "BiStateView.h"
#import "ORReplayDataModel.h"
#import "ORDetectorView.h"
#import "ORDetectorSegment.h"
#import "ORAdcInfoProviding.h"
#import "ORSegmentGroup.h"
#import "ORRunModel.h"

@interface ORExperimentController (private)
- (void) readPrimaryMapFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) savePrimaryMapFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) scaleValueHistogram;
@end


@implementation ORExperimentController

-(void) awakeFromNib
{
	[detectorView setDelegate:model];	
    
	NSString* tabPrefName = [NSString stringWithFormat:@"orca.%@.selectedtab",[self className]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: tabPrefName];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
        
	[[valueHistogramsPlot xScale] setRngLimitsLow:0 withHigh:50000 withMinRng:64];
	[[primaryColorScale colorAxis] setRngLimitsLow:0 withHigh:50000 withMinRng:5];
 	[[primaryColorScale colorAxis] setRngDefaultsLow:0 withHigh:50000];
   
    [[ratePlot xScale] setNeedsDisplay:YES];
    [[ratePlot yScale] setNeedsDisplay:YES];
    [[primaryColorScale colorAxis] setNeedsDisplay:YES];
    [selectionStringTextView setFont:[NSFont fontWithName:@"Monaco" size:9]];

	[self populateClassNamePopup:primaryAdcClassNamePopup];

	if([model replayMode]){
		[self updateForReplayMode];
	}

	[self findRunControl:nil];
	
    [super awakeFromNib];

}


- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[self loadSegmentGroups];
	[detectorView setDelegate:model];	
}

#pragma mark •••Subclass responsibility
- (void) loadSegmentGroups {;}
- (NSString*) defaultPrimaryMapFilePath{return @"";}
- (void) setDetectorTitle{;}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ExperimentDisplayUpdatedNeeded
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(findRunControl:)
                         name : ORGroupObjectsAdded
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(findRunControl:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    							
    [notifyCenter addObserver : self
                     selector : @selector(newTotalRateAvailable:)
                         name : ExperimentCollectedRates
                       object : model];
                
	[notifyCenter addObserver : self
                     selector : @selector(mapFileRead:)
                         name : ORSegmentGroupMapReadNotification
                       object : nil];
        
    [notifyCenter addObserver : self
                     selector : @selector(mapLockChanged:)
                         name : [model experimentMapLock]
					object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(detectorLockChanged:)
                         name : [model experimentDetectorLock]
                       object : nil];
                           
    [notifyCenter addObserver : self
                     selector : @selector(detectorLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(mapLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
        
    [notifyCenter addObserver : self
                     selector : @selector(hardwareCheckChanged:)
                         name : ExperimentHardwareCheckChangedNotification
                       object : nil];
                       
    [notifyCenter addObserver : self
                     selector : @selector(cardCheckChanged:)
                         name : ExperimentCardCheckChangedNotification
                       object : nil];
            
    [notifyCenter addObserver : self
                     selector : @selector(captureDateChanged:)
                         name : ExperimentCaptureDateChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(replayStarted:)
                         name : ORReplayRunningNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(replayStopped:)
                         name : ORReplayStoppedNotification
                       object : nil];    
					   
    [notifyCenter addObserver : self
                     selector : @selector(primaryAdcClassNameChanged:)
                         name : ORSegmentGroupAdcClassNameChanged
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(selectionStringChanged:)
                         name : ExperimentModelSelectionStringChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(selectionChanged:)
                         name : ExperimentModelSelectionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(primaryMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(displayTypeChanged:)
                         name : ExperimentModelDisplayTypeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(specialUpdate:)
                         name : ORAdcInfoProvidingValueChanged
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(specialUpdate:)
                         name : ORSegmentGroupConfiguationChanged
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(detailsLockChanged:)
                         name : [model experimentDetailsLock]
					object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(detailsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(histogramsUpdated:)
                         name : ExperimentDisplayHistogramsUpdated
						object: nil];

	[notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(updateRunInfo:)
						 name : ORRunStatusChangedNotification
					   object : nil];


    [notifyCenter addObserver : self
					 selector : @selector(timedRunChangted:)
						 name : ORRunTimedRunChangedNotification
					   object : nil];

   [notifyCenter addObserver : self
					 selector : @selector(repeatRunChanged:)
						 name : ORRunRepeatRunChangedNotification
					   object : nil];

   [notifyCenter addObserver : self
					 selector : @selector(runTimeLimitChanged:)
						 name : ORRunTimeLimitChangedNotification
					   object : nil];

   [notifyCenter addObserver : self
					 selector : @selector(runModeChanged:)
						 name : ORRunModeChangedNotification
					   object : nil];

   [notifyCenter addObserver: self
                     selector: @selector(elapsedTimeChanged:)
                         name: ORRunElapsedTimesChangedNotification
                       object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(showNamesChanged:)
                         name : ORExperimentModelShowNamesChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];
    [self miscAttributesChanged:nil];
    [self mapLockChanged:nil];
    [self detectorLockChanged:nil];
    [self hardwareCheckChanged:nil];
    [self cardCheckChanged:nil];
    [self captureDateChanged:nil];
	[self newTotalRateAvailable:nil];
    [ratePlot setNeedsDisplay:YES];
	[self selectionStringChanged:nil];
	[self primaryMapFileChanged:nil];
	[self displayTypeChanged:nil];	
	[self primaryAdcClassNameChanged:nil];
	[self selectionChanged:nil];

	[self timedRunChangted:nil];
	[self runModeChanged:nil];
	[self runTimeLimitChanged:nil];
	[self repeatRunChanged:nil];
	[self elapsedTimeChanged:nil];
	
		//details
	[self detailsLockChanged:nil];
	[self histogramsUpdated:nil];
	[self setValueHistogramTitle];
	[self scaleValueHistogram];
    [valueHistogramsPlot setNeedsDisplay:YES];
	[primaryValuesView reloadData];
	[self showNamesChanged:nil];
}

- (void) findRunControl:(NSNotification*)aNote
{
	runControl = [[[NSApp delegate] document] findObjectWithFullID:@"ORRunModel,1"];
	if(!runControl){
		runControl = [[[NSApp delegate] document] findObjectWithFullID:@"ORRemoteRunModel,1"];	
	}
	[self updateRunInfo:nil];
	[startRunButton setEnabled:runControl!=nil];
	[timedRunCB setEnabled:runControl!=nil];
	[runModeMatrix setEnabled:runControl!=nil];
}

- (void) timedRunChangted:(NSNotification*)aNote
{
	[timedRunCB setIntValue:[runControl timedRun]];
	[repeatRunCB setEnabled:[runControl timedRun]];
	[timeLimitField setEnabled:[runControl timedRun]];
}

- (void) runModeChanged:(NSNotification*)aNote
{
	[runModeMatrix selectCellWithTag: [[ORGlobal sharedGlobal] runMode]];
}

- (void) runTimeLimitChanged:(NSNotification*)aNote
{
	[timeLimitField setIntValue:[runControl timeLimit]];		
}

- (void) repeatRunChanged:(NSNotification*)aNote
{
	[repeatRunCB setIntValue:[runControl repeatRun]];
}


-(void) elapsedTimeChanged:(NSNotification*)aNotification
{

	if(runControl)[elapsedTimeField setStringValue:[runControl elapsedRunTimeString]];
	else [elapsedTimeField setStringValue:@"---"];
	if([runControl timedRun]){
		double timeLimit = [runControl timeLimit];
		double elapsedRunTime = [runControl elapsedRunTime];
		[runBar setDoubleValue:100*elapsedRunTime/timeLimit];
	}
}


- (void) updateRunInfo:(NSNotification*)aNote
{
	if(runControl)	{
		[runStatusField setStringValue:[runControl shortStatus]];
		[runNumberField setIntValue:[runControl runNumber]];
		
		if([runControl isRunning]){
			[runBar setIndeterminate:!([runControl timedRun] && ![runControl remoteControl])];
			[runBar setDoubleValue:0];
			[runBar startAnimation:self];

		}
		else {
			[elapsedTimeField setStringValue:@"---"];
			[runBar setDoubleValue:0];
			[runBar stopAnimation:self];
			[runBar setIndeterminate:NO];
		}
	}
	else {
		[runStatusField setStringValue:@"---"];
		[runNumberField setStringValue:@"---"];
		[elapsedTimeField setStringValue:@"---"];
	}
	[stopRunButton setEnabled:[runControl isRunning]];
	[timedRunCB setEnabled:![runControl isRunning]];
	[timeLimitField setEnabled:![runControl isRunning]];
	[runModeMatrix setEnabled:![runControl isRunning]];
}


- (void) updateForReplayMode
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateForReplayMode) object:nil];
	if([model replayMode]){
		//[[model detector] loadTotalCounts];
		[detectorView setNeedsDisplay:YES];
		[self performSelector:@selector(updateForReplayMode) withObject:nil afterDelay:.5];
	}
}

#pragma mark •••Actions

- (IBAction) showNamesAction:(id)sender
{
	[self endEditing];
	[model setShowNames:[sender intValue]];	
}

- (IBAction) startRunAction:(id)sender
{
	[self endEditing];
	if([runControl isRunning])[runControl restartRun];
	else [runControl startRun];
}

- (IBAction) stopRunAction:(id)sender
{
	[self endEditing];
	[runControl haltRun];
}

- (IBAction) timeLimitTextAction:(id)sender
{
	[runControl setTimeLimit:[sender intValue]];
}

- (IBAction) timedRunCBAction:(id)sender
{
	[self endEditing];
	[runControl setTimedRun:[sender intValue]];
}

- (IBAction) repeatRunCBAction:(id)sender
{
	[self endEditing];
	[runControl setRepeatRun:[sender intValue]];
}

- (IBAction) runModeAction:(id)sender
{
	[self endEditing];
    int tag = [[runModeMatrix selectedCell] tag];
    if(tag != [[ORGlobal sharedGlobal] runMode]){
        [[ORGlobal sharedGlobal] setRunMode:tag];
    }
}

- (IBAction) displayTypeAction:(id)sender
{
	[self endEditing];
	int type = [[sender selectedCell] tag];
	[model setDisplayType:type];	
	[self setValueHistogramTitle];
	[self scaleValueHistogram];
}

- (IBAction) primaryAdcClassNameAction:(id)sender
{
	[[segmentGroups objectAtIndex:0] setAdcClassName:[sender titleOfSelectedItem]];	
}

- (IBAction) captureStateAction:(id)sender
{
    [model captureState];
	[detectorView setNeedsDisplay:YES];
}

- (IBAction) reportConfigAction:(id)sender
{
    [model printProblemSummary];
}

- (IBAction) readPrimaryMapFileAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[[segmentGroups objectAtIndex:0] mapFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
    }
    [openPanel beginSheetForDirectory:startingDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(readPrimaryMapFilePanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}


- (IBAction) savePrimaryMapFileAction:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[[segmentGroups objectAtIndex:0] mapFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = [self defaultPrimaryMapFilePath];
        
    }
    [savePanel beginSheetForDirectory:startingDir
                                 file:[defaultFile stringByExpandingTildeInPath]
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(savePrimaryMapFilePanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (IBAction) mapLockAction:(id)sender
{
    [gSecurity tryToSetLock:[model experimentMapLock] to:[sender intValue] forWindow:[self window]];
}

- (IBAction) detectorLockAction:(id)sender
{
    [gSecurity tryToSetLock:[model experimentDetectorLock] to:[sender intValue] forWindow:[self window]];
}

#pragma mark •••Details Actions
- (IBAction) initAction:(id)sender;
{
	[model initHardware];
	[self  specialUpdate:nil];

}

- (IBAction) detailsLockAction:(id)sender
{
    [gSecurity tryToSetLock:[model experimentDetailsLock] to:[sender intValue] forWindow:[self window]];
}

#pragma mark •••Interface Management

- (void) showNamesChanged:(NSNotification*)aNote
{
	[showNamesCB setIntValue: [model showNames]];
	[detectorView setNeedsDisplay:YES];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [ratePlot xScale]){
		[model setMiscAttributes:[[ratePlot xScale]attributes] forKey:@"XAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [ratePlot yScale]){
		[model setMiscAttributes:[[ratePlot yScale]attributes] forKey:@"YAttributes"];
	};
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes"];
		if(attrib){
			[[ratePlot xScale] setAttributes:attrib];
			[ratePlot setNeedsDisplay:YES];
			[[ratePlot xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes"];
		if(attrib){
			[[ratePlot yScale] setAttributes:attrib];
			[ratePlot setNeedsDisplay:YES];
			[[ratePlot yScale] setNeedsDisplay:YES];
			[rateLogCB setState:[[ratePlot yScale] isLog]];
		}
	}
}

- (void) specialUpdate:(NSNotification*)aNote
{
	[model compileHistograms];
	[detectorView setNeedsDisplay:YES];	
	[primaryValuesView reloadData];
	[valueHistogramsPlot setNeedsDisplay:YES];
}

- (void) selectionChanged:(NSNotification*)aNote
{
}

- (void) displayTypeChanged:(NSNotification*)aNote
{
	[displayTypeMatrix selectCellWithTag: [model displayType]];
	[displayTypeMatrix1 selectCellWithTag: [model displayType]];
	[model compileHistograms];
	[detectorView setNeedsDisplay:YES];
	[valueHistogramsPlot setNeedsDisplay:YES];
	[self setDetectorTitle];
}

- (void) primaryMapFileChanged:(NSNotification*)aNote
{
	NSString* s = [[segmentGroups objectAtIndex:0] mapFile];
	if(s)[primaryMapFileTextField setStringValue: s];
	else [primaryMapFileTextField setStringValue: @"--"];
}

- (void) selectionStringChanged:(NSNotification*)aNote
{
	[selectionStringTextView setString: [model selectionString]];
}

- (void) primaryAdcClassNameChanged:(NSNotification*)aNote
{
	[primaryAdcClassNamePopup selectItemWithTitle: [[segmentGroups objectAtIndex:0] adcClassName]];
}

- (void) mapFileRead:(NSNotification*)aNote
{
    if(aNote == nil || [aNote object] == model){
        [primaryTableView reloadData];
    }
}

- (void) newTotalRateAvailable:(NSNotification*)aNotification
{
	[primaryRateField setFloatValue:[[segmentGroups objectAtIndex:0] rate]];
	[ratePlot setNeedsDisplay:YES];
	[detectorView setNeedsDisplay:YES];
	[valueHistogramsPlot setNeedsDisplay:YES];
}


- (void) objectsChanged:(NSNotification*)aNote
{
	[detectorView setNeedsDisplay:YES];
}

- (void) mapLockChanged:(NSNotification*)aNotification
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetectorLock]];
    BOOL locked = [gSecurity isLocked:[model experimentMapLock]];
    [mapLockButton setState: locked];
    
    if(locked)[primaryTableView deselectAll:self];
    [readPrimaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
    [savePrimaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
	[primaryAdcClassNamePopup setEnabled:!lockedOrRunningMaintenance]; 
}

- (void) detectorLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:[model experimentDetectorLock]];
    [detectorLockButton setState: locked];
    [captureStateButton setEnabled: !locked];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    //add setLock calls here as new lock buttons
    //are added to this dialog.
    [gSecurity setLock:[model experimentMapLock] to:secure];
    [gSecurity setLock:[model experimentDetectorLock] to:secure];
    [gSecurity setLock:[model experimentDetailsLock] to:secure];
    [mapLockButton setEnabled: secure];
    [detectorLockButton setEnabled: secure];
    [detailsLockButton setEnabled: secure];
    
}

- (void) hardwareCheckChanged:(NSNotification*)aNotification
{
    [hardwareCheckView setState:[model hardwareCheck]]; 
}

- (void) cardCheckChanged:(NSNotification*)aNotification
{
    [cardCheckView setState:[model cardCheck]]; 
}

- (void) captureDateChanged:(NSNotification*)aNotification
{
    [captureDateField setObjectValue:[model captureDate]]; 
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
	if(tableView == primaryTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == primaryValuesView){
		return ![gSecurity isLocked:[model experimentDetailsLock]];
	}
	else return YES;
}

- (void) replayStarted:(NSNotification*)aNote
{
	//[[model detector] clearAdcCounts]; 
	[model setReplayMode:YES];
	[self updateForReplayMode];
}

- (void) replayStopped:(NSNotification*)aNote
{
	[model setReplayMode:NO];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateForReplayMode) object:nil];
}

- (void) scaleValueHistogram
{

    [[valueHistogramsPlot xScale] setRngLow:0 withHigh:64];
	switch([model displayType]){
		case kDisplayRates:		[[valueHistogramsPlot xScale] setRngLow:0 withHigh:64]; break;
		case kDisplayThresholds:
		case kDisplayGains:		
			[valueHistogramsPlot xAndYAutoScale];
		break;
		default: break;
	}
}


- (int) numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	if(aPlotter == ratePlot){
		return [[[segmentGroups objectAtIndex:set]  totalRate] count];
	}
	else if(aPlotter == valueHistogramsPlot){
		int displayType = [model displayType];
		switch(displayType){
				case kDisplayRates: return [[segmentGroups objectAtIndex:set] numSegments];
				default:		    return 1000;
		}
	}
	else return 0;
}

#pragma mark •••Details Interface Management
- (void) histogramsUpdated:(NSNotification*)aNote
{
	[self scaleValueHistogram];
	[valueHistogramsPlot setNeedsDisplay:YES];
}

- (void) detailsLockChanged:(NSNotification*)aNotification
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetailsLock]];
    BOOL locked = [gSecurity isLocked:[model experimentDetailsLock]];

	[detailsLockButton setState: locked];
    [initButton setEnabled: !lockedOrRunningMaintenance];

	if(locked){
		[primaryValuesView deselectAll:self];
	}
}

- (void) setValueHistogramTitle
{	
	switch([model displayType]){
		case kDisplayRates:			
			[histogramTitle setStringValue:@"Channel Rates"];
			[valueHistogramsPlot setXLabel:@"Channel" yLabel:@"Counts/Sec"];	
		break;
		case kDisplayThresholds:	
			[histogramTitle setStringValue:@"Threshold Distribution"];	
			[valueHistogramsPlot setXLabel:@"Raw Threshold Value" yLabel:@"# Channels"];	
		break;
		case kDisplayGains:			
			[histogramTitle setStringValue:@"Gain Distribution"];		
			[valueHistogramsPlot setXLabel:@"Gain Value" yLabel:@"# Channels"];	
		break;
		default: break;
	}
}

#pragma mark •••Data Source For Plots
- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x
{
	if(aPlotter == ratePlot){
		int count = [[[segmentGroups objectAtIndex:set] totalRate] count];
		if(count==0)return 0;
		return [[[segmentGroups objectAtIndex:set] totalRate] valueAtIndex:count-x-1];
	}
	else if(aPlotter == valueHistogramsPlot){
		int displayType = [model displayType];
		float aValue = 0;
		switch(displayType){
			case kDisplayThresholds: aValue = [[segmentGroups objectAtIndex:set] thresholdHistogram:x];	break;
			case kDisplayGains:		 aValue = [[segmentGroups objectAtIndex:set] gainHistogram:x];		break;
			case kDisplayRates:		 aValue = [[segmentGroups objectAtIndex:set] getRate:x];				break;
			default:	break;
		}
		return aValue;
	}
	else return 0;
}

- (unsigned long) secondsPerUnit:(id) aPlotter
{
    return [[[segmentGroups objectAtIndex:0] totalRate] sampleTime];
}

- (int)	numberOfDataSetsInPlot:(id)aPlotter
{
    return [segmentGroups count];
}

#pragma mark •••Data Source For Tables
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	return [[segmentGroups objectAtIndex:0] segment:rowIndex objectForKey:[aTableColumn identifier]];
}

- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[segmentGroups objectAtIndex:0] numSegments];
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	ORDetectorSegment* aSegment;
	if(aTableView == primaryTableView){
		aSegment = [[segmentGroups objectAtIndex:0] segment:rowIndex];
		[aSegment setObject:anObject forKey:[aTableColumn identifier]];
		[[segmentGroups objectAtIndex:0] configurationChanged:nil];
	}
	else if(aTableView == primaryValuesView){
		aSegment = [[segmentGroups objectAtIndex:0] segment:rowIndex];
		if([[aTableColumn identifier] isEqualToString:@"threshold"]){
			[aSegment setThreshold:anObject];
		}
		else if([[aTableColumn identifier] isEqualToString:@"gain"]){
			[aSegment setGain:anObject];
		}
	}

}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    int index = [tabView indexOfTabViewItem:item];
	NSString* tabPrefName = [NSString stringWithFormat:@"orca.%@.selectedtab",[self className]];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:tabPrefName];
    
}
- (void) populateClassNamePopup:(NSPopUpButton*)aPopup
{
	[aPopup removeAllItems];
	[aPopup addItemWithTitle:@"--"];
	NSArray* allCardsObservingProtocol = [[[NSApp delegate] document] collectObjectsConformingTo:@protocol(ORAdcInfoProviding)];
	NSEnumerator* e = [allCardsObservingProtocol objectEnumerator];
	id aCard;
	while(aCard = [e nextObject]){
		NSString* className = NSStringFromClass([aCard class]);
		if(![aPopup itemWithTitle:className]){
			[aPopup addItemWithTitle:className];
		}
	}
}
@end

@implementation ORExperimentController (private)

- (void) scaleValueHistogram
{
	switch([model displayType]){
		case kDisplayRates:		[[valueHistogramsPlot xScale] setRngLow:0 withHigh:[model maxNumSegments]]; break;
		case kDisplayThresholds:
		case kDisplayGains:		
			[valueHistogramsPlot xAndYAutoScale];
		break;
		default: break;
	}
}


- (void)readPrimaryMapFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [[segmentGroups objectAtIndex:0] setMapFile:[[[sheet filenames] objectAtIndex:0]stringByAbbreviatingWithTildeInPath]];
		[[segmentGroups objectAtIndex:0] readMap];
		[primaryTableView reloadData];
    }
}

- (void)savePrimaryMapFilePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [[segmentGroups objectAtIndex:0] saveMapFileAs:[sheet filename]];
    }
}
@end