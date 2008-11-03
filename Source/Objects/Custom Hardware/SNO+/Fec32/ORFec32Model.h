//
//  ORSNOCardORSNOCard.h
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

@interface ORFec32Model :  ORSNOCard
{
	unsigned char	cmos[6];	//board related	0-ISETA1 1-ISETA0 2-ISETM1 3-ISETM0 4-TACREF 5-VMAX
	unsigned char	vRes;	//VRES for bipolar chip
	unsigned char	hVRef;	//HVREF for high voltage
    NSString*		comments;
    BOOL			showVolts;
}
- (void) setUpImage;
- (void) makeMainController;

#pragma mark •••Accessors
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
@end

extern NSString* ORFec32ModelShowVoltsChanged;
extern NSString* ORFec32ModelCommentsChanged;
extern NSString* ORFecCmosChanged;
extern NSString* ORFecVResChanged;
extern NSString* ORFecHVRefChanged;

extern NSString* ORFecLock;

