//-------------------------------------------------------------------------
//  ORGretina4AModel.m
//
//  Created by Mark A. Howe on Wednesday 11/20/14.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//Washington sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

//-------------------------------------------------------------------------

#pragma mark - Imported Files
#import "ORGretina4AModel.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORVmeTests.h"
#import "ORFileMoverOp.h"
#import "MJDCmds.h"
#import "ORRunModel.h"

#define kCurrentFirmwareVersion 0x1
#define kFPGARemotePath @"GretinaFPGA.bin"
//===Register Notifications===
NSString* ORGretina4AExtDiscrimitorSrcChanged           = @"ORGretina4AExtDiscrimitorSrcChanged";
NSString* ORGretina4AHardwareStatusChanged              = @"ORGretina4AHardwareStatusChanged";
NSString* ORGretina4AUserPackageDataChanged             = @"ORGretina4AUserPackageDataChanged";
NSString* ORGretina4AWindowCompMinChanged               = @"ORGretina4AWindowCompMinChanged";
NSString* ORGretina4AWindowCompMaxChanged               = @"ORGretina4AWindowCompMaxChanged";
//---channel control parts---
NSString* ORGretina4APileupWaveformOnlyModeChanged      = @"ORGretina4APileupWaveformOnlyModeChanged";
NSString* ORGretina4APileupExtensionModeChanged         = @"ORGretina4APileupExtensionModeChanged";
NSString* ORGretina4AEventExtensionModeChanged          = @"ORGretina4AEventExtensionModeChanged";
NSString* ORGretina4ADiscCountModeChanged               = @"ORGretina4ADiscCountModeChanged";
NSString* ORGretina4AAHitCountModeChanged               = @"ORGretina4AAHitCountModeChanged";
NSString* ORGretina4AEventCountModeChanged              = @"ORGretina4AEventCountModeChanged";
NSString* ORGretina4ADroppedEventCountModeChanged       = @"ORGretina4ADroppedEventCountModeChanged";
//NSString* ORGretina4AWriteFlagChanged                   = @"ORGretina4AWriteFlagChanged";
NSString* ORGretina4ADecimationFactorChanged            = @"ORGretina4ADecimationFactorChanged";
NSString* ORGretina4ATriggerPolarityChanged             = @"ORGretina4ATriggerPolarityChanged";
NSString* ORGretina4APreampResetDelayEnChanged          = @"ORGretina4APreampResetDelayEnChanged";
NSString* ORGretina4APileupModeChanged                  = @"ORGretina4APileupModeChanged";
NSString* ORGretina4AEnabledChanged                     = @"ORGretina4AEnabledChanged";
//---------
NSString* ORGretina4ALedThreshold0Changed               = @"ORGretina4ALedThreshold0Changed";
NSString* ORGretina4APreampResetDelay0Changed           = @"ORGretina4APreampResetDelay0Changed";
NSString* ORGretina4ARawDataLengthChanged               = @"ORGretina4ARawDataLengthChanged";
NSString* ORGretina4ARawDataWindowChanged               = @"ORGretina4ARawDataWindowChanged";
NSString* ORGretina4ADWindowChanged                     = @"ORGretina4ADWindowChanged";
NSString* ORGretina4AKWindowChanged                     = @"ORGretina4AKWindowChanged";
NSString* ORGretina4AMWindowChanged                     = @"ORGretina4AMWindowChanged";
NSString* ORGretina4AD3WindowChanged                    = @"ORGretina4AD3WindowChanged";
NSString* ORGretina4ADiscWidthChanged                   = @"ORGretina4ADiscWidthChanged";
NSString* ORGretina4ABaselineStartChanged               = @"ORGretina4ABaselineStart0Changed";
NSString* ORGretina4AP1WindowChanged                    = @"ORGretina4AP1WindowChanged";
//---DAC Config---
NSString* ORGretina4ADacChannelSelectChanged            = @"ORGretina4ADacChannelSelectChanged";
NSString* ORGretina4ADacAttenuationChanged              = @"ORGretina4ADacAttenuationChanged";
//------
NSString* ORGretina4AP2WindowChanged                    = @"ORGretina4AP2WindowChanged";
NSString* ORGretina4AChannelPulseControlChanged         = @"ORGretina4AChannelPulseControlChanged";
NSString* ORGretina4ADiagMuxControlChanged              = @"ORGretina4ADiagMuxControlChanged";
NSString* ORGretina4AHoldoffTimeChanged                 = @"ORGretina4AHoldoffTimeChanged";
NSString* ORGretina4APeakSensitivityChanged             = @"ORGretina4APeakSensitivityChanged";
NSString* ORGretina4AAutoModeChanged                    = @"ORGretina4AAutoModeChanged";
//---Baseline Delay---
NSString* ORGretina4ABaselineDelayChanged               = @"ORGretina4ABaselineDelayChanged";
NSString* ORGretina4ATrackingSpeedChanged               = @"ORGretina4ATrackingSpeedChanged";
//------
NSString* ORGretina4ADiagInputChanged                   = @"ORGretina4ADiagInputChanged";
NSString* ORGretina4ADiagChannelEventSelChanged         = @"ORGretina4ADiagChannelEventSelChanged";
NSString* ORGretina4AExtDiscriminatorModeChanged        = @"ORGretina4AExtDiscriminatorModeChanged";
NSString* ORGretina4ARj45SpareIoDirChanged              = @"ORGretina4ARj45SpareIoDirChanged"; //<<some more
NSString* ORGretina4ARj45SpareIoMuxSelChanged           = @"ORGretina4ARj45SpareIoMuxSelChanged";
NSString* ORGretina4ALedStatusChanged                   = @"ORGretina4ALedStatusChanged";
NSString* ORGretina4AVetoGateWidthChanged               = @"ORGretina4AVetoGateWidthChanged";
//---Master Logic Status
NSString* ORGretina4ADiagIsyncChanged                   = @"ORGretina4ADiagIsyncChanged";//<<some more
NSString* ORGretina4AOverflowFlagChanChanged            = @"ORGretina4AOverflowFlagChanChanged";
NSString* ORGretina4ASerdesSmLostLockChanged            = @"ORGretina4ASerdesSmLostLockChanged";
//------
NSString* ORGretina4ATriggerConfigChanged               = @"ORGretina4ATriggerConfigChanged";
NSString* ORGretina4APhaseErrorCountChanged             = @"ORGretina4APhaseErrorCountChanged";
NSString* ORGretina4APhaseStatusChanged                 = @"ORGretina4APhaseStatusChanged";
NSString* ORGretina4ASerdesPhaseValueChanged            = @"ORGretina4ASerdesPhaseValueChanged";
NSString* ORGretina4AMjrCodeRevisionChanged             = @"ORGretina4AMjrCodeRevisionChanged";
NSString* ORGretina4AMinCodeRevisionChanged             = @"ORGretina4AMinCodeRevisionChanged";
NSString* ORGretina4ACodeDateChanged                    = @"ORGretina4ACodeDateChanged";
NSString* ORGretina4ACodeRevisionChanged                 = @"ORGretina4ACodeRevisionChanged";
NSString* ORGretina4AFwTypeChanged                      = @"ORGretina4AFwTypeChanged";
NSString* ORGretina4ATSErrCntCtrlChanged                = @"ORGretina4ATSErrCntCtrlChanged";
NSString* ORGretina4ATSErrorCountChanged                = @"ORGretina4ATSErrorCountChanged";
NSString* ORGretina4ADroppedEventCountChanged           = @"ORGretina4ADroppedEventCountChanged";
NSString* ORGretina4AAcceptedEventCountChanged          = @"ORGretina4AAcceptedEventCountChanged";
NSString* ORGretina4AAhitCountChanged                   = @"ORGretina4AAhitCountChanged";
NSString* ORGretina4ADiscCountChanged                   = @"ORGretina4ADiscCountChanged";
//---sd_config Reg
NSString* ORGretina4ASdPemChanged                       = @"ORGretina4ASdPemChanged";
NSString* ORGretina4ASdSmLostLockFlagChanged            = @"ORGretina4ASdSmLostLockFlagChanged";
//------
NSString* ORGretina4AVmeStatusChanged                   = @"ORGretina4AVmeStatusChanged";
NSString* ORGretina4AConfigMainFpgaChanged              = @"ORGretina4AConfigMainFpgaChanged";
NSString* ORGretina4AClkSelect0Changed                  = @"ORGretina4AClkSelect0Changed";
NSString* ORGretina4AClkSelect1Changed                  = @"ORGretina4AClkSelect1Changed";
NSString* ORGretina4AFlashModeChanged                   = @"ORGretina4AFlashModeChanged";
NSString* ORGretina4ASerialNumChanged                   = @"ORGretina4ASerialNumChanged";
NSString* ORGretina4ABoardRevNumChanged                 = @"ORGretina4ABoardRevNumChanged";
NSString* ORGretina4AVhdlVerNumChanged                  = @"ORGretina4AVhdlVerNumChanged";
//---AuxIO--
NSString* ORGretina4AAuxIoReadChanged                   = @"ORGretina4AAuxIoReadChanged";
NSString* ORGretina4AAuxIoWriteChanged                  = @"ORGretina4AAuxIoWriteChanged";
NSString* ORGretina4AAuxIoConfigChanged                 = @"ORGretina4AAuxIoConfigChanged";
//===Notifications for Low-Level Reg Access===
NSString* ORGretina4ARegisterIndexChanged               = @"ORGretina4ARegisterIndexChanged";
NSString* ORGretina4ASelectedChannelChanged             = @"ORGretina4ASelectedChannelChanged";
NSString* ORGretina4ARegisterWriteValueChanged          = @"ORGretina4ARegisterWriteValueChanged";
NSString* ORGretina4ASPIWriteValueChanged               = @"ORGretina4ASPIWriteValueChanged";
//===Notifications for Firmware Loading===
NSString* ORGretina4AFpgaDownProgressChanged            = @"ORGretina4AFpgaDownProgressChanged";
NSString* ORGretina4AMainFPGADownLoadStateChanged		= @"ORGretina4AMainFPGADownLoadStateChanged";
NSString* ORGretina4AFpgaFilePathChanged				= @"ORGretina4AFpgaFilePathChanged";
NSString* ORGretina4AModelFirmwareStatusStringChanged	= @"ORGretina4AModelFirmwareStatusStringChanged";
NSString* ORGretina4AMainFPGADownLoadInProgressChanged	= @"ORGretina4AMainFPGADownLoadInProgressChanged";
//====General
NSString* ORGretina4ARateGroupChangedNotification       = @"ORGretina4ARateGroupChangedNotification";
NSString* ORGretina4AFIFOCheckChanged                   = @"ORGretina4AFIFOCheckChanged";
NSString* ORGretina4AModelInitStateChanged              = @"ORGretina4AModelInitStateChanged";
NSString* ORGretina4ACardInited                         = @"ORGretina4ACardInited";
NSString* ORGretina4AForceFullCardInitChanged           = @"ORGretina4AForceFullCardInitChanged";
NSString* ORGretina4AForceFullInitChanged               = @"ORGretina4AForceFullInitChanged";
NSString* ORGretina4ALockChanged                        = @"ORGretina4ALockChanged";
NSString* ORGretina4ASettingsLock                       = @"ORGretina4ASettingsLock";
NSString* ORGretina4ARegisterLock                       = @"ORGretina4ARegisterLock";

@interface ORGretina4AModel (private)
//firmware loading
- (void) programFlashBuffer:(NSData*)theData;
- (void) programFlashBufferBlock:(NSData*)theData address:(unsigned long)address numberBytes:(unsigned long)numberBytesToWrite;
- (void) blockEraseFlash;
- (void) programFlashBuffer:(NSData*)theData;
- (BOOL) verifyFlashBuffer:(NSData*)theData;
- (void) reloadMainFPGAFromFlash;
- (void) setProgressStateOnMainThread:(NSString*)aState;
- (void) updateDownLoadProgress;
- (void) downloadingMainFPGADone;
- (void) fpgaDownLoadThread:(NSData*)dataFromFile;
- (void) copyFirmwareFileToSBC:(NSString*)firmwarePath;
- (BOOL) controllerIsSBC;
- (void) setFpgaDownProgress:(short)aFpgaDownProgress;
- (void) loadFPGAUsingSBC;
@end


@implementation ORGretina4AModel


#pragma mark - Boilerplate
- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [firmwareStatusString release];
    [spiConnector release];
    [linkConnector release];
    [mainFPGADownLoadState release];
    [fpgaFilePath release];
    [waveFormRateGroup release];
    [fifoFullAlarm clearAlarm];
    [fifoFullAlarm release];
    [progressLock release];
    [fileQueue cancelAllOperations];
    [fileQueue release];
    [super dealloc];
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"Gretina4ACard"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    int chan;
    float y=73;
    float dy=3;
    NSColor* enabledColor  = [NSColor colorWithCalibratedRed:0.4 green:0.7 blue:0.4 alpha:1];
    NSColor* disabledColor = [NSColor clearColor];
    for(chan=0;chan<kNumGretina4AChannels;chan+=2){
        if(enabled[chan])  [enabledColor  set];
        else			  [disabledColor set];
        [[NSBezierPath bezierPathWithRect:NSMakeRect(5,y,4,dy)] fill];
        
        if(enabled[chan+1])[enabledColor  set];
        else			  [disabledColor set];
        [[NSBezierPath bezierPathWithRect:NSMakeRect(9,y,4,dy)] fill];
        y -= dy;
    }
    [i unlockFocus];
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:OROrcaObjectImageChanged
     object:self];
}

- (void) makeMainController
{
    [self linkToController:@"ORGretina4AController"];
}

- (NSString*) helpURL
{
    return @"VME/Gretina.html";
}

- (Class) guardianClass
{
    return NSClassFromString(@"ORVme64CrateModel");
}

- (NSRange)	memoryFootprint
{
    return NSMakeRange(baseAddress,baseAddress+0x1000+0xffff);
}

- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setSpiConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    
    [spiConnector setConnectorImageType:kSmallDot];
    [spiConnector setConnectorType: 'SPIO' ];
    [spiConnector addRestrictedConnectionType: 'SPII' ]; //can only connect to SPI inputs
    [spiConnector setOffColor:[NSColor colorWithCalibratedRed:0 green:.68 blue:.65 alpha:1.]];
    
    [self setLinkConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    
    [linkConnector setSameGuardianIsOK:YES];
    [linkConnector setConnectorImageType:kSmallDot];
    [linkConnector setConnectorType: 'LNKI' ];
    [linkConnector addRestrictedConnectionType: 'LNKO' ]; //can only connect to Link inputs
    [linkConnector setOffColor:[NSColor colorWithCalibratedRed:1 green:1 blue:.3 alpha:1.]];
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [self guardian:guardian positionConnectorsForCard:self];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ORVmeCardSlotChangedNotification
     object: self];
}

- (void) positionConnector:(ORConnector*)aConnector
{
    NSRect aFrame = [aConnector localFrame];
    if(aConnector == spiConnector){
        float x =  17 + [self slot] * 16*.62 ;
        float y =  78;
        aFrame.origin = NSMakePoint(x,y);
        [aConnector setLocalFrame:aFrame];
    }
    else if(aConnector == linkConnector){
        float x =  17 + [self slot] * 16*.62 ;
        float y =  100;
        aFrame.origin = NSMakePoint(x,y);
        [aConnector setLocalFrame:aFrame];
    }
}

- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
    
    [super setGuardian:aGuardian];
    
    if(oldGuardian != aGuardian){
        [oldGuardian removeDisplayOf:spiConnector];
        [oldGuardian removeDisplayOf:linkConnector];
    }
    
    [aGuardian assumeDisplayOf:spiConnector];
    [aGuardian assumeDisplayOf:linkConnector];
    [self guardian:aGuardian positionConnectorsForCard:self];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    [aGuardian positionConnector:spiConnector forCard:self];
    [aGuardian positionConnector:linkConnector forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:spiConnector];
    [aGuardian removeDisplayOf:linkConnector];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:spiConnector];
    [aGuardian assumeDisplayOf:linkConnector];
}

- (void) disconnect
{
    [spiConnector disconnect];
    [linkConnector disconnect];
    [super disconnect];
}

- (unsigned long) baseAddress   { return (([self slot]+1)&0x1f)<<20; }

- (ORConnector*)  linkConnector { return linkConnector; }
- (void) setLinkConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [linkConnector release];
    linkConnector = aConnector;
}

- (ORConnector*) spiConnector   {   return spiConnector;    }
- (void) setSpiConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [spiConnector release];
    spiConnector = aConnector;
}

#pragma mark ***Access Methods for Low-Level Access
- (unsigned long) spiWriteValue { return spiWriteValue; }
- (void) setSPIWriteValue:(unsigned long)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSPIWriteValue:spiWriteValue];
    spiWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASPIWriteValueChanged object:self];
}

- (short) registerIndex { return registerIndex; }
- (void) setRegisterIndex:(int)aRegisterIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterIndex:registerIndex];
    registerIndex = aRegisterIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARegisterIndexChanged object:self];
}

- (unsigned long) registerWriteValue { return registerWriteValue; }
- (void) setRegisterWriteValue:(unsigned long)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterWriteValue:registerWriteValue];
    registerWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARegisterWriteValueChanged object:self];
}

- (unsigned long) selectedChannel { return selectedChannel;}
- (void) setSelectedChannel:(unsigned short)aChannel
{
    if(aChannel >= kNumGretina4AChannels) aChannel = kNumGretina4AChannels - 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedChannel:selectedChannel];
    selectedChannel = aChannel;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASelectedChannelChanged object:self];
}

- (unsigned long) readRegister:(unsigned int)index
{
    if (index >= kNumberOfGretina4ARegisters) return -1;
    if (![Gretina4ARegisters regIsReadable:index]) return -1;
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[Gretina4ARegisters address:[self baseAddress] forRegisterIndex:index]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue;
}

- (void) writeRegister:(unsigned int)index withValue:(unsigned long)value
{
    if (index >= kNumberOfGretina4ARegisters) return;
    if (![Gretina4ARegisters regIsWriteable:index]) return;
    [[self adapter] writeLongBlock:&value
                         atAddress:[Gretina4ARegisters address:[self baseAddress] forRegisterIndex:index]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeToAddress:(unsigned long)anAddress aValue:(unsigned long)aValue
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + anAddress
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (unsigned long) readFromAddress:(unsigned long)anAddress
{
    unsigned long value = 0;
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + anAddress
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return value;
}

- (unsigned long) readFPGARegister:(unsigned int)index;
{
    if (index >= kNumberOfFPGARegisters) return -1;
    if (![Gretina4AFPGARegisters regIsReadable:index]) return -1;
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[Gretina4AFPGARegisters address:[self baseAddress] forRegisterIndex:index]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue;
}

- (void) writeFPGARegister:(unsigned int)index withValue:(unsigned long)value
{
    if (index >= kNumberOfFPGARegisters) return;
    if (![Gretina4AFPGARegisters regIsWriteable:index]) return;
    [[self adapter] writeLongBlock:&value
                         atAddress:[Gretina4AFPGARegisters address:[self baseAddress] forRegisterIndex:index]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) snapShotRegisters
{
    int i;
    for(i=0;i<kNumberOfGretina4ARegisters;i++){
        snapShot[i] = [self readRegister:i];
    }
    
    for(i=0;i<kNumberOfFPGARegisters;i++){
        fpgaSnapShot[i] = [self readFPGARegister:i];
    }
}

- (void) compareToSnapShot
{
    NSLog(@"------------------------------------------------\n");
    NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"offset   snapshot        newest\n");
    
    int i;
    for(i=0;i<kNumberOfGretina4ARegisters;i++){
        unsigned long theValue = [self readRegister:i];
        if(snapShot[i] != theValue){
            NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"0x%04x 0x%08x != 0x%08x %@\n",[Gretina4ARegisters offsetForRegisterIndex:i],snapShot[i],theValue,[Gretina4ARegisters registerName:i]);
            
        }
    }
    
    for(i=0;i<kNumberOfFPGARegisters;i++){
        unsigned long theValue = [self readFPGARegister:i];
        if(fpgaSnapShot[i] != theValue){
            NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"0x%04x 0x%08x != 0x%08x %@\n",[Gretina4AFPGARegisters offsetForRegisterIndex:i],fpgaSnapShot[i],theValue,[Gretina4AFPGARegisters registerName:i]);
            
        }
    }
    NSLog(@"------------------------------------------------\n");
    
}

- (void) dumpAllRegisters
{
    NSLog(@"------------------------------------------------\n");
    NSLog(@"Register Values for Channel #1\n");
    int i;
    for(i=0;i<kNumberOfGretina4ARegisters;i++){
        unsigned long theValue = [self readRegister:i];
        NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"0x%04x 0x%08x %10d %@\n",[Gretina4ARegisters offsetForRegisterIndex:i],theValue,theValue,[Gretina4ARegisters registerName:i]);
        snapShot[i] = theValue;
        
    }
    NSLog(@"------------------------------------------------\n");
    
    for(i=0;i<kNumberOfFPGARegisters;i++){
        unsigned long theValue = [self readFPGARegister:i];
        NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"0x%04x 0x%08x %@\n",[Gretina4AFPGARegisters offsetForRegisterIndex:i],theValue,[Gretina4AFPGARegisters registerName:i]);
        
        fpgaSnapShot[i] = theValue;
    }
}

#pragma mark - Firmware loading
- (BOOL) downLoadMainFPGAInProgress
{
    return downLoadMainFPGAInProgress;
}

- (void) setDownLoadMainFPGAInProgress:(BOOL)aState
{
    downLoadMainFPGAInProgress = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AMainFPGADownLoadInProgressChanged object:self];
}

- (short) fpgaDownProgress
{
    int temp;
    [progressLock lock];
    temp = fpgaDownProgress;
    [progressLock unlock];
    return temp;
}

- (NSString*) mainFPGADownLoadState
{
    if(!mainFPGADownLoadState) return @"--";
    else return mainFPGADownLoadState;
}

- (void) setMainFPGADownLoadState:(NSString*)aMainFPGADownLoadState
{
    if(!aMainFPGADownLoadState) aMainFPGADownLoadState = @"--";
    [mainFPGADownLoadState autorelease];
    mainFPGADownLoadState = [aMainFPGADownLoadState copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AMainFPGADownLoadStateChanged object:self];
}

- (NSString*) fpgaFilePath
{
    return fpgaFilePath;
}

- (void) setFpgaFilePath:(NSString*)aFpgaFilePath
{
    if(!aFpgaFilePath)aFpgaFilePath = @"";
    [fpgaFilePath autorelease];
    fpgaFilePath = [aFpgaFilePath copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFpgaFilePathChanged object:self];
}

- (void) startDownLoadingMainFPGA
{
    if(!progressLock)progressLock = [[NSLock alloc] init];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFpgaDownProgressChanged object:self];
    
    stopDownLoadingMainFPGA = NO;
    
    //to minimize disruptions to the download thread we'll check and update the progress from the main thread via a timer.
    fpgaDownProgress = 0;
    
    if(![self controllerIsSBC]){
        [self setDownLoadMainFPGAInProgress: YES];
        [self updateDownLoadProgress];
        NSLog(@"Gretina4A (%d) beginning firmware load via Mac, File: %@\n",[self uniqueIdNumber],fpgaFilePath);
        
        [NSThread detachNewThreadSelector:@selector(fpgaDownLoadThread:) toTarget:self withObject:[NSData dataWithContentsOfFile:fpgaFilePath]];
    }
    else {
        if([[[self adapter]sbcLink]isConnected]){
            [self setDownLoadMainFPGAInProgress: YES];
            NSLog(@"Gretina4A (%d) beginning firmware load via SBC, File: %@\n",[self uniqueIdNumber],fpgaFilePath);
            [self copyFirmwareFileToSBC:fpgaFilePath];
        }
        else {
            [self setDownLoadMainFPGAInProgress: NO];
            NSLog(@"Gretina4A (%d) unable to load firmware. SBC not connected.\n",[self uniqueIdNumber]);
        }
    }
}

- (void) tasksCompleted: (NSNotification*)aNote
{
}

- (BOOL) queueIsRunning
{
    return [fileQueue operationCount];
}

- (NSString*) firmwareStatusString
{
    if(!firmwareStatusString)return @"--";
    else return firmwareStatusString;
}

- (void) setFirmwareStatusString:(NSString*)aState
{
    if(!aState)aState = @"--";
    [firmwareStatusString autorelease];
    firmwareStatusString = [aState copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AModelFirmwareStatusStringChanged object:self];
}

- (void) flashFpgaStatus:(ORSBCLinkJobStatus*) jobStatus
{
    [self setDownLoadMainFPGAInProgress: [jobStatus running]];
    [self setFpgaDownProgress:           [jobStatus progress]];
    NSArray* parts = [[jobStatus message] componentsSeparatedByString:@"$"];
    NSString* stateString   = @"";
    NSString* verboseString = @"";
    if([parts count]>=1)stateString   = [parts objectAtIndex:0];
    if([parts count]>=2)verboseString = [parts objectAtIndex:1];
    [self setProgressStateOnMainThread:  stateString];
    [self setFirmwareStatusString:       verboseString];
    [self updateDownLoadProgress];
    if(![jobStatus running]){
        NSLog(@"Gretina4A (%d) firmware load job in SBC finished (%@)\n",[self uniqueIdNumber],[jobStatus finalStatus]?@"Success":@"Failed");
        if([jobStatus finalStatus]){
            [self readFPGAVersions];
            [self checkFirmwareVersion:YES];
        }
    }
    
}

- (void) stopDownLoadingMainFPGA
{
    if(downLoadMainFPGAInProgress){
        if(![self controllerIsSBC]){
            stopDownLoadingMainFPGA = YES;
        }
        else {
            SBC_Packet aPacket;
            aPacket.cmdHeader.destination			= kSBC_Process;//kSBC_Command;//kSBC_Process;
            aPacket.cmdHeader.cmdID					= kSBC_KillJob;
            aPacket.cmdHeader.numberBytesinPayload	= 0;
            
            @try {
                
                //send a kill packet. The response will be a job status record
                [[[self adapter] sbcLink] send:&aPacket receive:&aPacket];
                NSLog(@"Told SBC to stop FPGA load.\n");
                //NSLog(@"Error Code: %s\n",aPacket.message);
                //[NSException raise:@"Xilinx load failed" format:@"%d",errorCode];
                // }
                //else NSLog(@"Looks like success.\n");
            }
            @catch(NSException* localException) {
                NSLog(@"kSBC_KillJob command failed. %@\n",localException);
                [NSException raise:@"kSBC_KillJob command failed" format:@"%@",localException];
            }
            
        }
    }
}


#pragma mark - rates
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
     postNotificationName:ORGretina4ARateGroupChangedNotification
     object:self];
}

- (id) rateObject:(short)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
    //we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

- (unsigned long) getCounter:(short)counterTag forGroup:(short)groupTag
{
    if(groupTag == 0){
        if(counterTag>=0 && counterTag<kNumGretina4AChannels){
            return waveFormCount[counterTag];
        }
        else return 0;
    }
    else return 0;
}

#pragma mark - Initialization
- (BOOL) forceFullCardInit		{ return forceFullCardInit; }
- (void) setForceFullCardInit:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setForceFullCardInit:forceFullCardInit];
    forceFullCardInit = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AForceFullCardInitChanged object:self];
}

- (BOOL) forceFullInit:(short)chan		{ return forceFullInit[chan]; }
- (void) setForceFullInit:(short)chan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setForceFullInit:chan withValue:forceFullInit[chan]];
    forceFullInit[chan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AForceFullInitChanged object:self];
}

#pragma mark - Persistant Register Values
//------------------- Address = 0x0008  Bit Field = 32..0 ---------------
- (unsigned long) extDiscriminatorSrc { return extDiscriminatorSrc ;}
- (void)  setExtDiscriminatorSrc:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setExtDiscriminatorSrc:extDiscriminatorSrc];
    extDiscriminatorSrc = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AExtDiscrimitorSrcChanged object:self];
}

//------------------- Address = 0x0020  Bit Field = 31 ---------------
- (unsigned long) hardwareStatus { return hardwareStatus; }
- (void)          setHardwareStatus:(unsigned long)aValue
{
    hardwareStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AHardwareStatusChanged object:self];
}

//------------------- Address = 0x0024  Bit Field = 11..0 ---------------
- (unsigned long) userPackageData { return userPackageData; }
- (void) setUserPackageData:(unsigned long)aValue
{
    if(aValue>0xFFF)aValue = 0xFFF;
    if(userPackageData != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setUserPackageData:userPackageData];
        userPackageData = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AUserPackageDataChanged object:self];
    }
}

//------------------- Address = 0x0028  Bit Field = 15..0 ---------------
- (unsigned short) windowCompMin { return windowCompMin; }
- (void)           setWindowCompMin:(unsigned short)aValue
{
    if(aValue>0xFFFF)aValue = 0xFFFF;
    if(windowCompMin != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setWindowCompMin:windowCompMin];
        windowCompMin = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AWindowCompMinChanged object:self];
    }
}

//------------------- Address = 0x002C  Bit Field = 15..0 ---------------
- (unsigned short) windowCompMax    { return windowCompMax; }
- (void)           setWindowCompMax:(unsigned short)aValue
{
    if(aValue>0xFFFF)aValue = 0xFFFF;
    if(windowCompMax != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setWindowCompMax:windowCompMax];
        windowCompMax = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AWindowCompMaxChanged object:self];
    }
}

//------------------- Address = 0x0040  Bit Field = 15..0 ---------------
//------------------- kChannelControl  Bit Field = 0 ---------------
- (BOOL) enabled:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels)return enabled[chan];
    else return NO;
}
- (void) setEnabled:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan<kNumGretina4AChannels) && (aValue!=enabled[chan])){
        [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:chan withValue:enabled[chan]];
        enabled[chan] = aValue;
        [self setUpImage];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AEnabledChanged object:self];
        [self postAdcInfoProvidingValueChanged];
    }
}
//------------------- kChannelControl  Bit Field = 2 ---------------
- (BOOL) pileupMode:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels)return pileupMode[chan];
    else return NO;
}

- (void) setPileupMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels) && (aValue!=pileupMode[chan])){
        [[[self undoManager] prepareWithInvocationTarget:self] setPileupMode:chan withValue:pileupMode[chan]];
        pileupMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APileupModeChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 3 ---------------
- (BOOL) preampResetDelayEn:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels)  return preampResetDelayEn[chan];
    else                            return NO;
}

- (void) setPreampResetDelayEn:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels) && (aValue!=preampResetDelayEn[chan])){
        [[[self undoManager] prepareWithInvocationTarget:self] setPreampResetDelayEn:chan withValue:preampResetDelayEn[chan]];
        preampResetDelayEn[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APreampResetDelayEnChanged object:self];
    }
}


//------------------- kChannelControl  Bit Field = 10..11 ---------------
- (short) triggerPolarity:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels ) return triggerPolarity[chan];
    else                            return 0;
}

- (void) setTriggerPolarity:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue > 0x3)aValue = 0x3;
    if((chan < kNumGretina4AChannels) && (aValue!=triggerPolarity[chan])){
        [[[self undoManager] prepareWithInvocationTarget:self] setTriggerPolarity:chan withValue:triggerPolarity[chan]];
        triggerPolarity[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATriggerPolarityChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 12..14 ---------------
- (short) decimationFactor:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels) return decimationFactor[chan];
    else                             return 0;
}

- (void) setDecimationFactor:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue>0x7)aValue = 0x7;
    if((chan < kNumGretina4AChannels) && (aValue!=decimationFactor[chan])){
        [[[self undoManager] prepareWithInvocationTarget:self] setDecimationFactor:chan withValue:decimationFactor[chan]];
        decimationFactor[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADecimationFactorChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 15 ---------------
//******format all channels the same
//- (BOOL) writeFlag { return writeFlag; }
//- (void) setWriteFlag:(BOOL)aValue
//{
//    if(writeFlag != aValue){
//        [[[self undoManager] prepareWithInvocationTarget:self] setWriteFlag:writeFlag];
//        writeFlag = aValue;
//        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AWriteFlagChanged object:self];
//    }
//}

//------------------- kChannelControl  Bit Field = 20 ---------------
- (BOOL) droppedEventCountMode:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels)return droppedEventCountMode[chan];
    else return NO;
}

- (void) setDroppedEventCountMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels) && (droppedEventCountMode[chan] != aValue)) {
        [[[self undoManager] prepareWithInvocationTarget:self] setDroppedEventCountMode:chan withValue:droppedEventCountMode[chan]];
        droppedEventCountMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADroppedEventCountModeChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 21 ---------------
- (BOOL) eventCountMode:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels ) return eventCountMode[chan];
    else                              return NO;
}

- (void) setEventCountMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels) && (eventCountMode[chan] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setEventCountMode:chan withValue:eventCountMode[chan]];
        eventCountMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AEventCountModeChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 22 ---------------
- (BOOL)  aHitCountMode:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels) return aHitCountMode[chan];
    else                             return NO;
}

- (void)  setAHitCountMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels) && (aHitCountMode[chan] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setAHitCountMode:chan withValue:aHitCountMode[chan]];
        aHitCountMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAHitCountModeChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 23 ---------------
- (BOOL)  discCountMode:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels) return discCountMode[chan];
    else                           return NO;
    
}
- (void)  setDiscCountMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels) && (discCountMode[chan] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setDiscCountMode:chan withValue:discCountMode[chan]];
        discCountMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiscCountModeChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 24..25 ---------------
- (short) eventExtensionMode:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels )return eventExtensionMode[chan];
    else return 0;
}

- (void) setEventExtensionMode:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue>0x3)aValue = 0x3;
    if((chan < kNumGretina4AChannels) && (eventExtensionMode[chan] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setEventExtensionMode:chan withValue:eventExtensionMode[chan]];
        eventExtensionMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AEventExtensionModeChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 26 ---------------
- (BOOL)  pileupExtensionMode:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels )return pileupExtensionMode[chan];
    else                             return NO;
}

- (void) setPileupExtensionMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels) && (pileupExtensionMode[chan] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setPileupExtensionMode:chan withValue:pileupExtensionMode[chan]];
        pileupExtensionMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APileupExtensionModeChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 30 ---------------
- (BOOL) pileupWaveformOnlyMode:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels )return pileupWaveformOnlyMode[chan];
    else                             return NO;
}
- (void) setPileupWaveformOnlyMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels) && (pileupWaveformOnlyMode[chan] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setPileupWaveformOnlyMode:chan withValue:pileupWaveformOnlyMode[chan]];
        pileupWaveformOnlyMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APileupWaveformOnlyModeChanged object:self];
    }
}

//------------------- Address = 0x0080 ---------------
- (void) setThreshold:(unsigned short)chan withValue:(int)aValue
{
    [self setLedThreshold:chan withValue:aValue];
}

- (short) ledThreshold:(unsigned short)chan
{
    if(chan<0 || chan>kNumGretina4AChannels )return 0;
    return ledThreshold[chan];
}

- (void) setLedThreshold:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue>0x3FFF)aValue = 0x3FFF;
    if((chan < kNumGretina4AChannels) && (ledThreshold[chan] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setLedThreshold:chan withValue:ledThreshold[chan]];
        ledThreshold[chan] = aValue;
        
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ALedThreshold0Changed object:self userInfo:userInfo];
    }
}

- (short) preampResetDelay:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels )return preampResetDelay[chan];
    else return 0;
}

- (void) setPreampResetDelay:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue>0x3FF)aValue = 0x3FF;
    if((chan < kNumGretina4AChannels) && (preampResetDelay[chan] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setPreampResetDelay:chan withValue:preampResetDelay[chan]];
        preampResetDelay[chan] = aValue;
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APreampResetDelay0Changed object:self userInfo:userInfo];
    }
}


//------------------- Address = 0x0100 ---------------
//Sets the (maximum) size of the event packets.  Packet will be 4 bytes longer than the value written to this register. (10ns per count)
//same value for all channels
- (short) rawDataLength
{
    return rawDataLength;
}

- (void) setRawDataLength:(unsigned short)aValue
{
    //same value for all channels
    if(aValue>0x3FF)aValue = 0x3FF;
    if((rawDataLength != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setRawDataLength:rawDataLength];
        rawDataLength = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARawDataLengthChanged object:self];
    }
}

//Waveform offset value. (10 ns per count)
//same value for all channels
- (short) rawDataWindow
{
    return rawDataWindow;
}

- (void) setRawDataWindow:(unsigned short)aValue
{
    //same value for all channels
    if(aValue>0x3FF)aValue = 0x3FF;
    if(rawDataWindow != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setRawDataWindow:rawDataWindow];
        rawDataWindow = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARawDataWindowChanged object:self];
    }
}

//------------------- Address = 0x0180  Bit Field = 6..0 ---------------
- (short) dWindow:(unsigned short)chan
{
    //use only the first value for all channels. Keep the array for future expansion
    if(chan == 0)return dWindow[0];
    else return 0;
}

- (void) setDWindow:(unsigned short)chan withValue:(unsigned short)aValue
{
    //use only the first value for all channels. Keep the array for future expansion
    if(aValue>0x7F)aValue = 0x7F;
    if((chan == 0) && (dWindow[0] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setDWindow:0 withValue:dWindow[0]];
        dWindow[0] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADWindowChanged object:self];
    }
}

//------------------- Address = 0x01C0  Bit Field = 6..0 ---------------
- (short) kWindow:(unsigned short)chan
{
    //use only the first value for all channels. Keep the array for future expansion
    if(chan == 0)return kWindow[chan];
    else return 0;
}

- (void) setKWindow:(unsigned short)chan withValue:(unsigned short)aValue
{
    //use only the first value for all channels. Keep the array for future expansion
    if(aValue>0x7F)aValue = 0x7F;
    if((chan == 0) && (kWindow[chan] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setKWindow:chan withValue:kWindow[chan]];
        kWindow[chan] = aValue;
        
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AKWindowChanged object:self userInfo:userInfo];
    }
}
//------------------- Address = 0x0200  Bit Field = 6..0 ---------------
- (short) mWindow:(unsigned short)chan
{
    //use only the first value for all channels. Keep the array for future expansion
    if(chan == 0)return mWindow[chan];
    else return 0;
}

- (void) setMWindow:(unsigned short)chan withValue:(unsigned short)aValue
{
    //use only the first value for all channels. Keep the array for future expansion
    if(aValue>0x7F)aValue = 0x7F;
    if((chan == 0) && (mWindow[chan] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setMWindow:chan withValue:mWindow[chan]];
        mWindow[chan] = aValue;
        
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AMWindowChanged object:self userInfo:userInfo];
    }
}

//------------------- Address = 0x0240  Bit Field = 6..0 ---------------
- (short) d3Window:(unsigned short)chan
{
    //use only the first value for all channels. Keep the array for future expansion
    if(chan == 0)return d3Window[0];
    else return 0;
}

- (void) setD3Window:(unsigned short)chan withValue:(unsigned short)aValue
{
    //use only the first value for all channels. Keep the array for future expansion
    if(aValue>0x7F)aValue = 0x7F;
    if((chan == 0) && (d3Window[0] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setD3Window:0 withValue:d3Window[0]];
        d3Window[0] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AD3WindowChanged object:self];
    }
}

//------------------- Address = 0x0280  Bit Field = N/A ---------------
- (short) discWidth:(unsigned short)chan
{
    //use only the first value for all channels. Keep the array for future expansion
    if(chan == 0)return discWidth[0];
    else  return 0;
}

- (void) setDiscWidth:(unsigned short)chan withValue:(unsigned short)aValue
{
    //use only the first value for all channels. Keep the array for future expansion
    if((chan == 0) && (discWidth[0] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setDiscWidth:0 withValue:discWidth[0]];
        discWidth[0] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiscWidthChanged object:self];
    }
}

//------------------- Address = 0x02C0  Bit Field = 13..0 ---------------
- (short) baselineStart:(unsigned short)chan
{
    //use only the first value for all channels. Keep the array for future expansion
    if(chan == 0)return baselineStart[0];
    else return 0;
}

- (void) setBaselineStart:(unsigned short)chan withValue:(unsigned short)aValue
{
    //use only the first value for all channels. Keep the array for future expansion
    if(aValue>0x3FFF)aValue = 0x3FFF;
    if((chan == 0) && (baselineStart[0] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setBaselineStart:chan withValue:baselineStart[0]];
        baselineStart[0] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ABaselineStartChanged object:self];
    }
}

//------------------- Address = 0x0300  Bit Field = 3 .. 0 ---------------
- (short) p1Window:(unsigned short)chan
{
    //use only the first value for all channels. Keep the array for future expansion
    if(chan == 0)return p1Window[chan];
    else return 0;
}

- (void) setP1Window:(unsigned short)chan withValue:(unsigned short)aValue
{
    //use only the first value for all channels. Keep the array for future expansion
    if(aValue>0x7F)aValue = 0x7F;
    if((chan == 0) && (p1Window[0] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setP1Window:chan withValue:p1Window[0]];
        p1Window[0] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AP1WindowChanged object:self];
    }
}

//------------------- Address = 0x0404  Bit Field = N/A ---------------
- (long) p2Window { return p2Window; }
- (void) setP2Window:(long)aValue
{
    if(aValue>0x1FF)aValue = 0x1FF;
    if(p2Window != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setP2Window:p2Window];
        p2Window = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AP2WindowChanged object:self];
    }
}

//------------------- Address = 0x0400  Bit Field = 3..0 ---------------
- (short) dacChannelSelect { return dacChannelSelect; }
- (void) setDacChannelSelect:(unsigned short)aValue
{
    if(aValue>0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDacChannelSelect:dacChannelSelect];
    dacChannelSelect = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADacChannelSelectChanged object:self];
}

//------------------- Address = 0x0400  Bit Field = 7..0 ---------------
- (short) dacAttenuation { return dacAttenuation; }
- (void) setDacAttenuation:(unsigned short)aValue
{
    if(aValue>0xFF)aValue = 0xFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDacAttenuation:dacAttenuation];
    dacAttenuation = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADacAttenuationChanged object:self];
}

//------------------- Address = 0x040C  ---------------
- (unsigned long) channelPulsedControl { return channelPulsedControl; }
- (void) setChannelPulsedControl:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChannelPulsedControl:channelPulsedControl];
    channelPulsedControl = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AChannelPulseControlChanged object:self];
}

//------------------- Address = 0x0410  ---------------
- (unsigned long) diagMuxControl { return diagMuxControl; }
- (void) setDiagMuxControl:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDiagMuxControl:diagMuxControl];
    diagMuxControl = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiagMuxControlChanged object:self];
}

//------------------- Address = 0x0414  Bit Field = 9..0 ---------------
- (unsigned short) holdoffTime { return holdoffTime; }
- (void) setHoldoffTime:(unsigned short)aValue
{
    if(aValue>0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setHoldoffTime:holdoffTime];
    holdoffTime = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AHoldoffTimeChanged object:self];
}

//------------------- Address = 0x0414  Bit Field = 9..0 ---------------
- (unsigned short) peakSensitivity { return peakSensitivity; }
- (void) setPeakSensitivity:(unsigned short)aValue
{
    if(aValue>0x7)aValue = 0x7;
    [[[self undoManager] prepareWithInvocationTarget:self] setPeakSensitivity:peakSensitivity];
    peakSensitivity = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APeakSensitivityChanged object:self];
}

//------------------- Address = 0x0414  Bit Field = 9..0 ---------------
- (unsigned short) autoMode { return autoMode; }
- (void) setAutoMode:(unsigned short)aValue
{
    if(aValue>0xFF)aValue = 0xFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoMode:autoMode];
    autoMode = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAutoModeChanged object:self];
}

//------------------- Address = 0x0418  Bit Field = 13..0 ---------------
- (unsigned short) baselineDelay { return baselineDelay; }
- (void) setBaselineDelay:(unsigned short)aValue
{
    if(aValue > 0x3FFF)aValue = 0x3FFF;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setBaselineDelay:baselineDelay];
    baselineDelay = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ABaselineDelayChanged object:self];
}

//------------------- Address = 0x0420 ---------------
- (unsigned long)   extDiscriminatorMode { return extDiscriminatorMode; }
- (void)    setExtDiscriminatorMode:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setExtDiscriminatorMode:extDiscriminatorMode];
    extDiscriminatorMode = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AExtDiscriminatorModeChanged object:self];
}


//------------------- Address = 0x0418  Bit Field = 13..0 ---------------
- (unsigned short) trackingSpeed { return trackingSpeed; }
- (void) setTrackingSpeed:(unsigned short)aValue
{
    if(aValue > 0x7)aValue = 0x7;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setTrackingSpeed:trackingSpeed];
    trackingSpeed = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATrackingSpeedChanged object:self];
}

//------------------- Address = 0x041C  Bit Field = 13..0 ---------------
- (unsigned long) diagInput { return diagInput; }
- (void) setDiagInput:(unsigned long)aValue
{
    if(aValue>0x3FFF)aValue = 0x3FFF;
    if(diagInput != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setDiagInput:diagInput];
        diagInput = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiagInputChanged object:self];
    }
}

//------------------- Address = 0x0420  Bit Field = 15..0 ---------------
- (unsigned short) vetoGateWidth { return vetoGateWidth; }
- (void) setVetoGateWidth:(unsigned short)aValue
{
    if(aValue > 0x3FFF)aValue = 0x3FFF;
    if(vetoGateWidth != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setVetoGateWidth:vetoGateWidth];
        vetoGateWidth = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AVetoGateWidthChanged object:self];
    }
}

//------------------- Address = 0x0420  Bit Field = N/A ---------------
- (unsigned long) diagChannelEventSel { return diagChannelEventSel; }
- (void) setDiagChannelEventSel:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDiagChannelEventSel:diagChannelEventSel];
    diagChannelEventSel = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiagChannelEventSelChanged object:self];
}

//------------------- Address = 0x0424  Bit Field = 3..0 ---------------
- (unsigned long) rj45SpareIoMuxSel { return rj45SpareIoMuxSel; }
- (void) setRj45SpareIoMuxSel:(unsigned long)aValue
{
    if(aValue>0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setRj45SpareIoMuxSel:rj45SpareIoMuxSel];
    rj45SpareIoMuxSel = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARj45SpareIoMuxSelChanged object:self];
}

//------------------- Address = 0x0424  Bit Field = 4 ---------------
- (BOOL) rj45SpareIoDir { return rj45SpareIoDir; }
- (void) setRj45SpareIoDir:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRj45SpareIoDir:rj45SpareIoDir];
    rj45SpareIoDir = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARj45SpareIoDirChanged object:self];
}

//------------------- Address = 0x0428 ---------------
- (unsigned long) ledStatus { return ledStatus; }
- (void) setLedStatus:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLedStatus:ledStatus];
    ledStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ALedStatusChanged object:self];
}

//------------------- Address = 0x048C  Bit Field = 31..0 ---------------
//------------------- Address = 0x0490  Bit Field = 15..0 ---------------


//------------------- Address = 0x0500  Bit Field = 1 ---------------
- (BOOL) diagIsync { return diagIsync; }
- (void) setDiagIsync:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDiagIsync:diagIsync];
    diagIsync = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiagIsyncChanged object:self];
}

//------------------- Address = 0x0500  Bit Field = 19 ---------------
- (BOOL) serdesSmLostLock { return serdesSmLostLock; }
- (void) setSerdesSmLostLock:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerdesSmLostLock:serdesSmLostLock];
    serdesSmLostLock = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASerdesSmLostLockChanged object:self];
}

//------------------- Address = 0x0500  Bit Field = 22,23,24,25,26,27,28,29,30,31 ---------------
- (BOOL) overflowFlagChan:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels) return overflowFlagChan[chan];
    else return 0;
}

- (void) setOverflowFlagChan:(unsigned short)chan withValue:(BOOL)aValue
{
    if(chan < kNumGretina4AChannels){
        [[[self undoManager] prepareWithInvocationTarget:self] setOverflowFlagChan:chan withValue:aValue];
        overflowFlagChan[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AOverflowFlagChanChanged object:self];
    }
}

//------------------- Address = 0x0504  Bit Field = N/A ---------------
- (unsigned short) triggerConfig { return triggerConfig; }
- (void) setTriggerConfig:(unsigned short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerConfig:triggerConfig];
    triggerConfig = aValue & 0x3;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATriggerConfigChanged object:self];
}

//------------------- Address = 0x0508  Bit Field = N/A ---------------
- (unsigned long) phaseErrorCount { return phaseErrorCount; }
- (void) setPhaseErrorCount:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPhaseErrorCount:phaseErrorCount];
    phaseErrorCount = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhaseErrorCountChanged object:self];
}

//------------------- Address = 0x050C  Bit Field = 15..0 ---------------
- (unsigned long) phaseStatus { return phaseStatus; }
- (void) setPhaseStatus:(unsigned long)aValue
{
    if(aValue > 0xFFFF)aValue = 0xFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setPhaseStatus:phaseStatus];
    phaseStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhaseStatusChanged object:self];
}

//------------------- Address = 0x051C  Bit Field = N/A ---------------
- (unsigned long) serdesPhaseValue { return serdesPhaseValue; }
- (void) setSerdesPhaseValue:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerdesPhaseValue:serdesPhaseValue];
    serdesPhaseValue = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASerdesPhaseValueChanged object:self];
}

//------------------- Address = 0x0600  Bit Field = 15..12  ---------------
- (unsigned long) codeRevision { return codeRevision; }
- (void) setCodeRevision:(unsigned long)aValue
{
    codeRevision = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ACodeRevisionChanged object:self];
}

//------------------- Address = 0x0604  Bit Field = 31..0 ---------------
- (unsigned long) codeDate { return codeDate; }
- (void) setCodeDate:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCodeDate:codeDate];
    codeDate = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ACodeDateChanged object:self];
}

//------------------- Address = 0x0608  Bit Field = N/A ---------------
- (unsigned long) tSErrCntCtrl { return tSErrCntCtrl;}
- (void) setTSErrCntCtrl:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTSErrCntCtrl:tSErrCntCtrl];
    tSErrCntCtrl = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATSErrCntCtrlChanged object:self];
}

//------------------- Address = 0x060C  Bit Field = N/A ---------------
- (unsigned long) tSErrorCount { return tSErrorCount; }
- (void) setTSErrorCount:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTSErrorCount:tSErrorCount];
    tSErrorCount = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATSErrorCountChanged object:self];
}

//------------------- Address = 0x0700  Bit Field = 31..0 ---------------
- (unsigned long) droppedEventCount:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels)return droppedEventCount[chan];
    else return 0;
}

- (void) setDroppedEventCount:(unsigned short)chan withValue:(unsigned long)aValue
{
    if(chan < kNumGretina4AChannels) {
        [[[self undoManager] prepareWithInvocationTarget:self] setDroppedEventCount:chan withValue:droppedEventCount[chan]];
        droppedEventCount[chan] = aValue;
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADroppedEventCountChanged object:self userInfo:userInfo];
    }
}

//------------------- Address = 0x0740  Bit Field = 31..0 ---------------
- (unsigned long) acceptedEventCount:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels )return acceptedEventCount[chan];
    else return 0;
}

- (void) setAcceptedEventCount:(unsigned short)chan withValue:(unsigned long)aValue
{
    if((chan < kNumGretina4AChannels) && (acceptedEventCount[chan] != aValue)){
        [[[self undoManager] prepareWithInvocationTarget:self] setAcceptedEventCount:chan withValue:acceptedEventCount[chan]];
        acceptedEventCount[chan] = aValue;
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAcceptedEventCountChanged object:self userInfo:userInfo];
    }
}

//------------------- Address = 0x0780  Bit Field = 31..0 ---------------
- (unsigned long) ahitCount:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels )return ahitCount[chan];
    else return 0;
}

- (void) setAhitCount:(unsigned short)chan withValue:(unsigned long)aValue
{
    if(chan < kNumGretina4AChannels){
        [[[self undoManager] prepareWithInvocationTarget:self] setAhitCount:chan withValue:ahitCount[chan]];
        ahitCount[chan] = aValue;
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAhitCountChanged object:self userInfo:userInfo];
    }
}

//------------------- Address = 0x07C0  Bit Field = 31..0 ---------------
- (unsigned long) discCount:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels )return discCount[chan];
    else return 0;
}

- (void) setDiscCount:(unsigned short)chan withValue:(unsigned long)aValue
{
    if(chan < kNumGretina4AChannels) {
        [[[self undoManager] prepareWithInvocationTarget:self] setDiscCount:chan withValue:discCount[chan]];
        discCount[chan] = aValue;
        
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiscCountChanged object:self userInfo:userInfo];
    }
}

//------------------- Address = 0x0800  Bit Field = 31..0 ---------------
- (unsigned long) auxIoRead { return auxIoRead; }
- (void) setAuxIoRead:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAuxIoRead:auxIoRead];
    auxIoRead = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAuxIoReadChanged object:self];
}

//------------------- Address = 0x0804  Bit Field = 31..0 ---------------
- (unsigned long) auxIoWrite { return auxIoWrite; }
- (void) setAuxIoWrite:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAuxIoWrite:auxIoWrite];
    auxIoWrite = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAuxIoWriteChanged object:self];
}

//------------------- Address = 0x0808  Bit Field = 31..0 ---------------
- (unsigned long) auxIoConfig { return auxIoConfig; }
- (void) setAuxIoConfig:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAuxIoConfig:auxIoConfig];
    auxIoConfig = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAuxIoConfigChanged object:self];
}

//------------------- Address = 0x0848  Bit Field = 2..3 ---------------
- (unsigned long) sdPem { return sdPem; }
- (void) setSdPem:(unsigned long)aValue
{
    if(aValue > 0x0)aValue = 0x0;
    [[[self undoManager] prepareWithInvocationTarget:self] setSdPem:sdPem];
    sdPem = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASdPemChanged object:self];}

//------------------- Address = 0x0848  Bit Field = 9 ---------------
- (BOOL) sdSmLostLockFlag {return sdSmLostLockFlag; }
- (void) setSdSmLostLockFlag:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSdSmLostLockFlag:sdSmLostLockFlag];
    sdSmLostLockFlag = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASdSmLostLockFlagChanged object:self];
}

//------------------- Address = 0x0900  Bit Field = 0 ---------------
- (BOOL) configMainFpga { return configMainFpga; }
- (void) setConfigMainFpga:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setConfigMainFpga:configMainFpga];
    configMainFpga = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AConfigMainFpgaChanged object:self];
}

//------------------- Address = 0x0908  Bit Field = 0 ---------------
- (unsigned long) vmeStatus { return vmeStatus; }
- (void) setVmeStatus:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVmeStatus:vmeStatus];
    vmeStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AVmeStatusChanged object:self];
}

//------------------- Address = 0x0910  Bit Field = 0 ---------------
- (BOOL) clkSelect0 { return clkSelect0; }
- (void) setClkSelect0:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClkSelect0:clkSelect0];
    clkSelect0 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AClkSelect0Changed object:self];
}

//------------------- Address = 0x0910  Bit Field = 1 ---------------
- (BOOL) clkSelect1 { return clkSelect1; }
- (void) setClkSelect1:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClkSelect1:clkSelect1];
    clkSelect1 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AClkSelect1Changed object:self];
}

//------------------- Address = 0x0910  Bit Field = 4 ---------------
- (BOOL) flashMode { return flashMode; }
- (void) setFlashMode:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFlashMode:flashMode];
    flashMode = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFlashModeChanged object:self];
}

//------------------- Address = 0X0920  Bit Field = 15..0 ---------------
- (unsigned long) serialNum { return serialNum; }
- (void) setSerialNum:(unsigned long)aValue
{
    if(aValue > 0xFFFF)aValue = 0xFFFF;
    serialNum = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASerialNumChanged object:self];
}

//------------------- Address = 0X0920  Bit Field = 23..16 ---------------
- (unsigned long) boardRevNum { return boardRevNum; }
- (void) setBoardRevNum:(unsigned long)aValue
{
    if(aValue > 0xFF)aValue = 0xFF;
    boardRevNum = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ABoardRevNumChanged object:self];
}

//------------------- Address = 0X0920  Bit Field = 31..24 ---------------
- (unsigned long) vhdlVerNum { return vhdlVerNum; }
- (void) setVhdlVerNum:(unsigned long)aValue
{
    if(aValue > 0xFF)aValue = 0xFF;
    if(vhdlVerNum != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setVhdlVerNum:vhdlVerNum];
        vhdlVerNum = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AVhdlVerNumChanged object:self];
    }
}


#pragma mark - Hardware Access
//=============================================================================
//------------------------- low level calls------------------------------------
- (void) writeLong:(unsigned long)aValue toReg:(int)aReg
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress: [Gretina4ARegisters address:[self baseAddress] forRegisterIndex:aReg]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (unsigned long) readLongFromReg:(int)aReg
{
    unsigned long aValue = 0;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[Gretina4ARegisters address:[self baseAddress] forRegisterIndex:aReg]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return aValue;
}

- (void) writeLong:(unsigned long)aValue toOffset:(int)anOffset
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + anOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (unsigned long) readLongFromOffset:(int)anOffset
{
    unsigned long aValue = 0;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + anOffset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return aValue;
}

//------------------------- kBoardId Reg------------------------------------
- (short)readBoardIDReg         { return [self readLongFromReg:kBoardId]; }
- (BOOL) checkFirmwareVersion   { return [self checkFirmwareVersion:NO];  }



- (BOOL) checkFirmwareVersion:(BOOL)verbose
{
    //find out the Main FPGA version
    unsigned long mainVersion = ([self readLongFromReg:kBoardId] & 0xFFFF0000) >> 16;
    if(verbose)NSLog(@"Main FGPA version: 0x%x \n", mainVersion);
    
    if (mainVersion < kCurrentFirmwareVersion){
        NSLog(@"Main FPGA version does not match: 0x%x is required but 0x%x is loaded.\n", kCurrentFirmwareVersion,mainVersion);
        return NO;
    }
    else return YES;
}

- (BOOL) fifoIsEmpty
{
    unsigned long val = [self readLongFromReg:kProgrammingDone];
    return ((val>>20) & 0x3)==0x3; //both bits are high if FIFO is empty
}

//------------------------- kProgrammingDone Reg ------------------------------------
- (void) resetFIFO
{

    unsigned long val = (0x1<<27); //all other bits are read-only.
    [self writeLong:val toReg:kProgrammingDone];
    [self writeLong:0   toReg:kProgrammingDone];
    
    if(![self fifoIsEmpty]){
        NSLogColor([NSColor redColor], @"%@ Fifo NOT reset properly\n",[self fullID]);
    }
}

//------------------------- Ext Discrim Mode Reg------------------------------------
- (unsigned long) readExtDiscriminatorSrc { return [self readLongFromReg:kUserPackageData] & 0x1fffffff; }
- (void) writeExtDiscriminatorSrc
{
    unsigned long theValue = (extDiscriminatorSrc & 0x1fffffff);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kExternalDiscSrc]
                       mask:0x0000ffff
                  reportKey:@"ExternalDiscSrc"
              forceFullInit:forceFullCardInit];
}

//------------------------- kHardwareStatus Reg------------------------------------
- (unsigned long) readHardwareStatus
{
    [self setHardwareStatus: [self readLongFromReg:kHardwareStatus]];
    return hardwareStatus;
}

//------------------------- kUserPackage Reg------------------------------------
- (unsigned long) readUserPackageData { return [self readLongFromReg:kUserPackageData] & 0xFFFF; }
- (void) writeUserPackageData
{
    [self writeAndCheckLong:(userPackageData & 0xFFFF)
              addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kUserPackageData]
                       mask:0xFFFF
                  reportKey:@"UserPackageData"
              forceFullInit:forceFullCardInit];
}

//------------------------- kWindowCompMin Reg------------------------------------
- (unsigned long) readWindowCompMin { return [self readLongFromReg:kWindowCompMin] & 0xFFFF; }
- (void) writeWindowCompMin
{
    [self writeAndCheckLong:(windowCompMin & 0xFFFF)
              addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kWindowCompMin]
                       mask:0xFFFF
                  reportKey:@"WindowCompMin"
              forceFullInit:forceFullCardInit];
}

//------------------------- kWindowCompMax Reg------------------------------------
- (unsigned long) readWindowCompMax { return [self readLongFromReg:kWindowCompMax] & 0xFFFF; }
- (void) writeWindowCompMax
{
    [self writeAndCheckLong:(windowCompMax & 0xFFFF)
              addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kWindowCompMax]
                       mask:0xFFFF
                  reportKey:@"WindowCompMax"
              forceFullInit:forceFullCardInit];
    
}
//-------------------------kChannelControl----------------------------------------
- (unsigned long) readControlReg:(unsigned short)channel { return [self readLongFromReg:kChannelControl]; }

- (void) writeControlReg:(unsigned short)chan enabled:(BOOL)forceEnable
{
    /* writeControlReg writes the current model state to the board.  If forceEnable is NO, *
     * then all the channels are disabled.  Otherwise, the channels are enabled according  *
     * to the model state.                                                                 */
    
    BOOL startStop;
    if(forceEnable)	startStop= enabled[chan];
    else			startStop = NO;
    
    unsigned long theValue =
    (startStop                        << 0)  |
    (pileupMode[chan]                 << 2)  |
    (preampResetDelay[chan]           << 3)  |
    ((triggerPolarity[chan] & 0x3)    << 10) |
    ((decimationFactor[chan] & 0x7)   << 12) |
//    (writeFlag                        << 15) |
    (droppedEventCountMode[chan]      << 20) |
    (eventCountMode[chan]             << 21) |
    (aHitCountMode[chan]              << 22) |
    (discCountMode[chan]              << 23) |
    ((eventExtensionMode[chan] & 0x3) << 24) |
    (pileupExtensionMode[chan]        << 26) |
    (pileupWaveformOnlyMode[chan]     << 30);
    
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kChannelControl chan:chan]
                       mask:0x4FF0FC0D //mask off the reserved bits
                  reportKey:[NSString stringWithFormat:@"ControlStatus_%d",chan]
              forceFullInit:forceFullInit[chan]];
}

- (void) clearCounters
{
    int chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        unsigned long old = [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kChannelControl chan:chan]];
        //toggle the reset bit
        old ^= (0x1<<27);
        [self writeLong:old toOffset:[Gretina4ARegisters offsetForRegisterIndex:kChannelControl chan:chan]];
        old ^= (0x1<<27);
        [self writeLong:old toOffset:[Gretina4ARegisters offsetForRegisterIndex:kChannelControl chan:chan]];
    }
}

//-------------------------kLedThreshold Reg----------------------------------------
- (unsigned long) readLedThreshold:(unsigned short)channel
{
    if(channel<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kLedThreshold chan:channel]];
    }
    else return 0;
}

- (void) writeLedThreshold:(unsigned short)channel
{
    if(channel < kNumGretina4AChannels){
        unsigned long theValue = ((preampResetDelay[channel] & 0x000000ff)<<16) | (ledThreshold[channel] & 0x00003fff);
        [self writeAndCheckLong:theValue
                  addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kLedThreshold chan:channel]
                           mask:0x00ffffff
                      reportKey:[NSString stringWithFormat:@"LedThreshold_%d",channel]
                  forceFullInit:forceFullInit[channel]];
    }
}

//-------------------------kRawDataLength Reg----------------------------------------
- (unsigned long) readRawDataLength:(unsigned short)channel
{
    if(channel<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kRawDataLength chan:channel]];
    }
    else return 0;
}

- (void) writeRawDataLength:(unsigned short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel < kNumGretina4AChannels){
        unsigned long theValue = (rawDataLength & 0x000003ff);
        [self writeAndCheckLong:theValue
                  addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kRawDataLength chan:channel]
                           mask:0x000003ff
                      reportKey:[NSString stringWithFormat:@"RawDataLength_%d",channel]
                  forceFullInit:forceFullInit[channel]];
    }
}

//-------------------------kRawDataWindow Reg----------------------------------------
- (unsigned long) readRawDataWindow:(unsigned short)channel
{
    if(channel<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kRawDataWindow chan:channel]];
    }
    else return 0;
}

- (void) writeRawDataWindow:(unsigned short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel < kNumGretina4AChannels){
        unsigned long theValue = (rawDataWindow & 0x000003ff);
        [self writeAndCheckLong:theValue
                  addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kRawDataWindow chan:channel]
                           mask:0x000003ff
                      reportKey:[NSString stringWithFormat:@"RawDataWindow_%d",channel]
                  forceFullInit:forceFullInit[channel]];
    }
}


//-------------------------kDWindow Reg----------------------------------------
- (unsigned long) readDWindow:(unsigned short)channel
{
    if(channel<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kDWindow chan:channel]];
    }
    else return 0;
}

- (void) writeDWindow:(unsigned short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel < kNumGretina4AChannels){
        unsigned long theValue = (dWindow[0] & 0x0000007F);
        [self writeAndCheckLong:theValue
                  addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kDWindow chan:channel]
                           mask:0x0000007F
                      reportKey:[NSString stringWithFormat:@"DWindow_%d",channel]
                  forceFullInit:forceFullInit[channel]];
    }
}

//-------------------------kKWindow Reg----------------------------------------
- (unsigned long) readKWindow:(unsigned short)channel
{
    if(channel < kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kKWindow chan:channel]];
    }
    else return 0;
}

- (void) writeKWindow:(unsigned short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel < kNumGretina4AChannels){
        unsigned long theValue = (kWindow[0] & 0x0000007F);
        [self writeAndCheckLong:theValue
                  addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kKWindow chan:channel]
                           mask:0x0000007F
                      reportKey:[NSString stringWithFormat:@"KWindow_%d",channel]
                  forceFullInit:forceFullInit[channel]];
    }
}
//-------------------------kMWindow Reg----------------------------------------
- (unsigned long) readMWindow:(unsigned short)channel
{
    if(channel < kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kMWindow chan:channel]];
    }
    else return 0;
}

- (void) writeMWindow:(unsigned short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel < kNumGretina4AChannels){
        unsigned long theValue = (mWindow[0] & 0x0000007F);
        [self writeAndCheckLong:theValue
                  addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kMWindow chan:channel]
                           mask:0x0000007F
                      reportKey:[NSString stringWithFormat:@"MWindow_%d",channel]
                  forceFullInit:forceFullInit[channel]];
    }
}


//-------------------------kD3Window Reg----------------------------------------
- (unsigned long)readD3Window:(unsigned short)channel
{
    if(channel<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kD3Window chan:channel]];
    }
    else return 0;
}

- (void) writeD3Window:(unsigned short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel < kNumGretina4AChannels){
        unsigned long theValue = (d3Window[0] & 0x0000007F);
        [self writeAndCheckLong:theValue
                  addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kD3Window chan:channel]
                           mask:0x0000007F
                      reportKey:[NSString stringWithFormat:@"D3Window_%d",channel]
                  forceFullInit:forceFullInit[channel]];
    }
}

//-------------------------kDiscWidth Reg----------------------------------------
- (unsigned long) readDiscWidth:(unsigned short)channel
{
    if(channel<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kDiscWidth chan:channel]];
    }
    else return 0;
}
- (void) writeDiscWidth:(unsigned short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel < kNumGretina4AChannels){
        unsigned long theValue = (discWidth[0] & 0x0000003F);
        [self writeAndCheckLong:theValue
                  addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kDiscWidth chan:channel]
                           mask:0x0000003F
                      reportKey:[NSString stringWithFormat:@"DiscWidth%d",channel]
                  forceFullInit:forceFullInit[channel]];
    }
}
//-------------------------kBaselineStart Reg----------------------------------------
- (unsigned long) readBaselineStart:(unsigned short)channel
{
    if(channel<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kBaselineStart chan:channel]];
    }
    else return 0;
}

- (void) writeBaselineStart:(unsigned short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel < kNumGretina4AChannels){
        unsigned long theValue = (baselineStart[0] & 0x00003FFF);
        [self writeAndCheckLong:theValue
                  addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kBaselineStart chan:channel]
                           mask:0x00003FFF
                      reportKey:[NSString stringWithFormat:@"BaselineStart%d",channel]
                  forceFullInit:forceFullInit[channel]];
    }
}

//-------------------------kBaselineStart Reg----------------------------------------
- (unsigned long) readP1Window:(unsigned short)channel
{
    if(channel<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kP1Window chan:channel]];
    }
    else return 0;
}

- (void) writeP1Window:(unsigned short)channel
{
    //***NOTE that we only write the first value of the array to all channels
    if(channel < kNumGretina4AChannels){
        unsigned long theValue = (p1Window[0] & 0x0000000F);
        [self writeAndCheckLong:theValue
                  addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kP1Window chan:channel]
                           mask:0x0000000F
                      reportKey:[NSString stringWithFormat:@"P1Window_%d",channel]
                  forceFullInit:forceFullInit[channel]];
    }
    
}

//-------------------------kP2Window Reg----------------------------------------
- (unsigned long) readP2Window:(unsigned short)channel
{
    if(channel<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kP2Window chan:channel]];
    }
    else return 0;
}

- (void) writeP2Window
{
    unsigned long theValue = (p2Window & 0x0000003ff);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kP2Window]
                       mask:0x0000003ff
                  reportKey:@"P2Window"
              forceFullInit:forceFullCardInit];
}

//-------------------------kChannelPulsedControl Reg----------------------------------------
- (unsigned long) readChannelPulsedControl:(unsigned short)channel
{
    if(channel<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kChannelPulsedControl chan:channel]];
    }
    else return 0;
}

- (void) writeChannelPulsedControl
{
    [self writeAndCheckLong:channelPulsedControl
              addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kChannelPulsedControl]
                       mask:0x000037F7
                  reportKey:@"ChannelPulsedControl"
              forceFullInit:forceFullCardInit];
}

- (void) loadWindowDelays
{
    unsigned long theValue = [self readLongFromOffset:kChannelPulsedControl];
    theValue = theValue | 0x5;
    [self writeLong:theValue toOffset:kChannelPulsedControl];
    theValue = theValue & ~(0x5);
    [self writeAndCheckLong:theValue & 0x5
              addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kChannelPulsedControl]
                       mask:0x5
                  reportKey:@"PulsedControl"
              forceFullInit:forceFullCardInit];
}

//-------------------------kBaselineDelay Reg----------------------------------------
- (unsigned long) readBaselineDelay
{
    return [self readLongFromReg:kBaselineDelay];
}

- (void) writeBaselineDelay
{
    unsigned long theValue = (baselineStart[0] & 0x00003fff);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kBaselineDelay]
                       mask:0x00003fff
                  reportKey:@"BaselineDelay"
              forceFullInit:forceFullCardInit];
}

//-------------------------kHoldoffControl Reg----------------------------------------
- (unsigned long) readHoldoffControl
{
    return [self readLongFromReg:kHoldoffControl];
}

- (void) writeHoldoffControl
{
    unsigned long theValue = ((holdoffTime     & 0x1FF) << 0) |
    ((peakSensitivity & 0x07) << 9) |
    ((autoMode        & 0x01) << 12);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kHoldoffControl]
                       mask:0x00001FFF
                  reportKey:@"holdoffControl"
              forceFullInit:forceFullCardInit];
}

//-------------------------Timestamp Regs----------------------------------------
- (unsigned long long) readTimeStamp
{
    unsigned long      ts1 =  [self readLongFromReg:kLiveTimestampLsb];
    unsigned long long ts2 =  [self readLongFromReg:kLiveTimestampMsb];
    return (ts2<<32) | ts1;
}

//-------------------------kVetoGateWidth Reg----------------------------------------
- (unsigned long) readVetoGateWidth
{
    return [self readLongFromReg:kVetoGateWidth] & 0x00003fff;
}

- (void) writeVetoGateWidth
{
    [self writeAndCheckLong:(vetoGateWidth & 0x00003fff)
              addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kVetoGateWidth]
                       mask:0x00003fff
                  reportKey:@"BaselineDelay"
              forceFullInit:forceFullCardInit];
}

//-------------------------kMasterLogicStatus Reg----------------------------------------
- (void) writeMasterLogic:(BOOL)enable
{
    unsigned long oldValue = [self readLongFromOffset:kMasterLogicStatus];
    [self writeAndCheckLong:oldValue | enable
              addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kMasterLogicStatus]
                       mask:0x00000001 //mask off the reserved bits
                  reportKey:@"masterLogic"
              forceFullInit:YES];
}

//-------------------------kTriggerConfig Reg----------------------------------------
- (unsigned long) readTriggerConfig
{
    return [self readLongFromReg:kTriggerConfig];
}

- (void) writeTriggerConfig
{
    unsigned long theValue = (triggerConfig & 0x00000003);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetForRegisterIndex:kTriggerConfig]
                       mask:0x00000003
                  reportKey:@"TriggerConfig"
              forceFullInit:forceFullCardInit];
}

//-------------------------kCodeRevision Reg----------------------------------------
- (void) readCodeRevision
{
    unsigned long codeVersion = [self readLongFromReg:kCodeRevision];
    NSLog(@"Gretina4A %d code revisions:\n",[self slot]);
    NSLog(@"PCB : 0x%X \n",         (codeVersion >> 12) & 0xf);
    NSLog(@"FW Type: 0x%X \n",      (codeVersion >> 8)& 0xf);
    NSLog(@"Code: %02d.%02d \n",    ((codeVersion>>  4) & 0xf),(codeVersion&0xf));
}

//------------------------kDroppedEventCount Reg----------------------------------------
- (unsigned long) readDroppedEventCount:(unsigned short) aChan
{
    if(aChan<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kDroppedEventCount chan:aChan]];
    }
    else return 0;
}

//------------------------kAcceptedEventCount Reg----------------------------------------
- (unsigned long) readAcceptedEventCount:(unsigned short) aChan
{
    if(aChan<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kAcceptedEventCount chan:aChan]];
    }
    else return 0;
}
//------------------------kAhitCount Reg----------------------------------------
- (unsigned long) readAHitCount:(unsigned short) aChan
{
    if(aChan<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kAhitCount chan:aChan]];
    }
    else return 0;
}
//------------------------kDiscCount Reg----------------------------------------
- (unsigned long) readDiscCount:(unsigned short) aChan
{
    if(aChan<kNumGretina4AChannels){
        return [self readLongFromOffset:[Gretina4ARegisters offsetForRegisterIndex:kDiscCount chan:aChan]];
    }
    else return 0;
}

//-------------------------kVMEFPGAVersionStatus Reg----------------------------------------
- (void) readFPGAVersions
{
    //find out the VME FPGA version
    unsigned long vmeVersion = [self readLongFromReg:kVMEFPGAVersionStatus];
    NSLog(@"Gretina4A %d FPGA version:\n",[self slot]);
    NSLog(@"VME FPGA serial number: 0x%X \n",  ((vmeVersion >> 0) & 0xFFFF));
    NSLog(@"BOARD Revision number: 0x%X \n",   ((vmeVersion >>16) & 0xFF));
    NSLog(@"VME FPGA Version number: 0x%X \n", ((vmeVersion >>24) & 0xFF));
}

//-------------------------kVMEGPControl Reg----------------------------------------
- (short) readClockSource
{
    return [self readLongFromReg:kVMEGPControl] & 0x3;
}

//-------------------------kAuxStatus Reg----------------------------------------
- (unsigned long) readVmeAuxStatus
{
    return [self readLongFromReg:kAuxStatus];
}

- (void) resetBoard
{
    /* First disable all channels. This does not affect the model state,
     just the board state. */
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [self writeControlReg:i enabled:NO];
    }
    
    [self resetFIFO];
    [self resetMainFPGA];
    [ORTimer delay:6];  // 6 second delay during board reset
}

- (void) resetMainFPGA
{
    unsigned long theValue = 0x10;
    [[self adapter] writeLongBlock:&theValue
                         atAddress: [Gretina4AFPGARegisters address:[self baseAddress] forRegisterIndex:kMainFPGAControl]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    sleep(1);
    
    theValue = 0x00;
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[Gretina4AFPGARegisters address:[self baseAddress] forRegisterIndex:kMainFPGAControl]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


//==================================================
//initialization
- (void) initBoard
{
    [self clearCounters];
    [self writeMasterLogic:NO]; //disable
    int i;
    for(i=0;i<kNumGretina4AChannels;i++) {
        [self writeControlReg:i enabled:NO];
    }
    [self resetFIFO];
    //write the channel level params
    for(i=0;i<kNumGretina4AChannels;i++) {
        [self writeKWindow:i];          //only [0] is used
        [self writeMWindow:i];          //only [0] is used
        [self writeDWindow:i];          //only [0] is used
        [self writeD3Window:i];         //only [0] is used
        [self writeLedThreshold:i];
        
        [self writeRawDataLength:i];    //only [0] is used
        [self writeRawDataWindow:i];    //only [0] is used
        [self writeP1Window:i];         //only [0] is used
        [self writeDiscWidth:i];        //only [0] is used
        [self writeBaselineStart:i];    //only [0] is used
    }
    
    //write the card level params
    [self writeHoldoffControl];
    [self writeTriggerConfig];
    [self writeP2Window];
    [self writeBaselineDelay];
    [self writeWindowCompMin];
    [self writeWindowCompMax];
    [self writeVetoGateWidth];
    
    [self loadWindowDelays];
    
    [self writeMasterLogic:YES];
   
    //enable channels
    for(i=0;i<kNumGretina4AChannels;i++) {
        [self writeControlReg:i enabled:YES];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ACardInited object:self];
}




//=========================================================================
#pragma mark - Clock Sync
- (short) initState {return initializationState;}
- (void) setInitState:(short)aState
{
    initializationState = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AModelInitStateChanged object:self];
}

- (void) stepSerDesInit
{
    int i;
    switch(initializationState){
        case kSerDesSetup:
            [self writeRegister:kMasterLogicStatus  withValue: 0x00000051]; //power up value
            [self writeRegister:kSdConfig           withValue: 0x00001231]; //T/R SerDes off, reset clock manager, reset clocks
            [self setInitState:kSerDesIdle];
            break;
            
        case kSetDigitizerClkSrc:
            [[self undoManager] disableUndoRegistration];
            //[self setClockSource:0];                                //set to external clock (gui only!!!)
            [[self undoManager] enableUndoRegistration];
            [self writeFPGARegister:kVMEGPControl   withValue:0x00 ]; //set to external clock (in HW)
            [self setInitState:kFlushFifo];
            
            break;
            
        case kFlushFifo:
            for(i=0;i<kNumGretina4AChannels;i++){
                [self writeControlReg:i enabled:NO];
            }
            
            [self resetFIFO];
            [self setInitState:kReleaseClkManager];
            break;
            
        case kReleaseClkManager:
            //SERDES still disabled, release clk manager, clocks still held at reset
            [self writeRegister:kSdConfig           withValue: 0x00000211];
            [self setInitState:kPowerUpRTPower];
            break;
            
        case kPowerUpRTPower:
            //SERDES enabled, clocks still held at reset
            [self writeRegister:kSdConfig           withValue: 0x00000200];
            [self setInitState:kSetMasterLogic];
            break;
            
        case kSetMasterLogic:
            [self writeRegister:kMasterLogicStatus  withValue: 0x00000051]; //power up value
            [self setInitState:kSetSDSyncBit];
            break;
            
        case kSetSDSyncBit:
            [self writeRegister:kSdConfig           withValue: 0x00000000]; //release the clocks
            [self writeRegister:kSdConfig           withValue: 0x00000020]; //set sd syn
            
            [self setInitState:kSerDesIdle];
            break;
            
        case kSerDesError:
            break;
    }
    if(initializationState!= kSerDesError && initializationState!= kSerDesIdle){
        [self performSelector:@selector(stepSerDesInit) withObject:nil afterDelay:.01];
    }
}

- (BOOL) isLocked
{
    BOOL lockedBitSet   = ([self readRegister:kMasterLogicStatus] & kSDLockBit)==kSDLockBit;
    //BOOL lostLockBitSet = ([self readRegister:kSDLostLockBit] & kSDLostLockBit)==kSDLostLockBit;
    [self setLocked: lockedBitSet]; //& !lostLockBitSet];
    return [self locked];
}

- (BOOL) locked
{
    return locked;
}

- (void) setLocked:(BOOL)aState
{
    locked = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ALockChanged object: self];
}

- (NSString*) serDesStateName
{
    switch(initializationState){
        case kSerDesIdle:           return @"Idle";
        case kSerDesSetup:          return @"Reset to power up state";
        case kSetDigitizerClkSrc:   return @"Set the Clk Source";
        case kFlushFifo:            return @"Flush FIFO";
            
        case kPowerUpRTPower:       return @"Power up T/R Power";
        case kSetMasterLogic:       return @"Write Master Logic = 0x20051";
        case kSetSDSyncBit:         return @"Write SD Sync Bit";
        case kSerDesError:          return @"Error";
        default:                    return @"?";
    }
}


//==============================================================


#pragma mark - Data Taker
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
                                 @"ORGretina4AWaveformDecoder",           @"decoder",
                                 [NSNumber numberWithLong:dataId],        @"dataId",
                                 [NSNumber numberWithBool:YES],           @"variable",
                                 [NSNumber numberWithLong:-1],			  @"length",
                                 nil];
    [dataDictionary setObject:aDictionary forKey:@"Gretina4A"];
    
    return dataDictionary;
}

#pragma mark - HW Wizard
-(BOOL) hasParmetersToRamp
{
    return YES;
}

- (int) numberOfChannels
{
    return kNumGretina4AChannels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setOncePerCard:YES];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEnabled:withValue:) getMethod:@selector(enabled:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pile Up Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setPileupMode:withValue:) getMethod:@selector(pileupMode:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"PreampResetDelay Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setPreampResetDelayEn:withValue:) getMethod:@selector(preampResetDelayEn:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Dropped Event Count Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setDroppedEventCountMode:withValue:) getMethod:@selector(droppedEventCountMode:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Event Count Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEventCountMode:withValue:) getMethod:@selector(eventCountMode:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"LED Threshold"];
    [p setFormat:@"##0" upperLimit:0x1ffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setLedThreshold:withValue:) getMethod:@selector(ledThreshold:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Force Full Init"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setForceFullInit:withValue:) getMethod:@selector(forceFullInit:)];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel  name:@"Crate"   className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel     name:@"Card"    className:@"ORGretina4AModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel    name:@"Channel" className:@"ORGretina4AModel"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
    NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    
    id obj = [cardDictionary objectForKey:param];
    if(obj)return obj;
    else return [[cardDictionary objectForKey:param] objectAtIndex:aChannel];
}


- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    if(![self checkFirmwareVersion]){
        [NSException raise:@"Wrong Firmware" format:@"You must have firmware version 0x%x installed.",kCurrentFirmwareVersion];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORGretina4A"];
    
    
    if(serialNumber==0){
        @try {
            [[self adapter] readLongBlock:&serialNumber
                                atAddress:[Gretina4AFPGARegisters address:[self baseAddress] forRegisterIndex:kVMEFPGAVersionStatus]
                                numToRead:1
                               withAddMod:[self addressModifier]
                            usingAddSpace:0x01];
            
            serialNumber = serialNumber&0xffff;
        }
        @catch(NSException* e) {
        }
    }
    
    
    //cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16) | serialNumber;
    theController   = [self adapter];
    fifoAddress     = [self baseAddress] + 0x1000;
    fifoStateAddress= [self baseAddress] + [Gretina4ARegisters offsetForRegisterIndex:kProgrammingDone];
    
    fifoResetCount = 0;
    [self startRates];
    
    [self clearDiagnosticsReport];
    
    [self initBoard];
    
    if([self diagnosticsEnabled])[self briefDiagnosticsReport];
    
    [self performSelector:@selector(checkFifoAlarm) withObject:nil afterDelay:1];
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    isRunning = YES;
    NSString* errorLocation = @"";
    @try {
        if(![self fifoIsEmpty]){
            short orcaHeaderLen      = 2;
            short extraLenghtOfData  = 2;
            unsigned long dataLength = [self rawDataWindow]/2;
            dataBuffer[0] = dataId | (dataLength + extraLenghtOfData + orcaHeaderLen); //length + 2 longs + orca header
            dataBuffer[1] = location;
            
            [theController readLong:&dataBuffer[2]
                          atAddress:fifoAddress
                        timesToRead:dataLength+extraLenghtOfData //actual length is 4 shorts longer then the register
                         withAddMod:[self addressModifier]
                      usingAddSpace:0x01];
            
          //  NSLog(@"dropped: %lu  accepted: %lu  ahit: %lu  disc: %lu\n",[self readDroppedEventCount:0],[self readAcceptedEventCount:0],[self readAHitCount:0],[self readDiscCount:0]);
            //the first word of the actual data record had better be the packet separator
            if(dataBuffer[2]==kGretina4APacketSeparator){
                short chan = dataBuffer[3] & 0xf;
                if(chan < 10){
                    ++waveFormCount[dataBuffer[3] & 0x7];  //grab the channel and inc the count
                    [aDataPacket addLongsToFrameBuffer:dataBuffer length:dataLength + extraLenghtOfData + orcaHeaderLen];
//                    int n = (dataLength + extraLenghtOfData + orcaHeaderLen);
//                    for(int i=0;i<n;i++){
//                        NSLog(@"%3d: 0x%08x\n",i,dataBuffer[i]);
//                    }
                }
                else {
                    NSLogError(@"",@"Bad header--record discarded",@"GRETINA4M",[NSString stringWithFormat:@"slot %d",[self slot]], [NSString stringWithFormat:@"chan %d",1],nil);
                }
            }
            else {
                //oops... the buffer read is out of sequence
                NSLogError(@"",@"Packet Sequence Error -- FIFO reset",@"GRETINA4M",[NSString stringWithFormat:@"slot %d",[self slot]],nil);
                fifoResetCount++;
                [self resetFIFO];
            }
        }
    }
    @catch(NSException* localException) {
        NSLogError(@"",@"Gretina4A Card Error",errorLocation,nil);
        [self incExceptionCount];
        [localException raise];
    }
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    @try {
        int i;
        for(i=0;i<kNumGretina4AChannels;i++){
            [self writeControlReg:i enabled:NO];
        }
    }
    @catch(NSException* e){
        [self incExceptionCount];
        NSLogError(@"",@"Gretina4A Card Error",nil);
    }
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    isRunning = NO;
    [waveFormRateGroup stop];
    //stop all channels
    short i;
    for(i=0;i<kNumGretina4AChannels;i++){
        waveFormCount[i] = 0;
    }
    
    //disable all channels
    for(i=0;i<kNumGretina4AChannels;i++){
        [self writeControlReg:i enabled:NO];
    }
    
    [self writeMasterLogic:NO];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkFifoAlarm) object:nil];
}

- (void) checkFifoAlarm
{
    if(((fifoState & kGretina4AFIFOAlmostFull) != 0) && isRunning){
        fifoEmptyCount = 0;
        if(!fifoFullAlarm){
            NSString* alarmName = [NSString stringWithFormat:@"FIFO Almost Full Gretina4A (slot %d)",[self slot]];
            fifoFullAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kDataFlowAlarm];
            [fifoFullAlarm setSticky:YES];
            [fifoFullAlarm setHelpString:@"The rate is too high. Adjust the LED Threshold accordingly."];
            [fifoFullAlarm postAlarm];
        }
    }
    else {
        fifoEmptyCount++;
        if(fifoEmptyCount>=5){
            [fifoFullAlarm clearAlarm];
            [fifoFullAlarm release];
            fifoFullAlarm = nil;
        }
    }
    if(isRunning){
        [self performSelector:@selector(checkFifoAlarm) withObject:nil afterDelay:1.5];
    }
    else {
        [fifoFullAlarm clearAlarm];
        [fifoFullAlarm release];
        fifoFullAlarm = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFIFOCheckChanged object:self];
}

- (void) reset { ; }

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        waveFormCount[i]=0;
    }
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(isRunning)return NO;
    ++waveFormCount[channel];
    return YES;
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
    
    /* The current hardware specific data is:               *
     *                                                      *
     * 0: FIFO state address                                *
     * 1: FIFO empty state mask                             *
     * 2: FIFO address                                      *
     * 3: FIFO address AM                                   *
     * 4: FIFO size                                         */
    
    configStruct->total_cards++;
    configStruct->card_info[index].hw_type_id				= kGretina4A; //should be unique
    configStruct->card_info[index].hw_mask[0]				= dataId; //better be unique
    configStruct->card_info[index].slot						= [self slot];
    configStruct->card_info[index].crate					= [self crateNumber];
    configStruct->card_info[index].add_mod					= [self addressModifier];
    configStruct->card_info[index].base_add					= [self baseAddress];
    configStruct->card_info[index].deviceSpecificData[0]	= [self baseAddress] + [Gretina4ARegisters offsetForRegisterIndex:kProgrammingDone]; //fifoStateAddress
    configStruct->card_info[index].deviceSpecificData[1]	= [self baseAddress] + 0x1000; // fifoAddress
    configStruct->card_info[index].deviceSpecificData[2]	= 0x0B; // fifoAM
    configStruct->card_info[index].deviceSpecificData[3]	= [self baseAddress] + 0x04; // fifoReset Address
    configStruct->card_info[index].deviceSpecificData[4]	= [self rawDataWindow]+2;
    configStruct->card_info[index].num_Trigger_Indexes		= 0;
    
    configStruct->card_info[index].next_Card_Index 	= index+1;
    
    return index+1;
}

#pragma mark - Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setForceFullCardInit:         [decoder decodeBoolForKey:   @"forceFullCardInit"]];
    [self setSpiConnector:              [decoder decodeObjectForKey:@"spiConnector"]];
    [self setLinkConnector:             [decoder decodeObjectForKey:@"linkConnector"]];
    [self setRegisterIndex:				[decoder decodeIntForKey:   @"registerIndex"]];
    [self setSelectedChannel:           [decoder decodeIntForKey:   @"selectedChannel"]];
    [self setRegisterWriteValue:		[decoder decodeInt32ForKey: @"registerWriteValue"]];
    [self setSPIWriteValue:     		[decoder decodeInt32ForKey: @"spiWriteValue"]];
    [self setFpgaFilePath:				[decoder decodeObjectForKey:@"fpgaFilePath"]];
//    [self setWriteFlag:                 [decoder decodeBoolForKey:  @"writeFlag"]];
    [self setExtDiscriminatorSrc:       [decoder decodeInt32ForKey: @"extDiscriminatorSrc"]];
    [self setUserPackageData:           [decoder decodeInt32ForKey: @"userPackageData"]];
    [self setWindowCompMin:             [decoder decodeIntForKey:   @"windowCompMin"]];
    [self setWindowCompMax:             [decoder decodeIntForKey:   @"windowCompMax"]];
    [self setP2Window:                  [decoder decodeInt32ForKey: @"p2Window"]];
    [self setDacChannelSelect:          [decoder decodeIntForKey:   @"dacChannelSelect"]];
    [self setDacAttenuation:            [decoder decodeIntForKey:   @"dacAttenuation"]];
    [self setChannelPulsedControl:      [decoder decodeInt32ForKey: @"channelPulsedControl"]];
    [self setDiagMuxControl:            [decoder decodeInt32ForKey: @"diagMuxControl"]];
    [self setHoldoffTime:               [decoder decodeIntForKey:   @"holdoffTime"]];
    [self setPeakSensitivity:           [decoder decodeIntForKey:   @"peakSensitivity"]];
    [self setAutoMode:                  [decoder decodeIntForKey:   @"autoMode"]];
    [self setTrackingSpeed:             [decoder decodeIntForKey:   @"trackingSpeed"]];
    [self setBaselineDelay:             [decoder decodeIntForKey:   @"baselineDelay"]];
    [self setDiagInput:                 [decoder decodeInt32ForKey: @"diagInput"]];
    [self setDiagChannelEventSel:       [decoder decodeInt32ForKey: @"diagChannelEventSel"]];
    [self setRj45SpareIoDir:            [decoder decodeBoolForKey:  @"rj45SpareIoDir"]];
    [self setRj45SpareIoMuxSel:         [decoder decodeInt32ForKey: @"rj45SpareIoMuxSel"]];
    [self setVetoGateWidth:             [decoder decodeInt32ForKey: @"vetoGateWidth"]];
    [self setTriggerConfig:             [decoder decodeIntForKey:   @"triggerConfig"]];
    [self setTSErrCntCtrl:              [decoder decodeInt32ForKey: @"tSErrCntCtrl"]];
    [self setClkSelect0:                [decoder decodeBoolForKey:  @"clkSelect0"]];
    [self setClkSelect1:                [decoder decodeBoolForKey:  @"clkSelect1"]];
    [self setAuxIoRead:                 [decoder decodeInt32ForKey: @"auxIoRead"]];
    [self setAuxIoWrite:                [decoder decodeInt32ForKey: @"auxIoWrite"]];
    [self setAuxIoConfig:               [decoder decodeInt32ForKey: @"auxIoConfig"]];
    [self setRawDataLength:             [decoder decodeIntForKey:   @"rawDataLength"]];
    [self setRawDataWindow:             [decoder decodeIntForKey:   @"rawDataWindow"]];
    
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [self setForceFullInit:i           withValue: [decoder decodeIntForKey:   [@"forceFullInit"          stringByAppendingFormat:@"%d",i]]];
        [self setPileupWaveformOnlyMode:i  withValue: [decoder decodeBoolForKey:  [@"pileupWaveformOnlyMode" stringByAppendingFormat:@"%d",i]]];
        [self setPileupExtensionMode:i     withValue: [decoder decodeBoolForKey:  [@"pileExtensionMode"      stringByAppendingFormat:@"%d",i]]];
        [self setEventExtensionMode:i      withValue: [decoder decodeIntForKey:   [@"eventExtensionMode"     stringByAppendingFormat:@"%d",i]]];
        [self setAHitCountMode:i           withValue: [decoder decodeBoolForKey:  [@"aHitCountMode"          stringByAppendingFormat:@"%d",i]]];
        [self setDiscCountMode:i           withValue: [decoder decodeBoolForKey:  [@"discCountMode"          stringByAppendingFormat:@"%d",i]]];
        [self setEventCountMode:i          withValue: [decoder decodeBoolForKey:  [@"eventCountMode"         stringByAppendingFormat:@"%d",i]]];
        [self setDroppedEventCountMode:i   withValue: [decoder decodeBoolForKey:  [@"droppedEventCountMode"  stringByAppendingFormat:@"%d",i]]];
        [self setDecimationFactor:i        withValue: [decoder decodeIntForKey:   [@"decimationFactor"       stringByAppendingFormat:@"%d",i]]];
        [self setTriggerPolarity:i         withValue: [decoder decodeInt32ForKey: [@"triggerPolarity"        stringByAppendingFormat:@"%d",i]]];
        [self setPreampResetDelayEn:i      withValue: [decoder decodeBoolForKey:  [@"preampResetDelayEn"     stringByAppendingFormat:@"%d",i]]];
        [self setPileupMode:i              withValue: [decoder decodeBoolForKey:  [@"pileupMode"             stringByAppendingFormat:@"%d",i]]];
        [self setEnabled:i                 withValue: [decoder decodeBoolForKey:  [@"enabled"                stringByAppendingFormat:@"%d",i]]];
        [self setDWindow:i                 withValue: [decoder decodeIntForKey:   [@"dWindow"                stringByAppendingFormat:@"%d",i]]];
        [self setKWindow:i                 withValue: [decoder decodeIntForKey:   [@"kWindow"                stringByAppendingFormat:@"%d",i]]];
        [self setMWindow:i                 withValue: [decoder decodeIntForKey:   [@"mWindow"                stringByAppendingFormat:@"%d",i]]];
        [self setD3Window:i                withValue: [decoder decodeIntForKey:   [@"d3Window"               stringByAppendingFormat:@"%d",i]]];
        [self setDiscWidth:i               withValue: [decoder decodeIntForKey:   [@"discWidth"              stringByAppendingFormat:@"%d",i]]];
        [self setBaselineStart:i           withValue: [decoder decodeIntForKey:   [@"baselineStart"          stringByAppendingFormat:@"%d",i]]];
        [self setP1Window:i                withValue: [decoder decodeIntForKey:   [@"p1Window"               stringByAppendingFormat:@"%d",i]]];
        [self setLedThreshold:i            withValue: [decoder decodeIntForKey:   [@"ledThreshold"           stringByAppendingFormat:@"%d",i]]];
        [self setPreampResetDelay:i        withValue: [decoder decodeIntForKey:   [@"preampResetDelay"       stringByAppendingFormat:@"%d",i]]];
        [self setOverflowFlagChan:i        withValue: [decoder decodeBoolForKey:  [@"overflowFlagChan"       stringByAppendingFormat:@"%d",i]]];
    }
    
    [self setWaveFormRateGroup:[decoder decodeObjectForKey:@"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumGretina4AChannels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
    
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeBool:forceFullCardInit           forKey:@"forceFullCardInit"];
    [encoder encodeObject:spiConnector				forKey:@"spiConnector"];
    [encoder encodeObject:linkConnector				forKey:@"linkConnector"];
    [encoder encodeInt:registerIndex				forKey:@"registerIndex"];
    [encoder encodeInt:selectedChannel              forKey:@"selectedChannel"];
    [encoder encodeInt32:registerWriteValue			forKey:@"registerWriteValue"];
    [encoder encodeInt32:spiWriteValue			    forKey:@"spiWriteValue"];
    [encoder encodeObject:fpgaFilePath				forKey:@"fpgaFilePath"];
    [encoder encodeInt32:extDiscriminatorSrc        forKey:@"extDiscriminatorSrc"];
//    [encoder encodeBool:writeFlag                   forKey:@"writeFlag"];
    [encoder encodeInt32:userPackageData            forKey:@"userPackageData"];
    [encoder encodeInt32:windowCompMin              forKey:@"windowCompMin"];
    [encoder encodeInt32:windowCompMax              forKey:@"windowCompMax"];
    [encoder encodeInt32:p2Window                   forKey:@"p2Window"];
    [encoder encodeInt:dacChannelSelect             forKey:@"dacChannelSelect"];
    [encoder encodeInt:dacAttenuation               forKey:@"dacAttenuation"];
    [encoder encodeInt32:channelPulsedControl       forKey:@"channelPulsedControl"];
    [encoder encodeInt32:diagMuxControl             forKey:@"diagMuxControl"];
    [encoder encodeInt:holdoffTime                  forKey:@"holdoffTime"];
    [encoder encodeInt:peakSensitivity              forKey:@"peakSensitivity"];
    [encoder encodeInt:autoMode                     forKey:@"autoMode"];
    [encoder encodeInt:trackingSpeed                forKey:@"trackingSpeed"];
    [encoder encodeInt:baselineDelay                forKey:@"baselineDelay"];
    [encoder encodeInt32:diagInput                  forKey:@"diagInput"];
    [encoder encodeInt32:diagChannelEventSel        forKey:@"diagChannelEventSel"];
    [encoder encodeInt32:rj45SpareIoMuxSel          forKey:@"rj45SpareIoMuxSel"];
    [encoder encodeBool:rj45SpareIoDir              forKey:@"rj45SpareIoDir"];
    [encoder encodeInt:vetoGateWidth                forKey:@"vetoGateWidth"];
    [encoder encodeInt:triggerConfig                forKey:@"triggerConfig"];
    [encoder encodeInt32:tSErrCntCtrl               forKey:@"tSErrCntCtrl"];
    [encoder encodeBool:clkSelect0                  forKey:@"clkSelect0"];
    [encoder encodeBool:clkSelect1                  forKey:@"clkSelect1"];
    [encoder encodeInt32:auxIoRead                  forKey:@"auxIoRead"];
    [encoder encodeInt32:auxIoWrite                 forKey:@"auxIoWrite"];
    [encoder encodeInt32:auxIoConfig                forKey:@"auxIoConfig"];
    [encoder encodeInt:rawDataLength                forKey:@"rawDataLength"];
    [encoder encodeInt:rawDataWindow                forKey:@"rawDataWindow"];
    
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [encoder encodeInt:forceFullInit[i]           forKey:[@"forceFullInit"         stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:enabled[i]                forKey:[@"enabled"               stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:pileupMode[i]             forKey:[@"pileupMode"            stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:preampResetDelayEn[i]     forKey:[@"preampResetDelayEn"    stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:preampResetDelay[i]        forKey:[@"preampResetDelay"      stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:triggerPolarity[i]         forKey:[@"triggerPolarity"       stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:decimationFactor[i]        forKey:[@"decimationFactor"      stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:droppedEventCountMode[i]  forKey:[@"droppedEventCountMode" stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:eventCountMode[i]         forKey:[@"eventCountMode"        stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:aHitCountMode[i]          forKey:[@"aHitCountMode"         stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:discCountMode[i]          forKey:[@"discCountMode"         stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:eventExtensionMode[i]      forKey:[@"eventExtensionMode"    stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:pileupExtensionMode[i]    forKey:[@"pileExtensionMode"     stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:pileupWaveformOnlyMode[i] forKey:[@"pileupWaveformOnlyMode"stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:ledThreshold[i]            forKey:[@"ledThreshold"          stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:dWindow[i]                 forKey:[@"dWindow"               stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:kWindow[i]                 forKey:[@"kWindow"               stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:mWindow[i]                 forKey:[@"mWindow"               stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:discWidth[i]               forKey:[@"discWidth"             stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:d3Window[i]                forKey:[@"d3Window"              stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:baselineStart[i]           forKey:[@"baselineStart"         stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:p1Window[i]                forKey:[@"p1Window"              stringByAppendingFormat:@"%d",i]];
    }
    
    [encoder encodeObject:waveFormRateGroup			forKey:@"waveFormRateGroup"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithBool:forceFullCardInit]             forKey:@"forceFullCardInit"];
    [objDictionary setObject:[NSNumber numberWithInt:p2Window]                      forKey:@"p2Window"];
    
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:extDiscriminatorSrc]  forKey:@"extDiscriminatorSrc"];
//    [objDictionary setObject:[NSNumber numberWithBool:writeFlag]                    forKey:@"writeFlag"];
    [objDictionary setObject:[NSNumber numberWithInt:p2Window]                      forKey:@"p2Window"];
    [objDictionary setObject:[NSNumber numberWithInt:p2Window]                      forKey:@"p2Window"];
    [objDictionary setObject:[NSNumber numberWithInt:userPackageData]               forKey:@"userPackageData"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:windowCompMin]        forKey:@"windowCompMin"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:windowCompMax]        forKey:@"windowCompMax"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:p2Window]             forKey:@"p2Window"];
    [objDictionary setObject:[NSNumber numberWithInt:dacChannelSelect]              forKey:@"dacChannelSelect"];
    [objDictionary setObject:[NSNumber numberWithInt:dacAttenuation]                forKey:@"dacAttenuation"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:channelPulsedControl] forKey:@"channelPulsedControl"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:diagMuxControl]       forKey:@"diagMuxControl"];
    [objDictionary setObject:[NSNumber numberWithInt:holdoffTime]                   forKey:@"holdoffTime"];
    [objDictionary setObject:[NSNumber numberWithInt:peakSensitivity]               forKey:@"peakSensitivity"];
    [objDictionary setObject:[NSNumber numberWithInt:autoMode]                      forKey:@"autoMode"];
    [objDictionary setObject:[NSNumber numberWithInt:trackingSpeed]                 forKey:@"trackingSpeed"];
    [objDictionary setObject:[NSNumber numberWithInt:baselineDelay]                 forKey:@"baselineDelay"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:diagInput]            forKey:@"diagInput"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:diagChannelEventSel]  forKey:@"diagChannelEventSel"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:rj45SpareIoMuxSel]    forKey:@"rj45SpareIoMuxSel"];
    [objDictionary setObject:[NSNumber numberWithBool:rj45SpareIoDir]               forKey:@"rj45SpareIoDir"];
    [objDictionary setObject:[NSNumber numberWithInt:vetoGateWidth]                 forKey:@"vetoGateWidth"];
    [objDictionary setObject:[NSNumber numberWithInt:triggerConfig]                 forKey:@"triggerConfig"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:tSErrCntCtrl]         forKey:@"tSErrCntCtrl"];
    [objDictionary setObject:[NSNumber numberWithBool:clkSelect0]                   forKey:@"clkSelect0"];
    [objDictionary setObject:[NSNumber numberWithBool:clkSelect1]                   forKey:@"clkSelect1"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:auxIoRead]            forKey:@"auxIoRead"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:auxIoWrite]           forKey:@"auxIoWrite"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:auxIoConfig]          forKey:@"auxIoConfig"];
    [objDictionary setObject:[NSNumber numberWithInt:rawDataLength]                 forKey:@"rawDataLength"];
    [objDictionary setObject:[NSNumber numberWithInt:rawDataWindow]                 forKey:@"rawDataWindow"];
    
    [self addCurrentState:objDictionary boolArray:(BOOL*)forceFullInit              forKey:@"forceFullInit"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)enabled                    forKey:@"enabled"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)pileupMode                 forKey:@"pileupMode"];
    [self addCurrentState:objDictionary shortArray:(short*)preampResetDelayEn       forKey:@"preampResetDelayEn"];
    [self addCurrentState:objDictionary shortArray:(short*)preampResetDelay         forKey:@"preampResetDelay"];
    [self addCurrentState:objDictionary shortArray:(short*)triggerPolarity          forKey:@"pileupMode"];
    [self addCurrentState:objDictionary shortArray:(short*)decimationFactor         forKey:@"decimationFactor"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)droppedEventCountMode      forKey:@"droppedEventCountMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)eventCountMode             forKey:@"eventCountMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)aHitCountMode              forKey:@"aHitCountMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)discCountMode              forKey:@"discCountMode"];
    [self addCurrentState:objDictionary shortArray:(short*)eventExtensionMode       forKey:@"eventExtensionMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)pileupExtensionMode        forKey:@"pileExtensionMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)pileupWaveformOnlyMode     forKey:@"pileupWaveformOnlyMode"];
    [self addCurrentState:objDictionary shortArray:(short*)ledThreshold             forKey:@"ledThreshold"];
    [self addCurrentState:objDictionary shortArray:(short*)dWindow                  forKey:@"dWindow"];
    [self addCurrentState:objDictionary shortArray:(short*)kWindow                  forKey:@"kWindow"];
    [self addCurrentState:objDictionary shortArray:(short*)mWindow                  forKey:@"mWindow"];
    [self addCurrentState:objDictionary shortArray:(short*)discWidth                forKey:@"discWidth"];
    [self addCurrentState:objDictionary shortArray:(short*)d3Window                 forKey:@"d3Window"];
    [self addCurrentState:objDictionary shortArray:(short*)baselineStart            forKey:@"baselineStart"];
    [self addCurrentState:objDictionary shortArray:(short*)p1Window                 forKey:@"p1Window"];
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary shortArray:(short*)anArray forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [ar addObject:[NSNumber numberWithShort:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [ar addObject:[NSNumber numberWithBool:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

#pragma mark - AutoTesting
- (NSArray*) autoTests
{
    NSMutableArray* myTests = [NSMutableArray array];
    [myTests addObject:[ORVmeReadOnlyTest test:kBoardId wordSize:4 name:@"Board ID"]];
    return myTests;
}

#pragma mark - SPI Interface
- (unsigned long) writeAuxIOSPI:(unsigned long)spiData
{
    /*
     // Set AuxIO to mode 3 and set bits 0-3 to OUT (bit 0 is under FPGA control)
     [self writeRegister:kAuxIOConfig withValue:0x3025];
     // Read kAuxIOWrite to preserve bit 0, and zero bits used in SPI protocol
     unsigned long spiBase = [self readRegister:kAuxIOWrite] & ~(kSPIData | kSPIClock | kSPIChipSelect);
     unsigned long value;
     unsigned long readBack = 0;
     
     // set kSPIChipSelect to signify that we are starting
     [self writeRegister:kAuxIOWrite withValue:(kSPIChipSelect | kSPIClock | kSPIData)];
     // now write spiData starting from MSB on kSPIData, pulsing kSPIClock
     // each iteration
     int i;
     //NSLog(@"writing 0x%x\n", spiData);
     for(i=0; i<32; i++) {
     value = spiBase | kSPIChipSelect | kSPIData;
     if( (spiData & 0x80000000) != 0) value &= (~kSPIData);
     [self writeRegister:kAuxIOWrite withValue:value | kSPIClock];
     [self writeRegister:kAuxIOWrite withValue:value];
     readBack |= (([self readRegister:kAuxIORead] & kSPIRead) > 0) << (31-i);
     spiData = spiData << 1;
     }
     // unset kSPIChipSelect to signify that we are done
     [self writeRegister:kAuxIOWrite withValue:(kSPIClock | kSPIData)];
     //NSLog(@"readBack=%u (0x%x)\n", readBack, readBack);
     return readBack;
     */
    return 0;
}

#pragma mark - AdcProviding Protocol
- (BOOL)          onlineMaskBit:(int)bit                     { return [self enabled:bit];        }
- (BOOL)          partOfEvent:(unsigned short)aChannel       { return NO;                        }
- (unsigned long) waveFormCount:(short)aChannel              { return waveFormCount[aChannel];   }
- (unsigned long) eventCount:(int)aChannel                   { return waveFormCount[aChannel];   }
- (unsigned long) thresholdForDisplay:(unsigned short) aChan { return [self ledThreshold:aChan]; }
- (unsigned short)gainForDisplay:(unsigned short) aChan      { return 0; }

- (void) clearEventCounts
{
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        waveFormCount[i]=0;
    }
}

- (void) postAdcInfoProvidingValueChanged
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ORAdcInfoProvidingValueChanged
     object:self
     userInfo: nil];
}

@end

@implementation ORGretina4AModel (private)

- (void) updateDownLoadProgress
{
    //call only from main thread
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFpgaDownProgressChanged object:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:(self) selector:@selector(updateDownLoadProgress) object:nil];
    if(downLoadMainFPGAInProgress)[self performSelector:@selector(updateDownLoadProgress) withObject:nil afterDelay:.1];
}

- (void) setFpgaDownProgress:(short)aFpgaDownProgress
{
    [progressLock lock];
    fpgaDownProgress = aFpgaDownProgress;
    [progressLock unlock];
}

- (void) setProgressStateOnMainThread:(NSString*)aState
{
    if(!aState)aState = @"--";
    //this post a notification to the GUI so it must be done on the main thread
    [self performSelectorOnMainThread:@selector(setMainFPGADownLoadState:) withObject:aState waitUntilDone:NO];
}

- (void) fpgaDownLoadThread:(NSData*)dataFromFile
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    @try {
        [dataFromFile retain];
        
        [self setProgressStateOnMainThread:@"Block Erase"];
        if(!stopDownLoadingMainFPGA) [self blockEraseFlash];
        [self setProgressStateOnMainThread:@"Programming"];
        if(!stopDownLoadingMainFPGA) [self programFlashBuffer:dataFromFile];
        [self setProgressStateOnMainThread:@"Verifying"];
        
        if(!stopDownLoadingMainFPGA) {
            if (![self verifyFlashBuffer:dataFromFile]) {
                [NSException raise:@"Gretina4A Exception" format:@"Verification of flash failed."];
            }
            else {
                //reload the fpga from flash
                [self writeToAddress:0x900 aValue:kGretina4AResetMainFPGACmd];
                [self writeToAddress:0x900 aValue:kGretina4AReloadMainFPGACmd];
                [self setProgressStateOnMainThread:  @"Finishing$Flash Memory-->FPGA"];
                uint32_t statusRegValue = [self readFromAddress:0x904];
                while(!(statusRegValue & kGretina4AMainFPGAIsLoaded)) {
                    if(stopDownLoadingMainFPGA)return;
                    statusRegValue = [self readFromAddress:0x904];
                }
                NSLog(@"Gretina4(%d): FPGA Load Finished - No Errors\n",[self uniqueIdNumber]);
                
            }
        }
        [self setProgressStateOnMainThread:@"Loading FPGA"];
        if(!stopDownLoadingMainFPGA) [self reloadMainFPGAFromFlash];
        else NSLog(@"Gretina4(%d): FPGA Load Manually Stopped\n",[self uniqueIdNumber]);
        [self setProgressStateOnMainThread:@"--"];
    }
    @catch(NSException* localException) {
        [self setProgressStateOnMainThread:@"Exception"];
    }
    @finally {
        [self performSelectorOnMainThread:@selector(downloadingMainFPGADone) withObject:nil waitUntilDone:NO];
        [dataFromFile release];
    }
    [pool release];
}

- (void) blockEraseFlash
{
    /* We only erase the blocks currently used in the Gretina4A specification. */
    [self writeToAddress:0x910 aValue:kGretina4AFlashEnableWrite]; //Enable programming
    [self setFpgaDownProgress:0.];
    unsigned long count = 0;
    unsigned long end = (kGretina4AFlashBlocks / 4) * kGretina4AFlashBlockSize;
    unsigned long addr;
    [self setProgressStateOnMainThread:  @"Block Erase"];
    for (addr = 0; addr < end; addr += kGretina4AFlashBlockSize) {
        
        if(stopDownLoadingMainFPGA)return;
        @try {
            [self setFirmwareStatusString:       [NSString stringWithFormat:@"%lu of %d Blocks Erased",count,kGretina4AFlashBufferBytes]];
            [self setFpgaDownProgress: 100. * (count+1)/(float)kGretina4AUsedFlashBlocks];
            
            [self writeToAddress:0x980 aValue:addr];
            [self writeToAddress:0x98C aValue:kGretina4AFlashBlockEraseCmd];
            [self writeToAddress:0x98C aValue:kGretina4AFlashConfirmCmd];
            unsigned long stat = [self readFromAddress:0x904];
            while (stat & kFlashBusy) {
                if(stopDownLoadingMainFPGA)break;
                stat = [self readFromAddress:0x904];
            }
            count++;
        }
        @catch(NSException* localException) {
            NSLog(@"Gretina4A exception erasing flash.\n");
        }
    }
    
    [self setFpgaDownProgress: 100];
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
    [self setFpgaDownProgress: 0];
}

- (void) programFlashBuffer:(NSData*)theData
{
    unsigned long totalSize = [theData length];
    
    [self setProgressStateOnMainThread:@"Programming"];
    [self setFirmwareStatusString: [NSString stringWithFormat:@"FPGA File Size %lu KB",totalSize/1000]];
    [self setFpgaDownProgress:0.];
    
    [self writeToAddress:0x980 aValue:0x00];
    [self writeToAddress:0x98C aValue:kGretina4AFlashReadArrayCmd];
    
    unsigned long address = 0x0;
    while (address < totalSize ) {
        unsigned long numberBytesToWrite;
        if(totalSize-address >= kGretina4AFlashBufferBytes){
            numberBytesToWrite = kGretina4AFlashBufferBytes; //whole block
        }
        else {
            numberBytesToWrite = totalSize - address; //near eof, so partial block
        }
        
        [self programFlashBufferBlock:theData address:address numberBytes:numberBytesToWrite];
        
        address += numberBytesToWrite;
        if(stopDownLoadingMainFPGA)break;
        
        
        [self setFirmwareStatusString: [NSString stringWithFormat:@"Flashed: %lu/%lu KB",address/1000,totalSize/1000]];
        
        [self setFpgaDownProgress:100. * address/(float)totalSize];
        
        if(stopDownLoadingMainFPGA)break;
        
    }
    if(stopDownLoadingMainFPGA)return;
    
    [self writeToAddress:0x980 aValue:0x00];
    [self writeToAddress:0x98C aValue:kGretina4AFlashReadArrayCmd];
    [self writeToAddress:0x910 aValue:0x00];
    
    [self setProgressStateOnMainThread:@"Programming"];
}

- (void) programFlashBufferBlock:(NSData*)theData address:(unsigned long)anAddress numberBytes:(unsigned long)aNumber
{
    //issue the set-up command at the starting address
    [self writeToAddress:0x980 aValue:anAddress];
    [self writeToAddress:0x98C aValue:kGretina4AFlashWriteCmd];
    unsigned char* theDataBytes = (unsigned char*)[theData bytes];
    unsigned long statusRegValue;
    while(1) {
        if(stopDownLoadingMainFPGA)return;
        
        // Checking status to make sure that flash is ready
        unsigned long statusRegValue = [self readFromAddress:0x904];
        
        if ( (statusRegValue & kFlashBusy)  == kFlashBusy ) {
            //not ready, so re-issue the set-up command
            [self writeToAddress:0x980 aValue:anAddress];
            [self writeToAddress:0x98C aValue:kGretina4AFlashWriteCmd];
        }
        else break;
    }
    
    //Set the word count. Max is 0xF.
    unsigned long valueToWrite = (aNumber/2) - 1;
    [self writeToAddress:0x98C aValue:valueToWrite];
    
    // Loading all the words in
    /* Load the words into the bufferToWrite */
    unsigned long i;
    for ( i=0; i<aNumber; i+=4 ) {
        unsigned long* lPtr = (unsigned long*)&theDataBytes[anAddress+i];
        [self writeToAddress:0x984 aValue:lPtr[0]];
    }
    
    // Confirm the write
    [self writeToAddress:0x98C aValue:kGretina4AFlashConfirmCmd];
    
    //wait until the buffer is available again
    statusRegValue = [self readFromAddress:0x904];
    while(statusRegValue & kFlashBusy) {
        if(stopDownLoadingMainFPGA)break;
        statusRegValue = [self readFromAddress:0x904];
    }
}

- (BOOL) verifyFlashBuffer:(NSData*)theData
{
    unsigned long totalSize = [theData length];
    unsigned char* theDataBytes = (unsigned char*)[theData bytes];
    
    [self setProgressStateOnMainThread:@"Verifying"];
    [self setFirmwareStatusString: [NSString stringWithFormat:@"FPGA File Size %lu KB",totalSize/1000]];
    [self setFpgaDownProgress:0.];
    
    /* First reset to make sure it is read mode. */
    [self writeToAddress:0x980 aValue:0x0];
    [self writeToAddress:0x98C aValue:kGretina4AFlashReadArrayCmd];
    
    unsigned long errorCount =   0;
    unsigned long address    =   0;
    unsigned long valueToCompare;
    
    while ( address < totalSize ) {
        unsigned long valueToRead = [self readFromAddress:0x984];
        
        /* Now compare to file*/
        if ( address + 3 < totalSize) {
            unsigned long* ptr = (unsigned long*)&theDataBytes[address];
            valueToCompare = ptr[0];
        }
        else {
            //less than four bytes left
            unsigned long numBytes = totalSize - address - 1;
            valueToCompare = 0;
            unsigned long i;
            for ( i=0;i<numBytes;i++) {
                valueToCompare += (((unsigned long)theDataBytes[address]) << i*8) & (0xFF << i*8);
            }
        }
        if ( valueToRead != valueToCompare ) {
            [self setProgressStateOnMainThread:@"Error"];
            [self setFirmwareStatusString: @"Comparision Error"];
            [self setFpgaDownProgress:0.];
            errorCount++;
        }
        
        [self setFirmwareStatusString: [NSString stringWithFormat:@"Verified: %lu/%lu KB Errors: %lu",address/1000,totalSize/1000,errorCount]];
        [self setFpgaDownProgress:100. * address/(float)totalSize];
        
        address += 4;
    }
    if(errorCount==0){
        [self setProgressStateOnMainThread:@"Done"];
        [self setFirmwareStatusString: @"No Errors"];
        [self setFpgaDownProgress:0.];
        return YES;
    }
    else {
        [self setProgressStateOnMainThread:@"Errors"];
        [self setFirmwareStatusString: @"Comparision Errors"];
        
        return NO;
    }
}

- (void) reloadMainFPGAFromFlash
{
    
    [self writeToAddress:0x900 aValue:kGretina4AResetMainFPGACmd];
    [self writeToAddress:0x900 aValue:kGretina4AReloadMainFPGACmd];
    
    unsigned long statusRegValue=[self readFromAddress:0x904];
    
    while(!(statusRegValue & kGretina4AMainFPGAIsLoaded)) {
        if(stopDownLoadingMainFPGA)return;
        statusRegValue=[self readFromAddress:0x904];
    }
}

- (void) downloadingMainFPGADone
{
    [fpgaProgrammingThread release];
    fpgaProgrammingThread = nil;
    
    if(!stopDownLoadingMainFPGA) NSLog(@"Programming Complete.\n");
    else						 NSLog(@"Programming manually stopped before done\n");
    [self setDownLoadMainFPGAInProgress: NO];
    
}

- (void) copyFirmwareFileToSBC:(NSString*)firmwarePath
{
    if(!fileQueue){
        fileQueue = [[NSOperationQueue alloc] init];
        [fileQueue setMaxConcurrentOperationCount:1];
        [fileQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    }
    
    fpgaFileMover = [[ORFileMoverOp alloc] init];
    
    [fpgaFileMover setDelegate:self];
    
    [fpgaFileMover setMoveParams:[firmwarePath stringByExpandingTildeInPath]
                              to:kFPGARemotePath
                      remoteHost:[[[self adapter] sbcLink] IPNumber]
                        userName:[[[self adapter] sbcLink] userName]
                        passWord:[[[self adapter] sbcLink] passWord]];
    
    [fpgaFileMover setVerbose:YES];
    [fpgaFileMover doNotMoveFilesToSentFolder];
    [fpgaFileMover setTransferType:eOpUseSCP];
    [fileQueue addOperation:fpgaFileMover];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == fileQueue && [keyPath isEqual:@"operations"]) {
        if([fileQueue operationCount]==0){
        }
    }
}

- (BOOL) controllerIsSBC
{
    //long removeReturn;
    //return NO; //<<----- temp for testing
    if([[self adapter] isKindOfClass:NSClassFromString(@"ORVmecpuModel")])return YES;
    else return NO;
}

- (void) fileMoverIsDone
{
    BOOL transferOK;
    if ([[fpgaFileMover task] terminationStatus] == 0) {
        NSLog(@"Transferred FPGA Code: %@ to %@:%@\n",[fpgaFileMover fileName],[fpgaFileMover remoteHost],kFPGARemotePath);
        transferOK = YES;
    }
    else {
        NSLogColor([NSColor redColor], @"Failed to transfer FPGA Code to %@\n",[fpgaFileMover remoteHost]);
        transferOK = YES;
    }
    
    [fpgaFileMover release];
    fpgaFileMover  = nil;
    
    [self setDownLoadMainFPGAInProgress: NO];
    if(transferOK){
        //the FPGA file is now on the SBC, next step is to start the flash process on the SBC
        
        [self loadFPGAUsingSBC];
    }
}
- (void) loadFPGAUsingSBC
{
    if([self controllerIsSBC]){
        //if an SBC is available we pass the request to flash the fpga. this assumes the .bin file is already there
        SBC_Packet aPacket;
        aPacket.cmdHeader.destination           = kMJD;
        aPacket.cmdHeader.cmdID                 = kMJDFlashGretinaFPGA;
        aPacket.cmdHeader.numberBytesinPayload	= sizeof(MJDFlashGretinaFPGAStruct);
        
        MJDFlashGretinaFPGAStruct* p = (MJDFlashGretinaFPGAStruct*) aPacket.payload;
        p->baseAddress      = [self baseAddress];
        @try {
            NSLog(@"Gretina4A (%d) launching firmware load job in SBC\n",[self uniqueIdNumber]);
            
            [[[self adapter] sbcLink] send:&aPacket receive:&aPacket];
            
            [[[self adapter] sbcLink] monitorJobFor:self statusSelector:@selector(flashFpgaStatus:)];
            
        }
        @catch(NSException* e){
            
        }
    }
}
@end
