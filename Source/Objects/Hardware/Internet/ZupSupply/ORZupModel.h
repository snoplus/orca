//
//  ORZupModel.h
//  Orca
//
//  Created by Mark Howe on Monday March 16,2009
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

#import "ORRamperModel.h"
#import "ORHWWizard.h"

#define kZupCurrentAdc		0x0
#define kZupVoltageAdc		0x1
#define kZupDac				0x2
#define kZupStatusControl	0x3


//reg defs for ADC AD7734
#define kZupCommReg			0x0
#define kZupIOPort			0x1
#define kZupRevision			0x2
#define kZupTest				0x3
#define kZupIOAdcStatus		0x4
#define kZupCheckSum			0x5
#define kZupAdc0ScaleCalib	0x6
#define kZupAdcFullScale		0x7
#define kZupChanData			0x8
#define kZupChan0ScaleCal		0x10
#define kZupChanFSCal			0x18
#define kZupChanStatus		0x20
#define kZupChanSetup			0x28
#define kZupChanConvTime		0x30
#define kZupMode				0x38

#define kNplHvRead				0x40
#define kNplHvWrite				0x00

@class ORSerialPort;

@interface ORZupModel : ORRamperModel
{
	NSString*			portName;
	BOOL				portWasOpen;
	ORSerialPort*		serialPort;
	NSData*				lastRequest;
	NSMutableArray*		cmdQueue;
	NSMutableData*		inComingData;
	NSMutableString*    buffer;
	float voltage;
}

#pragma mark ***Accessors
- (float) voltage:(int)dummy;
- (void) setVoltage:(int)dummy withValue:(float)aValue;
- (SEL) getMethodSelector;
- (SEL) setMethodSelector;
- (SEL) initMethodSelector;
- (void) junk;
- (void) setVoltageReg:(int)aReg chan:(int)aChan value:(int)aValue;
- (void) setCurrentReg:(int)aReg chan:(int)aChan value:(int)aValue;
- (int) numberOfChannels;
- (void) initBoard;
- (void) loadDac:(int)dummy;

- (void) dataReceived:(NSNotification*)note;
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

#pragma mark ***Utilities
- (void) sendCmd;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORZupLock;
extern NSString* ORZupModelSerialPortChanged;
extern NSString* ORZupModelPortStateChanged;
extern NSString* ORZupModelPortNameChanged;

