//
//  SNOMonitoredHardware.m
//  Orca
//
//  Created by H S  Wan Chan Tseung on 11/18/11.
//  Copyright (c) 2011 CENPA, University of Washington. All rights reserved.
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

#import "ORSNOConstants.h"

#define kTubeTypeUnknown	0
#define kTubeTypeNormal		1
#define kTubeTypeOwl		2
#define kTubeTypeLowGain	3
#define kTubeTypeDeadTube	4
#define kTubeTypeButt		5
#define kTubeTypeNeck		6
#define kTubeTypeNumofTypes 7

@interface SNOMonitoredHardware : NSObject {
	struct {			//Crate Level
		struct {		//Card Level
			struct {	//Pmt Level
				short tubeType;	//not only the type but tube problems,too.
				float x;
				float y;
				float z;
				float cmosRate;
				float pmtBaseCurrent;
				NSString* pmtID;	
				NSString* cableID;
				NSString* paddleCardID;
			} Pmt[kNumSNOPmts];
			float fecFifo;
		} Card[kNumSNOCards];
		float xl3PacketRate;
	} SNOCrate[kMaxSNOCrates+2];	// + two spares
}

+ (SNOMonitoredHardware*) sharedSNOMonitoredHardware;
- (void) readCableDBDocumentFromOrcaDB;
- (void) readXL3StateDocumentFromMorca;
- (void) decode:(NSString*)chanInfo crate:(int*)crate card:(int*)card channel:(int*) channel;
- (BOOL) getCrate:(int)aCrate card:(int)aCard channel:(int)aChannel x:(float*)x y:(float*)y;
- (int)  tubeTypeCrate:(int)aCrate card:(int)aCard channel:(int)aChannel;
- (float) cmosRate:(int)aCrate card:(int)aCard channel:(int)aChannel;
- (float) baseCurrent:(int)aCrate card:(int)aCard channel:(int)aChannel;
- (float) fifo:(int)aCrate card:(int)aCard;
- (float) xl3Rate:(int)aCrate;
- (float) xpos:(int)aCrate card:(int)aCard channel:(int)aChannel;
- (float) ypos:(int)aCrate card:(int)aCard channel:(int)aChannel;
- (float) zpos:(int)aCrate card:(int)aCard channel:(int)aChannel;
- (NSString*)  pmtID:(int)aCrate card:(int)aCard channel:(int)aChannel;
- (NSColor*)  pmtColor:(int)aCrate card:(int)aCard channel:(int)aChannel;
@end
