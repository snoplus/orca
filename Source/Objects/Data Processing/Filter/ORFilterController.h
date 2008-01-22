//
//  ORFilterController.h
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

@class ORTimedTextField;
@class ORScriptView;

@interface ORFilterController : OrcaObjectController {

	IBOutlet ORScriptView*		scriptView;
    IBOutlet NSButton*			lockButton;
 	IBOutlet NSView*			argsView;
	IBOutlet NSTextView*		helpView;
	IBOutlet ORTimedTextField*	statusField;
	IBOutlet NSView*			panelView;
	IBOutlet NSMatrix*			argsMatrix;
	IBOutlet id					loadSaveView;
    IBOutlet NSTextField*		lastFileField;
    IBOutlet NSTextField*		lastFileField1;
    IBOutlet NSTextField*		classNameField;
	IBOutlet NSTextField*		runStatusField;
	IBOutlet NSButton*			runButton;
	IBOutlet NSButton*			loadSaveButton;
}

#pragma mark •••Initialization
- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) scriptChanged:(NSNotification*)aNote;
- (void) runningChanged:(NSNotification*)aNote;
- (void) textDidChange:(NSNotification*)aNote;
- (void) argsChanged:(NSNotification*)aNote;
- (void) errorChanged:(NSNotification*)aNote;
- (void) lastFileChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) lockAction:(id)sender;
- (IBAction) listMethodsAction:(id) sender;
- (IBAction) cancelLoadSaveAction:(id)sender;
- (IBAction) parseScript:(id) sender;	
- (IBAction) runScript:(id) sender;
- (IBAction) nameAction:(id) sender;
- (IBAction) argAction:(id) sender;
- (IBAction) loadSaveAction:(id)sender;
- (IBAction) loadFileAction:(id) sender;
- (IBAction) saveAsFileAction:(id) sender;
- (IBAction) saveFileAction:(id) sender;

#pragma mark •••Interface Management
- (void) lockChanged:(NSNotification*)aNotification;
@end

