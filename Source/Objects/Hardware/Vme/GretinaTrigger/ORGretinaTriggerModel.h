//-------------------------------------------------------------------------
//  ORGretinaTriggerModel.h
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
#import "ORVmeIOCard.h"
#import "SBC_Link.h"

@class ORFileMoverOp;

#pragma mark •••Register Definitions
enum {
    kInputLinkMask,
    kLEDRegister,
    kSkewCtlA,
    kSkewCtlB,
    kSkewCtlC,
    kMiscClkCrl,
    kAuxIOCrl,
    kAuxIOData,
    kAuxInputSelect,
    kAuxTriggerWidth,
    
    kSerdesTPower,
    kSerdesRPower,
    kSerdesLocalLe,
    kSerdesLineLe,
    kLvdsPreEmphasis,
    kLinkLruCrl,
    kMiscCtl1,
    kMiscCtl2,
    kGenericTestFifo,
    kDiagPinCrl,
   
    kTrigMask,
    kTrigDistMask,
    kSerdesMultThresh,
    kTwEthreshCrl,
    kTwEthreshLow,
    kTwEthreshHi,
    kRawEthreshlow,
    kRawEthreshHi,
    kIsomerThresh1,
    kIsomerThresh2,

    kIsomerTimeWindow,
    kFifoRawEsumThresh,
    kFifoTwEsumThresh,
    kCCPattern1,
    kCCPattern2,
    kCCPattern3,
    kCCPattern4,
    kCCPattern5,
    kCCPattern6,
    kCCPattern7,
    
    kCCPattern8,
    kMon1FifoSel,
    kMon2FifoSel,
    kMon3FifoSel,
    kMon4FifoSel,
    kMon5FifoSel,
    kMon6FifoSel,
    kMon7FifoSel,
    kMon8FifoSel,
    kChanFifoCrl,
    
    kDigMiscBits,
    kDigDiscBitSrc,
    kDenBits,
    kRenBits,
    kSyncBits,
    kPulsedCtl1,
    kPulsedCtl2,
    kFifoResets,
    kAsyncCmdFifo,
    kAuxCmdFifo,
    
    kDebugCmdFifo,
    kMask,
    kFastStrbThresh,
    kLinkLocked,
    kLinkDen,
    kLinkRen,
    kLinkSync,
    kChanFifoStat,
    kTimeStampA,
    kTimeStampB,
    
    kTimeStampC,
    kMSMState,
    kChanPipeStatus,
    kRcState,
    kMiscStatus,
    kDiagnosticA,
    kDiagnosticB,
    kDiagnosticC,
    kDiagnosticD,
    kDiagnosticE,
    
    kDiagnosticF,
    kDiagnosticG,
    kDiagnosticH,
    kDiagStat,
    kRunRawEsum,
    kCodeModeDate,
    kCodeRevision,
    kMon1Fifo,
    kMon2Fifo,
    kMon3Fifo,
    
    kMon4Fifo,
    kMon5Fifo,
    kMon6Fifo,
    kMon7Fifo,
    kMon8Fifo,
    kChan1Fifo,
    kChan2Fifo,
    kChan3Fifo,
    kChan4Fifo,
    kChan5Fifo,
    
    kChan6Fifo,
    kChan7Fifo,
    kChan8Fifo,
    kMonFifoState,
    kChanFifoState,
    kTotalMultiplicity,
    kRouterAMultiplicity,
    kRouterBMultiplicity,
    kRouterCMultiplicity,
    kRouterDMultiplicity,
    
    kNumberOfGretinaTriggerRegisters	//must be last
};

enum {
	kTriggerMainFPGAControl,			//[0] Main Digitizer FPGA configuration register
	kTriggerMainFPGAStatus,             //[1] Main Digitizer FPGA status register
	kTriggerVoltageAndTemperature,		//[2] Voltage and Temperature Status
	kTriggerVMEGPControl,				//[3] General Purpose VME Control Settings
	kTriggerVMETimeoutValue,			//[4] VME Timeout Value Register
	kTriggerVMEFPGAVersionStatus,		//[5] VME Version/Status
	kTriggerVMEFPGASandbox1,			//[6] VME FPGA Sandbox Register Block
	kTriggerVMEFPGASandbox2,			//[7] VME FPGA Sandbox Register Block
	kTriggerVMEFPGASandbox3,			//[8] VME FPGA Sandbox Register Block
	kTriggerVMEFPGASandbox4,			//[9] VME FPGA Sandbox Register Block
	kTriggerFlashAddress,				//[10] Flash Address
	kTriggerFlashDataWithAddrIncr,		//[11] Flash Data with Auto-increment address
	kTriggerFlashData,					//[12] Flash Data
	kTriggerFlashCommandRegister,		//[13] Flash Command Register
	kTriggerNumberOfFPGARegisters
};

enum {
    kStepIdle,
    kStepSetup,
    kStep1a,
    kStep1b,
    kStep1c,
    kStep1d,
    kCheckStep1d,
    kRunSteps2a2c,
    kWaitOnSteps2a2c,
    kStep2a,
    kStep2b,
    kStep2c,
    kStep3a,
    kStep3b,
    kRunSteps4a4b,
    kWaitOnSteps4a4b,
    kStep3c,
    kStep3d,
    kStep3e,
    kStep4a,
    kStepStartCheckingCounter,
    kStepCheckCounter,
    kStep4b,
    kStep5a,
    kStep5b,
    kStep5c,
    kStep5d,
    kRunSteps6To9,
    kWaitOnSteps6To9,
    kStep6a,
    kStep6b,
    kStep7a,
    kStep7b,
    kStep7c,
    kStep7d,
    kStep7e,
    kStep7f,
    kStep7g,
    kStep8,
    kStep9,
    kStep10,
    kStepError,
};


#define kResetLinkInitMachBit (0x1<<2)
#define kPowerOnLSerDes        (0x1<<8)
#define kClockSourceSelectBit (0x1<<15)
#define kLinkInitStateMask    (0x0F00)
#define kSerdesPowerOnAll     (0x7FF)
#define kLinkLruCrlMask       (0x700)
#define kLvdsPreEmphasisPowerOnL (0x1<<2)
#define kAllLockBit           (0x1<<14)
#define kStringentLockBit     (0x1<<4)
#define linkInitAckBit        (0x1<<1)
#define kWaitAcknowledgeStateMask  (0x0F00)
#define kAcknowledgedStateMask     (0x0F00)

@interface ORGretinaTriggerModel : ORVmeIOCard
{
  @private
	NSThread*		fpgaProgrammingThread;
	ORConnector*    linkConnector[11]; //we won't draw these connectors so we have to keep references to them
	BOOL            isMaster;
    unsigned short  regWriteValue;
    int             registerIndex;
    unsigned short  inputLinkMask;
    unsigned short  serdesTPowerMask;
    unsigned short  serdesRPowerMask;
    unsigned short  lvdsPreemphasisCtlMask;
    unsigned short  miscCtl1Reg;
    unsigned short  miscStatReg;
    unsigned short  linkLruCrlReg;
    unsigned short  linkLockedReg;
    unsigned short  lastCounter;
    unsigned short  currentCounter;
    int             stepAfterCounterCheck;
    unsigned short  totalTimeCheckingCounter;
    BOOL            clockUsingLLink;
    NSString*       mainFPGADownLoadState;
    NSString*       fpgaFilePath;
	BOOL            stopDownLoadingMainFPGA;
	BOOL            downLoadMainFPGAInProgress;
    int             fpgaDownProgress;
	NSLock*         progressLock;
    NSString*       firmwareStatusString;
    unsigned short  diagnosticCounter;
   
    //------------------internal use only
    ORFileMoverOp*  fpgaFileMover;
    NSOperationQueue*	fileQueue;
    BOOL            initializationRunning;
    BOOL            slaveRoutersToMasterRunning;
    short           initializationState;
    unsigned short  connectedRouterMask;
    unsigned short  connectedDigitizerMask;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian;
- (void) registerNotificationObservers;
- (void) runAboutToStart:(NSNotification*)aNote;

#pragma mark ***Accessors
- (unsigned short) diagnosticCounter;
- (void) setDiagnosticCounter:(unsigned short)aDiagnosticCounter;
- (short) initState;
- (void) setInitState:(short)aState;
- (NSString*) initStateName;

- (unsigned short) inputLinkMask;
- (void) setInputLinkMask:(unsigned short)aMask;
- (unsigned short) serdesTPowerMask;
- (void) setSerdesTPowerMask:(unsigned short)aMask;
- (unsigned short) serdesRPowerMask;
- (void) setSerdesRPowerMask:(unsigned short)aMask;
- (unsigned short) lvdsPreemphasisCtlMask;
- (void) setLvdsPreemphasisCtlMask:(unsigned short)aMask;
- (unsigned short)miscCtl1Reg;
- (void) setMiscCtl1Reg:(unsigned short)aValue;
- (unsigned short)miscStatReg;
- (void) setMiscStatReg:(unsigned short)aValue;
- (unsigned short)linkLruCrlReg;
- (void) setLinkLruCrlReg:(unsigned short)aValue;
- (unsigned short)linkLockedReg;
- (void) setLinkLockedReg:(unsigned short)aValue;
- (BOOL)clockUsingLLink;
- (void) setClockUsingLLink:(BOOL)aValue;

- (BOOL) downLoadMainFPGAInProgress;
- (void) setDownLoadMainFPGAInProgress:(BOOL)aState;
- (short) fpgaDownProgress;
- (NSString*) mainFPGADownLoadState;
- (void) setMainFPGADownLoadState:(NSString*)aMainFPGADownLoadState;
- (NSString*) fpgaFilePath;
- (void) setFpgaFilePath:(NSString*)aFpgaFilePath;
- (NSString*) firmwareStatusString;
- (void) setFirmwareStatusString:(NSString*)aFirmwareStatusString;
- (void) startDownLoadingMainFPGA;
- (void) stopDownLoadingMainFPGA;

- (ORConnector*) linkConnector:(int)index;
- (void) setLink:(int)index connector:(ORConnector*)aConnector;

- (BOOL) isMaster;
- (void) setIsMaster:(BOOL)aIsMaster;
- (int) registerIndex;
- (void) setRegisterIndex:(int)aRegisterIndex;
- (unsigned short) regWriteValue;
- (void) setRegWriteValue:(unsigned short)aWriteValue;

#pragma mark •••set up routines
- (void) initClockDistribution;
- (BOOL) systemAllLocked;
- (unsigned short)findRouterMask;
- (unsigned short)findDigitizerMask;
- (void) readDisplayRegs;

- (void) stepMaster;
- (void) stepRouter;
- (void) setRoutersToIdle;
- (BOOL) allRoutersIdle;


// Register access
- (void) writeToAddress:(unsigned long)anAddress aValue:(unsigned short)aValue;
- (unsigned short) readFromAddress:(unsigned long)anAddress;
- (void) dumpFpgaRegisters;
- (void) dumpRegisters;
- (void) testSandBoxRegisters;
- (void) testSandBoxRegister:(int)anOffset;
- (NSString*) registerNameAt:(unsigned int)index;
- (unsigned long) registerOffsetAt:(unsigned int)index;
- (unsigned short) readRegister:(unsigned int)index;
- (void) writeRegister:(unsigned int)index withValue:(unsigned short)value;
- (BOOL) canReadRegister:(unsigned int)index;
- (BOOL) canWriteRegister:(unsigned int)index;

#pragma mark •••Hardware Access
- (unsigned short) readCodeRevision;
- (unsigned short) readCodeDate;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORGretinaTriggerModelDiagnosticCounterChanged;
extern NSString* ORGretinaTriggerModelInputLinkMaskChanged;
extern NSString* ORGretinaTriggerSerdesTPowerMaskChanged;
extern NSString* ORGretinaTriggerSerdesRPowerMaskChanged;
extern NSString* ORGretinaTriggerLvdsPreemphasisCtlMask;
extern NSString* ORGretinaTriggerSettingsLock;
extern NSString* ORGretinaTriggerRegisterLock;
extern NSString* ORGretinaTriggerRegisterIndexChanged;
extern NSString* ORGretinaTriggerRegisterWriteValueChanged;
extern NSString* ORGretinaTriggerModelIsMasterChanged;
extern NSString* ORGretinaTriggerMainFPGADownLoadInProgressChanged;
extern NSString* ORGretinaTriggerFPGADownLoadStateChanged;
extern NSString* ORGretinaTriggerFpgaFilePathChanged;
extern NSString* ORGretinaTriggerMainFPGADownLoadInProgressChanged;
extern NSString* ORGretinaTriggerFirmwareStatusStringChanged;
extern NSString* ORGretinaTriggerMainFPGADownLoadStateChanged;
extern NSString* ORGretinaTriggerFpgaDownProgressChanged;
extern NSString* ORGretinaTriggerMiscCtl1RegChanged;
extern NSString* ORGretinaTriggerMiscStatRegChanged;
extern NSString* ORGretinaTriggerLinkLruCrlRegChanged;
extern NSString* ORGretinaTriggerLinkLockedRegChanged;
extern NSString* ORGretinaTriggerClockUsingLLinkChanged;
extern NSString* ORGretinaTriggerModelInitStateChanged;

