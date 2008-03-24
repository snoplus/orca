//  ORCalibration.h
//  Orca
//
//  Created by Mark Howe on 3/21/08.
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
//
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

@class ORCalibration;

@interface ORCalibrationPane : NSWindowController 
{
	IBOutlet NSButton*		ignoreButton;
	IBOutlet NSButton*		calibrateButton;
	IBOutlet NSForm*		channelForm;
	IBOutlet NSForm*		valueForm;
	IBOutlet NSTextField*	unitsField;
	
	id						objectToCalibrate;
	NSDictionary*			contextInfo;
}

+ (id) calibrateForWindow:(NSWindow *)aWindow modalDelegate:(id)aDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(id)aContextInfo;

- (id) initWithContext:(id)aContext;
- (void) beginSheetFor:(NSWindow *)aWindow delegate:(id)aDelegate didEndSelector:(SEL)aDidEndSelector contextInfo:(id)aContextInfo;
- (void) calibrate;
- (void) setContext:(NSDictionary*)someContext;

- (IBAction) apply:(id)sender;
- (IBAction) done:(id)sender;
- (IBAction) cancel:(id)sender;
@end

@interface ORCalibration : NSObject 
{
	NSArray*		calibrationArray;
	float			slope;
	float			intercept;
	NSString*		units;
	BOOL			calibrationValid;
	BOOL			ignoreCalibration;
}

- (id) initCalibrationArray:(NSArray*)calArray;
- (NSArray*)calibrationArray;
- (float) slope;
- (float) intercept;
- (void) calibrate;
- (BOOL) ignoreCalibration;
- (void) setIgnoreCalibration:(BOOL)aState;
- (BOOL) useCalibration;
- (NSString*) units;
- (void) setUnits:(NSString*)unitString;
- (float) convertedValueForChannel:(float)aChannel;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

@interface NSObject (ORCalibration)
- (id) calibration;
- (void) setCalibration:(id)aCalibration;
- (void) postUpdate;
@end
