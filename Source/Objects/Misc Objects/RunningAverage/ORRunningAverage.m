//
//  ORRunningAverage.m
//  Orca
//
//  Created by Wenqin on 3/23/16.
//
//



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
    for(int idx=0; idx<windowLength;idx++)
    {
        [inComingData addObject:[NSNumber numberWithFloat:0.]];
    }
    //NSLog(@"my running average window initially = %d\n",inComingData.count);
    runningAverage = 0.;
}

- (void) resetCounter:(float) rate
{
    [inComingData removeAllObjects];
    
    for(int idx=0; idx<windowLength;idx++)
    {
        [inComingData addObject:[NSNumber numberWithFloat:rate]];
    }
    runningAverage = rate;
    //NSLog(@"Running average window is reset to be %d array of %f\n",inComingData.count, runningAverage);
}

- (void) reset
{
    [inComingData removeAllObjects];
    
    for(int idx=0; idx<windowLength;idx++)
    {
        [inComingData addObject:[NSNumber numberWithDouble:0]];
    }
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

-(float)updateAverage:(float)datapoint{
    [inComingData addObject:[NSNumber numberWithFloat:datapoint]];
   // NSLog(@"my running average window now = %d-1\n",inComingData.count);

    //runningAverage = runningAverage - [[self oldestDataRemoval] floatValue]/windowLength + datapoint/windowLength;
    runningAverage = runningAverage - [self oldestDataRemoval]/windowLength + datapoint/windowLength;
    //NSLog(@"Internally running average for group tag = %d and channel tag = %s is %f\n",groupTag, tag, runningAverage);
    return runningAverage;
    
}

-(float)updateAveragewNSN:(NSNumber*)datapoint{
    [inComingData addObject: datapoint];
    runningAverage = runningAverage - [self oldestDataRemoval]/windowLength + [datapoint floatValue]/windowLength;
    return runningAverage;
}



-(void)updateAveragewObj:(id)obj{
    float datapoint = [obj getRate:tag forGroup:groupTag];
    [self updateAverage: datapoint]; //the variable runningAverage is updated in updateAverage
} //Expect the obj has a getRate method

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


