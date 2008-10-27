//
//  ORUnivVoltModel.h
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


#pragma mark •••Imported Filesg

#import "ORCard.h"

#define UVkNumChannels 12
#define UVkChnlNumParameters 11 //see below for list.

enum hveStatus {eHVUEnabled = 0, eHVURampingUp, eHVURampingDown, evHVUTripForSupplyLimits = 4,
                eHVUTripForUserCurrent, eHVUTripForHVError, eHVUTripForHVLimit};
typedef enum hveStatus hveStatus;


@interface ORUnivVoltModel : ORCard 
{
	id						adapter;
	NSMutableArray*			mChannelArray;
//	NSArray*				mSetCommands;
//	NSArray*				mAllCommands;
	NSMutableDictionary*	mParams;	//Dictionary of HV unit parameters indicating type of parameter and whether it is R or R/W. 
	NSMutableArray*			mCommands;  //Crate commands for HV Unit
}

#pragma mark ••• Notifications
- (void) registerNotificationObservers;

#pragma mark ••• Send Commands
- (void)  getValues;
- (void)  loadValues;

#pragma mark •••Accessors
- (NSMutableArray*) channelArray;
- (void) setChannelArray:(NSMutableArray*)anArray;
- (NSMutableDictionary*) channelDictionary: (int) aCurrentChnl;
- (void)  setChannelEnabled: (int) anEnabled chnl: (int) aCurrentChnl;
- (int)   chnlEnabled: (int) aCurrentChnl;
- (float) measuredCurrent: (int) aCurrentChnl;
- (float) measuredHV: (int) aCurrentChnl;
- (float) demandHV: (int) aCurrentChnl;
- (void)  setDemandHV: (float) aDemandHV chnl: (int) aCurrentChnl;
- (float) tripCurrent: (int) aCurrentChnl;
- (void)  setTripCurrent: (float) aTripCurrent chnl: (int) aCurrentChnl;
- (float) rampUpRate: (int) aCurrentChnl;
- (void)  setRampUpRate: (float) aRampUpRate chnl: (int) aCurrentChnl;
- (float) rampDownRate: (int) aCurrentChnl;
- (void)  setRampDownRate: (float) aRampDownRate chnl: (int) aCurrentChnl;
- (NSString*) status: (int) aCurrentChnl;
- (float) MVDZ: (int) aCurrentChnl;
- (void)  setMVDZ: (float) aMCDZ chnl: (int) aCurrentChnl;
- (float) MCDZ: (int) aCurrentChnl;
- (void)  setMCDZ: (float) aMCDZ chnl: (int) aCurrentChnl;
- (float)  HVLimit: (int) aCurrentChnl;


#pragma mark •••Interpret data
- (void) interpretDataReturn: (NSNotification*) aNote;
- (void) interpretDMPReturn: (NSDictionary*) aReturnData channel: (int) aCurChnl;

#pragma mark •••Utilities
- (void) printDictionary: (int) aCurrentChnl;

#pragma mark ***Archival
- (id) initWithCoder: (NSCoder*) decoder;
- (void) encodeWithCoder: (NSCoder*) encoder;
@end

extern NSString* UVChnlEnabledChanged;
extern NSString* UVChnlDemandHVChanged;
extern NSString* UVChnlMeasuredHVChanged;
extern NSString* UVChnlMeasuredCurrentChanged;
extern NSString* UVChnlSlotChanged;
extern NSString* UVChnlRampUpRateChanged;
extern NSString* UVChnlRampDownRateChanged;
extern NSString* UVChnlTripCurrentChanged;
extern NSString* UVChnlStatusChanged;
extern NSString* UVChnlMVDZChanged;
extern NSString* UVChnlMCDZChanged;
extern NSString* UVChnlHVLimitChanged;
extern NSString* UVChnlChanged;

extern NSString* UVChnlHVValuesChanged;

// HV unit Parameters
extern NSString* HVkChnlEnabled;		//1
extern NSString* HVkMeasuredCurrent;	//2
extern NSString* HVkMeasuredHV;			//3
extern NSString* HVkDemandHV;		    //4
extern NSString* HVkRampUpRate;			//5
extern NSString* HVkRampDownRate;		//6
extern NSString* HVkTripCurrent;		//7
extern NSString* HVkStatus;				//8
extern NSString* HVkMVDZ;				//9
extern NSString* HVkMCDZ;				//10
extern NSString* HVkHVLimit;			//11

extern NSString* HVkCurChnl;


//extern NSString* ORUnivVoltLock;