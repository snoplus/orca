//
//  ORScriptRunner.m
//  Orca
//
//  Created by Mark Howe  Dec 2006.
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

#import "ORDocument.h"
#import "ORScriptRunner.h"
#import "NodeTree.h"
#import "ORNodeEvaluator.h"
#import "NSNotifications+Extensions.h"

NSString* ORScriptRunnerRunningChanged			= @"ORScriptRunnerRunningChanged";
NSString* ORScriptRunnerParseError				= @"ORScriptRunnerParseError";
NSString* ORScriptRunnerDebuggerStateChanged	= @"ORScriptRunnerDebuggerStateChanged";
NSString* ORScriptRunnerDebuggingChanged		= @"ORScriptRunnerDebuggingChanged";
NSString* ORScriptRunnerDisplayDictionaryChanged= @"ORScriptRunnerDisplayDictionaryChanged";

//========================================================================
#pragma mark ¥¥¥YACC interface
#import "OrcaScript.tab.h"
extern void yyreset_state();
extern void OrcaScriptrestart();
extern long num_lines;
extern id functionList;
extern int OrcaScriptparse();
ORScriptRunner* theScriptRunner = nil;
int OrcaScriptYYINPUT(char* theBuffer,int maxSize) 
{
	return [theScriptRunner yyinputToBuffer:theBuffer withSize:maxSize];
}
//========================================================================


@interface ORScriptRunner (private)
- (void) _evalMain:(id)someNodes;
- (void) reportResult:(id)aResult;
- (void) pauseScript;
@end

@implementation ORScriptRunner

#pragma mark ¥¥¥Initialization
-(id)init {
	self = [super init];
	if(self) {
		expressionAsData = nil;
	}  
	return self;  
}

-(void)dealloc 
{
	[eval setDelegate:nil];
	[eval release];
	[functionTable release];
	[expressionAsData release];
	[breakpoints release];
	[displayDictionary release];
	[super dealloc];
}

#pragma mark ¥¥¥Accessors
- (void) setBreakpoints:(NSMutableIndexSet*)aSet
{
	[aSet retain];
	[breakpoints release];
	breakpoints = aSet;
}

- (ORNodeEvaluator*) eval
{
	return [eval functionEvaluator] ;
}

- (BOOL)	exitNow
{
	return exitNow;
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
- (id) displayDictionary
{
	id dic =nil;
	@synchronized ([NSApp delegate]){
		dic =  [[displayDictionary copy] autorelease];
	}
	return dic;
}

- (NSString*) scriptName
{
	return scriptName;
}

- (void) setScriptName:(NSString*)aString
{
    [scriptName autorelease];
    scriptName = [aString copy];	
}


-(void)setString:(NSString* )theString 
{
	NSData* theData = [theString dataUsingEncoding:NSUTF8StringEncoding];
	[theData retain];
	[expressionAsData release];
	expressionAsData = theData;
	yaccInputPosition = 0;
}

- (NSMutableDictionary*) functionTable
{
	return functionTable;
}

- (void) setFunctionTable:(NSMutableDictionary*)aFunctionTable
{
	[aFunctionTable retain];
	[functionTable release];
	functionTable = aFunctionTable;
}

- (void) appendFunctionTable:(NSMutableDictionary*)aFunctionTable
{
	if(!functionTable)[self setFunctionTable:aFunctionTable];
	else {
		[functionTable addEntriesFromDictionary:aFunctionTable];
	}
}


- (BOOL) running
{
	return running;
}
- (int) debuggerState
{
	return debuggerState;
}

- (void) setDebuggerState:(int)aState
{
	debuggerState = aState;
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORScriptRunnerDebuggerStateChanged object:self];
}

- (void) togglePause
{
	scriptShouldPause = !scriptShouldPause;
}

- (void) singleStep
{
	step = YES;
}

- (long) lastLine
{
	return lastLine;
}

- (void) stop
{
	stopThread = YES;
	exitNow = YES;;
}

- (void) setFinishCallBack:(id)aTarget selector:(SEL)aSelector
{
	finishTarget	= aTarget;
	finishSelector  = aSelector;
}

 - (unsigned) symbolTableCount
{
	return [eval symbolTableCount];
}
- (id) symbolNameForIndex:(int)i
{
	return [eval symbolNameForIndex:i];
}

- (id) symbolValueForIndex:(int)i
{
	return [eval symbolValueForIndex:i];
}


#pragma mark ¥¥¥Parsers

- (void) parseFile:(NSString*)aPath
{
	NSString* contents = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
	[self parse:contents];
}

- (BOOL) parsedOK
{
	return parsedOK;
}

- (BOOL) scriptExists
{
	return scriptExists;
}

-(void) parse:(NSString* )theString 
{  
	// yacc has a number of global variables so it is NOT thread safe
	// Acquire the lock to ensure one parse processing at a time
	@synchronized([NSApp delegate]){
		if([theString length]){
			parsedOK = NO;
			scriptExists = YES;
		}
		else {
			//no script... 
			parsedOK = YES;
			scriptExists = NO;
		}
		theScriptRunner = nil;
		@try {
			
			//recursively gather the imported files into a linear list and parse one by one.
			NSDictionary* importedContents = [self gatherImportedStrings:theString rootFile:@"Main Script"];
			NSArray* keys = [importedContents allKeys];
			for(id aFileName in keys){
				NSString* importedScript = [importedContents objectForKey:aFileName];
				[self subParse:importedScript rootFile:aFileName];
				[self appendFunctionTable:functionList];
				[functionList release];
				functionList = nil;
			}
			
			if(parsedOK){
				[self subParse:theString rootFile:@"Main Script"];
				[self appendFunctionTable:functionList];
				[functionList release];
				functionList = nil;
			}
			
			
			[eval release];
			eval = [[ORNodeEvaluator alloc] initWithFunctionTable:functionTable functionName:@"main"];
					
			if(inputValue){
				[eval setSymbolTable:[eval makeSymbolTableFor:@"main" args:[NSArray arrayWithObject:inputValue]]];
			}
			
		}
		@catch(NSException* e){
			parsedOK = NO;
			NSLog(@"%@\n",e);
			NSLog(@"line %d: %@\n",num_lines+1,[[theString componentsSeparatedByString:@"\n"] objectAtIndex:num_lines]);
			[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptRunnerParseError 
																object:self 
															  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithLong:num_lines+1] forKey:@"ErrorLocation"]];
			[functionList release];
			functionList = nil;
		}
	}
}

- (void) subParse:(NSString*)theString rootFile:(NSString*)rootFile
{
	@try { 
		yyreset_state();
		OrcaScriptrestart(NULL);
		
		theScriptRunner = self;
		
		[self setString:theString];
		
		//parse the main file
		NSArray* lines = [theString componentsSeparatedByString:@"\n" ];
		OrcaScriptparse();
		if(functionList) {
			if([rootFile isEqualToString:@"Main Script"])NSLog(@"%@: %d Lines Parsed Successfully\n",rootFile,num_lines);
			parsedOK = YES;
		}
		else  {
			parsedOK = NO;
			NSLog(@"%@: line %d: %@\n",rootFile,num_lines+1,[lines objectAtIndex:num_lines]);
			[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptRunnerParseError 
																object:self 
															  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithLong:num_lines+1] forKey:@"ErrorLocation"]];
		}
	}

	@catch(NSException* e) { 
		parsedOK = NO;
		int lineCount = num_lines;
		if([e userInfo]){
			NSLog(@"Caught Exception %@: %@\n",[e name],[e reason]);
			lineCount = [[[e userInfo] objectForKey:@"LineNum"] intValue];
		}
		else {
			NSLog(@"line %d: %@\n",num_lines+1,[[theString componentsSeparatedByString:@"\n"] objectAtIndex:num_lines]);
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptRunnerParseError 
															object:self 
														  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithLong:lineCount+1] forKey:@"ErrorLocation"]];
		[functionList release];
		functionList = nil;
	}

}

- (NSMutableDictionary*) gatherImportedStrings:(NSString*)scriptString rootFile:(NSString*)rootFile
{
	NSMutableDictionary* importedStrings = [NSMutableDictionary dictionary];
	int lineNum =0;
	NSArray* lines = [scriptString componentsSeparatedByString:@"\n" ];
	for(id aLine in lines){
		lineNum++;
		NSString* trimmedLine = [aLine trimSpacesFromEnds];
		if([trimmedLine hasPrefix:@"#"]){
			NSArray* files = [[trimmedLine stringByReplacingOccurrencesOfString:@"#" withString:@""] componentsSeparatedByString:@"import"];
			for(id aFile in files){
				NSString* theFileName = [aFile trimSpacesFromEnds];
				if([theFileName length]>=3){
					theFileName = [theFileName substringFromIndex:1];
					theFileName = [theFileName substringToIndex:[theFileName length]-1];
					NSFileManager* fm = [NSFileManager defaultManager];
					if([fm fileExistsAtPath:[theFileName stringByExpandingTildeInPath]]){
						NSString* contents = [NSString stringWithContentsOfFile:[theFileName stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
						if([contents length]){
							[importedStrings setObject:contents forKey:[theFileName stringByExpandingTildeInPath]];
						}
						NSMutableDictionary* more = [self gatherImportedStrings:contents rootFile:[theFileName stringByExpandingTildeInPath]];
						if([more count]){
							[importedStrings addEntriesFromDictionary:more];
						}
					}
					else {
						NSException* e = [NSException exceptionWithName:@"File Not Found" 
																 reason:[NSString stringWithFormat:@"%@ imported by %@ line: %d Not Found",theFileName,rootFile,lineNum] 
															   userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:lineNum] forKey:@"LineNum"]];
						[e raise];
					}
				}
			}
		}
	}
	return importedStrings;
	
}
#pragma mark ¥¥¥Group Evaluators
- (void) stopThread
{
	stopThread = YES;
}

- (void) setArgs:(NSArray*)someArgs
{
	[eval setArgs:someArgs];
}

- (void) evaluateAll:(id)someArgs sender:(id)aSender;
{
	if(!running){
				
		exitNow	   = NO;
		stopThread = NO;
		[eval setArgs:someArgs];
		NSArray* mainNodes = [functionTable objectForKey:@"main"];
		if(mainNodes){
			[eval setDelegate:self];
			//[NSThread detachNewThreadSelector:@selector(_evalMain:) toTarget:self withObject:mainNodes];
			scriptThread = [[NSThread alloc] initWithTarget:self selector:@selector(_evalMain:) object:mainNodes];
			[scriptThread setStackSize:4*1024*1024];
			[scriptThread start];
		}
		else NSLog(@"%@ has NO main function\n",scriptName);
	}
}

- (void) printAll
{
	NSLog(@"==================================\n");
	NSLog(@"Syntax Trees for [%@]\n",scriptName);
	id aKey;
	NSEnumerator* e = [functionTable keyEnumerator];
	while(aKey = [e nextObject]){
		id someNodes = [functionTable objectForKey:aKey];
		if(someNodes && ![aKey hasSuffix:@"_ArgNode"]){
			NSLog(@"Function: %@\n",aKey);
			[eval printAll:someNodes];
		}
	}
	NSLog(@"==================================\n");
}

- (id) display:(id)aValue forKey:(id)aKey
{
	@synchronized ([NSApp delegate]){
		if(!displayDictionary){
			displayDictionary = [[NSMutableDictionary alloc] init];
		}
		[displayDictionary setObject:aValue	forKey:aKey];
	}
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORScriptRunnerDisplayDictionaryChanged object:self userInfo:nil waitUntilDone:YES];
	return nil;
}


#pragma mark ¥¥¥Yacc Input
-(int)yyinputToBuffer:(char* )theBuffer withSize:(int)maxSize 
{
	int theNumberOfBytesRemaining = ([expressionAsData length] - yaccInputPosition);
	int theCopySize = maxSize < theNumberOfBytesRemaining ? maxSize : theNumberOfBytesRemaining;
	[expressionAsData getBytes:theBuffer range:NSMakeRange(yaccInputPosition,theCopySize)];  
	yaccInputPosition = yaccInputPosition + theCopySize;
	return theCopySize;
}

- (BOOL) debugging
{
	return debugging;
}

- (void) setDebugging:(BOOL)aState
{
	debugging = aState;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptRunnerDebuggingChanged 
														object:self];
}
//called from the NodeEvaluator from the eval thread
- (void) checkBreakpoint:(unsigned long) lineNumber functionLevel:(int)functionLevel
{
	if([self debugging]){
		if((lineNumber>0) && (lineNumber != lastLine)){
			lastLine = lineNumber;
			if((debugMode == kPauseHere) || [breakpoints containsIndex:lineNumber]){
				lastFunctionLevel = functionLevel;
				[self pauseScript];
			}
			else if(debugMode == kStepInto) {
				lastFunctionLevel = functionLevel;
				[self pauseScript];
			}
			else if((debugMode == kSingleStep) && (functionLevel<=lastFunctionLevel)){
				[self pauseScript];
			}
			else if((debugMode == kStepOutof)  && (functionLevel<lastFunctionLevel)){
				lastFunctionLevel = functionLevel;
				[self pauseScript];
			}
		}	
	}
}

- (void) setDebugMode:(int) aMode
{
	debugMode = aMode;
}

- (int) debugMode
{
	return debugMode;
}

- (void) run:(id)someArgs sender:(id)aSender
{
	if(!running){
		@synchronized ([NSApp delegate]){
			[displayDictionary release];
			displayDictionary = nil;
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORScriptRunnerDisplayDictionaryChanged object:self userInfo:nil waitUntilDone:NO];
		}
		[self evaluateAll:someArgs sender:aSender];
	}
}

- (void) runScriptAsString:(NSString*)aScript
{
	if(!running){
		[self parse:aScript];
		[self run:nil sender:nil];
	}
}

@end

@implementation ORScriptRunner (private)
- (void) _evalMain:(id)someNodes
{
	running = YES;
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORScriptRunnerRunningChanged object:self userInfo:nil waitUntilDone:YES];

	if([scriptName length])NSLog(@"Started %@\n",scriptName);
	else NSLog(@"Started OrcaScript\n");
	[someNodes retain];
	
	unsigned i;
	unsigned numNodes = [someNodes count];
	BOOL failed		= NO;
	BOOL reported	= NO;
	for(i=0;i<numNodes;i++){
		NSAutoreleasePool* innerPool = [[NSAutoreleasePool alloc] init];			
		@try {
			id aNode = [someNodes objectAtIndex:i];
			[eval execute:aNode container:nil];
		}
		@catch(NSException* localException) {
			if([[localException name] isEqualToString:@"return"]){
				NSDictionary* userInfo = [localException userInfo];
				if(userInfo){
					[self reportResult:[userInfo objectForKey:@"returnValue"]];
					reported = YES;
					[innerPool release];
					break;
				}
			}
			else if([[localException name] isEqualToString:@"exit"]){
				[self reportResult:[NSDecimalNumber numberWithInt:0]];
				reported = YES;
				[innerPool release];
				break;
			}
			else {
				NSLogColor([NSColor redColor],@"Script will exit because of exception: %@\n",localException);
				failed = YES;
			}
		}
		[innerPool release];
		if(stopThread || failed){
			if(stopThread){
				NSLogColor([NSColor redColor],@"Script stopped\n");
			}
			[self reportResult:[NSDecimalNumber numberWithInt:0]];
			break;
		}
	}	
	if(failed){
		NSLogColor([NSColor redColor],@"Run Time Error....Abnormal Exit\n");
	}
	
	if(!reported){
		[self reportResult:[NSDecimalNumber numberWithInt:1]];
	}
	
	[someNodes release];
	if([scriptName length])NSLog(@"%@ Exited\n",scriptName);
	else NSLog(@"OrcaScript Exited\n");
	running = NO;
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORScriptRunnerRunningChanged object:self userInfo:nil waitUntilDone:YES];
	[pool release];
	[scriptThread release];
	scriptThread = nil;
}


- (void) reportResult:(id)aResult
{
	if(finishTarget){
		NSInvocation* callBack = [NSInvocation invocationWithMethodSignature:[finishTarget methodSignatureForSelector:finishSelector]];
		[callBack setSelector:finishSelector];
		
		BOOL normalFinish = aResult!=nil;
		[callBack setArgument:&normalFinish atIndex:2];
		[callBack setArgument:&aResult atIndex:3];
		
		[callBack setTarget:finishTarget];
		[callBack performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
		[eval release];
		eval = nil;
	}
}

- (void) pauseScript
{	
	[self setDebuggerState:kDebuggerPaused];
	debugMode = kPauseHere;
	do {
		[NSThread sleepForTimeInterval:.1];
		if(!debugging)break;
		if(debugMode!=kPauseHere)break;
	} while(!exitNow);

	[self setDebuggerState:kDebuggerRunning];
}

@end

