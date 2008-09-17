//-------------------------------------------------------------------------
//  ORXYCom200Controller.h
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import <Cocoa/Cocoa.h>
#import "ORXYCom200Controller.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORValueBar.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORTimeRate.h"
#import "ORRate.h"

@implementation ORXYCom200Controller

-(id)init
{
    self = [super initWithWindowNibName:@"XYCom200"];
    
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

	polarityPU[0] = polarityPU0;
	polarityPU[1] = polarityPU1;
	polarityPU[2] = polarityPU2;
	polarityPU[3] = polarityPU3;
	polarityPU[4] = polarityPU4;
	polarityPU[5] = polarityPU5;
	polarityPU[6] = polarityPU6;
	polarityPU[7] = polarityPU7;

	triggerModePU[0] = triggerModePU0;
	triggerModePU[1] = triggerModePU1;
	triggerModePU[2] = triggerModePU2;
	triggerModePU[3] = triggerModePU3;
	triggerModePU[4] = triggerModePU4;
	triggerModePU[5] = triggerModePU5;
	triggerModePU[6] = triggerModePU6;
	triggerModePU[7] = triggerModePU7;

    NSString* key = [NSString stringWithFormat: @"orca.XYCom200%d.selectedtab",[model slot]];
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
                         name : ORXYCom200SettingsLock
                        object: nil];
    
    [notifyCenter addObserver:self selector:@selector(updateCardInfo:)
                         name:ORXYCom200CardInfoUpdated 
                       object:model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORXYCom200RateGroupChangedNotification
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
                     selector : @selector(noiseFloorChanged:)
                         name : ORXYCom200NoiseFloorChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorOffsetChanged:)
                         name : ORXYCom200ModelNoiseFloorOffsetChanged
                       object : model];
                       
    [notifyCenter addObserver : self
                     selector : @selector(setFifoStateLabel)
                         name : ORXYCom200ModelFIFOCheckChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorIntegrationChanged:)
                         name : ORXYCom200ModelNoiseFloorIntegrationTimeChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(enabledChanged:)
                         name : ORXYCom200ModelEnabledChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(debugChanged:)
                         name : ORXYCom200ModelDebugChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(pileUpChanged:)
                         name : ORXYCom200ModelPileUpChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(polarityChanged:)
                         name : ORXYCom200ModelPolarityChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerModeChanged:)
                         name : ORXYCom200ModelTriggerModeChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(ledThresholdChanged:)
                         name : ORXYCom200ModelLEDThresholdChanged
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(cfdDelayChanged:)
                         name : ORXYCom200ModelCFDDelayChanged
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(cfdFractionChanged:)
                         name : ORXYCom200ModelCFDFractionChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(cfdThresholdChanged:)
                         name : ORXYCom200ModelCFDThresholdChanged
                       object : model];
    [notifyCenter addObserver : self
                     selector : @selector(dataDelayChanged:)
                         name : ORXYCom200ModelDataDelayChanged
                       object : model];
    [notifyCenter addObserver : self
                     selector : @selector(dataLengthChanged:)
                         name : ORXYCom200ModelDataLengthChanged
                       object : model];

    [self registerRates];
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
    [self updateCardInfo:nil];
	[self enabledChanged:nil];
	[self debugChanged:nil];
	[self pileUpChanged:nil];
	[self polarityChanged:nil];
	[self triggerModeChanged:nil];
	[self ledThresholdChanged:nil];
	[self cfdDelayChanged:nil];
	[self cfdFractionChanged:nil];
	[self cfdThresholdChanged:nil];
	[self dataDelayChanged:nil];
	[self dataLengthChanged:nil];

    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
    [self waveFormRateChanged:nil];
	[self noiseFloorChanged:nil];
	[self noiseFloorIntegrationChanged:nil];
	[self noiseFloorOffsetChanged:nil];


}

#pragma mark •••Interface Management
- (void) enabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumXYCom200Channels;i++){
		[[enabledMatrix cellWithTag:i] setState:[model enabled:i]];
		[[enabled2Matrix cellWithTag:i] setState:[model enabled:i]];
	}
}

- (void) debugChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumXYCom200Channels;i++){
		[[debugMatrix cellWithTag:i] setState:[model debug:i]];
	}
}

- (void) pileUpChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumXYCom200Channels;i++){
		[[pileUpMatrix cellWithTag:i] setState:[model pileUp:i]];
	}
}

- (void) polarityChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumXYCom200Channels;i++){
		[polarityPU[i] selectItemAtIndex:[model polarity:i]];
	}
}

- (void) triggerModeChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumXYCom200Channels;i++){
		[triggerModePU[i] selectItemAtIndex:[model triggerMode:i]];
	}
}

- (void) ledThresholdChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumXYCom200Channels;i++){
		[[ledThresholdMatrix cellWithTag:i] setIntValue:[model ledThreshold:i]];
	}
}

- (void) cfdDelayChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumXYCom200Channels;i++){
		[[cfdDelayMatrix cellWithTag:i] setFloatValue:[model cfdDelayConverted:i]];
	}
}

- (void) cfdFractionChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumXYCom200Channels;i++){
		[[cfdFractionMatrix cellWithTag:i] setIntValue:[model cfdFraction:i]];
	}
}

- (void) cfdThresholdChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumXYCom200Channels;i++){
		[[cfdThresholdMatrix cellWithTag:i] setFloatValue:[model cfdThresholdConverted:i]];
	}
}

- (void) dataDelayChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumXYCom200Channels;i++){
		[[dataDelayMatrix cellWithTag:i] setFloatValue:[model dataDelayConverted:i]];
	}
}

- (void) dataLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumXYCom200Channels;i++){
		[[dataLengthMatrix cellWithTag:i] setFloatValue:[model dataLengthConverted:i]];
	}
}

- (void) noiseFloorIntegrationChanged:(NSNotification*)aNote
{
	[noiseFloorIntegrationField setFloatValue:[model noiseFloorIntegrationTime]];
}

- (void) noiseFloorChanged:(NSNotification*)aNote
{
	if([model noiseFloorRunning]){
		[noiseFloorProgress startAnimation:self];
	}
	else {
		[noiseFloorProgress stopAnimation:self];
	}
	[startNoiseFloorButton setTitle:[model noiseFloorRunning]?@"Stop":@"Start"];
}

- (void) noiseFloorOffsetChanged:(NSNotification*)aNote
{
	[noiseFloorOffsetField setIntValue:[model noiseFloorOffset]];
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
    [gSecurity setLock:ORXYCom200SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORXYCom200SettingsLock];
    BOOL locked = [gSecurity isLocked:ORXYCom200SettingsLock];
    
	[self setFifoStateLabel];
	
    [settingLockButton setState: locked];
    [addressText setEnabled:!locked && !runInProgress];
    [initButton setEnabled:!lockedOrRunningMaintenance];
    [clearFIFOButton setEnabled:!locked && !runInProgress];
	[noiseFloorButton setEnabled:!locked && !runInProgress];
	[statusButton setEnabled:!lockedOrRunningMaintenance];
	[probeButton setEnabled:!locked && !runInProgress];
	[enabledMatrix setEnabled:!lockedOrRunningMaintenance];
	[debugMatrix setEnabled:!lockedOrRunningMaintenance];
	[pileUpMatrix setEnabled:!lockedOrRunningMaintenance];
	[ledThresholdMatrix setEnabled:!lockedOrRunningMaintenance];
	[cfdDelayMatrix setEnabled:!lockedOrRunningMaintenance];
	[cfdFractionMatrix setEnabled:!lockedOrRunningMaintenance];
	[cfdThresholdMatrix setEnabled:!lockedOrRunningMaintenance];
	[dataDelayMatrix setEnabled:!lockedOrRunningMaintenance];
	[dataLengthMatrix setEnabled:!lockedOrRunningMaintenance];
	[cardInfoMatrix setEnabled:!lockedOrRunningMaintenance];
	
	int i;
	for(i=0;i<kNumXYCom200Channels;i++){
		[polarityPU[i] setEnabled:!lockedOrRunningMaintenance];
		[triggerModePU[i] setEnabled:!lockedOrRunningMaintenance];
	}		
}

- (void) setFifoStateLabel
{
	if(![gOrcaGlobals runInProgress]){
		[fifoState setTextColor:[NSColor blackColor]];
		[fifoState setStringValue:@"--"];
	}
	else {
		int val = [model fifoState];
		if((val & kXYCom200FIFOAllFull)==0) {
			[fifoState setTextColor:[NSColor redColor]];
			[fifoState setStringValue:@"Full"];
		}
		else {
			[fifoState setTextColor:[NSColor blackColor]];
			if((val & kXYCom200FIFOHalfFull)==0)			[fifoState setStringValue:@"Half Full"];
			else if((val & kXYCom200FIFOEmpty)==0)		[fifoState setStringValue:@"Empty"];
			else if((val & kXYCom200FIFOAlmostEmpty)==0)	[fifoState setStringValue:@"Almost Empty"];
		}
	}
}


- (void) updateCardInfo:(NSNotification*)aNote
{
    int i;
    for(i=0;i<kNumXYCom200CardParams;i++){
        [[cardInfoMatrix cellWithTag:i] setObjectValue:[model convertedCardValue:i]];
    }
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"XYCom200 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"XYCom200 Card (Slot %d)",[model slot]]];
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
- (IBAction) enabledAction:(id)sender
{
	if([sender intValue] != [model enabled:[[sender selectedCell] tag]]){
		[model setEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) debugAction:(id)sender
{
	if([sender intValue] != [model debug:[[sender selectedCell] tag]]){
		[model setDebug:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) pileUpAction:(id)sender
{
	if([sender intValue] != [model pileUp:[[sender selectedCell] tag]]){
		[model setPileUp:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) polarityAction:(id)sender
{
	if([sender indexOfSelectedItem] != [model polarity:[sender tag]]){
		[model setPolarity:[sender tag] withValue:[sender indexOfSelectedItem]];
	}
}

- (IBAction) triggerModeAction:(id)sender
{
	if([sender indexOfSelectedItem] != [model triggerMode:[sender tag]]){
		[model setTriggerMode:[sender tag] withValue:[sender indexOfSelectedItem]];
	}
}

- (IBAction) ledThresholdAction:(id)sender
{
	if([sender intValue] != [model ledThreshold:[[sender selectedCell] tag]]){
		[model setLEDThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) cfdFractionAction:(id)sender
{
	if([sender intValue] != [model cfdFraction:[[sender selectedCell] tag]]){
		[model setCFDFraction:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) cfdDelayAction:(id)sender
{
	if([sender intValue] != [model cfdDelay:[[sender selectedCell] tag]]){
		[model setCFDDelayConverted:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

- (IBAction) cfdThresholdAction:(id)sender
{
	if([sender intValue] != [model cfdThreshold:[[sender selectedCell] tag]]){
		[model setCFDThresholdConverted:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

- (IBAction) dataDelayAction:(id)sender
{
	if([sender intValue] != [model dataDelay:[[sender selectedCell] tag]]){
		[model setDataDelayConverted:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

- (IBAction) dataLengthAction:(id)sender
{
	if([sender intValue] != [model dataLength:[[sender selectedCell] tag]]){
		[model setDataLengthConverted:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

-(IBAction) noiseFloorOffsetAction:(id)sender
{
    if([sender intValue] != [model noiseFloorOffset]){
        [model setNoiseFloorOffset:[sender intValue]];
    }
}

- (IBAction) noiseFloorIntegrationAction:(id)sender
{
    if([sender floatValue] != [model noiseFloorIntegrationTime]){
        [model setNoiseFloorIntegrationTime:[sender floatValue]];
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
    [gSecurity tryToSetLock:ORXYCom200SettingsLock to:[sender intValue] forWindow:[self window]];
}


-(IBAction)initBoard:(id)sender
{
    NS_DURING
        [self endEditing];
        [model initBoard];		//initialize and load hardward
        NSLog(@"Initialized XYCom200 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    NS_HANDLER
        NSLog(@"Reset and Init of XYCom200 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed XYCom200 Reset and Init", @"OK", nil, nil,
                        localException);
    NS_ENDHANDLER
}

- (IBAction) clearFIFO:(id)sender
{
    NS_DURING  
        [model clearFIFO];
        NSLog(@"XYCom200 (Slot %d <%p>) FIFO cleared\n",[model slot],[model baseAddress]);
    NS_HANDLER
        NSLog(@"Clear of XYCom200 FIFO FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed XYCom200 FIFO Clear", @"OK", nil, nil,
                        localException);
    NS_ENDHANDLER
}


- (IBAction) cardInfoAction:(id) sender
{
    int index = [[sender selectedCell] tag];
    id theRawValue = [model rawCardValue:index value:[sender objectValue]];
    [model cardInfo:index setObject: theRawValue];
}

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model waveFormRateGroup]integrationTime]){
        [model setRateIntegrationTime:[sender doubleValue]];		
    }
}


-(IBAction)probeBoard:(id)sender
{
    [self endEditing];
    NS_DURING
        unsigned short theID = [model readBoardID];
        NSLog(@"Getina BoardID (slot %d): 0x%x\n",[model slot],theID);
        if(theID == ([model baseAddress]>>5))NSLog(@"Getina BoardID looks correct\n");
        else NSLogColor([NSColor redColor],@"Getina BoardID doesn't match dip settings\n");
    NS_HANDLER
        NSLog(@"Probe XYCom200 Board FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
                        localException);
    NS_ENDHANDLER
}

- (IBAction) openNoiseFloorPanel:(id)sender
{
	[self endEditing];
    [NSApp beginSheet:noiseFloorPanel modalForWindow:[self window]
		modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (IBAction) closeNoiseFloorPanel:(id)sender
{
    [noiseFloorPanel orderOut:nil];
    [NSApp endSheet:noiseFloorPanel];
}

- (IBAction) findNoiseFloors:(id)sender
{
	[noiseFloorPanel endEditingFor:nil];		
    NS_DURING
        NSLog(@"Getina (slot %d) Finding LED Thresholds \n",[model slot]);
		[model findNoiseFloors];
    NS_HANDLER
        NSLog(@"LED Threshold Finder for XYCom200 Board FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed LED Threshold finder", @"OK", nil, nil,
                        localException);
    NS_ENDHANDLER
}

-(IBAction)readStatus:(id)sender
{    
    [self endEditing];
    NS_DURING
        NSLog(@"Getina BoardID (slot %d): [0x%x] ID = 0x%x\n",[model slot],[model baseAddress],[model readBoardID]);
        int chan;
        for(chan = 0;chan<kNumXYCom200Channels;chan++){
            unsigned value = [model readControlReg:chan];
            NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"chan: %d Enabled: %@ Debug: %@  PileUp: %@ Polarity: 0x%02x TriggerMode: 0x%02x\n",
                      chan, 
                      (value&0x1)?@"[YES]":@"[ NO]",		//enabled
                      ((value>>1)&0x1)?@"[YES]":@"[ NO]",	//debug
                      ((value>>2)&0x1)?@"[YES]":@"[ NO]", //pileup
                      (value>>10)&0x3, (value>>3)&0x3);
        }
        unsigned short fifoStatus = [model readFifoState];
        if(fifoStatus == kFull)			    NSLog(@"FIFO = Full\n");
        else if(fifoStatus == kHalfFull)	NSLog(@"FIFO = Half Full\n");
        else if(fifoStatus == kEmpty)		NSLog(@"FIFO = Empty\n");
        else if(fifoStatus == kAlmostEmpty)	NSLog(@"FIFO = Almost Empty\n");
        else if(fifoStatus == kSome)		NSLog(@"FIFO = Not Empty\n");
        
    NS_HANDLER
        NSLog(@"Probe XYCom200 Board FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
                        localException);
    NS_ENDHANDLER
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
	
    NSString* key = [NSString stringWithFormat: @"orca.ORXYCom200%d.selectedtab",[model slot]];
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
