//-------------------------------------------------------------------------
//  ORGretinaTriggerController.h
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h"
#import "ORGretinaTriggerModel.h"

@interface ORGretinaTriggerController : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
	IBOutlet NSMatrix*      inputLinkMaskMatrix;

    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;

    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      registerLockButton;
    IBOutlet NSButton*      probeButton;
    IBOutlet NSPopUpButton* masterRouterPU;
 
	
    //register page
	IBOutlet NSPopUpButton*	registerIndexPU;
	IBOutlet NSTextField*	registerWriteValueField;
	IBOutlet NSButton*		writeRegisterButton;
	IBOutlet NSButton*		readRegisterButton;
	IBOutlet NSTextField*	registerStatusField;
		
    NSView *blankView;
    NSSize settingSize;
    NSSize registerTabSize;

    
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) inputLinkMaskChanged:(NSNotification*)aNote;
- (void) registerIndexChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) setRegisterDisplay:(unsigned int)index;
- (void) isMasterChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) probeBoard:(id)sender;

- (IBAction) isMasterAction:(id)sender;
- (IBAction) registerIndexPUAction:(id)sender;
- (IBAction) readRegisterAction:(id)sender;
- (IBAction) writeRegisterAction:(id)sender;
- (IBAction) registerLockAction:(id) sender;
- (IBAction) registerWriteValueAction:(id)sender;

#pragma mark •••Data Source
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

@end
