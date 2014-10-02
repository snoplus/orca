//
//  ORDT5720Controller.m
//  Orca
//
//  Created by Mark Howe on Wed Mar 12,2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina at the Center sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORDT5720Controller.h"
#import "ORDT5720Model.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"
#import "ORValueBar.h"
#import "ORTimeRate.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"

#define kNumChanConfigBits 5
#define kNumTrigSourceBits 10


@interface ORDT5720Controller (private)
- (void) populateInterfacePopup:(ORUSB*)usb;
@end

@implementation ORDT5720Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"DT5720" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceAdded
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceRemoved
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORDT5720ModelSerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORDT5720ModelUSBInterfaceChanged
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORDT5720ModelLock
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(overUnderThresholdChanged:)
                         name : ORDT5720OverUnderThresholdChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(zsThresholdChanged:)
                         name : ORDT5720ZsThresholdChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(thresholdChanged:)
                         name : ORDT5720ThresholdChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(nlfwdChanged:)
                         name : ORDT5720NlfwdChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(nlbkChanged:)
                         name : ORDT5720NlbkChanged
                       object : model];
    
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : ORDT5720SelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegChannelChanged:)
						 name : ORDT5720SelectedChannelChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : ORDT5720WriteValueChanged
					   object : model];
	
 	
	[notifyCenter addObserver : self
					 selector : @selector(dacChanged:)
						 name : ORDT5720ChnlDacChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(customSizeChanged:)
                         name : ORDT5720ModelCustomSizeChanged
					   object : model];
    
	[notifyCenter addObserver : self
                     selector : @selector(isCustomSizeChanged:)
                         name : ORDT5720ModelIsCustomSizeChanged
                       object : model];
		
	[notifyCenter addObserver : self
                     selector : @selector(countAllTriggersChanged:)
                         name : ORDT5720ModelCountAllTriggersChanged
					   object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(coincidenceLevelChanged:)
                         name : ORDT5720ModelCoincidenceLevelChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(triggerSourceMaskChanged:)
                         name : ORDT5720ModelTriggerSourceMaskChanged
					   object : model];
	[notifyCenter addObserver : self
                     selector : @selector(triggerOutMaskChanged:)
                         name : ORDT5720ModelTriggerOutMaskChanged
                       object : model];
    	
    [notifyCenter addObserver : self
                     selector : @selector(postTriggerSettingChanged:)
                         name : ORDT5720ModelPostTriggerSettingChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : ORDT5720ModelEnabledMaskChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(basicLockChanged:)
						 name : ORDT5720BasicLock
					   object : nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORDT5720SettingsLock
					   object : nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(basicLockChanged:)
						 name : ORDT5720BasicLock
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(integrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(setBufferStateLabel)
                         name : ORDT5720ModelBufferCheckChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(eventSizeChanged:)
                         name : ORDT5720ModelEventSizeChanged
						object: model];
	   
	[self registerRates];

    [notifyCenter addObserver : self
                     selector : @selector(logicTypeChanged:)
                         name : ORDT5720ModelLogicTypeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(zsAlgorithmChanged:)
                         name : ORDT5720ModelZsAlgorithmChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(trigOverlapEnabledChanged:)
                         name : ORDT5720ModelTrigOverlapEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(testPatternEnabledChanged:)
                         name : ORDT5720ModelTestPatternEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(trigOnUnderThresholdChanged:)
                         name : ORDT5720ModelTrigOnUnderThresholdChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORDT5720ModelClockSourceChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(gpiRunModeChanged:)
                         name : ORDT5720ModelGpiRunModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(softwareTrigEnabledChanged:)
                         name : ORDT5720ModelSoftwareTrigEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(externalTrigEnabledChanged:)
                         name : ORDT5720ModelExternalTrigEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fpExternalTrigEnabledChanged:)
                         name : ORDT5720ModelFpExternalTrigEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fpSoftwareTrigEnabledChanged:)
                         name : ORDT5720ModelFpSoftwareTrigEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(gpoEnabledChanged:)
                         name : ORDT5720ModelGpoEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(ttlEnabledChanged:)
                         name : ORDT5720ModelTtlEnabledChanged
						object: model];

}

- (void) awakeFromNib
{
    basicSize      = NSMakeSize(780,450); //NSMakeSize(280,400);
    settingsSize   = NSMakeSize(780,450);
    monitoringSize = NSMakeSize(783,320);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
    [registerAddressPopUp setAlignment:NSCenterTextAlignment];
    [channelPopUp setAlignment:NSCenterTextAlignment];
	
    [self populatePullDown];
    
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	[self populateInterfacePopup:[model getUSBController]];
    
    int i;
    for(i=0;i<kNumDT5720Channels;i++){
        [[thresholdMatrix cellAtRow:i column:0] setTag:i];
        [[zsThresholdMatrix cellAtRow:i column:0] setTag:i];
        [[nLbkMatrix cellAtRow:i column:0] setTag:i];
        [[nLfwdMatrix cellAtRow:i column:0] setTag:i];
    }
    
    
    [super awakeFromNib];

    
    NSString* key = [NSString stringWithFormat: @"orca.%@.selectedtab",[model fullID]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	[rate0 setNumber:8 height:10 spacing:5];
}

- (void) updateWindow
{
    [ super updateWindow ];
    
	[self serialNumberChanged:nil];
    
    [self overUnderThresholdChanged:nil];
    [self thresholdChanged:nil];
    [self nlfwdChanged:nil];
    [self nlbkChanged:nil];
    [self dacChanged:nil];

    [self integrationChanged:nil];
    [self writeValueChanged:nil];
    [self totalRateChanged:nil];
    [self selectedRegIndexChanged:nil];
    [self selectedRegChannelChanged:nil];
	[self customSizeChanged:nil];
	[self isCustomSizeChanged:nil];
	[self countAllTriggersChanged:nil];
	[self coincidenceLevelChanged:nil];
	[self triggerSourceMaskChanged:nil];
	[self triggerOutMaskChanged:nil];
	[self postTriggerSettingChanged:nil];
	[self enabledMaskChanged:nil];
    [self waveFormRateChanged:nil];
 	[self eventSizeChanged:nil];
	
	[self settingsLockChanged:nil];
    [self basicLockChanged:nil];
	[self logicTypeChanged:nil];
	[self zsAlgorithmChanged:nil];
	[self trigOverlapEnabledChanged:nil];
	[self testPatternEnabledChanged:nil];
	[self trigOnUnderThresholdChanged:nil];
	[self clockSourceChanged:nil];
	[self gpiRunModeChanged:nil];
	[self softwareTrigEnabledChanged:nil];
	[self externalTrigEnabledChanged:nil];
	[self fpExternalTrigEnabledChanged:nil];
	[self fpSoftwareTrigEnabledChanged:nil];
	[self gpoEnabledChanged:nil];
	[self ttlEnabledChanged:nil];
}

- (void) ttlEnabledChanged:(NSNotification*)aNote
{
	[ttlEnabledMatrix selectCellWithTag: [model ttlEnabled]];
}

- (void) gpoEnabledChanged:(NSNotification*)aNote
{
	[gpoEnabledButton setIntValue: [model gpoEnabled]];
}

- (void) fpSoftwareTrigEnabledChanged:(NSNotification*)aNote
{
	[fpSoftwareTrigEnabledButton setIntValue: [model fpSoftwareTrigEnabled]];
}

- (void) fpExternalTrigEnabledChanged:(NSNotification*)aNote
{
	[fpExternalTrigEnabledButton setIntValue: [model fpExternalTrigEnabled]];
}

- (void) externalTrigEnabledChanged:(NSNotification*)aNote
{
	[externalTrigEnabledButton setIntValue: [model externalTrigEnabled]];
}

- (void) softwareTrigEnabledChanged:(NSNotification*)aNote
{
	[softwareTrigEnabledButton setIntValue: [model softwareTrigEnabled]];
}

- (void) gpiRunModeChanged:(NSNotification*)aNote
{
	[gpiRunModeMatrix selectCellWithTag: [model gpiRunMode]];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
	[clockSourcePU selectItemAtIndex: [model clockSource]];
}

- (void) trigOnUnderThresholdChanged:(NSNotification*)aNote
{
	[trigOnUnderThresholdMatrix selectCellWithTag: [model trigOnUnderThreshold]];
}

- (void) testPatternEnabledChanged:(NSNotification*)aNote
{
	[testPatternEnabledButton setIntValue: [model testPatternEnabled]];
}

- (void) trigOverlapEnabledChanged:(NSNotification*)aNote
{
	[trigOverlapEnabledButton setIntValue: [model trigOverlapEnabled]];
}

- (void) zsAlgorithmChanged:(NSNotification*)aNote
{
	[zsAlgorithmPU selectItemAtIndex: [model zsAlgorithm]];
}

- (void) logicTypeChanged:(NSNotification*)aNote
{
	[logicTypeMatrix selectCellWithTag:[model logicType]];
}

- (void) registerRates
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self name:ORRateChangedNotification object:nil];
    
    NSEnumerator* e = [[[model waveFormRateGroup] rates] objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
		
        [notifyCenter removeObserver:self name:ORRateChangedNotification object:obj];
		
        [notifyCenter addObserver:self
                         selector:@selector(waveFormRateChanged:)
                             name:ORRateChangedNotification
                           object:obj];
    }
}

#pragma mark •••Notifications
- (void) serialNumberChanged:(NSNotification*)aNote
{
	if(![model serialNumber] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
	else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
	[[self window] setTitle:[model title]];
}

- (void) interfacesChanged:(NSNotification*)aNote
{
	[self populateInterfacePopup:[aNote object]];
}

- (void) lockChanged:(NSNotification*)aNote
{   
	//BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL locked = [gSecurity isLocked:ORDT5720ModelLock];
    [lockButton setState: locked];
	[serialNumberPopup setEnabled:!locked];
	
}


- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) eventSizeChanged:(NSNotification*)aNote
{
	[eventSizePopUp selectItemAtIndex:	[model eventSize]];
	[eventSizeTextField setIntValue:	1024*1024./powf(2.,(float)[model eventSize]) / 2]; //in Samples
	
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORDT5720BasicLock to:secure];
    [basicLockButton setEnabled:secure];
    [gSecurity setLock:ORDT5720SettingsLock to:secure];
    [settingsLockButton setEnabled:secure];
}

- (void) overUnderThresholdChanged: (NSNotification*) aNotification
{
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORDT5720Chnl] intValue];
        [[overUnderMatrix cellWithTag:chnl] setIntValue:[model overUnderThreshold:chnl]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[overUnderMatrix cellWithTag:i] setIntValue:[model overUnderThreshold:i]];
        }
    }
}
- (void) zsThresholdChanged:(NSNotification*) aNotification
{
    // Get the channel that changed and then set the GUI value using the model value.
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORDT5720Chnl] intValue];
        [[zsThresholdMatrix cellWithTag:chnl] setIntValue:[model zsThreshold:chnl]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[zsThresholdMatrix cellWithTag:i] setIntValue:[model zsThreshold:i]];
        }
    }
}
- (void) nlfwdChanged:(NSNotification*) aNotification
{
    // Get the channel that changed and then set the GUI value using the model value.
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORDT5720Chnl] intValue];
        [[nLfwdMatrix cellWithTag:chnl] setIntValue:[model nLfwd:chnl]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[nLfwdMatrix cellWithTag:i] setIntValue:[model nLfwd:i]];
        }
    }
}
- (void) nlbkChanged:(NSNotification*) aNotification
{
    // Get the channel that changed and then set the GUI value using the model value.
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORDT5720Chnl] intValue];
        [[nLbkMatrix cellWithTag:chnl] setIntValue:[model nLbk:chnl]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[nLbkMatrix cellWithTag:i] setIntValue:[model nLbk:i]];
        }
    }
}

- (void) thresholdChanged:(NSNotification*) aNotification
{
    // Get the channel that changed and then set the GUI value using the model value.
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORDT5720Chnl] intValue];
        [[thresholdMatrix cellWithTag:chnl] setIntValue:[model threshold:chnl]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
        }
    }
}

- (void) dacChanged: (NSNotification*) aNotification
{
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORDT5720Chnl] intValue];
        [[dacMatrix cellWithTag:chnl] setFloatValue:[model convertDacToVolts:[model dac:chnl]]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[dacMatrix cellWithTag:i] setFloatValue:[model convertDacToVolts:[model dac:i]]];
        }
    }
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

- (void) setBufferStateLabel
{
	if(![gOrcaGlobals runInProgress]){
		[bufferStateField setTextColor:[NSColor blackColor]];
		[bufferStateField setStringValue:@"--"];
	}
	else {
		int val = [model bufferState];
		if(val) {
			[bufferStateField setTextColor:[NSColor redColor]];
			[bufferStateField setStringValue:@"Full"];
		}
		else {
			[bufferStateField setTextColor:[NSColor blackColor]];
			[bufferStateField setStringValue:@"Ready"];
		}
	}
}

- (void) totalRateChanged:(NSNotification*)aNotification
{
	ORRateGroup* theRateObj = [aNotification object];
	if(aNotification == nil || [model waveFormRateGroup] == theRateObj){
		
		[totalRateText setFloatValue: [theRateObj totalRate]];
		[totalRate setNeedsDisplay:YES];
	}
}

- (void) waveFormRateChanged:(NSNotification*)aNote
{
    ORRate* theRateObj = [aNote object];
    [[rateTextFields cellWithTag:[theRateObj tag]] setFloatValue: [theRateObj rate]];
    [rate0 setNeedsDisplay:YES];
}

- (void) writeValueChanged:(NSNotification*) aNotification
{
	//  Set value of both text and stepper
	[self updateStepper:writeValueStepper setting:[model selectedRegValue]];
	[writeValueTextField setIntValue:[model selectedRegValue]];
}

- (void) selectedRegIndexChanged:(NSNotification*) aNotification
{
	
	//  Set value of popup
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerAddressPopUp setting:index];
	[self updateRegisterDescription:index];
	
	
	BOOL readAllowed = [model getAccessType:index] == kReadOnly || [model getAccessType:index] == kReadWrite;
	BOOL writeAllowed = [model getAccessType:index] == kWriteOnly || [model getAccessType:index] == kReadWrite;
	
	[basicWriteButton setEnabled:writeAllowed];
	[basicReadButton setEnabled:readAllowed];
	
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORDT5720BasicLock];
	if ([model selectedRegIndex] >= kZS_Thres && [model selectedRegIndex]<=kAdcConfig){
		[channelPopUp setEnabled:!lockedOrRunningMaintenance];
	}
	else [channelPopUp setEnabled:NO];
	
}

- (void) selectedRegChannelChanged:(NSNotification*) aNotification
{
	[self updatePopUpButton:channelPopUp setting:[model selectedChannel]];
}

- (void) enabledMaskChanged:(NSNotification*)aNote
{
	int i;
	unsigned short mask = [model enabledMask];
	for(i=0;i<kNumDT5720Channels;i++){
		[[enabledMaskMatrix cellWithTag:i] setIntValue:(mask & (1<<i)) !=0];
		[[enabled2MaskMatrix cellWithTag:i] setIntValue:(mask & (1<<i)) !=0];
	}
}

- (void) postTriggerSettingChanged:(NSNotification*)aNote
{
	//todo *4 in std mode *5 in packed mode
	[postTriggerSettingTextField setIntValue:([model postTriggerSetting] * 4)];
}

- (void) triggerSourceMaskChanged:(NSNotification*)aNote
{
	int i;
	unsigned long mask = [model triggerSourceMask];
	for(i=0;i<kNumDT5720Channels;i++){
		[[chanTriggerMatrix cellWithTag:i] setIntValue:(mask & (1L << i)) !=0];
	}
	[[otherTriggerMatrix cellWithTag:0] setIntValue:(mask & (1L << 30)) !=0];
	[[otherTriggerMatrix cellWithTag:1] setIntValue:(mask & (1L << 31)) !=0];
}

- (void) triggerOutMaskChanged:(NSNotification*)aNote
{
	int i;
	unsigned long mask = [model triggerOutMask];
	for(i=0;i<kNumDT5720Channels;i++){
		[[chanTriggerOutMatrix cellWithTag:i] setIntValue:(mask & (1L << i)) !=0];
	}
	[[otherTriggerOutMatrix cellWithTag:0] setIntValue:(mask & (1L << 30)) !=0];
	[[otherTriggerOutMatrix cellWithTag:1] setIntValue:(mask & (1L << 31)) !=0];
}

- (void) coincidenceLevelChanged:(NSNotification*)aNote
{
	[coincidenceLevelTextField setIntValue: [model coincidenceLevel]];
}


- (void) countAllTriggersChanged:(NSNotification*)aNote
{
	[countAllTriggersMatrix selectCellWithTag: [model countAllTriggers]];
}

- (void) customSizeChanged:(NSNotification*)aNote
{
	//todo: *4 in std mode, *5 in packed mode
	[customSizeTextField setIntValue:([model customSize] * 4)];
}

- (void) isCustomSizeChanged:(NSNotification*)aNote
{
	[customSizeButton setIntValue:[model isCustomSize]];
	[customSizeTextField setEnabled:[model isCustomSize]];
}

- (void) basicLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:ORDT5720BasicLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORDT5720BasicLock];
	
	//[softwareTriggerButton setEnabled: !locked && !runInProgress];
    [basicLockButton setState: locked];
    
    [addressStepper setEnabled:!locked && !runInProgress];
    [addressTextField setEnabled:!locked && !runInProgress];
	
    [writeValueStepper setEnabled:!lockedOrRunningMaintenance];
    [writeValueTextField setEnabled:!lockedOrRunningMaintenance];
    [registerAddressPopUp setEnabled:!lockedOrRunningMaintenance];
	
    [self selectedRegIndexChanged:nil];
	
    [basicWriteButton setEnabled:!lockedOrRunningMaintenance];
    [basicReadButton setEnabled:!lockedOrRunningMaintenance];
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORDT5720BasicLock])s = @"Not in Maintenance Run.";
    }
    [basicLockDocField setStringValue:s];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:ORDT5720SettingsLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORDT5720SettingsLock];
    [settingsLockButton setState: locked];
	[self setBufferStateLabel];
    [thresholdMatrix setEnabled:!lockedOrRunningMaintenance];
    [overUnderMatrix setEnabled:!lockedOrRunningMaintenance];
    [dacMatrix setEnabled:!lockedOrRunningMaintenance];

    //[softwareTriggerButton setEnabled:!lockedOrRunningMaintenance];
	[softwareTriggerButton setEnabled:YES];
    [otherTriggerMatrix setEnabled:!lockedOrRunningMaintenance];
    [chanTriggerMatrix setEnabled:!lockedOrRunningMaintenance];
	[otherTriggerOutMatrix setEnabled:!lockedOrRunningMaintenance];
	[chanTriggerOutMatrix setEnabled:!lockedOrRunningMaintenance];
	[fpIOGetButton setEnabled:!lockedOrRunningMaintenance];
	[fpIOSetButton setEnabled:!lockedOrRunningMaintenance];
    [postTriggerSettingTextField setEnabled:!lockedOrRunningMaintenance];
    [triggerSourceMaskMatrix setEnabled:!lockedOrRunningMaintenance];
    [coincidenceLevelTextField setEnabled:!lockedOrRunningMaintenance];
    [countAllTriggersMatrix setEnabled:!lockedOrRunningMaintenance];
    [eventSizePopUp setEnabled:!lockedOrRunningMaintenance];
    [loadThresholdsButton setEnabled:!lockedOrRunningMaintenance];
    [initButton setEnabled:!lockedOrRunningMaintenance];
	
	//these must NOT or can not be changed when run in progress
    [customSizeTextField setEnabled:!locked && !runInProgress && [model isCustomSize]];
	[customSizeButton setEnabled:!locked && !runInProgress];
	[fixedSizeButton setEnabled:!locked && !runInProgress];
    [eventSizePopUp setEnabled:!locked && !runInProgress];
    [enabledMaskMatrix setEnabled:!locked && !runInProgress];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORDT5720SettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingsLockDocField setStringValue:s];
}

#pragma mark •••Actions

- (void) ttlEnabledAction:(id)sender
{
	[model setTtlEnabled:[[sender selectedCell] tag]];
}

- (void) gpoEnabledAction:(id)sender
{
	[model setGpoEnabled:[sender intValue]];
}

- (void) fpSoftwareTrigEnabledAction:(id)sender
{
	[model setFpSoftwareTrigEnabled:[sender intValue]];
}

- (void) fpExternalTrigEnabledAction:(id)sender
{
	[model setFpExternalTrigEnabled:[sender intValue]];
}

- (void) externalTrigEnabledAction:(id)sender
{
	[model setExternalTrigEnabled:[sender intValue]];
}

- (void) softwareTrigEnabledAction:(id)sender
{
	[model setSoftwareTrigEnabled:[sender intValue]];
}

- (void) gpiRunModeAction:(id)sender
{
	[model setGpiRunMode:[[sender selectedCell] tag]];
}

- (void) clockSourceAction:(id)sender
{
	[model setClockSource:[sender indexOfSelectedItem]];
}

- (void) trigOnUnderThresholdAction:(id)sender
{
	[model setTrigOnUnderThreshold:[[sender selectedCell] tag]];
}

- (void) testPatternEnabledAction:(id)sender
{
	[model setTestPatternEnabled:[sender intValue]];
}

- (void) trigOverlapEnabledAction:(id)sender
{
	[model setTrigOverlapEnabled:[sender intValue]];
}

- (void) zsAlgorithmAction:(id)sender
{
	[model setZsAlgorithm:[sender indexOfSelectedItem]];
}
- (IBAction) zsThresholdAction: (id) sender
{
    if ([sender intValue] != [model zsThreshold:[[sender selectedCell] tag]]){
        [[[model document] undoManager] setActionName:@"Set zsThresholds"]; // Set name of undo.
        [model setZsThreshold:[[sender selectedCell] tag] withValue:[sender intValue]]; // Set new value
    }

}

- (IBAction) thresholdAction:(id) sender
{
    if ([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
        [[[model document] undoManager] setActionName:@"Set thresholds"]; // Set name of undo.
        [model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]]; // Set new value
    }
}

- (IBAction) nLbkAction: (id) sender
{
    if ([sender intValue] != [model nLbk:[[sender selectedCell] tag]]){
        [[[model document] undoManager] setActionName:@"Set thresholds"]; // Set name of undo.
        [model setNlbk:[[sender selectedCell] tag] withValue:[sender intValue]]; // Set new value
    }
   
}

- (IBAction) nLfwdAction: (id) sender
{
    if ([sender intValue] != [model nLbk:[[sender selectedCell] tag]]){
        [[[model document] undoManager] setActionName:@"Set thresholds"]; // Set name of undo.
        [model setNlfwd:[[sender selectedCell] tag] withValue:[sender intValue]]; // Set new value
    }
    
}

- (IBAction) dacAction:(id) sender
{
    [[[model document] undoManager] setActionName:@"Set dacs"]; // Set name of undo.
    [model setDac:[[sender selectedCell] tag] withValue:[model convertVoltsToDac:[[sender selectedCell] floatValue]]]; // Set new value
}

- (IBAction) overUnderAction: (id) sender
{
    [[[model document] undoManager] setActionName:@"Set Over_Under"]; // Set name of undo.
    [model setOverUnderThreshold:[[sender selectedCell] tag] withValue:[[sender selectedCell] intValue]]; // Set new value
}

- (IBAction) logicTypeAction:(id)sender
{
	[model setLogicType:[[sender selectedCell]tag]];
}

- (void) eventSizeAction:(id)sender
{
	[model setEventSize:[sender indexOfSelectedItem]];
}

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model waveFormRateGroup]integrationTime]){
        [model setRateIntegrationTime:[sender doubleValue]];
    }
}

- (IBAction) basicReadAction:(id) pSender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		[model read];
    }
	@catch(NSException* localException) {
        NSRunAlertPanel([localException name], @"%@\nRead of %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[model selectedRegIndex]]);
    }
}

- (IBAction) basicWriteAction:(id) pSender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		[model write];
    }
	@catch(NSException* localException) {
        NSRunAlertPanel([localException name], @"%@\nWrite to %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[model selectedRegIndex]]);
    }
}

- (IBAction) writeValueAction:(id) sender
{
    // Make sure that value has changed.
    if ([sender intValue] != [model selectedRegValue]){
		[[[model document] undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setSelectedRegValue:[sender intValue]]; // Set new value
    }
}

- (IBAction) selectRegisterAction:(id) sender
{
    // Make sure that value has changed.
    if ([sender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[[model document] undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[sender indexOfSelectedItem]]; // set new value
    }
}

- (IBAction) selectChannelAction:(id) sender
{
    // Make sure that value has changed.
    if ([sender indexOfSelectedItem] != [model selectedChannel]){
		[[[model document] undoManager] setActionName:@"Select Channel"]; // Set undo name
		[model setSelectedChannel:[sender indexOfSelectedItem]]; // Set new value
    }
}
- (IBAction) basicLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORDT5720BasicLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) settingsLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORDT5720SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) reportAction: (id) sender
{
	@try {
		[model report];
	}
	@catch(NSException* localException) {
        NSRunAlertPanel([localException name], @"%@\nRead failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) loadThresholdsAction: (id) sender
{
	@try {
		[model writeThresholds];
	}
	@catch(NSException* localException) {
        NSRunAlertPanel([localException name], @"%@\nThreshold loading failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) initBoardAction: (id) sender
{
	@try {
		[model initBoard];
	}
	@catch(NSException* localException) {
        NSRunAlertPanel([localException name], @"%@\nInit failed", @"OK", nil, nil,
                        localException);
	}
}


- (void) enabledMaskAction:(id)sender
{
	int i;
	unsigned short mask = 0;
	for(i=0;i<kNumDT5720Channels;i++){
		if([[sender cellWithTag:i] intValue]) mask |= (1 << i);
	}
	[model setEnabledMask:mask];
	
}

- (void) postTriggerSettingTextFieldAction:(id)sender
{
	//todo /4 in std mode /5 in packed mode
	[model setPostTriggerSetting:([sender intValue] / 4)];
}

- (IBAction) triggerSourceMaskAction:(id)sender
{
	int i;
	unsigned long mask = 0;
	for(i=0;i<kNumDT5720Channels;i++){
		if([[chanTriggerMatrix cellWithTag:i] intValue]) mask |= (1L << i);
	}
	if([[otherTriggerMatrix cellWithTag:0] intValue]) mask |= (1L << 30);
	if([[otherTriggerMatrix cellWithTag:1] intValue]) mask |= (1L << 31);
	[model setTriggerSourceMask:mask];
}

- (IBAction) triggerOutMaskAction:(id)sender
{
	int i;
	unsigned long mask = 0;
	for(i=0;i<kNumDT5720Channels;i++){
		if([[chanTriggerOutMatrix cellWithTag:i] intValue]) mask |= (1L << i);
	}
	if([[otherTriggerOutMatrix cellWithTag:0] intValue]) mask |= (1L << 30);
	if([[otherTriggerOutMatrix cellWithTag:1] intValue]) mask |= (1L << 31);
	[model setTriggerOutMask:mask];
}

- (IBAction) fpIOGetAction:(id)sender
{
	@try {
		//[model readFrontPanelControl];
	}
	@catch(NSException* localException) {
		NSRunAlertPanel([localException name], @"%@\nGet Front Panel Failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) fpIOSetAction:(id)sender
{
	@try {
		[model writeFrontPanelControl];
	}
	@catch(NSException* localException) {
		NSRunAlertPanel([localException name], @"%@\nSet Front Panel Failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) coincidenceLevelTextFieldAction:(id)sender
{
	[model setCoincidenceLevel:[sender intValue]];
}

- (IBAction) generateTriggerAction:(id)sender
{
	@try {
		[model generateSoftwareTrigger];
	}
	@catch(NSException* localException) {
        NSRunAlertPanel([localException name], @"%@\nSoftware Trigger Failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) countAllTriggersAction:(id)sender
{
	[model setCountAllTriggers:[[sender selectedCell] tag]];
}

- (IBAction) customSizeAction:(id)sender
{
	NSUInteger maxNumSamples = (NSUInteger) 1024 * 1024./powf(2.,(float)[model eventSize]) / 2;
	if(maxNumSamples > [sender intValue]) {
		//todo /4 in std mode /5 in packed mode
		[model setCustomSize:([sender intValue] / 4)];
	}
	else {
		[model setCustomSize:maxNumSamples / 4];
	}
}

- (IBAction) isCustomSizeAction:(id)sender
{
	[model setIsCustomSize:[sender intValue]];
}

#pragma mark ***Misc Helpers
- (void) populatePullDown
{
    short	i;
	
    [registerAddressPopUp removeAllItems];
    [channelPopUp removeAllItems];
    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp insertItemWithTitle:[model
												   getRegisterName:i]
										  atIndex:i];
    }
	
	for (i = 0; i < kNumDT5720Channels ; i++) {
        [channelPopUp insertItemWithTitle:[NSString stringWithFormat:@"%d", i]
								  atIndex:i];
    }
    [channelPopUp insertItemWithTitle:@"All" atIndex:kNumDT5720Channels];
    
    [self selectedRegIndexChanged:nil];
    [self selectedRegChannelChanged:nil];
	
}

- (void) updateRegisterDescription:(short) aRegisterIndex
{
    NSString* types[] = {
		@"[ReadOnly]",
		@"[WriteOnly]",
		@"[ReadWrite]"
    };
	
    [registerOffsetTextField setStringValue:
	 [NSString stringWithFormat:@"0x%04lx",
	  [model getAddressOffset:aRegisterIndex]]];
	
    [registerReadWriteTextField setStringValue:types[[model getAccessType:aRegisterIndex]]];
    [regNameField setStringValue:[model getRegisterName:aRegisterIndex]];
	
    [drTextField setStringValue:[model dataReset:aRegisterIndex] ? @"Y" :@"N"];
    [srTextField setStringValue:[model swReset:aRegisterIndex]   ? @"Y" :@"N"];
    [hrTextField setStringValue:[model hwReset:aRegisterIndex]   ? @"Y" :@"N"];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:basicSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingsSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:monitoringSize];
		[[self window] setContentView:tabView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.%@.selectedtab",[model fullID]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

#pragma mark •••Data Source
- (double) getBarValue:(int)tag
{
	
	return [[[[model waveFormRateGroup]rates] objectAtIndex:tag] rate];
}

- (int) numberPointsInPlot:(id)aPlotter
{
	return [[[model waveFormRateGroup]timeRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	int count = [[[model waveFormRateGroup]timeRate] count];
	int index = count-i-1;
	*yValue = [[[model waveFormRateGroup] timeRate] valueAtIndex:index];
	*xValue = [[[model waveFormRateGroup] timeRate] timeSampledAtIndex:index];
}

#pragma mark •••Actions

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORDT5720ModelLock to:[sender intValue] forWindow:[self window]];
}


- (void) validateInterfacePopup
{
	NSArray* interfaces = [[model getUSBController] interfacesForVender:[model vendorID] product:[model productID]];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([anInterface registeredObject] == nil || [serialNumber isEqualToString:[model serialNumber]]){
			[[serialNumberPopup itemWithTitle:serialNumber] setEnabled:YES];
		}
		else [[serialNumberPopup itemWithTitle:serialNumber] setEnabled:NO];
		
	}
}

- (IBAction) serialNumberAction:(id)sender
{
	if([serialNumberPopup indexOfSelectedItem] == 0){
		[model setSerialNumber:nil];
	}
	else {
		[model setSerialNumber:[serialNumberPopup titleOfSelectedItem]];
	}
	
}

@end

@implementation ORDT5720Controller (private)

- (void) populateInterfacePopup:(ORUSB*)usb
{
    [[self undoManager] disableUndoRegistration];
	NSArray* interfaces = [usb interfacesForVender:[model vendorID] product:[model productID]];
	[serialNumberPopup removeAllItems];
	[serialNumberPopup addItemWithTitle:@"N/A"];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([serialNumber length]){
			[serialNumberPopup addItemWithTitle:serialNumber];
		}
	}
	[self validateInterfacePopup];
	if([model serialNumber]){
		[serialNumberPopup selectItemWithTitle:[model serialNumber]];
	}
	else [serialNumberPopup selectItemAtIndex:0];
    [[self undoManager] enableUndoRegistration];
	
}

@end

