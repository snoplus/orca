//
//  ORRunningAverage.m
//  Orca
//
//  Created by Wenqin on 3/23/16.
//
//



#import "ORRunningAverage.h"
@implementation ORRunningAverage

- (id) init
{
    self = [super init];
    inComingData = [[NSMutableArray alloc] init];
    return self;
}


/*
- (id) initwithwindowLength:(int) wl
{
    windowLength = wl;
    self = [super init];
    inComingData = [[NSMutableArray alloc] init];
    for(int idx=0; idx<windowLength;idx++)
    {
        [inComingData addObject:[NSNumber numberWithDouble:0]];
    }
    NSLog(@"my running average window initially = %d",inComingData.count);
    runningAverage = 0;
    return self;
}
*/
- (void) dealloc
{
    [inComingData release];
    [super dealloc];
}

- (void) setWindowLength:(int) wl
{
    [inComingData removeAllObjects];
    
    windowLength = wl;
    for(int idx=0; idx<windowLength;idx++)
    {
        [inComingData addObject:[NSNumber numberWithFloat:0.]];
    }
    NSLog(@"my running average window initially = %d\n",inComingData.count);
    runningAverage = 0.;
}

- (void) resetCounter:(float) rate
{
    [inComingData removeAllObjects];
    
    for(int idx=0; idx<windowLength;idx++)
    {
        [inComingData addObject:[NSNumber numberWithDouble:rate]];
    }
    runningAverage = rate;
    NSLog(@"Running average window is reset\n",inComingData.count, runningAverage);

}


/*
-(NSNumber *)oldestDataRemoval{
    NSNumber* oldestdata=[[inComingData objectAtIndex:0] retain];
    [inComingData removeObjectAtIndex:0];
    return [oldestdata autorelease];
}*/

-(float)oldestDataRemoval{
    NSNumber* oldestdata=[inComingData objectAtIndex:0];
    float oldestDataValue=[oldestdata floatValue];
    [inComingData removeObjectAtIndex:0];
    return oldestDataValue;
}

//-(float)updateAverage:(NSNumber * )datapoint{
-(float)updateAverage:(float)datapoint{
    [inComingData addObject:[NSNumber numberWithDouble:datapoint]];
   // NSLog(@"my running average window now = %d-1\n",inComingData.count);

    //runningAverage = runningAverage - [[self oldestDataRemoval] floatValue]/windowLength + datapoint/windowLength;
    runningAverage = runningAverage - [self oldestDataRemoval]/windowLength + datapoint/windowLength;
    //NSLog(@"internal average = %f\n",runningAverage);
    return runningAverage;
    
}

-(float)getAverage{
    return runningAverage;
}


-(void)dump{
    for(int idx=0; idx<windowLength;idx++)
    {
        NSLog(@"number at index %d = %f\n",idx, [[inComingData objectAtIndex:idx] floatValue]);
    }
}

@end