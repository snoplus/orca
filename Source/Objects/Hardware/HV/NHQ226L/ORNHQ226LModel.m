
// ORNHQ226LModel.cpp
// Orca
//
//  Created by Mark Howe on Tues Sept 14,2010.
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
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
#import "ORNHQ226LModel.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"

#pragma mark •••Notification Strings
NSString* ORNHQ226LModelSerialPortChanged	= @"ORNHQ226LModelSerialPortChanged";
NSString* ORNHQ226LModelPortNameChanged		= @"ORNHQ226LModelPortNameChanged";
NSString* ORNHQ226LModelPortStateChanged	= @"ORNHQ226LModelPortStateChanged";
NSString* ORNHQ226LModelPollingErrorChanged = @"ORNHQ226LModelPollingErrorChanged";
NSString* ORNHQ226LModelStatusReg1Changed	= @"ORNHQ226LModelStatusReg2Changed";
NSString* ORNHQ226LModelStatusReg2Changed	= @"ORNHQ226LModelStatusReg2Changed";
NSString* ORNHQ226LSettingsLock				= @"ORNHQ226LSettingsLock";
NSString* ORNHQ226LSetVoltageChanged		= @"ORNHQ226LSetVoltageChanged";
NSString* ORNHQ226LActVoltageChanged		= @"ORNHQ226LActVoltageChanged";
NSString* ORNHQ226LRampRateChanged			= @"ORNHQ226LRampRateChanged";
NSString* ORNHQ226LPollTimeChanged			= @"ORNHQ226LPollTimeChanged";
NSString* ORNHQ226LModelTimeOutErrorChanged	= @"ORNHQ226LModelTimeOutErrorChanged";
NSString* ORNHQ226LActCurrentChanged		= @"ORNHQ226LActCurrentChanged";
NSString* ORNHQ226LMaxCurrentChanged		= @"ORNHQ226LMaxCurrentChanged";
NSString* ORNHQ226LModelTimeout				= @"ORNHQ226LModelTimeout";

@implementation ORNHQ226LModel

- (id) init //designated initializer
{
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];
		
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [buffer release];
	[cmdQueue release];
	[lastRequest release];
    [portName release];
	[inComingData release];
    if([serialPort isOpen]){
        [serialPort close];
    }
	[serialPort setDelegate:nil];
	[serialPort release];
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"NHQ226L"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORNHQ226LController"];
}

- (NSString*) helpURL
{
	return @"VME/NHQ226L.html";
}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataReceived:)
                         name : ORSerialPortDataReceived
                       object : nil];
}
#pragma mark •••Accessors

- (BOOL) pollingError
{
    return pollingError;
}

- (void) setPollingError:(BOOL)aPollingError
{
	if(pollingError!= aPollingError){
		pollingError = aPollingError;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelPollingErrorChanged object:self];
	}
}

- (unsigned short) statusReg1Chan:(unsigned short)aChan
{
	if(aChan>=kNumNHQ226LChannels)return 0;
    return statusReg1Chan[aChan];
}

- (void) setStatusReg1Chan:(unsigned short)aChan withValue:(unsigned short)aStatusWord
{
	if(aChan>=kNumNHQ226LChannels)return;
	if(statusReg1Chan[aChan] != aStatusWord || useStatusReg1Anyway[aChan]){
		statusChanged = YES;
		statusReg1Chan[aChan] = aStatusWord;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelStatusReg1Changed object:self userInfo:userInfo];
		useStatusReg1Anyway[aChan] = NO;
	}
}

- (unsigned short) statusReg2Chan:(unsigned short)aChan
{
	if(aChan>=kNumNHQ226LChannels)return 0;
    return statusReg2Chan[aChan];
}

- (void) setStatusReg2Chan:(unsigned short)aChan withValue:(unsigned short)aStatusWord
{
	if(aChan>=kNumNHQ226LChannels)return;
	if(statusReg2Chan[aChan] != aStatusWord){
		statusChanged = YES;
		statusReg2Chan[aChan] = aStatusWord;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelStatusReg2Changed object:self userInfo:userInfo];
	}
}

- (void) setTimeErrorState:(BOOL)aState
{
	if(timeOutError != aState){
		timeOutError = aState;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelTimeOutErrorChanged object:self];
	}
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LPollTimeChanged object:self];
}

- (float) voltage:(unsigned short) aChan
{
	if(aChan>=kNumNHQ226LChannels)return 0;
    return voltage[aChan];
}

- (void) setVoltage:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumNHQ226LChannels)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setVoltage:aChan withValue:voltage[aChan]];
	voltage[aChan] = aVoltage;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LSetVoltageChanged object:self userInfo: nil];
}

- (float) actVoltage:(unsigned short) aChan
{
	if(aChan>=kNumNHQ226LChannels)return 0;
    return actVoltage[aChan];
}

- (void) setActVoltage:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumNHQ226LChannels)return;
	if(actVoltage[aChan] != aVoltage){
		if(fabs(actVoltage[aChan]-aVoltage)>1){
			statusChanged = YES;
		}
		actVoltage[aChan] = aVoltage;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LActVoltageChanged object:self userInfo: userInfo];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelStatusReg1Changed object:self userInfo: userInfo]; //also send this to force some updates
	}
}

- (float) actCurrent:(unsigned short) aChan
{
	if(aChan>=kNumNHQ226LChannels)return 0;
    return actCurrent[aChan];
}

- (void) setActCurrent:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumNHQ226LChannels)return;
	if(actCurrent[aChan] != aCurrent){
		statusChanged = YES;
		actCurrent[aChan] = aCurrent;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LActCurrentChanged object:self userInfo: userInfo];
	}
}

- (float) maxCurrent:(unsigned short) aChan
{
	if(aChan>=kNumNHQ226LChannels)return 0;
    return maxCurrent[aChan];
}

- (void) setMaxCurrent:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumNHQ226LChannels)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setVoltage:aChan withValue:voltage[aChan]];
	maxCurrent[aChan] = aCurrent;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LMaxCurrentChanged object:self userInfo: nil];
}

- (unsigned short) rampRate:(unsigned short) aChan
{
	if(aChan>=kNumNHQ226LChannels)return 2;
	return rampRate[aChan];
}

- (void) setRampRate:(unsigned short) aChan withValue:(unsigned short) aRampRate
{
	if(aChan>=kNumNHQ226LChannels)return;
	
	if(aRampRate<2)aRampRate = 2;
	else if(aRampRate>255)aRampRate = 255;
	
	[[[self undoManager] prepareWithInvocationTarget:self] setVoltage:aChan withValue:[self voltage:aChan]];
	rampRate[aChan] = aRampRate;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LRampRateChanged object:self userInfo: nil];
}

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

#pragma mark •••Hardware Access
- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollTime == 0 )return;
    [[self undoManager] disableUndoRegistration];
	@try {
		[self readStatusWord:0];
		[self readStatusWord:1];
		[self readModuleStatus:0];
		[self readModuleStatus:1];
		[self readActVoltage:0];
		[self readActVoltage:1];
		[self readActCurrent:0];
		[self readActCurrent:1];
		if(statusChanged)[self shipVoltageRecords];
		[self setPollingError:NO];
	}
	@catch(NSException* e){
		[self setPollingError:YES];
		NSLogError(@"",@"NHQ226L",@"Polling Error",nil);
	}
	
    [[self undoManager] enableUndoRegistration];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (void) initBoard
{
}

- (void) loadValues:(unsigned short)aChannel
{
	useStatusReg1Anyway[aChannel] = YES; //force an update
	
	if(aChannel>=kNumNHQ226LChannels)return;
	//set the ramp rate
	//set voltage
	//set maxCurrent

}

- (void) stopRamp:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return;
	[self readActCurrent:aChannel];
	//unsigned short aValue = (unsigned short)actVoltage[aChannel];
	
}

- (void) panicToZero:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return;
	//unsigned short aValue;
	//set the ramp rate
	//unsigned short panicRate = 255;
	//set ramp speed
	//set startvoltage to zero
}


- (void) readStatusWord:(unsigned short)aChan
{
	NSString* cmd = [NSString stringWithFormat:@"S%d",aChan];
	[self sendCmd:cmd];
}

- (void) readModuleStatus:(unsigned short)aChan
{
	NSString* cmd = [NSString stringWithFormat:@"T%d",aChan];
	[self sendCmd:cmd];
}

- (void) readActVoltage:(unsigned short)aChan
{
	NSString* cmd = [NSString stringWithFormat:@"U%d",aChan];
	[self sendCmd:cmd];
}

- (void) readActCurrent:(unsigned short)aChan
{
	NSString* cmd = [NSString stringWithFormat:@"I%d",aChan];
	[self sendCmd:cmd];
}


- (void) readModuleID
{
	unsigned short aValue = 0;
	unsigned short serialNumber =	(aValue>>12)*1000 + 
									((aValue&0x0f00)>>8)*100 + 
									((aValue&0x00f0)>>4) *10 + 
									(aValue &0x000f);
	NSLog(@"NHQ226L (%d) Serial Number = %d\n", [self uniqueIdNumber], serialNumber);
}

#pragma mark •••Helpers
- (NSString*) rampStateString:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return @"";
	if(!(statusReg1Chan[aChannel] & kHVSwitch)){
		if(statusReg1Chan[aChannel] & kStatV) {
			if(statusReg1Chan[aChannel] & kTrendV)	return @"Rising  ";
			else									return @"Falling ";
		}
		else {
			if(!(statusReg1Chan[aChannel] & kVZOut)) return @"Stable  ";
			else return @"HV OFF  ";
		}
	}
	else return kHVOff;
}

- (eNHQ226LRampingState) rampingState:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return kHVOff;
	if(!(statusReg1Chan[aChannel] & kHVSwitch)){
		if(statusReg1Chan[aChannel] & kStatV) {
			if(statusReg1Chan[aChannel] & kTrendV)	return kHVRampingUp;
			else									return kHVRampingDn;
		}
		else {
			if(!(statusReg1Chan[aChannel] & kVZOut))return kHVStableHigh;
			else {
				if(actVoltage[aChannel]>2)return kHVStableLow;
				else return kHVOff;
			}
		}
	}
	else return kHVOff;
}

- (BOOL) polarity:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return 0;
	return statusReg1Chan[aChannel] & kHVPolarity;
}

- (BOOL) hvPower:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return 0;
	return !(statusReg1Chan[aChannel] & kHVSwitch); //reversed so YES is power on
}

- (BOOL) killSwitch:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return 0;
	return (statusReg1Chan[aChannel] & kKillSwitch); 
}

- (BOOL) currentTripped:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return 0;
	return (statusReg2Chan[aChannel] & kCurrentExceeded); 
}

- (BOOL) controlState:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return NO;
	return !(statusReg1Chan[aChannel] & kHVControl);
}

- (BOOL) extInhibitActive:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return NO;
	return (statusReg2Chan[aChannel] & kInibitActive);
}


#pragma mark •••Header Stuff
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"NHQ226LModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORNHQ226LDecoderForHVStatus",                 @"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:NO],                   @"variable",
								 [NSNumber numberWithLong:11],					 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"HVStatus"];
    return dataDictionary;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	int i;	
	for(i=0;i<kNumNHQ226LChannels;i++){
		[self setVoltage:i withValue:   [decoder decodeFloatForKey:[NSString stringWithFormat:@"voltage%d",i]]];
		[self setMaxCurrent:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"maxCurrent%d",i]]];
		[self setRampRate:i withValue:  [decoder decodeIntForKey:  [NSString stringWithFormat:@"rampRate%d",i]]];
	}
	[self setPortWasOpen:	[decoder decodeBoolForKey:	 @"portWasOpen"]];
    [self setPortName:		[decoder decodeObjectForKey: @"portName"]];
	[self setPollTime:[decoder decodeIntForKey:@"pollTime"]];
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	int i;	
	for(i=0;i<kNumNHQ226LChannels;i++){
		[encoder encodeFloat:voltage[i]    forKey:[NSString stringWithFormat:@"voltage%d",i]];
		[encoder encodeFloat:maxCurrent[i] forKey:[NSString stringWithFormat:@"maxCurrent%d",i]];
		[encoder encodeInt:rampRate[i]     forKey:[NSString stringWithFormat:@"rampRate%d",i]];
	}
    [encoder encodeBool:portWasOpen		forKey: @"portWasOpen"];
    [encoder encodeObject:portName		forKey: @"portName"];
	[encoder encodeInt:pollTime			forKey:@"pollTime"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	NSArray* status1 = [NSArray arrayWithObjects:[NSNumber numberWithInt:statusReg1Chan[0]],[NSNumber numberWithInt:statusReg1Chan[1]],nil];
    [objDictionary setObject:status1 forKey:@"StatusReg1"];	

	NSArray* status2 = [NSArray arrayWithObjects:[NSNumber numberWithInt:statusReg2Chan[0]],[NSNumber numberWithInt:statusReg2Chan[1]],nil];
    [objDictionary setObject:status2 forKey:@"StatusReg2"];
	
	NSArray* theActVoltages = [NSArray arrayWithObjects:[NSNumber numberWithFloat:actVoltage[0]],[NSNumber numberWithFloat:actVoltage[1]],nil];
    [objDictionary setObject:theActVoltages forKey:@"Voltages"];
	
	NSArray* theActCurrents = [NSArray arrayWithObjects:[NSNumber numberWithFloat:actCurrent[0]],[NSNumber numberWithFloat:actCurrent[1]],nil];
    [objDictionary setObject:theActCurrents forKey:@"Currents"];
     	
	return objDictionary;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherNHQ226L
{
    [self setDataId:[anotherNHQ226L dataId]];
}

#pragma mark •••RecordShipper
- (void) shipVoltageRecords
{
	if([[ORGlobal sharedGlobal] runInProgress]){
		//get the time(UT!)
		time_t	ut_Time;
		time(&ut_Time);
		//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
		
		unsigned long data[11];
		data[0] = dataId | 11;
		data[1] = [self uniqueIdNumber]&0xfff;
		data[2] = ut_Time;
		
		union {
			float asFloat;
			unsigned long asLong;
		}theData;
		int index = 3;
		int i;
		for(i=0;i<2;i++){
			data[index++] = statusReg1Chan[i];
			data[index++] = statusReg2Chan[i];

			theData.asFloat = actVoltage[i];
			data[index++] = theData.asLong;

			theData.asFloat = actCurrent[i];
			data[index++] = theData.asLong;
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(long)*11]];
	}	
	statusChanged = NO;
}

#pragma mark •••Serial Port
- (void) sendCmd:(NSString*)aCommand
{
	if([serialPort isOpen]){
		if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
		[cmdQueue addObject:[aCommand stringByAppendingString:@"\r\n"]];
		if(!lastRequest)[self processOneCommandFromQueue];	
	}
}

- (NSString*) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(NSString*)aRequest
{
	[aRequest retain];
	[lastRequest release];
	lastRequest = aRequest;    
}

- (BOOL) portWasOpen
{
    return portWasOpen;
}

- (void) setPortWasOpen:(BOOL)aPortWasOpen
{
    portWasOpen = aPortWasOpen;
}

- (NSString*) portName
{
    return portName;
}

- (void) setPortName:(NSString*)aPortName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortName:portName];
    
    if(![aPortName isEqualToString:portName]){
        [portName autorelease];
        portName = [aPortName copy];    
		
        BOOL valid = NO;
        NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
        ORSerialPort *aPort;
        while (aPort = [enumerator nextObject]) {
            if([portName isEqualToString:[aPort name]]){
                [self setSerialPort:aPort];
                if(portWasOpen){
                    [self openPort:YES];
				}
                valid = YES;
                break;
            }
        } 
        if(!valid){
            [self setSerialPort:nil];
        }       
    }
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelPortNameChanged object:self];
}

- (ORSerialPort*) serialPort
{
    return serialPort;
}

- (void) setSerialPort:(ORSerialPort*)aSerialPort
{
    [aSerialPort retain];
    [serialPort release];
    serialPort = aSerialPort;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelSerialPortChanged object:self];
}

- (void) openPort:(BOOL)state
{
    if(state) {
		[serialPort setSpeed:9600];
		[serialPort setParityNone];
		[serialPort setStopBits2:NO];
		[serialPort setDataBits:8];
		[serialPort commitChanges];
		
        [serialPort open];
		[serialPort setDelegate:self];
		
	}
    else {
		[serialPort close];
		[cmdQueue removeAllObjects];
	}
    portWasOpen = [serialPort isOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelPortStateChanged object:self];
}

- (void) dataReceived:(NSNotification*)note
{
	BOOL done = NO;
	if(!lastRequest){
		done = YES;
	}
    else if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		if(!inComingData)inComingData = [[NSMutableData data] retain];
        [inComingData appendData:[[note userInfo] objectForKey:@"data"]];
		//NSString* theLastCommand = [lastRequest uppercaseString];
		
		NSString* theResponse = [[[[NSString alloc] initWithData: inComingData 
														encoding: NSASCIIStringEncoding] autorelease] uppercaseString];
		if(theResponse){
			if([theResponse hasPrefix:@"?"]){
				done = YES;
				//handle error
				NSLog(@"Got Error.\n");
			}
			else {
				NSArray* parts = [theResponse componentsSeparatedByString:@"\r\n"];
				if([parts count] == 3){
					NSLog(@"Got good response.\n");
					NSLog(@"%@\n",parts);
					done = YES;
				}
			}
		}
	}
	if(done){
		[inComingData release];
		inComingData = nil;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
		[self setLastRequest:nil];			 //clear the last request
		[self processOneCommandFromQueue];	 //do the next command in the queue
	}	
}

- (void) timeout
{
	doSync[0] = NO;
	doSync[1] = NO;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	NSLogError(@"NHQ226L",@"command timeout",nil);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelTimeout object:self];
	[self setLastRequest:nil];
	[cmdQueue removeAllObjects];
	[inComingData release];
	inComingData = nil;
	[self processOneCommandFromQueue];	 //do the next command in the queue
}

- (void) processOneCommandFromQueue
{
	if([cmdQueue count] == 0) return;
	NSString* cmdString = [[[cmdQueue objectAtIndex:0] retain] autorelease];
	[cmdQueue removeObjectAtIndex:0];
	
	[self setLastRequest:cmdString];
	[serialPort writeDataInBackground:[cmdString dataUsingEncoding:NSASCIIStringEncoding]];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:1];
}

- (void) serialPortWriteProgress:(NSDictionary *)dataDictionary;
{
}

- (void) syncDialog
{
	int i;
	for(i=0;i<2;i++)doSync[i] = YES;
	[self getAllValues];
}

- (void) getAllValues
{
	[[self undoManager] disableUndoRegistration];
	int i;
	for(i=0;i<2;i++){
		//[self getOutput:i];
		[self readActVoltage:i];
		[self readActCurrent:i];
		if(statusChanged)[self shipVoltageRecords];
	}
	
    [[self undoManager] enableUndoRegistration];
}

@end
