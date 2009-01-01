//
//  ORProcessElementModel.m
//  Orca
//
//  Created by Mark Howe on 11/19/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORProcessElementModel.h"
#import "NSNotifications+Extensions.h"

NSString* ORProcessElementStateChangedNotification  = @"ORProcessElementStateChangedNotification";
NSString* ORProcessCommentChangedNotification       = @"ORProcessCommentChangedNotification";

@implementation ORProcessElementModel

#pragma mark ¥¥¥Inialization
- (id) init //designated initializer
{
    self = [super init];
    processLock = [[NSLock alloc] init];
    [self setUpNubs];
    return self;
}

- (void) dealloc
{
    [processLock release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
    [self setUpNubs];
}


- (void) setUpNubs
{
}

- (NSString*) shortName
{
	return @"";
}

- (int) compareStringTo:(id)anElement usingKey:(NSString*)aKey
{
    NSString* ourKey   = [self valueForKey:aKey];
    NSString* theirKey = [anElement valueForKey:aKey];
    if(!ourKey && theirKey)         return 1;
    else if(ourKey && !theirKey)    return -1;
    else if(!ourKey || !theirKey)   return 0;
    return [ourKey compare:theirKey];
}

#pragma mark ¥¥¥Accessors

- (NSString*) elementName
{
    return @"Processor";
}

- (NSString*) fullHwName
{
    return @"N/A";
}

- (id) stateValue
{
    return @"-";
}

- (NSString*) description:(NSString*)prefix
{
    return [NSString stringWithFormat:@"%@%@ %d",prefix,[self elementName],[self uniqueIdNumber]];
}

- (NSString*)comment
{
    return comment;
}
- (void) setComment:(NSString*)aComment
{
    if(!aComment)aComment = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setComment:comment];
    
    [comment autorelease];
    comment = [aComment copy];
    
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORProcessCommentChangedNotification
                              object:self];
    
}

- (void) setUniqueIdNumber :(unsigned long)aNumber
{
    [super setUniqueIdNumber:aNumber];
    [self postStateChange]; //force redraw
}


- (void) setState:(int)value
{
    [processLock lock];     //start critical section
    if(value != state){
        state = value;
		[self postStateChange];
    }
    [processLock unlock];   //end critical section
}

- (int) state
{
    return state;
}

- (void) setEvaluatedState:(int)value
{
    [processLock lock];     //start critical section
    if(value != evaluatedState){
        evaluatedState = value;
		[self postStateChange];
    }
    [processLock unlock];   //end critical section
}

- (int) evaluatedState
{
    return evaluatedState;
}


- (Class) guardianClass 
{
    return NSClassFromString(@"ORProcessModel");
}
- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return [aGuardian isKindOfClass:[self guardianClass]];
}

- (BOOL) canImageChangeWithState
{
    return NO;
}

#pragma mark ¥¥¥Thread Related
- (void) clearAlreadyEvaluatedFlag
{
    alreadyEvaluated = NO;
}

- (BOOL) alreadyEvaluated
{
	return alreadyEvaluated;
}

- (void) processIsStarting
{
	partOfRun = YES;
}

- (void) processIsStopping
{
	partOfRun = NO;
}

- (BOOL) partOfRun
{
	return partOfRun;
}


- (int) eval
{
    return 0;
}

- (void) postStateChange
{
    if([self canImageChangeWithState])[self setUpImage];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORProcessElementStateChangedNotification object:self userInfo:nil waitUntilDone:NO]; 
}

- (void) drawSelf:(NSRect)aRect withTransparency:(float)aTransparency
{
	[super drawSelf:aRect withTransparency:aTransparency];
}


#pragma mark ¥¥¥Archiving
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setComment:[decoder decodeObjectForKey:@"comment"]];
    
    [[self undoManager] enableUndoRegistration];
    
    processLock = [[NSLock alloc] init];
    [self setUpNubs];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:comment forKey:@"comment"];
}

@end
