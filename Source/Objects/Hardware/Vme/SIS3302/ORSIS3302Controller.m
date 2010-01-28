//-------------------------------------------------------------------------
//  ORSIS3302Controller.h
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
#import "ORSIS3302Controller.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORValueBar.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORTimeRate.h"
#import "ORRate.h"
#import "OHexFormatter.h"

@implementation ORSIS3302Controller

-(id)init
{
    self = [super initWithWindowNibName:@"SIS3302"];
    
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
	
    settingSize     = NSMakeSize(765,700);
    rateSize		= NSMakeSize(790,300);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
	
    NSString* key = [NSString stringWithFormat: @"orca.SIS3302%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
			
	OHexFormatter *numberFormatter = [[[OHexFormatter alloc] init] autorelease];
	
	NSNumberFormatter *rateFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[rateFormatter setFormat:@"##0.0;0;-##0.0"];
	
	int i;
	for(i=0;i<8;i++){
		NSCell* theCell = [thresholdMatrix cellAtRow:i column:0];
		[theCell setFormatter:numberFormatter];
	}
	for(i=0;i<8;i++){
		NSCell* theCell = [rateTextFields cellAtRow:i column:0];
		[theCell setFormatter:rateFormatter];
	}
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
                         name : ORSIS3302SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORSIS3302RateGroupChangedNotification
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
                         name : ORSIS3302EnabledChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(gtChanged:)
                         name : ORSIS3302GtChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(thresholdChanged:)
                         name : ORSIS3302ThresholdChanged
                       object : model];
		
    [self registerRates];

	
    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORSIS3302ClockSourceChanged
						object: model];
			
    [notifyCenter addObserver : self
                     selector : @selector(eventConfigChanged:)
                         name : ORSIS3302EventConfigChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(csrChanged:)
                         name : ORSIS3302CSRRegChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(gateLengthChanged:)
                         name : ORSIS3302GateLengthChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(pulseLengthChanged:)
                         name : ORSIS3302PulseLengthChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(sumGChanged:)
                         name : ORSIS3302SumGChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(peakingTimeChanged:)
                         name : ORSIS3302PeakingTimeChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(internalTriggerDelayChanged:)
                         name : ORSIS3302InternalTriggerDelayChanged
						object: model];	

	[notifyCenter addObserver : self
                     selector : @selector(triggerDecimationChanged:)
                         name : ORSIS3302TriggerDecimationChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(acqRegEnableMaskChanged:)
                         name : ORSIS3302AcqRegEnableMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lemoOutModeChanged:)
                         name : ORSIS3302LemoOutModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lemoInModeChanged:)
                         name : ORSIS3302LemoInModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dacOffsetChanged:)
                         name : ORSIS3302DacOffsetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sampleLengthChanged:)
                         name : ORSIS3302SampleLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sampleStartIndexChanged:)
                         name : ORSIS3302SampleStartIndexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(preTriggerDelayChanged:)
                         name : ORSIS3302ModelPreTriggerDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerGateLengthChanged:)
                         name : ORSIS3302ModelTriggerGateLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energyPeakingTimeChanged:)
                         name : ORSIS3302ModelEnergyPeakingTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energyGapTimeChanged:)
                         name : ORSIS3302ModelEnergyGapTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energySampleLengthChanged:)
                         name : ORSIS3302ModelEnergySampleLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energySampleStartIndex1Changed:)
                         name : ORSIS3302ModelEnergySampleStartIndex1Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energySampleStartIndex2Changed:)
                         name : ORSIS3302ModelEnergySampleStartIndex2Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energyTauFactorChanged:)
                         name : ORSIS3302ModelEnergyTauFactorChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energySampleStartIndex3Changed:)
                         name : ORSIS3302ModelEnergySampleStartIndex3Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(endAddressThresholdChanged:)
                         name : ORSIS3302ModelEndAddressThresholdChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(runModeChanged:)
                         name : ORSIS3302ModelRunModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energyGateLengthChanged:)
                         name : ORSIS3302ModelEnergyGateLengthChanged
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
	[self gtChanged:nil];
	[self thresholdChanged:nil];
	[self gateLengthChanged:nil];
	[self pulseLengthChanged:nil];
	[self sumGChanged:nil];
	[self peakingTimeChanged:nil];
	[self internalTriggerDelayChanged:nil];
	[self triggerDecimationChanged:nil];
	
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
    [self waveFormRateChanged:nil];
	[self clockSourceChanged:nil];
	
	[self csrChanged:nil];
	[self acqRegEnableMaskChanged:nil];
	[self lemoOutModeChanged:nil];
	[self lemoInModeChanged:nil];
	[self dacOffsetChanged:nil];
	[self sampleLengthChanged:nil];
	[self sampleStartIndexChanged:nil];
	[self preTriggerDelayChanged:nil];
	[self triggerGateLengthChanged:nil];
	[self energyPeakingTimeChanged:nil];
	[self energyGapTimeChanged:nil];
	[self energySampleLengthChanged:nil];
	[self energySampleStartIndex1Changed:nil];
	[self energySampleStartIndex2Changed:nil];
	[self energyTauFactorChanged:nil];
	[self energySampleStartIndex3Changed:nil];
	[self endAddressThresholdChanged:nil];
	[self runModeChanged:nil];
	[self energyGateLengthChanged:nil];
}

#pragma mark •••Interface Management

- (void) energyGateLengthChanged:(NSNotification*)aNote
{
	[energyGateLengthField setIntValue: [model energyGateLength]];
}

- (void) runModeChanged:(NSNotification*)aNote
{
	[runModePU selectItemAtIndex: [model runMode]];
	[lemoInAssignmentsField setStringValue: [model lemoInAssignments]];
	[lemoOutAssignmentsField setStringValue: [model lemoOutAssignments]];
}

- (void) endAddressThresholdChanged:(NSNotification*)aNote
{
	[endAddressThresholdField setIntValue: [model endAddressThreshold]];
}

- (void) energySampleStartIndex3Changed:(NSNotification*)aNote
{
	[energySampleStartIndex3Field setIntValue: [model energySampleStartIndex3]];
}

- (void) energyTauFactorChanged:(NSNotification*)aNote
{
	[energyTauFactorField setIntValue: [model energyTauFactor]];
}

- (void) energySampleStartIndex2Changed:(NSNotification*)aNote
{
	[energySampleStartIndex2Field setIntValue: [model energySampleStartIndex2]];
}

- (void) energySampleStartIndex1Changed:(NSNotification*)aNote
{
	[energySampleStartIndex1Field setIntValue: [model energySampleStartIndex1]];
}

- (void) energySampleLengthChanged:(NSNotification*)aNote
{
	[energySampleLengthField setIntValue: [model energySampleLength]];
}

- (void) energyGapTimeChanged:(NSNotification*)aNote
{
	[energyGapTimeField setIntValue: [model energyGapTime]];
}

- (void) energyPeakingTimeChanged:(NSNotification*)aNote
{
	[energyPeakingTimeField setIntValue: [model energyPeakingTime]];
}

- (void) triggerGateLengthChanged:(NSNotification*)aNote
{
	[triggerGateLengthField setIntValue: [model triggerGateLength]];
}

- (void) preTriggerDelayChanged:(NSNotification*)aNote
{
	[preTriggerDelayField setIntValue: [model preTriggerDelay]];
}

- (void) sampleStartIndexChanged:(NSNotification*)aNote
{
	[sampleStartIndexField setIntValue: [model sampleStartIndex]];
}

- (void) sampleLengthChanged:(NSNotification*)aNote
{
	[sampleLengthField setIntValue: [model sampleLength]];
}

- (void) lemoInModeChanged:(NSNotification*)aNote
{
	[lemoInModePU selectItemAtIndex: [model lemoInMode]];
	[lemoInAssignmentsField setStringValue: [model lemoInAssignments]];
}

- (void) lemoOutModeChanged:(NSNotification*)aNote
{
	[lemoOutModePU selectItemAtIndex: [model lemoOutMode]];
	[lemoOutAssignmentsField setStringValue: [model lemoOutAssignments]];
}

- (void) acqRegEnableMaskChanged:(NSNotification*)aNote
{
	int i;
	unsigned long aMask = [model acqRegEnableMask];
	for(i = 0;i<16;i++){
		BOOL state = (aMask & (1<<i)) != 0;
		[[acqRegEnableMaskMatrix cellWithTag:i] setIntValue:state];
	}
}

- (void) csrChanged:(NSNotification*)aNote
{
	[[csrMatrix cellWithTag:1] setIntValue:[model invertTrigger]];
	[[csrMatrix cellWithTag:2] setIntValue:[model activateTriggerOnArmed]];
	[[csrMatrix cellWithTag:3] setIntValue:[model enableInternalRouting]];
	[[csrMatrix cellWithTag:4] setIntValue:[model bankFullTo1]];
	[[csrMatrix cellWithTag:5] setIntValue:[model bankFullTo2]];
	[[csrMatrix cellWithTag:6] setIntValue:[model bankFullTo3]];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
	[clockSourcePU selectItemAtIndex: [model clockSource]];
}

- (void) enabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[enabledMatrix cellWithTag:i] setState:[model enabled:i]];
	}
}

- (void) gtChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[gtMatrix cellWithTag:i] setState:[model gt:i]];
	}
}

- (void) thresholdChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		//float volts = (0.0003*[model threshold:i])-5.0;
		[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
	}
}

- (void) dacOffsetChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		//float volts = (0.0003*[model threshold:i])-5.0;
		[[dacOffsetMatrix cellWithTag:i] setIntValue:[model dacOffset:i]];
	}
}

- (void) gateLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[gateLengthMatrix cellWithTag:i] setIntValue:[model gateLength:i]];
	}
}

- (void) pulseLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[pulseLengthMatrix cellWithTag:i] setIntValue:[model pulseLength:i]];
	}
}

- (void) sumGChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[sumGMatrix cellWithTag:i] setIntValue:[model sumG:i]];
	}
}

- (void) peakingTimeChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[peakingTimeMatrix cellWithTag:i] setIntValue:[model peakingTime:i]];
	}
}

- (void) internalTriggerDelayChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[internalTriggerDelayMatrix cellWithTag:i] setIntValue:[model internalTriggerDelay:i]];
	}
}

- (void) triggerDecimationChanged:(NSNotification*)aNote
{
	[triggerDecimationPU selectItemAtIndex:[model triggerDecimation]];
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
    [gSecurity setLock:ORSIS3302SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSIS3302SettingsLock];
    BOOL locked = [gSecurity isLocked:ORSIS3302SettingsLock];
    
    [settingLockButton		setState: locked];
    [addressText			setEnabled:!locked && !runInProgress];
    [initButton				setEnabled:!lockedOrRunningMaintenance];
	[enabledMatrix			setEnabled:!lockedOrRunningMaintenance];
	[gtMatrix				setEnabled:!lockedOrRunningMaintenance];
	[thresholdMatrix		setEnabled:!lockedOrRunningMaintenance];
	[checkEventButton	    setEnabled:!locked && !runInProgress];
	
	[csrMatrix				setEnabled:!locked && !runInProgress];
	[clockSourcePU			setEnabled:!lockedOrRunningMaintenance];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3302 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3302 Card (Slot %d)",[model slot]]];
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

- (void) energyGateLengthAction:(id)sender
{
	[model setEnergyGateLength:[sender intValue]];	
}

- (IBAction) runModeAction:(id)sender
{
	[model setRunMode:[sender indexOfSelectedItem]];	
}

- (IBAction) energySampleStartIndex3Action:(id)sender
{
	[model setEnergySampleStartIndex3:[sender intValue]];	
}

- (IBAction) energyTauFactorAction:(id)sender
{
	[model setEnergyTauFactor:[sender intValue]];	
}

- (IBAction) energySampleStartIndex2Action:(id)sender
{
	[model setEnergySampleStartIndex2:[sender intValue]];	
}

- (IBAction) energySampleStartIndex1Action:(id)sender
{
	[model setEnergySampleStartIndex1:[sender intValue]];	
}

- (IBAction) energySampleLengthAction:(id)sender
{
	[model setEnergySampleLength:[sender intValue]];	
}

- (IBAction) energyGapTimeAction:(id)sender
{
	[model setEnergyGapTime:[sender intValue]];	
}

- (IBAction) energyPeakingTimeAction:(id)sender
{
	[model setEnergyPeakingTime:[sender intValue]];	
}

- (IBAction) triggerGateLengthAction:(id)sender
{
	[model setTriggerGateLength:[sender intValue]];	
}

- (IBAction) preTriggerDelayAction:(id)sender
{
	[model setPreTriggerDelay:[sender intValue]];	
}


- (IBAction) sampleStartIndexAction:(id)sender
{
	[model setSampleStartIndex:[sender intValue]];	
}

- (IBAction) sampleLengthAction:(id)sender
{
	[model setSampleLength:[sender intValue]];	
}

- (IBAction) lemoInModeAction:(id)sender
{
	[model setLemoInMode:[sender indexOfSelectedItem]];	
}

- (IBAction) lemoOutModeAction:(id)sender
{
	[model setLemoOutMode:[sender indexOfSelectedItem]];	
}

- (IBAction) acqRegEnableMaskAction:(id)sender
{
	unsigned short aMask = 0;
	int i;
	for(i=0;i<16;i++){
		if([[sender cellWithTag:i] intValue]){
			aMask |= (1<<i);
		}
	}
	[model setAcqRegEnableMask:aMask];	
}

- (IBAction) csrAction:(id)sender
{
	//tags are defined in IB, they have to match here or there will be trouble
	BOOL state = [[sender selectedCell] intValue];
	switch ([[sender selectedCell] tag]) {
		case 1: [model setInvertTrigger:state];				break; 
		case 2: [model setActivateTriggerOnArmed:state];	break; 
		case 3: [model setEnableInternalRouting:state];		break; 
		case 4: [model setBankFullTo1:state];				break; 
		case 5: [model setBankFullTo2:state];				break; 
		case 6: [model setBankFullTo3:state];				break; 
		default: break;
	}
}

//hardware actions
- (IBAction) probeBoardAction:(id)sender;
{
	@try {
		[model readModuleID:YES];
	}
	@catch (NSException* localException) {
		NSLog(@"Probe of SIS 3300 board ID failed\n");
        NSRunAlertPanel([localException name], @"%@\nProbe Failed", @"OK", nil, nil,
                        localException);
	}
}
- (IBAction) forceTrigger:(id)sender;
{
	@try {
		[model forceTrigger];
	}
	@catch (NSException* localException) {
		NSLog(@"Trigger of SIS 3300 failed\n");
        NSRunAlertPanel([localException name], @"%@\nForce Trigger Failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) clockSourceAction:(id)sender
{
	[model setClockSource:[sender indexOfSelectedItem]];	
}

- (IBAction) enabledAction:(id)sender
{
	[model setEnabledBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) gtAction:(id)sender
{
	[model setGtBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) thresholdAction:(id)sender
{
    if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) dacOffsetAction:(id)sender
{
    if([sender intValue] != [model dacOffset:[[sender selectedCell] tag]]){
		[model setDacOffset:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) gateLengthAction:(id)sender
{
    if([sender intValue] != [model gateLength:[[sender selectedCell] tag]]){
		[model setGateLength:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) pulseLengthAction:(id)sender
{
    if([sender intValue] != [model pulseLength:[[sender selectedCell] tag]]){
		[model setPulseLength:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) sumGAction:(id)sender
{
    if([sender intValue] != [model sumG:[[sender selectedCell] tag]]){
		[model setSumG:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) peakingTimeAction:(id)sender
{
    if([sender intValue] != [model peakingTime:[[sender selectedCell] tag]]){
		[model setPeakingTime:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) internalTriggerDelayAction:(id)sender
{
    if([sender intValue] != [model internalTriggerDelay:[[sender selectedCell] tag]]){
		[model setInternalTriggerDelay:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) triggerDecimationAction:(id)sender
{
    if([sender intValue] != [model triggerDecimation]){
		[model setTriggerDecimation:[sender indexOfSelectedItem]];
	}
}

-(IBAction) baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORSIS3302SettingsLock to:[sender intValue] forWindow:[self window]];
}

-(IBAction) initBoard:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardward
        NSLog(@"Initialized SIS3302 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset and Init of SIS3302 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed SIS3302 Reset and Init", @"OK", nil, nil,
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
	
    NSString* key = [NSString stringWithFormat: @"orca.ORSIS3302%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

- (IBAction) writeThresholdsAction:(id)sender
{
    @try {
        [self endEditing];
		NSLog(@"Write Thresholds for SIS3302 %d\n",[model slot]);
        [model writeThresholds];
    }
	@catch(NSException* localException) {
        NSLog(@"SIS3302 Thresholds write FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nSIS3302 Write FAILED", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readThresholdsAction:(id)sender
{
    @try {
        [self endEditing];
        [model readThresholds:YES];
    }
	@catch(NSException* localException) {
        NSLog(@"SIS3302 Thresholds read FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nSIS3302 Read FAILED", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) checkEvent:(id)sender
{
    @try {
		[self endEditing];
		[model initBoard];
		[model readOutEvents];
	}
	@catch(NSException* localException) {
        NSLog(@"SIS3302 Test Read FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nSIS3302 Test Read FAILED", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) report:(id)sender
{
    @try {
		[self endEditing];
		[model initBoard];
		[model report];
	}
	@catch(NSException* localException) {
        NSLog(@"SIS3302 Report FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nSIS3302 Report FAILED", @"OK", nil, nil,
                        localException);
    }
}

#pragma mark •••Data Source

- (double) getBarValue:(int)tag
{
	
	return [[[[model waveFormRateGroup]rates] objectAtIndex:tag] rate];
}
- (BOOL)   	willSupplyColors
{
    return NO;
}

- (int) 	numberOfDataSetsInPlot:(id)aPlotter
{
	return 1;
}

- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	return [[[model waveFormRateGroup]timeRate]count];
}

- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{

	int count = [[[model waveFormRateGroup]timeRate] count];
	return [[[model waveFormRateGroup]timeRate]valueAtIndex:count-x-1];
}

- (unsigned long)  	secondsPerUnit:(id) aPlotter
{
	return [[[model waveFormRateGroup]timeRate]sampleTime];
}

@end
