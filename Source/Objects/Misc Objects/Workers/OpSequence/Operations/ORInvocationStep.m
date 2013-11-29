//
//  TaskStep.m
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

#import "ORInvocationStep.h"
#import "OROpSequenceQueue.h"
#import "NSInvocation+Extensions.h"

@implementation ORInvocationStep

@synthesize invocation;
@synthesize outputStateKey;
@synthesize outputStringErrorPattern;

+ (ORInvocationStep*)invocation:(NSInvocation*)anInvocation;
{
	ORInvocationStep* step = [[[self alloc] init] autorelease];
    step.invocation = anInvocation;
	return step;
}

- (void)dealloc
{
    [invocation release];
    invocation = nil;
	[outputStringErrorPattern release];
    outputStringErrorPattern=nil;
	[super dealloc];
}

- (void)runStep
{
	if (self.concurrentStep) [NSThread sleepForTimeInterval:5.0];

    [invocation invokeWithNoUndoOnTarget:[invocation target]];
    id result = [invocation returnValue];
    
    [self parseErrors:[NSString stringWithFormat:@"%@",result]];
    if (outputStateKey && result){
        [currentQueue setStateValue:[NSString stringWithFormat:@"%@",result] forKey:outputStateKey];
	}
}

- (void) parseErrors:(id)outputString
{
	NSInteger errors    = 0;
	
	if (outputStringErrorPattern) {
		NSPredicate *errorPredicate = [NSComparisonPredicate
                                       predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject]
                                       rightExpression:[NSExpression expressionForConstantValue:outputStringErrorPattern]
                                       modifier:NSDirectPredicateModifier
                                       type:NSMatchesPredicateOperatorType
                                       options:0];
        
        
		NSUInteger length       = [outputString length];
		NSUInteger paraStart    = 0;
		NSUInteger paraEnd      = 0;
		NSUInteger contentsEnd  = 0;
        
		NSRange currentRange;
		while (paraEnd < length){
			[outputString getParagraphStart:&paraStart
                                        end:&paraEnd
                                contentsEnd:&contentsEnd
                                   forRange:NSMakeRange(paraEnd, 0)];
			currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
			NSString *paragraph = [outputString substringWithRange:currentRange];
            
			if ([errorPredicate evaluateWithObject:paragraph])          errors++;
		}
	}

	self.errorCount   = errors;
    
}




@end
