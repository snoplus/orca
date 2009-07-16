//
//  KatrinController.h
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
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

#import "ORExperimentController.h"

@class ORColorScale;
@class ORSegmentGroup;

@interface KatrinController : ORExperimentController {

    IBOutlet ORColorScale*	secondaryColorScale;
	IBOutlet NSTextField*	slowControlNameField;
	IBOutlet NSTextField*	slowControlIsConnectedField;
	IBOutlet NSTextField*	slowControlIsConnectedField1;
    IBOutlet NSButton*		secondaryColorAxisLogCB;
    IBOutlet NSTextField*	secondaryRateField;
    IBOutlet NSTextField*	detectorTitle;
   
	//items in the  HW map tab view
	IBOutlet NSPopUpButton* secondaryAdcClassNamePopup;
	IBOutlet NSTextField*	secondaryMapFileTextField;
    IBOutlet NSButton*		readSecondaryMapFileButton;
    IBOutlet NSButton*		saveSecondaryMapFileButton;
    IBOutlet NSTableView*	secondaryTableView;

	//items in the  details tab view
    IBOutlet NSTableView*	secondaryValuesView;

	ORSegmentGroup* secondaryGroup;
}

#pragma mark ¥¥¥Initialization
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) loadSegmentGroups;

#pragma mark ¥¥¥HW Map Actions
- (IBAction) slowControlNameAction:(id)sender;
- (IBAction) secondaryAdcClassNameAction:(id)sender;
- (IBAction) readSecondaryMapFileAction:(id)sender;
- (IBAction) saveSecondaryMapFileAction:(id)sender;

#pragma mark ¥¥¥Detector Interface Management
- (void) slowControlNameChanged:(NSNotification*)aNote;
- (void) slowControlIsConnectedChanged:(NSNotification*)aNote;
- (void) secondaryColorAxisAttributesChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥HW Map Interface Management
- (void) secondaryAdcClassNameChanged:(NSNotification*)aNote;
- (void) secondaryMapFileChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Details Interface Management
- (void) setDetectorTitle;

#pragma mark ¥¥¥Table Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn 
                                row:(int) rowIndex;
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject 
            forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void) tableView:(NSTableView*)tv didClickTableColumn:(NSTableColumn *)tableColumn;
//- (void) updateTableHeaderToMatchCurrentSort;
 

@end
