/*
 *  ORMTCModel.cpp
 *  Orca
 *
 *  Created by Mark Howe on Fri, May 2, 2008
 *  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
 *
 */
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

#pragma mark •••Imported Files
#import "ORMTCModel.h"
#import "ORVmeCrateModel.h"
#import "ORMTC_Constants.h"
#import "NSDictionary+Extensions.h"
#import "SNOCmds.h"
#import "ORSelectorSequence.h"
#import "ORRunModel.h"
#import "ORRunController.h"

#define uShortDBValue(A) [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex: A]] unsignedShortValue]
#define uLongDBValue(A)  [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex: A]] unsignedLongValue]
#define floatDBValue(A)  [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex: A]] floatValue]

#pragma mark •••Definitions
NSString* ORMTCModelESumViewTypeChanged		= @"ORMTCModelESumViewTypeChanged";
NSString* ORMTCModelNHitViewTypeChanged		= @"ORMTCModelNHitViewTypeChanged";
NSString* ORMTCModelDefaultFileChanged		= @"ORMTCModelDefaultFileChanged";
NSString* ORMTCModelLastFileChanged			= @"ORMTCModelLastFileChanged";
NSString* ORMTCModelLastFileChangedLoaded	= @"ORMTCModelLastFileLoadedChanged";
NSString* ORMTCModelBasicOpsRunningChanged	= @"ORMTCModelBasicOpsRunningChanged";
NSString* ORMTCModelAutoIncrementChanged	= @"ORMTCModelAutoIncrementChanged";
NSString* ORMTCModelUseMemoryChanged		= @"ORMTCModelUseMemoryChanged";
NSString* ORMTCModelRepeatDelayChanged		= @"ORMTCModelRepeatDelayChanged";
NSString* ORMTCModelRepeatCountChanged		= @"ORMTCModelRepeatCountChanged";
NSString* ORMTCModelWriteValueChanged		= @"ORMTCModelWriteValueChanged";
NSString* ORMTCModelMemoryOffsetChanged		= @"ORMTCModelMemoryOffsetChanged";
NSString* ORMTCModelSelectedRegisterChanged	= @"ORMTCModelSelectedRegisterChanged";
NSString* ORMTCModelXilinxPathChanged		= @"ORMTCModelXilinxPathChanged";
NSString* ORMTCModelMtcDataBaseChanged		= @"ORMTCModelMtcDataBaseChanged";
NSString* ORMTCModelLastFileLoadedChanged	= @"ORMTCModelLastFileLoadedChanged";
NSString* ORMTCModelIsPulserFixedRateChanged	= @"ORMTCModelIsPulserFixedRateChanged";
NSString* ORMTCModelFixedPulserRateCountChanged = @"ORMTCModelFixedPulserRateCountChanged";
NSString* ORMTCModelFixedPulserRateDelayChanged = @"ORMTCModelFixedPulserRateDelayChanged";
NSString* ORMtcTriggerNameChanged		= @"ORMtcTriggerNameChanged";
NSString* ORMTCBasicLock				= @"ORMTCBasicLock";
NSString* ORMTCStandardOpsLock				= @"ORMTCStandardOpsLock";
NSString* ORMTCSettingsLock				= @"ORMTCSettingsLock";
NSString* ORMTCTriggersLock				= @"ORMTCTriggersLock";
NSString* ORMTCModelMTCAMaskChanged = @"ORMTCModelMTCAMaskChanged";
NSString* ORMTCModelIsPedestalEnabledInCSR = @"ORMTCModelIsPedestalEnabledInCSR";

#define kMTCRegAddressBase		0x00007000
#define kMTCRegAddressModifier	0x29
#define kMTCRegAddressSpace		0x01
#define kMTCMemAddressBase		0x03800000
#define kMTCMemAddressModifier	0x09
#define kMTCMemAddressSpace		0x02

static SnoMtcNamesStruct reg[kMtcNumRegisters] = {
{ @"ControlReg"	    , 0   ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //0
{ @"SerialReg"		, 4   ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //1
{ @"DacCntReg"		, 8   ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //2
{ @"SoftGtReg"		, 12  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //3
{ @"Pedestal Width"	, 16  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //4
{ @"Coarse Delay"	, 20  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //5
{ @"Fine Delay"		, 24  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //6
{ @"ThresModReg"	, 28  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //7
{ @"PmskReg"		, 32  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //8
{ @"ScaleReg"		, 36  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //9
{ @"BwrAddOutReg"	, 40  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //10
{ @"BbaReg"		, 44  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //11
{ @"GtLockReg"		, 48  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //12
{ @"MaskReg"		, 52  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //13
{ @"XilProgReg"		, 56  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //14
{ @"GmskReg"		, 60  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //15
{ @"OcGtReg"		, 128 ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //16
{ @"C50_0_31Reg"	, 132 ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //17
{ @"C50_32_42Reg"	, 136  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //18
{ @"C10_0_31Reg"	, 140 ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //19
{ @"C10_32_52Reg"	, 144 ,kMTCRegAddressModifier, kMTCRegAddressSpace }	//20
};

static SnoMtcDBInfoStruct dbLookUpTable[kDbLookUpTableSize] = {
{ @"MTC/D,LockOutWidth",	   	@"420" },   //0
{ @"MTC/D,PedestalWidth",		@"52" },   //1
{ @"MTC/D,Nhit100LoPrescale",	@"1" },   //2
{ @"MTC/D,PulserPeriod",		@"10.0" },   //3
{ @"MTC/D,Low10MhzClock",		@"0" },   //4
{ @"MTC/D,High10MhzClock",		@"0" },   //5
{ @"MTC/D,FineSlope",			@"0.0" },   //6
{ @"MTC/D,MinDelayOffset",		@"18.0" },   //7
{ @"MTC/D,CoarseDelay",			@"60" },   //8
{ @"MTC/D,FineDelay",			@"0" },   //9
{ @"MTC/D,GtMask",				@"0" }, //10
{ @"MTC/D,GtCrateMask",			@"0" },	//11
{ @"MTC/D,PEDCrateMask",		@"0" },	//12
{ @"MTC/D,ControlMask",			@"0" },		//13

//defaults for the MTC A NHit
{ @"MTC/A,NHit100Hi,Threshold",	@"1"},		//14
{ @"MTC/A,NHit100Med,Threshold",@"2"},		//15
{ @"MTC/A,NHit100Lo,Threshold",	@"3"},		//16
{ @"MTC/A,NHit20,Threshold",	@"4"},		//17
{ @"MTC/A,NHit20LB,Threshold",	@"5"},		//18
{ @"MTC/A,OWLN,Threshold",		@"6"},		//19

{ @"MTC/A,NHit100Hi,mV/Adc",	@"10"},		//20
{ @"MTC/A,NHit100Med,m/VAdc",	@"20"},		//21
{ @"MTC/A,NHit100Lo,mV/Adc",	@"30"},		//22
{ @"MTC/A,NHit20,mV/Adc",		@"40"},		//23
{ @"MTC/A,NHit20LB,mV/Adc",		@"50"},		//24
{ @"MTC/A,OWLN,mV/Adc",			@"60"},		//25

{ @"MTC/A,NHit100Hi,mV/Hit",	@"10"},		//26
{ @"MTC/A,NHit100Med,mV/Hit",	@"20"},		//27
{ @"MTC/A,NHit100Lo,mV/Hit",	@"30"},		//28
{ @"MTC/A,NHit20,mV/Hit",		@"40"},		//29
{ @"MTC/A,NHit20LB,mV/Hit",		@"50"},		//30
{ @"MTC/A,OWLN,mV/Hit",			@"60"},		//31

{ @"MTC/A,NHit100Hi,dcOffset",	@"10"},		//32
{ @"MTC/A,NHit100Med,dcOffset",	@"20"},		//33
{ @"MTC/A,NHit100Lo,dcOffset",	@"30"},		//34
{ @"MTC/A,NHit20,dcOffset",		@"40"},		//35
{ @"MTC/A,NHit20LB,dcOffset",	@"50"},		//36
{ @"MTC/A,OWLN,dcOffset",		@"60"},		//37

//defaults for the MTC A ESUM
{ @"MTC/A,ESumLow,Threshold",	@"10"},		//38
{ @"MTC/A,ESumHi,Threshold",	@"20"},		//39
{ @"MTC/A,OWLELo,Threshold",	@"30"},		//40
{ @"MTC/A,OWLEHi,Threshold",	@"40"},		//41

{ @"MTC/A,ESumLow,mV/Adc",		@"10"},		//42
{ @"MTC/A,ESumHi,mV/Adc",		@"20"},		//43
{ @"MTC/A,OWLELo,mV/Adc",		@"30"},		//44
{ @"MTC/A,OWLEHi,mV/Adc",		@"40"},		//45

{ @"MTC/A,ESumLow,mV/pC",		@"10"},		//46
{ @"MTC/A,ESumHi,mV/pC",		@"20"},		//47
{ @"MTC/A,OWLELo,mV/pC",		@"30"},		//48
{ @"MTC/A,OWLEHi,mV/pC",		@"40"},		//49

{ @"MTC/A,ESumLow,dcOffset",	@"10"},		//50
{ @"MTC/A,ESumHi,dcOffset",		@"20"},		//51
{ @"MTC/A,OWLELo,dcOffset",		@"30"},		//52
{ @"MTC/A,OWLEHi,dcOffset",		@"40"},		//53

{ @"MTC,tub",					@"40"},		//54

{@"Comments",					@"Nothing Noted"},		//55
{@"XilinxFilePath",				@"--"},		//56

};

int mtcDacIndexes[14]=
{
kNHit100HiThreshold,	
kNHit100MedThreshold,
kNHit100LoThreshold,	
kNHit20Threshold,	
kNHit20LBThreshold,	
kOWLNThreshold,		
kESumLowThreshold,	
kESumHiThreshold,	
kOWLELoThreshold,	
kOWLEHiThreshold,
kControlMask,
kGtMask,
kGtCrateMask,
kPEDCrateMask
};

@interface ORMTCModel (private)
- (void) doBasicOp;
- (void) setupDefaults;
@end

@implementation ORMTCModel

@synthesize
dataId = _dataId,
mtcStatusDataId = _mtcStatusDataId,
mtcStatusGTID = _mtcStatusGTID,
mtcStatusGTIDRate = _mtcStatusGTIDRate,
mtcStatusCnt10MHz = _mtcStatusCnt10MHz,
mtcStatusTime10Mhz = _mtcStatusTime10Mhz,
mtcStatusReadPtr = _mtcStatusReadPtr,
mtcStatusWritePtr = _mtcStatusWritePtr,
mtcStatusDataAvailable = _mtcStatusDataAvailable,
mtcStatusNumEventsInMem = _mtcStatusNumEventsInMem,
resetFifoOnStart = _resetFifoOnStart;

/* #define these variables for now. Eventually we need to add fields
 * to the GUI, but Javi is working on the SNOPModel now */
#define MTC_HOST @"sbc.sp.snolab.ca"
#define MTC_PORT 4001


- (id) init //designated initializer
{
    self = [super init];

    [self registerNotificationObservers];

    /* initialize our connection to the MTC server */
    mtc = [[RedisClient alloc] initWithHostName:MTC_HOST withPort:MTC_PORT];
	
    [[self undoManager] disableUndoRegistration];
    
    [[self undoManager] enableUndoRegistration];
	[self setFixedPulserRateCount: 1];
	[self setFixedPulserRateDelay: 10];
    return self;
}

- (void) dealloc
{
    [mtc release];
    [defaultFile release];
    [lastFile release];
    [lastFileLoaded release];
    [mtcDataBase release];
    [_mtcStatusTime10Mhz release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"MTCCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORMTCController"];
}


- (void) wakeUp
{
    if(![self aWake]){
    }
    [super wakeUp];
}

- (BOOL) solitaryObject
{
    return YES;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStart:)
                         name : @"SNOPRunStart"
                       object : nil];
}

- (void) runAboutToStart:(NSNotification*)aNote
{
    /* At the start of every run, we initialize the HW settings. */

    /* Setup MTCD pedestal/pulser settings */
    if ([self isPedestalEnabledInCSR]) [self enablePedestal];
    [self setupPulseGTDelaysCoarse: uLongDBValue(kCoarseDelay) fine:uLongDBValue(kFineDelay)];
    [self setTheLockoutWidth: uLongDBValue(kLockOutWidth)];
    [self setThePedestalWidth: uLongDBValue(kPedestalWidth)];
    [self setThePulserRate:floatDBValue(kPulserPeriod)];
    [self setThePrescaleValue];

    /* Setup Pedestal Crate Mask */
	[self setPedestalCrateMask];

    /* Setup the GT mask */
    [self clearGlobalTriggerWordMask];
    [self setSingleGTWordMask: uLongDBValue(kGtMask)];

    /* Setup GT Crate Mask */
    [self setGTCrateMask];

    /* Setup MTCA Thresholds */
    [self loadTheMTCADacs];

    /* Setup MTCA relays */
    [self mtcatLoadCrateMasks];
}

#pragma mark •••Accessors

- (unsigned short) addressModifier
{
	return 0x29;
}

- (int) eSumViewType
{
    return eSumViewType;
}

- (void) setESumViewType:(int)aESumViewType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setESumViewType:eSumViewType];
    
    eSumViewType = aESumViewType;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelESumViewTypeChanged object:self];
}

- (int) nHitViewType
{
    return nHitViewType;
}

- (void) setNHitViewType:(int)aNHitViewType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNHitViewType:nHitViewType];
    
    nHitViewType = aNHitViewType;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelNHitViewTypeChanged object:self];
}

- (NSString*) xilinxFilePath
{
    return [self dbObjectByIndex:kXilinxFile];
}

- (void) setXilinxFilePath:(NSString*)aDefaultFile
{
 	if(!aDefaultFile)aDefaultFile = @"--";
	[self setDbObject:aDefaultFile forIndex:kXilinxFile];
}

- (NSString*) defaultFile
{
    return defaultFile;
}

- (void) setDefaultFile:(NSString*)aDefaultFile
{
 	if(!aDefaultFile)aDefaultFile = @"--";
    [[[self undoManager] prepareWithInvocationTarget:self] setDefaultFile:defaultFile];
	
    [defaultFile autorelease];
    defaultFile = [aDefaultFile copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelDefaultFileChanged object:self];
}

- (NSString*) lastFile
{
    return lastFile;
}

- (void) setLastFile:(NSString*)aLastFile
{
    [lastFile autorelease];
    lastFile = [aLastFile copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelLastFileChanged object:self];
}

- (NSString*) lastFileLoaded
{
    return lastFileLoaded;
}

- (void) setLastFileLoaded:(NSString*)aFile
{
	if(!aFile)aFile = @"--";
    [lastFileLoaded autorelease];
    lastFileLoaded = [aFile copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelLastFileLoadedChanged object:self];
}


- (BOOL) basicOpsRunning
{
    return basicOpsRunning;
}

- (void) setBasicOpsRunning:(BOOL)aBasicOpsRunning
{
    basicOpsRunning = aBasicOpsRunning;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelBasicOpsRunningChanged object:self];
}

- (BOOL) autoIncrement
{
    return autoIncrement;
}

- (void) setAutoIncrement:(BOOL)aAutoIncrement
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoIncrement:autoIncrement];
    
    autoIncrement = aAutoIncrement;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelAutoIncrementChanged object:self];
}

- (int) useMemory
{
    return useMemory;
}

- (void) setUseMemory:(int)aUseMemory
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseMemory:useMemory];
    
    useMemory = aUseMemory;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelUseMemoryChanged object:self];
}

- (unsigned short) repeatDelay
{
    return repeatDelay;
}

- (void) setRepeatDelay:(unsigned short)aRepeatDelay
{
	if(aRepeatDelay<=0)aRepeatDelay = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatDelay:repeatDelay];
    
    repeatDelay = aRepeatDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelRepeatDelayChanged object:self];
}

- (short) repeatOpCount
{
    return repeatOpCount;
}

- (void) setRepeatOpCount:(short)aRepeatCount
{
	if(aRepeatCount<=0)aRepeatCount = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatOpCount:repeatOpCount];
    
    repeatOpCount = aRepeatCount;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelRepeatCountChanged object:self];
}

- (unsigned long) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(unsigned long)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:writeValue];
    
    writeValue = aWriteValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelWriteValueChanged object:self];
}

- (unsigned long) memoryOffset
{
    return memoryOffset;
}

- (void) setMemoryOffset:(unsigned long)aMemoryOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMemoryOffset:memoryOffset];
    
    memoryOffset = aMemoryOffset;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMemoryOffsetChanged object:self];
}

- (int) selectedRegister
{
    return selectedRegister;
}

- (void) setSelectedRegister:(int)aSelectedRegister
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegister:selectedRegister];
    
    selectedRegister = aSelectedRegister;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelSelectedRegisterChanged object:self];
}

- (NSMutableDictionary*) mtcDataBase
{
    return mtcDataBase;
}

- (void) setMtcDataBase:(NSMutableDictionary*)aNestedDictionary
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMtcDataBase:mtcDataBase];
	
    [aNestedDictionary retain];
    [mtcDataBase release];
    mtcDataBase = aNestedDictionary;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMtcDataBaseChanged object:self];
	
}

- (BOOL) isPulserFixedRate
{
	return isPulserFixedRate;
}

- (void) setIsPulserFixedRate:(BOOL) aIsPulserFixedRate
{
	[[[self undoManager] prepareWithInvocationTarget:self] setIsPulserFixedRate:isPulserFixedRate];
	
	isPulserFixedRate = aIsPulserFixedRate;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelIsPulserFixedRateChanged object:self];
	
}

- (unsigned long) fixedPulserRateCount
{
	return fixedPulserRateCount;
}

- (void) setFixedPulserRateCount:(unsigned long) aFixedPulserRateCount
{
	[[[self undoManager] prepareWithInvocationTarget:self] setFixedPulserRateCount:aFixedPulserRateCount];

	fixedPulserRateCount = aFixedPulserRateCount;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelFixedPulserRateCountChanged object:self];	
}

- (float) fixedPulserRateDelay
{
	return fixedPulserRateDelay;
}

- (void) setFixedPulserRateDelay:(float) aFixedPulserRateDelay
{
	[[[self undoManager] prepareWithInvocationTarget:self] setFixedPulserRateDelay:aFixedPulserRateDelay];
	
	fixedPulserRateDelay = aFixedPulserRateDelay;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelFixedPulserRateDelayChanged object:self];
}

//hardcoded base addresses (unlikely to ever change)
- (unsigned long) memBaseAddress
{
    return kMTCMemAddressBase;
}

- (unsigned long) memAddressModifier
{
	return kMTCMemAddressModifier;
}

- (unsigned long) baseAddress
{
    return kMTCRegAddressBase;
}

- (unsigned long) mtcaN100Mask
{
    return _mtcaN100Mask;
}

- (void) setMtcaN100Mask:(unsigned long)aMtcaN100Mask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaN100Mask:[self mtcaN100Mask]];
    _mtcaN100Mask = aMtcaN100Mask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (unsigned long) mtcaN20Mask
{
    return _mtcaN20Mask;
}

- (void) setMtcaN20Mask:(unsigned long)aMtcaN20Mask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaN20Mask:[self mtcaN20Mask]];
    _mtcaN20Mask = aMtcaN20Mask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (unsigned long) mtcaEHIMask
{
    return _mtcaEHIMask;
}

- (void) setMtcaEHIMask:(unsigned long)aMtcaEHIMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaEHIMask:[self mtcaEHIMask]];
    _mtcaEHIMask = aMtcaEHIMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (unsigned long) mtcaELOMask
{
    return _mtcaELOMask;
}

- (void) setMtcaELOMask:(unsigned long)aMtcaELOMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaELOMask:[self mtcaELOMask]];
    _mtcaELOMask = aMtcaELOMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (unsigned long) mtcaOELOMask
{
    return _mtcaOELOMask;
}

- (void) setMtcaOELOMask:(unsigned long)aMtcaOELOMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaOELOMask:[self mtcaOELOMask]];
    _mtcaOELOMask = aMtcaOELOMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (unsigned long) mtcaOEHIMask
{
    return _mtcaOEHIMask;
}

- (void) setMtcaOEHIMask:(unsigned long)aMtcaOEHIMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaOEHIMask:[self mtcaOEHIMask]];
    _mtcaOEHIMask = aMtcaOEHIMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (unsigned long) mtcaOWLNMask
{
    return _mtcaOWLNMask;
}

- (void) setMtcaOWLNMask:(unsigned long)aMtcaOWLNMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaOWLNMask:[self mtcaOWLNMask]];
    _mtcaOWLNMask = aMtcaOWLNMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (BOOL) isPedestalEnabledInCSR
{
    return _isPedestalEnabledInCSR;
}

- (void) setIsPedestalEnabledInCSR:(BOOL)isPedestalEnabledInCSR
{
	[[[self undoManager] prepareWithInvocationTarget:self] setIsPedestalEnabledInCSR:[self isPedestalEnabledInCSR]];
    _isPedestalEnabledInCSR = isPedestalEnabledInCSR;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelIsPedestalEnabledInCSR object:self];
}

#pragma mark •••Converters
- (unsigned long) mVoltsToRaw:(float) mVolts
{
	return (long)(((mVolts + 5000.0)*0.4096)+.5);
}

- (float) rawTomVolts:(long) aRawValue
{
	return (aRawValue*2.44140625)-5000.0;
}

- (float) mVoltsToNHits:(float) mVolts dcOffset:(float)dcOffset mVperNHit:(float)mVperNHit
{
	float NHits_per_mVolts = 0.0;
	if(mVperNHit)NHits_per_mVolts = 1/mVperNHit;
	//return (mVolts - dcOffset)*NHits_per_mVolts +.5;
	return (mVolts - dcOffset)*NHits_per_mVolts;
}

- (float) NHitsTomVolts:(float) NHits dcOffset:(float)dcOffset mVperNHit:(float)mVperNHit
{
	return dcOffset + (mVperNHit*NHits);
}

- (long) NHitsToRaw:(float) NHits dcOffset:(float)dcOffset mVperNHit:(float)mVperNHit
{
	float mVolts = [self NHitsTomVolts:NHits dcOffset:dcOffset mVperNHit:mVperNHit];
	return [self mVoltsToRaw:mVolts];
}

- (float) mVoltsTopC:(float) mVolts dcOffset:(float)dcOffset mVperpC:(float)mVperpC
{
	float pC_per_mVolts = 0.0;
	if(mVperpC)pC_per_mVolts = 1/mVperpC;
	return (mVolts - dcOffset)*pC_per_mVolts;	
}

- (float) pCTomVolts:(float) pC dcOffset:(float)dcOffset mVperpC:(float)mVperpC
{
	return (float)dcOffset + (mVperpC*pC);
}

- (long) pCToRaw:(float) pC dcOffset:(float)dcOffset mVperpC:(float)mVperpC
{
	float mVolts = [self pCTomVolts:pC dcOffset:dcOffset mVperpC:mVperpC];
	return [self mVoltsToRaw:mVolts];
}

-(NSMutableDictionary*) get_MTCDataBase
{
    return mtcDataBase;
    //return [[mtcDataBase objectForNestedKey:[self getDBDefaultByIndex:DBRef]] unsignedShortValue];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];

    [self registerNotificationObservers];

    /* initialize our connection to the MTC server */
    mtc = [[RedisClient alloc] initWithHostName:MTC_HOST withPort:MTC_PORT];
	
    [[self undoManager] disableUndoRegistration];
    [self setESumViewType:	[decoder decodeIntForKey:		@"ORMTCModelESumViewType"]];
    [self setNHitViewType:	[decoder decodeIntForKey:		@"ORMTCModelNHitViewType"]];
    [self setDefaultFile:	[decoder decodeObjectForKey:	@"ORMTCModelDefaultFile"]];
    [self setLastFile:		[decoder decodeObjectForKey:	@"ORMTCModelLastFile"]];
    [self setLastFileLoaded:[decoder decodeObjectForKey:	@"ORMTCModelLastFileLoaded"]];
    [self setAutoIncrement:	[decoder decodeBoolForKey:		@"ORMTCModelAutoIncrement"]];
    [self setUseMemory:		[decoder decodeIntForKey:		@"ORMTCModelUseMemory"]];
    [self setRepeatDelay:	[decoder decodeIntForKey:		@"ORMTCModelRepeatDelay"]];
    [self setRepeatOpCount:	[decoder decodeIntForKey:		@"ORMTCModelRepeatCount"]];
    [self setWriteValue:	[decoder decodeInt32ForKey:		@"ORMTCModelWriteValue"]];
    [self setMemoryOffset:	[decoder decodeInt32ForKey:		@"ORMTCModelMemoryOffset"]];
    [self setSelectedRegister:[decoder decodeIntForKey:		@"ORMTCModelSelectedRegister"]];
	[self setIsPulserFixedRate:	[decoder decodeBoolForKey:	@"ORMTCModelIsPulserFixedRate"]];
	[self setFixedPulserRateCount:	[decoder decodeIntForKey:	@"ORMTCModelFixedPulserRateCount"]];
	[self setFixedPulserRateDelay:	[decoder decodeFloatForKey:	@"ORMTCModelFixedPulserRateDelay"]];
	[self setMtcDataBase:		[decoder decodeObjectForKey:	@"ORMTCModelMtcDataBase"]];

    [self setMtcaN100Mask:[decoder decodeIntForKey:@"mtcaN100Mask"]];
    [self setMtcaN20Mask:[decoder decodeIntForKey:@"mtcaN20Mask"]];
    [self setMtcaEHIMask:[decoder decodeIntForKey:@"mtcaEHIMask"]];
    [self setMtcaELOMask:[decoder decodeIntForKey:@"mtcaELOMask"]];
    [self setMtcaOELOMask:[decoder decodeIntForKey:@"mtcaOELOMask"]];
    [self setMtcaOEHIMask:[decoder decodeIntForKey:@"mtcaOEHIMask"]];
    [self setMtcaOWLNMask:[decoder decodeIntForKey:@"mtcaOWLNMask"]];
    [self setIsPedestalEnabledInCSR:[decoder decodeBoolForKey:@"isPedestalEnabledInCSR"]];
    
	if(!mtcDataBase)[self setupDefaults];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInt:eSumViewType		forKey:@"ORMTCModelESumViewType"];
	[encoder encodeInt:nHitViewType		forKey:@"ORMTCModelNHitViewType"];
	[encoder encodeObject:defaultFile	forKey:@"ORMTCModelDefaultFile"];
	[encoder encodeObject:lastFile		forKey:@"ORMTCModelLastFile"];
	[encoder encodeObject:lastFileLoaded forKey:@"ORMTCModelLastFileLoaded"];
	[encoder encodeBool:autoIncrement	forKey:@"ORMTCModelAutoIncrement"];
	[encoder encodeInt:useMemory		forKey:@"ORMTCModelUseMemory"];
	[encoder encodeInt:repeatDelay		forKey:@"ORMTCModelRepeatDelay"];
	[encoder encodeInt:repeatOpCount	forKey:@"ORMTCModelRepeatCount"];
	[encoder encodeInt32:writeValue		forKey:@"ORMTCModelWriteValue"];
	[encoder encodeInt32:memoryOffset	forKey:@"ORMTCModelMemoryOffset"];
	[encoder encodeInt:selectedRegister	forKey:@"ORMTCModelSelectedRegister"];
	[encoder encodeObject:mtcDataBase	forKey:@"ORMTCModelMtcDataBase"];
	[encoder encodeBool:isPulserFixedRate	forKey:@"ORMTCModelIsPulserFixedRate"];
	[encoder encodeInt:fixedPulserRateCount forKey:@"ORMTCModelFixedPulserRateCount"];
	[encoder encodeFloat:fixedPulserRateDelay forKey:@"ORMTCModelFixedPulserRateDelay"];
    [encoder encodeInt:[self mtcaN100Mask] forKey:@"mtcaN100Mask"];
    [encoder encodeInt:[self mtcaN20Mask] forKey:@"mtcaN20Mask"];
    [encoder encodeInt:[self mtcaEHIMask] forKey:@"mtcaEHIMask"];
    [encoder encodeInt:[self mtcaEHIMask] forKey:@"mtcaELOMask"];
    [encoder encodeInt:[self mtcaEHIMask] forKey:@"mtcaOELOMask"];
    [encoder encodeInt:[self mtcaEHIMask] forKey:@"mtcaOEHIMask"];
    [encoder encodeInt:[self mtcaEHIMask] forKey:@"mtcaOWLNMask"];
    [encoder encodeBool:[self isPedestalEnabledInCSR] forKey:@"isPedestalEnabledInCSR"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	return objDictionary;
}

#pragma mark •••DB Helpers
- (void) setDbLong:(long) aValue forIndex:(int)anIndex
{
	[self setDbObject:[NSNumber numberWithLong:aValue] forIndex:anIndex];
}
- (void) setDbFloat:(float) aValue forIndex:(int)anIndex
{
	[self setDbObject:[NSNumber numberWithFloat:aValue] forIndex:anIndex];
}

- (void) setDbObject:(id) anObject forIndex:(int)anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDbObject:[mtcDataBase objectForNestedKey:[self getDBKeyByIndex:anIndex]] forIndex:anIndex];
	if (anIndex < kDBComments && [anObject isKindOfClass:[NSString class]]) {
		NSDecimalNumber* aValue = [NSDecimalNumber decimalNumberWithString:anObject];
		[mtcDataBase setObject:aValue forNestedKey:[self getDBKeyByIndex:anIndex]];
	}
	else {
		[mtcDataBase setObject:anObject forNestedKey:[self getDBKeyByIndex:anIndex]];
	}

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMtcDataBaseChanged object:self];
}

- (short)     dbLookTableSize					  { return kDbLookUpTableSize; }
- (id)        dbObjectByIndex:(int)anIndex		  { return [mtcDataBase objectForNestedKey:[self getDBKeyByIndex:anIndex]]; }
- (float)     dbFloatByIndex:(int)anIndex		  { return [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex:anIndex]] floatValue]; }
- (int)       dbIntByIndex:(int)anIndex			  { return [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex:anIndex]] intValue]; }
- (id)        dbObjectByName:(NSString*)aKey	  { return [mtcDataBase objectForNestedKey:aKey]; }
- (NSString*) getDBKeyByIndex:(short) anIndex	  { return dbLookUpTable[anIndex].key; }
- (NSString*) getDBDefaultByIndex:(short) anIndex { return dbLookUpTable[anIndex].defaultValue;  }
- (int)       dacValueByIndex:(short)anIndex	  { return [self dbIntByIndex:mtcDacIndexes[anIndex]]; }

#pragma mark •••HW Access
- (short) getNumberRegisters
{
    return kMtcNumRegisters;
}

- (NSString*) getRegisterName:(short) anIndex
{
    return reg[anIndex].regName;
}

- (uint32_t) read:(int)aReg
{
	uint32_t theValue = 0;
	@try {
        theValue = [mtc intCommand:"mtcd_read %d", reg[aReg].addressOffset];
	} @catch(NSException* localException) {
		NSLog(@"Couldn't read the MTC %@!\n",reg[aReg].regName);
		[localException raise];
	}
	return theValue;
}

- (void) write:(int)aReg value:(uint32_t)aValue
{
	@try {
        [mtc okCommand:"mtcd_write %d %d", reg[aReg].addressOffset, aValue];
	} @catch(NSException* localException) {
		NSLog(@"Couldn't write %d to the MTC %@!\n",aValue,reg[aReg].regName);
		[localException raise];
	}
}

- (void) setBits:(int)aReg mask:(uint32_t)aMask
{
	unsigned long old_value = [self read:aReg];
	unsigned long new_value = (old_value & ~aMask) | aMask;
	[self write:aReg value:new_value];
}

- (void) clrBits:(int)aReg mask:(uint32_t)aMask
{
	unsigned long old_value = [self read:aReg];
	unsigned long new_value = (old_value & ~aMask);
	[self write:aReg value:new_value];
}


- (unsigned long) getMTC_CSR
{
	unsigned long aValue = 0;
	@try {
		aValue =   [self read:kMtcControlReg];
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't get a MTC CSR!\n");
		NSLog(@"Exception: %@\n",localException);
	}
	return aValue;
}

- (unsigned long) getMTC_GTID
{
	unsigned long aValue = 0;
	@try {
		aValue =  [self read:kMtcOcGtReg] & 0xffffff;
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't get a MTC GTID!\n");
		NSLog(@"Exception: %@\n",localException);
	}
	return aValue;
}

- (unsigned long) getMTC_PedWidth
{
	unsigned long aValue = 0;
	@try {
		aValue =  [self read:kMtcPwIdReg] & 0xff;
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't get a MTC Ped Width!\n");
		NSLog(@"Exception: %@\n",localException);
	}
	return aValue;
}

- (unsigned long) getMTC_CoarseDelay
{
	unsigned long aValue = 0;
	@try {
		aValue = [self read:kMtcRtdelReg] & 0xff;
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't get a MTC Coarse Delay!\n");
		NSLog(@"Exception: %@\n",localException);
	}
	return aValue;
}

- (unsigned long) getMTC_FineDelay
{
	unsigned long aValue = 0;
	@try {
		aValue = [self read:kMtcAddelReg] & 0xff;
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't get a MTC Fine Delay!\n");
		NSLog(@"Exception: %@\n",localException);
	}
	return aValue;
}

- (void) sendMTC_SoftGt
{
	[self sendMTC_SoftGt:NO];
}

- (void) sendMTC_SoftGt:(BOOL) setGTMask
{
	@try {
		if(setGTMask)[self setSingleGTWordMask:MTC_SOFT_GT_MASK];   // Step 1: set the SOFT_GT mask
		[self write:kMtcSoftGtReg value:1];							// Step 2: write to the soft gt register (doesn't matter what you write to it)
		[self clearSingleGTWordMask:MTC_SOFT_GT_MASK];				// Step 3: clear the SOFT_GT mask
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't send a MTC SOFT_GT!\n");
		NSLog(@"Exception: %@\n",localException);
	}
	
}

- (void) initializeMtc:(BOOL) loadTheMTCXilinxFile load10MHzClock:(BOOL) loadThe10MHzClock
{
	ORSelectorSequence* seq = [ORSelectorSequence selectorSequenceWithDelegate:self];

	@try {		
		NSLog(@"Starting MTC init process....(load Xilinx: %@) (10MHzClock: %@)\n",loadTheMTCXilinxFile?@"YES":@"NO",loadThe10MHzClock?@"YES":@"NO");
		
		if (loadTheMTCXilinxFile) [[seq forTarget:self] loadMTCXilinx];				// STEP 1 : Load the Xilinx
		[[seq forTarget:self] clearGlobalTriggerWordMask];							// STEP 2: Clear the GT Word Mask
		[[seq forTarget:self] clearPedestalCrateMask];								// STEP 3: Clear the Pedestal Crate Mask
		[[seq forTarget:self] clearGTCrateMask];									// STEP 4: Clear the GT Crate Mask
		[[seq forTarget:self] loadTheMTCADacs];										// STEP 5: Load the DACs	
		[[seq forTarget:self] clearTheControlRegister];								// STEP 6: Clear the Control Register
		[[seq forTarget:self] zeroTheGTCounter];									// STEP 7: Clear the GT Counter
		[[seq forTarget:self] setTheLockoutWidth:uShortDBValue(kLockOutWidth)];		// STEP 8: Set the Lockout Width	
		[[seq forTarget:self] setThePrescaleValue];									// STEP 9:  Load the NHIT 100 LO prescale value
		[[seq forTarget:self] setThePulserRate:floatDBValue(kPulserPeriod)];		// STEP 10: Load the Pulser
		[[seq forTarget:self] setThePedestalWidth:uLongDBValue(kPedestalWidth)];	// STEP 11: Set the Pedestal Width
		[[seq forTarget:self] setupPulseGTDelaysCoarse:uLongDBValue(kCoarseDelay) fine:uLongDBValue(kFineDelay)]; // STEP 12: Setup the Pulse GT Delays
		if( loadThe10MHzClock)[[seq forTarget:self] setMtcTime];					// STEP 13: Load the 10MHz Counter
		[[seq forTarget:self] resetTheMemory];										// STEP 14: Reset the Memory	 
		//[[seq forTarget:self] setGTCrateMask];									// STEP 15: Set the GT Crate Mask from MTC database
		[[seq forTarget:self] initializeMtcDone];
		[seq startSequence];
		
	}
	@catch(NSException* localException) {
		NSLog(@"***Initialization of the MTC (%@ Xilinx, %@ 10MHz clock) failed!***\n", 
			  loadTheMTCXilinxFile?@"with":@"no", loadThe10MHzClock?@"load":@"don't load");
		NSLog(@"Exception: %@\n",localException);
		[seq stopSequence];
	}
}

- (void) initializeMtcDone
{
	NSLog(@"Initialization of the MTC complete.\n");
}

- (void) clearGlobalTriggerWordMask
{
	@try {
		[self write:kMtcMaskReg value:0];
		NSLog(@"Cleared GT Mask\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Could not clear GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) setGlobalTriggerWordMask
{
	@try {
		[self write:kMtcMaskReg value:uLongDBValue(kGtMask)];
		NSLog(@"Set GT Mask: 0x%08x\n",uLongDBValue(kGtMask));
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set a set GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}


- (unsigned long) getMTC_GTWordMask
{
	unsigned long aValue = 0;
	@try {	
		aValue =  [self read:kMtcMaskReg] & 0x03FFFFFF;
	}
	@catch(NSException* localException) {
		NSLog(@"Could not get GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
	return aValue;
}

- (void) setSingleGTWordMask:(unsigned long) gtWordMask
{	
	@try {
		[self setBits:kMtcMaskReg mask:gtWordMask];
		NSLog(@"Set GT Mask: 0x%08x\n",uLongDBValue(kGtMask));
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set a MTC GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) clearSingleGTWordMask:(unsigned long) gtWordMask
{
	@try {
		//[self clrBits:kMtcGmskReg mask:gtWordMask];
		[self clrBits:kMtcMaskReg mask:gtWordMask];
		NSLog(@"Set GT Mask: 0x%08x\n",uLongDBValue(kGtMask));
	}
	@catch(NSException* localException) {
		NSLog(@"Could not clear a MTC GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (void) clearPedestalCrateMask
{
	@try {
		[self write:kMtcPmskReg value:0];
		NSLog(@"Cleared Ped Mask\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Could not clear a Ped mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (void) setPedestalCrateMask
{
	@try {
		[self write:kMtcPmskReg value: uLongDBValue(kPEDCrateMask)];
		NSLog(@"Set Ped Mask: 0x%08x\n",uLongDBValue(kPEDCrateMask));
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set a Ped crate mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (void) clearGTCrateMask
{
	@try {
		[self write:kMtcGmskReg value:0];
		NSLog(@"Cleared GT Crate Mask\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Could not clear GT crate mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (void) setGTCrateMask
{
	@try {
		[self write:kMtcGmskReg value: uLongDBValue(kGtCrateMask)];
		NSLog(@"Set GT Crate Mask: 0x%08x\n",uLongDBValue(kGtCrateMask));
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set GT crate mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (unsigned long) getGTCrateMask
{
	unsigned long aValue = 0;
	@try {
		aValue =  [self read:kMtcGmskReg] & 0x01FFFFFF;	
	}
	@catch(NSException* localException) {
		NSLog(@"Could not get GT crate mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
	return aValue;	
}

- (void) clearTheControlRegister
{
	@try {
		[self write:kMtcControlReg value:0];
		NSLog(@"Cleared Control Reg\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Could not clear control reg!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) resetTheMemory
{
	@try {
		//Clear the MTC/D memory, the fifo write pointer and the BBA Register
		[self write:kMtcBbaReg value:0];
		[self setBits:kMtcControlReg mask:MTC_CSR_FIFO_RESET];
		[self clrBits:kMtcControlReg mask:MTC_CSR_FIFO_RESET];
		NSLog(@"Reset MTC memory\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Could not reset MTC memory!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) setTheGTCounter:(unsigned long) theGTCounterValue
{
	@try {
		// Load the serial shift register, 24 bits for the GT Counter
		short j;
		for (j = 23; j >= 0; j--){							
			if ( (1UL << j ) & theGTCounterValue ){
				[self write:kMtcSerialReg value:MTC_SERIAL_REG_DIN + MTC_SERIAL_REG_SEN];	// Bit 0 is always high
				[self write:kMtcSerialReg value:MTC_SERIAL_REG_DIN + MTC_SERIAL_SHFTCLKGT];	// clock in data value, BIT 0 = high 
			}
			else{
				[self write:kMtcSerialReg value:0UL + MTC_SERIAL_REG_SEN];		// Bit 0 is always high
				[self write:kMtcSerialReg value:0UL + MTC_SERIAL_SHFTCLKGT];	// clock in data value, BIT 0 = high 
			}
		}
		
		// Now load enable by clearing and setting the appropriate bit
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENGT];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENGT];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENGT];
		NSLog(@"Loaded the GT counter\n");			
	}
	@catch(NSException* localException) {
		NSLog(@"Could not load the MTC GT counter!\n");			
		[localException raise];
	}
}


- (void) zeroTheGTCounter
{
	[self setTheGTCounter:0UL];
}

- (void) setMtcTime
{
	//set the 10MHz counter to a time based on the number of seconds since 1/1/1996 (GMT)
	//static unsigned long theSecondsToSubtract = 0;
    

    double theTicks10MHz = [[NSDate date] timeIntervalSinceDate:[NSDate dateUsingYear:1996 month:1 day:1 hour:0 minute:0 second:0 timeZone:@"GMT"]];
	
    theTicks10MHz /= 100.E-9;
    unsigned long theLowerBits  = (unsigned long) fmod(theTicks10MHz,4294967296.0);
    unsigned long theUpperBits  = (unsigned long)(theTicks10MHz/4294967296.0);

    [self setThe10MHzCounterLow:theLowerBits high:theUpperBits];
    
    /*
 	if( theSecondsToSubtract == 0 ) {
		theSecondsToSubtract =  (unsigned long)[[NSDate date] timeIntervalSinceDate:[NSCalendarDate dateWithYear:1996 month:1 day:1 hour:0 minute:0 second:0 timeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]]];
 	}
    */
    
	/* 
	 //load the 10MHz clock from mac time....eventually we will 
	 //get the time from the GPS.
	 time_t theGPSSeconds = 0;
	 time_t theMacSeconds = 0;
	 short theGPSAddress = 0;
	 unsigned long theMacMtcSetTimeInSeconds = 0;
	 unsigned long theGPSMtcSetTimeInSeconds = 0;
	 CDatumGPS *theGPS = NULL;
	 if( gConfiguration->GetObject('SC1A' ) ) {
	 CRunControl * theRunControl = (CRunControl *)(gConfiguration->GetTheObject());
	 theGPSAddress = theRunControl->GetGPSAddress();
	 if( theGPSAddress > 0 ) {
	 // load from GPS if the GPS exists
	 // note if the GPS has already been created with the correct address
	 // then the method just returns mDatumGPS otherwise it creates a new one
	 theGPS = theRunControl->CreateDatumGPS();
	 if( theGPS ) {
	 if( theGPS->ReadTime(&theGPSSeconds ) == noErr) {
	 theGPSMtcSetTimeInSeconds = theGPSSeconds + kDelaySetTime - theSecondsToSubtract;
	 }
	 else {
	 theGPS = NULL;
	 }
	 }
	 }
	 }
	 time(&theMacSeconds);
	 theMacMtcSetTimeInSeconds = theMacSeconds - theSecondsToSubtract - OffsetFromGMT();
	 
	 unsigned long theSeconds = 0;
	 if( theGPS == NULL && (theGPSAddress > 0) ) {
	 SysBeep(10);
	 NSLog(@"Communication with the GPS at address %d failed.\n",theGPSAddress);
	 NSLog(@"Can not set the 10MHz clock!\n");
	 }
	 else {
	 if( theGPS == NULL )	theSeconds = theMacMtcSetTimeInSeconds;
	 else					theSeconds = theGPSMtcSetTimeInSeconds;
	 double        theTicks10MHz = theSeconds/100.E-9;
	 unsigned long theLowerBits  = (unsigned long) fmod(theTicks10MHz,4294967296.0);
	 unsigned long theUpperBits  = (unsigned long)(theTicks10MHz/4294967296.0);
	 [self setThe10MHzCounterLow:theLowerBits high:theUpperBits];
	 if( theGPS != NULL ) {
	 if( theGPS->WritePresetCoincidence(theGPSSeconds + kDelaySetTime) != noErr ) {
	 NSLog(@"The preset write to the GPS failed\n" );
	 NSLog(@"The MTC 10MHz clock has been loaded but not set\n" );
	 NSLog(@"The MTC MUST receive a sync pulse for the clock to latch\n" );
	 }
	 else {
	 NSLog(@"The MTC 10MHz clock will be loaded within %d seconds\n", kDelaySetTime);
	 }
	 }
	 else {
	 NSLog(@"The MTC 10MHz clock has been set to the Mac time\n" );
	 NSLog(@"The sync cable on the GPS MUST be connected to 1pps for this to work\n" );
	 }
	 }
	 */
}

- (double) get10MHzSeconds
{
	//get the 10MHz clock time expressed in seconds relative to SNO time zero
	unsigned long	lower, upper;
	double theValue = 0;
	@try {
		[self getThe10MHzCounterLow:&lower high:&upper];
		theValue =  ((double) 4294967296.0 * (double)upper + (double)lower) * 1e-7;
	}
	@catch(NSException* localException) {
		[localException raise];
	}
	return theValue;
}

- (unsigned long) getMtcTime
{
	//--get the 10MHz clock. seconds since 01/01/1904
	static unsigned long theSecondsToAdd = 0;
	
 	if( theSecondsToAdd == 0 ) {
		theSecondsToAdd =  (unsigned long)[[NSDate date] timeIntervalSinceDate:[NSDate dateUsingYear:1996 month:1 day:1 hour:0 minute:0 second:0 timeZone:@"GMT"]];
 	}
	
    return theSecondsToAdd + (unsigned long)[self get10MHzSeconds];
	
}

- (void) load10MHzClock
{
	[self setThe10MHzCounterLow:uLongDBValue(kLow10MhzClock) high:uLongDBValue(kHigh10MhzClock)];
}

// SetThe10MHzCounter
- (void) setThe10MHzCounterLow:(unsigned long) lowerValue high:(unsigned long) upperValue
{
	unsigned long	aValue;
	
	@try {
		
		// Now load the serial shift register	
		short j;
		for (j = 52; j >= 0; j--){							
			
			aValue = 0UL;
			
			if ( j < 32) {
				if ( (1UL << j ) & lowerValue ) aValue |= ( 1UL << 1 );		// build the data word
			}
 			else {
				if ( (1UL << (j - 32) ) & upperValue ) aValue |= ( 1UL << 1 );		// build the data word
			}
			[self write:kMtcSerialReg value:aValue + MTC_SERIAL_REG_SEN];	// Bit 0 is always high
			[self write:kMtcSerialReg value:aValue + MTC_SERIAL_SHFTCLK10];	// clock in data value, BIT 0 = high
		}
		
		// Now load enable by clearing and setting the appropriate bit		
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_EN10];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_EN10];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_EN10];
		NSLog(@"Loaded 10MHz counter\n");
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not load the 10MHz counter!\n");
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}


- (void) getThe10MHzCounterLow:(unsigned long*) lowerValue high:(unsigned long*) upperValue
{
	*lowerValue = 0;
	*upperValue  = 0;
	@try {
		*lowerValue = [self read:kMtcC10_0_31Reg];
		*upperValue = [self read:kMtcC10_32_52Reg] & 0x001fffffUL;
	}
	@catch(NSException* localException) {
		NSLog(@"Could not get 10MHz counter values!\n");		
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) setTheLockoutWidth:(unsigned short) theLockoutWidthValue
{
	@try {
		unsigned long lockout_index = (theLockoutWidthValue/20);
		unsigned long write_value   = (0xff - lockout_index);  //value in nano-seconds
		
		// write the GT lockout value in SMTC_GT_LOCK_REG
		[self write:kMtcGtLockReg value:write_value];
		
		// now assert and de-assert LOAD_ENLK in CONTROL REG and  
		// preserving the state of the register at the same time		
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENLK];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENLK];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENLK];
		
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not load the MTC GT lockout width!\n");		
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) setThePedestalWidth:(unsigned short) thePedestalWidthValue
{
	@try {
		unsigned long write_value = (0xff - thePedestalWidthValue/5); //value in nano-seconds
		
		// write the GT lockout value in SMTC_GT_LOCK_REG
		[self write:kMtcPwIdReg value:write_value];
		
		// now assert and de-assert LOAD_ENPW in CONTROL REG and  
		// preserving the state of the register at the same time		
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not load the MTC pedestal width!\n");	
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
		
	}
}

- (void) setThePrescaleValue
{
	@try {
		//value from 1 to 65535
		unsigned long write_value = (0xffff - (uLongDBValue(kNhit100LoPrescale) - 1));// 1 prescale/~N+1 NHIT_100_LOs
		
		// write the prescale  value in MTC_SCALE_REG
		[self write:kMtcScaleReg value:write_value];
		
		// now load it : assert and de-assert LOAD_ENPR in CONTROL REG  
		// and  preserving the state of the register at the same time		
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPR];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPR];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPR];
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not load the MTC prescale value!\n");		
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
		
	}
	
}


- (void) setupPulseGTDelaysCoarse:(unsigned short) theCoarseDelay fine:(unsigned short) theAddelValue
{		
	@try {
		
		[self setupGTCorseDelay:theCoarseDelay];	
		[self setupGTFineDelay:theAddelValue];
		
		// calculate the total delay and display
		//float theTotalDelay = (theAddelValue * [parameters uLongForKey:kPed_GT_Fine_Slope])
		//				+ (float)theCoarseDelay + [parameters uLongForKey: kPed_GT_Min_Delay_Offset];
		
		//		NSLog(@"MTC total delay set to %3.2f ns.\n", theTotalDelay);
		
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not setup the MTC PULSE_GT delays!\n");	
		NSLog(@"Exception: %@\n",localException);
		[localException raise];			
		
	}
}

- (void) setupGTCorseDelay
{
	[self setupGTCorseDelay:[self dbIntByIndex:kCoarseDelay]];
}

- (void) setupGTCorseDelay:(unsigned short) theCoarseDelay
{
	@try {
		// Set the coarse GTRIG/PED delay in ns
		unsigned long aValue = (0xff - theCoarseDelay/10);
		
		[self write:kMtcRtdelReg value:aValue];
		// now load it : assert and de-assert LOAD_ENPW in CONTROL REG  
		// and  preserving the state of the register at the same time
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
		[self setBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
		[self clrBits:kMtcControlReg mask:MTC_CSR_LOAD_ENPW];
		NSLog(@"Set GT Coarse Delay to 0x%02x\n",aValue);
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not setup the MTC GT coarse delay!\n");			
		NSLog(@"Exception: %@\n",localException);
		[localException raise];			
		
	}
}

- (void) setupGTFineDelay
{
	[self setupGTFineDelay:[self dbIntByIndex:kFineDelay]];
}

- (void) setupGTFineDelay:(unsigned short) aValue
{	
	@try {
		[self write:kMtcAddelReg value:aValue];
		NSLog(@"Set GT Fine Delay to 0x%02x\n",aValue);
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set GT fine delay!\n");			
		NSLog(@"Exception: %@\n",localException);
		[localException raise];			
		
	}
}

- (void) setThePulserRate:(float) pulserRate
{
	@try {
        [mtc okCommand:"set_pulser_freq %f", pulserRate];
		NSLog(@"mtc: pulser rate set to %.2f Hz\n", pulserRate);			
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set GT Pusler rate!\n");			
		NSLog(@"Exception: %@\n",localException);
		[localException raise];			
		
	}
}

- (void) enablePulser
{
	@try {
		[self setBits:kMtcControlReg mask:MTC_CSR_PULSE_EN];
		NSLog(@"Enabled Pulser.\n");		
	}
	@catch(NSException* localException) {
		NSLog(@"Unable to enable the pulser!\n");		
		[localException raise];	
	}
}

- (void) disablePulser
{
	@try {
		[self clrBits:kMtcControlReg mask:MTC_CSR_PULSE_EN];
		NSLog(@"Disabled Pulser.\n");		
	}
	@catch(NSException* localException) {
		NSLog(@"Unable to disable the pulser!\n");		
		[localException raise];	
	}
}

- (void)  enablePedestal
{
	@try {
		[self setBits:kMtcControlReg mask:MTC_CSR_PED_EN];
		NSLog(@"Enabled Pedestals.\n");		
	}
	@catch(NSException* localException) {
		NSLog(@"Unable to enable the Pedestals!\n");		
		[localException raise];	
	}
}

- (void)  disablePedestal
{
	@try {
		[self clrBits:kMtcControlReg mask:MTC_CSR_PED_EN];
		NSLog(@"Disabled Pedestals.\n");		
	}
	@catch(NSException* localException) {
		NSLog(@"Unable to disable the Pedestals!\n");		
		[localException raise];	
	}
}

- (void) stopMTCPedestalsFixedRate
{
	@try {
		[self disablePulser];
		[self disablePedestal];
	}
	@catch(NSException* e) {
		NSLog(@"MTC failed to stop pedestals!\n");
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
}

- (void) continueMTCPedestalsFixedRate
{
	@try {
        if ([self isPedestalEnabledInCSR]) {
            [self enablePedestal];
        }
		[self enablePulser];
	}
	@catch(NSException* e) {
		NSLog(@"MTC failed to continue pedestals!\n");
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
}

- (void) fireMTCPedestalsFixedRate
{
	//Fire Pedestal pulses at a pecified period in ms, with a specifed 
	//GT coarse delay, GT Lockout Width, pedestal width in ns and a 
	//specified crate mask set in MTC Databse. Trigger mask is EXT_8.
    
    @try {
		/* setup pedestals and global trigger */
        [self basicMTCPedestalGTrigSetup];
        [self setThePulserRate:floatDBValue(kPulserPeriod)];
        [self enablePulser];
    } @catch(NSException* e) {
        NSLog(@"MTC failed to fire pedestals at the specified settings!\n");
        NSLog(@"fireMTCPedestalsFixedRate: %@\n", [e reason]);
    }
}

- (void) basicMTCPedestalGTrigSetup
{
	
	@try {
		//[self clearGlobalTriggerWordMask];							//STEP 0a:	//added 01/24/98 QRA
        if ([self isPedestalEnabledInCSR]) {
            [self enablePedestal];											// STEP 1 : Enable Pedestal
        }
		[self setPedestalCrateMask];									// STEP 2: Mask in crates for pedestals (PMSK)
		[self setGTCrateMask];											// STEP 3: Mask  Mask in crates fo GTRIGs (GMSK)
		[self setupPulseGTDelaysCoarse: uLongDBValue(kCoarseDelay) fine:uLongDBValue(kFineDelay)]; // STEP 4: Set thSet the GTRIG/PED delay in ns
		[self setTheLockoutWidth: uLongDBValue(kLockOutWidth)];		// STEP 5: Set the GT lockout width in ns	
		[self setThePedestalWidth: uLongDBValue(kPedestalWidth)];		// STEP 6:Set the Pedestal width in ns
		[self setSingleGTWordMask: uLongDBValue(kGtMask)];				// STEP 7:Mask in global trigger word(MASK)
	}
	@catch(NSException* localException) {
		NSLog(@"Failure during MTC pedestal setup!\n");
		[localException raise];
		
	}
}

- (void) fireMTCPedestalsFixedTime
{
    @try {
		/* setup pedestals and global trigger */
        [self basicMTCPedestalGTrigSetup];

		[self clearSingleGTWordMask:MTC_SOFT_GT_MASK];

        /* set the pulser rate to 0, which will enable SOFT_GT to trigger
         * pedestals */
        [self setThePulserRate:0];

        [self enablePulser];

        [mtc okCommand:"multi_soft_gt %d %f", [self fixedPulserRateCount],
                        [self fixedPulserRateDelay]];

    } @catch(NSException* e) {
        NSLog(@"MTC failed to fire pedestals at the specified settings!\n");
        NSLog(@"fireMTCPedestalsFixedRate: %@\n", [e reason]);
    }
}

- (void) stopMTCPedestalsFixedTime
{
    [mtc okCommand:"stop_multi_soft_gt"];
}

- (void) firePedestals:(unsigned long) count withRate:(float) rate
{
    /* Fires a fix number of pedestals at a specified rate in Hz.
     * This function should not be called on the main GUI thread, but
     * only by ORCA scripts since it blocks until completion */

    long timeout = [mtc timeout];

    /* Temporarily increase the timeout since it might take a while */
    [mtc setTimeout:(long) 1.5*count/rate];

    [mtc okCommand:"fire_pedestals %d %f", count, rate];

    [mtc setTimeout:timeout];
}

- (void) basicMTCReset
{
	@try {
		
		[self disablePulser];
		[self clearGTCrateMask];
		[self clearPedestalCrateMask];		
		[self clearGlobalTriggerWordMask];
		[self resetTheMemory];
		[self zeroTheGTCounter];
		[self setTheLockoutWidth: uLongDBValue(kLockOutWidth)];		
		[self setThePrescaleValue];		
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not perform basic MTC reset!\n");
		[localException raise];
	}
}

- (void) loadTheMTCADacs
{
    /* Load the MTCA thresholds to hardware. */
    int i;
    uint16_t dacs[14];

    @try {
        for (i = 0; i < 14 ; i++) {
            dacs[i] = [self dacValueByIndex:i];
        }

        [mtc okCommand:"load_mtca_dacs %d %d %d %d %d %d %d %d %d %d %d %d %d %d", dacs[0], dacs[1], dacs[2], dacs[3], dacs[4], dacs[5], dacs[6], dacs[7], dacs[8], dacs[9], dacs[10], dacs[11], dacs[12], dacs[13]];
    } @catch(NSException* e) {
        NSLog(@"failed to load the MTCA dacs: %@", [e reason]);     
        [e raise];
    }
}

- (BOOL) adapterIsSBC
{
	return [[self adapter] isKindOfClass:NSClassFromString(@"ORVmecpuModel")];
}

- (void) loadMTCXilinx
{
    [mtc okCommand:"load_xilinx"];
}

- (void) setTubRegister
{
	@try {
		
		unsigned long aValue = [self  dbIntByIndex:kTub];
		
		unsigned long shift_value;
		unsigned long theRegValue;
		theRegValue = [self read:kMtcDacCntReg];
		short j;
		for ( j = 0; j < 32; j++) {
			shift_value = ((aValue >> j) & 0x01) == 1 ? TUB_SDATA : 0;
			theRegValue &= ~0x00001c00;   // only alter in TUB prog bits
			[self write:kMtcDacCntReg value:theRegValue];
			theRegValue |= shift_value;
			[self write:kMtcDacCntReg value:theRegValue];
			theRegValue |= TUB_SCLK;      // clock in SDATA
			[self write:kMtcDacCntReg value:theRegValue];
		}
		
		theRegValue = [self read:kMtcDacCntReg];
		theRegValue &= ~0x00001c00;
		[self write:kMtcDacCntReg value:theRegValue];
		theRegValue |= TUB_SLATCH;
		[self write:kMtcDacCntReg value:theRegValue];
		theRegValue &= ~0x00001c00;
		[self write:kMtcDacCntReg value:theRegValue];
		
		NSLog(@"0x%x was shifted into the TUB serial register\n", aValue);
		
	}
	@catch(NSException* localException) {
		NSLog(@"Failed to load Tub serial register\n");
		[localException raise];
	}
}


- (void) mtcatResetMtcat:(unsigned char) mtcat
{
    @try {
        [mtc okCommand:"mtca_reset %d", mtcat];
    } @catch (NSException *e) {
        NSLog(@"mtcatResetMtcat: %@\n", e.reason);
    }
}


- (void) mtcatResetAll
{
    @try {
        [mtc okCommand:"mtca_reset_all"];
    } @catch (NSException *e) {
        NSLog(@"mtcatResetAll: %@\n", e.reason);
    }
}

- (void) mtcatLoadCrateMasks
{
    [self mtcatResetAll];
    [self mtcatLoadCrateMask:[self mtcaN100Mask] toMtcat:0];
    [self mtcatLoadCrateMask:[self mtcaN20Mask] toMtcat:1];
    [self mtcatLoadCrateMask:[self mtcaELOMask] toMtcat:2];
    [self mtcatLoadCrateMask:[self mtcaEHIMask] toMtcat:3];
    [self mtcatLoadCrateMask:[self mtcaOELOMask] toMtcat:4];
    [self mtcatLoadCrateMask:[self mtcaOEHIMask] toMtcat:5];
    [self mtcatLoadCrateMask:[self mtcaOWLNMask] toMtcat:6];
}

- (void) mtcatClearCrateMasks
{
    [self mtcatResetAll];
    [self mtcatLoadCrateMask:0 toMtcat:0];
    [self mtcatLoadCrateMask:0 toMtcat:1];
    [self mtcatLoadCrateMask:0 toMtcat:2];
    [self mtcatLoadCrateMask:0 toMtcat:3];
    [self mtcatLoadCrateMask:0 toMtcat:4];
    [self mtcatLoadCrateMask:0 toMtcat:5];
    [self mtcatLoadCrateMask:0 toMtcat:6];
}

- (void) mtcatLoadCrateMask:(unsigned long) mask toMtcat:(unsigned char) mtcat
{
    if (mtcat > 7) {
        NSLog(@"MTCA load crate mask ignored, mtcat > 6\n");
        return;
    }

    @try {
        [mtc okCommand:"mtca_load_crate_mask %d %d", mtcat, mask];
    } @catch(NSException* e) {
        NSLog(@"mtcatLoadCrateMask: %@\n", e.reason);
        return;
    }

    char* mtcats[] = {"N100", "N20", "EHI", "ELO", "OELO", "OEHI", "OWLN"};
    NSLog(@"MTCA: set %s crate mask to 0x%08x\n", mtcats[mtcat], mask);
}


#pragma mark •••BasicOps
- (void) readBasicOps
{
	doReadOp = YES;
	workingCount = 0;
	[self setBasicOpsRunning:YES];
	[self doBasicOp];
}

- (void) writeBasicOps
{
	doReadOp = NO;
	workingCount = 0;
	[self setBasicOpsRunning:YES];
	[self doBasicOp];
}

- (void) stopBasicOps
{
	[self setBasicOpsRunning:NO];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doBasicOp) object:nil];
}

- (void) reportStatus
{
	NSLog(@"Mtc control reg: 0x%0x\n", [self getMTC_CSR]);
}

- (void) saveSet:(NSString*)filePath
{
	[mtcDataBase writeToFile:filePath atomically:NO];
} 

- (void) loadSet:(NSString*)filePath
{	
	[self setMtcDataBase:[NSMutableDictionary dictionaryWithContentsOfFile: filePath]];
	[self setLastFileLoaded:filePath];
}

@end

@implementation ORMTCModel (private)

- (void) doBasicOp
{
	@try {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doBasicOp) object:nil];
		if(useMemory){
			//TBD.....
			if(doReadOp){
			}
			else {
			}
		}
		else {
			if(doReadOp){
				NSLog(@"%@: 0x%08x\n",reg[selectedRegister].regName,[self read:selectedRegister]);
			}
			else {
				[self write:selectedRegister value:writeValue];
				NSLog(@"Wrote 0x%08x to %@\n",writeValue,reg[selectedRegister].regName);
			}
		}
		if(++workingCount<repeatOpCount){
			[self performSelector:@selector(doBasicOp) withObject:nil afterDelay:repeatDelay/1000.];
		}
		else {
			[self setBasicOpsRunning:NO];
		}
	}
	@catch(NSException* localException) {
		[self setBasicOpsRunning:NO];
		NSLog(@"Mtc basic op exception: %@\n",localException);
		[localException raise];
	}
}

- (void) setupDefaults
{
	NSMutableDictionary* aDictionary = [NSMutableDictionary dictionaryWithCapacity:100];
	int i;
	for(i=0;i<kDBComments;i++){
		NSDecimalNumber* defaultValue = [NSDecimalNumber decimalNumberWithString:[self getDBDefaultByIndex:i]];
		[aDictionary setObject:defaultValue forNestedKey:[self getDBKeyByIndex:i]];
	}
	for(i=kDBComments;i<kDbLookUpTableSize;i++){
		[aDictionary setObject:[self getDBDefaultByIndex:i] forNestedKey:[self getDBKeyByIndex:i]];
	}
	[self setMtcDataBase:aDictionary];
}
@end

