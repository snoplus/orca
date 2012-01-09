//
//  SNOController.h
//  Orca
//
//  Created by H S  Wan Chan Tseung on 11/18/11.
//  Copyright (c) 2011 CENPA, University of Washington. All rights reserved.
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

@class ORPlotView;
@class SNODetectorView;
@class ORRunModel;

//#import "ORExperimentController.h"
#import "SNODetectorView.h"
#import "SNOSlowControl.h"

@interface SNOController : OrcaObjectController {
	//run control window
	IBOutlet NSButton* startRunButton;
	IBOutlet NSButton* stopRunButton;
	IBOutlet NSTextField* runNumberField;
	IBOutlet NSTextField* runStatusField;
	IBOutlet NSTextField* elapsedTimeField;
	IBOutlet NSProgressIndicator* runBar;
	IBOutlet NSButton* showTotalDataRate;
	IBOutlet NSButton* showMonitorWindow;
	IBOutlet NSWindow* monitorWindow;
	IBOutlet NSWindow* totalDataRateWindow;
	ORRunModel* runControl;
	
    //slow control tab
	IBOutlet NSButton* connectToIOServerButton;
	IBOutlet NSButton* setThresholdsButton;
	IBOutlet NSButton* setGainButton;
	IBOutlet NSButton* startSlowControlMonitorButton;
	IBOutlet NSButton* stopSlowControlMonitorButton;	
	IBOutlet NSButton* enableSlowControlParameterButton;
	IBOutlet NSButton* setSlowControlMappingButton;
	IBOutlet NSTableView* slowControlParameterTable;
    IBOutlet NSPopUpButton* slowControlPollingButton;	
    IBOutlet NSTextField*  slowControlMonitorStatus;	
	
	//detector view tab	
	IBOutlet ORColorScale*	secondaryColorScale;
    IBOutlet NSButton*	  colorBarLogCB;	
	IBOutlet NSButton*    readMorca;
	IBOutlet NSButton*    stopXl3PollingButton;
	IBOutlet SNODetectorView* detectorView;
	IBOutlet NSTextView*	selectionStringTextView;
	IBOutlet NSTextView*	globalStatsView;
	IBOutlet NSPopUpButton* viewSelectionButton;
	IBOutlet NSPopUpButton* parameterDisplayButton;
	IBOutlet NSPopUpButton* selectionModeButton;
	IBOutlet NSPopUpButton* xl3PollingButton;
	IBOutlet NSTabView* tabView;
	BOOL pickPSUPView;
	
	NSView *blankView;
    NSSize runControlSize;
    NSSize detectorSize;
    NSSize monitorSize;
    NSSize slowControlSize;
}

#pragma mark •••Initialization
- (void) registerNotificationObservers;

#pragma mark •••Actions
//run control actions
- (IBAction) startRunAction:(id)sender;
- (IBAction) stopRunAction:(id)sender;
- (IBAction) showTotalDataRate:(id)sender;
- (IBAction) showMonitorWindow:(id)sender;

//slow control actions
- (IBAction) connectToIOServerAction:(id)sender;
- (IBAction) setSlowControlPollingAction:(id)sender;
- (IBAction) startSlowControlPollingAction:(id)sender;
- (IBAction) stopSlowControlPollingAction:(id)sender;
- (IBAction) setSlowControlParameterThresholdsAction:(id)sender;
- (IBAction) setSlowControlChannelGainAction:(id)sender;
- (IBAction) enableSlowControlParameterAction:(id)sender;
- (IBAction) setSlowControlMappingAction:(id)sender;

//detector view actions
- (IBAction) viewSelectionAction:(id)sender;
- (IBAction) parameterDisplayAction:(id)sender;
- (IBAction) selectionModeAction:(id)sender;
- (IBAction) readMorca:(id)sender;
- (IBAction) setXl3PollingAction:(id)sender;
- (IBAction) startXl3PollingAction:(id)sender;
- (IBAction) stopXl3PollingAction:(id)sender;

#pragma mark •••Interface Management
- (void) findRunControl;
- (void) updateRunInfo:(NSNotification*)aNote;
//- (void) scaleAction:(NSNotification*)aNote;
- (void) elapsedTimeChanged:(NSNotification*)aNote;
//- (void) colorAttributesChanged:(NSNotification*)aNote;
- (void) selectionStringChanged:(NSNotification*)aNote;
- (void) slowControlTableChanged:(NSNotification *)aNote;
//- (void) globalStatsStringChanged:(NSNotification *)aNote;
- (void) slowControlConnectionStatusChanged:(NSNotification *)aNote;
//- (void) drawView:(NSView*)aView inRect:(NSRect)aRect;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem;
- (void) morcaDBRead:(NSNotification *)aNote;

#pragma mark •••Table Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn 
			 row:(int) rowIndex;
//- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject 
   forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell 
   forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void) tableView:(NSTableView*)tv didClickTableColumn:(NSTableColumn *)tableColumn;


@end

/*@interface ORPSUPView : ORGenericView
{
}
@end*/