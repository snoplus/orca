//
//  ORMotionNodeModel.m
//  Orca
//
//  Created by Mark Howe on Fri Apr 24, 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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
#import "ORMotionNodeModel.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORSafeQueue.h"


NSString* ORMotionNodeModelShowDeltaFromAveChanged = @"ORMotionNodeModelShowDeltaFromAveChanged";
NSString* ORMotionNodeModelDisplayComponentsChanged = @"ORMotionNodeModelDisplayComponentsChanged";
NSString* ORMotionNodeModelTemperatureChanged	= @"ORMotionNodeModelTemperatureChanged";
NSString* ORMotionNodeModelNodeRunningChanged	= @"ORMotionNodeModelNodeRunningChanged";
NSString* ORMotionNodeModelTraceIndexChanged	= @"ORMotionNodeModelTraceIndexChanged";
NSString* ORMotionNodeModelPacketLengthChanged	= @"ORMotionNodeModelPacketLengthChanged";
NSString* ORMotionNodeModelIsAccelOnlyChanged	= @"ORMotionNodeModelIsAccelOnlyChanged";
NSString* ORMotionNodeModelVersionChanged		= @"ORMotionNodeModelVersionChanged";
NSString* ORMotionNodeModelLock					= @"ORMotionNodeModelLock";
NSString* ORMotionNodeModelSerialNumberChanged	= @"ORMotionNodeModelSerialNumberChanged";

#define kMotionNodeDriverPath @"/System/Library/Extensions/SiLabsUSBDriver.kext"
#define kMotionNodeAveN 2/(100.+1.)

static MotionNodeCommands motionNodeCmds[kNumMotionNodeCommands] = {
{kMotionNodeConnectResponse,@"0",		14,		NO},
{kMotionNodeMemoryContents,	@"rrr",		256,	NO}, 
{kMotionNodeStop,			@")",		-1,		YES}, 
{kMotionNodeStart,			@"xxx\0",	-1,		YES},
{kMotionNodeClosePort,		@"",		-1,		NO}
};

@interface ORMotionNodeModel (private)
- (void) timeout;
- (void) processOneCommandFromQueue;
- (void) enqueCmd:(int)aCmd;
- (void) processInComingData;
- (void) processPacket:(NSData*)thePacket;
- (void) delayedInit;
- (void) setAx:(float)aAx;
- (void) setAz:(float)aAz;
- (void) setAy:(float)aAy;
- (void) setTraceIndex:(int)aTraceIndex;
- (void) setTotalxyz;

@end


@implementation ORMotionNodeModel
- (void) dealloc
{
	if([self nodeRunning]){
		[self stopDevice];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[noDriverAlarm clearAlarm];
	[noDriverAlarm release];
	[cmdQueue release];
	[lastRequest release];
	[super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		//make sure the driver is installed.
		NSFileManager* fm = [NSFileManager defaultManager];
		if(![fm fileExistsAtPath:kMotionNodeDriverPath]){
			NSLogColor([NSColor redColor],@"*** Unable To Locate MotionNode Driver ***\n");
			if(!noDriverAlarm){
				noDriverAlarm = [[ORAlarm alloc] initWithName:@"No MotionNode Driver Found" severity:0];
				[noDriverAlarm setSticky:NO];
				[noDriverAlarm setHelpStringFromFile:@"NoMotionNodeDriverHelp"];
			}                      
			[noDriverAlarm setAcknowledged:NO];
			[noDriverAlarm postAlarm];
		}
	}
	@catch(NSException* localException) {
	}
	
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"MotionNode"]];
}

- (NSString*) title 
{
	if([serialPort isOpen]){
		return [NSString stringWithFormat:@"MotionNode (%@)",[self serialNumber]];
	}
	else {
		return @"MotionNode (---)";
	}
}


- (void) makeMainController
{
    [self linkToController:@"ORMotionNodeController"];
}

#pragma mark ***Accessors

- (BOOL) showDeltaFromAve
{
    return showDeltaFromAve;
}

- (void) setShowDeltaFromAve:(BOOL)aShowDeltaFromAve
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowDeltaFromAve:showDeltaFromAve];
    
    showDeltaFromAve = aShowDeltaFromAve;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelShowDeltaFromAveChanged object:self];
}

- (float) temperature
{
    return temperature;
}

- (void) setTemperature:(float)aTemperature
{
    temperature = aTemperature;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelTemperatureChanged object:self];
}

- (float) displayComponents
{
	return displayComponents;
}

- (void) setDisplayComponents:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDisplayComponents:displayComponents];
    
    displayComponents = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelDisplayComponentsChanged object:self];
}

- (BOOL) nodeRunning
{
    return nodeRunning;
}

- (void) setNodeRunning:(BOOL)aNodeRunning
{
    nodeRunning = aNodeRunning;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelNodeRunningChanged object:self];
}

- (int) traceIndex
{
    return traceIndex;
}

- (float) axDeltaAveAt:(int)i
{
	return xTrace[(i+traceIndex)%kModeNodeTraceLength] - xAve;
}

- (float) ayDeltaAveAt:(int)i
{
	return yTrace[(i+traceIndex)%kModeNodeTraceLength] - yAve;
}

- (float) azDeltaAveAt:(int)i
{
	return zTrace[(i+traceIndex)%kModeNodeTraceLength] - zAve;
}

- (float) xyzDeltaAveAt:(int)i
{
	return xyzTrace[(i+traceIndex)%kModeNodeTraceLength] - xyzAve;
}

- (float) axAt:(int)i
{
	return xTrace[(i+traceIndex)%kModeNodeTraceLength];
}
- (float) ayAt:(int)i
{
	return yTrace[(i+traceIndex)%kModeNodeTraceLength];
}
- (float) azAt:(int)i
{
	return zTrace[(i+traceIndex)%kModeNodeTraceLength];
}

- (float) totalxyzAt:(int)i
{
	return xyzTrace[(i+traceIndex)%kModeNodeTraceLength];
}

- (int) packetLength
{
    return packetLength;
}

- (void) setPacketLength:(int)aPacketLength
{
    packetLength = aPacketLength;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelPacketLengthChanged object:self];
}

- (BOOL) isAccelOnly
{
    return isAccelOnly;
}

- (void) setIsAccelOnly:(BOOL)aIsAccelOnly
{
    isAccelOnly = aIsAccelOnly;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelIsAccelOnlyChanged object:self];
}

- (int) nodeVersion
{
    return nodeVersion;
}

- (void) setNodeVersion:(int)aVersion
{
    nodeVersion = aVersion;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelVersionChanged object:self];
}

- (NSString*) serialNumber
{
	if(!serialNumber)return @"--";
    return serialNumber;
}

- (void) setSerialNumber:(NSString*)aSerialNumber
{
	if(!aSerialNumber)aSerialNumber = @"--";
    [[[self undoManager] prepareWithInvocationTarget:self] setSerialNumber:serialNumber];
    
    [serialNumber autorelease];
    serialNumber = [aSerialNumber copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelSerialNumberChanged object:self];
}

- (id) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(id)aCmd
{
	[aCmd retain];
	[lastRequest release];
	lastRequest = aCmd;
}

- (void) openPort:(BOOL)state
{
    if(state) {
		[serialPort open];
		NSMutableDictionary* options = [[[serialPort getOptions] mutableCopy] autorelease];
		[options setObject:@"57600" forKey:ORSerialOptionSpeed];
		[serialPort setOptions:options];
 		[serialPort setDelegate:self];
		[self performSelector:@selector(initDevice) withObject:nil afterDelay:1];
    }
    else {
		if(nodeRunning){
			[self stopDevice];
			[self enqueCmd:kMotionNodeClosePort];
		}
		else {
			[serialPort close];
			[inComingData release];
			inComingData = nil;
		}
		[self setSerialNumber:nil];
	}
    portWasOpen = [serialPort isOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSerialPortModelPortStateChanged object:self];
    
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setShowDeltaFromAve:[decoder decodeBoolForKey:@"ORMotionNodeModelShowDeltaFromAve"]];
    [self setDisplayComponents:[decoder decodeBoolForKey:@"displayComponents"]];
	
    [[self undoManager] enableUndoRegistration];    
	cmdQueue = [[ORSafeQueue alloc] init];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:showDeltaFromAve forKey:@"ORMotionNodeModelShowDeltaFromAve"];
    [encoder encodeBool:displayComponents		forKey: @"displayComponents"];
}

- (void) initDevice
{
	if(!nodeRunning){
		[self readConnect];
		[self readOnboardMemory];	
	}
}

- (void) stopDevice
{
	[self setNodeRunning:NO];
	[self enqueCmd:kMotionNodeStop];
}

- (void) startDevice
{
	memset(xTrace,0,sizeof(float)*kModeNodeTraceLength);
	memset(yTrace,0,sizeof(float)*kModeNodeTraceLength);
	memset(zTrace,0,sizeof(float)*kModeNodeTraceLength);
	memset(xyzTrace,0,sizeof(float)*kModeNodeTraceLength);
	[self setTraceIndex:0];
	[self enqueCmd:kMotionNodeStart];
	[self setNodeRunning:YES];
}


- (void) readOnboardMemory
{
	[self enqueCmd:kMotionNodeMemoryContents];
}

- (void) readConnect
{
	[self enqueCmd:kMotionNodeConnectResponse];
}

- (void) dataReceived:(NSNotification*)note
{
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		if(!inComingData)inComingData = [[NSMutableData data] retain];
		[inComingData appendData:[[note userInfo] objectForKey:@"data"]];
		if(!lastRequest){
			if(packetLength){
				if([inComingData length] >= packetLength){
					do {
						[self processPacket:inComingData];
						[inComingData replaceBytesInRange:NSMakeRange(0,packetLength) withBytes:nil length:0];
					} while([inComingData length] >= packetLength);
				}
			}
			else {
				//arg, the device is running from a previous time
				//since the packetLength is zero we have never been inited.in
				//we just throw the data away until we get none for .5 sec. then we init
				[self performSelectorOnMainThread:@selector(flushCheck) withObject:nil waitUntilDone:YES];
			}
		}
		else {
			int expectedLength = [[lastRequest objectForKey:@"expectedLength"] intValue];
			if([inComingData length] == expectedLength){
				[self processInComingData];
			}
		}
	}
}
@end

@implementation ORMotionNodeModel (private)
- (void) flushCheck
{
	[self setNodeRunning:YES];
	[inComingData release];
	inComingData = nil;
	[self enqueCmd:kMotionNodeStop];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedInit) object:nil];
	[self performSelector:@selector(delayedInit) withObject:nil afterDelay:1];
}

- (void) delayedInit
{
	[self setNodeRunning:NO];
	[self openPort:NO];
	[self openPort:YES];
}

- (void) processPacket:(NSData*)thePacket
{
	
	char* data = (char*)[thePacket bytes];
	
	const unsigned char lMask = 0xF0;
	const unsigned char rMask = 0x0F;
	
	if (data[0] == 0x31) {
		
#		if defined(__BIG_ENDIAN__)
		const int highBtyeIndex = 0;
		const int lowBtyeIndex  = 1;
#		else
		const int highBtyeIndex = 1;
		const int lowBtyeIndex  = 0;
#		endif // __BIG_ENDIAN__
		
		union {
			short unpacked;
			unsigned char bytes[2];
		}rawData;
		
		const float kSlope		= 4.0/4095.0;
		const float kIntercept	= -2.0;
		
		// accel 0
		rawData.bytes[highBtyeIndex] = (data[2] >> 4) & rMask;
		rawData.bytes[lowBtyeIndex] = data[1];
		[self setAz:kSlope * rawData.unpacked + kIntercept];
		
		// accel 1
		rawData.bytes[highBtyeIndex] = data[3] & rMask;
		rawData.bytes[lowBtyeIndex] = ((data[2] << 4) & lMask) | ((data[3] >> 4) & rMask);
		[self setAy:kSlope * rawData.unpacked + kIntercept];
		
		// accel 2
		rawData.bytes[highBtyeIndex] = (data[5] >> 4) & rMask;
		rawData.bytes[lowBtyeIndex] = data[4];
		[self setAx:kSlope * rawData.unpacked + kIntercept];
		
		
		//do a runing average for the temperature
		float temp;
		rawData.bytes[highBtyeIndex] = data[14] & rMask;
		rawData.bytes[lowBtyeIndex] = data[15];
		temp = rawData.unpacked * (330./4095.) - 50.;
		float k  = 2/(300.+1.);
		temperatureAverage = temp * k+temperatureAverage*(1-k);
		
		if((throttle == 0) || (throttle%300 == 0)){			
			[self setTemperature:temperatureAverage];
		}
		throttle++;
		
		[self setTotalxyz];
		
		[self setTraceIndex:++traceIndex];
		
	}
	else {
		[inComingData release];
		inComingData = nil;
	}
	
	/*		// Convert to signed degrees Celsius.
	 float celsius = sample[9] * (1.0/8.0);
	 // Invert the old temperature function to get the raw value
	 // from degrees Celsius. Add a half to "round up".
	 float temperature = (celsius + 50.0) * (4095.0/330.0) + 0.5;
	 if (temperature > 4095) temperature = 4095;
	 else if (temperature < 0) temperature = 0;
	 else temperature = (int)temperature;
	 
	 NSLog(@"%.3f,%.3f,%.3f,%.2f\n", 
	 kIntercept + kSlope*sample[0],
	 kIntercept + kSlope*sample[1],
	 kIntercept + kSlope*sample[2],
	 temperature
	 );
	 */
	
	
}

- (void) timeout
{
	BOOL okToTimeOut   = [[lastRequest objectForKey:@"okToTimeOut"] intValue]; 
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	[self setLastRequest:nil];
	if(!okToTimeOut) {
		NSLogError(@"PAC",@"command timeout",nil);
		[cmdQueue removeAllObjects];
	}
	[self processOneCommandFromQueue];	 //do the next command in the queue
}

- (void) processOneCommandFromQueue
{
	if([cmdQueue count] == 0) return;
	id cmd = [cmdQueue dequeue];
	if([[cmd objectForKey:@"cmdNumber"] intValue] == kMotionNodeClosePort){
		[serialPort close];
		portWasOpen = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSerialPortModelPortStateChanged object:self];
		[inComingData release];
		inComingData = nil;
	}
	else {
		[self setLastRequest:cmd];
		[serialPort writeString:[cmd objectForKey:@"command"]];
		[self performSelector:@selector(timeout) withObject:nil afterDelay:.3]; //maybe use a variable timeout
	}
}

- (void) enqueCmd:(int)aCmdNum
{
	if([serialPort isOpen]){
		NSString* theCommand = motionNodeCmds[aCmdNum].command;
		int theCommandNumber = motionNodeCmds[aCmdNum].cmdNumber;
		int theExpectedLength = motionNodeCmds[aCmdNum].expectedLength;
		BOOL okToTimeOut = motionNodeCmds[aCmdNum].okToTimeOut;
		if(theCommandNumber == kMotionNodeStart) {
			if(nodeVersion>= 7)theCommand = [theCommand stringByAppendingString:@"\151"];
			else if(nodeVersion>= 6)theCommand = [theCommand stringByAppendingString:@"\093"];
			else theCommand = [theCommand stringByAppendingString:@"\095"];
			theCommand = [theCommand stringByAppendingString:@"("];
		}
		NSDictionary* cmd = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithInt:theCommandNumber],	@"cmdNumber",
							 theCommand,								@"command",
							 [NSNumber numberWithInt:theExpectedLength],@"expectedLength",
							 [NSNumber numberWithBool:okToTimeOut],		@"okToTimeOut",
							 nil];
		[cmdQueue enqueue:cmd];
		if(!lastRequest)[self processOneCommandFromQueue];
	}
}

- (void) processInComingData
{
	BOOL doNextCommand = NO;
	if(lastRequest){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
		int i;
		char* p = (char*)[inComingData bytes];
		switch([[lastRequest objectForKey:@"cmdNumber"] intValue]){
			case kMotionNodeConnectResponse:
				break;
				
			case kMotionNodeMemoryContents:
				for(i=0;i<[inComingData length];i++){
					if(p[i]<0x20){
						[inComingData setLength:i];
						break;
					}
				}
				if([inComingData length]>=4){
					NSString* theString = [[[NSString alloc] initWithData:inComingData encoding:NSASCIIStringEncoding] autorelease];
					[self setSerialNumber:theString];
					[self setIsAccelOnly: [theString hasPrefix:@"acc"]];
					[self setNodeVersion: [[theString substringWithRange:NSMakeRange(3,1)] intValue]];
					[self setPacketLength:nodeVersion>=6?16:15];
				}
				else {
					[self setSerialNumber:@"--"];
					[self setIsAccelOnly:NO];
					[self setNodeVersion:0];
					[self setPacketLength:0];
				}
				break;
				
			case kMotionNodeStop:
				
				break;
				
			case kMotionNodeStart:
				break;
		}
		[self setLastRequest:nil];			 //clear the last request
		
		[inComingData release];
		inComingData = nil;
		doNextCommand = YES;
	}
	
	if(doNextCommand){
		[self processOneCommandFromQueue];	 //do the next command in the queue
	}
}

- (void) setTraceIndex:(int)aTraceIndex
{
    traceIndex = aTraceIndex % kModeNodeTraceLength;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelTraceIndexChanged object:self];
}

- (void) setAz:(float)aAz
{
    az = aAz;
	zTrace[traceIndex] = az;
	zAve = az * kMotionNodeAveN+zAve*(1-kMotionNodeAveN);
}

- (void) setAy:(float)aAy
{
    ay = aAy;
	yTrace[traceIndex] = ay;
	yAve = ay * kMotionNodeAveN+yAve*(1-kMotionNodeAveN);
}

- (void) setAx:(float)aAx
{
    ax = aAx;
	xTrace[traceIndex] = ax;
	xAve = ax * kMotionNodeAveN+xAve*(1-kMotionNodeAveN);
}

- (void) setTotalxyz
{
	xyzTrace[traceIndex] = 0.86 - sqrtf(ax*ax + ay*ay + az*az);
	xyzAve = xyzTrace[traceIndex] * kMotionNodeAveN+xyzAve*(1-kMotionNodeAveN);
}
@end
