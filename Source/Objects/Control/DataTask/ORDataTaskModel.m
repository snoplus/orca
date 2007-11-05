//
//  ORDataTaskModel.m
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
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

#pragma mark ¥¥¥Imported Files
#import "ORDataTaskModel.h"
#import "ORDataTaker.h"
#import "ORReadOutList.h"
#import "ORDataSet.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"
#import "ORGateGroup.h"

#pragma mark ¥¥¥Local Strings
static NSString* ORDataTaskInConnector 	= @"Data Task In Connector";
static NSString* ORDataTaskDataOut      = @"Data Task Data Out Connector";

NSString* ORDataTaskCollectModeChangedNotification	= @"Data Task Mode Changed Notification";
NSString* ORDataTaskQueueCountChangedNotification	= @"Data Task Queue Count Changed Notification";
NSString* ORDataTaskTimeScalerChangedNotification	= @"ORDataTaskTimeScalerChangedNotification";
NSString* ORDataTaskListLock						= @"ORDataTaskListLock";
NSString* ORDataTaskCycleRateChangedNotification	= @"ORDataTaskCycleRateChangedNotification";

#define kMaxQueueSize   10*1024
#define kQueueHighWater kMaxQueueSize*.90
#define kQueueLowWater  kQueueHighWater*.90
#define kProcessingBusy 1
#define kProcessingDone 0

@interface ORDataTaskModel (private)
- (void)   sendDataFromQueue;
- (void) shipPendingRecords:(ORDataPacket*)aDataPacket;
@end

@implementation ORDataTaskModel

#pragma mark ¥¥¥initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setReadOutList:[[[ORReadOutList alloc] initWithIdentifier:@"Data Task ReadOut"]autorelease]];
	timerLock = [[NSLock alloc] init];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [timerLock release];
    
	if(transferDataPacket){
		[transferDataPacket release];
		transferDataPacket = nil;
	}
	
    if(transferQueue){
        [transferQueue release];
        transferQueue = nil;
    }
	
    [queueFullAlarm clearAlarm];
    [queueFullAlarm release];
    [readOutList release];
    [dataTakers release];
    [super dealloc];
}

- (void) sleep
{
    [super sleep];
    
    [queueFullAlarm clearAlarm];
    [queueFullAlarm release];
    queueFullAlarm = nil;
    
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"DataTask"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORDataTaskController"];
}


- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(8,[self frame].size.height-[self frame].size.height/2+kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORDataTaskInConnector];
    [aConnector setOffColor:[NSColor purpleColor]];
    [aConnector setConnectorType:'RUNC'];
    [aConnector release];
    
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize-2,[self frame].size.height-[self frame].size.height/2+kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORDataTaskDataOut];
    [aConnector release];
    
}


-(void)registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver: self
                     selector: @selector(queueRecordForShipping:)
                         name: ORQueueRecordForShippingNotification
                       object: nil];
    
}
#pragma mark ¥¥¥Accessors
- (short) timeScaler
{
	return timeScaler;
}
- (void) setTimeScaler:(short)aValue
{
	if(aValue == 0)aValue = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeScaler:timeScaler];
    
	timeScaler = aValue;
	
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORDataTaskTimeScalerChangedNotification
                      object:self];
	
}

- (ORReadOutList*) readOutList
{
    return readOutList;
}

- (void) setReadOutList:(ORReadOutList*)someDataTakers
{
    [someDataTakers retain];
    [readOutList release];
    readOutList = someDataTakers;
}

- (BOOL) collectMode
{
    return collectMode;
}
- (void) setCollectMode:(BOOL)newMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCollectMode:[self collectMode]];
    collectMode=newMode;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORDataTaskCollectModeChangedNotification
                      object:self];
}

- (unsigned long)cycleRate
{
	return cycleRate;
}
- (void) setCycleRate:(unsigned long)aRate
{
	cycleRate = cycleCount;
	cycleCount = 0;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORDataTaskCycleRateChangedNotification
                      object:self];
}

// ===========================================================
// - queueCount:
// ===========================================================
- (unsigned long)queueCount
{
    return queueCount;
}

// ===========================================================
// - setQueueCount:
// ===========================================================
- (void)setQueueCount:(unsigned long)aQueueCount
{
    queueCount = aQueueCount;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORDataTaskQueueCountChangedNotification
                      object:self];
    
}

- (unsigned long) queueMaxSize
{
    return kMaxQueueSize;
}

- (NSString *)lastFile
{
    return lastFile;
}

- (void)setLastFile:(NSString *)aLastFile
{
    [lastFile autorelease];
    lastFile = [aLastFile copy];
}

- (unsigned long) dataTimeHist:(int)index
{
    return dataTimeHist[index];
}
- (unsigned long) processingTimeHist:(int)index
{
    return processingTimeHist[index];
}

- (void) clearTimeHistogram
{
    memset(processingTimeHist,0,kTimeHistoSize*sizeof(unsigned long));
    memset(dataTimeHist,0,kTimeHistoSize*sizeof(unsigned long));
}

- (void) setEnableTimer:(int)aState
{
	[timerLock lock];	//start critical section
	enableTimer = aState;
	if(enableTimer){
		[self clearTimeHistogram];
		dataTimer = [[ORTimer alloc]init];
		mainTimer = [[ORTimer alloc]init];
		[dataTimer start];
		[mainTimer start];
	}
	else {
		[dataTimer release];
		[mainTimer release];
		dataTimer = nil;
		mainTimer = nil;
	}
	[timerLock unlock];	//end critical section
}


#pragma mark ¥¥¥Run Management
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if(processThreadRunning){
		NSLogColor([NSColor redColor],@"Processing Thread still running from last run\n");
	}
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doCycleRate) object:nil];
	[self clearTimeHistogram];
    
    runStartTime = times(&runStartTmsTime); 
        
	if(enableTimer){
		[timerLock lock];	//start critical section
		dataTimer = [[ORTimer alloc]init];
		mainTimer = [[ORTimer alloc]init];
		[dataTimer start];
		[mainTimer start];
		[timerLock unlock];	//end critical section
	}
    
    //tell all data takers to get ready
    if(collectMode == kDataTaskAutoCollect){
        NSMutableArray* classList = [NSMutableArray arrayWithArray:[[self document]  collectObjectsConformingTo:@protocol(ORDataTaker)]];
        dataTakers = [classList retain];
        
    }
    else {
        dataTakers = [[readOutList allObjects] retain];
    }
    
	if([dataTakers count] == 0){
		NSLogColor([NSColor redColor],@"----------------------------------------------------------\n");
		NSLogColor([NSColor redColor],@"Warning: Run Started with empty readout list.\n");
		NSLogColor([NSColor redColor],@"----------------------------------------------------------\n");
	}
	
    cachedNumberDataTakers = [dataTakers count];
    doGateProcessing = [[[self document] gateGroup] count] > 0;
    if(doGateProcessing){
        NSLog(@"Gates will be processed.\n");
        cachedGateGroup = [[self document] gateGroup];
        [aDataPacket addDataDescriptionItem:[cachedGateGroup dataRecordDescription] forKey:@"ORGateGroup"];    
    }
    else cachedGateGroup = nil;
    
	cachedDataTakers = (id*)malloc(cachedNumberDataTakers * sizeof(id));
	
    int i;
    for(i=0;i<cachedNumberDataTakers;i++){
		id obj = [dataTakers objectAtIndex:i];
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
		cachedDataTakers[i] = obj;
    }
    
    
    //tell objects to add any additional data descriptions into the data description header.
    NSArray* objectList = [NSArray arrayWithArray:[[self document]collectObjectsRespondingTo:@selector(appendDataDescription:userInfo:)]];
    NSEnumerator* e = [objectList objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj appendDataDescription:aDataPacket userInfo:userInfo];
    }
	
//---------------------------------------------------
// comment out some in-development code.....
	NSMutableDictionary* eventDictionary = [NSMutableDictionary dictionary];
	[readOutList appendEventDictionary:eventDictionary topLevel:eventDictionary];
	if([eventDictionary count]){
		[aDataPacket addEventDescriptionItem:eventDictionary];
	}
//---------------------------------------------------	
    
    [aDataPacket generateObjectLookup];	 //MUST be done before data header will work.

	if(transferDataPacket){
		[transferDataPacket release];
		transferDataPacket = nil;
	}
    transferDataPacket  = [aDataPacket copy];
    [transferDataPacket generateObjectLookup];	//MUST be done before data header will work.
    [transferDataPacket clearData];	

   if(transferQueue){
        [transferQueue release];
        transferQueue = nil;
    }
    transferQueue       = [[ORSafeQueue alloc] init];
    
    //cache the next object
    nextObject =  [self objectConnectedTo: ORDataTaskDataOut];
    [nextObject runTaskStarted:aDataPacket userInfo:userInfo];
    	
	timeToStopProcessThread = NO;
    [NSThread detachNewThreadSelector:@selector(sendDataFromQueue) toTarget:self withObject:nil];
	NSLog(@"Processing Thread Started\n");
    
	cycleCount = 0;
	cycleRate  = 0;
    [self performSelector:@selector(doCycleRate) withObject:nil afterDelay:1];
	[aDataPacket startFrameTimer];
}

//-------------------------------------------------------------------------
//putDataInQueue -- operates out of the data taking thread it should not be
//called from anywhere else.
//-------------------------------------------------------------------------
- (void) putDataInQueue:(ORDataPacket*)aDataPacket force:(BOOL)forceAdd
{
	[aDataPacket addFrameBuffer:forceAdd];
    
    if([aDataPacket dataCount]){
        if([transferQueue count] < kQueueHighWater){
			BOOL result = [transferQueue tryEnqueueArray:[aDataPacket dataArray]];
			if(result) [aDataPacket clearData]; //remove old data
			else if(forceAdd){
				[transferQueue enqueueArray:[aDataPacket dataArray]];
                [aDataPacket clearData]; //remove old data
            }
        }
		else  [aDataPacket clearData]; //que is full throw it away.
		
    }
}
//-------------------------------------------------------------------------

//takeData...
//this operates out of the data taking thread. It should not be called from anywhere else.
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
        
	//ship pending records.
	if(areRecordsPending){
		id rec;
		while(rec = [recordsPending dequeue]){
			[aDataPacket addData:rec];
		}
		areRecordsPending = NO;
	}
    
    int i=0;
	while(i<cachedNumberDataTakers){
        [cachedDataTakers[i] takeData:aDataPacket userInfo:userInfo];
		++i;
    }
    

    [aDataPacket addCachedData];
    [self putDataInQueue:aDataPacket force:NO];   
    
    if(doGateProcessing){
		if([aDataPacket addedData]){
			[cachedGateGroup addProcessFlag:aDataPacket];
			[aDataPacket setAddedData:NO];
		}
    }
	
	if(enableTimer){
		[timerLock lock];	//start critical section
		long delta = [dataTimer microseconds];
		if(timeScaler==0)timeScaler=1;
		if((delta/timeScaler) < kTimeHistoSize)dataTimeHist[(int)delta/timeScaler]++;
		else dataTimeHist[kTimeHistoSize-1]++;
		[dataTimer reset];
		[timerLock unlock];	//end critical section
	}
	++cycleCount;
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	
    int i;
    for(i=0;i<cachedNumberDataTakers;i++){
        [cachedDataTakers[i] runTaskStopped:aDataPacket userInfo:userInfo];
    }
    free(cachedDataTakers);
    [nextObject runTaskStopped:aDataPacket userInfo:userInfo];
    [self putDataInQueue:aDataPacket force:YES];	//last data packet for this run
    [aDataPacket addCachedData];	 //data from other threads
    [self shipPendingRecords:aDataPacket];
    [self putDataInQueue:aDataPacket force:YES];	//last data packet for this run
	
    [self setQueueCount:[transferQueue count]];
	[self setCycleRate:0];
    cachedGateGroup = nil;    
}

- (void) closeOutRun:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	
    [self shipPendingRecords:aDataPacket];
    [self putDataInQueue:aDataPacket force:YES];	//last data packet for this run
	
    
    //issue a final call for actions at end of run time.
    NSDictionary* statusInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:eRunStopped], ORRunStatusValue,
        @"Last Call",                         ORRunStatusString,
        aDataPacket,                          @"DataPacket",
        nil];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunFinalCallNotification
                                                        object: self
                                                      userInfo: statusInfo];
	
    //wait for the processing thread to exit.
	float totalTime = 0;
    while(processThreadRunning){
		timeToStopProcessThread = YES;
		[NSThread sleepUntilDate:[[NSDate date] addTimeInterval:.1]];
		totalTime += .2;
		if(totalTime > 20){
			NSLogColor([NSColor redColor], @"Processing Thread Failed to stop.....You should stop and restart ORCA!\n");
			break;
		}
	}	
	
	NSLog(@"Close out run\n");
    //tell everyone it's over and done.
    [nextObject closeOutRun:aDataPacket userInfo:userInfo];
	

	NSLog(@"Final end of run cleanup\n");
    nextObject = nil;
    
    [dataTakers release];
    dataTakers = nil;
    cachedNumberDataTakers = 0; 
    
    
	if(enableTimer){
		[timerLock lock];	//start critical section
		[dataTimer release];
		[mainTimer release];
        dataTimer = nil;
        mainTimer = nil;
		[timerLock unlock];	//end critical section
	}
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doCycleRate) object:nil];
	[aDataPacket stopFrameTimer];
	[self setCycleRate:0];
	[self setQueueCount:0];
   
}


- (void) processData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    id obj =  [self objectConnectedTo: ORDataTaskDataOut];
    [obj processData:aDataPacket userInfo:userInfo];
}

#pragma mark ¥¥¥Archival
static NSString *ORDataTaskReadOutList 		= @"ORDataTask ReadOutList";
static NSString *ORDataTaskCollectMode 		= @"ORDataTask CollectMode";
static NSString *ORDataTaskLastFile 		= @"ORDataTask LastFile";
static NSString *ORDataTaskTimeScaler		= @"ORDataTaskTimeScaler";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setReadOutList:[decoder decodeObjectForKey:ORDataTaskReadOutList]];
    [self setCollectMode:[decoder decodeBoolForKey:ORDataTaskCollectMode]];
    [self setLastFile:[decoder decodeObjectForKey:ORDataTaskLastFile]];
    [self setTimeScaler:[decoder decodeIntForKey:ORDataTaskTimeScaler]];
    [[self undoManager] enableUndoRegistration];
  	if(timeScaler=0)timeScaler = 1;
    
    timerLock = [[NSLock alloc] init];
    [self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:readOutList forKey:ORDataTaskReadOutList];
    [encoder encodeBool:collectMode forKey:ORDataTaskCollectMode];
    [encoder encodeObject:lastFile forKey:ORDataTaskLastFile];
    [encoder encodeInt:timeScaler forKey:ORDataTaskTimeScaler];
}


#pragma mark ¥¥¥Save/Restore
- (void) saveReadOutListTo:(NSString*)fileName
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:fileName])[fileManager removeFileAtPath:fileName handler:nil];
    [fileManager createFileAtPath:fileName contents:nil attributes:nil];
    NSFileHandle* theFile = [NSFileHandle fileHandleForWritingAtPath:fileName];
    [readOutList saveUsingFile:theFile];
    [theFile closeFile];
    NSLog(@"Saved ReadOut List to: %@\n",[fileName stringByAbbreviatingWithTildeInPath]);
}

- (void) loadReadOutListFrom:(NSString*)fileName
{
    
    [self setReadOutList:[[[ORReadOutList alloc] initWithIdentifier:@"Data Task ReadOut"]autorelease]];
    
    NSFileHandle* theFile = [NSFileHandle fileHandleForReadingAtPath:fileName];
    [readOutList loadUsingFile:theFile];
    [theFile closeFile];
    NSLog(@"Loaded ReadOut List from: %@\n",[fileName stringByAbbreviatingWithTildeInPath]);
}

- (void) queueRecordForShipping:(NSNotification*)aNote
{
    if(!recordsPending){
        recordsPending = [[ORSafeQueue alloc] init];
    }
    [recordsPending enqueue:[aNote object]];
	areRecordsPending = YES;
}

- (void) doCycleRate
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doCycleRate) object:nil];
	[self setCycleRate:cycleCount];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORDataTaskQueueCountChangedNotification
                      object:self];
    [self performSelector:@selector(doCycleRate) withObject:nil afterDelay:1];
}
@end

@implementation ORDataTaskModel (private)

//-----------------------------------------------------------
//sendDataFromQueue runs out of the processing thread
//-----------------------------------------------------------
- (void) sendDataFromQueue
{
	NSAutoreleasePool *threadPool = [[NSAutoreleasePool allocWithZone:nil] init];
	[NSThread setThreadPriority:.8];
    id theNextObject =  [self objectConnectedTo: ORDataTaskDataOut];
	BOOL flushMessagePrintedOnce = NO;
    BOOL timeToQuit              = NO;
	processThreadRunning = YES;
    do {
		NSAutoreleasePool *pool = [[NSAutoreleasePool allocWithZone:nil] init];
		unsigned long qc = [transferQueue count];
		if(qc){
			queueCount = qc;
			
			if(queueCount > kQueueHighWater ){
				if(!queueFullAlarm){
					NSLogColor([NSColor redColor],@"Data Queue > 90%% full!\n");
					NSLogError(@"Queue Filled",@"Data Read_out",nil);
					
					queueFullAlarm = [[ORAlarm alloc] initWithName:@"Data Queue Full" severity:kDataFlowAlarm];
					[queueFullAlarm setSticky:YES];
					[queueFullAlarm setAcknowledged:NO];
					[queueFullAlarm postAlarm];
				}
			}
			else if(queueFullAlarm && (queueCount < kQueueLowWater)){
				NSLog(@"Data Queue clearing.\n");
				[queueFullAlarm clearAlarm];
				[queueFullAlarm release];
				queueFullAlarm = nil;
			}
			
			NS_DURING 
				NSArray* theDataArray = [transferQueue dequeueArray];
				if(theDataArray){
					unsigned long theFirstLong = *((unsigned long*)[[theDataArray objectAtIndex:0] bytes]);
					if(theFirstLong !=0){
						[transferDataPacket addDataFromArray:theDataArray];
						[theNextObject processData:transferDataPacket userInfo:nil];
					}
					else {
						NSLogError(@"Main Queue Exception",@"Data Read_out",@"First Word of Record == 0",nil);
					}
				}
				[transferDataPacket clearData];
			NS_HANDLER
				NSLogError(@"Main Queue Exception",@"Data Read_out",nil);
			NS_ENDHANDLER
			
		}
		else {
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		}
		
		if(enableTimer){
			[timerLock lock];	//start critical section
			float delta = [mainTimer microseconds];
			if(timeScaler==0)timeScaler = 1;
			if(delta/timeScaler<kTimeHistoSize)processingTimeHist[(int)delta/timeScaler]++;
			else processingTimeHist[kTimeHistoSize-1]++;
			[mainTimer reset];
			[timerLock unlock];	//end critical section
		}
		
		
		if(timeToStopProcessThread){
			queueCount = [transferQueue count];
			if(!flushMessagePrintedOnce){
				if(queueCount){
					NSLog(@"flushing %d block%@from processing queue\n",queueCount,(queueCount>1)?@"s ":@" ");
				}
				flushMessagePrintedOnce = YES;						
			}
			if(queueCount == 0)timeToQuit = YES;
		}
		[pool release];
	} while(!timeToQuit);
			
	NSLog(@"Processing Thread Exited\n");
	[threadPool	release];
	
	processThreadRunning = NO;
}

- (void) shipPendingRecords:(ORDataPacket*)aDataPacket
{
	if(areRecordsPending){
		id rec;
		while(rec = [recordsPending dequeue]){
			[aDataPacket addData:rec];
		}
		areRecordsPending = NO;
	}
}



@end
