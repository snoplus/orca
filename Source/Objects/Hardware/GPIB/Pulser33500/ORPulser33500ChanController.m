//
//  ORPulser33500ChanController.m
//  Orca
//
//  Created by Mark Howe on Thurs, Oct 25 2012.
//  Copyright (c) 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORPulser33500ChanController.h"
#import "ORPulser33500Chan.h"
#import "ORPulser33500Model.h"
#import "ORPulser33500Controller.h"
#import "ORPlot.h"
#import "ORAxis.h"
#import "ORCompositePlotView.h"

@interface ORPulser33500ChanController (private)
- (void) _clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // pre 10.6-specific
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
#endif
- (void) populateWaveformSelectionPU;
@end

@implementation ORPulser33500ChanController

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (id) model
{
	return model;
}
- (void) setModel:(id)aModel
{
	model = aModel;
	[self populateWaveformSelectionPU];
	[self registerNotificationObservers];
	[self updateWindow];
}

- (void) awakeFromNib
{		
	if(!controlsContent){
		if ([NSBundle loadNibNamed:@"Pulser33500Chan" owner:self]){
			[controlsView setContentView:controlsContent];
		}	
		else NSLog(@"Failed to load Pulser33500Chan.nib");
	}
	NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease];
	[formatter setFormat:@"#0.00"];	
	[frequencyField setFormatter:formatter];
	[burstRateField setFormatter:formatter];

	NSNumberFormatter* mFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[mFormatter setFormat:@"#0.000"];	
	[voltageField setFormatter:mFormatter];
	[voltageOffsetField setFormatter:mFormatter];

	
	NSNumberFormatter* uFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[uFormatter setFormat:@"#0.000000"];	
	[triggerTimerField setFormatter:uFormatter];
	
	int i;
	for(i=0;i<[model numberOfWaveforms];i++) {
        [selectedWaveformPU addItemWithTitle:[model nameOfWaveformAt:i]];
    }
	[[plotter yAxis] setRngLimitsLow:-1 withHigh:1 withMinRng:2];
	[plotter setShowGrid:NO];
	ORPlot* aPlot= [[ORPlot alloc] initWithTag:0 andDataSource:self];
	[plotter addPlot: aPlot];
	[aPlot release];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];  
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[notifyCenter addObserver : self
                     selector : @selector(voltageChanged:)
                         name : ORPulser33500ChanVoltageChanged
                       object : model];

	[notifyCenter addObserver : self
                     selector : @selector(voltageOffsetChanged:)
                         name : ORPulser33500ChanVoltageOffsetChanged
                       object : model];
	
	
	[notifyCenter addObserver : self
                     selector : @selector(frequencyChanged:)
                         name : ORPulser33500ChanFrequencyChanged
                       object : model];

	[notifyCenter addObserver : self
                     selector : @selector(burstRateChanged:)
                         name : ORPulser33500ChanBurstRateChanged
                       object : model];

	[notifyCenter addObserver : self
                     selector : @selector(burstPhaseChanged:)
                         name : ORPulser33500ChanBurstPhaseChanged
                       object : model];
	
	
	[notifyCenter addObserver : self
                     selector : @selector(burstCountChanged:)
                         name : ORPulser33500ChanBurstCountChanged
                       object : model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(triggerSourceChanged:)
                         name : ORPulser33500ChanTriggerSourceChanged
                       object : model];		

	[notifyCenter addObserver : self
                     selector : @selector(triggerTimerChanged:)
                         name : ORPulser33500ChanTriggerTimerChanged
                       object : model];		

	[notifyCenter addObserver : self
                     selector : @selector(selectedWaveformChanged:)
                         name : ORPulser33500ChanSelectedWaveformChanged
                       object : model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(negativePulseChanged:)
                         name : ORPulser33500NegativePulseChanged
						object: model];
	

	[notifyCenter addObserver : self
                     selector : @selector(waveformLoadStarted:)
                         name : ORPulser33500WaveformLoadStarted
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(waveformLoadProgressing:)
                         name : ORPulser33500WaveformLoadProgressing
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(waveformLoadFinished:)
                         name : ORPulser33500WaveformLoadFinished
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORPulser33500ChanFrequencyChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORPulser33500ChanBurstRateChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(setButtonStates)
                         name : ORPulser33500LoadingChanged
                       object : [model pulser]];
	
	
	
}

- (void) updateWindow
{    
	[self voltageChanged:nil];
	[self voltageOffsetChanged:nil];
    [self frequencyChanged:nil];
    [self burstRateChanged:nil];
    [self burstPhaseChanged:nil];
    [self burstCountChanged:nil];
    [self triggerSourceChanged:nil];
    [self triggerTimerChanged:nil];
    [self selectedWaveformChanged:nil];
	[self negativePulseChanged:nil];
    [self loadConstantsChanged:nil];

}

#pragma mark •••Notifications

- (void) loadConstantsChanged:(NSNotification*)aNotification
{
	if([model selectedWaveform] == kLogCalibrationWaveform){
		[voltageDisplay setFloatValue:kCalibrationVoltage];
		//[totalWidthDisplay setFloatValue:kCalibrationWidth];
		[burstRateDisplay setFloatValue:kCalibrationBurstRate];
	}
	else {
		[voltageDisplay setFloatValue:[model voltage]];
		//[totalWidthDisplay setFloatValue:[model totalWidth]];
		[burstRateDisplay setFloatValue:[model burstRate]];
	}
}

- (void) negativePulseChanged:(NSNotification*)aNote
{
	[negativePulseMatrix selectCellWithTag:[model negativePulse]];
}

- (void) selectedWaveformChanged:(NSNotification*)aNotification
{
	[selectedWaveformPU selectItemAtIndex:[model selectedWaveform]];
}

- (void) triggerTimerChanged:(NSNotification*)aNotification
{
	[triggerTimerField setFloatValue: [model triggerTimer]];
}

- (void) triggerSourceChanged:(NSNotification*)aNotification
{
	[triggerSourceMatrix selectCellWithTag: [model triggerSource]];
	[self setButtonStates];
}

- (void) voltageChanged:(NSNotification*)aNotification
{
	[voltageField setFloatValue:[model voltage]];
}

- (void) voltageOffsetChanged:(NSNotification*)aNotification
{
	[voltageOffsetField setFloatValue:[model voltageOffset]];
}

- (void) frequencyChanged:(NSNotification*)aNotification
{
	[frequencyField setFloatValue:[model frequency]];
}

- (void) burstPhaseChanged:(NSNotification*)aNotification
{
	[burstPhaseField setFloatValue:[model burstPhase]];
}

- (void) burstRateChanged:(NSNotification*)aNotification
{
	[burstRateField setFloatValue:[model burstRate]];
}

- (void) burstCountChanged:(NSNotification*)aNotification
{
	[burstCountField setFloatValue:[model burstCount]];
}


- (void) setButtonStates
{		
    //BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORPulser33500Lock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORPulser33500Lock];
	BOOL triggerModeIsSoftware		= [model triggerSource] == kSoftwareTrigger;
	BOOL triggerModeIsTimer			= [model triggerSource] == kTimerTrigger;
    BOOL selfLoading				= [model loading];
	BOOL somebodyLoading			= [[model pulser]loading];

    [downloadButton setTitle: selfLoading ? @"Stop":@"Load"];
	[downloadButton setEnabled:!locked && (selfLoading || !somebodyLoading)];
	
    [triggerButton setEnabled:!somebodyLoading && !lockedOrRunningMaintenance && triggerModeIsSoftware];
    [triggerTimerField setEnabled:!somebodyLoading && !lockedOrRunningMaintenance && triggerModeIsTimer];
    [voltageField setEnabled:!somebodyLoading && !lockedOrRunningMaintenance];
    [voltageOffsetField setEnabled:!somebodyLoading && !lockedOrRunningMaintenance];
    [frequencyField setEnabled:!somebodyLoading && !lockedOrRunningMaintenance];
    [burstRateField setEnabled:!somebodyLoading && !lockedOrRunningMaintenance];
    [burstPhaseField setEnabled:!somebodyLoading && !lockedOrRunningMaintenance];
    [burstCountField setEnabled:!somebodyLoading && !lockedOrRunningMaintenance];
	[triggerSourceMatrix setEnabled:!somebodyLoading && !lockedOrRunningMaintenance];
    [negativePulseMatrix setEnabled:!somebodyLoading && !lockedOrRunningMaintenance];
    [selectedWaveformPU setEnabled:!somebodyLoading && !locked];
    [burstPhaseField setEnabled:!somebodyLoading && !locked];
    [loadParametersButton setEnabled:!somebodyLoading && !somebodyLoading];
}

- (void) waveformLoadStarted:(NSNotification*)aNotification
{        
	[self setButtonStates];
	
	int mx = [model numPoints];
	
	[[plotter yAxis] setRngLimitsLow:-1 withHigh:1 withMinRng:2];
	[[plotter yAxis] setRngLow:-1 withHigh:1];
	//[[plotter yAxis] setFullRng];
	
	[[plotter xAxis] setRngLimitsLow:0 withHigh:mx withMinRng:mx];
	[[plotter xAxis] setRngLow:0 withHigh:mx];
	//[[plotter xAxis] setFullRng];
	
	
	[[plotter yAxis] setNeedsDisplay:YES];
	[[plotter xAxis] setNeedsDisplay:YES];
	[plotter setNeedsDisplay:YES];
}

- (void) waveformLoadProgressing:(NSNotification*)aNotification
{
	[progress setDoubleValue:[model downloadIndex]]; 
}

- (void) waveformLoadFinished:(NSNotification*)aNotification
{	
	[self setButtonStates];
	
	[progress setIndeterminate:NO];
	[progress stopAnimation:self];
	[progress setMaxValue:100];
	[progress setDoubleValue:0];
}


#pragma mark •••Actions
- (IBAction) negativePulseAction:(id)sender
{
	if([[sender selectedCell] tag] != [model negativePulse]){
		[model setNegativePulse:[[sender selectedCell] tag]];
	}
}

- (IBAction) selectWaveformAction:(id)sender;
{
    if([sender indexOfSelectedItem] != [model selectedWaveform]){ 	
        [model setSelectedWaveform:[sender indexOfSelectedItem]];
    }
} 

- (IBAction) voltageAction:(id)sender
{
	[model setVoltage:[sender floatValue]];	
}

- (IBAction) voltageOffsetAction:(id)sender
{
	[model setVoltageOffset:[sender floatValue]];	
}

- (IBAction) frequencyAction:(id)sender
{
	[model setFrequency:[sender floatValue]];	
}

- (IBAction) burstRateAction:(id)sender
{
	[model setBurstRate:[sender floatValue]];	
}

- (IBAction) burstPhaseAction:(id)sender
{
	[model setBurstPhase:[sender floatValue]];	
}

- (IBAction) burstCountAction:(id)sender
{
	[model setBurstCount:[sender intValue]];	
}

- (IBAction) loadParametersAction:(id)sender
{
	[owner endEditing];
	[model initHardware];
}

- (IBAction) triggerSourceAction:(id)sender
{
	@try {
		if([[sender selectedCell] tag] != [model triggerSource]){
			[model setTriggerSource:[[sender selectedCell]tag]];	
			[model writeTriggerSource];    
		}
	}
	@catch(NSException* localException) {
		[self showExceptionAlert:localException];
	}
}
- (IBAction) triggerAction:(id)sender
{
	@try {
		[model trigger];
	}
	@catch(NSException* localException) {
		[self showExceptionAlert:localException];
	}
}

- (IBAction) triggerTimerAction:(id)sender
{
	[model setTriggerTimer:[sender floatValue]];	
}

- (void) showExceptionAlert:(NSException*) localException
{
	NSLog( [ localException reason ] );
	NSRunAlertPanel( [ localException name ], 	// Name of panel
					[ localException reason ],	// Reason for error
					@"OK",				// Okay button
					nil,				// alternate button
					nil );				// other button
}

- (IBAction) clearMemory:(id)sender
{
    NSBeginAlertSheet([NSString stringWithFormat:@"Clear Channel%d Non-Volatile Memory",(ORPulser33500Chan*)[model channel]],
                      @"YES/Do it NOW",
                      @"Canel",
                      nil,[owner window],
                      self,
                      @selector(_clearSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,
                      @"Really Clear the Non-Volatile Memory?");
    
    
}

-(IBAction) downloadWaveformAction:(id)sender
{
    if([model selectedWaveform] == kWaveformFromFile){
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setCanChooseFiles:YES];
        [openPanel setAllowsMultipleSelection:NO];
        [openPanel setPrompt:@"Download"];
        
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
        [openPanel setDirectoryURL:[NSURL URLWithString:NSHomeDirectory()]];
        [openPanel beginSheetModalForWindow:[owner window] completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton) {
                NSString* fileName = [[[openPanel URL]path] stringByAbbreviatingWithTildeInPath];
                [model setFileName:fileName];
                [self performSelector:@selector(downloadWaveform) withObject:self afterDelay:0.1];
                NSLog(@"Downloading Waveform: %@\n",fileName);
			}
        }];
#else	
        [openPanel beginSheetForDirectory:NSHomeDirectory()
                                     file:nil
                                    types:nil
                           modalForWindow:[self window]
                            modalDelegate:self
                           didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                              contextInfo:NULL];
#endif
    }
    else {
		[self downloadWaveform];
		NSLog(@"Downloading Waveform: %@\n",[selectedWaveformPU titleOfSelectedItem]);
    }
}

-(void) downloadWaveform
{
    @try {
        [owner endEditing];
        
        if(![model loading]){
            [model downloadWaveform];
            [progress setMaxValue:[model numPoints]];
            [progress setDoubleValue:0];
        }
        else {
            [downloadButton setEnabled:NO];
            [model stopDownload];
            [progress setDoubleValue:0];
        }
        
	}
	@catch(NSException* localException) {
		[model stopDownload];
		[progress stopAnimation:self];
		[progress setIndeterminate:NO];
		[progress setDoubleValue:0];
		NSLog( [ localException reason ] );
		NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}


#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
    return [model numPoints];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
    float* d = (float*)[[model waveform] mutableBytes];
    *yValue = (double)d[i];
	*xValue = i;
}

@end

@implementation ORPulser33500ChanController (private)

#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // pre 10.6-specific
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* fileName = [[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath];
        [model setFileName:fileName];
        [self performSelector:@selector(downloadWaveform) withObject:self afterDelay:0.1];
		NSLog(@"Downloading Waveform: %@\n",fileName);
		
    }
}
#endif

- (void) _clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
    if(returnCode == NSAlertDefaultReturn){
		@try {
			[model emptyVolatileMemory];
		}
		@catch(NSException* localException) {
			NSLog( [ localException reason ] );
			NSRunAlertPanel( [ localException name ], 	// Name of panel
							[ localException reason ],	// Reason for error
							@"OK",				// Okay button
							nil,				// alternate button
							nil );				// other button
		}
    }
}

- (void) populateWaveformSelectionPU
{
	if(model){
		[selectedWaveformPU removeAllItems];
		int i;
		for(i=0;i<kNumWaveforms;i++){
			[selectedWaveformPU addItemWithTitle:[model nameOfWaveformAt:i]];
		}
	}
}

@end

