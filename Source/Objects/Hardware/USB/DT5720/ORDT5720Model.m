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

//connector names
NSString* ORDT5720USBInConnection                     = @"ORDT5720USBInConnection";
NSString* ORDT5720USBNextConnection                   = @"ORDT5720USBNextConnection";

//USB Notifications
NSString* ORDT5720ModelUSBInterfaceChanged            = @"ORDT5720ModelUSBInterfaceChanged";
NSString* ORDT5720ModelLock                           = @"ORDT5720ModelLock";
NSString* ORDT5720ModelSerialNumberChanged            = @"ORDT5720ModelSerialNumberChanged";

//Notifications
NSString* ORDT5720ModelLogicTypeChanged             = @"ORDT5720ModelLogicTypeChanged";
NSString* ORDT5720ZsThresholdChanged                = @"ORDT5720ZsThresholdChanged";
NSString* ORDT5720NlbkChanged                       = @"ORDT5720NlbkChanged";
NSString* ORDT5720NlfwdChanged                      = @"ORDT5720NlfwdChanged";
NSString* ORDT5720ThresholdChanged                  = @"ORDT5720ThresholdChanged";
NSString* ORDT5720OverUnderThresholdChanged         = @"ORDT5720OverUnderThresholdChanged";
NSString* ORDT5720ChnlDacChanged                    = @"ORDT5720ChnlDacChanged";
NSString* ORDT5720ModelZsAlgorithmChanged           = @"ORDT5720ModelZsAlgorithmChanged";
NSString* ORDT5720ModelTrigOnUnderThresholdChanged  = @"ORDT5720ModelTrigOnUnderThresholdChanged";
NSString* ORDT5720ModelTestPatternEnabledChanged    = @"ORDT5720ModelTestPatternEnabledChanged";
NSString* ORDT5720ModelTrigOverlapEnabledChanged    = @"ORDT5720ModelTrigOverlapEnabledChanged";
NSString* ORDT5720ModelEventSizeChanged             = @"ORDT5720ModelEventSizeChanged";
NSString* ORDT5720ModelIsCustomSizeChanged          = @"ORDT5720ModelIsCustomSizeChanged";
NSString* ORDT5720ModelCustomSizeChanged            = @"ORDT5720ModelCustomSizeChanged";
NSString* ORDT5720ModelClockSourceChanged           = @"ORDT5720ModelClockSourceChanged";
NSString* ORDT5720ModelCountAllTriggersChanged      = @"ORDT5720ModelCountAllTriggersChanged";
NSString* ORDT5720ModelGpiRunModeChanged            = @"ORDT5720ModelGpiRunModeChanged";
NSString* ORDT5720ModelTriggerSourceMaskChanged     = @"ORDT5720ModelTriggerSourceMaskChanged";
NSString* ORDT5720ModelExternalTrigEnabledChanged   = @"ORDT5720ModelExternalTrigEnabledChanged";
NSString* ORDT5720ModelSoftwareTrigEnabledChanged   = @"ORDT5720ModelSoftwareTrigEnabledChanged";
NSString* ORDT5720ModelCoincidenceLevelChanged      = @"ORDT5720ModelCoincidenceLevelChanged";
NSString* ORDT5720ModelEnabledMaskChanged           = @"ORDT5720ModelEnabledMaskChanged";
NSString* ORDT5720ModelFpSoftwareTrigEnabledChanged = @"ORDT5720ModelFpSoftwareTrigEnabledChanged";
NSString* ORDT5720ModelFpExternalTrigEnabledChanged = @"ORDT5720ModelFpExternalTrigEnabledChanged";
NSString* ORDT5720ModelTriggerOutMaskChanged        = @"ORDT5720ModelTriggerOutMaskChanged";
NSString* ORDT5720ModelPostTriggerSettingChanged    = @"ORDT5720ModelPostTriggerSettingChanged";
NSString* ORDT5720ModelGpoEnabledChanged            = @"ORDT5720ModelGpoEnabledChanged";
NSString* ORDT5720ModelTtlEnabledChanged            = @"ORDT5720ModelTtlEnabledChanged";

NSString* ORDT5720ModelNumberBLTEventsToReadoutChanged    = @"ORDT5720ModelNumberBLTEventsToReadoutChanged";
NSString* ORDT5720Chnl                                    = @"ORDT5720Chnl";
NSString* ORDT5720SelectedRegIndexChanged                 = @"ORDT5720SelectedRegIndexChanged";
NSString* ORDT5720SelectedChannelChanged                  = @"ORDT5720SelectedChannelChanged";
NSString* ORDT5720WriteValueChanged                       = @"ORDT5720WriteValueChanged";

NSString* ORDT5720BasicLock                               = @"ORDT5720BasicLock";
NSString* ORDT5720LowLevelLock                            = @"ORDT5720LowLevelLock";
NSString* ORDT5720RateGroupChanged                        = @"ORDT5720RateGroupChanged";
NSString* ORDT5720ModelBufferCheckChanged                 = @"ORDT5720ModelBufferCheckChanged";



static DT5720RegisterNamesStruct reg[kNumberDT5720Registers] = {
//  {regName            addressOffset, accessType, hwReset, softwareReset, clr},
    {@"Output Buffer",          0x0000, kReadOnly,  true,	true, 	true},
    {@"ZS_Thres",               0x1024,	kReadWrite,	true,	true, 	false},
    {@"ZS_NsAmp",               0x1028,	kReadWrite, true,	true, 	false},
    {@"Thresholds",             0x1080,	kReadWrite, true,	true, 	false},
    {@"Time O/U Threshold",     0x1084,	kReadWrite, true,	true, 	false},
    {@"Status",                 0x1088,	kReadOnly,  true,	true, 	false},
    {@"Firmware Version",       0x108C,	kReadOnly,  false,	false, 	false},
    {@"Buffer Occupancy",       0x1094,	kReadOnly,  true,	true, 	true},
    {@"Dacs",                   0x1098,	kReadWrite, true,	true, 	false},
    {@"Adc Config",             0x109C,	kReadWrite, true,	true, 	false},
    {@"Chan Config",            0x8000,	kReadWrite, true,	true, 	false},
    {@"Chan Config Bit Set",    0x8004,	kWriteOnly, true,	true, 	false},
    {@"Chan Config Bit Clr",    0x8008, kWriteOnly, true,	true, 	false},
    {@"Buffer Organization",    0x800C,	kReadWrite, true,	true, 	false},
    {@"Custom Size",            0x8020,	kReadWrite, true,	true, 	false},
    {@"Acq Control",            0x8100,	kReadWrite, true,	true, 	false},
    {@"Acq Status",             0x8104,	kReadOnly,  false,	false, 	false},
    {@"SW Trigger",             0x8108,	kWriteOnly, false,	false, 	false},
    {@"Trig Src Enbl Mask",     0x810C,	kReadWrite, true,	true, 	false},
    {@"FP Trig Out Enbl Mask",  0x8110, kReadWrite, true,  true, 	false},
    {@"Post Trig Setting",      0x8114,	kReadWrite, true,	true, 	false},
    {@"FP I/O Control",         0x811C,	kReadWrite, true,	true, 	false},
    {@"Chan Enable Mask",       0x8120,	kReadWrite, true,	true, 	false},
    {@"ROC FPGA Version",       0x8124,	kReadOnly,  false,	false, 	false},
    {@"Event Stored",           0x812C,	kReadOnly,  true,	true, 	true},
    {@"Board Info",             0x8140,	kReadOnly,  false,	false, 	false},
    {@"Event Size",             0x814C,	kReadOnly,  true,	true, 	true},
    {@"VME Control",            0xEF00,	kReadWrite, true,	false, 	false},
    {@"VME Status",             0xEF04,	kReadOnly,  false,	false, 	false},
    {@"Interrupt Status ID",    0xEF14,	kReadWrite, true,	false, 	false},
    {@"Interrupt Event Num",    0xEF18,	kReadWrite, true,	true, 	false},
    {@"BLT Event Num",          0xEF1C,	kReadWrite, true,	true, 	false},
    {@"Scratch",                0xEF20,	kReadWrite, true,	true, 	false},
    {@"SW Reset",               0xEF24,	kWriteOnly, false,	false, 	false},
    {@"SW Clear",               0xEF28,	kWriteOnly, false,	false, 	false},
    {@"Config ROM",             0xEF28,	kReadOnly,  false,	false, 	false},
    {@"Config ROM Board2",      0xEF34,	kReadOnly,  false,	false, 	false}
};

static DT5720ControllerRegisterNamesStruct ctrlReg[kNumberDT5720ControllerRegisters] = {
//  {regName, addressOffset, accessType, numBits},
    {@"Status register",    0x00, kReadOnly, 16},
    {@"Control register",   0x01, kReadWrite,16},
    {@"Firmware revision",  0x02, kReadOnly, 16},
    {@"Firmware download",  0x03, kReadWrite, 8},
    {@"Flash Enable",       0x04, kReadWrite, 1},
    {@"IRQ Status",         0x05, kReadOnly,  7},
    {@"Front Panel Input",  0x08, kReadWrite, 7},
    {@"Front Panel Output", 0x08, kReadWrite,11}
};

static NSString* DT5720RunModeString[4] = {
    @"Register Controlled",
    @"GPI Controlled",
};

@interface ORDT5720Model (private)
- (void) dataWorker:(NSDictionary*)arg;

@end


@implementation ORDT5720Model

@synthesize vmeRegValue,vmeRegIndex,vmeRegArray,isNeedToSwap,isVMEFIFOMode,isDataWorkerRunning,isTimeToStopDataWorker,dataArray;

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

#pragma mark ***USB
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

#pragma mark Accessors
//------------------------------
//Reg Channel n ZS_Thres (0x1n24)
- (int) logicType:(unsigned short) i;
{
    return logicType[i];
}

- (void) setLogicType:(unsigned short) i withValue:(int)aLogicType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLogicType:i withValue:[self logicType:i]];
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
    logicType[i] = aLogicType;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelLogicTypeChanged object:self userInfo:userInfo];
}

- (unsigned short) zsThreshold:(unsigned short) i
{
    return zsThresholds[i];
}

- (void) setZsThreshold:(unsigned short) i withValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:i withValue:[self threshold:i]];
    
    zsThresholds[i] = aValue;
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ZsThresholdChanged
                                                        object:self
                                                      userInfo:userInfo];
}

//------------------------------
//Reg Channel n ZS_NSAmp (0x1n28)
- (unsigned short)	nLbk:(unsigned short) i
{
    return nLbk[i];
}

- (void) setNlbk:(unsigned short) i withValue:(unsigned short) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNlbk:i withValue:nLbk[i]];
    
    nLbk[i] = aValue;
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720NlbkChanged
                                                        object:self
                                                      userInfo:userInfo];
}

- (unsigned short)	nLfwd:(unsigned short) i
{
    return nLfwd[i];
    
}

- (void) setNlfwd:(unsigned short) i withValue:(unsigned short) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNlfwd:i withValue:nLfwd[i]];
    nLfwd[i] = aValue;
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720NlfwdChanged
                                                        object:self
                                                      userInfo:userInfo];
}
//------------------------------
//Reg Channel n Threshold (0x1n80)
- (unsigned short) threshold:(unsigned short) i
{
    return thresholds[i];
}

- (void) setThreshold:(unsigned short) i withValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:i withValue:[self threshold:i]];
    
    thresholds[i] = aValue;
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ThresholdChanged
                                                        object:self
                                                      userInfo:userInfo];
}
//------------------------------
//Reg Channel n Over/Under Threshold (0x1n80)
- (unsigned short) overUnderThreshold:(unsigned short) i
{
    return overUnderThreshold[i];
}

- (void) setOverUnderThreshold:(unsigned short) i withValue:(unsigned short) aValue
{
    
    [[[self undoManager] prepareWithInvocationTarget:self] setOverUnderThreshold:i withValue:overUnderThreshold[i]];
    overUnderThreshold[i] = aValue;
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720OverUnderThresholdChanged
                                                        object:self
                                                      userInfo:userInfo];
}
//------------------------------
//Reg Channel n DAC (0x1n98)
- (unsigned short) dac:(unsigned short) i
{
    return dac[i];
}

- (void) setDac:(unsigned short) i withValue:(unsigned short) aValue
{
    
    [[[self undoManager] prepareWithInvocationTarget:self] setDac:i withValue:dac[i]];
    
    dac[i] = aValue;
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ChnlDacChanged
                                                        object:self
                                                      userInfo:userInfo];
}

//------------------------------
//Reg Channel Configuration (0x8000)
- (int) zsAlgorithm
{
    return zsAlgorithm;
}

- (void) setZsAlgorithm:(int)aZsAlgorithm
{
    [[[self undoManager] prepareWithInvocationTarget:self] setZsAlgorithm:zsAlgorithm];
    zsAlgorithm = aZsAlgorithm;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelZsAlgorithmChanged object:self];
}

- (BOOL) trigOnUnderThreshold
{
    return trigOnUnderThreshold;
}

- (void) setTrigOnUnderThreshold:(BOOL)aTrigOnUnderThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigOnUnderThreshold:trigOnUnderThreshold];
    trigOnUnderThreshold = aTrigOnUnderThreshold;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelTrigOnUnderThresholdChanged object:self];
}

- (BOOL) testPatternEnabled
{
    return testPatternEnabled;
}

- (void) setTestPatternEnabled:(BOOL)aTestPatternEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestPatternEnabled:testPatternEnabled];
    testPatternEnabled = aTestPatternEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelTestPatternEnabledChanged object:self];
}

- (BOOL) trigOverlapEnabled
{
    return trigOverlapEnabled;
}

- (void) setTrigOverlapEnabled:(BOOL)aTrigOverlapEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigOverlapEnabled:trigOverlapEnabled];
    trigOverlapEnabled = aTrigOverlapEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelTrigOverlapEnabledChanged object:self];
}

//------------------------------
//Reg Buffer Organization (0x800C)
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
//------------------------------
//Reg Custom Size (0x8020)
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
//------------------------------
//Reg Acquistion Control (0x8100)
- (BOOL) clockSource
{
    return clockSource;
}

- (void) setClockSource:(BOOL)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = aClockSource;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelClockSourceChanged object:self];
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

- (BOOL) gpiRunMode
{
    return gpiRunMode;
}

- (void) setGpiRunMode:(BOOL)aGpiRunMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGpiRunMode:gpiRunMode];
    gpiRunMode = aGpiRunMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelGpiRunModeChanged object:self];
}
//------------------------------
//Reg Trigger Source Enable Mask (0x810C)
- (BOOL) softwareTrigEnabled
{
    return softwareTrigEnabled;
}

- (void) setSoftwareTrigEnabled:(BOOL)aSoftwareTrigEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSoftwareTrigEnabled:softwareTrigEnabled];
    softwareTrigEnabled = aSoftwareTrigEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelSoftwareTrigEnabledChanged object:self];
}

- (BOOL) externalTrigEnabled
{
    return externalTrigEnabled;
}

- (void) setExternalTrigEnabled:(BOOL)aExternalTrigEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setExternalTrigEnabled:externalTrigEnabled];
    externalTrigEnabled = aExternalTrigEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelExternalTrigEnabledChanged object:self];
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

//------------------------------
//Reg Front Panel Trigger Out Enable Mask (0x8110)
- (BOOL) fpSoftwareTrigEnabled
{
    return fpSoftwareTrigEnabled;
}

- (void) setFpSoftwareTrigEnabled:(BOOL)aFpSoftwareTrigEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFpSoftwareTrigEnabled:fpSoftwareTrigEnabled];
    fpSoftwareTrigEnabled = aFpSoftwareTrigEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelFpSoftwareTrigEnabledChanged object:self];
}

- (BOOL) fpExternalTrigEnabled
{
    return fpExternalTrigEnabled;
}

- (void) setFpExternalTrigEnabled:(BOOL)aFpExternalTrigEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFpExternalTrigEnabled:fpExternalTrigEnabled];
    fpExternalTrigEnabled = aFpExternalTrigEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelFpExternalTrigEnabledChanged object:self];
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

//------------------------------
//Reg Post Trigger Setting (0x8114)
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
//------------------------------
//Reg Front Panel I/O Setting (0x811C)
- (BOOL) gpoEnabled
{
    return gpoEnabled;
}

- (void) setGpoEnabled:(BOOL)aGpoEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGpoEnabled:gpoEnabled];
    gpoEnabled = aGpoEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelGpoEnabledChanged object:self];
}

- (int) ttlEnabled
{
    return ttlEnabled;
}

- (void) setTtlEnabled:(int)aTtlEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTtlEnabled:ttlEnabled];
    ttlEnabled = aTtlEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelTtlEnabledChanged object:self];
}
//------------------------------
//Reg Channel Enable Mask (0x8120)
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

//------------------------------
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
               atAddress:[self getAddressOffset:pReg] + chan*0x100];
    
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
		[self writeLongBlock:&theValue
							 atAddress:[self getAddressOffset:pReg] + chan*0x100];
	}
	@catch(NSException* localException) {
	}
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
    [self readLongBlock:pValue
                        atAddress:[self getAddressOffset:pReg]];
    
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
		[self writeLongBlock:&pValue
                   atAddress:[self getAddressOffset:pReg]];
		
	}
	@catch(NSException* localException) {
	}
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
	for(chan=0;chan<kNumDT5720Channels;chan++){
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
	[self writeThresholds];
	[self writeChannelConfiguration];
	[self writeCustomSize];
	[self writeFrontPanelIOControl];
	[self writeChannelEnabledMask];
	[self writeBufferOrganization];
	[self writeNumOverUnderThresholds];
	[self writeDacs];
	[self writePostTriggerSetting];
    
    NSLog(@"%@ initialized\n",[self fullID]);
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

#pragma mark ***HW Reg Access
- (void) writeZSThresholds
{
    short	i;
    for (i=0;i<kNumDT5720Channels;i++){
        [self writeZSThreshold:i];
    }
}

- (void) writeZSThreshold:(unsigned short) i
{
    unsigned long aValue = 0;
    aValue |= logicType[i]<<31;
    aValue |= [self zsThreshold:i] & 0xFFF;
    
    [self writeLongBlock:&aValue
               atAddress:reg[kZS_Thres].addressOffset + (i * 0x100)];
}

- (void) writeZSAmplReg
{
    short	i;
    for (i=0;i<kNumDT5720Channels;i++){
        [self writeZSAmplReg:i];
    }
}

- (void) writeZSAmplReg:(unsigned short) i
{
    
    if(zsAlgorithm == kFullSuppressionBasedOnAmplitude){
        unsigned long 	aValue = [self overUnderThreshold:i] & 0xFFFFF;
    
        [self writeLongBlock:&aValue
                   atAddress:reg[kZS_NsAmp].addressOffset + (i * 0x100)];
    }
    else if(zsAlgorithm == kZeroLengthEncoding){
        unsigned long aValue = ([self nLbk:i] & 0xFFFF)<<16 |
                               ([self nLfwd:i]& 0xFFFF);
        [self writeLongBlock:&aValue
                   atAddress:reg[kZS_NsAmp].addressOffset + (i * 0x100)];
    }

}

- (void) writeThresholds
{
    short	i;
    for (i = 0; i < kNumDT5720Channels; i++){
        [self writeThreshold:i];
    }
}

- (void) writeThreshold:(unsigned short) i
{
    unsigned long 	aValue = [self threshold:i];
    [self writeLongBlock:&aValue
               atAddress:reg[kThresholds].addressOffset + (i * 0x100)];
}

- (void) writeNumOverUnderThresholds
{
    short	i;
    for (i = 0; i < kNumDT5720Channels; i++){
        [self writeNumOverUnderThreshold:i];
    }
}
- (void) writeNumOverUnderThreshold:(unsigned short) i
{
    unsigned long 	aValue = [self overUnderThreshold:i];
    [self writeLongBlock:&aValue
               atAddress:reg[kNumOUThreshold].addressOffset + (i * 0x100)];
}

- (void) writeDacs
{
    short	i;
    for (i = 0; i < kNumDT5720Channels; i++){
        [self writeDac:i];
    }
}

- (void) writeDac:(unsigned short) i
{
    unsigned long 	aValue = [self dac:i];
    [self writeLongBlock:&aValue
               atAddress:reg[kDacs].addressOffset + (i * 0x100)];
}

- (void) writeChannelConfiguration
{
    unsigned long mask = 0;
    mask |= (zsAlgorithm & 0x3)           << 16;
    mask |= (trigOnUnderThreshold & 0x1)  <<  6;
    mask |= (testPatternEnabled & 0x1)    <<  3;
    mask |= (trigOverlapEnabled & 0x1)    <<  1;
    //note that pack2.5 is permently disabled.
    [self writeLongBlock:&mask
               atAddress:reg[kChanConfig].addressOffset];
}

- (void) writeBufferOrganization
{
    unsigned long aValue = eventSize; //(unsigned long)pow(2.,(float)eventSize);
    [self writeLongBlock:&aValue
               atAddress:reg[kBufferOrganization].addressOffset];
}

- (void) writeCustomSize
{
    unsigned long aValue = [self isCustomSize]?[self customSize]:0UL;
    [self writeLongBlock:&aValue
               atAddress:reg[kCustomSize].addressOffset];
}

- (void) writeAcquistionControl:(BOOL)start
{
    unsigned long aValue = 0;
    aValue |= (clockSource & 0x1)       << 6;
    aValue |= (countAllTriggers & 0x1)  << 3;
    aValue |= (start & 0x1)             << 2;
    aValue |= (gpiRunMode & 0x1)        << 0;
    
    [self writeLongBlock:&aValue
               atAddress:reg[kAcqControl].addressOffset];
    
}

- (void) trigger
{
    unsigned long aValue = 0;
    [self writeLongBlock:&aValue
               atAddress:reg[kSWTrigger].addressOffset];
   
}

- (void) writeTriggerSourceEnableMask
{
    unsigned long aValue = 0;
    aValue |= (softwareTrigEnabled & 0x1) << 31;
    aValue |= (externalTrigEnabled & 0x1) << 30;
    aValue |= (coincidenceLevel    & 0x7) << 24;
    aValue |= (triggerSourceMask   & 0xf) <<  0;
    
    [self writeLongBlock:&aValue
               atAddress:reg[kTrigSrcEnblMask].addressOffset];
}

- (void) writeFrontPanelTriggerOutEnableMask
{
    unsigned long aValue = 0;
    aValue = (fpSoftwareTrigEnabled & 0x1) << 31;
    aValue = (fpExternalTrigEnabled & 0x1) << 30;
    aValue = (triggerOutMask        & 0xf) <<  0;
    
    [self writeLongBlock:&aValue
               atAddress:reg[kFPTrigOutEnblMask].addressOffset];
}

- (void) writePostTriggerSetting
{
    [self writeLongBlock:&postTriggerSetting
               atAddress:reg[kPostTrigSetting].addressOffset];
    
}

- (void) writeFrontPanelIOControl
{
    unsigned long aValue = 0;
    aValue = (gpoEnabled & 0x1) << 1;
    aValue = (ttlEnabled & 0x1) << 0;
    
    [self writeLongBlock:&aValue
               atAddress:reg[kFPIOControl].addressOffset];
}

- (void) writeChannelEnabledMask
{
    unsigned long aValue = enabledMask;
    [self writeLongBlock:&aValue
               atAddress:reg[kChanEnableMask].addressOffset];
    
}

- (void) softwareReset
{
    unsigned long aValue = 0;
    [self writeLongBlock:&aValue
               atAddress:reg[kSWReset].addressOffset];
    
}

- (void) clearAllMemory
{
    unsigned long aValue = 0;
    [self writeLongBlock:&aValue
               atAddress:reg[kSWClear].addressOffset];
    
}

- (void) checkBufferAlarm
{
    if((bufferState == 1) && isRunning){
        bufferEmptyCount = 0;
        if(!bufferFullAlarm){
            NSString* alarmName = [NSString stringWithFormat:@"Buffer FULL V1720 (%@)",[self fullID]];
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


#pragma mark ***Helpers
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
    NSLog(@"Fill in the takeData method!!!\n");
    
    return;
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

-(void) setEndianness
{
    if (0x0000ABCD == htonl(0x0000ABCD)) {
        self.isNeedToSwap = true;
    }
}

- (void) fillVmeRegArray
{
    
    NSMutableArray* vmeReg = [NSMutableArray arrayWithCapacity:kNumberDT5720ControllerRegisters];
    int i;
    for (i=0; i<kNumberDT5720ControllerRegisters; i++) {
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


//returns 0 if success; -1 if request fails, and number of bytes returned by digitizer in otherwise
- (int) writeLongBlock:(unsigned long*) writeValue atAddress:(unsigned int) anAddress
{
    struct {
        unsigned short commandID;
        unsigned long  address;
        unsigned long  value;
    } req;
    
    struct {
        unsigned short status;
    } resp;

    int num_read = 0;
    
    req.commandID   = 0x89A1;
    req.address     = anAddress;
    req.value       = *writeValue;
    
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
		NSLog(@"DT5720 failed write request at address: 0x%08x failed\n", req.address);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}

    memset(&resp, 0, sizeof(resp));
    
    @try {
        num_read = [[self usbInterface] readBytes:(void*) &resp length:sizeof(resp)];
	}
    @catch (NSException* e) {
		NSLog(@"DT5720 failed write respond at address: 0x%08x\n", req.address);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
    
    if (self.isNeedToSwap) {
        resp.status = swapShort(resp.status);
    }
    
    if (num_read != 2 || resp.status & 0x20) {
		NSLog(@"DT5720 failed write at address: 0x%08x\n", req.address);
		NSLog(@"DT5720 returned with bus error\n");
        return num_read;
    }
    
    return 0;
}


//returns 0 if success, -1 if request fails, and number of bytes returned by digitizer otherwise
-(int) readLongBlock:(unsigned long*) readValue atAddress:(unsigned int) anAddress
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
    req.address = anAddress;

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
		NSLog(@"DT5720 failed read request at address: 0x%08x failed\n", req.address);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}
    
    memset(&resp, 0, sizeof(resp));

    @try {
        num_read = [[self usbInterface] readBytes:(void*) &resp length:sizeof(resp)];
	}
    @catch (NSException* e) {
		NSLog(@"DT5720 failed read respond at address: 0x%08x\n", req.address);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}
    
    if (self.isNeedToSwap) {
        resp.value = swapLong(resp.value);
        resp.status = swapShort(resp.status);
    }
    
    if (num_read != 6 || (resp.status & 0x20)) {
		NSLog(@"DT5720 failed read at address: 0x%08x\n", req.address);
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
    [self setTtlEnabled:            [aDecoder decodeIntForKey:      @"ttlEnabled"]];
    [self setGpoEnabled:            [aDecoder decodeBoolForKey:     @"gpoEnabled"]];
    [self setFpSoftwareTrigEnabled: [aDecoder decodeBoolForKey:     @"fpSoftwareTrigEnabled"]];
    [self setFpExternalTrigEnabled: [aDecoder decodeBoolForKey:     @"fpExternalTrigEnabled"]];
    [self setExternalTrigEnabled:   [aDecoder decodeBoolForKey:     @"externalTrigEnabled"]];
    [self setSoftwareTrigEnabled:   [aDecoder decodeBoolForKey:     @"softwareTrigEnabled"]];
    [self setGpiRunMode:            [aDecoder decodeBoolForKey:     @"gpiRunMode"]];
    [self setClockSource:           [aDecoder decodeBoolForKey:     @"clockSource"]];
    [self setTrigOnUnderThreshold:  [aDecoder decodeBoolForKey:     @"trigOnUnderThreshold"]];
    [self setTestPatternEnabled:    [aDecoder decodeBoolForKey:     @"testPatternEnabled"]];
    [self setTrigOverlapEnabled:    [aDecoder decodeBoolForKey:     @"trigOverlapEnabled"]];
    [self setZsAlgorithm:           [aDecoder decodeIntForKey:      @"zsAlgorithm"]];
    [self setEventSize:             [aDecoder decodeIntForKey:      @"eventSize"]];
    [self setEnabledMask:           [aDecoder decodeIntForKey:      @"enabledMask"]];
    [self setPostTriggerSetting:    [aDecoder decodeInt32ForKey:    @"postTriggerSetting"]];
    [self setTriggerSourceMask:     [aDecoder decodeInt32ForKey:    @"triggerSourceMask"]];
	[self setTriggerOutMask:        [aDecoder decodeInt32ForKey:    @"triggerOutMask"]];
    [self setCoincidenceLevel:      [aDecoder decodeIntForKey:      @"coincidenceLevel"]];
    [self setCountAllTriggers:      [aDecoder decodeBoolForKey:     @"countAllTriggers"]];
    [self setCustomSize:            [aDecoder decodeInt32ForKey:    @"customSize"]];
	[self setIsCustomSize:          [aDecoder decodeBoolForKey:     @"isCustomSize"]];
    [self setWaveFormRateGroup:     [aDecoder decodeObjectForKey:   @"waveFormRateGroup"]];
    [self setNumberBLTEventsToReadout:[aDecoder decodeInt32ForKey:  @"numberBLTEventsToReadout"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:8 groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	int i;
    for (i = 0; i < kNumDT5720Channels; i++){
        [self setLogicType:i withValue:         [aDecoder decodeIntForKey: [NSString stringWithFormat:@"logicType%d", i]]];
        [self setThreshold:i   withValue:       [aDecoder decodeInt32ForKey:[NSString stringWithFormat:@"threshold%d", i]]];
        [self setZsThreshold:i withValue:       [aDecoder decodeInt32ForKey:[NSString stringWithFormat:@"zsThreshold%d", i]]];
        
        [self setDac:i withValue:               [aDecoder decodeInt32ForKey:[NSString stringWithFormat:@"dac%d", i]]];
        [self setOverUnderThreshold:i withValue:[aDecoder decodeIntForKey:  [NSString stringWithFormat:@"overUnderThreshold%d", i]]];
        [self setNlbk:i withValue:              [aDecoder decodeIntForKey:  [NSString stringWithFormat:@"nLbk%d", i]]];
        [self setNlfwd:i withValue:             [aDecoder decodeIntForKey:  [NSString stringWithFormat:@"nLfwd%d", i]]];
    }

    [self setEndianness];
    [self fillVmeRegArray];
    
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)anEncoder
{
    [super encodeWithCoder:anEncoder];
	[anEncoder encodeInt:ttlEnabled                 forKey:@"ttlEnabled"];
	[anEncoder encodeBool:gpoEnabled                forKey:@"gpoEnabled"];
	[anEncoder encodeBool:fpSoftwareTrigEnabled     forKey:@"fpSoftwareTrigEnabled"];
	[anEncoder encodeBool:fpExternalTrigEnabled     forKey:@"fpExternalTrigEnabled"];
	[anEncoder encodeBool:externalTrigEnabled       forKey:@"externalTrigEnabled"];
	[anEncoder encodeBool:softwareTrigEnabled       forKey:@"softwareTrigEnabled"];
	[anEncoder encodeBool:gpiRunMode                forKey:@"gpiRunMode"];
	[anEncoder encodeBool:clockSource               forKey:@"clockSource"];
	[anEncoder encodeBool:trigOnUnderThreshold      forKey:@"trigOnUnderThreshold"];
	[anEncoder encodeBool:testPatternEnabled        forKey:@"testPatternEnabled"];
	[anEncoder encodeBool:trigOverlapEnabled        forKey:@"trigOverlapEnabled"];
	[anEncoder encodeInt:zsAlgorithm                forKey:@"zsAlgorithm"];
	[anEncoder encodeInt:logicType                 forKey:@"logicType"];
	[anEncoder encodeInt:eventSize                  forKey:@"eventSize"];
	[anEncoder encodeInt:enabledMask                forKey:@"enabledMask"];
	[anEncoder encodeInt32:postTriggerSetting       forKey:@"postTriggerSetting"];
	[anEncoder encodeInt32:triggerSourceMask        forKey:@"triggerSourceMask"];
	[anEncoder encodeInt32:triggerOutMask           forKey:@"triggerOutMask"];
	[anEncoder encodeInt:coincidenceLevel           forKey:@"coincidenceLevel"];
	[anEncoder encodeBool:countAllTriggers          forKey:@"countAllTriggers"];
	[anEncoder encodeInt32:customSize               forKey:@"customSize"];
	[anEncoder encodeBool:isCustomSize              forKey:@"isCustomSize"];
    [anEncoder encodeObject:waveFormRateGroup       forKey:@"waveFormRateGroup"];
    [anEncoder encodeInt32:numberBLTEventsToReadout forKey:@"numberBLTEventsToReadout"];
    
	int i;
	for (i = 0; i < kNumDT5720Channels; i++){
        [anEncoder encodeInt32:logicType[i]         forKey:[NSString stringWithFormat:@"logicType%d", i]];
        [anEncoder encodeInt32:thresholds[i]        forKey:[NSString stringWithFormat:@"threshold%d", i]];
        [anEncoder encodeInt32:zsThresholds[i]      forKey:[NSString stringWithFormat:@"zsThreshold%d", i]];
        
        [anEncoder encodeInt32:dac[i]               forKey:[NSString stringWithFormat:@"dac%d", i]];
        [anEncoder encodeInt:overUnderThreshold[i]  forKey:[NSString stringWithFormat:@"overUnderThreshold%d", i]];
        [anEncoder encodeInt:nLbk[i]                forKey:[NSString stringWithFormat:@"nLbk%d", i]];
        [anEncoder encodeInt:nLfwd[i]               forKey:[NSString stringWithFormat:@"nLfwd%d", i]];
    }
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
//TD
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
    //BOOL isDataAvailable;
    
    while (!self.isTimeToStopDataWorker) {

        //is data available?
        
        //if no data available sleep 10 msec and then continue;
        
        //now we have data in digitizer...
        
        //fill from actually read event size
        unsigned long event_size = 1024; //in bytes
        
        
        //the data taker object thing goes here
        
        //pull all the events at once into a static buffer 11 MB large
        
        //break them into multiple events? here? decoder? think abo@sut max ORCA data packet size which is 0x3ffff words
        
        //get the bytes
        
        
        //turn them into nsdata with two empty words prepended
        memset(data_buffer, 0, 8); //make sure orca packet header placeholders are empty
        NSData* event_data = [NSData dataWithBytes:data_buffer length:event_size + 8];
        
        //add them into dataArray
        @synchronized(dataArray) {
            [self.dataArray addObject:[[event_data autorelease] retain]]; //passing ownership to the main thread
        }
    }
    
    self.isDataWorkerRunning = NO;
    [workerPool release];
}


@end

