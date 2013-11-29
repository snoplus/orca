//
//  OROpSeqStep.h
//  Orca
//
//  Created by Matt Gallagher on 2010/11/01.
//  Found on web and heavily modified by Mark Howe on Fri Nov 28, 2013.
//  Copyright (c) 2013  University of North Carolina. All rights reserved.
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

#import <Cocoa/Cocoa.h>

@class OROpSequenceQueue;

@interface OROpSeqStep : NSOperation
{
	OROpSequenceQueue*  currentQueue;
	OROpSeqStep*        concurrentStep;
	NSTextStorage*      outputStringStorage;
	NSTextStorage*      errorStringStorage;
	NSInteger           errorCount;
	NSString*           title;
	NSString*           errorTitle;
	NSString*           successTitle;
	NSMutableDictionary*   requirements;
	NSMutableDictionary*  andConditions;
	NSMutableDictionary*  orConditions;
}

@property (nonatomic, copy) NSString*       title;
@property (nonatomic, copy) NSString*       errorTitle;
@property (nonatomic, copy) NSString*       successTitle;
@property (readonly)        NSTextStorage*  outputStringStorage;
@property (readonly)        NSTextStorage*  errorStringStorage;
@property (retain)          OROpSequenceQueue* currentQueue;
@property (retain)          OROpSeqStep*    concurrentStep;
@property (readwrite)       NSInteger       errorCount;
@property (retain) NSMutableDictionary*   requirements;
@property (retain) NSMutableDictionary*   andConditions;
@property (retain) NSMutableDictionary*   orConditions;

- (NSString *)outputString;
- (NSString *)errorString;
- (void) require:(NSString*)aKey value:(NSString*)aValue;
- (void) addAndCondition:(NSString*)aKey value:(NSString*)aValue;
- (void) addOrCondition:(NSString*)aKey value:(NSString*)aValue;
- (NSInteger) checkRequirements;
- (BOOL) checkConditions;

- (NSArray *)resolvedScriptArrayForArray:(NSArray *)array;
- (NSDictionary *)resolvedScriptDictionaryForDictionary:(NSDictionary *)dictionary;
- (NSString *)resolvedScriptValueForValue:(id)value;

- (void)appendOutputString:(NSString *)string;
- (void)replaceOutputString:(NSString *)string;

- (void)appendErrorString:(NSString *)string;
- (void)replaceErrorString:(NSString *)string;

- (void)appendAttributedOutputString:(NSAttributedString *)string;
- (void)replaceAttributedOutputString:(NSAttributedString *)string;

- (void)appendAttributedErrorString:(NSAttributedString *)string;
- (void)replaceAttributedErrorString:(NSAttributedString *)string;

- (void)applyErrorAttributesToOutputStringStorageRange:(NSRange)aRange;

- (void)applyErrorAttributesToErrorStringStorageRange:(NSRange)aRange;

- (void)replaceAndApplyErrorToOutputString:(NSString *)string;

- (void)replaceAndApplyErrorToErrorString:(NSString *)string;
@end

@interface ScriptValue : NSObject
{
	NSString *stateKey;
}
+ (ScriptValue *)scriptValueWithKey:(NSString *)stateKey;
@property (nonatomic, copy) NSString *stateKey;

@end
