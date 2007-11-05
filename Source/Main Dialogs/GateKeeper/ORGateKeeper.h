//
//  ORGateKeeper.h
//  Orca
//
//  Created by Mark Howe on 1/24/05.
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




@class ORGate;
@class ORGateGroup;
@class ORGateKeyController;
@class ORGatedValueController;

@interface ORGateKeeper : NSWindowController 
{
    IBOutlet NSTableView*   gateListView;
    IBOutlet NSButton*      addGateButton;
    IBOutlet NSButton*      removeGateButton;
    IBOutlet NSTextField*   gateNameField;
    IBOutlet NSTabView*     gateTabView;
    IBOutlet ORGateKeyController*    gateKeyController;
    IBOutlet ORGatedValueController* gatedValueController;
    IBOutlet ORGatedValueController* gatedValueControllerY;
    IBOutlet NSButton*		settingLockButton;
    IBOutlet NSTextField*   settingLockDocField;
    IBOutlet NSMatrix*		dimensionButton;
    IBOutlet NSTabView*     dimensionTabView;
    IBOutlet NSTextField*   preScaleField;
    IBOutlet NSTextField*   twoDSizeField;
    IBOutlet NSButton*      ignoreKeyButton;
    IBOutlet NSBox*         gatedValue1DBox;
   
    ORGate*                 selectedGate;
    ORGateGroup*            gateGroup;
}

#pragma mark ***Initialization
+ (id) sharedGateKeeper;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window;

- (ORGateGroup *) gateGroup;
- (void) setGateGroup: (ORGateGroup *) aGateGroup;

#pragma mark ***Interface Management
- (void) endEditing;
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) dimensionChanged:(NSNotification*)aNotification;
- (void) ignoreKeyChanged:(NSNotification*)aNotification;
- (void) preScaleChanged:(NSNotification*)aNotification;
- (void) twoDSizeChanged:(NSNotification*)aNotification;
- (void) windowDidResignMain:(NSNotification *)aNotification;
- (void) selectionChanged:(NSNotification*)aNote;
- (void) gateArrayChanged:(NSNotification*)aNote;
- (void) securityStateChanged:(NSNotification*)aNotification;
- (void) checkGlobalSecurity;

#pragma mark ***Accessors
- (ORGate *) selectedGate;
- (void) setSelectedGate: (ORGate *) aSelectedGate;

#pragma mark ***Actions
- (IBAction) settingLockAction:(id) sender;
- (IBAction) addGateAction:(id)sender;
- (IBAction) dimensionAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) gateNameAction:(id)sender;
- (IBAction) saveDocument:(id)sender;
- (IBAction) saveDocumentAs:(id)sender;
- (IBAction) twoDSizeAction:(id) sender;
- (IBAction) preScaleAction:(id) sender;
- (IBAction) ignoreKeyAction:(id) sender;

#pragma mark ***Data Source for Gate Table
- (int)  numberOfRowsInTableView:(NSTableView *)tableView;
- (id)   tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void) tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row;

@end

extern NSString* ORGateKeeperSettingsLock;

