//
//  ORHPApcUpsController.h
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
@class ORCompositeTimeLineView;

@interface ORApcUpsController : OrcaObjectController 
{
    IBOutlet NSTableView*   powerTableView;
    IBOutlet NSTableView*   loadTableView;
    IBOutlet NSTableView*   batteryTableView;
	IBOutlet NSTextField*	ipConnectedField;
	IBOutlet NSTextField*	ipAddressField;
	IBOutlet NSTextField*	usernameField;
	IBOutlet NSTextField*	passwordField;
	IBOutlet NSButton*		ipConnectButton;
	IBOutlet NSButton*		dialogLock;
	IBOutlet NSTextField*   lastPolledField;
	IBOutlet NSTextField*	nextPollField;
    IBOutlet NSTextField*   dataValidField;
    IBOutlet NSTableView*   processTableView;

	IBOutlet ORTimedTextField*	timedOutField;
	IBOutlet ORCompositeTimeLineView*   plotter0;
	IBOutlet ORCompositeTimeLineView*   plotter1;
}

#pragma mark ***Interface Management
- (void) isConnectedChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) refreshTables:(NSNotification*)aNote;
- (void) pollingTimesChanged:(NSNotification*)aNote;
- (void) dataValidChanged:(NSNotification*)aNote;
- (void) usernameChanged:(NSNotification*)aNote;
- (void) passwordChanged:(NSNotification*)aNote;
- (void) refreshProcessTable:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) timedOut:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) ipAddressAction:(id)sender;
- (IBAction) usernameAction:(id)sender;
- (IBAction) passwordAction:(id)sender;
- (IBAction) connectAction:(id)sender;
- (IBAction) dialogLockAction:(id)sender;

#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end

