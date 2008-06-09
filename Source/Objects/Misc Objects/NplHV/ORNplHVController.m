//
//  ORHPNplHVController.m
//  Orca
//
//  Created by Mark Howe on Thurs Dec 6 2007
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORNplHVController.h"
#import "ORNplHVModel.h"

@implementation ORNplHVController
- (id) init
{
    self = [ super initWithWindowNibName: @"NplHV" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    basicOpsSize	= NSMakeSize(320,320);
    rampOpsSize		= NSMakeSize(570,750);
    blankView		= [[NSView alloc] init];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORNplHV%d.selectedtab",[model uniqueIdNumber]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];

}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORNplHVModelIpAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isConnectedChanged:)
                         name : ORNplHVModelIsConnectedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(boardChanged:)
                         name : ORNplHVModelBoardChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(channelChanged:)
                         name : ORNplHVModelChannelChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(functionChanged:)
                         name : ORNplHVModelFunctionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(writeValueChanged:)
                         name : ORNplHVModelWriteValueChanged
						object: model];

	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORNplHVLock
						object: nil];
}


- (void) updateWindow
{
    [ super updateWindow ];
    
	[self ipAddressChanged:nil];
	[self isConnectedChanged:nil];
	[self boardChanged:nil];
	[self channelChanged:nil];
	[self functionChanged:nil];
	[self writeValueChanged:nil];
    [self lockChanged:nil];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:basicOpsSize];    break;
		case  1: [self resizeWindowToSize:rampOpsSize];	    break;
    }
    [[self window] setContentView:totalView];
            
    NSString* key = [NSString stringWithFormat: @"orca.ORNplHV%d.selectedtab",[model uniqueIdNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORNplHVLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self setButtonStates];
}

- (void) updateButtons
{
	[writeValueField setEnabled:[model functionNumber] >= 2];
}

- (void) writeValueChanged:(NSNotification*)aNote
{
	[writeValueField setIntValue: [model writeValue]];
}

- (void) functionChanged:(NSNotification*)aNote
{
	[functionPU selectItemAtIndex: [model functionNumber]];
	[self updateButtons];
}

- (void) channelChanged:(NSNotification*)aNote
{
	[channelPU selectItemAtIndex: [model channel]];
}

- (void) boardChanged:(NSNotification*)aNote
{
	[boardPU selectItemAtIndex: [model board]];
}

#pragma mark •••Notifications
- (void) isConnectedChanged:(NSNotification*)aNote
{
	[ipConnectedTextField setStringValue: [model isConnected]?@"Connected":@"Not Connected"];
	[ipConnectButton setTitle:[model isConnected]?@"Disconnect":@"Connect"];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
}

- (void) setButtonStates
{
    BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORNplHVLock];
	int  ramping		= [model runningCount]>0;

    [lockButton setState: locked];
	[ipConnectButton setEnabled:!runInProgress || !locked && !ramping];
	[ipAddressTextField setEnabled:!locked && !ramping];
	[writeValueField setEnabled:!locked && [model functionNumber] >= 2 && !ramping];
	[functionPU setEnabled:!locked && !ramping];
	[channelPU setEnabled:!locked && !ramping];
	[boardPU setEnabled:!locked && !ramping];
	[sendButton setEnabled:!locked && !ramping];
	[super setButtonStates];
}

- (NSString*) windowNibName
{
	return @"NplHV";
}

- (NSString*) rampItemNibFileName
{
	//subclasses can specify a differant RampItem nib file if needed.
	return @"HVRampItem";
}

#pragma mark •••Actions
- (void) writeValueAction:(id)sender
{
	[model setWriteValue:[sender intValue]];	
}

- (void) functionAction:(id)sender
{
	[model setFunctionNumber:[sender indexOfSelectedItem]];	
}

- (void) channelAction:(id)sender
{
	[model setChannel:[sender indexOfSelectedItem]];	
}

- (void) boardAction:(id)sender
{
	[model setBoard:[sender indexOfSelectedItem]];	
}

- (IBAction) ipAddressTextFieldAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

- (IBAction) connectAction:(id)sender
{
	[self endEditing];
	[model connect];
}

- (IBAction) sendCmdAction:(id)sender
{
	[self endEditing];
	[model sendCmd];
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORNplHVLock to:[sender intValue] forWindow:[self window]];
}
@end
