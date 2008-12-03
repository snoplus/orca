/*
 *  ORJAMFModelController.cpp
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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
#import "ORJAMFController.h"
#import "ORCamacExceptions.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORTimeRate.h"

// methods
@implementation ORJAMFController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"JAMF"];
	
    return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
    [[plotter0 yScale] setRngLow:-12.0 withHigh:12.];
	[[plotter0 yScale] setRngLimitsLow:-12.0 withHigh:12 withMinRng:4];
    [[plotter1 yScale] setRngLow:-12.0 withHigh:12.];
	[[plotter1 yScale] setRngLimitsLow:-12.0 withHigh:12 withMinRng:4];
    [[plotter2 yScale] setRngLow:-12.0 withHigh:12.];
	[[plotter2 yScale] setRngLimitsLow:-12.0 withHigh:12 withMinRng:4];
    [[plotter3 yScale] setRngLow:-12.0 withHigh:12.];
	[[plotter3 yScale] setRngLimitsLow:-12.0 withHigh:12 withMinRng:4];
	
	
    [[plotter0 xScale] setRngLow:0.0 withHigh:10000];
	[[plotter0 xScale] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[plotter1 xScale] setRngLow:0.0 withHigh:10000];
	[[plotter1 xScale] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[plotter2 xScale] setRngLow:0.0 withHigh:10000];
	[[plotter2 xScale] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[plotter3 xScale] setRngLow:0.0 withHigh:10000];
	[[plotter3 xScale] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
	
	[plotter0 setUseGradient:YES];
	[plotter1 setUseGradient:YES];
	[plotter2 setUseGradient:YES];
	[plotter3 setUseGradient:YES];
}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORCamacCardSlotChangedNotification
                       object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORJAMFSettingsLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : ORJAMFModelEnabledMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(alarmsEnabledMaskChanged:)
                         name : ORJAMFModelAlarmsEnabledMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(lowLimitChanged:)
                         name : ORJAMFModelLowLimitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(highLimitChanged:)
                         name : ORJAMFModelHighLimitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(adcValueChanged:)
                         name : ORJAMFModelAdcValueChanged
						object: model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(rangeIndexChanged:)
                         name : ORJAMFModelRangeIndexChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(lastReadChanged:)
                         name : ORJAMFModelLastReadChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollingStateChanged:)
                         name : ORJAMFModelPollingStateChanged
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(updateTimePlot:)
						 name : ORRateAverageChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(scanLimitChanged:)
                         name : ORJAMFModelScanLimitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(scanEnabledChanged:)
                         name : ORJAMFModelScanEnabledChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(shipRecordsChanged:)
                         name : ORJAMFModelShipRecordsChanged
						object: model];
	
}

#pragma mark •••Interface Management

- (void) shipRecordsChanged:(NSNotification*)aNote
{
	[shipRecordsButton setIntValue: [model shipRecords]];
}

- (void) scanEnabledChanged:(NSNotification*)aNote
{
	[scanEnabledCB setIntValue: [model scanEnabled]];
}

- (void) scanLimitChanged:(NSNotification*)aNote
{
	[scanLimitMatrix selectCellWithTag:[model scanLimit]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self enabledMaskChanged:nil];
	[self alarmsEnabledMaskChanged:nil];
	[self highLimitChanged:nil];
	[self lowLimitChanged:nil];
	[self adcValueChanged:nil];
	[self rangeIndexChanged:nil];
	[self lastReadChanged:nil];
	[self pollingStateChanged:nil];
	[self updateTimePlot:nil];
    [self miscAttributesChanged:nil];
	[self scanLimitChanged:nil];
	[self scanEnabledChanged:nil];
	[self shipRecordsChanged:nil];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter0 xScale]){
		[model setMiscAttributes:[[plotter0 xScale]attributes] forKey:@"XAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter0 yScale]){
		[model setMiscAttributes:[[plotter0 yScale]attributes] forKey:@"YAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter1 xScale]){
		[model setMiscAttributes:[[plotter1 xScale]attributes] forKey:@"XAttributes1"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter1 yScale]){
		[model setMiscAttributes:[[plotter1 yScale]attributes] forKey:@"YAttributes1"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter2 xScale]){
		[model setMiscAttributes:[[plotter2 xScale]attributes] forKey:@"XAttributes2"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter2 yScale]){
		[model setMiscAttributes:[[plotter2 yScale]attributes] forKey:@"YAttributes2"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter3 xScale]){
		[model setMiscAttributes:[[plotter3 xScale]attributes] forKey:@"XAttributes3"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter3 yScale]){
		[model setMiscAttributes:[[plotter3 yScale]attributes] forKey:@"YAttributes3"];
	};
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
		if(attrib){
			[[plotter0 xScale] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
		if(attrib){
			[[plotter0 yScale] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 yScale] setNeedsDisplay:YES];
		}
	}
	
	if(aNote == nil || [key isEqualToString:@"XAttributes1"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes1"];
		if(attrib){
			[[plotter1 xScale] setAttributes:attrib];
			[plotter1 setNeedsDisplay:YES];
			[[plotter1 xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes1"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes1"];
		if(attrib){
			[[plotter1 yScale] setAttributes:attrib];
			[plotter1 setNeedsDisplay:YES];
			[[plotter1 yScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"XAttributes2"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes2"];
		if(attrib){
			[[plotter2 xScale] setAttributes:attrib];
			[plotter2 setNeedsDisplay:YES];
			[[plotter2 xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes2"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes2"];
		if(attrib){
			[[plotter2 yScale] setAttributes:attrib];
			[plotter2 setNeedsDisplay:YES];
			[[plotter2 yScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"XAttributes3"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes3"];
		if(attrib){
			[[plotter3 xScale] setAttributes:attrib];
			[plotter3 setNeedsDisplay:YES];
			[[plotter3 xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes3"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes3"];
		if(attrib){
			[[plotter3 yScale] setAttributes:attrib];
			[plotter3 setNeedsDisplay:YES];
			[[plotter3 yScale] setNeedsDisplay:YES];
		}
	}
}

- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [model timeRate:0])){
		[plotter0 setNeedsDisplay:YES];
	}
	else if(!aNote || ([aNote object] == [model timeRate:1])){
		[plotter1 setNeedsDisplay:YES];
	}
	else if(!aNote || ([aNote object] == [model timeRate:2])){
		[plotter2 setNeedsDisplay:YES];
	}
	else if(!aNote || ([aNote object] == [model timeRate:3])){
		[plotter3 setNeedsDisplay:YES];
	}
	
}

- (void) pollingStateChanged:(NSNotification*)aNote
{
	[pollingStatePopup selectItemWithTag: [model pollingState]];
}

- (void) lastReadChanged:(NSNotification*)aNote
{
	[lastReadTextField setStringValue: [model lastRead]];
}

- (void) rangeIndexChanged:(NSNotification*)aNote
{
	[rangeIndexPopup0 selectItemAtIndex: [model rangeIndex:0]];
	[rangeIndexPopup1 selectItemAtIndex: [model rangeIndex:1]];
	[rangeIndexPopup2 selectItemAtIndex: [model rangeIndex:2]];
	[rangeIndexPopup3 selectItemAtIndex: [model rangeIndex:3]];
	[rangeIndexPopup4 selectItemAtIndex: [model rangeIndex:4]];
	[rangeIndexPopup5 selectItemAtIndex: [model rangeIndex:5]];
	[rangeIndexPopup6 selectItemAtIndex: [model rangeIndex:6]];
	[rangeIndexPopup7 selectItemAtIndex: [model rangeIndex:7]];
	[rangeIndexPopup8 selectItemAtIndex: [model rangeIndex:8]];
	[rangeIndexPopup9 selectItemAtIndex: [model rangeIndex:9]];
	[rangeIndexPopup10 selectItemAtIndex: [model rangeIndex:10]];
	[rangeIndexPopup11 selectItemAtIndex: [model rangeIndex:11]];
	[rangeIndexPopup12 selectItemAtIndex: [model rangeIndex:12]];
	[rangeIndexPopup13 selectItemAtIndex: [model rangeIndex:13]];
	[rangeIndexPopup14 selectItemAtIndex: [model rangeIndex:14]];
	[rangeIndexPopup15 selectItemAtIndex: [model rangeIndex:15]];
}

- (void) lowLimitChanged:(NSNotification*)aNote
{
	if(aNote == nil){
		int i;
		for(i=0;i<16;i++)[[lowLimitsMatrix cellWithTag:i] setFloatValue: [model lowLimit:i]];
		
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:ORJAMFChan] intValue];
		[[lowLimitsMatrix cellWithTag:chan] setFloatValue: [model lowLimit:chan]];
	}
}

- (void) highLimitChanged:(NSNotification*)aNote
{
	if(aNote == nil){
		int i;
		for(i=0;i<16;i++)[[highLimitsMatrix cellWithTag:i] setFloatValue: [model highLimit:i]];
		
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:ORJAMFChan] intValue];
		[[highLimitsMatrix cellWithTag:chan] setFloatValue: [model highLimit:chan]];
	}
}

- (void) adcValueChanged:(NSNotification*)aNote
{
	if(aNote == nil){
		int i;
		for(i=0;i<16;i++){
			[[adcValueMatrix cellWithTag:i] setFloatValue: [model adcValue:i]];
			[[adcValueMatrix cellWithTag:i] setTextColor:[NSColor blackColor]];
		}
		
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:ORJAMFChan] intValue];
		[[adcValueMatrix cellWithTag:chan] setFloatValue: [model adcValue:chan]];
		int range = [model adcRange:chan];
		NSColor* theColor = [NSColor blackColor];
		if(range == kAdcFRangeLow || range == kAdcFRangeHigh)theColor = [NSColor colorWithCalibratedRed:.5 green:0 blue:0 alpha:1];
		[[adcValueMatrix cellWithTag:chan] setTextColor:theColor];
	}
}

- (void) enabledMaskChanged:(NSNotification*)aNote
{
	unsigned short theMask = [model enabledMask];
	int i;
	for(i=0;i<16;i++){
		[[enabledMaskMatrix cellWithTag:i] setState: (theMask & (1<<i))!=0];
	}
}
- (void) alarmsEnabledMaskChanged:(NSNotification*)aNote
{
	unsigned short theMask = [model alarmsEnabledMask];
	int i;
	for(i=0;i<16;i++){
		[[alarmsEnabledMaskMatrix cellWithTag:i] setState: (theMask & (1<<i))!=0];
	}
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORJAMFSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORJAMFSettingsLock];
    BOOL locked = [gSecurity isLocked:ORJAMFSettingsLock];
	
    [settingLockButton setState: locked];
	[lowLimitsMatrix setEnabled:!lockedOrRunningMaintenance];
	[highLimitsMatrix setEnabled:!lockedOrRunningMaintenance];
	[enabledMaskMatrix setEnabled:!lockedOrRunningMaintenance];
	[alarmsEnabledMaskMatrix setEnabled:!lockedOrRunningMaintenance];
	[initButton setEnabled:!lockedOrRunningMaintenance];
	[readIdButton setEnabled:!lockedOrRunningMaintenance];
	[scanLimitMatrix setEnabled:!lockedOrRunningMaintenance];
	[scanEnabledCB setEnabled:!lockedOrRunningMaintenance];
	[shipRecordsButton setEnabled:!locked];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORJAMFSettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	
}


- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"JAMF (Station %d)",[model stationNumber]]];
}

#pragma mark •••Actions

- (void) shipRecordsAction:(id)sender
{
	[model setShipRecords:[sender intValue]];	
}

- (void) scanEnabledAction:(id)sender
{
	[model setScanEnabled:[sender intValue]];	
}

- (void) scanLimitAction:(id)sender
{
	int tag = [[sender selectedCell] tag];
	[model setScanLimit:tag];	
}

- (void) pollingStatePopupAction:(id)sender
{
	[model setPollingState:[[sender selectedItem]tag]]; 
}

- (void) rangeIndexPopupAction:(id)sender
{
	[model setRangeIndex:[sender tag] withValue:[sender indexOfSelectedItem]];	
}

- (void) enabledMaskMatrixAction:(id)sender
{
	unsigned short theMask = [model enabledMask];
	int tag = [[sender selectedCell] tag];
	if(![sender intValue]) theMask &= ~(1<<tag);
	else theMask |= (1<<tag);
	[model setEnabledMask:theMask];	
}

- (void) alarmsEnabledMaskMatrixAction:(id)sender
{
	unsigned short theMask = [model alarmsEnabledMask];
	int tag = [[sender selectedCell] tag];
	if(![sender intValue]) theMask &= ~(1<<tag);
	else theMask |= (1<<tag);
	[model setAlarmsEnabledMask:theMask];	
}

-(IBAction) lowLimitsMatrixAction:(id)sender
{
	if([sender floatValue] != [model lowLimit:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set LowLimit"];
		[model setLowLimit:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

-(IBAction) highLimitsMatrixAction:(id)sender
{
	if([sender floatValue] != [model highLimit:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set HighLimit"];
		[model setHighLimit:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORJAMFSettingsLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) initAction:(id)sender
{
    @try {
		[self endEditing];
        [model checkCratePower];
        [model initBoard];
	}
	@catch(NSException* localException) {
        [self showError:localException name:@"InitBoard"];
    }
}

- (IBAction) readAdcsAction:(id)sender
{
    @try {
		[self endEditing];
        [model checkCratePower];
        [model readAdcs:YES];
	}
	@catch(NSException* localException) {
        [self showError:localException name:@"Read Adcs"];
    }
}

- (IBAction) readID:(id) sender
{
    @try {
        [model checkCratePower];
        unsigned short anID = [model readBoardID];
		char boardID[9];
		char* p = (char*)&anID;
		strncpy(boardID,p,8);
		boardID[8] = '\0';
		NSLog(@"JAM-F ID: %s\n",boardID);
	}
	@catch(NSException* localException) {
        [self showError:localException name:@"Read ID"];
    }
}

- (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i
{
    NSLog(@"Failed Cmd: %@ (F%d)\n",name,i);
    if([[anException name] isEqualToString: OExceptionNoCamacCratePower]) {
        [[model crate]  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@ (F%d)",name,i]];
    }
    else {
        NSRunAlertPanel([anException name], @"%@\n%@ (F%d)", @"OK", nil, nil,
                        [anException name],name,i);
    }
}

- (void) showError:(NSException*)anException name:(NSString*)name
{
    NSLog(@"Failed Cmd: %@\n",name);
    if([[anException name] isEqualToString: OExceptionNoCamacCratePower]) {
        [[model crate]  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@",name]];
    }
    else {
        NSRunAlertPanel([anException name], @"%@\n%@", @"OK", nil, nil,
                        [anException name],name);
    }
}


#pragma mark •••Data Source
- (int) numberOfDataSetsInPlot:(id)aPlotter
{
    return 4;
}

- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	if(aPlotter == plotter0) return [[model timeRate:set] count];
	else if(aPlotter == plotter1) return [[model timeRate:set+4] count];
	else if(aPlotter == plotter2) return [[model timeRate:set+8] count];
	else if(aPlotter == plotter3) return [[model timeRate:set+12] count];
	else return 0;
}
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
	if(aPlotter == plotter0){
		int count = [[model timeRate:set] count];
		return [[model timeRate:set] valueAtIndex:count-x-1];
	}
	else if(aPlotter == plotter1){
		int count = [[model timeRate:set+4] count];
		return [[model timeRate:set+4] valueAtIndex:count-x-1];
	}
	else if(aPlotter == plotter2){
		int count = [[model timeRate:set+8] count];
		return [[model timeRate:set+8] valueAtIndex:count-x-1];
	}
	else if(aPlotter == plotter3){
		int count = [[model timeRate:set+12] count];
		return [[model timeRate:set+12] valueAtIndex:count-x-1];
	}
	else return 0;
}

- (unsigned long)  	secondsPerUnit:(id) aPlotter
{
	return [[model timeRate:0] sampleTime]; //all should be the same, just return value for rate 0
}

@end



