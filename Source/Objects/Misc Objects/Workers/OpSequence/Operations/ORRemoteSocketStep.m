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
@synthesize cmdIndexToExecute;

// remoteSocketStep:
// sends a command to a remote ORCA and stores the response
+ (ORRemoteSocketStep*)remoteSocket:(ORRemoteSocketModel*)aSocketObj commandSelection:(NSNumber*)anIndex commands:(NSString *)aCmd, ...;

{
    
	ORRemoteSocketStep* step    = [[[self alloc] init] autorelease];
	step.socketObject           = aSocketObj;
    
    NSMutableArray *anArgumentsArray = [[NSMutableArray alloc] init];
    [anArgumentsArray addObject:aCmd];
   
    va_list args;
    va_start(args, aCmd);
    for (NSString *arg = va_arg(args, NSString*);
         arg != nil;
         arg = va_arg(args, NSString*))
    {
        [anArgumentsArray addObject:arg];
    }
    va_end(args);
    step.commands           = anArgumentsArray;
    step.cmdIndexToExecute  = anIndex;
    
	return step;
}

- (void)dealloc
{
    [socketObject release];
    socketObject = nil;
	[commands release];
    commands = nil;
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
                }
            }
            [socketObject disconnect];
        }
        else self.errorCount=1;
    }
    
     self.errorCount += [self checkRequirements];
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
    while (![self isCancelled]){
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        totalTime += 0.1;
        if(totalTime>2)break;
        if(outputStateKey){
            if([socketObject responseExistsForKey:outputStateKey]){
                id aValue = [socketObject responseForKey:outputStateKey];
                [currentQueue setStateValue:aValue forKey:outputStateKey];
                break;
            }
        }
        if([socketObject responseExistsForKey:@"Error"]){
            id aValue = [socketObject responseForKey:@"Error"];  //clear the error
            [self setErrorTitle:aValue];
            self.errorCount = 1;
            break;
        }
        if([socketObject responseExistsForKey:@"Success"]){
            [socketObject responseForKey:@"Success"]; //clear the success flag
            break;
        }
    }
}



@end
