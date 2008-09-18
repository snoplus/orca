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

#define ORHVNumChannels 12
#define ORUVChnlNumParameters 11 //see below for list.

enum hveStatus {eHVUEnabled = 0, eHVURampingUp, eHVURampingDown, evHVUTripForSupplyLimits = 4,
                eHVUTripForUserCurrent, eHVUTripForHVError, eHVUTripForHVLimit};


@interface ORUnivVoltModel : ORCard 
{
	id						adapter;
	NSMutableArray*			mChannelArray;
}

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

#pragma mark •••Utilities
- (void) interpretReturn: (NSString* ) aRawData dataStore: (NSMutableDictionary* ) aDataStore;
- (void) printDictionary: (int) aCurrentChnl;

#pragma mark •••DataRecords

#pragma mark ***Archival
- (id) initWithCoder: (NSCoder*) decoder;
- (void) encodeWithCoder: (NSCoder*) encoder;
@end

extern NSString* ORUVChnlEnabledChanged;
extern NSString* ORUVChnlDemandHVChanged;
extern NSString* ORUVChnlMeasuredHVChanged;
extern NSString* ORUVChnlMeasuredCurrentChanged;
extern NSString* ORUVChnlSlotChanged;
extern NSString* ORUVChnlTripCurrentChanged;
extern NSString* ORUVChnlRampUpRateChanged;
extern NSString* ORUVChnlRampDownRateChanged;
extern NSString* ORUVChnlMVDZChanged;
extern NSString* ORUVChnlMCDZChanged;
extern NSString* ORUVChnlHVLimitChanged;

// HV unit Parameters
extern NSString* ORHVkChnlEnabled;      //1
extern NSString* ORHVkMeasuredCurrent;	//2
extern NSString* ORHVkMeasuredHV;		//3
extern NSString* ORHVkDemandHV;		    //4
extern NSString* ORHVkRampUpRate;		//5
extern NSString* ORHVkRampDownRate;		//6
extern NSString* ORHVkTripCurrent;		//7
extern NSString* ORHVkStatus;			//8
extern NSString* ORHVkMVDZ;				//9
extern NSString* ORHVkMCDZ;				//10
extern NSString* ORHVkHVLimit;			//11

//extern NSString* ORUnivVoltLock;