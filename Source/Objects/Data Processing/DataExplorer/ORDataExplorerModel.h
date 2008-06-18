//
//  ORDataExplorerModel.h
//  Orca
//
//  Created by Mark Howe on Sun Dec 05 2004.
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

#pragma mark ¥¥¥Forward Declarations
@class ORDataPacket;
@class ORHeaderItem;
@class ORDataSet;
@class ThreadWorker;

@interface ORDataExplorerModel :  OrcaObject
{
    @private
        NSString*       fileToExplore;
        ORHeaderItem*   header;
        ORDataPacket*   fileAsDataPacket;
        NSArray*        dataRecords;
        ORDataSet*      dataSet;

        ThreadWorker*   parseThread;
        unsigned        totalLength;
        unsigned        lengthDecoded;
		BOOL			multiCatalog;
		BOOL			histoErrorFlag;
}

#pragma mark ¥¥¥Accessors
- (BOOL) histoErrorFlag;
- (void) setHistoErrorFlag:(BOOL)aHistoErrorFlag;
- (BOOL) multiCatalog;
- (void) setMultiCatalog:(BOOL)aMultiCatalog;
- (ORDataSet*) 	dataSet;
- (void)        setDataSet:(ORDataSet*)aDataSet;
- (NSString*)   fileToExplore;
- (void)        setFileToExplore:(NSString*)newFileToExplore;
- (ORHeaderItem*)header;
- (void)        setHeader:(ORHeaderItem *)aHeader;
- (NSArray *)   dataRecords;
- (void)        setDataRecords: (NSArray *) aDataRecords;
- (id)          dataRecordAtIndex:(int)index;
- (ORDataPacket*) fileAsDataPacket;
- (void) removeDataSet:(ORDataSet*)item;
- (id)   childAtIndex:(int)index;
- (unsigned)  numberOfChildren;
- (unsigned)  count;
- (void) createDataSet;
- (void) dataPacket:(id)aDataPacket setTotalLength:(unsigned)aLength;
- (void) dataPacket:(id)aDataPacket setLengthDecoded:(unsigned)aLength;
- (void) decodeOneRecordAtOffset:(unsigned long)offset forKey:(id)aKey;
- (void) byteSwapOneRecordAtOffset:(unsigned long)anOffset forKey:(id)aKey;
- (unsigned) totalLength;
- (unsigned) lengthDecoded;
- (void) clearCounts;
- (BOOL) parseInProgress;
- (void) stopParse;
- (void) flushMemory;


#pragma mark ¥¥¥Data Handling
- (void) parseFile;

#pragma mark ¥¥¥Thread
-(id) parse:(id)userInfo thread:(id)tw;
-(void) parseThreadExited:(id)userInfo;

#pragma mark ¥¥¥Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


#pragma mark ¥¥¥External String Definitions
extern NSString* ORDataExplorerModelHistoErrorFlagChanged;
extern NSString* ORDataExplorerModelMultiCatalogChanged;
extern NSString* ORDataExplorerFileChangedNotification;
extern NSString* ORDataExplorerDataChanged;
extern NSString* ORDataExplorerParseStartedNotification;
extern NSString* ORDataExplorerParseEndedNotification;