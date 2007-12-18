//
//  ORDataFileModel.h
//  Orca
//
//  Created by Mark Howe on Tue Dec 24 2002.
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
#import "ORDataChainObject.h"

#pragma mark ¥¥¥Forward Declarations
@class ORDataPacket;
@class ORQueue;
@class ORSmartFolder;

@interface ORDataFileModel :  ORDataChainObject
{
    @private
        NSFileHandle*  filePointer;
        NSTimer*	 fileSizeTimer;
        unsigned long dataFileSize;
        NSString*	fileName;
        NSString*	statusFileName;

        int		    statusStart;
        BOOL		saveConfiguration;
        BOOL		ignoreMode;
        BOOL        processedRunStart;
        BOOL        processedCloseRun;

        ORSmartFolder*	    dataFolder;
        ORSmartFolder*	    statusFolder;
        ORSmartFolder*	    configFolder;
        
        NSMutableData*     dataBuffer;
        NSTimeInterval     lastTime;
}

#pragma mark ¥¥¥Accessors
- (ORSmartFolder *)dataFolder;
- (void)setDataFolder:(ORSmartFolder *)aDataFolder;
- (ORSmartFolder *)statusFolder;
- (void)setStatusFolder:(ORSmartFolder *)aStatusFolder;
- (ORSmartFolder *)configFolder;
- (void)setConfigFolder:(ORSmartFolder *)aConfigFolder;

- (void) setFileName:(NSString*)aFileName;
- (NSString*)fileName;
- (NSFileHandle *)filePointer;
- (void)setFilePointer:(NSFileHandle *)aFilePointer;
- (void)setTitles;
- (unsigned long)dataFileSize;
- (void) setDataFileSize:(unsigned long)aSize;
- (NSTimer*) fileSizeTimer;
- (void) setFileSizeTimer:(NSTimer*)aTimer;
- (void) getDataFileSize:(NSTimer*)aTimer;

- (BOOL)saveConfiguration;
- (void)setSaveConfiguration:(BOOL)flag;
- (NSString*) tempDir;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) runAboutToStart:(NSNotification*)aNotification;
- (void) runModeChanged:(NSNotification*)aNotification;
- (void) statusLogFlushed:(NSNotification*)aNotification;

#pragma mark ¥¥¥Data Handling
- (void) processData:(ORDataPacket*)someData  userInfo:(NSDictionary*)userInfo;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;



@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORDataFileChangedNotification;
extern NSString* ORDataFileStatusChangedNotification;
extern NSString* ORDataFileSizeChangedNotification;
extern NSString* ORDataFileLock;
extern NSString* ORDataSaveConfigurationChangedNotification;

