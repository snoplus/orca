//
//  ORCaen260Controller.m
//  Orca
//
//  Created by Mark Howe on 12/7/07
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORCaen260Controller.h"
#import "ORCaen260Model.h"

@implementation ORCaen260Controller
-(id)init
{
    self = [super initWithWindowNibName:@"Caen260"];
	
    return self;
}

- (void) awakeFromNib
{
	int i;
	for(i=0;i<kNumCaen260Channels;i++){
		[[enabledMaskMatrix cellAtRow:i column:0] setTag:i];
		[[channelLabelMatrix cellAtRow:i column:0] setIntValue:i];
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
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(basicLockChanged:)
						 name : ORCaen260SettingsLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : ORCaen260ModelEnabledMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(scalerValueChanged:)
                         name : ORCaen260ModelScalerValueChanged
						object: model];


}

#pragma mark •••Interface Management
- (void) enabledMaskChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kNumCaen260Channels;i++){
		[[enabledMaskMatrix cellWithTag:i] setIntValue:[model enabledMask] & (1<<i)];
	}
}

- (void) updateWindow
{
    [super updateWindow];
	[self enabledMaskChanged:nil];
	[self scalerValueChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORCaen260SettingsLock to:secure];
    [basicLockButton setEnabled:secure];
}

- (void) basicLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORCaen260SettingsLock];
    BOOL locked = [gSecurity isLocked:ORCaen260SettingsLock];
	
    [basicLockButton setState: locked];
    [addressStepper setEnabled:!locked && !runInProgress];
    [addressTextField setEnabled:!locked && !runInProgress];
    
    [enableAllButton setEnabled:!lockedOrRunningMaintenance];
    [disableAllButton setEnabled:!lockedOrRunningMaintenance];
    [clearScalersButton setEnabled:!lockedOrRunningMaintenance];
    [readScalersButton setEnabled:!lockedOrRunningMaintenance];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"Caen260 Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Caen260 Card (Slot %d)",[model slot]]];
}

- (void) scalerValueChanged:(NSNotification*)aNotification
{
	if(aNotification==nil){
		int i;
		for(i=0;i<kNumCaen260Channels;i++){
			[[scalerValueMatrix cellAtRow:i column:0] setIntValue:[model scalerValue:i]];
		}
	}
	else {
		int index = [[[aNotification userInfo]objectForKey:@"Channel"] intValue];
		if(index>=0 && index < kNumCaen260Channels){
			[[scalerValueMatrix cellAtRow:index column:0] setIntValue:[model scalerValue:index]];
		}
	}
}

#pragma mark •••Actions
- (void) enabledMaskAction:(id)sender
{
	int i;
	unsigned short aMask = 0;
	for(i=0;i<kNumCaen260Channels;i++){
		int state = [[enabledMaskMatrix cellWithTag:i] intValue];
		if(state)aMask |= (1<<i);
	}
	[model setEnabledMask:aMask];	
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORCaen260SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction)enableAllAction:(id)sender
{
	[model setEnabledMask:0xFFFF];
}

- (IBAction)disableAllAction:(id)sender
{
	[model setEnabledMask:0];
}

- (IBAction) setInhibitAction:(id)sender
{
   NS_DURING
        [model setInhibit];
		NSLog(@"Set Inhibit on Caen260 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    NS_HANDLER
        NSLog(@"Set Inhibit of Caen260 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed Caen260 Set Inhibit", @"OK", nil, nil,
                        localException);
    NS_ENDHANDLER
}

- (IBAction) resetInhibitAction:(id)sender
{
   NS_DURING
        [model resetInhibit];
		NSLog(@"Reset Inhibit on Caen260 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    NS_HANDLER
        NSLog(@"Reset Inhibit of Caen260 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed Caen260 reset Inhibit", @"OK", nil, nil,
                        localException);
    NS_ENDHANDLER
}

- (IBAction) clearScalers:(id)sender
{
   NS_DURING
        [model clearScalers];
		NSLog(@"Clear Scalers on Caen260 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    NS_HANDLER
        NSLog(@"Clear Scalers of Caen260 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed Caen260 Clear Scalers", @"OK", nil, nil,
                        localException);
    NS_ENDHANDLER
}

- (IBAction) readScalers:(id)sender
{
   NS_DURING
        [model readScalers];
		NSLog(@"Read Scalers on Caen260 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    NS_HANDLER
        NSLog(@"Read Scalers of Caen260 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed Caen260 Read Scalers", @"OK", nil, nil,
                        localException);
    NS_ENDHANDLER
}

- (void) populatePullDown
{
    short	i;
        
    [registerAddressPopUp removeAllItems];
    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp insertItemWithTitle:[model 
                                    getRegisterName:i] 
                                            atIndex:i];
    }
    
}
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:NSMakeSize(560,630)];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:NSMakeSize(560,630)];
		[[self window] setContentView:tabView];
    }

    NSString* key = [NSString stringWithFormat: @"orca.ORCaenV260Card%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];

}

@end
