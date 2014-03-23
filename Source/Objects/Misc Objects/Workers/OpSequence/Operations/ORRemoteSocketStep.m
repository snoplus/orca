//
//  ORRemoteSocketStep.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 28, 2013.
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

#import "ORRemoteSocketStep.h"
#import "OROpSequenceQueue.h"
#import "ORRemoteSocketModel.h"

@implementation ORRemoteSocketStep

@synthesize commands;
@synthesize socketObject;
@synthesize cmdIndexToExecute;
@synthesize outputStateKey;

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
    NSString *arg;
    for (arg = va_arg(args, NSString*);
         arg != nil;
         arg = va_arg(args, NSString*))
    {
        [anArgumentsArray addObject:arg];
    }
    va_end(args);
    step.commands           = anArgumentsArray;
    step.cmdIndexToExecute  = anIndex;

    [anArgumentsArray release];
    
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
    [super runStep];
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
    if (outputStateKey){
        NSString* result;
        if(self.errorCount) result = @"0";
        else                result = @"1";
        [currentQueue setStateValue:result forKey:outputStateKey];
	}

}

- (void) executeCmd:(NSString*)aCmd
{
    [socketObject sendString:aCmd];
    NSTimeInterval totalTime = 0;
    NSString* aKey = nil;
    NSArray* parts = [aCmd componentsSeparatedByString:@"="];
    if([parts count]==2){
        aKey = [[parts objectAtIndex:0] trimSpacesFromEnds];
    }
    while (![self isCancelled]){
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        totalTime += 0.1;
        if(totalTime>2)break;
        if(aKey){
            if([socketObject responseExistsForKey:aKey]){
                id aValue = [socketObject responseForKey:aKey];
                [currentQueue setStateValue:aValue forKey:aKey];
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
