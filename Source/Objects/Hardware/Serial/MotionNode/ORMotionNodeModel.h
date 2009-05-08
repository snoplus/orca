//
//  ORMotionNodeModel.h
//  Orca
//
//  Created by Mark Howe on Fri Apr 24, 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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
#import "ORSerialPortModel.h"

@class ORAlarm;
@class ORSafeQueue;

enum {
	kMotionNodeConnectResponse,
	kMotionNodeMemoryContents,
	kMotionNodeStop,
	kMotionNodeStart,
	kMotionNodeClosePort,
	kNumMotionNodeCommands
};

typedef struct MotionNodeCommands {
	int			cmdNumber;
	NSString*   command;
	int			expectedLength;
	BOOL		okToTimeOut;
} MotionNodeCommands; 

#define kModeNodeTraceLength 1024

@interface ORMotionNodeModel : ORSerialPortModel {
    BOOL			nodeRunning;
	NSMutableData*	inComingData;
	ORSafeQueue*	cmdQueue;
	id				lastRequest;
    NSString*		serialNumber;
	NSLock*			localLock;
	ORAlarm*		noDriverAlarm;
    int				nodeVersion;
    BOOL			isAccelOnly;
    int				packetLength;
    float			ax;
    float			ay;
    float			az;
    int				traceIndex;
	float			xTrace[kModeNodeTraceLength];
	float			yTrace[kModeNodeTraceLength];
	float			zTrace[kModeNodeTraceLength];
	float			xyzTrace[kModeNodeTraceLength];
	float			xAve;
	float			yAve;
	float			zAve;
	float			xyzAve;
	BOOL			dump;
	int				throttle;
	float			temperatureAverage;
    float			temperature;
    float			totalxyz;
	BOOL			displayComponents;
    BOOL			showDeltaFromAve;
}

#pragma mark ***Accessors
- (BOOL) showDeltaFromAve;
- (void) setShowDeltaFromAve:(BOOL)aShowDeltaFromAve;
- (float) displayComponents;
- (void) setDisplayComponents:(BOOL)aState;
- (float) temperature;
- (void) setTemperature:(float)aTemperature;
- (BOOL) nodeRunning;
- (void) setNodeRunning:(BOOL)aNodeRunning;
- (float) totalxyzAt:(int)i;
- (float) axAt:(int)i;
- (float) ayAt:(int)i;
- (float) azAt:(int)i;
- (float) axDeltaAveAt:(int)i;
- (float) ayDeltaAveAt:(int)i;
- (float) azDeltaAveAt:(int)i;
- (float) xyzDeltaAveAt:(int)i;

- (int) traceIndex;
- (int) packetLength;
- (void) setPacketLength:(int)aPacketLength;
- (BOOL) isAccelOnly;
- (void) setIsAccelOnly:(BOOL)aIsAccelOnly;
- (int) nodeVersion;
- (void) setNodeVersion:(int)aVersion;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;
- (id) lastRequest;
- (void) setLastRequest:(id)aCmd;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***HW Commands
- (void) initDevice;
- (void) stopDevice;
- (void) startDevice;
- (void) readOnboardMemory;
- (void) readConnect;

#pragma mark •••Port Methods
- (void) dataReceived:(NSNotification*)note;
@end

extern NSString* ORMotionNodeModelShowDeltaFromAveChanged;
extern NSString* ORMotionNodeModelTemperatureChanged;
extern NSString* ORMotionNodeModelNodeRunningChanged;
extern NSString* ORMotionNodeModelTraceIndexChanged;
extern NSString* ORMotionNodeModelPacketLengthChanged;
extern NSString* ORMotionNodeModelIsAccelOnlyChanged;
extern NSString* ORMotionNodeModelVersionChanged;
extern NSString* ORMotionNodeModelLock;
extern NSString* ORMotionNodeModelSerialNumberChanged;
extern NSString* ORMotionNodeModelDisplayComponentsChanged;

