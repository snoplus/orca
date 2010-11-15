//
//  ORLabJackModel.m
//  Orca
//
//  Created by Mark Howe on Tues Nov 09,2010.
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
#import "ORLabJackModel.h"
#import "ORUSBInterface.h"
#import "NSNotifications+Extensions.h"

NSString* ORLabJackModelDigitalOutputEnabledChanged = @"ORLabJackModelDigitalOutputEnabledChanged";
NSString* ORLabJackModelCounterChanged		= @"ORLabJackModelCounterChanged";
NSString* ORLabJackModelSerialNumberChanged	= @"ORLabJackModelSerialNumberChanged";
NSString* ORLabJackModelUSBInterfaceChanged	= @"ORLabJackModelUSBInterfaceChanged";
NSString* ORLabJackUSBInConnection			= @"ORLabJackUSBInConnection";
NSString* ORLabJackUSBNextConnection		= @"ORLabJackUSBNextConnection";
NSString* ORLabJackModelLock				= @"ORLabJackModelLock";
NSString* ORLabJackChannelNameChanged		= @"ORLabJackChannelNameChanged";
NSString* ORLabJackAdcChanged				= @"ORLabJackAdcChanged";
NSString* ORLabJackDoNameChanged			= @"ORLabJackDoNameChanged";
NSString* ORLabJackIoNameChanged			= @"ORLabJackIoNameChanged";
NSString* ORLabJackDoDirectionChangedNotification	= @"ORLabJackDoDirectionChangedNotification";
NSString* ORLabJackIoDirectionChangedNotification	= @"ORLabJackIoDirectionChangedNotification";
NSString* ORLabJackDoValueOutChangedNotification	= @"ORLabJackDoValueOutChangedNotification";
NSString* ORLabJackIoValueOutChangedNotification	= @"ORLabJackIoValueOutChangedNotification";
NSString* ORLabJackDoValueInChangedNotification		= @"ORLabJackDoValueInChangedNotification";
NSString* ORLabJackIoValueInChangedNotification		= @"ORLabJackIoValueInChangedNotification";

#define kLabJackU12DriverPath @"/System/Library/Extensions/LabJackU12.kext"
@interface ORLabJackModel (private)
- (void) readPipe;
- (void) firstWrite;
- (void) writeData:(unsigned char*) data;
@end

@implementation ORLabJackModel

- (void) dealloc 
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	int i;
	for(i=0;i<8;i++)	[channelName[i] release];
	for(i=0;i<16;i++)	[ioName[i] release];
	for(i=0;i<4;i++)	[doName[i] release];
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
    [noDriverAlarm clearAlarm];
    [noDriverAlarm release];
    [serialNumber release];
	[super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		[self connectionChanged];		
		//make sure the driver is installed.
		NSFileManager* fm = [NSFileManager defaultManager];
		if(![fm fileExistsAtPath:kLabJackU12DriverPath]){
			NSLogColor([NSColor redColor],@"*** Unable To Locate LabJack U12 Driver ***\n");
			if(!noDriverAlarm){
				noDriverAlarm = [[ORAlarm alloc] initWithName:@"No LabJack U12 Driver Found" severity:0];
				[noDriverAlarm setSticky:NO];
				[noDriverAlarm setHelpStringFromFile:@"kLabJackU12DriverPath"];
			}                      
			[noDriverAlarm setAcknowledged:NO];
			[noDriverAlarm postAlarm];
		}
	}
	@catch(NSException* localException) {
	}
}


- (void) makeConnectors
{
	ORConnector* connectorObj1 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( 0, [self frame].size.height-20 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj1 forKey: ORLabJackUSBInConnection ];
	[ connectorObj1 setConnectorType: 'USBI' ];
	[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to usb outputs
	[connectorObj1 setOffColor:[NSColor yellowColor]];
	[ connectorObj1 release ];
	
	ORConnector* connectorObj2 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, 10 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj2 forKey: ORLabJackUSBNextConnection ];
	[ connectorObj2 setConnectorType: 'USBO' ];
	[ connectorObj2 addRestrictedConnectionType: 'USBI' ]; //can only connect to usb inputs
	[connectorObj2 setOffColor:[NSColor yellowColor]];
	[ connectorObj2 release ];
}

- (void) makeMainController
{
    [self linkToController:@"ORLabJackController"];
}

- (NSString*) helpURL
{
	return @"USB/LDA120.html";
}



- (void) connectionChanged
{
	NSArray* interfaces = [[self getUSBController] interfacesForVender:[self vendorID] product:[self productID]];
	NSString* sn = serialNumber;
	if([interfaces count] == 1 && ![sn length]){
		sn = [[interfaces objectAtIndex:0] serialNumber];
	}
	[self setSerialNumber:sn]; //to force usbinterface at doc startup
	[self checkUSBAlarm];
	[[self objectConnectedTo:ORLabJackUSBNextConnection] connectionChanged];
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];
	[self checkUSBAlarm];

}

-(void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
	NSImage* aCachedImage = [NSImage imageNamed:@"LabJack"];
    if(!usbInterface){
		NSSize theIconSize = [aCachedImage size];
		NSPoint theOffset = NSZeroPoint;
		
		NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
		[i lockFocus];
		
		[aCachedImage compositeToPoint:theOffset operation:NSCompositeCopy];
		
		if(!usbInterface || ![self getUSBController]){
			NSBezierPath* path = [NSBezierPath bezierPath];
			[path moveToPoint:NSMakePoint(20,10)];
			[path lineToPoint:NSMakePoint(40,30)];
			[path moveToPoint:NSMakePoint(40,10)];
			[path lineToPoint:NSMakePoint(20,30)];
			[path setLineWidth:3];
			[[NSColor redColor] set];
			[path stroke];
		}    
		
		[i unlockFocus];
		
		[self setImage:i];
		[i release];
    }
	else {
		[ self setImage: aCachedImage];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
}

- (NSString*) title 
{
	return [NSString stringWithFormat:@"LabJack (Serial# %@)",[usbInterface serialNumber]];
}

- (unsigned long) vendorID
{
	return 0x0CD5;
}

- (unsigned long) productID
{
	return 0x0001;	//LabJack ID
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORLabJackUSBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

#pragma mark ***Accessors

- (BOOL) digitalOutputEnabled
{
    return digitalOutputEnabled;
}

- (void) setDigitalOutputEnabled:(BOOL)aDigitalOutputEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDigitalOutputEnabled:digitalOutputEnabled];
    
    digitalOutputEnabled = aDigitalOutputEnabled;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackModelDigitalOutputEnabledChanged object:self];
}

- (unsigned long) counter
{
    return counter;
}

- (void) setCounter:(unsigned long)aCounter
{
    counter = aCounter;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackModelCounterChanged object:self];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackChannelNameChanged object:self userInfo:userInfo];
		
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackIoNameChanged object:self userInfo:userInfo];
		
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackDoNameChanged object:self userInfo:userInfo];
		
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
			[[[self undoManager] prepareWithInvocationTarget:self] setAdc:i withValue:adc[i]];
			adc[i] = aValue; 
			
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackAdcChanged object:self userInfo:userInfo];
		}	
	}
}

- (unsigned short) doDirection
{
    return doDirection;
}

- (void) setDoDirection:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoDirection:doDirection];
    doDirection = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackDoDirectionChangedNotification object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackIoDirectionChangedNotification object:self];
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
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackDoValueOutChangedNotification object:self];
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
		NSLog(@"IO 0x%0x\n",aMask);
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackIoValueOutChangedNotification object:self];
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
		[[[self undoManager] prepareWithInvocationTarget:self] setIoValueIn:ioValueIn];
		ioValueIn = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackIoValueInChangedNotification object:self];
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
		[[[self undoManager] prepareWithInvocationTarget:self] setDoValueIn:doValueIn];
		doValueIn = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackDoValueInChangedNotification object:self];
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
	
	
	if(!serialNumber){
		[[self getUSBController] releaseInterfaceFor:self];
	}
	else {
		[[self getUSBController] claimInterfaceWithSerialNumber:serialNumber for:self];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackModelSerialNumberChanged object:self];
}

- (ORUSBInterface*) usbInterface
{
	return usbInterface;
}

- (void) setUsbInterface:(ORUSBInterface*)anInterface
{
	
	[usbInterface release];
	usbInterface = anInterface;
	[usbInterface retain];
	[usbInterface setUsePipeType:kUSBInterrupt];
	//[usbInterface setUsePipeType:kUSBBulk];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ORLabJackModelUSBInterfaceChanged
	 object: self];
	[self checkUSBAlarm];
	[self firstWrite];
}

- (void) checkUSBAlarm
{
	if((usbInterface && [self getUSBController]) || !guardian){
		[noUSBAlarm clearAlarm];
		[noUSBAlarm release];
		noUSBAlarm = nil;
	}
	else {
		if(guardian){
			if(!noUSBAlarm){
				noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for LabJack"] severity:kHardwareAlarm];
				[noUSBAlarm setSticky:YES];		
			}
			[noUSBAlarm setAcknowledged:NO];
			[noUSBAlarm postAlarm];
		}
	}
	[self setUpImage];
}

- (void) interfaceAdded:(NSNotification*)aNote
{
	[[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
	[self firstWrite];
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
	ORUSBInterface* theInterfaceRemoved = [[aNote userInfo] objectForKey:@"USBInterface"];
	if((usbInterface == theInterfaceRemoved) && serialNumber){
		[self setUsbInterface:nil];
	}
}

- (NSString*) usbInterfaceDescription
{
	if(usbInterface)return [usbInterface description];
	else return @"?";
}

- (void) registerWithUSB:(id)usb
{
	[usb registerForUSBNotifications:self];
}

- (NSString*) hwName
{
	if(usbInterface)return [usbInterface deviceName];
	else return @"?";
}

- (void) makeUSBClaim:(NSString*)aSerialNumber
{
}

- (void) resetCounter
{
	doResetOfCounter = YES;
	[self sendIoControl];
}


#pragma mark ***HW Access
- (void) updateAll
{
	[self readAdcValues:0];
	[self readAdcValues:1];
	[self sendIoControl];
}

- (void) readAdcValues:(int) group
{
	if(usbInterface && [self getUSBController] && group >=0 && group <=1){
		unsigned char data[8];
		data[0] = 0x08 + 0 + (4*group);  //Bits 6-4 PGA, Bits 3-0 MUX first Channel
		data[1] = 0x08 + 1 + (4*group);  //Bits 6-4 PGA, Bits 3-0 MUX second Channel
		data[2] = 0x08 + 2 + (4*group);  //Bits 6-4 PGA, Bits 3-0 MUX third Channel
		data[3] = 0x08 + 3 + (4*group);  //Bits 6-4 PGA, Bits 3-0 MUX fourth Channel
		data[4] = led;					//led state	
		data[5] = 0xC0;
		data[6] = 0x00;					//Don't care
		data[7] = 0xFE | group;			// --- put in a unique label here.
		led = !led;
		[self writeData:data];
	}
}

- (void) sendIoControl
{
	if(usbInterface && [self getUSBController]){
		
		unsigned char data[8];
		data[0] = (doDirection>>8) & 0xFF;					//D15-D8 Direction
		data[1] = doDirection	   & 0xFF;					//D7-D0 Direction
		data[2] = ((doValueOut & ~doDirection) >> 8) & 0xFF;//D15-D8 State
		data[3] =  (doValueOut & ~doDirection) & 0xFF;		//D15-D8 State
		data[4] = (ioDirection<<4) | ((ioValueOut & ~ioDirection) & 0x0F); //I0-I3 Direction and state
		
		//updateDigital, resetCounter
		if(digitalOutputEnabled) data[5] = 0x10 | (doResetOfCounter<<5);
		else					 data[5] =  doResetOfCounter<<5;
		
		data[6] = 0x00;
		data[7] = 0x00;
		[self writeData:data];
	}
	doResetOfCounter = NO;
}


#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setDigitalOutputEnabled:[decoder decodeBoolForKey:@"digitalOutputEnabled"]];
    [self setSerialNumber:	[decoder decodeObjectForKey:@"serialNumber"]];
	int i;
	for(i=0;i<8;i++) {
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"channelName%d",i]];
		if(aName)[self setChannel:i name:aName];
		else [self setChannel:i name:[NSString stringWithFormat:@"Chan %d",i]];
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
	}
	[self setDoDirection:	[decoder decodeIntForKey:@"doDirection"]];
	[self setIoDirection:	[decoder decodeIntForKey:@"ioDirection"]];

    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:digitalOutputEnabled forKey:@"digitalOutputEnabled"];
    [encoder encodeObject:serialNumber	forKey: @"serialNumber"];
	int i;
	for(i=0;i<8;i++) {
		[encoder encodeObject:channelName[i] forKey:[NSString stringWithFormat:@"channelName%d",i]];
	}
	
	for(i=0;i<16;i++) {
		[encoder encodeObject:doName[i] forKey:[NSString stringWithFormat:@"DO%d",i]];
	}
	for(i=0;i<4;i++) {
		[encoder encodeObject:ioName[i] forKey:[NSString stringWithFormat:@"IO%d",i]];
	}

    [encoder encodeInt:doDirection		forKey:@"doDirection"];
    [encoder encodeInt:ioDirection		forKey:@"ioDirection"];
}

@end

@implementation ORLabJackModel (private)
- (void) readPipe
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		unsigned char data[8];
		int amountRead = [usbInterface readBytesOnInterruptPipeNoLock:data length:8];
		if(amountRead == 8){
			if((data[0] & 0x80)){
				//an AIO command
				int adcOffset = (data[1] & 0x1) * 4;
				[self setAdc:0 + adcOffset withValue:(data[2]&0x00f0)<<4 | data[3]];
				[self setAdc:1 + adcOffset withValue:(data[2]&0x000f)<<8 | data[4]];
				[self setAdc:2 + adcOffset withValue:(data[5]&0x00f0)<<4 | data[6]];
				[self setAdc:3 + adcOffset withValue:(data[5]&0x000f)<<8 | data[7]];				
			}
			else if((data[0] & 0xC0) == 0){
				//some digital I/O
				[self setDoValueIn:data[1]<<8 | data[2]];
				[self setIoValueIn:data[3]>>4];
				[self setCounter:(data[4]<<24) | (data[5]<<16) | (data[6]<<8) | data[7] ];
			}

		}
	}
	@catch(NSException* e){
	}
	@finally {
		[pool release];
	}
}

- (void) firstWrite
{
	unsigned char data[8];
	data[0] = 0x00;
	data[1] = 0x00;
	data[2] = 0x00;			
	data[3] = 0x00;
	data[4] = 0x00;
	data[5] = 0x57;
	data[6] = 0x00;			
	data[7] = 0x00;
	[usbInterface writeBytesOnInterruptPipe:data length:8];
	[NSThread detachNewThreadSelector: @selector(readPipe) toTarget:self withObject: nil];
}

- (void) writeData:(unsigned char*) data
{
	[usbInterface writeBytesOnInterruptPipe:data length:8];
	[NSThread detachNewThreadSelector: @selector(readPipe) toTarget:self withObject: nil];
	[ORTimer delay:0.02];
}
@end
