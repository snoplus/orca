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
#include <stdint.h>

@class ORMTC_DB;
@class ORReadOutList;

#define MTCLockOutWidth @"MTCLockOutWidth"

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
		
		//settings
		NSString*				lastFileLoaded;
		NSString*				lastFile;
		NSString*				defaultFile;
		
		int						nHitViewType;
		int						eSumViewType;
    
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
@property (nonatomic,assign) double mtcStatusGTIDRate;
@property (nonatomic,assign) unsigned long long mtcStatusCnt10MHz;
@property (nonatomic,copy) NSString* mtcStatusTime10Mhz;
@property (nonatomic,assign) unsigned long mtcStatusReadPtr;
@property (nonatomic,assign) unsigned long mtcStatusWritePtr;
@property (nonatomic,assign) BOOL mtcStatusDataAvailable;
@property (nonatomic,assign) unsigned long mtcStatusNumEventsInMem;
@property (nonatomic,assign) BOOL isPedestalEnabledInCSR;
@property (nonatomic,assign) BOOL resetFifoOnStart;

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (BOOL) solitaryObject;

- (void) registerNotificationObservers;
- (void) runAboutToStart:(NSNotification*)aNote;

#pragma mark •••Accessors
- (int) eSumViewType;
- (void) setESumViewType:(int)aESumViewType;
- (int) nHitViewType;
- (void) setNHitViewType:(int)aNHitViewType;
- (NSString*) xilinxFilePath;
- (void) setXilinxFilePath:(NSString*)aDefaultFile;
- (NSString*) defaultFile;
- (void) setDefaultFile:(NSString*)aDefaultFile;
- (NSString*) lastFile;
- (void) setLastFile:(NSString*)aLastFile;
- (NSString*) lastFileLoaded;
- (void) setLastFileLoaded:(NSString*)aLastFile;
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
- (int) dacValueByIndex:(short)anIndex;

#pragma mark •••Converters
- (unsigned long) mVoltsToRaw:(float) mVolts;
- (float) rawTomVolts:(long) aRawValue;
- (float) mVoltsToNHits:(float) mVolts dcOffset:(float)dcOffset mVperNHit:(float)mVperNHit;
- (float) NHitsTomVolts:(float) NHits dcOffset:(float)dcOffset mVperNHit:(float)mVperNHit;
- (long) NHitsToRaw:(float) NHits dcOffset:(float)dcOffset mVperNHit:(float)mVperNHit;
- (float) mVoltsTopC:(float) mVolts dcOffset:(float)dcOffset mVperpC:(float)mVperp;
- (float) pCTomVolts:(float) pC dcOffset:(float)dcOffset mVperpC:(float)mVperp;
- (long) pCToRaw:(float) pC dcOffset:(float)dcOffset mVperpC:(float)mVperp;

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

#pragma mark •••Settings
- (void) saveSet:(NSString*)filePath;
- (void) loadSet:(NSString*)filePath;
@end



extern NSString* ORMTCModelESumViewTypeChanged;
extern NSString* ORMTCModelNHitViewTypeChanged;
extern NSString* ORMTCModelDefaultFileChanged;
extern NSString* ORMTCModelLastFileChanged;
extern NSString* ORMTCModelLastFileLoadedChanged;
extern NSString* ORMTCModelBasicOpsRunningChanged;
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
