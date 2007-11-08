//
//  ORHPPulserController.m
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORHPPulserController.h"
#import "ORHPPulserModel.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"


@interface ORHPPulserController (private)
- (void) _clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (void) systemTest;
@end

@implementation ORHPPulserController
- (id) init
{
    self = [ super initWithWindowNibName: @"HPPulser" ];
    return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[yScale setRngLimitsLow:-1 withHigh:1 withMinRng:2];
}


- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(triggerModeChanged:)
                         name : ORHPPulserTriggerModeChangedNotification
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(voltageChanged:)
                         name : ORHPPulserVoltageChangedNotification
                       object : model];
					   
	[notifyCenter addObserver : self
                     selector : @selector(voltageOffsetChanged:)
                         name : ORHPPulserVoltageOffsetChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(burstRateChanged:)
                         name : ORHPPulserBurstRateChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(totalWidthChanged:)
                         name : ORHPPulserTotalWidthChangedNotification
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(selectedWaveformChanged:)
                         name : ORHPPulserSelectedWaveformChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORHPPulserVoltageChangedNotification
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORHPPulserVoltageOffsetChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORHPPulserBurstRateChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORHPPulserTotalWidthChangedNotification
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORHPPulserSelectedWaveformChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(waveformLoadStarted:)
                         name : ORHPPulserWaveformLoadStartedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(waveformLoadProgressing:)
                         name : ORHPPulserWaveformLoadProgressingNotification
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(waveformLoadFinished:)
                         name : ORHPPulserWaveformLoadFinishedNotification
                       object : model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( lockChanged: )
                          name: ORRunStatusChangedNotification
                        object: nil];
    
    [ notifyCenter addObserver: self
                      selector: @selector( nonVolatileChanged: )
                          name: ORHPPulserWaveformLoadingNonVoltileNotification
                        object: model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( volatileChanged: )
                          name: ORHPPulserWaveformLoadingVoltileNotification
                        object: model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : [model dialogLock]
                        object: model];
    
	
	[notifyCenter addObserver : self
					  selector: @selector(enableRandomChanged:)
						  name: ORHPPulserEnableRandomChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(minTimeChanged:)
						  name: ORHPPulserMinTimeChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(maxTimeChanged:)
						  name: ORHPPulserMaxTimeChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(randomCountChanged:)
						  name: ORHPPulserRandomCountChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(lockChanged:)
						  name: ORHPPulserModelLockGUIChanged
					   object : model];


    [notifyCenter addObserver : self
                     selector : @selector(negativePulseChanged:)
                         name : ORHPPulserModelNegativePulseChanged
						object: model];

}

- (void) updateWindow
{
    [ super updateWindow ];
    
    [self voltageChanged:nil];
    [self voltageOffsetChanged:nil];
    [self burstRateChanged:nil];
    [self totalWidthChanged:nil];
    [self selectedWaveformChanged:nil];
    [self loadConstantsChanged:nil];
    [self lockChanged:nil];
	[self enableRandomChanged:nil];
	[self minTimeChanged:nil];
	[self maxTimeChanged:nil];
	[self randomCountChanged:nil];
    [self triggerModeChanged:nil];
	[self negativePulseChanged:nil];
}

- (void) negativePulseChanged:(NSNotification*)aNote
{
	[negativePulseMatrix selectCellWithTag:[model negativePulse]];
}


#pragma mark •••Actions
- (IBAction) negativePulseAction:(id)sender
{
	if([[sender selectedCell] tag] != [model negativePulse]){
		[model setNegativePulse:[[sender selectedCell] tag]];
	}
}

- (IBAction) sendCommandAction:(id)sender
{
	NS_DURING
		[self endEditing];
		NSString* cmd = [commandField stringValue];
		if(cmd){
			if([cmd rangeOfString:@"?"].location != NSNotFound){
				char reply[1024];
				long n = [model writeReadGPIBDevice:cmd data:reply maxLength:1024];
				if(n>0)reply[n-1]='\0';
				NSLog(@"%s\n",reply);
			}
			else {
				[model writeToGPIBDevice:[commandField stringValue]];
			}
		}
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER

}

- (IBAction) clearMemory:(id)sender
{
    NSBeginAlertSheet(@"Clear Pulser Non-Volatile Memory",
                      @"YES/Do it NOW",
                      @"Canel",
                      nil,[self window],
                      self,
                      @selector(_clearSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,
                      @"Really Clear the Non-Volatile Memory in Pulser?");
    
    
}

- (void) _clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
    if(returnCode == NSAlertDefaultReturn){
		NS_DURING
			[model emptyVolatileMemory];
		NS_HANDLER
			NSLog( [ localException reason ] );
			NSRunAlertPanel( [ localException name ], 	// Name of panel
							 [ localException reason ],	// Reason for error
							 @"OK",				// Okay button
							 nil,				// alternate button
							 nil );				// other button
		NS_ENDHANDLER
    }
}

-(IBAction) readIdAction:(id)sender
{
	NS_DURING
		NSLog(@"Pulser Id: %@\n",[model readIDString]);
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

-(IBAction) resetAction:(id)sender
{
	NS_DURING
	    [model resetAndClear];
	    NSLog(@"HPPulser Reset and Clear successful.\n");
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

-(IBAction) testAction:(id)sender
{
	NSLog(@"Testing HP Pulser (takes a few seconds...).\n");
	[self performSelector:@selector(systemTest) withObject:nil afterDelay:0];
}

- (void) systemTest
{
	NS_DURING
	    [model systemTest];
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

-(IBAction) loadParamsAction:(id)sender
{
    [self endEditing];
	NS_DURING
		[model outputWaveformParams];
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}


-(IBAction) downloadWaveformAction:(id)sender
{
    if([model selectedWaveform] == kWaveformFromFile){
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setCanChooseFiles:YES];
        [openPanel setAllowsMultipleSelection:NO];
        [openPanel setPrompt:@"DownLoad"];
        [openPanel beginSheetForDirectory:NSHomeDirectory()
                                     file:nil
                                    types:nil
                           modalForWindow:[self window]
                            modalDelegate:self
                           didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                              contextInfo:NULL];
    }
    else {
			[self downloadWaveform];
			NSLog(@"Downloading Waveform: %@\n",[selectionPopUpButton titleOfSelectedItem]);
    }
}

-(void) downloadWaveform
{
    NS_DURING
        [self endEditing];
        
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
        
        NS_HANDLER
            NSLog( [ localException reason ] );
            NSRunAlertPanel( [ localException name ], 	// Name of panel
                             [ localException reason ],	// Reason for error
                             @"OK",				// Okay button
                             nil,				// alternate button
                             nil );				// other button
        NS_ENDHANDLER
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* fileName = [[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath];
        [model setFileName:fileName];
        [self performSelector:@selector(downloadWaveform) withObject:self afterDelay:0.1];
		NSLog(@"Downloading Waveform: %@\n",fileName);

    }
}


-(IBAction) triggerModeAction:(id)sender
{
	NS_DURING
		if([[sender selectedCell]tag] != [model triggerSource]){
			[[self undoManager] setActionName: @"Set TriggerMode"];
			[model setTriggerSource:[[sender selectedCell]tag]];	
			[model writeTriggerSource:[model triggerSource]];    
		}
	NS_HANDLER
		NSLog( [ localException reason ] );
		NSRunAlertPanel( [ localException name ], 	// Name of panel
						 [ localException reason ],	// Reason for error
						 @"OK",				// Okay button
						 nil,				// alternate button
						 nil );				// other button
	NS_ENDHANDLER
	
}

- (IBAction) triggerAction:(id)sender
{
	NS_DURING
		[model trigger];
	NS_HANDLER
		NSLog( [ localException reason ] );
		NSRunAlertPanel( [ localException name ], 	// Name of panel
						 [ localException reason ],	// Reason for error
						 @"OK",				// Okay button
						 nil,				// alternate button
						 nil );				// other button
	NS_ENDHANDLER
}

-(IBAction) setVoltageAction:(id)sender
{
    if([sender intValue] != [model voltage]){
        [[self undoManager] setActionName: @"Set Voltage"];
        [model setVoltage:[sender intValue]];		
    }
	
}

-(IBAction) setVoltageOffsetAction:(id)sender
{
    if([sender floatValue] != [model voltageOffset]){
        [[self undoManager] setActionName: @"Set Voltage Offset"];
        [model setVoltageOffset:[sender floatValue]];		
    }
	
}

-(IBAction) setBurstRateAction:(id)sender
{
    if([sender floatValue] != [model burstRate]){
        [[self undoManager] setActionName: @"Set Burst Rate"];
        [model setBurstRate:[sender floatValue]];		
    }
}

-(IBAction) setTotalWidthAction:(id)sender
{
    if([sender floatValue] != [model totalWidth]){
        [[self undoManager] setActionName: @"Set Total Width"];
        [model setTotalWidth:[sender floatValue]];		
    }
}

-(IBAction) selectWaveformAction:(id)sender;
{
    if([sender indexOfSelectedItem] != [model selectedWaveform]){ 	
        [[self undoManager] setActionName: @"Selected Waveform"];
        [model setSelectedWaveform:[selectionPopUpButton indexOfSelectedItem]];
    }
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:[model dialogLock] to:[sender intValue] forWindow:[self window]];
}

- (IBAction) enableRandomAction:(id)sender
{
	[model setEnableRandom:[sender state]];
}

- (IBAction) minTimeAction:(id)sender
{
	[model setMinTime:[sender floatValue]];
}

- (IBAction) maxTimeAction:(id)sender
{
	[model setMaxTime:[sender floatValue]];
}


#pragma mark •••Notifications

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:[model dialogLock] to:secure];
    
    [lockButton setEnabled:secure];
}

- (void) lockChanged: (NSNotification*) aNotification
{
	[self setButtonStates];

}

- (void) primaryAddressChanged:(NSNotification*)aNotification
{
	[super primaryAddressChanged:aNotification];
	[[self window] setTitle:[model title]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[model title]];
}


- (void) triggerModeChanged:(NSNotification*)aNotification
{
	[triggerModeMatrix selectCellWithTag: [model triggerSource]];
	[self setButtonStates];
	//[model writeTriggerSource:[model triggerSource]];
}
- (void) voltageChanged:(NSNotification*)aNotification
{
	[self updateStepper:voltageStepper setting:[model voltage]];
	[voltageField setIntValue: [model voltage]];
}

- (void) voltageOffsetChanged:(NSNotification*)aNotification
{
	[self updateStepper:voltageOffsetStepper setting:[model voltageOffset]];
	[voltageOffsetField setFloatValue: [model voltageOffset]];
}

- (void) burstRateChanged:(NSNotification*)aNotification
{
	[self updateStepper:burstRateStepper setting:[model burstRate]];
	[burstRateField setFloatValue: [model burstRate]];
}

- (void) totalWidthChanged:(NSNotification*)aNotification
{
	[self updateStepper:totalWidthStepper setting:[model totalWidth]];
	[totalWidthField setFloatValue: [model totalWidth]];
}

- (void) selectedWaveformChanged:(NSNotification*)aNotification
{
	[selectionPopUpButton selectItemAtIndex:[model selectedWaveform]];
}

- (void) volatileChanged:(NSNotification*)aNotification
{
	[progress setIndeterminate:NO];
	[downloadTypeField setStringValue:@""];
}

- (void) nonVolatileChanged:(NSNotification*)aNotification
{
	[progress setIndeterminate:YES];
	[progress startAnimation:self];
	[downloadTypeField setStringValue:@"In NonVol. Mem."];
}

- (void) loadConstantsChanged:(NSNotification*)aNotification
{
	if([model selectedWaveform] == kLogCalibrationWaveform){
		[voltageDisplay setFloatValue:kCalibrationVoltage];
		[voltageOffsetDisplay setFloatValue:0.0];
		[totalWidthDisplay setFloatValue:kCalibrationWidth];
		[burstRateDisplay setFloatValue:kCalibrationBurstRate];
	}
	else {
		[voltageDisplay setFloatValue:[model voltage]];
		[voltageOffsetDisplay setFloatValue:[model voltageOffset]];
		[totalWidthDisplay setFloatValue:[model totalWidth]];
		[burstRateDisplay setFloatValue:[model burstRate]];
	}
}

- (void) enableRandomChanged:(NSNotification*)aNote
{
	[enableRandomButton setState:[model enableRandom]];
}

- (void) minTimeChanged:(NSNotification*)aNote
{
	[minTimeField setFloatValue:[model minTime]];
	[minTimeStepper setFloatValue:[model minTime]];
}

- (void) maxTimeChanged:(NSNotification*)aNote
{
	[maxTimeField setFloatValue:[model maxTime]];
	[maxTimeStepper setFloatValue:[model maxTime]];
}

- (void) randomCountChanged:(NSNotification*)aNote
{
	[randomCountField setIntValue:[model randomCount]];
}


- (void) waveformLoadStarted:(NSNotification*)aNotification
{        
	[self setButtonStates];
	
	int mx = [model numPoints];
	
	[yScale setRngLimitsLow:-1 withHigh:1 withMinRng:2];
	[yScale setRngLow:-1 withHigh:1];
	//[yScale setFullRng];
	
	[xScale setRngLimitsLow:0 withHigh:mx withMinRng:mx];
	[xScale setRngLow:0 withHigh:mx];
	//[xScale setFullRng];
	
	
	[yScale setNeedsDisplay:YES];
	[xScale setNeedsDisplay:YES];
	[plotter setNeedsDisplay:YES];
}

- (void) waveformLoadProgressing:(NSNotification*)aNotification
{
	[progress setDoubleValue:[model downloadIndex]]; 
}

- (void) waveformLoadFinished:(NSNotification*)aNotification
{
	[yScale setNeedsDisplay:YES];
	[xScale setNeedsDisplay:YES];
	[plotter setNeedsDisplay:YES];
	[progress setDoubleValue:[model downloadIndex]]; 
	[downloadButton setEnabled:![model loading] && ![model lockGUI]];
	
	[progress setIndeterminate:NO];
	[progress stopAnimation:self];
	[downloadTypeField setStringValue:@""];

	[progress setDoubleValue:0]; 
	[self setButtonStates];
}


- (int)	numberOfPointsInPlot:(ORPlotter1D*)aPlotter dataSet:(int)set
{
    return [model numPoints];
}

- (float) plotter:(ORPlotter1D *) aPlotter  dataSet:(int)set dataValue:(int) index
{
    float* d = (float*)[[model waveform] mutableBytes];
    return d[index];
}

- (void) setButtonStates
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model dialogLock]];
    BOOL loading = [model loading];
	BOOL runInProgress  = [gOrcaGlobals runInProgress];
	
    if(loading){
        [downloadButton setTitle:@"Stop"];
    }
    else {
        [downloadButton setTitle:@"Load"];
    }
	BOOL locked		= [gSecurity isLocked:[model dialogLock]];
    BOOL triggerModeIsSoftware = [model triggerSource] == kSoftwareTrigger;
   
	locked |= [model lockGUI];
   
    [enableRandomButton setEnabled: !locked && triggerModeIsSoftware];	
    [minTimeField setEnabled: !locked && triggerModeIsSoftware];	
    [maxTimeField setEnabled: !locked && triggerModeIsSoftware];	
    [minTimeStepper setEnabled: !locked && triggerModeIsSoftware];	
    [maxTimeStepper setEnabled: !locked && triggerModeIsSoftware];	
	
    [negativePulseMatrix setEnabled:!loading && !locked];
    [mPrimaryAddress setEnabled:!loading && !locked];
    [mConnectButton setEnabled:!loading && !locked];
    [readIdButton setEnabled:!loading && !locked];
    [resetButton setEnabled:!loading && !locked];
    [testButton setEnabled:!loading && !locked];
    [clearButton setEnabled:!loading && !locked];
    [selectionPopUpButton setEnabled:!loading && !locked];
    [voltageField setEnabled:!loading && !locked];
    [voltageStepper setEnabled:!loading && !locked];
	[voltageOffsetField setEnabled:!loading && !locked];
    [voltageOffsetStepper setEnabled:!loading && !locked];
    [burstRateField setEnabled:!loading && !locked];
    [burstRateStepper setEnabled:!loading && !locked];
    [totalWidthField setEnabled:!loading && !locked];
    [totalWidthStepper setEnabled:!loading && !locked];
    [triggerModeMatrix setEnabled:!locked && !loading];
    [triggerButton setEnabled:!locked && !loading && triggerModeIsSoftware];
    [loadParamsButton setEnabled:!locked && !loading];
    [sendCommandButton setEnabled:!locked && !loading];
	[commandField setEnabled:!locked && !loading];
    NSString* s = @"";
	if([model lockGUI]){
		s = @"Locked by other object";
	}
    else if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:[model dialogLock]])s = @"Not in Maintenance Run.";
    }
    [lockDocField setStringValue:s];

}

@end
