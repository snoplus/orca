//
//  ORCARootService.m
//  Orca
//
//  Created by Mark Howe on Thu Nov 06 2003.
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


#import "ORCARootService.h"
#import "NetSocket.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"
#import "ORCARootServiceDefs.h"
#import "SynthesizeSingleton.h"

NSString* ORCARootServicePortChanged			= @"ORCARootServicePortChanged";
NSString* ORCARootServiceTimeConnectedChanged	= @"ORCARootServiceTimeConnectedChanged";
NSString* ORCARootServiceHostNameChanged		= @"ORCARootServiceHostNameChanged";
NSString* ORCARootServiceConnectAtStartChanged	= @"ORCARootServiceConnectAtStartChanged";
NSString* ORCARootServiceAutoReconnectChanged	= @"ORCARootServiceAutoReconnectChanged";
NSString* ORORCARootServiceLock					= @"ORORCARootServiceLock";


@implementation ORCARootService

SYNTHESIZE_SINGLETON_FOR_CLASS(ORCARootService);

- (id) init
{
    self = [super init];
    requestTag = 0;
    [[self undoManager] disableUndoRegistration];
    int port = [[NSUserDefaults standardUserDefaults] integerForKey: @"orca.rootservice.ServiceHostPort"];
    if(port==0)port = kORCARootServicePort;
	[self setAutoReconnect:[[NSUserDefaults standardUserDefaults] integerForKey: @"orca.rootservice.AutoReconnect"]];
	[self setConnectAtStart:[[NSUserDefaults standardUserDefaults] integerForKey: @"orca.rootservice.ConnectAtStartUp"]];
	
	NSString* s = [[NSUserDefaults standardUserDefaults] objectForKey: @"orca.rootservice.ServiceHostName"];
	hostNameIndex = [[NSUserDefaults standardUserDefaults] integerForKey: @"orca.rootservice.HostNameIndex"];
	connectionHistory = [[NSUserDefaults standardUserDefaults] objectForKey: @"orca.rootservice.ServiceHistory"];
	if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];

	if(s){
		if(![connectionHistory containsObject:s])[connectionHistory addObject:s];
	}
	if(![connectionHistory containsObject:kORCARootServiceHost])[connectionHistory addObject:kORCARootServiceHost];
	
	[self setHostName:[connectionHistory objectAtIndex:	hostNameIndex]];
    [self setSocketPort:port];
    [[self undoManager] enableUndoRegistration];
    	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestNotification:) name:ORCARootServiceRequestNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(broadcastConnectionStatus) name:ORCARootServiceBroadcastConnection object:nil];
	if(kORCARootFitNames[0] != nil){} //just to get rid of stupid compiler warning
	if(kORCARootFitShortNames[0] != nil){} //just to get rid of stupid compiler warning
	if(kORCARootFFTNames[0] != nil){} //just to get rid of stupid compiler warning
	if(kORCARootFFTWindowOptions[0] != nil){} //just to get rid of stupid compiler warning
	if(kORCARootFFTWindowNames[0] != nil){} //just to get rid of stupid compiler warning
		
    return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[waitingObjects release];
    [socket release];
	[socket setDelegate:nil];
    [timeConnected release];
    [name release];
	[hostName release];
	[dataBuffer release];
	[connectionHistory release];
    [super dealloc];
}

- (void) connectAtStartUp
{
    if(connectAtStart){
        [self connectSocket:YES];
    }
}
#pragma mark ¥¥¥Accessors
- (NSUndoManager *)undoManager
{
    return [[NSApp delegate] undoManager];
}


- (void) connectSocket:(BOOL)state
{
    if(state){
        [self setSocket:[NetSocket netsocketConnectedToHost:hostName port:socketPort]];
    }
    else {
        [socket close];
        [self setIsConnected:[socket isConnected]];
    }
}

- (NSString*) hostName
{
	return hostName;
}

- (void) setHostName:(NSString*)aName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHostName:hostName];
    [hostName autorelease];
    hostName = [aName copy];    	

	if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
	if(![connectionHistory containsObject:hostName]){
		[connectionHistory addObject:hostName];
	}
	if(aName)hostNameIndex = [connectionHistory indexOfObject:aName];
	else hostNameIndex = 0;

    [[NSUserDefaults standardUserDefaults] setObject:connectionHistory forKey:@"orca.rootservice.ServiceHistory"];
    [[NSUserDefaults standardUserDefaults] setInteger:hostNameIndex forKey:@"orca.rootservice.HostNameIndex"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServiceHostNameChanged object:self userInfo:nil];

}

- (unsigned) hostNameIndex
{
	return hostNameIndex;
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

- (BOOL) isConnected
{
	return isConnected;
}

- (void) setIsConnected:(BOOL)aNewIsConnected
{
	isConnected = aNewIsConnected;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:isConnected] forKey:ORCARootServiceConnectedKey];
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORCARootServiceConnectionChanged 
                          object: self 
						  userInfo:userInfo];

	[self setTimeConnected:isConnected?[NSCalendarDate date]:nil];
}

- (void) clearHistory
{
	[connectionHistory release];
	connectionHistory = nil;

	[self setHostName:kORCARootServiceHost];
	
}

- (void) broadcastConnectionStatus
{
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:isConnected] forKey:ORCARootServiceConnectedKey];
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORCARootServiceConnectionChanged
                      object:self 
					userInfo:userInfo];
}

- (NSArray*) connectionHistory
{
	return connectionHistory;
}

- (unsigned) connectionHistoryCount
{
	return [connectionHistory count];
}

- (id) connectionHistoryItem:(unsigned)index
{
	if(connectionHistory)return [connectionHistory objectAtIndex:index];
	else return nil;
}


- (int) socketPort
{
    return socketPort;
}
- (void) setSocketPort:(int)aPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSocketPort:socketPort];
    
    socketPort = aPort;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServicePortChanged object:self];
    [[NSUserDefaults standardUserDefaults] setInteger:socketPort forKey:@"orca.rootservice.ServiceHostPort"];
}

- (NSString*) name
{
	return name;
}

- (void) setName:(NSString*)newName
{
	[name autorelease];
	name=[newName copy];
}

- (unsigned long)totalSent 
{
    return totalSent;
}

- (void)setTotalSent:(unsigned long)aTotalSent 
{
    totalSent = aTotalSent;
}

- (NSCalendarDate*) timeConnected
{
	return timeConnected;
}

- (void) setTimeConnected:(NSCalendarDate*)newTimeConnected
{
	[timeConnected autorelease];
	timeConnected=[newTimeConnected retain];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServiceTimeConnectedChanged object:self];
}

- (unsigned long)amountInBuffer 
{
    return amountInBuffer;
}

- (void)setAmountInBuffer:(unsigned long)anAmountInBuffer 
{
    amountInBuffer = anAmountInBuffer;
}

- (void)writeData:(NSData*)inData
{
    [socket writeData:inData];
}

- (unsigned long) dataId
{
    return dataId;
}
- (void) setDataId: (unsigned long) aDataId
{
    dataId = aDataId;
}
- (void) setDataIds:(id)assigner
{
    dataId = [assigner reservedDataId:[self className]];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORCARootServiceDecoder",			@"decoder",
        [NSNumber numberWithLong:dataId],   @"dataId",
        [NSNumber numberWithBool:YES],      @"variable",
        [NSNumber numberWithLong:-1],		@"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"ResponsePacket"];
    return dataDictionary;
}

#pragma mark ¥¥¥Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
		NSLog( @"ORCARoot Service: Connection established\n" );		
		[self setName:[socket remoteHost]];

		ORDataPacket* aDataPacket = [[ORDataPacket alloc] init];
		[aDataPacket makeFileHeader];
		ORDataTypeAssigner* assigner = [[ORDataTypeAssigner alloc] init];
		dataId = [assigner reservedDataId:[self className]];
		[assigner release];
   
		[aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORCARootService"];

		NSData* dataHeader = [aDataPacket headerAsData];
		[socket writeData:dataHeader];
		[aDataPacket release];
        [self setIsConnected:[socket isConnected]];
	}
}

- (void)netsocketDisconnected:(NetSocket*)inNetSocket
{	
    if(inNetSocket == socket){
		NSLog(@"ORCARoot Service: %@ disconnected\n",[inNetSocket remoteHost]);
        [self setIsConnected:[socket isConnected]];
		[self setName:@"---"];
        if(autoReconnect)[self performSelector:@selector(reConnect) withObject:nil afterDelay:10];
        [self setIsConnected:NO];
    }

}

- (BOOL) autoReconnect
{
	return autoReconnect;
}

- (void) setAutoReconnect:(BOOL)aAutoReconnect
{
	[[[self undoManager] prepareWithInvocationTarget:self] setAutoReconnect:autoReconnect];
    
	autoReconnect = aAutoReconnect;
    
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORCARootServiceAutoReconnectChanged
                      object:self];
    [[NSUserDefaults standardUserDefaults] setInteger:autoReconnect forKey:@"orca.rootservice.AutoReconnect"];
}

- (BOOL) connectAtStart
{
	return connectAtStart;
}

- (void) setConnectAtStart:(BOOL)aConnectAtStart
{
	[[[self undoManager] prepareWithInvocationTarget:self] setConnectAtStart:connectAtStart];
    
	connectAtStart = aConnectAtStart;
    
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORCARootServiceConnectAtStartChanged
                      object:self];
    [[NSUserDefaults standardUserDefaults] setInteger:connectAtStart forKey:@"orca.rootservice.ConnectAtStartUp"];
}


- (void) reConnect
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reConnect) object:nil];
    [self connectSocket:YES];
}

- (void) netsocketDataInOutgoingBuffer:(NetSocket*)insocket length:(unsigned long)length
{
	if(insocket == socket){
		[self setAmountInBuffer:length];
	}
}

- (void) clearCounts
{
    [self setTotalSent:0];
    [self setAmountInBuffer:0];
}

- (void)netsocketDataSent:(NetSocket*)insocket length:(unsigned long)length
{
	if(insocket == socket){
		[self setTotalSent:[self totalSent]+length];
	}
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
	if(inNetSocket == socket){
		if(dataId==0){
			ORDataTypeAssigner* assigner = [[ORDataTypeAssigner alloc] init];
			dataId = [assigner reservedDataId:[self className]];
			[assigner release];
		}

		if(!dataBuffer)dataBuffer = [[NSMutableData alloc] initWithCapacity:5*1025];
		NSData* data = [inNetSocket readData:inAmount];
		[dataBuffer appendBytes:[data bytes] length:[data length]];
		unsigned long* ptr = (unsigned long*)[dataBuffer bytes];
		unsigned long length = ExtractLength(*ptr);
		unsigned long theID   = ExtractDataId(*ptr);
		if([dataBuffer length]/4 >= length && theID == dataId){
			ptr++;
			NSString* plist = [NSString stringWithCString:(const char *)ptr length:(length-1)*4];
			NSDictionary* theResponse = [NSDictionary dictionaryWithPList:plist];
						
			unsigned long oldLength = [dataBuffer length];
			[dataBuffer replaceBytesInRange:NSMakeRange(0,length*4) withBytes:dataBuffer];
			[dataBuffer setLength:oldLength - length*4];
			
			id aKey = [theResponse objectForKey:@"Request Tag Number"];
			id theRequestingObj = [waitingObjects objectForKey:aKey];
			if([theRequestingObj respondsToSelector:@selector(processResponse:)]){
				[theRequestingObj processResponse:theResponse];
			}
			[waitingObjects removeObjectForKey:aKey];
		}
	}
}

- (void) requestNotification:(NSNotification*)aNote
{
	[self sendRequest:[[aNote userInfo] objectForKey:ServiceRequestKey] fromObject:[aNote object]];
}

- (void) sendRequest:(NSMutableDictionary*)request fromObject:(id)anObject
{
	if(!socket)return;
	
	if(dataId==0){
		ORDataTypeAssigner* assigner = [[ORDataTypeAssigner alloc] init];
		dataId = [assigner reservedDataId:[self className]];
 		[assigner release];
	}
	
	if(!waitingObjects)waitingObjects = [[NSMutableDictionary dictionary] retain];
	requestTag++;
	[request setObject:[NSNumber numberWithInt:requestTag] forKey:@"Request Tag Number"];
	[waitingObjects setObject:anObject forKey:[NSNumber numberWithInt:requestTag]];
	
	NSData* dataBlock = [request asData];
	
	//the request is now in dataBlock
	unsigned long headerLength        = [dataBlock length];											//in bytes
	unsigned long lengthWhenPadded    = sizeof(long)*(round(.5 + headerLength/(float)sizeof(long)));					//in bytes
	unsigned long padSize             = lengthWhenPadded - headerLength;							//in bytes
	unsigned long totalLength		  = 1 + (lengthWhenPadded/4);									//in longs
	unsigned long theHeaderWord = dataId | (0x1ffff & totalLength);										//compose the header word
	NSMutableData* dataToSend = [NSMutableData dataWithBytes:&theHeaderWord length:sizeof(long)];			//add the header word
	
	[dataToSend appendData:dataBlock];
	
	//pad to nearest long word
	unsigned char padByte = 0;
	int i;
	for(i=0;i<padSize;i++){
		[dataToSend appendBytes:&padByte length:1];
	}
	
	[socket writeData:dataToSend];
}

@end