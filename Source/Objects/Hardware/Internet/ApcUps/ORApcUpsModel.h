//
//  ORApcUpsModel.h
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORAdcProcessing.h"

#define kApcPollTime            60*10
#define kApcUpsPort             23
#define kNumApcUpsAdcChannels    7

@class ORAlarm;
@class ORTimeRate;

@interface ORApcUpsModel : OrcaObject <ORAdcProcessing>
{
    NSString*   ipAddress;
    NSString*   password;
    NSString*   username;
    BOOL        statusSentOnce;
    NSMutableDictionary* valueDictionary;

    NSMutableDictionary* channelFromNameTable;
    NSDate*              lastTimePolled;
    NSDate*              nextPollScheduled;
    ORTimeRate*          timeRate[8];
    BOOL                 dataValid;
    ORAlarm*             dataInValidAlarm;
    NSOperationQueue*    fileQueue;
    NSMutableSet*        eventLog;
    
    float lowLimit[kNumApcUpsAdcChannels];
    float hiLimit[kNumApcUpsAdcChannels];

}

#pragma mark ***Accessors
- (NSMutableSet*) eventLog;
- (void) setEventLog:(NSMutableSet*)aEventLog;
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;
- (ORTimeRate*)timeRate:(int)aChannel;
- (void) setDataValid:(BOOL)aState;
- (void) clearEventLog;

#pragma mark ***Utilities
- (void) pollHardware;
- (NSString*) nameAtIndexInPowerTable:(int)i;
- (NSString*) nameForIndexInLoadTable:(int)i;
- (NSString*) nameForIndexInBatteryTable:(int)i;
- (id) nameForChannel:(int)aChannel;
- (float) valueForChannel:(int)aChannel;
- (int) channelForName:(NSString*)aName;
- (NSString*) nameForIndexInProcessTable:(int)i;

- (id) valueForKeyInValueDictionary:(NSString*)aKey;
- (NSString*) valueForPowerPhase:(int)aPhaseIndex powerTableIndex:(int)aRowIndex;
- (NSString*) valueForLoadPhase:(int)aLoadIndex loadTableIndex:(int)aRowIndex;
- (NSString*) valueForBattery:(int)aLoadIndex batteryTableIndex:(int)aRowIndex;

- (void) checkAlarms;
- (BOOL) isConnected;
- (void) setUpQueue;
- (void) getEvents;
- (void) getData;

#pragma mark •••Process Limits
- (float) lowLimit:(int)i;
- (void)  setLowLimit:(int)i value:(float)aValue;
- (float) hiLimit:(int)i;
- (void)  setHiLimit:(int)i value:(float)aValue;

#pragma mark •••Bit Processing Protocol
- (void) startProcessCycle;
- (void) endProcessCycle;
- (void) processIsStarting;
- (void) processIsStopping;
- (NSString*) identifier;
- (NSString*) processingTitle;
- (BOOL) processValue:(int)channel;
- (double) convertedValue:(int)aChan;
- (void) setProcessOutput:(int)aChan value:(int)aValue;
- (double) maxValueForChan:(int)aChan;
- (double) minValueForChan:(int)aChan;
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@property (retain) NSMutableDictionary* valueDictionary;
@property (assign,nonatomic) BOOL dataValid;
@property (retain,nonatomic) NSString* username;
@property (retain,nonatomic) NSString* password;
@property (retain,nonatomic) NSDate* lastTimePolled;
@property (retain,nonatomic) NSDate* nextPollScheduled;
@end

extern NSString* ORApcUpsModelEventLogChanged;
extern NSString* ORApcUpsIsConnectedChanged;
extern NSString* ORApcUpsIpAddressChanged;
extern NSString* ORApcUpsUsernameChanged;
extern NSString* ORApcUpsPasswordChanged;
extern NSString* ORApcUpsRefreshTables;
extern NSString* ORApcUpsPollingTimesChanged;
extern NSString* ORApcUpsDataValidChanged;
extern NSString* ORApcUpsTimedOut;
extern NSString* ORApcUpsLock;
extern NSString* ORApcUpsHiLimitChanged;
extern NSString* ORApcUpsLowLimitChanged;