//
//  ORReplayDataModel.m
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
#import "ORReplayDataModel.h"
#import "ORDataPacket.h"
#import "ORStatusController.h"
#import "ORDataTaker.h"
#import "ORDataPacket.h"
#import "ORHeaderItem.h"
#import "ORHistoModel.h"
#import "ThreadWorker.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORReplayFileListChangedNotification = @"ORReplayFileListChangedNotification";
NSString* ORReplayFileAtEndNotification       = @"ORReplayFileAtEndNotification";
NSString* ORReplayFileInProgressNotification  = @"ORReplayFileInProgressNotification";


NSString* ORReplayRunningNotification		  = @"ORReplayRunningNotification";
NSString* ORReplayStoppedNotification		  = @"ORReplayStoppedNotification";
NSString* ORRelayParseStartedNotification		= @"ORRelayParseStartedNotification";
NSString* ORRelayParseEndedNotification			= @"ORRelayParseEndedNotification";
NSString* ORRelayFileChangedNotification		= @"ORRelayFileChangedNotification";
NSString* ORReplayReadingNotification			= @"ORReplayReadingNotification";
NSString* ORReplayParseStartedNotification		= @"ORReplayParseStartedNotification";
NSString* ORReplayProcessingStartedNotification	= @"ORReplayProcessingStartedNotification";

#pragma mark ¥¥¥Definitions
static NSString *ORReplayDataConnection = @"Replay File Input Connector";

@interface ORReplayDataModel (private)
- (void) replayFinished;
- (void) fileFinished;
@end


@implementation ORReplayDataModel

#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}


- (void) dealloc
{
    [lastListPath release];
	[lastFilePath release];
	
    [filesToReplay release];
    [fileAsDataPacket release];
	[fileToReplay release];
	
    [dataRecords release];

    [super dealloc];
}

- (void) makeConnectors
{
	ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,30) withGuardian:self withObjectLink:self];
	[[self connectors] setObject:aConnector forKey:ORReplayDataConnection];
	[aConnector release];
}


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"ReplayData"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORReplayDataController"];
}

#pragma mark ¥¥¥Accessors
- (unsigned long)   totalLength
{
	return totalLength;
}

- (unsigned long)   lengthDecoded
{
	return lengthDecoded;
}


- (id) dataRecordAtIndex:(int)index
{
    return [dataRecords objectAtIndex:index];
}

- (ORDataPacket*) fileAsDataPacket
{
    return fileAsDataPacket;
}

- (NSString*) fileToReplay
{
    if(fileToReplay)return fileToReplay;
    else return @"";
}

- (void) setFileToReplay:(NSString*)newFileToReplay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFileToReplay:fileToReplay];
    
    [fileToReplay autorelease];
    fileToReplay=[newFileToReplay retain];
    
	NSLog(@"Replaying: %@\n",[newFileToReplay  stringByAbbreviatingWithTildeInPath]);
	
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORRelayFileChangedNotification
                              object: self];
    
}
- (NSArray *) dataRecords
{
    return dataRecords; 
}

- (void) setDataRecords: (NSArray *) aDataRecords
{
    [aDataRecords retain];
    [dataRecords release];
    dataRecords = aDataRecords;
}

- (NSArray*) filesToReplay
{
    return filesToReplay;
}

- (void) addFilesToReplay:(NSMutableArray*)newFilesToReplay
{
    
    if(!filesToReplay){
        filesToReplay = [[NSMutableArray array] retain];
    }
    
    [[[self undoManager] prepareWithInvocationTarget:self] removeFiles:newFilesToReplay];
    
    
    //remove dups
    NSEnumerator* newListEnummy = [newFilesToReplay objectEnumerator];
    id newFileName;
    while(newFileName = [newListEnummy nextObject]){
        NSEnumerator* oldListEnummy = [filesToReplay objectEnumerator];
        id oldFileName;
        while(oldFileName = [oldListEnummy nextObject]){
            if([oldFileName isEqualToString:newFileName]){
                [filesToReplay removeObject:oldFileName];
                break;
            }
        }
        
    }
    
    [filesToReplay addObjectsFromArray:newFilesToReplay];
    [filesToReplay sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORReplayFileListChangedNotification
                              object: self];
    
}

- (ORHeaderItem *)header
{
    return header; 
}

- (void)setHeader:(ORHeaderItem *)aHeader
{
    [aHeader retain];
    [header release];
    header = aHeader;
}

- (BOOL)isReplaying
{
    return parseThread!=nil;
}

- (NSString *) lastListPath
{
    return lastListPath; 
}

- (void) setLastListPath: (NSString *) aLastListPath
{
    [lastListPath release];
    lastListPath = [aLastListPath copy];
}

- (NSString *) lastFilePath
{
    return lastFilePath;
}
- (void) setLastFilePath: (NSString *) aSetLastListPath
{
    [lastFilePath release];
    lastFilePath = [aSetLastListPath copy];
}


#pragma mark ¥¥¥File Actions

- (void) removeAll
{
    [filesToReplay removeAllObjects];
}

- (void) replayFiles
{

	if([self isReplaying]) return;
	stop = NO;
	
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayRunningNotification
                              object: self];

	sentRunStart = NO;

	[self parseFile];
	
}

- (void) sendRunStart:(ORDataPacket*)aDataPacket
{
	nextObject = [self objectConnectedTo:ORReplayDataConnection];
    [nextObject runTaskStarted:aDataPacket userInfo:nil];
}

- (void) readHeaderForFileIndex:(int)index
{
    if(index>=0 && [filesToReplay count]){
        NSString* aFileName = [filesToReplay objectAtIndex:index];
        NSFileHandle* fp = [NSFileHandle fileHandleForReadingAtPath:aFileName];
        
        if(fp){
            ORDataPacket* aDataPacket = [[ORDataPacket alloc] init];
            if([aDataPacket legalDataFile:fp]){
				if([aDataPacket readHeader:fp]){
					[self setHeader:[ORHeaderItem headerFromObject:[aDataPacket fileHeader] named:@"Root"]];
				}
				else {
					NSLogColor([NSColor redColor],@"Problem reading header for <%@>.\n",aFileName);
				}
			}
            [aDataPacket release];
        }
        else {
            NSLogColor([NSColor redColor],@"Could NOT Open <%@> for replay.\n",aFileName);
        }
    }
    else [self setHeader:nil];
}

- (void) removeFiles:(NSMutableArray*)anArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] addFilesToReplay:anArray];
    [filesToReplay removeObjectsInArray:anArray];
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORReplayFileListChangedNotification
                              object: self];
}

- (void) removeFilesWithIndexes:(NSIndexSet*)indexSet;
{
    NSMutableArray* filesToRemove = [NSMutableArray array];
	unsigned current_index = [indexSet firstIndex];
    while (current_index != NSNotFound)
    {
		[filesToRemove addObject:[filesToReplay objectAtIndex:current_index]];
        current_index = [indexSet indexGreaterThanIndex: current_index];
    }
	if([filesToRemove count]){
		[[[self undoManager] prepareWithInvocationTarget:self] addFilesToReplay:filesToRemove];
		[filesToReplay removeObjectsInArray:filesToRemove];
    
    
		[[NSNotificationCenter defaultCenter]
			    postNotificationName:ORReplayFileListChangedNotification
                              object: self];
	}
}


- (void) stopReplay
{
	stop = YES;
    [fileAsDataPacket setStopDecodeIntoArray:YES];
    //[self replayFinished];
    NSLog(@"Replay stopped manually\n");
}

//-----
#pragma mark ¥¥¥File Actions
- (void) dataPacket:(id)aDataPacket setTotalLength:(unsigned)aLength
{
    if(aDataPacket == fileAsDataPacket){
        totalLength = aLength;
    }
}
- (void) dataPacket:(id)aDataPacket setLengthDecoded:(unsigned)aLength
{
    if(aDataPacket == fileAsDataPacket){
		lengthDecoded = aLength;    
	}    
}

- (BOOL) parseInProgress
{
    return parseThread != nil;
}
- (void) stopParse
{
    [fileAsDataPacket setStopDecodeIntoArray:YES];
}

- (void) parseFile
{
    if(parseThread)return;
    
    totalLength   = 0;
    lengthDecoded = 0;
    [self setDataRecords:nil];
    //[self setHeader:nil];
    
    if(fileAsDataPacket)[fileAsDataPacket release];
    fileAsDataPacket = [[ORDataPacket alloc] init];
    
    
    parseThread = [[ThreadWorker workOn:self withSelector:@selector(parse:thread:)
                             withObject:nil
                         didEndSelector:@selector(parseThreadExited:)] retain];
    
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORRelayParseStartedNotification
                              object: self];
    
    if(!parseThread){
        [self parseThreadExited:nil];
    }
}


-(id) parse:(id)userInfo thread:(id)tw
{
	NSEnumerator* e = [filesToReplay objectEnumerator];
	id aFile;
	while(aFile = [e nextObject]){
		if(stop)break;
		
		[self performSelectorOnMainThread:@selector(setFileToReplay:) withObject:aFile waitUntilDone:YES];

		NSAutoreleasePool *pool = [[NSAutoreleasePool allocWithZone:nil] init];
		NSFileHandle* fp = [NSFileHandle fileHandleForReadingAtPath:aFile];
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:.001]];
		[dataRecords release];
		dataRecords = nil;
		[fileAsDataPacket clearData];
		if(fp){
			if([fileAsDataPacket legalDataFile:fp]){
				[self performSelectorOnMainThread:@selector(postReadStarted) withObject:nil waitUntilDone:NO];
				if([fileAsDataPacket readData:fp]){
					[self performSelectorOnMainThread:@selector(postParseStarted) withObject:nil waitUntilDone:NO];
					[fileAsDataPacket generateObjectLookup];       //MUST be done before data header will work.
					
					if(!sentRunStart){
						[self performSelectorOnMainThread:@selector(sendRunStart:) withObject:fileAsDataPacket waitUntilDone:YES];
						sentRunStart = YES;
					}
					
					[self setDataRecords:[fileAsDataPacket decodeDataIntoArrayForDelegate:self]]; 
					
					[self performSelectorOnMainThread:@selector(postProcessingStarted) withObject:nil waitUntilDone:NO];
					NS_DURING
						[self processData];
						[self performSelectorOnMainThread:@selector(fileFinished) withObject:nil waitUntilDone:YES];
					NS_HANDLER
						stop = true;
					NS_ENDHANDLER
				}
				else {
					NSLogColor([NSColor redColor],@"Problem reading <%@> for replaying.\n",[aFile stringByAbbreviatingWithTildeInPath]);
				}
			}
			else {
				NSLogColor([NSColor redColor],@" <%@> doesn't appear to be a legal ORCA data file.\n",[aFile stringByAbbreviatingWithTildeInPath]);
			}
		}
		else {
			NSLogColor([NSColor redColor],@"Could NOT Open <%@> for replaying.\n",[aFile stringByAbbreviatingWithTildeInPath]);
		}
		[pool release];
	}

    return @"done";
}

-(void)parseThreadExited:(id)userInfo
{
    [self replayFinished];
	
    [parseThread release];
    parseThread = nil;
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORRelayParseEndedNotification
                              object: self];
    
}

- (void) postReadStarted
{
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORReplayReadingNotification
                              object: self];
}

- (void) postParseStarted
{
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORReplayParseStartedNotification
                              object: self];
}

- (void) postProcessingStarted
{
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORReplayProcessingStartedNotification
                              object: self];
}
- (void) processData
{
    unsigned long num = [dataRecords count];
	totalLength   = num;
	lengthDecoded = 0;
	//make a dataPacket for transfering, use a copy of our packet but make it small
	NSMutableArray* tempData = [[fileAsDataPacket dataArray] retain];
	[fileAsDataPacket setDataArray:nil];
	ORDataPacket* tempPacket = [fileAsDataPacket copy];
	[tempPacket setNeedToSwap:[fileAsDataPacket needToSwap]];
	[fileAsDataPacket setDataArray: tempData];
	[tempData release];
	
	[tempPacket generateObjectLookup]; 
		
	[tempPacket addData:[tempPacket headerAsData]];
	[nextObject processData:tempPacket userInfo:nil];
	[tempPacket clearData];
	
    NSAutoreleasePool *pool = nil;
	NSArray* theDataArray = [fileAsDataPacket dataArray];
	NSData* theData = [theDataArray objectAtIndex:0];

	unsigned long* startPtr = ((unsigned long*)[theData bytes]);
	unsigned long* endPtr   = startPtr + [theData length]/4;
	
	unsigned long i;
    for(i=0;i<num;i++){
        if(pool== nil) pool = [[NSAutoreleasePool allocWithZone:nil] init];
		NSMutableDictionary* dataDictionary = [dataRecords objectAtIndex:i];
		unsigned long anOffset = [[dataDictionary objectForKey:@"StartingOffset"] longValue];
		unsigned long aLength = [[dataDictionary objectForKey:@"Length"] longValue];
		
		unsigned long* dPtr = ((unsigned long*)[theData bytes]) + anOffset;
		if(!dPtr)break;
		if(dPtr+aLength <=  endPtr){
		    id aKey = [dataDictionary objectForKey:@"Key"];
			[tempPacket byteSwapData:dPtr forKey:aKey];
			[tempPacket addData:[NSData dataWithBytes:dPtr length:aLength*sizeof(long)]];
			[nextObject processData:tempPacket userInfo:nil];
			[tempPacket clearData];
		}
		else {
			NSLog(@"Replay ended early: data pointer stepped past %d bytes past end of file\n",dPtr+aLength - endPtr);
			NSLog(@"Looks like something is corrupted\n");
			NSLog(@"Last %d words of file not processed\n",endPtr - dPtr);
			break;
		}
		lengthDecoded = num-i;
		if(!(i % 10000)){
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
			[pool release];
			pool = nil;
		}
		if(stop)break;
    }
    [pool release];
}


#pragma mark ¥¥¥Archival
static NSString* ORReplayFileList 			= @"ORReplayFileList";
static NSString* ORLastListPath 			= @"ORLastListPath";
static NSString* ORLastFilePath 			= @"ORLastFilePath";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
	[[self undoManager] disableUndoRegistration];
	[self addFilesToReplay:[decoder decodeObjectForKey:ORReplayFileList]];
	[self setLastListPath:[decoder decodeObjectForKey:ORLastListPath]];
	[self setLastFilePath:[decoder decodeObjectForKey:ORLastFilePath]];
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:filesToReplay forKey:ORReplayFileList];
    [encoder encodeObject:lastListPath forKey:ORLastListPath];
    [encoder encodeObject:lastFilePath forKey:ORLastFilePath];
    
}

@end

@implementation ORReplayDataModel (private)


- (void) replayFinished
{
    [self fileFinished];
    
    [nextObject runTaskStopped:fileAsDataPacket userInfo:nil];
    [nextObject closeOutRun:fileAsDataPacket userInfo:nil];

	[fileAsDataPacket clearData];
    [fileAsDataPacket release];
    fileAsDataPacket = nil;
	
    [self setDataRecords:nil];
	      
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORReplayStoppedNotification
                              object: self];

}

- (void) fileFinished
{
    [nextObject runTaskBoundary:fileAsDataPacket userInfo:nil];
}



@end

