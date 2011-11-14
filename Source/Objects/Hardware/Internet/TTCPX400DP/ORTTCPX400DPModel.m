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

#define ORTTCPX400DPPort 9221

NSString* ORTTCPX400DPDataHasArrived = @"ORTTCPX400DPDataHasArrived";
NSString* ORTTCPX400DPConnectionHasChanged = @"ORTTCPX400DPConnectionHasChanged";
NSString* ORTTCPX400DPIpHasChanged = @"ORTTCPX400DPIpHasChanged";
NSString* ORTTCPX400DPModelLock = @"ORTTCPX400DPModelLock";
NSString* ORTTCPX400DPGeneralReadbackHasChanged = @"ORTTCPX400DPGeneralReadbackHasChanged";

struct ORTTCPX400DPCmdInfo;

@interface ORTTCPX400DPModel (private)
- (void) _connectIP;
- (void) _mainThreadSocketSend:(NSString*) data;
- (void) _setIsConnected:(BOOL)connected;
- (void) _addCommandToDataProcessingQueue:(struct ORTTCPX400DPCmdInfo*)cmd;
- (void)  _processNextCmdWithInputString:(NSString *)input withSelectorName:(NSString*)selName;
- (void) _writeCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutput:(int)output withSelectorName:(NSString*)selName;
- (void) _processGeneralReadback:(NSNumber*)aFloat withOutputNum:(NSNumber*) anInt;
- (void) _processGeneralReadback:(NSNumber*)aFloat;
- (void) _setGeneralReadback:(NSString*)read;
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

//#define ORTTCPXFunctionsForCmd(cmd) \
//- (void) 
static struct ORTTCPX400DPCmdInfo gORTTCPXCmds[kNumTTCPX400Cmds] = {
    {@"Set Voltage", @"V%i %f", NO, YES, YES, @""}, //kSetVoltage,
    {@"Set Voltage/Verify", @"V%iV %f", NO, YES, YES, @""}, //kSetVoltageAndVerify,
    {@"Set Over Voltage Protection", @"OVP%i %f", NO, YES, YES, @""}, //kSetOverVoltageProtectionTripPoint,
    {@"Set Current Limit", @"I%i %f", NO, YES, YES, @""}, //kSetCurrentLimit,
    {@"Set Over Current Protection", @"OCP%i %f", NO, YES, YES, @""}, //kSetOverCurrentProtectionTripPoint,
    {@"Get Voltage Set Point", @"V%i?", YES, YES, NO, @"V%i %f"}, //kGetVoltageSet,
    {@"Get Current Set Point", @"I%i?", YES, YES, NO, @"I%i %f"}, //kGetCurrentSet,
    // These next two should be the following
    //{@"Get Voltage Trip Point", @"OVP%i?", YES, YES, NO, @"VP%i %f"}, //kGetVoltageTripSet,
    //{@"Get Current Trip Point", @"OCP%i?", YES, YES, NO, @"CP%i %f"}, //kGetCurrentTripSet,
    // But I have instead found them to be:
    {@"Get Voltage Trip Point", @"OVP%i?", YES, YES, NO, @"%f"}, //kGetVoltageTripSet,
    {@"Get Current Trip Point", @"OCP%i?", YES, YES, NO, @"%f"}, //kGetCurrentTripSet,
    
    {@"Get Voltage Readback", @"V%iO?", YES, YES, NO, @"%fV"}, //kGetVoltageReadback,
    {@"Get Current Readback", @"I%iO?", YES, YES, NO, @"%fA"}, //kGetCurrentReadback,
    {@"Set Voltage Step Size", @"DELTAV%i %f", NO, YES, YES, @""}, //kSetVoltageStepSize,
    {@"Set Current Step Size", @"DELTAI%i %f", NO, YES, YES, @""}, //kSetCurrentStepSize,
    {@"Get Voltage Step Size", @"DELTAV%i?", YES, YES, NO, @"DELTAV%i %f"}, //kGetVoltageStepSize,
    {@"Get Current Step Size", @"DELTAI%i?", YES, YES, NO, @"DELTAI%i %f"}, //kGetCurrentStepSize,
    {@"Increment Voltage", @"INCV%i", NO, YES, NO, @""}, //kIncrementVoltage,
    {@"Increment Voltage and Verify", @"INCV%iV", NO, YES, NO, @""}, //kIncrementVoltageAndVerify,
    {@"Decrement Voltage", @"DECV%i", NO, YES, NO, @""}, //kDecrementVoltage,
    {@"Decrement Voltage and Verify", @"DECV%iV", NO, YES, NO, @""}, //kDecrementVoltageAndVerify,
    {@"Increment Current", @"INCI%i", NO, YES, NO, @""}, //kIncrementCurrent,
    {@"Decrement Current", @"DECI%i", NO, YES, NO, @""}, //kDecrementCurrent,
    {@"Set Output", @"OP%i %f", NO, YES, YES, @""}, //kSetOutput,
    {@"Set All Output", @"OPALL %f", NO, NO, YES, @""}, //kSetAllOutput,
    {@"Get Output Status", @"OP%i?", YES, YES, NO, @"%f"}, //kGetOutputStatus,
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

- (id) init
{
    self = [super init];
    [self setIpAddress:@""];
    return self;
}

- (void) dealloc
{
    [socket release];
    [ipAddress release];
    [dataQueue release];
    [generalReadback release];
}

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
    [[[self undoManager] prepareWithInvocationTarget:self] 
     setIpAddress:ipAddress];
    
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
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:ORTTCPX400DPPort]];	
	}
}

- (void) _setIsConnected:(BOOL)connected
{
    if (isConnected == connected) return;
    isConnected = connected;
    // Also release the dataQueue
    [dataQueue release];
    dataQueue = nil;
    
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:ORTTCPX400DPConnectionHasChanged 
     object:self];
}

- (void) _addCommandToDataProcessingQueue:(struct ORTTCPX400DPCmdInfo *)cmd withSelectorName:(NSString*) selName;
{
    // We take pointers, but we know the pointers always exist.
    if (selName == nil) selName = @"";
    @synchronized(self) {
        if (dataQueue == nil) {
            dataQueue = [[NSMutableArray array] retain];
        }
        [dataQueue addObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLong:(unsigned long)cmd],selName,nil]];
    }
}

- (void) _processNextCmdWithInputString:(NSString *)input
{
    struct ORTTCPX400DPCmdInfo* cmd = nil;
    SEL callSelector = nil;    
    @synchronized(self) {
        if ([dataQueue count] > 0) {
            cmd = (struct ORTTCPX400DPCmdInfo*)[[[dataQueue objectAtIndex:0] objectAtIndex:0] longValue];
            callSelector = NSSelectorFromString([[dataQueue objectAtIndex:0] objectAtIndex:1]);
            [dataQueue removeObjectAtIndex:0];
        }
    }
    // we don't need to synchronize this part necessarily.
    if (cmd == nil) return;
    // This command absolutely needs to respond
    assert(cmd->responds);
    float readBackValue = 0;
    int outputNum;   
    
    int numberOfOutputs = [[cmd->responseFormat componentsSeparatedByString:@"%"] count] - 1;
    switch (numberOfOutputs) {
        case 1:
            if (sscanf([input cStringUsingEncoding:NSASCIIStringEncoding], 
                       [cmd->responseFormat cStringUsingEncoding:NSASCIIStringEncoding],&readBackValue) != 1) {
                NSLog(@"Error parsing input string (%@) with format (%@)",input,cmd->responseFormat);
                return;
            }        
            if (callSelector) {
                [self performSelector:callSelector withObject:[NSNumber numberWithFloat:readBackValue]];
            } 
            break;
        case 2:

            if (sscanf([input cStringUsingEncoding:NSASCIIStringEncoding], 
                       [cmd->responseFormat cStringUsingEncoding:NSASCIIStringEncoding],&outputNum,&readBackValue) != 2) {
                NSLog(@"Error parsing input string (%@) with format (%@)\n",input,cmd->responseFormat);
                return;
            }
            if (callSelector) {
                [self performSelector:callSelector withObject:[NSNumber numberWithFloat:readBackValue] withObject:[NSNumber numberWithInt:outputNum] ];
            }
            break;
        default:
            assert((numberOfOutputs != 1 && numberOfOutputs != 2));
            break;
    }
}

- (void) _processGeneralReadback:(NSNumber*)aFloat withOutputNum:(NSNumber*) anInt
{
    [self _setGeneralReadback:[NSString stringWithFormat:@"Output %i: %f",[anInt intValue],[aFloat floatValue]]];
}

- (void) _processGeneralReadback:(NSNumber*)aFloat
{
    [self _setGeneralReadback:[NSString stringWithFormat:@"%f",[aFloat floatValue]]];
}

- (void) _setGeneralReadback:(NSString *)read
{
    [read retain];
    [generalReadback release];
    generalReadback = read;
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:ORTTCPX400DPGeneralReadbackHasChanged
     object:self];
}

- (BOOL) isConnected
{
    return isConnected;
}

- (NSString*) generalReadback
{
    if (generalReadback == nil) return @"";
    return generalReadback;
}

#pragma mark ***General Querying
- (int) numberOfCommands
{
    return kNumTTCPX400Cmds;
}
- (NSString*) commandName:(ETTCPX400DPCmds)cmd
{
    return gORTTCPXCmds[cmd].name;        
}
- (BOOL) commandTakesInput:(ETTCPX400DPCmds)cmd
{
    return gORTTCPXCmds[cmd].takesInput;    
}
- (BOOL) commandTakesOutputNumber:(ETTCPX400DPCmds)cmd
{
    return gORTTCPXCmds[cmd].takesOutputNum;
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
	if(inNetSocket != socket) return;
	[self _setIsConnected:[socket isConnected]];
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
	if(inNetSocket != socket) return;
	NSString* theString = [[inNetSocket readString:NSASCIIStringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[self _processNextCmdWithInputString:theString];
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

- (void) writeCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutputNumber:(int)output
{
    [self _writeCommand:cmd withInput:input withOutput:output withSelectorName:nil];
}

- (void) _writeCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutput:(int)output withSelectorName:(NSString*)selName
{
    NSString* cmdStr = [self commandStringForCommand:cmd withInput:input withOutputNumber:output];
    
    if ([cmdStr isEqualToString:@""]) {
        return;
    }
    struct ORTTCPX400DPCmdInfo* theCmd = &gORTTCPXCmds[cmd];
    if (theCmd->responds) {
        if (selName == nil){
            int numberOfOutputs = [[theCmd->responseFormat componentsSeparatedByString:@"%"] count] - 1;
            switch (numberOfOutputs) {
                case 1:
                    selName = NSStringFromSelector(@selector(_processGeneralReadback:));
                    break;
                case 2:
                    selName = NSStringFromSelector(@selector(_processGeneralReadback:withOutputNum:));
                    break;                    
                default:
                    assert((numberOfOutputs != 1 && numberOfOutputs != 2));
                    break;
            }
        }
        [self _addCommandToDataProcessingQueue:theCmd withSelectorName:selName];
    }
    [self write:cmdStr];
    if(!theCmd->responds) [self _setGeneralReadback:@"N/A"];
}

- (NSString*) commandStringForCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutputNumber:(int)output
{
    if (cmd >= kNumTTCPX400Cmds) {
        // Throw an exception?
        return @"";
    }
    struct ORTTCPX400DPCmdInfo* theCmd = &gORTTCPXCmds[cmd];
    NSString* cmdStr;
    if (theCmd->takesOutputNum) {
        if (output != 1 && output != 2) {
            // Throw an exception?
            return @"";
        }
        if (theCmd->takesInput) {
            cmdStr = [NSString stringWithFormat:theCmd->cmd,output,input];
        } else {
            cmdStr = [NSString stringWithFormat:theCmd->cmd,output];
        }
    } else {
        if (theCmd->takesInput) {
            cmdStr = [NSString stringWithFormat:theCmd->cmd,input];
        } else {
            cmdStr = [NSString stringWithString:theCmd->cmd];
        }        
    }  
    return cmdStr;
}

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
