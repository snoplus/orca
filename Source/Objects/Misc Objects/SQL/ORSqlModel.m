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

NSString* ORSqlModelWebSitePathChanged	= @"ORSqlModelWebSitePathChanged";
NSString* ORSqlDataBaseNameChanged		= @"ORSqlDataBaseNameChanged";
NSString* ORSqlPasswordChanged			= @"ORSqlPasswordChanged";
NSString* ORSqlUserNameChanged			= @"ORSqlUserNameChanged";
NSString* ORSqlHostNameChanged			= @"ORSqlHostNameChanged";
NSString* ORDBConnectionVerifiedChanged	= @"ORDBConnectionVerifiedChanged";
NSString* ORSqlLock						= @"ORSqlLock";

static NSString* ORSqlModelInConnector 	= @"ORSqlModelInConnector";
@interface ORSqlModel (private)
- (NSString*) dbPartOfPost;
- (void) submitPost:(NSString*)postString to:(NSString*)aPHPScript;
- (void) postMachineName;
- (void) postRunState:(int)aRunState runNumber:(int)runNumber subRunNumber:(int)subRunNumber;
- (NSString *)urlEncodeValue:(NSString *)str;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)response;
- (void) updateDataSets;
@end

@implementation ORSqlModel

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
	[webSitePath release];
	[dataMonitors release];
    [dataBaseName release];
    [password release];
    [userName release];
    [hostName release];
	[responseData release];
	[super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	[self setConnected:YES];
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
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
}

- (void) runStatusChanged:(NSNotification*)aNote
{
	id pausedKeyIncluded = [[aNote userInfo] objectForKey:@"ORRunPaused"];
	if(!pausedKeyIncluded){
		int runState = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
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
}


#pragma mark ***Accessors

- (NSString*) webSitePath
{
    return webSitePath;
}

- (void) setWebSitePath:(NSString*)aWebSitePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWebSitePath:webSitePath];
    
    [webSitePath autorelease];
    webSitePath = [aWebSitePath copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSqlModelWebSitePathChanged object:self];
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
    [self setWebSitePath:[decoder decodeObjectForKey:@"webSitePath"]];
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
    [encoder encodeObject:webSitePath forKey:@"webSitePath"];
    [encoder encodeObject:dataBaseName forKey:@"DataBaseName"];
    [encoder encodeObject:password forKey:@"Password"];
    [encoder encodeObject:userName forKey:@"UserName"];
    [encoder encodeObject:hostName forKey:@"HostName"];
}

- (BOOL) dbConnectionVerified
{
	return dbConnectionVerified;
}

- (void) setConnected:(BOOL) aState
{
	dbConnectionVerified = aState;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORDBConnectionVerifiedChanged object:self];	
}

-(void) apply
{
	[self setConnected:YES];
	[self postMachineName];

}

@end

@implementation ORSqlModel (private)
- (void) postMachineName
{
	NSString* name = computerName();
	
	NSString *postString = [NSString stringWithFormat:@"%@&name=%@",
					  [self dbPartOfPost],
					  [self urlEncodeValue:name]];
	[self submitPost:postString to:@"addMachineInfo.php"];
}

- (void) postRunState:(int)aRunState runNumber:(int)runNumber subRunNumber:(int)subRunNumber
{
	NSString *postString = [NSString stringWithFormat:@"%@&runNumber=%d&subRunNumber=%d&runState=%d",
					  [self dbPartOfPost],
					  runNumber,
					  subRunNumber,
					  aRunState];
	[self submitPost:postString to:@"setRunState.php"];
}

- (void) submitPost:(NSString*)postString to:(NSString*)aPHPScript
{
	NSData *postData = [postString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	NSString* phpScriptName = [NSString stringWithFormat:@"http://%@/%@/%@",hostName,webSitePath,aPHPScript];
	[request setURL:[NSURL URLWithString:phpScriptName]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:postData];
	
	NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (!urlConnection) {
		NSLog(@"Failed to submit request");
	} 
}

- (NSString*) dbPartOfPost
{
	NSString* hw_address = macAddress();
	return [NSString stringWithFormat:@"hostName=%@&dataBase=%@&userName=%@&pw=%@&hwaddress=%@",
			[self urlEncodeValue:hostName],
			[self urlEncodeValue:dataBaseName],
			[self urlEncodeValue:userName],
			[self urlEncodeValue:password],
			[self urlEncodeValue:hw_address]];
}

- (NSString*) urlEncodeValue:(NSString *)str
{
	NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, CFSTR("?=&+"), kCFStringEncodingUTF8);
	return [result autorelease];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)response 
{
	if(!responseData){
		responseData = [[NSMutableData alloc] init];
	}
	[responseData setLength:0];
	[responseData appendData:response];
	NSString* resultString = [[[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding] autorelease];
	if([resultString rangeOfString:@"Connection Failed"].location != NSNotFound){
		[self setConnected:NO];
	}
}

- (void) connection:(NSURLConnection *)connection didFinishLoading:(NSData *)response 
{
	[connection release];
}

- (void) updateDataSets
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDataSets) object:nil];
	for(id aDataMonitor in dataMonitors) {
		NSArray* dataSets = [aDataMonitor collectObjectsOfClass:NSClassFromString(@"OR1DHisto")];
		for(ORDataSet* aSet in dataSets){
			NSString *postString = [NSString stringWithFormat:@"%@&monitor_id=%d&name=%@&counts=%d",
									[self dbPartOfPost],
									[aDataMonitor uniqueIdNumber],
									[aSet fullName],
									[aSet totalCounts]];
			[self submitPost:postString to:@"updateDataSet.php"];
		}
	}
	[self performSelector:@selector(updateDataSets) withObject:self afterDelay:10];
}
@end
