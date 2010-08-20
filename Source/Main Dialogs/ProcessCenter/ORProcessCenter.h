//
//  ORProcessCenter.h
//  Orca
//
//  Created by Mark Howe on Sun Dec 11, 2005.
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

@class ORProcessModel;

@interface ORProcessCenter : NSWindowController {
    IBOutlet NSOutlineView* processView;
    IBOutlet NSButton*      startAllButton;
    IBOutlet NSButton*      stopAllButton;
    IBOutlet NSButton*      startSelectedButton;
    IBOutlet NSButton*      stopSelectedButton;
    IBOutlet NSMatrix*      modeSelectionButton;
	
	IBOutlet NSTableView*	addressList;
	IBOutlet NSButton* 		removeAddressButton;
	IBOutlet NSPopUpButton* heartbeatTimeIndexPU;
	IBOutlet NSButton* 		sendAtStopButton;
	IBOutlet NSButton* 		sendAtStartButton;
	IBOutlet NSTextField*   nextHeartbeatField;
    IBOutlet NSImageView*	heartbeatImage;
	
    NSMutableArray* eMailList;
    BOOL			emailEnabled;
    NSMutableArray* processorList;
    NSImage*		descendingSortingImage;
    NSImage*		ascendingSortingImage;
    NSString*		_sortColumn;
    BOOL			_sortIsDescending;
	int				processMode;
	int				heartbeatTimeIndex;
	BOOL			sendAtStart;
	BOOL			sendAtStop;
	NSDate*			nextHeartbeat;
}

+ (ORProcessCenter*) sharedProcessCenter;

- (id) init;
- (void) dealloc;
- (void) findObjects;

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window;
- (void) updateButtons;
- (void) setHeartbeatImage;
- (int) numberRunningProcesses;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) doReload:(NSNotification*)aNote;
- (void) objectsAdded:(NSNotification*)aNote;
- (void) objectsRemoved:(NSNotification*)aNote;
- (void) awakeAfterDocumentLoaded;

#pragma mark ¥¥¥Accessors
- (BOOL) emailEnabled;
- (void) setEmailEnabled:(BOOL)aEmailEnabled;
- (NSMutableArray*) eMailList;
- (void) setEMailList:(NSMutableArray*)aEMailList;
- (void) setProcessMode:(int)aMode;
- (int) processMode;

#pragma mark ¥¥¥eMail
- (void) removeAddressAtIndex:(int) anIndex;
- (void) addAddress:(id)anAddress atIndex:(int)anIndex;
- (int) heartbeatTimeIndex;
- (void) setHeartbeatTimeIndex:(int)aTime;
- (BOOL) sendAtStart;
- (void) setSendAtStart:(BOOL)aState;
- (BOOL) sendAtStop;
- (void) setSendAtStop:(BOOL)aState;
- (int) heartbeatSeconds;
- (void) sendHeartbeatShutOffWarning;
- (void) sendHeartbeat;
- (void) sendStopNotice:(ORProcessModel*)aProcess;
- (void) sendStartNotice:(ORProcessModel*)aProcess;
- (void) sendStartStopNotice:(ORProcessModel*)aProcess started:(BOOL)state;
- (void) eMailThread:(id)userInfo;
- (void) setNextHeartbeatString;

#pragma mark ¥¥¥Actions
- (IBAction) saveDocument:(id)sender;
- (IBAction) saveDocumentAs:(id)sender;
- (IBAction) startAll:(id)sender;
- (IBAction) stopAll:(id)sender;
- (IBAction) startSelected:(id)sender;
- (IBAction) stopSelected:(id)sender;
- (IBAction) modeAction:(id)sender;
- (IBAction) addAddress:(id)sender;
- (IBAction) removeAddress:(id)sender;
- (IBAction) heartbeatTimeIndexAction:(id)sender;
- (IBAction) sendAtStartAction:(id)sender;
- (IBAction) sendAtStopAction:(id)sender;

#pragma mark ¥¥¥Archival
- (void) decodeEMailList:(NSCoder*) aDecoder;
- (void) encodeEMailList:(NSCoder*) anEncoder;

#pragma mark ¥¥¥Data Source
- (id)   outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (int)  outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)  outlineView:(NSOutlineView *)outlineView  objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (void) outlineView:(NSOutlineView *)outlineView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn byItem:(id)item;
- (IBAction) doubleClick:(id)sender;
- (void) outlineView:(NSOutlineView*)tv didClickTableColumn:(NSTableColumn *)tableColumn;
- (void) updateTableHeaderToMatchCurrentSort;
-(void)setSortColumn:(NSString *)identifier ;
- (NSString *)sortColumn;
- (void)setSortIsDescending:(BOOL)whichWay ;
- (BOOL)sortIsDescending;
- (void)sort;

#pragma mark ¥¥¥Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification;

@end

extern NSString* ORProcessEmailOptionsChangedNotification;
