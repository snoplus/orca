//-------------------------------------------------------------------------
//  ORGretina4Model.h
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
#import "SBC_Config.h";

@class ORRateGroup;
@class ORAlarm;

#define kNumGretina4Channels		10 
#define kNumGretina4CardParams		6
#define kGretina4HeaderLengthLongs	7

#define kGretina4FIFOEmpty			0x100000
#define kGretina4FIFOAlmostEmpty	0x400000
#define kGretina4FIFOAlmostFull		0x800000
#define kGretina4FIFOAllFull		0x1000000

#define kGretina4PacketSeparator    0xAAAAAAAA

#define kGretina4NumberWordsMask	0x7FF0000

#define kGretina4FlashMaxWordCount	0xF
#define kGretina4FlashBlockSize		( 128 * 1024 )
#define kGretina4FlashBlocks		128
#define kGretina4UsedFlashBlocks	( kGretina4FlashBlocks / 4 )
#define kGretina4FlashBufferBytes	32
#define kGretina4FlashReady			0x80
#define kGretina4FlashEnableWrite	0x10
#define kGretina4FlashDisableWrite	0x0
#define kGretina4FlashConfirmCmd	0xD0
#define kGretina4FlashWriteCmd		0xE8
#define kGretina4FlashBlockEraseCmd	0x20
#define kGretina4FlashReadArrayCmd	0xFF
#define kGretina4FlashStatusRegCmd	0x70
#define kGretina4FlashClearrSRCmd	0x50

#define kGretina4ResetMainFPGACmd	0x30
#define kGretina4ReloadMainFPGACmd	0x3
#define kGretina4MainFPGAIsLoaded	0x41


#pragma mark ¥¥¥Register Definitions
enum {
	kBoardID,					//[0] board ID
    kProgrammingDone,			//[1] Programming done
    kExternalWindow,			//[2] External Window
    kPileupWindow,				//[3] Pileup Window
    kNoiseWindow,				//[4] Noise Window
    kExtTriggerSlidingLength,	//[5] Extrn trigger sliding length
    kCollectionTime,			//[6] Collection time
    kIntegrationTime,			//[7] Integration time
    kHardwareStatus,			//[8] Hardware Status
    kControlStatus,				//[9] Control Status
    kLEDThreshold,				//[10] LED Threshold
    kCFDParameters,				//[11] CFD Parameters
    kRawDataSlidingLength,		//[12] Raw data sliding length
    kRawDataWindowLength,		//[13] Raw data window length
    kDAC,						//[14] DAC
	kSlaveFrontBusStatus,		//[15] Slave Front bus status
    kChanZeroTimeStampLSB,		//[16] Channel Zero time stamp LSB
    kChanZeroTimeStampMSB,		//[17] Channel Zero time stamp MSB
    kSlaveFrontBusSendBox18_1,  //[18] Slave Front Bus Send Box 18 - 1
    kSlaveFrontBusRegister0_10, //[19] Slave Front bus register 0 - 10
    kMasterLogicStatus,			//[20] Master Logic Status
    kSlowDataCCLEDTimers,		//[21] SlowData CCLED timers
    kDeltaT155_DeltaT255,		//[22] DeltaT155_DeltaT255 (3)
    kSnapShot,					//[23] SnapShot 
    kXtalID,					//[24] XTAL ID 
    kHitPatternTimeOut,			//[25] Length of Time to get Hit Pattern 
    kFrontSideBusRegister,		//[26] Front Side Bus Register
    kFrontBusRegisters0_10,		//[27] FrontBus Registers 0-10
	kDebugDataBufferAddress,	//[28] Debug data buffer address
	kDebugDataBufferData,		//[29] Debug data buffer data
	kLEDFlagWindow,				//[30] LED flag window
	kAuxIORead,					//[31] Aux io read
	kAuxIOWrite,				//[32] Aux io write
	kAuxIOConfig,				//[33] Aux io config
	kFBRead,					//[34] FB_Read
	kFBWrite,					//[35] FB_Write
	kFBConfig,					//[36] FB_Config
	kSDRead,					//[37] SD_Read
	kSDWrite,					//[38] SD_Write
	kSDConfig,					//[39] SD_Config; This has a number of important set/reset bits
	kADCConfig,					//[40] Adc config
	kSelfTriggerEnable,			//[41] self trigger enable
	kSelfTriggerPeriod,			//[42] self trigger period
	kSelfTriggerCount,			//[43] self trigger count
	kNumberOfGretina4Registers	//must be last
};

enum {
	kMainFPGAControl,			//[0] Main Digitizer FPGA configuration register
	kMainFPGAStatus,			//[1] Main Digitizer FPGA status register
	kVoltageAndTemperature,		//[2] Voltage and Temperature Status
	kVMEGPControl,				//[3] General Purpose VME Control Settings
	kVMETimeoutValue,			//[4] VME Timeout Value Register
	kVMEFPGAVersionStatus,		//[5] VME Version/Status
	kVMEFPGASandbox,			//[6] VME FPGA Sandbox Register Block
	kFlashAddress,				//[7] Flash Address
	kFlashDataWithAddrIncr,		//[8] Flash Data with Auto-increment address
	kFlashData,					//[9] Flash Data
	kFlashCommandRegister,		//[10] Flash Command Register
	kNumberOfFPGARegisters
};

enum Gretina4FIFOStates {
	kEmpty,
	kAlmostEmpty,	
	kAlmostFull,
	kFull,
	kHalfFull
};

@interface ORGretina4Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping>
{
  @private
	unsigned long   dataId;
	unsigned long*  dataBuffer;

	NSMutableArray* cardInfo;
    short			enabled[kNumGretina4Channels];
    short			debug[kNumGretina4Channels];
    short			pileUp[kNumGretina4Channels];
    short			polarity[kNumGretina4Channels];
    short			triggerMode[kNumGretina4Channels];
    unsigned long   ledThreshold[kNumGretina4Channels];
    short			cfdDelay[kNumGretina4Channels];
    short			cfdThreshold[kNumGretina4Channels];
    short			cfdFraction[kNumGretina4Channels];
    short           dataDelay[kNumGretina4Channels];
    short           dataLength[kNumGretina4Channels];
    short           cfdEnabled[kNumGretina4Channels];
    short           poleZeroEnabled[kNumGretina4Channels];
	
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumGretina4Channels];
	BOOL			isRunning;

    int fifoState;
	ORAlarm*        fifoFullAlarm;
	int				fifoEmptyCount;
    int             fifoLostEvents;

	//cache to speed takedata
	unsigned long location;
	id theController;
	unsigned long fifoAddress;
	unsigned long fifoStateAddress;

	BOOL oldEnabled[kNumGretina4Channels];
	unsigned long oldLEDThreshold[kNumGretina4Channels];
	unsigned long newLEDThreshold[kNumGretina4Channels];
	BOOL noiseFloorRunning;
	int noiseFloorState;
	int noiseFloorWorkingChannel;
	int noiseFloorLow;
	int noiseFloorHigh;
	int noiseFloorTestValue;
	int noiseFloorOffset;
    float noiseFloorIntegrationTime;
	
    NSString* mainFPGADownLoadState;
	BOOL isFlashWriteEnabled;
    NSString* fpgaFilePath;
	BOOL stopDownLoadingMainFPGA;
	BOOL downLoadMainFPGAInProgress;
    int fpgaDownProgress;
	NSLock* progressLock;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (BOOL) downLoadMainFPGAInProgress;
- (void) setDownLoadMainFPGAInProgress:(BOOL)aState;
- (int) fpgaDownProgress;
- (NSString*) mainFPGADownLoadState;
- (void) setMainFPGADownLoadState:(NSString*)aMainFPGADownLoadState;
- (NSString*) fpgaFilePath;
- (void) setFpgaFilePath:(NSString*)aFpgaFilePath;
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
- (const char*) registerNameAt:(unsigned int)index;
- (const char*) fpgaRegisterNameAt:(unsigned int)index;
- (unsigned long) readRegister:(unsigned int)index;
- (void) writeRegister:(unsigned int)index withValue:(unsigned long)value;
- (unsigned long) readFPGARegister:(unsigned int)index;
- (void) writeFPGARegister:(unsigned int)index withValue:(unsigned long)value;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;

#pragma mark ¥¥¥specific accessors
- (void) setExternalWindow:(int)aValue;
- (void) setPileUpWindow:(int)aValue;
- (void) setNoiseWindow:(int)aValue;
- (void) setExtTrigLength:(int)aValue;
- (void) setCollectionTime:(int)aValue;
- (void) setIntegrationTime:(int)aValue;

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
- (void) setCFDEnabled:(short)chan withValue:(short)aValue;
- (void) setPoleZeroEnabled:(short)chan withValue:(short)aValue;		
- (void) setDebug:(short)chan withValue:(short)aValue;	
- (void) setLEDThreshold:(short)chan withValue:(int)aValue;
- (void) setCFDDelay:(short)chan withValue:(int)aValue;	
- (void) setCFDFraction:(short)chan withValue:(int)aValue;	
- (void) setCFDThreshold:(short)chan withValue:(int)aValue;
- (void) setDataDelay:(short)chan withValue:(int)aValue;
// Data Length refers to total length of the record (w/ header), trace length refers to length of trace
- (void) setDataLength:(short)chan withValue:(int)aValue;  
- (void) setTraceLength:(short)chan withValue:(int)aValue;  

- (int) enabled:(short)chan;
- (int) poleZeroEnabled:(short)chan;
- (int) cfdEnabled:(short)chan;		
- (int) debug:(short)chan;		
- (int) pileUp:(short)chan;		
- (int)	polarity:(short)chan;	
- (int) triggerMode:(short)chan;	
- (int) ledThreshold:(short)chan;	
- (int) cfdDelay:(short)chan;		
- (int) cfdFraction:(short)chan;	
- (int) cfdThreshold:(short)chan;	
- (int) dataDelay:(short)chan;		
// Data Length refers to total length of the record (w/ header), trace length refers to length of trace
- (int) dataLength:(short)chan;
- (int) traceLength:(short)chan;

//conversion methods
- (float) cfdDelayConverted:(short)chan;
- (float) cfdThresholdConverted:(short)chan;
- (float) dataDelayConverted:(short)chan;
- (float) traceLengthConverted:(short)chan;

- (void) setCFDDelayConverted:(short)chan withValue:(float)aValue;	
- (void) setCFDThresholdConverted:(short)chan withValue:(float)aValue;
// Data Length refers to total length of the record (w/ header), trace length refers to length of trace
- (void) setDataDelayConverted:(short)chan withValue:(float)aValue;   
- (void) setTraceLengthConverted:(short)chan withValue:(float)aValue;  

#pragma mark ¥¥¥Hardware Access
- (short) readBoardID;
- (void) resetBoard;
- (void) resetDCM;
- (void) initBoard;
- (void) initSerDes;
- (unsigned long) readControlReg:(int)channel;
- (void) writeControlReg:(int)channel enabled:(BOOL)enabled;
- (void) writeLEDThreshold:(int)channel;
- (void) writeCFDParameters:(int)channel;
- (void) writeRawDataSlidingLength:(int)channel;
- (void) writeRawDataWindowLength:(int)channel;
- (unsigned short) readFifoState;
- (int) clearFIFO;
- (int) findNextEventInTheFIFO;
- (void) findNoiseFloors;
- (void) stepNoiseFloor;
- (BOOL) noiseFloorRunning;

#pragma mark ¥¥¥FPGA download
- (void) startDownLoadingMainFPGA;
- (void) stopDownLoadingMainFPGA;

#pragma mark ¥¥¥Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (unsigned long) waveFormCount:(int)aChannel;
- (void)   startRates;
- (void) clearWaveFormCounts;
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag;
- (void) checkFifoAlarm;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (BOOL) bumpRateFromDecodeStage:(short)channel;


#pragma mark ¥¥¥HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(short*)anArray forKey:(NSString*)aKey;
@end

extern NSString* ORGretina4ModelMainFPGADownLoadInProgressChanged;
extern NSString* ORGretina4ModelFpgaDownProgressChanged;
extern NSString* ORGretina4ModelMainFPGADownLoadStateChanged;
extern NSString* ORGretina4ModelFpgaFilePathChanged;
extern NSString* ORGretina4ModelNoiseFloorIntegrationTimeChanged;
extern NSString* ORGretina4ModelNoiseFloorOffsetChanged;

extern NSString* ORGretina4ModelEnabledChanged;
extern NSString* ORGretina4ModelDebugChanged;
extern NSString* ORGretina4ModelPileUpChanged;
extern NSString* ORGretina4ModelCFDEnabledChanged;
extern NSString* ORGretina4ModelPoleZeroEnabledChanged;
extern NSString* ORGretina4ModelPolarityChanged;
extern NSString* ORGretina4ModelTriggerModeChanged;
extern NSString* ORGretina4ModelLEDThresholdChanged;
extern NSString* ORGretina4ModelCFDDelayChanged;
extern NSString* ORGretina4ModelCFDFractionChanged;
extern NSString* ORGretina4ModelCFDThresholdChanged;
extern NSString* ORGretina4ModelDataDelayChanged;
extern NSString* ORGretina4ModelDataLengthChanged;

extern NSString* ORGretina4SettingsLock;
extern NSString* ORGretina4CardInfoUpdated;
extern NSString* ORGretina4RateGroupChangedNotification;
extern NSString* ORGretina4NoiseFloorChanged;
extern NSString* ORGretina4ModelFIFOCheckChanged;
extern NSString* ORGretina4CardInited;
