//
//  ORPQModel.m
//  Orca
//
//  Created by Mark Howe on 10/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
//
//  Abritrary database accesses may be made via this object by defining
//  a callback function in the calling object like this:
//
//    - (void) callbackProc:(ORPQResult*)theResult
//    {
//        // do stuff here
//    }
//
//  then calling dbQuery like this:
//
//    if ([ORPQModel getCurrent]) {
//        [[ORPQModel getCurrent] dbQuery:@"<query string>" object:self selector:@selector(callbackProc:)];
//    }
//
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
//

#import "ORPQModel.h"
#import "ORPQConnection.h"
#import "ORPQResult.h"
#import "ORAlarmController.h"

const int kPQAlarm_OrcaAlarmActive = 85001;
const int kOrcaAlarmMin = 80000;
const int kOrcaAlarmMax = 89999;

NSString* ORPQModelStealthModeChanged = @"ORPQModelStealthModeChanged";
NSString* ORPQDataBaseNameChanged	= @"ORPQDataBaseNameChanged";
NSString* ORPQPasswordChanged		= @"ORPQPasswordChanged";
NSString* ORPQUserNameChanged		= @"ORPQUserNameChanged";
NSString* ORPQHostNameChanged		= @"ORPQHostNameChanged";
NSString* ORPQConnectionValidChanged	= @"ORPQConnectionValidChanged";
NSString* ORPQLock					= @"ORPQLock";

static ORPQModel *currentORPQModel = nil;

static NSString* ORPQModelInConnector 	= @"ORPQModelInConnector";

@interface ORPQModel (private)
- (ORPQConnection*) pqConnection;
- (void) alarmPosted:(NSNotification*)aNote;
- (void) alarmCleared:(NSNotification*)aNote;
@end

@implementation ORPQModel

+ (ORPQModel*)getCurrent
{
    return currentORPQModel;
}

#pragma mark ***Initialization
- (id) init
{
	self=[super init];
    currentORPQModel = self;
    return self;
}
- (void) dealloc
{
    if (currentORPQModel == self) currentORPQModel = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [dataBaseName release];
    [password release];
    [userName release];
    [hostName release];
	[super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
		[self registerNotificationObservers];
    }
    [super wakeUp];
}


- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[ORPQDBQueue queue]cancelAllOperations];
	[[ORPQDBQueue queue] waitUntilAllOperationsAreFinished];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super sleep];
}

- (void) awakeAfterDocumentLoaded
{
    /// stub
}
- (BOOL) solitaryObject
{
    return YES;
}
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"PostgreSQL"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORPQController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORPQModelInConnector];
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
                       object : (ORAppDelegate*)[NSApp delegate]];
	
    [notifyCenter addObserver : self
                     selector : @selector(alarmPosted:)
                         name : ORAlarmWasPostedNotification
                       object : nil];	
	
    [notifyCenter addObserver : self
                     selector : @selector(alarmCleared:)
                         name : ORAlarmWasClearedNotification
                       object : nil];	

}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
}


#pragma mark ***Accessors

- (id) nextObject
{
	return [self objectConnectedTo:ORPQModelInConnector];
}

- (void)dbQuery:(NSString*)aCommand object:(id)anObject selector:(SEL)aSelector timeout:(float)aTimeoutSecs
{
    if(stealthMode){
        [anObject performSelector:aSelector withObject:nil afterDelay:0.1];
    } else {
        ORPQQueryOp* anOp = [[ORPQQueryOp alloc] initWithDelegate:self object:anObject selector:aSelector];
        if (aTimeoutSecs) {
            [anOp performSelector:@selector(cancel) withObject:nil afterDelay:aTimeoutSecs];
        }
        [anOp setCommand:aCommand];
        [ORPQDBQueue addOperation:anOp];
        [anOp release];
    }
}

- (void)dbQuery:(NSString*)aCommand object:(id)anObject selector:(SEL)aSelector
{
    [self dbQuery:aCommand object:anObject selector:aSelector timeout:0];
}

- (void)dbQuery:(NSString*)aCommand
{
    [self dbQuery:aCommand object:nil selector:nil timeout:0];
}

- (void)pmtdbQuery:(NSString*)aPmtdbField object:(id)anObject selector:(SEL)aSelector
{
    if(stealthMode){
        [anObject performSelector:aSelector withObject:nil afterDelay:0.1];
    } else {
        ORPQQueryOp* anOp = [[ORPQQueryOp alloc] initWithDelegate:self object:anObject selector:aSelector];
        [anOp setPmtdbFieldName:aPmtdbField];
        [ORPQDBQueue addOperation:anOp];
        [anOp release];
    }
}

// cancel all dbQuery and pmtdbQuery operations
- (void) cancelDbQueries
{
    for (NSOperation *op in [[ORPQDBQueue queue] operations]) {
        if ([op isKindOfClass:[ORPQQueryOp class]]) {
            [op cancel];
        }
    }
}


- (BOOL) stealthMode
{
    return stealthMode;
}

- (void) setStealthMode:(BOOL)aStealthMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStealthMode:stealthMode];
    stealthMode = aStealthMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPQModelStealthModeChanged object:self];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORPQDataBaseNameChanged object:self];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORPQPasswordChanged object:self];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORPQUserNameChanged object:self];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORPQHostNameChanged object:self];
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
    currentORPQModel = self;
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:stealthMode forKey:@"stealthMode"];
    [encoder encodeObject:dataBaseName forKey:@"DataBaseName"];
    [encoder encodeObject:password forKey:@"Password"];
    [encoder encodeObject:userName forKey:@"UserName"];
    [encoder encodeObject:hostName forKey:@"HostName"];
}

#pragma mark ***SQL Access
- (BOOL) testConnection
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	if(!pqConnection) pqConnection = [[ORPQConnection alloc] init];
	if([pqConnection isConnected]){
		[pqConnection disconnect];
	} 
	
	if([pqConnection connectToHost:hostName userName:userName passWord:password dataBase:dataBaseName]){
	}
	else {
		[self disconnectSql];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPQConnectionValidChanged object:self];
	

	return [pqConnection isConnected];
}

- (void) disconnectSql
{
	if(pqConnection){
		[pqConnection disconnect];
		[pqConnection release];
		pqConnection = nil;
		if([dataBaseName length] && [hostName length])NSLog(@"Disconnected from DataBase %@ on %@\n",dataBaseName,hostName);
		[[NSNotificationCenter defaultCenter] postNotificationName:ORPQConnectionValidChanged object:self];
	}
}

- (BOOL) connected
{
	return [pqConnection isConnected];
}


- (void) logQueryException:(NSException*)e
{
	NSLogError([e reason],@"SQL",@"Query Problem",nil);
	[pqConnection release];
	pqConnection = nil;
}

@end

@implementation ORPQModel (private)

- (ORPQConnection*) pqConnection
{
	@synchronized(self){
		BOOL oldConnectionValid = [pqConnection isConnected];
		BOOL newConnectionValid = oldConnectionValid;
		if(!pqConnection) pqConnection = [[ORPQConnection alloc] init];
		if(![pqConnection isConnected]){
			newConnectionValid = [pqConnection connectToHost:hostName userName:userName passWord:password dataBase:dataBaseName verbose:NO];
		}
	
		if(newConnectionValid != oldConnectionValid){
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORPQConnectionValidChanged object:self];
		}
	}
	return [pqConnection isConnected]?pqConnection:nil;
}


- (void) alarmPosted:(NSNotification*)aNote
{
	if(!stealthMode){
		ORPQPostAlarmOp* anOp = [[ORPQPostAlarmOp alloc] initWithDelegate:self];
		[anOp postAlarm:[aNote object]];
		[ORPQDBQueue addOperation:anOp];
		[anOp release];
	}
}

- (void) alarmCleared:(NSNotification*)aNote
{
	if(!stealthMode){
		ORPQPostAlarmOp* anOp = [[ORPQPostAlarmOp alloc] initWithDelegate:self];
		[anOp clearAlarm:[aNote object]];
		[ORPQDBQueue addOperation:anOp];
		[anOp release];
	}
}
@end

@implementation ORRunState
@end

@implementation ORPQOperation
- (id) initWithDelegate:(id)aDelegate
{
    return [self initWithDelegate:aDelegate object:nil selector:nil];
}

- (id) initWithDelegate:(id)aDelegate object:(id)anObject selector:(SEL)aSelector
{
	self = [super init];
	delegate = aDelegate;
    object = anObject;
    selector = aSelector;
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

@end

@implementation ORPQQueryOp
- (void) dealloc
{
    [command release];
    [super dealloc];
}

- (void) setCommand:(NSString*)aCommand;
{
    [command autorelease];
    command = [aCommand copy];
}

- (void) setCommandType:(int)aCommandType;
{
    commandType = aCommandType;
}

- (void) setPmtdbFieldName:(NSString*)aFieldName;
{
    commandType = kPQCommandType_GetPMT;
    command = [[NSString stringWithFormat: @"SELECT crate,card,channel,%@ FROM pmtdb", aFieldName] retain];
}

- (void) cancel
{
    [super cancel];
    if (selector) {
        // do callback with nil object
        [object performSelectorOnMainThread:selector withObject:nil waitUntilDone:YES];
        selector = nil;
    }
}

- (void) main
{
    if([self isCancelled]) return;

    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
    NSObject *theResultObject = nil;
    @try {
        ORPQConnection* pqConnection = [[delegate pqConnection] retain];
        if([pqConnection isConnected] && ![self isCancelled]){
            ORPQResult *theResult = [pqConnection queryString:command];

            if (theResult && ![self isCancelled]) {
                switch (commandType) {
                    case kPQCommandType_General:
                        theResultObject = theResult;
                        break;
                    case kPQCommandType_GetPMT: {
                        int numRows = [theResult numOfRows];
                        int numCols = [theResult numOfFields];
                        if (numCols == 4) {
                            NSMutableData *data = [[[NSMutableData alloc] initWithCapacity:(kSnoChannels * sizeof(int32_t))] autorelease];
                            int32_t *pt = [data mutableBytes];
                            memset(pt, 0xff, (kSnoChannels * sizeof(int32_t)));
                            for (int i=0; i<numRows; ++i) {
                                int crate = [theResult getInt32atRow:i column:0];
                                int card = [theResult getInt32atRow:i column:1];
                                int channel = [theResult getInt32atRow:i column:2];
                                if (crate < kSnoCrates && card < kSnoCardsPerCrate && channel < kSnoChannelsPerCard) {
                                    int n = (crate * kSnoCardsPerCrate + card) * kSnoChannelsPerCard + channel;
                                    pt[n] = [theResult getInt32atRow:i column:3];
                                }
                                theResultObject = data;
                            }
                        }
                    } break;
                }
            }
        }
        [pqConnection release];
    }
    @catch(NSException* e){
        if (![self isCancelled]) {
            [delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
        }
    }
    @finally {
        // do callback on main thread if a selector was specified
        if (selector && ![self isCancelled]) {
            [object performSelectorOnMainThread:selector withObject:theResultObject waitUntilDone:YES];
            selector = nil;
        }
        [thePool release];
    }
}
@end

@implementation ORPQPostAlarmOp
- (void) dealloc
{
	[alarm release];
	[super dealloc];
}

- (void) postAlarm:(id)anAlarm
{
	[anAlarm retain];
	[alarm release];
	alarm = anAlarm;
	opType = kPost;
}

- (void) clearAlarm:(id)anAlarm
{
	[anAlarm retain];
	[alarm release];
	alarm = anAlarm;
	opType = kClear;
}

// extract alarm number from hex alarm id embedded inside alarm name
// (must be called from inside an auto release pool to handle memory allocated by cStringUsingEncoding)
static int getAlarmNumber(id alarm)
{
    int alarmNum = 0;
    const char *name = [[alarm name] cStringUsingEncoding:NSUTF8StringEncoding];
    // look for alarm number inside brackets in alarm name
    const char *pt = strstr(name, "(");
    if (pt) {
        while (*(++pt)) {
            if ((*pt >= '0') && (*pt <= '9')) {
                alarmNum = (alarmNum * 10) + (*pt - '0');
            } else {
                break;
            }
        }
        if ((*pt != ')') || (alarmNum < kOrcaAlarmMin) || (alarmNum > kOrcaAlarmMax)) alarmNum = 0;
    }
    return alarmNum;
}

- (void) main
{
    if([self isCancelled])return;
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	@try {
        int alarmNum = getAlarmNumber(alarm);
        if (!alarmNum) {
            // this is a regular ORCA alarm, so just count the number of regular alarms posted
            NSEnumerator* e = [[ORAlarmCollection sharedAlarmCollection] alarmEnumerator];
            id anAlarm;
            int numRegularOrcaAlarms = 0;
            while (anAlarm = [e nextObject]){
                if (getAlarmNumber(anAlarm) > 0) ++numRegularOrcaAlarms;
            }
            // so post/clear a generic ORCA alarm if necessary
            if ((numRegularOrcaAlarms && opType == kPost) || (!numRegularOrcaAlarms && opType == kClear)) {
                alarmNum = kPQAlarm_OrcaAlarmActive;
            }
        }
        if (alarmNum) {
            char *type = (opType==kPost) ? "post" : "clear";
            ORPQConnection* pqConnection = [[delegate pqConnection] retain];
            if([pqConnection isConnected]){
                // post or clear the alarm
                [pqConnection queryString:[NSString stringWithFormat:@"SELECT * FROM %s_alarm(%d)",type,kPQAlarm_OrcaAlarmActive]];
                [pqConnection release];
            }
        }
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
    @finally {
        [thePool release];
    }
}
@end

