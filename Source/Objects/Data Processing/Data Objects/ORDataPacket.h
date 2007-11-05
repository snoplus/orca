//
//  ORDataPacket.h
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
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

#pragma mark •••Forward Declarations
@class ORDataSet;

#define kMaxReservedPoolSize 2045
#define kFastLoopupCacheSize 16384

@interface ORDataPacket : NSObject <NSCoding>{
    @private
		unsigned long        runNumber;             //current run number for this data
		NSString*            filePrefix;             //name for file prefix (i.e. Run, R_Run, etc..)
		NSMutableDictionary* objectLookup;			//table of objects that are taking data.
		id					 fastLookupCache[kFastLoopupCacheSize];
		NSMutableArray*  	 dataArray;             //data records
		NSMutableArray*  	 cacheArray;			//data records that are to be cached for later inclusion into data
		BOOL				 dataInCache;
		NSMutableDictionary* fileHeader;
		NSMutableData*		 frameBuffer;			//accumulator for data
		unsigned long		 frameIndex;
		NSRecursiveLock*     theDataLock;
		unsigned long		 reserveIndex;
        unsigned long        reservePool[kMaxReservedPoolSize];
        unsigned long        lastFrameBufferSize;
		BOOL				 dataAvailable;
		//one record decoding
		long            dataOffset;
		long            blockIndex;
		NSData*         currentDataBlock;
		int             version;
        BOOL            stopDecodeIntoArray;
        BOOL            addedData;
		long			frameCounter;
		long			oldFrameCounter;
		BOOL			needToSwap;
}

#pragma mark •••Accessors
- (BOOL) needToSwap;
- (int)  version;
- (void)  setVersion:(int)aVersion;
- (void) setRunNumber:(unsigned long)aRunNumber;
- (unsigned long)runNumber;
- (NSMutableDictionary *) fileHeader;
- (void) setFileHeader: (NSMutableDictionary *) aFileHeader;
- (void) makeFileHeader;
- (BOOL) addedData;
- (void) setAddedData:(BOOL)flag;

- (NSMutableDictionary*) objectLookup;
- (void) setObjectLookup:(NSMutableDictionary*)aDictionary;
- (void) generateXMLLookup;
- (id) 	 objectForKey:(id)key;
- (unsigned long) frameIndex;
- (NSMutableArray*)  dataArray;
- (void) setDataArray:(NSMutableArray*)someData;
- (NSMutableArray*) cacheArray;
- (void) setCacheArray:(NSMutableArray*)newCacheArray;
- (NSString*)filePrefix;
- (void)setFilePrefix:(NSString*)aFilePrefix;
- (NSMutableData*)  frameBuffer;
- (void) setFrameBuffer:(NSMutableData*)someData;

- (void) startFrameTimer;
- (void) stopFrameTimer;
- (void) forceFrameLoad;
- (void) addCachedData;
- (void) addDataToCach:(NSData*)someData;
- (void) addArrayToCache:(NSArray*)aDataArray;

- (void) addFrameBuffer:(BOOL)forceAdd;
- (void) addData:(NSData*)someData;
- (void) addDataFromArray:(NSArray*)aDataArray;

- (unsigned long*) getBlockForAddingLongs:(unsigned long)length;
- (unsigned long) addLongsToFrameBuffer:(unsigned long*)someData length:(unsigned long)length;
- (void) replaceReservedDataInFrameBufferAtIndex:(unsigned long)index withLongs:(unsigned long*)data length:(unsigned long)length;
- (unsigned long)reserveSpaceInFrameBuffer:(unsigned long)length;
- (void) removeReservedLongsFromFrameBuffer:(NSRange)aRange;
- (void) clearData;
- (void) decodeIntoDataSet:(ORDataSet*)aDataSet;
- (void) decode:(NSData*)someData intoDataSet:(ORDataSet*)aDataSet;
- (void) decode:(unsigned long*)dPtr length:(unsigned long)length intoDataSet:(ORDataSet*)aDataSet;
- (NSArray*) decodeDataIntoArrayForDelegate:(id)aDelegate;
- (unsigned long) dataCount;
- (NSString*) dataRecordDescription:(unsigned long)anOffset forKey:(NSNumber*)aKey;
- (void) addEventDescriptionItem:(NSDictionary*) eventDictionary;
- (void) decodeOneRecordAtOffset:(unsigned long)offset intoDataSet:(ORDataSet*)aDataSet forKey:(NSNumber*)aKey;
- (void) byteSwapOneRecordAtOffset:(unsigned long)anOffset intoDataSet:(ORDataSet*)aDataSet forKey:(NSNumber*)aKey;
- (void) setStopDecodeIntoArray:(BOOL)state;

//one record decoding
- (void) decodeStart;
- (BOOL) decodeFileFinished;

#pragma mark •••File I/O
- (NSData*) headerAsData;
- (unsigned long) readXMLHeader: (NSFileHandle*)fp;
- (id) headerObject:(NSString*) firstKey,...;

- (void) writeData: (NSFileHandle*)fp;
- (BOOL) readData: (NSFileHandle*)fp;
- (BOOL) readDataBytes: (NSFileHandle*)fp;
- (BOOL) readDataRecord: (NSFileHandle*)fp;
- (long) getExpectedDataLength:(unsigned long)data;
- (BOOL) readBeginData: (NSFileHandle*)fp;
- (BOOL) legalDataFile: (NSFileHandle*)fp;
- (void) addDataDescriptionItem:(NSDictionary*) dataDictionary forKey:(NSString*)aKey;
- (id) fileDetails;
- (void) generateObjectLookup;
- (BOOL) readHeader: (NSFileHandle*)fp;
-(unsigned long)decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

@interface NSObject (ORDataPacket)
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
- (void) dataPacket:(id)aDataPacket setTotalLength:(unsigned)aLength;
- (void) dataPacket:(id)aDataPacket setLengthDecoded:(unsigned)aLength;
@end
