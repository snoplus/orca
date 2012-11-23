//
//  ORTTCPX400DPController.h
//  Orca
//
//  Created by Michael Marino on Saturday 12 Nov 2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORTTCPX400DPController.h"
#import "ORTTCPX400DPModel.h"
#import "ORVXI11HardwareFinder.h"

@interface ORTTCPX400DPController (private)
- (void) _buildPopUpButtons;
@end

@implementation ORTTCPX400DPController
- (id) init
{
    self = [ super initWithWindowNibName: @"TTCPX400DP" ];
    return self;
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"TT CPX400DP  %@",[model serialNumber]]];
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
					 selector : @selector(hwFinderChanged:)
						 name : ORHardwareFinderAvailableHardwareChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORTTCPX400DPModelLock
						object: nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(ipChanged:)
						 name : ORTTCPX400DPIpHasChanged
						object: nil];  

    [notifyCenter addObserver : self
					 selector : @selector(serialChanged:)
						 name : ORTTCPX400DPSerialNumberHasChanged
						object: nil];      
    
    [notifyCenter addObserver : self
					 selector : @selector(generalReadbackChanged:)
						 name : ORTTCPX400DPGeneralReadbackHasChanged
						object: nil];        
    
    [notifyCenter addObserver : self
					 selector : @selector(connectionChanged:)
						 name : ORTTCPX400DPConnectionHasChanged
						object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(verbosityChanged:)
						 name : ORTTCPX400DPVerbosityHasChanged
						object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(readbackChanged:)
						 name : ORTTCPX400DPReadBackGetCurrentReadbackIsChanged
						object: nil];    
    
    [notifyCenter addObserver : self
					 selector : @selector(readbackChanged:)
						 name : ORTTCPX400DPReadBackGetVoltageTripSetIsChanged
						object: nil];

    [notifyCenter addObserver : self
					 selector : @selector(setValuesChanged:)
						 name : ORTTCPX_NOTIFY_WRITE_FORM(SetVoltage)
						object: nil];    
    
    [notifyCenter addObserver : self
					 selector : @selector(setValuesChanged:)
						 name : ORTTCPX_NOTIFY_WRITE_FORM(SetCurrentLimit)
						object: nil];    

    [notifyCenter addObserver : self
					 selector : @selector(setValuesChanged:)
						 name : ORTTCPX_NOTIFY_WRITE_FORM(SetOverVoltageProtectionTripPoint)
						object: nil];    
    
    [notifyCenter addObserver : self
					 selector : @selector(setValuesChanged:)
						 name : ORTTCPX_NOTIFY_WRITE_FORM(SetOverCurrentProtectionTripPoint)
						object: nil];        

    [notifyCenter addObserver : self
					 selector : @selector(outputStatusChanged:)
						 name : ORTTCPX_NOTIFY_WRITE_FORM(SetOutput)
						object: nil];      
    
}

- (void) awakeFromNib
{
	[super awakeFromNib];
    [self _buildPopUpButtons];
//	[ipNumberComboBox reloadData];
}

- (void) updateWindow
{
    [ super updateWindow ];
    [self lockChanged:nil];
    [self ipChanged:nil];
    [self serialChanged:nil];    
    [self generalReadbackChanged:nil];
    [self connectionChanged:nil];
    [self readbackChanged:nil]; 
    [self setValuesChanged:nil];
    [self outputStatusChanged:nil];
    [self verbosityChanged:nil];
}

- (void) _buildPopUpButtons
{
    if ([commandPopUp numberOfItems] == [model numberOfCommands]) return;
    [commandPopUp removeAllItems];
    int i;
    for (i=0; i<[model numberOfCommands]; i++) {
        [commandPopUp addItemWithTitle:[model commandName:i]];
        [[commandPopUp itemAtIndex:i] setTag:i];
    }
}

#pragma mark •••Notifications
- (void) lockChanged:(NSNotification*)aNote
{   
    BOOL locked = [gSecurity isLocked:ORTTCPX400DPModelLock];
    [lockButton setState: locked];
}

- (void) ipChanged:(NSNotification*)aNote
{   
    [ipAddressBox setStringValue:[model ipAddress]];
}

- (void) serialChanged:(NSNotification*)aNote
{   
    [serialNumberBox setStringValue:[model serialNumber]];
}

- (void) generalReadbackChanged:(NSNotification *)aNote
{
    [readBackText setStringValue:[model generalReadback]];
    //[sendCommandButton setEnabled:YES];    
}

- (void) connectionChanged:(NSNotification *)aNote
{
    BOOL isConnected = [model isConnected];
    if (isConnected) {
        [connectButton setTitle:@"Disconnect"];
        [serialNumberBox setEnabled:NO];
        [ipAddressBox setEnabled:NO];
    } else {
        [connectButton setTitle:@"Connect"];
        [serialNumberBox setEnabled:YES];
        [ipAddressBox setEnabled:YES];
    }
    [[self window] setTitle:[NSString stringWithFormat:@"TT CPX400DP  %@",[model serialNumber]]];
}

- (void) readbackChanged:(NSNotification *)aNote
{
    [readBackVoltOne setFloatValue:[model readBackGetVoltageReadbackWithOutput:0]];
    [readBackVoltTripOne setFloatValue:[model readBackGetVoltageTripSetWithOutput:0]];    
    [readBackCurrentOne setFloatValue:[model readBackGetCurrentReadbackWithOutput:0]];
    [readBackCurrentTripOne setFloatValue:[model readBackGetCurrentTripSetWithOutput:0]];   

    [readBackVoltTwo setFloatValue:[model readBackGetVoltageReadbackWithOutput:1]];
    [readBackVoltTripTwo setFloatValue:[model readBackGetVoltageTripSetWithOutput:1]];    
    [readBackCurrentTwo setFloatValue:[model readBackGetCurrentReadbackWithOutput:1]];
    [readBackCurrentTripTwo setFloatValue:[model readBackGetCurrentTripSetWithOutput:1]];    

}

- (void) setValuesChanged:(NSNotification*)aNote
{
    if (aNote == nil) {
        [writeVoltOne setFloatValue:[model writeToSetVoltageWithOutput:0]];
        [writeVoltTripOne setFloatValue:[model writeToSetOverVoltageProtectionTripPointWithOutput:0]];    
        [writeCurrentOne setFloatValue:[model writeToSetCurrentLimitWithOutput:0]];
        [writeCurrentTripOne setFloatValue:[model writeToSetOverCurrentProtectionTripPointWithOutput:0]];   
        
        [writeVoltTwo setFloatValue:[model writeToSetVoltageWithOutput:1]];
        [writeVoltTripTwo setFloatValue:[model writeToSetOverVoltageProtectionTripPointWithOutput:1]];    
        [writeCurrentTwo setFloatValue:[model writeToSetCurrentLimitWithOutput:1]];
        [writeCurrentTripTwo setFloatValue:[model writeToSetOverCurrentProtectionTripPointWithOutput:1]];
        return;
    }
    if ([[aNote name] isEqualToString:ORTTCPX_NOTIFY_WRITE_FORM(SetVoltage)]) {
        [writeVoltOne setFloatValue:[model writeToSetVoltageWithOutput:0]];
        [writeVoltTwo setFloatValue:[model writeToSetVoltageWithOutput:1]];        
    } else if ([[aNote name] isEqualToString:ORTTCPX_NOTIFY_WRITE_FORM(SetOverVoltageProtectionTripPoint)]) {
        [writeVoltTripOne setFloatValue:[model writeToSetOverVoltageProtectionTripPointWithOutput:0]];
        [writeVoltTripTwo setFloatValue:[model writeToSetOverVoltageProtectionTripPointWithOutput:1]];        
    } else if ([[aNote name] isEqualToString:ORTTCPX_NOTIFY_WRITE_FORM(SetOverCurrentProtectionTripPoint)]) {
        [writeCurrentTripOne setFloatValue:[model writeToSetOverCurrentProtectionTripPointWithOutput:0]];
        [writeCurrentTripTwo setFloatValue:[model writeToSetOverCurrentProtectionTripPointWithOutput:1]];        
    } else if ([[aNote name] isEqualToString:ORTTCPX_NOTIFY_WRITE_FORM(SetCurrentLimit)]) {
        [writeCurrentOne setFloatValue:[model writeToSetCurrentLimitWithOutput:0]];
        [writeCurrentTwo setFloatValue:[model writeToSetCurrentLimitWithOutput:1]];        
    }
}

- (void) outputStatusChanged:(NSNotification *)aNote
{
    [outputOnOne setState:[model writeToSetOutputWithOutput:0]];
    [outputOnTwo setState:[model writeToSetOutputWithOutput:1]];    
}

- (void) hwFinderChanged:(NSNotification*)aNote
{
    NSString* serialNumber = [model serialNumber];
    NSString* ipAddress = [model ipAddress];
    if ([serialNumber isEqualToString:@""]) {
        if([ipAddress isEqualToString:@""]) return;
        // Otherwise try to set the serial Number
        NSDictionary* dict = [[ORVXI11HardwareFinder sharedVXI11HardwareFinder] availableHardware];
        for (NSString* key in dict) {
            ORVXI11IPDevice* dev = [dict objectForKey:key];
            if ([[dev ipAddress] isEqualToString:ipAddress]) {
                [model setSerialNumber:[dev serialNumber]];
                break;
            }
        }
    } else {
        // Otherwise try to change the IP address
        NSDictionary* dict = [[ORVXI11HardwareFinder sharedVXI11HardwareFinder] availableHardware];
        for (NSString* key in dict) {
            ORVXI11IPDevice* dev = [dict objectForKey:key];
            if ([[dev serialNumber] isEqualToString:serialNumber]) {
                if ([ipAddress isEqualToString:[dev ipAddress]]) return;
                
                // Otherwise we need to ask for confirmation
                if (NSRunAlertPanel(@"IP Address changed",
                                [NSString stringWithFormat:@"The IP (%@) of %@,%@ has changed to %@.  Do you wish to allow this?",
                                 [model ipAddress],[model objectName],[model serialNumber],[dev ipAddress]],
                                    @"OK",@"Cancel", nil) == NSAlertDefaultReturn) {
                    [model setIpAddress:[dev ipAddress]];
                }
                break;
            }
        }
    }
}

- (void) verbosityChanged:(NSNotification*)aNote
{
    [verbosity setState:[model verbose]];
}

#pragma mark •••Actions
- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORTTCPX400DPModelLock to:[sender intValue] forWindow:[self window]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORTTCPX400DPModelLock to:secure];
    [lockButton setEnabled:secure];
	//[self updateButtons];
}

- (IBAction) commandPulldownAction:(id)sender
{
    int selectedRow = [[sender selectedItem] tag];
    [inputValueText setEnabled:[model commandTakesInput:selectedRow]];
    [outputNumberPopUp setEnabled:[model commandTakesOutputNumber:selectedRow ]];    
}

- (IBAction) sendCommandAction:(id)sender
{
    [self endEditing];
    int cmd = [[commandPopUp selectedItem] tag];
    int output = [[outputNumberPopUp selectedItem] tag];
    float input = [inputValueText floatValue];
    [model writeCommand:cmd withInput:input withOutputNumber:output];
    //[sendCommandButton setEnabled:NO];
}

- (IBAction)connectAction:(id)sender
{
    [model toggleConnection];
}

- (IBAction)setSerialNumberAction:(id)sender
{
    [model setSerialNumber:[serialNumberBox stringValue]];
}

- (IBAction)setIPAddressAction:(id)sender
{
    [model setIpAddress:[ipAddressBox stringValue]];
}

- (IBAction)readBackAction:(id)sender
{
    [model readback];
}

- (IBAction) syncValuesAction:(id)sender
{
#define SYNCALL(val)                                                                        \
    [model setWriteToSetVoltage:[writeVolt ## val floatValue]                               \
                     withOutput:[writeVolt ## val tag]];                                    \
    [model setWriteToSetOverVoltageProtectionTripPoint:[writeVoltTrip ## val floatValue]    \
                                            withOutput:[writeVoltTrip ## val tag]];         \
    [model setWriteToSetCurrentLimit:[writeCurrent ## val floatValue]                       \
                          withOutput:[writeCurrent ## val tag]];                            \
    [model setWriteToSetOverCurrentProtectionTripPoint:[writeCurrentTrip ## val floatValue] \
                                            withOutput:[writeCurrentTrip ## val tag]];
    
    SYNCALL(One)
    SYNCALL(Two)
}

- (IBAction) writeOutputStatusAction:(id)sender
{
    if ([outputOnOne state] == [outputOnTwo state]) {
        [model setAllOutputToBeOn:[outputOnOne state]];
    } else {
        [model setOutput:0 toBeOn:[outputOnOne state]];
        [model setOutput:1 toBeOn:[outputOnTwo state]];        
    }
}

- (IBAction) changeVerbosityAction:(id)sender
{
    [model setVerbose:[sender state]];
}

@end

