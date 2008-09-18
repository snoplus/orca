//-------------------------------------------------------------------------
//  ORXYCom200Controller.h
//
//  Created by Mark A. Howe on Wednesday 9/18/2008.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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
#import "ORXYCom200Controller.h"

@implementation ORXYCom200Controller

-(id)init
{
    self = [super initWithWindowNibName:@"XYCom200"];
    
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
    [registerAddressPopUp setAlignment:NSCenterTextAlignment];
	    
    [self populatePullDown];
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
                     selector : @selector(baseAddressChanged:)
                         name : ORVmeIOCardBaseAddressChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORXYCom200SettingsLock
                        object: nil];
   
	[notifyCenter addObserver:self
					 selector:@selector(selectedRegIndexChanged:)
						 name:ORXYCom200SelectedRegIndexChanged
					   object:model];
	
    [notifyCenter addObserver:self
					 selector:@selector(writeValueChanged:)
						 name:ORXYCom200WriteValueChanged
					   object:model]; 
}


- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];

    [self writeValueChanged:nil];
    [self selectedRegIndexChanged:nil];
}

#pragma mark •••Interface Management

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORXYCom200SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
   // BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORXYCom200SettingsLock];
    BOOL locked = [gSecurity isLocked:ORXYCom200SettingsLock];
    	
    [settingLockButton setState: locked];
    [addressText setEnabled:!locked && !runInProgress];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"XYCom200 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"XYCom200 Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
    [addressText setIntValue: [model baseAddress]];
}

- (void) selectedRegIndexChanged:(NSNotification*) aNotification
{
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerAddressPopUp setting:index];
	[self updateRegisterDescription:index];
}

- (void) writeValueChanged:(NSNotification*) aNotification
{
	[self updateStepper:writeValueStepper setting:[model writeValue]];
	[writeValueTextField setIntValue:[model writeValue]];
}

#pragma mark •••Actions

-(IBAction) baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORXYCom200SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) writeValueAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender intValue] != [model writeValue]){
		[[[model document] undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction) selectRegisterAction:(id) aSender
{
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[[model document] undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
    }
}

- (IBAction) read:(id) pSender
{
	NS_DURING
		[self endEditing];		// Save in memory user changes before executing command.
		[model read];
    NS_HANDLER
        NSRunAlertPanel([localException name], @"%@\nRead of %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[model selectedRegIndex]]);
    NS_ENDHANDLER
}

- (IBAction) write:(id) pSender
{
	NS_DURING
		[self endEditing];		// Save in memory user changes before executing command.
		[model write];
    NS_HANDLER
        NSRunAlertPanel([localException name], @"%@\nWrite to %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[model selectedRegIndex]]);
    NS_ENDHANDLER
}

#pragma mark ***Misc Helpers
- (void) populatePullDown
{
    [registerAddressPopUp removeAllItems];
    
    short	i;
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp insertItemWithTitle:[model 
                                    getRegisterName:i] 
                                            atIndex:i];
    }
    
    [self selectedRegIndexChanged:nil];
}

- (void) updateRegisterDescription:(short) aRegisterIndex
{
    [registerOffsetField setStringValue:
    [NSString stringWithFormat:@"0x%04x",
    [model getAddressOffset:aRegisterIndex]]];
	
    [regNameField setStringValue:[model getRegisterName:aRegisterIndex]];

}


@end
