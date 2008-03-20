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

#define kCAL0_mask  0x0014
#define kCAL1_mask  0x0015
#define kCAL2_mask  0x0016
#define kCAL3_mask  0x0017
#define kAUTOZERO_mask  0x0300

#define kCAL0_volt 4.9000
#define kCAL1_volt 2.4500
#define kCAL2_volt 1.2250
#define kCAL3_volt 0.6125
#define kAUTOZERO_volt 0.0000

#define kNumIP320Channels 40

#define kMinus5to5 -5
#define kMinus10to10 -10
#define k0to10 0
#define kUncalibrated 1

#define knumGainSettings 4

enum {
    kDiff0_19_Cal0_3,
    kSingle0_19,
    kSingle20_39,
    kAutoZero
};

struct{
int kCardJumperSetting;
float kSlope_m;
float kIdeal_Volt_Span;
float kIdeal_Zero;
float kVoltCALLO;
short kCountCALLO;
float kVoltCALHI;
short kCountCALHI;
}CalibrationConstants[knumGainSettings];


@interface ORIP320Model : ORVmeIPCard <ORDataTaker,ORAdcProcessing>
{
    NSMutableArray* chanObjs;
    NSTimeInterval	pollingState;
    BOOL            hasBeenPolled;
	NSLock*			hwLock;
    unsigned long   dataId;
	BOOL			valuesReadyToShip;
    BOOL			displayRaw;
	int				mode;
	BOOL			first;
    BOOL			isRunning;
	BOOL			pollRunning;
	
	//cached values -- valid ONLY during running
	unsigned long slotMask;
	unsigned long lowMask;
	unsigned long highMask;
}

#pragma mark ¥¥¥Accessors
- (void) setCardJumperSetting:(int)aCardJumperSetting;
//calibration rotines
- (void) setCardCalibration;
- (void) loadCALHIControReg:(unsigned short)gain;
- (void) loadCALLOControReg:(unsigned short)gain;
- (void)  calculateCalibrationSlope:(unsigned short)gain;
- (unsigned short) calculateCorrectedCount:(unsigned short)gain countActual:(unsigned short)CountActual;
- (void) callibrateIP320;


- (BOOL) displayRaw;
- (void) setDisplayRaw:(BOOL)aDisplayRaw;
- (NSMutableArray *)chanObjs;
- (void)setChanObjs:(NSMutableArray *)chanObjs;

- (void) setPollingState:(NSTimeInterval)aState;
- (NSTimeInterval) pollingState;
- (BOOL) hasBeenPolled;
- (void)			setMode:(int)aMode;
- (int)				mode;
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
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (BOOL) processDataBlock:(unsigned long*)ptr length:(short)n;

@end


#pragma mark ¥¥¥External String Definitions
extern NSString* ORIP320ModelDisplayRawChanged;
extern NSString* ORIP320GainChangedNotification;
extern NSString* ORIP320ModeChangedNotification;
extern NSString* ORIP320AdcValueChangedNotification;
extern NSString* ORIP320WriteValueChangedNotification;
extern NSString* ORIP320ReadMaskChangedNotification;
extern NSString* ORIP320ReadValueChangedNotification;
extern NSString* ORIP320PollingStateChangedNotification;
extern NSString* ORIP320ModelModeChanged;
