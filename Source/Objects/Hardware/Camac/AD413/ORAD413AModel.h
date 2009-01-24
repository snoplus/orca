/*
 *  ORAD413AModel.h
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

 
#pragma mark ¥¥¥Imported Files
#import "ORCamacIOCard.h"
#import "ORDataTaker.h"

@class ORDataPacket;

enum {
    kZeroSuppressionBit = 8,
    kECLPortEnableBit   = 9,
    kCoincidenceBit     = 12,
    kRandomAccessBit    = 13,
    kLAMEnableBit       = 14,
    kOFSuppressionBit   = 15,
    kEnableGate1Bit     = 0,
    kEnableGate2Bit     = 1,
    kEnableGate3Bit     = 2,
    kEnableGate4Bit     = 3,
    kMasterGateBit      = 4,

};


@interface ORAD413AModel : ORCamacIOCard <ORDataTaker,ORFeraReadout> {
    @private
        unsigned long dataId;
        unsigned short onlineMask;
		NSMutableArray* discriminators;
		unsigned short controlReg1;
		unsigned short controlReg2;
        
        //place to cache some stuff for alittle more speed.
        unsigned long 	unChangingDataPart;
        unsigned short cachedStation;
        BOOL  randomAccessMode;
        BOOL  zeroSuppressionMode;
		BOOL  eclMode;
        short onlineChannelCount;
        short onlineList[8];
        
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;
        
#pragma mark ¥¥¥Accessors
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (NSMutableArray *) discriminators;
- (void) setDiscriminators: (NSMutableArray *) anArray;

- (unsigned char)   onlineMask;
- (void)	    setOnlineMask:(unsigned char)anOnlineMask;
- (BOOL)	    onlineMaskBit:(int)bit;
- (void)	    setOnlineMaskBit:(int)bit withValue:(BOOL)aValue;
- (void)        setDiscriminator:(unsigned short)aValue forChan:(int)aChan;
- (unsigned short) discriminatorForChan:(int)aChan;
- (unsigned short) controlReg1;
- (void)        setControlReg1: (unsigned short) aControlReg1;
- (unsigned short) controlReg2;
- (void)        setControlReg2: (unsigned short) aControlReg2;

#pragma mark ¥¥¥Hardware functions
- (void) readControlReg1;
- (void) readControlReg2;
- (void) writeControlReg1;
- (void) writeControlReg2;
- (void) readDiscriminators;
- (void) writeDiscriminators;
- (void) clearModule;
- (void) clearLAM;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;

#pragma mark ¥¥¥FERA
- (void) setVSN:(int)aVSN;
- (void) shipFeraData:(void*)ptr length:(int)len;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORAD413AOnlineMaskChangedNotification;
extern NSString* ORAD413ASettingsLock;
extern NSString* ORAD413ADiscriminatorChangedNotification;
extern NSString* ORAD413AControlReg1ChangedNotification;
extern NSString* ORAD413AControlReg2ChangedNotification;
