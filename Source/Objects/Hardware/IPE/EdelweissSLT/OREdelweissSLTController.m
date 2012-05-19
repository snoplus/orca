//
//  OREdelweissSLTController.m
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


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Imported Files
#import "OREdelweissSLTController.h"
#import "OREdelweissSLTModel.h"
#import "TimedWorker.h"
#import "SBC_Link.h"

#define kFltNumberTriggerSources 5

NSString* fltEdelweissV4TriggerSourceNames[2][kFltNumberTriggerSources] = {
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

@interface OREdelweissSLTController (private)
#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
- (void)loadPatternPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
#endif
- (void) calibrationSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (void) do:(SEL)aSelector name:(NSString*)aName;
@end

@implementation OREdelweissSLTController

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"EdelweissSLT"];
    
    return self;
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Initialization
- (void) dealloc
{
	[xImage release];
	[yImage release];
    [super dealloc];
}

- (void) awakeFromNib
{
	controlSize			= NSMakeSize(555,670);
    statusSize			= NSMakeSize(555,480);
    lowLevelSize		= NSMakeSize(555,400);
    cpuManagementSize	= NSMakeSize(485,450);
    cpuTestsSize		= NSMakeSize(555,315);
    udpSize		        = NSMakeSize(555,670);
	
	[[self window] setTitle:@"IPE-DAQ-V4 EDELWEISS SLT"];	
	
    [super awakeFromNib];
    [self updateWindow];
	
	[self populatePullDown];
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
	
	[notifyCenter addObserver : self
                     selector : @selector(hwVersionChanged:)
                         name : OREdelweissSLTModelHwVersionChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(statusRegChanged:)
                         name : OREdelweissSLTModelStatusRegChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(controlRegChanged:)
                         name : OREdelweissSLTModelControlRegChanged
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : OREdelweissSLTSelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : OREdelweissSLTWriteValueChanged
					   object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(pulserAmpChanged:)
                         name : OREdelweissSLTPulserAmpChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pulserDelayChanged:)
                         name : OREdelweissSLTPulserDelayChanged
                       object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : OREdelweissSLTModelPageSizeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : OREdelweissSLTModelDisplayEventLoopChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : OREdelweissSLTModelDisplayTriggerChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(interruptMaskChanged:)
                         name : OREdelweissSLTModelInterruptMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(nextPageDelayChanged:)
                         name : OREdelweissSLTModelNextPageDelayChanged
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
                         name : OREdelweissSLTModelPatternFilePathChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(secondsSetChanged:)
                         name : OREdelweissSLTModelSecondsSetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(deadTimeChanged:)
                         name : OREdelweissSLTModelDeadTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(vetoTimeChanged:)
                         name : OREdelweissSLTModelVetoTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(runTimeChanged:)
                         name : OREdelweissSLTModelRunTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(clockTimeChanged:)
                         name : OREdelweissSLTModelClockTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(countersEnabledChanged:)
                         name : OREdelweissSLTModelCountersEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sltScriptArgumentsChanged:)
                         name : OREdelweissSLTModelSltScriptArgumentsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(secondsSetInitWithHostChanged:)
                         name : OREdelweissSLTModelSecondsSetInitWithHostChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPCommandPortChanged:)
                         name : OREdelweissSLTModelCrateUDPCommandPortChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPCommandIPChanged:)
                         name : OREdelweissSLTModelCrateUDPCommandIPChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPReplyPortChanged:)
                         name : OREdelweissSLTModelCrateUDPReplyPortChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPCommandChanged:)
                         name : OREdelweissSLTModelCrateUDPCommandChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isListeningOnServerSocketChanged:)
                         name : OREdelweissSLTModelIsListeningOnServerSocketChanged
						object: model];

}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Interface Management

- (void) isListeningOnServerSocketChanged:(NSNotification*)aNote
{
    if([model isListeningOnServerSocket])
	    [listeningForReplyIndicator  startAnimation: nil];
    else
	    [listeningForReplyIndicator  stopAnimation: nil];
}

- (void) crateUDPCommandChanged:(NSNotification*)aNote
{
	[crateUDPCommandTextField setStringValue: [model crateUDPCommand]];
}

- (void) crateUDPReplyPortChanged:(NSNotification*)aNote
{
	[crateUDPReplyPortTextField setIntValue: [model crateUDPReplyPort]];
}

- (void) crateUDPCommandIPChanged:(NSNotification*)aNote
{
	[crateUDPCommandIPTextField setStringValue: [model crateUDPCommandIP]];
}

- (void) crateUDPCommandPortChanged:(NSNotification*)aNote
{
	[crateUDPCommandPortTextField setIntValue: [model crateUDPCommandPort]];
}

- (void) secondsSetInitWithHostChanged:(NSNotification*)aNote
{
	[secondsSetInitWithHostButton setState: [model secondsSetInitWithHost]];
	[secondsSetField setEnabled:![model secondsSetInitWithHost]];
}

- (void) sltScriptArgumentsChanged:(NSNotification*)aNote
{
	[sltScriptArgumentsTextField setStringValue: [model sltScriptArguments]];
}

- (void) countersEnabledChanged:(NSNotification*)aNote
{
	[enableDisableCountersMatrix selectCellWithTag: [model countersEnabled]];
}

- (void) clockTimeChanged:(NSNotification*)aNote
{
	[[countersMatrix cellWithTag:3] setIntValue:[model clockTime]];
}

- (void) runTimeChanged:(NSNotification*)aNote
{
	//[[countersMatrix cellWithTag:2] setStringValue: [NSString stringWithFormat:@"%llu",(unsigned long long)[model runTime]]];
	unsigned long long t=[model runTime];
	[[countersMatrix cellWithTag:2] setStringValue: [NSString stringWithFormat:@"%llu",t]];
	//[[countersMatrix cellWithTag:2] setStringValue: [NSString stringWithFormat:@"%llu.%llu", (t>>32) & 0xffffffff, t & 0xffffffff]];
	//[[countersMatrix cellWithTag:2] setIntValue:  [model runTime]];
}

- (void) vetoTimeChanged:(NSNotification*)aNote
{
	unsigned long long t=[model vetoTime];
	[[countersMatrix cellWithTag:1] setStringValue: [NSString stringWithFormat:@"%llu",t]];
	//[[countersMatrix cellWithTag:1] setStringValue: [NSString stringWithFormat:@"%llu.%llu", (t>>32) & 0xffffffff, t & 0xffffffff]];
	//[[countersMatrix cellWithTag:1] setIntValue:[model vetoTime]];
}

- (void) deadTimeChanged:(NSNotification*)aNote
{
	unsigned long long t=[model deadTime];
	[[countersMatrix cellWithTag:0] setStringValue: [NSString stringWithFormat:@"%llu",t]];
	//[[countersMatrix cellWithTag:0] setStringValue: [NSString stringWithFormat:@"%llu.%llu", (t>>32) & 0xffffffff, t & 0xffffffff]];
	//[[countersMatrix cellWithTag:0] setIntValue:[model deadTime]];
}

- (void) secondsSetChanged:(NSNotification*)aNote
{
	[secondsSetField setIntValue: [model secondsSet]];
}

- (void) statusRegChanged:(NSNotification*)aNote
{
	unsigned long statusReg = [model statusReg];
	[[statusMatrix cellWithTag:0] setStringValue: IsBitSet(statusReg,kStatusFltRq)?@"ERR":@"OK"];
	[[statusMatrix cellWithTag:1] setStringValue: IsBitSet(statusReg,kStatusWDog)?@"ERR":@"OK"];
	[[statusMatrix cellWithTag:2] setStringValue: IsBitSet(statusReg,kStatusPixErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:3] setStringValue: IsBitSet(statusReg,kStatusPpsErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:4] setStringValue: [NSString stringWithFormat:@"0x%02x",ExtractValue(statusReg,kStatusClkErr,4)]]; 
	[[statusMatrix cellWithTag:5] setStringValue: IsBitSet(statusReg,kStatusGpsErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:6] setStringValue: IsBitSet(statusReg,kStatusVttErr)?@"ERR":@"OK"]; 
	[[statusMatrix cellWithTag:7] setStringValue: IsBitSet(statusReg,kStatusFanErr)?@"ERR":@"OK"]; 

}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	[super tabView:aTabView didSelectTabViewItem:tabViewItem];
	
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:controlSize];			break;
		case  1: [self resizeWindowToSize:statusSize];			break;
		case  2: [self resizeWindowToSize:lowLevelSize];	    break;
		case  3: [self resizeWindowToSize:cpuManagementSize];	break;
		case  4: [self resizeWindowToSize:cpuTestsSize];	    break;
		default: [self resizeWindowToSize:udpSize];	            break;
    }
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
	for(i=0;i<16;i++){
		if(aMaskValue & (1L<<i))[[interruptMaskMatrix cellWithTag:i] setIntValue:1];
		else [[interruptMaskMatrix cellWithTag:i] setIntValue:0];
	}
}

- (void) pageSizeChanged:(NSNotification*)aNote
{
	[pageSizeField setIntValue: [model pageSize]];
	[pageSizeStepper setIntValue: [model pageSize]];
}


- (void) updateWindow
{
    [super updateWindow];
	[self hwVersionChanged:nil];
	[self controlRegChanged:nil];
    [self writeValueChanged:nil];
    [self pulserAmpChanged:nil];
    [self pulserDelayChanged:nil];
    [self selectedRegIndexChanged:nil];
	[self pageSizeChanged:nil];	
	[self displayEventLoopChanged:nil];	
	[self displayTriggerChanged:nil];	
	[self interruptMaskChanged:nil];
	[self nextPageDelayChanged:nil];
    [self pollRateChanged:nil];
    [self pollRunningChanged:nil];
	[self patternFilePathChanged:nil];
	[self statusRegChanged:nil];
	[self secondsSetChanged:nil];
	[self deadTimeChanged:nil];
	[self vetoTimeChanged:nil];
	[self runTimeChanged:nil];
	[self clockTimeChanged:nil];
	[self countersEnabledChanged:nil];
	[self sltScriptArgumentsChanged:nil];
	[self secondsSetInitWithHostChanged:nil];
	[self crateUDPCommandPortChanged:nil];
	[self crateUDPCommandIPChanged:nil];
	[self crateUDPReplyPortChanged:nil];
	[self crateUDPCommandChanged:nil];
	[self isListeningOnServerSocketChanged:nil];
}


- (void) checkGlobalSecurity
{
    [super checkGlobalSecurity]; 
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:[model sbcLockName] to:secure];
}


- (void) settingsLockChanged:(NSNotification*)aNotification
{
    [super settingsLockChanged:aNotification];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:OREdelweissSLTSettingsLock];
    BOOL locked = [gSecurity isLocked:OREdelweissSLTSettingsLock];
	BOOL isRunning = [gOrcaGlobals runInProgress];
	
	
	[triggerEnableMatrix setEnabled:!lockedOrRunningMaintenance]; 
    [inhibitEnableMatrix setEnabled:!lockedOrRunningMaintenance];
	[hwVersionButton setEnabled:!isRunning];
	[enableDisableCountersMatrix setEnabled:!isRunning];

	[loadPatternFileButton setEnabled:!lockedOrRunningMaintenance];
	[definePatternFileButton setEnabled:!lockedOrRunningMaintenance];
	[setSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[relSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[resetPageManagerButton setEnabled:!lockedOrRunningMaintenance];
	[forceTriggerButton setEnabled:!lockedOrRunningMaintenance];
	[initBoardButton setEnabled:!lockedOrRunningMaintenance];
	[initBoard1Button setEnabled:!lockedOrRunningMaintenance];
	[readBoardButton setEnabled:!lockedOrRunningMaintenance];
	[secStrobeSrcPU setEnabled:!lockedOrRunningMaintenance]; 
	
	[setSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[relSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[forceTrigger1Button setEnabled:!lockedOrRunningMaintenance];

	[resetHWButton setEnabled:!isRunning];
	
	[pulserAmpField setEnabled:!locked];
		
	[pageSizeField setEnabled:!lockedOrRunningMaintenance];
	[pageSizeStepper setEnabled:!lockedOrRunningMaintenance];
	
	
	[nextPageDelaySlider setEnabled:!lockedOrRunningMaintenance];
	
	[self enableRegControls];
}

- (void) enableRegControls
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:OREdelweissSLTSettingsLock];
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

- (void) hwVersionChanged:(NSNotification*) aNote
{
	NSString* s = [NSString stringWithFormat:@"%d,0x%x,0x%x",[model projectVersion],[model documentVersion],[model implementation]];
	[hwVersionField setStringValue:s];
}

- (void) writeValueChanged:(NSNotification*) aNote
{
	[self updateStepper:regWriteValueStepper setting:[model writeValue]];
	[regWriteValueTextField setIntValue:[model writeValue]];
}

- (void) displayEventLoopChanged:(NSNotification*) aNote
{
	[displayEventLoopButton setState:[model displayEventLoop]];
}

- (void) displayTriggerChanged:(NSNotification*) aNote
{
	[displayTriggerButton setState:[model displayTrigger]];
}


- (void) selectedRegIndexChanged:(NSNotification*) aNote
{
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerPopUp	 setting:index];
	
	[self enableRegControls];
}


- (void) controlRegChanged:(NSNotification*)aNote
{
	unsigned long value = [model controlReg];
	unsigned long aMask = (value & kCtrlTrgEnMask)>>kCtrlTrgEnShift;
	int i;
	for(i=0;i<6;i++)[[triggerEnableMatrix cellWithTag:i] setIntValue:aMask & (0x1<<i)];
	
	aMask = (value & kCtrlInhEnMask)>>kCtrlInhEnShift;
	for(i=0;i<4;i++)[[inhibitEnableMatrix cellWithTag:i] setIntValue:aMask & (0x1<<i)];
	
	aMask = (value & kCtrlTpEnMask)>>kCtrlTpEnEnShift;
	[testPatternEnableMatrix selectCellWithTag:aMask];
	
	[[miscCntrlBitsMatrix cellWithTag:0] setIntValue:value & kCtrlPPSMask];
	[[miscCntrlBitsMatrix cellWithTag:1] setIntValue:value & kCtrlShapeMask];
	[[miscCntrlBitsMatrix cellWithTag:2] setIntValue:value & kCtrlRunMask];
	[[miscCntrlBitsMatrix cellWithTag:3] setIntValue:value & kCtrlTstSltMask];
	[[miscCntrlBitsMatrix cellWithTag:4] setIntValue:value & kCtrlIntEnMask];
	[[miscCntrlBitsMatrix cellWithTag:5] setIntValue:value & kCtrlLedOffmask];	
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
//reply socket (server)
- (IBAction) startListeningForReplyButtonAction:(id)sender
{
	NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model startListeningServerSocket];	
}


- (IBAction) stopListeningForReplyButtonAction:(id)sender
{
	NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model stopListeningServerSocket];	
}

- (void) crateUDPCommandPortTextFieldAction:(id)sender
{
	[model setCrateUDPCommandPort:[sender intValue]];	
}




//command socket (client)
- (void) crateUDPCommandSendButtonAction:(id)sender
{
	//NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model sendUDPCommand];	
}

- (void) crateUDPCommandTextFieldAction:(id)sender
{
	[model setCrateUDPCommand:[sender stringValue]];	
}

- (void) crateUDPReplyPortTextFieldAction:(id)sender
{
	[model setCrateUDPReplyPort:[sender intValue]];	
}

- (void) crateUDPCommandIPTextFieldAction:(id)sender
{
	[model setCrateUDPCommandIP:[sender stringValue]];	
}

- (IBAction) openCommandSocketButtonAction:(id)sender
{
	NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model openCommandSocket];	
}

- (IBAction) closeCommandSocketButtonAction:(id)sender
{
	NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model closeCommandSocket];	
}







- (void) secondsSetInitWithHostButtonAction:(id)sender
{
	[model setSecondsSetInitWithHost:[secondsSetInitWithHostButton intValue]];	
}

- (void) sltScriptArgumentsTextFieldAction:(id)sender
{
	[model setSltScriptArguments:[sender stringValue]];	
}

- (void) enableDisableCounterAction:(id)sender
{
	[model setCountersEnabled:[[sender selectedCell]tag]];	
}

- (IBAction) secondsSetAction:(id)sender
{
	[model setSecondsSet:[sender intValue]];	
}

- (IBAction) triggerEnableAction:(id)sender
{
	unsigned long aMask = 0;
	int i;
	for(i=0;i<6;i++){
		if([[triggerEnableMatrix cellWithTag:i] intValue]) aMask |= (1L<<i);
		else aMask &= ~(1L<<i);
	}
	unsigned long theRegValue = [model controlReg] & ~kCtrlTrgEnMask; 
	theRegValue |= (aMask<< kCtrlTrgEnShift);
	[model setControlReg:theRegValue];
}

- (IBAction) inhibitEnableAction:(id)sender;
{
	unsigned long aMask = 0;
	int i;
	for(i=0;i<4;i++){
		if([[inhibitEnableMatrix cellWithTag:i] intValue]) aMask |= (1L<<i);
		else aMask &= ~(1L<<i);
	}
	unsigned long theRegValue = [model controlReg] & ~kCtrlInhEnMask; 
	theRegValue |= (aMask<<kCtrlInhEnShift);
	[model setControlReg:theRegValue];
}

- (IBAction) testPatternEnableAction:(id)sender;
{
	unsigned long aMask       = [[testPatternEnableMatrix selectedCell] tag];
	unsigned long theRegValue = [model controlReg] & ~kCtrlTpEnMask; 
	theRegValue |= (aMask<<kCtrlTpEnEnShift);
	[model setControlReg:theRegValue];
}

- (IBAction) miscCntrlBitsAction:(id)sender;
{
	unsigned long theRegValue = [model controlReg] & ~(kCtrlPPSMask | kCtrlShapeMask | kCtrlRunMask | kCtrlTstSltMask | kCtrlIntEnMask | kCtrlLedOffmask); 
	if([[miscCntrlBitsMatrix cellWithTag:0] intValue])	theRegValue |= kCtrlPPSMask;
	if([[miscCntrlBitsMatrix cellWithTag:1] intValue])	theRegValue |= kCtrlShapeMask;
	if([[miscCntrlBitsMatrix cellWithTag:2] intValue])	theRegValue |= kCtrlRunMask;
	if([[miscCntrlBitsMatrix cellWithTag:3] intValue])	theRegValue |= kCtrlTstSltMask;
	if([[miscCntrlBitsMatrix cellWithTag:4] intValue])	theRegValue |= kCtrlIntEnMask;
	if([[miscCntrlBitsMatrix cellWithTag:5] intValue])	theRegValue |= kCtrlLedOffmask;

	[model setControlReg:theRegValue];
}

//----------------------------------



- (IBAction) dumpPageStatus:(id)sender
{
	if([[NSApp currentEvent] clickCount] >=2){
		//int pageIndex = [sender selectedRow]*32 + [sender selectedColumn];
		@try {
			//[model dumpTriggerRAM:pageIndex];
		}
		@catch(NSException* localException) {
			NSLog(@"Exception doing SLT dump trigger RAM page\n");
			NSRunAlertPanel([localException name], @"%@\nSLT%d dump trigger RAM failed", @"OK", nil, nil,
							localException,[model stationNumber]);
		}
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
	for(i=0;i<16;i++){
		if([[interruptMaskMatrix cellWithTag:i] intValue]) aMaskValue |= (1L<<i);
		else aMaskValue &= ~(1L<<i);
	}
	[model setInterruptMask:aMaskValue];	
}

- (IBAction) nextPageDelayAction:(id)sender
{
	[model setNextPageDelay:100-[sender intValue]];	
}

- (IBAction) pageSizeAction:(id)sender
{
	[model setPageSize:[sender intValue]];	
}

- (IBAction) displayTriggerAction:(id)sender
{
	[model setDisplayTrigger:[sender intValue]];	
}


- (IBAction) displayEventLoopAction:(id)sender
{
	[model setDisplayEventLoop:[sender intValue]];	
}


- (IBAction) initBoardAction:(id)sender
{
	@try {
		[self endEditing];
		[model initBoard];
		NSLog(@"SLT%d initialized\n",[model stationNumber]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception SLT init\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d InitBoard failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) readStatus:(id)sender
{
	[model readStatusReg];
}

- (IBAction) reportAllAction:(id)sender
{
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont, @"SLT station# %d Report:\n",[model stationNumber]);

	@try {
		NSLogFont(aFont, @"Board ID: %lld\n",[model readBoardID]);
		[model printStatusReg];
		[model printControlReg];
		NSLogFont(aFont,@"--------------------------------------\n");
		NSLogFont(aFont,@"Dead Time  : %lld\n",[model readDeadTime]);
		NSLogFont(aFont,@"Veto Time  : %lld\n",[model readVetoTime]);
		NSLogFont(aFont,@"Run Time   : %lld\n",[model readRunTime]);
		NSLogFont(aFont,@"Seconds    : %d\n",  [model getSeconds]);
		[model printInterruptMask];
		[model printInterruptRequests];
	    long fdhwlibVersion = [model getFdhwlibVersion];  //TODO: write a method [model printFdhwlibVersion];
	    int ver=(fdhwlibVersion>>16) & 0xff,maj =(fdhwlibVersion>>8) & 0xff,min = fdhwlibVersion & 0xff;
	    NSLogFont(aFont,@"%@: SBC PrPMC running with fdhwlib version: %i.%i.%i (0x%08x)\n",[model fullID],ver,maj,min, fdhwlibVersion);
	    NSLogFont(aFont,@"SBC PrPMC readout code version: %i \n", [model getSBCCodeVersion]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT status\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
	
	[self hwVersionAction: self]; //display SLT firmware version, fdhwlib ver, SLT PCI driver ver
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:OREdelweissSLTSettingsLock to:[sender intValue] forWindow:[self window]];
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
	@try {
		unsigned long value = [model readReg:index];
		NSLog(@"SLT reg: %@ value: 0x%x\n",[model getRegisterName:index],value);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT reg: %@\n",[model getRegisterName:index]);
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}
- (IBAction) writeRegAction: (id) sender
{
	[self endEditing];
	int index = [registerPopUp indexOfSelectedItem];
	@try {
		[model writeReg:index value:[model writeValue]];
		NSLog(@"wrote 0x%x to SLT reg: %@ \n",[model writeValue],[model getRegisterName:index]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception writing SLT reg: %@\n",[model getRegisterName:index]);
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) hwVersionAction: (id) sender
{
	@try {
		[model readHwVersion];
		//NSLog(@"%@ Project:%d Doc:%d Implementation:%d\n",[model fullID], [model projectVersion], [model documentVersion], [model implementation]);
		NSLog(@"%@ Project:%d Doc:0x%x Implementation:0x%x\n",[model fullID], [model projectVersion], [model documentVersion], [model implementation]);
		long fdhwlibVersion = [model getFdhwlibVersion];
		int ver=(fdhwlibVersion>>16) & 0xff,maj =(fdhwlibVersion>>8) & 0xff,min = fdhwlibVersion & 0xff;
	    NSLog(@"%@: SBC PrPMC running with fdhwlib version: %i.%i.%i (0x%08x)\n",[model fullID],ver,maj,min, fdhwlibVersion);
		long SltPciDriverVersion = [model getSltPciDriverVersion];
		//NSLog(@"%@: SLT PCI driver version: %i\n",[model fullID],SltPciDriverVersion);
	    if(SltPciDriverVersion<0) NSLog(@"%@: unknown SLT PCI driver version: %i\n",[model fullID],SltPciDriverVersion);
        else if(SltPciDriverVersion==0) NSLog(@"%@: SBC running with SLT PCI driver version: %i (fzk_ipe_slt)\n",[model fullID],SltPciDriverVersion);
        else if(SltPciDriverVersion==1) NSLog(@"%@: SBC running with SLT PCI driver version: %i (fzk_ipe_slt_dma)\n",[model fullID],SltPciDriverVersion);
        else NSLog(@"%@: SBC running with SLT PCI driver version: %i (fzk_ipe_slt%i)\n",[model fullID],SltPciDriverVersion,SltPciDriverVersion);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT HW Model Version\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

//most of these are not currently connected to anything.. used during testing..
- (IBAction) enableCountersAction:(id)sender	{ [self do:@selector(writeEnCnt) name:@"Enable Counters"]; }
- (IBAction) disableCountersAction:(id)sender	{ [self do:@selector(writeDisCnt) name:@"Disable Counters"]; }
- (IBAction) clearCountersAction:(id)sender		{ [self do:@selector(writeClrCnt) name:@"Clear Counters"]; }
- (IBAction) activateSWRequestAction:(id)sender	{ [self do:@selector(writeSwRq) name:@"Active SW Request Interrupt"]; }
- (IBAction) configureFPGAsAction:(id)sender	{ [self do:@selector(writeFwCfg) name:@"Config FPGAs"]; }
- (IBAction) tpStartAction:(id)sender			{ [self do:@selector(writeTpStart) name:@"Test Pattern Start"]; }
- (IBAction) resetFLTAction:(id)sender			{ [self do:@selector(writeFltReset) name:@"FLT Reset"]; }
- (IBAction) resetSLTAction:(id)sender			{ [self do:@selector(writeSltReset) name:@"SLT Reset"]; }
- (IBAction) writeSWTrigAction:(id)sender		{ [self do:@selector(writeSwTrigger) name:@"SW Trigger"]; }
- (IBAction) writeClrInhibitAction:(id)sender	{ [self do:@selector(writeClrInhibit) name:@"Clr Inhibit"]; }
- (IBAction) writeSetInhibitAction:(id)sender	{ [self do:@selector(writeSetInhibit) name:@"Set Inhibit"]; }
- (IBAction) resetPageManagerAction:(id)sender	{ [self do:@selector(writePageManagerReset) name:@"Reset Page Manager"]; }
- (IBAction) releaseAllPagesAction:(id)sender	{ [self do:@selector(writeReleasePage) name:@"Release Pages"]; }

- (IBAction) sendCommandScript:(id)sender
{
	[self endEditing];
	NSString *fullCommand = [NSString stringWithFormat: @"shellcommand %@",[model sltScriptArguments]];
	[model sendPMCCommandScript: fullCommand];  
}

- (IBAction) sendSimulationConfigScriptON:(id)sender
{
	//[self killCrateAction: nil];//TODO: this seems not to be modal ??? -tb- 2010-04-27
    NSBeginAlertSheet(@"This will KILL the crate process before compiling and starting simulation mode. "
						"There may be other ORCAs connected to the crate. You need to do a 'Force reload' before.",
                      @"Cancel",
                      @"Yes, Kill Crate",
                      nil,[self window],
                      self,
                      @selector(_SLTv4killCrateAndStartSimDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Is this really what you want?");
}

- (void) _SLTv4killCrateAndStartSimDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
//NSLog(@"This is my _killCrateDidEnd: -tb-\n");
	//called
	if(returnCode == NSAlertAlternateReturn){		
		[[model sbcLink] killCrate]; //XCode says "No '-killCrate' method found!" but it is found during runtime!! -tb- How to get rid of this warning?
		BOOL rememberState = [[model sbcLink] forceReload];
		if(rememberState) [[model sbcLink] setForceReload: NO];
		[model sendSimulationConfigScriptON];  
		//[self connectionAction: nil];
		//[self toggleCrateAction: nil];
		//[[model sbcLink] startCrate]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
		//   [[model sbcLink] startCrateProcess]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
		[[model sbcLink] startCrate];
		if(rememberState !=[[model sbcLink] forceReload]) [[model sbcLink] setForceReload: rememberState];
	}
}


- (IBAction) sendSimulationConfigScriptOFF:(id)sender
{
	[model sendSimulationConfigScriptOFF];  
	NSLog(@"Sending simulation-mode-off script is still under development. If it fails just stop and force-reload-start the crate.\n");
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
	@try {
		//[model loadPulserValues];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception loading SLT pulser values\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d load pulser failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
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
    
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* fileName = [[openPanel URL] path];
            [model setPatternFilePath:fileName];
        }
    }];
#else 	
    [openPanel beginSheetForDirectory:startDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(loadPatternPanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
#endif
}

- (IBAction) loadPatternFile:(id)sender
{
	//[model loadPatternFile];
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

@implementation OREdelweissSLTController (private)
#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
-(void)loadPatternPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* fileName = [[sheet filenames] objectAtIndex:0];
        [model setPatternFilePath:fileName];
    }
}
#endif

- (void) calibrationSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
		@try {
			[model autoCalibrate];
		}
		@catch(NSException* localException) {
		}
    }    
}

- (void) do:(SEL)aSelector name:(NSString*)aName
{
	@try { 
		[model performSelector:aSelector]; 
		NSLog(@"SLT: Manual %@\n",aName);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception doing SLT %@\n",aName);
        NSRunAlertPanel([localException name], @"%@\nSLT%d %@ failed", @"OK", nil, nil,
                        localException,[model stationNumber],aName);
	}
}

@end


