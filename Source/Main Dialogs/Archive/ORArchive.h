//
//  ORArchive.h
//  Orca
//
//  Created by Mark Howe on Thu Nov 28 2002.
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
@class ORTimedTextField;

@interface ORArchive : NSWindowController {
	IBOutlet ORTimedTextField* operationStatusField;
	IBOutlet NSTextField* archivePathField;
	IBOutlet NSTextField* runStatusField;
	IBOutlet NSButton* archiveOrcaButton;
	IBOutlet NSButton* unarchiveRestartButton;
    IBOutlet NSButton* updateButton;
    IBOutlet NSButton* lockButton;
	int opState;
	NSOperationQueue* queue;
}

+ (ORArchive*) sharedArchive;

- (void) registerNotificationObservers;
- (void) securityStateChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;

- (IBAction) archiveThisOrca:(id)sender;
- (IBAction) startOldOrca:(id)sender;
- (IBAction) lockAction:(id)sender;
- (IBAction) updateWithSvn:(id)sender;

- (BOOL) checkOldBinariesFolder;
- (void) updateStatus:(NSString*)aString;

- (void) archiveCurrentBinary;
- (void) unArchiveBinary:(NSString*)fileToUnarchive;
- (void) restart;

- (void) startOldOrcaPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) updateWithSvnPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) deferedSvnUpdate:(NSString *)anUpdatePath;
- (void) deferedStartOldOrca:(NSString*)anOldOrcaPath;
- (void) checkQueueBusy;

@end

extern NSString*  ArchiveLock;

@interface ORArchiveOrcaOp : NSOperation
{
	id delegate;
}
- (id) initWithDelegate:(id)aDelegate;
- (void) main;
@end

@interface ORUnarchiveOrcaOp : NSOperation
{
	id		  delegate;
	NSString* fileToUnarchive;
}

- (id) initWithFile:(NSString*)aFile delegate:(id)aDelegate;
- (void) main;
@end

@interface ORRestartOrcaOp : NSOperation
{
	id		  delegate;
}
- (id) initWithDelegate:(id)aDelegate;
- (void) main;
@end

@interface ORUpdateOrcaWithSvnOp : NSOperation
{
	id		  delegate;
	NSString* srcPath;
}

- (id) initAtPath:(NSString*)aPath delegate:(id)aDelegate;
- (void) main;
@end

