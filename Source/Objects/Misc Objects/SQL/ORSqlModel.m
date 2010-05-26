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

NSString* ORSqlDataBaseNameChanged	= @"ORSqlDataBaseNameChanged";
NSString* ORSqlPasswordChanged		= @"ORSqlPasswordChanged";
NSString* ORSqlUserNameChanged		= @"ORSqlUserNameChanged";
NSString* ORSqlHostNameChanged		= @"ORSqlHostNameChanged";
NSString* ORSqlConnectionChanged	= @"ORSqlConnectionChanged";
NSString* ORSqlLock					= @"ORSqlLock";

static NSString* ORSqlModelInConnector 	= @"ORSqlModelInConnector";
@interface ORSqlModel (private)
- (void) postMachineName;
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
	if(conn){
		mysql_close (conn);
	}
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
		int runState     = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
		//int runNumber    = [[aNote object] runNumber];
		//int subRunNumber = [[aNote object] subRunNumber];
		
		//[self postRunState: runState runNumber:runNumber subRunNumber:subRunNumber];
		
		if(runState == eRunInProgress){
			if(!dataMonitors)dataMonitors = [[NSMutableArray array] retain];
			NSArray* list = [[self document] collectObjectsOfClass:NSClassFromString(@"ORHistoModel")];
			for(ORDataChainObject* aDataMonitor in list){
				if([aDataMonitor involvedInCurrentRun]){
					[dataMonitors addObject:aDataMonitor];
				}
			}
			//[self updateDataSets];
		}
		else if(runState == eRunStopped){
			[dataMonitors release];
			dataMonitors = nil;
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDataSets) object:nil];
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
- (void) toggleConnection
{
	if(conn) [self disconnect];
	else     [self connect];
}
- (BOOL) isConnected
{
	return connected;
}

-(BOOL) connect
{
	conn = mysql_init (NULL);  /* allocate, initialize connection handler */
	
	if (conn == nil){
		NSLog(@"ORSql: mysql_init() failed\n");
		connected = NO;
		return NO;
	}
	
	if (mysql_real_connect (conn, [hostName UTF8String], [userName UTF8String], [password UTF8String],
							[dataBaseName UTF8String], 0, nil, 0) == nil){
		NSLog(@"mysql_real_connect() failed: %u\n",mysql_errno (conn));
		NSLog(@"Error: (%s)\n",mysql_error (conn));
		[self disconnect];
		return NO;
	}
	connected = YES;
	NSLog(@"Connected to DataBase %@ on %@\n",dataBaseName,hostName);
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlConnectionChanged object:self];
	if(dataBaseName && [dataBaseName length]){
		NSLog(@"%@\n",[self databases]);
		[self use:dataBaseName];
		[self postMachineName];
		NSLog(@"%@\n",[self tables]);
		//NSLog(@"%@\n",[self machines]);
	}
	return YES;     /* connection is established */
}

-(void) disconnect
{
	if(conn){
		mysql_close (conn);
		conn = nil;
		if(connected){
			NSLog(@"Disconnected from DataBase %@ on %@\n",dataBaseName,hostName);
			connected = NO;
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlConnectionChanged object:self];
	}
}
- (MYSQL_RES*) sendQuery:(NSString*)query
{
	if(conn){
		if(mysql_query(conn,[query UTF8String])){
			NSLog(@"%@ failed\n",query);
			NSLog(@"%s\n",mysql_error(conn));
			return NO;
		}
		MYSQL_RES* theResult =  mysql_store_result(conn);
		if(theResult)[ORSqlTempResult sqlResult:theResult];
		
		return theResult;
	}
	
	NSLog(@"Not connected to any database\n");
	return NO;
}

- (void) use:(NSString*)aDataBase
{
	NSString* query = [NSString stringWithFormat:@"USE %@",aDataBase];
	if([self sendQuery:query]) NSLog(@"Using DataBase: %@\n",aDataBase);
}

- (NSArray*) tables
{
	NSString* query = @"SHOW TABLES";
	MYSQL_RES* resTables = [self sendQuery:query];
	if(resTables){
		NSMutableArray* result = [NSMutableArray array];
		MYSQL_ROW table;
		while((table = mysql_fetch_row(resTables))!=nil){
			[result addObject:[NSString stringWithUTF8String:table[0]]];
		}
		return result;
	}
	return nil;
}

- (NSArray*) machines
{
	NSString* query = @"Select * from machines";
	MYSQL_RES* resSet = [self sendQuery:query];
	if(resSet){
		MYSQL_ROW row;
		NSMutableArray* result = [NSMutableArray array];
		while((row = mysql_fetch_row(resSet))!=nil){
			int numFields = mysql_num_fields (resSet);
			if(numFields>0){
				NSMutableArray* fields = [NSMutableArray array];
				int i;
				for (i = 0; i < numFields; i++) {
					[fields addObject:[NSString stringWithUTF8String:row[i]]];
				}
				[result addObject:fields];
			}
		}
		return result;
	}
	return nil;
}


- (NSArray*) databases
{
	MYSQL_RES* theResult = [self sendQuery:@"SHOW databases"];
	if(theResult){
		NSMutableArray* result = [NSMutableArray array];
		MYSQL_ROW row;
		while((row = mysql_fetch_row(theResult))!=nil){
			int i;
			for(i=0;i<mysql_num_fields(theResult);i++){
				[result addObject:[NSString stringWithUTF8String:row[i]]];
			}
		}
		return result;
	}
	return nil;
}
@end

@implementation ORSqlModel (private)
- (void) postMachineName
{
	if(conn){
		NSString* name = computerName();
		NSString* hw_address = macAddress();

		NSString* query = [NSString stringWithFormat:@"INSERT INTO machines (name,hw_address) VALUES ('%@','%@')",name,hw_address];
		if(mysql_query(conn,[query UTF8String])!=0){
			NSLog(@"post Machine Name failed\n");
		}				
	}
}

- (void) postRunState:(int)aRunState runNumber:(int)runNumber subRunNumber:(int)subRunNumber
{
/*	NSString* name       = computerName();
	NSString* hw_address = macAddress();
	
	NSString* query = [NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = '%@'",hw_address];
	MYSQL_RES* theResult = mysql_query(conn,[query UTF8String])!=0);
	if(theResult){
		int numFields = mysql_num_fields (resSet);
		MYSQL_ROW row;
		while((row = mysql_fetch_row(theResult))!=nil){
		}
		mysql_free_result (theResult);
	}
 */
}
/*
int numFields = mysql_num_fields (resSet);
if(numFields>0){
	NSMutableArray* fields = [NSMutableArray array];
	int i;
	for (i = 0; i < numFields; i++) {
		[fields addObject:[NSString stringWithUTF8String:row[i]]];
	}
	[result addObject:fields];
}
*/

@end

@implementation ORSqlTempResult
+ (id) sqlResult:(MYSQL_RES*)aResultPtr
{
	return [[[ORSqlTempResult alloc] initWithResult:aResultPtr] autorelease];
}

- (id) initWithResult:(MYSQL_RES*)aResultPtr
{
	[super init];
	resultPtr = aResultPtr;
	return self;
}
- (void) dealloc
{
	if(resultPtr!=nil){
		mysql_free_result(resultPtr);
	}
	[super dealloc];
}
@end
