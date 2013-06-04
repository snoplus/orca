//
//  ORCouch.m
//  Orca
//
//  Created by Mark Howe on 02/19/11.
//  Copyright 20011, University of North Carolina
//-------------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORCouchDB.h"
#import <YAJL/NSObject+YAJL.h>
#import <YAJL/YAJLDocument.h>
#import "SynthesizeSingleton.h"

@implementation ORCouchDB

@synthesize database,host,port,queue,delegate,username,pwd;

+ (id) couchHost:(NSString*)aHost port:(NSUInteger)aPort username:(NSString*)aUsername pwd:(NSString*)aPwd database:(NSString*)aDatabase delegate:(id)aDelegate
{
	return [[[ORCouchDB alloc] initWithHost:aHost port:aPort username:aUsername pwd:aPwd database:aDatabase delegate:aDelegate] autorelease];
}

+ (id) couchHost:(NSString*)aHost port:(NSUInteger)aPort database:(NSString*)aDatabase delegate:(id)aDelegate
{
	return [[[ORCouchDB alloc] initWithHost:aHost port:aPort database:aDatabase delegate:aDelegate] autorelease];
}

- (id) initWithHost:(NSString*)aHost port:(NSUInteger)aPort database:(NSString*)aDatabase delegate:(id)aDelegate
{
	return [self initWithHost:aHost port:aPort username:nil pwd:nil database:aDatabase delegate:aDelegate];
}

- (id) initWithHost:(NSString*)aHost port:(NSUInteger)aPort username:(NSString*)aUsername pwd:(NSString*)aPwd database:(NSString*)aDatabase delegate:(id)aDelegate
{
	self = [super init];
	self.delegate = aDelegate;
	self.database = aDatabase;
	self.host = aHost;
	self.port = aPort;
	self.username = aUsername;
	self.pwd = aPwd;
	return self;
}

- (void) dealloc
{
	self.username	= nil;
	self.pwd		= nil;
	self.host		= nil;
	self.database	= nil;
	[super dealloc];
}

- (void) version:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBVersionOp* anOp = [[ORCouchDBVersionOp alloc] initWithHost:host port:port database:nil delegate:aDelegate tag:aTag];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

#pragma mark •••DataBase API
- (void) compactDatabase:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBCompactDBOp* anOp = [[ORCouchDBCompactDBOp alloc] initWithHost:host port:port database:database delegate:aDelegate tag:aTag];
	[anOp setUsername:username];
	[anOp setPwd:pwd];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) databaseInfo:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBInfoDBOp* anOp = [[ORCouchDBInfoDBOp alloc] initWithHost:host port:port database:database delegate:aDelegate tag:aTag];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) listDatabases:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBListDBOp* anOp = [[ORCouchDBListDBOp alloc] initWithHost:host port:port database:nil delegate:delegate tag:aTag];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) listDocuments:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBListDocsOp* anOp = [[ORCouchDBListDocsOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) processEachDoc:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBProcessEachDocOp* anOp = [[ORCouchDBProcessEachDocOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) renameDoc:(id)aDoc adc:(NSString*)oldName to:(NSString*)aReplacementName delegate:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBRenameAdcOp* anOp = [[ORCouchDBRenameAdcOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setDocument:aDoc documentID:[aDoc objectForKey:@"_id"]];
	[anOp setOldName: oldName];
	[anOp setReplacementName: aReplacementName];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) listTasks:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBListTasksOp* anOp = [[ORCouchDBListTasksOp alloc] initWithHost:host port:port database:nil delegate:delegate tag:aTag];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}
- (void) createDatabase:(NSString*)aTag views:(NSDictionary*)theViews
{
	ORCouchDBCreateDBOp* anOp = [[ORCouchDBCreateDBOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setUsername:username];
	[anOp setPwd:pwd];
	if(theViews)[anOp setViews:theViews];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) deleteDatabase:(NSString*)aTag;
{
	ORCouchDBDeleteDBOp* anOp = [[ORCouchDBDeleteDBOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setUsername:username];
	[anOp setPwd:pwd];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) replicateLocalDatabase:(NSString*)aTag continous:(BOOL)continuous
{
	ORCouchDBReplicateDBOp* anOp = [[ORCouchDBReplicateDBOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setUsername:username];
	[anOp setPwd:pwd];
	[anOp setContinuous:continuous];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}


#pragma mark •••Document API
- (void) deleteDocumentId:(NSString*)anId tag:(NSString*)aTag;
{
	ORCouchDBDeleteDocumentOp* anOp = [[ORCouchDBDeleteDocumentOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setDocumentId:anId];
	[anOp setUsername:username];
	[anOp setPwd:pwd];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) addDocument:(NSDictionary*)aDict tag:(NSString*)aTag;
{
	[self addDocument:aDict documentId:nil tag:aTag];
}

- (void) addDocument:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag;
{
	ORCouchDBPutDocumentOp* anOp = [[ORCouchDBPutDocumentOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setDocument:aDict documentID:anId];
	[anOp setUsername:username];
	[anOp setPwd:pwd];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) updateDocument:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag;
{
	ORCouchDBUpdateDocumentOp* anOp = [[ORCouchDBUpdateDocumentOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setDocument:aDict documentID:anId];
	[anOp setUsername:username];
	[anOp setPwd:pwd];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) updateDocument:(NSDictionary*)aDict documentId:(NSString*)anId attachmentData:(NSData*)someData attachmentName:(NSString*)aName tag:(NSString*)aTag;
{
	ORCouchDBUpdateDocumentOp* anOp = [[ORCouchDBUpdateDocumentOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setDocument:aDict documentID:anId];
	[anOp setAttachment:someData];
	[anOp setAttachmentName:aName];
	[anOp setUsername:username];
	[anOp setPwd:pwd];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) updateDocument:(NSDictionary *)aDict documentId:(NSString *)anId tag:(NSString *)aTag informingDelegate:(BOOL)ok
{
    ORCouchDBUpdateDocumentOp* anOp = [[ORCouchDBUpdateDocumentOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setDocument:aDict documentID:anId];
	[anOp setUsername:username];
	[anOp setPwd:pwd];
    [anOp setInformDelegate:ok];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}
- (void) updateEventCatalog:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag;
{
	ORCouchDBUpdateEventCatalogOp* anOp = [[ORCouchDBUpdateEventCatalogOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setDocument:aDict documentID:anId];
	[anOp setUsername:username];
	[anOp setPwd:pwd];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) getDocumentId:(NSString*)anId  tag:(NSString*)aTag
{
	ORCouchDBGetDocumentOp* anOp = [[ORCouchDBGetDocumentOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setDocumentId:anId];
    [anOp setUsername:username];
	[anOp setPwd:pwd];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

#pragma mark ***Changes API
- (NSOperation*) changesFeedMode:(NSString*)mode Tag:(NSString*)aTag{
    return [self changesFeedMode:mode Heartbeat:(NSUInteger)5000 Tag:aTag];
}

- (NSOperation*) changesFeedMode:(NSString*)mode Heartbeat:(NSUInteger)heartbeat Tag:(NSString*)aTag{
    ORCouchDBChangesfeedOp* anOp=[[[ORCouchDBChangesfeedOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag] autorelease];
    [anOp setUsername:username];
	[anOp setPwd:pwd];
    [anOp setListeningMode:mode];
    [anOp setHeartbeat:heartbeat];
	[ORCouchDBQueue addOperation:anOp];
	return anOp;
}

#pragma mark ***CouchDB Checks
- (BOOL) couchDBRunning
{
	BOOL couchDBRunning = NO;
	@try {
		NSTask* task = [[[NSTask alloc] init] autorelease];
		[task setLaunchPath: @"/bin/ps"];
		[task setArguments: [NSArray arrayWithObjects:@"-ef",nil]];
		
		NSPipe* pipe = [NSPipe pipe];
		[task setStandardOutput: pipe];
		
		NSFileHandle* file = [pipe fileHandleForReading];
		
		[task launch];
		NSData* data = [file readDataToEndOfFile];		
		[task waitUntilExit];
		

		NSString* result = [[[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding] autorelease];
		if([result rangeOfString:@"couchdb"].location != NSNotFound &&
		   [result rangeOfString:@"erlang"].location != NSNotFound) {
			couchDBRunning = YES;
		}
	}
	@catch (NSException* e) {
	}
	return couchDBRunning;
}

@end

#pragma mark •••Threaded Ops
@implementation ORCouchDBOperation

@synthesize username,pwd;

- (id) initWithHost:(NSString*)aHost port:(NSInteger)aPort database:(NSString*)aDatabase delegate:(id)aDelegate tag:(NSString*)aTag;
{
	self = [super init];
	//normally a delegate would not be retained. In this case, we have
	//to ensure that the delegate is still around when the op executes
	//out of a thread
	delegate = [aDelegate retain]; 
	database = [aDatabase copy];
	tag		 = [aTag copy];
	host	 = [aHost copy];
	port	 = aPort;
	pwd = nil;
	username = nil;
	return self;
}

- (void) dealloc
{
	[username release];
	[pwd release];
	[host release];
	[tag release];
	[database release];
	[delegate release];
	[super dealloc];
}

- (id) send:(NSString*)httpString
{
	return [self send:httpString type:nil body:nil];
}

- (id) send:(NSString*)httpString type:(NSString*)aType
{
	return [self send:httpString type:aType body:nil];
}

- (id) send:(NSString*)httpString type:(NSString*)aType body:(NSDictionary*)aBody
{
	if(username && pwd){
		httpString = [httpString stringByReplacingOccurrencesOfString:@"://" withString:[NSString stringWithFormat:@"://%@:%@@",username,pwd]];
	}
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:httpString]];
    //[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    
    if(aType){
		[request setHTTPMethod:aType];
		if([aType isEqualToString:@"POST"]){
			[request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"]];
		}
	}
	if(aBody)[request setHTTPBody:[[aBody yajl_JSONString] dataUsingEncoding:NSASCIIStringEncoding]];
	NSData *data = [[[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil] retain] autorelease];
    
	if (data) {
		YAJLDocument *document = [[[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:nil] autorelease];
		return [document root];
	}
	else return nil;
}

- (void) sendToDelegate:(id)obj
{
	if(obj && [delegate respondsToSelector:@selector(couchDBResult:tag:op:)]){
		[delegate couchDBResult:obj tag:tag op:self];
	}
}	

- (NSString*) revision:(NSString*)anID
{
	NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, anID];
	id result = [self send:httpString];
	return [result objectForKey:@"_rev"];
}
@end


#pragma mark •••Database API


@implementation ORCouchDBCompactDBOp
-(void) main
{	
	if([self isCancelled])return;
	NSString* httpString = [NSString stringWithFormat:@"http://%@:%u/%@/_compact", host, port,database];
	if(username && pwd){
		httpString = [httpString stringByReplacingOccurrencesOfString:@"://" withString:[NSString stringWithFormat:@"://%@:%@@",username,pwd]];
	}
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:httpString]];
	[request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"]];
	[request setHTTPMethod:@"POST"];
	NSData *data = [[[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil] retain] autorelease];	
	YAJLDocument *document = nil;
	if (data) {
		document = [[[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:nil] autorelease];
		[self sendToDelegate:[document root]];
	}	
}
@end

@implementation ORCouchDBListDBOp
-(void) main
{
	if([self isCancelled])return;
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u/_all_dbs", host, port]];
	for(id name in result){
        NSLog([NSString stringWithFormat:@"%@\n",name]);
	}
	[self sendToDelegate:result];
}
@end

@implementation ORCouchDBProcessEachDocOp
-(void) main
{
	if([self isCancelled])return;
	if([delegate respondsToSelector:@selector(startingSweep)]){
		[delegate performSelectorOnMainThread:@selector(startingSweep) withObject:nil waitUntilDone:NO ];
	}
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u/%@/_all_docs", host, port,database]];
	
	id theDocArray = [result objectForKey:@"rows"];
	for(id aDoc in theDocArray){
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		id docId = [aDoc objectForKey:@"id"];
		if([docId rangeOfString:@"/"].location == NSNotFound){
			NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, docId];
			id result = [self send:httpString];
			[self sendToDelegate:result];
		}
		[pool release];
		if([self isCancelled])break;
	}
	if([delegate respondsToSelector:@selector(sweepDone)]){
		[delegate performSelectorOnMainThread:@selector(sweepDone) withObject:nil waitUntilDone:NO ];
	}
}
@end

@implementation ORCouchDBRenameAdcOp
@synthesize oldName,replacementName;
- (void) main
{
	if([self isCancelled])return;
	if([replacementName length]==0)return;
	if([oldName length]==0)return;
	NSArray* adcs = [document objectForKey:@"adcs"];
	for(id anAdc in adcs){
		for(id aKey in anAdc){
			if([aKey isEqualToString:oldName]){
				id theValue = [anAdc objectForKey:aKey];
				[anAdc setObject:theValue forKey:replacementName];
				[anAdc removeObjectForKey:oldName];
				NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, documentId];
				[self send:httpString type:@"PUT" body:document];
				if([delegate respondsToSelector:@selector(incChangeCounter)]){
					[delegate performSelectorOnMainThread:@selector(incChangeCounter) withObject:nil waitUntilDone:NO ];
				}
			}
		}
	}
	
}

- (void) dealloc
{
	self.replacementName=nil;
	self.oldName=nil;
	[super dealloc];
}
@end


@implementation ORCouchDBListDocsOp
-(void) main
{
	if([self isCancelled])return;
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u/%@/_all_docs", host, port,database]];
	[self sendToDelegate:result];
}
@end

@implementation ORCouchDBListTasksOp
-(void) main
{
	if([self isCancelled])return;
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u/_active_tasks", host, port]];
	[self sendToDelegate:result];
}
@end
@implementation ORCouchDBVersionOp
- (void) main
{
	if([self isCancelled])return;
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u", host, port]];
	[self sendToDelegate:result];
}

@end

@implementation ORCouchDBInfoDBOp
-(void) main
{
	if([self isCancelled])return;
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u/%@/", host, port,database]];
	[self sendToDelegate:result];
}
@end

@implementation ORCouchDBCreateDBOp
@synthesize views;
- (void) dealloc
{
	self.views = nil;
	[super dealloc];
}

-(void) main
{
	if([self isCancelled])return;
	NSString *escaped = [database stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u/_all_dbs", host, port]];
	if(![result containsObject:database]){
		result = [self send:[NSString stringWithFormat:@"http://%@:%u/%@", host, port, escaped] type:@"PUT"];
		if([response statusCode] != 201)  result = [NSDictionary dictionaryWithObjectsAndKeys:
												   [NSString stringWithFormat:@"[%@] creation FAILED",database],
												   @"Message",
												   [NSString stringWithFormat:@"Error Code: %d",[response statusCode]],
												   @"Reason",
												   nil];
		else {
            if(views){
                NSMutableDictionary* allMaps = [NSMutableDictionary dictionary];

                NSDictionary* viewDictionary = [views objectForKey:@"views"];
                for(id aViewKey in viewDictionary){
                    
                    NSMutableDictionary* aNewView = [[[viewDictionary objectForKey:aViewKey] mutableCopy] autorelease];
                                    
                    id mapName = [[[aNewView objectForKey:@"mapName"] retain] autorelease];
                    if(![mapName length])mapName = database;
                    else [aNewView removeObjectForKey:@"mapName"];
                    
                    if(![allMaps objectForKey:mapName]){
                        [allMaps setObject:[NSMutableDictionary dictionary] forKey:mapName];
                        [[allMaps objectForKey:mapName] setObject:@"javascript" forKey:@"language"];
                        [[allMaps objectForKey:mapName] setObject:[NSMutableDictionary dictionary] forKey:@"views"];
                    }
                    
                    [[[allMaps objectForKey:mapName] objectForKey:@"views"] setObject:aNewView forKey:aViewKey];
                 }
                 for(id aMapName in allMaps){
                    NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/_design/%@", host, port, database, aMapName];
                    /*id result = */[self send:httpString type:@"PUT" body:[allMaps objectForKey:aMapName]];
                 }
            }
            
        }
	}
	else {
		result = [NSDictionary dictionaryWithObjectsAndKeys:
				  @"Did not create new database", @"Message",
				  [NSString stringWithFormat:@"[%@] already exists",database],
				  @"Reason",nil];
	}
	[self sendToDelegate:result];
}


@end

@implementation ORCouchDBDeleteDBOp
-(void) main
{
	if([self isCancelled])return;
	
	NSString *escaped = [database stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u/_all_dbs", host, port]];
	if([result containsObject:database]){
		result = [self send:[NSString stringWithFormat:@"http://%@:%u/%@", host, port, escaped] type:@"DELETE"];
		if([response statusCode] != 200) result = [NSDictionary dictionaryWithObjectsAndKeys:
												   [NSString stringWithFormat:@"[%@] deletion FAILED",database],
												   @"Message",
												   [NSString stringWithFormat:@"Error Code: %d",[response statusCode]],
												   @"Reason",
												   nil];
	}
	else result = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"[%@] didn't exist",database],@"Message",nil];
	[self sendToDelegate:result];
}
@end

@implementation ORCouchDBReplicateDBOp
@synthesize continuous;
- (void) main
{
	if([self isCancelled])return;
	NSString* escaped   = [database stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString* httpString = [NSString stringWithFormat:@"http://127.0.0.1:%u/_replicate", port];
	if(username && pwd){
		httpString = [httpString stringByReplacingOccurrencesOfString:@"://" withString:[NSString stringWithFormat:@"://%@:%@@",username,pwd]];
	}
	
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:httpString]];
	[request setHTTPMethod:@"POST"];
	[request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"]];
	NSString* target = [NSString stringWithFormat:@"http://%@:%d/%@",host,port,escaped];
	NSDictionary* aBody;
	if(continuous) aBody= [NSDictionary dictionaryWithObjectsAndKeys:escaped,@"source",target,@"target",[NSNumber numberWithBool:1],@"continuous",nil];
	else           aBody = [NSDictionary dictionaryWithObjectsAndKeys:escaped,@"source",target,@"target",nil];
	NSString* s = [aBody yajl_JSONString];
	NSData* asData = [s dataUsingEncoding:NSASCIIStringEncoding];
	[request setHTTPBody:asData];
	NSData *data = [[[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil] retain] autorelease];
	
	id result = nil;
	if (data) {
		YAJLDocument *document = [[[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:nil] autorelease];
		result= [document root];
	}
	
	[self sendToDelegate:result];
}

@end


#pragma mark •••Document API
@implementation ORCouchDBPutDocumentOp
- (void) dealloc 
{
	[document release];
	[documentId release];
	[attachmentData release];
	[attachmentName release];
	[super dealloc];
}

- (void) setDocument:(NSDictionary*)aDocument documentID:(NSString*)anID
{
	
	[aDocument retain];
	[document release];
	document = aDocument;
	
	[documentId autorelease];
	documentId = [anID copy];
}

- (void) setAttachmentName:(NSString*)aName
{
	[attachmentName autorelease];
	attachmentName = [aName copy];
}
- (void) setAttachment:(NSData*)someData
{
	[someData retain];
	[attachmentData release]; 
	attachmentData = someData;
}

- (void) main
{
	if([self isCancelled])return;
	NSString* httpString;
	NSString* action;
	if(documentId){
		action = @"PUT";
		httpString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, documentId];
	}
	else {
		action = @"POST";
		httpString = [NSString stringWithFormat:@"http://%@:%u/%@", host, port, database];
	}	
	
	
	id result = [self send:httpString type:action body:document];
	if(!result){
		result = [NSDictionary dictionaryWithObjectsAndKeys:
				  [NSString stringWithFormat:@"[%@] timeout",
				   database],@"Message",nil];
		[self sendToDelegate:result];
	}	
	else {
		if(attachmentData){
			[self addAttachement];
		}
	}
	
	[self sendToDelegate:result];
	
}

- (id) addAttachement
{
	NSString* rev = [self revision:documentId];
	if(rev){
		NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, documentId];
		if(username && pwd){
			httpString = [httpString stringByReplacingOccurrencesOfString:@"://" withString:[NSString stringWithFormat:@"://%@:%@@",username,pwd]];
		}
		httpString = [httpString stringByAppendingFormat:@"/%@?rev=%@",attachmentName,rev];
		NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:httpString]];
		[request setHTTPMethod:@"PUT"];
		[request setHTTPBody:attachmentData];
		
		NSData *data = [[[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil] retain] autorelease];
		
		
		if (data) {
			YAJLDocument *result = [[[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:nil] autorelease];
			return [result root];
		}
		else {
			return [NSDictionary dictionaryWithObjectsAndKeys:
					[NSString stringWithFormat:@"[%@] timeout",
					 database],@"Message",nil];
		}
		
	}
	return nil;
}

@end

//-------------------------

@implementation ORCouchDBUpdateDocumentOp
- (void) main
{
	if([self isCancelled])return;
	//check for an existing document
	NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, documentId];
	id result = [self send:httpString];
	if(!result){
		result = [NSDictionary dictionaryWithObjectsAndKeys:
				  [NSString stringWithFormat:@"[%@] timeout",
				   database],@"Message",nil];
		informDelegate=YES;
	}
	else if([result objectForKey:@"error"]){
		//document doesn't exist. So just add it.
		result = [self send:httpString type:@"PUT" body:document];
		if(![result objectForKey:@"error"] && attachmentData){
			[self addAttachement];
		}
	}
	else {
		//it already exists. insert the rev number into the document and put it back
		id rev = [result objectForKey:@"_rev"];
		if(rev){
			NSMutableDictionary* newDocument = [NSMutableDictionary dictionaryWithDictionary:document];
			[newDocument setObject:rev forKey:@"_rev"];
			result = [self send:httpString type:@"PUT" body:newDocument];
			if(![result objectForKey:@"error"] && attachmentData){
				[self addAttachement];
			}
		}
	}
    if (informDelegate) [self sendToDelegate:result];

}
- (void) setInformDelegate:(BOOL)ok
{
    informDelegate = ok;
}
@end

@implementation ORCouchDBUpdateEventCatalogOp
- (void) main
{
	if([self isCancelled])return;
	//check for an existing document
	NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, documentId];
	id result = [self send:httpString];
	if(!result){
		result = [NSDictionary dictionaryWithObjectsAndKeys:
				  [NSString stringWithFormat:@"[%@] timeout",
				   database],@"Message",nil];
		[self sendToDelegate:result];
	}
	else if([result objectForKey:@"error"]){
		//document doesn't exist. So just add it.
        NSArray* anEvent = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:[document objectForKey:@"time"] forKey:[document objectForKey:@"name"]]];
        NSDictionary* newDocument = [NSDictionary dictionaryWithObjectsAndKeys:@"EventCatalog",@"name", @"Event Catalog",@"title",anEvent,@"events",nil];
		result = [self send:httpString type:@"PUT" body:newDocument];
		if(![result objectForKey:@"error"] && attachmentData){
			[self addAttachement];
		}
	}
	else {
		//it already exists. insert the rev number into the document and put it back
		id rev = [result objectForKey:@"_rev"];
		if(rev){
            NSString* eventNameForCatalog = [document objectForKey:@"name"];
			NSMutableDictionary* newDocument = [NSMutableDictionary dictionaryWithDictionary:result];
            NSArray* eventsAlreadyInCatalog = [result objectForKey:@"events"];
            for(id anEntry in eventsAlreadyInCatalog){
                if([anEntry objectForKey:eventNameForCatalog])return; //alreay there
            }
            //if we get here, it's not in the list of events already
            NSArray* newArray = [[result objectForKey:@"events"] arrayByAddingObject:[NSDictionary dictionaryWithObject:[document objectForKey:@"time"] forKey:eventNameForCatalog]];
            [newDocument setObject:newArray forKey:@"events"];
            [newDocument setObject:rev forKey:@"_rev"];
            result = [self send:httpString type:@"PUT" body:newDocument];
		}
	}
    
}
@end

@implementation ORCouchDBDeleteDocumentOp
- (void) main
{
	if([self isCancelled])return;
	//check for an existing document
	NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, documentId];
	id result = [self send:httpString];
	id rev = [result objectForKey:@"_rev"];
	if(rev){
		httpString = [httpString stringByAppendingFormat:@"?rev=%@",rev];
		[self send:httpString type:@"DELETE"];
	}
}
@end

@implementation ORCouchDBGetDocumentOp
- (void) dealloc 
{
	[documentId release];
	[super dealloc];
}

- (void) setDocumentId:(NSString*)anID
{
	[documentId autorelease];
	documentId = [anID copy];
}

- (void) main
{
	if([self isCancelled])return;
    NSString* escaped = [documentId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, escaped];
	id result = [self send:httpString];
	[self sendToDelegate:result];
}
@end


static void callback(CFReadStreamRef stream, CFStreamEventType type, ORCouchDBChangesfeedOp* delegate){
    
    UInt8 data[1024];
    CFHTTPMessageRef aResponse;
    int len;
    NSURL* url;
    int status;
    NSHTTPURLResponse* response;
    NSDictionary* header;
    switch(type){
        case kCFStreamEventHasBytesAvailable:
            if([delegate isWaitingForResponse]){
                aResponse = (CFHTTPMessageRef)CFReadStreamCopyProperty(stream, kCFStreamPropertyHTTPResponseHeader);
                if (CFHTTPMessageIsHeaderComplete(aResponse)){
                    url=[(NSURL*)CFHTTPMessageCopyRequestURL(aResponse) autorelease];
                    status=CFHTTPMessageGetResponseStatusCode(aResponse);
                    header=[(NSDictionary*)CFHTTPMessageCopyAllHeaderFields(aResponse) autorelease];
                    response=[[[NSHTTPURLResponse alloc] initWithURL:url statusCode:status HTTPVersion:@"HTTP/1.1" headerFields:header]autorelease];
                    [delegate streamReceivedResponse:response];
                }
                CFRelease(aResponse);
                break;
                
            }
            len=CFReadStreamRead(stream, data, sizeof(data));
            if (len < 0) {
                [delegate streamFailedWithError:[(NSError*) CFReadStreamCopyError(stream) autorelease]];
            }
            [delegate streamReceivedData:[NSData dataWithBytes:data length:len]];
            break;
        case kCFStreamEventErrorOccurred:
            [delegate streamFailedWithError:[(NSError*) CFReadStreamCopyError(stream) autorelease]];
            break;
        case kCFStreamEventEndEncountered:
            [delegate streamFinished];
            break;
        default:break;
    }
}

@interface ORCouchDBChangesfeedOp (private)
- (void) _startConnection;
- (void) _clearConnection;
@end

@implementation ORCouchDBChangesfeedOp (private)
-(void) _clearConnection {
    [self sendToDelegate:[NSString stringWithFormat:@"%@: Stopped", self]];
    [_inputBuffer release];
    _inputBuffer = nil;
    _status = 0;
}

-(void) _startConnection {
    if([self isCancelled]){
        [self _clearConnection];
        return;
    }
    
    //get the current last_seq so we only receive changes from now on. if we want the complete history, set last_seq to 0
    NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/_changes", host, port,database];
    if(username && pwd){
		httpString = [httpString stringByReplacingOccurrencesOfString:@"://" withString:[NSString stringWithFormat:@"://%@:%@@",username,pwd]];
	}
    id result = [self send:httpString];
    NSNumber* last_seq;
    last_seq=(NSNumber*)[result objectForKey:@"last_seq"];
    //last_seq=[NSNumber numberWithInt:0];
    
    NSRunLoop* rl = [NSRunLoop currentRunLoop];
    
    
    CFStringRef bodyString = CFSTR(""); // Usually used for POST data
    CFDataRef bodyData = CFStringCreateExternalRepresentation(kCFAllocatorDefault, bodyString, kCFStringEncodingUTF8, 0);
    
    CFStringRef headerFieldName = CFSTR("content-type");
    CFStringRef headerFieldValue = CFSTR("text/json");
    
    if (!heartbeat) {
        heartbeat=(NSUInteger) 5000;
    }
    
    NSString *options=[NSString stringWithFormat:@"?heartbeat=%u&feed=continuous&since=%@", heartbeat, last_seq];
    if (filter) {
        options = [options stringByAppendingString:[NSString stringWithFormat:@"&filter=%@", filter]];
    }
    httpString = [httpString stringByAppendingString:options];
    CFStringRef url = (CFStringRef)httpString;
    CFURLRef theURL = CFURLCreateWithString(kCFAllocatorDefault, url, NULL);
    
    CFStringRef requestMethod = CFSTR("GET");
    CFHTTPMessageRef theRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, requestMethod, theURL, kCFHTTPVersion1_1);
    
    CFHTTPMessageSetBody(theRequest, bodyData);
    CFHTTPMessageSetHeaderFieldValue(theRequest, headerFieldName, headerFieldValue);
    
    CFReadStreamRef _stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, theRequest);
    
    CFRelease(bodyData);
    CFRelease(theURL);
    CFRelease(theRequest);
    
    CFStreamClientContext theContext={0,self,NULL,NULL,NULL};
    
    CFReadStreamSetClient(_stream,
                          kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered
                          , (CFReadStreamClientCallBack) &callback, &theContext);
    
    CFReadStreamScheduleWithRunLoop(_stream, [rl getCFRunLoop], kCFRunLoopDefaultMode);
    
    _waitingForResponse=TRUE;
    
    CFReadStreamOpen(_stream);
    
    while( ![self isCancelled] &&
          [rl runMode:NSDefaultRunLoopMode
           beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]]);
    
    // When we reach here, we have been cancelled.
    // The close of the stream removes it from the run list.
    CFReadStreamClose(_stream);
    CFRelease(_stream);
    
}
@end

@implementation ORCouchDBChangesfeedOp
-(void) main
{
    if([listeningMode isEqualToString:kContinuousFeed]){
        [self performContinuousFeed];
    }
    else if([listeningMode isEqualToString:kPolling]){
        [self performPolling];
    }
    else{
    [self performContinuousFeed]; // insert default here
    }
}

-(void) setListeningMode:(NSString*)mode {
    listeningMode=mode;
}

-(void) setHeartbeat:(NSUInteger)beat {
    heartbeat=beat;
}

- (void) setFilter:(NSString*)aFilter{
    filter = aFilter;
}

-(void) performContinuousFeed {
    [self _startConnection];
    [self stop];
}

-(BOOL) isWaitingForResponse {
    return _waitingForResponse;
}

- (void) stop {
    [self _clearConnection];
    [self cancel];
}

- (void)streamReceivedResponse:(NSURLResponse *)aResponse {
    _waitingForResponse=FALSE;
    _status = (int) ((NSHTTPURLResponse*)aResponse).statusCode;
    if (_status >= 300) {
        [self stop];
    }
    [self sendToDelegate:[NSString stringWithFormat:@"%@: Got response, status %d", self, _status]];
}

- (void)streamReceivedData:(NSData *)data {
    if ([self isCancelled]){
        [self stop];
        return;
    }
    
    //NSLog(@"%@: Got %lu bytes\n", self, (unsigned long)data.length);
    if (_inputBuffer == nil) {
        _inputBuffer = [[NSMutableData alloc] init];
    }
    [_inputBuffer appendData: data];
    
    // In continuous mode, break input into lines and parse each as JSON:
    const char* start = _inputBuffer.bytes;
    const char* eol;
    NSUInteger totalLengthProcessed = 0;
    NSUInteger bufferLength = _inputBuffer.length;
    // Remove empty lines
    while ((bufferLength - totalLengthProcessed) > 0 && start[0] == '\n') {
        totalLengthProcessed++;
        start++;
    }
    while ((eol = strnstr(start, "\n", bufferLength-totalLengthProcessed)) != nil){
    // Only if we have a complete line
        ptrdiff_t lineLength = eol - start;
        totalLengthProcessed += lineLength + 1;
        if (lineLength > 0) {
            // Only parse lines with > 0 length, others are the heartbeats.
            NSData* chunk = [NSData dataWithBytes:start length:lineLength];
            
            // Parse the line and send to delegate:
            if (chunk) {
                YAJLDocument *document = [[[YAJLDocument alloc] initWithData:chunk parserOptions:YAJLParserOptionsNone error:nil] autorelease];
                [self sendToDelegate:[document root]];
            }
        }
        // Move the pointer
        start += totalLengthProcessed;
    }
    // Remove the processed bytes from the buffer.
    [_inputBuffer replaceBytesInRange: NSMakeRange(0, totalLengthProcessed) withBytes: NULL length: 0];
}

- (void)streamFailedWithError:(NSError *)error {
    NSLog(@"%@: Got error %@\n", self, error);
    [self stop];
}

- (void)streamFinished {
    NSLog(@"%@ connection ended\n", self);
    [self stop];
}

-(void) performPolling {
	if([self isCancelled])return;
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u/%@/_changes", host, port,database]];
    NSArray* query_results;
    NSNumber* last_seq;
    last_seq=(NSNumber*)[result objectForKey:@"last_seq"];
    
    while (![self isCancelled]) {
        id result=[self send:[NSString stringWithFormat:@"http://%@:%u/%@/_changes?since=%@", host, port,database,last_seq]];
        last_seq=(NSNumber*)[result objectForKey:@"last_seq"];
        
        query_results=[result objectForKey:@"results"];
        if ([query_results count]){
            for (id aChange in query_results) {
                [self sendToDelegate:aChange];
                //NSLog(@"change sent to delegate");
            }
        }
        //NSLog(@"poll done, now sleep");
        sleep(10);
    }
    //NSLog(@"feed stopped");
    return;
}
@end

//-----------------------------------------------------------
//ORCouchQueue: A shared queue for couchdb access. You should 
//never have to use this object directly. It will be created
//on demand when a couchDB op is called.
//-----------------------------------------------------------
@implementation ORCouchDBQueue
SYNTHESIZE_SINGLETON_FOR_ORCLASS(CouchDBQueue);
+ (NSOperationQueue*) queue
{
	return [[ORCouchDBQueue sharedCouchDBQueue] queue];
}

+ (void) addOperation:(NSOperation*)anOp
{
	[[ORCouchDBQueue sharedCouchDBQueue] addOperation:anOp];
}
+ (NSUInteger) operationCount
{
	return 	[[ORCouchDBQueue sharedCouchDBQueue] operationCount];
}
+ (void) cancelAllOperations
{
	[[ORCouchDBQueue sharedCouchDBQueue] cancelAllOperations];
}

//don't call this unless you're using this class in a special, non-global way.
- (id) init
{
    self = [super init];
	queue = [[NSOperationQueue alloc] init];
	[queue setMaxConcurrentOperationCount:4];
    return self;
}

- (NSOperationQueue*) queue
{
	return queue;
}

- (void) addOperation:(NSOperation*)anOp
{
	[queue addOperation:anOp];
}

- (void) cancelAllOperations
{
	[queue cancelAllOperations];
}
			 
- (NSInteger) operationCount
{
	return [[queue operations]count];
}
			 
@end