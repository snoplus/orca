//
//  ORHPLabJackController.m
//  Orca
//
//  Created by Mark Howe on Wed Feb 18, 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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

#import "ORLabJackController.h"
#import "ORLabJackModel.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"

@implementation ORLabJackController
- (id) init
{
    self = [ super initWithWindowNibName: @"LabJack" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
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
                         name : ORLabJackModelSerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORLabJackModelUSBInterfaceChanged
						object: nil];
		
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORLabJackModelLock
						object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(channelNameChanged:)
                         name : ORLabJackChannelNameChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(adcChanged:)
                         name : ORLabJackAdcChanged
						object: model];		
	
	[notifyCenter addObserver : self
                     selector : @selector(doNameChanged:)
                         name : ORLabJackDoNameChanged
						object: model];
		
	[notifyCenter addObserver : self
                     selector : @selector(ioNameChanged:)
                         name : ORLabJackIoNameChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(doDirectionChanged:)
                         name : ORLabJackDoDirectionChangedNotification
                       object : model];

	[notifyCenter addObserver : self
                     selector : @selector(ioDirectionChanged:)
                         name : ORLabJackIoDirectionChangedNotification
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(doValueOutChanged:)
                         name : ORLabJackDoValueOutChangedNotification
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(ioValueOutChanged:)
                         name : ORLabJackIoValueOutChangedNotification
                       object : model];

	[notifyCenter addObserver : self
                     selector : @selector(doValueInChanged:)
                         name : ORLabJackDoValueInChangedNotification
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(ioValueInChanged:)
                         name : ORLabJackIoValueInChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(counterChanged:)
                         name : ORLabJackModelCounterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(digitalOutputEnabledChanged:)
                         name : ORLabJackModelDigitalOutputEnabledChanged
						object: model];

}

- (void) awakeFromNib
{
	[self populateInterfacePopup:[model getUSBController]];
	short i;
	for(i=0;i<8;i++){	
		[[nameMatrix cellAtRow:i column:0] setEditable:YES];
		[[nameMatrix cellAtRow:i column:0] setTag:i];
		[[adcMatrix cellAtRow:i column:0] setTag:i];
	}
	
	for(i=0;i<16;i++){	
		[[doNameMatrix cellAtRow:i column:0] setTag:i];
		[[doDirectionMatrix cellAtRow:i column:0] setTag:i];
		[[doValueOutMatrix cellAtRow:i column:0] setTag:i];
		[[doValueInMatrix cellAtRow:i column:0] setTag:i];
	}
	for(i=0;i<4;i++){	
		[[ioNameMatrix cellAtRow:i column:0] setTag:i];
		[[ioDirectionMatrix cellAtRow:i column:0] setTag:i];
		[[ioValueOutMatrix cellAtRow:i column:0] setTag:i];
		[[ioValueInMatrix cellAtRow:i column:0] setTag:i];
	}
	[super awakeFromNib];
}

- (void) updateWindow
{
    [ super updateWindow ];
	[self serialNumberChanged:nil];
	[self channelNameChanged:nil];
	[self ioNameChanged:nil];
	[self doNameChanged:nil];
	[self doDirectionChanged:nil];
	[self ioDirectionChanged:nil];
	[self doValueOutChanged:nil];
	[self ioValueOutChanged:nil];
	[self doValueInChanged:nil];
	[self ioValueInChanged:nil];
	[self adcChanged:nil];
    [self lockChanged:nil];
	[self counterChanged:nil];
	[self digitalOutputEnabledChanged:nil];
}

- (void) digitalOutputEnabledChanged:(NSNotification*)aNote
{
	[digitalOutputEnabledButton setState: [model digitalOutputEnabled]];
}

- (void) counterChanged:(NSNotification*)aNote
{
	[counterField setIntValue: [model counter]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORLabJackModelLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) setDoEnabledState
{
	unsigned short aMask = [model doDirection];
	int i;
	for(i=0;i<16;i++){
		[[doValueOutMatrix cellWithTag:i] setTransparent: (aMask & (1L<<i))!=0];
	}
	[doValueOutMatrix setNeedsDisplay:YES];
}

- (void) setIoEnabledState
{
	unsigned short aMask = [model ioDirection];
	int i;
	for(i=0;i<4;i++){
		[[ioValueOutMatrix cellWithTag:i] setTransparent: (aMask & (1L<<i))!=0];
	}
	[ioValueOutMatrix setNeedsDisplay:YES];
}

- (void) channelNameChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<8;i++){
			[[nameMatrix cellWithTag:i] setStringValue:[model channelName:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<8){
			[[nameMatrix cellWithTag:chan] setStringValue:[model channelName:chan]];
		}
	}
}

- (void) doDirectionChanged:(NSNotification*)aNotification
{
	int value = [model doDirection];
	short i;
	for(i=0;i<16;i++){
		[[doDirectionMatrix cellWithTag:i] setState:(value & 1L<<i)>0];
	}
	[self setDoEnabledState];
	[self doValueInChanged:nil];
}

- (void) ioDirectionChanged:(NSNotification*)aNotification
{
	int value = [model ioDirection];
	short i;
	for(i=0;i<4;i++){
		[[ioDirectionMatrix cellWithTag:i] setState:(value & 1L<<i)>0];
	}
	[self setIoEnabledState];
	[self ioValueInChanged:nil];
}

- (void) doValueOutChanged:(NSNotification*)aNotification
{
	int value = [model doValueOut];
	short i;
	for(i=0;i<16;i++){
		[[doValueOutMatrix cellWithTag:i] setState:(value & 1L<<i)>0];
	}
}

- (void) ioValueOutChanged:(NSNotification*)aNotification
{
	int value = [model ioValueOut];
	short i;
	for(i=0;i<4;i++){
		[[ioValueOutMatrix cellWithTag:i] setState:(value & 1L<<i)>0];
	}
}

- (void) doValueInChanged:(NSNotification*)aNotification
{
	short i;
	for(i=0;i<16;i++){
		[[doValueInMatrix cellWithTag:i] setTextColor:[model doInColor:i]];
		[[doValueInMatrix cellWithTag:i] setStringValue:[model doInString:i]];
	}
}

- (void) ioValueInChanged:(NSNotification*)aNotification
{
	short i;
	for(i=0;i<4;i++){
		[[ioValueInMatrix cellWithTag:i] setTextColor:[model ioInColor:i]];
		[[ioValueInMatrix cellWithTag:i] setStringValue:[model ioInString:i]];
	}
}

- (void) adcChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<8;i++){
			float theValue = 20./4095. * [model adc:i] -10;
			[[adcMatrix cellWithTag:i] setFloatValue:theValue];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<8){
			float theValue = 20./4095. * [model adc:chan] -10;
			[[adcMatrix cellWithTag:chan] setFloatValue:theValue];
		}
	}
}

- (void) ioNameChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<4;i++){
			[[ioNameMatrix cellWithTag:i] setStringValue:[model ioName:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<4) [[ioNameMatrix cellWithTag:chan] setStringValue:[model ioName:chan]];
	}
}

- (void) doNameChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<16;i++){
			[[doNameMatrix cellWithTag:i] setStringValue:[model doName:i]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		[[doNameMatrix cellWithTag:chan]   setStringValue:[model doName:chan]];
	}
}



#pragma mark •••Notifications
- (void) interfacesChanged:(NSNotification*)aNote
{
	[self populateInterfacePopup:[aNote object]];
}

- (void) lockChanged:(NSNotification*)aNote
{
	//BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORLabJackModelLock];
    BOOL locked = [gSecurity isLocked:ORLabJackModelLock];
    [lockButton setState: locked];
	[serialNumberPopup setEnabled:!locked];
}

- (void) serialNumberChanged:(NSNotification*)aNote
{
	if(![model serialNumber] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
	else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
	[[self window] setTitle:[model title]];
}

#pragma mark •••Actions

- (void) digitalOutputEnabledAction:(id)sender
{
	[model setDigitalOutputEnabled:[sender state]];	
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORLabJackModelLock to:[sender intValue] forWindow:[self window]];
}

- (void) populateInterfacePopup:(ORUSB*)usb
{
	NSArray* interfaces = [usb interfacesForVender:[model vendorID] product:[model productID]];
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
	if([model serialNumber])[serialNumberPopup selectItemWithTitle:[model serialNumber]];
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

- (IBAction) channelNameAction:(id)sender
{
	[model setChannel:[[sender selectedCell] tag] name:[[sender selectedCell] stringValue]];
}

- (IBAction) ioNameAction:(id)sender
{
	[model setIo:[[sender selectedCell] tag] name:[[sender selectedCell] stringValue]];
}

- (IBAction) doNameAction:(id)sender
{
	[model setDo:[[sender selectedCell] tag] name:[[sender selectedCell] stringValue]];
}

- (IBAction) updateAllAction:(id)sender
{
	[model updateAll];
}

- (IBAction) ioDirectionBitAction:(id)sender
{
	[model setIoDirectionBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) doDirectionBitAction:(id)sender
{
	int theIndex = [[sender selectedCell] tag];
	[model setDoDirectionBit:theIndex withValue:[sender intValue]];
}


- (IBAction) ioValueOutBitAction:(id)sender
{
	[model setIoValueOutBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) doValueOutBitAction:(id)sender
{
	int theIndex = [[sender selectedCell] tag];
	[model setDoValueOutBit:theIndex withValue:[sender intValue]];
}

- (IBAction) resetCounter:(id)sender
{
	[model resetCounter];
}

@end
