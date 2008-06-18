//
//  ORDataExplorerModel.m
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
#import "ORDataExplorerModel.h"
#import "ORDataPacket.h"
#import "ORHeaderItem.h"
#import "ORDataSet.h"
#import "ThreadWorker.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORDataExplorerModelHistoErrorFlagChanged = @"ORDataExplorerModelHistoErrorFlagChanged";
NSString* ORDataExplorerModelMultiCatalogChanged = @"ORDataExplorerModelMultiCatalogChanged";
NSString* ORDataExplorerFileChangedNotification     = @"ORDataExplorerFileChangedNotification";
NSString* ORDataExplorerParseStartedNotification    = @"ORDataExplorerParseStartedNotification";
NSString* ORDataExplorerParseEndedNotification      = @"ORDataExplorerParseEndedNotification";
NSString* ORDataExplorerDataChanged                 = @"ORDataExplorerDataChanged";

@implementation ORDataExplorerModel

#pragma mark ¥¥¥Initialization
- (void) dealloc
{
    [fileToExplore release];
    [header release];
    [fileAsDataPacket release];
    [dataRecords release];
    [dataSet release];
    
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"DataExplorer"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORDataExplorerController"];
}

#pragma mark ¥¥¥Accessors

- (BOOL) histoErrorFlag
{
    return histoErrorFlag;
}

- (void) setHistoErrorFlag:(BOOL)aHistoErrorFlag
{
    histoErrorFlag = aHistoErrorFlag;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataExplorerModelHistoErrorFlagChanged object:self];
}

- (BOOL) multiCatalog
{
    return multiCatalog;
}

- (void) setMultiCatalog:(BOOL)aMultiCatalog
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMultiCatalog:multiCatalog];
    
    multiCatalog = aMultiCatalog;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataExplorerModelMultiCatalogChanged object:self];
}
- (ORDataSet*) dataSet
{
    return dataSet;
}

- (void) setDataSet:(ORDataSet*)aDataSet
{
    [aDataSet retain];
    [dataSet release];
    dataSet = aDataSet;
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

- (id) dataRecordAtIndex:(int)index
{
    return [dataRecords objectAtIndex:index];
}
- (ORDataPacket*) fileAsDataPacket
{
    return fileAsDataPacket;
}

- (NSString*) fileToExplore
{
    if(fileToExplore)return fileToExplore;
    else return @"";
}

- (void) setFileToExplore:(NSString*)newFileToExplore
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFileToExplore:fileToExplore];
    
    [fileToExplore autorelease];
    fileToExplore=[newFileToExplore retain];
    
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORDataExplorerFileChangedNotification
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

- (id)   name
{
    return @"System";
}

- (id)   childAtIndex:(int)index
{
    NSEnumerator* e = [dataSet objectEnumerator];
    id obj;
    id child = nil;
    short i = 0;
    while(obj = [e nextObject]){
        if(i++ == index){
            child = obj;
            break;
        }
    }
    return child;
}
- (unsigned)  count
{
    return [dataSet count];
}

- (unsigned)  numberOfChildren
{
    int count =  [dataSet count];
    return count;
}

- (void) removeDataSet:(ORDataSet*)item
{
    if([[item name] isEqualToString: [self name]]) {
        [self setDataSet:nil];
    }
    else [dataSet removeObject:item];
}
- (void) createDataSet
{
    [self setDataSet:[[[ORDataSet alloc]initWithKey:@"System" guardian:nil] autorelease]];
}

- (unsigned) totalLength
{
    return totalLength;
}

- (unsigned) lengthDecoded
{
    return lengthDecoded;
}

- (void) clearCounts
{
    [dataSet clear];
    NSEnumerator* e = [dataRecords objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj setObject:[NSNumber numberWithBool:NO] forKey:@"DecodedOnce"];
    }
    
}
- (void) flushMemory
{
    [self setDataRecords:nil];
    [self setHeader:nil];
    [self setDataSet:nil];    
}

#pragma mark ¥¥¥File Actions

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
	[self setHistoErrorFlag:NO];
	
    if(parseThread)return;
    
    totalLength   = 0;
    lengthDecoded = 0;
    [self setDataRecords:nil];
    [self setHeader:nil];
    [self setDataSet:nil];
    
    if(fileAsDataPacket)[fileAsDataPacket release];
    fileAsDataPacket = [[ORDataPacket alloc] init];
    
    
    parseThread = [[ThreadWorker workOn:self withSelector:@selector(parse:thread:)
                             withObject:nil
                         didEndSelector:@selector(parseThreadExited:)] retain];
    
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORDataExplorerParseStartedNotification
                              object: self];
    
    if(!parseThread){
        [self parseThreadExited:nil];
    }
}

-(id) parse:(id)userInfo thread:(id)tw
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool allocWithZone:nil] init];
    NSFileHandle* fp = [NSFileHandle fileHandleForReadingAtPath:fileToExplore];
    if(fp){
        
        if([fileAsDataPacket legalDataFile:fp]){
			if([fileAsDataPacket readData:fp]){
				[fileAsDataPacket generateObjectLookup];       //MUST be done before data header will work.
				
				[self setHeader:[ORHeaderItem headerFromObject:[fileAsDataPacket fileHeader] named:@"Root"]];
				
				[self setDataRecords:[fileAsDataPacket decodeDataIntoArrayForDelegate:self]]; 
			}
			else {
				NSLogColor([NSColor redColor],@"Problem reading <%@> for exploring.\n",[fileToExplore stringByAbbreviatingWithTildeInPath]);
			}
		}
		else {
			NSLogColor([NSColor redColor],@" <%@> doesn't appear to be a legal ORCA data file.\n",[fileToExplore stringByAbbreviatingWithTildeInPath]);
		}
    }
    else {
        NSLogColor([NSColor redColor],@"Could NOT Open <%@> for exploring.\n",[fileToExplore stringByAbbreviatingWithTildeInPath]);
    }
    [pool release];
    return @"done";
}

-(void)parseThreadExited:(id)userInfo
{
    [parseThread release];
    parseThread = nil;
    [[NSNotificationCenter defaultCenter]
			    postNotificationName:ORDataExplorerParseEndedNotification
                              object: self];
    
}

- (void) byteSwapOneRecordAtOffset:(unsigned long)anOffset forKey:(id)aKey
{
    [fileAsDataPacket byteSwapOneRecordAtOffset:anOffset forKey:aKey];
}

- (void) decodeOneRecordAtOffset:(unsigned long)anOffset forKey:(id)aKey
{
    [fileAsDataPacket decodeOneRecordAtOffset:anOffset intoDataSet:dataSet forKey:aKey];
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
	[[self undoManager] disableUndoRegistration];
    [self setMultiCatalog:	[decoder decodeBoolForKey:		@"ORDataExplorerModelMultiCatalog"]];
	[self setFileToExplore:	[decoder decodeObjectForKey:	@"ORDataExplorerFileName"]];
    [self setDataSet:		[decoder decodeObjectForKey:	@"ORDataExplorerDataSet"]];
	[[self undoManager] enableUndoRegistration];
    
    if(!dataSet)[self setDataSet:[[[ORDataSet alloc]initWithKey:@"System" guardian:nil] autorelease]];
    
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:multiCatalog	forKey: @"ORDataExplorerModelMultiCatalog"];
    [encoder encodeObject:fileToExplore forKey: @"ORDataExplorerFileName"];
    [encoder encodeObject:dataSet		forKey: @"ORDataExplorerDataSet"];
    
}

@end
