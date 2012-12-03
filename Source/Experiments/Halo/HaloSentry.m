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
#import "HaloSentry.h"
#import "ORTaskSequence.h"
#import "NetSocket.h"
#import "ORRunModel.h"

NSString* HaloSentryIpNumber2Changed = @"HaloSentryIpNumber2Changed";
NSString* HaloSentryIpNumber1Changed = @"HaloSentryIpNumber1Changed";
NSString* HaloSentryIsPrimaryChanged = @"HaloSentryIsPrimaryChanged";
NSString* HaloSentryIsRunningChanged = @"HaloSentryIsRunningChanged";
NSString* HaloSentryStateChanged     = @"HaloSentryStateChanged";
NSString* HaloSentryTypeChanged      = @"HaloSentryTypeChanged";
NSString* HaloSentryPingTask         = @"HaloSentryPingTask";
NSString* HaloSentryIsConnectedChanged = @"HaloSentryIsConnectedChanged";
NSString* HaloSentryRemoteStateChanged = @"HaloSentryRemoteStateChanged";
NSString* HaloSentryStealthMode2Changed = @"HaloSentryStealthMode2Changed";
NSString* HaloSentryStealthMode1Changed = @"HaloSentryStealthMode1Changed";

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
    [remoteRunParams release];
    
    [remoteMachineNotReachable clearAlarm];
    [remoteMachineNotReachable release];
    
    [noOrcaConnection clearAlarm];
    [noOrcaConnection release];
    
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
    
    [notifyCenter addObserver : self
                     selector : @selector(runStarted:)
                         name : ORRunStartedNotification
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStopped:)
                         name : ORRunStoppedNotification
						object: nil];
}

#pragma mark ***Notifications
- (void) objectsChanged:(NSNotification*)aNote
{
    [runControl release];
    runControl = nil;
    [sbcArray release];
    [shapers release];
    shapers = [[[[NSApp delegate ]document] collectObjectsOfClass:NSClassFromString(@"ORShaperModel")]retain];
    sbcArray = [[[[NSApp delegate ]document] collectObjectsOfClass:NSClassFromString(@"ORVmecpuModel")]retain];
    NSArray* anArray = [[[NSApp delegate ]document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if([anArray count]){
        runControl = [[anArray objectAtIndex:0] retain];
    }
}

- (void) runStarted:(NSNotification*)aNote
{
    //a local run has started
    if(isRunning){
        [self setSentryType:ePrimary];
        [self setNextState:eStarting stepTime:.2];
        [self start];
    }
}

- (void) runStopped:(NSNotification*)aNote
{
    //a local run has ended. Switch back to being a neutral system
    if(isRunning){
        [self setSentryType:eNeither];
        [self setNextState:eStarting stepTime:.2];
        [self start];
    }
}

#pragma mark ***Accessors

- (BOOL) isRunning
{
    return isRunning;
}
- (void) setIsRunning:(BOOL)aState
{
    isRunning = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryIsRunningChanged object:self];
}

- (BOOL) otherSystemStealthMode
{
    return otherSystemStealthMode;
}

- (BOOL) stealthMode2
{
    return stealthMode2;
}

- (void) setStealthMode2:(BOOL)aStealthMode2
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStealthMode2:stealthMode2];
    stealthMode2 = aStealthMode2;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryStealthMode2Changed object:self];
    [self setOtherIP];
}

- (BOOL) stealthMode1
{
    return stealthMode1;
}

- (void) setStealthMode1:(BOOL)aStealthMode1
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStealthMode1:stealthMode1];
    stealthMode1 = aStealthMode1;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryStealthMode1Changed object:self];
    [self setOtherIP];
}

- (NSString*) ipNumber2
{
    if(!ipNumber2)return @"";
    else return ipNumber2;
}

- (void) setIpNumber2:(NSString*)aIpNumber2
{
    if(!aIpNumber2)aIpNumber2 = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIpNumber2:ipNumber2];
    
    [ipNumber2 autorelease];
    ipNumber2 = [aIpNumber2 copy];    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryIpNumber2Changed object:self];
    [self setOtherIP];

}

- (NSString*) ipNumber1
{
    if(!ipNumber1)return @"";
    else return ipNumber1;
}

- (void) setIpNumber1:(NSString*)aIpNumber1
{
    if(!aIpNumber1)aIpNumber1 = @"";
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
                otherSystemStealthMode = stealthMode2;
                break;
            }
            if([anAddress isEqualToString:ipNumber2]){
                [otherSystemIP autorelease];
                otherSystemIP = [ipNumber1 copy];
                otherSystemStealthMode = stealthMode1;
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
    if((remoteRunInProgress==YES) && isRunning){
        [[ORGlobal sharedGlobal] addRunVeto:@"Secondary" comment:@"Run in progress on Primary Machine"];
    }
    else {
        [[ORGlobal sharedGlobal] removeRunVeto:@"Secondary"];
    }

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
        case eConnectToRemoteOrca:  return @"Connecting";
        case eGetRunState:          return @"GetRunState";
        case eCheckRunState:        return @"Checking Run";
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
    if(isRunning || [otherSystemIP length]==0)return;
    [self setIsRunning:YES];
    [self setSentryType:eNeither];
    [self setNextState:eStarting stepTime:1];
    [self step];
}

- (void) stop
{
    if (!isRunning) return;
    [self setNextState:eStopping stepTime:1];
    [self step];
    [[ORGlobal sharedGlobal] removeRunVeto:@"Secondary"];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [self setIpNumber2:[decoder decodeObjectForKey: @"ipNumber2"]];
    [self setIpNumber1:[decoder decodeObjectForKey: @"ipNumber1"]];
    [self setStealthMode2:[decoder decodeBoolForKey: @"stealthMode2"]];
    [self setStealthMode1:[decoder decodeBoolForKey: @"stealthMode1"]];
    [[self undoManager] enableUndoRegistration];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:ipNumber2 forKey: @"ipNumber2"];
    [encoder encodeObject:ipNumber1 forKey: @"ipNumber1"];
    [encoder encodeBool:stealthMode2 forKey: @"stealthMode2"];
    [encoder encodeBool:stealthMode1 forKey: @"stealthMode1"];
}

- (NSUndoManager *)undoManager
{
    return [[[NSApp delegate]document]  undoManager];
}


- (void) postOrcaAlarm
{
    if(!noOrcaConnection){
        noOrcaConnection = [[ORAlarm alloc] initWithName:@"No ORCA Connection" severity:kHardwareAlarm];
        [noOrcaConnection setHelpString:@"No connection can be made to the other ORCA.\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
        [noOrcaConnection setSticky:YES];
    }
    [noOrcaConnection postAlarm];
}

- (void) clearOcraAlarm
{
    [noOrcaConnection clearAlarm];
    noOrcaConnection = nil;
}

- (void) postMachineAlarm
{
    if(!remoteMachineNotReachable && !otherSystemStealthMode){
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
#pragma mark •••Finite State Machines
- (void) step
{
    state = nextState;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryStateChanged object:self];
   
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(step) object:nil];
    
    switch(sentryType){
        case eNeither:[self stepSimpleWatch];break;
        case ePrimary:[self stepPrimarySystem];break;
        case eSecondary:[self stepSecondarySystem];break;
    }
    
    if(state!=eIdle)[self performSelector:@selector(step) withObject:nil afterDelay:stepTime];
}

- (void) stepSimpleWatch
{
    //Neither system is running. Just check the other system and ensure that the network is alive
    //and that ORCA is running. If a run is started on a machine, that machine will become primary
    //and the other one will become secondary
    switch (state){
        case eStarting:
            
            [self setRemoteMachineRunning:NO];
            [self setRemoteORCARunning:NO];
            [self setRemoteMachineRunning:NO];

            //----temp for testing
            //[self setRemoteMachineRunning:YES];
            //[self setNextState:eConnectToRemoteOrca stepTime:1];
            //--------------------
            
           [self setNextState:eCheckRemoteMachine stepTime:.3];
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
                    [self postMachineAlarm]; //just watching, so just post alarm
                }
            }
            break;
 
        case eConnectToRemoteOrca:
            if(!isConnected)[self connectSocket:YES];
            [self setNextState:eGetRunState stepTime:2];
            break;
            
        case eGetRunState:
            if(isConnected){
                [self clearOcraAlarm];
                [self sendCmd:@"runningState = [RunControl runningState];"];
                [self setNextState:eCheckRunState stepTime:1];
            }
            else {
                [self setNextState:eCheckRemoteMachine stepTime:10];
                [self postOrcaAlarm]; //just watching, so just post alarm
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
            [self finish];
            [self setNextState:eIdle stepTime:.2];
           break;
            
        default: break;
    }

}

- (void) stepPrimarySystem
{
    //We are the primary, we are taking data. We will just monitor the other
    //system to ensure that it is alive. If not, all we do is post an alarm.
    switch (state){
        case eStarting:
            [self setRemoteMachineRunning:NO];
            [self setRemoteORCARunning:NO];
            [self setNextState:eCheckRemoteMachine stepTime:.3];
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
                    [self postMachineAlarm];
                    [self setNextState:eCheckRemoteMachine stepTime:60];
                    //remote machine not running. post alarm and retry later
                    //we are just watching at this point so do nothing other than
                    //the alarm post
                }
            }
            break;
            
        case eStopping:
            [self finish];
            [self setNextState:eIdle stepTime:.2];
            break;
            
        default: break;
    }
}

- (void) stepSecondarySystem
{
    //We are the secondary system -- the machine in waiting. We monitor the other machine and
    //if it dies, we have to take over and take control of the run
    //this sentry type should not be run unless the connection is open and we are ready to take over
    //running is it closes
    switch (state){
        case eStarting:
            [self setNextState:eGetRunState stepTime:10];
           break;
                        
        case eGetRunState:
            if(isConnected){
                [self clearOcraAlarm];
                [self askForRunStatus];
                [self setNextState:eGetRunState stepTime:30];
            }
            else {
                [self postOrcaAlarm];
                //the connection was dropped. This signals that the other machine has crashed
                [self takeOverRunning];
            }
            break;

        case eStopping:
            [self finish];
            [self setNextState:eIdle stepTime:.2];
            break;

        default: break;

    }
}

- (void) finish
{
    [self connectSocket:NO];
    [self setRemoteMachineRunning:NO];
    [self setRemoteORCARunning:NO];
    [self clearMachineAlarm];
    [self clearOcraAlarm];
    [self setIsRunning:NO];
}

- (void) takeOverRunning
{
    //switch over to being the primary system
    [[ORGlobal sharedGlobal] removeRunVeto:@"Secondary"];
    [self setSentryType:ePrimary];
    [self setNextState:eStarting stepTime:.2];
    //do the start up...
    // 1) double check the SBCs
    // 2) set up RunControl
    // 3) start a run
}


#pragma mark •••Helpers
- (void) ping
{
    if(!pingTask){
        if(otherSystemStealthMode){
            [self setRemoteMachineRunning:YES];
        }
        else {
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
        if(otherSystemStealthMode) [self setRemoteMachineRunning:YES];
        else [self setRemoteMachineRunning:NO];
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
    if(!remoteRunParams){
        remoteRunParams = [[NSMutableDictionary alloc]init];
    }
    NSArray* lines= [inString componentsSeparatedByString:@"\n"];
    int n = [lines count];
    int i;    
    for(i=0;i<n;i++){
        NSString* aLine = [lines objectAtIndex:i];
        NSRange firstColonRange = [aLine rangeOfString:@":"];
        if(firstColonRange.location != NSNotFound){
            NSString* key = [aLine substringToIndex:firstColonRange.location];
            id value      = [aLine substringFromIndex:firstColonRange.location+1];
            [remoteRunParams setObject:value forKey:key];
            if([key isEqualToString:@"runStatus"]){
                int ival = [value intValue];
                [self setRemoteRunInProgress:ival!=eRunStopped];
            }
        }
        else {
            if([aLine hasPrefix:@"OrcaHeartBeat"]){
                //should get a heartbeat every 30 seconds if ORCA is not hung
               // NSLog(@"got heartbeat\n");
            }
        }
		
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryRemoteStateChanged object:self];

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

- (void) askForRunStatus
{
    //put a 1 onto the parameter so we can load the parameter
    //into the right status dictionary
    [self sendCmd:@"runNumber = [RunControl runNumber];"];
    [self sendCmd:@"subRunNumber = [RunControl subRunNumber];"];
    [self sendCmd:@"elapsedTime = [RunControl elapsedRunTime];"];
    [self sendCmd:@"repeatRun = [RunControl repeatRun];"];
    [self sendCmd:@"timedRun = [RunControl timedRun];"];
    [self sendCmd:@"timeLimit = [RunControl timeLimit];"];
    [self sendCmd:@"quickStart = [RunControl quickStart];"];
    [self sendCmd:@"offline = [RunControl offlineRun];"];
    [self sendCmd:@"runningState = [RunControl runningState];"];
    [self sendCmd:@"startTime = [RunControl startTimeAsString];"];
}

- (void) toggleSystems
{
    
    //to be done... have to make a fsm to control the process
    //only proceed if connection Open
    if([self isConnected]){
        if([runControl isRunning]){
           // [runControl stopRun];
           // [self sendCmd:@"[RunControl startRun];"];
         }
        else {
           // [self sendCmd:@"[RunControl stopRun];"];
           // [runControl startRun];
        }
    }
}
@end