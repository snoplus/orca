//
//  ORDT5720Model.m
//  Orca
//
//  USB Relay I/O Interface
//
//  Created by Mark Howe on Thurs Jan 26 2007.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORDT5720Model.h"
#import "ORUSBInterface.h"
#import "ORDataTypeAssigner.h"
#import "ORDataSet.h"
#import "ORRateGroup.h"

NSString* ORDT5720ModelUSBInterfaceChanged                = @"ORDT5720ModelUSBInterfaceChanged";
NSString* ORDT5720ModelLock                               = @"ORDT5720ModelLock";
NSString* ORDT5720ModelSerialNumberChanged                = @"ORDT5720ModelSerialNumberChanged";

NSString* ORDT5720USBInConnection                         = @"ORDT5720USBInConnection";
NSString* ORDT5720USBNextConnection                       = @"ORDT5720USBNextConnection";
NSString* ORDT5720ModelEnabledMaskChanged                 = @"ORDT5720ModelEnabledMaskChanged";
NSString* ORDT5720ModelPostTriggerSettingChanged          = @"ORDT5720ModelPostTriggerSettingChanged";
NSString* ORDT5720ModelTriggerSourceMaskChanged           = @"ORDT5720ModelTriggerSourceMaskChanged";
NSString* ORDT5720ModelTriggerOutMaskChanged              = @"ORDT5720ModelTriggerOutMaskChanged";
NSString* ORDT5720ModelFrontPanelControlMaskChanged       = @"ORDT5720ModelFrontPanelControlMaskChanged";
NSString* ORDT5720ModelCoincidenceLevelChanged            = @"ORDT5720ModelCoincidenceLevelChanged";
NSString* ORDT5720ModelAcquisitionModeChanged             = @"ORDT5720ModelAcquisitionModeChanged";
NSString* ORDT5720ModelCountAllTriggersChanged            = @"ORDT5720ModelCountAllTriggersChanged";
NSString* ORDT5720ModelCustomSizeChanged                  = @"ORDT5720ModelCustomSizeChanged";
NSString* ORDT5720ModelIsCustomSizeChanged                = @"ORDT5720ModelIsCustomSizeChanged";
NSString* ORDT5720ModelIsFixedSizeChanged                 = @"ORDT5720ModelIsFixedSizeChanged";
NSString* ORDT5720ModelChannelConfigMaskChanged           = @"ORDT5720ModelChannelConfigMaskChanged";
NSString* ORDT5720ModelNumberBLTEventsToReadoutChanged    = @"ORDT5720ModelNumberBLTEventsToReadoutChanged";
NSString* ORDT5720ChnlDacChanged                          = @"ORDT5720ChnlDacChanged";
NSString* ORDT5720OverUnderThresholdChanged               = @"ORDT5720OverUnderThresholdChanged";
NSString* ORDT5720Chnl                                    = @"ORDT5720Chnl";
NSString* ORDT5720ChnlThresholdChanged                    = @"ORDT5720ChnlThresholdChanged";
NSString* ORDT5720SelectedChannelChanged                  = @"ORDT5720SelectedChannelChanged";
NSString* ORDT5720SelectedRegIndexChanged                 = @"ORDT5720SelectedRegIndexChanged";
NSString* ORDT5720WriteValueChanged                       = @"ORDT5720WriteValueChanged";
NSString* ORDT5720BasicLock                               = @"ORDT5720BasicLock";
NSString* ORDT5720SettingsLock                            = @"ORDT5720SettingsLock";
NSString* ORDT5720RateGroupChanged                        = @"ORDT5720RateGroupChanged";
NSString* ORDT5720ModelBufferCheckChanged                 = @"ORDT5720ModelBufferCheckChanged";
NSString* ORDT5720ModelContinuousModeChanged              = @"ORDT5720ModelContinuousModeChanged";
NSString* ORDT5720ModelEventSizeChanged                   = @"ORDT5720ModelEventSizeChanged";

static DT5720RegisterNamesStruct reg[kNumberDT5720Registers] = {
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

static NSString* DT5720RunModeString[4] = {
    @"Register-Controlled",
    @"S-In Controlled",
    @"S-In Gate",
    @"Multi-Board Sync",
};

@implementation ORDT5720Model
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	[self setEnabledMask:0xF];
    [self setEventSize:0xa];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void) makeConnectors
{
	ORConnector* connectorObj1 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( 0, [self frame].size.height/2- kConnectorSize/2 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj1 forKey: ORDT5720USBInConnection ];
	[ connectorObj1 setConnectorType: 'USBI' ];
	[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to gpib outputs
	[connectorObj1 setOffColor:[NSColor yellowColor]];
	[ connectorObj1 release ];
	
	ORConnector* connectorObj2 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, [self frame].size.height/2- kConnectorSize/2)
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj2 forKey: ORDT5720USBNextConnection ];
	[ connectorObj2 setConnectorType: 'USBO' ];
	[ connectorObj2 addRestrictedConnectionType: 'USBI' ]; //can only connect to gpib inputs
	[connectorObj2 setOffColor:[NSColor yellowColor]];
	[ connectorObj2 release ];
}

- (void) makeMainController
{
    [self linkToController:@"ORDT5720Controller"];
}

- (NSString*) helpURL
{
	return @"USB/DT5720.html";
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[usbInterface release];
    [serialNumber release];
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		[self connectionChanged];
	}
	@catch(NSException* localException) {
	}
	
}

- (void) connectionChanged
{
	NSArray* interfaces = [[self getUSBController] interfacesForVender:[self vendorID] product:[self productID]];
	NSString* sn = serialNumber;
	if([interfaces count] == 1 && ![sn length]){
		sn = [[interfaces objectAtIndex:0] serialNumber];
	}
	[self setSerialNumber:sn]; //to force usbinterface at doc startup
	[self checkUSBAlarm];
	[[self objectConnectedTo:ORDT5720USBNextConnection] connectionChanged];
}

-(void) setUpImage
{
	
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
	NSImage* aCachedImage = [NSImage imageNamed:@"DT5720"];
    if(!usbInterface || ![self getUSBController]){
		NSSize theIconSize = [aCachedImage size];
		
		NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
		[i lockFocus];
		
        [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];		
		NSBezierPath* path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(15,8)];
		[path lineToPoint:NSMakePoint(30,28)];
		[path moveToPoint:NSMakePoint(15,28)];
		[path lineToPoint:NSMakePoint(30,8)];
		[path setLineWidth:3];
		[[NSColor yellowColor] set];
		[path stroke];
		
		[i unlockFocus];
		
		[self setImage:i];
		[i release];
    }
	else {
		[ self setImage: aCachedImage];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
	
}

- (NSString*) title 
{
	return [NSString stringWithFormat:@"DT5720 (Serial# %@)",[usbInterface serialNumber]];
}

- (unsigned long) vendorID
{
	return 0x21E1UL; //DT5720
}

- (unsigned long) productID
{
	return 0x0000UL; //DT5720
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORDT5720USBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

#pragma mark ***Accessors
- (ORUSBInterface*) usbInterface
{
	return usbInterface;
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];
	[self checkUSBAlarm];
}

- (void) setUsbInterface:(ORUSBInterface*)anInterface
{	
	if(anInterface != usbInterface){
		[usbInterface release];
		usbInterface = anInterface;
		[usbInterface retain];
		[usbInterface setUsePipeType:kUSBInterrupt];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: ORDT5720ModelUSBInterfaceChanged object: self];

		[self checkUSBAlarm];
	}
}

- (void)checkUSBAlarm
{
	if((usbInterface && [self getUSBController]) || !guardian){
		[noUSBAlarm clearAlarm];
		[noUSBAlarm release];
		noUSBAlarm = nil;
	}
	else {
		if(guardian){
			if(!noUSBAlarm){
				noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for DT5720"] severity:kHardwareAlarm];
				[noUSBAlarm setSticky:YES];		
			}
			[noUSBAlarm setAcknowledged:NO];
			[noUSBAlarm postAlarm];
		}
	}
	
	[self setUpImage];
	
}

- (void) interfaceAdded:(NSNotification*)aNote
{
	[[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
	ORUSBInterface* theInterfaceRemoved = [[aNote userInfo] objectForKey:@"USBInterface"];
	if((usbInterface == theInterfaceRemoved) && serialNumber){
		[self setUsbInterface:nil];
	}
}

- (NSString*) usbInterfaceDescription
{
	if(usbInterface)return [usbInterface description];
	else return @"?";
}

- (void) registerWithUSB:(id)usb
{
	[usb registerForUSBNotifications:self];
}

- (NSString*) hwName
{
	if(usbInterface)return [usbInterface deviceName];
	else return @"?";
}

- (void) makeUSBClaim:(NSString*)aSerialNumber
{	
}
- (NSString*) serialNumber
{
    return serialNumber;
}

- (void) setSerialNumber:(NSString*)aSerialNumber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerialNumber:serialNumber];
    
    [serialNumber autorelease];
    serialNumber = [aSerialNumber copy];
	
	if(!serialNumber){
		[[self getUSBController] releaseInterfaceFor:self];
	}
	else {
		[[self getUSBController] claimInterfaceWithSerialNumber:serialNumber for:self];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelSerialNumberChanged object:self];
	[self checkUSBAlarm];
}

- (BOOL) continuousMode
{
    return continuousMode;
}

- (void) setContinuousMode:(BOOL)aContinuousMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setContinuousMode:continuousMode];
    
    continuousMode = aContinuousMode;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelContinuousModeChanged object:self];
}


- (int) eventSize
{
    return eventSize;
}

- (void) setEventSize:(int)aEventSize
{
	//if(aEventSize == 0)aEventSize = 0xa; //default
	
    [[[self undoManager] prepareWithInvocationTarget:self] setEventSize:eventSize];
    
    eventSize = aEventSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelEventSizeChanged object:self];
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
	 postNotificationName:ORDT5720RateGroupChanged
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
	 postNotificationName:ORDT5720SelectedRegIndexChanged
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
	 postNotificationName:ORDT5720SelectedChannelChanged
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
	 postNotificationName:ORDT5720WriteValueChanged
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelEnabledMaskChanged object:self];
}

- (unsigned long) postTriggerSetting
{
    return postTriggerSetting;
}

- (void) setPostTriggerSetting:(unsigned long)aPostTriggerSetting
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerSetting:postTriggerSetting];
    
    postTriggerSetting = aPostTriggerSetting;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelPostTriggerSettingChanged object:self];
}

- (unsigned long) triggerSourceMask
{
    return triggerSourceMask;
}

- (void) setTriggerSourceMask:(unsigned long)aTriggerSourceMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerSourceMask:triggerSourceMask];
    
    triggerSourceMask = aTriggerSourceMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelTriggerSourceMaskChanged object:self];
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
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelTriggerOutMaskChanged object:self];
}

- (unsigned long) frontPanelControlMask
{
	return frontPanelControlMask;
}

- (void) setFrontPanelControlMask:(unsigned long)aFrontPanelControlMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setFrontPanelControlMask:aFrontPanelControlMask];
	
	frontPanelControlMask = aFrontPanelControlMask;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelFrontPanelControlMaskChanged object:self];
}

- (unsigned short) coincidenceLevel
{
    return coincidenceLevel;
}

- (void) setCoincidenceLevel:(unsigned short)aCoincidenceLevel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCoincidenceLevel:coincidenceLevel];
    
    coincidenceLevel = aCoincidenceLevel;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelCoincidenceLevelChanged object:self];
}

- (unsigned short) acquisitionMode
{
    return acquisitionMode;
}

- (void) setAcquisitionMode:(unsigned short)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAcquisitionMode:acquisitionMode];
    
    acquisitionMode = aMode;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelAcquisitionModeChanged object:self];
}

- (BOOL) countAllTriggers
{
    return countAllTriggers;
}

- (void) setCountAllTriggers:(BOOL)aCountAllTriggers
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCountAllTriggers:countAllTriggers];
    
    countAllTriggers = aCountAllTriggers;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelCountAllTriggersChanged object:self];
}

- (unsigned long) customSize
{
    return customSize;
}

- (void) setCustomSize:(unsigned long)aCustomSize
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCustomSize:customSize];
    
    customSize = aCustomSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelCustomSizeChanged object:self];
}

- (BOOL) isCustomSize
{
	return isCustomSize;
}

- (void) setIsCustomSize:(BOOL)aIsCustomSize
{
	[[[self undoManager] prepareWithInvocationTarget:self] setIsCustomSize:isCustomSize];
	
	isCustomSize = aIsCustomSize;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelIsCustomSizeChanged object:self];
}

- (BOOL) isFixedSize
{
	return isFixedSize;
}

- (void) setIsFixedSize:(BOOL)aIsFixedSize
{
	[[[self undoManager] prepareWithInvocationTarget:self] setIsFixedSize:isFixedSize];
	
	isFixedSize = aIsFixedSize;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelIsFixedSizeChanged object:self];
}

- (unsigned short) channelConfigMask
{
    return channelConfigMask;
}

- (void) setChannelConfigMask:(unsigned short)aChannelConfigMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChannelConfigMask:channelConfigMask];
    
    channelConfigMask = aChannelConfigMask;
	
	//can't get the packed form to work so just make sure that bit is cleared.
	channelConfigMask &= ~(1L<<11);
    
	//we do the sequential memory access only
	channelConfigMask |= (1L<<4);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelChannelConfigMaskChanged object:self];
}

- (unsigned long) numberBLTEventsToReadout
{
    return numberBLTEventsToReadout;
}

- (void) setNumberBLTEventsToReadout:(unsigned long) numBLTEvents
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNumberBLTEventsToReadout:numberBLTEventsToReadout];
    
    numberBLTEventsToReadout = numBLTEvents;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelNumberBLTEventsToReadoutChanged object:self];
}

#pragma mark ***Register - General routines
- (short) getNumberRegisters
{
    return kNumberDT5720Registers;
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
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:ORDT5720Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDT5720ChnlDacChanged
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
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:ORDT5720Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDT5720OverUnderThresholdChanged
	 object:self
	 userInfo:userInfo];
}

- (void) readChan:(unsigned short)chan reg:(unsigned short) pReg returnValue:(unsigned long*) pValue
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
    [self  readLongBlock:pValue
                        atAddress:[self baseAddress] + [self getAddressOffset:pReg] + chan*0x100
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
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
    
    // Do actual write
    @try {
		[[self adapter] writeLongBlock:&theValue
							 atAddress:[self baseAddress] + [self getAddressOffset:pReg] + chan*0x100
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
		
	}
	@catch(NSException* localException) {
	}
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
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:ORDT5720Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDT5720ChnlThresholdChanged
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
            if(theChannelIndex >= kNumDT5720Channels) {
                start = 0;
                end = kNumDT5720Channels - 1;
            }
            
            // Loop through the thresholds and read them.
            for(i = start; i <= end; i++){
				[self readChan:i reg:theRegIndex returnValue:&theValue];
                NSLog(@"%@ %2d = 0x%04lx\n", reg[theRegIndex].regName,i, theValue);
            }
        }
		else {
			[self read:theRegIndex returnValue:&theValue];
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
            if(theChannelIndex >= kNumDT5720Channels){
				NSLog(@"Channel: ALL\n");
                start = 0;
                end = kNumDT5720Channels - 1;
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
    @try {
		[[self adapter] writeLongBlock:&pValue
                   atAddress:[self baseAddress] + [self getAddressOffset:pReg]
                  numToWrite:1
                  withAddMod:[self addressModifier]
               usingAddSpace:0x01];
		
	}
	@catch(NSException* localException) {
	}
}


- (void) writeThreshold:(unsigned short) pChan
{
    unsigned long 	threshold = [self threshold:pChan];
    
    [[self adapter] writeLongBlock:&threshold
                         atAddress:[self baseAddress] + reg[kThresholds].addressOffset + (pChan * 0x100)
                        numToWrite:1
                       withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeOverUnderThresholds
{
	int i;
	for(i=0;i<kNumDT5720Channels;i++){
		unsigned long aValue = overUnderThreshold[i];
		[[self adapter] writeLongBlock:&aValue
							 atAddress:[self baseAddress] + reg[kNumOUThreshold].addressOffset + (i * 0x100)
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (void) readOverUnderThresholds
{
	int i;
	for(i=0;i<kNumDT5720Channels;i++){
		unsigned long value;
		[[self adapter] readLongBlock:&value
							atAddress:[self baseAddress] + reg[kNumOUThreshold].addressOffset + (i * 0x100)
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];

 }
}

- (void) writeDacs
{
    short	i;
    for (i = 0; i < kNumDT5720Channels; i++){
        [self writeDac:i];
    }
}

- (void) writeDac:(unsigned short) pChan
{
    unsigned long 	aValue = [self dac:pChan];
    
    [[self adapter] writeLongBlock:&aValue
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
	unsigned long mask = [self channelConfigMask];
	[[self adapter] writeLongBlock:&mask
                         atAddress:[self baseAddress] + reg[kChanConfig].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeCustomSize
{
	unsigned long aValue = [self isCustomSize]?[self customSize]:0UL;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kCustomSize].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) report
{
	unsigned long enabled, threshold, numOU, status, bufferOccupancy, dacValue,triggerSrc;
	[self read:kChanEnableMask returnValue:&enabled];
	[self read:kTrigSrcEnblMask returnValue:&triggerSrc];
	int chan;
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"-----------------------------------------------------------\n");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Chan Enabled Thres  NumOver Status Buffers  Offset trigSrc\n");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"-----------------------------------------------------------\n");
	for(chan=0;chan<8;chan++){
		[self readChan:chan reg:kThresholds returnValue:&threshold];
		[self readChan:chan reg:kNumOUThreshold returnValue:&numOU];
		[self readChan:chan reg:kStatus returnValue:&status];
		[self readChan:chan reg:kBufferOccupancy returnValue:&bufferOccupancy];
		[self readChan:chan reg:kDacs returnValue:&dacValue];
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
	[self read:kBufferOrganization returnValue:&aValue];
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"# Buffer Blocks : %d\n",(long)powf(2.,(float)aValue));
	
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Software Trigger: %@\n",triggerSrc&0x80000000?@"Enabled":@"Disabled");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"External Trigger: %@\n",triggerSrc&0x40000000?@"Enabled":@"Disabled");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Trigger nHit    : %d\n",(triggerSrc&0x00c000000) >> 24);
	
	
	[self read:kAcqControl returnValue:&aValue];
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Triggers Count  : %@\n",aValue&0x4?@"Accepted":@"All");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Run Mode        : %@\n",DT5720RunModeString[aValue&0x3]);
	
	[self read:kCustomSize returnValue:&aValue];
	if(aValue)NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Custom Size     : %d\n",aValue);
	else      NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Custom Size     : Disabled\n");
	
	[self read:kAcqStatus returnValue:&aValue];
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Board Ready     : %@\n",aValue&0x100?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"PLL Locked      : %@\n",aValue&0x80?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"PLL Bypass      : %@\n",aValue&0x40?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Clock source    : %@\n",aValue&0x20?@"External":@"Internal");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Buffer full     : %@\n",aValue&0x10?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Events Ready    : %@\n",aValue&0x08?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Run             : %@\n",aValue&0x04?@"ON":@"OFF");
	
	[self read:kEventStored returnValue:&aValue];
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
    for (i = 0; i < kNumDT5720Channels; i++){
        [self writeThreshold:i];
    }
}

- (void) softwareReset
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kSWReset].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}

- (void) clearAllMemory
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kSWClear].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}

- (void) writeTriggerCount
{
	unsigned long aValue = ((coincidenceLevel&0x7)<<24) | (triggerSourceMask & 0xffffffff);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kTrigSrcEnblMask].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
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

- (void) writeTriggerOut
{
	unsigned long aValue = triggerOutMask;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kFPTrigOutEnblMask].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeFrontPanelControl
{
	unsigned long aValue = frontPanelControlMask;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kFPIOControl].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) readFrontPanelControl
{
	unsigned long aValue = 0;
	[[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + reg[kFPIOControl].addressOffset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
	
	[self setFrontPanelControlMask:aValue];
}


- (void) writeBufferOrganization
{
	unsigned long aValue = eventSize;//(unsigned long)pow(2.,(float)eventSize);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kBufferOrganization].addressOffset
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

- (void) writeNumberBLTEvents:(BOOL)enable
{
    //we must start in a safe mode with 1 event, the numberBLTEvents is passed to SBC
    //unsigned long aValue = (enable) ? numberBLTEventsToReadout : 0;
    unsigned long aValue = (enable) ? 1 : 0;
    
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kBLTEventNum].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeEnableBerr:(BOOL)enable
{
    unsigned long aValue;
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] + reg[kVMEControl].addressOffset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    
	//we set both bit4: BERR and bit5: ALIGN64 for MBLT64 to work correctly with SBC
	if ( enable ) aValue |= 0x30;
	else aValue &= 0xFFCF;
	//if ( enable ) aValue |= 0x10;
	//else aValue &= 0xFFEF;
    
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kVMEControl].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelBufferCheckChanged object:self];
}

#pragma mark ***DataTaker

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


- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    isRunning = NO;
    [waveFormRateGroup stop];
	short i;
    for(i=0;i<8;i++)waveFormCount[i] = 0;
    
    [self writeAcquistionControl:NO];
}


- (NSString*) identifier
{
	return [NSString stringWithFormat:@"DT5720 %lu",[self uniqueIdNumber]];
}

- (void) initBoard:(int)i
{
}

#pragma mark •••Data Taker
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORDT5720Decoder", @"decoder",
								 [NSNumber numberWithLong:dataId],  @"dataId",
								 [NSNumber numberWithBool:YES],     @"variable",
								 [NSNumber numberWithLong:-1],		@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Spectrum"];
    
    return dataDictionary;
}
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORDT5720Model"];    
	//----------------------------------------------------------------------------------------
    [self initBoard];
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}

#pragma mark ***Archival

-(id) adapter
{
    return self;
}
- (unsigned long) baseAddress
{
    return 0;//no meaning ?
}
- (unsigned short) addressModifier
{
    return 0;//no meaning ?
}
- (int) slot
{
    return 0; //no meaning ?
}

-(void) writeLongBlock:(unsigned long *) writeAddress
			 atAddress:(unsigned int) vmeAddress
			numToWrite:(unsigned int) numberLongs
			withAddMod:(unsigned short) anAddressModifier
		 usingAddSpace:(unsigned short) anAddressSpace
{
}
-(void) readLongBlock:(unsigned long *) readAddress
			atAddress:(unsigned int) vmeAddress
			numToRead:(unsigned int) numberLongs
		   withAddMod:(unsigned short) anAddressModifier
		usingAddSpace:(unsigned short) anAddressSpace
{
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setEventSize:             [aDecoder decodeIntForKey:      @"ORDT5720ModelEventSize"]];
    [self setEnabledMask:           [aDecoder decodeIntForKey:      @"ORDT5720ModelEnabledMask"]];
    [self setPostTriggerSetting:    [aDecoder decodeInt32ForKey:    @"ORDT5720ModelPostTriggerSetting"]];
    [self setTriggerSourceMask:     [aDecoder decodeInt32ForKey:    @"ORDT5720ModelTriggerSourceMask"]];
	[self setTriggerOutMask:        [aDecoder decodeInt32ForKey:    @"ORDT5720ModelTriggerOutMask"]];
	[self setFrontPanelControlMask: [aDecoder decodeInt32ForKey:    @"ORDT5720ModelFrontPanelControlMask"]];
    [self setCoincidenceLevel:      [aDecoder decodeIntForKey:      @"ORDT5720ModelCoincidenceLevel"]];
    [self setAcquisitionMode:       [aDecoder decodeIntForKey:      @"acquisitionMode"]];
    [self setCountAllTriggers:      [aDecoder decodeBoolForKey:     @"countAllTriggers"]];
    [self setCustomSize:            [aDecoder decodeInt32ForKey:    @"customSize"]];
	[self setIsCustomSize:          [aDecoder decodeBoolForKey:     @"isCustomSize"]];
	[self setIsFixedSize:           [aDecoder decodeBoolForKey:     @"isFixedSize"]];
    [self setChannelConfigMask:     [aDecoder decodeIntForKey:      @"channelConfigMask"]];
    [self setWaveFormRateGroup:     [aDecoder decodeObjectForKey:   @"waveFormRateGroup"]];
    [self setNumberBLTEventsToReadout:[aDecoder decodeInt32ForKey:  @"numberBLTEventsToReadout"]];
    [self setContinuousMode:        [aDecoder decodeBoolForKey:     @"continuousMode"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:8 groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	int i;
    for (i = 0; i < kNumDT5720Channels; i++){
        [self setDac:i withValue:      [aDecoder decodeInt32ForKey: [NSString stringWithFormat:@"CAENDacChnl%d", i]]];
        [self setThreshold:i withValue:[aDecoder decodeInt32ForKey: [NSString stringWithFormat:@"CAENThresChnl%d", i]]];
        [self setOverUnderThreshold:i withValue:[aDecoder decodeIntForKey: [NSString stringWithFormat:@"CAENOverUnderChnl%d", i]]];
    }
    
    
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)anEncoder
{
    [super encodeWithCoder:anEncoder];
	[anEncoder encodeInt:eventSize                  forKey:@"ORDT5720ModelEventSize"];
	[anEncoder encodeInt:enabledMask                forKey:@"ORDT5720ModelEnabledMask"];
	[anEncoder encodeInt32:postTriggerSetting       forKey:@"ORDT5720ModelPostTriggerSetting"];
	[anEncoder encodeInt32:triggerSourceMask        forKey:@"ORDT5720ModelTriggerSourceMask"];
	[anEncoder encodeInt32:triggerOutMask           forKey:@"ORDT5720ModelTriggerOutMask"];
	[anEncoder encodeInt32:frontPanelControlMask    forKey:@"ORDT5720ModelFrontPanelControlMask"];
	[anEncoder encodeInt:coincidenceLevel           forKey:@"ORDT5720ModelCoincidenceLevel"];
	[anEncoder encodeInt:acquisitionMode            forKey:@"acquisitionMode"];
	[anEncoder encodeBool:countAllTriggers          forKey:@"countAllTriggers"];
	[anEncoder encodeInt32:customSize               forKey:@"customSize"];
	[anEncoder encodeBool:isCustomSize              forKey:@"isCustomSize"];
	[anEncoder encodeBool:isFixedSize               forKey:@"isFixedSize"];
	[anEncoder encodeInt:channelConfigMask          forKey:@"channelConfigMask"];
    [anEncoder encodeObject:waveFormRateGroup       forKey:@"waveFormRateGroup"];
    [anEncoder encodeInt32:numberBLTEventsToReadout forKey:@"numberBLTEventsToReadout"];
    [anEncoder encodeBool:continuousMode            forKey:@"continuousMode"];
	int i;
	for (i = 0; i < kNumDT5720Channels; i++){
        [anEncoder encodeInt32:dac[i]               forKey:[NSString stringWithFormat:@"CAENDacChnl%d", i]];
        [anEncoder encodeInt32:thresholds[i]        forKey:[NSString stringWithFormat:@"CAENThresChnl%d", i]];
        [anEncoder encodeInt:overUnderThreshold[i]  forKey:[NSString stringWithFormat:@"CAENOverUnderChnl%d", i]];
    }
    
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	
    return objDictionary;
}

@end

