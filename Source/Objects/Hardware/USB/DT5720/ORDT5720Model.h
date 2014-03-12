//
//  ORDT5720Model.h
//  Orca
//
//  Created by Mark Howe on Wed Mar 12,2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina at the Center sponsored in part by the United States
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

#import "ORUsbDeviceModel.h"
#import "ORUSB.h"
#import "ORDataTaker.h"

@class ORUSBInterface;
@class ORAlarm;
@class ORDataSet;

enum {
	kNumberDT5720Registers
};

typedef struct DT5720Registers {
	NSString*       regName;
	unsigned long 	addressOffset;
} DT5720Registers;

@interface ORDT5720Model : ORUsbDeviceModel <USBDevice,ORDataTaker> {
	unsigned long   dataId;
	ORUSBInterface* usbInterface;
 	ORAlarm*		noUSBAlarm;
    NSString*		serialNumber;
}

#pragma mark ***Accessors
- (id) getUSBController;
- (ORUSBInterface*) usbInterface;
- (void) setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;
- (unsigned long) vendorID;
- (unsigned long) productID;
- (NSString*) usbInterfaceDescription;
- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;

#pragma mark ***Comm methods
- (void) checkUSBAlarm;
- (void) initBoard:(int)index;

#pragma mark •••Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORDT5720ModelSerialNumberChanged;
extern NSString* ORDT5720ModelUSBInterfaceChanged;
extern NSString* ORDT5720ModelLock;


