/*
 *  ORMTCModel.h
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

#import "ORVmeIOCard.h"
#import "RedisClient.h"
#import "ORPQResult.h"
#include <stdint.h>

@class ORMTC_DB;
@class ORReadOutList;

#define MTCLockOutWidth @"MTCLockOutWidth"
#define FIRST_MTC_THRESHOLD_INDEX 0
#define MTC_N100_LO_THRESHOLD_INDEX  0
#define MTC_N100_MED_THRESHOLD_INDEX 1
#define MTC_N100_HI_THRESHOLD_INDEX  2
#define MTC_N20_THRESHOLD_INDEX      3
#define MTC_N20LB_THRESHOLD_INDEX    4
#define MTC_ESUML_THRESHOLD_INDEX    5
#define MTC_ESUMH_THRESHOLD_INDEX    6
#define MTC_OWLN_THRESHOLD_INDEX     7
#define MTC_OWLELO_THRESHOLD_INDEX   8
#define MTC_OWLEHI_THRESHOLD_INDEX   9
#define LAST_MTC_THRESHOLD_INDEX 9
#define MTC_NUM_THRESHOLDS 14  // The number of thresholds that exist
#define MTC_NUM_USED_THRESHOLDS 10 // The number of thresholds that are actually used

#define MTC_RAW_UNITS 1
#define MTC_mV_UNITS 2
#define MTC_NHIT_UNITS 3



@interface ORMTCModel :  ORVmeIOCard
{
    @private
		unsigned long			_dataId;
        unsigned long			_mtcStatusDataId;
		NSMutableDictionary*	mtcDataBase;
		
		//basic ops
		int						selectedRegister;
		unsigned long			memoryOffset;
		unsigned long			writeValue;
		short					repeatOpCount;
		unsigned short			repeatDelay;
		int						useMemory;
		unsigned long			workingCount;
		BOOL				doReadOp;
		BOOL				autoIncrement;
		BOOL				basicOpsRunning;
		BOOL				isPulserFixedRate;
		unsigned long			fixedPulserRateCount;
		float				fixedPulserRateDelay;
    BOOL _isPedestalEnabledInCSR;
    BOOL _pulserEnabled;
    
    //MTCA+ crate masks
    unsigned long _mtcaN100Mask;
    unsigned long _mtcaN20Mask;
    unsigned long _mtcaEHIMask;
    unsigned long _mtcaELOMask;
    unsigned long _mtcaOELOMask;
    unsigned long _mtcaOEHIMask;
    unsigned long _mtcaOWLNMask;

    unsigned long _mtcStatusGTID;
    double _mtcStatusGTIDRate;
    unsigned long long _mtcStatusCnt10MHz;
    NSString* _mtcStatusTime10Mhz;
    unsigned long _mtcStatusReadPtr;
    unsigned long _mtcStatusWritePtr;
    BOOL _mtcStatusDataAvailable;
    unsigned long _mtcStatusNumEventsInMem;
    BOOL _resetFifoOnStart;

    uint16_t mtca_thresholds[MTC_NUM_THRESHOLDS];
    uint16_t mtca_baselines[MTC_NUM_THRESHOLDS];
    float mtca_dac_per_nhit[MTC_NUM_THRESHOLDS]; //Let the ESUMs have a conversion in case we ever need it
    float mtca_dac_per_mV[MTC_NUM_THRESHOLDS];
    RedisClient *mtc;
}

@property (nonatomic,assign) BOOL isPulserFixedRate;
@property (nonatomic,assign) unsigned long fixedPulserRateCount;
@property (nonatomic,assign) float fixedPulserRateDelay;
@property (nonatomic,assign) unsigned long mtcaN100Mask;
@property (nonatomic,assign) unsigned long mtcaN20Mask;
@property (nonatomic,assign) unsigned long mtcaEHIMask;
@property (nonatomic,assign) unsigned long mtcaELOMask;
@property (nonatomic,assign) unsigned long mtcaOELOMask;
@property (nonatomic,assign) unsigned long mtcaOEHIMask;
@property (nonatomic,assign) unsigned long mtcaOWLNMask;
@property (nonatomic,assign) unsigned long dataId;
@property (nonatomic,assign) unsigned long mtcStatusDataId;
@property (nonatomic,assign) unsigned long mtcStatusGTID;
@property (nonatomic,assign) unsigned long long mtcStatusCnt10MHz;
@property (nonatomic,copy) NSString* mtcStatusTime10Mhz;
@property (nonatomic,assign) unsigned long mtcStatusReadPtr;
@property (nonatomic,assign) unsigned long mtcStatusWritePtr;
@property (nonatomic,assign) BOOL mtcStatusDataAvailable;
@property (nonatomic,assign) unsigned long mtcStatusNumEventsInMem;
@property (nonatomic,assign) BOOL isPedestalEnabledInCSR;
@property (nonatomic,assign) BOOL resetFifoOnStart;
@property (nonatomic,assign) BOOL pulserEnabled;

//TODO refactor all this MTCA crap into it's own class/struct
@property (nonatomic) uint16_t N100H_Threshold;
@property (nonatomic) uint16_t N100M_Threshold;
@property (nonatomic) uint16_t N100L_Threshold;
@property (nonatomic) uint16_t N20_Threshold;
@property (nonatomic) uint16_t N20LB_Threshold;
@property (nonatomic) uint16_t ESUML_Threshold;
@property (nonatomic) uint16_t ESUMH_Threshold;
@property (nonatomic) uint16_t OWLEL_Threshold;
@property (nonatomic) uint16_t OWLEH_Threshold;
@property (nonatomic) uint16_t OWLN_Threshold;

@property (nonatomic) uint16_t N100H_Baseline;
@property (nonatomic) uint16_t N100M_Baseline;
@property (nonatomic) uint16_t N100L_Baseline;
@property (nonatomic) uint16_t N20_Baseline;
@property (nonatomic) uint16_t N20LB_Baseline;
@property (nonatomic) uint16_t ESUML_Baseline;
@property (nonatomic) uint16_t ESUMH_Baseline;
@property (nonatomic) uint16_t OWLEL_Baseline;
@property (nonatomic) uint16_t OWLEH_Baseline;
@property (nonatomic) uint16_t OWLN_Baseline;

@property (nonatomic) float N100H_DAC_per_NHIT;
@property (nonatomic) float N100M_DAC_per_NHIT;
@property (nonatomic) float N100L_DAC_per_NHIT;
@property (nonatomic) float N20_DAC_per_NHIT;
@property (nonatomic) float N20LB_DAC_per_NHIT;
@property (nonatomic) float OWLN_DAC_per_NHIT;

@property (nonatomic) float N100H_DAC_per_mV;
@property (nonatomic) float N100M_DAC_per_mV;
@property (nonatomic) float N100L_DAC_per_mV;
@property (nonatomic) float N20_DAC_per_mV;
@property (nonatomic) float N20LB_DAC_per_mV;
@property (nonatomic) float ESUML_DAC_per_mV;
@property (nonatomic) float ESUMH_DAC_per_mV;
@property (nonatomic) float OWLEL_DAC_per_mV;
@property (nonatomic) float OWLEH_DAC_per_mV;
@property (nonatomic) float OWLN_DAC_per_mV;



#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (BOOL) solitaryObject;

- (void) setMTCPort: (int) port;
- (void) setMTCHost: (NSString *) host;

- (void) awakeAfterDocumentLoaded;

- (void) registerNotificationObservers;
- (int) initAtRunStart: (int) loadTriggers;
- (void) detectorStateChanged:(NSNotification*)aNote;

#pragma mark •••Accessors
- (BOOL) basicOpsRunning;
- (void) setBasicOpsRunning:(BOOL)aBasicOpsRunning;
- (BOOL) autoIncrement;
- (void) setAutoIncrement:(BOOL)aAutoIncrement;
- (int) useMemory;
- (void) setUseMemory:(int)aUseMemory;
- (unsigned short) repeatDelay;
- (void) setRepeatDelay:(unsigned short)aRepeatDelay;
- (short) repeatOpCount;
- (void) setRepeatOpCount:(short)aRepeatCount;
- (unsigned long) writeValue;
- (void) setWriteValue:(unsigned long)aWriteValue;
- (unsigned long) memoryOffset;
- (void) setMemoryOffset:(unsigned long)aMemoryOffset;
- (int) selectedRegister;
- (void) setSelectedRegister:(int)aSelectedRegister;
- (NSMutableDictionary*) mtcDataBase;
- (id) dbObjectByName:(NSString*)aKey;
- (void) setMtcDataBase:(NSMutableDictionary*)aNestedDictionary;
- (unsigned long) memBaseAddress;
- (unsigned long) memAddressModifier;
- (unsigned long) baseAddress;

- (short) dbLookTableSize;
- (NSString*) getDBKeyByIndex:(short) anIndex;
- (NSString*) getDBDefaultByIndex:(short) anIndex;
- (id) dbObjectByIndex:(int)anIndex;
- (void) setDbLong:(long) aValue forIndex:(int)anIndex;
- (void) setDbFloat:(float) aValue forIndex:(int)anIndex;
- (void) setDbObject:(id) anObject forIndex:(int)anIndex;
- (float) dbFloatByIndex:(int)anIndex;
- (int) dbIntByIndex:(int)anIndex;
- (float) getThresholdOfType:(int) type inUnits:(int) units;
- (void) setThresholdOfType:(int) type fromUnits: (int) units toValue:(float) aThreshold;

- (uint16_t) getBaselineOfType:(int) type;
- (void) setBaselineOfType:(int) type toValue:(uint16_t) _val;

- (float) DAC_per_NHIT_ofType:(int) type;
- (void) setDAC_per_NHIT_OfType:(int) type toValue:(float) _val;

- (float) DAC_per_mV_ofType:(int) type;
- (void) setDAC_per_mV_OfType:(int) type toValue:(float) _val;

- (void) loadFromSearialization:(NSMutableDictionary*) serial;
- (NSMutableDictionary*) serializeToDictionary;


#pragma mark •••Converters
- (float) convertThreshold:(float)aThreshold OfType:(int) type fromUnits:(int)in_units toUnits:(int) out_units;
- (int) server_index_to_model_index:(int) server_index;
- (int) model_index_to_server_index:(int) model_index;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark •••HW Access
- (BOOL) adapterIsSBC;
- (short) getNumberRegisters;
- (NSString*) getRegisterName:(short) anIndex;
- (uint32_t) read:(int)aReg;
- (void) write:(int)aReg value:(uint32_t)aValue;
- (void) setBits:(int)aReg mask:(uint32_t)aMask;
- (void) clrBits:(int)aReg mask:(uint32_t)aMask;
- (unsigned long) getMTC_CSR;
- (unsigned long) getMTC_GTID;
- (unsigned long) getMTC_PedWidth;
- (unsigned long) getMTC_CoarseDelay;
- (unsigned long) getMTC_FineDelay;
- (void) sendMTC_SoftGt;
- (void) sendMTC_SoftGt:(BOOL) setGTMask;
- (void) initializeMtc:(BOOL) loadTheMTCXilinxFile load10MHzClock:(BOOL) loadThe10MHzClock;
- (void) initializeMtcDone;
- (void) clearGlobalTriggerWordMask;
- (void) setGlobalTriggerWordMask;
- (unsigned long) getMTC_GTWordMask;
- (void) setSingleGTWordMask:(unsigned long) gtWordMask;
- (void) clearSingleGTWordMask:(unsigned long) gtWordMask;
- (void) clearPedestalCrateMask;
- (long) getPedestalCrateMask;
- (void) setPedestalCrateMask;
- (void) clearGTCrateMask;
- (void) setGTCrateMask;
- (unsigned long) getGTCrateMask;
- (void) clearTheControlRegister;
- (void) resetTheMemory;
- (void) setTheGTCounter:(unsigned long) theGTCounterValue;
- (void) zeroTheGTCounter;
- (void) setMtcTime;
- (double) get10MHzSeconds;
- (unsigned long) getMtcTime;
- (void) setThe10MHzCounterLow:(unsigned long) lowerValue high:(unsigned long) upperValue;
- (void) getThe10MHzCounterLow:(unsigned long*) lowerValue high:(unsigned long*) upperValue;
- (void) setTheLockoutWidth:(unsigned short) theLockoutWidthValue;
- (void) setThePedestalWidth:(unsigned short) thePedestalWidthValue;
- (void) setThePrescaleValue;
- (void) setupPulseGTDelaysCoarse:(unsigned short) theCoarseDelay fine:(unsigned short) theAddelValue;
- (void) setupGTCorseDelay:(unsigned short) theCoarseDelay;
- (void) setupGTCorseDelay;
- (void) setupGTFineDelay:(unsigned short) theAddelValue;
- (void) setupGTFineDelay;
- (float) getThePulserRate;
- (void) setThePulserRate:(float) pulserRate;
- (void) enablePulser;
- (void) disablePulser;
- (void) enablePedestal;
- (void) disablePedestal;
- (void) fireMTCPedestalsFixedRate;
- (void) continueMTCPedestalsFixedRate;
- (void) stopMTCPedestalsFixedRate;
- (void) basicMTCPedestalGTrigSetup;
- (void) fireMTCPedestalsFixedTime;
- (void) stopMTCPedestalsFixedTime;
- (void) firePedestals:(unsigned long) count withRate:(float) rate;
- (void) basicMTCReset;
- (void) loadTheMTCADacs;
- (void) loadMTCXilinx;
- (void) setTubRegister;
- (void) load10MHzClock;

- (void) mtcatResetMtcat:(unsigned char) mtcat;
- (void) mtcatResetAll;
- (void) mtcatLoadCrateMasks;
- (void) mtcatClearCrateMasks;
- (void) mtcatLoadCrateMask:(unsigned long) mask toMtcat:(unsigned char) mtcat;

#pragma mark •••BasicOps
- (void) readBasicOps;
- (void) writeBasicOps;
- (void) stopBasicOps;
- (void) reportStatus;

//Extra getter functions
-(NSMutableDictionary*) get_MTCDataBase;

@end



extern NSString* ORMTCModelBasicOpsRunningChanged;
extern NSString* ORMTCABaselineChanged;
extern NSString* ORMTCAThresholdChanged;
extern NSString* ORMTCAConversionChanged;
extern NSString* ORMTCModelAutoIncrementChanged;
extern NSString* ORMTCModelUseMemoryChanged;
extern NSString* ORMTCModelRepeatDelayChanged;
extern NSString* ORMTCModelRepeatCountChanged;
extern NSString* ORMTCModelWriteValueChanged;
extern NSString* ORMTCModelMemoryOffsetChanged;
extern NSString* ORMTCModelSelectedRegisterChanged;
extern NSString* ORMTCModelXlinixPathChanged;
extern NSString* ORMTCModelMtcDataBaseChanged;
extern NSString* ORMTCModelIsPulserFixedRateChanged;
extern NSString* ORMTCModelFixedPulserRateCountChanged;
extern NSString* ORMTCModelFixedPulserRateDelayChanged;
extern NSString* ORMtcTriggerNameChanged;
extern NSString* ORMTCBasicLock;
extern NSString* ORMTCStandardOpsLock;
extern NSString* ORMTCSettingsLock;
extern NSString* ORMTCTriggersLock;
extern NSString* ORMTCModelMTCAMaskChanged;
extern NSString* ORMTCModelIsPedestalEnabledInCSR;
