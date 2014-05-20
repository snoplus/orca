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

static GretinaTriggerRegisterInformation fpga_register_information[kNumberOfFPGARegisters] = {
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

    int i;
    for(i=0;i<9;i++){
        [linkConnector[i] release];
    }
    [mainFPGADownLoadState release];
    [fpgaFilePath release];
	[progressLock release];
    [fileQueue cancelAllOperations];
    [fileQueue release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

#pragma mark ***Accessors

- (unsigned long) diagnosticCounter
{
    return diagnosticCounter;
}

- (void) setDiagnosticCounter:(unsigned long)aDiagnosticCounter
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

- (unsigned long) inputLinkMask          { return inputLinkMask & 0xffff; }
- (unsigned long) serdesTPowerMask       { return serdesTPowerMask & 0xffff; }
- (unsigned long) serdesRPowerMask       { return serdesRPowerMask & 0xffff; }
- (unsigned long) lvdsPreemphasisCtlMask { return lvdsPreemphasisCtlMask; }
- (unsigned long) miscCtl1Reg            { return miscCtl1Reg; }
- (unsigned long) miscStatReg            { return miscStatReg; }
- (unsigned long) linkLruCrlReg          { return linkLruCrlReg; }
- (unsigned long) linkLockedReg          { return linkLockedReg; }
- (BOOL)          clockUsingLLink        { return clockUsingLLink; }


- (void) setClockUsingLLink:(BOOL)aValue
{
    clockUsingLLink = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerClockUsingLLinkChanged object:self];
    
}

- (void) setLinkLockedReg:(unsigned long)aValue
{
    linkLockedReg = aValue & 0x7ff;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerLinkLockedRegChanged object:self];
  
}

- (void) setInputLinkMask:(unsigned long)aMask
{
    inputLinkMask = aMask & 0xffff;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerModelInputLinkMaskChanged object:self];
}


- (void) setSerdesTPowerMask:(unsigned long)aMask
{
    serdesTPowerMask = aMask & 0xffff;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerSerdesTPowerMaskChanged object:self];
}


- (void) setSerdesRPowerMask:(unsigned long)aMask
{
    serdesRPowerMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerSerdesRPowerMaskChanged object:self];
}

- (void) setLvdsPreemphasisCtlMask:(unsigned long)aMask
{
    lvdsPreemphasisCtlMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerLvdsPreemphasisCtlMask object:self];
    
}
- (void) setMiscCtl1Reg:(unsigned long)aValue
{
    miscCtl1Reg = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerMiscCtl1RegChanged object:self];
}
- (void) setMiscStatReg:(unsigned long)aValue
{
    miscStatReg = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerMiscStatRegChanged object:self];
    
}
- (void) setLinkLruCrlReg:(unsigned long)aValue
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

- (unsigned long) registerWriteValue
{
    return registerWriteValue;
}

- (void) setRegisterWriteValue:(unsigned long)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterWriteValue:registerWriteValue];
    registerWriteValue = aWriteValue;
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

- (unsigned long) readRegister:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return -1;
	if (![self canReadRegister:index]) return -1;
	unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[index].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    //NSLog(@"%@ = 0x%04x\n",register_information[index].name,theValue);
    return theValue & 0xffff;
}

- (void) writeRegister:(unsigned int)index withValue:(unsigned long)value
{
	if (index >= kNumberOfGretinaTriggerRegisters) return;
	if (![self canWriteRegister:index]) return;
    unsigned long value1 = (value&0xFFFF);
    NSLog(@"%@ write 0x%04x to 0x%04x (%@)\n",[self isMaster]?@"Master":@"Router",value1,register_information[index].offset,register_information[index].name);
    
    [[self adapter] writeLongBlock:&value1
                         atAddress:[self baseAddress] + register_information[index].offset
                         numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];	
}

- (void) setLink:(char)linkName state:(BOOL)aState
{
    if(linkName>='A' && linkName<='U'){
        unsigned long aMask = inputLinkMask;
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
        case kStep4a:       return @"Set Clock Source";
        case kStep4b:       return @"Check Router Lock";
            
        case kRunSteps4a4c: return @"Setting Router Clock Src";
        case kWaitOnSteps4a4c: return @"Waiting on Routers";
            
        case kStepError:    return @"Error. See Status Log";
        default:            return @"?";
    }
}
- (void) initAsOneMasterOneRouter
{
    if(!initializationRunning && isMaster){
        
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
- (void) readDisplayRegs
{
    [self setLinkLockedReg:     [self readRegister:kLinkLocked]];
    [self setMiscStatReg:       [self readRegister:kMiscStatus]];
    [self setMiscCtl1Reg:       [self readRegister:kMiscCtl1]];
    [self setDiagnosticCounter: [self readRegister:kDiagnosticF]];
    
}
- (void) stepMaster
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stepMaster) object:nil];
    
    unsigned long preMask = 0;
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
            [self setInputLinkMask:  [self readRegister:kInputLinkMask]];       //read it back for display
            [self setInitState:kStep1b];
            break;
        
        case kStep1b: //1b. Set the matching bit in the serdes tpower and rpower registers
            [self writeRegister:kSerdesTPower withValue:0xffff];
            [self writeRegister:kSerdesRPower withValue:0xffff];
            [self setSerdesTPowerMask:[self readRegister:kSerdesTPower]]; //read it back for display
            [self setSerdesRPowerMask:[self readRegister:kSerdesRPower]]; //read it back for display
            [self setInitState:kStep1c];
            break;
 
        case kStep1c: //1c. Turn on the driver enable bits for the used channels
            if(connectedRouterMask & 0xf)   preMask |= 0x151; //Links A,B,C,D
            if(connectedRouterMask & 0x70)  preMask |= 0x152; //Links E,F,G
             if(connectedRouterMask & 0x780) preMask |= 0x14; //Links H,L,R,U
            [self writeRegister:kLvdsPreEmphasis withValue:preMask];
            [self setLvdsPreemphasisCtlMask:[self readRegister:kLvdsPreEmphasis]]; //read it back for display
            [self setInitState:kStep1d];
            break;
 
        case kStep1d: //1d. Release the link-init machine by clearing the reset bit in the misc-ctl register
            [self writeRegister:kMiscCtl1 withValue:[self readRegister:kMiscCtl1] & ~kResetLinkInitMachBit];
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
            
        case kStep3a://3a. Read Link Locked to verify the SERDES of Master is locked the syn pattern of the Router
            [self setInitState:kStep3b];
            break;
           
        case kStep3b: //3b. Verify that the state of the link
            [self setInitState:kRunSteps4a4c];
            break;
 
        case kRunSteps4a4c:
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

            [self setInitState:kWaitOnSteps4a4c];
            break;

        case kWaitOnSteps4a4c:
            if([self allRoutersIdle]){
                [self setInitState:kIdle];
            }
            break;
    }
    
    if(initializationState != kRunSteps2a2c && initializationState!= kWaitOnSteps2a2c){
       // NSLog(@"After Step\n");
        [self readDisplayRegs]; //read a few registers that we will use repeatedly and display
    }
    if(initializationState != kStepError && initializationState != kIdle){
        [self performSelector:@selector(stepMaster) withObject:nil afterDelay:kTriggerInitDelay];
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
            //2a-0. Not in orginal document
            //[self writeRegister:kMiscCtl1 withValue:[self readRegister:kMiscCtl1] | kResetLinkInitMachBit]; //<--added
            [self writeRegister:kInputLinkMask withValue:~0x100];           //A set bit disables a channel
            [self setInputLinkMask:  [self readRegister:kInputLinkMask]];   //read it back for display
            //--------------

            [self writeRegister:kSerdesTPower withValue:0xffff];
            [self writeRegister:kSerdesRPower withValue:0xffff];
            
            [self setSerdesTPowerMask:[self readRegister:kSerdesTPower]]; //read back for display
            [self setSerdesRPowerMask:[self readRegister:kSerdesRPower]]; //read back for display
            
            [self setInitState:kStep2b];
            break;
            
        case kStep2b: //2b. Turn on the DEN, REN, and SYNC for Link "L"
            [self writeRegister:kLinkLruCrl withValue:0x007];
            [self setLinkLruCrlReg:[self readRegister:kLinkLruCrl]]; //read back for display
            [self setInitState:kStep2c];
            break;
 
        case kStep2c: //2c. Enable the Link "L" driver
            [self writeRegister:kLvdsPreEmphasis withValue:0x154];
            [self setLvdsPreemphasisCtlMask:[self readRegister:kLvdsPreEmphasis]]; //read back for display
            
            [self setInitState:kStep4a];
            break;
            
        case kStep4a:
            [self writeRegister:kMiscClkCrl withValue:[self readRegister:kMiscClkCrl] | kClockSourceSelectBit];
            [self setInitState:kStep4b]; //go to idle until Master calls back
            break;

        case kStep4b:
            [self setClockUsingLLink:([self readRegister:kMiscClkCrl] & kClockSourceSelectBit)!=0]; //read back for display
            [self setInitState:kIdle]; //go to idle until Master calls back
            break;
          
    }
    //NSLog(@"After Step\n");
    [self readDisplayRegs]; //read a few registers that we will use repeatedly and display
   
    if(initializationState != kStepIdle){
        [self performSelector:@selector(stepRouter) withObject:nil afterDelay:kTriggerInitDelay];
    }
}

- (unsigned long)findRouterMask
{
    unsigned long aMask = 0x0;
    int i;
    for(i=0;i<8;i++){
        ORConnector* otherConnector = [linkConnector[i] connector];
        if([otherConnector identifer] == 'L')aMask |= (0x1<<i);
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
        unsigned long theValue;
        [[self adapter] readLongBlock:&theValue
                            atAddress:[self baseAddress] + fpga_register_information[i].offset
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        NSLog(@"0x%08x: 0x%04x %@\n",[self baseAddress] +fpga_register_information[i].offset,theValue&0xffff,fpga_register_information[i].name);

    }
    NSLog(@"--------------------------------------\n");
}

- (void) dumpRegisters
{
    NSLog(@"--------------------------------------\n");
    NSLog(@"Gretina Trigger Card registers (%@)\n",[self isMaster]?@"Master":@"Router");
    int i;
    for(i=0;i<kNumberOfGretinaTriggerRegisters;i++){
        unsigned long theValue;
        [[self adapter] readLongBlock:&theValue
                            atAddress:[self baseAddress] + register_information[i].offset
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        NSLog(@"0x%08x: 0x%04x %@\n",[self baseAddress] +register_information[i].offset,theValue & 0xffff,register_information[i].name);
        
    }
    NSLog(@"--------------------------------------\n");
}


- (void) testSandBoxRegisters
{
    int i;
    for(i=0;i<4;i++){
        [self testSandBoxRegister:kVMEFPGASandbox1+i];
    }
}

- (void) testSandBoxRegister:(int)anOffset
{
    int errorCount = 0;
    int i;
    unsigned long writeValue = 0 ;
    for(i=0;i<16;i++){
        writeValue = (0x1<<i) & 0xffff;
        [[self adapter] writeLongBlock:&writeValue
                            atAddress:[self baseAddress] + fpga_register_information[anOffset].offset
                            numToWrite:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];

        unsigned long readValue = 0 ;
        [[self adapter] readLongBlock:&readValue
                            atAddress:[self baseAddress] + fpga_register_information[anOffset].offset
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];

        if((writeValue&0xffff) != (readValue & 0xffff)){
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

- (unsigned long) readCodeRevision
{
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kCodeRevision].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue & 0xffff;
}

- (unsigned long) readCodeDate
{
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kCodeModeDate].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue & 0xfff;
}
- (void) writeToAddress:(unsigned long)anAddress aValue:(unsigned long)aValue
{
    aValue &= 0xFFFF;
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
    return value & 0xffff;
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
    [self setInputLinkMask:[decoder decodeInt32ForKey:@"inputLinkMask"]];
    [self setIsMaster: [decoder decodeBoolForKey:@"isMaster"]];
    int i;
    for(i=0;i<9;i++){
        [self setLink:i connector:[decoder decodeObjectForKey:[NSString stringWithFormat:@"linkConnector%d",i]]];
    }
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt32:inputLinkMask forKey:@"inputLinkMask"];
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
        unsigned long statusRegValue = [self readFromAddress:0x904];
		
		if ( (statusRegValue & kFlashBusy)  == kFlashBusy ) {
            //not ready, so re-issue the set-up command
            [self writeToAddress:0x980 aValue:anAddress];
            [self writeToAddress:0x98C aValue:kGretinaTriggerFlashWriteCmd];
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
    
    [self writeToAddress:0x900 aValue:kGretinaTriggerResetMainFPGACmd];
    [self writeToAddress:0x900 aValue:kGretinaTriggerReloadMainFPGACmd];
	
    unsigned long statusRegValue=[self readFromAddress:0x904];
    
    while(!(statusRegValue & kGretinaTriggerMainFPGAIsLoaded)) {
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
