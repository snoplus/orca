//
//  ORUnivVoltController.m
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
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


#import "ORUnivVoltController.h"
#import "ORUnivVoltModel.h"

@implementation ORUnivVoltController
- (id) init
{
    self = [ super initWithWindowNibName: @"UnivVolt" ];
    return self;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
/*    [notifyCenter addObserver : self
                     selector : @selector( slotChanged: )
                         name : ORUVHVSlotChanged
						object: model];
*/

    [notifyCenter addObserver : self
                     selector : @selector( channelEnabledChanged:)
                         name : ORUVUnitEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector( demandHVChanged:)
                         name : ORUVUnitDemandHVChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector( measuredHVChanged:)
                         name : ORUVUnitMeasuredHVChanged
						object: model];

/*
    [notifyCenter addObserver : self
                     selector : @selector( measuredCurrentChanged: )
                         name : ORHVMeasuredCurrentChanged
*/
/*						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
					   object : nil];
*/
}


- (void) updateWindow
{
    [ super updateWindow ];
    
//    [self settingsLockChanged:nil];
//	[self ipAddressChanged:nil];
//	[self isConnectedChanged:nil];
//	[self frameErrorChanged:nil];
//	[self averageChanged:nil];
//	[self receiveCountChanged:nil];
}

- (void) channelEnabledChanged: (NSNotification*) aNote
{
	[mChnlEnabled setIntValue: [model chnlEnabled: mCurrentChnl]];
}

- (void) demandHVChanged: (NSNotification*) aNote
{
	[mChnlEnabled setFloatValue: [model demandHV: mCurrentChnl]];
}

- (void) measuredHVChanged: (NSNotification*) aNote
{
	[mDemandHV setFloatValue: [model measuredHV: mCurrentChnl]];
}


/*- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORUnivVoltLock to:secure];
    [dialogLock setEnabled:secure];
}
*/
/*
- (void) receiveCountChanged:(NSNotification*)aNote
{
	[receiveCountField setIntValue: [model receiveCount]];
}
*/
/*
- (void) frameErrorChanged:(NSNotification*)aNote
{
	[frameErrorField setIntValue: [model frameError]];
}
*/
/*
- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL locked			= [gSecurity isLocked:ORUnivVoltLock];

	[ipConnectButton setEnabled:!locked];
	[ipAddressTextField setEnabled:!locked];

    [dialogLock setState: locked];

}
*/
#pragma mark •••Actions
- (IBAction) setChannelNumberField: (id) aSender
{
	 mCurrentChnl = [mChannelNumber intValue];
	[self setChnlValues: mCurrentChnl];
	[mChannelStepper setIntValue: mCurrentChnl];
}

- (IBAction) setChannelNumberStepper: (id) aSender
{
	mCurrentChnl = [mChannelStepper intValue];
	[self setChnlValues: mCurrentChnl];
	[mChannelNumber setIntValue: mCurrentChnl];
}

- (IBAction) setChnlEnabled: (id) aSender
{
	int enabled = [mChnlEnabled state];
	
//	NSNumber* enabledObj = [NSNumber numberWithBool: enabled];

	[model setChannelEnabled: enabled chnl: mCurrentChnl];
}

- (IBAction) setDemandHV: (id) aSender
{
	
//	NSLog( @"Number of items in dictionary in setDemandHV: %d", [mChannelDict count] );
	[model setDemandHV: [mDemandHV stringValue]];
}

- (void) updateDemandHV: (NSNotification*) aNote
{
	float demandHV = [model demandHV: mCurrentChnl];
	[mDemandHV setFloatValue: demandHV];
//	NSString* demandHV = [NSString stringWithString: [mDemandHV stringValue]];

}
/*
- (IBAction) setChnlEnabled: (id) aSender
{
	bool enabled = [mChnlEnabled state];
	
	NSNumber* enabledObj = [NSNumber numberWithBool: enabled];

	NSMutableDictionary* tmpChnl = [mChannelDict objectAtIndex: mCurrentChnl];
	[tmpChnl setObject: enabledObj forKey: ORHVkChnlEnabled];
}

- (IBAction) setTripCurrent: (id) aSender
{
	NSString* tripCurrent = [NSString stringWithString: [mTripCurrent stringValue]];

	NSMutableDictionary* tmpChnl = [mChannelDict objectAtIndex: mCurrentChnl];
	[tmpChnl setObject: tripCurrent forKey: ORHVkTripCurrent];
}

- (IBAction) setRampUpRate: (id) aSender
{
	NSString* rampUpRate = [NSString stringWithString: [mRampUpRate stringValue]];

	NSMutableDictionary* tmpChnl = [mChannelDict objectAtIndex: mCurrentChnl];
	[tmpChnl setObject: rampUpRate forKey: ORHVkRampUpRate];
}

- (IBAction) setRampDownRate: (id) aSender
{
	NSString* rampDownRate = [NSString stringWithString: [mRampDownRate stringValue]];

	NSMutableDictionary* tmpChnl = [mChannelDict objectAtIndex: mCurrentChnl];
	[tmpChnl setObject: rampDownRate forKey: ORHVkRampDownRate];
}

- (IBAction) setMVDZ: (id) aSender
{
	NSString* MVDZ = [NSString stringWithString: [mMVDZ stringValue]];

	NSMutableDictionary* tmpChnl = [mChannelDict objectAtIndex: mCurrentChnl];
	[tmpChnl setObject: MVDZ forKey: ORHVkMVDZ];
}

- (IBAction) setMCDZ: (id) aSender
{
	NSString* MCDZ = [NSString stringWithString: [mMVDZ stringValue]];

	NSMutableDictionary* tmpChnl = [mChannelDict objectAtIndex: mCurrentChnl];
	[tmpChnl setObject: MCDZ forKey: ORHVkMCDZ];
}
*/
- (IBAction) updateTable: (id) aSender
{
	[mModuleTable reloadData];	
}

#pragma mark •••Table handling routines
- (int) numberOfRowsInTableView: (NSTableView*) aTableView
{
	return( ORHVNumChannels );
}

- (void) tableView: (NSTableView*) aTableView
       setObjectValue: (id) anObject
	   forTableColumn: (NSTableColumn*) aTableColumn
	   row: (int) aRowIndex
{
//	NSMutableDictionary* tmpChnl = [[model dictionary] objectAtIndex: aRowIndex];
	NSString* colIdentifier = [aTableColumn identifier];
	NSMutableDictionary* tmpChnl = [model channelDictionary: aRowIndex];
	[tmpChnl setObject: anObject forKey: colIdentifier];
}

- (id) tableView: (NSTableView*) aTableView
	   objectValueForTableColumn: (NSTableColumn*) aTableColumn
	   row: (int) aRowIndex
{
	NSMutableDictionary* tmpChnl = [model channelDictionary: aRowIndex];
	NSString* colIdentifier = [aTableColumn identifier];
	if ( [colIdentifier isEqualToString: @"chnlEnabled"]) NSLog( @"Row: %d, column: %@", aRowIndex, colIdentifier );
	return( [tmpChnl objectForKey: colIdentifier] );
}

#pragma mark •••Utilities
- (void) setChnlValues: (int) aCurrentChannel
{
	NSDictionary*	tmpChnl = [model channelDictionary: aCurrentChannel];
	bool			state = [mChnlEnabled state];
	int				status;
	
	[model printDictionary: mCurrentChnl];
	
	[mChnlEnabled setState: state];
	[mDemandHV setStringValue: [tmpChnl objectForKey: ORHVkDemandHV] ];
	[mMeasuredHV setStringValue: [tmpChnl objectForKey: ORHVkMeasuredHV]];
	[mMeasuredCurrent setStringValue: [tmpChnl objectForKey: ORHVkMeasuredCurrent]];
	[mTripCurrent setStringValue: [tmpChnl objectForKey: ORHVkTripCurrent]];
	[mRampUpRate setStringValue: [tmpChnl objectForKey: ORHVkRampUpRate]];
	[mRampDownRate setStringValue: [tmpChnl objectForKey: ORHVkRampDownRate]];
	[mMVDZ setStringValue: [tmpChnl objectForKey: ORHVkMVDZ]];
	[mMCDZ setStringValue: [tmpChnl objectForKey: ORHVkMCDZ]];
	
	// status case statement
	status =  [[tmpChnl objectForKey: ORHVkStatus] boolValue];
	switch ( status ) {
		case eHVUEnabled:
			[mStatus setStringValue: @"Enabled"];
			break;
			
		case eHVURampingUp:
			[mStatus setStringValue: @"Ramping up"];
			break;
			
		case eHVURampingDown:
			[mStatus setStringValue: @"Ramping down"];
			break;
			
		case evHVUTripForSupplyLimits:
			[mStatus setStringValue: @"Trip for viol. spply lmt"];
			break;
			
		case eHVUTripForUserCurrent:
			[mStatus setStringValue: @"Trip for viol. current lmt"];
			break;
			
		case eHVUTripForHVError:
			break;
		case eHVUTripForHVLimit:
		default:
			break;
	}
	
}


@end
