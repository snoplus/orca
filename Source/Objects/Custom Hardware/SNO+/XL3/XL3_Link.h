//
//  XL3_Link.h
//  ORCA
//
//  Created by Jarek Kaspar on Sat, Jul 9, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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

#import "XL3_Cmds.h"
@class ORSafeCircularBuffer;

typedef enum eXL3_ConnectStates {
	kDisconnected,
	kWaiting,
	kConnected,
	kNumStates //must be last
}
eXL3_CrateStates;


@interface XL3_Link : ORGroup
{
	int         serverSocket;
	int         workingSocket;
	NSLock*		commandSocketLock;	//avoids clashes between commands. Wrap an XL3 packet write,
                                    //so you know a possible write error comes from your command.
	NSLock*		coreSocketLock;		//protects the socket, to guarantee that full packet is read/written
                                    //and that reads and writes do not clash, XL3 is a fixed packet size protocol
	NSLock*		cmdArrayLock;		//cmdArrayLock protects manipulations with the array of command responses
                                    //received from an XL3, to synchronize the threaded worker pushing XL3 responses,
                                    //and XL3Model pulling/distributing the responses
	BOOL		needToSwap;
	NSString*	IPNumber;
	NSString*	crateName;
	unsigned long	portNumber;
	BOOL		isConnected;
    BOOL        autoConnect;
	int		connectState;
	int		errorTimeOut;
	NSCalendarDate*	timeConnected;
	NSMutableArray*	cmdArray;
	unsigned long long num_cmd_packets;
	unsigned long long num_dat_packets;
	XL3_Packet	aMultiCmdPacket;
    
@private
    //memory optimized circular buffer, motivated by ORSafeCirularBuffer. Thanks Mark.
    //XL3_Link allocates and pushes megabundles as NSData, cb stores pointers to NSData*
    //ORXL3_Model takeData memcopies into the data stream and releases
    //it's not design to buffer, it's used to reverse the data stream direction
    //if we went with ORSafeCircularBuffer the 20 pool releases caused noticable interruptions
    NSMutableData*  bundleBuffer;
    unsigned long*	dataPtr;
    unsigned        bundleBufferSize;
    unsigned        bundleReadMark;
    unsigned        bundleWriteMark;
    NSLock*         bundleBufferLock;
    long            bundleFreeSpace;
}

@property (assign)	BOOL    isConnected;
@property (assign)	BOOL    autoConnect;

- (id)   init;
- (void) dealloc;
- (void) wakeUp; 
- (void) sleep ;	

#pragma mark •••DataTaker Helpers
- (BOOL) bundleAvailable;
- (NSMutableData*) readNextBundle;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Accessors
- (int)  serverSocket;
- (void) setServerSocket:(int) aSocket;
- (int)  workingSocket;
- (void) setWorkingSocket:(int) aSocket;
- (BOOL) needToSwap;
- (void) setNeedToSwap;
- (int)  connectState;
- (void) setErrorTimeOut:(int)aValue;
- (int) errorTimeOut;
- (int) errorTimeOutSeconds;
- (void) toggleConnect;
- (NSCalendarDate*) timeConnected;
- (void) setTimeConnected:(NSCalendarDate*)newTimeConnected;
- (NSString*) IPNumber;
- (void) setIPNumber:(NSString*)aIPNumber;
- (unsigned long)  portNumber;
- (void) setPortNumber:(unsigned long)aPortNumber;
- (NSString*) crateName;
- (void) setCrateName:(NSString*)aCrateName;

- (void) newMultiCmd;
- (void) addMultiCmdToAddress:(long)anAddress withValue:(long)aValue;
- (XL3_Packet*) executeMultiCmd;
- (BOOL) multiCmdFailed;

- (void) sendXL3Packet:(XL3_Packet*)aSendPacket;
- (void) sendCommand:(long)aCmd withPayload:(XL3_PayloadStruct*)payloadBlock expectResponse:(BOOL)askForResponse;
- (void) sendCommand:(long)aCmd expectResponse:(BOOL)askForResponse;
- (void) sendFECCommand:(long)aCmd toAddress:(unsigned long)address withData:(unsigned long*)value;
- (void) readXL3Packet:(XL3_Packet*)aPacket withPacketType:(unsigned char)packetType andPacketNum:(unsigned short)packetNum;

- (void) connectSocket;
- (void) disconnectSocket;
- (void) connectToPort;
- (void) writePacket:(char*)aPacket;
- (void) readPacket:(char*)aPacket;
- (BOOL) canWriteTo:(int)aSocket;

@end


extern NSString* XL3_LinkConnectionChanged;
extern NSString* XL3_LinkTimeConnectedChanged;
extern NSString* XL3_LinkIPNumberChanged;
extern NSString* XL3_LinkConnectStateChanged;
extern NSString* XL3_LinkErrorTimeOutChanged;
extern NSString* XL3_LinkAutoConnectChanged;
