//
//  ORCouchDBModel.m
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


#import "ORCouchDBModel.h"
#import "ORCouchDB.h"
#import "MemoryWatcher.h"
#import "NSNotifications+Extensions.h"
#import "Utilities.h"
#import "ORRunModel.h"
#import "ORExperimentModel.h"
#import "ORAlarmCollection.h"
#import "ORAlarm.h"

NSString* ORCouchDBModelStealthModeChanged	= @"ORCouchDBModelStealthModeChanged";
NSString* ORCouchDBDataBaseNameChanged		= @"ORCouchDBDataBaseNameChanged";
NSString* ORCouchDBPasswordChanged			= @"ORCouchDBPasswordChanged";
NSString* ORCouchDBUserNameChanged			= @"ORCouchDBUserNameChanged";
NSString* ORCouchDBHostNameChanged			= @"ORCouchDBHostNameChanged";
NSString* ORCouchDBModelDBInfoChanged		= @"ORCouchDBModelDBInfoChanged";

NSString* ORCouchDBLock						= @"ORCouchDBLock";

#define kCreateDB		 @"kCreateDB"
#define kDeleteDB		 @"kDeleteDB"
#define kListDB			 @"kListDB"
#define kDocument		 @"kDocument"
#define kInfoDB			 @"kInfoDB"
#define kDocumentAdded	 @"kDocumentAdded"
#define kDocumentUpdated @"kDocumentUpdated"
#define kDocumentDeleted @"kDocumentDeleted"
#define kCompactDB		 @"kCompactDB"
#define kInfoInternalDB   @"kInfoInternalDB"

#define kCouchDBPort 5984

static NSString* ORCouchDBModelInConnector 	= @"ORCouchDBModelInConnector";

@interface ORCouchDBModel (private)
- (void) updateMachineRecord;
- (void) postRunState:(NSNotification*)aNote;
- (void) postRunTime:(NSNotification*)aNote;
- (void) postRunOptions:(NSNotification*)aNote;
- (void) updateRunState:(ORRunModel*)rc;
@end

@implementation ORCouchDBModel

#pragma mark ***Initialization
- (id) init
{
	[super init];
    [[self undoManager] disableUndoRegistration];
	[self registerNotificationObservers];
    [[self undoManager] enableUndoRegistration];
	return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [dataBaseName release];
    [password release];
    [userName release];
    [hostName release];
	[super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
		[self createDatabase];
		[self performSelector:@selector(updateMachineRecord) withObject:nil afterDelay:1];
		[self performSelector:@selector(updateDatabaseStats) withObject:nil afterDelay:2];
    }
    [super wakeUp];
}


- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self deleteDatabase];
	[super sleep];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"CouchDB"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCouchDBController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORCouchDBModelInConnector];
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
                     selector : @selector(runStatusChanged:)
                         name : ORRunElapsedTimesChangedNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunRepeatRunChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(alarmsChanged:)
                         name : ORAlarmWasPostedNotification
                       object : nil];	
	
    [notifyCenter addObserver : self
                     selector : @selector(alarmsChanged:)
                         name : ORAlarmWasClearedNotification
                       object : nil];	
}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
	[self deleteDatabase];
}

- (void) awakeAfterDocumentLoaded
{
	[self runStatusChanged:nil];
	[self alarmsChanged:nil];
}

#pragma mark ***Accessors
- (BOOL) stealthMode
{
    return stealthMode;
}

- (void) setStealthMode:(BOOL)aStealthMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStealthMode:stealthMode];
    stealthMode = aStealthMode;
	if(stealthMode){
		if([ORCouchDBQueue operationCount]) [ORCouchDBQueue cancelAllOperations];
		[self deleteDatabase];
	}
	else {
		[self createDatabase];
		NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
		if([runObjects count]){
			ORRunModel* rc = [runObjects objectAtIndex:0];
			[self updateRunState:rc];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBModelStealthModeChanged object:self];
}

- (id) nextObject
{
	return [self objectConnectedTo:ORCouchDBModelInConnector];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBDataBaseNameChanged object:self];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBPasswordChanged object:self];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBUserNameChanged object:self];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBHostNameChanged object:self];
	}
}

- (NSString*) machineName
{		
	NSString* machineName = [NSString stringWithFormat:@"%@_%@",computerName(),[macAddress() stringByReplacingOccurrencesOfString:@":" withString:@"_"]];
	machineName = [machineName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	return [machineName lowercaseString];
}

- (void) createDatabase
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort   username:userName pwd:password database:[self machineName] delegate:self];
	[db createDatabase:kCreateDB];
	[self updateMachineRecord];
	[self updateDatabaseStats];
}

- (void) deleteDatabase
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort   username:userName pwd:password database:[self machineName] delegate:self];
	[db deleteDatabase:kDeleteDB];
}

- (void) updateMachineRecord
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateMachineRecord) object:nil];
		
		ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort  username:userName pwd:password database:[self machineName] delegate:self];
		
		NSString* thisHostAdress = @"";
		NSArray* names =  [[NSHost currentHost] addresses];
		NSEnumerator* e = [names objectEnumerator];
		id aName;
		while(aName = [e nextObject]){
			if([aName rangeOfString:@"::"].location == NSNotFound){
				if([aName rangeOfString:@".0.0."].location == NSNotFound){
					thisHostAdress = aName;
					break;
				}
			}
		}
		NSDictionary* machineInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 @"machineinfo",@"type",
									 [NSNumber numberWithLong:[[[NSApp delegate] memoryWatcher] accurateUptime]], @"uptime",
									  computerName(),@"name",
									  macAddress(),@"hw_address",
									  thisHostAdress,@"ip_address",
									  fullVersion(),@"version",nil];	
			
		[db updateDocument:machineInfo documentId:@"machineinfo" tag:kDocumentUpdated];
		
		[self performSelector:@selector(updateMachineRecord) withObject:nil afterDelay:5];	
	}
}

- (void) updateDatabaseStats
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDatabaseStats) object:nil];
		
		ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort database:[self machineName] delegate:self];
		[db databaseInfo:self tag:kInfoInternalDB];
		
		[self performSelector:@selector(updateDatabaseStats) withObject:nil afterDelay:30];	
	}
}

- (void) setDBInfo:(NSDictionary*)someInfo
{
	@synchronized(self){
		[someInfo retain];
		[dBInfo release];
		dBInfo = someInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBModelDBInfoChanged object:self];
}

- (NSDictionary*) dBInfo
{
	return [[dBInfo retain] autorelease];
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag
{
	@synchronized(self){
		if([aResult isKindOfClass:[NSDictionary class]]){
			NSString* message = [aResult objectForKey:@"Message"];
			if(message){
				[aResult prettyPrint:@"CouchDB Message:"];
			}
			else {
				if([aTag isEqualToString:kInfoDB]){
					[aResult prettyPrint:@"CouchDB Info:"];
				}
				
				else if([aTag isEqualToString:kCreateDB]){
					[self setDataBaseName:[self machineName]];
				}
				else if([aTag isEqualToString:kDeleteDB]){
					[self setDataBaseName:@"---"];
				}
				
				else if([aTag isEqualToString:kInfoInternalDB]){
					[self performSelectorOnMainThread:@selector(setDBInfo:) withObject:aResult waitUntilDone:NO];
				}
				
				else if([aTag isEqualToString:@"Message"]){
					[aResult prettyPrint:@"CouchDB Message:"];
				}
				else if([aTag isEqualToString:kCompactDB]){
					[aResult prettyPrint:@"CouchDB Compacted:"];
				}
				else {
					[aResult prettyPrint:@"CouchDB"];
				}
			}
		}
		else if([aResult isKindOfClass:[NSArray class]]){
			if([aTag isEqualToString:kListDB]){
				[aResult prettyPrint:@"CouchDB List:"];
			}
			else [aResult prettyPrint:@"CouchDB"];
		}
		else {
			NSLog(@"%@\n",aResult);
		}
	}
}

- (void) updateFunction
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort   username:userName pwd:password database:[self machineName] delegate:self];
	NSString* theTime = [NSString stringWithFormat:@"%@",[NSDate date]];
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"123",@"Run",theTime,@"Time",nil];
	[db updateDocument:aDictionary documentId:@"idtest" tag:kDocumentUpdated];
}

- (void) compactDatabase
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort   username:userName pwd:password database:[self machineName] delegate:self];
	[db compactDatabase:self tag:kCompactDB];
	[self performSelector:@selector(updateDatabaseStats) withObject:nil afterDelay:4];
}

- (void) listDatabases
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort database:[self machineName] delegate:self];
	[db listDatabases:self tag:kListDB];
}

- (void) databaseInfo:(BOOL)toStatusWindow
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort database:[self machineName] delegate:self];
	if(toStatusWindow)	[db databaseInfo:self tag:kInfoDB];
	else				[db databaseInfo:self tag:kInfoInternalDB];
}

- (void) runStatusChanged:(NSNotification*)aNote
{
	[self updateRunState:[aNote object]];
}

- (void) updateRunState:(ORRunModel*)rc
{
	if(!stealthMode){
		@try {
			
			id nextObject = [self nextObject];
			NSString* experimentName;
			if(!nextObject)	experimentName = @"TestStand";
			else {
				experimentName = [nextObject className];
				if([experimentName hasPrefix:@"OR"])experimentName = [experimentName substringFromIndex:2];
				if([experimentName hasSuffix:@"Model"])experimentName = [experimentName substringToIndex:[experimentName length] - 5];
			}
			
			NSMutableDictionary* runInfo = [NSMutableDictionary dictionaryWithDictionary:[rc fullRunInfo]];
			[runInfo setObject:@"runinfo" forKey:@"type"];	
			[runInfo setObject:experimentName forKey:@"experiment"];	
			
			ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort   username:userName pwd:password database:[self machineName] delegate:self];
			[db updateDocument:runInfo documentId:@"runinfo" tag:kDocumentUpdated];
		}
		@catch (NSException* e) {
			//silently catch and continue
		}
	}
}

- (void) alarmsChanged:(NSNotification*)aNote
{
	if(!stealthMode){
		ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort   username:userName pwd:password database:[self machineName] delegate:self];
		ORAlarmCollection* alarmCollection = [ORAlarmCollection sharedAlarmCollection];
		NSArray* theAlarms = [[[alarmCollection alarms] retain] autorelease];
		if([theAlarms count]){
			NSMutableArray* arrayForDoc = [NSMutableArray array];
			for(id anAlarm in theAlarms)[arrayForDoc addObject:[anAlarm alarmInfo]];
			NSDictionary* alarmInfo  = [NSDictionary dictionaryWithObjectsAndKeys:arrayForDoc,@"alarmlist",@"alarms",@"type",nil];
			[db updateDocument:alarmInfo documentId:@"alarms" tag:kDocumentAdded];
		}
		else {
			[db deleteDocumentId:@"alarms" tag:kDocumentDeleted];
		}
	}
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
    [encoder encodeObject:dataBaseName forKey:@"DataBaseName"];
    [encoder encodeBool:stealthMode forKey:@"stealthMode"];
    [encoder encodeObject:password forKey:@"Password"];
    [encoder encodeObject:userName forKey:@"UserName"];
    [encoder encodeObject:hostName forKey:@"HostName"];
}
@end

