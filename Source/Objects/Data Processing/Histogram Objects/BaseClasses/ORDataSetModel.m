//
//  ORDataSetModel.m
//  Orca
//
//  Created by Mark Howe on Mon Sep 29 2003.
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


#import "ORDataSetModel.h"
#import "ORScale.h"
#import "ORGate.h"

NSString* ORDataSetModelPausedChanged		= @"ORDataSetModelPausedChanged";
NSString* ORDataSetModelRefreshModeChanged	= @"ORDataSetModelRefreshModeChanged";
NSString* ORDataSetModelRemoved				= @"ORDataSetModelRemoved";
NSString* ORDataSetDataChanged				= @"ORDataSetDataChanged";

@implementation ORDataSetModel
- (id) init
{
	self = [super init];
	dataSetLock = [[NSLock alloc] init];
	return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORDataSetModelRemoved
						  object:self
						userInfo: nil];
	
    
	[dataSetLock release];
    [key release];
    [fullName release];
    [shortName release];	
	
    [super dealloc];
}

#pragma mark ¥¥¥Accessors

- (BOOL) paused
{
    return paused;
}

- (void) setPaused:(BOOL)aPaused
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPaused:paused];
    
    paused = aPaused;
	scheduledForUpdate = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataSetModelPausedChanged object:self];
}

- (int) refreshMode
{
    return refreshMode;
}

- (void) setRefreshMode:(int)aRefreshMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRefreshMode:refreshMode];
    refreshMode = aRefreshMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataSetModelRefreshModeChanged object:self];
}

- (id) calibration
{
	return calibration;
}

- (void) setCalibration:(id)aCalibration
{
	[aCalibration retain];
	[calibration release];
	calibration  = aCalibration;
}

- (void) setDataSet:(id)aDataSet
{
	dataSet = aDataSet;	 //don't retain things like this.
}

- (id) dataSet
{
	return dataSet;
}

- (void) setKey:(NSString*)aKey
{
	[dataSetLock lock];
	[key autorelease];
	key = [aKey copy];
	[dataSetLock unlock];
}

- (NSString*)key
{
	[dataSetLock lock];
	NSString* temp = [[key retain] autorelease];
	[dataSetLock unlock];
	return temp;
}
- (void) setFullName:(NSString*)aString
{
	[dataSetLock lock];
    [fullName autorelease];
    fullName = [aString copy];
    if(fullName){
		
		//also parse the full name to create a short version the name.
		NSScanner* 		 scanner  	= [NSScanner scannerWithString:fullName];
		NSCharacterSet*  numbers 	= [NSCharacterSet decimalDigitCharacterSet];
		NSCharacterSet*  delimiters = [NSCharacterSet characterSetWithCharactersInString:@"\r\n\t ,"];
		NSString* 		 scanResult = [NSString string];
		NSString* comma = @",";
		NSMutableString* result = [NSMutableString string];
		[scanner scanUpToCharactersFromSet:[delimiters invertedSet] intoString:nil];//skip any leading whitespace
		[scanner scanUpToCharactersFromSet:delimiters intoString:&scanResult];		//read in the leading name i.e.'Shaper'
		[result appendString:scanResult];
		[result appendString:comma];
		
		[scanner scanUpToCharactersFromSet:[delimiters invertedSet] intoString:nil];//skip any leading whitespace
		[scanner scanUpToCharactersFromSet:delimiters intoString:&scanResult];	//skip any non-alphanumerics
		[result appendString:scanResult];
	   
		while(![scanner isAtEnd]) {
			[result appendString:comma];											//add a ','	
			[scanner scanUpToCharactersFromSet:numbers intoString:nil];				//skip any non-alphanumerics
			[scanner scanUpToCharactersFromSet:delimiters intoString:&scanResult];	//skip any non-alphanumerics
			[result appendString:scanResult];										
		}
		[shortName release];
		shortName = [result copy];
	}
	[dataSetLock unlock];
}

-(NSString*) fullName
{
	[dataSetLock lock];
	NSString* temp = [[fullName retain] autorelease];
	[dataSetLock unlock];
	return temp;
}

-(NSString*) shortName
{
	[dataSetLock lock];
	NSString* temp = [[shortName retain] autorelease];
	[dataSetLock unlock];
	return temp;
}

- (NSString*) fullNameWithRunNumber
{
	return [NSString stringWithFormat:@"%@%@%@",[self runNumberString],[[self runNumberString] length]>0?@",":@"",[self fullName]];
}

- (NSString*) runNumberString
{
	long runNumber = [dataSet runNumber];
	if(runNumber > 0) return [NSString stringWithFormat:@"Run %d",runNumber];
	else return @"";
}

-(unsigned long) totalCounts
{
	return totalCounts;
}

- (void) setTotalCounts:(unsigned long) aNewCount
{
    if(aNewCount!=totalCounts){
        totalCounts = aNewCount;
        
        [self postUpdateOnMainThread];
    }
}    


- (void) incrementTotalCounts
{
	++totalCounts;
	if(!paused){
		if(!scheduledForUpdate){
			scheduledForUpdate = YES;
			[self performSelectorOnMainThread:@selector(scheduleUpdateOnMainThread) withObject:nil waitUntilDone:NO];
		}
	}
}

- (void) postUpdateOnMainThread
{
	[self performSelectorOnMainThread:@selector(postUpdate) withObject:nil waitUntilDone:NO];
}

- (void) scheduleUpdateOnMainThread
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(postUpdate) object:nil];;
	[self performSelector:@selector(postUpdate) withObject:nil afterDelay:[self refreshRate]];
	scheduledForUpdate = YES;
}

- (float) refreshRate
{
	switch(refreshMode){
		case 0: return 1.0;
		case 1: return 0.5;
		case 2: return 0.2;
		case 3: return 0.0;
		default: return 1.0;
	}
}

- (void) postUpdate
{
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORDataSetDataChanged
					  object:self];    
	scheduledForUpdate = NO;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //by default there is no data description. subclasses can override
}

- (void) processResponse:(NSDictionary*)aResponse
{
	[dataSet processResponse:aResponse];
}


#pragma mark ¥¥¥Data Source Methods
- (unsigned)  numberOfChildren
{
	return 0;
}

- (id)   childAtIndex:(int)index
{
	return nil;
}

- (NSString*)   name
{
	return [NSString stringWithFormat:@"Error: no concrete class defined"];
}


- (void) runTaskStopped
{
    //default is do nothing. subclasses can override
}

- (void) runTaskBoundary
{
    //default is do nothing. subclasses can override
}


#pragma mark ¥¥¥Archival
static NSString *ORDataSetModelKey              = @"ORDataSetModelKey";
static NSString *ORDataSetModelFullName         = @"ORDataSetModelFullName";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	dataSetLock = [[NSLock alloc] init];
    [self setRefreshMode:[decoder decodeIntForKey:@"refreshMode"]];
    [self setKey:[decoder decodeObjectForKey:ORDataSetModelKey]];
    [self setFullName:[decoder decodeObjectForKey:ORDataSetModelFullName]];
	[self setCalibration:[decoder decodeObjectForKey:@"calibration"]];
	[self setDataSet:[decoder decodeObjectForKey:@"dataSet"]];
    
    [[self undoManager] enableUndoRegistration];
	scheduledForUpdate = NO;
    
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:refreshMode forKey:@"refreshMode"];
    [encoder encodeObject:key forKey:ORDataSetModelKey];
    [encoder encodeObject:fullName forKey:ORDataSetModelFullName];
    [encoder encodeObject:calibration forKey:@"calibration"];
    [encoder encodeObject:dataSet forKey:@"dataSet"];
}

- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo keys:(NSMutableArray*)aKeyArray
{
    //default is no data... subclasses can override
}

- (BOOL) canJoinMultiPlot
{
    //default is no... subclasses can override
    return NO;
}

@end
