//
//  ORHPLakeShore336Controller.m
//  Orca
//  Created by Mark Howe on Mon, May 6, 2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#import "ORLakeShore336Controller.h"
#import "ORLakeShore336Model.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"
#import "ORLakeShore336Input.h"
#import "ORLakeShore336Heater.h"

@implementation ORLakeShore336Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"LakeShore336" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(connectionProtocolChanged:)
                         name : ORLakeShore336ConnectionProtocolChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORLakeShore336IpAddressChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(usbConnectedChanged:)
                         name : ORLakeShore336UsbConnectedChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ipConnectedChanged:)
                         name : ORLakeShore336IpConnectedChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(canChangeConnectionProtocolChanged:)
                         name : ORLakeShore336CanChangeConnectionProtocolChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceAdded
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceRemoved
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORLakeShore336SerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORLakeShore336USBInterfaceChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORLakeShore336PollTimeChanged
						object: model];
}

- (void) awakeFromNib
{
	[self populateInterfacePopup];
	[super awakeFromNib];
}

- (void) updateWindow
{
    [ super updateWindow ];
    
    [self connectionProtocolChanged:nil];
	[self ipAddressChanged:nil];
	[self usbConnectedChanged:nil];
	[self ipConnectedChanged:nil];
	[self canChangeConnectionProtocolChanged:nil];
	[self serialNumberChanged:nil];
	[self pollTimeChanged:nil];
}

- (NSMutableArray*) inputs
{
    return [model inputs];
}

#pragma mark •••Notifications
- (void) serialNumberChanged:(NSNotification*)aNote
{
	if(![model serialNumber] || ![[model serialNumber] length] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
	else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
	if([model connectionProtocol] == kLakeShore336UseUSB){
		[[self window] setTitle:[model title]];
	}
}

- (void) pollTimeChanged:(NSNotification*)aNote
{
	[pollTimePopup selectItemWithTag: [model pollTime]];
}

- (void) interfacesChanged:(NSNotification*)aNote
{
	[self populateInterfacePopup];
}

- (void) canChangeConnectionProtocolChanged:(NSNotification*)aNote
{
	[connectionProtocolMatrix setEnabled:[model canChangeConnectionProtocol]];
	if([model canChangeConnectionProtocol])[connectionNoteTextField setStringValue:@""];
	else [connectionNoteTextField setStringValue:@"Disconnect Icon to Enable"];
	[self populateInterfacePopup];
}

- (void) ipConnectedChanged:(NSNotification*)aNote
{
	[ipConnectedTextField setStringValue: [model ipConnected]?@"Connected":@"Not Connected"];
}

- (void) usbConnectedChanged:(NSNotification*)aNote
{
	[usbConnectedTextField setStringValue: [model usbConnected]?@"Connected":@"Not Connected"];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
}

- (void) lockChanged: (NSNotification*) aNotification
{	
	[self setButtonStates];
}

- (void) connectionProtocolChanged:(NSNotification*)aNote
{
	[connectionProtocolMatrix selectCellWithTag:[model connectionProtocol]];
	[connectionProtocolTabView selectTabViewItemAtIndex:[model connectionProtocol]];
	[[self window] setTitle:[model title]];
	[self populateInterfacePopup];
}

- (void) setButtonStates
{	
    BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORLakeShore336Lock];
    	
	[connectionProtocolMatrix setEnabled:!runInProgress || !locked];
	[ipConnectButton setEnabled:!runInProgress || !locked];
	[usbConnectButton setEnabled:!runInProgress || !locked];
	[ipAddressTextField setEnabled:!locked];
	[serialNumberPopup setEnabled:!locked];
	[pollTimePopup		setEnabled:!locked];
}

#pragma mark •••Actions
- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:[[sender selectedItem] tag]];
}

- (IBAction) connectAction: (id) aSender
{
    if(![model isConnected])[model connect];
}

- (IBAction) sendCommandAction:(id)sender
{
	@try {
		[self endEditing];
		NSString* cmd = [commandField stringValue];
        [model addCmdToQueue:cmd];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
	
}
- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORLakeShore336Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) ipAddressTextFieldAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

-(IBAction) loadParamsAction:(id)sender
{
    [self endEditing];
	@try {
		//[model outputWaveformParams];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

- (IBAction) connectionProtocolAction:(id)sender
{
	[model setConnectionProtocol:[[connectionProtocolMatrix selectedCell] tag]];
	
	BOOL undoWasEnabled = [[model undoManager] isUndoRegistrationEnabled];
    if(undoWasEnabled)[[model undoManager] disableUndoRegistration];
	[model adjustConnectors:NO];
	if(undoWasEnabled)[[model undoManager] enableUndoRegistration];
	
}

- (void) populateInterfacePopup
{
	NSArray* interfaces = [model usbInterfaces];
	[serialNumberPopup removeAllItems];
	[serialNumberPopup addItemWithTitle:@"N/A"];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([serialNumber length]){
			[serialNumberPopup addItemWithTitle:serialNumber];
		}
	}
	[self validateInterfacePopup];
	if([[model serialNumber] length] > 0){
		if([serialNumberPopup indexOfItemWithTitle:[model serialNumber]]>=0){
			[serialNumberPopup selectItemWithTitle:[model serialNumber]];
		}
		else [serialNumberPopup selectItemAtIndex:0];
	}
	else [serialNumberPopup selectItemAtIndex:0];
}

- (void) validateInterfacePopup
{
	NSArray* interfaces = [[model getUSBController] interfacesForVender:[model vendorID] product:[model productID]];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([anInterface registeredObject] == nil || [serialNumber isEqualToString:[model serialNumber]]){
			[[serialNumberPopup itemWithTitle:serialNumber] setEnabled:YES];
		}
		else [[serialNumberPopup itemWithTitle:serialNumber] setEnabled:NO];
	}
}

- (IBAction) serialNumberAction:(id)sender
{
	if([serialNumberPopup indexOfSelectedItem] == 0){
		[model setSerialNumber:nil];
	}
	else {
		[model setSerialNumber:[serialNumberPopup titleOfSelectedItem]];
	}
}

-(IBAction) readIdAction:(id)sender
{
	@try {
		[model readIDString];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

-(IBAction) testAction:(id)sender
{
	NSLog(@"Testing LakeShore 336 (takes a few seconds...).\n");
	[self performSelector:@selector(systemTest) withObject:nil afterDelay:0];
}
- (void) systemTest
{
	@try {
	    [model systemTest];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}
-(IBAction) resetAction:(id)sender
{
	@try {
	    [model resetAndClear];
	    NSLog(@"LakeShore336 Reset and Clear successful.\n");
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
						[ localException reason ],	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil );				// other button
	}
}

@end
