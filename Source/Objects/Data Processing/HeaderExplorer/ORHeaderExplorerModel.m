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
#import "ORDataTaker.h"
#import "ORDataPacket.h"
#import "ORHeaderItem.h"

#pragma mark •••Notification Strings
NSString* ORHeaderExplorerUseFilterChanged		= @"ORHeaderExplorerUseFilterChanged";
NSString* ORHeaderExplorerSearchKeyChanged		= @"ORHeaderExplorerSearchKeyChanged";
NSString* ORHeaderExplorerAutoProcessChanged	= @"ORHeaderExplorerAutoProcessChanged";
NSString* ORHeaderExplorerListChanged			= @"ORHeaderExplorerListChanged";

NSString* ORHeaderExplorerProcessing			= @"ORHeaderExplorerProcessing";
NSString* ORHeaderExplorerProcessingFinished	= @"ORHeaderExplorerProcessingFinished";
NSString* ORHeaderExplorerProcessingFile		= @"ORHeaderExplorerProcessingFile";
NSString* ORHeaderExplorerOneFileDone			= @"ORHeaderExplorerOneFileDone";

NSString* ORHeaderExplorerSelectionDate			= @"ORHeaderExplorerSelectionDate";
NSString* ORHeaderExplorerRunSelectionChanged	= @"ORHeaderExplorerRunSelectionChanged";
NSString* ORHeaderExplorerHeaderChanged			= @"ORHeaderExplorerHeaderChanged";

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
    [searchKey release];
    [lastListPath release];
	[lastFilePath release];
	
    [filesToProcess release];
    [fileAsDataPacket release];
	[fileToProcess release];
	[runArray release];

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

- (BOOL) useFilter
{
    return useFilter;
}

- (void) setUseFilter:(BOOL)aUseFilter
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseFilter:useFilter];
    
    useFilter = aUseFilter;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHeaderExplorerUseFilterChanged object:self];
}

- (NSString*) searchKey
{
    return searchKey;
}

- (void) setSearchKey:(NSString*)aSearchKey
{
	if(aSearchKey==nil)aSearchKey=@"";
    [[[self undoManager] prepareWithInvocationTarget:self] setSearchKey:searchKey];
    
    [searchKey autorelease];
    searchKey = [aSearchKey copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHeaderExplorerSearchKeyChanged object:self];
}

- (BOOL) autoProcess
{
    return autoProcess;
}

- (void) setAutoProcess:(BOOL)aAutoProcess
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoProcess:autoProcess];
    
    autoProcess = aAutoProcess;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHeaderExplorerAutoProcessChanged object:self];
}

- (int) selectedRunIndex
{
	return selectedRunIndex;
}

- (void) setSelectedRunIndex:(int)anIndex
{
	selectedRunIndex = anIndex;
	[[NSNotificationCenter defaultCenter]
			postNotificationName:ORHeaderExplorerRunSelectionChanged
				object: self];
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
			    postNotificationName:ORHeaderExplorerSelectionDate
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
	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORHeaderExplorerProcessingFile
								object: self];
}

- (NSArray*) filesToProcess
{
    return filesToProcess;
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

	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORHeaderExplorerHeaderChanged
								object: self];
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
		[self setSelectedRunIndex: -1];
		[self setHeader: nil];
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
    [self removeFiles:filesToProcess];
}

- (void) addFilesToProcess:(NSMutableArray*)newFilesToProcess
{
	if(!newFilesToProcess)return;
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
			    postNotificationName:ORHeaderExplorerListChanged
                              object: self];

	if(autoProcess)[self readHeaders];
      
}

- (void) removeFiles:(NSMutableArray*)anArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] addFilesToProcess:anArray];
    [filesToProcess removeObjectsInArray:anArray];

    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORHeaderExplorerListChanged
                              object: self];
	if(autoProcess)[self readHeaders];
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
		[self removeFiles:filesToRemove];    
	}
}

- (void) stopProcessing
{
	stop = YES;
    NSLog(@"Header Explorer stopped manually\n");
}

#pragma mark •••File Actions
- (void) readHeaders
{
	if([self isProcessing]) return;
	
	[runArray release];
	runArray = [[NSMutableArray array] retain];
	
	reading = YES;
	stop = NO;
	numberLeft = [filesToProcess count];

    if(fileAsDataPacket)[fileAsDataPacket release];
    fileAsDataPacket = [[ORDataPacket alloc] init];

    [self setHeader:nil];
	minRunStartTime  = 0xffffffff;
	maxRunEndTime	 = 0;
    currentFileIndex = 0;
	
	if ([filesToProcess count]){
		[[NSNotificationCenter defaultCenter]
				postNotificationName:ORHeaderExplorerProcessing
                              object: self];
		[self performSelector:@selector(readNextFile) withObject:nil afterDelay:.1];
	}
}

- (void) readNextFile
{
	[[self undoManager] disableUndoRegistration];
	if(!stop && currentFileIndex < [filesToProcess count]){
		id aFile = [filesToProcess objectAtIndex:currentFileIndex];
		
		[self setFileToProcess:aFile];

		NSFileHandle* fp = [NSFileHandle fileHandleForReadingAtPath:aFile];

		[fileAsDataPacket clearData];
		if(fp){
		
			unsigned long runStart  = 0;
			unsigned long runEnd    = 0;
			unsigned long runNumber = 0;
			
			if([fileAsDataPacket readHeaderReturnRunLength:fp runStart:&runStart runEnd:&runEnd runNumber:&runNumber]){
				if(runStart!=0 && runEnd!=0){
					if(runStart < minRunStartTime) minRunStartTime = runStart;
					if(runEnd > maxRunEndTime)     maxRunEndTime   = runEnd;
					[fp seekToEndOfFile];
					
					id headerData;
					if([searchKey length] && useFilter){
						NSMutableArray* keyArray = [NSMutableArray arrayWithArray:[searchKey componentsSeparatedByString:@"/"]]; //must be mutable
						headerData = [[fileAsDataPacket fileHeader] objectForKeyArray:keyArray];
					}
					else headerData = [fileAsDataPacket fileHeader];
					
					NSMutableDictionary* runDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithUnsignedLong:runStart],				  @"RunStart",
							[NSNumber numberWithUnsignedLong:runEnd],				  @"RunEnd",
							[NSNumber numberWithUnsignedLong:runEnd-runStart],		  @"RunLength",
							[NSNumber numberWithUnsignedLong:runNumber],			  @"RunNumber",
							[NSNumber numberWithUnsignedLong:[fp offsetInFile]],	  @"FileSize",
							[ORHeaderItem headerFromObject:headerData named:@"Root"], @"FileHeader",
							nil];
							
					[runArray addObject:runDictionary];
					
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
	}
	[[self undoManager] enableUndoRegistration];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
	[[self undoManager] disableUndoRegistration];
    [self setUseFilter:		[decoder decodeBoolForKey:	@"useFilter"]];
    [self setSearchKey:		[decoder decodeObjectForKey:@"searchKey"]];
    [self setAutoProcess:	[decoder decodeBoolForKey:	@"autoProcess"]];
	[self addFilesToProcess:[decoder decodeObjectForKey:@"filesToProcess"]];
	[self setLastListPath:	[decoder decodeObjectForKey:@"lastListPath"]];
	[self setLastFilePath:	[decoder decodeObjectForKey:@"lastFilePath"]];
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:useFilter		forKey: @"useFilter"];
    [encoder encodeObject:searchKey		forKey: @"searchKey"];
    [encoder encodeBool:autoProcess		forKey: @"autoProcess"];
    [encoder encodeObject:filesToProcess forKey:@"filesToProcess"];
    [encoder encodeObject:lastListPath	forKey: @"lastListPath"];
    [encoder encodeObject:lastFilePath	forKey: @"lastFilePath"];
    
}

@end

@implementation ORHeaderExplorerModel (private)
- (void) processFinished
{    
    [nextObject runTaskStopped:fileAsDataPacket userInfo:nil];
    [nextObject closeOutRun:fileAsDataPacket userInfo:nil];

	[fileAsDataPacket clearData];
    [fileAsDataPacket release];
    fileAsDataPacket = nil;
		      
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORHeaderExplorerProcessingFinished
                              object: self];

}

- (void) fileFinished
{
    [nextObject runTaskBoundary:fileAsDataPacket userInfo:nil];
	numberLeft--;
	[[NSNotificationCenter defaultCenter]
				postNotificationName:ORHeaderExplorerOneFileDone
                              object: self];

}



@end

