//
//  OREdelweissFLTModel.m
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

#import "OREdelweissFLTModel.h"
#import "ORIpeV4SLTModel.h"
#import "ORIpeCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORDataTypeAssigner.h"
#import "ORTimeRate.h"
#import "ORTest.h"
#import "SBC_Config.h"
#import "EdelweissSLTv4_HW_Definitions.h"
#import "ORCommandList.h"

NSString* OREdelweissFLTModelSwTriggerIsRepeatingChanged = @"OREdelweissFLTModelSwTriggerIsRepeatingChanged";
NSString* OREdelweissFLTModelRepeatSWTriggerModeChanged = @"OREdelweissFLTModelRepeatSWTriggerModeChanged";
NSString* OREdelweissFLTModelControlRegisterChanged = @"OREdelweissFLTModelControlRegisterChanged";
NSString* OREdelweissFLTModelTotalTriggerNRegisterChanged = @"OREdelweissFLTModelTotalTriggerNRegisterChanged";
NSString* OREdelweissFLTModelStatusRegisterChanged = @"OREdelweissFLTModelStatusRegisterChanged";
NSString* OREdelweissFLTModelFastWriteChanged = @"OREdelweissFLTModelFastWriteChanged";
NSString* OREdelweissFLTModelFiberDelaysChanged = @"OREdelweissFLTModelFiberDelaysChanged";
NSString* OREdelweissFLTModelStreamMaskChanged = @"OREdelweissFLTModelStreamMaskChanged";
NSString* OREdelweissFLTModelSelectFiberTrigChanged = @"OREdelweissFLTModelSelectFiberTrigChanged";
NSString* OREdelweissFLTModelBBv1MaskChanged = @"OREdelweissFLTModelBBv1MaskChanged";
NSString* OREdelweissFLTModelFiberEnableMaskChanged = @"OREdelweissFLTModelFiberEnableMaskChanged";
NSString* OREdelweissFLTModelFltModeFlagsChanged = @"OREdelweissFLTModelFltModeFlagsChanged";
NSString* OREdelweissFLTModelTargetRateChanged			= @"OREdelweissFLTModelTargetRateChanged";
NSString* OREdelweissFLTModelStoreDataInRamChanged		= @"OREdelweissFLTModelStoreDataInRamChanged";
NSString* OREdelweissFLTModelFilterLengthChanged		= @"OREdelweissFLTModelFilterLengthChanged";
NSString* OREdelweissFLTModelGapLengthChanged			= @"OREdelweissFLTModelGapLengthChanged";
NSString* OREdelweissFLTModelPostTriggerTimeChanged		= @"OREdelweissFLTModelPostTriggerTimeChanged";
NSString* OREdelweissFLTModelFifoBehaviourChanged		= @"OREdelweissFLTModelFifoBehaviourChanged";
NSString* OREdelweissFLTModelAnalogOffsetChanged		= @"OREdelweissFLTModelAnalogOffsetChanged";
NSString* OREdelweissFLTModelLedOffChanged				= @"OREdelweissFLTModelLedOffChanged";
NSString* OREdelweissFLTModelInterruptMaskChanged		= @"OREdelweissFLTModelInterruptMaskChanged";
NSString* OREdelweissFLTModelTModeChanged				= @"OREdelweissFLTModelTModeChanged";
NSString* OREdelweissFLTModelHitRateLengthChanged		= @"OREdelweissFLTModelHitRateLengthChanged";
NSString* OREdelweissFLTModelTriggersEnabledChanged		= @"OREdelweissFLTModelTriggersEnabledChanged";
NSString* OREdelweissFLTModelGainsChanged				= @"OREdelweissFLTModelGainsChanged";
NSString* OREdelweissFLTModelThresholdsChanged			= @"OREdelweissFLTModelThresholdsChanged";
NSString* OREdelweissFLTModelModeChanged				= @"OREdelweissFLTModelModeChanged";
NSString* OREdelweissFLTSettingsLock					= @"OREdelweissFLTSettingsLock";
NSString* OREdelweissFLTChan							= @"OREdelweissFLTChan";
NSString* OREdelweissFLTModelTestPatternsChanged		= @"OREdelweissFLTModelTestPatternsChanged";
NSString* OREdelweissFLTModelGainChanged				= @"OREdelweissFLTModelGainChanged";
NSString* OREdelweissFLTModelThresholdChanged			= @"OREdelweissFLTModelThresholdChanged";
NSString* OREdelweissFLTModelHitRateChanged				= @"OREdelweissFLTModelHitRateChanged";
NSString* OREdelweissFLTModelTestsRunningChanged		= @"OREdelweissFLTModelTestsRunningChanged";
NSString* OREdelweissFLTModelTestEnabledArrayChanged	= @"OREdelweissFLTModelTestEnabledChanged";
NSString* OREdelweissFLTModelTestStatusArrayChanged		= @"OREdelweissFLTModelTestStatusChanged";
NSString* OREdelweissFLTModelEventMaskChanged			= @"OREdelweissFLTModelEventMaskChanged";

NSString* OREdelweissFLTSelectedRegIndexChanged			= @"OREdelweissFLTSelectedRegIndexChanged";
NSString* OREdelweissFLTWriteValueChanged				= @"OREdelweissFLTWriteValueChanged";
NSString* OREdelweissFLTSelectedChannelValueChanged		= @"OREdelweissFLTSelectedChannelValueChanged";
NSString* OREdelweissFLTNoiseFloorChanged				= @"OREdelweissFLTNoiseFloorChanged";
NSString* OREdelweissFLTNoiseFloorOffsetChanged			= @"OREdelweissFLTNoiseFloorOffsetChanged";

static NSString* fltTestName[kNumEdelweissFLTTests]= {
	@"Run Mode",
	@"Ram",
	@"Threshold/Gain",
	@"Speed",
	@"Event",
};

// data for low-level page (IPE V4 electronic definitions)
enum IpeFLTV4Enum{
	kFLTV4StatusReg,
	kFLTV4ControlReg,
	kFLTV4CommandReg,
	kFLTV4VersionReg,
//HEAT	kFLTV4pVersionReg,
	kFLTV4BoardIDLsbReg,
	kFLTV4BoardIDMsbReg,
	kFLTV4InterruptMaskReg,
	kFLTV4InterruptRequestReg,
	/*kFLTV4HrMeasEnableReg,
	kFLTV4EventFifoStatusReg,
	kFLTV4PixelSettings1Reg,
	kFLTV4PixelSettings2Reg,
	kFLTV4RunControlReg,*/
	kFLTV4FiberSet_1Reg,
	kFLTV4FiberSet_2Reg,   
	kFLTV4StreamMask_1Reg,
	kFLTV4StreamMask_2Reg,
	kFLTV4TriggerMask_1Reg,
	kFLTV4TriggerMask_2Reg,
//	kFLTV4HistgrSettingsReg,
	kFLTV4Ion2HeatDelayReg,
	kFLTV4AccessTestReg,
//	kFLTV4SecondCounterReg,
    /*
	kFLTV4HrControlReg,
	kFLTV4HistMeasTimeReg,
	kFLTV4HistRecTimeReg,
	kFLTV4HistNumMeasReg,
	kFLTV4PostTrigger,
	*/
	kFLTV4RunControlReg,     	
	kFLTV4ThreshAdjustReg,   	
	kFLTV4HeatTriggPart1Reg, 	
	kFLTV4HeatTriggPart2Reg, 	
	kFLTV4IonTriggPart1Reg,		
	kFLTV4IonTriggPart2Reg,	
		
	kFLTV4ThresholdReg,

	kFLTV4TotalTriggerNReg,
		
	kFLTV4RAMDataReg,
	
	kFLTV4NumRegs //must be last
};

static IpeRegisterNamesStruct regV4[kFLTV4NumRegs] = {
	//2nd column is PCI register address shifted 2 bits to right (the two rightmost bits are always zero) -tb-
	{@"Status",				0x000000>>2,		-1,				kIpeRegReadable},
	{@"Control",			0x000004>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"Command",			0x000008>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"CFPGAVersion",		0x00000c>>2,		-1,				kIpeRegReadable},
//HEAT	{@"FPGA8Version",		0x000010>>2,		-1,				kIpeRegReadable},
	{@"BoardIDLSB",         0x000014>>2,		-1,				kIpeRegReadable},
	{@"BoardIDMSB",         0x000018>>2,		-1,				kIpeRegReadable},
	
	{@"InterruptMask",      0x00001C>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"InterruptRequest",   0x000020>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	/*
	{@"HrMeasEnable",       0x000024>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"EventFifoStatus",    0x00002C>>2,		-1,				kIpeRegReadable},
	{@"PixelSettings1",     0x000030>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"PixelSettings2",     0x000034>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"RunControl",         0x000038>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	*/
	{@"FiberSet_1",			0x000024>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"FiberSet_2",         0x000028>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"StreamMask_1",		0x00002C>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"StreamMask_2",		0x000030>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"TriggerMask_1",		0x000034>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"TriggerMask_2",      0x000038>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	
	//{@"HistgrSettings",     0x00003c>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"Ion2HeatDelay",      0x00003c>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"AccessTest",         0x000040>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},

//	{@"SecondCounter",      0x000044>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
    /*
	{@"HrControl",          0x000048>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HistMeasTime",       0x00004C>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HistRecTime",        0x000050>>2,		-1,				kIpeRegReadable},
	{@"HistNumMeas",         0x000054>>2,		-1,				kIpeRegReadable},
	{@"PostTrigger",		0x000058>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	*/
	{@"RunControl",         0x000048>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"ThreshAdjust",       0x00004C>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HeatTriggPart1",     0x000050>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HeatTriggPart2",     0x000054>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"IonTriggPart1",		0x000058>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"IonTriggPart2",		0x00005C>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},

	{@"Threshold",          0x002080>>2,		-1,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},
	
	{@"TotalTriggerN",		0x000084>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},

	{@"RAMData",		    0x003000>>2,		1024,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},

};

@interface OREdelweissFLTModel (private)
- (NSAttributedString*) test:(int)testName result:(NSString*)string color:(NSColor*)aColor;
- (void) enterTestMode;
- (void) leaveTestMode;
- (void) stepNoiseFloor;
@end

@implementation OREdelweissFLTModel

- (id) init
{
    self = [super init];
	ledOff = YES;
    return self;
}

- (void) dealloc
{	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [testEnabledArray release];
    [testStatusArray release];
	[testSuit release];
	[thresholds release];
	[gains release];
	[totalRate release];
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"EdelweissFLTCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"OREdelweissFLTController"];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORIpeV4CrateModel");
}

- (BOOL) partOfEvent:(short)chan
{
	return (eventMask & (1L<<chan)) != 0;
}

- (int) stationNumber
{
	//is it a minicrate?
	if([[[self crate] class]  isSubclassOfClass: NSClassFromString(@"ORIpeV4MiniCrateModel")]){
		if([self slot]<3)return [self slot]+1;
		else return [self slot]; //there is a gap at slot 3 (for the SLT) -tb-
	}
	//... or a full crate?
	if([[[self crate] class]  isSubclassOfClass: NSClassFromString(@"ORIpeV4CrateModel")]){
		if([self slot]<11)return [self slot]+1;
		else return [self slot]; //there is a gap at slot 11 (for the SLT) -tb-
	}
	//fallback
	return [self slot]+1;
}

- (ORTimeRate*) totalRate   { return totalRate; }
- (short) getNumberRegisters{ return kFLTV4NumRegs; }

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Accessors

- (int) swTriggerIsRepeating
{
    return swTriggerIsRepeating;
}

- (void) setSwTriggerIsRepeating:(int)aSwTriggerIsRepeating
{
    swTriggerIsRepeating = aSwTriggerIsRepeating;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelSwTriggerIsRepeatingChanged object:self];
}

- (int) repeatSWTriggerMode
{
    return repeatSWTriggerMode;
}

- (void) setRepeatSWTriggerMode:(int)aRepeatSWTriggerMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatSWTriggerMode:repeatSWTriggerMode];
    
    repeatSWTriggerMode = aRepeatSWTriggerMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelRepeatSWTriggerModeChanged object:self];
}

- (uint32_t) controlRegister
{
    return controlRegister;
}

- (void) setControlRegister:(uint32_t)aControlRegister
{
    [[[self undoManager] prepareWithInvocationTarget:self] setControlRegister:controlRegister];
	
    controlRegister = aControlRegister;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelControlRegisterChanged object:self];
	
	//TODO: OREdelweissFLTModelControlRegisterChanged
	//replaced
	//OREdelweissFLTModelFiberEnableMaskChanged, OREdelweissFLTModelSelectFiberTrigChanged
}

- (int) statusLatency
{    return (controlRegister >> kEWFlt_ControlReg_StatusLatency_Shift) & kEWFlt_ControlReg_StatusLatency_Mask;   }

- (void) setStatusLatency:(int)aValue
{
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_StatusLatency_Mask << kEWFlt_ControlReg_StatusLatency_Shift);
    cr = cr | ((aValue & kEWFlt_ControlReg_StatusLatency_Mask) << kEWFlt_ControlReg_StatusLatency_Shift);
	[self setControlRegister:cr];
}

- (int) vetoFlag
{    return (controlRegister >> kEWFlt_ControlReg_VetoFlag_Shift) & kEWFlt_ControlReg_VetoFlag_Mask;   }

- (void) setVetoFlag:(int)aValue
{
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_VetoFlag_Mask << kEWFlt_ControlReg_VetoFlag_Shift);
    cr = cr | ((aValue & kEWFlt_ControlReg_VetoFlag_Mask) << kEWFlt_ControlReg_VetoFlag_Shift);
	[self setControlRegister:cr];
}



- (int) selectFiberTrig
{
    uint32_t aselectFiberTrig = (controlRegister >> kEWFlt_ControlReg_SelectFiber_Shift) & kEWFlt_ControlReg_SelectFiber_Mask;
    return aselectFiberTrig;
}

- (void) setSelectFiberTrig:(int)aSelectFiberTrig
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setSelectFiberTrig:selectFiberTrig];
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_SelectFiber_Mask << kEWFlt_ControlReg_SelectFiber_Shift);
    selectFiberTrig = aSelectFiberTrig;
    cr = cr | ((selectFiberTrig & kEWFlt_ControlReg_SelectFiber_Mask) << kEWFlt_ControlReg_SelectFiber_Shift);
	[self setControlRegister:cr];
    //[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelSelectFiberTrigChanged object:self];
}

- (int) BBv1Mask
{    return (controlRegister >> kEWFlt_ControlReg_BBv1_Shift) & kEWFlt_ControlReg_BBv1_Mask;   }
//{
//    return BBv1Mask;
//}

- (BOOL) BBv1MaskForChan:(int)i
{
    return ([self BBv1Mask] & (0x1 <<i)) != 0;
}

//TODO: OREdelweissFLTModelBBv1MaskChanged and BBv1Mask obsolete -tb-
- (void) setBBv1Mask:(int)aBBv1Mask
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setBBv1Mask:BBv1Mask];
    //BBv1Mask = aBBv1Mask;
    //[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelBBv1MaskChanged object:self];
    BBv1Mask = aBBv1Mask;
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_BBv1_Mask << kEWFlt_ControlReg_BBv1_Shift);
    cr = cr | ((aBBv1Mask & kEWFlt_ControlReg_BBv1_Mask) << kEWFlt_ControlReg_BBv1_Shift);
	[self setControlRegister:cr];
}

- (int) fiberEnableMask
{    return (controlRegister >> kEWFlt_ControlReg_FiberEnable_Shift) & kEWFlt_ControlReg_FiberEnable_Mask;   }
//{    return fiberEnableMask;}

- (int) fiberEnableMaskForChan:(int)i
{
    return ([self fiberEnableMask] & (0x1 <<i)) != 0;
}

//TODO: OREdelweissFLTModelFiberEnableMaskChanged and fiberEnableMask obsolete -tb-
- (void) setFiberEnableMask:(int)aFiberEnableMask
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setFiberEnableMask:fiberEnableMask];
    //fiberEnableMask = aFiberEnableMask;
    //[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFiberEnableMaskChanged object:self];
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_FiberEnable_Mask << kEWFlt_ControlReg_FiberEnable_Shift);
    fiberEnableMask = aFiberEnableMask;
    cr = cr | ((aFiberEnableMask & kEWFlt_ControlReg_FiberEnable_Mask) << kEWFlt_ControlReg_FiberEnable_Shift);
	[self setControlRegister:cr];
}

- (int) fltModeFlags // this are the flags 4-6 -tb-
{    return (controlRegister >> kEWFlt_ControlReg_ModeFlags_Shift) & kEWFlt_ControlReg_ModeFlags_Mask;   }
//{    return fltModeFlags;}

- (void) setFltModeFlags:(int)aFltModeFlags
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setFltModeFlags:fltModeFlags];
    //fltModeFlags = aFltModeFlags;
    //[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFltModeFlagsChanged object:self];
    fltModeFlags = aFltModeFlags;
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_ModeFlags_Mask << kEWFlt_ControlReg_ModeFlags_Shift);
    cr = cr | ((aFltModeFlags & kEWFlt_ControlReg_ModeFlags_Mask) << kEWFlt_ControlReg_ModeFlags_Shift);
	[self setControlRegister:cr];
}




- (int) totalTriggerNRegister
{
    return totalTriggerNRegister;
}

- (void) setTotalTriggerNRegister:(int)aTotalTriggerNRegister
{
    totalTriggerNRegister = aTotalTriggerNRegister;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTotalTriggerNRegisterChanged object:self];
}

- (uint32_t) statusRegister
{
    return statusRegister;
}

- (void) setStatusRegister:(uint32_t)aStatusRegister
{
    statusRegister = aStatusRegister;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelStatusRegisterChanged object:self];
}

- (int) fastWrite
{
    return fastWrite;
}

- (void) setFastWrite:(int)aFastWrite
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFastWrite:fastWrite];
    
    fastWrite = aFastWrite;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFastWriteChanged object:self];
}

- (uint64_t) fiberDelays
{
    return fiberDelays;
}

- (void) setFiberDelays:(uint64_t)aFiberDelays
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFiberDelays:fiberDelays];
    
    if(fastWrite){ 
	    //if(fiberDelays != aFiberDelays)
		{
            fiberDelays = aFiberDelays;
		    [self writeFiberDelays];
		}
	}else{
		fiberDelays = aFiberDelays;
	}

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFiberDelaysChanged object:self];
}

- (uint64_t) streamMask
{
    return streamMask;
}

- (uint32_t) streamMask1
{
    uint32_t val=0;
	val = streamMask & 0xffffffffLL;
	return (uint32_t)val;
}

- (uint32_t) streamMask2
{
    uint32_t val;
	val = (streamMask & 0xffffffff00000000LL) >> 32;
	return val;
}

- (int) streamMaskForFiber:(int)aFiber chan:(int)aChan
{
    uint64_t mask = ((0x1LL<<aChan) << (aFiber*8));
	return ((streamMask & mask) !=0);
}


- (void) setStreamMask:(uint64_t)aStreamMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStreamMask:streamMask];
    
    streamMask = aStreamMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelStreamMaskChanged object:self];
}

//- (void) setStreamMaskForFiber:(int)aFiber chan:(int)aChan value:(BOOL)val
//{
//}




- (int) targetRate { return targetRate; }
- (void) setTargetRate:(int)aTargetRate
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTargetRate:targetRate];
    targetRate = [self restrictIntValue:aTargetRate min:1 max:100];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTargetRateChanged object:self];
}



- (int) runMode { return runMode; }
- (void) setRunMode:(int)aRunMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunMode:runMode];
    runMode = aRunMode;
	
	readWaveforms = YES;
	
            //DEBUG OUTPUT:
 	        NSLog(@"%@::%@: mode 0x%016llx \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),runMode);//TODO: DEBUG testing ...-tb-
	
	switch (runMode) {
		case kIpeFltV4_EventDaqMode:
			//TODO: [self setFltRunMode:kIpeFltV4Katrin_Run_Mode];
       	    readWaveforms = YES;
			break;
			
		case kIpeFltV4_MonitoringDaqMode:
			//TODO: [self setFltRunMode:kIpeFltV4Katrin_Run_Mode];
			break;
			
#if 0
		case kIpeFltV4_EnergyDaqMode:
			[self setFltRunMode:kIpeFltV4Katrin_Run_Mode];
			break;
			
		case kIpeFltV4_EnergyTraceDaqMode:
			[self setFltRunMode:kIpeFltV4Katrin_Run_Mode];
			readWaveforms = YES;
			break;
			
		case kIpeFltV4_Histogram_DaqMode:
			[self setFltRunMode:kIpeFltV4Katrin_Histo_Mode];
			//TODO: workaround - if set to kFifoStopOnFull the histogramming stops after some seconds - probably a FPGA bug? -tb-
			if(fifoBehaviour == kFifoStopOnFull){
				//NSLog(@"OREdelweissFLTModel message: due to a FPGA side effect histogramming mode should run with kFifoEnableOverFlow setting! -tb-\n");//TODO: fix it -tb-
				NSLog(@"OREdelweissFLTModel message: switched FIFO behaviour to kFifoEnableOverFlow (required for histogramming mode)\n");//TODO: fix it -tb-
				[self setFifoBehaviour: kFifoEnableOverFlow];
			}
			break;
#endif			
		default:
			break;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelModeChanged object:self];
}

- (BOOL) noiseFloorRunning { return noiseFloorRunning; }

- (int) noiseFloorOffset { return noiseFloorOffset; }
- (void) setNoiseFloorOffset:(int)aNoiseFloorOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseFloorOffset:noiseFloorOffset];
    noiseFloorOffset = aNoiseFloorOffset;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTNoiseFloorOffsetChanged object:self];
}



- (BOOL) storeDataInRam { return storeDataInRam; }
- (void) setStoreDataInRam:(BOOL)aStoreDataInRam
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStoreDataInRam:storeDataInRam];
    storeDataInRam = aStoreDataInRam;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelStoreDataInRamChanged object:self];
}

- (int) filterLength { return filterLength; }
- (void) setFilterLength:(int)aFilterLength
{
	if(aFilterLength == 6 && gapLength>0){
		[self setGapLength:0];
		NSLog(@"Warning: setFilterLength: FLTv4: maximum filter length allows only gap length of 0. Gap length reset to 0!\n");
	}
    [[[self undoManager] prepareWithInvocationTarget:self] setFilterLength:filterLength];
    filterLength = [self restrictIntValue:aFilterLength min:2 max:8];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFilterLengthChanged object:self];
}

- (int) gapLength { return gapLength; }
- (void) setGapLength:(int)aGapLength
{
	if(filterLength == 6 && aGapLength>0){
		aGapLength=0;
		NSLog(@"Warning: setGapLength: FLTv4: maximum filter length allows only gap length of 0. Gap length reset to 0!\n");
	}
    [[[self undoManager] prepareWithInvocationTarget:self] setGapLength:gapLength];
    gapLength = [self restrictIntValue:aGapLength min:0 max:7];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelGapLengthChanged object:self];
}

- (unsigned long) postTriggerTime { return postTriggerTime; }
- (void) setPostTriggerTime:(unsigned long)aPostTriggerTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerTime:postTriggerTime];
    postTriggerTime = [self restrictIntValue:aPostTriggerTime min:6 max:2047];//min 6 is found 'experimental' -tb-
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelPostTriggerTimeChanged object:self];
}

- (int) fifoBehaviour { return fifoBehaviour; }
- (void) setFifoBehaviour:(int)aFifoBehaviour
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFifoBehaviour:fifoBehaviour];
    fifoBehaviour = [self restrictIntValue:aFifoBehaviour min:0 max:1];;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFifoBehaviourChanged object:self];
}

- (unsigned long) eventMask { return eventMask; }
- (void) eventMask:(unsigned long)aMask
{
	eventMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelEventMaskChanged object:self];
}

- (int) analogOffset{ return analogOffset; }
- (void) setAnalogOffset:(int)aAnalogOffset
{
	
    [[[self undoManager] prepareWithInvocationTarget:self] setAnalogOffset:analogOffset];
    analogOffset = [self restrictIntValue:aAnalogOffset min:0 max:4095];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelAnalogOffsetChanged object:self];
}

- (BOOL) ledOff{ return ledOff; }
- (void) setLedOff:(BOOL)aState
{
    ledOff = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelLedOffChanged object:self];
}

- (unsigned long) interruptMask { return interruptMask; }
- (void) setInterruptMask:(unsigned long)aInterruptMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    interruptMask = aInterruptMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelInterruptMaskChanged object:self];
}

- (void) setTotalRate:(ORTimeRate*)newTimeRate
{
	[totalRate autorelease];
	totalRate=[newTimeRate retain];
}

- (unsigned short) hitRateLength { return hitRateLength; }
- (void) setHitRateLength:(unsigned short)aHitRateLength
{	
    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateLength:hitRateLength];
    hitRateLength = [self restrictIntValue:aHitRateLength min:0 max:6]; //0->1sec, 1->2, 2->4 .... 6->32sec

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelHitRateLengthChanged object:self];
}


- (NSMutableArray*) gains { return gains; }
- (void) setGains:(NSMutableArray*)aGains
{
	[aGains retain];
	[gains release];
    gains = aGains;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelGainsChanged object:self];
}

- (NSMutableArray*) thresholds { return thresholds; }
- (void) setThresholds:(NSMutableArray*)aThresholds
{
	[aThresholds retain];
	[thresholds release];
    thresholds = aThresholds;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelThresholdsChanged object:self];
}

-(unsigned long) threshold:(unsigned short) aChan
{
    return [[thresholds objectAtIndex:aChan] intValue];
}

-(unsigned short) gain:(unsigned short) aChan
{
    return [[gains objectAtIndex:aChan] shortValue];
}

-(void) setThreshold:(unsigned short) aChan withValue:(unsigned long) aThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
	aThreshold = [self restrictIntValue:aThreshold min:0 max:0xfffff];
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aThreshold]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: OREdelweissFLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:OREdelweissFLTModelThresholdChanged
	 object:self
	 userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain
{
	if(aGain>0xfff) aGain = 0xfff;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:aChan withValue:[self gain:aChan]];
	[gains replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aGain]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: OREdelweissFLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:OREdelweissFLTModelGainChanged
	 object:self
	 userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

-(BOOL) triggerEnabled:(unsigned short) aChan
{
//TODO: triggerEnabled UNDER CONSTRUCTION -tb- 2012-07-19
//TODO: triggerEnabled UNDER CONSTRUCTION -tb- 2012-07-19
	//if(aChan<kNumV4FLTChannels)return (triggerEnabledMask >> aChan) & 0x1;
	//else 
	return NO;
}

-(void) setTriggerEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
//TODO: setTriggerEnabled UNDER CONSTRUCTION -tb- 2012-07-19
//TODO: setTriggerEnabled UNDER CONSTRUCTION -tb- 2012-07-19
#if 0
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerEnabled:aChan withValue:(triggerEnabledMask>>aChan)&0x1];
	if(aState) triggerEnabledMask |= (1L<<aChan);
	else triggerEnabledMask &= ~(1L<<aChan);
	
    [[NSNotificationCenter defaultCenter]postNotificationName:OREdelweissFLTModelTriggerEnabledMaskChanged object:self];
	[self postAdcInfoProvidingValueChanged];
#endif
}



- (void) enableAllHitRates:(BOOL)aState
{
	//TODO: [self setHitRateEnabledMask:aState?0xffffff:0x0];
}

- (void) enableAllTriggers:(BOOL)aState
{
	//TODO: [self setTriggerEnabledMask:aState?0xffffff:0x0];
}

- (void) setHitRateTotal:(float)newTotalValue
{
	hitRateTotal = newTotalValue;
	if(!totalRate){
		[self setTotalRate:[[[ORTimeRate alloc] init] autorelease]];
	}
	[totalRate addDataToTimeAverage:hitRateTotal];
}

- (float) hitRateTotal 
{ 
	return hitRateTotal; 
}

- (float) hitRate:(unsigned short)aChan
{
	if(aChan<kNumV4FLTChannels){
		return hitRate[aChan];
	}
	else return 0.0;
}



- (float) rate:(int)aChan { return [self hitRate:aChan]; }
- (BOOL) hitRateOverFlow:(unsigned short)aChan
{
	if(aChan<kNumV4FLTChannels)return hitRateOverFlow[aChan];
	else return NO;
}

- (unsigned short) selectedChannelValue { return selectedChannelValue; }
- (void) setSelectedChannelValue:(unsigned short) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedChannelValue:selectedChannelValue];
    selectedChannelValue = aValue;
    [[NSNotificationCenter defaultCenter]	 postNotificationName:OREdelweissFLTSelectedChannelValueChanged	 object:self];
}

- (unsigned short) selectedRegIndex { return selectedRegIndex; }
- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:selectedRegIndex];
    selectedRegIndex = anIndex;
    [[NSNotificationCenter defaultCenter]	 postNotificationName:OREdelweissFLTSelectedRegIndexChanged	 object:self];
}

- (unsigned long) writeValue { return writeValue; }
- (void) setWriteValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    writeValue = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTWriteValueChanged object:self];
}

- (NSString*) getRegisterName: (short) anIndex
{
    return regV4[anIndex].regName;
}

- (unsigned long) getAddressOffset: (short) anIndex
{
    return( regV4[anIndex].addressOffset );
}

- (short) getAccessType: (short) anIndex
{
	return regV4[anIndex].accessType;
}

- (void) setToDefaults
{
//TODO: setToDefaults UNDER CONSTRUCTION -tb-
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		[self setThreshold:i withValue:17000];
		[self setGain:i withValue:0];
	}
	[self setGapLength:0];
	[self setFilterLength:6];
	[self setFifoBehaviour:kFifoEnableOverFlow];// kFifoEnableOverFlow or kFifoStopOnFull
	[self setPostTriggerTime:300]; // max. filter length should fit into the range -tb-
	
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢HW Access
- (unsigned long) readBoardIDLow
{
	unsigned long value = [self readReg:kFLTV4BoardIDLsbReg];
	return value;
}

- (unsigned long) readBoardIDHigh
{
	unsigned long value = [self readReg:kFLTV4BoardIDMsbReg];
	return value;
}

- (int) readSlot
{
	return ([self readReg:kFLTV4BoardIDMsbReg]>>24) & 0x1F;
}

- (unsigned long)  readVersion
{	
	return [self readReg: kFLTV4VersionReg];
}



- (int) readMode
{
	return ([self readControl]>>16) & 0xf;
}

- (void) loadThresholdsAndGains
{
//TODO: loadThresholdsAndGains UNDER CONSTRUCTION -tb- 2012-07-19
//TODO: loadThresholdsAndGains UNDER CONSTRUCTION -tb- 2012-07-19
#if 0
	//use the command list to load all the thresholds and gains with one PMC command packet
	int i;
	ORCommandList* aList = [ORCommandList commandList];
	for(i=0;i<kNumV4FLTChannels;i++){
		unsigned long thres;
		if( !(triggerEnabledMask & (0x1<<i)) )	thres = 0xfffff;
		else									thres = [self threshold:i];
		[aList addCommand: [self writeRegCmd:kFLTV4ThresholdReg channel:i value:thres & 0xFFFFF]];
		[aList addCommand: [self writeRegCmd:kFLTV4GainReg channel:i value:[self gain:i] & 0xFFF]];
	}
	[aList addCommand: [self writeRegCmd:kFLTV4CommandReg value:kIpeFlt_Cmd_LoadGains]];
	
	[self executeCommandList:aList];
    
#endif
}

- (int) restrictIntValue:(int)aValue min:(int)aMinValue max:(int)aMaxValue
{
	if(aValue<aMinValue)	  return aMinValue;
	else if(aValue>aMaxValue) return aMaxValue;
	else					  return aValue;
}

- (float) restrictFloatValue:(int)aValue min:(float)aMinValue max:(float)aMaxValue
{
	if(aValue<aMinValue)	  return aMinValue;
	else if(aValue>aMaxValue) return aMaxValue;
	else					  return aValue;
}

- (void) enableStatistics
{
#if (0)
    unsigned long aValue;
	bool enabled = true;
	unsigned long adc_guess = 150;			// This are parameter that work with the standard Auger-type boards
	unsigned long n = 65000;				// There is not really a need to make them variable. ak 7.10.07
	
    aValue =     (  ( (unsigned long) (enabled  &   0x1) ) << 31)
	| (  ( (unsigned long) (adc_guess   & 0x3ff) ) << 16)
	|    ( (unsigned long) ( (n-1)  & 0xffff) ) ; // 16 bit !
	
	// Broadcast to all channel	(pseudo channel 0x1f)     
	[self writeReg:kFLTStaticSetReg channel:0x1f value:aValue]; 
	
	// Save parameter for calculation of mean and variance
	statisticOffset = adc_guess;
	statisticN = n;
#endif
}


- (void) getStatistics:(int)aChannel mean:(double *)aMean  var:(double *)aVar 
{
#if (0)
    unsigned long data;
	signed long sum;
    unsigned long sumSq;
	
    // Read Statistic parameter
    data = [self  readReg:kFLTStaticSetReg channel:aChannel];
	statisticOffset = (data  >> 16) & 0x3ff;
	statisticN = (data & 0xffff) +1;
	
	
    // Read statistics
	// The sum is a 25bit signed number.
	sum = [self readReg:kFLTSumXReg channel:aChannel];
	// Move the sign
	sum = (sum & 0x01000000) ? (sum | 0xFE000000) : (sum & 0x00FFFFFF);
	
    // Read the sum of squares	
	sumSq = [self readReg:kFLTSumX2Reg channel:aChannel];
	
	//NSLog(@"data = %x Offset = %d, n = %d, sum = %08x, sum2 = %08x\n", data, statisticOffset, statisticN, sum, sumSq);
	
	// Calculate mean and variance
	if (statisticN > 0){
		*aMean = (double) sum / statisticN + statisticOffset;
		*aVar = (double) sumSq / statisticN 
		- (double) sum / statisticN * sum / statisticN;
    } else {
		*aMean = -1; 
		*aVar = -1;
	}
#endif
}


- (void) initBoard
{
	[self writeControl];
	[self writeStreamMask];//TODO: is this necessary? we want event mode but this is for stream mode -tb-
	[self writeFiberDelays];
	[self loadThresholdsAndGains]; //TODO:
	//!!!: xxx
	//???: yyy
	[self writeTriggerControl];			//TODO:   (for v4 this needs to be implemented by DENIS)-tb- //set trigger mask
	[self enableStatistics];			//TODO: OBSOLETE -tb- enable hardware ADC statistics, ak 7.1.07
	
}

- (unsigned long) readStatus
{
    unsigned long status = [self readReg: kFLTV4StatusReg ];
 	NSLog(@"%@::%@ status: 0x%08x\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),status);//TODO: DEBUG testing ...-tb-
	[self setStatusRegister:status];
	return status;
}

- (unsigned long) readTotalTriggerNRegister 
{
    unsigned long n = [self readReg: kFLTV4TotalTriggerNReg ];
 	NSLog(@"%@::%@ status: 0x%08x\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),n);//TODO: DEBUG testing ...-tb-
	[self setTotalTriggerNRegister: n ];
	return n;
}

- (unsigned long) readControl
{
	return [self readReg: kFLTV4ControlReg];
}

//TODO: OBSOLETE for EW - remove it! -tb-
//TODO: better use the STANDBY flag of the FLT -tb- 2010-01-xx     !!!!!!!!!!!!!!!!!
- (void) writeRunControl:(BOOL)startSampling
{
	unsigned long aValue = 
	((filterLength & 0xf)<<8)		| 
	((gapLength & 0xf)<<4)			| 
	// -tb- ((runBoxCarFilter & 0x1)<<2)	|
	((startSampling & 0x1)<<3)		|		// run trigger unit
	((startSampling & 0x1)<<2)		|		// run filter unit
	((startSampling & 0x1)<<1)      |		// start ADC sampling
	 (startSampling & 0x1);					// store data in QDRII RAM
	
	[self writeReg:kFLTV4RunControlReg value:aValue];					
}

- (void) writeControl
{
    #if 0
	//unsigned long aValue =	((fltRunMode & 0xf)<<16) | 
	//((fifoBehaviour & 0x1)<<24) |
	//((ledOff & 0x1)<<1 );
	unsigned long aMode = 0;
	switch(fltModeFlags){
	case 0: //Normal
	    aMode = 0x0;
	    break;
	case 1: //TM-Order
	    aMode = 0x1;
	    break;
	case 2: //TM-Ramp
	    aMode = 0x2;
	    break;
	case 3: //TM-PB
	    aMode = 0x4;
	    break;
	}	

	
	unsigned long aValue =	
	((selectFiberTrig & 0x7)<<28) | 
	((fiberEnableMask & 0x3f)<<16) |
	((BBv1Mask & 0x3f)<<8 ) |
	((aMode & 0x7)<<4 );
	#endif
	
	unsigned long aValue =	controlRegister;
//DEBUG OUTPUT:
 	NSLog(@"%@::%@:   kFLTV4ControlReg: 0x%08x \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aValue);//TODO: DEBUG testing ...-tb-
    //DEBUG OUTPUT: 	NSLog(@"%@::%@:   selectFiberTrig: 0x%08x \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),selectFiberTrig);//TODO: DEBUG testing ...-tb-
	
	[self writeReg: kFLTV4ControlReg value:aValue];
}

- (void) writeStreamMask
{
    //NSLog(@"%@::%@:   kFLTV4ControlReg: 0x%016qx \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self streamMask]);//TODO: DEBUG testing ...-tb-
	unsigned long aValue =	[self streamMask1];
	[self writeReg: kFLTV4StreamMask_1Reg value:aValue];
	aValue =	[self streamMask2];
	[self writeReg: kFLTV4StreamMask_2Reg value:aValue];
}



- (void) writeFiberDelays
{
 	//NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG testing ...-tb-
    uint32_t val=0;
	val = fiberDelays & 0xffffffffLL;
	[self writeReg: kFLTV4FiberSet_1Reg value:val];
	val = (fiberDelays & 0xffffffff00000000LL) >> 32;
	[self writeReg: kFLTV4FiberSet_2Reg value:val];
}

- (void) readFiberDelays
{
    //DEBUG OUTPUT:
 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG testing ...-tb-
    uint64_t fiberDelays1=[self readReg: kFLTV4FiberSet_1Reg];
    uint64_t fiberDelays2=[self readReg: kFLTV4FiberSet_2Reg];
	uint64_t thefiberDelays = (fiberDelays2 << 32) | fiberDelays1;
	[self setFiberDelays: thefiberDelays];
}


- (void) writeCommandResync
{	[self writeReg: kFLTV4CommandReg value:kIpeFlt_Cmd_resync];   }

- (void) writeCommandTrigEvCounterReset
{	[self writeReg: kFLTV4CommandReg value:kIpeFlt_Cmd_TrigEvCountRes];   }

- (void) writeCommandSoftwareTrigger
{	[self writeReg: kFLTV4CommandReg value:kIpeFlt_Cmd_SWTrig];   }

- (void) readTriggerData
{
//DEBUG OUTPUT:
 	NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
    unsigned long totalTriggerN = [self readReg:kFLTV4TotalTriggerNReg];
 	NSLog(@" totalTriggerN: %i\n",totalTriggerN);//TODO: DEBUG testing ...-tb-
 	NSLog(@" selectFiberTrig: %i\n",selectFiberTrig);//TODO: DEBUG testing ...-tb-
	int num=5;
	int chan = 0;
	int i;
	unsigned long adcval;
for(chan=0; chan<6;chan++)
	for (i=0; i<num; i++) {
		 adcval = [self readReg:kFLTV4RAMDataReg channel: chan index:i];
 	    NSLog(@" adcval chan: %i index %i: 0x%08x\n",chan,i,adcval);//TODO: DEBUG testing ...-tb-

	}
}

- (unsigned long) regAddress:(int)aReg channel:(int)aChannel index:(int)index
{
	return (([self stationNumber] << 17) | (aChannel << 12)   | regV4[aReg].addressOffset) + index; //TODO: the channel ... -tb-   | ((aChannel&0x01f)<<kIpeFlt_ChannelAddress)
}

- (unsigned long) regAddress:(int)aReg channel:(int)aChannel
{
	return ([self stationNumber] << 17) | (aChannel << 12)   | regV4[aReg].addressOffset; //TODO: the channel ... -tb-   | ((aChannel&0x01f)<<kIpeFlt_ChannelAddress)
}

- (unsigned long) regAddress:(int)aReg
{
	
	return ([self stationNumber] << 17) |  regV4[aReg].addressOffset; //TODO: NEED <<17 !!! -tb-
}

- (unsigned long) adcMemoryChannel:(int)aChannel page:(int)aPage
{
	//TODO:  replace by V4 code -tb-
    //adc access now is very different from v3 -tb-
	return 0;
    //TODO: obsolete (v3) -tb-
	return ([self slot] << 24) | (0x2 << kIpeFlt_AddressSpace) | (aChannel << kIpeFlt_ChannelAddress)	| (aPage << kIpeFlt_PageNumber);
}

- (unsigned long) readReg:(int)aReg
{
	return [self read: [self regAddress:aReg]];
}

- (unsigned long) readReg:(int)aReg channel:(int)aChannel
{
	return [self read:[self regAddress:aReg channel:aChannel]];
}

- (unsigned long) readReg:(int)aReg channel:(int)aChannel  index:(int)aIndex
{
	return [self read:[self regAddress:aReg channel:aChannel index:aIndex]];
}

- (void) writeReg:(int)aReg value:(unsigned long)aValue
{
	[self write:[self regAddress:aReg] value:aValue];
}

- (void) writeReg:(int)aReg channel:(int)aChannel value:(unsigned long)aValue
{
	[self write:[self regAddress:aReg channel:aChannel] value:aValue];
}

- (void) writeThreshold:(int)i value:(unsigned int)aValue
{
	aValue &= 0xfffff;
	[self writeReg: kFLTV4ThresholdReg channel:i value:aValue];
}

- (unsigned int) readThreshold:(int)i
{
	return [self readReg:kFLTV4ThresholdReg channel:i] & 0xfffff;
}


- (void) writeTestPattern:(unsigned long*)mask length:(int)len
{
	[self rewindTestPattern];
	[self writeNextPattern:0];
	int i;
	for(i=0;i<len;i++){
		[self writeNextPattern:mask[i]];
		NSLog(@"%d: %@\n",i,mask[i]?@".":@"-");
	}
	[self rewindTestPattern];
}

- (void) rewindTestPattern
{
#if (0)
    //TODO: obsolete (v3) -tb-
	[self writeReg:kFLTTestPulsMemReg value: kIpeFlt_TP_Control | kIpeFlt_TestPattern_Reset];
	
#endif
}

- (void) writeNextPattern:(unsigned long)aValue
{
#if (0)
    //TODO: obsolete (v3) -tb-
	[self writeReg:kFLTTestPulsMemReg value:aValue];
#endif
}

- (void) clear:(int)aChan page:(int)aPage value:(unsigned short)aValue
{
	unsigned long aPattern;
	
	aPattern =  aValue;
	aPattern = ( aPattern << 16 ) + aValue;
	
	// While emulating the block transfer by a loop of single transfers
	// it is nec. to increment the address pointer by 2
	[self clearBlock:[self adcMemoryChannel:aChan page:aPage]
			 pattern:aPattern
			  length:kIpeFlt_Page_Size / 2
		   increment:2];
}

- (void) writeMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{
	[self writeBlock: [self adcMemoryChannel:aChan page:aPage] 
		  dataBuffer: (unsigned long*)aPageBuffer
			  length: kIpeFlt_Page_Size/2
		   increment: 2];
}

- (void) readMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{
	
	[self readBlock: [self adcMemoryChannel:aChan page:aPage]
		 dataBuffer: (unsigned long*)aPageBuffer
			 length: kIpeFlt_Page_Size/2
		  increment: 2];
}

- (unsigned long) readMemoryChan:(int)aChan page:(int)aPage
{
	return [self read:[self adcMemoryChannel:aChan page:aPage]];
}


- (void) writeInterruptMask
{
	[self writeReg:kFLTV4InterruptMaskReg value:interruptMask];
}



- (void) writeTriggerControl  //TODO: must be handled by readout, single pixels cannot be disabled for KATRIN ; this is fixed now, remove workaround after all crates are updated -tb-
{
//TODO: writeTriggerControl UNDER CONSTRUCTION -tb- 2012-07-19
//TODO: writeTriggerControl UNDER CONSTRUCTION -tb- 2012-07-19
//TODO: writeTriggerControl UNDER CONSTRUCTION -tb- 2012-07-19
    //PixelSetting....
	//2,1:
	//0,0 Normal
	//0,1 test pattern
	//1,0 always 0
	//1,1 always 1
	//[self writeReg:kFLTV4PixelSettings1Reg value:0]; //must be handled by readout, single pixels cannot be disabled for KATRIN - OK, FIRMWARE FIXED -tb-
	//uint32_t mask = (~triggerEnabledMask) & 0xffffff;
	//[self writeReg:kFLTV4PixelSettings2Reg value: mask];
}

- (void) readHitRates
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
	
//TODO: readHitRates UNDER CONSTRUCTION -tb- 2012-07-19
//TODO: readHitRates UNDER CONSTRUCTION -tb- 2012-07-19
#if 0
	@try {
		
		BOOL oneChanged = NO;
		float newTotal = 0;
		int chan;
        int hitRateLengthSec = 1<<hitRateLength;
		float freq = 1.0/((double)hitRateLengthSec);
				
		unsigned long location = (([self crateNumber]&0x1e)<<21) | ([self stationNumber]& 0x0000001f)<<16;
		unsigned long data[5 + kNumV4FLTChannels];
		
		//combine all the hitrate read commands into one command packet
		ORCommandList* aList = [ORCommandList commandList];
		for(chan=0;chan<kNumV4FLTChannels;chan++){
			if(hitRateEnabledMask & (1L<<chan)){
				[aList addCommand: [self readRegCmd:kFLTV4HitRateReg channel:chan]];
			}
		}
		
		[self executeCommandList:aList];
		
		//put the synchronized around this code to test if access to the hitrates is thread safe
		//pull out the result
		int dataIndex = 0;
		for(chan=0;chan<kNumV4FLTChannels;chan++){
			if(hitRateEnabledMask & (1L<<chan)){
				unsigned long aValue = [aList longValueForCmd:dataIndex];
				BOOL overflow = (aValue >> 31) & 0x1;
				aValue = aValue & 0x7fffffff;
				if(aValue != hitRate[chan] || overflow != hitRateOverFlow[chan]){
					if (hitRateLengthSec!=0)	hitRate[chan] = aValue * freq;
					//if (hitRateLengthSec!=0)	hitRate[chan] = aValue; 
					else					    hitRate[chan] = 0;
					
					if(hitRateOverFlow[chan])hitRate[chan] = 0;
					hitRateOverFlow[chan] = overflow;
					
					oneChanged = YES;
				}
				if(!hitRateOverFlow[chan]){
					newTotal += hitRate[chan];
				}
				data[dataIndex + 5] = ((chan&0xff)<<20) | ((overflow&0x1)<<16) | aValue;// the hitrate may have more than 16 bit in the future -tb-
				dataIndex++;
			}
		}
		
		if(dataIndex>0){
			time_t	ut_time;
			time(&ut_time);

			data[0] = hitRateId | (dataIndex + 5); 
			data[1] = location;
			data[2] = ut_time;	
			data[3] = hitRateLengthSec;	
			data[4] = newTotal;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(long)*(dataIndex + 5)]];
			
		}
		
		[self setHitRateTotal:newTotal];
		
		if(oneChanged){
		    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelHitRateChanged object:self];
		}
	}
	@catch(NSException* localException) {
	}
	
	[self performSelector:@selector(readHitRates) withObject:nil afterDelay:(1<<[self hitRateLength])];


#endif
}





//------------------
//command Lists
- (void) executeCommandList:(ORCommandList*)aList
{
	[[[self crate] adapter] executeCommandList:aList];
}

- (id) readRegCmd:(unsigned long) aRegister channel:(short) aChannel
{
	unsigned long theAddress = [self regAddress:aRegister channel:aChannel];
	return [[[self crate] adapter] readHardwareRegisterCmd:theAddress];		
}

- (id) readRegCmd:(unsigned long) aRegister
{
	return [[[self crate] adapter] readHardwareRegisterCmd:[self regAddress:aRegister]];		
}

- (id) writeRegCmd:(unsigned long) aRegister channel:(short) aChannel value:(unsigned long)aValue
{
	unsigned long theAddress = [self regAddress:aRegister channel:aChannel];
	return [[[self crate] adapter] writeHardwareRegisterCmd:theAddress value:aValue];		
}

- (id) writeRegCmd:(unsigned long) aRegister value:(unsigned long)aValue
{
	return [[[self crate] adapter] writeHardwareRegisterCmd:[self regAddress:aRegister] value:aValue];		
}
//------------------





- (NSString*) rateNotification
{
	return OREdelweissFLTModelHitRateChanged;
}

#pragma mark *** archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setRepeatSWTriggerMode:[decoder decodeIntForKey:@"repeatSWTriggerMode"]];
    [self setControlRegister:[decoder decodeIntForKey:@"controlRegister"]];
    [self setFastWrite:[decoder decodeIntForKey:@"fastWrite"]];
    [self setFiberDelays:[decoder decodeInt64ForKey:@"fiberDelays"]];
    [self setStreamMask:[decoder decodeInt64ForKey:@"streamMask"]];
    [self setSelectFiberTrig:[decoder decodeIntForKey:@"selectFiberTrig"]];
    [self setBBv1Mask:[decoder decodeIntForKey:@"BBv1Mask"]];
//DEBUG OUTPUT:
 	NSLog(@"%@::%@: UNDER CONSTRUCTION! BBv1Mask %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),BBv1Mask);//TODO: DEBUG testing ...-tb-
    [self setFiberEnableMask:[decoder decodeIntForKey:@"fiberEnableMask"]];
    [self setFltModeFlags:[decoder decodeIntForKey:@"fltModeFlags"]];
    [self setTargetRate:[decoder decodeIntForKey:@"targetRate"]];
	[self setRunMode:			[decoder decodeIntForKey:@"runMode"]];
    [self setStoreDataInRam:	[decoder decodeBoolForKey:@"storeDataInRam"]];
    [self setFilterLength:		[decoder decodeIntForKey:@"filterLength"]-2];//to be backward compatible with old Orca config files -tb-
    [self setGapLength:			[decoder decodeIntForKey:@"gapLength"]];
    [self setPostTriggerTime:	[decoder decodeInt32ForKey:@"postTriggerTime"]];
    [self setFifoBehaviour:		[decoder decodeIntForKey:@"fifoBehaviour"]];
    [self setAnalogOffset:		[decoder decodeIntForKey:@"analogOffset"]];
    [self setInterruptMask:		[decoder decodeInt32ForKey:@"interruptMask"]];
    [self setHitRateLength:		[decoder decodeIntForKey:@"OREdelweissFLTModelHitRateLength"]];
    [self setGains:				[decoder decodeObjectForKey:@"gains"]];
    [self setThresholds:		[decoder decodeObjectForKey:@"thresholds"]];
    [self setTotalRate:			[decoder decodeObjectForKey:@"totalRate"]];
	[self setTestEnabledArray:	[decoder decodeObjectForKey:@"testsEnabledArray"]];
	[self setTestStatusArray:	[decoder decodeObjectForKey:@"testsStatusArray"]];
    [self setWriteValue:		[decoder decodeIntForKey:@"writeValue"]];
    [self setSelectedRegIndex:  [decoder decodeIntForKey:@"selectedRegIndex"]];
    [self setSelectedChannelValue:  [decoder decodeIntForKey:@"selectedChannelValue"]];
	
	int i;
	if(!thresholds){
		[self setThresholds: [NSMutableArray array]];
		for(i=0;i<kNumV4FLTChannels;i++) [thresholds addObject:[NSNumber numberWithInt:50]];
	}
	if([thresholds count]<kNumV4FLTChannels){
		for(i=[thresholds count];i<kNumV4FLTChannels;i++) [thresholds addObject:[NSNumber numberWithInt:50]];
	}
	
	if(!gains){
		[self setGains: [NSMutableArray array]];
		for(i=0;i<kNumV4FLTChannels;i++) [gains addObject:[NSNumber numberWithInt:100]];
	}
	if([gains count]<kNumV4FLTChannels){
		for(i=[gains count];i<kNumV4FLTChannels;i++) [gains addObject:[NSNumber numberWithInt:50]];
	}
	
	if(!testStatusArray){
		[self setTestStatusArray: [NSMutableArray array]];
		for(i=0;i<kNumEdelweissFLTTests;i++) [testStatusArray addObject:@"--"];
	}
	
	if(!testEnabledArray){
		[self setTestEnabledArray: [NSMutableArray array]];
		for(i=0;i<kNumEdelweissFLTTests;i++) [testEnabledArray addObject:[NSNumber numberWithBool:YES]];
	}
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
    [encoder encodeInt:repeatSWTriggerMode forKey:@"repeatSWTriggerMode"];
    [encoder encodeInt:controlRegister forKey:@"controlRegister"];
    [encoder encodeInt:fastWrite forKey:@"fastWrite"];
    [encoder encodeInt64:fiberDelays forKey:@"fiberDelays"];
    [encoder encodeInt64:streamMask forKey:@"streamMask"];
    [encoder encodeInt:selectFiberTrig forKey:@"selectFiberTrig"];
//DEBUG OUTPUT:
 	NSLog(@"%@::%@: UNDER CONSTRUCTION! BBv1Mask %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),BBv1Mask);//TODO: DEBUG testing ...-tb-
    [encoder encodeInt:BBv1Mask forKey:@"BBv1Mask"];
    [encoder encodeInt:fiberEnableMask forKey:@"fiberEnableMask"];
    [encoder encodeInt:fltModeFlags forKey:@"fltModeFlags"];
    [encoder encodeInt:targetRate			forKey:@"targetRate"];
    [encoder encodeInt:runMode				forKey:@"runMode"];
    [encoder encodeBool:runBoxCarFilter		forKey:@"runBoxCarFilter"];
    [encoder encodeBool:storeDataInRam		forKey:@"storeDataInRam"];
    [encoder encodeInt:(filterLength+2)			forKey:@"filterLength"];//to be backward compatible with old Orca config files (this is the register value)-tb-
    [encoder encodeInt:gapLength			forKey:@"gapLength"];
    [encoder encodeInt32:postTriggerTime	forKey:@"postTriggerTime"];
    [encoder encodeInt:fifoBehaviour		forKey:@"fifoBehaviour"];
    [encoder encodeInt:analogOffset			forKey:@"analogOffset"];
    [encoder encodeInt32:interruptMask		forKey:@"interruptMask"];
    [encoder encodeInt:hitRateLength		forKey:@"OREdelweissFLTModelHitRateLength"];
    [encoder encodeObject:gains				forKey:@"gains"];
    [encoder encodeObject:thresholds		forKey:@"thresholds"];
    [encoder encodeObject:totalRate			forKey:@"totalRate"];
    [encoder encodeObject:testEnabledArray	forKey:@"testEnabledArray"];
    [encoder encodeObject:testStatusArray	forKey:@"testStatusArray"];
    [encoder encodeInt:writeValue           forKey:@"writeValue"];	
    [encoder encodeInt:selectedRegIndex  	forKey:@"selectedRegIndex"];	
    [encoder encodeInt:selectedChannelValue	forKey:@"selectedChannelValue"];	
}

#pragma mark *** Data Taking
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) aDataId
{
    dataId = aDataId;
}

- (unsigned long) waveFormId { return waveFormId; }
- (void) setWaveFormId: (unsigned long) aWaveFormId
{
    waveFormId = aWaveFormId;
}

- (unsigned long) hitRateId { return hitRateId; }
- (void) setHitRateId: (unsigned long) aDataId
{
    hitRateId = aDataId;
}

- (unsigned long) histogramId { return histogramId; }
- (void) setHistogramId: (unsigned long) aDataId
{
    histogramId = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId      = [assigner assignDataIds:kLongForm];
    hitRateId   = [assigner assignDataIds:kLongForm];
    waveFormId  = [assigner assignDataIds:kLongForm];
    histogramId  = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
    [self setHitRateId:[anotherCard hitRateId]];
    [self setWaveFormId:[anotherCard waveFormId]];
    [self setHistogramId:[anotherCard histogramId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"OREdelweissFLTDecoderForEnergy",			@"decoder",
								 [NSNumber numberWithLong:dataId],		@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:7],			@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissFLTEnergy"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"OREdelweissFLTDecoderForWaveForm",			@"decoder",
				   [NSNumber numberWithLong:waveFormId],	@"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissFLTWaveForm"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"OREdelweissFLTDecoderForHitRate",			@"decoder",
				   [NSNumber numberWithLong:hitRateId],		@"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissFLTHitRate"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"OREdelweissFLTDecoderForHistogram",		@"decoder",
				   [NSNumber numberWithLong:histogramId],	@"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissFLTHistogram"];
	
    return dataDictionary;
}


//what is the event dictionary? -tb-
- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   [NSNumber numberWithLong:dataId],				@"dataId",
				   [NSNumber numberWithLong:kNumV4FLTChannels],		@"maxChannels",
				   nil];
	
	[anEventDictionary setObject:aDictionary forKey:@"EdelweissFLT"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
	//TODO: some of these shall move to ORKatrinV4FLTModel.m in the future ... -tb- 2010-05-19
    //TO DO....other things need to be added here.....
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:thresholds										forKey:@"thresholds"];
    [objDictionary setObject:gains											forKey:@"gains"];
    [objDictionary setObject:[NSNumber numberWithInt:runMode]				forKey:@"runMode"];
    [objDictionary setObject:[NSNumber numberWithLong:postTriggerTime]		forKey:@"postTriggerTime"];
    [objDictionary setObject:[NSNumber numberWithLong:fifoBehaviour]		forKey:@"fifoBehaviour"];
    [objDictionary setObject:[NSNumber numberWithLong:analogOffset]			forKey:@"analogOffset"];
    [objDictionary setObject:[NSNumber numberWithLong:hitRateLength]		forKey:@"hitRateLength"];
    [objDictionary setObject:[NSNumber numberWithLong:gapLength]			forKey:@"gapLength"];
    [objDictionary setObject:[NSNumber numberWithLong:filterLength+2]			forKey:@"filterLength"];//this is the fpga register value -tb-
	return objDictionary;
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(channel>=0 && channel<kNumV4FLTChannels){
		++eventCount[channel];
	}
    return YES;
}

- (unsigned long) eventCount:(int)aChannel
{
    return eventCount[aChannel];
}

- (void) clearEventCounts
{
    int i;
    for(i=0;i<kNumV4FLTChannels;i++){
		eventCount[i]=0;
    }
}

//! Write 1 to all reset/clear flags of the FLTv4 command register.
- (void) reset 
{
	//[self writeReg:kFLTV4CommandReg value:kIpeFlt_Reset_All];
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{	
//TODO: runTaskStarted UNDER CONSTRUCTION -tb- 
//TODO: runTaskStarted UNDER CONSTRUCTION -tb- 
//TODO: runTaskStarted UNDER CONSTRUCTION -tb- 
//TODO: runTaskStarted UNDER CONSTRUCTION -tb- 

	firstTime = YES;
	
    [self clearExceptionCount];
	[self clearEventCounts];
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"OREdelweissFLTModel"];    
    //----------------------------------------------------------------------------------------	

	//check which mode to use
	BOOL ratesEnabled = NO;
#if 0	
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		if([self hitRateEnabled:i]){
			ratesEnabled = YES;
			break;
		}
	}
#endif	
    //if([[userInfo objectForKey:@"doinit"]intValue]){
	[self setLedOff:NO];
	[self writeRunControl:YES]; // writes to run control register (was NO, but this causes the first few noise events -tb-)
	//[self reset];               // Write 1 to all reset/clear flags of the FLTv4 command register.
	[self initBoard];           // writes control reg + hr control reg + PostTrigg + thresh+gains + offset + triggControl + hr mask + enab.statistics
	//}
	
	
	if(0 & ratesEnabled){//TODO: disabled ... -tb-
		[self performSelector:@selector(readHitRates) 
				   withObject:nil
				   afterDelay: (1<<[self hitRateLength])];		//start reading out the rates
	}
		
	if(runMode == kIpeFltV4_MonitoringDaqMode ){ ///obsolete ... kIpeFltV4_Histogram_DaqMode){
		//start polling histogramming mode status
/*		[self performSelector:@selector(readHistogrammingStatus) 
				   withObject:nil
				   afterDelay: 1];		//start reading out histogram timer and page toggle
*/
	}
	
	[self writeRunControl:YES];
	
	if([self repeatSWTriggerMode] == 1){
	    NSLog(@"Start SW Trigger\n");//TODO: debug output -tb-
		[self setSwTriggerIsRepeating: 1];
	}

}


//**************************************************************************************
// Function:	

// Description: Read data from a card
//***************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{	
	if(firstTime){
		firstTime = NO;
		NSLogColor([NSColor redColor],@"Readout List Error: FLT %d must be a child of an SLT in the readout list\n",[self stationNumber]);
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	//[self writeRunControl:NO];// let it run, see runTaskStarted ... -tb-
	[self setLedOff:YES];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
//	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHistogrammingStatus) object:nil];
	int chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		hitRate[chan] = 0;
	}
	[self setHitRateTotal:0];

	if([self repeatSWTriggerMode] == 1){
	    NSLog(@"Stop SW Trigger\n");//TODO: debug output -tb-
		[self setSwTriggerIsRepeating: 0];
	}

	
	[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelHitRateChanged object:self];
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢SBC readout control structure... Till, fill out as needed
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kFLTv4EW;					//unique identifier for readout hw
	configStruct->card_info[index].hw_mask[0] 	= dataId;					//record id for energies
	configStruct->card_info[index].hw_mask[1] 	= waveFormId;				//record id for the waveforms
	configStruct->card_info[index].hw_mask[2] 	= histogramId;				//record id for the histograms
	configStruct->card_info[index].slot			= [self stationNumber];		//the PMC readout uses col 0 thru n
	configStruct->card_info[index].crate		= [self crateNumber];
//DEBUG OUTPUT: 
	NSLog(@"    %@::%@:slot %i, crate %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd), [self stationNumber], [self crateNumber]);//TODO: DEBUG testing ...-tb-
	
	configStruct->card_info[index].deviceSpecificData[0] = postTriggerTime;	//needed to align the waveforms
	
	unsigned long eventTypeMask = 0;
	if(readWaveforms) eventTypeMask |= kReadWaveForms;
	configStruct->card_info[index].deviceSpecificData[1] = eventTypeMask;	
	configStruct->card_info[index].deviceSpecificData[2] = fltModeFlags;	
	
    //"first time" flag (needed for histogram mode)
	unsigned long runFlagsMask = 0;
	runFlagsMask |= kFirstTimeFlag;          //bit 16 = "first time" flag
    //if(runMode == kIpeFltV4_EnergyDaqMode | runMode == kIpeFltV4_EnergyTraceDaqMode)
    //    runFlagsMask |= kSyncFltWithSltTimerFlag;//bit 17 = "sync flt with slt timer" flag
    
	configStruct->card_info[index].deviceSpecificData[3] = runFlagsMask;	
//NSLog(@"RunFlags 0x%x\n",configStruct->card_info[index].deviceSpecificData[3]);

    //for all daq modes
//	configStruct->card_info[index].deviceSpecificData[4] = triggerEnabledMask;	
    //the daq mode (should replace the flt mode)
    configStruct->card_info[index].deviceSpecificData[5] = runMode;//the daqRunMode

    //new for Edelweiss
    configStruct->card_info[index].deviceSpecificData[10] = [self selectFiberTrig];//the fiber_select (Select Fiber) setting of control register

	configStruct->card_info[index].num_Trigger_Indexes = 0;					//we can't have children
	configStruct->card_info[index].next_Card_Index 	= index+1;	

	
	return index+1;
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}

- (int) numberOfChannels
{
    return kNumV4FLTChannels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Run Mode"];
    [p setFormat:@"##0" upperLimit:2 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setRunMode:) getMethod:@selector(runMode)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0xfffff lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gain"];
    [p setFormat:@"##0" upperLimit:0xfff lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setGain:withValue:) getMethod:@selector(gain:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setTriggerEnabled:withValue:) getMethod:@selector(triggerEnabled:)];
    [a addObject:p];
	
#if 0
//TODO: xxx -tb-
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"HitRate Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setHitRateEnabled:withValue:) getMethod:@selector(hitRateEnabled:)];
    [a addObject:p];
#endif	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Post Trigger Delay"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:2047 units:@"x50ns"];
    [p setSetMethod:@selector(setPostTriggerTime:) getMethod:@selector(postTriggerTime)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Fifo Behavior"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setFifoBehaviour:) getMethod:@selector(fifoBehaviour)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Analog Offset"];
    [p setFormat:@"##0" upperLimit:4095 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setAnalogOffset:) getMethod:@selector(analogOffset)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Hit Rate Length"];
    [p setFormat:@"##0" upperLimit:4095 lowerLimit:255 stepSize:1 units:@""];
    [p setSetMethod:@selector(setHitRateLength:) getMethod:@selector(hitRateLength)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gap Length"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setGapLength:) getMethod:@selector(gapLength)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"FilterLength"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:2 stepSize:1 units:@""];
    [p setSetMethod:@selector(setFilterLength:) getMethod:@selector(filterLength)];
    [a addObject:p];			
	
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORIpeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"OREdelweissFLTModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"OREdelweissFLTModel"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Threshold"])				return  [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Gain"])				return [[cardDictionary objectForKey:@"gains"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Trigger Enabled"])		return [[cardDictionary objectForKey:@"triggersEnabled"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"HitRate Enabled"])		return [[cardDictionary objectForKey:@"hitRatesEnabled"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Post Trigger Time"])	return [cardDictionary objectForKey:@"postTriggerTime"];
    else if([param isEqualToString:@"Run Mode"])			return [cardDictionary objectForKey:@"runMode"];
    else if([param isEqualToString:@"Fifo Behaviour"])		return [cardDictionary objectForKey:@"fifoBehaviour"];
    else if([param isEqualToString:@"Analog Offset"])		return [cardDictionary objectForKey:@"analogOffset"];
    else if([param isEqualToString:@"Hit Rate Length"])		return [cardDictionary objectForKey:@"hitRateLength"];
    else if([param isEqualToString:@"Gap Length"])			return [cardDictionary objectForKey:@"gapLength"];
    else if([param isEqualToString:@"Filter Length"])		return [cardDictionary objectForKey:@"filterLength"];
    else return nil;
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢AdcInfo Providing
- (void) postAdcInfoProvidingValueChanged
{
	//this notification is be picked up by high-level objects like the 
	//Katrin U/I that displays all the thresholds and gains in the system
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAdcInfoProvidingValueChanged object:self];
}

- (BOOL) onlineMaskBit:(int)bit
{
	return [self triggerEnabled:bit];
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Reporting

- (void) printEventFIFOs
{
//TODO: printEventFIFOs UNDER CONSTRUCTION move to SLT? -tb-
#if 0
	unsigned long status = [self readReg: kFLTV4StatusReg];
	int fifoStatus = (status>>24) & 0xf;
	if(fifoStatus != 0x03){
		
		NSLog(@"fifoStatus: 0x%0x\n",(status>>24)&0xf);
		
		unsigned long aValue = [self readReg: kFLTV4EventFifoStatusReg];
		NSLog(@"aValue: 0x%0x\n", aValue);
		NSLog(@"Read: %d\n", (aValue>>16)&0x3ff);
		NSLog(@"Write: %d\n", (aValue>>0)&0x3ff);
		
		unsigned long eventFifo1 = [self readReg: kFLTV4EventFifo1Reg];
		unsigned long channelMap = (eventFifo1>>10)&0xfffff;
		NSLog(@"Channel Map: 0x%0x\n",channelMap);
		
		unsigned long eventFifo2 = [self readReg: kFLTV4EventFifo2Reg];
		unsigned long sec =  ((eventFifo1&0x3ff)<<5) | ((eventFifo2>>27)&0x1f);
		NSLog(@"sec: %d %d\n",((eventFifo2>>27)&0x1f),eventFifo1&0x3ff);
		NSLog(@"Time: %d\n",sec);
		
		int i;
		for(i=0;i<kNumV4FLTChannels;i++){
			if(channelMap & (1<<i)){
				unsigned long eventFifo3 = [self readReg: kFLTV4EventFifo3Reg channel:i];
				unsigned long energy     = [self readReg: kFLTV4EventFifo4Reg channel:i];
				NSLog(@"channel: %d page: %d energy: %d\n\n",i, eventFifo3 & 0x3f, energy);
			}
		}
		NSLog(@"-------\n");
	}
	else NSLog(@"FIFO empty\n");
#endif
}


- (NSString*) boardTypeName:(int)aType
{
	switch(aType){
		case 0:  return @"FZK HEAT";	break;
		case 1:  return @"FZK KATRIN";	break;
		case 2:  return @"FZK USCT";	break;
		case 3:  return @"ITALY HEAT";	break;
		case 4:  return @"EDELWEISS";	break;
		default: return @"UNKNOWN";		break;
	}
}
- (NSString*) fifoStatusString:(int)aType  //TODO: OBSOLETE for EW? -tb-
{
	switch(aType){
		case 0x3:  return @"Empty";			break;
		case 0x2:  return @"Almost Empty";	break;
		case 0x4:  return @"Almost Full";	break;
		case 0xc:  return @"Full";			break;
		default:   return @"UNKNOWN";		break;
	}
}

- (void) printVersions
{
	unsigned long data;
	data = [self readVersion];
	if(0x1f000000 == data){
		NSLogColor([NSColor redColor],@"FLTv4: Could not access hardware, no version register read!\n");
		return;
	}
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"CFPGA Version %u.%u.%u.%u\n",((data>>28)&0xf),((data>>16)&0xfff),((data>>8)&0xff),((data>>0)&0xff));
	NSLogFont(aFont,@"      Version Proj:%u DocRev %u,  Vers. %u, Rev. %u\n",((data>>28)&0xf),((data>>16)&0xfff),((data>>8)&0xff),((data>>0)&0xff));

	switch ( ((data>>28)&0xf) ) {
		case 1: //AUGER
			NSLogFont(aFont,@"    This is a Auger FLTv4 firmware configuration!\n");
			break;
		case 2: //KATRIN
			NSLogFont(aFont,@"    This is a KATRIN FLTv4 firmware configuration!\n");
			break;
		case 4: //EDELWEISS
			NSLogFont(aFont,@"    This is a EDELWEISS FLTv4 firmware configuration!\n");
			break;
		default:
			NSLogFont(aFont,@"    This is a Unknown FLTv4 firmware configuration!\n");
			break;
	}
}

- (void) printStatusReg
{
	unsigned long status = [self readStatus];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"FLT %d status Reg (address:0x%08x): 0x%08x\n", [self stationNumber],[self regAddress:kFLTV4StatusReg],status);
	NSLogFont(aFont,@"Power           : %@\n",	((status>>0) & 0x1) ? @"FAILED":@"OK");
	NSLogFont(aFont,@"PLL1            : %@\n",	((status>>1) & 0x1) ? @"ERROR":@"OK");
	NSLogFont(aFont,@"PLL2            : %@\n",	((status>>2) & 0x1) ? @"ERROR":@"OK");
	NSLogFont(aFont,@"10MHz Phase     : %@\n",	((status>>3) & 0x1) ? @"UNLOCKED":@"OK");
	NSLogFont(aFont,@"LED (?)         : %@\n",	((status>>15) & 0x1) ? @"OFF":@"ON");
#if 0
	NSLogFont(aFont,@"Firmware Type   : %@\n",	[self boardTypeName:((status>>4) & 0x3)]);
	NSLogFont(aFont,@"Hardware Type   : %@\n",	[self boardTypeName:((status>>6) & 0x3)]);
#endif
	NSLogFont(aFont,@"Busy            : %@\n",	((status>>8) & 0x1) ? @"BUSY":@"IDLE");
	NSLogFont(aFont,@"Interrupt Srcs  : 0x%x\n",	(status>>16) &0xff);
	//TODO: NSLogFont(aFont,@"FIFO Status     : %@\n",	[self fifoStatusString:((status>>24) & 0xf)]);
	NSLogFont(aFont,@"FIFO Status     : 0x%x\n",((status>>24) & 0xf));
	NSLogFont(aFont,@"ATo             : %d\n",	((status>>28) & 0x1));
	NSLogFont(aFont,@"HRo             : %d\n",	((status>>29) & 0x1));
	NSLogFont(aFont,@"IRQ             : %d\n",	((status>>31) & 0x1));
}

- (void) printValueTable
{
//TODO: printValueTable under construction -tb-
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,   @"chan | HitRate  | Gain | Threshold\n");
	NSLogFont(aFont,   @"----------------------------------\n");



#if 0
	unsigned long aHitRateMask = [self readHitRateMask];

	//grab all the thresholds and gains using one command packet
	int i;
	ORCommandList* aList = [ORCommandList commandList];
	for(i=0;i<kNumV4FLTChannels;i++){
		[aList addCommand: [self readRegCmd:kFLTV4GainReg channel:i]];
		[aList addCommand: [self readRegCmd:kFLTV4ThresholdReg channel:i]];
	}
	
	[self executeCommandList:aList];
	
	for(i=0;i<kNumV4FLTChannels;i++){
		NSLogFont(aFont,@"%4d | %@ | %4d | %4d \n",i,(aHitRateMask>>i)&0x1 ? @" Enabled":@"Disabled",[aList longValueForCmd:i*2],[aList longValueForCmd:1+i*2]);
	}
#endif
	NSLogFont(aFont,   @"---------------------------------\n");
}

- (void) printStatistics
{
	//TODO:  replace by V4 code -tb-
	NSLog(@"FLTv4: printStatistics not implemented \n");//TODO: needs implementation -tb-
	return;
    int j;
	double mean;
	double var;
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
    NSLogFont(aFont,@"Statistics      :\n");
	for (j=0;j<kNumV4FLTChannels;j++){
		[self getStatistics:j mean:&mean var:&var];
		NSLogFont(aFont,@"  %2d -- %10.2f +/-  %10.2f\n", j, mean, var);
	}
}

- (void) findNoiseFloors
{
	if(noiseFloorRunning){
		noiseFloorRunning = NO;
	}
	else {
		noiseFloorState = 0;
		noiseFloorRunning = YES;
		[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:0];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTNoiseFloorChanged object:self];
}

- (NSString*) noiseFloorStateString
{
	if(!noiseFloorRunning) return @"Idle";
	else switch(noiseFloorState){
		case 0: return @"Initializing"; 
		case 1: return @"Setting Thresholds";
		case 2: return @"Integrating";
		case 3: return @"Finishing";
		default: return @"?";
	}	
}
- (unsigned long) thresholdForDisplay:(unsigned short) aChan
{
	return [self threshold:aChan];
}
- (unsigned short) gainForDisplay:(unsigned short) aChan
{
	return [self gain:aChan];
}
@end




@implementation OREdelweissFLTModel (tests)
#pragma mark ‚Ä¢‚Ä¢‚Ä¢Accessors
- (BOOL) testsRunning { return testsRunning; }
- (void) setTestsRunning:(BOOL)aTestsRunning
{
    testsRunning = aTestsRunning;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTestsRunningChanged object:self];
}

- (NSMutableArray*) testEnabledArray { return testEnabledArray; }
- (void) setTestEnabledArray:(NSMutableArray*)aTestEnabledArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestEnabledArray:testEnabledArray];
    
    [aTestEnabledArray retain];
    [testEnabledArray release];
    testEnabledArray = aTestEnabledArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTestEnabledArrayChanged object:self];  
}

- (NSMutableArray*) testStatusArray { return testStatusArray; }
- (void) setTestStatusArray:(NSMutableArray*)aTestStatusArray
{
    [aTestStatusArray retain];
    [testStatusArray release];
    testStatusArray = aTestStatusArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTestStatusArrayChanged object:self];
}

- (NSString*) testStatus:(int)index
{
	if(index<[testStatusArray count])return [testStatusArray objectAtIndex:index];
	else return @"---";
}

- (BOOL) testEnabled:(int)index
{
	if(index<[testEnabledArray count])return [[testEnabledArray objectAtIndex:index] boolValue];
	else return NO;
}

- (void) runTests
{
	if(!testsRunning){
		@try {
			[self setTestsRunning:YES];
			NSLog(@"Starting tests for FLT station %d\n",[self stationNumber]);
			
			//clear the status text array
			int i;
			for(i=0;i<kNumEdelweissFLTTests;i++){
				[testStatusArray replaceObjectAtIndex:i withObject:@"--"];
			}
			
			//create the test suit
			if(testSuit)[testSuit release];
			testSuit = [[ORTestSuit alloc] init];
			if([self testEnabled:0]) [testSuit addTest:[ORTest testSelector:@selector(modeTest) tag:0]];
			if([self testEnabled:1]) [testSuit addTest:[ORTest testSelector:@selector(ramTest) tag:1]];
			if([self testEnabled:2]) [testSuit addTest:[ORTest testSelector:@selector(thresholdGainTest) tag:2]];
			if([self testEnabled:3]) [testSuit addTest:[ORTest testSelector:@selector(speedTest) tag:3]];
			if([self testEnabled:4]) [testSuit addTest:[ORTest testSelector:@selector(eventTest) tag:4]];
			
			[testSuit runForObject:self];
		}
		@catch(NSException* localException) {
		}
	}
	else {
		NSLog(@"Tests for FLT (station: %d) stopped manually\n",[self stationNumber]);
		[testSuit stopForObject:self];
	}
}

- (void) runningTest:(int)aTag status:(NSString*)theStatus
{
	[testStatusArray replaceObjectAtIndex:aTag withObject:theStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTestStatusArrayChanged object:self];
}


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Tests
- (void) modeTest
{
//TODO: TESTS DISABLED -tb-
#if 0
	int testNumber = 0;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	savedMode = fltRunMode;
	@try {
		BOOL passed = YES;
		int i;
		for(i=0;i<4;i++){
			fltRunMode = i;
			[self writeControl];
			if([self readMode] != i){
				[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
				passed = NO;
				break;
			}
			if(passed){
				fltRunMode = savedMode;
				[self writeControl];
				if([self readMode] != savedMode){
					[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
					passed = NO;
				}
			}
		}
		if(passed){
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}
	
	[testSuit runForObject:self]; //do next test
#endif
}


- (void) ramTest
{
	int testNumber = 1;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	@try {
		[self test:testNumber result:@"TBD" color:[NSColor passedColor]];
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
}

- (void) thresholdGainTest
{

#if 0
	int testNumber = 2;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	@try {
		[self enterTestMode];
		unsigned long aPattern[4] = {0x3fff,0x0,0x2aaa,0x1555};
		int chan;
		BOOL passed = YES;
		int testIndex;
		//thresholds first
		for(testIndex = 0;testIndex<4;testIndex++){
			unsigned short thePattern = aPattern[testIndex];
			for(chan=0;chan<kNumV4FLTChannels;chan++){
				[self writeThreshold:chan value:thePattern];
			}
			
			for(chan=0;chan<kNumV4FLTChannels;chan++){
				if([self readThreshold:chan] != thePattern){
					[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
					NSLog(@"Error: Threshold (pattern: 0x%0x) FLT %d chan %d does not work\n",thePattern,[self stationNumber],chan);
					passed = NO;
					break;
				}
			}
		}
		if(passed){		
			unsigned long gainPattern[4] = {0xfff,0x0,0xaaa,0x555};
			
			//now gains
			for(testIndex = 0;testIndex<4;testIndex++){
				unsigned short thePattern = gainPattern[testIndex];
				for(chan=0;chan<kNumV4FLTChannels;chan++){
					[self writeGain:chan value:thePattern];
				}
				
				for(chan=0;chan<kNumV4FLTChannels;chan++){
					unsigned short theValue = [self readGain:chan];
					if(theValue != thePattern){
						[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
						NSLog(@"Error: Gain (pattern: 0x%0x!=0x%0x) FLT %d chan %d does not work\n",thePattern,theValue,[self stationNumber],chan);
						passed = NO;
						break;
					}
				}
			}
		}
		if(passed){	
			unsigned long offsetPattern[4] = {0xfff,0x0,0xaaa,0x555};
			for(testIndex = 0;testIndex<4;testIndex++){
				unsigned short thePattern = offsetPattern[testIndex];
				[self writeReg:kFLTV4AnalogOffset value:thePattern];
				unsigned short theValue = [self readReg:kFLTV4AnalogOffset];
				if(theValue != thePattern){
					NSLog(@"Error: Offset (pattern: 0x%0x!=0x%0x) FLT %d does not work\n",thePattern,theValue,[self stationNumber]);
					passed = NO;
					break;
				}
			}
		}
		
		if(passed) [self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		
		[self loadThresholdsAndGains]; //put the old values back
		
		[self leaveTestMode];
		
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
	
#endif
}

- (void) speedTest
{
	int testNumber = 3;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	ORTimer* aTimer = [[ORTimer alloc] init];
	[aTimer start];
	
	@try {
		BOOL passed = YES;
		int numLoops = 250;
		int numPatterns = 4;
		int j;
		for(j=0;j<numLoops;j++){
			unsigned long aPattern[4] = {0xfffffff,0x00000000,0xaaaaaaaa,0x55555555};
			int i;
			for(i=0;i<numPatterns;i++){
				[self writeReg:kFLTV4AccessTestReg value:aPattern[i]];
				unsigned long aValue = [self readReg:kFLTV4AccessTestReg];
				if(aValue!=aPattern[i]){
					NSLog(@"Error: Comm Check (pattern: 0x%0x!=0x%0x) FLT %d does not work\n",aPattern,aValue,[self stationNumber]);
					passed = NO;				
				}
			}
			if(!passed)break;
		}
		[aTimer stop];
		if(passed){
			int totalOps = numLoops*numPatterns*2;
			double secs = [aTimer seconds];
			[self test:testNumber result:[NSString stringWithFormat:@"%.2f/s",totalOps/secs] color:[NSColor passedColor]];
			NSLog(@"Speed Test For FLT %d : %d accesses in %.3f sec\n",[self stationNumber], totalOps,secs);
		}
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}	
	@finally {
		[aTimer release];
	}
	
	[testSuit runForObject:self]; //do next test
}

- (void) eventTest
{
	int testNumber = 4;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	@try {
		[self test:testNumber result:@"TBD" color:[NSColor passedColor]];
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
		
	}		
	
	[testSuit runForObject:self]; //do next test
}

- (int) compareData:(unsigned short*) data
			pattern:(unsigned short*) pattern
			  shift:(int) shift
				  n:(int) n 
{
	unsigned int i, j;
	
	// Check for errors
	for (i=0;i<n;i++) {
		if (data[i]!=pattern[(i+shift)%n]) {
			for (j=(i/4);(j<i/4+3) && (j < n/4);j++){
				NSLog(@"%04x: %04x %04x %04x %04x - %04x %04x %04x %04x \n",j*4,
					  data[j*4],data[j*4+1],data[j*4+2],data[j*4+3],
					  pattern[(j*4+shift)%n],  pattern[(j*4+1+shift)%n],
					  pattern[(j*4+2+shift)%n],pattern[(j*4+3+shift)%n]  );
				return i; // check only for one error in every page!
			}
		}
	}
	
	return n;
}

@end

@implementation OREdelweissFLTModel (private)

- (void) stepNoiseFloor
{


return;
#if 0
	[[self undoManager] disableUndoRegistration];
	int i;
	BOOL atLeastOne;
    @try {
		switch(noiseFloorState){
			case 0:
				//disable all channels
				for(i=0;i<kNumV4FLTChannels;i++){
					oldEnabled[i]   = [self hitRateEnabled:i];
					oldThreshold[i] = [self threshold:i];
					[self setThreshold:i withValue:0x7fff];
					newThreshold[i] = 0x7fff;
				}
				atLeastOne = NO;
				for(i=0;i<kNumV4FLTChannels;i++){
					if(oldEnabled[i]){
						noiseFloorLow[i]			= 0;
						noiseFloorHigh[i]		= 0x7FFF;
						noiseFloorTestValue[i]	= 0x7FFF/2;              //Initial probe position
						[self setThreshold:i withValue:noiseFloorHigh[i]];
						atLeastOne = YES;
					}
				}
				
				[self initBoard];
				
				if(atLeastOne)	noiseFloorState = 1;
				else			noiseFloorState = 4; //nothing to do
			break;
				
			case 1:
				for(i=0;i<kNumV4FLTChannels;i++){
					if([self hitRateEnabled:i]){
						if(noiseFloorLow[i] <= noiseFloorHigh[i]) {
							[self setThreshold:i withValue:noiseFloorTestValue[i]];
							
						}
						else {
							newThreshold[i] = MAX(0,noiseFloorTestValue[i] + noiseFloorOffset);
							[self setThreshold:i withValue:0x7fff];
							//hitRateEnabledMask &= ~(1L<<i);
						}
					}
				}
				[self initBoard];
				
				//if(hitRateEnabledMask)	noiseFloorState = 2;	//go check for data
				//else					noiseFloorState = 3;	//done
			break;
				
			case 2:
				//read the hitrates
				[self readHitRates];
				
				for(i=0;i<kNumV4FLTChannels;i++){
					if([self hitRateEnabled:i]){
						if([self hitRate:i] > targetRate){
							//the rate is too high, bump the threshold up
							[self setThreshold:i withValue:0x7fff];
							noiseFloorLow[i] = noiseFloorTestValue[i] + 1;
						}
						else noiseFloorHigh[i] = noiseFloorTestValue[i] - 1;									//no data so continue lowering threshold
						noiseFloorTestValue[i] = noiseFloorLow[i]+((noiseFloorHigh[i]-noiseFloorLow[i])/2);     //Next probe position.
					}
				}
				
				[self initBoard];
				
				noiseFloorState = 1;
				break;
								
			case 3: //finish up	
				//load new results
				for(i=0;i<kNumV4FLTChannels;i++){
					[self setHitRateEnabled:i withValue:oldEnabled[i]];
					[self setThreshold:i withValue:newThreshold[i]];
				}
				[self initBoard];
				noiseFloorRunning = NO;
			break;
		}
		if(noiseFloorRunning){
			float timeToWait;
			if(noiseFloorState==2)	timeToWait = pow(2.,hitRateLength)* 1.5;
			else					timeToWait = 0.2;
			[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:timeToWait];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTNoiseFloorChanged object:self];
    }
	@catch(NSException* localException) {
        int i;
        for(i=0;i<kNumV4FLTChannels;i++){
            [self setHitRateEnabled:i withValue:oldEnabled[i]];
            [self setThreshold:i withValue:oldThreshold[i]];
			//[self reset];
			[self initBoard];
        }
		NSLog(@"FLT4 LED threshold finder quit because of exception\n");
    }
	[[self undoManager] enableUndoRegistration];
#endif
}


- (NSAttributedString*) test:(int)testIndex result:(NSString*)result color:(NSColor*)aColor
{
	NSLogColor(aColor,@"%@ test %@\n",fltTestName[testIndex],result);
	id theString = [[NSAttributedString alloc] initWithString:result 
												   attributes:[NSDictionary dictionaryWithObject: aColor forKey:NSForegroundColorAttributeName]];
	
	[self runningTest:testIndex status:theString];
	return [theString autorelease];
}

- (void) enterTestMode
{
//TODO: TESTS DISABLED -tb-
#if 0
	//put into test mode
	savedMode = fltRunMode;
	fltRunMode = kIpeFltV4Katrin_StandBy_Mode; //TODO: test mode has changed for V4 -tb- kIpeFltV4Katrin_Test_Mode;
	[self writeControl];
	//if([self readMode] != kIpeFltV4Katrin_Test_Mode){
	if(1){//TODO: test mode has changed for V4 -tb-
		NSLogColor([NSColor redColor],@"Could not put FLT %d into test mode\n",[self stationNumber]);
		[NSException raise:@"Ram Test Failed" format:@"Could not put FLT %d into test mode\n",[self stationNumber]];
	}
#endif
}

- (void) leaveTestMode
{
//TODO: TESTS DISABLED -tb-
#if 0

	fltRunMode = savedMode;
	[self writeControl];
#endif
}
@end