//
//  ORReplayDataModel.h
//  Orca
//
//  Created by Rielage on Thu Oct 02 2003.
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


#pragma mark ¥¥¥Imported Files
#import "ORFileMover.h"

#pragma mark ¥¥¥Forward Declarations
@class ORDataPacket;
@class ThreadWorker;
@class ORHeaderItem;
@class ORDataSet;

@interface ORReplayDataModel :  OrcaObject
{
    @private
		BOOL			stop;
        NSMutableArray*	filesToReplay;
        id              nextObject;

        ORHeaderItem*   header;
        NSString*       lastListPath;
        NSString*       lastFilePath;
		NSString*       fileToReplay;
        ORDataPacket*   fileAsDataPacket;
        NSArray*        dataRecords;

        ThreadWorker*   parseThread;
        unsigned long   totalLength;
        unsigned long   lengthDecoded;
		BOOL			sentRunStart;

}

#pragma mark ¥¥¥Accessors
- (unsigned long)   totalLength;
- (unsigned long)   lengthDecoded;
- (NSArray *)   dataRecords;
- (void)        setDataRecords: (NSArray *) aDataRecords;
- (id)          dataRecordAtIndex:(int)index;
- (NSString*)   fileToReplay;
- (void)        setFileToReplay:(NSString*)newFileToReplay;
- (NSArray*) filesToReplay;
- (void) addFilesToReplay:(NSMutableArray*)newFilesToReplay;
- (ORHeaderItem *)header;
- (void)setHeader:(ORHeaderItem *)aHeader;
- (BOOL)isReplaying;
- (NSString *) lastListPath;
- (void) setLastListPath: (NSString *) aSetLastListPath;
- (NSString *) lastFilePath;
- (void) setLastFilePath: (NSString *) aSetLastListPath;

#pragma mark ¥¥¥Data Handling
- (void) stopReplay;
- (void) readHeaderForFileIndex:(int)index;
- (void) removeFilesWithIndexes:(NSIndexSet*)indexSet;
- (void) stopReplay;
- (void) removeAll;
- (void) removeFiles:(NSMutableArray*)anArray;
- (void) replayFiles;

#pragma mark ¥¥¥Data Handling
- (void) dataPacket:(id)aDataPacket setTotalLength:(unsigned)aLength;
- (void) dataPacket:(id)aDataPacket setLengthDecoded:(unsigned)aLength;
- (void) parseFile;
- (BOOL) parseInProgress;

#pragma mark ¥¥¥Thread
- (id) parse:(id)userInfo thread:(id)tw;
- (void) processData;
- (void) parseThreadExited:(id)userInfo;
- (void) stopParse;
- (id) parse:(id)userInfo thread:(id)tw;
- (void)parseThreadExited:(id)userInfo;
- (void) postReadStarted;
- (void) postParseStarted;

@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORReplayFileListChangedNotification;
extern NSString* ORReplayFileAtEndNotification;
extern NSString* ORReplayRunningNotification;
extern NSString* ORReplayStoppedNotification;
extern NSString* ORReplayFileInProgressNotification;

extern NSString* ORRelayParseStartedNotification;
extern NSString* ORRelayParseEndedNotification;
extern NSString* ORRelayFileChangedNotification;
extern NSString* ORReplayReadingNotification;
extern NSString* ORReplayParseStartedNotification;
extern NSString* ORReplayProcessingStartedNotification;
