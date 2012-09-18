//-------------------------------------------------------------------------
//  ORRemoteSocketModel.h
//
//  Created by Mark A. Howe on Wednesday 10/18/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

#pragma mark ***Imported Files

@class SimpleCocoaConnection;
//return values of connect message
enum SCCInit {
    SCCInitOK = 1,
    SCCInitError_Connected = 2,
	SCCInitError_Host = 4,
	SCCInitError_Port = 8,
	SCCInitError_NoConnection = 32,
	SCCInitError_Timeout = 64,
	SCCInitError_NoSocket = 128,
	SCCInitError_Unknown = 256
};
typedef enum SCCInit SCCInit;

#define SCCDefaultConnectionTimeout 30
@interface ORRemoteSocketModel : OrcaObject
{
@private
	SimpleCocoaConnection*	c;
	NSString*				remoteHost;
	int						remotePort;
	BOOL					isConnected;
	int						connectionTimeout;
	NSStringEncoding		defaultStringEncoding;
	NSMutableDictionary*	responseDictionary;
}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;

#pragma mark ***Accessors
- (void)		setNewHost:(NSString*)newHost andPort:(int)newPort;
- (BOOL)		isConnected;

- (NSString*)	remoteHost;
- (NSString*)	remoteHostName;
- (void)		setRemoteHost:(NSString*)newHost;
- (int)			remotePort;
- (void)		setRemotePort:(int)newPort;
- (int)			connectionTimeout;
- (void)		setConnectionTimeout:(int)newTimeout;
- (NSStringEncoding) defaultStringEncoding;
- (void)		setDefaultStringEncoding:(NSStringEncoding)encoding;

#pragma mark ***Socket Methods
- (SCCInit) connect;
- (void)	disconnect;
- (BOOL)	sendData:(NSData*)data;
- (BOOL)	sendString:(NSString*)string;
- (BOOL)	sendString:(NSString*)string withEncoding:(NSStringEncoding)encoding;
- (id)		responseForKey:(NSString*)aKey;
- (BOOL)	responseExistsForKey:(NSString*)aKey;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORRSRemotePortChanged;
extern NSString* ORRSRemoteHostChanged;
extern NSString* ORRemoteSocketLock;

@interface SimpleCocoaConnection : NSObject {
@private
	NSFileHandle* fileHandle;	//Socket for the connection
    id connectionDelegate;		//always the client
    NSString* remoteAddress;	//server/remote IP address
	int remotePort;				//server/remote port
}

- (id)	initWithFileHandle:(NSFileHandle*)fh delegate:(id)initDelegate;
- (NSFileHandle*) fileHandle;
- (NSString*)	  remoteAddress;
- (int)			  remotePort;
- (void) dataReceivedNotification:(NSNotification*)notification;

@end
