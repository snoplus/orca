//
//  ScriptStep.h
//  CocoaScript
//
//  Created by Matt Gallagher on 2010/11/01.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <Cocoa/Cocoa.h>

@class OROpSequenceQueue;

@interface OROpSeqStep : NSOperation
{
	OROpSequenceQueue*  currentQueue;
	OROpSeqStep*        concurrentStep;
	NSTextStorage*      outputStringStorage;
	NSTextStorage*      errorStringStorage;
	NSInteger           errorCount;
	NSInteger           warningCount;
	NSString*           title;
	NSString*           errorTitle;
    NSInteger           stepId;
    BOOL                continueOnError;
    BOOL                useContinueMask;
    unsigned long long  continueMask;
    unsigned long long  quitMask;
}

@property (nonatomic, copy) NSString*       title;
@property (nonatomic, copy) NSString*       errorTitle;
@property (readonly)        NSTextStorage*  outputStringStorage;
@property (readonly)        NSTextStorage*  errorStringStorage;
@property (retain)          OROpSequenceQueue* currentQueue;
@property (retain)          OROpSeqStep*    concurrentStep;
@property (readwrite)       NSInteger       errorCount;
@property (readwrite)       NSInteger       warningCount;
@property (readwrite)       NSInteger       stepId;
@property (readwrite)       BOOL            continueOnError;

- (NSString *)outputString;
- (NSString *)errorString;

- (NSArray *)resolvedScriptArrayForArray:(NSArray *)array;
- (NSDictionary *)resolvedScriptDictionaryForDictionary:(NSDictionary *)dictionary;
- (NSString *)resolvedScriptValueForValue:(id)value;
- (void) requiredSuccessfullSteps:(int)aBit,... NS_REQUIRES_NIL_TERMINATION;
- (void) setSuccess;
- (void) setError;

- (void)appendOutputString:(NSString *)string;
- (void)replaceOutputString:(NSString *)string;

- (void)appendErrorString:(NSString *)string;
- (void)replaceErrorString:(NSString *)string;

- (void)appendAttributedOutputString:(NSAttributedString *)string;
- (void)replaceAttributedOutputString:(NSAttributedString *)string;

- (void)appendAttributedErrorString:(NSAttributedString *)string;
- (void)replaceAttributedErrorString:(NSAttributedString *)string;

- (void)applyErrorAttributesToOutputStringStorageRange:(NSRange)aRange;
- (void)applyWarningAttributesToOutputStringStorageRange:(NSRange)aRange;

- (void)applyErrorAttributesToErrorStringStorageRange:(NSRange)aRange;
- (void)applyWarningAttributesToErrorStringStorageRange:(NSRange)aRange;

- (void)replaceAndApplyErrorToOutputString:(NSString *)string;
- (void)replaceAndApplyWarningToOutputString:(NSString *)string;

- (void)replaceAndApplyErrorToErrorString:(NSString *)string;
- (void)replaceAndApplyWarningToErrorString:(NSString *)string;
@end

@interface ScriptValue : NSObject
{
	NSString *stateKey;
}
+ (ScriptValue *)scriptValueWithKey:(NSString *)stateKey;
@property (nonatomic, copy) NSString *stateKey;

@end
