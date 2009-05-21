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
#import "ORCircularBufferUV.h"
#import "ORPlotter1D.h"

const int MAXcCHNLS_PER_PLOT = 6;

@implementation ORUnivVoltController
- (id) init
{
    self = [ super initWithWindowNibName: @"UnivVolt" ];
	if ( self ) 
	{
	
	}
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
						
//	[notifyCenter  addObserver: self
//	                  selector: @selector( writeErrorMsg: )
//					     name : HVSocketNotConnectedNotification
//					   object : nil];

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
					     name : HVShortErrorNotification
					   object : nil];
	
}


- (void) awakeFromNib
{
	[super awakeFromNib];
	
	mCurrentChnl = 0;
	mOrigChnl = 0;
	NSLog( @"UnivVolt:AwakeFromNIB.  Current chnl: ", mCurrentChnl );
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
	int value =  [model chnlEnabled: mCurrentChnl];
//	NSLog( @"ORController - EnabledChanged( %d ): %d\n", mCurrentChnl, value );
	[mChnlEnabled setIntValue: value];
}

- (void) measuredCurrentChanged: (NSNotification*) aNote
{
//	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mMeasuredCurrent setFloatValue: [model measuredCurrent: mCurrentChnl]];
	NSLog( @"Measured current: %g, for chnl: %d", [model measuredCurrent: mCurrentChnl], mCurrentChnl );
}

- (void) demandHVChanged: (NSNotification*) aNote
{
	float value;
	[self setCurrentChnl: (NSNotification *) aNote ];  
	value = [model demandHV: mCurrentChnl];
	NSLog( @"Setting demand HV to: %f  for channel %d\n", value, mCurrentChnl);
	[mDemandHV setFloatValue: value];
}

- (void) measuredHVChanged: (NSNotification*) aNote
{
//	[self setCurrentChnl: (NSNotification *) aNote ];  
	float hvValue = [model measuredHV: mCurrentChnl];
	[mMeasuredHV setFloatValue: hvValue];	
//	ORCircularBufferUV* cbObj = [mCircularBuffers objectAtIndex: mCurrentChnl];
	
/*	if (cbObj ) {
		NSDate* dateObj = [NSDate date];
//	NSNumber* hvValueObj = [NSNumber numberWithFloat: hvValue];
		[cbObj insertHVEntry: dateObj hvValue: hvValue];
	}
	*/
}

- (void) tripCurrentChanged: (NSNotification*) aNote
{
	float value;
	[self setCurrentChnl: (NSNotification *) aNote ];  
	value = [model tripCurrent: mCurrentChnl];
	NSLog( @"tripCurrentChanged for chnl %d: %f\n", mCurrentChnl, value );
	[mTripCurrent setFloatValue: value];
}

- (void) rampUpRateChanged: (NSNotification*) aNote
{
	float value;
	[self setCurrentChnl: (NSNotification *) aNote ]; 
	value = [model rampUpRate: mCurrentChnl];
	NSLog( @"RampUpRate %f for channel %d changed.\n", value, mCurrentChnl);
	[mRampUpRate setFloatValue: [model rampUpRate: mCurrentChnl]];
}

- (void) rampDownRateChanged: (NSNotification*) aNote
{
	float value;
	[self setCurrentChnl: (NSNotification *) aNote ]; 
	value = [model rampDownRate: mCurrentChnl];
	NSLog( @"RampDownRate %f for channel %d changed.\n", value, mCurrentChnl);
	[mRampDownRate setFloatValue: [model rampDownRate: mCurrentChnl]];
}

-(void) statusChanged: (NSNotification*) aNote
{
	[self setCurrentChnl: (NSNotification *) aNote ];  
	[mStatus setStringValue: [model status: mCurrentChnl]];
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
	[mPollingTimeMinsField setFloatValue: [model pollTimeMinutes]];
	NSLog( @"Controller - notified of polling time change: %f\n", [mPollingTimeMinsField floatValue]);
}

- (void) pollingStatusChanged: (NSNotification *) aNote
{
	bool ifPoll = [model isPollingTaskRunning];
	[mStartStopPolling setTitle: ( ifPoll ? @"Stop" : @"Start" ) ];
}

- (void) writeErrorMsg: (NSNotification*) aNote
{
	NSDictionary* errorDict = [aNote userInfo];
	NSLog( @"error: %@", [errorDict objectForKey: HVkErrorMsg] );
	[mCmdStatus setStringValue: [errorDict objectForKey: HVkErrorMsg]];
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
//	[self updateWindow]; Not needed.
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
	int enabled = [mChnlEnabled intValue];
//	NSLog( @"ORController - SetEnabled( %d ): %d\n", mCurrentChnl, enabled );
	[model setChannelEnabled: enabled chnl: mCurrentChnl];
}

- (IBAction) setDemandHV: (id) aSender
{	
	[model setDemandHV: [mDemandHV floatValue] chnl: mCurrentChnl];
}

- (IBAction) setTripCurrent: (id) aSender
{
	float value = [mTripCurrent floatValue];
	NSLog( @"Set trip current for channel %d to %f\n", mCurrentChnl, value );
	[model setTripCurrent: value chnl: mCurrentChnl];	
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
		float pollingTimeMins = [mPollingTimeMinsField floatValue];
		[model setPollTimeMinutes: pollingTimeMins] ;
		[model startPolling];
	}
}

#pragma mark •••Code for plotter
- (int) numberOfDataSetsInPlot: (id) aPlotter
{
	int totalChnls;
	
	totalChnls = [model numChnlsEnabled];
	NSLog( @"Total chnls: %d\n", totalChnls );
	
	if ( aPlotter == mPlottingObj1 ) {
		if ( totalChnls > MAXcCHNLS_PER_PLOT ) {
			return( MAXcCHNLS_PER_PLOT );
		}
		else {
			return( totalChnls );
		}
	}
	else {
		return( totalChnls - MAXcCHNLS_PER_PLOT );
	}
	return( 0 );
}

- (float) plotter: (id) aPlotter dataSet: (int) aChnl dataValue: (int) anX 
{
	
	if ( aChnl >= 0 ) {
		ORCircularBufferUV* cbObj = [model circularBuffer: aChnl];
		if ( anX >= [cbObj size] )
			return( 0.0 );
			
		NSDictionary* retDataObj = [cbObj HVEntry: anX];
		NSNumber* hvValueObj = [retDataObj objectForKey: @"HVValue"];
		float hvValue = [hvValueObj floatValue];
		
		return( hvValue );
	}
	return 0;
}


/*
- (double) getBarValue: (int) aTag
{
	ORCircularBufferUV* cbObj = [model circularBuffer: aTag ];
	NSDictionary* retData = [cbObj HVEntry: aTag];
	NSNumber*  hvMeasuredObj = [retDate objectForKey: ];
	return( [hvMeasuredObj floatValue] );
}
*/




- (int)	numberOfPointsInPlot: (id) aPlotter dataSet: (int) aChnl
{
	return( [model circularBufferSize: aChnl] );
}


/*- (float) plotter: (id) aPlotter dataSet: (int) aChnl dataValue: (int) x  
{
	
	if( aChnl ) {
		ORCircularBufferUV* cbObj = [model circularBuffer: aChnl];
		NSDictionary* dictObj = [cbObj HVEntry: -1 * x];
//		NSString* keyStr = [[cbObj mKeys] objectAtIndex: 1];
		NSNumber* numObj = [dictObj objectForKey: CBkHVKey];
		return [numObj floatValue];

	}
	return 0;
}
*/

- (unsigned long) secondsPerUnit: (id) aPlotter
{
	unsigned long sampleTime = [mPollingTimeMinsField intValue] * 60;
	return( sampleTime );
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

#pragma mark •••Delegate
- (void) tabView: (NSTabView*) aTabView didSelectTabViewItem: (NSTabViewItem*) aTabViewItem
{
	int index = [aTabView indexOfTabViewItem: aTabViewItem];
	NSString* labelTab = [aTabViewItem label];
	NSLog( @"tab index: %d, tab label %@\n", index, labelTab );
	if ( [labelTab isEqualToString: @"Channel"] )
	{
		mCurrentChnl = mOrigChnl;
		[mChannelStepperField setIntValue: mCurrentChnl];
		[mChannelNumberField setIntValue: mCurrentChnl];
		[self setChnlValues: mCurrentChnl];
	}
	else
	{
		mOrigChnl = mCurrentChnl;
	}
}

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
	if ( [colIdentifier isEqualToString: @"chnlEnabled"]) NSLog( @"ORUnivVoltCont - Row: %d, column: %@", aRowIndex, colIdentifier );
	return( [tmpChnl objectForKey: colIdentifier] );
}

#pragma mark •••Utilities
- (void) setCurrentChnl: (NSNotification *) aNote
{
	if ( aNote == 0 ) {
//	    NSLog( @"aNote is nil" );
		mCurrentChnl = 0;
	} else {
		NSDictionary* chnlDict = [aNote userInfo];
		mCurrentChnl = [[chnlDict objectForKey: HVkChannel] intValue];
	}
//[chnlDict objectForKey: HVkCurChnl];

}

// Set values for single channel display.
- (void) setChnlValues: (int) aCurrentChannel
{
	float			value;
	NSDictionary*	tmpChnl = [model channelDictionary: aCurrentChannel];
//	bool			state = [mChnlEnabled state];
	NSString*		valueStr;
	int				valueInt;
//	int				status;

//	[model printDictionary: mCurrentChnl];
//	NSLog( @"\n\nChnl: %d\n", aCurrentChannel );
	
//	[mChnlEnabled setState: state];
//	NSLog( @"State: %d\n", state );
	valueInt = [[tmpChnl objectForKey: HVkChannelEnabled] intValue];
	[mChnlEnabled setIntValue: valueInt];
//	valueStr = [mChnlEnabled: intValue: valueInt];
	
	value = [[tmpChnl objectForKey: HVkMeasuredCurrent] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	
	[mMeasuredCurrent setStringValue: valueStr];
//	NSLog( @"Measured current: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkMeasuredHV] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mMeasuredHV setStringValue: valueStr];
//	NSLog( @"Measured HV: %f\n", value );

	value = [[tmpChnl objectForKey: HVkDemandHV] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mDemandHV setStringValue: valueStr];
//	NSLog( @"Demand HV: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkRampUpRate] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mRampUpRate setStringValue: valueStr];
//	NSLog( @"mRampUpRate: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkRampDownRate] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mRampDownRate setStringValue: valueStr];
//	NSLog( @"mRampDownRate: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkTripCurrent] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mTripCurrent setStringValue: valueStr];
//	NSLog( @"mTripCurrent: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkMVDZ] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mMVDZ setStringValue: valueStr];
//	NSLog( @"mMVDZ: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkMCDZ] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mMCDZ setStringValue: valueStr];
//	NSLog( @"mMCDZ: %f\n", value );
	
	value = [[tmpChnl objectForKey: HVkHVLimit] floatValue];
	valueStr = [NSString stringWithFormat: @"%f", value];
	[mHVLimit setStringValue: valueStr];
//	NSLog( @"mHVLimit: %f\n", value );
	
	// status case statement
	[mStatus setStringValue: [tmpChnl objectForKey: HVkStatus]];

}


@end
