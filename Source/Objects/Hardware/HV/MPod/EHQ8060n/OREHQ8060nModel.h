//
//  OREHQ8060nModel.h
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORPxiIOCard.h";
#import "ORDataTaker.h";
#import "ORHWWizard.h";
#import "SBC_Config.h"

@class ORRateGroup;
@class ORAlarm;

#define kNumEHQ8060nChannels			32 

#pragma mark •••Register Definitions
enum {
	kBoardID,					//[0] 
	kThreshold,					//[1] 
	kNumberOfEHQ8060nRegisters	//must be last
};

@interface OREHQ8060nModel : ORPxiIOCard <ORDataTaker,ORHWWizard>
{
  @private
	unsigned long   dataId;
	unsigned long*  dataBuffer;
    short			enabled[kNumEHQ8060nChannels];
    short			threshold[kNumEHQ8060nChannels];
 	
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumEHQ8060nChannels];
	BOOL isRunning;

	//cach to speed takedata
	unsigned long location;
	
	//for testing
	unsigned long delay;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark •••specific accessors
- (int) enabled:(short)chan;		
- (void) setEnabled:(short)chan withValue:(short)aValue;		
- (int) threshold:(short)chan;	
- (void) setThreshold:(short)chan withValue:(int)aValue;

#pragma mark •••Hardware Access
- (void) initBoard;
- (void) setDefaults;
- (void) writeThreshold:(int)channel;

#pragma mark •••Rates
- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;

#pragma mark •••Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (unsigned long) waveFormCount:(int)aChannel;
- (void)   startRates;
- (void) clearWaveFormCounts;
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag;

#pragma mark •••HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(short*)anArray forKey:(NSString*)aKey;
@end

extern NSString* OREHQ8060nModelEnabledChanged;
extern NSString* OREHQ8060nModelThresholdChanged;
extern NSString* OREHQ8060nSettingsLock;
extern NSString* OREHQ8060nRateGroupChangedNotification;
