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


NSString* ORMotionNodeModelLongTermSensitivityChanged = @"ORMotionNodeModelLongTermSensitivityChanged";
NSString* ORMotionNodeModelStartTimeChanged = @"ORMotionNodeModelStartTimeChanged";
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
NSString* ORMotionNodeModelUpdateLongTermTrace	= @"ORMotionNodeModelUpdateLongTermTrace";

#define kMotionNodeDriverPath @"/System/Library/Extensions/SLAB_USBtoUART.kext"
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
- (void) incTraceIndex;
- (void) setTotalxyz;
@end


@implementation ORMotionNodeModel
- (void) dealloc
{
 	if([self nodeRunning])[self stopDevice];
	[[NSNotificationCenter defaultCenter] removeObserver:self];	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[startTime release];
	[noDriverAlarm clearAlarm];
	[noDriverAlarm release];
	[cmdQueue release];
	[lastRequest release];
	[inComingData release];
	[lastRequest release];
	[serialNumber release];
	[localLock release];
	
	
	int i;
	for (i = 0; i < kNumMin; i++) free(longTermTrace[i]);
	free(longTermTrace);
	
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
		//alloc a large 2-D array for the long term storage
		int i;
		longTermTrace = malloc(kNumMin * sizeof(float *));
		for (i = 0; i < kNumMin; i++) {
			longTermTrace[i] = malloc(kModeNodeLongTraceLength * sizeof(float));
			memset(longTermTrace[i],0,kModeNodeLongTraceLength * sizeof(float));
		}
		longTermValid = YES;
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

- (int) longTermSensitivity
{
    return longTermSensitivity;
}

- (void) setLongTermSensitivity:(int)aSensitivity
{
	
	if(aSensitivity<=0)aSensitivity = 1;
	else if(aSensitivity>1000)aSensitivity = 1000;
    [[[self undoManager] prepareWithInvocationTarget:self] setLongTermSensitivity:longTermSensitivity];
    
    longTermSensitivity = aSensitivity;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelLongTermSensitivityChanged object:self];
}

- (NSDate*) startTime
{
    return startTime;
}

- (void) setStartTime:(NSDate*)aStartTime
{
    [aStartTime retain];
    [startTime release];
    startTime = aStartTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelStartTimeChanged object:self];
}

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

- (float) axDeltaAveAt:(int)i
{
	return xTrace[(i+traceIndex)%kModeNodeTraceLength] - xTrace[(i+traceIndex-1)%kModeNodeTraceLength];
}

- (float) ayDeltaAveAt:(int)i
{
	return yTrace[(i+traceIndex)%kModeNodeTraceLength] - yTrace[(i+traceIndex-1)%kModeNodeTraceLength];
}

- (float) azDeltaAveAt:(int)i
{
	return zTrace[(i+traceIndex)%kModeNodeTraceLength] - zTrace[(i+traceIndex-1)%kModeNodeTraceLength];
}

- (float) xyzDeltaAveAt:(int)i
{
	return xyzTrace[(i+traceIndex)%kModeNodeTraceLength] - xyzTrace[(i+traceIndex-1)%kModeNodeTraceLength];
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
    [[self undoManager] disableUndoRegistration];

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
	[[self undoManager] enableUndoRegistration];
   
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setLongTermSensitivity:	[decoder decodeIntForKey:@"longTermSensitivity"]];
    [self setShowDeltaFromAve:		[decoder decodeBoolForKey:@"showDeltaFromAve"]];
    [self setDisplayComponents:	[decoder decodeBoolForKey:@"displayComponents"]];
	
    [[self undoManager] enableUndoRegistration];    
	cmdQueue = [[ORSafeQueue alloc] init];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:longTermSensitivity		forKey:@"longTermSensitivity"];
    [encoder encodeBool:showDeltaFromAve	forKey:@"showDeltaFromAve"];
    [encoder encodeBool:displayComponents	forKey: @"displayComponents"];
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
	[self setStartTime:[NSDate date]];
	memset(xTrace,0,sizeof(float)*kModeNodeTraceLength);
	memset(yTrace,0,sizeof(float)*kModeNodeTraceLength);
	memset(zTrace,0,sizeof(float)*kModeNodeTraceLength);
	memset(xyzTrace,0,sizeof(float)*kModeNodeTraceLength);
	int i;
	for(i=0;i<kNumMin;i++){
		memset(longTermTrace[i],0,sizeof(float)*kModeNodeLongTraceLength);
	}
	[self setTraceIndex:0];
	longTraceIndex = longTraceMinIndex = 0;
	cycledOnce = NO;
	[self enqueCmd:kMotionNodeStart];
	[self setNodeRunning:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelUpdateLongTermTrace object:self];
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
					[[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelTraceIndexChanged object:self];

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

- (int) indexForLine:(int)m
{
	int line = longTraceMinIndex-m;
	if(line<0)line = kNumMin + (longTraceMinIndex - m);
	return line;
}

- (int) maxLinesInLongTermView
{
	return kNumMin;
}

- (int) numLinesInLongTermView
{
	if(cycledOnce) return kNumMin;
	else return longTraceMinIndex;
}

- (int) numPointsPerLineInLongTermView
{
	return kModeNodeLongTraceLength;
}

- (float)longTermDataAtLine:(int)m point:(int)i
{
	if(longTermValid && i>0){
		return (longTermTrace[m][(i-1)] - longTermTrace[m][i])  * longTermSensitivity;
	}
	else return 0;
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
		
		[self incTraceIndex];
		
	}
	else {
		[inComingData release];
		inComingData = nil;
	}
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

- (void) incTraceIndex
{
    traceIndex = (traceIndex+1) % kModeNodeTraceLength;
}

- (void) setAz:(float)aAz
{
    az = aAz;
	zTrace[traceIndex] = az;
}

- (void) setAy:(float)aAy
{
    ay = aAy;
	yTrace[traceIndex] = ay;
}

- (void) setAx:(float)aAx
{
    ax = aAx;
	xTrace[traceIndex] = ax;
}

- (void) setTotalxyz
{
	xyzTrace[traceIndex] = 0.86 - sqrtf(ax*ax + ay*ay + az*az);
	if(longTermValid){
		if(traceIndex >= kModeNodeTraceLength-1){
			int i;
			float	longTraceValueToKeep = 0;
			for(i=0;i<kModeNodeTraceLength;i++){
				if(fabs(xyzTrace[i]) > fabs(longTraceValueToKeep)){
					longTraceValueToKeep = xyzTrace[i];
				}
				if(i!=0 && !(i%kModeNodePtsToCombine)){				
					longTermTrace[longTraceMinIndex][longTraceIndex] = longTraceValueToKeep;
					longTraceValueToKeep = 0;
					longTraceIndex = (longTraceIndex+1)%kModeNodeLongTraceLength;
					if(longTraceIndex==0){
						[[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelUpdateLongTermTrace object:self];
						longTraceMinIndex = (longTraceMinIndex+1)%kNumMin;
						if(longTraceMinIndex == 0) cycledOnce = YES;
						int i;
						for(i=0;i<kModeNodeLongTraceLength;i++){
							longTermTrace[longTraceMinIndex][i] = 0;
						}
					}
				}
			}
		}
	}
	
}

	


@end
