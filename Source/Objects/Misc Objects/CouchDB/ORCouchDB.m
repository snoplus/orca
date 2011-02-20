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
@synthesize database,host,port,queue;

+ (id) couchHost:(NSString*)aHost port:(NSUInteger)aPort database:(NSString*)aDatabase
{
	return [[[ORCouchDB alloc] initWithHost:aHost port:aPort database:aDatabase] autorelease];
}

- (id) initWithHost:(NSString*)aHost port:(NSUInteger)aPort database:(NSString*)aDatabase
{
	self = [super init];
	self.database = aDatabase;
	self.host = aHost;
	self.port = aPort;
	return self;
}

- (void) dealloc
{
	self.host     = nil;
	self.database = nil;
	[super dealloc];
}

- (void) version:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBVersionOp* anOp = [[ORCouchDBVersionOp alloc] initWithHost:host port:port database:nil delegate:aDelegate tag:aTag];
	[[ORCouchDBQueue queue] addOperation:anOp];
	[anOp release];
}

- (void) listDatabases:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBListDBOp* anOp = [[ORCouchDBListDBOp alloc] initWithHost:host port:port database:nil delegate:aDelegate tag:aTag];
	[[ORCouchDBQueue queue] addOperation:anOp];
	[anOp release];
}

- (void) createDatabase:(id)aName delegate:(NSString*)aDelegate tag:(NSString*)aTag
{
	ORCouchDBCreateDBOp* anOp = [[ORCouchDBCreateDBOp alloc] initWithHost:host port:port database:aName delegate:aDelegate tag:aTag];
	[[ORCouchDBQueue queue] addOperation:anOp];
	[anOp release];
}

- (void) deleteDatabase:(NSString*)aName delegate:(id)aDelegate tag:(NSString*)aTag;
{
	ORCouchDBDeleteDBOp* anOp = [[ORCouchDBDeleteDBOp alloc] initWithHost:host port:port database:aName delegate:aDelegate tag:aTag];
	[[ORCouchDBQueue queue] addOperation:anOp];
	[anOp release];
}

- (void) addDocument:(NSDictionary*)aDict documentId:(NSString*)anId database:(NSString*)aName delegate:(id)aDelegate tag:(NSString*)aTag;
{
	ORCouchDBPutDocumentOp* anOp = [[ORCouchDBPutDocumentOp alloc] initWithHost:host port:port database:aName delegate:aDelegate tag:aTag];
	[anOp setDocument:aDict documentID:anId];
	[[ORCouchDBQueue queue] addOperation:anOp];
	[anOp release];
}

- (void) updateDocument:(NSDictionary*)aDict documentId:(NSString*)anId database:(NSString*)aName delegate:(id)aDelegate tag:(NSString*)aTag;
{
	ORCouchDBUpdateDocumentOp* anOp = [[ORCouchDBUpdateDocumentOp alloc] initWithHost:host port:port database:aName delegate:aDelegate tag:aTag];
	[anOp setDocument:aDict documentID:anId];
	[[ORCouchDBQueue queue] addOperation:anOp];
	[anOp release];
}

- (void) getDocumentId:(NSString*)anId database:(NSString*)aName delegate:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBGetDocumentOp* anOp = [[ORCouchDBGetDocumentOp alloc] initWithHost:host port:port database:aName delegate:aDelegate tag:aTag];
	[anOp setDocumentId:anId];
	[[ORCouchDBQueue queue] addOperation:anOp];
	[anOp release];
}

@end

@implementation ORCouchDBOperation
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
	return self;
}

- (void) dealloc
{
	[host release];
	[tag release];
	[database release];
	[delegate release];
	[super dealloc];
}

- (void) send:(NSURL*)url type:(NSString*)type
{
	NSError *error;
	NSHTTPURLResponse *response;
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    if(type)[request setHTTPMethod:type];
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

	if (data) {
		YAJLDocument *document = [[[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:nil] autorelease];
		if([delegate respondsToSelector:@selector(couchDBResult:tag:)]){
			[delegate couchDBResult:[document root] tag:tag];
		}
	}
}
- (BOOL) responseCodeOK:(int)aCode
{
	return (aCode <= 202);
}

@end

@implementation ORCouchDBVersionOp
- (void) main
{
    NSString *server = [NSString stringWithFormat:@"http://%@:%u", host, port];
	[self send:[NSURL URLWithString:server] type:nil];
}

@end

@implementation ORCouchDBCreateDBOp
-(void) main
{
	NSError *error;
	NSHTTPURLResponse *response;
	//first get the list of existing databases
	NSString *server = [NSString stringWithFormat:@"http://%@:%u/_all_dbs", host, port];
    NSURL *url = [NSURL URLWithString:server];   
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if([self responseCodeOK:[response statusCode]]){
		if (data) {
			YAJLDocument *document = [[[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:nil] autorelease];
			if(![[document root] containsObject:database]){
				NSString *escaped = [database stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				NSString *server = [NSString stringWithFormat:@"http://%@:%u/%@", host, port, escaped];
				[self send:[NSURL URLWithString:server] type:@"PUT"];
			}
			else {
				NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@ already exists",database],@"Message",nil];
				[delegate couchDBResult:dict tag:@"Message"];	
			}
		}
	}
	else {
		NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[response statusCode]],@"Error",nil];
		[delegate couchDBResult:dict tag:@"Message"];	
	}
}
		
@end

@implementation ORCouchDBDeleteDBOp
-(void) main
{
	NSError *error;
	NSHTTPURLResponse *response;
	//first get the list of existing databases
	NSString *server = [NSString stringWithFormat:@"http://%@:%u/_all_dbs", host, port];
    NSURL *url = [NSURL URLWithString:server];   
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if (data) {
		YAJLDocument *document = [[[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:nil] autorelease];
		if([[document root] containsObject:database]){
			NSString *escaped = [database stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSString *server = [NSString stringWithFormat:@"http://%@:%u/%@", host, port, escaped];
			[self send:[NSURL URLWithString:server] type:@"DELETE"];
		}
	}
}
@end


@implementation ORCouchDBListDBOp
-(void) main
{
	NSString *server = [NSString stringWithFormat:@"http://%@:%u/_all_dbs", host, port];
    NSURL *url = [NSURL URLWithString:server];   
	[self send:url type:nil];
}
@end

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
	NSString *urlString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, documentId];
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];        
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];    
    [request setHTTPBody:[[document yajl_JSONString] dataUsingEncoding:NSASCIIStringEncoding]];
    [request setHTTPMethod:@"PUT"];
    
    NSHTTPURLResponse *response;
    /*NSData* data = */[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
	if(![self responseCodeOK:[response statusCode]]){
    }
}
@end

@implementation ORCouchDBUpdateDocumentOp
- (void) main
{
	NSError *error;
	NSHTTPURLResponse *response;
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, documentId];
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];        
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if (data) {
		YAJLDocument *returnedDoc = [[[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:nil] autorelease];
		NSDictionary* asDict = [returnedDoc root];
		if([asDict objectForKey:@"error"]){
			//document doesn't exist. So just add it.
			NSString *urlString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, documentId];
			NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];        
			
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];    
			[request setHTTPBody:[[document yajl_JSONString] dataUsingEncoding:NSASCIIStringEncoding]];
			[request setHTTPMethod:@"PUT"];
			
			NSHTTPURLResponse *response;
			/*NSData* data = */[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
			if(![self responseCodeOK:[response statusCode]]){
			}
		}
		else {
			//it exists. Include the rev number into it and PUT it back
			id rev = [asDict objectForKey:@"_rev"];
			NSString *urlString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, documentId];
			NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];        
			
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url]; 
			NSMutableDictionary* newDocument = [NSMutableDictionary dictionaryWithDictionary:document];
			
			[newDocument setObject:rev forKey:@"_rev"];
			[document release];
			document   = [newDocument retain];

			[request setHTTPBody:[[document yajl_JSONString] dataUsingEncoding:NSASCIIStringEncoding]];
			[request setHTTPMethod:@"PUT"];
			
			NSHTTPURLResponse *response;
			/*NSData* data = */ [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
			if(![self responseCodeOK:[response statusCode]]){
			}
		}
	}
}
@end


@implementation ORCouchDBGetDocumentOp
- (void) dealloc 
{
	[documentId release];
	[revision release];
	[super dealloc];
}

- (void) setDocumentId:(NSString*)anID withRevisionCount:(BOOL)withCount andInfo:(BOOL)andInfo
{
	[self setDocumentId:anID withRevisionCount:withCount andInfo:andInfo revision:nil];
}
- (void) setDocumentId:(NSString*)anID withRevisionCount:(BOOL)withCount
{
	[self setDocumentId:anID withRevisionCount:withCount andInfo:NO revision:nil];
}
- (void) setDocumentId:(NSString*)anID
{
	[self setDocumentId:anID withRevisionCount:NO andInfo:NO revision:nil];
}

- (void) setDocumentId:(NSString*)anID withRevisionCount:(BOOL)withCount andInfo:(BOOL)andInfo revision:(NSString*)revisionOrNil
{
	documentId = [anID copy];
	getRevisionCount = withCount;
	getInfo	= andInfo;
	revision = [revisionOrNil copy];
}

- (void) main
{
    NSString *args;
    if(getInfo)		  args = [NSString stringWithFormat:@"%@?revs=true&revs_info=true", documentId];
	else			  args = [NSString stringWithFormat:@"%@", documentId];
    if(revision)	  args = [NSString stringWithFormat:@"%@&rev=%@",args,revision];
	
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%u/%@/%@", host, port, database, args];
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];        
	[self send:url type:nil];	
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
//don't call this unless you're using this class in a special, non-global way.
- (id) init
{
    self = [super init];
	queue = [[NSOperationQueue alloc] init];
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