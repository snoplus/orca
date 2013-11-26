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

// remoteSocketStep:
// sends a command to a remote ORCA and stores the response
+ (ORRemoteSocketStep*)remoteCommands:(NSArray*)cmds remoteSocket:(ORRemoteSocketModel*)aSocketObj;
{
	ORRemoteSocketStep* step    = [[[self alloc] init] autorelease];
	step.socketObject = aSocketObj;
	step.commands      = cmds;
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
            for(id aCmd in commands){
                if([self isCancelled])break;
                [socketObject sendString:aCmd];
                NSTimeInterval totalTime = 0;
                NSString* outputStateKey = nil;
                NSArray* parts = [aCmd componentsSeparatedByString:@"="];
                if([parts count]==2){
                    outputStateKey = [[parts objectAtIndex:0] trimSpacesFromEnds];
                }
                while (![self isCancelled]){
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                         beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
                    totalTime += 0.25;
                    if(totalTime>2){
                        break;
                    }
                    if([socketObject responseExistsForKey:outputStateKey]){
                        [currentQueue setStateValue:[socketObject responseForKey:outputStateKey] forKey:outputStateKey];
                        break;
                    }
                }
                if([self isCancelled])break;
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
    if(self.errorCount && self.errorTitle)self.title = errorTitle;
}

- (void) require:(NSString*)aKey value:(NSString*)aValue
{
    if(!requirements)self.requirements = [NSMutableDictionary dictionary];
    [requirements setObject:aValue forKey:aKey];
}

@end
