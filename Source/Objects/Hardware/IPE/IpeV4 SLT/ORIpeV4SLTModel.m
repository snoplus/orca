//
//  ORIpeV4SLTModel.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

#import "../IPE Base Classes/ORIpeDefs.h"
#import "ORCrate.h"
#import "ORIpeV4SLTModel.h"
#import "ORIpeFLTModel.h"
#import "ORIpeCrateModel.h"
#import "ORIpeV4SLTDefs.h"
#import "ORReadOutList.h"
#import "unistd.h"
#import "TimedWorker.h"
#import "ORDataTypeAssigner.h"
#import "PCM_Link.h"
#import "SLTv4_HW_Definitions.h"

//control reg bit masks
#define kCtrlLedOffmask	(0x00000001 << 17) //RW
#define kCtrlIntEnMask	(0x00000001 << 16) //RW
#define kCtrlTstSltMask	(0x00000001 << 15) //RW
#define kCtrlRunMask	(0x00000001 << 14) //RW
#define kCtrlShapeMask	(0x00000001 << 13) //RW
#define kCtrlTpEn		(0x00000003 << 11) //RW
#define kCtrlPPS		(0x00000001 << 10) //RW
#define kCtrlInhEn		(0x0000000F <<  6) //RW
#define kCtrlTrEn		(0x0000003F <<  0) //RW

//status reg bit masks
#define kStatusIrq			(0x00000001 << 31) //R
#define kStatusFltStat		(0x00000001 << 30) //R
#define kStatusGps2			(0x00000001 << 29) //R
#define kStatusGps1			(0x00000001 << 28) //R
#define kStatusInhibitSrc	(0x0000000f << 24) //R
#define kStatusInh			(0x00000001 << 23) //R
#define kStatusSemaphores	(0x00000007 << 16) //R - cleared on W
#define kStatusFltTmo		(0x00000001 << 15) //R - cleared on W
#define kStatusPgFull		(0x00000001 << 14) //R - cleared on W
#define kStatusPgRdy		(0x00000001 << 13) //R - cleared on W
#define kStatusEvRdy		(0x00000001 << 12) //R - cleared on W
#define kStatusSwRq			(0x00000001 << 11) //R - cleared on W
#define kStatusFanErr		(0x00000001 << 10) //R - cleared on W
#define kStatusFanErr		(0x00000001 << 10) //R - cleared on W
#define kStatusVttErr		(0x00000001 <<  9) //R - cleared on W
#define kStatusGpsErr		(0x00000001 <<  8) //R - cleared on W
#define kStatusClkErr		(0x0000000F <<  4) //R - cleared on W
#define kStatusPpsErr		(0x00000001 <<  3) //R - cleared on W
#define kStatusPixErr		(0x00000001 <<  2) //R - cleared on W
#define kStatusWDog			(0x00000001 <<  1) //R - cleared on W
#define kStatusFltRq		(0x00000001 <<  0) //R - cleared on W

//Cmd reg bit masks
#define kCmdDisCnt			(0x00000001 << 10) //W - self cleared
#define kCmdEnCnt			(0x00000001 <<  9) //W - self cleared
#define kCmdClrCnt			(0x00000001 <<  8) //W - self cleared
#define kCmdSwRq			(0x00000001 <<  7) //W - self cleared
#define kCmdFltRes			(0x00000001 <<  6) //W - self cleared
#define kCmdSltRes			(0x00000001 <<  5) //W - self cleared
#define kCmdFwCfg			(0x00000001 <<  4) //W - self cleared
#define kCmdTpStart			(0x00000001 <<  3) //W - self cleared
#define kCmdSwTr			(0x00000001 <<  2) //W - self cleared
#define kCmdClrInh			(0x00000001 <<  1) //W - self cleared
#define kCmdSetInh			(0x00000001 <<  0) //W - self cleared

//Interrupt Request and Mask reg bit masks
//Interrupt Request Read only - cleared on Read
//Interrupt Mask Read/Write only
#define kIrptFtlTmo		(0x00000001 << 15) 
#define kIrptPgFull		(0x00000001 << 14) 
#define kIrptPgRdy		(0x00000001 << 13) 
#define kIrptEvRdy		(0x00000001 << 12) 
#define kIrptSwRq		(0x00000001 << 11) 
#define kIrptFanErr		(0x00000001 << 10) 
#define kIrptVttErr		(0x00000001 <<  9) 
#define kIrptGPSErr		(0x00000001 <<  8) 
#define kIrptClkErr		(0x0000000F <<  4) 
#define kIrptPpsErr		(0x00000001 <<  3) 
#define kIrptPixErr		(0x00000001 <<  2) 
#define kIrptWdog		(0x00000001 <<  1) 
#define kIrptFltRq		(0x00000001 <<  0) 

//Revision Masks
#define kRevisionProject (0x0000000F << 28) //R
#define kDocRevision	 (0x00000FFF << 16) //R
#define kImplemention	 (0x0000FFFF <<  0) //R

//Page Manager Masks
#define kPageMngReset			(0x00000001 << 22) //W - self cleared
#define kPageMngNumFreePages	(0x0000007F << 15) //R
#define kPageMngPgFull			(0x00000001 << 14) //W
#define kPageNextPage			(0x0000003F <<  8) //W
#define kPageReady				(0x00000001 <<  7) //W
#define kPageOldestBuffer		(0x0000003F <<  1) //W
#define kPageRelease			(0x00000001 <<  0) //W - self cleared

//Trigger Timing
#define kTrgTimingTrgWindow		(0x00000007 <<  16) //R/W
#define kTrgEndPageDelay		(0x000007FF <<   0) //R/W

//IPE V4 register definitions
enum IpeV4Enum {
	kSLTV4ControlReg,
	kSLTV4StatusReg,
	kSLTV4CommandReg,
	kSLTV4InterruptReguestReg,
	kSLTV4InterruptMaskReg,
	kSLTV4RequestSemaphoreReg,
	kSLTV4HWRevisionReg,
	kSLTV4PixelBusErrorReg,
	kSLTV4PixelBusEnableReg,
	kSLTV4PixelBusTestReg,
	kSLTV4AuxBusTestReg,
	kSLTV4DebugStatusReg,
	kSLTV4DeadCounterLSBReg,
	kSLTV4DeadCounterMSBReg,
	kSLTV4VetoCounterLSBReg,
	kSLTV4VetoCounterMSBReg,
	kSLTV4RunCounterLSBReg,
	kSLTV4RunCounterMSBReg,
	kSLTV4SecondSetReg,
	kSLTV4SecondCounterReg,
	kSLTV4SubSecondCounterReg,
	kSLTV4PageManagerReg,
	kSLTV4TriggerTimingReg,
	kSLTV4PageSelectReg,
	kSLTV4NumberPagesReg,
	kSLTV4PageNumbersReg,
	kSLTV4EventStatusReg,
	kSLTV4ReadoutCSRReg,
	kSLTV4BufferSelectReg,
	kSLTV4ReadoutDefinitionReg,
	kSLTV4TPTimingReg,
	kSLTV4TPShapeReg,
	kSLTV4i2cCommandReg,
	kSLTV4epcsCommandReg,
	kSLTV4BoardIDLSBReg,
	kSLTV4BoardIDMSBReg,
	kSLTV4PROMsControlReg,
	kSLTV4PROMsBufferReg,
	kSLTV4TriggerDataReg,
	kSLTV4ADCDataReg,
	kSLTV4NumRegs //must be last
};

static IpeRegisterNamesStruct regV4[kSLTV4NumRegs] = {
{@"Control",			0xa80000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Status",				0xa80004,		1,			kIpeRegReadable },
{@"Command",			0xa80008,		1,			kIpeRegWriteable },
{@"Interrupt Reguest",	0xA8000C,		1,			kIpeRegReadable },
{@"Interrupt Mask",		0xA80010,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Request Semaphore",	0xA80014,		3,			kIpeRegReadable },
{@"HWRevision",			0xa80020,		1,			kIpeRegReadable },
{@"Pixel Bus Error",	0xA80024,		1,			kIpeRegReadable },			
{@"Pixel Bus Enable",	0xA80028,		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Pixel Bus Test",		0xA8002C, 		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Aux Bus Test",		0xA80030, 		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Debug Status",		0xA80034,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Dead Counter (LSB)",	0xA80080, 		1,			kIpeRegReadable },	
{@"Dead Counter (MSB)",	0xA80084,		1,			kIpeRegReadable },	
{@"Veto Counter (LSB)",	0xA80088, 		1,			kIpeRegReadable },	
{@"Veto Counter (MSB)",	0xA8008C, 		1,			kIpeRegReadable },	
{@"Run Counter (LSB)",	0xA80090,		1,			kIpeRegReadable },	
{@"Run Counter (MSB)",	0xA80094, 		1,			kIpeRegReadable },	
{@"Second Set",			0xB00000,  		1, 			kIpeRegReadable | kIpeRegWriteable }, 
{@"Second Counter",		0xB00004, 		1,			kIpeRegReadable },
{@"Sub-second Counter",	0xB00008, 		1,			kIpeRegReadable }, 
{@"Page Manager",		0xB80000,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Trigger Timing",		0xB80004,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Page Select",		0xB80008, 		1,			kIpeRegReadable },
{@"Number of Pages",	0xB8000C, 		1,			kIpeRegReadable },
{@"Page Numbers",		0xB81000,		64, 		kIpeRegReadable | kIpeRegWriteable },
{@"Event Status",		0xB82000,		64,			kIpeRegReadable },
{@"Readout CSR",		0xC00000,		1,			kIpeRegWriteable },
{@"Buffer Select",		0xC00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Readout Definition",	0xC10000,	  2048,			kIpeRegReadable | kIpeRegWriteable },			
{@"TP Timing",			0xC80000,	   128,			kIpeRegReadable | kIpeRegWriteable },	
{@"TP Shape",			0xC81000,	   512,			kIpeRegReadable | kIpeRegWriteable },	
{@"I2C Command",		0xD00000,		1,			kIpeRegReadable },
{@"EPC Command",		0xD00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Board ID (LSB)",		0xD00008,		1,			kIpeRegReadable },
{@"Board ID (MSB)",		0xD0000C,		1,			kIpeRegReadable },
{@"PROMs Control",		0xD00010,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"PROMs Buffer",		0xD00100,		256,		kIpeRegReadable | kIpeRegWriteable },
{@"Trigger Data",		0xD80000,	  14000,		kIpeRegReadable | kIpeRegWriteable },
{@"ADC Data",			0xE00000,	 0x8000,		kIpeRegReadable | kIpeRegWriteable },
//{@"Data Block RW",		0xF00000 Data Block RW
//{@"Data Block Length",	0xF00004 Data Block Length 
//{@"Data Block Address",	0xF00008 Data Block Address
};


#pragma mark ***External Strings

NSString* ORIpeV4SLTModelHwVersionChanged		= @"ORIpeV4SLTModelHwVersionChanged";

NSString* ORIpeV4SLTModelPatternFilePathChanged		= @"ORIpeV4SLTModelPatternFilePathChanged";
NSString* ORIpeV4SLTModelInterruptMaskChanged		= @"ORIpeV4SLTModelInterruptMaskChanged";
NSString* ORIpeV4SLTModelFpgaVersionChanged			= @"ORIpeV4SLTModelFpgaVersionChanged";
NSString* ORIpeV4SLTModelNHitThresholdChanged		= @"ORIpeV4SLTModelNHitThresholdChanged";
NSString* ORIpeV4SLTModelNHitChanged				= @"ORIpeV4SLTModelNHitChanged";
NSString* ORIpeV4SLTPulserDelayChanged				= @"ORIpeV4SLTPulserDelayChanged";
NSString* ORIpeV4SLTPulserAmpChanged				= @"ORIpeV4SLTPulserAmpChanged";
NSString* ORIpeV4SLTSettingsLock					= @"ORIpeV4SLTSettingsLock";
NSString* ORIpeV4SLTStatusRegChanged				= @"ORIpeV4SLTStatusRegChanged";
NSString* ORIpeV4SLTControlRegChanged				= @"ORIpeV4SLTControlRegChanged";
NSString* ORIpeV4SLTSelectedRegIndexChanged			= @"ORIpeV4SLTSelectedRegIndexChanged";
NSString* ORIpeV4SLTWriteValueChanged				= @"ORIpeV4SLTWriteValueChanged";
NSString* ORIpeV4SLTModelNextPageDelayChanged		= @"ORIpeV4SLTModelNextPageDelayChanged";
NSString* ORIpeV4SLTModelPageStatusChanged			= @"ORIpeV4SLTModelPageStatusChanged";
NSString* ORIpeV4SLTModelPollRateChanged			= @"ORIpeV4SLTModelPollRateChanged";
NSString* ORIpeV4SLTModelReadAllChanged				= @"ORIpeV4SLTModelReadAllChanged";

NSString* ORIpeV4SLTModelPageSizeChanged			= @"ORIpeV4SLTModelPageSizeChanged";
NSString* ORIpeV4SLTModelDisplayTriggerChanged		= @"ORIpeV4SLTModelDisplayTrigerChanged";
NSString* ORIpeV4SLTModelDisplayEventLoopChanged	= @"ORIpeV4SLTModelDisplayEventLoopChanged";
NSString* ORSLTV4cpuLock							= @"ORSLTV4cpuLock";

@interface ORIpeV4SLTModel (private)
- (unsigned long) read:(unsigned long) address;
- (void) write:(unsigned long) address value:(unsigned long) aValue;
@end

@implementation ORIpeV4SLTModel

- (id) init
{
    self = [super init];
	ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];	
	[self setReadOutGroup:readList];
    [self makePoller:0];
	[readList release];
	pcmLink = [[PCM_Link alloc] initWithDelegate:self];
    return self;
}

-(void) dealloc
{
    [patternFilePath release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[readOutGroup release];
    [poller stop];
    [poller release];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
	[pcmLink wakeUp];
    [super wakeUp];
    if(![gOrcaGlobals runInProgress]){
        [poller runWithTarget:self selector:@selector(readAllStatus)];
    }
}

- (void) sleep
{
    [super sleep];
	[pcmLink sleep];
    [poller stop];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		if(!pcmLink){
			pcmLink = [[PCM_Link alloc] initWithDelegate:self];
		}
		[pcmLink connect];
	}
	@catch(NSException* localException) {
	}
}

- (void) setUpImage			{ [self setImage:[NSImage imageNamed:@"IpeV4SLTCard"]]; }
- (void) makeMainController	{ [self linkToController:@"ORIpeV4SLTController"];		}
- (Class) guardianClass		{ return NSClassFromString(@"ORIpeV4CrateModel");		}

- (void) setGuardian:(id)aGuardian //-tb-
{
	if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:self];			
		}
	}
	else {
		[[self guardian] setAdapter:nil];
	}
	[super setGuardian:aGuardian];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(runIsAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(runIsStopped:)
                         name : ORRunStoppedNotification
                       object : nil];
}

#pragma mark •••Accessors
- (unsigned long) projectVersion  { return (hwVersion & kRevisionProject)>>28;}
- (unsigned long) documentVersion { return (hwVersion & kDocRevision)>>16;}
- (unsigned long) implementation  { return hwVersion & kImplemention;}

- (void) setHwVersion:(unsigned long) aVersion
{
	hwVersion = aVersion;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelHwVersionChanged object:self];	
}

/*
- (void) releaseSwInhibit
{
	[self writeReg:kSLTSwRelInhibit value:0];
}

- (void) setSwInhibit
{
	[self writeReg:kSLTSwSetInhibit value:0];
}

- (void) releaseAllPages
{
	int i;
	for(i=0;i<64;i++){
		[self writeReg:kSLTSetPageFree value:i];
	}
}
*/
- (id) controllerCard		{ return self;	  }
- (SBC_Link*)sbcLink		{ return pcmLink; } 
- (TimedWorker *) poller	{ return poller;  }

- (void) setPoller: (TimedWorker *) aPoller
{
    if(aPoller == nil){
        [poller stop];
    }
    [aPoller retain];
    [poller release];
    poller = aPoller;
}

- (void) setPollingInterval:(float)anInterval
{
	[self readAllStatus];
    if(!poller){
        [self makePoller:(float)anInterval];
    }
    else [poller setTimeInterval:anInterval];
    
	[poller stop];
    [poller runWithTarget:self selector:@selector(readAllStatus)];
}


- (void) makePoller:(float)anInterval
{
    [self setPoller:[TimedWorker TimeWorkerWithInterval:anInterval]];
}


- (void) runIsAboutToStart:(NSNotification*)aNote
{
	if([readOutGroup count] == 0){
		[self initBoard];
	}	
}

- (void) runIsStopped:(NSNotification*)aNote
{	
	// Stop all activities by software inhibit
	if([readOutGroup count] == 0){
		//[self setSwInhibit];
	}
	
	// TODO: Save dead time counters ?!
	// Is it sensible to send a new package here?
	// ak 18.7.07
	
	//NSLog(@"Deadtime: %lld\n", [self readDeadTime]);
}

- (void) checkAndLoadFPGAs
{
	BOOL doLoad = NO;
	@try {
		NSArray* cards = [[self crate] orcaObjects];
		NSEnumerator* e = [cards objectEnumerator];
		id card;
		while (card = [e nextObject]){
			if([card isKindOfClass:NSClassFromString(@"ORIpeFLTModel")]){
				//try to access a card. if it throws then we have to load the FPGAs
				[card readControlStatus];
				break;	//only need to try one
			}
		}
	}
	@catch(NSException* localException) {
		doLoad = YES;
	}
	
	@try {
		if(doLoad){
			//[self writeControlReg];
			[self hw_reset];
			NSLog(@"SLT loaded FLT FPGAs\n");
		}
	}
	@catch(NSException* localException) {
		NSLogColor([NSColor redColor],@"SLT failed FLT FPGA load attempt\n");
	}
}

#pragma mark •••Accessors

- (NSString*) patternFilePath
{
    return patternFilePath;
}

- (void) setPatternFilePath:(NSString*)aPatternFilePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternFilePath:patternFilePath];
	
	if(!aPatternFilePath)aPatternFilePath = @"";
    [patternFilePath autorelease];
    patternFilePath = [aPatternFilePath copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelPatternFilePathChanged object:self];
}

- (unsigned long) nextPageDelay
{
	return nextPageDelay;
}

- (void) setNextPageDelay:(unsigned long)aDelay
{	
	if(aDelay>102400) aDelay = 102400;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setNextPageDelay:nextPageDelay];
    
    nextPageDelay = aDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelNextPageDelayChanged object:self];
	
}

- (BOOL) readAll
{
	return readAll;
}

- (void) setReadAll:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setReadAll:readAll];
    
    readAll = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelReadAllChanged object:self];
}


- (unsigned long) pageStatusLow
{
	return pageStatusLow;
}

- (unsigned long) pageStatusHigh
{
	return pageStatusHigh;
}
- (unsigned long) actualPage
{
	return actualPage;
}
- (unsigned long) nextPage
{
	return nextPage;
}

- (void) setPageStatusLow:(unsigned long)loPart high:(unsigned long)hiPart actual:(unsigned long)p0 next:(unsigned long)p1
{
    pageStatusLow	= loPart;
    pageStatusHigh	= hiPart;
    actualPage		= p0;
    nextPage		= p1;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelPageStatusChanged object:self];
}


- (unsigned long) interruptMask
{
    return interruptMask;
}

- (void) setInterruptMask:(unsigned long)aInterruptMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    
    interruptMask = aInterruptMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelInterruptMaskChanged object:self];
}

- (ORReadOutList*) readOutGroup
{
	return readOutGroup;
}

- (void) setReadOutGroup:(ORReadOutList*)newReadOutGroup
{
	[readOutGroup autorelease];
	readOutGroup=[newReadOutGroup retain];
}

- (NSMutableArray*) children 
{
	//method exists to give common interface across all objects for display in lists
	return [NSMutableArray arrayWithObject:readOutGroup];
}

- (BOOL) usingNHitTriggerVersion
{
	if(fpgaVersion >= 3.5)return YES;
	else return NO;
}

- (float) fpgaVersion
{
    return fpgaVersion;
}

- (void) setFpgaVersion:(float)aFpgaVersion
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFpgaVersion:fpgaVersion];
    
    fpgaVersion = aFpgaVersion;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelFpgaVersionChanged object:self];
}

- (unsigned short) nHitThreshold
{
    return nHitThreshold;
}

- (void) setNHitThreshold:(unsigned short)aNHitThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNHitThreshold:nHitThreshold];
	
	if(aNHitThreshold>127)aNHitThreshold=127;
    
    nHitThreshold = aNHitThreshold;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelNHitThresholdChanged object:self];
}

- (unsigned short) nHit
{
    return nHit;
}

- (void) setNHit:(unsigned short)aNHit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNHit:nHit];
    
	if(aNHit>255)aNHit=255;
	
    nHit = aNHit;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelNHitChanged object:self];
}


- (float) pulserDelay
{
    return pulserDelay;
}

- (void) setPulserDelay:(float)aPulserDelay
{
	if(aPulserDelay<100)		 aPulserDelay = 100;
	else if(aPulserDelay>3276.7) aPulserDelay = 3276.7;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setPulserDelay:pulserDelay];
    
    pulserDelay = aPulserDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTPulserDelayChanged object:self];
}

- (float) pulserAmp
{
    return pulserAmp;
}

- (void) setPulserAmp:(float)aPulserAmp
{
	if(aPulserAmp>4)aPulserAmp = 4;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setPulserAmp:pulserAmp];
    
    pulserAmp = aPulserAmp;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTPulserAmpChanged object:self];
}

- (short) getNumberRegisters			
{ 
    return kSLTV4NumRegs; 
}

- (NSString*) getRegisterName: (short) anIndex
{
    return regV4[anIndex].regName;
}

- (unsigned long) getAddress: (short) anIndex
{
    return( regV4[anIndex].addressOffset>>2);

}

- (short) getAccessType: (short) anIndex
{
	return regV4[anIndex].accessType;
}

- (unsigned short) selectedRegIndex
{
    return selectedRegIndex;
}

- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:selectedRegIndex];
    
    selectedRegIndex = anIndex;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIpeV4SLTSelectedRegIndexChanged
	 object:self];
}

- (unsigned long) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    
    writeValue = aValue;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIpeV4SLTWriteValueChanged
	 object:self];
}

//status reg values

- (BOOL) inhibit
{
    return inhibit;
}

- (void) setInhibit:(BOOL)aInhibit
{
	inhibit = aInhibit;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTStatusRegChanged object:self];
}

- (BOOL) swInhibit
{
    return swInhibit;
}

- (void) setSwInhibit:(BOOL)aSwInhibit
{
	swInhibit = aSwInhibit;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTStatusRegChanged object:self];
}

- (BOOL) nopgInhibit
{
    return nopgInhibit;
}

- (void) setNopgInhibit:(BOOL)aNopgInhibit
{
	nopgInhibit = aNopgInhibit;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTStatusRegChanged object:self];
}

- (BOOL) extInhibit
{
    return extInhibit;
}

- (void) setExtInhibit:(BOOL)aExtInhibit
{
	extInhibit = aExtInhibit;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTStatusRegChanged object:self];
}

- (BOOL) veto
{
    return veto;
}

- (void) setVeto:(BOOL)aVeto
{
	veto = aVeto;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTStatusRegChanged object:self];
}


//control reg access
- (BOOL) ledInhibit
{
	return ledInhibit;
}
- (void) setLedInhibit:(BOOL)aState
{
	if(aState != ledInhibit) {
		[[[self undoManager] prepareWithInvocationTarget:self] setLedInhibit:ledInhibit];
		
		ledInhibit = aState;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTControlRegChanged object:self];
	}
}

- (BOOL) ledVeto
{
	return ledVeto;
}
- (void) setLedVeto:(BOOL)aState
{
	if(aState != ledVeto) {
		[[[self undoManager] prepareWithInvocationTarget:self] setLedVeto:ledVeto];
		
		ledVeto = aState;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTControlRegChanged object:self];
	}
}

- (BOOL) enableDeadTimeCounter
{
    return enableDeadTimeCounter;
}

- (void) setEnableDeadTimeCounter:(BOOL)aState
{
	if(aState != enableDeadTimeCounter) {
		[[[self undoManager] prepareWithInvocationTarget:self] setEnableDeadTimeCounter:enableDeadTimeCounter];
		
		enableDeadTimeCounter = aState;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTControlRegChanged object:self];
	}
}


- (int) watchDogStart
{
    return watchDogStart;
}

- (void) setWatchDogStart:(int)aWatchDogStart
{
	if(aWatchDogStart ==  0)aWatchDogStart  = 1;
	if(aWatchDogStart!= 1 && aWatchDogStart!= 2) aWatchDogStart  = 1;
	if(aWatchDogStart != watchDogStart) {
		[[[self undoManager] prepareWithInvocationTarget:self] setWatchDogStart:watchDogStart];
		
		watchDogStart = aWatchDogStart;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTControlRegChanged object:self];
	}
}

- (int) secStrobeSource
{
    return secStrobeSource;
}

- (void) setSecStrobeSource:(int)aSecStrobeSource
{
	if(aSecStrobeSource!= 0 && aSecStrobeSource!= 1) return;
	
	if(aSecStrobeSource != secStrobeSource) {
		[[[self undoManager] prepareWithInvocationTarget:self] setSecStrobeSource:secStrobeSource];
		
		secStrobeSource = aSecStrobeSource;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTControlRegChanged object:self];
	}
}

- (int) testPulseSource
{
    return testPulseSource;
}

- (void) setTestPulseSource:(int)aTestPulseSource
{
	if(aTestPulseSource ==  0)aTestPulseSource  = 1;
	if(aTestPulseSource!= 1 && aTestPulseSource!= 2) return;
	
	if(aTestPulseSource != testPulseSource) {
		[[[self undoManager] prepareWithInvocationTarget:self] setTestPulseSource:testPulseSource];
		
		testPulseSource = aTestPulseSource;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTControlRegChanged object:self];
	}
}

- (int) inhibitSource
{
    return inhibitSource;
}

- (void) setInhibitSource:(int)aInhibitSource
{
	aInhibitSource &= 0x7; //only care about the lowest 3 bits
	
	if(aInhibitSource != inhibitSource) {
		[[[self undoManager] prepareWithInvocationTarget:self] setInhibitSource:inhibitSource];
		
		inhibitSource = aInhibitSource;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTControlRegChanged object:self];
	}
}

- (int) triggerSource
{	
    return triggerSource;
}

- (void) setTriggerSource:(int)aTriggerSource
{
	if(aTriggerSource != triggerSource) {
		[[[self undoManager] prepareWithInvocationTarget:self] setTriggerSource:triggerSource];
		
		triggerSource = aTriggerSource;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTControlRegChanged object:self];
	}
}


- (BOOL) displayTrigger
{
	return displayTrigger;
}

- (void) setDisplayTrigger:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayTrigger:displayTrigger];
	
	displayTrigger = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelDisplayTriggerChanged object:self];
	
}

- (BOOL) displayEventLoop
{
	return displayEventLoop;
}

- (void) setDisplayEventLoop:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayEventLoop:displayEventLoop];
	
	displayEventLoop = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelDisplayEventLoopChanged object:self];
	
}

- (unsigned long) pageSize
{
	return pageSize;
}

- (void) setPageSize: (unsigned long) aPageSize
{
	
	[[[self undoManager] prepareWithInvocationTarget:self] setPageSize:pageSize];
	
    if (aPageSize < 0) pageSize = 0;
	else if (aPageSize > 100) pageSize = 100;
	else pageSize = aPageSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelPageSizeChanged object:self];
	
}  

#pragma mark ***HW Access
- (void) checkPresence
{
	@try {
	//	[self readStatusReg];
		[self setPresent:YES];
	}
	@catch(NSException* localException) {
		[self setPresent:NO];
	}
}
/*
- (void) loadPatternFile
{
	NSString* contents = [NSString stringWithContentsOfFile:patternFilePath encoding:NSASCIIStringEncoding error:nil];
	if(contents){
		NSLog(@"loading Pattern file: <%@>\n",patternFilePath);
		NSScanner* scanner = [NSScanner scannerWithString:contents];
		int amplitude;
		[scanner scanInt:&amplitude];
		int i=0;
		int j=0;
		unsigned long time[256];
		unsigned long mask[20][256];
		int len = 0;
		BOOL status;
		while(1){
			status = [scanner scanHexInt:(unsigned*)&time[i]];
			if(!status)break;
			if(time[i] == 0){
				break;
			}
			for(j=0;j<20;j++){
				status = [scanner scanHexInt:(unsigned*)&mask[j][i]];
				if(!status)break;
			}
			i++;
			len++;
			if(i>256)break;
			if(!status)break;
		}
		
		@try {
			//collect all valid cards
			ORIpeFLTModel* cards[20];//TODO: ORIpeV4SLTModel -tb-
			int i;
			for(i=0;i<20;i++)cards[i]=nil;
			
			NSArray* allFLTs = [[self crate] orcaObjects];
			NSEnumerator* e = [allFLTs objectEnumerator];
			id aCard;
			while(aCard = [e nextObject]){
				if([aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")])continue;//TODO: is this still true for v4? -tb-
				int index = [aCard stationNumber] - 1;
				if(index<20){
					cards[index] = aCard;
				}
			}
			for(i=0;i<20;i++){
				[cards[i] setFltRunMode: kIpeFlt_Test_Mode];
			}
			
			
			[self writeReg:kSLTTestpulsAmpl value:amplitude];
			[self writeBlock:SLT_REG_ADDRESS(kSLTTimingMemory) 
				  dataBuffer:time
					  length:len
				   increment:1];
			
			
			int j;
			for(j=0;j<20;j++){
				[cards[j] writeTestPattern:mask[j] length:len];
			}
			
			[self swTrigger];
			
			NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n");			
			NSLogFont(aFont,@"Index|  Time    | Mask                              Amplitude = %5d\n",amplitude);			
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n");			
			NSLogFont(aFont,@"     |    delta |  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20\n");			
			unsigned int delta = time[0];
			for(i=0;i<len;i++){
				NSMutableString* line = [NSMutableString stringWithFormat:@"  %2d |=%4d=%4d|",i,delta,time[i]];
				delta += time[i];
				for(j=0;j<20;j++){
					if(mask[j][i] != 0x1000000)[line appendFormat:@"%3s",mask[j][i]?"•":"-"];
					else [line appendFormat:@"%3s","="];
				}
				NSLogFont(aFont,@"%@\n",line);
			}
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n",amplitude);			
			
			
			for(i=0;i<20;i++){
				[cards[i] setFltRunMode: kIpeFlt_Run_Mode];
			}
			
			
		}
		@catch(NSException* localException) {
			NSLogColor([NSColor redColor],@"Couldn't load Pattern file <%@>\n",patternFilePath);
		}
	}
	else NSLogColor([NSColor redColor],@"Couldn't open Pattern file <%@>\n",patternFilePath);
}

- (void) swTrigger
{
	[self writeReg:kSLTSwTestpulsTrigger value:0];
}
*/

- (void) writeReg:(unsigned short)index value:(unsigned long)aValue
{
	[self write: [self getAddress:index] value:aValue];
}

- (unsigned long) readReg:(unsigned short) index
{
	return [self read: [self getAddress:index]];

}

- (void) readAllStatus
{
	//[self readPageStatus];
	//[self readStatusReg];
}
/*
- (void) readPageStatus
{
	[self setPageStatusLow:   [self readReg:kPageStatusLow] 
					  high:   [self readReg:kPageStatusHigh]
					actual: [self readReg:kSLTActualPage]
					  next:   [self readReg:kSLTNextPage]];
}

- (unsigned long) readStatusReg
{
	unsigned long data = 0;
	
	data = [self readReg:kSLTStatusReg];
	
	[self setVeto:				(data >> SLT_VETO)			& 0x1];
	[self setExtInhibit:		(data >> SLT_EXTINHIBIT)	& 0x1];	
	[self setNopgInhibit:		(data >> SLT_NOPGINHIBIT)	& 0x1];
	[self setSwInhibit:			(data >> SLT_SWINHIBIT)		& 0x1];
	[self setInhibit:			(data >> SLT_INHIBIT)		& 0x1];
	
	return data;
}
*/
- (void) printStatusReg
{
	//[self readStatusReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Status Register SLT (%d) ----\n",[self stationNumber]);
	NSLogFont(aFont,@"Veto             : %d\n",veto);
	NSLogFont(aFont,@"ExtInhibit       : %d\n",extInhibit);
	NSLogFont(aFont,@"NopgInhibit      : %d\n",nopgInhibit);
	NSLogFont(aFont,@"SwInhibit        : %d\n",swInhibit);
	NSLogFont(aFont,@"Inhibit          : %d\n",inhibit);
}
/*
- (void) writeStatusReg
{
	unsigned long data = 0;
	data |= veto			 << SLT_VETO;
	data |= extInhibit		 << SLT_EXTINHIBIT;
	data |= nopgInhibit		 << SLT_NOPGINHIBIT;
	data |= swInhibit		 << SLT_SWINHIBIT;
	data |= inhibit			 << SLT_INHIBIT;
	[self writeReg:kSLTStatusReg value:data];
}

- (void) writeNextPageDelay
{
	//nextPageDelay stored as number from 0 - 100
	unsigned long aValue = nextPageDelay * 1999./100.; //convert to value 0 - 1999 x 50us  // ak, 5.10.07
	[self writeReg:kSLTT1 value:aValue];
}


- (unsigned long) readControlReg
{
	unsigned long data;
	
	data = [self readReg:kSLTControlReg];
	
	[self setLedInhibit:			(data >> SLT_UPPERLED)      & SLT_UPPERLED_MASK];
	[self setLedVeto:				(data >> SLT_LOWERLED)      & SLT_LOWERLED_MASK];
	[self setTriggerSource:			(data >> SLT_TRIGGER_LOW)   & SLT_TRIGGER_MASK];
	[self setInhibitSource:			(data >> SLT_INHIBIT_LOW)   & SLT_INHIBIT_MASK];
	[self setTestPulseSource:		(data >> SLT_TESTPULS_LOW)  & SLT_TESTPULS_MASK];
	[self setSecStrobeSource:		(data >> SLT_SECSTROBE_LOW) & SLT_SECSTROBE_MASK];
	[self setWatchDogStart:		    (data >> SLT_WATCHDOGSTART_LOW) & SLT_WATCHDOGSTART_MASK];
	[self setEnableDeadTimeCounter: (data >> SLT_DEADTIMECOUNTERS)  & SLT_DEADTIMECOUNTERS_MASK];
	
	if(fpgaVersion >= 3.5){
		data = [self readReg:kSLTThresh_Rd];
		[self setNHit:			(data >> SLT_NHIT)			 & SLT_NHIT_MASK];
		[self setNHitThreshold:	(data >> SLT_NHIT_THRESHOLD) & SLT_NHIT_THRESHOLD_MASK];
	}
	
	return data;
}

- (void) printControlReg
{
	unsigned long data = [self readReg:kSLTControlReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Control Register SLT (%d) ----\n",[self stationNumber]);
	NSLogFont(aFont,@"LedInhibit       : %d\n",(data >> SLT_UPPERLED)      & SLT_UPPERLED_MASK);
	NSLogFont(aFont,@"LedVeto          : %d\n",(data >> SLT_LOWERLED)      & SLT_LOWERLED_MASK);
	NSLogFont(aFont,@"TriggerSource    : 0x%x\n",(data >> SLT_TRIGGER_LOW)   & SLT_TRIGGER_MASK);
	NSLogFont(aFont,@"InhibitSource    : 0x%x\n",(data >> SLT_INHIBIT_LOW)   & SLT_INHIBIT_MASK);
	NSLogFont(aFont,@"TestPulseSource  : 0x%x\n",(data >> SLT_TESTPULS_LOW)  & SLT_TESTPULS_MASK);
	NSLogFont(aFont,@"SecStrobeSource  : 0x%x\n",(data >> SLT_SECSTROBE_LOW) & SLT_SECSTROBE_MASK);
	NSLogFont(aFont,@"WatchDogStart    : 0x%x\n",(data >> SLT_WATCHDOGSTART_LOW) & SLT_WATCHDOGSTART_MASK);
	NSLogFont(aFont,@"EnableDeadTimeCnt: %d\n",(data >> SLT_DEADTIMECOUNTERS)  & SLT_DEADTIMECOUNTERS_MASK);
	if(fpgaVersion >= 3.5){
		data = [self readReg:kSLTThresh_Rd];
		NSLogFont(aFont,@"Multiplicity Receive\n");
		NSLogFont(aFont,@"NHit             : %d\n",(data >> SLT_NHIT)			 & SLT_NHIT_MASK);
		NSLogFont(aFont,@"NHitThreshold    : %d\n",(data >> SLT_NHIT_THRESHOLD)	 & SLT_NHIT_THRESHOLD_MASK);
	}
}

- (void) writeControlReg
{
	unsigned long data = 0;
	data |= (ledInhibit   & SLT_UPPERLED_MASK)   << SLT_UPPERLED;
	data |= (ledVeto   & SLT_LOWERLED_MASK)   << SLT_LOWERLED;
	data |= (triggerSource   & SLT_TRIGGER_MASK)   << SLT_TRIGGER_LOW;
	data |= (inhibitSource   & SLT_INHIBIT_MASK)   << SLT_INHIBIT_LOW;
	data |= (testPulseSource  & SLT_TESTPULS_MASK)  << SLT_TESTPULS_LOW;
	data |= (secStrobeSource & SLT_SECSTROBE_MASK) << SLT_SECSTROBE_LOW;
	data |= (watchDogStart   & SLT_WATCHDOGSTART_MASK)   << SLT_WATCHDOGSTART_LOW;
	data |= (enableDeadTimeCounter  & SLT_DEADTIMECOUNTERS_MASK)  << SLT_DEADTIMECOUNTERS;
	[self writeReg:kSLTControlReg value:data];
	
	if(fpgaVersion >= 3.5){
		data = 0x8000 | 
		(nHit   & SLT_NHIT_MASK)   << SLT_NHIT | 
		(nHitThreshold & SLT_NHIT_THRESHOLD_MASK)   << SLT_NHIT_THRESHOLD;
		[self writeReg:kSLTThresh_Wr value:data];
		[self writeReg:kSLTThresh_Wr value:0];
		data = [self readReg:kSLTThresh_Rd];
		NSLog(@"M threshold = %4d  N threshold = %4d\n",(data>>8)&0x3f, data&0xff);				
	}
}

- (void) writeInterruptMask
{
	[self writeReg:kSLTIRMask value:interruptMask];
}

- (void) readInterruptMask
{
	[self setInterruptMask:[self readReg:kSLTIRMask]];
}

- (void) printInterruptMask
{
	unsigned long data = [self readReg:kSLTIRMask];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Interrupt Mask SLT (%d) ----\n",[self stationNumber]);
	if(!data)NSLogFont(aFont,@"Interrupt Mask is Clear (No interrupts enabled)\n");
	else {
		NSLogFont(aFont,@"The following interrupts are enabled:\n");
		
		if(data & (1<<0))NSLogFont(aFont,@"\tNext Page\n");
		if(data & (1<<1))NSLogFont(aFont,@"\tAll Pages Full\n");
		if(data & (1<<2))NSLogFont(aFont,@"\tFLT Config Failure\n");
		if(data & (1<<3))NSLogFont(aFont,@"\tFLT Cmd sent after Config Failure\n");
		if(data & (1<<4))NSLogFont(aFont,@"\tWatchDog Error\n");
		if(data & (1<<5))NSLogFont(aFont,@"\tSecond Strobe Error\n");
		if(data & (1<<6))NSLogFont(aFont,@"\tParity Error\n");
		if(data & (1<<7))NSLogFont(aFont,@"\tNext Page When Full\n");
		if(data & (1<<8))NSLogFont(aFont,@"\tNext Page , Previous\n");
	}
}
*/

- (float) readHwVersion
{
	unsigned long value;
	@try {
		[self setHwVersion:[self readReg: kSLTV4HWRevisionReg]];	
	}
	@catch (NSException* e){
	}
	return value;
}

/*
- (unsigned long long) readDeadTime
{
	unsigned long low  = [self readReg:kSLTDeadTimeLow];
	unsigned long high = [self readReg:kSLTDeadTimeHigh];
	return ((unsigned long long)high << 32) | low;
}

- (unsigned long long) readVetoTime
{
	unsigned long low  = [self readReg:kSLTVetoTimeLow];
	unsigned long high = [self readReg:kSLTVetoTimeHigh];
	return ((unsigned long long)high << 32) | low;
}
*/
- (void) initBoard
{
	
	//-----------------------------------------------
	//board doesn't appear to start without this stuff
	//[self writeReg:kSLTActResetFlt value:0];
	//[self writeReg:kSLTActResetSlt value:0];
	usleep(10);
	//[self writeReg:kSLTRelResetFlt value:0];
	//[self writeReg:kSLTRelResetSlt value:0];
	//[self writeReg:kSLTSwSltTrigger value:0];
	//[self writeReg:kSLTSwSetInhibit value:0];
	
	usleep(100);
	
	int savedTriggerSource = triggerSource;
	int savedInhibitSource = inhibitSource;
	triggerSource = 0x1; //sw trigger only
	inhibitSource = 0x3; 
	//[self writeControlReg];
//	[self releaseAllPages];
	//unsigned long long p1 = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	//[self writeReg:kSLTSwRelInhibit value:0];
	int i = 0;
	unsigned long lTmp;
    do {
	//	lTmp = [self readReg:kSLTStatusReg];
		//NSLog(@"waiting for inhibit %x i=%d\n", lTmp, i);
		usleep(10);
		i++;
    } while(((lTmp & 0x10000) != 0) && (i<10000));
	
    if (i>= 10000){
		NSLog(@"Release inhibit failed\n");
		[NSException raise:@"SLT error" format:@"Release inhibit failed"];
	}
/*	
	unsigned long long p2  = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	if(p1 == p2) NSLog (@"No software trigger\n");
	[self writeReg:kSLTSwSetInhibit value:0];
 */
	triggerSource = savedTriggerSource;
	inhibitSource = savedInhibitSource;
	//-----------------------------------------------
	
	//[self writeControlReg];
	//[self writeInterruptMask];
	//[self writeNextPageDelay];
	//[self readControlReg];	
	//[self printStatusReg];
	//[self printControlReg];
}

- (void) reset
{
	[self hw_config];
	[self hw_reset];
}

- (void) hw_config
{
	NSLog(@"SLT: HW Configure\n");
	//[self writeReg:kSLTConfFltFPGAs value:0];
	[ORTimer delay:1.5];
	//[self writeReg:kSLTConfSltFPGAs value:0];
	[ORTimer delay:1.5];
	//[self readReg:kSLTStatusReg];
	[guardian checkCards];
}

- (void) hw_reset
{
	NSLog(@"SLT: HW Reset\n");
	//[self writeReg:kSLTSwRelInhibit value:0];
	//[self writeReg:kSLTActResetFlt value:0];
	//[self writeReg:kSLTActResetSlt value:0];
	usleep(10);
	//[self writeReg:kSLTRelResetFlt value:0];
	//[self writeReg:kSLTRelResetSlt value:0];
	//[self writeReg:kSLTSwSltTrigger value:0];
	//[self writeReg:kSLTSwSetInhibit value:0];				
}
/*
- (void) loadPulseAmp
{
	unsigned short theConvertedAmp = pulserAmp * 4095./4.;
	[self writeReg:kSLTTestpulsAmpl value:theConvertedAmp];
	NSLog(@"Wrote %.2fV to SLT pulser Amplitude\n",pulserAmp);
}

- (void) loadPulseDelay
{
	//delay goes from 100ns to 3276.8us
	//writing 0x00 to hw gives longest delay. 
	//conversion equation:  hwValue = -10.0*delay + 32768.
	unsigned short theConvertedDelay = pulserDelay * -10.0 + 32768.;
	[self write:SLT_REG_ADDRESS(kSLTTestpulsTiming)+0 value:theConvertedDelay];
	[self write:SLT_REG_ADDRESS(kSLTTestpulsTiming)+1 value:theConvertedDelay];
	int i; //load the rest of the pulser memory with 0's
	for (i=2;i<256;i++) [self write:SLT_REG_ADDRESS(kSLTTestpulsTiming)+i value:theConvertedDelay];
}


- (void) pulseOnce
{
	//int savedTriggerSource = [self triggerSource];
	//[self setTriggerSource:0x01]; //set for sw trigger
	//[self writeControlReg];
	
	[self writeReg:kSLTSwSltTrigger value:0];	// send SW trigger
	
	//[self setTriggerSource:savedTriggerSource];
	//[self writeControlReg];
}

- (void) loadPulserValues
{
	[self loadPulseAmp];
	[self loadPulseDelay];
}
*/
- (void) setCrateNumber:(unsigned int)aNumber
{
	[guardian setCrateNumber:aNumber];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	pcmLink = [[decoder decodeObjectForKey:@"PCM_Link"] retain];
	if(!pcmLink){
		pcmLink = [[PCM_Link alloc] initWithDelegate:self];
	}
	else [pcmLink setDelegate:self];
	
	//status reg
	[self setPatternFilePath:		[decoder decodeObjectForKey:@"ORIpeV4SLTModelPatternFilePath"]];
	[self setInterruptMask:			[decoder decodeInt32ForKey:@"ORIpeV4SLTModelInterruptMask"]];
	[self setPulserDelay:			[decoder decodeFloatForKey:@"ORIpeV4SLTModelPulserDelay"]];
	[self setPulserAmp:				[decoder decodeFloatForKey:@"ORIpeV4SLTModelPulserAmp"]];
	[self setInhibit:				[decoder decodeBoolForKey:@"ORIpeV4SLTStatusInhibit"]];
	[self setSwInhibit:				[decoder decodeBoolForKey:@"ORIpeV4SLTStatusSwInhibit"]];
	[self setNopgInhibit:			[decoder decodeBoolForKey:@"ORIpeV4SLTStatusNopgInhibit"]];
	[self setExtInhibit:			[decoder decodeBoolForKey:@"ORIpeV4SLTStatusExtInhibit"]];
	[self setVeto:					[decoder decodeBoolForKey:@"ORIpeV4SLTStatusVeto"]];
	
	//control reg
	[self setTriggerSource:			[decoder decodeIntForKey:@"triggerSource"]];
	[self setInhibitSource:			[decoder decodeIntForKey:@"inhibitSource"]];
	[self setTestPulseSource:		[decoder decodeIntForKey:@"testPulseSource"]];
	[self setSecStrobeSource:		[decoder decodeIntForKey:@"secStrobeSource"]];
	[self setWatchDogStart:			[decoder decodeIntForKey:@"watchDogStart"]];
	[self setEnableDeadTimeCounter:	[decoder decodeIntForKey:@"enableDeadTimeCounter"]];
	[self setLedInhibit:			[decoder decodeBoolForKey:@"ledInhibit"]];
	[self setLedVeto:				[decoder decodeBoolForKey:@"ledVeto"]];
	
	//special
	[self setNHitThreshold:			[decoder decodeIntForKey:@"ORIpeV4SLTModelNHitThreshold"]];
	[self setNHit:					[decoder decodeIntForKey:@"ORIpeV4SLTModelNHit"]];
	[self setReadAll:				[decoder decodeBoolForKey:@"readAll"]];
    [self setNextPageDelay:			[decoder decodeIntForKey:@"nextPageDelay"]]; // ak, 5.10.07
	
	[self setReadOutGroup:			[decoder decodeObjectForKey:@"ReadoutGroup"]];
    [self setPoller:				[decoder decodeObjectForKey:@"poller"]];
	
    [self setPageSize:				[decoder decodeIntForKey:@"ORIpeV4SLTPageSize"]]; // ak, 9.12.07
    [self setDisplayTrigger:		[decoder decodeBoolForKey:@"ORIpeV4SLTDisplayTrigger"]];
    [self setDisplayEventLoop:		[decoder decodeBoolForKey:@"ORIpeV4SLTDisplayEventLoop"]];
    	
    if (!poller)[self makePoller:0];
	
	//needed because the readoutgroup was added when the object was already in the config and so might not be in the configuration
	if(!readOutGroup){
		ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
		[self setReadOutGroup:readList];
		[readList release];
	}
	
	[[self undoManager] enableUndoRegistration];
	
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	
	[encoder encodeObject:pcmLink		forKey:@"PCM_Link"];
	
	//status reg
	[encoder encodeObject:patternFilePath forKey:@"ORIpeV4SLTModelPatternFilePath"];
	[encoder encodeInt32:interruptMask	 forKey:@"ORIpeV4SLTModelInterruptMask"];
	[encoder encodeFloat:pulserDelay	 forKey:@"ORIpeV4SLTModelPulserDelay"];
	[encoder encodeFloat:pulserAmp		 forKey:@"ORIpeV4SLTModelPulserAmp"];
	[encoder encodeBool:inhibit			 forKey:@"ORIpeV4SLTStatusInhibit"];
	[encoder encodeBool:swInhibit		 forKey:@"ORIpeV4SLTStatusSwInhibit"];
	[encoder encodeBool:nopgInhibit		 forKey:@"ORIpeV4SLTStatusNopgInhibit"];
	[encoder encodeBool:extInhibit		 forKey:@"ORIpeV4SLTStatusExtInhibit"];
	[encoder encodeBool:veto			 forKey:@"ORIpeV4SLTStatusVeto"];
	
	//control reg
	[encoder encodeInt:triggerSource	forKey:@"triggerSource"];
	[encoder encodeInt:inhibitSource	forKey:@"inhibitSource"];
	[encoder encodeInt:testPulseSource	forKey:@"testPulseSource"];
	[encoder encodeInt:secStrobeSource	forKey:@"secStrobeSource"];
	[encoder encodeInt:watchDogStart	forKey:@"watchDogStart"];
	[encoder encodeInt:enableDeadTimeCounter	forKey:@"enableDeadTimeCounter"];
	[encoder encodeBool:ledInhibit		forKey:@"ledInhibit"];
	[encoder encodeBool:ledVeto			forKey:@"ledVeto"];
	
	
	//special
	[encoder encodeInt:nHitThreshold	 forKey:@"ORIpeV4SLTModelNHitThreshold"];
	[encoder encodeInt:nHit				 forKey:@"ORIpeV4SLTModelNHit"];
	[encoder encodeBool:readAll			 forKey:@"readAll"];
    [encoder encodeInt:nextPageDelay     forKey:@"nextPageDelay"]; // ak, 5.10.07
	
	[encoder encodeObject:readOutGroup  forKey:@"ReadoutGroup"];
    [encoder encodeObject:poller         forKey:@"poller"];
	
    [encoder encodeInt:pageSize         forKey:@"ORIpeV4SLTPageSize"]; // ak, 9.12.07
    [encoder encodeBool:displayTrigger   forKey:@"ORIpeV4SLTDisplayTrigger"];
    [encoder encodeBool:displayEventLoop forKey:@"ORIpeV4SLTDisplayEventLoop"];
		
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORIpeV4SLTDecoderForEvent",				@"decoder",
								 [NSNumber numberWithLong:eventDataId],	@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:5],			@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeV4SLTEvent"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORIpeV4SLTDecoderForMultiplicity",			@"decoder",
				   [NSNumber numberWithLong:multiplicityId],   @"dataId",
				   [NSNumber numberWithBool:NO],				@"variable",
				   [NSNumber numberWithLong:3+20*100],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeV4SLTMultiplicity"];
    
    return dataDictionary;
}

- (unsigned long) eventDataId        { return eventDataId; }
- (unsigned long) multiplicityId	 { return multiplicityId; }
- (void) setEventDataId: (unsigned long) aDataId    { eventDataId = aDataId; }
- (void) setMultiplicityId: (unsigned long) aDataId { multiplicityId = aDataId; }

- (void) setDataIds:(id)assigner
{
    eventDataId     = [assigner assignDataIds:kLongForm];
    multiplicityId  = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setEventDataId:[anotherCard eventDataId]];
    [self setMultiplicityId:[anotherCard multiplicityId]];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithInt:triggerSource]	forKey:@"triggerSource"];
    [objDictionary setObject:[NSNumber numberWithInt:inhibitSource]	forKey:@"inhibitSource"];	
    [objDictionary setObject:[NSNumber numberWithInt:nHit]			forKey:@"nHit"];	
    [objDictionary setObject:[NSNumber numberWithInt:nHitThreshold]	forKey:@"nHitThreshold"];	
    [objDictionary setObject:[NSNumber numberWithBool:readAll]		forKey:@"readAll"];	
	return objDictionary;
}

#pragma mark •••Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    [self clearExceptionCount];
	
	//check that we can actually run
    if(![[[self crate] adapter] serviceIsAlive]){
		[NSException raise:@"No FireWire Service" format:@"Check Crate Power and FireWire Cable."];
    }
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORIpeV4SLTModel"];    
    //----------------------------------------------------------------------------------------	
	
	pollingWasRunning = [poller isRunning];
	if(pollingWasRunning) [poller stop];
	
	//[self setSwInhibit];
	
    if([[userInfo objectForKey:@"doinit"]intValue]){
		[self initBoard];					
	}	
	
	dataTakers = [[readOutGroup allObjects] retain];		//cache of data takers.
	
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
	
	//[self readStatusReg];
	actualPageIndex = 0;
	eventCounter    = 0;
	first = YES;
	lastDisplaySec = 0;
	lastDisplayCounter = 0;
	lastDisplayRate = 0;
	lastSimSec = 0;
	
	//load all the data needed for the eCPU to do the HW read-out.
	[self load_HW_Config];
	[pcmLink runTaskStarted:aDataPacket userInfo:userInfo];
	
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if(!first){
		//event readout controlled by the SLT cpu now. ORCA reads out 
		//the resulting data from a generic circular buffer in the pcmLink code.
		[pcmLink takeData:aDataPacket userInfo:userInfo];
	}
	else {
		//[self releaseAllPages];
		//[self releaseSwInhibit];
		//[self writeReg:kSLTResetDeadTime value:0];
		first = NO;
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	//[self setSwInhibit];
	
	[pcmLink runTaskStopped:aDataPacket userInfo:userInfo];
	
	if(pollingWasRunning) {
		[poller runWithTarget:self selector:@selector(readAllStatus)];
	}
}

- (unsigned long) calcProjection:(unsigned long *)pMult  xyProj:(unsigned long *)xyProj  tyProj:(unsigned long *)tyProj
{ 
	//temp----
	int i, j, k;
	int sltSize = pageSize * 20;	
	
	
	// Dislay the matrix of triggered pixel and timing
	// The xy-Projection is needed to readout only the triggered pixel!!!
	//unsigned long xyProj[20];
	//unsigned long tyProj[100];
	for (i=0;i<20;i++) xyProj[i] = 0;
	for (k=0;k<100;k++) tyProj[k] = 0;
	for (k=0;k<sltSize;k++){
		xyProj[k%20] = xyProj[k%20] | (pMult[k] & 0x3fffff);
	}  
	for (k=0;k<sltSize;k++){
		if (xyProj[k%20]) {
			tyProj[k/20] = tyProj[k/20] | (pMult[k] & 0x3fffff);
		}
	}
	
	int nTriggered = 0;
	for (i=0;i<20;i++){
		for(j=0;j<22;j++){
			if (((xyProj[i]>>j) & 0x1 ) == 0x1) nTriggered++;
		}
	}
	
	
	// Display trigger data
	if (displayTrigger) {	
		int i, j, k;
		NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
		
		for(j=0;j<22;j++){
			NSMutableString* s = [NSMutableString stringWithFormat:@"%2d: ",j];
			//matrix of triggered pixel
			for(i=0;i<20;i++){
				if (((xyProj[i]>>j) & 0x1) == 0x1) [s appendFormat:@"X"];
				else							   [s appendFormat:@"."];
			}
			[s appendFormat:@"  "];
			
			// trigger timing
			for (k=0;k<pageSize;k++){
				if (((tyProj[k]>>j) & 0x1) == 0x1 )[s appendFormat:@"="];
				else							   [s appendFormat:@"."];
			}
			NSLogFont(aFont, @"%@\n", s);
		}
		
		NSLogFont(aFont,@"\n");	
	}		
	return(nTriggered);
}

- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [readOutGroup saveUsingFile:aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [self setReadOutGroup:[[[ORReadOutList alloc] initWithIdentifier:@"cPCI"]autorelease]];
    [readOutGroup loadUsingFile:aFile];
}
/*
- (void) dumpTriggerRAM:(int)aPageIndex
{
	
	//read page start address
	unsigned long lTimeL     = [self read: SLT_REG_ADDRESS(kSLTLastTriggerTimeStamp) + aPageIndex];
	int iPageStart = (((lTimeL >> 10) & 0x7fe)  + 20) % 2000;
	
	unsigned long timeStampH = [self read: SLT_REG_ADDRESS(kSLTPageTimeStamp) + 2*aPageIndex];
	unsigned long timeStampL = [self read: SLT_REG_ADDRESS(kSLTPageTimeStamp) + 2*aPageIndex+1];
	
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
	NSLogFont(aFont,@"Reading event from page %d, start=%d:  %ds %dx100us\n", 
			  aPageIndex+1, iPageStart, timeStampH, (timeStampL >> 11) & 0x3fff);
	
	//readout the SLT pixel trigger data
	unsigned long buffer[2000];
	unsigned long sltMemoryAddress = (SLTID << 24) | aPageIndex<<11;
	[self readBlock:sltMemoryAddress dataBuffer:(unsigned long*)buffer length:20*100 increment:1];
	unsigned long reorderBuffer[2000];
	// Re-organize trigger data to get it in a continous data stream
	unsigned long *pMult = reorderBuffer;
	memcpy( pMult, buffer + iPageStart, (2000 - iPageStart)*sizeof(unsigned long));  
	memcpy( pMult + 2000 - iPageStart, buffer, iPageStart*sizeof(unsigned long));  
	
	int i;
	int j;	
	int k;	
	
	// Dislay the matrix of triggered pixel and timing
	// The xy-Projection is needed to readout only the triggered pixel!!!
	unsigned long xyProj[20];
	unsigned long tyProj[100];
	for (i=0;i<20;i++) xyProj[i] = 0;
	for (k=0;k<100;k++) tyProj[k] = 0;
	for (k=0;k<2000;k++){
		xyProj[k%20] = xyProj[k%20] | (pMult[k] & 0x3fffff);
	}  
	for (k=0;k<2000;k++){
		if (xyProj[k%20]) {
			tyProj[k/20] = tyProj[k/20] | (pMult[k] & 0x3fffff);
		}
	}
	
	
	for(j=0;j<22;j++){
		NSMutableString* s = [NSMutableString stringWithFormat:@"%2d: ",j];
		//matrix of triggered pixel
		for(i=0;i<20;i++){
			if (((xyProj[i]>>j) & 0x1) == 0x1) [s appendFormat:@"X"];
			else							   [s appendFormat:@"."];
		}
		[s appendFormat:@"  "];
		
		// trigger timing
		for (k=0;k<100;k++){
			if (((tyProj[k]>>j) & 0x1) == 0x1 )[s appendFormat:@"="];
			else							   [s appendFormat:@"."];
		}
		NSLogFont(aFont, @"%@\n", s);
	}
	
	
	NSLogFont(aFont,@"\n");			
	
	
}
*/
- (void) autoCalibrate
{
	NSArray* allFLTs = [[self crate] orcaObjects];
	NSEnumerator* e = [allFLTs objectEnumerator];
	id aCard;
	while(aCard = [e nextObject]){
		if(![aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")]){
			[aCard autoCalibrate];
		}
	}
}


#pragma mark •••SBC_Linking protocol

- (NSString*) cpuName
{
	return [NSString stringWithFormat:@"SLT (Crate %d)",[self crateNumber]];
}

- (NSString*) sbcLockName
{
	return ORIpeV4SLTSettingsLock;
}

- (NSString*) sbcLocalCodePath
{
	return @"Source/Objects/Hardware/IPE/IpeV4 SLT/SLTv4_Readout_Code";
}

- (NSString*) codeResourcePath
{
	return [[self sbcLocalCodePath] lastPathComponent];
}


#pragma mark •••SBC I/O layer
- (unsigned long) read:(unsigned long) address
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	unsigned long theData;
	[pcmLink readLongBlockPbus:&theData
					  atAddress:address
					  numToRead: 1];
	return theData;
}

- (void) read:(unsigned long long) address data:(unsigned long*)theData size:(unsigned long)len
{ 
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pcmLink readLongBlockPbus:theData
					 atAddress:address
					 numToRead:len];
}

- (void) writeBitsAtAddress:(unsigned long)address 
					  value:(unsigned long)dataWord 
					   mask:(unsigned long)aMask 
					shifted:(int)shiftAmount
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	
	unsigned long buffer = [self  read:address];
	buffer =(buffer & ~(aMask<<shiftAmount) ) | (dataWord << shiftAmount);
	[self write:address value:buffer];
}

- (void) setBitsHighAtAddress:(unsigned long)address 
						 mask:(unsigned long)aMask
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	unsigned long buffer = [self  read:address];
	buffer = (buffer | aMask );
	[self write:address value:buffer];
}

- (void) readRegisterBlock:(unsigned long)  anAddress 
				dataBuffer:(unsigned long*) aDataBuffer
					length:(unsigned long)  length 
				 increment:(unsigned long)  incr
			   numberSlots:(unsigned long)  nSlots 
			 slotIncrement:(unsigned long)  incrSlots
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	
	int i,j;
	for(i=0;i<nSlots;i++) {
		for(j=0;j<length;j++) {
			aDataBuffer[i*length + j] = [self read:(anAddress + i*incrSlots + j*incr)]; // Slots start with id 1 !!!
		}
	}
}

- (void) readBlock:(unsigned long)  anAddress 
		dataBuffer:(unsigned long*) aDataBuffer
			length:(unsigned long)  length 
		 increment:(unsigned long)  incr
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	
	int i;
	for(i=0;i<length;i++) {
		aDataBuffer[i] = [self read:anAddress + i*incr];
	}
}

- (void) writeBlock:(unsigned long)  anAddress 
		 dataBuffer:(unsigned long*) aDataBuffer
			 length:(unsigned long)  length 
		  increment:(unsigned long)  incr
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	
	int i;
	for(i=0;i<length;i++) {
		[self write:anAddress + i*incr value:aDataBuffer[i]];
	}	
}

- (void) clearBlock:(unsigned long)  anAddress 
			pattern:(unsigned long) aPattern
			 length:(unsigned long)  length 
		  increment:(unsigned long)  incr
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	int i;
	for(i=0;i<length;i++) {
		[self write:anAddress + i*incr value:aPattern];
	}
}

#pragma mark •••SBC Data Structure Setup
- (void) load_HW_Config
{
	int index = 0;
	SBC_crate_config configStruct;
	
	configStruct.total_cards = 0;
	
	[self load_HW_Config_Structure:&configStruct index:index];
	
	[pcmLink load_HW_Config:&configStruct];
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kSLTv4;	//should be unique
	configStruct->card_info[index].hw_mask[0] 	= eventDataId;
	configStruct->card_info[index].hw_mask[1] 	= multiplicityId;
	configStruct->card_info[index].slot			= [self stationNumber];
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].add_mod		= 0;		//not needed for this HW
	
	//use the following as needed to define base addresses and special data for use by the cpu to 
	//do the readout
	//configStruct->card_info[index].base_add		= [self baseAddress];
	//configStruct->card_info[index].deviceSpecificData[0] = onlineMask;
	//configStruct->card_info[index].deviceSpecificData[1] = register_offsets[kConversionStatusRegister];
	//configStruct->card_info[index].deviceSpecificData[2] = register_offsets[kADC1OutputRegister];
	
	configStruct->card_info[index].num_Trigger_Indexes = 1;	//Just 1 group of objects controlled by SLT
    int nextIndex = index+1;
    
	configStruct->card_info[index].next_Trigger_Index[0] = -1;
	NSEnumerator* e = [dataTakers objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		if([obj respondsToSelector:@selector(load_HW_Config_Structure:index:)]){
			if(configStruct->card_info[index].next_Trigger_Index[0] == -1){
				configStruct->card_info[index].next_Trigger_Index[0] = nextIndex;
			}
			int savedIndex = nextIndex;
			nextIndex = [obj load_HW_Config_Structure:configStruct index:nextIndex];
			if(obj == [dataTakers lastObject]){
				configStruct->card_info[savedIndex].next_Card_Index = -1; //make the last object a leaf node
			}
		}
	}
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	return index+1;
}
@end

@implementation ORIpeV4SLTModel (private)
- (unsigned long) read:(unsigned long) address
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	unsigned long theData;
	[pcmLink readLongBlockPbus:&theData
					  atAddress:address
					  numToRead: 1];
	return theData;
}

- (void) write:(unsigned long) address value:(unsigned long) aValue
{
	if(![pcmLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pcmLink writeLongBlockPbus:&aValue
					  atAddress:address
					 numToWrite:1];
}
@end

