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

NSString* ORUnivVoltHVCrateIsConnectedChangedNotification		= @"ORUnivVoltHVCrateIsConnectedChangedNotification";
NSString* ORUnivVoltHVCrateIpAddressChangedNotification		    = @"ORUnivVoltHVCrateIpAddressChangedNotification";
NSString* ORUnivVoltHVCrateHVStatusChangedNotification			= @"ORUnivVoltHVCrateStatusChangedNotification";
NSString* ORUnivVoltHVStatusAvailableNotification				= @"ORUnivVoltHVStatusAvailableNotification";
NSString* ORConfigAvailableNotification							= @"ORConfigAvailableNotification";
NSString* OREnetAvailableNotification							= @"OREnetAvailableNotification";

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
	[mSocket close];
	[mSocket release];
	

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
- (void) setIpAddress: (NSString *) anIpAddress
{
	if (!anIpAddress) anIpAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget: self] setIpAddress: anIpAddress];
    
    [ipAddress autorelease];
    ipAddress = [anIpAddress copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName: ORUnivVoltHVCrateIpAddressChangedNotification object: self];
}

- (NSString*) hvStatus
{ 
	return( mReturnFromSocket );
}

- (NSString *) ethernetConfig
{
	return( mReturnFromSocket );
}

- (NSString *) config
{
	return( mReturnFromSocket );
}

- (NSString*) ipAddress
{
    return ipAddress;
}

#pragma mark ***Crate Actions
- (NetSocket*) socket
{
	return mSocket;
}

- (void) setSocket: (NetSocket*) aSocket
{
	if(aSocket != mSocket)[mSocket close];
	[aSocket retain];
	[mSocket release];
	mSocket = aSocket;
    [mSocket setDelegate: self];
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
- (void) handleDataReturn: (NSData*) aSomeData
{
//	NSString* returnFromSocket;	
	// For commands that return ascii data parse the data.
	if ( mLastCommand <= 3 ) {  // kUVEnet
		mReturnFromSocket = [self interpretDataFromSocket: aSomeData];
	}

	switch( mLastCommand )
	{
		case eUVHVStatus: // 	
			[[NSNotificationCenter defaultCenter] postNotificationName: ORUnivVoltHVStatusAvailableNotification object: self];	
			break;	
			
		case eUVConfig:
			[[NSNotificationCenter defaultCenter] postNotificationName: ORConfigAvailableNotification object: self];
			break;
			
		case eUVEnet:
			[[NSNotificationCenter defaultCenter] postNotificationName: OREnetAvailableNotification object: self];

	}
	return;
}

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
- (void) obtainHVStatus
{
//	NSString*	finalStatus;
//	NSString*	retString;
	
	@try
	{
		NSString* command = [NSString stringWithFormat: @"HVSTATUS"];	
		const char* buffer = [command cStringUsingEncoding: NSASCIIStringEncoding];
		
		// Write the command.
		NSLog( @"Command: %s,  length:%d", buffer, [command length] + 1 );
		[mSocket write: buffer length: [command length] + 1];	

/*		int lenString = strlen( charBuffer );
		NSLog( @"Length of command string %d", lenString );
		[mSocket write: charBuffer length: [command length]];	
*/	
		// Interpret return response
		//[self interpretResponse: kHVStatus];
		// Read back response from crate
/*		[mSocket read: &retBuffer amount: 256];
	
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
		*/	
	}
	
	@catch (NSException *exception) {

			NSLog(@"Tests: Caught %@: %@", [exception name], [exception  reason]);
	} 
	
	@finally
	{
	//	[command release];
	}
}

- (void) obtainConfig
{
	
	@try
	{
		NSString* command = [NSString stringWithFormat: @"CONFIG"];	
		const char* buffer = [command cStringUsingEncoding: NSASCIIStringEncoding];
		
		// Write the command.
		NSLog( @"Command: %s,  length:%d", buffer, [command length] + 1 );
		[mSocket write: buffer length: [command length] + 1];	
	}
	@catch (NSException *exception) {

			NSLog(@"Tests: Caught %@: %@", [exception name], [exception  reason]);
	} 
	
	@finally
	{
	//	[command release];
	}
}

- (void) obtainEthernetConfig
{
	
	@try
	{
		NSString* command = [NSString stringWithFormat: @"Enet"];	
		const char* buffer = [command cStringUsingEncoding: NSASCIIStringEncoding];
		
		// Write the command.
		NSLog( @"Command: %s,  length:%d", buffer, [command length] + 1 );
		[mSocket write: buffer length: [command length] + 1];	
	}
	@catch (NSException *exception) {

			NSLog(@"Tests: Caught %@: %@", [exception name], [exception  reason]);
	} 
	
	@finally
	{
	//	[command release];
	}
}

- (void) connect
{
	
	if (!mIsConnected)
	{

		[self setSocket: [NetSocket netsocketConnectedToHost: ipAddress port: kUnivVoltHVCratePort]];	
//        [self setIsConnected: [mSocket isConnected]];  // setIsConnected sends out notification.
//		if ( isConnected )
//		{
//			NSLog( @"Connected to %@", ipAddress );
//			[mSocket read: &retBuffer amount: 256];
//			NSLog( @"Return from connect %s", retBuffer);
//		}
//		else
//		{
//			NSLog( @"Disconnected from %@", ipAddress );
//		}
	}
}
- (void) disconnect
{
	if (mIsConnected ) {	
		[mSocket close];
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
- (NSString *) interpretDataFromSocket: (NSData *)aDataObject
{
	NSString*	returnStringFromSocket;
	char		returnBufferArray[ 257 ];
//	char		tmpArray[ 2 ];
	int			lengthOfReturn = 0;
	int			i;
	int			count;
	BOOL		newLine;
	
//	tmpArray[ 1 ] = '\0';

	@try
	{
		// Get amount of data and data itself.
		lengthOfReturn = [aDataObject length];
		[aDataObject getBytes: returnBufferArray length: lengthOfReturn];
		NSLog( @"Return string: %s  length: %d", returnBufferArray, lengthOfReturn );
		
		count = 0;
		newLine = YES;
		
		// Loop through characters in data array since there exist embedded \0 in the array.  We replace these '\0'
		// with \n.
		for ( i = 0; i < lengthOfReturn; i++ )
		{
			if ( newLine && returnBufferArray[ i ] == 'C' ) {
				newLine = NO;
			}

			if ( !newLine && returnBufferArray[ i ] == '\0' ) {

				newLine = YES;
				returnBufferArray[ i ] = '\n';
				count++;
			}
//			tmpArray[ 0 ] = returnBufferArray[ i ];
//			NSLog( @"Char( %d ): %s", i, tmpArray );
		}
		
		// Convert modified char array to string.
		returnStringFromSocket = [[[NSString alloc] initWithFormat: @"%s\n", returnBufferArray] autorelease];
		NSLog( @"Full return string:\n %@", returnStringFromSocket );
		return ( returnStringFromSocket );
    }
	@catch (NSException *exception) {

		NSLog(@"handleDataReturn: Caught %@: %@", [exception name], [exception  reason]);
	} 
	
	@finally
	{
		return( returnStringFromSocket );
	}
}

- (BOOL) isConnected
{
	return mIsConnected;
}

- (void) setIsConnected: (BOOL) aFlag
{
    mIsConnected = aFlag;
//	[self setReceiveCount: 0];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORUnivVoltHVCrateIsConnectedChangedNotification object: self];
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected: (NetSocket*) inNetSocket
{
    if(inNetSocket == mSocket){
        [self setIsConnected: [mSocket isConnected]];
    }
}

- (void) netsocketDisconnected: (NetSocket*) inNetSocket
{
    if (inNetSocket == mSocket)
	{
        [self setIsConnected: NO];
		[mSocket autorelease];
		mSocket = nil;
    }
}


- (void) netsocket: (NetSocket*) anInNetSocket dataAvailable: (unsigned) anInAmount
{
    if (anInNetSocket == mSocket) {
		[self handleDataReturn: [anInNetSocket readData]];
	}
}


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
