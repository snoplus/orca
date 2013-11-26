//
//  TaskStep.h
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

#import "OROpSeqStep.h"

@class ORTaskHandler;

@interface ORShellStep : OROpSeqStep
{
	NSString*       launchPath;
	NSArray*        argumentsArray;
	ORTaskHandler*  taskHandler;
	NSDictionary*   environment;
	id              currentDirectory;
	ORShellStep*    outputPipe;
	ORShellStep*    errorPipe;
	NSString*       outputStateKey;
	NSString*       errorStateKey;
	BOOL            trimNewlines;
	NSCondition*    taskStartedCondition;
	
	NSString*       outputStringErrorPattern;
	NSString*       errorStringErrorPattern;
	NSString*       outputStringWarningPattern;
	NSString*       errorStringWarningPattern;
}

@property (assign) BOOL         trimNewlines;
@property (copy) NSString*      outputStateKey;
@property (copy) NSString*      errorStateKey;
@property (retain) id           currentDirectory;
@property (copy) NSDictionary*  environment;
@property (copy) NSString*      launchPath;
@property (copy) NSArray*       argumentsArray;
@property (copy) NSString*      outputStringErrorPattern;
@property (copy) NSString*      errorStringErrorPattern;
@property (copy) NSString*      outputStringWarningPattern;
@property (copy) NSString*      errorStringWarningPattern;

+ (ORShellStep *)shellStepWithCommandLine:(NSString *)aLaunchPath, ... NS_REQUIRES_NIL_TERMINATION;

- (void) pipeOutputInto:(ORShellStep*)destination;
- (void) pipeErrorInto:(ORShellStep*) destination;

@end
