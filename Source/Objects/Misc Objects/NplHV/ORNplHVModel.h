//
//  ORNplHVModel.h
//  Orca
//
//  Created by Mark Howe on Thurs Dec 6 2007
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

#define kNplHVPort 5000


@class NetSocket;
@class ORAlarm;

@interface ORNplHVModel : OrcaObject {
	NSLock* localLock;
    int connectionProtocol;
    NSString* ipAddress;
    BOOL isConnected;
	NetSocket* socket;
    NSString* cmdString;
}

#pragma mark ***Accessors
- (NSString*) cmdString;
- (void) setCmdString:(NSString*)aCmdString;
- (NetSocket*) socket;
- (void) setSocket:(NetSocket*)aSocket;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aFlag;
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;

#pragma mark ***Utilities
- (void) connect;
- (void) sendCmd:(NSString*)aCmd;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORNplHVModelCmdStringChanged;
extern NSString* ORNplHVModelIsConnectedChanged;
extern NSString* ORNplHVModelIpAddressChanged;
