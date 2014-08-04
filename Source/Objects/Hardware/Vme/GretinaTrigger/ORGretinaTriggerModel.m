//-------------------------------------------------------------------------
//  ORGretinaTriggerModel.m
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
#import "ORGretinaTriggerModel.h"
#import "ORVmeCrateModel.h"
#import "ORFileMoverOp.h"
#import "MJDCmds.h"
#import "ORGretina4MModel.h"
#import "ORRunModel.h"

NSString* ORGretinaTriggerModelDiagnosticCounterChanged = @"ORGretinaTriggerModelDiagnosticCounterChanged";
NSString* ORGretinaTriggerModelIsMasterChanged       = @"ORGretinaTriggerModelIsMasterChanged";
NSString* ORGretinaTriggerSettingsLock				 = @"ORGretinaTriggerSettingsLock";
NSString* ORGretinaTriggerRegisterLock				 = @"ORGretinaTriggerRegisterLock";
NSString* ORGretinaTriggerRegisterIndexChanged       = @"ORGretinaTriggerRegisterIndexChanged";
NSString* ORGretinaTriggerRegisterWriteValueChanged  = @"ORGretinaTriggerRegisterWriteValueChanged";
NSString* ORGretinaTriggerFpgaDownProgressChanged	 = @"ORGretinaTriggerFpgaDownProgressChanged";
NSString* ORGretinaTriggerMainFPGADownLoadStateChanged		= @"ORGretinaTriggerMainFPGADownLoadStateChanged";
NSString* ORGretinaTriggerFpgaFilePathChanged				= @"ORGretinaTriggerFpgaFilePathChanged";
NSString* ORGretinaTriggerMainFPGADownLoadInProgressChanged = @"ORGretinaTriggerMainFPGADownLoadInProgressChanged";
NSString* ORGretinaTriggerFirmwareStatusStringChanged		= @"ORGretinaTriggerFirmwareStatusStringChanged";
NSString* ORGretinaTriggerModelInputLinkMaskChanged = @"ORGretinaTriggerModelInputLinkMaskChanged";
NSString* ORGretinaTriggerSerdesTPowerMaskChanged   = @"ORGretinaTriggerSerdesTPowerMaskChanged";
NSString* ORGretinaTriggerSerdesRPowerMaskChanged   = @"ORGretinaTriggerSerdesRPowerMaskChanged";
NSString* ORGretinaTriggerLvdsPreemphasisCtlMask    = @"ORGretinaTriggerLvdsPreemphasisCtlMask";
NSString* ORGretinaTriggerMiscCtl1RegChanged        = @"ORGretinaTriggerMiscCtl1RegChanged";
NSString* ORGretinaTriggerMiscStatRegChanged        = @"ORGretinaTriggerMiscStatRegChanged";
NSString* ORGretinaTriggerLinkLruCrlRegChanged      = @"ORGretinaTriggerLinkLruCrlRegChanged";
NSString* ORGretinaTriggerLinkLockedRegChanged      = @"ORGretinaTriggerLinkLockedRegChanged";
NSString* ORGretinaTriggerClockUsingLLinkChanged    = @"ORGretinaTriggerClockUsingLLinkChanged";
NSString* ORGretinaTriggerModelInitStateChanged     = @"ORGretinaTriggerModelInitStateChanged";

#define kFPGARemotePath @"GretinaFPGA.bin"
#define kCurrentFirmwareVersion 0x107
#define kTriggerInitDelay  .1

@interface ORGretinaTriggerModel (private)
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

@implementation ORGretinaTriggerModel
#pragma mark •••Static Declarations
//offsets from the base address
typedef struct {
	unsigned long offset;
	NSString* name;
	BOOL accessType;
	BOOL hwType;
} GretinaTriggerRegisterInformation;

#define kReadOnly           0x1
#define kWriteOnly          0x2
#define kReadWrite          0x4
#define kMasterAndRouter    0x1
#define kMasterOnly         0x2
#define kRouterOnly         0x4
#define kDataGenerator      0x8

#define kGretinaTriggerFlashMaxWordCount	0xF
#define kGretinaTriggerFlashBlockSize		(128 * 1024)
#define kGretinaTriggerFlashBlocks          128
#define kGretinaTriggerUsedFlashBlocks      32
#define kGretinaTriggerFlashBufferBytes     32
#define kGretinaTriggerTotalFlashBytes      (kGretinaTriggerFlashBlocks * kGretinaTriggerFlashBlockSize)
#define kFlashBusy                          0x80
#define kGretinaTriggerFlashEnableWrite     0x10
#define kGretinaTriggerFlashDisableWrite	0x0
#define kGretinaTriggerFlashConfirmCmd      0xD0
#define kGretinaTriggerFlashWriteCmd		0xE8
#define kGretinaTriggerFlashBlockEraseCmd	0x20
#define kGretinaTriggerFlashReadArrayCmd	0xFF
#define kGretinaTriggerFlashStatusRegCmd	0x70
#define kGretinaTriggerFlashClearSRCmd      0x50

#define kGretinaTriggerResetMainFPGACmd     0x30
#define kGretinaTriggerReloadMainFPGACmd	0x3
#define kGretinaTriggerMainFPGAIsLoaded     0x41


static GretinaTriggerRegisterInformation register_information[kNumberOfGretinaTriggerRegisters] = {
    {0x0800,    @"Input Link Mask",     kReadWrite, kMasterAndRouter},
    {0x0804,    @"LED Register",        kReadWrite, kMasterAndRouter},
    {0x0808,    @"Skew Ctl A",          kReadWrite, kMasterAndRouter},
    {0x080D,    @"Skew Ctl B",          kReadWrite, kMasterAndRouter},
    {0x0810,    @"Skew Ctl C",          kReadWrite, kMasterAndRouter},
    {0x0814,    @"Misc Clk Crl",        kReadWrite, kMasterAndRouter},
    {0x0818,    @"Aux IO Crl",          kReadWrite, kMasterAndRouter},
    {0x081C,    @"Aux IO Data",         kReadWrite, kMasterAndRouter},
    {0x0820,    @"Aux Input Select",    kReadWrite, kMasterAndRouter},
    {0x0824,    @"Aux Trigger Width",   kReadWrite, kMasterOnly},
    
    {0x0828,    @"Serdes TPower",       kReadWrite, kMasterAndRouter},
    {0x082C,    @"Serdes RPower",       kReadWrite, kMasterAndRouter},
    {0x0830,    @"Serdes Local Le",     kReadWrite, kMasterAndRouter},
    {0x0834,    @"Serdes Line Le",      kReadWrite, kMasterAndRouter},
    {0x0838,    @"Lvds PreEmphasis",    kReadWrite, kMasterAndRouter},
    {0x083C,    @"Link Lru Crl",        kReadWrite, kMasterAndRouter},
    {0x0840,    @"Misc Ctl1",           kReadWrite, kMasterAndRouter},
    {0x0844,    @"Misc Ctl2",           kReadWrite, kMasterAndRouter},
    {0x0848,    @"Generic Test Fifo",   kReadWrite, kMasterAndRouter},
    {0x084C,    @"Diag Pin Crl",        kReadWrite, kMasterAndRouter},
    
    {0x0850,    @"Trig Mask",           kReadWrite, kMasterOnly},
    {0x0854,    @"Trig Dist Mask",      kReadWrite, kMasterOnly},
    {0x0860,    @"Serdes Mult Thresh",  kReadWrite, kMasterOnly},
    {0x0864,    @"Tw Ethresh Crl",      kReadWrite, kMasterOnly},
    {0x0868,    @"Tw Ethresh Low",      kReadWrite, kMasterOnly},
    {0x086C,    @"Tw Ethresh Hi",       kReadWrite, kMasterOnly},
    {0x0870,    @"Raw Ethresh low",     kReadWrite, kMasterOnly},
    {0x0874,    @"Raw Ethresh Hi",      kReadWrite, kMasterOnly},
    //------
    //Next blocks are define differently in Master and Router
    {0x0878,    @"Isomer Thresh1",      kReadWrite, kMasterOnly},
    {0x087C,    @"Isomer Thresh2",      kReadWrite, kMasterOnly},
    
    {0x0880,    @"Isomer Time Window",  kReadWrite, kMasterOnly},
    {0x0884,    @"Fifo Raw Esum Thresh",kReadWrite, kMasterOnly},
    {0x0888,    @"Fifo Tw Esum Thresh", kReadWrite, kMasterOnly},
    //-------
    {0x0878,    @"CC Pattern1",         kReadWrite, kRouterOnly},
    {0x087C,    @"CC Pattern2",         kReadWrite, kRouterOnly},
    {0x0880,    @"CC Pattern3",         kReadWrite, kRouterOnly},
    {0x0884,    @"CC Pattern4",         kReadWrite, kRouterOnly},
    {0x0888,    @"CC Pattern5",         kReadWrite, kRouterOnly},
    {0x088C,    @"CC Pattern6",         kReadWrite, kRouterOnly},
    {0x0890,    @"CC Pattern7",         kReadWrite, kRouterOnly},
    
    {0x0894,    @"CC Pattern8",         kReadWrite, kRouterOnly},
    //End of Split
    //----------
    {0x08A0,    @"Mon1 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08A4,    @"Mon2 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08A8,    @"Mon3 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08AC,    @"Mon4 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08B0,    @"Mon5 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08B4,    @"Mon6 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08B8,    @"Mon7 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08BC,    @"Mon8 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08C0,    @"Chan Fifo Crl",       kReadWrite, kMasterAndRouter},
    
    {0x08C4,    @"Dig Misc Bits",       kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08C8,    @"Dig DiscBit Src",     kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08CC,    @"Den Bits",            kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08D0,    @"Ren Bits",            kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08D4,    @"Sync Bits",           kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08E0,    @"Pulsed Ctl1",         kReadWrite, kMasterAndRouter},
    {0x08E4,    @"Pulsed Ctl2",         kReadWrite, kMasterAndRouter},
    {0x08F0,    @"Fifo Resets",         kReadWrite, kMasterAndRouter},
    {0x08F4,    @"Async Cmd Fifo",      kReadWrite, kMasterAndRouter},
    {0x08F8,    @"Aux Cmd Fifo",        kReadWrite, kMasterAndRouter},
    
    {0x08FC,    @"Debug Cmd Fifo",      kReadWrite, kMasterAndRouter},
    {0xA000,    @"Mask",                kReadWrite, kMasterAndRouter},
    {0xE000,    @"Fast Strb Thresh",    kReadWrite, kMasterAndRouter},
    {0x0100,    @"Link Locked",         kReadOnly, kMasterAndRouter},
    {0x0104,    @"Link Den",            kReadOnly, kMasterAndRouter},
    {0x0108,    @"Link Ren",            kReadOnly, kMasterAndRouter},
    {0x010C,    @"Link Sync",           kReadOnly, kMasterAndRouter},
    {0x0110,    @"Chan Fifo Stat",      kReadOnly, kMasterAndRouter},
    {0x0114,    @"TimeStamp A",         kReadOnly, kMasterAndRouter},
    {0x0118,    @"TimeStamp B",         kReadOnly, kMasterAndRouter},
    
    {0x011C,    @"TimeStamp C",         kReadOnly, kMasterAndRouter},
    {0x0120,    @"MSM State",           kReadOnly, kMasterOnly},
    //------
    //Next blocks are define differently in Master and Router
    {0x0124,    @"Chan Pipe Status",    kReadOnly, kMasterOnly},
    //-------
    {0x0124,    @"Rc State",            kReadOnly, kRouterOnly},
    //End of Split
    //----------
    {0x0128,    @"Misc State",          kReadOnly, kMasterAndRouter},
    {0x012C,    @"Diagnostic A",        kReadOnly, kMasterAndRouter},
    {0x0130,    @"Diagnostic B",        kReadOnly, kMasterAndRouter},
    {0x0134,    @"Diagnostic C",        kReadOnly, kMasterAndRouter},
    {0x0138,    @"Diagnostic D",        kReadOnly, kMasterAndRouter},
    {0x013C,    @"Diagnostic E",        kReadOnly, kMasterAndRouter},
    
    {0x0140,    @"Diagnostic F",        kReadOnly, kMasterAndRouter},
    {0x0144,    @"Diagnostic G",        kReadOnly, kMasterAndRouter},
    {0x0148,    @"Diagnostic H",        kReadOnly, kMasterAndRouter},
    {0x014C,    @"Diag Stat",           kReadOnly, kMasterAndRouter},
    {0x0154,    @"Run Raw Esum",        kReadOnly, kMasterOnly},
    {0x0158,    @"Code Mode Date",      kReadOnly, kMasterAndRouter},
    {0x015C,    @"Code Revision",       kReadOnly, kMasterAndRouter},
    {0x0160,    @"Mon1 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0164,    @"Mon2 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0168,    @"Mon3 Fifo",           kReadOnly, kMasterAndRouter},
    
    {0x016C,    @"Mon4 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0170,    @"Mon5 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0174,    @"Mon6 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0178,    @"Mon7 Fifo",           kReadOnly, kMasterAndRouter},
    {0x017C,    @"Mon8 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0180,    @"Chan1 Fifo",          kReadOnly, kMasterAndRouter},
    {0x0184,    @"Chan2 Fifo",          kReadOnly, kMasterAndRouter},
    {0x0188,    @"Chan3 Fifo",          kReadOnly, kMasterAndRouter},
    {0x018C,    @"Chan4 Fifo",          kReadOnly, kMasterAndRouter},
    {0x0190,    @"Chan5 Fifo",          kReadOnly, kMasterAndRouter},
    
    {0x0194,    @"Chan6 Fifo",          kReadOnly, kMasterAndRouter},
    {0x0198,    @"Chan7 Fifo",          kReadOnly, kMasterAndRouter},
    {0x019C,    @"Chan8 Fifo",          kReadOnly, kMasterAndRouter},
    {0x01A0,    @"Mon Fifo State",      kReadOnly, kMasterAndRouter},
    {0x01A4,    @"Chan Fifo State",     kReadOnly, kMasterAndRouter},
    {0xA004,    @"Total Multiplicity",  kReadOnly, kMasterOnly},
    {0xA010,    @"RouterA Multiplicity",kReadOnly, kMasterOnly},
    {0xA014,    @"RouterB Multiplicity",kReadOnly, kMasterOnly},
    {0xA018,    @"RouterC Multiplicity",kReadOnly, kMasterOnly},
    {0xA01C,    @"RouterD Multiplicity",kReadOnly, kMasterOnly},
};

static GretinaTriggerRegisterInformation fpga_register_information[kTriggerNumberOfFPGARegisters] = {
    {0x900,	@"Main Digitizer FPGA configuration register"   ,kReadWrite, kMasterAndRouter},
    {0x904,	@"Main Digitizer FPGA status register"          ,kReadOnly, kMasterAndRouter},
    {0x908,	@"Voltage and Temperature Status"               ,kReadOnly, kMasterAndRouter},
    {0x910,	@"General Purpose VME Control Settings"         ,kReadWrite, kMasterAndRouter},
    {0x914,	@"VME Timeout Value Register"                   ,kReadWrite, kMasterAndRouter},
    {0x920,	@"VME Version/Status"                           ,kReadOnly, kMasterAndRouter},
    {0x930,	@"VME FPGA Sandbox Register 1"                  ,kReadWrite, kMasterAndRouter},
    {0x934,	@"VME FPGA Sandbox Register 2"                  ,kReadWrite, kMasterAndRouter},
    {0x938,	@"VME FPGA Sandbox Register 3"                  ,kReadWrite, kMasterAndRouter},
    {0x93C,	@"VME FPGA Sandbox Register 4"                  ,kReadWrite, kMasterAndRouter},
    {0x980,	@"Flash Address"                                ,kReadWrite, kMasterAndRouter},
    {0x984,	@"Flash Data with Auto-increment address"       ,kReadWrite, kMasterAndRouter},
    {0x988,	@"Flash Data"                                   ,kReadWrite, kMasterAndRouter},
    {0x98C,	@"Flash Command Register"                       ,kReadWrite, kMasterAndRouter}
};

#pragma mark ***Initialization
- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    int i;
    for(i=0;i<9;i++){
        [linkConnector[i] release];
    }
    [mainFPGADownLoadState release];
    [fpgaFilePath release];
	[progressLock release];
    [fileQueue cancelAllOperations];
    [fileQueue release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"GretinaTrigger"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORGretinaTriggerController"];
}

//- (NSString*) helpURL
//{
//	return @"VME/Gretina.html";
//}

- (Class) guardianClass
{
	return NSClassFromString(@"ORVme64CrateModel");
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,baseAddress+0xffff);
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

- (void) makeConnectors
{
    //make and cache our connector. However these connectors will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    int i;
    for(i=0;i<9;i++){
        [self setLink:i connector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
        [linkConnector[i] setSameGuardianIsOK:YES];
        [linkConnector[i] setConnectorImageType:kSmallDot];
        if(i<8){
            [linkConnector[i] setConnectorType: 'LNKO' ];
            [linkConnector[i] addRestrictedConnectionType: 'LNKI' ];
        }
        else {
            [linkConnector[i] setConnectorType: 'LNKI' ];
            [linkConnector[i] addRestrictedConnectionType: 'LNKO' ];
        }
        [linkConnector[i] setOffColor:[NSColor colorWithCalibratedRed:1 green:1 blue:.3 alpha:1.]];
        if(i<8)[linkConnector[i] setIdentifer:'A'+i];
        else   [linkConnector[i] setIdentifer:'L'];
    }
}

- (void) positionConnector:(ORConnector*)aConnector
{
    NSRect aFrame = [aConnector localFrame];
    int i;
    for(i=0;i<9;i++){
        if(aConnector == linkConnector[i]){
            float x =  17 + [self slot] * 16*.62 ;
            float y =  95 - (kConnectorSize-4)*i;
            if(i==8)y -= 10;
            aFrame.origin = NSMakePoint(x,y);
            [aConnector setLocalFrame:aFrame];
            break;
        }
    }
}

- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
	
	[super setGuardian:aGuardian];
	
    int i;
    if(oldGuardian != aGuardian){
        for(i=0;i<9;i++){
            [oldGuardian removeDisplayOf:linkConnector[i]];
        }
    }
	
    for(i=0;i<9;i++){
        [aGuardian assumeDisplayOf:linkConnector[i]];
    }
    [self guardian:aGuardian positionConnectorsForCard:self];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    int i;
    for(i=0;i<9;i++){
        [aGuardian positionConnector:linkConnector[i] forCard:self];
    }
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    int i;
    for(i=0;i<9;i++){
        [aGuardian removeDisplayOf:linkConnector[i]];
    }
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    int i;
    for(i=0;i<9;i++){
        [aGuardian assumeDisplayOf:linkConnector[i]];
    }
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter removeObserver:self];
    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
    
}

- (void) runAboutToStart:(NSNotification*)aNote
{
    //[self initClockDistribution];
}

#pragma mark ***Accessors

- (unsigned short) diagnosticCounter
{
    return diagnosticCounter;
}

- (void) setDiagnosticCounter:(unsigned short)aDiagnosticCounter
{
    diagnosticCounter = aDiagnosticCounter;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerModelDiagnosticCounterChanged object:self];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerFirmwareStatusStringChanged object:self];
}
- (BOOL) downLoadMainFPGAInProgress
{
	return downLoadMainFPGAInProgress;
}

- (void) setDownLoadMainFPGAInProgress:(BOOL)aState
{
	downLoadMainFPGAInProgress = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerMainFPGADownLoadInProgressChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerMainFPGADownLoadStateChanged object:self];
}

- (NSString*) fpgaFilePath
{
    if(fpgaFilePath) return fpgaFilePath;
    else return @"";
}

- (void) setFpgaFilePath:(NSString*)aFpgaFilePath
{
	if(!aFpgaFilePath)aFpgaFilePath = @"";
    [fpgaFilePath autorelease];
    fpgaFilePath = [aFpgaFilePath copy];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerFpgaFilePathChanged object:self];
}

- (unsigned short) inputLinkMask         { return inputLinkMask & 0xffff; }
- (unsigned short) serdesTPowerMask      { return serdesTPowerMask & 0xffff; }
- (unsigned short) serdesRPowerMask      { return serdesRPowerMask & 0xffff; }
- (unsigned short) lvdsPreemphasisCtlMask { return lvdsPreemphasisCtlMask; }
- (unsigned short) miscCtl1Reg           { return miscCtl1Reg; }
- (unsigned short) miscStatReg           { return miscStatReg; }
- (unsigned short) linkLruCrlReg         { return linkLruCrlReg; }
- (unsigned short) linkLockedReg         { return linkLockedReg; }
- (BOOL)          clockUsingLLink        { return clockUsingLLink; }


- (void) setClockUsingLLink:(BOOL)aValue
{
    clockUsingLLink = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerClockUsingLLinkChanged object:self];
    
}

- (void) setLinkLockedReg:(unsigned short)aValue
{
    linkLockedReg = aValue & 0x7ff;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerLinkLockedRegChanged object:self];
    
}

- (void) setInputLinkMask:(unsigned short)aMask
{
    inputLinkMask = aMask & 0xffff;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerModelInputLinkMaskChanged object:self];
}


- (void) setSerdesTPowerMask:(unsigned short)aMask
{
    serdesTPowerMask = aMask & 0xffff;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerSerdesTPowerMaskChanged object:self];
}


- (void) setSerdesRPowerMask:(unsigned short)aMask
{
    serdesRPowerMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerSerdesRPowerMaskChanged object:self];
}

- (void) setLvdsPreemphasisCtlMask:(unsigned short)aMask
{
    lvdsPreemphasisCtlMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerLvdsPreemphasisCtlMask object:self];
    
}
- (void) setMiscCtl1Reg:(unsigned short)aValue
{
    miscCtl1Reg = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerMiscCtl1RegChanged object:self];
}
- (void) setMiscStatReg:(unsigned short)aValue
{
    miscStatReg = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerMiscStatRegChanged object:self];
    
}
- (void) setLinkLruCrlReg:(unsigned short)aValue
{
    linkLruCrlReg = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerLinkLruCrlRegChanged object:self];
}


- (ORConnector*) linkConnector:(int)index
{
    if(index>=0 && index<9)return linkConnector[index];
    else return nil;
}

- (void) setLink:(int)index connector:(ORConnector*)aConnector
{
    if(index>=0 && index<9){
        [aConnector retain];
        [linkConnector[index] release];
        linkConnector[index] = aConnector;
    }
}

- (BOOL) isMaster
{
    return isMaster;
}

- (void) setIsMaster:(BOOL)aIsMaster
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsMaster:isMaster];
    
    isMaster = aIsMaster;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerModelIsMasterChanged object:self];
}
- (int) registerIndex
{
    return registerIndex;
}

- (void) setRegisterIndex:(int)aRegisterIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterIndex:registerIndex];
    registerIndex = aRegisterIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerRegisterIndexChanged object:self];
}

- (unsigned short) regWriteValue
{
    return regWriteValue;
}

- (void) setRegWriteValue:(unsigned short)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegWriteValue:regWriteValue];
    regWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerRegisterWriteValueChanged object:self];
}

- (NSString*) registerNameAt:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return @"";
	return register_information[index].name;
}

- (unsigned long) registerOffsetAt:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return 0;
	return register_information[index].offset;
}

- (unsigned short) readRegister:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return -1;
	if (![self canReadRegister:index]) return -1;
	unsigned short theValue = 0;
    [[self adapter] readWordBlock:&theValue
                        atAddress:[self baseAddress] + register_information[index].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    //NSLog(@"%@ = 0x%04x\n",register_information[index].name,theValue);
    return theValue;
}

- (void) writeRegister:(unsigned int)index withValue:(unsigned short)value
{
	if (index >= kNumberOfGretinaTriggerRegisters) return;
	if (![self canWriteRegister:index]) return;
    NSLog(@"%@ write 0x%04x to 0x%04x (%@)\n",[self isMaster]?@"Master":@"Router",value,register_information[index].offset,register_information[index].name);
    
    [[self adapter] writeWordBlock:&value
                         atAddress:[self baseAddress] + register_information[index].offset
                        numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) setLink:(char)linkName state:(BOOL)aState
{
    if(linkName>='A' && linkName<='U'){
        unsigned short aMask = inputLinkMask;
        int index = (int)(linkName - 'A');
        if(aState)  aMask |= (0x1 << index);
        else        aMask &= ~(0x1 << index);
        [self setInputLinkMask:aMask];
    }
}

- (BOOL) canReadRegister:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return NO;
	return (register_information[index].accessType & kReadOnly) || (register_information[index].accessType & kReadWrite);
}

- (BOOL) canWriteRegister:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return NO;
	return (register_information[index].accessType & kWriteOnly) || (register_information[index].accessType & kReadWrite);
}

#pragma mark •••set up routines

- (short) initState {return initializationState;}
- (void) setInitState:(short)aState
{
    initializationState = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerModelInitStateChanged object:self];
    
}
- (NSString*) initStateName
{
    switch(initializationState){
        case kStepIdle:     return @"Idle";
        case kStepSetup:    return @"Setup";
        case kStep1a:       return @"Set Input Link Mask";
        case kStep1b:       return @"Set SerDes T/R Power";
        case kStep1c:       return @"Pre-Emphassis Control";
        case kStep1d:       return @"Release Link-Init";
        case kCheckStep1d:  return @"Check Misc Status";
        case kRunSteps2a2c: return @"Running Router Setup";
        case kWaitOnSteps2a2c: return @"Waiting on Routers";
        case kStep2a:       return @"Set SerDes T/R Power";
        case kStep2b:       return @"L Link DEN,REN,SYNC";
        case kStep2c:       return @"Enable Driver L Link";
        case kStep3a:       return @"Read Link Lock";
        case kStep3b:       return @"Verify Link State";
        case kStep3c:       return @"Altering Misc Ctl1";
        case kStep3d:       return @"Altering Misc Ctl1";
        case kStep3e:       return @"Altering Misc Ctl1";
        case kRunSteps4a4b: return @"Setting Router Clock Src";
        case kWaitOnSteps4a4b: return @"Waiting on Routers";
        case kStep4a:       return @"Set Clock Source";
        case kStep4b:       return @"Check Router Lock";
        case kStep5a:       return @"Check WAIT_ACK State";
        case kStep5b:       return @"Set and Clear ACK Bit";
        case kStep5c:       return @"Verify ACKED Mode";
        case kStep5d:       return @"Send Normal Data";
        case kRunSteps6To9:  return @"Running non-Master Setup";
        case kWaitOnSteps6To9:return @"Waiting on Routers and Digitizers";
        case kStep6a:       return @"Router Stringent Data Checking";
        case kStep6b:       return @"Verify Router Still Locked";
        case kStep7a:       return @"Mask Unused Router Channels";
        case kStep7b:       return @"Set TPower and RPower Bits";
        case kStep7c:       return @"Pre-Emphasis Control";
        case kStep7d:       return @"Release LINK_INIT Reset";
        case kStep8:        return @"Running Digitizer Setup";
        case kStep9:        return @"Set and Clear ACK Bit";
        case kStep10:       return @"Turn Off IMPERATIVE_SYNC Bit";            
        case kStepError:    return @"Error. See Status Log";
        default:            return @"?";
    }
}

- (void) initClockDistribution
{
    if(!initializationRunning && isMaster){
        
        [self addRunWaitWithReason:@"Wait for Trigger Card Clock Distribution Init"];

        [self setInitState:kStepSetup];
        connectedRouterMask = 0;
        
        [self setRoutersToIdle];
        
        [self performSelector:@selector(stepMaster) withObject:nil afterDelay:kTriggerInitDelay];
    }
}

- (void) setRoutersToIdle
{
    int i;
    for(i=0;i<8;i++){
        ORConnector* otherConnector = [linkConnector[i] connector];
        if([otherConnector identifer] == 'L'){
            ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
            [routerObj setInitState:kStepIdle];
        }
    }
}

//  In progress
- (BOOL) systemAllLocked
{
    return YES; //temp
    /*
    int i;
    //int j;
    
    if ( (miscStatReg & 0x4000) != kAllLockBit  )
        return NO;
    else {
        for(i=0;i<8;i++){
            ORConnector* routerConnector = [linkConnector[i] connector];
            if([routerConnector identifer] == 'L'){
                if ( [routerConnector miscStatReg] & 0x4000 != kAllLockBit)
                    return NO;
                else {
                    for(i=0;i<8;i++){
                     //   if([[routerConnector linkConnector[j]] connector] != 'L'){
                      //      ORConnector* triggerConnector = [linkConnector[i] connector];
                       //     ORGretina4MModel* digitizerObj = [triggerConnector objectLink];
                     //   }
                    }
                }
            }
        }
    }
     */
}

- (void) readDisplayRegs
{
    [self setLinkLockedReg:     [self readRegister:kLinkLocked]];
    [self setMiscStatReg:       [self readRegister:kMiscStatus]];
    [self setMiscCtl1Reg:       [self readRegister:kMiscCtl1]];
    [self setDiagnosticCounter: [self readRegister:kDiagnosticF]];
    [self setLinkLruCrlReg:     [self readRegister:kLinkLruCrl]];
    [self setInputLinkMask:     [self readRegister:kInputLinkMask]];
    [self setSerdesTPowerMask:  [self readRegister:kSerdesTPower]];
    [self setSerdesRPowerMask:  [self readRegister:kSerdesRPower]];
    [self setLvdsPreemphasisCtlMask:[self readRegister:kLvdsPreEmphasis]];
    
    
}
- (void) stepMaster
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stepMaster) object:nil];
    
    unsigned short masterPreMask = 0;
    NSLog(@"\n");
    NSLog(@"%@ Running Step: %@\n",[self isMaster]?@"Master":@"Router",[self initStateName]);
    if(initializationState != kRunSteps2a2c && initializationState!= kWaitOnSteps2a2c){
        //NSLog(@"Before Step\n");
        [self readDisplayRegs]; //read a few registers that we will use repeatedly and display
    }
    switch(initializationState){
            
        case kStepSetup:
            connectedRouterMask = [self findRouterMask];
            if(connectedRouterMask==0){
                NSLog(@"HW Error. Tried to initialize %@ for clock distribution but it is not connected to any routers\n",[self fullID]);
                [self setInitState:kStepError];
            }
            else {
                [self setInitState:kStep1a];
            }
            break;
            
        case kStep1a: //1a. Mask out all unused channels
            [self writeRegister:kInputLinkMask withValue:~connectedRouterMask]; //A set bit disables a channel
            //[self writeRegister:kInputLinkMask withValue:0xFE];
            [self setInputLinkMask:  [self readRegister:kInputLinkMask]];       //read it back for display
            [self setInitState:kStep1b];
            break;
            
        case kStep1b: //1b. Set the matching bit in the serdes tpower and rpower registers
            [self writeRegister:kSerdesTPower withValue:connectedRouterMask];
            [self writeRegister:kSerdesRPower withValue:connectedRouterMask];
            //[self writeRegister:kSerdesTPower withValue:0x1];
            //[self writeRegister:kSerdesRPower withValue:0x1];
            [self setSerdesTPowerMask:[self readRegister:kSerdesTPower]]; //read it back for display
            [self setSerdesRPowerMask:[self readRegister:kSerdesRPower]]; //read it back for display
            [self setInitState:kStep1c];
            break;
            
        case kStep1c: //1c. Turn on the driver enable bits for the used channels
            if(connectedRouterMask & 0xf)    masterPreMask |= 0x151; //Links A,B,C,D
            if(connectedRouterMask & 0x70)   masterPreMask |= 0x152; //Links E,F,G
            if(connectedRouterMask & 0x780)  masterPreMask |= 0x154; //Links H,L,R,U
            [self writeRegister:kLvdsPreEmphasis withValue:masterPreMask];
            [self setLvdsPreemphasisCtlMask:[self readRegister:kLvdsPreEmphasis]]; //read it back for display
            [self setInitState:kStep1d];
            break;
            
        case kStep1d: //1d. Release the link-init machine by clearing the reset bit in the misc-ctl register
            [self writeRegister:kMiscCtl1 withValue:[self readRegister:kMiscCtl1] & ~kResetLinkInitMachBit];
            //[self writeRegister:kMiscCtl1 withValue:0xFFC0];
            [self setMiscCtl1Reg:[self readRegister:kMiscCtl1]]; //read it back for display
            [self setInitState:kCheckStep1d];
            break;
            
        case kCheckStep1d: //verify that we are waiting to lock onto the data stream of the router
            if(((miscStatReg & kLinkInitStateMask)>>8) != 0x3){
                NSLog(@"HW issue: Master Trigger %@ not waiting for data stream from Router.\n",[self fullID]);
                [self setInitState:kStepError];
            }
            else {
                NSLog(@"Master Trigger Misc Status (0x%04x) indicates it is waiting to lock on Router data stream.\n",miscStatReg);
                [self setInitState:kRunSteps2a2c];
            }
            break;
            
        case kRunSteps2a2c:
        {
            int i;
            for(i=0;i<8;i++){
                ORConnector* otherConnector = [linkConnector[i] connector];
                if([otherConnector identifer] == 'L'){
                    ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
                    [routerObj setInitState:kStep2a];
                    [routerObj stepRouter];
                }
            }
        }
            [self setInitState:kWaitOnSteps2a2c];
            break;
            
        case kWaitOnSteps2a2c:
            if([self allRoutersIdle]){
                [self setInitState:kStep3a];
            }
            break;
            
        // Also rarely gets stuck here. Trigger cards stop responding. Current solution is power off / on.
        case kStep3a://3a. Read Link Locked to verify the SERDES of Master is locked the syn pattern of the Router
            if(linkLockedReg!= (~connectedRouterMask & 0x7FF)) {
                NSLog(@"HW issue: the SERDES of the Master has not locked on to the synchronization pattern from the Router");
                [self setInitState:kStepError];
            }
            else {
                NSLog(@"The Link Locked Register of the Master indicates it has locked onto the synchronization pattern of the router");
                [self setInitState:kStep3b];
            }
            
            break;
            
        case kStep3b: //3b. Verify that the state of the link
            if (((miscStatReg & kLinkInitStateMask)>>8) != 0x4) {
                NSLog(@"HW issue: Master Trigger %@ has not locked on to the synchronization pattern from the Router.\n",[self fullID]);
                [self setInitState:kStepError];
            }
            else if(((miscStatReg & kAllLockBit)>>14) != 0x1) {
                NSLog(@"HW issue: Master Trigger %@ does not have all links locked.\n",[self fullID]);
                [self setInitState:kStepError];
            }
            else {
                NSLog(@"Master Trigger %@ indicates it has locked on to the Router data stream.\n",[self fullID]);
                [self setInitState:kRunSteps4a4b];
            }
            break;
       
        case kRunSteps4a4b:
        {
            int i;
            for(i=0;i<8;i++){
                ORConnector* otherConnector = [linkConnector[i] connector];
                if([otherConnector identifer] == 'L'){
                    ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
                    [routerObj setInitState:kStep4a];
                    [routerObj stepRouter];
                }
            }
        }
            [self setInitState:kWaitOnSteps4a4b];
            break;

        case kWaitOnSteps4a4b:
            if([self allRoutersIdle]){
                [self setInitState:kStep5a];
            }
            break;
            
        case kStep5a:  // This is where it sometimes fails
            if(((miscStatReg & kWaitAcknowledgeStateMask)
                >> 8) != 0x4) {
                NSLog(@"HW Error: Master Trigger MISC_STAT register %@ indicates that it is not in WAIT_ACK mode.\n", [self fullID]);
                [self setInitState:kStepError];
            }
            else {
                NSLog(@"Master Trigger MISC_STAT_REG %@ indicates that is is in WAIT_ACK mode.\n", [self fullID]);
                [self setInitState:kStep5b];
            }
            break;
        
        case kStep5b:
            [self writeRegister:kMiscCtl1 withValue:0xFFC2];
            [self writeRegister:kMiscCtl1 withValue:0xFFC0];
            [self setMiscCtl1Reg:[self readRegister:kMiscCtl1]];
            [self setInitState:kStep5c];
            break;
            
        case kStep5c:
            if (((miscStatReg & kAcknowledgedStateMask) >> 8 != 0x5)) {
                NSLog(@"HW Error: Master Trigger MISC_STAT register %@ indicates that it is not in ACKED mode.\n", [self fullID]);
                [self setInitState:kStepError];
            }
            else {
                NSLog(@"Master Trigger MISC_STAT register %@ indicates that it is in ACKED mode.\n", [self fullID]);
                [self setInitState:kStep5d];
            }
            break;
            
        case kStep5d:
            [self writeRegister:kMiscCtl1 withValue:0xFF40];
            [self setMiscCtl1Reg:[self readRegister:kMiscCtl1]];
            [self setInitState:kRunSteps6To9];
            break;
            
        case kRunSteps6To9:
        {
            int i;
            for(i=0;i<8;i++){
                ORConnector* otherConnector = [linkConnector[i] connector];
                if([otherConnector identifer] == 'L'){
                    ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
                    [routerObj setInitState:kStep6a];
                    [routerObj stepRouter];
                }
            }
        }
            [self setInitState:kWaitOnSteps6To9];
            break;
            
        case kWaitOnSteps6To9:
            if([self allRoutersIdle]){
                [self setInitState:kStep10];
            }
            break;
            
        case kStep10:
            [self writeRegister:kMiscCtl1 withValue:0xFF00];
            [self setMiscCtl1Reg:[self readRegister:kMiscCtl1]];
            [self setInitState:kStepIdle];
    }
    
    if(initializationState != kRunSteps2a2c     &&
       initializationState!= kWaitOnSteps2a2c   &&
       initializationState != kWaitOnSteps4a4b  &&
       initializationState != kWaitOnSteps6To9) {
        // NSLog(@"After Step\n");
        [self readDisplayRegs]; //read a few registers that we will use repeatedly and display
    }
    
    if(initializationState != kStepError &&
       initializationState != kStepIdle) {
        [self performSelector:@selector(stepMaster) withObject:nil afterDelay:kTriggerInitDelay];
    }

    if(initializationState == kStepError){
        //there was an error, we must make sure the run doesn't continue to start
        NSString* reason = @"Trigger Card Failed to achieve lock";
        [[NSNotificationCenter defaultCenter] postNotificationName:ORRequestRunHalt
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:reason,@"Reason",nil]];
        [self releaseRunWait];

    }
    else if(initializationState == kStepIdle){
        //OK, the lock was achieved. The run can continue to start
        [self releaseRunWait];
    }
}


- (BOOL) allRoutersIdle
{
    int i;
    for(i=0;i<8;i++){
        ORConnector* otherConnector = [linkConnector[i] connector];
        if([otherConnector identifer] == 'L'){
            ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
            if([routerObj initState] != kStepIdle)return NO;
        }
    }
    return YES;
}

- (void) stepRouter
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stepRouter) object:nil];
    
    NSLog(@"\n");
    NSLog(@"%@ Running Step: %@\n",[self isMaster]?@"Master":@"Router",[self initStateName]);
    //    NSLog(@"Before Step\n");
    //read a few registers that we will use repeatedly and display
    [self readDisplayRegs]; //read a few registers that we will use repeatedly and display
    
    switch(initializationState){
        case kStep2a://2a. Enable the "L" link
            //--------------
            //[self writeRegister:kInputLinkMask withValue:([self readRegister:kInputLinkMask] & ~0x100)]; //A set bit disables a channel !!!
            //[self setInputLinkMask:  [self readRegister:kInputLinkMask]];   //read it back for display
            //--------------
            
            [self writeRegister:kSerdesTPower withValue:kPowerOnLSerDes];
            [self writeRegister:kSerdesRPower withValue:kPowerOnLSerDes];
            //[self writeRegister:kSerdesTPower withValue:0x100];
            //[self writeRegister:kSerdesRPower withValue:0x100];
            
            [self setSerdesTPowerMask:[self readRegister:kSerdesTPower]]; //read back for display
            [self setSerdesRPowerMask:[self readRegister:kSerdesRPower]]; //read back for display
            
            [self setInitState:kStep2b];
            break;
            
        case kStep2b: //2b. Turn on the DEN, REN, and SYNC for Link "L"
            //[self writeRegister:kLinkLruCrl withValue: ( [self readRegister:kLinkLruCrl] | kLinkLruCrlMask)];
            [self writeRegister:kLinkLruCrl withValue:0x88F];
            [self setLinkLruCrlReg:[self readRegister:kLinkLruCrl]]; //read back for display
            [self setInitState:kStep2c];
            break;
            
        case kStep2c: //2c. Enable the Link "L" driver
            //[self writeRegister:kLvdsPreEmphasis withValue:([self readRegister:kLvdsPreEmphasis] | kLvdsPreEmphasisPowerOnL)]; // !!!
            [self writeRegister:kLvdsPreEmphasis withValue:0x157];
            [self setLvdsPreemphasisCtlMask:[self readRegister:kLvdsPreEmphasis]]; //read back for display
            [self setInitState:kStepIdle];
            break;
            
        case kStep4a:
            //[self writeRegister:kMiscClkCrl withValue:[self readRegister:kMiscClkCrl] | kClockSourceSelectBit];
            [self writeRegister:kMiscClkCrl withValue:0x8007];
            [self setClockUsingLLink:([self readRegister:kMiscClkCrl] & kClockSourceSelectBit)!=0]; //read back for display
            [self setInitState:kStepIdle];
            break;
            
            /*        case kStepStartCheckingCounter:
             lastCounter = [self readRegister:kDiagnosticF];
             [self setInitState:kStepCheckCounter];
             break;
             
             case kStepCheckCounter: // !!! May have to change. See email from Mark
             totalTimeCheckingCounter += kTriggerInitDelay;
             currentCounter = [self readRegister:kDiagnosticF];
             if ([self readRegister:kDiagnosticF] == 0x0) {
             NSLog(@"HW Issue: Diagnostic Register F never began counting, indicating that the Router never attempted to lock onto the Master.");
             }
             else if(currentCounter == lastCounter) {
             NSLog(@"Router's diagnostic counter has stopped counting, indicating the Router has locked to the Master.");
             [self setInitState:stepAfterCounterCheck];
             }
             else if(totalTimeCheckingCounter > kMaxTimeAllowed) {
             NSLog(@"HW Issue: Router has not stopped counting. The Router has not locked onto the Master");
             [self setInitState:kStepError];
             }
             else {
             
             }
             break;
             */
/*        case kStep4b: // Completed in kStepStartCheckingCounter and kStepCheckCounter. Kept to match exact steps outlined in instructions
            stepAfterCounterCheck = kStep4b;
            [self setInitState:kStepStartCheckingCounter];
            [self setInitState:kStepIdle];
            break;
*/
        case kStep6a:
            //[self writeRegister:kMiscClt1 withValue:[self readRegister:kMiscCtl1] | kStringentLockBit];
            [self writeRegister:kMiscCtl1 withValue:0x14];
            [self setMiscCtl1Reg:[self readRegister:kMiscCtl1]]; //read back for display
            [self setInitState:kStep7a];
            break;
            
/*        case kStep6b:
            stepAfterCounterCheck = kStep6b;
            [self setInitState:kStepStartCheckingCounter];
            [self setInitState:kStep7a];
*/            
       case kStep7a:
            connectedDigitizerMask = [self findDigitizerMask];
            if(connectedDigitizerMask == 0) {
                NSLog(@"The Router is not connected to any digitizers.");
                [self setInitState:kStepError];
            }
            else {
                [self writeRegister:kInputLinkMask withValue:(~connectedDigitizerMask)];
                //[self writeRegister:kInputLinkMask withValue:0xFC];
                [self setInputLinkMask:[self readRegister:kInputLinkMask]]; // read back for display
                [self setInitState:kStep7b];
            }
            break;
            
        case kStep7b:
            [self writeRegister:kSerdesTPower withValue:connectedDigitizerMask];
            [self writeRegister:kSerdesRPower withValue:connectedDigitizerMask];
            //[self writeRegister:kSerdesTPower withValue:0x103];
            //[self writeRegister:kSerdesRPower withValue:0x103];
            [self setSerdesRPowerMask:[self readRegister:kSerdesRPower]]; // read back for display
            [self setSerdesTPowerMask:[self readRegister:kSerdesTPower]]; // read back for display
            [self setInitState:kStep7d];
            break;
            
            //not used because all preemps are turned on
/*        case kStep7c:
            if(connectedDigitizerMask & 0xf) routerPreMask |= 0x151; //Links A,B,C,D
            if(connectedRouterMask & 0x70)   routerPreMask |= 0x152; //Links E,F,G
            if(connectedRouterMask & 0x780)  routerPreMask |= 0x154; //Links H,L,R,U
            [self writeRegister:kLvdsPreEmphasis withValue:routerPreMask];
            [self setLvdsPreemphasisCtlMask:[self readRegister:kLvdsPreEmphasis]]; //read it back for display
            [self setInitState:kStep7d];
            break;
*/           
        case kStep7d:
          //  [self writeRegister:kMiscCtl1 withValue:([self readRegister:kMiscCtl1] & ~kResetLinkInitMachBit)];
            [self writeRegister:kMiscCtl1 withValue:0x10];
            [self setMiscCtl1Reg:[self readRegister:kMiscCtl1]]; // read back for display
            [self setInitState:kStep8];
            break;
            
/*        case kStep7e:
            // Finish ???
            [self setInitState:kStep7f];
            break;
            
        case kStep7f:
            if (([self readRegister:kMiscCtl1] & linkInitAckBit)>>1 != 0x1) {
                NSLog(@"HW Issue: All router links are not reporting that they are locked.");
                [self setInitState:kStepError];
            }
            else {
                // ???
                
            }
            break;
 */
        case kStep8:
        {
            int i;
            for(i=0;i<8;i++){
                if([linkConnector[i]  identifer] != 'L'){
                    ORConnector* otherConnector = [linkConnector[i] connector];
                    ORGretina4MModel* digitizerObj = [otherConnector objectLink];
                    NSLog(@"%@\n",[digitizerObj className]);
                    [digitizerObj writeFPGARegister:kVMEGPControl withValue:0x2];
                    [digitizerObj writeRegister:kSDConfig withValue:0x10];
                    [digitizerObj writeRegister:kSDConfig withValue:0x0];
                    [digitizerObj writeRegister:kMasterLogicStatus withValue:0x20051];
                    [digitizerObj writeRegister:kSDConfig withValue:0x20];
                    NSLog(@"Good!!!");
                }
            }
        }
            [self setInitState:kStep9];
            break;
            
            
        case kStep9:
            [self writeRegister:kMiscCtl1 withValue:0x12];
            [self setMiscCtl1Reg:[self readRegister:kMiscCtl1]];
            [self writeRegister:kMiscCtl1 withValue:0x10];
            [self setMiscCtl1Reg:[self readRegister:kMiscCtl1]];
            [self setInitState:kStepIdle];
         
    }
    //NSLog(@"After Step\n");
    [self readDisplayRegs]; //read a few registers that we will use repeatedly and display
    
    if(initializationState != kStepIdle){
        [self performSelector:@selector(stepRouter) withObject:nil afterDelay:kTriggerInitDelay];
    }
}

- (unsigned short)findRouterMask
{
    unsigned short aMask = 0x0;
    int i;
    for(i=0;i<8;i++){
        ORConnector* otherConnector = [linkConnector[i] connector];
        if([otherConnector identifer] == 'L')aMask |= (0x1<<i);
    }
    return aMask;
}

- (unsigned short)findDigitizerMask
{
    unsigned short aMask = 0x0;
    int i;
    for(i=0;i<9;i++){
        ORConnector* otherConnector = [linkConnector[i] connector];
        if([otherConnector objectLink] != nil) aMask |= (0x1<<i);
    }
    return aMask;
}

#pragma mark •••Hardware Access
- (void) dumpFpgaRegisters
{
    NSLog(@"--------------------------------------\n");
    NSLog(@"Gretina Trigger Card FPGA registers (%@)\n",[self isMaster]?@"Master":@"Router");
    int i;
    for(i=0;i<kNumberOfFPGARegisters;i++){
        unsigned short theValue;
        [[self adapter] readWordBlock:&theValue
                            atAddress:[self baseAddress] + fpga_register_information[i].offset
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        NSLog(@"0x%08x: 0x%04x %@\n",[self baseAddress] +fpga_register_information[i].offset,theValue,fpga_register_information[i].name);
        
    }
    NSLog(@"--------------------------------------\n");
}

- (void) dumpRegisters
{
    NSLog(@"--------------------------------------\n");
    NSLog(@"Gretina Trigger Card registers (%@)\n",[self isMaster]?@"Master":@"Router");
    int i;
    for(i=0;i<kNumberOfGretinaTriggerRegisters;i++){
        unsigned short theValue;
        [[self adapter] readWordBlock:&theValue
                            atAddress:[self baseAddress] + register_information[i].offset
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        NSLog(@"0x%08x: 0x%04x %@\n",[self baseAddress] +register_information[i].offset,theValue,register_information[i].name);
        
    }
    NSLog(@"--------------------------------------\n");
}


- (void) testSandBoxRegisters
{
    int i;
    for(i=0;i<4;i++){
        [self testSandBoxRegister:kTriggerVMEFPGASandbox1+i];
    }
}

- (void) testSandBoxRegister:(int)anOffset
{
    int errorCount = 0;
    int i;
    unsigned short writeValue = 0 ;
    for(i=0;i<16;i++){

        writeValue = (0x1<<i);
        [[self adapter] writeWordBlock:&writeValue
                            atAddress:[self baseAddress] + fpga_register_information[anOffset].offset
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
        
        unsigned short readValue = 0 ;
        [[self adapter] readWordBlock:&readValue
                            atAddress:[self baseAddress] + fpga_register_information[anOffset].offset
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        
        if((writeValue&0xffff) != readValue){
            NSLog(@"Sandbox Reg 0x%08x error: wrote: 0x%08x read: 0x%08x\n",[self baseAddress] + fpga_register_information[anOffset].offset,writeValue,readValue);
            errorCount++;
        }
    }
    if(!errorCount){
        NSLog(@"Sandbox Reg 0x%08x had no errors\n",[self baseAddress] + fpga_register_information[anOffset].offset);
    }
}


- (unsigned long) baseAddress
{
	return (([self slot]+1)&0x1f)<<20;
}

- (unsigned short) readCodeRevision
{
    unsigned short theValue = 0;
    [[self adapter] readWordBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kCodeRevision].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}

- (unsigned short) readCodeDate
{
    unsigned short theValue = 0;
    [[self adapter] readWordBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kCodeModeDate].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}
- (void) writeToAddress:(unsigned long)anAddress aValue:(unsigned short)aValue
{
    [[self adapter] writeWordBlock:&aValue
                         atAddress:[self baseAddress] + anAddress
                        numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
    
}
- (unsigned short) readFromAddress:(unsigned long)anAddress
{
    unsigned short value = 0;
    [[self adapter] readWordBlock:&value
                        atAddress:[self baseAddress] + anAddress
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return value;
}
- (void) startDownLoadingMainFPGA
{
    {
        if(!progressLock)progressLock = [[NSLock alloc] init];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerFpgaDownProgressChanged object:self];
        
        stopDownLoadingMainFPGA = NO;
        
        //to minimize disruptions to the download thread we'll check and update the progress from the main thread via a timer.
        fpgaDownProgress = 0;
        
        if(![self controllerIsSBC]){
            [self setDownLoadMainFPGAInProgress: YES];
            [self updateDownLoadProgress];
            NSLog(@"GretinaTrigger (%d) beginning firmware load via Mac, File: %@\n",[self uniqueIdNumber],fpgaFilePath);
            [NSThread detachNewThreadSelector:@selector(fpgaDownLoadThread:) toTarget:self withObject:[NSData dataWithContentsOfFile:fpgaFilePath]];
        }
        else {
            if([[[self adapter]sbcLink]isConnected]){
                [self setDownLoadMainFPGAInProgress: YES];
                NSLog(@"GretinaTrigger (%d) beginning firmware load via SBC, File: %@\n",[self uniqueIdNumber],fpgaFilePath);
                [self copyFirmwareFileToSBC:fpgaFilePath];
            }
            else {
                [self setDownLoadMainFPGAInProgress: NO];
                NSLog(@"GretinaTrigger (%d) unable to load firmware. SBC not connected.\n",[self uniqueIdNumber]);
            }
        }
    }
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
        NSLog(@"GretinaTrigger (%d) firmware load job in SBC finished (%@)\n",[self uniqueIdNumber],[jobStatus finalStatus]?@"Success":@"Failed");
        if([jobStatus finalStatus]){
            // [self checkFirmwareVersion:YES];
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

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setInputLinkMask:[decoder decodeIntForKey:@"inputLinkMask"]];
    [self setIsMaster: [decoder decodeBoolForKey:@"isMaster"]];
    int i;
    for(i=0;i<9;i++){
        [self setLink:i connector:[decoder decodeObjectForKey:[NSString stringWithFormat:@"linkConnector%d",i]]];
    }
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:inputLinkMask forKey:@"inputLinkMask"];
    [encoder encodeBool:isMaster	forKey:@"isMaster"];
    int i;
    for(i=0;i<9;i++){
        [encoder encodeObject:linkConnector[i] forKey:[NSString stringWithFormat:@"linkConnector%d",i]];
    }
}
@end

@implementation ORGretinaTriggerModel (private)

- (void) updateDownLoadProgress
{
	//call only from main thread
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerFpgaDownProgressChanged object:self];
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
				[NSException raise:@"GretinaTrigger Exception" format:@"Verification of flash failed."];
			}
            else {
                //reload the fpga from flash
                [self writeToAddress:0x900 aValue:kGretinaTriggerResetMainFPGACmd];
                [self writeToAddress:0x900 aValue:kGretinaTriggerReloadMainFPGACmd];
                [self setProgressStateOnMainThread:  @"Finishing$Flash Memory-->FPGA"];
                uint32_t statusRegValue = [self readFromAddress:0x904];
                while(!(statusRegValue & kGretinaTriggerMainFPGAIsLoaded)) {
                    if(stopDownLoadingMainFPGA)return;
                    statusRegValue = [self readFromAddress:0x904];
                }
                NSLog(@"GretinaTrigger(%d): FPGA Load Finished - No Errors\n",[self uniqueIdNumber]);
                
            }
		}
		[self setProgressStateOnMainThread:@"Loading FPGA"];
		if(!stopDownLoadingMainFPGA) [self reloadMainFPGAFromFlash];
        else NSLog(@"GretinaTrigger(%d): FPGA Load Manually Stopped\n",[self uniqueIdNumber]);
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
	/* We only erase the blocks currently used in the GretinaTrigger specification. */
    [self writeToAddress:0x910 aValue:kGretinaTriggerFlashEnableWrite]; //Enable programming
	[self setFpgaDownProgress:0.];
    unsigned long count = 0;
    unsigned long end = (kGretinaTriggerFlashBlocks / 4) * kGretinaTriggerFlashBlockSize;
    unsigned long addr;
    [self setProgressStateOnMainThread:  @"Block Erase"];
    for (addr = 0; addr < end; addr += kGretinaTriggerFlashBlockSize) {
        
		if(stopDownLoadingMainFPGA)return;
		@try {
            [self setFirmwareStatusString:       [NSString stringWithFormat:@"%lu of %d Blocks Erased",count,kGretinaTriggerFlashBufferBytes]];
 			[self setFpgaDownProgress: 100. * (count+1)/(float)kGretinaTriggerUsedFlashBlocks];
            
            [self writeToAddress:0x980 aValue:addr];
            [self writeToAddress:0x98C aValue:kGretinaTriggerFlashBlockEraseCmd];
            [self writeToAddress:0x98C aValue:kGretinaTriggerFlashConfirmCmd];
            unsigned long stat = [self readFromAddress:0x904];
            while (stat & kFlashBusy) {
                if(stopDownLoadingMainFPGA)break;
                stat = [self readFromAddress:0x904];
            }
            count++;
		}
		@catch(NSException* localException) {
			NSLog(@"GretinaTrigger exception erasing flash.\n");
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
    [self writeToAddress:0x98C aValue:kGretinaTriggerFlashReadArrayCmd];
    
    unsigned long address = 0x0;
    while (address < totalSize ) {
        unsigned long numberBytesToWrite;
        if(totalSize-address >= kGretinaTriggerFlashBufferBytes){
            numberBytesToWrite = kGretinaTriggerFlashBufferBytes; //whole block
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
    [self writeToAddress:0x98C aValue:kGretinaTriggerFlashReadArrayCmd];
    [self writeToAddress:0x910 aValue:0x00];
    
    [self setProgressStateOnMainThread:@"Programming"];
}

- (void) programFlashBufferBlock:(NSData*)theData address:(unsigned long)anAddress numberBytes:(unsigned long)aNumber
{
    //issue the set-up command at the starting address
    [self writeToAddress:0x980 aValue:anAddress];
    [self writeToAddress:0x98C aValue:kGretinaTriggerFlashWriteCmd];
    unsigned char* theDataBytes = (unsigned char*)[theData bytes];
    unsigned long statusRegValue;
	while(1) {
        if(stopDownLoadingMainFPGA)return;
		
		// Checking status to make sure that flash is ready
        unsigned short statusRegValue = [self readFromAddress:0x904];
		
		if ( (statusRegValue & kFlashBusy)  == kFlashBusy ) {
            //not ready, so re-issue the set-up command
            [self writeToAddress:0x980 aValue:anAddress];
            [self writeToAddress:0x98C aValue:kGretinaTriggerFlashWriteCmd];
		}
        else break;
	}
    
	//Set the word count. Max is 0xF.
	unsigned short valueToWrite = (aNumber/2) - 1;
    [self writeToAddress:0x98C aValue:valueToWrite];
	
	// Loading all the words in
    /* Load the words into the bufferToWrite */
	unsigned short i;
	for ( i=0; i<aNumber; i+=4 ) {
        unsigned long* lPtr = (unsigned long*)&theDataBytes[anAddress+i];
        [self writeToAddress:0x984 aValue:lPtr[0]];
	}
	
	// Confirm the write
    [self writeToAddress:0x98C aValue:kGretinaTriggerFlashConfirmCmd];
	
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
    [self writeToAddress:0x98C aValue:kGretinaTriggerFlashReadArrayCmd];
    
    unsigned long errorCount =   0;
    unsigned long address    =   0;
    unsigned long valueToCompare;
    
    while ( address < totalSize ) {
        unsigned short valueToRead = [self readFromAddress:0x984];
        
        /* Now compare to file*/
        if ( address + 3 < totalSize) {
            unsigned long* ptr = (unsigned long*)&theDataBytes[address];
            valueToCompare = ptr[0];
        }
        else {
            //less than four bytes left
            unsigned long numBytes = totalSize - address - 1;
            valueToCompare = 0;
            unsigned short i;
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
    [self writeToAddress:0x090c aValue:0x0002];
    [self writeToAddress:0x090c aValue:0x0000];
    [self writeToAddress:0x090c aValue:0x0001];
    sleep(3);
    NSLog(@"After reset: 0x902 = 0x%04x\n",[self readFromAddress:0x902]);
    [self writeToAddress:0x090c aValue:0x0000];
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
    
    fpgaFileMover = [[[ORFileMoverOp alloc] init] autorelease];
    
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
            NSLog(@"GretinaTrigger (%d) launching firmware load job in SBC\n",[self uniqueIdNumber]);
            
            [[[self adapter] sbcLink] send:&aPacket receive:&aPacket];
            
            [[[self adapter] sbcLink] monitorJobFor:self statusSelector:@selector(flashFpgaStatus:)];
            
        }
        @catch(NSException* e){
            
        }
    }
}

@end