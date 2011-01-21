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

NSString* ORMPodCModelCrateStatusChanged	 = @"ORMPodCModelCrateStatusChanged";
NSString* ORMPodCModelLock					 = @"ORMPodCModelLock";
NSString* ORMPodCPingTask					 = @"ORMPodCPingTask";
NSString* MPodCIPNumberChanged				 = @"MPodCIPNumberChanged";
NSString* ORMPodCModelSystemParamsChanged	 = @"ORMPodCModelSystemParamsChanged";
NSString* MPodPowerFailedNotification		 = @"MPodPowerFailedNotification";
NSString* MPodPowerRestoredNotification		 = @"MPodPowerRestoredNotification";

@implementation ORMPodCModel

- (void) dealloc
{
	[queue cancelAllOperations];
	[queue release];
	[systemParams release];
	[connectionHistory release];
    [IPNumber release];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
	if(!queue){
		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:1]; //can only do one at a time
		[queue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
	}
	[self pollHardwareAfterDelay];
}

- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[queue cancelAllOperations];
	[queue release];
	queue = nil;
	[super sleep];
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
	if(connectionHistory && index>=0 && index<[connectionHistory count])return [connectionHistory objectAtIndex:index];
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
		ORMPodCUpdateOp* anUpdateOp = [[ORMPodCUpdateOp alloc] initWithDelegate:aCard];
		[queue addOperation:anUpdateOp];
		[anUpdateOp release];
	}
}

- (void) pollHardwareAfterDelay
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:2];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == queue && [keyPath isEqual:@"operations"]) {
        if ([[queue operations] count] == 0) {
			[self performSelectorOnMainThread:@selector(pollHardwareAfterDelay) withObject:nil waitUntilDone:NO];
        }
		
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object 
                               change:change context:context];
    }
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
				//time so flush the queue
				[queue cancelAllOperations];
			}
		}
		else {
			NSString* name  = [anEntry objectForKey:@"Name"];
			if(name)[systemParams setObject:anEntry forKey:name];
		}
	}
	
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCModelSystemParamsChanged object:self];
}


#pragma mark ¥¥¥Hardware Access
- (id) controllerCard
{
	return [[self crate] controllerCard];
}



- (void)  checkCratePower
{
	NSString* noteName;
	if([self power]) noteName = MPodPowerRestoredNotification;
	else			 noteName = MPodPowerFailedNotification;
	[[NSNotificationCenter defaultCenter] postNotificationName:noteName object:self];
	
}

- (void) getValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector
{
	[self getValues:[NSArray arrayWithObject:aCmd] target:aTarget selector:aSelector];
}

- (void) getValues:(NSArray*)cmds target:(id)aTarget selector:(SEL)aSelector
{
	ORSNMP* ss = [[ORSNMP alloc] initWithMib:@"WIENER-CRATE-MIB"];
	[ss openPublicSession:IPNumber];
	NSArray* response = [ss readValues:cmds];
	[aTarget performSelectorOnMainThread:aSelector withObject:response waitUntilDone:YES];
	[ss release];
}

- (void) writeValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector
{
	[self writeValues:[NSArray arrayWithObject:aCmd] target:aTarget selector:aSelector];
}

- (void) writeValues:(NSArray*)cmds target:(id)aTarget selector:(SEL)aSelector
{
	ORSNMP* ss = [[ORSNMP alloc] initWithMib:@"WIENER-CRATE-MIB"];
	[ss openGuruSession:IPNumber];
	NSArray* response = [ss writeValues:cmds];
	[aTarget performSelectorOnMainThread:aSelector withObject:response waitUntilDone:YES];
	[ss release];
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

@implementation ORMPodCUpdateOp
- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) main
{
	@try {
		[delegate updateAllValues];
	}
	@catch(NSException* e){
	}
}
@end
