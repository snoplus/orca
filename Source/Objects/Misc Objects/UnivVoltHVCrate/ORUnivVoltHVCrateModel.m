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

NSString* HVCrateIsConnectedChangedNotification			= @"HVCrateIsConnectedChangedNotification";
NSString* HVCrateIpAddressChangedNotification			= @"HVCrateIpAddressChangedNotification";
//NSString* ORUnivVoltHVCrateHVStatusChangedNotification			= @"ORUnivVoltHVCrateStatusChangedNotification";
NSString* HVCrateHVStatusAvailableNotification			= @"HVCrateHVStatusAvailableNotification";
NSString* HVCrateConfigAvailableNotification			= @"HVCrateConfigAvailableNotification";
NSString* HVCrateEnetAvailableNotification				= @"HVCrateEnetAvailableNotification";
NSString* HVUnitInfoAvailableNotification				= @"HVUnitInfoAvailableNotification";
NSString* HVSocketNotConnectedNotification				= @"HVSocketNotConnectedNotification";

// HV crate commands
NSString* ORHVkCrateHVStatus							= @"HVSTATUS";
NSString* ORHVkCrateConfig							    = @"CONFIG";
NSString* ORHVkCrateEnet								= @"ENET";
NSString* ORHVkCrateHVPanic								= @"IMOFF";
NSString* ORHVkCrateHVOn								= @"HVON";
NSString* ORHVkCrateHVOff								= @"HVOFF";

NSString* ORHVkNoReturn = @"No Return";

//NSString* ORHVkModuleDMP								= @"DMP";

// Entries in data return dictionary
NSString* UVkCmdId	 = @"CmdId";
NSString* UVkSlot	 = @"Slot";
NSString* UVkChnl    = @"Chnl";
NSString* UVkCommand = @"Command";
NSString* UVkReturn  = @"Return";

NSString* UVkErrorMsg = @"ErrorMsg";

@implementation ORUnivVoltHVCrateModel

#pragma mark •••initialization

- (id) init
{
	self = [super init];
	if ( self ) {
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
	if ( mCmdQueue != nil ) [mCmdQueue dealloc];
//	if ( mQueueReturn != nil ) [mQueueReturn dealloc];
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
}

#pragma mark •••Accessors
- (void) setIpAddress: (NSString *) anIpAddress
{
	if (!anIpAddress) anIpAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget: self] setIpAddress: anIpAddress];
    
    [ipAddress autorelease];
    ipAddress = [anIpAddress copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName: HVCrateIpAddressChangedNotification object: self];
}

- (NSString*) hvStatus
{ 
	if (mMostRecentHVStatus != nil )
	{
		return( mMostRecentHVStatus );
	}	
	return( ORHVkNoReturn );
}

- (NSString *) ethernetConfig
{
	if (mMostRecentEnetConfig != nil )
	{
		return( mMostRecentEnetConfig );
	}	
	return( ORHVkNoReturn );
}

- (NSString *) config
{
//	NSDictionary* queuedCommand = [mQueue dequeue];
//	NSString* command = [queuedCommand objectForKey: UVkCommand];
//	NSString* command = [mReturnToUnit objectForKey: UVkCommand];
	
//	if ( [command isEqualTo: ORHVkCrateConfig] )
	if (mMostRecentConfig != nil )
	{
		return( mMostRecentConfig );
	}	
	return( ORHVkNoReturn );
}

- (NSString*) ipAddress
{
    return ipAddress;
}

- (NetSocket*) socket
{
	return mSocket;
}

/*- (NSDictionary*) returnDataToHVUnit
{
	return( mReturnToUnit );
}
*/

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
	[self sendCrateCommand: ORHVkCrateHVStatus];
}
 

- (void) hvPanic
{
	[self sendCrateCommand: ORHVkCrateHVPanic];
}

- (void) turnHVOn
{
	[self sendCrateCommand: ORHVkCrateHVOn];
}

- (void) turnHVOff
{
	[self sendCrateCommand: ORHVkCrateHVOff];
}

- (void) sendCrateCommand: (NSString*) aCommand
{
	[self queueCommand: 0 totalCmds: 1 slot: -1 channel: -1 command: aCommand];
}

//------------------------------------------------------------------------------------------------
// Sends actual command to crate and unit from computer.  Please note that commands that are sent
// to entire crate cannot have slot and channel number set.  If command is only for slot then Sx.
// is the form of the command where x is the slot number.  If command is directed at specific channel
// then command is of the form Sx.y where y is the channel number. 
//
// Implemented both cmdQueue and retQueue queues.  queueCommand allows the queuing of multiple
// commands in cmdQueue.  If only one command is queued then this routine automatically sends 
// that command.  If many commands need to be sent then queueCommand can be called multiple times 
// without a single command being sent. A single call to sendCommandBasic with ensure that all the 
// queued
// commands are sent out in order.  sendCommandBasic works in tandem with HandleReturnData to 
// ensure that commands are sent and received synchonously, which is required by the hardware.
// each return is received from the hardware.

// sendCommand is issued, the number of commands to send is also given.  This routine will wait until
// all commands have been issued.  
//  
//------------------------------------------------------------------------------------------------
- (void) queueCommand: (int) aCmdId			// 0 based.
		     totalCmds: (int) aTotalCmds
                  slot: (int) aCurrentUnit 
			   channel: (int) aCurrentChnl 
			   command: (NSString*) aCommand 
{

	if ( aCmdId == 11 )
		NSLog( @"id: %d, total: %d\n", aCmdId, aTotalCmds );
		
	@try
	{
		// see if all commands have been downloaded.
		if ( aTotalCmds > aCmdId )	
		{
			// Have first command - set up parameters
			if ( aCmdId == 0 )
			{
				mCmdsToProcess = aTotalCmds;
//				mRetsToProcess = aTotalCmds;
				mTotalCmds = aTotalCmds;
			}
		
			if ( mCmdQueue == nil )
			{
				mCmdQueue = [[ORQueue alloc] init];
				[mCmdQueue retain];
			}
		
			// Create command dictionary object
			NSNumber* cmdId = [NSNumber numberWithInt: aCmdId];
			NSNumber* unitObj = [NSNumber numberWithInt: aCurrentUnit];
			NSNumber* chnlObj = [NSNumber numberWithInt: aCurrentChnl];
		
			NSMutableDictionary* commandObj = [NSMutableDictionary dictionaryWithCapacity: 4];
		
			[commandObj setObject: cmdId forKey: UVkCmdId];
			[commandObj setObject: unitObj forKey: UVkSlot];
			[commandObj setObject: chnlObj forKey: UVkChnl];
			[commandObj setObject: aCommand forKey: UVkCommand];

			mCmdsToProcess--;
			mRetsToProcess++;
			[mCmdQueue enqueue: commandObj];
			
			NSLog( @"Queue cmd with id: %d - %@\n", aCmdId, aCommand );
//			} 
		}
		
		// Queue has been filled so dequeue a single command.
		if ( mCmdsToProcess == 0 && mTotalCmds == mRetsToProcess )
		{
			[self sendCommandBasic];
		}	
		
	}	
	
	@catch (NSException *exception) {

			NSLog(@"Tests: Caught %@: %@", [exception name], [exception  reason]);
	} 
	
	@finally
	{
	}
}

/*- (void) sendCommandFromQueue
{
	NSDictionary* cmdDictObj = [mCmdQueue dequeue];
	
	[self sendCommandBasic: cmdDictObj];
}
*/

//------------------------------------
//depreciated (11/29/06) remove someday
/*- (NSString*) crateAdapterConnectorKey
{
	return @"UnivVoltHV Crate Adapter Connector";
}
*/
//------------------------------------


#pragma mark •••Notifications
//------------------------------------------------------------------------------------------------
// Sends used to respond to data returns from HV crate.  Called by delegate method netSocket::
// dataAvailable. 
//
// This routine processes the returned data and places it on an output queue.  It sends all the
// appropriate notifications once all commands have been processed.  In the meantime it stores
// all the returned data in a retQueue.  See sendCommand method for more details.  Only HVUnit
// needs to send multiple commands so only returns from the HVUnit are stored in Queue.
//  
//------------------------------------------------------------------------------------------------
- (void) handleDataReturn: (NSData*) aSomeData
{
	NSString*	retSlotChnl;
	NSString*	returnFromSocket;
	NSNumber*   retSlot;
	NSNumber*   retChnl;
	int			returnCode;
	bool		f_NotFound = YES;
	int			retSlotNum;
	int			retChnlNum;
	int			scanLoc;
	int			j;
	int			i;

	@try {		
		// Get oldest command
		NSDictionary* queuedCommand = [mCmdQueue dequeue];
	
		// Check Get data from Queued dictionary entry.
		NSString* queuedCommandStr = [queuedCommand objectForKey: UVkCommand];
		NSNumber* cmdId = [queuedCommand objectForKey: UVkCmdId];
//		NSNumber* queuedSlot = [queuedCommand objectForKey: UVkSlot];
		NSNumber* queuedChnl = [queuedCommand objectForKey: UVkChnl];
	
		// Parse the returned data.
		returnFromSocket = [[self interpretDataFromSocket: aSomeData returnCode: &returnCode] retain];
		NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @" \n"];
		NSArray* tokens = [returnFromSocket componentsSeparatedByCharactersInSet: separators]; 
 
		
		// Make sure we have data returned from HV Crate.
		if ( [tokens count] > 0 )
		{
			NSString* retCommand = [tokens objectAtIndex: 0];
		
			// Get slot and channel
			i = 0;
			if ( [queuedChnl intValue] > 0 )
			{
				while ( f_NotFound && i < [tokens count] )
				{
					retSlotChnl = [tokens objectAtIndex: 1];
					char retChar = [retSlotChnl characterAtIndex: 0];
					if ( retChar == 'S' || retChar == 's' )
					{
						NSScanner* scannerForSlotAndChnl = [NSScanner scannerWithString: retSlotChnl];
						[scannerForSlotAndChnl setScanLocation: 1];
						[scannerForSlotAndChnl scanInt: &retSlotNum];
						retSlot = [NSNumber numberWithInt: retSlotNum];
						scanLoc = [scannerForSlotAndChnl scanLocation];
						[scannerForSlotAndChnl setScanLocation: scanLoc + 1];
						[scannerForSlotAndChnl scanInt: &retChnlNum];
						retChnl = [NSNumber numberWithInt: retChnlNum];
						f_NotFound = NO;
					} // End parsing address.
				i++;
				}	// End looking for address
			}
		
	
//	NSArray* tokens = [self returnedTokens];

			NSLog( @"Returned command '%@', recent command '%@'.", retCommand, queuedCommandStr );
			if ( [retCommand isEqualTo: queuedCommandStr]  )
			{
				// Debug only.
				for ( j = 0;  j < [tokens count]; j++ )
				{
					NSString* object = [tokens objectAtIndex: j];
					NSLog( @"Token ( %d ) string: %@\n", j, object );
				}
	
//			NSLog( @"Queue command %@, return command %@", queuedCommandStr, [tokens objectAtIndex: 0] );
	
//			if ( [channelNum intValue] < 0 ) { // crate command
		
				// crate only returns.
				if ( [retCommand isEqualTo: ORHVkCrateHVStatus] || [retCommand isEqualTo: ORHVkCrateHVOn]
				      || [retCommand isEqualTo:  ORHVkCrateHVOff] || [retCommand isEqualTo: ORHVkCrateHVPanic] )
				{
					NSNumber* slotForCrate = [NSNumber numberWithInt: -1];
					NSNumber* chnlForCrate = [NSNumber numberWithInt: -1];
					[self setupReturnDict: slotForCrate channel: chnlForCrate command: retCommand  returnString: tokens];

					if ( mMostRecentHVStatus != nil ) [mMostRecentHVStatus release];
					mMostRecentHVStatus = [[NSString stringWithString: returnFromSocket] retain];
					[self setupReturnDict: retSlot channel: retChnl command: retCommand  returnString: tokens];
					
					NSLog( @"Send notification about HVStatus change.");
					[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateHVStatusAvailableNotification object: self];
				}
				
				else if ( [retCommand isEqualTo: ORHVkCrateConfig] )
				{
					NSNumber* slotForCrate = [NSNumber numberWithInt: -1];
					NSNumber* chnlForCrate = [NSNumber numberWithInt: -1];
					[self setupReturnDict: slotForCrate channel: chnlForCrate command: retCommand  returnString: tokens];
					if ( mMostRecentConfig != nil ) [mMostRecentConfig release];
					mMostRecentConfig = [[NSString stringWithString: returnFromSocket] retain];
					NSLog( @"Send notification about Config.");
					[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateConfigAvailableNotification object: self];
				}
		
				else if ( [retCommand isEqualTo: ORHVkCrateEnet] )
				{
					NSNumber* slotForCrate = [NSNumber numberWithInt: -1];
					NSNumber* chnlForCrate = [NSNumber numberWithInt: -1];
					[self setupReturnDict: slotForCrate channel: chnlForCrate command: retCommand  returnString: tokens];
					if ( mMostRecentEnetConfig != nil ) [mMostRecentEnetConfig release];
					mMostRecentEnetConfig = [[NSString stringWithString: returnFromSocket] retain];
					NSLog( @"Send notification about Enet Config.");
					[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateEnetAvailableNotification object: self];
				}
				
			
				// Handle return to HV unit.
				else
				{
					[self handleUnitReturn: cmdId slot: retSlot channel: retChnl command: retCommand retTokens: tokens];
				}			// End if looking if returned command equals queued command.
			}
		}
	}
	@catch (NSException * e) {
		NSLog( @"Caught exception '%@'.", [e reason] );
	}
	@finally {	
		if ( returnFromSocket != nil )
		[returnFromSocket release];
	}
	return;
}


- (void) handleUnitReturn: (NSNumber *) aCmdId
				     slot: (NSNumber *) aRetSlot 
                  channel: (NSNumber *) aRetChnl 
				  command: (NSString *) aCommand 
				retTokens: (NSArray *) aTokens
{
	// Create return dictionary.
	if ( mRetQueue == nil )
	{
		mRetQueue = [[ORQueue alloc] init];
		[mRetQueue retain];
	}
	
	// send notification for one queued return.
	if ( mRetsToProcess > 0 )
	{
		NSDictionary* returnDict = [mRetQueue dequeue];
		mRetsToProcess--;
		NSLog( @"dequeue data grom return queue for HV Unit - cmdId: %d, slot: %d, chnl: %d, command '%@'\n", 
				[aCmdId intValue], [aRetSlot intValue], [aRetChnl intValue], aCommand );

		[[NSNotificationCenter defaultCenter] postNotificationName: HVUnitInfoAvailableNotification object: self userInfo: returnDict];
		if ( mRetsToProcess	> 0 ) 
		{
			// Call sendCommand to issue the remainder of the commands.
		   [self sendCommandBasic];
		}
	}
	
	// Queue a return
	else
	{
		NSLog( @"Store  data into return queue for HV Unit - cmdId: %d, slot: %d, chnl: %d\n", 
				[aCmdId intValue], [aRetSlot intValue], [aRetChnl intValue] );
		NSArray *keys = [NSArray arrayWithObjects: UVkCmdId, UVkSlot, UVkChnl, UVkCommand, UVkReturn, nil];
		NSArray *data = [NSArray arrayWithObjects:  aCmdId, aRetSlot, aRetChnl, aCommand, aTokens, nil];
		NSDictionary* retObj = [[NSDictionary alloc] initWithObjects: data forKeys: keys];
		
		[mRetQueue enqueue: retObj];
	}
		// notify HV unit about return from command.
/*		mReturnToUnit = [[NSDictionary alloc] initWithObjects: data forKeys: keys];
						[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateEnetAvailableNotification object: self userInfo: mReturnToUnit];

						NSLog( @"Writing command '%@' for return dictionary.", [mReturnToUnit objectForKey: UVkCommand] );
//					[mReturnToUnit retain];  // ***When Using notification will have to be changed.
					}  // End if looking for returned command.
*/
}

- (void) obtainConfig
{	
	@try
	{
		[self queueCommand: 1 totalCmds: 1 slot: -1 channel: -1 command: ORHVkCrateConfig];
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
		NSString* command = [NSString stringWithFormat: ORHVkCrateEnet];	
		[self sendCrateCommand: command];
			
		// Write the command.
		
		

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
//------------------------------------------------------------------------------------------
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
/*		for ( i = 0; i < lengthOfReturn; i++ ) {
			displayArray[ 0 ] = returnBufferArray[ i ];
			if ( returnBufferArray[ i ] == '\0' ) 
				displayArray[ 0 ] = '-';
			else if ( returnBufferArray[ i ] == '\n' )
				displayArray[ 0 ] = '/';

			NSLog( @"Interpreted.  Char( %d ): %s\n", i, displayArray );
		}
*/		
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
/*
		displayArray[ 1 ] = '\0';
		for ( i = 0; i < nChar; i++ ) {
			displayArray[ 0 ] = returnBufferString[ i ];
			NSLog( @"Char( %d ): %s\n", i, displayArray );
		}
*/			

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
	
	@finally{
	}
	
	[returnCodeAsString release];
	return ( returnStringFromSocket );
}

- (BOOL) isConnected
{
	return mIsConnected;
}


- (void) setIsConnected: (BOOL) aFlag
{
    mIsConnected = aFlag;
//	[self setReceiveCount: 0];
    [[NSNotificationCenter defaultCenter] postNotificationName: HVCrateIsConnectedChangedNotification object: self];
}

- (void) setupReturnDict: (NSNumber*) aSlotNum 
                 channel: (NSNumber*) aChnlNum 
				 command: (NSString*) aCommand 
			returnString: (NSArray*) aRetTokens
{
	NSLog( @"Send notification data return - slot: %d, chnl: %d\n", [aSlotNum intValue], [aChnlNum intValue]);
	NSArray *keys = [NSArray arrayWithObjects: UVkSlot, UVkChnl, UVkCommand, UVkReturn, nil];
	NSArray *data = [NSArray arrayWithObjects:  aSlotNum, aChnlNum, aCommand, aRetTokens, nil];
	if ( mReturnToCrate != nil )
	{
		[mReturnToCrate release];
	}
				
	// notify HV unit about return from command.
	mReturnToCrate = [[NSDictionary alloc] initWithObjects: data forKeys: keys];
}

// Actually takes command off of queue and sends it to the HV Crate.

- (void) sendCommandBasic
{
	NSString* fullCommand = nil;
	NSDictionary* cmdDictObj = 0;
	if ( [mCmdQueue isEmpty] && mCmdsToProcess > 0)
	{
		NSLog( @"Error  - sendCommandBasic has empty cmd queue even though there should still be %d cmds to process.\n" );
	}
	else
	{	
		cmdDictObj = [mCmdQueue dequeue];
	}
	
	if ( cmdDictObj != nil )
	{
		fullCommand = [cmdDictObj objectForKey: UVkCommand];
		const char* buffer = [fullCommand cStringUsingEncoding: NSASCIIStringEncoding];
		
		NSLog( @"SendCommandBasic - Command '%s',  length:%d\n", buffer, [fullCommand length] + 1 );
		if (mSocket != nil )
		{
			[mSocket write: buffer length: [fullCommand length] + 1];	
		}
		else
		{
			NSString* errorMsg = [NSString stringWithFormat: @"Socket not connected to Crate.\n"];
			NSDictionary* errorMsgDict = [NSDictionary dictionaryWithObject: errorMsg forKey: UVkErrorMsg];
			[[NSNotificationCenter defaultCenter] postNotificationName: HVSocketNotConnectedNotification object: self userInfo: errorMsgDict];
		}
	}
}

#pragma mark •••Delegate Methods
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

// Unused code - getting crate return data from HV unit return.  Did work - but simplified.
/*		NSArray* tokens = [mReturnToUnit objectForKey: UVkReturn];
		int i;
		NSString* result = [NSString stringWithString: [tokens objectAtIndex: 0]];
		for (i = 1; i < [tokens count]; i++ )
		{	
			result = [result stringByAppendingFormat: @" %@", [tokens objectAtIndex: i]];
		}
		
		// setup mMostRecentConfig parameter which holds last config.
		if ( mMostRecentConfig != nil )
			[mMostRecentConfig release];
		
			
		mMostRecentConfig = [NSString stringWithString: result];
		[mMostRecentConfig retain];
		return( result );
	}
	else if ( mMostRecentConfig != nil )
		return( mMostRecentConfig );
*/

/* Old version of - (void) handleDataReturn: (NSData) aSomeData
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
				[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateHVStatusAvailableNotification object: self];
				
				}
				else if ( [command isEqualTo: ORHVkCrateConfig] )
				{
					NSLog( @"Send notification about Config.");
					[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateConfigAvailableNotification object: self];
				}
		
				else if ( [command isEqualTo: ORHVkCrateEnet] )
				{
					NSLog( @"Send notification about Enet.");
					[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateConfigAvailableNotification object: self];
				}
				
				else if ( [command isEqualTo: ORHVkHVOn] )
				{
					NSLog( @"Send notification about HV being turned on.");
					[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateHVStatusAvailableNotification object: self];
				}
				
				else if ( [command isEqualTo: ORHVkHVOff] )
				{
					NSLog( @"Send notification about HV being turned off.");
					[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateHVStatusAvailableNotification object: self];
				}

				else if ( [command isEqualTo: ORHVkHVPanic] )
				{
					NSLog( @"Send notification about HV PANIC.");
					[[NSNotificationCenter defaultCenter] postNotificationName: HVCrateHVStatusAvailableNotification object: self];
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
	*/



@end
