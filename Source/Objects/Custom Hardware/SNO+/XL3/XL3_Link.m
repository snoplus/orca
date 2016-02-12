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
#import "PacketTypes.h"
#import "XL3_Link.h"
#import "ORSafeCircularBuffer.h"

#import <netdb.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <sys/select.h>
#import <sys/errno.h>
#include "anet.h"

#define XL3_SERVER "daq1.sp.snolab.ca"

NSString* XL3_LinkConnectionChanged     = @"XL3_LinkConnectionChanged";
NSString* XL3_LinkTimeConnectedChanged	= @"XL3_LinkTimeConnectedChanged";
NSString* XL3_LinkIPNumberChanged       = @"XL3_LinkIPNumberChanged";
NSString* XL3_LinkConnectStateChanged	= @"XL3_LinkConnectStateChanged";
NSString* XL3_LinkErrorTimeOutChanged	= @"XL3_LinkErrorTimeOutChanged";
NSString* XL3_LinkAutoConnectChanged    = @"XL3_LinkAutoConnectChanged";


#define kCmdArrayHighWater 1000
#define kBundleBufferSize 10000 //PMTMegaBundles


@interface XL3_Link (private)
- (void) allocBufferWithSize:(unsigned) aBufferSize;
- (void) releaseBuffer;
- (BOOL) writeBundle:(char*)someBytes length:(unsigned)numBytes version:(unsigned)aRev packetNum:(unsigned short)packetNum;
- (unsigned) bundleBufferSize;
- (unsigned) bundleReadMark;
- (unsigned) bundleWriteMark;
@end


@implementation XL3_Link
@synthesize fifoTimeStamp = _fifoTimeStamp,
readFifoFlag = _readFifoFlag;

- (id) init
{
	self = [super init];

	commandSocketLock = [[NSLock alloc] init];
	coreSocketLock = [[NSLock alloc] init];
	cmdArrayLock = [[NSLock alloc] init];
	[self setNeedToSwap];
	connectState = kDisconnected;
	cmdArray = [[NSMutableArray alloc] init];
	//bundleBuffer = [[ORSafeCircularBuffer alloc] initWithBufferSize:kBundleBufferSize];
    [self allocBufferWithSize:kBundleBufferSize];
	//[self initConnectionHistory];
	num_cmd_packets = 0;
	num_dat_packets = 0;
	return self;
}

- (void) dealloc
{
	[commandSocketLock release];
	[coreSocketLock release];
	[cmdArrayLock release];
	if(cmdArray){
		[cmdArray release];
		cmdArray = nil;
	}
    if (bundleBuffer) [self releaseBuffer];

    if (fifoStatus) {
        [fifoStatus release];
        fifoStatus = nil;
    }

    if (_fifoTimeStamp) {
        [_fifoTimeStamp release];
        _fifoTimeStamp = nil;
    }

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

- (void) awakeAfterDocumentLoaded
{
    if (autoConnect) [self connectSocket];
}

#pragma mark •••DataTaker Helpers
- (BOOL) bundleAvailable
{
	return bundleReadMark != bundleWriteMark || bundleFreeSpace == 0;
}

- (NSMutableData*) readNextBundle
{
    NSMutableData* theBlock = nil;

    [bundleBufferLock lock];
    if(bundleWriteMark != bundleReadMark || bundleFreeSpace == 0){
        theBlock = (NSMutableData*)(*(dataPtr+bundleReadMark));
        /*
        if (!theBlock) {
            NSLog(@"too bad\n");
        }
        if ([theBlock length] < 16) {
            NSLog(@"even worse\n");
        }
         */
        bundleReadMark = (bundleReadMark + 1) % bundleBufferSize;
        bundleFreeSpace++; 
    }
    [bundleBufferLock unlock];
    return theBlock;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];

	[self setErrorTimeOut: [decoder decodeIntForKey: @"errorTimeOut"]];
    [self setAutoConnect: [decoder decodeBoolForKey: @"autoConnect"]];
	[self setNeedToSwap];

	commandSocketLock = [[NSLock alloc] init];
	coreSocketLock = [[NSLock alloc] init];
	cmdArrayLock = [[NSLock alloc] init];
	cmdArray = [[NSMutableArray alloc] init];
    [self allocBufferWithSize:kBundleBufferSize];
	
	num_cmd_packets = 0;
	num_dat_packets = 0;

	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeInt:[self errorTimeOut] forKey:@"errorTimeOut"];
    [encoder encodeBool:autoConnect forKey:@"autoConnect"];
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
    @synchronized(self) {
        isConnected = aNewIsConnected;
        [[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectionChanged object: self];
        [self setTimeConnected:isConnected?[NSDate date]:nil];
    }
}

- (BOOL) autoConnect
{
	return autoConnect;
}

- (void) setAutoConnect:(BOOL)anAutoConnect
{
	autoConnect = anAutoConnect;
	[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkAutoConnectChanged object: self];
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
	[[[self undoManager] prepareWithInvocationTarget:self] setErrorTimeOut:[self errorTimeOut]];
	_errorTimeOut = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkErrorTimeOutChanged object:self];
}

- (int) errorTimeOut
{
	return _errorTimeOut;
}

- (int) errorTimeOutSeconds
{
	static int translatedTimeOut[4] = {2,5,60,0};
	if([self errorTimeOut] < 0 || [self errorTimeOut] > 3) return 2;
	else return translatedTimeOut[[self errorTimeOut]];
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

- (NSDate*) timeConnected
{
	return timeConnected;
}

- (void) setTimeConnected:(NSDate*)newTimeConnected
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

- (NSArray*) fifoStatus
{
    return fifoStatus; //may return nil
}

- (void) setFifoStatus:(NSArray *)aFifoStatus
{
    if (fifoStatus) [fifoStatus release];
    fifoStatus = [aFifoStatus copy];
    
    if (_fifoTimeStamp) [_fifoTimeStamp release];
    _fifoTimeStamp = [[NSDate alloc] init];
}

- (void) copyFifoStatus:(int32_t*)aStatus
{
    NSNumber* nStatus[17];
    unsigned char i = 0;
    NSMutableArray* fifo = [[NSMutableArray alloc] initWithCapacity:17];
    for (i = 0; i < 17; i++) {
        nStatus[i] = [[NSNumber alloc] initWithInt:aStatus[i]];
        [fifo addObject:nStatus[i]];
    }

    [self setFifoStatus:fifo];
    [fifo release];
    fifo = nil;

    for (i = 0; i < 17; i++) {
        [nStatus[i] release];
        nStatus[i] = nil;
    }

    memcpy(_fifoBundle, aStatus, 17*4);
    [self setReadFifoFlag:YES];
}

- (unsigned long*) fifoBundle
{
    return _fifoBundle;
}

- (void) newMultiCmd
{
	aMultiCmdPacket.header.packetType = MULTI_FAST_CMD_ID;
	aMultiCmdPacket.header.packetNum = (unsigned short) ++num_cmd_packets;
	aMultiCmdPacket.header.numBundles = 0;
	memset(aMultiCmdPacket.payload, 0, XL3_PAYLOAD_SIZE);
}

- (void) addMultiCmdToAddress:(long)anAddress withValue:(long)aValue
{
	MultiCommand* theMultiCommand = (MultiCommand*) aMultiCmdPacket.payload;
	Command* aCommand = &(theMultiCommand->cmd[theMultiCommand->howMany]);

	aCommand->cmdNum = theMultiCommand->howMany;
	aCommand->packetNum = aMultiCmdPacket.header.packetNum;
	aCommand->flags = 0;
	aCommand->address = anAddress;
	aCommand->data = aValue;
	
	theMultiCommand->howMany++;
}

- (XL3Packet*) executeMultiCmd
{
	MultiCommand* theMultiCommand = (MultiCommand*) aMultiCmdPacket.payload;
	if (needToSwap) {
		unsigned int i = 0;
		for (i = 0; i < theMultiCommand->howMany; i++) {
			Command* command = &(theMultiCommand->cmd[i]);
			command->cmdNum = swapLong(command->packetNum);
			command->packetNum = swapShort(command->packetNum);
			command->address = swapLong(command->address);
			command->data = swapLong(command->data);
		}
		theMultiCommand->howMany = swapLong(theMultiCommand->howMany);
		aMultiCmdPacket.header.packetType = swapShort(aMultiCmdPacket.header.packetType);
	}

	@try {
		[self sendXL3Packet:&aMultiCmdPacket];
	}
	@catch (NSException* localException) {
		NSLog(@"%@ MultiCmd failed.\n", [self crateName]);
		//@throw localException;
	}
		
	if (needToSwap) {
		aMultiCmdPacket.header.packetType = swapShort(aMultiCmdPacket.header.packetType);
		theMultiCommand->howMany = swapLong(theMultiCommand->howMany);
		unsigned int i = 0;
		for (i = 0; i < theMultiCommand->howMany; i++) {
			Command* command = &(theMultiCommand->cmd[i]);
			command->cmdNum = swapLong(command->packetNum);
			command->packetNum = swapShort(command->packetNum);
			command->address = swapLong(command->address);
			command->data = swapLong(command->data);
		}
	}
	
	return &aMultiCmdPacket;
}

- (BOOL) multiCmdFailed
{
	BOOL error = NO;
	MultiCommand* theMultiCommand = (MultiCommand*) aMultiCmdPacket.payload;

	unsigned int i = 0;
	for (i = 0; i < theMultiCommand->howMany; i++) {
		Command* command = &theMultiCommand->cmd[i];
		error |= command->flags;
	}
			
	return error;
}

- (void) sendXL3Packet:(XL3Packet*)aPacket
{
	//expects the packet is swapped correctly (both header and payload)
	unsigned char  packetType = aPacket->header.packetType;
	unsigned short packetNum  = aPacket->header.packetNum;
	if (needToSwap) packetNum = swapShort(packetNum);
	
	@try {
		[commandSocketLock lock]; //begin critial section
		[self writePacket:(char*) aPacket];
		[self readXL3Packet:(XL3Packet*)aPacket withPacketType:packetType andPacketNum:packetNum];
		[commandSocketLock unlock]; //end critial section
	}
	@catch (NSException* localException) {
		[commandSocketLock unlock]; //end critial section
		@throw localException;
	}
}

- (void) sendCommand:(uint8_t) aCmd withPayload:(char *) payload expectResponse:(BOOL) askForResponse
{
    //client is responsible for payload swapping, we take care of the header
    XL3Packet aPacket;

    uint16_t packetNum = ++num_cmd_packets;
    aPacket.header.packetNum = htons(packetNum);
    aPacket.header.packetType = aCmd;
    aPacket.header.numBundles = 0;
    memcpy(aPacket.payload, payload, XL3_PAYLOAD_SIZE);
    
    @try {
        [commandSocketLock lock]; //begin critical section
        [self writePacket:(char*) &aPacket];
        [commandSocketLock unlock]; //end critical section
    } @catch (NSException* localException) {
        [commandSocketLock unlock]; //end critical section
        @throw localException;
    }
    if(askForResponse){
        @try {
            [self readXL3Packet:&aPacket withPacketType:aCmd andPacketNum:packetNum];
            memcpy(payload, aPacket.payload, XL3_PAYLOAD_SIZE);
        } @catch (NSException* localException) {
            @throw localException;
        }
    } else {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    }
}


- (void) sendCommand:(uint8_t) aCmd expectResponse:(BOOL) askForResponse
{
	char payload[XL3_PAYLOAD_SIZE];
	@try {
		[self sendCommand:aCmd withPayload:payload expectResponse:askForResponse];
	} @catch (NSException* localException) {
		@throw localException;
		//what about the response?		
	}
}

- (void) sendCommand:(uint8_t) aCmd toAddress:(uint32_t) address withData:(uint32_t *) value
{
	char payload[XL3_PAYLOAD_SIZE];
	Command* command = (Command*) payload;
		
	command->cmdNum = aCmd;
	command->packetNum = 0; // todo: figure out what are these two good for...
	command->flags = 0;
	command->address = (uint32_t) address;
	command->data = *(uint32_t*) value;

	if (needToSwap) {
		command->cmdNum = swapLong(command->packetNum);
		command->packetNum = swapShort(command->packetNum);
		command->address = swapLong(command->address);
		command->data = swapLong(command->data);
	}	

	@try { 
		[self sendCommand:FAST_CMD_ID withPayload:payload expectResponse:YES];
	}
	@catch (NSException* e) {
		NSLog(@"%@ Command error sending command\n", [self crateName]);
		@throw e;
	}
	//return the same packet!
	if (command->flags != 0) {
		NSLog(@"%@ bus error\n", [self crateName]);
		@throw [NSException exceptionWithName:@"Command error.\n" reason:@"XL3 bus error\n" userInfo:nil];
	}	

	*value = command->data;
	if (needToSwap) *value = swapLong(*value);	
}

- (void) readXL3Packet:(XL3Packet*) aPacket withPacketType:(uint8_t) packetType andPacketNum: (uint16_t) packetNum
{
	//look into the cmdArray
    NSDate* sleepDate = [[NSDate alloc] initWithTimeIntervalSinceNow:0.01];
	[NSThread sleepUntilDate:sleepDate];
    [sleepDate release];
    sleepDate = nil;
    
	NSDictionary* aCmd;
	NSMutableArray* foundCmds = [[NSMutableArray alloc] initWithCapacity:1];
	time_t xl3ReadTimer = time(0);
    NSNumber* aPacketType;
    NSNumber* aPacketNum;

    //NSLog(@"%@ waiting for response with packetType: %d and packetNum %d\n",[self crateName], packetType, packetNum);
    
	while(1) {
		@try {
			[cmdArrayLock lock];
			for (aCmd in cmdArray) {
				aPacketType = [aCmd objectForKey:@"packetType"];
				aPacketNum = [aCmd objectForKey:@"packetNum"];
				//NSLog(@"aPacketType: 0x%x, packetType: 0x%x, aPacketNum: 0x%x, packetNum: 0x%x\n",[aPacketType unsignedShortValue],packetType,[aPacketNum unsignedCharValue],packetNum); 

				if ([aPacketType unsignedCharValue] == packetType && [aPacketNum unsignedShortValue] == packetNum) {
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
            [self performSelectorOnMainThread:@selector(disconnectSocket) withObject:nil waitUntilDone:NO];
			@throw [NSException exceptionWithName:@"ReadXL3Packet time out"
				reason:[NSString stringWithFormat:@"Time out for %@ <%@> port: %lu\n", [self crateName], IPNumber, portNumber]
				userInfo:nil];
		}
		else {
            //[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            usleep(500);
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
    @finally {
        [foundCmds release];
        foundCmds = nil;
    }
} 

- (void) connectSocket
{
	if(([IPNumber length]!=0) && (portNumber!=0)){
		@try {
			[NSThread detachNewThreadSelector:@selector(connectToPort) toTarget:self withObject:nil];
		}
		@catch (NSException* localException) {
			NSLog(@"Socket creation failed for %@ on port %d\n", [self crateName], portNumber);
			[self setIsConnected: NO];
			[self setTimeConnected:nil];
			
			@throw localException;
		}
	}
	else {
        NSLog(@"connectSocket: XL3_Link failed to call connect for IP %@ and port %d\n", IPNumber, portNumber);
	}
}

- (void) disconnectSocket
{
	if(workingSocket){
		close(workingSocket);
		workingSocket = 0;
	}
		
	[self setIsConnected: NO];
	[self setTimeConnected:nil];
	NSLog(@"Disconnected %@ <%@> port: %d\n", [self crateName], IPNumber, portNumber);
}

static void SwapLongBlock(void* p, int32_t n)
{
    int32_t* lp = (int32_t*)p;
    int32_t i;
    for(i=0;i<n;i++){
        int32_t x = *lp;
        *lp =  (((x) & 0x000000FF) << 24) |    
        (((x) & 0x0000FF00) <<  8) |    
        (((x) & 0x00FF0000) >>  8) |    
        (((x) & 0xFF000000) >> 24);
        lp++;
    }
}

- (void) connectToPort
{
    char err[ANET_ERR_LEN];

	NSAutoreleasePool *pool = [[NSAutoreleasePool allocWithZone:nil] init];

    connectState = kWaiting;
    [[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];

    workingSocket = 0;
    if ((workingSocket = anetTcpConnect(err, XL3_SERVER, portNumber)) == ANET_ERR) {
        if (workingSocket) {
            close(workingSocket);
            workingSocket = 0;
        }

        connectState = kDisconnected;
        [[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];

        [self setIsConnected:NO];

        [NSThread sleepForTimeInterval:10.0];
    } else {
        [self setIsConnected:YES];
    }
	
    if ([self isConnected]) {
        connectState = kConnected;
        [[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];
        NSLog(@"%@ connected on local port %d\n",[self crateName], [self portNumber]);
    }

	fd_set fds;
	int selectionResult = 0;
	struct timeval tv;
	tv.tv_sec  = 0;
	tv.tv_usec = 2000;

	char aPacket[XL3_PACKET_SIZE];
	unsigned long bundle_count = 0;

	time_t t0 = time(0);
    BOOL go = [self isConnected];
    
	while(go) { //yes, this is correct
		if (!workingSocket) {
			NSLog(@"%@ not connected <%@> port: %d\n", [self crateName], IPNumber, portNumber);
			break;
		}
				
		FD_ZERO(&fds);
		FD_SET(workingSocket, &fds);
		selectionResult = select(workingSocket + 1, &fds, NULL, NULL, &tv);
		if (selectionResult == -1 && !(errno == EAGAIN || errno == EINTR)) {
            usleep(500);
			//[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.005]];
            
			if (workingSocket) {
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
				if (workingSocket) {
					NSLog(@"Couldn't read from XL3 <%@> port:%d\n", IPNumber, portNumber);
				}
				break;
			}

            //reset the timer
            t0 = time(0);
            
            //NSLog(@"Read packet:  packetType: 0x%x, packetNum: 0x%x\n", ((XL3Packet*) aPacket)->header.packetType, ((XL3Packet*) aPacket)->header.packetNum);

            if (((XL3Packet*) aPacket)->header.packetType == MEGA_BUNDLE_ID) {
                //packetNum?
                unsigned short packetNum = ((XL3Packet*) aPacket)->header.packetNum;
                if (needToSwap) packetNum = swapShort(packetNum);
                if (((XL3Packet*) aPacket)->header.numBundles != 0) {
                    [self writeBundle:((XL3Packet*) aPacket)->payload length:((XL3Packet*) aPacket)->header.numBundles * 12 version:0 packetNum:packetNum];
                }
                else {
                    unsigned int num_bytes = *(unsigned int*)(((XL3Packet*)aPacket)->payload);
                    if (needToSwap) num_bytes = swapLong(num_bytes);
                    num_bytes &= 0xffffff;
                    if (num_bytes == 0) {
                        NSLog(@"%@ megabundle with zero length ignored\n", [self crateName]);
                    }
                    num_bytes = (num_bytes + 3) * 4;
                    if (num_bytes > XL3_PAYLOAD_SIZE) {
                        num_bytes = XL3_PAYLOAD_SIZE;
                    }
                    [self writeBundle:((XL3Packet*) aPacket)->payload length:num_bytes version:1 packetNum:packetNum];
                }
                bundle_count++;
            }
            else if (((XL3Packet*) aPacket)->header.packetType == PING_ID) {
                //NSLog(@"%@: received ping request\n", [self crateName]);
                (((XL3Packet*) aPacket)->header.packetType = PONG_ID);
                //get data
                if (needToSwap) SwapLongBlock(((XL3Packet*) aPacket)->payload, 17);
                [self copyFifoStatus:(int32_t*)((XL3Packet*) aPacket)->payload];
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

            else if (((XL3Packet*) aPacket)->header.packetType == MESSAGE_ID) {
                ((XL3Packet*) aPacket)->payload[XL3_PAYLOAD_SIZE-1] = '\0';
                NSString* msg = [NSString stringWithFormat:@"%s", ((XL3Packet*) aPacket)->payload]; //odd encoding
                msg = [msg stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                NSLog(@"%@ message:\n%@\n", [self crateName], [[msg retain] autorelease]);
            }

            else if (((XL3Packet*) aPacket)->header.packetType == ERROR_ID) {
                NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ error packet received:\n", [self crateName]];
                int error;
                ErrorPacket* data = (ErrorPacket*)((XL3Packet*)aPacket)->payload;
                if (needToSwap) SwapLongBlock(data, sizeof(ErrorPacket)/4);

                error = data->cmdRejected;
                if (error) [msg appendFormat:@"cmd_in_rejected: 0x%x, ", error];
                error = data->transferError;
                if (error) [msg appendFormat:@"transfer_error: 0x%x, ", error];
                error = data->xl3DataAvailUnknown;
                if (error) [msg appendFormat:@"xl3_davail_unknown: 0x%x, ", error];
                unsigned int slot;
                for (slot=0; slot<16; slot++) {
                    error = data->fecBundleReadError[slot];
                    if (error) [msg appendFormat:@"bundle_read_error slot %2d: 0x%x, ", slot, error];
                }
                for (slot=0; slot<16; slot++) {
                    error = data->fecBundleResyncError[slot];
                    if (error) [msg appendFormat:@"bundle_resync_error slot %2d: 0x%x, ", slot, error];
                }
                for (slot=0; slot< 16; slot++) {
                    error = data->fecMemLevelUnknown[slot];
                    if (error) [msg appendFormat:@"mem_level_unknown slot %2d: 0x%x, ", slot, error];
                }
                [msg appendFormat:@"\n"];
                NSLog(msg);
            }

            else if (((XL3Packet*) aPacket)->header.packetType == SCREWED_ID) {
                NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ screwed for slot:\n", [self crateName]];
                unsigned i, error;
                for (i = 0; i < 16; i++) {
                    error = ((ScrewedPacket*) ((XL3Packet *) aPacket)->payload)->fecScrewed[i];
                    if (needToSwap) error = swapLong(error);
                    [msg appendFormat:@"%2d: 0x%x\n", i, error];
                }
                NSLog(msg);
            }

            else {	//cmd response
                unsigned short packetNum = ((XL3Packet*) aPacket)->header.packetNum;
                unsigned short packetType = ((XL3Packet*) aPacket)->header.packetType;
                
                if (needToSwap) packetNum = swapShort(packetNum);
                //NSLog(@"%@ packet type: %d and packetNum: %d, xl3 megabundle count: %d, NSNumber value: %dß\n", [self crateName], packetType, packetNum, bundle_count, [[NSNumber numberWithUnsignedShort:packetType] unsignedShortValue]);
                                
                NSData* packetData = [[NSData alloc] initWithBytes:aPacket length:XL3_PACKET_SIZE];
                NSNumber* packetNNum = [[NSNumber alloc] initWithUnsignedShort:packetNum];
                NSNumber* packetNType = [[NSNumber alloc] initWithUnsignedChar:packetType];
                NSDate* packetDate = [[NSDate alloc] init];
                NSDictionary* aDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                             packetNNum, @"packetNum",
                                             packetNType, @"packetType",
                                             packetDate, @"date",
                                             packetData, @"xl3Packet",
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

                [aDictionary release];
                aDictionary = nil;
                [packetData release];
                packetData = nil;
                [packetNNum release];
                packetNNum = nil;
                [packetNType release];
                packetNType = nil;
                [packetDate release];
                packetDate = nil;

                //NSLog(@"%@: cmdArray includes %d cmd responses\n", [self crateName], [cmdArray count]);
                
                if ([cmdArray count] > kCmdArrayHighWater) {
                    //todo: post alarm
                    NSLog(@"%@ command array close to full.\n", [self crateName]);
                }
            }
        } //select
    } //while

	if (workingSocket) {
        close(workingSocket);
        workingSocket = 0;
	
		NSLog(@"%@ disconnected from local port %d\n", [self crateName], [self portNumber]);
		connectState = kDisconnected;
		[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];
		[self setIsConnected:NO];
	}

	[pool release];

    if ([self autoConnect]) {
        [self performSelectorOnMainThread:@selector(connectSocket) withObject:nil waitUntilDone:NO];
    }
}


- (void) writePacket:(char*)aPacket
{
	//this is private method called from this object only, we lock the socket, and expect that thread lock is provided at a higher level
	if (!workingSocket) {
		[NSException raise:@"Write error" format:@"XL3 not connected %@ <%@> port: %lu",[self crateName], IPNumber, portNumber];
	}

    //NSLog(@"Write packet: packetType: 0x%x, packetNum: 0x%x\n", ((XL3Packet*) aPacket)->header.packetType, ((XL3Packet*) aPacket)->header.packetNum);
    
	int bytesWritten;
	int selectionResult = 0;
	int numBytesToSend = XL3_PACKET_SIZE;
	fd_set write_fds;

	struct timeval tv;
	tv.tv_sec  = [self errorTimeOutSeconds];
	tv.tv_usec = 2000;
	
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
                    [self performSelector:@selector(disconnectSocket) withObject:nil afterDelay:0];
			}
			else if (selectionResult == 0 || ([self errorTimeOutSeconds] && time(0) - t1 > [self errorTimeOutSeconds])) {
				[NSException raise:@"Connection time out" format:@"Write to %@ <%@> port: %lu timed out",[self crateName], IPNumber, portNumber];
                [self performSelector:@selector(disconnectSocket) withObject:nil afterDelay:0];
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
                    [self performSelector:@selector(disconnectSocket) withObject:nil afterDelay:0];
					//what do we want to do?
                    //not really used, SIGPIPE instead
				}
				[NSException raise:@"Write error" format:@"Write error(%s) %@ <%@> port: %lu",strerror(errno),[self crateName],IPNumber,portNumber];
			}
		}
        [coreSocketLock unlock];
	}
	@catch (NSException* localException) {
		[coreSocketLock unlock];
		if (workingSocket) {
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
	tv.tv_usec = 2000;
	memset(aPacket, 0, XL3_PACKET_SIZE);
	
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
			//numBytesToGet = 0;
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


@implementation XL3_Link (private)


- (void) allocBufferWithSize:(unsigned) aBufferSize;
{
	bundleBufferSize = aBufferSize;
	bundleBuffer	 = [[NSMutableData alloc] initWithLength:bundleBufferSize * sizeof(long)];
	[bundleBuffer setLength:bundleBufferSize * sizeof(long)];
	bundleBufferLock = [[NSLock alloc] init];
	bundleFreeSpace	 = bundleBufferSize;
	bundleReadMark	 = 0;
	bundleWriteMark	 = 0;
	dataPtr			 = (unsigned long*)[bundleBuffer mutableBytes];
}

- (void) releaseBuffer
{
	[bundleBuffer release]; bundleBuffer = nil;
    [bundleBufferLock release];
}

- (unsigned) bundleBufferSize
{
	return bundleBufferSize;
}

- (unsigned) bundleReadMark
{
	return bundleReadMark;
}

- (unsigned) bundleWriteMark
{
	return bundleWriteMark;
}

- (BOOL) writeBundle:(char*)someBytes length:(unsigned)numBytes version:(unsigned)aRev packetNum:(unsigned short)packetNum
{
    [bundleBufferLock lock];
    BOOL full = NO;
    if(bundleFreeSpace > 0){
        NSMutableData* theData = [[NSMutableData alloc] initWithLength:numBytes + 8];
        unsigned int rev = aRev << 5;
        rev |= packetNum << 16;
        [theData replaceBytesInRange:NSMakeRange(4, 4) withBytes:&rev length:4];
        [theData replaceBytesInRange:NSMakeRange(8, numBytes) withBytes:someBytes length:numBytes];
        *(dataPtr+bundleWriteMark) = (unsigned long)theData;
        bundleWriteMark = (bundleWriteMark+1)%bundleBufferSize;	//move the write mark ahead 
        bundleFreeSpace--; 
    }
    else full = YES;
    [bundleBufferLock unlock];
    return full;
}

@end
