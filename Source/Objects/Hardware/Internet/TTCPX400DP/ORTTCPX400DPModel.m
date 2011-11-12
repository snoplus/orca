//
//  ORTTCPX400DPModel.m
//  Orca
//
//  Created by Michael Marino on Thurs Nov 10 2011.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORTTCPX400DPModel.h"
#import "NetSocket.h"

NSString* ORTTCPX400DPDataHasArrived = @"ORTTCPX400DPDataHasArrived";
NSString* ORTTCPX400DPConnectionHasChanged = @"ORTTCPX400DPConnectionHasChanged";
NSString* ORTTCPX400DPIpHasChanged = @"ORTTCPX400DPIpHasChanged";
NSString* ORTTCPX400DPModelLock = @"ORTTCPX400DPModelLock";

@interface ORTTCPX400DPModel (private)
- (void) _connectIP;
- (void) _mainThreadSocketSend:(NSString*) data;
- (void) _setIsConnected:(BOOL)connected;
@end

@implementation ORTTCPX400DPModel

struct ORTTCPX400DPCmdInfo {
	NSString* name;
	NSString* cmd;
	BOOL responds;
	BOOL takesOutputNum;
	BOOL takesInput;
	NSString* responseFormat;
};

static struct ORTTCPX400DPCmdInfo gORTTCPXCmds[kNumTTCPX400Cmds] = {
    {@"Set Voltage", @"V%i %f", NO, YES, YES, @""}, //kSetVoltage,
    {@"Set Voltage/Verify", @"V%iV %f", NO, YES, YES, @""}, //kSetVoltageAndVerify,
    {@"Set Over Voltage Protection", @"OVP%i %f", NO, YES, YES, @""}, //kSetOverVoltageProtectionTripPoint,
    {@"Set Current Limit", @"I%i %f", NO, YES, YES, @""}, //kSetCurrentLimit,
    {@"Set Over Current Protection", @"OCP%i %f", NO, YES, YES, @""}, //kSetOverCurrentProtectionTripPoint,
    {@"Get Voltage Set Point", @"V%i?", YES, YES, NO, @"V%i %f"}, //kGetVoltageSet,
    {@"Get Current Set Point", @"I%i?", YES, YES, NO, @"I%i %f"}, //kGetCurrentSet,
    {@"Get Voltage Trip Point", @"OVP%i?", YES, YES, NO, @"VP%i %f"}, //kGetVoltageTripSet,
    {@"Get Current Trip Point", @"OCP%i?", YES, YES, NO, @"CP%i %f"}, //kGetCurrentTripSet,
    {@"Get Voltage Readback", @"V%iO?", YES, YES, NO, @"%fV"}, //kGetVoltageReadback,
    {@"Get Current Readback", @"C%iO?", YES, YES, NO, @"%fA"}, //kGetCurrentReadback,
    {@"Set Voltage Step Size", @"DELTAV%i %f", NO, YES, YES, @""}, //kSetVoltageStepSize,
    {@"Set Current Step Size", @"DELTAI%i %f", NO, YES, YES, @""}, //kSetCurrentStepSize,
    {@"Get Voltage Step Size", @"DELTAV%i?", YES, YES, YES, @"DELTAV%i %f"}, //kGetVoltageStepSize,
    {@"Get Current Step Size", @"DELTAI%i?", YES, YES, YES, @"DELTAI%i %f"}, //kGetCurrentStepSize,
    {@"Increment Voltage", @"INCV%i", NO, YES, NO, @""}, //kIncrementVoltage,
    {@"Increment Voltage and Verify", @"INCV%iV", NO, YES, NO, @""}, //kIncrementVoltageAndVerify,
    {@"Decrement Voltage", @"DECVV%i", NO, YES, NO, @""}, //kDecrementVoltage,
    {@"Decrement Voltage and Verify", @"DECV%iV", NO, YES, NO, @""}, //kDecrementVoltageAndVerify,
    {@"Increment Current", @"INCI%i", NO, YES, NO, @""}, //kIncrementCurrent,
    {@"Decrement Current", @"DECI%i", NO, YES, NO, @""}, //kDecrementCurrent,
    {@"Set Output", @"OP%i %f", NO, YES, YES, @""}, //kSetOutput,
    {@"Set All Output", @"OPALL %f", NO, NO, YES, @""}, //kSetAllOutput,
    {@"Get Output Status", @"OP%i?", YES, YES, NO, @""}, //kGetOutputStatus,
    {@"Clear Trip", @"TRIPRST", NO, NO, NO, @""}, //kClearTrip,
    {@"Go Local", @"LOCAL", NO, NO, NO, @""}, //kLocal,
    {@"Request Lock", @"IFLOCK", YES, NO, NO, @"%f"}, //kRequestLock,
    {@"Check Lock", @"IFLOCK?", YES, NO, NO, @"%f"}, //kCheckLock,
    {@"Release Lock", @"IFUNLOCK", YES, NO, NO, @"%f"}, //kReleaseLock,
    {@"Query and Clear LSR", @"LSR%i?", YES, YES, NO, @"%f"}, //kQueryClearLSR,
    {@"Set LSE", @"LSE%i %f", NO, YES, YES, @""}, //kSetEventStatusRegister,
    {@"Get LSE", @"LSE%i?", YES, YES, NO, @"%f"}, //kGetEventStatusRegister,
    {@"Save Setup", @"SAV%i %f", NO, YES, YES, @""}, //kSaveCurrentSetup,
    {@"Recall Setup", @"RCL%i %f", NO, YES, YES, @""}, //kRecallSetup,
    {@"Set Operating Mode", @"CONFIG %f", NO, NO, YES, @""}, //kSetOperatingMode,
    {@"Get Operating Mode", @"CONFIG?", YES, NO, NO, @"%f"}, //kGetOperatingMode,
    {@"Set Ratio", @"RATIO %f", NO, NO, YES, @""}, //kSetRatio,
    {@"Get Ratio", @"RATIO?", YES, NO, NO, @"%f"}, //kGetRatio,
    {@"Clear Status", @"*CLS", NO, NO, NO, @""}, //kClearStatus,
    {@"Query and Clear EER", @"EER?", YES, NO, NO, @"%f"}, //kQueryAndClearEER,
    {@"Set ESE", @"*ESE %f", NO, NO, YES, @""}, //kSetESE,
    {@"Get ESE", @"*ESE?", YES, NO, NO, @"%f"}, //kGetESE,
    {@"Get ESR", @"*ESR?", YES, NO, NO, @"%f"}, //kGetESR,
    {@"Get IST Local", @"*IST?", YES, NO, NO, @"%f"}, //kGetISTLocalMsg,
    {@"Set Operation Complete Bit", @"*OPC", NO, NO, NO, @""}, //kSetOPCBit,
    {@"Get Operation Complete Bit", @"*OPC?", YES, NO, NO, @"%f"}, //kGetOPCBit,
    {@"Set Parallel Poll Enable", @"*PRE %f", NO, NO, YES, @""}, //kSetParallelPollRegister,
    {@"Get Parallel Poll Enable", @"*PRE?", YES, NO, NO, @"%f"}, //kGetParallelPollRegister,
    {@"Query and Clear QER", @"QER?", YES, NO, NO, @"%f"}, //kQueryAndClearQER,
    {@"Reset", @"*RST", NO, NO, NO, @""}, //kResetToRemoteDflt,
    {@"Set Service Rqst Enable", @"*SRE%f", NO, NO, YES, @""}, //kSetSRE,
    {@"Get Service Rqst Enable", @"*SRE?", YES, NO, NO, @"%f"}, //kGetSRE,
    {@"Get Status Byte", @"*STB?", YES, NO, NO, @"%f"}, //kGetSTB,
    {@"Get Identity", @"*IDN?", YES, NO, NO, @"%s"}, //kGetID,
    {@"Get Address", @"ADDRESS?", YES, NO, NO, @"%s"} //kGetBusAddress
};



@synthesize socket;
@synthesize ipAddress;
@synthesize port;
@synthesize mostRecentData;

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"TTCPX400DP"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORTTCPX400DPController"];
}

- (void) setSocket:(NetSocket*)aSocket
{
	if(aSocket != socket)[socket close];
	[aSocket retain];
	[socket release];
	socket = aSocket;
	[socket setDelegate:self];
}

- (void) setIpAddress:(NSString *)anIp 
{
    [anIp retain];
    [ipAddress release];
    ipAddress = anIp;
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:ORTTCPX400DPIpHasChanged
     object:self];   
}

- (void) connect
{
	if(!isConnected && !socket) [self _connectIP]; 
}

- (void) _connectIP
{
	if(!isConnected){
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:port]];	
	}
}

- (void) _setIsConnected:(BOOL)connected
{
    if (isConnected == connected) return;
    isConnected = connected;
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:ORTTCPX400DPConnectionHasChanged 
     object:self];
}

- (BOOL) isConnected
{
    return isConnected;
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
	if(inNetSocket != socket) return;
	isConnected = [socket isConnected];
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
	if(inNetSocket != socket) return;
	NSString* theString = [[inNetSocket readString:NSASCIIStringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[self setMostRecentData:theString];
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
	if(inNetSocket == socket){
		[self _setIsConnected:[socket isConnected]];
		[self _setIsConnected:NO];
		[socket autorelease];
		socket = nil;
	}
	// Forward it if the other delegate wants this info
    /*
	if ([delegate respondsToSelector:selector(netsocketDisconnected:)]) {
		[delegate netsocketDisconnected:];
         }
     */
}

#pragma mark ***Comm methods

- (int) read:(void*)data maxLengthInBytes:(NSUInteger)len
{
    return 0;
}

- (void) write: (NSString*) aCommand
{
	if([self isConnected]){
		[self performSelectorOnMainThread:@selector(_mainThreadSocketSend:) withObject:aCommand waitUntilDone:YES];
	}
	else {
		NSString *errorMsg = @"Must establish IP connection prior to issuing command.\n";
        NSLog(errorMsg);
		
	} 			
}

- (void) _mainThreadSocketSend:(NSString*)aCommand
{
	if(!aCommand)aCommand = @"";
	[socket writeString:aCommand encoding:NSASCIIStringEncoding];
}

- (NSString*) serialNumber
{
    return @"";
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self setIpAddress:[decoder decodeObjectForKey:@"ipAddress"]];
    [self setPort:[decoder decodeIntForKey:@"portNumber"]];

	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
 	[encoder encodeObject:ipAddress	forKey:@"ipAddress"];
    [encoder encodeInt:port forKey:@"portNumber"];    
}



@end
