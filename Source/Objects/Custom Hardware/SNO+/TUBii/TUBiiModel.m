//
//  TUBiiModel.m
//  Orca
//
//  Created by Ian Coulter on 9/15/15.
//
//

#import "TUBiiModel.h"
#import "NetSocket.h"
#import "netdb.h"

#define kRemotePort 4001
NSString* otherSystemIP = @"192.168.1.10";

@implementation TUBiiModel

- (void) setUpImage
{
    NSImage* img = [NSImage imageNamed:@"tubii"];
    
    // Scale the image down by half
    NSSize halfSize = [img size];
    halfSize.height = (int)(halfSize.height / 2);
    halfSize.width  = (int)(halfSize.width  / 2);
    [img setScalesWhenResized:YES];
    [img setSize:halfSize];
    
    [self setImage:img];
}

// Link the model to the controller
- (void) makeMainController
{
    [self linkToController:@"TUBiiController"];
}

// Initialize the model.
// Note that this is initWithCoder and not just init, and we
// call the superclass initWithCoder too!
- (id) initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    
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
    smellieDelay = 0;
    tellieDelay = 0;
    genericDelay = 0;
    trigMask=0;
    
    return self;
}

- (float) smellieRate
{
    return smellieRate;
}

- (float) tellieRate
{
    return tellieRate;
}

- (float) pulserRate
{
    return pulserRate;
}

- (float) smelliePulseWidth
{
    return smelliePulseWidth;
}

- (float) telliePulseWidth
{
    return telliePulseWidth;
}

- (float) pulseWidth
{
    return pulseWidth;
}

- (float) smellieDelay
{
    return smellieDelay;
}

- (float) tellieDelay
{
    return tellieDelay;
}

- (float) genericDelay
{
    return genericDelay;
}

- (void) sendCmd:(NSString*)aCmd
{
    //if([self isConnected]){
        [socket writeString:aCmd encoding:NSASCIIStringEncoding];
    //}
}

- (void) connectSocket:(BOOL)aFlag
{
    NSLog(@"Try to connect...\n");
    if(aFlag){
        NSLog(@"Connected and stuff? Port %i\n", kRemotePort);
        [self setSocket:[NetSocket netsocketConnectedToHost:otherSystemIP port:kRemotePort]];
        //[self sendCmd:@"gtpoll"];
        NSLog(@"Connected and stuff!\n");
    }
    else {
        [nsocket close];
        //[self setIsConnected:[socket isConnected]];
    }
}


- (void) connectToPort:(NSString*)command
{
    struct sockaddr_in address;
    struct hostent* pHostInfo;
    char* strHostName="192.168.80.25";

    int hSocketCommand;
    portNumber=4001;
    
    NSLog(@"Making a socket!\n");
    NSLog(@"Sending command %@\n",command);
    /*@try{hSocketCommand=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);}
    @catch(NSException* localException){
        NSLog(@"Could not make a socket.\n");
        return;
    }
    NSLog(@"so far\n");
    pHostInfo= gethostbyname(strHostName);
    if(pHostInfo == NULL){
        [NSException raise:@"No such host.\n"];
        return;
    }
    
    bzero((char *) &address, sizeof(address));
    address.sin_family = AF_INET;         // host byte order
    bcopy((char *) pHostInfo->h_addr, (char *) &address.sin_addr.s_addr, pHostInfo->h_length);
    address.sin_port = htons(portNumber);     // short, network byte order

    if(connect(hSocketCommand,(struct sockaddr*) &address, sizeof(address)) == -1){
        [NSException raise:@"Could not connect to host.\n"];
        return;
    }

    char* chcomm= [command UTF8String];
    write(hSocketCommand,chcomm,255);
    
    if(close(hSocketCommand) == -1){
        [NSException raise:@"Could not close socket.\n"];
        return;
    }*/
}


- (void) setSocket:(NetSocket*)aSocket
{
    [aSocket retain];
    [nsocket release];
    nsocket = aSocket;
    
    [nsocket setDelegate:self];
}

- (void) setSmellieRate:(float)value
{
    smellieRate = value;
}

- (void) setSmelliePulseWidth:(float)value
{
    smelliePulseWidth = value;
}

- (void) setSmellieNPulses:(int)value
{
    smellieNPulses = value;
}

- (void) fireSmelliePulser:(BOOL)button
{
    NSString* command=@"smelliepulser ";
    NSString* argument1=[NSString stringWithFormat:@"%f", smellieRate];
    NSString* argument2=[NSString stringWithFormat:@" %f", smelliePulseWidth];
    NSString* argument3=[NSString stringWithFormat:@" %i", smellieNPulses];
    NSString* endl=@" \r\n";
    command= [command stringByAppendingString:argument1];
    command= [command stringByAppendingString:argument2];
    command= [command stringByAppendingString:argument3];
    command = [command stringByAppendingString:endl];
    [self connectToPort:command];
}

- (void) stopSmelliePulser:(BOOL)button
{
    NSString* command=@"smelliepulser 0 0 0\r\n";
    [self connectToPort:command];
}

- (void) setTellieRate:(float)value
{
    tellieRate = value;
}

- (void) setTelliePulseWidth:(float)value
{
    telliePulseWidth = value;
}

- (void) setTellieNPulses:(int)value
{
    tellieNPulses = value;
}

- (void) fireTelliePulser:(BOOL)button
{
    NSString* command=@"telliepulser ";
    NSString* argument1=[NSString stringWithFormat:@"%f", tellieRate];
    NSString* argument2=[NSString stringWithFormat:@" %f", telliePulseWidth];
    NSString* argument3=[NSString stringWithFormat:@" %i", tellieNPulses];
    NSString* endl=@" \r\n";
    command= [command stringByAppendingString:argument1];
    command= [command stringByAppendingString:argument2];
    command= [command stringByAppendingString:argument3];
    command = [command stringByAppendingString:endl];
    [self connectToPort:command];
}

- (void) stopTelliePulser:(BOOL)button
{
    NSString* command=@"telliepulser 0 0 0\r\n";
    [self connectToPort:command];
}

- (void) setPulserRate:(float)value
{
    pulserRate = value;
}

- (void) setPulseWidth:(float)value
{
    pulseWidth = value;
}

- (void) setNPulses:(int)value
{
    NPulses = value;
}

- (void) firePulser:(BOOL)button
{
    NSString* command=@"genericpulser ";
    NSString* argument1=[NSString stringWithFormat:@"%f", pulserRate];
    NSString* argument2=[NSString stringWithFormat:@" %f", pulseWidth];
    NSString* argument3=[NSString stringWithFormat:@" %i", NPulses];
    NSString* endl=@" \r\n";
    command= [command stringByAppendingString:argument1];
    command= [command stringByAppendingString:argument2];
    command= [command stringByAppendingString:argument3];
    command = [command stringByAppendingString:endl];
    [self connectToPort:command];
}

- (void) stopPulser:(BOOL)button
{
    NSString* command=@"genericpulser 0 0 0\r\n";
    [self connectToPort:command];
}

- (void) setSmellieDelay:(float)value
{
    smellieDelay = value;
}

- (void) loadSmellieDelay:(BOOL)button
{
    NSString* command=@"smelliedelay ";
    NSString* argument=[NSString stringWithFormat:@"%f", smellieDelay];
    NSString* endl=@" \r\n";
    command= [command stringByAppendingString:argument];
    command = [command stringByAppendingString:endl];
    [self connectToPort:command];
}

- (void) setTellieDelay:(float)value
{
    tellieDelay = value;
}

- (void) loadTellieDelay:(BOOL)button
{
    NSString* command=@"telliedelay ";
    NSString* argument=[NSString stringWithFormat:@"%f", tellieDelay];
    NSString* endl=@" \r\n";
    command= [command stringByAppendingString:argument];
    command = [command stringByAppendingString:endl];
    [self connectToPort:command];
}

- (void) setGenericDelay:(float)value
{
    genericDelay = value;
}

- (void) loadDelay:(BOOL)button
{
    NSString* command=@"genericdelay ";
    NSString* argument=[NSString stringWithFormat:@"%f", genericDelay];
    NSString* endl=@" \r\n";
    command= [command stringByAppendingString:argument];
    command = [command stringByAppendingString:endl];
    [self connectToPort:command];
}

- (void) setTrigMask:(unsigned long)value
{
    trigMask = value;
}

- (void) loadTrigMask:(BOOL)button
{
    NSString* command=@"trigMask ";
    NSString* argument=[NSString stringWithFormat:@"%i", trigMask];
    NSString* endl=@" \r\n";
    command= [command stringByAppendingString:argument];
    command = [command stringByAppendingString:endl];
    [self connectToPort:command];
}

@end
