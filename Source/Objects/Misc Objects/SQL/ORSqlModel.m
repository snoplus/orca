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
- (void) postMachineName;
- (void) postRunState:(NSNotification*)aNote;
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
	[self postMachineName];
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
	
}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
	if([self validateConnection]){
		[sqlConnection queryString:[NSString stringWithFormat:@"DELETE from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
	}
	[self disconnect];
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
				[self updateDataSets];
			}
			else if(runState == eRunStopped){
				[dataMonitors release];
				dataMonitors = nil;
				[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDataSets) object:nil];
			}
		}
		@catch (NSException* e) {
			//silently catch and continue
		}
	}
}

#pragma mark ***Accessors

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
    [[self undoManager] enableUndoRegistration];    
	[self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
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

- (BOOL) validateConnection
{
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
- (void) postMachineName
{
	if([self validateConnection]){
		ORPostMachineNameOp* anOp = [[ORPostMachineNameOp alloc] initWithSqlConnection:sqlConnection delegate:self];
		[queue addOperation:anOp];
		[anOp release];
	}
}

/* Table: runs
 +------------+-------------+------+-----+---------+----------------+
 | Field      | Type        | Null | Key | Default | Extra          |
 +------------+-------------+------+-----+---------+----------------+
 | run_id     | int(11)     | NO   | PRI | NULL    | auto_increment |
 | run        | int(11)     | YES  |     | NULL    |                |
 | subrun     | int(11)     | YES  |     | NULL    |                |
 | state      | int(11)     | YES  |     | NULL    |                |
 | machine_id | int(11)     | NO   | MUL | NULL    |                |
 | experiment | varchar(64) | YES  |     | NULL    |                |
 +------------+-------------+------+-----+---------+----------------+
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

/*Table: datasets
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
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if([self validateConnection]){		
		ORPostDataOp* anOp = [[ORPostDataOp alloc] initWithSqlConnection:sqlConnection delegate:self];
		[anOp setDataMonitors:dataMonitors];
		[queue addOperation:anOp];
		[anOp release];
		
	}
	[self performSelector:@selector(updateDataSets) withObject:nil afterDelay:10];
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
		if(ourRunEntry)[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE runs SET run=%d, subrun=%d, state=%d  WHERE machine_id=%@",runNumber,subRunNumber,runState,[sqlConnection quoteObject:machine_id]]];
		else   [sqlConnection queryString:[NSString stringWithFormat:@"INSERT INTO runs (run,subrun,state,machine_id) VALUES (%d,%d,%d,%@)",runNumber,subRunNumber,runState,[sqlConnection quoteObject:machine_id]]];
		
		if(runState == 1){
			[sqlConnection queryString:[NSString stringWithFormat:@"DELETE FROM datasets WHERE machine_id=%@",[sqlConnection quoteObject:machine_id]]];
			if( ![oldExperiment isEqual:experimentName]){
				[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE runs SET experiment=%@ WHERE machine_id=%@",
											[sqlConnection quoteObject:experimentName], 
											[sqlConnection quoteObject:machine_id]]];
			}
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
				ORSqlResult* theResult	 = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT dataset_id,counts from datasets where (machine_id=%@ and name=%@ and monitor_id=%d)",
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
						NSString* theQuery = [NSString stringWithFormat:@"UPDATE datasets SET counts=%d,start=%d,end=%d,data=%@ WHERE dataset_id=%@",
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
					NSString* theQuery = [NSString stringWithFormat:@"INSERT INTO datasets (monitor_id,machine_id,name,counts,type,start,end,length,data) VALUES (%d,%@,%@,%d,1,%d,%d,%d,%@)",
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