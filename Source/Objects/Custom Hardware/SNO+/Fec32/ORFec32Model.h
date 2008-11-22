//
//  ORSNOCard.h
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORSNOCard.h"
#import "OROrderedObjHolding.h"

@class ORFecDaughterCardModel;

#define kISetA1 0
#define kISetA0	1
#define kISetM1	2
#define kISetM0	3
#define kTACRef	4
#define kVMax	5

#define kCmosMin		0.0
#define kCmosMax		5.0
#define kCmosStep 		((kCmosMax-kCmosMin)/255.0)

#define kVResMin		0.0
#define kVResMax		5.0
#define kVResStep 		((kVResMax-kVResMin)/255.0)

#define kHVRefMin		0.0
#define kHVRefMax		5.0
#define kHVResStep 		((kHVRefMax-kHVRefMin)/255.0)

// FEC32 Discrete and Sequencer register indices 
#define FEC32_GENERAL_CS_REG					0
#define FEC32_ADC_VALUE_REG						1
#define FEC32_VOLTAGE_MONITOR_REG				2
#define FEC32_PEDESTAL_ENABLE_REG				3
#define FEC32_DAC_PROGRAM_REG					4
#define FEC32_CALIBRATION_DAC_PROGRAM_REG		5
#define FEC32_HVC_CS_REG						6
#define FEC32_CMOS_SPY_OUTPUT_REG				7
#define FEC32_CMOS_FULL_REG						8
#define FEC32_CMOS_SELECT_REG					9
#define FEC32_CMOS_1_16_REG						10
#define FEC32_CMOS_17_32_REG					11
#define FEC32_CMOS_LGISEL_SET_REG				12
#define FEC32_BOARD_ID_REG						13

#define FEC32_SEQ_OUTPUT_CS_REG					14
#define FEC32_SEQ_INTPUT_CS_REG					15
#define FEC32_CMOS_DATA_AVAIL_REG				16
#define FEC32_CMOS_CHIP_SELECT_REG				17
#define FEC32_CMOS_CHIP_DISABLE_REG				18
#define FEC32_CMOS_DATA_OUTPUT_REG				19
#define FEC32_FIFO_WRITE_POINTER_REG			20
#define FEC32_FIFO_READ_POINTER_REG				21
#define FEC32_FIFO_POINTER_DIFF_REG				22

// FEC32 CMOS Internal register indices, used for Apple Events only
#define FEC32_CMOS_MISSED_COUNT_REG				0					
#define FEC32_CMOS_BUSY_REG						1
#define FEC32_CMOS_TOTAL_COUNT_REG				2	
#define FEC32_CMOS_TEST_ID_REG					3
#define FEC32_CMOS_SPARE_COUNTER_REG			4
#define FEC32_CMOS_ARRAY_POINTER_REG			5
#define	FEC32_CMOS_COUNT_INFO_REG				6

// SNTR CSR register, bit masks
#define FEC32_CSR_ZERO					0x00000000
#define FEC32_CSR_SOFT_RESET			0x00000001
#define FEC32_CSR_FIFO_RESET			0x00000002
#define FEC32_CSR_SEQ_RESET				0x00000004
#define FEC32_CSR_CMOS_RESET			0x00000008
#define FEC32_CSR_FULL_RESET			0x0000000F
#define FEC32_CSR_TESTMODE1				0x00000010
#define FEC32_CSR_TESTMODE2				0x00000020
#define FEC32_CSR_TESTMODE3				0x00000040
#define FEC32_CSR_TESTMODE4				0x00000080
#define FEC32_CSR_SPARE1				0x00000100
#define FEC32_CSR_SPARE2				0x00000200
#define FEC32_CSR_CAL_DAC_ENA			0x00000400
#define FEC32_CSR_CRATE_ADD				0x0000F800
#define FEC32_CSR_CGT24ERR1				0x00004000
#define FEC32_CSR_CGT24ERR2				0x00008000
#define FEC32_CSR_CGT24ERR3				0x00010000
#define FEC32_CSR_PULSERTESTPT			0x00020000
// BOARD ID register for all cards
#define BOARD_ID_REG_NUMBER		15  			// Register 15 on the Board ID chip stores the four letter board code

// Bit shift values
#define FEC32_CSR_CRATE_BITSIFT					11

// Fec32 Discrete and Sequencer register offsets 
#define Fec32_GENERAL_CS_REG					128
#define Fec32_ADC_VALUE_REG						132
#define Fec32_VOLTAGE_MONITOR_REG				136
#define Fec32_PEDESTAL_ENABLE_REG				140
#define Fec32_DAC_PROGRAM_REG					144
#define Fec32_CALIBRATION_DAC_PROGRAM_REG		148
#define Fec32_HVC_CS_REG						152
#define Fec32_CMOS_SPY_OUTPUT_REG				156
#define Fec32_CMOS_FULL_REG						160
#define Fec32_CMOS_SELECT_REG					164
#define Fec32_CMOS_1_16_REG						168
#define Fec32_CMOS_17_32_REG					172
#define Fec32_CMOS_LGISEL_SET_REG				176
#define Fec32_BOARD_ID_REG						180

#define Fec32_SEQ_OUTPUT_CS_REG					512
#define Fec32_SEQ_INTPUT_CS_REG					528
#define Fec32_CMOS_DATA_AVAIL_REG				544
#define Fec32_CMOS_CHIP_SELECT_REG				560
#define Fec32_CMOS_CHIP_DISABLE_REG				576
#define Fec32_CMOS_DATA_OUTPUT_REG				592
#define Fec32_FIFO_READ_POINTER_REG				624
#define Fec32_FIFO_WRITE_POINTER_REG			628
#define Fec32_FIFO_POINTER_DIFF_REG				632

#define Fec32_CMOS_MISSED_COUNT_OFFSET		   1028
#define Fec32_CMOS_BUSY_REG_OFFSET			   1032
#define Fec32_CMOS_TOTALS_COUNTER_OFFSET	   1036
#define Fec32_CMOS_TEST_ID_OFFSET			   1040
#define Fec32_CMOS_SHIFT_REG_OFFSET			   1044
#define Fec32_CMOS_ARRAY_POINTER_OFFSET		   1048
#define Fec32_CMOS_COUNT_INFO_OFFSET		   1052

// CMOS Shoft Register defintions
#define FEC32_CMOS_SHIFT_SERSTROB		0x00000001
#define FEC32_CMOS_SHIFT_CLOCK			0x00000002

#define NS20_MASK_BITS				0
#define NS_MASK_BITS				0
#define TACTRIM_BITS				3
#define NS20_DELAY_BITS				3
#define NS20_WIDTH_BITS				4
#define NS100_DELAY_BITS			5

// CMOS Shift Register Item
#define TAC_TRIM1	0
#define TAC_TRIM0	1
#define NS20_MASK	2
#define NS20_WIDTH	3
#define NS20_DELAY	4
#define NS100_MASK	5
#define NS100_DELAY	6

// Board ID Masks
#define	BOARD_ID_WDS		0x00000100 			// 100 00 xxxx
#define	BOARD_ID_WEN		0x00000130 			// 100 11 xxxx
#define BOARD_ID_WRITE		0x00000140 			// 101 00 0000
#define	BOARD_ID_READ  		0x00000180 			// 110 00 0000

#define	BOARD_ID_PREN  		0x00000130 			// 100 11 xxxx
#define	BOARD_ID_PRCLEAR 	0x000001FF			// 111 11 1111
#define	BOARD_ID_PRREAD  	0x00000180 			// 110 00 0000
#define	BOARD_ID_PRWRITE 	0x00000140 			// 101 00 0000

#define	BOARD_ID_SK 		0x00000001			
#define	BOARD_ID_DI 		0x00000080			
#define	BOARD_ID_PRE 		0x00000100			
#define	BOARD_ID_PE 		0x00000200			
#define	BOARD_ID_DO 		0x00000400	

typedef struct Fec32CmosShiftReg{
	unsigned short	cmos_shift_item[7];
} aFec32CmosShiftReg;

@interface ORFec32Model :  ORSNOCard <OROrderedObjHolding>
{
	unsigned char	cmos[6];	//board related	0-ISETA1 1-ISETA0 2-ISETM1 3-ISETM0 4-TACREF 5-VMAX
	unsigned char	vRes;	//VRES for bipolar chip
	unsigned char	hVRef;	//HVREF for high voltage
    NSString*		comments;
    BOOL			showVolts;	
	unsigned long   onlineMask;
	unsigned long   pedEnabledMask;
	unsigned long   seqDisabledMask;
	unsigned long   dirtyMask;
	unsigned long   thresholdToMax;
	unsigned long   trigger20nsDisabledMask;
	unsigned long   trigger100nsDisabledMask;
	BOOL			qllEnabled;
	BOOL			dcPresent[4];
	ORFecDaughterCardModel* dc[4]; //cache the dc's
	aFec32CmosShiftReg	cmosShiftRegisterValue[16];
}
- (void) setUpImage;
- (void) makeMainController;

#pragma mark •••Accessors
- (id) xl2;
- (BOOL)			dcPresent:(unsigned short)index;
- (unsigned long)	pedEnabledMask;
- (void)			setPedEnabledMask:(unsigned long) aMask;
- (unsigned long)	onlineMask;
- (void)			setOnlineMask:(unsigned long) aMask;
- (unsigned long)	seqDisabledMask;
- (void)			setSeqDisabledMask:(unsigned long) aMask;
- (BOOL)			trigger20nsDisabled:(short)chan;
- (BOOL)			trigger100nsDisabled:(short)chan;
- (void)			setTrigger20ns:(short) chan disabled:(short)state;
- (void)			setTrigger100ns:(short) chan disabled:(short)state;
- (unsigned long)	trigger20nsDisabledMask;
- (void)			setTrigger20nsDisabledMask:(unsigned long) aMask;
- (unsigned long)	trigger100nsDisabledMask;
- (void)			setTrigger100nsDisabledMask:(unsigned long) aMask;
- (BOOL)			qllEnabled;
- (void)			setQllEnabled:(BOOL) aState;

- (int)     globalCardNumber;
- (NSComparisonResult) globalCardNumberCompare:(id)aCard;
- (BOOL)	showVolts;
- (void)	setShowVolts:(BOOL)aShowVolts;
- (NSString*)	comments;
- (void)		setComments:(NSString*)aComments;
- (unsigned char)  cmos:(short)anIndex;
- (void)	setCmos:(short)anIndex withValue:(unsigned char)aValue;
- (float)	vRes;
- (void)	setVRes:(float)aValue;
- (float)	hVRef;
- (void)	setHVRef:(float)aValue;
- (BOOL)	pmtOnline:(unsigned short)index;
- (int)		stationNumber;

#pragma mark Converted Data Methods
- (void)	setCmosVoltage:(short)anIndex withValue:(float) value;
- (float)	cmosVoltage:(short) n;
- (void)	setVResVoltage:(float) value;
- (float)	vResVoltage;
- (void)	setHVRefVoltage:(float) value;
- (float)	hVRefVoltage;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Hardware Access
- (unsigned long) fec32RegAddress:(unsigned long)aRegOffset;
- (NSString*) performBoardIDRead:(short) boardIndex;
- (void) writeToFec32Register:(unsigned long) aRegister value:(unsigned long) aBitPattern;
- (void) setFec32RegisterBits:(unsigned long) aRegister bitMask:(unsigned long) bits_to_set;
- (void) clearFec32RegisterBits:(unsigned long) aRegister bitMask:(unsigned long) bits_to_clear;

- (unsigned long) readFromFec32Register:(unsigned long) Register;
- (void) readBoardIds;
- (void) boardIDOperation:(unsigned long)theDataValue boardSelectValue:(unsigned long) boardSelectVal beginIndex:(short) beginIndex;
- (void) autoInitThisCard;
- (void) fullResetOfCard;
- (void) loadCrateAddress;
- (void) loadAllDacs;
- (void) setPedestals;
-(void) performPMTSetup:(BOOL) aTriggersDisabled;

#pragma mark •••OROrderedObjHolding Protocal
- (int) maxNumberOfObjects;
- (int) objWidth;
- (int) groupSeparation;
- (NSRange) legalSlotsForObj:(id)anObj;
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj;
- (int)slotAtPoint:(NSPoint)aPoint; 
- (NSPoint) pointForSlot:(int)aSlot; 
- (void) place:(id)aCard intoSlot:(int)aSlot;
- (NSString*) slotName:(int)aSlot;
@end


extern NSString* ORFecShowVoltsChanged;
extern NSString* ORFecCommentsChanged;
extern NSString* ORFecCmosChanged;
extern NSString* ORFecVResChanged;
extern NSString* ORFecHVRefChanged;
extern NSString* ORFecOnlineMaskChanged;
extern NSString* ORFecPedEnabledMaskChanged;
extern NSString* ORFecSeqDisabledMaskChanged;
extern NSString* ORFecTrigger20nsDisabledMaskChanged;
extern NSString* ORFecTrigger100nsDisabledMaskChanged;
extern NSString* ORFecQllEnabledChanged;

extern NSString* ORFecLock;


@interface NSObject (ORFec32Model)
- (void) writeHardwareRegister:(unsigned long) anAddress value:(unsigned long) aValue;
- (unsigned long) readHardwareRegister:(unsigned long) regAddress;
@end
