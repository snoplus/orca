//--------------------------------------------------------------------------------
//ORCV977Model.h
//Mark A. Howe 20013-09-26
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORCaenCardModel.h"

// Declaration of constants for module.
enum {
	kInputSet,           //0x0000
	kInputMask,          //0x0002
	kInputRead,          //0x0004
	kSingleHitRead,      //0x0006
	kMultihitRead,       //0x0008
	kOutputSet,          //0x000A
	kOutputMask,         //0x000C
	kInterruptMask,      //0x000E
	kClearOutput,        //0x0010
	kSinglehitReadClear, //0x0016
	kMultihitReadClear,  //0x0018
	kTestControl,        //0x001A
	kInterruptLevel,     //0x0020
	kInterruptVector,    //0x0022
	kSerialNumber,       //0x0024
	kFirmwareRevision,   //0x0026
	kControlRegister,    //0x0028
	kSoftwareReset,      //0x002E
    kNumRegisters        //must be last
};

typedef struct V977NamesStruct {
	NSString*       regName;
	unsigned long 	addressOffset;
	short           accessType;
} V977NamesStruct;


// Class definition
@interface ORCV977Model : ORCaenCardModel
{
	unsigned long inputSet;
}

#pragma mark ***Accessors
- (unsigned long)   inputSet;
- (void)			setInputSet:(unsigned long)anInputSet;
- (BOOL)			inputSetBit:(int)bit;
- (void)			setInputSetBit:(int)bit withValue:(BOOL)aValue;

- (unsigned long)   inputMask;
- (void)			setInputMask:(unsigned long)anInputSet;
- (BOOL)			inputMaskBit:(int)bit;
- (void)			setInputMaskBit:(int)bit withValue:(BOOL)aValue;

#pragma mark ***Register - General routines
- (short)           getNumberRegisters;

#pragma mark ***Register - Register specific routines
- (NSString*) 		getRegisterName: (short) anIndex;
- (unsigned long) 	getAddressOffset: (short) anIndex;

#pragma mark ***Hardware Access

@end

extern NSString* ORCV977ModelInputSetChanged;
extern NSString* ORCV977ModelInputMaskChanged;
