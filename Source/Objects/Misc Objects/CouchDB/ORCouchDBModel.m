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
#import "OR1DHisto.h"
#import "ORStatusController.h"
#import "ORProcessModel.h"
#import "ORProcessElementModel.h"
#import <sys/socket.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

NSString* ORCouchDBModelReplicationRunningChanged = @"ORCouchDBModelReplicationRunningChanged";
NSString* ORCouchDBModelKeepHistoryChanged	= @"ORCouchDBModelKeepHistoryChanged";
NSString* ORCouchDBModelStealthModeChanged	= @"ORCouchDBModelStealthModeChanged";
NSString* ORCouchDBPasswordChanged			= @"ORCouchDBPasswordChanged";
NSString* ORCouchDBUserNameChanged			= @"ORCouchDBUserNameChanged";
NSString* ORCouchDBRemoteHostNameChanged			= @"ORCouchDBRemoteHostNameChanged";
NSString* ORCouchDBModelDBInfoChanged		= @"ORCouchDBModelDBInfoChanged";
NSString* ORCouchDBLock						= @"ORCouchDBLock";

#define kCreateDB		 @"kCreateDB"
#define kReplicateDB	 @"kReplicateDB"
#define kCreateRemoteDB  @"kCreateRemoteDB"
#define kDeleteDB		 @"kDeleteDB"
#define kListDB			 @"kListDB"
#define kRemoteInfo		 @"kRemoteInfo"
#define kRemoteInfoVerbose		 @"kRemoteInfoVerbose"
#define kDocument		 @"kDocument"
#define kInfoDB			 @"kInfoDB"
#define kDocumentAdded	 @"kDocumentAdded"
#define kDocumentUpdated @"kDocumentUpdated"
#define kDocumentDeleted @"kDocumentDeleted"
#define kCompactDB		 @"kCompactDB"
#define kInfoInternalDB  @"kInfoInternalDB"
#define kAttachmentAdded @"kAttachmentAdded"
#define kInfoHistoryDB   @"kInfoHistoryDB"
#define kListDocuments	 @"kListDocuments"

#define kCouchDBPort 5984

static NSString* ORCouchDBModelInConnector 	= @"ORCouchDBModelInConnector";

@interface ORCouchDBModel (private)
- (void) updateProcesses;
- (void) updateHistory;
- (void) updateMachineRecord;
- (void) postRunState:(NSNotification*)aNote;
- (void) postRunTime:(NSNotification*)aNote;
- (void) postRunOptions:(NSNotification*)aNote;
- (void) updateRunState:(ORRunModel*)rc;
- (void) processElementStateChanged:(NSNotification*)aNote;
- (void) periodicCompact;
- (void) updateDataSets;
- (void) updateStatus;
@end

@implementation ORCouchDBModel

#pragma mark ***Initialization
- (id) init
{
	self=[super init];
    [[self undoManager] disableUndoRegistration];
	[self registerNotificationObservers];
    [[self undoManager] enableUndoRegistration];
	return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [password release];
    [userName release];
    [remoteHostName release];
	[docList release];
	[super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
		[self performSelector:@selector(updateMachineRecord) withObject:nil afterDelay:2];
		[self performSelector:@selector(updateRunInfo) withObject:nil afterDelay:3];
		[self performSelector:@selector(updateDatabaseStats) withObject:nil afterDelay:4];
		[self performSelector:@selector(periodicCompact) withObject:nil afterDelay:60];
    }
    [super wakeUp];
}


- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self deleteDatabase];
	[super sleep];
}

- (BOOL) solitaryObject
{
    return YES;
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
                     selector : @selector(runOptionsOrTimeChanged:)
                         name : ORRunElapsedTimesChangedNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(runOptionsOrTimeChanged:)
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
	
    [notifyCenter addObserver : self
                     selector : @selector(statusLogChanged:)
                         name : ORStatusLogUpdatedNotification
                       object : nil];    
	
	[notifyCenter addObserver : self
					 selector : @selector(updateProcesses)
						 name : ORProcessRunningChangedNotification
					   object : nil];	
	
	[notifyCenter addObserver : self
					 selector : @selector(processElementStateChanged:)
						 name : ORProcessElementStateChangedNotification
					   object : nil];	
	
}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
	[self deleteDatabase];
}

- (void) awakeAfterDocumentLoaded
{
	[self updateRunInfo];
	[self alarmsChanged:nil];
	[self statusLogChanged:nil];
}

#pragma mark ***Accessors

- (BOOL) replicationRunning
{
    return replicationRunning;
}

- (void) setReplicationRunning:(BOOL)aReplicationRunning
{
    replicationRunning = aReplicationRunning;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBModelReplicationRunningChanged object:self];
}

- (BOOL) keepHistory
{
    return keepHistory;
}

- (void) setKeepHistory:(BOOL)aKeepHistory
{
    [[[self undoManager] prepareWithInvocationTarget:self] setKeepHistory:keepHistory];
	if([self couchRunning]){
		keepHistory = aKeepHistory;
		if(keepHistory){
			[self createHistoryDatabase];
		}
	} 
	else keepHistory=NO;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBModelKeepHistoryChanged object:self];
}

- (BOOL) stealthMode
{
    return stealthMode;
}

- (void) setStealthMode:(BOOL)aStealthMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStealthMode:stealthMode];
	BOOL okToRun = [self couchRunning];
	if(okToRun){
		stealthMode = aStealthMode;
		if(stealthMode){
			if([ORCouchDBQueue operationCount]) [ORCouchDBQueue cancelAllOperations];
			[self deleteDatabase];
		}
		else {
			[self createDatabase];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBModelStealthModeChanged object:self];
}

- (BOOL) couchRunning
{
	BOOL okToRun = YES;
	ORCouchDB* couch = [[[ORCouchDB alloc] init] autorelease];
	if(![couch couchDBRunning]){
		NSBeep();
		NSLogColor([NSColor redColor],@"It appears CouchDB is not running.\n");
		okToRun = NO;
	}
	
	return okToRun;
}

- (id) nextObject
{
	return [self objectConnectedTo:ORCouchDBModelInConnector];
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

- (NSString*) remoteHostName
{
    return remoteHostName;
}

- (void) setRemoteHostName:(NSString*)aHostName
{
	if(aHostName){
		[[[self undoManager] prepareWithInvocationTarget:self] setRemoteHostName:remoteHostName];
		
		[remoteHostName autorelease];
		remoteHostName = [aHostName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBRemoteHostNameChanged object:self];
	}
}

- (NSString*) databaseName
{		
	return [self machineName];
}

- (NSString*) historyDatabaseName
{		
	return [@"history_" stringByAppendingString:[self machineName]];
}

- (NSString*) machineName
{		
	NSString* machineName = [NSString stringWithFormat:@"%@",computerName()];
	machineName = [machineName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	return [machineName lowercaseString];
}

- (ORCouchDB*) statusDBRef
{
	return [ORCouchDB couchHost:@"localhost" port:kCouchDBPort username:userName pwd:password database:[self databaseName] delegate:self];
}

- (ORCouchDB*) historyDBRef
{
	return [ORCouchDB couchHost:@"localhost" port:kCouchDBPort username:userName pwd:password database:[self historyDatabaseName] delegate:self];
}

- (ORCouchDB*) remoteHistoryDBRef
{
	return [ORCouchDB couchHost:remoteHostName port:kCouchDBPort username:userName pwd:password database:[self historyDatabaseName] delegate:self];
}

- (ORCouchDB*) remoteDBRef
{
	return [ORCouchDB couchHost:remoteHostName port:kCouchDBPort username:userName pwd:password database:[self databaseName] delegate:self];
}

- (void) createDatabase
{
	//set up the views
	NSString* aMap;
	NSDictionary* aMapDictionary;
	NSMutableDictionary* aViewDictionary = [NSMutableDictionary dictionary];
	
	aMap            = @"function(doc) { if(doc.type == 'Histogram1D') { emit(doc.name, { 'name': doc.name, 'counts': doc.counts }); } }";
	aMapDictionary  = [NSDictionary dictionaryWithObject:aMap forKey:@"map"]; 
	[aViewDictionary setObject:aMapDictionary forKey:@"counts"]; 

	aMap            = @"function(doc) { if(doc.type == 'alarms') { emit(doc.type, {'alarmlist': doc.alarmlist}); } }";
	aMapDictionary  = [NSDictionary dictionaryWithObject:aMap forKey:@"map"]; 
	[aViewDictionary setObject:aMapDictionary forKey:@"alarms"]; 

	aMap            = @"function(doc) { if(doc.type == 'processes') { emit(doc.type, {'processlist': doc.processlist}); } }";
	aMapDictionary  = [NSDictionary dictionaryWithObject:aMap forKey:@"map"]; 
	[aViewDictionary setObject:aMapDictionary forKey:@"processes"]; 
	
	
	aMap            = @"function(doc) { if(doc.type == 'machineinfo') { emit(doc.type, doc); } }";
	aMapDictionary  = [NSDictionary dictionaryWithObject:aMap forKey:@"map"]; 
	[aViewDictionary setObject:aMapDictionary forKey:@"machineinfo"]; 

	aMap            = @"function(doc) { if(doc.type == 'runinfo') { emit(doc._id, doc); } }";
	aMapDictionary  = [NSDictionary dictionaryWithObject:aMap forKey:@"map"]; 
	[aViewDictionary setObject:aMapDictionary forKey:@"runinfo"]; 

	aMap            = @"function(doc) { if(doc.type == 'StatusLog') { emit(doc._id, doc); } }";
	aMapDictionary  = [NSDictionary dictionaryWithObject:aMap forKey:@"map"]; 
	[aViewDictionary setObject:aMapDictionary forKey:@"statuslog"]; 
	
	
	NSDictionary* theViews = [NSDictionary dictionaryWithObjectsAndKeys:
				  @"javascript",@"language",
				  aViewDictionary,@"views",
				  nil];	
		
	[[self statusDBRef] createDatabase:kCreateDB views:theViews];
}

- (void) createHistoryDatabase
{			
	NSString*     aMap;
	NSString*     aReduce;
	NSDictionary* aDictionary;
	NSMutableDictionary* aViewDictionary = [NSMutableDictionary dictionary];

	aMap            = @"function(doc) {if(doc.title){emit([doc.time,doc.title],doc);}}";
	aDictionary  = [NSDictionary dictionaryWithObject:aMap forKey:@"map"];
	[aViewDictionary setObject:aDictionary forKey:@"adcs"]; 

	
    NSBundle* mainBundle = [NSBundle mainBundle];
	NSString*   mapPath = [mainBundle pathForResource: @"CouchHistoryAveMap" ofType: @"txt"];
	NSString*   reducePath = [mainBundle pathForResource: @"CouchHistoryAveReduce" ofType: @"txt"];
    if([[NSFileManager defaultManager] fileExistsAtPath:mapPath] && [[NSFileManager defaultManager] fileExistsAtPath:reducePath] ){
		aMap         = [NSString stringWithContentsOfFile:mapPath encoding:NSASCIIStringEncoding error:nil];
		aReduce      = [NSString stringWithContentsOfFile:reducePath encoding:NSASCIIStringEncoding error:nil];
		NSMutableDictionary* aDictionary  = [NSMutableDictionary dictionary];
		[aDictionary setObject:aMap forKey:@"map"];
		[aDictionary setObject:aReduce forKey:@"reduce"];
		[aViewDictionary setObject:aDictionary forKey:@"ave"]; 
    }
	

	NSDictionary* theViews = [NSDictionary dictionaryWithObjectsAndKeys:
							  @"javascript",@"language",
							  aViewDictionary,@"views",
							  nil];	
	
	[[self historyDBRef] createDatabase:kCreateDB views:theViews];
	
}

- (void) createRemoteDataBases;
{			
	[[self remoteHistoryDBRef] createDatabase:kCreateRemoteDB views:nil];
	[[self remoteDBRef] createDatabase:kCreateRemoteDB views:nil];
}

- (void) replicate:(BOOL)continuously
{			
	[[self remoteHistoryDBRef] replicateLocalDatabase:kReplicateDB continous:continuously];
	[[self remoteDBRef] replicateLocalDatabase:kReplicateDB continous:continuously];
}


- (void) deleteDatabase
{
	[[self statusDBRef] deleteDatabase:kDeleteDB];
}

- (void) updateProcesses
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateProcesses) object:nil];
				
		NSArray* theProcesses = [[[[self document] collectObjectsOfClass:NSClassFromString(@"ORProcessModel")] retain] autorelease];
		
		NSMutableArray* arrayForDoc = [NSMutableArray array];
		if([theProcesses count]){
			for(id aProcess in theProcesses){
				NSString* shortName     = [aProcess shortName];
				
				NSDate *localDate = [aProcess lastSampleTime];
				
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				dateFormatter.dateFormat = @"yyyy/MM/dd HH:mm:ss";
				
				NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
				[dateFormatter setTimeZone:gmt];
				NSString *lastTimeStamp = [dateFormatter stringFromDate:localDate];
				NSDate* gmtTime = [dateFormatter dateFromString:lastTimeStamp];
				unsigned long secondsSince1970 = [gmtTime timeIntervalSince1970];
				[dateFormatter release];
				
				if(![lastTimeStamp length]) lastTimeStamp = @"0";
				if(![shortName length]) shortName = @"Untitled";
				
				NSString* s = [aProcess report];
				
				NSDictionary* processInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											 [aProcess fullID],@"name",
											 shortName,@"title",
											 lastTimeStamp,@"timestamp",
											 [NSNumber numberWithUnsignedLong: secondsSince1970],		@"time",
											 s,@"data",
											 [NSNumber numberWithUnsignedLong:[aProcess processRunning]] ,@"state",
											 nil];
				[arrayForDoc addObject:processInfo];
			}
		}
		
		NSDictionary* processInfo  = [NSDictionary dictionaryWithObjectsAndKeys:@"processinfo",@"name",arrayForDoc,@"processlist",@"processes",@"type",nil];
		[[self statusDBRef] updateDocument:processInfo documentId:@"processinfo" tag:kDocumentUpdated];
		
		[self performSelector:@selector(updateProcesses) withObject:nil afterDelay:30];	
	}
}

- (void) updateMachineRecord
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateMachineRecord) object:nil];
		
		struct ifaddrs *ifaddr, *ifa;
        if (getifaddrs(&ifaddr) == 0) {
            // Successfully received the structs of addresses.
            NSString* thisHostAdress = @"";
            char tempInterAddr[INET_ADDRSTRLEN];
            NSMutableArray* names = [NSMutableArray array];
            // The following is a replacement for [[NSHost currentHost] addresses].  The problem is
            // that the NSHost call can do reverse DNS calls which block and are *very* slow.  The 
            // following is much faster.
            for (ifa = ifaddr; ifa != nil; ifa = ifa->ifa_next) {
                // skip IPv6 addresses
                if (ifa->ifa_addr->sa_family != AF_INET) continue;
                inet_ntop(AF_INET, 
                          &((struct sockaddr_in *)ifa->ifa_addr)->sin_addr,
                          tempInterAddr,
                          sizeof(tempInterAddr));
                [names addObject:[NSString stringWithCString:tempInterAddr encoding:NSASCIIStringEncoding]];
            }
            freeifaddrs(ifaddr);
            // Now enumerate and find the first non-loop-back address.
            NSEnumerator* e = [names objectEnumerator];
            id aName;
            while(aName = [e nextObject]){
                if([aName rangeOfString:@".0.0."].location == NSNotFound){
                    thisHostAdress = aName;
                    break;
                }
            }
            NSDictionary* machineInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                         @"machineinfo",@"type",
                                         [NSNumber numberWithLong:[[[NSApp delegate] memoryWatcher] accurateUptime]], @"uptime",
                                          computerName(),@"name",
                                          macAddress(),@"hw_address",
                                          thisHostAdress,@"ip_address",
                                          fullVersion(),@"version",nil];	
                
            [[self statusDBRef] updateDocument:machineInfo documentId:@"machineinfo" tag:kDocumentUpdated];
		}
		[self performSelector:@selector(updateMachineRecord) withObject:nil afterDelay:5];	
	}
}

- (void) processElementStateChanged:(NSNotification*)aNote
{
	if(!historyUpdateScheduled){
		[self performSelector:@selector(updateHistory) withObject:nil afterDelay:60];
		historyUpdateScheduled = YES;
	}
}

- (void) updateHistory
{
	historyUpdateScheduled = NO;
	if(!stealthMode && keepHistory){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateHistory) object:nil];
				
		NSArray* theProcesses = [[[[self document] collectObjectsOfClass:NSClassFromString(@"ORProcessModel")] retain] autorelease];
				
		for(id aProcess in theProcesses){
			if([aProcess processRunning]){
				NSString* shortName     = [aProcess shortName];
				NSDate *localDate = [aProcess lastSampleTime];
				
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				dateFormatter.dateFormat = @"yyyy/MM/dd HH:mm:ss";
				
				NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
				[dateFormatter setTimeZone:gmt];
				NSString *lastTimeStamp = [dateFormatter stringFromDate:localDate];
				NSDate* gmtTime = [dateFormatter dateFromString:lastTimeStamp];
				unsigned long secondsSince1970 = [gmtTime timeIntervalSince1970];
				[dateFormatter release];
				
				
				if(![lastTimeStamp length]) lastTimeStamp = @"0";
				if(![shortName length]) shortName = @"Untitled";
				
				NSMutableDictionary* processDictionary = [aProcess processDictionary];
				if([processDictionary count]){
					
					NSMutableDictionary* processInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												[aProcess fullID],	@"name",
												shortName,			@"title",
												lastTimeStamp,		@"timestamp",
												[NSNumber numberWithUnsignedLong: secondsSince1970],		@"time",
												nil];
					
					[processInfo addEntriesFromDictionary:processDictionary];
					[[self historyDBRef] addDocument:processInfo tag:kDocumentAdded];
				}
			}
		}
		
	}
}

- (void) updateDatabaseStats
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDatabaseStats) object:nil];
		
		[[self statusDBRef] databaseInfo:self tag:kInfoInternalDB];
		if(keepHistory)[[self historyDBRef] databaseInfo:self tag:kInfoHistoryDB];
		[self getRemoteInfo:NO];
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

- (void) setDocuments:(NSDictionary*)someInfo
{
	@synchronized(self){
		[someInfo retain];
		[docList release];
		docList = someInfo;
		
		//---------temp---- for a db repair
		//		id theDocArray = [docList objectForKey:@"rows"];
		//for(id aDoc in theDocArray){
		//	id docId = [aDoc objectForKey:@"id"];
		//	if([docId rangeOfString:@"/"].location == NSNotFound){
		//		[[self historyDBRef] fixDocument:docId tag:kDocumentUpdated];
		//	}
		//}
		//------------------------------------
		
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBModelDBInfoChanged object:self];
}

- (void) setDBHistoryInfo:(NSDictionary*)someInfo
{
	@synchronized(self){
		[someInfo retain];
		[dBHistoryInfo release];
		dBHistoryInfo = someInfo;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBModelDBInfoChanged object:self];
}

- (NSDictionary*) dBInfo
{
	return [[dBInfo retain] autorelease];
}
- (NSDictionary*) dBHistoryInfo
{
	return [[dBHistoryInfo retain] autorelease];
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag
{
	@synchronized(self){
		if([aResult isKindOfClass:[NSDictionary class]]){
			NSString* message = [aResult objectForKey:@"Message"];
			if(message){
				if([aTag isEqualToString:kCreateRemoteDB]){
					NSLog(@"Following Couch Message is from: %@\n",remoteHostName);
				}
				[aResult prettyPrint:@"CouchDB Message:"];
			}
			else {
				if([aTag isEqualToString:kInfoDB]){
					[aResult prettyPrint:@"CouchDB Info:"];
				}
				else if([aTag isEqualToString:kDocumentAdded]){
					//ignore
				}
				else if([aTag isEqualToString:kCreateDB]){
					[aResult prettyPrint:@"CouchDB Message:"];
				}
				else if([aTag isEqualToString:kCreateRemoteDB]){
					[aResult prettyPrint:@"Remote Create Action:"];
				}
				else if([aTag isEqualToString:kDeleteDB]){
					[aResult prettyPrint:@"CouchDB Message:"];
				}
				
				else if([aTag isEqualToString:kInfoInternalDB]){
					[self performSelectorOnMainThread:@selector(setDBInfo:) withObject:aResult waitUntilDone:NO];
				}
				else if([aTag isEqualToString:kInfoHistoryDB]){
					[self performSelectorOnMainThread:@selector(setDBHistoryInfo:) withObject:aResult waitUntilDone:NO];
				}
				else if([aTag isEqualToString:kListDocuments]){
					[self performSelectorOnMainThread:@selector(setDocuments:) withObject:aResult waitUntilDone:NO];
				}
				
				else if([aTag isEqualToString:@"Message"]){
					[aResult prettyPrint:@"CouchDB Message:"];
				}
				else if([aTag isEqualToString:kCompactDB]){
					//[aResult prettyPrint:@"CouchDB Compacted:"];
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
			else if([aTag isEqualToString:kRemoteInfo]){
				[self processRemoteTaskList:aResult verbose:NO];
			}
			else if([aTag isEqualToString:kRemoteInfoVerbose]){
				[self processRemoteTaskList:aResult verbose:YES];
			}
			else [aResult prettyPrint:@"CouchDB"];
		}
		else {
			NSLog(@"%@\n",aResult);
		}
	}
}
- (void) processRemoteTaskList:(NSArray*)aList verbose:(BOOL)verbose
{
	if(!remoteHostName)return;
	if([aList count] && verbose)NSLog(@"Couch Remote Tasks:\n");
	for(id aTask in aList){
		if([[aTask objectForKey:@"type"] isEqualToString:@"Replication"]){
			NSString* anItem = [aTask objectForKey:@"task"];
			NSUInteger sepLoc = [anItem rangeOfString:@"->"].location;
			NSUInteger colonLoc = [anItem rangeOfString:@":"].location;
			if(colonLoc < sepLoc){
				NSString* result = [anItem substringFromIndex:colonLoc+1];
				if(verbose)NSLog(@"%@\n",result);
				if([result rangeOfString:remoteHostName].location != NSNotFound){
						[self setReplicationRunning:YES];
				}
				else [self setReplicationRunning:NO];
			}
			else if(verbose)NSLog(@"%@\n",anItem);
		}
	}
}

- (void) startReplication
{
	[self createRemoteDataBases];
	[self replicate:YES];

}

- (void) periodicCompact
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(periodicCompact) object:nil];
	[self compactDatabase];
	[self performSelector:@selector(periodicCompact) withObject:nil afterDelay:600];
}

- (void) compactDatabase
{
	[[self statusDBRef] compactDatabase:self tag:kCompactDB];
	[self performSelector:@selector(updateDatabaseStats) withObject:nil afterDelay:4];
}

- (void) listDatabases
{
	[[self statusDBRef] listDatabases:self tag:kListDB];
}

//temp......
- (void) listDocuments
{
	[[self historyDBRef] listDocuments:self tag:kListDocuments];
}

- (void) getRemoteInfo:(BOOL)verbose
{
	if(verbose)[[self statusDBRef] listTasks:self tag:kRemoteInfoVerbose];
	else	   [[self statusDBRef] listTasks:self tag:kRemoteInfo];
}

- (void) databaseInfo:(BOOL)toStatusWindow
{
	if(toStatusWindow)	[[self statusDBRef] databaseInfo:self tag:kInfoDB];
	else				[[self statusDBRef] databaseInfo:self tag:kInfoInternalDB];
}

- (void) runStatusChanged:(NSNotification*)aNote
{
	[self updateRunState:[aNote object]];
	[self updateDataSets];
}

- (void) runOptionsOrTimeChanged:(NSNotification*)aNote
{
	[self updateRunState:[aNote object]];
}

- (void) updateRunInfo
{
	NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
	if([runObjects count]){
		ORRunModel* rc = [runObjects objectAtIndex:0];
		[self updateRunState:rc];
		[self updateDataSets];
	}
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
			runNumber = [rc runNumber];
			subRunNumber = [rc subRunNumber];
			if(![rc isRunning] && ![rc offlineRun]){
				runNumber=0;
				subRunNumber=0;
			}
			[runInfo setObject:@"runinfo" forKey:@"type"];	
			[runInfo setObject:experimentName forKey:@"experiment"];	
			
			[[self statusDBRef] updateDocument:runInfo documentId:@"runinfo" tag:kDocumentUpdated];
			
			int runState = [[runInfo objectForKey:@"state"] intValue];
			if(runState == eRunInProgress){
				if(!dataMonitors){
					dataMonitors = [[NSMutableArray array] retain];
					NSArray* list = [[self document] collectObjectsOfClass:NSClassFromString(@"ORHistoModel")];
					for(ORDataChainObject* aDataMonitor in list){
						if([aDataMonitor involvedInCurrentRun]){
							[dataMonitors addObject:aDataMonitor];
						}
					}
				}
			}
			else {
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

- (void) statusLogChanged:(NSNotification*)aNote
{
	if(!stealthMode){
		if(!statusUpdateScheduled){
			[self performSelector:@selector(updateStatus) withObject:nil afterDelay:10];
			statusUpdateScheduled = YES;
		}
	}
}

- (void) updateStatus
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateStatus) object:nil];
	statusUpdateScheduled = NO;
	NSString* s = [[ORStatusController sharedStatusController] contents];
	NSDictionary* dataInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  s,				@"statuslog",
							  @"StatusLog",		@"type",
							  nil];
	
	[[self statusDBRef] updateDocument:dataInfo documentId:@"statuslog" tag:kDocumentAdded];
	
}

- (void) alarmsChanged:(NSNotification*)aNote
{
	if(!stealthMode){
		ORAlarmCollection* alarmCollection = [ORAlarmCollection sharedAlarmCollection];
		NSArray* theAlarms = [[[alarmCollection alarms] retain] autorelease];
		NSMutableArray* arrayForDoc = [NSMutableArray array];
		if([theAlarms count]){
			for(id anAlarm in theAlarms)[arrayForDoc addObject:[anAlarm alarmInfo]];
		}
		NSDictionary* alarmInfo  = [NSDictionary dictionaryWithObjectsAndKeys:@"alarms",@"name",arrayForDoc,@"alarmlist",@"alarms",@"type",nil];
		[[self statusDBRef] updateDocument:alarmInfo documentId:@"alarms" tag:kDocumentAdded];
	}
}

- (void) updateDataSets
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDataSets) object:nil];
		
		NSUInteger n = [ORCouchDBQueue operationCount];
		if(n<10){
				
			for(id aMonitor in dataMonitors){
				NSArray* objs1d = [[aMonitor  collectObjectsOfClass:[OR1DHisto class]] retain];
				@try {
					for(id aDataSet in objs1d){
						unsigned long start,end;
					    NSString* s = [aDataSet getnonZeroDataAsStringWithStart:&start end:&end];
						NSDictionary* dataInfo = [NSDictionary dictionaryWithObjectsAndKeys:
													[aDataSet fullName],										@"name",
													[NSNumber numberWithUnsignedLong:[aDataSet totalCounts]],	@"counts",
													[NSNumber numberWithUnsignedLong:start],					@"start",
													[NSNumber numberWithUnsignedLong:[aDataSet numberBins]],	@"length",
													s,															@"PlotData",
													@"Histogram1D",												@"type",
													 nil];
						NSString* dataName = [[[aDataSet fullName] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];

						[[self statusDBRef] updateDocument:dataInfo documentId:dataName tag:kDocumentAdded];
						
					}
				}
				@catch(NSException* e){
				}
				@finally {
					[objs1d release];
				}
			}
		}

		[self performSelector:@selector(updateDataSets) withObject:nil afterDelay:10];
	}
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{    
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setKeepHistory:[decoder decodeBoolForKey:@"keepHistory"]];
    [self setPassword:[decoder decodeObjectForKey:@"Password"]];
    [self setUserName:[decoder decodeObjectForKey:@"UserName"]];
    [self setRemoteHostName:[decoder decodeObjectForKey:@"RemoteHostName"]];
    [self setStealthMode:[decoder decodeBoolForKey:@"stealthMode"]];
    [[self undoManager] enableUndoRegistration];    
	[self registerNotificationObservers];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:keepHistory forKey:@"keepHistory"];
    [encoder encodeBool:stealthMode forKey:@"stealthMode"];
    [encoder encodeObject:password forKey:@"Password"];
    [encoder encodeObject:userName forKey:@"UserName"];
    [encoder encodeObject:remoteHostName forKey:@"RemoteHostName"];
}
@end

