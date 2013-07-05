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

#define kApcUpsPort             23
#define kNumApcUpsAdcChannels    8 

@class NetSocket;
@class ORAlarm;
@class ORTimeRate;

@interface ORApcUpsModel : OrcaObject <ORAdcProcessing>
{
	NSLock*     localLock;
    NSString*   ipAddress;
    NSString*   password;
    NSString*   username;
    BOOL        isConnected;
	NetSocket*  socket;
    BOOL        statusSentOnce;
    NSMutableDictionary* singleValueDictionary;
    NSMutableDictionary* phaseDictionary;
    NSMutableDictionary* nameFromChannelTable;
    NSMutableDictionary* channelFromNameTable;
    NSMutableString* inputBuffer;
    NSDate*     lastTimePolled;
    NSDate*     nextPollScheduled;
    ORTimeRate*		timeRate[8];
    BOOL        dataValid;
    ORAlarm*    dataInValidAlarm;
    
    float lowLimit[kNumApcUpsAdcChannels];
    float hiLimit[kNumApcUpsAdcChannels];

}

#pragma mark ***Accessors
- (NetSocket*) socket;
- (void) setSocket:(NetSocket*)aSocket;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aFlag;
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;
- (ORTimeRate*)timeRate:(int)aChannel;
- (void) setDataValid:(BOOL)aState;

#pragma mark ***Utilities
- (void) connect;
- (void) disconnect;
- (void) pollHardware;
- (NSString*) keyForIndexInPowerTable:(int)i;
- (NSString*) nameAtIndexInPowerTable:(int)i;
- (NSString*) keyForIndexInLoadTable:(int)i;
- (NSString*) nameForIndexInLoadTable:(int)i;
- (NSString*) keyForIndexInBatteryTable:(int)i;
- (NSString*) nameForIndexInBatteryTable:(int)i;
- (void) setUpTagDictionaries;
- (id) nameForChannel:(int)aChannel;
- (float) valueForChannel:(int)aChannel;
- (int) channelForName:(NSString*)aName;
- (id) phaseKey:(NSString*)aPhaseKey valueKey:(NSString*)aValueKey;
- (id) valueForKeyInSingleValueDictionary:(NSString*)aKey;
- (NSString*) nameForIndexInProcessTable:(int)i;

- (id) phaseKey:(NSString*)aPhaseKey valueKey:(NSString*)aValueKey;
- (id) valueForKeyInSingleValueDictionary:(NSString*)aKey;

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

@property (retain) NSMutableDictionary* singleValueDictionary;
@property (retain) NSMutableDictionary* phaseDictionary;
@property (assign,nonatomic) BOOL dataValid;
@property (retain,nonatomic) NSString* username;
@property (retain,nonatomic) NSString* password;
@property (retain,nonatomic) NSDate* lastTimePolled;
@property (retain,nonatomic) NSDate* nextPollScheduled;
@end

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