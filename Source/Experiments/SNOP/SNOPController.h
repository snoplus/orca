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
#import "SNOPDetectorView.h"
#import "StopLightView.h"

@class ORColorScale;
@class ORSegmentGroup;

@interface SNOPController : ORExperimentController {
	IBOutlet NSTextField* detectorTitle;
	IBOutlet NSPopUpButton*	viewTypePU;
    IBOutlet NSView *snopView;
    
    NSView *blankView;
    NSSize detectorSize;
	NSSize detailsSize;
	NSSize focalPlaneSize;
	NSSize couchDBSize;
	NSSize hvMasterSize;
	NSSize runsSize;
    
    IBOutlet NSComboBox *orcaDBIPAddressPU;
    IBOutlet NSComboBox *debugDBIPAddressPU;
    IBOutlet NSMatrix* hvStatusMatrix;
    
    //Run control (the rest is in the ORExperimentController)
    IBOutlet NSButton *maintenanceRunBox;
    IBOutlet NSTextField* standardRunTypeField;
    IBOutlet StopLightView *lightBoardView;

    //Quick links
    
    //Danger zone
    IBOutlet NSButton *panicDownButton;
    IBOutlet NSTextField *detectorHVStatus;
    
    //Standard Runs
    IBOutlet NSComboBox *standardRunPopupMenu;
    IBOutlet NSComboBox *standardRunVersionPopupMenu;
    IBOutlet NSButton *standardRunLoadButton;
    IBOutlet NSButton *standardRunLoadDefaultsButton;
    IBOutlet NSButton *standardRunSaveButton;
    IBOutlet NSButton *standardRunSaveDefaultsButton;
    IBOutlet NSMatrix *standardRunThresNewValues;
    IBOutlet NSMatrix *standardRunThresStoredValues;
    IBOutlet NSMatrix *standardRunThresDefaultValues;

    
    //Run Types Information
    IBOutlet NSMatrix*  globalRunTypesMatrix;
    
    //Xl3 Mode
    IBOutlet NSMatrix * globalxl3Mode;
    
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
    
    IBOutlet NSButton *smellieLoadRunFile;
    IBOutlet NSButton *smellieCheckInterlock;
    IBOutlet NSButton *smellieStartRunButton;
    IBOutlet NSButton *smellieStopRunButton;
    IBOutlet NSButton *smellieEmergencyStop;
    IBOutlet NSButton *smellieBuildCustomRun;
    IBOutlet NSButton *smellieChangeConfiguration;
        
    //eStop buttons
    IBOutlet NSButton *emergyencyStopEnabled;
    IBOutlet NSButton *eStopButton;
    
    IBOutlet NSTextField *pollingStatus;
    
    
    NSImage* _runStopImg;
    NSMutableDictionary *smellieRunFileList;
    NSDictionary *smellieRunFile;
    NSThread *smellieThread;
    NSNumber * runTypeMask;
    NSThread *eStopPollingThread;
    
    NSMutableDictionary *snopRunTypeMaskDic; 

    IBOutlet NSButton* runsLockButton;
    IBOutlet NSTextField *runStatusTextField;

    //ECA RUNS
    IBOutlet NSPopUpButton *ECApatternPopUpButton;
    IBOutlet NSPopUpButton *ECAtypePopUpButton;
    IBOutlet NSTextField *TSlopePatternTextField;
    IBOutlet NSTextField *subTimeTextField;
    
}

@property (nonatomic,retain) NSImage* runStopImg;
@property (nonatomic,retain) NSMutableDictionary *smellieRunFileList;
@property (nonatomic,retain) NSMutableDictionary *snopRunTypeMaskDic;
@property (nonatomic,retain) NSDictionary *smellieRunFile;
@property (nonatomic,retain) NSNumber *runTypeMask;

#pragma mark ¥¥¥Initialization
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ¥¥¥Interface
- (void) hvStatusChanged:(NSNotification*)aNote;
- (void) dbOrcaDBIPChanged:(NSNotification*)aNote;
- (void) dbDebugDBIPChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) viewTypeAction:(id)sender;

- (IBAction) eStop:(id)sender;

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

//eStop functions
- (IBAction) enmergencyStopToggle:(id)sender;

//xl3 mode sttaus
- (IBAction)updatexl3Mode:(id)sender;

#pragma mark ¥¥¥Details Interface Management
- (void) setDetectorTitle;
- (void) viewTypeChanged:(NSNotification*)aNote;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem;
-(void) windowDidLoad;
-(void) fetchRunMaskSettings;

- (IBAction) runsLockAction:(id)sender;

@end
@interface ORDetectorView (SNO)
- (void) setViewType:(int)aState;
@end

extern NSString* ORSNOPRequestHVStatus;
