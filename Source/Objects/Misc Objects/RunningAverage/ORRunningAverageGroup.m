//
//  ORRunningAverageGroup
//  Orca
//
//  Created by Wenqin on 5/16/16.
//
//


#import "ORRunningAverage.h"
#import "ORRunningAverageGroup.h"
NSString* ORRunningAverageChangedNotification = @"ORRunningAverageChangedNotification";


@implementation ORRunningAverageGroup

- (id) initGroup:(int)numberInGroup groupTag:(int) aGroupTag withLength:(int)wl
{
    self = [super init];
    PrintMymessages = true;
    if(PrintMymessages)NSLog(@"ORRunningAverageGroup, init for %d channels", numberInGroup);

    [self setTag:aGroupTag];
    [self setWindowLength:wl];
    [self setGroupSize:numberInGroup];
    
    [self setRunningAverages:[NSMutableArray array]];
    [self setCurrentRates:[NSMutableArray array]];
    [self setSpikes:[NSMutableArray array]];
    
    triggerOnRatio=true;
    threshold=0.1;
    sampled=0;
    

    int i;
    for(i=0;i<numberInGroup;i++){
        ORRunningAverage* aRAObj = [[ORRunningAverage alloc] initWithTag:i andLength:wl];
        //[aRAObj setTag:i];
        [aRAObj setGroupTag:aGroupTag];
        [runningAverages addObject:aRAObj];
        [aRAObj release]; //this should be fine.
        [spikes addObject:[NSNumber numberWithFloat:0]];
        [currentRates addObject:[NSNumber numberWithFloat:0]];
    }
    return self;
}

- (void) dealloc
{
    if(PrintMymessages)NSLog(@"ORRunningAverageGroup, - dealloc\n");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [runningAverages release];
    [spikes release];
    [currentRates release];
    [super dealloc];
}

#pragma mark •••Accessors
-(void) setGroupSize:(int)a{
    groupSize=a;
}

-(int)groupSize
{
    return groupSize;
}

-(void)setSampled:(int)a{
    sampled=a;
}

-(int)sampled{
    return sampled;
}

-(void) setPrintMymessages:(bool)b{
    PrintMymessages=b;
}


- (void) setTriggerOnRatio: (bool)b
{
    triggerOnRatio=b;
}
- (bool) triggerOnRatio
{
    return triggerOnRatio;
}

- (void) setThreshold:(float)a
{
    threshold =a;
}
- (float) threshold
{
    return threshold;
}

- (NSArray*) runningAverages
{
    if(PrintMymessages)NSLog(@"ORRunningAverageGroup, - runningAverages\n");
    return runningAverages;
}

- (void) setRunningAverages:(NSMutableArray *)newRAs
{
    if(PrintMymessages)NSLog(@"ORRunningAverageGroup, - setRunningAverages\n");
    [newRAs retain]; //in case the newRAs is itself.
    [runningAverages release];
    runningAverages = newRAs;
}

- (id) runningAverageObject:(short)index
{
    if(index<[runningAverages count]){
        return [runningAverages objectAtIndex:index];
    }
    else return nil;
}

-(float)getRunningAverageValue:(short)idx{
    //if(PrintMymessages)NSLog(@"ORRunningAverageGroup, - getRunningAverage\n");
    if(idx<[runningAverages count]){
        return [[self runningAverageObject:idx] getAverage];
    }
    else return 0;
} //this is no new caculation in the getAverage method, just returns a value

-(NSArray*)getRunningAverageValues{
    if(PrintMymessages)NSLog(@"ORRunningAverageGroup, - (NSArray*)getRunningAverage\n");

    NSMutableArray * newrunningAverages = [[NSMutableArray alloc] init];
    for(int idx=0; idx<[runningAverages count];idx++)
    {
        [newrunningAverages addObject:[NSNumber numberWithFloat:[self getRunningAverageValue: idx]]];
    }
    return [newrunningAverages autorelease];
} //return the copy of running averages that this object keeps

- (void) setCurrentRates:(NSMutableArray *)newarray
{
    [newarray retain]; //in case the newRAs is itself.
    [currentRates release];
    currentRates = newarray;
}

-(NSArray*) currentRates{
    return currentRates; //return the copy of rates that this object keeps
}

- (void) setSpikes:(NSMutableArray *)newarray
{
    [newarray retain]; //in case the newRAs is itself.
    [spikes release];
    spikes = newarray;
}

-(NSArray*) spikes{
    return spikes; //return the copy of sudden change in rates compared to the average, it could be a ratio or an absolute value.
}

 -(void) setGlobalSpiked:(BOOL)b
{
    globalSpiked=b;
}
-(BOOL)globalSpiked
{
    return globalSpiked;
}

- (double) integrationTime
{
    return integrationTime;
}

- (void) setIntegrationTime:(double)newIntegrationTime
{
    integrationTime=newIntegrationTime;
   // [[NSNotificationCenter defaultCenter] postNotificationName:ORRunningAverageGroupIntegrationChangedNotification object:self userInfo:nil];
    if(PrintMymessages)NSLog(@"ORRunningAverageGroup, - newIntegrationTime is %lg \n", integrationTime);
}
- (void) updateWindowLength:(int) newWindowLength
{
    if(PrintMymessages)NSLog(@"ORRunningAverageGroup, - setWindowLength\n");
    for(int idx=0; idx<[runningAverages count];idx++)
    {
        [[self runningAverageObject:idx] setWindowLength:newWindowLength];
    }
}

-(void) setWindowLength:(int)newWindowLength
{
    windowLength=newWindowLength;
}

-(int) windowLength
{
    return windowLength;
}

- (void) resetCounters:(float) rate
{
    for(int idx=0; idx<[runningAverages count];idx++)
    {
        [[self runningAverageObject:idx] resetCounter:rate];
    }
}

-(void) updateRunningAverages:(NSArray*)newdatapoints{
    if([runningAverages count]!=[self groupSize]){NSLog(@"ORRunningAverageGroup group size is unexpectedly broken\n"); return;}
    for(int idx=0; idx<[runningAverages count];idx++)
    {NSLog(@"ORRunningAverageGroup updateRunningAverages not implemented. Bypassed for now");}
}

- (int) tag
{
    return tag;
}
- (void) setTag:(int)newTag
{
    tag=newTag;
}




- (void) start:(id)obj
{
    if(PrintMymessages)NSLog(@"ORRunningAverageGroup, - start, obj\n");

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self resetCounters:0];
    objectKeepingRate = obj;
    
    [self calcRunningAverages];
    
    //[self collectTimeRate];
}

- (void) quit
{
    if(PrintMymessages)NSLog(@"ORRunningAverageGroup, - quit\n");

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    objectKeepingRate = nil;
}

- (void) stop
{
    if(PrintMymessages)NSLog(@"ORRunningAverageGroup, - stop\n");

    [self quit];
    [self resetCounters:0];
}


- (void) calcRunningAverages
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(calcRunningAverages) object:nil];
    
    if(!objectKeepingRate){
        NSLog(@"ORRunningAverageGroup stopped \n");
        return;
    }

    NSArray* ra = [objectKeepingRate getRates:[self tag]];
    if(!runningAverages) {NSLog(@"error initilization of running average"); return;}
    //if([ra count]!=[runningAverages count])NSLog(@"# in average array, %d != # in obj rate array: %d \n",[runningAverages count], [ra count]);
    if([runningAverages count]!=[self groupSize]){NSLog(@"ORRunningAverageGroup group size is unexpectedly broken\n"); return;}

    else{
//        for(int idx=0; idx<[runningAverages count];idx++){
//            float b =   [[runningAverages objectAtIndex:idx] updateAveragewNSN: [a objectAtIndex:idx]];
//            if(b>0.00001)NSLog(@"channel %d has a rate of %f \n", idx, b);
            
//        }
        for(int idx=0; idx<[runningAverages count];idx++)
        {
            [spikes replaceObjectAtIndex:idx withObject:[NSNumber numberWithFloat:0]];//re-initialize at every loop?
            
            float rate = [[ra objectAtIndex:idx] floatValue];
            float average = [self getRunningAverageValue:idx];
            if(sampled < [self windowLength]) continue; //sampled will be increased out of the channel loop.
            
            bool  locate_updated = false;
            float locate_spike=0;
            if(triggerOnRatio) //trigger on the ratio of the rate over the average
            {
                if(average != 0) //leave the minimum average rate constain to specfic object using running average
                {
                    if(fabs(rate/average) >= threshold) //updated due to trigger, this comes first.
                    {
                        locate_updated = true;
                        [self setGlobalSpiked:true]; //this did really spike
                        locate_spike = rate/average;
                    } //otherwise, locate_updated stay false
                    else if([self globalSpiked]) //updated due to recovery from last trigger
                    {
                        locate_updated = true;
                        [self setGlobalSpiked:false]; //this line is different; it didn't spike; will not come here again
                        locate_spike = rate/average;
                    }
                }
            }
            else //trigger on the difference between the rate and the average
            {
                if(fabs(rate-average) > threshold)
                {
                    locate_updated = true;
                    [self setGlobalSpiked:true];
                    locate_spike = rate-average;
                }
                else if([self globalSpiked])
                {
                    locate_updated = true;
                    [self setGlobalSpiked:false];
                    locate_spike = rate-average;
                }
            }
            if(locate_updated){
                [spikes replaceObjectAtIndex:idx withObject:[NSNumber numberWithFloat:locate_spike]];
                [[NSNotificationCenter defaultCenter] postNotificationName:ORRunningAverageChangedNotification object:self userInfo:nil];
                // NSLog(@"channel %d, spike = %g v.s. %g----- \n", idx,rate/average, [[spikes objectAtIndex:idx] floatValue]);
            }
            [[self runningAverageObject:idx] updateAveragewNSN:[ra objectAtIndex:idx]];
            // this is to update the running average, no matter what.

        } //for loop over the channels
               
        if(sampled < [self windowLength])sampled++; //sampled max = windowLength, cannot sample more than demanded. This avoid re-initialization of sampled when the windowLength changes.
    }
    [self performSelector:@selector(calcRunningAverages) withObject:nil afterDelay:[self integrationTime]];
   // Never do something like [ra release]. I didn't allocate ra's memory here, so ra is pointing to some memory of other object.
    //Never release memory of object not created by init, alloc, copy and
}

- (void) resetRates
{
    if(PrintMymessages)NSLog(@"ORRunningAverageGroup, - resetRates");

    [runningAverages makeObjectsPerformSelector:@selector(reset)];//what does this mean?
    //[self setTotalRate:0];
}


@end






//   [[runningAverages objectAtIndex:0] updateAveragewObj:objectKeepingRate];
//    [[runningAverages objectAtIndex:1] updateAveragewObj:objectKeepingRate];
//    [[runningAverages objectAtIndex:2] updateAveragewObj:objectKeepingRate];
//    [[runningAverages objectAtIndex:3] updateAveragewObj:objectKeepingRate];
//    [[runningAverages objectAtIndex:4] updateAveragewObj:objectKeepingRate];
//    [[runningAverages objectAtIndex:5] updateAveragewObj:objectKeepingRate];
//    [[runningAverages objectAtIndex:6] updateAveragewObj:objectKeepingRate];
//    [[runningAverages objectAtIndex:7] updateAveragewObj:objectKeepingRate];
//    [[runningAverages objectAtIndex:8] updateAveragewObj:objectKeepingRate];
//    [[runningAverages objectAtIndex:9] updateAveragewObj:objectKeepingRate];
//
//    [[runningAverages objectAtIndex:0] updateAverage:10.2];
//    [[runningAverages objectAtIndex:1] updateAverage:10.2];
//    [[runningAverages objectAtIndex:2] updateAverage:10.2];
//    [[runningAverages objectAtIndex:3] updateAverage:10.2];
//    [[runningAverages objectAtIndex:4] updateAverage:10.2];
//    [[runningAverages objectAtIndex:5] updateAverage:10.2];
//    [[runningAverages objectAtIndex:6] updateAverage:10.2];
//    [[runningAverages objectAtIndex:7] updateAverage:10.2];
//    [[runningAverages objectAtIndex:8] updateAverage:10.2];
//    [[runningAverages objectAtIndex:9] updateAverage:10.2];

//}
//[runningAverages makeObjectsPerformSelector:@selector(updateAveragewObj:) withObject:objectKeepingRate];
//this is to ask the element of the array of runningAverages to perform updateAveragewNSN
