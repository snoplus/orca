//
//  ORHP3458aController.m
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


#import "ORHP3458aController.h"
#import "ORHP3458aModel.h"


@interface ORHP3458aController (private)
- (void) _clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (void) systemTest;
@end

@implementation ORHP3458aController
- (id) init
{
    self = [ super initWithWindowNibName: @"HP3458a" ];
    return self;
}
- (void) awakeFromNib
{
    [super awakeFromNib];
    [self populatePullDown];
}

#pragma mark •••Notifications
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
                         name : ORHP3458aLock
                        object: model];
    	
	[notifyCenter addObserver : self
					  selector: @selector(lockChanged:)
						  name: ORHP3458aModelLockGUIChanged
					   object : model];


	[notifyCenter addObserver : self
					  selector: @selector(lockChanged:)
						  name: ORHP3458aModelLockGUIChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(functionDefChanged:)
                         name : ORHP3458aModelFunctionDefChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(maxInputChanged:)
                         name : ORHP3458aModelMaxInputChanged
						object: model];

}

- (void) updateWindow
{
    [ super updateWindow ];
    [self lockChanged:nil];
	[self functionDefChanged:nil];
	[self maxInputChanged:nil];
}

- (void) maxInputChanged:(NSNotification*)aNote
{
	[maxInputPU selectItemAtIndex: [model maxInput]];
}

- (void) functionDefChanged:(NSNotification*)aNote
{
	[functionDefPU selectItemWithTag: [model functionDef]];
    [self populatePullDown];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORHP3458aLock to:secure];
    
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
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORHP3458aLock];
	BOOL runInProgress  = [gOrcaGlobals runInProgress];
	
	//BOOL locked		= [gSecurity isLocked:ORHP3458aLock];
      
	[sendCommandButton setEnabled:!lockedOrRunningMaintenance];
	[commandField setEnabled:!lockedOrRunningMaintenance];
	

	[sendToHWButton setEnabled:!lockedOrRunningMaintenance];
	[readFromHWButton setEnabled:!lockedOrRunningMaintenance];
	
	NSString* s = @"";
	if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORHP3458aLock])s = @"Not in Maintenance Run.";
    }
    [lockDocField setStringValue:s];
}

#pragma mark •••Actions
- (void) maxInputAction:(id)sender
{
	[model setMaxInput:[sender indexOfSelectedItem]];	
}

- (void) functionDefAction:(id)sender
{
	[model setFunctionDef:[[sender selectedItem] tag]];	
}

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
    [gSecurity tryToSetLock:ORHP3458aLock to:[sender intValue] forWindow:[self window]];
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

- (void) populatePullDown
{
    short	i;
        
    [maxInputPU removeAllItems];
    
    for (i = 0; i < [model getNumberItemsForMaxInput]; i++) {
        [maxInputPU insertItemWithTitle:[model getMaxInputName:i] atIndex:i];
    }
     
    [self maxInputChanged:nil];

}


@end
