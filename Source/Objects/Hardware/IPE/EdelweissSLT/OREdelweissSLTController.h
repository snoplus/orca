
//
//  OREdelweissSLTController.h
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
#import "OREdelweissSLTModel.h"
#import "SBC_LinkController.h"

@interface OREdelweissSLTController : SBC_LinkController {
	@private
	
	    //udp connection
		//listener (server)
	    IBOutlet NSTextField*   crateUDPReplyPortTextField;
		IBOutlet NSButton*		startListeningForReplyButton;
		IBOutlet NSButton*		stopListeningForReplyButton;
	    IBOutlet NSProgressIndicator*   listeningForReplyIndicator;
		//command sender (client)
		IBOutlet NSButton*		openCommandSocketButton;
		IBOutlet NSButton*		closeCommandSocketButton;
	    IBOutlet   NSTextField* crateUDPCommandTextField;
	    IBOutlet NSTextField*   crateUDPCommandIPTextField;
	    IBOutlet NSTextField*   crateUDPCommandPortTextField;
		
		IBOutlet NSTextField*	hwVersionField;
		IBOutlet NSTextField*	sltScriptArgumentsTextField;
		IBOutlet NSMatrix*		countersMatrix;
		IBOutlet NSTextField*	secondsSetField;
		IBOutlet NSButton*		secondsSetInitWithHostButton;
		IBOutlet NSButton*		hwVersionButton;
	
		//control reg
		IBOutlet NSMatrix*		triggerEnableMatrix;
		IBOutlet NSMatrix*		inhibitEnableMatrix;
		IBOutlet NSMatrix*		testPatternEnableMatrix;
		IBOutlet NSMatrix*		miscCntrlBitsMatrix;
		IBOutlet NSMatrix*		enableDisableCountersMatrix;
	
		IBOutlet NSButton*		initBoardButton;
		IBOutlet NSButton*		initBoard1Button;
		IBOutlet NSButton*		readBoardButton;
		IBOutlet NSMatrix*		interruptMaskMatrix;
		IBOutlet NSPopUpButton* secStrobeSrcPU;
		IBOutlet NSTextField*   pageSizeField;
		IBOutlet NSStepper*     pageSizeStepper;
		IBOutlet NSButton*      displayTriggerButton;
		IBOutlet NSButton*      displayEventLoopButton;
		
		//status reg
		IBOutlet NSMatrix*		statusMatrix;
		IBOutlet NSButton*		resetPageManagerButton;
        
        //low level
		IBOutlet NSPopUpButton*	registerPopUp;
		IBOutlet NSStepper* 	regWriteValueStepper;
		IBOutlet NSTextField* 	regWriteValueTextField;
		IBOutlet NSButton*		regWriteButton;
		IBOutlet NSButton*		regReadButton;
		IBOutlet NSButton*		setSWInhibitButton;
		IBOutlet NSButton*		relSWInhibitButton;
		IBOutlet NSButton*		forceTriggerButton;
		IBOutlet NSButton*		setSWInhibit1Button;
		IBOutlet NSButton*		relSWInhibit1Button;
		IBOutlet NSButton*		forceTrigger1Button;

		IBOutlet NSButton*		resetHWButton;
		IBOutlet NSButton*		definePatternFileButton;
		IBOutlet NSTextField*	patternFilePathField;
		IBOutlet NSButton*		loadPatternFileButton;

		IBOutlet NSSlider*		nextPageDelaySlider;
		IBOutlet NSTextField*	nextPageDelayField;
		
		//pulser
		IBOutlet NSTextField*	pulserAmpField;
		IBOutlet NSTextField*	pulserDelayField;


        IBOutlet NSPopUpButton*	pollRatePopup;
        IBOutlet NSProgressIndicator*	pollRunningIndicator;
				
		NSImage* xImage;
		NSImage* yImage;

		NSSize					controlSize;
		NSSize					statusSize;
		NSSize					lowLevelSize;
		NSSize					cpuManagementSize;
		NSSize					cpuTestsSize;
		NSSize					udpSize;
};

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Notifications
- (void) registerNotificationObservers;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Interface Management
- (void) isListeningOnServerSocketChanged:(NSNotification*)aNote;
- (void) crateUDPCommandChanged:(NSNotification*)aNote;
- (void) crateUDPCommandIPChanged:(NSNotification*)aNote;
- (void) crateUDPCommandPortChanged:(NSNotification*)aNote;
- (void) crateUDPReplyPortChanged:(NSNotification*)aNote;
- (void) secondsSetInitWithHostChanged:(NSNotification*)aNote;
- (void) sltScriptArgumentsChanged:(NSNotification*)aNote;
- (void) countersEnabledChanged:(NSNotification*)aNote;
- (void) clockTimeChanged:(NSNotification*)aNote;
- (void) runTimeChanged:(NSNotification*)aNote;
- (void) vetoTimeChanged:(NSNotification*)aNote;
- (void) deadTimeChanged:(NSNotification*)aNote;
- (void) secondsSetChanged:(NSNotification*)aNote;
- (void) statusRegChanged:(NSNotification*)aNote;
- (void) controlRegChanged:(NSNotification*)aNote;
- (void) hwVersionChanged:(NSNotification*) aNote;

- (void) patternFilePathChanged:(NSNotification*)aNote;
- (void) interruptMaskChanged:(NSNotification*)aNote;
- (void) nextPageDelayChanged:(NSNotification*)aNote;
- (void) pageSizeChanged:(NSNotification*)aNote;
- (void) displayEventLoopChanged:(NSNotification*)aNote;
- (void) displayTriggerChanged:(NSNotification*)aNote;
- (void) populatePullDown;
- (void) updateWindow;
- (void) checkGlobalSecurity;
- (void) settingsLockChanged:(NSNotification*)aNote;

- (void) endAllEditing:(NSNotification*)aNote;
- (void) controlRegChanged:(NSNotification*)aNote;
- (void) selectedRegIndexChanged:(NSNotification*) aNote;
- (void) writeValueChanged:(NSNotification*) aNote;

- (void) pulserAmpChanged:(NSNotification*) aNote;
- (void) pulserDelayChanged:(NSNotification*) aNote;
- (void) pollRateChanged:(NSNotification*)aNote;
- (void) pollRunningChanged:(NSNotification*)aNote;

- (void) enableRegControls;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Actions
- (IBAction) startListeningForReplyButtonAction:(id)sender;
- (IBAction) stopListeningForReplyButtonAction:(id)sender;
- (IBAction) crateUDPReplyPortTextFieldAction:(id)sender;

- (IBAction) crateUDPCommandTextFieldAction:(id)sender;
- (IBAction) crateUDPCommandIPTextFieldAction:(id)sender;
- (IBAction) crateUDPCommandPortTextFieldAction:(id)sender;
- (IBAction) openCommandSocketButtonAction:(id)sender;
- (IBAction) closeCommandSocketButtonAction:(id)sender;

- (IBAction) secondsSetInitWithHostButtonAction:(id)sender;
- (IBAction) sltScriptArgumentsTextFieldAction:(id)sender;
- (IBAction) enableDisableCounterAction:(id)sender;
- (IBAction) secondsSetAction:(id)sender;
- (IBAction) triggerEnableAction:(id)sender;
- (IBAction) inhibitEnableAction:(id)sender;
- (IBAction) testPatternEnableAction:(id)sender;
- (IBAction) miscCntrlBitsAction:(id)sender;
- (IBAction) hwVersionAction: (id) sender;
- (IBAction) writeSWTrigAction:(id)sender;
- (IBAction) resetPageManagerAction:(id)sender;

- (IBAction) dumpPageStatus:(id)sender;
- (IBAction) pollRateAction:(id)sender;
- (IBAction) pollNowAction:(id)sender;
- (IBAction) readStatus:(id)sender;
- (IBAction) nextPageDelayAction:(id)sender;
- (IBAction) interruptMaskAction:(id)sender;
- (IBAction) pageSizeAction:(id)sender;
- (IBAction) displayTriggerAction:(id)sender;
- (IBAction) displayEventLoopAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) selectRegisterAction:(id) sender;
- (IBAction) writeValueAction:(id) sender;
- (IBAction) readRegAction: (id) sender;
- (IBAction) writeRegAction: (id) sender;
- (IBAction) pulserAmpAction: (id) sender;
- (IBAction) pulserDelayAction: (id) sender;
- (IBAction) loadPulserAction: (id) sender;
- (IBAction) initBoardAction:(id)sender;
- (IBAction) reportAllAction:(id)sender;
- (IBAction) definePatternFileAction:(id)sender;
- (IBAction) loadPatternFile:(id)sender;
- (IBAction) calibrateAction:(id)sender;


- (IBAction) enableCountersAction:(id)sender;
- (IBAction) disableCountersAction:(id)sender;
- (IBAction) clearCountersAction:(id)sender;
- (IBAction) activateSWRequestAction:(id)sender;
- (IBAction) configureFPGAsAction:(id)sender;
- (IBAction) tpStartAction:(id)sender;
- (IBAction) resetFLTAction:(id)sender;
- (IBAction) resetSLTAction:(id)sender;
- (IBAction) writeSWTrigAction:(id)sender;
- (IBAction) writeClrInhibitAction:(id)sender;
- (IBAction) writeSetInhibitAction:(id)sender;
- (IBAction) resetPageManagerAction:(id)sender;
- (IBAction) resetPageManagerAction:(id)sender;

- (IBAction) sendCommandScript:(id)sender;
- (IBAction) sendSimulationConfigScriptON:(id)sender;
- (IBAction) sendSimulationConfigScriptOFF:(id)sender;
- (void) _SLTv4killCrateAndStartSimDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;

@end