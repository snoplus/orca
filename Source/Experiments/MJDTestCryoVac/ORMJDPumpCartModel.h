//
//  ORMJDPumpCartModel.h
//  Orca
//
//  Created by Mark Howe on Mon Aug 13, 2012.
//  Copyright ¬© 2012 CENPA, University of North Carolina. All rights reserved.
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
@class ORAlarm;
@class ORMJDTestCryostat;

//-----------------------------------
//region definitions
#define kRegionDiaphramPump	0
#define kRegionBelowTurbo	1
#define kRegionAboveTurbo	2
#define kRegionRGA			3
#define kRegionDryN2		4
#define kRegionLeftSide		5
#define kRegionRightSide	6

#define kNumberRegions	    10
//-----------------------------------
//component tag numbers
#define kTurboComponent			0
#define kRGAComponent			1
#define kCryoPumpComponent		2
#define kPressureGaugeComponent 3

//-----------------------------------
@interface ORMJDPumpCartModel : ORGroup <OROrderedObjHolding,ORAdcProcessor>
{
	NSMutableDictionary* partDictionary;
	NSMutableDictionary* valueDictionary;
	NSMutableDictionary* statusDictionary;
	NSMutableArray*		 parts;
	BOOL				 showGrid;
	BOOL				 involvedInProcess;
	NSMutableArray*		 testCryostats;
}

#pragma mark ***Accessors

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
- (ORMJDTestCryostat*) testCryoStat:(int)i;

#pragma mark ***Notificatons
- (void) registerNotificationObservers;
- (void) turboChanged:(NSNotification*)aNote;
- (void) pressureGaugeChanged:(NSNotification*)aNote;
- (void) rgaChanged:(NSNotification*)aNote;

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***AdcProcessor Protocol
- (double) setProcessAdc:(int)channel value:(double)value isLow:(BOOL*)isLow isHigh:(BOOL*)isHigh;
- (NSString*) processingTitle;

#pragma mark ***CallBackBitProcessor Protocol
- (void) mapChannel:(int)aChannel toHWObject:(NSString*)objIdentifier hwChannel:(int)objChannel;
- (void) unMapChannel:(int)aChannel fromHWObject:(NSString*)objIdentifier hwChannel:(int)aHWChannel;

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
- (BOOL) detectorsBiased;

@end

extern NSString* ORMJDPumpCartModelShowGridChanged;
extern NSString* ORMJCTestCryoVacLock;


@interface NSObject (ORMHDVacuumModel)
- (double) convertedValue:(int)aChan;
@end

