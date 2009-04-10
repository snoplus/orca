//
//  ORZupController.m
//  Orca
//
//  Created by Mark Howe on Monday March 16,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORZupController.h"
#import "ORZupModel.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"

@interface ORZupController (private)
- (void) populatePortListPopup;
@end

@implementation ORZupController
- (id) init
{
    self = [ super initWithWindowNibName: @"Zup" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [self populatePortListPopup];


    basicOpsSize	= NSMakeSize(280,280);
    rampOpsSize		= NSMakeSize(570,650);
    blankView		= [[NSView alloc] init];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORZup%d.selectedtab",[model uniqueIdNumber]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	[super awakeFromNib];

}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORZupLock
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORZupModelPortNameChanged
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(boardAddressChanged:)
                         name : ORZupModelBoardAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(outputStateChanged:)
                         name : ORZupModelOutputStateChanged
						object: model];

}


- (void) updateWindow
{
    [ super updateWindow ];
    [self lockChanged:nil];
	[self portStateChanged:nil];
    [self portNameChanged:nil];
   
	[self boardAddressChanged:nil];
	[self outputStateChanged:nil];
}

- (void) outputStateChanged:(NSNotification*)aNote
{
	if([model sentAddress]){
		[outputStateField setObjectValue: [model outputState]?@"ON":@"OFF"];
		[onOffButton setTitle:![model outputState]?@"TURN ON":@"TURN OFF"];
	}
	else {
		[outputStateField setObjectValue: @"--"];
		[onOffButton setTitle:@"--"];
	}
}

- (void) boardAddressChanged:(NSNotification*)aNote
{
	[boardAddressField setIntValue: [model boardAddress]];
}

- (void) portStateChanged:(NSNotification*)aNotification
{
    if(aNotification == nil || [aNotification object] == [model serialPort]){
        if([model serialPort]){
            [openPortButton setEnabled:YES];
			
            if([[model serialPort] isOpen]){
                [openPortButton setTitle:@"Close"];
                [portStateField setTextColor:[NSColor colorWithCalibratedRed:0.0 green:.8 blue:0.0 alpha:1.0]];
                [portStateField setStringValue:@"Open"];
				
            }
            else {
                [openPortButton setTitle:@"Open"];
                [portStateField setStringValue:@"Closed"];
                [portStateField setTextColor:[NSColor redColor]];
            }
        }
        else {
            [openPortButton setEnabled:NO];
            [portStateField setTextColor:[NSColor blackColor]];
            [portStateField setStringValue:@"---"];
            [openPortButton setTitle:@"---"];
        }
    }
}

- (void) portNameChanged:(NSNotification*)aNotification
{
    NSString* portName = [model portName];
    
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
	
    [portListPopup selectItemAtIndex:0]; //the default
    while (aPort = [enumerator nextObject]) {
        if([portName isEqualToString:[aPort name]]){
            [portListPopup selectItemWithTitle:portName];
            break;
        }
	}  
    [self portStateChanged:nil];
}


- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:basicOpsSize];    break;
		case  1: [self resizeWindowToSize:rampOpsSize];	    break;
    }
    [[self window] setContentView:totalView];
            
    NSString* key = [NSString stringWithFormat: @"orca.ORZup%d.selectedtab",[model uniqueIdNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORZupLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self setButtonStates];
}

- (void) updateButtons
{
}

#pragma mark •••Notifications

- (void) setButtonStates
{
    //BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORZupLock];
	int  ramping		= [model runningCount]>0;

    [lockButton setState: locked];
	[sendButton setEnabled:!locked && !ramping];
	[super setButtonStates];
}

- (NSString*) windowNibName
{
	return @"Zup";
}

- (NSString*) rampItemNibFileName
{
	//subclasses can specify a differant RampItem nib file if needed.
	return @"ZupRampItem";
}

#pragma mark •••Actions

- (IBAction) boardAddressAction:(id)sender
{
	[model setBoardAddress:[sender intValue]];	
}

- (IBAction) getStatusAction:(id)sender
{
	[model getStatus];	
}
- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORZupLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) initBoard:(id) sender
{
	[model initBoard];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) onOffAction:(id)sender
{
	[model togglePower];
}

@end

@implementation ORZupController (private)

- (void) populatePortListPopup
{
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
    [portListPopup removeAllItems];
    [portListPopup addItemWithTitle:@"--"];
	
	while (aPort = [enumerator nextObject]) {
        [portListPopup addItemWithTitle:[aPort name]];
	}    
}
@end


