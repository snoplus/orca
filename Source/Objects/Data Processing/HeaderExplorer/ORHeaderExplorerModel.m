//
//  ORHeaderExplorerModel.m
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
#import "ORHeaderExplorerModel.h"
#import "ORDataPacket.h"
#import "ORStatusController.h"
#import "ORDataTaker.h"
#import "ORDataPacket.h"
#import "ORHeaderItem.h"
#import "ORHistoModel.h"
#import "ThreadWorker.h"

#pragma mark •••Notification Strings
NSString* ORHeaderExplorerListChangedNotification		= @"ORHeaderExplorerListChangedNotification";
NSString* ORHeaderExplorerAtEndNotification				= @"ORHeaderExplorerAtEndNotification";
NSString* ORHeaderExplorerInProgressNotification		= @"ORHeaderExplorerInProgressNotification";
NSString* ORHeaderExplorerSelectionDateNotification		= @"ORHeaderExplorerSelectionDateNotification";
NSString* ORHeaderExplorerRunningNotification			= @"ORHeaderExplorerRunningNotification";
NSString* ORHeaderExplorerStoppedNotification			= @"ORHeaderExplorerStoppedNotification";
NSString* ORHeaderExplorerProcessingEndedNotification	= @"ORHeaderExplorerProcessingEndedNotification";
NSString* ORHeaderExplorerReadingNotification			= @"ORHeaderExplorerReadingNotification";
NSString* ORHeaderExplorerRunSelectionChanged			= @"ORHeaderExplorerRunSelectionChanged";
NSString* ORHeaderExplorerOneFileDoneNotification		= @"ORHeaderExplorerOneFileDoneNotification";

#pragma mark •••Definitions

@interface ORHeaderExplorerModel (private)
- (void) processFinished;
- (void) fileFinished;
@end


@implementation ORHeaderExplorerModel

#pragma mark •••Initialization
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
	
    [filesToProcess release];
    [fileAsDataPacket release];
	[fileToProcess release];
	[runArray release];
    [dataRecords release];

    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"HeaderExplorer"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORHeaderExplorerController"];
}

#pragma mark •••Accessors
- (int) selectedRunIndex
{
	return selectedRunIndex;
}

- (void) setSelectedRunIndex:(int)anIndex
{
	if(anIndex!=selectedRunIndex){
		selectedRunIndex = anIndex;
		[[NSNotificationCenter defaultCenter]
			postNotificationName:ORHeaderExplorerRunSelectionChanged
				object: self];
	}
	if(anIndex<0)[self setHeader: nil];
}


- (int) selectionDate
{
	return selectionDate;
}

- (void) setSelectionDate:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectionDate:selectionDate];

    selectionDate = aValue;
	
	[self findSelectedRun];
	
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORHeaderExplorerSelectionDateNotification
                              object: self];
}

- (unsigned long)   total
{
	return [filesToProcess count];
}

- (unsigned long)   numberLeft
{
	return numberLeft;
}

- (NSDictionary*) runDictionaryForIndex:(int)index
{
	if(index>=0 && index<[runArray count]){
		return [runArray objectAtIndex:index];
	}
	else return nil;
}

- (id) dataRecordAtIndex:(int)index
{
    return [dataRecords objectAtIndex:index];
}

- (ORDataPacket*) fileAsDataPacket
{
    return fileAsDataPacket;
}

- (NSString*) fileToProcess
{
    if(fileToProcess)return fileToProcess;
    else return @"";
}

- (void) setFileToProcess:(NSString*)newFileToProcess
{    
    [fileToProcess autorelease];
    fileToProcess=[newFileToProcess retain];
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

- (NSArray*) filesToProcess
{
    return filesToProcess;
}

- (void) addFilesToProcess:(NSMutableArray*)newFilesToProcess
{
    
    if(!filesToProcess){
        filesToProcess = [[NSMutableArray array] retain];
    }
    
    [[[self undoManager] prepareWithInvocationTarget:self] removeFiles:newFilesToProcess];
    
    
    //remove dups
    NSEnumerator* newListEnummy = [newFilesToProcess objectEnumerator];
    id newFileName;
    while(newFileName = [newListEnummy nextObject]){
        NSEnumerator* oldListEnummy = [filesToProcess objectEnumerator];
        id oldFileName;
        while(oldFileName = [oldListEnummy nextObject]){
            if([oldFileName isEqualToString:newFileName]){
                [filesToProcess removeObject:oldFileName];
                break;
            }
        }
        
    }
    
    [filesToProcess addObjectsFromArray:newFilesToProcess];
    [filesToProcess sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORHeaderExplorerListChangedNotification
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

- (BOOL)isProcessing
{
    return reading;
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

- (void) findSelectedRun
{
	int index;
	BOOL valid = NO;
	int n = [runArray count];
	unsigned long actualDate	= minRunStartTime + ((maxRunEndTime - minRunStartTime) * (selectionDate/1000.));
	for(index=0;index<n;index++){
		NSDictionary* runDictionary = [runArray objectAtIndex:index];
		unsigned long start = [[runDictionary objectForKey:@"RunStart"] unsignedLongValue];
		unsigned long end   = [[runDictionary objectForKey:@"RunEnd"] unsignedLongValue];
		if(actualDate >= start && actualDate < end){
			[self setSelectedRunIndex: index];
			[self setHeader: [runDictionary objectForKey:@"FileHeader"]];
			valid = YES;
			break;
		}
	}
	if(!valid){
		[self setHeader: nil];
		[self setSelectedRunIndex: -1];
	}
}

- (unsigned long) minRunStartTime {return minRunStartTime;}
- (unsigned long) maxRunEndTime	  {return maxRunEndTime;}
- (long) numberRuns {return [runArray count];}
- (id) run:(int)index objectForKey:(id)aKey
{
	if(index<[runArray count]){
		return [[runArray objectAtIndex:index] objectForKey:aKey];
	}
	else return 0;
}

#pragma mark •••File Actions

- (void) removeAll
{
    [filesToProcess removeAllObjects];
}

- (void) readHeaders
{

	if([self isProcessing]) return;

	[runArray release];
	runArray = [[NSMutableArray array] retain];
	
	reading = YES;
	stop = NO;
	numberLeft = [filesToProcess count];
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORHeaderExplorerRunningNotification
                              object: self];

	sentRunStart = NO;
    
    [self setDataRecords:nil];
    [self setHeader:nil];
    
    if(fileAsDataPacket)[fileAsDataPacket release];
    fileAsDataPacket = [[ORDataPacket alloc] init];

	minRunStartTime = 0xffffffff;
	maxRunEndTime = 0;
    currentFileIndex = 0;
	if ([filesToProcess count]){
		[self performSelector:@selector(readNextFile) withObject:nil afterDelay:.1];
	}
}

- (void) removeFiles:(NSMutableArray*)anArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] addFilesToProcess:anArray];
    [filesToProcess removeObjectsInArray:anArray];
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORHeaderExplorerListChangedNotification
                              object: self];
}

- (void) removeFilesWithIndexes:(NSIndexSet*)indexSet;
{

    NSMutableArray* filesToRemove = [NSMutableArray array];
	unsigned current_index = [indexSet firstIndex];
    while (current_index != NSNotFound){
		[filesToRemove addObject:[filesToProcess objectAtIndex:current_index]];
        current_index = [indexSet indexGreaterThanIndex: current_index];
    }
	if([filesToRemove count]){
		[[[self undoManager] prepareWithInvocationTarget:self] addFilesToProcess:filesToRemove];
		[filesToProcess removeObjectsInArray:filesToRemove];
    
    
		[[NSNotificationCenter defaultCenter]
			    postNotificationName:ORHeaderExplorerListChangedNotification
                              object: self];
	}
}


- (void) stopProcessing
{
	stop = YES;
    //[self processFinished];
    NSLog(@"Header Explorer stopped manually\n");
}

//-----
#pragma mark •••File Actions

- (void) readNextFile
{
	if(!stop && currentFileIndex < [filesToProcess count]){
		id aFile = [filesToProcess objectAtIndex:currentFileIndex];
		
		[self setFileToProcess:aFile];

		NSFileHandle* fp = [NSFileHandle fileHandleForReadingAtPath:aFile];

		[dataRecords release];
		dataRecords = nil;
		[fileAsDataPacket clearData];
		if(fp){
		
			unsigned long runStart  = 0;
			unsigned long runEnd    = 0;
			unsigned long runNumber = 0;
			
			if([fileAsDataPacket readHeaderReturnRunLength:fp runStart:&runStart runEnd:&runEnd runNumber:&runNumber]){
				[[NSNotificationCenter defaultCenter]
					postNotificationName:ORHeaderExplorerReadingNotification
								  object: self];
				if(runStart!=0 && runEnd!=0){
					if(runStart < minRunStartTime) minRunStartTime = runStart;
					if(runEnd > maxRunEndTime)     maxRunEndTime   = runEnd;
					[fp seekToEndOfFile];
					
					[runArray addObject:
						[NSMutableDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithUnsignedLong:runStart],			@"RunStart",
							[NSNumber numberWithUnsignedLong:runEnd],			@"RunEnd",
							[NSNumber numberWithUnsignedLong:runEnd-runStart],	@"RunLength",
							[NSNumber numberWithUnsignedLong:runNumber],		@"RunNumber",
							[NSNumber numberWithUnsignedLong:[fp offsetInFile]],	@"FileSize",
							[ORHeaderItem headerFromObject:[fileAsDataPacket fileHeader] named:@"Root"], @"FileHeader",
							nil
						]
					];
					
					[self fileFinished];
				}
				else NSLogColor([NSColor redColor],@"Problem reading <%@> for exploring.\n",[aFile stringByAbbreviatingWithTildeInPath]);
			}
			else NSLogColor([NSColor redColor],@" <%@> doesn't appear to be a legal ORCA data file.\n",[aFile stringByAbbreviatingWithTildeInPath]);
		}
		else NSLogColor([NSColor redColor],@"Could NOT Open <%@> for exploring.\n",[aFile stringByAbbreviatingWithTildeInPath]);
		currentFileIndex++;
		[self performSelector:@selector(readNextFile) withObject:nil afterDelay:.01];
	}
	else {
		reading = NO;
		[self processFinished];
	
		[[NSNotificationCenter defaultCenter]
			    postNotificationName:ORHeaderExplorerProcessingEndedNotification
                              object: self];
	}
}

#pragma mark •••Archival
static NSString* ORHeaderExplorerList 			= @"ORHeaderExplorerList";
static NSString* ORLastListPath 			= @"ORLastListPath";
static NSString* ORLastFilePath 			= @"ORLastFilePath";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
	[[self undoManager] disableUndoRegistration];
	[self addFilesToProcess:[decoder decodeObjectForKey:ORHeaderExplorerList]];
	[self setLastListPath:[decoder decodeObjectForKey:ORLastListPath]];
	[self setLastFilePath:[decoder decodeObjectForKey:ORLastFilePath]];
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:filesToProcess forKey:ORHeaderExplorerList];
    [encoder encodeObject:lastListPath forKey:ORLastListPath];
    [encoder encodeObject:lastFilePath forKey:ORLastFilePath];
    
}

@end

@implementation ORHeaderExplorerModel (private)
- (void) processFinished
{
    [self fileFinished];
    
    [nextObject runTaskStopped:fileAsDataPacket userInfo:nil];
    [nextObject closeOutRun:fileAsDataPacket userInfo:nil];

	[fileAsDataPacket clearData];
    [fileAsDataPacket release];
    fileAsDataPacket = nil;
	
    [self setDataRecords:nil];
	      
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORHeaderExplorerStoppedNotification
                              object: self];

}

- (void) fileFinished
{
    [nextObject runTaskBoundary:fileAsDataPacket userInfo:nil];
	numberLeft--;
	    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORHeaderExplorerOneFileDoneNotification
                              object: self];

}



@end

