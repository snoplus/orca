//
//  XL3_LinkController.m
//  ORCA
//
//  Created by Jarek Kaspar on Sat, Jul 9, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "XL3_Cmds.h"
#import "XL3_LinkController.h"
#import "XL3_Link.h"
#import "ORXL3Model.h"
#import "ORSNOCrateModel.h"

@implementation XL3_LinkController

#pragma mark •••Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"XL3_Link"];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[self populatePullDown];
}	

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	if(aModel) [[self window] setTitle:[model shortName]];
	//[self setDriverInfo];
}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];

	[notifyCenter addObserver : self
			 selector : @selector(linkConnectionChanged:)
			     name : XL3_LinkConnectionChanged
			    object: [model xl3Link]];

	[notifyCenter addObserver : self
			 selector : @selector(selectedRegisterChanged:)
			     name : ORXL3ModelSelectedRegisterChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(repeatCountChanged:)
			     name : ORXL3ModelRepeatCountChanged
			   object : model];
	
	[notifyCenter addObserver : self
			 selector : @selector(repeatDelayChanged:)
			     name : ORXL3ModelRepeatDelayChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(autoIncrementChanged:)
			     name : ORXL3ModelAutoIncrementChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(basicOpsRunningChanged:)
			     name : ORXL3ModelBasicOpsRunningChanged
			   object : model];
	
	[notifyCenter addObserver : self
			 selector : @selector(writeValueChanged:)
			     name : ORXL3ModelWriteValueChanged
			   object : model];
	
	[notifyCenter addObserver : self
			 selector : @selector(ipNumberChanged:)
			     name : XL3_LinkIPNumberChanged
			   object : [model xl3Link]];
	
	[notifyCenter addObserver : self
			 selector : @selector(connectStateChanged:)
			     name : XL3_LinkConnectStateChanged
			    object: [model xl3Link]];

	[notifyCenter addObserver : self
			 selector : @selector(errorTimeOutChanged:)
			     name : XL3_LinkErrorTimeOutChanged
			   object : [model xl3Link]];		
}

- (void) updateWindow
{
	[super updateWindow];

	[self settingsLockChanged:nil];
	//basic ops
	[self selectedRegisterChanged:nil];
	[self repeatCountChanged:nil];
	[self repeatDelayChanged:nil];
	[self autoIncrementChanged:nil];
	[self basicOpsRunningChanged:nil];
	[self writeValueChanged:nil];

	//ip connection
	[self errorTimeOutChanged:nil];

	/*
	
	[self filePathChanged:nil];
	[self verboseChanged:nil];
	[self forceReloadChanged:nil];
	[self setToggleCrateButtonState];
	[self loadModeChanged:nil];
	
	[self byteRateChanged:nil];
	
	[self ipNumberChanged:nil];
	[self portNumberChanged:nil];
	[self initAfterConnectChanged:nil];
	
	[self addressChanged:nil];
	[self infoTypeChanged:nil];
	[self pingTaskChanged:nil];
	[self cbTestChanged:nil];
	[self numTestPointsChanged:nil];
	[self payloadSizeChanged:nil];
	
	[self lamSlotChanged:nil];
*/
}

- (void) checkGlobalSecurity
{
	BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
	[gSecurity setLock:[model xl3LockName] to:secure];
	[lockButton setEnabled:secure];
}

#pragma mark •••Interface Management


- (void) settingsLockChanged:(NSNotification*)aNotification
{
	BOOL locked = [gSecurity isLocked:[model xl3LockName]];   
	[lockButton setState: locked];
	[self xl3LockChanged:aNotification];
}

- (void) xl3LockChanged:(NSNotification*)aNotification
{
	
	//BOOL runInProgress = [gOrcaGlobals runInProgress];
	BOOL locked = [gSecurity isLocked:[model xl3LockName]];
	//BOOL connected		 = [[model xl3Link] isConnected];
/*	
	[clearHistoryButton setEnabled:!locked  && !connected];
	[ipNumberComboBox setEnabled:!locked  && !connected];
	[portNumberField setEnabled:!locked  && !connected];
	[passWordField setEnabled:!locked && !connected];
	[userNameField setEnabled:!locked && !connected];
	[pingButton setEnabled:!locked && !runInProgress];
	[cbTestButton setEnabled:!locked && !runInProgress && connected];
	[payloadSizeSlider setEnabled:!locked && !runInProgress && connected];
	[connectButton setEnabled:!locked && !runInProgress];
	[connect1Button setEnabled:!locked && !runInProgress];
	[killCrateButton setEnabled:!locked && !runInProgress];
	[loadModeMatrix setEnabled:!locked && !runInProgress];
	[forceReloadButton setEnabled:!locked && !runInProgress];
	[verboseButton setEnabled:!locked && !runInProgress];
*/
	[errorTimeOutPU setEnabled:!locked];
	//[self setToggleCrateButtonState];

}

#pragma mark •basic ops
- (void) repeatCountChanged:(NSNotification*)aNote
{
	[repeatCountField setIntValue: [model repeatOpCount]];
	[repeatCountStepper setIntValue: [model repeatOpCount]];
}

- (void) repeatDelayChanged:(NSNotification*)aNote
{
	[repeatDelayField setIntValue:[model repeatDelay]];
	[repeatDelayStepper setIntValue: [model repeatDelay]];
}

- (void) autoIncrementChanged:(NSNotification*)aNote
{
	[autoIncrementCB setState:[model autoIncrement]];
}

- (void) basicOpsRunningChanged:(NSNotification*)aNote
{
	if ([model basicOpsRunning]) [basicOpsRunningIndicator startAnimation:model];
	else [basicOpsRunningIndicator stopAnimation:model];
}

- (void) writeValueChanged:(NSNotification*)aNote
{
	[writeValueField setIntValue:[model writeValue]];
	[writeValueStepper setIntValue:[model writeValue]];
}

- (void) selectedRegisterChanged:(NSNotification*)aNote
{
	[selectedRegisterPU selectItemAtIndex: [model selectedRegister]];
}

#pragma mark •ip connection

- (void) linkConnectionChanged:(NSNotification*)aNote
{
	
}


- (void) connectStateChanged:(NSNotification*)aNote
{
	BOOL runInProgress = [gOrcaGlobals runInProgress];
	BOOL locked = [gSecurity isLocked:[model xl3LockName]];
	if(runInProgress) {
		[toggleConnectButton setTitle:@"---"];
		[toggleConnectButton setEnabled:NO];
	}
	else {
		if([[model xl3Link] connectState] == kDisconnected){
			[toggleConnectButton setTitle:@"Connect"];
			
		}
		else {
			[toggleConnectButton setTitle:@"Disconnect"];
		}
		[toggleConnectButton setEnabled:!locked];
	}	
}

- (void) ipNumberChanged:(NSNotification*)aNote;
{
	//todo
}

- (void) errorTimeOutChanged:(NSNotification*)aNote
{
	[errorTimeOutPU selectItemAtIndex:[[model xl3Link] errorTimeOut]];
}


#pragma mark •••Helper

- (void) populatePullDown
{
	short	i;
	[selectedRegisterPU removeAllItems];
	for (i = 0; i < [model getNumberRegisters]; i++) {
		[selectedRegisterPU insertItemWithTitle:[model getRegisterName:i] atIndex:i];
	}
	[self selectedRegisterChanged:nil];
}


#pragma mark •••Actions
- (IBAction) lockAction:(id)sender
{
	[gSecurity tryToSetLock:[model xl3LockName] to:[sender intValue] forWindow:[self window]];
}


- (void) basicSelectedRegisterAction:(id)sender
{
	[model setSelectedRegister:[sender indexOfSelectedItem]];	
}

- (IBAction) basicReadAction:(id)sender
{
	[model readBasicOps];
}

- (IBAction) basicWriteAction:(id)sender
{
	[model writeBasicOps];
}

- (IBAction) basicStopAction:(id)sender
{
	[model stopBasicOps];
}

- (IBAction) basicStatusAction:(id) sender
{
	[model reportStatus];
}

- (IBAction) repeatCountAction:(id) sender
{
	[model setRepeatOpCount:[sender intValue]];	
}

- (IBAction) repeatDelayAction:(id) sender
{
	[model setRepeatDelay:[sender intValue]];
}

- (IBAction) autoIncrementAction:(id) sender
{
	[model setAutoIncrement:[sender intValue]];
}

- (IBAction) writeValueAction:(id) sender;
{
	[model setWriteValue:[sender intValue]];
}

- (void) toggleConnectAction:(id)sender
{
	[[model xl3Link] toggleConnect];
}

- (IBAction) errorTimeOutAction:(id)sender
{
	[[model xl3Link] setErrorTimeOut:[sender indexOfSelectedItem]];
}

@end
