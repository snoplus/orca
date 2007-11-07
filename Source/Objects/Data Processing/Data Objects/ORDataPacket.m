//
//  ORDataPacket.m
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
#import "ORDataPacket.h"
#import "ORFileIOHelpers.h"
#import "ORDataSet.h"
#import "ORDataTaker.h"
#import "ORDataTypeAssigner.h"
#import "ORGateGroup.h"

#define kDataVersion 3
#define kMinSize 4096*2
#define kMinCapacity 4096

@implementation ORDataPacket

- (id)init
{
    self = [super init];
        
    theDataLock         = [[NSRecursiveLock alloc] init];
    
    version = kDataVersion;
    lastFrameBufferSize = kMinSize;
    return self;
}

- (void) dealloc
{
    [theDataLock release];
    [dataArray release];
	[cacheArray release];
    [objectLookup release];
    [filePrefix release];
    [fileHeader release];
    [frameBuffer release];
    [super dealloc];
}

- (id) copyWithZone:(NSZone*)zone
{
    return [[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]] retain];
}


#pragma mark •••Accessors
- (void) setRunNumber:(unsigned long)aRunNumber
{
    runNumber = aRunNumber;
}

- (unsigned long)runNumber
{
    return runNumber;
}

- (NSMutableDictionary *) fileHeader
{
    return fileHeader; 
}

- (void) setFileHeader: (NSMutableDictionary *) aFileHeader
{
    [aFileHeader retain];
    [fileHeader release];
    fileHeader = aFileHeader;
}

- (void) makeFileHeader
{
    [self setFileHeader:[[[NSApp delegate] document] captureCurrentState:[NSMutableDictionary dictionary]]];
    NSMutableDictionary* docDict = [fileHeader objectForKey:@"Document Info"];
    if(!docDict){
        docDict = [NSMutableDictionary dictionary];
        [fileHeader setObject:docDict forKey:@"Document Info"];
    }
    [docDict setObject:[NSNumber numberWithInt:kDataVersion] forKey:@"dataVersion"];
    
}

- (void) addDataDescriptionItem:(NSDictionary*) dataDictionary forKey:(NSString*)aKey
{
    id dataDescriptionDictionary = [fileHeader objectForKey:@"dataDescription"];
    if(!dataDescriptionDictionary){
        dataDescriptionDictionary = [NSMutableDictionary dictionary];
        [fileHeader setObject:dataDescriptionDictionary forKey:@"dataDescription"];
    }
    [dataDescriptionDictionary setObject:dataDictionary forKey:aKey];
}

- (void) addEventDescriptionItem:(NSDictionary*) eventDictionary
{
	[fileHeader setObject:eventDictionary forKey:@"eventDescription"];
}

- (id) headerObject:(NSString*) firstKey,...
{
    va_list myArgs;
    va_start(myArgs,firstKey);
    
    NSString* s = firstKey;
	id result = [fileHeader objectForKey:s];
	while(s = va_arg(myArgs, NSString *)) {
		result = [result objectForKey:s];
    }
    va_end(myArgs);
	
	return result;
}

- (void) startFrameTimer
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceFrameLoad) object:nil];
    [self performSelector:@selector(forceFrameLoad) withObject:nil afterDelay:.1];
	oldFrameCounter = 0;
	frameCounter = 0;
}

- (void) stopFrameTimer
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceFrameLoad) object:nil];
}

- (void) forceFrameLoad
{
	++frameCounter;
    [self performSelector:@selector(forceFrameLoad) withObject:nil afterDelay:.1];
}

- (NSMutableArray*)  dataArray
{
	[theDataLock lock];   //-----begin critical section
	NSMutableArray* temp = [[dataArray retain] autorelease];
	[theDataLock unlock];   //-----end critical section
	return temp;
}

- (void) setDataArray:(NSMutableArray*)someData
{
	[theDataLock lock];   //-----begin critical section
    [someData retain];
    [dataArray release];
    dataArray = someData;
	[theDataLock unlock];   //-----end critical section
}

- (NSMutableData*)  frameBuffer
{
	[theDataLock lock];   //-----begin critical section
	NSMutableData* temp = [[frameBuffer retain] autorelease];
	[theDataLock unlock];   //-----end critical section
	return temp;
}

- (void) setFrameBuffer:(NSMutableData*)someData
{
	[theDataLock lock];   //-----begin critical section
    [someData retain];
    [frameBuffer release];
    frameBuffer = someData;
	
	frameIndex = 0;
    reserveIndex = 0;
	[theDataLock unlock];   //-----end critical section
}

- (NSMutableArray*) cacheArray
{
	[theDataLock lock];   //-----begin critical section
	NSMutableArray* temp = [[cacheArray retain] autorelease];
	[theDataLock unlock];   //-----end critical section
	return temp;
}
- (void) setCacheArray:(NSMutableArray*)newCacheArray
{
	[theDataLock lock];   //-----begin critical section
    [cacheArray autorelease];
    cacheArray=[newCacheArray retain];
	[theDataLock unlock];   //-----end critical section
}

- (NSMutableDictionary*) objectLookup
{
	[theDataLock lock];   //-----begin critical section
	NSMutableDictionary* temp = [[objectLookup retain] autorelease];
	[theDataLock unlock];   //-----end critical section
    return temp;
}

- (void) setObjectLookup:(NSMutableDictionary*)aDictionary
{
	[theDataLock lock];   //-----begin critical section
    [aDictionary retain];
    [objectLookup release];
    objectLookup = aDictionary;
	[theDataLock unlock];   //-----end critical section
}

- (NSString*)filePrefix
{
    return filePrefix;
}

- (void)setFilePrefix:(NSString*)aFilePrefix
{
    [filePrefix autorelease];
    filePrefix = [aFilePrefix copy];
}

- (void) generateXMLLookup
{
    NSDictionary* descriptionDict = [fileHeader objectForKey:@"dataDescription"];
    NSString* objKey;
    NSEnumerator*  descriptionDictEnum = [descriptionDict keyEnumerator];
    while(objKey = [descriptionDictEnum nextObject]){
        NSDictionary* objDictionary = [descriptionDict objectForKey:objKey];
        NSEnumerator* dataObjEnum = [objDictionary keyEnumerator];
        NSString* dataObjKey;
        while(dataObjKey = [dataObjEnum nextObject]){
            NSDictionary* lowestLevel = [objDictionary objectForKey:dataObjKey];
            id decoderName = [lowestLevel objectForKey:@"decoder"];
            id decoderObj =  [[NSClassFromString(decoderName) alloc] init];
            if(decoderObj){
				if([lowestLevel objectForKey:@"dataId"]){
					[objectLookup setObject:decoderObj forKey:[lowestLevel objectForKey:@"dataId"]];
					//install any defined gates
					ORGateGroup* theGates = [[[NSApp delegate] document] gateGroup];
					[theGates installGates:decoderObj];
				}
				[decoderObj release];
            }
            else NSLogError(decoderName,@"Data Description Item",@"Programming Error (no Object)",nil);
        }
   }      
}


- (id) objectForKey:(id)key
{
    return [objectLookup objectForKey:key];
}


//------------------------------------------------------------------------------
//data addition methods
- (unsigned long) frameIndex
{
	return frameIndex;
}
- (void) replaceReservedDataInFrameBufferAtIndex:(unsigned long)index withLongs:(unsigned long*)data length:(unsigned long)length
{
	[theDataLock lock];   //-----begin critical section
	if(frameBuffer && index<reserveIndex){
		memcpy(((unsigned long*)[frameBuffer bytes])+reservePool[index],data,length*sizeof(long));
		addedData = YES;
	}
	[theDataLock unlock];   //-----end critical section
}


- (unsigned long) addLongsToFrameBuffer:(unsigned long*)someData length:(unsigned long)length
{
	[theDataLock lock];   //-----begin critical section
    if(!frameBuffer){
		[self setFrameBuffer:[NSMutableData dataWithLength:lastFrameBufferSize]];
	}
	if((frameIndex+length)*sizeof(long)>=[frameBuffer length]){
		[frameBuffer increaseLengthBy:(length*sizeof(long))+kMinSize];
        lastFrameBufferSize = [frameBuffer length];
	}
    memcpy(((unsigned long*)[frameBuffer bytes])+frameIndex,someData,length*sizeof(long));

	frameIndex += length;
    addedData = YES;
	[theDataLock unlock];   //-----end critical section
	return  frameIndex;
}

- (unsigned long*) getBlockForAddingLongs:(unsigned long)length
{
	[theDataLock lock];   //-----begin critical section
    if(!frameBuffer){
		[self setFrameBuffer:[NSMutableData dataWithLength:lastFrameBufferSize]];
	}
	unsigned long oldFrameIndex = frameIndex;
	frameIndex += length;
	if([frameBuffer length]<frameIndex*sizeof(long)){
		unsigned long deltaLength = (length*sizeof(long))+kMinSize;
		[frameBuffer increaseLengthBy:deltaLength];
        lastFrameBufferSize = [frameBuffer length];  
	}
	unsigned long* ptr = (unsigned long*)[frameBuffer bytes];
	[theDataLock unlock];   //-----end critical section
	return &ptr[oldFrameIndex];
}

- (unsigned long)reserveSpaceInFrameBuffer:(unsigned long)length
{
	[theDataLock lock];   //-----begin critical section
    if(!frameBuffer) [self setFrameBuffer:[NSMutableData dataWithLength:kMinSize]];
	
    reservePool[reserveIndex] = frameIndex;
	unsigned long oldIndex = reserveIndex;
    reserveIndex++;

	frameIndex += length;
	if([frameBuffer length]<=frameIndex*sizeof(long)){
		[frameBuffer increaseLengthBy:(length*sizeof(long))+kMinSize];
        lastFrameBufferSize = [frameBuffer length];        
	}
	[theDataLock unlock];   //-----end critical section
	return oldIndex;
}

- (void) removeReservedLongsFromFrameBuffer:(NSRange)aRange
{
	[theDataLock lock];   //-----begin critical section
	if(frameBuffer){
        unsigned long actualReservedLocation = reservePool[aRange.location];
        if(actualReservedLocation>=0){
			unsigned long* ptr = (unsigned long*)[frameBuffer bytes];
			memmove(&ptr[actualReservedLocation],&ptr[actualReservedLocation+aRange.length],(frameIndex-actualReservedLocation-aRange.length)*sizeof(long));
			frameIndex -= aRange.length;
			
			unsigned long i;
			reservePool[aRange.location] = -1;
			for(i=aRange.location+1;i<reserveIndex;i++){
				reservePool[i] -= aRange.length;
			}
		}
	}	
	[theDataLock unlock];   //-----end critical section
}

- (void) addFrameBuffer:(BOOL)forceAdd
{
	if(frameBuffer && (forceAdd || (oldFrameCounter!=frameCounter) || dataAvailable || dataInCache)){
		[theDataLock lock];   //-----begin critical section
		oldFrameCounter = frameCounter;
		[frameBuffer setLength:(frameIndex*sizeof(long))];

		//[self addData:frameBuffer];
		if(!dataArray)[self setDataArray:[NSMutableArray arrayWithCapacity:kMinCapacity]];
		[dataArray addObject:frameBuffer];
		addedData = YES;
		
		dataAvailable = NO;
		[frameBuffer release];
        frameBuffer = nil;
		frameIndex = 0;
		[theDataLock unlock];   //-----end critical section
	}
	reserveIndex = 0;
}

- (void) addData:(NSData*)someData
{
	[theDataLock lock];   //-----begin critical section
    if(!dataArray)[self setDataArray:[NSMutableArray arrayWithCapacity:kMinCapacity]];
    [dataArray addObject:someData];
    addedData = YES;
	dataAvailable = YES;
	[theDataLock unlock];   //-----end critical section
}


- (void) addDataFromArray:(NSArray*)aDataArray
{
	[theDataLock lock];   //-----begin critical section
    if(!dataArray)[self setDataArray:[NSMutableArray arrayWithCapacity:kMinCapacity]];
    [dataArray addObjectsFromArray:aDataArray];
    addedData = YES;
	dataAvailable = YES;
	[theDataLock unlock];   //-----end critical section
}

- (void) addCachedData
{
	if(dataInCache){
		[theDataLock lock];   //-----begin critical section
		if([cacheArray count]){
			[self addDataFromArray:cacheArray];
			[cacheArray removeAllObjects];
		}
		dataInCache = NO;
		[theDataLock unlock];   //-----end critical section
	}
}

- (unsigned long) dataCount
{
    return [dataArray count];
}

- (void) addDataToCach:(NSData*)someData;
{
    if(!cacheArray)[self setCacheArray:[NSMutableArray arrayWithCapacity:kMinCapacity]];
    [theDataLock lock];   //-----begin critical section
    [cacheArray addObject:someData];
	dataInCache = YES;
    [theDataLock unlock];   //-----end critical section
}

- (void) addArrayToCache:(NSArray*)aDataArray
{
    [theDataLock lock];   //-----begin critical section
    if(!cacheArray)[self setCacheArray:[NSMutableArray arrayWithCapacity:kMinCapacity]];
    [cacheArray addObjectsFromArray:aDataArray];
	dataInCache = YES;
    [theDataLock unlock];   //-----end critical section
}

- (void) clearData
{
    [theDataLock lock];   //-----begin critical section
    [dataArray removeAllObjects];

	frameIndex = 0;
    reserveIndex = 0;
	
	dataAvailable = NO;
    addedData = NO;
    [theDataLock unlock];   //-----end critical section
}

- (BOOL) addedData
{
    return addedData;
}

- (void) setAddedData:(BOOL)flag
{
    addedData = flag;
}


//------------------------------------------------------------------------------



- (void) decodeIntoDataSet:(ORDataSet*)aDataSet
{
    unsigned n = [dataArray count];
    unsigned i;
    for(i=0;i<n;i++){
        [self decode:[dataArray objectAtIndex:i] intoDataSet:aDataSet];
    }
}

- (void) decode:(NSData*)someData intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long length = [someData length]/sizeof(long);
    unsigned long* dPtr = (unsigned long*)[someData bytes];
	[self decode:dPtr length:length intoDataSet:aDataSet];
}

- (void) decode:(unsigned long*)dPtr length:(unsigned long)length intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long keyMaskValue;
    do {
        if(!dPtr)break;
				
		keyMaskValue = ExtractDataId(*dPtr);
 		
        id anObj = fastLookupCache[keyMaskValue>>18]; //optimization, but dangerous. keyMask must be < kFastLoopupCacheSize
		if(!anObj){
			if(keyMaskValue == 0x0 || keyMaskValue == 0x3C3C){
				//this is the header, maybe the old form, but worry about that in the decoder
				anObj = self;
			}
			else {
				anObj = [objectLookup objectForKey:[NSNumber  numberWithLong:keyMaskValue]];
			}
			fastLookupCache[keyMaskValue>>18] = anObj;
		}
        unsigned long numLong;
        if(!anObj){
			//no decoder defined for this object
            if(version>=2){
				numLong = ExtractLength(*dPtr); //new form--just skip it by getting the length from the header.
				if(numLong == 0){
					NSLogError(@"Data Decoder",@"Zero Packet Length",nil);
					break;
				}
			}
            else break;									//old form--can not decode.
        }
        else numLong = [anObj decodeData:dPtr  fromDataPacket:self intoDataSet:aDataSet];
                
        if(numLong)dPtr+=numLong;
        else break; //can not continue with this record.. size was zero
		
        length-=numLong;
		
    } while( length>0 );
}

- (void) decodeOneRecordAtOffset:(unsigned long)anOffset intoDataSet:(ORDataSet*)aDataSet forKey:(NSNumber*)aKey
{
    NSData* theData = [dataArray objectAtIndex:0];
    unsigned long* dPtr = ((unsigned long*)[theData bytes]) + anOffset;
    if(!dPtr)return;
    id anObj = [objectLookup objectForKey:aKey];
    if(anObj)[anObj decodeData:dPtr  fromDataPacket:self intoDataSet:aDataSet];
}

- (void) byteSwapOneRecordAtOffset:(unsigned long)anOffset intoDataSet:(ORDataSet*)aDataSet forKey:(NSNumber*)aKey
{
	if(needToSwap){
		NSData* theData = [dataArray objectAtIndex:0];
		unsigned long* dPtr = ((unsigned long*)[theData bytes]) + anOffset;
		if(!dPtr)return;
		[[objectLookup objectForKey:aKey] swapData:dPtr];	
	}
}


- (NSString*) dataRecordDescription:(unsigned long)anOffset forKey:(NSNumber*)aKey
{
    NSData* theData = [dataArray objectAtIndex:0];
    unsigned long* dataPtr = ((unsigned long*)[theData bytes]) + anOffset;
    return [[objectLookup objectForKey:aKey] dataRecordDescription:dataPtr];
}


- (void) setStopDecodeIntoArray:(BOOL)state
{
    stopDecodeIntoArray = state;
}

//decode the entire data set into an array. Assumes that the the data array holds only
//one long NSData object.
- (NSArray*) decodeDataIntoArrayForDelegate:(id)aDelegate
{
    
    stopDecodeIntoArray = NO;
    
    NSMutableArray* array;
    NSAutoreleasePool *pool = nil;
    NS_DURING
        array = [NSMutableArray arrayWithCapacity:1024*1000];
        NSData* d = [dataArray objectAtIndex:0];
        NSNumber* aKey;
        long length = [d length]/sizeof(long);
        unsigned long decodedLength;
        unsigned long* dPtr = (unsigned long*)[d bytes];
        unsigned long* start = dPtr;
        unsigned long* end = start + [d length]/4;
        [aDelegate dataPacket:self setTotalLength:length];
        NSMutableDictionary* nameCatalog = [NSMutableDictionary dictionary];
		NSNumber* decodedFlag = [NSNumber numberWithBool:NO];
        do {
            if(stopDecodeIntoArray)break;
            if(!dPtr)break;
            NSAutoreleasePool *innerPool = [[NSAutoreleasePool allocWithZone:nil] init];
            
			id anObj;
			if(version>=2){
			   //get length from the first word.
			   unsigned long val = *dPtr;
			   if(needToSwap)val = CFSwapInt32(val); //if data is from old PPC file, must swap.
				aKey		  = [NSNumber  numberWithLong:ExtractDataId(val)];
				decodedLength = ExtractLength(val);
				anObj		  = [objectLookup objectForKey:aKey];
            }
			
            if(anObj){
                NSString* shortName = [nameCatalog objectForKey:aKey];
                if(!shortName){
                     NSString* sname = [[NSStringFromClass([anObj class]) componentsSeparatedByString:@"DecoderFor"] componentsJoinedByString:@" "];
                    if([sname hasPrefix:@"OR"])     sname = [sname substringFromIndex:2];
                    if([sname hasSuffix:@"Record"]) sname = [sname substringToIndex:[sname length]-6];
                    [nameCatalog setObject:sname forKey:aKey]; 
                    shortName = sname;
                }
                                                                                              
                if(decodedLength){
					if((dPtr+decodedLength) > end){
						NSLog(@"Parser stepped past end of file...\n");
						NSLog(@"Last Record in file appears corrupted:\n");
						NSLog(@"Object Name: %@\n",shortName);
						NSLog(@"Decoded Len: %d\n",decodedLength);
						NSLog(@"Length extends %d bytes past end of file\n",dPtr+decodedLength - end);
						[innerPool release];
						break;
					}
					else {
						unsigned long offset = dPtr - start;
						[array addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithLong:decodedLength],@"Length",
							shortName,@"Name",
							aKey,@"Key",
							decodedFlag,@"DecodedOnce",
							[NSNumber numberWithLong:offset],@"StartingOffset",
							nil]];
						dPtr+=decodedLength;
					}
				}
                else {
					[innerPool release];
					break; //can not continue with this record.. size was zero
				}
                length-=decodedLength;
                
                [aDelegate dataPacket:self setLengthDecoded:length];
            }
            else {
				[innerPool release];
				break;
			}
            [innerPool release];
        } while( length>0 );
    NS_HANDLER
        [array release];
        array = nil;
    NS_ENDHANDLER
    
    [pool release];
    pool = nil;

    return array;
}

//one record decoding
- (void) decodeStart
{
    blockIndex = 0;
    currentDataBlock = [dataArray objectAtIndex:blockIndex];
    dataOffset = 0;
}


- (BOOL) decodeFileFinished
{
    return blockIndex >= [dataArray count];
}
- (void)  setVersion:(int)aVersion
{
    version=aVersion;
}
- (int)  version
{
    return version;
}
- (BOOL) needToSwap
{
	return needToSwap;
}

#pragma mark •••File I/O
- (NSFileHandle*) createFileFromHeader: (NSString*)path
{
    [fileHeader writeToFile:path atomically:YES];
    NSFileHandle* fp = [NSFileHandle fileHandleForWritingAtPath:path];
    [fp seekToEndOfFile];
    
    return fp;
}

- (NSData*) headerAsData
{
    //write header to temp file because we want the form you get from a disk file...the string to property list isn't right.
    char* name = tempnam([[@"~" stringByExpandingTildeInPath]cStringUsingEncoding:NSASCIIStringEncoding] ,"OrcaHeaderXXX");
    [self createFileFromHeader:[NSString stringWithCString:name]];
    NSData* dataBlock = [NSData dataWithContentsOfFile:[NSString stringWithCString:name]];
	unsigned long headerLength        = [dataBlock length];											//in bytes
	unsigned long lengthWhenPadded    = sizeof(long)*(round(.5 + headerLength/(float)sizeof(long)));					//in bytes
	unsigned long padSize             = lengthWhenPadded - headerLength;							//in bytes
	unsigned long totalLength		  = 2 + (lengthWhenPadded/4);									//in longs
	unsigned long theHeaderWord = 0 | (0x1ffff & totalLength);										//compose the header word
	NSMutableData* data = [NSMutableData dataWithBytes:&theHeaderWord length:sizeof(long)];			//add the header word
	[data appendBytes:&headerLength length:sizeof(long)];											//add the header len in bytes
	
	[data appendData:dataBlock];
	
	//pad to nearest long word
	unsigned char padByte = 0;
	int i;
	for(i=0;i<padSize;i++){
		[data appendBytes:&padByte length:1];
	}
	
    [[NSFileManager defaultManager] removeFileAtPath:[NSString stringWithCString:name] handler:nil];
    
    free(name);
    return data;
}

- (BOOL) legalDataFile: (NSFileHandle*)fp
{
	NSData* someData = [fp readDataOfLength:100];
	unsigned long* p = (unsigned long*)[someData bytes];
	needToSwap = NO;
	unsigned long theDataId;
	if((*p & 0xffff0000) == 0x3C3F0000){
		//old style header with no orca header info, just starts "<?xm" which is 0x3c3f
		//ascii does need to be swapped so it's not clear if this was written on a big endian mac or a little endian mac
		//however, this style was ONLY produced on a big endian mac so that is what we will assume...
		return YES;
	}
	if((*p & 0x0000ffff) == 0x00003f3c){
		//old style header with no orca header info, just starts "<?xm" which is 0x3c3f (but swapped here)
		//ascii does need to be swapped so it's not clear if this was written on a big endian mac or a little endian mac
		//however, this style was ONLY produced on a big endian mac so that is what we will assume...
		needToSwap = YES;
		return YES;
	}
	if((*p & 0xffff0000) != 0x0000){
		//the dataID for the header is always zero the length of the record is always non-zero -- this
		//gives us a way to determine endian-ness 
		needToSwap = YES;
		theDataId = ExtractDataId(CFSwapInt32(*p));	
	}
	else theDataId = ExtractDataId(*p);	

	
	if(theDataId == 0x00000000){
		p++;	//in valid file the second word is the length
		p++;	//third word should be start of xml header
		NSString* headerString = [[[NSString alloc] initWithBytes:p length:50 encoding:NSASCIIStringEncoding] autorelease];
		if([headerString rangeOfString:@"xml"].location != NSNotFound){
			return YES;
		}
		else return NO;
	}
	else return NO;
}


- (BOOL) readDataBytes: (NSFileHandle*)fp
{
	[self addData:[fp readDataToEndOfFile]];
	return  YES;
}

- (BOOL) readBeginData: (NSFileHandle*)fp
{
    NSString* dataBegin = getNextString(fp); //read the "BeginData" string.
    if(![dataBegin isEqualTo:@"BeginData"])return NO;
    else return YES;
}

- (BOOL) readDataRecord: (NSFileHandle*)fp
{
    NSMutableData* theFinalData = [NSMutableData dataWithCapacity:35000];
    NSData* theData;
    unsigned long data;
    //first the first long
    theData = [fp readDataOfLength:4];
    if([theData length]){
        [theFinalData appendData:theData];
        
        //use it to get the size
        data = *((unsigned long*)[theData bytes]);
        int numLongsLeft = [self getExpectedDataLength:data] - 1;//already read in the first long
        if(numLongsLeft > 0){
            [theFinalData appendData:[fp readDataOfLength:numLongsLeft*sizeof(long)]];
        }
        [self addData:theFinalData];
        return YES;
    }
    else return NO;
}


- (long) getExpectedDataLength:(unsigned long)data
{
	return ExtractLength(data);
}

- (BOOL) readData: (NSFileHandle*)fp
{
    if(![self readHeader:fp])return NO;
    if(![self readDataBytes:fp])return NO;
    return YES;
}


- (void) writeData: (NSFileHandle*)fp
{
    //write the data itself
    int i;
    int n = [dataArray count];
    for(i=0;i<n;i++){
        [fp writeData:[dataArray objectAtIndex:i]];
    }
}

#pragma mark •••Archival
static NSString *ORDataPacketFilePrefix         = @"ORDataPacketFilePrefix";
static NSString *ORDataPacketObjectLookup       = @"ORDataPacketObjectLookup";
static NSString *ORDataPacketDataArray          = @"ORDataPacketDataArray";
static NSString *ORDataPacketCacheArray         = @"ORDataPacketCacheArray";
static NSString *ORDataPacketVersion            = @"ORDataPacketVersion";
static NSString *ORDataPacketFileHeader        = @"ORDataPacketFileHeader";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [self setFilePrefix: [decoder decodeObjectForKey:ORDataPacketFilePrefix]];
    [self setObjectLookup: [decoder decodeObjectForKey:ORDataPacketObjectLookup]];
    [self setDataArray: [decoder decodeObjectForKey:ORDataPacketDataArray]];
    [self setCacheArray: [decoder decodeObjectForKey:ORDataPacketCacheArray]];
    [self setCacheArray: [decoder decodeObjectForKey:ORDataPacketCacheArray]];
    [self setVersion: [decoder decodeIntForKey:ORDataPacketVersion]];
    [self setFileHeader: [decoder decodeObjectForKey:ORDataPacketFileHeader]];
    
    theDataLock         = [[NSRecursiveLock alloc] init];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:filePrefix forKey:ORDataPacketFilePrefix];
    [encoder encodeObject:dataArray forKey:ORDataPacketDataArray];
    [encoder encodeInt:version forKey:ORDataPacketVersion];
    [encoder encodeObject:fileHeader forKey:ORDataPacketFileHeader];
}


- (unsigned long) readXMLHeader: (NSFileHandle*)fp
{
    [fp seekToFileOffset:0];
	NSData* firstTwoLongs = [fp readDataOfLength:8];
	unsigned long* ptr = (unsigned long*)[firstTwoLongs bytes];
	if(needToSwap)*ptr = CFSwapInt32(*ptr);
	unsigned long theDataId = ExtractDataId(*ptr);
	if(theDataId == 0){
		unsigned long totalHeaderLength = ExtractLength(*ptr);
		ptr++;
		if(needToSwap)*ptr = CFSwapInt32(*ptr);
		unsigned long headerLengthInBytes = *ptr;
		ptr++;
		NSData* headerData = [fp readDataOfLength:headerLengthInBytes];
		NSString* headerString = [[[NSString alloc] initWithBytes:[headerData bytes] length:headerLengthInBytes encoding:NSASCIIStringEncoding]autorelease];
		[self setFileHeader:[headerString propertyList]]; 
		[fp seekToFileOffset:totalHeaderLength*sizeof(long)];
	}
	else if(theDataId == 0x3C3C0000){
		//old form...depreciated. Remove in a few years...
		[fp seekToFileOffset:0];
		NSString* aString = [NSString string];
		while(1){
			NSData* someData = [fp readDataOfLength:10000];
			if(!someData)return NO;
			NSString* piece = [[[NSString alloc] initWithBytes:[someData bytes] length:[someData length] encoding:NSASCIIStringEncoding]autorelease];
			aString = [aString stringByAppendingString:piece];
			NSRange range = [aString rangeOfString:@"</plist>"];
			if(range.location!=NSNotFound){
				aString = [aString substringWithRange: NSMakeRange(0,range.location+[@"</plist>" length]+1)];
				break;
			}
		}
		[self setFileHeader:[aString propertyList]]; 
		[fp seekToFileOffset:[aString length]];
	}
    NSDictionary* docinfo = [fileHeader objectForKey:@"Document Info"];
    [self setVersion:[[docinfo objectForKey:@"dataVersion"] intValue]];
       
    return fileHeader!=nil;
}

- (id) fileDetails
{
    return fileHeader;
}
- (void) generateObjectLookup
{
	int i;
	for(i=0;i<kFastLoopupCacheSize;i++){
		fastLookupCache[i] = 0;
	}
    [self setObjectLookup:[NSMutableDictionary dictionaryWithCapacity:100]];
	[self generateXMLLookup];
}

- (BOOL) readHeader: (NSFileHandle*)fp
{
	return [self readXMLHeader:fp];
}

//decoder for the header
-(unsigned long)decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
	//only get here if the data is a data header
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long val = *ptr;

	unsigned long theDataId = ExtractDataId(val);
	
	if(theDataId == 0x0) {		//great, this is easy... it's the new form
		unsigned long theLength = ExtractLength(val);
		return theLength;
	}
	else {	//crap -- old form.... eventually we'll depreciate this form	
		//shouldn't get here using the old form but just in case...
		return 0; //just to show we couldn't process.
	}
}

@end
