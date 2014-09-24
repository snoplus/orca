//
//  ORDT5720Model.m
//  Orca
//
//  Created by Mark Howe on Wed Mar 12,2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina at the Center sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
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
    {@"SW Clear",			false,	false, 	false,	0xEF28,		kWriteOnly},
    //	{@"Flash Enable",		false,	false, 	true,	0xEF2C,		kReadWrite},
    //	{@"Flash Data",			false,	false, 	true,	0xEF30,		kReadWrite},
    //	{@"Config Reload",		false,	false, 	false,	0xEF34,		kWriteOnly},
    {@"ConfROM CheckSum",	false,	false, 	false,	0xF000,		kReadOnly},
    {@"ConfROM CheckSumLen2",false,	false, 	false,	0xF004,		kReadOnly},
    {@"ConfROM CheckSumLen1",false,	false, 	false,	0xF008,		kReadOnly},
    {@"ConfROM CheckSumLen0",false,	false, 	false,	0xF00C,		kReadOnly},
    {@"ConfROM Version",	false,	false, 	false,	0xF030,		kReadOnly},
    {@"ConfROM Board2",     false,	false, 	false,	0xF034,		kReadOnly},
    {@"ConfROM Board1",     false,	false, 	false,	0xF038,		kReadOnly},
    {@"ConfROM Board0",     false,	false, 	false,	0xF03C,		kReadOnly},
    {@"ConfROM SerNum1",    false,	false, 	false,	0xF080,		kReadOnly},
    {@"ConfROM SerNum0",    false,	false, 	false,	0xF084,		kReadOnly},
    {@"ConfROM VCXOType",   false,	false, 	false,	0xF088,		kReadOnly}
};

static DT5720ControllerRegisterNamesStruct ctrlReg[kNumberDT5720ControllerRegisters] = {
    {@"Status register", 0x00, kReadOnly, 16},
    {@"Control register", 0x01, kReadWrite, 16},
    {@"Firmware revision", 0x02, kReadOnly, 16},
    {@"Firmware download", 0x03, kReadWrite, 8},
    {@"Flash Enable", 0x04, kReadWrite, 1},
    {@"IRQ Status", 0x05, kReadOnly, 7},
    {@"Front Panel Input", 0x08, kReadWrite, 7},
    {@"Front Panel Output", 0x08, kReadWrite, 11}
};

static NSString* DT5720RunModeString[4] = {
    @"Register-Controlled",
    @"S-In Controlled",
    @"S-In Gate",
    @"Multi-Board Sync",
};

@interface ORDT5720Model (private)
{
}

- (void) dataWorker:(NSDictionary*)arg;

@end


@implementation ORDT5720Model

@synthesize
vmeRegValue = _vmeRegValue,
vmeRegIndex = _vmeRegIndex,
vmeRegArray = _vmeRegArray,
isNeedToSwap = _isNeedToSwap,
isVMEFIFOMode = _isVMEFIFOMode,
isDataWorkerRunning = _isDataWorkerRunning,
isTimeToStopDataWorker = _isTimeToStopDataWorker;

- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	[self setEnabledMask:0xF];
    [self setEventSize:0xa];
    [self setEndianness];
    [self fillVmeRegArray];
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

- (unsigned long) selectedRegValue
{
    return selectedRegValue;
}

- (void) setSelectedRegValue:(unsigned long) aValue
{
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegValue:[self selectedRegValue]];
    
    // Set the new value in the model.
    selectedRegValue = aValue;
    
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
	
    long theValue			= [self selectedRegValue];
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
    [self initEmbeddedVMEController];
    [self readConfigurationROM];
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

- (void) initEmbeddedVMEController
{

    //get FIFO mode; address increment bit == 1 -> disabled -> fifo mode
    unsigned short value;
    int err;

    err = [self readVmeCtrlRegister:ctrlReg[kCtrlCtrl].addressOffset toValue:&value];
    if (err) {
		NSLog(@"DT5720 error reading VME control register.\n");
        NSLog(@"DT5720 Embedded VME controller was NOT initialized.\n");
        return;
    }

    //NSLog(@"DT5720 VME control register: 0x%04x\n", value);
    self.isVMEFIFOMode = (BOOL)(value & 0x2000);
    
}


- (void) readConfigurationROM
{
    unsigned long value;
    int err;
    
    //test we can write and read
    value = 0xCC00FFEE;
    err = [self writeLongBlock:&value atAddress:reg[kScratch].addressOffset];
    if (err) {
        NSLog(@"DT5720 write scratch register at address: 0x%04x failed\n", reg[kScratch].addressOffset);
        return;
    }
    
    value = 0;
    err = [self readLongBlock:&value atAddress:reg[kScratch].addressOffset];
    if (err) {
        NSLog(@"DT5720 read scratch register at address: 0x%04x failed\n", reg[kScratch].addressOffset);
        return;
    }
    if (value != 0xCC00FFEE) {
        NSLog(@"DT5720 read scratch register returned bad value: 0x%08x, expected: 0xCC00FFEE\n");
        return;
    }

    //get digitizer version
    value = 0;
    err = [self readLongBlock:&value atAddress:reg[kConfigROMVersion].addressOffset];
    if (err) {
        NSLog(@"DT5720 read configuration ROM version at address: 0x%04x failed\n", reg[kConfigROMVersion].addressOffset);
        return;
    }
    switch (value & 0xFF) {
        case 0x30: //DT5720 tested. 4 Ch. 12 bit 250 MS/s Digitizer: 1.25MS/ch, C4, SE
            break;

        case 0x32:
            NSLog(@"Warning: DT5720B/C is not tested\n");
            //DT5720B is 4 Ch. 12 bit 250 MS/s Digitizer: 1.25MS/ch, C20, SE, i.e., different FPGA
            //DT5720C is 2 Ch. 12 bit 250 MS/s Digitizer: 1.25MS/ch, C20, SE
            //unlikely to work without testing
            break;

        case 0x34:
            NSLog(@"Warning: DT5720A is not tested\n");
            //DT5720A is 2 Ch. 12 bit 250 MS/s Digitizer: 1.25MS/ch, C4, SE
            //should work fine
            //todo: reduce number of channels in UI
            break;

        case 0x38:
            NSLog(@"Warning: DT5720D is not tested\n");
            //DT5720D is 4 Ch. 12 bit 250 MS/s Digitizer: 10MS/ch, C20, SE, i.e., different FPGA and RAM
            //unlikely to work
            break;

        case 0x39:
            NSLog(@"Warning: DT5720E is not tested\n");
            //DT5720E is 2 Ch. 12 bit 250 MS/s Digitizer: 10MS/ch, C20, SE; two channel version of D
            break;

        default:
            NSLog(@"Warning: unknown digitizer version read from its configuration ROM.\n");
            break;
    }
    
    //check board ID
    value = 0;
    err = [self readLongBlock:&value atAddress:reg[kConfigROMBoard2].addressOffset];
    if (err) {
        NSLog(@"DT5720 read configuration ROM Board2 at address: 0x%04x failed\n", reg[kConfigROMBoard2].addressOffset);
        return;
    }
    switch (value & 0xFF) {
        case 0x02: //DT5720x
            break;
            
        default:
            NSLog(@"Warning: unknown digitizer Board2 ID read from its configuration ROM.\n");
            break;
    }
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

    
    //launch data pulling thread
    if (!self.dataArray) self.dataArray = [NSMutableArray arrayWithCapacity:10000];
    [self.dataArray removeAllObjects];
    
    self.isTimeToStopDataWorker = NO;
    self.isDataWorkerRunning = NO;
    [NSThread detachNewThreadSelector:@selector(dataWorker:) toTarget:self withObject:nil];
    
    
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{

}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{

    //stop data pulling thread
    
    self.isTimeToStopDataWorker = YES;
    while (self.isDataWorkerRunning) {
        usleep(1000);
    }
    
    //copy all the remaining data from dataArray
    
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

-(void) setEndianness
{
    if (0x0000ABCD == htonl(0x0000ABCD)) {
        self.isNeedToSwap = true;
    }
}

- (void) fillVmeRegArray
{
    
    NSMutableArray* vmeReg = [NSMutableArray arrayWithCapacity:kNumberDT5720ControllerRegisters];
    for (int i=0; i<kNumberDT5720ControllerRegisters; i++) {
        //[vmeReg addObject:[NSValue valueWithBytes:&ctrlReg[i] objCType:@encode(DT5720ControllerRegisterNamesStruct)]];
        [vmeReg addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                           ctrlReg[i].regName, @"name",
                           [NSNumber numberWithLong:ctrlReg[i].addressOffset], @"addressOffset",
                           [NSNumber numberWithBool:(ctrlReg[i].accessType == kReadOnly || ctrlReg[i].accessType == kReadWrite)], @"readEnable",
                           [NSNumber numberWithBool:(ctrlReg[i].accessType == kWriteOnly || ctrlReg[i].accessType == kReadWrite)], @"writeEnable",
                           nil]];
    }
    self.vmeRegArray = vmeReg;
    
    /*
    self.vmeRegArray = @[
                          @{@"name": @"Status register", @"offset": @0x00, @"access": @0, @"bits": @16},
                          @{@"name": @"Control register", @"offset": @0x01, @"access": @1, @"bits": @16},
                          @{@"name": @"Firmware revision", @"offset": @0x02, @"access": @0, @"bits": @16}
                        ];
     */
}

#define swapShort(x) (((uint16_t)(x) <<  8) | ((uint16_t)(x)>>  8))
#define swapLong(x) (((uint32_t)(x) << 24) | (((uint32_t)(x) & 0x0000FF00) <<  8) | (((uint32_t)(x) & 0x00FF0000) >>  8) | ((uint32_t)(x) >> 24))

- (void) readVmeCtrlRegister
{
    unsigned short value;
    int error;
    
    error = [self readVmeCtrlRegister:ctrlReg[self.vmeRegIndex].addressOffset toValue:&value];
    if (!error) {
        self.vmeRegValue = value;
    }
}

- (int) readVmeCtrlRegister:(unsigned short) address toValue:(unsigned short*) value
{
    struct {
        unsigned short address;
    } req;
    
    struct {
        unsigned short value;
        unsigned short status;
    } resp;
    
    req.address = 0x4080U | address;
    
    if (self.isNeedToSwap) {
        req.address = swapShort(req.address);
    }
    
    @try {
		[[self usbInterface] writeBytes:(void*) &req length:sizeof(req)];
	}
    @catch (NSException* e) {
		NSLog(@"DT5720 read controller at address: 0x%04x failed\n", address);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}
    
    memset(&resp, 0, sizeof(resp));
    
    @try {
        [[self usbInterface] readBytes:(void*) &resp length:sizeof(resp)];
	}
    @catch (NSException* e) {
		NSLog(@"DT5720 controller failed to respond at address: 0x%04x\n", address);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}
    
    if (self.isNeedToSwap) {
        resp.value = swapShort(resp.value);
    }
    
    *value = resp.value;
    
    return 0;
}

- (void) writeVmeCtrlRegister
{
    [self writeVmeCtrlRegister:ctrlReg[self.vmeRegIndex].addressOffset value:self.vmeRegValue];
}

- (int) writeVmeCtrlRegister:(unsigned short) address value:(unsigned short) value
{
    struct {
        unsigned short address;
        unsigned short value;
    } req;
    
    req.address = 0x0080U | address;
    req.value = value;
    
    if (self.isNeedToSwap) {
        req.address = swapShort(req.address);
        req.value = swapShort(req.value);
    }
    
    @try {
		[[self usbInterface] writeBytes:(void*) &req length:sizeof(req)];
	}
    @catch (NSException* e) {
		NSLog(@"DT5720 write controller register at address: 0x%04x failed\n", address);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}
    
    return 0;
}

//compatibility with VME interface
-(void) writeLongBlock:(unsigned long *) writeAddress
			 atAddress:(unsigned int) vmeAddress
			numToWrite:(unsigned int) numberLongs
			withAddMod:(unsigned short) anAddressModifier
		 usingAddSpace:(unsigned short) anAddressSpace
{
    [self writeLongBlock:writeAddress atAddress:vmeAddress];
}

//returns 0 if success; -1 if request fails, and number of bytes returned by digitizer in otherwise
-(int) writeLongBlock:(unsigned long*) writeValue atAddress:(unsigned int) vmeAddress
{
    struct {
        unsigned short commandID;
        unsigned long address;
        unsigned long value;
    } req;
    
    struct {
        unsigned short status;
    } resp;

    int num_read = 0;
    
    req.commandID = 0x89A1;
    req.address = vmeAddress;
    req.value = *writeValue;
    
    if (self.isNeedToSwap) {
        req.commandID = swapShort(req.commandID);
        req.address = swapLong(req.address);
        req.value = swapLong(req.value);
    }
    
    //req c struct is aligned in a different way than CAEN wants
    char req_aligned[10];
    *(unsigned short*) req_aligned = req.commandID;
    *(unsigned long*) (req_aligned + 2) = req.address;
    *(unsigned long*) (req_aligned + 6) = req.value;
    
    @try {
		[[self usbInterface] writeBytes:(void*) req_aligned length:10];
	}
    @catch (NSException* e) {
		NSLog(@"DT5720 failed write request at address: 0x%08x failed\n", vmeAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}

    memset(&resp, 0, sizeof(resp));
    
    @try {
        num_read = [[self usbInterface] readBytes:(void*) &resp length:sizeof(resp)];
	}
    @catch (NSException* e) {
		NSLog(@"DT5720 failed write respond at address: 0x%08x\n", vmeAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
    
    if (self.isNeedToSwap) {
        resp.status = swapShort(resp.status);
    }
    
    if (num_read != 2 || resp.status & 0x20) {
		NSLog(@"DT5720 failed write at address: 0x%08x\n", vmeAddress);
		NSLog(@"DT5720 returned with bus error\n");
        return num_read;
    }
    
    return 0;
}

//compatibility with VME interface
-(void) readLongBlock:(unsigned long *) readAddress
			atAddress:(unsigned int) vmeAddress
			numToRead:(unsigned int) numberLongs
		   withAddMod:(unsigned short) anAddressModifier
		usingAddSpace:(unsigned short) anAddressSpace
{
    [self readLongBlock:readAddress atAddress:vmeAddress];
}

//returns 0 if success, -1 if request fails, and number of bytes returned by digitizer otherwise
-(int) readLongBlock:(unsigned long*) readValue atAddress:(unsigned int) vmeAddress
{
    struct {
        unsigned short commandID;
        unsigned int address;
    } req;
    
    struct {
        unsigned int value;
        unsigned short status;
    } resp;

    int num_read = 0;
    
    req.commandID = 0xC9A1;
    req.address = vmeAddress;

    if (self.isNeedToSwap) {
        req.commandID = swapShort(req.commandID);
        req.address = swapLong(req.address);
    }

    //req c struct is aligned in a different way than CAEN wants
    char req_aligned[6];
    *(unsigned short*) req_aligned = req.commandID;
    *(unsigned long*) (req_aligned + 2) = req.address;
    
    @try {
		[[self usbInterface] writeBytes:(void*) req_aligned length:6];
	}
    @catch (NSException* e) {
		NSLog(@"DT5720 failed read request at address: 0x%08x failed\n", vmeAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}
    
    memset(&resp, 0, sizeof(resp));

    @try {
        num_read = [[self usbInterface] readBytes:(void*) &resp length:sizeof(resp)];
	}
    @catch (NSException* e) {
		NSLog(@"DT5720 failed read respond at address: 0x%08x\n", vmeAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}
    
    if (self.isNeedToSwap) {
        resp.value = swapLong(resp.value);
        resp.status = swapShort(resp.status);
    }
    
    if (num_read != 6 || (resp.status & 0x20)) {
		NSLog(@"DT5720 failed read at address: 0x%08x\n", vmeAddress);
		NSLog(@"DT5720 returned with bus error\n");
        return num_read;
    }
    
    *readValue = resp.value;
    return 0;
}

//returns 0 if success; -1 if request fails, and number of bytes returned by digitizer otherwise
//this isn't a user friendly function for performance reasons
//numBytes must be multiple of 8
//readValue must be atleast (numBytes + 2) long
- (int) readMBLT:(unsigned long*) readValue
       atAddress:(unsigned int) vmeAddress
  numBytesToRead:(unsigned long) numBytes
{
    if (numBytes == 0) return 0;
    
    //64 bit cycles -> numBytes must be 8 aligned
    const unsigned long aligned_num_bytes = (numBytes + 7) & ~7UL;
    
    //limited to 16 MB on linux why?
    //chunk size in bytes, must be multiples of 8, max is 0xffff * 8
    const unsigned long chunk_size = 0x8000 * 8; //bytes

    int num_read = 0;
    int i;
    
    unsigned long num_transfers = (aligned_num_bytes - 1) / chunk_size + 1;

    //MBLT request is an array of readLongBlock like requests
    char req[num_transfers * 8];
    struct {
        unsigned short commandID;
        unsigned short num_cycles;
        unsigned long address;
    } mblt_req;
    
    mblt_req.commandID = 0xC8BF;
    mblt_req.num_cycles = chunk_size >> 4;
    mblt_req.address = vmeAddress; //this works in fifo mode, regardless what the vme controller says
    
    if (self.isNeedToSwap) {
        mblt_req.commandID = swapShort(mblt_req.commandID);
        mblt_req.num_cycles = swapShort(mblt_req.num_cycles);
        mblt_req.address = swapLong(mblt_req.address);
    }
    
    //req c struct is aligned in a different way than CAEN wants
    char mblt_req_aligned[8];
    *(unsigned short*) mblt_req_aligned = mblt_req.commandID;
    *(unsigned short*) (mblt_req_aligned + 2) = mblt_req.num_cycles;
    *(unsigned long*) (mblt_req_aligned + 4) = mblt_req.address;

    for (i = 0; i < num_transfers - 1; ++i) {
        memcpy(req + i*8, mblt_req_aligned, 8);
    }
    
    //now the final readLongBlock request
    mblt_req.commandID = 0xC8BC;
    mblt_req.num_cycles = (aligned_num_bytes - (num_transfers - 1) * chunk_size) >> 4;
    mblt_req.address = vmeAddress;

    if (self.isNeedToSwap) {
        mblt_req.commandID = swapShort(mblt_req.commandID);
        mblt_req.num_cycles = swapShort(mblt_req.num_cycles);
        mblt_req.address = swapLong(mblt_req.address);
    }

    size_t req_offset = (num_transfers - 1) * 8;
    
    *(unsigned short*) (req + req_offset) = mblt_req.commandID;
    *(unsigned short*) (req + req_offset + 2) = mblt_req.num_cycles;
    *(unsigned long*) (req + req_offset + 4) = mblt_req.address;

    @try {
		[[self usbInterface] writeBytes:(void*) req length:sizeof(req)];
	}
    @catch (NSException* e) {
		NSLog(@"DT5720 readMBLT request at address: 0x%08x failed\n", vmeAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}
    
    //char read_buffer[aligned_num_bytes + 2];
    //memset(read_buffer, 0, sizeof(read_buffer));
    memset(readValue, 0, aligned_num_bytes + 2);
    
    @try {
        num_read = [[self usbInterface] readBytes:(void*) readValue length:aligned_num_bytes + 2];
	}
    @catch (NSException* e) {
		NSLog(@"DT5720 failed readMBLT respond at address: 0x%08x\n", vmeAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}

    unsigned short* resp_status = (unsigned short*) readValue + aligned_num_bytes;
    if (self.isNeedToSwap) {
        *resp_status = swapShort(*resp_status);
    }

    if (num_read != aligned_num_bytes + 2 || (*resp_status & 0x20)) {
		NSLog(@"DT5720 failed readMBLT at address: 0x%08x\n", vmeAddress);
		NSLog(@"DT5720 returned with bus error\n");
        return num_read;
    }
    *resp_status = 0x0;
    
/*
    dw = 64 -> dsize = 3
    DW = 0x08 it's in bytes
    am = VME_MBLT_AM = 0x08
    MAX_BLT_SIZE = 60 * 1024 //chunk used for everything
    
    opcode = 0xC000 | (AM << 8) | (2 << 6) | (dsize << 4);
    opcode = 0xC000 | (0x08 << 8) | (0x02 << 6) | (0x03 << 4);
             0xC000    0x0800        0x0080        0x0030
             0xC8B0
    
    //    all transfers but the last one | FPBLT = 0xF
    //    last transfer | FBLT = 0xC
*/
    
    return 0;
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

    [self setEndianness];
    [self fillVmeRegArray];
    
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

@implementation ORDT5720Model (private)


//data is NSArray of NSData ever growing
//we need a lock token for @synchronized to copy data from the NSArray


- (void) dataWorker:(NSDictionary*)arg
{
    NSAutoreleasePool* workerPool = [[NSAutoreleasePool alloc] init];
    self.isDataWorkerRunning = YES;

    char data_buffer[11*1024*1024]; //digitizer RAM
    BOOL isDataAvailable;
    
    while (!self.isTimeToStopDataWorker) {

        //is data available?
        
        //if no data available sleep 10 msec and then continue;
        
        //now we have data in digitizer...
        
        //fill from actually read event size
        unsigned long event_size = 1024; //in bytes
        
        
        //the data taker object thing goes here
        
        //pull all the events at once into a static buffer 11 MB large
        
        //break them into multiple events? here? decoder? think about max ORCA data packet size which is 0x3ffff words
        
        //get the bytes
        
        
        //turn them into nsdata with two empty words prepended
        memset(data_buffer, 0, 8); //make sure orca packet header placeholders are empty
        NSData* event_data = [NSData dataWithBytes:data_buffer length:event_size + 8];
        
        //add them into dataArray
        @synchronized(_dataArray) {
            [self.dataArray addObject:[[event_data autorelease] retain]]; //passing ownership to the main thread
        }
    }
    
    self.isDataWorkerRunning = NO;
    [workerPool release];
}


@end

