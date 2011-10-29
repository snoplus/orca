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
#import "ORVmeIOCard.h"
#import "ORAdcProcessing.h"

#pragma mark •••Register Definitions
typedef enum {
    kModuleID = 0,
    kStatusControl,
    kInterruptTimer,
    kProgTimerInterruptVector,
    kAutoscanControl,
    kADMode,
    kADStatusControl,
    kEndOfConversionVector,
    kGainChannelHigh,
    kGainChannelLow,    
    kADScan,    
    kNumberOfXyCom564Registers
} EXyCom564Registers;

typedef enum {
    kA16,
    kA24
} EXyCom564ReadoutMode;

typedef enum {
    kGainOne,
    kGainTwo,
    kGainFive,
    kGainTen,
    kNumberOfGains
} EXyCom564ChannelGain;

typedef enum {
    kSingleChannel,
    kSequentialChannel,
    kRandomChannel,
    kExternalTrigger,
    kAutoscanning,
    kProgramGain,
    kNumberOfOpModes
} EXyCom564OperationMode;

typedef enum {
    k0to8,
    k0to16,
    k0to32,
    k0to64,
    kNumberOfAutoscanModes
} EXyCom564AutoscanMode;

@interface ORXYCom564Model : ORVmeIOCard <ORAdcProcessing>
{
    @protected
    EXyCom564OperationMode operationMode;
    EXyCom564AutoscanMode  autoscanMode;
    NSTimeInterval         pollingState;
    BOOL                   pollRunning;
    NSMutableArray*        channelGains;
    NSMutableArray*        chanADCVals;    
}
#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (EXyCom564ReadoutMode)    readoutMode;
- (void)                    setReadoutMode:(EXyCom564ReadoutMode) aMode;
- (EXyCom564OperationMode) 	operationMode;
- (void)                    setOperationMode: (EXyCom564OperationMode) anIndex;
- (EXyCom564AutoscanMode) 	autoscanMode;
- (void)                    setAutoscanMode: (EXyCom564AutoscanMode) anIndex;
- (NSTimeInterval)          pollingState;
- (void)                    setPollingState:(NSTimeInterval)aState;

#pragma mark •••Hardware Access
- (void) read:(uint8_t*) aval atRegisterIndex:(EXyCom564Registers)index; 
- (void) write:(uint8_t) aval atRegisterIndex:(EXyCom564Registers)index;

- (void) setGain:(EXyCom564ChannelGain) gain channel:(unsigned short) aChannel;
- (void) setGain:(EXyCom564ChannelGain) gain;
- (EXyCom564ChannelGain) getGain:(unsigned short) aChannel;
- (void) readAllAdcChannels;
- (uint16_t) getAdcValueAtChannel:(int)chan;

- (void) initBoard;
- (void) report;
- (void) resetBoard;
- (void) programGains;
- (void) programReadoutMode;

#pragma mark ***Card qualities
- (short) getNumberOfChannels;

#pragma mark ***Register - Register specific routines
- (short)			getNumberRegisters;
- (short)			getNumberOperationModes;
- (short)			getNumberAutoscanModes;
- (short)			getNumberGainModes;
- (NSString*) 		getRegisterName:(EXyCom564Registers) anIndex;
- (unsigned long) 	getAddressOffset: (EXyCom564Registers) anIndex;
- (NSString*) 		getOperationModeName: (EXyCom564OperationMode) anIndex;
- (NSString*) 		getAutoscanModeName: (EXyCom564AutoscanMode) aMode;
- (NSString*) 		getChannelGainName: (EXyCom564ChannelGain) aMode;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
@end

#pragma mark •••External String Definitions
extern NSString* ORXYCom564Lock;
extern NSString* ORXYCom564ReadoutModeChanged;
extern NSString* ORXYCom564OperationModeChanged;
extern NSString* ORXYCom564AutoscanModeChanged;
extern NSString* ORXYCom564ChannelGainChanged;
extern NSString* ORXYCom564PollingStateChanged;
extern NSString* ORXYCom564ADCValuesChanged;
