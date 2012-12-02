//-------------------------------------------------------------------------
//  HaloSentry.m
//
//  Created by Mark Howe on Saturday 12/01/2012.
//  Copyright (c) 2012 University of North Carolina. All rights reserved.
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

#pragma mark ***Imported Files
#import <Cocoa/Cocoa.h>
#import "HaloSentry.h"
#import "ORTaskSequence.h"
#import "NetSocket.h"
#import "ORAlarm.h"

NSString* HaloSentryIpNumber2Changed = @"HaloSentryIpNumber2Changed";
NSString* HaloSentryIpNumber1Changed = @"HaloSentryIpNumber1Changed";
NSString* HaloSentryIsPrimaryChanged = @"HaloSentryIsPrimaryChanged";
NSString* HaloSentryIsRunningChanged = @"HaloSentryIsRunningChanged";
NSString* HaloSentryStateChanged     = @"HaloSentryStateChanged";
NSString* HaloSentryTypeChanged      = @"HaloSentryTypeChanged";
NSString* HaloSentryPingTask         = @"HaloSentryPingTask";
NSString* HaloSentryIsConnectedChanged = @"HaloSentryIsConnectedChanged";
NSString* HaloSentryRemoteStateChanged = @"HaloSentryRemoteStateChanged";

#define kRemotePort 4667

@implementation HaloSentry

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [self registerNotificationObservers];
    [self objectsChanged:nil];
    return self;
}

- (void) dealloc 
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [socket release];
    [ipNumber2 release];
    [ipNumber1 release];
    [sbcArray release];
    [otherSystemIP release];
    [super dealloc];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
    
	[notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
}

- (void) objectsChanged:(NSNotification*)aNote
{
    [sbcArray release];
    sbcArray = [[[[NSApp delegate ]document] collectObjectsOfClass:NSClassFromString(@"ORVmecpuModel")]retain];
}

#pragma mark ***Accessors
- (NSString*) ipNumber2
{
    return ipNumber2;
}

- (void) setIpNumber2:(NSString*)aIpNumber2
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIpNumber2:ipNumber2];
    
    [ipNumber2 autorelease];
    ipNumber2 = [aIpNumber2 copy];    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryIpNumber2Changed object:self];
    [self setOtherIP];

}

- (NSString*) ipNumber1
{
    return ipNumber1;
}

- (void) setIpNumber1:(NSString*)aIpNumber1
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIpNumber1:ipNumber1];
    
    [ipNumber1 autorelease];
    ipNumber1 = [aIpNumber1 copy];    
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryIpNumber1Changed object:self];
    [self setOtherIP];
}

- (void) setOtherIP
{
    //one of the addresses is ours, one is the other machine
    //we need to know which is which so
    if(ipNumber1 && ipNumber2){
        NSArray* addresses =  [[NSHost currentHost] addresses];
        for(id anAddress in addresses){
            if([anAddress isEqualToString:ipNumber1]){
                [otherSystemIP autorelease];
                otherSystemIP = [ipNumber2 copy];
                break;
            }
            if([anAddress isEqualToString:ipNumber2]){
                [otherSystemIP autorelease];
                otherSystemIP = [ipNumber1 copy];
                break;
            }
        }
    }
}

- (BOOL) remoteMachineRunning
{
    return remoteMachineRunning;
}

- (void) setRemoteMachineRunning:(BOOL)aState
{
    remoteMachineRunning = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryRemoteStateChanged object:self];
 
}

- (BOOL) remoteORCARunning
{
    return remoteORCARunning;
}

- (void) setRemoteORCARunning:(BOOL)aState
{
    remoteORCARunning = aState;
   [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryRemoteStateChanged object:self];
}

- (BOOL) remoteRunInProgress
{
    return remoteRunInProgress;
}

- (void) setRemoteRunInProgress:(BOOL)aState
{
    remoteRunInProgress = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryRemoteStateChanged object:self];
}

- (enum eHaloSentryType) sentryType
{
    return sentryType;
}

- (void) setSentryType:(enum eHaloSentryType)aType;
{
    sentryType = aType;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryTypeChanged object:self];
}

- (NSString*) stateName
{
    switch(state){
        case eIdle:                 return @"Idle";
        case eStarting:             return @"Starting";
        case eStopping:             return @"Stopping";
        case eCheckRemoteMachine:   return @"Pinging";
        case eConnectToRemoteOrca:  return @"ConnectToRemoteOrca";
        case eGetRunState:          return @"GetRunState";
        case eCheckRunState:        return @"CheckRunState";
        case eWaitForPing:          return @"Ping Wait";
    }
}

- (NSString*) sentryTypeName
{
    switch(sentryType){
        case eNeither:      return @"Waiting";
        case ePrimary:      return @"Primary";
        case eSecondary:    return @"Secondary";
    }
}

- (enum eHaloSentryState) state
{
    return state;
}

- (void) setNextState:(enum eHaloSentryState)aState stepTime:(NSTimeInterval)aStep
{
    nextState = aState;
    stepTime = aStep;
}

- (NetSocket*) socket
{
    return socket;
}

- (void) setSocket:(NetSocket*)aSocket
{
    [aSocket retain];
    [socket release];
    socket = aSocket;
    
    [socket setDelegate:self];
}
- (BOOL) isConnected
{
	return isConnected;
}
- (void) setIsConnected:(BOOL)aIsConnected
{
	isConnected = aIsConnected;
	[[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryIsConnectedChanged object:self];
}

#pragma mark ***Run Stuff
- (void) start
{
    if(isRunning)return;
    isRunning = YES;
    [self setNextState:eStarting stepTime:1];
    [self step];
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryIsRunningChanged object:self];
}

- (void) stop
{
    if (!isRunning) return;
    [self setNextState:eStopping stepTime:1];
    isRunning = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryIsRunningChanged object:self];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [self setIpNumber2:[decoder decodeObjectForKey: @"ipNumber2"]];
    [self setIpNumber1:[decoder decodeObjectForKey: @"ipNumber1"]];
    [[self undoManager] enableUndoRegistration];    

    state = eIdle;
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:ipNumber2 forKey:@"ipNumber2"];
    [encoder encodeObject:ipNumber1 forKey:@"ipNumber1"];
}

- (NSUndoManager *)undoManager
{
    return [[[NSApp delegate]document]  undoManager];
}

- (void) postMachineAlarm
{
    if(!remoteMachineNotReachable){
        NSString* alarmName = [NSString stringWithFormat:@"%@ Unreachable",otherSystemIP];
        remoteMachineNotReachable = [[ORAlarm alloc] initWithName:alarmName severity:kHardwareAlarm];
        [remoteMachineNotReachable setHelpString:@"The backup machine is not reachable.\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
        [remoteMachineNotReachable setSticky:YES];
    }
    [remoteMachineNotReachable postAlarm];
}

- (void) clearMachineAlarm
{
    [remoteMachineNotReachable clearAlarm];
    remoteMachineNotReachable = nil;
}

- (void) step
{
    state = nextState;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryStateChanged object:self];

    switch(sentryType){
        case eNeither:
            [self stepSimpleWatch];
            break;
            
        case ePrimary:
            [self stepPrimarySystem];
            break;
            
        case eSecondary:
            [self stepSecondarySystem];
            break;
    }
}

- (void) stepSimpleWatch
{
    //Neither system is running. Just check the other system and ensure that the network is alive
    //and that ORCA is running. If a run is started on a machine, that machine will become primary
    //and the other one will become secondary
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(step) object:nil];
    switch (state){
        case eStarting:
            
            [self setRemoteMachineRunning:NO];
            [self setRemoteORCARunning:NO];
            [self setRemoteRunInProgress:NO];
            
            [self setNextState:eCheckRemoteMachine stepTime:.3];
            stepTime = .3;
            break;
            
        case eCheckRemoteMachine:
            [self ping];
            [self setNextState:eWaitForPing stepTime:1];
            break;
            
        case eWaitForPing:
            if(!pingTask){
                if(remoteMachineRunning){
                    [self setNextState:eConnectToRemoteOrca stepTime:1];
                    [self clearMachineAlarm];
                }
                else {
                    [self setNextState:eCheckRemoteMachine stepTime:60];
                    [self postMachineAlarm];
                    //remote machine not running. post alarm and retry later
                    //we are just watching at this point so do nothing other than
                    //the alarm post
                    [self postMachineAlarm];
                }
            }
            break;
 
        case eConnectToRemoteOrca:
            if(!isConnected)[self connectSocket:YES];
            [self setNextState:eGetRunState stepTime:1];
            break;
            
        case eGetRunState:
            if(isConnected){
                [self sendCmd:@"RunStatus=[RunControl isRunning];"];
                [self setNextState:eCheckRunState stepTime:1];
            }
            else {
                [self setNextState:eCheckRemoteMachine stepTime:10];
            }
            break;
            
        case eCheckRunState:
            if(!remoteMachineRunning){
                [self setNextState:eGetRunState stepTime:10];
            }
            else {
               //the remote macine is running. Flip over to being the secondarySystem
                [self setSentryType:eSecondary];
                [self setNextState:eStarting stepTime:.2];
            }
            
            break;

        case eStopping:
            [self connectSocket:NO];
            [self setRemoteMachineRunning:NO];
            [self setRemoteORCARunning:NO];
            [self setRemoteRunInProgress:NO];
            break;
            
        case eIdle:
            break;
    }
    if(state!=eStopping)[self performSelector:@selector(step) withObject:nil afterDelay:stepTime];

}

- (void) stepPrimarySystem
{
    //We are the primary, we are taking data. We will just monitor the other
    //system to ensure that it is alive. If not, all we do is post an alarm.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(step) object:nil];
    switch (state){
        case eStarting:
            [self setRemoteMachineRunning:NO];
            [self setRemoteORCARunning:NO];
            [self setRemoteRunInProgress:NO];
            [self setNextState:eCheckRemoteMachine stepTime:.3];
            stepTime = .3;
            break;
            
        case eCheckRemoteMachine:
            [self ping];
            [self setNextState:eWaitForPing stepTime:1];
            break;
            
        case eWaitForPing:
            if(!pingTask){
                if(remoteMachineRunning){
                    [self setNextState:eConnectToRemoteOrca stepTime:1];
                }
                else {
                    NSLog(@"post alarm\n");
                    [self setNextState:eCheckRemoteMachine stepTime:60];
                    //remote machine not running. post alarm and retry later
                    //we are just watching at this point so do nothing other than
                    //the alarm post
                }
            }
            break;
            
            
        //unsed state to stop compiler warnings
        case eIdle:
        case eStopping:
        case eConnectToRemoteOrca:
        case eGetRunState:
        case eCheckRunState:
            break;
    }
    if(state!=eStopping)[self performSelector:@selector(step) withObject:nil afterDelay:stepTime];
}

- (void) stepSecondarySystem
{
    //We are the secondary system -- the machine in waiting. We monitor the other machine and
    //if it dies, we have to take over and take control of the run
    //this sentry type should not be run unless the connection is open and we are ready to take over
    //running is it closes
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(step) object:nil];
    switch (state){
        case eStarting:
            [self setNextState:eGetRunState stepTime:10];
           break;
            
        case eStopping:
            break;
            
        case eGetRunState:
            if(isConnected){
                [self sendCmd:@"RunStatus=[RunControl isRunning];"];
                [self setNextState:eGetRunState stepTime:10];
            }
            else {
                //the connection was dropped. This signals that the other machine has crashed
                //we will now take over the run
                [self takeOverRunning];
            }
            break;
            
            //unsed state to stop compiler warnings
        case eIdle:
        case eCheckRemoteMachine:
        case eConnectToRemoteOrca:
        case eCheckRunState:
        case  eWaitForPing:
            break;

    }
    if(state!=eStopping)[self performSelector:@selector(step) withObject:nil afterDelay:stepTime];
}

- (void) takeOverRunning
{
    [self setSentryType:ePrimary];
    [self setNextState:eStarting stepTime:.2];
    //do the start up
}


#pragma mark •••Helpers
- (void) ping
{
	if(!pingTask){
		ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
		pingTask = [[NSTask alloc] init];
		
		[pingTask setLaunchPath:@"/sbin/ping"];
		[pingTask setArguments: [NSArray arrayWithObjects:@"-c",@"1",@"-t",@"10",@"-q",otherSystemIP,nil]];
		
		[aSequence addTaskObj:pingTask];
		[aSequence setVerbose:NO];
		[aSequence setTextToDelegate:YES];
		[aSequence launch];
		[[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryPingTask object:self];
	}
	else {
		[pingTask terminate];
	}
}

- (BOOL) pingTaskRunning
{
	return pingTask != nil;
}

- (void) tasksCompleted:(id)sender
{
    [pingTask release];
    pingTask = nil;

}

- (void) taskData:(NSString*)text
{
    if([text rangeOfString:@"100.0% packet loss"].location != NSNotFound){
        [self setRemoteMachineRunning:NO];
    }
    else {
        [self setRemoteMachineRunning:YES];
    }
}

- (void) connectSocket:(BOOL)aFlag
{
    if(aFlag){
        [self setSocket:[NetSocket netsocketConnectedToHost:otherSystemIP port:kRemotePort]];
    }
    else {
        [socket close];
        [self setIsConnected:[socket isConnected]];
    }
}

- (void) parseString:(NSString*)inString
{
    [[self undoManager] disableUndoRegistration];
    NSArray* lines= [inString componentsSeparatedByString:@"\n"];
    int n = [lines count];
    int i;    
    for(i=0;i<n;i++){
        NSString* aLine = [lines objectAtIndex:i];
        NSRange firstColonRange = [aLine rangeOfString:@":"];
        if(firstColonRange.location != NSNotFound){
            NSString* key = [aLine substringToIndex:firstColonRange.location];
            id value      = [aLine substringFromIndex:firstColonRange.location+1];
            if([key isEqualToString:@"runStatus"]){
                int runStatus = [value intValue];
                if(runStatus==1) [self setRemoteRunInProgress:YES];
                else             [self setRemoteRunInProgress:NO];
                NSLog(@"runStatus: %d\n",runStatus);
            }
        }
        else {
            //probably a heartbeat
            if([aLine hasPrefix:@"OrcaHeartBeat"]){
                NSLog(@"got heartbeat\n");
            }
        }
		
    }
	[[self undoManager] enableUndoRegistration];
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(id)aSocket
{
    if(aSocket == socket){
        [self setIsConnected:[socket isConnected]];
        [self sendCmd:@"[self setName:Halo];"];
        //able to connect, so ORCA is running remotely
        [self setRemoteORCARunning:YES];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
    if(inNetSocket == socket){
        NSString* inString = [socket readString:NSASCIIStringEncoding];
        if(inString){
            [self parseString:inString];
        }
    }
}


- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
        [self setIsConnected:NO];
    }
}

- (void) sendCmd:(NSString*)aCmd
{
    if([self isConnected]){
        [socket writeString:aCmd encoding:NSASCIIStringEncoding];
    }
}

@end
