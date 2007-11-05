//
//  ORTimeRate.m
//  Orca
//
//  Created by Mark Howe on Tue Sep 09 2003.
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


#import "ORTimeRate.h"

NSString* ORRateAverageChangedNotification 	= @"ORRateAverageChangedNotification";


@interface ORTimeRate (private)
- (float) _getAverageFromStack;
@end;


@implementation ORTimeRate

- (id) init
{
	self = [super init];
	sampleTime = 30;
	timeAverageWrite = 0;
	timeAverageRead = 0;
	averageStackCount = 0;
	return self;
}

- (void) dealloc
{
	[lastAverageTime release];
	[super dealloc];
}


#pragma mark •••Accessors
- (NSDate*) lastAverageTime
{
	return lastAverageTime;
}
- (void) setLastAverageTime:(NSDate*)newLastAverageTime
{
	[lastAverageTime autorelease];
	lastAverageTime=[newLastAverageTime retain];
}

- (unsigned long) sampleTime
{
	return sampleTime;
}
- (void) setSampleTime:(unsigned long)newSampleTime
{
	sampleTime=newSampleTime;
}

- (void) addDataToTimeAverage:(float)aValue
{
	if(sampleTime == 0)sampleTime = 30;
	if(averageStackCount<kAverageStackSize){
		averageStack[averageStackCount] = aValue;
		averageStackCount++;
	}
	//has enough time elapsed to accept the new data?
	NSDate* now = [NSDate date];
	NSTimeInterval deltaTime = [now timeIntervalSinceDate:lastAverageTime];

	if(lastAverageTime==0 || deltaTime>=sampleTime){
			
		aValue = [self _getAverageFromStack];
								
		[self setLastAverageTime:now];
		
		timeAverage[timeAverageWrite] = aValue;

		timeAverageWrite = (timeAverageWrite+1)%kTimeAverageBufferSize;
		if(timeAverageWrite == timeAverageRead){
			//the circular buffer is full, advance the read position
			timeAverageRead = (timeAverageRead+1)%kTimeAverageBufferSize;
		}
				
		[[NSNotificationCenter defaultCenter] postNotificationName:ORRateAverageChangedNotification object:self userInfo:nil];
		
	}	
}

- (unsigned) count
{
	if(timeAverageWrite > timeAverageRead)return timeAverageWrite - timeAverageRead;
	else return kTimeAverageBufferSize-timeAverageRead + timeAverageWrite;
}

- (float)valueAtIndex:(unsigned)index
{
	NSAssert(index>=0 && index < kTimeAverageBufferSize,@"Time Average Index Out Of Bounds");
	return timeAverage[(timeAverageRead+index)%kTimeAverageBufferSize];
}

#pragma mark •••Archival
static NSString *ORTimeRate_SampleTime 	= @"ORTimeRate_SampleTime";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    [self setSampleTime:[decoder decodeInt32ForKey:ORTimeRate_SampleTime]];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt32:[self sampleTime] forKey:ORTimeRate_SampleTime];
}

@end


@implementation ORTimeRate (private)

- (float) _getAverageFromStack
{
	if(averageStackCount){
		int total = averageStackCount;
		float sum = 0;
		int i;
		for(i=0;i<total;++i){
			sum += averageStack[i];
		}
		averageStackCount = 0;
		return sum/total;
	}
	else return 0;
}

@end
