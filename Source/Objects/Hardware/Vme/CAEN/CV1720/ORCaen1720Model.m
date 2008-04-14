//
//ORCaen1720Model.m
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

#import "ORCaen1720Model.h"
#import "ORVmeCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"


// Address information for this unit.
#define k792DefaultBaseAddress 		0xa00000
#define k792DefaultAddressModifier 	0x39

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
	{@"VME Status",			false,	false, 	false,	0xEF00,		kReadOnly},
	{@"Board ID",			false,	true, 	true,	0xEF08,		kReadWrite},
	{@"MultCast Base Add",	false,	false, 	true,	0xEF0C,		kReadWrite},
	{@"Relocation Add",		false,	false, 	true,	0xEF10,		kReadWrite},
	{@"Interrupt Status ID",false,	false, 	true,	0xEF14,		kReadWrite},
	{@"Interrupt Event Num",false,	true, 	true,	0xEF18,		kReadWrite},
	{@"BLT Event Num",		false,	true, 	true,	0xEF1C,		kReadWrite},
	{@"Scratch",			false,	true, 	true,	0xEF20,		kReadWrite},
	{@"SW Reset",			false,	false, 	false,	0xEF24,		kWriteOnly},
	{@"SW Clear",			false,	false, 	false,	0xEF28,		kWriteOnly},
	{@"Flash Enable",		false,	false, 	true,	0xEF2C,		kReadWrite},
	{@"Flash Data",			false,	false, 	true,	0xEF30,		kReadWrite},
	{@"Config Reload",		false,	false, 	false,	0xEF34,		kWriteOnly},
	{@"Config ROM",			false,	false, 	false,	0xF000,		kReadOnly}
};

NSString* ORCaen1720ModelEnabledMaskChanged			= @"ORCaen1720ModelEnabledMaskChanged";
NSString* ORCaen1720ModelPostTriggerSettingChanged	= @"ORCaen1720ModelPostTriggerSettingChanged";
NSString* ORCaen1720ModelTriggerSourceMaskChanged	= @"ORCaen1720ModelTriggerSourceMaskChanged";
NSString* ORCaen1720ModelCoincidenceLevelChanged	= @"ORCaen1720ModelCoincidenceLevelChanged";
NSString* ORCaen1720ModelAcquisitionModeChanged		= @"ORCaen1720ModelAcquisitionModeChanged";
NSString* ORCaen1720ModelCountAllTriggersChanged	= @"ORCaen1720ModelCountAllTriggersChanged";
NSString* ORCaen1720ModelCustomSizeChanged			= @"ORCaen1720ModelCustomSizeChanged";
NSString* ORCaen1720ModelChannelConfigMaskChanged	= @"ORCaen1720ModelChannelConfigMaskChanged";
NSString* ORCaen1720ChnlDacChanged					= @"ORCaen1720ChnlDacChanged";
NSString* ORCaen1720OverUnderThresholdChanged		= @"ORCaen1720OverUnderThresholdChanged";
NSString* ORCaen1720Chnl							= @"ORCaen1720Chnl";
NSString* ORCaen1720ChnlThresholdChanged			= @"ORCaen1720ChnlThresholdChanged";
NSString* ORCaen1720SelectedChannelChanged			= @"ORCaen1720SelectedChannelChanged";
NSString* ORCaen1720SelectedRegIndexChanged			= @"ORCaen1720SelectedRegIndexChanged";
NSString* ORCaen1720WriteValueChanged				= @"ORCaen1720WriteValueChanged";
NSString* ORCaen1720BasicLock						= @"ORCaen1720BasicLock";
NSString* ORCaen1720SettingsLock					= @"ORCaen1720SettingsLock";

@implementation ORCaen1720Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k792DefaultBaseAddress];
    [self setAddressModifier:k792DefaultAddressModifier];
	[self setEnabledMask:0xFF];
    [[self undoManager] enableUndoRegistration];
   
    return self;
}

#pragma mark ***Accessors
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
        postNotificationName:ORCaen1720SelectedRegIndexChanged
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
        postNotificationName:ORCaen1720SelectedChannelChanged
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
        postNotificationName:ORCaen1720WriteValueChanged
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1720ModelEnabledMaskChanged object:self];
}

- (unsigned long) postTriggerSetting
{
    return postTriggerSetting;
}

- (void) setPostTriggerSetting:(unsigned long)aPostTriggerSetting
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerSetting:postTriggerSetting];
    
    postTriggerSetting = aPostTriggerSetting;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1720ModelPostTriggerSettingChanged object:self];
}

- (unsigned long) triggerSourceMask
{
    return triggerSourceMask;
}

- (void) setTriggerSourceMask:(unsigned long)aTriggerSourceMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerSourceMask:triggerSourceMask];
    
    triggerSourceMask = aTriggerSourceMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1720ModelTriggerSourceMaskChanged object:self];
}

- (unsigned short) coincidenceLevel
{
    return coincidenceLevel;
}

- (void) setCoincidenceLevel:(unsigned short)aCoincidenceLevel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCoincidenceLevel:coincidenceLevel];
    
    coincidenceLevel = aCoincidenceLevel;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1720ModelCoincidenceLevelChanged object:self];
}

- (unsigned short) acquisitionMode
{
    return acquisitionMode;
}

- (void) setAcquisitionMode:(unsigned short)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAcquisitionMode:acquisitionMode];
    
    acquisitionMode = aMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1720ModelAcquisitionModeChanged object:self];
}

- (BOOL) countAllTriggers
{
    return countAllTriggers;
}

- (void) setCountAllTriggers:(BOOL)aCountAllTriggers
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCountAllTriggers:countAllTriggers];
    
    countAllTriggers = aCountAllTriggers;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1720ModelCountAllTriggersChanged object:self];
}

- (unsigned long) customSize
{
    return customSize;
}

- (void) setCustomSize:(unsigned long)aCustomSize
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCustomSize:customSize];
    
    customSize = aCustomSize;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1720ModelCustomSizeChanged object:self];
}

- (unsigned short) channelConfigMask
{
    return channelConfigMask;
}

- (void) setChannelConfigMask:(unsigned short)aChannelConfigMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChannelConfigMask:channelConfigMask];
    
    channelConfigMask = aChannelConfigMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1720ModelChannelConfigMaskChanged object:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Caen1720Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCaen1720Controller"];
 }


#pragma mark ***Register - General routines
- (short) getNumberRegisters
{
    return kNumRegisters;
}

- (unsigned long) getBufferOffset
{
    return reg[kOutputBuffer].addressOffset;
}

- (unsigned short) getDataBufferSize
{
    return kEventBufferSize;
}

- (unsigned long) getThresholdOffset
{
   return reg[kThresholds].addressOffset;
}

- (short) getStatusRegisterIndex:(short) aRegister
{
  //  if (aRegister == 1) return kStatusRegister1;
   // else		return kStatusRegister2;
	return 0;
}

- (short) getThresholdIndex
{
    return kThresholds;
}

- (short) getOutputBufferIndex
{
    return kOutputBuffer;
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
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:ORCaen1720Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORCaen1720ChnlDacChanged
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
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:ORCaen1720Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORCaen1720OverUnderThresholdChanged
                      object:self
                    userInfo:userInfo];
}



- (void) readChan:(unsigned short)chan reg:(unsigned short) pReg returnValue:(unsigned short*) pValue
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
    
    // Perform the read operation.
    [[self adapter] readWordBlock:pValue
                        atAddress:[self baseAddress] + [self getAddressOffset:pReg] + chan*0x100
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
}

- (void) writeChan:(unsigned short)chan reg:(unsigned short) pReg sendValue:(unsigned short) pValue
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
    
    // Do actual write
    NS_DURING
		[[self adapter] writeLongBlock:&theValue
                                 atAddress:[self baseAddress] + [self getAddressOffset:pReg] + chan*0x100
                                numToWrite:1
                                withAddMod:[self addressModifier]
                             usingAddSpace:0x01];
            
        NS_HANDLER
		NS_ENDHANDLER
}

- (unsigned short) threshold:(unsigned short) aChnl
{
    return thresholds[aChnl];
}

- (void) setThreshold:(unsigned short) aChnl threshold:(unsigned long) aValue
{
    
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChnl threshold:[self threshold:aChnl]];
    
    // Set the new value in the model.
    thresholds[aChnl] = aValue;
    
    // Create a dictionary object that stores a pointer to this object and the channel that was changed.
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:ORCaen1720Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORCaen1720ChnlThresholdChanged
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
    
    NS_DURING
        if (theRegIndex >= kZS_Thres && theRegIndex<=kAdcConfig){
            start = theChannelIndex;
            end = theChannelIndex;
            if(theChannelIndex >= [self numberOfChannels]) {
                start = 0;
                end = [self numberOfChannels] - 1;
            }
            
            // Loop through the thresholds and read them.
            for(i = start; i <= end; i++){
                [self readThreshold:i];
                NSLog(@"%@ %2d = 0x%04lx\n", reg[theRegIndex].regName,i, [self threshold:i]);
            }
        }
		else {
			[self read:theRegIndex returnValue:&theValue];
			NSLog(@"CAEN reg [%@]:0x%04lx\n", [self getRegisterName:theRegIndex], theValue);
		}
        
	NS_HANDLER
		NSLog(@"Can't Read [%@] on the %@.\n",
		[self getRegisterName:theRegIndex], [self identifier]);
		[localException raise];
	NS_ENDHANDLER
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
    
    NS_DURING
        
        NSLog(@"Register is:%d\n", theRegIndex);
        NSLog(@"Index is   :%d\n", theChannelIndex);
        NSLog(@"Value is   :0x%04x\n", theValue);
        
        if (theRegIndex >= kZS_Thres && theRegIndex<=kAdcConfig){
            start	= theChannelIndex;
            end 	= theChannelIndex;
            if(theChannelIndex >= [self numberOfChannels]){
                start = 0;
                end = [self numberOfChannels] - 1;
            }
            for (i = start; i <= end; i++){
                if(theRegIndex == kThresholds){
					[self setThreshold:i threshold:theValue];
				}
				[self write:theRegIndex sendValue: theValue];
            }
        }
        
        // Handle all other registers
        else {
			[self write:theRegIndex sendValue: theValue];
        } 
        NS_HANDLER
            NSLog(@"Can't write 0x%04lx to [%@] on the %@.\n",
                  theValue, [self getRegisterName:theRegIndex],[self identifier]);
            [localException raise];
        NS_ENDHANDLER
}


- (void) read:(unsigned short) pReg returnValue:(unsigned long*) pValue
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
    
    // Perform the read operation.
    [[self adapter] readLongBlock:pValue
                        atAddress:[self baseAddress] + [self getAddressOffset:pReg]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
}

- (void) write:(unsigned short) pReg sendValue:(unsigned long) pValue
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
    
    // Do actual write
    NS_DURING
		[[self adapter] writeLongBlock:&pValue
							atAddress:[self baseAddress] + [self getAddressOffset:pReg]
							numToWrite:1
							withAddMod:[self addressModifier]
							usingAddSpace:0x01];
            
        NS_HANDLER
            NS_ENDHANDLER
}


- (void) readThreshold:(unsigned short) pChan
{
    
    unsigned long value;
    
    // Read the threshold
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + [self getThresholdOffset] + (pChan * 0x100)
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    // Store new value
    [self setThreshold:pChan threshold:value];
    
}

- (void) writeThreshold:(unsigned short) pChan
{
    unsigned long 	threshold = [self threshold:pChan];
    
    [[self adapter] writeLongBlock:&threshold
                         atAddress:[self baseAddress] + [self getThresholdOffset] + (pChan * 0x100)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) readOverUnderThresholds
{
	int i;
	for(i=0;i<8;i++){
		unsigned long value;
		[[self adapter] readLongBlock:&value
                         atAddress:[self baseAddress] + reg[kNumOUThreshold].addressOffset + (i * 0x100)
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
		[self setOverUnderThreshold:i withValue:value];
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
    unsigned long 	threshold = [self threshold:pChan];
    
    [[self adapter] writeLongBlock:&threshold
                         atAddress:[self baseAddress] + reg[kDacs].addressOffset + (pChan * 0x100)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) generateSoftwareTrigger
{
	unsigned long dummy = 0;
    [[self adapter] writeLongBlock:&dummy
                         atAddress:[self baseAddress] + reg[kSWTrigger].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeChannelConfiguration
{
	//there is some mystery about the channel config set/clr bits....
	//This is our best guess so far about what to do.
	//load the channel Config 
	unsigned long mask = [self channelConfigMask];
	[[self adapter] writeLongBlock:&mask
                         atAddress:[self baseAddress] + reg[kChanConfig].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
					 
	//clear ALL of the channel config bits
    mask = 0xff;	
    [[self adapter] writeLongBlock:&mask
                         atAddress:[self baseAddress] + reg[kChanConfigBitClr].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];

	//set the enabled channel's channel config bits
	mask = [self enabledMask];
    [[self adapter] writeLongBlock:&mask
                         atAddress:[self baseAddress] + reg[kChanConfigBitSet].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeCustomSize
{
	unsigned long aValue = [self customSize];
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kCustomSize].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) initBoard
{
	[self writeThresholds];
	[self writeDacs];
	[self writeChannelConfiguration];
	[self writeCustomSize];
	[self writeTriggerSource];
	[self writeChannelEnabledMask];
}

- (float) convertDacToVolts:(unsigned short)aDacValue 
{ 
	return 2*aDacValue/65535. - 0.9999;  
}

- (unsigned short) convertVoltsToDac:(float)aVoltage  
{ 
	return 65535. * (aVoltage+1)/2.; 
}

- (void) writeThresholds
{
    short	i;
    
    for (i = 0; i < [self numberOfChannels]; i++){
        [self writeThreshold:i];
    }
}

- (void) writeTriggerSource
{
	unsigned long aValue = ((coincidenceLevel&0x7)<<24) | (triggerSourceMask & 0xffffffff);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kTrigSrcEnblMask].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}

- (void) writeChannelEnabledMask
{
	unsigned long aValue = enabledMask;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kChanEnableMask].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}

- (void) writePostTriggerSetting
{
	[[self adapter] writeLongBlock:&postTriggerSetting
                         atAddress:[self baseAddress] + reg[kPostTrigSetting].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}


- (void) writeAcquistionControl:(BOOL)start
{
	unsigned long aValue = (countAllTriggers<<3) | (start<<2) | (acquisitionMode&0x3);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kAcqControl].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
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
    
    NSString* decoderName = [[NSStringFromClass([self class]) componentsSeparatedByString:@"Model"] componentsJoinedByString:@"DecoderFor"];
    decoderName = [decoderName stringByAppendingString:@"CAEN"];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORCaen1720WaveformDecoder",				"decoder",
        [NSNumber numberWithLong:dataId],           @"dataId",
        [NSNumber numberWithBool:YES],              @"variable",
        [NSNumber numberWithLong:-1],               @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"CAEN"];
    return dataDictionary;
}


- (void) reset
{
    //required by the datataking protocal.
}

- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
   if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:NSStringFromClass([self class])]; 
    
    controller = [self adapter]; //cache for speed
	     
    [self initBoard];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
{
}

- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 792 (Slot %d) ",[self slot]];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];

    [[self undoManager] disableUndoRegistration];
    [self setEnabledMask:[aDecoder decodeIntForKey:@"ORCaen1720ModelEnabledMask"]];
    [self setPostTriggerSetting:[aDecoder decodeInt32ForKey:@"ORCaen1720ModelPostTriggerSetting"]];
    [self setTriggerSourceMask:[aDecoder decodeInt32ForKey:@"ORCaen1720ModelTriggerSourceMask"]];
    [self setCoincidenceLevel:[aDecoder decodeIntForKey:@"ORCaen1720ModelCoincidenceLevel"]];
    [self setAcquisitionMode:[aDecoder decodeIntForKey:@"acquisitionMode"]];
    [self setCountAllTriggers:[aDecoder decodeBoolForKey:@"countAllTriggers"]];
    [self setCustomSize:[aDecoder decodeInt32ForKey:@"customSize"]];
    [self setChannelConfigMask:[aDecoder decodeIntForKey:@"channelConfigMask"]];

	int i;
    for (i = 0; i < [self numberOfChannels]; i++){
        [self setDac:i withValue:[aDecoder decodeIntForKey: [NSString stringWithFormat:@"CAENDacChnl%d", i]]];
    }
    
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
	[anEncoder encodeInt:enabledMask forKey:@"ORCaen1720ModelEnabledMask"];
	[anEncoder encodeInt32:postTriggerSetting forKey:@"ORCaen1720ModelPostTriggerSetting"];
	[anEncoder encodeInt32:triggerSourceMask forKey:@"ORCaen1720ModelTriggerSourceMask"];
	[anEncoder encodeInt:coincidenceLevel forKey:@"ORCaen1720ModelCoincidenceLevel"];
	[anEncoder encodeInt:acquisitionMode forKey:@"acquisitionMode"];
	[anEncoder encodeBool:countAllTriggers forKey:@"countAllTriggers"];
	[anEncoder encodeInt32:customSize forKey:@"customSize"];
	[anEncoder encodeInt:channelConfigMask forKey:@"channelConfigMask"];
	int i;
	for (i = 0; i < [self numberOfChannels]; i++){
        [anEncoder encodeInt:dac[i] forKey:[NSString stringWithFormat:@"CAENDacChnl%d", i]];
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
    [p setSetMethod:@selector(setThreshold:threshold:) getMethod:@selector(threshold:)];
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

@implementation ORCaen1720DecoderForCAEN : ORCaenDataDecoder
- (NSString*) identifier
{
    return @"CAEN 1720 Digitizer";
}
@end

