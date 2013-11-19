//-------------------------------------------------------------------------
//  ORGretinaTriggerController.m
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORGretinaTriggerController.h"

@implementation ORGretinaTriggerController

-(id)init
{
    self = [super initWithWindowNibName:@"GretinaTrigger"];
    
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    settingSize     = NSMakeSize(830,510);
    registerTabSize	= NSMakeSize(400,287);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

	// Setup register popup buttons
	[registerIndexPU removeAllItems];
	[registerIndexPU setAutoenablesItems:NO];
	int i;
	for (i=0;i<kNumberOfGretinaTriggerRegisters;i++) {
		[registerIndexPU insertItemWithTitle:[model registerNameAt:i]	atIndex:i];
	}
    
    NSString* key = [NSString stringWithFormat: @"orca.Gretina4%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];

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
                     selector : @selector(baseAddressChanged:)
                         name : ORVmeIOCardBaseAddressChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORGretinaTriggerSettingsLock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORGretinaTriggerSettingsLock
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(registerWriteValueChanged:)
                         name : ORGretinaTriggerRegisterWriteValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(registerIndexChanged:)
                         name : ORGretinaTriggerRegisterIndexChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(isMasterChanged:)
                         name : ORGretinaTriggerModelIsMasterChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(inputLinkMaskChanged:)
                         name : ORGretinaTriggerModelInputLinkMaskChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
    [self registerLockChanged:nil];
	[self registerIndexChanged:nil];
	[self registerWriteValueChanged:nil];
	[self isMasterChanged:nil];
	[self inputLinkMaskChanged:nil];
}

#pragma mark •••Interface Management

- (void) inputLinkMaskChanged:(NSNotification*)aNote
{
	//[inputLinkMask<custom> setIntValue: [model inputLinkMask]];
}

- (void) registerWriteValueChanged:(NSNotification*)aNote
{
	[registerWriteValueField setIntValue: [model registerWriteValue]];
}

- (void) registerIndexChanged:(NSNotification*)aNote
{
	[registerIndexPU selectItemAtIndex: [model registerIndex]];
	[self setRegisterDisplay:[model registerIndex]];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORGretinaTriggerSettingsLock to:secure];
    [gSecurity setLock:ORGretinaTriggerRegisterLock to:secure];
    [settingLockButton setEnabled:secure];
    [registerLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    //BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretinaTriggerSettingsLock];
    BOOL locked = [gSecurity isLocked:ORGretinaTriggerSettingsLock];
		
    [settingLockButton setState: locked];
    [addressText setEnabled:!locked && !runInProgress];
	[probeButton setEnabled:!locked && !runInProgress];
}

- (void) registerLockChanged:(NSNotification*)aNotification
{
    
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretinaTriggerRegisterLock];
    BOOL locked = [gSecurity isLocked:ORGretinaTriggerRegisterLock];
		
    [registerLockButton setState: locked];
    [registerWriteValueField setEnabled:!lockedOrRunningMaintenance];
    [registerIndexPU setEnabled:!lockedOrRunningMaintenance];
    [readRegisterButton setEnabled:!lockedOrRunningMaintenance];
    [writeRegisterButton setEnabled:!lockedOrRunningMaintenance];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"GretinaTrigger Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"GretinaTrigger Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
    [addressText setIntValue: [model baseAddress]];
}

- (void) setRegisterDisplay:(unsigned int)index
{
	if (index < kNumberOfGretinaTriggerRegisters) {
        [writeRegisterButton setEnabled:[model canWriteRegister:index]];
        [registerWriteValueField setEnabled:[model canWriteRegister:index]];
        [readRegisterButton setEnabled:[model canReadRegister:index]];
        [registerStatusField setStringValue:@""];
	}
}

- (void) isMasterChanged:(NSNotification*)aNote
{
    [masterRouterPU selectItemAtIndex:[model isMaster]];
}

#pragma mark •••Actions
- (IBAction) isMasterAction:(id)sender
{
    [model setIsMaster:[sender indexOfSelectedItem]];
}

- (IBAction) baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) readRegisterAction:(id)sender
{
	[self endEditing];
	unsigned long aValue = 0;
	unsigned int index = [model registerIndex];
	if (index < kNumberOfGretinaTriggerRegisters) {
		aValue = [model readRegister:index];
		NSLog(@"GretinaTrigger(%d,%d) %@: %u (0x%0x)\n",[model crateNumber],[model slot], [model registerNameAt:index],aValue,aValue);
	}
}

- (IBAction) writeRegisterAction:(id)sender
{
	[self endEditing];
	unsigned long aValue = [model registerWriteValue];
	unsigned int index = [model registerIndex];
	if (index < kNumberOfGretinaTriggerRegisters) {
		[model writeRegister:index withValue:aValue];
	} 
}

- (IBAction) registerWriteValueAction:(id)sender
{
	[model setRegisterWriteValue:[sender intValue]];
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretinaTriggerSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) registerLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretinaTriggerRegisterLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) registerIndexPUAction:(id)sender
{
	unsigned int index = [sender indexOfSelectedItem];
	[model setRegisterIndex:index];
	[self setRegisterDisplay:index];
}

-(IBAction)probeBoard:(id)sender
{
    [self endEditing];
    @try {
        unsigned long rev = [model readCodeRevision];
        NSLog(@"Gretina Trigger Code Revision (slot %d): 0x%x\n",[model slot],rev);
        unsigned long date = [model readCodeDate];
        NSLog(@"Gretina Trigger Code Date (slot %d): 0x%x\n",[model slot],date);
    }
	@catch(NSException* localException) {
        NSLog(@"Probe GretinaTrigger Board FAILED Probe.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
                        localException);
    }
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingSize];
		[[self window] setContentView:tabView];
    }
 	else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:registerTabSize];
		[[self window] setContentView:tabView];
    }	

    NSString* key = [NSString stringWithFormat: @"orca.ORGretinaTrigger%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

@end

