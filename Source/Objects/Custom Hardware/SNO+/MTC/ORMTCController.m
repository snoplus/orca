//
//  ORMTCController.m
//  Orca
//
//Created by Mark Howe on Fri, May 2, 2008
//Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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


#import "ORMTCController.h"
#import "ORMTCModel.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORValueBar.h"
#import "ORAxis.h"
#import "ORPlotter1D.h"
#import "ORTimeRate.h"
#import "ORMTC_Constants.h"

@implementation ORMTCController

-(id)init
{
    self = [super initWithWindowNibName:@"MTC"];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    NSString* key = [NSString stringWithFormat: @"orca.ORMTC%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
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
					 selector : @selector(settingsLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORMTCSettingsLock
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(loadFilePathChanged:)
                         name : ORMTCModelLoadFilePathChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(selectedRegisterChanged:)
                         name : ORMTCModelSelectedRegisterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(memoryOffsetChanged:)
                         name : ORMTCModelMemoryOffsetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(writeValueChanged:)
                         name : ORMTCModelWriteValueChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(repeatCountChanged:)
                         name : ORMTCModelRepeatCountChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(repeatDelayChanged:)
                         name : ORMTCModelRepeatDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useMemoryChanged:)
                         name : ORMTCModelUseMemoryChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(autoIncrementChanged:)
                         name : ORMTCModelAutoIncrementChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(basicOpsRunningChanged:)
                         name : ORMTCModelBasicOpsRunningChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];
    [self regBaseAddressChanged:nil];
    [self memBaseAddressChanged:nil];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self loadFilePathChanged:nil];
	[self selectedRegisterChanged:nil];
	[self memoryOffsetChanged:nil];
	[self writeValueChanged:nil];
	[self repeatCountChanged:nil];
	[self repeatDelayChanged:nil];
	[self useMemoryChanged:nil];
	[self autoIncrementChanged:nil];
	[self basicOpsRunningChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMTCSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

#pragma mark •••Interface Management

- (void) basicOpsRunningChanged:(NSNotification*)aNote
{
	if([model basicOpsRunning])[basicOpsRunningIndicator startAnimation:model];
	else [basicOpsRunningIndicator stopAnimation:model];
}

- (void) autoIncrementChanged:(NSNotification*)aNote
{
	[autoIncrementCB setIntValue: [model autoIncrement]];
}

- (void) useMemoryChanged:(NSNotification*)aNote
{
	[useMemoryMatrix selectCellWithTag: [model useMemory]];
}

- (void) repeatDelayChanged:(NSNotification*)aNote
{
	[repeatDelayTextField setIntValue: [model repeatDelay]];
	[repeatDelayStepper setIntValue:   [model repeatDelay]];
}

- (void) repeatCountChanged:(NSNotification*)aNote
{
	[repeatCountTextField setIntValue: [model repeatCount]];
	[repeatCountStepper setIntValue:   [model repeatCount]];
}

- (void) writeValueChanged:(NSNotification*)aNote
{
	[writeValueTextField setIntValue: [model writeValue]];
}

- (void) memoryOffsetChanged:(NSNotification*)aNote
{
	[memoryOffsetTextField setIntValue: [model memoryOffset]];
}

- (void) selectedRegisterChanged:(NSNotification*)aNote
{
	[selectedRegisterPU selectItemAtIndex: [model selectedRegister]];
}

- (void) loadFilePathChanged:(NSNotification*)aNote
{
	[loadFilePathField setStringValue: [model loadFilePath]];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
   // BOOL runInProgress = [gOrcaGlobals runInProgress];
    //BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORMTCSettingsLock];
    BOOL locked = [gSecurity isLocked:ORMTCSettingsLock];
	
    [settingLockButton setState: locked];
	
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    NSString* key = [NSString stringWithFormat: @"orca.ORMTC%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"MTC Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"MTC Card (Slot %d)",[model slot]]];
}

- (void) regBaseAddressChanged:(NSNotification*)aNotification
{
	[regBaseAddressText setIntValue: [model baseAddress]];
}

- (void) memBaseAddressChanged:(NSNotification*)aNotification
{
	[memBaseAddressText setIntValue: [model memBaseAddress]];
}

#pragma mark •••Actions
- (void) autoIncrementAction:(id)sender
{
	[model setAutoIncrement:[sender intValue]];	
}

//basic ops
- (void) useMemoryAction:(id)sender
{
	[model setUseMemory:[[sender selectedCell] tag]];	
}

- (void) repeatDelayTextFieldAction:(id)sender
{
	[model setRepeatDelay:[sender intValue]];	
}

- (void) repeatCountTextFieldAction:(id)sender
{
	[model setRepeatCount:[sender intValue]];	
}

- (void) writeValueTextFieldAction:(id)sender
{
	[model setWriteValue:[sender intValue]];	
}

- (void) memoryOffsetTextFieldAction:(id)sender
{
	[model setMemoryOffset:[sender intValue]];	
}

- (void) selectedRegisterAction:(id)sender
{
	[model setSelectedRegister:[sender indexOfSelectedItem]];	
}

//------
- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORMTCSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (void) populatePullDown
{
    short	i;
        
    [selectedRegisterPU removeAllItems];
    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [selectedRegisterPU insertItemWithTitle:[model getRegisterName:i] atIndex:i];
    }
     
    [self selectedRegisterChanged:nil];

}

- (IBAction) readAction:(id) sender
{
	[model readBasicOps];
}

- (IBAction) writeAction:(id) sender
{
	[model writeBasicOps];
}

- (IBAction) stopAction:(id) sender
{
	[model stopBasicOps];
}

- (IBAction) statusReportAction:(id) sender
{
	[model reportStatus];
}

//Basic Ops buttons.
- (void) buttonPushed:(id) sender {
	NSLog(@"Input received from %@\n", [sender title] );	//This is the only real method.  The other button push methods just call this one.
}
- (IBAction) basicRead:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) basicWrite:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) basicStatus:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) basicStop:(id) sender {
	[self buttonPushed:sender];
}

//MTC Init Ops buttons.
- (IBAction) standardInitMTC:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) standardInitMTCnoXilinx:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) standardInitMTCno10MHz:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) standardInitMTCnoXilinxno10MHz:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) standardMakeOnlineCrateMasks:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) standardLoad10MHzCounter:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) standardLoadOnlineGTMasks:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) standardLoadMTCADacs:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) standardSetCoarseDelay:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) standardFirePedestals:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) standardFindTriggerZeroes:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) standardStopFindTriggerZeroes:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) standardPeriodicReadout:(id) sender {
	[self buttonPushed:sender];
}

//Settings buttons.
- (IBAction) settingsLoadDBFile:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) settingsDefValFile:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) settingsXilinxFile:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) settingsDefaultGetSet:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) settingsMTCRecordGet:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) settingsMTCRecordSaveAs:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) settingsMTCDelete:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) settingsLoadDefVals:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) settingsPrint:(id) sender {
	[self buttonPushed:sender];
}
- (IBAction) settingsComments:(id) sender {
	[self buttonPushed:sender];
}

- (IBAction) settingsDefaultSaveSet:(id) sender {
	[self buttonPushed:sender];
}




@end
