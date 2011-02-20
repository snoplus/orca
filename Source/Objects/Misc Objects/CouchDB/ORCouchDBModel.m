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

NSString* ORCouchDBModelStealthModeChanged	= @"ORCouchDBModelStealthModeChanged";
NSString* ORCouchDBDataBaseNameChanged		= @"ORCouchDBDataBaseNameChanged";
NSString* ORCouchDBPasswordChanged			= @"ORCouchDBPasswordChanged";
NSString* ORCouchDBUserNameChanged			= @"ORCouchDBUserNameChanged";
NSString* ORCouchDBHostNameChanged			= @"ORCouchDBHostNameChanged";
NSString* ORCouchDBConnectionValidChanged	= @"ORCouchDBConnectionValidChanged";
NSString* ORCouchDBLock						= @"ORCouchDBLock";

#define kCreateDB	@"kCreateDB"
#define kListDB		@"kListDB"
#define kDocumentUpdated @"kDocumentUpdated"
#define kDocument	@"kDocument"


static NSString* ORCouchDBModelInConnector 	= @"ORCouchDBModelInConnector";

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [dataBaseName release];
    [password release];
    [userName release];
    [hostName release];
	[super dealloc];
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
	
}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
}


#pragma mark ***Accessors
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


- (void) createDatabase
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:5984 database:dataBaseName];
	//[db version:self tag:@"Version"];
	if([dataBaseName length]){
		[db createDatabase:dataBaseName delegate:self tag:kCreateDB];
	}
	//[db listDatabases:self tag:@"List"];
	//NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"123",@"Run",@"12:00",@"Time",nil];
	//[db addDocument:aDictionary documentId:@"idtest" database:self name:dataBaseName tag:@"addedDoc"];
	//[db getDocumentId:@"idtest" database:dataBaseName delegate:self tag:@"returnedDoc"];
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag
{
	@synchronized(self){
		if([aTag isEqualToString:kCreateDB]){
			int value = [[aResult objectForKey:@"ok"] intValue];
			if(value)NSLog(@"Created counchDB: %@\n",dataBaseName);
			else	 NSLog(@"Failed to create couchdB: %@\n",dataBaseName);
		}
		else if([aTag isEqualToString:kListDB]){
			NSLog(@"Database List: %@\n",aResult);
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
- (void) updateFunction
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:5984 database:dataBaseName];
	NSString* theTime = [NSString stringWithFormat:@"%@",[NSDate date]];
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"123",@"Run",theTime,@"Time",nil];
	[db updateDocument:aDictionary documentId:@"idtest" database:dataBaseName delegate:self tag:kDocumentUpdated];
	[db getDocumentId:@"idtest" database:dataBaseName delegate:self tag:kDocument];
}

- (void) listFunction
{
	ORCouchDB* db = [ORCouchDB couchHost:hostName port:5984 database:dataBaseName];
	[db listDatabases:self tag:kListDB];
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

