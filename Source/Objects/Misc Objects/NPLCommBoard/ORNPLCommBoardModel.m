//
//  ORNPLCommBoardModel.m
//  Orca
//
//  Created by Mark Howe on Fri Jun 13 2008
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
#import "ORNPLCommBoardModel.h"
#import "NetSocket.h"

NSString* ORNPLCommBoardModelWriteValueChanged		= @"ORNPLCommBoardModelWriteValueChanged";
NSString* ORNPLCommBoardModelFunctionChanged		= @"ORNPLCommBoardModelFunctionChanged";
NSString* ORNPLCommBoardModelChannelChanged			= @"ORNPLCommBoardModelChannelChanged";
NSString* ORNPLCommBoardModelBoardChanged			= @"ORNPLCommBoardModelBoardChanged";
NSString* ORNPLCommBoardModelCmdStringChanged		= @"ORNPLCommBoardModelCmdStringChanged";
NSString* ORNPLCommBoardModelIsConnectedChanged		= @"ORNPLCommBoardModelIsConnectedChanged";
NSString* ORNPLCommBoardModelIpAddressChanged		= @"ORNPLCommBoardModelIpAddressChanged";
NSString* ORNPLCommBoardLock						= @"ORNPLCommBoardLock";

static NSString* NPLComConnectors[8] = {
    @"NPLCom0 Connector", @"NPLCom1 Connector", @"NPLCom2 Connector",
    @"NPLCom3 Connector", @"NPLCom4 Connector", @"NPLCom5 Connector",
    @"NPLCom6 Connector", @"NPLCom7 Connector",
};

@implementation ORNPLCommBoardModel

- (void) makeMainController
{
    [self linkToController:@"ORNPLCommBoardController"];
}

- (void) dealloc
{
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
    [self setImage:[NSImage imageNamed:@"NPLCommBoardIcon"]];
}

- (void) makeConnectors
{
	int conv[8] = {7,5,3,1,6,4,2,0};
    int i;
    for(i=0;i<8;i++){
        ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - (i<4 ? (2*kConnectorSize + 5) : ((2*kConnectorSize + 27))),
																		  [self frame].size.height - 62-(i<4?i:i-4)*11.5) withGuardian:self withObjectLink:self];
        [[self connectors] setObject:aConnector forKey:NPLComConnectors[conv[i]]];
        [aConnector setIdentifer:conv[i]];
		[aConnector setConnectorType: 'NCmO' ];
		[aConnector setIoType:kOutputConnector];
		[aConnector addRestrictedConnectionType: 'NSLV' ]; //can only connect to Slave Boards
        [aConnector release];
    }

}

#pragma mark ***Accessors
- (NSString*) lockName
{
	return ORNPLCommBoardLock;
}

- (int) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(int)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:writeValue];
    
    writeValue = aWriteValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelWriteValueChanged object:self];
}

- (int) functionNumber
{
    return functionNumber;
}

- (void) setFunctionNumber:(int)aFunction
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFunctionNumber:functionNumber];
    
    functionNumber = aFunction;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelFunctionChanged object:self];
}

- (int) channel
{
    return channel;
}

- (void) setChannel:(int)aChannel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChannel:channel];
    
    channel = aChannel;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelChannelChanged object:self];
}

- (int) board
{
    return board;
}

- (void) setBoard:(int)aBoard
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBoard:board];
    
    board = aBoard;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelBoardChanged object:self];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelIsConnectedChanged object:self];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelIpAddressChanged object:self];
}


- (void) connect
{
	if(!isConnected){
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:kNPLCommBoardPort]];	
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
		NSData* theData = [inNetSocket readData];
		char* theBytes = (char*)[theData bytes];
		int i;
		for(i=0;i<[theData length];i++){
			NSLog(@"From NPL HV [%d]: 0x%x\n",i,theBytes[i]);
		}
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
    [self setWriteValue:	[decoder decodeIntForKey:	@"writeValue"]];
    [self setFunctionNumber:[decoder decodeIntForKey:	@"function"]];
    [self setChannel:		[decoder decodeIntForKey:	@"channel"]];
    [self setBoard:			[decoder decodeIntForKey:	@"board"]];
	[self setIpAddress:		[decoder decodeObjectForKey:@"ipAddress"]];
    [[self undoManager] enableUndoRegistration];    
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:writeValue		forKey: @"writeValue"];
    [encoder encodeInt:functionNumber	forKey: @"function"];
    [encoder encodeInt:channel			forKey: @"channel"];
    [encoder encodeInt:board			forKey: @"board"];
    [encoder encodeObject:ipAddress		forKey: @"ipAddress"];
}

- (void) sendB:(int)b s:(int)s f:(int)f controlReg:(int)aReg valueLen:(int)len value:(int)aValue
{
	//send the values from the basic ops
	char bytes[6];
	bytes[0] = 2 + len;
	bytes[1] = ((b & 0xf)<<4) | ((s & 0x3)<<2) | (f & 0x3);
	bytes[2] = aReg;	
	if(len == 3){
		bytes[3] = (writeValue>>16 & 0xf);
		bytes[4] = (writeValue>>8 & 0xf); 
		bytes[5] = writeValue & 0xf; 
	}
	else if(len == 2){
		bytes[3] = (writeValue>>8 & 0xf);
		bytes[4] = (writeValue & 0xf); 
	}
	else if(len == 1){
		bytes[3] = (writeValue & 0xf); 
	}

	int i;
	for(i=0;i<2 + len + 1;i++){
		NSLog(@"%d: 0x%0x\n",i,bytes[i]);
	}

	[socket write:bytes length:2 + len + 1];
	
}

- (void) sendCmd
{	
	//send the values from the basic ops
	char bytes[6];
	bytes[0] = 5;
	bytes[1] = ((board & 0xf)<<4) | ((channel & 0x3)<<2) | (functionNumber & 0x3);
	bytes[2] = 0;
	bytes[3] = (writeValue>>16 & 0xf);
	bytes[4] = (writeValue>>8 & 0xf); 
	bytes[5] = writeValue & 0xf; 
	[socket write:bytes length:6];
}

@end
