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
#import "ORVXI11HardwareFinder.h"

#define ORTTCPX400DPPort 9221

NSString* ORTTCPX400DPDataHasArrived = @"ORTTCPX400DPDataHasArrived";
NSString* ORTTCPX400DPConnectionHasChanged = @"ORTTCPX400DPConnectionHasChanged";
NSString* ORTTCPX400DPIpHasChanged = @"ORTTCPX400DPIpHasChanged";
NSString* ORTTCPX400DPSerialNumberHasChanged = @"ORTTCPX400DPSerialNumberHasChanged";
NSString* ORTTCPX400DPModelLock = @"ORTTCPX400DPModelLock";
NSString* ORTTCPX400DPGeneralReadbackHasChanged = @"ORTTCPX400DPGeneralReadbackHasChanged";

struct ORTTCPX400DPCmdInfo;

@interface ORTTCPX400DPModel (private)
- (void) _connectIP;
- (void) _mainThreadSocketSend:(NSString*) data;
- (void) _setIsConnected:(BOOL)connected;
- (void) _addCommandToDataProcessingQueue:(struct ORTTCPX400DPCmdInfo*)theCmd 
                           withSendString:(NSString*)cmdStr 
                   withReturnSelectorName:(NSString*)selName
                        withOutputNumber:(unsigned int)output;    
- (void) _processNextReadCommandInQueueWithInputString:(NSString *)input;
- (void) _processNextWriteCommandInQueue;
- (void) _writeCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutputNum:(int)output withSelectorName:(NSString*)selName;
- (void) _processGeneralReadback:(NSNumber*)aFloat withOutputNum:(NSNumber*) anInt;
- (void) _processGeneralReadback:(NSNumber*)aFloat;
- (void) _setGeneralReadback:(NSString*)read;

@end

#define STRINGIFY2( x) #x
#define STRINGIFY(x) STRINGIFY2(x)
#define NSSTRINGIFY(b) @b

#define ORTTCPX400DP_NOTIFY_STRING(X)     \
NSString* X = NSSTRINGIFY( STRINGIFY(X));

#define ORTTCPX_READ_IMPLEMENT_NOTIFY(CMD)  \
ORTTCPX400DP_NOTIFY_STRING( ORTTCPX_NOTIFY_READ_FORM(CMD) )

#define ORTTCPX_WRITE_IMPLEMENT_NOTIFY(CMD) \
ORTTCPX400DP_NOTIFY_STRING( ORTTCPX_NOTIFY_WRITE_FORM(CMD) )

#define ORTTCPX_GEN_IMPLEMENT(CMD, TYPE, PREPENDFUNC, UC, LC, PREPENDVAR)   \
- (void) PREPENDFUNC##set##UC##PREPENDVAR##CMD:(TYPE)aVal                   \
    withOutput:(unsigned int)output                                         \
{                                                                           \
    assert(output < kORTTCPX400DPOutputChannels);                           \
    if (LC ## PREPENDVAR ## CMD[output] == aVal) return;                    \
    [[[self undoManager] prepareWithInvocationTarget:self]                  \
     PREPENDFUNC##set##UC##PREPENDVAR##CMD:LC ## PREPENDVAR ## CMD[output]  \
     withOutput:output];                                                    \
    LC ## PREPENDVAR ## CMD[output] = aVal;                                 \
    [self sendCommand ## UC ## PREPENDVAR ## CMD ## WithOutput:output];     \
    [[NSNotificationCenter defaultCenter]                                   \
     postNotificationName:ORTTCPX400DP ##UC##PREPENDVAR ## CMD ## IsChanged \
     object:self];                                                          \
}                                                                           \
                                                                            \
- (void) _processCmd ## CMD ## WithFloat:(NSNumber*)theFloat                \
   withOutput:(NSNumber*)theOutput                                          \
{                                                                           \
    assert(gORTTCPXCmds[k ## CMD].responds);                                \
    [self PREPENDFUNC##set##UC##PREPENDVAR##CMD:[theFloat TYPE ## Value]    \
        withOutput:([theOutput intValue]-1)];                               \
}                                                                           \
                                                                            \
- (void) PREPENDFUNC ## write ## CMD ## WithOutput:(unsigned int)output     \
{                                                                           \
    assert(output < kORTTCPX400DPOutputChannels);                           \
    NSString* temp = nil;                                                   \
    if (gORTTCPXCmds[k ## CMD].responds) {                                  \
        temp = NSStringFromSelector(                                        \
                     @selector(_processCmd ## CMD ## WithFloat:withOutput:));\
    }                                                                       \
    [self _writeCommand:k ## CMD withInput:LC ## PREPENDVAR ## CMD[output]  \
          withOutputNum:output+1                                            \
       withSelectorName:temp];                                              \
}                                                                           \
                                                                            \
- (TYPE) LC ## PREPENDVAR ## CMD ## WithOutput:(unsigned int)output         \
{                                                                           \
    return LC ## PREPENDVAR ## CMD[output];                                 \
}                                                                           \
- (void) sendCommand ## UC ## PREPENDVAR ## CMD ## WithOutput:              \
    (unsigned int) output                                                   \
{                                                                           \
    [self PREPENDFUNC ## write ## CMD ## WithOutput:output];                \
}                                                                           

#define ORTTCPX_READ_IMPLEMENT(CMD, TYPE) ORTTCPX_GEN_IMPLEMENT(CMD, TYPE,_, R, r, eadBack)
#define ORTTCPX_WRITE_IMPLEMENT(CMD, TYPE) ORTTCPX_GEN_IMPLEMENT(CMD, TYPE, , W, w, riteTo)
                                                                 
 
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetVoltage)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetVoltageAndVerify)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetOverVoltageProtectionTripPoint)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetCurrentLimit)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetOverCurrentProtectionTripPoint)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetVoltageSet)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetCurrentSet)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetVoltageTripSet)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetCurrentTripSet)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetVoltageReadback)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetCurrentReadback)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetVoltageStepSize)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetCurrentStepSize)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetVoltageStepSize)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetCurrentStepSize)
ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetOutput)
ORTTCPX_READ_IMPLEMENT_NOTIFY(GetOutputStatus)

//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(IncrementVoltage)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(IncrementVoltageAndVerify)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(DecrementCurrent)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(DecrementVoltage)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(DecrementVoltageAndVerify)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(IncrementCurrent)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetAllOutput)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(ClearTrip)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(Local)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(RequestLock)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(CheckLock)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(ReleaseLock)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(QueryClearLSR)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetEventStatusRegister)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetEventStatusRegister)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SaveCurrentSetup)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(RecallSetup)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetOperatingMode)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetOperatingMode)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetRatio)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetRatio)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(ClearStatus)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(QueryAndClearEER)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetESE)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetESE)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetESR)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetISTLocalMsg)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetOPCBit)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetOPCBit)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetParallelPollRegister)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetParallelPollRegister)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(QueryAndClearQER)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(ResetToRemoteDflt)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(SetSRE)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetSRE)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetSTB)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetID)
//ORTTCPX_WRITE_IMPLEMENT_NOTIFY(GetBusAddress)


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
    // These next two should be the following
    //{@"Get Voltage Trip Point", @"OVP%i?", YES, YES, NO, @"VP%i %f"}, //kGetVoltageTripSet,
    //{@"Get Current Trip Point", @"OCP%i?", YES, YES, NO, @"CP%i %f"}, //kGetCurrentTripSet,
    // But I have instead found them to be:
    {@"Get Voltage Trip Point", @"OVP%i?", YES, YES, NO, @"%f"}, //kGetVoltageTripSet,
    {@"Get Current Trip Point", @"OCP%i?", YES, YES, NO, @"%f"}, //kGetCurrentTripSet,
    // This is a bit of a problem, because it means we have to specially handle these two cases.
    
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


ORTTCPX_WRITE_IMPLEMENT(SetVoltage, float)
ORTTCPX_WRITE_IMPLEMENT(SetVoltageAndVerify, float)
ORTTCPX_WRITE_IMPLEMENT(SetOverVoltageProtectionTripPoint, float)
ORTTCPX_WRITE_IMPLEMENT(SetCurrentLimit, float)
ORTTCPX_WRITE_IMPLEMENT(SetOverCurrentProtectionTripPoint, float)
ORTTCPX_READ_IMPLEMENT(GetVoltageSet, float)
ORTTCPX_READ_IMPLEMENT(GetCurrentSet, float)
ORTTCPX_READ_IMPLEMENT(GetVoltageTripSet, float)
ORTTCPX_READ_IMPLEMENT(GetCurrentTripSet, float)
ORTTCPX_READ_IMPLEMENT(GetVoltageReadback, float)
ORTTCPX_READ_IMPLEMENT(GetCurrentReadback, float)
ORTTCPX_WRITE_IMPLEMENT(SetVoltageStepSize, float)
ORTTCPX_WRITE_IMPLEMENT(SetCurrentStepSize, float)
ORTTCPX_READ_IMPLEMENT(GetVoltageStepSize, float)
ORTTCPX_READ_IMPLEMENT(GetCurrentStepSize, float)
ORTTCPX_WRITE_IMPLEMENT(SetOutput, int)
ORTTCPX_READ_IMPLEMENT(GetOutputStatus, int)

//ORTTCPX_WRITE_IMPLEMENT(IncrementVoltage, float)
//ORTTCPX_WRITE_IMPLEMENT(IncrementVoltageAndVerify, float)
//ORTTCPX_WRITE_IMPLEMENT(DecrementCurrent, float)
//ORTTCPX_WRITE_IMPLEMENT(DecrementVoltage, float)
//ORTTCPX_WRITE_IMPLEMENT(DecrementVoltageAndVerify, float)
//ORTTCPX_WRITE_IMPLEMENT(IncrementCurrent, float)
//ORTTCPX_WRITE_IMPLEMENT(SetAllOutput, float)
//ORTTCPX_WRITE_IMPLEMENT(ClearTrip, float)
//ORTTCPX_WRITE_IMPLEMENT(Local, float)
//ORTTCPX_WRITE_IMPLEMENT(RequestLock, float)
//ORTTCPX_WRITE_IMPLEMENT(CheckLock, float)
//ORTTCPX_WRITE_IMPLEMENT(ReleaseLock, float)
//ORTTCPX_WRITE_IMPLEMENT(QueryClearLSR, float)
//ORTTCPX_WRITE_IMPLEMENT(SetEventStatusRegister, float)
//ORTTCPX_WRITE_IMPLEMENT(GetEventStatusRegister, float)
//ORTTCPX_WRITE_IMPLEMENT(SaveCurrentSetup, float)
//ORTTCPX_WRITE_IMPLEMENT(RecallSetup, float)
//ORTTCPX_WRITE_IMPLEMENT(SetOperatingMode, float)
//ORTTCPX_WRITE_IMPLEMENT(GetOperatingMode, float)
//ORTTCPX_WRITE_IMPLEMENT(SetRatio, float)
//ORTTCPX_WRITE_IMPLEMENT(GetRatio, float)
//ORTTCPX_WRITE_IMPLEMENT(ClearStatus, float)
//ORTTCPX_WRITE_IMPLEMENT(QueryAndClearEER, float)
//ORTTCPX_WRITE_IMPLEMENT(SetESE, float)
//ORTTCPX_WRITE_IMPLEMENT(GetESE, float)
//ORTTCPX_WRITE_IMPLEMENT(GetESR, float)
//ORTTCPX_WRITE_IMPLEMENT(GetISTLocalMsg, float)
//ORTTCPX_WRITE_IMPLEMENT(SetOPCBit, float)
//ORTTCPX_WRITE_IMPLEMENT(GetOPCBit, float)
//ORTTCPX_WRITE_IMPLEMENT(SetParallelPollRegister, float)
//ORTTCPX_WRITE_IMPLEMENT(GetParallelPollRegister, float)
//ORTTCPX_WRITE_IMPLEMENT(QueryAndClearQER, float)
//ORTTCPX_WRITE_IMPLEMENT(ResetToRemoteDflt, float)
//ORTTCPX_WRITE_IMPLEMENT(SetSRE, float)
//ORTTCPX_WRITE_IMPLEMENT(GetSRE, float)
//ORTTCPX_WRITE_IMPLEMENT(GetSTB, float)
//ORTTCPX_WRITE_IMPLEMENT(GetID, float)
//ORTTCPX_WRITE_IMPLEMENT(GetBusAddress, float)

@synthesize socket;
@synthesize ipAddress;
@synthesize port;

- (id) init
{
    self = [super init];
    [self setIpAddress:@""];
    [self setSerialNumber:@""];    
    return self;
}

- (void) dealloc
{
    [socket release];
    [ipAddress release];
    [serialNumber release];
    [dataQueue release];  
    [generalReadback release];
	[super dealloc];
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

- (void) toggleConnection 
{
    if (!isConnected) [self connect];
    else {
        [self setSocket:nil];
        [self _setIsConnected:NO];
    }
}

- (void) connect
{
	if(!isConnected && !socket) [self _connectIP]; 
}

- (void) _connectIP
{
	if(!isConnected){
        NSDictionary* dict = [[ORVXI11HardwareFinder sharedVXI11HardwareFinder] availableHardware];
        for (NSString* key in dict) {
            ORVXI11IPDevice* dev = [dict objectForKey:key];
            if ([[dev serialNumber] isEqualToString:serialNumber]) {
                [self setIpAddress:[dev ipAddress]];
                break;
            }
            // do stuff
        }
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

- (void) setAllOutputToBeOn:(BOOL)on
{
    [self writeCommand:kSetAllOutput withInput:on withOutputNumber:1];
    writeToSetOutput[0] = on;
    writeToSetOutput[1] = on;    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ORTTCPX400DPWriteToSetOutputIsChanged
     object:self];      
}
- (void) setOutput:(unsigned int)output toBeOn:(BOOL)on
{
    [self setWriteToSetOutput:on withOutput:output];
}

- (void) _addCommandToDataProcessingQueue:(struct ORTTCPX400DPCmdInfo*)theCmd 
   withSendString:(NSString*)cmdStr 
   withReturnSelectorName:(NSString*)selName
   withOutputNumber:(unsigned int)output
{
    // We take pointers, but we know the pointers always exist.

    @synchronized(self) {
        if (dataQueue == nil) {
            dataQueue = [[NSMutableArray array] retain];
        }
        // First add the write command
        [dataQueue addObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLong:(unsigned long)theCmd],cmdStr,@"",[NSNumber numberWithUnsignedInt:output],nil]];        
        // If there's a read command, add it as well.
        if (selName != nil) {        
            [dataQueue addObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedLong:(unsigned long)theCmd],@"",selName,[NSNumber numberWithUnsignedInt:output],nil]];
        }
    }
}

- (void) _processNextWriteCommandInQueue
{
    // This function processes the next write command in the queue.  It returns if the next command is a read command.
    while (1) {
        BOOL shouldContinue = NO;
        NSString* nextCmdToWrite;
        struct ORTTCPX400DPCmdInfo* theCmd = nil;
        @synchronized(self) {
            if ([dataQueue count] > 0 && [[[dataQueue objectAtIndex:0] objectAtIndex:1] length] != 0) {
                // The queue to receive something is empty.
                shouldContinue = YES;
                // We have to copy it, because removing it gets rid of it.
                nextCmdToWrite = [NSString stringWithString:[[dataQueue objectAtIndex:0] objectAtIndex:1]];
                theCmd = (struct ORTTCPX400DPCmdInfo*)[[[dataQueue objectAtIndex:0] objectAtIndex:0] longValue];                
                [dataQueue removeObjectAtIndex:0];
            }
        }
        if (!shouldContinue) return;
        if(!theCmd->responds) [self _setGeneralReadback:@"N/A"];
        if([self isConnected]){
            [self performSelectorOnMainThread:@selector(_mainThreadSocketSend:) withObject:nextCmdToWrite
                                waitUntilDone:YES];
        }
        else {
            NSString *errorMsg = @"Must establish IP connection prior to issuing command.\n";
            NSLog(errorMsg);
            return;
        }     
    }
}

- (void) _processNextReadCommandInQueueWithInputString:(NSString *)input
{
    struct ORTTCPX400DPCmdInfo* cmd = nil;
    SEL callSelector = nil;    
    int outputNum = 1;       
    @synchronized(self) {
        if ([dataQueue count] > 0 && [[[dataQueue objectAtIndex:0] objectAtIndex:2] length] != 0) {
            cmd = (struct ORTTCPX400DPCmdInfo*)[[[dataQueue objectAtIndex:0] objectAtIndex:0] longValue];
            callSelector = NSSelectorFromString([[dataQueue objectAtIndex:0] objectAtIndex:2]);
            // We unfortunately have to do this, because some output numbers are not set by the returned strings.
            outputNum = [[[dataQueue objectAtIndex:0] objectAtIndex:3] unsignedIntValue];
            [dataQueue removeObjectAtIndex:0];
        }
    }
    // we don't need to synchronize this part necessarily.
    if (cmd == nil) return;
    // This command absolutely needs to respond
    assert(cmd->responds);
    float readBackValue = 0;

    
    int numberOfOutputs = [[cmd->responseFormat componentsSeparatedByString:@"%"] count] - 1;
    switch (numberOfOutputs) {
        case 1:
            if (sscanf([input cStringUsingEncoding:NSASCIIStringEncoding], 
                       [cmd->responseFormat cStringUsingEncoding:NSASCIIStringEncoding],&readBackValue) != 1) {
                NSLog(@"Error parsing input string (%@) with format (%@)",input,cmd->responseFormat);
                return;
            }        
            break;
        case 2:

            if (sscanf([input cStringUsingEncoding:NSASCIIStringEncoding], 
                       [cmd->responseFormat cStringUsingEncoding:NSASCIIStringEncoding],&outputNum,&readBackValue) != 2) {
                NSLog(@"Error parsing input string (%@) with format (%@)\n",input,cmd->responseFormat);
                return;
            }
            break;
        default:
            assert((numberOfOutputs != 1 && numberOfOutputs != 2));
            break;
    }
    if (callSelector) {
        numberOfOutputs = [[NSStringFromSelector(callSelector) componentsSeparatedByString:@":"] count] - 1;
        switch (numberOfOutputs) {
            case 1:
                [self performSelector:callSelector withObject:[NSNumber numberWithFloat:readBackValue]];
                break;
            case 2:
                [self performSelector:callSelector withObject:[NSNumber numberWithFloat:readBackValue] withObject:[NSNumber numberWithInt:outputNum] ];
                break;
            default:
                assert((numberOfOutputs != 1 && numberOfOutputs != 2));
                break;
        }
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
	[self _processNextReadCommandInQueueWithInputString:theString];
    // Process any waiting write commands.
    [self _processNextWriteCommandInQueue];
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

#pragma mark ***Guardian
- (BOOL) acceptsGuardian:(OrcaObject *)aGuardian
{
    return [super acceptsGuardian:aGuardian] || 
    [aGuardian isKindOfClass:NSClassFromString(@"ORnEDMCoilModel")];
}

- (short) numberSlotsUsed
{
    // Allows us to use only one slot
    return 1;
}

#pragma mark ***Comm methods

- (void) writeCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutputNumber:(int)output
{
    [self _writeCommand:cmd withInput:input withOutputNum:output withSelectorName:nil];
}

- (void) _writeCommand:(ETTCPX400DPCmds)cmd withInput:(float)input withOutputNum:(int)output withSelectorName:(NSString*)selName
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
        
    }
    [self _addCommandToDataProcessingQueue:theCmd withSendString:cmdStr withReturnSelectorName:selName withOutputNumber:output];
    [self _processNextWriteCommandInQueue];
    //[self write:cmdStr];
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
    // This function is disable for now.
    //[self _addCommandToDataProcessingQueue:<#(struct ORTTCPX400DPCmdInfo *)#> withSendString:<#(NSString *)#> withReturnSelectorName:<#(NSString *)#>];
    //[self _processNextCmdInWriteQueue];
}

- (void) _mainThreadSocketSend:(NSString*)aCommand
{
	if(!aCommand)aCommand = @"";
	[socket writeString:aCommand encoding:NSASCIIStringEncoding];
}

- (void) setSerialNumber:(NSString *)aSerial
{
    [aSerial retain];
    [serialNumber release];
    serialNumber = aSerial;
    
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:ORTTCPX400DPSerialNumberHasChanged
     object:self];      
    
}

- (NSString*) serialNumber
{
    if (serialNumber == nil) return @"";
    return serialNumber;
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self setIpAddress:[decoder decodeObjectForKey:@"ipAddress"]];
	[self setSerialNumber:[decoder decodeObjectForKey:@"serialNumber"]];    
    [self setPort:[decoder decodeIntForKey:@"portNumber"]];

	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
 	[encoder encodeObject:ipAddress	forKey:@"ipAddress"];
 	[encoder encodeObject:serialNumber	forKey:@"serialNumber"];    
    [encoder encodeInt:port forKey:@"portNumber"];    
}



@end
