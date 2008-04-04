//--------------------------------------------------------------------------------
// CLASS:		ORCaen1720Model
// Purpose:		Handles hardware interface for those commands specific to the 792.
// Author:		Mark A. Howe
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
#import "ORCaen1720Model.h"


// Address information for this unit.
#define k792DefaultBaseAddress 		0xa00000
#define k792DefaultAddressModifier 	0x39

// Define all the registers available to this unit.
static RegisterNamesStruct reg[kNumRegisters] = {
	{@"Output Buffer",      true,	true, 	true,	0x0000,		kReadOnly,	kD32}, //not implemented in HW yet
	{@"ZS_Thres",			true,	true, 	false,	0x1024,		kReadWrite,	kD32}, //not implemented in HW yet
	{@"ZS_NsAmp",			true,	true, 	false,	0x1028,		kReadWrite,	kD32},
	{@"Thresholds",			true,	true, 	false,	0x1080,		kReadWrite,	kD32},
	{@"Time O/U Threshold",	true,	true, 	false,	0x1084,		kReadWrite,	kD32},
	{@"Status",				true,	true, 	false,	0x1088,		kReadOnly,	kD32},
	{@"Firmware Version",	false,	false, 	false,	0x108C,		kReadOnly,	kD32},
	{@"Buffer Occupancy",	true,	true, 	true,	0x1094,		kReadOnly,	kD32},
	{@"Dacs",				true,	true, 	false,	0x1098,		kReadWrite,	kD32},
	{@"Adc Config",			true,	true, 	false,	0x109C,		kReadWrite,	kD32},
	{@"Chan Config",		true,	true, 	false,	0x8000,		kReadWrite,	kD32},
	{@"Chan Config Bit Set",true,	true, 	false,	0x8004,		kWriteOnly,	kD32},
	{@"Chan Config Bit Clr",true,	true, 	false,	0x8008,		kWriteOnly,	kD32},
	{@"Buffer Organization",true,	true, 	false,	0x800C,		kReadWrite,	kD32},
	{@"Buffer Free",		false,	false, 	false,	0x8010,		kReadWrite,	kD32},
	{@"Custom Size",		true,	true, 	false,	0x8020,		kReadWrite,	kD32},
	{@"Acq Control",		true,	true, 	false,	0x8100,		kReadWrite,	kD32},
	{@"Acq Status",			false,	false, 	false,	0x8104,		kReadOnly,	kD32},
	{@"SW Trigger",			false,	false, 	false,	0x8108,		kWriteOnly,	kD32},
	{@"Trig Src Enbl Mask",	true,	true, 	false,	0x810C,		kReadWrite,	kD32},
	{@"FP Trig Out Enbl Mask",true,	true, 	false,	0x8110,		kReadWrite,	kD32},
	{@"Post Trig Setting",	true,	true, 	false,	0x8114,		kReadWrite,	kD32},
	{@"FP I/O Data",		true,	true, 	false,	0x8118,		kReadWrite,	kD32},
	{@"FP I/O Control",		true,	true, 	false,	0x811C,		kReadWrite,	kD32},
	{@"Chan Enable Mask",	true,	true, 	false,	0x8120,		kReadWrite,	kD32},
	{@"ROC FPGA Version",	false,	false, 	false,	0x8124,		kReadOnly,	kD32},
	{@"Event Stored",		true,	true, 	true,	0x812C,		kReadOnly,	kD32},
	{@"Set Monitor DAC",	true,	true, 	false,	0x8138,		kReadWrite,	kD32},
	{@"Board Info",			false,	false, 	false,	0x8140,		kReadOnly,	kD32},
	{@"Monitor Mode",		true,	true, 	false,	0x8144,		kReadWrite,	kD32},
	{@"Event Size",			true,	true, 	false,	0x814C,		kReadOnly,	kD32},
	{@"VME Control",		true,	false, 	false,	0xEF00,		kReadWrite,	kD32},
	{@"Board ID",			true,	true, 	false,	0xEF08,		kReadWrite,	kD32},
	{@"MultCast Base Add",	true,	false, 	false,	0xEF0C,		kReadWrite,	kD32},
	{@"Relocation Add",		true,	false, 	false,	0xEF10,		kReadWrite,	kD32},
	{@"Interrupt Status ID",true,	false, 	false,	0xEF14,		kReadWrite,	kD32},
	{@"Interrupt Event Num",true,	true, 	false,	0xEF18,		kReadWrite,	kD32},
	{@"BLT Event Num",		true,	true, 	false,	0xEF1C,		kReadWrite,	kD32},
	{@"Scratch",			true,	true, 	false,	0xEF20,		kReadWrite,	kD32},
	{@"SW Reset",			false,	false, 	false,	0xEF24,		kWriteOnly,	kD32},
	{@"SW Clear",			false,	false, 	false,	0xEF28,		kWriteOnly,	kD32},
	{@"Flash Enable",		true,	false, 	false,	0xEF2C,		kReadWrite,	kD32},
	{@"Flash Data",			true,	false, 	false,	0xEF30,		kReadWrite,	kD32},
	{@"Config Reload",		false,	false, 	false,	0xEF34,		kWriteOnly,	kD32},
	{@"Config ROM",			false,	false, 	false,	0xF000,		kReadOnly,	kD32}
};

NSString* caenChnlDacChanged  = @"caenChnlDacChanged";

@implementation ORCaen1720Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k792DefaultBaseAddress];
    [self setAddressModifier:k792DefaultAddressModifier];
	
    [[self undoManager] enableUndoRegistration];
   
    return self;
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

- (short) getAccessSize:(short) anIndex
{
    return reg[anIndex].size;
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
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:caenChnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
        postNotificationName:caenChnlDacChanged
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
		[[self adapter] writeWordBlock:&pValue
                                 atAddress:[self baseAddress] + [self getAddressOffset:pReg] + chan*0x100
                                numToWrite:1
                                withAddMod:[self addressModifier]
                             usingAddSpace:0x01];
            
        NS_HANDLER
		NS_ENDHANDLER
}

- (void) readThreshold:(unsigned short) pChan
{
    
    unsigned short		value;
    
    // Read the threshold
    [[self adapter] readWordBlock:&value
                        atAddress:[self baseAddress] + [self getThresholdOffset] + (pChan * 0x100)
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    // Store new value
    [self setThreshold:pChan threshold:value];
    
}

- (void) writeThreshold:(unsigned short) pChan
{
    unsigned short 	threshold = [self threshold:pChan];
    
    [[self adapter] writeWordBlock:&threshold
                         atAddress:[self baseAddress] + [self getThresholdOffset] + (pChan * 0x100)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
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
    unsigned short 	threshold = [self threshold:pChan];
    
    [[self adapter] writeWordBlock:&threshold
                         atAddress:[self baseAddress] + reg[kDacs].addressOffset + (pChan * kD16)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) initBoard
{
	[self writeThresholds];
	[self writeDacs];
}

- (float) convertDacToVolts:(unsigned short)aDacValue 
{ 
	return 2*aDacValue/65535. - 0.9999;  
}

- (unsigned short) convertVoltsToDac:(float)aVoltage  
{ 
	return 65535. * (aVoltage+1)/2.; 
}


#pragma mark ***DataTaker
- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    [super runTaskStarted:aDataPacket userInfo:userInfo];
    
    // Clear unit
    //[self write:kBitSet2 sendValue:kClearData];		// Clear data, 
   // [self write:kBitClear2 sendValue:kClearData];       // Clear "Clear data" bit of status reg.
   // [self write:kEventCounterReset sendValue:0x0000];	// Clear event counter

    // Set options
    [self initBoard];
}


- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    [super runTaskStopped:aDataPacket userInfo:userInfo];
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
	int i;
	for (i = 0; i < [self numberOfChannels]; i++){
        [anEncoder encodeInt:dac[i] forKey:[NSString stringWithFormat:@"CAENDacChnl%d", i]];
    }
}

- (int) numberOfChannels
{
    return 8;
}

@end

@implementation ORCaen1720DecoderForCAEN : ORCaenDataDecoder
- (NSString*) identifier
{
    return @"CAEN 1720 Digitizer";
}
@end

