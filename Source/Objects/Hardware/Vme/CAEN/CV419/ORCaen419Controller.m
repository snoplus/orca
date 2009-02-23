//
//  ORCaen419Controller.m
//  Orca
//
//  Created by Mark Howe on 2/20/09
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nug Physics and 
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
#import "ORCaen419Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCaen419Model.h"

@implementation ORCaen419Controller
#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"Caen419" ];
    return self;
}

#pragma mark •••Notfications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
	
    [notifyCenter addObserver:self
					 selector:@selector(baseAddressChanged:)
						 name:ORVmeIOCardBaseAddressChangedNotification
					   object:model];
		
    [notifyCenter addObserver:self
					 selector:@selector(thresholdChanged:)
						 name:ORCaren419ThresholdChanged
					   object:model];
		
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : ORCaen419BasicLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(basicLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(auxAddressChanged:)
                         name : ORCaen419ModelAuxAddressChanged
						object: model];
    [notifyCenter addObserver : self
                     selector : @selector(linearGateModeChanged:)
                         name : ORCaen419ModelLinearGateModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(riseTimeProtectionChanged:)
                         name : ORCaen419ModelRiseTimeProtectionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(resetMaskChanged:)
                         name : ORCaen419ModelResetMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : ORCaen419ModelEnabledMaskChanged
						object: model];

}
- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
	[self auxAddressChanged:nil];
 	[self linearGateModeChanged:nil];
	[self riseTimeProtectionChanged:nil];
	[self resetMaskChanged:nil];
	[self enabledMaskChanged:nil];
	[self slotChanged:nil];
	
    short 	i;
    for (i = 0; i < [model numberOfChannels]; i++){
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:@"channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORCaren419ThresholdChanged object:model userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen419ModelRiseTimeProtectionChanged object:model userInfo:userInfo];
	}
	
    [self basicLockChanged:nil];
}

#pragma mark ***Interface Management
- (void) enabledMaskChanged:(NSNotification*)aNote
{
	short aMask = [model enabledMask];
	int i;
	for(i=0;i<kCV419NumberChannels;i++){
		[[enabledMaskMatrix cellWithTag:i] setIntValue:aMask&(1<<i)];
	}
}

- (void) resetMaskChanged:(NSNotification*)aNote
{
	short aMask = [model resetMask];
	int i;
	for(i=0;i<kCV419NumberChannels;i++){
		[[resetMaskMatrix cellWithTag:i] setIntValue:aMask&(1<<i)];
	}
}

- (void) riseTimeProtectionChanged:(NSNotification*)aNote
{
	int chnl = [[[aNote userInfo] objectForKey:@"channel"] intValue];
	int microSec = 2*([model riseTimeProtection:chnl] +1);
	[[riseTimeProtectionMatrix cellWithTag:chnl] setIntValue: microSec];
}

- (void) thresholdChanged:(NSNotification*) aNote
{
	int chnl = [[[aNote userInfo] objectForKey:@"channel"] intValue];
	[[thresholdMatrix cellWithTag:chnl] setIntValue:[model threshold:chnl]];
}

- (void) linearGateModeChanged:(NSNotification*)aNote
{
	[linearGateMode0PU selectItemAtIndex: [model linearGateMode:0]];
	[linearGateMode1PU selectItemAtIndex: [model linearGateMode:1]];
	[linearGateMode2PU selectItemAtIndex: [model linearGateMode:2]];
	[linearGateMode3PU selectItemAtIndex: [model linearGateMode:3]];
}

- (void) auxAddressChanged:(NSNotification*)aNote
{
	[auxAddressField setIntValue: [model auxAddress]];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORCaen419BasicLock to:secure];
    [basicLockButton setEnabled:secure];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
	[baseAddressField setIntValue: [model baseAddress]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) basicLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORCaen419BasicLock];
    BOOL locked = [gSecurity isLocked:ORCaen419BasicLock];
    [basicLockButton setState: locked];
    
    [baseAddressField setEnabled:!locked && !runInProgress];
    [auxAddressField setEnabled:!locked && !runInProgress];
    [enabledMaskMatrix setEnabled:!lockedOrRunningMaintenance];
    [resetMaskMatrix setEnabled:!lockedOrRunningMaintenance];
    [riseTimeProtectionMatrix setEnabled:!lockedOrRunningMaintenance];
    [linearGateMode0PU setEnabled:!lockedOrRunningMaintenance];
    [linearGateMode1PU setEnabled:!lockedOrRunningMaintenance];
    [linearGateMode2PU setEnabled:!lockedOrRunningMaintenance];
    [linearGateMode3PU setEnabled:!lockedOrRunningMaintenance];
    [thresholdMatrix setEnabled:!lockedOrRunningMaintenance];
    [readThresholdsButton setEnabled:!lockedOrRunningMaintenance];
    [writeThresholdsButton setEnabled:!lockedOrRunningMaintenance];
    [initButton setEnabled:!lockedOrRunningMaintenance];
    [fireButton setEnabled:!lockedOrRunningMaintenance];
	    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORCaen419BasicLock])s = @"Not in Maintenance Run.";
    }
    [basicLockDocField setStringValue:s];
}

#pragma mark •••Actions
- (void) enabledMaskAction:(id)sender
{
	short aMask = 0;
	int i;
	for(i=0;i<kCV419NumberChannels;i++){
		if([[enabledMaskMatrix cellWithTag:i] intValue]){
			aMask |= (1<<i);
		}
	}
	[model setEnabledMask:aMask];	
}

- (void) resetMaskAction:(id)sender
{
	short aMask = 0;
	int i;
	for(i=0;i<kCV419NumberChannels;i++){
		if([[resetMaskMatrix cellWithTag:i] intValue]){
			aMask |= (1<<i);
		}
	}
	[model setResetMask:aMask];	
}

- (void) riseTimeProtectionAction:(id)sender
{
    if ([sender intValue] != [model riseTimeProtection:[[sender selectedCell] tag]]){
		int rawValue = [sender intValue]/2 - 1;
        [model setRiseTimeProtection:[[sender selectedCell] tag] withValue:rawValue]; 
    }
}

- (void) linearGateModeAction:(id)sender
{
	[model setLinearGateMode:[sender tag] withValue:[sender indexOfSelectedItem]];	
}

- (void) auxAddressAction:(id)sender
{
	[model setAuxAddress:[sender intValue]];	
}

- (IBAction) baseAddressAction:(id) sender
{
    if ([sender intValue] != [model baseAddress]){
		[model setBaseAddress:[sender intValue]]; 
    }
} 

- (IBAction) thresholdAction:(id) sender
{
    if ([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
        [model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]]; 
    }
}

- (IBAction) readThresholds:(id) sender
{
	@try {
		[self endEditing];
		[model readThresholds];
		[model logThresholds];
    }
	@catch(NSException* localException) {
        NSLog(@"Read of %@ thresholds FAILED.\n",[model identifier]);
        NSRunAlertPanel([localException name], @"%@\nFailed Reading Thresholds", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) initBoard:(id) sender
{
	@try {
		[self endEditing];
		[model initBoard];
    }
	@catch(NSException* localException) {
        NSLog(@"Init of %@  FAILED.\n",[model identifier]);
        NSRunAlertPanel([localException name], @"%@\nFailed Init", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) basicLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORCaen419BasicLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) writeThresholds:(id) pSender
{
	@try {
		[self endEditing];
		[model writeThresholds];
    }
	@catch(NSException* localException) {
        NSLog(@"Write of %@ thresholds FAILED.\n",[model identifier]);
        NSRunAlertPanel([localException name], @"%@\nFailed Writing Thresholds", @"OK", nil, nil,
                        localException);
    }
}
- (IBAction) fire:(id) pSender
{
	@try {
		[self endEditing];
		[model fire];
    }
	@catch(NSException* localException) {
        NSLog(@"Software trigger of %@  FAILED.\n",[model identifier]);
        NSRunAlertPanel([localException name], @"%@\nFailed Software Trigger", @"OK", nil, nil,
                        localException);
    }
}
@end
