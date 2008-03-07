//
//  ORHeaderExplorerModel.h
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


#pragma mark •••Imported Files
#import "ORFileMover.h"

#pragma mark •••Forward Declarations
@class ORDataPacket;
@class ThreadWorker;
@class ORHeaderItem;
@class ORDataSet;

@interface ORHeaderExplorerModel :  OrcaObject
{
    @private
		BOOL			stop;
        NSMutableArray*	filesToProcess;
        id              nextObject;

        ORHeaderItem*   header;
        NSString*       lastListPath;
        NSString*       lastFilePath;
		NSString*       fileToProcess;
        ORDataPacket*   fileAsDataPacket;

        BOOL			reading;
        unsigned long   total;
        unsigned long   numberLeft;
        unsigned long   currentFileIndex;
		
		NSMutableArray* runArray;
		unsigned long	minRunStartTime;
		unsigned long	maxRunEndTime;
		int				selectionDate;
		int				selectedRunIndex;

    BOOL autoProcess;
    NSString* searchKey;
    BOOL useFilter;
}

#pragma mark •••Accessors
- (BOOL) useFilter;
- (void) setUseFilter:(BOOL)aUseFilter;
- (NSString*) searchKey;
- (void) setSearchKey:(NSString*)aSearchKey;
- (BOOL) autoProcess;
- (void) setAutoProcess:(BOOL)aAutoProcess;
- (int) selectedRunIndex;
- (void) setSelectedRunIndex:(int)anIndex;
- (int)  selectionDate;
- (void) setSelectionDate:(int)aValue;
- (NSDictionary*) runDictionaryForIndex:(int)index;
- (unsigned long)   total;
- (unsigned long)   numberLeft;
- (NSString*)   fileToProcess;
- (void)        setFileToProcess:(NSString*)newFileToProcess;
- (NSArray*) filesToProcess;
- (void) addFilesToProcess:(NSMutableArray*)newFilesToProcess;
- (ORHeaderItem *)header;
- (void)setHeader:(ORHeaderItem *)aHeader;
- (BOOL)isProcessing;
- (NSString *) lastListPath;
- (void) setLastListPath: (NSString *) aSetLastListPath;
- (NSString *) lastFilePath;
- (void) setLastFilePath: (NSString *) aSetLastListPath;
- (unsigned long)	minRunStartTime;
- (unsigned long)	maxRunEndTime;

#pragma mark •••Data Handling
- (void) stopProcessing;
- (void) removeFilesWithIndexes:(NSIndexSet*)indexSet;
- (void) stopProcessing;
- (void) removeAll;
- (void) removeFiles:(NSMutableArray*)anArray;
- (void) readHeaders;
- (void) findSelectedRun;

#pragma mark •••Data Handling
- (void) readNextFile;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


#pragma mark •••External String Definitions
extern NSString* ORHeaderExplorerUseFilterChanged;
extern NSString* ORHeaderExplorerSearchKeyChanged;
extern NSString* ORHeaderExplorerAutoProcessChanged;
extern NSString* ORHeaderExplorerListChanged;
extern NSString* ORHeaderExplorerProcessing;
extern NSString* ORHeaderExplorerProcessingFinished;

extern NSString* ORHeaderExplorerProcessingEnded;
extern NSString* ORHeaderExplorerProcessingFile;
extern NSString* ORHeaderExplorerSelectionDate;
extern NSString* ORHeaderExplorerRunSelectionChanged;
extern NSString* ORHeaderExplorerOneFileDone;
extern NSString* ORHeaderExplorerHeaderChanged;
