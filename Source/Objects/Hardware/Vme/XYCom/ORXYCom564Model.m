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
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"

#pragma mark ***Notification Strings
NSString* ORXYCom564Lock					= @"ORXYCom564Lock";
NSString* ORXYCom564ReadoutModeChanged      = @"ORXYCom564ReadoutModeChanged";
NSString* ORXYCom564OperationModeChanged    = @"ORXYCom564OperationModeChanged";
NSString* ORXYCom564AutoscanModeChanged     = @"ORXYCom564AutoscanModeChanged";
NSString* ORXYCom564ChannelGainChanged      = @"ORXYCom564ChannelGainChanged";
NSString* ORXYCom564PollingStateChanged     = @"ORXYCom564PollingStateChanged";
NSString* ORXYCom564ADCValuesChanged        = @"ORXYCom564ADCValuesChanged";
NSString* ORXYCom564PollingActivityChanged  = @"ORXYCom564PollingActivityChanged"; 
NSString* ORXYCom564ShipRecordsChanged      = @"ORXYCom564ShipRecordsChanged";
NSString* ORXYCom564AverageValueNumberHasChanged = @"ORXYCom564AverageValueNumberHasChanged";

@interface ORXYCom564Model (private)
- (void) _setChannelGains:(NSMutableArray*)gains;
- (void) _setUpPolling:(BOOL)verbose;
- (void) _stopPolling;
- (void) _startPolling;
- (void) _pollAllChannels;
- (void) _setChannelADCValues:(NSMutableArray*)vals withNotify:(BOOL)notify;
- (void) _shipRawValues:(ORDataPacket*)dataPacket;
- (void) _addAverageValues:(NSArray*)vals;
- (void) _setAverageADCValues:(uint32_t*)array withLength:(int)length;
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
- (void) _addAverageValues:(NSArray *)vals
{
    if (vals == nil) return;
    uint32_t* averageValPtr = nil;
    if (chanADCAverageValsCache == nil) chanADCAverageValsCache = [[NSMutableData data] retain];
    if ([chanADCAverageValsCache length]/sizeof(*averageValPtr) != [vals count]) {
        
        [chanADCAverageValsCache setLength:[vals count]*sizeof(*averageValPtr)];
        averageValPtr = (uint32_t*)[chanADCAverageValsCache mutableBytes];
        memset(averageValPtr, 0, [chanADCAverageValsCache length]); 
        currentAverageState = 0;
    }
    averageValPtr = (uint32_t*)[chanADCAverageValsCache mutableBytes];
    int i;
    for (i=0;i<[vals count];i++) {
        averageValPtr[i] += (uint16_t)[[vals objectAtIndex:i] intValue];
    }
    currentAverageState++;
    if (currentAverageState == averageValueNumber) {
        for (i=0;i<[vals count];i++) {
            averageValPtr[i] /= averageValueNumber;
        }        
        [self _setAverageADCValues:averageValPtr withLength:[vals count]];
        memset(averageValPtr, 0, [chanADCAverageValsCache length]);
        currentAverageState = 0;
    }
    
    
}

- (void) _setAverageADCValues:(uint32_t *)array withLength:(int)length
{
    if (chanADCAverageVals == nil) chanADCAverageVals = [[NSMutableArray array] retain];
    [chanADCAverageVals removeAllObjects];
    int i;
    for (i=0;i<length;i++) {
        [chanADCAverageVals addObject:[NSNumber numberWithInt:array[i]]];
    }
}

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

- (void) _setChannelADCValues:(NSMutableArray *)vals withNotify:(BOOL)notify
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
    if (notify) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:ORXYCom564ADCValuesChanged
         object:self];            
    }

    
}

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x29];
    [self _setChannelGains:nil];
    [self _setChannelADCValues:nil withNotify:YES];
    [self setShipRecords:NO];
    [self setOperationMode:kAutoscanning];
    [self setAutoscanMode:k0to64];   
    [self _stopPolling];
    [self setPollingState:0.0];
    [[self undoManager] enableUndoRegistration]; 
    [self setAverageValueNumber:1];
    return self;
}

- (void) dealloc 
{
    [channelGains release];
    [chanADCVals release];
    [chanADCAverageVals release];
    [chanADCAverageValsCache release];  
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
- (unsigned long) dataId 
{
    return dataId;
}
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

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
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom564PollingStateChanged
	 object: self];
}

- (NSTimeInterval) pollingState
{
    return pollingState;
}

- (void) startPollingActivity
{
    [self performSelector:@selector(_startPolling) withObject:nil afterDelay:0.5];    
    
}
- (void) stopPollingActivity
{
    [self performSelector:@selector(_stopPolling) withObject:nil afterDelay:0.5];    
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
    uint8_t val = 0x3;
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
    NSLog(@"VME-564 Crate %i: Slot: %i\n",[self crateNumber],[self slot]);
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
 
- (int) averageValueNumber
{
    return averageValueNumber;
}

- (void) setAverageValueNumber:(int)aValue
{
    if (aValue == averageValueNumber) return;
    if (aValue < 1) aValue = 1;
    averageValueNumber = aValue;
    [chanADCAverageValsCache setLength:0];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom564AverageValueNumberHasChanged
	 object:self];    
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

- (uint16_t) getAdcAverageValueAtChannel:(int)chan
{
    if (chan >= [chanADCAverageVals count]) return 0;    
    return [[chanADCAverageVals objectAtIndex:chan] intValue];    
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

- (BOOL) shipRecords
{
    return shipRecords;
}

- (void) setShipRecords:(BOOL)ship
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipRecords:[self shipRecords]];
    
    shipRecords = ship;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom564ShipRecordsChanged
	 object:self];    
}

#pragma mark ***Readout

- (void) readAllAdcChannels
{
    if (operationMode != kAutoscanning) {
        NSLog(@"XVME not in autoscanning mode\n");   
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
    [self _addAverageValues:chanADCVals];
    [self _setChannelADCValues:chanADCVals withNotify:!isRunning];
    
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

- (int) numberOfChannels
{
    return [self getNumberOfChannels];
}

- (void) setProcessOutput:(int)channel value:(int)value
{
    
}

- (NSString*) processingTitle
{
    return [NSString stringWithFormat:@"XVME-564,%d,%d",[self crateNumber],[self slot]];
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
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom564PollingActivityChanged
	 object: self];    
}

- (void) _startPolling
{
	[self _setUpPolling:YES];
}

- (void) _setUpPolling:(BOOL)verbose
{
	
	if(pollRunning && pollingState != 0)return;
    if (isRunning) {
        if(verbose) NSLog(@"XVME564,%d,%d, can not poll while it is in the run loop\n",[self crateNumber],[self slot]);
        return;
    }
    
    if(pollingState!=0){  
        if ([self operationMode] != kAutoscanning) {
            if(verbose) NSLog(@"XVME564,%d,%d, must be in autoscan mode to poll\n",[self crateNumber],[self slot]);
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
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom564PollingActivityChanged
	 object: self];
}

- (void) _pollAllChannels
{
    @try { 
        [self readAllAdcChannels]; 
        if ([self shipRecords]) {
            [self _shipRawValues:nil];
        }
    }
	@catch(NSException* localException) { 
		//catch this here to prevent it from falling thru, but nothing to do.
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
	if(pollingState!=0){
		[self performSelector:@selector(_pollAllChannels) withObject:nil afterDelay:pollingState];
	} else {
        [self _stopPolling];
    }
}
- (BOOL) isPolling
{
    return pollRunning;
}

#pragma mark •••Data records
- (void) setDataIds:(id)assigner
{
    dataId          = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];	
    return objDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORXYCom564Model"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"ORXYCom564Decoder",                                               @"decoder",
                                 [NSNumber numberWithLong:dataId],@"dataId",
                                 [NSNumber numberWithBool:YES],@"variable",
                                 [NSNumber numberWithLong:-1],@"length",
                                 nil];
    [dataDictionary setObject:aDictionary forKey:@"XYCom564"];
    
    return dataDictionary;
}
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a Controller."];
    }
    if ([self operationMode] != kAutoscanning) {
        [NSException raise:@"Not in autoscanning mode" format:@"You must be in autoscanning mode to run in the loop."];
    }
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    isRunning = YES;
    [self _stopPolling];
    [self appendDataDescription:aDataPacket userInfo:userInfo];
    
    //cache some stuff
    [self initBoard];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    [self readAllAdcChannels];
    [self _shipRawValues:aDataPacket];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    isRunning = NO;
}

- (void) reset
{
}

- (void) _shipRawValues:(ORDataPacket*)dataPacket
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
	
	if(!runInProgress) return;
    int channelsToRead =kXVME564_NumAutoScanChannelsPerGroup << ([self autoscanMode]);    
    int headernumber = 4;
    unsigned long data[headernumber+channelsToRead];
    
    data[1] = (([self crateNumber]&0x01e)<<21) |  (([self slot]&0x1f) << 16);
    
    //get the time(UT!)
    struct timeval ut_time;
    gettimeofday(&ut_time, NULL);
    data[2] = ut_time.tv_sec;	//seconds since 1970
    data[3] = ut_time.tv_usec;	//seconds since 1970    
    int index = headernumber;
    int i;
    for(i=0;i<channelsToRead;i++){
        uint16_t val = [self getAdcValueAtChannel:i];
        data[index++] = (i&0xff)<<16 | (val & 0xffff);
    }
    data[0] = dataId | index;
    
    if(dataPacket != nil) {
        [dataPacket addLongsToFrameBuffer:data length:index];
    } else if(index>headernumber){
        //the full record goes into the data stream via a notification
        [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
                                                            object:[NSData dataWithBytes:data length:sizeof(data[0])*index]];
    }
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self _setChannelGains:[decoder decodeObjectForKey:@"kORXYCom564chanGains"]];
    [self _setChannelADCValues:[decoder decodeObjectForKey:@"kORXYCom564chanADCValues"] withNotify:YES];
    // The super decoder handles the address Modifier output
    if ([self addressModifier] == 0x29) {
        [self setReadoutMode:kA16];
    } else {
        [self setReadoutMode:kA24];
    }
    [self setOperationMode:[decoder decodeIntForKey:@"kORXYCom564OperationMode"]];
    [self setAverageValueNumber:[decoder decodeIntForKey:@"kORXYCom564AvgValNumber"]];    
    [self setAutoscanMode:[decoder decodeIntForKey:@"kORXYCom564AutoscanMode"]];
    [self setPollingState:[decoder decodeDoubleForKey:@"kORXYCom564PollingState"]]; 
    [self setShipRecords:[decoder decodeBoolForKey:@"kORXYCom564ShipRecords"]];     
    [[self undoManager] enableUndoRegistration];
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:channelGains forKey:@"kORXYCom564chanGains"];
    [encoder encodeInt:[self operationMode] forKey:@"kORXYCom564OperationMode"];    
    [encoder encodeInt:[self autoscanMode] forKey:@"kORXYCom564AutoscanMode"];
    [encoder encodeInt:[self averageValueNumber] forKey:@"kORXYCom564AvgValNumber"];        
    [encoder encodeDouble:pollingState forKey:@"kORXYCom564PollingState"];        
    [encoder encodeObject:chanADCVals forKey:@"kORXYCom564chanADCValues"]; 
    [encoder encodeBool:shipRecords forKey:@"kORXYCom564ShipRecords"];
}

@end

