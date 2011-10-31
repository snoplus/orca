//-------------------------------------------------------------------------
//  ORXYCom564Controller.h
//
//  Created by Michael G. Marino on 10/21/1011
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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


#define kXVME564ChannelKey	@"Chan"

#pragma mark ***Imported Files
#import "ORXYCom564Controller.h"

@implementation ORXYCom564Controller

-(id)init
{
    self = [super initWithWindowNibName:@"XYCom564"];
	
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
	
    [self populatePopups];
	
	[self modelChanged:nil];
	
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
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORXYCom564Lock
                        object: nil];
    
    [notifyCenter addObserver:self
					 selector:@selector(readoutModeChanged:)
						 name:ORXYCom564ReadoutModeChanged
					   object:model]; 
    
    [notifyCenter addObserver:self
					 selector:@selector(operationModeChanged:)
						 name:ORXYCom564OperationModeChanged
					   object:model]; 	
    
    [notifyCenter addObserver:self
					 selector:@selector(autoscanModeChanged:)
						 name:ORXYCom564AutoscanModeChanged
					   object:model]; 
    
    [notifyCenter addObserver:self
					 selector:@selector(channelGainsChanged:)
						 name:ORXYCom564ChannelGainChanged
					   object:model];     
    
    [notifyCenter addObserver:self
					 selector:@selector(pollingStateChanged:)
						 name:ORXYCom564PollingStateChanged
					   object:model];       
    
    [notifyCenter addObserver:self
					 selector:@selector(displayRawChanged:)
						 name:ORXYCom564ADCValuesChanged
					   object:model];     
    
    [notifyCenter addObserver:self
					 selector:@selector(pollingActivityChanged:)
						 name:ORXYCom564PollingActivityChanged
					   object:model];         
    
    [notifyCenter addObserver:self
					 selector:@selector(shipRecordsChanged:)
						 name:ORXYCom564ShipRecordsChanged
					   object:model];         
}


- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self lockChanged:nil];
    [self readoutModeChanged:nil];
    [self operationModeChanged:nil];    
    [self autoscanModeChanged:nil];
    [self channelGainsChanged:nil]; 
    [self displayRawChanged:nil];
    [self pollingActivityChanged:nil];    
}
#pragma mark •••Interface Management

- (void) modelChanged:(NSNotification*)aNotification
{    

}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORXYCom564Lock to:secure];
    [settingLockButton setEnabled:secure];
    [basicOpsLockButton setEnabled:secure];
}

- (void) pollingStateChanged:(NSNotification*)aNotification
{
	[pollingState selectItemAtIndex:[pollingState indexOfItemWithTag:[model pollingState]]];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
	// BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORXYCom564Lock];
    BOOL locked = [gSecurity isLocked:ORXYCom564Lock];
	
    [settingLockButton setState: locked];
    [basicOpsLockButton setState: locked];
    [addressText setEnabled:!locked && !runInProgress];
	[initBoardButton setEnabled:!locked && !runInProgress];
}

- (void) setModel:(id)aModel
{	
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"XYCom564 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"XYCom564 Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
    [addressText setIntValue:[model baseAddress]];
}

- (void) readoutModeChanged:(NSNotification*) aNotification
{
	short index = [model readoutMode];
	[self updatePopUpButton:addressModifierPopUp setting:index];
}

- (void) operationModeChanged:(NSNotification*) aNotification
{
	short index = [model operationMode];
	[self updatePopUpButton:operationModePopUp setting:index];
    if ([model operationMode] != kAutoscanning) {
        [autoscanModePopUp setEnabled:NO];
    } else {
        [autoscanModePopUp setEnabled:YES];
        [self autoscanModeChanged:nil];
    }    
}

- (void) autoscanModeChanged:(NSNotification*) aNotification
{
	short index = [model autoscanMode];
	[self updatePopUpButton:autoscanModePopUp setting:index];
}

- (void) channelGainsChanged:(NSNotification *)aNotification
{

    NSInteger rows = [channelGainSettings numberOfRows];
	short index;
    for (index=0; index < [model getNumberOfChannels]; index++) {
        NSInteger currentColumn = index / rows;
        NSInteger currentRow = index % rows;    
        [self updatePopUpButton:[channelGainSettings cellAtRow:currentRow column:currentColumn] setting:[model getGain:index]];
    }
	[self updatePopUpButton:autoscanModePopUp setting:index];
}

- (void) pollingActivityChanged:(NSNotification*)aNote
{
    if ([model isPolling]) {
        [pollButton setTitle:@"Stop Polling"];
    } else {
        [pollButton setTitle:@"Start Polling"];        
    }
}

- (void) shipRecordsChanged:(NSNotification*)aNote
{
    [shipRecordsButton setState:[model shipRecords]];
}

- (void) displayRawChanged:(NSNotification*)aNote
{
    [adcCountsAndChannels reloadData];
}

#pragma mark •••Actions

- (IBAction) initBoard:(id)sender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		[model initBoard];
    }
	@catch(NSException* localException) {
        NSRunAlertPanel([localException name], @"Init failed: %@", @"OK", nil, nil,
                        localException);
    }	
}

- (IBAction) resetBoard:(id)sender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		[model resetBoard];
    }
	@catch(NSException* localException) {
        NSRunAlertPanel([localException name], @"Reset failed: %@", @"OK", nil, nil,
                        localException);
    }	
}

- (IBAction) report:(id)sender
{
	@try {
		[model report];
    }
	@catch(NSException* localException) {
        NSRunAlertPanel([localException name], @"%Report failed: %@", @"OK", nil, nil,
                        localException);
    }
}

-(IBAction) baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORXYCom564Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) writeValueAction:(id) aSender
{
}

- (IBAction) selectReadoutModeAction:(id) aSender
{
    if ([aSender indexOfSelectedItem] != [model readoutMode]){
	    [[[model document] undoManager] setActionName:@"Readout Mode"]; // Set undo name
	    [model setReadoutMode:[aSender indexOfSelectedItem]]; // set new value
    }
}

- (IBAction) selectRegisterAction:(id) aSender
{
    [self updateRegisterDescription:[aSender indexOfSelectedItem]];
}

- (IBAction) selectOperationModeAction:(id) aSender
{
    if ([aSender indexOfSelectedItem] != [model operationMode]){
	    [[[model document] undoManager] setActionName:@"Operation Mode"]; // Set undo name
	    [model setOperationMode:[aSender indexOfSelectedItem]]; // set new value
    }    
}

- (IBAction) selectAutoscanModeAction:(id) aSender
{
    if ([aSender indexOfSelectedItem] != [model autoscanMode]){
	    [[[model document] undoManager] setActionName:@"Autoscan Mode"]; // Set undo name
	    [model setAutoscanMode:[aSender indexOfSelectedItem]]; // set new value
    }    
}

- (IBAction) setOneChannelGain:(id)sender
{
    id cell = [sender selectedCell];
    NSInteger rows = [sender numberOfRows];
    short channel = rows*[sender selectedColumn] + [sender selectedRow];
    if ([cell indexOfSelectedItem] != [model getGain:channel]) {
        [[[model document] undoManager] setActionName:@"Channel Gain"]; // Set undo name
        [model setGain:[cell indexOfSelectedItem] channel:channel];
    }
}

- (IBAction) setAllChannelGains:(id)sender
{
    [model setGain:[setAllChannelGains indexOfSelectedItem]];
}

- (IBAction) setPollingAction:(id)sender
{
    [model setPollingState:(NSTimeInterval)[[sender selectedItem] tag]];
}

- (IBAction) read:(id) pSender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		uint8_t val = 0;
        [model read:&val atRegisterIndex:[registerAddressPopUp indexOfSelectedItem]];
        [readbackField setStringValue:[NSString stringWithFormat:@"0x%02x",val]];
        
    }
	@catch(NSException* localException) {
        NSRunAlertPanel([localException name], @"%@\nRead of %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[registerAddressPopUp indexOfSelectedItem]]);
    }
}

- (IBAction) write:(id) pSender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		uint8_t val = [writeValueTextField intValue];
        [model write:val atRegisterIndex:[registerAddressPopUp indexOfSelectedItem]];    
    }
	@catch(NSException* localException) {
        NSRunAlertPanel([localException name], @"%@\nWrite to %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[registerAddressPopUp indexOfSelectedItem]]);
    }
}

- (IBAction) startPollingActivityAction:(id)sender
{
    if ([model isPolling]) {
        [model stopPollingActivity];
    } else {
        [model startPollingActivity];        
    }
}

- (IBAction) setShipRecordsAction:(id)sender
{
    [model setShipRecords:[sender state]];
}

#pragma mark ***Misc Helpers
- (void) populatePopups
{
    [registerAddressPopUp removeAllItems];
    [operationModePopUp removeAllItems]; 
    [autoscanModePopUp removeAllItems];
    [setAllChannelGains removeAllItems];    
    short	i;
    short	j;    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp addItemWithTitle:[model getRegisterName:i]];
    }
    for (i = 0; i < [model getNumberOperationModes]; i++) {
        [operationModePopUp addItemWithTitle:[model getOperationModeName:i]];
    }    
    for (i = 0; i < [model getNumberAutoscanModes]; i++) {
        [autoscanModePopUp addItemWithTitle:[model getAutoscanModeName:i]];
    }        
    for (j=0;j< [model getNumberGainModes];j++) {
        [setAllChannelGains addItemWithTitle:[model getChannelGainName:j]];
    }    
    NSInteger columns;
    NSInteger rows;
    [channelLabels getNumberOfRows:&rows columns:&columns];
    [channelGainSettings setTabKeyTraversesCells:YES];
    assert(columns*rows >= [model getNumberOfChannels]);

    for (i=0;i < [model getNumberOfChannels];i++) {
        NSInteger currentColumn = i / rows;
        NSInteger currentRow = i % rows;
        id cell = [channelLabels cellAtRow:currentRow column:currentColumn];
        [cell setTag:i];
        [[channelLabels cellAtRow:currentRow column:currentColumn] setStringValue:[NSString stringWithFormat:@"%d:",i]];
        NSPopUpButtonCell* popCell = [channelGainSettings cellAtRow:currentRow column:currentColumn];
        [popCell setTag:i];
        [popCell removeAllItems];
        for (j=0;j< [model getNumberGainModes];j++) {
            [popCell addItemWithTitle:[model getChannelGainName:j]];
        }
    }
}

- (void) updateRegisterDescription:(short) aRegisterIndex
{
    [registerOffsetField setStringValue:[NSString stringWithFormat:@"0x%04x",[model getAddressOffset:aRegisterIndex]]];
	
    [regNameField setStringValue:[model getRegisterName:aRegisterIndex]];
	
    [readbackField setStringValue:@"N/A"];
}

#pragma mark •••Data Source
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    return YES;
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    rowIndex += [aTableView tag];
    int chan = [[aTableView tableColumns] indexOfObject:aTableColumn]/2;
    chan = rowIndex + chan*[self numberOfRowsInTableView:aTableView];    
	if([[aTableColumn identifier] hasPrefix:kXVME564ChannelKey]){
        return [NSString stringWithFormat:@"%d",chan];
	} else {
        return [NSString stringWithFormat:@"%d",[model getAdcValueAtChannel:chan]];        
    }
}


// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [model getNumberOfChannels]*2/[aTableView numberOfColumns];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
}

@end