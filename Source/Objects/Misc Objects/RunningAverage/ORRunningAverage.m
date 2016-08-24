//
//  ORRunningAverage.m
//  Orca
//
//  Created by Wenqin on 3/23/16.
//
//
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

#import "ORRunningAverage.h"
@implementation ORRunningAverage

- (id) initWithTag: (short)aTag
         andLength: (short) wl
{
    self = [super init];
    [self setTag: aTag];
    inComingData = [[NSMutableArray alloc] init];
    [self setWindowLength:wl];
    spikeStartDate = nil;
    return self;
}

- (void) dealloc
{
    [spikeStartDate release];
    [inComingData release];
    [super dealloc];
}

- (int) tag
{
    return tag;
}

- (void) setTag:(int)newTag
{
    tag=newTag;
}

- (int) groupTag
{
    return groupTag;
} 

- (void) setGroupTag:(int)newGroupTag
{
    groupTag=newGroupTag;
}

- (void) setWindowLength:(int) wl
{
    [inComingData removeAllObjects];
    
    windowLength = wl;
    [self reset];
    //NSLog(@"my running average window initially = %d\n",inComingData.count);
    runningAverage = 0.;
}

- (void) resetCounter:(float) rate
{
    [inComingData removeAllObjects];
}
- (void) reset
{
    [inComingData removeAllObjects];
}

- (float) lastRateValue
{
    return lastRateValue;
}

- (float) runningAverage
{
    return runningAverage;
}
- (float)   spikeValue
{
    return spikeValue;
}

- (ORRunningAveSpike*) calculateAverage:(float)dataPoint minSamples:(int)minSamples triggerValue:(float)triggerValue spikeType:(BOOL)triggerType
{
    lastRateValue = dataPoint;
    [inComingData addObject:[NSNumber numberWithFloat:dataPoint]];
    if([inComingData count] > minSamples)[inComingData removeObjectAtIndex:0];
    
    unsigned long n = [inComingData count];
    if(n==1){
        runningAverage = dataPoint;
        return [self spikedInfo:NO];
    }
    runningAverage = runningAverage + (dataPoint - runningAverage)/(float)n;
    
    spikeValue = 0;
    switch(triggerType){
        case kRASpikeOnRatio: //trigger on the ratio of the rate over the average
            if(runningAverage != 0) {
                spikeValue = dataPoint/runningAverage;
                didSpike   = (fabs(spikeValue) >= triggerValue);
            }
            break;
            
        case kRASpikeOnThreshold:
            spikeValue = dataPoint-runningAverage;
            didSpike   = (fabs(spikeValue) > triggerValue);
            break;
            
        default:
            break;
    }
    
    if(lastDidSpike != didSpike){
        lastDidSpike = didSpike;
        return [self spikedInfo:didSpike];
    }
    return nil;
}

- (ORRunningAveSpike*) spikedInfo:(BOOL)spiked
{
    NSTimeInterval duration;
    if(spiked){
        [spikeStartDate release];
        spikeStartDate = [[NSDate date]retain];
        duration = -1;
    }
    else {
        duration = [[NSDate date] timeIntervalSinceDate:spikeStartDate];
        [spikeStartDate release];
        spikeStartDate = nil;
    }
    
    ORRunningAveSpike* aSpikeObj = [[ORRunningAveSpike alloc] init];
    aSpikeObj.spikeStart    = spikeStartDate;
    aSpikeObj.duration      = duration; //only valid at end of spike, else -1
    aSpikeObj.spiked        = spiked;
    aSpikeObj.tag           = tag;
    aSpikeObj.ave           = runningAverage;
    aSpikeObj.spikeValue    = spikeValue;
    
    if(!spiked){
        [spikeStartDate release];
        spikeStartDate = nil;
    }
    
    return [aSpikeObj autorelease];
}

- (void) dump
{
    int idx;
    for(idx=0; idx<[inComingData count];idx++){
        NSLog(@"number at index %d = %f\n",idx, [[inComingData objectAtIndex:idx] floatValue]);
    }
}

@end

@implementation ORRunningAveSpike
@synthesize tag,spiked,spikeStart,ave,spikeValue,duration;

- (void) dealloc
{
    //dealloc properties like this
    self.spikeStart = nil;
    
    [super dealloc];
}

- (NSString*) description
{
    NSString* s = [NSString stringWithFormat:@"\ntime:%@\nspiked:%@\ntag:%d\nave:%.3f\nspikeValue:%.3f",
                   self.spikeStart,
                   self.spiked?@"YES":@"NO",
                   self.tag,
                   self.ave,
                   self.spikeValue];
    return s;
}
@end

