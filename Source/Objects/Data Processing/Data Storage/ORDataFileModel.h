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
#import "ORDataProcessing.h"

#pragma mark ¥¥¥Forward Declarations
@class ORQueue;
@class ORSmartFolder;
@class ORAlarm;
@class ORDecoder;

#define kStopOnLimit	0
#define kRestartOnLimit 1
#define kMinDiskSpace   500 //MBytes

@interface ORDataFileModel :  ORDataChainObject <ORDataProcessing>
{
    @private
        NSFileHandle*	filePointer;
        unsigned long	dataFileSize;
        NSString*		fileName;
        NSString*		statusFileName;

        int				statusStart;
        BOOL			saveConfiguration;
        BOOL			ignoreMode;
        BOOL			processedRunStart;
        BOOL			processedCloseRun;

        ORSmartFolder*	dataFolder;
        ORSmartFolder*	statusFolder;
        ORSmartFolder*	configFolder;
        
        NSMutableData*	dataBuffer;
        NSTimeInterval	lastTime;
		BOOL			limitSize;
		float			maxFileSize;
		int				fileSegment;
		BOOL			fileLimitExceeded;
		NSString*		filePrefix;
		BOOL			useFolderStructure;
		BOOL			useDatedFileNames;
		int				sizeLimitReachedAction;
		ORAlarm*		diskFullAlarm;
		int				checkCount;
		int				runMode;
		NSTimeInterval	lastFileCheckTime;
		NSString*		openFilePath;
		BOOL			savedFirstTime; //use to force a config save
}

#pragma mark ¥¥¥Accessors
- (BOOL) useDatedFileNames;
- (void) setUseDatedFileNames:(BOOL)aUseDatedFileNames;
- (BOOL) useFolderStructure;
- (void) setUseFolderStructure:(BOOL)aUseFolderStructure;
- (NSString*) filePrefix;
- (void) setFilePrefix:(NSString*)aFilePrefix;
- (int) fileSegment;
- (void) setFileSegment:(int)aFileSegment;
- (float) maxFileSize;
- (void) setMaxFileSize:(float)aMaxFileSize;
- (BOOL) limitSize;
- (void) setLimitSize:(BOOL)aLimitSize;
- (ORSmartFolder *)dataFolder;
- (void)setDataFolder:(ORSmartFolder *)aDataFolder;
- (ORSmartFolder *)statusFolder;
- (void)setStatusFolder:(ORSmartFolder *)aStatusFolder;
- (ORSmartFolder *)configFolder;
- (void)setConfigFolder:(ORSmartFolder *)aConfigFolder;
- (int)sizeLimitReachedAction;
- (void) setSizeLimitReachedAction:(int)aValue;
- (void) setFileName:(NSString*)aFileName;
- (NSString*)fileName;
- (NSFileHandle *)filePointer;
- (void)setFilePointer:(NSFileHandle *)aFilePointer;
- (void)setTitles;
- (unsigned long)dataFileSize;
- (void) setDataFileSize:(unsigned long)aSize;
- (void) getDataFileSize;
- (void) checkDiskStatus;

- (BOOL)saveConfiguration;
- (void)setSaveConfiguration:(BOOL)flag;
- (NSString*) tempDir;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) runAboutToStart:(NSNotification*)aNotification;
- (void) setRunMode:(int)aMode;
- (void) statusLogFlushed:(NSNotification*)aNotification;

#pragma mark ¥¥¥Data Handling
- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;
- (void) runTaskStarted:(id)userInfo;
- (void) runTaskStopped:(id)userInfo;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


#pragma mark ¥¥¥External String Definitions
extern NSString* ORDataFileModelUseDatedFileNamesChanged;
extern NSString* ORDataFileModelUseFolderStructureChanged;
extern NSString* ORDataFileModelFilePrefixChanged;
extern NSString* ORDataFileModelFileSegmentChanged;
extern NSString* ORDataFileModelMaxFileSizeChanged;
extern NSString* ORDataFileModelLimitSizeChanged;
extern NSString* ORDataFileChangedNotification;
extern NSString* ORDataFileStatusChangedNotification;
extern NSString* ORDataFileSizeChangedNotification;
extern NSString* ORDataFileLock;
extern NSString* ORDataSaveConfigurationChangedNotification;
extern NSString* ORDataFileModelSizeLimitReachedActionChanged;

