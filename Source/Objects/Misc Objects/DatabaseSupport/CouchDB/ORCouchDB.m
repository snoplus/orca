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

- (void) createDatabase:(NSString*)aTag
{
	ORCouchDBCreateDBOp* anOp = [[ORCouchDBCreateDBOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setUsername:username];
	[anOp setPwd:pwd];
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

- (void) getDocumentId:(NSString*)anId  tag:(NSString*)aTag
{
	ORCouchDBGetDocumentOp* anOp = [[ORCouchDBGetDocumentOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setDocumentId:anId];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
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
    if(aType)[request setHTTPMethod:aType];
	if(aBody)[request setHTTPBody:[[aBody yajl_JSONString] dataUsingEncoding:NSASCIIStringEncoding]];
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
	
	if (data) {
		YAJLDocument *document = [[[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:nil] autorelease];
		return [document root];
	}
	else return nil;
}

- (void) sendToDelegate:(id)obj
{
	if(obj && [delegate respondsToSelector:@selector(couchDBResult:tag:)]){
		[delegate couchDBResult:obj tag:tag];
	}
}	

@end


#pragma mark •••Database API


@implementation ORCouchDBCompactDBOp
-(void) main
{	
	NSString* httpString = [NSString stringWithFormat:@"http://%@:%u/%@/_compact", host, port,database];
	if(username && pwd){
		httpString = [httpString stringByReplacingOccurrencesOfString:@"://" withString:[NSString stringWithFormat:@"://%@:%@@",username,pwd]];
	}
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:httpString]];
	[request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"]];
	[request setHTTPMethod:@"POST"];
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
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
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u/_all_dbs", host, port]];
	[self sendToDelegate:result];
}
@end

@implementation ORCouchDBVersionOp
- (void) main
{
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u", host, port]];
	[self sendToDelegate:result];
}

@end

@implementation ORCouchDBInfoDBOp
-(void) main
{
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u/%@/", host, port,database]];
	[self sendToDelegate:result];
}
@end

@implementation ORCouchDBCreateDBOp
-(void) main
{
	NSString *escaped = [database stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u/_all_dbs", host, port]];
	if(![result containsObject:database]){
		[self send:[NSString stringWithFormat:@"http://%@:%u/%@", host, port, escaped] type:@"PUT"];
		if([response statusCode] == 201) result = [NSDictionary dictionaryWithObjectsAndKeys:
												   [NSString stringWithFormat:@"[%@] created",
													database],@"Message",nil];
		else							 result = [NSDictionary dictionaryWithObjectsAndKeys:
												   [NSString stringWithFormat:@"[%@] creation FAILED",database],
												   @"Message",
												   [NSString stringWithFormat:@"Error Code: %d",[response statusCode]],
												   @"Reason",
												   nil];
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
	
	NSString *escaped = [database stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	id result = [self send:[NSString stringWithFormat:@"http://%@:%u/_all_dbs", host, port]];
	if([result containsObject:database]){
		result = [self send:[NSString stringWithFormat:@"http://%@:%u/%@", host, port, escaped] type:@"DELETE"];
		if([response statusCode] == 200) result = [NSDictionary dictionaryWithObjectsAndKeys:
												   [NSString stringWithFormat:@"[%@] deleted",
													database],@"Message",nil];
		else							 result = [NSDictionary dictionaryWithObjectsAndKeys:
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


#pragma mark •••Document API
@implementation ORCouchDBPutDocumentOp
- (void) dealloc 
{
	[document release];
	[documentId release];
	[super dealloc];
}

- (void) setDocument:(NSDictionary*)aDocument documentID:(NSString*)anID
{
	document   = [aDocument retain];
	documentId = [anID copy];
}

- (void) main
{
	NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, documentId];
	id result = [self send:httpString type:@"PUT" body:document];
	[self sendToDelegate:result];
}

@end

@implementation ORCouchDBUpdateDocumentOp
- (void) main
{
	//check for an existing document
	NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, documentId];
	id result = [self send:httpString];
	if([result objectForKey:@"error"]){
		//document doesn't exist. So just add it.
		result = [self send:httpString type:@"PUT" body:document];
	}
	else {
		//it already exists. insert the rev number into the document and put it back
		id rev = [result objectForKey:@"_rev"];
		if(rev){
			NSMutableDictionary* newDocument = [NSMutableDictionary dictionaryWithDictionary:document];
			[newDocument setObject:rev forKey:@"_rev"];
			[self send:httpString type:@"PUT" body:newDocument];
		}
	}
}
@end

@implementation ORCouchDBDeleteDocumentOp
- (void) main
{
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
	documentId = [anID copy];
}

- (void) main
{
	NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, documentId];
	id result = [self send:httpString];
	[self sendToDelegate:result];
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
	return [[ORCouchDBQueue sharedCouchDBQueue] addOperation:anOp];
}

//don't call this unless you're using this class in a special, non-global way.
- (id) init
{
    self = [super init];
	queue = [[NSOperationQueue alloc] init];
	[queue setMaxConcurrentOperationCount:1];
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
@end