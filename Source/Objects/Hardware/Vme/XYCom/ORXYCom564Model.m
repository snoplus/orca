//-------------------------------------------------------------------------
//  ORXYCom564Model.h
//
//  Created by Michael G. Marino on 10/21/1011
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
#import "ORXYCom564Model.h"
#import "ORVmeCrateModel.h"

#pragma mark ***Notification Strings
NSString* ORXYCom564Lock					= @"ORXYCom564Lock";
NSString* ORXYCom564ReadoutModeChanged      = @"ORXYCom564ReadoutModeChanged";
NSString* ORXYCom564OperationModeChanged    = @"ORXYCom564OperationModeChanged";
NSString* ORXYCom564AutoscanModeChanged     = @"ORXYCom564AutoscanModeChanged";
NSString* ORXYCom564ChannelGainChanged      = @"ORXYCom564ChannelGainChanged";
NSString* ORXYCom564PollingStateChanged     = @"ORXYCom564PollingStateChanged";
NSString* ORXYCom564ADCValuesChanged        = @"ORXYCom564ADCValuesChanged";


@interface ORXYCom564Model (private)
- (void) _setChannelGains:(NSMutableArray*)gains;
- (void) _setUpPolling:(BOOL)verbose;
- (void) _stopPolling;
- (void) _startPolling;
- (void) _pollAllChannels;
- (void) _setChannelADCValues:(NSMutableArray*)vals;
@end

@implementation ORXYCom564Model

#pragma mark •••Static Declarations
typedef struct {
	unsigned long offset;
	NSString* name;
} XyCom564RegisterInformation;

#define kXVME564_SizeOfModuleIDData 0x14
#define kXVME564_NumAutoScanChannelsPerGroup 8


static XyCom564RegisterInformation mIOXY564Reg[kNumberOfXyCom564Registers] = {
    {0x01,  @"Module ID"},
    {0x81,  @"Status/Control"},     
    {0x101,  @"Interrupt Timer"},  
    {0x103,  @"Interrupt Vector"},      
    {0x111,  @"Autoscan Control"},         
    {0x180,  @"A/D Mode"},             
    {0x181,  @"A/D Status/Control"},
    {0x183,  @"End of Conversion Vector"},
    {0x184,  @"A/D Gain Channel High"},
    {0x185,  @"A/D Gain Channel Low"},    
    {0x200,  @"A/D Scan"}
};

#pragma mark ***Private
- (void) _setChannelGains:(NSMutableArray *)gains
{
    [gains retain];
    [channelGains release];
    channelGains = gains;    
    if (channelGains == nil) {
        int i;
        channelGains = [[NSMutableArray array] retain];
        for (i=0;i<[self getNumberOfChannels];i++) {
            [channelGains addObject:[NSNumber numberWithInt:kGainOne]];
        }
    }

    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom564ChannelGainChanged
	 object:self];    
    
}

- (void) _setChannelADCValues:(NSMutableArray *)vals
{
    [vals retain];
    [chanADCVals release];
    chanADCVals = vals;
    if (chanADCVals == nil) {
        chanADCVals = [[NSMutableArray array] retain];
        int i;
        for (i=0; i<[self getNumberOfChannels]; i++) {
            [chanADCVals addObject:[NSNumber numberWithInt:0]];
        }
    }
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom564ADCValuesChanged
	 object:self];    
    
}

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x29];
    [[self undoManager] enableUndoRegistration];
    [self _setChannelGains:nil];
    [self _setChannelADCValues:nil];    
    return self;
}

- (void) dealloc 
{
    [channelGains release];
    [chanADCVals release];    
	[self _stopPolling];    
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"XYCom564Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORXYCom564Controller"];
}
#pragma mark ***Accessors

- (void) setReadoutMode:(EXyCom564ReadoutMode) aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setReadoutMode:[self readoutMode]];
    switch (aMode) {
        case kA16:
            [self setAddressModifier:0x29];
            break;
        case kA24:
            [self setAddressModifier:0x39];
            break;            
        default:
            break;
    }    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom564ReadoutModeChanged
	 object:self];

}

- (void) setPollingState:(NSTimeInterval)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollingState:pollingState];
    
    pollingState = aState;
    
    if (pollingState != 0) {        
        [self performSelector:@selector(_startPolling) withObject:nil afterDelay:0.5];
    } else {
        [self performSelector:@selector(_stopPolling) withObject:nil afterDelay:0.5];
    }
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom564PollingStateChanged
	 object: self];
}

- (NSTimeInterval) pollingState
{
    return pollingState;
}

#pragma mark •••Hardware Access

- (void) initBoard
{
    [self resetBoard];
    [self programGains];
    [self programReadoutMode];
}

- (void) programReadoutMode
{
    uint8_t val = 0x0;
    if ([self operationMode] == kAutoscanning) {
        val = 0x80 + (uint8_t)[self autoscanMode];
        
    } 
    // Disables if we are not in autoscanning mode
    [self write:val atRegisterIndex:kAutoscanControl];
    
    // Write the mode to the card
    val = [self operationMode];
    [self write:val atRegisterIndex:kADMode];

}
- (void) programGains
{
    uint8_t oldMode = 0x0;
    uint8_t programMode = kProgramGain;    
    // read the old Mode
    [self read:&oldMode atRegisterIndex:kADMode];
    // set to programming mode
    [self write:programMode atRegisterIndex:kADMode];
    int i;
    for (i=0;i<[self getNumberOfChannels];i++) {
        programMode = (uint8_t)[[channelGains objectAtIndex:i] intValue];
        [self write:programMode atRegisterIndex:kGainChannelHigh];        
        [self write:(uint8_t)i atRegisterIndex:kGainChannelLow];
    }
    [self write:oldMode atRegisterIndex:kADMode];    
}

- (void) resetBoard
{
    uint8_t val = 0x11;
    // reset the LEDs
    [self write:val atRegisterIndex:kStatusControl];
    // Reset the IRQs
    val = 0x0;
    [self write:val atRegisterIndex:kInterruptTimer];    
    // reset the A/D
    val = 0x10;
    [self write:val atRegisterIndex:kADStatusControl];
    val = 0x00;
    [self write:val atRegisterIndex:kADStatusControl];
}

- (void) report
{
    NSString* output = @"";
    uint8_t val = 0x10;
    int i;
    for (i=0; i<kXVME564_SizeOfModuleIDData; i++) {
        [[self adapter] readByteBlock:&val 
                            atAddress:[self baseAddress] + mIOXY564Reg[kModuleID].offset + 2*i
                            numToRead:1 
                           withAddMod:[self addressModifier] 
                        usingAddSpace:0x01];
        output = [output stringByAppendingFormat:@"%c",(char)val];
        
    }
    NSLog(@"VME-564 Crate %i: Slot: %i\n",[self crate],[self slot]);
    NSLog(@"  Module ID: %@\n",output);
}

- (void) read:(uint8_t*) aval atRegisterIndex:(EXyCom564Registers)index 
{
    *aval = 0;
    [[self adapter] readByteBlock:aval 
                        atAddress:[self baseAddress] + mIOXY564Reg[index].offset 
                        numToRead:1 
                       withAddMod:[self addressModifier] 
                    usingAddSpace:0x01];
}

- (void) setGain:(EXyCom564ChannelGain) gain 
{
    
    [[[self undoManager] prepareWithInvocationTarget:self] 
      _setChannelGains:[NSMutableArray arrayWithArray:channelGains]];
    short i;
    for (i=0;i < [channelGains count];i++) {
        [channelGains replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:gain]];        
    }

    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom564ChannelGainChanged
	 object:self];    
    
}

- (void) setGain:(EXyCom564ChannelGain) gain channel:(unsigned short) aChannel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:[self getGain:aChannel] channel:aChannel];
    
    [channelGains replaceObjectAtIndex:aChannel withObject:[NSNumber numberWithInt:gain]];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom564ChannelGainChanged
	 object:self];    

}
    
- (EXyCom564ChannelGain) getGain:(unsigned short) aChannel;
{
    return [[channelGains objectAtIndex:aChannel] intValue];
}
    
    
- (void) write:(uint8_t) aval atRegisterIndex:(EXyCom564Registers)index;
{
    [[self adapter] writeByteBlock:&aval 
                        atAddress:[self baseAddress] + mIOXY564Reg[index].offset 
                        numToWrite:1 
                       withAddMod:[self addressModifier] 
                    usingAddSpace:0x01];
}

- (short) getNumberRegisters
{
	return kNumberOfXyCom564Registers;
}

- (short) getNumberOperationModes
{
	return kNumberOfOpModes;
}

- (short) getNumberAutoscanModes
{
	return kNumberOfAutoscanModes;
}

- (short) getNumberGainModes
{
	return kNumberOfGains;
}

- (NSString*) getRegisterName:(EXyCom564Registers) anIndex
{
    return mIOXY564Reg[anIndex].name;
}

- (unsigned long) getAddressOffset:(EXyCom564Registers) anIndex
{
    return mIOXY564Reg[anIndex].offset;
}

- (NSString*) getOperationModeName: (EXyCom564OperationMode) anIndex
{
    switch (anIndex) {
        case kSingleChannel:
            return @"Single Channel";
        case kSequentialChannel:
            return @"Sequential Channel";
        case kRandomChannel:
            return @"Random Channel";
        case kExternalTrigger:
            return @"External Trigger";
        case kAutoscanning:
            return @"Autoscanning";
        case kProgramGain:
            return @"Program Gains";
        default:
            return @"Error";
    }
}

- (NSString*) getAutoscanModeName:(EXyCom564AutoscanMode)aMode
{
    switch (aMode) {
        case k0to8:
            return @"Chan 0 -> 8";
        case k0to16:
            return @"Chan 0 -> 16";
        case k0to32:
            return @"Chan 0 -> 32";
        case k0to64:
            return @"Chan 0 -> 64";
        default:
            return @"Error";
    }
}

- (NSString*) getChannelGainName:(EXyCom564ChannelGain)aMode
{
    switch (aMode) {
        case kGainOne:
            return @"1x";
        case kGainTwo:
            return @"2x";
        case kGainFive:
            return @"5x";
        case kGainTen:
            return @"10x";
        default:
            return @"Error";
    }
}

- (uint16_t) getAdcValueAtChannel:(int)chan
{
    if (chan >= [chanADCVals count]) return 0;
    return [[chanADCVals objectAtIndex:chan] intValue];
}

- (EXyCom564ReadoutMode) readoutMode
{
    assert([self addressModifier] == 0x29 || [self addressModifier] == 0x39);
    if ([self addressModifier] == 0x29) return kA16;
    else return kA24;
}

- (EXyCom564OperationMode) 	operationMode
{
    return operationMode;
}

- (void) setOperationMode: (EXyCom564OperationMode) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOperationMode:[self operationMode]];
    
    operationMode = anIndex;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom564OperationModeChanged
	 object:self];
}

- (EXyCom564AutoscanMode) autoscanMode
{
    return autoscanMode;
}

- (void) setAutoscanMode: (EXyCom564AutoscanMode) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoscanMode:[self autoscanMode]];
    
    autoscanMode = anIndex;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom564AutoscanModeChanged
	 object:self];    
}
#pragma mark ***Readout

- (void) readAllAdcChannels
{
    if (operationMode != kAutoscanning) {
        NSLog(@"XVME not in autoscanning mode");   
        return;
    }
    int channelsToRead = kXVME564_NumAutoScanChannelsPerGroup << ([self autoscanMode]);
    uint16_t readOut[channelsToRead];
    [[self adapter] readWordBlock:readOut
                        atAddress:[self baseAddress] + mIOXY564Reg[kADScan].offset 
                        numToRead:channelsToRead 
                       withAddMod:[self addressModifier] 
                    usingAddSpace:0x01];
    int i;
    for (i=0; i<[chanADCVals count]; i++) {
        if (i>=channelsToRead) {
            [chanADCVals replaceObjectAtIndex:i withObject:[NSNumber numberWithShort:0]];
        } else {
            [chanADCVals replaceObjectAtIndex:i withObject:[NSNumber numberWithShort:readOut[i]]];            
        }
    }
    [self _setChannelADCValues:chanADCVals];
    
}

#pragma mark ***Card qualities
- (short) getNumberOfChannels
{
    return 64;
}

#pragma mark ***ORAdcProcessing protocol
- (void) startProcessCycle
{
	[self _stopPolling];
}
- (void) endProcessCycle
{
    
}

- (void)processIsStarting
{
	[self _stopPolling];
}

- (void)processIsStopping
{
	[self _startPolling];
}

- (BOOL) processValue:(int)channel
{
    return YES;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
    
}
- (NSString*) processingTitle
{
    return [NSString stringWithFormat:@"XVME-564,%d,%@",[self crateNumber],[self slot]];
}
- (double) convertedValue:(int)channel
{
    return (double) 0xFFFF;    
}
- (double) maxValueForChan:(int)channel
{
    return (double) 0xFFFF;
}
- (double) minValueForChan:(int)channel
{
    return 0.0;
}
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel
{
    
}

#pragma mark •••Polling
- (void) _stopPolling
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
	pollRunning = NO;
}

- (void) _startPolling
{
	[self _setUpPolling:YES];
}

- (void) _setUpPolling:(BOOL)verbose
{
	
	if(pollRunning && pollingState != 0)return;
	
    if(pollingState!=0){  
        if ([self operationMode] != kAutoscanning) {
            if(verbose) NSLog(@"XVME564,%d,%d, must be in autoscan mode to poll",[self crateNumber],[self slot]);
            return;
        }
		pollRunning = YES;
        if(verbose) NSLog(@"Polling XVME564,%d,%d  every %.0f seconds.\n",[self crateNumber],[self slot],pollingState);
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
        [self performSelector:@selector(_pollAllChannels) withObject:self afterDelay:pollingState];
        [self _pollAllChannels];
    }
    else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
        if(verbose) NSLog(@"Not Polling XVME564,%d,%d\n",[self crateNumber],[self slot]);
    }
}

- (void) _pollAllChannels
{
    @try { 
        [self readAllAdcChannels]; 
    }
	@catch(NSException* localException) { 
		//catch this here to prevent it from falling thru, but nothing to do.
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
	if(pollingState!=0){
		[self performSelector:@selector(_pollAllChannels) withObject:nil afterDelay:pollingState];
	}
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self _setChannelGains:[decoder decodeObjectForKey:@"kORXYCom564chanGains"]];
    [self _setChannelADCValues:[decoder decodeObjectForKey:@"kORXYCom564chanADCValues"]];    
    if ([self addressModifier] == 0x29) {
        [self setReadoutMode:kA16];
    } else {
        [self setReadoutMode:kA24];
    }
    [self setOperationMode:[decoder decodeIntForKey:@"kORXYCom564OperationMode"]];    
    [self setAutoscanMode:[decoder decodeIntForKey:@"kORXYCom564AutoscanMode"]];
    [self setPollingState:[decoder decodeIntForKey:@"kORXYCom564PollingState"]];    
    [[self undoManager] enableUndoRegistration];
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:channelGains forKey:@"kORXYCom564chanGains"];
    [encoder encodeInt:[self operationMode] forKey:@"kORXYCom564OperationMode"];    
    [encoder encodeInt:[self autoscanMode] forKey:@"kORXYCom564AutoscanMode"];
    [encoder encodeInt:pollingState forKey:@"kORXYCom564PollingState"];        
    [encoder encodeObject:chanADCVals forKey:@"kORXYCom564chanADCValues"];    
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	
    return objDictionary;
}

@end

