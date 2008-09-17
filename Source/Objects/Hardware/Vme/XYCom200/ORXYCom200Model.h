//-------------------------------------------------------------------------
//  ORXYCom200Model.h
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORVmeIOCard.h";
#import "ORDataTaker.h";
#import "ORHWWizard.h";
#import "SBC_Config.h"

@class ORRateGroup;
@class ORAlarm;

#define kNumXYCom200Channels			8 
#define kNumXYCom200CardParams		6

#define kXYCom200FIFOEmpty		0x800
#define kXYCom200FIFOAlmostEmpty 0x1000
#define kXYCom200FIFOHalfFull	0x2000
#define kXYCom200FIFOAllFull		0x4000

#pragma mark •••Register Definitions
enum {
	kBoardID,			//[0] 
	kProgrammingDone,		//[1] 
	kExternalWindow,                //[2] 
	kPileupWindow,			//[3] 
	kNoiseWindow,			//[4] 
	kExtTriggerSlidingLength,	//[5] 
	kCollectionTime,		//[6] 
	kIntegrationTime,		//[7]
	kControlStatus,			//[8]
	kLEDThreshold,			//[9]
	kCFDParameters,			//[10]
	kRawDataSlidingLength,		//[11]
	kRawDataWindowLength,		//[12]
	kDebugDataBufferAddress,	//[13]
	kDebugDataBufferData,		//[14]
	kNumberOfXYCom200Registers	//must be last
};

enum XYCom200FIFOStates {
	kEmpty,
	kAlmostEmpty,	
	kHalfFull,
	kFull,
	kSome
};

@interface ORXYCom200Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping>
{
  @private
	unsigned long   dataId;
	unsigned long*  dataBuffer;

	NSMutableArray* cardInfo;
    short			enabled[kNumXYCom200Channels];
    short			debug[kNumXYCom200Channels];
    short			pileUp[kNumXYCom200Channels];
    short			polarity[kNumXYCom200Channels];
    short			triggerMode[kNumXYCom200Channels];
    short			ledThreshold[kNumXYCom200Channels];
    short			cfdDelay[kNumXYCom200Channels];
    short			cfdThreshold[kNumXYCom200Channels];
    short			cfdFraction[kNumXYCom200Channels];
    short			dataDelay[kNumXYCom200Channels];
    short			dataLength[kNumXYCom200Channels];
	
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumXYCom200Channels];
	BOOL isRunning;

    int fifoState;
	ORAlarm*        fifoFullAlarm;
	int				fifoEmptyCount;

	//cach to speed takedata
	unsigned long location;
	id theController;
	unsigned long fifoAddress;
	unsigned long fifoStateAddress;

	BOOL oldEnabled[kNumXYCom200Channels];
	unsigned short oldLEDThreshold[kNumXYCom200Channels];
	unsigned short newLEDThreshold[kNumXYCom200Channels];
	BOOL noiseFloorRunning;
	int noiseFloorState;
	int noiseFloorWorkingChannel;
	int noiseFloorLow;
	int noiseFloorHigh;
	int noiseFloorTestValue;
	int noiseFloorOffset;
    float noiseFloorIntegrationTime;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (float) noiseFloorIntegrationTime;
- (void) setNoiseFloorIntegrationTime:(float)aNoiseFloorIntegrationTime;
- (int) fifoState;
- (void) setFifoState:(int)aFifoState;
- (int) noiseFloorOffset;
- (void) setNoiseFloorOffset:(int)aNoiseFloorOffset;
- (void) initParams;
- (void) cardInfo:(int)index setObject:(id)aValue;
- (id)   cardInfo:(int)index;
- (id)   rawCardValue:(int)index value:(id)aValue;
- (id)   convertedCardValue:(int)index;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;

#pragma mark •••specific accessors
- (void) setExternalWindow:(int)aValue;
- (void) setPileUpWindow:(int)aValue;
- (void) setNoiseWindow:(int)aValue;
- (void) setExtTrigLength:(int)aValue;
- (void) setCollectionTime:(int)aValue;
- (void) setIntegratonTime:(int)aValue;

- (int) externalWindow;
- (int) pileUpWindow;
- (int) noiseWindow;
- (int) extTrigLength;
- (int) collectionTime;
- (int) integrationTime; 

- (void) setPolarity:(short)chan withValue:(int)aValue;
- (void) setTriggerMode:(short)chan withValue:(int)aValue; 
- (void) setPileUp:(short)chan withValue:(short)aValue;		
- (void) setEnabled:(short)chan withValue:(short)aValue;		
- (void) setDebug:(short)chan withValue:(short)aValue;	
- (void) setLEDThreshold:(short)chan withValue:(int)aValue;
- (void) setCFDDelay:(short)chan withValue:(int)aValue;	
- (void) setCFDFraction:(short)chan withValue:(int)aValue;	
- (void) setCFDThreshold:(short)chan withValue:(int)aValue;
- (void) setDataDelay:(short)chan withValue:(int)aValue;   
- (void) setDataLength:(short)chan withValue:(int)aValue;  

- (int) enabled:(short)chan;		
- (int) debug:(short)chan;		
- (int) pileUp:(short)chan;		
- (int)	polarity:(short)chan;	
- (int) triggerMode:(short)chan;	
- (int) ledThreshold:(short)chan;	
- (int) cfdDelay:(short)chan;		
- (int) cfdFraction:(short)chan;	
- (int) cfdThreshold:(short)chan;	
- (int) dataDelay:(short)chan;		
- (int) dataLength:(short)chan;		

//conversion methods
- (float) cfdDelayConverted:(short)chan;
- (float) cfdThresholdConverted:(short)chan;
- (float) dataDelayConverted:(short)chan;
- (float) dataLengthConverted:(short)chan;

- (void) setCFDDelayConverted:(short)chan withValue:(float)aValue;	
- (void) setCFDThresholdConverted:(short)chan withValue:(float)aValue;
- (void) setDataDelayConverted:(short)chan withValue:(float)aValue;   
- (void) setDataLengthConverted:(short)chan withValue:(float)aValue;  

#pragma mark •••Hardware Access
- (short) readBoardID;
- (void) initBoard;
- (short) readControlReg:(int)channel;
- (void) writeControlReg:(int)channel enabled:(BOOL)enabled;
- (void) writeLEDThreshold:(int)channel;
- (void) writeCFDParameters:(int)channel;
- (void) writeRawDataSlidingLength:(int)channel;
- (void) writeRawDataWindowLength:(int)channel;
- (unsigned short) readFifoState;
- (unsigned long) readFIFO:(unsigned long)offset;
- (void) writeFIFO:(unsigned long)index value:(unsigned long)aValue;
- (int) clearFIFO;
- (void) findNoiseFloors;
- (void) stepNoiseFloor;
- (BOOL) noiseFloorRunning;

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
- (void) checkFifoAlarm;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

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

extern NSString* ORXYCom200ModelNoiseFloorIntegrationTimeChanged;
extern NSString* ORXYCom200ModelNoiseFloorOffsetChanged;

extern NSString* ORXYCom200ModelEnabledChanged;
extern NSString* ORXYCom200ModelDebugChanged;
extern NSString* ORXYCom200ModelPileUpChanged;
extern NSString* ORXYCom200ModelPolarityChanged;
extern NSString* ORXYCom200ModelTriggerModeChanged;
extern NSString* ORXYCom200ModelLEDThresholdChanged;
extern NSString* ORXYCom200ModelCFDDelayChanged;
extern NSString* ORXYCom200ModelCFDFractionChanged;
extern NSString* ORXYCom200ModelCFDThresholdChanged;
extern NSString* ORXYCom200ModelDataDelayChanged;
extern NSString* ORXYCom200ModelDataLengthChanged;

extern NSString* ORXYCom200SettingsLock;
extern NSString* ORXYCom200CardInfoUpdated;
extern NSString* ORXYCom200RateGroupChangedNotification;
extern NSString* ORXYCom200NoiseFloorChanged;
extern NSString* ORXYCom200ModelFIFOCheckChanged;
