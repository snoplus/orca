//
//  ORUnivVoltController.h
//  Orca
//
//  Created by Jan Wouters on Tues June 24, 2008
//  Copyright (c) 2008, LANS. All rights reserved.
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
//#import "ORCard.h"

@interface ORUnivVoltController : OrcaObjectController {
//@interface ORUnivVoltController : ORCard {
	IBOutlet NSTextField*	ipConnectedTextField;
	IBOutlet NSTextField*	ipAddressTextField;
	IBOutlet NSButton*		ipConnectButton;
	IBOutlet NSMatrix*		averageValueMatrix;
	IBOutlet NSButton*		dialogLock;
}

#pragma mark ***Interface Management
//- (void) receiveCountChanged:(NSNotification*)aNote;
- (void) isConnectedChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
//- (void) frameErrorChanged:(NSNotification*)aNote;
- (void) averageChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) ipAddressTextFieldAction:(id)sender;
- (IBAction) connectAction:(id)sender;
- (IBAction) dialogLockAction:(id)sender;

@end

