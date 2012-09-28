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
	controlSize			= NSMakeSize(650,670);
    statusSize			= NSMakeSize(650,670);
    lowLevelSize		= NSMakeSize(650,500);
    cpuManagementSize	= NSMakeSize(650,500);
    cpuTestsSize		= NSMakeSize(650,450);
    udpKCmdSize		    = NSMakeSize(650,670);
    streamingSize		= NSMakeSize(650,670);
    udpDReadSize		= NSMakeSize(650,670);
	
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
                     selector : @selector(clockTimeChanged:)
                         name : OREdelweissSLTModelClockTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sltScriptArgumentsChanged:)
                         name : OREdelweissSLTModelSltScriptArgumentsChanged
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

    [notifyCenter addObserver : self
                     selector : @selector(selectedFifoIndexChanged:)
                         name : OREdelweissSLTModelSelectedFifoIndexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pixelBusEnableRegChanged:)
                         name : OREdelweissSLTModelPixelBusEnableRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(eventFifoStatusRegChanged:)
                         name : OREdelweissSLTModelEventFifoStatusRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPDataPortChanged:)
                         name : OREdelweissSLTModelCrateUDPDataPortChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPDataIPChanged:)
                         name : OREdelweissSLTModelCrateUDPDataIPChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPDataReplyPortChanged:)
                         name : OREdelweissSLTModelCrateUDPDataReplyPortChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isListeningOnDataServerSocketChanged:)
                         name : OREdelweissSLTModelIsListeningOnDataServerSocketChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(numRequestedUDPPacketsChanged:)
                         name : OREdelweissSLTModelNumRequestedUDPPacketsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(openDataCommandSocketChanged:)
                         name : OREdelweissSLTModelOpenCloseDataCommandSocketChanged
						object: model];

}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Interface Management

- (void) numRequestedUDPPacketsChanged:(NSNotification*)aNote
{
	[numRequestedUDPPacketsTextField setIntValue: [model numRequestedUDPPackets]];
}

- (void) crateUDPDataReplyPortChanged:(NSNotification*)aNote
{
	[crateUDPDataReplyPortTextField setIntValue: [model crateUDPDataReplyPort]];
}

- (void) crateUDPDataIPChanged:(NSNotification*)aNote
{
	[crateUDPDataIPTextField setStringValue: [model crateUDPDataIP]];
}

- (void) crateUDPDataPortChanged:(NSNotification*)aNote
{
	[crateUDPDataPortTextField setIntValue: [model crateUDPDataPort]];
}

- (void) eventFifoStatusRegChanged:(NSNotification*)aNote
{
	//[eventFifoStatusRegTextField setIntValue: [model eventFifoStatusReg]];
	//[countersMatrix setIntValue: [model eventFifoStatusReg]];
	//[[countersMatrix cellWithTag:0] setStringValue: [NSString stringWithFormat:@"%qu",[model clockTime]]];
	[[countersMatrix cellWithTag:0] setIntValue:  ([model eventFifoStatusReg]&0x7ff) ];
	if([model eventFifoStatusReg]&0x400) [[countersMatrix cellWithTag:1] setStringValue:  @"EMPTY" ];
	else if([model eventFifoStatusReg]&0x800) [[countersMatrix cellWithTag:1] setStringValue:  @"OVFL" ];
	else  [[countersMatrix cellWithTag:1] setStringValue:  @"0" ];
}

- (void) pixelBusEnableRegChanged:(NSNotification*)aNote
{
	[pixelBusEnableRegTextField setIntValue: [model pixelBusEnableReg]];
	int i;
	for(i=0;i<16;i++){
		[[pixelBusEnableRegMatrix cellWithTag:i] setIntValue: ([model pixelBusEnableReg] & (0x1 <<i))];
	}    


}

- (void) selectedFifoIndexChanged:(NSNotification*)aNote
{
	[selectedFifoIndexPU selectItemWithTag: [model selectedFifoIndex]];
}

- (void) isListeningOnServerSocketChanged:(NSNotification*)aNote
{
    if([model isListeningOnServerSocket]){
	    [listeningForReplyIndicator  startAnimation: nil];
		[startListeningForReplyButton setEnabled:NO];
		[stopListeningForReplyButton setEnabled:YES];
	}
    else
	{
	    [listeningForReplyIndicator  stopAnimation: nil];
		[startListeningForReplyButton setEnabled:YES];
		[stopListeningForReplyButton setEnabled:NO];
	}
}

- (void) isListeningOnDataServerSocketChanged:(NSNotification*)aNote
{
	//[isListeningOnDataServerSocketNo Outlet setIntValue: [model isListeningOnDataServerSocket]];
	//TODO:  START PROGRESS INDICATOR etc
    if([model isListeningOnDataServerSocket]){
	    [listeningForDataReplyIndicator  startAnimation: nil];
		[startListeningForDataReplyButton setEnabled:NO];
		[stopListeningForDataReplyButton setEnabled:YES];
	}
    else
	{
	    [listeningForDataReplyIndicator  stopAnimation: nil];
		[startListeningForDataReplyButton setEnabled:YES];
		[stopListeningForDataReplyButton setEnabled:NO];
	}
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


- (void) openCommandSocketChanged:(NSNotification*)aNote
{
    if([model isOpenCommandSocket]){
	    [openCommandSocketIndicator  startAnimation: nil];
		[openCommandSocketButton setEnabled:NO];
		[closeCommandSocketButton setEnabled:YES];
	}
    else
	{
	    [openCommandSocketIndicator  stopAnimation: nil];
		[openCommandSocketButton setEnabled:YES];
		[closeCommandSocketButton setEnabled:NO];
	}

}

- (void) openDataCommandSocketChanged:(NSNotification*)aNote
{
    if([model isOpenDataCommandSocket]){
	    [openDataCommandSocketIndicator  startAnimation: nil];
		[openDataCommandSocketButton setEnabled:NO];
		[closeDataCommandSocketButton setEnabled:YES];
	}
    else
	{
	    [openDataCommandSocketIndicator  stopAnimation: nil];
		[openDataCommandSocketButton setEnabled:YES];
		[closeDataCommandSocketButton setEnabled:NO];
	}

}


- (void) sltScriptArgumentsChanged:(NSNotification*)aNote
{
	[sltScriptArgumentsTextField setStringValue: [model sltScriptArguments]];
}


- (void) clockTimeChanged:(NSNotification*)aNote
{
 	//NSLog(@"   %@::%@:   clockTime: 0x%016qx   \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[model clockTime]);//TODO: DEBUG testing ...-tb-
	//[[countersMatrix cellWithTag:3] setIntValue:[model clockTime]];  //setIntValue seems not to work for 64-bit integer? -tb-
	[[countersMatrix cellWithTag:3] setStringValue: [NSString stringWithFormat:@"%qu",[model clockTime]]];
}



- (void) statusRegChanged:(NSNotification*)aNote
{
	unsigned long statusReg = [model statusReg];
//DEBUG OUTPUT:  NSLog(@"WARNING: %@::%@: UNDER CONSTRUCTION! status reg: 0x%08x\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),statusReg);//TODO: DEBUG testing ...-tb-
	
	[[statusMatrix cellWithTag:0] setStringValue: IsBitSet(statusReg,kStatusIrq)?@"1":@"0"];
	[[statusMatrix cellWithTag:1] setStringValue: IsBitSet(statusReg,kStatusPixErr)?@"1":@"0"];

	[[statusMatrix cellWithTag:2] setStringValue: [NSString stringWithFormat:@"0x%04lx",ExtractValue(statusReg,0xffff,0)]];

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
		case  5: [self resizeWindowToSize:udpKCmdSize];				break;
		case  6: [self resizeWindowToSize:streamingSize];	    break;
		case  7: [self resizeWindowToSize:udpDReadSize];	    break;
		default: [self resizeWindowToSize:controlSize];	            break;
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
	[self clockTimeChanged:nil];
	[self sltScriptArgumentsChanged:nil];
	[self crateUDPCommandPortChanged:nil];
	[self crateUDPCommandIPChanged:nil];
	[self crateUDPReplyPortChanged:nil];
	[self crateUDPCommandChanged:nil];
	[self isListeningOnServerSocketChanged:nil];
	[self selectedFifoIndexChanged:nil];
	[self pixelBusEnableRegChanged:nil];
	[self eventFifoStatusRegChanged:nil];
    [self openCommandSocketChanged:nil];
    [self openDataCommandSocketChanged:nil];
	[self crateUDPDataPortChanged:nil];
	[self crateUDPDataIPChanged:nil];
	[self crateUDPDataReplyPortChanged:nil];
	[self isListeningOnDataServerSocketChanged:nil];
	[self numRequestedUDPPacketsChanged:nil];
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
	
	
	[hwVersionButton setEnabled:!isRunning];

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
	BOOL needsIndex = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegNeedsIndex)>0;
	
	[regWriteButton setEnabled:writeAllowed];
	[regReadButton setEnabled:readAllowed];
	
	[regWriteValueStepper setEnabled:writeAllowed];
	[regWriteValueTextField setEnabled:writeAllowed];

    [selectedFifoIndexPU setEnabled: needsIndex];
}

- (void) endAllEditing:(NSNotification*)aNotification
{
}

- (void) hwVersionChanged:(NSNotification*) aNote
{
	NSString* s = [NSString stringWithFormat:@"%lu,0x%lx,0x%lx",[model projectVersion],[model documentVersion],[model implementation]];
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
	
	[[miscCntrlBitsMatrix cellWithTag:0] setIntValue:value & kCtrlInvert];
	[[miscCntrlBitsMatrix cellWithTag:1] setIntValue:value & kCtrlLedOff];
	[[miscCntrlBitsMatrix cellWithTag:2] setIntValue:value & kCtrlOnLine];
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

	// Clear all the popup items.
    [selectedFifoIndexPU removeAllItems];
    
	// Populate the register popup
    for (i = 0; i < 16; i++) {
        [selectedFifoIndexPU insertItemWithTitle: [NSString stringWithFormat: @"%i",i ] atIndex:i];
        [[selectedFifoIndexPU itemAtIndex:i] setTag: i]; //I am not using the tag ... -tb-
    }
    [selectedFifoIndexPU insertItemWithTitle: @"All" atIndex:i];
    [[selectedFifoIndexPU itemAtIndex:i] setTag: i];//TODO: do I need this??? -tb-

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
- (IBAction) setMasterModeButtonAction:(id)sender
{
	[model writeMasterMode];
}

- (IBAction) setSlaveModeButtonAction:(id)sender
{
	[model writeSlaveMode];
}

- (void) eventFifoStatusRegTextFieldAction:(id)sender
{
	[model setEventFifoStatusReg:[sender intValue]];	
}

- (void) pixelBusEnableRegTextFieldAction:(id)sender
{
	[model setPixelBusEnableReg:[sender intValue]];	
}


- (void) pixelBusEnableRegMatrixAction:(id)sender
{
    //debug
	NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
//	[model setPixelBusEnableReg:[sender intValue]];	
	int i, val=0;
	for(i=0;i<16;i++){
		if([[sender cellWithTag:i] intValue]) val |= (0x1<<i);
	}
	[model setPixelBusEnableReg:val];
}

- (IBAction) writePixelBusEnableRegButtonAction:(id)sender
{
	[model writePixelBusEnableReg];	
}

- (IBAction) readPixelBusEnableRegButtonAction:(id)sender
{
	[model readPixelBusEnableReg];	
}


- (void) selectedFifoIndexPUAction:(id)sender
{
	[model setSelectedFifoIndex:[sender indexOfSelectedItem]];	//sender is selectedFifoIndexPU
}



//ADC data UDP connection
- (IBAction) startUDPDataConnectionButtonAction:(id)sender
{
    [self openDataCommandSocketButtonAction:nil];
    [self startListeningForDataReplyButtonAction:nil];
}

- (IBAction) stopUDPDataConnectionButtonAction:(id)sender
{
    [self closeDataCommandSocketButtonAction:nil];
    [self stopListeningForDataReplyButtonAction:nil];
}


- (void) crateUDPDataReplyPortTextFieldAction:(id)sender
{
	[model setCrateUDPDataReplyPort:[sender intValue]];	
}

- (void) crateUDPDataIPTextFieldAction:(id)sender
{
	[model setCrateUDPDataIP:[sender stringValue]];	
}

- (void) crateUDPDataPortTextFieldAction:(id)sender
{
	[model setCrateUDPDataPort:[sender intValue]];	
}

- (IBAction) openDataCommandSocketButtonAction:(id)sender
{
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model openDataCommandSocket];	
    //[self openDataCommandSocketChanged:nil];
}


- (IBAction) closeDataCommandSocketButtonAction:(id)sender
{
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model closeDataCommandSocket];	
    //[self openDataCommandSocketChanged:nil];
}


- (IBAction) startListeningForDataReplyButtonAction:(id)sender
{
    //debug 	NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model startListeningDataServerSocket];	
}

- (IBAction) stopListeningForDataReplyButtonAction:(id)sender
{
	NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model stopListeningDataServerSocket];	
}

- (IBAction) crateUDPDataCommandSendButtonAction:(id)sender
{
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model sendUDPDataCommandRequestUDPData];	
}

- (void) numRequestedUDPPacketsTextFieldAction:(id)sender
{
	[model setNumRequestedUDPPackets:[sender intValue]];	
}

- (IBAction) testUDPDataConnectionButtonAction:(id)sender
{
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model setRequestStoppingDataServerSocket:1];	
}


//K command UDP connection
//UDP command Connection Start/Stop all
- (IBAction) startUDPCommandConnectionButtonAction:(id)sender
{
    [self openCommandSocketButtonAction:nil];
    [self startListeningForReplyButtonAction:nil];
}

- (IBAction) stopUDPCommandConnectionButtonAction:(id)sender
{
    [self closeCommandSocketButtonAction:nil];
    [self stopListeningForReplyButtonAction:nil];
}

//reply socket (server)
- (IBAction) startListeningForReplyButtonAction:(id)sender
{
    //debug	NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model startListeningServerSocket];	
}


- (IBAction) stopListeningForReplyButtonAction:(id)sender
{
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model stopListeningServerSocket];	
}

- (void) crateUDPCommandPortTextFieldAction:(id)sender
{
	[model setCrateUDPCommandPort:[sender intValue]];	
}




//command socket (client)
- (IBAction) crateUDPCommandSendButtonAction:(id)sender
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
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model openCommandSocket];	
    [self openCommandSocketChanged:nil];//TODO: use a notification from model -tb-
}

- (IBAction) closeCommandSocketButtonAction:(id)sender
{
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model closeCommandSocket];	
    [self openCommandSocketChanged:nil];//TODO: use a notification from model -tb-
}







- (void) sltScriptArgumentsTextFieldAction:(id)sender
{
	[model setSltScriptArguments:[sender stringValue]];	
}


- (IBAction) miscCntrlBitsAction:(id)sender;
{
	unsigned long theRegValue = [model controlReg] & ~(kCtrlInvert | kCtrlLedOff | kCtrlOnLine); 
	if([[miscCntrlBitsMatrix cellWithTag:0] intValue])	theRegValue |= kCtrlInvert;
	if([[miscCntrlBitsMatrix cellWithTag:1] intValue])	theRegValue |= kCtrlLedOff;
	if([[miscCntrlBitsMatrix cellWithTag:2] intValue])	theRegValue |= kCtrlOnLine;

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
//DEBUG OUTPUT: 	NSLog(@"WARNING: %@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
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
		NSLogFont(aFont,@"SLT Time   : %lld\n",[model getTime]);
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
		//unsigned long value = [model readReg:index];
		//NSLog(@"SLT reg: %@ value: 0x%x\n",[model getRegisterName:index],value);
		unsigned long value;
        if(([model getAccessType:index] & kIpeRegNeedsIndex)){
            int fifoIndex = [model selectedFifoIndex];
		    value = [model readReg:index forFifo: fifoIndex ];
		    NSLog(@"FLTv4 reg: %@  for fifo# %i has value: 0x%x (%i)\n",[model getRegisterName:index], fifoIndex, value, value);
		    //NSLog(@"  (addr: 0x%08x = 0x%08x ... 0x%08x)  \n", ([model getAddress:index]|(fifoIndex << 14)), [model getAddress:index],  (fifoIndex << 14));
        }
		else {
		    value = [model readReg:index ];
		    NSLog(@"SLTv4 reg: %@ has value: 0x%x (%i)\n",[model getRegisterName:index],value, value);
        }
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
		//[model writeReg:index value:[model writeValue]];
		//NSLog(@"wrote 0x%x to SLT reg: %@ \n",[model writeValue],[model getRegisterName:index]);
		unsigned long val = [model writeValue];
        if(([model getAccessType:index] & kIpeRegNeedsIndex)){
            int fifoIndex = [model selectedFifoIndex];
		    [model writeReg:index forFifo: fifoIndex  value:val];
    		NSLog(@"wrote 0x%x (%i) to SLTv4 reg: %@ fifo# %i\n", val, val, [model getRegisterName:index], fifoIndex);
        }
		else {
		    [model writeReg:index value:val];
		    NSLog(@"wrote 0x%x to SLT reg: %@ \n",val,[model getRegisterName:index]);
        }
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
- (IBAction) configureFPGAsAction:(id)sender	{ [self do:@selector(writeFwCfg) name:@"Config FPGAs"]; }
- (IBAction) resetFLTAction:(id)sender			{ [self do:@selector(writeFltReset) name:@"FLT Reset"]; }
- (IBAction) resetSLTAction:(id)sender			{ [self do:@selector(writeSltReset) name:@"SLT Reset"]; }
- (IBAction) evResAction:(id)sender		        { [self do:@selector(writeEvRes) name:@"EvRes"]; }

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
		NSLog(@"Exception doing EDELWEISS SLT %@\n",aName);
        NSRunAlertPanel([localException name], @"%@\nSLT%d %@ failed", @"OK", nil, nil,
                        localException,[model stationNumber],aName);
	}
}

@end


