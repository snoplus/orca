//
//  ORAdcModel.h
//  Orca
//
//  Created by Mark Howe on 11/25/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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



#import "ORProcessHWAccessor.h"
#import "ORProcessNub.h"

@class ORAdcLowLimitNub;
@class ORAdcHighLimitNub;
@class CTGradient;

@interface ORAdcModel : ORProcessHWAccessor {
	double hwValue;
	double maxValue;
	double minValue;
	double lowLimit;
	double highLimit;
	BOOL valueTooLow;
	BOOL valueTooHigh;
	ORAdcLowLimitNub*  lowLimitNub;
	ORAdcHighLimitNub* highLimitNub;
    float minChange;
    NSString* displayFormat;
    NSString* customLabel;
    int labelType;
    int viewIconType;
	CTGradient* normalGradient;
	CTGradient* alarmGradient;
}

#pragma mark ***Accessors
- (int) viewIconType;
- (void) setViewIconType:(int)aViewIconType;
- (int) labelType;
- (void) setLabelType:(int)aLabelType;
- (NSString*) customLabel;
- (void) setCustomLabel:(NSString*)aCustomLabel;
- (NSImage*) altImage;
- (NSString*) displayFormat;
- (void) setDisplayFormat:(NSString*)aDisplayFormat;
- (float) minChange;
- (void) setMinChange:(float)aMinChange;
- (void) dealloc;

- (BOOL) valueTooLow;
- (BOOL) valueTooHigh;
- (double) lowLimit;
- (double) highLimit;
- (double) hwValue;
- (double) maxValue;
- (void) viewSource;

- (float) evalAndReturnAnalogValue;

- (BOOL) acceptsClickAtPoint:(NSPoint)aPoint;
- (BOOL) intersectsRect:(NSRect) aRect;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORAdcModelViewIconTypeChanged;
extern NSString* ORAdcModelLabelTypeChanged;
extern NSString* ORAdcModelCustomLabelChanged;
extern NSString* ORAdcModelDisplayFormatChanged;
extern NSString* ORAdcModelMinChangeChanged;

@interface ORAdcLowLimitNub : ORProcessNub
- (int) eval;
- (int) evaluatedState;
@end

@interface ORAdcHighLimitNub : ORProcessNub
- (int) eval;
- (int) evaluatedState;
@end
