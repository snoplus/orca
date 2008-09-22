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
#import "ORQueue.h"

NSString* ORUVHVCrateIsConnectedChangedNotification		= @"ORUVHVCrateIsConnectedChangedNotification";
NSString* ORUVHVCrateIpAddressChangedNotification	    = @"ORUVHVCrateIpAddressChangedNotification";
//NSString* ORUnivVoltHVCrateHVStatusChangedNotification			= @"ORUnivVoltHVCrateStatusChangedNotification";
NSString* ORUVHVCrateHVStatusAvailableNotification		= @"ORUVHVCrateHVStatusAvailableNotification";
NSString* ORUVHVCrateConfigAvailableNotification		= @"ORUVHVCrateConfigAvailableNotification";
NSString* ORUVHVCrateEnetAvailableNotification		    = @"ORUVHVCrateEnetAvailableNotification";

// HV Module commands
NSString* ORHVkCrateHVStatus							= @"HVSTATUS";
NSString* ORHVkCrateConfig							    = @"CONFIG";
NSString* ORHVkCrateEnet								= @"ENET";

NSString* ORHVkModuleDMP								= @"DMP";

NSString* UVkUnit	 = @"Unit";
NSString* UVkChnl    = @"Chnl";
NSString* UVkCommand = @"Command";

@implementation ORUnivVoltHVCrateModel

#pragma mark •••initialization

- (id) init
{
	self = [super init];
	if ( self ) {
		mQueue = [ORQueue init];
	}
	return ( self );
}

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

    [[NSNotificationCenter defaultCenter] postNotificationName: ORUVHVCrateIpAddressChangedNotification object: self];
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

- (NetSocket*) socket
{
	return mSocket;
}

#pragma mark ***Crate Actions
- (void) setSocket: (NetSocket*) aSocket
{
	if(aSocket != mSocket)[mSocket close];
	[aSocket retain];
	[mSocket release];
	mSocket = aSocket;
    [mSocket setDelegate: self];
}
 
- (void) obtainHVStatus
{
	int		unit = -1;
	int		chnl = -1;
	[self sendCommand: unit channel: chnl command: ORHVkCrateHVStatus];
}

- (void) sendGeneralCommand: (NSString*) aCommand
{
	[self sendCommand: -1 channel: -1 command: aCommand];
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
	// Get oldest command
	NSDictionary* recentCommand = [mQueue dequeue];
	
	// Check that it matches return.
	NSString* command = [recentCommand objectForKey: UVkCommand];
	
	// For commands that return ascii data parse the data.
	mReturnFromSocket = [self interpretDataFromSocket: aSomeData];
	NSArray* tokens = [mReturnFromSocket componentsSeparatedByString: @" "]; 
	
	NSLog( @"Queue command %s, return command %s", recentCommand, tokens[ 0 ] );
	
	if ([tokens count] > 0 && [[tokens objectAtIndex: 0] isEqualTo: command]) 
	{
		NSString* command = [tokens objectAtIndex: 0];
		
		// crate only returns.
		if ( [command isEqualTo: ORHVkCrateHVStatus] )
		{
			NSLog( @"Send notification about HVStatus.");
			[[NSNotificationCenter defaultCenter] postNotificationName: ORUVHVCrateHVStatusAvailableNotification object: self];
		}
		else if ( [command isEqualTo: ORHVkCrateConfig] )
		{
			NSLog( @"Send notification about Config.");
			[[NSNotificationCenter defaultCenter] postNotificationName: ORUVHVCrateConfigAvailableNotification object: self];
		}
		
		else if ( [command isEqualTo: ORHVkCrateEnet] )
		{
			NSLog( @"Send notification about Enet.");
			[[NSNotificationCenter defaultCenter] postNotificationName: ORUVHVCrateConfigAvailableNotification object: self];
		}
		
		else if ( [command isEqualTo: ORHVkModuleDMP] )
		{
			NSLog( @"Send notification about Ethernet.");
			[[NSNotificationCenter defaultCenter] postNotificationName: ORUVHVCrateEnetAvailableNotification object: self];
		}
	}

//		if ( mLastError != Nil ) [mLastError release];
//		[mLastError stringWithSting: @"Returned data from HV unit '%s' with last command queue '%s'.", 
//		NSLog( mLastError 
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

- (void) obtainConfig
{
	
	@try
	{
		[self sendCommand: -1 channel: -1 command: ORHVkCrateConfig];
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
/*		NSString* command = [NSString stringWithFormat: ORHVkCrateEnet];	
			
		// Write the command.
		
		
*/
//		mLastCommand = eUVEnet;	
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
		NSLog( @"Return string '%s'  length: %d", returnBufferArray, lengthOfReturn );
		
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

- (void) sendCommand: (int) aCurrentUnit channel: (int) aCurrentChnl command: (NSString*) aCommand
{
//	@try
		NSNumber* unitObj = [NSNumber numberWithInt: aCurrentUnit];
		NSNumber* chnlObj = [NSNumber numberWithInt: aCurrentChnl];
		
		NSMutableDictionary* commandObj = [NSMutableDictionary dictionaryWithCapacity: 3];
		
		[commandObj setObject: unitObj forKey: UVkUnit];
		[commandObj setObject: chnlObj forKey: UVkChnl];
		[commandObj setObject: aCommand forKey: UVkCommand];

		[mQueue enqueue: commandObj];
		
		if (aCurrentChnl < 0 ) 
		{
			const char* buffer = [aCommand cStringUsingEncoding: NSASCIIStringEncoding];
		
			NSLog( @"Command: %s,  length:%d", buffer, [aCommand length] + 1 );
			[mSocket write: buffer length: [aCommand length] + 1];	
//			mLastCommand = eUVHVStatus;
		}
		
//	@catch (NSException *exception) {

//			NSLog(@"Tests: Caught %@: %@", [exception name], [exception  reason]);
//	} 
	
//	@finally


 }

- (void) setIsConnected: (BOOL) aFlag
{
    mIsConnected = aFlag;
//	[self setReceiveCount: 0];
    [[NSNotificationCenter defaultCenter] postNotificationName: ORUVHVCrateIsConnectedChangedNotification object: self];
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
