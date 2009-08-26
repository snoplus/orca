//
//  ORAmrelHVModel.m
//  Orca
//
//  Created by Mark Howe on Thursday, Aug 20,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "ORAmrelHVModel.h"

#import "ORHVRampItem.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORSerialPortList.h"
#import "ORDataPacket.h"

NSString* ORAmrelHVModelOutputStateChanged = @"ORAmrelHVModelOutputStateChanged";
NSString* ORAmrelHVModelNumberOfChannelsChanged = @"ORAmrelHVModelNumberOfChannelsChanged";
NSString* ORAmrelHVSetVoltageChanged		= @"ORAmrelHVSetVoltageChanged";
NSString* ORAmrelHVActVoltageChanged		= @"ORAmrelHVActVoltageChanged";
NSString* ORAmrelHVModelRampRateChanged		= @"ORAmrelHVModelRampRateChanged";
NSString* ORAmrelHVPollTimeChanged			= @"ORAmrelHVPollTimeChanged";
NSString* ORAmrelHVModelTimeOutErrorChanged	= @"ORAmrelHVModelTimeOutErrorChanged";
NSString* ORAmrelHVActCurrentChanged		= @"ORAmrelHVActCurrentChanged";
NSString* ORAmrelHVMaxCurrentChanged		= @"ORAmrelHVMaxCurrentChanged";
NSString* ORAmrelHVLock						= @"ORAmrelHVLock";
NSString* ORAmrelHVModelSerialPortChanged	= @"ORAmrelHVModelSerialPortChanged";
NSString* ORAmrelHVModelPortNameChanged		= @"ORAmrelHVModelPortNameChanged";
NSString* ORAmrelHVModelPortStateChanged	= @"ORAmrelHVModelPortStateChanged";
NSString* ORAmrelHVPolarityChanged			= @"ORAmrelHVPolarityChanged";

@interface ORAmrelHVModel (private)
- (void) timeout;
- (void) processOneCommandFromQueue;
@end

#define kGetActualVoltageCmd	@"MEAS:VOLT?"
#define kGetActualCurrentCmd	@"MEAS:CURR?"
#define kSetVoltageCmd			@"VOLT:LEV"
#define kSetMaxCurrentCmd		@"CURR:TRIG"
#define kSetOutputCmd			@"OUTP:STAT"
#define kGetOutputCmd			@"OUTP:STAT?"
#define kSetPolarityCmd			@"OUTP:REL:POL"
#define kGetPolarityCmd			@"OUTP:REL:POL?"

@implementation ORAmrelHVModel

- (void) makeMainController
{
    [self linkToController:@"ORAmrelHVController"];
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
    [serialPort release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"AmrelHV"]];
}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(dataReceived:)
                         name : ORSerialPortDataReceived
                       object : nil];
}

#pragma mark ***Accessors
- (int) rampRate:(unsigned short)aChan
{
	if(aChan<2) return rampRate[aChan];
	else        return 0;
}

- (void) setRampRate:(unsigned short)aChan withValue:(int)aRate;
{
	if(aChan<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setRampRate:aChan withValue:rampRate[aChan]];
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		rampRate[aChan] = aRate;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelRampRateChanged object:self userInfo:userInfo];
	}
}

- (BOOL) outputState:(unsigned short) aChan
{
	if(aChan<2) return outputState[aChan];
	else        return 0;
}

- (void) setOutputState:(unsigned short)aChan withValue:(BOOL)aOutputState
{
	if(aChan<2){
		if(aOutputState != outputState[aChan]) {
			statusChanged = YES;
		}
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		outputState[aChan] = aOutputState;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelOutputStateChanged object:self userInfo:userInfo];
	}
	if(outputState[aChan] && pollTime == 0){
		[self setPollTime:1];
	}
}

- (int) numberOfChannels
{
	if(numberOfChannels==0)numberOfChannels=1;
    return numberOfChannels;
}

- (void) setNumberOfChannels:(int)aNumberOfChannels
{
	if(aNumberOfChannels==0)aNumberOfChannels = 1;
	else if(aNumberOfChannels>2)aNumberOfChannels=2;
    [[[self undoManager] prepareWithInvocationTarget:self] setNumberOfChannels:numberOfChannels];
    numberOfChannels = aNumberOfChannels;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelNumberOfChannelsChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVPollTimeChanged object:self];
}

- (BOOL) polarity:(unsigned short) aChan
{
	if(aChan>=kNumAmrelHVChannels)return 0;
    return polarity[aChan];
}

- (void)  setPolarity:(unsigned short) aChan withValue:(BOOL) aState
{
	if(aChan>=kNumAmrelHVChannels)return;
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[[self undoManager] prepareWithInvocationTarget:self] setPolarity:aChan withValue:polarity[aChan]];
	polarity[aChan] = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVPolarityChanged object:self  userInfo:userInfo];
}

- (float) voltage:(unsigned short) aChan
{
	if(aChan>=kNumAmrelHVChannels)return 0;
    return voltage[aChan];
}

- (void) setVoltage:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumAmrelHVChannels)return;
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[[self undoManager] prepareWithInvocationTarget:self] setVoltage:aChan withValue:voltage[aChan]];
	voltage[aChan] = aVoltage;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVSetVoltageChanged object:self  userInfo:userInfo];
}

- (float) actVoltage:(unsigned short) aChan
{
	if(aChan>=kNumAmrelHVChannels)return 0;
    return actVoltage[aChan];
}

- (void) setActVoltage:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumAmrelHVChannels)return;
	if(actVoltage[aChan] != aVoltage){
		if(fabs(actVoltage[aChan]-aVoltage)>1){
			statusChanged = YES;
		}
		actVoltage[aChan] = aVoltage;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVActVoltageChanged object:self userInfo: userInfo];
	}
}

- (float) actCurrent:(unsigned short) aChan
{
	if(aChan>=kNumAmrelHVChannels)return 0;
    return actCurrent[aChan];
}

- (void) setActCurrent:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumAmrelHVChannels)return;
	if(actCurrent[aChan] != aCurrent){
		statusChanged = YES;
		actCurrent[aChan] = aCurrent;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVActCurrentChanged object:self userInfo: userInfo];
	}
}

- (float) maxCurrent:(unsigned short) aChan
{
	if(aChan>=kNumAmrelHVChannels)return 0;
    return maxCurrent[aChan];
}

- (void) setMaxCurrent:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumAmrelHVChannels)return;
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[[self undoManager] prepareWithInvocationTarget:self] setVoltage:aChan withValue:voltage[aChan]];
	maxCurrent[aChan] = aCurrent;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVMaxCurrentChanged object:self  userInfo:userInfo];
}


- (NSString*) lockName
{
	return ORAmrelHVLock;
}

- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollTime == 0 )return;
	[self getAllValues];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (void) getAllValues
{
	[[self undoManager] disableUndoRegistration];
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		[self getOutput:i];
		[self getActualVoltage:i];
		[self getActualCurrent:i];
	}
	if(statusChanged)[self shipVoltageRecords];
	
    [[self undoManager] enableUndoRegistration];
}

- (void) shipVoltageRecords
{
	if([[ORGlobal sharedGlobal] runInProgress]){
		//get the time(UT!)
		time_t	theTime;
		time(&theTime);
		struct tm* theTimeGMTAsStruct = gmtime(&theTime);
		
		unsigned long data[11];
		data[0] = dataId | 11;
		data[1] = [self uniqueIdNumber]&0xfff;
		data[2] = mktime(theTimeGMTAsStruct);
		
		union {
			float asFloat;
			unsigned long asLong;
		}theData;
		int index = 3;
		int i;
		for(i=0;i<2;i++){
			
			theData.asFloat = actVoltage[i];
			data[index++] = theData.asLong;
			
			theData.asFloat = actCurrent[i];
			data[index++] = theData.asLong;
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:&data length:sizeof(long)*11]];
	}	
	statusChanged = NO;
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setNumberOfChannels:[decoder decodeIntForKey:@"numberOfChannels"]];
	int i;
	for(i=0;i<kNumAmrelHVChannels;i++){
		[self setVoltage:i withValue:	[decoder decodeFloatForKey:[NSString stringWithFormat:@"voltage%d",i]]];
		[self setRampRate:i withValue:	[decoder decodeIntForKey:[NSString stringWithFormat:@"rampRate%d",i]]];
	}
	[self setPortWasOpen:	[decoder decodeBoolForKey:	 @"portWasOpen"]];
    [self setPortName:		[decoder decodeObjectForKey: @"portName"]];
    [[self undoManager] enableUndoRegistration];    
    [self registerNotificationObservers];
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInt:numberOfChannels forKey:@"numberOfChannels"];
	int i;
	for(i=0;i<kNumAmrelHVChannels;i++){
		[encoder encodeFloat:voltage[i] forKey:[NSString stringWithFormat:@"voltage%d",i]];
		[encoder encodeInt:voltage[i] forKey:[NSString stringWithFormat:@"rampRate%d",i]];
	}
    [encoder encodeBool:portWasOpen		forKey: @"portWasOpen"];
    [encoder encodeObject:portName		forKey: @"portName"];
}

- (void) sendCmd:(NSString*)aCommand channel:(short)aChannel value:(float)aValue
{

	[cmdQueue addObject:[aCommand stringByAppendingFormat:@" %d %f\r\n",aChannel+1,aValue]];
	if(!lastRequest)[self processOneCommandFromQueue];	
}

- (void) sendCmd:(NSString*)aCommand channel:(short)aChannel boolValue:(BOOL)aValue
{
	[cmdQueue addObject:[aCommand stringByAppendingFormat:@" %d %d\r\n",aChannel+1,aValue]];
	if(!lastRequest)[self processOneCommandFromQueue];	
}

- (void) sendCmd:(NSString*)aCommand channel:(short)aChannel
{
	[cmdQueue addObject:[aCommand stringByAppendingFormat:@" %d\r\n",aChannel+1]];
	if(!lastRequest)[self processOneCommandFromQueue];	
}

- (void) sendCmd:(NSString*)aCommand
{	
	if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
	
	[cmdQueue addObject:[aCommand dataUsingEncoding:NSASCIIStringEncoding]];
	if(!lastRequest)[self processOneCommandFromQueue];
}

- (NSData*) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(NSData*)aRequest
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelPortNameChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelSerialPortChanged object:self];
}

- (void) openPort:(BOOL)state
{
    if(state) {
		[serialPort setSpeed:9600];
		[serialPort setParityNone];
		[serialPort setStopBits2:NO];
		[serialPort setDataBits:8];
        [serialPort open];
		[serialPort setDelegate:self];

	}
    else      [serialPort close];
    portWasOpen = [serialPort isOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelPortStateChanged object:self];
    
}

#pragma mark •••HW Commands
- (void) getID							{ [self sendCmd:@"*IDN?\r\n"]; }
- (void) getActualVoltage:(int)aChannel	{ [self sendCmd:kGetActualVoltageCmd channel:aChannel]; }
- (void) getActualCurrent:(int)aChannel	{ [self sendCmd:kGetActualCurrentCmd channel:aChannel]; }
- (void) getOutput:(int)aChannel		{ [self sendCmd:kGetOutputCmd channel:aChannel]; }

- (void) setOutput:(int)aChannel withValue:(BOOL)aState
{
	[self sendCmd:kSetOutputCmd channel:aChannel value:aState]; 
}

- (void) loadHardware:(int)aChannel
{
	if(aChannel>=0 && aChannel<2){
		[self sendCmd:kSetOutputCmd     channel:aChannel boolValue:outputState[aChannel]];
		[self sendCmd:kSetPolarityCmd   channel:aChannel boolValue:polarity[aChannel]];
		[self sendCmd:kSetVoltageCmd    channel:aChannel value:voltage[aChannel]];
		[self sendCmd:kSetMaxCurrentCmd channel:aChannel boolValue:maxCurrent[aChannel]];
	}
}

- (void) dataReceived:(NSNotification*)note
{
	//query response = OK\n\rRESPONSE\n\rOK\n\r
	//non-query response = OK\n\r
	//error response = OK\n\rERROR\n\rOK\n\r
	
	BOOL done = NO;
	if(!lastRequest)return;
	
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		if(!inComingData)inComingData = [[NSMutableData data] retain];
        [inComingData appendData:[[note userInfo] objectForKey:@"data"]];
		
		NSString* theLastCommand = [[[[NSString alloc] initWithData:lastRequest 
														  encoding:NSASCIIStringEncoding] autorelease] uppercaseString];
		
		NSString* theResponse = [[[[NSString alloc] initWithData:inComingData 
														  encoding:NSASCIIStringEncoding] autorelease] uppercaseString];
		
		BOOL isQuery = ([theLastCommand rangeOfString:@"?"].location != NSNotFound);
		
		NSArray* parts = [theResponse componentsSeparatedByString:@"\n\r"];
		if(isQuery && [parts count] == 4){ //4 because the last \n\r results in a zero length part
			
			theResponse = [parts objectAtIndex:1];
			
			if([theResponse isEqualToString:@"ERROR"]){
				//count the error....
			}
			
			else if([theLastCommand hasPrefix:@"*IDN?"]){
				NSLog(@"%@\n",theResponse);
				done = YES;
			}
			
			else if([theLastCommand hasPrefix:kGetActualVoltageCmd]){
				int theChannel	 = [[theLastCommand substringFromIndex:[kGetActualVoltageCmd length]] intValue] - 1;
				float theVoltage = [theResponse floatValue];
				[self setActVoltage:theChannel withValue:theVoltage];
				done = YES;
			}
			
			else if([theLastCommand hasPrefix:kGetActualCurrentCmd]){
				int theChannel	 = [[theLastCommand substringFromIndex:[kGetActualCurrentCmd length]] intValue] - 1;
				float theCurrent = [theResponse floatValue];
				[self setActCurrent:theChannel withValue:theCurrent];
				done = YES;
			}
			
			else if([theLastCommand hasPrefix:kGetOutputCmd]){
				int theChannel = [[theLastCommand substringFromIndex:[kGetOutputCmd length]] intValue] - 1;
				BOOL theState  = [theResponse boolValue];
				[self setOutput:theChannel withValue:theState];
				done = YES;
			}		
		}	
		else if(!isQuery && [parts count] == 2){ //2 because the last \n\r results in a zero length part
			done = YES;
		}
		else if(!isQuery && [parts count] == 4){ //4 because the last \n\r results in a zero length part
			if([theResponse isEqualToString:@"ERROR"]){
				//count the error....
			}
			done = YES;
		}
		
		if(done){
			[inComingData release];
			inComingData = nil;
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
			[self setLastRequest:nil];			 //clear the last request
			[self processOneCommandFromQueue];	 //do the next command in the queue
		}
	}
}

- (void) serialPortWriteProgress:(NSDictionary *)dataDictionary;
{
}

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

#pragma mark •••Header Stuff
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"VHQ224LModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORAmrelHVDecoderForHVStatus",                 @"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:NO],                   @"variable",
								 [NSNumber numberWithLong:11],					 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"HVStatus"];
    return dataDictionary;
}
@end

@implementation ORAmrelHVModel (private)

- (void) timeout
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	NSLogError(@"ZUP",@"command timeout",nil);
	[self setLastRequest:nil];
	[cmdQueue removeAllObjects];
	[self processOneCommandFromQueue];	 //do the next command in the queue
}

- (void) processOneCommandFromQueue
{
	if([cmdQueue count] == 0) return;
	NSData* cmdData = [[[cmdQueue objectAtIndex:0] retain] autorelease];
	[cmdQueue removeObjectAtIndex:0];
	[self setLastRequest:cmdData];
	[serialPort writeDataInBackground:cmdData];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:1];
	
}

@end
