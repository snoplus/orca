//-------------------------------------------------------------------------
//  ORXYCom200Model.h
//
//  Created by Mark A. Howe on Wednesday 9/18/2008.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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
#import "ORVmeIOCard.h";
#import "ORHWWizard.h";

#pragma mark •••Register Definitions
enum {
	kGeneralControl,
	kServiceRequest,
	kADataDirection,
	kBDataDirection,
	kCDataDirection,
	kInterruptVector,
	kAControl,
	kBControl,
	kAData,
	kBData,
	kCData,
	kAAlternate,
	kBAlternate,
	kStatus,
	kTimerControl,
	kTimerInterruptVector,
	kTimerStatus,
	kCounterPreloadHigh,
	kCounterPreloadMid,
	kCounterPreloadLow,
	kCountHigh,
	kCountMid,
	kCountLow,
	kNumRegs
};

@interface ORXYCom200Model : ORVmeIOCard <ORHWWizard>
{
  @private
    unsigned short  selectedRegIndex;
    unsigned long   writeValue;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ••• accessors
- (unsigned short) 	selectedRegIndex;
- (void)			setSelectedRegIndex: (unsigned short) anIndex;
- (unsigned long) 	writeValue;
- (void)			setWriteValue: (unsigned long) anIndex;


#pragma mark •••Hardware Access
- (void) read;
- (void) write;
- (void) read:(unsigned short) pReg returnValue:(void*) pValue;
- (void) write: (unsigned short) pReg sendValue: (unsigned char) pValue;

#pragma mark ***Register - Register specific routines
- (short)			getNumberRegisters;
- (NSString*) 		getRegisterName: (short) anIndex;
- (unsigned long) 	getAddressOffset: (short) anIndex;

#pragma mark •••HW Wizard
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
@end


#pragma mark •••External String Definitions
extern NSString*	ORXYCom200SettingsLock;
extern NSString* 	ORXYCom200SelectedRegIndexChanged;
extern NSString* 	ORXYCom200WriteValueChanged;
