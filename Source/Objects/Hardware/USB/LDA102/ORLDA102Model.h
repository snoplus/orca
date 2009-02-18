//
//  ORLDA102Model.h
//  Orca
//
//  Created by Mark Howe on Thurs Jan 26 2007.
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

#import "ORHPPulserModel.h"
#import "ORUSB.h"

@class ORUSBInterface;
@class ORAlarm;

@interface ORLDA102Model : OrcaObject <USBDevice> {
	NSLock* localLock;
	ORUSBInterface* usbInterface;
    NSString* serialNumber;
	ORAlarm*  noUSBAlarm;
	ORAlarm*  noDriverAlarm;
    short attenuation;
    float stepSize;
    float rampStart;
    float rampEnd;
    int dwellTime;
    int idleTime;
	
	//Thread variables
	BOOL threadRunning;
	BOOL timeToStop;
}

- (id) getUSBController;

#pragma mark ***Accessors
- (int) idleTime;
- (void) setIdleTime:(int)aIdleTime;
- (int) dwellTime;
- (void) setDwellTime:(int)aDwellTime;
- (float) rampEnd;
- (void) setRampEnd:(float)aRampEnd;
- (float) rampStart;
- (void) setRampStart:(float)aRampStart;
- (float) stepSize;
- (void) setStepSize:(float)aStepSize;
- (float) attenuation;
- (void) setAttenuation:(float)aAttenuation;
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
- (void) writeCommand:(unsigned char)cmdWord count:(unsigned char)count data:(unsigned char*)contents;

#pragma mark ***Thread methods
- (void) startReadThread;
- (void) stopReadThread;
- (void) decodeResponse:(unsigned char*)data;
- (void) responseThread;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORLDA102ModelIdleTimeChanged;
extern NSString* ORLDA102ModelDwellTimeChanged;
extern NSString* ORLDA102ModelRampEndChanged;
extern NSString* ORLDA102ModelRampStartChanged;
extern NSString* ORLDA102ModelStepSizeChanged;
extern NSString* ORLDA102ModelAttenuationChanged;
extern NSString* ORLDA102ModelSerialNumberChanged;
extern NSString* ORLDA102ModelUSBInterfaceChanged;
extern NSString* ORLDA102ModelRelayChanged;
extern NSString* ORLDA102ModelLock;
extern NSString* ORLDA102ModelSerialPortChanged;

