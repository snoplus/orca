//
//  ORMJDVacuumModel.h
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
//  Copyright © 2012 CENPA, University of North Carolina. All rights reserved.
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
#import "ORVacuumParts.h"
#import "ORAdcProcessing.h"
#import "ORBitProcessing.h"
#import "OROrderedObjHolding.h"

@class ORVacuumGateValve;
@class ORVacuumPipe;
@class ORLabJackUE9Model;

//-----------------------------------
//region definitions
#define kRegionAboveTurbo	0
#define kRegionRGA			1
#define kRegionCryostat		2
#define kRegionCryoPump		3
#define kRegionBaratron		4
#define kRegionDryN2		5
#define kRegionNegPump		6
#define kRegionDiaphramPump	7
#define kRegionBelowTurbo	8

#define kNumberRegions	    9 
//-----------------------------------
//component tag numbers
#define kTurboComponent			0
#define kRGAComponent			1
#define kCryoPumpComponent		2
#define kPressureGaugeComponent 3
#define kBaratronComponent		4


#define kTurboOnPressureConstraint				 @"Turbo ON, Pressure >1.0E-1 Torr."
#define kTurboOnPressureConstraintReason		 @"Opening valve will expose turbo pump to potentially damaging pressures."

#define kTurboOnSentryOpenConstraint			 @"Turbo ON, sentry is open."
#define kTurboOnSentryOpenConstraintReason		 @"Opening cryopump roughing valve could expose turbo pump to potentially damaging pressures."

#define kTurboOnCryoRoughingOpenG4HighConstraint @"Turbo ON, Cryopump roughing valve OPEN, PKR G4 >2 Torr."
#define kTurboOnCryoRoughingOpenG4HighReason	 @"Opening vacuum sentry could expose turbo pump to potentially damaging pressures."

#define kCryoCondensationConstraint				 @"Cryopump ON."
#define kCryoCondensationReason				     @"Opening purge or roughing valve could cause excessive gas condensation on cryo pump."

#define kRgaOnConstraint						 @"RGA ON."
#define kRgaConstraintReason					 @"Opening valve will expose RGA to potentially damaging pressures."

#define kRgaOnOpenToCryoConstraint				 @"RGA ON, Connected to Cryopump."
#define kRgaOnOpenToCryoReason					 @"Turning cryopump OFF will expose RGA to potentially damaging pressures."

#define kPressureTooHighForCryoConstraint		 @"Pressure > 2E0."
#define kPressureTooHighForCryoReason			 @"Turning Cryopump ON could cause excessive gas condensation on cryo pump."

#define kRoughingValveOpenCryoConstraint		 @"Roughing Valve OPEN."
#define kRoughingValveOpenCryoReason			 @"Turning Cryopump ON could cause excessive gas condensation on cryo pump."

#define k6CFValveOpenCryoConstraint				@"6CF Valve OPEN."
#define k6CFValveOpenCryoReason					@"Turning Cryopump OFF will expose system to cryo pump evaporation."

#define kRgaOnOpenToTurboConstraint				@"RGA ON, Connected to Turbopump."
#define kRgaOnOpenToTurboReason					@"Turning Turbopump OFF would expose RGA filament to potentially damaging pressures."

#define kRgaFilamentConstraint					@"PKR G2 > 5E-6. Too high for RGA Filament"
#define kRgaFilamentReason						@"Filament could be damaged."

#define kRgaCEMConstraint						@"PKR G2 > 5E-7. Too high for CEM"
#define kRgaCEMReason							@"CEM could be damaged."

#define kDetectorBiasedConstraint				@"Detector Biased"
#define kDetectorBiasedReason					@"Detector must be protected from regions with pressure higher than 1E-5."


//-----------------------------------
@interface ORMJDVacuumModel : ORGroup <OROrderedObjHolding,ORAdcProcessor,ORBitProcessor,ORCallBackBitProcessor>
{
	NSMutableDictionary* partDictionary;
	NSMutableDictionary* valueDictionary;
	NSMutableDictionary* statusDictionary;
	NSMutableArray*		 parts;
	BOOL				 showGrid;
	NSMutableArray*		 adcMapArray;
    unsigned long		 vetoMask;
	BOOL				 involvedInProcess;
	BOOL				 constraintCheckScheduled;
    BOOL				 detectorsBiased;
    BOOL				 okToBiasDetector;
    BOOL				 shouldUnbiasDetector;
}

#pragma mark ***Accessors
- (BOOL) shouldUnbiasDetector;
- (void) setShouldUnbiasDetector:(BOOL)aShouldUnbiasDetector;
- (BOOL) okToBiasDetector;
- (BOOL) detectorsBiased;

- (void) setOkToBiasDetector:(BOOL)aOkToBiasDetector;
- (void) setDetectorsBiased:(BOOL)aDetectorsBiased;
- (unsigned long) vetoMask;
- (void) setVetoMask:(unsigned long)aVetoMask;
- (void) setUpImage;
- (void) makeMainController;
- (NSArray*) parts;
- (BOOL) showGrid;
- (void) setShowGrid:(BOOL)aState;
- (void) toggleGrid;
- (int) stateOfGateValve:(int)aTag;
- (NSArray*) pipesForRegion:(int)aTag;
- (ORVacuumPipe*) onePipeFromRegion:(int)aTag;
- (NSArray*) gateValves;
- (ORVacuumGateValve*) gateValve:(int)aTag;
- (NSArray*) valueLabels;
- (NSArray*) statusLabels;
- (NSArray*) staticLabels;
- (NSArray*) gateValvesConnectedTo:(int)aRegion;
- (NSColor*) colorOfRegion:(int)aRegion;
- (NSString*) namesOfRegionsWithColor:(NSColor*)aColor;
- (NSString*) valueLabel:(int)region;
- (NSString*) statusLabel:(int)region;
- (void) openDialogForComponent:(int)i;
- (NSString*) regionName:(int)i;

#pragma mark ***Notificatons
- (void) registerNotificationObservers;
- (void) baratronChanged:(NSNotification*)aNote;
- (void) turboChanged:(NSNotification*)aNote;
- (void) pressureGaugeChanged:(NSNotification*)aNote;
- (void) cryoPumpChanged:(NSNotification*)aNote;
- (void) rgaChanged:(NSNotification*)aNote;
- (void) stateChanged:(NSNotification*)aNote;

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***AdcProcessor Protocol
- (double) setProcessAdc:(int)channel value:(double)value isLow:(BOOL*)isLow isHigh:(BOOL*)isHigh;
- (NSString*) processingTitle;

#pragma mark ***BitProcessor Protocol
- (BOOL) setProcessBit:(int)channel value:(int)value;

#pragma mark ***CallBackBitProcessor Protocol
- (void) mapChannel:(int)aChannel toHWObject:(NSString*)objIdentifier hwChannel:(int)objChannel;
- (void) unMapChannel:(int)aChannel fromHWObject:(NSString*)objIdentifier hwChannel:(int)aHWChannel;
- (void) vetoChangesOnChannel:(int)aChannel state:(BOOL)aState;

#pragma mark •••OROrderedObjHolding Protocol
- (int) maxNumberOfObjects;
- (int) objWidth;
- (int) groupSeparation;
- (NSString*) nameForSlot:(int)aSlot;
- (NSRange) legalSlotsForObj:(id)anObj;
- (int) slotAtPoint:(NSPoint)aPoint;
- (NSPoint) pointForSlot:(int)aSlot;
- (void) place:(id)anObj intoSlot:(int)aSlot;
- (int) slotForObj:(id)anObj;
- (int) numberSlotsNeededFor:(id)anObj;
@end

extern NSString* ORMJDVacuumModelShouldUnbiasDetectorChanged;
extern NSString* ORMJDVacuumModelOkToBiasDetectorChanged;
extern NSString* ORMJDVacuumModelDetectorsBiasedChanged;
extern NSString* ORMJDVacuumModelVetoMaskChanged;
extern NSString* ORMJDVacuumModelPollTimeChanged;
extern NSString* ORMJDVacuumModelShowGridChanged;
extern NSString* ORMJCVacuumLock;


@interface ORMJDVacuumModel (hidden)
//we don't want scripts calling these -- too dangerous
- (void) closeGateValve:(int)aGateValveTag;
- (void) openGateValve:(int)aGateValveTag;
- (id) findGateValveControlObj:(ORVacuumGateValve*)aGateValve;
@end

@interface NSObject (ORMHDVacuumModel)
- (double) convertedValue:(int)aChan;
@end

