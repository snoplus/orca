//-------------------------------------------------------------------------
//  ORScriptIDEModel.m
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
#import "OrcaObject.h"

@class ORScriptRunner;

@interface ORScriptIDEModel : OrcaObject
{
	NSString*				script;
	ORScriptRunner*			scriptRunner;
	NSString*				scriptName;
	BOOL					parsedOK;
	BOOL					scriptExists;
	NSString*				lastFile;
    BOOL					showSuperClass;
	id						inputValue;
	NSMutableArray*			inputValues;
    NSString*				comments;
	BOOL					debugging;
	NSDictionary*			breakpoints;
	BOOL					breakChain;
}

#pragma mark ***Initialization
- (void) dealloc;

#pragma mark ***Accessors
- (BOOL)	breakChain;
- (void)	setBreakChain:(BOOL)aState;
- (id)		inputValue;
- (void)	setInputValue:(id)aValue;
- (NSDictionary*)		breakpoints;
- (NSMutableIndexSet*)	breakpointSet;
- (void)		setBreakpoints:(NSDictionary*) someBreakpoints;
- (NSString*)	comments;
- (void)		setComments:(NSString*)aComments;
- (BOOL)		showSuperClass;
- (void)		setShowSuperClass:(BOOL)aShowSuperClass;
- (NSString*)	lastFile;
- (void)		setLastFile:(NSString*)aFile;
- (NSString*)	script;
- (void)		setScript:(NSString*)aString;
- (void)		setScriptNoNote:(NSString*)aString;
- (NSString*)	scriptName;
- (void)		setScriptName:(NSString*)aString;
- (BOOL)		parsedOK;
- (BOOL)		scriptExists;
- (ORScriptRunner*)	scriptRunner;
- (NSMutableArray*) inputValues;
- (void)		addInputValue;
- (void)		removeInputValue:(int)i;
- (NSString*)	identifier;

#pragma mark ***Script Methods
- (id) nextScriptConnector;
- (void) scriptRunnerDidFinish:(BOOL)normalFinish returnValue:(id)aValue;
- (void) parseScript;
- (void) runScript;
- (BOOL) running;
- (void) stopScript;
- (void) saveFile;
- (void) loadScriptFromFile:(NSString*)aFilePath;
- (void) saveScriptToFile:(NSString*)aFilePath;
- (id) evaluator;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORScriptIDEModelCommentsChanged;
extern NSString* ORScriptIDEModelLock;
extern NSString* ORScriptIDEModelShowSuperClassChanged;
extern NSString* ORScriptIDEModelScriptChanged;
extern NSString* ORScriptIDEModelNameChanged;
extern NSString* ORScriptIDEModelLastFileChangedChanged;
extern NSString* ORScriptIDEModelBreakpointsChanged;
extern NSString* ORScriptIDEModelBreakChainChanged;

