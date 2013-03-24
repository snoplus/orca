
//
//  OREdelweissFLTController.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
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


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Imported Files
#import "OREdelweissFLTModel.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface OREdelweissFLTController : OrcaObjectController {
	@private
    
        //FLT settings
        IBOutlet NSButton*		settingLockButton;
	IBOutlet   NSTextField* wCmdArg2TextField;
	IBOutlet   NSTextField* wCmdArg1TextField;
	IBOutlet   NSTextField* wCmdCodeTextField;
	IBOutlet   NSTextField* adcRtTextField;
    
	IBOutlet   NSMatrix* dacbMatrix;
	IBOutlet   NSMatrix* signbMatrix;
	IBOutlet   NSMatrix* dacaMatrix;
	IBOutlet   NSMatrix* signaMatrix;
	IBOutlet   NSMatrix* adcRgForBBAccessMatrix;
    
    //BB access tab
	IBOutlet   NSButton*    writeToBBModeCB;
    IBOutlet   NSProgressIndicator*	writeToBBModeIndicator;
	IBOutlet   NSMatrix* adcValueForBBAccessMatrix;
	IBOutlet   NSMatrix* adcMultForBBAccessMatrix;
	IBOutlet   NSMatrix* adcFreqkHzForBBAccessMatrix;
	IBOutlet   NSButton* useBroadcastIdforBBAccessCB;
	IBOutlet   NSTextField* fiberIsBBv1TextField;
	IBOutlet   NSTextField* idBBforBBAccessTextField;
	IBOutlet   NSTextField* idBBforWCommandTextField;//clone of idBBforBBAccessTextField
	IBOutlet   NSTextField* idBBforAlimCommandTextField;//clone of idBBforBBAccessTextField
	IBOutlet   NSPopUpButton* fiberSelectForBBAccessPU;
	IBOutlet   NSMatrix* relaisStatesBBMatrix;
	    IBOutlet   NSPopUpButton* fiberSelectForBBStatusBitsPU;
	    IBOutlet NSButton*      tpixCB;
//	IBOutlet   No Outlet* swTriggerIsRepeatingNo Outlet;
		
	IBOutlet   NSTextField* repeatSWTriggerModeTextField;
		
		IBOutlet NSPopUpButton*	repeatSWTriggerModePU;
		IBOutlet NSProgressIndicator*	swTriggerProgress;
		//control register
	    IBOutlet   NSTextField* controlRegisterTextField;
		IBOutlet NSPopUpButton* fltModeFlagsPU;
		IBOutlet NSPopUpButton* statusLatencyPU;
	    IBOutlet NSButton*      vetoFlagCB;
	IBOutlet   NSTextField* totalTriggerNRegisterTextField;
	    //other registers
	    IBOutlet   NSMatrix*    fiberOutMaskMatrix;
        
	IBOutlet   NSTextField* statusRegisterTextField;
		IBOutlet NSMatrix*		fiberDelaysMatrix;
	    IBOutlet NSTextField*   fiberDelaysTextField;
	    IBOutlet NSButton*      fastWriteCB;
	    IBOutlet NSTextField*   streamMaskTextField;
		IBOutlet NSMatrix*		streamMaskMatrix;
		
		IBOutlet NSMatrix*		fiberEnableMaskMatrix;
		IBOutlet NSMatrix*		BBv1MaskMatrix;
		IBOutlet NSPopUpButton* selectFiberTrigPU;
		
		IBOutlet NSMatrix*		displayEventRateMatrix;
		IBOutlet NSTextField*	targetRateField;
        IBOutlet NSTextField*   fltSlotNumTextField;
        IBOutlet NSMatrix*      fltSlotNumMatrix;
		IBOutlet NSButton*		storeDataInRamCB;
		IBOutlet NSPopUpButton*	filterLengthPU;
		IBOutlet NSPopUpButton*	gapLengthPU;
		IBOutlet NSTextField*   postTriggerTimeField;
		IBOutlet NSMatrix*		fifoBehaviourMatrix;
		IBOutlet NSTextField*	interruptMaskField;
		IBOutlet NSPopUpButton*	modeButton;
		IBOutlet NSButton*		versionButton;
		IBOutlet NSButton*		statusButton;
		IBOutlet NSButton*		initBoardButton;
		IBOutlet NSButton*		reportButton;
		IBOutlet NSButton*		resetButton;
		IBOutlet NSMatrix*		gainTextFields;
		IBOutlet NSMatrix*		thresholdTextFields;
		IBOutlet NSMatrix*		triggerEnabledCBs;
		IBOutlet NSMatrix*		hitRateEnabledCBs;
		IBOutlet NSPopUpButton*	hitRateLengthPU;
		IBOutlet NSButton*		hitRateAllButton;
		IBOutlet NSButton*		hitRateNoneButton;
		IBOutlet NSButton*		triggersAllButton;
		IBOutlet NSButton*		triggersNoneButton;
		IBOutlet NSButton*		defaultsButton;
	
		//rate page
		IBOutlet NSMatrix*		rateTextFields;
		
		IBOutlet ORValueBarGroupView*		rate0;
		IBOutlet ORValueBarGroupView*		totalRate;
		IBOutlet NSButton*					rateLogCB;
		IBOutlet ORCompositeTimeLineView*	timeRatePlot;
		IBOutlet NSButton*					timeRateLogCB;
		IBOutlet NSButton*					totalRateLogCB;
		IBOutlet NSTextField*				totalHitRateField;
		IBOutlet NSTabView*					tabView;	
		IBOutlet NSView*					totalView;
		
		//test page
		IBOutlet NSButton*		testButton;
		IBOutlet NSMatrix*		testEnabledMatrix;
		IBOutlet NSMatrix*		testStatusMatrix;
		
		NSNumberFormatter*		rateFormatter;
		NSSize					settingSize;
		NSSize					BBAccessSize;
		NSSize					rateSize;
		NSSize					testSize;
		NSSize					lowlevelSize;
		NSView*					blankView;
        
        //low level
		IBOutlet NSPopUpButton*	registerPopUp;
		IBOutlet NSPopUpButton*	channelPopUp;
		IBOutlet NSStepper* 	regWriteValueStepper;
		IBOutlet NSTextField* 	regWriteValueTextField;
		IBOutlet NSButton*		regWriteButton;
		IBOutlet NSButton*		regReadButton;
	
		IBOutlet NSButton*      noiseFloorButton;
		//offset panel
		IBOutlet NSPanel*				noiseFloorPanel;
		IBOutlet NSTextField*			noiseFloorOffsetField;
		IBOutlet NSTextField*			noiseFloorStateField;
		IBOutlet NSButton*				startNoiseFloorButton;
		IBOutlet NSProgressIndicator*	noiseFloorProgress;
		IBOutlet NSTextField*			noiseFloorStateField2;
		
};
#pragma mark ‚Ä¢‚Ä¢‚Ä¢Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Notifications
- (void) registerNotificationObservers;
- (void) updateButtons;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Interface Management
- (void) writeToBBModeChanged:(NSNotification*)aNote;
- (void) wCmdArg2Changed:(NSNotification*)aNote;
- (void) wCmdArg1Changed:(NSNotification*)aNote;
- (void) wCmdCodeChanged:(NSNotification*)aNote;
- (void) adcRtChanged:(NSNotification*)aNote;
- (void) dacbChanged:(NSNotification*)aNote;
- (void) signbChanged:(NSNotification*)aNote;
- (void) dacaChanged:(NSNotification*)aNote;
- (void) signaChanged:(NSNotification*)aNote;
- (void) statusBitsBBDataChanged:(NSNotification*)aNote;
- (void) adcRgForBBAccessChanged:(NSNotification*)aNote;
- (void) adcValueForBBAccessChanged:(NSNotification*)aNote;
- (void) adcMultForBBAccessChanged:(NSNotification*)aNote;
- (void) adcFreqkHzForBBAccessChanged:(NSNotification*)aNote;
- (void) useBroadcastIdforBBAccessChanged:(NSNotification*)aNote;
- (void) idBBforBBAccessChanged:(NSNotification*)aNote;
- (void) fiberSelectForBBAccessChanged:(NSNotification*)aNote;
- (void) relaisStatesBBChanged:(NSNotification*)aNote;
- (void) fiberSelectForBBStatusBitsChanged:(NSNotification*)aNote;
- (void) fiberOutMaskChanged:(NSNotification*)aNote;
- (void) swTriggerIsRepeatingChanged:(NSNotification*)aNote;
- (void) repeatSWTriggerModeChanged:(NSNotification*)aNote;
- (void) controlRegisterChanged:(NSNotification*)aNote;
- (void) totalTriggerNRegisterChanged:(NSNotification*)aNote;
- (void) statusRegisterChanged:(NSNotification*)aNote;
- (void) fastWriteChanged:(NSNotification*)aNote;
- (void) fiberDelaysChanged:(NSNotification*)aNote;
- (void) streamMaskChanged:(NSNotification*)aNote;
- (void) selectFiberTrigChanged:(NSNotification*)aNote;
- (void) BBv1MaskChanged:(NSNotification*)aNote;
- (void) fiberEnableMaskChanged:(NSNotification*)aNote;
- (void) fltModeFlagsChanged:(NSNotification*)aNote;
- (void) tpixChanged:(NSNotification*)aNote;
- (void) targetRateChanged:(NSNotification*)aNote;
- (void) noiseFloorChanged:(NSNotification*)aNote;
- (void) noiseFloorOffsetChanged:(NSNotification*)aNote;
- (void) storeDataInRamChanged:(NSNotification*)aNote;
- (void) filterLengthChanged:(NSNotification*)aNote;
- (void) gapLengthChanged:(NSNotification*)aNote;
- (void) postTriggerTimeChanged:(NSNotification*)aNote;
- (void) fifoBehaviourChanged:(NSNotification*)aNote;

- (void) interruptMaskChanged:(NSNotification*)aNote;
- (void) populatePullDown;
- (void) updateWindow;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) enableRegControls;
- (void) slotChanged:(NSNotification*)aNote;
- (void) modeChanged:(NSNotification*)aNote;
- (void) gainChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) gainArrayChanged:(NSNotification*)aNote;
- (void) thresholdArrayChanged:(NSNotification*)aNote;
- (void) triggersEnabledArrayChanged:(NSNotification*)aNote;
- (void) triggerEnabledChanged:(NSNotification*)aNote;

- (void) hitRateLengthChanged:(NSNotification*)aNote;
- (void) hitRateChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) testStatusArrayChanged:(NSNotification*)aNote;
- (void) testEnabledArrayChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) selectedRegIndexChanged:(NSNotification*) aNote;
- (void) writeValueChanged:(NSNotification*) aNote;
- (void) selectedChannelValueChanged:(NSNotification*) aNote;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Actions
- (IBAction) writeToBBModeCBAction:(id)sender;
- (IBAction) wCmdArg2TextFieldAction:(id)sender;
- (IBAction) wCmdArg1TextFieldAction:(id)sender;
- (IBAction) wCmdCodeTextFieldAction:(id)sender;
- (IBAction) sendWCommandButtonAction:(id)sender;

- (IBAction) adcRtTextFieldAction:(id)sender;

- (IBAction) dacbMatrixAction:(id)sender;
- (IBAction) signbMatrixAction:(id)sender;
- (IBAction) dacaMatrixAction:(id)sender;
- (IBAction) signaMatrixAction:(id)sender;
- (IBAction) readBBStatusBBAccessButtonAction:(id)sender;
- (IBAction) dumpBBStatusBBAccessTextFieldAction:(id)sender;
- (IBAction) adcRgForBBAccessMatrixAction:(id)sender;
- (IBAction) adcValueForBBAccessMatrixAction:(id)sender;
- (IBAction) adcMultForBBAccessMatrixAction:(id)sender;


- (IBAction) adcFreqkHzForBBAccessMatrixAction:(id)sender;
- (IBAction) useBroadcastIdforBBAccessCBAction:(id)sender;
- (IBAction) idBBforBBAccessTextFieldAction:(id)sender;
- (IBAction) fiberSelectForBBAccessPUAction:(id)sender;
- (IBAction) relaisStatesBBMatrixAction:(id)sender;
- (IBAction) fiberSelectForBBStatusBitsPUAction:(id)sender;
- (IBAction) readBBStatusBitsButtonAction:(id)sender;
- (IBAction) readAllBBStatusBitsButtonAction:(id)sender;
- (IBAction) fiberOutMaskMatrixAction:(id)sender;
- (IBAction) readFiberOutMaskButtonAction:(id)sender;
- (IBAction) writeFiberOutMaskButtonAction:(id)sender;
- (IBAction) tpixCBAction:(id)sender;
- (IBAction) repeatSWTriggerModePUAction:(id)sender;
- (IBAction) repeatSWTriggerModeTextFieldAction:(id)sender;
- (IBAction) controlRegisterTextFieldAction:(id)sender;
- (IBAction) writeControlRegisterButtonAction:(id)sender;
- (IBAction) readControlRegisterButtonAction:(id)sender;

- (IBAction) statusLatencyPUAction:(id)sender;
- (IBAction) vetoFlagCBAction:(id)sender;

- (IBAction) totalTriggerNRegisterTextFieldAction:(id)sender;
- (void) readStatusButtonAction:(id)sender;
- (IBAction) statusRegisterTextFieldAction:(id)sender;
- (IBAction) fastWriteCBAction:(id)sender;
- (void) writeFiberDelaysButtonAction:(id)sender;
- (void) readFiberDelaysButtonAction:(id)sender;
- (IBAction) fiberDelaysTextFieldAction:(id)sender;
- (IBAction) fiberDelaysMatrixAction:(id)sender;
- (IBAction) streamMaskEnableAllAction:(id)sender;
- (IBAction) streamMaskEnableNoneAction:(id)sender;
- (IBAction) streamMaskTextFieldAction:(id)sender;
- (IBAction) streamMaskMatrixAction:(id)sender;
- (IBAction) writeStreamMaskRegisterButtonAction:(id)sender;
- (IBAction) readStreamMaskRegisterButtonAction:(id)sender;
- (IBAction) selectFiberTrigPUAction:(id)sender;
- (IBAction) BBv1MaskMatrixAction:(id)sender;
- (IBAction) fiberEnableMaskMatrixAction:(id)sender;
- (IBAction) fltModeFlagsPUAction:(id)sender;

- (IBAction) writeCommandResyncAction:(id)sender;
- (IBAction) writeCommandTrigEvCounterResetAction:(id)sender;
- (IBAction) writeSWTriggerAction:(id)sender;
- (IBAction) readTriggerDataAction:(id)sender;

- (IBAction) targetRateAction:(id)sender;

- (IBAction) storeDataInRamAction:(id)sender;
- (IBAction) filterLengthAction:(id)sender;
- (IBAction) gapLengthAction:(id)sender;

- (IBAction) postTriggerTimeAction:(id)sender;
- (IBAction) fifoBehaviourAction:(id)sender;
- (IBAction) analogOffsetAction:(id)sender;
- (IBAction) interruptMaskAction:(id)sender;
- (IBAction) initBoardButtonAction:(id)sender;
- (IBAction) reportButtonAction:(id)sender;
- (IBAction) gainAction:(id)sender;
- (IBAction) triggerEnableAction:(id)sender;

- (IBAction) thresholdAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) modeAction: (id) sender;
- (IBAction) versionAction: (id) sender;
- (IBAction) testAction: (id) sender;
- (IBAction) resetAction: (id) sender;
- (IBAction) hitRateLengthAction: (id) sender;
- (IBAction) hitRateAllAction: (id) sender;
- (IBAction) hitRateNoneAction: (id) sender;
- (IBAction) testEnabledAction:(id)sender;
- (IBAction) statusAction:(id)sender;
- (IBAction) enableAllTriggersAction: (id) sender;
- (IBAction) enableNoTriggersAction: (id) sender;
- (IBAction) readThresholdsGains:(id)sender;
- (IBAction) writeThresholdsGains:(id)sender;
- (IBAction) selectRegisterAction:(id) aSender;
- (IBAction) selectChannelAction:(id) aSender;
- (IBAction) writeValueAction:(id) aSender;
- (IBAction) readRegAction: (id) sender;
- (IBAction) writeRegAction: (id) sender;
- (IBAction) setDefaultsAction: (id) sender;
- (IBAction) openNoiseFloorPanel:(id)sender;
- (IBAction) closeNoiseFloorPanel:(id)sender;
- (IBAction) findNoiseFloors:(id)sender;
- (IBAction) noiseFloorOffsetAction:(id)sender;

- (IBAction) testButtonAction: (id) sender; //temp routine to hook up to any on a temp basis

	
#pragma mark ‚Ä¢‚Ä¢‚Ä¢Plot DataSource
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end