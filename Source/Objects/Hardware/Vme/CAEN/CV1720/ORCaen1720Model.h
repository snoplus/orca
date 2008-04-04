//--------------------------------------------------------------------------------
/*!\class	ORCaen1720Model
 * \brief	Handles all access to CAEN CV792 ADC module.
 * \methods
 *			\li \b 			- Constructor
 *			\li \b 
 * \note
 * \author	Mark A. Howe
 * \history	2004-04-21 (MAH) - Original
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

#import "ORCaenCardModel.h"

// Declaration of constants for module.
enum {
	kOutputBuffer,			//0x0000
	kZS_Thres,				//0x1024
	kZS_NsAmp,				//0x1028
	kThresholds,			//0x1084
	kTimeOUThreshold,		//0x1084
	kStatus,				//0x1088
	kFirmwareVersion,		//0x108C
	kBufferOccupancy,		//0x1094
	kDacs,					//0x1098	
	kAdcConfig,				//0x109C
	kChanConfig,			//0x8000
	kChanConfigBitSet,		//0x8004
	kChanConfigBitClr,		//0x8008
	kBufferOrganization,	//0x800C
	kBufferFree,			//0x8010
	kCustomSize,			//0x8020
	kAcqControl,			//0x8100
	kAcqStatus,				//0x8104
	kSWTrigger,				//0x8108
	kTrigSrcEnblMask,		//0x810C
	kFPTrigOutEnblMask,		//0x8110
	kPostTriSetting,		//0x8114
	kFPIOData,				//0x8118
	kFPIOControl,			//0x811C
	kChanEnableMask,		//0x8120
	kROCFPGAVersion,		//0x8124
	kEventStored,			//0x812C
	kSetMonitorDAC,			//0x8138
	kBoardInfo,				//0x8140
	kMonitorMode,			//0x8144
	kEventSize,				//0x814C
	kVMEControl,			//0xEF00
	kBoardID,				//0xEF08
	kMultCastBaseAdd,		//0xEF0C
	kRelocationAdd,			//0xEF10		
	kInterruptStatusID,		//0xEF14
	kInterruptEventNum,		//0xEF18
	kBLTEventNum,			//0xEF1C
	kScratch,				//0xEF20
	kSWReset,				//0xEF24
	kSWClear,				//0xEF28
	kFlashEnable,			//0xEF2C
	kFlashData,				//0xEF30
	kConfigReload,			//0xEF34
	kConfigROM,				//0xF000
	kNumRegisters
};

// Size of output buffer
#define kEventBufferSize 0x0FFC

// Class definition
@interface ORCaen1720Model : ORCaenCardModel
{
	unsigned short dac[8];
}

#pragma mark ***Accessors

#pragma mark ***Register - General routines
- (void)			initBoard;
- (short)			getNumberRegisters;
- (unsigned long) 	getBufferOffset;
- (unsigned short) 	getDataBufferSize;
- (unsigned long) 	getThresholdOffset;
- (short)			getStatusRegisterIndex: (short) aRegister;
- (short)			getThresholdIndex;
- (short)			getOutputBufferIndex;
- (unsigned short) dac:(unsigned short) aChnl;
- (void) setDac:(unsigned short) aChnl withValue:(unsigned short) aValue;

#pragma mark ***Register - Register specific routines
- (NSString*) 		getRegisterName: (short) anIndex;
- (unsigned long) 	getAddressOffset: (short) anIndex;
- (short)			getAccessType: (short) anIndex;
- (short)			getAccessSize: (short) anIndex;
- (BOOL)			dataReset: (short) anIndex;
- (BOOL)			swReset: (short) anIndex;
- (BOOL)			hwReset: (short) anIndex;
- (void)			readChan:(unsigned short)chan reg:(unsigned short) pReg returnValue:(unsigned short*) pValue;
- (void)			writeChan:(unsigned short)chan reg:(unsigned short) pReg sendValue:(unsigned short) pValue;
- (void)			writeDacs;
- (void)			writeDac:(unsigned short) pChan;
- (float)			convertDacToVolts:(unsigned short)aDacValue;
- (unsigned short)	convertVoltsToDac:(float)aVoltage;

#pragma mark ***Hardware Access

@end


extern NSString*	caenChnlDacChanged;


//the decoder concrete decoder class
@interface ORCaen1720DecoderForCAEN : ORCaenDataDecoder
{}
- (NSString*) identifier;
@end

