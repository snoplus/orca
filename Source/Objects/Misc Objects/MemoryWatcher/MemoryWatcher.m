//-------------------------------------------------------------------------
//  MemoryWatcher.m
//
//  Created by Mark Howe on Friday 05/13/2005.
//  Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files

#import "MemoryWatcher.h"
#import "ORTimeRate.h"
#import "NSString+Extensions.h"

@interface MemoryWatcher (private)
- (void) processResult;
@end

NSString* MemoryWatcherUpTimeChanged         = @"MemoryWatcherUpTimeChanged";
NSString* MemoryWatcherChangedNotification   = @"MemoryWatcherChangedNotification";
NSString* MemoryWatcherTaskIntervalNotification = @"MemoryWatcherTaskIntervalNotification";

enum {
	kCPU,
	kRSize,
	kVSize
};

@implementation MemoryWatcher

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [self setTaskInterval:60];
    [self setMaxSamples:200];
    [self setLaunchTime:[NSDate date]];
    [self launchTask];
    return self;
}

- (void) dealloc 
{
    [launchTime release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
    [taskResult release];
    if([vmTask isRunning]){
        [vmTask terminate];
    }
    [vmTask release];
	
	int i;
	for(i=0;i<kNumWatchedValues;i++){
		[timeRate[i] release];
	}
    [super dealloc];
}

#pragma mark ***Accessors

- (NSTimeInterval) upTime
{
    return upTime;
}

- (void) setUpTime:(NSTimeInterval)aUpTime
{
    upTime = aUpTime;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MemoryWatcherUpTimeChanged object:self];
}

- (NSDate*) launchTime
{
    return launchTime;
}

- (void) setLaunchTime:(NSDate*)aLaunchTime
{
    [aLaunchTime retain];
    [launchTime release];
    launchTime = aLaunchTime;
}

- (int) maxSamples
{
    return maxSamples;
}

- (void) setMaxSamples:(int)aMaxSamples
{
    maxSamples = aMaxSamples;
}

- (NSTimeInterval) taskInterval
{
    return taskInterval;
}

- (void) setTaskInterval:(NSTimeInterval)aTaskInterval
{
    if(aTaskInterval<1)aTaskInterval = 1;
    taskInterval = aTaskInterval;
	
	[[NSNotificationCenter defaultCenter]
				postNotificationName:MemoryWatcherTaskIntervalNotification
							  object:self];


}

- (NSMutableString*) taskResult
{
    return taskResult;
}

- (void) setTaskResult:(NSMutableString*)aTaskResult
{
    [taskResult autorelease];
    taskResult = [aTaskResult mutableCopy];    
}

- (NSTask*) vmTask
{
    return vmTask;
}

- (void) setVmTask:(NSTask*)aVmTask
{
    [aVmTask retain];
    [vmTask release];
    vmTask = aVmTask;
}

- (unsigned) timeRateCount:(int)rateIndex
{
	if(rateIndex<kNumWatchedValues)return [timeRate[rateIndex] count];
	else return 0;
}

- (float) timeRate:(int)rateIndex value:(int)valueIndex
{	
	if(rateIndex<kNumWatchedValues)return [timeRate[rateIndex] valueAtIndex:valueIndex];
	else return 0;
}

- (void) launchTask
{
    if(![vmTask isRunning]){
        
		int i;
		for(i=0;i<kNumWatchedValues;i++){
			if(!timeRate[i])timeRate[i] = [[ORTimeRate alloc] init];
		}
        [self setTaskResult:[NSMutableString string]];
		
        NSTask *t = [[NSTask alloc] init];
        [self setVmTask:t];
        [t release];
        		
        NSPipe *newPipe = [NSPipe pipe];
        NSFileHandle *readHandle = [newPipe fileHandleForReading];
        
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        
        [nc addObserver:self 
               selector:@selector(taskDataAvailable:) 
                   name:NSFileHandleReadCompletionNotification 
                 object:readHandle];
        
        [nc addObserver : self
               selector : @selector(taskCompleted:)
                   name : NSTaskDidTerminateNotification
                 object : vmTask];
        
        [readHandle readInBackgroundAndNotify];
        
        [vmTask setLaunchPath:@"/usr/bin/top"];
        [vmTask setArguments: [NSArray arrayWithObjects:@"-l",@"2",@"-i",@"1",@"-stats",@"command,cpu,rsize,vsize",nil]];
        [vmTask setStandardOutput:newPipe];
        [vmTask setStandardError:newPipe];
        [vmTask launch];
    }
    
    [self setUpTime:[[NSDate date] timeIntervalSinceDate:launchTime]]; 
    
}

- (void) taskCompleted: (NSNotification*)aNote
{
    if([aNote object] == vmTask){
        
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(launchTask) object:nil];
        [self performSelector:@selector(launchTask) withObject:nil afterDelay:taskInterval];
    }
}

- (void) taskDataAvailable:(NSNotification*)aNotification
{
	NSData* incomingData   = [[aNotification userInfo] valueForKey:NSFileHandleNotificationDataItem];
	if(incomingData){
		NSString *incomingText = [[NSString alloc] initWithData:incomingData encoding:NSASCIIStringEncoding];
		[taskResult appendString:incomingText];
		[incomingText release];
	}

	if(![vmTask isRunning]) {
		[self processResult];

		[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
		[taskResult release];
		taskResult = nil;

		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(launchTask) object:nil];
        [self performSelector:@selector(launchTask) withObject:nil afterDelay:taskInterval];


	}
	

	
	[[aNotification object] readInBackgroundAndNotify];  // go back for more.
}


- (float) convertValue:(float)aValue withMultiplier:(NSString*)aMultiplier
{
    if([aMultiplier hasPrefix:@"M"])return aValue;
    else if([aMultiplier hasPrefix:@"K"])return aValue/1000.;
    else return aValue/1000000.;
}

- (void) processResult
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSArray* lines = [taskResult componentsSeparatedByString:@"\n"];
	NSString* goodLine = @"";
	for(id aLine in lines){
		if([aLine rangeOfString:@"Orca "].location != NSNotFound){
			aLine = [aLine removeExtraSpaces];
			NSArray* parts = [aLine componentsSeparatedByString:@" "];
			if([parts count]==4 && [[parts objectAtIndex:1] floatValue]){
				goodLine = aLine;
				break;
			}
		}
	}
	if([goodLine length]){
		//should now have a line that looks like "Orca 0.2 40M+ 1056M"
		NSScanner* scanner = [[NSScanner alloc] initWithString:goodLine];
		if([scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil]){
			float value;
			//scan in cpu
			[scanner scanFloat:&value];
			[timeRate[kCPU] addDataToTimeAverage:value];
			
			//scan in RSIZE
			NSString* multiplier;
			[scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
			[scanner scanFloat:&value];
			if([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&multiplier]){
				[timeRate[kRSize] addDataToTimeAverage:[self convertValue:value withMultiplier:multiplier]];
			}
			
			//scan in VSIZE
			[scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
			[scanner scanFloat:&value];
			if([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&multiplier]){
				[timeRate[kVSize] addDataToTimeAverage:[self convertValue:value withMultiplier:multiplier]];
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName:MemoryWatcherChangedNotification object:self];
		}
		[scanner release];
	}
    [pool release];
}

@end
