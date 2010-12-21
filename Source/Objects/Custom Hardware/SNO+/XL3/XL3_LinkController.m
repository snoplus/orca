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

static NSArray* xl3RWModes;
static NSDictionary* xl3RWSelects;
static NSDictionary* xl3RWAddresses;
static NSDictionary* xl3Ops;

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
	basicSize	= NSMakeSize(452,290);
	compositeSize	= NSMakeSize(452,510);
	blankView = [[NSView alloc] init];
	[self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

	[super awakeFromNib];

	NSString* key = [NSString stringWithFormat: @"orca.ORXL3%d.selectedtab",[model crateNumber]]; //uniqueIdNumber?
	int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
	if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;

	[tabView selectTabViewItemAtIndex: index];
	[self populateOps];
	[self populatePullDown];
	[self updateWindow];
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
			 selector : @selector(opsRunningChanged:)
			     name : ORXL3ModelXl3OpsRunningChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(compositeSlotMaskChanged:)
			     name : ORXL3ModelSlotMaskChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(compositeXl3ModeChanged:)
			     name : ORXL3ModelXl3ModeChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(compositeXl3ModeRunningChanged:)
			     name : ORXL3ModelXl3ModeRunningChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(compositeXl3RWAddressChanged:)
			     name : ORXL3ModelXl3RWAddressValueChanged
			   object : model];
	
	[notifyCenter addObserver : self
			 selector : @selector(compositeXL3RWDataChanged:)
			     name : ORXL3ModelXl3RWDataValueChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(compositeXl3PedestalMaskChanged:)
			     name : ORXL3ModelXl3PedestalMaskChanged
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
	[self opsRunningChanged:nil];
	//basic ops
	[self selectedRegisterChanged:nil];
	[self repeatCountChanged:nil];
	[self repeatDelayChanged:nil];
	[self autoIncrementChanged:nil];
	[self basicOpsRunningChanged:nil];
	[self writeValueChanged:nil];
	//composite
	[self compositeSlotMaskChanged:nil];
	[self compositeXl3ModeChanged:nil];
	[self compositeXl3ModeRunningChanged:nil];
	[self compositeXl3PedestalMaskChanged:nil];
	[self compositeXl3RWAddressChanged:nil];
	[self compositeXL3RWDataChanged:nil];
	//ip connection
	[self errorTimeOutChanged:nil];

/*
	[self ipNumberChanged:nil];
	[self portNumberChanged:nil];
	[self initAfterConnectChanged:nil];
*/
}

- (void) checkGlobalSecurity
{
	BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
	[gSecurity setLock:[model xl3LockName] to:secure];
	[lockButton setEnabled:secure];
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
	if([tabView indexOfTabViewItem:item] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:basicSize];
		[[self window] setContentView:tabView];
	}
	else if([tabView indexOfTabViewItem:item] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:compositeSize];
		[[self window] setContentView:tabView];
	}
	else if([tabView indexOfTabViewItem:item] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:basicSize];
		[[self window] setContentView:tabView];
	}
	else if([tabView indexOfTabViewItem:item] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:basicSize];
		[[self window] setContentView:tabView];
	}
		
	NSString* key = [NSString stringWithFormat: @"orca.ORXL3%d.selectedtab",[model crateNumber]];
	int index = [tabView indexOfTabViewItem:item];
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
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

- (void) opsRunningChanged:(NSNotification*)aNote
{
	for (id key in xl3Ops) {
		if ([model xl3OpsRunningForKey:key]) {
			[[[xl3Ops objectForKey:key] objectForKey:@"spinner"] startAnimation:model];
		}
		else {
			[[[xl3Ops objectForKey:key] objectForKey:@"spinner"] stopAnimation:model];			
		}
	}
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


#pragma mark •composite
- (void) compositeXl3ModeChanged:(NSNotification*)aNote
{
	[compositeXl3ModePU selectItemWithTag:[model xl3Mode]]; 
}

- (void) compositeXl3ModeRunningChanged:(NSNotification*)aNote
{
	if ([model xl3ModeRunning]) [compositeXl3ModeRunningIndicator startAnimation:model];
	else [compositeXl3ModeRunningIndicator stopAnimation:model];
}

- (void) compositeSlotMaskChanged:(NSNotification*)aNote
{
	unsigned long mask = [model slotMask];
	int i;
	for(i=0; i<16; i++){
		[[compositeSlotMaskMatrix cellWithTag:i] setIntValue:(mask & 1UL << i)];
	}
	[compositeSlotMaskField setIntValue:mask];
}

- (void) compositeXl3RWAddressChanged:(NSNotification*)aNote
{
	[compositeXl3RWAddressValueField setIntValue:[model xl3RWAddressValue]];
	[compositeXl3RWModePU selectItemAtIndex:([model xl3RWAddressValue] >> 28)];

	[compositeXl3RWSelectPU selectItemWithTitle:
	 [[xl3RWSelects allKeysForObject:[NSNumber numberWithInt:[model xl3RWAddressValue] >> 20 & 0x0FF]] lastObject]];
	
	[compositeXl3RWRegisterPU selectItemWithTitle:
	 [[xl3RWAddresses allKeysForObject:[NSNumber numberWithInt:[model xl3RWAddressValue] & 0xFFF]] lastObject]];
}

- (void) compositeXL3RWDataChanged:(NSNotification*)aNote
{
	[compositeXl3RWDataValueField setIntValue:[model xl3RWDataValue]];
}

- (void) compositeXl3PedestalMaskChanged:(NSNotification*)aNote
{
	[compositeSetPedestalField setIntValue:[model xl3PedestalMask]];
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
- (void) populateOps
{
	
	xl3Ops = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeDeselectButton, @"button",
									deselectCompositeRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(deselectComposite)), @"selector",
			 nil], @"compositeDeselect",
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeQuitButton, @"button",
									compositeQuitRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(compositeQuit)), @"selector",
			 nil], @"compositeQuit",
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeSetPedestalButton, @"button",
									compositeSetPedestalRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(compositeSetPedestal)), @"selector",
			 nil], @"compositeSetPedestal",
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeBoardIDButton, @"button",
									compositeBoardIDRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(getBoardIDs)), @"selector",
			 nil], @"compositeBoardID",
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeXl3RWButton, @"button",
									compositeXl3RWRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(compositeXl3RW)), @"selector",
			 nil], @"compositeXl3RW",
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeResetCrateButton, @"button",
									compositeResetCrateRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(compositeResetCrate)), @"selector",
			 nil], @"compositeResetCrate",
		  nil];
}

- (void) populatePullDown
{
	xl3RWModes = [[NSArray alloc] initWithObjects:@"0: REG_WRITE",@"1: REG_READ",
		       @"2: MEM_WRITE",@"3: MEM_READ", nil];

	xl3RWSelects = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSNumber numberWithInt:0x00], @"FEC 0", 
			[NSNumber numberWithInt:0x01], @"FEC 1",
			[NSNumber numberWithInt:0x02], @"FEC 2",
			[NSNumber numberWithInt:0x03], @"FEC 3",
			[NSNumber numberWithInt:0x04], @"FEC 4",
			[NSNumber numberWithInt:0x05], @"FEC 5",
			[NSNumber numberWithInt:0x06], @"FEC 6",
			[NSNumber numberWithInt:0x07], @"FEC 7",
			[NSNumber numberWithInt:0x08], @"FEC 8",
			[NSNumber numberWithInt:0x09], @"FEC 9",
			[NSNumber numberWithInt:0x0A], @"FEC 10",
			[NSNumber numberWithInt:0x0B], @"FEC 11",
			[NSNumber numberWithInt:0x0C], @"FEC 12",
			[NSNumber numberWithInt:0x0D], @"FEC 13",
			[NSNumber numberWithInt:0x0E], @"FEC 14",
			[NSNumber numberWithInt:0x0F], @"FEC 15",
			[NSNumber numberWithInt:0x10], @"CTC",
			[NSNumber numberWithInt:0x20], @"XL3",
			nil];

	xl3RWAddresses = [[NSDictionary alloc] initWithObjectsAndKeys:
			  [NSNumber numberWithInt:0x00], @"xl3 select",
			  [NSNumber numberWithInt:0x01], @"xl3 data avail",
			  [NSNumber numberWithInt:0x02], @"xl3 ctrl&stat",
			  [NSNumber numberWithInt:0x03], @"xl3 slot mask",
			  [NSNumber numberWithInt:0x04], @"xl3 dac clock",
			  [NSNumber numberWithInt:0x05], @"xl3 hv relay",
			  [NSNumber numberWithInt:0x06], @"xl3 xilinx csr",
			  [NSNumber numberWithInt:0x07], @"xl3 test",
			  [NSNumber numberWithInt:0x08], @"xl3 hv csr",
			  [NSNumber numberWithInt:0x09], @"xl3 hv setpoints",
			  [NSNumber numberWithInt:0x0A], @"xl3 hv vlt read",
			  [NSNumber numberWithInt:0x0B], @"xl3 hv crnt read",
			  [NSNumber numberWithInt:0x0C], @"xl3 vm",
			  [NSNumber numberWithInt:0x0E], @"xl3 vr",
			  [NSNumber numberWithInt:0x20], @"fec ctrl&stat",
			  [NSNumber numberWithInt:0x21], @"fec adc value",
			  [NSNumber numberWithInt:0x22], @"fec vlt mon",
			  [NSNumber numberWithInt:0x23], @"fec ped enable",
			  [NSNumber numberWithInt:0x24], @"fec dac prg",
			  [NSNumber numberWithInt:0x25], @"fec caldac prg",
			  [NSNumber numberWithInt:0x26], @"fec hvc csr",
			  [NSNumber numberWithInt:0x27], @"fec cmos spy out",
			  [NSNumber numberWithInt:0x28], @"fec cmos full",
			  [NSNumber numberWithInt:0x29], @"fec cmos select",
			  [NSNumber numberWithInt:0x2A], @"fec cmos 1_16",
			  [NSNumber numberWithInt:0x2B], @"fec cmos 17_32",
			  [NSNumber numberWithInt:0x2C], @"fec cmos lgisel",
			  [NSNumber numberWithInt:0x2D], @"fec board id",
			  [NSNumber numberWithInt:0x80], @"fec seq out csr",
			  [NSNumber numberWithInt:0x84], @"fec seq in csr",
			  [NSNumber numberWithInt:0x88], @"fec cmos dt avl",
			  [NSNumber numberWithInt:0x8C], @"fec cmos chp sel",
			  [NSNumber numberWithInt:0x90], @"fec cmos chp dis",
			  [NSNumber numberWithInt:0x90], @"fec cmos dat out",
			  [NSNumber numberWithInt:0x9C], @"fec fifo read",
			  [NSNumber numberWithInt:0x9D], @"fec fifo write",
			  [NSNumber numberWithInt:0x9E], @"fec fifo diff",
			  [NSNumber numberWithInt:0x101], @"fec cmos msd cnt",
			  [NSNumber numberWithInt:0x102], @"fec cmos busy rg",
			  [NSNumber numberWithInt:0x103], @"fec cmos tot cnt",
			  [NSNumber numberWithInt:0x104], @"fec cmos test id",
			  [NSNumber numberWithInt:0x105], @"fec cmos shft rg",
			  [NSNumber numberWithInt:0x106], @"fec cmos arry pt",
			  [NSNumber numberWithInt:0x107], @"fec cmos cnt inf",
			  nil];

	short	i;
	[selectedRegisterPU removeAllItems];
	for (i = 0; i < [model getNumberRegisters]; i++) {
		[selectedRegisterPU insertItemWithTitle:[model getRegisterName:i] atIndex:i];
	}
	[self selectedRegisterChanged:nil];

	[compositeXl3RWModePU removeAllItems];
	[compositeXl3RWModePU addItemsWithTitles:xl3RWModes];
	
	[compositeXl3RWSelectPU removeAllItems];
	[compositeXl3RWSelectPU addItemsWithTitles:[xl3RWSelects keysSortedByValueUsingSelector:@selector(compare:)]];
	
	[compositeXl3RWRegisterPU removeAllItems];
	[compositeXl3RWRegisterPU addItemsWithTitles:[xl3RWAddresses keysSortedByValueUsingSelector:@selector(compare:)]];
	//for (id key in xl3RWAddresses) [compositeXl3RWRegisterPU addItemWithTitle:key]; // doesn't guarantee the order
}


#pragma mark •••Actions
- (IBAction) lockAction:(id)sender
{
	[gSecurity tryToSetLock:[model xl3LockName] to:[sender intValue] forWindow:[self window]];
}


- (IBAction) opsAction:(id)sender
{
	NSString* theKey = @"";
	for (id key in xl3Ops) {
		if ((id) [[xl3Ops objectForKey:key] objectForKey:@"button"] == sender) {
			theKey = [NSString stringWithString: key];
			//NSLog(@"%@ found in keys\n", theKey);
			break;
		}
	}
	
	[model performSelector:NSSelectorFromString([[xl3Ops objectForKey:theKey] objectForKey:@"selector"])];
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


//composite
- (IBAction) compositeSlotMaskAction:(id) sender 
{
	unsigned long mask = 0;
	int i;
	for(i=0;i<16;i++){
		if([[sender cellWithTag:i] intValue]){	
			mask |= (1L << i);
		}
	}
	[model setSlotMask:mask];	
}

- (IBAction) compositeSlotMaskFieldAction:(id) sender
{
	unsigned long mask = [sender intValue];
	if (mask > 0xFFFFUL) mask = 0xFFFF;
	[model setSlotMask:mask];
}

- (IBAction) compositeSlotMaskSelectAction:(id) sender
{
	[model setSlotMask:0xffffUL];
}

- (IBAction) compositeSlotMaskDeselectAction:(id) sender
{
	[model setSlotMask:0UL];
}

- (IBAction) compositeSlotMaskPresentAction:(id) sender
{
	NSArray* fecs = [[model guardian] collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];
	unsigned int msk = 0UL;
	for (id key in fecs) {
		msk |= 1 << [key stationNumber];
	}
	[model setSlotMask:msk];
}

- (IBAction) compositeDeselectAction:(id) sender
{
	[model deselectComposite];
}

- (IBAction) compositeXl3ModeAction:(id) sender
{
	[model setXl3Mode:[[sender selectedItem] tag]];
}

- (IBAction) compositeXl3ModeSetAction:(id) sender
{
	[model writeXl3Mode];
}

- (IBAction) compositeXl3RWAddressValueAction:(id)sender
{
	[model setXl3RWAddressValue:[sender intValue]];
}	

- (IBAction) compositeXl3RWModeAction:(id)sender
{
	unsigned long addressValue = [model xl3RWAddressValue];
	addressValue = addressValue & 0x0FFFFFFF | [sender indexOfSelectedItem] << 28;
	[model setXl3RWAddressValue:addressValue];
}

- (IBAction) compositeXl3RWSelectAction:(id)sender
{
	unsigned long addressValue = [model xl3RWAddressValue];
	addressValue = addressValue & 0xF00FFFFF | [[xl3RWSelects objectForKey:[[sender selectedItem] title]] intValue] << 20;
	[model setXl3RWAddressValue:addressValue];
}

- (IBAction) compositeXl3RWRegisterAction:(id)sender
{
	unsigned long addressValue = [model xl3RWAddressValue];
	addressValue = addressValue & 0xFFF00000 | [[xl3RWAddresses objectForKey:[[sender selectedItem] title]] intValue];
	[model setXl3RWAddressValue:addressValue];
}

- (IBAction) compositeXl3RWDataValueAction:(id)sender;
{
	[model setXl3RWDataValue:[sender intValue]];
}

- (IBAction) compositeXl3RWSend:(id)sender
{
	[model compositeXl3RW];
}

- (IBAction) compositeSetPedestalValue:(id)sender
{
	[model setXl3PedestalMask:[sender intValue]];
}

//connection
- (void) toggleConnectAction:(id)sender
{
	[[model xl3Link] toggleConnect];
}

- (IBAction) errorTimeOutAction:(id)sender
{
	[[model xl3Link] setErrorTimeOut:[sender indexOfSelectedItem]];
}

@end
