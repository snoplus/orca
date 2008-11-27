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
#import "ORUnivVoltHVCrateModel.h"

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

    
   [notifyCenter addObserver : self
                     selector : @selector( channelChanged: )
                         name : UVChnlChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector( channelEnabledChanged:)
                         name : UVChnlEnabledChanged
						object: model];

   [notifyCenter addObserver : self
                     selector : @selector( measuredCurrentChanged:)
                         name : UVChnlMeasuredCurrentChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector( measuredHVChanged:)
                         name : UVChnlMeasuredHVChanged
						object: model];
						    
	[notifyCenter addObserver : self
                     selector : @selector( demandHVChanged:)
                         name : UVChnlDemandHVChanged
						object: model];

						
	[notifyCenter  addObserver: self
	                  selector: @selector( writeErrorMsg: )
					     name : HVSocketNotConnectedNotification
					   object : nil];


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

	[notifyCenter  addObserver: self
	                  selector: @selector( setValues: )
					     name : UVChnlHVValuesChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector( pollingTimeChanged:)
                         name : UVPollTimeMinutesChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector( pollingStatusChanged:)
                         name : UVStatusPollTaskChanged
						object: model];

	[notifyCenter  addObserver: self
	                  selector: @selector( writeErrorMsg: )
					     name : HVSocketNotConnectedNotification
					   object : nil];

}


- (void) awakeFromNib
{
	[super awakeFromNib];
	
	mCurrentChnl = 0;
	[mChannelStepperField setIntValue: mCurrentChnl];
	[mChannelNumberField setIntValue: mCurrentChnl];
	
	[mChnlTable reloadData];
}

- (void) setValues: (NSNotification *) aNote
{
	NSDictionary* curChnlDict = [aNote userInfo];
	mCurrentChnl = [[curChnlDict objectForKey: HVkCurChnl] intValue];
	[self setChnlValues: mCurrentChnl];

	[mChnlTable reloadData];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"Univ Volt Card (Slot %d)",[model stationNumber]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Univ Volt Card (Slot %d)",[model stationNumber]]];
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
	[self pollingTimeChanged: nil];
	
	[mChnlTable reloadData];	
}

#pragma mark •••Notification - Responses•••
- (void) channelChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  

}

- (void) channelEnabledChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mChnlEnabled setIntValue: [model chnlEnabled: mCurrentChnl]];
}

- (void) measuredCurrentChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mMeasuredCurrent setFloatValue: [model measuredCurrent: mCurrentChnl]];
	NSLog( @"Measured current: %g, for chnl: %d", [model measuredCurrent: mCurrentChnl], mCurrentChnl );
}

- (void) demandHVChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mDemandHV setFloatValue: [model demandHV: mCurrentChnl]];
}

- (void) measuredHVChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mMeasuredHV setFloatValue: [model measuredHV: mCurrentChnl]];
}

- (void) tripCurrentChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mTripCurrent setFloatValue: [model tripCurrent: mCurrentChnl]];
}

- (void) rampUpRateChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mRampUpRate setFloatValue: [model rampUpRate: mCurrentChnl]];
}

-(void) statusChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mStatus setStringValue: [model status: mCurrentChnl]];
}

- (void) rampDownRateChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mRampDownRate setFloatValue: [model rampDownRate: mCurrentChnl]];
}

- (void) MVDZChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mMVDZ setFloatValue: [model MVDZ: mCurrentChnl]];
}

- (void) MCDZChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mMCDZ setFloatValue: [model MCDZ: mCurrentChnl]];
}

- (void) hvLimitChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mHVLimit setFloatValue: [model HVLimit: mCurrentChnl]];
}

- (void) pollingTimeChanged: (NSNotification *) aNote
{
	[mPollingTimeMinsField setIntValue: [model pollTimeMinutes]];
}

- (void) pollingStatusChanged: (NSNotification *) aNote
{
	bool ifPoll = [model isPollingTaskRunning];;
	[mStartStopPolling setTitle: ( ifPoll ? @"Stop" : @"Start" ) ];
//		[mStartStopPolling setText
}

- (void) writeErrorMsg: (NSNotification*) aNote
{
	NSDictionary* errorDict = [aNote userInfo];
	NSLog( @"error: %@", [errorDict objectForKey: UVkErrorMsg] );
	[mCmdStatus setStringValue: [errorDict objectForKey: UVkErrorMsg]];
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
	// setChannelNumberField - updates display
}

- (IBAction) setChnlEnabled: (id) aSender
{
	int enabled = [mChnlEnabled state];

	[model setChannelEnabled: enabled chnl: mCurrentChnl];
}

- (IBAction) setDemandHV: (id) aSender
{	
	[model setDemandHV: [mDemandHV floatValue] chnl: mCurrentChnl];}
- (IBAction) setTripCurrent: (id) aSender
{
	[model setTripCurrent: [mTripCurrent floatValue] chnl: mCurrentChnl];	
}

- (IBAction) setRampUpRate: (id) aSender
{
	[model setRampUpRate: [mRampUpRate floatValue] chnl: mCurrentChnl];
}

- (IBAction) setRampDownRate: (id) aSender
{
	[model setRampDownRate: [mRampDownRate floatValue] chnl: mCurrentChnl];
}

- (IBAction) setMVDZ: (id) aSender
{
	[model setMVDZ: [mMVDZ floatValue] chnl: mCurrentChnl];
}

- (IBAction) setMCDZ: (id) aSender
{
	[model setMCDZ: [mMCDZ floatValue] chnl: mCurrentChnl];
}

- (IBAction) updateTable: (id) aSender
{
	[mChnlTable reloadData];	
}

- (IBAction) hardwareValuesOneChannel: (id) aSender
{
	[model getValues: mCurrentChnl];
}

- (IBAction) hardwareValues: (id) aSender
{
	NSLog( @"Get hardware values\n" );
	[model getValues: -1];
}

- (IBAction) setHardwareValesOneChannel: (id ) aSender;
{
	NSLog( @"Download params for chnl %d\n", mCurrentChnl );
	[model loadValues: mCurrentChnl];
}

- (IBAction) setHardwareValues: (id) aSender
{
	NSLog( @"Download hardware values\n" );
	[model loadValues: -1];
}

- (IBAction) pollTimeAction: (id) aSender
{
	[model setPollTimeMinutes: [mPollingTimeMinsField floatValue]];
}

- (IBAction) startStopPolling: (id) aSender
{
	if ( [model isPollingTaskRunning] ) {
		[model stopPolling];
	} else {
		int pollingTimeMins = [mPollingTimeMinsField intValue];
		[model setPollTimeMinutes: pollingTimeMins] ;
		[model startPolling];
	}
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
{	return( UVkNumChannels );
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
- (void) setCurrentChnl: (NSNotification *) aNote
{
	NSDictionary* chnlDict = [aNote userInfo];
	mCurrentChnl = [[chnlDict objectForKey: HVkCurChnl] intValue];
}

- (void) setChnlValues: (int) aCurrentChannel
{
	NSDictionary*	tmpChnl = [model channelDictionary: aCurrentChannel];
	bool			state = [mChnlEnabled state];
//	int				status;

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
	[mStatus setStringValue: [tmpChnl objectForKey: HVkStatus]];

}


@end
