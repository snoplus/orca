//
//  ORDT5725Model.h
//  Orca
//
//  Created by Mark Howe on Wed Jun 29,2016.
//  Copyright (c) 2016 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina at the Center sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files

#import "ORUsbDeviceModel.h"
#import "ORUSB.h"
#import "ORDataTaker.h"

@class ORUSBInterface;
@class ORAlarm;
@class ORDataSet;
@class ORRateGroup;
@class ORSafeCircularBuffer;

enum {
	kZS_Thres,				//0x1024
	kZS_NsAmp,				//0x1028
    kThresholds,			//0x1080
    kNumOUThreshold,		//0x1084
    kStatus,				//0x1088
    kFirmwareVersion,		//0x108C
    kBufferOccupancy,		//0x1094
    kDacs,					//0x1098
    kAdcConfig,				//0x109C
    kChanConfig,			//0x8000
    kChanConfigBitSet,		//0x8004
    kChanConfigBitClr,		//0x8008
    kBufferOrganization,	//0x800C
    kAcqControl,			//0x8100
    kAcqStatus,				//0x8104
    kSWTrigger,				//0x8108
    kTrigSrcEnblMask,		//0x810C
    kFPTrigOutEnblMask,		//0x8110
    kPostTrigSetting,		//0x8114
    kFPIOControl,			//0x811C
    kChanEnableMask,		//0x8120
    kROCFPGAVersion,		//0x8124
    kEventStored,			//0x812C
    kBoardInfo,				//0x8140
    kEventSize,				//0x814C
    kVMEControl,			//0xEF00
    kVMEStatus,				//0xEF04
    kInterruptStatusID,		//0xEF14
    kInterruptEventNum,		//0xEF18
    kBLTEventNum,			//0xEF1C
    kScratch,				//0xEF20
    kSWReset,				//0xEF24
    kSWClear,				//0xEF28
    kConfigReload,			//0xEF34
    kConfigROMVersion,      //0xF030
    kConfigROMBoard2,       //0xF034
	kNumberDT5725Registers  //must be last
};

typedef struct  {
	NSString*       regName;
    unsigned long 	addressOffset;
    short			accessType;
    bool			hwReset;
    bool			softwareReset;
	bool			dataReset;
} DT5725RegisterNamesStruct;


enum {
    kNoZeroSuppression ,
    kZeroLengthEncoding,
    kFullSuppressionBasedOnAmplitude
};

#define kDT5725BufferEmpty 0
#define kDT5725BufferReady 1
#define kDT5725BufferFull  3

typedef struct  {
	NSString*       regName;
	unsigned long 	addressOffset;
	short			accessType;
    unsigned short  numBits;
} DT5725ControllerRegisterNamesStruct;


// Size of output buffer
#define kEventBufferSize 0x0FFC

#define kReadOnly 0
#define kWriteOnly 1
#define kReadWrite 2

#define kNumDT5725Channels 8

@interface ORDT5725Model : ORUsbDeviceModel <USBDevice,ORDataTaker> {
	ORUSBInterface* usbInterface;
 	ORAlarm*		noUSBAlarm;
    NSString*		serialNumber;
	unsigned long   dataId;
    unsigned short  zsThresholds[kNumDT5725Channels];
    unsigned short	numOverUnderZsThreshold[kNumDT5725Channels];
    unsigned short  thresholds[kNumDT5725Channels];
    unsigned short  nLbk[kNumDT5725Channels];
    unsigned short  nLfwd[kNumDT5725Channels];
    int             logicType[kNumDT5725Channels];
    int             zsAlgorithm;
    BOOL            packed;
    BOOL            trigOverlapEnabled;
    BOOL            testPatternEnabled;
    BOOL            trigOnUnderThreshold;
    BOOL            packEnabled;
    BOOL            clockSource;
    BOOL            gpiRunMode;
    BOOL            softwareTrigEnabled;
    BOOL            externalTrigEnabled;
    BOOL            fpExternalTrigEnabled;
    BOOL            fpSoftwareTrigEnabled;
    BOOL            gpoEnabled;
    int             ttlEnabled;
    unsigned long   triggerSourceMask;

    
	unsigned short	dac[kNumDT5725Channels];
	unsigned short	numOverUnderThreshold[kNumDT5725Channels];
    BOOL			countAllTriggers;
    unsigned short  coincidenceLevel;
	unsigned long   triggerOutMask;
    unsigned long	postTriggerSetting;
    unsigned short	enabledMask;
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumDT5725Channels];
    int				bufferState;
    int				lastBufferState;
	ORAlarm*        bufferFullAlarm;
	int				bufferEmptyCount;
    int				eventSize;
    
    unsigned short  selectedRegIndex;
    unsigned short  selectedChannel;
    unsigned long   selectedRegValue;

	//data taking, some are cached and only valid during running
	unsigned int    statusReg;
	unsigned long   location;
	unsigned long	eventSizeReg;
	unsigned long	dataReg;
    unsigned long   totalBytesTransfered;
    float           totalByteRate;
    NSDate*         lastTimeByteTotalChecked;
    BOOL            firstTime;
    BOOL            isRunning;
    BOOL            isDataWorkerRunning;
    BOOL            isTimeToStopDataWorker;
    ORSafeCircularBuffer* circularBuffer;
    NSMutableData*  eventData;
    BOOL            cachedPack;
}

@property (assign) BOOL isDataWorkerRunning;
@property (assign) BOOL isTimeToStopDataWorker;

#pragma mark ***USB
- (id)              getUSBController;
- (ORUSBInterface*) usbInterface;
- (void)            setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*)       serialNumber;
- (void)            setSerialNumber:(NSString*)aSerialNumber;
- (unsigned long)   vendorID;
- (unsigned long)   productID;
- (NSString*)       usbInterfaceDescription;
- (void)            interfaceAdded:(NSNotification*)aNote;
- (void)            interfaceRemoved:(NSNotification*)aNote;
- (void)            checkUSBAlarm;

#pragma mark Accessors
//------------------------------
- (int)             logicType:(unsigned short) i;
- (void)            setLogicType:(unsigned short) i withValue:(int)aLogicType;
- (unsigned short)	zsThreshold:(unsigned short) i;
- (void)			setZsThreshold:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (unsigned short)	numOverUnderZsThreshold:(unsigned short) i;
- (void)			setNumOverUnderZsThreshold:(unsigned short) i withValue:(unsigned short) aValue;
- (unsigned short)	nLbk:(unsigned short) i;
- (void)			setNlbk:(unsigned short) i withValue:(unsigned short) aValue;
- (unsigned short)	nLfwd:(unsigned short) i;
- (void)			setNlfwd:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (unsigned short)	threshold:(unsigned short) i;
- (void)			setThreshold:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (unsigned short)	numOverUnderThreshold:(unsigned short) i;
- (void)			setNumOverUnderThreshold:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (unsigned short)	dac:(unsigned short) i;
- (void)			setDac:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (int)             zsAlgorithm;
- (void)            setZsAlgorithm:(int)aZsAlgorithm;
- (BOOL)            packed;
- (void)            setPacked:(BOOL)aPacked;
- (BOOL)            trigOnUnderThreshold;
- (void)            setTrigOnUnderThreshold:(BOOL)aTrigOnUnderThreshold;
- (BOOL)            testPatternEnabled;
- (void)            setTestPatternEnabled:(BOOL)aTestPatternEnabled;
- (BOOL)            trigOverlapEnabled;
- (void)            setTrigOverlapEnabled:(BOOL)aTrigOverlapEnabled;
//------------------------------
- (int)				eventSize;
- (void)			setEventSize:(int)aEventSize;
//------------------------------
- (BOOL)            clockSource;
- (void)            setClockSource:(BOOL)aClockSource;
- (BOOL)			countAllTriggers;
- (void)			setCountAllTriggers:(BOOL)aCountAllTriggers;
- (BOOL)            gpiRunMode;
- (void)            setGpiRunMode:(BOOL)aGpiRunMode;
//------------------------------
- (BOOL)            softwareTrigEnabled;
- (void)            setSoftwareTrigEnabled:(BOOL)aSoftwareTrigEnabled;
- (BOOL)            externalTrigEnabled;
- (void)            setExternalTrigEnabled:(BOOL)aExternalTrigEnabled;
- (unsigned short)	coincidenceLevel;
- (void)			setCoincidenceLevel:(unsigned short)aCoincidenceLevel;
- (unsigned long)	triggerSourceMask;
- (void)			setTriggerSourceMask:(unsigned long)aTriggerSourceMask;
//------------------------------
- (BOOL)            fpSoftwareTrigEnabled;
- (void)            setFpSoftwareTrigEnabled:(BOOL)aFpSoftwareTrigEnabled;
- (BOOL)            fpExternalTrigEnabled;
- (void)            setFpExternalTrigEnabled:(BOOL)aFpExternalTrigEnabled;
- (unsigned long)	triggerOutMask;
- (void)			setTriggerOutMask:(unsigned long)aTriggerOutMask;
//------------------------------
- (BOOL)            gpoEnabled;
- (void)            setGpoEnabled:(BOOL)aGpoEnabled;
- (int)             ttlEnabled;
- (void)            setTtlEnabled:(int)aTtlEnabled;
//------------------------------
- (unsigned long)	postTriggerSetting;
- (void)			setPostTriggerSetting:(unsigned long)aPostTriggerSetting;
//------------------------------
- (unsigned short)	enabledMask;
- (void)			setEnabledMask:(unsigned short)aEnabledMask;
//------------------------------

- (int)				bufferState;

//------------------------------
//rate related
- (void)			clearWaveFormCounts;
- (void)			setRateIntegrationTime:(double)newIntegrationTime;
- (id)				rateObject:(int)channel;
- (ORRateGroup*)	waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;

#pragma mark ***Register - General routines
- (void)			read;
- (void)			write;
- (void)			report;
- (void)			read:(unsigned short) pReg returnValue:(unsigned long*) pValue;
- (void)			write:(unsigned short) pReg sendValue:(unsigned long) pValue;
- (short)			getNumberRegisters;


#pragma mark ***HW Init
- (void)			initBoard;

- (void)            writeZSThresholds;
- (void)            writeZSThreshold:(unsigned short) i;
- (void)            writeZSAmplReg;
- (void)            writeZSAmplReg:(unsigned short) i;
- (void)			writeThresholds;
- (void)			writeThreshold:(unsigned short) pChan;
- (void)            writeNumOverUnderThresholds;
- (void)            writeNumOverUnderThreshold:(unsigned short) i;
- (void)			writeDacs;
- (void)			writeDac:(unsigned short) pChan;
- (void)			writeChannelConfiguration;
- (void)			writeBufferOrganization;
- (void)			writeAcquistionControl:(BOOL)start;
- (void)            trigger;
- (void)            writeTriggerSourceEnableMask;
- (void)            writeFrontPanelIOControl;
- (void)            writeFrontPanelTriggerOutEnableMask;
- (void)			writePostTriggerSetting;
- (void)			writeChannelEnabledMask;
- (void)			writeNumBLTEventsToReadout;
- (void)			softwareReset;
- (void)			clearAllMemory;
- (void)			checkBufferAlarm;

- (void)            readConfigurationROM;

#pragma mark ***Register - Register specific routines
- (unsigned short) 	selectedChannel;
- (void)			setSelectedChannel: (unsigned short) anIndex;
- (unsigned long) 	selectedRegValue;
- (void)			setSelectedRegValue: (unsigned long) anIndex;
- (unsigned short)  selectedRegIndex;
- (void)            setSelectedRegIndex:(unsigned short) anIndex;
- (NSString*) 		getRegisterName: (short) anIndex;
- (unsigned long) 	getAddressOffset: (short) anIndex;
- (short)			getAccessType: (short) anIndex;
- (BOOL)			dataReset: (short) anIndex;
- (BOOL)			swReset: (short) anIndex;
- (BOOL)			hwReset: (short) anIndex;

#pragma mark •••DataTaker
- (unsigned long)	dataId;
- (void)			setDataId: (unsigned long) DataId;
- (void)			setDataIds:(id)assigner;
- (void)			syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*)	dataRecordDescription;
- (void)			runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(id)userInfo;
- (void)			takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void)			runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(id)userInfo;
- (BOOL)            bumpRateFromDecodeStage:(short)channel;
- (float)           totalByteRate;

#pragma mark ***Helpers
- (float)			convertDacToVolts:(unsigned short)aDacValue;
- (unsigned short)	convertVoltsToDac:(float)aVoltage;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(long*)anArray forKey:(NSString*)aKey;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***HW Read/Write API
- (int)     writeLongBlock:(unsigned long*) writeValue atAddress:(unsigned int) vmeAddress;
- (int)     readLongBlock:(unsigned long*)  readValue atAddress:(unsigned int) vmeAddress;
- (void)    writeChan:(unsigned short)chan reg:(unsigned short) pReg sendValue:(unsigned long) pValue;
- (void)    readChan:(unsigned short)chan reg:(unsigned short) pReg returnValue:(unsigned long*) pValue;
- (int) readFifo:(char*)destBuff numBytesToRead:(unsigned long)    numBytes;


@end

extern NSString* ORDT5725BasicLock;
extern NSString* ORDT5725LowLevelLock;
extern NSString* ORDT5725ModelUSBInterfaceChanged;
extern NSString* ORDT5725ModelSerialNumberChanged;

extern NSString* ORDT5725ModelLogicTypeChanged;
extern NSString* ORDT5725ZsThresholdChanged;
extern NSString* ORDT5725NumOverUnderZsThresholdChanged;
extern NSString* ORDT5725NlbkChanged;
extern NSString* ORDT5725NlfwdChanged;
extern NSString* ORDT5725ThresholdChanged;
extern NSString* ORDT5725NumOverUnderThresholdChanged;
extern NSString* ORDT5725DacChanged;
extern NSString* ORDT5725ModelZsAlgorithmChanged;
extern NSString* ORDT5725ModelPackedChanged;
extern NSString* ORDT5725ModelTrigOnUnderThresholdChanged;
extern NSString* ORDT5725ModelTestPatternEnabledChanged;
extern NSString* ORDT5725ModelTrigOverlapEnabledChanged;
extern NSString* ORDT5725ModelEventSizeChanged;
extern NSString* ORDT5725ModelClockSourceChanged;
extern NSString* ORDT5725ModelCountAllTriggersChanged;
extern NSString* ORDT5725ModelGpiRunModeChanged;
extern NSString* ORDT5725ModelTriggerSourceMaskChanged;
extern NSString* ORDT5725ModelExternalTrigEnabledChanged;
extern NSString* ORDT5725ModelSoftwareTrigEnabledChanged;
extern NSString* ORDT5725ModelCoincidenceLevelChanged;
extern NSString* ORDT5725ModelEnabledMaskChanged;
extern NSString* ORDT5725ModelFpSoftwareTrigEnabledChanged;
extern NSString* ORDT5725ModelFpExternalTrigEnabledChanged;
extern NSString* ORDT5725ModelTriggerOutMaskChanged;
extern NSString* ORDT5725ModelPostTriggerSettingChanged;
extern NSString* ORDT5725ModelGpoEnabledChanged;
extern NSString* ORDT5725ModelTtlEnabledChanged;



extern NSString* ORDT5725Chnl;
extern NSString* ORDT5725SelectedRegIndexChanged;
extern NSString* ORDT5725SelectedChannelChanged;
extern NSString* ORDT5725WriteValueChanged;

extern NSString* ORDT5725SelectedRegIndexChanged;
extern NSString* ORDT5725SelectedRegIndexChanged;
extern NSString* ORDT5725SelectedChannelChanged;
extern NSString* ORDT5725WriteValueChanged;

extern NSString* ORDT5725RateGroupChanged;
extern NSString* ORDT5725ModelBufferCheckChanged;

