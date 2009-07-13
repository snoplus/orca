//
//  ORGlobal.m
//  Orca
//
//  Created by Mark Howe on Wed Dec 24 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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

#import "ORStatusController.h"
#import "SynthesizeSingleton.h"
#import "NSNotifications+Extensions.h"
#import <sys/sysctl.h>

//--------------------------------------------------------
NSString* runState[kNumRunStates] ={
    @"Stoppped",
    @"Running",
    @"Run Starting",
	@"Run Stopping",
	@"Bewteen Sub Runs"
};
//--------------------------------------------------------
//--------------------------------------------------------
NSString* ORTaskStateName[] = {
    @"Stopped",
    @"Running",
    @"Waiting"
};
//--------------------------------------------------------

#pragma mark •••External Strings

NSString* ORQueueRecordForShippingNotification  = @"ORQueueRecordForShippingNotification";


NSString* ORNeedMoreTimeToStopRun			= @"Extend Time to stop run";
NSString* ORRunAboutToStartNotification     = @"Run is about to start";
NSString* ORRunStartedNotification          = @"Run started";
NSString* ORRunAboutToStopNotification      = @"Run is about to stop";
NSString* ORRunStoppedNotification          = @"Run Stopped";
NSString* ORRunFinalCallNotification        = @"Run Final Call";
NSString* ORRunStatusChangedNotification    = @"Run Status Changed";
NSString* ORTaskStateChangedNotification    = @"Task State Changed";
NSString* ORRunModeChangedNotification      = @"Run Mode Has Changed";
NSString* ORRequestRunStop					= @"ORRequestRunStop";
NSString* ORRequestRunRestart				= @"ORRequestRunRestart";
NSString* ORRequestRunHalt					= @"ORRequestRunHalt";

NSString* ORRunTypeMask			    = @"ORRunTypeMask";
NSString* ORRunStatusValue		    = @"Run Status Value";
NSString* ORRunStatusString		    = @"Run Status String";
NSString* ORRunVetosChanged			= @"ORRunVetosChanged";

NSString* ORHardwareEnvironmentNoisy = @"ORHardwareEnvironmentNoisy";
NSString* ORHardwareEnvironmentQuiet = @"ORHardwareEnvironmentQuiet";


ORGlobal* gOrcaGlobals = nil;


@implementation ORGlobal

SYNTHESIZE_SINGLETON_FOR_ORCLASS(Global);

//don't call this, use +sharedInstance instead
-(id)init
{
    self = [super init];
	gOrcaGlobals = sharedGlobal;
    [self registerNotificationObservers];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [runModeAlarm clearAlarm];
    [runModeAlarm release];
	[runVetos release];
    [super dealloc];
}


- (void) registerNotificationObservers
{
    NSNotificationCenter* noteCenter = [NSNotificationCenter defaultCenter];
    [noteCenter addObserver : self
                   selector : @selector(runStatusChanged:)
                       name : ORRunStatusChangedNotification
                     object : nil];
    
    [noteCenter addObserver : self
                   selector : @selector(taskStatusChanged:)
                       name : ORTaskStateChangedNotification
                     object : nil];
    
    [noteCenter addObserver : self
                   selector : @selector(documentClosed:)
                       name : ORDocumentClosedNotification
                     object : nil];
}

- (void) runStatusChanged:(NSNotification*)aNotification
{
    [self setRunInProgress: [[[aNotification userInfo] objectForKey:ORRunStatusValue] intValue]];
    [self setRunType: [[[aNotification userInfo] objectForKey:ORRunTypeMask] longValue]];
    if(runInProgress == eRunStarting){
        [[ORStatusController sharedStatusController] clearAllAction:nil];
    }
}

- (void) taskStatusChanged:(NSNotification*)aNotification
{
}

- (void) documentClosed:(NSNotification*)aNotification
{
    [runModeAlarm clearAlarm];
    [runModeAlarm release];
	runModeAlarm = nil;
}

- (void) checkRunMode
{
    [[self undoManager] disableUndoRegistration];
    [self setRunMode: runMode];
    [[self undoManager] enableUndoRegistration];
}

- (void) setRunMode:(eRunMode)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunMode:runMode];
    runMode = aMode;
    if(runMode == kNormalRun){
        [runModeAlarm clearAlarm];
    }
    else {
        if(!runModeAlarm){
            runModeAlarm = [[ORAlarm alloc] initWithName:@"Offline Run" severity:kDataFlowAlarm];
            [runModeAlarm setSticky:YES];
            [runModeAlarm setHelpStringFromFile:@"OfflineRunHelp"];
        }
        [runModeAlarm setAcknowledged:NO];
        [runModeAlarm postAlarm];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName: ORRunModeChangedNotification object:self userInfo:nil];
    
}

- (eRunMode) runMode
{
    return runMode;
}

- (NSString*) runModeString
{
	if(runInProgress == eRunStopped)		return  @"";
	else if(runInProgress == eRunStopping)	return  @"Run Stopping";
	else  switch(runMode){
        case kOfflineRun:
            return @"Running Offline.";
		break;
            
        default:
        case kNormalRun:	
		{
			NSString* rs;
			if(runInProgress == eRunBetweenSubRuns) rs= @"Between Sub Runs.";
			else {
				rs= @"Run In Progress.";
			
				if(runType){
					if(runType & eMaintenanceRunType){
						rs = [rs stringByAppendingString:@" Maintenance."];
					}

					if(runType & ~eMaintenanceRunType){
						rs = [rs stringByAppendingFormat:@" Mask: 0x%X",runType & ~eMaintenanceRunType];
					}
				}
            }
			return rs;
		}
		break;
    }
}

- (int) cpuCount
{
	if(cpuCount)return cpuCount;
	else {
		NSProcessInfo* pinfo = [NSProcessInfo processInfo];
		cpuCount = [pinfo processorCount];
		return cpuCount;
	}
}

- (BOOL) runInProgress
{
    return runInProgress >= eRunInProgress;
}
- (BOOL) runStopped
{
    return runInProgress == eRunStopped;
}
- (BOOL) runRunning
{
    return runInProgress == eRunInProgress;
}

- (void) setRunInProgress:(BOOL)state
{
    runInProgress = state;
	[[[NSApp delegate] document] setStatusText:[self runModeString]];
}

- (unsigned long)runType {
    
    return runType;
}
- (void)setRunType:(unsigned long)aRunType {
    runType = aRunType;
}


- (NSUndoManager*) undoManager
{
    return [[NSApp delegate] undoManager];
}

- (void) addRunVeto:(NSString*)vetoName comment:(NSString*)aComment
{
	if(!runVetos){
		runVetos = [[NSMutableDictionary dictionary] retain];
	}
	BOOL vetoExisted = [runVetos objectForKey:vetoName]!=nil;
	[runVetos setObject:aComment forKey:vetoName];
	if(!vetoExisted)[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRunVetosChanged object:nil userInfo:nil waitUntilDone:NO]; 
}

- (void) removeRunVeto:(NSString*)vetoName
{
	BOOL vetoExisted = [runVetos objectForKey:vetoName]!=nil;
	[runVetos removeObjectForKey:vetoName];
	if([runVetos count] == 0){
		[runVetos release];
		runVetos = nil;
	}
	if(vetoExisted)[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRunVetosChanged object:nil userInfo:nil waitUntilDone:NO]; 
}

- (BOOL) anyVetosInPlace
{
	return [runVetos count];
}

- (int) vetoCount
{
	return [runVetos count];
}

- (void) listVetoReasons
{
	int n = [runVetos count];
	if(n){
		NSLog(@"There %@ %d veto%@in force:\n",n>1?@"are":@"is",n,n>1?@"s ":@" ");
		NSEnumerator* e = [runVetos keyEnumerator];
		NSString* key;
		while(key = [e nextObject]){
			NSLog(@"%@ : %@\n",key,[runVetos objectForKey:key]);
		}
	}
	else NSLog(@"No run vetos in place. Run is OK to go.\n");
}

#pragma mark •••Archival
static NSString* ORRunModeKey		    = @"ORRunMode";

- (id)loadParams:(NSCoder*)decoder
{
    [[self undoManager] disableUndoRegistration];
    [self setRunMode:[decoder decodeIntForKey:ORRunModeKey]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)saveParams:(NSCoder*)encoder
{
    [encoder encodeInt:[self runMode] forKey:ORRunModeKey];
}



@end
