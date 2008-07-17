//
//  ORUnivVoltHVCrateModel.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORUnivVoltHVCrateModel.h"
#import "NetSocket.h"
#import "ORMacModel.h"

//NSString* ORUnivVoltHVUSBConnector				= @"ORUnivVoltHVUSBConnector";
NSString* ORUnivVoltHVCrateIsConnectedChangedNotification		= @"ORUnivVoltHVCrateIsConnectedChangedNotification";
NSString* ORUnivVoltHVCrateIpAddressChangedNotification		    = @"ORUnivVoltHVCrateIpAddressChangedNotification";
NSString* ORUnivVoltHVCrateHVStatusChangedNotification			= @"ORUnivVoltHVCrateStatusChangedNotification";

@implementation ORUnivVoltHVCrateModel

#pragma mark •••initialization


- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed: @"UnivVoltHVCrateSmall"];
    NSImage* i = [[NSImage alloc] initWithSize: [aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint: NSZeroPoint operation: NSCompositeCopy];
    if([self powerOff]){
        NSAttributedString* s = [[[NSAttributedString alloc] initWithString: @"No Pwr"
                                                                 attributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [NSColor redColor],NSForegroundColorAttributeName,
                                                                     [NSFont fontWithName: @"Geneva" size:10],NSFontAttributeName,
                                                                     nil]] autorelease]; 
        [s drawAtPoint:NSMakePoint(35,10)];
    }
    
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy: 5 yBy: 10];
        [transform scaleXBy: 0.45 yBy: 0.45];
        [transform concat];
        NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
        OrcaObject* anObject;
        while(anObject = [e nextObject])
		{
            BOOL oldHighlightState = [anObject highlighted];
            [anObject setHighlighted: NO];
            [anObject drawSelf: NSMakeRect(0, 0, 500, [[self image] size].height)];
            [anObject setHighlighted:oldHighlightState];
        }
    }
    [i unlockFocus];
    [self setImage: i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
                postNotificationName:OROrcaObjectImageChanged
                              object:self];
}

- (void) dealloc
{
	[socket close];
	[socket release];
	

/*
	for( i = 0; i < kNplpCNumChannels;i++) 
		[dataStack[i] release];
*/	
    [super dealloc];
}
- (void) makeMainController
{
    [self linkToController: @"ORUnivVoltHVCrateController"];
}

- (void) makeConnectors
{
	//since CAMAC can have usb or pci adapters, we let the controllers make the connectors
}

- (void) connectionChanged
{
/*
	ORConnector* controllerConnector = [[self connectors] objectForKey:[self crateAdapterConnectorKey]];
	ORConnector* usbConnector = [[self connectors] objectForKey:ORUnivVoltHVUSBConnector];
	if(![usbConnector isConnected] && ![controllerConnector isConnected]){
		[usbConnector setHidden:NO];
		[controllerConnector setHidden:NO];
		if(cratePowerAlarm){
			[self setPowerOff:NO];
		    [cratePowerAlarm clearAlarm];
			[cratePowerAlarm release];
			cratePowerAlarm = nil;
			[self viewChanged:nil];
			[[NSNotificationCenter defaultCenter]
                postNotificationName:ORForceRedraw
                              object:self];

		}
	}
	else {
//		if([usbConnector isConnected]){
//			usingUSB = YES;
			[controllerConnector setHidden:YES];
		}
		else {
			usingUSB = NO;
			[usbConnector setHidden:YES];
		}
	}
	*/
}

#pragma mark •••Accessors

- (NSString*) ipAddress
{
    return ipAddress;
}

- (void) setIpAddress: (NSString *) anIpAddress
{
	if (!anIpAddress) anIpAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget: self] setIpAddress: anIpAddress];
    
    [ipAddress autorelease];
    ipAddress = [anIpAddress copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName: ORUnivVoltHVCrateIpAddressChangedNotification object: self];
}

- (NetSocket*) socket
{
	return socket;
}

- (void) setSocket: (NetSocket*) aSocket
{
	if(aSocket != socket)[socket close];
	[aSocket retain];
	[socket release];
	socket = aSocket;
    [socket setDelegate: self];
}

//------------------------------------
//depreciated (11/29/06) remove someday
/*- (NSString*) crateAdapterConnectorKey
{
	return @"UnivVoltHV Crate Adapter Connector";
}
*/
//------------------------------------


#pragma mark •••Notifications
/*- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : @"ORUnivVoltHVCrateStatus"
                       object : nil];

    
    [notifyCenter addObserver : self
                     selector : @selector(powerFailed:)
                         name : @"UnivVoltHVCratePowerOn"
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(powerRestored:)
                         name : @"UnivVoltHVCratePowerOff"
                       object : nil];
}
*/
- (NSString *) obtainHVStatus
{
	NSString*	finalStatus;
	NSString*	retString;
	NSString*	command = @"HVSTATUS";
	char retBuffer[ 256 ];
	
	@try
	{
		NSRange extResponse;
		NSRange isItContained;
		
		// Write the command.
		[socket write: command length: [command length]];	
	
		// Read back response from crate
		[socket read: &retBuffer amount: 256];
	
		retString = [[NSString alloc] initWithCString: (char *)retBuffer encoding: NSASCIIStringEncoding];
		NSLog( @"retString %@ ", retString );
	
		isItContained  = [retString rangeOfString: command];
		if ( isItContained.length > 0 ) {
			extResponse = NSMakeRange( command.length + 1, [retString length]- command.length -1 );
		} 
		else {
			extResponse = NSMakeRange( 0, 0 );
		}
		
		finalStatus = [retString substringWithRange: extResponse];
		NSLog( @"Returned value %@", finalStatus );
		
			}
	
	@catch (NSException *exception) {

			NSLog(@"Tests: Caught %@: %@", [exception name], [exception  reason]);
	} 
	
	@finally
	{
		[retString release];
		[command release];
	}

	return ( finalStatus );
}

/*- (void) powerFailed:(NSNotification*)aNotification
{
    if([aNotification object] == [self controllerCard] || [[aNotification object] guardian] == self){
        if(!cratePowerAlarm){
            cratePowerAlarm = [[ORAlarm alloc] initWithName:@"No UnivVoltHV Crate Power" severity:kHardwareAlarm];
            [cratePowerAlarm setSticky:YES];
            [cratePowerAlarm setHelpStringFromFile:@"NoUnivVoltHVCratePowerHelp"];
            [cratePowerAlarm postAlarm];
        } 
        [self setPowerOff:YES];
    }
}
*/

- (void) connect
{
	if (!isConnected)
	{
		[self setSocket: [NetSocket netsocketConnectedToHost: ipAddress port: kUnivVoltHVCratePort]];	
        [self setIsConnected: [socket isConnected]];
	}
}

- (void) hvPanic
{
}

- (void) hvOn
{
}

- (void) hvOff
{
}



#pragma mark ***Utilities

- (BOOL) isConnected
{
	return isConnected;
}

- (void) setIsConnected: (BOOL) aFlag
{
    isConnected = aFlag;
//	[self setReceiveCount: 0];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORUnivVoltHVCrateIsConnectedChangedNotification object: self];
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected: (NetSocket*) inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected: [socket isConnected]];
    }
}

- (void) netsocketDisconnected: (NetSocket*) inNetSocket
{
    if (inNetSocket == socket)
	{
        [self setIsConnected: NO];
		[socket autorelease];
		socket = nil;
    }
}


/*- (void) netsocket: (NetSocket*) inNetSocket dataAvailable: (unsigned) inAmount
{
    if (inNetSocket == socket) {
		[self dataBuffer: [inNetSocket readData]];
		[self shipValues];
	}
}
*/

#pragma mark ***Archival
// Encode decode variable names.
static NSString*	ORUnivVoltHVCrateIPAddress		= @"ORUnivVoltHVCrateIPAddress";

- (id) initWithCoder: (NSCoder*) aDecoder
{
    self = [super initWithCoder: aDecoder];
    
    [[self undoManager] disableUndoRegistration];
	[self setIpAddress: [aDecoder decodeObjectForKey: ORUnivVoltHVCrateIPAddress]];
    [[self undoManager] enableUndoRegistration];    
		
    return self;
}

- (void)encodeWithCoder: (NSCoder*) anEncoder
{
    [super encodeWithCoder: anEncoder];
    [anEncoder encodeObject: ipAddress forKey: ORUnivVoltHVCrateIPAddress];
}




@end
