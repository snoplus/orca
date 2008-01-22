//
//  ORFilterModel.m
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
#import "ORFilterModel.h"
#import "ORDataPacket.h"
#import "ORScriptRunner.h"

static NSString* ORFilterInConnector 		= @"Filter In Connector";
static NSString* ORFilterOutConnector 		= @"Filter Out Connector";
NSString* ORFilterLastFileChanged			= @"ORFilterLastFileChanged";
NSString* ORFilterNameChanged				= @"ORFilterNameChanged";
NSString* ORFilterArgsChanged				= @"ORFilterArgsChanged";
NSString* ORFilterBreakChainChanged			= @"ORFilterBreakChainChanged";
NSString* ORFilterLastFileChangedChanged	= @"ORFilterLastFileChangedChanged";
NSString* ORFilterScriptChanged				= @"ORFilterScriptChanged";

NSString* ORFilterLock                      = @"ORFilterLock";

@implementation ORFilterModel

#pragma mark •••Initialization

- (id) init //designated initializer
{
	self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [[self undoManager] enableUndoRegistration];
        
	return self;
}

-(void)dealloc
{
    [super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"Filter"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORFilterController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORFilterInConnector];
    [aConnector release];

    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width-kConnectorSize,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORFilterOutConnector];
    [aConnector release];
    
}

#pragma mark •••Accessors
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
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterLastFileChangedChanged object:self];
}

#pragma mark •••Data Handling
- (void) processData:(ORDataPacket*)someData userInfo:(NSDictionary*)userInfo
{
	//pass it on
	id theNextObject = [self objectConnectedTo:ORFilterOutConnector];
	[theNextObject processData:someData userInfo:userInfo];
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{		
	dataHeader = [[aDataPacket headerAsData] retain];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}

- (void) closeOutRun:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[dataHeader release];
	dataHeader = nil;
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
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterScriptChanged object:self];
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
    [scriptName autorelease];
    scriptName = [aString copy];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterNameChanged object:self];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:ORFilterArgsChanged object:self];
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
	}
}


- (void) scriptRunnerDidFinish:(BOOL)normalFinish returnValue:(id)aValue
{
	[self setInputValue:nil];
	if(normalFinish){
		ORFilterModel* nextFilter =  [self objectConnectedTo: ORFilterOutConnector];
		[nextFilter setInputValue:aValue];
		[nextFilter runScript];
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

#pragma mark •••Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
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
	
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:script forKey:@"script"];
    [encoder encodeObject:scriptName forKey:@"scriptName"];
    [encoder encodeObject:args forKey:@"args"];
    [encoder encodeObject:lastFile forKey:@"lastFile"];
}


@end
