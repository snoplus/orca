//-------------------------------------------------------------------------
//  ORGretina4AModel.m
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

#pragma mark - Imported Files
#import "ORGretina4AModel.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORVmeTests.h"
#import "ORFileMoverOp.h"
#import "MJDCmds.h"
#import "ORRunModel.h"

#define kCurrentFirmwareVersion 0x10
#define kFPGARemotePath @"GretinaFPGA.bin"

NSString* ORGretina4ARegisterIndexChanged               = @"ORGretina4ARegisterIndexChanged";
NSString* ORGretina4ASelectedChannelChanged             = @"ORGretina4ASelectedChannelChanged";
NSString* ORGretina4ARegisterWriteValueChanged          = @"ORGretina4ARegisterWriteValueChanged";
NSString* ORGretina4ASPIWriteValueChanged               = @"ORGretina4ASPIWriteValueChanged";
NSString* ORGretina4AFpgaDownProgressChanged            = @"ORGretina4AFpgaDownProgressChanged";
NSString* ORGretina4AMainFPGADownLoadStateChanged		= @"ORGretina4AMainFPGADownLoadStateChanged";
NSString* ORGretina4AFpgaFilePathChanged				= @"ORGretina4AFpgaFilePathChanged";
NSString* ORGretina4ANoiseFloorIntegrationTimeChanged	= @"ORGretina4ANoiseFloorIntegrationTimeChanged";
NSString* ORGretina4ANoiseFloorOffsetChanged            = @"ORGretina4ANoiseFloorOffsetChanged";
NSString* ORGretina4ARateGroupChangedNotification       = @"ORGretina4ARateGroupChangedNotification";
NSString* ORGretina4ANoiseFloorChanged                  = @"ORGretina4ANoiseFloorChanged";
NSString* ORGretina4AFIFOCheckChanged                   = @"ORGretina4AFIFOCheckChanged";
NSString* ORGretina4AModelFirmwareStatusStringChanged	= @"ORGretina4AModelFirmwareStatusStringChanged";


NSString* ORGretina4AModelInitStateChanged              = @"ORGretina4AModelInitStateChanged";
NSString* ORGretina4ACardInited                         = @"ORGretina4ACardInited";

NSString* ORGretina4AForceFullCardInitChanged           = @"ORGretina4AForceFullCardInitChanged";
NSString* ORGretina4AForceFullInitChanged               = @"ORGretina4AForceFullInitChanged";
NSString* ORGretina4AEnabledChanged                     = @"ORGretina4AEnabledChanged";

NSString* ORGretina4AMainFPGADownLoadInProgressChanged	= @"ORGretina4AMainFPGADownLoadInProgressChanged";
NSString* ORGretina4ASettingsLock                       = @"ORGretina4ASettingsLock";
NSString* ORGretina4ARegisterLock                       = @"ORGretina4ARegisterLock";
NSString* ORGretina4ALockChanged                        = @"ORGretina4ALockChanged";

NSString* ORGretina4AFirmwareVersionChanged             = @"ORGretina4AFirmwareVersionChanged";
NSString* ORGretina4AAcqDcmCtrlStatusChanged            = @"ORGretina4AAcqDcmCtrlStatusChanged";
NSString* ORGretina4AAcqDcmLockChanged                  = @"ORGretina4AAcqDcmLockChanged";
NSString* ORGretina4AAcqDcmResetChanged                 = @"ORGretina4AAcqDcmResetChanged";
NSString* ORGretina4AAcqPhShiftOverflowChanged          = @"ORGretina4AAcqPhShiftOverflowChanged";
NSString* ORGretina4AAcqDcmClockStoppedChanged          = @"ORGretina4AAcqDcmClockStoppedChanged";
NSString* ORGretina4AAdcDcmCtrlStatusChanged            = @"ORGretina4AAdcDcmCtrlStatusChanged";
NSString* ORGretina4AAdcDcmLockChanged                  = @"ORGretina4AAdcDcmLockChanged";
NSString* ORGretina4AAdcDcmResetChanged                 = @"ORGretina4AAdcDcmResetChanged";
NSString* ORGretina4AAdcPhShiftOverflowChanged          = @"ORGretina4AAdcPhShiftOverflowChanged";
NSString* ORGretina4AAdcDcmClockStoppedChanged          = @"ORGretina4AAdcDcmClockStoppedChanged";
NSString* ORGretina4AUserPackageDataChanged             = @"ORGretina4AUserPackageDataChanged";
NSString* ORGretina4ARouterVetoEn0Changed               = @"ORGretina4ARouterVetoEn0Changed";
NSString* ORGretina4APreampResetDelayEnChanged          = @"ORGretina4APreampResetDelayEnChanged";
NSString* ORGretina4ADecimationFactorChanged            = @"ORGretina4ADecimationFactorChanged";
NSString* ORGretina4APileupMode0Changed                 = @"ORGretina4APileupMode0Changed";
NSString* ORGretina4ADroppedEventCountModeChanged       = @"ORGretina4ADroppedEventCountModeChanged";
NSString* ORGretina4AEventCountModeChanged              = @"ORGretina4AEventCountModeChanged";
NSString* ORGretina4AAHitCountModeChanged               = @"ORGretina4AAHitCountModeChanged";
NSString* ORGretina4ADiscCountModeChanged               = @"ORGretina4ADiscCountModeChanged";
NSString* ORGretina4AEventExtensionModeChanged          = @"ORGretina4AEventExtensionModeChanged";
NSString* ORGretina4AWriteFlagChanged                   = @"ORGretina4AWriteFlagChanged";
NSString* ORGretina4APileupExtensionModeChanged         = @"ORGretina4APileupExtensionModeChanged";
NSString* ORGretina4ACounterResetChanged                = @"ORGretina4ACounterResetChanged";
NSString* ORGretina4APileupWaveformOnlyModeChanged      = @"ORGretina4APileupWaveformOnlyModeChanged";
NSString* ORGretina4ALedThreshold0Changed               = @"ORGretina4ALedThreshold0Changed";
NSString* ORGretina4APreampResetDelay0Changed           = @"ORGretina4APreampResetDelay0Changed";
NSString* ORGretina4ACFDFractionChanged                 = @"ORGretina4ACFDFractionChanged";
NSString* ORGretina4ARawDataLengthChanged               = @"ORGretina4ARawDataLengthChanged";
NSString* ORGretina4ARawDataWindowChanged               = @"ORGretina4ARawDataWindowChanged";
NSString* ORGretina4ADWindowChanged                     = @"ORGretina4ADWindowChanged";
NSString* ORGretina4AKWindowChanged                     = @"ORGretina4AKWindowChanged";
NSString* ORGretina4AMWindowChanged                     = @"ORGretina4AMWindowChanged";
NSString* ORGretina4AD3WindowChanged                    = @"ORGretina4AD3WindowChanged";
NSString* ORGretina4ADiscWidthChanged                   = @"ORGretina4ADiscWidthChanged";
NSString* ORGretina4ABaselineStartChanged               = @"ORGretina4ABaselineStart0Changed";
NSString* ORGretina4ABaselineDelayChanged               = @"ORGretina4ABaselineDelayChanged";
NSString* ORGretina4AP1WindowChanged                    = @"ORGretina4AP1WindowChanged";
NSString* ORGretina4AP2WindowChanged                    = @"ORGretina4AP2WindowChanged";
NSString* ORGretina4ADacChannelSelectChanged            = @"ORGretina4ADacChannelSelectChanged";
NSString* ORGretina4ADacAttenuationChanged              = @"ORGretina4ADacAttenuationChanged";
NSString* ORGretina4AIlaConfigChanged                   = @"ORGretina4AIlaConfigChanged";
NSString* ORGretina4APhaseHuntChanged                   = @"ORGretina4APhaseHuntChanged";
NSString* ORGretina4ALoadbaselineChanged                = @"ORGretina4ALoadbaselineChanged";
NSString* ORGretina4APhaseHuntDebugChanged              = @"ORGretina4APhaseHuntDebugChanged";
NSString* ORGretina4APhaseHuntProceedChanged            = @"ORGretina4APhaseHuntProceedChanged";
NSString* ORGretina4APhaseDecChanged                    = @"ORGretina4APhaseDecChanged";
NSString* ORGretina4APhaseIncChanged                    = @"ORGretina4APhaseIncChanged";
NSString* ORGretina4ASerdesPhaseIncChanged              = @"ORGretina4ASerdesPhaseIncChanged";
NSString* ORGretina4ASerdesPhaseDecChanged              = @"ORGretina4ASerdesPhaseDecChanged";
NSString* ORGretina4ADiagMuxControlChanged              = @"ORGretina4ADiagMuxControlChanged";
NSString* ORGretina4APeakSensitivityChanged             = @"ORGretina4APeakSensitivityChanged";
NSString* ORGretina4ADiagInputChanged                   = @"ORGretina4ADiagInputChanged";
NSString* ORGretina4ADiagChannelEventSelChanged         = @"ORGretina4ADiagChannelEventSelChanged";
NSString* ORGretina4ARj45SpareIoMuxSelChanged           = @"ORGretina4ARj45SpareIoMuxSelChanged";
NSString* ORGretina4ARj45SpareIoDirChanged              = @"ORGretina4ARj45SpareIoDirChanged";
NSString* ORGretina4ALedStatusChanged                   = @"ORGretina4ALedStatusChanged";
NSString* ORGretina4ALiveTimestampLsbChanged            = @"ORGretina4ALiveTimestampLsbChanged";
NSString* ORGretina4ALiveTimestampMsbChanged            = @"ORGretina4ALiveTimestampMsbChanged";
NSString* ORGretina4ADiagIsyncChanged                   = @"ORGretina4ADiagIsyncChanged";
NSString* ORGretina4ASerdesSmLostLockChanged            = @"ORGretina4ASerdesSmLostLockChanged";
NSString* ORGretina4AOverflowFlagChanChanged            = @"ORGretina4AOverflowFlagChanChanged";
NSString* ORGretina4ATriggerConfigChanged               = @"ORGretina4ATriggerConfigChanged";
NSString* ORGretina4APhaseErrorCountChanged             = @"ORGretina4APhaseErrorCountChanged";
NSString* ORGretina4APhaseStatusChanged                 = @"ORGretina4APhaseStatusChanged";
NSString* ORGretina4APhase0Changed                      = @"ORGretina4APhase0Changed";
NSString* ORGretina4APhase1Changed                      = @"ORGretina4APhase1Changed";
NSString* ORGretina4APhase2Changed                      = @"ORGretina4APhase2Changed";
NSString* ORGretina4APhase3Changed                      = @"ORGretina4APhase3Changed";
NSString* ORGretina4ASerdesPhaseValueChanged            = @"ORGretina4ASerdesPhaseValueChanged";
NSString* ORGretina4APcbRevisionChanged                 = @"ORGretina4APcbRevisionChanged";
NSString* ORGretina4AFwTypeChanged                      = @"ORGretina4AFwTypeChanged";
NSString* ORGretina4AMjrCodeRevisionChanged             = @"ORGretina4AMjrCodeRevisionChanged";
NSString* ORGretina4AMinCodeRevisionChanged             = @"ORGretina4AMinCodeRevisionChanged";
NSString* ORGretina4ACodeDateChanged                    = @"ORGretina4ACodeDateChanged";
NSString* ORGretina4ATSErrCntCtrlChanged                = @"ORGretina4ATSErrCntCtrlChanged";
NSString* ORGretina4ATSErrorCountChanged                = @"ORGretina4ATSErrorCountChanged";
NSString* ORGretina4ADroppedEventCountChanged           = @"ORGretina4ADroppedEventCountChanged";
NSString* ORGretina4AAcceptedEventCountChanged          = @"ORGretina4AAcceptedEventCountChanged";
NSString* ORGretina4AAhitCountChanged                   = @"ORGretina4AAhitCountChanged";
NSString* ORGretina4ADiscCountChanged                   = @"ORGretina4ADiscCountChanged";
NSString* ORGretina4AAuxIoReadChanged                   = @"ORGretina4AAuxIoReadChanged";
NSString* ORGretina4AAuxIoWriteChanged                  = @"ORGretina4AAuxIoWriteChanged";
NSString* ORGretina4AAuxIoConfigChanged                 = @"ORGretina4AAuxIoConfigChanged";
NSString* ORGretina4ASdPemChanged                       = @"ORGretina4ASdPemChanged";
NSString* ORGretina4ASdSmLostLockFlagChanged            = @"ORGretina4ASdSmLostLockFlagChanged";
NSString* ORGretina4AAdcConfigChanged                   = @"ORGretina4AAdcConfigChanged";
NSString* ORGretina4AConfigMainFpgaChanged              = @"ORGretina4AConfigMainFpgaChanged";
NSString* ORGretina4APowerOkChanged                     = @"ORGretina4APowerOkChanged";
NSString* ORGretina4AOverVoltStatChanged                = @"ORGretina4AOverVoltStatChanged";
NSString* ORGretina4AUnderVoltStatChanged               = @"ORGretina4AUnderVoltStatChanged";
NSString* ORGretina4ATemp0SensorChanged                 = @"ORGretina4ATemp0SensorChanged";
NSString* ORGretina4ATemp1SensorChanged                 = @"ORGretina4ATemp1SensorChanged";
NSString* ORGretina4ATemp2SensorChanged                 = @"ORGretina4ATemp2SensorChanged";
NSString* ORGretina4AClkSelect0Changed                  = @"ORGretina4AClkSelect0Changed";
NSString* ORGretina4AClkSelect1Changed                  = @"ORGretina4AClkSelect1Changed";
NSString* ORGretina4AFlashModeChanged                   = @"ORGretina4AFlashModeChanged";
NSString* ORGretina4ASerialNumChanged                   = @"ORGretina4ASerialNumChanged";
NSString* ORGretina4ABoardRevNumChanged                 = @"ORGretina4ABoardRevNumChanged";
NSString* ORGretina4AVhdlVerNumChanged                  = @"ORGretina4AVhdlVerNumChanged";
NSString* ORGretina4AFifoAccessChanged                  = @"ORGretina4AFifoAccessChanged";
NSString* ORGretina4ATriggerPolarityChanged             = @"ORGretina4ATriggerPolarityChanged";
NSString* ORGretina4AWindowCompMinChanged               = @"ORGretina4AWindowCompMinChanged";
NSString* ORGretina4AWindowCompMaxChanged               = @"ORGretina4AWindowCompMaxChanged";

@interface ORGretina4AModel (private)
//firmware loading
- (void) programFlashBuffer:(NSData*)theData;
- (void) programFlashBufferBlock:(NSData*)theData address:(unsigned long)address numberBytes:(unsigned long)numberBytesToWrite;
- (void) blockEraseFlash;
- (void) programFlashBuffer:(NSData*)theData;
- (BOOL) verifyFlashBuffer:(NSData*)theData;
- (void) reloadMainFPGAFromFlash;
- (void) setProgressStateOnMainThread:(NSString*)aState;
- (void) updateDownLoadProgress;
- (void) downloadingMainFPGADone;
- (void) fpgaDownLoadThread:(NSData*)dataFromFile;
- (void) copyFirmwareFileToSBC:(NSString*)firmwarePath;
- (BOOL) controllerIsSBC;
- (void) setFpgaDownProgress:(short)aFpgaDownProgress;
- (void) loadFPGAUsingSBC;
@end


@implementation ORGretina4AModel

#pragma mark - Static Declarations
typedef struct {
    unsigned long offset;
    NSString* name;
    BOOL canRead;
    BOOL canWrite;
    BOOL hasChannels;
    unsigned short enumId;
} Gretina4ARegisterInformation;

static Gretina4ARegisterInformation register_information[kNumberOfGretina4ARegisters] = {
    { 0x0000,	@"Board Id",                YES,	 NO,	 NO,	 kBoardId },
    { 0x0004,	@"Programming Done",        YES,	YES,	 NO,	 kProgrammingDone },
    { 0x0008,	@"External Discrim Src",    YES,	YES,	 NO,	 kExternalDiscSrc },
    { 0x0020,	@"Hardware Status",         YES,	 NO,	 NO,	 kHardwareStatus },
    { 0x0024,	@"User Package Data",       YES,	YES,	 NO,	 kUserPackageData },
    { 0x0028,	@"Window Comp Min",         YES,	YES,	 NO,	 kWindowCompMin },
    { 0x002C,	@"Window Comp Max",         YES,	YES,	 NO,	 kWindowCompMax },
    { 0x0040,	@"Channel Control",         YES,	YES,	 YES,	 kChannelControl },
    { 0x0080,	@"Led Threshold",           YES,	YES,	 YES,	 kLedThreshold },
    { 0x00C0,	@"CFD Fraction",            YES,	YES,	 YES,	 kCFDFraction },
    { 0x0100,	@"Raw Data Length",         YES,	YES,	 YES,	 kRawDataLength },
    { 0x0140,	@"Raw Data Window",         YES,	YES,	 YES,	 kRawDataWindow },
    { 0x0180,	@"D Window",                YES,	YES,	 YES,	 kDWindow },
    { 0x01C0,	@"K Window",                YES,	YES,	 YES,	 kKWindow },
    { 0x0200,	@"M Window",                YES,	YES,	 YES,	 kMWindow },
    { 0x0240,	@"D3 Window",               YES,	YES,	 YES,	 kD3Window },
    { 0x0280,	@"Disc Width",              YES,	YES,	 YES,	 kDiscWidth },
    { 0x02C0,	@"Baseline Start",          YES,	YES,	 NO,	 kBaselineStart },
    { 0x0300,	@"P1 Window",               YES,	YES,	 YES,	 kP1Window },
    { 0x0400,	@"Dac",                     YES,	YES,	 NO,	 kDac },
    { 0x0404,	@"P2 Window",               YES,	YES,	 NO,	 kP2Window },
    { 0x0408,	@"Ila Config",              YES,	YES,	 NO,	 kIlaConfig },
    { 0x040C,	@"Channel Pulsed Control",	 NO,	YES,	 NO,	 kChannelPulsedControl },
    { 0x0410,	@"Diag Mux Control",        YES,	YES,	 NO,	 kDiagMuxControl },
    { 0x0414,	@"Peak Sensitivity",        YES,	YES,	 NO,	 kPeakSensitivity },
    { 0x0418,	@"Baseline Delay",          YES,	YES,	 NO,	 kBaselineDelay },
    { 0x041C,	@"Diag Channel Input",      YES,	YES,	 NO,	 kDiagChannelInput },
    { 0x0420,	@"Ext Discriminator Select",YES,	YES,	 NO,	 kExtDiscSel },
    { 0x0424,	@"Rj45 Spare Dout Control",	YES,	YES,	 NO,	 kRj45SpareDoutControl },
    { 0x0428,	@"Led Status",              YES,     NO,	 NO,	 kLedStatus },
    { 0x0480,	@"Lat Timestamp Lsb",       YES,	 NO,	 NO,	 kLatTimestampLsb },
    { 0x0488,	@"Lat Timestamp Msb",       YES,	 NO,	 NO,	 kLatTimestampMsb },
    { 0x048C,	@"Live Timestamp Lsb",      YES,	 NO,	 NO,	 kLiveTimestampLsb },
    { 0x0490,	@"Live Timestamp Msb",      YES,	 NO,	 NO,	 kLiveTimestampMsb },
    { 0x0494,	@"Veto Gate Width",         YES,	YES,	 NO,	 kVetoGateWidth },
    { 0x0500,	@"Master Logic Status",     YES,	YES,	 NO,	 kMasterLogicStatus },
    { 0x0504,	@"Trigger Config",          YES,	YES,	 NO,	 kTriggerConfig },
    { 0x0508,	@"Phase Error Count",       YES,	 NO,	 NO,	 kPhaseErrorCount },
    { 0x050C,	@"Phase Value",             YES,	 NO,	 NO,	 kPhaseValue },
    { 0x0510,	@"Phase Offset0",           YES,	 NO,	 NO,	 kPhaseOffset0 },
    { 0x0514,	@"Phase Offset1",           YES,	 NO,	 NO,	 kPhaseOffset1 },
    { 0x0518,	@"Phase Offset2",           YES,	 NO,	 NO,	 kPhaseOffset2 },
    { 0x051C,	@"Serdes Phase Value",      YES,	 NO,	 NO,	 kSerdesPhaseValue },
    { 0x0600,	@"Code Revision",           YES,	 NO,	 NO,	 kCodeRevision },
    { 0x0604,	@"Code Date",               YES,	 NO,	 NO,	 kCodeDate },
    { 0x0608,	@"TS Err Cnt Enable",       YES,	YES,	 NO,	 kTSErrCntEnable },
    { 0x060C,	@"TS Error Count",          YES,	 NO,	 NO,	 kTSErrorCount },
    { 0x0700,	@"Dropped Event Count",     YES,	 NO,	YES,	 kDroppedEventCount },
    { 0x0740,	@"Accepted Event Count",	YES,	 NO,	YES,	 kAcceptedEventCount },
    { 0x0780,	@"Ahit Count",              YES,	 NO,	YES,	 kAhitCount },
    { 0x07C0,	@"Disc Count",              YES,	 NO,	YES,	 kDiscCount },
    { 0x0800,	@"Aux IO Read",             YES,	YES,	YES,	 kAuxIORead },
    { 0x0804,	@"Aux IO Write",            YES,	YES,	YES,	 kAuxIOWrite },
    { 0x0808,	@"Aux IO Config",           YES,	YES,	YES,	 kAuxIOConfig },
    { 0x0848,	@"Sd Config",               YES,	YES,	 NO,	 kSdConfig },
    { 0x1000,	@"Fifo",                     NO,     NO,	 NO,	 kFifo },
};

static Gretina4ARegisterInformation fpga_register_information[kNumberOfFPGARegisters] = {
    {0x900,	@"FPGA configuration register", YES, YES, NO, NO},
    {0x904,	@"VME Status register",         YES, NO, NO, NO},
    {0x908,	@"VME Aux Status",              YES, NO, NO, NO},
    {0x910,	@"VME General Purpose Control", YES, YES, NO, NO},
    {0x914,	@"VME Timeout Value Register",  YES, YES, NO, NO},
    {0x920,	@"VME Version/Status",          YES, NO, NO, NO},
    {0x930,	@"VME Sandbox Register1",       YES, YES, NO, NO},
    {0x934,	@"VME Sandbox Register2",       YES, YES, NO, NO},
    {0x938,	@"VME Sandbox Register3",       YES, YES, NO, NO},
    {0x93C,	@"VME Sandbox Register3",       YES, YES, NO, NO},
};

#pragma mark - Boilerplate
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self initParams];
    [self setAddressModifier:0x09];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [firmwareStatusString release];
    [spiConnector release];
    [linkConnector release];
    [mainFPGADownLoadState release];
    [fpgaFilePath release];
    [waveFormRateGroup release];
	[fifoFullAlarm clearAlarm];
	[fifoFullAlarm release];
	[progressLock release];
    [fileQueue cancelAllOperations];
    [fileQueue release];
    [super dealloc];
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"Gretina4ACard"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    int chan;
    float y=73;
    float dy=3;
    NSColor* enabledColor  = [NSColor colorWithCalibratedRed:0.4 green:0.7 blue:0.4 alpha:1];
    NSColor* disabledColor = [NSColor clearColor];
    for(chan=0;chan<kNumGretina4AChannels;chan+=2){
        if(enabled[chan])  [enabledColor  set];
        else			  [disabledColor set];
        [[NSBezierPath bezierPathWithRect:NSMakeRect(5,y,4,dy)] fill];
        
        if(enabled[chan+1])[enabledColor  set];
        else			  [disabledColor set];
        [[NSBezierPath bezierPathWithRect:NSMakeRect(9,y,4,dy)] fill];
        y -= dy;
    }
    [i unlockFocus];
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:OROrcaObjectImageChanged
     object:self];
}

- (void) makeMainController
{
    [self linkToController:@"ORGretina4AController"];
}

- (NSString*) helpURL
{
	return @"VME/Gretina.html";
}

- (Class) guardianClass
{
	return NSClassFromString(@"ORVme64CrateModel");
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,baseAddress+0x1000+0xffff);
}

- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setSpiConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    
	[spiConnector setConnectorImageType:kSmallDot]; 
	[spiConnector setConnectorType: 'SPIO' ];
	[spiConnector addRestrictedConnectionType: 'SPII' ]; //can only connect to SPI inputs
	[spiConnector setOffColor:[NSColor colorWithCalibratedRed:0 green:.68 blue:.65 alpha:1.]];

    [self setLinkConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    
    [linkConnector setSameGuardianIsOK:YES];
	[linkConnector setConnectorImageType:kSmallDot];
	[linkConnector setConnectorType: 'LNKI' ];
	[linkConnector addRestrictedConnectionType: 'LNKO' ]; //can only connect to Link inputs
	[linkConnector setOffColor:[NSColor colorWithCalibratedRed:1 green:1 blue:.3 alpha:1.]];
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [self guardian:guardian positionConnectorsForCard:self];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORVmeCardSlotChangedNotification
	 object: self];
}

- (void) positionConnector:(ORConnector*)aConnector
{
    NSRect aFrame = [aConnector localFrame];
    if(aConnector == spiConnector){
        float x =  17 + [self slot] * 16*.62 ;
        float y =  78;
        aFrame.origin = NSMakePoint(x,y);
        [aConnector setLocalFrame:aFrame];
    }
    else if(aConnector == linkConnector){
        float x =  17 + [self slot] * 16*.62 ;
        float y =  100;
        aFrame.origin = NSMakePoint(x,y);
        [aConnector setLocalFrame:aFrame];
    }
}

- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
	
	[super setGuardian:aGuardian];
	
    if(oldGuardian != aGuardian){
        [oldGuardian removeDisplayOf:spiConnector];
        [oldGuardian removeDisplayOf:linkConnector];
    }
	
    [aGuardian assumeDisplayOf:spiConnector];
    [aGuardian assumeDisplayOf:linkConnector];
    [self guardian:aGuardian positionConnectorsForCard:self];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    [aGuardian positionConnector:spiConnector forCard:self];
    [aGuardian positionConnector:linkConnector forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:spiConnector];
    [aGuardian removeDisplayOf:linkConnector];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:spiConnector];
    [aGuardian assumeDisplayOf:linkConnector];
}

- (void) disconnect
{
    [spiConnector disconnect];
    [linkConnector disconnect];
    [super disconnect];
}

- (unsigned long) baseAddress
{
    return (([self slot]+1)&0x1f)<<20;
}

#pragma mark - Accessors


- (ORConnector*) linkConnector
{
    return linkConnector;
}

- (void) setLinkConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [linkConnector release];
    linkConnector = aConnector;
}

- (ORConnector*) spiConnector
{
    return spiConnector;
}

- (void) setSpiConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [spiConnector release];
    spiConnector = aConnector;
}

#pragma mark - Low-level registers and diagnostics
- (unsigned long) spiWriteValue
{
    return spiWriteValue;
}

- (void) setSPIWriteValue:(unsigned long)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSPIWriteValue:spiWriteValue];
    spiWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASPIWriteValueChanged object:self];
}

- (short) registerIndex
{
    return registerIndex;
}

- (void) setRegisterIndex:(int)aRegisterIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterIndex:registerIndex];
    registerIndex = aRegisterIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARegisterIndexChanged object:self];
}

- (unsigned long) registerWriteValue
{
    return registerWriteValue;
}

- (void) setRegisterWriteValue:(unsigned long)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterWriteValue:registerWriteValue];
    registerWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARegisterWriteValueChanged object:self];
}
- (unsigned long) selectedChannel
{
    return selectedChannel;
}

- (void) setSelectedChannel:(unsigned short)aChannel
{
    if(aChannel >= kNumGretina4AChannels) aChannel = kNumGretina4AChannels - 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedChannel:selectedChannel];
    selectedChannel = aChannel;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASelectedChannelChanged object:self];
}
- (NSString*) registerNameAt:(unsigned int)index
{
	if (index >= kNumberOfGretina4ARegisters) return @"";
	return register_information[index].name;
}

- (unsigned short) registerOffsetAt:(unsigned int)index
{
	if (index >= kNumberOfGretina4ARegisters) return 0;
	return register_information[index].offset;
}
- (unsigned short) registerEnumAt:(unsigned int)index
{
    if (index >= kNumberOfGretina4ARegisters) return @"";
    return register_information[index].enumId;
}

- (NSString*) fpgaRegisterNameAt:(unsigned int)index
{
	if (index >= kNumberOfFPGARegisters) return @"";
	return fpga_register_information[index].name;
}

- (unsigned short) fpgaRegisterOffsetAt:(unsigned int)index
{
	if (index >= kNumberOfFPGARegisters) return 0;
	return fpga_register_information[index].offset;
}

- (unsigned long) readRegister:(unsigned int)index
{
	if (index >= kNumberOfGretina4ARegisters) return -1;
	if (![self canReadRegister:index]) return -1;
	unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[index].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}

- (void) writeRegister:(unsigned int)index withValue:(unsigned long)value
{
	if (index >= kNumberOfGretina4ARegisters) return;
	if (![self canWriteRegister:index]) return;
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + register_information[index].offset
                         numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];	
}

- (void) writeToAddress:(unsigned long)anAddress aValue:(unsigned long)aValue
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + anAddress
                        numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
    
}

- (unsigned long) readFromAddress:(unsigned long)anAddress
{
    unsigned long value = 0;
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + anAddress
                        numToRead:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
    return value;
}
- (BOOL) hasChannels:(unsigned int)index
{
    if (index >= kNumberOfGretina4ARegisters) return NO;
    return register_information[index].hasChannels;
}
- (BOOL) canReadRegister:(unsigned int)index
{
	if (index >= kNumberOfGretina4ARegisters) return NO;
	return register_information[index].canRead;
}

- (BOOL) canWriteRegister:(unsigned int)index
{
	if (index >= kNumberOfGretina4ARegisters) return NO;
	return register_information[index].canWrite;
}

- (unsigned long) readFPGARegister:(unsigned int)index;
{
	if (index >= kNumberOfFPGARegisters) return -1;
	if (![self canReadFPGARegister:index]) return -1;
	unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + fpga_register_information[index].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}

- (void) writeFPGARegister:(unsigned int)index withValue:(unsigned long)value
{
	if (index >= kNumberOfFPGARegisters) return;
	if (![self canWriteFPGARegister:index]) return;
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + fpga_register_information[index].offset
                         numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];	
}

- (BOOL) canReadFPGARegister:(unsigned int)index
{
	if (index >= kNumberOfFPGARegisters) return NO;
	return fpga_register_information[index].canRead;
}

- (BOOL) canWriteFPGARegister:(unsigned int)index
{
	if (index >= kNumberOfFPGARegisters) return NO;
	return fpga_register_information[index].canWrite;
}


- (void) snapShotRegisters
{
    int i;
    for(i=0;i<kNumberOfGretina4ARegisters;i++){
        snapShot[i] = [self readRegister:i];
    }
    
    for(i=0;i<kNumberOfFPGARegisters;i++){
        fpgaSnapShot[i] = [self readFPGARegister:i];
    }
}

- (void) compareToSnapShot
{
    NSLog(@"------------------------------------------------\n");
    NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"offset   snapshot        newest\n");
    
    int i;
    for(i=0;i<kNumberOfGretina4ARegisters;i++){
        unsigned long theValue = [self readRegister:i];
        if(snapShot[i] != theValue){
            NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"0x%04x 0x%08x != 0x%08x %@\n",register_information[i].offset,snapShot[i],theValue,register_information[i].name);
            
        }
    }
    
    for(i=0;i<kNumberOfFPGARegisters;i++){
        unsigned long theValue = [self readFPGARegister:i];
        if(fpgaSnapShot[i] != theValue){
            NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"0x%04x 0x%08x != 0x%08x %@\n",register_information[i].offset,fpgaSnapShot[i],theValue,register_information[i].name);
            
        }
    }
    NSLog(@"------------------------------------------------\n");
    
}

- (void) dumpAllRegisters
{
    NSLog(@"------------------------------------------------\n");
    NSLog(@"Register Values for Channel #1\n");
    int i;
    for(i=0;i<kNumberOfGretina4ARegisters;i++){
        unsigned long theValue = [self readRegister:i];
        NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"0x%04x 0x%08x %@\n",register_information[i].offset,theValue,register_information[i].name);
        snapShot[i] = theValue;
        
    }
    NSLog(@"------------------------------------------------\n");
    
    for(i=0;i<kNumberOfFPGARegisters;i++){
        unsigned long theValue = [self readFPGARegister:i];
        NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"0x%04x 0x%08x %@\n",fpga_register_information[i].offset,theValue,fpga_register_information[i].name);
        
        fpgaSnapShot[i] = theValue;
    }
}

#pragma mark - Firmware loading
- (BOOL) downLoadMainFPGAInProgress
{
	return downLoadMainFPGAInProgress;
}

- (void) setDownLoadMainFPGAInProgress:(BOOL)aState
{
	downLoadMainFPGAInProgress = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AMainFPGADownLoadInProgressChanged object:self];	
}

- (short) fpgaDownProgress
{
	int temp;
	[progressLock lock];
    temp = fpgaDownProgress;
	[progressLock unlock];
    return temp;
}

- (NSString*) mainFPGADownLoadState
{
	if(!mainFPGADownLoadState) return @"--";
    else return mainFPGADownLoadState;
}

- (void) setMainFPGADownLoadState:(NSString*)aMainFPGADownLoadState
{
	if(!aMainFPGADownLoadState) aMainFPGADownLoadState = @"--";
    [mainFPGADownLoadState autorelease];
    mainFPGADownLoadState = [aMainFPGADownLoadState copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AMainFPGADownLoadStateChanged object:self];
}

- (NSString*) fpgaFilePath
{
    return fpgaFilePath;
}

- (void) setFpgaFilePath:(NSString*)aFpgaFilePath
{
	if(!aFpgaFilePath)aFpgaFilePath = @"";
    [fpgaFilePath autorelease];
    fpgaFilePath = [aFpgaFilePath copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFpgaFilePathChanged object:self];
}

- (void) startDownLoadingMainFPGA
{
    if(!progressLock)progressLock = [[NSLock alloc] init];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFpgaDownProgressChanged object:self];
    
    stopDownLoadingMainFPGA = NO;
    
    //to minimize disruptions to the download thread we'll check and update the progress from the main thread via a timer.
    fpgaDownProgress = 0;
    
    if(![self controllerIsSBC]){
        [self setDownLoadMainFPGAInProgress: YES];
        [self updateDownLoadProgress];
        NSLog(@"Gretina4A (%d) beginning firmware load via Mac, File: %@\n",[self uniqueIdNumber],fpgaFilePath);
        
        [NSThread detachNewThreadSelector:@selector(fpgaDownLoadThread:) toTarget:self withObject:[NSData dataWithContentsOfFile:fpgaFilePath]];
    }
    else {
        if([[[self adapter]sbcLink]isConnected]){
            [self setDownLoadMainFPGAInProgress: YES];
            NSLog(@"Gretina4A (%d) beginning firmware load via SBC, File: %@\n",[self uniqueIdNumber],fpgaFilePath);
            [self copyFirmwareFileToSBC:fpgaFilePath];
        }
        else {
            [self setDownLoadMainFPGAInProgress: NO];
            NSLog(@"Gretina4A (%d) unable to load firmware. SBC not connected.\n",[self uniqueIdNumber]);
        }
    }
}

- (void) tasksCompleted: (NSNotification*)aNote
{
}

- (BOOL) queueIsRunning
{
    return [fileQueue operationCount];
}

- (NSString*) firmwareStatusString
{
    if(!firmwareStatusString)return @"--";
    else return firmwareStatusString;
}

- (void) setFirmwareStatusString:(NSString*)aState
{
    if(!aState)aState = @"--";
    [firmwareStatusString autorelease];
    firmwareStatusString = [aState copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AModelFirmwareStatusStringChanged object:self];
}

- (void) flashFpgaStatus:(ORSBCLinkJobStatus*) jobStatus
{
    [self setDownLoadMainFPGAInProgress: [jobStatus running]];
    [self setFpgaDownProgress:           [jobStatus progress]];
    NSArray* parts = [[jobStatus message] componentsSeparatedByString:@"$"];
    NSString* stateString   = @"";
    NSString* verboseString = @"";
    if([parts count]>=1)stateString   = [parts objectAtIndex:0];
    if([parts count]>=2)verboseString = [parts objectAtIndex:1];
    [self setProgressStateOnMainThread:  stateString];
    [self setFirmwareStatusString:       verboseString];
    [self updateDownLoadProgress];
    if(![jobStatus running]){
        NSLog(@"Gretina4A (%d) firmware load job in SBC finished (%@)\n",[self uniqueIdNumber],[jobStatus finalStatus]?@"Success":@"Failed");
        if([jobStatus finalStatus]){
            [self readFPGAVersions];
            [self checkFirmwareVersion:YES];
        }
    }
    
}

- (void) stopDownLoadingMainFPGA
{
    if(downLoadMainFPGAInProgress){
        if(![self controllerIsSBC]){
            stopDownLoadingMainFPGA = YES;
        }
        else {
            SBC_Packet aPacket;
            aPacket.cmdHeader.destination			= kSBC_Process;//kSBC_Command;//kSBC_Process;
            aPacket.cmdHeader.cmdID					= kSBC_KillJob;
            aPacket.cmdHeader.numberBytesinPayload	= 0;
            
            @try {
                
                //send a kill packet. The response will be a job status record
                [[[self adapter] sbcLink] send:&aPacket receive:&aPacket];
                NSLog(@"Told SBC to stop FPGA load.\n");
                //NSLog(@"Error Code: %s\n",aPacket.message);
                //[NSException raise:@"Xilinx load failed" format:@"%d",errorCode];
                // }
                //else NSLog(@"Looks like success.\n");
            }
            @catch(NSException* localException) {
                NSLog(@"kSBC_KillJob command failed. %@\n",localException);
                [NSException raise:@"kSBC_KillJob command failed" format:@"%@",localException];
            }
            
        }
    }
}

#pragma mark - noise floor
- (BOOL) noiseFloorRunning
{
    return noiseFloorRunning;
}

- (short) noiseFloorOffset
{
    return noiseFloorOffset;
}

- (void) setNoiseFloorOffset:(short)aNoiseFloorOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseFloorOffset:noiseFloorOffset];
    
    noiseFloorOffset = aNoiseFloorOffset;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ANoiseFloorOffsetChanged object:self];
}

- (float) noiseFloorIntegrationTime
{
    return noiseFloorIntegrationTime;
}

- (void) setNoiseFloorIntegrationTime:(float)aNoiseFloorIntegrationTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseFloorIntegrationTime:noiseFloorIntegrationTime];
    
    if(aNoiseFloorIntegrationTime<.01)aNoiseFloorIntegrationTime = .01;
    else if(aNoiseFloorIntegrationTime>5)aNoiseFloorIntegrationTime = 5;
    
    noiseFloorIntegrationTime = aNoiseFloorIntegrationTime;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ANoiseFloorIntegrationTimeChanged object:self];
}

- (void) findNoiseFloors
{
    if(noiseFloorRunning){
        noiseFloorRunning = NO;
    }
    else {
        noiseFloorState = 0;
        noiseFloorRunning = YES;
        [self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:0];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ANoiseFloorOffsetChanged object:self];
}

- (void) stepNoiseFloor
{
    [[self undoManager] disableUndoRegistration];
    
    @try {
        unsigned long val;
        int i;
        
        switch(noiseFloorState){
            case 0: //init
                //disable all channels
                for(i=0;i<kNumGretina4AChannels;i++){
                    oldEnabled[i] = [self enabled:i];
                    [self setEnabled:i withValue:NO];
                    [self writeControlReg:i enabled:NO];
                    oldLedThreshold[i] = [self ledThreshold:i];
                    [self setLedThreshold:i withValue:0x1ffff];
                    newLedThreshold[i] = 0x1ffff;
                }
                [self initBoard];
                noiseFloorWorkingChannel = -1;
                //find first channel
                for(i=0;i<kNumGretina4AChannels;i++){
                    if(oldEnabled[i]){
                        noiseFloorWorkingChannel = i;
                        break;
                    }
                }
                if(noiseFloorWorkingChannel>=0){
                    noiseFloorLow			= 0;
                    noiseFloorHigh		= 0x1FFFF;
                    noiseFloorTestValue	= 0x1FFFF/2;              //Initial probe position
                    [self setLedThreshold:noiseFloorWorkingChannel withValue:noiseFloorHigh];
                    [self writeLedThreshold:noiseFloorWorkingChannel];
                    [self setEnabled:noiseFloorWorkingChannel withValue:YES];
                    [self writeControlReg:noiseFloorWorkingChannel enabled:YES];
                    [self resetFIFO];
                    noiseFloorState = 1;
                }
                else {
                    noiseFloorState = 2; //nothing to do
                }
                break;
                
            case 1:
                if(noiseFloorLow <= noiseFloorHigh) {
                    [self setLedThreshold:noiseFloorWorkingChannel withValue:noiseFloorTestValue];
                    [self writeLedThreshold:noiseFloorWorkingChannel];
                    noiseFloorState = 2;	//go check for data
                }
                else {
                    newLedThreshold[noiseFloorWorkingChannel] = noiseFloorTestValue + noiseFloorOffset;
                    [self setEnabled:noiseFloorWorkingChannel withValue:NO];
                    [self writeControlReg:noiseFloorWorkingChannel enabled:NO];
                    [self setLedThreshold:noiseFloorWorkingChannel withValue:0x1ffff];
                    [self writeLedThreshold:noiseFloorWorkingChannel];
                    noiseFloorState = 3;	//done with this channel
                }
                break;
                
            case 2:
                //read the fifo state
                [[self adapter] readLongBlock:&val
                                    atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                                    numToRead:1
                                   withAddMod:[self addressModifier]
                                usingAddSpace:0x01];
                
                if((val & kGretina4AFIFOEmpty) == 0){
                    //there's some data in fifo so we're too low with the threshold
                    [self setLedThreshold:noiseFloorWorkingChannel withValue:0x1ffff];
                    [self writeLedThreshold:noiseFloorWorkingChannel];
                    [self resetFIFO];
                    noiseFloorLow = noiseFloorTestValue + 1;
                }
                else noiseFloorHigh = noiseFloorTestValue - 1;										//no data so continue lowering threshold
                noiseFloorTestValue = noiseFloorLow+((noiseFloorHigh-noiseFloorLow)/2);     //Next probe position.
                noiseFloorState = 1;	//continue with this channel
                break;
                
            case 3:
                //go to next channel
                noiseFloorLow		= 0;
                noiseFloorHigh		= 0x7FFF;
                noiseFloorTestValue	= 0x7FFF/2;              //Initial probe position
                //find first channel
                int startChan = noiseFloorWorkingChannel+1;
                noiseFloorWorkingChannel = -1;
                for(i=startChan;i<kNumGretina4AChannels;i++){
                    if(oldEnabled[i]){
                        noiseFloorWorkingChannel = i;
                        break;
                    }
                }
                if(noiseFloorWorkingChannel >= startChan){
                    [self setEnabled:noiseFloorWorkingChannel withValue:YES];
                    [self writeControlReg:noiseFloorWorkingChannel enabled:YES];
                    noiseFloorState = 1;
                }
                else {
                    noiseFloorState = 4;
                }
                break;
                
            case 4: //finish up	
                //load new results
                for(i=0;i<kNumGretina4AChannels;i++){
                    [self setEnabled:i withValue:oldEnabled[i]];
                    [self setLedThreshold:i withValue:newLedThreshold[i]];
                }
                [self initBoard];
                
                noiseFloorRunning = NO;
                break;
        }
        if(noiseFloorRunning){
            [self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:noiseFloorIntegrationTime];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ANoiseFloorChanged object:self];
        }
    }
    @catch(NSException* localException) {
        int i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [self setEnabled:i withValue:oldEnabled[i]];
            [self setLedThreshold:i withValue:oldLedThreshold[i]];
        }
        NSLog(@"Gretina4A LED threshold finder quit because of exception\n");
    }
    [[self undoManager] enableUndoRegistration];
}

#pragma mark - rates
- (ORRateGroup*) waveFormRateGroup
{
    return waveFormRateGroup;
}
- (void) setWaveFormRateGroup:(ORRateGroup*)newRateGroup
{
    [newRateGroup retain];
    [waveFormRateGroup release];
    waveFormRateGroup = newRateGroup;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORGretina4ARateGroupChangedNotification
	 object:self];    
}

- (id) rateObject:(short)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

- (unsigned long) getCounter:(short)counterTag forGroup:(short)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumGretina4AChannels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

#pragma mark - Hardware Parameters
- (void) initParams
{
    
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        enabled[i]			= YES;
    }
    fifoResetCount = 0;
}

- (BOOL) forceFullCardInit		{ return forceFullCardInit; }
- (void) setForceFullCardInit:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setForceFullCardInit:forceFullCardInit];
    forceFullCardInit = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AForceFullCardInitChanged object:self];
}

- (BOOL) forceFullInit:(short)chan		{ return forceFullInit[chan]; }
- (void) setForceFullInit:(short)chan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setForceFullInit:chan withValue:forceFullInit[chan]];
    forceFullInit[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AForceFullInitChanged object:self userInfo:userInfo];
}

- (BOOL) enabled:(short)chan			{ return enabled[chan]; }
- (void) setEnabled:(short)chan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:chan withValue:enabled[chan]];
    enabled[chan] = aValue;
    [self setUpImage];
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AEnabledChanged object:self userInfo:userInfo];
}


#pragma mark - Hardware Access
- (void) initBoard
{
    //write the channel level params
    int i;
    for(i=0;i<kNumGretina4AChannels;i++) {
        [self writeMWindow:i];          //only [0] is used
        [self writeKWindow:i];          //only [0] is used
        [self writeDWindow:i];          //only [0] is used
        [self writeD3Window:i];         //only [0] is used
        [self writeLedThreshold:i];
        [self writeControlReg:i enabled:YES];

        [self writeCFDFraction:i];
        [self writeRawDataLength:i];    //only [0] is used
        [self writeRawDataWindow:i];    //only [0] is used
        [self writeP1Window:i];         //only [0] is used
        [self writeDiscWidth:i];        //only [0] is used
        [self writeBaselineStart:i];    //only [0] is used
    }
    //write the card level params
    [self writePeakSensitivity];
    [self writeTriggerConfig];
    [self writeP2Window];
    [self writeBaselineDelay];
    [self writeWindowCompMin];
    [self writeWindowCompMax];

    [self loadWindowDelays];
    
    //enable channels
    [self resetFIFO];
    
    [self writeMasterLogic:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ACardInited object:self];
}

- (void) resetBoard
{
    /* First disable all channels. This does not affect the model state,
     just the board state. */
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [self writeControlReg:i enabled:NO];
    }
    
    [self resetFIFO];
    [self resetMainFPGA];
    [ORTimer delay:6];  // 6 second delay during board reset
}

- (void) resetMainFPGA
{
    unsigned long theValue = 0x10;
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + fpga_register_information[kMainFPGAControl].offset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    sleep(1);
    
    /*
     NSDate* startDate = [NSDate date];
     while(1) {
     // Wait for the SD and DCM to lock
     [[self adapter] readLongBlock:&theValue
     atAddress:[self baseAddress] + register_information[kHardwareStatus].offset
     numToRead:1
     withAddMod:[self addressModifier]
     usingAddSpace:0x01];
     
     if ((theValue & 0x7) == 0x7) break;
     if([[NSDate date] timeIntervalSinceDate:startDate] > 1) {
     NSLog(@"Initializing SERDES timed out (slot %d). \n",[self slot]);
     return;
     }
     }
     */
    
    theValue = 0x00;
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + fpga_register_information[kMainFPGAControl].offset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (BOOL) checkFirmwareVersion
{
    return [self checkFirmwareVersion:NO];
}

- (BOOL) checkFirmwareVersion:(BOOL)verbose
{
    //find out the Main FPGA version
    unsigned long mainVersion = 0x00;
    [[self adapter] readLongBlock:&mainVersion
                        atAddress:[self baseAddress] + register_information[kBoardId].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    //mainVersion = (mainVersion & 0xFFFF0000) >> 16;
    mainVersion = (mainVersion & 0xFFFFF000) >> 12;
    if(verbose)NSLog(@"Main FGPA version: 0x%x \n", mainVersion);
    
    if (mainVersion < kCurrentFirmwareVersion){
        NSLog(@"Main FPGA version does not match: 0x%x is required but 0x%x is loaded.\n", kCurrentFirmwareVersion,mainVersion);
        return NO;
    }
    else return YES;
}

- (unsigned long) readControlReg:(short)channel
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kChannelControl].offset + 4*channel
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return theValue;
}

- (void) writeControlReg:(short)chan enabled:(BOOL)forceEnable
{
    /* writeControlReg writes the current model state to the board.  If forceEnable is NO, *
     * then all the channels are disabled.  Otherwise, the channels are enabled according  *
     * to the model state.                                                                 */
    
    BOOL startStop;
    if(forceEnable)	startStop= enabled[chan];
    else			startStop = NO;
    
    unsigned long theValue =
    (startStop                        << 0)  |
    (pileupMode[chan]                 << 2)  |
    (preampResetDelay[chan]           << 3)  |
    ((triggerPolarity[chan] & 0x3)    << 10) |
    ((decimationFactor & 0x7)         << 12) |
    (writeFlag                        << 15) |
    (droppedEventCountMode[chan]      << 20) |
    (eventCountMode[chan]             << 21) |
    (aHitCountMode[chan]              << 22) |
    (discCountMode[chan]              << 23) |
    ((eventExtensionMode[chan] & 0x3) << 24) |
    (pileupExtensionMode[chan]        << 26) |
    (counterReset[chan]               << 27) |
    (pileupWaveformOnlyMode[chan]     << 30);

    [self writeAndCheckLong:theValue
              addressOffset:register_information[kChannelControl].offset + 4*chan
                       mask:0x4FF00C0D //mask off the reserved bits
                  reportKey:[NSString stringWithFormat:@"ControlStatus_%d",chan]
              forceFullInit:forceFullInit[chan]];

}

- (void) writeMasterLogic:(BOOL)enable
{
    unsigned long theValue =  0x000E0051;
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kMasterLogicStatus].offset
                       mask:0x000E0051 //mask off the reserved bits
                  reportKey:@"masterLogic"
              forceFullInit:YES];
}

- (short) readClockSource
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + fpga_register_information[kVMEGPControl].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue & 0X3;
}

- (void) resetFIFO
{
    
    [self resetSingleFIFO];
    [self resetSingleFIFO];
    
    if(![self fifoIsEmpty]){
        NSLogColor([NSColor redColor], @"%@ Fifo NOT reset properly\n",[self fullID]);
    }
    
}

- (void) resetSingleFIFO
{
    unsigned long val = (0x1<<27); //all other bits are read-only.
    
    [[self adapter] writeLongBlock:&val
                         atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    val = 0;
    
    [[self adapter] writeLongBlock:&val
                         atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (BOOL) fifoIsEmpty
{
    unsigned long val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return ((val>>20) & 0x3)==0x3; //both bits are high if FIFO is empty
}

- (void) readFPGAVersions
{
    //find out the VME FPGA version
	unsigned long vmeVersion = 0x00;
	[[self adapter] readLongBlock:&vmeVersion
                        atAddress:[self baseAddress] + fpga_register_information[kVMEFPGAVersionStatus].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
	NSLog(@"VME FPGA serial number: 0x%x \n", (vmeVersion & 0x0000FFFF));
	NSLog(@"BOARD Revision number: 0x%x \n", ((vmeVersion & 0x00FF0000) >> 16));
	NSLog(@"VME FPGA Version number: 0x%x \n", ((vmeVersion & 0xFF000000) >> 24));
}

- (short) readBoardID
{
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kBoardId].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue & 0xfff;
}

- (void) testRead
{
    unsigned long theValue1 = 0;
    unsigned long theValue2 = 0;
    unsigned long theValue3 = 0;
    
    id myAdapter = [self adapter];
    [myAdapter readLongBlock:&theValue1
                        atAddress:[self baseAddress] + register_information[kBoardId].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];

    [myAdapter readLongBlock:&theValue2
                   atAddress:0x8610
                   numToRead:1
                  withAddMod:0x29
               usingAddSpace:0x01];
    
    [myAdapter readLongBlock:&theValue3
                   atAddress:0x8610
                   numToRead:1
                  withAddMod:0x29
               usingAddSpace:0x01];
    NSLog(@"Gretina: 0x%0x   Shaper1: 0x%0x   Shaper2: 0x%0x\n",theValue1,theValue2,theValue3);
}

- (void) testReadHV
{
    unsigned long theValue1 = 0;
    unsigned long theValue2 = 0;
    unsigned long theValue3 = 0;
    
    id myAdapter = [self adapter];
    [myAdapter readLongBlock:&theValue1
                   atAddress:[self baseAddress] + register_information[kBoardId].offset
                   numToRead:1
                  withAddMod:[self addressModifier]
               usingAddSpace:0x01];
    
    [myAdapter readLongBlock:&theValue2
                   atAddress:0xDD00
                   numToRead:1
                  withAddMod:0x29
               usingAddSpace:0x01];
    
    [myAdapter readLongBlock:&theValue3
                   atAddress:0xDD00
                   numToRead:1
                  withAddMod:0x29
               usingAddSpace:0x01];
    NSLog(@"Gretina: 0x%0x   HV1: 0x%0x   HV2: 0x%0x\n",theValue1,theValue2,theValue3);
}

- (void) loadWindowDelays
{
    unsigned long theValue = 0x105;
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kChannelPulsedControl].offset
                       mask:0x00000fff
                  reportKey:@"PulsedControl"
              forceFullInit:forceFullCardInit];
    
}

- (void) writeLedThreshold:(short)channel
{
    if(channel<0 || channel>kNumGretina4AChannels)return;
    unsigned long theValue = ((preampResetDelay[channel] & 0x000000ff)<<16) | (ledThreshold[channel] & 0x00ffffff);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kLedThreshold].offset + 4*channel
                       mask:0x00ffffff
                  reportKey:[NSString stringWithFormat:@"LedThreshold_%d",channel]
              forceFullInit:forceFullInit[channel]];
    
}

- (void) writeCFDFraction:(short)channel
{
    
    if(channel<0 || channel>kNumGretina4AChannels)return;
    unsigned long theValue = ((unsigned long)(cFDFraction[channel]/100. * 8192)) & 0x1FFF;
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kCFDFraction].offset + 4*channel
                       mask:0x00001fff
                  reportKey:[NSString stringWithFormat:@"CFDFraction_%d",channel]
              forceFullInit:forceFullInit[channel]];
    
}

- (void) writeRawDataLength:(short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel<0 || channel>kNumGretina4AChannels)return;
    unsigned long theValue = (rawDataLength[0] & 0x000007ff);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kRawDataLength].offset + 4*channel
                       mask:0x000007ff
                  reportKey:[NSString stringWithFormat:@"RawDataLength_%d",channel]
              forceFullInit:forceFullInit[channel]];
    
}

- (void) writeRawDataWindow:(short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel<0 || channel>kNumGretina4AChannels)return;
    unsigned long theValue = (rawDataWindow[0] & 0x000007ff);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kRawDataWindow].offset + 4*channel
                       mask:0x000007ff
                  reportKey:[NSString stringWithFormat:@"RawDataWindow_%d",channel]
              forceFullInit:forceFullInit[channel]];
    
}

- (void) writeDWindow:(short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel<0 || channel>kNumGretina4AChannels)return;
    unsigned long theValue = (dWindow[0] & 0x0000007F);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kDWindow].offset + 4*channel
                       mask:0x0000007F
                  reportKey:[NSString stringWithFormat:@"DWindow_%d",channel]
              forceFullInit:forceFullInit[channel]];
    
}

- (void) writeKWindow:(short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel<0 || channel>kNumGretina4AChannels)return;
    unsigned long theValue = (kWindow[0] & 0x0000007F);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kKWindow].offset + 4*channel
                       mask:0x0000007F
                  reportKey:[NSString stringWithFormat:@"KWindow_%d",channel]
              forceFullInit:forceFullInit[channel]];
}

- (void) writeMWindow:(short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel<0 || channel>kNumGretina4AChannels)return;
    unsigned long theValue = (mWindow[0] & 0x000003FF);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kMWindow].offset + 4*channel
                       mask:0x0000007F
                  reportKey:[NSString stringWithFormat:@"MWindow_%d",channel]
              forceFullInit:forceFullInit[channel]];
}

- (void) writeD3Window:(short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel<0 || channel>kNumGretina4AChannels)return;
    unsigned long theValue = (d3Window[0] & 0x0000007F);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kD3Window].offset + 4*channel
                       mask:0x0000007F
                  reportKey:[NSString stringWithFormat:@"D3Window_%d",channel]
              forceFullInit:forceFullInit[channel]];
}

- (void) writeP1Window:(short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel<0 || channel>kNumGretina4AChannels)return;
    unsigned long theValue = (p1Window[0] & 0x0000000F);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kP1Window].offset + 4*channel
                       mask:0x0000007F
                  reportKey:[NSString stringWithFormat:@"P1Window_%d",channel]
              forceFullInit:forceFullInit[channel]];
    
}
- (void) writeP2Window
{
    unsigned long theValue = (p2Window & 0x0000000F);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kP2Window].offset
                       mask:0x000001FF
                  reportKey:@"P2Window"
              forceFullInit:forceFullCardInit];
}

- (void) writeDiscWidth:(short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel<0 || channel>kNumGretina4AChannels)return;
    unsigned long theValue = (discWidth[0] & 0x0000007F);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kDiscWidth].offset + 4*channel
                       mask:0x0000007F
                  reportKey:[NSString stringWithFormat:@"DiscWidth%d",channel]
              forceFullInit:forceFullInit[channel]];
    
}

- (void) writeBaselineStart:(short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel<0 || channel>kNumGretina4AChannels)return;
    unsigned long theValue = (baselineStart[0] & 0x0000007F);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kBaselineStart].offset + 4*channel
                       mask:0x0000007F
                  reportKey:[NSString stringWithFormat:@"BaselineStart%d",channel]
              forceFullInit:forceFullInit[channel]];
    
}
- (void) writeBaselineDelay
{
    unsigned long theValue = (baselineStart[0] & 0x00003fff);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kBaselineDelay].offset
                       mask:0x00003fff
                  reportKey:@"BaselineDelay"
              forceFullInit:forceFullCardInit];
    
}
- (void) writeWindowCompMin
{
    //***NOTE that we only write the first value of the array to all channels
    unsigned long theValue = (windowCompMin & 0x0000ffff);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kWindowCompMin].offset
                       mask:0x0000ffff
                  reportKey:@"WindowCompMin"
              forceFullInit:forceFullCardInit];
    
}
- (void) writeWindowCompMax
{
    //***NOTE that we only write the first value of the array to all channels
    unsigned long theValue = (windowCompMax & 0x0000ffff);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kWindowCompMax].offset
                       mask:0x0000ffff
                  reportKey:@"WindowCompMax"
              forceFullInit:forceFullCardInit];
    
}
- (void) writePeakSensitivity
{
    //***NOTE that we only write the first value of the array to all channels
    unsigned long theValue = (triggerConfig & 0x00000003);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kPeakSensitivity].offset
                       mask:0x00000003
                  reportKey:@"PeakSensitivity"
              forceFullInit:forceFullCardInit];

}
- (void) writeTriggerConfig
{
    //***NOTE that we only write the first value of the array to all channels
    unsigned long theValue = (triggerConfig & 0x00000003);
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kTriggerConfig].offset
                       mask:0x00000003
                  reportKey:@"TriggerConfig"
              forceFullInit:forceFullCardInit];

}

#pragma mark - Clock Sync
- (short) initState {return initializationState;}
- (void) setInitState:(short)aState
{
    initializationState = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AModelInitStateChanged object:self];
}

- (void) stepSerDesInit
{
    int i;
    switch(initializationState){
        case kSerDesSetup:
            [self writeRegister:kMasterLogicStatus  withValue: 0x00000051]; //power up value
            [self writeRegister:kSdConfig           withValue: 0x00001231]; //T/R SerDes off, reset clock manager, reset clocks
            [self setInitState:kSerDesIdle];
            break;
        
        case kSetDigitizerClkSrc:
            [[self undoManager] disableUndoRegistration];
            //[self setClockSource:0];                                //set to external clock (gui only!!!)
            [[self undoManager] enableUndoRegistration];
            [self writeFPGARegister:kVMEGPControl   withValue:0x00 ]; //set to external clock (in HW)
            [self setInitState:kFlushFifo];
            
            break;
            
        case kFlushFifo:
            for(i=0;i<kNumGretina4AChannels;i++){
                [self writeControlReg:i enabled:NO];
            }
            
            [self resetFIFO];
            [self setInitState:kReleaseClkManager];
            break;
            
        case kReleaseClkManager:
            //SERDES still disabled, release clk manager, clocks still held at reset
            [self writeRegister:kSdConfig           withValue: 0x00000211];
            [self setInitState:kPowerUpRTPower];
            break;
            
        case kPowerUpRTPower:
            //SERDES enabled, clocks still held at reset
            [self writeRegister:kSdConfig           withValue: 0x00000200];
            [self setInitState:kSetMasterLogic];
            break;
            
        case kSetMasterLogic:
            [self writeRegister:kMasterLogicStatus  withValue: 0x00000051]; //power up value
            [self setInitState:kSetSDSyncBit];
            break;
            
        case kSetSDSyncBit:
            [self writeRegister:kSdConfig           withValue: 0x00000000]; //release the clocks
            [self writeRegister:kSdConfig           withValue: 0x00000020]; //set sd syn

            [self setInitState:kSerDesIdle];
            break;
            
        case kSerDesError:
            break;
    }
    if(initializationState!= kSerDesError && initializationState!= kSerDesIdle){
       [self performSelector:@selector(stepSerDesInit) withObject:nil afterDelay:.01];
    }
}

- (BOOL) isLocked
{
    BOOL lockedBitSet   = ([self readRegister:kMasterLogicStatus] & kSDLockBit)==kSDLockBit;
    //BOOL lostLockBitSet = ([self readRegister:kSDLostLockBit] & kSDLostLockBit)==kSDLostLockBit;
    [self setLocked: lockedBitSet]; //& !lostLockBitSet];
    return [self locked];
}

- (BOOL) locked
{
    return locked;
}

- (void) setLocked:(BOOL)aState
{
    locked = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ALockChanged object: self];
}

- (NSString*) initSerDesStateName
{
    switch(initializationState){    
        case kSerDesIdle:           return @"Idle";
        case kSerDesSetup:          return @"Reset to power up state";
        case kSetDigitizerClkSrc:   return @"Set the Clk Source";
        case kFlushFifo:            return @"Flush FIFO";
 
        case kPowerUpRTPower:       return @"Power up T/R Power";
        case kSetMasterLogic:       return @"Write Master Logic = 0x20051";
        case kSetSDSyncBit:         return @"Write SD Sync Bit";
        case kSerDesError:          return @"Error";
        default:                    return @"?";
    }
}



#pragma mark - Data Taker
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORGretina4AWaveformDecoder",           @"decoder",
								 [NSNumber numberWithLong:dataId],        @"dataId",
								 [NSNumber numberWithBool:YES],           @"variable",
								 [NSNumber numberWithLong:-1],			  @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Gretina4A"];
    
    return dataDictionary;
}

#pragma mark - HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}

- (int) numberOfChannels
{
    return kNumGretina4AChannels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setOncePerCard:YES];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
 
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEnabled:withValue:) getMethod:@selector(enabled:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pile Up Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setPileupMode:withValue:) getMethod:@selector(pileupMode:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"PreampResetDelay Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setPreampResetDelayEn:withValue:) getMethod:@selector(preampResetDelayEn:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Dropped Event Count Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setDroppedEventCountMode:withValue:) getMethod:@selector(droppedEventCountMode:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Event Count Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEventCountMode:withValue:) getMethod:@selector(eventCountMode:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"LED Threshold"];
    [p setFormat:@"##0" upperLimit:0x1ffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setLedThreshold:withValue:) getMethod:@selector(ledThreshold:)];
    [p setCanBeRamped:YES];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"CFD Fraction"];
    [p setFormat:@"##0" upperLimit:0x1ffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setCFDFraction:withValue:) getMethod:@selector(cFDFraction:)];
    [p setCanBeRamped:YES];
    [a addObject:p];

    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Force Full Init"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setForceFullInit:withValue:) getMethod:@selector(forceFullInit:)];
    [a addObject:p];

    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel  name:@"Crate"   className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel     name:@"Card"    className:@"ORGretina4AModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel    name:@"Channel" className:@"ORGretina4AModel"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
 	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    
    id obj = [cardDictionary objectForKey:param];
    if(obj)return obj;
    else return [[cardDictionary objectForKey:param] objectAtIndex:aChannel];
}


- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    if(![self checkFirmwareVersion]){
        [NSException raise:@"Wrong Firmware" format:@"You must have firmware version 0x%x installed.",kCurrentFirmwareVersion];
    }

    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORGretina4A"];    
    
    //cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
    fifoAddress     = [self baseAddress] + 0x1000;
    fifoStateAddress= [self baseAddress] + register_information[kProgrammingDone].offset;
    
    fifoResetCount = 0;
    [self startRates];
    
    [self clearDiagnosticsReport];
    
    [self initBoard];
    
    if([self diagnosticsEnabled])[self briefDiagnosticsReport];
    
	[self performSelector:@selector(checkFifoAlarm) withObject:nil afterDelay:1];
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    isRunning = YES;
    NSString* errorLocation = @"";
    @try {
        if(![self fifoIsEmpty]){
            dataBuffer[0] = dataId | kG4MDataPacketSize;
            dataBuffer[1] = location;
        
            [theController readLong:&dataBuffer[2]
                          atAddress:fifoAddress 
                        timesToRead:1024
                         withAddMod:[self addressModifier] 
                      usingAddSpace:0x01];
            
            //the first word of the actual data record had better be the packet separator
            if(dataBuffer[2]==kGretina4APacketSeparator){
                short chan = dataBuffer[3] & 0xf;
                if(chan < 10){
                    ++waveFormCount[dataBuffer[3] & 0x7];  //grab the channel and inc the count
                    [aDataPacket addLongsToFrameBuffer:dataBuffer length:kG4MDataPacketSize];
                }
                else {
                    NSLogError(@"",@"Bad header--record discarded",@"GRETINA4M",[NSString stringWithFormat:@"slot %d",[self slot]], [NSString stringWithFormat:@"chan %d",1],nil);
                }
            }
            else {
                //oops... the buffer read is out of sequence
                NSLogError(@"",@"Packet Sequence Error -- FIFO reset",@"GRETINA4M",[NSString stringWithFormat:@"slot %d",[self slot]],nil);
                fifoResetCount++;
                [self resetFIFO];
            }
        }
     }
	@catch(NSException* localException) {
        NSLogError(@"",@"Gretina4A Card Error",errorLocation,nil);
        [self incExceptionCount];
        [localException raise];
    }
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    @try {
		int i;
		for(i=0;i<kNumGretina4AChannels;i++){					
			[self writeControlReg:i enabled:NO];
		}
	}
	@catch(NSException* e){
        [self incExceptionCount];
        NSLogError(@"",@"Gretina4A Card Error",nil);
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    isRunning = NO;
    [waveFormRateGroup stop];
    //stop all channels
    short i;
    for(i=0;i<kNumGretina4AChannels;i++){					
		waveFormCount[i] = 0;
    }
    
    //disable all channels
    for(i=0;i<kNumGretina4AChannels;i++){
        [self writeControlReg:i enabled:NO];
    }

    [self writeMasterLogic:NO];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkFifoAlarm) object:nil];
}

- (void) checkFifoAlarm
{
	if(((fifoState & kGretina4AFIFOAlmostFull) != 0) && isRunning){
		fifoEmptyCount = 0;
		if(!fifoFullAlarm){
			NSString* alarmName = [NSString stringWithFormat:@"FIFO Almost Full Gretina4A (slot %d)",[self slot]];
			fifoFullAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kDataFlowAlarm];
			[fifoFullAlarm setSticky:YES];
			[fifoFullAlarm setHelpString:@"The rate is too high. Adjust the LED Threshold accordingly."];
			[fifoFullAlarm postAlarm];
		}
	}
	else {
		fifoEmptyCount++;
		if(fifoEmptyCount>=5){
			[fifoFullAlarm clearAlarm];
			[fifoFullAlarm release];
			fifoFullAlarm = nil;
		}
	}
	if(isRunning){
		[self performSelector:@selector(checkFifoAlarm) withObject:nil afterDelay:1.5];
	}
	else {
		[fifoFullAlarm clearAlarm];
		[fifoFullAlarm release];
		fifoFullAlarm = nil;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFIFOCheckChanged object:self];
}

- (void) reset
{
}

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        waveFormCount[i]=0;
    }
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(isRunning)return NO;
    ++waveFormCount[channel];
    return YES;
}

- (unsigned long) waveFormCount:(short)aChannel
{
    return waveFormCount[aChannel];
}


- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	
    /* The current hardware specific data is:               *
     *                                                      *
     * 0: FIFO state address                                *
     * 1: FIFO empty state mask                             *
     * 2: FIFO address                                      *
     * 3: FIFO address AM                                   *
     * 4: FIFO size                                         */

	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kGretina4A; //should be unique
	configStruct->card_info[index].hw_mask[0]				= dataId; //better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= [self addressModifier];
	configStruct->card_info[index].base_add					= [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0]	= [self baseAddress] + register_information[kProgrammingDone].offset; //fifoStateAddress
    configStruct->card_info[index].deviceSpecificData[1]	= [self baseAddress] + 0x1000; // fifoAddress
    configStruct->card_info[index].deviceSpecificData[2]	= 0x0B; // fifoAM
    configStruct->card_info[index].deviceSpecificData[3]	= [self baseAddress] + 0x04; // fifoReset Address
    configStruct->card_info[index].deviceSpecificData[4]	= [self rawDataWindow:0];
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

#pragma mark - Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setSpiConnector:              [decoder decodeObjectForKey:@"spiConnector"]];
    [self setLinkConnector:             [decoder decodeObjectForKey:@"linkConnector"]];
    [self setRegisterIndex:				[decoder decodeIntForKey:@"registerIndex"]];
    [self setSelectedChannel:           [decoder decodeIntForKey:@"selectedChannel"]];
    [self setRegisterWriteValue:		[decoder decodeInt32ForKey:@"registerWriteValue"]];
    [self setSPIWriteValue:     		[decoder decodeInt32ForKey:@"spiWriteValue"]];
    [self setFpgaFilePath:				[decoder decodeObjectForKey:@"fpgaFilePath"]];
    [self setNoiseFloorIntegrationTime:	[decoder decodeFloatForKey:@"NoiseFloorIntegrationTime"]];
    [self setNoiseFloorOffset:			[decoder decodeIntForKey:@"NoiseFloorOffset"]];
    [self setWaveFormRateGroup:[decoder decodeObjectForKey:@"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumGretina4AChannels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
    [self setFirmwareVersion:   [decoder decodeInt32ForKey:@"firmwareVersion"]];
    [self setAcqDcmCtrlStatus:  [decoder decodeInt32ForKey:@"acqDcmCtrlStatus"]];
    [self setAcqDcmLock:        [decoder decodeBoolForKey: @"acqDcmLock"]];
    [self setAcqDcmReset:       [decoder decodeBoolForKey: @"acqDcmReset"]];
    [self setAcqPhShiftOverflow:[decoder decodeBoolForKey: @"acqPhShiftOverflow"]];
    [self setAcqDcmClockStopped:[decoder decodeBoolForKey: @"acqDcmClockStopped"]];
    [self setAdcDcmCtrlStatus:  [decoder decodeInt32ForKey:@"adcDcmCtrlStatus"]];
    [self setAdcDcmLock:        [decoder decodeBoolForKey: @"adcDcmLock"]];
    [self setAdcDcmReset:       [decoder decodeBoolForKey: @"adcDcmReset"]];
    [self setAdcPhShiftOverflow:[decoder decodeBoolForKey: @"adcPhShiftOverflow"]];
    [self setAdcDcmClockStopped:[decoder decodeBoolForKey: @"adcDcmClockStopped"]];
    [self setUserPackageData:   [decoder decodeInt32ForKey:@"userPackageData"]];
    [self setDacChannelSelect:  [decoder decodeInt32ForKey:@"dacChannelSelect"]];
    [self setDacAttenuation:    [decoder decodeInt32ForKey:@"dacAttenuation"]];
    [self setIlaConfig:         [decoder decodeInt32ForKey:@"ilaConfig"]];
    [self setPhaseHunt:         [decoder decodeBoolForKey: @"phaseHunt"]];
    [self setLoadbaseline:      [decoder decodeBoolForKey: @"loadbaseline"]];
    [self setPhaseHuntDebug:    [decoder decodeBoolForKey: @"phaseHuntDebug"]];
    [self setPhaseHuntProceed:  [decoder decodeBoolForKey: @"phaseHuntProceed"]];
    [self setPhaseDec:          [decoder decodeBoolForKey: @"phaseDec"]];
    [self setPhaseInc:          [decoder decodeBoolForKey: @"phaseInc"]];
    [self setSerdesPhaseInc:    [decoder decodeBoolForKey: @"serdesPhaseInc"]];
    [self setSerdesPhaseDec:    [decoder decodeBoolForKey: @"serdesPhaseDec"]];
    [self setDiagMuxControl:    [decoder decodeInt32ForKey:@"diagMuxControl"]];
    [self setPeakSensitivity:   [decoder decodeInt32ForKey:@"peakSensitivity"]];
    [self setDiagInput:         [decoder decodeInt32ForKey:@"diagInput"]];
    [self setDiagChannelEventSel:[decoder decodeInt32ForKey:@"diagChannelEventSel"]];
    [self setRj45SpareIoMuxSel:  [decoder decodeInt32ForKey:@"rj45SpareIoMuxSel"]];
    [self setRj45SpareIoDir:    [decoder decodeBoolForKey: @"rj45SpareIoDir"]];
    [self setLedStatus:         [decoder decodeInt32ForKey:@"ledStatus"]];
    [self setLiveTimestampLsb:  [decoder decodeInt32ForKey:@"liveTimestampLsb"]];
    [self setLiveTimestampMsb:  [decoder decodeInt32ForKey:@"liveTimestampMsb"]];
    [self setDiagIsync:         [decoder decodeBoolForKey: @"diagIsync"]];
    [self setSerdesSmLostLock:  [decoder decodeBoolForKey: @"serdesSmLostLock"]];
    [self setTriggerConfig:     [decoder decodeInt32ForKey:@"triggerConfig"]];
    [self setPhaseErrorCount:   [decoder decodeInt32ForKey:@"phaseErrorCount"]];
    [self setPhaseStatus:       [decoder decodeInt32ForKey:@"phaseStatus"]];
    [self setSerdesPhaseValue:  [decoder decodeInt32ForKey:@"serdesPhaseValue"]];
    [self setPcbRevision:       [decoder decodeInt32ForKey:@"pcbRevision"]];
    [self setFwType:            [decoder decodeInt32ForKey:@"fwType"]];
    [self setMjrCodeRevision:   [decoder decodeInt32ForKey:@"mjrCodeRevision"]];
    [self setMinCodeRevision:   [decoder decodeInt32ForKey:@"minCodeRevision"]];
    [self setCodeDate:          [decoder decodeInt32ForKey:@"codeDate"]];
    [self setTSErrCntCtrl:      [decoder decodeInt32ForKey:@"tSErrCntCtrl"]];
    [self setTSErrorCount:      [decoder decodeInt32ForKey:@"tSErrorCount"]];
    [self setAuxIoRead:         [decoder decodeInt32ForKey:@"auxIoRead"]];
    [self setAuxIoWrite:        [decoder decodeInt32ForKey:@"auxIoWrite"]];
    [self setAuxIoConfig:       [decoder decodeInt32ForKey:@"auxIoConfig"]];
    [self setSdPem:             [decoder decodeInt32ForKey:@"sdPem"]];
    [self setSdSmLostLockFlag:  [decoder decodeBoolForKey: @"sdSmLostLockFlag"]];
    [self setAdcConfig:         [decoder decodeInt32ForKey:@"adcConfig"]];
    [self setConfigMainFpga:    [decoder decodeBoolForKey: @"configMainFpga"]];
    [self setPowerOk:           [decoder decodeBoolForKey: @"powerOk"]];
    [self setOverVoltStat:      [decoder decodeBoolForKey: @"overVoltStat"]];
    [self setUnderVoltStat:     [decoder decodeBoolForKey: @"underVoltStat"]];
    [self setTemp0Sensor:       [decoder decodeBoolForKey: @"temp0Sensor"]];
    [self setTemp1Sensor:       [decoder decodeBoolForKey: @"temp1Sensor"]];
    [self setTemp2Sensor:       [decoder decodeBoolForKey: @"temp2Sensor"]];
    [self setClkSelect0:        [decoder decodeBoolForKey: @"clkSelect0"]];
    [self setClkSelect1:        [decoder decodeBoolForKey: @"clkSelect1"]];
    [self setFlashMode:         [decoder decodeBoolForKey: @"flashMode"]];
    [self setSerialNum:         [decoder decodeInt32ForKey:@"serialNum"]];
    [self setBoardRevNum:       [decoder decodeInt32ForKey:@"boardRevNum"]];
    [self setVhdlVerNum:        [decoder decodeInt32ForKey:@"vhdlVerNum"]];
    [self setFifoAccess:        [decoder decodeInt32ForKey:@"fifoAccess"]];
    [self setWriteFlag:         [decoder decodeInt32ForKey:@"writeFlag"]];
    [self setDecimationFactor:  [decoder decodeInt32ForKey:@"decimationFactor"]];
    [self setP2Window:          [decoder decodeInt32ForKey:@"p2Window"]];
    [self setForceFullCardInit: [decoder decodeIntForKey:  @"forceFullInit"]];
    [self setBaselineDelay:     [decoder decodeIntForKey:  @"baselineDelay"]];
    [self setWindowCompMin:     [decoder decodeIntForKey:  @"windowCompMin"]];
    [self setWindowCompMax:     [decoder decodeIntForKey:  @"windowCompMax"]];

	
	int i;
	for(i=0;i<kNumGretina4AChannels;i++){
        [self setEnabled:i                  withValue:  [decoder decodeBoolForKey:  [NSString stringWithFormat:@"enabled%d",i]]];
        [self setOverflowFlagChan:i         withValue:  [decoder decodeBoolForKey:  [NSString stringWithFormat:@"overflowFlagChan%d",i]]];
        [self setForceFullInit:i            withValue:  [decoder decodeIntForKey:   [NSString stringWithFormat:@"forceFullInit%d",i]]];
        [self setRouterVetoEn:i             withValue:  [decoder decodeBoolForKey:  [NSString stringWithFormat:@"routerVetoEn%d",i]]]; //0-10
        [self setPreampResetDelayEn:i       withValue:  [decoder decodeBoolForKey:  [NSString stringWithFormat:@"preampResetDelayEn%d",i]]]; //0-10
        [self setPileupMode:i               withValue:  [decoder decodeBoolForKey:  [NSString stringWithFormat:@"pileupMode%d",i]]]; //0-10
        [self setDroppedEventCountMode:i    withValue:  [decoder decodeBoolForKey:  [NSString stringWithFormat:@"droppedEventCountMode%d",i]]]; //0-10
        [self setEventCountMode:i           withValue:  [decoder decodeBoolForKey:  [NSString stringWithFormat:@"eventCountMode%d",i]]]; //0-10
        
        [self setAHitCountMode:i           withValue:  [decoder decodeBoolForKey:  [NSString stringWithFormat:@"aHitCountMode%d",i]]]; //0-10
        [self setDiscCountMode:i           withValue:  [decoder decodeBoolForKey:  [NSString stringWithFormat:@"discCountMode%d",i]]]; //0-10
        [self setEventExtensionMode:i      withValue:  [decoder decodeInt32ForKey:  [NSString stringWithFormat:@"eventExtensionMode%d",i]]]; //0-10
        [self setPileupExtensionMode:i     withValue:  [decoder decodeBoolForKey:  [NSString stringWithFormat:@"pileExtensionMode%d",i]]]; //0-10
        [self setCounterReset:i            withValue:  [decoder decodeBoolForKey:  [NSString stringWithFormat:@"counterReset%d",i]]]; //0-10
        [self setPileupWaveformOnlyMode:i  withValue:  [decoder decodeBoolForKey:  [NSString stringWithFormat:@"pileupWaveformOnlyMode%d",i]]]; //0-10
        
        [self setLedThreshold:i             withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"ledThreshold%d",i]]]; //0-10;
        [self setPreampResetDelay:i         withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"preampResetDelay%d",i]]]; //0-10
        [self setRawDataLength:i            withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"rawDataLength%d",i]]]; //0-10
        [self setRawDataWindow:i            withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"rawDataWindow%d",i]]]; //0-10
        [self setDWindow:i                  withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"dWindow%d",i]]]; //0-10
        [self setKWindow:i                  withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"kWindow%d",i]]]; //0-10
        [self setMWindow:i                  withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"mWindow%d",i]]]; //0-10
        [self setD3Window:i                 withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"d3Window%d",i]]]; //0-10
        [self setBaselineStart:i            withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"baselineStart%d",i]]]; //0-10
        [self setP1Window:i                  withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"p1Window%d",i]]]; //0-10
        [self setDroppedEventCount:i        withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"droppedEventCount%d",i]]]; //0-10
        [self setAcceptedEventCount:i       withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"acceptedEventCount%d",i]]]; //0-10
        [self setAhitCount:i                withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"ahitCount%d",i]]]; //0-10
        [self setDiscCount:i                withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"discCount%d",i]]]; //0-10
        [self setCFDFraction:i              withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"cFDFraction%d",i]]];
        [self setDiscWidth:i                withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"discWidth%d",i]]];
        [self setTriggerPolarity:i          withValue:  [decoder decodeInt32ForKey: [NSString stringWithFormat:@"triggerPolarity%d",i]]];
    }
    for(i=0;i<4;i++){
        [self setPhase0:i withValue:   [decoder decodeInt32ForKey: [NSString stringWithFormat:@"phase0%d",i]]]; //0-3
        [self setPhase1:i withValue:   [decoder decodeInt32ForKey: [NSString stringWithFormat:@"phase1%d",i]]]; //0-3
        [self setPhase2:i withValue:   [decoder decodeInt32ForKey: [NSString stringWithFormat:@"phase2%d",i]]]; //0-3
        [self setPhase3:i withValue:   [decoder decodeInt32ForKey: [NSString stringWithFormat:@"phase3%d",i]]]; //0-3
    }
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:spiConnector				forKey:@"spiConnector"];
    [encoder encodeObject:linkConnector				forKey:@"linkConnector"];
    [encoder encodeInt:registerIndex				forKey:@"registerIndex"];
    [encoder encodeInt:selectedChannel              forKey:@"selectedChannel"];
    [encoder encodeInt32:registerWriteValue			forKey:@"registerWriteValue"];
    [encoder encodeInt32:spiWriteValue			    forKey:@"spiWriteValue"];
    [encoder encodeObject:fpgaFilePath				forKey:@"fpgaFilePath"];
    [encoder encodeFloat:noiseFloorIntegrationTime	forKey:@"NoiseFloorIntegrationTime"];
    [encoder encodeInt:noiseFloorOffset				forKey:@"NoiseFloorOffset"];
    [encoder encodeObject:waveFormRateGroup			forKey:@"waveFormRateGroup"];
    
    [encoder encodeInt32:firmwareVersion            forKey:@"firmwareVersion"];
    [encoder encodeInt32:acqDcmCtrlStatus           forKey:@"acqDcmCtrlStatus"];
    [encoder encodeBool:acqDcmLock                  forKey:@"acqDcmLock"];
    [encoder encodeBool:acqDcmReset                 forKey:@"acqDcmReset"];
    [encoder encodeBool:acqPhShiftOverflow          forKey:@"acqPhShiftOverflow"];
    [encoder encodeBool:acqDcmClockStopped          forKey:@"acqDcmClockStopped"];
    [encoder encodeInt32:adcDcmCtrlStatus           forKey:@"adcDcmCtrlStatus"];
    [encoder encodeBool:adcDcmLock                  forKey:@"adcDcmLock"];
    [encoder encodeBool:adcDcmReset                 forKey:@"adcDcmReset"];
    [encoder encodeBool:adcPhShiftOverflow          forKey:@"adcPhShiftOverflow"];
    [encoder encodeBool:adcDcmClockStopped          forKey:@"adcDcmClockStopped"];
    [encoder encodeInt32:userPackageData            forKey:@"userPackageData"];
    [encoder encodeInt32:dacChannelSelect           forKey:@"dacChannelSelect"];
    [encoder encodeInt32:dacAttenuation             forKey:@"dacAttenuation"];
    [encoder encodeInt32:ilaConfig                  forKey:@"ilaConfig"];
    [encoder encodeBool:phaseHunt                   forKey:@"phaseHunt"];
    [encoder encodeBool:loadbaseline                forKey:@"loadbaseline"];
    [encoder encodeBool:phaseHuntDebug              forKey:@"phaseHuntDebug"];
    [encoder encodeBool:phaseHuntProceed            forKey:@"phaseHuntProceed"];
    [encoder encodeBool:phaseDec                    forKey:@"phaseDec"];
    [encoder encodeBool:phaseInc                    forKey:@"phaseInc"];
    [encoder encodeBool:serdesPhaseInc              forKey:@"serdesPhaseInc"];
    [encoder encodeBool:serdesPhaseDec              forKey:@"serdesPhaseDec"];
    [encoder encodeInt32:diagMuxControl             forKey:@"diagMuxControl"];
    [encoder encodeInt32:peakSensitivity            forKey:@"peakSensitivity"];
    [encoder encodeInt32:diagInput                  forKey:@"diagInput"];
    [encoder encodeInt32:diagChannelEventSel        forKey:@"diagChannelEventSel"];
    [encoder encodeInt32:rj45SpareIoMuxSel          forKey:@"rj45SpareIoMuxSel"];
    [encoder encodeBool:rj45SpareIoDir              forKey:@"rj45SpareIoDir"];
    [encoder encodeInt32:ledStatus                  forKey:@"ledStatus"];
    [encoder encodeInt32:liveTimestampLsb           forKey:@"liveTimestampLsb"];
    [encoder encodeInt32:liveTimestampMsb           forKey:@"liveTimestampMsb"];
    [encoder encodeBool:diagIsync                   forKey:@"diagIsync"];
    [encoder encodeBool:serdesSmLostLock            forKey:@"serdesSmLostLock"];
    [encoder encodeInt32:triggerConfig              forKey:@"triggerConfig"];
    [encoder encodeInt32:phaseErrorCount            forKey:@"phaseErrorCount"];
    [encoder encodeInt32:phaseStatus                forKey:@"phaseStatus"];
    [encoder encodeInt32:serdesPhaseValue           forKey:@"serdesPhaseValue"];
    [encoder encodeInt32:pcbRevision                forKey:@"pcbRevision"];
    [encoder encodeInt32:fwType                     forKey:@"fwType"];
    [encoder encodeInt32:mjrCodeRevision            forKey:@"mjrCodeRevision"];
    [encoder encodeInt32:minCodeRevision            forKey:@"minCodeRevision"];
    [encoder encodeInt32:codeDate                   forKey:@"codeDate"];
    [encoder encodeInt32:tSErrCntCtrl               forKey:@"tSErrCntCtrl"];
    [encoder encodeInt32:tSErrorCount               forKey:@"tSErrorCount"];
    [encoder encodeInt32:auxIoRead                  forKey:@"auxIoRead"];
    [encoder encodeInt32:auxIoWrite                 forKey:@"auxIoWrite"];
    [encoder encodeInt32:auxIoConfig                forKey:@"auxIoConfig"];
    [encoder encodeInt32:sdPem                      forKey:@"sdPem"];
    [encoder encodeBool:sdSmLostLockFlag            forKey:@"sdSmLostLockFlag"];
    [encoder encodeInt32:adcConfig                  forKey:@"adcConfig"];
    [encoder encodeBool:configMainFpga              forKey:@"configMainFpga"];
    [encoder encodeBool:powerOk                     forKey:@"powerOk"];
    [encoder encodeBool:overVoltStat                forKey:@"overVoltStat"];
    [encoder encodeBool:underVoltStat               forKey:@"underVoltStat"];
    [encoder encodeBool:temp0Sensor                 forKey:@"temp0Sensor"];
    [encoder encodeBool:temp1Sensor                 forKey:@"temp1Sensor"];
    [encoder encodeBool:temp2Sensor                 forKey:@"temp2Sensor"];
    [encoder encodeBool:clkSelect0                  forKey:@"clkSelect0"];
    [encoder encodeBool:clkSelect1                  forKey:@"clkSelect1"];
    [encoder encodeBool:flashMode                   forKey:@"flashMode"];
    [encoder encodeInt32:serialNum                  forKey:@"serialNum"];
    [encoder encodeInt32:boardRevNum                forKey:@"boardRevNum"];
    [encoder encodeInt32:vhdlVerNum                 forKey:@"vhdlVerNum"];
    [encoder encodeInt32:fifoAccess                 forKey:@"fifoAccess"];
    [encoder encodeInt32:writeFlag                  forKey:@"writeFlag"];
    [encoder encodeInt32:decimationFactor           forKey:@"decimationFactor"];
    [encoder encodeInt32:p2Window                   forKey:@"p2Window"];
    [encoder encodeInt32:forceFullCardInit          forKey:@"forceFullCardInit"];
    [encoder encodeInt32:baselineDelay              forKey:@"baselineDelay"];
    [encoder encodeInt32:windowCompMin              forKey:@"windowCompMin"];
    [encoder encodeInt32:windowCompMax              forKey:@"windowCompMax"];

	int i;
 	for(i=0;i<kNumGretina4AChannels;i++){
        [encoder encodeInt:forceFullInit[i]             forKey:[@"forceFullInit"		stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:enabled[i]                  forKey:[NSString stringWithFormat:@"enabled%d",i]]; //0-10
        [encoder encodeBool:overflowFlagChan[i]         forKey:[NSString stringWithFormat:@"overflowFlagChan%d",i]]; //0-10
        [encoder encodeBool:routerVetoEn[i]             forKey:[NSString stringWithFormat:@"routerVetoEn%d",i]]; //0-10
        [encoder encodeBool:preampResetDelayEn[i]       forKey:[NSString stringWithFormat:@"preampResetDelayEn%d",i]]; //0-10
        [encoder encodeBool:pileupMode[i]               forKey:[NSString stringWithFormat:@"pileupMode%d",i]]; //0-10
        [encoder encodeInt32:triggerPolarity[i]         forKey:[NSString stringWithFormat:@"triggerPolarity%d",i]]; //0-10
        [encoder encodeInt32:ledThreshold[i]            forKey:[NSString stringWithFormat:@"ledThreshold%d",i]]; //0-10
        [encoder encodeInt32:cFDFraction[i]             forKey:[NSString stringWithFormat:@"cFDFraction%d",i]]; //0-10
        [encoder encodeInt32:preampResetDelay[i]        forKey:[NSString stringWithFormat:@"preampResetDelay%d",i]]; //0-10
        [encoder encodeBool:droppedEventCountMode[i]    forKey:[NSString stringWithFormat:@"droppedEventCountMode%d",i]]; //0-10
        
        [encoder encodeBool:aHitCountMode[i]            forKey:[NSString stringWithFormat:@"aHitCountMode%d",i]]; //0-10
        [encoder encodeBool:discCountMode[i]            forKey:[NSString stringWithFormat:@"discCountMode%d",i]]; //0-10
        [encoder encodeInt32:eventExtensionMode[i]      forKey:[NSString stringWithFormat:@"eventExtensionMode%d",i]]; //0-10
        [encoder encodeBool:pileupExtensionMode[i]      forKey:[NSString stringWithFormat:@"pileExtensionMode%d",i]]; //0-10
        [encoder encodeBool:counterReset[i]             forKey:[NSString stringWithFormat:@"counterReset%d",i]]; //0-10
        [encoder encodeBool:pileupWaveformOnlyMode[i]   forKey:[NSString stringWithFormat:@"pileupWaveformOnlyMode%d",i]]; //0-10
        
        [encoder encodeBool:eventCountMode[i]           forKey:[NSString stringWithFormat:@"eventCountMode%d",i]]; //0-10
        [encoder encodeInt32:rawDataLength[i]           forKey:[NSString stringWithFormat:@"rawDataLength%d",i]]; //0-10
        [encoder encodeInt32:rawDataWindow[i]           forKey:[NSString stringWithFormat:@"rawDataWindow%d",i]]; //0-10
        [encoder encodeInt32:dWindow[i]                 forKey:[NSString stringWithFormat:@"dWindow%d",i]]; //0-10
        [encoder encodeInt32:kWindow[i]                 forKey:[NSString stringWithFormat:@"kWindow%d",i]]; //0-10
        [encoder encodeInt32:mWindow[i]                 forKey:[NSString stringWithFormat:@"mWindow%d",i]]; //0-10
        [encoder encodeInt32:d3Window[i]                forKey:[NSString stringWithFormat:@"d3Window%d",i]]; //0-10
        [encoder encodeInt32:baselineStart[i]           forKey:[NSString stringWithFormat:@"baselineStart%d",i]]; //0-10
        [encoder encodeInt32:p1Window[i]                forKey:[NSString stringWithFormat:@"p1Window%d",i]]; //0-10
        [encoder encodeInt32:droppedEventCount[i]       forKey:[NSString stringWithFormat:@"droppedEventCount%d",i]]; //0-10
        [encoder encodeInt32:acceptedEventCount[i]      forKey:[NSString stringWithFormat:@"acceptedEventCount%d",i]]; //0-10
        [encoder encodeInt32:ahitCount[i]               forKey:[NSString stringWithFormat:@"ahitCount%d",i]]; //0-10
        [encoder encodeInt32:discCount[i]               forKey:[NSString stringWithFormat:@"discCount%d",i]]; //0-10
        [encoder encodeInt32:discWidth[i]               forKey:[NSString stringWithFormat:@"discWidth%d",i]]; //0-10
    }
    for(i=0;i<4;i++){
        [encoder encodeInt32:phase0[i]      forKey:[NSString stringWithFormat:@"phase0%d",i]]; //0-3
        [encoder encodeInt32:phase1[i]      forKey:[NSString stringWithFormat:@"phase1%d",i]]; //0-3
        [encoder encodeInt32:phase2[i]      forKey:[NSString stringWithFormat:@"phase2%d",i]]; //0-3
        [encoder encodeInt32:phase3[i]      forKey:[NSString stringWithFormat:@"phase3%d",i]]; //0-3
    }
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumGretina4AChannels;i++)[ar addObject:[NSNumber numberWithLong:ledThreshold[i]]];
    [objDictionary setObject:ar forKey:@"LED Threshold"];

    
    [ar removeAllObjects];
    for(i=0;i<kNumGretina4AChannels;i++)[ar addObject:[NSNumber numberWithLong:cFDFraction[i]]];
    [objDictionary setObject:ar forKey:@"CFD Fraction"];

    [ar removeAllObjects];
    for(i=0;i<kNumGretina4AChannels;i++)[ar addObject:[NSNumber numberWithLong:triggerPolarity[i]]];
    [objDictionary setObject:ar forKey:@"Trigger Polarity"];

    
    [self addCurrentState:objDictionary boolArray:(BOOL*)forceFullInit              forKey:@"forceFullInit"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)pileupMode                 forKey:@"pileupMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)preampResetDelayEn         forKey:@"preampResetDelayEn"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)droppedEventCountMode      forKey:@"droppedEventCountMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)eventCountMode             forKey:@"eventCountMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)aHitCountMode              forKey:@"aHitCountMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)discCountMode              forKey:@"discCountMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)eventExtensionMode         forKey:@"eventExtensionMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)pileupExtensionMode        forKey:@"pileExtensionMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)counterReset               forKey:@"counterReset"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)pileupWaveformOnlyMode     forKey:@"pileupWaveformOnlyMode"];
  
    [objDictionary setObject:[NSNumber numberWithInt:mWindow[0]] forKey:@"mWindow"]; //just dealling with one value for now
    [objDictionary setObject:[NSNumber numberWithInt:kWindow[0]] forKey:@"kWindow"]; //just dealling with one value for now
    [objDictionary setObject:[NSNumber numberWithInt:dWindow[0]] forKey:@"dWindow"]; //just dealling with one value for now
    [objDictionary setObject:[NSNumber numberWithInt:d3Window[0]] forKey:@"d3Window"]; //just dealling with one value for now
    [objDictionary setObject:[NSNumber numberWithInt:p1Window[0]] forKey:@"p1Window"]; //just dealling with one value for now

    
    [objDictionary setObject:[NSNumber numberWithInt:rawDataLength[0]] forKey:@"rawdatalength"]; //just dealling with one value for now
    [objDictionary setObject:[NSNumber numberWithInt:rawDataWindow[0]] forKey:@"rawdataWindow"]; //just dealling with one value for now
    [objDictionary setObject:[NSNumber numberWithInt:writeFlag] forKey:@"writeFlag"];
    [objDictionary setObject:[NSNumber numberWithInt:decimationFactor] forKey:@"decimationFactor"];
    [objDictionary setObject:[NSNumber numberWithInt:p2Window] forKey:@"p2Window"];
    [objDictionary setObject:[NSNumber numberWithInt:forceFullCardInit] forKey:@"forceFullCardInit"];

    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary shortArray:(short*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<kNumGretina4AChannels;i++){
		[ar addObject:[NSNumber numberWithShort:anArray[i]]];
	}
	[dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [ar addObject:[NSNumber numberWithBool:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}


#pragma mark - AutoTesting
- (NSArray*) autoTests
{
	NSMutableArray* myTests = [NSMutableArray array];
	[myTests addObject:[ORVmeReadOnlyTest test:kBoardId wordSize:4 name:@"Board ID"]];
	return myTests;
}


#pragma mark - SPI Interface
- (unsigned long) writeAuxIOSPI:(unsigned long)spiData
{
    /*
    // Set AuxIO to mode 3 and set bits 0-3 to OUT (bit 0 is under FPGA control)
    [self writeRegister:kAuxIOConfig withValue:0x3025];
    // Read kAuxIOWrite to preserve bit 0, and zero bits used in SPI protocol
    unsigned long spiBase = [self readRegister:kAuxIOWrite] & ~(kSPIData | kSPIClock | kSPIChipSelect); 
    unsigned long value;
    unsigned long readBack = 0;
	
    // set kSPIChipSelect to signify that we are starting
    [self writeRegister:kAuxIOWrite withValue:(kSPIChipSelect | kSPIClock | kSPIData)];
    // now write spiData starting from MSB on kSPIData, pulsing kSPIClock
    // each iteration
    int i;
    //NSLog(@"writing 0x%x\n", spiData);
    for(i=0; i<32; i++) {
        value = spiBase | kSPIChipSelect | kSPIData;
        if( (spiData & 0x80000000) != 0) value &= (~kSPIData);
        [self writeRegister:kAuxIOWrite withValue:value | kSPIClock];
        [self writeRegister:kAuxIOWrite withValue:value];
        readBack |= (([self readRegister:kAuxIORead] & kSPIRead) > 0) << (31-i);
        spiData = spiData << 1;
    }
    // unset kSPIChipSelect to signify that we are done
    [self writeRegister:kAuxIOWrite withValue:(kSPIClock | kSPIData)];
    //NSLog(@"readBack=%u (0x%x)\n", readBack, readBack);
    return readBack;
     */
    return 0;
}


#pragma mark - AdcProviding Protocol
- (BOOL) onlineMaskBit:(int)bit
{
   return [self enabled:bit];
}

- (BOOL) partOfEvent:(unsigned short)aChannel
{
	//included to satisfy the protocol... change if needed
	return NO;
}

- (unsigned long) eventCount:(int)aChannel
{
    return waveFormCount[aChannel];
}

- (void) clearEventCounts
{
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
		waveFormCount[i]=0;
    }
}

- (unsigned long) thresholdForDisplay:(unsigned short) aChan
{
	return [self ledThreshold:aChan];
}

- (unsigned short) gainForDisplay:(unsigned short) aChan
{
	return 0;
}
- (void) postAdcInfoProvidingValueChanged
{
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORAdcInfoProvidingValueChanged
	 object:self
	 userInfo: nil];
}
- (void) setThreshold:(short)chan withValue:(int)aValue
{
    [self setLedThreshold:chan withValue:aValue];
}
#pragma mark - Accessors

//------------------- Address = 0x0000  Bit Field = 31..16 ---------------
- (unsigned long) firmwareVersion
{
    return firmwareVersion;
}

- (void) setFirmwareVersion:(unsigned long)aValue
{
    if(aValue > 0xFFFF)aValue = 0xFFFF;
    firmwareVersion = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFirmwareVersionChanged object:self];
}


//------------------- Address = 0x0020  Bit Field = 19..16 ---------------
- (unsigned long) acqDcmCtrlStatus
{
    return acqDcmCtrlStatus;
}

- (void) setAcqDcmCtrlStatus:(unsigned long)aValue
{
    if(aValue > 0xF)aValue = 0xF;
    acqDcmCtrlStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAcqDcmCtrlStatusChanged object:self];
}

//------------------- Address = 0x0020  Bit Field = 20 ---------------
- (BOOL) acqDcmLock
{
    return acqDcmLock;
}

- (void) setAcqDcmLock:(BOOL)aValue
{
    acqDcmLock = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAcqDcmLockChanged object:self];
    
}

//------------------- Address = 0x0020  Bit Field = 21 ---------------
- (BOOL) acqDcmReset
{
    return acqDcmReset;
}

- (void) setAcqDcmReset:(BOOL)aValue
{
    if(acqDcmReset != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setAcqDcmReset:acqDcmReset];
        acqDcmReset = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAcqDcmResetChanged object:self];
    }
}

//------------------- Address = 0x0020  Bit Field = 22 ---------------
- (BOOL) acqPhShiftOverflow
{
    return acqPhShiftOverflow;
}

- (void) setAcqPhShiftOverflow:(BOOL)aValue
{
    acqPhShiftOverflow = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAcqPhShiftOverflowChanged object:self];
}

//------------------- Address = 0x0020  Bit Field = 23 ---------------
- (BOOL) acqDcmClockStopped
{
    return acqDcmClockStopped;
}

- (void) setAcqDcmClockStopped:(BOOL)aValue
{
    acqDcmClockStopped = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAcqDcmClockStoppedChanged object:self];
}

//------------------- Address = 0x0020  Bit Field = 27..24 ---------------
- (unsigned long) adcDcmCtrlStatus
{
    return adcDcmCtrlStatus;
}

- (void) setAdcDcmCtrlStatus:(unsigned long)aValue
{
    if(aValue > 0xF)aValue = 0xF;
    adcDcmCtrlStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAdcDcmCtrlStatusChanged object:self];
}

//------------------- Address = 0x0020  Bit Field = 28 ---------------
- (BOOL) adcDcmLock
{
    return adcDcmLock;
}

- (void) setAdcDcmLock:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcDcmLock:adcDcmLock];
    adcDcmLock = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAdcDcmLockChanged object:self];
}

//------------------- Address = 0x0020  Bit Field = 29 ---------------
- (BOOL) adcDcmReset
{
    return adcDcmReset;
}

- (void) setAdcDcmReset:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcDcmReset:adcDcmReset];
    adcDcmReset = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAdcDcmResetChanged object:self];
}

//------------------- Address = 0x0020  Bit Field = 30 ---------------
- (BOOL) adcPhShiftOverflow
{
    return adcPhShiftOverflow;
}

- (void) setAdcPhShiftOverflow:(BOOL)aValue
{
    adcPhShiftOverflow = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAdcPhShiftOverflowChanged object:self];
}

//------------------- Address = 0x0020  Bit Field = 31 ---------------
- (BOOL) adcDcmClockStopped
{
    return adcDcmClockStopped;
}

- (void) setAdcDcmClockStopped:(BOOL)aValue
{
    adcDcmClockStopped = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAdcDcmClockStoppedChanged object:self];
}

//------------------- Address = 0x0024  Bit Field = 11..0 ---------------
- (unsigned long) userPackageData
{
    return userPackageData;
}

- (void) setUserPackageData:(unsigned long)aValue
{
    if(aValue > 0xFFF)aValue = 0xFFF;
    if(userPackageData != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setUserPackageData:userPackageData];
        userPackageData = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AUserPackageDataChanged object:self];
    }
}

//------------------- Address = 0x028  Bit Field = 15..0 ---------------
- (unsigned long) windowCompMin
{
    return windowCompMin;
}

- (void) setWindowCompMin:(unsigned long)aValue
{
    if(aValue > 0xFFFF)aValue = 0xFFFF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setWindowCompMin:windowCompMin];
    windowCompMin = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AWindowCompMinChanged object:self];
}
//------------------- Address = 0x032  Bit Field = 15..0 ---------------
- (unsigned long) windowCompMax
{
    return windowCompMax;
}

- (void) setWindowCompMax:(unsigned long)aValue
{
    if(aValue > 0xFFFF)aValue = 0xFFFF;
    
    if(windowCompMax != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setWindowCompMax:windowCompMax];
        windowCompMax = aValue;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AWindowCompMaxChanged object:self];
    }
}
//------------------- Address = 0x0040  Bit Field = 1 ---------------
- (BOOL) routerVetoEn:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return routerVetoEn[anIndex];
}

- (void) setRouterVetoEn:(int)anIndex withValue:(BOOL)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setRouterVetoEn:anIndex withValue:routerVetoEn[anIndex]];
    routerVetoEn[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARouterVetoEn0Changed object:self userInfo:userInfo];
}

//------------------- Address = 0x0040  Bit Field = 3 ---------------
- (BOOL) preampResetDelayEn:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return preampResetDelayEn[anIndex];
}

- (void) setPreampResetDelayEn:(int)anIndex withValue:(BOOL)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setPreampResetDelayEn:anIndex withValue:preampResetDelayEn[anIndex]];
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APreampResetDelayEnChanged object:self userInfo:userInfo];
}


//------------------- Address = 0x0040  Bit Field = 10..11 ---------------
- (unsigned long) triggerPolarity:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return triggerPolarity[anIndex];
}

- (void) setTriggerPolarity:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    if(aValue > 0x3)aValue = 0x3;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerPolarity:anIndex withValue:triggerPolarity[anIndex]];
    triggerPolarity[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATriggerPolarityChanged object:self userInfo:userInfo];
}
//------------------- Address = 0x0040  Bit Field = 15 ---------------
- (BOOL) writeFlag
{
    return writeFlag;
}

- (void) setWriteFlag:(BOOL)aWriteFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteFlag:writeFlag];
    writeFlag = aWriteFlag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AWriteFlagChanged object:self];
}

//------------------- Address = 0x0040  Bit Field = 15 ---------------
- (unsigned long) decimationFactor
{
    return decimationFactor;
}

- (void) setDecimationFactor:(unsigned long)aDecimationFactor
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDecimationFactor:decimationFactor];
    decimationFactor = aDecimationFactor & 0x7;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADecimationFactorChanged object:self];
}


//------------------- Address = 0x0040  Bit Field = 15 ---------------
- (BOOL) pileupMode:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return pileupMode[anIndex];
}

- (void) setPileupMode:(int)anIndex withValue:(BOOL)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setPileupMode:anIndex withValue:pileupMode[anIndex]];
    pileupMode[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APileupMode0Changed object:self userInfo:userInfo];
}

//------------------- Address = 0x0040  Bit Field = 20 ---------------
- (BOOL)  droppedEventCountMode:(int)anIndex;
{
    if( anIndex<0 || anIndex>10 )return 0;
    return droppedEventCountMode[anIndex];
}
- (void)    setDroppedEventCountMode:(int)anIndex withValue:(BOOL)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;

    if(droppedEventCountMode[anIndex] != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setDroppedEventCountMode:anIndex withValue:droppedEventCountMode[anIndex]];
        droppedEventCountMode[anIndex] = aValue;
        
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADroppedEventCountModeChanged object:self userInfo:userInfo];
    }
}

//------------------- Address = 0x0040  Bit Field = 21 ---------------
- (BOOL)  eventCountMode:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return eventCountMode[anIndex];
   
}
- (void)    setEventCountMode:(int)anIndex withValue:(BOOL)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setEventCountMode:anIndex withValue:eventCountMode[anIndex]];
    eventCountMode[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AEventCountModeChanged object:self userInfo:userInfo];
}
//------------------- Address = 0x0040  Bit Field = 22 ---------------
- (BOOL)  aHitCountMode:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return aHitCountMode[anIndex];
    
}
- (void)  setAHitCountMode:(int)anIndex withValue:(BOOL)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setAHitCountMode:anIndex withValue:aHitCountMode[anIndex]];
    aHitCountMode[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAHitCountModeChanged object:self userInfo:userInfo];
}
//------------------- Address = 0x0040  Bit Field = 23 ---------------
- (BOOL)  discCountMode:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return discCountMode[anIndex];
    
}
- (void)  setDiscCountMode:(int)anIndex withValue:(BOOL)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setDiscCountMode:anIndex withValue:discCountMode[anIndex]];
    discCountMode[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiscCountModeChanged object:self userInfo:userInfo];
}
//------------------- Address = 0x0040  Bit Field = 24..25 ---------------
- (unsigned long) eventExtensionMode:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return eventExtensionMode[anIndex];
}

- (void) setEventExtensionMode:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    if(aValue > 0x3)aValue = 0x3;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setEventExtensionMode:anIndex withValue:eventExtensionMode[anIndex]];
    eventExtensionMode[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AEventExtensionModeChanged object:self userInfo:userInfo];
}

//------------------- Address = 0x0040  Bit Field = 26 ---------------
- (BOOL)  pileupExtensionMode:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return pileupExtensionMode[anIndex];
    
}
- (void)    setPileupExtensionMode:(int)anIndex withValue:(BOOL)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setPileupExtensionMode:anIndex withValue:pileupExtensionMode[anIndex]];
    pileupExtensionMode[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APileupExtensionModeChanged object:self userInfo:userInfo];
    
}

//------------------- Address = 0x0040  Bit Field = 27 ---------------
- (BOOL)  counterReset:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return counterReset[anIndex];
    
}
- (void)    setCounterReset:(int)anIndex withValue:(BOOL)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setCounterReset:anIndex withValue:counterReset[anIndex]];
    counterReset[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ACounterResetChanged object:self userInfo:userInfo];
}

//------------------- Address = 0x0040  Bit Field = 30 ---------------
- (BOOL)  pileupWaveformOnlyMode:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return pileupWaveformOnlyMode[anIndex];
    
}
- (void)    setPileupWaveformOnlyMode:(int)anIndex withValue:(BOOL)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setPileupWaveformOnlyMode:anIndex withValue:pileupWaveformOnlyMode[anIndex]];
    pileupWaveformOnlyMode[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APileupWaveformOnlyModeChanged object:self userInfo:userInfo];
}

//------------------- Address = 0x0080  Bit Field = 15..0 ---------------
- (unsigned long) ledThreshold:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return ledThreshold[anIndex];
}

- (void) setLedThreshold:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    if(aValue > 0xFFFF)aValue = 0xFFFF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setLedThreshold:anIndex withValue:ledThreshold[anIndex]];
    ledThreshold[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ALedThreshold0Changed object:self userInfo:userInfo];
}

//------------------- Address = 0x0080  Bit Field = 23..16 ---------------
- (unsigned long) preampResetDelay:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return preampResetDelay[anIndex];
}

- (void) setPreampResetDelay:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    if(aValue > 0xFF)aValue = 0xFF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setPreampResetDelay:anIndex withValue:preampResetDelay[anIndex]];
    preampResetDelay[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APreampResetDelay0Changed object:self userInfo:userInfo];
}

//------------------- Address = 0x00C0  Bit Field = N/A ---------------
- (unsigned long) cFDFraction:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return cFDFraction[anIndex];
}

- (void) setCFDFraction:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    if(aValue>100)aValue = 100;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setCFDFraction:anIndex withValue:cFDFraction[anIndex]];
    cFDFraction[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ACFDFractionChanged object:self userInfo:userInfo];
}

//------------------- Address = 0x0100  Bit Field = 9..0 ---------------
//Sets the (maximum) size of the event packets.  Packet will be 4 bytes longer than the value written to this register. (10ns per count)
//for now we actuall only use the first value and write it to all channels. We keep the array for future expansion.
- (unsigned long) rawDataLength:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return rawDataLength[anIndex];
}

- (void) setRawDataLength:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    if(aValue > 0x3FF)aValue = 0x3FF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setRawDataLength:anIndex withValue:rawDataLength[anIndex]];
    rawDataLength[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARawDataLengthChanged object:self userInfo:userInfo];
}

//------------------- Address = 0x0140  Bit Field = 9..0 ---------------
//Waveform offset value. (10 ns per count)
//for now we acuall only use the first value and write it to all channels. We keep the array for future expansion.
- (unsigned long) rawDataWindow:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return rawDataWindow[anIndex];
}

- (void) setRawDataWindow:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    if(aValue > 0x3FF)aValue = 0x3FF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setRawDataWindow:anIndex withValue:rawDataWindow[anIndex]];
    rawDataWindow[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARawDataWindowChanged object:self userInfo:userInfo];
}

//------------------- Address = 0x0180  Bit Field = 6..0 ---------------
- (unsigned long) dWindow:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return dWindow[anIndex];
}

- (void) setDWindow:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    if(aValue > 0x7F)aValue = 0x7F;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setDWindow:anIndex withValue:dWindow[anIndex]];
    dWindow[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADWindowChanged object:self userInfo:userInfo];
}

//------------------- Address = 0x01C0  Bit Field = 6..0 ---------------
- (unsigned long) kWindow:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return kWindow[anIndex];
}

- (void) setKWindow:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    if(aValue > 0x7F)aValue = 0x7F;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setKWindow:anIndex withValue:kWindow[anIndex]];
    kWindow[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AKWindowChanged object:self userInfo:userInfo];
}

//------------------- Address = 0x0200  Bit Field = 9..0 ---------------
- (unsigned long) mWindow:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return mWindow[anIndex];
}

- (void) setMWindow:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    if(aValue > 0x3FF)aValue = 0x3FF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setMWindow:anIndex withValue:mWindow[anIndex]];
    mWindow[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AMWindowChanged object:self userInfo:userInfo];
}
//------------------- Address = 0x0240  Bit Field = 6..0 ---------------
- (unsigned long) d3Window:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return d3Window[anIndex];
}

- (void) setD3Window:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    if(aValue > 0x7F)aValue = 0x7F;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setD3Window:anIndex withValue:d3Window[anIndex]];
    d3Window[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AD3WindowChanged object:self userInfo:userInfo];
}


//------------------- Address = 0x0280  Bit Field = N/A ---------------
- (unsigned long) discWidth:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return discWidth[anIndex];
}

- (void) setDiscWidth:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setDiscWidth:anIndex withValue:discWidth[anIndex]];
    discWidth[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiscWidthChanged object:self userInfo:userInfo];
}

//------------------- Address = 0x02C0  Bit Field = 13..0 ---------------
- (unsigned long) baselineStart:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return baselineStart[anIndex];
}

- (void) setBaselineStart:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    if(aValue > 0x3FFF)aValue = 0x3FFF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setBaselineStart:anIndex withValue:baselineStart[anIndex]];
    baselineStart[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ABaselineStartChanged object:self userInfo:userInfo];
}
//------------------- Address = 0x0300  Bit Field = 3 .. 0 ---------------
- (unsigned long) p1Window:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return p1Window[anIndex];
}

- (void) setP1Window:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    if(aValue > 0x7F)aValue = 0x7F;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setP1Window:anIndex withValue:p1Window[anIndex]];
    p1Window[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AP1WindowChanged object:self userInfo:userInfo];
}

//------------------- Address = 0x0400  Bit Field = 3..0 ---------------
- (unsigned long) dacChannelSelect
{
    return dacChannelSelect;
}

- (void) setDacChannelSelect:(unsigned long)aValue
{
    if(aValue > 0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDacChannelSelect:dacChannelSelect];
    dacChannelSelect = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADacChannelSelectChanged object:self];
}

//------------------- Address = 0x0400  Bit Field = 7..0 ---------------
- (unsigned long) dacAttenuation
{
    return dacAttenuation;
}

- (void) setDacAttenuation:(unsigned long)aValue
{
    if(aValue > 0xFF)aValue = 0xFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDacAttenuation:dacAttenuation];
    dacAttenuation = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADacAttenuationChanged object:self];
}

//------------------- Address = 0x0404  Bit Field = N/A ---------------
- (unsigned long) p2Window
{
    return p2Window;
}

- (void) setP2Window:(unsigned long)aValue
{
    if(aValue > 0x1FF)aValue = 0x1FF;
    
    if(p2Window != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setP2Window:p2Window];
        p2Window = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AP2WindowChanged object:self];
    }
}

//------------------- Address = 0x0408  Bit Field = N/A ---------------
- (unsigned long) ilaConfig
{
    return ilaConfig;
}

- (void) setIlaConfig:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIlaConfig:ilaConfig];
    ilaConfig = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AIlaConfigChanged object:self];
}

//------------------- Address = 0x040C  Bit Field = 1 ---------------
- (BOOL) phaseHunt
{
    return phaseHunt;
}

- (void) setPhaseHunt:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPhaseHunt:phaseHunt];
    phaseHunt = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhaseHuntChanged object:self];
}

//------------------- Address = 0x040C  Bit Field = 2 ---------------
- (BOOL) loadbaseline
{
    return loadbaseline;
}

- (void) setLoadbaseline:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLoadbaseline:loadbaseline];
    loadbaseline = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ALoadbaselineChanged object:self];
}

//------------------- Address = 0x040C  Bit Field = 4 ---------------
- (BOOL) phaseHuntDebug
{
    return phaseHuntDebug;
}

- (void) setPhaseHuntDebug:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPhaseHuntDebug:phaseHuntDebug];
    phaseHuntDebug = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhaseHuntDebugChanged object:self];
}

//------------------- Address = 0x040C  Bit Field = 5 ---------------
- (BOOL) phaseHuntProceed
{
    return phaseHuntProceed;
}

- (void) setPhaseHuntProceed:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPhaseHuntProceed:phaseHuntProceed];
    phaseHuntProceed = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhaseHuntProceedChanged object:self];
}

//------------------- Address = 0x040C  Bit Field = 6 ---------------
- (BOOL) phaseDec
{
    return phaseDec;
}

- (void) setPhaseDec:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPhaseDec:phaseDec];
    phaseDec = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhaseDecChanged object:self];
}

//------------------- Address = 0x040C  Bit Field = 7 ---------------
- (BOOL) phaseInc
{
    return phaseInc;
}

- (void) setPhaseInc:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPhaseInc:phaseInc];
    phaseInc = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhaseIncChanged object:self];
}

//------------------- Address = 0x040C  Bit Field = 8 ---------------
- (BOOL) serdesPhaseInc
{
    return serdesPhaseInc;
}

- (void) setSerdesPhaseInc:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerdesPhaseInc:serdesPhaseInc];
    serdesPhaseInc = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASerdesPhaseIncChanged object:self];
}

//------------------- Address = 0x040C  Bit Field = 9 ---------------
- (BOOL) serdesPhaseDec
{
    return serdesPhaseDec;
}

- (void) setSerdesPhaseDec:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerdesPhaseDec:serdesPhaseDec];
    serdesPhaseDec = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASerdesPhaseDecChanged object:self];
}

//------------------- Address = 0x0410  Bit Field = N/A ---------------
- (unsigned long) diagMuxControl
{
    return diagMuxControl;
}

- (void) setDiagMuxControl:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDiagMuxControl:diagMuxControl];
    diagMuxControl = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiagMuxControlChanged object:self];
}

//------------------- Address = 0x0414  Bit Field = 9..0 ---------------
- (unsigned long) peakSensitivity
{
    return peakSensitivity;
}

- (void) setPeakSensitivity:(unsigned long)aValue
{
    if(aValue > 0xFF)aValue = 0xFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setPeakSensitivity:peakSensitivity];
    peakSensitivity = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APeakSensitivityChanged object:self];
}
//------------------- Address = 0x0418  Bit Field = 13..0 ---------------
- (unsigned long) baselineDelay
{
    return baselineDelay;
}

- (void) setBaselineDelay:(unsigned long)aValue
{
    if(aValue > 0x3FFF)aValue = 0x3FFF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setBaselineDelay:baselineDelay];
    baselineDelay = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ABaselineDelayChanged object:self];
}

//------------------- Address = 0x041C  Bit Field = 13..0 ---------------
- (unsigned long) diagInput
{
    return diagInput;
}

- (void) setDiagInput:(unsigned long)aValue
{
    if(aValue > 0x3FFF)aValue = 0x3FFF;
    if(diagInput != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setDiagInput:diagInput];
        diagInput = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiagInputChanged object:self];
    }
}

//------------------- Address = 0x0420  Bit Field = N/A ---------------
- (unsigned long) diagChannelEventSel
{
    return diagChannelEventSel;
}

- (void) setDiagChannelEventSel:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDiagChannelEventSel:diagChannelEventSel];
    diagChannelEventSel = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiagChannelEventSelChanged object:self];
}

//------------------- Address = 0x0424  Bit Field = 3..0 ---------------
- (unsigned long) rj45SpareIoMuxSel
{
    return rj45SpareIoMuxSel;
}

- (void) setRj45SpareIoMuxSel:(unsigned long)aValue
{
    if(aValue > 0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setRj45SpareIoMuxSel:rj45SpareIoMuxSel];
    rj45SpareIoMuxSel = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARj45SpareIoMuxSelChanged object:self];
}

//------------------- Address = 0x0424  Bit Field = 4 ---------------
- (BOOL) rj45SpareIoDir
{
    return rj45SpareIoDir;
}

- (void) setRj45SpareIoDir:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRj45SpareIoDir:rj45SpareIoDir];
    rj45SpareIoDir = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARj45SpareIoDirChanged object:self];
}

//------------------- Address = 0x0428  Bit Field = N/A ---------------
- (unsigned long) ledStatus
{
    return ledStatus;
}

- (void) setLedStatus:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLedStatus:ledStatus];
    ledStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ALedStatusChanged object:self];
}

//------------------- Address = 0x048C  Bit Field = 31..0 ---------------
- (unsigned long) liveTimestampLsb
{
    return liveTimestampLsb;
}

- (void) setLiveTimestampLsb:(unsigned long)aValue
{
    if(liveTimestampLsb != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setLiveTimestampLsb:liveTimestampLsb];
        liveTimestampLsb = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ALiveTimestampLsbChanged object:self];
    }
}

//------------------- Address = 0x0490  Bit Field = 15..0 ---------------
- (unsigned long) liveTimestampMsb
{
    return liveTimestampMsb;
}

- (void) setLiveTimestampMsb:(unsigned long)aValue
{
    if(aValue > 0xFFFF)aValue = 0xFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setLiveTimestampMsb:liveTimestampMsb];
    liveTimestampMsb = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ALiveTimestampMsbChanged object:self];
}


//------------------- Address = 0x0500  Bit Field = 1 ---------------
- (BOOL) diagIsync
{
    return diagIsync;
}

- (void) setDiagIsync:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDiagIsync:diagIsync];
    diagIsync = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiagIsyncChanged object:self];
}

//------------------- Address = 0x0500  Bit Field = 19 ---------------
- (BOOL) serdesSmLostLock
{
    return serdesSmLostLock;
}

- (void) setSerdesSmLostLock:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerdesSmLostLock:serdesSmLostLock];
    serdesSmLostLock = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASerdesSmLostLockChanged object:self];
}

//------------------- Address = 0x0500  Bit Field = 22,23,24,25,26,27,28,29,30,31 ---------------
- (BOOL) overflowFlagChan:(int)anIndex
{
    if(anIndex>=0 && anIndex<kNumGretina4AChannels) return overflowFlagChan[anIndex];
    else return 0;
}

- (void) setOverflowFlagChan:(int)anIndex withValue:(BOOL)aValue
{
    if(anIndex>=0 && anIndex<kNumGretina4AChannels){
        [[[self undoManager] prepareWithInvocationTarget:self] setOverflowFlagChan:anIndex withValue:anIndex];
        overflowFlagChan[anIndex] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AOverflowFlagChanChanged object:self];
    }
}


//------------------- Address = 0x0504  Bit Field = N/A ---------------
- (unsigned long) triggerConfig
{
    return triggerConfig;
}

- (void) setTriggerConfig:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerConfig:triggerConfig];
    triggerConfig = aValue & 0x3;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATriggerConfigChanged object:self];
}

//------------------- Address = 0x0508  Bit Field = N/A ---------------
- (unsigned long) phaseErrorCount
{
    return phaseErrorCount;
}

- (void) setPhaseErrorCount:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPhaseErrorCount:phaseErrorCount];
    phaseErrorCount = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhaseErrorCountChanged object:self];
}

//------------------- Address = 0x050C  Bit Field = 15..0 ---------------
- (unsigned long) phaseStatus
{
    return phaseStatus;
}

- (void) setPhaseStatus:(unsigned long)aValue
{
    if(aValue > 0xFFFF)aValue = 0xFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setPhaseStatus:phaseStatus];
    phaseStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhaseStatusChanged object:self];
}

//------------------- Address = 0x0510  Bit Field = 7..0 ---------------
- (unsigned long) phase0:(int)anIndex
{
    if( anIndex<0 || anIndex>3 )return 0;
    return phase0[anIndex];
}

- (void) setPhase0:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 3)  return;
    if(aValue > 0xFF)aValue = 0xFF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setPhase0:anIndex withValue:phase0[anIndex]];
    phase0[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhase0Changed object:self userInfo:userInfo];
}

//------------------- Address = 0x0510  Bit Field = 15..8 ---------------
- (unsigned long) phase1:(int)anIndex
{
    if( anIndex<0 || anIndex>3 )return 0;
    return phase1[anIndex];
}

- (void) setPhase1:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 3)  return;
    if(aValue > 0xFF)aValue = 0xFF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setPhase1:anIndex withValue:phase1[anIndex]];
    phase1[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhase1Changed object:self userInfo:userInfo];
}

//------------------- Address = 0x0510  Bit Field = 23..16 ---------------
- (unsigned long) phase2:(int)anIndex
{
    if( anIndex<0 || anIndex>3 )return 0;
    return phase2[anIndex];
}

- (void) setPhase2:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 3)  return;
    if(aValue > 0xFF)aValue = 0xFF;
    
    if(phase2[anIndex] != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setPhase2:anIndex withValue:phase2[anIndex]];
        phase2[anIndex] = aValue;
        
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhase2Changed object:self userInfo:userInfo];
    }
}

//------------------- Address = 0x0510  Bit Field = 31..24 ---------------
- (unsigned long) phase3:(int)anIndex
{
    if( anIndex<0 || anIndex>3 )return 0;
    return phase3[anIndex];
}

- (void) setPhase3:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 3)  return;
    if(aValue > 0xFF)aValue = 0xFF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setPhase3:anIndex withValue:phase3[anIndex]];
    phase3[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhase3Changed object:self userInfo:userInfo];
}

//------------------- Address = 0x051C  Bit Field = N/A ---------------
- (unsigned long) serdesPhaseValue
{
    return serdesPhaseValue;
}

- (void) setSerdesPhaseValue:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerdesPhaseValue:serdesPhaseValue];
    serdesPhaseValue = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASerdesPhaseValueChanged object:self];
}

//------------------- Address = 0x0600  Bit Field = 15..12  ---------------
- (unsigned long) pcbRevision
{
    return pcbRevision;
}

- (void) setPcbRevision:(unsigned long)aValue
{
    if(aValue > 0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setPcbRevision:pcbRevision];
    pcbRevision = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APcbRevisionChanged object:self];
}

//------------------- Address = 0x0600  Bit Field = 11..8 ---------------
- (unsigned long) fwType
{
    return fwType;
}

- (void) setFwType:(unsigned long)aValue
{
    if(aValue > 0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setFwType:fwType];
    fwType = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFwTypeChanged object:self];
}

//------------------- Address = 0x0600  Bit Field = 7..4  ---------------
- (unsigned long) mjrCodeRevision
{
    return mjrCodeRevision;
}

- (void) setMjrCodeRevision:(unsigned long)aValue
{
    if(aValue > 0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setMjrCodeRevision:mjrCodeRevision];
    mjrCodeRevision = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AMjrCodeRevisionChanged object:self];
}

//------------------- Address = 0x0600  Bit Field = 3..0  ---------------
- (unsigned long) minCodeRevision
{
    return minCodeRevision;
}

- (void) setMinCodeRevision:(unsigned long)aValue
{
    if(aValue > 0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setMinCodeRevision:minCodeRevision];
    minCodeRevision = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AMinCodeRevisionChanged object:self];
}

//------------------- Address = 0x0604  Bit Field = 31..0 ---------------
- (unsigned long) codeDate
{
    return codeDate;
}

- (void) setCodeDate:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCodeDate:codeDate];
    codeDate = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ACodeDateChanged object:self];
}

//------------------- Address = 0x0608  Bit Field = N/A ---------------
- (unsigned long) tSErrCntCtrl
{
    return tSErrCntCtrl;
}

- (void) setTSErrCntCtrl:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTSErrCntCtrl:tSErrCntCtrl];
    tSErrCntCtrl = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATSErrCntCtrlChanged object:self];
}

//------------------- Address = 0x060C  Bit Field = N/A ---------------
- (unsigned long) tSErrorCount
{
    return tSErrorCount;
}

- (void) setTSErrorCount:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTSErrorCount:tSErrorCount];
    tSErrorCount = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATSErrorCountChanged object:self];
}

//------------------- Address = 0x0700  Bit Field = 31..0 ---------------
- (unsigned long) droppedEventCount:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return droppedEventCount[anIndex];
}

- (void) setDroppedEventCount:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setDroppedEventCount:anIndex withValue:droppedEventCount[anIndex]];
    droppedEventCount[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADroppedEventCountChanged object:self userInfo:userInfo];
}

//------------------- Address = 0x0740  Bit Field = 31..0 ---------------
- (unsigned long) acceptedEventCount:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return acceptedEventCount[anIndex];
}

- (void) setAcceptedEventCount:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    if(acceptedEventCount[anIndex] != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setAcceptedEventCount:anIndex withValue:acceptedEventCount[anIndex]];
        acceptedEventCount[anIndex] = aValue;
        
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAcceptedEventCountChanged object:self userInfo:userInfo];
    }
}

//------------------- Address = 0x0780  Bit Field = 31..0 ---------------
- (unsigned long) ahitCount:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return ahitCount[anIndex];
}

- (void) setAhitCount:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setAhitCount:anIndex withValue:ahitCount[anIndex]];
    ahitCount[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAhitCountChanged object:self userInfo:userInfo];
}

//------------------- Address = 0x07C0  Bit Field = 31..0 ---------------
- (unsigned long) discCount:(int)anIndex
{
    if( anIndex<0 || anIndex>10 )return 0;
    return discCount[anIndex];
}

- (void) setDiscCount:(int)anIndex withValue:(unsigned long)aValue
{
    if(anIndex < 0 || anIndex > 10)  return;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setDiscCount:anIndex withValue:discCount[anIndex]];
    discCount[anIndex] = aValue;
        
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiscCountChanged object:self userInfo:userInfo];
}

//------------------- Address = 0x0800  Bit Field = 31..0 ---------------
- (unsigned long) auxIoRead
{
    return auxIoRead;
}

- (void) setAuxIoRead:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAuxIoRead:auxIoRead];
    auxIoRead = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAuxIoReadChanged object:self];
}

//------------------- Address = 0x0804  Bit Field = 31..0 ---------------
- (unsigned long) auxIoWrite
{
    return auxIoWrite;
}

- (void) setAuxIoWrite:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAuxIoWrite:auxIoWrite];
    auxIoWrite = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAuxIoWriteChanged object:self];
}

//------------------- Address = 0x0808  Bit Field = 31..0 ---------------
- (unsigned long) auxIoConfig
{
    return auxIoConfig;
}

- (void) setAuxIoConfig:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAuxIoConfig:auxIoConfig];
    auxIoConfig = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAuxIoConfigChanged object:self];
}

//------------------- Address = 0x0848  Bit Field = 2..3 ---------------
- (unsigned long) sdPem
{
    return sdPem;
}

- (void) setSdPem:(unsigned long)aValue
{
    if(aValue > 0x0)aValue = 0x0;
    [[[self undoManager] prepareWithInvocationTarget:self] setSdPem:sdPem];
    sdPem = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASdPemChanged object:self];}

//------------------- Address = 0x0848  Bit Field = 9 ---------------
- (BOOL) sdSmLostLockFlag
{
    return sdSmLostLockFlag;
}

- (void) setSdSmLostLockFlag:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSdSmLostLockFlag:sdSmLostLockFlag];
    sdSmLostLockFlag = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASdSmLostLockFlagChanged object:self];
}

//------------------- Address = 0x084C  Bit Field = 31..0 ---------------
- (unsigned long) adcConfig
{
    return adcConfig;
}

- (void) setAdcConfig:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcConfig:adcConfig];
    adcConfig = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAdcConfigChanged object:self];
}

//------------------- Address = 0x0900  Bit Field = 0 ---------------
- (BOOL) configMainFpga
{
    return configMainFpga;
}

- (void) setConfigMainFpga:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setConfigMainFpga:configMainFpga];
    configMainFpga = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AConfigMainFpgaChanged object:self];
}

//------------------- Address = 0x0908  Bit Field = 0 ---------------
- (BOOL) powerOk
{
    return powerOk;
}

- (void) setPowerOk:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPowerOk:powerOk];
    powerOk = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APowerOkChanged object:self];
}

//------------------- Address = 0x0908  Bit Field = 1 ---------------
- (BOOL) overVoltStat
{
    return overVoltStat;
}

- (void) setOverVoltStat:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOverVoltStat:overVoltStat];
    overVoltStat = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AOverVoltStatChanged object:self];
}

//------------------- Address = 0x0908  Bit Field = 2 ---------------
- (BOOL) underVoltStat
{
    return underVoltStat;
}

- (void) setUnderVoltStat:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUnderVoltStat:underVoltStat];
    underVoltStat = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AUnderVoltStatChanged object:self];
}

//------------------- Address = 0x0908  Bit Field = 3 ---------------
- (BOOL) temp0Sensor
{
    return temp0Sensor;
}

- (void) setTemp0Sensor:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTemp0Sensor:temp0Sensor];
    temp0Sensor = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATemp0SensorChanged object:self];
}

//------------------- Address = 0x0908  Bit Field = 4 ---------------
- (BOOL) temp1Sensor
{
    return temp1Sensor;
}

- (void) setTemp1Sensor:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTemp1Sensor:temp1Sensor];
    temp1Sensor = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATemp1SensorChanged object:self];
}

//------------------- Address = 0x0908  Bit Field = 5 ---------------
- (BOOL) temp2Sensor
{
    return temp2Sensor;
}

- (void) setTemp2Sensor:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTemp2Sensor:temp2Sensor];
    temp2Sensor = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATemp2SensorChanged object:self];
}

//------------------- Address = 0x0910  Bit Field = 0 ---------------
- (BOOL) clkSelect0
{
    return clkSelect0;
}

- (void) setClkSelect0:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClkSelect0:clkSelect0];
    clkSelect0 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AClkSelect0Changed object:self];
}

//------------------- Address = 0x0910  Bit Field = 1 ---------------
- (BOOL) clkSelect1
{
    return clkSelect1;
}

- (void) setClkSelect1:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClkSelect1:clkSelect1];
    clkSelect1 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AClkSelect1Changed object:self];
}

//------------------- Address = 0x0910  Bit Field = 4 ---------------
- (BOOL) flashMode
{
    return flashMode;
}

- (void) setFlashMode:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFlashMode:flashMode];
    flashMode = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFlashModeChanged object:self];
}

//------------------- Address = 0X0920  Bit Field = 15..0 ---------------
- (unsigned long) serialNum
{
    return serialNum;
}

- (void) setSerialNum:(unsigned long)aValue
{
    if(aValue > 0xFFFF)aValue = 0xFFFF;
    serialNum = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASerialNumChanged object:self];
}

//------------------- Address = 0X0920  Bit Field = 23..16 ---------------
- (unsigned long) boardRevNum
{
    return boardRevNum;
}

- (void) setBoardRevNum:(unsigned long)aValue
{
    if(aValue > 0xFF)aValue = 0xFF;
    boardRevNum = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ABoardRevNumChanged object:self];
}

//------------------- Address = 0X0920  Bit Field = 31..24 ---------------
- (unsigned long) vhdlVerNum
{
    return vhdlVerNum;
}

- (void) setVhdlVerNum:(unsigned long)aValue
{
    if(aValue > 0xFF)aValue = 0xFF;
    if(vhdlVerNum != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setVhdlVerNum:vhdlVerNum];
        vhdlVerNum = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AVhdlVerNumChanged object:self];
    }
}

//------------------- Address = 0x1000  Bit Field = 31..0 ---------------
- (unsigned long) fifoAccess
{
    return fifoAccess;
}

- (void) setFifoAccess:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFifoAccess:fifoAccess];
    fifoAccess = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFifoAccessChanged object:self];
}

@end

@implementation ORGretina4AModel (private)

- (void) updateDownLoadProgress
{
	//call only from main thread
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFpgaDownProgressChanged object:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:(self) selector:@selector(updateDownLoadProgress) object:nil];
	if(downLoadMainFPGAInProgress)[self performSelector:@selector(updateDownLoadProgress) withObject:nil afterDelay:.1];
}

- (void) setFpgaDownProgress:(short)aFpgaDownProgress
{
	[progressLock lock];
    fpgaDownProgress = aFpgaDownProgress;
	[progressLock unlock];
}

- (void) setProgressStateOnMainThread:(NSString*)aState
{
	if(!aState)aState = @"--";
	//this post a notification to the GUI so it must be done on the main thread
	[self performSelectorOnMainThread:@selector(setMainFPGADownLoadState:) withObject:aState waitUntilDone:NO];
}

- (void) fpgaDownLoadThread:(NSData*)dataFromFile
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	@try {
		[dataFromFile retain];

		[self setProgressStateOnMainThread:@"Block Erase"];
		if(!stopDownLoadingMainFPGA) [self blockEraseFlash];
		[self setProgressStateOnMainThread:@"Programming"];
		if(!stopDownLoadingMainFPGA) [self programFlashBuffer:dataFromFile];
		[self setProgressStateOnMainThread:@"Verifying"];
        
		if(!stopDownLoadingMainFPGA) {
			if (![self verifyFlashBuffer:dataFromFile]) {
				[NSException raise:@"Gretina4A Exception" format:@"Verification of flash failed."];	
			}
            else {
                //reload the fpga from flash
                [self writeToAddress:0x900 aValue:kGretina4AResetMainFPGACmd];
                [self writeToAddress:0x900 aValue:kGretina4AReloadMainFPGACmd];
                [self setProgressStateOnMainThread:  @"Finishing$Flash Memory-->FPGA"];
                uint32_t statusRegValue = [self readFromAddress:0x904];
                while(!(statusRegValue & kGretina4AMainFPGAIsLoaded)) {
                    if(stopDownLoadingMainFPGA)return;
                    statusRegValue = [self readFromAddress:0x904];
                }
                NSLog(@"Gretina4(%d): FPGA Load Finished - No Errors\n",[self uniqueIdNumber]);

            }
		}
		[self setProgressStateOnMainThread:@"Loading FPGA"];
		if(!stopDownLoadingMainFPGA) [self reloadMainFPGAFromFlash];
        else NSLog(@"Gretina4(%d): FPGA Load Manually Stopped\n",[self uniqueIdNumber]);
		[self setProgressStateOnMainThread:@"--"];
	}
	@catch(NSException* localException) {
		[self setProgressStateOnMainThread:@"Exception"];
	}
	@finally {
		[self performSelectorOnMainThread:@selector(downloadingMainFPGADone) withObject:nil waitUntilDone:NO];
		[dataFromFile release];
	}
	[pool release];
}

- (void) blockEraseFlash
{
	/* We only erase the blocks currently used in the Gretina4A specification. */
    [self writeToAddress:0x910 aValue:kGretina4AFlashEnableWrite]; //Enable programming
	[self setFpgaDownProgress:0.];
    unsigned long count = 0;
    unsigned long end = (kGretina4AFlashBlocks / 4) * kGretina4AFlashBlockSize;
    unsigned long addr;
    [self setProgressStateOnMainThread:  @"Block Erase"];
    for (addr = 0; addr < end; addr += kGretina4AFlashBlockSize) {
        
		if(stopDownLoadingMainFPGA)return;
		@try {
            [self setFirmwareStatusString:       [NSString stringWithFormat:@"%lu of %d Blocks Erased",count,kGretina4AFlashBufferBytes]];
 			[self setFpgaDownProgress: 100. * (count+1)/(float)kGretina4AUsedFlashBlocks];
           
            [self writeToAddress:0x980 aValue:addr];
            [self writeToAddress:0x98C aValue:kGretina4AFlashBlockEraseCmd];
            [self writeToAddress:0x98C aValue:kGretina4AFlashConfirmCmd];
            unsigned long stat = [self readFromAddress:0x904];
            while (stat & kFlashBusy) {
                if(stopDownLoadingMainFPGA)break;
                stat = [self readFromAddress:0x904];
            }
            count++;
		}
		@catch(NSException* localException) {
			NSLog(@"Gretina4A exception erasing flash.\n");
		}
	}
    
	[self setFpgaDownProgress: 100];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	[self setFpgaDownProgress: 0];
}

- (void) programFlashBuffer:(NSData*)theData
{
    unsigned long totalSize = [theData length];
    
    [self setProgressStateOnMainThread:@"Programming"];
    [self setFirmwareStatusString: [NSString stringWithFormat:@"FPGA File Size %lu KB",totalSize/1000]];
    [self setFpgaDownProgress:0.];

    [self writeToAddress:0x980 aValue:0x00];
    [self writeToAddress:0x98C aValue:kGretina4AFlashReadArrayCmd];
    
     unsigned long address = 0x0;
     while (address < totalSize ) {
         unsigned long numberBytesToWrite;
         if(totalSize-address >= kGretina4AFlashBufferBytes){
             numberBytesToWrite = kGretina4AFlashBufferBytes; //whole block
         }
         else {
             numberBytesToWrite = totalSize - address; //near eof, so partial block
         }
         
         [self programFlashBufferBlock:theData address:address numberBytes:numberBytesToWrite];
         
         address += numberBytesToWrite;
         if(stopDownLoadingMainFPGA)break;
         

         [self setFirmwareStatusString: [NSString stringWithFormat:@"Flashed: %lu/%lu KB",address/1000,totalSize/1000]];
         
         [self setFpgaDownProgress:100. * address/(float)totalSize];

         if(stopDownLoadingMainFPGA)break;
         
     }
     if(stopDownLoadingMainFPGA)return;

    [self writeToAddress:0x980 aValue:0x00];
    [self writeToAddress:0x98C aValue:kGretina4AFlashReadArrayCmd];
    [self writeToAddress:0x910 aValue:0x00];

    [self setProgressStateOnMainThread:@"Programming"];
}

- (void) programFlashBufferBlock:(NSData*)theData address:(unsigned long)anAddress numberBytes:(unsigned long)aNumber
{
    //issue the set-up command at the starting address
    [self writeToAddress:0x980 aValue:anAddress];
    [self writeToAddress:0x98C aValue:kGretina4AFlashWriteCmd];
    unsigned char* theDataBytes = (unsigned char*)[theData bytes];
    unsigned long statusRegValue;
	while(1) {
        if(stopDownLoadingMainFPGA)return;
		
		// Checking status to make sure that flash is ready
        unsigned long statusRegValue = [self readFromAddress:0x904];
		
		if ( (statusRegValue & kFlashBusy)  == kFlashBusy ) {
            //not ready, so re-issue the set-up command
            [self writeToAddress:0x980 aValue:anAddress];
            [self writeToAddress:0x98C aValue:kGretina4AFlashWriteCmd];
		}
        else break;
	}
    
	//Set the word count. Max is 0xF.
	unsigned long valueToWrite = (aNumber/2) - 1;
    [self writeToAddress:0x98C aValue:valueToWrite];
	
	// Loading all the words in
    /* Load the words into the bufferToWrite */
	unsigned long i;
	for ( i=0; i<aNumber; i+=4 ) {
        unsigned long* lPtr = (unsigned long*)&theDataBytes[anAddress+i];
        [self writeToAddress:0x984 aValue:lPtr[0]];
	}
	
	// Confirm the write
    [self writeToAddress:0x98C aValue:kGretina4AFlashConfirmCmd];
	
    //wait until the buffer is available again
    statusRegValue = [self readFromAddress:0x904];
    while(statusRegValue & kFlashBusy) {
        if(stopDownLoadingMainFPGA)break;
        statusRegValue = [self readFromAddress:0x904];
    }
}

- (BOOL) verifyFlashBuffer:(NSData*)theData
{
    unsigned long totalSize = [theData length];
    unsigned char* theDataBytes = (unsigned char*)[theData bytes];
    
    [self setProgressStateOnMainThread:@"Verifying"];
    [self setFirmwareStatusString: [NSString stringWithFormat:@"FPGA File Size %lu KB",totalSize/1000]];
    [self setFpgaDownProgress:0.];
    
    /* First reset to make sure it is read mode. */
    [self writeToAddress:0x980 aValue:0x0];
    [self writeToAddress:0x98C aValue:kGretina4AFlashReadArrayCmd];
    
    unsigned long errorCount =   0;
    unsigned long address    =   0;
    unsigned long valueToCompare;
    
    while ( address < totalSize ) {
        unsigned long valueToRead = [self readFromAddress:0x984];
        
        /* Now compare to file*/
        if ( address + 3 < totalSize) {
            unsigned long* ptr = (unsigned long*)&theDataBytes[address];
            valueToCompare = ptr[0];
        }
        else {
            //less than four bytes left
            unsigned long numBytes = totalSize - address - 1;
            valueToCompare = 0;
            unsigned long i;
            for ( i=0;i<numBytes;i++) {
                valueToCompare += (((unsigned long)theDataBytes[address]) << i*8) & (0xFF << i*8);
            }
        }
        if ( valueToRead != valueToCompare ) {
            [self setProgressStateOnMainThread:@"Error"];
            [self setFirmwareStatusString: @"Comparision Error"];
            [self setFpgaDownProgress:0.];
            errorCount++;
        }
        
        [self setFirmwareStatusString: [NSString stringWithFormat:@"Verified: %lu/%lu KB Errors: %lu",address/1000,totalSize/1000,errorCount]];
        [self setFpgaDownProgress:100. * address/(float)totalSize];
        
        address += 4;
    }
    if(errorCount==0){
        [self setProgressStateOnMainThread:@"Done"];
        [self setFirmwareStatusString: @"No Errors"];
        [self setFpgaDownProgress:0.];
        return YES;
    }
    else {
        [self setProgressStateOnMainThread:@"Errors"];
        [self setFirmwareStatusString: @"Comparision Errors"];

        return NO;
    }
}

- (void) reloadMainFPGAFromFlash
{
    
    [self writeToAddress:0x900 aValue:kGretina4AResetMainFPGACmd];
    [self writeToAddress:0x900 aValue:kGretina4AReloadMainFPGACmd];
	
    unsigned long statusRegValue=[self readFromAddress:0x904];

    while(!(statusRegValue & kGretina4AMainFPGAIsLoaded)) {
        if(stopDownLoadingMainFPGA)return;
        statusRegValue=[self readFromAddress:0x904];
    }
}

- (void) downloadingMainFPGADone
{
	[fpgaProgrammingThread release];
	fpgaProgrammingThread = nil;
	
	if(!stopDownLoadingMainFPGA) NSLog(@"Programming Complete.\n");
	else						 NSLog(@"Programming manually stopped before done\n");
	[self setDownLoadMainFPGAInProgress: NO];
	
}

- (void) copyFirmwareFileToSBC:(NSString*)firmwarePath
{
    if(!fileQueue){
        fileQueue = [[NSOperationQueue alloc] init];
        [fileQueue setMaxConcurrentOperationCount:1];
        [fileQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    }

    fpgaFileMover = [[ORFileMoverOp alloc] init];
    
    [fpgaFileMover setDelegate:self];
    
    [fpgaFileMover setMoveParams:[firmwarePath stringByExpandingTildeInPath]
                              to:kFPGARemotePath
                      remoteHost:[[[self adapter] sbcLink] IPNumber]
                        userName:[[[self adapter] sbcLink] userName]
                        passWord:[[[self adapter] sbcLink] passWord]];
    
    [fpgaFileMover setVerbose:YES];
    [fpgaFileMover doNotMoveFilesToSentFolder];
    [fpgaFileMover setTransferType:eOpUseSCP];
    [fileQueue addOperation:fpgaFileMover];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == fileQueue && [keyPath isEqual:@"operations"]) {
        if([fileQueue operationCount]==0){
        }
    }
}

- (BOOL) controllerIsSBC
{
    //long removeReturn;
    //return NO; //<<----- temp for testing
    if([[self adapter] isKindOfClass:NSClassFromString(@"ORVmecpuModel")])return YES;
    else return NO;
}

- (void) fileMoverIsDone
{
    BOOL transferOK;
    if ([[fpgaFileMover task] terminationStatus] == 0) {
        NSLog(@"Transferred FPGA Code: %@ to %@:%@\n",[fpgaFileMover fileName],[fpgaFileMover remoteHost],kFPGARemotePath);
        transferOK = YES;
    }
    else {
        NSLogColor([NSColor redColor], @"Failed to transfer FPGA Code to %@\n",[fpgaFileMover remoteHost]);
        transferOK = YES;
    }
    
    [fpgaFileMover release];
    fpgaFileMover  = nil;

    [self setDownLoadMainFPGAInProgress: NO];
    if(transferOK){
        //the FPGA file is now on the SBC, next step is to start the flash process on the SBC

        [self loadFPGAUsingSBC];
    }
}
- (void) loadFPGAUsingSBC
{
    if([self controllerIsSBC]){
        //if an SBC is available we pass the request to flash the fpga. this assumes the .bin file is already there
        SBC_Packet aPacket;
        aPacket.cmdHeader.destination           = kMJD;
        aPacket.cmdHeader.cmdID                 = kMJDFlashGretinaFPGA;
        aPacket.cmdHeader.numberBytesinPayload	= sizeof(MJDFlashGretinaFPGAStruct);
        
        MJDFlashGretinaFPGAStruct* p = (MJDFlashGretinaFPGAStruct*) aPacket.payload;
        p->baseAddress      = [self baseAddress];
        @try {
            NSLog(@"Gretina4A (%d) launching firmware load job in SBC\n",[self uniqueIdNumber]);

            [[[self adapter] sbcLink] send:&aPacket receive:&aPacket];
            
            [[[self adapter] sbcLink] monitorJobFor:self statusSelector:@selector(flashFpgaStatus:)];

        }
        @catch(NSException* e){
            
        }
    }
}
@end
