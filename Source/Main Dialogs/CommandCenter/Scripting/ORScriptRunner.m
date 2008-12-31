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

NSString* ORScriptRunnerRunningChanged = @"ORScriptRunnerRunningChanged";
NSString* ORScriptRunnerParseError	   = @"ORScriptRunnerParseError";
NSString* ORScriptRunnerDebuggerStateChanged	   = @"ORScriptRunnerDebuggerStateChanged";

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
- (void)    _evalMain:(id)someNodes;
- (void)	reportResult:(id)aResult;
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
	[eval release];
	[functionTable release];
	[expressionAsData release];
	[super dealloc];
}

#pragma mark ¥¥¥Accessors
- (ORNodeEvaluator*) eval
{
	return eval;
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

- (BOOL) running
{
	return running;
}

- (BOOL) debugging
{
	return debugging;
}

- (void) setDebugging:(BOOL)aState
{
	debugging = aState;
	if(running)[eval setDebugging:aState];
}

- (void) run:(id)someArgs sender:(id)aSender
{
	if(!running){
		[self evaluateAll:someArgs sender:aSender];
	}
}

- (void) pauseRunning
{
	if(debugging)[eval pauseRunning];
}

- (void) singleStep
{
	if(debugging)[eval singleStep];
}

- (void) continueRunning
{
	if(debugging)[eval continueRunning];
}

- (int) debuggerState
{
	if(debugging)return [eval debuggerState];
	else return 0;
}

- (long) lastLine
{
	if(debugging)return [eval lastLine];
	else return 0;
}

- (void) stop
{
	stopThread = YES;
	exitNow = YES;;
	if(debugging)[eval setDebugging:NO];
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

//- (id) minSymbolTable
//{
//	return [eval minSymbolTable];
//}

#pragma mark ¥¥¥Parsers

- (id) parseFile:(NSString*)aPath
{
	NSString* contents = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath]];
	return [self parse:contents];
}

- (BOOL) parsedOK
{
	return parsedOK;
}

- (BOOL) scriptExists
{
	return scriptExists;
}

-(id) parse:(NSString* )theString 
{  
	// yacc has a number of global variables so it is NOT thread safe
	// Acquire the lock to ensure one parse processing at a time
	@synchronized([NSApp delegate]){
		if([theString length]){
			parsedOK = NO;
			scriptExists = YES;
			
			@try { 
				
				yyreset_state();
				OrcaScriptrestart(NULL);
				
				theScriptRunner = self;
				[self setString:theString];
				
				// Call the parser    
				OrcaScriptparse();
				if(functionList) {
					NSLog(@"%d Lines Parsed Successfully\n",num_lines);
					parsedOK = YES;
				}
				else  {
					NSLog(@"line %d: %@\n",num_lines+1,[[theString componentsSeparatedByString:@"\n"] objectAtIndex:num_lines]);
					[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptRunnerParseError 
																		object:self 
																	  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithLong:num_lines+1] forKey:@"ErrorLocation"]];
				}
			}
			
			@catch(NSException* localException) { 
				NSLog(@"line %d: %@\n",num_lines+1,[[theString componentsSeparatedByString:@"\n"] objectAtIndex:num_lines]);
				[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptRunnerParseError 
																	object:self 
																  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithLong:num_lines+1] forKey:@"ErrorLocation"]];
				NSLog(@"Caught %@: %@\n",[localException name],[localException reason]);
				[functionList release];
				functionList = nil;
				
			}
		}
		else {
			//no script... 
			parsedOK = YES;
			scriptExists = NO;
		}
		theScriptRunner = nil;
		[self setFunctionTable:functionList];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self name:ORNodeEvaluatorDebuggerStateChanged object:eval];
		
		[eval release];
		eval = [[ORNodeEvaluator alloc] initWithFunctionTable:functionTable];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(evalDebuggerStateChanged:) name:ORNodeEvaluatorDebuggerStateChanged object:eval];
		
		if(inputValue){
			[eval setSymbolTable:[eval makeSymbolTableFor:@"main" args:[NSArray arrayWithObject:inputValue]]];
		}
		[functionList release];
		functionList = nil;
	}
	return [self functionTable];
}

- (void) evalDebuggerStateChanged:(NSNotificationCenter*)aNote
{
	//just pass it on
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptRunnerDebuggerStateChanged object:self];
	
}

#pragma mark ¥¥¥Group Evaluators
- (void) stopThread
{
	[eval setDebugging:NO];
	stopThread = YES;
}

- (void) setArgs:(NSArray*)someArgs
{
	[eval setArgs:someArgs];
}

- (void) evaluateAll:(id)someArgs sender:(id)aSender;
{
	if(!running){
		
		[eval setDebugging:debugging];
		
		exitNow	   = NO;
		stopThread = NO;
		[eval setScriptName:scriptName];
		[eval setArgs:someArgs];
		NSArray* mainNodes = [functionTable objectForKey:@"main"];
		if(mainNodes){
			[eval setDelegate:self];
			[NSThread detachNewThreadSelector:@selector(_evalMain:) toTarget:self withObject:mainNodes];
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

#pragma mark ¥¥¥Yacc Input
-(int)yyinputToBuffer:(char* )theBuffer withSize:(int)maxSize 
{
	int theNumberOfBytesRemaining = ([expressionAsData length] - yaccInputPosition);
	int theCopySize = maxSize < theNumberOfBytesRemaining ? maxSize : theNumberOfBytesRemaining;
	[expressionAsData getBytes:theBuffer range:NSMakeRange(yaccInputPosition,theCopySize)];  
	yaccInputPosition = yaccInputPosition + theCopySize;
	return theCopySize;
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
				NSLogColor([NSColor redColor],@"Script manually stopped\n");
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
}


- (void) reportResult:(id)aResult
{
	if(finishTarget){
		NSInvocation* callBack = [NSInvocation invocationWithMethodSignature:[finishTarget methodSignatureForSelector:finishSelector]];
		[callBack setSelector:finishSelector];
		
		//selector =  script:didFinish:returnValue:
		BOOL normalFinish = aResult!=nil;
		[callBack setArgument:&normalFinish atIndex:2];
		[callBack setArgument:&aResult atIndex:3];
		
		[callBack setTarget:finishTarget];
		[callBack performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
	}
}

@end

