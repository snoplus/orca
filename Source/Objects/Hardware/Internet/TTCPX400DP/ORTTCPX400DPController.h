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
    IBOutlet NSTextField*   serialNumberBox;    
    IBOutlet NSPopUpButton* commandPopUp;
    IBOutlet NSPopUpButton* outputNumberPopUp;
    IBOutlet NSTextField*   inputValueText;    
    IBOutlet NSTextField*   readBackText;
    IBOutlet NSButton*      sendCommandButton;    
    IBOutlet NSButton*      connectButton; 
    
    IBOutlet NSTextField*   readBackVoltOne;
    IBOutlet NSTextField*   readBackVoltTripOne;    
    IBOutlet NSTextField*   readBackCurrentOne;
    IBOutlet NSTextField*   readBackCurrentTripOne;   
    
    IBOutlet NSTextField*   readBackVoltTwo;
    IBOutlet NSTextField*   readBackVoltTripTwo;    
    IBOutlet NSTextField*   readBackCurrentTwo;
    IBOutlet NSTextField*   readBackCurrentTripTwo;

    IBOutlet NSTextField*   writeVoltOne;
    IBOutlet NSTextField*   writeVoltTripOne;    
    IBOutlet NSTextField*   writeCurrentOne;
    IBOutlet NSTextField*   writeCurrentTripOne;   
    
    IBOutlet NSTextField*   writeVoltTwo;
    IBOutlet NSTextField*   writeVoltTripTwo;    
    IBOutlet NSTextField*   writeCurrentTwo;
    IBOutlet NSTextField*   writeCurrentTripTwo; 
    
    IBOutlet NSButton*      outputOnOne;
    IBOutlet NSButton*      outputOnTwo;    
}

#pragma mark •••Initialization
- (id)	 init;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) lockChanged:(NSNotification*)aNote;
- (void) ipChanged:(NSNotification*)aNote;
- (void) serialChanged:(NSNotification*)aNote;
- (void) connectionChanged:(NSNotification*)aNote;
- (void) generalReadbackChanged:(NSNotification*)aNote;
- (void) readbackChanged:(NSNotification*)aNote;
- (void) setValuesChanged:(NSNotification*)aNote;
- (void) outputStatusChanged:(NSNotification*)aNote;

#pragma mark •••Actions
//- (IBAction) passwordFieldAction:(id)sender;
- (IBAction) lockAction:(id)sender;
- (IBAction) commandPulldownAction:(id)sender;
- (IBAction) setSerialNumberAction:(id)sender;
- (IBAction) connectAction:(id)sender;
- (IBAction) sendCommandAction:(id)sender;
- (IBAction) readBackAction:(id)sender;

- (IBAction) writeVoltageAction:(id)sender;
- (IBAction) writeVoltageTripAction:(id)sender;
- (IBAction) writeCurrentAction:(id)sender;
- (IBAction) writeCurrentTripAction:(id)sender;
- (IBAction) writeOutputStatusAction:(id)sender;

@end


