//
//  OReRamper.h
//  Orca
//
//  Created by Mark Howe on Friday May 25,2012
//  Copyright (c) 2012 University of North Carolina. All rights reserved.
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

@interface ORDetectorRamper : NSObject {
	OrcaObject*	  delegate;
	short channel;
	short stepWait;
	float lowVoltageThreshold;
	float voltageStep;
	short lowVoltageWait;
	float lowVoltageStep;
	float maxVoltage;
	float minVoltage;
	BOOL  enabled;
	//ramp state variables
	float  currentStep;
	float nextVoltage;
	BOOL  running;
	int   state;
	NSDate* lastWaitTime;
}

- (id) initWithDelegate:(OrcaObject*)aDelegate channel:(int)aChannel;

@property (assign) OrcaObject* delegate;
@property (assign) short channel;
@property (assign) short stepWait;
@property (assign) float lowVoltageThreshold;
@property (assign) float voltageStep;
@property (assign) short lowVoltageWait;
@property (assign) float lowVoltageStep;
@property (assign) float maxVoltage;
@property (assign) float minVoltage;
@property (assign) BOOL enabled;
@property (assign) BOOL running;
@property (assign) int state;
@property (retain) NSDate* lastWaitTime;
@end

extern NSString* ORDetectorRamperStepWaitChanged;
extern NSString* ORDetectorRamperLowVoltageWaitChanged;
extern NSString* ORDetectorRamperLowVoltageThresholdChanged;
extern NSString* ORDetectorRamperLowVoltageStepChanged;
extern NSString* ORDetectorRamperMaxVoltageChanged;
extern NSString* ORDetectorRamperMaxVoltageChanged;
extern NSString* ORDetectorRamperVoltageStepChanged;
extern NSString* ORDetectorRamperEnabledChanged;
extern NSString* ORDetectorRamperStateChanged;
extern NSString* ORDetectorRamperRunningChanged;

@interface NSObject (ORDetectorRamper)
- (BOOL) isOn:(int)aChannel;
- (float) hwGoal:(int)aChannel;
- (void) setHwGoal:(int)aChannel withValue:(float)aValue;
- (float) voltage:(int)aChannel;
- (float) writeVoltage:(int)aChannel;
@end
