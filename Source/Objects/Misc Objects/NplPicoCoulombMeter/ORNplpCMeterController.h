//
//  ORHPNplpCMeterController.h
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
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

#import "OrcaObjectController.h"

@interface ORNplpCMeterController : OrcaObjectController 
{
	IBOutlet NSTextField*	ipConnectedTextField;
	IBOutlet NSTextField*	ipAddressTextField;
	IBOutlet NSButton*		ipConnectButton;
	IBOutlet NSTextField*	frameErrorField;
	IBOutlet NSTextField*	receiveCountField;
	IBOutlet NSMatrix*		averageValueMatrix;
	IBOutlet NSButton*		dialogLock;
}

#pragma mark •••Notifications

#pragma mark ***Interface Management
- (void) receiveCountChanged:(NSNotification*)aNote;
- (void) isConnectedChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) frameErrorChanged:(NSNotification*)aNote;
- (void) averageChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) ipAddressTextFieldAction:(id)sender;
- (IBAction) connectAction:(id)sender;
- (IBAction) dialogLockAction:(id)sender;

@end

