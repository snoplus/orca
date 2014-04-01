//
//  ORHeartbeatCheckerModel.m
//  Orca
//
//  Created by Mark Howe on Tues April 1, 2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "ORHeartbeatCheckerModel.h"
#import "ORProcessOutConnector.h"
#import "ORRemoteSocketModel.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>
#import <arpa/inet.h>

NSString* ORHeartbeatCheckerOutConnection    = @"ORHeartbeatCheckerOutConnection";
NSString* ORHeartbeatCheckerCycleTimeChanged = @"ORHeartbeatCheckerCycleTimeChanged";
NSString* ORHeartbeatCheckerLock             = @"ORHeartbeatCheckerLock";
NSString* ORHeartbeatCheckerPortChanged      = @"ORHeartbeatCheckerPortChanged";
NSString* ORHeartbeatCheckerHostChanged      = @"ORHeartbeatCheckerHostChanged";

@implementation ORHeartbeatCheckerModel

#pragma mark •••Initialization
- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(isConnected) {
		[self disconnect];
	}
	[remoteHost release];
	[responseDictionary release];
	[super dealloc];
}

-(void)makeConnectors
{

    ORProcessOutConnector* outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORHeartbeatCheckerOutConnection];
    [outConnector setConnectorType: 'LP2 ' ];
    [outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];
}

- (void) setUpImage
{
   [self setImage:[NSImage imageNamed:@"HeartbeatChecker"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORHeartbeatCheckerController"];
}
- (NSString*) elementName
{
	return @"HeartBeatChecker";
}

- (NSString*) iconLabel
{
    if(remoteHost)	{
        return [NSString stringWithFormat:@"%@",remoteHost];
    }
    else		return @"";

}

#pragma mark •••Accessors
- (SimpleCocoaConnection*)c
{
	return c;
}

- (void) setC:(SimpleCocoaConnection *)con
{
	[c release];
	[con retain];
	c = con;
}

- (NSString*) remoteHost
{
	if(remoteHost)	return remoteHost;
	else			return @"";
}

- (void) setRemoteHost:(NSString *)newHost
{
    if([newHost isEqualToString:remoteHost])return;
	if(newHost)	{
		[[[self undoManager] prepareWithInvocationTarget:self] setRemoteHost:remoteHost];
		
		[remoteHost autorelease];
		remoteHost = [newHost copy];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORHeartbeatCheckerHostChanged object:self];
        
	}
}

- (int) remotePort
{
	return remotePort;
}

- (void) setRemotePort:(int)newPort
{
    if(newPort==0)newPort = 4667;
    if(newPort == remotePort)return;
	if(isConnected) return;
	[[[self undoManager] prepareWithInvocationTarget:self] setRemotePort:remotePort];
	remotePort = newPort;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORHeartbeatCheckerPortChanged object:self];
}

- (BOOL) isConnected
{
	return isConnected;
}

- (void) setIsConnected:(BOOL)flag
{
	isConnected = flag;
}

- (int) connectionTimeout
{
	if(connectionTimeout < 1)return SCCDefaultConnectionTimeout;
	return connectionTimeout;
}

- (void) setConnectionTimeout:(int)newTimeout
{
	connectionTimeout = newTimeout;
}

- (NSStringEncoding) defaultStringEncoding
{
	if(defaultStringEncoding!=0)	return defaultStringEncoding;
	else							return NSASCIIStringEncoding;
}

- (void) setDefaultStringEncoding:(NSStringEncoding)encoding
{
	defaultStringEncoding = encoding;
}

#pragma mark Connecting
- (SCCInit) connect
{
	if(isConnected)		return SCCInitError_Connected;
	if(!remoteHost)		return SCCInitError_Host;
	if(remotePort < 1)	return SCCInitError_Port;
	
	int filedescriptor = -1;
	CFSocketRef socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 1, NULL, NULL);
	
	if(socket) {
		
		filedescriptor = CFSocketGetNative(socket);
		
		//this code prevents the socket from existing after the server has crashed or been forced to close
		
		int yes = 1;
		setsockopt(filedescriptor, SOL_SOCKET, SO_REUSEADDR, (void*)&yes, sizeof(yes));
		
		struct sockaddr_in addr4;
		memset(&addr4, 0, sizeof(addr4));
		addr4.sin_len = sizeof(addr4);
		addr4.sin_family = AF_INET;
		addr4.sin_port = htons(remotePort);
		inet_pton(AF_INET, [remoteHost UTF8String], &addr4.sin_addr);
		
		NSData* address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
		
		int retVal = CFSocketConnectToAddress(socket, (CFDataRef)address4, [self connectionTimeout]);
		CFRelease(socket);
        
		if(retVal == kCFSocketError)   return SCCInitError_NoConnection;
		if(retVal == kCFSocketTimeout) return SCCInitError_Timeout;
		if(retVal != kCFSocketSuccess) return SCCInitError_Unknown;
		
	}
	else return SCCInitError_NoSocket;
	
	NSFileHandle* fileHandle = [[[NSFileHandle alloc] initWithFileDescriptor:filedescriptor closeOnDealloc:YES] autorelease];
	if(fileHandle) {
		SimpleCocoaConnection* connection = [[SimpleCocoaConnection alloc] initWithFileHandle:fileHandle delegate:self];
		if(connection) {
			[self setC:connection];
			[self setIsConnected:YES];
		}
		[connection release];
	}
	return SCCInitOK;
}

- (void) disconnect
{
	[self setC:nil];
	[self setIsConnected:NO];
}

- (void) closeConnection:(SimpleCocoaConnection*)con
{
	[self disconnect];
}
- (NSTimeInterval) cycleTime
{
    return cycleTime;
}

- (void) setCycleTime:(NSTimeInterval)aCycleTime
{
    if(aCycleTime<=0)aCycleTime = 1;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setCycleTime:cycleTime];
	
    cycleTime = aCycleTime;
	
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORHeartbeatCheckerOutConnection
					  object:self];
}

#pragma mark Sending and Receiving
- (BOOL) sendData:(NSData*)data
{
	@try {
		[[c fileHandle] writeData:data];
    }
    @catch (NSException* exception) {
		return NO;
    }
	return YES;
}

- (BOOL) sendString:(NSString*)string
{
	return [self sendData:[string dataUsingEncoding:[self defaultStringEncoding]]];
}

- (BOOL) sendString:(NSString*)string withEncoding:(NSStringEncoding)encoding
{
	return [self sendData:[string dataUsingEncoding:encoding]];
}

- (void) processMessage:(NSString*)message fromConnection:(SimpleCocoaConnection*)con
{
	if(!responseDictionary)responseDictionary = [[NSMutableDictionary dictionary] retain];
	message = [[message trimSpacesFromEnds] removeNLandCRs];
	NSArray* parts = [message componentsSeparatedByString:@":"];
	if([parts count]==2) [responseDictionary setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
    if([self isConnected])[self disconnect];
}
- (BOOL) responseExistsForKey:(NSString*)aKey
{
	if([responseDictionary objectForKey:aKey])return YES;
	else return NO;
}

- (void) removeResponseForKey:(NSString*)aKey
{
	[responseDictionary removeObjectForKey:aKey];
}

- (id) responseForKey:(NSString*)aKey
{
	if(aKey){
		id theValue =  [[[responseDictionary objectForKey:aKey] retain] autorelease];
		[responseDictionary removeObjectForKey:aKey];
		return theValue;
	}
	else return nil;
}

- (void) processIsStarting
{
    [super processIsStarting];
    t0 = [NSDate timeIntervalSinceReferenceDate];
    [self setState:0];
}

- (id) eval
{
    NSTimeInterval t1 = [NSDate timeIntervalSinceReferenceDate];
    if((t1 - t0) >= cycleTime){
        t0 = t1;
        if(![self isConnected])[self connect];
        [self sendString:@"n=[RunControl isRunning];"];
    }
    
    [self setState:timerState]; //nothing connected..return timerState
	[self setEvaluatedState:[self state]];
	return [ORProcessResult processState:evaluatedState value:evaluatedState] ;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setCycleTime: [decoder decodeFloatForKey:@"cycleTime"]];
    [self setRemoteHost:[decoder decodeObjectForKey:@"remoteHost"]];
    [self setRemotePort:[decoder decodeIntForKey:@"remotePort"]];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:cycleTime   forKey:@"cycleTime"];
    [encoder encodeObject:remoteHost forKey:@"remoteHost"];
    [encoder encodeInt:remotePort    forKey:@"remotePort"];
}

@end
