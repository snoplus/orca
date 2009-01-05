//
//  ORUnivVoltModel.m
//  Orca
//
//  Created by Jan Wouters on Mon Apr 21 2008
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
//Changes
//MAH 11/18/08 : Changed 'slot' calls to stationNumber calls. This was to be consistent with the rest of ORCA where slots run from 0-n.
//				 If a different mapping is needed for some other reason, the stationNumber method is used. Needed to do this to get rid
//				 all of the xxxCrateView objects by moving functionality into the Crate objects themselves.


#pragma mark •••Imported Files
#import "ORUnivVoltModel.h"
#import "ORUnivVoltHVCrateModel.h"
#import "NetSocket.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORQueue.h"

//NSString* ORUVChnlSlotChanged				= @"ORUVChnlSlotChanged";

#pragma mark •••Constants
// HV Unit parameters by symbol.
NSString* HVkParam = @"Params";
NSString* HVkChannelEnabled = @"CE";
NSString* HVkMeasuredCurrent = @"MC";
NSString* HVkMeasuredHV = @"MV";
NSString* HVkDemandHV = @"DV";
NSString* HVkRampUpRate = @"RUP";
NSString* HVkRampDownRate = @"RDN";
NSString* HVkTripCurrent = @"TC";
NSString* HVkStatus = @"ST";
NSString* HVkMVDZ = @"MVDZ";
NSString* HVkMCDZ = @"MCDZ";
NSString* HVkHVLimit = @"HVL";
NSString* HVkCurChnl = @"HVCurChnl";

NSString* HVkPollTimeMinutes = @"mPollTimeMinutes";
NSString* HVkChannel = @"Channel";

// Order in which data is returned from DMP command.  Index in token array.
const int HVkCommandIndx = 0;
const int HVKSlot_ChnlIndx = 1;
const int HVkMeasuredCurrentIndx = 2;
const int HVkMeasuredHVIndx = 3;
const int HVkDemandHVIndx = 4;
const int HVkRampUpRateIndx = 5;
const int HVkRampDownRateIndx = 6;
const int HVkTripCurrentIndx = 7;
const int HVkChannelEnabledIndx = 8;
const int HVkStatusIndx = 9;
const int HVkMVDZIndx = 10;
const int HVkMCDZIndx = 11;
const int HVkHVLimitIndx = 12;

//const int HVkNumChannels = 12;

const float kMinutesToSecs = 60.0;

// Notifications
NSString* UVChnlChanged					= @"ChnlChanged";
NSString* UVChnlEnabledChanged			= @"ChnlChannelEnabledChanged";
NSString* UVChnlMeasuredCurrentChanged	= @"ChnlMeasuredCurrentChanged";
NSString* UVChnlMeasuredHVChanged		= @"ChnlMeasuredChanged";
NSString* UVChnlDemandHVChanged			= @"ChnlDemandHVChanged";
//NSString* UVChnlSlotChanged				= @"UnitSlotChanged";
NSString* UVChnlRampUpRateChanged		= @"ChnlRampUpRateChanged";
NSString* UVChnlRampDownRateChanged		= @"ChnlRampDownRateChanged";
NSString* UVChnlTripCurrentChanged		= @"ChnlTripCurrentChanged";
NSString* UVChnlStatusChanged			= @"ChnlStatusChanged";
NSString* UVChnlMVDZChanged				= @"ChnlMVDZChanged";
NSString* UVChnlMCDZChanged				= @"ChnlMCDZChanged";
NSString* UVChnlHVLimitChanged			= @"ChnlHVLimitChanged";
NSString* UVCardSlotChanged				= @"UVCardSlotChanged";

NSString* UVPollTimeMinutesChanged		= @"UVPollTimeMinutesChanged";
NSString* UVStatusPollTaskChanged		= @"UVStatusPollTaskChanged";

NSString* UVChnlHVValuesChanged			= @"ChnlHVValuesChanged";
//NSString* UVErrorNotification			= @"UVNotification";

// Commands possible from HV Unit.
NSString* HVkModuleDMP	= @"DMP";
NSString* HVkModuleLD = @"LD";

// Dictionary keys for data return dictionary
//NSString* UVkSlot	 = @"Slot";
//NSString* UVkChnl    = @"Chnl";
//NSString* UVkCommand = @"Command";
//NSString* UVkReturn  = @"Return";

#define HVkNumChannels 12

// Keys
//NSString* UVkCOMMAND = @"Command"; defined in ORUnivVoltHVCrateModel.h
NSString* UVkRW = @"RW";
NSString* UVkTYPE = @"Type";

// Type of parameter
NSString* UVkFLOAT	= @"float";
NSString* UVkINT	= @"int";
NSString* UVkSTRING = @"NSString";

// params dictionary holds NAME, R/W and TYPE
NSString* UVkReadWrite = @"RW";
NSString* UVkType = @"TYPE";

NSString* UVkRead = @"R";
NSString* UVkWrite = @"W";

//NSString* UVkInt = @"int";
//NSString* UVkFloat = @"float";
//NSString* UVkString = @"string";


@implementation ORUnivVoltModel
#pragma mark •••Init/Dealloc
/*- (NSString*) fullID
{
    return [NSString stringWithFormat:@"%@,%d,%d",NSStringFromClass([self class]),[self crateNumber], [self stationNumber]];
}
*/
- (Class) guardianClass 
{
	return NSClassFromString(@"ORUnivVoltHVCrateModel");
}

- (void) makeMainController
{
    [self linkToController: @"ORUnivVoltController"];
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector( pollTask ) object: nil];		
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{

	NSLog( @"awakeAfterDocumentLoaded - ORUnivVoltModel.m\n" );
		@try {
			mParams = [NSMutableDictionary dictionaryWithCapacity: UVkChnlNumParameters];

			// ---- Load dictionary with commands supported for this unit ----
			NSArray* keysCmd = [NSArray arrayWithObjects: UVkCommand, @"SLOT", @"CHNL", nil];
		
			NSArray* objectsCmd0 = [NSArray arrayWithObjects: @"DMP", @"YES", @"YES", nil];
			NSDictionary* tmpCmd0 = [NSDictionary dictionaryWithObjects: objectsCmd0 forKeys: keysCmd];
			[mCommands insertObject: tmpCmd0 atIndex: 0];
		
			NSArray* objectsCmd1 = [NSArray arrayWithObjects: @"LD", @"YES", @"YES", nil];
			NSDictionary* tmpCmd1 = [NSDictionary dictionaryWithObjects: objectsCmd1 forKeys: keysCmd];
			[mCommands insertObject: tmpCmd1 atIndex: 1];
		

			// --- load array with dictionary values for parameters - Store name, R/W, and type.
			NSArray* keys = [NSArray arrayWithObjects: HVkParam, UVkReadWrite, UVkType, nil];
				
		
			mWParams = 0;
			NSArray* objects0 = [NSArray arrayWithObjects: @"Chnl", UVkRead, @"int", nil];
			NSDictionary* tmpParam0 = [NSDictionary dictionaryWithObjects: objects0 forKeys: keys];
			[mParams setObject: tmpParam0 forKey: @"Chnl"];

			NSArray* objects1 = [NSArray arrayWithObjects: HVkMeasuredCurrent, UVkRead, UVkFLOAT, nil];
			NSDictionary* tmpParam1 = [NSDictionary dictionaryWithObjects: objects1 forKeys: keys];
			[mParams setObject: tmpParam1 forKey: HVkMeasuredCurrent];

			NSArray* objects2 = [NSArray arrayWithObjects: HVkMeasuredHV, UVkRead, UVkFLOAT, nil];
			NSDictionary* tmpParam2 = [NSDictionary dictionaryWithObjects: objects2 forKeys: keys];
			[mParams setObject: tmpParam2 forKey: HVkMeasuredHV];

			mWParams++;
			NSArray* objects5 = [NSArray arrayWithObjects:HVkDemandHV, UVkWrite, UVkFLOAT, nil];
			NSDictionary* tmpParam5 = [NSDictionary dictionaryWithObjects: objects5 forKeys: keys];
			[mParams setObject: tmpParam5 forKey: HVkDemandHV];

			mWParams++;
			NSArray* objects6 = [NSArray arrayWithObjects: HVkRampUpRate, UVkWrite, UVkFLOAT, nil];
			NSDictionary* tmpParam6 = [NSDictionary dictionaryWithObjects: objects6 forKeys: keys];
			[mParams setObject: tmpParam6 forKey: HVkRampUpRate];

			mWParams++;
			NSArray* objects7 = [NSArray arrayWithObjects: HVkRampDownRate, UVkWrite, UVkFLOAT, nil];
			NSDictionary* tmpParam7 = [NSDictionary dictionaryWithObjects: objects7 forKeys: keys];
			[mParams setObject: tmpParam7 forKey: HVkRampDownRate];

			mWParams++;
			NSArray* objects8 = [NSArray arrayWithObjects: HVkTripCurrent, UVkWrite, UVkFLOAT, nil];
			NSDictionary* tmpParam8 = [NSDictionary dictionaryWithObjects: objects8 forKeys: keys];
			[mParams setObject: tmpParam8 forKey: HVkTripCurrent];
		
			mWParams++;
			NSArray* objects4 = [NSArray arrayWithObjects: HVkChannelEnabled, UVkWrite, UVkINT, nil];
			NSDictionary* tmpParam4 = [NSDictionary dictionaryWithObjects: objects4 forKeys: keys];
			[mParams setObject: tmpParam4 forKey: HVkChannelEnabled];

			NSArray* objects3 = [NSArray arrayWithObjects: HVkStatus, UVkRead, UVkINT, nil];
			NSDictionary* tmpParam3 = [NSDictionary dictionaryWithObjects: objects3 forKeys: keys];
			[mParams setObject: tmpParam3 forKey: HVkStatus];

			NSArray* objects10 = [NSArray arrayWithObjects: HVkMVDZ, UVkWrite, UVkFLOAT, nil];
			NSDictionary* tmpParam10 = [NSDictionary dictionaryWithObjects: objects10 forKeys: keys];
			[mParams setObject: tmpParam10 forKey: HVkMVDZ];
		
			mWParams++;
			NSArray* objects11 = [NSArray arrayWithObjects: HVkMCDZ, UVkWrite, UVkFLOAT, nil];
			NSDictionary* tmpParam11 = [NSDictionary dictionaryWithObjects: objects11 forKeys: keys];
			[mParams setObject: tmpParam11 forKey: HVkMCDZ];
		
			NSArray* objects12 = [NSArray arrayWithObjects: HVkHVLimit, UVkRead, UVkINT, nil];
			NSDictionary* tmpParam12 = [NSDictionary dictionaryWithObjects: objects12 forKeys: keys];
			[mParams setObject: tmpParam12 forKey: HVkHVLimit];


			[mParams retain];
		
			//Debug code - Print out parameters and their attributes.
/*	
			NSDictionary* dictObjDeb = [mParams objectForKey: [mParams objectForKey: HVkTripCurrent]];				// Get static dictionary for this chnl describing the parameters.
			NSLog( @"command: %@,  type: %@,  R/W: %@\n", [[dictObjDeb objectForKey: UVkCommand] stringValue], 
	                                            [[dictObjDeb objectForKey: UVkType] stringValue],
    											[[dictObjDeb objectForKey: UVkRW] stringValue] );

			NSArray*	allKeys = [mParams allKeys];
			int j;
			for ( j = 0; j < [mParams count]; j++ )
			{
				NSDictionary* dictObj = [mParams objectForKey: [allKeys objectAtIndex: j]];				// Get static dictionary for this chnl describing the parameters.
				NSString*	commandDict = [dictObj objectForKey: HVkParam];		
				NSString*	writableDict = [dictObj objectForKey: UVkRW];
				NSString*   typeDict = [dictObj objectForKey: UVkType ];
		
				NSLog( @" Param '%@', R/W :%@, Type: %@\n", commandDict, writableDict, typeDict );
			}
*/			
			// Set polltask to false
			mPollTaskIsRunning = FALSE;
		/* */
	}	
	@catch (NSException *exception) {
		NSLog(@"awakeFromNib: Caught %@: %@", [exception name], [exception  reason]);
	}
	@finally
	{
	}
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"UnivVoltHVIcon"]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers{
//    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    [notifyCenter addObserver : self
                     selector : @selector( interpretDataReturn: )
                         name : HVUnitInfoAvailableNotification
                       object : nil];
					   
}


//------------------------------------------------------------------------------------------
#pragma mark •••sendCommands
//------------------------------------------------------------------------------------------
- (void) getValues: (int) aCurrentChnl
{
	int		i;	
	int		slot;
	
	slot = [self stationNumber];
    if ( aCurrentChnl > -1 )
	{
		NSString* command = [NSString stringWithFormat: @"DMP S%d.%d", slot, aCurrentChnl];
		[[self crate] queueCommand: 0 totalCmds: 1 slot: [self stationNumber] channel: aCurrentChnl command: command];
	}
	else 
	{
		for ( i = 0; i < UVkNumChannels; i++ )
		{
			NSString* command = [NSString stringWithFormat: @"DMP S%d.%d", slot, i];
			[[self crate] queueCommand: i totalCmds: UVkNumChannels slot: [self stationNumber] channel: i command: command];
		}
	}
}

//------------------------------------------------------------------------------------------
- (void) loadValues: (int) aCurrentChnl
{
//	int			i;
	int			jParam;
	int			writeCmdCtr = 0;
//	int			totalCmdsToExecute;
//	int			nParams;
//	float		value;	
	//Debug code - 
/*	NSDictionary* dictObjDeb = [mParams objectForKey: [mParams objectForKey: HVkTripCurrent]];				// Get static dictionary for this chnl describing the parameters.
	NSLog( @"command: %@,  type: %@,  R/W: %@", [[dictObjDeb objectForKey: UVkCommand] stringValue], 
	                                            [[dictObjDeb objectForKey: UVkType] stringValue],
												[[dictObjDeb objectForKey: UVkRW] stringValue] );
*/
	// Loop through all parameters to load the values into the hardware.
	NSArray*	allKeys = [mParams allKeys];
	
	// loop through parameters since we load all twelve channels at once on a normal basis.
//	for ( jParam = 0; jParam < [allKeys count]; jParam++ )

//	totalCmdsToExecute = mWParams * HVkNumChannels;
	for ( jParam = 0; jParam < [allKeys count]; jParam++ )
	{
		int				iChnl;
		NSString*		command = [NSString stringWithFormat: @""];
		NSDictionary*	dictParamObj = [mParams objectForKey: [allKeys objectAtIndex: jParam]];				// Get static dictionary for this chnl describing the parameters.
//		NSString*		commandDict = [dictParamObj objectForKey: UVkCommand];								// Get command from dictionary
		NSString*		writableDict = [dictParamObj objectForKey: UVkRW];									// Get whether command is read only or writable.
		
/*		
		NSString*   typeDict = [dictObj objectForKey: UVkType ];  // Debug only
		NSLog( @" Command '%@', R/W :%@, Type: %@", commandDict, writableDict, typeDict );
*/
		
		if ( [writableDict isEqualTo: UVkWrite] )		
		{
			
			if ( aCurrentChnl > -1 )
			{
				command = [self createCommand: aCurrentChnl          
								 dictParamObj: dictParamObj
								      command: command];
				[command retain];
//				[[ self crate] queueCommand: jParam totalCmds: 1 slot: [self slot] channel: aCurrentChnl command: command];
				[[ self crate] queueCommand: writeCmdCtr totalCmds: mWParams slot: [self stationNumber] channel: aCurrentChnl command: command];
				writeCmdCtr++;
			}
			
			else
			{
				// Loop through all channels to load all values for specified parameter for all channels with one command.
				for ( iChnl = 0; iChnl < HVkNumChannels; iChnl++ )
				{					
					command = [self createCommand: iChnl
									 dictParamObj: dictParamObj
									      command: command];
				
				    [command retain];
				} // Loop through channels
				
				// Single command has been assembled for one param - now queue it.
				[[ self crate] queueCommand: writeCmdCtr totalCmds: mWParams slot: [self slot] channel: iChnl command: command];
				writeCmdCtr++;
				[command release];

			}     // Determine if one should process one or all channels
		}			  // Determine if parameter is writeable.
	}				  // Loop through all parameters.
}

//------------------------------------------------------------------------------------------
- (NSString *) createCommand: (int) aCurChnl
                dictParamObj: (NSDictionary *) aDictParamObj
				     command: (NSString *) aCommand
{
	
	// Get value to set parameter to.
	NSMutableDictionary* chnlDict = [mChannelArray objectAtIndex: aCurChnl]; // Get values we want to set for channel.
	NSString* param = [aDictParamObj objectForKey: HVkParam];
	NSNumber* valueObj = [chnlDict objectForKey: param];
	
	// Get static dictionary for chnl describing the parameter.
	

	if ( [aCommand length] == 0 )
	{
		// LD command handles all channels at once so unit identifier is Sx followed by parameter followed
		// by values for all 12 channels.
		if ( aCurChnl == -1 )
			aCommand = [NSString stringWithFormat: @"LD S%d %@", [self stationNumber], param];
		else
			aCommand = [NSString stringWithFormat: @"LD S%d.%d %@", [self stationNumber], aCurChnl, param];
	}
			
	if ( [[aDictParamObj objectForKey: UVkType] isEqualTo: UVkINT] )
		aCommand = [aCommand stringByAppendingFormat: @" %d", [valueObj intValue]];
	else if ([[aDictParamObj objectForKey: UVkType] isEqualTo: UVkFLOAT])
		aCommand = [aCommand stringByAppendingFormat: @" %g", [valueObj floatValue]];
	else if ([[aDictParamObj objectForKey: UVkType] isEqualTo: UVkSTRING])
		aCommand = [aCommand stringByAppendingFormat: @" %@", [valueObj stringValue]];
		
	return( aCommand );
}

#pragma mark •••Polling
- (float) pollTimeMinutes
{
	return( [mPollTimeMinutes floatValue] );
}

- (void) setPollTimeMinutes: (float) aPollTimeMinutes
{
//    [[[self undoManager] prepareWithInvocationTarget: self] setPollTimeMinutes: aPollTimeMinutes];
	[mPollTimeMinutes release];
    mPollTimeMinutes = [NSNumber numberWithFloat: aPollTimeMinutes];
	[mPollTimeMinutes retain];
//	NSLog( @"UnivVoltModel - Set polling time to %f\n", [mPollTimeMinutes floatValue]);
    [[NSNotificationCenter defaultCenter] postNotificationName: UVPollTimeMinutesChanged object: self];
}


- (void) startPolling
{    
	mPollTaskIsRunning = FALSE;
	
	float pollTimeSecs = kMinutesToSecs * [mPollTimeMinutes floatValue];
	
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector( pollTask ) object: nil];
	
	if ( [mPollTimeMinutes floatValue] > 0 ) {
		[self performSelector: @selector( pollTask ) withObject: nil afterDelay: pollTimeSecs];
		mPollTaskIsRunning = TRUE;
		NSLog( @"Started poll task with interval: %f\n", pollTimeSecs);
		[[NSNotificationCenter defaultCenter] postNotificationName: UVStatusPollTaskChanged object: self];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector( pollTask ) object: nil];
	}
}

- (void) stopPolling
{	
	NSLog( @"Stopped poll task with interval: %f\n", [mPollTimeMinutes floatValue]);
	mPollTaskIsRunning = FALSE;
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector( pollTask ) object: nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: UVStatusPollTaskChanged object: self];
}

- (void) pollTask;
{
	float pollTimeSecs = kMinutesToSecs * [mPollTimeMinutes floatValue];
	NSDate *now = [NSDate date];	

	NSString* lastPollTime = [now descriptionWithCalendarFormat: @"%H:%M:%S"
	                                                   timeZone: nil   
													     locale: [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
	NSString* lastPollTimeMsg = [NSString stringWithFormat: @"Last Poll :%@", lastPollTime];
	
	NSLog( @"%@\n", lastPollTimeMsg );

	// Send notification of latest poll time.
	NSDictionary* retMsg = [NSDictionary dictionaryWithObject: lastPollTimeMsg forKey: HVkErrorMsg]; 
	[[NSNotificationCenter defaultCenter] postNotificationName: HVShortErrorNotification object: self userInfo: retMsg];
	
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector( pollTask ) object: nil];
//	[self getValues: -1];
	[self performSelector: @selector( pollTask) withObject: nil afterDelay: pollTimeSecs];
//	mPollTaskIsRunning = TRUE;	
}

- (bool) isPollingTaskRunning
{
	return mPollTaskIsRunning;
}

#pragma mark •••Accessors
- (NSMutableArray*) channelArray
{
	return( mChannelArray );
}

- (void) setChannelArray: (NSMutableArray*) anArray
{
	[anArray retain];
	[mChannelArray release];
	mChannelArray = anArray;
}

- (NSMutableDictionary*) channelDictionary: (int) aCurrentChnl
{
	return( [mChannelArray objectAtIndex: aCurrentChnl] );
}

- (int) chnlEnabled: (int) aCurrentChnl
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurrentChnl];
	NSNumber* numObj = [tmpChnl objectForKey: [tmpChnl objectForKey: HVkChannelEnabled]];
	return( [numObj intValue] );
}

- (void) setChannelEnabled: (int) anEnabled chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	
	NSNumber* enabledNumber = [NSNumber numberWithInt: anEnabled];
	[tmpChnl setObject: enabledNumber forKey: HVkChannelEnabled];
//	NSLog( @"Channel %d has enabled flag set to %d \n", aCurChannel, [enabledNumber intValue]);
	
	NSDictionary* chnlRet = [self createChnlRetDict: aCurChannel];
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlEnabledChanged object: self userInfo: chnlRet];		
}

- (float) demandHV: (int) aCurChannel
{
	NSDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	
	return ( [[tmpChnl objectForKey: HVkDemandHV] floatValue] );
}

- (void) setDemandHV: (float) aDemandHV chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* demandHV = [NSNumber numberWithFloat: aDemandHV];
	[tmpChnl setObject: demandHV forKey: HVkDemandHV];
	
	// Put specific code here to talk with unit.
	NSDictionary* retDict = [self createChnlRetDict: aCurChannel];
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlDemandHVChanged object: self userInfo: retDict];	
}

- (float) measuredCurrent: (int) aChnl
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: HVkMeasuredCurrent] floatValue] );
}

- (float) measuredHV: (int) aChnl
{
	// Send command to get HV
//	[adapter sendCommand: @"RC"];
	
	// Now update dictionary
	
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: HVkDemandHV] floatValue] );
}

- (float) tripCurrent: (int) aChnl
{
	// Now update dictionary
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: HVkTripCurrent] floatValue] );
}

- (void) setTripCurrent: (float) aTripCurrent chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* tripCurrent = [NSNumber numberWithFloat: aTripCurrent];
	[tmpChnl setObject: tripCurrent forKey: HVkTripCurrent];
	
	// Create return dictionary with channel.  Then send notification that value has changed.
	NSDictionary* chnlRet = [self createChnlRetDict: aCurChannel];
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlTripCurrentChanged object: self userInfo: chnlRet];	
}

- (float) rampUpRate: (int) aChnl
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: HVkRampUpRate] floatValue] );
}

- (void) setRampUpRate: (float) aRampUpRate chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* rampUpRate = [NSNumber numberWithFloat: aRampUpRate];
	[tmpChnl setObject: rampUpRate forKey: HVkRampUpRate];
	
	// Create return dictionary with channel.  Then send notification that value has changed.
	NSDictionary* chnlRet = [self createChnlRetDict: aCurChannel];
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlRampUpRateChanged object: self userInfo: chnlRet];	
}


- (float) rampDownRate: (int) aChnl
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: HVkRampDownRate] floatValue] );
}

- (void) setRampDownRate: (float) aRampDownRate chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* rampDownRate = [NSNumber numberWithFloat: aRampDownRate];
	[tmpChnl setObject: rampDownRate forKey: HVkRampDownRate];
	
	// Create return dictionary with channel.  Then send notification that value has changed.
	NSDictionary* chnlRet = [self createChnlRetDict: aCurChannel];
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlRampDownRateChanged object: self userInfo: chnlRet];	
}

- (NSString*) status: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSString* status = [tmpChnl objectForKey: HVkStatus];
	[status autorelease];
	return( status );
}

- (float) MVDZ: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	return( [[tmpChnl objectForKey: HVkMVDZ] floatValue] );
}

- (void) setMVDZ: (float) aChargeWindow chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* hvWindow = [NSNumber numberWithFloat: aChargeWindow];
	[tmpChnl setObject: hvWindow forKey: HVkMVDZ];
	
	// Create return dictionary with channel.  Then send notification that value has changed.
	NSDictionary* chnlRet = [self createChnlRetDict: aCurChannel];
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlMVDZChanged object: self userInfo: chnlRet];	
}

- (float) MCDZ: (int) aChnl
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aChnl];
	return( [[tmpChnl objectForKey: HVkMCDZ] floatValue] );
}

- (void) setMCDZ: (float) aChargeWindow chnl: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	NSNumber* chargeWindow = [NSNumber numberWithFloat: aChargeWindow];
	[tmpChnl setObject: chargeWindow forKey: HVkMCDZ];
	
	// Create return dictionary with channel.  Then send notification that value has changed.
	NSDictionary* chnlRet = [self createChnlRetDict: aCurChannel];
	[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlMCDZChanged object: self userInfo: chnlRet];	
}

- (float) HVLimit: (int) aCurChannel
{
	NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: aCurChannel];
	return( [[tmpChnl objectForKey: HVkHVLimit] floatValue] );
}

#pragma mark •••Interpret Data
- (void) interpretDataReturn: (NSNotification*) aNote
{
	@try {
		int slotThisUnit;
	
		// Data is in notification - Get data
		NSDictionary* returnData = [aNote userInfo];
		
		// Get data for this channel from crate - in ORCA place data in NOTIFICATION Object.
//		NSDictionary* returnData = [[self crate] returnDataToHVUnit];
//		NSLog ( @" '%@'\n", [returnData objectForKey: UVkCommand]);
		[returnData retain];
			
		NSNumber* slotNum = [returnData objectForKey: UVkSlot];
		slotThisUnit = [self stationNumber];
		if ( [slotNum intValue] == slotThisUnit )
		{
			NSString* retCmd = [returnData objectForKey: UVkCommand];
			if ( [retCmd isEqualTo: HVkModuleDMP] )
			{
				NSNumber* curChnlNum = [returnData objectForKey: UVkChnl];
				int curChnl = [curChnlNum intValue];
				
				[self interpretDMPReturn: returnData channel: curChnl];

//				NSMutableDictionary* chnl = [mChannelArray objectAtIndex: curChnl];

	
				NSDictionary* chnlDictObj = [NSDictionary dictionaryWithObject: curChnlNum forKey: HVkCurChnl];
				[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlHVValuesChanged 
				                                                    object: self
																  userInfo: chnlDictObj];
			}
			else if( [retCmd isEqualTo: HVkModuleLD] ) 
			{
				// Interpret return from LD command.  Notifications are done from within interpretLDReturn routine
				// since have to update many channels.
				[self interpretLDReturn: returnData];
			}
		}				
	}
	@catch (NSException * e) {
		NSLog( @"Caught exception '%@'.", [e reason] );
	}
	@finally {
		
	}
}

- (void) interpretDMPReturn: (NSDictionary*) aReturnData channel: (int) aCurChnl
{
// Order of return from DMP command
	NSString*			statusStr;
	int					status;
	
	// Get chnl object from mChannelArray.  This object will be changed with new values from return.
	NSMutableDictionary* chnlDictObj = [mChannelArray objectAtIndex: aCurChnl];
     
	
	NSArray* tokens = [aReturnData objectForKey: UVkReturn];
		
	// Place new values into mChannelArray for channel aCurChnl
	NSNumber* measuredCurrent = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkMeasuredCurrentIndx] floatValue]];
	[chnlDictObj setObject: measuredCurrent forKey: HVkMeasuredCurrent];
//	[notifyCenter postNotificationName: UVChnlMeasuredCurrentChanged object: self userInfo: chnlDictObj];
	
	NSNumber* measuredHV = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkMeasuredHVIndx] floatValue]];
	[chnlDictObj setObject: measuredHV forKey: HVkMeasuredHV];
//	[notifyCenter postNotificationName: UVChnlMeasuredHVChanged object: self userInfo: chnlDictObj];
	
	NSNumber* demandHV = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkDemandHVIndx] floatValue]];
	[chnlDictObj setObject: demandHV forKey: HVkDemandHV];
//	[notifyCenter postNotificationName: UVChnlDemandHVChanged object: self userInfo: chnlDictObj];
	
	NSNumber* rampUpRate = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkRampUpRateIndx] floatValue]];
	[chnlDictObj setObject: rampUpRate forKey: HVkRampUpRate];
//	[notifyCenter postNotificationName: UVChnlRampUpRateChanged object: self userInfo: chnlDictObj];
	
	NSNumber* rampDownRate = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkRampDownRateIndx] floatValue]];
	[chnlDictObj setObject: rampDownRate forKey: HVkRampDownRate];
//	[notifyCenter postNotificationName: UVChnlRampDownRateChanged object: self userInfo: chnlDictObj];

	NSNumber* tripCurrent = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkTripCurrentIndx] floatValue]];
	[chnlDictObj setObject: tripCurrent forKey: HVkTripCurrent];
//	[notifyCenter postNotificationName: UVChnlTripCurrentChanged object: self userInfo: chnlDictObj];
	
	NSNumber* channelEnabled = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkChannelEnabledIndx] intValue]];
	[chnlDictObj setObject: channelEnabled forKey: HVkChannelEnabled];
//	[notifyCenter postNotificationName: UVChnlMeasuredCurrentChanged object: self userInfo: chnlDictObj];

	NSNumber* statusNum = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkStatusIndx] intValue]];
	status = [statusNum intValue];
//	[notifyCenter postNotificationName: UVChnlEnabledChanged object: self userInfo: chnlDictObj];
	
	// Interpret status
	
	NSLog( @"interpretDMPReturn - Status: %d\n", status );
	// status case statement
	switch ( status ) {
		case eHVUEnabled:
			statusStr = [NSString stringWithString: @"Enabled"];
			break;
			
		case eHVURampingUp:
			statusStr = [NSString stringWithString: @"Ramping up"];
			break;
			
		case eHVURampingDown:
			statusStr = [NSString stringWithString: @"Ramping down"];
			break;
			
		case evHVUTripForSupplyLimits:
			statusStr = [NSString stringWithString: @"Trip for viol. supply lmt"];
			break;
			
		case eHVUTripForUserCurrent:
			statusStr = [NSString stringWithString: @"Trip for viol. current lmt"];
			break;
			
		case eHVUTripForHVError:
			statusStr = [NSString stringWithString: @"Trip HV for volt. error"];
			break;
			
		case eHVUTripForHVLimit:
			statusStr = [NSString stringWithString: @"Trip for voil. of volt. lmt"];
			
		default:
			statusStr = [NSString stringWithString: @"Undefined"];
			break;
	}
	[chnlDictObj setObject: statusStr forKey: HVkStatus];
//	[notifyCenter postNotificationName: UVChnlStatusChanged object: self userInfo: chnlDictObj];

	NSNumber* MVDZ = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkMVDZIndx] floatValue]];
	[chnlDictObj setObject: MVDZ forKey: HVkMVDZ];
//	[notifyCenter postNotificationName: UVChnlMVDZChanged object: self userInfo: chnlDictObj];
	
	NSNumber* MCDZ = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkMCDZIndx] floatValue]];
	[chnlDictObj setObject: MCDZ forKey: HVkMCDZ];
//	[notifyCenter postNotificationName: UVChnlMCDZChanged object: self userInfo: chnlDictObj];
	
	NSNumber* hvLimit = [NSNumber numberWithFloat: [[tokens objectAtIndex: HVkHVLimitIndx] floatValue]];
	[chnlDictObj setObject: hvLimit forKey: HVkHVLimit];
//	[notifyCenter postNotificationName: UVChnlHVLimitChanged object: self userInfo: chnlDictObj];
}

- (void) interpretLDReturn: (NSDictionary*) aReturnData
{
	int			i;
	int			j;
//	NSString*			statusStr;
//	int					status;
	NSNumber*			valueObj;
	
//	NSMutableDictionary* chnl = [mChannelArray objectAtIndex: 10];
	NSArray* tokens = [aReturnData objectForKey: UVkReturn];
	for ( i = 3; i < 10; i++ ) {
		NSString* oneParameter = [tokens objectAtIndex: i];
		NSLog( @"Token %d, String: %@\n", i, oneParameter );
	}

	// discover load command executed
	NSString* command = [tokens objectAtIndex: 2];
	
	NSArray*	allKeys = [mParams allKeys];
	for ( i = 0; i < [allKeys count]; i++ )
	 {
		NSString* oneParamName = [allKeys objectAtIndex: i];
		if ( [command localizedCaseInsensitiveCompare: oneParamName] == NSOrderedSame ) 
		{
			// Now process data for all returned values
			NSLog( @"Found command %@ in dictionary %@\n", command, oneParamName );
			for ( j = 0; j < HVkNumChannels; j++ )
			{
				NSNumber* curChnlNum = [NSNumber  numberWithInt: j];
				NSDictionary* chnlDictObj = [NSDictionary dictionaryWithObject: curChnlNum forKey: HVkCurChnl];
				int tokenIndex = 2 + j;
				if ( [tokens count] > tokenIndex )
				{
					NSMutableDictionary* tmpChnl = [mChannelArray objectAtIndex: j];
					NSString* parameter = [tokens objectAtIndex: j];
					NSLog( @"Token %d, String: %@\n", i, parameter );

//					NSNumber* valueLoaded = [NSNumber numberWithFloat: aRampUpRate];
//					[tmpChnl setObject: rampUpRate forKey: command];
					
					NSString* type = [mParams objectForKey: oneParamName];
					NSString* valueStr = [tokens objectAtIndex: tokenIndex];
					
					if ( type == UVkFLOAT )
					{
						float value = [valueStr floatValue];
						valueObj = [NSNumber numberWithFloat: value];
					}
					else if ( type = UVkINT )
					{
						int value = [valueStr intValue];
						valueObj = [NSNumber numberWithInt: value];
					}
					[tmpChnl setObject: valueObj forKey: oneParamName];
	
					if ( [oneParamName isEqualTo: HVkChannelEnabled] ) {
//						[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlEnabledChanged object: self];
//						NSDictionary* chnlDictObj = [NSDictionary dictionaryWithObject: curChnlNum forKey: HVkCurChnl];
						[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlEnabledChanged 
				                                                    object: self
																  userInfo: chnlDictObj];
					}
					
					else if ( [oneParamName isEqualTo: HVkDemandHV] ) {
						[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlDemandHVChanged 
						                                                    object: self 
																		  userInfo: chnlDictObj];	
					}
					
					else if ( [oneParamName isEqualTo: HVkRampUpRate] ) {
						[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlRampUpRateChanged 
																			object: self
																		  userInfo: chnlDictObj];
							
					}
					
					else if ( [oneParamName isEqualTo: HVkRampDownRate] ) {
						[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlRampDownRateChanged 
																			object: self	
																		  userInfo: chnlDictObj];
					}
					
					else if ( [oneParamName isEqualTo: HVkTripCurrent] ){
						[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlTripCurrentChanged 
						                                                    object: self	
																		  userInfo: chnlDictObj];
					}

					else if ( [oneParamName isEqualTo: HVkMVDZ] ){
						[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlMVDZChanged 
						                                                    object: self	
																		  userInfo: chnlDictObj];
					}

					else if ( [oneParamName isEqualTo: HVkMCDZ] ){
						[[NSNotificationCenter defaultCenter] postNotificationName: UVChnlMCDZChanged 
						                                                    object: self	
																		  userInfo: chnlDictObj];
					}	// End of if statements to figure out which notification message to send
				}		// End of if determining whether token exists for channel.
			}			// end of loop through all channels.
			return;
		}				// End of if determining if we have found correct command.
	}					// End of loop through all keys to determine which key to use.
}

/*
#pragma mark •••Data Records
- (unsigned long) dataId
{
	return dataId;
}

- (void) setDataId: (unsigned long) aDataId
{
	dataId = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"NplpCMeter"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORUnivVoltDecoder",					@"decoder",
        [NSNumber numberWithLong:dataId],       @"dataId",
        [NSNumber numberWithBool:YES],          @"variable",
        [NSNumber numberWithLong:-1],			@"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"NplpCMeter"];
    
    return dataDictionary;
}

- (void) shipValues
{
	if(meterData){
	
		unsigned int numBytes = [meterData length];
		if(numBytes%4 == 0) {											//OK, we know we got a integer number of long words
			if([self validateMeterData]){
				unsigned long data[1003];									//max buffer size is 1000 data words + ORCA header
				unsigned int numLongsToShip = numBytes/sizeof(long);		//convert size to longs
				numLongsToShip = numLongsToShip<1000?numLongsToShip:1000;	//don't exceed the data array
				data[0] = dataId | (3 + numLongsToShip);					//first word is ORCA id and size
				data[1] =  [self uniqueIdNumber]&0xf;						//second word is device number
				
				//get the time(UT!)
				time_t	theTime;
				time(&theTime);
				struct tm* theTimeGMTAsStruct = gmtime(&theTime);
				time_t ut_time = mktime(theTimeGMTAsStruct);
				data[2] = ut_time;											//third word is seconds since 1970 (UT)
				
				unsigned long* p = (unsigned long*)[meterData bytes];
				
				int i;
				for(i=0;i<numLongsToShip;i++){
					p[i] = CFSwapInt32BigToHost(p[i]);
					data[3+i] = p[i];
					int chan = (p[i] & 0x00600000) >> 21;
					if(chan < kNplpCNumChannels) [dataStack[chan] enqueue: [NSNumber numberWithLong:p[i] & 0x000fffff]];
				}
				
				[self averageMeterData];
				
				if(numLongsToShip*sizeof(long) == numBytes){
					//OK, shipped it all
					[meterData release];
					meterData = nil;
				}
				else {
					//only part of the record was shipped, zero the part that was and keep the part that wasn't
					[meterData replaceBytesInRange:NSMakeRange(0,numLongsToShip*sizeof(long)) withBytes:nil length:0];
				}
				
				if([gOrcaGlobals runInProgress] && numBytes>0){
					[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:(3+numLongsToShip)*sizeof(long)]];
				}
				[self setReceiveCount: receiveCount + numLongsToShip];
			}
			
			else {
				[meterData release];
				meterData = nil;
				[self setFrameError:frameError+1];
			}
		}
	}
}

*/
#pragma mark ***Archival
- (id) initWithCoder: (NSCoder*) decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	[self setChannelArray: [decoder decodeObjectForKey: @"mChannelArray"]];
	mPollTimeMinutes = [decoder decodeObjectForKey: HVkPollTimeMinutes];
/*	if( !mChannelArray ){
		//first time.... set up the structure....
		[self setChannelArray: [NSMutableArray array]];
		int i;
		
		mPollTimeMinutes = [NSNumber numberWithFloat: 1.0];
		// Put in dummy values for testing.
		for(i = 0 ; i < UVkNumChannels; i++ )
		{

			NSNumber* chnl = [NSNumber numberWithInt: i];
			NSNumber* measuredCurrent = [NSNumber numberWithFloat: ((float)i * 1.0)];
			NSNumber* measuredHV = [NSNumber numberWithFloat: (1000.0 + 10.0 * (float)i)];
			NSNumber* demandHV = [NSNumber numberWithFloat: (2000.0 + (float) i)];
			NSNumber* rampUpRate = [NSNumber numberWithFloat: 61.3];
			NSNumber* rampDownRate = [NSNumber numberWithFloat: 61.3];
			NSNumber* tripCurrent = [NSNumber numberWithFloat: 2550.0];
			NSString* status = [NSString stringWithString: @"enabled"];
			NSNumber* enabled = [NSNumber numberWithInt: 1];
			NSNumber* MVDZ = [NSNumber numberWithFloat: 1.5];
			NSNumber* MCDZ = [NSNumber numberWithFloat: 1.3];
			NSNumber* HVLimit = [NSNumber numberWithFloat: 1580.0];
			
			NSMutableDictionary* tmpChnl = [NSMutableDictionary dictionaryWithCapacity: 9];
			
			[tmpChnl setObject: chnl forKey: @"channel"];
			[tmpChnl setObject: measuredCurrent forKey: HVkMeasuredCurrent];
			[tmpChnl setObject: measuredHV forKey:HVkMeasuredHV];
			[tmpChnl setObject: demandHV forKey: HVkDemandHV];
			[tmpChnl setObject: tripCurrent	forKey: HVkTripCurrent];
			[tmpChnl setObject: enabled forKey:HVkChannelEnabled];
			[tmpChnl setObject: rampUpRate forKey: HVkRampUpRate];			
			[tmpChnl setObject: rampDownRate forKey: HVkRampDownRate];
			[tmpChnl setObject: status forKey: HVkStatus];
			[tmpChnl setObject: MVDZ forKey: HVkMVDZ];			
			[tmpChnl setObject: MCDZ forKey: HVkMCDZ];
			[tmpChnl setObject: HVLimit forKey: HVkHVLimit];			

			[tmpChnl setObject: status forKey: HVkStatus];
			
			[mChannelArray insertObject: tmpChnl atIndex: i];
		}
		
	}
	*/
	[mChannelArray retain];
	[mPollTimeMinutes retain];
    [[self undoManager] enableUndoRegistration]; 
	
	// Model does not automatically call registerNotificationObservers so we do it here where object is restored
	// or initialized for first time.
	[self registerNotificationObservers];   
	
    return self;
}

- (void) encodeWithCoder: (NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject: mChannelArray forKey: @"mChannelArray"];
//	NSNumber* pollingTime = [NSNumber numberWithFloat: mPollTimeMinutes];
	[encoder encodeObject: mPollTimeMinutes forKey: HVkPollTimeMinutes];
}

#pragma mark •••Utilities
/*- (void) interpretReturn: (NSString* ) aRawData dataStore: (NSMutableDictionary* ) aDataStore
{
	
	if ( [aRawData length] )
	{
		NSString*	values[ ORUVChnlNumParameters ];
		NSScanner* scanner = [NSScanner scannerWithString: aRawData];
		NSCharacterSet* blankSet = [NSCharacterSet characterSetWithCharactersInString: @" "];
		int i = 0;
		for ( i = 0; i < ORUVChnlNumParameters; i++ )
		{
			[scanner scanUpToCharactersFromSet: blankSet intoString: &values[ i ]];
			[scanner setScanLocation: [scanner scanLocation] + 1];

		}
	}
//	[scanner setCharactersToBeSkipped: newlineCharacterSet];

}
*/
- (void) printDictionary: (int) aCurrentChnl
{
	NSDictionary*	tmpChnl = [mChannelArray objectAtIndex: aCurrentChnl];
	
	NSLog( @"Channel: %d\n", aCurrentChnl);
	
	NSLog( @"Measured HV: %f\n", [[tmpChnl objectForKey: HVkMeasuredHV] floatValue] );

	NSLog( @"Measured Current: %g\n", [[tmpChnl objectForKey: HVkMeasuredCurrent] floatValue] );

	NSLog( @"Demand HV: %g\n", [[tmpChnl objectForKey: HVkDemandHV] floatValue] );

	NSLog( @"RampUpRate: %f\n", [[tmpChnl objectForKey: HVkRampUpRate] floatValue] );

	NSLog( @"RampDownRate: %f\n", [[tmpChnl objectForKey: HVkRampDownRate] floatValue] );

	NSLog( @"Trip current: %f\n", [[tmpChnl objectForKey: HVkTripCurrent] floatValue] );

	NSLog( @"Channel enabled: %d\n", [[tmpChnl objectForKey: HVkChannelEnabled] intValue] );

	NSLog( @"Status: %@\n", [tmpChnl objectForKey: HVkStatus] );
	
	NSLog( @"MVDZ: %f\n", [[tmpChnl objectForKey: HVkMCDZ] floatValue] );
	
	NSLog( @"MCDZ: %f\n", [[tmpChnl objectForKey: HVkMCDZ] floatValue] );

	NSLog( @"HV limit: %f\n", [[tmpChnl objectForKey: HVkHVLimit] floatValue] );	
}

//Added the following during a sweep to put the CrateView functionality into the Crate  objects MAH 11/18/08
- (int) stationNumber
{
	int station = [[self crate] maxNumberOfObjects] - [self slot] - 1;
	return( station );
}

- (NSString*) cardSlotChangedNotification
{
    return UVCardSlotChanged;
}

- (NSDictionary*) createChnlRetDict: (int) aCurrentChnl
{
	NSNumber* curChannel = [NSNumber numberWithInt: aCurrentChnl];
	[curChannel retain];
	NSDictionary* retDict = [NSDictionary dictionaryWithObject: curChannel forKey: HVkChannel];
	[curChannel release];
	return( retDict );
}

@end
