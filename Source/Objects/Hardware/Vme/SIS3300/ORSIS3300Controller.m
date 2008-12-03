//-------------------------------------------------------------------------
//  ORSIS3300Controller.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
#import <Cocoa/Cocoa.h>
#import "ORSIS3300Controller.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORValueBar.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORTimeRate.h"
#import "ORRate.h"

@implementation ORSIS3300Controller

-(id)init
{
    self = [super initWithWindowNibName:@"SIS3300"];
    
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
	
    settingSize     = NSMakeSize(790,460);
    rateSize		= NSMakeSize(790,300);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
	
    NSString* key = [NSString stringWithFormat: @"orca.SIS3300%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	[super awakeFromNib];
	
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(baseAddressChanged:)
                         name : ORVmeIOCardBaseAddressChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORSIS3300SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORSIS3300RateGroupChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
    //a fake action for the scale objects
    [notifyCenter addObserver : self
                     selector : @selector(scaleAction:)
                         name : ORAxisRangeChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateTimePlot:)
                         name : ORRateAverageChangedNotification
                       object : [[model waveFormRateGroup]timeRate]];
    
    [notifyCenter addObserver : self
                     selector : @selector(integrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledChanged:)
                         name : ORSIS3300ModelEnabledChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ltGtChanged:)
                         name : ORSIS3300ModelLtGtChanged
                       object : model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(thresholdChanged:)
                         name : ORSIS3300ModelThresholdChanged
                       object : model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : ORSIS3300ModelPageSizeChanged
						object: model];
	
    [self registerRates];
    [notifyCenter addObserver : self
                     selector : @selector(stopDelayChanged:)
                         name : ORSIS3300ModelStopDelayChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORSIS3300ModelClockSourceChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(startDelayChanged:)
                         name : ORSIS3300ModelStartDelayChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stopDelayChanged:)
                         name : ORSIS3300ModelStopDelayChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stopDelayEnabledChanged:)
                         name : ORSIS3300ModelStopDelayEnabledChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(startDelayEnabledChanged:)
                         name : ORSIS3300ModelStartDelayEnabledChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(gateModeChanged:)
                         name : ORSIS3300ModelGateModeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(randomClockChanged:)
                         name : ORSIS3300ModelRandomClockChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(lemoStartStopChanged:)
                         name : ORSIS3300ModelLemoStartStopChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(p2StartStopChanged:)
                         name : ORSIS3300ModelP2StartStopChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stopTriggerChanged:)
                         name : ORSIS3300ModelStopTriggerChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pageWrapChanged:)
                         name : ORSIS3300ModelPageWrapChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(multiEventModeChanged:)
                         name : ORSIS3300ModelMultiEventModeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(autoStartChanged:)
                         name : ORSIS3300ModelAutoStartChanged
						object: model];
	
}

- (void) registerRates
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self name:ORRateChangedNotification object:nil];
    
    NSEnumerator* e = [[[model waveFormRateGroup] rates] objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
		
        [notifyCenter removeObserver:self name:ORRateChangedNotification object:obj];
		
        [notifyCenter addObserver : self
                         selector : @selector(waveFormRateChanged:)
                             name : ORRateChangedNotification
                           object : obj];
    }
}


- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self enabledChanged:nil];
	[self ltGtChanged:nil];
	[self thresholdChanged:nil];
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
    [self waveFormRateChanged:nil];
	[self pageSizeChanged:nil];
	[self stopDelayChanged:nil];
	[self clockSourceChanged:nil];
	[self startDelayChanged:nil];
	[self stopDelayChanged:nil];
	[self stopDelayEnabledChanged:nil];
	[self startDelayEnabledChanged:nil];
	[self gateModeChanged:nil];
	[self randomClockChanged:nil];
	[self lemoStartStopChanged:nil];
	[self p2StartStopChanged:nil];
	[self stopTriggerChanged:nil];
	[self pageWrapChanged:nil];
	[self multiEventModeChanged:nil];
	[self autoStartChanged:nil];
}

#pragma mark •••Interface Management

- (void) autoStartChanged:(NSNotification*)aNote
{
	[autoStartButton setIntValue: [model autoStart]];
}

- (void) multiEventModeChanged:(NSNotification*)aNote
{
	[multiEventModeButton setIntValue: [model multiEventMode]];
}

- (void) pageWrapChanged:(NSNotification*)aNote
{
	[pageWrapButton setIntValue: [model pageWrap]];
}

- (void) stopTriggerChanged:(NSNotification*)aNote
{
	[stopTriggerButton setIntValue: [model stopTrigger]];
}

- (void) p2StartStopChanged:(NSNotification*)aNote
{
	[p2StartStopButton setIntValue: [model p2StartStop]];
}

- (void) lemoStartStopChanged:(NSNotification*)aNote
{
	[lemoStartStopButton setIntValue: [model lemoStartStop]];
}

- (void) randomClockChanged:(NSNotification*)aNote
{
	[randomClockButton setIntValue: [model randomClock]];
}

- (void) gateModeChanged:(NSNotification*)aNote
{
	[gateModeButton setIntValue: [model gateMode]];
}

- (void) startDelayEnabledChanged:(NSNotification*)aNote
{
	[startDelayEnabledButton setIntValue: [model startDelayEnabled]];
}

- (void) stopDelayEnabledChanged:(NSNotification*)aNote
{
	[stopDelayEnabledButton setIntValue: [model stopDelayEnabled]];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
	[clockSourcePU selectItemAtIndex: [model clockSource]];
}

- (void) startDelayChanged:(NSNotification*)aNote
{
	[startDelayField setIntValue: [model startDelay]];
}

- (void) stopDelayChanged:(NSNotification*)aNote
{
	[stopDelayField setIntValue: [model stopDelay]];
}

- (void) pageSizeChanged:(NSNotification*)aNote
{
	[pageSizePU selectItemAtIndex: [model pageSize]];
}

- (void) enabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3300Channels;i++){
		[[enabledMatrix cellWithTag:i] setState:[model enabled:i]];
		[[enabled2Matrix cellWithTag:i] setState:[model enabled:i]];
	}
}

- (void) ltGtChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3300Channels;i++){
		[[ltGtMatrix cellWithTag:i] setState:[model ltGt:i]];
	}
}

- (void) thresholdChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3300Channels;i++){
		[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
	}
}


- (void) waveFormRateChanged:(NSNotification*)aNote
{
    ORRate* theRateObj = [aNote object];		
    [[rateTextFields cellWithTag:[theRateObj tag]] setFloatValue: [theRateObj rate]];
    [rate0 setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNotification
{
	ORRateGroup* theRateObj = [aNotification object];
	if(aNotification == nil || [model waveFormRateGroup] == theRateObj){
		
		[totalRateText setFloatValue: [theRateObj totalRate]];
		[totalRate setNeedsDisplay:YES];
	}
}

- (void) rateGroupChanged:(NSNotification*)aNote
{
    [self registerRates];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORSIS3300SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSIS3300SettingsLock];
    BOOL locked = [gSecurity isLocked:ORSIS3300SettingsLock];
    
    [settingLockButton setState: locked];
	
    [addressText			setEnabled:!locked && !runInProgress];
    [initButton				setEnabled:!lockedOrRunningMaintenance];
	[enabledMatrix			setEnabled:!lockedOrRunningMaintenance];
	[ltGtMatrix				setEnabled:!lockedOrRunningMaintenance];
	[thresholdMatrix		setEnabled:!lockedOrRunningMaintenance];
	
	[autoStartButton		setEnabled:!lockedOrRunningMaintenance];
	[multiEventModeButton	setEnabled:!lockedOrRunningMaintenance];
	[pageWrapButton			setEnabled:!lockedOrRunningMaintenance];
	[stopTriggerButton		setEnabled:!lockedOrRunningMaintenance];
	[p2StartStopButton		setEnabled:!lockedOrRunningMaintenance];
	[lemoStartStopButton	setEnabled:!lockedOrRunningMaintenance];
	[randomClockButton		setEnabled:!lockedOrRunningMaintenance];
	[gateModeButton			setEnabled:!lockedOrRunningMaintenance];
	[startDelayEnabledButton setEnabled:!lockedOrRunningMaintenance];
	[stopDelayEnabledButton setEnabled:!lockedOrRunningMaintenance];
	[startDelayField		setEnabled:!lockedOrRunningMaintenance];
	[clockSourcePU			setEnabled:!lockedOrRunningMaintenance];
	[stopDelayField			setEnabled:!lockedOrRunningMaintenance];
	[pageSizePU				setEnabled:!lockedOrRunningMaintenance];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3300 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3300 Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
    [addressText setIntValue: [model baseAddress]];
}

- (void) integrationChanged:(NSNotification*)aNotification
{
    ORRateGroup* theRateGroup = [aNotification object];
    if(aNotification == nil || [model waveFormRateGroup] == theRateGroup || [aNotification object] == model){
        double dValue = [[model waveFormRateGroup] integrationTime];
        [integrationStepper setDoubleValue:dValue];
        [integrationText setDoubleValue: dValue];
    }
}


- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [rate0 xScale]){
		[model setMiscAttributes:[[rate0 xScale]attributes] forKey:@"RateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [totalRate xScale]){
		[model setMiscAttributes:[[totalRate xScale]attributes] forKey:@"TotalRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot xScale]){
		[model setMiscAttributes:[[timeRatePlot xScale]attributes] forKey:@"TimeRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot yScale]){
		[model setMiscAttributes:[[timeRatePlot yScale]attributes] forKey:@"TimeRateYAttributes"];
	};
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"RateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"RateXAttributes"];
		if(attrib){
			[[rate0 xScale] setAttributes:attrib];
			[rate0 setNeedsDisplay:YES];
			[[rate0 xScale] setNeedsDisplay:YES];
			[rateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TotalRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TotalRateXAttributes"];
		if(attrib){
			[[totalRate xScale] setAttributes:attrib];
			[totalRate setNeedsDisplay:YES];
			[[totalRate xScale] setNeedsDisplay:YES];
			[totalRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateXAttributes"];
		if(attrib){
			[[timeRatePlot xScale] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateYAttributes"];
		if(attrib){
			[[timeRatePlot yScale] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot yScale] setNeedsDisplay:YES];
			[timeRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
}


- (void) updateTimePlot:(NSNotification*)aNote
{
    if(!aNote || ([aNote object] == [[model waveFormRateGroup]timeRate])){
        [timeRatePlot setNeedsDisplay:YES];
    }
}

#pragma mark •••Actions

- (void) autoStartAction:(id)sender
{
	[model setAutoStart:[sender intValue]];	
}

- (void) multiEventModeAction:(id)sender
{
	[model setMultiEventMode:[sender intValue]];	
}

- (void) pageWrapAction:(id)sender
{
	[model setPageWrap:[sender intValue]];	
}

- (void) stopTriggerAction:(id)sender
{
	[model setStopTrigger:[sender intValue]];	
}

- (void) p2StartStopAction:(id)sender
{
	[model setP2StartStop:[sender intValue]];	
}

- (void) lemoStartStopAction:(id)sender
{
	[model setLemoStartStop:[sender intValue]];	
}

- (void) randomClockAction:(id)sender
{
	[model setRandomClock:[sender intValue]];	
}

- (void) gateModeAction:(id)sender
{
	[model setGateMode:[sender intValue]];	
}

- (void) startDelayEnabledAction:(id)sender
{
	[model setStartDelayEnabled:[sender intValue]];	
}

- (void) stopDelayEnabledAction:(id)sender
{
	[model setStopDelayEnabled:[sender intValue]];	
}


- (void) startDelayAction:(id)sender
{
	[model setStartDelay:[sender intValue]];	
}

- (void) clockSourceAction:(id)sender
{
	[model setClockSource:[sender indexOfSelectedItem]];	
}

- (void) stopDelayAction:(id)sender
{
	[model setStopDelay:[sender intValue]];	
}

- (void) pageSizeAction:(id)sender
{
	[model setPageSize:[sender indexOfSelectedItem]];	
}

- (IBAction) enabledAction:(id)sender
{
	[model setEnabledBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) ltGtAction:(id)sender
{
	[model setLtGtBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) thresholdAction:(id)sender
{
	if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

-(IBAction)baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORSIS3300SettingsLock to:[sender intValue] forWindow:[self window]];
}


-(IBAction)initBoard:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardward
        NSLog(@"Initialized SIS3300 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset and Init of SIS3300 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed SIS3300 Reset and Init", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model waveFormRateGroup]integrationTime]){
        [model setRateIntegrationTime:[sender doubleValue]];		
    }
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:rateSize];
		[[self window] setContentView:tabView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.ORSIS3300%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}


#pragma mark •••Data Source

- (double) getBarValue:(int)tag
{
	
	return [[[[model waveFormRateGroup]rates] objectAtIndex:tag] rate];
}

- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	return [[[model waveFormRateGroup]timeRate]count];
}

- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
	if(set == 0){
		int count = [[[model waveFormRateGroup]timeRate] count];
		return [[[model waveFormRateGroup]timeRate]valueAtIndex:count-x-1];
	}
	return 0;
}

- (unsigned long)  	secondsPerUnit:(id) aPlotter
{
	return [[[model waveFormRateGroup]timeRate]sampleTime];
}

@end
