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

#import "ORHVRampItem.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORSerialPortList.h"

NSString* ORZupModelOutputStateChanged = @"ORZupModelOutputStateChanged";
NSString* ORZupModelBoardAddressChanged = @"ORZupModelBoardAddressChanged";
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
		[[self undoManager] disableUndoRegistration];
		ORHVRampItem* aRampItem = [[ORHVRampItem alloc] initWithOwner:self];
		[aRampItem setTargetName:[self className]];
		[aRampItem setParameterName:@"Voltage"];
		[aRampItem loadParams:self];
		[rampItems addObject:aRampItem];
		[aRampItem release];
	
		[[self undoManager] enableUndoRegistration];
	}
}

#pragma mark ***Accessors
- (BOOL) sentAddress
{
	return sentAddress;
}

- (BOOL) outputState
{
    return outputState;
}

- (void) setOutputState:(BOOL)aOutputState
{
    outputState = aOutputState;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelOutputStateChanged object:self];
}

- (int) boardAddress
{
    return boardAddress;
}

- (void) setBoardAddress:(int)aBoardAddress
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBoardAddress:boardAddress];
    
    boardAddress = aBoardAddress;
	sentAddress = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORZupModelBoardAddressChanged object:self];
}

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
	NSString* s = [NSString stringWithFormat:@"PV %f",[self voltage:0]];
	[self sendCmd:s];
	NSLog(@"%.1f\n",[self voltage:0]);
}

- (void) getStatus
{
	[self sendCmd:@"Out?"];
	[self sendCmd:@"PV?"];
}


#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setBoardAddress:	[decoder decodeIntForKey:	 @"boardAddress"]];
	[self setPortWasOpen:	[decoder decodeBoolForKey:	 @"portWasOpen"]];
    [self setPortName:		[decoder decodeObjectForKey: @"portName"]];
    [[self undoManager] enableUndoRegistration];    
    [self registerNotificationObservers];
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:boardAddress		forKey:@"boardAddress"];
    [encoder encodeBool:portWasOpen		forKey: @"portWasOpen"];
    [encoder encodeObject:portName		forKey: @"portName"];
}

- (void) sendCmd:(NSString*)aCommand
{	
	if(![aCommand hasSuffix:@"\r"])aCommand = [aCommand stringByAppendingString:@"\r"];
	if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
	if(!sentAddress){
		NSString* addressCmd = [NSString stringWithFormat:@"ADR %d\r",[self boardAddress]];
		[cmdQueue addObject:[addressCmd dataUsingEncoding:NSASCIIStringEncoding]];
	}
	
	[cmdQueue addObject:[aCommand dataUsingEncoding:NSASCIIStringEncoding]];
	if(!lastRequest)[self processOneCommandFromQueue];
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
	return @selector(rampAboutToStart);
}

- (void) rampAboutToStart
{
	NSLog(@"do it\n");
}

- (void) initBoard
{
}

- (int) numberOfChannels
{
    return 1;
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
		sentAddress = NO;

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
		
		NSString* theLastCommand = [[[NSString alloc] initWithData:lastRequest 
														  encoding:NSASCIIStringEncoding] autorelease];
		theLastCommand = [theLastCommand uppercaseString];
		
		NSString* theResponse = [[[NSString alloc] initWithData:inComingData 
														  encoding:NSASCIIStringEncoding] autorelease];
		
		theLastCommand	= [theLastCommand uppercaseString];
		theResponse		= [theResponse uppercaseString];
		
		if([theResponse hasPrefix:@"OK"]){
			if([theLastCommand hasPrefix:@"ADR"]){
				sentAddress = YES;
			}
			done = YES;
		}
		else if([theLastCommand hasPrefix:@"C"]){
			NSLog(@"%@\n",theResponse);
			done = YES;
		}		
		else if([theLastCommand rangeOfString:@"?"].location != NSNotFound){
			if([theLastCommand hasPrefix:@"OUT"]){
				if([theResponse hasPrefix:@"ON"])		[self setOutputState:YES];
				else if([theResponse hasPrefix:@"OFF"])	[self setOutputState:NO];
				done = YES;
			}
			if([theLastCommand hasPrefix:@"PV"]){
				float theVoltage = [theResponse floatValue];
				NSLog(@"Voltage is %.1f\n",theVoltage);
				[self setVoltage:0 withValue:theVoltage];
				[[rampItems objectAtIndex:0] placeCurrentValue];
				done = YES;
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
}

- (void) togglePower
{
	NSString* s = [NSString stringWithFormat:@"OUT %d",![self outputState]];
	[self sendCmd:s];
	[self sendCmd:@"OUT?"];
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
	[cmdQueue removeAllObjects];
	sentAddress = NO;
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
