//
//  ORFilterModel.h
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
#import "ORDataChainObject.h"
#import "ORBaseDecoder.h"

#define kNumScriptArgs 5
#define kNumDisplayValues 5
#define kNumFilterStacks 32

#pragma mark •••Forward Declarations
@class ORDataPacket;
@class ORQueue;

@interface ORFilterModel :  ORDataChainObject 
{
    @private
	
		unsigned long dataId1D;
		unsigned long dataId2D;

		NSString*			lastFile;
		NSString*			script;
		NSString*			scriptName;
		NSMutableArray*		args;
		NSMutableArray*		displayValues;
		id					inputValue;
		
		BOOL				stopThread;
		BOOL				running;
		BOOL				parsedOK;
		BOOL				normalExit;
		unsigned			yaccInputPosition;
		NSData*				expressionAsData;
		BOOL				exitNow;
		BOOL				firstTime;
		ORDataPacket*       transferDataPacket;
		ORDataPacket*       currentDataPacket;
		ORQueue*			stacks[kNumFilterStacks];
		BOOL				updateScheduled;
}

- (id)   init;
- (void) dealloc;
- (void) freeNodes;

#pragma mark •••Accessors
- (NSString*) lastFile;
- (void) setLastFile:(NSString*)aFile;
- (NSString*) script;
- (void) setScript:(NSString*)aString;
- (void) setScriptNoNote:(NSString*)aString;
- (NSString*) scriptName;
- (void) setScriptName:(NSString*)aString;
- (BOOL) parsedOK;
- (id)	 arg:(int)index;
- (void) setArg:(int)index withValue:(id)aValue;

- (id)	 displayValue:(int)index;

- (id)	 inputValue;
- (void) setInputValue:(id)aValue;
- (BOOL) exitNow;

#pragma mark •••Data Handling
- (unsigned long) dataId1D;
- (void) setDataId1D: (unsigned long) aDataId;
- (unsigned long) dataId2D;
- (void) setDataId2D: (unsigned long) aDataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;
- (NSDictionary*) dataRecordDescription;

- (void) processData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) closeOutRun:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;

#pragma mark ***Script Methods
- (void) parseScript;
- (void) saveFile;
- (void) loadScriptFromFile:(NSString*)aFilePath;
- (void) saveScriptToFile:(NSString*)aFilePath;

#pragma mark ***Plugin Interface
- (long) extractRecordID:(long)aValue;
- (long) extractRecordLen:(long)aValue;
- (void) shipRecord:(long*)p length:(long)length;
- (void) pushOntoStack:(int)i record:(long*)p;
- (long*) popFromStack:(int)i;
- (void) shipStack:(int)i;
- (void) dumpStack:(int)i;
- (long) stackCount:(int)i;
- (void) histo1D:(int)i value:(long)aValue;
- (void) histo2D:(int)i x:(long)x y:(long)y;
- (void) setDisplayValue:(int)index withValue:(long)aValue;

- (void) scheduledUpdate;

#pragma mark •••Parsers
- (void) parseFile:(NSString*)aPath;
- (BOOL) parsedOK;
- (void) parse:(NSString*)theString;

#pragma mark •••Yacc Input
- (void) setString:(NSString* )theString;
- (int) yyinputToBuffer:(char* )theBuffer withSize:(int)maxSize;

@end

extern NSString* ORFilterLock;
extern NSString* ORFilterLastFileChanged;
extern NSString* ORFilterNameChanged;
extern NSString* ORFilterArgsChanged;
extern NSString* ORFilterLastFileChangedChanged;
extern NSString* ORFilterScriptChanged;
extern NSString* ORFilterDisplayValuesChanged;


@interface ORFilterDecoderFor1D : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end

@interface ORFilterDecoderFor2D : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)ptr;
@end
