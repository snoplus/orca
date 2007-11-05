//
//  ORIpeSLTController.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
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


#pragma mark ¥¥¥Imported Files
#import "ORIpeSLTController.h"
#import "ORIpeSLTModel.h"
#import "ORFireWireInterface.h"
#import "TimedWorker.h"

#define kFltNumberTriggerSources 5

NSString* fltTriggerSourceNames[2][kFltNumberTriggerSources] = {
	{
		@"Software",
		@"Right",
		@"Left",
		@"Mirror",
		@"External",
	},
	{
		@"Software",
		@"N/A",
		@"N/A",
		@"Multiplicity",
		@"External",
	}
};

@implementation ORIpeSLTController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"IpeSLT"];
    
    return self;
}

#pragma mark ¥¥¥Initialization
- (void) dealloc
{
	[xImage release];
	[yImage release];
    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
	[[self window] setTitle:@"IPE-DAQ-V3 SLT"];	
	[self populatePullDown];
    [self updateWindow];
	[pageStatusMatrix setMode:NSRadioModeMatrix];
	[pageStatusMatrix setTarget:self];
	[pageStatusMatrix setAction:@selector(dumpPageStatus:)];
}

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORIpeSLTSettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(serviceChanged:)
                         name : @"ORFireWireInterfaceServiceAliveChanged"
                       object : [model fireWireInterface]];

    [notifyCenter addObserver : self
                     selector : @selector(deviceOpenChanged:)
                         name : @"ORFireWireInterfaceIsOpenChanged"
                       object : [model fireWireInterface]];

    [notifyCenter addObserver : self
                     selector : @selector(controlRegChanged:)
                         name : ORIpeSLTControlRegChanged
                       object : model];

    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : ORIpeSLTSelectedRegIndexChanged
					   object : model];
	
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : ORIpeSLTWriteValueChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(statusRegChanged:)
                         name : ORIpeSLTStatusRegChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(pulserAmpChanged:)
                         name : ORIpeSLTPulserAmpChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(pulserDelayChanged:)
                         name : ORIpeSLTPulserDelayChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(usePBusSimChanged:)
                         name : ORIpePBusSimChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(nHitChanged:)
                         name : ORIpeSLTModelNHitChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(nHitThresholdChanged:)
                         name : ORIpeSLTModelNHitThresholdChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(versionChanged:)
                         name : ORIpeSLTModelFpgaVersionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(interruptMaskChanged:)
                         name : ORIpeSLTModelInterruptMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(nextPageDelayChanged:)
                         name : ORIpeSLTModelNextPageDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pageStatusChanged:)
                         name : ORIpeSLTModelPageStatusChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollRateChanged:)
                         name : TimedWorkerTimeIntervalChangedNotification
                       object : [model poller]];

    [notifyCenter addObserver : self
                     selector : @selector(pollRunningChanged:)
                         name : TimedWorkerIsRunningChangedNotification
                       object : [model poller]];

    [notifyCenter addObserver : self
                     selector : @selector(patternFilePathChanged:)
                         name : ORIpeSLTModelPatternFilePathChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(readAllChanged:)
                         name : ORIpeSLTModelReadAllChanged
						object: model];


}

#pragma mark ¥¥¥Interface Management
- (void) readAllChanged:(NSNotification*)aNote
{
	[readAllMatrix selectCellWithTag:[model readAll]];
}

- (void) patternFilePathChanged:(NSNotification*)aNote
{
	NSString* thePath = [[model patternFilePath] stringByAbbreviatingWithTildeInPath];
	if(!thePath)thePath = @"---";
	[patternFilePathField setStringValue: thePath];
}

- (void) pollRateChanged:(NSNotification*)aNotification
{
    if(aNotification== nil || [aNotification object] == [model poller]){
        [pollRatePopup selectItemAtIndex:[pollRatePopup indexOfItemWithTag:[[model poller] timeInterval]]];
    }
}

- (void) pollRunningChanged:(NSNotification*)aNotification
{
    if(aNotification== nil || [aNotification object] == [model poller]){
        if([[model poller] isRunning])[pollRunningIndicator startAnimation:self];
        else [pollRunningIndicator stopAnimation:self];
    }
}

- (void) nextPageDelayChanged:(NSNotification*)aNote
{
	[nextPageDelaySlider setIntValue:100-[model nextPageDelay]];
	[nextPageDelayField  setFloatValue:[model nextPageDelay]*102.3/100.];
}

- (void) interruptMaskChanged:(NSNotification*)aNote
{
	unsigned long aMaskValue = [model interruptMask];
	int i;
	for(i=0;i<9;i++){
		if(aMaskValue & (1L<<i))[[interruptMaskMatrix cellWithTag:i] setIntValue:1];
		else [[interruptMaskMatrix cellWithTag:i] setIntValue:0];
	}
}

- (void) versionChanged:(NSNotification*)aNote
{
	[versionField setFloatValue: [model fpgaVersion]];
	int i;
	if(![model usingNHitTriggerVersion]){
		for(i=0;i<kFltNumberTriggerSources;i++){
			[[triggerSrcMatrix cellWithTag:i] setTitle:fltTriggerSourceNames[0][i]];
		}
	}
	else {
		for(i=0;i<kFltNumberTriggerSources;i++){
			[[triggerSrcMatrix cellWithTag:i] setTitle:fltTriggerSourceNames[1][i]];
		}
	}

	[self settingsLockChanged:nil];
}

- (void) nHitThresholdChanged:(NSNotification*)aNote
{
	[nHitThresholdField setIntValue: [model nHitThreshold]];
	[nHitThresholdStepper setIntValue: [model nHitThreshold]];
}

- (void) nHitChanged:(NSNotification*)aNote
{
	[nHitField setIntValue: [model nHit]];
	[nHitStepper setIntValue: [model nHit]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self settingsLockChanged:nil];
	[self serviceChanged:nil];
	[self deviceOpenChanged:nil];
	[self controlRegChanged:nil];
	[self statusRegChanged:nil];
    [self writeValueChanged:nil];
    [self pulserAmpChanged:nil];
    [self pulserDelayChanged:nil];
    [self selectedRegIndexChanged:nil];
    [self usePBusSimChanged:nil];
	[self nHitChanged:nil];
	[self nHitThresholdChanged:nil];
	[self interruptMaskChanged:nil];
	[self nextPageDelayChanged:nil];
	[self pageStatusChanged:nil];
	[self versionChanged:nil];
    [self pollRateChanged:nil];
    [self pollRunningChanged:nil];
	[self patternFilePathChanged:nil];
	[self readAllChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORIpeSLTSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORIpeSLTSettingsLock];
    BOOL locked = [gSecurity isLocked:ORIpeSLTSettingsLock];
	BOOL isRunning = [gOrcaGlobals runInProgress];
	
	BOOL nHitSupported = [model usingNHitTriggerVersion];
	

	[calibrateButton setEnabled:!lockedOrRunningMaintenance];
	[readAllMatrix setEnabled:!lockedOrRunningMaintenance];
	[loadPatternFileButton setEnabled:!lockedOrRunningMaintenance];
	[definePatternFileButton setEnabled:!lockedOrRunningMaintenance];
	[setSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[relSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[releaseAllPagesButton setEnabled:!lockedOrRunningMaintenance];
	[forceTriggerButton setEnabled:!lockedOrRunningMaintenance];
	[forceTrigger1Button setEnabled:!lockedOrRunningMaintenance];
	[initBoardButton setEnabled:!lockedOrRunningMaintenance];
	[initBoard1Button setEnabled:!lockedOrRunningMaintenance];
	[readBoardButton setEnabled:!lockedOrRunningMaintenance];
    [controlCheckBoxMatrix setEnabled:!lockedOrRunningMaintenance];
    [inhibitCheckBoxMatrix setEnabled:!lockedOrRunningMaintenance];

	[dumpROMButton setEnabled:!locked];
	[versionButton setEnabled:!isRunning];
	[deadTimeButton setEnabled:!isRunning];
	[vetoTimeButton setEnabled:!isRunning];
	[resetHWButton setEnabled:!isRunning];
	[usePBusSimButton setEnabled:!isRunning];

	[pulserAmpField setEnabled:!locked];

	[nHitThresholdField setEnabled:nHitSupported && !lockedOrRunningMaintenance];
	[nHitThresholdStepper setEnabled:nHitSupported && !lockedOrRunningMaintenance];
	[nHitField setEnabled:nHitSupported && !lockedOrRunningMaintenance];
	[nHitStepper setEnabled:nHitSupported && !lockedOrRunningMaintenance];


	[nextPageDelaySlider setEnabled:!isRunning];
	
    [settingLockButton setState: lockedOrRunningMaintenance];

	[self enableRegControls];
}

- (void) enableRegControls
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORIpeSLTSettingsLock];
	short index = [model selectedRegIndex];
	BOOL readAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegReadable)>0;
	BOOL writeAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegWriteable)>0;

	[regWriteButton setEnabled:writeAllowed];
	[regReadButton setEnabled:readAllowed];
	
	[regWriteValueStepper setEnabled:writeAllowed];
	[regWriteValueTextField setEnabled:writeAllowed];
}

- (void) endAllEditing:(NSNotification*)aNotification
{
}

- (void) writeValueChanged:(NSNotification*) aNote
{
	[self updateStepper:regWriteValueStepper setting:[model writeValue]];
	[regWriteValueTextField setIntValue:[model writeValue]];
}

- (void) usePBusSimChanged:(NSNotification*) aNote
{
	[usePBusSimButton setState:[model pBusSim]];
}

- (void) selectedRegIndexChanged:(NSNotification*) aNote
{
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerPopUp	 setting:index];

	[self enableRegControls];
}

- (void) serviceChanged:(NSNotification*)aNote
{
	if(aNote== nil || [aNote object] == [model fireWireInterface] ){
		//NSLog(@"%@ station %d: firewire service %@\n",[model className],[model stationNumber],[[model fireWireInterface] serviceAlive]?@"OK":@"interrupted");
	}
}

- (void) deviceOpenChanged:(NSNotification*)aNote
{
	if(aNote== nil || [aNote object] == [model fireWireInterface] ){
		//NSLog(@"%@ station %d: firewire service %@\n",[model className],[model stationNumber],[[model fireWireInterface] isOpen]?@"open":@"closed");
		//if(![[model fireWireInterface] isOpen]){
			//[model startConnectionAttempts];
		//}
	}
}

- (void) pageStatusChanged:(NSNotification*)aNote
{
	if(!xImage)xImage = [[NSImage imageNamed:@"exMark"] retain];
	if(!yImage)yImage = [[NSImage imageNamed:@"checkMark"] retain];
	unsigned long lowWord = [model pageStatusLow];
	unsigned long highWord = [model pageStatusHigh];
	unsigned long theWord;
	int i;
	for(i=0;i<64;i++){
		NSCell* aCell = [[pageStatusMatrix cells] objectAtIndex:i];
		if(i<32) theWord = lowWord;
		else     theWord = highWord;
		if(theWord & (1<<(i%32))) {
			[aCell setImage:yImage];
		}
		else {
			[aCell setImage:xImage];
		}
	}
	[pageStatusMatrix setNeedsDisplay:YES];
	
	[actualPageField setIntValue:[model actualPage]+1];
	[nextPageField setIntValue:  [model nextPage]+1];
	
}

- (void) controlRegChanged:(NSNotification*)aNote
{

	[[controlCheckBoxMatrix cellWithTag:0] setIntValue:[model ledInhibit]];
	[[controlCheckBoxMatrix cellWithTag:1] setIntValue:[model ledVeto]];
	[[controlCheckBoxMatrix cellWithTag:2] setIntValue:[model enableDeadTimeCounter]];

	int value = [model inhibitSource];
	[[inhibitCheckBoxMatrix cellWithTag:0] setIntValue:value&0x1];
	[[inhibitCheckBoxMatrix cellWithTag:1] setIntValue:(value>>1)&0x1];
	[[inhibitCheckBoxMatrix cellWithTag:2] setIntValue:(value>>2)&0x1];

	
	[watchDogPU selectItemAtIndex:[watchDogPU indexOfItemWithTag:[model watchDogStart]]];
	[secStrobeSrcPU selectItemAtIndex:[secStrobeSrcPU indexOfItemWithTag:[model secStrobeSource]]];
	[startSrcPU selectItemAtIndex:[startSrcPU indexOfItemWithTag:[model testPulseSource]]];
	
	int i;
	for(i=0;i<kFltNumberTriggerSources;i++){
		unsigned long aTriggerMask = [model triggerSource];
		if(aTriggerMask & (1L<<i)) [[triggerSrcMatrix cellWithTag:i] setIntValue:1];
		else [[triggerSrcMatrix cellWithTag:i] setIntValue:0];
	}
	
}

- (void) statusRegChanged:(NSNotification*)aNote
{
	NSColor* redColor  = [NSColor colorWithDeviceRed:.65 green:0 blue:0 alpha:1];
	NSColor* greenColor = [NSColor colorWithDeviceRed:0 green:.65 blue:0 alpha:1];
	
	[[statusMatrix cellWithTag:0] setTitle:[model veto]?@"Set": @"Clear"];
	[[statusMatrix cellWithTag:0] setTextColor:[model veto]?redColor:greenColor];
	
	[[statusMatrix cellWithTag:1] setTitle:[model extInhibit]?@"Set": @"Clear"];
	[[statusMatrix cellWithTag:1] setTextColor:[model extInhibit]?redColor:greenColor];

	[[statusMatrix cellWithTag:2] setTitle:[model nopgInhibit]?@"Set": @"Clear"];
	[[statusMatrix cellWithTag:2] setTextColor:[model nopgInhibit]?redColor:greenColor];

	[[statusMatrix cellWithTag:3] setTitle:[model swInhibit]?@"Set": @"Clear"];
	[[statusMatrix cellWithTag:3] setTextColor:[model swInhibit]?redColor:greenColor];

	[[statusMatrix cellWithTag:4] setTitle:[model inhibit]?@"Set": @"Clear"];
	[[statusMatrix cellWithTag:4] setTextColor:[model inhibit]?redColor:greenColor];
}




- (void) populatePullDown
{
    short	i;
        
// Clear all the popup items.
    [registerPopUp removeAllItems];
    
// Populate the register popup
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerPopUp insertItemWithTitle:[model getRegisterName:i] atIndex:i];
    }
}

- (void) pulserAmpChanged:(NSNotification*) aNote
{
	[pulserAmpField setFloatValue:[model pulserAmp]];
}

- (void) pulserDelayChanged:(NSNotification*) aNote
{
	[pulserDelayField setFloatValue:[model pulserDelay]];
}


#pragma mark ***Actions
- (void) dumpPageStatus:(id)sender
{
	if([[NSApp currentEvent] clickCount] >=2){
		int pageIndex = [sender selectedRow]*32 + [sender selectedColumn];
		NS_DURING
			[model dumpTriggerRAM:pageIndex];
		NS_HANDLER
			NSLog(@"Exception doing SLT dump trigger RAM page\n");
			NSRunAlertPanel([localException name], @"%@\nSLT%d dump trigger RAM failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
		NS_ENDHANDLER
	}
}

- (IBAction) pollNowAction:(id)sender
{
	[model readAllStatus];
}

- (IBAction) pollRateAction:(id)sender
{
    [model setPollingInterval:[[pollRatePopup selectedItem] tag]];
}

- (IBAction) interruptMaskAction:(id)sender
{
	unsigned long aMaskValue = 0;
	int i;
	for(i=0;i<9;i++){
		if([[interruptMaskMatrix cellWithTag:i] intValue]) aMaskValue |= (1L<<i);
		else aMaskValue &= ~(1L<<i);
	}
	[model setInterruptMask:aMaskValue];	
}

- (IBAction) nextPageDelayAction:(id)sender
{
	[model setNextPageDelay:100-[sender intValue]];	
}


- (IBAction) nHitThresholdAction:(id)sender
{
	[model setNHitThreshold:[sender intValue]];	
}

- (IBAction) nHitAction:(id)sender
{
	[model setNHit:[sender intValue]];	
}

- (IBAction) usePBusSimAction:(id)sender
{
	[model setPBusSim:[sender intValue]];
}

- (IBAction) initBoardAction:(id)sender
{
	NS_DURING
		[self endEditing];
		[model initBoard];
		NSLog(@"SLT%d initialized\n",[model stationNumber]);
	NS_HANDLER
		NSLog(@"Exception SLT init\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d InitBoard failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) readStatus:(id)sender
{
	[model readStatusReg];
	[model readPageStatus];
}

- (IBAction) reportAllAction:(id)sender
{
	NS_DURING
		[model printStatusReg];
		[model printControlReg];
		[model printInterruptMask];
	NS_HANDLER
		NSLog(@"Exception reading SLT status\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}


- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORIpeSLTSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) dumpROMAction:(id)sender
{
	NS_DURING
		[model dumpROM];
	NS_HANDLER
		NSLog(@"Exception reading SLT ROM\n");
        NSRunAlertPanel([localException name], @"%@\nSLT Access failed", @"OK", nil, nil,
                        localException);
	NS_ENDHANDLER
}

- (IBAction) controlRegAction:(id)sender
{
	int tag		= [sender tag];
	int value	= [sender indexOfSelectedItem];
	switch(tag){
		case 0:	[model setWatchDogStart:value]; break;
		case 1:	[model setSecStrobeSource:value]; break;
		case 2:	[model setTestPulseSource:value]; break;
		case 4:	[model setTriggerSource:value]; break;
	}
}

- (IBAction) selectRegisterAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[model undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
		[self settingsLockChanged:nil];
    }
}

- (IBAction) writeValueAction:(id) aSender
{
	[self endEditing];
    // Make sure that value has changed.
    if ([aSender intValue] != [model writeValue]){
		[[model undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction) readRegAction: (id) sender
{
	int index = [registerPopUp indexOfSelectedItem];
	NS_DURING
		unsigned long value = [model readReg:index];
		NSLog(@"SLT reg: %@ value: 0x%x\n",[model getRegisterName:index],value);
	NS_HANDLER
		NSLog(@"Exception reading SLT reg: %@\n",[model getRegisterName:index]);
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}
- (IBAction) writeRegAction: (id) sender
{
	[self endEditing];
	int index = [registerPopUp indexOfSelectedItem];
	NS_DURING
		[model writeReg:index value:[model writeValue]];
		NSLog(@"wrote 0x%x to SLT reg: %@ \n",[model writeValue],[model getRegisterName:index]);
	NS_HANDLER
		NSLog(@"Exception writing SLT reg: %@\n",[model getRegisterName:index]);
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) versionAction: (id) sender
{
	NS_DURING
		NSLog(@"SLT Hardware Model Version: %.1f\n",[model readVersion]);
	NS_HANDLER
		NSLog(@"Exception reading SLT HW Model Version\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) deadTimeAction: (id) sender
{
	NS_DURING
		NSLog(@"SLT Dead Time: %lld\n",[model readDeadTime]);
	NS_HANDLER
		NSLog(@"Exception reading SLT Dead Time\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) vetoTimeAction: (id) sender
{
	NS_DURING
		NSLog(@"SLT Veto Time: %lld\n",[model readVetoTime]);
	NS_HANDLER
		NSLog(@"Exception reading SLT Veto Time\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) resetHWAction: (id) pSender
{
	NS_DURING
		[model hw_config];
	NS_HANDLER
		NSLog(@"Exception reading SLT HW Reset\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) controlCheckBoxAction:(id) sender
{
	switch([[sender selectedCell]tag]){
		case 0: [model setLedInhibit:[[sender selectedCell]state]]; break;
		case 1: [model setLedVeto:[[sender selectedCell]state]]; break;
		case 2: [model setEnableDeadTimeCounter:[[sender selectedCell]state]]; break;
		default: break;
	}
}

- (IBAction) inhibitCheckBoxAction:(id) sender
{
	int tag = [[sender selectedCell]tag];
	int value = [model inhibitSource];
	
	if([[sender selectedCell]state])value |= (1<<tag);
	else	 value &= ~(1<<tag);
	[model setInhibitSource:value];
}

- (IBAction) pulserAmpAction: (id) sender
{
	[model setPulserAmp:[sender floatValue]];
}

- (IBAction) pulserDelayAction: (id) sender
{
	[model setPulserDelay:[sender floatValue]];
}

- (IBAction) loadPulserAction: (id) sender
{
	NS_DURING
		[model loadPulserValues];
	NS_HANDLER
		NSLog(@"Exception loading SLT pulser values\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d load pulser failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
	
}

- (IBAction) pulseOnceAction: (id) sender
{
	NS_DURING
		[model pulseOnce];
	NS_HANDLER
		NSLog(@"Exception doing SLT pulse\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d pulse failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}


- (IBAction) triggerSourceAction:(id)sender
{
	unsigned long aTriggerMask = 0;
	int i;
	for(i=0;i<kFltNumberTriggerSources;i++){
		if([[triggerSrcMatrix cellWithTag:i] intValue]) aTriggerMask |= (1L<<i);
		else aTriggerMask &= ~(1L<<i);
	}
	[model setTriggerSource:aTriggerMask];
}

- (IBAction) releaseAllPagesAction:(id)sender
{
	NS_DURING
		[model releaseAllPages];
		[model readAllStatus];
	NS_HANDLER
		NSLog(@"Exception doing SLT release pages\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d release pages failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) setSWInhibitAction:(id)sender
{
	NS_DURING
		[model setSwInhibit];
		[model readStatusReg];
	NS_HANDLER
		NSLog(@"Exception doing SLT Set SW Inhibit pages\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d set SW inhibiit failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) releaseSWInhibitAction:(id)sender
{
	NS_DURING
		[model releaseSwInhibit];
		[model readStatusReg];
	NS_HANDLER
		NSLog(@"Exception doing SLT Release SW Inhibit pages\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d release SW inhibiit failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) forceTrigger:(id)sender
{
	NS_DURING
		[model pulseOnce];
		[model readAllStatus];
	NS_HANDLER
		NSLog(@"Exception doing SLT Software trigger\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d software trigger failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}


- (IBAction) definePatternFileAction:(id)sender
{
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model patternFilePath]){
        startDir = [[model patternFilePath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Load Pattern File"];
    [openPanel beginSheetForDirectory:startDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(loadPatternPanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];

}

- (IBAction) loadPatternFile:(id)sender
{
	[model loadPatternFile];
}

- (IBAction) readAllAction:(id)sender
{
	[model setReadAll:[[sender selectedCell] tag]];
}

- (IBAction) calibrateAction:(id)sender
{
    NSBeginAlertSheet(@"Threshold Calibration",
                      @"Cancel",
                      @"Yes/Do Calibrate",
                      nil,[self window],
                      self,
                      @selector(calibrationSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Really run threshold calibration for ALL FLTs?\n This will change ALL thresholds on ALL cards.");
}

@end

@implementation ORIpeSLTController (private)
-(void)loadPatternPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* fileName = [[sheet filenames] objectAtIndex:0];
        [model setPatternFilePath:fileName];
    }
}

- (void) calibrationSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
		NS_DURING
			[model autoCalibrate];
		NS_HANDLER
		NS_ENDHANDLER
    }    
}

@end


