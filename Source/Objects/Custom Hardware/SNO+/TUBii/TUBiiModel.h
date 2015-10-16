//
//  TUBiiModel.h
//  Orca
//
//  Created by Ian Coulter on 9/15/15.
//
//

#import "OrcaObject.h"
@class NetSocket;

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
    NetSocket *nsocket;

    int serverSocket;
	int workingSocket;
    unsigned long portNumber;
    int	connectState;
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

@end
