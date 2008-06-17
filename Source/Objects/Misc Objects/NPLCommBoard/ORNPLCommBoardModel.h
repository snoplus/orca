//
//  ORNPLCommBoardModel.h
//  Orca
//
//  Created by Mark Howe on Fri Jun 13 2008
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

#define kNPLCommBoardPort 5000

@class NetSocket;

@interface ORNPLCommBoardModel : OrcaObject {
    NSString* ipAddress;
    BOOL isConnected;
	NetSocket* socket;
    int board;
    int channel;
    int functionNumber;
    int writeValue;
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
- (void) sendB:(int)b s:(int)s f:(int)f controlReg:(int)aReg valueLen:(int)len value:(int)aValue;

#pragma mark ***Utilities
- (void) connect;
- (void) sendCmd;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORNPLCommBoardLock;
extern NSString* ORNPLCommBoardModelWriteValueChanged;
extern NSString* ORNPLCommBoardModelFunctionChanged;
extern NSString* ORNPLCommBoardModelChannelChanged;
extern NSString* ORNPLCommBoardModelBoardChanged;
extern NSString* ORNPLCommBoardModelIsConnectedChanged;
extern NSString* ORNPLCommBoardModelIpAddressChanged;
