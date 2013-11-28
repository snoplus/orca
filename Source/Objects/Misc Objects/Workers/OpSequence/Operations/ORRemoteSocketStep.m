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

#import "ORRemoteSocketStep.h"
#import "OROpSequenceQueue.h"
#import "ORRemoteSocketModel.h"

@implementation ORRemoteSocketStep

@synthesize commands;
@synthesize socketObject;
@synthesize requirements;
@synthesize cmdIndexToExecute;

// remoteSocketStep:
// sends a command to a remote ORCA and stores the response
+ (ORRemoteSocketStep*)remoteSocket:(ORRemoteSocketModel*)aSocketObj commandSelection:(NSNumber*)anIndex commands:(NSString *)aCmd, ...;

{
    
	ORRemoteSocketStep* step    = [[[self alloc] init] autorelease];
	step.socketObject           = aSocketObj;
    step.commands               = [NSMutableArray array];
    
    va_list args;
    va_start(args, aCmd);
    for (NSString *arg = va_arg(args, NSString*);
         arg != nil;
         arg = va_arg(args, NSString*)) {
        [step.commands addObject:arg];
    }
    va_end(args);
        
    step.cmdIndexToExecute  = anIndex;
	return step;
}

- (void)dealloc
{
    [socketObject release];
    socketObject = nil;
	[commands release];
    commands = nil;
    [requirements release];
    requirements = nil;
    [cmdIndexToExecute release];
    cmdIndexToExecute = nil;
	[super dealloc];
}

- (NSString *)title
{
    if(!title)return [socketObject fullID];
    else      return title;
}

- (void)runStep
{
    
	if (self.concurrentStep) [NSThread sleepForTimeInterval:5.0];
    if(socketObject){
        [socketObject connect];
        if([socketObject isConnected]){
            NSNumber* indexNum = (NSNumber*)[self resolvedScriptValueForValue:cmdIndexToExecute];
            if(indexNum){
                NSInteger index = [indexNum intValue];
                if([commands count] > index){
                    [self executeCmd:[commands objectAtIndex:index]];
                }
            }
            else {
                for(id aCmd in commands){
                    if([self isCancelled])break;
                    [self executeCmd:aCmd];
                    if([self isCancelled])break;
                }
            }
            [socketObject disconnect];
        }
    }
    NSInteger err=0;
    for(id aKey in requirements){
        NSString* aValue = [self resolvedScriptValueForValue:[ScriptValue scriptValueWithKey:aKey]];
        NSString* requiredValue = [requirements objectForKey:aKey];
        if(![aValue isEqualToString:requiredValue]){
            err++;
        }
    }
    self.errorCount=err;
    if(self.errorCount) [currentQueue setErrorBit:self.stepId];
    else                [currentQueue setSuccessBit:self.stepId];
    if(self.errorCount && self.errorTitle)self.title = errorTitle;
}

- (void) executeCmd:(NSString*)aCmd
{
    [socketObject sendString:aCmd];
    NSTimeInterval totalTime = 0;
    NSString* outputStateKey = nil;
    NSArray* parts = [aCmd componentsSeparatedByString:@"="];
    if([parts count]==2){
        outputStateKey = [[parts objectAtIndex:0] trimSpacesFromEnds];
    }
    if(outputStateKey){
        while (![self isCancelled]){
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            totalTime += 0.1;
            if(totalTime>2)break;
            if([socketObject responseExistsForKey:outputStateKey]){
                [currentQueue setStateValue:[socketObject responseForKey:outputStateKey] forKey:outputStateKey];
                break;
            }
        }
    }

}

- (void) require:(NSString*)aKey value:(NSString*)aValue
{
    if(!requirements)self.requirements = [NSMutableDictionary dictionary];
    [requirements setObject:aValue forKey:aKey];
}

@end
