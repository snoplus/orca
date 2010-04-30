//--------------------------------------------------------
// ORKJL2200IonGaugeModel
// Created by Mark  A. Howe on Fri Jul 22 2005
// Created by Mark  A. Howe on Thurs Apr 22 2010
// Copyright (c) 2010 University of North Caroline. All rights reserved.
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

#pragma mark ***Imported Files

#import "ORKJL2200IonGaugeModel.h"
#import "ORSerialPort.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORTimeRate.h"

#pragma mark ***External Strings
NSString* ORKJL2200IonGaugeModelDegasTimeChanged		= @"ORKJL2200IonGaugeModelDegasTimeChanged";
NSString* ORKJL2200IonGaugeModelEmissionCurrentChanged	= @"ORKJL2200IonGaugeModelEmissionCurrentChanged";
NSString* ORKJL2200IonGaugeModelSensitivityChanged		= @"ORKJL2200IonGaugeModelSensitivityChanged";
NSString* ORKJL2200IonGaugeModelSetPointChanged			= @"ORKJL2200IonGaugeModelSetPointChanged";
NSString* ORKJL2200IonGaugeModelStatusBitsChanged		= @"ORKJL2200IonGaugeModelStatusBitsChanged";
NSString* ORKJL2200IonGaugePressureChanged				= @"ORKJL2200IonGaugePressureChanged";
NSString* ORKJL2200IonGaugeShipPressureChanged			= @"ORKJL2200IonGaugeShipPressureChanged";
NSString* ORKJL2200IonGaugePollTimeChanged				= @"ORKJL2200IonGaugePollTimeChanged";
NSString* ORKJL2200IonGaugeSerialPortChanged			= @"ORKJL2200IonGaugeSerialPortChanged";
NSString* ORKJL2200IonGaugePortNameChanged				= @"ORKJL2200IonGaugePortNameChanged";
NSString* ORKJL2200IonGaugePortStateChanged				= @"ORKJL2200IonGaugePortStateChanged";
NSString* ORKJL2200IonGaugeModelStateMaskChanged		= @"ORKJL2200IonGaugeModelStateMaskChanged";
NSString* ORKJL2200IonGaugeLock							= @"ORKJL2200IonGaugeLock";

@interface ORKJL2200IonGaugeModel (private)
- (void) runStarted:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;
- (void) sendFromOutgoingBuffer;
- (void) decodeCommand:(NSString*)aCmd;
@end

@implementation ORKJL2200IonGaugeModel
- (id) init
{
	self = [super init];
    [self registerNotificationObservers];
	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [portName release];
	[outgoingBuffer release];
	
    if([serialPort isOpen]){
        [serialPort close];
    }
    [serialPort release];
	[timeRate release];
    [buffer release];

	[super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"KJL2200IonGauge"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORKJL2200IonGaugeController"];
}

//- (NSString*) helpURL
//{
//	return @"RS232/LakeShore_210.html";
//}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(dataReceived:)
                         name : ORSerialPortDataReceived
                       object : nil];

    [notifyCenter addObserver: self
                     selector: @selector(runStarted:)
                         name: ORRunStartedNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStopped:)
                         name: ORRunStoppedNotification
                       object: nil];

}

- (void) dataReceived:(NSNotification*)note
{
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
        NSString* theString = [[[[NSString alloc] initWithData:[[note userInfo] objectForKey:@"data"] 
												      encoding:NSASCIIStringEncoding] autorelease] uppercaseString];

		//the serial port may break the data up into small chunks, so we have to accumulate the chunks until
		//we get a full piece.
        theString = [[theString componentsSeparatedByString:@"\n"] componentsJoinedByString:@""];
        if(!buffer)buffer = [[NSMutableString string] retain];
        [buffer appendString:theString];					
		
        do {
            NSRange lineRange = [buffer rangeOfString:@"\r"];
            if(lineRange.location!= NSNotFound){
                NSMutableString* theResponse = [[[buffer substringToIndex:lineRange.location+1] mutableCopy] autorelease];
                [buffer deleteCharactersInRange:NSMakeRange(0,lineRange.location+1)];      //take the cmd out of the buffer
				[self decodeCommand:theResponse];
            }
        } while([buffer rangeOfString:@"\r"].location!= NSNotFound);
	}
}


- (void) shipPressureValue
{
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		unsigned long data[4];
		data[0] = dataId | 4;
		data[1] =  ([self uniqueIdNumber]&0x0000fffff);
		
		union {
			float asFloat;
			unsigned long asLong;
		}theData;
		theData.asFloat = pressure;
		data[2] = theData.asLong;
		data[3] = timeMeasured;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:&data length:sizeof(long)*4]];
	}
}


#pragma mark ***Accessors
- (void) setStateMask:(unsigned short)aMask
{
	stateMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelStateMaskChanged object:self];
}

- (unsigned short)stateMask
{
	return stateMask;
}

- (float) degasTime
{
    return degasTime;
}

- (void) setDegasTime:(float)aDegasTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDegasTime:degasTime];
    
    degasTime = aDegasTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelDegasTimeChanged object:self];
}

- (float) emissionCurrent
{
    return emissionCurrent;
}

- (void) setEmissionCurrent:(float)aValue
{
	if(aValue<1)aValue = 1;
	else if(aValue>25.5)aValue=25.5;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setEmissionCurrent:emissionCurrent];
    
    emissionCurrent = aValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelEmissionCurrentChanged object:self];
}

- (int) sensitivity
{
    return sensitivity;
}

- (void) setSensitivity:(int)aValue
{
	if(aValue<1)aValue = 1;
	else if(aValue>80)aValue=80;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setSensitivity:sensitivity];
    
    sensitivity = aValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelSensitivityChanged object:self];
}

- (float) setPoint:(int)index
{
	if(index>=0 && index<4)return setPoint[index];
	else return 0;
}

- (void) setSetPoint:(int)index withValue:(float)aSetPoint
{
	if(index>=0 && index<4){
		[[[self undoManager] prepareWithInvocationTarget:self] setSetPoint:index withValue:setPoint[index]];
    
		setPoint[index] = aSetPoint;

		[[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelSetPointChanged object:self];
	}
}

- (int) statusBits
{
    return statusBits;
}

- (void) setStatusBits:(int)aStatusBits
{
    statusBits = aStatusBits;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelStatusBitsChanged object:self];
}

- (float) pressure
{
    return pressure;
}

- (void) setPressure:(float)aPressure
{
    pressure = aPressure;
	//get the time(UT!)
	time_t	ut_Time;
	time(&ut_Time);
	//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
	timeMeasured = ut_Time;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugePressureChanged 
														object:self 
													  userInfo:nil];
	
	if(timeRate == nil) timeRate = [[ORTimeRate alloc] init];
	[timeRate addDataToTimeAverage:aPressure];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugePressureChanged object:self];
}

- (void) readPressure
{
	[self sendCommand:@"=RV\r"];
}

- (ORTimeRate*)timeRate
{
	return timeRate;
}

- (BOOL) shipPressure
{
    return shipPressure;
}

- (void) setShipPressure:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipPressure:shipPressure];
    
    shipPressure = aFlag;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeShipPressureChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugePollTimeChanged object:self];

	if(pollTime){
		[self performSelector:@selector(pollPressure) withObject:nil afterDelay:2];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollPressure) object:nil];
	}
}

- (void) pollPressure
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollPressure) object:nil];
	//testing: [self decodeCommand:@"V=5.0-07"];
	[self readPressure];
	[self performSelector:@selector(pollPressure) withObject:nil afterDelay:pollTime];
}


- (unsigned long) timeMeasured
{
	return timeMeasured;
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugePortNameChanged object:self];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeSerialPortChanged object:self];
}

- (void) openPort:(BOOL)state
{
    if(state) {
		[serialPort setSpeed:2400];
		[serialPort setParityNone];
		[serialPort setStopBits2:0];
		[serialPort setDataBits:8];
        [serialPort open];
		[self sendFromOutgoingBuffer];
    }
    else  {
		[outgoingBuffer release];
		outgoingBuffer = nil;
		[serialPort close];
	}
    portWasOpen = [serialPort isOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugePortStateChanged object:self];
    
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	[self setDegasTime:		 [decoder decodeFloatForKey:@"degasTime"]];
	[self setEmissionCurrent:[decoder decodeFloatForKey:@"emissionCurrent"]];
	[self setSensitivity:	 [decoder decodeIntForKey:@"sensitivity"]];
	[self setShipPressure:	 [decoder decodeBoolForKey:@"shipPressure"]];
	[self setPollTime:		 [decoder decodeIntForKey:@"pollTime"]];
	[self setPortWasOpen:	 [decoder decodeBoolForKey:@"portWasOpen"]];
    [self setPortName:		 [decoder decodeObjectForKey: @"portName"]];
	[[self undoManager] enableUndoRegistration];
	timeRate = [[ORTimeRate alloc] init];
	
	int i;
	for(i=0;i<4;i++){
		[self setSetPoint:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"setPoint%d",i]]];
	}
		 
    [self registerNotificationObservers];

	return self;
}
- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:degasTime forKey:@"degasTime"];
    [encoder encodeFloat:emissionCurrent forKey:@"emissionCurrent"];
    [encoder encodeInt:sensitivity forKey:@"sensitivity"];
    [encoder encodeBool:shipPressure forKey:@"shipPressure"];
    [encoder encodeInt:pollTime		forKey:@"pollTime"];
    [encoder encodeBool:portWasOpen forKey:@"portWasOpen"];
    [encoder encodeObject:portName	forKey: @"portName"];
	int i;
	for(i=0;i<4;i++){
		[encoder encodeFloat:setPoint[i] forKey:[NSString stringWithFormat:@"setPoint%d",i]];
	}
}

#pragma mark *** Commands
- (void) sendCommand:(NSString*)aCmd
{
	if(!outgoingBuffer)outgoingBuffer = [[NSMutableArray array] retain];
	if([serialPort isOpen]){
		NSArray* cmdList = [aCmd componentsSeparatedByString:@"\r"];
		for(id oneCommand in cmdList)[outgoingBuffer addObject:oneCommand];
	}
}


- (void) initBoard
{
	NSString* aCmd = [NSString stringWithFormat:@"=SS:%d\r",sensitivity];
	aCmd = [aCmd stringByAppendingFormat:@"=SE:%.1f\r",emissionCurrent];
	aCmd = [aCmd stringByAppendingFormat:@"=ST:%d\r",degasTime];
	int i;
	for(i=0;i<4;i++){
		aCmd = [aCmd stringByAppendingFormat:@"=S%d:%.1E\r",setPoint[i]];
	}
	aCmd = [aCmd stringByReplacingOccurrencesOfString:@"E-" withString:@"-"];
	[self sendCommand:aCmd];
}

#pragma mark ***Data Records
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherKJL2200IonGauge
{
    [self setDataId:[anotherKJL2200IonGauge dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"KJL2200IonGaugeModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORKJL2200IonGaugeDecoderForPressure",@"decoder",
        [NSNumber numberWithLong:dataId],   @"dataId",
        [NSNumber numberWithBool:NO],       @"variable",
        [NSNumber numberWithLong:18],       @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Pressure"];
    
    return dataDictionary;
}

@end

@implementation ORKJL2200IonGaugeModel (private)
- (void) runStarted:(NSNotification*)aNote
{
}

- (void) runStopped:(NSNotification*)aNote
{
}

- (void) decodeCommand:(NSString*)aCmd
{
	NSString* prefix = [aCmd substringToIndex:2];
	NSString* value = [aCmd substringFromIndex:2];
	if([prefix isEqualToString:@"V="]){
		value = [value stringByReplacingOccurrencesOfString:@"-" withString:@"E-"];
		[self setPressure:[value floatValue]];
	}
}

- (void) sendFromOutgoingBuffer
{
	if([serialPort isOpen] && [outgoingBuffer count}>0){
		id aCmd = [[[outgoingBuffer objectAtIndex:0] retain] autorelease];
		[outgoingBuffer removeObjectAtIndex:0];
		[serialPort writeString:aCmd];
		[self performSelector:@selector(sendFromOutgoingBuffer) withObject:nil afterDelay:.1];
	}
}


@end