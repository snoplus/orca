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
	IBOutlet NSTextField* detectorTitle;
	IBOutlet NSPopUpButton*	viewTypePU;

	NSView *blankView;
	NSSize detectorSize;
	NSSize detailsSize;
	NSSize focalPlaneSize;
	NSSize couchDBSize;
	NSSize hvMasterSize;
	NSSize slowControlSize;
    
    IBOutlet NSComboBox *orcaDBIPAddressPU;
    IBOutlet NSComboBox *debugDBIPAddressPU;
    IBOutlet NSMatrix* hvStatusMatrix;
}

#pragma mark ¥¥¥Initialization
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ¥¥¥Interface
- (void) hvStatusChanged:(NSNotification*)aNote;
- (void) dbOrcaDBIPChanged:(NSNotification*)aNote;
- (void) dbDebugDBIPChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) viewTypeAction:(id)sender;

- (IBAction) orcaDBIPAddressAction:(id)sender;
- (IBAction) orcaDBClearHistoryAction:(id)sender;
- (IBAction) orcaDBFutonAction:(id)sender;
- (IBAction) orcaDBTestAction:(id)sender;
- (IBAction) orcaDBPingAction:(id)sender;

- (IBAction) debugDBIPAddressAction:(id)sender;
- (IBAction) debugDBClearHistoryAction:(id)sender;
- (IBAction) debugDBFutonAction:(id)sender;
- (IBAction) debugDBTestAction:(id)sender;
- (IBAction) debugDBPingAction:(id)sender;

- (IBAction) hvMasterPanicAction:(id)sender;
- (IBAction) hvMasterTriggersOFF:(id)sender;
- (IBAction) hvMasterTriggersON:(id)sender;
- (IBAction) hvMasterStatus:(id)sender;

#pragma mark ¥¥¥Details Interface Management
- (void) setDetectorTitle;
- (void) viewTypeChanged:(NSNotification*)aNote;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem;

@end
@interface ORDetectorView (SNO)
- (void) setViewType:(int)aState;
@end

extern NSString* ORSNOPRequestHVStatus;
