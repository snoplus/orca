//
//  ORLabJackUE9Model.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 11,2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
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
#import "ORLabJackUE9Model.h"
#import "NSNotifications+Extensions.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "NetSocket.h"

@implementation ORLabJackUE9Cmd

@synthesize cmdData, tag;

- (void) dealloc
{
	self.cmdData = nil;
	[super dealloc];
}
@end


NSString* ORLabJackUE9IsConnectedChanged			= @"ORLabJackUE9IsConnectedChanged";
NSString* ORLabJackUE9IpAddressChanged				= @"ORLabJackUE9IpAddressChanged";
NSString* ORLabJackUE9ModelDeviceSerialNumberChanged = @"ORLabJackUE9ModelDeviceSerialNumberChanged";
NSString* ORLabJackUE9ModelInvolvedInProcessChanged = @"ORLabJackUE9ModelInvolvedInProcessChanged";
NSString* ORLabJackUE9ModelAOut1Changed				= @"ORLabJackUE9ModelAOut1Changed";
NSString* ORLabJackUE9ModelAOut0Changed				= @"ORLabJackUE9ModelAOut0Changed";
NSString* ORLabJackUE9ShipDataChanged				= @"ORLabJackUE9ShipDataChanged";
NSString* ORLabJackUE9DigitalOutputEnabledChanged	= @"ORLabJackUE9DigitalOutputEnabledChanged";
NSString* ORLabJackUE9CounterChanged				= @"ORLabJackUE9CounterChanged";
NSString* ORLabJackUE9SerialNumberChanged			= @"ORLabJackUE9SerialNumberChanged";
NSString* ORLabJackUE9Lock							= @"ORLabJackUE9Lock";
NSString* ORLabJackUE9ChannelNameChanged			= @"ORLabJackUE9ChannelNameChanged";
NSString* ORLabJackUE9ChannelUnitChanged			= @"ORLabJackUE9ChannelUnitChanged";
NSString* ORLabJackUE9AdcChanged					= @"ORLabJackUE9AdcChanged";
NSString* ORLabJackUE9GainChanged					= @"ORLabJackUE9GainChanged";
NSString* ORLabJackUE9DoNameChanged					= @"ORLabJackUE9DoNameChanged";
NSString* ORLabJackUE9IoNameChanged					= @"ORLabJackUE9IoNameChanged";
NSString* ORLabJackUE9DoDirectionChanged			= @"ORLabJackUE9DoDirectionChanged";
NSString* ORLabJackUE9IoDirectionChanged			= @"ORLabJackUE9IoDirectionChanged";
NSString* ORLabJackUE9DoValueOutChanged				= @"ORLabJackUE9DoValueOutChanged";
NSString* ORLabJackUE9IoValueOutChanged				= @"ORLabJackUE9IoValueOutChanged";
NSString* ORLabJackUE9DoValueInChanged				= @"ORLabJackUE9DoValueInChanged";
NSString* ORLabJackUE9IoValueInChanged				= @"ORLabJackUE9IoValueInChanged";
NSString* ORLabJackUE9PollTimeChanged				= @"ORLabJackUE9PollTimeChanged";
NSString* ORLabJackUE9HiLimitChanged				= @"ORLabJackUE9HiLimitChanged";
NSString* ORLabJackUE9LowLimitChanged				= @"ORLabJackUE9LowLimitChanged";
NSString* ORLabJackUE9AdcDiffChanged				= @"ORLabJackUE9AdcDiffChanged";
NSString* ORLabJackUE9SlopeChanged					= @"ORLabJackUE9SlopeChanged";
NSString* ORLabJackUE9InterceptChanged				= @"ORLabJackUE9InterceptChanged";
NSString* ORLabJackUE9MinValueChanged				= @"ORLabJackUE9MinValueChanged";
NSString* ORLabJackUE9MaxValueChanged				= @"ORLabJackUE9MaxValueChanged";

#define kUE9Idle		0
#define kUE9ComCmd		1
#define kUE9CalBlock	2
#define kUE9SingleIO	3
#define kUE9FeedBack	4

#define kUE9DigitalBitRead	0x0
#define kUE9DigitalBitWrite	0x1
#define DigitalPortRead		0x2
#define DigitalPortWrite	0x3
#define kUE9AnalogIn		0x4
#define kUE9AnalogOut		0x5

@interface ORLabJackUE9Model (private)
- (void) pollHardware;
- (void) sendIoControl;
- (void) readAdcValues;
- (void) normalChecksum:(unsigned char*)b len:(int)n;
- (void) extendedChecksum:(unsigned char*)b len:(int)n;
- (unsigned char) normalChecksum8:(unsigned char*)b len:(int)n;
- (unsigned short) extendedChecksum16:(unsigned char*)b len:(int) n;
- (unsigned char) extendedChecksum8:(unsigned char*) b;
- (double) bufferToDouble:(unsigned char*)buffer index:(int) startIndex;

- (void) timeout;
- (void) decodeComCmd:(NSData*) theData;
- (void) decodeCalibData:(NSData*)theData;
- (void) decodeSingleAdcRead:(NSData*) theData;
- (void) decodeFeedBack:(NSData*) theData;
- (long) convert:(unsigned long)rawAdc gainBip:(unsigned short)bipGain result:(double*)voltage;
- (long) convert:(double) analogVoltage chan:(int) DACNumber result:(unsigned short*)rawDacValue;
@end

#define kLabJackUE9DataSize 17

@implementation ORLabJackUE9Model
- (id)init
{
	self = [super init];
	int i;
	for(i=0;i<8;i++){
		lowLimit[i] = -10;
		hiLimit[i]  = 10;
		minValue[i] = -10;
		maxValue[i]  = 10;
		//default to range from -10 to +10 over adc range of 0 to 4095
		slope[i] = 20./4095.;
		intercept[i] = -10;
	}
		
	return self;	
}

- (void) dealloc 
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	int i;
	for(i=0;i<8;i++)	[channelName[i] release];
	for(i=0;i<8;i++)	[channelUnit[i] release];
	for(i=0;i<16;i++)	[ioName[i] release];
	for(i=0;i<4;i++)	[doName[i] release];
    [serialNumber release];
	[cmdQueue release];
	[lastRequest release];
	[super dealloc];
}


- (void) makeMainController
{
    [self linkToController:@"ORLabJackUE9Controller"];
}

-(void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"LabJackUE9"]];
}

- (NSString*) title 
{
	return [NSString stringWithFormat:@"LabJackUE9"];
}


#pragma mark ***Accessors
- (ORLabJackUE9Cmd*) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(ORLabJackUE9Cmd*)aRequest
{
	[aRequest retain];
	[lastRequest release];
	lastRequest = aRequest;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9IsConnectedChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9IpAddressChanged object:self];
}


- (void) connect
{
	if(!isConnected){
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:52360]];	
	}
	else {
		//[self stop];
		[self setSocket:nil];	
        [self setIsConnected:[socket isConnected]];
	}
}

- (BOOL) isConnected
{
	return isConnected;
}
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
		[self getCalibrationInfo:0];
		[self getCalibrationInfo:1];
		[self getCalibrationInfo:2];
		[self getCalibrationInfo:3];
		[self getCalibrationInfo:4];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
    if(inNetSocket == socket){
		NSData* theData = [inNetSocket readData];
		switch(lastRequest.tag){
			case kUE9ComCmd: 
				[self decodeComCmd:theData]; 
			break;
				
			case kUE9CalBlock: 
				[self decodeCalibData:theData]; 
			break;
				
			case kUE9SingleIO:
				[self decodeSingleAdcRead:theData]; 
			break;
				
			case kUE9FeedBack:
				[self decodeFeedBack:theData]; 
			break;
		}
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
		[self setLastRequest:nil];			 //clear the last request
		[self processOneCommandFromQueue];	 //do the next command in the queu
	}
}

- (void) goToNextCommand
{
	[self setLastRequest:nil];			 //clear the last request
	[self processOneCommandFromQueue];	 //do the next command in the queue
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
		
		[self setIsConnected:NO];
		[socket autorelease];
		socket = nil;
    }
}

- (unsigned long) deviceSerialNumber
{
    return deviceSerialNumber;
}

- (void) setDeviceSerialNumber:(unsigned long)aDeviceSerialNumber
{
    deviceSerialNumber = aDeviceSerialNumber;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelDeviceSerialNumberChanged object:self];
}

- (BOOL) involvedInProcess
{
    return involvedInProcess;
}

- (void) setInvolvedInProcess:(BOOL)aInvolvedInProcess
{
    involvedInProcess = aInvolvedInProcess;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelInvolvedInProcessChanged object:self];
}

- (unsigned short) aOut1
{
    return aOut1;
}

- (void) setAOut1:(unsigned short)aValue
{
	if(aValue>1023)aValue=1023;
    [[[self undoManager] prepareWithInvocationTarget:self] setAOut1:aOut1];
    aOut1 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelAOut1Changed object:self];
}

- (void) setAOut0Voltage:(float)aValue
{
	[self setAOut0:aValue*255./5.1];
}

- (void) setAOut1Voltage:(float)aValue
{
	[self setAOut1:aValue*255./5.1];
}
		 
- (unsigned short) aOut0
{
    return aOut0;
}

- (void) setAOut0:(unsigned short)aValue
{
	if(aValue>1023)aValue=1023;
    [[[self undoManager] prepareWithInvocationTarget:self] setAOut0:aOut0];
    aOut0 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelAOut0Changed object:self];
}

- (float) slope:(int)i
{
	if(i>=0 && i<8)return slope[i];
	else return 20./4095.;
}

- (void) setSlope:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setSlope:i withValue:slope[i]];
		
		slope[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9SlopeChanged object:self userInfo:userInfo];
		
	}
}

- (float) intercept:(int)i
{
	if(i>=0 && i<8)return intercept[i];
	else return -10;
}

- (void) setIntercept:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setIntercept:i withValue:intercept[i]];
		
		intercept[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9InterceptChanged object:self userInfo:userInfo];
		
	}
}

- (float) lowLimit:(int)i
{
	if(i>=0 && i<8)return lowLimit[i];
	else return 0;
}

- (void) setLowLimit:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:i withValue:lowLimit[i]];
		
		lowLimit[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9LowLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) hiLimit:(int)i
{
	if(i>=0 && i<8)return hiLimit[i];
	else return 0;
}

- (void) setHiLimit:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setHiLimit:i withValue:lowLimit[i]];
		
		hiLimit[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9HiLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) minValue:(int)i
{
	if(i>=0 && i<8)return minValue[i];
	else return 0;
}

- (void) setMinValue:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setMinValue:i withValue:minValue[i]];
		
		minValue[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9MinValueChanged object:self userInfo:userInfo];
		
	}
}
- (float) maxValue:(int)i
{
	if(i>=0 && i<8)return maxValue[i];
	else return 0;
}

- (void) setMaxValue:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setMaxValue:i withValue:maxValue[i]];
		
		maxValue[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9MaxValueChanged object:self userInfo:userInfo];
		
	}
}


- (BOOL) shipData
{
    return shipData;
}

- (void) setShipData:(BOOL)aShipData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipData:shipData];
    shipData = aShipData;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ShipDataChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
	[self pollHardware];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9PollTimeChanged object:self];
}

- (BOOL) digitalOutputEnabled
{
    return digitalOutputEnabled;
}

- (void) setDigitalOutputEnabled:(BOOL)aDigitalOutputEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDigitalOutputEnabled:digitalOutputEnabled];
    digitalOutputEnabled = aDigitalOutputEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9DigitalOutputEnabledChanged object:self];
}

- (unsigned long) counter
{
    return counter;
}

- (void) setCounter:(unsigned long)aCounter
{
    counter = aCounter;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9CounterChanged object:self];
}

- (NSString*) channelName:(int)i
{
	if(i>=0 && i<8){
		if([channelName[i] length])return channelName[i];
		else return [NSString stringWithFormat:@"Chan %d",i];
	}
	else return @"";
}

- (void) setChannel:(int)i name:(NSString*)aName
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:i name:channelName[i]];
		
		[channelName[i] autorelease];
		channelName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ChannelNameChanged object:self userInfo:userInfo];
		
	}
}

- (NSString*) channelUnit:(int)i
{
	if(i>=0 && i<8){
		if([channelUnit[i] length])return channelUnit[i];
		else return @"V";
	}
	else return @"";
}

- (void) setChannel:(int)i unit:(NSString*)aName
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:i unit:channelUnit[i]];
		
		[channelUnit[i] autorelease];
		channelUnit[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ChannelUnitChanged object:self userInfo:userInfo];
		
	}
}



- (NSString*) ioName:(int)i
{
	if(i>=0 && i<4){
		if([ioName[i] length])return ioName[i];
		else return [NSString stringWithFormat:@"IO%d",i];
	}
	else return @"";
}

- (void) setIo:(int)i name:(NSString*)aName
{
	if(i>=0 && i<4){
		[[[self undoManager] prepareWithInvocationTarget:self] setIo:i name:ioName[i]];
		
		[ioName[i] autorelease];
		ioName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9IoNameChanged object:self userInfo:userInfo];
		
	}
}

- (NSString*) doName:(int)i
{
	if(i>=0 && i<16){
		if([doName[i] length])return doName[i];
		else return [NSString stringWithFormat:@"DO%d",i];
	}
	else return @"";
}

- (void) setDo:(int)i name:(NSString*)aName
{
	if(i>=0 && i<16){
		[[[self undoManager] prepareWithInvocationTarget:self] setDo:i name:doName[i]];
		
		[doName[i] autorelease];
		doName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9DoNameChanged object:self userInfo:userInfo];
		
	}
}

- (int) adc:(int)i
{
	unsigned short result = 0;
	@synchronized(self){
		if(i>=0 && i<8){
			result =  adc[i];
		}
	}
	return result;
}

- (void) setAdc:(int)i withValue:(int)aValue
{
	@synchronized(self){
		if(i>=0 && i<8){
			adc[i] = aValue; 
			
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9AdcChanged object:self userInfo:userInfo];
		}	
	}
}
- (int) gain:(int)i
{
	unsigned short result = 0;
	@synchronized(self){
		if(i>=0 && i<4){
			result =  gain[i];
		}
	}
	return result;
}

- (void) setGain:(int)i withValue:(int)aValue
{
	@synchronized(self){
		if(i>=0 && i<4){
			[[[self undoManager] prepareWithInvocationTarget:self] setGain:i withValue:gain[i]];
			gain[i] = aValue; 
			
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9GainChanged object:self userInfo:userInfo];
		}	
	}
}

- (unsigned short) adcDiff
{
	return adcDiff;
}

- (void) setAdcDiff:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcDiff:adcDiff];
    adcDiff = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9AdcDiffChanged object:self];
	
}

- (void) setAdcDiffBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = adcDiff;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setAdcDiff:aMask];
}

- (unsigned short) doDirection
{
    return doDirection;
}

- (void) setDoDirection:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoDirection:doDirection];
    doDirection = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9DoDirectionChanged object:self];
}


- (void) setDoDirectionBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = doDirection;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setDoDirection:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (unsigned short) ioDirection
{
    return ioDirection;
}

- (void) setIoDirection:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIoDirection:ioDirection];
    ioDirection = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9IoDirectionChanged object:self];
}

- (void) setIoDirectionBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = ioDirection;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setIoDirection:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}


- (unsigned short) doValueOut
{
    return doValueOut;
}

- (void) setDoValueOut:(unsigned short)aMask
{
	@synchronized(self){
		[[[self undoManager] prepareWithInvocationTarget:self] setDoValueOut:doValueOut];
		doValueOut = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9DoValueOutChanged object:self];
	}
}

- (void) setDoValueOutBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = doValueOut;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setDoValueOut:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (unsigned short) ioValueOut
{
    return ioValueOut;
}

- (void) setIoValueOut:(unsigned short)aMask
{
	@synchronized(self){
		[[[self undoManager] prepareWithInvocationTarget:self] setIoValueOut:ioValueOut];
		ioValueOut = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9IoValueOutChanged object:self];
	}
}

- (void) setIoValueOutBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = ioValueOut;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setIoValueOut:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (unsigned short) ioValueIn
{
    return ioValueIn;
}

- (void) setIoValueIn:(unsigned short)aMask
{
	@synchronized(self){
		ioValueIn = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9IoValueInChanged object:self];
	}
}

- (void) setIoValueInBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = ioValueIn;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setIoValueIn:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (NSString*) ioInString:(int)i
{
	if(ioDirection & (1L<<i) ) return (ioValueIn & 1L<<i) ? @"Hi":@"Lo";
	else						 return @"";
}

- (NSColor*) ioInColor:(int)i
{
	if(ioDirection & (1L<<i) ) return (ioValueIn & 1L<<i) ? 
		[NSColor colorWithCalibratedRed:0 green:.8 blue:0 alpha:1.0] :
		[NSColor colorWithCalibratedRed:.8 green:0 blue:0 alpha:1.0];
	else						 return [NSColor blackColor];
}

- (NSColor*) doInColor:(int)i
{
	if(doDirection & (1L<<i) ) return (doValueIn & 1L<<i) ? 
		[NSColor colorWithCalibratedRed:0 green:.8 blue:0 alpha:1.0] :
		[NSColor colorWithCalibratedRed:.8 green:0 blue:0 alpha:1.0];
	else						 return [NSColor blackColor];
}

- (unsigned short) doValueIn
{
    return doValueIn;
}

- (void) setDoValueIn:(unsigned short)aMask
{
	@synchronized(self){
		doValueIn = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9DoValueInChanged object:self];
	}
}

- (void) setDoValueInBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = doValueIn;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setDoValueIn:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (NSString*) doInString:(int)i
{
	if(doDirection & (1L<<i) ) return (doValueIn & 1L<<i) ? @"Hi":@"Lo";
	else						 return @"";
}

- (NSString*) serialNumber
{
    return serialNumber;
}

- (void) setSerialNumber:(NSString*)aSerialNumber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerialNumber:serialNumber];
    
    [serialNumber autorelease];
    serialNumber = [aSerialNumber copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9SerialNumberChanged object:self];
}

- (void) resetCounter
{
	doResetOfCounter = YES;
	[self sendIoControl];
}

#pragma mark ***HW Access


#pragma mark ***Data Records
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId   = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anOtherDevice
{
    [self setDataId:[anOtherDevice dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"LabJackUE9"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORLabJackUE9DecoderForIOData",@"decoder",
								 [NSNumber numberWithLong:dataId],   @"dataId",
								 [NSNumber numberWithBool:NO],       @"variable",
								 [NSNumber numberWithLong:kLabJackUE9DataSize],       @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Temperatures"];
    
    return dataDictionary;
}

- (unsigned long) timeMeasured
{
	return timeMeasured;
}


- (void) shipIOData
{
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		unsigned long data[kLabJackUE9DataSize];
		data[0] = dataId | kLabJackUE9DataSize;
		data[1] = ((adcDiff & 0xf) << 16) | ([self uniqueIdNumber] & 0x0000fffff);
		
		union {
			float asFloat;
			unsigned long asLong;
		} theData;
		
		int index = 2;
		int i;
		for(i=0;i<8;i++){
			theData.asFloat = [self convertedValue:i];
			data[index] = theData.asLong;
			index++;
		}
		data[index++] = counter;
		data[index++] = ((ioDirection & 0xF) << 16) | (doDirection & 0xFFFF);
		data[index++] = ((ioValueOut  & 0xF) << 16) | (doValueOut & 0xFFFF);
		data[index++] = ((ioValueIn   & 0xF) << 16) | (doValueIn & 0xFFFF);
	
		data[index++] = timeMeasured;
		data[index++] = 0; //spares
		data[index++] = 0;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(long)*kLabJackUE9DataSize]];
	}
}
#pragma mark •••Bit Processing Protocol
- (void) processIsStarting
{
	//we will control the polling loop
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
    readOnce = NO;
	[self setInvolvedInProcess:YES];
}

- (void) processIsStopping
{
	//return control to the normal loop
	[self setPollTime:pollTime];
	[self setInvolvedInProcess:NO];
}

//note that everything called by these routines MUST be threadsafe
- (void) startProcessCycle
{
    if(!readOnce){
        @try { 
            [self queryAll]; 
            if(shipData){
                [self shipIOData]; 
            }
            readOnce = YES;
        }
		@catch(NSException* localException) { 
			//catch this here to prevent it from falling thru, but nothing to do.
        }
		
		//grab the bit pattern at the start of the cycle. it
		//will not be changed during the cycle.
		processInputValue = (doValueIn | (ioValueIn & 0xf)<<16) & (~doDirection | (~ioDirection & 0xf)<<16);
		processOutputMask = (doDirection | (ioDirection & 0xf)<<16);
		
    }
}

- (void) endProcessCycle
{
	readOnce = NO;
	//don't use the setter so the undo manager is bypassed
	doValueOut = processOutputValue & 0xFFFF;
	ioValueOut = (processOutputValue >> 16) & 0xF;
}

- (BOOL) processValue:(int)channel
{
	return (processInputValue & (1L<<channel)) > 0;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
	processOutputMask |= (1L<<channel);
	if(value)	processOutputValue |= (1L<<channel);
	else		processOutputValue &= ~(1L<<channel);
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"LabJackUE9,%d",[self uniqueIdNumber]];
}

- (NSString*) processingTitle
{
    return [self identifier];
}

- (double) convertedValue:(int)aChan
{
	double volts = 20.0/4095.*adc[aChan] - 10.;
	if(aChan>=0 && aChan<8)return slope[aChan] * volts + intercept[aChan];
	else return 0;
}

- (double) maxValueForChan:(int)aChan
{
	return maxValue[aChan];
}

- (double) minValueForChan:(int)aChan
{
	return minValue[aChan];
}

- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		if(channel>=0 && channel<8){
			*theLowLimit = lowLimit[channel];
			*theHighLimit =  hiLimit[channel];
		}
		else {
			*theLowLimit = -10;
			*theHighLimit = 10;
		}
	}		
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
  	[self setIpAddress:[decoder decodeObjectForKey:@"ipAddress"]];
	[self setAOut1:[decoder decodeIntForKey:@"aOut1"]];
    [self setAOut0:[decoder decodeIntForKey:@"aOut0"]];
    [self setShipData:[decoder decodeBoolForKey:@"shipData"]];
    [self setDigitalOutputEnabled:[decoder decodeBoolForKey:@"digitalOutputEnabled"]];
    [self setSerialNumber:	[decoder decodeObjectForKey:@"serialNumber"]];
	int i;
	for(i=0;i<8;i++) {
		
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"channelName%d",i]];
		if(aName)[self setChannel:i name:aName];
		else	 [self setChannel:i name:[NSString stringWithFormat:@"Chan %d",i]];
		
		NSString* aUnit = [decoder decodeObjectForKey:[NSString stringWithFormat:@"channelUnit%d",i]];
		if(aUnit)[self setChannel:i unit:aName];
		else	 [self setChannel:i unit:@"V"];
		
		[self setMinValue:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"minValue%d",i]]];
		[self setMaxValue:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"maxValue%d",i]]];
		[self setLowLimit:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"lowLimit%d",i]]];
		[self setHiLimit:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"hiLimit%d",i]]];
		[self setSlope:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"slope%d",i]]];
		[self setIntercept:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"intercept%d",i]]];
	}
	
	for(i=0;i<16;i++) {
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"DO%d",i]];
		if(aName)[self setDo:i name:aName];
		else [self setDo:i name:[NSString stringWithFormat:@"DO%d",i]];
	}
	
	for(i=0;i<4;i++) {
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"IO%d",i]];
		if(aName)[self setIo:i name:aName];
		else [self setIo:i name:[NSString stringWithFormat:@"IO%d",i]];
		[self setGain:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"gain%d",i]]];
	}
	[self setAdcDiff:	[decoder decodeIntForKey:@"adcDiff"]];
	[self setDoDirection:	[decoder decodeIntForKey:@"doDirection"]];
	[self setIoDirection:	[decoder decodeIntForKey:@"ioDirection"]];
    [self setPollTime:		[decoder decodeIntForKey:@"pollTime"]];

    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject:ipAddress forKey:@"ipAddress"];
	[encoder encodeInt:aOut1 forKey:@"aOut1"];
    [encoder encodeInt:aOut0 forKey:@"aOut0"];
    [encoder encodeBool:shipData forKey:@"shipData"];
    [encoder encodeInt:pollTime forKey:@"pollTime"];
    [encoder encodeBool:digitalOutputEnabled forKey:@"digitalOutputEnabled"];
    [encoder encodeObject:serialNumber	forKey: @"serialNumber"];
	int i;
	for(i=0;i<8;i++) {
		[encoder encodeObject:channelUnit[i] forKey:[NSString stringWithFormat:@"unitName%d",i]];
		[encoder encodeObject:channelName[i] forKey:[NSString stringWithFormat:@"channelName%d",i]];
		[encoder encodeFloat:lowLimit[i] forKey:[NSString stringWithFormat:@"lowLimit%d",i]];
		[encoder encodeFloat:hiLimit[i] forKey:[NSString stringWithFormat:@"hiLimit%d",i]];
		[encoder encodeFloat:slope[i] forKey:[NSString stringWithFormat:@"slope%d",i]];
		[encoder encodeFloat:intercept[i] forKey:[NSString stringWithFormat:@"intercept%d",i]];
		[encoder encodeFloat:minValue[i] forKey:[NSString stringWithFormat:@"minValue%d",i]];
		[encoder encodeFloat:maxValue[i] forKey:[NSString stringWithFormat:@"maxValue%d",i]];
	}
	
	for(i=0;i<16;i++) {
		[encoder encodeObject:doName[i] forKey:[NSString stringWithFormat:@"DO%d",i]];
	}
	for(i=0;i<4;i++) {
		[encoder encodeObject:ioName[i] forKey:[NSString stringWithFormat:@"IO%d",i]];
		[encoder encodeInt:gain[i] forKey:[NSString stringWithFormat:@"gain%d",i]];
	}

    [encoder encodeInt:adcDiff		forKey:@"adcDiff"];
    [encoder encodeInt:doDirection	forKey:@"doDirection"];
    [encoder encodeInt:ioDirection	forKey:@"ioDirection"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	
    [objDictionary setObject:[NSNumber numberWithInt:adcDiff] forKey:@"AdcDiffMask"];
	
    return objDictionary;
}

- (void) readSerialNumber
{
}
- (void) queryAll
{
}

- (void) enqueCmd:(NSData*)cmdData tag:(int)aTag
{
	ORLabJackUE9Cmd* aCmd = [[[ORLabJackUE9Cmd alloc] init] autorelease];
	aCmd.cmdData = cmdData;
	aCmd.tag	 = aTag;
	if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
	[cmdQueue addObject:aCmd];
	if(!lastRequest){
		[self processOneCommandFromQueue];
	}
}
- (void) processOneCommandFromQueue
{
	if([cmdQueue count] == 0) return;
	ORLabJackUE9Cmd* aCmd = [[[cmdQueue objectAtIndex:0] retain] autorelease];
	[cmdQueue removeObjectAtIndex:0];
	[self setLastRequest:aCmd];
	
	if(aCmd){
		[self startTimeOut];
		unsigned char* sendBuffer = (unsigned char*)[[aCmd cmdData] bytes];
		[socket write:sendBuffer length:[[aCmd cmdData] length]];
	}
	if(!lastRequest){
		[self performSelector:@selector(processOneCommandFromQueue) withObject:nil afterDelay:.1];
	}
}

- (void) startTimeOut
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:3];
}

- (void) getCalibrationInfo:(int)block
{
	if(block>=0 && block<5){
		unsigned char sendBuffer[8];		
		sendBuffer[1] = (unsigned char)0xF8;  //command unsigned char
		sendBuffer[2] = (unsigned char)0x01;  //number of data words
		sendBuffer[3] = (unsigned char)0x2A;  //extended command number
		sendBuffer[6] = (unsigned char)0x00;
		sendBuffer[7] = (unsigned char)block;    //Blocknum = 0
		[self extendedChecksum:sendBuffer len:8];
		NSData* data = [NSData dataWithBytes:sendBuffer length:8];
		[self enqueCmd:data tag:kUE9CalBlock];
	}
}

- (void) sendComCmd
{		
	unsigned char sendBuff[38];
	sendBuff[1] = (unsigned char)(0x78);  //command bytes
	sendBuff[2] = (unsigned char)(0x10);  //number of data words
	sendBuff[3] = (unsigned char)(0x01);  //extended command number
								  //Rest of the command is zero'ed out. not used.
	int i;
	for(i = 6; i < 38; i++) sendBuff[i] = (unsigned char)(0x00);
	
	[self extendedChecksum:sendBuff len:38];
	
	NSData* data = [NSData dataWithBytes:sendBuff length:38];
	[self enqueCmd:data tag:kUE9ComCmd]; //fix
}

- (void) readSingleAdc:(int)aChan
{		
	unsigned char ainResolution = 12;
	unsigned char sendBuff[8];
	sendBuff[1] = (unsigned char)0xA3;			//command byte
	sendBuff[2] = (unsigned char)kUE9AnalogIn;  //IOType = 4 (adc)
	sendBuff[3] = (unsigned char)aChan;			//Channel
	sendBuff[4] = (unsigned char)0x00;			//BipGain (Bip = unipolar, Gain = 1)
	sendBuff[5] = ainResolution;				//Resolution = 12
	sendBuff[6] = (unsigned char)0x00;			//SettlingTime = 0
	sendBuff[7] = (unsigned char)0x00;			//Reserved
	
	[self normalChecksum:sendBuff len:8];
	
	NSData* data = [NSData dataWithBytes:sendBuff length:8];
	[self enqueCmd:data tag:kUE9SingleIO];
}

- (void) feedBack
{	
	unsigned char sendBuff[34];
	int i;
	unsigned short rawDacValue;
	
	unsigned char ainResolution = 12;
	unsigned char gainBip = 0;  //(Gain = 1, Bipolar = 0)
	
	sendBuff[1] = (unsigned char)(0xF8);  //command byte
	sendBuff[2] = (unsigned char)(0x0E);  //number of data words
	sendBuff[3] = (unsigned char)(0x00);  //extended command number
	
	//all these bytes are set to zero since we are not changing
	//the FIO, EIO, CIO and MIO directions and states
	for(i = 6; i <= 15; i++)
		sendBuff[i] = (unsigned char)(0x00);
	
	if([self convert:2.5 chan:0 result:&rawDacValue]==0){
		//setting the voltage of DAC0
		sendBuff[16] = (unsigned char)( rawDacValue & (0x00FF) ); //low bits of voltage
		sendBuff[17] = (unsigned char)( rawDacValue / 256 ) + 192; //high bits of voltage
	}
	else {
		sendBuff[16] = 0; //low bits of voltage
		sendBuff[17] = 0; //high bits of voltage
	}
	//(bit 7 : Enable, bit 6: Update)
	if([self convert:3.5 chan:1 result:&rawDacValue]==0){	
		//setting the voltage of DAC1
		sendBuff[18] = (unsigned char)( rawDacValue & (0x00FF) ); //low bits of voltage
		sendBuff[19] = (unsigned char)( rawDacValue / 256 ) + 192; //high bits of voltage
																	//(bit 7 : Enable, bit 6: Update)
	}
	else {
		sendBuff[18] = 0;
		sendBuff[19] = 0;
	}
	
	sendBuff[20] = (unsigned char)(0xff);  //AINMask - reading AIN0 - AIN3, not AIN4 - AIN7
	sendBuff[21] = (unsigned char)(0xff);  //AINMask - not reading AIN8 - AIN15
	sendBuff[22] = (unsigned char)(0x00);  //AIN14ChannelNumber - not using
	sendBuff[23] = (unsigned char)(0x00);  //AIN15ChannelNumber - not using
	sendBuff[24] = ainResolution;     //Resolution = 12
	
	//setting BipGains
	for(i = 25; i < 34; i++) sendBuff[i] = gainBip;
	
	[self extendedChecksum:sendBuff len:34];
	
	
	NSData* data = [NSData dataWithBytes:sendBuff length:34];
	[self enqueCmd:data tag:kUE9FeedBack];
}
@end

@implementation ORLabJackUE9Model (private)

- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollTime == 0 )return;
    [[self undoManager] disableUndoRegistration];
	[self queryAll];
    [[self undoManager] enableUndoRegistration];
	if(pollTime == -1)[self performSelector:@selector(pollHardware) withObject:nil afterDelay:1/200.];
	else [self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (void) timeout
{
	NSLogError(@"LabJackUE9",@"command timeout",nil);
	[cmdQueue removeAllObjects];
	[self setLastRequest:nil];
}
		
- (void) readAdcValues
{
}

- (void) sendIoControl
{}


#pragma mark ***Checksum Helpers
- (void) normalChecksum:(unsigned char*)b len:(int)n
{
	b[0]=[self normalChecksum8:b len:n];
}

- (void) extendedChecksum:(unsigned char*)b len:(int)n
{
	unsigned short a;
	a = [self extendedChecksum16:b len:n];
	b[4] = (unsigned char)(a & 0xff);
	b[5] = (unsigned char)((a / 256) & 0xff);
	b[0] = [self extendedChecksum8:b];
}


- (unsigned char) normalChecksum8:(unsigned char*)b len:(int)n
{
	int i;
	unsigned short a, bb;
	
	//Sums bytes 1 to n-1 unsigned to a 2 byte value. Sums quotient and
	//remainder of 256 division.  Again, sums quotient and remainder of
	//256 division.
	for(i = 1, a = 0; i < n; i++){
		a+=(unsigned short)b[i];
	}
	bb = a / 256;
	a = (a - 256 * bb) + bb;
	bb = a / 256;
	
	return (unsigned char)((a-256*bb)+bb);
}


- (unsigned short) extendedChecksum16:(unsigned char*)b len:(int) n
{
	int i, a = 0;
	
	//Sums bytes 6 to n-1 to a unsigned 2 byte value
	for(i = 6; i < n; i++){
		a += (unsigned short)b[i];
	}
	return a;
}


/* Sum bytes 1 to 5. Sum quotient and remainder of 256 division. Again, sum
 quotient and remainder of 256 division. Return result as unsigned char. */
- (unsigned char) extendedChecksum8:(unsigned char*) b
{
	int i, a, bb;
	
	//Sums bytes 1 to 5. Sums quotient and remainder of 256 division. Again, sums 
	//quotient and remainder of 256 division.
	for(i = 1, a = 0; i < 6; i++){
		a+=(unsigned short)b[i];
	}
	bb = a / 256;
	a = (a - 256 * bb) + bb;
	bb = a / 256;
	
	return (unsigned char)((a - 256 * bb) + bb);  
}

- (double) bufferToDouble:(unsigned char*)buffer index:(int) startIndex 
{ 
    unsigned long resultDec = 0;
	unsigned long resultWh = 0;
    int i;
    for( i = 0; i < 4; i++ ){
        resultDec += (unsigned long)buffer[startIndex + i] * pow(2, (i*8));
        resultWh += (unsigned long)buffer[startIndex + i + 4] * pow(2, (i*8));
    }
	
    return ( (double)((int)resultWh) + (double)(resultDec)/4294967296.0 );
}

- (void) decodeComCmd:(NSData*) theData
{
	unsigned char* recBuff = (unsigned char*)[theData bytes];
	NSLog(@"LocalID (byte 8): %d\n", recBuff[8]);
	NSLog(@"PowerLevel (byte 9): %d\n", recBuff[9]);
	NSLog(@"ipAddress (bytes 10-13): %d.%d.%d.%d\n", recBuff[13], recBuff[12], recBuff[11], recBuff[10]);
	NSLog(@"Gateway (bytes 14 - 17): %d.%d.%d.%d\n", recBuff[17], recBuff[16], recBuff[15], recBuff[14]);
	NSLog(@"Subnet (bytes 18 - 21): %d.%d.%d.%d\n", recBuff[21], recBuff[20], recBuff[19], recBuff[18]);
	NSLog(@"PortA (bytes 22 - 23): %d\n", recBuff[22] + (recBuff[23] * 256 ));
	NSLog(@"PortB (bytes 24 - 25): %d\n", recBuff[24] + (recBuff[25] * 256 ));
	NSLog(@"DHCPEnabled (byte 26): %d\n", recBuff[26]);
	NSLog(@"ProductID (byte 27): %d\n", recBuff[27]);
	int i;
	NSString* s = @"MACAddress (bytes 28 - 33): ";
	for(i = 5; i >= 0  ; i--){
		s = [s stringByAppendingFormat:@"%02x",recBuff[i+28]];
		if(i !=0)s = [s stringByAppendingString:@"."];
	}
	NSLog(@"%@\n",s);
	NSLog(@"HWVersion (bytes 34-35): %.3f\n", (unsigned int)recBuff[35]  + (double)recBuff[34]/100.0);
	NSLog(@"CommFWVersion (bytes 36-37): %.3f\n\n", (unsigned int)recBuff[37] + (double)recBuff[36]/100.0);
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
}

- (void) decodeSingleAdcRead:(NSData*) theData
{
	unsigned char* recBuff = (unsigned char*)[theData bytes];
	unsigned long rawAdc = recBuff[5] + recBuff[6] * 256;
	double voltage;
	if([self convert:rawAdc gainBip:recBuff[4] result:&voltage]==0){
		NSLog(@"adc(%d): %f\n",recBuff[3],voltage);
	}
	else NSLog(@"error converting\n");
}

- (void) decodeFeedBack:(NSData*) theData
{
	int i;
	unsigned char* recBuff = (unsigned char*)[theData bytes];
	if(recBuff[1] != (uint8)(0xF8) || recBuff[2] != (uint8)(0x1D) || recBuff[3] != (uint8)(0x00))
	{
		printf("Error : received buffer has wrong command bytes \n");
		return;
	}
	
	printf("Set DAC0 to 2.500 volts and DAC1 to 3.500 volts.\n\n");
	printf("Flexible digital I/O directions and states (FIO0 - FIO3):\n");
	for(i = 0; i < 4; i++){
		unsigned int tempDir = ( (uint32)(recBuff[6] / pow(2, i)) & 0x01 );
		unsigned int tempState = ( (uint32)(recBuff[7] / pow(2, i)) & 0x01 );
		printf("  FI%d: %d and %d\n", i, tempDir, tempState);
	}
	
	double voltage;
	printf("\nAnalog Inputs (AI0 - AI3):\n");
	for(i = 0; i < 14; i++){
		unsigned long rawAdc = recBuff[12 + 2*i] + recBuff[13 + 2*i] * 256;
		
		//getting analog voltage
		if([self convert:rawAdc gainBip:0 result:&voltage]==0){
			printf("  AI%d: %.6f V\n", i, voltage);
		}
	}
	printf("\n");
}

- (void) decodeCalibData:(NSData*)theData
{

	if( [theData length] < 136 ){
		NSLog(@"getCalibrationInfo Error : did not read all of the buffer\n");
		return;
	}
	unsigned char* recBuffer = (unsigned char*)[theData bytes];
	if( recBuffer[1] != (unsigned char)(0xF8) || recBuffer[2] != (unsigned char)(0x41) || recBuffer[3] != (unsigned char)(0x2A) ){
		NSLog(@"getCalibrationInfo error: incorrect command bytes for ReadMem response");
		return;
	}
	int i = recBuffer[7];
	NSLog(@"got calib: %d\n",i);
	
	switch(i){
		case 0:
			//block data starts on byte 8 of the buffer
			unipolarSlope[0]	= [self bufferToDouble:recBuffer + 8 index:0];
			unipolarOffset[0]	= [self bufferToDouble:recBuffer + 8 index:8];
			unipolarSlope[1]	= [self bufferToDouble:recBuffer + 8 index:16];
			unipolarOffset[1]	= [self bufferToDouble:recBuffer + 8 index:24];
			unipolarSlope[2]	= [self bufferToDouble:recBuffer + 8 index:32];
			unipolarOffset[2]	= [self bufferToDouble:recBuffer + 8 index:40];
			unipolarSlope[3]	= [self bufferToDouble:recBuffer + 8 index:48];
			unipolarOffset[3]	= [self bufferToDouble:recBuffer + 8 index:56];
		break;
			
		case 1:
			bipolarSlope	= [self bufferToDouble:recBuffer + 8 index:0];
			bipolarOffset	= [self bufferToDouble:recBuffer + 8 index:8];
		break;
			
		case 2:
			DACSlope[0]		= [self bufferToDouble:recBuffer + 8	index:0];
			DACOffset[0]	= [self bufferToDouble:recBuffer + 8	index:8];
			DACSlope[1]		= [self bufferToDouble:recBuffer + 8	index:16];
			DACOffset[1]	= [self bufferToDouble:recBuffer + 8	index:24];
			tempSlope		= [self bufferToDouble:recBuffer + 8	index:32];
			tempSlopeLow	= [self bufferToDouble:recBuffer + 8	index:48];
			calTemp			= [self bufferToDouble:recBuffer + 8	index:64];
			Vref			= [self bufferToDouble:recBuffer + 8	index:72];
			VrefDiv2		= [self bufferToDouble:recBuffer + 8	index:88];
			VsSlope			= [self bufferToDouble:recBuffer + 8	index:96];
		break;
			
		case 3:
			hiResUnipolarSlope  = [self bufferToDouble:recBuffer + 8 index:0];
			hiResUnipolarOffset = [self bufferToDouble:recBuffer + 8 index:8];
		break;
			
		case 4:
			hiResBipolarSlope  = [self bufferToDouble:recBuffer + 8 index:0];
			hiResBipolarOffset = [self bufferToDouble:recBuffer + 8 index:8];
		break;
	}
}
- (long) convert:(double) analogVoltage chan:(int) DACNumber result:(unsigned short*)rawDacValue
{
	double internalSlope;
	double internalOffset;
    
	switch(DACNumber) {
		case 0:
			internalSlope = DACSlope[0];
			internalOffset = DACOffset[0];
		break;
		case 1:
			internalSlope = DACSlope[1];
			internalOffset = DACOffset[1];
		break;
		default:
			return -1;
	}
	
	double tempBytesVoltage = internalSlope * analogVoltage + internalOffset;
	
	//Checking to make sure bytesVoltage will be a value between 0 and 4095, 
	//or that a unsigned short overflow does not occur.  A too high analogVoltage 
	//(above 5 volts) or too low analogVoltage (below 0 volts) will cause a 
	//value not between 0 and 4095.
	if(tempBytesVoltage < 0)	tempBytesVoltage = 0;
	if(tempBytesVoltage > 4095) tempBytesVoltage = 4095;
	
	*rawDacValue = (unsigned short)tempBytesVoltage; 
	
	return 0;
}

- (long) convert:(unsigned long)rawAdc gainBip:(unsigned short)gainBip result:(double*)analogVoltage
{
	double internalSlope;
	double internalOffset;
		
	switch(gainBip ){
		case 0:
			internalSlope = unipolarSlope[0];
			internalOffset = unipolarOffset[0];
		break;
		case 1:
			internalSlope = unipolarSlope[1];
			internalOffset = unipolarOffset[1];
		break;
		case 2:
			internalSlope = unipolarSlope[2];
			internalOffset = unipolarOffset[2];
		break;
		case 3:
			internalSlope = unipolarSlope[3];
			internalOffset = unipolarOffset[3];
		break;
		case 8:
			internalSlope = bipolarSlope;
			internalOffset = bipolarOffset;
		break;
		default:
			return -1;

	}
	
	*analogVoltage = (internalSlope * rawAdc) + internalOffset;
	return 0;
}

@end


