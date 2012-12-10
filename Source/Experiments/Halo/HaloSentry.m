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
#import "SBC_Link.h"
#import "ORShaperModel.h"

NSString* HaloSentryIpNumber2Changed = @"HaloSentryIpNumber2Changed";
NSString* HaloSentryIpNumber1Changed = @"HaloSentryIpNumber1Changed";
NSString* HaloSentryIsPrimaryChanged = @"HaloSentryIsPrimaryChanged";
NSString* HaloSentryIsRunningChanged = @"HaloSentryIsRunningChanged";
NSString* HaloSentryStateChanged     = @"HaloSentryStateChanged";
NSString* HaloSentryTypeChanged      = @"HaloSentryTypeChanged";
NSString* HaloSentryIsConnectedChanged = @"HaloSentryIsConnectedChanged";
NSString* HaloSentryRemoteStateChanged = @"HaloSentryRemoteStateChanged";
NSString* HaloSentryStealthMode2Changed = @"HaloSentryStealthMode2Changed";
NSString* HaloSentryStealthMode1Changed = @"HaloSentryStealthMode1Changed";
NSString* HaloSentryMissedHeartbeat     = @"HaloSentryMissedHeartbeat";
NSString* HaloSentrySbcRootPwdChanged   = @"HaloSentrySbcRootPwdChanged";

#define kRemotePort 4667

@implementation HaloSentry

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [self registerNotificationObservers];
    return self;
}

- (void) dealloc 
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [socket release];
    [ipNumber2 release];
    [ipNumber1 release];
    [sbcs release];
    [otherSystemIP release];
    [sbcPingTasks release];
    [unPingableSBCs release];
    [sentryLog release];
    
    [self clearPingAlarm];
    [self clearConnectionAlarm];
    [self clearOrcaHungAlarm];
    [self clearNoRemoteSentryAlarm];
    [self clearRunProblemAlarm];
    [self clearListModAlarm];
    
    [super dealloc];
}

- (void) sleep
{
    [self stop];
}

- (void) wakeUp
{
    if(wasRunning)[self start];
}

- (void) awakeAfterDocumentLoaded
{
    if(wasRunning) [self start];
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
                     selector : @selector(runStarted:)
                         name : ORRunStartSubRunNotification
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStopped:)
                         name : ORRunStoppedNotification
						object: nil];
}

#pragma mark ***Notifications
- (void) objectsChanged:(NSNotification*)aNote
{
    [self collectObjects];
}

- (void) collectObjects
{
    [sbcPingTasks release];
    sbcPingTasks = nil;
    
    [sbcs release];
    sbcs = nil;
    sbcs = [[[[NSApp delegate ]document] collectObjectsOfClass:NSClassFromString(@"ORVmecpuModel")]retain];

    [shapers release];
    shapers = nil;
    shapers = [[[[NSApp delegate ]document] collectObjectsOfClass:NSClassFromString(@"ORShaperModel")]retain];
    
    [runControl release];
    runControl = nil;
    NSArray* anArray = [[[NSApp delegate ]document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if([anArray count])runControl = [[anArray objectAtIndex:0] retain];
}

- (void) runStarted:(NSNotification*)aNote
{
    //a local run has started
    if(sentryIsRunning && !ignoreRunStates){
        [self setSentryType:ePrimary];
        [self setNextState:eStarting stepTime:.2];
        [self step];
        [self updateRemoteMachine];
    }
}

- (void) runStopped:(NSNotification*)aNote
{
    //a local run has ended. Switch back to being a neutral system
    if(sentryIsRunning && !ignoreRunStates){
        [self setSentryType:eNeither];
        [self setNextState:eStarting stepTime:.2];
        [self step];
    }
}

#pragma mark ***Accessors
- (NSString*)sbcRootPwd
{
    if(sbcRootPwd)return sbcRootPwd;
    else return @"";
}

- (void) setSbcRootPwd:(NSString*)aString
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSbcRootPwd:sbcRootPwd];
    [sbcRootPwd autorelease];
    sbcRootPwd = [aString copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryIsRunningChanged object:self];
}

- (BOOL) sentryIsRunning
{
    return sentryIsRunning;
}
- (void) setSentryIsRunning:(BOOL)aState
{
    wasRunning = aState;
    sentryIsRunning = aState;
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
                [thisSystemIP autorelease];
                thisSystemIP = [ipNumber1 copy];
                otherSystemStealthMode = stealthMode2;
                break;
            }
            if([anAddress isEqualToString:ipNumber2]){
                [otherSystemIP autorelease];
                otherSystemIP = [ipNumber1 copy];
                [thisSystemIP autorelease];
                thisSystemIP = [ipNumber2 copy];
                otherSystemStealthMode = stealthMode1;
                break;
            }
        }
    }
}


- (enum eHaloStatus) remoteMachineReachable
{
    return remoteMachineReachable;
}

- (void) setRemoteMachineReachable:(enum eHaloStatus)aState
{
    remoteMachineReachable = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryRemoteStateChanged object:self];
}

- (enum eHaloStatus) remoteORCARunning
{
    return remoteORCARunning;
}

- (void) setRemoteORCARunning:(enum eHaloStatus)aState
{
    remoteORCARunning = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryRemoteStateChanged object:self];
}


- (enum eHaloStatus) remoteRunInProgress
{
    return remoteRunInProgress;
}

- (void) setRemoteRunInProgress:(enum eHaloStatus)aState
{
    remoteRunInProgress = aState;
    
    if((aState == eYES) && sentryIsRunning){
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
        case eGetSecondaryState:    return @"Checking Sentry";
        case eWaitForLocalRunStop:  return @"Run Stop Wait";
        case eWaitForRemoteRunStop: return @"Run Stop Wait";
        case eWaitForLocalRunStart: return @"Run Start Wait";
        case eWaitForRemoteRunStart:return @"Run Start Wait";
        case eKillCrates:           return @"Killing Crates";
        case eKillCrateWait:        return @"Wait For Crates";
        case eStartCrates:          return @"Starting Crates";
        case eStartCrateWait:       return @"Wait For Crates";
        case eStartRun:             return @"Starting Run";
        case eCheckRun:             return @"Checking Run";
        case eBootCrates:           return @"Booting Crates";
        case eWaitForBoot:          return @"Waiting For Crates";
        case ePingCrates:           return @"Pinging Crates";
    }
}

- (NSString*) sentryTypeName
{
    switch(sentryType){
        case eNeither:          return @"Waiting";
        case ePrimary:          return @"Primary";
        case eSecondary:        return @"Secondary";
        case eHealthyToggle:    return @"Toggle";
        case eTakeOver:         return @"TakeOver";
    }
}

- (NSString*) remoteMachineStatusString
{
    if(remoteMachineReachable == eOK){
        if(otherSystemStealthMode) return @"Stealth Mode";
        else                       return @"Reachable";
    }
    else if(remoteMachineReachable == eBad)          return  @"Unreachable";
    else if(remoteMachineReachable == eBeingChecked) return  @"Being Checked";
    else return @"?";
}

- (NSString*) connectionStatusString
{
    if(missedHeartbeatCount==0){
        if(remoteORCARunning == eYES)               return @"Connected";
        else if(remoteORCARunning == eBad)          return @"NOT Connected";
        else if(remoteORCARunning == eBeingChecked) return @"Being Checked";
    }
    else if(missedHeartbeatCount<kMaxHungCount){
        return [NSString stringWithFormat:@"Missed %d Heartbeat%@",missedHeartbeatCount,missedHeartbeatCount>1?@"s":@""];
    }
    return @"Hung";
}

- (NSString*) remoteORCArunStateString
{
    if(remoteMachineReachable == eOK){
        if(remoteRunInProgress == eOK)               return @"Running";
        else if(remoteRunInProgress == eBad)         return @"NOT Running";
        else if(remoteRunInProgress == eBeingChecked)return @"Being Checked";
    }
    return @"?";
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

- (BOOL) runIsInProgress
{
    return (remoteRunInProgress == eYES) || [runControl isRunning];
}

#pragma mark ***Run Stuff
- (void) start
{
    if(sentryIsRunning || [otherSystemIP length]==0)return;
    [self collectObjects];
    [self setSentryIsRunning:YES];
    [self setSentryType:eNeither];
    [self setNextState:eStarting stepTime:1];
    [self step];
}

- (void) stop
{
    if (!sentryIsRunning) return;
    [self setNextState:eStopping stepTime:1];
    [self step];
    [[ORGlobal sharedGlobal] removeRunVeto:@"Secondary"];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [self setIpNumber2:     [decoder decodeObjectForKey: @"ipNumber2"]];
    [self setIpNumber1:     [decoder decodeObjectForKey: @"ipNumber1"]];
    [self setStealthMode2:  [decoder decodeBoolForKey:   @"stealthMode2"]];
    [self setStealthMode1:  [decoder decodeBoolForKey:   @"stealthMode1"]];
    [self setSbcRootPwd:    [decoder decodeObjectForKey: @"sbcRootPwd"]];
    
    wasRunning = [decoder decodeBoolForKey: @"wasRunning"];
    [[self undoManager] enableUndoRegistration];
    
    [self registerNotificationObservers];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:ipNumber2     forKey: @"ipNumber2"];
    [encoder encodeObject:ipNumber1     forKey: @"ipNumber1"];
    [encoder encodeBool:stealthMode2    forKey: @"stealthMode2"];
    [encoder encodeBool:stealthMode1    forKey: @"stealthMode1"];
    [encoder encodeBool:wasRunning      forKey: @"wasRunning"];
    [encoder encodeObject:sbcRootPwd    forKey: @"sbcRootPwd"];
}

- (NSUndoManager *)undoManager
{
    return [[[NSApp delegate]document]  undoManager];
}

- (void) postConnectionAlarm
{
    if(!noConnectionAlarm){
        noConnectionAlarm = [[ORAlarm alloc] initWithName:@"No ORCA Connection" severity:kHardwareAlarm];
        [noConnectionAlarm setHelpString:@"No connection can be made to the other ORCA.\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
        [noConnectionAlarm setSticky:YES];
    }
    [noConnectionAlarm postAlarm];
}

- (void) clearConnectionAlarm
{
    [noConnectionAlarm clearAlarm];
    noConnectionAlarm = nil;
}

- (void) postPingAlarm
{
    if(!pingFailedAlarm && !otherSystemStealthMode){
        NSString* alarmName = [NSString stringWithFormat:@"%@ Unreachable",otherSystemIP];
        pingFailedAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kHardwareAlarm];
        [pingFailedAlarm setHelpString:@"The backup machine is not reachable.\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
        [pingFailedAlarm setSticky:YES];
    }
    [pingFailedAlarm postAlarm];
}

- (void) clearPingAlarm
{
    [pingFailedAlarm clearAlarm];
    pingFailedAlarm = nil;
}

- (void) postOrcaHungAlarm
{
    if(!orcaHungAlarm){
        NSString* alarmName = [NSString stringWithFormat:@"ORCA %@ Hung",otherSystemIP];
        orcaHungAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kHardwareAlarm];
        [orcaHungAlarm setHelpString:@"The primary ORCA appears hung.\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
        [orcaHungAlarm setSticky:YES];
    }
    [orcaHungAlarm postAlarm];
}


- (void) clearOrcaHungAlarm
{
    [orcaHungAlarm clearAlarm];
    orcaHungAlarm = nil;
}

- (void) postNoRemoteSentryAlarm
{
    if(!noRemoteSentryAlarm){
        noRemoteSentryAlarm = [[ORAlarm alloc] initWithName:@"No Remote Sentry" severity:kInformationAlarm];
        [noRemoteSentryAlarm setHelpString:@"There is no remote sentry watching this machine.\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
        [noRemoteSentryAlarm setSticky:YES];
    }
    [noRemoteSentryAlarm postAlarm];
}


- (void) clearNoRemoteSentryAlarm
{
    [noRemoteSentryAlarm clearAlarm];
    noRemoteSentryAlarm = nil;
}

- (void) postRunProblemAlarm:(NSString*)aTitle
{
    if(!runProblemAlarm){
        runProblemAlarm = [[ORAlarm alloc] initWithName:aTitle severity:kHardwareAlarm];
        [runProblemAlarm setHelpString:@"There was trouble with the run state.\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
        [runProblemAlarm setSticky:YES];
    }
    [runProblemAlarm postAlarm];

}
- (void) clearRunProblemAlarm
{
    [runProblemAlarm clearAlarm];
    runProblemAlarm = nil;
}
- (void) postListModAlarm
{
    if(!listModAlarm){
        listModAlarm = [[ORAlarm alloc] initWithName:@"Readout List Modified" severity:kHardwareAlarm];
        [listModAlarm setHelpString:@"There was a problem with one of the SBCs, so the offending object was removed from the readout list"];
        [listModAlarm setSticky:NO];
    }
    [listModAlarm postAlarm];
}


- (void) clearListModAlarm
{
    [listModAlarm clearAlarm];
    listModAlarm = nil;
}

#pragma mark •••Finite State Machines
- (void) step
{
    state    =  nextState;
    loopTime += stepTime;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryStateChanged object:self];
   
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(step) object:nil];
    
    switch(sentryType){
        case eNeither:      [self stepSimpleWatch];     break;
        case ePrimary:      [self stepPrimarySystem];   break;
        case eSecondary:    [self stepSecondarySystem]; break;
        case eHealthyToggle:[self stepHealthyToggle];   break;
        case eTakeOver:     [self stepTakeOver];        break;
    }
    
    if(state!=eIdle)[self performSelector:@selector(step) withObject:nil afterDelay:stepTime];
}

//------------------------------------------------------------------
//Neither system is running. Just check the other system and ensure that the network is alive
//and that ORCA is running. If a run is started on a machine, that machine will become primary
//and the other one will become secondary
- (void) stepSimpleWatch
{
    switch (state){
        case eStarting:
            [self flushSentryLog];
            [self setRemoteMachineReachable:eBeingChecked];
            [self setRemoteRunInProgress: eUnknown];
            [self setNextState:eCheckRemoteMachine stepTime:.3];
            break;
            
        case eCheckRemoteMachine:
            [self ping];
            [self setNextState:eWaitForPing stepTime:.3];
            break;
            
        case eWaitForPing:
            if(!pingTask){
                if(remoteMachineReachable == eYES){
                    [self setRemoteORCARunning:eBeingChecked];
                    [self setNextState:eConnectToRemoteOrca stepTime:1];
                    [self clearPingAlarm];
                }
                else {
                    [self setNextState:eCheckRemoteMachine stepTime:60];
                    [self postPingAlarm]; //just watching, so just post alarm
                }
            }
            break;
 
        case eConnectToRemoteOrca:
            if(!isConnected)[self connectSocket:YES];
            [self setNextState:eGetRunState stepTime:2];
            break;
            
        case eGetRunState:
            if(isConnected){
                [self clearConnectionAlarm];
                [self sendCmd:@"runStatus = [RunControl runningState];"];
                [self setNextState:eCheckRunState stepTime:1];
           }
            else {
                [self setRemoteORCARunning:eBeingChecked];
                [self setNextState:eCheckRemoteMachine stepTime:10];
            }
            break;
            
        case eCheckRunState:
            if(remoteRunInProgress != eYES){
                [self setNextState:eGetRunState stepTime:10];
            }
            else {
               //the remote macine is running. Flip over to being the secondarySystem
                [self setSentryType:eSecondary];
                [self setNextState:eStarting stepTime:.3];
            }
            break;

        case eStopping:
            [self finish];
          break;
            
        default: break;
    }

}

//------------------------------------------------------------------
//We are the primary, we are taking data. We will just monitor the other
//system to ensure that it is alive. If not, all we do is post an alarm.
- (void) stepPrimarySystem
{
    switch (state){
        case eStarting:
            [self flushSentryLog];
            [self setRemoteMachineReachable:eBeingChecked];
            [self setNextState:eCheckRemoteMachine stepTime:.3];
            break;
            
        case eCheckRemoteMachine:
            [self ping];
            [self setNextState:eWaitForPing stepTime:1];
            break;
            
        case eWaitForPing:
            if(!pingTask){
                if(remoteMachineReachable == eYES){
                    [self setNextState:eConnectToRemoteOrca stepTime:10];
                    [self clearPingAlarm];
               }
                else {
                    [self postPingAlarm];
                    [self setNextState:eCheckRemoteMachine stepTime:60];
                    //remote machine not running. post alarm and retry later
                    //we are just watching at this point so do nothing other than
                    //the alarm post
                }
            }
            break;
 
        case eConnectToRemoteOrca:
            if(!isConnected)[self connectSocket:YES];
            [self setNextState:eGetSecondaryState stepTime:2];
            break;
            
        case eGetSecondaryState:
            if(isConnected){
                [self sendCmd:@"remoteSentryRunning = [HaloModel sentryIsRunning];"];
                [self setNextState:eGetSecondaryState stepTime:30];
            }
            else {
                [self setNextState:eStarting stepTime:10];
            }
            break;

            
        case eStopping:
            [self finish];
            break;
            
        default: break;
    }
}
//------------------------------------------------------------------
//We are the secondary system -- the machine in waiting. We monitor the other machine and
//if it dies, we have to take over and take control of the run
//this sentry type should not be run unless the connection is open and we are ready to take over
- (void) stepSecondarySystem
{
    switch (state){
        case eStarting:
            [self flushSentryLog];
            [self setRemoteRunInProgress:eBeingChecked];
            [self setNextState:eGetRunState stepTime:2];
           break;
                        
        case eGetRunState:
            if(isConnected && !orcaHungAlarm){
                [self setNextState:eGetRunState stepTime:30];
                //we should get the runStatus at run boundaries, but we'll ask anyway
                [self sendCmd:@"runStatus = [RunControl runningState];"];
            }
            else {
                //the connection was dropped (other mac crashed) or other mac appears hung.
                [self takeOverRunning];
            }
            break;

        case eStopping:
            [self finish];
            break;

        default: break;

    }
}

//------------------------------------------------------------------
//The System is running, but the user requested a toggle. Just do it
//
- (void) stepHealthyToggle
{
    switch (state){
        case eStarting:
            loopTime = 0;
            ignoreRunStates = YES;
            [self flushSentryLog];
            [self appendToSentryLog:@"Toggling healthy systems"];
            if([runControl isRunning]){
               wasLocalRun = YES;
               [self appendToSentryLog:@"Stopping local run."];
               [runControl stopRun];
                [self setNextState:eWaitForLocalRunStop stepTime:.1];
            }
            else if (remoteRunInProgress == eYES){
                wasLocalRun = NO;
                [self appendToSentryLog:@"Stopping remote run."];
                [self sendCmd:@"[RunControl stopRun];"];
                [self setNextState:eWaitForRemoteRunStop stepTime:.1];
            }
            break;
            
        case eWaitForLocalRunStop:
            if(![runControl isRunning]){
                [self appendToSentryLog:@"Local run stopped. Passing control to other system"];
                [self sendCmd:@"[HaloModel takeOverRunning];"];
                [self setSentryType:eNeither];
                [self setNextState:eStarting stepTime:2];
           }
            else {
                if(loopTime>10){
                    //something is seriously wrong...
                    [self appendToSentryLog:[NSString stringWithFormat:@"Local run didn't stop after %.0f seconds.\n",loopTime]];
                    [self appendToSentryLog:@"Passing control to other system"];
                    [self postRunProblemAlarm:@"Local Run didn't stop"];
                    [self sendCmd:@"[HaloModel takeOver:YES];"];
                    [self setSentryType:eNeither];
                    [self setNextState:eStarting stepTime:2];
                }
            }
            break;
            
        case eWaitForRemoteRunStop:
            if(remoteRunInProgress == eNO){
                [self takeOverRunning:YES];
            }
            else {
                if(loopTime>10){
                    [self appendToSentryLog:[NSString stringWithFormat:@"Remote run didn't stop after %.0f seconds.\n",loopTime]];
                    [self postRunProblemAlarm:@"Remote Run didn't stop"];
                    [self takeOverRunning];
                }
            }
           break;
 
        default: break;
    }
}
//------------------------------------------------------------------
//Something is wrong with the other machine. It is hung or it dropped the
//connection to this machine. Either way we will take over the run.
//The main idea here is to kill the sbc readouts to prepare for the restart,
//then try and figure out if the sbcs are healthy, and then restart from
//this machine.
- (void) stepTakeOver
{
    switch (state){
        case eStarting:
            [unPingableSBCs release];
            unPingableSBCs= nil;
            [self setNextState:eKillCrates stepTime:.1];
            break;
            
        case eKillCrates:
            [self appendToSentryLog:@"Killing Crates to ensure the socket is cleared."];
            for(id anSBC in sbcs)[[anSBC sbcLink] killCrate];
            [self setNextState:eKillCrateWait stepTime:.1];
            loopTime = 0;
            break;
            
        case eKillCrateWait:
            if(loopTime >= 8)[self setNextState:ePingCrates stepTime:.1];
            break;
  
        case ePingCrates:
            if(!unPingableSBCs) unPingableSBCs = [[NSMutableArray arrayWithArray:sbcs]retain];
            [self appendToSentryLog:@"Pinging Crates"];
            for(id anSBC in sbcs)[[anSBC sbcLink] pingOnce];
            [self setNextState:eWaitForPing stepTime:.2];
            loopTime = 0;
         break;
  
        case eWaitForPing:
            if(loopTime >= 5){
                if([unPingableSBCs count] == [sbcs count]){
                    [self appendToSentryLog:@"**None of the SBCs responded to ping. Will try rebooting."];
                    [self setNextState:eBootCrates stepTime:.1];
                }
                else {
                    [self appendToSentryLog:@"**Some of the SBCs responded to ping. Some didn't -- they are removed from readout list"];

                    [self removeFromReadoutList:unPingableSBCs];
                    [self setNextState:eStartCrates stepTime:2];
                    [self postListModAlarm];
                }
            }
            else {
                for(id anSBC in sbcs){
                    if([[anSBC sbcLink]pingedSuccessfully]){
                        [unPingableSBCs removeObject:anSBC];
                    }
                }
                if([unPingableSBCs count] == 0){
                    [self appendToSentryLog:@"All SBCs responded to ping"];
                    [self setNextState:eStartCrates stepTime:2];
                }
            }
            break;

            
        case eStartCrates:
            for(id anSBC in sbcs){
                if(![unPingableSBCs containsObject:anSBC]){
                    if(![[anSBC sbcLink] isConnected]){
                        [self appendToSentryLog:[NSString stringWithFormat:@"Start crate @ %@",[[anSBC sbcLink] IPNumber]]];
                        [[anSBC sbcLink] startCrate];
                    }
                }
            }
            [self setNextState:eStartCrateWait stepTime:.1];
            loopTime = 0;
            break;
            
        case eStartCrateWait:
            if(loopTime >= 5){
                [self appendToSentryLog:@"**One or more crates didn't restart. Will try rebooting."];
                [self setNextState:eBootCrates stepTime:.1];
            }
            else {
                int connectedSBCCount=0;
                for(id anSBC in sbcs){
                    if(![unPingableSBCs containsObject:anSBC]){
                        if([[anSBC sbcLink]isConnected]){
                            connectedSBCCount++;
                        }
                    }
                }
                if(connectedSBCCount == ([sbcs count]-[unPingableSBCs count])){
                    [self setNextState:eStartRun stepTime:.1];
                }
            }
            break;

        case eStartRun:
            [self appendToSentryLog:@"Try to start run"];
            [[ORGlobal sharedGlobal] removeRunVeto:@"Secondary"];
            [runControl startRun];
            [self setNextState:eCheckRun stepTime:.1];
            loopTime = 0;
            break;

        case eCheckRun:
            if(loopTime >= 5){
                [self appendToSentryLog:@"**Run failed to start. Will try rebooting."];
                [self setNextState:eBootCrates stepTime:.1];
            }
            else if([runControl isRunning]){
                [self appendToSentryLog:@"Now running again"];
                [self setSentryType:ePrimary];
                [self setNextState:eStarting stepTime:.1];
            }
            else [self setNextState:eCheckRun stepTime:.1];
            break;
  
        case eBootCrates:
            if(!triedBooting){
                [self appendToSentryLog:@"**Takeover failed after one reboot"];
                [self postRunProblemAlarm:@"Sentry unable to start run"];
                [self setNextState:eStopping stepTime:.1];
            }
            else {
                triedBooting = YES;
                for(id anSBC in sbcs)[[anSBC sbcLink] shutDown:sbcRootPwd reboot:YES];
                [self setNextState:eWaitForBoot stepTime:.1];
                loopTime = 0;
            }
            break;

            
        case eWaitForBoot:
            stepTime = 5;
            if(loopTime >= 45){
                [self appendToSentryLog:@"Wait for reboot over. Will try to start run again."];
                [self setNextState:eStarting stepTime:.1];
            }
           break;
        
            
        case eStopping:
            [self setSentryType:eNeither];
            [self setNextState:eIdle stepTime:.1];
            [self finish];
            break;

        default: break;
    }
}

- (void) finish
{
    [self connectSocket:NO];
    [self setRemoteMachineReachable:eUnknown];
    [self setRemoteORCARunning:eUnknown];
    [self setRemoteRunInProgress:eUnknown];
    [self clearPingAlarm];
    [self clearConnectionAlarm];
    [self clearOrcaHungAlarm];
    [self setSentryIsRunning:NO];
    [self setSentryType:eNeither];
    [self setNextState:eIdle stepTime:.2];
}

- (void) takeOverRunning:(BOOL)quiet
{
    if(quiet)NSLogColor([NSColor redColor],@"Something is wrong so the secondary system is attempting a takeover\n");
    triedBooting = NO;
    [self setSentryType:eTakeOver];
    [self setNextState:eStarting stepTime:.2];
    [self step];
}

- (void) takeOverRunning
{
    [self takeOverRunning:NO];
}

- (void) appendToSentryLog:(NSString*)aString
{
    if([aString hasPrefix:@"**"])   NSLogColor([NSColor redColor],@"%@\n",aString);
    else                            NSLog(@"%@\n",aString);
    if(!sentryLog)sentryLog = [[NSMutableArray array] retain];
    if(aString)[sentryLog addObject:aString];
}

- (void) flushSentryLog
{
    [sentryLog release];
    sentryLog = nil;
}

#pragma mark •••Helpers
- (void) ping
{
    if(!pingTask){
        if(otherSystemStealthMode){
            [self setRemoteMachineReachable:eYES];
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
        }
    }
    else {
        [pingTask terminate];
    }
}

- (void) pingSBC:(id)anSBC
{
    if(!sbcPingTasks)sbcPingTasks = [[NSMutableDictionary dictionary] retain];
    NSTask* aPingTask = [sbcPingTasks objectForKey:anSBC];
    
    if(!aPingTask){

        ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
        aPingTask = [[NSTask alloc] init];
        [sbcPingTasks setObject:aPingTask forKey:anSBC];
        [aPingTask setLaunchPath:@"/sbin/ping"];
        [aPingTask setArguments: [NSArray arrayWithObjects:@"-c",@"1",@"-t",@"10",@"-q",otherSystemIP,nil]];
        
        [aSequence addTaskObj:aPingTask];
        [aSequence setVerbose:NO];
        [aSequence setTextToDelegate:YES];
        [aSequence launch];
        
    }
    else {
        [aPingTask terminate];
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
        if(otherSystemStealthMode) [self setRemoteMachineReachable:eYES];
        else                       [self setRemoteMachineReachable:eBad];
    }
    else {
        [self setRemoteMachineReachable:eYES];
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
    //handle returns from the other system
    //If a connection is open, a heartbeat should arrive every 30 seconds
    //the run state of the remote machine should arrive whenever it changes
    NSArray* lines= [inString componentsSeparatedByString:@"\n"];
    int n = [lines count];
    int i;    
    for(i=0;i<n;i++){
        NSString* aLine = [lines objectAtIndex:i];
        NSRange firstColonRange = [aLine rangeOfString:@":"];
        if(firstColonRange.location != NSNotFound){
            NSString* key = [aLine substringToIndex:firstColonRange.location];
            id value      = [aLine substringFromIndex:firstColonRange.location+1];
            long ival = (long)[value doubleValue];
            if([key isEqualToString:@"runStatus"] || [key isEqualToString:@"runningState"]){
                if(ival==eRunStopped)   [self setRemoteRunInProgress:eNO];
                else                    [self setRemoteRunInProgress:eYES];
            }
            else if([key isEqualToString:@"remoteSentryRunning"]){
                if(ival == NO)  [self postNoRemoteSentryAlarm];
                else            [self clearNoRemoteSentryAlarm];
            }
        }
        else {
            if([aLine hasPrefix:@"OrcaHeartBeat"]){
                [self startHeartbeatTimeout];
            }
         }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryRemoteStateChanged object:self];

}

- (void) removeFromReadoutList:(NSArray*)someObjects
{
    [[self undoManager] disableUndoRegistration];

    NSArray* dataTasks = [[[[NSApp delegate ]document] collectObjectsOfClass:NSClassFromString(@"ORDataTaskModel")]retain];
    for(id aDataTask in dataTasks){
        for(id anObj in someObjects){
            [aDataTask removeObject:anObj];
        }
    }
    [[self undoManager] enableUndoRegistration];
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(id)aSocket
{
    if(aSocket == socket){
        [self setIsConnected:[socket isConnected]];
        [self clearConnectionAlarm];
        [self setRemoteORCARunning:eYES];
        [self startHeartbeatTimeout];
    }
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
        [self setIsConnected:NO];
        [self setRemoteORCARunning:eBad];
        [self postConnectionAlarm];
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

- (void) sendCmd:(NSString*)aCmd
{
    if([self isConnected]){
        [socket writeString:aCmd encoding:NSASCIIStringEncoding];
    }
}

- (void) updateRemoteMachine
{
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setRunNumber:%lu];",[runControl runNumber]]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setSubRunNumber:%d];",[runControl subRunNumber]]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setRepeatRun:%d];",[runControl repeatRun]]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setTimedRun:%d];",[runControl timedRun]]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setTimeLimit:%f];",[runControl timeLimit]]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setQuickStart:%d];",[runControl quickStart]]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setOfflineRun:%d];",[runControl offlineRun]]];
    [self sendCmd:@"runStatus = [RunControl runningState];"];
    
    for(id aShaper in shapers){
        int i;
        for(i=0;i<8;i++){
            [self sendCmd:[NSString stringWithFormat:@"[%@ setThreshold:%d withValue:%d];",[aShaper fullID],i,[aShaper threshold:i]]];
            [self sendCmd:[NSString stringWithFormat:@"[%@ setGain:%d withValue:%d];",[aShaper fullID],i,[aShaper threshold:i]]];

        }
        
    }
}

- (void) startHeartbeatTimeout
{
    [self clearOrcaHungAlarm];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(missedHeartBeat) object:nil];
    [self performSelector:@selector(missedHeartBeat) withObject:nil afterDelay:40];
    missedHeartbeatCount = 0;
}

- (void) cancelHeartbeatTimeout
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(missedHeartBeat) object:nil];
}

- (void) missedHeartBeat
{
    missedHeartbeatCount++;
    if(missedHeartbeatCount>=kMaxHungCount){
        [self postOrcaHungAlarm];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(missedHeartBeat) object:nil];
    [self performSelector:@selector(missedHeartBeat) withObject:nil afterDelay:40];
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryMissedHeartbeat object:self];

}

- (short) missedHeartBeatCount
{
    return missedHeartbeatCount;
}
- (BOOL) systemIsHeathy
{
    if(!pingFailedAlarm && 
       !noConnectionAlarm &&
       !orcaHungAlarm &&
       !noRemoteSentryAlarm) {
        return YES;
    }
    else {
        return NO;
    }
}

- (void) toggleSystems
{
    [self flushSentryLog];
    if([self systemIsHeathy]){
        [self setSentryType:eHealthyToggle];
        [self setNextState:eStarting stepTime:.1];
        [self step];
    }
    else {
        [self takeOverRunning];
    }
}

- (NSString*) report
{
    NSString* theReport = @"";
    theReport = [theReport stringByAppendingFormat:@"Reporting Machine: %@\n",thisSystemIP];
    theReport = [theReport stringByAppendingString:@"----------------------------------------------\n"];
    theReport = [theReport stringByAppendingFormat:@"Sentry Running: %@\n",[self sentryIsRunning]?@"YES":@"NO"];
    theReport = [theReport stringByAppendingFormat:@"Sentry Type   : %@\n",[self sentryTypeName]];
    if(sentryType == ePrimary){
        theReport = [theReport stringByAppendingString:@"Current running as the Primary Machine\n"];
        theReport = [theReport stringByAppendingString:@"Status of the Secondary machine:\n"];
        theReport = [theReport stringByAppendingFormat:@"Computer: %@\n",[self remoteMachineStatusString]];
        theReport = [theReport stringByAppendingFormat:@"ORCA: %@\n",[self connectionStatusString]];
    }
    else if(sentryType == eSecondary){
        theReport = [theReport stringByAppendingString:@"Current running as the Secondary Machine\n"];
        if([self systemIsHeathy]){
            theReport = [theReport stringByAppendingString:@"Status of the Primary machine:\n"];
            theReport = [theReport stringByAppendingFormat:@"Computer: %@\n",[self remoteMachineStatusString]];
            theReport = [theReport stringByAppendingFormat:@"ORCA: %@\n",[self connectionStatusString]];
            theReport = [theReport stringByAppendingFormat:@"Running: %@\n",[self remoteORCArunStateString]];
        }
    }
    else if(sentryType == eNeither){
        theReport = [theReport stringByAppendingString:@"No Run is Progress"];
    }
    else {
        theReport = [theReport stringByAppendingString:@"Sentry state is one that would indicate a problem is being addressed now"];
   }

    if([sentryLog count]!=0){
        theReport = [theReport stringByAppendingString:@"----------------------------------------------\n"];
        theReport = [theReport stringByAppendingString:@"These exists a Sentry Log:\n\n"];
        for(id aLine in sentryLog){
            theReport = [theReport stringByAppendingString:aLine];
        }
        theReport = [theReport stringByAppendingString:@"----------------------------------------------\n"];
    }
    
    return theReport;
}

@end