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
NSString* ORUnitInfoAvailableNotification               = @"ORUnitInfoAvailableNotification";

// HV Module commands
NSString* ORHVkCrateHVStatus							= @"HVSTATUS";
NSString* ORHVkCrateConfig							    = @"CONFIG";
NSString* ORHVkCrateEnet								= @"ENET";
NSString* ORHVkHVPanic									= @"IMOFF";
NSString* ORHVkHVOn										= @"HVON";
NSString* ORHVkHVOff									= @"HVOFF";

NSString* ORHVkModuleDMP								= @"DMP";

NSString* UVkUnit										= @"Unit";
NSString* UVkChnl										= @"Chnl";
NSString* UVkCommand									= @"Command";

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
	
	// setIsConnected sends notification message
    [mSocket setDelegate: self];
}
 
- (void) obtainHVStatus
{
	int		unit = -1;
	int		chnl = -1;
	[self sendCommand: unit channel: chnl command: ORHVkCrateHVStatus];
}
 

- (void) sendCrateCommand: (NSString*) aCommand
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
	int			i;
	int			returnCode;
	bool		f_NotFound;
	int			retSlot;
	int			scanLoc;
	int			retChnl;
	
	f_NotFound = YES;
	i = 0;

	// Get oldest command
	NSDictionary* recentCommand = [mQueue dequeue];
	
	// Check that it matches return.
	NSString* command = [recentCommand objectForKey: UVkCommand];
	NSNumber* chnlNum = [recentCommand objectForKey: UVkChnl];
	NSNumber* slotNum = [recentCommand objectForKey: UVkUnit];
	
	// For commands that return ascii data parse the data.
	mReturnFromSocket = [self interpretDataFromSocket: aSomeData returnCode: &returnCode];
	NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @" \n"];
	NSArray* tokens = [mReturnFromSocket componentsSeparatedByCharactersInSet: separators]; 
	
	// Get slot and channel
	while ( f_NotFound && i < [tokens count] )
	{
		NSString* slotChnl = [tokens objectAtIndex: 1];
		char retChar = [slotChnl characterAtIndex: 0];
		if ( retChar == 'S' || retChar == 's' )
		{
			NSScanner* scannerForSlotAndChnl = [NSScanner scannerWithString: slotChnl];
			[scannerForSlotAndChnl setScanLocation: 1];
			[scannerForSlotAndChnl scanInt: &retSlot];
			scanLoc = [scannerForSlotAndChnl scanLocation];
			[scannerForSlotAndChnl setScanLocation: scanLoc + 1];
			[scannerForSlotAndChnl scanInt: &retChnl];
			f_NotFound = NO;
		}
	}
	
	
	if ( [tokens count] > 0 )
	{
		NSString* retCommand = [tokens objectAtIndex: 0];
		NSLog( @"Returned command '%@', recent command '%@'.", retCommand, command );
		if ( [retCommand isEqualTo: command]  )
		{
			// Debug only.
			for ( i = 0; i < [tokens count]; i++ )
			{
				NSString* object = [tokens objectAtIndex: i];
				NSLog( @"Token ( %d ) string: %@\n", i, object );
			}
	
	
			NSString* command = [tokens objectAtIndex: 0];
			NSLog( @"Queue command %@, return command %@", recentCommand, tokens[ 0 ] );
	
			if ( [chnlNum intValue] < 0 ) { // crate command
		
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
				
				else if ( [command isEqualTo: ORHVkHVOn] )
				{
					NSLog( @"Send notification about HV being turned on.");
					[[NSNotificationCenter defaultCenter] postNotificationName: ORUVHVCrateHVStatusAvailableNotification object: self];
				}
				
				else if ( [command isEqualTo: ORHVkHVOff] )
				{
					NSLog( @"Send notification about HV being turned off.");
					[[NSNotificationCenter defaultCenter] postNotificationName: ORUVHVCrateHVStatusAvailableNotification object: self];
				}

				else if ( [command isEqualTo: ORHVkHVPanic] )
				{
					NSLog( @"Send notification about HV PANIC.");
					[[NSNotificationCenter defaultCenter] postNotificationName: ORUVHVCrateHVStatusAvailableNotification object: self];
				}
			}
		
			// notify HV unit about return from command.
			else
			{
				
				NSMutableDictionary* channelIdentification = [[NSMutableDictionary alloc] init]; 
				[channelIdentification setObject: slotNum forKey: UVkUnit];
				[channelIdentification setObject: chnlNum forKey: UVkChnl];
				[channelIdentification setObject: command forKey: UVkCommand];
				NSDictionary* channelIdObj = [NSDictionary dictionaryWithDictionary: channelIdentification];
				NSLog( @"Send notification about HV Unit - slot: %d, chnl: %d\n", slotNum, chnlNum);
				[[NSNotificationCenter defaultCenter] postNotificationName: ORUnitInfoAvailableNotification object: self userInfo: channelIdObj];
			}
		}
	}

//		if ( mLastError != Nil ) [mLastError release];
//		[mLastError stringWithSting: @"Returned data from HV unit '%s' with last command queue '%s'.", 
//		NSLog( mLastError 
	return;
}


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
		// setSocket method will send out notification.
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
	[self sendCrateCommand: ORHVkHVPanic];
}

- (void) hvOn
{
	[self sendCrateCommand: ORHVkHVOn];
}

- (void) hvOff
{
	[self sendCrateCommand: ORHVkHVOff];
}



#pragma mark ***Utilities
//------------------------------------------------------------------------------------------
// \note:	Data is returned as follows:
//			012345678901234567890123456789012345678901234567890
//			     1 HVSTATUS
//          C    1 DMP S0.10
//
//			Where column 0 is either blank or has the letter C.  C means that more data follows
//			this line.  The next 4 columns form the return code: 
//			1 - last command succesful.
//			2 - Not used.
//			3 - Crate is in local command.  Need to turn key.
//			4 - Last command a PANIC.
//			
- (NSString*) interpretDataFromSocket: (NSData*) aDataObject returnCode: (int*) aReturnCode
{
	const int	NUMcCODENUM = 5;
	NSString*	returnStringFromSocket;
	NSString*	returnCodeAsString;
	char		returnBufferArray[ 257 ];	// 0 Byte is continuation character C is continuation.
	char		returnBufferString[ 257 ];
	char		returnCodeArray[ NUMcCODENUM + 1  ];
	char		displayArray[ 2 ];
	int			lengthOfReturn = 0;
	int			i;
	int			responseIndex;
	int			j;
	int			nChar;
	BOOL		newLine;
	BOOL		haveCode;
	
	
	@try
	{
		// Get amount of data and data itself.
		lengthOfReturn = [aDataObject length];
		[aDataObject getBytes: returnBufferArray length: lengthOfReturn];
		NSLog( @"Return string '%s'  length: %d\n", returnBufferArray, lengthOfReturn );
		
		returnCodeArray[ NUMcCODENUM ] = '\0';
		
		// Zero return array
		for ( i = 0; i < lengthOfReturn; i++ ) {
			returnBufferString[ i ] = '\0';
		}
		
		displayArray[ 1 ] = '\0';
		for ( i = 0; i < lengthOfReturn; i++ ) {
			displayArray[ 0 ] = returnBufferArray[ i ];
			if ( returnBufferArray[ i ] == '\0' ) 
				displayArray[ 0 ] = '-';
			else if ( returnBufferArray[ i ] == '\n' )
				displayArray[ 0 ] = '/';

			NSLog( @"Interpreted.  Char( %d ): %s\n", i, displayArray );
		}
		
		nChar = 0;
				
		// Find the C and \0 in the character array.  Replace them with \n except for the last
		//\0 which stays.
		// Also find return code which is number consisting of 4 bits at front of return string.
		responseIndex = 0;
		j = -1;
		newLine = YES;
		haveCode = NO;
		
		for ( i = 0; i < lengthOfReturn; i++ )
		{
			if ( !haveCode && !newLine ) {
				if ( returnBufferArray[ i ] == '\0' ) {
					if ( i == lengthOfReturn - 1 ) {
						returnBufferString[ responseIndex++ ] = '\0';
					} 
					else {
						returnBufferString[ responseIndex++ ] = '\n';
					}
					newLine = true;						
				} 
				else {
					returnBufferString[ responseIndex++ ] = returnBufferArray[ i ];
				nChar++;
				}
			}

			if ( haveCode ) {
				j++;
				if ( j < NUMcCODENUM ) {
					returnCodeArray[ j ] = returnBufferArray[ i ];
				} else
				{
					haveCode = NO;
					j = -1;
				}
			}
			
			if ( newLine ) {
				if ( returnBufferArray[ i ] == 'C' || returnBufferArray[ i ] == ' ' ) {
					newLine = NO;
					haveCode = YES;
				}
			}						
		}
		
		// Debugging display each character in returnBufferString.		
		displayArray[ 1 ] = '\0';
		for ( i = 0; i < nChar; i++ ) {
			displayArray[ 0 ] = returnBufferString[ i ];
			NSLog( @"Char( %d ): %s\n", i, displayArray );
		}
			

		// Get the return code as both number and string.
		returnCodeAsString = [[NSString alloc] initWithBytes: returnCodeArray length: 5 encoding: NSASCIIStringEncoding];
		*aReturnCode = [returnCodeAsString intValue];
		
		NSLog( @"Return Code: %@, number: %d\n", returnCodeAsString, *aReturnCode);
		
		// Convert modified char array to string.
		returnStringFromSocket = [[[NSString alloc] initWithFormat: @"%s\n\0", returnBufferString] autorelease];
		NSLog( @"Full return string:\n %@\n", returnStringFromSocket );
   }
	
	@catch (NSException *exception) {

		NSLog(@"handleDataReturn: Caught %@: %@\n", [exception name], [exception  reason]);
	} 
	
	@finally
	{
	}
	
	[returnCodeAsString release];
	return ( returnStringFromSocket );
}

- (BOOL) isConnected
{
	return mIsConnected;
}

//------------------------------------------------------------------------------------------------
// Sends actual command to crate and unit from computer.  Please note that commands that are sent
// to entire crate cannot have slot and channel number set.  If command is only for slot then Sx.
// is the form of the command where x is the slot number.  If command is directed at specific channel
// then command is of the form Sx.y where y is the channel number. 
//------------------------------------------------------------------------------------------------
- (void) sendCommand: (NSString*) aCommand
{
//	NSString* fullCommand;
//	@try
//		NSNumber* unitObj = [NSNumber numberWithInt: aCurrentUnit];
//		NSNumber* chnlObj = [NSNumber numberWithInt: aCurrentChnl];
		
//		NSMutableDictionary* commandObj = [NSMutableDictionary dictionaryWithCapacity: 3];
		
//		[commandObj setObject: unitObj forKey: UVkUnit];
//		[commandObj setObject: chnlObj forKey: UVkChnl];
//		[commandObj setObject: aCommand forKey: UVkCommand];

		[mQueue enqueue: aCommand];
		
/*
		if ( aCurrentChnl > -1 )
		{
			fullCommand = [aCommand stringByAppendingFormat: @" S%d.%d", aCurrentUnit, aCurrentChnl];
		}
		else if ( aCurrentUnit > -1 )
		{
			fullCommand = [aCommand stringByAppendingFormat: @"S%d", aCurrentUnit];
		} 
		else
		{
			fullCommand = aCommand;
		}
*/			
		const char* buffer = [aCommand cStringUsingEncoding: NSASCIIStringEncoding];
		
		NSLog( @"Command: %s,  length:%d", buffer, [aCommand length] + 1 );
		[mSocket write: buffer length: [aCommand length] + 1];	
//			mLastCommand = eUVHVStatus;
		
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
