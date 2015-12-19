//
//  TUBiiModel.h
//  Orca
//
//  Created by Ian Coulter on 9/15/15.
//
//

#import "OrcaObject.h"
@class NetSocket;

//typedef NS_OPTIONS(NSUInteger, CAEN_BIT_MASK);
typedef NS_OPTIONS(NSUInteger, CAEN_CHANNEL_MASK) {
    channelSel_0 = 1<<0,
    channelSel_1 = 1<<1,
    channelSel_2 = 1<<2,
    channelSel_3 = 1<<3
};
typedef NS_OPTIONS(NSUInteger,CAEN_GAIN_MASK)
{
    gainSel_0 = 1<<0,
    gainSel_1 = 1<<1,
    gainSel_2 = 1<<2,
    gainSel_3 = 1<<3,
    gainSel_4 = 1<<4,
    gainSel_5 = 1<<5,
    gainSel_6 = 1<<6,
    gainSel_7 = 1<<7
};
typedef NS_OPTIONS(NSUInteger,CONTROL_REG_MASK)
{
    clkSel = 1<<0,      //1 indicates FOX is default clk TUB is backup. O is vice versa
    lockoutSel = 1<<1,  //1 is MTCD supplies LO
    ecalEnable = 1<<2,  //1 is for when an ECAL is being done. GT is routed to MTCD's EXT_Async
    scaler_LZB = 1<<3,  //Scaler Lead Zero Blanking
    scaler_T = 1<<4,    //Scaler Test* when low scaler is test mode
    scaler_I = 1<<5    //Scaler Inhibit* when low counting is inhibited
};
typedef NS_OPTIONS(NSUInteger, TRIG_MASK)
{
    ExtTrig0 = 1<<0,
    ExtTrig1 = 1<<1,
    ExtTrig2 = 1<<2,
    ExtTrig3 = 1<<3,
    ExtTrig4 = 1<<4,
    ExtTrig5 = 1<<5,
    ExtTrig6 = 1<<6,
    ExtTrig7 = 1<<7,
    ExtTrig8 = 1<<8,
    ExtTrig9 = 1<<9,
    ExtTrig10 = 1<<10,
    ExtTrig11 = 1<<11,
    ExtTrig12 = 1<<12,
    ExtTrig13 = 1<<13,
    ExtTrig14 = 1<<14,
    ExtTrig15 = 1<<15,
    Mimic1 = 1<<16,
    Mimic2 = 1<<17,
    Burst = 1<<18,
    Prescale = 1<<19,
    Combo = 1<<20,
    GT = 1<<21
};

@interface TUBiiModel : OrcaObject{
    float smellieRate;
    float tellieRate;
    float pulserRate;
    float smelliePulseWidth;
    float telliePulseWidth;
    float pulseWidth;
    int smellieNPulses;
    int tellieNPulses;
    int NPulses;
    float smellieDelay;
    float tellieDelay;
    float genericDelay;
    unsigned long trigMask;
    float MTCAMimic1_Threshold;
    float DGT_DelayLength;
    float LO_DelayLength;
    NSUInteger speakerMask;
    NSUInteger counterMask;

    CAEN_CHANNEL_MASK caenChannelMask;
    CAEN_GAIN_MASK caenGainMask;

    NetSocket *nsocket;
    int serverSocket;
	int workingSocket;
    unsigned long portNumber;
    int	connectState;
    char* strHostName;//="192.168.80.25";
}

@property (nonatomic) float smellieRate;
@property (nonatomic) float tellieRate;
@property (nonatomic) float pulserRate;
@property (nonatomic) float smelliePulseWidth;
@property (nonatomic) float telliePulseWidth;
@property (nonatomic) float pulseWidth;
@property (nonatomic) int smellieNPulses;
@property (nonatomic) int tellieNPulses;
@property (nonatomic) int NPulses;
@property (nonatomic) float smellieDelay;
@property (nonatomic) float tellieDelay;
@property (nonatomic) float genericDelay;
@property (nonatomic) unsigned long trigMask;
@property (nonatomic) CAEN_CHANNEL_MASK caenChannelMask;
@property (nonatomic) CAEN_GAIN_MASK caenGainMask;
@property (nonatomic) NSUInteger speakerMask;
@property (nonatomic) NSUInteger counterMask;

- (void) connectSocket:(BOOL)aFlag;
- (void) connectToPort:(NSString*)command;
- (void) fireSmelliePulser:(BOOL)button;
- (void) fireTelliePulser:(BOOL)button;
- (void) firePulser:(BOOL)button;
- (void) stopSmelliePulser:(BOOL)button;
- (void) stopTelliePulser:(BOOL)button;
- (void) stopPulser:(BOOL)button;
- (void) loadSmellieDelay:(BOOL)button;
- (void) loadTellieDelay:(BOOL)button;
- (void) loadDelay:(BOOL)button;
- (void) setTrigMask:(unsigned long)trigMask;
- (void) loadTrigMask:(BOOL)button;

- (CAEN_CHANNEL_MASK) caenChannelMask;
- (CAEN_GAIN_MASK) caenGainMask;
-(void) setCaenMasks: (CAEN_CHANNEL_MASK)aChannelMask
            GainMask:(CAEN_GAIN_MASK) aGainMask;

@end
