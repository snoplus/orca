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

#define kResetLinkInitMachBit (0x1<<2)
#define kLinkInitStateMask    (0x0f00)

@interface ORGretinaTriggerModel : ORVmeIOCard
{
  @private
	ORConnector*    linkConnector[11]; //we won't draw these connectors so we have to keep references to them
	BOOL            isMaster;
    unsigned long   registerWriteValue;
    int             registerIndex;
    unsigned long   inputLinkMask;
    unsigned long   serdesTPowerMask;
    unsigned long   serdesRPowerMask;
    unsigned long   lvdsPreemphasisCtlMask;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian;

#pragma mark ***Accessors
- (unsigned long) inputLinkMask;
- (void) setInputLinkMask:(unsigned long)aMask;
- (unsigned long) serdesTPowerMask;
- (void) setSerdesTPowerMask:(unsigned long)aMask;
- (unsigned long) serdesRPowerMask;
- (void) setSerdesRPowerMask:(unsigned long)aMask;
- (unsigned long) lvdsPreemphasisCtlMask;
- (void) setLvdsPreemphasisCtlMask:(unsigned long)aMask;

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
- (void) slaveToMaster;
- (unsigned long)findRouters;

// Register access
- (NSString*) registerNameAt:(unsigned int)index;
- (unsigned long) readRegister:(unsigned int)index;
- (void) writeRegister:(unsigned int)index withValue:(unsigned long)value;
- (BOOL) canReadRegister:(unsigned int)index;
- (BOOL) canWriteRegister:(unsigned int)index;

#pragma mark •••Hardware Access
- (unsigned long) readCodeRevision;
- (unsigned long) readCodeDate;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORGretinaTriggerModelInputLinkMaskChanged;
extern NSString* ORGretinaTriggerSerdesTPowerMaskChanged;
extern NSString* ORGretinaTriggerSerdesRPowerMaskChanged;
extern NSString* ORGretinaTriggerLvdsPreemphasisCtlMask;
extern NSString* ORGretinaTriggerSettingsLock;
extern NSString* ORGretinaTriggerRegisterLock;
extern NSString* ORGretinaTriggerRegisterIndexChanged;
extern NSString* ORGretinaTriggerRegisterWriteValueChanged;
extern NSString* ORGretinaTriggerModelIsMasterChanged;
