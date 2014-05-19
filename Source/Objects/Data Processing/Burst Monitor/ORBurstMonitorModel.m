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
- (unsigned short) timeWindow           { return timeWindow; }
- (unsigned short) nHit                 { return nHit; }
- (unsigned short) minimumEnergyAllowed { return minimumEnergyAllowed; }

- (void) setNumBurstsNeeded:(unsigned short)aNumBurstsNeeded
{
    if(aNumBurstsNeeded<1)aNumBurstsNeeded=1;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setNumBurstsNeeded:numBurstsNeeded];
    numBurstsNeeded = aNumBurstsNeeded;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBurstMonitorModelNumBurstsNeededChanged object:self];
}

- (void) setTimeWindow:(unsigned short)aValue
{
    if(aValue<5)aValue = 5;
	[[[self undoManager] prepareWithInvocationTarget:self] setTimeWindow:timeWindow];
    timeWindow = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBurstMonitorTimeWindowChanged object:self];
}

- (void) setNHit:(unsigned short)value
{
	[[[self undoManager] prepareWithInvocationTarget:self] setNHit:nHit];
    nHit = value;
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
                    NSString* runHeaderString   = [[NSString alloc] initWithBytes:&ptr[2] length:ptr[1] encoding:NSASCIIStringEncoding];
                    NSDictionary* runHeader     = [runHeaderString propertyList];
                    shaperID                    = [[runHeader nestedObjectForKey:@"dataDescription",@"ORShaperModel",@"Shaper",@"dataId",nil] unsignedLongValue];
                }
                
                if (dataID == shaperID) {                    
                    if (recordLen>1) {
                        //extract the card's info
                        unsigned short crateNum = ShiftAndExtract(ptr[1],21,0xf);
                        unsigned short cardNum  = ShiftAndExtract(ptr[1],16,0x1f);
                        unsigned short chanNum  = ShiftAndExtract(ptr[1],12,0xf);
                        unsigned short energy   = ShiftAndExtract(ptr[1], 0,0xfff);
                        
                        if(energy >= minimumEnergyAllowed){
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
                            NSData* theShaperRecord = [NSData dataWithBytes:ptr length:recordLen*sizeof(long)];
                            
                            ORBurstData* burstData = [[ORBurstData alloc] init];
                            burstData.datePosted = now;
                            burstData.dataRecord = theShaperRecord;
                            
                            [[queueArray objectAtIndex:queueIndex ] addObject:burstData];
                            [burstData release];
                            
                            [queueLock unlock]; //--end critial section
                        }
                    }
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
    
    NSDate* now = [NSDate date];
    int numBurstingChannels = 0;

    NSArray* allKeys = [queueMap allKeys];
    for(id aKey in allKeys){
        int i     = [[queueMap  objectForKey:aKey]intValue];
        id aQueue = [queueArray objectAtIndex:i];
            
        while ([aQueue count]) {
            ORBurstData* aRecord = [aQueue objectAtIndex:0];
            NSDate* datePosted = aRecord.datePosted;
            
            NSTimeInterval timeDiff = [now timeIntervalSinceDate:datePosted];
            if(timeDiff > timeWindow){
                [aQueue removeObjectAtIndex:0];
            }
            else break; //done -- no records in queue are older than the time window
        }
         
        //check if the number still in the queue would signify a burst then count it.
         if([aQueue count] > nHit){
            numBurstingChannels++;
         }
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORBurstMonitorQueueChanged object:self];
    [queueLock unlock];//--end critial section

    //only tag this as a true burst if the number of detectors seeing the burst is more than the number specified.
    if(numBurstingChannels>=numBurstsNeeded){
        NSLog(@"Burst Detected\n");
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedBurstEvent) object:nil];
        [self performSelector:@selector(delayedBurstEvent) withObject:nil afterDelay:1];
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
    theContent = [theContent stringByAppendingFormat:@"Time Window: %d sec\n",timeWindow];
    theContent = [theContent stringByAppendingFormat:@"Events/Window Needed: %d\n",nHit];
    theContent = [theContent stringByAppendingFormat:@"Minimum ADC Energy: %d\n",minimumEnergyAllowed];
    theContent = [theContent stringByAppendingFormat:@"Minimum Bursts Needed: %d\n",numBurstsNeeded];
    theContent = [theContent stringByAppendingFormat:@"Num Bursts this run: %d\n",burstCount];
    theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
    
    NSArray* allKeys = [[queueMap allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for(id aKey in allKeys){
        int i     = [[queueMap  objectForKey:aKey]intValue];
        id aQueue = [queueArray objectAtIndex:i];
        int count = [aQueue count];
        theContent = [theContent stringByAppendingFormat:@"Channel: %@ Number Events: %d %@\n",aKey,[aQueue count],count>=nHit?@" <---":@""];
    }
    
    theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
    theContent = [theContent stringByAppendingString:@"The following people received this message:\n"];
    for(id address in emailList) theContent = [theContent stringByAppendingFormat:@"%@\n",address];
    theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self cleanupAddresses:emailList],@"Address",theContent,@"Message",nil];
    [self sendMail:userInfo];
    
    //flush all queues to the disk fle
    NSString* fileSuffix = [NSString stringWithFormat:@"Burst_%d_",burstCount];
    [runUserInfo setObject:fileSuffix forKey:kFileSuffix];
	[theBurstMonitoredObject runTaskStarted:runUserInfo];
	[theBurstMonitoredObject setInvolvedInCurrentRun:YES];

    [theBurstMonitoredObject processData:[NSArray arrayWithObject:header] decoder:theDecoder];
    for(NSMutableArray* aQueue in queueArray){
        NSMutableArray* anArrayOfData = [NSMutableArray array];
        //have to extract the raw data record.
        for(ORBurstData* someData in aQueue)[anArrayOfData addObject:someData.dataRecord];
        
        [theBurstMonitoredObject processData:anArrayOfData decoder:theDecoder];
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

- (void) dealloc {
    [datePosted release];
    [dataRecord release];
    [super dealloc];
}
@end
