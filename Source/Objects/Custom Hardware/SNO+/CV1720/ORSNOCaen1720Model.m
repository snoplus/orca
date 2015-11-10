//
//ORSNOCaen1720Model.m
//Orca
//
//Created by Mark Howe on Mon Apr 14 2008.
//Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//
//-------------------------------------------------------------
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

#import "ORSNOCaen1720Model.h"
#import "ORVmeCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORRateGroup.h"
#import "VME_HW_Definitions.h"
#import "ORRunModel.h"
#include <stdint.h>
#include <hiredis.h>
#import "SNOPModel.h"


// Address information for this unit.
#define k792DefaultBaseAddress 		0xa00000
#define k792DefaultAddressModifier 	0x09
#define kNumberBLTEventsToReadout   12 //most BLTEvent numbers don't make sense, make sure you know what you change

NSString* ORSNOCaen1720ModelEventSizeChanged = @"ORSNOCaen1720ModelEventSizeChanged";
static NSString* Caen1720RunModeString[4] = {
@"Register-Controlled",
@"S-In Controlled",
@"S-In Gate",
@"Multi-Board Sync",
};
// Define all the registers available to this unit.
static Caen1720RegisterNamesStruct reg[kNumRegisters] = {
{@"Output Buffer",      true,	true, 	true,	0x0000,		kReadOnly}, //not implemented in HW yet
{@"ZS_Thres",			false,	true, 	true,	0x1024,		kReadWrite}, //not implemented in HW yet
{@"ZS_NsAmp",			false,	true, 	true,	0x1028,		kReadWrite},
{@"Thresholds",			false,	true, 	true,	0x1080,		kReadWrite},
{@"Num O/U Threshold",	false,	true, 	true,	0x1084,		kReadWrite},
{@"Status",				false,	true, 	true,	0x1088,		kReadOnly},
{@"Firmware Version",	false,	false, 	false,	0x108C,		kReadOnly},
{@"Buffer Occupancy",	true,	true, 	true,	0x1094,		kReadOnly},
{@"Dacs",				false,	true, 	true,	0x1098,		kReadWrite},
{@"Adc Config",			false,	true, 	true,	0x109C,		kReadWrite},
{@"Chan Config",		false,	true, 	true,	0x8000,		kReadWrite},
{@"Chan Config Bit Set",false,	true, 	true,	0x8004,		kWriteOnly},
{@"Chan Config Bit Clr",false,	true, 	true,	0x8008,		kWriteOnly},
{@"Buffer Organization",false,	true, 	true,	0x800C,		kReadWrite},
{@"Buffer Free",		false,	false, 	false,	0x8010,		kReadWrite},
{@"Custom Size",		false,	true, 	true,	0x8020,		kReadWrite},
{@"Acq Control",		false,	true, 	true,	0x8100,		kReadWrite},
{@"Acq Status",			false,	false, 	false,	0x8104,		kReadOnly},
{@"SW Trigger",			false,	false, 	false,	0x8108,		kWriteOnly},
{@"Trig Src Enbl Mask",	false,	true, 	true,	0x810C,		kReadWrite},
{@"FP Trig Out Enbl Mask",false,true, 	true,	0x8110,		kReadWrite},
{@"Post Trig Setting",	false,	true, 	true,	0x8114,		kReadWrite},
{@"FP I/O Data",		false,	true, 	true,	0x8118,		kReadWrite},
{@"FP I/O Control",		false,	true, 	true,	0x811C,		kReadWrite},
{@"Chan Enable Mask",	false,	true, 	true,	0x8120,		kReadWrite},
{@"ROC FPGA Version",	false,	false, 	false,	0x8124,		kReadOnly},
{@"Event Stored",		true,	true, 	true,	0x812C,		kReadOnly},
{@"Set Monitor DAC",	false,	true, 	true,	0x8138,		kReadWrite},
{@"Board Info",			false,	false, 	false,	0x8140,		kReadOnly},
{@"Monitor Mode",		false,	true, 	true,	0x8144,		kReadWrite},
{@"Event Size",			true,	true, 	true,	0x814C,		kReadOnly},
{@"VME Control",		false,	false, 	true,	0xEF00,		kReadWrite},
{@"VME Status",			false,	false, 	false,	0xEF04,		kReadOnly},
{@"Board ID",			false,	true, 	true,	0xEF08,		kReadWrite},
{@"MultCast Base Add",	false,	false, 	true,	0xEF0C,		kReadWrite},
{@"Relocation Add",		false,	false, 	true,	0xEF10,		kReadWrite},
{@"Interrupt Status ID",false,	false, 	true,	0xEF14,		kReadWrite},
{@"Interrupt Event Num",false,	true, 	true,	0xEF18,		kReadWrite},
{@"BLT Event Num",		false,	true, 	true,	0xEF1C,		kReadWrite},
{@"Scratch",			false,	true, 	true,	0xEF20,		kReadWrite},
{@"SW Reset",			false,	false, 	false,	0xEF24,		kWriteOnly},
{@"SW Clear",			false,	false, 	false,	0xEF28,		kWriteOnly}
//	{@"Flash Enable",		false,	false, 	true,	0xEF2C,		kReadWrite},
//	{@"Flash Data",			false,	false, 	true,	0xEF30,		kReadWrite},
//	{@"Config Reload",		false,	false, 	false,	0xEF34,		kWriteOnly},
//	{@"Config ROM",			false,	false, 	false,	0xF000,		kReadOnly}
};

#define kEventReadyMask 0x8

NSString* ORSNOCaen1720ModelEnabledMaskChanged                 = @"ORSNOCaen1720ModelEnabledMaskChanged";
NSString* ORSNOCaen1720ModelPostTriggerSettingChanged          = @"ORSNOCaen1720ModelPostTriggerSettingChanged";
NSString* ORSNOCaen1720ModelTriggerSourceMaskChanged           = @"ORSNOCaen1720ModelTriggerSourceMaskChanged";
NSString* ORSNOCaen1720ModelTriggerOutMaskChanged		    = @"ORSNOCaen1720ModelTriggerOutMaskChanged";
NSString* ORSNOCaen1720ModelFrontPanelControlMaskChanged	    = @"ORSNOCaen1720ModelFrontPanelControlMaskChanged";
NSString* ORSNOCaen1720ModelCoincidenceLevelChanged            = @"ORSNOCaen1720ModelCoincidenceLevelChanged";
NSString* ORSNOCaen1720ModelAcquisitionModeChanged             = @"ORSNOCaen1720ModelAcquisitionModeChanged";
NSString* ORSNOCaen1720ModelCountAllTriggersChanged            = @"ORSNOCaen1720ModelCountAllTriggersChanged";
NSString* ORSNOCaen1720ModelCustomSizeChanged                  = @"ORSNOCaen1720ModelCustomSizeChanged";
NSString* ORSNOCaen1720ModelIsCustomSizeChanged                = @"ORSNOCaen1720ModelIsCustomSizeChanged";
NSString* ORSNOCaen1720ModelIsFixedSizeChanged                 = @"ORSNOCaen1720ModelIsFixedSizeChanged";
NSString* ORSNOCaen1720ModelChannelConfigMaskChanged           = @"ORSNOCaen1720ModelChannelConfigMaskChanged";
NSString* ORSNOCaen1720ModelNumberBLTEventsToReadoutChanged    = @"ORSNOCaen1720ModelNumberBLTEventsToReadoutChanged";
NSString* ORSNOCaen1720ChnlDacChanged                          = @"ORSNOCaen1720ChnlDacChanged";
NSString* ORSNOCaen1720OverUnderThresholdChanged               = @"ORSNOCaen1720OverUnderThresholdChanged";
NSString* ORSNOCaen1720Chnl                                    = @"ORSNOCaen1720Chnl";
NSString* ORSNOCaen1720ChnlThresholdChanged                    = @"ORSNOCaen1720ChnlThresholdChanged";
NSString* ORSNOCaen1720SelectedChannelChanged                  = @"ORSNOCaen1720SelectedChannelChanged";
NSString* ORSNOCaen1720SelectedRegIndexChanged                 = @"ORSNOCaen1720SelectedRegIndexChanged";
NSString* ORSNOCaen1720WriteValueChanged                       = @"ORSNOCaen1720WriteValueChanged";
NSString* ORSNOCaen1720BasicLock                               = @"ORSNOCaen1720BasicLock";
NSString* ORSNOCaen1720SettingsLock                            = @"ORSNOCaen1720SettingsLock";
NSString* ORSNOCaen1720RateGroupChanged                        = @"ORSNOCaen1720RateGroupChanged";
NSString* ORSNOCaen1720ModelBufferCheckChanged                 = @"ORSNOCaen1720ModelBufferCheckChanged";
NSString* ORSNOCaen1720ModelContinuousModeChanged              = @"ORSNOCaen1720ModelContinuousModeChanged";

@implementation ORSNOCaen1720Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k792DefaultBaseAddress];
    [self setAddressModifier:k792DefaultAddressModifier];
	[self setEnabledMask:0xFF];
    [self setEventSize:0xa];
    [self setNumberBLTEventsToReadout:kNumberBLTEventsToReadout];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void) connect
{
    struct timeval timeout = {1, 0}; // 1 second
    NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    SNOPModel* sno;
    if ([objs count]) {
        sno = [objs objectAtIndex:0];
    } else {
	NSException *exception = [NSException exceptionWithName:@"caen" reason:@"couldn't find SNOPModel"  userInfo:Nil];
        [exception raise];
    }

    const char *host = [[sno MTCHostName] UTF8String];

    if (host == NULL) {
	NSException *exception = [NSException exceptionWithName:@"caen" reason:@"mtc hostname == NULL"  userInfo:Nil];
        [exception raise];
    }

    context = redisConnectWithTimeout(host, 4001, timeout);

    NSLog(@"caen: connecting...\n");
    if (context == NULL) {
	NSException *exception = [NSException exceptionWithName:@"caen" reason:@"caen: connect failed" userInfo:Nil];
	[exception raise];
    } else if (context->err) {
	NSString *err = [NSString stringWithUTF8String:context->errstr];
	redisFree(context);
	context = NULL;
	NSException *exception = [NSException exceptionWithName:@"caen" reason:err userInfo:Nil];
	[exception raise];
    }
    NSLog(@"caen: connected!\n");
}

- (void) disconnect
{
    if (context) redisFree(context);
    NSLog(@"caen: disconnected.\n");
}

- (redisReply *) vcommand: (char *)fmt args:(va_list) ap
{
    if (context == NULL) [self connect];

    redisReply *r = redisvCommand(context, fmt, ap);

    if (r == NULL) {
	NSString *err = [NSString stringWithUTF8String:context->errstr];
	freeReplyObject(r);
	redisFree(context);
	context = NULL;
	NSException *exception = [NSException exceptionWithName:@"caen" reason:err userInfo:Nil];
	[exception raise];
    }

    if (r->type == REDIS_REPLY_ERROR) {
	NSString *err = [NSString stringWithUTF8String:r->str];
	freeReplyObject(r);
	NSException *exception = [NSException exceptionWithName:@"caen" reason:err userInfo:Nil];
	[exception raise];
    }

    return r;
}
    
- (redisReply *) command: (char *)fmt, ...
{
    /* Sends a command to the MTC server. Takes a variable number of arguments with
     * a format similar to printf().
     *
     *   redisReply *r = [self command:"caen_read 0x34"];
     *   freeReplyObject(r);
     *
     * Replies should be freed by calling the freeReplyObject() function.;
     */
    va_list ap;
    va_start(ap, fmt);
    redisReply *r = [self vcommand:fmt args:ap];
    va_end(ap);
    return r;
}

- (int) intCommand: (char *)fmt, ...
{
    va_list ap;
    va_start(ap, fmt);
    redisReply *r = [self vcommand:fmt args:ap];
    va_end(ap);

    if (r->type != REDIS_REPLY_INTEGER) {
	NSException *exception = [NSException exceptionWithName:@"caen" reason:@"unexpected response type" userInfo:Nil];
	[exception raise];
    }

    int integer = r->integer;
    freeReplyObject(r);
    return integer;
}

- (void) okCommand: (char *)fmt, ...
{
    va_list ap;
    va_start(ap, fmt);
    redisReply *r = [self vcommand:fmt args:ap];
    va_end(ap);

    if (r->type != REDIS_REPLY_STATUS) {
	NSException *exception = [NSException exceptionWithName:@"caen" reason:@"unexpected response type" userInfo:Nil];
	[exception raise];
    }

    freeReplyObject(r);
}

- (void) dealloc 
{
    [waveFormRateGroup release];
	[bufferFullAlarm release];
    [super dealloc];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0xEF28);
}

#pragma mark ***Accessors

- (int) eventSize
{
    return eventSize;
}

- (void) setEventSize:(int)aEventSize
{
	//if(aEventSize == 0)aEventSize = 0xa; //default
	
    [[[self undoManager] prepareWithInvocationTarget:self] setEventSize:eventSize];
    
    eventSize = aEventSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelEventSizeChanged object:self];
}

- (int)	bufferState
{
	return bufferState;
}

- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<8){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (ORRateGroup*) waveFormRateGroup
{
    return waveFormRateGroup;
}

- (void) setWaveFormRateGroup:(ORRateGroup*)newRateGroup
{
    [newRateGroup retain];
    [waveFormRateGroup release];
    waveFormRateGroup = newRateGroup;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSNOCaen1720RateGroupChanged
	 object:self];    
}

- (unsigned short) selectedRegIndex
{
    return selectedRegIndex;
}

- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self]
	 setSelectedRegIndex:[self selectedRegIndex]];
    
    // Set the new value in the model.
    selectedRegIndex = anIndex;
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSNOCaen1720SelectedRegIndexChanged
	 object:self];
}

- (unsigned short) selectedChannel
{
    return selectedChannel;
}

- (void) setSelectedChannel:(unsigned short) anIndex
{
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self]
	 setSelectedChannel:[self selectedChannel]];
    
    // Set the new value in the model.
    selectedChannel = anIndex;
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSNOCaen1720SelectedChannelChanged
	 object:self];
}

- (unsigned long) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(unsigned long) aValue
{
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    
    // Set the new value in the model.
    writeValue = aValue;
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSNOCaen1720WriteValueChanged
	 object:self];
}

- (unsigned short) enabledMask
{
    return enabledMask;
}

- (void) setEnabledMask:(unsigned short)aEnabledMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabledMask:enabledMask];
    
    enabledMask = aEnabledMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelEnabledMaskChanged object:self];
}

- (unsigned long) postTriggerSetting
{
    return postTriggerSetting;
}

- (void) setPostTriggerSetting:(unsigned long)aPostTriggerSetting
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerSetting:postTriggerSetting];
    
    postTriggerSetting = aPostTriggerSetting;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelPostTriggerSettingChanged object:self];
}

- (unsigned long) triggerSourceMask
{
    return triggerSourceMask;
}

- (void) setTriggerSourceMask:(unsigned long)aTriggerSourceMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerSourceMask:triggerSourceMask];
    
    triggerSourceMask = aTriggerSourceMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelTriggerSourceMaskChanged object:self];
}

- (unsigned long) triggerOutMask
{
	return triggerOutMask;
}

- (void) setTriggerOutMask:(unsigned long)aTriggerOutMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setTriggerOutMask:triggerOutMask];
	
	//do not step into the reserved area
	triggerOutMask = aTriggerOutMask & 0xc00000ff;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelTriggerOutMaskChanged object:self];
}

- (unsigned long) frontPanelControlMask
{
	return frontPanelControlMask;
}

- (void) setFrontPanelControlMask:(unsigned long)aFrontPanelControlMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setFrontPanelControlMask:aFrontPanelControlMask];
	
	frontPanelControlMask = aFrontPanelControlMask;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelFrontPanelControlMaskChanged object:self];
}

- (unsigned short) coincidenceLevel
{
    return coincidenceLevel;
}

- (void) setCoincidenceLevel:(unsigned short)aCoincidenceLevel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCoincidenceLevel:coincidenceLevel];
    
    coincidenceLevel = aCoincidenceLevel;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelCoincidenceLevelChanged object:self];
}

- (unsigned short) acquisitionMode
{
    return acquisitionMode;
}

- (void) setAcquisitionMode:(unsigned short)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAcquisitionMode:acquisitionMode];
    
    acquisitionMode = aMode;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelAcquisitionModeChanged object:self];
}

- (BOOL) countAllTriggers
{
    return countAllTriggers;
}

- (void) setCountAllTriggers:(BOOL)aCountAllTriggers
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCountAllTriggers:countAllTriggers];
    
    countAllTriggers = aCountAllTriggers;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelCountAllTriggersChanged object:self];
}

- (unsigned long) customSize
{
    return customSize;
}

- (void) setCustomSize:(unsigned long)aCustomSize
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCustomSize:customSize];
    
    customSize = aCustomSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelCustomSizeChanged object:self];
}

- (BOOL) isCustomSize
{
	return isCustomSize;
}

- (void) setIsCustomSize:(BOOL)aIsCustomSize
{
	[[[self undoManager] prepareWithInvocationTarget:self] setIsCustomSize:isCustomSize];
	
	isCustomSize = aIsCustomSize;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelIsCustomSizeChanged object:self];
}

- (BOOL) isFixedSize
{
	return isFixedSize;
}

- (void) setIsFixedSize:(BOOL)aIsFixedSize
{
	[[[self undoManager] prepareWithInvocationTarget:self] setIsFixedSize:isFixedSize];
	
	isFixedSize = aIsFixedSize;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelIsFixedSizeChanged object:self];
}

- (unsigned short) channelConfigMask
{
    return channelConfigMask;
}

- (void) setChannelConfigMask:(unsigned short)aChannelConfigMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChannelConfigMask:channelConfigMask];
    
    channelConfigMask = aChannelConfigMask;
	
	//can't get the d form to work so just make sure that bit is cleared.
	channelConfigMask &= ~(1L<<11);

	//we do the sequential memory access only
	channelConfigMask |= (1L<<4);

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelChannelConfigMaskChanged object:self];
}

- (unsigned long) numberBLTEventsToReadout
{
    return numberBLTEventsToReadout; 
}

- (void) setNumberBLTEventsToReadout:(unsigned long) numBLTEvents
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNumberBLTEventsToReadout:numberBLTEventsToReadout];
    
    numberBLTEventsToReadout = numBLTEvents;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelNumberBLTEventsToReadoutChanged object:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Caen1720Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORSNOCaen1720Controller"];
}

- (BOOL) continuousMode
{
    return continuousMode;
}

- (void) setContinuousMode:(BOOL)aContinuousMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setContinuousMode:continuousMode];
    
    continuousMode = aContinuousMode;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelContinuousModeChanged object:self];    
}

#pragma mark ***Register - General routines
- (short) getNumberRegisters
{
    return kNumRegisters;
}

#pragma mark ***Register - Register specific routines

- (NSString*) getRegisterName:(short) anIndex
{
    return reg[anIndex].regName;
}

- (unsigned long) getAddressOffset:(short) anIndex
{
    return reg[anIndex].addressOffset;
}

- (short) getAccessType:(short) anIndex
{
    return reg[anIndex].accessType;
}

- (BOOL) dataReset:(short) anIndex
{
    return reg[anIndex].dataReset;
}

- (BOOL) swReset:(short) anIndex
{
    return reg[anIndex].softwareReset;
}

- (BOOL) hwReset:(short) anIndex
{
    return reg[anIndex].hwReset;
}


- (unsigned short) dac:(unsigned short) aChnl
{
    return dac[aChnl];
}

- (void) setDac:(unsigned short) aChnl withValue:(unsigned short) aValue
{
	
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setDac:aChnl withValue:dac[aChnl]];
    
    // Set the new value in the model.
    dac[aChnl] = aValue;
    
    // Create a dictionary object that stores a pointer to this object and the channel that was changed.
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:ORSNOCaen1720Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSNOCaen1720ChnlDacChanged
	 object:self
	 userInfo:userInfo];
}

- (unsigned short) overUnderThreshold:(unsigned short) aChnl
{
    return overUnderThreshold[aChnl];
}

- (void) setOverUnderThreshold:(unsigned short) aChnl withValue:(unsigned short) aValue
{
	
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setOverUnderThreshold:aChnl withValue:overUnderThreshold[aChnl]];
    
    // Set the new value in the model.
    overUnderThreshold[aChnl] = aValue;
    
    // Create a dictionary object that stores a pointer to this object and the channel that was changed.
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:ORSNOCaen1720Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSNOCaen1720OverUnderThresholdChanged
	 object:self
	 userInfo:userInfo];
}

- (uint32_t) readChan:(unsigned short)chan reg:(unsigned short) pReg
{
    // Make sure that register is valid
    if (pReg >= [self getNumberRegisters]) {
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    // Make sure that one can read from register
    if([self getAccessType:pReg] != kReadOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (read not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }
    
    return [self intCommand:"caen_read %d", [self getAddressOffset:pReg] + chan*0x100];
}

- (void) writeChan:(unsigned short)chan reg:(unsigned short) pReg sendValue:(unsigned long) pValue
{
	unsigned long theValue = pValue;
    // Check that register is a valid register.
    if (pReg >= [self getNumberRegisters]){
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    // Make sure that register can be written to.
    if([self getAccessType:pReg] != kWriteOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (write not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }
    
    [self okCommand:"caen_write %d %d", [self getAddressOffset:pReg] + chan*0x100, pValue];
}

- (unsigned short) threshold:(unsigned short) aChnl
{
    return thresholds[aChnl];
}

- (void) setThreshold:(unsigned short) aChnl withValue:(unsigned long) aValue
{
    
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChnl withValue:[self threshold:aChnl]];
    
    // Set the new value in the model.
    thresholds[aChnl] = aValue;
    
    // Create a dictionary object that stores a pointer to this object and the channel that was changed.
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:ORSNOCaen1720Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSNOCaen1720ChnlThresholdChanged
	 object:self
	 userInfo:userInfo];
}

- (void) read
{
	short		start;
    short		end;
    short		i;   
    unsigned long 	theValue = 0;
    short theChannelIndex	 = [self selectedChannel];
    short theRegIndex		 = [self selectedRegIndex];
    
    @try {
        if (theRegIndex >= kZS_Thres && theRegIndex<=kAdcConfig){
            start = theChannelIndex;
            end = theChannelIndex;
            if(theChannelIndex >= [self numberOfChannels]) {
                start = 0;
                end = [self numberOfChannels] - 1;
            }
            
            // Loop through the thresholds and read them.
            for(i = start; i <= end; i++){
				theValue = [self readChan:i reg:theRegIndex];
                NSLog(@"%@ %2d = 0x%04lx\n", reg[theRegIndex].regName,i, theValue);
            }
        }
		else {
			theValue = [self read:theRegIndex];
			NSLog(@"CAEN reg [%@]:0x%04lx\n", [self getRegisterName:theRegIndex], theValue);
		}
        
	}
	@catch(NSException* localException) {
		NSLog(@"Can't Read [%@] on the %@.\n",
			  [self getRegisterName:theRegIndex], [self identifier]);
		[localException raise];
	}
}


//--------------------------------------------------------------------------------
/*!\method  write
 * \brief	Writes data out to a CAEN VME device register.
 * \note
 */
//--------------------------------------------------------------------------------
- (void) write
{
    short	start;
    short	end;
    short	i;
	
    long theValue			=  [self writeValue];
    short theChannelIndex	= [self selectedChannel];
    short theRegIndex 		= [self selectedRegIndex];
    
    @try {
        
        NSLog(@"Register is:%@\n", [self getRegisterName:theRegIndex]);
        NSLog(@"Value is   :0x%04x\n", theValue);
        
        if (theRegIndex >= kZS_Thres && theRegIndex<=kAdcConfig){
            start	= theChannelIndex;
            end 	= theChannelIndex;
            if(theChannelIndex >= [self numberOfChannels]){
				NSLog(@"Channel: ALL\n");
                start = 0;
                end = [self numberOfChannels] - 1;
            }
			else NSLog(@"Channel: %d\n", theChannelIndex);
			
            for (i = start; i <= end; i++){
                if(theRegIndex == kThresholds){
					[self setThreshold:i withValue:theValue];
				}
				[self writeChan:i reg:theRegIndex sendValue:theValue];
            }
        }
        
        // Handle all other registers
        else {
			[self write:theRegIndex sendValue: theValue];
        } 
	}
	@catch(NSException* localException) {
		NSLog(@"Can't write 0x%04lx to [%@] on the %@.\n",
			  theValue, [self getRegisterName:theRegIndex],[self identifier]);
		[localException raise];
	}
}


- (uint32_t) read:(uint32_t) pReg
{
    // Make sure that register is valid
    if (pReg >= [self getNumberRegisters]) {
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    // Make sure that one can read from register
    if([self getAccessType:pReg] != kReadOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (read not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }

    return [self intCommand:"caen_read %d", [self getAddressOffset:pReg]];
}

- (void) write:(uint32_t) pReg sendValue:(uint32_t) pValue
{
    // Check that register is a valid register.
    if (pReg >= [self getNumberRegisters]){
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    // Make sure that register can be written to.
    if([self getAccessType:pReg] != kWriteOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (write not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }
    
    [self okCommand:"caen_write %d %d", [self getAddressOffset:pReg], pValue];
}


- (void) writeThreshold:(unsigned short) pChan
{
    unsigned long threshold = [self threshold:pChan];
    
    [self writeChan:pChan reg:kThresholds sendValue:threshold];
}

- (void) writeOverUnderThresholds
{
	int i;
	for(i=0;i<8;i++){
		unsigned long aValue = overUnderThreshold[i];
		[self writeChan:i reg:kNumOUThreshold sendValue:aValue];
	}
}

- (void) readOverUnderThresholds
{
	int i;
	for(i=0;i<8;i++){
		unsigned long value = [self readChan:i reg:kNumOUThreshold];
	}
}

- (void) writeDacs
{
    short	i;
    for (i = 0; i < [self numberOfChannels]; i++){
        [self writeDac:i];
    }
}

- (void) writeDac:(unsigned short) pChan
{
    unsigned long 	aValue = [self dac:pChan];

    [self writeChan:pChan reg:kDacs sendValue:aValue];
}

- (void) generateSoftwareTrigger
{
    [self write:kSWTrigger sendValue:0];
}

- (void) writeChannelConfiguration
{
	unsigned long mask = [self channelConfigMask];
	[self write:kChanConfig sendValue:mask];
}

- (void) writeCustomSize
{
	unsigned long aValue = [self isCustomSize]?[self customSize]:0UL;
	[self write:kCustomSize sendValue:aValue];
}

- (void) report
{
	unsigned long enabled, threshold, numOU, status, bufferOccupancy, dacValue,triggerSrc;
	enabled = [self read:kChanEnableMask];
	triggerSrc = [self read:kTrigSrcEnblMask];
	int chan;
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"-----------------------------------------------------------\n");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Chan Enabled Thres  NumOver Status Buffers  Offset trigSrc\n");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"-----------------------------------------------------------\n");
	for(chan=0;chan<8;chan++){
		threshold = [self readChan:chan reg:kThresholds];
		numOU = [self readChan:chan reg:kNumOUThreshold];
		status = [self readChan:chan reg:kStatus];
		bufferOccupancy = [self readChan:chan reg:kBufferOccupancy];
		dacValue = [self readChan:chan reg:kDacs];
		NSString* statusString = @"";
		if(status & 0x20)			statusString = @"Error";
		else if(status & 0x04)		statusString = @"Busy ";
		else {
			if(status & 0x02)		statusString = @"Empty";
			else if(status & 0x01)	statusString = @"Full ";
		}
		NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"  %d     %@    0x%04x  0x%04x  %@  0x%04x  %6.3f  %@\n",
				  chan, enabled&(1<<chan)?@"E":@"X",
				  threshold&0xfff, numOU&0xfff,statusString, 
				  bufferOccupancy&0x7ff, [self convertDacToVolts:dacValue], 
				  triggerSrc&(1<<chan)?@"Y":@"N");
	}
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"-----------------------------------------------------------\n");
	
	unsigned long aValue;
	aValue = [self read:kBufferOrganization];
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"# Buffer Blocks : %d\n",(long)powf(2.,(float)aValue));
	
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Software Trigger: %@\n",triggerSrc&0x80000000?@"Enabled":@"Disabled");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"External Trigger: %@\n",triggerSrc&0x40000000?@"Enabled":@"Disabled");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Trigger nHit    : %d\n",(triggerSrc&0x00c000000) >> 24);
	
	
	aValue = [self read:kAcqControl];
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Triggers Count  : %@\n",aValue&0x4?@"Accepted":@"All");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Run Mode        : %@\n",Caen1720RunModeString[aValue&0x3]);
	
	aValue = [self read:kCustomSize];
	if(aValue)NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Custom Size     : %d\n",aValue);
	else      NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Custom Size     : Disabled\n");
	
	aValue = [self read:kAcqStatus];
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Board Ready     : %@\n",aValue&0x100?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"PLL Locked      : %@\n",aValue&0x80?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"PLL Bypass      : %@\n",aValue&0x40?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Clock source    : %@\n",aValue&0x20?@"External":@"Internal");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Buffer full     : %@\n",aValue&0x10?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Events Ready    : %@\n",aValue&0x08?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Run             : %@\n",aValue&0x04?@"ON":@"OFF");
	
	aValue = [self read:kEventStored];
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Events Stored   : %d\n",aValue);
	
} 

- (void) initBoard
{
    [self writeAcquistionControl:NO]; // Make sure it's off.
	[self clearAllMemory];
	[self softwareReset];
	[self writeThresholds];
	[self writeChannelConfiguration];
	[self writeCustomSize];
	[self writeTriggerSource];
	[self writeTriggerOut];
	[self writeFrontPanelControl];
	[self writeChannelEnabledMask];
	[self writeBufferOrganization];
	[self writeOverUnderThresholds];
	[self writeDacs];
	[self writePostTriggerSetting];
}

- (float) convertDacToVolts:(unsigned short)aDacValue 
{ 
	return 2*aDacValue/65535. - 0.9999;  
    //return 2*((short)aDacValue)/65535.;  
}

- (unsigned short) convertVoltsToDac:(float)aVoltage  
{ 
	return 65535. * (aVoltage+1)/2.; 
    //return (unsigned short)((short) (65535. * (aVoltage)/2.)); 
}

- (void) writeThresholds
{
    short	i;
    for (i = 0; i < [self numberOfChannels]; i++){
        [self writeThreshold:i];
    }
}

- (void) softwareReset
{
    [self write:kSWReset aValue:0];
}

- (void) clearAllMemory
{
    [self write:kSWClear aValue:0];
}

- (void) writeTriggerSource
{
    uint32_t aValue = ((coincidenceLevel&0x7)<<24) | (triggerSourceMask & 0xffffffff);
    [self write:kTrigSrcEnblMask sendValue:aValue];
}

- (void) writeTriggerOut
{
    [self write:kFPTrigOutEnblMask sendValue:triggerOutMask];
}

- (void) writeFrontPanelControl
{
    [self write:kFPIOControl sendValue:frontPanelControlMask];
}

- (void) readFrontPanelControl
{
	unsigned long aValue = 0;
	aValue = [self read:kFPIOControl];
	[self setFrontPanelControlMask:aValue];
}


- (void) writeBufferOrganization
{
	unsigned long aValue = eventSize;
	[self write:kBufferOrganization sendValue:aValue];
}

- (void) writeChannelEnabledMask
{
	unsigned long aValue = enabledMask;
	[self write:kChanEnableMask sendValue:aValue];
}

- (void) writePostTriggerSetting
{
    [self write:kPostTrigSetting sendValue:postTriggerSetting];
}

- (void) writeAcquistionControl:(BOOL)start
{
    unsigned long aValue = (countAllTriggers<<3) | (start<<2) | (acquisitionMode&0x3);
    [self write:kAcqControl sendValue:aValue];
}

- (void) writeNumberBLTEvents:(BOOL)enable
{
    //we must start in a safe mode with 1 event, the numberBLTEvents is passed to SBC
    //unsigned long aValue = (enable) ? numberBLTEventsToReadout : 0;
    unsigned long aValue = (enable) ? 1 : 0;

    [self write:kBLTEventNum sendValue:aValue];
}

- (void) writeEnableBerr:(BOOL)enable
{
    unsigned long aValue;
    aValue = [self read:kVMEControl];

    //we set both bit4: BERR and bit5: ALIGN64 for MBLT64 to work correctly with SBC
    if (enable) {
	aValue |= 0x30;
    } else {
	aValue &= 0xFFCF;
    }

    [self write:kVMEControl sendValue:aValue];
}

- (void) checkBufferAlarm
{
	if((bufferState == 1) && isRunning){
		bufferEmptyCount = 0;
		if(!bufferFullAlarm){
			NSString* alarmName = [NSString stringWithFormat:@"Buffer FULL V1720 (slot %d)",[self slot]];
			bufferFullAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kDataFlowAlarm];
			[bufferFullAlarm setSticky:YES];
			[bufferFullAlarm setHelpString:@"The rate is too high. Adjust the Threshold accordingly."];
			[bufferFullAlarm postAlarm];
		}
	}
	else {
		bufferEmptyCount++;
		if(bufferEmptyCount>=5){
			[bufferFullAlarm clearAlarm];
			[bufferFullAlarm release];
			bufferFullAlarm = nil;
			bufferEmptyCount = 0;
		}
	}
	if(isRunning){
		[self performSelector:@selector(checkBufferAlarm) withObject:nil afterDelay:1.5];
	}
	else {
		[bufferFullAlarm clearAlarm];
		[bufferFullAlarm release];
		bufferFullAlarm = nil;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOCaen1720ModelBufferCheckChanged object:self];
}

#pragma mark ***DataTaker
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORSNOCaen1720WaveformDecoder",				@"decoder",
								 [NSNumber numberWithLong:dataId],           @"dataId",
								 [NSNumber numberWithBool:YES],              @"variable",
								 [NSNumber numberWithLong:-1],               @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"CAEN1720"];
    return dataDictionary;
}

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<8;i++){
        waveFormCount[i]=0;
    }
}

- (void) reset
{
}

- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
	if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:NSStringFromClass([self class])]; 
    
	//cache for speed    
	controller		= [self adapter]; 
	statusReg		= [self baseAddress] + reg[kAcqStatus].addressOffset;
	eventSizeReg	= [self baseAddress] + reg[kEventSize].addressOffset;
	dataReg			= [self baseAddress] + reg[kOutputBuffer].addressOffset;
	location		=  (([self crateNumber]&0x01e)<<21) | (([self slot]& 0x0000001f)<<16);
	isRunning		= NO;
    
    BOOL sbcRun = [[userInfo objectForKey:kSBCisDataTaker] boolValue];

    [self startRates];

	if ([self continuousMode] && ![[userInfo objectForKey:@"doinit"] boolValue]) {
        //??
    }
    else {
        [self initBoard];
        [self writeNumberBLTEvents:sbcRun];
        [self writeEnableBerr:sbcRun];
        [self writeAcquistionControl:YES];
    }
	
	[self performSelector:@selector(checkBufferAlarm) withObject:nil afterDelay:1];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
{
	@try {
		unsigned long status;
		isRunning = YES; 
		
		[controller readLongBlock:&status
						atAddress:statusReg
						numToRead:1
					   withAddMod:addressModifier 
					usingAddSpace:0x01];
		bufferState = (status & 0x10) >> 4;						
		if(status & kEventReadyMask){
			//OK, at least one event is ready
			unsigned long theFirst;
			[controller readLongBlock:&theFirst
					atAddress:dataReg
					numToRead:1
				       withAddMod:addressModifier 
				    usingAddSpace:0x01]; //we set it to not increment the address.
			
			unsigned long theEventSize;
			theEventSize = theFirst&0x0FFFFFFF;
			if ( theEventSize == 0 ) return;

			NSMutableData* theData = [NSMutableData dataWithCapacity:2+theEventSize*sizeof(long)];
			[theData setLength:(2+theEventSize)*sizeof(long)];
			unsigned long* p = (unsigned long*)[theData bytes];
			*p++ = dataId | (2 + theEventSize);
			*p++ = location; 
			*p++ = theFirst;

			[controller readLongBlock:p
							atAddress:dataReg
							numToRead:theEventSize
						   withAddMod:addressModifier 
						usingAddSpace:0xFF]; //we set it to not increment the address.
			
			[aDataPacket addData:theData];
			unsigned short chanMask = p[0]; //remember, the point was already inc'ed to the start of data+1
			int i;
			for(i=0;i<8;i++){
				if(chanMask & (1<<i)) ++waveFormCount[i]; 
			}
		}
	}
	@catch(NSException* localException) {
	}
}

- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    isRunning = NO;
    [waveFormRateGroup stop];
	short i;
    for(i=0;i<8;i++)waveFormCount[i] = 0;
    
    NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* runControl;
    if ([objs count]) {
        runControl = [objs objectAtIndex:0];
        if ([self continuousMode] && [runControl nextRunWillQuickStart]) {
            return;
        }
    }
    [self writeAcquistionControl:NO];
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
	if(isRunning)return NO;
    
    ++waveFormCount[channel];
    return YES;
}


- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 1720 (Slot %d) ",[self slot]];
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kCaen1720; //should be unique
	configStruct->card_info[index].hw_mask[0] 	= dataId; //better be unique
	configStruct->card_info[index].slot			= [self slot];
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].add_mod		= [self addressModifier];
	configStruct->card_info[index].base_add		= [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0]	= reg[kVMEStatus].addressOffset; //VME Status buffer
    configStruct->card_info[index].deviceSpecificData[1]	= reg[kEventSize].addressOffset; // "next event size" address
    configStruct->card_info[index].deviceSpecificData[2]	= reg[kOutputBuffer].addressOffset; // fifo Address
    configStruct->card_info[index].deviceSpecificData[3]	= 0x0C; // fifo Address Modifier (A32 MBLT supervisory)
    configStruct->card_info[index].deviceSpecificData[4]	= 0x0FFC; // fifo Size, has to match datasheet
    configStruct->card_info[index].deviceSpecificData[5]	= location;
    configStruct->card_info[index].deviceSpecificData[6]	= reg[kVMEControl].addressOffset; // VME Control address
    configStruct->card_info[index].deviceSpecificData[7]	= reg[kBLTEventNum].addressOffset; // Num of BLT events address

    //sizeOfEvent is the size of a single event, regardless what the BLTEvent number is
    //SBC uses it to calculate number of blocks for the DMA transfer
    //unit is uint32_t word
	unsigned sizeOfEvent = 0;
	if (isFixedSize) {
		unsigned long numChan = 0;
		unsigned long chanMask = [self enabledMask];
		for (; chanMask; numChan++) chanMask &= chanMask - 1;
		if (isCustomSize) {
			sizeOfEvent = numChan * customSize * 2 + 4;
		}
		else {
			sizeOfEvent = numChan * (1UL << 20 >> [self eventSize]) / 4 + 4; //(1MB / num of blocks)
		}
	}
	configStruct->card_info[index].deviceSpecificData[8] = sizeOfEvent;
    configStruct->card_info[index].deviceSpecificData[9] = kNumberBLTEventsToReadout;
	configStruct->card_info[index].num_Trigger_Indexes = 0;
	configStruct->card_info[index].next_Card_Index = index+1;
	
	return index+1;
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setEventSize:[aDecoder decodeIntForKey:@"ORSNOCaen1720ModelEventSize"]];
    [self setEnabledMask:[aDecoder decodeIntForKey:@"ORSNOCaen1720ModelEnabledMask"]];
    [self setPostTriggerSetting:[aDecoder decodeInt32ForKey:@"ORSNOCaen1720ModelPostTriggerSetting"]];
    [self setTriggerSourceMask:[aDecoder decodeInt32ForKey:@"ORSNOCaen1720ModelTriggerSourceMask"]];
	[self setTriggerOutMask:[aDecoder decodeInt32ForKey:@"ORSNOCaen1720ModelTriggerOutMask"]];
	[self setFrontPanelControlMask:[aDecoder decodeInt32ForKey:@"ORSNOCaen1720ModelFrontPanelControlMask"]];
    [self setCoincidenceLevel:[aDecoder decodeIntForKey:@"ORSNOCaen1720ModelCoincidenceLevel"]];
    [self setAcquisitionMode:[aDecoder decodeIntForKey:@"acquisitionMode"]];
    [self setCountAllTriggers:[aDecoder decodeBoolForKey:@"countAllTriggers"]];
    [self setCustomSize:[aDecoder decodeInt32ForKey:@"customSize"]];
	[self setIsCustomSize:[aDecoder decodeBoolForKey:@"isCustomSize"]];
	[self setIsFixedSize:[aDecoder decodeBoolForKey:@"isFixedSize"]];
    [self setChannelConfigMask:[aDecoder decodeIntForKey:@"channelConfigMask"]];
    [self setWaveFormRateGroup:[aDecoder decodeObjectForKey:@"waveFormRateGroup"]];
    [self setNumberBLTEventsToReadout:[aDecoder decodeInt32ForKey:@"numberBLTEventsToReadout"]];
    [self setContinuousMode:[aDecoder decodeBoolForKey:@"continuousMode"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:8 groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	int i;
    for (i = 0; i < [self numberOfChannels]; i++){
        [self setDac:i withValue:      [aDecoder decodeInt32ForKey: [NSString stringWithFormat:@"CAENDacChnl%d", i]]];
        [self setThreshold:i withValue:[aDecoder decodeInt32ForKey: [NSString stringWithFormat:@"CAENThresChnl%d", i]]];
        [self setOverUnderThreshold:i withValue:[aDecoder decodeIntForKey: [NSString stringWithFormat:@"CAENOverUnderChnl%d", i]]];
    }
    
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
	[anEncoder encodeInt:eventSize forKey:@"ORSNOCaen1720ModelEventSize"];
	[anEncoder encodeInt:enabledMask forKey:@"ORSNOCaen1720ModelEnabledMask"];
	[anEncoder encodeInt32:postTriggerSetting forKey:@"ORSNOCaen1720ModelPostTriggerSetting"];
	[anEncoder encodeInt32:triggerSourceMask forKey:@"ORSNOCaen1720ModelTriggerSourceMask"];
	[anEncoder encodeInt32:triggerOutMask forKey:@"ORSNOCaen1720ModelTriggerOutMask"];
	[anEncoder encodeInt32:frontPanelControlMask forKey:@"ORSNOCaen1720ModelFrontPanelControlMask"];
	[anEncoder encodeInt:coincidenceLevel forKey:@"ORSNOCaen1720ModelCoincidenceLevel"];
	[anEncoder encodeInt:acquisitionMode forKey:@"acquisitionMode"];
	[anEncoder encodeBool:countAllTriggers forKey:@"countAllTriggers"];
	[anEncoder encodeInt32:customSize forKey:@"customSize"];
	[anEncoder encodeBool:isCustomSize forKey:@"isCustomSize"];
	[anEncoder encodeBool:isFixedSize forKey:@"isFixedSize"];
	[anEncoder encodeInt:channelConfigMask forKey:@"channelConfigMask"];
    [anEncoder encodeObject:waveFormRateGroup forKey:@"waveFormRateGroup"];
    [anEncoder encodeInt32:numberBLTEventsToReadout forKey:@"numberBLTEventsToReadout"];
    [anEncoder encodeBool:continuousMode forKey:@"continuousMode"];
	int i;
	for (i = 0; i < [self numberOfChannels]; i++){
        [anEncoder encodeInt32:dac[i] forKey:[NSString stringWithFormat:@"CAENDacChnl%d", i]];
        [anEncoder encodeInt32:thresholds[i] forKey:[NSString stringWithFormat:@"CAENThresChnl%d", i]];
        [anEncoder encodeInt:overUnderThreshold[i] forKey:[NSString stringWithFormat:@"CAENOverUnderChnl%d", i]];
    }
}

#pragma mark •••HW Wizard
- (int) numberOfChannels
{
    return 8;
}
-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:1200 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
	[p setInitMethodSelector:@selector(writeThresholds)];
    [a addObject:p];
    
	p = [[[ORHWWizParam alloc] init] autorelease];
	[p setUseValue:NO];
	[p setName:@"Init"];
	[p setSetMethodSelector:@selector(writeThresholds)];
	[a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:NSStringFromClass([self class])]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:NSStringFromClass([self class])]];
    return a;
    
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Threshold"])return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else return nil;
}

@end

@implementation ORSNOCaen1720DecoderForCAEN : ORCaenDataDecoder
- (NSString*) identifier
{
    return @"CAEN 1720 Digitizer";
}
@end

