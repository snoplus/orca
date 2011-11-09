//--------------------------------------------------------
// ORPacModel
// Created by Mark  A. Howe on Tue Jan 6, 2009
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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

@class ORSerialPort;
@class ORTimeRate;

#define kPacShipAdcs	0xff

//Main Cmd Bytes
#define kPacADCmd		0x01    //--II.
#define kPacSelCmd		0x02	//--III.
#define kPacLcmEnaCmd	0x04	//-->IV.
#define kPacRDacCmd		0x10	//-->V.
//followed by zero or more bytes

//Secondary Cmd Bytes
//II.
#define kPacSelectMask 0x07

//III.
//no further command byte

//IV.
#define kPacLcmEnaSet   0x01		
#define kPacLcmEnaClr   0x02	

//V.
#define kPacRDacWriteAll		0x01 //write all with same value. 2 data words follow		
#define kPacRDacReadAll			0x02 //Read all	
#define kPacRDacWriteOneRDac    0x10 //Write One RDAC.  Position follows (1 Byte) Value Follows (two bytes)	
#define kPacRDacReadOneRDac		0x20 //Read One RDAC.   Position follows (1 Byte) Output of two bytes	

#define kPacOkByte				0xf0
#define kPacErrorByte			0x0f

@interface ORPacModel : OrcaObject <ORAdcProcessing>
{
    @private
        NSString*			portName;
        BOOL				portWasOpen;
        ORSerialPort*		serialPort;
        unsigned long		dataId;
		NSData*				lastRequest;
		NSMutableArray*		cmdQueue;
		NSMutableString*    buffer;
		unsigned long		timeMeasured[8];
		unsigned short		adc[8];
		ORTimeRate*			timeRates[8];
		NSMutableData*		inComingData;
		int					module;
		int					preAmp;
		BOOL				lcmEnabled;
		int					rdacChannel;
		int					dacValue;
		BOOL				setAllRDacs;
		int					rdac[148];
		BOOL				pollRunning;
		NSTimeInterval		pollingState;
		BOOL				logToFile;
		NSString*			logFile;
		NSMutableArray*		logBuffer;
		unsigned long		readCount;
		int					rdacDisplayType;
		NSString*			lastRdacFile;
        BOOL                readOnce;
		float				leakageAlarmLevel[8];
		float				temperatureAlarmLevel[8];
}

#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;
- (void) registerNotificationObservers;
- (void) dataReceived:(NSNotification*)note;

#pragma mark •••Accessors
- (float) temperatureAlarmLevel:(int)index;
- (void) setTemperatureAlarmLevel:(int)index value:(float)aTemperatureAlarmLevel;
- (float) leakageAlarmLevel:(int)index;
- (void) setLeakageAlarmLevel:(int)index value:(float)aLeakageAlarmLevel;
- (NSString*) lastRdacFile;
- (void) setLastRdacFile:(NSString*)aLastRdacFile;
- (int) rdacDisplayType;
- (void) setRdacDisplayType:(int)aRdacDisplayType;
- (ORTimeRate*)timeRate:(int)index;
- (void) setPollingState:(NSTimeInterval)aState;
- (NSTimeInterval) pollingState;
- (int)  rdac:(int)index;
- (void) setRdac:(int)index withValue:(int)aValue;
- (BOOL) setAllRDacs;
- (void) setSetAllRDacs:(BOOL)aSetAllRDacs;
- (int) rdacChannel;
- (void) setRdacChannel:(int)aRdacChannel;
- (BOOL) lcmEnabled;
- (void) setLcmEnabled:(BOOL)aLcmEnabled;
- (int) preAmp;
- (void) setPreAmp:(int)aPreAmp;
- (int) module;
- (void) setModule:(int)aModule;
- (int) dacValue;
- (void) setDacValue:(int)aDacValue;
- (ORSerialPort*) serialPort;
- (void) setSerialPort:(ORSerialPort*)aSerialPort;
- (BOOL) portWasOpen;
- (void) setPortWasOpen:(BOOL)aPortWasOpen;
- (NSString*) portName;
- (void) setPortName:(NSString*)aPortName;
- (NSData*) lastRequest;
- (void) setLastRequest:(NSData*)aRequest;
- (void) openPort:(BOOL)state;
- (unsigned short) adc:(int)index;
- (unsigned long) timeMeasured:(int)index;
- (void) setAdc:(int)index value:(unsigned short)aValue;
- (float) adcVoltage:(int)index;
- (float) convertedAdc:(int)index;
- (NSString*) logFile;
- (void) setLogFile:(NSString*)aLogFile;
- (BOOL) logToFile;
- (void) setLogToFile:(BOOL)aLogToFile;
- (int) queCount;

#pragma mark •••Data Records
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (NSDictionary*) dataRecordDescription;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherPac;
- (void) writeDac;
- (void) readDac;
- (void) selectModule;
- (void) writeLogBufferToFile;

#pragma mark •••Commands
- (void) enqueCmdData:(NSData*)someData;
- (void) enqueReadADC:(int)aChannel;
- (void) enqueWriteDac;
- (void) enqueReadDac;
- (void) enqueLcmEnable;
- (void) enqueModuleSelect;
- (void) enqueWriteRdac:(int)index;

- (void) enqueShipCmd;
- (void) readAdcs;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (void) serialPortWriteProgress:(NSDictionary *)dataDictionary;
- (void) readRdacFile:(NSString*) aPath;
- (void) saveRdacFile:(NSString*) aPath;

#pragma mark •••Adc Processing Protocol
- (void)processIsStarting;
- (void)processIsStopping;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel;
- (double) convertedValue:(int)channel;
- (double) maxValueForChan:(int)channel;


@end

@interface NSObject (ORHistModel)
- (void) removeFrom:(NSMutableArray*)anArray;
@end

extern NSString* ORPacModelAlarmLevelChanged;
extern NSString* ORPacModelRdacDisplayTypeChanged;
extern NSString* ORPacModelSetAllRDacsChanged;
extern NSString* ORPacModelRdacChannelChanged;
extern NSString* ORPacModelLcmEnabledChanged;
extern NSString* ORPacModelPreAmpChanged;
extern NSString* ORPacModelModuleChanged;
extern NSString* ORPacModelDacValueChanged;
extern NSString* ORPacModelSerialPortChanged;
extern NSString* ORPacLock;
extern NSString* ORPacModelPortNameChanged;
extern NSString* ORPacModelPortStateChanged;
extern NSString* ORPacModelAdcChanged;
extern NSString* ORPacModelRDacsChanged;
extern NSString* ORPacModelMultiPlotsChanged;
extern NSString* ORPacModelPollingStateChanged;
extern NSString* ORPacModelLogToFileChanged;
extern NSString* ORPacModelLogFileChanged;
extern NSString* ORPacModelQueCountChanged;

