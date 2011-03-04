//
//  ORBootBarModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
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
#import "ORBootBarModel.h"
#import "NetSocket.h"

#define kBootBarPort 9100

NSString* ORBootBarModelSelectedStateChanged = @"ORBootBarModelSelectedStateChanged";
NSString* ORBootBarModelSelectedChannelChanged = @"ORBootBarModelSelectedChannelChanged";
NSString* ORBootBarModelPasswordChanged		 = @"ORBootBarModelPasswordChanged";
NSString* ORBootBarModelLock				 = @"ORBootBarModelLock";
NSString* BootBarIPNumberChanged			 = @"BootBarIPNumberChanged";
NSString* ORBootBarModelIsConnectedChanged	 = @"ORBootBarModelIsConnectedChanged";
NSString* ORBootBarModelStatusChanged		 = @"ORBootBarModelStatusChanged";
NSString* ORBootBarModelBusyChanged			 = @"ORBootBarModelBusyChanged";

@interface ORBootBarModel (private)
- (void) sendCmd;
- (void) setPendingCmd:(NSString*)aCmd;
- (void) timeout;
@end

@implementation ORBootBarModel

- (void) dealloc
{
	[pendingCmd release];
    [password release];
	[socket close];
    [socket setDelegate:nil];
	[socket release];
 	[connectionHistory release];
    [IPNumber release];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:5];
}

- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super sleep];
}


#pragma mark •••Initialization
- (void) makeMainController
{
    [self linkToController:@"ORBootBarController"];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"BootBar"]];
}

- (void) initConnectionHistory
{
	ipNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.IPNumberIndex",[self className]]];
	if(!connectionHistory){
		NSArray* his = [[NSUserDefaults standardUserDefaults] objectForKey: [NSString stringWithFormat:@"orca.%@.ConnectionHistory",[self className]]];
		connectionHistory = [his mutableCopy];
	}
	if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
}

#pragma mark ***Accessors
- (int) selectedState
{
    return selectedState;
}

- (void) setSelectedState:(int)aSelectedState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedState:selectedState];
    selectedState = aSelectedState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBootBarModelSelectedStateChanged object:self];
}

- (int) selectedChannel
{
    return selectedChannel;
}

- (void) setSelectedChannel:(int)aSelectedChannel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedChannel:selectedChannel];
    selectedChannel = aSelectedChannel;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBootBarModelSelectedChannelChanged object:self];
}

- (NSString*) password
{
    return password;
}

- (void) setPassword:(NSString*)aPassword
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
    
    [password autorelease];
    password = [aPassword copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORBootBarModelPasswordChanged object:self];
}

- (void) clearHistory
{
	[connectionHistory release];
	connectionHistory = nil;
	
	[self setIPNumber:[self IPNumber]];
}

- (unsigned) connectionHistoryCount
{
	return [connectionHistory count];
}

- (id) connectionHistoryItem:(unsigned)index
{
	if(connectionHistory && index>=0 && index<[connectionHistory count])return [connectionHistory objectAtIndex:index];
	else return nil;
}

- (unsigned) ipNumberIndex
{
	return ipNumberIndex;
}

- (NSString*) IPNumber
{
	if(!IPNumber)return @"";
    return IPNumber;
}

- (void) setIPNumber:(NSString*)aIPNumber
{
	if([aIPNumber length]){
		
		[[[self undoManager] prepareWithInvocationTarget:self] setIPNumber:IPNumber];
		
		[IPNumber autorelease];
		IPNumber = [aIPNumber copy];    
		
		if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
		if(![connectionHistory containsObject:IPNumber]){
			[connectionHistory addObject:IPNumber];
		}
		ipNumberIndex = [connectionHistory indexOfObject:aIPNumber];
		
		[[NSUserDefaults standardUserDefaults] setObject:connectionHistory forKey:[NSString stringWithFormat:@"orca.%@.ConnectionHistory",[self className]]];
		[[NSUserDefaults standardUserDefaults] setInteger:ipNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.IPNumberIndex",[self className]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:BootBarIPNumberChanged object:self];
	}
}

- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
	if(![self isBusy])[self getStatus];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:30];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORBootBarModelIsConnectedChanged object:self];
}

- (void) connect
{
	if(!isConnected && [IPNumber length]){
		[self setSocket:[NetSocket netsocketConnectedToHost:IPNumber port:kBootBarPort]];	
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

- (void) turnOnOutlet:(int) i
{
	if([password length]){
		NSString* cmd = [NSString stringWithFormat:@"%c%@%dON\r",0x1B,password,i+1];
		[self setPendingCmd:cmd];
	}
}

- (void) turnOffOutlet:(int) i
{
	if([password length]){
		NSString* cmd = [NSString stringWithFormat:@"%c%@%dOFF\r",0x1B,password,i+1];
		[self setPendingCmd:cmd];
	}
}

- (void) getStatus
{
	if([password length]){
		NSString* cmd = [NSString stringWithFormat:@"%c%@?\r",0x1B,password];
		[self setPendingCmd:cmd];
	}
}

- (BOOL) outletStatus:(int)i
{
	if(i>=0 && i<8)return outletStatus[i];
	else return NO;
}

- (void) setOutlet:(int)i status:(BOOL)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setOutlet:i status:outletStatus[i]];
		outletStatus[i] = aValue;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:i] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORBootBarModelStatusChanged object:self userInfo:userInfo];
	}
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
		[self sendCmd];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
    if(inNetSocket == socket){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connect) object:nil];
		NSString* theString = [[[[NSString alloc] initWithData:[inNetSocket readData] encoding:NSASCIIStringEncoding] autorelease] uppercaseString];
		NSArray* lines = [theString componentsSeparatedByString:@"\n\r"];
		for(NSString* anOutlet in lines){
			if([anOutlet length] >= 4){
				NSArray* parts = [anOutlet componentsSeparatedByString:@" "];
				if([parts count]>=2){
					int index = [[parts objectAtIndex:0] intValue];
					if([[parts objectAtIndex:1] isEqualToString:@"ON"]){
						[self setOutlet:index-1 status:YES];
					}
					else if([[parts objectAtIndex:1] isEqualToString:@"OFF"]){
						[self setOutlet:index-1 status:NO];
					}
				}
			}
		}
		[self disconnect];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	}
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
		
		[self setIsConnected:NO];
		[socket autorelease];
		socket = nil;
		[self setPendingCmd:nil];
    }
}

- (BOOL) isBusy
{
	return pendingCmd != nil;
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self initConnectionHistory];
	
	[self setSelectedState:[decoder decodeIntForKey:@"selectedState"]];
	[self setSelectedChannel:[decoder decodeIntForKey:@"selectedChannel"]];
	[self setPassword:	[decoder decodeObjectForKey:@"password"]];
	[self setIPNumber:	[decoder decodeObjectForKey:@"IPNumber"]];
	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
 	[encoder encodeInt:selectedState forKey:@"selectedState"];
 	[encoder encodeInt:selectedChannel forKey:@"selectedChannel"];
 	[encoder encodeObject:password		forKey:@"password"];
 	[encoder encodeObject:IPNumber		forKey:@"IPNumber"];
}
@end

@implementation ORBootBarModel (private)
- (void) sendCmd
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	const char* bytes = [pendingCmd cStringUsingEncoding:NSASCIIStringEncoding];
	[socket write:bytes length:[pendingCmd length]];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:3];	
}
		 
- (void) timeout
{
	if([self isConnected]){
		[self disconnect];
	}
	else [self setPendingCmd:nil];
}
		 
- (void) setPendingCmd:(NSString*)aCmd
{
	if(!aCmd){
		[pendingCmd release];
		pendingCmd = nil;
	}
	else if(![self isBusy]){
		[pendingCmd release];
		pendingCmd = [aCmd copy];
		[self connect];
	}
	else NSLog(@"Boot Bar cmd ignored -- busy\n");
	[[NSNotificationCenter defaultCenter] postNotificationName:ORBootBarModelBusyChanged object:self];
}
@end

