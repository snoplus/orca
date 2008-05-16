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
#import "ORDataTaker.h"
#import "VME_eCPU_Config.h"
#import "SBC_Config.h"

@interface ORMTCModel :  ORVmeIOCard <ORDataTaker>
{
    @private
		NSString*				loadFilePath;
		NSFileHandle*			loadFile;
		unsigned long			dataId;
		unsigned long			memBaseAddress;
		NSMutableDictionary*	parameters;
		
		//basic ops
		int						selectedRegister;
		unsigned long			memoryOffset;
		unsigned long			writeValue;
		short					repeatCount;
		unsigned short			repeatDelay;
		int						useMemory;
		unsigned long			workingOffset;
		unsigned long			workingCount;
		BOOL					doReadOp;
		BOOL					autoIncrement;
		BOOL					basicOpsRunning;
}


#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (BOOL) solitaryObject;

#pragma mark •••Accessors
- (BOOL) basicOpsRunning;
- (void) setBasicOpsRunning:(BOOL)aBasicOpsRunning;
- (BOOL) autoIncrement;
- (void) setAutoIncrement:(BOOL)aAutoIncrement;
- (int) useMemory;
- (void) setUseMemory:(int)aUseMemory;
- (unsigned short) repeatDelay;
- (void) setRepeatDelay:(unsigned short)aRepeatDelay;
- (short) repeatCount;
- (void) setRepeatCount:(short)aRepeatCount;
- (unsigned long) writeValue;
- (void) setWriteValue:(unsigned long)aWriteValue;
- (unsigned long) memoryOffset;
- (void) setMemoryOffset:(unsigned long)aMemoryOffset;
- (int) selectedRegister;
- (void) setSelectedRegister:(int)aSelectedRegister;
- (NSMutableDictionary*) parameters;
- (void) setParameters:(NSMutableDictionary*)aParameters;
- (NSString*) loadFilePath;
- (void) setLoadFilePath:(NSString*)aLoadFilePath;
- (unsigned long) memBaseAddress;
- (unsigned long) baseAddress;
- (unsigned long) parameter:(NSString*)aKey;

#pragma mark •••Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (NSDictionary*) dataRecordDescription;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherMTC;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark •••HW Access
- (short) getNumberRegisters;
- (NSString*) getRegisterName:(short) anIndex;
- (unsigned long) read:(int)aReg;
- (void) write:(int)aReg value:(unsigned long)aValue;
- (void) setBits:(int)aReg mask:(unsigned long)aMask;
- (void) clrBits:(int)aReg mask:(unsigned long)aMask;
- (unsigned long) getMTC_CSR;
- (unsigned long) getMTC_GTID;
- (unsigned long) getMTC_PedWidth;
- (unsigned long) getMTC_CoarseDelay;
- (unsigned long) getMTC_FineDelay;
- (void) sendMTC_SoftGt;
- (void) sendMTC_SoftGt:(BOOL) setGTMask;
- (void) initializeMtc:(BOOL) loadTheMTCXilinxFile load10MHzClock:(BOOL) loadThe10MHzClock;
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
- (void) setupGTFineDelay:(unsigned short) theAddelValue;
- (void) setThePulserRate:(float) thePulserPeriodValue;
- (void) setThePulserRate:(float) thePulserPeriodValue setToInfinity:(BOOL) setToInfinity;
- (void) loadEnablePulser;
- (void) enablePulser;
- (void) disablePulser;
- (void)  enablePedestal;
- (void)  disablePedestal;
- (void) fireMTCPedestalsFixedRate;
- (void) basicMTCPedestalGTrigSetup;
- (void) setupPulserRateAndEnable:(double) pulserPeriodVal;
- (void) fireMTCPedestalsFixedNumber:(unsigned long) numPedestals;
- (void) basicMTCReset;
- (void) loadParameters;
- (void) loadTheMTCADacs;
- (void) loadMTCXilinx;
- (void) setUpTheFile;
- (void) finishXilinxLoad;
- (void) setTubRegister;

#pragma mark •••BasicOps
- (void) readBasicOps;
- (void) writeBasicOps;
- (void) stopBasicOps;

- (void) reportStatus;

@end

extern NSString* ORMTCModelBasicOpsRunningChanged;
extern NSString* ORMTCModelAutoIncrementChanged;
extern NSString* ORMTCModelUseMemoryChanged;
extern NSString* ORMTCModelRepeatDelayChanged;
extern NSString* ORMTCModelRepeatCountChanged;
extern NSString* ORMTCModelWriteValueChanged;
extern NSString* ORMTCModelMemoryOffsetChanged;
extern NSString* ORMTCModelSelectedRegisterChanged;
extern NSString* ORMTCModelLoadFilePathChanged;
extern NSString* ORMTCSettingsLock;

