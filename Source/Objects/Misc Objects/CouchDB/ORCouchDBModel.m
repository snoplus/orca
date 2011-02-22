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

NSString* ORCouchDBModelStealthModeChanged	= @"ORCouchDBModelStealthModeChanged";
NSString* ORCouchDBDataBaseNameChanged		= @"ORCouchDBDataBaseNameChanged";
NSString* ORCouchDBPasswordChanged			= @"ORCouchDBPasswordChanged";
NSString* ORCouchDBUserNameChanged			= @"ORCouchDBUserNameChanged";
NSString* ORCouchDBHostNameChanged			= @"ORCouchDBHostNameChanged";
NSString* ORCouchDBConnectionValidChanged	= @"ORCouchDBConnectionValidChanged";
NSString* ORCouchDBLock						= @"ORCouchDBLock";

#define kCreateDB		 @"kCreateDB"
#define kDeleteDB		 @"kDeleteDB"
#define kListDB			 @"kListDB"
#define kDocument		 @"kDocument"
#define kInfoDB			 @"kInfoDB"
#define kDocumentUpdated @"kDocumentUpdated"

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
	[self registerNotificationObservers];
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
                         name : ORRunQuickStartChangedNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunTimedRunChangedNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunRepeatRunChangedNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunTimeLimitChangedNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunOfflineRunNotification
                       object : nil];
}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
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
		[self deleteDatabase];
	}
	else {
		[self createDatabase];
		NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
		if([runObjects count]){
			//ORRunModel* rc = [runObjects objectAtIndex:0];
			//NSDictionary* runInfo = [rc runInfo];
			//if(runInfo){
				//				[self postRunState:[NSNotification notificationWithName:@"DoesNotMatter" object:rc userInfo:runInfo]];
				//}
		}
	}
	//    [[NSNotificationCenter defaultCenter] postNotificationName:ORSqlModelStealthModeChanged object:self];
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

- (NSUndoManager*) undoManager
{
	return [[NSApp delegate] undoManager];
}

- (NSString*) machineName
{		
	NSString* machineName = [NSString stringWithFormat:@"machine_%@",[macAddress() stringByReplacingOccurrencesOfString:@":" withString:@"_"]];
	return [machineName lowercaseString];
}

- (void) createDatabase
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort database:[self machineName] delegate:self];
	if([dataBaseName length]){
		[db createDatabase:kCreateDB];
	}
}

- (void) deleteDatabase
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort database:[self machineName] delegate:self];
	if([dataBaseName length]){
		[db deleteDatabase:kDeleteDB];
	}
}

- (void) updateMachineRecord
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateMachineRecord) object:nil];
		
		ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort database:[self machineName] delegate:self];
		
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
									 [NSNumber numberWithLong:[[[NSApp delegate] memoryWatcher] accurateUptime]], @"uptime",
									  computerName(),@"name",
									  macAddress(),@"hw_address",
									  thisHostAdress,@"ip_address",
									  fullVersion(),@"version",nil];	
			
		[db updateDocument:machineInfo documentId:@"machineinfo" tag:kDocumentUpdated];
		
		[self performSelector:@selector(updateMachineRecord) withObject:nil afterDelay:5];	
	}
}
								 								 
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag
{
	@synchronized(self){
		if([aResult isKindOfClass:[NSDictionary class]]){
			NSString* message = [aResult objectForKey:@"Message"];
			if(message){
				NSLog(@"%@\n",message);
				NSString* reason = [aResult objectForKey:@"Reason"];
				if(reason)NSLog(@"Reason: %@\n",reason);
			}
			else {
				if([aTag isEqualToString:kListDB]){
					NSLog(@"Database List: %@\n",aResult);
				}
				if([aTag isEqualToString:kInfoDB]){
					NSLog(@"----------------------------\n");
					NSLog(@"Database %@ Info\n",dataBaseName);
					NSArray* allKeys = [aResult allKeys];
					for(id aKey in allKeys){
						NSLog(@"%@ : %@\n",aKey,[aResult objectForKey:aKey]);
					}
					NSLog(@"----------------------------\n");
				}
				else if([aTag isEqualToString:@"Message"]){
					NSLog(@"CouchDB Message: %@\n",[aResult objectForKey:@"Message"]);
				}
				else {
					NSLog(@"Tag: %@\n",aTag);
					NSLog(@"%@\n",aResult);
				}
			}
		}
		else {
			NSLog(@"%@\n",aResult);
		}
	}
}
- (void) updateFunction
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort database:[self machineName] delegate:self];
	NSString* theTime = [NSString stringWithFormat:@"%@",[NSDate date]];
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"123",@"Run",theTime,@"Time",nil];
	[db updateDocument:aDictionary documentId:@"idtest" tag:kDocumentUpdated];
	[db getDocumentId:@"idtest" tag:kDocument];
}

- (void) listDatabases
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort database:[self machineName] delegate:self];
	[db listDatabases:self tag:kListDB];
}

- (void) databaseInfo
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort database:[self machineName] delegate:self];
	[db databaseInfo:self tag:kInfoDB];
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
			NSDictionary* runInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithUnsignedLong:[rc runNumber]],		@"run",
									 [NSNumber numberWithUnsignedLong:[rc subRunNumber]],	@"subrun",
									 [NSNumber numberWithUnsignedLong:[rc runningState]],	@"state",
									 [[rc startTime] description],							@"startTime",
									 [[rc subRunStartTime]description],						@"subRunStartTime",
									 [NSNumber numberWithUnsignedLong:[rc elapsedRunTime]],	@"elapsedTime",
									 [NSNumber numberWithUnsignedLong:[rc elapsedSubRunTime]],@"elapsedSubRunTime",
									 [NSNumber numberWithUnsignedLong:[rc elapsedBetweenSubRunTime]],@"elapsedBetweenSubRunTime",
									 [NSNumber numberWithBool:[rc timeToGo]],				@"timeToGo",
									 [NSNumber numberWithBool:[rc quickStart]],				@"quickStart",
									 [NSNumber numberWithBool:[rc repeatRun]],				@"repeatRun",
									 [NSNumber numberWithBool:[rc offlineRun]],				@"offlineRun",
									 [NSNumber numberWithBool:[rc timedRun]],				@"timedRun",
									 [NSNumber numberWithUnsignedLong:[rc timeLimit]],		@"timeLimit",
									 experimentName,										@"experiment",
									 nil];	
			
			ORCouchDB* db = [ORCouchDB couchHost:hostName port:kCouchDBPort database:[self machineName] delegate:self];
			[db updateDocument:runInfo documentId:@"runinfo" tag:kDocumentUpdated];
		}
		@catch (NSException* e) {
			//silently catch and continue
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
@end

