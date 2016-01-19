//
//  TUBiiModel.m
//  Orca
//
//  Created by Ian Coulter on 9/15/15.
//
//
#pragma mark •••Imported Files
#import "TUBiiModel.h"
#import "RedisClient.h"
#import "netdb.h"

#pragma mark •••Definitions
#define TUBII_DEFAULT_IP "192.168.80.25"
#define TUBII_DEFAULT_PORT 4001

@implementation TUBiiModel
#pragma mark •••Synthesized Variables
@synthesize portNumber;
@synthesize strHostName;
@synthesize telliePulseWidth;
@synthesize smelliePulseWidth;
@synthesize pulseWidth;
@synthesize tellieNPulses;
@synthesize smellieNPulses;
@synthesize NPulses;
@synthesize tellieRate;
@synthesize smellieRate;
@synthesize pulserRate;


- (void) setUpImage
{
    NSImage* img = [NSImage imageNamed:@"tubii"];
    
    // Scale the image down by half
    NSSize halfSize = [img size];
    halfSize.height = (int)(halfSize.height / 2);
    halfSize.width  = (int)(halfSize.width  / 2);
    [img setSize:halfSize];
    [self setImage:img];
}

- (BOOL) solitaryObject {
    return YES; //Prevents there from being two TUBiis
}
// Link the model to the controller
- (void) makeMainController
{
    [self linkToController:@"TUBiiController"];
}
// Initialize the model.
// Note that this is initWithCoder and not just init, and we
// call the superclass initWithCoder too!

- (id) init {
    NSLog(@"init called\n");
    self = [super init];
    if (self) {
        // Initialize model member variables
        smellieRate = 0;
        tellieRate = 0;
        pulserRate = 0;
        smelliePulseWidth = 0;
        telliePulseWidth = 0;
        pulseWidth = 0;
        smellieNPulses=0;
        tellieNPulses=0;
        NPulses=0;
        portNumber =TUBII_DEFAULT_PORT;
        strHostName = [[NSString alloc]initWithUTF8String:TUBII_DEFAULT_IP];
        connection = [[RedisClient alloc] initWithHostName:strHostName withPort:portNumber];
    }
    return self;
}
- (void) dealloc {
    [connection release];
    [strHostName release];
    [super dealloc];

}
#pragma mark •••Archival
- (id) initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        smellieRate =     [ aCoder decodeFloatForKey:@"TUBiiModelSmellieRate"];
        smelliePulseWidth=[ aCoder decodeFloatForKey:@"TUBiiModelSmelliePulseWidth"];
        smellieNPulses =  [ aCoder decodeIntForKey:@"TUBiiModelSmellieNPulses"];
        tellieRate =      [ aCoder decodeFloatForKey:@"TUBiiModelTellieRate"];
        telliePulseWidth =[ aCoder decodeFloatForKey:@"TUBiiModelTelliePulseWidth"];
        tellieNPulses =   [ aCoder decodeIntForKey:@"TUBiiModelTellieNPulses"];
        pulserRate =      [ aCoder decodeFloatForKey:@"TUBiiModelPulserRate"];
        pulseWidth =      [ aCoder decodeFloatForKey:@"TUBiiModelPulseWidth"];
        NPulses =         [ aCoder decodeIntForKey:@"TUBiiModelNPulses"];
        portNumber =      [ aCoder decodeIntForKey:@"TUBiiModelPortNumber"];
        strHostName =     [ aCoder decodeObjectForKey:@"TUBiiModelStrHostName"];
        if (!strHostName) {
            [strHostName dealloc]; //Not sure if this is needed or not.
            strHostName = [[NSString alloc]initWithUTF8String:TUBII_DEFAULT_IP];

        }
        if (!portNumber) {
            portNumber = TUBII_DEFAULT_PORT;
        }
        connection = [[RedisClient alloc] initWithHostName:strHostName withPort:portNumber];
    }
    return self;
}
- (void) encodeWithCoder:(NSCoder *)aCoder{
    [super encodeWithCoder:aCoder];
    [aCoder encodeFloat:smellieRate         forKey:@"TUBiiModelSmellieRate"];
    [aCoder encodeFloat:smelliePulseWidth   forKey:@"TUBiiModelSmelliePulseWidth"];
    [aCoder encodeInt:smellieNPulses		forKey:@"TUBiiModelSmellieNPulses"];
    [aCoder encodeFloat:tellieRate          forKey:@"TUBiiModelTellieRate"];
    [aCoder encodeFloat:telliePulseWidth    forKey:@"TUBiiModelTelliePulseWidth"];
    [aCoder encodeInt:tellieNPulses         forKey:@"TUBiiModelTellieNPulses"];
    [aCoder encodeFloat:pulserRate          forKey:@"TUBiiModelPulserRate"];
    [aCoder encodeFloat:pulseWidth          forKey:@"TUBiiModelPulseWidth"];
    [aCoder encodeInt:NPulses               forKey:@"TUBiiModelNPulses"];
    [aCoder encodeInt:portNumber            forKey:@"TUBiiModelPortNumber"];
    [aCoder encodeObject:strHostName        forKey:@"TUBiiModelStrHostName"];
}
#pragma mark •••Network Communication
- (void) sendOkCmd:(NSString* const)aCmd {
    @try {
        NSLog(@"Sending %@ to TUBii\n",aCmd);
        [connection okCommand: [aCmd UTF8String]];
    }
    @catch (NSException *exception) {
        NSLog(@"Command: %@ failed.  Reason: %@\n", aCmd,[exception reason]);
    }
}
- (int) sendIntCmd: (NSString* const) aCmd {
    @try {
        NSLog(@"Sending %@ to TUBii\n",aCmd);
        return [connection intCommand: [aCmd UTF8String]];
    }
    @catch (NSException *exception) {
        NSLog(@"Command: %@ failed.  Reason: %@\n", aCmd,[exception reason]);
        return nil;
    }
}
#pragma mark •••HW Access
- (void) fireSmelliePulser {
    NSString* const command=[NSString stringWithFormat:@"SetSmelliePulser %f %f %d",tellieRate,telliePulseWidth,tellieNPulses ];
    [self sendOkCmd:command];
}
- (void) stopSmelliePulser {
    NSString* const command=@"SetSmelliePulser 0 0 0";
    [self sendOkCmd:command];
}
- (void) fireTelliePulser{
    NSString* const command=[NSString stringWithFormat:@"SetTelliePulser %f %f %d",tellieRate,telliePulseWidth,tellieNPulses ];
    [self sendOkCmd:command];
}
- (void) stopTelliePulser {
    NSString* const command=@"SetTelliePulser 0 0 0";
    [self sendOkCmd:command];
}
- (void) firePulser{
    NSString* const command=[NSString stringWithFormat:@"SetGenericPulser %f %f %d",pulserRate,pulseWidth,NPulses ];
    [self sendOkCmd:command];
}
- (void) stopPulser {
    NSString* const command=@"SetGenericPulser 0 0 0";
    [self sendOkCmd:command];
}

- (void) ResetClock {
    [self sendOkCmd:@"ResetCommand"];
}
-(void) setCaenMasks: (CAEN_CHANNEL_MASK)aChannelMask
            GainMask:(CAEN_GAIN_MASK) aGainMask; {
    NSString* const command = [NSString stringWithFormat:@"SetCAENWords %d %d",aGainMask,aChannelMask];
    [self sendOkCmd:command];
}
-(CAEN_CHANNEL_MASK) caenChannelMask {
    NSString* const command = @"GetCAENChannelSelectWord";
    return [self sendIntCmd:command];
}

-(CAEN_GAIN_MASK) caenGainMask {
    return [self sendIntCmd:@"GetCAENGainPathWord"];
}
- (void) setGTDelaysBits:(NSUInteger)aDGTMask LOBits:(NSUInteger)aLOMask {
    NSString* const command = [NSString stringWithFormat:@"SetGTDelays %d %d",aLOMask,aDGTMask];
    [self sendOkCmd:command];
}
- (NSUInteger) DGTBits{
    return [self sendIntCmd:@"GetDGTDelay"];
}
- (NSUInteger) LOBits{
    return [self sendIntCmd:@"GetLODelay"];
}
- (void) setTrigMask:(NSUInteger)_trigMask {
    NSString * const command = [NSString stringWithFormat:@"SetTriggerMask %d",_trigMask];
    [self sendOkCmd:command];
}
- (NSUInteger) trigMask {
    return [connection intCommand: "GetTriggerMask"];
}
- (void) setSmellieDelay:(NSUInteger)_smellieDelay {
    NSString * const command = [NSString stringWithFormat:@"SetSmellieDelay %d",_smellieDelay];
    [self sendOkCmd:command];
}
- (NSUInteger) smellieDelay {
    return [connection intCommand: "GetSmellieDelay"];
}
- (void) setTellieDelay:(NSUInteger)_tellieDelay {
    NSString * const command = [NSString stringWithFormat:@"SetTellieDelay %d",_tellieDelay];
    [self sendOkCmd:command];
}
- (NSUInteger) tellieDelay {
    return [self sendIntCmd:@"GetTellieDelay"];
}
- (void) setGenericDelay:(NSUInteger)_genericDelay {
    NSString * const command = [NSString stringWithFormat:@"SetGenericDelay %d",_genericDelay];
    [self sendOkCmd:command];
}
- (NSUInteger) genericDelay {
    return [self sendIntCmd:@"GetGenericDelay"];
}
- (void) setCounterMask:(NSUInteger)_counterMask {
    NSString * const command = [NSString stringWithFormat:@"SetCounterMask %d",_counterMask];
    [self sendOkCmd:command];
}
- (NSUInteger) counterMask {
    return [self sendIntCmd:@"GetCounterMask"];
}
- (void) setControlReg:(CONTROL_REG_MASK)_controlReg {
    NSString * const command = [NSString stringWithFormat:@"SetControlReg %d",_controlReg];
    [self sendOkCmd:command];
}
- (CONTROL_REG_MASK) controlReg {
    return [self sendIntCmd:@"GetControlReg"];
}
- (void) setECAMode:(BOOL)_ECAMode {
    CONTROL_REG_MASK controlReg = [self controlReg];
    if (_ECAMode){
        controlReg |= ecalEnable_Bit;
    }
    else {
        controlReg &= ~ecalEnable_Bit;
    }
    [self setControlReg: controlReg];
}
- (BOOL) ECAMode {
    CONTROL_REG_MASK controlReg =[self controlReg];
    return (controlReg & ecalEnable_Bit) > 0;
}
- (void) setMTCAMimic1_Threshold:(NSUInteger)_MTCAMimic1_Threshold {
    NSString * const command = [NSString stringWithFormat:@"SetDACThreshold %u",_MTCAMimic1_Threshold];
    [self sendOkCmd:command];
}
- (NSUInteger) MTCAMimic1_Threshold {
    return [self sendIntCmd:@"GetDACThreshold"];
}
- (void) setSpeakerMask:(NSUInteger)_speakerMask{
    NSString * const command = [NSString stringWithFormat:@"SetSpeakerMask %d",_speakerMask];
    [self sendOkCmd:command];
}
- (NSUInteger) speakerMask {
    NSString* const command = @"GetSpeakerMask";
    return [self sendIntCmd:command];
}
- (void) setTUBiiIsDefaultClock: (BOOL) IsDefault {
    CONTROL_REG_MASK controlReg = [self controlReg];
    if (IsDefault){
        controlReg |= clkSel_Bit;
    }
    else {
        controlReg &= ~clkSel_Bit;
    }
    [self setControlReg: controlReg];
}
-(BOOL) TUBiiIsDefaultClock {
    CONTROL_REG_MASK controlReg = [self controlReg];
    return (controlReg & clkSel_Bit) >0;
}
- (void) setDataReadout:(BOOL)val {
    if (val) {
        [self sendOkCmd:@"StartDataReadout"];
    }
    else {
        [self sendOkCmd:@"StopDataReadout"];
    }
}
- (void) setStatusReadout:(BOOL)val {
    if (val) {
        [self sendOkCmd:@"StartStatusReadout"];
    }
    else {
        [self sendOkCmd:@"StopStatusReadout"];
    }
}
- (void) setCounterMode:(BOOL)mode {
    if (mode) {
        [self sendOkCmd:@"SetCounterMode 1"]; //Rate Mode
    }
    else {
        [self sendOkCmd:@"SetCounterMode 0"]; //Totalizer Mode
    }
}
- (BOOL) CounterMode {
    return ([self sendIntCmd:@"GetCounterMode"]) > 0;
}
@end