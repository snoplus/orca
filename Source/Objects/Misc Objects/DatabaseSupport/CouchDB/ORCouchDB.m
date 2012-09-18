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

- (void) getDocumentId:(NSString*)anId  tag:(NSString*)aTag
{
	ORCouchDBGetDocumentOp* anOp = [[ORCouchDBGetDocumentOp alloc] initWithHost:host port:port database:database delegate:delegate tag:aTag];
	[anOp setDocumentId:anId];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
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
				NSDictionary* oldViews = [views objectForKey:@"views"];
				NSArray* allViewKeys = [oldViews allKeys];
				for(id aViewKey in allViewKeys){
					
					NSMutableDictionary* newViews = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"javascript",@"language",nil];

					NSMutableDictionary* aOldView = [[[oldViews objectForKey:aViewKey] mutableCopy] autorelease];
					
					NSMutableDictionary* aNewView= [NSMutableDictionary dictionaryWithDictionary:aOldView];
					
					id mapName = [[[aNewView objectForKey:@"mapName"] retain] autorelease];
					if(![mapName length])mapName = database;
					else [aNewView removeObjectForKey:@"mapName"];
					
					NSMutableDictionary* theLowLevelView = [NSMutableDictionary dictionaryWithObjectsAndKeys:aNewView,aViewKey,nil];


					[newViews setObject:theLowLevelView forKey:@"views"];
					
					NSString *httpString = [NSString stringWithFormat:@"http://%@:%u/%@/_design/%@", host, port, database, mapName];
					/*id result = */[self send:httpString type:@"PUT" body:newViews];		
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
		[self sendToDelegate:result];
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