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
#import "Pbus_Link.h"
#import "SLTv4_HW_Definitions.h"

enum {
	kSLTControlReg,
	kSLTStatusReg,
	kSLTIRStatus,
	kSLTIRMask,
	kSLTIRVector,
	kSLTThresh_Wr,
	kSLTThresh_Rd,
	kSLTSwNextPage,
	kSLTSwSltTrigger,
	kSLTSwSetInhibit,
	kSLTSwRelInhibit,
	kSLTSwTestpulsTrigger,
	kSLTSwReadADC,
	kSLTSwSecondStrobe,
	kSLTConfSltFPGAs,
	kSLTConfFltFPGAs,
	kSLTActResetFlt,
	kSLTRelResetFlt,
	kSLTActResetSlt,
	kSLTRelResetSlt,
	kPageStatusLow,
	kPageStatusHigh,
	kSLTActualPage,
	kSLTNextPage,
	kSLTSetPageFree,
	kSLTSetPageNoUse,
	kSLTTimingMemory,
	kSLTTestpulsAmpl,
	kSLTTestpulsStartSec,
	kSLTTestpulsStartSubSec,
	kSLTSetSecCounter,
	kSLTSecCounter,
	kSLTSubSecCounter,
	kSLTT1,
	kSLTIRInput,
	kSLTVersion,
	kSLTVetoTimeLow,
	kSLTVetoTimeHigh,
	kSLTDeadTimeLow,
	kSLTDeadTimeHigh,
	kSLTResetDeadTime,
	kSLTSensorMask,
	kSLTSensorStatus,
	kSLTPageTimeStamp,
	kSLTLastTriggerTimeStamp,
	kSLTTestpulsTiming,
	kSLTSensorData,
	kSLTSensorConfig,
	kSLTSensorUpperThresh,
	kSLTSensorLowerThresh,
	kSLTWatchDogMask,
	kSLTWatchDogStatus,
	kSLTNumRegs //must be last
};

static IpeRegisterNamesStruct reg[kSLTNumRegs] = {
{@"Control",			0x0f00,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"Status",				0x0f02,		-1,				kIpeRegReadable},
{@"IRStatus",			0x0f04,		-1,				kIpeRegReadable},
{@"IRMask",				0x0f05,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"IRVector",			0x0f06,		-1,				kIpeRegReadable},
{@"Thresh_Wr",			0x0f0d,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"Thresh_Rd",			0x0f0e,		-1,				kIpeRegReadable},
{@"SwNextPage",			0x0f10,		-1,				kIpeRegWriteable},
{@"SwSltTrigger",		0x0f12,		-1,				kIpeRegWriteable},
{@"SwSetInhibit",		0x0f13,		-1,				kIpeRegWriteable},
{@"SwRelInhibit",		0x0f14,		-1,				kIpeRegWriteable},
{@"SwTestpulsTrigger",	0x0f20,		-1,				kIpeRegWriteable},
{@"SwReadADC",			0x0f40,		-1,				kIpeRegWriteable},
{@"SwSecondStrobe",		0x0f50,		-1,				kIpeRegWriteable},
{@"ConfSltFPGAs",		0x0f51,		-1,				kIpeRegWriteable},
{@"ConfFltFPGAs",		0x0f61,		-1,				kIpeRegWriteable},
{@"ActResetFlt",		0x0f80,		-1,				kIpeRegWriteable},
{@"RelResetFlt",		0x0f81,		-1,				kIpeRegWriteable},
{@"ActResetSlt",		0x0f90,		-1,				kIpeRegWriteable},
{@"RelResetSlt",		0x0f91,		-1,				kIpeRegWriteable},
{@"PageStatusLow",		0x0100,		-1,				kIpeRegReadable},
{@"PageStatusHigh",		0x0101,		-1,				kIpeRegReadable},
{@"ActualPage",			0x0102,		-1,				kIpeRegReadable},
{@"NextPage",			0x0103,		-1,				kIpeRegReadable},
{@"SetPageFree",		0x0105,		-1,				kIpeRegWriteable},
{@"SetPageNoUse",		0x0106,		-1,				kIpeRegWriteable},
{@"TimingMemory",		0x0200,		0xff,			kIpeRegReadable | kIpeRegWriteable},
{@"TestpulsAmpl",		0x0300,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"TestpulsStartSec",	0x0301,		-1,				kIpeRegReadable},
{@"TestpulsStartSubSec",0x0302,		-1,				kIpeRegReadable},
{@"SetSecCounter",		0x0500,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"SecCounter",			0x0501,		-1,				kIpeRegReadable},
{@"SubSecCounter",		0x0502,		-1,				kIpeRegReadable},
{@"T1",					0x0503,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"IRInput",			0x0f07,		-1,				kIpeRegReadable},
{@"SltVersion",			0x0f08,		-1,				kIpeRegReadable},
{@"VetoTimeLow",		0x0f0a,		-1,				kIpeRegReadable},
{@"VetoTimeHigh",		0x0f09,		-1,				kIpeRegReadable},
{@"DeadTimeLow",		0x0f0c,		-1,				kIpeRegReadable},
{@"DeadTimeHigh",		0x0f0b,		-1,				kIpeRegReadable},
{@"ResetDeadTime",		0x0f11,		-1,				kIpeRegReadable},
{@"SensorMask",			0x0f20,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"SensorStatus",		0x0f21,		-1,				kIpeRegReadable},
{@"PageTimeStamp",		0x0000,		-1,				kIpeRegReadable},
{@"LastTriggerTimeStamp",0x0080,	-1,				kIpeRegReadable},
{@"TestpulsTiming",		0x0200,		256,			kIpeRegReadable | kIpeRegWriteable},
{@"SensorData",			0x0400,		8,				kIpeRegReadable},
{@"SensorConfig",		0x0408,		8,				kIpeRegReadable},
{@"SensorUpperThresh",	0x0410,		8,				kIpeRegReadable},
{@"SensorLowerThresh",	0x0418,		8,				kIpeRegReadable},
{@"WatchDogMask",		0x0420,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"WatchDogStatus",		0x0421,		-1,				kIpeRegReadable},
};

#define SLTID 21
#define SLT_REG_ADDRESS(A) ((SLTID << 24) + ((0x1) << 18) + reg[(A)].addressOffset)

//status reg bit positions
#define SLT_CRATEID				22
#define SLT_SLOTID				27
#define SLT_VETO				20
#define SLT_EXTINHIBIT			19

#define SLT_NOPGINHIBIT			18
#define SLT_SWINHIBIT			17
#define SLT_INHIBIT				16

//control reg defs
#define SLT_TRIGGER_LOW       0
#define SLT_TRIGGER_MASK   0x1f

#define SLT_INHIBIT_LOW       5
#define SLT_INHIBIT_MASK   0x07

#define SLT_TESTPULS_LOW      8
#define SLT_TESTPULS_MASK  0x03

#define SLT_SECSTROBE_LOW    10
#define SLT_SECSTROBE_MASK 0x01

#define SLT_WATCHDOGSTART_LOW      11
#define SLT_WATCHDOGSTART_MASK   0x03

#define SLT_DEADTIMECOUNTERS      13
#define SLT_DEADTIMECOUNTERS_MASK   0x01

#define SLT_LOWERLED      14
#define SLT_LOWERLED_MASK   0x01

#define SLT_UPPERLED      15
#define SLT_UPPERLED_MASK   0x01

#define SLT_NHIT					0
#define SLT_NHIT_MASK			 0xff

#define SLT_NHIT_THRESHOLD			8
#define SLT_NHIT_THRESHOLD_MASK  0x7f


//IPE V4 electronic definitions

enum IpeV4Enum{
	kSLTV4ControlReg,
	kSLTV4StatusReg,
	kSLTV4CommandReg,
	kSLTV4HWRevision,
	kSLTV4SecondSet,
	kSLTV4SecondCounter,
	kSLTV4SubSecondCounter,
	kSLTV4NumRegs //must be last
};

static IpeRegisterNamesStruct regV4[kSLTV4NumRegs] = {
//2nd column is PCI register address shifted 2 bits to right (the two rightmost bits are always zero) -tb-
{@"Control",			0xa80000>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"Status",				0xa80004>>2,		-1,				kIpeRegReadable},
{@"Command",			0xa80008>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"HWRevision",			0xa80020>>2,		-1,				kIpeRegReadable},
{@"SecondSet",          0xb00000>>2,		-1,				kIpeRegWriteable},
{@"SecondCounter",      0xb00004>>2,		-1,				kIpeRegReadable},
{@"SubSecondCounter",   0xb00008>>2,		-1,				kIpeRegReadable},
};



#pragma mark ***External Strings
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

NSString* ORIpeV4SLTIpeCrateVersionChanged			= @"ORIpeV4SLTIpeCrateVersionChanged";

@implementation ORIpeV4SLTModel


- (id) init
{
    self = [super init];
	ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];	
	[self setReadOutGroup:readList];
    [self makePoller:0];
	[readList release];
    IpeCrateVersion=4;//the default -tb-
	pbusLink = [[Pbus_Link alloc] initWithDelegate:self]; //mah -- Jun 06,2009 link wasn't made in this path of creation
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
	[pbusLink wakeUp];
    [super wakeUp];
    if(![gOrcaGlobals runInProgress]){
        [poller runWithTarget:self selector:@selector(readAllStatus)];
    }
}

- (void) sleep
{
    [super sleep];
	[pbusLink sleep];
    [poller stop];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		if(!pbusLink){
			pbusLink = [[Pbus_Link alloc] initWithDelegate:self];
		}
		[pbusLink connect];
	}
	@catch(NSException* localException) {
	}
}


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"IpeV4SLTCard"]];
}


- (void) makeMainController
{
    [self linkToController:@"ORIpeV4SLTController"];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORIpeV4CrateModel");
}

- (void) setGuardian:(id)aGuardian //-tb-
{
	if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:self];			
		}
		//[self findInterface];
	}
	else {
		//[self setFireWireInterface:nil];
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

- (id) controllerCard
{
	return self;
}

- (SBC_Link*)sbcLink
{
	return pbusLink;
}

- (TimedWorker *) poller
{
    return poller; 
}

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
		[self setSwInhibit];
	}
	
	// TODO: Save dead time counters ?!
	// Is it sensible to send a new package here?
	// ak 18.7.07
	
	NSLog(@"Deadtime: %lld\n", [self readDeadTime]);
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
			[self writeControlReg];
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
    if(IpeCrateVersion==4) return kSLTV4NumRegs; 
    else //IpeCrateVersion==3
		return kSLTNumRegs; 
}

- (NSString*) getRegisterName: (short) anIndex
{
    if(IpeCrateVersion==4) return regV4[anIndex].regName;
    else // V3
		return reg[anIndex].regName;
}

- (unsigned long) getAddressOffset: (short) anIndex
{
    if(IpeCrateVersion==4)  return( regV4[anIndex].addressOffset );
    return( reg[anIndex].addressOffset );
}

- (short) getAccessType: (short) anIndex
{
    if(IpeCrateVersion==4)  return regV4[anIndex].accessType;
	return reg[anIndex].accessType;
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

- (int) IpeCrateVersion
{
    return IpeCrateVersion;
}

- (int) setIpeCrateVersion:(int) aValue
{
    IpeCrateVersion = aValue;
    //NSLog(@"setIpeCrateVersion: %i\n",aValue);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTIpeCrateVersionChanged object:self];
    return IpeCrateVersion;
}

#pragma mark ***HW Access
- (void) checkPresence
{
	@try {
		[self readStatusReg];
		[self setPresent:YES];
	}
	@catch(NSException* localException) {
		[self setPresent:NO];
	}
}

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

- (void) writeReg:(unsigned short)index value:(unsigned long)aValue
{
    if(IpeCrateVersion==4){
	    [self write: regV4[index].addressOffset value:aValue];
    }else{
    	[self write: SLT_REG_ADDRESS(index) value:aValue];
    }
}

- (unsigned long) readReg:(unsigned short) index
{
    if(IpeCrateVersion==4){
        return [self read: regV4[index].addressOffset];
    }else{
        return [self read: SLT_REG_ADDRESS(index)];
    }
}

- (void) readAllStatus
{
	[self readPageStatus];
	[self readStatusReg];
}

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

- (void) printStatusReg
{
	[self readStatusReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Status Register SLT (%d) ----\n",[self stationNumber]);
	NSLogFont(aFont,@"Veto             : %d\n",veto);
	NSLogFont(aFont,@"ExtInhibit       : %d\n",extInhibit);
	NSLogFont(aFont,@"NopgInhibit      : %d\n",nopgInhibit);
	NSLogFont(aFont,@"SwInhibit        : %d\n",swInhibit);
	NSLogFont(aFont,@"Inhibit          : %d\n",inhibit);
}

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

- (float) readVersion
{
	if(IpeCrateVersion==3){
        [self setFpgaVersion: [self readReg:kSLTVersion]/10.];
        NSLog(@"IPE-DAQ interface version %@ (build %s %s, fpga version %f)\n", ORIPE_VERSION, __DATE__, __TIME__, fpgaVersion);	
    }
    
    //pbusPCI interface test -tb- 2008-09-04 BEGIN	
    if(IpeCrateVersion==4){
        NSLog(@"V4: IPE-V4-SLT ; crate is %p\n",  [self crate]);	
        unsigned long value = 23;
        unsigned long address;
        //address = 0xfd000000 + 0xa80020; NO! omit offset  -tb-
        address =  0xa80020;
        [self write: address value: value];	// a test for PbusSim -tb-				  
        value = [self read: address];					  
        NSLog(@"V4: IPE-V4-SLT HW revision 0x%08x = %i (from register address 0x%x)\n", value,value,address);	
        [self setFpgaVersion: (((double)value)/10.)];
    }
    //pbusPCI interface test -tb- 2008-09-04 END						  
	return fpgaVersion;
}

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

- (void) initBoard
{
	
	//-----------------------------------------------
	//board doesn't appear to start without this stuff
	[self writeReg:kSLTActResetFlt value:0];
	[self writeReg:kSLTActResetSlt value:0];
	usleep(10);
	[self writeReg:kSLTRelResetFlt value:0];
	[self writeReg:kSLTRelResetSlt value:0];
	[self writeReg:kSLTSwSltTrigger value:0];
	[self writeReg:kSLTSwSetInhibit value:0];
	
	usleep(100);
	
	int savedTriggerSource = triggerSource;
	int savedInhibitSource = inhibitSource;
	triggerSource = 0x1; //sw trigger only
	inhibitSource = 0x3; 
	[self writeControlReg];
	[self releaseAllPages];
	unsigned long long p1 = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	[self writeReg:kSLTSwRelInhibit value:0];
	int i = 0;
	unsigned long lTmp;
    do {
		lTmp = [self readReg:kSLTStatusReg];
		//NSLog(@"waiting for inhibit %x i=%d\n", lTmp, i);
		usleep(10);
		i++;
    } while(((lTmp & 0x10000) != 0) && (i<10000));
	
    if (i>= 10000){
		NSLog(@"Release inhibit failed\n");
		[NSException raise:@"SLT error" format:@"Release inhibit failed"];
	}
	
	unsigned long long p2  = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	if(p1 == p2) NSLog (@"No software trigger\n");
	[self writeReg:kSLTSwSetInhibit value:0];
	triggerSource = savedTriggerSource;
	inhibitSource = savedInhibitSource;
	//-----------------------------------------------
	
	[self writeControlReg];
	[self writeInterruptMask];
	[self writeNextPageDelay];
	[self readControlReg];	
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
	[self writeReg:kSLTConfFltFPGAs value:0];
	[ORTimer delay:1.5];
	[self writeReg:kSLTConfSltFPGAs value:0];
	[ORTimer delay:1.5];
	[self readReg:kSLTStatusReg];
	
	[guardian checkCards];
	
}

- (void) hw_reset
{
	NSLog(@"SLT: HW Reset\n");
	[self writeReg:kSLTSwRelInhibit value:0];
	[self writeReg:kSLTActResetFlt value:0];
	[self writeReg:kSLTActResetSlt value:0];
	usleep(10);
	[self writeReg:kSLTRelResetFlt value:0];
	[self writeReg:kSLTRelResetSlt value:0];
	[self writeReg:kSLTSwSltTrigger value:0];
	[self writeReg:kSLTSwSetInhibit value:0];				
}

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

- (void) setCrateNumber:(unsigned int)aNumber
{
	[guardian setCrateNumber:aNumber];
}


#pragma mark ***Archival

- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	pbusLink = [[decoder decodeObjectForKey:@"Pbus_Link"] retain];
	if(!pbusLink){
		pbusLink = [[Pbus_Link alloc] initWithDelegate:self];
	}
	else [pbusLink setDelegate:self];
	
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
    
    //V3/V4 handling
    [self setIpeCrateVersion:		[decoder decodeIntForKey:@"ORIpeCrateVersion"]];
    if(IpeCrateVersion==0) IpeCrateVersion=4; //not saved, set the default -tb-
	
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
	
	[encoder encodeObject:pbusLink		forKey:@"Pbus_Link"];
	
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
	
    //V3/V4 handling
    [encoder encodeInt:IpeCrateVersion  forKey:@"ORIpeCrateVersion"];
	
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
	
	[self setSwInhibit];
	
    if([[userInfo objectForKey:@"doinit"]intValue]){
		[self initBoard];					
	}	
	
	dataTakers = [[readOutGroup allObjects] retain];		//cache of data takers.
	
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
	
	[self readStatusReg];
	actualPageIndex = 0;
	eventCounter    = 0;
	first = YES;
	lastDisplaySec = 0;
	lastDisplayCounter = 0;
	lastDisplayRate = 0;
	lastSimSec = 0;
	
	//load all the data needed for the eCPU to do the HW read-out.
	[self load_HW_Config];
	[pbusLink runTaskStarted:aDataPacket userInfo:userInfo];
	
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	if(!first){
		//event readout controlled by the SLT cpu now. ORCA reads out 
		//the resulting data from a generic circular buffer in the pbusLink code.
		[pbusLink takeData:aDataPacket userInfo:userInfo];
	}
	else {
		[self releaseAllPages];
		[self releaseSwInhibit];
		[self writeReg:kSLTResetDeadTime value:0];
		first = NO;
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[self setSwInhibit];
	
	[pbusLink runTaskStopped:aDataPacket userInfo:userInfo];
	
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
	return @"Source/Objects/Hardware/IPE/IpeV4SLT/SLTv4_Readout_Code";
}

- (NSString*) codeResourcePath
{
	return [[self sbcLocalCodePath] lastPathComponent];
}


#pragma mark •••SBC I/O layer
- (unsigned long) read:(unsigned long) address
{
	if(![pbusLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	unsigned long theData;
	[pbusLink readLongBlockPbus:&theData
					  atAddress:address
					  numToRead: 1];
	return theData;
}

- (void) read:(unsigned long long) address data:(unsigned long*)theData size:(unsigned long)len;
{ 
	if(![pbusLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pbusLink readLongBlockPbus:theData
					  atAddress:address
					  numToRead:len];
}


- (void) write:(unsigned long) address value:(unsigned long) aValue
{
	if(![pbusLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pbusLink writeLongBlockPbus:&aValue
					   atAddress:address
					  numToWrite:1];
}

- (void) writeBitsAtAddress:(unsigned long)address 
					  value:(unsigned long)dataWord 
					   mask:(unsigned long)aMask 
					shifted:(int)shiftAmount
{
	if(![pbusLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	
	unsigned long buffer = [self  read:address];
	buffer =(buffer & ~(aMask<<shiftAmount) ) | (dataWord << shiftAmount);
	[self write:address value:buffer];
}

- (void) setBitsHighAtAddress:(unsigned long)address 
						 mask:(unsigned long)aMask
{
	if(![pbusLink isConnected]){
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
	if(![pbusLink isConnected]){
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
	if(![pbusLink isConnected]){
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
	if(![pbusLink isConnected]){
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
	if(![pbusLink isConnected]){
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
	
	[pbusLink load_HW_Config:&configStruct];
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
