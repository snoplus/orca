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
#import "NetSocket.h"

NSString* ORRSRemotePortChanged		 = @"ORRSRemotePortChanged";
NSString* ORRSRemoteHostChanged		 = @"ORRSRemoteHostChanged";
NSString* ORRemoteSocketLock		 = @"ORRemoteSocketLock";
NSString* ORRSRemoteConnectedChanged = @"ORRSRemoteConnectedChanged";

@implementation ORRemoteSocketModel
#pragma mark ***Initialization

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(isConnected) {
		[self disconnect];
	}
    
    [socket setDelegate:nil];
    [socket release];
    
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


- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
	return [super acceptsGuardian:aGuardian] ||
            [aGuardian isMemberOfClass:NSClassFromString(@"MajoranaModel")] ||
            [aGuardian isMemberOfClass:NSClassFromString(@"ORApcUpsModel")];
}

#pragma mark ***Accessors
- (void) setNewHost:(NSString*)newHost andPort:(int)newPort
{
	[self setRemoteHost:newHost];
	[self setRemotePort:newPort];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORRSRemoteHostChanged object:self];

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
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRSRemotePortChanged object:self];
}

- (BOOL) isConnected
{
	return isConnected;
}

- (void) setIsConnected:(BOOL)flag
{
	isConnected = flag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRSRemoteConnectedChanged object:self];
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

- (NetSocket*) socket
{
    return socket;
}

- (void) setSocket:(NetSocket*)aSocket
{
    [aSocket retain];
    [socket release];
    socket = aSocket;
    [socket setDelegate:self];
}

#pragma mark Connecting
- (void) connect
{
    if(remoteHost && remotePort){
        [self setSocket:[NetSocket netsocketConnectedToHost:remoteHost port:remotePort]];
    }
}

- (void) disconnect
{
    [socket close];
    [self setIsConnected:[socket isConnected]];
}

#pragma mark Sending and Receiving
- (BOOL) sendData:(NSData*)data
{
	@try {
        [socket writeData:data];
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

- (void) processMessage:(NSString*)message
{
    @synchronized(self){
        if(!responseDictionary)responseDictionary = [[NSMutableDictionary dictionary] retain];
    }
	message = [[message trimSpacesFromEnds] removeNLandCRs];
	NSArray* parts = [message componentsSeparatedByString:@":"];
    if([parts count]==2){
        NSString* aKey   = [[parts objectAtIndex:0]trimSpacesFromEnds];
        NSString* aValue = [[parts objectAtIndex:1]trimSpacesFromEnds];
        if([aKey length]!=0 && [aValue length]!=0){
            @synchronized(self){
                [responseDictionary setObject:aValue forKey:aKey];
            }
        }
    }
}

- (BOOL) responseExistsForKey:(NSString*)aKey
{
    BOOL itExists = NO;
    @synchronized(self){
        itExists = [responseDictionary objectForKey:aKey]!=nil;
    }
	return itExists;
}

- (void) removeResponseForKey:(NSString*)aKey
{
    @synchronized(self){
        [responseDictionary removeObjectForKey:aKey];
    }
}

- (id) responseForKey:(NSString*)aKey
{
	if(aKey){
        id theValue = nil;
        @synchronized(self){
            theValue =  [[[responseDictionary objectForKey:aKey] retain] autorelease];
            [responseDictionary removeObjectForKey:aKey];
        }
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

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
    }
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:NO];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
    if(inNetSocket == socket){
        NSString* theString = [[NSString alloc] initWithData:[inNetSocket readData] encoding:NSASCIIStringEncoding];
        NSArray* parts = [theString componentsSeparatedByString:@"\n"];
        for(NSString* aPart in parts){
            if([aPart length]==0) continue;
            else if([aPart rangeOfString:@"OrcaHeartBeat"].location != NSNotFound) continue;
            else if([aPart rangeOfString:@"runStatus"].location     != NSNotFound) continue;
            else [self processMessage:aPart];
        }
        [theString release];
    }
}
@end
