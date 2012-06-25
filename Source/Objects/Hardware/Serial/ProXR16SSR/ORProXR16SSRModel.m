//--------------------------------------------------------
// ORProXR16SSRModel
// Created by Mark  A. Howe on Thurs June 21, 2012
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
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

#import "ORProXR16SSRModel.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"

#pragma mark •••External Strings
NSString* ORProXR16SSRModelPollTimeChanged			= @"ORProXR16SSRModelPollTimeChanged";
NSString* ORProXR16SSRModelSerialPortChanged		= @"ORProXR16SSRModelSerialPortChanged";
NSString* ORProXR16SSRModelPortNameChanged			= @"ORProXR16SSRModelPortNameChanged";
NSString* ORProXR16SSRModelPortStateChanged			= @"ORProXR16SSRModelPortStateChanged";
NSString* ORProXR16SSRModelRelayStateChanged		= @"ORProXR16SSRModelRelayStateChanged";
NSString* ORProXR16SSRModelUpdateAllRelaysChanged	= @"ORProXR16SSRModelUpdateAllRelaysChanged";
NSString* ORProXR16SSRModelOutletNameChanged		= @"ORProXR16SSRModelOutletNameChanged";
NSString* ORProXR16SSRLock							= @"ORProXR16SSRLock";

@interface ORProXR16SSRModel (private)
- (void) timeout;
- (void) processOneCommandFromQueue;
- (void) setupOutletNames;
- (NSData*) lastRequest;
- (void) setLastRequest:(NSData*)aRequest;
- (void) setRelayMask:(unsigned char)mask bank:(int)aBank;
- (void) setRelay:(int)index state:(BOOL)aState;
@end

@implementation ORProXR16SSRModel
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
	[cmdQueue release];
	[lastRequest release];
    [portName release];
    if([serialPort isOpen]){
        [serialPort close];
    }
    [serialPort release];

	[super dealloc];
}

- (void) setUpImage
{
	//---------------------------------------------------------------------------------------------------
	//arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
	//so, we cache the image here so that each crate can have its own version for drawing into.
	//---------------------------------------------------------------------------------------------------
	NSImage* aCachedImage = [NSImage imageNamed:@"ProXR16SSR"];
	NSSize imageSize = [aCachedImage size];
	NSImage* i = [[NSImage alloc] initWithSize:imageSize];
	[i lockFocus];
	[aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	
	int relay;
	for(relay=0;relay<8;relay++){
		NSBezierPath* circle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(6+relay*8, imageSize.height-15,7,7)];
		if(relayState[relay]) [[NSColor greenColor] set];
		else			        [[NSColor lightGrayColor] set];
		[circle fill];
	}
	
	for(relay=0;relay<8;relay++){
		NSBezierPath* circle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(6+relay*8, 7,7,7)];
		if(relayState[relay+8]) [[NSColor greenColor] set];
		else			        [[NSColor lightGrayColor] set];
		[circle fill];
	}
	
	[i unlockFocus];		
	[self setImage:i];
	[i release];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:OROrcaObjectImageChanged object:self];
}

- (void) makeMainController
{
	[self linkToController:@"ORProXR16SSRController"];
}

- (NSString*) helpURL
{
	return @"RS232/ProXR16SSR.html";
}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(dataReceived:)
                         name : ORSerialPortDataReceived
                       object : nil];
}

- (void) dataReceived:(NSNotification*)note
{
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
		NSData* theResponse = [[note userInfo] objectForKey:@"data"];
		NSUInteger responseLength    = [theResponse length];
		unsigned char* responseBytes = (unsigned char*)[theResponse bytes];
		if(responseLength>=1){
			if(responseBytes[0] == kProXR16SSRCmdResponse){
				[self setLastRequest:nil];			 //clear the last request
				[self processOneCommandFromQueue];	 //do the next command in the queue
			}
			else {
				NSUInteger lastRequestLength    = [lastRequest length];
				unsigned char* lastCmdBytes = (unsigned char*)[lastRequest bytes];
				if(lastRequestLength>=2){
					switch(lastCmdBytes[1]){
						case kProXR16SSRAllRelayStatus:
							if(lastRequestLength >=3){
								[self setRelayMask:responseBytes[0] bank:lastCmdBytes[2]];
							}
						break;
					}
				}
				[self setLastRequest:nil];			 //clear the last request
				[self processOneCommandFromQueue];	 //do the next command in the queue
			}
		}
	}
}

#pragma mark •••Accessors
- (NSString*) commonScriptMethods
{
    NSMutableString *methods = [[NSMutableString alloc] init];
    [methods appendString: methodsInCommonSection(self)];
    return [methods autorelease];
}

//-------------Methode to flag beginning of common script methods---------------------------------
- (void) commonScriptMethodSectionBegin { }
- (NSString*) outletName:(int)index
{
	if(index<0)index = 0;
	else if(index>16)index=16;
	if(!outletNames)[self setupOutletNames];
	return [outletNames objectAtIndex:index];
}

- (void) setOutlet:(int)index name:(NSString*)aName
{
	if(!outletNames)[self setupOutletNames];
	[[[self undoManager] prepareWithInvocationTarget:self] setOutlet:index name:[self outletName:index]];
	[outletNames replaceObjectAtIndex:index withObject:aName];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProXR16SSRModelOutletNameChanged object:self];
}

- (BOOL) relayState:(int)index
{
    if(index>=0 && index<16)return relayState[index];
    else return NO;
}

-  (void) turnRelayOn:(int) aChan
{    
	int bank = aChan/8 + 1;
	unsigned char cmdArray[3];
	cmdArray[0] = kProXR16SSRCmdStart;
	cmdArray[1] = kProXR16SSRRelayOnStart + aChan%8;
	cmdArray[2] = bank;
    [self addCmdToQueue:[NSData dataWithBytes:cmdArray length:3]];
}

-  (void) turnRelayOff:(int) aChan
{
	int bank = aChan/8 + 1;
	unsigned char cmdArray[3];
	cmdArray[0] = kProXR16SSRCmdStart;
	cmdArray[1] = kProXR16SSRRelayOffStart + aChan%8;
	cmdArray[2] = bank;
    [self addCmdToQueue:[NSData dataWithBytes:cmdArray length:3]];
}

-  (void) readAllRelayStates
{
	unsigned char cmdArray[3];
	cmdArray[0] = kProXR16SSRCmdStart;
	cmdArray[1] = kProXR16SSRAllRelayStatus;
	cmdArray[2] = 0; //bank
    [self addCmdToQueue:[NSData dataWithBytes:cmdArray length:3]];
	
	cmdArray[2] = 1; //bank
    [self addCmdToQueue:[NSData dataWithBytes:cmdArray length:3]];
}

- (void) commonScriptMethodSectionEnd { }
//-------------end of common script methods---------------------------------


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
					[self readAllRelayStates];
                }
                valid = YES;
                break;
            }
        } 
        if(!valid){
            [self setSerialPort:nil];
        }       
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProXR16SSRModelPortNameChanged object:self];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProXR16SSRModelSerialPortChanged object:self];
}

- (void) openPort:(BOOL)state
{
    if(state) {
        [serialPort open];
		[serialPort setSpeed:115200];
		[serialPort setParityNone];
		[serialPort setStopBits2:NO];
		[serialPort setDataBits:8];
		[serialPort commitChanges];
    }
    else      [serialPort close];
    portWasOpen = [serialPort isOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProXR16SSRModelPortStateChanged object:self];
}


#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
    
	[self setPortWasOpen:[decoder decodeBoolForKey:@"ORProXR16SSRModelPortWasOpen"]];
    [self setPortName:[decoder decodeObjectForKey: @"portName"]];
	[[self undoManager] enableUndoRegistration];
    
	[self registerNotificationObservers];
    
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:portWasOpen forKey:@"ORProXR16SSRModelPortWasOpen"];
    [encoder encodeObject:portName forKey: @"portName"];
}

#pragma mark ••• Commands
- (void) addCmdToQueue:(NSData*)aCmd
{
    if([serialPort isOpen]){ 
		if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
		[cmdQueue addObject:aCmd];
		if(!lastRequest) {
			[self processOneCommandFromQueue];
		}
	}
}

#pragma mark •••Bit Processing Protocol
- (void) processIsStarting
{
    //nothing to do
}

- (void) processIsStopping
{
    //nothing to do
}

//note that everything called by these routines MUST be threadsafe
- (void) startProcessCycle
{
    //nothing to do
}

- (void) endProcessCycle
{
    //nothing to do
}

- (NSString*) identifier
{
	NSString* s;
 	@synchronized(self){
		s= [NSString stringWithFormat:@"ProXR16,%d",[self uniqueIdNumber]];
	}
	return s;
}

- (NSString*) processingTitle
{
	NSString* s;
 	@synchronized(self){
		s= [self identifier];
	}
	return s;
}

- (BOOL) processValue:(int)channel
{
	BOOL theValue = 0;
	@synchronized(self){
		theValue = [self relayState:channel];
	}
	return theValue;
}

- (void) setProcessOutput:(int)channel value:(int)value
{	
    //nothing to do
}

- (void) setOutputBit:(int)channel value:(int)value
{
	@synchronized(self){
		if(value==1)	  [self turnRelayOn:channel];
		else if(value==0) [self turnRelayOff:channel];
	}
}
@end

@implementation ORProXR16SSRModel (private)
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
- (void) setupOutletNames
{
	outletNames = [[NSMutableArray array] retain];
	int i;
	for(i=0;i<16;i++)[outletNames addObject:[NSString stringWithFormat:@"Relay %d",i]];	
}

- (void) timeout
{
	NSLogError(@"command timeout","ProXR16SSR",nil);
	[self setLastRequest:nil];
	[cmdQueue removeAllObjects];
}

- (void) processOneCommandFromQueue
{
	if([cmdQueue count] == 0) return;
	NSData* aCmd = [[[cmdQueue objectAtIndex:0] retain] autorelease];
	[cmdQueue removeObjectAtIndex:0];
	
	[self setLastRequest:aCmd];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:3];
	NSString* s = [[NSString alloc] initWithData:aCmd encoding:NSASCIIStringEncoding];
	[serialPort writeString:s];
	if(!lastRequest){
		[self performSelector:@selector(processOneCommandFromQueue) withObject:nil afterDelay:.01];
	}
}

- (void) setRelayMask:(unsigned char)mask bank:(int)aBank
{
	if(aBank>=0 && aBank<2){
		int i;
		for(i=0;i<8;i++){
			relayState[i + aBank*8] = ((mask & (0x1<<i)) > 0);
		}
		[self setUpImage];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORProXR16SSRModelUpdateAllRelaysChanged object:self];
	}
}

- (void) setRelay:(int)index state:(BOOL)aState
{
    relayState[index] = aState;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:index],@"Channel", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProXR16SSRModelRelayStateChanged object:self userInfo:userInfo];
	[self setUpImage];
}

@end