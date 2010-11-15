//
//  ORLabJackModel.h
//  Orca
//
//  Created by Mark Howe on Tues Nov 09,2010.
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
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

#import "ORHPPulserModel.h"
#import "ORUSB.h"

@class ORUSBInterface;
@class ORAlarm;


@interface ORLabJackModel : OrcaObject <USBDevice> {
	NSLock* localLock;
	ORUSBInterface* usbInterface;
    NSString* serialNumber;
	ORAlarm*  noUSBAlarm;
	ORAlarm*  noDriverAlarm;
	int adc[8];
	NSString* channelName[8];   //adc names
	NSString* doName[16];		//the D connector on the side
	NSString* ioName[4];		//on top
	unsigned short doDirection;
	unsigned short ioDirection;
	unsigned short ioValueOut;
	unsigned short doValueOut;
	unsigned short ioValueIn;
	unsigned short doValueIn;
	BOOL	led;
	BOOL	doResetOfCounter;
	//int		count;
    unsigned long counter;
    BOOL digitalOutputEnabled;
}

#pragma mark ***Accessors
- (BOOL) digitalOutputEnabled;
- (void) setDigitalOutputEnabled:(BOOL)aDigitalOutputEnabled;
- (unsigned long) counter;
- (void) setCounter:(unsigned long)aCounter;
- (NSString*) channelName:(int)i;
- (void) setChannel:(int)i name:(NSString*)aName;
- (NSString*) doName:(int)i;
- (void) setDo:(int)i name:(NSString*)aName;
- (NSString*) ioName:(int)i;
- (void) setIo:(int)i name:(NSString*)aName;
- (int) adc:(int)i;
- (void) setAdc:(int)i withValue:(int)aValue;

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

- (void) resetCounter;

- (id) getUSBController;

#pragma mark ***Accessors
- (ORUSBInterface*) usbInterface;
- (void) setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;
- (unsigned long) vendorID;
- (unsigned long) productID;
- (NSString*) usbInterfaceDescription;
- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;
- (void) checkUSBAlarm;


#pragma mark ***HW Access
- (void) updateAll;
- (void) readAdcValues:(int) group;
- (void) sendIoControl;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORLabJackModelDigitalOutputEnabledChanged;
extern NSString* ORLabJackModelCounterChanged;
extern NSString* ORLabJackModelSerialNumberChanged;
extern NSString* ORLabJackModelUSBInterfaceChanged;
extern NSString* ORLabJackModelRelayChanged;
extern NSString* ORLabJackModelLock;
extern NSString* ORLabJackChannelNameChanged;
extern NSString* ORLabJackAdcChanged;
extern NSString* ORLabJackDoNameChanged;
extern NSString* ORLabJackIoNameChanged;
extern NSString* ORLabJackDoDirectionChangedNotification;
extern NSString* ORLabJackIoDirectionChangedNotification;
extern NSString* ORLabJackDoValueOutChangedNotification;
extern NSString* ORLabJackIoValueOutChangedNotification;
extern NSString* ORLabJackDoValueInChangedNotification;
extern NSString* ORLabJackIoValueInChangedNotification;

