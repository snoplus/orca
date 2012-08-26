//
//  ORRemoteSocketModel.m
//  Orca
//
//  Created by Mark Howe on 10/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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

#import "ORRemoteSocketModel.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>
#import <arpa/inet.h>

NSString* ORRSRemotePortChanged		= @"ORRSRemotePortChanged";
NSString* ORRSRemoteHostChanged		= @"ORRSRemoteHostChanged";
NSString* ORRemoteSocketLock		= @"ORRemoteSocketLock";

@implementation ORRemoteSocketModel
#pragma mark ***Initialization
- (id) init
{
	self=[super init];
 //   [[self undoManager] disableUndoRegistration];
//    [[self undoManager] enableUndoRegistration];
	return self;
}

- (void) dealloc
{
	if(isConnected) {
		[self disconnect];
	}
	[remoteHost release];
	[responseDictionary release];
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"RemoteSocket"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORRemoteSocketController"];
}



#pragma mark ***Accessors
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

- (void) setNewHost:(NSString*)newHost andPort:(int)newPort
{
	if(isConnected) return;
	[self setRemoteHost:newHost];
	[self setRemotePort:newPort];
}

- (NSString*) remoteHost
{
	if(remoteHost)	return remoteHost;
	else			return @"";
}

- (NSString*) remoteHostName
{
	if([remoteHost length]){
		struct in_addr IPaddr;
		struct hostent *host;
		inet_pton(AF_INET, [remoteHost UTF8String], &IPaddr);
		host = gethostbyaddr((char *) &IPaddr, sizeof(IPaddr),AF_INET);
		return [NSString stringWithUTF8String:(host->h_name)];
	}
	else return @"";
}

- (void) setRemoteHost:(NSString *)newHost
{
	if(isConnected)	return;
	if(newHost)	{	
		[[[self undoManager] prepareWithInvocationTarget:self] setRemoteHost:remoteHost];
		
		[remoteHost autorelease];
		remoteHost = [newHost copy];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORRSRemoteHostChanged object:self];

	}
}

- (int) remotePort
{
	return remotePort;
}

- (void) setRemotePort:(int)newPort
{
	if(isConnected) return;
	[[[self undoManager] prepareWithInvocationTarget:self] setRemotePort:remotePort];
	remotePort = newPort;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRSRemotePortChanged object:self];
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
//	if([delegate respondsToSelector:@selector(connectionWillClose:)])
//		[delegate performSelector:@selector(connectionWillClose:) withObject:self];
	[self setC:nil];
	[self setIsConnected:NO];
//	if([delegate respondsToSelector:@selector(connectionDidClose:)])
//		[delegate performSelector:@selector(connectionDidClose:) withObject:self];
}

- (void) closeConnection:(SimpleCocoaConnection*)con
{
	[self disconnect];
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
}

- (BOOL) responseExistsForKey:(NSString*)aKey
{
	if([responseDictionary objectForKey:aKey])return YES;
	else return NO;
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

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{    
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setRemoteHost:[decoder decodeObjectForKey:@"remoteHost"]];
    [self setRemotePort:[decoder decodeIntForKey:@"remotePort"]];
    [[self undoManager] enableUndoRegistration];    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:remoteHost forKey:@"remoteHost"];
    [encoder encodeInt:remotePort    forKey:@"remotePort"];
}
@end

@interface SimpleCocoaConnection (PrivateMethods)
- (void)setRemoteAddress:(NSString*)newAddress;
- (void)setRemotePort:(int)newPort;
@end

@implementation SimpleCocoaConnection
- (id) initWithFileHandle:(NSFileHandle*)fh delegate:(id)initDelegate
{
    if(self = [super init]) {
		fileHandle = [fh retain];
		connectionDelegate = [initDelegate retain];
		
		// Get IP address of remote client
		CFSocketRef socket = CFSocketCreateWithNative(kCFAllocatorDefault, [fileHandle fileDescriptor], kCFSocketNoCallBack, NULL, NULL);
		CFDataRef addrData = CFSocketCopyPeerAddress(socket);
		CFRelease(socket);
		
		if(addrData) {
			struct sockaddr_in* sock = (struct sockaddr_in*)CFDataGetBytePtr(addrData);
			[self setRemotePort:(sock->sin_port)];
			char* naddr = inet_ntoa(sock->sin_addr);
			[self setRemoteAddress:[NSString stringWithCString:naddr encoding:NSASCIIStringEncoding]];
			CFRelease(addrData);
		} 
		else {
			[self setRemoteAddress:@"NULL"];
		}
		
		// Register for notification when data arrives
		NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self
			   selector:@selector(dataReceivedNotification:)
				   name:NSFileHandleReadCompletionNotification
				 object:fileHandle];
		[fileHandle readInBackgroundAndNotify];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[connectionDelegate release];
	[fileHandle closeFile];
	[fileHandle release];
	[remoteAddress release];
	[super dealloc];
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"%@:%d",[self remoteAddress],[self remotePort]];
}

#pragma mark Accessor Methods

- (NSFileHandle*) fileHandle 
{
	return fileHandle;
}

- (void) setRemoteAddress:(NSString*)newAddress
{
	[remoteAddress release];
	remoteAddress = [newAddress copy];
}

- (NSString*) remoteAddress
{
	return remoteAddress;
}

- (void) setRemotePort:(int)newPort
{
	remotePort = newPort;
}

- (int) remotePort
{
	return remotePort;
}

#pragma mark Notification Methods

- (void) dataReceivedNotification:(NSNotification*)notification
{
	NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
	if ([data length] == 0) {
		// NSFileHandle's way of telling us that the client closed the connection
		[connectionDelegate closeConnection:self];
	} 
	else {
		[fileHandle readInBackgroundAndNotify];
		NSString *received = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		if([received characterAtIndex:0] == 0x04) { // End-Of-Transmission sent by client
			return;
		}
		NSArray* parts = [received componentsSeparatedByString:@"\n"];
		for(NSString* aPart in parts){
			if([aPart length]==0) continue;
			else if([aPart rangeOfString:@"OrcaHeartBeat"].location != NSNotFound) continue; 
			else if([aPart rangeOfString:@"runStatus"].location     != NSNotFound) continue; 
			else [connectionDelegate processMessage:aPart fromConnection:self];
		}
	}
}

@end

