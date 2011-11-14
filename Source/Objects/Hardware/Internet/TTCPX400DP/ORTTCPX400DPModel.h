//
//  ORTTCPX400DPModel.h
//  Orca
//
//  Created by Michael Marino on Thurs Nov 10 2011.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORTcpIpProtocol.h"
#import "OrcaObject.h"

typedef enum {
  kSetVoltage,
  kSetVoltageAndVerify,
  kSetOverVoltageProtectionTripPoint,
  kSetCurrentLimit,
  kSetOverCurrentProtectionTripPoint,
  kGetVoltageSet,
  kGetCurrentSet,
  kGetVoltageTripSet,
  kGetCurrentTripSet,
  kGetVoltageReadback,
  kGetCurrentReadback,
  kSetVoltageStepSize,
  kSetCurrentStepSize,
  kGetVoltageStepSize,
  kGetCurrentStepSize,
  kIncrementVoltage,
  kIncrementVoltageAndVerify,
  kDecrementCurrent,
  kDecrementVoltage,
  kDecrementVoltageAndVerify,
  kIncrementCurrent,
  kSetOutput,
  kSetAllOutput,
  kGetOutputStatus,
  kClearTrip,
  kLocal,
  kRequestLock,
  kCheckLock,
  kReleaseLock,
  kQueryClearLSR,
  kSetEventStatusRegister,
  kGetEventStatusRegister,
  kSaveCurrentSetup,
  kRecallSetup,
  kSetOperatingMode,
  kGetOperatingMode,
  kSetRatio,
  kGetRatio,
  kClearStatus,
  kQueryAndClearEER,
  kSetESE,
  kGetESE,
  kGetESR,
  kGetISTLocalMsg,
  kSetOPCBit,
  kGetOPCBit,
  kSetParallelPollRegister,
  kGetParallelPollRegister,
  kQueryAndClearQER,
  kResetToRemoteDflt,
  kSetSRE,
  kGetSRE,
  kGetSTB,
  //kWaitUntilComplete,
  kGetID,
  kGetBusAddress,
  kNumTTCPX400Cmds
} ETTCPX400DPCmds;

@interface ORTTCPX400DPModel : OrcaObject<ORTcpIpProtocol> {
	NetSocket* socket;
	NSString* ipAddress;
	BOOL isConnected;
	id delegate;
    NSUInteger port;
    NSString* generalReadback;
    NSMutableArray* dataQueue;
}

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

- (NSString*) serialNumber;

- (void) writeCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutputNumber:(int)output;

- (NSString*) commandStringForCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutputNumber:(int)output;

#pragma mark ***General Querying
- (NSString*) generalReadback;
- (int) numberOfCommands;
- (NSString*) commandName:(ETTCPX400DPCmds)cmd;
- (BOOL) commandTakesInput:(ETTCPX400DPCmds)cmd;
- (BOOL) commandTakesOutputNumber:(ETTCPX400DPCmds)cmd;
@end

extern NSString* ORTTCPX400DPDataHasArrived;
extern NSString* ORTTCPX400DPConnectionHasChanged;
extern NSString* ORTTCPX400DPModelLock;
extern NSString* ORTTCPX400DPIpHasChanged;
extern NSString* ORTTCPX400DPGeneralReadbackHasChanged;
