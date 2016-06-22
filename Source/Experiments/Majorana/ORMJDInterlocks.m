//
//  ORMJDInterlocks.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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

#import "ORMJDInterlocks.h"
#import "MajoranaModel.h"
#import "ORTaskSequence.h"
#import "ORRemoteSocketModel.h"
#import "ORAlarm.h"

//do NOT change this list without changing the enum states in the .h filef
static MJDInterlocksStateInfo state_info [kMJDInterlocks_NumStates] = {
    { kMJDInterlocks_Idle,               @"State Machine"},
    { kMJDInterlocks_Ping,               @"Ping Vac System"},
    { kMJDInterlocks_PingWait,           @"Ping Response"},
    { kMJDInterlocks_CheckHVisOn,        @"HV Status"},
    { kMJDInterlocks_UpdateVacSystem,    @"Update Vac System"},
    { kMJDInterlocks_GetShouldUnBias,    @"Vac: Should UnBias?"},
    { kMJDInterlocks_GetOKToBias,        @"Vac: OK to Bias?"},
    { kMJDInterlocks_HVRampDown,         @"Ramp HV Down"},
    { kMJDInterlocks_HandleHVDialog,     @"HV Dialog"},
    { kMJDInterlocks_FinalState,         @"Final Status"},
};

#define kAllowedPingRetry       5
#define kAllowedConnectionRetry 5
#define kAllowedResponseRetry   5

@implementation ORMJDInterlocks

@synthesize delegate,isRunning,currentState,stateStatus,slot,finalReport;

NSString* ORMJDInterlocksIsRunningChanged = @"ORMJDInterlocksIsRunningChanged";
NSString* ORMJDInterlocksStateChanged     = @"ORMJDInterlocksStateChanged";

- (id) initWithDelegate:(MajoranaModel*)aDelegate slot:(int)aSlot;
{
    self = [super init];
    self.delegate = aDelegate;
    self.slot = aSlot;
    retryCount = 0;
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.delegate    = nil;
    self.stateStatus = nil;
    self.finalReport = nil;
    [interlockFailureAlarm clearAlarm];
    [interlockFailureAlarm release];
    [super dealloc];
}

- (int) vacSystem
{
    if(slot==0) return 1; //CryoVacB
    else        return 0; //CryoVacA
}

- (NSString*) vacSystemName
{
    return [NSString stringWithFormat:@"CryoVac%c",'A'+[self vacSystem]];
}

- (int) module
{
    if(slot==0) return 1; //module 1 (assumes VME crate 1)
    else        return 2; //module 2 (assumes VME crate 2)
}

- (NSString*) moduleName
{
    return [NSString stringWithFormat:@"Module%d",[self module]];
}


- (void) reset:(BOOL)continueRunning
{
    printedErrorReport  = NO;
    self.finalReport    = nil;
    self.remoteOpStatus = nil;
    retryCount          = 0;
    
    currentState = kMJDInterlocks_Idle;
    [self setupStateArray]; //info for display in dialog
    NSLog(@"HV Interlocks procedure reset for %@\n",[self moduleName]);
    if(!continueRunning){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(step) object:nil];
    }
}

- (void) start
{
    if(retryCount == 0){
        [self setupStateArray]; //info for display in dialog
        [self setCurrentState:kMJDInterlocks_Ping]; //first state
    }
    else {
        [self setCurrentState:retryState]; //there was an error so doing a restart
    }
    self.isRunning = YES;
    [self performSelector:@selector(step) withObject:nil afterDelay:.1];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDInterlocksIsRunningChanged object:self];
}

- (void) stop
{
    self.isRunning = NO;
    self.currentState = kMJDInterlocks_Idle;
    [delegate setVmeCrateHVConstraint:[self module] state:NO];
}


- (void) setCurrentState:(int)aState
{
    currentState  = aState;
 
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDInterlocksStateChanged object:self];
}

- (void) setupStateArray
{
    [stateStatus release];
    stateStatus = [[NSMutableArray array] retain];
    int i;
    for(i=0;i<kMJDInterlocks_NumStates;i++){
        NSMutableDictionary* anEntry = [NSMutableDictionary dictionary];
        [anEntry setObject:@"--" forKey:@"status"];
        [stateStatus addObject:anEntry];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDInterlocksStateChanged object:self];
}



- (NSString*) stateName:(int)anIndex
{
    if(anIndex<kMJDInterlocks_NumStates){
        //double check the array
        if(state_info[anIndex].state == anIndex){
            return state_info[anIndex].name;
        }
        else {
            NSLogColor([NSColor redColor],@"MJDInterlocks Programmer Error: Struct entry mismatch: (enum)%d != (struct)%d\n",anIndex,state_info[anIndex].state);
            return @"Program Error";
        }
    }
    else {
        return @"";
    }
}

- (void) setState:(int)aState status:(id)aString color:(NSColor*)aColor
{
    NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:aColor,NSForegroundColorAttributeName,nil];
    NSAttributedString* s = [[[NSAttributedString alloc] initWithString:aString attributes:attrsDictionary] autorelease];

    NSMutableDictionary* anEntry = [NSMutableDictionary dictionary];
    [anEntry setObject:s forKey:@"status"];
    [stateStatus replaceObjectAtIndex:aState withObject:anEntry];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDInterlocksStateChanged object:self];
}

- (NSString*) stateStatus:(int)aStateIndex
{
    if(aStateIndex < [stateStatus count]){
        return [[stateStatus objectAtIndex:aStateIndex] objectForKey:@"status"];
    }
    else return @"";
}

- (int) numStates { return kMJDInterlocks_NumStates;}

- (void) step
{
    NSColor* normalColor  = [NSColor grayColor];
    NSColor* concernColor = [NSColor orangeColor];
    NSColor* badColor     = [NSColor colorWithCalibratedRed:.7 green:0 blue:0 alpha:1.0];
    NSColor* okColor      = [NSColor colorWithCalibratedRed:0 green:.7 blue:0 alpha:1.0];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(step) object:nil];
    switch (currentState){
        case kMJDInterlocks_Idle:
            [self setState:kMJDInterlocks_Idle status:@"Waiting" color:normalColor];
            break;
            
        case kMJDInterlocks_Ping:
            [self setState:kMJDInterlocks_Idle status:@"Running" color:normalColor];
            if(!retryCount)[self setState:kMJDInterlocks_Ping status:@"Pinging..." color:normalColor];
            [self ping];
            [self setCurrentState:kMJDInterlocks_PingWait];
            break;
            
        case kMJDInterlocks_PingWait:
            if(![self pingTaskRunning]){
                if(pingedSuccessfully){
                    retryCount = 0;
                    [self clearInterlockFailureAlarm];
                    [self setState:kMJDInterlocks_Ping status:@"OK" color:okColor];
                    [self setState:kMJDInterlocks_PingWait status:@"Got Response" color:normalColor];
                    [self setCurrentState:kMJDInterlocks_CheckHVisOn];
                    [self clearInterlockFailureAlarm];
                }
                else {
                    if(retryCount>=kAllowedPingRetry){
                        [self setState:kMJDInterlocks_FinalState status:@"Ping Failed" color:badColor];
                        [self setState:kMJDInterlocks_Ping status:@"Failed" color:badColor];
                        [self addToReport:@"Multiple attempts to ping the Vac system failed"];
                        [self addToReport:@"Vacuum system appears unreachable"];
                        [self setCurrentState:kMJDInterlocks_CheckHVisOn];
                        retryCount = 0;
                    }
                    else {
                        retryCount++;
                        [self postInterlockFailureAlarm: [NSString stringWithFormat:@"%@ failed ping. HV will rampDown.",[self vacSystemName]]];
                        [self setState:kMJDInterlocks_PingWait status:[NSString stringWithFormat:@"Failed: %d/%d",retryCount,kAllowedPingRetry] color:badColor];
                        [self setState:kMJDInterlocks_Ping status:@"Will Retry" color:concernColor];
                        retryState = kMJDInterlocks_Ping;  //force a re-ping next time around
                        [self setCurrentState:kMJDInterlocks_Idle];
                    }
                }
            }
            break;
            
        //lots depends on whether or not we are already biased.
        case kMJDInterlocks_CheckHVisOn:
            hvIsOn = [delegate anyHvOnVMECrate:[self module]];
            [self setState:kMJDInterlocks_CheckHVisOn status:[NSString stringWithFormat:@"HV is %@",hvIsOn?@"ON":@"OFF"] color:normalColor];
            if(pingedSuccessfully){
                [self setCurrentState:kMJDInterlocks_UpdateVacSystem];
            }
            else {
                //couldn't reach the Vac system. no point int trying to get the status
                [self setState:kMJDInterlocks_UpdateVacSystem     status:@"Skipped" color:normalColor];
                [self setState:kMJDInterlocks_GetShouldUnBias     status:@"Skipped" color:normalColor];
                [self setState:kMJDInterlocks_GetOKToBias         status:@"Skipped" color:normalColor];
                if(hvIsOn){
                    [self setCurrentState:kMJDInterlocks_HVRampDown];
                }
                else {
                    [self setState:kMJDInterlocks_HVRampDown     status:@"HV already OFF" color:normalColor];
                    [self addToReport:@"HV would have been ramped down but is already OFF"];

                    lockHVDialog = YES;
                    [self setCurrentState:kMJDInterlocks_HandleHVDialog];
                }
            }
            break;
        
        //send the HV Bias state to the Vac system
        case kMJDInterlocks_UpdateVacSystem:
            if(remoteOpStatus){
                if([[remoteOpStatus objectForKey:@"connected"] boolValue]==YES){
                    //it worked. move on.
                    retryCount = 0;
                    [self clearInterlockFailureAlarm];
                    [self setState:kMJDInterlocks_UpdateVacSystem status:@"HV Status Sent" color:normalColor];

                    if(hvIsOn){
                        [self setState:kMJDInterlocks_GetOKToBias     status:@"Skipped" color:normalColor];
                        [self setCurrentState:kMJDInterlocks_GetShouldUnBias];
                    }
                    else {
                        [self setState:kMJDInterlocks_GetShouldUnBias     status:@"Skipped" color:normalColor];
                        [self setCurrentState:kMJDInterlocks_GetOKToBias];
                    }
                }
                else {
                    if(retryCount>=kAllowedConnectionRetry){
                        [self setState:kMJDInterlocks_FinalState status:@"No Vac Connection"color:badColor];
                        [self addToReport:@"Could not send the Bias Info to the Vac system"];
                        if(!hvIsOn){
                            [self setState:kMJDInterlocks_GetShouldUnBias     status:@"Skipped" color:normalColor];
                            [self setState:kMJDInterlocks_GetOKToBias         status:@"Skipped" color:normalColor];
                            [self setState:kMJDInterlocks_HVRampDown          status:@"HV already OFF" color:normalColor];
                            lockHVDialog = YES;
                            [self setCurrentState:kMJDInterlocks_HandleHVDialog];
                        }
                        else {
                            [self setCurrentState:kMJDInterlocks_HVRampDown];
                        }
                        retryCount = 0;
                    }
                    else {
                        //no connection
                        retryCount++;
                        [self postInterlockFailureAlarm: [NSString stringWithFormat:@"%@ unreachable. HV will rampDown.",[self vacSystemName]]];
                        [self setState:kMJDInterlocks_UpdateVacSystem status:[NSString stringWithFormat:@"Failed: %d/%d",retryCount,kAllowedConnectionRetry] color:badColor];
                        retryState = kMJDInterlocks_UpdateVacSystem;  //force a retry of this state next time around
                        [self setCurrentState:kMJDInterlocks_Idle];
                    }
                }
                sentCmds = NO;
                self.remoteOpStatus=nil;
            }
            else {
                if(!sentCmds){
                    self.remoteOpStatus=nil;
                    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                                            [NSString stringWithFormat:@"[ORMJDVacuumModel,1 setDetectorsBiased:%d];",hvIsOn],
                                            [NSString stringWithFormat:@"[ORMJDVacuumModel,1 setHvUpdateTime:%d];",2*[delegate pollTime]],
                                            
                                            nil];
                    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
                    [self setState:kMJDInterlocks_UpdateVacSystem status:@"Sending..." color:normalColor];
                    sentCmds = YES;
                }
            }
            break;
            
        //HV is ON... see if we need to unbias
        case kMJDInterlocks_GetShouldUnBias:
            if(remoteOpStatus){
                if([[remoteOpStatus objectForKey:@"connected"] boolValue]==YES && [remoteOpStatus objectForKey:@"shouldUnBias"]){
                    //it worked. move on.
                    retryCount = 0;
                    [self clearInterlockFailureAlarm];
                    shouldUnBias = [[remoteOpStatus objectForKey:@"shouldUnBias"] boolValue];
                    if(shouldUnBias){
                        [self setState:kMJDInterlocks_GetShouldUnBias status:@"Vac says Unbias" color:badColor];
                        [self setState:kMJDInterlocks_FinalState      status:@"Vac says Unbias" color:badColor];
                        [self addToReport:@"Vac system asked for the HV to be unbiased"];
                        [self setCurrentState:kMJDInterlocks_HVRampDown];
                    }
                    else {
                        [self setState:kMJDInterlocks_GetShouldUnBias status:@"OK for Bias" color:okColor];
                        [self setState:kMJDInterlocks_FinalState      status:@"OK for Bias" color:okColor];
                        if(hvIsOn)[self setState:kMJDInterlocks_HVRampDown      status:@"Leave HV ON"  color:okColor];
                        else      [self setState:kMJDInterlocks_HVRampDown      status:@"HV is OFF"     color:normalColor];
                        
                        lockHVDialog = NO;
                        [self setCurrentState:kMJDInterlocks_HandleHVDialog];
                        
                        //added by wenqin in this condition of vacuum spike indicating possible breakdowns
                        if(hvIsOn){
                            shouldCheckBreakdown = [[remoteOpStatus objectForKey:@"shouldCheckBreakdown"] boolValue];
                            if(shouldCheckBreakdown){
                                [delegate checkBreakdown:[self module] vac:[self vacSystem]];
                            }
                        }
                    }
                }
                else {
                    if(retryCount>=kAllowedConnectionRetry){
                        [self setState:kMJDInterlocks_FinalState status:@"No Vac Connection" color:badColor];
                        [self addToReport:@"Vac system did not respond to requests asking if HV should be unbiased"];
                        [self setCurrentState:kMJDInterlocks_HVRampDown];
                        retryCount = 0;
                    }
                    else {
                        //no connection
                        retryCount++;
                         [self postInterlockFailureAlarm: [NSString stringWithFormat:@"%@ unreachable. HV will rampDown.",[self vacSystemName]]];
                        [self setState:kMJDInterlocks_GetShouldUnBias status:[NSString stringWithFormat:@"Waited: %d/%d",retryCount,kAllowedResponseRetry] color:badColor];
                        retryState = kMJDInterlocks_GetShouldUnBias;  //force a retry of this state next time around
                        [self setCurrentState:kMJDInterlocks_Idle];
                        
                    }
                }
                sentCmds = NO;
               self.remoteOpStatus=nil;
            }
            else {
                if(!sentCmds){
                    self.remoteOpStatus=nil;
                    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:@"shouldUnBias = [ORMJDVacuumModel,1 shouldUnbiasDetector];", nil]; //nil means end
                    [cmds addObject:@"shouldCheckBreakdown = [ORMJDVacuumModel,1 shouldCheckBreakdown];"];//added by wenqin

                    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
                    [self setState:kMJDInterlocks_GetShouldUnBias status:@"Asking..." color:normalColor];
                    sentCmds = YES;
               }
            }
            break;
            
            
        //HV is off... see if we would be allowed to bias HV
        case kMJDInterlocks_GetOKToBias:
            if(remoteOpStatus){
                if([[remoteOpStatus objectForKey:@"connected"] boolValue]==YES && [remoteOpStatus objectForKey:@"okToBias"]){
                    //it worked. move on.
                    retryCount = 0;
                    [self clearInterlockFailureAlarm];

                    okToBias = [[remoteOpStatus objectForKey:@"okToBias"] boolValue];
                    [self setState:kMJDInterlocks_GetOKToBias status:okToBias?@"OK to Bias":@"NOT OK to Bias" color:okToBias?okColor:badColor];
                    [self setState:kMJDInterlocks_HVRampDown status:@"HV Already OFF" color:normalColor];
                    if(okToBias){
                        [self setState:kMJDInterlocks_FinalState status:@"OK to Bias" color:okColor];
                        lockHVDialog = NO;
                    }
                    else {
                        [self setState:kMJDInterlocks_FinalState status:@"Do NOT Bias" color:badColor];
                        lockHVDialog = YES;
                    }
                    [self setCurrentState:kMJDInterlocks_HandleHVDialog];
              }
                else {
                    if(retryCount>=kAllowedConnectionRetry){
                        [self setState:kMJDInterlocks_FinalState status:@"No Response"color:badColor];
                        [self addToReport:@"Could not get OK to Bias confirmation from the Vac system"];
                        [self setState:kMJDInterlocks_GetShouldUnBias     status:@"Skipped" color:normalColor];
                        [self setState:kMJDInterlocks_HVRampDown          status:@"HV already OFF" color:normalColor];
                        lockHVDialog = YES;
                        [self setCurrentState:kMJDInterlocks_HandleHVDialog];
                         retryCount = 0;
                    }
                    else {
                        retryCount++;
                        [self postInterlockFailureAlarm: [NSString stringWithFormat:@"%@ unreachable. HV will rampDown.",[self vacSystemName]]];
                        [self setState:kMJDInterlocks_GetOKToBias status:[NSString stringWithFormat:@"Failed: %d/%d",retryCount,kAllowedConnectionRetry] color:badColor];
                        retryState = kMJDInterlocks_GetOKToBias;  //force a retry of this state next time around
                        [self setCurrentState:kMJDInterlocks_Idle];
                    }
                }
                sentCmds = NO;
                self.remoteOpStatus=nil;
            }
            else {
                if(!sentCmds){
                    self.remoteOpStatus=nil;
                    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:@"okToBias = [ORMJDVacuumModel,1 okToBiasDetector];", nil];
                    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
                    [self setState:kMJDInterlocks_GetOKToBias status:@"Asking..." color:normalColor];
                    sentCmds = YES;
               }
            }
        break;
            
        case kMJDInterlocks_HVRampDown:
            retryCount=0;
            if(hvIsOn){
                [delegate rampDownHV:[self module] vac:[self vacSystem]];
                if((([self module] == 2) && [delegate ignorePanicOnA]) ||
                   (([self module] == 1) && [delegate ignorePanicOnB]) ){
                    [self addToReport:@"HV should be ramped down, but was ignored"];
                    [self addToReport:@"HV Did NOT actually ramp down, because the 'Ignore Ramp Down Actions' was selected"];
                    [self setState:kMJDInterlocks_HVRampDown status:@"HV Ramp Ignored!"  color:badColor];
               }
                else {
                    [self addToReport:@"HV ramp down started"];
                    [self setState:kMJDInterlocks_HVRampDown status:@"HV Ramp Down!"  color:badColor];
                }
                
            }
            else {
                [self setState:kMJDInterlocks_HVRampDown status:@"HV already OFF" color:normalColor];
                [self addToReport:@"HV Would have ramped down, but was already off"];
           }
            lockHVDialog = YES;
            [self setCurrentState:kMJDInterlocks_HandleHVDialog];
            [self addToReport:@"HV Dialog Locked"];
          break;

            
        case kMJDInterlocks_HandleHVDialog:
            [delegate setVmeCrateHVConstraint:[self module] state:lockHVDialog];
            if(lockHVDialog)[self setState:kMJDInterlocks_HandleHVDialog status:@"Locked" color:badColor];
            else [self setState:kMJDInterlocks_HandleHVDialog status:@"Unlocked" color:okColor];
            [self setCurrentState:kMJDInterlocks_FinalState];
            break;

        case kMJDInterlocks_FinalState:
            if([finalReport count])[self errorReport];
            break;
    }
    if(currentState != kMJDInterlocks_Idle){
        [self performSelector:@selector(step) withObject:nil afterDelay:.3];
    }
}

- (void) addToReport:(NSString*)aString
{
    if(!self.finalReport)self.finalReport = [NSMutableArray array];
    [finalReport addObject:aString];
}

- (void) errorReport
{
    if(printedErrorReport)return;
    printedErrorReport = YES;
    NSLog(@"------------------------------------------------\n");
    NSLog(@"HV Interlock Voliation Report for %@\n",[self moduleName]);
    for(id aString in finalReport){
        NSLog(@"%@\n",aString);
    }
    NSLog(@"------------------------------------------------\n");
}

- (void) postInterlockFailureAlarm:(NSString*)reason
{
    BOOL hvOn = [delegate anyHvOnVMECrate:[self module]];
    if(hvOn){
        if(!interlockFailureAlarm){
            interlockFailureAlarm = [[ORAlarm alloc] initWithName:reason severity:kEmergencyAlarm];
            [interlockFailureAlarm setSticky:YES];
            [interlockFailureAlarm setHelpString:[NSString stringWithFormat:@"HV will be ramped down soon on %@ because [%@].\nThis alarm will not be cleared until the condition causing it goes away.\nYou can silence this alarm by acknowledging it", [self vacSystemName],reason]];
            [interlockFailureAlarm postAlarm];
        }
    }
    else {
        [self clearInterlockFailureAlarm];
    }
}

- (void) clearInterlockFailureAlarm
{
    if(interlockFailureAlarm){
        [interlockFailureAlarm clearAlarm];
        [interlockFailureAlarm release];
        interlockFailureAlarm = nil;
    }
}
@end


@implementation ORMJDInterlocks (Tasks)
- (void) ping
{
    if(!pingTask){
        pingedSuccessfully = NO;
        
        ORRemoteSocketModel* remObj = [delegate remoteSocket:slot];
        NSString*               ip  = [remObj remoteHost];
        
        ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
        pingTask = [[NSTask alloc] init];
        
        [pingTask setLaunchPath:@"/sbin/ping"];
        
        [pingTask setArguments: [NSArray arrayWithObjects:@"-c",@"3",@"-t",@"10",@"-q",ip,nil]];
        
        [aSequence addTaskObj:pingTask];
        [aSequence setVerbose:NO];
        [aSequence setTextToDelegate:YES];
        [aSequence launch];
    }
}

- (BOOL) pingTaskRunning            { return pingTask != nil;}
- (BOOL) pingedSuccessfully         { return pingedSuccessfully; }
- (void) tasksCompleted:(id)sender  { }
- (void) taskFinished:(NSTask*)aTask
{
    if(aTask == pingTask){
        [pingTask release];
        pingTask = nil;
    }
}

- (void) taskData:(NSString*)text
{
    if([text rangeOfString:@"round-trip"].location != NSNotFound){
        pingedSuccessfully = YES;
    }
    else if([text rangeOfString:@"100.0% packet loss"].location != NSNotFound){
        pingedSuccessfully = NO;
    }
    else if([text rangeOfString:@"Host is down"].location != NSNotFound){
        pingedSuccessfully = NO;
    }
    else if([text rangeOfString:@"No route to host"].location != NSNotFound){
        pingedSuccessfully = NO;
    }
}
@end

