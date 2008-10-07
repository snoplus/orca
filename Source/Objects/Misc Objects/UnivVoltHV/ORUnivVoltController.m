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
  
	  [super registerNotificationObservers];

    
/*    [notifyCenter addObserver : self
                     selector : @selector( slotChanged: )
                         name : ORUVHVSlotChanged
						object: model];
*/

    [notifyCenter addObserver : self
                     selector : @selector( channelEnabledChanged:)
                         name : UVChnlEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector( demandHVChanged:)
                         name : UVChnlDemandHVChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector( measuredHVChanged:)
                         name : UVChnlMeasuredHVChanged
						object: model];

/*
    [notifyCenter addObserver : self
                     selector : @selector( measuredCurrentChanged: )
                         name : ORHVMeasuredCurrentChanged
*/
   [notifyCenter addObserver : self
                     selector : @selector( rampUpRateChanged:)
                         name : UVChnlRampUpRateChanged
						object: model];

   [notifyCenter addObserver : self
                     selector : @selector( rampDownRateChanged:)
                         name : UVChnlRampDownRateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector( tripCurrentChanged:)
                         name : UVChnlTripCurrentChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector( statusChanged:)
                         name : UVChnlMVDZChanged
						object: model];
						
   [notifyCenter addObserver : self
                     selector : @selector( MVDZChanged:)
                         name : UVChnlMVDZChanged
						object: model];
						
    [notifyCenter addObserver : self
                     selector : @selector( MCDZChanged:)
                         name : UVChnlMVDZChanged
						object: model];
						
    [notifyCenter addObserver : self
                     selector : @selector( hvLimitChanged:)
                         name : UVChnlHVLimitChanged
						object: model];						
}


- (void) awakeFromNib
{
	[super awakeFromNib];
	
	mCurrentChnl = 0;
	[mChannelStepperField setIntValue: mCurrentChnl];
	[mChannelNumberField setIntValue: mCurrentChnl];
}


- (void) updateWindow
{
    [super updateWindow];
    
	[self channelEnabledChanged: nil];
	[self demandHVChanged: nil];
	[self measuredHVChanged: nil];
	[self tripCurrentChanged: nil];
	[self rampUpRateChanged: nil];
	[self rampDownRateChanged: nil];
	[self MVDZChanged: nil];
	[self MCDZChanged: nil];
	[self hvLimitChanged: nil];
	
	[mChnlTable reloadData];	
}

- (void) channelEnabledChanged: (NSNotification*) aNote
{
	[mChnlEnabled setIntValue: [model chnlEnabled: mCurrentChnl]];
}

- (void) measuredCurrentChanged: (NSNotification*) aNote
{
	[mMeasuredCurrent setFloatValue: [model measuredCurrent: mCurrentChnl]];
	NSLog( @"Measured current: %g, for chnl: %d", [model measuredCurrent: mCurrentChnl], mCurrentChnl );
}

- (void) demandHVChanged: (NSNotification*) aNote
{
	[mDemandHV setFloatValue: [model demandHV: mCurrentChnl]];
}

- (void) measuredHVChanged: (NSNotification*) aNote
{
	[mMeasuredHV setFloatValue: [model measuredHV: mCurrentChnl]];
}

- (void) tripCurrentChanged: (NSNotification*) aNote
{
	[mTripCurrent setFloatValue: [model tripCurrent: mCurrentChnl]];
}

- (void) rampUpRateChanged: (NSNotification*) aNote
{
	[mRampUpRate setFloatValue: [model rampUpRate: mCurrentChnl]];
}

-(void) statusChanged: (NSNotification*) aNote
{
	[mStatus setStringValue: [model status: mCurrentChnl]];
}

- (void) rampDownRateChanged: (NSNotification*) aNote
{
	[mRampDownRate setFloatValue: [model rampDownRate: mCurrentChnl]];
}

- (void) MVDZChanged: (NSNotification*) aNote
{
	[mMVDZ setFloatValue: [model MVDZ: mCurrentChnl]];
}

- (void) MCDZChanged: (NSNotification*) aNote
{
	[mMCDZ setFloatValue: [model MCDZ: mCurrentChnl]];
}

- (void) hvLimitChanged: (NSNotification*) aNote
{
	[mHVLimit setFloatValue: [model HVLimit: mCurrentChnl]];
}

- (IBAction) updateTable: (id) aSender
{
	[mChnlTable reloadData];	
}

- (IBAction) hardwareValues: (id) aSender
{
}

- (IBAction) setHardwareValues: (id) aSender
{
}


/*- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORUnivVoltLock to:secure];
    [dialogLock setEnabled:secure];
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
	 mCurrentChnl = [mChannelNumberField intValue];
	[mChannelStepperField setIntValue: mCurrentChnl];
	[self setChnlValues: mCurrentChnl];
	[self updateWindow];
}

- (IBAction) setChannelNumberStepper: (id) aSender
{
	mCurrentChnl = [mChannelStepperField intValue];
	[mChannelNumberField setIntValue: mCurrentChnl];
	[self setChnlValues: mCurrentChnl];
	[self updateWindow];
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
- (IBAction) setTripCurrent: (id) aSender
{
	[model setTripCurrent: [mTripCurrent stringValue]];	
}

- (IBAction) setRampUpRate: (id) aSender
{
	[model setRampUpRate: [mRampUpRate stringValue]];
}

- (IBAction) setRampDownRate: (id) aSender
{
	[model setRampDownRate: [mRampDownRate stringValue]];
}

- (IBAction) setMVDZ: (id) aSender
{
	[model setMVDZ: [mMVDZ stringValue]];
}

- (IBAction) setMCDZ: (id) aSender
{
	[model setMCDZ: [mMCDZ stringValue]];
}


#pragma mark ***Code no longer used.
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
//	if ( [colIdentifier isEqualToString: @"chnlEnabled"]) NSLog( @"Row: %d, column: %@", aRowIndex, colIdentifier );
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
	[mMeasuredCurrent setStringValue: [tmpChnl objectForKey: HVkMeasuredCurrent]];
	[mMeasuredHV setStringValue: [tmpChnl objectForKey: HVkMeasuredHV]];
	[mDemandHV setStringValue: [tmpChnl objectForKey: HVkDemandHV] ];
	[mRampUpRate setStringValue: [tmpChnl objectForKey: HVkRampUpRate]];
	[mRampDownRate setStringValue: [tmpChnl objectForKey: HVkRampDownRate]];
	[mTripCurrent setStringValue: [tmpChnl objectForKey: HVkTripCurrent]];
	[mMVDZ setStringValue: [tmpChnl objectForKey: HVkMVDZ]];
	[mMCDZ setStringValue: [tmpChnl objectForKey: HVkMCDZ]];
	[mHVLimit setStringValue: [tmpChnl objectForKey: HVkHVLimit]];
	
	// status case statement
	status =  [[tmpChnl objectForKey: HVkStatus] intValue];
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
			[mStatus setStringValue: @"Trip for viol. spply lmt."];
			break;
			
		case eHVUTripForUserCurrent:
			[mStatus setStringValue: @"Trip for viol. current lmt."];
			break;
			
		case eHVUTripForHVError:
			[mStatus setStringValue: @"Trip of HV limit"];
			break;
			
		case eHVUTripForHVLimit:
			[mStatus setStringValue: @"Trip for viol. volt. lmt."];
			break;
			
		default:
			[mStatus setStringValue: @"unknown status"];
			break;
	}
	
}


@end
