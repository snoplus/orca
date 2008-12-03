//
//  ORScriptRunner.h
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

@class ORNodeEvaluator;

@interface ORScriptRunner : NSObject {
	@private
		id					 finishTarget;
		SEL					 finishSelector;
		unsigned			 yaccInputPosition;
		BOOL				 stopThread;
		BOOL				 running;
		BOOL				 parsedOK;
		BOOL				 normalExit;
		id					 returnValue;
		NSData*				 expressionAsData;
		NSString*			 scriptName;
		
		NSMutableDictionary* functionTable;
		ORNodeEvaluator*	eval;
		id					inputValue;
		BOOL				exitNow;
		BOOL				scriptExists;

} 

#pragma mark ¥¥¥Accessors
- (BOOL)	exitNow;
- (id)		inputValue;
- (void)	setInputValue:(id)aValue;
- (void)	 setString:(NSString* )theString;
- (NSMutableDictionary*) functionTable;
- (void)	 setFunctionTable:(NSMutableDictionary*)aFunctionTable;
- (NSString*) scriptName;
- (void)	 setScriptName:(NSString*)aString;
- (BOOL)	 parsedOK;
- (BOOL)	 scriptExists;
- (void)	 setArgs:(NSArray*)args;

#pragma mark ¥¥¥Run Methods
- (BOOL) running;
- (void) run:(id) someArgs  sender:(id)aSender;
- (void) stop;
- (void) setFinishCallBack:(id)aTarget selector:(SEL)aSelector;

#pragma mark ¥¥¥Parsers
- (id)		 parseFile:(NSString*) aPath;
- (id)		 parse:(NSString*) theString;

#pragma mark ¥¥¥Group Evaluators
- (void)	evaluateAll:(id) args sender:(id)aSender;
- (void)	printAll;

#pragma mark ¥¥¥Yacc Input
- (int)		 yyinputToBuffer:(char* )theBuffer withSize:(int)maxSize;

@end

extern NSString* ORScriptRunnerRunningChanged;
extern NSString* ORScriptRunnerParseError;