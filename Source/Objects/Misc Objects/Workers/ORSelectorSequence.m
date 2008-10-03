//
//  ORSelectorSequence.m
//  Orca
//
//  Created by Mark Howe on 10/3/08.
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
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

#import "ORSelectorSequence.h"

NSString* ORSequenceRunning  = @"ORSequenceRunning";
NSString* ORSequenceProgress = @"ORSequenceProgress";
NSString* ORSequenceStopped  = @"ORSequenceStopped";

@interface ORSelectorSequence (private)
- (void) doOneItem;
@end

@implementation ORSelectorSequence
+ (id) selectorSequenceWithDelegate:(id)aDelegate
{
	return [[[ORSelectorSequence alloc] initWithDelegate:aDelegate] autorelease];
}

- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSequenceStopped 
														object:delegate
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tag],@"tag",nil]];
	[tasks release];
	[nextTask release];
	[super dealloc];
}

- (void) setTag:(int)aTag
{
	tag = aTag;
}

- (id) forTarget:(id)aTarget
{
	if(nextTask)[nextTask release];
	nextTask = [[NSMutableDictionary dictionary] retain];
	[nextTask setObject:aTarget forKey:@"target"];
	return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	id target = [nextTask objectForKey:@"target"];
		
	if(target && ![self respondsToSelector:aSelector]){
		return [target methodSignatureForSelector:aSelector];
	}
	else {
		return [super methodSignatureForSelector:aSelector];
	}	
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
	if(nextTask){
		[nextTask setObject:invocation forKey:@"invocation"];
		if(!tasks)tasks = [[NSMutableArray array] retain];
		[tasks addObject: nextTask];
		[nextTask release];
		nextTask = nil;
	}
}

- (void) startSequence
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSequenceRunning 
														object:delegate
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:tag],@"tag",nil]];
	startCount = [tasks count];
	[self retain];
	[self performSelector:@selector(doOneItem) withObject:nil afterDelay:0];
}

- (void) stopSequence
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[tasks release];
	tasks = nil;
	[self autorelease];
	[delegate tasksCompleted:self];
}

@end

@implementation ORSelectorSequence (private)
- (void) doOneItem
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	NS_DURING
		if([tasks count]){
			NSMutableDictionary* theTask = [tasks objectAtIndex:0];
			
			id target					 = [theTask objectForKey:@"target"];
			NSInvocation* theInvocation  = [theTask objectForKey:@"invocation"];
		
			[theInvocation invokeWithTarget:target];
			[tasks removeObject:theTask];
			float progress = 100. - 100.*[tasks count]/(float)startCount;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORSequenceProgress 
																object:delegate
																userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:progress],@"progress",[NSNumber numberWithInt:tag],@"tag",nil]];
			
			[self performSelector:@selector(doOneItem) withObject:nil afterDelay:0];

		}
		else {
			if([delegate respondsToSelector:@selector(tasksCompleted:)]) [delegate tasksCompleted:self];
			[self autorelease];
		}
	
	NS_HANDLER
		NSLog(@"Task sequence aborted because of exception: %@\n",localException);
		[self autorelease];
		[localException raise];
	NS_ENDHANDLER
}
@end
