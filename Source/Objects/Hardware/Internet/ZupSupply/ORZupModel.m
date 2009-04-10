//
//  ORZupModel.m
//  Orca
//
//  Created by Mark Howe on Monday March 16,2009
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
#import "ORZupModel.h"
#import "ORNPLCommBoardModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORHVRampItem.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORSerialPortList.h"

NSString* ORZupLock					= @"ORZupLock";
NSString* ORZupModelSerialPortChanged	= @"ORZupModelSerialPortChanged";
NSString* ORZupModelPortNameChanged	= @"ORZupModelPortNameChanged";
NSString* ORZupModelPortStateChanged	= @"ORZupModelPortStateChanged";

@interface ORZupModel (private)
- (void) timeout;
- (void) processOneCommandFromQueue;
@end

@implementation ORZupModel

- (void) makeMainController
{
    [self linkToController:@"ORZupController"];
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
    [self setImage:[NSImage imageNamed:@"ZupIcon"]];
}

- (void) awakeAfterDocumentLoaded
{
}



- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataReceived:)
                         name : ORSerialPortDataReceived
                       object : nil];
}

- (void) addRampItem
{
	ORHVRampItem* aRampItem = [[ORHVRampItem alloc] initWithOwner:self];
	[rampItems addObject:aRampItem];
	[aRampItem release];
}

- (void) ensureMinimumNumberOfRampItems
{
	if(!rampItems)[self setRampItems:[NSMutableArray array]];
	if([rampItems count] == 0){
		int i;
		[[self undoManager] disableUndoRegistration];
		for(i=0;i<[self numberOfChannels];i++){
			ORHVRampItem* aRampItem = [[ORHVRampItem alloc] initWithOwner:self];
			[aRampItem setTargetName:[self className]];
			[aRampItem setChannelNumber:i];
			[aRampItem setParameterName:@"Voltage"];
			[aRampItem loadParams:self];
			[rampItems addObject:aRampItem];
			[aRampItem release];
		}
		[[self undoManager] enableUndoRegistration];
	}
}

#pragma mark ***Accessors
- (NSString*) lockName
{
	return ORZupLock;
}

- (float) voltage:(int)dummy
{
	return voltage;
}

- (void) setVoltage:(int)dummy withValue:(float)aValue
{
	voltage = aValue;
}

- (void) loadDac:(int)dummy
{
}
#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	[self setPortWasOpen:	[decoder decodeBoolForKey:	 @"portWasOpen"]];
    [self setPortName:		[decoder decodeObjectForKey: @"portName"]];
    [[self undoManager] enableUndoRegistration];    
    [self registerNotificationObservers];
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:portWasOpen		forKey: @"portWasOpen"];
    [encoder encodeObject:portName		forKey: @"portName"];
}

- (void) sendCmd
{	

}

- (SEL) getMethodSelector
{
	return @selector(voltage:);
}

- (SEL) setMethodSelector
{
	return @selector(setVoltage:withValue:);
}

- (SEL) initMethodSelector
{
	//fake out, so we can actually do the load ourselves
	return @selector(junk);
}

- (void) junk
{
}


- (void) initBoard
{
	int chan;
	for(chan = 0 ; chan<[self numberOfChannels] ; chan++){
		//set up the Voltage Adc
		[self setVoltageReg:kZupChanConvTime	chan:chan value:0xff]; //set conversion time to max
		[self setVoltageReg:kZupChanSetup		chan:chan value:0x5];  //bits 0,1 are gain, bit 2 is enables chan for continous conversion
		[self setVoltageReg:kZupMode			chan:chan value:0x20]; //20 = continous and 16 bit output word

		//set up the Current Adc
		[self setCurrentReg:kZupChanConvTime	chan:chan value:0xff]; //set conversion time to max
		[self setCurrentReg:kZupChanSetup		chan:chan value:0x5];  //bits 0,1 are gain, bit 2 is enables chan for continous conversion
		[self setCurrentReg:kZupMode			chan:chan value:0x20]; //20 = continous and 16 bit output word

	}
}

- (void) setVoltageReg:(int)aReg chan:(int)aChan value:(int)aValue
{

}

- (void) setCurrentReg:(int)aReg chan:(int)aChan value:(int)aValue
{

}


#pragma mark •••HW Wizard
//the next two methods exist only to 'fake' out Hardware wizard and the Ramper so this item can be selected
- (int) crateNumber	{	return 0;	}
- (int) slot		{	return [self tag];	}

- (int) numberOfChannels
{
    return 1;
}

- (BOOL) hasParmetersToRamp
{
	return YES;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Voltage"];
    [p setFormat:@"##0.0" upperLimit:30 lowerLimit:0 stepSize:0.1 units:@"V"];
    [p setSetMethod:@selector(setVoltage:witheValue:) getMethod:@selector(voltage:)];
	[p setInitMethodSelector:@selector(sendVoltage)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate"	className:@"ORZupModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card"		className:@"ORZupModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel"	className:@"ORZupModel"]];
    return a;
	
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelPortNameChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelSerialPortChanged object:self];
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
		
		if([serialPort isOpen]){ 
			NSString* s = @"ADR 06\r";
			if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
			[cmdQueue addObject:[s dataUsingEncoding:NSASCIIStringEncoding]];
			
			if(!lastRequest)[self processOneCommandFromQueue];
			
		}
	}
    else      [serialPort close];
    portWasOpen = [serialPort isOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelPortStateChanged object:self];
    
}
- (void) dataReceived:(NSNotification*)note
{
	BOOL done = NO;
	if(!lastRequest)return;
	
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		if(!inComingData)inComingData = [[NSMutableData data] retain];
        [inComingData appendData:[[note userInfo] objectForKey:@"data"]];
		
		char* theCmd = (char*)[lastRequest bytes];
		switch (theCmd[0]){
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

@end

@implementation ORZupModel (private)

- (void) timeout
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	NSLogError(@"ZUP",@"command timeout",nil);
	[self setLastRequest:nil];
	[self processOneCommandFromQueue];	 //do the next command in the queue
}

- (void) processOneCommandFromQueue
{
	if([cmdQueue count] == 0) return;
	NSData* cmdData = [[[cmdQueue objectAtIndex:0] retain] autorelease];
	[cmdQueue removeObjectAtIndex:0];
	//unsigned char* cmd = (unsigned char*)[cmdData bytes];
	[self setLastRequest:cmdData];
	[serialPort writeDataInBackground:cmdData];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:1];
	
}

@end
