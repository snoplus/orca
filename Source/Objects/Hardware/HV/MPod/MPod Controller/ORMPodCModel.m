//
//  ORMPodCModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ¥¥¥Imported Files
#import "ORMPodCModel.h"
#import "ORMPodCrate.h"
#import "ORTaskSequence.h"
#import "ORSNMP.h"

NSString* ORMPodCModelVerboseChanged		 = @"ORMPodCModelVerboseChanged";
NSString* ORMPodCModelCrateStatusChanged	 = @"ORMPodCModelCrateStatusChanged";
NSString* ORMPodCModelLock					 = @"ORMPodCModelLock";
NSString* ORMPodCPingTask					 = @"ORMPodCPingTask";
NSString* MPodCIPNumberChanged				 = @"MPodCIPNumberChanged";
NSString* ORMPodCModelSystemParamsChanged	 = @"ORMPodCModelSystemParamsChanged";
NSString* MPodPowerFailedNotification		 = @"MPodPowerFailedNotification";
NSString* MPodPowerRestoredNotification		 = @"MPodPowerRestoredNotification";
NSString* ORMPodCQueueCountChanged			 = @"ORMPodCQueueCountChanged";

@implementation ORMPodCModel

- (void) dealloc
{
	[[ORSNMPQueue queue] cancelAllOperations];
	[systemParams release];
	[connectionHistory release];
    [IPNumber release];
	[[ORSNMPQueue queue] removeObserver:self forKeyPath:@"operationCount"];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
	[[ORSNMPQueue queue] addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
	[self pollHardwareAfterDelay];
}

- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[ORSNMPQueue queue] removeObserver:self forKeyPath:@"operationCount"];
	[[ORSNMPQueue queue] cancelAllOperations];
	[super sleep];
}
- (NSString*) helpURL
{
	return @"MPod/MPodC.html";
}
#pragma mark ¥¥¥Initialization
- (void) makeMainController
{
    [self linkToController:@"ORMPodCController"];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"MPodC"]];
}

- (void) setGuardian:(id)aGuardian
{
    if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:self];			
		}
	}
    else [[self guardian] setAdapter:nil];
	
    [super setGuardian:aGuardian];
}

- (void) initConnectionHistory
{
	ipNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.%d.IPNumberIndex",[self className],[self slot]]];
	if(!connectionHistory){
		NSArray* his = [[NSUserDefaults standardUserDefaults] objectForKey: [NSString stringWithFormat:@"orca.%@.%d.ConnectionHistory",[self className],[self slot]]];
		connectionHistory = [his mutableCopy];
	}
	if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
}

#pragma mark ***Accessors

- (BOOL) verbose
{
    return verbose;
}

- (void) setVerbose:(BOOL)aVerbose
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVerbose:verbose];
    verbose = aVerbose;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCModelVerboseChanged object:self];
}

- (BOOL) power
{
    return [[[systemParams objectForKey:@"sysMainSwitch"] objectForKey:@"Value"] boolValue];
}

- (id) systemParam:(NSString*)name
{
	id result =  [[systemParams objectForKey:name] objectForKey:@"Value"];
	if(result)return result;
	else return @"";
}

- (int) systemParamAsInt:(NSString*)name
{
	return [[[systemParams objectForKey:name] objectForKey:@"Value"] intValue];
}

- (void) clearHistory
{
	[connectionHistory release];
	connectionHistory = nil;
	
	[self setIPNumber:[self IPNumber]];
}

- (unsigned) connectionHistoryCount
{
	return [connectionHistory count];
}

- (id) connectionHistoryItem:(unsigned)index
{
	if(connectionHistory && index<[connectionHistory count])return [connectionHistory objectAtIndex:index];
	else return nil;
}

- (unsigned) ipNumberIndex
{
	return ipNumberIndex;
}

- (NSString*) IPNumber
{
	if(!IPNumber)return @"";
    return IPNumber;
}

- (void) setIPNumber:(NSString*)aIPNumber
{
	if([aIPNumber length]){
		
		[[[self undoManager] prepareWithInvocationTarget:self] setIPNumber:IPNumber];
		
		[IPNumber autorelease];
		IPNumber = [aIPNumber copy];    
		
		if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
		if(![connectionHistory containsObject:IPNumber]){
			[connectionHistory addObject:IPNumber];
		}
		ipNumberIndex = [connectionHistory indexOfObject:aIPNumber];
		
		[[NSUserDefaults standardUserDefaults] setObject:connectionHistory forKey:[NSString stringWithFormat:@"orca.%@.%d.ConnectionHistory",[self className],[self slot]]];
		[[NSUserDefaults standardUserDefaults] setInteger:ipNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.%d.IPNumberIndex",[self className],[self slot]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:MPodCIPNumberChanged object:self];
	}
}

- (void) pollHardware
{
	for(id aCard in [[self crate] orcaObjects]){
		[aCard updateAllValues];
	}
}

- (void) pollHardwareAfterDelay
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:2];
}

- (void) updateAllValues
{
	[self getValues: [self systemUpdateList]  target:self selector:@selector(processSystemResponseArray:)];
}

- (NSArray*) systemUpdateList
{
	NSArray* systemReadParams = [NSArray arrayWithObjects:
								 @"sysMainSwitch",
								 @"sysStatus",	
								 @"psSerialNumber",
								 @"psOperatingTime",
								 nil];
	NSMutableArray* convertedArray = [NSMutableArray array];
	for(id aParam in systemReadParams){
		[convertedArray addObject:[aParam stringByAppendingString:@".0"]];
	}
	return convertedArray;
}

- (void) processSystemResponseArray:(NSArray*)response
{
	for(id anEntry in response){
		if(!systemParams)systemParams = [[NSMutableDictionary dictionary] retain];
		NSString* error = [anEntry objectForKey:@"Error"];
		if([error length]){
			if([error rangeOfString:@"Timeout"].location != NSNotFound){
				[systemParams release];
				systemParams = nil; 
				//time out so flush the queue
				[[ORSNMPQueue queue] cancelAllOperations];
				NSLogError(@"TimeOut",[NSString stringWithFormat:@"MPod Crate %d\n",[self crateNumber]],@"HV Controller",nil);
				[[NSNotificationCenter defaultCenter] postNotificationName:@"Timeout" object:self];
			}
		}
		else {
			NSString* name  = [anEntry objectForKey:@"Name"];
			if(name)[systemParams setObject:anEntry forKey:name];
		}
	}
	
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCModelSystemParamsChanged object:self];
	
}

- (void) togglePower
{
	NSString* cmd = [NSString stringWithFormat:@"sysMainSwitch.0 i %d",![self power]];
	[[self adapter] writeValue:cmd target:self selector:@selector(processSystemResponseArray:)];
}

#pragma mark ¥¥¥Hardware Access
- (id) controllerCard
{
	return [[self crate] controllerCard];
}

- (void)  checkCratePower
{
	NSString* noteName;
	BOOL currentPower = [self power];
	if(currentPower != oldPower){
		if([self power]) noteName = MPodPowerRestoredNotification;
		else			 noteName = MPodPowerFailedNotification;
		[[NSNotificationCenter defaultCenter] postNotificationName:noteName object:self];
	}
	oldPower = currentPower;
}

- (void) getValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector
{
	[self getValues:[NSArray arrayWithObject:aCmd] target:aTarget selector:aSelector];
}

- (void) getValues:(NSArray*)cmds target:(id)aTarget selector:(SEL)aSelector
{
	for(id aCmd in cmds){
		ORSNMPReadOperation* aReadOp = [[ORSNMPReadOperation alloc] initWithDelegate:aTarget];
		aReadOp.mib			= @"WIENER-CRATE-MIB";
		aReadOp.ipNumber	= IPNumber;
		aReadOp.selector	= aSelector;
		aReadOp.cmds		= [NSArray arrayWithObject:aCmd];
		aReadOp.verbose	= verbose;
		[ORSNMPQueue addOperation:aReadOp];
		[aReadOp release];
	}
}

- (void) writeValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector
{
	[self writeValues:[NSArray arrayWithObject:aCmd] target:aTarget selector:aSelector];
}

- (void) writeValues:(NSArray*)cmds target:(id)aTarget selector:(SEL)aSelector
{
	for(id aCmd in cmds){
		ORSNMPWriteOperation* aWriteOP = [[ORSNMPWriteOperation alloc] initWithDelegate:self];
		aWriteOP.mib		= @"WIENER-CRATE-MIB";
		aWriteOP.target		= aTarget;
		aWriteOP.ipNumber	= IPNumber;
		aWriteOP.selector	= aSelector;
		aWriteOP.cmds		= [NSArray arrayWithObject:aCmd];
		aWriteOP.verbose	= verbose;
		[ORSNMPQueue addOperation:aWriteOP];
		[aWriteOP release];
	}
}

#pragma mark ¥¥¥Tasks
- (void) taskFinished:(NSTask*)aTask
{
	if(aTask == pingTask){
		[pingTask release];
		pingTask = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCPingTask object:self];
	}
}

- (void) ping
{
	if(!pingTask){
		ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
		pingTask = [[NSTask alloc] init];
		
		[pingTask setLaunchPath:@"/sbin/ping"];
		[pingTask setArguments: [NSArray arrayWithObjects:@"-c",@"5",@"-t",@"10",@"-q",IPNumber,nil]];
		
		[aSequence addTaskObj:pingTask];
		[aSequence setVerbose:YES];
		[aSequence setTextToDelegate:YES];
		[aSequence launch];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCPingTask object:self];
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
}

- (void) taskData:(NSString*)text
{
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
	NSOperationQueue* queue = [[ORSNMPQueue sharedSNMPQueue] queue];
    if (object == queue && [keyPath isEqual:@"operationCount"]) {
		NSNumber* n = [NSNumber numberWithInt:[[[ORSNMPQueue queue] operations] count]];
		[self performSelectorOnMainThread:@selector(setQueCount:) withObject:n waitUntilDone:NO];
		if ([[queue operations] count] == 0) {
			[self performSelectorOnMainThread:@selector(pollHardwareAfterDelay) withObject:nil waitUntilDone:NO];
		}
	}
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) setQueCount:(NSNumber*)n
{
	queueCount = [n intValue];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCQueueCountChanged object:self];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self initConnectionHistory];
	[self setIPNumber:		[decoder decodeObjectForKey:@"IPNumber"]];
	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
 	[encoder encodeObject:IPNumber		forKey:@"IPNumber"];
}

@end

