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
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"


NSString* ORMotionNodeModelTotalShippedChanged			= @"ORMotionNodeModelTotalShippedChanged";
NSString* ORMotionNodeModelLastRecordShippedChanged		= @"ORMotionNodeModelLastRecordShippedChanged";
NSString* ORMotionNodeModelOutOfBandChanged				= @"ORMotionNodeModelOutOfBandChanged";
NSString* ORMotionNodeModelShipExcursionsChanged		= @"ORMotionNodeModelShipExcursionsChanged";
NSString* ORMotionNodeModelShipThresholdChanged			= @"ORMotionNodeModelShipThresholdChanged";
NSString* ORMotionNodeModelAutoStartChanged				= @"ORMotionNodeModelAutoStartChanged";
NSString* ORMotionNodeModelShowLongTermDeltaChanged		= @"ORMotionNodeModelShowLongTermDeltaChanged";
NSString* ORMotionNodeModelLongTermSensitivityChanged	= @"ORMotionNodeModelLongTermSensitivityChanged";
NSString* ORMotionNodeModelStartTimeChanged				= @"ORMotionNodeModelStartTimeChanged";
NSString* ORMotionNodeModelShowDeltaFromAveChanged		= @"ORMotionNodeModelShowDeltaFromAveChanged";
NSString* ORMotionNodeModelDisplayComponentsChanged		= @"ORMotionNodeModelDisplayComponentsChanged";
NSString* ORMotionNodeModelTemperatureChanged			= @"ORMotionNodeModelTemperatureChanged";
NSString* ORMotionNodeModelNodeRunningChanged			= @"ORMotionNodeModelNodeRunningChanged";
NSString* ORMotionNodeModelTraceIndexChanged			= @"ORMotionNodeModelTraceIndexChanged";
NSString* ORMotionNodeModelPacketLengthChanged			= @"ORMotionNodeModelPacketLengthChanged";
NSString* ORMotionNodeModelIsAccelOnlyChanged			= @"ORMotionNodeModelIsAccelOnlyChanged";
NSString* ORMotionNodeModelVersionChanged				= @"ORMotionNodeModelVersionChanged";
NSString* ORMotionNodeModelLock							= @"ORMotionNodeModelLock";
NSString* ORMotionNodeModelSerialNumberChanged			= @"ORMotionNodeModelSerialNumberChanged";
NSString* ORMotionNodeModelUpdateLongTermTrace			= @"ORMotionNodeModelUpdateLongTermTrace";

#define kMotionNodeDriverPath @"/System/Library/Extensions/SLAB_USBtoUART.kext"
#define kMotionNodeAveN (2/(100.+1.))

#define kSlope		 (4.0/4095.0)
#define kIntercept	 (-2.0)

#define kPtPerSec 100
#define kSecToShip 5
#define kPerTrigger 1 //sec


static MotionNodeCommands motionNodeCmds[kNumMotionNodeCommands] = {
	{kMotionNodeConnectResponse,@"0",		14,		NO},
	{kMotionNodeMemoryContents,	@"rrr",		256,	NO}, 
	{kMotionNodeStop,			@")",		-1,		YES}, 
	{kMotionNodeStart,			@"xxx\0",	-1,		YES},
	{kMotionNodeClosePort,		@"",		-1,		NO}
};

static MotionNodeCalibrations motionNodeCalibration[3] = {
	{-2.528, 0.001205}, //z (blue)
	{-2.497, 0.00123}, //y (green)
	{-2.536, 0.00123}, //x (red)
//{-2.0, 0.000976801}, //Z
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
- (void) checkForDriver;
- (void) createLongTermTraceStorage;
@end


@implementation ORMotionNodeModel
- (id) init
{
	self = [super init];
	[self checkForDriver];
	[self createLongTermTraceStorage];
	shipThreshold = .2;
	return self;
}

- (void) dealloc
{
    [lastRecordShipped release];
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
	
	if(longTermTrace){
		int i;
		for (i = 0; i < kNumMin; i++) free(longTermTrace[i]);
		free(longTermTrace);
		longTermTrace = nil;
		longTermValid = NO;
	}
	[super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	[self createLongTermTraceStorage];
}

- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];        
    [notifyCenter addObserver : self
                     selector : @selector(runStarting:)
                         name : ORRunAboutToStartNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(runStopping:)
                         name : ORRunAboutToStopNotification
                       object : nil];
}

- (void) runStarting:(NSNotification*)aNote
{
	if(autoStart){
		if(![serialPort isOpen])[self openPort:YES];
		if(!nodeRunning)[self startDevice];
	}
	scheduledToShip = NO;
	[self setTotalShipped:0];

}

- (void) runStopping:(NSNotification*)aNote
{
	if(scheduledToShip)[self shipXYZTrace];
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

- (NSString*) helpURL
{
	return @"USB/Motion_Node.html";
}


#pragma mark ***Accessors

- (int) totalShipped
{
    return totalShipped;
}

- (void) setTotalShipped:(int)aTotalShipped
{
    totalShipped = aTotalShipped;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelTotalShippedChanged object:self];
}

- (NSDate*) lastRecordShipped
{
    return lastRecordShipped;
}

- (void) setLastRecordShipped:(NSDate*)aLastRecordShipped
{
    [aLastRecordShipped retain];
    [lastRecordShipped release];
    lastRecordShipped = aLastRecordShipped;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelLastRecordShippedChanged object:self];
}

- (BOOL) outOfBand
{
    return outOfBand;
}

- (void) setOutOfBand:(BOOL)aOutOfBand
{
	if(aOutOfBand!=outOfBand){
		outOfBand = aOutOfBand;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelOutOfBandChanged object:self];
	}
}

- (BOOL) shipExcursions
{
    return shipExcursions;
}

- (void) setShipExcursions:(BOOL)aShipExcursions
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipExcursions:shipExcursions];
    
    shipExcursions = aShipExcursions;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelShipExcursionsChanged object:self];
}

- (float) shipThreshold
{
    return shipThreshold;
}

- (void) setShipThreshold:(float)aShipThreshold
{
	if(aShipThreshold <.001)aShipThreshold = .001;
	else if(aShipThreshold > 2)aShipThreshold = 2;
    [[[self undoManager] prepareWithInvocationTarget:self] setShipThreshold:shipThreshold];
    
    shipThreshold = aShipThreshold;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelShipThresholdChanged object:self];
}

- (BOOL) autoStart
{
    return autoStart;
}

- (void) setAutoStart:(BOOL)aAutoStart
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoStart:autoStart];
    
    autoStart = aAutoStart;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelAutoStartChanged object:self];
}

- (BOOL) showLongTermDelta
{
    return showLongTermDelta;
}

- (void) setShowLongTermDelta:(BOOL)aShowLongTermDelta
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowLongTermDelta:showLongTermDelta];
    
    showLongTermDelta = aShowLongTermDelta;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMotionNodeModelShowLongTermDeltaChanged object:self];
}

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
    [self setShipExcursions:		[decoder decodeBoolForKey:@"shipExcursions"]];
    [self setShipThreshold:			[decoder decodeFloatForKey:@"shipThreshold"]];
    [self setAutoStart:				[decoder decodeBoolForKey:@"autoStart"]];
    [self setShowLongTermDelta:		[decoder decodeBoolForKey:@"showLongTermDelta"]];
    [self setLongTermSensitivity:	[decoder decodeIntForKey:@"longTermSensitivity"]];
    [self setShowDeltaFromAve:		[decoder decodeBoolForKey:@"showDeltaFromAve"]];
    [self setDisplayComponents:		[decoder decodeBoolForKey:@"displayComponents"]];
	
    [[self undoManager] enableUndoRegistration];    
	cmdQueue = [[ORSafeQueue alloc] init];
	
	[self checkForDriver];
	[self createLongTermTraceStorage];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:shipExcursions		forKey:@"shipExcursions"];
    [encoder encodeFloat:shipThreshold		forKey:@"shipThreshold"];
    [encoder encodeBool:autoStart			forKey:@"autoStart"];
    [encoder encodeBool:showLongTermDelta	forKey:@"showLongTermDelta"];
    [encoder encodeInt:longTermSensitivity	forKey:@"longTermSensitivity"];
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
	scheduledToShip = NO;
	longTraceValueToKeep = 0;
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

- (int) startingLine
{
	return longTraceMinIndex;
}

- (int) maxLinesInLongTermView
{
	return kNumMin;
}

- (int) numLinesInLongTermView
{
	if(cycledOnce) return kNumMin;
	else return longTraceMinIndex+1;
}

- (int) numPointsPerLineInLongTermView
{
	return kModeNodeLongTraceLength;
}

- (float)longTermDataAtLine:(int)m point:(int)i
{
	if(longTermValid){
		if(showLongTermDelta && i>0){
			return (longTermTrace[m][(i-1)] - longTermTrace[m][i])  * longTermSensitivity;
		}
		else return longTermTrace[m][i]*longTermSensitivity;
	}
	else return 0;
}

#pragma mark •••Data Records
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherPDcu
{
    [self setDataId:[anotherPDcu dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORMotionNodeModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORMotionNodeDecoderForXYZTrace",	@"decoder",
								 [NSNumber numberWithLong:dataId],  @"dataId",
								 [NSNumber numberWithBool:YES],     @"variable",
								 [NSNumber numberWithLong:-1],		@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"XYZTrace"];
    
    return dataDictionary;
}


- (void) shipXYZTrace
{
	scheduledToShip = NO;
    if([[ORGlobal sharedGlobal] runInProgress]){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(shipXYZTrace) object:nil];

		//get the time(UT!)
		time_t	ut_Time;
		time(&ut_Time);
		//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
		int shipLen = kSecToShip * kPtPerSec;
		
		int backIndex = (excursionIndex - kPerTrigger*kPtPerSec);
		if(backIndex<0)backIndex = kModeNodeTraceLength + backIndex; //wrap it
		
		int type;
		for(type=0;type<3;type++){
			unsigned long data[3 + (kSecToShip * kPtPerSec)];
			data[0] = dataId | (3 + shipLen);
			data[1] = ((type&0x3)<<16) | ([self uniqueIdNumber]&0xfff); // xtrace
			data[2] = ut_Time;
			int i;
			float slope		= motionNodeCalibration[type].slope;
			float intercept = motionNodeCalibration[type].intercept;
			for(i=0;i<shipLen;i++){
				if(type==0)		data[3+i] = (xTrace[(backIndex+i)%kModeNodeTraceLength] - intercept)/slope;
				else if(type==1)data[3+i] = (yTrace[(backIndex+i)%kModeNodeTraceLength] - intercept)/slope;
				else if(type==2)data[3+i] = (zTrace[(backIndex+i)%kModeNodeTraceLength] - intercept)/slope;
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:&data length:sizeof(long)*(3+shipLen)]];
		}
		[self setTotalShipped:[self totalShipped]+1];
		[self setLastRecordShipped:[NSDate date]];
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
		
		
		// accel 0
		rawData.bytes[highBtyeIndex] = (data[2] >> 4) & rMask;
		rawData.bytes[lowBtyeIndex] = data[1];			
		
		[self setAz:motionNodeCalibration[0].slope * rawData.unpacked + motionNodeCalibration[0].intercept];
		
		// accel 1
		rawData.bytes[highBtyeIndex] = data[3] & rMask;
		rawData.bytes[lowBtyeIndex] = ((data[2] << 4) & lMask) | ((data[3] >> 4) & rMask);
		[self setAy:motionNodeCalibration[1].slope * rawData.unpacked + motionNodeCalibration[1].intercept];
		
		// accel 2
		rawData.bytes[highBtyeIndex] = (data[5] >> 4) & rMask;
		rawData.bytes[lowBtyeIndex] = data[4];
		[self setAx:motionNodeCalibration[2].slope * rawData.unpacked + motionNodeCalibration[2].intercept];
		
		
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
		NSLogError(@"Motion Node",@"command timeout",nil);
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
	xyzTrace[traceIndex] = 1 - sqrtf(ax*ax + ay*ay + az*az);
	if(traceIndex>0){
		float delta = xyzTrace[(traceIndex)%kModeNodeTraceLength] - xyzTrace[(traceIndex-1)%kModeNodeTraceLength];
		if(shipExcursions){
			BOOL shouldShip = fabs(delta)>shipThreshold;
			if(shouldShip){
				if(!scheduledToShip){
					excursionIndex = traceIndex;
					[self performSelector:@selector(shipXYZTrace) withObject:nil afterDelay:kSecToShip-kPerTrigger];
					scheduledToShip = YES;
				}
			}
			[self setOutOfBand:shouldShip];
		}
	}
	
	if(longTermValid){
		if(fabs(xyzTrace[traceIndex]) > fabs(longTraceValueToKeep)){
			longTraceValueToKeep = xyzTrace[traceIndex];
		}
		if(!(traceIndex%kModeNodePtsToCombine)){				
			longTermTrace[longTraceMinIndex][longTraceIndex] = longTraceValueToKeep;
			longTraceValueToKeep = 0;
			longTraceIndex = (longTraceIndex+1)%kModeNodeLongTraceLength;
			if(longTraceIndex==kModeNodeLongTraceLength-1){
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

- (void) checkForDriver
{
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
- (void) createLongTermTraceStorage
{
	if(!longTermValid){
		//alloc a large 2-D array for the long term storage
		int i;
		longTermTrace = malloc(kNumMin * sizeof(float *));
		for (i = 0; i < kNumMin; i++) {
			longTermTrace[i] = malloc(kModeNodeLongTraceLength * sizeof(float));
			memset(longTermTrace[i],0,kModeNodeLongTraceLength * sizeof(float));
		}
		longTermValid = YES;
	}
}
@end
