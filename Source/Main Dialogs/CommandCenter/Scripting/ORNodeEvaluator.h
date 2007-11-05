//
//  ORNodeEvaluator.h
//  Orca
//
//  Created by Mark Howe on 12/29/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
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


@interface ORNodeEvaluator : NSObject {
	NSMutableDictionary* symbolTable;
	NSMutableDictionary* argValueDicionary;
	NSArray*			 parsedNodes;
	NSArray*			 args;
	NSDecimalNumber*	 _one;
	NSDecimalNumber*	 _zero;
	NSString*			 scriptName;
	NSDictionary*		 functionTable;
	unsigned short       switchLevel;
	id					 switchValue[256];
	id					 delegate;
	BOOL				 stop;
	NSFileHandle*		 logFileHandle;
}

#pragma mark •••Initialization
- (id)		initWithFunctionTable:(id)aFunctionTable;
- (void)	dealloc; 
- (NSUndoManager*) undoManager;

#pragma mark •••Accessors
- (void) setDelegate:(id)aDelegate;
- (NSString*) scriptName;
- (void) setScriptName:(NSString*)aString;
- (BOOL)	exitNow;

#pragma mark •••Symbol Table Routines
- (NSDictionary*) makeSymbolTableFor:(NSString*)functionName args:(id)argObject;
- (void) setSymbolTable:(NSDictionary*)aSymbolTable;
- (void) setArgs:(NSArray*)someArgs;
- (id) valueForSymbol:(NSString*) aSymbol;
- (id) setValue:(id)aValue forSymbol:(id) aSymbol;

#pragma mark •••Finders
- (id) findObject:(id) p;
- (id) findCard:(id)p collection:objects;
- (id) findVmeDaughterCard:(id)p collection:objects;

#pragma mark •••Individual Evaluators
- (id)		execute:(id) p container:(id)aContainer;
- (id)		printNode:(id) p;
- (void)	printAll:(NSArray*)someNodes;

@end
@interface OrcaObject (ORNodeEvaluation)
- (NSComparisonResult)compare:(NSNumber *)otherNumber;
- (BOOL)	exitNow;
@end