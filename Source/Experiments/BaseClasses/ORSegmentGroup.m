//
//  ORSegmentGroup.m
//  Orca
//
//  Created by Mark Howe on 12/15/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORSegmentGroup.h"
#import "ORDetectorSegment.h"
#import "ORTimeRate.h"
#import "ORAxis.h"

NSString* ORSegmentGroupMapFileChanged		= @"ORSegmentGroupMapFileChanged";
NSString* ORSegmentGroupAdcClassNameChanged = @"ORSegmentGroupAdcClassNameChanged";
NSString* ORSegmentGroupMapReadNotification = @"ORSegmentGroupMapReadNotification";
NSString* ORSegmentGroupConfiguationChanged = @"ORSegmentGroupConfiguationChanged";

@implementation ORSegmentGroup

#pragma mark •••Initialization
- (id) initWithName:(NSString*)aName numSegments:(int)numSegments mapEntries:(NSArray*)someMapEntries;
{
	self=[super init];
	
    [[self undoManager] disableUndoRegistration];

	[self setGroupName:aName];
	[self setMapEntries:someMapEntries];
	
	segments = [[NSMutableArray array] retain];
	int i;
	for(i=0;i<numSegments;i++){
		ORDetectorSegment* aSegment = [[ORDetectorSegment alloc] init];
		[segments addObject:aSegment];
		[aSegment setSegmentNumber:i];
		[aSegment setMapEntries:someMapEntries];
		[aSegment release];
	}
	
	[self setColorAxisAttributes : [NSDictionary dictionaryWithObjectsAndKeys:
													[NSNumber numberWithDouble:0],ORAxisMinValue,
													[NSNumber numberWithDouble:10000],ORAxisMaxValue,
													[NSNumber numberWithBool:NO],ORAxisUseLog,
													nil]];
													

	
	[self setMapFile: [NSString stringWithFormat:@"~/%@",groupName]];

	ORTimeRate* r = [[ORTimeRate alloc] init];
	[self setTotalRate:r];
	[r release];
	
	memset(thresholdHistogram,0,1000);
	memset(gainHistogram,0,1000);
	memset(totalCountsHistogram,0,1000);

    [[self undoManager] enableUndoRegistration];
	
	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[segments release];
	[mapEntries release];
	[super dealloc];
}

- (NSUndoManager*) undoManager
{
	return [[NSApp delegate] undoManager];
}

- (void) showDialogForSegment:(int)aSegment
{
	[[segments objectAtIndex:aSegment] showDialog];
}

#pragma mark •••Notifications
- (void) awakeAfterDocumentLoaded
{
	[self registerNotificationObservers];
	[self configurationChanged:nil];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
           
    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORAdcInfoProvidingValueChanged
                       object : nil];

}

- (void) unregisterRates
{
	[segments makeObjectsPerformSelector:@selector(unregisterRates)];
}

- (void) registerForRates
{
	NSArray* adcObjects = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(adcClassName)];
	[segments makeObjectsPerformSelector:@selector(registerForRates:) withObject:adcObjects];
}

- (void) configurationChanged:(NSNotification*)aNote
{
	NSArray* adcObjects = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(adcClassName)];
	[segments makeObjectsPerformSelector:@selector(configurationChanged:) withObject:adcObjects];
	[self registerForRates];
	
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORSegmentGroupConfiguationChanged
                      object:self];
}

#pragma mark •••Accessors
- (void) setMapEntries:(NSArray*)someMapEntries
{
    [mapEntries autorelease];
    mapEntries = [someMapEntries retain];
	[segments makeObjectsPerformSelector:@selector(setMapEntries:) withObject:mapEntries];
}

- (NSArray*) mapEntries
{
	return mapEntries;
}

- (int) numSegments
{
	return [segments count];
}

- (id) segment:(int)index objectForKey:(id)aKey
{
	return [[segments objectAtIndex:index] objectForKey:aKey];
}

- (ORDetectorSegment*) segment:(int)index
{
	return [segments objectAtIndex:index];
}

- (NSString*) groupName
{
	return groupName;
}

- (void) setGroupName:(NSString*)aName
{
    [groupName autorelease];
    groupName = [aName copy];    
}

- (int) thresholdHistogram:(int) index
{
	return thresholdHistogram[index];
}

- (int) gainHistogram:(int) index;
{
	return gainHistogram[index];
}

- (int) totalCountsHistogram:(int) index;
{
	return totalCountsHistogram[index];
}

- (ORTimeRate*) totalRate
{
    return totalRate;
}

- (void) setTotalRate:(ORTimeRate*)newTotalRate
{
    [totalRate autorelease];
    totalRate=[newTotalRate retain];
}

- (BOOL) hwPresent:(int)aChannel
{
	if(aChannel < [segments count]) return [[segments objectAtIndex:aChannel] hwPresent];
	else return NO;
}

- (BOOL) online:(int)aChannel;
{
	return [[segments objectAtIndex:aChannel] online];
}

- (NSString*) mapFile
{
    return mapFile;
}

- (void) setMapFile:(NSString*)aMapFile
{    
	if(!aMapFile)aMapFile = [NSString stringWithFormat:@"~/%@",groupName];
    [mapFile autorelease];
    mapFile = [aMapFile copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSegmentGroupMapFileChanged object:self];
}

- (NSString*) adcClassName
{
    return adcClassName;
}

- (void) setAdcClassName:(NSString*)anAdcClassName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcClassName:adcClassName];
    
    [adcClassName autorelease];
    adcClassName = [anAdcClassName copy];    
	[self configurationChanged:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSegmentGroupAdcClassNameChanged object:self];
}

- (void) setSegments:(NSMutableArray*)anArray
{
	[anArray retain];
	[segments release];
	segments = anArray;
}

- (NSMutableArray*) segments
{
	return segments;
}

- (NSMutableDictionary*) colorAxisAttributes
{
    return colorAxisAttributes;
}

- (void) setColorAxisAttributes:(NSMutableDictionary*)newColorAxisAttributes
{
	[colorAxisAttributes release];
    colorAxisAttributes = [newColorAxisAttributes copy];
}

- (float) rate
{
	return rate;
}

- (float) getThreshold:(int) index
{
	id seg = [segments objectAtIndex:index];
	if([seg hardwarePresent]) return [seg threshold];
	else return -1;
}

- (float) getGain:(int) index
{
	id seg = [segments objectAtIndex:index];
	if([seg hardwarePresent]) return [seg gain];
	else return -1;
}

- (float) getPartOfEvent:(int) index
{
	id seg = [segments objectAtIndex:index];
	if([seg hardwarePresent]) return (float)[seg partOfEvent];
	else return -1;
}

- (BOOL) getError:(int) index
{
	return [[segments objectAtIndex:index] segmentError];
}

- (float) getRate:(int) index
{
	return [[segments objectAtIndex:index] rate];
}

- (float) getTotalCounts:(int) index
{
	return [[segments objectAtIndex:index] totalCounts];
}

- (void) clearTotalCounts
{
	[segments makeObjectsPerformSelector:@selector(clearTotalCounts)];
}

- (void) clearSegmentErrors
{
	[segments makeObjectsPerformSelector:@selector(clearSegmentError)];
}

- (void) setSegmentErrorClassName:(NSString*)aClassName card:(int)card channel:(int)channel
{
	int i;
	ORDetectorSegment* aSegment;
	int n = [segments count];
	for(i=0;i<n;i++){
		aSegment = [segments objectAtIndex:i];
		if([[aSegment hardwareClassName] isEqualToString:aClassName] && [aSegment cardSlot] == card && [aSegment channel] == channel){
			[aSegment setSegmentError];
		}
	}
}

#pragma mark •••Work Methods
- (void) collectRates
{
	float sum = 0;
	int i;	
	int n = [segments count];
	for(i=0;i<n;i++)sum += [[segments objectAtIndex:i] rate];
    rate = sum;
    [totalRate addDataToTimeAverage:sum];
}

- (NSSet*) hwCards
{
	NSMutableSet* allCards = [NSMutableSet set];
	ORDetectorSegment* aSegment;
	NSEnumerator* e = [segments objectEnumerator];
	while(aSegment = [e nextObject]){
		id<ORAdcInfoProviding> segmentCard = [aSegment hardwareCard];
		if(segmentCard){
			[allCards addObject:segmentCard];
		}
	}
	return allCards;
}

- (void) histogram
{
	memset(thresholdHistogram,0,sizeof(int) * 32*1024);
	memset(gainHistogram,0,sizeof(int) * 1024);
	memset(totalCountsHistogram,0,sizeof(int) * 1024);
	
	int i;
	int n = [segments count];
	for(i=0;i<n;i++){
		if([[segments objectAtIndex:i] hwPresent]){
			int thresholdValue = (int)[self getThreshold:i];
			if(thresholdValue>=0 && thresholdValue<32*1024)thresholdHistogram[thresholdValue]++;
			int gainValue = (int)[self getGain:i];
			if(gainValue>=0 && gainValue<1024)gainHistogram[gainValue]++;
			int totalClountsValue = (int)[self getTotalCounts:i];
			totalCountsHistogram[i] += totalClountsValue;
		}
	}
}

#pragma mark •••Map Methods
- (void) readMap:(NSString*)aFileName
{
	[self setMapFile:aFileName];
    NSString* contents = [NSString stringWithContentsOfFile:aFileName encoding:NSASCIIStringEncoding error:nil];
	contents = [[contents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
	contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
    NSArray*  lines = [contents componentsSeparatedByString:@"\n"];
    NSEnumerator* e = [lines objectEnumerator];
    NSString* aLine;
    BOOL oldFormat = [[[lines objectAtIndex:0] componentsSeparatedByString:@","] count] == 5;
	int index = -1;
	for(ORDetectorSegment* aSegment in segments){
		[aSegment setHwPresent:NO];
		[aSegment setParams:nil];
	}
    while(aLine = [e nextObject]){
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        if([aLine length] && [aLine characterAtIndex:0] != '#'){
			if(oldFormat){
				index++;
			}
			else {
				if(![aLine hasPrefix:@"--"]) index = [aLine intValue];
				else index = -1;
			}
			if(index>=0 && index < [segments count]){
				ORDetectorSegment* aSegment = [segments objectAtIndex:index];
				[aSegment decodeLine:aLine];
			}
        }
    }
	[self configurationChanged:nil];   
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORSegmentGroupMapReadNotification
                      object:self];
    
}

- (void) saveMapFileAs:(NSString*)newFileName
{
    NSMutableData* theContents = [NSMutableData data];
    NSEnumerator* e = [segments objectEnumerator];
    ORDetectorSegment* segment;
    while(segment = [e nextObject]){
        [theContents appendData:[[segment paramsAsString] dataUsingEncoding:NSASCIIStringEncoding]];
        [theContents appendData:[@"\n" dataUsingEncoding:NSASCIIStringEncoding]];
    }
    
    NSFileManager* theFileManager = [NSFileManager defaultManager];
    if([theFileManager fileExistsAtPath:newFileName]){
        [theFileManager removeItemAtPath:newFileName error:nil];
    }
    [theFileManager createFileAtPath:newFileName contents:theContents attributes:nil];
	[self setMapFile:newFileName];

}

- (NSString*) selectedSegementInfo:(int)index
{
	if(index<0)return @"<nothing selected>";
	else if(index>=[segments count]) return @"";
	else {
		NSString* string = [NSString stringWithFormat:@"%@\n",groupName];
		return [string stringByAppendingFormat:@"%@",[segments objectAtIndex:index]];
	}
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary useName:(NSString*)aName header:(NSString*)aHeader
{
    NSMutableDictionary* mapDictionary = [NSMutableDictionary dictionary];
	
	NSString* contents = [NSString stringWithContentsOfFile:[mapFile stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
	if([contents length]){
		if(aHeader)contents = [aHeader stringByAppendingFormat:@"\n%@",contents];
		[mapDictionary setObject:contents forKey:aName];
	}
	else {
		[mapDictionary setObject:@"NONE" forKey:aName];
	}
    [dictionary setObject:mapDictionary forKey:groupName];
    return dictionary;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary useName:(NSString*)aName 
{
	return [self addParametersToDictionary:dictionary useName:aName header:nil];	
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setGroupName:		[decoder decodeObjectForKey:@"GroupName"]];
    [self setAdcClassName:	[decoder decodeObjectForKey:@"AdcClassName"]];
    [self setColorAxisAttributes:[decoder decodeObjectForKey:@"ColorAxisAttributes"]];
    [self setTotalRate:		[decoder decodeObjectForKey:@"TotalRate"]];
 	[self setSegments:		[decoder decodeObjectForKey:@"Segments"]];
	[self setMapEntries:	[decoder decodeObjectForKey:@"mapEntries"]];
    [self setMapFile:		[decoder decodeObjectForKey:@"MapFile"]];
	
	[[self undoManager] enableUndoRegistration];
    
	if(!adcClassName)[self setAdcClassName:@"ORAugerFltModel"];
	[segments makeObjectsPerformSelector:@selector(setMapEntries:) withObject:mapEntries];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{        
    [encoder encodeObject:groupName		forKey:@"GroupName"];
    [encoder encodeObject:adcClassName	forKey:@"AdcClassName"];
    [encoder encodeObject:colorAxisAttributes forKey:@"ColorAxisAttributes"];
    [encoder encodeObject:totalRate		forKey:@"TotalRate"];
    [encoder encodeObject:mapFile		forKey:@"MapFile"];
	[encoder encodeObject:mapEntries	forKey:@"mapEntries"];
    [encoder encodeObject:segments		forKey:@"Segments"];
}


@end
