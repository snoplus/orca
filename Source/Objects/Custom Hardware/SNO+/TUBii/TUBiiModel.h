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

@interface TUBiiModel : OrcaObject{
    float smellieRate;
    float tellieRate;
    float pulserRate;
    int smellieNPulses;
    int tellieNPulses;
    int NPulses;
    float smellieDelay;
    float tellieDelay;
    float genericDelay;
    unsigned long trigMask;
    
    CAEN_CHANNEL_MASK caenChannelMask;
    CAEN_GAIN_MASK caenGainMask;
    NetSocket *nsocket;
    int serverSocket;
	int workingSocket;
    unsigned long portNumber;
    int	connectState;
    char* strHostName;//="192.168.1.10";
}

@property (nonatomic) float smellieRate;
@property (nonatomic) float tellieRate;
@property (nonatomic) float pulserRate;
@property (nonatomic) int smellieNPulses;
@property (nonatomic) int tellieNPulses;
@property (nonatomic) int NPulses;
@property (nonatomic) float smellieDelay;
@property (nonatomic) float tellieDelay;
@property (nonatomic) float genericDelay;
@property (nonatomic) unsigned long trigMask;
@property (nonatomic) CAEN_CHANNEL_MASK caenChannelMask;
@property (nonatomic) CAEN_GAIN_MASK caenGainMask;

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
