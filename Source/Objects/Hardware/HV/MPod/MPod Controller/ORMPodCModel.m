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

NSString* ORMPodCModelCrateStatusChanged = @"ORMPodCModelCrateStatusChanged";
NSString* ORMPodCModelCratePowerStateChanged = @"ORMPodCModelCratePowerStateChanged";
NSString* ORMPodCModelLock		= @"ORMPodCModelLock";
NSString* ORMPodCPingTask		= @"ORMPodCPingTask";
NSString* MPodCIPNumberChanged	= @"MPodCIPNumberChanged";
NSString* ORMPodCModelSystemParamsChanged	= @"ORMPodCModelSystemParamsChanged";

@implementation ORMPodCModel

- (void) dealloc
{
	[systemParams release];
	[connectionHistory release];
    [IPNumber release];
	[super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
	[self updateAllValues];
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

- (void) updateAllValues
{
	[self getValues: [self systemUpdateList]  target:self selector:@selector(processSystemResponseArray:)];
}

- (NSArray*) systemUpdateList
{
	NSArray* systemReadParams = [NSArray arrayWithObjects:
								 @"sysMainSwitch.0",
								 @"sysStatus.0",	
								 nil];
	return systemReadParams;
}

- (void) processSystemResponseArray:(NSArray*)response
{
	for(id anEntry in response){
		if(!systemParams)systemParams = [[NSMutableDictionary dictionary] retain];
		NSString* name = [anEntry objectForKey:@"Name"];
		if(name)[systemParams setObject:anEntry forKey:name];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCModelSystemParamsChanged object:self];
}

#pragma mark ¥¥¥Hardware Access
- (id) controllerCard
{
	return [[self crate] controllerCard];
}

- (void) getValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector
{
	[self getValues:[NSArray arrayWithObject:aCmd] target:aTarget selector:aSelector];
}

- (void) getValues:(NSArray*)cmds target:(id)aTarget selector:(SEL)aSelector
{
	ORSNMP* ss = [[ORSNMP alloc] initWithMib:@"WIENER-CRATE-MIB"];
	[ss openPublicSession:IPNumber];
	[aTarget performSelector:aSelector withObject:[ss readValues:cmds]];
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
	[ss writeValues:cmds];
	//[aTarget performSelector:aSelector withObject:[ss readValues:cmds]];
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
