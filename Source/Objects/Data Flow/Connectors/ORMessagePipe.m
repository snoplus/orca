//
//  ORMessagePipe.m
//  Orca
//
//  Created by Mark Howe on 10/13/05.
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


#import "ORMessagePipe.h"
#import "ORDataPacket.h"

@implementation ORMessagePipe
+ (id) messagePipe
{
	ORMessagePipe* obj = [[ORMessagePipe alloc] init];
	return [obj autorelease];
}

- (ORConnector*) destination
{
	return destination;
}

- (void) setDestination:(ORConnector*)aConnector
{
	//don't retain to avoid cycles
	destination = aConnector;
}

#pragma mark ¥¥¥Message Passing
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if(![self respondsToSelector:aSelector]){
		id obj = [[destination connector] objectLink];
		if(obj)return [obj methodSignatureForSelector:aSelector];
		else return [super methodSignatureForSelector:aSelector];
	}
    else {
        return [super methodSignatureForSelector:aSelector];
    }
}

- (void) forwardInvocation:(NSInvocation *)invocation
{
	id obj = [[destination connector] objectLink];
	if(obj)[invocation invokeWithTarget:obj];
}

- (void) connectionChanged
{
}

#pragma mark ¥¥¥Optimization
- (void) runTaskStarted:(id)userInfo
{
	id obj = [[destination connector] objectLink];
	if(obj && [obj respondsToSelector:@selector(runTaskStarted:)]){
		[obj runTaskStarted:userInfo];
	}
}

- (void) processData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
{
	id obj = [[destination connector] objectLink];
	if(obj && [obj respondsToSelector:@selector(processData:userInfo:)]){
		[obj processData:aDataPacket userInfo:userInfo];
	}
}

- (void) runTaskStopped:(id)userInfo
{
	id obj = [[destination connector] objectLink];
	if(obj && [obj respondsToSelector:@selector(processData:)]){
		[obj runTaskStopped:userInfo];
	}
}

- (void) closeOutRun:(id)userInfo
{
	id obj = [[destination connector] objectLink];
	if(obj && [obj respondsToSelector:@selector(processData:)]){
		[obj closeOutRun:userInfo];
	}
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    
    self = [super init];
    [[[NSApp delegate] undoManager] disableUndoRegistration];
    [self setDestination:[decoder decodeObjectForKey:@"destination"]];    
    [[[NSApp delegate] undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:destination forKey:@"destination"];
}


@end
