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
#import "ORPQModel.h"
#import "SNOPModel.h"

//#define uShortDBValue(A) [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex: A]] unsignedShortValue]
//#define uLongDBValue(A)  [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex: A]] unsignedLongValue]
//#define floatDBValue(A)  [[mtcDataBase objectForNestedKey:[self getDBKeyByIndex: A]] floatValue]

#pragma mark •••Definitions
NSString* ORMTCModelESumViewTypeChanged		= @"ORMTCModelESumViewTypeChanged";
NSString* ORMTCModelNHitViewTypeChanged		= @"ORMTCModelNHitViewTypeChanged";
NSString* ORMTCModelBasicOpsRunningChanged	= @"ORMTCModelBasicOpsRunningChanged";
NSString* ORMTCABaselineChanged             = @"ORMTCABaselineChanged";
NSString* ORMTCAThresholdChanged            = @"ORMTCAThresholdChanged";
NSString* ORMTCAConversionChanged           = @"ORMTCAConversionChanged";
NSString* ORMTCModelAutoIncrementChanged	= @"ORMTCModelAutoIncrementChanged";
NSString* ORMTCModelUseMemoryChanged		= @"ORMTCModelUseMemoryChanged";
NSString* ORMTCModelRepeatDelayChanged		= @"ORMTCModelRepeatDelayChanged";
NSString* ORMTCModelRepeatCountChanged		= @"ORMTCModelRepeatCountChanged";
NSString* ORMTCModelWriteValueChanged		= @"ORMTCModelWriteValueChanged";
NSString* ORMTCModelMemoryOffsetChanged		= @"ORMTCModelMemoryOffsetChanged";
NSString* ORMTCModelSelectedRegisterChanged	= @"ORMTCModelSelectedRegisterChanged";
NSString* ORMTCModelXilinxPathChanged		= @"ORMTCModelXilinxPathChanged";
NSString* ORMTCModelMtcDataBaseChanged		= @"ORMTCModelMtcDataBaseChanged";
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

#define PulserRateSerializationString @"PulserRate"
#define PGT_PED_Mode_SerializationString @"PulserRate"
#define PulserEnabledSerializationString @"PulserEnabled"

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


@interface ORMTCModel (private)
- (void) doBasicOp;
- (void) setupDefaults;
@end

@implementation ORMTCModel

@synthesize
pgt_rate,
pedestalWidth,
prescaleValue,
fineDelay,
coarseDelay,
pedCrateMask,
GTCrateMask,
gtMask,
lockoutWidth,
pulserEnabled = _pulserEnabled,
tubRegister;

- (id) init //designated initializer
{
    self = [super init];

    [self registerNotificationObservers];

    /* initialize our connection to the MTC server */
    mtc = [[RedisClient alloc] init];
    [[self undoManager] disableUndoRegistration];

    [[self undoManager] enableUndoRegistration];
	[self setFixedPulserRateCount: 1];
	[self setFixedPulserRateDelay: 10];
    [self setupDefaults];

    /* We need to sync the MTC server hostname and port with the SNO+ model.
     * Usually this is done in the awakeAfterDocumentLoaded function, because
     * there we are guaranteed that the SNO+ model already exists.
     * We call updateSettings here too though to cover the case that this
     * object was added to an already existing experiment in which case
     * awakeAfterDocumentLoaded is not called. */
    [self updateSettings];
    return self;
}

- (void) updateSettings
{
    NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOPModel")];

    SNOPModel* sno;
    if ([objs count] == 0) return;

    sno = [objs objectAtIndex:0];
    [self setMTCHost:[sno mtcHost]];
    [self setMTCPort:[sno mtcPort]];
}

- (void) awakeAfterDocumentLoaded
{
    [self updateSettings];
}

- (void) setMTCPort: (int) port
{
    [mtc setPort:port];
    [mtc disconnect];
}

- (void) setMTCHost: (NSString *) host
{
    [mtc setHost:host];
    [mtc disconnect];
}

- (void) dealloc
{
    [mtc release];
    [mtcDataBase release];
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
                     selector : @selector(detectorStateChanged:)
                         name : ORPQDetectorStateChanged
                       object : nil];
}

- (int) initAtRunStart:(int) loadTriggers
{
    /* Initialize all hardware from the model at run start. If loadTriggers
     * is true, then load the GT mask, otherwise, clear the GT mask.
     * Returns 0 on success, -1 on failure. */

    @try {
        /* Setup MTCD pedestal/pulser settings */
        if ([self isPedestalEnabledInCSR]) {
            [self enablePedestal];
        } else {
            [self disablePedestal];
        }
        if ([self pulserEnabled]) [self enablePulser];

        [self loadCoarseDelayToHardware];
        [self loadFineDelayToHardware];
        [self loadLockOutWidthToHardware];
        [self loadPedWidthToHardware];
        [self loadPulserRateToHardware];
        [self loadPrescaleValueToHardware];
        /* Setup Pedestal Crate Mask */
        [self loadPedestalCrateMaskToHardware];

        /* Setup GT Crate Mask */
        [self loadGTCrateMaskToHardware];
        /* Clear the GT mask before setting the trigger thresholds because
         * we've noticed that changing the thresholds results in a brief
         * burst of events. */
        [self clearGlobalTriggerWordMask];

        /* Setup MTCA Thresholds */
        [self loadTheMTCADacs];

        /* Setup MTCA relays */
        [self mtcatLoadCrateMasks];

        if (loadTriggers) {
            /* Setup the GT mask */
            [self setSingleGTWordMask: [self gtMask]];
        }
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"error loading MTC hardware at run start: %@\n", [e reason]);
        return -1;
    }

    return 0;
}

// update MTC GUI based on current detector state
- (void) detectorStateChanged:(NSNotification*)aNote
{
    ORPQDetectorDB *detDB = [aNote object];
    PQ_MTC *pqMTC = NULL;

    if (detDB) pqMTC = (PQ_MTC *)[detDB getMTC];

    if (!pqMTC) {     // nothing to do if MTC doesn't exist in the current state
        NSLogColor([NSColor redColor], @"MTC settings not loaded!\n");
        return;
    }

    int countInvalid = 0;

    @try {
        [[self undoManager] disableUndoRegistration];

        if (pqMTC->valid[kMTC_controlReg]) {
            // TO_DO is this the best way to handle the pedestal enable (bit 0x01) and pulser enable (bit 0x02)?
            if (((pqMTC->controlReg >> 1) ^ pqMTC->controlReg) & 0x01) {
                [self setIsPedestalEnabledInCSR:(pqMTC->controlReg & 0x01)];
            }
        } else ++countInvalid;

        //TO_DO verify that order of MTCA DACs is correct
        for (int i=0; i<10; ++i) {
            if (pqMTC->valid[kMTC_mtcaDacs] & (1 << i)) {
                uint32_t val = pqMTC->mtcaDacs[i];
                [self setDbLong:val forIndex:mtcDacIndexFromDetectorDB[i]];
            } else ++countInvalid;
        }

        if (pqMTC->valid[kMTC_pedWidth]) {
            [self setDbLong:pqMTC->pedWidth forIndex:kPedestalWidth];
        } else ++countInvalid;


        if (pqMTC->valid[kMTC_coarseDelay]) {
            [self setDbLong:pqMTC->coarseDelay forIndex:kCoarseDelay];
        } else ++countInvalid;

        if (pqMTC->valid[kMTC_fineDelay]) {
            [self setDbLong:pqMTC->fineDelay/100 forIndex:kFineDelay];
        } else ++countInvalid;

        if (pqMTC->valid[kMTC_pedMask]) {
            [self setDbLong:pqMTC->pedMask forIndex:kPEDCrateMask];
        } else ++countInvalid;

        if (pqMTC->valid[kMTC_prescale]) {
            [self setDbLong:pqMTC->prescale forIndex:kNhit100LoPrescale];
        } else ++countInvalid;

        if (pqMTC->valid[kMTC_lockoutWidth]) {
            [self setDbLong:pqMTC->lockoutWidth forIndex:kLockOutWidth];
        } else ++countInvalid;

        if (pqMTC->valid[kMTC_gtMask]) {
            [self setDbLong:pqMTC->gtMask forIndex:kGtMask];
        } else ++countInvalid;

        if (pqMTC->valid[kMTC_gtCrateMask]) {
            [self setDbLong:pqMTC->gtCrateMask forIndex:kGtCrateMask];
        } else ++countInvalid;

        //TO_DO verify that order of relays is correct
        for (int i=0; i<kNumMtcRelays; ++i) {
            if (pqMTC->valid[kMTC_mtcaRelays] & (1 << i)) {
                uint32_t val = pqMTC->mtcaRelays[i];
                switch (i) {
                    case 0:
                        [self setMtcaN100Mask:val];
                        break;
                    case 1:
                        [self setMtcaN20Mask:val];
                        break;
                    case 2:
                        [self setMtcaELOMask:val];
                        break;
                    case 3:
                        [self setMtcaEHIMask:val];
                        break;
                    case 4:
                        [self setMtcaOELOMask:val];
                        break;
                    case 5:
                        [self setMtcaOEHIMask:val];
                        break;
                    case 6:
                        [self setMtcaOWLNMask:val];
                        break;
                }
            } else ++countInvalid;
        }

        if (pqMTC->valid[kMTC_pulserRate] && pqMTC->pulserRate) { // (don't set if rate is 0)
            [self setDbLong:pqMTC->pulserRate forIndex:kPulserPeriod];
        } else ++countInvalid;

        // set find slope and min delay offset to constant values (aren't used anyway)
        [self setDbFloat:0.1 forIndex:kFineSlope];
        [self setDbFloat:18.35 forIndex:kMinDelayOffset];
    }
    @finally {
        [[self undoManager] enableUndoRegistration];
    }
    if (countInvalid) {
        NSLogColor([NSColor redColor], @"%d MTC settings not loaded!\n", countInvalid);
    }
}

#pragma mark •••Accessors

- (unsigned short) addressModifier
{
	return 0x29;
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
- (int) server_index_to_model_index:(int) server_index {
    switch (server_index) {
        case SERVER_N100L_INDEX:
            return MTC_N100_LO_THRESHOLD_INDEX;
            break;
        case SERVER_N100M_INDEX:
            return MTC_N100_MED_THRESHOLD_INDEX;
            break;
        case SERVER_N100H_INDEX:
            return MTC_N100_HI_THRESHOLD_INDEX;
            break;
        case SERVER_N20_INDEX:
            return MTC_N20_THRESHOLD_INDEX;
            break;
        case SERVER_N20LB_INDEX:
            return MTC_N20LB_THRESHOLD_INDEX;
            break;
        case SERVER_ESUMH_INDEX:
            return MTC_ESUMH_THRESHOLD_INDEX;
            break;
        case SERVER_ESUML_INDEX:
            return MTC_ESUML_THRESHOLD_INDEX;
            break;
        case SERVER_OWLEL_INDEX:
            return MTC_OWLELO_THRESHOLD_INDEX;
            break;
        case SERVER_OWLEH_INDEX:
            return MTC_OWLEHI_THRESHOLD_INDEX;
            break;
        case SERVER_OWLN_INDEX:
            return MTC_OWLN_THRESHOLD_INDEX;
            break;
            
    }
    [NSException raise:@"MTCModelError" format:@"Cannot convert server index %i to model index",server_index];
    return -1;
}
- (int) model_index_to_server_index:(int) model_index {
    switch (model_index) {
        case MTC_N100_LO_THRESHOLD_INDEX:
            return SERVER_N100L_INDEX;
            break;
            
        case MTC_N100_MED_THRESHOLD_INDEX:
            return SERVER_N100M_INDEX;
            break;
        case MTC_N100_HI_THRESHOLD_INDEX:
            return SERVER_N100H_INDEX;
            break;
        case MTC_N20_THRESHOLD_INDEX:
            return SERVER_N20_INDEX;
            break;
        case MTC_N20LB_THRESHOLD_INDEX:
            return SERVER_N20LB_INDEX;
            break;
        case MTC_ESUMH_THRESHOLD_INDEX:
            return SERVER_ESUMH_INDEX;
            break;
        case MTC_ESUML_THRESHOLD_INDEX:
            return SERVER_ESUML_INDEX;
            break;
        case MTC_OWLELO_THRESHOLD_INDEX:
            return SERVER_OWLEL_INDEX;
            break;
        case MTC_OWLEHI_THRESHOLD_INDEX:
            return SERVER_OWLEH_INDEX;
            break;
        case MTC_OWLN_THRESHOLD_INDEX:
            return SERVER_OWLN_INDEX;
            break;
    }
    [NSException raise:@"MTCModelError" format:@"Cannot convert model index %i to server index",model_index];
    return -1;
}
-(NSMutableDictionary*) get_MTCDataBase
{
    return mtcDataBase;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];

    [self registerNotificationObservers];

    /* initialize our connection to the MTC server */
    mtc = [[RedisClient alloc] init];

    [[self undoManager] disableUndoRegistration];
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

    [self setMtcaN100Mask:[decoder decodeIntForKey:@"mtcaN100Mask"]];
    [self setMtcaN20Mask:[decoder decodeIntForKey:@"mtcaN20Mask"]];
    [self setMtcaEHIMask:[decoder decodeIntForKey:@"mtcaEHIMask"]];
    [self setMtcaELOMask:[decoder decodeIntForKey:@"mtcaELOMask"]];
    [self setMtcaOELOMask:[decoder decodeIntForKey:@"mtcaOELOMask"]];
    [self setMtcaOEHIMask:[decoder decodeIntForKey:@"mtcaOEHIMask"]];
    [self setMtcaOWLNMask:[decoder decodeIntForKey:@"mtcaOWLNMask"]];
    [self setIsPedestalEnabledInCSR:[decoder decodeBoolForKey:@"isPedestalEnabledInCSR"]];
    [self setPulserEnabled:[decoder decodeBoolForKey:@"pulserEnabled"]];


    [self setLockoutWidth:[decoder decodeIntForKey:@"MTCLockoutWidth"]];
    [self setPedestalWidth:[decoder decodeIntForKey:@"MTCPedestalWidth"]];
    [self setPrescaleValue:[decoder decodeIntForKey:@"MTCPrescaleValue"]];
    [self setPgt_rate:[decoder decodeIntForKey:@"MTCPulserRate"]];
    [self setFineDelay: [decoder decodeIntForKey:@"MTCFineDelay"]];
    [self setCoarseDelay:[decoder decodeIntForKey:@"MTCCoarseDelay"]];
    [self setGtMask:[decoder decodeIntForKey:@"MTCGTMask"]];
    [self setGTCrateMask: [decoder decodeIntForKey:@"MTCGTCrateMask"]];
    [self setPedCrateMask:[decoder decodeIntForKey:@"MTCPedCrateMask"]];

    [[self undoManager] enableUndoRegistration];

    /* We need to sync the MTC server hostname and port with the SNO+ model.
     * Usually this is done in the awakeAfterDocumentLoaded function, because
     * there we are guaranteed that the SNO+ model already exists.
     * We call updateSettings here too though to cover the case that this
     * object was added to an already existing experiment in which case
     * awakeAfterDocumentLoaded is not called. */
    [self updateSettings];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
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
    [encoder encodeInt:[self mtcaELOMask] forKey:@"mtcaELOMask"];
    [encoder encodeInt:[self mtcaOELOMask] forKey:@"mtcaOELOMask"];
    [encoder encodeInt:[self mtcaOEHIMask] forKey:@"mtcaOEHIMask"];
    [encoder encodeInt:[self mtcaOWLNMask] forKey:@"mtcaOWLNMask"];
    [encoder encodeBool:[self isPedestalEnabledInCSR] forKey:@"isPedestalEnabledInCSR"];
    
    [encoder encodeBool:[self pulserEnabled] forKey:@"pulserEnabled"];
    [encoder encodeInt:[self lockoutWidth] forKey:@"MTCLockoutWidth"];
    [encoder encodeInt:[self pedestalWidth] forKey:@"MTCPedestalWidth"];
    [encoder encodeInt:[self prescaleValue] forKey:@"MTCPrescaleValue"];
    [encoder encodeInt:[self pgt_rate] forKey:@"MTCPulserRate"];
    [encoder encodeInt:[self fineDelay] forKey:@"MTCFineDelay"];
    [encoder encodeInt:[self coarseDelay] forKey:@"MTCCoarseDelay"];
    [encoder encodeInt:[self gtMask] forKey:@"MTCGTMask"];
    [encoder encodeInt:[self GTCrateMask] forKey:@"MTCGTCrateMask"];
    [encoder encodeInt:[self pedCrateMask] forKey:@"MTCPedCrateMask"];
}


- (float) getThresholdOfType:(int) type inUnits:(int) units
{
    if(type<0 || type > MTC_NUM_USED_THRESHOLDS)
    {
        [NSException raise:@"MTCModelError" format:@"Unknown threshold index specified. Cannot continue."];
    }
    uint16_t threshold = mtca_thresholds[type];
    // The following could let an exception bubble up
    return [self convertThreshold:threshold OfType:type fromUnits:MTC_RAW_UNITS toUnits:units];
}

- (void) setThresholdOfType:(int)type fromUnits:(int)units toValue:(float) aThreshold
{
    if(type<0 || type > MTC_NUM_USED_THRESHOLDS)
    {
        [NSException raise:@"MTCModelError" format:@"Unknown threshold index specified. Cannot continue."];
    }
    uint16_t threshold_in_dac_counts = (uint16)[self convertThreshold:aThreshold OfType:type fromUnits:units toUnits:MTC_RAW_UNITS];
    if(mtca_thresholds[type] != threshold_in_dac_counts) {
        mtca_thresholds[type] = threshold_in_dac_counts;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCAThresholdChanged object:self];
    }
}
- (float) convertThreshold:(float)aThreshold OfType:(int) type fromUnits:(int)in_units toUnits:(int) out_units{
    
    if(type<0 || type > MTC_NUM_USED_THRESHOLDS)
    {
        [NSException raise:@"MTCModelError" format:@"Unknown threshold index specified. Cannot continue."];
    }
    if(in_units == out_units)
    {
        return aThreshold;
    }
    float DAC_per_nhit = [self DAC_per_NHIT_ofType:type];
    float DAC_per_mv = [self DAC_per_mV_ofType:type];
    float mv_per_nhit = DAC_per_nhit/DAC_per_mv;

    if(in_units == MTC_RAW_UNITS) {
        // Note the following conversion is in relative units for absolute units subtract 5000mV
        // and replace the [self getbaseline] with just 4096
        float value_in_mv = ((aThreshold - [self getBaselineOfType:type])/DAC_per_mv); //TODO less magic
        
        if(out_units == MTC_mV_UNITS)
        {
            return value_in_mv;
        }
        else if (out_units == MTC_NHIT_UNITS)
        {
            return [self convertThreshold:value_in_mv OfType:type fromUnits:MTC_mV_UNITS toUnits:out_units];
        }
    }
    else if (in_units == MTC_mV_UNITS) {
        if(out_units == MTC_RAW_UNITS) {
            return (((aThreshold) * DAC_per_mv)+[self getBaselineOfType:type]);
        }
        else if(out_units == MTC_NHIT_UNITS) {
            int baseline = [self getBaselineOfType:type];
            float baseline_in_mV = [self convertThreshold:baseline OfType:type fromUnits:MTC_RAW_UNITS toUnits:MTC_mV_UNITS];
            
            //Note the following conversion is in relative units for absolute units add 5000mV
            // and replace the [self getbaseline] with just 4096
            return (aThreshold - baseline_in_mV)/mv_per_nhit;
        }
    }
    else if (in_units == MTC_NHIT_UNITS) {
        int baseline = [self getBaselineOfType:type];
        float baseline_in_mV = [self convertThreshold:baseline OfType:type fromUnits:MTC_RAW_UNITS toUnits:MTC_mV_UNITS];
        float value_in_mv = mv_per_nhit * aThreshold+baseline_in_mV;
        
        if(out_units == MTC_mV_UNITS) {
            return value_in_mv;
        }
        else if (out_units == MTC_RAW_UNITS) {
            return [self convertThreshold:value_in_mv OfType:type fromUnits:MTC_mV_UNITS toUnits:out_units];
        }
    }
    [NSException raise:@"MTCModelError" format:@"Unknown threshold index specified. Cannot continue."];
    return -1.0;
}

- (uint16_t) getBaselineOfType:(int) type {
    return mtca_baselines[type];
}
- (void) setBaselineOfType:(int) type toValue:(uint16_t) _val {
    if(mtca_baselines[type] != _val)
    {
        mtca_baselines[type] = _val;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCABaselineChanged object:self];
    }
}

- (float) DAC_per_NHIT_ofType:(int) type {
    return mtca_dac_per_nhit[type];
}
- (void) setDAC_per_NHIT_OfType:(int) type toValue:(float) _val {
    if(mtca_dac_per_nhit[type] != _val)
    {
        mtca_dac_per_nhit[type] = _val;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCAConversionChanged object:self];
    }
}
- (float) DAC_per_mV_ofType:(int) type {
    return mtca_dac_per_mV[type];
}
- (void) setDAC_per_mV_OfType:(int) type toValue:(float) _val {
    if(mtca_dac_per_mV[type] != _val)
    {
        mtca_dac_per_mV[type] = _val;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCAConversionChanged object:self];
    }
}

- (id) valueForKey:(NSString*) str fromSerialization:(NSMutableDictionary*)serial {
    NSLog(@"Note to self finish this\n");
    [[serial valueForKey:@"rows"] intValue];
    return [[[[serial valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"N100H_Threshold"];
}
- (NSString*) StringForThreshold:(int) threshold_index {
    NSString *ret;
    
    switch (threshold_index) {
        case MTC_N100_HI_THRESHOLD_INDEX:
            ret = @"N100H_Threshold";
            break;

        case MTC_N100_MED_THRESHOLD_INDEX:
            ret = @"N100M_Threshold";
            break;
        case MTC_N100_LO_THRESHOLD_INDEX:
            ret = @"N100L_Threshold";
            break;
        case MTC_N20_THRESHOLD_INDEX:
            ret = @"N20_Threshold";
            break;
        case MTC_N20LB_THRESHOLD_INDEX:
            ret = @"N20LB_Threshold";
            break;
        case MTC_ESUMH_THRESHOLD_INDEX:
            ret = @"ESUMH_Threshold";
            break;
        case MTC_ESUML_THRESHOLD_INDEX:
            ret = @"ESUML_Threshold";
            break;
        case MTC_OWLN_THRESHOLD_INDEX:
            ret = @"OWLN_Threshold";
            break;
        case MTC_OWLEHI_THRESHOLD_INDEX:
            ret = @"OWLEH_Threshold";
            break;
        case MTC_OWLELO_THRESHOLD_INDEX:
            ret = @"OWLEL_Threshold";
            break;
        default:
            ret =@"";
            [NSException raise:@"MTCModelError" format:@"Given index ( %i ) is not a valid threshold index",threshold_index];
            break;
    }
    return ret;
}

- (void) loadFromSearialization:(NSMutableDictionary*) serial {
    //This function will let any exceptions from below bubble up
    [self setThresholdOfType:MTC_N100_HI_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self valueForKey:[self StringForThreshold:MTC_N100_HI_THRESHOLD_INDEX] fromSerialization:serial] intValue]];
    [self setThresholdOfType:MTC_N100_MED_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self valueForKey:[self StringForThreshold:MTC_N100_MED_THRESHOLD_INDEX] fromSerialization:serial] intValue]];
    [self setThresholdOfType:MTC_N100_LO_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self valueForKey:[self StringForThreshold:MTC_N100_LO_THRESHOLD_INDEX] fromSerialization:serial] intValue]];
    [self setThresholdOfType:MTC_N20_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self valueForKey:[self StringForThreshold:MTC_N20_THRESHOLD_INDEX] fromSerialization:serial] intValue]];
    [self setThresholdOfType:MTC_N20LB_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self valueForKey:[self StringForThreshold:MTC_N20LB_THRESHOLD_INDEX] fromSerialization:serial] intValue]];
    [self setThresholdOfType:MTC_ESUMH_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self valueForKey:[self StringForThreshold:MTC_ESUMH_THRESHOLD_INDEX] fromSerialization:serial] intValue]];
    [self setThresholdOfType:MTC_ESUML_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self valueForKey:[self StringForThreshold:MTC_ESUML_THRESHOLD_INDEX] fromSerialization:serial] intValue]];
    [self setThresholdOfType:MTC_OWLN_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self valueForKey:[self StringForThreshold:MTC_OWLN_THRESHOLD_INDEX] fromSerialization:serial] intValue]];
    [self setThresholdOfType:MTC_OWLEHI_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self valueForKey:[self StringForThreshold:MTC_OWLEHI_THRESHOLD_INDEX] fromSerialization:serial] intValue]];
    [self setThresholdOfType:MTC_OWLELO_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self valueForKey:[self StringForThreshold:MTC_OWLELO_THRESHOLD_INDEX] fromSerialization:serial] intValue]];

    [self setPgt_rate:[[self valueForKey:PulserRateSerializationString fromSerialization:serial] intValue]];
    [self setIsPedestalEnabledInCSR:[[self valueForKey:PGT_PED_Mode_SerializationString fromSerialization:serial] boolValue]];
    [self setPulserEnabled:[[self valueForKey:PulserEnabledSerializationString fromSerialization:serial] boolValue]];
}

- (NSMutableDictionary*) serializeToDictionary {
    NSMutableDictionary *serial = [NSMutableDictionary dictionaryWithCapacity:30];
    [serial autorelease];
    //This function will let any exceptions from below bubble up
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_N100_HI_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self StringForThreshold:MTC_N100_HI_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_N100_MED_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self StringForThreshold:MTC_N100_MED_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_N100_LO_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self StringForThreshold:MTC_N100_LO_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_N20_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self StringForThreshold:MTC_N20_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_N20LB_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self StringForThreshold:MTC_N20LB_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_ESUMH_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self StringForThreshold:MTC_ESUMH_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_ESUML_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self StringForThreshold:MTC_ESUML_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_OWLN_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self StringForThreshold:MTC_OWLN_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_OWLEHI_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self StringForThreshold:MTC_OWLEHI_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_OWLELO_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self StringForThreshold:MTC_OWLELO_THRESHOLD_INDEX]];

    [serial setObject:[NSNumber numberWithUnsignedLong:[self pgt_rate]] forKey:PulserRateSerializationString];
    [serial setObject:[NSNumber numberWithBool:[self isPedestalEnabledInCSR]] forKey:PGT_PED_Mode_SerializationString];
    [serial setObject:[NSNumber numberWithBool:[self pulserEnabled] ] forKey:PulserEnabledSerializationString];
    return serial;
}



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
        [[seq forTarget:self] loadLockOutWidthToHardware];                          // STEP 8: Set the Lockout Width
		[[seq forTarget:self] loadPrescaleValueToHardware];									// STEP 9:  Load the NHIT 100 LO prescale value
		[[seq forTarget:self] loadPulserRateToHardware];                            // STEP 10: Load the Pulser
		[[seq forTarget:self] loadPedWidthToHardware];                              // STEP 11: Set the Pedestal Width
		[[seq forTarget:self] setupPulseGTDelaysCoarse:[self coarseDelay] fine:[self fineDelay]]; // STEP 12: Setup the Pulse GT Delays
		if( loadThe10MHzClock)[self setThe10MHzCounter:0];                          // STEP 13: Load the 10MHz Counter
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
        [self gtMask];
		[self write:kMtcMaskReg value:[self gtMask]];
		NSLog(@"Set GT Mask: 0x%08x\n",[self gtMask]);
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set a set GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}


- (uint32_t) getGTMaskFromHardware
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
        //NSLog(@"Set GT Mask: 0x%08x\n",uLongDBValue(kGtMask)); This isn't right fixit
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
        //NSLog(@"Set GT Mask: 0x%08x\n",uLongDBValue(kGtMask)); This isn't right fixit
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


- (void) loadPedestalCrateMaskToHardware
{
    uint32_t pedMaskValue = [self pedCrateMask];
	@try {
		[self write:kMtcPmskReg value: pedMaskValue];
		NSLog(@"Set Ped Mask: 0x%08x\n",pedMaskValue);
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

- (void) loadGTCrateMaskToHardware
{
    uint32_t gtCrateMaskValue = [self GTCrateMask];
	@try {
		[self write:kMtcGmskReg value: gtCrateMaskValue];
		NSLog(@"Set GT Crate Mask: 0x%08x\n",gtCrateMaskValue);
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set GT crate mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (uint32_t) getGTCrateMaskFromHardware
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
        [mtc okCommand:"set_gtid %lu",theGTCounterValue];
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

- (void) setThe10MHzCounter:(uint64_t) newValue
{
    @try {
        [mtc okCommand:"load_10mhz_clock %llu",newValue];
		NSLog(@"Loaded 10MHz counter\n");
		
	}
	@catch(NSException* localException) {
		NSLog(@"Could not load the 10MHz counter!\n");
		NSLog(@"Exception: %@\n",[localException reason]);
		[localException raise];
	}
}

- (void) loadLockOutWidthToHardware
{
    uint32_t theLockoutWidthValue = [self lockoutWidth];
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

- (void) loadPedWidthToHardware
{
    uint16_t thePedestalWidthValue = [self pedestalWidth];
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

- (void) loadPrescaleValueToHardware
{
    uint32_t N100PrescaleValue = [self prescaleValue];
	@try {
		//value from 1 to 65535
		unsigned long write_value = (0xffff - N100PrescaleValue - 1);// 1 prescale/~N+1 NHIT_100_LOs
		
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


- (void) setupPulseGTDelaysCoarse:(uint16_t) theCoarseDelay fine:(uint16_t) theAddelValue
{		
	@try {
        [self setCoarseDelay:theCoarseDelay];
		[self setFineDelay:theAddelValue];
        [self loadCoarseDelayToHardware];
        [self loadFineDelayToHardware];
	}
	@catch(NSException* localException) {
		NSLog(@"Could not setup the MTC PULSE_GT delays!\n");	
		NSLog(@"Exception: %@\n",localException);
		[localException raise];			
		
	}
}

- (void) loadCoarseDelayToHardware
{
    uint32_t theCoarseDelay = [self coarseDelay];
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

- (void) loadFineDelayToHardware
{
    uint16_t fineDelayValue = [self fineDelay];
    @try {
		[self write:kMtcAddelReg value:fineDelayValue];
		NSLog(@"Set GT Fine Delay to 0x%02x\n",fineDelayValue);
	}
	@catch(NSException* localException) {
		NSLog(@"Could not set GT fine delay!\n");			
		NSLog(@"Exception: %@\n",localException);
		[localException raise];			
		
	}
}

- (void) loadPulserRateToHardware
{
    float pulserRate = [self pgt_rate];
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

    [self setPulserEnabled:YES];
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

    [self setPulserEnabled:NO];
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
        } else {
            [self disablePedestal];
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
        [self loadPulserRateToHardware];
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
        } else {
            [self disablePedestal];
        }
		[self loadPedestalCrateMaskToHardware];									// STEP 2: Mask in crates for pedestals (PMSK)
		[self loadGTCrateMaskToHardware];								// STEP 3: Mask  Mask in crates fo GTRIGs (GMSK)
		[self setupPulseGTDelaysCoarse: [self coarseDelay] fine:[self fineDelay]]; // STEP 4: Set thSet the GTRIG/PED delay in ns
		[self loadLockOutWidthToHardware];                              // STEP 5: Set the GT lockout width in ns
        [self loadPedWidthToHardware];
		[self setSingleGTWordMask: [self gtMask]];				// STEP 7:Mask in global trigger word(MASK)
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
        [self setPgt_rate:0];
        [self loadPulserRateToHardware];

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
    [mtc setTimeout:(long) 1500*count/rate];

    @try {
        [mtc okCommand:"fire_pedestals %d %f", count, rate];
    } @catch (NSException *e) {
        @throw e;
    } @finally {
        [mtc setTimeout:timeout];
    }
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
        [self loadLockOutWidthToHardware];
		[self loadPrescaleValueToHardware];
		
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
    int server_index;
    for(i=FIRST_MTC_THRESHOLD_INDEX;i<=LAST_MTC_THRESHOLD_INDEX;i++)
    {
        @try {
            server_index = [self model_index_to_server_index:i];
            dacs[server_index] = [self getThresholdOfType:i inUnits:MTC_RAW_UNITS];
        } @catch (NSException* excep) {
            @throw; //Let it bubble up
        }
    }
    /* Last four DAC values are spares? */
    for (i = 10; i < 14; i++) {
        dacs[i] = 0;
    }

    @try {
        [mtc okCommand:"load_mtca_dacs %d %d %d %d %d %d %d %d %d %d %d %d %d %d", dacs[0], dacs[1], dacs[2], dacs[3], dacs[4], dacs[5], dacs[6], dacs[7], dacs[8], dacs[9], dacs[10], dacs[11], dacs[12], dacs[13]];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor],@"failed to load the MTCA dacs: %@\n", [e reason]);
        [e raise];
    }
    NSLog(@"Successfully loaded MTCA+ thresholds\n");
}

- (BOOL) adapterIsSBC
{
	return [[self adapter] isKindOfClass:NSClassFromString(@"ORVmecpuModel")];
}

- (void) loadMTCXilinx
{
    [mtc okCommand:"load_xilinx"];
}

- (void) loadTubRegister
{
	@try {
		
		unsigned long aValue = [self tubRegister];
		
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
    [self setLockoutWidth:420];
    [self setPedestalWidth:52];
    [self setPrescaleValue:1];
    [self setPgt_rate:10];
    [self setFineDelay: 0];
    [self setCoarseDelay:60];
    [self setGtMask:0];
    [self setGTCrateMask: 0];
    [self setPedCrateMask:0];
}
@end

