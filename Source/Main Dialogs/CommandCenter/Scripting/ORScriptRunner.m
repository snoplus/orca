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

NSString* ORScriptRunnerRunningChanged = @"ORScriptRunnerRunningChanged";
NSString* ORScriptRunnerParseError	   = @"ORScriptRunnerParseError";
//========================================================================
#pragma mark ¥¥¥YACC interface
#import "y.tab.h"
extern void yyreset_state();
extern void yyrestart();
extern long num_lines;
extern id functionList;
extern int yyparse();
ORScriptRunner* theScriptRunner = nil;
int yyYYINPUT(char* theBuffer,int maxSize) 
{
	return [theScriptRunner yyinputToBuffer:theBuffer withSize:maxSize];
}
//========================================================================


@interface ORScriptRunner (private)
- (void)    _evalMain:(id)someNodes;
- (void)	postRunningChanged;
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

- (void) run:(NSArray*)someArgs
{
	if(!running)[self evaluateAll:someArgs];
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

-(id) parse:(NSString* )theString 
{  
	// yacc has a number of global variables so it is NOT thread safe
	// Acquire the lock to ensure one parse processing at a time
	@synchronized([NSApp delegate]){
		parsedOK = NO;
		NS_DURING {
			
			yyreset_state();
			yyrestart(NULL);
			
			theScriptRunner = self;
			[self setString:theString];
			
			// Call the parser    
			yyparse();
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
		NS_HANDLER {
			NSLog(@"line %d: %@\n",num_lines+1,[[theString componentsSeparatedByString:@"\n"] objectAtIndex:num_lines]);
			[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptRunnerParseError 
																	object:self 
																  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithLong:num_lines+1] forKey:@"ErrorLocation"]];
			NSLog(@"Caught %@: %@\n",[localException name],[localException reason]);
			[functionList release];
			functionList = nil;
		}
		NS_ENDHANDLER
		
		theScriptRunner = nil;
		[self setFunctionTable:functionList];
		[eval release];
		eval = [[ORNodeEvaluator alloc] initWithFunctionTable:functionTable];
		if(inputValue){
			[eval setSymbolTable:[eval makeSymbolTableFor:@"main" args:inputValue]];
		}
		[functionList release];
		functionList = nil;
	}
	return [self functionTable];
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

- (void) evaluateAll:(NSArray*)someArgs;
{
	if(!running){
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
	[self performSelectorOnMainThread:@selector(postRunningChanged) withObject:nil waitUntilDone:YES];
	if([scriptName length])NSLog(@"Started %@\n",scriptName);
	else NSLog(@"Started OrcaScript\n");
	[someNodes retain];
	
	unsigned i;
	unsigned numNodes = [someNodes count];
	BOOL failed = NO;
	for(i=0;i<numNodes;i++){
		NSAutoreleasePool* innerPool = [[NSAutoreleasePool alloc] init];			
		NS_DURING
			id aNode = [someNodes objectAtIndex:i];
			[eval execute:aNode container:nil];
		NS_HANDLER
			if([[localException name] isEqualToString:@"return"]){
				NSDictionary* userInfo = [localException userInfo];
				if(userInfo){
					[self reportResult:[userInfo objectForKey:@"returnValue"]];
					[innerPool release];
					break;
				}
			}
			else if([[localException name] isEqualToString:@"exit"]){
				[self reportResult:[NSDecimalNumber numberWithInt:0]];
				[innerPool release];
				break;
			}
			else {
				NSLogColor([NSColor redColor],@"Script will exit because of exception: %@\n",localException);
				failed = YES;
			}
		NS_ENDHANDLER
		[innerPool release];
		if(stopThread || failed)break;
	}	
	if(failed){
		NSLogColor([NSColor redColor],@"Run Time Error....Abnormal Exit\n");
	}
	
	[someNodes release];
	if([scriptName length])NSLog(@"%@ Exited\n",scriptName);
	else NSLog(@"OrcaScript Exited\n");
	running = NO;
	[self performSelectorOnMainThread:@selector(postRunningChanged) withObject:nil waitUntilDone:YES];
	[pool release];
}

- (void) postRunningChanged
{	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptRunnerRunningChanged object:self];
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

