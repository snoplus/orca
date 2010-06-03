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
- (void) listMachines;
- (void) updateDataSets;

- (void) postMachineName;
- (void) postRunState:(int)aRunState runNumber:(int)runNumber subRunNumber:(int)subRunNumber;
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
	[sqlConnection release];
    [dataBaseName release];
    [password release];
    [userName release];
    [hostName release];
	[super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
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
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(15,8) withGuardian:self withObjectLink:self];
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
                     selector : @selector(disconnect)
                         name : @"ORAppTerminating"
                       object : [NSApp delegate]];
	
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
}

- (void) runStatusChanged:(NSNotification*)aNote
{
	id pausedKeyIncluded = [[aNote userInfo] objectForKey:@"ORRunPaused"];
	if(!pausedKeyIncluded){
		@try {
			int runState     = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
			int runNumber    = [[aNote object] runNumber];
			int subRunNumber = [[aNote object] subRunNumber];
			
			[self postRunState: runState runNumber:runNumber subRunNumber:subRunNumber];
			
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
	
	[self listMachines];
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

@end

@implementation ORSqlModel (private)

- (BOOL) validateConnection
{
	BOOL oldConnectionValid = connectionValid;
	if(!sqlConnection) sqlConnection = [[ORSqlConnection alloc] init];
	if(![sqlConnection isConnected]){
		if([sqlConnection connectToHost:hostName userName:userName passWord:password dataBase:dataBaseName]){
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

- (void) listMachines
{
	if([self validateConnection]){
		ORSqlResult* theResult = [sqlConnection queryString:@"select * from machines"];
		while (1){
			id d = [theResult fetchRowAsDictionary];
			if(!d)break;
			NSLog(@"%@\n",d);
		}
	}
}

- (void) postMachineName
{
	if([self validateConnection]){
		
		NSString* name = computerName();
		NSString* hw_address = macAddress();
		
		NSString* query = [NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = '%@'",hw_address];
		ORSqlResult* theResult = [sqlConnection queryString:query];
		id d = [theResult fetchRowAsDictionary];
		if(!d){
			NSString* query = [NSString stringWithFormat:@"INSERT INTO machines (name,hw_address) VALUES ('%@','%@')",name,hw_address];
			[sqlConnection queryString:query];
		}
	}
}

- (void) postRunState:(int)aRunState runNumber:(int)runNumber subRunNumber:(int)subRunNumber
{
	if([self validateConnection]){
		//get our machine id using our MAC Address
		ORSqlResult* theResult = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = '%@'",macAddress()]];
		id row				   = [theResult fetchRowAsDictionary];
		
		//get the entry for our run state using our machine_id
		id machine_id	= [row objectForKey:@"machine_id"];
		theResult		= [sqlConnection queryString:[NSString stringWithFormat:@"SELECT run_id,state,experiment from runs where machine_id = '%@'",machine_id]];
		id ourRunEntry	= [theResult fetchRowAsDictionary];
		id oldExperiment = [ourRunEntry objectForKey:@"experiment"];
		
		//if we have a run entry, update it. Otherwise create it.
		if(ourRunEntry)[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE runs SET run='%d', subrun='%d', state='%d' WHERE machine_id='%@'",runNumber,subRunNumber,aRunState,machine_id]];
		else   [sqlConnection queryString:[NSString stringWithFormat:@"INSERT INTO runs (run,subrun,state,machine_id) VALUES ('%d','%d','%d','%@')",runNumber,subRunNumber,aRunState,machine_id]];
		
		if(aRunState == 1){
			[sqlConnection queryString:[NSString stringWithFormat:@"DELETE FROM datasets WHERE machine_id='%@'",machine_id]];
			id nextObject = [self objectConnectedTo:ORSqlModelInConnector];
			NSString* experimentName;
			if(!nextObject)experimentName = @"TestStand";
			else {
				experimentName = [nextObject className];
				if([experimentName hasPrefix:@"OR"])experimentName = [experimentName substringFromIndex:2];
				if([experimentName hasSuffix:@"Model"])experimentName = [experimentName substringToIndex:[experimentName length] - 5];
				if(![oldExperiment isEqualToString:experimentName]){
					[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE runs SET experiment='%@' WHERE machine_id='%@'",experimentName, machine_id]];
				}
			}
		}
	}
}

- (void) updateDataSets
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if([self validateConnection]){
		//get our machine_id using our MAC Address
		ORSqlResult* theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = '%@'",macAddress()]];
		id row				    = [theResult fetchRowAsDictionary];
		id machine_id			= [row objectForKey:@"machine_id"];
		
		for(id aMonitor in dataMonitors){
			NSArray* objs1d = [aMonitor  collectObjectsOfClass:[OR1DHisto class]];
			for(id aDataSet in objs1d){
				ORSqlResult* theResult = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT dataset_id from datasets where (machine_id='%@' and name='%@' and monitor_id='%d')",machine_id,[aDataSet fullName],[aMonitor uniqueIdNumber]]];
				id dataSetEntry		   = [theResult fetchRowAsDictionary];
				id dataset_id		   = [dataSetEntry objectForKey:@"dataset_id"];

				if(dataset_id) [sqlConnection queryString:[NSString stringWithFormat:@"UPDATE datasets SET counts=%d WHERE dataset_id=%@",[aDataSet totalCounts],dataset_id]];
				else		   [sqlConnection queryString:[NSString stringWithFormat:@"INSERT INTO datasets (monitor_id,machine_id,name,counts) VALUES ('%d','%@','%@','%d')",[aMonitor uniqueIdNumber],machine_id,[aDataSet fullName],[aDataSet totalCounts]]];
				
			}
		}
	}
	[self performSelector:@selector(updateDataSets) withObject:nil afterDelay:10];
}

@end

