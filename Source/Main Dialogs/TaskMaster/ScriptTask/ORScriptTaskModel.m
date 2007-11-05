//-------------------------------------------------------------------------
//  ORSciptTaskModel.m
//
//  Created by Mark A. Howe on Tuesday 12/26/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import <Cocoa/Cocoa.h>
#import "ORScriptTaskModel.h"
#import "ORScriptRunner.h"
#import "ORScriptInterface.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

NSString* ORScriptTaskScriptChanged			= @"ORScriptTaskScriptChanged";
NSString* ORScriptTaskNameChanged			= @"ORScriptTaskNameChanged";
NSString* ORScriptTaskArgsChanged			= @"ORScriptTaskArgsChanged";
NSString* ORScriptTaskBreakChainChanged		= @"ORScriptTaskBreakChainChanged";
NSString* ORScriptTaskLastFileChangedChanged= @"ORScriptTaskLastFileChangedChanged";

NSString*  ORScriptTaskInConnector			= @"ORScriptTaskInConnector";
NSString*  ORScriptTaskOutConnector			= @"ORScriptTaskOutConnector";

@implementation ORScriptTaskModel

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    return self;
}

- (void) dealloc 
{
    [task release];
    task = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[scriptName release];
	[args release];
	[scriptRunner release];
    [super dealloc];
}

-(void)makeMainController
{
    [self linkToController:@"ORScriptTaskController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize-4,[self frame].size.height-kConnectorSize) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORScriptTaskInConnector];
	[aConnector setOffColor:[NSColor brownColor]];
	[aConnector setConnectorType: 'SCRI'];
	[aConnector addRestrictedConnectionType: 'SCRO']; //can only connect to Script Outputs
    [aConnector release];
 
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize-4,0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORScriptTaskOutConnector];
	[aConnector setOffColor:[NSColor brownColor]];
	[aConnector setConnectorType: 'SCRO'];
	[aConnector addRestrictedConnectionType: 'SCRI']; //can only connect to Script Inputs
    [aConnector release];
    
}


- (void) connectionChanged
{
	[self setUpImage];
}

- (void) setUpImage
{
    //[self setImage:[NSImage imageNamed:@"ScriptTask"]];

    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"ScriptTask"];
	    
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	if([self breakChain] && [self objectConnectedTo: ORScriptTaskOutConnector]){
		[[NSImage imageNamed:@"chainBroken"] compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
	}	
    if([self running]){
        [[NSImage imageNamed:@"ScriptRunning"] compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
    }

    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORForceRedraw
                      object: self];

}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
    
    [task wakeUp];
}
- (void) sleep
{
    [super sleep];    
    [task sleep];
}

- (void) installTasks:(NSNotification*)aNote
{
    if(!task){
        task = [[ORScriptInterface alloc] init];
    }
    [task setDelegate:self];
    [task wakeUp];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(runningChanged:)
                         name : ORScriptRunnerRunningChanged
						object: nil];	
}

- (void) runningChanged:(NSNotification*)aNote
{
	[self setUpImage];
}

#pragma mark ***Accessors

- (BOOL) breakChain
{
	return breakChain;
}

- (void) setBreakChain:(BOOL)aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setBreakChain:breakChain];
	breakChain = aState;
	[self setUpImage];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptTaskBreakChainChanged object:self];

}

- (NSString*) lastFile
{
	return lastFile;
}

- (void) setLastFile:(NSString*)aFile
{
	if(!aFile)aFile = [[NSHomeDirectory() stringByAppendingPathComponent:@"Untitled"] stringByExpandingTildeInPath];
	[[[self undoManager] prepareWithInvocationTarget:self] setLastFile:lastFile];
    [lastFile autorelease];
    lastFile = [aFile copy];		
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptTaskLastFileChangedChanged object:self];
}

- (id) inputValue
{
	return inputValue;
}

- (void) setInputValue:(id)aValue
{
	[aValue retain];
	[inputValue release];
	inputValue = aValue;
}

- (NSString*) script
{
	return script;
}

- (void) setScript:(NSString*)aString
{
	if(!aString)aString= @"";
    //[[[self undoManager] prepareWithInvocationTarget:self] setScript:script];
    [script autorelease];
    script = [aString copy];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptTaskScriptChanged object:self];
}

- (void) setScriptNoNote:(NSString*)aString
{
    [script autorelease];
    script = [aString copy];	
}

- (NSString*) scriptName
{
	return scriptName;
}

- (void) setScriptName:(NSString*)aString
{
	if(!aString)aString = @"OrcaScript";
    [[[self undoManager] prepareWithInvocationTarget:self] setScriptName:scriptName];
	[task setTitle:scriptName];
    [scriptName autorelease];
    scriptName = [aString copy];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptTaskNameChanged object:self];
}

- (id) arg:(int)index
{
	if(index>=0 && index<[args count])return [args objectAtIndex:index];
	else return nil;
}

- (void) setArg:(int)index withValue:(id)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setArg:index withValue:[self arg:index]];
	[args replaceObjectAtIndex:index withObject:aValue];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptTaskArgsChanged object:self];
}

#pragma mark ***Data ID
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId        = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORDecoderScriptTask",					@"decoder",
        [NSNumber numberWithLong:dataId],		@"dataId",
        [NSNumber numberWithBool:NO],           @"variable",
        [NSNumber numberWithLong:3],            @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"scriptTask"];
    
    return dataDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORScriptTaskModel"];
    
}

#pragma mark ***Script Methods
- (ORScriptRunner*) scriptRunner
{
	return scriptRunner;
}
- (BOOL) parsedOK
{
	return parsedOK;
}

- (void) parseScript
{
	parsedOK = YES;
	if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
	if(![scriptRunner running]){
		[scriptRunner setScriptName:scriptName];
		[scriptRunner parse:script];
		parsedOK = [scriptRunner parsedOK];
		if(([[NSApp currentEvent] modifierFlags] & 0x80000)>0){
			//option key is down
			[scriptRunner printAll];
		}
		[scriptRunner release];
		scriptRunner = nil;
	}
}

- (void) runScript
{
	parsedOK = YES;
	if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
	if(![scriptRunner running]){
		[scriptRunner setScriptName:scriptName];
		[scriptRunner setInputValue:inputValue];
		[scriptRunner parse:script];
		parsedOK = [scriptRunner parsedOK];
		if(parsedOK){
			[scriptRunner setFinishCallBack:self selector:@selector(scriptRunnerDidFinish:returnValue:)];
			[scriptRunner evaluateAll:args];
		}
	}
	else {
		[scriptRunner stop];
		[scriptRunner release];
		scriptRunner = nil;
		[task hardHaltTask];
	}
}


- (void) scriptRunnerDidFinish:(BOOL)normalFinish returnValue:(id)aValue
{
	[self setInputValue:nil];
	if(normalFinish && !breakChain){
		ORScriptTaskModel* nextScriptTask =  [self objectConnectedTo: ORScriptTaskOutConnector];
		[nextScriptTask setInputValue:aValue];
		[nextScriptTask runScript];
	}
	if(normalFinish)NSLog(@"[%@] Returned with: %@\n",[scriptRunner scriptName],aValue);
	else NSLogColor([NSColor redColor],@"[%@] Abnormal exit!\n",[scriptRunner scriptName]);

}

- (void) stopScript
{
	[scriptRunner stop];
	[scriptRunner release];
	scriptRunner = nil;
}

- (BOOL) running
{
	return [scriptRunner running];
}

- (void) loadScriptFromFile:(NSString*)aFilePath
{
	[self setLastFile:aFilePath];
	[self setScript:[NSString stringWithContentsOfFile:[lastFile stringByExpandingTildeInPath]]];
}

- (void) saveFile
{
	[self saveScriptToFile:lastFile];
}

- (void) saveScriptToFile:(NSString*)aFilePath
{
	NSFileManager* fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:[aFilePath stringByExpandingTildeInPath]]){
		[fm removeFileAtPath:[aFilePath stringByExpandingTildeInPath] handler:nil];
	}
	NSData* theData = [script dataUsingEncoding:NSASCIIStringEncoding];
	[fm createFileAtPath:[aFilePath stringByExpandingTildeInPath] contents:theData attributes:nil];
	[self setLastFile:aFilePath];
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	
    [self setBreakChain:[decoder decodeBoolForKey:@"breakChain"]];
    [self setScript:[decoder decodeObjectForKey:@"script"]];
    [self setScriptName:[decoder decodeObjectForKey:@"scriptName"]];
    [self setLastFile:[decoder decodeObjectForKey:@"lastFile"]];
    args = [[decoder decodeObjectForKey:@"args"] retain];

	if(!args){
		args = [[NSMutableArray array] retain];
		int i;
		for(i=0;i<kNumScriptArgs;i++){
			[args addObject:[NSDecimalNumber zero]];
		}
	}
	
    task = [[decoder decodeObjectForKey:@"task"] retain];
    [self installTasks:nil];
	[task setTitle:scriptName];
    [[self undoManager] enableUndoRegistration];
	[self registerNotificationObservers];
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:task forKey:@"task"];
    [encoder encodeObject:script forKey:@"script"];
    [encoder encodeObject:scriptName forKey:@"scriptName"];
    [encoder encodeObject:args forKey:@"args"];
    [encoder encodeObject:lastFile forKey:@"lastFile"];
    [encoder encodeBool:breakChain forKey:@"breakChain"];
}

- (void) shipTaskRecord:(id)aTask running:(BOOL)aState
{
    if(dataId!= -1){
		unsigned long data[3];
		data[0] = dataId | 3; 
		data[1] = [self uniqueIdNumber]; 
		data[2] = aState;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:&data length:sizeof(long)*3]];
    }
}

- (void) taskDidStart:(NSNotification*)aNote
{
	//this really means a task is about to start....
	id reportingTask = [aNote object];

	if(reportingTask != task){
		if([task taskState] == eTaskRunning || [task taskState] == eTaskWaiting){
			[task stopTask];
		}
	}


    [self shipTaskRecord:[aNote object] running:YES];
}

- (void) taskDidFinish:(NSNotification*)aNote
{
    [self shipTaskRecord:[aNote object] running:NO];
}

@end


@implementation ORDecoderScriptTask
- (unsigned long) decodeData:(void*)someData  fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long value = *((unsigned long*)someData);
    return ExtractLength(value);
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Script Task\n\n";
    NSString* state = [NSString stringWithFormat:    @"Task %d State = %@\n",ptr[1],ptr[2]?@"Started":@"Stopped"];
    return [NSString stringWithFormat:@"%@%@",title,state];               
}
@end

