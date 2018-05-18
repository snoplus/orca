//
//  ORTDS2024Model.m
//  Orca
//  Created by Mark Howe on Mon, May 9, 2018.
//  Copyright (c) 2018 University of North Carolina. All rights reserved.
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
#import "ORTDS2024Model.h"
#import "ORUSBInterface.h"
#import "ORSafeQueue.h"

#define kMaxNumberOfPoints33220 0xFFFF

NSString* ORTDS2024SerialNumberChanged     = @"ORTDS2024SerialNumberChanged";
NSString* ORTDS2024USBInConnection         = @"ORTDS2024USBInConnection";
NSString* ORTDS2024USBNextConnection       = @"ORTDS2024USBNextConnection";
NSString* ORTDS2024USBInterfaceChanged     = @"ORTDS2024USBInterfaceChanged";
NSString* ORTDS2024Lock                    = @"ORTDS2024Lock";
NSString* ORTDS2024IsValidChanged		   = @"ORTDS2024IsValidChanged";
NSString* ORTDS2024PortClosedAfterTimeout  = @"ORTDS2024PortClosedAfterTimeout";
NSString* ORTDS2024TimeoutCountChanged     = @"ORTDS2024TimeoutCountChanged";
NSString* ORTDS2024PollTimeChanged         = @"ORTDS2024PollTimeChanged";
NSString* ORTDS2024SelectedChannelChanged  = @"ORTDS2024SelectedChannelChanged";
NSString* ORWaveFormDataChanged            = @"ORWaveFormDataChanged";

@interface ORTDS2024Model (private)
- (long) writeReadFromDevice: (NSString*) aCommand data: (char*) aData
                   maxLength: (long) aMaxLength;
- (void) curveThread;
@end

@implementation ORTDS2024Model

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[timeoutAlarm clearAlarm];
	[timeoutAlarm release];
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
    [serialNumber release];
     [super dealloc];
}

- (void) sleep
{
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
	noUSBAlarm = nil;
	[super sleep];
}

- (void) wakeUp 
{
    if([self aWake])return;
	[super wakeUp];
	[self checkNoUsbAlarm];
}

- (void) makeConnectors
{
    ORConnector* connectorObj1 = [[ ORConnector alloc ]
                                  initAt: NSMakePoint( 0, 0 )
                                  withGuardian: self];
    [[ self connectors ] setObject: connectorObj1 forKey: ORTDS2024USBInConnection ];
    [ connectorObj1 setConnectorType: 'USBI' ];
    [ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to gpib outputs
    [connectorObj1 setOffColor:[NSColor yellowColor]];
    [ connectorObj1 release ];

    ORConnector* connectorObj2 = [[ ORConnector alloc ]
                                  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, 0 )
                                  withGuardian: self];
    [[ self connectors ] setObject: connectorObj2 forKey: ORTDS2024USBNextConnection ];
    [ connectorObj2 setConnectorType: 'USBO' ];
    [ connectorObj2 addRestrictedConnectionType: 'USBI' ]; //can only connect to gpib inputs
    [connectorObj2 setOffColor:[NSColor yellowColor]];
    [ connectorObj2 release ];
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];
	[self checkNoUsbAlarm];
}


- (void) makeMainController
{
    [self linkToController:@"ORTDS2024Controller"];
}

//- (NSString*) helpURL
//{
//	return @"GPIB/Aglient_33220a.html";
//}


- (void) awakeAfterDocumentLoaded
{
	@try {
		okToCheckUSB = YES;
		[self connectionChanged];
	}
	@catch(NSException* localException) {
	}
}

- (void) connectionChanged
{
	NSArray* interfaces = [[self getUSBController] interfacesForVender:[self vendorID] product:[self productID]];
	NSString* sn = serialNumber;
	if([interfaces count] == 1 && ![sn length]){
		sn = [[interfaces objectAtIndex:0] serialNumber];
	}
	[self setSerialNumber:sn]; //to force usbinterface at doc startup
	[self checkNoUsbAlarm];	
	[[self objectConnectedTo:ORTDS2024USBNextConnection] connectionChanged];
	[self setUpImage];
}


-(void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"TDS2024"];
	
    NSSize theIconSize = [aCachedImage size];
    NSPoint theOffset = NSZeroPoint;
    
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];

    [aCachedImage drawAtPoint:theOffset fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];	
    if(!usbInterface || ![self getUSBController]){
        NSBezierPath* path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(20,2)];
        [path lineToPoint:NSMakePoint(40,22)];
        [path moveToPoint:NSMakePoint(40,2)];
        [path lineToPoint:NSMakePoint(20,22)];
        [path setLineWidth:3];
        [[NSColor redColor] set];
        [path stroke];
    }    
	
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
}

- (id)  dialogLock
{
	return @"ORTDS2024Lock";
}

- (NSString*) title 
{
   return [NSString stringWithFormat:@"TDS2024 (Serial# %@)",[usbInterface serialNumber]];
}

- (unsigned long) vendorID
{
	return 0x0699;
}

- (unsigned long) productID
{
	return 0x036a;
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORTDS2024USBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
	return [super acceptsGuardian:aGuardian] ||
    [aGuardian isMemberOfClass:NSClassFromString(@"ORMJDVacuumModel")];
}

#pragma mark ***Accessors

- (int)  selectedChannel
{
    return selectedChannel;
}
- (void) setSelectedChannel:(int)aChan
{
    if(aChan<0)aChan = 0;
    if(aChan>3)aChan = 3;
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedChannel:selectedChannel];
    selectedChannel = aChan;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTDS2024SelectedChannelChanged object:self];

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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTDS2024PollTimeChanged object:self];
}

- (void) setTimeoutCount:(int)aValue
{
    timeoutCount=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTDS2024TimeoutCountChanged object:self];
    
}

- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    if(pollTime==0)return;
    [self getCurve];
    [self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (int) timeoutCount
{
	return timeoutCount;
}

- (NSString*) serialNumber
{
    return serialNumber;
}

- (void) setSerialNumber:(NSString*)aSerialNumber
{
	if(!aSerialNumber)aSerialNumber = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setSerialNumber:serialNumber];
    
    [serialNumber autorelease];
    serialNumber = [aSerialNumber copy];    
	
	if(!serialNumber){
		[[self getUSBController] releaseInterfaceFor:self];
	}
	else [[self getUSBController] claimInterfaceWithSerialNumber:serialNumber for:self];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTDS2024SerialNumberChanged object:self];
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
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName: ORTDS2024USBInterfaceChanged
     object: self];
    
    [self setUpImage];
}

- (void) interfaceAdded:(NSNotification*)aNote
{
    [[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
    [self checkNoUsbAlarm];
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
    ORUSBInterface* theInterfaceRemoved = [[aNote userInfo] objectForKey:@"USBInterface"];
    if((usbInterface == theInterfaceRemoved) && serialNumber){
        [self setUsbInterface:nil];
        [self checkNoUsbAlarm];
    }
}

- (void) checkNoUsbAlarm
{
	if(!okToCheckUSB) return;
	if((usbInterface && [self getUSBController]) || !guardian){
		[noUSBAlarm clearAlarm];
		[noUSBAlarm release];
		noUSBAlarm = nil;
	}
	else {
		if(guardian && [self aWake]){
			if(!noUSBAlarm){
				noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for TD2024"] severity:kHardwareAlarm];
				[noUSBAlarm setHelpString:@"\n\nThe USB interface is no longer available for this object. This could mean the cable is disconnected or the power is off"];
				[noUSBAlarm setSticky:YES];		
			}
			[noUSBAlarm setAcknowledged:NO];
			[noUSBAlarm postAlarm];
		}
	}
	[self setUpImage];
}

- (NSArray*) usbInterfaces
{
	return [[self getUSBController]  interfacesForVender:[self vendorID] product:[self productID]];
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

- (void) logSystemResponse
{
}

#pragma mark •••Hardware Access
- (void) cancelTimeout
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
}

- (void) startTimeout:(int)aDelay
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:aDelay];
}

- (void) readWaveformPreamble
{
    char  reply[256];
    long n = [self writeReadFromDevice: @"WFMPre?"
                                  data: reply
                             maxLength: 256 ];
    reply[n] = "\n";
    NSString* s =  [NSString stringWithCString:reply encoding:NSASCIIStringEncoding];
    long nlPos = [s rangeOfString:@"\n"].location;
    if(nlPos != NSNotFound){
        s = [s substringWithRange:NSMakeRange(0,nlPos)];
        NSLog(@"%@\n",s);
    }
}
- (void) readDataInfo
{
    char  reply[256];
    long n = [self writeReadFromDevice: @"DAT?"
                                  data: reply
                             maxLength: 256 ];
    reply[n] = "\n";
    NSString* s =  [NSString stringWithCString:reply encoding:NSASCIIStringEncoding];
    long nlPos = [s rangeOfString:@"\n"].location;
    if(nlPos != NSNotFound){
        s = [s substringWithRange:NSMakeRange(0,nlPos)];
        NSLog(@"%@\n",s);
    }
}
- (void) readIDString
{
    char  reply[256];
    long n = [self writeReadFromDevice: @"*IDN?"
                                  data: reply
                             maxLength: 256 ];
    reply[n] = "\n";
    NSString* s =  [NSString stringWithCString:reply encoding:NSASCIIStringEncoding];
    long nlPos = [s rangeOfString:@"\n"].location;
    if(nlPos != NSNotFound){
        s = [s substringWithRange:NSMakeRange(0,nlPos)];
        NSLog(@"%@\n",s);
    }
}

- (void) getCurve
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(!curveIsBusy){
            [self curveThread];
    //[self performSelectorOnMainThread:@selector(postCouchDB) withObject:nil waitUntilDone:NO];
        }
    });
}


#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setSerialNumber:          [decoder decodeObjectForKey:    @"serialNumber"]];
    [self setPollTime:              [decoder decodeIntForKey:       @"pollTime"]];
    [self setSelectedChannel:       [decoder decodeIntForKey:       @"selectedChannel"]];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:serialNumber      forKey:@"serialNumber"];
    [encoder encodeInt:pollTime             forKey:@"pollTime"];
    [encoder encodeInt:selectedChannel      forKey:@"selectedChannel"];
}

#pragma mark ***Comm methods
- (long) readFromDevice: (char*) aData maxLength: (long) aMaxLength
{
    if(usbInterface && [self getUSBController]){
        @try {
            return [usbInterface readUSB488:aData length:aMaxLength];;
        }
        @catch(NSException* e){
        }
    }
    else {
        NSString *errorMsg = @"Must establish connection prior to issuing command\n";
        [NSException raise: @"TDS2024 Error" format: @"%@",errorMsg];
    }
    return 0;
}

- (void) writeToDevice: (NSString*) aCommand
{
    if(usbInterface && [self getUSBController]){
        aCommand = [aCommand stringByAppendingString:@"\n"];
        [usbInterface writeUSB488Command:aCommand eom:YES];
    }
    else {
        NSString *errorMsg = @"Must establish connection prior to issuing command\n";
        [NSException raise: @"TDS2024 Error" format:@"%@", errorMsg];
    }
}
- (void) queryAll
{
    
}
- (void) makeUSBClaim:(NSString*)aSerialNumber
{
    NSLog(@"claimed\n");
}

- (void) timeout
{
	[self setTimeoutCount: timeoutCount+1];
	if(timeoutCount>10){
		[self postTimeoutAlarm];
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	NSLogError(@"command timeout",[self fullID],nil);
}


- (void) clearTimeoutAlarm
{
	[timeoutAlarm clearAlarm];
	[timeoutAlarm release];
	timeoutAlarm = nil;
}

- (void) postTimeoutAlarm
{
	if(!timeoutAlarm){
		NSString* alarmName = [NSString stringWithFormat:@"%@ Serial Port Timeout",[self fullID]];
		timeoutAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kHardwareAlarm];
		[timeoutAlarm setSticky:NO];
		[timeoutAlarm setHelpString:@"The serial port is not working. The port was closed. Acknowledging this alarm will clear it. You will need to reopen the serial port to try again."];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORTDS2024PortClosedAfterTimeout object:self];
	}
	[timeoutAlarm postAlarm];
}

- (int) numPoints:(int)index
{
    return numPoints[index];
}

- (long) dataSet:(int)index valueAtChannel:(int)x
{
    return waveForm[index][x+6];
}
- (BOOL) curveIsBusy
{
    return curveIsBusy;
}
@end

@implementation ORTDS2024Model (private)
- (void) curveThread
{
    curveIsBusy = YES;
    int i;
    for(i=0;i<2500;i++){
        waveForm[selectedChannel][i] = 0;
    }
    @try {
        [self writeToDevice:[NSString stringWithFormat:@"DAT:SOU CH%d",selectedChannel+1]];
        [self writeToDevice:@"DATa:ENCdg RPBINARY"];
        [self writeToDevice:@"DATa:WIDth 1"];

        [self writeToDevice:@"DATa:START 1"];
        [self writeToDevice:@"DATa:STOP 2500"];
        //[self readWaveformPreamble]; //<--- remove or decode
        //[self readDataInfo];         //<--- remove or decode
        unsigned char  reply[2600];
        long n1 = 0;
        long n2 = 0;
        long n3 = 0;
        n1 = [self writeReadFromDevice: @"CURVE?"
                                  data: (char*)reply
                             maxLength: 2500];
        n1 = MIN(1024,n1);
        if(n1!=0){
            for(i=0;i<n1;i++){
                waveForm[selectedChannel][i] = reply[i];
            }
            
            n2 = [self readFromDevice: (char*)reply maxLength:2500];
            n2 = MIN(1024,n2);
            if(n2!=0){
                for(i=0;i<n2;i++){
                    waveForm[selectedChannel][i+n1] = reply[i];
                }
                n3 = [self readFromDevice: (char*)reply maxLength:2500 ];
                n3 = MIN(452,n3);

                for(i=0;i<n3;i++){
                    waveForm[selectedChannel][i+n1+n2] = reply[i];
                }
            }
        }
        long total = n1+n2+n3;
        if(total > 2500)total = 2500;
        numPoints[selectedChannel] = total;
    }
    @catch(NSException* e){
        
    }
    
    [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORWaveFormDataChanged object:self];

    curveIsBusy = NO;
}

- (long) writeReadFromDevice: (NSString*) aCommand data: (char*) aData
                   maxLength: (long) aMaxLength
{
    [self writeToDevice: aCommand];
    return [self readFromDevice: aData maxLength: aMaxLength];
}

@end
