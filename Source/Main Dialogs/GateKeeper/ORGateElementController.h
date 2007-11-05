//
//  ORGateElementController.h
//  Orca
//
//  Created by Mark Howe on 1/25/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files

#pragma mark •••Forward Declarations

@interface ORGateElementController : NSObject 
{
    @protected
        id model;
        BOOL ignore;
        
    @private
        IBOutlet NSPopUpButton* decoderTargetPopup;
        IBOutlet NSTextField*   crateField;
        IBOutlet NSTextField*   cardField;
        IBOutlet NSTextField*   channelField;
        
        NSMutableArray*         decoderList;
}

#pragma mark •••Initialization
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark •••Accessors
- (BOOL) ignore;
- (void) setIgnore:(BOOL)aIgnore;
- (id) model;
- (void) setModel: (id) aGateElement;
- (NSMutableArray *) decoderList;
- (void) setDecoderList: (NSMutableArray *) aDecoderList;


#pragma mark •••Notifications
- (void) registerNotificationObservers;


#pragma mark ***Interface Management
- (void) updateWindow;
- (void) decoderTargetChanged:(NSNotification*)aNote;
- (void) crateChanged:(NSNotification*)aNote;
- (void) cardChanged:(NSNotification*)aNote;
- (void) channelChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNotification;

#pragma mark ***Actions
- (IBAction) decoderTargetAction:(id)sender;
- (IBAction) crateAction:(id)sender;
- (IBAction) cardAction:(id)sender;
- (IBAction) channelAction:(id)sender;

@end
