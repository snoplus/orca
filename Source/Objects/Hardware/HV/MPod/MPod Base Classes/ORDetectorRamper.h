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
	short         channel;
    
    //user parameters
	short stepWait;
	float lowVoltageThreshold;
	float voltageStep;
	short lowVoltageWait;
	float lowVoltageStep;
	float maxVoltage;
	float minVoltage;
	BOOL  enabled;
    
	//ramp state variables
	float   target;
	BOOL    running;
	int     state;
	NSDate* lastWaitTime;
}

- (id) initWithDelegate:(OrcaObject*)aDelegate channel:(int)aChannel;
- (void) startRamping;
- (void) stopRamping;
- (void) emergencyOff;
- (void) setStepWait:(short)aValue;
- (void) setLowVoltageWait:(short)aValue;
- (void) setLowVoltageThreshold:(float)aValue;
- (void) setLowVoltageStep:(float)aValue;
- (void) setMaxVoltage:(float)aValue;
- (void) setMinVoltage:(float)aValue;
- (void) setVoltageStep:(float)aValue;
- (void) setEnabled:(BOOL)aValue;
- (NSString*) stateString;
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@property (nonatomic,assign) OrcaObject* delegate;
@property (nonatomic,assign) short channel;
@property (nonatomic,assign) short stepWait;
@property (nonatomic,assign) float target;
@property (nonatomic,assign) float lowVoltageThreshold;
@property (nonatomic,assign) float voltageStep;
@property (nonatomic,assign) short lowVoltageWait;
@property (nonatomic,assign) float lowVoltageStep;
@property (nonatomic,assign) float maxVoltage;
@property (nonatomic,assign) float minVoltage;
@property (nonatomic,assign) BOOL enabled;
@property (nonatomic,assign) BOOL running;
@property (nonatomic,assign) int state;
@property (nonatomic,retain) NSDate* lastWaitTime;
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
- (float) target:(int)aChannel;
- (float) writeVoltage:(int)aChannel;
@end
