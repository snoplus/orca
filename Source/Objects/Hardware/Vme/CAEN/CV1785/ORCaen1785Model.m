/*
 *  ORCaen1785Model.m
 *  Orca
 *
 *  Created by Mark Howe on Friday June 19 2009.
 *  Copyright (c) 2009 UNC. All rights reserved.
 *
 */
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
#import "ORCaen1785Model.h"
#import "ORCaen1785Decoder.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORRateGroup.h"

// Address information for this unit.
#define k965DefaultBaseAddress 		0xd0000
#define k965DefaultAddressModifier 	0x39

// Define all the registers available to this unit.
static RegisterNamesStruct reg[kNumRegisters] = {
	{@"Output Buffer",      true,	true, 	true,	0x0000,		kReadOnly,	kD32},
	{@"FirmWare Revision",	false,  false, 	false,	0x1000,		kReadOnly,	kD16},
	{@"Geo Address",		false,	false, 	false,	0x1002,		kReadWrite,	kD16},
	{@"MCST CBLT Address",	false,	false, 	true,	0x1004,		kReadWrite,	kD16},
	{@"Bit Set 1",			false,	true, 	true,	0x1006,		kReadWrite,	kD16},
	{@"Bit Clear 1",		false,	true, 	true,	0x1008,		kReadWrite,	kD16},
	{@"Interrup Level",     false,	true, 	true,	0x100A,		kReadWrite,	kD16},
	{@"Interrup Vector",	false,	true, 	true,	0x100C,		kReadWrite,	kD16},
	{@"Status Register 1",	false,	true, 	true,	0x100E,		kReadOnly,	kD16},
	{@"Control Register 1",	false,	true, 	true,	0x1010,		kReadWrite,	kD16},
	{@"ADER High",			false,	false, 	true,	0x1012,		kReadWrite,	kD16},
	{@"ADER Low",			false,	false, 	true,	0x1014,		kReadWrite,	kD16},
	{@"Single Shot Reset",	false,	false, 	false,	0x1016,		kWriteOnly,	kD16},
	{@"MCST CBLT Ctrl",     false,	false, 	true,	0x101A,		kReadWrite,	kD16},
	{@"Event Trigger Reg",	false,	true, 	true,	0x1020,		kReadWrite,	kD16},
	{@"Status Register 2",	false,	true, 	true,	0x1022,		kReadOnly,	kD16},
	{@"Event Counter L",	true,	true, 	true,	0x1024,		kReadOnly,	kD16},
	{@"Event Counter H",	true,	true, 	true,	0x1026,		kReadOnly,	kD16},
	{@"Increment Event",	false,	false, 	false,	0x1028,		kWriteOnly,	kD16},
	{@"Increment Offset",	false,	false, 	false,	0x102A,		kWriteOnly,	kD16},
	{@"Load Test Register",	false,	false, 	false,	0x102C,		kReadWrite,	kD16},
	{@"FCLR Window",		false,	true, 	true,	0x102E,		kReadWrite,	kD16},
	{@"Bit Set 2",			false,	true, 	true,	0x1032,		kReadWrite,	kD16},
	{@"Bit Clear 2",		false,	true, 	true,	0x1034,		kWriteOnly,	kD16},
	{@"W Mem Test Address",	false,	true, 	true,	0x1036,		kWriteOnly,	kD16},
	{@"Mem Test Word High",	false,	true, 	true,	0x1038,		kWriteOnly,	kD16},
	{@"Mem Test Word Low",	false,	false, 	false,	0x103A,		kWriteOnly,	kD16},
	{@"Crate Select",       false,	true, 	true,	0x103C,		kReadWrite,	kD16},
	{@"Test Event Write",	false,	false, 	false,	0x103E,		kWriteOnly,	kD16},
	{@"Event Counter Reset",false,	false, 	false,	0x1040,		kWriteOnly,	kD16},
	{@"R Test Address",     false,	true, 	true,	0x1064,		kWriteOnly,	kD16},
	{@"SW Comm",			false,	false, 	false,	0x1068,		kWriteOnly,	kD16},
	{@"Slide Constant",		false,	true, 	true,	0x106A,		kReadWrite,	kD16},
	{@"ADD",				false,	false, 	false,	0x1070,		kReadOnly,	kD16},
	{@"BADD",				false,	false, 	false,	0x1072,		kReadOnly,	kD16},
	{@"Thresholds",			false,	false, 	false,	0x1080,		kReadWrite,	kD16},
};

#define k1785DefaultBaseAddress 0xee000000

@implementation ORCaen1785Model

#pragma mark ***Initialization
//--------------------------------------------------------------------------------
/*!\method  init
 * \brief	Called first time class is initialized.  Used to set basic
 *			default values first time object is created.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k1785DefaultBaseAddress];
    [self setAddressModifier:0x39];
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

//--------------------------------------------------------------------------------
/*!\method  setUpImage
 * \brief	Sets the image used by this device in the catalog window.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Caen1785"]];
}

//--------------------------------------------------------------------------------
/*!\method  makeMainController
 * \brief	Makes the controller object that interfaces between the GUI and
 *			this model.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) makeMainController
{
    [self linkToController:@"ORCaen1785Controller"];
}

- (NSString*) helpURL
{
	return @"VME/V1785.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x10BF);
}


- (void) write
{
    // Get the value - Already validated by stepper.
    unsigned long theValue =  [self writeValue];
    // Get register and channel from dialog box.
    short theChannelIndex	= [self selectedChannel];
    short theRegIndex 		= [self selectedRegIndex];
	short		start;
    short		end;
    short		i;
	
    @try {
        
        NSLog(@"Register is:%d\n", theRegIndex);
        NSLog(@"Index is   :%d\n", theChannelIndex);
        NSLog(@"Value is   :0x%04x\n", theValue);
		if (theRegIndex == kThresholds){
            start = theChannelIndex;
            end = theChannelIndex;
            if(theChannelIndex >= [self numberOfChannels]) {
                start = 0;
                end = kCV1785NumberChannels - 1;
            }
            
            // Loop through the thresholds and read them.
			if(theRegIndex == kThresholds){
				for(i = start; i <= end; i++){
					[self setThreshold:i withValue:theValue];
					[self writeThreshold:i];
					NSLog(@"Threshold %2d = 0x%04lx\n", i, [self threshold:i]);
				}
			}
        }
		
		else if ([self getAccessSize:theRegIndex] == kD16){
			unsigned short sValue = (unsigned short)theValue;
			[[self adapter] writeWordBlock:&sValue
								 atAddress:[self baseAddress] + [self getAddressOffset:theRegIndex]
								numToWrite:1
								withAddMod:[self addressModifier]
							 usingAddSpace:0x01];
        }
		else {
			[[self adapter] writeLongBlock:&theValue
								 atAddress:[self baseAddress] + [self getAddressOffset:theRegIndex]
								numToWrite:1
								withAddMod:[self addressModifier]
							 usingAddSpace:0x01];
		}
	}
	@catch(NSException* localException) {
		NSLog(@"Can't write 0x%04lx to [%@] on the %@.\n",
			  theValue, [self getRegisterName:theRegIndex],[self identifier]);
		[localException raise];
	}
}


- (void) read:(unsigned short) pReg returnValue:(void*) pValue
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
	if ([self getAccessSize:pReg] == kD16){
		unsigned short aValue;
		[[self adapter] readWordBlock:&aValue
							atAddress:[self baseAddress] + [self getAddressOffset:pReg]
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		*((unsigned short*)pValue) = aValue;
	}
	else {
		unsigned long aValue;
		[[self adapter] readLongBlock:&aValue
							atAddress:[self baseAddress] + [self getAddressOffset:pReg]
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		*((unsigned long*)pValue) = aValue;
	}
}



- (void) writeThresholds
{
    short i;
    for (i = 0; i < kCV1785NumberChannels; i++){
        [self writeThreshold:i];
    }
}

- (void) readThresholds
{
    short i;
    for (i = 0; i < kCV1785NumberChannels; i++){
        [self readThreshold:i];
    }
}

- (void) writeThreshold:(unsigned short) pChan
{    
	int kill = ((onlineMask & (1<<pChan))!=0)?0x0:0x100;
	unsigned short threshold = thresholds[pChan] | kill;
    [[self adapter] writeWordBlock:&threshold
                         atAddress:[self baseAddress] + [self thresholdOffset:pChan]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}


- (unsigned short) readThreshold:(unsigned short) pChan
{    
	int lowOffset = [self thresholdOffset:pChan];
	unsigned short threshold;
    [[self adapter] readWordBlock:&threshold
						atAddress:[self baseAddress] + lowOffset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	return threshold;
}


- (int) thresholdOffset:(unsigned short)aChan
{
	return reg[kThresholds].addressOffset + (aChan * 4);
}


- (short) getNumberRegisters
{
    return kNumRegisters;
}

//--------------------------------------------------------------------------------
/*!\method  getBufferOffset
 * \brief	Get the output buffer offset relative to the module's base address.
 * \return	The output buffer offset.
 * \note	
 */
//--------------------------------------------------------------------------------
- (unsigned long) getBufferOffset
{
    return reg[kOutputBuffer].addressOffset;
}

//--------------------------------------------------------------------------------
/*!\method  getDataBufferSize
 * \brief	Get size of class data buffer.
 * \return	The size of the data buffer.
 * \note	
 */
//--------------------------------------------------------------------------------
- (unsigned short) getDataBufferSize
{
    return kADCOutputBufferSize;
}

//--------------------------------------------------------------------------------
/*!\method  getThresholdOffset
 * \brief	Get the offset relative to the module's base address for the threshold
 *			registers.
 * \return	The threshold offset.
 * \note	
 */
//--------------------------------------------------------------------------------
- (unsigned long) getThresholdOffset
{
    return reg[kThresholds].addressOffset;
}

//--------------------------------------------------------------------------------
/*!\method  getStatusRegisterIndex
 * \brief	Get the offset relative to the module's base address for
 *			either status register 1 or 2.
 * \param	aRegister			- Either 1 or 2 for status register 1 or 2.
 * \return	The offset
 * \note	
 */
//--------------------------------------------------------------------------------
- (short) getStatusRegisterIndex:(short) aRegister
{
    if (aRegister == 1) return kStatusRegister1;
    else		return kStatusRegister2;
}

//--------------------------------------------------------------------------------
/*!\method  getThresholdIndex
 * \brief	Get the index number within mreg for the thresholds. 
 * \return	The index
 * \note	
 */
//--------------------------------------------------------------------------------
- (short) getThresholdIndex
{
    return(kThresholds);
}

//--------------------------------------------------------------------------------
/*!\method  getOutputBufferIndex
 * \brief	Get the index number within mreg for the output buffer. 
 * \return	The index
 * \note	
 */
//--------------------------------------------------------------------------------
- (short) getOutputBufferIndex
{
    return(kOutputBuffer);
}


#pragma mark ***Register - Register specific routines
//--------------------------------------------------------------------------------
/*!\method  getRegisterName
 * \brief	Get the name of the register at index anIndex.
 * \param	anIndex			- Register index.
 * \return	The name of the register.
 * \note	
 */
//--------------------------------------------------------------------------------
- (NSString*) getRegisterName:(short) anIndex
{
    return reg[anIndex].regName;
}

//--------------------------------------------------------------------------------
/*!\method  getAddressOffset
 * \brief	Get the address offset for the specific register.
 * \param	anIndex			- Register index.
 * \return	The offset to the register.
 * \note	
 */
//--------------------------------------------------------------------------------
- (unsigned long) getAddressOffset:(short) anIndex
{
    return(reg[anIndex].addressOffset);
}

//--------------------------------------------------------------------------------
/*!\method  getAccessType
 * \brief	Get the access type, either read, write or readWrite for the
 *			register at index anIndex.
 * \param	anIndex			- Register index.
 * \return	The access type.
 * \note	
 */
//--------------------------------------------------------------------------------
- (short) getAccessType:(short) anIndex
{
    return reg[anIndex].accessType;
}

//--------------------------------------------------------------------------------
/*!\method  getAccessSize
 * \brief	Get the access size, either 32 or 16 bit for the
 *			register at index anIndex.
 * \param	anIndex			- Register index.
 * \return	The access type.
 * \note	
 */
//--------------------------------------------------------------------------------
- (short) getAccessSize:(short) anIndex
{
    return reg[anIndex].size;
}

//--------------------------------------------------------------------------------
/*!\method  dataReset
 * \brief	Get the data reset flag for register at index anIndex.
 * \param	anIndex			- Index of the register.
 * \return	The data reset flag either true of false.
 * \note	
 */
//--------------------------------------------------------------------------------
- (BOOL) dataReset:(short) anIndex
{
    return reg[anIndex].dataReset;
}

//--------------------------------------------------------------------------------
/*!\method  swReset
 * \brief	Get the software reset flag for register at index anIndex.
 * \param	anIndex			- Register index.
 * \return	The software reset flag.
 * \note	
 */
//--------------------------------------------------------------------------------
- (BOOL) swReset:(short) anIndex
{
    return reg[anIndex].softwareReset;
}

//--------------------------------------------------------------------------------
/*!\method  hwReset
 * \brief	Get the hardware reset flag for register at index anIndex.
 * \param	anIndex			- Register index.
 * \return	The hardware reset flag.
 * \note	
 */
//--------------------------------------------------------------------------------
- (BOOL) hwReset:(short) anIndex
{
    return reg[anIndex].hwReset;
}


#pragma mark ***DataTaker
//--------------------------------------------------------------------------------
/*!\method  runTaskStarted
 * \brief	Beginning of run.  Prepare this object to take data.  Write out hardware settings
 *			to data stream.
 * \param	aDataPacket				- Object where data is written.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    [super runTaskStarted:aDataPacket userInfo:userInfo];
    
    // Clear unit
    [self write:kBitSet2 sendValue:kClearData];		// Clear data, 
    [self write:kBitClear2 sendValue:kClearData];       // Clear "Clear data" bit of status reg.
    [self write:kEventCounterReset sendValue:0x0000];	// Clear event counter
	
    // Set options
	
    // Set thresholds in unit
    [self writeThresholds];
    
}


//--------------------------------------------------------------------------------
/*!\method  runTaskStopped
 * \brief	Resets the oscilloscope so that it is in continuous acquisition mode.
 * \param	aDataPacket			- Data from most recent event.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    [super runTaskStopped:aDataPacket userInfo:userInfo];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 1785 (Slot %d) ",[self slot]];
}

#pragma mark ***Archival
//--------------------------------------------------------------------------------
/*!\method  initWithCoder  
 * \brief	Initialize object using archived settings.
 * \param	aDecoder			- Object used for getting archived internal parameters.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];
	
    [[self undoManager] disableUndoRegistration];
	
    
    [[self undoManager] enableUndoRegistration];
    return self;
}

//--------------------------------------------------------------------------------
/*!\method  encodeWithCoder  
 * \brief	Save the internal settings to the archive.  OscBase saves most
 *			of the settings.
 * \param	anEncoder			- Object used for encoding.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
}

@end

@implementation ORCaen1785DecoderForCAEN : ORCaenDataDecoder
- (NSString*) identifier
{
    return @"CAEN 1785 ADC";
}
@end

