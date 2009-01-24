//--------------------------------------------------------------------------------
// CLASS:		ORCaen775Model
// Purpose:		Handles hardware interface for those commands specific to the 775.
// Author:		Jan M. Wouters
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
#import "ORCaen775Model.h"


// Address information for this unit.
#define k775DefaultBaseAddress 		0xa00000
#define k775DefaultAddressModifier 	0x39

//NSString* OR775SelectedRegIndexChanged 	= @"775 Selected Register Index Changed";
//NSString* OR775SelectedChannelChanged 	= @"775 Selected Channel Changed";
//NSString* OR775WriteValueChanged 		= @"775 Write Value Changed";

// Define all the registers available to this unit.
static RegisterNamesStruct reg[kNumRegisters] = {
{@"Output Buffer",		true,	true, 	true,	0x0000,		kReadOnly,	kD32},
{@"FirmWare Revision",	false,	false, 	false,	0x1000,		kReadOnly,	kD16},
{@"Geo Address",		false,	false, 	false,	0x1002,		kReadWrite,	kD16},
{@"MCST CBLT Address",	false,	false, 	true,	0x1004,		kReadWrite,	kD16},
{@"Bit Set 1",			false,	true, 	true,	0x1006,		kReadWrite,	kD16},
{@"Bit Clear 1",		false,	true, 	true,	0x1008,		kReadWrite,	kD16},
{@"Interrup Level",		false,	true, 	true,	0x100A,		kReadWrite,	kD16},
{@"Interrup Vector",	false,	true, 	true,	0x100C,		kReadWrite,	kD16},
{@"Status Register 1",	false,	true, 	true,	0x100E,		kReadOnly,	kD16},
{@"Control Register 1",	false,	true, 	true,	0x1010,		kReadWrite,	kD16},
{@"ADER High",			false,	false, 	true,	0x1012,		kReadWrite,	kD16},
{@"ADER Low",			false,	false, 	true,	0x1014,		kReadWrite,	kD16},
{@"Single Shot Reset",	false,	false, 	false,	0x1016,		kWriteOnly,	kD16},
{@"MCST CBLT Ctrl",		false,	false, 	true,	0x101A,		kReadWrite,	kD16},
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
{@"Crate Select",		false,	true, 	true,	0x103C,		kReadWrite,	kD16},
{@"Test Event Write",	false,	false, 	false,	0x103E,		kWriteOnly,	kD16},
{@"Event Counter Reset",false,	false, 	false,	0x1040,		kWriteOnly,	kD16},
{@"Full Scale Range",	false,	true, 	true,	0x1060,		kReadWrite,	kD16},
{@"R Test Address",		false,	true, 	true,	0x1064,		kWriteOnly,	kD16},
{@"SW Comm",			false,	false, 	false,	0x1068,		kWriteOnly,	kD16},
{@"ADD",				false,	false, 	false,	0x1070,		kReadOnly,	kD16},
{@"BADD",				false,	false, 	false,	0x1072,		kReadOnly,	kD16},
{@"Thresholds",			false,	false, 	false,	0x1080,		kReadWrite,	kD16},
};


@implementation ORCaen775Model

#pragma mark ¥¥¥Initialization
//--------------------------------------------------------------------------------
/*!\method  init
* \brief	Called first time class is initialized.  Used to set basic
*			default values first time object is created.
* \param	aDocument			- The initialization document.
* \note	
*/
//--------------------------------------------------------------------------------
- (id) init //designated initializer
{
    self = [super init];
	[[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress: k775DefaultBaseAddress];
    [self setAddressModifier: k775DefaultAddressModifier];
	
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
    [self setImage:[NSImage imageNamed:@"775Card"]];
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
    [self linkToController:@"ORCaen775Controller"];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x1080);
}

#pragma mark ¥¥¥Register - General routines
//--------------------------------------------------------------------------------
/*!\method  getNumberRegisters
* \brief	Get the number of registers used by this module.
* \return	The number of registers.
* \note	
*/
//--------------------------------------------------------------------------------
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
	return kTDCOutputBufferSize;
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
- (short) getStatusRegisterIndex: (short) aRegister
{
    if ( aRegister == 1 ) return kStatusRegister1;
    else return kStatusRegister2;
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
    //<<<<<<< ORCaen775Model.m
    return( kThresholds );
    /*=======
	[[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
	writeValue = aValue;
	[[NSNotificationCenter defaultCenter]
				postNotificationName:OR775WriteValueChanged
                              object:self];
    >>>>>>> 1.2
    */
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
    return( kOutputBuffer );
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
- (NSString*) getRegisterName: (short) anIndex
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
- (unsigned long) getAddressOffset: (short) anIndex
{
    return( reg[anIndex].addressOffset );
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
- (short) getAccessType: (short) anIndex
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
- (short) getAccessSize: (short) anIndex
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
- (BOOL) dataReset: (short) anIndex
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
- (BOOL) swReset: (short) anIndex
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
- (BOOL) hwReset: (short) anIndex
{
	return reg[anIndex].hwReset;
}


- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 775 (Slot %d) ",[self slot]];
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
- (void) runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    [super runTaskStarted:aDataPacket userInfo:userInfo];
    
    // Clear unit
    [self write: kBitSet2 sendValue: kClearData];				// Clear data, 
    [self write: kBitClear2 sendValue: kClearData];			// Clear "Clear data" bit of status reg.
    [self write: kEventCounterReset sendValue: 0x0000];	// Clear event counter
    
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
- (void) runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(id)userInfo
{
    [super runTaskStopped:aDataPacket userInfo:userInfo];
}


#pragma mark ¥¥¥Archival
//--------------------------------------------------------------------------------
/*!\method  initWithCoder  
* \brief	Initialize object using archived settings.
* \param	aDecoder			- Object used for getting archived internal parameters.
* \note	
*/
//--------------------------------------------------------------------------------
- (id) initWithCoder: (NSCoder*) aDecoder
{
    self = [super initWithCoder: aDecoder];
    
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
- (void) encodeWithCoder: (NSCoder*) anEncoder
{
    [super encodeWithCoder: anEncoder];
}


@end

@implementation ORCaen775DecoderForCAEN : ORCaenDataDecoder
- (NSString*) identifier
{
    return @"CAEN 775 TDC";
}
@end

