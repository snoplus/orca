//-------------------------------------------------------------------------
//  ORRunScriptModel.m
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
#import "ORBaseDecoder.h"

@class ORScriptRunner;
@class ORDataPacket;
@class ORDataSet;
@class ORLineNumberingTextStorage;

#define kRunStartScript 0
#define kRunStopScript  1

@interface ORRunScriptModel : OrcaObject
{
	NSString*				script;
	ORScriptRunner*			scriptRunner;
	NSString*				scriptName;
	BOOL					parsedOK;
	BOOL					scriptExists;
	NSString*				lastFile;
	unsigned long		    dataId;
    BOOL					showSuperClass;
	NSMutableArray*			inputValues;
    NSString*				comments;
	SEL						selectorOK;
	SEL						selectorBAD;
	id						anArg;
	id						target;
}


#pragma mark ***Initialization
- (id) init;
- (void) dealloc;

#pragma mark ***Accessors
- (void) setSelectorOK:(SEL)aSelectorOK bad:(SEL)aSelectorBAD withObject:(id)anObject target:(id)aTarget;
- (NSString*) comments;
- (void)	setComments:(NSString*)aComments;
- (BOOL)	showSuperClass;
- (void)	setShowSuperClass:(BOOL)aShowSuperClass;
- (NSString*) lastFile;
- (void) setLastFile:(NSString*)aFile;
- (NSString*) script;
- (void) setScript:(NSString*)aString;
- (void) setScriptNoNote:(NSString*)aString;
- (NSString*) scriptName;
- (void) setScriptName:(NSString*)aString;
- (BOOL) parsedOK;
- (BOOL) scriptExists;
- (ORScriptRunner*) scriptRunner;
- (NSMutableArray*) inputValues;
- (void) addInputValue;
- (void) removeInputValue:(int)i;
- (NSString*) identifier;

#pragma mark ***Data ID
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;
- (NSDictionary*) dataRecordDescription;
- (void) shipTaskRecord:(id)aTask running:(BOOL)aState;

#pragma mark ***Script Methods
- (void) scriptRunnerDidFinish:(BOOL)normalFinish returnValue:(id)aValue;
- (void) parseScript;
- (void) runScript;
- (BOOL) running;
- (void) stopScript;
- (void) saveFile;
- (void) loadScriptFromFile:(NSString*)aFilePath;
- (void) saveScriptToFile:(NSString*)aFilePath;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORRunScriptModelCommentsChanged;
extern NSString* ORRunScriptLock;
extern NSString* ORRunScriptModelShowSuperClassChanged;
extern NSString* ORRunScriptScriptChanged;
extern NSString* ORRunScriptNameChanged;
extern NSString* ORRunScriptArgsChanged;
extern NSString* ORRunScriptLastFileChangedChanged;


@interface ORDecoderRunScript : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData  fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

