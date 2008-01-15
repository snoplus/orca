//
//  ORAppDelegate.h
//  Orca
//
//  Created by Mark Howe on Tue Dec 03 2002.
//  Copyright  © 2002 CENPA, University of Washington. All rights reserved.
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


@class ORAlarmCollection;
@class MemoryWatcher;
@class ORSplashWindowController;

@interface ORAppDelegate : NSObject {
    id   document;
    ORAlarmCollection* alarmCollection;
    MemoryWatcher*     memoryWatcher;
    ORSplashWindowController* theSplashController;
}
+ (BOOL)isMacOSX10_5;
+ (BOOL)isMacOSX10_4;

- (MemoryWatcher*) memoryWatcher;
- (void) setMemoryWatcher:(MemoryWatcher*)aWatcher;
- (ORAlarmCollection*) alarmCollection;
- (void) setAlarmCollection:(ORAlarmCollection*)someAlarms;
- (void) mailCrashLog;
- (void) deleteCrashLog;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) applicationDidFinishLaunching:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) showProcessCenter:(id)sender;
- (IBAction) showAlarms:(id)sender;
- (IBAction) showTaskMaster:(id)sender;
- (IBAction) showHardwareWizard:(id)sender;
- (IBAction) showStatusLog:(id)sender;
- (IBAction) newDocument:(id)sender;
- (IBAction) openDocument:(id)sender;
- (IBAction) performClose:(id)sender;
- (IBAction) terminate:(id)sender;
- (IBAction) showCommandCenter:(id)sender;
- (IBAction) showCatalog:(id)sender;
- (IBAction) showPreferences:(id)sender;
- (IBAction) showMemoryWatcher:(id)sender;
- (IBAction) showGateKeeper:(id)sender;
- (IBAction) showWindowList:(id)sender;
- (IBAction) showORCARootServiceController:(id)sender;

#pragma mark ¥¥¥Accessors
- (id) document;
- (void) setDocument:(id)aDocument;
- (NSUndoManager*) undoManager;
@end

