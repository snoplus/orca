//
//  ORBurstMonitorModel.m
//  Orca
//
//  Created by Mark Howe on Mon Nov 18 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORBurstMonitorModel.h"
#import "ORDataSet.h"
#import "ORDecoder.h"
#import "ORShaperModel.h"
#import "ORDataTypeAssigner.h"
#import "NSData+Extensions.h"
#import "ORMailer.h"

NSString* ORBurstMonitorModelNumBurstsNeededChanged = @"ORBurstMonitorModelNumBurstsNeededChanged";
static NSString* ORBurstMonitorInConnector          = @"BurstMonitor In Connector";
static NSString* ORBurstMonitorOutConnector         = @"BurstMonitor Out Connector";
static NSString* ORBurstMonitorBurstConnector       = @"BurstMonitored Burst Connector";

//========================================================================

#pragma mark •••Notification Strings
NSString* ORBurstMonitorTimeWindowChanged           = @"ORBurstMonitorTimeWindowChangedNotification";
NSString* ORBurstMonitorNHitChanged                 = @"ORBurstMonitorNHitChangedNotification";
NSString* ORBurstMonitorMinimumEnergyAllowedChanged = @"ORBurstMonitorMinimumEnergyAllowedChangedNotification";
NSString* ORBurstMonitorQueueChanged                = @"ORBurstMonitorQueueChangedNotification";
NSString* ORBurstMonitorEmailListChanged		    = @"ORBurstMonitorEmailListChanged";
NSString* ORBurstMonitorLock                        = @"ORBurstMonitorLock";
NSDate* burstStart = NULL;


@interface ORBurstMonitorModel (private)
- (void) deleteQueues;
- (void) monitorQueues;
- (void) delayedBurstEvent;
@end

@implementation ORBurstMonitorModel
#pragma mark •••Initialization
- (id) init //designated initializer
{
	self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [[self undoManager] enableUndoRegistration];
	
	return self;
}

-(void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self deleteQueues];
    [theDecoder release];
    [runUserInfo release];
    [queueLock release];
    [emailList release];
    [burstString release];
    
    [Bchans release];
    [Bcards release];
    [Badcs release];
    [Bsecs release];
    [Bmics release];
    [Bwords release];

    
    [chans release];
    [cards release];
    [adcs release];
    [secs release];
    [mics release];
    [words release];
    [Nchans release];
    [Ncards release];
    [Nadcs release];
    [Nsecs release];
    [Nmics release];

    [super dealloc];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,2*[self frame].size.height/3. - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORBurstMonitorInConnector];
	[aConnector setIoType:kInputConnector];
    [aConnector release];
	
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width/2 - kConnectorSize/2 , 0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORBurstMonitorBurstConnector];
	[aConnector setIoType:kOutputConnector];
    [aConnector release];
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width-kConnectorSize,2*[self frame].size.height/3. - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORBurstMonitorOutConnector];
	[aConnector setIoType:kOutputConnector];
    [aConnector release];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"BurstMonitor"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORBurstMonitorController"];
}

#pragma mark •••Accessors
- (NSArray*) collectConnectedObjectsOfClass:(Class)aClass
{
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
	id obj = [[connectors objectForKey:ORBurstMonitorOutConnector] connectedObject];
	[collection addObjectsFromArray:[obj collectConnectedObjectsOfClass:aClass]];
	return collection;
}

- (unsigned short) numBurstsNeeded      { return numBurstsNeeded; }
- (double) timeWindow           { return timeWindow; }
- (unsigned short) nHit                 { return nHit; }
- (unsigned short) minimumEnergyAllowed { return minimumEnergyAllowed; }

- (void) setNumBurstsNeeded:(unsigned short)aNumBurstsNeeded
{
    if(aNumBurstsNeeded<1)aNumBurstsNeeded=1;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setNumBurstsNeeded:numBurstsNeeded];
    numBurstsNeeded = aNumBurstsNeeded;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBurstMonitorModelNumBurstsNeededChanged object:self];
}

- (void) setTimeWindow:(double)aValue //was unsigned short for integers
{
    if(aValue<0.000001)aValue = 0.000001;
	[[[self undoManager] prepareWithInvocationTarget:self] setTimeWindow:timeWindow];
    timeWindow = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBurstMonitorTimeWindowChanged object:self];
}

- (void) setNHit:(unsigned short)value
{
	[[[self undoManager] prepareWithInvocationTarget:self] setNHit:nHit];
    nHit = value;
    //buffer
    [chans removeAllObjects];
    [cards removeAllObjects];
    [adcs removeAllObjects];
    [secs removeAllObjects];
    [mics removeAllObjects];
    [words removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBurstMonitorNHitChanged object:self];
}



- (void) setMinimumEnergyAllowed:(unsigned short)value
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMinimumEnergyAllowed:minimumEnergyAllowed];
    minimumEnergyAllowed = value;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBurstMonitorMinimumEnergyAllowedChanged object:self];
}

- (NSMutableArray*) queueArray
{
    return queueArray;
}

- (NSMutableDictionary*) queueMap
{
    return queueMap;
}

- (NSMutableArray*) emailList
{
    return emailList;
}

- (void) setEmailList:(NSMutableArray*)aEmailList
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEmailList:emailList];
    
    [aEmailList retain];
    [emailList release];
    emailList = aEmailList;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBurstMonitorEmailListChanged object:self];
}

- (void) addAddress:(id)anAddress atIndex:(int)anIndex
{
	if(!emailList) emailList= [[NSMutableArray array] retain];
	if([emailList count] == 0)anIndex = 0;
	anIndex = MIN(anIndex,[emailList count]);
	
	[[[self undoManager] prepareWithInvocationTarget:self] removeAddressAtIndex:anIndex];
	[emailList insertObject:anAddress atIndex:anIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBurstMonitorEmailListChanged object:self];
}

- (void) removeAddressAtIndex:(int) anIndex
{
	id anAddress = [emailList objectAtIndex:anIndex];
	[[[self undoManager] prepareWithInvocationTarget:self] addAddress:anAddress atIndex:anIndex];
	[emailList removeObjectAtIndex:anIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBurstMonitorEmailListChanged object:self];
}

- (int) channelsCheck:(NSMutableArray*) aChans
{
    int searchChan = 0;
    int numChan = 0;
    while([aChans count]>0)
    {
        searchChan = [[aChans objectAtIndex:(0)] intValue]; //This is first channel, look to see if there are more of it
        int k; //MAH -- declaration has to be outside the loop for XCode < 5.x
        for(k = 1; k<[aChans count]; k++)
        {
            if([[aChans objectAtIndex:(k)] intValue] == searchChan)
            {
                [aChans removeObjectAtIndex:(k)];
                k=k-1;
            }
        }
        [aChans removeObjectAtIndex:(0)];
        numChan++;
    }
    return numChan;
}

#pragma mark •••Data Handling
- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;
{
	//pass it on
	[thePassThruObject processData:dataArray decoder:aDecoder];
    
    if(!theDecoder){
        theDecoder = [aDecoder retain];
    }
    NSDate* now = [NSDate date];
	[dataArray retain];
	//each block of data is an array of NSData objects, each potentially containing many records
	for(id data in dataArray){
		[data retain];
		long totalLen = [data length]/sizeof(long);
		if(totalLen>0){
			unsigned long* ptr = (unsigned long*)[data bytes];
			while(totalLen>0){
				unsigned long dataID = ExtractDataId(ptr[0]);
                long recordLen       = ExtractLength(ptr[0]);
                
                if(recordLen > totalLen){
                    NSLog(@"Bad Record Length\n");
                    NSLogError(@" ",@"BurstMonitor",@"Bad Record:Incorrect Length",nil);
                    printf("Bad Record Length\n");
                    break;
                }
                
                if(dataID==0){
                    header                      = [[NSData dataWithBytes:ptr length:recordLen*4] retain]; //save it for the secondary file
                    NSString* runHeaderString   = [[[NSString alloc] initWithBytes:&ptr[2] length:ptr[1] encoding:NSASCIIStringEncoding] autorelease];
                    NSDictionary* runHeader     = [runHeaderString propertyList];
                    shaperID                    = [[runHeader nestedObjectForKey:@"dataDescription",@"ORShaperModel",@"Shaper",@"dataId",nil] unsignedLongValue];
                }
                // header gets here
                if (dataID == shaperID || burstForce==1) {
                    if (recordLen>1 || burstForce==1) {
                        //extract the card's info
                        unsigned long firstword = ShiftAndExtract(ptr[0], 0, 0xffffffff);
                        
                        unsigned short crateNum = ShiftAndExtract(ptr[1],21,0xf);
                        unsigned short cardNum  = ShiftAndExtract(ptr[1],16,0x1f);
                        unsigned short chanNum  = ShiftAndExtract(ptr[1],12,0xf);
                        unsigned short energy   = ShiftAndExtract(ptr[1], 0,0xfff);
                        
                        unsigned long secondsSinceEpoch = ShiftAndExtract(ptr[2], 0, 0xffffffff);
                        unsigned long microseconds = ShiftAndExtract(ptr[3], 0, 0xffffffff);
                        if(cardNum>=16){
                            break;
                        }
                        quietSec=0;
                        
                        
                        //make array of data to be buffered
                        [chans insertObject:[NSNumber numberWithInt:chanNum] atIndex:0];
                        [cards insertObject:[NSNumber numberWithInt:cardNum] atIndex:0];
                        [adcs insertObject:[NSNumber numberWithInt:energy]  atIndex:0];
                        [secs insertObject:[NSNumber numberWithLong:secondsSinceEpoch] atIndex:0];
                        [mics insertObject:[NSNumber numberWithLong:microseconds] atIndex:0];
                        [words insertObject:[NSNumber numberWithLong:firstword] atIndex:0];
                        if((energy >= minimumEnergyAllowed && cardNum <= 15) || burstForce ==1){  //Filter
                            [self performSelector:@selector(monitorQueues) withObject:nil afterDelay:1];
                            //make a key for looking up the correct queue for this record
                            NSString* aShaperKey = [NSString stringWithFormat:@"%d,%d,%d",crateNum,cardNum,chanNum];
                            
                            [queueLock lock]; //--begin critial section
                            if(![queueMap objectForKey:aShaperKey]){
                                if(!queueArray) queueArray = [[NSMutableArray array] retain];

                                //haven't seen this one before so make a look up table and add a queue for it
                                [queueMap   setObject:[NSNumber numberWithInt:[queueArray count]] forKey:aShaperKey];
                                [queueArray addObject:[NSMutableArray array]];
                            }
                            
                            //get the right queue for this record and insert the record
                            int     queueIndex      = [[queueMap objectForKey:aShaperKey] intValue];
                            NSData* theShaperRecord = [NSData dataWithBytes:ptr length:recordLen*sizeof(long)]; //couldnt put humpdy together again //CBDO re the count
                            
                            ORBurstData* burstData = [[ORBurstData alloc] init];
                            burstData.datePosted = now; //DAQ at LU has a different time zone than the data records do.  It might be best not to mix DAQ time and SBC time in the monitor.
                            burstData.dataRecord = theShaperRecord;
                            NSNumber* epochSec = [NSNumber numberWithLong:secondsSinceEpoch];
                            NSNumber* epochMic = [NSNumber numberWithLong:microseconds];
                            //burstData.epSec = [epochSec copy]; <--- leaks....
                            //burstData.epMic = [epochMic copy]; <--- leaks....
                            burstData.epSec = epochSec; //MAH 9/30/14--no need to copy or retain. the property is doing that.
                            burstData.epMic = epochMic;
                            
                            //[[queueArray objectAtIndex:queueIndex ] addObject:burstData]; //fixme dont add the last event of the burst
                            //[burstData release];
                            int addThisToQueue = 1;
                            
                            [queueLock unlock]; //--end critial section
                            
                            //NSLog(@"length of Nchans is %i", Nchans.count);
                            //fill neutron array
                            [Nchans insertObject:[NSNumber numberWithInt:chanNum] atIndex:0];
                            [Ncards insertObject:[NSNumber numberWithInt:cardNum] atIndex:0];
                            [Nadcs insertObject:[NSNumber numberWithInt:energy]  atIndex:0];
                            [Nsecs insertObject:[NSNumber numberWithLong:secondsSinceEpoch] atIndex:0];
                            [Nmics insertObject:[NSNumber numberWithLong:microseconds] atIndex:0];
                            //NSLog(@"2length of Nchans is %i", Nchans.count);
                            
                            if([Nchans count] >= nHit){ //There is enough data in the buffer now, start looking for bursts
                                int countofchan = [chans count];
                                int countofNchan = [Nchans count]; //CB this probs needs implementing
                                double lastTime = ([[Nsecs objectAtIndex:0] longValue] + 0.000001*[[Nmics objectAtIndex:0] longValue]);
                                double firstTime = ([[Nsecs objectAtIndex:(nHit-1)] longValue] + 0.000001*[[Nmics objectAtIndex:(nHit-1)] longValue]);
                                double diffTime = (lastTime - firstTime);
                                if(diffTime < timeWindow && burstForce==0){ //burst found, start saveing everything untill it stops
                                    burstState = 1;
                                    novaState = 1;
                                    novaP = 1;
                                }
                                else{ //no burst found, stop saveing things and send alarm if there was a burst directly before.
                                    if(burstState == 1){
                                        
                                        [Bchans release];
                                        Bchans = [chans mutableCopy];
                                        
                                        [Bcards release];
                                        Bcards = [cards mutableCopy];

                                        [Badcs  release];
                                        Badcs  = [adcs mutableCopy];

                                        [Bsecs  release];
                                        Bsecs  = [secs mutableCopy];

                                        [Bmics  release];
                                        Bmics  = [mics mutableCopy];

                                        [Bwords release];
                                        Bwords = [words mutableCopy];
                                        
                                        int iter;
                                        NSString* bString;
                                        for(iter=1; iter<countofchan; iter++) //Skip most recent event, print all others
                                        { 
                                            double countTime = [[secs objectAtIndex:iter] longValue] + 0.000001*[[mics objectAtIndex:iter] longValue];
                                            //NSLog(@"count %i t=%f, adc=%i, chan=%i-%i \n", iter, countTime, [[adcs objectAtIndex:iter] intValue], [[cards objectAtIndex:iter] intValue], [[chans objectAtIndex:iter] intValue]);
                                            bString = [bString stringByAppendingString:[NSString stringWithFormat:@"count %i t=%lf, adc=%i, chan=%i-%i \n", iter, countTime, [[adcs objectAtIndex:iter] intValue], [[cards objectAtIndex:iter] intValue], [[chans objectAtIndex:iter] intValue]]];
                                        }
                                        
                                        //Find characturistics of burst
                                        NSMutableArray* reChans = [[Nchans mutableCopy] autorelease]; //MAH added autorelease to prevent memory leak
                                        int j; //MAH -- declaration has to be outside the loop for XCode < 5.x
                                        for(j=0; j<[reChans count]; j++)
                                        {
                                            int chanID = [[reChans objectAtIndex:j] intValue] + 10*[[Ncards objectAtIndex:j] intValue];
                                            [reChans replaceObjectAtIndex:j withObject:[NSNumber numberWithInt:chanID]];
                                        }
                                        [reChans removeObjectAtIndex:(0)];
                                        int numChan = [self channelsCheck:(reChans)];
                                        numBurstChan = numChan;
                                        double startTime = ([[Nsecs objectAtIndex:(countofNchan-1)] longValue] + 0.000001*[[Nmics objectAtIndex:(countofNchan-1)] longValue]);
                                        double endTime = ([[Nsecs objectAtIndex:1] longValue] + 0.000001*[[Nmics objectAtIndex:1] longValue]);
                                        int adcStart = ([[Nadcs objectAtIndex:(countofNchan-1)] intValue]);
                                        durSec = (endTime - startTime);
                                        NSLog(@"Burst duration is %f, start is %f, end is %f, adc %i \n", durSec, startTime, endTime, adcStart);
                                        countsInBurst = countofNchan - 1;
                                        
                                        addThisToQueue = 0;
                                        
                                        [burstString release];
                                        if(bString!=nil)burstString = [bString retain];
                                        else            burstString = @"";
                                        
                                        //NSLog(@"precall \n");
                                        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedBurstEvent) object:nil]; //monitorqueues 2 lines
                                        //[self performSelector:@selector(delayedBurstEvent) withObject:nil afterDelay:0]; //Has no effect
                                        //NSLog(@"postcall \n");
                                        
                                        //fixme //Try to start DelayedBurstEvent directly, but does not work
                                        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(monitorQueues) object:nil];
                                        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedBurstEvent) object:nil]; //copied from monitorqueues, maybe?
                                        //[self performSelector:@selector(monitorQueues) withObject:nil afterDelay:1]; //does not work in this function
                                        //NSInvocation *newvoke = [NSInvocation invocationWithMethodSignature:[self, [instanceMethodSignitureForSelector monitorQueues]];
                                        //newvoke.target = self;
                                        //newvoke.selector = monitorQueues;
                                        //[newvoke setArgument:nil atIndex:2];
                                        //[newvoke invoke];
                                        
                                        if(numBurstChan>=numBurstsNeeded)
                                        {
                                            burstTell = 1;
                                        }
                                        else
                                        {
                                            NSLog(@"Burst had only %i channels, needed %i \n", numBurstChan, numBurstsNeeded);
                                            removedSec = [[secs objectAtIndex:1] longValue];
                                            removedMic = [[mics objectAtIndex:1] longValue];
                                        }
                                        //Clean up
                                        [chans removeAllObjects];
                                        [cards removeAllObjects];
                                        [adcs removeAllObjects];
                                        [secs removeAllObjects];
                                        [mics removeAllObjects];
                                        [words removeAllObjects];
                                        
                                        [Nchans removeAllObjects];
                                        [Ncards removeAllObjects];
                                        [Nadcs removeAllObjects];
                                        [Nsecs removeAllObjects];
                                        [Nmics removeAllObjects];
                                    }//end of burststate = 1 stuff
                                    loudSec=0;
                                    burstForce=0;
                                    novaState = 0;
                                    novaP = 0;
                                    burstState = 0;
                                    if(Nchans.count<nHit){ // happens if a burst had too few channels and just got whiped
                                        [burstData release]; //MAH... added to prevent memory leak on early return.
                                        return;
                                    }
                                    removedSec = [[Nsecs objectAtIndex:(nHit-2)] longValue];
                                    removedMic = [[Nmics objectAtIndex:(nHit-2)] longValue];

                                    //NSLog(@"removed time is now %f \n", removedSec+0.000001*removedMic);
                                    [Nchans removeObjectAtIndex:nHit-1]; //remove old things from the buffer
                                    [Ncards removeObjectAtIndex:nHit-1];
                                    [Nadcs removeObjectAtIndex:nHit-1];
                                    [Nsecs removeObjectAtIndex:nHit-1];
                                    [Nmics removeObjectAtIndex:nHit-1];
                                    int k=0;
                                    for(k = nHit-1; k<chans.count; k++) //remove old things from the buffer (was k<countofchan, this terminates the function);
                                    {
                                        if(([[secs objectAtIndex:k] longValue] + 0.000001*[[mics objectAtIndex:k] longValue])<(removedSec+0.000001*removedMic))
                                        {
                                            //NSLog(@"removeing stuff, index is %i, time is %li.%li \n", k,[[secs objectAtIndex:k] longValue],[[mics objectAtIndex:k] longValue]);
                                            [chans removeObjectAtIndex:k];
                                            [cards removeObjectAtIndex:k];
                                            [adcs removeObjectAtIndex:k];
                                            [secs removeObjectAtIndex:k];
                                            [mics removeObjectAtIndex:k];
                                            [words removeObjectAtIndex:k];
                                            k=k-1;
                                        }
                                    }
                                    //NSLog(@"Nchans,chans lengths: %i,%i \n", [Nchans count], [chans count]);
                                    NSTimeInterval removedSeconds = removedSec;
                                    burstStart = [NSDate dateWithTimeIntervalSince1970:removedSeconds]; //Fixme hard to get consistency, so used removedSec instead
                                }//End of no burst found
                            }//End of Nchans>nHit
                            else{
                                loudSec=0;
                                burstForce=0;
                                NSLog(@"not full, has %i neutrons\n", [Nchans count]);
                                if(burstTell ==1) //Event showed up before burst was prossessed, say it for now but don't record it.
                                {
                                    double lateTime = [[secs objectAtIndex:0] longValue] + 0.000001*[[mics objectAtIndex:0] longValue];
                                    NSLog(@"extra trip: t=%lf, adc=%i, chan=%i-%i \n", lateTime, [[adcs objectAtIndex:0] intValue], [[cards objectAtIndex:0] intValue], [[chans objectAtIndex:0] intValue]);
                                    addThisToQueue = 0;
                                    //Clean up
                                    [chans removeAllObjects];
                                    [cards removeAllObjects];
                                    [adcs removeAllObjects];
                                    [secs removeAllObjects];
                                    [mics removeAllObjects];
                                }
                            }
                            if((addThisToQueue == 1) || (burstState + burstTell ==0)){
                                [[queueArray objectAtIndex:queueIndex ] addObject:burstData]; //fixme dont add the last event of the burst
                                [burstData release];
                            }
                        }//end Filter
                    }//end of valid event with recordlen>1
                }
                
				ptr += recordLen;
				totalLen -= recordLen;
                
			}
		}
		[data release];
	}
	[dataArray release];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:objDictionary forKey:@"BurstMonitorObject"];
	return objDictionary;
}

- (void) runTaskStarted:(id)userInfo
{
    burstCount          = 0;
    shaperID            = 0;

    [theDecoder release];
    theDecoder = nil;
    
	thePassThruObject       = [self objectConnectedTo:ORBurstMonitorOutConnector];
	theBurstMonitoredObject = [self objectConnectedTo:ORBurstMonitorBurstConnector];
	
	[thePassThruObject runTaskStarted:userInfo];
	[thePassThruObject setInvolvedInCurrentRun:YES];
	
    [runUserInfo release];
	runUserInfo = [userInfo mutableCopy];
    
    //make sure we start clean
    [self deleteQueues];
    
    if(!queueLock)queueLock = [[NSRecursiveLock alloc] init];
    queueMap = [[NSMutableDictionary dictionary] retain];
    
    //buffer  clear throut
    chans   = [[NSMutableArray alloc] init];
    cards   = [[NSMutableArray alloc] init];
    adcs    = [[NSMutableArray alloc] init];
    secs    = [[NSMutableArray alloc] init];
    mics    = [[NSMutableArray alloc] init];
    words   = [[NSMutableArray alloc] init];
    
    Nchans  = [[NSMutableArray alloc] init];
    Ncards  = [[NSMutableArray alloc] init];
    Nadcs   = [[NSMutableArray alloc] init];
    Nsecs   = [[NSMutableArray alloc] init];
    Nmics   = [[NSMutableArray alloc] init];
    burstTell   = 0;
    burstState  = 0;
    novaState   = 0;
    novaP       = 0;
    quietSec    = 0;
    loudSec     = 0;
    
    //start the monitoring
    [self performSelector:@selector(monitorQueues) withObject:nil afterDelay:1];
    
}

- (void) subRunTaskStarted:(id)userInfo
{
	//we don't care
}

- (void) runTaskStopped:(id)userInfo
{
    //stop monitoring the queues
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
   
	[thePassThruObject          runTaskStopped:userInfo];
	[thePassThruObject          setInvolvedInCurrentRun:NO];
    //Clean up
    [chans release];
    [cards release];
    [adcs release];
    [secs release];
    [mics release];
    [words release];
    [Nchans release];
    [Ncards release];
    [Nadcs release];
    [Nsecs release];
    [Nmics release];
    
}

- (void) closeOutRun:(id)userInfo
{
	[thePassThruObject       closeOutRun:userInfo];
 

    
    [self deleteQueues];
    
    [theDecoder release];
    theDecoder = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORBurstMonitorQueueChanged object:self];

}

- (void) setRunMode:(int)aMode
{
	[[self objectConnectedTo:ORBurstMonitorOutConnector] setRunMode:aMode];
	[[self objectConnectedTo:ORBurstMonitorBurstConnector] setRunMode:aMode];
}

- (void) runTaskBoundary
{
}

#pragma mark •••Archival
static NSString* ORBurstMonitorTimeWindow			 = @"ORBurstMonitor Time Window";
static NSString* ORBurstMonitorNHit                  = @"ORBurstMonitor N Hit";
static NSString* ORBurstMonitorMinimumEnergyAllowed  = @"ORBurstMonitor Minimum Energy Allowed";

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    
    [self setNumBurstsNeeded:       [decoder decodeIntForKey:@"numBurstsNeeded"]];
    [self setTimeWindow:            [decoder decodeInt32ForKey:ORBurstMonitorTimeWindow]];
    [self setNHit:                  [decoder decodeInt32ForKey:ORBurstMonitorNHit]];
    [self setMinimumEnergyAllowed:  [decoder decodeInt32ForKey:ORBurstMonitorMinimumEnergyAllowed]];
    [self setEmailList:             [decoder decodeObjectForKey:@"emailList"]];
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:numBurstsNeeded               forKey:@"numBurstsNeeded"];
    [encoder encodeInt32:[self timeWindow]		     forKey:ORBurstMonitorTimeWindow];
    [encoder encodeInt32:[self nHit]		         forKey:ORBurstMonitorNHit];
    [encoder encodeInt32:[self minimumEnergyAllowed] forKey:ORBurstMonitorMinimumEnergyAllowed];
	[encoder encodeObject:emailList                  forKey:@"emailList"];
}

#pragma mark •••EMail
- (void) mailSent:(NSString*)address
{
	NSLog(@"Process Center status was sent to:\n%@\n",address);
}

- (void) sendMail:(id)userInfo
{
	NSString* address =  [userInfo objectForKey:@"Address"];
	NSString* content = [NSString string];
	NSString* hostAddress = @"<Unable to get host address>";
	NSArray* names =  [[NSHost currentHost] addresses];
	for(id aName in names){
		if([aName rangeOfString:@"::"].location == NSNotFound){
			if([aName rangeOfString:@".0.0."].location == NSNotFound){
				hostAddress = aName;
				break;
			}
		}
	}
	content = [content stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
	content = [content stringByAppendingFormat:@"ORCA Message From Host: %@\n",hostAddress];
	content = [content stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n\n"];
	NSString* theMessage = [userInfo objectForKey:@"Message"];
	if(theMessage){
		content = [content stringByAppendingString:theMessage];
	}
	
	NSAttributedString* theContent = [[NSAttributedString alloc] initWithString:content];
	ORMailer* mailer = [ORMailer mailer];
	[mailer setTo:address];
	[mailer setSubject:@"HALO Burst Notification"];
	[mailer setBody:theContent];
	[mailer send:self];
	[theContent release];
}

- (NSString*) cleanupAddresses:(NSArray*)aListOfAddresses
{
	NSMutableArray* listCopy = [NSMutableArray array];
	for(id anAddress in aListOfAddresses){
		if([anAddress length] && [anAddress rangeOfString:@"@"].location!= NSNotFound){
			[listCopy addObject:anAddress];
		}
	}
	return [listCopy componentsJoinedByString:@","];
}

- (void) lockArray
{
    [queueLock lock]; //--begin critial section
    
}
- (void) unlockArray
{
    [queueLock unlock];//--end critial section  
}

@end

@implementation ORBurstMonitorModel (private)
- (void) deleteQueues
{
    
    [queueLock lock]; //--begin critial section
    [queueArray release];
    queueArray = nil;

    [queueMap release];
    queueMap = nil;
    [queueLock unlock]; //--end critial section

    [header release];
    header = nil;

}

- (void) monitorQueues
{
    //first make sure that we don't start a new timer
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(monitorQueues) object:nil];
    [queueLock lock]; //--begin critial section
    
    //NSDate* now = [NSDate date];
    int numBurstingChannels = 0;
	int numTotalCounts = 0;

    NSArray* allKeys = [queueMap allKeys];
    for(id aKey in allKeys){
        int i     = [[queueMap  objectForKey:aKey]intValue];
        id aQueue = [queueArray objectAtIndex:i];
            
        while ([aQueue count]) {
			ORBurstData* aRecord = [aQueue objectAtIndex:0]; 
            //NSDate* datePosted = aRecord.datePosted;
            double timePosted = ([aRecord.epSec longValue] + 0.000001*[aRecord.epMic longValue]);
            double timeRemoved = (removedSec + 0.000001*removedMic);
            if(timePosted < timeRemoved){
                [aQueue removeObjectAtIndex:0];
            }
            else break; //done -- no records in queue are older than the time window
        }
		numTotalCounts = numTotalCounts + [aQueue count];
        //check if the number still in the queue would signify a burst then count it.
         if([aQueue count] >= 1){
            numBurstingChannels++;
         }
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORBurstMonitorQueueChanged object:self];
    [queueLock unlock];//--end critial section

    //only tag this as a true burst if the number of detectors seeing the burst is more than the number specified.
    //if(numBurstingChannels>=numBurstsNeeded && numTotalCounts>=nHit){
    if(burstTell == 1){  //just call delayedburst when told by data proc //fixme need to remove last event from buffer, or not add it to queue
        burstTell = 0;
        NSLog(@"numBurstingChannels is %i \n", numBurstingChannels);
        NSLog(@"Burst Detected\n");
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedBurstEvent) object:nil]; //CB dissabled for now
        [self performSelector:@selector(delayedBurstEvent) withObject:nil afterDelay:0];
    }
    //Check stall in buffer
    if(burstState == 1){
        quietSec++;
        loudSec=[[secs objectAtIndex:1] longValue] - [[secs objectAtIndex:(secs.count-1)] longValue];
        if(quietSec > 30){
            burstForce=1;
            [theBurstMonitoredObject processData:[NSArray arrayWithObject:header] decoder:theDecoder];
        }
        if(loudSec > 120){
            burstForce=1;
            //[theBurstMonitoredObject processData:[NSArray arrayWithObject:header] decoder:theDecoder];
        }
    }

    [self performSelector:@selector(monitorQueues) withObject:nil afterDelay:1];
}

- (void) delayedBurstEvent
{
    burstCount++;
    [queueLock lock]; //--begin critial section
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedBurstEvent) object:nil];
    //send email to announce the burst
    NSString* theContent = @"";
    theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
    theContent = [theContent stringByAppendingFormat:@"This report was generated automatically at:\n"];
    theContent = [theContent stringByAppendingFormat:@"%@ (Local time of ORCA machine)\n",[[NSDate date]descriptionWithCalendarFormat:nil timeZone:nil locale:nil]];
    theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
    theContent = [theContent stringByAppendingFormat:@"Time Window: %f sec\n",timeWindow];
    theContent = [theContent stringByAppendingFormat:@"Events/Window Needed: %d\n",nHit];
    theContent = [theContent stringByAppendingFormat:@"Minimum ADC Energy: %d\n",minimumEnergyAllowed];
    theContent = [theContent stringByAppendingFormat:@"Number of channels required: %d\n",numBurstsNeeded];
    theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
    theContent = [theContent stringByAppendingFormat:@"Number of counts in the burst: %d\n",countsInBurst];
    theContent = [theContent stringByAppendingFormat:@"Number of channels in this burst: %d\n",numBurstChan];
    theContent = [theContent stringByAppendingFormat:@"Duration of burst: %f seconds \n",durSec];
    theContent = [theContent stringByAppendingFormat:@"Num Bursts this run: %d\n",burstCount];
    theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
    theContent = [theContent stringByAppendingString:burstString];
    theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
    
    NSArray* allKeys = [[queueMap allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for(id aKey in allKeys){
        int i     = [[queueMap  objectForKey:aKey]intValue];
        id aQueue = [queueArray objectAtIndex:i];
        int count = [aQueue count];
        theContent = [theContent stringByAppendingFormat:@"Channel: %@ Number Events: %d %@\n",aKey,[aQueue count],count>=1?@" <---":@""];
    }
    
    theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
    theContent = [theContent stringByAppendingString:@"The following people received this message:\n"];
    for(id address in emailList) theContent = [theContent stringByAppendingFormat:@"%@\n",address];
    theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
    
    NSLog(@"theContent in delayedBurstEvent is: \n %@", theContent);
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self cleanupAddresses:emailList],@"Address",theContent,@"Message",nil];
    [self sendMail:userInfo];
    
    //flush all queues to the disk fle
    NSString* fileSuffix = [NSString stringWithFormat:@"Burst_%d_",burstCount];
    [runUserInfo setObject:fileSuffix forKey:kFileSuffix];
	[theBurstMonitoredObject runTaskStarted:runUserInfo];
	[theBurstMonitoredObject setInvolvedInCurrentRun:YES];

    //Creating the data file
    [theBurstMonitoredObject processData:[NSArray arrayWithObject:header] decoder:theDecoder]; //this is the header of the data file
    NSMutableArray* anArrayOfData = [NSMutableArray array];
    //Make the data record from the burst array
    int BurstSize = Bchans.count;
    NSLog(@"Size of burst file: %i \n", (BurstSize - 1) );
    int l;
    for(l=1;l<BurstSize; l++)
    {
        
        //------------------------
        //MAH 09/16/14 Some notes:
        //this was some really bad code below... modified slightly by MAH to get rid of compiler warnings.
        //you should review this and make additional changes. Please review the use of pointers and objects...
        //if you are trying to make a data record, we need to talk. you need to use the proper data id and data
        //record size in the first word in order to have it work....
        //-------------------------
        ORBurstData* someData = [[[ORBurstData alloc] init] autorelease]; //<<<<MAH. added the autorelease to prevent memory leak below. //was separate, test
        //someData.epSec=[[Bsecs objectAtIndex:l] longValue]; //crashes from bad access, but seems unneccesary //fixme?
        //someData.epMic=[[Bmics objectAtIndex:l] longValue];
       // unsigned long* testsec[4]; <<--this is not being used as a pointer. removed MAH 09/16/14
        unsigned long testsec[4];
        testsec[0]=[[Bwords objectAtIndex:l] longValue];
        testsec[1]=[[Badcs objectAtIndex:l] longValue]+(4096*[[Bchans objectAtIndex:l] longValue])+(65536*[[Bcards objectAtIndex:l] longValue]); // adc 3 digets, channel, card
        testsec[2]=[[Bsecs objectAtIndex:l] longValue];
        testsec[3]=[[Bmics objectAtIndex:l] longValue]; //CB works, make data file from array now
        //someData.dataRecord = [NSData dataWithBytes:&testsec length: sizeof(testsec)]; <<--removed MAH 09/16/14
        someData.dataRecord = [NSData dataWithBytes:testsec length: sizeof(testsec)];
        [anArrayOfData addObject:someData.dataRecord];
    }
    [theBurstMonitoredObject processData:anArrayOfData decoder:theDecoder];
    //end of adding things to the data file
    
    for(NSMutableArray* aQueue in queueArray){
        //Data file writing was here before
        //for(ORBurstData* someData in aQueue)
        //[anArrayOfData addObject:someData.dataRecord];
        [aQueue removeAllObjects];
    }
    [queueLock unlock];//--end critial section
    
	[theBurstMonitoredObject    runTaskStopped:userInfo];
    [theBurstMonitoredObject    closeOutRun:userInfo];
	[theBurstMonitoredObject    setInvolvedInCurrentRun:NO];
}

@end

@implementation ORBurstData

@synthesize datePosted;
@synthesize dataRecord;
@synthesize epSec;
@synthesize epMic;

- (void) dealloc
{
    //release the properties
    self.dataRecord =   nil;
    self.datePosted =   nil;
    self.epSec      =   nil;
    self.epMic      =   nil;
    [super dealloc];
}
@end
