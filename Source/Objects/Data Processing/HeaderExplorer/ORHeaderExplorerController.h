//
//  ORHeaderExplorerController.h
//  Orca
//
//  Created by Mark Howe on Tue Feb 26.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


@interface ORHeaderExplorerController : OrcaObjectController  {
    @private
		IBOutlet NSButton* 		selectButton;
		IBOutlet NSButton*		useFilterCB;
		IBOutlet NSTextField*	searchKeyField;
		IBOutlet NSButton*		autoProcessCB;
		IBOutlet NSButton* 		replayButton;
		IBOutlet NSButton* 		saveButton;
		IBOutlet NSButton* 		loadButton;
		IBOutlet NSTableView*   fileListView;
		IBOutlet NSOutlineView*	headerView;
		IBOutlet NSProgressIndicator* 	progressIndicator;
		IBOutlet NSTextField* 	progressField;
		IBOutlet NSProgressIndicator* 	progressIndicatorBottom;
		IBOutlet NSView* 		runTimeView;
		IBOutlet NSTextField* 	runStartField;
		IBOutlet NSTextField* 	runEndField;
		IBOutlet NSTextField* 	selectionDateField;
		IBOutlet NSSlider*		selectionDateSlider;
		IBOutlet NSTextView* 	runSummaryTextView;
}

#pragma  mark •••Actions
- (IBAction) useFilterAction:(id)sender;
- (IBAction) searchKeyAction:(id)sender;
- (IBAction) autoProcessAction:(id)sender;
- (IBAction) selectButtonAction:(id)sender;
- (IBAction) replayButtonAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;
- (IBAction) removeItemAction:(id)sender;
- (IBAction) saveListAction:(id)sender;
- (IBAction) loadListAction:(id)sender;
- (IBAction) selectionDateAction:(id)sender;
- (IBAction) doubleClick:(id)sender;

#pragma mark •••Interface Management
- (void) useFilterChanged:(NSNotification*)aNote;
- (void) searchKeyChanged:(NSNotification*)aNote;
- (void) autoProcessChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) fileListChanged:(NSNotification*)aNote;
- (void) selectionDateChanged:(NSNotification*)aNote;
- (void) runSelectionChanged:(NSNotification*)aNote;
- (void) started:(NSNotification *)aNote;
- (void) stopped:(NSNotification *)aNote;
- (void) processingFile:(NSNotification *)aNote;
- (void) oneFileDone:(NSNotification *)aNote;
- (void) headerChanged:(NSNotification*)aNote;
- (void) setSelectionDate:(long)aValue;

#pragma mark •••Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex;
- (int) numberOfRowsInTableView:(NSTableView *)aTableView;
- (unsigned long) minRunStartTime;
- (unsigned long) maxRunEndTime;
- (long) numberRuns;
- (id) run:(int)index objectForKey:(id)aKey;

@end

@class CTGradient;

@interface ORRunTimeView : NSView
{
	IBOutlet id dataSource;
	CTGradient* selectedGradient;
	CTGradient* backgroundGradient;
	CTGradient* normalGradient;
	
}

- (void) drawRect:(NSRect)aRect;

@end

@interface NSObject (RunTimeView)
- (unsigned long) minRunStartTime;
- (unsigned long) maxRunEndTime;
- (int) selectedRunIndex;
- (long) numberRuns;
- (id) run:(int)index objectForKey:(id)aKey;
@end
