//
//  ORHP6622aController.m
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
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


#import "ORHP6622aController.h"
#import "ORHP6622aModel.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"


@interface ORHP6622aController (private)
- (void) _clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (void) systemTest;
@end

@implementation ORHP6622aController
- (id) init
{
    self = [ super initWithWindowNibName: @"HP6622a" ];
    return self;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
      
    [ notifyCenter addObserver: self
                      selector: @selector( lockChanged: )
                          name: ORRunStatusChangedNotification
                        object: nil];
    
     [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORHP6622aLock
                        object: model];
    	
	[notifyCenter addObserver : self
					  selector: @selector(lockChanged:)
						  name: ORHP6622aModelLockGUIChanged
					   object : model];


	[notifyCenter addObserver : self
					  selector: @selector(lockChanged:)
						  name: ORHP6622aModelLockGUIChanged
					   object : model];

	[notifyCenter addObserver : self
					  selector: @selector(outputOnChanged:)
						  name: ORHP6622aOutputOnChanged
					   object : model];


	[notifyCenter addObserver : self
					  selector: @selector(ocProtectionOnChanged:)
						  name: ORHP6622aOcProtectionOnChanged
					   object : model];

	[notifyCenter addObserver : self
					  selector: @selector(setVoltageChanged:)
						  name: ORHP6622aSetVolageChanged
					   object : model];

	[notifyCenter addObserver : self
					  selector: @selector(actVoltageChanged:)
						  name: ORHP6622aActVolageChanged
					   object : model];

	[notifyCenter addObserver : self
					  selector: @selector(overVoltageChanged:)
						  name: ORHP6622aOverVolageChanged
					   object : model];

	[notifyCenter addObserver : self
					  selector: @selector(setCurrentChanged:)
						  name: ORHP6622aSetCurrentChanged
					   object : model];

	[notifyCenter addObserver : self
					  selector: @selector(actCurrentChanged:)
						  name: ORHP6622aActCurrentChanged
					   object : model];
}

- (void) updateWindow
{
    [ super updateWindow ];
    [self lockChanged:nil];
    [self outputOnChanged:nil];
    [self ocProtectionOnChanged:nil];
    [self setVoltageChanged:nil];
    [self actVoltageChanged:nil];
    [self setCurrentChanged:nil];
    [self overVoltageChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORHP6622aLock to:secure];
    
    [lockButton setEnabled:secure];
}

- (void) lockChanged: (NSNotification*) aNotification
{
	[self setButtonStates];

}

- (void) primaryAddressChanged:(NSNotification*)aNotification
{
	[super primaryAddressChanged:aNotification];
	[[self window] setTitle:[model title]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[model title]];
}

- (void) setButtonStates
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORHP6622aLock];
	BOOL runInProgress  = [gOrcaGlobals runInProgress];
	
	//BOOL locked		= [gSecurity isLocked:ORHP6622aLock];
      
	[sendCommandButton setEnabled:!lockedOrRunningMaintenance];
	[commandField setEnabled:!lockedOrRunningMaintenance];
	
	[outputOnMatrix setEnabled:!lockedOrRunningMaintenance];
	[setVoltageMatrix setEnabled:!lockedOrRunningMaintenance];
	[setCurrentMatrix setEnabled:!lockedOrRunningMaintenance];
	[overVoltageMatrix setEnabled:!lockedOrRunningMaintenance];
	[ocProtectionMatrix setEnabled:!lockedOrRunningMaintenance];
	[ocProtectionMatrix setEnabled:!lockedOrRunningMaintenance];
	[sendToHWButton setEnabled:!lockedOrRunningMaintenance];
	[readFromHWButton setEnabled:!lockedOrRunningMaintenance];
	
	NSString* s = @"";
	if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORHP6622aLock])s = @"Not in Maintenance Run.";
    }
    [lockDocField setStringValue:s];
}

- (void) actCurrentChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[actCurrentMatrix cellWithTag:i] setFloatValue:[model actCurrent:i]];
	}
}


- (void) setCurrentChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[setCurrentMatrix cellWithTag:i] setFloatValue:[model setCurrent:i]];
	}
}

- (void) overVoltageChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[overVoltageMatrix cellWithTag:i] setFloatValue:[model overVoltage:i]];
	}
}

- (void) actVoltageChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[actVoltageMatrix cellWithTag:i] setFloatValue:[model actVoltage:i]];
	}
}


- (void) outputOnChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[outputOnMatrix cellWithTag:i] setState:[model outputOn:i]];
	}
}

- (void) ocProtectionOnChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[ocProtectionMatrix cellWithTag:i] setState:[model ocProtectionOn:i]];
	}
}

- (void) setVoltageChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[setVoltageMatrix cellWithTag:i] setFloatValue:[model setVoltage:i]];
	}
}


#pragma mark ¥¥¥Actions
- (IBAction) sendCommandAction:(id)sender
{
	NS_DURING
		[self endEditing];
		if([commandField stringValue]){
			[model writeToGPIBDevice:[commandField stringValue]];
		}
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER

}


- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORHP6622aLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) idAction:(id)sender
{
	NS_DURING
		[model readIDString];
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}
- (IBAction) testAction:(id)sender
{
	NS_DURING
		[model doSelfTest];
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction) sendToHWAction:(id)sender
{
	NS_DURING
		[self endEditing];
		[model sendAllToHW];
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction) readHWAction:(id)sender
{
	NS_DURING
		[self endEditing];
		[model readAllHW];
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction) outputOnAction:(id)sender
{
	NS_DURING
		[model setOutputOn:[[sender selectedCell] tag] withValue:[[sender selectedCell] intValue]];
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction) ocProtectionOnAction:(id)sender
{
	NS_DURING
		[model setOcProtectionOn:[[sender selectedCell] tag] withValue:[[sender selectedCell] intValue]];
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction) setVoltageAction:(id)sender
{
	NS_DURING
		[model setSetVoltage:[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction) setCurrentAction:(id)sender
{
	NS_DURING
		[model setSetCurrent:[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction) setOverVoltageAction:(id)sender
{
	NS_DURING
		[model setOverVoltage:[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction) resetOverVoltageAction:(id)sender
{
	NS_DURING
		[model resetOverVoltage:[[sender selectedCell] tag]];
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}

- (IBAction) resetOcProtectionAction:(id)sender
{
	NS_DURING
		[model resetOcProtection:[[sender selectedCell] tag]];
	NS_HANDLER
        NSLog( [ localException reason ] );
        NSRunAlertPanel( [ localException name ], 	// Name of panel
                         [ localException reason ],	// Reason for error
                         @"OK",				// Okay button
                         nil,				// alternate button
                         nil );				// other button
	NS_ENDHANDLER
}


@end
