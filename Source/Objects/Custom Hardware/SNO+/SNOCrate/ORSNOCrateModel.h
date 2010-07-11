//
//  ORSNOCrateModel.h
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORCrate.h"
#import "Sno_Monitor_Adcs.h"
#import "ORDataTaker.h"
#import "VME_eCPU_Config.h"
#import "SBC_Config.h"

@interface ORSNOCrateModel : ORCrate <ORDataTaker> {
	int slot;
	int workingSlot;
	BOOL working;
	BOOL pauseWork;
	BOOL autoInit;
	eFecMonitorState  voltageStatus;

	unsigned long dataId;
}

- (void) setUpImage;
- (void) makeMainController;
- (void) connected;
- (void) disconnected;
- (Class) guardianClass;
- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian;
- (void) setSlot:(int)aSlot;
- (int)  slot;
- (void) setAutoInit:(BOOL) autoInit;

#pragma mark •••Accessors
- (unsigned long) memoryBaseAddress;
- (unsigned long) registerBaseAddress;
- (NSString*) iPAddress;

#pragma mark •••Notifications
- (void) registerNotificationObservers;

#pragma mark •••HW Access
- (void) scanWorkingSlot;
- (short) numberSlotsUsed;
- (BOOL) adapterIsXL3;
- (void) initCrate:(BOOL) loadTheFEC32XilinxFile phase:(int) phase;
- (void) initCrateDone;
- (void) resetCrate;
- (eFecMonitorState) voltageStatus;
- (void) setVoltageStatus:(eFecMonitorState)aState;

#pragma mark •••Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (NSDictionary*) dataRecordDescription;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherSNOCrate;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
@end

@interface ORSNOCrateModel (OROrderedObjHolding)
- (int) maxNumberOfObjects;
- (int) objWidth;
- (int) stationForSlot:(int)aSlot;
@end

extern NSString* ORSNOCrateSlotChanged;
