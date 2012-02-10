//
//  ORLabJackUE9Model.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 11,2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files

#import "ORAdcProcessing.h"
#import "ORBitProcessing.h"

@class NetSocket;
@class ORLabJackUE9Cmd;

@interface ORLabJackUE9Model : OrcaObject <ORAdcProcessing,ORBitProcessing> {
	NSMutableArray*  cmdQueue;
	ORLabJackUE9Cmd* lastRequest;
	NSString*		 ipAddress;
    BOOL			 isConnected;
	NetSocket*		 socket;
	NSLock*			 localLock;
    NSString*		 serialNumber;
	int adc[8];
	int gain[4];
	float lowLimit[8];
	float hiLimit[8];
	float minValue[8];
	float maxValue[8];
	float slope[8];
	float intercept[8];
	NSString* channelName[8];   //adc names
	NSString* channelUnit[8];   //adc names
	unsigned long timeMeasured;
	NSString* doName[16];		//the D connector on the side
	NSString* ioName[4];		//on top
	unsigned short adcDiff;
	unsigned short doDirection;
	unsigned short ioDirection;
	unsigned short ioValueOut;
	unsigned short doValueOut;
	unsigned short ioValueIn;
	unsigned short doValueIn;
    unsigned short aOut0;
    unsigned short aOut1;
	BOOL	led;
	BOOL	doResetOfCounter;
    unsigned long counter;
    BOOL digitalOutputEnabled;
    int pollTime;
	unsigned long	dataId;
    BOOL shipData;
    BOOL readOnce;
	NSTimeInterval lastTime;
	NSOperationQueue* queue;
	
	double unipolarSlope[4];
	double unipolarOffset[4];
	double bipolarSlope;
	double bipolarOffset;
	double DACSlope[2];
	double DACOffset[2];
	double tempSlope;
	double tempSlopeLow;
	double calTemp;
	double Vref;
	double VrefDiv2;
	double VsSlope;
	double hiResUnipolarSlope;
	double hiResUnipolarOffset;
	double hiResBipolarSlope;
	double hiResBipolarOffset;
	
	//bit processing variables
	unsigned long processInputValue;  //snapshot of the inputs at start of process cycle
	unsigned long processOutputValue; //outputs to be written at end of process cycle
	unsigned long processOutputMask;  //controlls which bits are written
    BOOL involvedInProcess;
    unsigned long deviceSerialNumber;
}

#pragma mark ***Accessors
- (ORLabJackUE9Cmd*) lastRequest;
- (void) setLastRequest:(ORLabJackUE9Cmd*)aRequest;
- (unsigned long) deviceSerialNumber;
- (void) setDeviceSerialNumber:(unsigned long)aDeviceSerialNumber;
- (BOOL) involvedInProcess;
- (void) setInvolvedInProcess:(BOOL)aInvolvedInProcess;
- (void) setAOut0Voltage:(float)aValue;
- (void) setAOut1Voltage:(float)aValue;
- (unsigned short) aOut1;
- (void) setAOut1:(unsigned short)aAOut1;
- (unsigned short) aOut0;
- (void) setAOut0:(unsigned short)aAOut0;
- (BOOL) shipData;
- (void) setShipData:(BOOL)aShipData;
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;
- (BOOL) digitalOutputEnabled;
- (void) setDigitalOutputEnabled:(BOOL)aDigitalOutputEnabled;
- (unsigned long) counter;
- (void) setCounter:(unsigned long)aCounter;
- (NSString*) channelName:(int)i;
- (void) setChannel:(int)i name:(NSString*)aName;
- (NSString*) channelUnit:(int)i;
- (void) setChannel:(int)i unit:(NSString*)aName;
- (NSString*) doName:(int)i;
- (void) setDo:(int)i name:(NSString*)aName;
- (NSString*) ioName:(int)i;
- (void) setIo:(int)i name:(NSString*)aName;
- (int) adc:(int)i;
- (void) setAdc:(int)i withValue:(int)aValue;
- (int) gain:(int)i;
- (void) setGain:(int)i withValue:(int)aValue;
- (float) lowLimit:(int)i;
- (void) setLowLimit:(int)i withValue:(float)aValue;
- (float) hiLimit:(int)i;
- (void) setHiLimit:(int)i withValue:(float)aValue;
- (float) slope:(int)i;
- (void) setSlope:(int)i withValue:(float)aValue;
- (float) intercept:(int)i;
- (void) setIntercept:(int)i withValue:(float)aValue;
- (float) minValue:(int)i;
- (void) setMinValue:(int)i withValue:(float)aValue;
- (float) maxValue:(int)i;
- (void) setMaxValue:(int)i withValue:(float)aValue;

- (unsigned short) adcDiff;
- (void) setAdcDiff:(unsigned short)aMask;
- (void) setAdcDiffBit:(int)bit withValue:(BOOL)aValue;

- (unsigned short) doDirection;
- (void) setDoDirection:(unsigned short)aMask;
- (void) setDoDirectionBit:(int)bit withValue:(BOOL)aValue;

- (unsigned short) ioDirection;
- (void) setIoDirection:(unsigned short)aMask;
- (void) setIoDirectionBit:(int)bit withValue:(BOOL)aValue;

- (unsigned short) doValueOut;
- (void) setDoValueOut:(unsigned short)aMask;
- (void) setDoValueOutBit:(int)bit withValue:(BOOL)aValue;

- (unsigned short) ioValueOut;
- (void) setIoValueOut:(unsigned short)aMask;
- (void) setIoValueOutBit:(int)bit withValue:(BOOL)aValue;

- (unsigned short) doValueIn;
- (void) setDoValueIn:(unsigned short)aMask;
- (void) setDoValueInBit:(int)bit withValue:(BOOL)aValue;
- (NSString*) doInString:(int)bit;
- (NSColor*) doInColor:(int)i;

- (unsigned short) ioValueIn;
- (void) setIoValueIn:(unsigned short)aMask;
- (void) setIoValueInBit:(int)bit withValue:(BOOL)aValue;
- (NSString*) ioInString:(int)bit;
- (NSColor*) ioInColor:(int)i;
- (unsigned long) timeMeasured;

- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherLakeShore210;
- (void) readSerialNumber;

#pragma mark ***IP Stuff
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;
- (NetSocket*) socket;
- (void) setSocket:(NetSocket*)aSocket;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aFlag;
- (void) connect;
- (void) netsocketConnected:(NetSocket*)inNetSocket;
- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount;
- (void) netsocketDisconnected:(NetSocket*)inNetSocket;

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

#pragma mark ***HW Access
- (void) resetCounter;
- (void) queryAll;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

- (void) sendComCmd;
- (void) getCalibrationInfo:(int)block;
- (void) readSingleAdc:(int)aChan;
- (void) feedBack;


- (void) goToNextCommand;
- (void) processOneCommandFromQueue;
- (void) startTimeOut;

@end

extern NSString* ORLabJackUE9ModelDeviceSerialNumberChanged;
extern NSString* ORLabJackUE9ModelInvolvedInProcessChanged;
extern NSString* ORLabJackUE9ModelAOut1Changed;
extern NSString* ORLabJackUE9ModelAOut0Changed;
extern NSString* ORLabJackUE9ShipDataChanged;
extern NSString* ORLabJackUE9PollTimeChanged;
extern NSString* ORLabJackUE9DigitalOutputEnabledChanged;
extern NSString* ORLabJackUE9CounterChanged;
extern NSString* ORLabJackUE9SerialNumberChanged;
extern NSString* ORLabJackUE9RelayChanged;
extern NSString* ORLabJackUE9Lock;
extern NSString* ORLabJackUE9ChannelNameChanged;
extern NSString* ORLabJackUE9ChannelUnitChanged;
extern NSString* ORLabJackUE9AdcChanged;
extern NSString* ORLabJackUE9DoNameChanged;
extern NSString* ORLabJackUE9IoNameChanged;
extern NSString* ORLabJackUE9DoDirectionChanged;
extern NSString* ORLabJackUE9IoDirectionChanged;
extern NSString* ORLabJackUE9DoValueOutChanged;
extern NSString* ORLabJackUE9IoValueOutChanged;
extern NSString* ORLabJackUE9DoValueInChanged;
extern NSString* ORLabJackUE9IoValueInChanged;
extern NSString* ORLabJackUE9HiLimitChanged;
extern NSString* ORLabJackUE9LowLimitChanged;
extern NSString* ORLabJackUE9AdcDiffChanged;
extern NSString* ORLabJackUE9GainChanged;
extern NSString* ORLabJackUE9SlopeChanged;
extern NSString* ORLabJackUE9InterceptChanged;
extern NSString* ORLabJackUE9MinValueChanged;
extern NSString* ORLabJackUE9MaxValueChanged;
extern NSString* ORLabJackUE9IpAddressChanged;
extern NSString* ORLabJackUE9IsConnectedChanged;

@interface ORLabJackUE9Cmd : NSObject
{
	int tag;
	NSData* cmdData;
}
@property (nonatomic,assign) int tag;
@property (nonatomic,retain) NSData* cmdData;
@end
