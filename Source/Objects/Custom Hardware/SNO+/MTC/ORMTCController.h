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

#import "ORPQResult.h"

@interface ORMTCController : OrcaObjectController {

    IBOutlet NSView *mtcView;
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
    IBOutlet NSTextField*   slotField;
    IBOutlet NSStepper* 	regBaseAddressStepper;
    IBOutlet NSTextField* 	regBaseAddressText;
    IBOutlet NSTextField* 	memBaseAddressText;
    IBOutlet NSStepper* 	memBaseAddressStepper;
	IBOutlet NSButton*		basicOpsLockButton;
    IBOutlet NSButton *readButton;
    IBOutlet NSButton *writteButton;
    IBOutlet NSButton *stopButton;
    IBOutlet NSButton *statusButton;

    
	//standard Ops
	IBOutlet NSButton*		initMtcButton;
	IBOutlet NSButton*		initNoXilinxButton;
	IBOutlet NSButton*		initNo10MHzButton;
	IBOutlet NSButton*		initNoXilinxNo100MHzButton;
	IBOutlet NSButton*		load10MhzCounterButton;
	IBOutlet NSButton*		setFineDelayButton;
	IBOutlet NSButton*		setCoarseDelayButton;
	IBOutlet NSButton*		loadMTCADacsButton;
	IBOutlet NSButton*		firePedestalsButton;
	IBOutlet NSButton*		stopPedestalsButton;
	IBOutlet NSButton*		continuePedestalsButton;
	IBOutlet NSButton*		fireFixedTimePedestalsButton;
	IBOutlet NSButton*		stopFixedTimePedestalsButton;
	IBOutlet NSTextField*		fixedTimePedestalsCountField;
	IBOutlet NSTextField*		fixedTimePedestalsDelayField;
	IBOutlet NSProgressIndicator* initProgressBar;
	IBOutlet NSTextField*	initProgressField;
	IBOutlet NSMatrix*		isPulserFixedRateMatrix;
    IBOutlet NSMatrix* pulserFeedsMatrix;
	
	//settings
	IBOutlet NSMatrix*		eSumViewTypeMatrix;
	IBOutlet NSMatrix*		nHitViewTypeMatrix;
 	IBOutlet NSTextField*	lockOutWidthField;
 	IBOutlet NSTextField*	pedestalWidthField;
 	IBOutlet NSTextField*	nhit100LoPrescaleField;
 	IBOutlet NSTextField*	pulserPeriodField;
    IBOutlet NSTextField*   extraPulserPeriodField;
 	IBOutlet NSTextField*	low10MhzClockField;
 	IBOutlet NSTextField*	high10MhzClockField;
 	IBOutlet NSTextField*	fineSlopeField;
 	IBOutlet NSTextField*	minDelayOffsetField;
 	IBOutlet NSTextField*	coarseDelayField;
 	IBOutlet NSTextField*	fineDelayField;

	IBOutlet NSMatrix*		nhitMatrix;
	IBOutlet NSMatrix*		esumMatrix;
	IBOutlet NSTextField*	commentsField;

	//trigger
	IBOutlet NSMatrix*		globalTriggerMaskMatrix;
	IBOutlet NSMatrix*		globalTriggerCrateMaskMatrix;
	IBOutlet NSMatrix*		pedCrateMaskMatrix;
	IBOutlet NSMatrix*		mtcaN100Matrix;
	IBOutlet NSMatrix*		mtcaN20Matrix;
	IBOutlet NSMatrix*		mtcaEHIMatrix;
	IBOutlet NSMatrix*		mtcaELOMatrix;
	IBOutlet NSMatrix*		mtcaOELOMatrix;
	IBOutlet NSMatrix*		mtcaOEHIMatrix;
	IBOutlet NSMatrix*		mtcaOWLNMatrix;
    
    IBOutlet NSButton* loadTriggerMaskButton;
    IBOutlet NSButton* loadGTCrateMaskButton;
    IBOutlet NSButton* loadPEDCrateMaskButton;
    IBOutlet NSButton* loadMTCACrateMaskButton;
    
    IBOutlet NSButton *clearTriggersButton;
    IBOutlet NSButton *clearGTCratesButton;
    IBOutlet NSButton *clearPEDCratesButton;
    IBOutlet NSButton *clearMTCAMaskButton;
    
	BOOL	sequenceRunning;
    NSView* blankView;
    NSSize  basicOpsSize;
    NSSize  standardOpsSize;
    NSSize  settingsSize;
    NSSize  triggerSize;

}

//Getter Method for the Text fields in the View
- (NSMutableDictionary*) getMatriciesFromNib;

- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) mtcDataBaseChanged:(NSNotification*)aNote;
- (void) basicOpsRunningChanged:(NSNotification*)aNote;
- (void) autoIncrementChanged:(NSNotification*)aNote;
- (void) useMemoryChanged:(NSNotification*)aNote;
- (void) repeatDelayChanged:(NSNotification*)aNote;
- (void) repeatCountChanged:(NSNotification*)aNote;
- (void) writeValueChanged:(NSNotification*)aNote;
- (void) memoryOffsetChanged:(NSNotification*)aNote;
- (void) selectedRegisterChanged:(NSNotification*)aNote;
- (void) basicLockChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) regBaseAddressChanged:(NSNotification*)aNote;
- (void) memBaseAddressChanged:(NSNotification*)aNote;
- (void) isPulserFixedRateChanged:(NSNotification*)aNote;
- (void) fixedPulserRateCountChanged:(NSNotification*)aNote;
- (void) fixedPulserRateDelayChanged:(NSNotification*)aNote;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item;
- (void) displayMasks;
- (void) sequenceRunning:(NSNotification*)aNote;
- (void) sequenceStopped:(NSNotification*)aNote;
- (void) sequenceProgress:(NSNotification*)aNote;
- (void) triggerMTCAMaskChanged:(NSNotification*)aNotification;
- (void) isPedestalEnabledInCSRChanged:(NSNotification*)aNotification;
- (void) placeholder:(NSNotification*) aNote;

- (int) convert_view_thresold_index_to_model_index: (int) view_index;
- (int) convert_model_threshold_index_to_view_index: (int) model_index;
- (int) convert_view_unit_index_to_model_index: (int) view_index;
- (int) convert_model_unit_index_to_view_index: (int) model_index;


//DB Access
- (void) load_settings_from_trigger_scan_for_type:(int) type;
- (void) grab_current_thresholds;

- (void) waitForTriggerScan: (ORPQResult *) result;
- (void) waitForThresholds: (ORPQResult *) result;

#pragma mark •••Helper
- (void) populatePullDown;
- (int) trigger_scan_name_to_index:(NSString*) name;
- (int) index_to_trigger_scan_name:(int) index;

#pragma mark •••Actions

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
- (IBAction) standardLoad10MHzCounter:(id) sender;
- (IBAction) standardLoadMTCADacs:(id) sender;
- (IBAction) standardSetCoarseDelay:(id) sender;
- (IBAction) standardSetFineDelay:(id) sender;
- (IBAction) standardIsPulserFixedRate:(id) sender;
- (IBAction) standardFirePedestals:(id) sender;
- (IBAction) standardStopPedestals:(id) sender;
- (IBAction) standardContinuePedestals:(id) sender;
- (IBAction) standardFirePedestalsFixedTime:(id) sender;
- (IBAction) standardStopPedestalsFixedTime:(id) sender;
- (IBAction) standardSetPedestalsCount:(id) sender;
- (IBAction) standardSetPedestalsDelay:(id) sender;
- (IBAction) standardPulserFeeds:(id)sender;

//Settings
- (IBAction) eSumViewTypeAction:(id)sender;
- (IBAction) nHitViewTypeAction:(id)sender;
- (IBAction) settingsMTCDAction:(id) sender;
- (IBAction) settingsNHitAction:(id) sender;
- (IBAction) settingsESumAction:(id) sender;
- (IBAction) settingsGTMaskAction:(id) sender;
- (IBAction) settingsGTCrateMaskAction:(id) sender;
- (IBAction) settingsPEDCrateMaskAction:(id) sender;

//Triggers
- (IBAction) triggerMTCAN100:(id) sender;
- (IBAction) triggerMTCAN20:(id) sender;
- (IBAction) triggerMTCAEHI:(id) sender;
- (IBAction) triggerMTCAELO:(id) sender;
- (IBAction) triggerMTCAOELO:(id) sender;
- (IBAction) triggerMTCAOEHI:(id) sender;
- (IBAction) triggerMTCAOWLN:(id) sender;

- (IBAction) triggersLoadTriggerMask:(id) sender;
- (IBAction) triggersLoadGTCrateMask:(id) sender;
- (IBAction) triggersLoadPEDCrateMask:(id) sender;
- (IBAction) triggersLoadMTCACrateMask:(id) sender;

- (IBAction) triggersClearTriggerMask:(id) sender;
- (IBAction) triggersClearGTCrateMask:(id) sender;
- (IBAction) triggersClearPEDCrateMask:(id) sender;
- (IBAction) triggersClearMTCACrateMask:(id) sender;

@end
