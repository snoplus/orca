//
//  ORHP4405AController.m
//  Orca
//
//  Created by Mark Howe on Wed Jul28, 2010.
//  Copyright 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina at the UNC Physics Dept sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORHP4405AController.h"
#import "ORHP4405AModel.h"

@implementation ORHP4405AController

#pragma mark ¥¥¥Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"ORHP4405A" ];
    return self;
}

#pragma mark ***Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
	
    [ notifyCenter addObserver: self
                      selector: @selector( lockChanged: )
                          name: ORRunStatusChangedNotification
                        object: nil];
    
	[notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORHP4405ALock
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(centerFreqChanged:)
                         name : ORHP4405AModelCenterFreqChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(startFreqChanged:)
                         name : ORHP4405AModelStartFreqChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(stopFreqChanged:)
                         name : ORHP4405AModelStopFreqChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(unitsChanged:)
                         name : ORHP4405AModelUnitsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(freqStepSizeChanged:)
                         name : ORHP4405AModelFreqStepSizeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(freqStepDirChanged:)
                         name : ORHP4405AModelFreqStepDirChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerDelayChanged:)
                         name : ORHP4405AModelTriggerDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerDelayEnabledChanged:)
                         name : ORHP4405AModelTriggerDelayEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerSlopeChanged:)
                         name : ORHP4405AModelTriggerSlopeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerOffsetChanged:)
                         name : ORHP4405AModelTriggerOffsetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerOffsetEnabledChanged:)
                         name : ORHP4405AModelTriggerOffsetEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerSourceChanged:)
                         name : ORHP4405AModelTriggerSourceChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerDelayUnitsChanged:)
                         name : ORHP4405AModelTriggerDelayUnitsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerOffsetUnitsChanged:)
                         name : ORHP4405AModelTriggerOffsetUnitsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(burstFreqEnabledChanged:)
                         name : ORHP4405AModelBurstFreqEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(burstModeSettingChanged:)
                         name : ORHP4405AModelBurstModeSettingChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(burstModeAbsChanged:)
                         name : ORHP4405AModelBurstModeAbsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(burstPulseDiscrimEnabledChanged:)
                         name : ORHP4405AModelBurstPulseDiscrimEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(detectorGainEnabledChanged:)
                         name : ORHP4405AModelDetectorGainEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(inputAttenuationChanged:)
                         name : ORHP4405AModelInputAttenuationChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(inputAttAutoEnabledChanged:)
                         name : ORHP4405AModelInputAttAutoEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(inputGainEnabledChanged:)
                         name : ORHP4405AModelInputGainEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(inputMaxMixerPowerChanged:)
                         name : ORHP4405AModelInputMaxMixerPowerChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(optimizePreselectorFreqChanged:)
                         name : ORHP4405AModelOptimizePreselectorFreqChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(continuousMeasurementChanged:)
                         name : ORHP4405AModelContinuousMeasurementChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(statusRegChanged:)
                         name : ORHP4405AModelStatusRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(standardEventRegChanged:)
                         name : ORHP4405AModelStandardEventRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(questionableCalibrationRegChanged:)
                         name : ORHP4405AModelQuestionableCalibrationRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(questionableConditionRegChanged:)
                         name : ORHP4405AModelQuestionableConditionRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(questionableEventRegChanged:)
                         name : ORHP4405AModelQuestionableEventRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(questionableFreqRegChanged:)
                         name : ORHP4405AModelQuestionableFreqRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(questionableIntegrityRegChanged:)
                         name : ORHP4405AModelQuestionableIntegrityRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(questionablePowerRegChanged:)
                         name : ORHP4405AModelQuestionablePowerRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(statusOperationRegChanged:)
                         name : ORHP4405AModelStatusOperationRegChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(measurementInProgressChanged:)
                         name : ORHP4405AModelMeasurementInProgressChanged
						object: model];
}

- (void) updateWindow
{
    [ super updateWindow ];
	[self centerFreqChanged:nil];
	[self startFreqChanged:nil];
	[self stopFreqChanged:nil];
	[self unitsChanged:nil];
	[self freqStepSizeChanged:nil];
	[self freqStepDirChanged:nil];
	[self triggerDelayChanged:nil];
	[self triggerDelayEnabledChanged:nil];
	[self triggerSlopeChanged:nil];
	[self triggerOffsetChanged:nil];
	[self triggerOffsetEnabledChanged:nil];
	[self triggerSourceChanged:nil];
	[self triggerDelayUnitsChanged:nil];
	[self triggerOffsetUnitsChanged:nil];
	[self burstFreqEnabledChanged:nil];
	[self burstModeSettingChanged:nil];
	[self burstModeAbsChanged:nil];
	[self burstPulseDiscrimEnabledChanged:nil];
	[self detectorGainEnabledChanged:nil];
	[self inputAttenuationChanged:nil];
	[self inputAttAutoEnabledChanged:nil];
	[self inputGainEnabledChanged:nil];
	[self inputMaxMixerPowerChanged:nil];
	[self optimizePreselectorFreqChanged:nil];
	[self continuousMeasurementChanged:nil];
	[self statusRegChanged:nil];
	[self standardEventRegChanged:nil];
	[self questionableCalibrationRegChanged:nil];
	[self questionableConditionRegChanged:nil];
	[self questionableEventRegChanged:nil];
	[self questionableFreqRegChanged:nil];
	[self questionableIntegrityRegChanged:nil];
	[self questionablePowerRegChanged:nil];
	[self statusOperationRegChanged:nil];
	[self measurementInProgressChanged:nil];
    [self lockChanged:nil];
}

- (void) lockChanged: (NSNotification*) aNotification
{
}



#pragma mark ***Interface Management
- (void) measurementInProgressChanged: (NSNotification*) aNotification
{
	BOOL measuring = [model measurementInProgress];
	[startMeasurementButton setEnabled: !measuring];
	[continuousMeasurementCB setEnabled: !measuring];
	[stopMeasurementButton setEnabled: measuring];
}

- (void) statusOperationRegChanged:(NSNotification*)aNote
{
	NSLog(@"status Op: 0x%x\n",[model statusOperationReg]);
}

- (void) questionablePowerRegChanged:(NSNotification*)aNote
{
}

- (void) questionableIntegrityRegChanged:(NSNotification*)aNote
{
}

- (void) questionableFreqRegChanged:(NSNotification*)aNote
{
}

- (void) questionableEventRegChanged:(NSNotification*)aNote
{
}

- (void) questionableConditionRegChanged:(NSNotification*)aNote
{
}

- (void) questionableCalibrationRegChanged:(NSNotification*)aNote
{
}

- (void) standardEventRegChanged:(NSNotification*)aNote
{
	NSLog(@"standard event: 0x%0x\n",[model standardEventReg]);
}

- (void) statusRegChanged:(NSNotification*)aNote
{
	NSLog(@"status event: 0x%0x\n",[model statusReg]);
}

- (void) continuousMeasurementChanged:(NSNotification*)aNote
{
	[continuousMeasurementCB setIntValue: [model continuousMeasurement]];
}

- (void) optimizePreselectorFreqChanged:(NSNotification*)aNote
{
	[optimizePreselectorFreqField setIntValue: [model optimizePreselectorFreq]];
}

- (void) inputMaxMixerPowerChanged:(NSNotification*)aNote
{
	[inputMaxMixerPowerField setIntValue: [model inputMaxMixerPower]];
}

- (void) inputGainEnabledChanged:(NSNotification*)aNote
{
	[inputGainEnabledCB setIntValue: [model inputGainEnabled]];
}

- (void) inputAttAutoEnabledChanged:(NSNotification*)aNote
{
	[inputAttAutoEnabledCB setIntValue: [model inputAttAutoEnabled]];
}

- (void) inputAttenuationChanged:(NSNotification*)aNote
{
	[inputAttenuationField setIntValue: [model inputAttenuation]];
}

- (void) detectorGainEnabledChanged:(NSNotification*)aNote
{
	[detectorGainEnabledCB setIntValue: [model detectorGainEnabled]];
}

- (void) burstPulseDiscrimEnabledChanged:(NSNotification*)aNote
{
	[burstPulseDiscrimEnabledCB setIntValue: [model burstPulseDiscrimEnabled]];
}

- (void) burstModeAbsChanged:(NSNotification*)aNote
{
	[burstModeAbsPU setIntValue: [model burstModeAbs]];
}

- (void) burstModeSettingChanged:(NSNotification*)aNote
{
	[burstModeSettingField setIntValue: [model burstModeSetting]];
}

- (void) burstFreqEnabledChanged:(NSNotification*)aNote
{
	[burstFreqEnabledCB setIntValue: [model burstFreqEnabled]];
}

- (void) triggerOffsetUnitsChanged:(NSNotification*)aNote
{
	[triggerOffsetUnitsPU selectItemAtIndex: [model triggerOffsetUnits]];
}

- (void) triggerDelayUnitsChanged:(NSNotification*)aNote
{
	[triggerDelayUnitsPU selectItemAtIndex: [model triggerDelayUnits]];
}

- (void) triggerSourceChanged:(NSNotification*)aNote
{
	[triggerSourcePU selectItemAtIndex: [model triggerSource]];
}

- (void) triggerOffsetEnabledChanged:(NSNotification*)aNote
{
	[triggerOffsetEnabledCB setIntValue: [model triggerOffsetEnabled]];
}

- (void) triggerOffsetChanged:(NSNotification*)aNote
{
	[triggerOffsetField setFloatValue: [model triggerOffset]];
}

- (void) triggerSlopeChanged:(NSNotification*)aNote
{
	[triggerSlopePU setIntValue: [model triggerSlope]];
}

- (void) triggerDelayEnabledChanged:(NSNotification*)aNote
{
	[triggerDelayEnableCB setFloatValue: [model triggerDelayEnabled]];
}

- (void) triggerDelayChanged:(NSNotification*)aNote
{
	[triggerDelayField setFloatValue: [model triggerDelay]];
}

- (void) freqStepDirChanged:(NSNotification*)aNote
{
	[freqStepDirPU selectItemAtIndex: [model freqStepDir]];
}

- (void) freqStepSizeChanged:(NSNotification*)aNote
{
	[freqStepSizeField setFloatValue: [model freqStepSize]];
}
- (void) unitsChanged:(NSNotification*)aNote
{
	[unitsPU selectItemAtIndex: [model units]];
}

- (void) stopFreqChanged:(NSNotification*)aNote
{
	[stopFreqField setFloatValue: [model stopFreq]];
}

- (void) startFreqChanged:(NSNotification*)aNote
{
	[startFreqField setFloatValue: [model startFreq]];
}

- (void) centerFreqChanged:(NSNotification*)aNote
{
	[centerFreqField setFloatValue: [model centerFreq]];
}

#pragma mark ¥¥¥Actions

- (void) continuousMeasurementAction:(id)sender
{
	[model setContinuousMeasurement:[sender intValue]];	
}

- (void) optimizePreselectorFreqAction:(id)sender
{
	[model setOptimizePreselectorFreq:[sender intValue]];	
}

- (void) inputMaxMixerPowerAction:(id)sender
{
	[model setInputMaxMixerPower:[sender intValue]];	
}

- (void) inputGainEnabledAction:(id)sender
{
	[model setInputGainEnabled:[sender intValue]];	
}

- (void) inputAttAutoEnabledAction:(id)sender
{
	[model setInputAttAutoEnabled:[sender intValue]];	
}

- (void) inputAttenuationAction:(id)sender
{
	[model setInputAttenuation:[sender intValue]];	
}

- (void) detectorGainEnabledAction:(id)sender
{
	[model setDetectorGainEnabled:[sender intValue]];	
}

- (IBAction) burstPulseDiscrimEnabledAction:(id)sender
{
	[model setBurstPulseDiscrimEnabled:[sender intValue]];	
}

- (IBAction) burstModeAbsAction:(id)sender
{
	[model setBurstModeAbs:[sender indexOfSelectedItem]];	
}

- (IBAction) burstModeSettingAction:(id)sender
{
	[model setBurstModeSetting:[sender intValue]];	
}

- (void) burstFreqEnabledAction:(id)sender
{
	[model setBurstFreqEnabled:[sender intValue]];	
}

- (IBAction) triggerOffsetUnitsAction:(id)sender
{
	[model setTriggerOffsetUnits:[sender indexOfSelectedItem]];	
}

- (IBAction) triggerDelayUnitsAction:(id)sender
{
	[model setTriggerDelayUnits:[sender indexOfSelectedItem]];	
}

- (IBAction) triggerSourceAction:(id)sender
{
	[model setTriggerSource:[sender indexOfSelectedItem]];	
}

- (IBAction) triggerOffsetEnabledAction:(id)sender
{
	[model setTriggerOffsetEnabled:[sender intValue]];	
}

- (IBAction) triggerOffsetAction:(id)sender
{
	[model setTriggerOffset:[sender floatValue]];	
}

- (IBAction) triggerSlopeAction:(id)sender
{
	[model setTriggerSlope:[sender indexOfSelectedItem]];	
}

- (IBAction) triggerDelayEnabledAction:(id)sender
{
	[model setTriggerDelayEnabled:[sender intValue]];	
}

- (IBAction) triggerDelayAction:(id)sender
{
	[model setTriggerDelay:[sender floatValue]];	
}

- (IBAction) freqStepDirAction:(id)sender
{
	[model setFreqStepDir:[sender indexOfSelectedItem]];	
}

- (IBAction) freqStepSizeAction:(id)sender
{
	[model setFreqStepSize:[sender floatValue]];	
}

- (IBAction) unitsAction:(id)sender
{
	[model setUnits:[sender indexOfSelectedItem]];	
}

- (IBAction) stopFreqAction:(id)sender
{
	[model setStopFreq:[sender floatValue]];	
}

- (IBAction) startFreqAction:(id)sender
{
	[model setStartFreq:[sender floatValue]];	
}

- (IBAction) centerFreqAction:(id)sender
{
	[model setCenterFreq:[sender floatValue]];	
}

#pragma mark ¥¥¥Hardware Actions
- (IBAction) loadFreqSettingsAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadFreqSettings];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A Freq Settings Load Failed");
        NSRunAlertPanel( @"HP4405A Freq Settings Load Failed",
						[localException reason],
						@"OK",
						nil,
						nil );
	}
}

- (IBAction) loadTriggerSettingsAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadTriggerSettings];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A Trigger Settings Load Failed");
        NSRunAlertPanel( @"HP4405A Trigger Settings Load Failed",
						[localException reason],
						@"OK",
						nil,
						nil );
	}
}

- (IBAction) loadRFBurstSettingsAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadRFBurstSettings];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A RF Burst Settings Load Failed");
        NSRunAlertPanel( @"HP4405A RF Burst Settings Load Failed",
						[localException reason],
						@"OK",
						nil,
						nil );
	}
}
- (IBAction) loadInputPortSettingsAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadInputPortSettings];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A Input Port Settings Load Failed");
        NSRunAlertPanel( @"HP4405A Input Port Settings Load Failed",
						[localException reason],
						@"OK",
						nil,
						nil );
	}
}

- (IBAction) startMeasuremnt:(id)sender
{
	@try {
		[self endEditing];
		[model initiateMeasurement];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A Initiate Measurement Failed");
        NSRunAlertPanel( @"HP4405A Initiate Measurement Failed",
						[localException reason],
						@"OK",
						nil,
						nil );
	}
}

- (IBAction) pauseMeasuremnt:(id)sender
{
	@try {
		[self endEditing];
		[model pauseMeasurement];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A Pause Measurement Failed");
        NSRunAlertPanel( @"HP4405A Pause Measurement Failed",
						[localException reason],
						@"OK",
						nil,
						nil );
	}
}

- (IBAction) checkStatusAction:(id)sender;
{
	@try {
		[self endEditing];
		[model checkStatus];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A Check Status Failed");
        NSRunAlertPanel( @"HP4405A Check Status Failed",
						[localException reason],
						@"OK",
						nil,
						nil );
	}
}

@end
