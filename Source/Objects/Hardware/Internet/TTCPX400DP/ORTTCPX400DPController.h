//
//  ORTTCPX400DPController.m
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

#import "OrcaObjectController.h"


@interface ORTTCPX400DPController : OrcaObjectController 
{
	IBOutlet NSButton*		lockButton;
    IBOutlet NSTextField*   ipAddressBox;
    IBOutlet NSPopUpButton* commandPopUp;
    IBOutlet NSPopUpButton* outputNumberPopUp;
    IBOutlet NSTextField*   inputValueText;    
    IBOutlet NSTextField*   readBackText;
    IBOutlet NSButton*      sendCommandButton;    
    IBOutlet NSButton*      connectButton;     
}

#pragma mark •••Initialization
- (id)	 init;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) lockChanged:(NSNotification*)aNote;
- (void) ipChanged:(NSNotification*)aNote;
- (void) connectionChanged:(NSNotification*)aNote;
- (void) generalReadbackChanged:(NSNotification*)aNote;

#pragma mark •••Actions
//- (IBAction) passwordFieldAction:(id)sender;
- (IBAction) lockAction:(id)sender;
- (IBAction) commandPulldownAction:(id)sender;
- (IBAction) connectAction:(id)sender;
- (IBAction) sendCommandAction:(id)sender;
@end


