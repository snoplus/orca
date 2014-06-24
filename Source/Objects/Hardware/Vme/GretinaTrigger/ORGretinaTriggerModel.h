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
	kMainFPGAControl,			//[0] Main Digitizer FPGA configuration register
	kMainFPGAStatus,			//[1] Main Digitizer FPGA status register
	kVoltageAndTemperature,		//[2] Voltage and Temperature Status
	kVMEGPControl,				//[3] General Purpose VME Control Settings
	kVMETimeoutValue,			//[4] VME Timeout Value Register
	kVMEFPGAVersionStatus,		//[5] VME Version/Status
	kVMEFPGASandbox1,			//[6] VME FPGA Sandbox Register Block
	kVMEFPGASandbox2,			//[7] VME FPGA Sandbox Register Block
	kVMEFPGASandbox3,			//[8] VME FPGA Sandbox Register Block
	kVMEFPGASandbox4,			//[9] VME FPGA Sandbox Register Block
	kFlashAddress,				//[10] Flash Address
	kFlashDataWithAddrIncr,		//[11] Flash Data with Auto-increment address
	kFlashData,					//[12] Flash Data
	kFlashCommandRegister,		//[13] Flash Command Register
	kNumberOfFPGARegisters
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
    kRunSteps4a4c,
    kWaitOnSteps4a4c,
    kStep4a,
    kStep4b,
    kStepError,
};


#define kResetLinkInitMachBit (0x1<<2)
#define kClockSourceSelectBit (0x1<<15)
#define kLinkInitStateMask    (0x0f00)

@interface ORGretinaTriggerModel : ORVmeIOCard
{
  @private
	NSThread*		fpgaProgrammingThread;
	ORConnector*    linkConnector[11]; //we won't draw these connectors so we have to keep references to them
	BOOL            isMaster;
    unsigned long   registerWriteValue;
    int             registerIndex;
    unsigned long   inputLinkMask;
    unsigned long   serdesTPowerMask;
    unsigned long   serdesRPowerMask;
    unsigned long   lvdsPreemphasisCtlMask;
    unsigned long   miscCtl1Reg;
    unsigned long   miscStatReg;
    unsigned long   linkLruCrlReg;
    unsigned long   linkLockedReg;
    BOOL            clockUsingLLink;
    NSString*       mainFPGADownLoadState;
    NSString*       fpgaFilePath;
	BOOL            stopDownLoadingMainFPGA;
	BOOL            downLoadMainFPGAInProgress;
    int             fpgaDownProgress;
	NSLock*         progressLock;
    NSString*       firmwareStatusString;
    unsigned long   diagnosticCounter;
   
    //------------------internal use only
    ORFileMoverOp*  fpgaFileMover;
    NSOperationQueue*	fileQueue;
    BOOL            initializationRunning;
    BOOL            slaveRoutersToMasterRunning;
    short           initializationState;
    unsigned short  connectedRouterMask;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian;

#pragma mark ***Accessors
- (unsigned long) diagnosticCounter;
- (void) setDiagnosticCounter:(unsigned long)aDiagnosticCounter;
- (short) initState;
- (void) setInitState:(short)aState;
- (NSString*) initStateName;

- (unsigned long) inputLinkMask;
- (void) setInputLinkMask:(unsigned long)aMask;
- (unsigned long) serdesTPowerMask;
- (void) setSerdesTPowerMask:(unsigned long)aMask;
- (unsigned long) serdesRPowerMask;
- (void) setSerdesRPowerMask:(unsigned long)aMask;
- (unsigned long) lvdsPreemphasisCtlMask;
- (void) setLvdsPreemphasisCtlMask:(unsigned long)aMask;
- (unsigned long)miscCtl1Reg;
- (void) setMiscCtl1Reg:(unsigned long)aValue;
- (unsigned long)miscStatReg;
- (void) setMiscStatReg:(unsigned long)aValue;
- (unsigned long)linkLruCrlReg;
- (void) setLinkLruCrlReg:(unsigned long)aValue;
- (unsigned long)linkLockedReg;
- (void) setLinkLockedReg:(unsigned long)aValue;
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
- (unsigned long) registerWriteValue;
- (void) setRegisterWriteValue:(unsigned long)aWriteValue;

#pragma mark •••set up routines
- (void) initAsOneMasterOneRouter;
- (unsigned long)findRouterMask;
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

@interface NSObject (Gretina4M)
- (NSString*) IPNumber;
- (NSString*) userName;
- (NSString*) passWord;
- (SBC_Link*) sbcLink;
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

