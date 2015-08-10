//-------------------------------------------------------------------------
//  ORGretina4AModel.h
//
//  Created by Mark A. Howe on Wednesday 11/20/14.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//Washington sponsored in part by the United States
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
#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "SBC_Config.h"
#import "AutoTesting.h"
#import "ORAdcInfoProviding.h"
#import "SBC_Link.h"

@class ORRateGroup;
@class ORConnector;
@class ORFileMoverOp;

#define kNumGretina4AChannels		10
#define kNumGretina4ACardParams		6
#define kGretina4AHeaderLengthLongs	7

#define kGretina4AFIFOEmpty			0x100000
#define kGretina4AFIFOAlmostEmpty	0x400000
#define kGretina4AFIFOAlmostFull	0x800000
#define kGretina4AFIFOAllFull		0x1000000

#define kGretina4APacketSeparator    0xAAAAAAAA

#define kGretina4ANumberWordsMask	0x7FF0000

#define kGretina4AFlashMaxWordCount	0xF
#define kGretina4AFlashBlockSize		( 128 * 1024 )
#define kGretina4AFlashBlocks		128
#define kGretina4AUsedFlashBlocks	32
#define kGretina4AFlashBufferBytes	32
#define kGretina4ATotalFlashBytes	( kGretina4AFlashBlocks * kGretina4AFlashBlockSize)
#define kFlashBusy                  0x80
#define kGretina4AFlashEnableWrite	0x10
#define kGretina4AFlashDisableWrite	0x0
#define kGretina4AFlashConfirmCmd	0xD0
#define kGretina4AFlashWriteCmd		0xE8
#define kGretina4AFlashBlockEraseCmd	0x20
#define kGretina4AFlashReadArrayCmd	0xFF
#define kGretina4AFlashStatusRegCmd	0x70
#define kGretina4AFlashClearSRCmd	0x50

#define kGretina4AResetMainFPGACmd	0x30
#define kGretina4AReloadMainFPGACmd	0x3
#define kGretina4AMainFPGAIsLoaded	0x41

#define kGretain4AMasterLogicCFDModeBit 0x00008000

#define kSPIData	    0x2
#define kSPIClock	    0x4
#define kSPIChipSelect	0x8
#define kSPIRead        0x10
#define kSDLockBit      (0x1<<17)
#define kSDLostLockBit  (0x1<<24)

enum {
    kSerDesIdle,
    kSerDesSetup,
    kSetDigitizerClkSrc,
    kFlushFifo,
    kReleaseClkManager,
    kPowerUpRTPower,
    kSetMasterLogic,
    kSetSDSyncBit,
    kSerDesError,
};

#pragma mark •••Register Definitions
enum {
    kBoardId,               //0x0000    board_id
    kProgrammingDone,       //0x0004	programming_done
    kExternalDiscSrc,       //0x0008    external Discriminator Src
    kHardwareStatus,        //0x0020	hardware_status
    kUserPackageData,       //0x0024	user_package_data
    kWindowCompMin,         //0x0028    window comparison min
    kWindowCompMax,         //0x002C    window comparison max
    kChannelControl,        //0x0040	channel_control0
    kLedThreshold,          //0x0080	led_threshold0
    kCFDFraction,           //0x00C0	CFD_fraction0
    kRawDataLength,         //0x0100	raw_data_length0
    kRawDataWindow,         //0x0140	raw_data_window0
    kDWindow,               //0x0180	d_window0
    kKWindow,               //0x01C0	k_window0
    kMWindow,               //0x0200	m_window0
    kD3Window,              //0x0240	d2_window0
    kDiscWidth,             //0x0280	disc_width0
    kBaselineStart,         //0x02C0	baseline_start0
    kP1Window,              //0x0300    p1_Window
    kDac,                   //0x0400	dac
    kP2Window,              //0x0404    p2_Window
    kIlaConfig,             //0x0408	ila_config
    kChannelPulsedControl,	//0x040C	channel_pulsed_control
    kDiagMuxControl,        //0x0410	diag_mux_control
    kPeakSensitivity,       //0x0414	peak_sensitivity
    kBaselineDelay,         //0x418     baseline delay
    kDiagChannelInput,      //0x041C	diag_channel_input
    kExtDiscSel,            //0x0420	ext_desc_sel
    kRj45SpareDoutControl,	//0x0424	rj45_spare_dout_control
    kLedStatus,             //0x0428	led_status
    kLatTimestampLsb,       //0x0480	lat_timestamp_lsb
    kLatTimestampMsb,       //0x0488	lat_timestamp_msb
    kLiveTimestampLsb,      //0x048C	live_timestamp_lsb
    kLiveTimestampMsb,      //0x0490	live_timestamp_msb
    kVetoGateWidth,         //0x0494	time window for slave accepts vetos
    kMasterLogicStatus,     //0x0500	master_logic_status
    kTriggerConfig,         //0x0504	trigger_config
    kPhaseErrorCount,       //0x0508	Phase_Error_count
    kPhaseValue,            //0x050C	Phase_Value
    kPhaseOffset0,          //0x0510	phase_offset0
    kPhaseOffset1,          //0x0510	phase_offset1
    kPhaseOffset2,          //0x0510	phase_offset2
    kSerdesPhaseValue,      //0x051C	Serdes_Phase_Value
    kCodeRevision,          //0x0600	code_revision
    kCodeDate,              //0x0604	code_date
    kTSErrCntEnable,        //0x0608	TS_err_cnt_enable
    kTSErrorCount,          //0x060C	TS_error_count
    kDroppedEventCount,     //0x0700	dropped_event_count0
    kAcceptedEventCount,	//0x0740	accepted_event_count0
    kAhitCount,             //0x0780	ahit_count0
    kDiscCount,             //0x07C0	disc_count0
    kAuxIORead,             //0x0800	aux_io_read
    kAuxIOWrite,            //0x0804	aux_io_write
    kAuxIOConfig,           //0x0808	aux_io_config
    kSdConfig,              //0x0848    serdes config
    kFifo,                  //0x1000	fifo
    kNumberOfGretina4ARegisters         //must be last
};


enum {
	kMainFPGAControl,			//0x0900 Main Digitizer FPGA config register
	kMainFPGAStatus,			//0x0904 Main Digitizer FPGA status register
	kVoltageAndTemperature,		//0x0908 Aux Status
	kVMEGPControl,				//0x0910 General Purpose VME Control Settings
	kVMETimeoutValue,			//0x0914 VME Timeout Value Register
	kVMEFPGAVersionStatus,		//0x0920 VME Version/Status
    kVMEFPGASandbox1,			//0x0930 VME Sandbox1
    kVMEFPGASandbox2,			//0x0934 VME Sandbox2
    kVMEFPGASandbox3,			//0x0938 VME Sandbox3
    kVMEFPGASandbox4,			//0x093C VME Sandbox4
	kNumberOfFPGARegisters
};

enum Gretina4AFIFOStates {
	kEmpty,
	kAlmostEmpty,	
	kAlmostFull,
	kFull,
	kHalfFull
};

#define kG4MDataPacketSize 1024+2  //waveforms are fixed at 1024, ORCA header is 2

#define kHeaderSize  29

@interface ORGretina4AModel : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping,AutoTesting,ORAdcInfoProviding>
{
  @private
    //connectors
    ORConnector* spiConnector;  //we won't draw this connector but need a reference to it
    ORConnector* linkConnector; //we won't draw this connector but need a reference to it
    
    //noise floor
	BOOL            oldEnabled[kNumGretina4AChannels];
	unsigned long   oldLedThreshold[kNumGretina4AChannels];
	unsigned long   newLedThreshold[kNumGretina4AChannels];
	BOOL    noiseFloorRunning;
	int     noiseFloorState;
	int     noiseFloorWorkingChannel;
	int     noiseFloorLow;
	int     noiseFloorHigh;
	int     noiseFloorTestValue;
	int     noiseFloorOffset;
    float   noiseFloorIntegrationTime;
	
    //firmware loading
    NSThread*	fpgaProgrammingThread;
    NSString*   mainFPGADownLoadState;
    NSString*   fpgaFilePath;
	BOOL        stopDownLoadingMainFPGA;
	BOOL        downLoadMainFPGAInProgress;
    int         fpgaDownProgress;
	NSLock*     progressLock;
	
    //low-level registers and diagnostics
    NSOperationQueue*	fileQueue;
    unsigned short      selectedChannel;
    unsigned long       registerWriteValue;
    int                 registerIndex;
    unsigned long       spiWriteValue;
    ORFileMoverOp*      fpgaFileMover;
	BOOL                isRunning;
    NSString*           firmwareStatusString;
    BOOL                locked;
    unsigned long       snapShot[kNumberOfGretina4ARegisters];
    unsigned long       fpgaSnapShot[kNumberOfFPGARegisters];
    
    //rates
    ORRateGroup*        waveFormRateGroup;
    unsigned long       waveFormCount[kNumGretina4AChannels];

    //clock sync
    int                 initializationState;
    
    //data taker
    unsigned long   dataId;
    unsigned long   dataBuffer[kG4MDataPacketSize];
    unsigned long   location;           //cache value
    id              theController;      //cache value
    unsigned long   fifoAddress;        //cache value
    unsigned long   fifoStateAddress;   //cache value
    int             fifoState;
    int				fifoEmptyCount;
    int             fifoResetCount;
    ORAlarm*        fifoFullAlarm;
    unsigned long       serialNumber;
    
    //hardware params
    BOOL			forceFullInit[kNumGretina4AChannels];
    BOOL			enabled[kNumGretina4AChannels];
    BOOL            forceFullCardInit;
    
    unsigned long firmwareVersion;
    unsigned long acqDcmCtrlStatus;
    BOOL acqDcmLock;
    BOOL acqDcmReset;
    BOOL acqPhShiftOverflow;
    BOOL acqDcmClockStopped;
    unsigned long adcDcmCtrlStatus;
    BOOL adcDcmLock;
    BOOL adcDcmReset;
    BOOL adcPhShiftOverflow;
    BOOL adcDcmClockStopped;
    unsigned long userPackageData;
    BOOL writeFlag;
    unsigned long decimationFactor;
    unsigned long windowCompMin;
    unsigned long windowCompMax;
    BOOL routerVetoEn[kNumGretina4AChannels];
    BOOL preampResetDelayEn[kNumGretina4AChannels];
    BOOL pileupMode[kNumGretina4AChannels];
    BOOL droppedEventCountMode[kNumGretina4AChannels];
    BOOL eventCountMode[kNumGretina4AChannels];
    BOOL aHitCountMode[kNumGretina4AChannels];
    BOOL discCountMode[kNumGretina4AChannels];
    unsigned long eventExtensionMode[kNumGretina4AChannels];
    BOOL pileupExtensionMode[kNumGretina4AChannels];
    BOOL counterReset[kNumGretina4AChannels];
    BOOL pileupWaveformOnlyMode[kNumGretina4AChannels];
    unsigned long triggerPolarity[kNumGretina4AChannels];
    unsigned long ledThreshold[kNumGretina4AChannels];
    unsigned long preampResetDelay[kNumGretina4AChannels];
    unsigned long cFDFraction[kNumGretina4AChannels];
    unsigned long rawDataLength[kNumGretina4AChannels];
    unsigned long rawDataWindow[kNumGretina4AChannels];
    unsigned long dWindow[kNumGretina4AChannels];
    unsigned long kWindow[kNumGretina4AChannels];
    unsigned long mWindow[kNumGretina4AChannels];
    unsigned long d3Window[kNumGretina4AChannels];
    unsigned long discWidth[kNumGretina4AChannels];
    unsigned long baselineStart[kNumGretina4AChannels];
    unsigned long p1Window[kNumGretina4AChannels];
    unsigned long p2Window;
    unsigned long dacChannelSelect;
    unsigned long dacAttenuation;
    unsigned long ilaConfig;
    unsigned long baselineDelay;
    BOOL phaseHunt;
    BOOL loadbaseline;
    BOOL phaseHuntDebug;
    BOOL phaseHuntProceed;
    BOOL phaseDec;
    BOOL phaseInc;
    BOOL serdesPhaseInc;
    BOOL serdesPhaseDec;
    unsigned long diagMuxControl;
    unsigned long peakSensitivity;
    unsigned long diagInput;
    unsigned long diagChannelEventSel;
    unsigned long rj45SpareIoMuxSel;
    BOOL rj45SpareIoDir;
    unsigned long ledStatus;
    unsigned long liveTimestampLsb;
    unsigned long liveTimestampMsb;
    BOOL diagIsync;
    BOOL serdesSmLostLock;
    BOOL overflowFlagChan[kNumGretina4AChannels];
    unsigned long triggerConfig;
    unsigned long phaseErrorCount;
    unsigned long phaseStatus;
    unsigned long phase0[kNumGretina4AChannels];
    unsigned long phase1[kNumGretina4AChannels];
    unsigned long phase2[kNumGretina4AChannels];
    unsigned long phase3[kNumGretina4AChannels];
    unsigned long serdesPhaseValue;
    unsigned long pcbRevision;
    unsigned long fwType;
    unsigned long mjrCodeRevision;
    unsigned long minCodeRevision;
    unsigned long codeDate;
    unsigned long tSErrCntCtrl;
    unsigned long tSErrorCount;
    unsigned long droppedEventCount[kNumGretina4AChannels];
    unsigned long acceptedEventCount[kNumGretina4AChannels];
    unsigned long ahitCount[kNumGretina4AChannels];
    unsigned long discCount[kNumGretina4AChannels];
    unsigned long auxIoRead;
    unsigned long auxIoWrite;
    unsigned long auxIoConfig;
    unsigned long sdPem;
    BOOL sdSmLostLockFlag;
    unsigned long adcConfig;
    BOOL configMainFpga;
    BOOL powerOk;
    BOOL overVoltStat;
    BOOL underVoltStat;
    BOOL temp0Sensor;
    BOOL temp1Sensor;
    BOOL temp2Sensor;
    BOOL clkSelect0;
    BOOL clkSelect1;
    BOOL flashMode;
    unsigned long serialNum;
    unsigned long boardRevNum;
    unsigned long vhdlVerNum;
    unsigned long fifoAccess;
}

#pragma mark ***Boilerplate
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian;
- (BOOL) isLocked;
- (BOOL) locked;
- (void) setLocked:(BOOL)aState;

#pragma mark ***Accessors
- (ORConnector*)    spiConnector;
- (void)            setSpiConnector:(ORConnector*)aConnector;
- (ORConnector*)    linkConnector;
- (void)            setLinkConnector:(ORConnector*)aConnector;

#pragma mark ***Low-level registers and diagnostics
- (short)           registerIndex;
- (void)            setRegisterIndex:(int)aRegisterIndex;
- (unsigned long)   selectedChannel;
- (void)            setSelectedChannel:(unsigned short)aChannel;
- (unsigned long)   registerWriteValue;
- (void)            setRegisterWriteValue:(unsigned long)aWriteValue;
- (unsigned long)   spiWriteValue;
- (void)            setSPIWriteValue:(unsigned long)aWriteValue;
- (NSString*)       registerNameAt:(unsigned int)index;
- (unsigned short)  registerOffsetAt:(unsigned int)index;
- (NSString*)       fpgaRegisterNameAt:(unsigned int)index;
- (unsigned short)  registerEnumAt:(unsigned int)index;
- (unsigned short)  fpgaRegisterOffsetAt:(unsigned int)index;
- (unsigned long)   readRegister:(unsigned int)index;
- (void)            writeRegister:(unsigned int)index withValue:(unsigned long)value;
- (BOOL)            hasChannels:(unsigned int)index;
- (BOOL)            canReadRegister:(unsigned int)index;
- (BOOL)            canWriteRegister:(unsigned int)index;
- (unsigned long)   readFPGARegister:(unsigned int)index;
- (void)            writeFPGARegister:(unsigned int)index withValue:(unsigned long)value;
- (BOOL)            canReadFPGARegister:(unsigned int)index;
- (BOOL)            canWriteFPGARegister:(unsigned int)index;
- (void)            writeToAddress:(unsigned long)anAddress aValue:(unsigned long)aValue;
- (unsigned long)   readFromAddress:(unsigned long)anAddress;
- (void)            dumpAllRegisters;
- (void)            snapShotRegisters;
- (void)            compareToSnapShot;

#pragma mark ***Firmware loading
- (void)            startDownLoadingMainFPGA;
- (void)            stopDownLoadingMainFPGA;
- (BOOL)            downLoadMainFPGAInProgress;
- (void)            setDownLoadMainFPGAInProgress:(BOOL)aState;
- (short)           fpgaDownProgress;
- (NSString*)       mainFPGADownLoadState;
- (void)            setMainFPGADownLoadState:(NSString*)aMainFPGADownLoadState;
- (NSString*)       fpgaFilePath;
- (void)            setFpgaFilePath:(NSString*)aFpgaFilePath;
- (void)            tasksCompleted: (NSNotification*)aNote;
- (BOOL)            queueIsRunning;
- (NSString*)       firmwareStatusString;
- (void)            setFirmwareStatusString:(NSString*)aState;

#pragma mark ***noise floor
- (float)           noiseFloorIntegrationTime;
- (void)            setNoiseFloorIntegrationTime:(float)aNoiseFloorIntegrationTime;
- (short)           noiseFloorOffset;
- (void)            setNoiseFloorOffset:(short)aNoiseFloorOffset;
- (void)            initParams;
- (BOOL)            enabled:(short)chan;
- (void)            setEnabled:(short)chan withValue:(BOOL)aValue;
- (void)            findNoiseFloors;
- (void)            stepNoiseFloor;
- (BOOL)            noiseFloorRunning;

#pragma mark ***rates
- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(short)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;

- (BOOL)            forceFullInit:(short)chan;
- (void)            setForceFullInit:(short)chan withValue:(BOOL)aValue;
- (BOOL)            forceFullCardInit;
- (void)            setForceFullCardInit:(BOOL)aValue;

#pragma mark •••Hardware Access
- (void)            initBoard;
- (short)           readBoardID;
- (BOOL)            checkFirmwareVersion;
- (BOOL)            checkFirmwareVersion:(BOOL)verbose;
- (void)            readFPGAVersions;
- (void)            resetBoard;
- (void)            resetMainFPGA;
- (void)            resetFIFO;
- (void)            resetSingleFIFO;
- (unsigned long)   readControlReg:(short)channel;
- (void)            writeMasterLogic:(BOOL)enable;
- (void)            writeControlReg:(short)channel enabled:(BOOL)enabled;
- (BOOL)            fifoIsEmpty;
- (void)            loadWindowDelays;
- (void)            writeLedThreshold:(short)channel;
- (void)            writeCFDFraction:(short)channel;
- (void)            writeRawDataLength:(short)channel;
- (void)            writeRawDataWindow:(short)channel;
- (void)            writeDWindow:(short)channel;
- (void)            writeKWindow:(short)channel;
- (void)            writeMWindow:(short)channel;
- (void)            writeD3Window:(short)channel;
- (void)            writeP1Window:(short)channel;
- (void)            writeP2Window;
- (void)            writeDiscWidth:(short)channel;
- (void)            writeBaselineDelay;
- (void)            writeBaselineStart:(short)channel;
- (void)            writeTriggerConfig;
- (void)            writePeakSensitivity;
- (void)            writeWindowCompMin;
- (void)            writeWindowCompMax;

#pragma mark •••Data Taker
- (unsigned long)   dataId;
- (void)            setDataId: (unsigned long) DataId;
- (void)            setDataIds:(id)assigner;
- (void)            syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*)   dataRecordDescription;
- (void)            runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void)            takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void)            runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void)            runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void)            startRates;
- (void)            clearWaveFormCounts;
- (unsigned long)   getCounter:(short)counterTag forGroup:(short)groupTag;
- (void)            checkFifoAlarm;
- (int)             load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (void)            reset;
- (BOOL)            bumpRateFromDecodeStage:(short)channel;
- (unsigned long)   waveFormCount:(short)aChannel;

#pragma mark •••Clock Sync
- (short)           initState;
- (void)            setInitState:(short)aState;
- (void)            stepSerDesInit;
- (NSString*)       serDesStateName;

#pragma mark •••HW Wizard
- (int)         numberOfChannels;
- (NSArray*)    wizardParameters;
- (NSArray*)    wizardSelections;
- (NSNumber*)   extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

#pragma mark •••Archival
- (id)                      initWithCoder:(NSCoder*)decoder;
- (void)                    encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*)    addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void)                    addCurrentState:(NSMutableDictionary*)dictionary shortArray:(short*)anArray forKey:(NSString*)aKey;
- (void)                    addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray forKey:(NSString*)aKey;

#pragma mark •••AutoTesting
- (NSArray*) autoTests;

#pragma mark •••SPI Interface
- (unsigned long) writeAuxIOSPI:(unsigned long)spiData;

#pragma mark •••AdcProviding Protocol
- (BOOL)            onlineMaskBit:(int)bit;
- (BOOL)            partOfEvent:(unsigned short)aChannel;
- (unsigned long)   eventCount:(int)aChannel;
- (void)            clearEventCounts;
- (unsigned long)   thresholdForDisplay:(unsigned short) aChan;
- (unsigned short)  gainForDisplay:(unsigned short) aChan;

#pragma mark •••Hardware Register Accessors
- (unsigned long)  firmwareVersion;
- (void)    setFirmwareVersion:(unsigned long)aValue;
- (unsigned long)  acqDcmCtrlStatus;
- (void)    setAcqDcmCtrlStatus:(unsigned long)aValue;
- (BOOL)  acqDcmLock;
- (void)    setAcqDcmLock:(BOOL)aValue;
- (BOOL)  acqDcmReset;
- (void)    setAcqDcmReset:(BOOL)aValue;
- (BOOL)  acqPhShiftOverflow;
- (void)    setAcqPhShiftOverflow:(BOOL)aValue;
- (BOOL)  acqDcmClockStopped;
- (void)    setAcqDcmClockStopped:(BOOL)aValue;
- (unsigned long)  adcDcmCtrlStatus;
- (void)    setAdcDcmCtrlStatus:(unsigned long)aValue;
- (BOOL)  adcDcmLock;
- (void)    setAdcDcmLock:(BOOL)aValue;
- (BOOL)  adcDcmReset;
- (void)    setAdcDcmReset:(BOOL)aValue;
- (BOOL)  adcPhShiftOverflow;
- (void)    setAdcPhShiftOverflow:(BOOL)aValue;
- (BOOL)  adcDcmClockStopped;
- (void)    setAdcDcmClockStopped:(BOOL)aValue;
- (unsigned long)  userPackageData;
- (void)    setUserPackageData:(unsigned long)aValue;
- (unsigned long) windowCompMin;
- (void) setWindowCompMin:(unsigned long)aValue;
- (unsigned long) windowCompMax;
- (void) setWindowCompMax:(unsigned long)aValue;
- (BOOL)  routerVetoEn:(int)anIndex;
- (void)    setRouterVetoEn:(int)anIndex withValue:(BOOL)aValue;
- (BOOL)  preampResetDelayEn:(int)anIndex;
- (void)    setPreampResetDelayEn:(int)anIndex withValue:(BOOL)aValue;
- (BOOL) writeFlag;
- (void) setWriteFlag:(BOOL)aWriteFlag;
- (unsigned long) decimationFactor;
- (void) setDecimationFactor:(unsigned long)aDecimationFactor;
- (BOOL)  pileupMode:(int)anIndex;
- (void)    setPileupMode:(int)anIndex withValue:(BOOL)aValue;
- (BOOL)  droppedEventCountMode:(int)anIndex;
- (void)    setDroppedEventCountMode:(int)anIndex withValue:(BOOL)aValue;
- (BOOL)  eventCountMode:(int)anIndex;
- (void)    setEventCountMode:(int)anIndex withValue:(BOOL)aValue;
- (unsigned long)  triggerPolarity:(int)anIndex;
- (void)    setTriggerPolarity:(int)anIndex withValue:(unsigned long)aValue;
- (BOOL)  aHitCountMode:(int)anIndex;
- (void)  setAHitCountMode:(int)anIndex withValue:(BOOL)aValue;
- (BOOL)  discCountMode:(int)anIndex;
- (void)  setDiscCountMode:(int)anIndex withValue:(BOOL)aValue;
- (unsigned long) eventExtensionMode:(int)anIndex;
- (void) setEventExtensionMode:(int)anIndex withValue:(unsigned long)aValue;
- (BOOL)  pileupExtensionMode:(int)anIndex;
- (void)    setPileupExtensionMode:(int)anIndex withValue:(BOOL)aValue;
- (BOOL)  counterReset:(int)anIndex;
- (void)    setCounterReset:(int)anIndex withValue:(BOOL)aValue;
- (BOOL)  pileupWaveformOnlyMode:(int)anIndex;
- (void)    setPileupWaveformOnlyMode:(int)anIndex withValue:(BOOL)aValue;
- (unsigned long)  ledThreshold:(int)anIndex;
- (void)    setLedThreshold:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  preampResetDelay:(int)anIndex;
- (void)    setPreampResetDelay:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  cFDFraction:(int)anIndex;
- (void)    setCFDFraction:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  rawDataLength:(int)anIndex;
- (void)    setRawDataLength:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  rawDataWindow:(int)anIndex;
- (void)    setRawDataWindow:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  dWindow:(int)anIndex;
- (void)    setDWindow:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  kWindow:(int)anIndex;
- (void)    setKWindow:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  mWindow:(int)anIndex;
- (void)    setMWindow:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  d3Window:(int)anIndex;
- (void)    setD3Window:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  discWidth:(int)anIndex;
- (void)    setDiscWidth:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  baselineStart:(int)anIndex;
- (void)    setBaselineStart:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  baselineDelay;
- (void)    setBaselineDelay:(unsigned long)aValue;

- (unsigned long)  p2Window;
- (void)    setP2Window:(unsigned long)aValue;
- (unsigned long)  p1Window:(int)anIndex;
- (void)    setP1Window:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  dacChannelSelect;
- (void)    setDacChannelSelect:(unsigned long)aValue;
- (unsigned long)  dacAttenuation;
- (void)    setDacAttenuation:(unsigned long)aValue;
- (unsigned long)  ilaConfig;
- (void)    setIlaConfig:(unsigned long)aValue;
- (BOOL)  phaseHunt;
- (void)    setPhaseHunt:(BOOL)aValue;
- (BOOL)  loadbaseline;
- (void)    setLoadbaseline:(BOOL)aValue;
- (BOOL)  phaseHuntDebug;
- (void)    setPhaseHuntDebug:(BOOL)aValue;
- (BOOL)  phaseHuntProceed;
- (void)    setPhaseHuntProceed:(BOOL)aValue;
- (BOOL)  phaseDec;
- (void)    setPhaseDec:(BOOL)aValue;
- (BOOL)  phaseInc;
- (void)    setPhaseInc:(BOOL)aValue;
- (BOOL)  serdesPhaseInc;
- (void)    setSerdesPhaseInc:(BOOL)aValue;
- (BOOL)  serdesPhaseDec;
- (void)    setSerdesPhaseDec:(BOOL)aValue;
- (unsigned long)  diagMuxControl;
- (void)    setDiagMuxControl:(unsigned long)aValue;
- (unsigned long)  peakSensitivity;
- (void)    setPeakSensitivity:(unsigned long)aValue;
- (unsigned long)  diagInput;
- (void)    setDiagInput:(unsigned long)aValue;
- (unsigned long)  diagChannelEventSel;
- (void)    setDiagChannelEventSel:(unsigned long)aValue;
- (unsigned long)  rj45SpareIoMuxSel;
- (void)    setRj45SpareIoMuxSel:(unsigned long)aValue;
- (BOOL)  rj45SpareIoDir;
- (void)    setRj45SpareIoDir:(BOOL)aValue;
- (unsigned long)  ledStatus;
- (void)    setLedStatus:(unsigned long)aValue;
- (unsigned long)  liveTimestampLsb;
- (void)    setLiveTimestampLsb:(unsigned long)aValue;
- (unsigned long)  liveTimestampMsb;
- (void)    setLiveTimestampMsb:(unsigned long)aValue;
- (BOOL)  diagIsync;
- (void)    setDiagIsync:(BOOL)aValue;
- (BOOL)  serdesSmLostLock;
- (void)    setSerdesSmLostLock:(BOOL)aValue;
- (BOOL)    overflowFlagChan:(int)anIndex;
- (void)    setOverflowFlagChan:(int)anIndex withValue:(BOOL)aValue;
- (unsigned long)  triggerConfig;
- (void)    setTriggerConfig:(unsigned long)aValue;
- (unsigned long)  phaseErrorCount;
- (void)    setPhaseErrorCount:(unsigned long)aValue;
- (unsigned long)  phaseStatus;
- (void)    setPhaseStatus:(unsigned long)aValue;
- (unsigned long)  phase0:(int)anIndex;
- (void)    setPhase0:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  phase1:(int)anIndex;
- (void)    setPhase1:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  phase2:(int)anIndex;
- (void)    setPhase2:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  phase3:(int)anIndex;
- (void)    setPhase3:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  serdesPhaseValue;
- (void)    setSerdesPhaseValue:(unsigned long)aValue;
- (unsigned long)  pcbRevision;
- (void)    setPcbRevision:(unsigned long)aValue;
- (unsigned long)  fwType;
- (void)    setFwType:(unsigned long)aValue;
- (unsigned long)  mjrCodeRevision;
- (void)    setMjrCodeRevision:(unsigned long)aValue;
- (unsigned long)  minCodeRevision;
- (void)    setMinCodeRevision:(unsigned long)aValue;
- (unsigned long)  codeDate;
- (void)    setCodeDate:(unsigned long)aValue;
- (unsigned long)  tSErrCntCtrl;
- (void)    setTSErrCntCtrl:(unsigned long)aValue;
- (unsigned long)  tSErrorCount;
- (void)    setTSErrorCount:(unsigned long)aValue;
- (unsigned long)  droppedEventCount:(int)anIndex;
- (void)    setDroppedEventCount:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  acceptedEventCount:(int)anIndex;
- (void)    setAcceptedEventCount:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  ahitCount:(int)anIndex;
- (void)    setAhitCount:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  discCount:(int)anIndex;
- (void)    setDiscCount:(int)anIndex withValue:(unsigned long)aValue;
- (unsigned long)  auxIoRead;
- (void)    setAuxIoRead:(unsigned long)aValue;
- (unsigned long)  auxIoWrite;
- (void)    setAuxIoWrite:(unsigned long)aValue;
- (unsigned long)  auxIoConfig;
- (void)    setAuxIoConfig:(unsigned long)aValue;
- (unsigned long)  sdPem;
- (void)    setSdPem:(unsigned long)aValue;
- (BOOL)  sdSmLostLockFlag;
- (void)    setSdSmLostLockFlag:(BOOL)aValue;
- (unsigned long)  adcConfig;
- (void)    setAdcConfig:(unsigned long)aValue;
- (BOOL)  configMainFpga;
- (void)    setConfigMainFpga:(BOOL)aValue;
- (BOOL)  powerOk;
- (void)    setPowerOk:(BOOL)aValue;
- (BOOL)  overVoltStat;
- (void)    setOverVoltStat:(BOOL)aValue;
- (BOOL)  underVoltStat;
- (void)    setUnderVoltStat:(BOOL)aValue;
- (BOOL)  temp0Sensor;
- (void)    setTemp0Sensor:(BOOL)aValue;
- (BOOL)  temp1Sensor;
- (void)    setTemp1Sensor:(BOOL)aValue;
- (BOOL)  temp2Sensor;
- (void)    setTemp2Sensor:(BOOL)aValue;
- (BOOL)  clkSelect0;
- (void)    setClkSelect0:(BOOL)aValue;
- (BOOL)  clkSelect1;
- (void)    setClkSelect1:(BOOL)aValue;
- (BOOL)  flashMode;
- (void)    setFlashMode:(BOOL)aValue;
- (unsigned long)  serialNum;
- (void)    setSerialNum:(unsigned long)aValue;
- (unsigned long)  boardRevNum;
- (void)    setBoardRevNum:(unsigned long)aValue;
- (unsigned long)  vhdlVerNum;
- (void)    setVhdlVerNum:(unsigned long)aValue;
- (unsigned long)  fifoAccess;
- (void)    setFifoAccess:(unsigned long)aValue;

@end

@interface NSObject (Gretina4A)
- (NSString*) IPNumber;
- (NSString*) userName;
- (NSString*) passWord;
- (SBC_Link*) sbcLink;
@end

extern NSString* ORGretina4ARegisterIndexChanged;
extern NSString* ORGretina4ASelectedChannelChanged;
extern NSString* ORGretina4ARegisterWriteValueChanged;
extern NSString* ORGretina4ASPIWriteValueChanged;
extern NSString* ORGretina4AMainFPGADownLoadInProgressChanged;
extern NSString* ORGretina4AFpgaDownProgressChanged;
extern NSString* ORGretina4AMainFPGADownLoadStateChanged;
extern NSString* ORGretina4AFpgaFilePathChanged;
extern NSString* ORGretina4ANoiseFloorOffsetChanged;
extern NSString* ORGretina4ANoiseFloorIntegrationTimeChanged;
extern NSString* ORGretina4ANoiseFloorChanged;
extern NSString* ORGretina4AFIFOCheckChanged;
extern NSString* ORGretina4AModelFirmwareStatusStringChanged;

extern NSString* ORGretina4AModelInitStateChanged;
extern NSString* ORGretina4ACardInited;

extern NSString* ORGretina4AForceFullCardInitChanged;
extern NSString* ORGretina4AForceFullInitChanged;
extern NSString* ORGretina4AEnabledChanged;

extern NSString* ORGretina4ASettingsLock;
extern NSString* ORGretina4ARegisterLock;
extern NSString* ORGretina4ARateGroupChangedNotification;

extern NSString* ORGretina4AFirmwareVersionChanged;
extern NSString* ORGretina4AWindowCompMinChanged;
extern NSString* ORGretina4AWindowCompMaxChanged;
extern NSString* ORGretina4AAcqDcmCtrlStatusChanged;
extern NSString* ORGretina4AAcqDcmLockChanged;
extern NSString* ORGretina4AAcqDcmResetChanged;
extern NSString* ORGretina4AAcqPhShiftOverflowChanged;
extern NSString* ORGretina4AAcqDcmClockStoppedChanged;
extern NSString* ORGretina4AAdcDcmCtrlStatusChanged;
extern NSString* ORGretina4AAdcDcmLockChanged;
extern NSString* ORGretina4AAdcDcmResetChanged;
extern NSString* ORGretina4AAdcPhShiftOverflowChanged;
extern NSString* ORGretina4AAdcDcmClockStoppedChanged;
extern NSString* ORGretina4AUserPackageDataChanged;
extern NSString* ORGretina4ARouterVetoEn0Changed;
extern NSString* ORGretina4APreampResetDelayEnChanged;
extern NSString* ORGretina4ADecimationFactorChanged;
extern NSString* ORGretina4APileupMode0Changed;
extern NSString* ORGretina4ADroppedEventCountModeChanged;
extern NSString* ORGretina4AEventCountModeChanged;
extern NSString* ORGretina4AAHitCountModeChanged;
extern NSString* ORGretina4ADiscCountModeChanged;
extern NSString* ORGretina4AEventExtensionModeChanged;
extern NSString* ORGretina4APileupExtensionModeChanged;
extern NSString* ORGretina4AWriteFlagChanged;
extern NSString* ORGretina4ACounterResetChanged;
extern NSString* ORGretina4APileupWaveformOnlyModeChanged;
extern NSString* ORGretina4ALedThreshold0Changed;
extern NSString* ORGretina4APreampResetDelay0Changed;
extern NSString* ORGretina4ATriggerPolarityChanged;
extern NSString* ORGretina4ACFDFractionChanged;
extern NSString* ORGretina4ARawDataLengthChanged;
extern NSString* ORGretina4ARawDataWindowChanged;
extern NSString* ORGretina4ADWindowChanged;
extern NSString* ORGretina4AKWindowChanged;
extern NSString* ORGretina4AMWindowChanged;
extern NSString* ORGretina4AD3WindowChanged;
extern NSString* ORGretina4ADiscWidthChanged;
extern NSString* ORGretina4ABaselineStartChanged;
extern NSString* ORGretina4ABaselineDelayChanged;
extern NSString* ORGretina4AP1WindowChanged;
extern NSString* ORGretina4AP2WindowChanged;
extern NSString* ORGretina4ADacChannelSelectChanged;
extern NSString* ORGretina4ADacAttenuationChanged;
extern NSString* ORGretina4AIlaConfigChanged;
extern NSString* ORGretina4APhaseHuntChanged;
extern NSString* ORGretina4ALoadbaselineChanged;
extern NSString* ORGretina4APhaseHuntDebugChanged;
extern NSString* ORGretina4APhaseHuntProceedChanged;
extern NSString* ORGretina4APhaseDecChanged;
extern NSString* ORGretina4APhaseIncChanged;
extern NSString* ORGretina4ASerdesPhaseIncChanged;
extern NSString* ORGretina4ASerdesPhaseDecChanged;
extern NSString* ORGretina4ADiagMuxControlChanged;
extern NSString* ORGretina4APeakSensitivityChanged;
extern NSString* ORGretina4ADiagInputChanged;
extern NSString* ORGretina4ADiagChannelEventSelChanged;
extern NSString* ORGretina4ARj45SpareIoMuxSelChanged;
extern NSString* ORGretina4ARj45SpareIoDirChanged;
extern NSString* ORGretina4ALedStatusChanged;
extern NSString* ORGretina4ALiveTimestampLsbChanged;
extern NSString* ORGretina4ALiveTimestampMsbChanged;
extern NSString* ORGretina4ADiagIsyncChanged;
extern NSString* ORGretina4ASerdesSmLostLockChanged;
extern NSString* ORGretina4AOverflowFlagChanChanged;
extern NSString* ORGretina4ATriggerConfigChanged;
extern NSString* ORGretina4APhaseErrorCountChanged;
extern NSString* ORGretina4APhaseStatusChanged;
extern NSString* ORGretina4APhase0Changed;
extern NSString* ORGretina4APhase1Changed;
extern NSString* ORGretina4APhase2Changed;
extern NSString* ORGretina4APhase3Changed;
extern NSString* ORGretina4ASerdesPhaseValueChanged;
extern NSString* ORGretina4APcbRevisionChanged;
extern NSString* ORGretina4AFwTypeChanged;
extern NSString* ORGretina4AMjrCodeRevisionChanged;
extern NSString* ORGretina4AMinCodeRevisionChanged;
extern NSString* ORGretina4ACodeDateChanged;
extern NSString* ORGretina4ATSErrCntCtrlChanged;
extern NSString* ORGretina4ATSErrorCountChanged;
extern NSString* ORGretina4ADroppedEventCountChanged;
extern NSString* ORGretina4AAcceptedEventCountChanged;
extern NSString* ORGretina4AAhitCountChanged;
extern NSString* ORGretina4ADiscCountChanged;
extern NSString* ORGretina4AAuxIoReadChanged;
extern NSString* ORGretina4AAuxIoWriteChanged;
extern NSString* ORGretina4AAuxIoConfigChanged;
extern NSString* ORGretina4ASdPemChanged;
extern NSString* ORGretina4ASdSmLostLockFlagChanged;
extern NSString* ORGretina4AAdcConfigChanged;
extern NSString* ORGretina4AConfigMainFpgaChanged;
extern NSString* ORGretina4APowerOkChanged;
extern NSString* ORGretina4AOverVoltStatChanged;
extern NSString* ORGretina4AUnderVoltStatChanged;
extern NSString* ORGretina4ATemp0SensorChanged;
extern NSString* ORGretina4ATemp1SensorChanged;
extern NSString* ORGretina4ATemp2SensorChanged;
extern NSString* ORGretina4AClkSelect0Changed;
extern NSString* ORGretina4AClkSelect1Changed;
extern NSString* ORGretina4AFlashModeChanged;
extern NSString* ORGretina4ASerialNumChanged;
extern NSString* ORGretina4ABoardRevNumChanged;
extern NSString* ORGretina4AVhdlVerNumChanged;
extern NSString* ORGretina4AFifoAccessChanged;

