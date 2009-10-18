//
//  ORExperimentController.h
//  Orca
//
//  Created by Mark Howe on 12/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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

@class ORDetectorView;
@class ORAxis;
@class ORPlotter1D;
@class ORColorScale;
@class BiStateView;
@class ORRunModel;

@interface ORExperimentController : OrcaObjectController {
    IBOutlet NSTabView*		tabView;
	IBOutlet NSButton*		showNamesCB;

	//detector View tab view
	IBOutlet NSPopUpButton*	displayTypePU;
	IBOutlet NSTextView*	selectionStringTextView;
    IBOutlet ORDetectorView* detectorView;
    IBOutlet ORColorScale*	primaryColorScale;
    IBOutlet NSButton*		primaryColorAxisLogCB;
    IBOutlet ORPlotter1D*	ratePlot;
    IBOutlet NSButton*		rateLogCB;
    IBOutlet NSTableView*	primaryTableView;
    IBOutlet NSButton*		detectorLockButton;
    IBOutlet BiStateView*	hardwareCheckView;
    IBOutlet BiStateView*	cardCheckView;
    IBOutlet NSButton*		captureStateButton;
    IBOutlet NSButton*		reportStateButton;
    IBOutlet NSTextField*	captureDateField;
    IBOutlet NSTextField*	primaryRateField;
    IBOutlet NSButton*		startRunButton;
    IBOutlet NSButton*		stopRunButton;
    IBOutlet NSTextField*	runNumberField;
    IBOutlet NSTextField*	runStatusField;
    IBOutlet NSTextField*	elapsedTimeField;
    IBOutlet NSButton*      timedRunCB;
    IBOutlet NSButton*      repeatRunCB;
    IBOutlet NSTextField*   timeLimitField;
    IBOutlet NSMatrix*      runModeMatrix;
    IBOutlet NSProgressIndicator* 	runBar;

	//items in the  details tab view
	IBOutlet NSPopUpButton*	displayTypePU1;
    IBOutlet ORPlotter1D*	valueHistogramsPlot;
	IBOutlet NSTextField*	histogramTitle;
    IBOutlet NSTableView*	primaryValuesView;
    IBOutlet NSButton*		initButton;
    IBOutlet NSButton*		detailsLockButton;

	//items in the  Map tab view
	IBOutlet NSTextField*	primaryMapFileTextField;
    IBOutlet NSButton*		readPrimaryMapFileButton;
    IBOutlet NSButton*		savePrimaryMapFileButton;
    IBOutlet NSButton*		mapLockButton;
	IBOutlet NSPopUpButton* primaryAdcClassNamePopup;
   
	NSMutableArray* segmentGroups;
	ORRunModel*     runControl;
}

#pragma mark •••Initialization
- (void) registerNotificationObservers;

#pragma mark •••Subclass responsibility
- (void) loadSegmentGroups;
- (NSString*) defaultPrimaryMapFilePath;
- (void) setDetectorTitle;

#pragma mark •••Actions
- (IBAction) showNamesAction:(id)sender;
- (IBAction) displayTypeAction:(id)sender;
- (IBAction) primaryAdcClassNameAction:(id)sender;
- (IBAction) mapLockAction:(id)sender;
- (IBAction) detectorLockAction:(id)sender;
- (IBAction) captureStateAction:(id)sender;
- (IBAction) reportConfigAction:(id)sender;
- (IBAction) readPrimaryMapFileAction:(id)sender;
- (IBAction) savePrimaryMapFileAction:(id)sender;
- (IBAction) startRunAction:(id)sender;
- (IBAction) stopRunAction:(id)sender;
- (IBAction) timeLimitTextAction:(id)sender;
- (IBAction) timedRunCBAction:(id)sender;
- (IBAction) repeatRunCBAction:(id)sender;
- (IBAction) runModeAction:(id)sender;

#pragma mark •••Details Actions
- (IBAction) detailsLockAction:(id)sender;
- (IBAction) initAction:(id)sender;

#pragma mark •••Interface Management
- (void) showNamesChanged:(NSNotification*)aNote;
- (void) updateRunInfo:(NSNotification*)aNote;
- (void) findRunControl:(NSNotification*)aNote;
- (void) selectionChanged:(NSNotification*)aNote;
- (void) populateClassNamePopup:(NSPopUpButton*)aPopup;
- (void) specialUpdate:(NSNotification*)aNote;
- (void) displayTypeChanged:(NSNotification*)aNote;
- (void) primaryMapFileChanged:(NSNotification*)aNote;
- (void) selectionStringChanged:(NSNotification*)aNote;
- (void) primaryAdcClassNameChanged:(NSNotification*)aNote;
- (void) replayStarted:(NSNotification*)aNotification;
- (void) replayStopped:(NSNotification*)aNotification;
- (void) objectsChanged:(NSNotification*)aNote;
- (void) mapFileRead:(NSNotification*)aNote;
- (void) mapLockChanged:(NSNotification*)aNotification;
- (void) detectorLockChanged:(NSNotification*)aNotification;
- (void) checkGlobalSecurity;
- (void) hardwareCheckChanged:(NSNotification*)aNotification;
- (void) cardCheckChanged:(NSNotification*)aNotification;
- (void) captureDateChanged:(NSNotification*)aNotification;
- (void) updateForReplayMode;
- (void) newTotalRateAvailable:(NSNotification*)aNotification;
- (void) miscAttributesChanged:(NSNotification*)aNotification;
- (void) timedRunChangted:(NSNotification*)aNote;
- (void) runModeChanged:(NSNotification*)aNote;
- (void) runTimeLimitChanged:(NSNotification*)aNote;
- (void) repeatRunChanged:(NSNotification*)aNote;
-(void) elapsedTimeChanged:(NSNotification*)aNotification;

#pragma mark •••Details Interface Management
- (void) histogramsUpdated:(NSNotification*)aNote;
- (void) setValueHistogramTitle;
- (void) scaleValueHistogram;
- (void) detailsLockChanged:(NSNotification*)aNotification;

#pragma mark •••Data Source For Plots
- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (float)  	plotter:(id) aPlotter  dataSet:(int)set dataValue:(int) x;
- (unsigned long)  	secondsPerUnit:(id) aPlotter;

#pragma mark •••Data Source For Tables
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn 
                                row:(int) rowIndex;
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject 
            forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
 
@end
