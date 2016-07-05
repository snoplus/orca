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
    return self;
}

- (void) dealloc
{
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
    int idx;
    for(idx=0; idx<windowLength;idx++){
        [inComingData addObject:[NSNumber numberWithFloat:rate]];
    }
    runningAverage = rate;
}
- (void) reset
{
    [inComingData removeAllObjects];
}


- (float) updateAverage:(float)dataPoint
{
    lastRateValue = dataPoint;
    [inComingData push:[NSNumber numberWithFloat:dataPoint]];
    runningAverage = runningAverage - [[inComingData firstObject]floatValue]/windowLength + dataPoint/windowLength;
    
    return runningAverage;
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

- (ORRunningAveSpike*) calculateAverage:(float)rate minSamples:(int)minSamples triggerValue:(float)triggerValue spikeType:(BOOL)triggerType
{
    [self  updateAverage:rate];
    
    if([inComingData count] < minSamples) return nil;
    [inComingData removeObjectAtIndex:0];
    
    spikeValue = 0;
    switch(triggerType){
        case kRASpikeOnRatio: //trigger on the ratio of the rate over the average
            if(runningAverage != 0) {
                spikeValue = rate/runningAverage;
                //didSpike   = (fabs(spikeValue) >= triggerValue);
                didSpike   = testSpike;
            }
            break;
            
        case kRASpikeOnThreshold:
            spikeValue = rate-runningAverage;
            //didSpike   = (fabs(spikeValue) > triggerValue) || testSpike;
            didSpike   = testSpike;
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
    ORRunningAveSpike* aSpikeObj = [[ORRunningAveSpike alloc] init];
    aSpikeObj.timeOfSpike  = [NSDate date];
    aSpikeObj.spiked       = didSpike;
    aSpikeObj.tag          = tag;
    aSpikeObj.ave          = runningAverage;
    aSpikeObj.spikeValue   = spikeValue;
    return aSpikeObj;
}
- (void)    setTestSpike:(BOOL)aFlag
{
    testSpike = aFlag;   //for testing only
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
@synthesize tag,spiked,timeOfSpike,ave,spikeValue;

- (void) dealloc
{
    //dealloc properties like this
    self.timeOfSpike = nil;
    
    [super dealloc];
}

- (NSString*) description
{
    NSString* s = [NSString stringWithFormat:@"\ntime:%@\nspiked:%@\ntag:%d\nave:%.3f\nspikeValue:%.3f",
                   self.timeOfSpike,
                   self.spiked?@"YES":@"NO",
                   self.tag,
                   self.ave,
                   self.spikeValue];
    return s;
}
@end

