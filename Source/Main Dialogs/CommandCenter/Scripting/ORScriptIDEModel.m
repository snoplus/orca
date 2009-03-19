//-------------------------------------------------------------------------
//  ORSciptTaskModel.m
//
//  Created by Mark A. Howe on Tuesday 12/26/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved
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
#import "ORScriptIDEModel.h"
#import "ORScriptRunner.h"
#import "ORLineMarker.h"
#import "ORNodeEvaluator.h"
#import "NSNotifications+Extensions.h"
#import "NSString+Extensions.h"

NSString* ORScriptIDEModelCommentsChanged		 = @"ORScriptIDEModelCommentsChanged";
NSString* ORScriptIDEModelShowSuperClassChanged	 = @"ORScriptIDEModelShowSuperClassChanged";
NSString* ORScriptIDEModelScriptChanged			 = @"ORScriptIDEModelScriptChanged";
NSString* ORScriptIDEModelNameChanged			 = @"ORScriptIDEModelNameChanged";
NSString* ORScriptIDEModelLastFileChangedChanged = @"ORScriptIDEModelLastFileChangedChanged";
NSString* ORScriptIDEModelLock					 = @"ORScriptIDEModelLock";
NSString* ORScriptIDEModelBreakpointsChanged	 = @"ORScriptIDEModelBreakpointsChanged";
NSString* ORScriptIDEModelBreakChainChanged		 = @"ORScriptIDEModelBreakChainChanged";

@implementation ORScriptIDEModel

#pragma mark ***Initialization
- (void) dealloc 
{
    [comments release];
	[scriptName release];
	[inputValues release];
	[scriptRunner release];
    [super dealloc];
}

- (void) makeMainController
{
    [self linkToController:@"ORScriptIDEController"];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelBreakChainChanged object:self];
	
}
- (NSDictionary*) breakpoints
{
	return breakpoints;
}

- (void) setBreakpoints:(NSDictionary*) someBreakpoints
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setBreakpoints:breakpoints];
	
	[someBreakpoints retain];
	[breakpoints release];
	breakpoints = someBreakpoints;
	
	if([scriptRunner debugging] && [scriptRunner running]){
		[scriptRunner setBreakpoints:[self breakpointSet]];
	}
	
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelBreakpointsChanged object:self];
}

- (NSMutableIndexSet*) breakpointSet
{
	NSMutableIndexSet* aBreakpointSet = [NSMutableIndexSet indexSet];
	if([breakpoints count]){
		NSEnumerator* e = [breakpoints objectEnumerator];
		ORLineMarker* aMarker;
		while (aMarker = [e nextObject]) {
			[aBreakpointSet addIndex: [aMarker lineNumber]];
		}	
	}
	return aBreakpointSet;
}
- (id) evaluator
{
	if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
	return [scriptRunner eval];
}

- (NSString*) comments
{
	if(!comments)return @"";
    return comments;
}

- (void) setComments:(NSString*)aComments
{
	if(!aComments)aComments = @"";
    //[[[self undoManager] prepareWithInvocationTarget:self] setComments:comments];
    
    [comments autorelease];
    comments = [aComments copy];    
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelCommentsChanged object:self];
}

- (void) setCommentsNoNote:(NSString*)aString
{
	if(!aString)aString= @"";
    [comments autorelease];
    comments = [aString copy];	
}

- (BOOL) showSuperClass
{
    return showSuperClass;
}

- (void) setShowSuperClass:(BOOL)aShowSuperClass
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowSuperClass:showSuperClass];
    
    showSuperClass = aShowSuperClass;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelShowSuperClassChanged object:self];
}

- (NSString*) lastFile
{
	if(!lastFile)return @"";
	else return lastFile;
}

- (void) setLastFile:(NSString*)aFile
{
	if(!aFile)aFile = [[NSHomeDirectory() stringByAppendingPathComponent:@"Untitled"] stringByExpandingTildeInPath];
	[[[self undoManager] prepareWithInvocationTarget:self] setLastFile:lastFile];
    [lastFile autorelease];
    lastFile = [aFile copy];		
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelLastFileChangedChanged object:self];
}

- (NSString*) script
{
	if(!script)return @"";
	return script;
}

- (void) setScript:(NSString*)aString
{
	if(!aString)aString= @"";
    //[[[self undoManager] prepareWithInvocationTarget:self] setScript:script];
    [script autorelease];
    script = [aString copy];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelScriptChanged object:self];
}

- (void) setScriptNoNote:(NSString*)aString
{
	if(!aString)aString= @"";
    [script autorelease];
    script = [aString copy];	
}

- (NSString*) scriptName
{
	if(!scriptName)return @"ORCAScript";
	return scriptName;
}

- (void) setScriptName:(NSString*)aString
{
	if(!aString)aString = @"OrcaScript";
    [[[self undoManager] prepareWithInvocationTarget:self] setScriptName:scriptName];
    [scriptName autorelease];
    scriptName = [aString copy];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORScriptIDEModelNameChanged object:self];
	[self setUpImage];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"%@ %d",[self scriptName],[self uniqueIdNumber]];
}

- (NSMutableArray*) inputValues
{
	return inputValues;
}

- (void) addInputValue
{
	if(!inputValues)inputValues = [[NSMutableArray array] retain];
	[inputValues addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
							[NSString stringWithFormat:@"$%d",[inputValues count]],	@"name",
							[NSDecimalNumber numberWithUnsignedLong:0],				@"iValue",
							nil]];
	
}

- (void) removeInputValue:(int)i
{
	[inputValues removeObjectAtIndex:i];
}



#pragma mark ***Script Methods
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

- (ORScriptRunner*) scriptRunner
{
	if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
	return scriptRunner;
}

- (BOOL) parsedOK
{
	return parsedOK;
}

- (BOOL) scriptExists
{
	return scriptExists;
}

- (void) parseScript
{
	parsedOK = YES;
	if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
	if(![scriptRunner running]){
		[scriptRunner setScriptName:scriptName];
		[scriptRunner parse:script];
		parsedOK = [scriptRunner parsedOK];
		scriptExists = [scriptRunner scriptExists];
		if(([[NSApp currentEvent] modifierFlags] & 0x80000)>0){
			//option key is down
			[scriptRunner printAll];
		}
	}
}

- (BOOL) runScript
{
	parsedOK = YES;
	if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
	if(![scriptRunner running]){
		[scriptRunner setScriptName:scriptName];
		[scriptRunner setInputValue:inputValue];
		[scriptRunner parse:script];
		parsedOK = [scriptRunner parsedOK];
		if(parsedOK){
			if([scriptRunner scriptExists]){
				[scriptRunner setFinishCallBack:self selector:@selector(scriptRunnerDidFinish:returnValue:)];
				if([scriptRunner debugging]){
					[scriptRunner setBreakpoints:[self breakpointSet]];
				}
				[scriptRunner setDebugMode:kRunToBreakPoint];
				[scriptRunner run:inputValues sender:self];
			}
			else {
				[self scriptRunnerDidFinish:YES returnValue:[NSNumber numberWithInt:1]];
			}
		}
	}
	else {
		[scriptRunner stop];
	}
	return parsedOK;
}

- (void) stopScript
{
	[scriptRunner stop];
	[scriptRunner release];
	scriptRunner = nil;
}

- (id) nextScriptConnector
{
	//default is nil. If subclasses use the breakchain variable and have a chain of scripts they can override
	return nil;
}

- (void) scriptRunnerDidFinish:(BOOL)normalFinish returnValue:(id)aValue
{	
	[self setInputValue:nil];
	if(normalFinish && !breakChain){
		if([self nextScriptConnector]){
			ORScriptIDEModel* nextScriptTask =  [self objectConnectedTo: [self nextScriptConnector]];
			[nextScriptTask setInputValue:aValue];
			[nextScriptTask runScript];
		}
	}
	
	if(normalFinish)NSLog(@"[%@] Returned with: %@\n",[self identifier],aValue);
	else NSLogColor([NSColor redColor],@"[%@] Abnormal exit!\n",[[self scriptRunner] scriptName]);
}

- (BOOL) running
{
	return [scriptRunner running];
}

- (void) loadScriptFromFile:(NSString*)aFilePath
{
	[self setLastFile:aFilePath];
	NSString* theContents = [NSString stringWithContentsOfFile:[lastFile stringByExpandingTildeInPath]];
	//if the name and description are prepended then strip off and restore
	//the name is always first if it exists
	if([theContents hasPrefix:@"//#Name:"]){
		unsigned eofLoc = [theContents rangeOfString:@"\n"].location;
		NSString* theName = [theContents substringToIndex:eofLoc];
		theContents = [theContents substringFromIndex:eofLoc+1];
		theName = [theName substringFromIndex:[theName rangeOfString:@":"].location+1];
		if(theName)[self setScriptName:theName];
	}
	else [self setScriptName:@"OrcaScript"];
	//the description comment is always second if it exists
	if([theContents hasPrefix:@"//#Comments:"]){
		unsigned eofLoc = [theContents rangeOfString:@"\n"].location;
		NSString* theComments = [theContents substringToIndex:eofLoc];
		theContents = [theContents substringFromIndex:eofLoc+1];
		theComments = [theComments substringFromIndex:[theComments rangeOfString:@":"].location+1];
		if(theComments)[self setComments:theComments];
		else [self setComments:@""];
	}
	else [self setComments:@""];
	[self setScript: theContents];
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
	//prepend the name and description
	NSMutableString* theScript = [script mutableCopy];
	if([[self comments] length]){
		[theScript insertString:[NSString stringWithFormat:@"//#Comments:%@\n",[[self comments]removeNLandCRs]] atIndex:0];
	}
	if([[self scriptName] length]){
		[theScript insertString:[NSString stringWithFormat:@"//#Name:%@\n",[[self scriptName] removeNLandCRs]] atIndex:0];
	}
	else {
		[theScript insertString:@"//#Name:OrcaScript\n" atIndex:0];
	}
	NSData* theData = [theScript dataUsingEncoding:NSASCIIStringEncoding];
	[theScript release];
	[fm createFileAtPath:[aFilePath stringByExpandingTildeInPath] contents:theData attributes:nil];
	[self setLastFile:aFilePath];
}

//functions for testing script objC calls
- (float) testNoArgFunc											{ return 1.1; }
- (float) testOneArgFunc:(float)aValue							{ return aValue; }
- (float) testTwoArgFunc:(float)aValue argTwo:(float)aValue2	{ return aValue + aValue2; }
- (NSString*) testFuncStringReturn								{ return @"PASSED";}
- (NSPoint) testFuncPointReturn:(NSPoint)aPoint					{ return aPoint; }
- (NSRect) testFuncRectReturn:(NSRect)aRect						{ return aRect; }

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	
	[self setBreakChain:[decoder decodeBoolForKey:@"breakChain"]];
	[self setComments:[decoder decodeObjectForKey:@"comments"]];
    [self setShowSuperClass:[decoder decodeBoolForKey:@"showSuperClass"]];
    [self setScript:[decoder decodeObjectForKey:@"script"]];
    [self setScriptName:[decoder decodeObjectForKey:@"scriptName"]];
    [self setLastFile:[decoder decodeObjectForKey:@"lastFile"]];
	[self setBreakpoints:[decoder decodeObjectForKey:@"breakpoints"]];
    inputValues = [[decoder decodeObjectForKey:@"inputValues"] retain];	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:breakChain forKey:@"breakChain"];
    [encoder encodeObject:comments forKey:@"comments"];
    [encoder encodeBool:showSuperClass forKey:@"showSuperClass"];
    [encoder encodeObject:script forKey:@"script"];
    [encoder encodeObject:scriptName forKey:@"scriptName"];
    [encoder encodeObject:inputValues forKey:@"inputValues"];
    [encoder encodeObject:lastFile forKey:@"lastFile"];
    [encoder encodeObject:breakpoints forKey:@"breakpoints"];
}
@end

