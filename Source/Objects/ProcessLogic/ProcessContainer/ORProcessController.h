//
//  ORProcessController.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORContainerController.h"

@interface ORProcessController : ORContainerController
{
    IBOutlet NSTabView* tabView;
	IBOutlet NSTextField* sampleRateField;
    IBOutlet NSTableView* tableView;
    IBOutlet NSButton* testModeButton;
    IBOutlet NSButton* startButton;
    IBOutlet NSTextField* statusTextField;
    IBOutlet NSTextView* detailsTextView;
    IBOutlet NSTextField* shortNameField;
    IBOutlet NSButton* altViewButton;

    NSImage* descendingSortingImage;
    NSImage* ascendingSortingImage;
    NSString *_sortColumn;
    BOOL _sortIsDescending;
}

#pragma mark ¥¥¥Initialization
- (id) init;
-(void) awakeFromNib;

#pragma mark ¥¥¥Interface Management
- (void) sampleRateChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) testModeChanged:(NSNotification*)aNote;
- (void) elementStateChanged:(NSNotification*)aNote;
- (void) processRunningChanged:(NSNotification*)aNote;
- (void) commentChanged:(NSNotification*)aNote;
- (void) shortNameChanged:(NSNotification*)aNote;
- (void) detailsChanged:(NSNotification*)aNote;
- (void) useAltViewChanged:(NSNotification*)aNote;
- (void) objectsChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) useAltViewAction:(id)sender;
- (IBAction) sampleRateAction:(id)sender;
- (IBAction) startProcess:(id)sender;
- (IBAction) testModeAction:(id)sender;
- (IBAction) shortNameAction:(id)sender;
- (IBAction) doubleClick:(id)sender;

#pragma mark ¥¥¥Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item;
- (void)setSortColumn:(NSString *)identifier;
- (NSString *)sortColumn;
- (void)setSortIsDescending:(BOOL)whichWay;
- (BOOL)sortIsDescending;
- (void) sort;
- (void) updateTableHeaderToMatchCurrentSort;

@end
