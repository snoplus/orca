//
//  ORTDS2024Model.h
//  Orca
//  Created by Mark Howe on Mon, May 9, 2018.
//  Copyright (c) 2018 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
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
#import "ORTDS2024Model.h"
#import "ORUSB.h"
#import "ORGroup.h"

@class ORUSBInterface;
@class ORAlarm;

@interface ORTDS2024Model : ORGroup <USBDevice> {
    BOOL curveIsBusy;
	NSLock*         localLock;
	ORUSBInterface* usbInterface;
    NSString*       serialNumber;
	ORAlarm*        noUSBAlarm;
	BOOL            okToCheckUSB;
	ORAlarm*		timeoutAlarm;
	int				timeoutCount;
    int             pollTime;
    int             selectedChannel;
    int             numPoints[4];
    int             waveForm[4][2600];
}

- (id) getUSBController;
- (NSArray*) usbInterfaces;
- (void) checkNoUsbAlarm;

#pragma mark ***Accessors
- (int)  selectedChannel;
- (void) setSelectedChannel:(int)aChan;
- (int)  pollTime;
- (void) setPollTime:(int)aPollTime;
- (ORUSBInterface*) usbInterface;
- (void) setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;
- (BOOL) curveIsBusy;

- (unsigned long) vendorID;
- (unsigned long) productID;
- (NSString*) usbInterfaceDescription;
- (void) connectionChanged;

#pragma mark •••Cmd Handling
- (void) cancelTimeout;
- (void) startTimeout:(int)aDelay;
- (void) setTimeoutCount:(int)aValue;
- (void) timeout;
- (void) clearTimeoutAlarm;
- (void) postTimeoutAlarm;
- (int) timeoutCount;

- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;
- (long) readFromDevice: (char*) aData maxLength: (long) aMaxLength;
- (void) writeToDevice: (NSString*) aCommand;
- (void) queryAll;

- (void) readIDString;
- (void) readWaveformPreamble;
- (void) pollHardware;
- (void) getCurve;
- (void) readDataInfo;
- (int) numPoints:(int)index;
- (long) dataSet:(int)index valueAtChannel:(int)x;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORTDS2024SelectedChannelChanged;
extern NSString* ORTDS2024SerialNumberChanged;
extern NSString* ORTDS2024USBInterfaceChanged;
extern NSString* ORTDS2024Lock;
extern NSString* ORTDS2024PortClosedAfterTimeout;
extern NSString* ORTDS2024TimeoutCountChanged;
extern NSString* ORTDS2024PollTimeChanged;
extern NSString* ORWaveFormDataChanged;
