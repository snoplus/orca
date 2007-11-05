//-------------------------------------------------------------------------
//  ORScriptTaskModel.m
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

#define kNumScriptArgs 5

@class ORScriptRunner;
@class ORScriptInterface;
@class ORDataPacket;
@class ORDataSet;
@class ORLineNumberingTextStorage;

@interface ORScriptTaskModel : OrcaObject
{
	NSString*				script;
	ORScriptRunner*			scriptRunner;
	NSString*				scriptName;
	BOOL					parsedOK;
	NSMutableArray*			args;
	ORScriptInterface*		task;
	NSString*				lastFile;
	id						inputValue;
	BOOL					breakChain;
	unsigned long		    dataId;
}


#pragma mark ***Initialization
- (id) init;
- (void) dealloc;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) runningChanged:(NSNotification*)aNote;

#pragma mark ***Accessors
- (BOOL)	breakChain;
- (void)	setBreakChain:(BOOL)aState;
- (id)		inputValue;
- (void)	setInputValue:(id)aValue;
- (NSString*) lastFile;
- (void) setLastFile:(NSString*)aFile;
- (NSString*) script;
- (void) setScript:(NSString*)aString;
- (void) setScriptNoNote:(NSString*)aString;
- (NSString*) scriptName;
- (void) setScriptName:(NSString*)aString;
- (BOOL) parsedOK;
- (id) arg:(int)index;
- (void) setArg:(int)index withValue:(id)aValue;
- (ORScriptRunner*) scriptRunner;


#pragma mark ***Data ID
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;
- (NSDictionary*) dataRecordDescription;
- (void) shipTaskRecord:(id)aTask running:(BOOL)aState;
- (void) taskDidStart:(NSNotification*)aNote;
- (void) taskDidFinish:(NSNotification*)aNote;

#pragma mark ***Script Methods
- (void) scriptRunnerDidFinish:(BOOL)normalFinish returnValue:(id)aValue;
- (void) parseScript;
- (void) runScript;
- (BOOL) running;
- (void) stopScript;
- (void) saveFile;
- (void) loadScriptFromFile:(NSString*)aFilePath;
- (void) saveScriptToFile:(NSString*)aFilePath;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORScriptTaskScriptChanged;
extern NSString* ORScriptTaskNameChanged;
extern NSString* ORScriptTaskArgsChanged;
extern NSString* ORScriptTaskBreakChainChanged;
extern NSString* ORScriptTaskLastFileChangedChanged;


@interface ORDecoderScriptTask : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData  fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

