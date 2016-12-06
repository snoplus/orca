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
NSString* ORPQConnectionValidChanged = @"ORPQConnectionValidChanged";
NSString* ORPQDetectorStateChanged  = @"ORPQDetectorStateChanged";
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

- (void)detectorDbQuery:(id)anObject selector:(SEL)aSelector
{
    if(stealthMode){
        [anObject performSelector:aSelector withObject:nil afterDelay:0.1];
    } else {
        ORPQQueryOp* anOp = [[ORPQQueryOp alloc] initWithDelegate:self object:anObject selector:aSelector];
        [anOp setCommandType:kPQCommandType_GetDetectorDB];
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

@implementation ORPQDetectorDB

- (id) init
{
    self = [super init];
    data = [[[NSMutableData alloc] initWithLength:(kSnoCardsTotal * sizeof(PQ_FEC) + sizeof(PQ_MTC) + sizeof(PQ_CAEN))] retain];
    return self;
}

- (void) dealloc
{
    [data release];
    pmthvLoaded = fecLoaded = mtcLoaded = caenLoaded = NO;
    [super dealloc];
}

- (PQ_FEC *) getFEC:(int)aCard crate:(int)aCrate
{
    if (!fecLoaded || aCrate >= kSnoCrates || aCard >= kSnoCardsPerCrate) return nil;
    return (PQ_FEC *)[data mutableBytes] + aCrate * kSnoCardsPerCrate + aCard;
}

- (PQ_MTC *) getMTC
{
    if (!mtcLoaded) return nil;
    return (PQ_MTC *)((PQ_FEC *)[data mutableBytes] + kSnoCardsTotal);
}

- (PQ_CAEN *) getCAEN
{
    if (!caenLoaded) return nil;
    return (PQ_CAEN *)((PQ_MTC *)((PQ_FEC *)[data mutableBytes] + kSnoCardsTotal) + 1);
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

- (void) _detectorDbCallback:(ORPQDetectorDB *)detDB
{
    // inform everyone that our detector state has changed
    if (detDB) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ORPQDetectorStateChanged object:detDB];
    }
    // finally do our callback
    if (![self isCancelled] && selector) {
        [object performSelectorOnMainThread:selector withObject:detDB waitUntilDone:YES];
        selector = nil;
    }
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

// load and parse the full detector database from the PostgreSQL server
- (ORPQDetectorDB *) loadDetectorDB: (ORPQConnection *)pqConnection
{
    int i;

    /**** load PMT HV database ****/
    [command autorelease];
    // column:    0     1    2       3
    char *cols = "crate,card,channel,pmthv";
    command = [[NSString stringWithFormat: @"SELECT %s FROM pmtdb",cols] retain];
    ORPQResult *theResult = [pqConnection queryString:command];
    if ([self isCancelled]) return nil;
    ORPQDetectorDB *detDB = [[[ORPQDetectorDB alloc] init] autorelease];
    if (theResult) {
        int numRows = [theResult numOfRows];
        int numCols = [theResult numOfFields];
        if (numCols != 4) {
            NSLog(@"Expected %d columns from PMT HV database, but got %d\n", 4, numCols);
            return nil;
        }
        for (i=0; i<numRows; ++i) {
            int64_t val = [theResult getInt64atRow:i column:3];
            if (val == kPQBadValue) continue;
            unsigned crate   = [theResult getInt64atRow:i column:0];
            unsigned card    = [theResult getInt64atRow:i column:1];
            unsigned channel = [theResult getInt64atRow:i column:2];
            if (crate < kSnoCrates && card < kSnoCardsPerCrate && channel < kSnoChannelsPerCard) {
                PQ_FEC *theCard = [detDB getFEC:card crate:crate];
                theCard->valid[kFEC_hvDisabled] |= (1 << channel);
                if (val == 1) theCard->hvDisabled |= (1 << channel);
            }
        }
        if (numRows) {
            detDB->pmthvLoaded = YES;
        }
    }
    if ([self isCancelled]) return nil;

    /**** load FEC database ****/
    [command autorelease];
    // (funny, but tcmos_tacshift=tac0trim and scmos=tac1trim)
    //      0     1    2          3           4         5          6          7      8      9              10    11   12            13           14          15        16        17        18         19           20          21          22   23
    cols = "crate,slot,tr100_mask,tr100_delay,tr20_mask,tr20_width,tr20_delay,vbal_0,vbal_1,tcmos_tacshift,scmos,vthr,pedestal_mask,disable_mask,tdisc_rmpup,tdisc_rmp,tdisc_vsi,tdisc_vli,tcmos_vmax,tcmos_tacref,tcmos_isetm,tcmos_iseta,vint,hvref";
    command = [[NSString stringWithFormat: @"SELECT %s FROM current_detector_state",cols] retain];
    theResult = [pqConnection queryString:command];
    if ([self isCancelled]) return nil;
    if (theResult) {
        int numRows = [theResult numOfRows];
        int numCols = [theResult numOfFields];
        if (numCols != kFEC_numDbColumns) {
            NSLog(@"Expected %d columns from detector database, but got %d\n", kFEC_numDbColumns, numCols);
            return nil;
        }
        for (i=0; i<numRows; ++i) {
            unsigned crate = [theResult getInt64atRow:i column:0];
            unsigned card  = [theResult getInt64atRow:i column:1];
            if (crate >= kSnoCrates || card >= kSnoCardsPerCrate) continue;
            PQ_FEC *theCard = [detDB getFEC:card crate:crate];
            // set flag indicating that the card exists in the current detector state
            theCard->valid[kFEC_exists] = 1;
            for (int col=2; col<kFEC_numDbColumns; ++col) {
                NSMutableData *dat = [theResult getInt64arrayAtRow:i column:col];
                if (!dat) continue;
                int n = [dat length] / sizeof(int64_t);
                if (n > kSnoChannelsPerCard) n = kSnoChannelsPerCard;
                int64_t *valPt = (int64_t *)[dat mutableBytes];
                for (int ch=0; ch<n; ++ch) {
                    // ignore bad values (includes NULL values)
                    if (valPt[ch] == kPQBadValue) continue;
                    int32_t val = (int32_t)valPt[ch];
                    // set valid flag for this setting for this channel
                    theCard->valid[col] |= (1 << ch);
                    switch (col) {
                        case kFEC_nhit100enabled:
                            if (val) theCard->nhit100enabled |= (1 << ch);
                            break;
                        case kFEC_nhit100delay:
                            theCard->nhit100delay[ch] = val;
                            break;
                        case kFEC_nhit20enabled:
                            if (val) theCard->nhit20enabled |= (1 << ch);
                            break;
                        case kFEC_nhit20width:
                            theCard->nhit20width[ch] = val;
                            break;
                        case kFEC_nhit20delay:
                            theCard->nhit20delay[ch] = val;
                            break;
                        case kFEC_vbal0:
                            theCard->vbal0[ch] = val;
                            break;
                        case kFEC_vbal1:
                            theCard->vbal1[ch] = val;
                            break;
                        case kFEC_tac0trim:
                            theCard->tac0trim[ch] = val;
                            break;
                        case kFEC_tac1trim:
                            theCard->tac1trim[ch] = val;
                            break;
                        case kFEC_vthr:
                            theCard->vthr[ch] = val;
                            break;
                        case kFEC_pedEnabled:
                            theCard->pedEnabled = val;
                            theCard->valid[col] = 0xffffffff;
                            break;
                        case kFEC_seqDisabled:
                            theCard->seqDisabled = val;
                            theCard->valid[col] = 0xffffffff;
                            break;
                        case kFEC_tdiscRp1:
                            if (ch < 8) theCard->tdiscRp1[ch] = val;
                            break;
                        case kFEC_tdiscRp2:
                            if (ch < 8) theCard->tdiscRp2[ch] = val;
                            break;
                        case kFEC_tdiscVsi:
                            if (ch < 8) theCard->tdiscVsi[ch] = val;
                            break;
                        case kFEC_tdiscVli:
                            if (ch < 8) theCard->tdiscVli[ch] = val;
                            break;
                        case kFEC_tcmosVmax:
                            theCard->tcmosVmax = val;
                            break;
                        case kFEC_tcmosTacref:
                            theCard->tcmosTacref = val;
                            break;
                        case kFEC_tcmosIsetm:
                            if (ch < 2) theCard->tcmosIsetm[ch] = val;
                            break;
                        case kFEC_tcmosIseta:
                            if (ch < 2) theCard->tcmosIseta[ch] = val;
                            break;
                        case kFEC_vres:
                            theCard->vres = val;
                            break;
                        case kFEC_hvref:
                            theCard->hvref = val;
                            break;
                    }
                }
            }
        }
        if (numRows) {
            detDB->fecLoaded = YES;
        }
    }

    /**** load MTC database ****/
    [command autorelease];
    cols = "control_register,mtca_dacs,pedestal_width,coarse_delay,fine_delay,pedestal_mask,prescale,lockout_width";
    command = [[NSString stringWithFormat: @"select %s from mtc where key = (select mtc from run_state where run = 0)",cols] retain];
    theResult = [pqConnection queryString:command];
    if ([self isCancelled]) return nil;
    if (theResult) {
        int numRows = [theResult numOfRows];
        int numCols = [theResult numOfFields];
        if (numCols != kMTC_numDbColumns) {
            NSLog(@"Expected %d columns from MTC database, but got %d\n", kMTC_numDbColumns, numCols);
            return nil;
        }
        if (numRows) {
            PQ_MTC *mtc = [detDB getMTC];
            for (int col=0; col<kMTC_numDbColumns; ++col) {
                NSMutableData *dat = [theResult getInt64arrayAtRow:0 column:col];
                if (!dat) continue;
                int n = [dat length] / sizeof(int64_t);
                if (col == kMTC_mtcaDacs) {
                    if (n > 14) n = 14;
                } else if (col == kMTC_mtcaRelays) {
                    if (n > 7) n = 7;
                } else {
                    if (n > 1) n = 1;
                }
                for (int j=0; j<n; ++j) {
                    int64_t *valPt = (int64_t *)[dat mutableBytes];
                    if (valPt[j] == kPQBadValue) continue;
                    mtc->valid[col] |= (1 << j);    // set valid flag
                    int32_t val = (int32_t)valPt[j];
                    switch (col) {
                        case kMTC_controlReg:
                            mtc->controlReg = val;
                            break;
                        case kMTC_mtcaDacs:
                            mtc->mtcaDacs[j] = val;
                            break;
                        case kMTC_pedWidth:
                            mtc->pedWidth = val;
                            break;
                        case kMTC_coarseDelay:
                            mtc->coarseDelay = val;
                            break;
                        case kMTC_fineDelay:
                            mtc->fineDelay = val;
                            break;
                        case kMTC_pedMask:
                            mtc->pedMask = val;
                            mtc->valid[kMTC_pedMask] = 0xffffffff;
                            break;
                        case kMTC_prescale:
                            mtc->prescale = val;
                            break;
                        case kMTC_lockoutWidth:
                            mtc->lockoutWidth = val;
                            break;
                        case kMTC_gtMask:
                            mtc->gtMask = val;
                            mtc->valid[kMTC_gtMask] = 0xffffffff;
                            break;
                        case kMTC_gtCrateMask:
                            mtc->gtCrateMask = val;
                            mtc->valid[kMTC_gtCrateMask] = 0xffffffff;
                            break;
                        case kMTC_mtcaRelays:
                            mtc->mtcaRelays[j] = val;
                            break;
                    }
                }
            }
            detDB->mtcLoaded = YES;
        }
    }

    /**** load CAEN database ****/
    [command autorelease];
    cols = "channel_configuration,buffer_organization,custom_size,acquisition_control,trigger_mask,trigger_out_mask,post_trigger,front_panel_io_control,channel_mask,channel_dacs";
    command = [[NSString stringWithFormat: @"select %s from caen where key = (select caen from run_state where run = 0)",cols] retain];
    theResult = [pqConnection queryString:command];
    if ([self isCancelled]) return nil;
    if (theResult) {
        int numRows = [theResult numOfRows];
        int numCols = [theResult numOfFields];
        if (numCols != kCAEN_numDbColumns) {
            NSLog(@"Expected %d columns from CAEN database, but got %d\n", kCAEN_numDbColumns, numCols);
            return nil;
        }
        if (numRows) {
            PQ_CAEN *caen = [detDB getCAEN];
            for (int col=0; col<kCAEN_numDbColumns; ++col) {
                NSMutableData *dat = [theResult getInt64arrayAtRow:0 column:col];
                if (!dat) continue;
                int n = [dat length] / sizeof(int64_t);
                if (col == kCAEN_channelDacs) {
                    if (n > 8) n = 8;
                } else {
                    if (n > 1) n = 1;
                }
                for (int j=0; j<n; ++j) {
                    int64_t *valPt = (int64_t *)[dat mutableBytes];
                    if (valPt[j] == kPQBadValue) continue;
                    caen->valid[col] |= (1 << j);    // set valid flag
                    int32_t val = (int32_t)valPt[j];
                    switch (col) {
                        case kCAEN_channelConfiguration:
                            caen->channelConfiguration = val;
                            break;
                        case kCAEN_bufferOrganization:
                            caen->bufferOrganization = val;
                            break;
                        case kCAEN_customSize:
                            caen->customSize = val;
                            break;
                        case kCAEN_acquisitionControl:
                            caen->acquisitionControl = val;
                            break;
                        case kCAEN_triggerMask:
                            caen->triggerMask = val;
                            caen->valid[kCAEN_triggerMask] = 0xffffffff;
                            break;
                        case kCAEN_triggerOutMask:
                            caen->triggerOutMask = val;
                            caen->valid[kCAEN_triggerOutMask] = 0xffffffff;
                            break;
                        case kCAEN_postTrigger:
                            caen->postTrigger = val;
                            break;
                        case kCAEN_frontPanelIoControl:
                            caen->frontPanelIoControl = val;
                            break;
                        case kCAEN_channelMask:
                            caen->channelMask = val;
                            caen->valid[kCAEN_channelMask] = 0xffffffff;
                            break;
                        case kCAEN_channelDacs:
                            caen->channelDacs[j] = val;
                            break;
                    }
                }
            }
            detDB->caenLoaded = YES;
        }
    }
    // all done
    if (detDB->pmthvLoaded || detDB->fecLoaded || detDB->mtcLoaded || detDB->caenLoaded) {
        return detDB;
    } else {
        [detDB release];
        return nil;
    }
}

- (void) main
{
    ORPQResult *theResult;

    if([self isCancelled]) return;

    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
    NSObject *theResultObject = nil;
    @try {
        ORPQConnection* pqConnection = [[delegate pqConnection] retain];
        if([pqConnection isConnected] && ![self isCancelled]){

            switch (commandType) {

                case kPQCommandType_General:
                    theResult = [pqConnection queryString:command];
                    if (theResult && ![self isCancelled]) {
                        theResultObject = theResult;
                    }
                    break;

                case kPQCommandType_GetDetectorDB:
                    theResultObject = [self loadDetectorDB:pqConnection];
                    break;
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
        if (![self isCancelled]) {
            if (commandType == kPQCommandType_GetDetectorDB) {
                [self performSelectorOnMainThread:@selector(_detectorDbCallback:) withObject:theResultObject waitUntilDone:YES];
            } else if (selector) {
                [object performSelectorOnMainThread:selector withObject:theResultObject waitUntilDone:YES];
                selector = nil;
            }
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

