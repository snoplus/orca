//
//  ORSqlModel.m
//  Orca
//
//  Created by Mark Howe on 10/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORSqlModel.h"
#import "ORRunModel.h"
#import "OR1DHisto.h"
#import "ORSqlConnection.h"
#import "ORSqlResult.h"
#import "ORAlarm.h"
#import "ORAlarmCollection.h"
#import "ORExperimentModel.h"
#import "ORSegmentGroup.h"

NSString* ORSqlModelStealthModeChanged = @"ORSqlModelStealthModeChanged";
NSString* ORSqlDataBaseNameChanged	= @"ORSqlDataBaseNameChanged";
NSString* ORSqlPasswordChanged		= @"ORSqlPasswordChanged";
NSString* ORSqlUserNameChanged		= @"ORSqlUserNameChanged";
NSString* ORSqlHostNameChanged		= @"ORSqlHostNameChanged";
NSString* ORSqlConnectionValidChanged	= @"ORSqlConnectionValidChanged";
NSString* ORSqlLock					= @"ORSqlLock";

static NSString* ORSqlModelInConnector 	= @"ORSqlModelInConnector";

@interface ORSqlModel (private)
- (BOOL) validateConnection;
- (void) updateDataSets;
- (void) updateExperiment;
- (void) addMachineName;
- (void) removeMachineName;
- (void) postRunState:(NSNotification*)aNote;
- (void) postRunTime:(NSNotification*)aNote;
- (void) collectSegmentMap;
- (void) collectAlarms;
@end

@implementation ORSqlModel

#pragma mark ***Initialization
- (id) init
{
	[super init];
	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[queue cancelAllOperations];
	[queue release];
	[sqlConnection release];
    [dataBaseName release];
    [password release];
    [userName release];
    [hostName release];
	[super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	if(!queue){
		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:1]; //can only do one at a time
	}
	[self addMachineName];

	[self performSelector:@selector(collectAlarms) withObject:nil afterDelay:2];
	[self performSelector:@selector(collectSegmentMap) withObject:nil afterDelay:2];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Sql"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORSqlController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORSqlModelInConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB I' ];
	[ aConnector addRestrictedConnectionType: 'DB O' ]; //can only connect to DB outputs
	
    [aConnector release];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[notifyCenter removeObserver:self];
	
    [notifyCenter addObserver : self
                     selector : @selector(applicationIsTerminating:)
                         name : @"ORAppTerminating"
                       object : [NSApp delegate]];
	
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(postRunTime:)
                         name : ORRunElapsedTimesChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(alarmPosted:)
                         name : ORAlarmWasPostedNotification
                       object : nil];	
	
    [notifyCenter addObserver : self
                     selector : @selector(alarmCleared:)
                         name : ORAlarmWasClearedNotification
                       object : nil];	
	
}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
	[self removeMachineName];
}

- (void) runStatusChanged:(NSNotification*)aNote
{
	id pausedKeyIncluded = [[aNote userInfo] objectForKey:@"ORRunPaused"];
	if(!pausedKeyIncluded){
		@try {
			int runState     = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
			
			[self postRunState:aNote];

			if(runState == eRunInProgress){
				if(!dataMonitors)dataMonitors = [[NSMutableArray array] retain];
				NSArray* list = [[self document] collectObjectsOfClass:NSClassFromString(@"ORHistoModel")];
				for(ORDataChainObject* aDataMonitor in list){
					if([aDataMonitor involvedInCurrentRun]){
						[dataMonitors addObject:aDataMonitor];
					}
				}
				[self updateExperiment];
				[self updateDataSets];
			}
			else if(runState == eRunStopped){
				[self postRunTime:aNote];
				[dataMonitors release];
				dataMonitors = nil;
				[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDataSets) object:nil];
				[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateExperiment) object:nil];
			}
		}
		@catch (NSException* e) {
			//silently catch and continue
		}
	}
}

#pragma mark ***Accessors
- (id) nextObject
{
	return [self objectConnectedTo:ORSqlModelInConnector];
}

- (BOOL) stealthMode
{
    return stealthMode;
}

- (void) setStealthMode:(BOOL)aStealthMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStealthMode:stealthMode];
    stealthMode = aStealthMode;
	if(stealthMode){
		[self removeMachineName];
	}
	else {
		[self addMachineName];
		NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
		if([runObjects count]){
			ORRunModel* rc = [runObjects objectAtIndex:0];
			NSDictionary* runInfo = [rc runInfo];
			if(runInfo){
				[self postRunState:[NSNotification notificationWithName:@"DoesNotMatter" object:rc userInfo:runInfo]];
			}
		}
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSqlModelStealthModeChanged object:self];
}

- (NSString*) dataBaseName
{
    return dataBaseName;
}

- (void) setDataBaseName:(NSString*)aDataBaseName
{
	if(aDataBaseName){
		[[[self undoManager] prepareWithInvocationTarget:self] setDataBaseName:dataBaseName];
		
		[dataBaseName autorelease];
		dataBaseName = [aDataBaseName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlDataBaseNameChanged object:self];
	}
}

- (NSString*) password
{
    return password;
}

- (void) setPassword:(NSString*)aPassword
{
	if(aPassword){
		[[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
		
		[password autorelease];
		password = [aPassword copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlPasswordChanged object:self];
	}
}

- (NSString*) userName
{
    return userName;
}

- (void) setUserName:(NSString*)aUserName
{
	if(aUserName){
		[[[self undoManager] prepareWithInvocationTarget:self] setUserName:userName];
		
		[userName autorelease];
		userName = [aUserName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlUserNameChanged object:self];
	}
}

- (NSString*) hostName
{
    return hostName;
}

- (void) setHostName:(NSString*)aHostName
{
	if(aHostName){
		[[[self undoManager] prepareWithInvocationTarget:self] setHostName:hostName];
		
		[hostName autorelease];
		hostName = [aHostName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlHostNameChanged object:self];
	}
}

- (NSUndoManager*) undoManager
{
	return [[NSApp delegate] undoManager];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{    
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setDataBaseName:[decoder decodeObjectForKey:@"DataBaseName"]];
    [self setPassword:[decoder decodeObjectForKey:@"Password"]];
    [self setUserName:[decoder decodeObjectForKey:@"UserName"]];
    [self setHostName:[decoder decodeObjectForKey:@"HostName"]];
    [self setStealthMode:[decoder decodeBoolForKey:@"stealthMode"]];
    [[self undoManager] enableUndoRegistration];    
	[self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:stealthMode forKey:@"stealthMode"];
    [encoder encodeObject:dataBaseName forKey:@"DataBaseName"];
    [encoder encodeObject:password forKey:@"Password"];
    [encoder encodeObject:userName forKey:@"UserName"];
    [encoder encodeObject:hostName forKey:@"HostName"];
}

#pragma mark ***SQL Access
- (BOOL) testConnection
{
	if(!sqlConnection) sqlConnection = [[ORSqlConnection alloc] init];
	if([sqlConnection isConnected]){
		[sqlConnection disconnect];
	} 
	
	if([sqlConnection connectToHost:hostName userName:userName passWord:password dataBase:dataBaseName]){
		connectionValid = YES;
		[self addMachineName];
	}
	else {
		connectionValid = NO;
		[sqlConnection release];
		sqlConnection = nil;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlConnectionValidChanged object:self];
	

	return connectionValid;
}

-(void) disconnect
{
	if(sqlConnection){
		[sqlConnection release];
		sqlConnection = nil;
		if(connectionValid){
			NSLog(@"Disconnected from DataBase %@ on %@\n",dataBaseName,hostName);
			connectionValid = NO;
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlConnectionValidChanged object:self];
	}
}
- (BOOL) connectionValid
{
	return connectionValid;
}

- (void) logQueryException:(NSException*)e
{
	//assert(![NSThread isMainThread]);
	NSLogError(@"SQL",@"Query Problem",[e reason],nil);
	[sqlConnection release];
	sqlConnection = nil;
}

@end

@implementation ORSqlModel (private)
/*
 +------------+---------------+------+-----+---------+----------------+
 | Field      | Type          | Null | Key | Default | Extra          |
 +------------+---------------+------+-----+---------+----------------+
 | alarm_id   | int(11)       | NO   | PRI | NULL    | auto_increment |
 | machine_id | int(11)       | NO   | MUL | NULL    |                |
 | timePosted | varchar(64)   | NO   |     | NULL    |                |
 | severity   | int(11)       | YES  |     | NULL    |                |
 | name       | varchar(64)   | YES  |     | NULL    |                |
 | help       | varchar(1024) | YES  |     | NULL    |                |
 +------------+---------------+------+-----+---------+----------------+
*/
- (void) collectAlarms
{
	NSArray* alarms = [[ORAlarmCollection sharedAlarmCollection] alarms];
	for(id anAlarm in alarms){
		ORPostAlarmOp* anOp = [[ORPostAlarmOp alloc] initWithSqlConnection:sqlConnection delegate:self];
		[anOp postAlarm:anAlarm];
		[queue addOperation:anOp];
		[anOp release];
	}
	
}
/*
+-----------------+-------------+------+-----+---------+----------------+
| Field           | Type        | Null | Key | Default | Extra          |
+-----------------+-------------+------+-----+---------+----------------+
| segment_id      | int(11)     | NO   | PRI | NULL    | auto_increment |
| machine_id      | int(11)     | NO   | MUL | NULL    |                |
| monitor_id      | int(11)     | YES  |     | NULL    |                |
| segment         | int(11)     | YES  |     | NULL    |                |
| histogram1DName | varchar(64) | YES  |     | NULL    |                |
| crate           | int(11)     | YES  |     | NULL    |                |
| card            | int(11)     | YES  |     | NULL    |                |
| channel         | int(11)     | YES  |     | NULL    |                |
+-----------------+-------------+------+-----+---------+----------------+
 */
- (void) collectSegmentMap
{		
	ORPostSegmentMapOp* anOp = [[ORPostSegmentMapOp alloc] initWithSqlConnection:sqlConnection delegate:self];
	
	[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
	NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
	NSArray* arrayOfHistos = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
	if([arrayOfHistos count]){
		id histoObj = [arrayOfHistos objectAtIndex:0];
		//assume first one in the data chain
		[anOp setDataMonitorId:[histoObj uniqueIdNumber]];
		[queue addOperation:anOp];
		[anOp release];
	}
}

- (BOOL) validateConnection
{
	if(stealthMode)return NO;
	BOOL oldConnectionValid = connectionValid;
	if(!sqlConnection) sqlConnection = [[ORSqlConnection alloc] init];
	if(![sqlConnection isConnected]){
		if([sqlConnection connectToHost:hostName userName:userName passWord:password dataBase:dataBaseName verbose:NO]){
			connectionValid = YES;
		}
		else {
			connectionValid = NO;
		}
	}
	
	if(connectionValid != oldConnectionValid){
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlConnectionValidChanged object:self];
	}
	return connectionValid;
}


/* Table: machines
+------------+-------------+------+-----+---------+----------------+
| Field      | Type        | Null | Key | Default | Extra          |
+------------+-------------+------+-----+---------+----------------+
| machine_id | int(11)     | NO   | PRI | NULL    | auto_increment |
| name       | varchar(64) | YES  |     | NULL    |                |
| hw_address | varchar(32) | YES  | UNI | NULL    |                |
+------------+-------------+------+-----+---------+----------------+
*/
- (void) addMachineName
{
	if([self validateConnection]){
		ORPostMachineNameOp* anOp = [[ORPostMachineNameOp alloc] initWithSqlConnection:sqlConnection delegate:self];
		[queue addOperation:anOp];
		[anOp release];
	}
}

- (void) removeMachineName
{
	ORDeleteMachineNameOp* anOp = [[ORDeleteMachineNameOp alloc] initWithSqlConnection:sqlConnection delegate:self];
	[queue addOperation:anOp];
	[anOp release];	
}

/* Table: runs
 +-------------+-------------+------+-----+---------+----------------+
 | Field       | Type        | Null | Key | Default | Extra          |
 +-------------+-------------+------+-----+---------+----------------+
 | run_id      | int(11)     | NO   | PRI | NULL    | auto_increment |
 | run         | int(11)     | YES  |     | NULL    |                |
 | subrun      | int(11)     | YES  |     | NULL    |                |
 | state       | int(11)     | YES  |     | NULL    |                |
 | machine_id  | int(11)     | NO   | MUL | NULL    |                |
 | experiment  | varchar(64) | YES  |     | NULL    |                |
 | startTime   | varchar(64) | YES  |     | NULL    |                |
 | elapsedTime | varchar(64) | YES  |     | NULL    |                |
 +-------------+-------------+------+-----+---------+----------------+
 run types:
	0 stopped
	1 running
	2 starting
	3 stopping
	4 between subruns
 */
- (void) postRunState:(NSNotification*)aNote
{
	if([self validateConnection]){		
		id nextObject = [self objectConnectedTo:ORSqlModelInConnector];
		NSString* experimentName;
		if(!nextObject)	experimentName = @"TestStand";
		else {
			experimentName = [nextObject className];
			if([experimentName hasPrefix:@"OR"])experimentName = [experimentName substringFromIndex:2];
			if([experimentName hasSuffix:@"Model"])experimentName = [experimentName substringToIndex:[experimentName length] - 5];
		}
		ORPostRunStateOp* anOp = [[ORPostRunStateOp alloc] initWithSqlConnection:sqlConnection delegate:self];
		[anOp setRunState:aNote];
		[anOp setExperimentName:experimentName];
		[queue addOperation:anOp];
		[anOp release];
	}
}

- (void) postRunTime:(NSNotification*)aNote
{
	if([self validateConnection]){		
		ORPostRunTimesOp* anOp = [[ORPostRunTimesOp alloc] initWithSqlConnection:sqlConnection delegate:self];
		[anOp setParams:aNote];
		[queue addOperation:anOp];
		[anOp release];
	}
}


/*Table: Histogram1Ds
 +------------+-------------+------+-----+---------+----------------+
 | Field      | Type        | Null | Key | Default | Extra          |
 +------------+-------------+------+-----+---------+----------------+
 | dataset_id | int(11)     | NO   | PRI | NULL    | auto_increment |
 | name       | varchar(64) | YES  |     | NULL    |                |
 | counts     | int(11)     | YES  |     | NULL    |                |
 | machine_id | int(11)     | NO   | MUL | NULL    |                |
 | monitor_id | int(11)     | YES  |     | NULL    |                |
 | type       | int(11)     | YES  |     | NULL    |                |
 | length     | int(11)     | YES  |     | NULL    |                |
 | start      | int(11)     | YES  |     | NULL    |                |
 | end        | int(11)     | YES  |     | NULL    |                |
 | data       | mediumblob  | YES  |     | NULL    |                |
 +------------+-------------+------+-----+---------+----------------+
 types:
 0 undefined
 1 1DHisto
 2 2DHisto
 3 Waveform
*/ 
- (void) updateDataSets
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDataSets) object:nil];
	if([self validateConnection]){		
		ORPostDataOp* anOp = [[ORPostDataOp alloc] initWithSqlConnection:sqlConnection delegate:self];
		[anOp setDataMonitors:dataMonitors];
		[queue addOperation:anOp];
		[anOp release];
		
	}
	[self performSelector:@selector(updateDataSets) withObject:nil afterDelay:10];
}

/*Table: Experiment
 +----------------+-------------+------+-----+---------+-------+
 | Field          | Type        | Null | Key | Default | Extra |
 +----------------+-------------+------+-----+---------+-------+
 | experiment_id  | int(11)     | NO   |     | NULL    |       |
 | machine_id     | int(11)     | NO   | MUL | NULL    |       |
 | experiment     | varchar(64) | YES  |     | NULL    |       |
 | numberSegments | int(11)     | YES  |     | NULL    |       |
 | rates          | mediumblob  | YES  |     | NULL    |       |
 | totalRate      | mediumblob  | YES  |     | NULL    |       |
 | thresholds     | mediumblob  | YES  |     | NULL    |       |
 | gains          | mediumblob  | YES  |     | NULL    |       |
 +----------------+-------------+------+-----+---------+-------+
 */ 
- (void) updateExperiment
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateExperiment) object:nil];
	id nextObject = [self objectConnectedTo:ORSqlModelInConnector];
	if(nextObject){
		if([self validateConnection]){		
			ORPostExperimentOp* anOp = [[ORPostExperimentOp alloc] initWithSqlConnection:sqlConnection delegate:self];
			[anOp setExperiment:nextObject];
			[queue addOperation:anOp];
			[anOp release];
		}
	}
	
	[self performSelector:@selector(updateExperiment) withObject:nil afterDelay:10];
}

/*
+------------+---------------+------+-----+---------+----------------+
| Field      | Type          | Null | Key | Default | Extra          |
+------------+---------------+------+-----+---------+----------------+
| alarm_id   | int(11)       | NO   | PRI | NULL    | auto_increment |
| machine_id | int(11)       | NO   | MUL | NULL    |                |
| timePosted | date          | NO   |     | NULL    |                |
| serverity  | int(11)       | YES  |     | NULL    |                |
| name       | varchar(64)   | YES  |     | NULL    |                |
| help       | varchar(1024) | YES  |     | NULL    |                |
+------------+---------------+------+-----+---------+----------------+
*/
- (void) alarmPosted:(NSNotification*)aNote
{
	if([self validateConnection]){		
		ORPostAlarmOp* anOp = [[ORPostAlarmOp alloc] initWithSqlConnection:sqlConnection delegate:self];
		[anOp postAlarm:[aNote object]];
		[queue addOperation:anOp];
		[anOp release];
	}
}

- (void) alarmCleared:(NSNotification*)aNote
{
	if([self validateConnection]){		
		ORPostAlarmOp* anOp = [[ORPostAlarmOp alloc] initWithSqlConnection:sqlConnection delegate:self];
		[anOp clearAlarm:[aNote object]];
		[queue addOperation:anOp];
		[anOp release];
	}
}
@end

@implementation ORSqlOperation
- (id) initWithSqlConnection:(ORSqlConnection*)aSqlConnection delegate:(id)aDelegate
{
	self = [super init];
	sqlConnection = [aSqlConnection retain];
	delegate = aDelegate;
    return self;
}

- (void) dealloc
{
	[sqlConnection release];	
	[super dealloc];
}

@end

@implementation ORPostMachineNameOp
- (void) main
{
	@try {
		NSString* name		 = computerName();
		NSString* hw_address = macAddress();
	
		NSString* query = [NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",
								[sqlConnection quoteObject:hw_address]];
		ORSqlResult* theResult = [sqlConnection queryString:query];
		id d = [theResult fetchRowAsDictionary];
		if(!d){
			NSString* query = [NSString stringWithFormat:@"INSERT INTO machines (name,hw_address) VALUES (%@,%@)",
								[sqlConnection quoteObject:name],
								[sqlConnection quoteObject:hw_address]];
			[sqlConnection queryString:query];
		}
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
}
@end

@implementation ORDeleteMachineNameOp
- (void) main
{
	@try {		
		[sqlConnection queryString:[NSString stringWithFormat:@"DELETE from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
		[delegate disconnect];
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
}
@end


@implementation ORPostRunStateOp
- (void) dealloc
{
	[experimentName release];
	[super dealloc];
}

- (void) setRunState:(NSNotification*)aNote
{
	runState     = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
	runNumber    = [[aNote object] runNumber];
	subRunNumber = [[aNote object] subRunNumber];
}

- (void) setExperimentName:(NSString*)anExperiment
{
	[experimentName autorelease];
	experimentName = [anExperiment copy];
}

- (void) main
{
	@try {
		//get our machine id using our MAC Address
		ORSqlResult* theResult = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
		id row				   = [theResult fetchRowAsDictionary];
		
		//get the entry for our run state using our machine_id
		id machine_id	= [row objectForKey:@"machine_id"];
		theResult		= [sqlConnection queryString:[NSString stringWithFormat:@"SELECT run_id,state,experiment from runs where machine_id = %@",[sqlConnection quoteObject:machine_id]]];
		id ourRunEntry	= [theResult fetchRowAsDictionary];
		id oldExperiment = [ourRunEntry objectForKey:@"experiment"];
		
		//if we have a run entry, update it. Otherwise create it.
		if(ourRunEntry){
			[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE runs SET run=%d, subrun=%d, state=%d  WHERE machine_id=%@",
										runNumber,
										subRunNumber,
										runState,
										[sqlConnection quoteObject:machine_id]
										]];

		}
		else {
			[sqlConnection queryString:[NSString stringWithFormat:@"INSERT INTO runs (run,subrun,state,machine_id) VALUES (%d,%d,%d,%@)",
										runNumber,
										subRunNumber,
										runState,
										[sqlConnection quoteObject:machine_id]
										]];
		}
		
		if(runState == 1){
			[sqlConnection queryString:[NSString stringWithFormat:@"DELETE FROM Histogram1Ds WHERE machine_id=%@",[sqlConnection quoteObject:machine_id]]];
		}
		if( ![oldExperiment isEqual:experimentName]){
			[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE runs SET experiment=%@ WHERE machine_id=%@",
										[sqlConnection quoteObject:experimentName], 
										[sqlConnection quoteObject:machine_id]]];
		}
		
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}

}
@end

@implementation ORPostRunTimesOp
- (void) dealloc
{
	[startTime release];
	[elapsedTime release];
	[super dealloc];
}

- (void) setParams:(NSNotification*)aNote
{
	startTime	 = [[[aNote object] startTimeAsString] copy];
	elapsedTime	 = [[[aNote object] elapsedRunTimeString] copy];
}

- (void) main
{
	@try {
		//get our machine id using our MAC Address
		ORSqlResult* theResult = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
		id row				   = [theResult fetchRowAsDictionary];
		
		//get the entry for our run state using our machine_id
		id machine_id	= [row objectForKey:@"machine_id"];
		theResult		= [sqlConnection queryString:[NSString stringWithFormat:@"SELECT run_id from runs where machine_id = %@",[sqlConnection quoteObject:machine_id]]];
		id ourRunEntry	= [theResult fetchRowAsDictionary];
		
		//if we have a run entry, update it. Otherwise create it.
		if(ourRunEntry){
			[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE runs SET startTime=%@,elapsedTime=%@  WHERE machine_id=%@",
										[sqlConnection quoteObject:startTime],
										[sqlConnection quoteObject:elapsedTime],
										[sqlConnection quoteObject:machine_id]
										]];
		}		
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
	
}
@end


@implementation ORPostDataOp

- (void) dealloc
{
	[dataMonitors release];
	[super dealloc];
}

- (void) setDataMonitors:(id)someMonitors
{
	[someMonitors retain];
	[dataMonitors release];
	dataMonitors = someMonitors;
}

- (void) main
{
	@try {
		//get our machine_id using our MAC Address
		ORSqlResult* theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
		id row				    = [theResult fetchRowAsDictionary];
		id machine_id			= [row objectForKey:@"machine_id"];

		for(id aMonitor in dataMonitors){
			NSArray* objs1d = [aMonitor  collectObjectsOfClass:[OR1DHisto class]];
			for(id aDataSet in objs1d){
				ORSqlResult* theResult	 = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT dataset_id,counts from Histogram1Ds where (machine_id=%@ and name=%@ and monitor_id=%d)",
																	   machine_id,
																	   [sqlConnection quoteObject:[aDataSet fullName]],
																	   [aMonitor uniqueIdNumber]]];
				id dataSetEntry			 = [theResult fetchRowAsDictionary];
				id dataset_id			 = [dataSetEntry objectForKey:@"dataset_id"];
				unsigned long lastCounts = [[dataSetEntry objectForKey:@"counts"] longValue];
				unsigned long countsNow  = [aDataSet totalCounts];
				unsigned long start,end;
				if(dataset_id) {
					if(lastCounts != countsNow){
						NSData* theData = [aDataSet getNonZeroRawDataWithStart:&start end:&end];
						NSString* convertedData = [sqlConnection quoteObject:theData];
						NSString* theQuery = [NSString stringWithFormat:@"UPDATE Histogram1Ds SET counts=%d,start=%d,end=%d,data=%@ WHERE dataset_id=%@",
											  [aDataSet totalCounts],
											  start,end,
											  convertedData,
											  [sqlConnection quoteObject:dataset_id]];
											  [sqlConnection queryString:theQuery];
					}
				}
				else {
					NSData* theData = [aDataSet getNonZeroRawDataWithStart:&start end:&end];
					NSString* convertedData = [sqlConnection quoteObject:theData];
					NSString* theQuery = [NSString stringWithFormat:@"INSERT INTO Histogram1Ds (monitor_id,machine_id,name,counts,type,start,end,length,data) VALUES (%d,%@,%@,%d,1,%d,%d,%d,%@)",
										  [aMonitor uniqueIdNumber],
										  [sqlConnection quoteObject:machine_id],
										  [sqlConnection quoteObject:[aDataSet fullName]],
										  [aDataSet totalCounts],
										  start,end,
										  [aDataSet numberBins],
										  convertedData];
					[sqlConnection queryString:theQuery];
				}
			}
		}
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}

}

@end

@implementation ORPostExperimentOp
- (void) dealloc
{
	[experiment release];
	[super dealloc];
}

- (void) setExperiment:(id)anExperiment
{
	[anExperiment retain];
	[experiment release];
	experiment = anExperiment;
}

- (void) main
{
	@try {
		if([experiment isKindOfClass:NSClassFromString(@"ORExperimentModel")]) {
			NSString* experimentName = [experiment className];
			if([experimentName hasPrefix:@"OR"])    experimentName = [experimentName substringFromIndex:2];
			if([experimentName hasSuffix:@"Model"]) experimentName = [experimentName substringToIndex:[experimentName length] - 5];

			//get our machine_id using our MAC Address
			ORSqlResult* theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
			id row				    = [theResult fetchRowAsDictionary];
			id machine_id			= [row objectForKey:@"machine_id"];

			theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT experiment_id from experiment where (machine_id = %@ and experiment = %@)",[sqlConnection quoteObject:machine_id],[sqlConnection quoteObject:experimentName]]];
			row				    = [theResult fetchRowAsDictionary];
			id experiment_id		= [row objectForKey:@"experiment_id"];

		
			//if we have a run entry, update it. Otherwise create it.
			if(experiment_id){
				[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE experiment SET thresholds=%@,gains=%@,rates=%@ WHERE machine_id=%@",
											[sqlConnection quoteObject:[experiment thresholdDataForSet:0]],
											[sqlConnection quoteObject:[experiment gainDataForSet:0]],
											[sqlConnection quoteObject:[experiment rateDataForSet:0]],
											[sqlConnection quoteObject:machine_id]]];
			}
			else  {
				int numberSegments = [experiment maxNumSegments];
				[sqlConnection queryString:[NSString stringWithFormat:@"INSERT INTO experiment (machine_id,experiment,numberSegments,thresholds,gains,rates) VALUES (%@,%@,%d,%@,%@,%@)",
											[sqlConnection quoteObject:machine_id],
											[sqlConnection quoteObject:experimentName],
											numberSegments,
											[sqlConnection quoteObject:[experiment thresholdDataForSet:0]],
											[sqlConnection quoteObject:[experiment gainDataForSet:0]],
											[sqlConnection quoteObject:[experiment rateDataForSet:0]]]];
			}
		}
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
	
}

@end

@implementation ORPostAlarmOp
- (void) dealloc
{
	[alarm release];
	[super dealloc];
}

- (void) postAlarm:(id)anAlarm
{
	[anAlarm retain];
	[alarm release];
	alarm = anAlarm;
	opType = kPost;
}

- (void) clearAlarm:(id)anAlarm
{
	[anAlarm retain];
	[alarm release];
	alarm = anAlarm;
	opType = kClear;
}

- (void) main
{
	@try {			
		//get our machine_id using our MAC Address
		ORSqlResult* theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
		id row				    = [theResult fetchRowAsDictionary];
		id machine_id			= [row objectForKey:@"machine_id"];
		
		if(machine_id){
			if(opType == kPost){
				theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT alarm_id from alarms where (machine_id = %@ and name = %@)",[sqlConnection quoteObject:machine_id],[sqlConnection quoteObject:[alarm name]]]];
				row				= [theResult fetchRowAsDictionary];
				id alarm_id		= [row objectForKey:@"alarm_id"];
				if(!alarm_id){
					[sqlConnection queryString:[NSString stringWithFormat:@"INSERT INTO alarms (machine_id,timePosted,severity,name,help) VALUES (%@,%@,%d,%@,%@)",
												[sqlConnection quoteObject:machine_id],
												[sqlConnection quoteObject:[alarm timePosted]],
												[alarm severity],
												[sqlConnection quoteObject:[alarm name]],
												[sqlConnection quoteObject:[alarm helpString]]]];
				}
			}
			else {
				[sqlConnection queryString:[NSString stringWithFormat:@"DELETE FROM alarms where (machine_id=%@ AND name=%@)",
											[sqlConnection quoteObject:machine_id],
											[sqlConnection quoteObject:[alarm name]]]];
			}
		}		
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
	
}

@end

@implementation ORPostSegmentMapOp
- (void) dealloc
{
	[super dealloc];
}
- (void) setDataMonitorId:(int)anID
{
	monitor_id = anID;
}
- (void) main
{
	ORExperimentModel* experiment = (ORExperimentModel*)[[delegate nextObject] retain];
	@try {			
		//get our machine_id using our MAC Address
		ORSqlResult* theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
		id row				    = [theResult fetchRowAsDictionary];
		id machine_id			= [row objectForKey:@"machine_id"];
		
		if(machine_id){
			//since we only update this map on demand (i.e. if it changes we'll just delete and start over
			[sqlConnection queryString:[NSString stringWithFormat:@"DELETE FROM segmentMap where machine_id=%@",
										[sqlConnection quoteObject:machine_id]]];
			
			ORSegmentGroup* theGroup = [experiment segmentGroup:0];
			NSArray* segments = [theGroup segments];
			int segmentNumber = 0;
			for(id aSegment in segments){
				NSString* crateName		= [aSegment objectForKey:@"kCrate"];
				NSString* cardName		= [aSegment objectForKey:@"kCardSlot"];
				NSString* chanName		= [aSegment objectForKey:@"kChannel"];
				NSString* dataSetName   = [experiment dataSetNameGroup:0 segment:segmentNumber];
				[sqlConnection queryString:[NSString stringWithFormat:@"INSERT INTO segmentMap (machine_id,monitor_id,segment,histogram1DName,crate,card,channel) VALUES (%@,%d,%d,%@,%@,%@,%@)",
											[sqlConnection quoteObject:machine_id],
											monitor_id,
											segmentNumber,
											[sqlConnection quoteObject:dataSetName],
											[sqlConnection quoteObject:crateName],
											[sqlConnection quoteObject:cardName],
											[sqlConnection quoteObject:chanName]]];
				segmentNumber++;
			}
			
			
		}		
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
	@finally {
		[experiment release];
	}
	
}

@end



