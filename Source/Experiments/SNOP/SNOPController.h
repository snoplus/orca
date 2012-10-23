//
//  SNOPController.h
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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

#import "ORExperimentController.h"
#import "SNOPDetectorView.h"

@class ORColorScale;
@class ORSegmentGroup;

@interface SNOPController : ORExperimentController {
	IBOutlet NSTextField*	detectorTitle;
	IBOutlet NSPopUpButton*	viewTypePU;

	NSView *blankView;
	NSSize detectorSize;
	NSSize detailsSize;
	NSSize focalPlaneSize;
	NSSize couchDBSize;
	NSSize hvMasterSize;
	NSSize slowControlSize;
    
    IBOutlet NSTextField *morcaUserNameField;
    IBOutlet NSSecureTextField *morcaPasswordField;
    IBOutlet NSTextField *morcaDBNameField;
    IBOutlet NSTextField *morcaPortField;
    IBOutlet NSComboBox *morcaIPAddressPU;
    IBOutlet NSButton *morcaIsVerboseButton;
    IBOutlet NSButton *morcaIsWithinRunButton;
    IBOutlet NSPopUpButton *morcaUpdateRatePU;
    IBOutlet NSTextField *morcaStatusField;
    IBOutlet NSMatrix* hvStatusMatrix;
}

#pragma mark ¥¥¥Initialization
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ¥¥¥Interface
- (void) morcaUserNameChanged:(NSNotification*)aNote;
- (void) morcaPasswordChanged:(NSNotification*)aNote;
- (void) morcaDBNameChanged:(NSNotification*)aNote;
- (void) morcaPortChanged:(NSNotification*)aNote;
- (void) morcaIPAddressChanged:(NSNotification*)aNote;
- (void) morcaIsVerboseChanged:(NSNotification*)aNote;
- (void) morcaIsWithinRunChanged:(NSNotification*)aNote;
- (void) morcaUpdateRateChanged:(NSNotification*)aNote;
- (void) morcaStatusChanged:(NSNotification*)aNote;

- (void) hvStatusChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) viewTypeAction:(id)sender;

- (IBAction)morcaUserNameAction:(id)sender;
- (IBAction)morcaPasswordAction:(id)sender;
- (IBAction)morcaDBNameAction:(id)sender;
- (IBAction)morcaPortAction:(id)sender;
- (IBAction)morcaIPAddressAction:(id)sender;
- (IBAction)morcaClearHistoryAction:(id)sender;
- (IBAction)morcaFutonAction:(id)sender;
- (IBAction)morcaTestAction:(id)sender;
- (IBAction)morcaPingAction:(id)sender;
- (IBAction)morcaUpdateNowAction:(id)sender;
- (IBAction)morcaStartAction:(id)sender;
- (IBAction)morcaStopAction:(id)sender;
- (IBAction)morcaIsVerboseAction:(id)sender;
- (IBAction)morcaUpdateRateAction:(id)sender;
- (IBAction)morcaUpdateWithinRunAction:(id)sender;

- (IBAction)hvMasterPanicAction:(id)sender;

#pragma mark ¥¥¥Details Interface Management
- (void) setDetectorTitle;
- (void) viewTypeChanged:(NSNotification*)aNote;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem;

@end
@interface ORDetectorView (SNO)
- (void) setViewType:(int)aState;
@end
