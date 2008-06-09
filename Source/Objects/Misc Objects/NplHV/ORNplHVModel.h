//
//  ORNplHVModel.h
//  Orca
//
//  Created by Mark Howe on Wed Jun 4 2008
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

#import "ORRamperModel.h"
#import "ORHWWizard.h"

#define kNplHVPort 5000

@class NetSocket;

@interface ORNplHVModel : ORRamperModel <ORHWWizard,ORHWRamping> {
    NSString* ipAddress;
    BOOL isConnected;
	NetSocket* socket;
    int board;
    int channel;
    int functionNumber;
    int writeValue;
	int dac[8];
	int adc[8];
	int current[8];
	int controlReg[8];
}

#pragma mark ***Accessors
- (int) writeValue;
- (void) setWriteValue:(int)aWriteValue;
- (int) functionNumber;
- (void) setFunctionNumber:(int)aFunction;
- (int) channel;
- (void) setChannel:(int)aChannel;
- (int) board;
- (void) setBoard:(int)aBoard;
- (NetSocket*) socket;
- (void) setSocket:(NetSocket*)aSocket;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aFlag;
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;

- (int) adc:(int)aChan;
- (void) setAdc:(int)channel withValue:(int)aValue;
- (int) dac:(int)aChan;
- (void) setDac:(int)channel withValue:(int)aValue;
- (int) current:(int)aChan;
- (void) setCurrent:(int)channel withValue:(int)aValue;
- (int) controlReg:(int)aChan;
- (void) setControlReg:(int)channel withValue:(int)aValue;
- (SEL) getMethodSelector;
- (SEL) setMethodSelector;
- (SEL) initMethodSelector;
- (void) junk;
- (void) loadDac:(int)aChan;

#pragma mark ***Utilities
- (void) connect;
- (void) sendCmd;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORNplHVLock;
extern NSString* ORNplHVModelWriteValueChanged;
extern NSString* ORNplHVModelFunctionChanged;
extern NSString* ORNplHVModelChannelChanged;
extern NSString* ORNplHVModelBoardChanged;
extern NSString* ORNplHVModelCmdStringChanged;
extern NSString* ORNplHVModelIsConnectedChanged;
extern NSString* ORNplHVModelIpAddressChanged;
