
//
//  ORKatrinFLTController.h
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


#pragma mark ¥¥¥Imported Files
#import "ORKatrinFLTModel.h"

@class ORPlotter1D;
@class ORValueBar;

@interface ORKatrinFLTController : OrcaObjectController {
	@private
        IBOutlet NSButton*		settingLockButton; 
		IBOutlet NSButton*		checkWaveFormEnabledButton;
		IBOutlet NSPopUpButton*	daqRunModeButton;//!<The tag needs to be equal to the daq run mode. See ORKatrinFLTModel.h for values.
		IBOutlet NSButton*		versionButton;
		IBOutlet NSButton*		statusButton;
		IBOutlet NSButton*		readFltModeButton;
		IBOutlet NSTextField*   fltModeField;
		IBOutlet NSButton*		writeFltModeButton;
		IBOutlet NSButton*		resetButton;
		IBOutlet NSButton*		triggerButton; // ak, 3.7.07		
		IBOutlet NSMatrix*		gainTextFields;
		IBOutlet NSMatrix*		thresholdTextFields;
		IBOutlet NSMatrix*		triggerEnabledCBs;
		IBOutlet NSMatrix*		hitRateEnabledCBs;
		IBOutlet NSButton*		readThresholdsGainsButton;
		IBOutlet NSButton*		writeThresholdsGainsButton;
		IBOutlet NSButton*		loadTimeButton;
		IBOutlet NSButton*		readTimeButton;
		IBOutlet NSPopUpButton* shapingTimePU0;
		IBOutlet NSPopUpButton* shapingTimePU1;
		IBOutlet NSPopUpButton* shapingTimePU2;
		IBOutlet NSPopUpButton* shapingTimePU3;
		IBOutlet NSTextField*	hitRateLengthField;
		IBOutlet NSButton*		hitRateAllButton;
		IBOutlet NSButton*		hitRateNoneButton;
        IBOutlet NSButton*		broadcastTimeCB;
		
		IBOutlet NSTextField*	readoutPagesField; // ak, 2.7.07
        
        //histogram page
        IBOutlet NSButton*		helloButton; // -tb- 2008/1/17
        IBOutlet NSTextField*	eMinField;
        IBOutlet NSTextField*	eMaxField;
        //EMax buttons missing
        IBOutlet NSTextField*	tRunField;
        IBOutlet NSTextField*	tRecField;
        // TRun buttons missing
        IBOutlet NSTextField*	firstBinField;
        IBOutlet NSTextField*	lastBinField;
        IBOutlet ORPlotter1D*      histogramPlotterId;
        IBOutlet NSButton*		vetoEnableButton;
        IBOutlet NSPopUpButton* eSamplePopUpButton;////eSample=BW TODO: rename to binWidth -tb-
        IBOutlet NSProgressIndicator* histoProgressIndicator;
        IBOutlet NSTextField*	histoElapsedTimeField;
        IBOutlet NSPopUpButton* histoCalibrationChanNumPopUpButton;////eSample=BW TODO: rename to binWidth -tb-
        

		//rate page
		IBOutlet NSMatrix*		rateTextFields;
		
		IBOutlet ORValueBar*	rate0;
		IBOutlet ORValueBar*	totalRate;
		IBOutlet NSButton*		rateLogCB;
		IBOutlet ORPlotter1D*	timeRatePlot;
		IBOutlet NSButton*		timeRateLogCB;
		IBOutlet NSButton*		totalRateLogCB;
		IBOutlet NSTextField*	totalHitRateField;
		IBOutlet NSTabView*		tabView;	
		IBOutlet NSView*		totalView;

		//test page
		IBOutlet NSButton*		testButton;
		IBOutlet NSMatrix*		testEnabledMatrix;
		IBOutlet NSMatrix*		testStatusMatrix;
		IBOutlet NSMatrix*		testParamsMatrix;
		IBOutlet NSTableView*	patternTable;
		IBOutlet NSMatrix*		tModeMatrix;
		IBOutlet NSButton*		initTPButton;
		IBOutlet NSTextField*	numTestPatternsField;
		IBOutlet NSStepper*		numTestPatternsStepper;

		
		NSNumberFormatter*		rateFormatter;
		NSSize					settingSize;
		NSSize					histogramSize;
		NSSize					rateSize;
		NSSize					testSize;
		NSView*					blankView;
		
};
#pragma mark ¥¥¥Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) checkWaveFormEnabledChanged:(NSNotification*)aNote;
- (void) updateWindow;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) numTestPattersChanged:(NSNotification*)aNote;
- (void) fltRunModeChanged:(NSNotification*)aNote;
- (void) daqRunModeChanged:(NSNotification*)aNote;
- (void) gainChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) gainArrayChanged:(NSNotification*)aNote;
- (void) thresholdArrayChanged:(NSNotification*)aNote;
- (void) triggersEnabledArrayChanged:(NSNotification*)aNote;
- (void) triggerEnabledChanged:(NSNotification*)aNote;
- (void) hitRatesEnabledArrayChanged:(NSNotification*)aNote;
- (void) hitRateEnabledChanged:(NSNotification*)aNote;
- (void) shapingTimesArrayChanged:(NSNotification*)aNote;
- (void) shapingTimeChanged:(NSNotification*)aNote;
- (void) hitRateLengthChanged:(NSNotification*)aNote;
- (void) hitRateChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) broadcastTimeChanged:(NSNotification*)aNote;
- (void) testStatusArrayChanged:(NSNotification*)aNote;
- (void) testEnabledArrayChanged:(NSNotification*)aNote;
- (void) testParamChanged:(NSNotification*)aNote;
- (void) patternChanged:(NSNotification*) aNote;
- (void) tModeChanged:(NSNotification*) aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) readoutPagesChanged:(NSNotification*)aNote;
//from here: hardware histogramming -tb- 2008-02-08
- (void) histoBinWidthChanged:(NSNotification*)aNote;
- (void) histoMinEnergyChanged:(NSNotification*)aNote;
- (void) histoMaxEnergyChanged:(NSNotification*)aNote;
- (void) histoFirstBinChanged:(NSNotification*)aNote;
- (void) histoLastBinChanged:(NSNotification*)aNote;
- (void) histoRunTimeChanged:(NSNotification*)aNote;
- (void) histoRecordingTimeChanged:(NSNotification*)aNote;
- (void) histoTestValuesChanged:(NSNotification*)aNote;
- (void) histoCalibrationChanChanged:(NSNotification*)aNote;

    
    
    
    
    


#pragma mark ¥¥¥Actions
- (IBAction) checkWaveFormEnabledAction:(id)sender;
- (IBAction) numTestPatternsAction:(id)sender;
- (IBAction) readThresholdsGains:(id)sender;
- (IBAction) writeThresholdsGains:(id)sender;
- (IBAction) gainAction:(id)sender;
- (IBAction) triggerEnableAction:(id)sender;
- (IBAction) hitRateEnableAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) readFltModeButtonAction:(id)sender;
- (IBAction) writeFltModeButtonAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) daqRunModeAction: (id) sender;
- (IBAction) versionAction: (id) sender;
- (IBAction) testAction: (id) sender;
- (IBAction) resetAction: (id) sender;
- (IBAction) triggerAction: (id) sender; 
- (IBAction) loadTimeAction: (id) sender;
- (IBAction) readTimeAction: (id) sender;
- (IBAction) shapingTimeAction: (id) sender;
- (IBAction) hitRateLengthAction: (id) sender;
- (IBAction) hitRateAllAction: (id) sender;
- (IBAction) hitRateNoneAction: (id) sender;
- (IBAction) broadcastTimeAction: (id) sender;
- (IBAction) testEnabledAction:(id)sender;
- (IBAction) testParamAction:(id)sender;
- (IBAction) statusAction:(id)sender;
- (IBAction) tModeAction: (id) sender;
- (IBAction) initTPAction: (id) sender;
- (IBAction) readoutPagesAction: (id) sender; // ak 2.7.07
- (IBAction) helloButtonAction:(id)sender;//from here: hardware histogramming -tb- 2008-1-17
- (IBAction) readEMinButtonAction:(id)sender;
- (IBAction) writeEMinButtonAction:(id)sender;
- (IBAction) readEMaxButtonAction:(id)sender;
- (IBAction) writeEMaxButtonAction:(id)sender;
- (IBAction) readTRecButtonAction:(id)sender;
- (IBAction) readTRunAction:(id)sender;
- (IBAction) writeTRunAction:(id)sender;
- (IBAction) readFirstBinButtonAction:(id)sender;
- (IBAction) readLastBinButtonAction:(id)sender;
- (IBAction) changedBinWidthPopupButtonAction:(id)sender;//TODO: rename -tb-
- (IBAction) changedHistoMinEnergyAction:(id)sender;
- (IBAction) changedHistoMaxEnergyAction:(id)sender;
- (IBAction) changedHistoFirstBinAction:(id)sender;
- (IBAction) changedHistoLastBinAction:(id)sender;
- (IBAction) changedHistoRunTimeAction:(id)sender;
- (IBAction) changedHistoRecordingTimeAction:(id)sender;

- (IBAction) startHistogramButtonAction:(id)sender;
- (IBAction) stopHistogramButtonAction:(id)sender;
- (IBAction) readHistogramDataButtonAction:(id)sender;
- (IBAction) readCurrentStatusButtonAction:(id)sender;
- (IBAction) changedHistoCalibrationChanPopupButtonAction:(id)sender;

- (IBAction) vetoTestButtonAction:(id)sender;
- (IBAction) readVetoStateButtonAction:(id)sender;
- (IBAction) readEnableVetoButtonAction:(id)sender;
- (IBAction) writeEnableVetoButtonAction:(id)sender;
- (IBAction) readVetoDataButtonAction:(id)sender;





#pragma mark ¥¥¥Plot DataSource
- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x ;
- (unsigned long)  	secondsPerUnit:(id) aPlotter;

@end