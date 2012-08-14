//
//  ORRunListModel.m
//  Orca
//
//  Created by Mark Howe on Tues Feb 09 2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
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
#import "ORRunListModel.h"
#import "ORDataPacket.h"
#import "ORDataProcessing.h"
#import "TimedWorker.h"
#import "ORRunModel.h"
#import "ORScriptIDEModel.h"
#import "ORScriptRunner.h"

#define kTimeDelta .1

#pragma mark •••Local Strings
NSString* ORRunListModelTimesToRepeatChanged	= @"ORRunListModelTimesToRepeatChanged";
NSString* ORRunListModelLastFileChanged			= @"ORRunListModelLastFileChanged";
NSString* ORRunListModelRandomizeChanged		= @"ORRunListModelRandomizeChanged";
NSString* ORRunListModelWorkingItemIndexChanged = @"ORRunListModelWorkingItemIndexChanged";
NSString* ORRunListItemsAdded		= @"ORRunListItemsAdded";
NSString* ORRunListItemsRemoved		= @"ORRunListItemsRemoved";
NSString* ORRunListListLock			= @"ORRunListListLock";
NSString* ORRunListRunStateChanged	= @"ORRunListRunStateChanged";
NSString* ORRunListModelReloadTable	= @"ORRunListModelReloadTable";

static NSString* ORRunListDataOut	= @"ORRunListDataOut";

@interface ORRunListModel (private)
- (void) checkStatus;
- (void) restoreRunModelOptions;
- (void) saveRunModelOptions;
- (void) setWorkingItemIndex:(int)aWorkingItemIndex;
- (void) incWorkingIndex;
- (id) getScriptParameters;
- (void) resetItemStates;
- (void) setWorkingItemState;
- (id) objectAtWorkingIndex;
- (void) calcTotalExpectedTime;
@end

@implementation ORRunListModel

#pragma mark •••initialization
- (id) init
{
    self = [super init];
	[self registerNotificationObservers];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [lastFile release];
	[runModel release];
	[scriptModel release];
	[timedWorker release];
	[items release];
	[orderArray release];
    [super dealloc];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(10,0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORRunListDataOut];
	[aConnector setIoType:kOutputConnector];
	[aConnector setConnectorType: 'SCRO'];
	[aConnector addRestrictedConnectionType: 'SCRI']; //can only connect to Script Inputs
    [aConnector release];
}

//- (BOOL) solitaryObject
//{
//    return YES;
//}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"RunList"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORRunListController"];
}

- (NSString*) helpURL
{
	return @"Data_Chain/Run_List.html";
}

#pragma mark ***Accessors

- (int) executionCount
{
    return executionCount;
}

- (int) timesToRepeat
{
    return timesToRepeat;
}

- (void) setTimesToRepeat:(int)aTimesToRepeat
{
	if(aTimesToRepeat<1)aTimesToRepeat=1;
    [[[self undoManager] prepareWithInvocationTarget:self] setTimesToRepeat:timesToRepeat];
    
    timesToRepeat = aTimesToRepeat;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelTimesToRepeatChanged object:self];
}

- (NSString*) lastFile
{
	if(![lastFile length]) return @"--";
    else return lastFile;
}

- (void) setLastFile:(NSString*)aLastFile
{
    [lastFile autorelease];
    lastFile = [aLastFile copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelLastFileChanged object:self];
}

- (BOOL) randomize
{
    return randomize;
}

- (void) setRandomize:(BOOL)aRandomize
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRandomize:randomize];
    
    randomize = aRandomize;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelRandomizeChanged object:self];
}
- (TimedWorker*) timedWorker
{
	return timedWorker;
}

- (int) workingItemIndex
{
    return workingItemIndex;
}

- (BOOL) isRunning
{
    return timedWorker != nil;
}

- (void) stopRunning
{
	runListState = kFinishUp;
}

- (void) startRunning
{
	timedWorker = [[TimedWorker TimeWorkerWithInterval:kTimeDelta] retain]; 
	[timedWorker runWithTarget:self selector:@selector(checkStatus)];
	runListState = kStartup;
	executionCount = 0;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRunListRunStateChanged object:self];
}

- (void) addItem
{
	if(!items) items= [[NSMutableArray array] retain];
	id newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"-",@"RunState",nil];
	[self addItem:newItem atIndex:[items count]];
}

- (void) addItem:(id)anItem atIndex:(int)anIndex
{
	if(!items) items= [[NSMutableArray array] retain];
	if([items count] == 0)anIndex = 0;
	anIndex = MIN(anIndex,[items count]);
	[[[self undoManager] prepareWithInvocationTarget:self] removeItemAtIndex:anIndex];
	[items insertObject:anItem atIndex:anIndex];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListItemsAdded object:self userInfo:userInfo];
}

- (void) removeItemAtIndex:(int) anIndex
{
	id anItem = [items objectAtIndex:anIndex];
	[[[self undoManager] prepareWithInvocationTarget:self] addItem:anItem atIndex:anIndex];
	[items removeObjectAtIndex:anIndex];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListItemsRemoved object:self userInfo:userInfo];
}

- (id) itemAtIndex:(int)anIndex
{
	if(anIndex>=0 && anIndex<[items count])return [items objectAtIndex:anIndex];
	else return nil;
}

- (unsigned long) itemCount
{
	return [items count];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [notifyCenter addObserver : self
                     selector : @selector(runHalted:)
                         name : ORRunModelRunHalted
                       object : nil];
}

- (void)runHalted:(NSNotification*)aNote
{   
    runListState = kFinishUp;
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setTimesToRepeat:[decoder decodeIntForKey:@"timesToRepeat"]];
    [self setLastFile:[decoder decodeObjectForKey:@"lastFile"]];
    [self setRandomize:[decoder decodeBoolForKey:@"randomize"]];
	items = [[decoder decodeObjectForKey:@"items"] retain];
	
	for(id anItem in items){ 
		[anItem setObject:@"" forKey:@"RunState"];
	}
	
    [self registerNotificationObservers];

    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInt:timesToRepeat forKey:@"timesToRepeat"];
	[encoder encodeObject:lastFile forKey:@"lastFile"];
	[encoder encodeBool:randomize forKey:@"randomize"];
	[encoder encodeObject:items			forKey:@"items"];
}

- (void) saveToFile:(NSString*)aPath
{
	NSString* s = @"#Script Parameters:RunLength:SubRun\n";
	for(id anItem in items){ 
        if(![[anItem objectForKey:@"ScriptParameters"]length] && ![[anItem objectForKey:@"RunLength"]length] && ![[anItem objectForKey:@"SubRun"]length])continue;
        id isSubRun = [anItem objectForKey:@"SubRun"];
        if(!isSubRun)isSubRun = [NSNumber numberWithBool:NO];
		s = [s stringByAppendingFormat:@"%@:%@:%@\n",
			 [anItem objectForKey:@"ScriptParameters"],
			 [anItem objectForKey:@"RunLength"],isSubRun];
	}
	[s writeToFile:aPath atomically:YES encoding:NSASCIIStringEncoding error:nil];
}

- (void) restoreFromFile:(NSString*)aPath
{
	[self setLastFile:aPath];
	NSStringEncoding* encoding = nil;
	NSString* s = [NSString stringWithContentsOfFile:[lastFile stringByExpandingTildeInPath] usedEncoding:encoding error:nil];
	[items release];
	items = [[NSMutableArray array] retain];
	NSArray* lines = [s componentsSeparatedByString:@"\n"];
	for(id aLine in lines){
		aLine = [aLine trimSpacesFromEnds];
		if(![aLine hasPrefix:@"#"]){
			NSArray* parts = [aLine componentsSeparatedByString:@":"];
			if([parts count] == 3){
                NSString* args = [[parts objectAtIndex:0] trimSpacesFromEnds];
                if([args isEqualToString:@"(null)"])args = @"";
				NSMutableDictionary* anItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										args,@"ScriptParameters",
										[NSNumber numberWithFloat:[[[parts objectAtIndex:1] trimSpacesFromEnds]floatValue]],@"RunLength",
										[NSNumber numberWithInt:[[[parts objectAtIndex:2] trimSpacesFromEnds]intValue]],@"SubRun",
										@"",@"RunState",
										nil];
				[items addObject:anItem];
			}
		}
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelReloadTable object:self];    
}

- (NSString*) runStateName
{
	switch(runListState){
		case kStartup:			return @"Startup";
		case kWaitForRunToStop:	return @"Run Wait";
		case kWaitForSubRun:	return @"Subrun Wait";
		case kReadyToStart:     return @"Ready";
		case kStartRun:			return @"StartRun";
		case kStartSubRun:		return @"StartSubRun";
		case kStartScript:		return @"Starting Script";
		case kWaitForScript:	return @"Script Wait";
		case kWaitForRunTime:	return [NSString stringWithFormat:@"%.0f",runLength];
		case kRunFinished:		return @"Done";
		case kCheckForRepeat:	return @"Repeat Check";
		case kFinishUp:			return @"Manual Quit";
		default:			    return @"-";
	}
}
- (float) totalExpectedTime
{
	return totalExpectedTime;
}

- (float) accumulatedTime
{
	return accumulatedTime;
}

@end


@implementation ORRunListModel (private)
- (void) calcTotalExpectedTime
{
	accumulatedTime   = 0;
	totalExpectedTime = 0;
	for(id anItem in items){ 
		totalExpectedTime += [[anItem objectForKey:@"RunLength"] floatValue];
	}
}
	
- (void) setUpWorkingOrder
{
	if(orderArray)[orderArray release];
	NSMutableArray* tempArray = [NSMutableArray array];
	int i=0;
	for(id anItem in items){ 
		[tempArray addObject:[NSNumber numberWithInt:i]];
		i++;
	}
	if(randomize){
		orderArray = [[NSMutableArray array] retain];
		do {
			int randomIndex = random_range(0,[tempArray count]-1);
			[orderArray addObject:[tempArray objectAtIndex:randomIndex]];
			[tempArray removeObjectAtIndex:randomIndex];
		} while([tempArray count]);
	}
	else orderArray = [[NSArray arrayWithArray:tempArray] retain];
}

- (id) objectAtWorkingIndex
{
	int index = [[orderArray objectAtIndex:workingItemIndex] intValue];
	return [items objectAtIndex:index];
}

- (void) checkStatus
{
	BOOL doSubRun;
	NSArray* runObjects;
	id scriptParameters;
	
	switch(runListState){
		case kStartup:
			[self resetItemStates];
			runObjects = [[self document] collectObjectsOfClass:[ORRunModel class]];
			runModel     = [[runObjects objectAtIndex:0] retain];
			scriptModel  = [[self objectConnectedTo:ORRunListDataOut] retain];
			[self saveRunModelOptions];
            if([runModel isRunning]){
                [runModel stopRun];
                runListState = kWaitForRunToStop;
                nextState = kReadyToStart;
            }
            else   runListState = kReadyToStart;
        break;
            
        case kWaitForRunToStop:
			[self setWorkingItemState];
            if(![runModel isRunning])runListState = nextState;
        break;
			
		case kWaitForSubRun:
			[self setWorkingItemState];
			if([runModel runningState] == eRunBetweenSubRuns) runListState = nextState;
		break;
			
            
        case kReadyToStart:
			if(!scriptModel) runListState = kStartRun;
			else			 runListState = kStartScript;
			[self calcTotalExpectedTime];
			[self setUpWorkingOrder];
			[self setWorkingItemIndex:0];
		break;
			
		case kStartRun:
			[self setWorkingItemState];
			runLength = [[[self objectAtWorkingIndex] objectForKey:@"RunLength"] floatValue];
			if(runLength>0)[runModel startRun];
			runListState = kWaitForRunTime;
		break;
			
		case kStartSubRun:
			[self setWorkingItemState];
			runLength = [[[self objectAtWorkingIndex] objectForKey:@"RunLength"] intValue];
			[runModel startNewSubRun];
			runListState = kWaitForRunTime;
			break;
			
		case kStartScript:
			[self setWorkingItemState];
			scriptParameters = [self getScriptParameters];
			[scriptModel setInputValue:scriptParameters];
			[scriptModel runScript];
			runListState = kWaitForScript;
		break;
			
		case kWaitForScript:
			[self setWorkingItemState];
			if(![[scriptModel scriptRunner] running]) {
				doSubRun = [[[self objectAtWorkingIndex] objectForKey:@"SubRun"] intValue];
				if(doSubRun && workingItemIndex!=0) runListState = kStartSubRun;
				else		 runListState = kStartRun;
			}
		break;
			
		case kWaitForRunTime:
			[self setWorkingItemState];
			runLength -= kTimeDelta;
			accumulatedTime += kTimeDelta;
			if(runLength <= 0)runListState = kRunFinished;
		break;
			
		case kRunFinished:
			[self setWorkingItemState];
			[self incWorkingIndex];
			if(workingItemIndex >= [items count]) runListState = kCheckForRepeat;
			else {
				doSubRun = [[[self objectAtWorkingIndex] objectForKey:@"SubRun"] intValue];
				if(doSubRun){
					[runModel prepareForNewSubRun];
					runListState = kWaitForSubRun;
					if(!scriptModel) nextState = kStartSubRun;
					else			 nextState = kStartScript;
				}
				else {
					[runModel stopRun];
					runListState = kWaitForRunToStop;
					if(!scriptModel) nextState = kStartRun;
					else nextState = kStartScript;
				}
			}
		break;
			
		case kCheckForRepeat:
			executionCount++;
			if(executionCount>=timesToRepeat){
				runListState = kFinishUp;
			}
			else {
				runListState = kStartup;
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:ORRunListRunStateChanged object:self];
		break;
			
		case kFinishUp:
			[self setWorkingItemState];
			[[scriptModel scriptRunner] stop];
			if([runModel isRunning])[runModel stopRun];
			[self restoreRunModelOptions];
			
			[runModel release];		runModel = nil;
			[scriptModel release];	scriptModel = nil;

			[timedWorker stop];
			[timedWorker release];
			timedWorker = nil;
			[orderArray release];
			orderArray = nil;
					
			[[NSNotificationCenter defaultCenter] postNotificationName:ORRunListRunStateChanged object:self];
		break;
	}
}

- (void) restoreRunModelOptions
{
	[runModel setTimedRun:oldTimedRun];
	[runModel setRepeatRun:oldRepeatRun];
	[runModel setTimeLimit:oldRepeatTime];
}

- (void) saveRunModelOptions
{
	oldTimedRun = [runModel timedRun];
	oldRepeatRun = [runModel repeatRun];
	oldRepeatTime = [runModel timeLimit];
	[runModel setTimedRun:NO];
	[runModel setRepeatRun:NO];
}

- (void) setWorkingItemIndex:(int)aWorkingItemIndex
{
	workingItemIndex = aWorkingItemIndex;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelWorkingItemIndexChanged object:self];
}
			   
- (void) incWorkingIndex
{
	[self setWorkingItemIndex:workingItemIndex+1];
}

- (id) getScriptParameters
{
	NSString* s = [[self objectAtWorkingIndex] objectForKey:@"ScriptParameters"];
	if([s length] == 0) return nil;
	else if([s rangeOfString:@","].location == NSNotFound)return [NSDecimalNumber decimalNumberWithString:s];
	else {
		NSArray* parts = [s componentsSeparatedByString:@","];
		NSMutableArray* numbers = [NSMutableArray array];
		for(id anItem in parts){
			[numbers addObject:[NSDecimalNumber decimalNumberWithString:anItem]];
		}
		return numbers;
	}
}

- (void) resetItemStates
{
	for(id anItem in items){
		[anItem setObject:@"-" forKey:@"RunState"];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelReloadTable object:self];
}


- (void) setWorkingItemState
{
	if(workingItemIndex < [items count]){
		id anItem = [self objectAtWorkingIndex];
		[anItem setObject:[self runStateName]  forKey:@"RunState"];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRunListModelReloadTable object:self];
}

@end