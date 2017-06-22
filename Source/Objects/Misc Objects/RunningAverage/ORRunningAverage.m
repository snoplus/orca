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
#import "ORRunningAverageGroup.h"

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

- (void) calculateAverage:(float)dataPoint minSamples:(int)minSamples triggerValue:(float)triggerValue spikeType:(BOOL)triggerType group:(ORRunningAverageGroup*)aGroup
{
    lastRateValue = dataPoint;
    [inComingData addObject:[NSNumber numberWithFloat:dataPoint]];
    if([inComingData count] > minSamples)[inComingData removeObjectAtIndex:0];
    
    unsigned long n = [inComingData count];
    if(n<=5){
        spikeState       = NO;
        lastSpikeState   = NO;
        runningAverage = dataPoint;
        runningAverage = ((n-1)*runningAverage + dataPoint)/(float)n;
        return;
    }
    runningAverage = ((n-1)*runningAverage + dataPoint)/(float)n;
    
    spikeValue = 0;
    switch(triggerType){
        case kRASpikeOnRatio: //trigger on the ratio of the rate over the average
            if(runningAverage != 0) {
                spikeValue = dataPoint/runningAverage;
                spikeState = (fabs(spikeValue) >= triggerValue);
            }
            break;
            
        case kRASpikeOnThreshold:
            spikeValue = dataPoint-runningAverage;
            spikeState   = (fabs(spikeValue) > triggerValue);
            break;
            
        default:
            break;
    }
    
    if(lastSpikeState != spikeState){
        lastSpikeState = spikeState;
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[self spikedInfo:spikeState]forKey:@"SpikeObject"];
        [[NSNotificationCenter defaultCenter] postNotificationName: ORSpikeStateChangedNotification
                                                                object: aGroup
                                                              userInfo: userInfo];
    }
}

- (ORRunningAveSpike*) spikedInfo:(BOOL)spiked
{
    ORRunningAveSpike* aSpikeObj = [[ORRunningAveSpike alloc] init];
    aSpikeObj.spiked        = spiked;
    aSpikeObj.tag           = tag;
    aSpikeObj.ave           = runningAverage;
    aSpikeObj.spikeValue    = spikeValue;
    
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
@synthesize tag,spiked,ave,spikeValue;

- (NSString*) description
{
    NSString* s = [NSString stringWithFormat:@"\nspiked:%@\ntag:%d\nave:%.3f\nspikeValue:%.3f",
                   self.spiked?@"YES":@"NO",
                   self.tag,
                   self.ave,
                   self.spikeValue];
    return s;
}
@end

