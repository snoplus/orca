//
//  ORNplHVModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Dec 6 2007
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORNplHVModel.h"
#import "NetSocket.h"

NSString* ORNplHVModelCmdStringChanged = @"ORNplHVModelCmdStringChanged";
NSString* ORNplHVModelIsConnectedChanged	= @"ORNplHVModelIsConnectedChanged";
NSString* ORNplHVModelIpAddressChanged		= @"ORNplHVModelIpAddressChanged";

@implementation ORNplHVModel

- (void) makeMainController
{
    [self linkToController:@"ORNplHVController"];
}

- (void) dealloc
{
    [cmdString release];
	[socket close];
	[socket release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	NS_DURING
		[self connect];
		[self connectionChanged];
	NS_HANDLER
	NS_ENDHANDLER
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"NplHVIcon"]];
}


- (id)  dialogLock
{
	return @"ORNplHVLock";
}

#pragma mark ***Accessors

- (NSString*) cmdString
{
    return cmdString;
}

- (void) setCmdString:(NSString*)aCmdString
{
	if(!aCmdString)aCmdString = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setCmdString:cmdString];
    
	[cmdString autorelease];
    cmdString = [aCmdString copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNplHVModelCmdStringChanged object:self];
}

- (NetSocket*) socket
{
	return socket;
}
- (void) setSocket:(NetSocket*)aSocket
{
	if(aSocket != socket)[socket close];
	[aSocket retain];
	[socket release];
	socket = aSocket;
    [socket setDelegate:self];
}

- (void) setIsConnected:(BOOL)aFlag
{
    isConnected = aFlag;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNplHVModelIsConnectedChanged object:self];
}

- (NSString*) ipAddress
{
    return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
	if(!aIpAddress)aIpAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
    
    [ipAddress autorelease];
    ipAddress = [aIpAddress copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNplHVModelIpAddressChanged object:self];
}


- (void) connect
{
	if(!isConnected){
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:kNplHVPort]];	
        [self setIsConnected:[socket isConnected]];
	}
	else {
		[self setSocket:nil];	
        [self setIsConnected:[socket isConnected]];
	}
}

- (BOOL) isConnected
{
	return isConnected;
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
    if(inNetSocket == socket){
		NSString* theString = [[inNetSocket readString:NSASCIIStringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		NSLog(@"From NPL HV: %@\n",theString);
	}
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:NO];
		[socket autorelease];
		socket = nil;
    }
}


#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setCmdString:[decoder decodeObjectForKey:@"ORNplHVModelCmdString"]];
	[self setIpAddress:[decoder decodeObjectForKey:@"ORNplHVModelIpAddress"]];
    [[self undoManager] enableUndoRegistration];    
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:cmdString forKey:@"ORNplHVModelCmdString"];
    [encoder encodeObject:ipAddress forKey:@"ORNplHVModelIpAddress"];
}

- (void) sendCmd:(NSString*)aCmd
{
	if(aCmd)[socket writeString:aCmd encoding:NSASCIIStringEncoding];
}
@end
