//
//  SNOController.m
//  Orca
//
//  Created by H S  Wan Chan Tseung on 11/18/11.
//  Copyright (c) 2011 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "SNOController.h"
#import "SNOModel.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORSNOConstants.h"
#import "ORRunModel.h"

@implementation SNOController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"SNO"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

-(void) awakeFromNib
{
	runControlSize		= NSMakeSize(465,260);
	detectorSize        = NSMakeSize(1121,734);
	slowControlSize		= NSMakeSize(600,650);
	
	[[self window] setContentSize:runControlSize];
	
//	[[self window] setAspectRatio:NSMakeSize(5,3)];
//	[[self window] setMinSize:NSMakeSize(600,360)];	
    blankView = [[NSView alloc] init];
//    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
	SNOMonitoredHardware *db = [SNOMonitoredHardware sharedSNOMonitoredHardware];
	[db readCableDBDocumentFromOrcaDB];
	[db release];
	
	[self findRunControl];
    [super awakeFromNib];

	/*[secondaryColorScale setSpectrumRange:0.7];
	[[secondaryColorScale colorAxis] setRngLimitsLow:0 withHigh:20 withMinRng:1];
    [[secondaryColorScale colorAxis] setRngDefaultsLow:0 withHigh:20];
	[[secondaryColorScale colorAxis] setNeedsDisplay:YES];*/
	
	[selectionStringTextView setFont:[NSFont fontWithName:@"Monaco" size:9]];
}

#pragma mark •••Accessors


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    /*[notifyCenter addObserver : self
                     selector : @selector(colorAttributesChanged:)
                         name : ORSNORateColorBarChangedNotification
                       object : model];*/
    
    //a fake action for the scale objects
    /*[notifyCenter addObserver : self
                     selector : @selector(scaleAction:)
                         name : ORAxisRangeChangedNotification
                       object : nil];*/

    [notifyCenter addObserver : self
					 selector : @selector(updateRunInfo:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
	[notifyCenter addObserver: self
                     selector: @selector(elapsedTimeChanged:)
                         name: ORRunElapsedTimesChangedNotification
                       object: nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectionStringChanged:)
						 name : selectionStringChanged
					   object : detectorView];
	
    [notifyCenter addObserver : self
					 selector : @selector(slowControlTableChanged:)
						 name : slowControlTableChanged
					   object : model];	

	[notifyCenter addObserver : self
					 selector : @selector(slowControlConnectionStatusChanged:)
						 name : slowControlConnectionStatusChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(morcaDBRead:)
						 name : morcaDBRead
					   object : model];
}

#pragma mark •••Actions
//a fake action from the scale object
/*
- (void) scaleAction:(NSNotification*)aNotification
{
    if(aNotification == nil || [aNotification object] == [detectorColorBar colorAxis]){
        [[self undoManager] setActionName: @"Set Color Bar Attributes"];
        [model setColorBarAttributes:[[detectorColorBar colorAxis]attributes]];
    }
}*/

//Run control action
- (void) findRunControl
{
	runControl = [[[NSApp delegate] document] findObjectWithFullID:@"ORRunModel,1"];
	//	if(!runControl){
	//		runControl = [[[NSApp delegate] document] findObjectWithFullID:@"ORRemoteRunModel,1"];	
	//	}
	[self updateRunInfo:nil];
	//	[startRunButton setEnabled:runControl!=nil];
	//	[timedRunCB setEnabled:runControl!=nil];
	//	[runModeMatrix setEnabled:runControl!=nil];
	
}

- (IBAction) startRunAction:(id) sender
{
	if([runControl isRunning]){
		//if ([startRunButton state]==0) [startRunButton setState:1]; 
		[runControl restartRun];
	}else{
		[runControl startRun];
	}
}

- (IBAction) stopRunAction:(id) sender;
{
	//if ([startRunButton state]==1) [startRunButton setState:0];
	[runControl haltRun];
}

- (void) updateRunInfo:(NSNotification*)aNote
{
	if(runControl)	{
		[runStatusField setStringValue:[runControl shortStatus]];
		[runNumberField setIntValue:[runControl runNumber]];
		
		if([runControl isRunning]){
			[startRunButton setState:1];
			[runBar setIndeterminate:!([runControl timedRun] && ![runControl remoteControl])];
			[runBar setDoubleValue:0];
			[runBar startAnimation:self];
			
		}
		else if (![runControl isRunning]){
			[startRunButton setState:0];
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

- (IBAction) showTotalDataRate:(id) sender;
{
	[totalDataRateWindow makeKeyAndOrderFront:sender];
}

- (IBAction) showMonitorWindow:(id) sender;
{
	[detectorView updateSNODetectorView];
	[monitorWindow makeKeyAndOrderFront:sender];
}

//detector view actions

- (void) viewSelectionAction:(id)sender
{ 
	if ([[sender selectedItem] tag]==0){
		[detectorView setViewType:YES];		
	} else if ([[sender selectedItem] tag]==1) {
		[detectorView setViewType:NO];
	}
	
	[detectorView updateSNODetectorView];
}

- (void) parameterDisplayAction:(id)sender
{
	[detectorView setParameterToDisplay:[[sender selectedItem] tag]];
	[model getDataFromMorca];
	[detectorView updateSNODetectorView];
}

- (void) selectionModeAction:(id)sender
{
	[detectorView setSelectionMode:[[sender selectedItem] tag]];
	//[model getDataFromMorca];
	[detectorView updateSNODetectorView];
}

- (void) readMorca:(id)sender
{
	[model getDataFromMorca];
	[detectorView updateSNODetectorView];
}

- (void) setXl3PollingAction:(id)sender
{
	[model setXl3Polling:[[sender selectedItem] tag]];
}

- (void) startXl3PollingAction:(id)sender
{
	[model startXl3Polling];
}

- (void) stopXl3PollingAction:(id)sender
{
	[model stopXl3Polling];
}

//slow control actions
- (IBAction) setSlowControlPollingAction:(id)sender
{
	[model setSlowControlPolling:[[sender selectedItem] tag]];
}

- (IBAction) startSlowControlPollingAction:(id)sender
{
	[model startSlowControlPolling];
}

- (IBAction) stopSlowControlPollingAction:(id)sender
{
	[model stopSlowControlPolling];
}

- (IBAction) connectToIOServerAction:(id)sender
{
	[model connectToIOServer];
}

- (IBAction) setSlowControlParameterThresholdsAction:(id)sender
{
	[model setSlowControlParameterThresholds];
}

- (IBAction) setSlowControlChannelGainAction:(id)sender
{
	[model setSlowControlChannelGain];
}

- (IBAction) enableSlowControlParameterAction:(id)sender
{
	[model enableSlowControlParameter];
}

- (IBAction) setSlowControlMappingAction:(id)sender
{
	[model setSlowControlMapping];
}

#pragma mark •••Interface Management
- (void) updateWindow
{
    [super updateWindow];
    //[self colorAttributesChanged:nil];
}
/*
- (void) colorAttributesChanged:(NSNotification*)aNote
{        
	[[detectorColorBar colorAxis] setAttributes:[model colorBarAttributes]];
	[detectorColorBar setNeedsDisplay:YES];
	[[detectorColorBar colorAxis]setNeedsDisplay:YES];
	
	BOOL state = [[[model colorBarAttributes] objectForKey:ORAxisUseLog] boolValue];
	[colorBarLogCB setState:state];
}*/

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	float toolBarOffset = 0;
	BOOL toolBarVisible = [[monitorWindow toolbar] isVisible];
	if(toolBarVisible){
		switch([[monitorWindow toolbar] sizeMode]){
			case NSToolbarSizeModeRegular:	toolBarOffset = 60; break;
			case NSToolbarSizeModeSmall:	toolBarOffset = 50; break;
			default:						toolBarOffset = 60; break;
		}
	}
	if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[monitorWindow setContentView:blankView];
		NSSize newSize = detectorSize;
		//newSize.height += toolBarOffset;
		[monitorWindow setContentSize:newSize];
		//[self resizeWindowToSize:newSize];
		[monitorWindow setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[monitorWindow setContentView:blankView];
		NSSize newSize = slowControlSize;
		//newSize.height += toolBarOffset;
		[monitorWindow setContentSize:newSize];
		//[self resizeWindowToSize:newSize];
		[monitorWindow setContentView:tabView];
    }
//	int index = [tabView indexOfTabViewItem:tabViewItem];
//   [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.SNOController.selectedtab"];
}

- (void) selectionStringChanged:(NSNotification*)aNote
{
	[selectionStringTextView setString:[detectorView selectionString]];
}

- (void) slowControlTableChanged:(NSNotification*)aNote
{
	[slowControlParameterTable reloadData];
}

- (void) slowControlConnectionStatusChanged:(NSNotification*)aNote
{
	[slowControlMonitorStatus setStringValue:[model getSlowControlMonitorStatusString]];
	[slowControlMonitorStatus setTextColor:[model getSlowControlMonitorStatusStringColor]];
}

- (void) morcaDBRead:(NSNotification*)aNote
{
	[detectorView updateSNODetectorView];
}

#pragma mark •••Table Data Source
//- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
//{
//	return ![gSecurity isLocked:[model experimentMapLock]];;
//}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
//	NSLog(@"%@\n",[[tableEntries objectAtIndex:rowIndex] valueForKey:[aTableColumn identifier]]);
	NSString *columnName = [aTableColumn identifier];
	if ([columnName isEqualToString:@"parameterSelected"]){
	    //return [[tableEntries objectAtIndex:rowIndex] valueForKey:columnName];
		BOOL isSelected = [[[model getSlowControlVariable:rowIndex] valueForKey:columnName] boolValue];
		return [NSNumber numberWithInteger:(isSelected ? NSOnState : NSOffState)];
	}else {
		return [[model getSlowControlVariable:rowIndex] valueForKey:columnName];
	}
}

- (void) tableView:(NSTableView*)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *status = [[model getSlowControlVariable:rowIndex] parameterStatus];
	NSString *columnName = [aTableColumn identifier];
						
	if ([[model getSlowControlVariable:rowIndex] isSlowControlParameterChanged] &&
		![columnName isEqualToString:@"parameterSelected"]) {
		[aCell setTextColor:[NSColor redColor]];
	} else if ([columnName isEqualToString:@"parameterStatus"]) {
		if ([status isEqualToString:@"LoLo"] || [status isEqualToString:@"HiHi"]) {
			[aCell setTextColor:[NSColor redColor]];
		}else if ([status isEqualToString:@"Hi"] || [status isEqualToString:@"Lo"]) {
			[aCell setTextColor:[NSColor orangeColor]];
		}else if ([status isEqualToString:@"OK"]) {
			[aCell setTextColor:[NSColor greenColor]];
		}else{
			[aCell setTextColor:[NSColor blackColor]];
		}
	}else if ([columnName isEqualToString:@"parameterSelected"]){
	}else{
		[aCell setTextColor:[NSColor blackColor]];
	}
		
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return kNumSlowControlParameters;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{	
	NSString *columnName = [aTableColumn identifier];
	SNOSlowControl *slowControlVariable=[model getSlowControlVariable:rowIndex];
	
	if ([columnName isEqualToString:@"parameterName"]) {
		[slowControlVariable setParameterName:anObject];
	}else if ([columnName isEqualToString:@"parameterLoThreshold"]){
		if ([slowControlVariable parameterLoThreshold] != [anObject floatValue]) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}		
		[slowControlVariable setLoThresh:[anObject floatValue]];
	}else if ([columnName isEqualToString:@"parameterHiThreshold"]) {
		if ([slowControlVariable parameterHiThreshold] != [anObject floatValue]) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}
		[slowControlVariable setHiThresh:[anObject floatValue]];
	}else if ([columnName isEqualToString:@"parameterLoLoThreshold"]){
		if ([slowControlVariable parameterLoLoThreshold] != [anObject floatValue]) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}		
		[slowControlVariable setLoLoThresh:[anObject floatValue]];
	}else if ([columnName isEqualToString:@"parameterHiHiThreshold"]) {
		if ([slowControlVariable parameterHiHiThreshold] != [anObject floatValue]) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}		
		[slowControlVariable setHiHiThresh:[anObject floatValue]];		
	}else if ([columnName isEqualToString:@"parameterGain"]) {
		if ([slowControlVariable parameterGain] != [anObject floatValue]) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}		
		[slowControlVariable setChannelGain:[anObject floatValue]];
	}else if ([columnName isEqualToString:@"parameterCard"]) {
		if ([slowControlVariable parameterCard] != anObject) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}	
		[slowControlVariable setCardName:anObject];
	}else if ([columnName isEqualToString:@"parameterChannel"]) {
		if ([slowControlVariable parameterChannel] != [anObject intValue]) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}	
		[slowControlVariable setChannelNumber:[anObject intValue]];
	}else if ([columnName isEqualToString:@"parameterSelected"]){
		[slowControlVariable setSelected:[anObject boolValue]];
	}
}

- (void) tableView:(NSTableView*)aTableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	BOOL AllSelected=YES;
	
	int i;
	for(i=0;i<kNumSlowControlParameters;++i){
		if (![[model getSlowControlVariable:i] parameterSelected]) {
			AllSelected=NO;
			break;
		}
	}
	
	//NSString *columnName = [tableColumn identifier];
	if (AllSelected) {
		for(i=0;i<kNumSlowControlParameters;++i){
			[[model getSlowControlVariable:i] setSelected:NO];
		}
	}else if (!AllSelected) {
		for(i=0;i<kNumSlowControlParameters;++i){
			[[model getSlowControlVariable:i] setSelected:YES];
		}
	}
	
	[slowControlParameterTable reloadData];
}

@end