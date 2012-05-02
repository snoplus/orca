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

@class ORVacuumGateValve;
@class ORVacuumPipe;
@class ORLabJackUE9Model;

@interface ORMJDVacuumModel : OrcaObject <ORAdcProcessor,ORBitProcessor,ORCallBackBitProcessor>
{
	NSMutableDictionary* partDictionary;
	NSMutableArray*		 parts;
	BOOL				 showGrid;
	NSMutableArray*		 adcMapArray;
    unsigned long		 vetoMask;
}

#pragma mark ***Accessors
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
- (NSArray*) dynamicLabels;
- (NSArray*) staticLabels;
- (NSArray*) gateValvesConnectedTo:(int)aRegion;
- (NSColor*) colorOfRegion:(int)aRegion;
- (NSString*) namesOfRegionsWithColor:(NSColor*)aColor;
- (NSString*) dynamicLabel:(int)region;

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

@end

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

