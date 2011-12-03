//
//  XL3_Link.m
//  ORCA
//
//  Created by Jarek Kaspar on Sat, Jul 9, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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
#import "XL3_Cmds.h"
#import "XL3_Link.h"
#import "ORSafeCircularBuffer.h"

#import <netdb.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <sys/select.h>
#import <sys/errno.h>


NSString* XL3_LinkConnectionChanged	= @"XL3_LinkConnectionChanged";
NSString* XL3_LinkTimeConnectedChanged	= @"XL3_LinkTimeConnectedChanged";
NSString* XL3_LinkIPNumberChanged	= @"XL3_LinkIPNumberChanged";
NSString* XL3_LinkConnectStateChanged	= @"XL3_LinkConnectStateChanged";
NSString* XL3_LinkErrorTimeOutChanged	= @"XL3_LinkErrorTimeOutChanged";

#define kCmdArrayHighWater 1000
#define kBundleBufferSize 10000*1440

@implementation XL3_Link

- (id) init
{
	self = [super init];
	commandSocketLock = [[NSLock alloc] init];
	coreSocketLock = [[NSLock alloc] init];
	cmdArrayLock = [[NSLock alloc] init];
	[self setNeedToSwap];
	connectState = kDisconnected;
	cmdArray = [[NSMutableArray alloc] init];
	bundleBuffer = [[ORSafeCircularBuffer alloc] initWithBufferSize:kBundleBufferSize];
	//[self initConnectionHistory];
	num_cmd_packets = 0;
	num_dat_packets = 0;
	return self;
}

- (void) dealloc
{
	@try {
		//[self stopCrate];
	}
	@catch (NSException* localException) {
	}
	[commandSocketLock release];
	[coreSocketLock release];
	[cmdArrayLock release];
	if(cmdArray){
		[cmdArray release];
		cmdArray = nil;
	}
	[bundleBuffer release];
	[super dealloc];
}

- (void) wakeUp 
{
	
	//[self performSelector:@selector(calculateRates) withObject:self afterDelay:kSBCRateIntegrationTime];
}

- (void) sleep 	
{
	
	//[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(calculateRates) object:nil];
}

#pragma mark •••DataTaker Helpers
- (BOOL) bundleAvailable
{
	return [bundleBuffer dataAvailable];
}

- (void) resetBundleBuffer
{
	return [bundleBuffer reset];
}

- (NSData*) readNextBundle
{
	return [bundleBuffer readNextBlock];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];

	[self setErrorTimeOut:  [decoder decodeIntForKey:   @"errorTimeOut"]];
	[self setNeedToSwap];

	commandSocketLock = [[NSLock alloc] init];
	coreSocketLock = [[NSLock alloc] init];
	cmdArrayLock = [[NSLock alloc] init];
	cmdArray = [[NSMutableArray alloc] init];
	bundleBuffer = [[ORSafeCircularBuffer alloc] initWithBufferSize:kBundleBufferSize];
	
	num_cmd_packets = 0;
	num_dat_packets = 0;

	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeInt:errorTimeOut		forKey:@"errorTimeOut"];
}


#pragma mark •••Accessors

- (BOOL) needToSwap
{
	return needToSwap;
}

- (void) setNeedToSwap
{
	//VME bus & ML403 are big-endian, ethernet as well
	if (0x0000ABCD == htonl(0x0000ABCD)) needToSwap = NO;
	else needToSwap = YES;
	//NSLog(@"XL3_Link %@ swapping.\n", needToSwap?@"is":@"is not");
}

#define swapLong(x) (((uint32_t)(x) << 24) | (((uint32_t)(x) & 0x0000FF00) <<  8) | (((uint32_t)(x) & 0x00FF0000) >>  8) | ((uint32_t)(x) >> 24))
#define swapShort(x) (((uint16_t)(x) <<  8) | ((uint16_t)(x)>>  8))

- (int)  connectState;
{
	return connectState;
}

- (BOOL) isConnected
{
	return isConnected;
}

- (void) setIsConnected:(BOOL)aNewIsConnected
{
	isConnected = aNewIsConnected;
	[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectionChanged object: self];
	[self setTimeConnected:isConnected?[NSCalendarDate date]:nil];
}

- (int)  serverSocket
{
	return serverSocket;
}

- (void) setServerSocket:(int) aSocket
{
	serverSocket = aSocket;
}

- (int)  workingSocket
{
	return workingSocket;
}

- (void) setWorkingSocket:(int) aSocket
{
	workingSocket = aSocket;
}

- (void) setErrorTimeOut:(int)aValue
{
	[[[self undoManager] prepareWithInvocationTarget:self] setErrorTimeOut:errorTimeOut];
	errorTimeOut = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkErrorTimeOutChanged object:self];
}

- (int) errorTimeOut
{
	return errorTimeOut;
}

- (int) errorTimeOutSeconds
{
	static int translatedTimeOut[4] = {2,10,60,0};
	if(errorTimeOut<0 || errorTimeOut>3)return 2;
	else return translatedTimeOut[errorTimeOut];
}

- (void) toggleConnect
{
	int oldState = connectState;
	switch(connectState){
		case kDisconnected:
			@try {
				[self connectSocket]; //will throw if can't connect
				connectState = kWaiting;
			}
			@catch (NSException* localException) {
				connectState = kDisconnected;
			}
			break;

		case kWaiting:
			@try {
				[self disconnectSocket]; //will throw if can't connect
				connectState = kDisconnected;
			}
			@catch (NSException* localException) {
				connectState = kDisconnected;
			}
			break;

		case kConnected:
			@try {
				[self disconnectSocket]; //will throw if can't connect
				connectState = kDisconnected;
			}
			@catch (NSException* localException) {
				connectState = kDisconnected;
			}
			break;
	}

	if (oldState != connectState) {
		[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object:self];
	}
}

- (NSCalendarDate*) timeConnected
{
	return timeConnected;
}

- (void) setTimeConnected:(NSCalendarDate*)newTimeConnected
{
	[timeConnected autorelease];
	timeConnected=[newTimeConnected retain];	
	[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkTimeConnectedChanged object:self];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkIPNumberChanged object:self];
	}
}

- (unsigned long)  portNumber
{
	return portNumber;
}

- (void) setPortNumber:(unsigned long)aPortNumber;
{
	portNumber = aPortNumber;
	//[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkIPNumberChanged object:self];
}

- (NSString*) crateName
{
	if(!crateName) return @"";
	return crateName;
}

- (void) setCrateName:(NSString*)aCrateName
{
	if([aCrateName length]){
		[[[self undoManager] prepareWithInvocationTarget:self] setCrateName:crateName];
		
		[crateName autorelease];
		crateName = [aCrateName copy];    
		
		//[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkIPNumberChanged object:self];
	}
}	

- (void) newMultiCmd
{
	aMultiCmdPacket.cmdHeader.packet_type = MULTI_FAST_CMD_ID;
	aMultiCmdPacket.cmdHeader.packet_num = (unsigned short) ++num_cmd_packets;
	aMultiCmdPacket.cmdHeader.num_bundles = 0;
	memset(aMultiCmdPacket.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
}

- (void) addMultiCmdToAddress:(long)anAddress withValue:(long)aValue
{
	MultiFC* theMultiFC = (MultiFC*) aMultiCmdPacket.payload;
	FECCommand* aFECCommand = &(theMultiFC->cmd[theMultiFC->howmany]);

	aFECCommand->cmd_num = theMultiFC->howmany;
	aFECCommand->packet_num = aMultiCmdPacket.cmdHeader.packet_num;
	aFECCommand->flags = 0;
	aFECCommand->address = anAddress;
	aFECCommand->data = aValue;
	
	theMultiFC->howmany++;
}

- (XL3_Packet*) executeMultiCmd
{
	MultiFC* theMultiFC = (MultiFC*) aMultiCmdPacket.payload;
	if (needToSwap) {
		unsigned int i = 0;
		for (i = 0; i < theMultiFC->howmany; i++) {
			FECCommand* command = &(theMultiFC->cmd[i]);
			command->cmd_num = swapLong(command->packet_num);
			command->packet_num = swapShort(command->packet_num);
			command->address = swapLong(command->address);
			command->data = swapLong(command->data);
		}
		theMultiFC->howmany = swapLong(theMultiFC->howmany);
		aMultiCmdPacket.cmdHeader.packet_type = swapShort(aMultiCmdPacket.cmdHeader.packet_type);
	}

	@try {
		[self sendXL3Packet:&aMultiCmdPacket];
	}
	@catch (NSException* localException) {
		NSLog(@"MultiCmd failed.\n");
		//@throw localException;
	}
		
	if (needToSwap) {
		aMultiCmdPacket.cmdHeader.packet_type = swapShort(aMultiCmdPacket.cmdHeader.packet_type);
		theMultiFC->howmany = swapLong(theMultiFC->howmany);
		unsigned int i = 0;
		for (i = 0; i < theMultiFC->howmany; i++) {
			FECCommand* command = &(theMultiFC->cmd[i]);
			command->cmd_num = swapLong(command->packet_num);
			command->packet_num = swapShort(command->packet_num);
			command->address = swapLong(command->address);
			command->data = swapLong(command->data);
		}
	}
	
	return &aMultiCmdPacket;
}

- (BOOL) multiCmdFailed
{
	BOOL error = NO;
	MultiFC* theMultiFC = (MultiFC*) aMultiCmdPacket.payload;

	unsigned int i = 0;
	for (i = 0; i < theMultiFC->howmany; i++) {
		FECCommand* command = &theMultiFC->cmd[i];
		error |= command->flags;
	}
			
	return error;
}

- (void) sendXL3Packet:(XL3_Packet*)aPacket
{
	//expects the packet is swapped correctly (both header and payload)
	unsigned char  packetType = aPacket->cmdHeader.packet_type;
	unsigned short packetNum  = aPacket->cmdHeader.packet_num;
	if (needToSwap) packetNum = swapShort(packetNum);
	
	@try {
		[commandSocketLock lock]; //begin critial section
		[self writePacket:(char*) aPacket];
		[self readXL3Packet:(XL3_Packet*)aPacket withPacketType:packetType andPacketNum:packetNum];
		[commandSocketLock unlock]; //end critial section
	}
	@catch (NSException* localException) {
		[commandSocketLock unlock]; //end critial section
		[localException raise];
	}
}


- (void) sendCommand:(long)aCmd withPayload:(XL3_PayloadStruct*)payloadBlock expectResponse:(BOOL)askForResponse
{
	//client is responsible for payload swapping, we take care of the header
	XL3_Packet aPacket;
	memset(aPacket.payload, 0, XL3_MAXPAYLOADSIZE_BYTES);
	unsigned char packetType = (unsigned char) aCmd;
	unsigned short packetNum = (unsigned short) ++num_cmd_packets;
	aPacket.cmdHeader.packet_num = (uint16_t) packetNum;
	aPacket.cmdHeader.packet_type = (uint8_t) packetType;
	aPacket.cmdHeader.num_bundles = 0;
	if (needToSwap) aPacket.cmdHeader.packet_num = swapShort(aPacket.cmdHeader.packet_num);
	memcpy(aPacket.payload, payloadBlock->payload, payloadBlock->numberBytesinPayload);
	
	@try {
		[commandSocketLock lock]; //begin critical section
		[self writePacket:(char*) &aPacket];
		[commandSocketLock unlock]; //end critical section
		
		if(askForResponse){
			[self readXL3Packet:&aPacket withPacketType:packetType andPacketNum:packetNum];
			XL3_PayloadStruct* payloadPtr = (XL3_PayloadStruct*) aPacket.payload;
			memcpy(payloadBlock->payload, payloadPtr, payloadBlock->numberBytesinPayload);
		}
	}
	@catch (NSException* localException) {
		[commandSocketLock unlock]; //end critical section
		@throw localException;
	}
	if (! askForResponse) {
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
	}
}


- (void) sendCommand:(long)aCmd expectResponse:(BOOL)askForResponse
{
	XL3_PayloadStruct payload;
	payload.numberBytesinPayload = 0;
	@try {
		[self sendCommand:aCmd withPayload:&payload expectResponse:askForResponse];
	}
	@catch (NSException* localException) {
		@throw localException;
		//what about the response?		
	}
}

- (void) sendFECCommand:(long)aCmd toAddress:(unsigned long)address withData:(unsigned long*)value
{
	XL3_PayloadStruct payload;
	FECCommand* command = (FECCommand*) payload.payload;
		
	command->cmd_num = aCmd;
	command->packet_num = 0; // todo: figure out what are these two good for...
	command->flags = 0;
	command->address = (uint32_t) address;
	command->data = *(uint32_t*) value;

	if (needToSwap) {
		command->cmd_num = swapLong(command->packet_num);
		command->packet_num = swapShort(command->packet_num);
		command->address = swapLong(command->address);
		command->data = swapLong(command->data);
	}	

	payload.numberBytesinPayload = sizeof(FECCommand);
	@try { 
		[self sendCommand:FAST_CMD_ID withPayload:&payload expectResponse:YES];
	}
	@catch (NSException* e) {
		NSLog(@"FECCommand error sending command\n");
		@throw e;
	}
	//return the same packet!
	if (command->flags != 0) {
		NSLog(@"%@ bus error\n", [self crateName]);
		@throw [NSException exceptionWithName:@"FECCommand error.\n" reason:@"XL3 bus error\n" userInfo:nil];
	}	

	*value = command->data;
	if (needToSwap) *value = swapLong(*value);	
}

- (void) readXL3Packet:(XL3_Packet*)aPacket withPacketType:(unsigned char)packetType andPacketNum:(unsigned short)packetNum
{
	//look into the cmdArray
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	NSDictionary* aCmd;
	NSMutableArray* foundCmds = [NSMutableArray array];
	time_t xl3ReadTimer = time(0);

    NSLog(@"waiting for response with packetType: %d and packetNum %d\n", packetType, packetNum);
    
	while(1) {
		@try {
			[cmdArrayLock lock];
			for (aCmd in cmdArray) {
				NSNumber* aPacketType = [aCmd objectForKey:@"packet_type"];
				NSNumber* aPacketNum = [aCmd objectForKey:@"packet_num"];
				
				if ([aPacketType unsignedShortValue] == packetType && [aPacketNum unsignedCharValue] == packetNum) {
					[foundCmds addObject:aCmd];
				}
			}
			[cmdArrayLock unlock];
		}
		@catch (NSException* e) {
			[cmdArrayLock unlock];
			NSLog(@"Error in readXL3Packet parsing cmdArray: %@ %@\n", [e name], [e reason]);
			@throw e;
		}	

		if ([foundCmds count]) {
			break;
		}
		else if ([self errorTimeOutSeconds] && time(0) - xl3ReadTimer > [self errorTimeOutSeconds]) {
			@throw [NSException exceptionWithName:@"ReadXL3Packet time out"
				reason:[NSString stringWithFormat:@"Time out for %@ <%@> port: %d\n", [self crateName], IPNumber, portNumber]
				userInfo:nil];
		}
		else {
            sleep(1);
        }
	}

	if ([foundCmds count] > 1) {
		NSLog(@"Multiple responses for XL3 command with packet type: %d and packet num: %d from %@ <%@> port: %d\n",
		      [self crateName], IPNumber, portNumber, packetType, packetNum);
		// todo: do something not too retarded, ask a smart guy
	}
	
	aCmd = [foundCmds objectAtIndex:0];
	[[aCmd objectForKey:@"xl3Packet"] getBytes:aPacket length:XL3_PACKET_SIZE];
	
	@try {
		[cmdArrayLock lock];
		[cmdArray removeObjectsInArray:foundCmds];
		[cmdArrayLock unlock];
	}
	@catch (NSException* localException) {
		[cmdArrayLock unlock];
		NSLog(@"XL3_Link error removing an XL3 packet from the command array\n");
		NSLog(@"%@ %@\n", [localException name], [localException reason]);
		@throw localException;
	}
} 

- (void) connectSocket
{
	if(!serverSocket && ([IPNumber length]!=0) && (portNumber!=0)){
		@try {
			[NSThread detachNewThreadSelector:@selector(connectToPort) toTarget:self withObject:nil];

			//[self setIsConnected: YES];
			//[self setTimeConnected:[NSCalendarDate date]];
			
		}
		@catch (NSException* localException) {
			NSLog(@"Socket creation failed for %@ on port %d\n", [self crateName], portNumber);
			if(serverSocket){
				close(serverSocket);
				serverSocket = 0;
			}
			[self setIsConnected: NO];
			[self setTimeConnected:nil];
			
			@throw localException;
		}
	}
	else {
		NSLog(@"XL3 Link failed to call connect for socketfd: %@, IPNumber: %@, and portNumber: %d\n",
		      serverSocket?@"ALLOCATED!":@"ok", IPNumber, portNumber);
	}
}

- (void) disconnectSocket
{
	if(serverSocket){
		close(serverSocket);
		serverSocket = 0;
	}
	
	if(workingSocket){
		close(workingSocket);
		workingSocket = 0;
	}
		
	[self setIsConnected: NO];
	[self setTimeConnected:nil];
	NSLog(@"Disconnected %@ <%@> port: %d\n", [self crateName], IPNumber, portNumber);
	//[[delegate crate] disconnected];	 
}

- (void) connectToPort
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool allocWithZone:nil] init];

	struct sockaddr_in my_addr;
	struct sockaddr_in their_addr;
	socklen_t sin_size;
	int32_t yes=1;

	//start try block here if we know how to handle the exceptions, ORCA gets killed now
	@try {
		if ((serverSocket = socket(PF_INET, SOCK_STREAM, 0)) == -1)
			[NSException raise:@"Socket failed" format:@"Couldn't get a socket for local XL3 Port %d", portNumber];
		//todo: try harder...
		//???TCP_NODELAY for the moment done with recv
		if (setsockopt(serverSocket,SOL_SOCKET,SO_REUSEADDR,&yes,sizeof(int)) == -1)
			[NSException raise:@"Socket options failed" format:@"Couldn't set socket options for local XL3 Port %d", portNumber];
			
		my_addr.sin_family = AF_INET;         // host byte order
		my_addr.sin_addr.s_addr = INADDR_ANY; // automatically fill with my IP
		memset(my_addr.sin_zero, '\0', sizeof my_addr.sin_zero);
			
		my_addr.sin_port = htons(portNumber);     // short, network byte order
		if (bind(serverSocket, (struct sockaddr *)&my_addr, sizeof(struct sockaddr)) == -1)
			[NSException raise:@"Bind failed" format:@"Couldn't bind to local XL3 Port %d", portNumber];
		
		if (listen(serverSocket, 1) == -1)
			[NSException raise:@"Listen failed" format:@"Couldn't listen on local XL3 port %d\n", portNumber];

		connectState = kWaiting;
		[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];

		//a single connection allowed only, no fork.
		sin_size = sizeof(struct sockaddr_in);
		workingSocket = 0;
		if ((workingSocket = accept(serverSocket, (struct sockaddr *)&their_addr, &sin_size)) == -1) {
			//if not socket connection was kill by UI... do something meaningful
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];		
			if ([self serverSocket]) {
				[NSException raise:@"Connection failed" format:@"Couldn't accept connection on local XL3 port %d\n", portNumber];
			}
			else {
				//disconnected by UI...
				return;
			}
		}
	}
	@catch (NSException* localException) {
		NSLog(@"XL3 socket failed with exception: %@ with reason: %@\n", [localException name], [localException reason]);
		
		if (serverSocket) {
			close(serverSocket);
			serverSocket = 0;
		}
		if (workingSocket) {
			close(workingSocket);
			workingSocket = 0;
		}
		NSLog(@"XL3 disconnected from local port %d\n", [self portNumber]);
		connectState = kDisconnected;
		[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];
		[self setIsConnected:NO];
		
		return;
	}
	
	//parse their_addr
	//if not correct swap the xl3Link with the correct crate
	//NSLog(@"Connected to %@ <%@> port: %d\n",[self crateName], IPNumber, portNumber);

	connectState = kConnected;
	[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];
	[self setIsConnected:YES];

	//[self getRunInfoBlock];
	//[[delegate crate] performSelector:@selector(connected) withObject:nil afterDelay:1];			

	NSLog(@"%@ connected on local port %d\n",[self crateName], [self portNumber]);

	fd_set fds;
	int selectionResult = 0;
	struct timeval tv;
	tv.tv_sec  = 0;
	tv.tv_usec = 10000;

	char aPacket[XL3_PACKET_SIZE];
	unsigned long bundle_count = 0;
	
	while(1) {
		if (!workingSocket) {
			NSLog(@"%@ not connected <%@> port: %d\n", [self crateName], IPNumber, portNumber);
			break;
		}
				
		FD_ZERO(&fds);
		FD_SET(workingSocket, &fds);
		selectionResult = select(workingSocket + 1, &fds, NULL, NULL, &tv);
		if (selectionResult == -1 && !(errno == EAGAIN || errno == EINTR)) {
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
			if (workingSocket || serverSocket) {
				NSLog(@"Error reading XL3 <%@> port: %d\n", IPNumber, portNumber);
			}
			break;
		}
		if (selectionResult > 0 && FD_ISSET(workingSocket, &fds)) {
			@try {
				[coreSocketLock lock];
				[self readPacket:aPacket];
				[coreSocketLock unlock];
            }
			@catch (NSException* localException) {
                [coreSocketLock unlock];
				if (serverSocket || workingSocket) {
					NSLog(@"Couldn't read from XL3 <%@> port:%d\n", IPNumber, portNumber);
				}
				break;
			}

            if (((XL3_Packet*) aPacket)->cmdHeader.packet_type == MEGA_BUNDLE_ID) {
                //packet_num?
                [bundleBuffer writeBlock:((XL3_Packet*) aPacket)->payload length:((XL3_Packet*) aPacket)->cmdHeader.num_bundles * 12];
                bundle_count++;
            }
            else if (((XL3_Packet*) aPacket)->cmdHeader.packet_type == PING_ID) {
                //NSLog(@"%@: received ping request\n", [self crateName]);
                (((XL3_Packet*) aPacket)->cmdHeader.packet_type = PONG_ID);
                @try {
                    [commandSocketLock lock]; //begin critial section
                    [self writePacket:(char*) aPacket];
                    //NSLog(@"%@: Sending pong response\n", [self crateName]);
                    [commandSocketLock unlock]; //end critial section
                }
                @catch (NSException* localException) {
                    [commandSocketLock unlock]; //end critial section
                    NSLog(@"%@: Sending pong response failed\n", [self crateName]);
                }
            }

            else if (((XL3_Packet*) aPacket)->cmdHeader.packet_type == MESSAGE_ID) {
                NSLog(@"%@ message: %s\n", [self crateName], ((XL3_Packet*) aPacket)->payload);
            }

            else if (((XL3_Packet*) aPacket)->cmdHeader.packet_type == ERROR_ID) {
                NSLog(@"%@ error packet received:\n", [self crateName]);
                int error;

                error = ((error_packet_t*) ((XL3_Packet*) aPacket)->payload)->cmd_in_rejected;
                if (needToSwap) error = swapLong(error);
                NSLog(@"cmd_in_rejected: %d\n", error);
 
                error = ((error_packet_t*) ((XL3_Packet *) aPacket)->payload)->transfer_error;
                if (needToSwap) error = swapLong(error);
                NSLog(@"transfer_errror: %d\n", error);

                error = ((error_packet_t*) ((XL3_Packet *) aPacket)->payload)->xl3_data_avail_unknown;
                if (needToSwap) error = swapLong(error);
                NSLog(@"xl3_data_avail_unknown: %d\n", error);

                error = ((error_packet_t*) ((XL3_Packet *) aPacket)->payload)->bundle_read_error;
                if (needToSwap) error = swapLong(error);
                NSLog(@"bundle_read_error: %d\n", error);

                error = ((error_packet_t*) ((XL3_Packet *) aPacket)->payload)->bundle_resync_error;
                if (needToSwap) error = swapLong(error);
                NSLog(@"bundle_resync_error: %d\n", error);

                NSLog(@"mem_level_unknown for slot:\n");
                unsigned i = 0;
                for (i = 0; i < 16; i++) {
                    error = ((error_packet_t*) ((XL3_Packet *) aPacket)->payload)->mem_level_unknown[i];
                    if (needToSwap) error = swapLong(error);
                    NSLog(@"%2d: %d\n", i, error);
                }
            }

            else if (((XL3_Packet*) aPacket)->cmdHeader.packet_type == SCREWED_ID) {
                NSLog(@"%@ screwed for slot:%s\n", [self crateName]);
                unsigned i, error;
                for (i = 0; i < 16; i++) {
                    error = ((screwed_packet_t*) ((XL3_Packet *) aPacket)->payload)->screwed[i];
                    if (needToSwap) error = swapLong(error);
                    NSLog(@"%2d: %d\n", i, error);
                }
            }

            else {	//cmd response
                unsigned short packetNum = ((XL3_Packet*) aPacket)->cmdHeader.packet_num;
                unsigned short packetType = ((XL3_Packet*) aPacket)->cmdHeader.packet_type;
                
                if (needToSwap) packetNum = swapShort(packetNum);
                NSLog(@"%@ packet type: %d and packetNum: %d, xl3 megabundle count: %d\n", [self crateName], packetType, packetNum, bundle_count);
                
                NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithUnsignedShort:packetNum],		@"packet_num",
                                [NSNumber numberWithUnsignedChar:packetType],		@"packet_type",
                                [NSDate dateWithTimeIntervalSinceNow:0],		@"date",
                                [NSData dataWithBytes:aPacket length:XL3_PACKET_SIZE],	@"xl3Packet",
                                nil];
                @try {
                    [cmdArrayLock lock];
                    [cmdArray addObject:aDictionary];
                    [cmdArrayLock unlock];
                }
                @catch (NSException* e) {
                    NSLog(@"%@: Failed to add received command response into the command array\n", [self crateName]);
                    [cmdArrayLock unlock];
                }
                
                //NSLog(@"%@: cmdArray includes %d cmd responses\n", [self crateName], [cmdArray count]);
                
                if ([cmdArray count] > kCmdArrayHighWater) {
                    //todo: post alarm
                    NSLog(@"Xl3 command array close to full for XL3 crate %@\n", [self crateName]);
                }
            }

        } //select
    } //while

	if (serverSocket || workingSocket) {
		if (serverSocket) {
			close(serverSocket);
			serverSocket = 0;
		}
		if (workingSocket) {
			close(workingSocket);
			workingSocket = 0;
		}
	
		NSLog(@"%@ disconnected from local port %d\n", [self crateName], [self portNumber]);
		connectState = kDisconnected;
		[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];
		[self setIsConnected:NO];
	}
	[pool release];
}


- (void) writePacket:(char*)aPacket
{
	//this is private method called from this object only, we lock the socket, and expect that thread lock is provided at a higher level
	if (!workingSocket) {
		[NSException raise:@"Write error" format:@"XL3 not connected %@ <%@> port: %d",[self crateName], IPNumber, portNumber];
	}

	int bytesWritten;
	int selectionResult = 0;
	int numBytesToSend = XL3_PACKET_SIZE;
	fd_set write_fds;

	struct timeval tv;
	tv.tv_sec  = [self errorTimeOutSeconds];
	tv.tv_usec = 10000;
	
	time_t t1 = time(0);

	@try {
        [coreSocketLock lock];
		while (numBytesToSend) {
			// The loop is to ignore EAGAIN and EINTR errors as these are harmless 
			do {
				FD_ZERO(&write_fds);
				FD_SET(workingSocket, &write_fds);
				
				selectionResult = select(workingSocket+1, NULL, &write_fds, NULL, &tv);
			} while (selectionResult == -1 && (errno == EAGAIN || errno == EINTR));
			
			if (selectionResult == -1){
				[NSException raise:@"Write error" format:@"Write error %@ <%@>: %s",[self crateName], IPNumber, strerror(errno)];
			}
			else if (selectionResult == 0 || ([self errorTimeOutSeconds] && time(0) - t1 > [self errorTimeOutSeconds])) {
				[NSException raise:@"Connection time out" format:@"Write to %@ <%@> port: %d timed out",[self crateName], IPNumber, portNumber];
			}

			do {
				bytesWritten = write(workingSocket, aPacket, numBytesToSend);
			} while (bytesWritten < 0 && (errno == EAGAIN || errno == EINTR));

			if (bytesWritten > 0) {
				aPacket += bytesWritten;
				numBytesToSend -= bytesWritten;
			} 
			else if (bytesWritten < 0) {
				if (errno == EPIPE) {
					//[self disconnect];
					//what do we want to do?
				}
				[NSException raise:@"Write error" format:@"Write error(%s) %@ <%@> port: %d",strerror(errno),[self crateName],IPNumber,portNumber];
			}
		}
        [coreSocketLock unlock];
	}
	@catch (NSException* localException) {
		[coreSocketLock unlock];
		if (serverSocket || workingSocket) {
			NSLog(@"Couldn't write to XL3 <%@> port:%d\n", IPNumber, portNumber);
		}
		@throw localException;
	}
}

- (void) readPacket:(char*)aPacket
{
	//this is private method called from this object only, we lock the socket, and expect that xl3 thread is the only accessor
	int n;			
	int selectionResult = 0;
	int numBytesToGet = XL3_PACKET_SIZE;
	time_t t1 = time(0);
	fd_set fds;
	
	struct timeval tv;
	tv.tv_sec  = 0;
	tv.tv_usec = 10000;
	
	while(numBytesToGet){
		do {
			n = recv(workingSocket, aPacket, numBytesToGet, MSG_DONTWAIT);
			if(n < 0 && (errno == EAGAIN || errno == EINTR)){
				if ([self errorTimeOutSeconds] && (time(0) - t1) > [self errorTimeOutSeconds]) {
					//[self disconnect];
					[NSException raise:@"Socket time out" format:@"%@ Disconnected", IPNumber];
				}
			}
			else break;
		} while (1);

		if (n > 0) {
			numBytesToGet -= n;
			aPacket += n;
			if (numBytesToGet == 0) break;
			//TODO!!! remove the following lines for deployment
			NSLog(@"XL3 packet read incomplete??? numBytesToGet: %d n: %d\n", numBytesToGet, n);
			aPacket[n] = '\0';
			NSLog(@"Dumping the partial packet as a string: %s\n", aPacket);
			numBytesToGet = 0;
			break;
		}
		else if(n==0){
			//[self disconnect];
			[NSException raise:@"Socket time out" format:@"%@ Disconnected", IPNumber];
		} 
		else {
			[NSException raise:@"Socket error" format:@"Error <%@>: %s",IPNumber,strerror(errno)];
		} 
		
		while(1) {
			FD_ZERO(&fds);
			FD_SET(workingSocket, &fds);
			selectionResult = select(workingSocket + 1, &fds, NULL, NULL, &tv);
			if (selectionResult == -1 && !(errno == EAGAIN || errno == EINTR)) {
				NSLog(@"Error reading XL3 <%@> port: %d\n", IPNumber, portNumber);
				[NSException raise:@"Socket Error" format:@"Error <%@>: %s", IPNumber, strerror(errno)];
			}
			if ([self errorTimeOutSeconds] && (time(0) - t1) > [self errorTimeOutSeconds]) {
				//[self disconnect];
				[NSException raise:@"Socket time out" format:@"%@ Disconnected",IPNumber];
			}
			
			if (selectionResult > 0 && FD_ISSET(workingSocket, &fds)) break;
		}			
 	}
}

- (BOOL) canWriteTo:(int)aSocket
{
	fd_set wfds;
	struct timeval tv;
	
	FD_ZERO(&wfds);
	FD_SET(aSocket, &wfds);
	
	tv.tv_sec = 0;
	tv.tv_usec = 0;
	
	int retval = select(aSocket + 1, NULL, &wfds, NULL, &tv);
	return (retval > 0) && FD_ISSET(aSocket, &wfds);
}

@end
