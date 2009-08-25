//
//  ORAmrelHVModel.h
//  Orca
//
//  Created by Mark Howe on Thursday, Aug 20,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark •••Imported Files

#import "OrcaObject.h"

#define kNumAmrelHVChannels 2

@class ORSerialPort;

@interface ORAmrelHVModel : OrcaObject
{
	NSString*			portName;
	BOOL				portWasOpen;
	ORSerialPort*		serialPort;
	NSData*				lastRequest;
	NSMutableArray*		cmdQueue;
	NSMutableData*		inComingData;
	NSMutableString*    buffer;
	unsigned long		dataId;
	int					pollTime;
    BOOL				outputState[2];
	float				voltage[2];
	float				actVoltage[2];
	float				actCurrent[2];
	float				maxCurrent[2];
	BOOL				polarity[2];
	BOOL				rampRate[2];
	BOOL				statusChanged; 
    int					numberOfChannels;
}

#pragma mark ***Accessors
- (BOOL) outputState:(unsigned short)aChan;
- (void) setOutputState:(unsigned short)aChan withValue:(BOOL)aOutputState;
- (int) rampRate:(unsigned short)aChan;
- (void) setRampRate:(unsigned short)aChan withValue:(int)aRate;
- (int) numberOfChannels;
- (void) setNumberOfChannels:(int)aNumberOfChannels;
- (float) voltage:(unsigned short) aChan;
- (void)  setVoltage:(unsigned short) aChan withValue:(float) aVoltage;
- (float) actVoltage:(unsigned short) aChan;
- (void)  setActVoltage:(unsigned short) aChan withValue:(float) aVoltage;
- (float) actCurrent:(unsigned short) aChan;
- (void)  setActCurrent:(unsigned short) aChan withValue:(float) aCurrent;
- (BOOL) polarity:(unsigned short) aChan;
- (void)  setPolarity:(unsigned short) aChan withValue:(BOOL) aState;
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;

- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;

- (ORSerialPort*) serialPort;
- (void) setSerialPort:(ORSerialPort*)aSerialPort;
- (BOOL) portWasOpen;
- (void) setPortWasOpen:(BOOL)aPortWasOpen;
- (NSString*) portName;
- (void) setPortName:(NSString*)aPortName;
- (NSData*) lastRequest;
- (void) setLastRequest:(NSData*)aRequest;
- (void) openPort:(BOOL)state;
- (void) serialPortWriteProgress:(NSDictionary *)dataDictionary;

#pragma mark •••Header Stuff
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (NSDictionary*) dataRecordDescription;

#pragma mark •••HW Commands
- (void) getID;
- (void) getActualVoltage:(int)aChannel;
- (void) getActualCurrent:(int)aChannel;
- (void) getOutput:(int)aChannel;
- (void) setOutput:(int)aChannel withValue:(BOOL)aState;
- (void) dataReceived:(NSNotification*)note;
- (void) loadHardware:(int)aChannel;
- (void) pollHardware;
- (void) getAllValues;

- (void) shipVoltageRecords;

#pragma mark ***Utilities
- (void) sendCmd:(NSString*)aCommand;
- (void) sendCmd:(NSString*)aCommand channel:(short)aChannel;
- (void) sendCmd:(NSString*)aCommand channel:(short)aChannel value:(float)aValue;
- (void) sendCmd:(NSString*)aCommand channel:(short)aChannel boolValue:(BOOL)aValue;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORAmrelHVModelOutputStateChanged;
extern NSString* ORAmrelHVModelNumberOfChannelsChanged;
extern NSString* ORAmrelHVSetVoltageChanged;
extern NSString* ORAmrelHVActVoltageChanged;
extern NSString* ORAmrelHVPollTimeChanged;
extern NSString* ORAmrelHVActCurrentChanged;
extern NSString* ORAmrelHVMaxCurrentChanged;

extern NSString* ORAmrelHVLock;
extern NSString* ORAmrelHVModelSerialPortChanged;
extern NSString* ORAmrelHVModelPortStateChanged;
extern NSString* ORAmrelHVModelPortNameChanged;
extern NSString* ORAmrelHVModelPolarityChanged;
extern NSString* ORAmrelHVModelRampRateChanged;

