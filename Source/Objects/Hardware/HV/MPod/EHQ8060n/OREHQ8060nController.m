//-------------------------------------------------------------------------
//  OREHQ8060nController.h
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
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
#import "OREHQ8060nController.h"
#import "OREHQ8060nModel.h"
#import "TimedWorker.h"

@implementation OREHQ8060nController

-(id)init
{
    self = [super initWithWindowNibName:@"EHQ8060n"];
    
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) awakeFromNib
{
	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter setFormat:@"0.0"];
	int i;
	for(i=0;i<8;i++){
		[[targetMatrix cellAtRow:i column:0]  setTag:i];
		[[voltageMatrix cellAtRow:i column:0]  setTag:i];
		[[currentMatrix cellAtRow:i column:0]  setTag:i];
		[[onlineMaskMatrix cellAtRow:i column:0]  setTag:i];
		
		[[currentMatrix cellAtRow:i column:0] setFormatter:numberFormatter];
		[[voltageMatrix cellAtRow:i column:0] setFormatter:numberFormatter];

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
						 name : ORMPodCardSlotChangedNotification
					   object : model];
	    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : OREHQ8060nSettingsLock
                        object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(targetChanged:)
                         name : OREHQ8060nModelTargetChanged
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(voltageChanged:)
                         name : OREHQ8060nModelVoltageChanged
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(currentChanged:)
                         name : OREHQ8060nModelCurrentChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollRateChanged:)
                         name : TimedWorkerTimeIntervalChangedNotification
                       object : [model poller]];
	
	[notifyCenter addObserver : self
                     selector : @selector(pollRunningChanged:)
                         name : TimedWorkerIsRunningChangedNotification
                       object : [model poller]];
		
    [notifyCenter addObserver : self
					 selector : @selector(onlineMaskChanged:)
						 name : OREHQ8060nModelOnlineMaskChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(riseRateChanged:)
						 name : OREHQ8060nModelRiseRateChanged
					   object : model];
		
	[notifyCenter addObserver : self
					 selector : @selector(channelReadParamsChanged:)
						 name : OREHQ8060nModelChannelReadParamsChanged
					   object : model];
	
	
}

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self targetChanged:nil];
	[self voltageChanged:nil];
	[self currentChanged:nil];
    [self pollRunningChanged:nil];
    [self pollRateChanged:nil];
    [self onlineMaskChanged:nil];
    [self riseRateChanged:nil];
    [self channelReadParamsChanged:nil];
	
}

#pragma mark •••Interface Management
- (void) channelReadParamsChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<8;i++){
		[[stateMatrix cellWithTag:i] setObjectValue:[model channel:i readParamAsInt:@"outputSwitch"]?@"ON":@"OFF"];
		[[voltageMatrix cellWithTag:i] setFloatValue:[model channel:i readParamAsFloat:@"outputMeasurementSenseVoltage"]];
		[[currentMatrix cellWithTag:i] setFloatValue:[model channel:i readParamAsFloat:@"outputMeasurementCurrent"]];
	}
}

- (void) onlineMaskChanged:(NSNotification*)aNote
{
	short i;
	unsigned char theMask = [model onlineMask];
	for(i=0;i<8;i++){
		BOOL bitSet = (theMask&(1<<i))>0;
		[[onlineMaskMatrix cellWithTag:i] setState:bitSet];
	}
	[self settingsLockChanged:nil];
}

- (void) riseRateChanged:(NSNotification*)aNote
{
	[riseRateField setFloatValue:[model riseRate]];
}

- (void) pollRateChanged:(NSNotification*)aNote
{
    if(aNote== nil || [aNote object] == [model poller]){
        [pollRatePopup selectItemAtIndex:[pollRatePopup indexOfItemWithTag:[[model poller] timeInterval]]];
    }
}

- (void) pollRunningChanged:(NSNotification*)aNote
{
    if(aNote== nil || [aNote object] == [model poller]){
        if([[model poller] isRunning])[pollRunningIndicator startAnimation:self];
        else [pollRunningIndicator stopAnimation:self];
    }
}
- (void) voltageChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<8;i++){
		[[voltageMatrix cellWithTag:i] setIntValue:[model voltage:i]];
	}
}
- (void) targetChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<8;i++){
		[[targetMatrix cellWithTag:i] setIntValue:[model target:i]];
	}
}
- (void) currentChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<8;i++){
		[[currentMatrix cellWithTag:i] setFloatValue:[model current:i]];
	}
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:OREHQ8060nSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
   // BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:OREHQ8060nSettingsLock];
    BOOL locked = [gSecurity isLocked:OREHQ8060nSettingsLock];
    	
    [settingLockButton setState: locked];
	
	[voltageMatrix setEnabled:!lockedOrRunningMaintenance];
	
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"EHQ8060n Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [[self window] setTitle:[NSString stringWithFormat:@"EHQ8060n Card (Slot %d)",[model slot]]];
}

#pragma mark •••Actions
- (IBAction) onlineAction:(id)sender
{
	if([sender intValue] != [model onlineMaskBit:[[sender selectedCell] tag]]){
		[model setOnlineMaskBit:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) riseRateAction:(id)sender
{
	if([sender intValue] != [model riseRate]){
		[model setRiseRate:[sender floatValue]];
	}
}


- (IBAction) targetAction:(id)sender
{
	if([sender intValue] != [model target:[[sender selectedCell] tag]]){
		[model setTarget:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) currentAction:(id)sender
{
	if([sender intValue] != [model current:[[sender selectedCell] tag]]){
		[model setCurrent:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:OREHQ8060nSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) pollNowAction:(id)sender
{
	[model updateAllValues];
}

- (IBAction) pollRateAction:(id)sender
{
    [model setPollingInterval:[[pollRatePopup selectedItem] tag]];
}

- (IBAction) syncAction:(id)sender
{
    [model syncDialog];
}


@end
