//
//  ORShaperController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 16 2002.
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


#import "ORShaperController.h"
#import "ORShaperModel.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORValueBar.h"
#import "ORAxis.h"
#import "ORPlotter1D.h"
#import "ORTimeRate.h"


@implementation ORShaperController

-(id)init
{
    self = [super initWithWindowNibName:@"Shaper"];
	
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    NSString* key = [NSString stringWithFormat: @"orca.ORShaper%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	[[rate0 xScale] setRngLimitsLow:0 withHigh:500000 withMinRng:128];
	[[totalRate xScale] setRngLimitsLow:0 withHigh:500000 withMinRng:128];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(thresholdArrayChanged:)
						 name : ORShaperThresholdArrayChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(gainArrayChanged:)
						 name : ORShaperGainArrayChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(baseAddressChanged:)
						 name : ORVmeIOCardBaseAddressChangedNotification
					   object : model];
	
	
    [notifyCenter addObserver : self
					 selector : @selector(thresholdChanged:)
						 name : ORShaperThresholdChangedNotification
					   object : model];
	
	
    [notifyCenter addObserver : self
					 selector : @selector(gainChanged:)
						 name : ORShaperGainChangedNotification
					   object : model];
	
	
    [notifyCenter addObserver : self
					 selector : @selector(continousChanged:)
						 name : ORShaperContinousChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(scalersEnabledChanged:)
						 name : ORShaperScalersEnabledChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(multiBoardEnabledChanged:)
						 name : ORShaperMultiBoardEnabledChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(scalerMaskChanged:)
						 name : ORShaperScalerMaskChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(onlineMaskChanged:)
						 name : ORShaperOnlineMaskChangedNotification
					   object : model];
	
	
    [notifyCenter addObserver : self
					 selector : @selector(scanStartChanged:)
						 name : ORShaperScanStartChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(scanDeltaChanged:)
						 name : ORShaperScanDeltaChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(scanNumberChanged:)
						 name : ORShaperScanNumChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(integrationChanged:)
						 name : ORRateGroupIntegrationChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(rateGroupChanged:)
						 name : ORShaperRateGroupChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
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
					 selector : @selector(updateTimePlot:)
						 name : ORRateAverageChangedNotification
					   object : [[model adcRateGroup]timeRate]];
	
    [notifyCenter addObserver : self
					 selector : @selector(displayRawChanged:)
						 name : ORShaperDisplayRawChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORShaperSettingsLock
						object: nil];
	
	
    [self registerRates];
}

- (void) registerRates
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[notifyCenter removeObserver:self name:ORRateChangedNotification object:nil];
	
	NSEnumerator* e = [[[model adcRateGroup] rates] objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		[notifyCenter addObserver : self
						 selector : @selector(adcRateChanged:)
							 name : ORRateChangedNotification
						   object : obj];
	}
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self thresholdArrayChanged:nil];
    [self gainArrayChanged:nil];
    [self continousChanged:nil];
    [self scalersEnabledChanged:nil];
    [self multiBoardEnabledChanged:nil];
    [self scalerMaskChanged:nil];
    [self onlineMaskChanged:nil];
	
    [self scanStartChanged:nil];
    [self scanDeltaChanged:nil];
    [self scanNumberChanged:nil];
	
    [self adcRateChanged:nil];
    [self totalRateChanged:nil];
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self updateTimePlot:nil];
    [self settingsLockChanged:nil];
	
    [self displayRawChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORShaperSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORShaperSettingsLock];
    BOOL locked = [gSecurity isLocked:ORShaperSettingsLock];
	
    [settingLockButton setState: locked];
    [addressStepper setEnabled:!locked && !runInProgress];
    [addressText setEnabled:!locked && !runInProgress];
    
    [continousModeCB setEnabled:!locked];
    [enableScalersCB setEnabled:!locked];
    [enableMultiBoardCB setEnabled:!locked];
	
    [initButton setEnabled:!lockedOrRunningMaintenance];
    [thresholdSteppers setEnabled:!locked];
    [thresholdTextFields setEnabled:!locked];
    [gainSteppers setEnabled:!locked];
    [gainTextFields setEnabled:!locked];
    [scalerMaskMatrix setEnabled:!locked];
    [online1MaskMatrix setEnabled:!lockedOrRunningMaintenance];
    [online2MaskMatrix setEnabled:!lockedOrRunningMaintenance];
	
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORShaperSettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	
}
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    NSString* key = [NSString stringWithFormat: @"orca.ORShaper%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"Shaper Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Shaper Card (Slot %d)",[model slot]]];
}


- (void) thresholdArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumShaperChannels;chan++){
		[self updateStepper:[thresholdSteppers cellWithTag:chan] setting:[model threshold:chan]];
		if([model displayRaw]){
			[[thresholdTextFields cellWithTag:chan] setIntValue: [model threshold:chan]];
		}
		else {
			[[thresholdTextFields cellWithTag:chan] setIntValue: [model thresholdmV:chan]];
		}
	}	
}

- (void) gainArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumShaperChannels;chan++){
		[self updateStepper:[gainSteppers cellWithTag:chan] setting:[model gain:chan]];
		[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];
	}
}


- (void) baseAddressChanged:(NSNotification*)aNotification
{
	[self updateStepper:addressStepper setting:[model baseAddress]];
	[addressText setIntValue: [model baseAddress]];
}

- (void) thresholdChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORShaperChan] intValue];
	[self updateStepper:[thresholdSteppers cellWithTag:chan] setting:[model threshold:chan]];
	if([model displayRaw]){
		[[thresholdTextFields cellWithTag:chan] setIntValue: [model threshold:chan]];
	}
	else {
		[[thresholdTextFields cellWithTag:chan] setIntValue: [model thresholdmV:chan]];
	}	
}



- (void) gainChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORShaperChan] intValue];
	[self updateStepper:[gainSteppers cellWithTag:chan] setting:[model gain:chan]];
	[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];
}


- (void) continousChanged:(NSNotification*)aNotification
{
	[self updateTwoStateCheckbox:continousModeCB setting:[model continous]];
}

- (void) scalersEnabledChanged:(NSNotification*)aNotification
{
	[self updateTwoStateCheckbox:enableScalersCB setting:[model scalersEnabled]];
}

- (void) multiBoardEnabledChanged:(NSNotification*)aNotification
{
	[self updateTwoStateCheckbox:enableMultiBoardCB setting:[model multiBoardEnabled]];
}

- (void) scalerMaskChanged:(NSNotification*)aNotification
{
	short i;
	unsigned char theMask = [model scalerMask];
	for(i=0;i<kNumShaperChannels;i++){
		BOOL bitSet = (theMask&(1<<i))>0;
		if(bitSet != [[scalerMaskMatrix cellWithTag:i] intValue]){
			[[scalerMaskMatrix cellWithTag:i] setState:bitSet];
		}
		
	}	
}

- (void) onlineMaskChanged:(NSNotification*)aNotification
{
	short i;
	unsigned char theMask = [model onlineMask];
	for(i=0;i<kNumShaperChannels;i++){
		BOOL bitSet = (theMask&(1<<i))>0;
		if(bitSet != [[online1MaskMatrix cellWithTag:i] intValue]){
			[[online1MaskMatrix cellWithTag:i] setState:bitSet];
		}
		if(bitSet != [[online2MaskMatrix cellWithTag:i] intValue]){
			[[online2MaskMatrix cellWithTag:i] setState:bitSet];
		}
	}
}

- (void) displayRawChanged:(NSNotification*)aNotification
{
	[self updateTwoStateCheckbox:displayRawCB setting:[model displayRaw]];
	[self thresholdArrayChanged:nil];
	if([model displayRaw]){
		[thresholdLabel setStringValue:@"(Raw)"];
	}
	else {
		[thresholdLabel setStringValue:@"(mV)"];
	}	
}


- (void) scanStartChanged:(NSNotification*)aNotification
{
	[scanStartField setIntValue: [model scanStart]];
}

- (void) scanDeltaChanged:(NSNotification*)aNotification
{
	[scanDeltaField setIntValue: [model scanDelta]];
}
- (void) scanNumberChanged:(NSNotification*)aNotification
{
	[scanNumberField setIntValue: [model scanNumber]];
}

- (void) adcRateChanged:(NSNotification*)aNotification
{
	ORRate* theRateObj = [aNotification object];		
	[[rateTextFields cellWithTag:[theRateObj tag]] setFloatValue: [theRateObj rate]];
	[rate0 setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNotification
{
	ORRateGroup* theRateObj = [aNotification object];
	if(aNotification == nil || [model adcRateGroup] == theRateObj){
		
		[totalRateText setFloatValue: [theRateObj totalRate]];
		[totalRate setNeedsDisplay:YES];
	}
}

- (void) rateGroupChanged:(NSNotification*)aNotification
{
	[self registerRates];
}

- (void) integrationChanged:(NSNotification*)aNotification
{
	ORRateGroup* theRateGroup = [aNotification object];
	if(aNotification == nil || [model adcRateGroup] == theRateGroup || [aNotification object] == model){
		double dValue = [[model adcRateGroup] integrationTime];
		[integrationStepper setDoubleValue:dValue];
		[integrationText setDoubleValue: dValue];
	}
}

- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [[model adcRateGroup]timeRate])){
		[timeRatePlot setNeedsDisplay:YES];
	}
}

//a fake action from the scale object
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

#pragma mark ¥¥¥Actions

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORShaperSettingsLock to:[sender intValue] forWindow:[self window]];
}

-(IBAction)baseAddressAction:(id)sender
{
	if([sender intValue] != [model baseAddress]){
		[[self undoManager] setActionName: @"Set Base Address"];
		[model setBaseAddress:[sender intValue]];		
	}
}

-(IBAction)continousAction:(id)sender
{
	if([sender intValue] != [model continous]){
		[[self undoManager] setActionName: @"Enable Continous"];
		[model setContinous:[sender intValue]];
	}
}


- (IBAction) scalersEnabledAction:(id)sender
{
	if([sender intValue] != [model scalersEnabled]){
		[[self undoManager] setActionName: @"Scalers Enabled"];
		[model setScalersEnabled:[sender intValue]];
	}
}

- (IBAction) mulitBoardEnabledAction:(id)sender
{
	if([sender intValue] != [model multiBoardEnabled]){
		[[self undoManager] setActionName: @"Enable MultiBoard"];
		[model setMultiBoardEnabled:[sender intValue]];
	}
}



-(IBAction) thresholdAction:(id)sender
{
	if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Threshold"];
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

-(IBAction) thresholdTextAction:(id)sender
{
	if([model displayRaw]){
		if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
			[[self undoManager] setActionName: @"Set Threshold (Raw)"];
			[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
		}
	}
	else {
		if([sender intValue] != [model thresholdmV:[[sender selectedCell] tag]]){
			[[self undoManager] setActionName: @"Set Threshold (mV)"];
			[model setThresholdmV:[[sender selectedCell] tag] withValue:[sender intValue]];
		}
	}
}


- (IBAction) gainAction:(id)sender
{
	if([sender intValue] != [model gain:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Gain"];
		[model setGain:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) scalerMaskAction:(id)sender
{
	if([sender intValue] != [model scalerMaskBit:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Scaler Mask"];
		[model setScalerMaskBit:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) onlineAction:(id)sender
{
	if([sender intValue] != [model onlineMaskBit:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Online Mask"];
		[model setOnlineMaskBit:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) displayRawAction:(id)sender
{
	if([sender intValue] != [model displayRaw]){
		[[self undoManager] setActionName: @"Display Raw"];
		[model setDisplayRaw:[sender intValue]];
	}
}


-(IBAction)initBoard:(id)sender
{
    NS_DURING
		[self endEditing];
        [model reset];		//initialize and load hardward
		NSLog(@"Initialized Shaper (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    NS_HANDLER
        NSLog(@"Reset and Init of Shaper FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed Shaper Reset and Init", @"OK", nil, nil,
                        localException);
    NS_ENDHANDLER
}

- (IBAction) report:(id)sender
{
	NS_DURING
		[self endEditing];
		short chan;
        NSLog(@"%@\n",[model boardIdString]);
		for(chan=0;chan<kNumShaperChannels;chan++){
			short gain = [model readGain:chan];
			NSLog(@"gain %d value: %d\n",chan,gain);
		}
		NS_HANDLER
			NSLog(@"Read Gain of Shaper FAILED.\n");
			NSRunAlertPanel([localException name], @"%@\nFailed Read Gains", @"OK", nil, nil,
							localException);
		NS_ENDHANDLER
		
}

- (IBAction) readScalers:(id)sender
{
	NS_DURING
		[self endEditing];
		short chan;
		NSLog(@"Scalers for Shaper in Slot %d  <0x%x> enabled: %@\n",[model slot],[model baseAddress],[model scalersEnabled]?@"YES":@"NO");
		unsigned short mask = [model scalerMask];
		if([model scalersEnabled]){
			if(mask){
				NSLog(@"Scaler enabled mask: 0x%02x\n",mask);
				for(chan=0;chan<kNumShaperChannels;chan++){
					if(mask & (1<<chan)){
						[model readScaler:chan];
						NSLog(@"%2d: %d\n",chan,[model scalerCount:chan]);
					}	
				}
			}
			else NSLog(@"Scaler Mask is zero. No Scalers read.\n");
		}
		//NSLog(@"global scaler:  %d  %d\n",[model readCounter2],[model readCounter1]);
		NS_HANDLER
			NSLog(@"Read Scalers of Shaper FAILED.\n");
			NSRunAlertPanel([localException name], @"%@\nFailed Read Scalers", @"OK", nil, nil,
							localException);
		NS_ENDHANDLER
}

- (IBAction) scanStartAction:(id)sender
{
	if([sender intValue] != [model scanStart]){
		[[self undoManager] setActionName: @"Set Scan Start"];
		[model setScanStart:[sender intValue]];		
	}
}

- (IBAction) scanDeltaAction:(id)sender
{
	if([sender intValue] != [model scanDelta]){
		[[self undoManager] setActionName: @"Set Scan Delta"];
		[model setScanDelta:[sender intValue]];		
	}
}

- (IBAction) scanNumberAction:(id)sender
{
	if([sender intValue] != [model scanNumber]){
		[[self undoManager] setActionName: @"Set Scan Number"];
		[model setScanNumber:[sender intValue]];		
	}
}

- (IBAction) scanAction:(id)sender
{
    [self endEditing];
    [model scanForShapers];
	
}


- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
	if([sender doubleValue] != [[model adcRateGroup]integrationTime]){
		[[self undoManager] setActionName: @"Set Integration Time"];
		[model setIntegrationTime:[sender doubleValue]];		
	}
	
}



//**************************************************************************************
// Function:	loadGrains
// Description: writes the gains  to hardware
//**************************************************************************************
-(IBAction)probeBoard:(id)sender
{
	[self endEditing];
    [model setBaseAddress:[addressStepper intValue]];
    
	NS_DURING
        NSLog(@"%@\n",[model boardIdString]);
    NS_HANDLER
        NSLog(@"Probe Shaper Board FAILED.\n");
		NSRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
						localException);
    NS_ENDHANDLER
}


- (double) getBarValue:(int)tag
{
	
	return [[[[model adcRateGroup]rates] objectAtIndex:tag] rate];
}


- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	return [[[model adcRateGroup]timeRate]count];
}
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
	if(set == 0){
		int count = [[[model adcRateGroup]timeRate] count];
		return [[[model adcRateGroup]timeRate]valueAtIndex:count-x-1];
	}
	return 0;
}

- (unsigned long)  	secondsPerUnit:(id) aPlotter
{
	return [[[model adcRateGroup]timeRate]sampleTime];
}



@end
