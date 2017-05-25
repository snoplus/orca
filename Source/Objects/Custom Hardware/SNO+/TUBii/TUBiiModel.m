//
//   TUBiiModel.m
//   Orca
//
//   Created by Ian Coulter on 9/15/15.
//   Largely written by Eric Marzec
//   Last edited on Jan 23 2016
//
//   This file is a bit different from other Models in
//   Orca. Most use instance variables which dynamically update
//   to represent a hardware item. TUBiiModel however has very
//   few instance variables. Instead it forwards every desired change
//   to the server that runs on the MicroZed. The server then is in 
//   charge of tracking and dynamically updating the state. And
//   of course the server also contacts the FPGA side of the MicroZed
//   and that changes the actual hardware on the board.
//
//
#pragma mark •••Imported Files
#import "TUBiiModel.h"
#import "RedisClient.h"
#import "netdb.h"

#pragma mark •••Definitions
#define TUBII_DEFAULT_IP "192.168.80.25"
#define TUBII_DEFAULT_PORT 4001

NSString* ORTubiiLock				= @"ORTubiiLock";

@implementation TUBiiModel
#pragma mark •••Synthesized Variables

@synthesize keepAliveThread = _keepAliveThread;

- (void) setUpImage
{
    NSImage* img = [NSImage imageNamed:@"tubii"];
    [self setImage:img];
}

- (BOOL) solitaryObject {
    return YES; // Prevents there from being two TUBiis
}
- (void) setPortNumber:(int)_portNumber {
    if( _portNumber != portNumber)
    {
        [connection setPort:_portNumber];
        [connection disconnect];
    }
}
- (int) portNumber {
    return [connection port];
}
- (void) setStrHostName:(NSString *)_strHostName {
    if(_strHostName != strHostName) {
        [connection setHost:_strHostName];
        [connection disconnect];
    }

}
- (NSString*) strHostName {
    return [connection host];
}
//  Link the model to the controller
- (void) makeMainController
{
    [self linkToController:@"TUBiiController"];
}
//  Initialize the model.
//  Note that this is initWithCoder and not just init, and we
//  call the superclass initWithCoder too!

- (id) init {
    self = [super init];
    [self registerNotificationObservers];
    if (self) {
        //  Initialize model member variables
        smellieRate = 0;
        tellieRate = 0;
        pulserRate = 0;
        smelliePulseWidth = 0;
        telliePulseWidth = 0;
        pulserPulseWidth = 0;
        smellieNPulses=0;
        tellieNPulses=0;
        pulserNPulses=0;
        connection = [[RedisClient alloc] init]; // Connection must be allocated before port and host name are set
        portNumber =TUBII_DEFAULT_PORT;
        strHostName = [[NSString alloc]initWithUTF8String:TUBII_DEFAULT_IP];
    }
    return self;
}
- (void) dealloc {
    [_keepAliveThread release];
    [connection release];
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
        pulserPulseWidth =[ aCoder decodeFloatForKey:@"TUBiiModelPulseWidth"];
        pulserNPulses =   [ aCoder decodeIntForKey:@"TUBiiModelNPulses"];
        portNumber =      [ aCoder decodeIntForKey:@"TUBiiModelPortNumber"];
        
        //Connection must be made before port and host name are set.
        connection = [[RedisClient alloc] initWithHostName:strHostName withPort:portNumber];
        [self setStrHostName:[ aCoder decodeObjectForKey:@"TUBiiModelStrHostName"]];
        if (!strHostName) {
            [self setStrHostName: @TUBII_DEFAULT_IP];
        }
        if (![self portNumber]) {
            [self setPortNumber:TUBII_DEFAULT_PORT];
        }
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
    [aCoder encodeFloat:pulserPulseWidth          forKey:@"TUBiiModelPulseWidth"];
    [aCoder encodeInt:pulserNPulses               forKey:@"TUBiiModelNPulses"];
    [aCoder encodeInt:portNumber            forKey:@"TUBiiModelPortNumber"];
    [aCoder encodeObject:strHostName        forKey:@"TUBiiModelStrHostName"];
}
- (void) registerNotificationObservers{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
}
- (void) runAboutToStart: (NSNotification*) aNone {
    [self setDataReadout:NO];
    [self ResetFifo]; //Maybe take this out eventually? I'm not sure
    [self setDataReadout:YES];
}

- (void) awakeAfterDocumentLoaded
{
    [self activateKeepAlive];
}

#pragma mark •••Network Communication
- (void) sendOkCmd:(NSString* const)aCmd {
    [self sendOkCmd:aCmd print:YES];
}
- (void) sendOkCmd:(NSString* const)aCmd print:(BOOL)printCheck{
    @try {
        if(printCheck){
            NSLog(@"Sending %@ to TUBii\n",aCmd);
        }
        [connection okCommand: [aCmd UTF8String]];
    }
    @catch (NSException *exception) {
        if(printCheck){
            NSLogColor([NSColor redColor],@"Command: %@ failed.  Reason: %@\n", aCmd,[exception reason]);
        }
    }
}
- (int) sendIntCmd: (NSString* const) aCmd {
    @try {
        NSLog(@"Sending %@ to TUBii\n",aCmd);
        return [connection intCommand: [aCmd UTF8String]];
    }
    @catch (NSException *exception) {
        NSLogColor([NSColor redColor],@"Command: %@ failed.  Reason: %@\n", aCmd,[exception reason]);
        return nil;
    }
}
#pragma mark •••HW Access
- (void) Initialize {
    // The contents of initialize are defined on the TUBii Server
    // See documentation for that for more info (assuming it exists eventually)
    NSString* const command=@"Initialise";
    [self sendOkCmd:command];
}
- (void) Ping {
    NSString* const command = @"ping";
    [self sendOkCmd:command];
}
- (void) setBurstTrigger {
    //I'm not exactly sure what the command is for this yet
}
- (void) setComboTrigger_EnableMask:(uint32_t) enableMask TriggerMask:(uint32_t) triggerMask {
    NSString* const command = [NSString stringWithFormat:@"SetComboTrigger %u %u",enableMask,triggerMask];
    [self sendOkCmd:command];
}
- (void) setPrescaleTrigger_Mask:(uint32_t)mask ByFactor:(uint32_t)factor {
    NSString* const command = [NSString stringWithFormat:@"SetPrescaleTrigger %u %u",factor,mask];
    [self sendOkCmd:command];
}
- (void) setTUBiiPGT_Rate:(float)rate {
    NSString* const command = [NSString stringWithFormat:@"SetTUBiiPGT %f",rate];
    [self sendOkCmd:command];
}

- (void) setSmellieRate:(float)_rate {
    // Specifies the frequency (in Hz) that the smellie pulser will pulse at
    // once fireSmelliePulser is called.
    smellieRate = _rate;
}
- (void) setSmelliePulseWidth:(double) _pulseWidth {
    // Specifies the width the of the pulses that the smellie pulser will pulse at
    // once fireSmelliePulser is called
    smelliePulseWidth = _pulseWidth;
}
- (void) setSmellieNPulses:(int) _NPulses {
    // Specifies the number of pulses that will be fired off by the Smellie pulser
    // once fireSmellie pulser is called
    smellieNPulses = _NPulses;
}
- (void) setTellieRate:(float)_rate {
    // Specifies the frequency (in Hz) that the tellie pulser will pulse at
    // once fireTelliePulser is called.
    tellieRate = _rate;
}
- (void) setTelliePulseWidth:(double)_pulseWidth {
    // Specifies the width the of the pulses that the tellie pulser will pulse at
    // once fireTelliePulser is called
    telliePulseWidth = _pulseWidth;
}
- (void) setTellieNPulses:(int) _NPulses {
    // Specifies the number of pulses that will be fired off by the Tellie pulser
    // once fireTellie pulser is called
    tellieNPulses = _NPulses;
}
- (void) setPulserRate:(float) _rate {
    // Specifies the frequency (in Hz) that the generic pulser will pulse at
    // once firePulser is called.
    pulserRate = _rate;
}
- (void) setPulseWidth:(double) _pulseWidth {
    // Specifies the width the of the pulses that the generic pulser will pulse at
    // once firePulser is called
    pulserPulseWidth = _pulseWidth;
}
- (void) setNPulses:(int) _NPulses {
    // Specifies the number of pulses that will be fired off by the generic pulser
    // once firePulser pulser is called
    pulserNPulses = _NPulses;
}
- (void) fireSmelliePulser {
    // Causes the SMELLIE pulser to fire off pulses at a rate/duty cycle as
    // specified by it's internal variables which can be set with
    // setSmellieRate setSmelliePulseWidth setSmellieNPulses
    NSString* command = [NSString stringWithFormat:@"SetSmelliePulser %f %f %d", smellieRate,smelliePulseWidth,smellieNPulses];
    [self sendOkCmd:command];
}
- (void) stopSmelliePulser {
    // Stops the smellie pulser by setting the number of pulses to be fired to zero.
    [self setSmellieNPulses:0];
    NSString* const command=@"SetSmelliePulser 1 0.1 0";
    [self sendOkCmd:command];
}
- (void) fireTelliePulser{
    // Causes the TELLIE pulser to fire off pulses at a rate/duty cycle as
    // specified by it's internal variables which can be set with
    // setTellieRate setTelliePulseWidth setTellieNPulses
    NSString* command = [NSString stringWithFormat:@"SetTelliePulser %f %f %d", tellieRate,telliePulseWidth,tellieNPulses];
    [self sendOkCmd:command];
}
- (void) stopTelliePulser {
    // Stops the Tellie pulser by setting the number of pulses to be fired to zero.
    [self setTellieNPulses:0];
    NSString* const command=@"SetTelliePulser 1 0.1 0";
    [self sendOkCmd:command];
}
- (void) firePulser{
    // Causes the generic pulser to fire off pulses at a rate/duty cycle as
    // specified by it's internal variables which can be set with
    // setPulserRate setPulseWidth setNPulses
    NSString* command = [NSString stringWithFormat:@"SetGenericPulser %f %f %d", pulserRate,pulserPulseWidth,pulserNPulses];
    [self sendOkCmd:command];
}
- (void) stopPulser {
    // Stops the generic pulser by setting the number of pulses to be fired to zero.
    [self setNPulses:0];
    NSString* const command=@"SetGenericPulser 1 0.1 0";
    [self sendOkCmd:command];
}
- (void) fireSmelliePulser_rate: (float)rate pulseWidth:(double)_pulseWidth NPulses:(int)_NPulses {
    NSString* const command = [NSString stringWithFormat:@"SetSmelliepulser %0.3f %e %d",rate,_pulseWidth,_NPulses];
    [self sendOkCmd:command];
}
- (void) fireTelliePulser_rate: (float)rate pulseWidth:(double)_pulseWidth NPulses:(int)_NPulses {
    NSString* const command = [NSString stringWithFormat:@"SetTelliePulser %0.3f %e %d",rate,_pulseWidth,_NPulses];
    [self sendOkCmd:command];
}
- (void) firePulser_rate: (float)rate pulseWidth:(double)_pulseWidth NPulses:(int)_NPulses {
    NSString* const command = [NSString stringWithFormat:@"SetGenericPulser %0.3f %e %d",rate,_pulseWidth,_NPulses];
    [self sendOkCmd:command];
}
- (void) ResetClock {
    // Resets the clock error checking circuitry.
    // i.e. if the circuitry detects an error in the clock and then automatcially
    // switches over to the backup clock you need to reset the system with this command
    // in order to go back to using the default clock
    // See TUBii schematics page 7,7A, and 7B for more info.
    [self sendOkCmd:@"clockReset"];
}
-(void) setCaenMasks: (CAEN_CHANNEL_MASK)aChannelMask
            GainMask:(CAEN_GAIN_MASK) aGainMask; {
    // Sets the two shift registers that specify how TUBii should handle the 12 Analog inputs (A0-A11) it has.
    // The channel mask specifies which channels should be routed from input to output.
    // There are 4 output channels (C0,C1,C2,&C3) which are capable of being sent 1 of 2 different inputs.
    // i.e. If bit 0 in the channel mask is low then C0 recieves A0 as input. If bit 0 is high C0 recieves A8 as input.
    // The same is true for the scope output (S0 can recieve either A0 or A8 as input)
    // Only the first 4 bits of the channel mask are used
    //
    // The Gain mask controls what sort of attenuations is applied to a given channel's input.
    // The 8 CAEN outputs (C0-C7) are controlled by a bit in the GainMask.
    // If a Bit is high that channel is attenuated. If low that channel has unity-gain.
    //
    // These two masks have to be set at the same time b/c the 8-bit shift registers that
    // hold these masks are daisy chained together so in effect it's a single 16 bit shift register
    //
    // See TUBii Schematics pages 11A and 11B for more info.
    NSString* const command = [NSString stringWithFormat:@"SetCAENWords %d %d",aGainMask,aChannelMask];
    [self sendOkCmd:command];
}
-(CAEN_CHANNEL_MASK) caenChannelMask {
    // See comments in setCaenMask for info
    NSString* const command = @"GetCAENChannelSelectWord";
    return [self sendIntCmd:command];
}
-(CAEN_GAIN_MASK) caenGainMask {
    // See comments in setCaenMask for info
    return [self sendIntCmd:@"GetCAENGainPathWord"];
}
- (void) setGTDelaysBits:(NSUInteger)aDGTMask LOBits:(NSUInteger)aLOMask {
    // Sets two 8 bit shift register that are daisy chained together such that they
    // act like a single 16 bit register.
    // The first of these registers controls the length of time between when a GT arrives and when DGT is sent
    // The seconds controls how long the LO window is.
    // The chips that create these delays are the DS1023-200 and DS1023-500, see their data sheet for details
    // See TUBii schematic page 13A for more info
    NSString* const command = [NSString stringWithFormat:@"SetGTDelays %d %d",aLOMask,aDGTMask];
    [self sendOkCmd:command];
}
- (NSUInteger) DGTBits{
    // See comments in setGTDelayBits for info
    return [self sendIntCmd:@"GetDGTDelay"];
}
- (NSUInteger) LODelayBits{
    // See comments in setGTDelayBits for info
    return [self sendIntCmd:@"GetLODelay"];
}
- (void) setGTDelaysInNS:(int)DGT LOValue:(int)LO {
    // Convenience method that sets the DGT and LO delays
    // and automatically converts from nano seconds to bit values
    [self setGTDelaysBits:[self DGT_NanoSecondsToBits:DGT]
                   LOBits:[self LODelay_NanoSecondsToBits:LO]];
}
- (int) LODelayInNS {
    // Convenience method that gets the LO width/delay and
    // automatically handles the conversion from bit value to nanoseconds
    // See Comments in setGTDelayBits for more info
    return [self LODelay_NanoSecondsToBits:[self LODelayBits]];
}
- (int) DGTInNS {
    // Convenience method that gets the DGT delay and
    // automatically handles the conversion from bit value to nanoseconds
    // See Comments in setGTDelayBits for more info
    return [self DGT_BitsToNanoSeconds:[self DGTBits]];
}
- (int) LODelay_BitsToNanoSeconds: (NSUInteger)Bits {
    // Helper method that handles the conversion to ns from bits for the
    // LO delay on TUBii
    return [self ConvertBitsToValue:Bits NBits:8 MinVal:0 MaxVal: 1275];
}
- (NSUInteger) LODelay_NanoSecondsToBits: (int) Nanoseconds {
    // Helper method that handles the conversion to bits from ns for the
    // LO delay on TUBii
    return [self ConvertValueToBits:Nanoseconds NBits:8 MinVal:0 MaxVal:1275];
}
- (int) DGT_BitsToNanoSeconds: (NSUInteger) Bits {
    // Helper method that handles the conversion to ns from bits for the
    // DGT delay on TUBii
    return [self ConvertBitsToValue:Bits NBits:8 MinVal:0 MaxVal: 510];
}
- (NSUInteger) DGT_NanoSecondsToBits: (int) Nanoseconds {
    // Helper method that handles the conversion to bits from ns for the
    // DGT delay on TUBii
    return [self ConvertValueToBits:Nanoseconds NBits:8 MinVal:0 MaxVal:510];
}
- (void) setTrigMask:(NSUInteger)_syncTrigMask setAsyncMask:(NSUInteger)_asyncTrigMask{
    // Sets which trigger inputs are capable causing TUBii to issue a Raw Trigger
    // This function is handled entierly within the MicroZed processing logic.
    
    NSString * const command = [NSString stringWithFormat:@"SetTriggerMask %d %d",_syncTrigMask,_asyncTrigMask];
    [self sendOkCmd:command];
}
- (NSUInteger) syncTrigMask {
    // See comment in setTrigMask for info.
    return [connection intCommand: "GetSyncTriggerMask"];
}
- (NSUInteger) asyncTrigMask {
    // See comment in setTrigMask for info.
    return [connection intCommand: "GetAsyncTriggerMask"];
}
- (void) setSmellieDelay:(NSUInteger)_smellieDelay {
    // This specifies (in nanoseconds) how long the MicroZed should delay a pulse that
    // is put into TUBii's SMELLIE Delay In port. After that delay the signal is then sent back out
    // at TUBii's SMELLIE Delay Out port. Additionally the MicroZed registers the input signal as a trigger
    // after that delay.
    NSString * const command = [NSString stringWithFormat:@"SetSmellieDelay %d",_smellieDelay];
    [self sendOkCmd:command];
}
- (NSUInteger) smellieDelay {
    // See comments setSmellieDelay for info
    return [connection intCommand: "GetSmellieDelay"];
}
- (void) setTellieDelay:(NSUInteger)_tellieDelay {
    // This specifies (in nanoseconds) how long the MicroZed should delay a pulse that
    // is put into TUBii's TELLIE Delay In port. After that delay the signal is then sent back out
    // at TUBii's TELLIE Delay Out port. Additionally the MicroZed registers the input signal as a trigger
    // after that delay.
    NSString * const command = [NSString stringWithFormat:@"SetTellieDelay %d",_tellieDelay];
    [self sendOkCmd:command];
}
- (NSUInteger) tellieDelay {
    // See comments in setTellieDelay for more info
    return [self sendIntCmd:@"GetTellieDelay"];
}
- (void) setGenericDelay:(NSUInteger)_genericDelay {
    // This specifies how long a pulse fed into TUBii's Generic Delay in port in
    // should be delayed before it appears on TUBii's Generic Delay Out port
    // The arguement should be in nano-seconds.
    // It's not currently supported in the TUBiiServer but the hardware supports a a coarse and a fine delay
    // The coarse delay happens in the MicroZed, the fine delay is done by a chip on TUBii (a DS1023-50)
    // The MicroZed is capable of ~10ns resolution on delays. The chip is capable of 0.5ns resolution.
    // Hopefully I'll get around to adding this some time.
    //
    // As of the time of writing this it is not possible to trigger on this input.
    // /See TUBii Schematics 8C for more information
    NSString * const command = [NSString stringWithFormat:@"SetGenericDelay %d",_genericDelay];
    [self sendOkCmd:command];
}
- (NSUInteger) genericDelay {
    // See comments in setGenericDelay for info
    return [self sendIntCmd:@"GetGenericDelay"];
}
- (void) setCounterMask:(NSUInteger)_counterMask {
    // Sets which trigger inputs are capable of incrementing the count
    // for the scaler/counter on TUBii's front panel
    // This is handled entierly within the MicroZed/TUBiiServer
    NSString * const command = [NSString stringWithFormat:@"SetCounterMask %d",_counterMask];
    [self sendOkCmd:command];
}
- (NSUInteger) counterMask {
    // See comments in setCounterMask for info
    return [self sendIntCmd:@"GetCounterMask"];
}
- (void) setControlReg:(CONTROL_REG_MASK)_controlReg {
    // TUBii's control register is an 8-bit shift register.
    // It contains state information that is not expected to change very often
    // i.e. It's values change on a run by run basis and not at 1khz or something like that.
    // The bits in the register specify the following things.
    // If TUBii is the default clock source or not (see setTUBiiIsDefaultClock for more info)
    // If TUBii is the source for LO* (see setTUBiiIsLOSrc for more info)
    // If TUBii is in ECAL Mode (see setECALMode for more info)
    // Sets the Lead Zero Blanking, Test Mode and Inhibit bits for the Scaler/Counter on TUBii's front panel
    // See TUBii schematics page 4 for even more info
    NSString * const command = [NSString stringWithFormat:@"SetControlReg %d",_controlReg];
    [self sendOkCmd:command];
}
- (CONTROL_REG_MASK) controlReg {
    // See comments in setControlReg for more info
    return [self sendIntCmd:@"GetControlReg"];
}
- (void) setECALMode:(BOOL)_ECALMode {
    // This is kindof a helper function.
    // In general one should use setControlReg with CraftControlReg
    // to change the control register. But if you only want to change this one bit
    // then this is handy for that b/c you don't have to worry about the other
    // bits in the control register
    //
    // ECAL Mode enabled means TUBii re-routes GT to it's EXT PED Out port (Ext Ped In then does nothing)
    // To enter ECALMode the ecalEnable_Bit in the control register must be high
    // See TUBii schematics page 10 and page 4 for more info
    CONTROL_REG_MASK controlReg = [self controlReg];
    if (_ECALMode){
        controlReg |= ecalEnable_Bit;
    }
    else {
        controlReg &= ~ecalEnable_Bit;
    }
    [self setControlReg: controlReg];
}
- (BOOL) ECALMode {
    // See comments setECAMode for info
    CONTROL_REG_MASK controlReg =[self controlReg];
    return (controlReg & ecalEnable_Bit) > 0;
}
- (void) setMTCAMimic1_ThresholdInBits:(NSUInteger)_MTCAMimic1_ThresholdInBits {
    // Sets the bits on the DAC on TUBii that is used as a threshold against which
    // an analog pulse is compared.
    // See TUBii schematics page 14 or AD7243 data sheet for more info.
    //
    // The arguement for this must be the bits that are to be loaded into the DAC on TUBii
    // To convert a threshold value to bits use the convinience function MTCAMimic_VoltsToBits
    // Or skip the middle man and use the function setMTCAMimic_ThresholdInVolts
    NSString * const command = [NSString stringWithFormat:@"SetDACThreshold %u",_MTCAMimic1_ThresholdInBits];
    [self sendOkCmd:command];
}
- (NSUInteger) MTCAMimic1_ThresholdInBits {
    // See setMTCAMimic1_Threshold for more info
    return [self sendIntCmd:@"GetDACThreshold"];
}
- (void) setMTCAMimic1_ThresholdInVolts:(float)_MTCAMimic1_ThresholdInVolts {
    // Sets the voltage Value MTCA Mimic thresold.
    // The only difference between this and setMTCAMimic1_ThresholdInBits is that
    // This takes a voltage value as an input. Whereas the other function takes a bit value.
    // For more info see AD7243 data sheet and TUBii schematics pg 14
    [self setMTCAMimic1_ThresholdInBits:[self MTCAMimic_VoltsToBits:_MTCAMimic1_ThresholdInVolts]];
}
- (float) MTCAMimic1_ThresholdInVolts {
    // Gets the voltage alue MTCA Mimic DAC thresold.
    // The only difference between this and MTCAMimic1_ThresholdInBits is that
    // this returns the analog voltage value between -5.0V and 5.0V that the threshold
    // is capable of being. Whereas the other function returns a bit value
    // See AD7243 data sheet and TUBii schematics pg 14 for more info
    return [self MTCAMimic_BitsToVolts:[self MTCAMimic1_ThresholdInBits]];
}
- (NSUInteger) MTCAMimic_VoltsToBits:(float)VoltageValue {
    // Helper function that converts MTCA Mimic threshold values from a voltage
    // to a 12 bit word. See AD7243 data sheet and TUBii schematics pg 14 for more info
    return [self ConvertValueToBits:VoltageValue NBits:12 MinVal:-5.0 MaxVal:5.0];
}
- (float) MTCAMimic_BitsToVolts: (NSUInteger) BitValue {
    // Helper function that converts MTCA Mimic 12 bit word to the corresponding
    // analog threshold value. See AD7243 data sheet & TUBii schematics pg 14 for more info
    return [self ConvertBitsToValue:BitValue NBits:12 MinVal:-5.0 MaxVal:5.0];
}
- (void) setSpeakerMask:(NSUInteger)_speakerMask{
    // Sets the mask for which trigger inputs should driver the speaker/aux jack on TUBii
    NSString * const command = [NSString stringWithFormat:@"SetSpeakerMask %d",_speakerMask];
    [self sendOkCmd:command];
}
- (NSUInteger) speakerMask {
    // See comment in setSpeakerMask for info about the speaker mask.
    NSString* const command = @"GetSpeakerMask";
    return [self sendIntCmd:command];
}
- (void) setTUBiiIsLOSrc:(BOOL)isSrc {
    // This is kindof a helper function.
    // In general one should use setControlReg with CraftControlReg
    // to change the control register. But if you only want to change this one bit
    // then this is handy for that b/c you don't have to worry about the other
    // bits in the control register
    //
    // Note if TUBii is the LO source than the lockoutSel_Bit should be low.
    // High means the MTC/D is the LO source
    // See TUBii schematics pg 13B
    CONTROL_REG_MASK controlReg = [self controlReg];
    if (!isSrc){
        controlReg |= lockoutSel_Bit;
    }
    else {
        controlReg &= ~lockoutSel_Bit;
    }
    [self setControlReg: controlReg];
}
- (BOOL) TUBiiIsLOSrc {
    // Note if TUBii is the LO source than the lockoutSel_Bit should be low.
    // High means the MTC/D is the LO
    // See TUBii schematics pg 13B
    CONTROL_REG_MASK controlReg = [self controlReg];
    return !((controlReg & lockoutSel_Bit) >0);
}
- (void) setTUBiiIsDefaultClock: (BOOL) IsDefault {
    // This is kindof a helper function.
    // In general one should use setControlReg with CraftControlReg
    // to change the control register. But if you only want to change this one bit
    // then this is handy for that b/c you don't have to worry about the other
    // bits in the control register
    //
    // Note if TUBii is the Default clock the clkSel_Bit should be high
    // Low means the TUB is the default clock
    // The default clock gets checked for errors, the backup clock is used in the event
    // that the default clock fails/ has too many errors.
    // See TUBii schematics pg 7A
    CONTROL_REG_MASK controlReg = [self controlReg];
    if (IsDefault){
        controlReg |= clkSel_Bit;
    }
    else {
        controlReg &= ~clkSel_Bit;
    }
    [self setControlReg: controlReg];
}
- (BOOL) TUBiiIsDefaultClock {
    // See comment in setTUBiiIsDefaultClock for info
    CONTROL_REG_MASK controlReg = [self controlReg];
    return (controlReg & clkSel_Bit) >0;
}
- (void) setDataReadout:(BOOL) Readout {
    // This is implemented in the TUBii Server that runs on the MicroZed.
    // It simply tells the MicroZed to begin reading out data about it's trigger inputs
    // The data should include info about which triggers were high when a GT arrived as well as
    if (Readout) {
        [self sendOkCmd:@"StartReadout"];
    }
    else {
        [self sendOkCmd:@"StopReadout"];
    }
}
- (void) ResetFifo
{
    [self sendOkCmd:@"ResetFifo"];
}
- (void) setCounterMode:(BOOL)mode {
    // The TUBii Server logic on the MicroZed determines what the pin state should be for
    // Rate mode or Totalizer mode.
    //
    // The way it should work is in Rate mode the counterReset and the counterLatch pin is
    // toggled once per second that way the display only updates once per second and it
    // displays how many count pulses were sent in that second.
    // In totalizer mode the display is always latched and the count is never reset.
    //
    // The max rate the scaler is capable is 750kHz, the MZ (puroposefully) limits it even further to ~500kHz
    // See data sheet for SUBCub 28a and TUBii schematics pages 3,4, and FP_6 for more info
    CounterMode_memoryVal = mode;
    if (mode) {
        [self sendOkCmd:@"CountMode 1"]; // Rate Mode
    }
    else {
        [self sendOkCmd:@"CountMode 0"]; // Totalizer Mode
    }
}
- (float) ConvertBitsToValue:(NSUInteger)bits NBits: (int) nBits MinVal: (float) minVal MaxVal: (float) maxVal{
    // Helper function converts a bit value to a float value where it's assume
    // that if all the bits are zero the desired float value is MinVal and
    // if all the bits are 1 the desired float value is maxVal.
    float stepSize = (maxVal - minVal)/(pow(2, nBits)-1.0);
    return bits*stepSize+minVal;
}
- (NSUInteger) ConvertValueToBits: (float) value NBits: (int) nBits MinVal: (float) minVal MaxVal: (float) maxVal{
    // Helper function converts a float value to a bit value.
    // It's assumed that a float value equal to MinVal is equal to a bit value of all 0s
    // and a float value equal to MaxVal is equal to all 1's
    float stepSize = (maxVal - minVal)/(pow(2,nBits)-1.0);
    return (value - minVal)/stepSize;
}
- (CONTROL_REG_MASK) CraftControlReg_isClkSrc:(bool)ClkSrc
                                      isLOSrc: (bool) LOsrc
                                       EcalOn: (bool)EcalOn
                                 CounterLZBOn: (bool) LZB
                                CounterTestOn: (bool) TestMode
                             CounterInhibitOn: (bool) Inhibit {
    // This is a helper function that handles the details of what should
    // be sent to the control register for a given functional state
    // So for example if you want to create a control register value you shouldn't
    // have to worry about the fact that the scaler requires the Inhibit bit to be low
    // to display properly. So you just tell this function Inhbit=false and it appropriately
    // creates the register value that reflects that.
    // See the CONTROL_REG_MASK type def and TUBiiSchematics Page 4 for more detail

    CONTROL_REG_MASK aRegVal =0;
    if (ClkSrc) {
        aRegVal |= clkSel_Bit; // Sets TUBii as default clock
    }
    if (!LOsrc) {
        aRegVal |= lockoutSel_Bit; // Sets MTCD as LO Src
    }
    if(EcalOn) {
        aRegVal |= ecalEnable_Bit; // Turns on ECAL mode
    }
    if(LZB) {
        aRegVal |= scalerLZB_Bit; // Gets rid of leading zeroes on scaler
    }
    if (!TestMode) {
        aRegVal |= scalerT_Bit; // Puts scaler in test mode
    }
    if (!Inhibit) {
        aRegVal |= scalerI_Bit; // Inhibits the scaler from displaying right.
    }
    return aRegVal;
}

- (BOOL) CounterMode {
    // See comments in setCounterMode for info
    //return ([self sendIntCmd:@"GetCounterMode"]) > 0;

    //Note TUBii server doesn't yet have GetCounterMode command so this hack is in here for now
    return CounterMode_memoryVal;
}

- (void) setCurrentState:(struct TUBiiState)aState {
    // Set every relevant variable state variable of TUBii
    // aState must have every variable filled in with a value
    // to have good behavior from this function
    [self setSmellieNPulses: aState.smellieRate];
    [self setTellieRate: aState.tellieRate];
    [self setPulserRate: aState.pulserRate];
    [self setSmelliePulseWidth: aState.smelliePulseWidth];
    [self setTelliePulseWidth: aState.telliePulseWidth];
    [self setPulseWidth: aState.pulserPulseWidth];
    [self setSmellieNPulses: aState.smellieNPulses];
    [self setTellieNPulses: aState.tellieNPulses];
    [self setNPulses: aState.pulserNPulses];
    [self setTellieDelay: aState.tellieDelay];
    [self setSmellieDelay: aState.smellieDelay];
    [self setGenericDelay: aState.genericDelay];
    [self setCaenMasks:aState.CaenChannelMask GainMask:aState.CaenGainMask];
    [self setGTDelaysBits:aState.DGT_Bits LOBits:aState.LO_Bits];
    [self setSpeakerMask: aState.speakerMask];
    [self setCounterMask: aState.counterMask];
    [self setTrigMask: aState.syncTrigMask setAsyncMask:aState.asyncTrigMask];
    [self setCounterMode: aState.CounterMode];
    [self setControlReg: aState.controlReg];
}

- (void) setCurrentStateFromDict:(NSMutableDictionary*)settingsDict {

    //Convert from dict to TubiiState
    @try{
        struct TUBiiState tubiiStateSettings = [self CurrentState];
        tubiiStateSettings.tellieDelay = [[settingsDict objectForKey:[self getStandardRunKeyForField:@"tellieDelay"]] floatValue];
        tubiiStateSettings.smellieDelay = [[settingsDict objectForKey:[self getStandardRunKeyForField:@"smellieDelay"]] floatValue];
        tubiiStateSettings.genericDelay = [[settingsDict objectForKey:[self getStandardRunKeyForField:@"genericDelay"]] floatValue];
        [self setCurrentState:tubiiStateSettings];
    } @catch(...){
        NSLogColor([NSColor redColor], @"TUBii: settings couldn't not be loaded \n");
    }

}

- (struct TUBiiState) CurrentState {
    // Returns a struct that that is a static representation of
    // TUBii's static.
    struct TUBiiState aState;

    // Write the write only variables to a reasonable value
    aState.smellieRate = 0;
    aState.tellieRate = 0;
    aState.pulserRate = 0;
    aState.smelliePulseWidth = 0;
    aState.telliePulseWidth = 0;
    aState.pulserPulseWidth = 0;
    aState.smellieNPulses = 0;
    aState.tellieNPulses = 0;
    aState.pulserNPulses = 0;
    //Get the rest from the TUBiiServer
    aState.tellieDelay = [self tellieDelay];
    aState.smellieDelay = [self smellieDelay];
    aState.genericDelay = [self genericDelay];
    aState.CaenChannelMask = [self caenChannelMask];
    aState.CaenGainMask = [self caenGainMask];
    aState.DGT_Bits = [self DGTBits];
    aState.LO_Bits = [self LODelayBits];
    aState.speakerMask = [self speakerMask];
    aState.counterMask = [self counterMask];
    aState.syncTrigMask = [self syncTrigMask];
    aState.asyncTrigMask = [self asyncTrigMask];
    aState.CounterMode = [self CounterMode];
    aState.controlReg = [self controlReg];
    return aState;
}

- (NSDictionary*) CurrentStateToDict
{

    //Manually cherry-pick struct elements and store it into dictionary.
    NSMutableDictionary* TubiiStateDict = [NSMutableDictionary dictionaryWithCapacity:3]; //CHANGE TO TubiiStateNumberOfKeys!!!
    @try{
        [TubiiStateDict setObject:[NSNumber numberWithUnsignedLong:[self CurrentState].tellieDelay] forKey:[self getStandardRunKeyForField:@"tellieDelay" ]];
        [TubiiStateDict setObject:[NSNumber numberWithUnsignedLong:[self CurrentState].smellieDelay] forKey:[self getStandardRunKeyForField:@"smellieDelay"]];
        [TubiiStateDict setObject:[NSNumber numberWithUnsignedLong:[self CurrentState].genericDelay] forKey:[self getStandardRunKeyForField:@"genericDelay"]];
    } @catch(...){
        NSLogColor([NSColor redColor], @"TUBii: settings couldn't not be saved \n");
    }

    return TubiiStateDict;

}

- (NSString*) getStandardRunKeyForField:(NSString*)aField
{
    aField = [NSString stringWithFormat:@"TUBii_%@",aField];
    return aField;
}

//////////////////////////////////////////
// Keep alive stuff -
// If ORCA dies we want to force tubii from
// sending triggers to the ellie system
-(void)activateKeepAlive
{
    /*
     Start a thread to constantly send a keep alive signal to the smellie interlock server
     */
    [self setKeepAliveThread:[[[NSThread alloc] initWithTarget:self selector:@selector(pulseKeepAlive:) object:nil] autorelease]];
    [[self keepAliveThread] start];
}

-(void)pulseKeepAlive:(id)passed
{
    /*
     A fuction to be run in a thread, continually sending keep alive pulses to the interlock server
     */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    int counter = 0;
    while (![[self keepAliveThread] isCancelled]) {
        @try{
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self sendOkCmd:@"keepAlive" print:NO];
            });
        } @catch(NSException* e) {
            NSLogColor([NSColor redColor], @"[TUBii]: Problem sending keep alive to TUBii server, reason: %@\n", [e reason]);
            break;
        }
        [NSThread sleepForTimeInterval:0.5];

        // This is a very long running thread need to relase the pool every so often
        if(counter == 1000){
            [pool release];
            pool = [[NSAutoreleasePool alloc] init];
            counter = 0;
        }
        counter = counter + 1;
    }
    NSLog(@"[TUBii]: Stopped sending keep-alive to TUBii - ELLIE pulses will be shut off\n");
    [pool release];
}

-(void)killKeepAlive
{
    /*
     Stop pulsing the keep alive and disarm the interlock
     */
    [[self keepAliveThread] cancel];
    NSLog(@"[TUBii]: Killing keep alive - ELLIE pulses will be shut off\n");
}


@end
