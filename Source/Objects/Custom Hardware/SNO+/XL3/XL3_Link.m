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

#import <netdb.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <sys/select.h>
#import <sys/errno.h>


NSString* XL3_LinkConnectionChanged	= @"XL3_LinkConnectionChanged";
NSString* XL3_LinkTimeConnectedChanged	= @"XL3_LinkTimeConnectedChanged";
NSString* XL3_LinkIPNumberChanged	= @"XL3_LinkIPNumberChanged";
NSString* XL3_LinkConnectStateChanged	= @"XL3_LinkConnectStateChanged";

@implementation XL3_Link

- (id)   init
{
	self = [super init];
	socketLock = [[NSLock alloc] init];
	[self setNeedToSwap];
	connectState = kDisconnected;
	//[self initConnectionHistory];
	return self;
}

- (void) dealloc
{
	@try {
		//[self stopCrate];
	}
	@catch (NSException* localException) {
	}
	[socketLock release];

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


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];

	socketLock = [[NSLock alloc] init];

	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	
}


#pragma mark •••Accessors

- (bool) needToSwap
{
	return needToSwap;
}

- (void) setNeedToSwap
{
	//VME bus & ML403 are big-endian, ethernet as well
	uint32_t test = 0x0000ABCD;
	if (test == htonl(test)) needToSwap = false;
	else needToSwap = true;
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

- (int)  portNumber
{
	return portNumber;
}

- (void) setPortNumber:(int)aPortNumber;
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

- (void) sendCommand:(long)aCmd withPayload:(XL3_PayloadStruct*)payloadBlock expectResponse:(BOOL)askForResponse
{
	XL3_Packet aPacket;
	aPacket.cmdHeader.cmdID = (uint32_t) aCmd;
	if (needToSwap) aPacket.cmdHeader.cmdID = swapLong(aPacket.cmdHeader.cmdID);
	memcpy(&aPacket.payload, &payloadBlock->payload, payloadBlock->numberBytesinPayload);
	
	@try {
		[socketLock lock]; //begin critical section
		[self write:workingSocket buffer:&aPacket];
		
		if(askForResponse){
			[self read:workingSocket buffer:&aPacket];
			XL3_PayloadStruct* payloadPtr = (XL3_PayloadStruct*) aPacket.payload;
			memcpy(&payloadBlock->payload, payloadPtr, payloadBlock->numberBytesinPayload);
		}
		[socketLock unlock]; //end critical section
		
	}
	@catch (NSException* localException) {
		[socketLock unlock]; //end critical section
		[localException raise];
	}	
}


- (void) sendCommand:(long)aCmd expectResponse:(BOOL)askForResponse
{
	XL3_PayloadStruct payload;
	payload.numberBytesinPayload = 0;
	[self sendCommand:aCmd withPayload:&payload expectResponse:askForResponse];
	//what about the response?
}

- (void) sendFECCommand:(long)aCmd toAddress:(unsigned long)address withData:(unsigned long*)value
{
	XL3_PayloadStruct payload;
	FECCommand* command = (FECCommand*) &payload.payload;
		
	command->cmdID = (uint16_t) aCmd;
	command->flags = 0;
	command->address = (uint32_t) address;
	command->data = (uint32_t) value;

	if (needToSwap) {
		command->cmdID = swapShort(command->cmdID);
		command->address = swapLong(command->address);
		command->data = swapLong(command->data);
	}	

	payload.numberBytesinPayload = sizeof(FECCommand);
	[self sendCommand:SINGLE_CMD_ID withPayload:&payload expectResponse:YES];
	
	//return the same packet!
	//look for flags
	if (command->flags != 0) NSLog(@"XL3 bus error\n");
	//raise exception
	*value = command->data;
	if (needToSwap) *value = swapLong(*value);	
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
			
			@throw;
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
	NSLog(@"Disconnected from %@ <%@> port: %d\n", [self crateName], IPNumber, portNumber);
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
	if ((serverSocket = socket(PF_INET, SOCK_STREAM, 0)) == -1)
		[NSException raise:@"Socket Failed" format:@"Couldn't get a socket for local XL3 Port %d", portNumber];
	//try harder...
	//???TCP_NODELAY
	if (setsockopt(serverSocket,SOL_SOCKET,SO_REUSEADDR,&yes,sizeof(int)) == -1)
		[NSException raise:@"Socket Options Failed" format:@"Couldn't set socket options for local XL3 Port %d", portNumber];
		
	my_addr.sin_family = AF_INET;         // host byte order
	my_addr.sin_addr.s_addr = INADDR_ANY; // automatically fill with my IP
	memset(my_addr.sin_zero, '\0', sizeof my_addr.sin_zero);
		
	my_addr.sin_port = htons(portNumber);     // short, network byte order
	if (bind(serverSocket, (struct sockaddr *)&my_addr, sizeof(struct sockaddr)) == -1)
		[NSException raise:@"Bind Failed" format:@"Couldn't bind to local XL3 Port %d", portNumber];
	
	if (listen(serverSocket, 1) == -1)
		[NSException raise:@"Listen Failed" format:@"Couldn't listen on local XL3 port %d\n", portNumber];

	connectState = kWaiting;
	[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];

	//a single connection allowed only, no fork.
	sin_size = sizeof(struct sockaddr_in);
	workingSocket = 0;
	if ((workingSocket = accept(serverSocket, (struct sockaddr *)&their_addr, &sin_size)) == -1) {
		//if not socket connection was kill by UI... do something meaningful
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];		
		if ([self serverSocket]) {
			[NSException raise:@"Connection Failed" format:@"Couldn't accept connection on local XL3 port %d\n", portNumber];
		}
		else {
			//disconnected by UI...
			return;
		}
	}
	//catch block to be added here
	
	//parse their_addr
	//if not correct swap the xl3Link with the correct crate
	//NSLog(@"Connected to %@ <%@> port: %d\n",[self crateName], IPNumber, portNumber);

	connectState = kConnected;
	[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];
	[self setIsConnected:YES];
	//[self getRunInfoBlock];
	//[[delegate crate] performSelector:@selector(connected) withObject:nil afterDelay:1];			

	NSLog(@"XL3 connected on local port %d\n", [self portNumber]);

	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];

	close(serverSocket);
	serverSocket = 0;
	close(workingSocket);
	workingSocket = 0;
	
	NSLog(@"XL3 disconnected from local port %d\n", [self portNumber]);
	connectState = kDisconnected;
	[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];
	[self setIsConnected:NO];


	[pool release];
}


- (void) send:(XL3_Packet*)aSendPacket receive:(XL3_Packet*)aReceivePacket
{
	@try {
		[socketLock lock]; //begin critial section
		[self write:workingSocket buffer:aSendPacket];
		[self read:workingSocket buffer:aReceivePacket];
		[socketLock unlock]; //end critial section
	}
	@catch (NSException* localException) {
		[socketLock unlock]; //end critial section
		[localException raise];
	}
}

- (void) write:(int)aSocket buffer:(XL3_Packet*)aPacket
{
	/*
	//Note there are NO locks on this method, but it is private and can only be called from this object. Care must
	//be taken that thread locks are provided at a higher level.
	aPacket->message[0] = '\0';
	if(!aSocket)	[NSException raise:@"Write Error" format:@"SBC Not Connected %@ <%@> port: %d",[self crateName],IPNumber,portNumber];
	
	
	// wait until timeout or data received
	int selectionResult = 0;
	int bytesWritten = 0;
	int numBytesToSend = sizeof(long) +
	sizeof(SBC_CommandHeader) + 
	kSBC_MaxMessageSizeBytes + 
	aPacket->cmdHeader.numberBytesinPayload;
	aPacket->numBytes = numBytesToSend;
	char* packetPtr = (char*)aPacket;		//recast the first 'real' word in the packet
	while (numBytesToSend) {
		// The loop is to ignore EAGAIN and EINTR errors as these are harmless 
		do {
			// set up the file descriptor set
			fd_set write_fds;
			FD_ZERO(&write_fds);
			FD_SET(aSocket, &write_fds);
			
			struct timeval tv;
			tv.tv_sec  = 2;
			tv.tv_usec = 0;
			selectionResult = select(aSocket+1, NULL, &write_fds, NULL, &tv);
		} while (selectionResult == kSelectionError && (errno == EAGAIN || errno == EINTR));
		
		if (selectionResult == kSelectionError){
			[NSException raise:@"Write Error" format:@"Write Error %@ <%@>: %s",[self crateName],IPNumber,strerror(errno)];
		}
		else if (selectionResult == kSelectionTimeout) {
			[NSException raise:@"ConnectionTimeOut" format:@"Write from %@ <%@> port: %d timed out",[self crateName],IPNumber,portNumber];
		}   
		do {
			bytesWritten = write(aSocket,packetPtr,numBytesToSend);
		} while (bytesWritten < 0 && (errno == EAGAIN || errno == EINTR));
		if (bytesWritten > 0) {
			packetPtr += bytesWritten;
			numBytesToSend -= bytesWritten;
			bytesSent += bytesWritten;
		} 
		else if (bytesWritten < 0) {
			if (errno == EPIPE) {
				[self disconnect];
			}
			[NSException raise:@"Write Error" format:@"Write Error(%s) %@ <%@> port: %d",strerror(errno),[self crateName],IPNumber,portNumber];
		}
	}
	*/
}

- (void) read:(int)aSocket buffer:(XL3_Packet*)aPacket
{
	/*	
	//Note that there are NO locks on this method, but it is private and can only be called from this object. 
	//Care must be taken that thread locks are provided at a higher level in this object
	if(!aSocket)	[NSException raise:@"Read Error" format:@"SBC Not Connected %@ <%@> port: %d",[self crateName],IPNumber,portNumber];
	
	// wait until timeout or data received
	int  selectionResult;
	
	// The loop is to ignore EAGAIN and EINTR errors as these are harmless 
	do {
		// set up the file descriptor set
		fd_set read_fds;
		FD_ZERO(&read_fds);
		FD_SET(aSocket, &read_fds);
		
		struct timeval tv;
		tv.tv_sec  = 2;
		tv.tv_usec = 0;
		selectionResult = select(aSocket+1, NULL, &read_fds, NULL, &tv);
	} while (selectionResult == kSelectionError && (errno == EAGAIN || errno == EINTR));
	
	if(selectionResult > 0){
		[self readSocket:aSocket buffer:aPacket];
	}
	else if (selectionResult == kSelectionError){
		[NSException raise:@"Read Error" format:@"Read Error %@ <%@>: %s",[self crateName], IPNumber,strerror(errno)];
	}
	else if (selectionResult == kSelectionTimeout) {
		[NSException raise:@"ConnectionTimeOut" format:@"Read from %@ <%@> port: %d timed out",[self crateName],IPNumber,portNumber];
	}
	if(aPacket->message[0])NSLog(@"%s\n",aPacket->message);
	*/
} 

- (void) readSocket:(int)aSocket buffer:(XL3_Packet*)aPacket
{
	/*
	int n;			
	int  selectionResult = 0;
	long numBytesToGet = 0;
	time_t t1 = time(0);
	do {
		n = recv(aSocket, &numBytesToGet, sizeof(numBytesToGet), 0);
		if(n<0 && (errno == EAGAIN || errno == EINTR)){
			int timeout = [self errorTimeOutSeconds];
			if(timeout>0){
				if((time(0)-t1)>timeout) {
					[self disconnect];
					[NSException raise:@"Socket Disconnected" format:@"%@ Disconnected",IPNumber];
				}
			}
		}
		else break;
		
	} while (1);
	
	if(n==0){
		[self disconnect];
		[NSException raise:@"Socket Disconnected" format:@"%@ Disconnected",IPNumber];
	} 
	else if (n<0) {
		[NSException raise:@"Socket Error" format:@"Error: %s",strerror(errno)];
	} 
	else if (n < sizeof(long)) {
		// We didn't get the whole word.  This probably will never happen.
		int numToGet = sizeof(numBytesToGet) - n;
		char* ptrToNumBytesToGet = ((char*)&numBytesToGet) + n;
		while (numToGet) {
			// The loop is to ignore EAGAIN and EINTR errors as these are harmless 
			do {
				// set up the file descriptor set
				fd_set read_fds;
				FD_ZERO(&read_fds);
				FD_SET(aSocket, &read_fds);
				
				struct timeval tv;
				tv.tv_sec  = 2;
				tv.tv_usec = 0;
				selectionResult = select(aSocket+1, NULL, &read_fds, NULL, &tv);
			} while (selectionResult == kSelectionError && (errno == EAGAIN || errno == EINTR));
			
			if(selectionResult > 0){
				time_t t1 = time(0);
				do {
					n = recv(aSocket, ptrToNumBytesToGet, numToGet, 0);	
					if(n<0 && (errno == EAGAIN || errno == EINTR)){
						int timeout = [self errorTimeOutSeconds];
						if(timeout>0){
							if((time(0)-t1)>timeout) {
								[self disconnect];
								[NSException raise:@"Socket Disconnected" format:@"%@ Disconnected",IPNumber];
							}
						}
					}
					else break;
				} while (1);
				if(n==0){
					[self disconnect];
					[NSException raise:@"Socket Disconnected" format:@"%@ Disconnected",IPNumber];
				} 
				else if (n<0) {
					[NSException raise:@"Socket Error" format:@"Error <%@>: %s",IPNumber,strerror(errno)];
				} else {
					numToGet -= n;
					ptrToNumBytesToGet += n;    
				}
			}
			else if (selectionResult == kSelectionError){
				[NSException raise:@"Read Error" format:@"Read Error %@ <%@>: %s",[self crateName],IPNumber,strerror(errno)];
			}
			else if (selectionResult == kSelectionTimeout) {
				[NSException raise:@"ConnectionTimeOut" format:@"Read from %@ <%@> port: %d timed out",[self crateName],IPNumber,portNumber];
			}
			
		}
	}
	bytesReceived += sizeof(numBytesToGet);
	numBytesToGet -= sizeof(numBytesToGet);
	
	char* packetPtr = (char*)&aPacket->cmdHeader;
	while(numBytesToGet){
		// The loop is to ignore EAGAIN and EINTR errors as these are harmless 
		do {
			// set up the file descriptor set
			fd_set read_fds;
			FD_ZERO(&read_fds);
			FD_SET(aSocket, &read_fds);
			
			struct timeval tv;
			tv.tv_sec  = 2;
			tv.tv_usec = 0;
			selectionResult = select(aSocket+1, NULL, &read_fds, NULL, &tv);
		} while (selectionResult == kSelectionError && (errno == EAGAIN || errno == EINTR));
		
		if (selectionResult == kSelectionError){
			[NSException raise:@"Read Error" format:@"Read Error %@ <%@>: %s",[self crateName],IPNumber,strerror(errno)];
		}
		else if (selectionResult == kSelectionTimeout) {
			[NSException raise:@"ConnectionTimeOut" format:@"Read from %@ <%@> port: %d timed out",[self crateName],IPNumber,portNumber];
		}
		time_t t1 = time(0);
		do {
			n = recv(aSocket, packetPtr, numBytesToGet, 0);
			if(n<0 && (errno == EAGAIN || errno == EINTR)){
				int timeout = [self errorTimeOutSeconds];
				if(timeout>0){
					if((time(0)-t1)>timeout) {
						[self disconnect];
						[NSException raise:@"Socket Disconnected" format:@"%@ Disconnected",IPNumber];
					}
				}
			}
			else break;
			
		} while (1);
		
		if(n==0){
			[self disconnect];
			[NSException raise:@"Socket Disconnected" format:@"%@ Disconnected",IPNumber];
		} 
		else if (n<0) {
			[NSException raise:@"Socket Error" format:@"Error <%@>: %s",IPNumber,strerror(errno)];
		} 
		else {
			packetPtr += n;
			numBytesToGet -= n;
			bytesReceived += n;
			missedHeartBeat = 0;
		}
 	}
	*/
}

- (BOOL) canWriteTo:(int) sck
{
	fd_set wfds;
	struct timeval tv;
	
	FD_ZERO(&wfds);
	FD_SET(sck, &wfds);
	
	tv.tv_sec = 0;
	tv.tv_usec = 0;
	
	int retval = select(sck + 1, NULL, &wfds, NULL, &tv);
	return (retval > 0) && FD_ISSET(sck, &wfds);
}

- (BOOL) dataAvailable:(int) aSocket
{
	if(!aSocket)return NO;
	
	// set up the file descriptor set
	fd_set fds;
	FD_ZERO(&fds);
	FD_SET(aSocket, &fds);
	
	struct timeval tv;
	tv.tv_sec  = 0;
	tv.tv_usec = 1000;
	
	// wait until timeout or data received
	int  selectionResult = select(aSocket+1, &fds, NULL, NULL, &tv);
	return (selectionResult > 0) && FD_ISSET(aSocket, &fds);
}


@end
