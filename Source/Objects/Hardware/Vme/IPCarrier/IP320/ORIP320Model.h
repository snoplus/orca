//
//  ORIP320Model.h
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
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


#pragma mark ¥¥¥Imported Files
#import "ORVmeIPCard.h"
#import "ORAdcProcessing.h"
#import "ORDataTaker.h"
#import "VME_eCPU_Config.h"
#import "SBC_Config.h"

enum {
    kControlReg,
    kConvertCmd,
    kADCDataReg,
    kNum320Registers
};

#define kCTRIG_mask  0x8000
#define kMode_mask   0x0300
#define kGain_mask   0x00c0
#define kChan_mask   0x001f

#define kNumIP320Channels 40

enum {
    kDiff0_19_Cal0_3,
    kSingle0_19,
    kSingle20_39,
    kAutoZero
};

@interface ORIP320Model : ORVmeIPCard <ORDataTaker,ORAdcProcessing>
{
    NSMutableArray* chanObjs;
    NSTimeInterval	pollingState;
    BOOL            hasBeenPolled;
	NSLock*			hwLock;
    unsigned long   dataId;
	BOOL			valuesReadyToShip;
	
	//cached values -- valid ONLY during running
	unsigned long slotMask;
	unsigned long lowMask;
	unsigned long highMask;
}

#pragma mark ¥¥¥Accessors
- (NSMutableArray *)chanObjs;
- (void)setChanObjs:(NSMutableArray *)chanObjs;

- (void) setPollingState:(NSTimeInterval)aState;
- (NSTimeInterval) pollingState;
- (BOOL) hasBeenPolled;

- (unsigned long)  getRegisterAddress:(short) aRegister;
- (unsigned long)  getAddressOffset:(short) anIndex;
- (NSString*)      getRegisterName:(short) anIndex;
- (short)          getNumRegisters;
- (void)           loadConstants:(unsigned short)aChannel;
- (unsigned short) readAdcChannel:(unsigned short)aChannel;
- (void)           readAllAdcChannels;
- (void)		   enablePollAll:(BOOL)state;
- (void)		   enableAlarmAll:(BOOL)state;
- (void)		   postNotification:(NSNotification*)aNote;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (unsigned long) lowMask;
- (unsigned long) highMask;

#pragma mark ¥¥¥Adc Processing Protocol
- (void)processIsStarting;
- (void)processIsStopping;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (int) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel;
- (double) convertedValue:(int)channel;
- (double) maxValueForChan:(int)channel;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORIP320GainChangedNotification;
extern NSString* ORIP320ModeChangedNotification;
extern NSString* ORIP320AdcValueChangedNotification;
extern NSString* ORIP320WriteValueChangedNotification;
extern NSString* ORIP320ReadMaskChangedNotification;
extern NSString* ORIP320ReadValueChangedNotification;
extern NSString* ORIP320PollingStateChangedNotification;

