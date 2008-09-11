//
//  ORMTCController.h
//  Orca
//
//Created by Mark Howe on Fri, May 2, 2008
//Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

@interface ORMTCController : OrcaObjectController {

    IBOutlet NSTabView*		tabView;
	//basic Ops
	IBOutlet NSProgressIndicator* basicOpsRunningIndicator;
	IBOutlet NSButton*		autoIncrementCB;
	IBOutlet NSMatrix*		useMemoryMatrix;
	IBOutlet NSTextField*	repeatDelayField;
	IBOutlet NSStepper*		repeatDelayStepper;
	IBOutlet NSTextField*	repeatCountField;
	IBOutlet NSStepper*		repeatCountStepper;
	IBOutlet NSTextField*	writeValueField;
	IBOutlet NSStepper*		writeValueStepper;
	IBOutlet NSTextField*	memoryOffsetField;
	IBOutlet NSStepper*		memoryOffsetStepper;
	IBOutlet NSPopUpButton* selectedRegisterPU;
	IBOutlet NSTextField*	loadFilePathField;
    IBOutlet NSTextField*   slotField;
    IBOutlet NSStepper* 	regBaseAddressStepper;
    IBOutlet NSTextField* 	regBaseAddressText;
    IBOutlet NSStepper* 	memBaseAddressStepper;
    IBOutlet NSTextField* 	memBaseAddressText;
	IBOutlet NSButton*		basicOpsLockButton;
 	IBOutlet NSTextField*	defaultFileField;
	
	//standard Ops
	IBOutlet NSButton*		standardOpsLockButton;

	//settings
	IBOutlet NSMatrix*		eSumViewTypeMatrix;
	IBOutlet NSMatrix*		nHitViewTypeMatrix;
 	IBOutlet NSTextField*	xilinxFileField;
	IBOutlet NSButton*		settingsLockButton;
	IBOutlet NSTextField*	lastFileLoadedField;
 	IBOutlet NSTextField*	lockOutWidthField;
 	IBOutlet NSTextField*	pedestalWidthField;
 	IBOutlet NSTextField*	nhit100LoPrescaleField;
 	IBOutlet NSTextField*	pulserPeriodField;
 	IBOutlet NSTextField*	low10MhzClockField;
 	IBOutlet NSTextField*	high10MhzClockField;
 	IBOutlet NSTextField*	fineSlopeField;
 	IBOutlet NSTextField*	minDelayOffsetField;
 	IBOutlet NSTextField*	coarseDelayField;
 	IBOutlet NSTextField*	fineDelayField;

	IBOutlet NSMatrix*		globalTriggerMaskMatrix;
	IBOutlet NSMatrix*		globalTriggerCrateMaskMatrix;
	IBOutlet NSMatrix*		pedCrateMaskMatrix;
	IBOutlet NSMatrix*		controlRegMaskMatrix;
	IBOutlet NSMatrix*		nhitMatrix;
	IBOutlet NSMatrix*		esumMatrix;
	IBOutlet NSTextField*	commentsField;
	IBOutlet NSButton*		commentButton;

	//trigger
	IBOutlet NSMatrix*		globalTriggerMaskMatrix2;
	IBOutlet NSMatrix*		globalTriggerCrateMaskMatrix2;
	IBOutlet NSMatrix*		pedCrateMaskMatrix2;


    NSView* blankView;
    NSSize  basicOpsSize;
    NSSize  standardOpsSize;
    NSSize  settingsSize;
    NSSize  triggerSize;

}

- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) eSumViewTypeChanged:(NSNotification*)aNote;
- (void) nHitViewTypeChanged:(NSNotification*)aNote;
- (void) mtcDataBaseChanged:(NSNotification*)aNote;
- (void) defaultFileChanged:(NSNotification*)aNote;
- (void) basicOpsRunningChanged:(NSNotification*)aNote;
- (void) autoIncrementChanged:(NSNotification*)aNote;
- (void) useMemoryChanged:(NSNotification*)aNote;
- (void) repeatDelayChanged:(NSNotification*)aNote;
- (void) repeatCountChanged:(NSNotification*)aNote;
- (void) writeValueChanged:(NSNotification*)aNote;
- (void) memoryOffsetChanged:(NSNotification*)aNote;
- (void) selectedRegisterChanged:(NSNotification*)aNote;
- (void) loadFilePathChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) regBaseAddressChanged:(NSNotification*)aNote;
- (void) memBaseAddressChanged:(NSNotification*)aNote;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item;
- (void) loadMasks;
- (void) lastFileLoadedChanged:(NSNotification*)aNote;

#pragma mark •••Helper
- (void) populatePullDown;

#pragma mark •••Button Stubs
//Actions for the various buttons in the MTC dialog.  There is a generic "buttonPushed()" method that
//is called by each of the individual actions to avoid redundant code.
- (IBAction) buttonPushed:(id) sender;

#pragma mark •••Actions
- (IBAction) lockAction:(id) sender;

//Basic Ops
- (IBAction) basicReadAction:(id) sender;
- (IBAction) basicWriteAction:(id) sender;
- (IBAction) basicStatusAction:(id) sender;
- (IBAction) basicStopAction:(id) sender;
- (IBAction) basicAutoIncrementAction:(id)sender;
- (IBAction) basicUseMemoryAction:(id)sender;
- (IBAction) basicRepeatDelayAction:(id)sender;
- (IBAction) basicRepeatCountAction:(id)sender;
- (IBAction) basicWriteValueAction:(id)sender;
- (IBAction) basicMemoryOffsetAction:(id)sender;
- (IBAction) basicSelectedRegisterAction:(id)sender;

//MTC Init Ops
- (IBAction) standardInitMTC:(id) sender;
- (IBAction) standardInitMTCnoXilinx:(id) sender;
- (IBAction) standardInitMTCno10MHz:(id) sender;
- (IBAction) standardInitMTCnoXilinxno10MHz:(id) sender;
- (IBAction) standardMakeOnlineCrateMasks:(id) sender;
- (IBAction) standardLoad10MHzCounter:(id) sender;
- (IBAction) standardLoadOnlineGTMasks:(id) sender;
- (IBAction) standardLoadMTCADacs:(id) sender;
- (IBAction) standardSetCoarseDelay:(id) sender;
- (IBAction) standardFirePedestals:(id) sender;
- (IBAction) standardFindTriggerZeroes:(id) sender;
- (IBAction) standardStopFindTriggerZeroes:(id) sender;
- (IBAction) standardPeriodicReadout:(id) sender;

//Settings
- (IBAction) eSumViewTypeAction:(id)sender;
- (IBAction) nHitViewTypeAction:(id)sender;
- (IBAction) settingsLoadDBFile:(id) sender;
- (IBAction) settingsDefValFile:(id) sender;
- (IBAction) settingsXilinxFile:(id) sender;
- (IBAction) settingsDefaultGetSet:(id) sender;
- (IBAction) settingsDefaultSaveSet:(id) sender;
- (IBAction) settingsMTCRecordSaveAs:(id) sender;
- (IBAction) settingsLoadDefVals:(id) sender;
- (IBAction) settingsPrint:(id) sender;
- (IBAction) settingsNewComments:(id) sender;
- (IBAction) settingsMTCDAction:(id) sender;
- (IBAction) settingsNHitAction:(id) sender;
- (IBAction) settingsESumAction:(id) sender;
- (IBAction) settingsGTMaskAction:(id) sender;
- (IBAction) settingsGTCrateMaskAction:(id) sender;
- (IBAction) settingsControlRegMaskAction:(id) sender; 
- (IBAction) settingsPEDCrateMaskAction:(id) sender; 

@end
