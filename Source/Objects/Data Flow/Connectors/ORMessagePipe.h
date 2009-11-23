//
//  ORMessagePipe.h
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




@class ORConnector;
@class ORDataPacket;

@interface ORMessagePipe : NSObject {
	ORConnector* destination;
}
+ (id) messagePipe;

#pragma mark ¥¥¥Accessors
- (ORConnector*) destination;
- (void) setDestination:(ORConnector*)aconnector;

#pragma mark ¥¥¥Message Passing
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
- (void) forwardInvocation:(NSInvocation *)invocation;
- (void) connectionChanged;

#pragma mark ¥¥¥Optimization
- (void) runTaskStarted:(id)userInfo;
- (void) processData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(id)userInfo;
- (void) closeOutRun:(id)userInfo;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end
