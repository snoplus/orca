//
//  ORDT5720Model.h
//  Orca
//
//  Created by Mark Howe on Wed Mar 12,2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
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

enum {
	kOutputBuffer,			//0x0000
	kZS_Thres,				//0x1024
	kZS_NsAmp,				//0x1028
	kThresholds,			//0x1084
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
	kBufferFree,			//0x8010
	kCustomSize,			//0x8020
	kAcqControl,			//0x8100
	kAcqStatus,				//0x8104
	kSWTrigger,				//0x8108
	kTrigSrcEnblMask,		//0x810C
	kFPTrigOutEnblMask,		//0x8110
	kPostTrigSetting,		//0x8114
	kFPIOData,				//0x8118
	kFPIOControl,			//0x811C
	kChanEnableMask,		//0x8120
	kROCFPGAVersion,		//0x8124
	kEventStored,			//0x812C
	kSetMonitorDAC,			//0x8138
	kBoardInfo,				//0x8140
	kMonitorMode,			//0x8144
	kEventSize,				//0x814C
	kVMEControl,			//0xEF00
	kVMEStatus,				//0xEF04
	kBoardID,				//0xEF08
	kMultCastBaseAdd,		//0xEF0C
	kRelocationAdd,			//0xEF10
	kInterruptStatusID,		//0xEF14
	kInterruptEventNum,		//0xEF18
	kBLTEventNum,			//0xEF1C
	kScratch,				//0xEF20
	kSWReset,				//0xEF24
	kSWClear,				//0xEF28
	//kFlashEnable,			//0xEF2C
	//kFlashData,			//0xEF30
	//kConfigReload,		//0xEF34
	kConfigROMCheckSum,		//0xF000
	kConfigROMCheckSumLen2,	//0xF004
	kConfigROMCheckSumLen1,	//0xF008
	kConfigROMCheckSumLen0,	//0xF00C
	kConfigROMVersion,		//0xF030
	kConfigROMBoard2,		//0xF034
	kConfigROMBoard1,		//0xF038
	kConfigROMBoard0,		//0xF03C
	kConfigROMSerNum1,		//0xF080
	kConfigROMSerNum0,		//0xF084
	kConfigROMVCXOType,		//0xF088
	kNumberDT5720Registers
};

typedef struct  {
	NSString*       regName;
	bool			dataReset;
	bool			softwareReset;
	bool			hwReset;
	unsigned long 	addressOffset;
	short			accessType;
} DT5720RegisterNamesStruct;

// DT5720 includes SW implemenation of V1718
// V1718 registers follow
enum {
    kCtrlStatus,    //0x00
    kCtrlCtrl,      //0x01
    kCtrlFwRev,     //0x02
    kCtrlFwDwnld,   //0x03
    kCtrlFlEna,     //0x04
    kCtrlIrqStat,   //0x05
    kCtrlInReg,     //0x08
    kCtrlOutRegS,   //0x0A
    //the rest is probably not relevant
	kNumberDT5720ControllerRegisters
};

typedef struct  {
	NSString*       regName;
	unsigned long 	addressOffset;
	short			accessType;
    unsigned short  numBits;
} DT5720ControllerRegisterNamesStruct;


// Size of output buffer
#define kEventBufferSize 0x0FFC

#define kReadOnly 0
#define kWriteOnly 1
#define kReadWrite 2

#define kNumDT5720Channels 4

@interface ORDT5720Model : ORUsbDeviceModel <USBDevice,ORDataTaker> {
	ORUSBInterface* usbInterface;
 	ORAlarm*		noUSBAlarm;
    NSString*		serialNumber;
	unsigned long   dataId;
	unsigned short  selectedRegIndex;
    unsigned short  selectedChannel;
    unsigned long   selectedRegValue;
	unsigned short  thresholds[kNumDT5720Channels];
	unsigned short	dac[kNumDT5720Channels];
	unsigned short	overUnderThreshold[kNumDT5720Channels];
    unsigned short	channelConfigMask;
    unsigned long	customSize;
	BOOL            isCustomSize;
	BOOL            isFixedSize;
    BOOL			countAllTriggers;
    unsigned short	acquisitionMode;
    unsigned short  coincidenceLevel;
    unsigned long   triggerSourceMask;
	unsigned long   triggerOutMask;
	unsigned long   frontPanelControlMask;
    unsigned long	postTriggerSetting;
    unsigned short	enabledMask;
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumDT5720Channels];
    int				bufferState;
	ORAlarm*        bufferFullAlarm;
	int				bufferEmptyCount;
	BOOL			isRunning;
    int				eventSize;
    unsigned long   numberBLTEventsToReadout;
    BOOL            continuousMode;
    
    unsigned long   _vmeRegValue;
    unsigned int   _vmeRegIndex;
    NSArray*        _vmeRegArray;
    BOOL            _isNeedToSwap; //DT5720 talks little endian
    BOOL            _isVMEFIFOMode;
    
	//cached variables, valid only during running
	unsigned int    statusReg;
	unsigned long   location;
	unsigned long	eventSizeReg;
	unsigned long	dataReg;

    BOOL _isDataWorkerRunning;
    BOOL _isTimeToStopDataWorker;
    NSMutableArray* _dataArray;
}

@property (nonatomic, assign) unsigned long vmeRegValue;
@property (nonatomic, assign) unsigned int vmeRegIndex;
@property (nonatomic, assign) BOOL isNeedToSwap;
@property (nonatomic, copy) NSArray* vmeRegArray;
@property (nonatomic, assign) BOOL isVMEFIFOMode;
@property (assign) BOOL isDataWorkerRunning;
@property (assign) BOOL isTimeToStopDataWorker;
@property (nonatomic, assign) NSMutableArray* dataArray;

#pragma mark ***Accessors
- (id) getUSBController;
- (ORUSBInterface*) usbInterface;
- (void) setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;
- (unsigned long) vendorID;
- (unsigned long) productID;
- (NSString*) usbInterfaceDescription;
- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;

#pragma mark ***Comm methods
- (void) checkUSBAlarm;

- (BOOL)            continuousMode;
- (void)            setContinuousMode:(BOOL)aContinuousMode;
- (int)				eventSize;
- (void)			setEventSize:(int)aEventSize;
- (int)				bufferState;
- (void)			clearWaveFormCounts;
- (void)			setRateIntegrationTime:(double)newIntegrationTime;
- (id)				rateObject:(int)channel;
- (ORRateGroup*)	waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (unsigned short) 	selectedRegIndex;
- (void)			setSelectedRegIndex: (unsigned short) anIndex;
- (unsigned short) 	selectedChannel;
- (void)			setSelectedChannel: (unsigned short) anIndex;
- (unsigned long) 	selectedRegValue;
- (void)			setSelectedRegValue: (unsigned long) anIndex;
- (unsigned short)	enabledMask;
- (void)			setEnabledMask:(unsigned short)aEnabledMask;
- (unsigned long)	postTriggerSetting;
- (void)			setPostTriggerSetting:(unsigned long)aPostTriggerSetting;
- (unsigned long)	triggerSourceMask;
- (void)			setTriggerSourceMask:(unsigned long)aTriggerSourceMask;
- (unsigned long)	triggerOutMask;
- (void)			setTriggerOutMask:(unsigned long)aTriggerOutMask;
- (unsigned long)	frontPanelControlMask;
- (void)			setFrontPanelControlMask:(unsigned long)aFrontPanelControlMask;
- (unsigned short)	coincidenceLevel;
- (void)			setCoincidenceLevel:(unsigned short)aCoincidenceLevel;
- (unsigned short)	acquisitionMode;
- (void)			setAcquisitionMode:(unsigned short)aMode;
- (BOOL)			countAllTriggers;
- (void)			setCountAllTriggers:(BOOL)aCountAllTriggers;
- (BOOL)		isCustomSize;
- (void)		setIsCustomSize:(BOOL)aIsCustomSize;
- (BOOL)		isFixedSize;
- (void)		setIsFixedSize:(BOOL)aIsFixedSize;
- (unsigned long)	customSize;
- (void)			setCustomSize:(unsigned long)aCustomSize;
- (unsigned short)	channelConfigMask;
- (void)			setChannelConfigMask:(unsigned short)aChannelConfigMask;
- (unsigned short)	dac:(unsigned short) aChnl;
- (void)			setDac:(unsigned short) aChnl withValue:(unsigned short) aValue;
- (unsigned short)	overUnderThreshold:(unsigned short) aChnl;
- (void)			setOverUnderThreshold:(unsigned short) aChnl withValue:(unsigned short) aValue;
- (unsigned long)	numberBLTEventsToReadout;
- (void)			setNumberBLTEventsToReadout:(unsigned long)aNumberOfBLTEvents;

#pragma mark ***Register - General routines
- (int)     readVmeCtrlRegister:(unsigned short) address toValue:(unsigned short*) value;
- (void)    readVmeCtrlRegister;
- (int)     writeVmeCtrlRegister:(unsigned short) address value:(unsigned short) value;
- (void)    writeVmeCtrlRegister;
- (void)			read;
- (void)			write;
- (void)			report;
- (void)			read:(unsigned short) pReg returnValue:(unsigned long*) pValue;
- (void)			write:(unsigned short) pReg sendValue:(unsigned long) pValue;
- (short)			getNumberRegisters;
- (void)			generateSoftwareTrigger;
- (void)			softwareReset;
- (void)			clearAllMemory;
- (void)			checkBufferAlarm;


#pragma mark ***HW Init
- (void)			initBoard;
- (void)			initEmbeddedVMEController;
- (void)            readConfigurationROM;
- (void)			writeChannelConfiguration;
- (void)			writeCustomSize;
- (void)			writeAcquistionControl:(BOOL)start;
- (void)			writeTriggerSource;
- (void)			writeTriggerOut;
- (void)			writeFrontPanelControl;
- (void)			readFrontPanelControl;
- (void)			writePostTriggerSetting;
- (void)			writeChannelEnabledMask;
- (void)            writeNumberBLTEvents:(BOOL)enable;
- (void)            writeEnableBerr:(BOOL)enable;
- (void)			writeOverUnderThresholds;

#pragma mark ***Register - Register specific routines
- (unsigned short) selectedRegIndex;
- (void) setSelectedRegIndex:(unsigned short) anIndex;
- (NSString*) 		getRegisterName: (short) anIndex;
- (unsigned long) 	getAddressOffset: (short) anIndex;
- (short)			getAccessType: (short) anIndex;
- (BOOL)			dataReset: (short) anIndex;
- (BOOL)			swReset: (short) anIndex;
- (BOOL)			hwReset: (short) anIndex;
- (void)			writeThresholds;
- (unsigned short)	threshold:(unsigned short) aChnl;
- (void)			setThreshold:(unsigned short) aChnl withValue:(unsigned long) aValue;
- (void)			writeChan:(unsigned short)chan reg:(unsigned short) pReg sendValue:(unsigned long) pValue;
- (void)			readChan:(unsigned short)chan reg:(unsigned short) pReg returnValue:(unsigned long*) pValue;
- (void)			writeDacs;
- (void)			writeDac:(unsigned short) pChan;
- (float)			convertDacToVolts:(unsigned short)aDacValue;
- (unsigned short)	convertVoltsToDac:(float)aVoltage;
- (void)			writeThreshold:(unsigned short) pChan;
- (void)			readOverUnderThresholds;
- (void)			writeBufferOrganization;

#pragma mark •••DataTaker
- (unsigned long)	dataId;
- (void)			setDataId: (unsigned long) DataId;
- (void)			setDataIds:(id)assigner;
- (void)			syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*)	dataRecordDescription;
- (void)			runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(id)userInfo;
- (void)			takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void)			runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(id)userInfo;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***HW Read/Write API
- (void) setEndianness;
- (void) fillVmeRegArray;
- (id) adapter;
- (unsigned long) baseAddress;
- (unsigned short) addressModifier;
- (int) slot;
- (int) writeLongBlock:(unsigned long*) writeValue atAddress:(unsigned int) vmeAddress;
- (int) readLongBlock:(unsigned long*) readValue atAddress:(unsigned int) vmeAddress;

- (int) readMBLT:(unsigned long*) readValue
       atAddress:(unsigned int) vmeAddress
  numBytesToRead:(unsigned long) numBytes;

- (void) writeLongBlock:(unsigned long *) writeAddress
			 atAddress:(unsigned int) vmeAddress
			numToWrite:(unsigned int) numberLongs
			withAddMod:(unsigned short) anAddressModifier
          usingAddSpace:(unsigned short) anAddressSpace;


- (void) readLongBlock:(unsigned long *) readAddress
			atAddress:(unsigned int) vmeAddress
			numToRead:(unsigned int) numberLongs
		   withAddMod:(unsigned short) anAddressModifier
         usingAddSpace:(unsigned short) anAddressSpace;

@end

extern NSString* ORDT5720ModelSerialNumberChanged;
extern NSString* ORDT5720ModelUSBInterfaceChanged;
extern NSString* ORDT5720ModelLock;
extern NSString* ORDT5720ModelEventSizeChanged;
extern NSString* ORDT5720SelectedRegIndexChanged;
extern NSString* ORDT5720SelectedChannelChanged;
extern NSString* ORDT5720WriteValueChanged;
extern NSString* ORDT5720ModelEnabledMaskChanged;
extern NSString* ORDT5720ModelPostTriggerSettingChanged;
extern NSString* ORDT5720ModelTriggerSourceMaskChanged;
extern NSString* ORDT5720ModelTriggerOutMaskChanged;
extern NSString* ORDT5720ModelFrontPanelControlMaskChanged;
extern NSString* ORDT5720ModelCoincidenceLevelChanged;
extern NSString* ORDT5720ModelAcquisitionModeChanged;
extern NSString* ORDT5720ModelCountAllTriggersChanged;
extern NSString* ORDT5720ModelCustomSizeChanged;
extern NSString* ORDT5720ModelIsCustomSizeChanged;
extern NSString* ORDT5720ModelIsFixedSizeChanged;
extern NSString* ORDT5720ModelChannelConfigMaskChanged;
extern NSString* ORDT5720ModelNumberBLTEventsToReadoutChanged;
extern NSString* ORDT5720ChnlDacChanged;
extern NSString* ORDT5720OverUnderThresholdChanged;
extern NSString* ORDT5720Chnl;
extern NSString* ORDT5720ChnlThresholdChanged;
extern NSString* ORDT5720SelectedRegIndexChanged;
extern NSString* ORDT5720SelectedRegIndexChanged;
extern NSString* ORDT5720SelectedChannelChanged;
extern NSString* ORDT5720WriteValueChanged;
extern NSString* ORDT5720BasicLock;
extern NSString* ORDT5720SettingsLock;
extern NSString* ORDT5720RateGroupChanged;
extern NSString* ORDT5720ModelBufferCheckChanged;
extern NSString* ORDT5720ModelContinuousModeChanged;

