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
#import "StopLightView.h"
#import "RunStatusIcon.h"
#include <stdint.h>
#import <WebKit/WebKit.h>

@class ORColorScale;
@class ORSegmentGroup;

@interface SNOPController : ORExperimentController {
    IBOutlet NSView *snopView;
    
    NSView *blankView;
    NSSize detectorSize;
	NSSize detailsSize;
	NSSize focalPlaneSize;
	NSSize couchDBSize;
	NSSize hvMasterSize;
	NSSize runsSize;
    
    IBOutlet NSMatrix* hvStatusMatrix;
    
    //Run control (the rest is in the ORExperimentController)
    IBOutlet StopLightView *lightBoardView;

    //Quick links
    
    //Danger zone
    IBOutlet NSButton *panicDownButton;
    IBOutlet NSTextField *detectorHVStatus;
    
    //Standard Runs
    IBOutlet NSComboBox *standardRunPopupMenu;
    IBOutlet NSComboBox *standardRunVersionPopupMenu;
    IBOutlet NSButton *standardRunLoadButton;
    IBOutlet NSButton *standardRunSaveButton;
    IBOutlet NSMatrix *standardRunThresCurrentValues;
    IBOutlet NSMatrix *standardRunThresStoredValues;

    //Run Types Information
    IBOutlet NSMatrix*  runTypeWordMatrix;
    IBOutlet NSMatrix *runTypeWordSRMatrix;

    //Xl3 Mode
    IBOutlet NSMatrix * globalxl3Mode;
    IBOutlet NSMatrix *panicDownCrateButton;
    
    //smellie buttons ---------
    IBOutlet NSComboBox *smellieRunFileNameField;
    IBOutlet NSTextField *loadedSmellieRunNameLabel;
    IBOutlet NSTextField *loadedSmellieTriggerFrequencyLabel;
    IBOutlet NSTextField *loadedSmellieApproxTimeLabel;
    IBOutlet NSTextField *loadedSmellieLasersLabel;
    IBOutlet NSTextField *loadedSmellieFibresLabel;
    IBOutlet NSTextField *loadedSmellieOperationModeLabel;
    IBOutlet NSTextField *loadedSmellieMaxIntensityLaser;
    IBOutlet NSTextField *loadedSmellieMinIntensityLaser;
    
    //SMELLIE
    NSMutableDictionary *smellieRunFileList;
    NSDictionary *smellieRunFile;
    NSThread *smellieThread;
    IBOutlet NSButton *smellieLoadRunFile;
    IBOutlet NSButton *smellieCheckInterlock;
    IBOutlet NSButton *smellieStartRunButton;
    IBOutlet NSButton *smellieStopRunButton;
    IBOutlet NSButton *smellieEmergencyStop;
    IBOutlet NSButton *smellieBuildCustomRun;
    IBOutlet NSButton *smellieChangeConfiguration;

    IBOutlet NSButton* runsLockButton;
    IBOutlet NSTextField *lockStatusTextField;

    //ECA RUNS
    IBOutlet NSPopUpButton *ECApatternPopUpButton;
    IBOutlet NSPopUpButton *ECAtypePopUpButton;
    IBOutlet NSTextField *TSlopePatternTextField;
    IBOutlet NSTextField *ecaNEventsTextField;
    IBOutlet NSTextField *ecaPulserRate;
    IBOutlet NSButton *startSingleECAButton;

    NSButton *refreshRunWordNames;
    
    //Server settings
    IBOutlet NSComboBox *orcaDBIPAddressPU;
    IBOutlet NSComboBox *debugDBIPAddressPU;
    IBOutlet NSTextField *mtcPort;
    IBOutlet NSTextField *mtcHost;
    IBOutlet NSTextField *xl3Port;
    IBOutlet NSTextField *xl3Host;
    IBOutlet NSTextField *dataPort;
    IBOutlet NSTextField *dataHost;
    IBOutlet NSTextField *logPort;
    IBOutlet NSTextField *logHost;
    IBOutlet NSTextField *orcaDBUser;
    IBOutlet NSTextField *orcaDBPswd;
    IBOutlet NSTextField *orcaDBName;
    IBOutlet NSTextField *orcaDBPort;
    IBOutlet NSButton *orcaDBClearButton;
    IBOutlet NSTextField *debugDBUser;
    IBOutlet NSTextField *debugDBPswd;
    IBOutlet NSTextField *debugDBName;
    IBOutlet NSTextField *debugDBPort;
    IBOutlet NSButton *debugDBClearButton;

    //Custom colors
    NSColor *snopRedColor;
    NSColor *snopBlueColor;
    NSColor *snopGreenColor;
    NSColor *snopOrangeColor;
    NSColor *snopBlackColor;
    NSColor *snopGrayColor;

    /* Mask of which HV supplies are on. Power supply B on crate 16 is bit 19 */
    uint32_t hvMask;

    RunStatusIcon* doggy_icon;

    // Detector State
    IBOutlet WebView* detectorState;
}

@property (nonatomic,retain) NSMutableDictionary *smellieRunFileList;
@property (nonatomic,retain) NSDictionary *smellieRunFile;
@property (nonatomic,retain) NSColor *snopRedColor;
@property (nonatomic,retain) NSColor *snopBlueColor;
@property (nonatomic,retain) NSColor *snopGreenColor;
@property (nonatomic,retain) NSColor *snopOrangeColor;
@property (nonatomic,retain) NSColor *snopBlackColor;
@property (nonatomic,retain) NSColor *snopGrayColor;

#pragma mark ¥¥¥Initialization
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ¥¥¥Interface
- (void) hvStatusChanged:(NSNotification*)aNote;
- (void) dbOrcaDBIPChanged:(NSNotification*)aNote;
- (void) dbDebugDBIPChanged:(NSNotification*)aNote;

- (IBAction) testMTCServer:(id)sender;
- (IBAction) testXL3Server:(id)sender;
- (IBAction) testDataServer:(id)sender;
- (IBAction) testLogServer:(id)sender;

- (void) updateSettings: (NSNotification *) aNote;

#pragma mark ¥¥¥Actions

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

//smellie functions -------------------
- (IBAction) loadSmellieRunAction:(id)sender;
- (IBAction) callSmellieSettings:(id)sender;
- (IBAction) startSmellieRunAction:(id)sender;
- (IBAction) stopSmellieRunAction:(id)sender;
- (IBAction) emergencySmellieStopAction:(id)sender;

//xl3 mode status
- (IBAction)updatexl3Mode:(id)sender;

#pragma mark ¥¥¥Details Interface Management
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem;
-(void) windowDidLoad;

- (IBAction) runsLockAction:(id)sender;

//Run type
- (IBAction) refreshRunWordLabels:(id)sender;
- (IBAction) runTypeWordAction:(id)sender;
@end

extern NSString* ORSNOPRequestHVStatus;
