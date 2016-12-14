//
//  SNOPModel.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "SNOPModel.h"
#import "SNOPController.h"
#import "ORSegmentGroup.h"
#import "ORTaskSequence.h"
#import "ORCouchDB.h"
#import "ORXL3Model.h"
#import "ORDataTaker.h"
#import "ORDataTypeAssigner.h"
#import "ORRunModel.h"
#import "ORMTCModel.h"
#import "ORMTCController.h"
#import "ORMTC_Constants.h"
#import "ORFecDaughterCardModel.h"
#import "ORFec32Model.h"
#import "OROrderedObjManager.h"
#import "ORSNOConstants.h"
#import "ELLIEModel.h"
#import "SNOP_Run_Constants.h"
#import "SBC_Link.h"
#import "SNOCmds.h"
#import "RedisClient.h"
#include <stdint.h>
#import "SNOCaenModel.h"
#import "XL3_Link.h"
#import "ORPQModel.h"
#import "ORPQResult.h"
#import "SNOPGlobals.h"

#define RUNNING 0
#define STARTING 1
#define STOPPING 2
#define STOPPED 3

#define COLD_START 0
#define CONTINUOUS_START 1
#define ROLLOVER_START 2

static NSString* SNOPDbConnector	= @"SNOPDbConnector";
NSString* ORSNOPModelOrcaDBIPAddressChanged = @"ORSNOPModelOrcaDBIPAddressChanged";
NSString* ORSNOPModelDebugDBIPAddressChanged = @"ORSNOPModelDebugDBIPAddressChanged";
NSString* ORSNOPRunTypeWordChangedNotification = @"ORSNOPRunTypeWordChangedNotification";
NSString* ORSNOPRunTypeChangedNotification = @"ORSNOPRunTypeChangedNotification";
NSString* ORSNOPRunsLockNotification = @"ORSNOPRunsLockNotification";
NSString* ORSNOPModelRunsECAChangedNotification = @"ORSNOPModelRunsECAChangedNotification";
NSString* ORSNOPModelSRChangedNotification = @"ORSNOPModelSRChangedNotification";
NSString* ORSNOPModelSRVersionChangedNotification = @"ORSNOPModelSRVersionChangedNotification";

#define kOrcaRunDocumentAdded   @"kOrcaRunDocumentAdded"
#define kOrcaRunDocumentUpdated @"kOrcaRunDocumentUpdated"
#define kOrcaConfigDocumentAdded @"kOrcaConfigDocumentAdded"
#define kOrcaConfigDocumentUpdated @"kOrcaConfigDocumentUpdated"
#define kMtcRunDocumentAdded @"kMtcRunDocumentAdded"
#define kNumChanConfigBits 5 //used for the CAEN values 

#define kMorcaCompactDB         @"kMorcaCompactDB"

@interface SNOPModel (private)
- (void) morcaUpdateDBDict;
- (void) morcaUpdatePushDocs:(unsigned int) crate;
- (NSString*) stringDateFromDate:(NSDate*)aDate;
- (void) _runDocumentWorker;
- (void) _runEndDocumentWorker:(NSDictionary*)runDoc;
@end

@implementation SNOPModel

@synthesize
orcaDBUserName = _orcaDBUserName,
smellieRunNameLabel = _smellieRunNameLabel,
orcaDBPassword = _orcaDBPassword,
orcaDBName = _orcaDBName,
orcaDBPort = _orcaDBPort,
orcaDBConnectionHistory = _orcaDBConnectionHistory,
orcaDBIPNumberIndex = _orcaDBIPNumberIndex,
orcaDBPingTask = _orcaDBPingTask,
debugDBUserName = _debugDBUserName,
debugDBPassword = _debugDBPassword,
debugDBName = _debugDBName,
debugDBPort = _debugDBPort,
debugDBConnectionHistory = _debugDBConnectionHistory,
debugDBIPNumberIndex = _debugDBIPNumberIndex,
debugDBPingTask = _debugDBPingTask,
epedDataId = _epedDataId,
rhdrDataId = _rhdrDataId,
runDocument = _runDocument,
smellieDBReadInProgress = _smellieDBReadInProgress,
smellieDocUploaded = _smellieDocUploaded,
configDocument  = _configDocument,
mtcConfigDoc = _mtcConfigDoc,
dataHost,
dataPort,
logHost,
logPort,
resync;

@synthesize smellieRunHeaderDocList;

#pragma mark ¥¥¥Initialization

- (id) init
{
    
    self = [super init];

    rolloverRun = NO;
    state = STOPPED;
    start = COLD_START;
    resync = NO;

    /* initialize our connection to the MTC server */
    mtc_server = [[RedisClient alloc] init];

    /* initialize our connection to the XL3 server */
    xl3_server = [[RedisClient alloc] init];

    [[self undoManager] disableUndoRegistration];

    [self setMTCHost:@""];
    [self setXL3Host:@""];
    [self setDataServerHost:@""];
    [self setLogServerHost:@""];

    [self setMTCPort:4001];
    [self setXL3Port:4004];
    [self setDataServerPort:4005];
    [self setLogServerPort:4001];

	[self initOrcaDBConnectionHistory];
	[self initDebugDBConnectionHistory];
    [self initSmellieRunDocsDic];

    [[self undoManager] enableUndoRegistration];

    return self;
}

- (void) setMTCPort: (int) port
{
    int i;

    if (port == mtcPort) return;

    mtcPort = port;
    [mtc_server disconnect];
    [mtc_server setPort:port];

    /* Set the MTC server hostname for the MTC model. */
    NSArray* mtcs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];

    ORMTCModel* mtc;
    for (i = 0; i < [mtcs count]; i++) {
        mtc = [mtcs objectAtIndex:0];
        [mtc setMTCPort:port];
    }

    /* Set the MTC server hostname for the CAEN model. */
    NSArray* caens = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOCaenModel")];

    SNOCaenModel* caen;
    for (i = 0; i < [caens count]; i++) {
        caen = [caens objectAtIndex:0];
        [caen setMTCPort:port];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SNOPSettingsChanged" object:self];
    
}

- (int) mtcPort
{
    return mtcPort;
}

- (void) setMTCHost: (NSString *) host
{
    int i;

    if ([host isEqualToString:mtcHost]) return;

    [mtcHost autorelease];//MAH -- strings should be handled like this
    mtcHost = [host copy];
    [mtc_server disconnect];
    [mtc_server setHost:host];

    /* Set the MTC server hostname for the MTC model. */
    NSArray* mtcs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];

    ORMTCModel* mtc;
    for (i = 0; i < [mtcs count]; i++) {
        mtc = [mtcs objectAtIndex:0];
        [mtc setMTCHost:host];
    }

    /* Set the MTC server hostname for the CAEN model. */
    NSArray* caens = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOCaenModel")];

    SNOCaenModel* caen;
    for (i = 0; i < [caens count]; i++) {
        caen = [caens objectAtIndex:0];
        [caen setMTCHost:host];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SNOPSettingsChanged" object:self];

}

- (NSString *) mtcHost
{
    return mtcHost;
}

- (void) setXL3Port: (int) port
{
    /* Set the port number for the XL3 server redis client. */
    if (port == xl3Port) return;

    xl3Port = port;
    [xl3_server disconnect];
    [xl3_server setPort:port];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SNOPSettingsChanged" object:self];
    
}

- (int) xl3Port
{
    return xl3Port;
}

- (void) setXL3Host: (NSString *) host
{
    /* Set the XL3 server hostname. This function will automatically
     * sync this value to all of the XL3 model objects. */
    int i;

    if ([host isEqualToString:xl3Host]) return;

    [xl3Host autorelease];//MAH -- strings should be handled like this
    xl3Host = [host copy];
    [xl3_server disconnect];
    [xl3_server setHost:host];

    /* Set the XL3 server hostname for the XL3 models. */
    NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];

    ORXL3Model* xl3;
    for (i = 0; i < [xl3s count]; i++) {
        xl3 = [xl3s objectAtIndex:i];
        [[xl3 xl3Link] disconnectSocket];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SNOPSettingsChanged" object:self];

}

- (NSString *) xl3Host
{
    return xl3Host;
}

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];

    rolloverRun = NO;
    state = STOPPED;
    start = COLD_START;
    resync = NO;

    [[self undoManager] disableUndoRegistration];
	[self initOrcaDBConnectionHistory];
	[self initDebugDBConnectionHistory];
    [self initSmellieRunDocsDic];

    [self setViewType:[decoder decodeIntForKey:@"viewType"]];

    //CouchDB
    self.orcaDBUserName = [decoder decodeObjectForKey:@"ORSNOPModelOrcaDBUserName"];
    self.orcaDBPassword = [decoder decodeObjectForKey:@"ORSNOPModelOrcaDBPassword"];
    self.orcaDBName = [decoder decodeObjectForKey:@"ORSNOPModelOrcaDBName"];
    self.orcaDBPort = [decoder decodeInt32ForKey:@"ORSNOPModelOrcaDBPort"];
    self.orcaDBIPAddress = [decoder decodeObjectForKey:@"ORSNOPModelOrcaDBIPAddress"];
    self.debugDBUserName = [decoder decodeObjectForKey:@"ORSNOPModelDebugDBUserName"];
    self.debugDBPassword = [decoder decodeObjectForKey:@"ORSNOPModelDebugDBPassword"];
    self.debugDBName = [decoder decodeObjectForKey:@"ORSNOPModelDebugDBName"];
    self.debugDBPort = [decoder decodeInt32ForKey:@"ORSNOPModelDebugDBPort"];
    self.debugDBIPAddress = [decoder decodeObjectForKey:@"ORSNOPModelDebugDBIPAddress"];

    //ECA
    [self setECA_pattern:[decoder decodeIntForKey:@"SNOPECApattern"]];
    [self setECA_type:[decoder decodeObjectForKey:@"SNOPECAtype"]];
    [self setECA_tslope_pattern:[decoder decodeIntForKey:@"SNOPECAtslppattern"]];
    [self setECA_nevents:[decoder decodeIntForKey:@"SNOPECANEvents"]];
    [self setECA_rate:[decoder decodeObjectForKey:@"SNOPECAPulserRate"]];

    //Settings
    [self setMTCHost:[decoder decodeObjectForKey:@"mtcHost"]];
    [self setMTCPort:[decoder decodeIntForKey:@"mtcPort"]];

    [self setXL3Host:[decoder decodeObjectForKey:@"xl3Host"]];
    [self setXL3Port:[decoder decodeIntForKey:@"xl3Port"]];

    [self setDataServerHost:[decoder decodeObjectForKey:@"dataHost"]];
    [self setDataServerPort:[decoder decodeIntForKey:@"dataPort"]];

    [self setLogServerHost:[decoder decodeObjectForKey:@"logHost"]];
    [self setLogServerPort:[decoder decodeIntForKey:@"logPort"]];
    
    /* Check if we actually decoded the mtc, xl3, data, and log server
     * hostnames and ports. decodeObjectForKey() will return NULL if the
     * key doesn't exist, and decodeIntForKey() will return 0. */
    if ([self mtcHost] == NULL) [self setMTCHost:@""];
    if ([self xl3Host] == NULL) [self setXL3Host:@""];
    if ([self dataHost] == NULL) [self setDataServerHost:@""];
    if ([self logHost] == NULL) [self setLogServerHost:@""];

    if ([self mtcPort] == 0) [self setMTCPort:4001];
    if ([self xl3Port] == 0) [self setXL3Port:4004];
    if ([self dataPort] == 0) [self setDataServerPort:4005];
    if ([self logPort] == 0) [self setLogServerPort:4001];

    [[self undoManager] enableUndoRegistration];

    //Set extra security
    [gSecurity addSuperUnlockMask:kDiagnosticRunType forObject:self];

    /* initialize our connection to the MTC server */
    mtc_server = [[RedisClient alloc] initWithHostName:mtcHost withPort:mtcPort];

    /* initialize our connection to the XL3 server */
    xl3_server = [[RedisClient alloc] initWithHostName:xl3Host withPort:xl3Port];

    return self;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SNOP"]];
}

- (void) makeMainController
{
    [self linkToController:@"SNOPController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:SNOPDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB O' ];
	[ aConnector addRestrictedConnectionType: 'DB I' ]; //can only connect to DB outputs
    [aConnector release];
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [standardRunType release];
    [standardRunVersion release];
    [_configDocument release];
    [_debugDBConnectionHistory release];
    [_debugDBName release];
    [_debugDBUserName release];
    [_debugDBPassword release];
    [_debugDBPingTask release];
    [_mtcConfigDoc release];
    [_orcaDBName release];
    [_orcaDBPassword release];
    [_orcaDBUserName release];
    [_orcaDBConnectionHistory release];
    [_orcaDBPingTask release];
    [_runDocument release];
    [_smellieRunNameLabel release];
    [dataHost release];
    [logHost release];
    [smellieRunHeaderDocList release];
    [super dealloc];
}

- (void) sleep
{
    [super sleep];
    //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(morcaUpdateDB) object:nil];
}


- (void) initSmellieRunDocsDic
{
    [self setSmellieDBReadInProgress:NO];
    
    if(!self.smellieRunHeaderDocList) {
        self.smellieRunHeaderDocList = nil;//[[NSMutableDictionary alloc] init];
    }
}

-(void) initRunMaskHistory
{
    
}

- (void) initOrcaDBConnectionHistory
{
	self.orcaDBIPNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.orcaDBIPNumberIndex",[self className]]];
	if(!self.orcaDBConnectionHistory){
		NSArray* his = [[NSUserDefaults standardUserDefaults] objectForKey:
                        [NSString stringWithFormat:@"orca.%@.orcaDBConnectionHistory",[self className]]];

        self.orcaDBConnectionHistory = [[his mutableCopy] autorelease];
	}
	if(!self.orcaDBConnectionHistory) {
        self.orcaDBConnectionHistory = [NSMutableArray array];
    }
}

- (void) initDebugDBConnectionHistory
{
	self.debugDBIPNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.debugDBIPNumberIndex",[self className]]];
	if(!self.debugDBConnectionHistory){
		NSArray* his = [[NSUserDefaults standardUserDefaults] objectForKey:
                        [NSString stringWithFormat:@"orca.%@.debugDBConnectionHistory",[self className]]];
        
		self.debugDBConnectionHistory = [[his mutableCopy] autorelease];
	}
	if(!self.debugDBConnectionHistory) {
        self.debugDBConnectionHistory = [NSMutableArray array];
    }
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(runInitialization:)
                         name : ORRunInitializationNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runAboutToRollOver:)
                         name : ORRunIsAboutToRollOver
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStart:)
                         name : ORRunSecondChanceForWait
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runStarted:)
                         name : ORRunStartedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStop:)
                         name : ORRunAboutToStopNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runStopped:)
                         name : ORRunStoppedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(subRunStarted:)
                         name : ORRunStartSubRunNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(subRunEnded:)
                         name : ORRunBetweenSubRunsNotification
                       object : nil];

}

- (void) runAboutToRollOver:(NSNotification*)aNote
{
    /* When the next run is going to be started due to a rollover, this method
     * is called.
     *
     * Note that the rolloverRun variable is reset to NO after the next run
     * start. */
    rolloverRun = YES;
}

- (void) runInitialization:(NSNotification*)aNote
{
    /* Called at the start of a run before the run actually starts. Here
     * we initialize the hardware before the run starts. */
    NSArray* objs;
    ORMTCModel *mtc;
    SNOCaenModel *caen;
    ORXL3Model *xl3;
    int i;

    objs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];

    if ([objs count]) {
        mtc = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        goto err;
    }

    objs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOCaenModel")];

    if ([objs count]) {
        caen = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find SNO CAEN model. Please add it to the experiment and restart the run.\n");
        goto err;
    }

    switch (state) {
    case STOPPED:
        start = COLD_START;
        break;
    case RUNNING:
        if (rolloverRun) {
            start = ROLLOVER_START;
            rolloverRun = NO;
        } else {
            start = CONTINUOUS_START;
        }
        break;
    default:
        start = COLD_START;
    }

    state = STARTING;

    switch (start) {
    case ROLLOVER_START:
        @try {
            /* Tell the MTC server to queue the run start. This will suspend
             * the MTC readout and fire a SOFT_GT. When the run starts, we will
             * resume the MTC readout */
            [mtc_server okCommand:"queue_run_start"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending queue_run_start "
                       "command to mtc_server: %@\n", [e reason]);
            goto err;
        }
        break;
    case CONTINUOUS_START:
        @try {
            /* Tell the MTC server to queue the run start. This will suspend
             * the MTC readout and fire a SOFT_GT. When the run starts, we will
             * resume the MTC readout */
            [mtc_server okCommand:"queue_run_start"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending queue_run_start "
                       "command to mtc_server: %@\n", [e reason]);
            goto err;
        }

        /* Load the MTC settings from model to hardware. */
        if ([mtc initAtRunStart:1]) {
            NSLogColor([NSColor redColor], @"error initializing MTC.\n");
            goto err;
        }
        break;
    default:
        /* Turn off triggers */
        @try {
            [mtc_server okCommand:"set_gt_mask 0"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending set_gt_mask command "
                       "to mtc_server: %@\n", [e reason]);
            goto err;
        }

        @try {
            [mtc_server okCommand:"reset_gtid"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending reset_gtid command "
                       "to mtc_server: %@\n", [e reason]);
            goto err;
        }

        /* Load the CAEN settings to hardware. */
        if ([caen initAtRunStart]) {
            NSLogColor([NSColor redColor], @"error initializing CAEN.\n");
            goto err;
        }

        /* Load the MTC hardware. */
        if ([mtc initAtRunStart:0]) {
            NSLogColor([NSColor redColor], @"error initializing MTC.\n");
            goto err;
        }

        /* Load the XL3 hardware. */
        objs = [[(ORAppDelegate*)[NSApp delegate] document]
             collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];

        for (i = 0; i < [objs count]; i++) {
            xl3 = [objs objectAtIndex:i];

            if ([xl3 initAtRunStart]) {
                NSLogColor([NSColor redColor], @"error initializing XL3.\n");
                goto err;
            }
        }
        break;
    }

    if ([ORPQModel getCurrent]) {
        /* Wait to start the run until we get the next run number from the
         * database. */
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"querying database for run number",
                                  @"Reason",
                                  nil];

        /* Tell the run control to wait. */
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object: self userInfo: userInfo];

        [[ORPQModel getCurrent] dbQuery:@"SELECT nextval('run_number')"
             object:self selector:@selector(waitForRunNumber:) timeout:1.0];
    } else {
        /* If there is no database object, just continue with the existing run
         * number saved to Orca. */
        NSLogColor([NSColor redColor], @"Unable to find ORCA PostgreSQL model. Please add it to the experiment. Aborting run start.\n");

        goto err;
    }

    return;

err:
{
    /* Need to abort the run start here, because uncaught exceptions are not
     * handled by ORCA during this phase of run start */
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"", @"Reason",
                                @"", @"Details",
                                nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStartupAbort object: self userInfo: userInfo];

    state = STOPPED;
}
}

- (void) waitForRunNumber: (ORPQResult *) result
{
    int numRows, numCols, run_number;

    if (!result) {
        NSLogColor([NSColor redColor], @"Error getting the run number from the database. Using default run number. Data is going in the bit bucket.\n");
        goto err;
    }

    numRows = [result numOfRows];
    numCols = [result numOfFields];

    if (numRows != 1) {
        NSLogColor([NSColor redColor], @"Error getting run number from database: got %i rows but expected 1. Using default run number. Data is going in the bit bucket.", numRows);
        goto err;
    }

    if (numCols != 1) {
        NSLogColor([NSColor redColor], @"Error getting run number from database: got %i columns but expected 1. Using default run number. Data is going in the bit bucket.", numCols);
        goto err;
    }

    run_number = [result getInt64atRow:0 column:0];

    NSArray*  runObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runObjects count]){
        NSLogColor([NSColor redColor], @"waitForRunNumber: couldn't find run control object!");
        [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object: self];
        /* This should never happen. */
        return;
    }

    ORRunModel* runControl = [runObjects objectAtIndex:0];

    /* We set the run to the next run number - 1 because the run control will
     * increment the run number before the run starts. */
    [runControl setRunNumber:run_number-1];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object: self];

    return;

err:
{
    NSArray*  runObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];

    if(![runObjects count]){
        NSLogColor([NSColor redColor], @"waitForRunNumber: couldn't find run control object!");
        [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object: self];
        /* This should never happen. */
        return;
    }

    ORRunModel* runControl = [runObjects objectAtIndex:0];

    [runControl setRunNumber:0xffffffff - 1];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object: self];

    return;
}
}

- (void) runAboutToStart:(NSNotification*)aNote
{
    NSArray* objs;
    ORMTCModel *mtc;

    objs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];

    if ([objs count]) {
        mtc = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        goto err;
    }

    switch (start) {
    case COLD_START:
        @try {
            /* Tell the MTC server to queue the run start. This will suspend
             * the MTC readout and fire a SOFT_GT. When the run starts, we will
             * resume the MTC readout */
            [mtc_server okCommand:"queue_run_start"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending queue_run_start "
                       "command to mtc_server: %@\n", [e reason]);
            goto err;
        }

        /* Load the GT mask. */
        if ([mtc initAtRunStart:1]) {
            NSLogColor([NSColor redColor], @"error initializing MTC.\n");
            goto err;
        }

        break;
    default:
        break;
    }

    return;

err:
{
    /* Need to abort the run start here, because uncaught exceptions are not
     * handled by ORCA during this phase of run start */
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"", @"Reason",
                                @"", @"Details",
                                nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStartupAbort object: self userInfo: userInfo];

    state = STOPPED;
}
}

- (void) runStarted:(NSNotification*)aNote
{
    ORRunModel *run = [aNote object];

    uint32_t run_type = [run runType];
    uint32_t run_number = [run runNumber];
    uint32_t source_mask = 0; /* needs to come from the MANIP system */

    @try {
        /* send the run_start command to the MTC server which will send the
         * run header record to the builder, resume the MTC readout, fire a
         * SOFT_GT, and send a trigger record to the builder */
        [mtc_server okCommand:"run_start %d %d %d", run_number, run_type, source_mask];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"error sending run_start "
                   "command to mtc_server: %@\n", [e reason]);
        goto err;
    }

    state = RUNNING;

    //initilise the run document
    self.runDocument = nil;
    //intialise the configuation document
    self.configDocument = nil;
    //initilise the run document
    self.mtcConfigDoc = nil;
    
    [NSThread detachNewThreadSelector:@selector(_runDocumentWorker) toTarget:self withObject:nil];

    [self updateRHDRSruct];
    [self shipRHDRRecord];

    return;

err:
{
    /* Need to abort the run start here, because uncaught exceptions are not
     * handled by ORCA during this phase of run start */
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"", @"Reason",
                                @"", @"Details",
                                nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRequestRunHalt object: self userInfo: userInfo];

    state = RUNNING;
}
}

- (void) runAboutToStop:(NSNotification*)aNote
{
    /* If this is a hard stop, we send run_stop to the MTC server which
     * will fire a SOFT_GT and turn triggers off. Then we need to wait
     * until the MTC/CAEN/XL3s have read out all the data. */

    NSDictionary *userInfo = [aNote userInfo];

    if (![[userInfo objectForKey:@"willRestart"] boolValue] || resync) {
        state = STOPPING;
	resync = NO;
    }

    switch (state) {
    case STOPPING:
        @try {
            [mtc_server okCommand:"run_stop"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending run_stop "
                       "command to mtc_server: %@\n", [e reason]);
            goto err;
        }

        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"waiting for MTC/XL3/CAEN data", @"Reason",
                                  nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object: self userInfo: userInfo];

        /* detach a thread to monitor XL3/CAEN/MTC buffers */
        [NSThread detachNewThreadSelector:@selector(_waitForBuffers)
                                 toTarget:self
                               withObject:nil];
        break;
    default:
        break;
    }

    return;

err:
    state = RUNNING;
}

- (void) _waitForBuffers
{
    /* Since we are running in a separate thread, we just open a new
     * connection to the MTC and XL3 servers. */
    RedisClient *mtc = [[RedisClient alloc] initWithHostName:mtcHost withPort:mtcPort];
    RedisClient *xl3 = [[RedisClient alloc] initWithHostName:xl3Host withPort:xl3Port];

    while (1) {
        @try {
            if (([mtc intCommand:"data_available"] == 0) &&
                ([xl3 intCommand:"data_available"] == 0))
                break;
        } @catch (NSException *e) {
            NSLog(@"Failed to check MTC/XL3 data buffers. Quitting run...\n");
            break;
        }
    }

    [mtc release];
    [xl3 release];

    /* Go ahead and end the run. */
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object: self];
    });
    
}

- (void) runStopped:(NSNotification*)aNote
{
    /* By this point, the MTC/CAEN/XL3s should be read out, so if this is
     * a hard run stop, we send the MTC server the builder_end_run command
     * which will tell the builder to flush all events */

    switch (state) {
    case STOPPING:
        @try {
            [mtc_server okCommand:"builder_end_run"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending builder_end_run "
                       "command to mtc_server: %@\n", [e reason]);
        }

        state = STOPPED;
        break;
    }

    [NSThread detachNewThreadSelector:@selector(_runEndDocumentWorker:)
                             toTarget:self
                           withObject:[[self.runDocument copy] autorelease]];
    self.runDocument = nil;
    self.configDocument = nil;
}

- (void) subRunStarted:(NSNotification*)aNote
{
    //Ship subrunrecord - Just a special case of an eped record
    [self shipSubRunRecord];
}

- (void) subRunEnded:(NSNotification*)aNote
{
    //update calibration documents (TELLIE temp)
}

// orca script helper (will come from DB)
- (void) updateEPEDStructWithCoarseDelay: (unsigned long) coarseDelay
                               fineDelay: (unsigned long) fineDelay
                          chargePulseAmp: (unsigned long) chargePulseAmp
                           pedestalWidth: (unsigned long) pedestalWidth
                                 calType: (unsigned long) calType
{
    _epedStruct.coarseDelay = coarseDelay; // nsec
    _epedStruct.fineDelay = fineDelay; // clicks
    _epedStruct.chargePulseAmp = chargePulseAmp; // clicks
    _epedStruct.pedestalWidth = pedestalWidth; // nsec
    _epedStruct.calType = calType; // nsec
}

- (void) updateEPEDStructWithStepNumber: (unsigned long) stepNumber
{
    _epedStruct.stepNumber = stepNumber;
    
}

- (void) updateEPEDStructWithNSlopePoint: (unsigned long) nTSlopePoints
{
    _epedStruct.nTSlopePoints = nTSlopePoints;
}

- (void) shipSubRunRecord
{
    /* Sends a command to the MTC server to ship an 'EPED' record to the data
     * stream server, which will eventually get to the builder. The feature that 
     * distinguishs between the subRunRecord and the eped record is the 
     * inclusion of the subrun flag, defined in rat's zdab_convert.cc as:
     * 
     *     #define EPED_FLAG_SUBRUN 0x01000000
     *
     * All fields associated with EPED settings are set to zero, with the exception
     * of the half crate id, which is repurposed to hold the 
     * [runControl subRunNumber]. The mtc server adds a GTID value to the record
     * before piping it down to the builder.
     *
     */
    //get the run controller
    NSArray*  runObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if([runObjects count]){
        ORRunModel* runControl = [runObjects objectAtIndex:0];
        if ([[ORGlobal sharedGlobal] runInProgress]) {
            @try {
                [mtc_server okCommand:"send_eped_record %d %d %d %d %d %d %d",
                 0,
                 0,
                 0,
                 0,
                 [runControl subRunNumber], /* In place of half crate id */
                 0,
                 0x01000000 /* subRun flag */
                 ];
            } @catch (NSException *e) {
                NSLogColor([NSColor redColor], @"failed to send EPED record: %@",
                           [e reason]);
            }
        }
    }
}
- (void) shipEPEDRecord
{
    /* Sends a command to the MTC server to ship an EPED record to the data
     * stream server, which will eventually get to the builder.
     *
     * Note: Currently, this function does not send EPED records to mark
     * subrun boundaries. To accomplish this, one would need to mask in
     * the EPED_FLAG_SUBRUN bit in the flags bitmask, where EPED_FLAG_SUBRUN
     * is defined in the builder's RecordInfo.h as:
     *
     *     #define EPED_FLAG_SUBRUN 0x1000000
     *
     */
    if ([[ORGlobal sharedGlobal] runInProgress]) {
        @try {
            [mtc_server okCommand:"send_eped_record %d %d %d %d %d %d %d",
                _epedStruct.pedestalWidth,
                _epedStruct.coarseDelay,
                _epedStruct.fineDelay,
                _epedStruct.chargePulseAmp, /* qinj_dacsetting */
                _epedStruct.stepNumber, /* half crate id? */
                _epedStruct.calType,
                0 /* flags */
            ];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"failed to send EPED record: %@",
                       [e reason]);
        }
    }
}

- (void) updateRHDRSruct
{
    //form run info
    NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
	if([runObjects count]){
		ORRunModel* rc = [runObjects objectAtIndex:0];
        _rhdrStruct.runNumber = [rc runNumber];
        NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
        NSDateComponents *cmpStartTime = [gregorian components:
                                                 (NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay |
                                                  NSCalendarUnitHour | NSCalendarUnitMinute |NSCalendarUnitSecond)
                                                      fromDate:[NSDate date]];
        _rhdrStruct.date = [cmpStartTime day] + [cmpStartTime month] * 100 + [cmpStartTime year] * 10000;
        _rhdrStruct.time = [cmpStartTime second] * 100 + [cmpStartTime minute] * 10000 + [cmpStartTime hour] * 1000000;
	}

    //svn revision
    if (_rhdrStruct.daqCodeVersion == 0) {
        NSFileManager* fm = [NSFileManager defaultManager];
		NSString* svnVersionPath = [[NSBundle mainBundle] pathForResource:@"svnversion"ofType:nil];
		NSMutableString* svnVersion = [NSMutableString stringWithString:@""];
		if([fm fileExistsAtPath:svnVersionPath])svnVersion = [NSMutableString stringWithContentsOfFile:svnVersionPath encoding:NSASCIIStringEncoding error:nil];
		if([svnVersion hasSuffix:@"\n"]){
			[svnVersion replaceCharactersInRange:NSMakeRange([svnVersion length]-1, 1) withString:@""];
		}
        NSLog(svnVersion);
        NSLog(svnVersionPath);
        _rhdrStruct.daqCodeVersion = [svnVersion integerValue]; //8045:8046M -> 8045 which is desired
    }
    
    _rhdrStruct.calibrationTrialNumber = 0;
    _rhdrStruct.sourceMask = 0; // from run type document
    _rhdrStruct.runMask = 0; // from run type document
    _rhdrStruct.gtCrateMask = 0; // from run type document
}

- (void) shipRHDRRecord
{
    const unsigned char rhdr_rec_length = 20;
    unsigned long data[rhdr_rec_length];
    data[0] = [self rhdrDataId] | rhdr_rec_length;
    data[1] = 0;
    
    data[2] = _rhdrStruct.date;
    data[3] = _rhdrStruct.time;
    data[4] = _rhdrStruct.daqCodeVersion;
    data[5] = _rhdrStruct.runNumber;
    data[6] = _rhdrStruct.calibrationTrialNumber;
    data[7] = _rhdrStruct.sourceMask;
    data[8] = _rhdrStruct.runMask & 0xffffffffULL;
    data[9] = _rhdrStruct.gtCrateMask;
    data[10] = 0;
    data[11] = 0;
    data[12] = _rhdrStruct.runMask >> 32;
    data[13] = 0;
    data[14] = 0;
    data[15] = 0;
    data[16] = 0;
    data[17] = 0;
    data[18] = 0;
    data[19] = 0;
    
    NSData* pdata = [[NSData alloc] initWithBytes:data length:sizeof(long)*(rhdr_rec_length)];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification object:pdata];
    [pdata release];
    pdata = nil;
}

#pragma mark ¥¥¥Accessors

- (void) clearOrcaDBConnectionHistory
{
	self.orcaDBConnectionHistory = nil;
    [self setOrcaDBIPAddress:[self orcaDBIPAddress]];
}

- (void) clearDebugDBConnectionHistory
{
	self.debugDBConnectionHistory = nil;
	[self setDebugDBIPAddress:[self debugDBIPAddress]];
}

- (id) orcaDBConnectionHistoryItem:(unsigned int)index
{
	if(self.orcaDBConnectionHistory && index < [self.orcaDBConnectionHistory count]) {
        return [self.orcaDBConnectionHistory objectAtIndex:index];
    }
	else return nil;
}

- (id) debugDBConnectionHistoryItem:(unsigned int)index
{
	if(self.debugDBConnectionHistory && index < [self.debugDBConnectionHistory count]) {
        return [self.debugDBConnectionHistory objectAtIndex:index];
    }
	else return nil;
}

- (NSString*) orcaDBIPAddress
{
    if (!_orcaDBIPAddress) {
        return @"";
    }
    id result;
    result = [_orcaDBIPAddress retain];
    return [result autorelease];
}

- (void) setOrcaDBIPAddress:(NSString*)orcaIPAddress
{
	if([orcaIPAddress length] && orcaIPAddress != self.orcaDBIPAddress) {
		[[[self undoManager] prepareWithInvocationTarget:self] setOrcaDBIPAddress:self.orcaDBIPAddress];
		
		if (self.orcaDBIPAddress) [_orcaDBIPAddress autorelease];
		if (orcaIPAddress) _orcaDBIPAddress = [orcaIPAddress copy];
		
		if(!self.orcaDBConnectionHistory) self.orcaDBConnectionHistory = [NSMutableArray arrayWithCapacity:4];
		if(![self.orcaDBConnectionHistory containsObject:self.orcaDBIPAddress]){
			[self.orcaDBConnectionHistory addObject:self.orcaDBIPAddress];
		}
		self.orcaDBIPNumberIndex = [self.orcaDBConnectionHistory indexOfObject:self.orcaDBIPAddress];
		
		[[NSUserDefaults standardUserDefaults] setObject:self.orcaDBConnectionHistory forKey:[NSString stringWithFormat:@"orca.%@.orcaDBConnectionHistory",[self className]]];
		[[NSUserDefaults standardUserDefaults] setInteger:self.orcaDBIPNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.orcaDBIPNumberIndex",[self className]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelOrcaDBIPAddressChanged object:self];

	}
}

- (NSString*) debugDBIPAddress
{
    if (!_debugDBIPAddress) {
        return @"";
    }
    id result;
    result = [_debugDBIPAddress retain];
    return [result autorelease];
}

- (void) setDebugDBIPAddress:(NSString*)debugIPAddress
{
	if([debugIPAddress length] && debugIPAddress != self.debugDBIPAddress) {
		[[[self undoManager] prepareWithInvocationTarget:self] setDebugDBIPAddress:self.debugDBIPAddress];

        if (self.debugDBIPAddress) [_debugDBIPAddress autorelease];
		if (debugIPAddress) _debugDBIPAddress = [debugIPAddress copy];

		if(!self.debugDBConnectionHistory) self.debugDBConnectionHistory = [NSMutableArray arrayWithCapacity:4];
		if(![self.debugDBConnectionHistory containsObject:self.debugDBIPAddress]){
			[self.debugDBConnectionHistory addObject:self.debugDBIPAddress];
		}
		self.debugDBIPNumberIndex = [self.debugDBConnectionHistory indexOfObject:self.debugDBIPAddress];
		
		[[NSUserDefaults standardUserDefaults] setObject:self.debugDBConnectionHistory forKey:[NSString stringWithFormat:@"orca.%@.debugDBConnectionHistory",[self className]]];
		[[NSUserDefaults standardUserDefaults] setInteger:self.debugDBIPNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.debugDBIPNumberIndex",[self className]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelDebugDBIPAddressChanged object:self];
	}
}

- (void) orcaDBPing
{
    if(!self.orcaDBPingTask){
		ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
		self.orcaDBPingTask = [[[NSTask alloc] init] autorelease];
		
		[self.orcaDBPingTask setLaunchPath:@"/sbin/ping"];
		[self.orcaDBPingTask setArguments: [NSArray arrayWithObjects:@"-c",@"2",@"-t",@"5",@"-q",self.orcaDBIPAddress,nil]];
		
		[aSequence addTaskObj:self.orcaDBPingTask];
		[aSequence setVerbose:YES];
		[aSequence setTextToDelegate:YES];
		[aSequence launch];
	}
	else {
		[self.orcaDBPingTask terminate];
	}
}

- (void) debugDBPing
{
    if(!self.debugDBPingTask){
		ORTaskSequence* aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
		self.debugDBPingTask = [[[NSTask alloc] init] autorelease];
		
		[self.debugDBPingTask setLaunchPath:@"/sbin/ping"];
		[self.debugDBPingTask setArguments: [NSArray arrayWithObjects:@"-c",@"2",@"-t",@"5",@"-q",self.debugDBIPAddress,nil]];
		
		[aSequence addTaskObj:self.debugDBPingTask];
		[aSequence setVerbose:YES];
		[aSequence setTextToDelegate:YES];
		[aSequence launch];
	}
	else {
		[self.debugDBPingTask terminate];
	}
}

- (void) taskFinished:(NSTask*)aTask
{
	if(aTask == self.orcaDBPingTask){
		self.orcaDBPingTask = nil;
	}
	else if(aTask == self.debugDBPingTask){
		self.debugDBPingTask = nil;
	}
}

- (void) orcaUpdateDB {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(orcaUpdateDB) object:nil];
    //[self orcaUpdateDBDict];
    //[self performSelector:@selector(morcaUpdatePushDocs) withObject:nil afterDelay:0.2];
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp
{
	@synchronized(self) {
        if ([aResult isKindOfClass:[NSDictionary class]]) {
            NSString* message = [aResult objectForKey:@"Message"];
            if (message) {
                /*
                if([aTag isEqualToString:kMorcaCrateDocGot]){
                    NSLog(@"CouchDB Message getting a crate doc:");
                }
                 */
                [aResult prettyPrint:@"CouchDB Message:"];
                return;
            }

            if ([aTag isEqualToString:kOrcaRunDocumentAdded]) {
                NSMutableDictionary* runDoc = [[[self runDocument] mutableCopy] autorelease];
                [runDoc setObject:[aResult objectForKey:@"id"] forKey:@"_id"];
                //[runDoc setObject:[aResult objectForKey:@"rev"] forKey:@"_rev"];
                //[runDoc setObject:[aResult objectForKey:@"ok"] forKey:@"ok"];
                self.runDocument = runDoc;
                //[aResult prettyPrint:@"CouchDB Ack Doc:"];
            }
            
            //This is called when smellie run header is queried from CouchDB
            else if ([aTag isEqualToString:@"kSmellieRunHeaderRetrieved"])
            {
                //NSLog(@"here\n");
                //NSLog(@"Object: %@\n",aResult);
                //NSLog(@"result1: %@\n",[aResult objectForKey:@"rows"]);
                //NSLog(@"result2: %@\n",[[aResult objectForKey:@"rows"] objectAtIndexedSubscript:0]);
                [self parseSmellieRunHeaderDoc:aResult];
            }
            else if ([aTag isEqualToString:kOrcaRunDocumentUpdated]) {
                //there was error
                //[aResult prettyPrint:@"couchdb update doc:"];
            }
            else if([aTag isEqualToString:kMtcRunDocumentAdded]){
                NSMutableDictionary* mtcConfigDoc = [[[self mtcConfigDoc] mutableCopy] autorelease];
                [mtcConfigDoc setObject:[aResult objectForKey:@"id"] forKey:@"_id"];
                self.mtcConfigDoc = mtcConfigDoc;
            }
            //Look for the configuration document tag
            else if ([aTag isEqualToString:kOrcaConfigDocumentAdded]) {
                NSMutableDictionary* configDoc = [[[self configDocument] mutableCopy] autorelease];
                [configDoc setObject:[aResult objectForKey:@"id"] forKey:@"_id"];
                //[runDoc setObject:[aResult objectForKey:@"rev"] forKey:@"_rev"];
                //[runDoc setObject:[aResult objectForKey:@"ok"] forKey:@"ok"];
                self.configDocument = configDoc;
                //[aResult prettyPrint:@"CouchDB Ack Doc:"];
            }
            //look for the configuation docuemnt updated tag
            else if ([aTag isEqualToString:kOrcaConfigDocumentUpdated]) {
                //there was error
                //[aResult prettyPrint:@"couchdb update doc:"];
            }
            /*
            else if([aTag rangeOfString:kMorcaCrateDocGot].location != NSNotFound){
                //int key = [[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"key"];
                if ([[aResult objectForKey:@"rows"] count] && [[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"key"]){
                    [morcaDBDict setObject:[[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"doc"]
                        forKey:[[[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"key"] stringValue]];
                }
                else {
                    [morcaDBDict removeObjectForKey:[[aTag componentsSeparatedByString:@"."] objectAtIndex:1]];
                }
                if ([self morcaIsVerbose]) {
                    [aResult prettyPrint:@"CouchDB pull doc from DB"];
                }
                [self morcaUpdatePushDocs:[[[aTag componentsSeparatedByString:@"."] objectAtIndex:1] intValue]];
            }
             */
            else if ([aTag isEqualToString:@"Message"]) {
                [aResult prettyPrint:@"CouchDB Message:"];
            }
            else {
                [aResult prettyPrint:@"CouchDB"];
            }
        }
        else if ([aResult isKindOfClass:[NSArray class]]) {
            /*
            if([aTag isEqualToString:kListDB]){
                [aResult prettyPrint:@"CouchDB List:"];
            else [aResult prettyPrint:@"CouchDB"];
             */
            [aResult prettyPrint:@"CouchDB"];
        }
        else {
            NSLog(@"%@\n",aResult);
        }

	} // synchronized
}

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups
{
    ORSegmentGroup* group = [[ORSegmentGroup alloc] initWithName:@"SNO+ Detector" numSegments:kNumTubes mapEntries:[self setupMapEntries:0]];
	[self addGroup:group];
	[group release];
}

- (int)  maxNumSegments
{
	return kNumTubes;
}

- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		NSString* cardName = [aGroup segment:index objectForKey:@"kCardSlot"];
		NSString* chanName = [aGroup segment:index objectForKey:@"kChannel"];
		if(cardName && chanName && ![cardName hasPrefix:@"-"] && ![chanName hasPrefix:@"-"]){
			ORDataSet* aDataSet = nil;
			[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
			NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
			if([objs count]){
				NSArray* arrayOfHistos = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
				if([arrayOfHistos count]){
					id histoObj = [arrayOfHistos objectAtIndex:0];
					aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:@"SIS3302", @"Crate  0",
															[NSString stringWithFormat:@"Card %2d",[cardName intValue]], 
															[NSString stringWithFormat:@"Channel %2d",[chanName intValue]],
															nil]];
					
					[aDataSet doDoubleClick:nil];
				}
			}
		}
	}
}
- (NSString*) dataSetNameGroup:(int)aGroup segment:(int)index
{
	ORSegmentGroup* theGroup = [segmentGroups objectAtIndex:aGroup];
	
	NSString* crateName = [theGroup segment:index objectForKey:@"kCrate"];
	NSString* cardName  = [theGroup segment:index objectForKey:@"kCardSlot"];
	NSString* chanName  = [theGroup segment:index objectForKey:@"kChannel"];
	
	return [NSString stringWithFormat:@"SIS3302,Energy,Crate %2d,Card %2d,Channel %2d",[crateName intValue],[cardName intValue],[chanName intValue]];
}
#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"SNOPMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"SNOPDetectorLock";
}

- (id) sbcLink
{
    NSArray* theSBCs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORVmecpuModel")];
    //NSLog(@"Found %d SBCs.\n", theSBCs.count);
    for(id anSBC in theSBCs)
    {
        return [anSBC sbcLink];
    }
    return nil;
}

- (NSString*) experimentDetailsLock
{
	return @"SNOPDetailsLock";
}

- (void) setViewType:(int)aViewType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setViewType:aViewType];
	viewType = aViewType;
}

- (int) viewType
{
	return viewType;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:viewType forKey:@"viewType"];

    //CouchDB
    [encoder encodeObject:self.orcaDBUserName forKey:@"ORSNOPModelOrcaDBUserName"];
    [encoder encodeObject:self.orcaDBPassword forKey:@"ORSNOPModelOrcaDBPassword"];
    [encoder encodeObject:self.orcaDBName forKey:@"ORSNOPModelOrcaDBName"];
    [encoder encodeInt32:self.orcaDBPort forKey:@"ORSNOPModelOrcaDBPort"];
    [encoder encodeObject:self.orcaDBIPAddress forKey:@"ORSNOPModelOrcaDBIPAddress"];
    [encoder encodeObject:self.debugDBUserName forKey:@"ORSNOPModelDebugDBUserName"];
    [encoder encodeObject:self.debugDBPassword forKey:@"ORSNOPModelDebugDBPassword"];
    [encoder encodeObject:self.debugDBName forKey:@"ORSNOPModelDebugDBName"];
    [encoder encodeInt32:self.debugDBPort forKey:@"ORSNOPModelDebugDBPort"];
    [encoder encodeObject:self.debugDBIPAddress forKey:@"ORSNOPModelDebugDBIPAddress"];

    //ECA
    [encoder encodeInt:[self ECA_pattern] forKey:@"SNOPECApattern"];
    [encoder encodeObject:[self ECA_type] forKey:@"SNOPECAtype"];
    [encoder encodeInt:[self ECA_tslope_pattern] forKey:@"SNOPECAtslppattern"];
    [encoder encodeInt:[self ECA_nevents] forKey:@"SNOPECANEvents"];
    [encoder encodeObject:[self ECA_rate] forKey:@"SNOPECAPulserRate"];

    //Settings
    [encoder encodeObject:[self mtcHost] forKey:@"mtcHost"];
    [encoder encodeInt:[self mtcPort] forKey:@"mtcPort"];

    [encoder encodeObject:[self xl3Host] forKey:@"xl3Host"];
    [encoder encodeInt:[self xl3Port] forKey:@"xl3Port"];

    [encoder encodeObject:[self dataHost] forKey:@"dataHost"];
    [encoder encodeInt:[self dataPort] forKey:@"dataPort"];

    [encoder encodeObject:[self logHost] forKey:@"logHost"];
    [encoder encodeInt:[self logPort] forKey:@"logPort"];

}

- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
	if([aString length] == 0)return @"Not Mapped";
	
	NSString* finalString = @"";
	NSArray* parts = [aString componentsSeparatedByString:@"\n"];
	finalString = [finalString stringByAppendingString:@"\n-----------------------\n"];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Detector" parts:parts]];
	finalString = [finalString stringByAppendingString:@"-----------------------\n"];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" CardSlot" parts:parts]];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Channel" parts:parts]];
	finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Threshold" parts:parts]];
	finalString = [finalString stringByAppendingString:@"-----------------------\n"];
	return finalString;
}

- (NSString*) getPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound) return aLine;
	}
	return @"";
}

#pragma mark ¥¥¥DataTaker
- (void) setDataIds:(id)assigner
{
    [self setRhdrDataId:[assigner assignDataIds:kLongForm]];
    [self setEpedDataId:[assigner assignDataIds:kLongForm]];
}

- (void) syncDataIdsWith:(id)anotherObj
{
	[self setRhdrDataId:[anotherObj rhdrDataId]];
	[self setEpedDataId:[anotherObj epedDataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"SNOPModel"];
}

- (NSDictionary*) dataRecordDescription
{
	NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"SNOPDecoderForRHDR", @"decoder",
                                 [NSNumber numberWithLong:[self rhdrDataId]], @"dataId",
                                 [NSNumber numberWithBool:NO],	@"variable",
                                 [NSNumber numberWithLong:20], @"length",
                                 nil];
	[dataDictionary setObject:aDictionary forKey:@"snopRhdrBundle"];
    
	NSDictionary* bDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"SNOPDecoderForEPED", @"decoder",
                                 [NSNumber numberWithLong:[self epedDataId]], @"dataId",
                                 [NSNumber numberWithBool:NO], @"variable",
                                 [NSNumber numberWithLong:11], @"length",
                                 nil];
	[dataDictionary setObject:bDictionary forKey:@"snopEpedBundle"];
    
	return dataDictionary;
}


#pragma mark ¥¥¥SnotDbDelegate

- (ORCouchDB*) orcaDbRef:(id)aCouchDelegate
{
    ORCouchDB* result = [ORCouchDB couchHost:self.orcaDBIPAddress
                                        port:self.orcaDBPort
                                    username:self.orcaDBUserName
                                         pwd:self.orcaDBPassword
                                    database:self.orcaDBName
                                    delegate:self];

    if (aCouchDelegate)
        [result setDelegate:aCouchDelegate];
    
    return [[result retain] autorelease];
}

- (ORCouchDB*) orcaDbRefWithEntryDB:(id)aCouchDelegate withDB:(NSString*)entryDB;
 {

     ORCouchDB* result = [ORCouchDB couchHost:self.orcaDBIPAddress
                                         port:self.orcaDBPort
                                     username:self.orcaDBUserName
                                          pwd:self.orcaDBPassword
                                     database:entryDB
                                     delegate:self];
     
     if (aCouchDelegate)
         [result setDelegate:aCouchDelegate];
 
     return [[result retain] autorelease];
 }

- (ORCouchDB*) debugDBRef:(id) aCouchDelegate
{
    ORCouchDB* result = [ORCouchDB couchHost:self.debugDBIPAddress
                                        port:self.debugDBPort
                                    username:self.debugDBUserName
                                         pwd:self.debugDBPassword
                                    database:self.debugDBName
                                    delegate:self];

    if (aCouchDelegate)
        [result setDelegate:aCouchDelegate];
    
    return [[result retain] autorelease];
}


#pragma mark ¥¥¥OrcaScript helpers


- (void) zeroPedestalMasks
{
    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")]
     makeObjectsPerformSelector:@selector(zeroPedestalMasks)];
}

- (void) updatePedestalMasks:(unsigned int)pattern
{
    
    unsigned int** pt_step = (unsigned int**) pattern;
    NSLog(@"aaa 0x%08x\n", pt_step);
    
    //unsigned int* pt_step_crate = pt_step[0];
    
}

- (void)hvMasterTriggersOFF
{
    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(setIsPollingXl3:) withObject:NO];
    
    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(hvTriggersOFF)];
}

- (void) getSmellieRunListInfo
{
    //Collect a series of objects from the ORMTCModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if([objs count]){
        //Initialise the MTCModal
        ELLIEModel* anELLIEModel = [objs objectAtIndex:0];
        
        //NSMutableDictionary *state = [[NSMutableDictionary alloc] initWithDictionary:[anELLIEModel pullEllieCustomRunFromDB:@"smellie"]];
        
        NSString *requestString = [NSString stringWithFormat:@"_design/smellieMainQuery/_view/pullEllieRunHeaders"];
        
        [[anELLIEModel generalDBRef:@"smellie"] getDocumentId:requestString tag:@"kSmellieRunHeaderRetrieved"];
        
        [self setSmellieDBReadInProgress:YES];
        [self performSelector:@selector(smellieDocumentsRecieved) withObject:nil afterDelay:10.0];
    }
    else {
        NSLogColor([NSColor redColor], @"Must have an ELLIE object in the configuration\n");
    }
    
}

//complete this after the smellie documents have been recieved 
-(void)smellieDocumentsRecieved
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(smellieDocumentsRecieved) object:nil];
    if (![self smellieDBReadInProgress]) { //killed already
        return;
    }
    
    [self setSmellieDBReadInProgress:NO];
    
}

-(void) parseSmellieRunHeaderDoc:(id)aResult
{
    unsigned int i,cnt = [[aResult objectForKey:@"rows"] count];
    
    NSMutableDictionary *tmp = [[NSMutableDictionary alloc] init];
    
    for(i=0;i<cnt;i++){
        NSMutableDictionary* smellieRunHeaderDocIterator = [[[aResult objectForKey:@"rows"] objectAtIndex:i] objectForKey:@"value"];
        NSString *keyForSmellieDocs = [NSString stringWithFormat:@"%u",i];
        [tmp setObject:smellieRunHeaderDocIterator forKey:keyForSmellieDocs];
    }

    [self setSmellieRunHeaderDocList:tmp];
    [tmp release];
    
    [self setSmellieDocUploaded:YES];
}

/*-(void)setSmellieRunNameLabel:(NSString*)aRunNameLabel
{
    [self setSmellieRunNameLabel:aRunNameLabel];
}*/


- (NSMutableDictionary*)smellieTestFct
{
    if([self smellieDocUploaded] == YES){
        return smellieRunHeaderDocList;
    }
    else{
        NSLog(@"Document no loaded yet\n");
        return nil;
    }
}

- (unsigned long) runTypeWord
{
    return runTypeWord;
}

- (void) setRunTypeWord:(unsigned long)aValue
{
    runTypeWord = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPRunTypeWordChangedNotification object: self];
}

- (unsigned long) lastRunTypeWord
{
    return lastRunTypeWord;
}

- (void) setLastRunTypeWord:(unsigned long)aValue
{
    lastRunTypeWord = aValue;
}

- (NSString*) lastRunTypeWordHex
{
    return lastRunTypeWordHex;
}

- (void) setLastRunTypeWordHex:(NSString*)aValue
{
    [lastRunTypeWordHex autorelease]; //MAH -- strings should be handled like this
    lastRunTypeWordHex = [aValue copy];
}

- (NSString*)standardRunType
{
    return standardRunType;
}

- (void) setStandardRunType:(NSString *)aValue
{
    [standardRunType autorelease];//MAH -- strings should be handled like this
    standardRunType = [aValue copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelSRChangedNotification object:self];
}

- (NSString*)standardRunVersion
{
    return standardRunVersion;
}

- (void) setStandardRunVersion:(NSString *)aValue
{
    [aValue retain];
    [standardRunVersion release];
    standardRunVersion = aValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelSRVersionChangedNotification object:self];
}

- (NSString*)lastStandardRunType
{
    return lastStandardRunType;
}

- (void) setLastStandardRunType:(NSString *)aValue
{
    [lastStandardRunType autorelease];//MAH -- strings should be handled like this
    lastStandardRunType = [aValue copy];
}

- (NSString*)lastStandardRunVersion
{
    return lastStandardRunVersion;
}

- (void) setLastStandardRunVersion:(NSString *)aValue
{
    [lastStandardRunVersion autorelease];//MAH -- strings should be handled like this
    lastStandardRunVersion = [aValue copy];
}

- (int)ECA_pattern
{
    return ECA_pattern;
}

- (void) setECA_pattern:(int)aValue
{
    ECA_pattern = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelRunsECAChangedNotification object:self];
}

- (NSString*)ECA_type
{
    return [NSString stringWithFormat:@"%@",ECA_type];
}

- (void) setECA_type:(NSString*)aValue
{
    if(aValue != ECA_type)
    {
        NSString* temp = ECA_type;
        ECA_type = [aValue retain];
        [temp release];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelRunsECAChangedNotification object:self];
    }
}

- (int)ECA_tslope_pattern
{
    return ECA_tslope_pattern;
}

- (void) setECA_tslope_pattern:(int)aValue
{
    ECA_tslope_pattern = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelRunsECAChangedNotification object:self];
}

- (int)ECA_nevents
{
    return ECA_nevents;
}

- (void) setECA_nevents:(int)aValue
{
    if(aValue <= 0) aValue = 1;
    ECA_nevents = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelRunsECAChangedNotification object:self];
}

- (NSNumber*)ECA_rate
{
    return ECA_rate;
}

- (void) setECA_rate:(NSNumber*)aValue
{
    ECA_rate = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelRunsECAChangedNotification object:self];
}

// Load Detector Settings from the DB into the Models
-(BOOL) loadStandardRun:(NSString*)runTypeName withVersion:(NSString*)runVersion
{

    //Alert the operator
    if(runTypeName == nil || runVersion == nil){
        NSLog(@"Please, set a valid name and click enter. \n");
        return false;
    }
    else if([runTypeName isEqualToString:@"DIAGNOSTIC"]){
        NSLog(@"Going to DIAGNOSTIC run: the trigger settings will not change \n",runTypeName, runVersion);
    }
    else{
        NSLog(@"Loading settings for standard run: %@ - Version: %@ ........ \n",runTypeName, runVersion);
    }

    //Get RC model
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* runControlModel;
    if ([objs count]) {
        runControlModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return 0;
    }
    //Get MTC model
    objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtc;
    if ([objs count]) {
        mtc = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return 0;
    }

    //Query the OrcaDB and get a dictionary with the parameters
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/%@/_design/standardRuns/_view/getStandardRuns?startkey=[\"%@\",\"%@\",{}]&endkey=[\"%@\",\"%@\",0]&descending=True&include_docs=True",[self orcaDBUserName],[self orcaDBPassword],[self orcaDBIPAddress],[self orcaDBPort],[self orcaDBName],runTypeName,runVersion,runTypeName,runVersion];

    NSString* urlStringScaped = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlStringScaped];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error =  nil;
    NSDictionary *detectorSettings = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];

    if(error) {
        NSLog(@"Error querying couchDB, please check the connection is correct: \n %@ \n", ret);
        return false;
    }
    
    //Load values
    @try{

        //Load run type word
        unsigned long nextruntypeword = [[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"run_type_word"] unsignedLongValue];
        unsigned long currentruntypeword = [runControlModel runType];
        //Do not touch the data quality bits
        currentruntypeword &= 0xFFE00000;
        nextruntypeword |= currentruntypeword;
        [runControlModel setRunType:nextruntypeword];
        
        //Do not load thresholds if in Diagnostic run
        if(nextruntypeword & kDiagnosticRunType) return true;

        //Load MTC thresholds
        [mtc setDbObject:[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[mtc getDBKeyByIndex:kNHit100HiThreshold]] forIndex:kNHit100HiThreshold];
        [mtc setDbObject:[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[mtc getDBKeyByIndex:kNHit100MedThreshold]] forIndex:kNHit100MedThreshold];
        [mtc setDbObject:[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[mtc getDBKeyByIndex:kNHit100LoThreshold]] forIndex:kNHit100LoThreshold];
        [mtc setDbObject:[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[mtc getDBKeyByIndex:kNHit20Threshold]] forIndex:kNHit20Threshold];
        [mtc setDbObject:[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[mtc getDBKeyByIndex:kNHit20LBThreshold]] forIndex:kNHit20LBThreshold];
        [mtc setDbObject:[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[mtc getDBKeyByIndex:kOWLNThreshold]] forIndex:kOWLNThreshold];
        [mtc setDbObject:[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[mtc getDBKeyByIndex:kESumLowThreshold]] forIndex:kESumLowThreshold];
        [mtc setDbObject:[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[mtc getDBKeyByIndex:kESumHiThreshold]] forIndex:kESumHiThreshold];
        [mtc setDbObject:[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[mtc getDBKeyByIndex:kOWLELoThreshold]] forIndex:kOWLELoThreshold];
        [mtc setDbObject:[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[mtc getDBKeyByIndex:kOWLEHiThreshold]] forIndex:kOWLEHiThreshold];
        [mtc setDbObject:[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[mtc getDBKeyByIndex:kNhit100LoPrescale]] forIndex:kNhit100LoPrescale];
        [mtc setDbObject:[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[mtc getDBKeyByIndex:kPulserPeriod]] forIndex:kPulserPeriod];
        
        //Load MTC GT Mask
        [mtc setDbObject:[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:[mtc getDBKeyByIndex:kGtMask]] forIndex:kGtMask];

        //Load the PED/PGT mode
        BOOL pedpgtmode = [[[[[detectorSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"PED_PGT_Mode"] boolValue];
        [mtc setIsPedestalEnabledInCSR:pedpgtmode];
        
        NSLog(@"Standard run %@ (%@) settings loaded. \n",runTypeName,runVersion);
        return true;
    }
    @catch (NSException *e) {
        NSLog(@"Error retrieving Standard Runs information: \n %@ \n", e);
        return false;
    }
    
}

//Save MTC settings in a Standard Run table in CouchDB for later use by the Run Scripts or the user
-(BOOL) saveStandardRun:(NSString*)runTypeName withVersion:(NSString*)runVersion
{
    
    //Check that runTypeName is properly set:
    if(runTypeName == nil || runVersion == nil){
        ORRunAlertPanel(@"Invalid Standard Run Name",@"Please, set a valid name in the popup menus and click enter",@"OK",nil,nil);
        return false;
    }
    else{
        BOOL cancel = ORRunAlertPanel([NSString stringWithFormat:@"Overwriting stored values for run \"%@\" with version \"%@\"", runTypeName,runVersion],@"Is this really what you want?",@"Cancel",@"Yes, Save it",nil);
        if(cancel) return false;
    }
    NSLog(@"Saving settings for Standard Run: %@ - Version: %@ ........ \n",runTypeName,runVersion);

    //Get RC model
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* runControlModel;
    if ([objs count]) {
        runControlModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return 0;
    }
    //Get MTC model
    objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtc;
    if ([objs count]) {
        mtc = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return 0;
    }

    //Build run table
    NSMutableDictionary *detectorSettings = [NSMutableDictionary dictionaryWithCapacity:200];
    
    [detectorSettings setObject:@"standard_run" forKey:@"type"];
    [detectorSettings setObject:runTypeName forKey:@"run_type"];
    [detectorSettings setObject:runVersion forKey:@"run_version"];
    NSNumber *date = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    [detectorSettings setObject:date forKey:@"time_stamp"];
    //Do not touch the data quality bits
    unsigned long currentRunTypeWord = [runControlModel runType];
    currentRunTypeWord &= ~0xFFE00000;
    [detectorSettings setObject:[NSNumber numberWithUnsignedLong:currentRunTypeWord] forKey:@"run_type_word"];

    //Save MTC/D parameters, trigger masks and MTC/A+ thresholds
    for (int iparam=0; iparam<kDbLookUpTableSize; iparam++) {
        [detectorSettings setObject:[mtc dbObjectByIndex:iparam] forKey:[mtc getDBKeyByIndex:iparam]];
    }
    //Save PED/PGT mode
    [detectorSettings setObject:[NSNumber numberWithBool:[mtc isPedestalEnabledInCSR]] forKey:@"PED_PGT_Mode"];
    
    [[self orcaDbRefWithEntryDB:self withDB:@"orca"] addDocument:detectorSettings tag:@"kStandardRunDocumentAdded"];

    NSLog(@"%@ run saved as standard run. \n",runTypeName);
    return true;

}

//Ship GUI settings to hardware
-(void) loadSettingsInHW
{

    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtc;
    if ([objs count]) {
        mtc = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return;
    }

    @try{
        //Load MTC settings
        [mtc loadTheMTCADacs];
        [mtc setGlobalTriggerWordMask];
        [mtc setThePulserRate:[mtc dbFloatByIndex:kPulserPeriod]];
    }
    @catch(NSException *e){
        NSLogColor([NSColor redColor], @"Problem loading settings into Hardware: %@\n",[e reason]);
        return;
    }
    
    NSLogColor([NSColor redColor], @"Settings loaded in Hardware \n");

}

-(void) loadHighThresholds
{

    //Get RC model
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* runControlModel;
    if ([objs count]) {
        runControlModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return;
    }
    
    //Get MTC model
    objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtc;
    if ([objs count]) {
        mtc = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return;
    }
    //FIXME: Set correct hardcoded values!!!
    [mtc setDbObject:[NSNumber numberWithDouble:0.0] forIndex:kNHit100HiThreshold];
    [mtc setDbObject:[NSNumber numberWithDouble:0.0] forIndex:kNHit100MedThreshold];
    [mtc setDbObject:[NSNumber numberWithDouble:0.0] forIndex:kNHit100LoThreshold];
    [mtc setDbObject:[NSNumber numberWithDouble:0.0] forIndex:kNHit20Threshold];
    [mtc setDbObject:[NSNumber numberWithDouble:0.0] forIndex:kNHit20LBThreshold];
    [mtc setDbObject:[NSNumber numberWithDouble:0.0] forIndex:kOWLNThreshold];
    [mtc setDbObject:[NSNumber numberWithDouble:0.0] forIndex:kESumLowThreshold];
    [mtc setDbObject:[NSNumber numberWithDouble:0.0] forIndex:kESumHiThreshold];
    [mtc setDbObject:[NSNumber numberWithDouble:0.0] forIndex:kOWLELoThreshold];
    [mtc setDbObject:[NSNumber numberWithDouble:0.0] forIndex:kOWLEHiThreshold];
    [mtc setDbObject:[NSNumber numberWithDouble:100.0] forIndex:kNhit100LoPrescale];
    [mtc setDbObject:[NSNumber numberWithDouble:0.0] forIndex:kPulserPeriod];
    [runControlModel setRunType:0x0]; //Zero run type word since this run is not valid

    [self loadSettingsInHW];

}

@end


@implementation SNOPModel (private)

- (NSString*) stringDateFromDate:(NSDate*)aDate
{
    NSDateFormatter* snotDateFormatter = [[NSDateFormatter alloc] init];
    [snotDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SS'Z'"];
    snotDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate* strDate;
    if (!aDate)
        strDate = [NSDate date];
    else
        strDate = aDate;
    NSString* result = [snotDateFormatter stringFromDate:strDate];
    [snotDateFormatter release];
    strDate = nil;
    return [[result retain] autorelease];
}

//iso formatted string from date
- (NSString*) stringUnixFromDate:(NSDate*)aDate
{
    //NSDateFormatter* snotDateFormatter = [[NSDateFormatter alloc] init];
    //[snotDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SS'Z'"];
    //snotDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate* strDate;
    if (!aDate)
        strDate = [NSDate date];
    else
        strDate = aDate;
    //strDate.date.timeIntervalSince1970
    NSString* result = [NSString stringWithFormat:@"%f",[strDate timeIntervalSince1970]];
    //[snotDateFormatter release];
    strDate = nil;
    return [[result retain] autorelease];
}


//rfc2822 formatted string from date
- (NSString*) rfc2822StringDateFromDate:(NSDate*)aDate
{
    NSDateFormatter* snotDateFormatter = [[NSDateFormatter alloc] init];
    [snotDateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
    snotDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate* strDate;
    if (!aDate) strDate = [NSDate date];
    else        strDate = aDate;
    NSString* result = [snotDateFormatter stringFromDate:strDate];
    [snotDateFormatter release];
    return [[result retain] autorelease];
}

- (void) _runDocumentWorker
{
    NSAutoreleasePool* runDocPool   = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:100];
    
    unsigned int run_number = 0;
    NSMutableString* runStartString = [NSMutableString string];
    NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* rc = nil;
	if([runObjects count]){
        rc = [runObjects objectAtIndex:0];
        run_number = [rc runNumber];
    }
    
    //Collect a series of objects from the ORMTCModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    
    //Initialise the MTCModal
    ORMTCModel* aMTCcard = [objs objectAtIndex:0];
    
    NSNumber* runNumber = [NSNumber numberWithUnsignedInt:run_number];

    [runDocDict setObject:@"run" forKey:@"type"];
    [runDocDict setObject:[NSNumber numberWithUnsignedLong:[aMTCcard mtcStatusGTID]] forKey:@"start_gtid"];
    [runDocDict setObject:[NSNumber numberWithUnsignedLong:[self runTypeWord]] forKey:@"run_type"];
    [runDocDict setObject:[NSNumber numberWithUnsignedInt:0] forKey:@"version"];
    [runDocDict setObject:[NSNumber numberWithDouble:[[self stringUnixFromDate:nil] doubleValue]] forKey:@"timestamp_start"];
    [runDocDict setObject:[self rfc2822StringDateFromDate:nil] forKey:@"sudbury_time_start"];
    [runDocDict setObject:runNumber forKey:@"run"];
    [runDocDict setObject:@"starting" forKey:@"run_status"];
    
    //[runDocDict setObject:runStartString forKey:@"run_start"];
    [runDocDict setObject:@"" forKey:@"timestamp_end"];
    [runDocDict setObject:@"" forKey:@"sudbury_time_end"];
    //[runDocDict setObject:@"" forKey:@"run_stop"];

    self.runDocument = runDocDict;
    
    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRef:self] addDocument:runDocDict tag:kOrcaRunDocumentAdded];
    }
    
    //wait for main thread to receive acknowledgement from couchdb
    NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow:2.0];
    while ([timeout timeIntervalSinceNow] > 0 && ![self.runDocument objectForKey:@"_id"]) {
        [NSThread sleepForTimeInterval:0.1];
    }
    
    //if failed emit alarm and give up
    runDocDict = [[[self runDocument] mutableCopy] autorelease];
    if (rc) {
        NSDate* runStart = [[[rc startTime] copy] autorelease];
        [runStartString setString:[self stringDateFromDate:runStart]];
    }
    [runDocDict setObject:@"in progress" forKey:@"run_status"];
        

    //self.runDocument = runDocDict;
    
    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRef:self] updateDocument:runDocDict documentId:[runDocDict objectForKey:@"_id"] tag:kOrcaRunDocumentUpdated];
    }
    
    NSMutableDictionary* configDocDict = [NSMutableDictionary dictionaryWithCapacity:1000];
    
    //Pulling all the MTC Values
    NSNumber * mtcFineDelay         = [NSNumber numberWithUnsignedLong:[aMTCcard getMTC_FineDelay]];
    NSNumber * mtcPedWidth          = [NSNumber numberWithUnsignedLong:[aMTCcard getMTC_PedWidth]];
    NSNumber * mtcGTWordMask        = [NSNumber numberWithUnsignedLong:[aMTCcard getMTC_GTWordMask]];
    
    NSNumber * mtcCoarseDelay       = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kCoarseDelay]];
    NSNumber * mtcPedestalWidth     = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kPedestalWidth]];
    NSNumber * mtcNhit100LoPrescale = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kNhit100LoPrescale]];
    NSNumber * mtcPulserPeriod      = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kPulserPeriod]];
    NSNumber * mtcLow10MhzClock     = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kLow10MhzClock]];
    NSNumber * mtcFineSlope         = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kFineSlope]];
    NSNumber * mtcMinDelayOffset    = [NSNumber numberWithUnsignedLong:[aMTCcard dbFloatByIndex:kMinDelayOffset]];
    
    //Important not to help complete this work
    //dbFloatByIndex - this function will get the value on the screen (at least for the mtc and
    //read this from what is placed into the GUI (I think)
    //An example:
	//[pedestalWidthField		setFloatValue:	[model dbFloatByIndex: kPedestalWidth]];

    //The above example actually set the values in the GUI. But for loading into the database
    //it is more important to think about the [modeal dbFloatByIndex: kPedestalWidth] information
    //this is actualy looking up the model information and using it.
    
    //Extra values to load into the DB
    //load the nhit values
    //NSMatrix * nhitMatrix = nil;
    NSMutableDictionary *nhitMtcaArray = [NSMutableDictionary dictionaryWithCapacity:100];

	int col,row;
	float displayValue=0;
	for(col=0;col<4;col++){
        
        NSMutableDictionary * tempArray = [NSMutableDictionary dictionaryWithCapacity:100];
        
		for(row=0;row<6;row++){
            
			int index = kNHit100HiThreshold + row + (col * 6);
            
			if(col == 0){
	 			int type = [aMTCcard nHitViewType];
				
                if(type == kNHitsViewRaw) {
					displayValue = [aMTCcard dbFloatByIndex: index];
				}
				
                else if(type == kNHitsViewmVolts) {
					float rawValue = [aMTCcard dbFloatByIndex: index];
					displayValue = [aMTCcard rawTomVolts:rawValue];
				}
				
                else if(type == kNHitsViewNHits) {
					int rawValue    = [aMTCcard dbFloatByIndex: index];
					float mVolts    = [aMTCcard rawTomVolts:rawValue];
					float dcOffset  = [aMTCcard dbFloatByIndex:index + kNHitDcOffset_Offset];
					float mVperNHit = [aMTCcard dbFloatByIndex:index + kmVoltPerNHit_Offset];
					displayValue    = [aMTCcard mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
				}
			}
			else displayValue = [aMTCcard dbFloatByIndex: index];
            
            NSNumber * valueToDisplay = [NSNumber numberWithFloat:displayValue];
            switch (row){
                case 0: [tempArray setObject:valueToDisplay forKey:@"nhit_100_hi"];  break;
                case 1: [tempArray setObject:valueToDisplay forKey:@"nhit_100_med"]; break;
                case 2: [tempArray setObject:valueToDisplay forKey:@"nhit_100_lo"];  break;
                case 3: [tempArray setObject:valueToDisplay forKey:@"nhit_20"];      break;
                case 4: [tempArray setObject:valueToDisplay forKey:@"nhit_20_lo"];   break;
                case 5: [tempArray setObject:valueToDisplay forKey:@"owln"];         break;
                default: NSLog(@"OrcaDB::Cannot write the Mtca Nhit DAC Values to the OrcaDB"); break;
            }
    
		}
        
        //Do I need to release the memory for the temporary Array?
        //This will reveal itself during my analysis for the new Array
        switch(col){
            case 0: [nhitMtcaArray setObject:tempArray forKey:@"threshold_value"];  break;
            case 1: [nhitMtcaArray setObject:tempArray forKey:@"mv_per_adc"];       break;
            case 2: [nhitMtcaArray setObject:tempArray forKey:@"mv_per_nhit"];      break;
            case 3: [nhitMtcaArray setObject:tempArray forKey:@"dc_offset"];        break;
            default:  NSLog(@"OrcaDB::Cannot write the Mtca Nhit DAC values to the OrcaDB"); break;
        }
	}
    
     //now the esum values
    NSMutableDictionary *esumArray = [NSMutableDictionary dictionaryWithCapacity:100];
    
    for(col=0;col<4;col++){
         
        NSMutableDictionary * tempArray = [NSMutableDictionary dictionaryWithCapacity:100];
         
         for(row=0;row<4;row++){
            int index = kESumLowThreshold + row + (col * 4);
             if(col == 0){
                 int type = [aMTCcard eSumViewType];
                 if(type == kESumViewRaw) {
                     displayValue = [aMTCcard dbFloatByIndex: index];
                 }
                 else if(type == kESumViewmVolts) {
                     float rawValue = [aMTCcard dbFloatByIndex: index];
                     displayValue = [aMTCcard rawTomVolts:rawValue];
                 }
                 else if(type == kESumVieweSumRel) {
                     float dcOffset = [aMTCcard dbFloatByIndex:index + kESumDcOffset_Offset];
                     displayValue = dcOffset - [aMTCcard dbFloatByIndex: index];
                 }
                 else if(type == kESumViewpC) {
                     int rawValue   = [aMTCcard dbFloatByIndex: index];
                     float mVolts   = [aMTCcard rawTomVolts:rawValue];
                     float dcOffset = [aMTCcard dbFloatByIndex:index + kESumDcOffset_Offset];
                     float mVperpC  = [aMTCcard dbFloatByIndex:index + kmVoltPerpC_Offset];
                     displayValue   = [aMTCcard mVoltsTopC:mVolts dcOffset:dcOffset mVperpC:mVperpC];
                 }
             }
             
             else displayValue = [aMTCcard dbFloatByIndex: index];
             
             NSNumber * valueToDisplay = [NSNumber numberWithFloat:displayValue];
             switch (row){
                 case 0: [tempArray setObject:valueToDisplay forKey:@"esum_hi"]; break;
                 case 1: [tempArray setObject:valueToDisplay forKey:@"esum_lo"]; break;
                 case 2: [tempArray setObject:valueToDisplay forKey:@"owle_hi"]; break;
                 case 3: [tempArray setObject:valueToDisplay forKey:@"owle_lo"]; break;
                 default: NSLog(@"OrcaDB::Cannot write the Mtca Esum DAC values to the OrcaDB"); break;
             }
             
         }
        switch(col){
            case 0: [esumArray setObject:tempArray forKey:@"threshold_value"];  break;
            case 1: [esumArray setObject:tempArray forKey:@"mv_per_adc"];       break;
            case 2: [esumArray setObject:tempArray forKey:@"mv_per_nhit"];      break;
            case 3: [esumArray setObject:tempArray forKey:@"dc_offset"];        break;
            default: break;
        }
    }
        
    //Get the trigger information and place into the DB
    //NSMutableDictionary * triggerMask = [NSMutableDictionary dictionaryWithCapacity:100];
    
    //Respective arrays that will be used to fill the main array 
    NSMutableArray * gtMask = [NSMutableArray arrayWithCapacity:100];
    //NSMutableDictionary *gtMask = [NSMutableDictionary dictionaryWithCapacity:100];
    NSMutableArray * gtCrateMask = [NSMutableArray arrayWithCapacity:100];
    NSMutableArray * pedCrateMask = [NSMutableArray arrayWithCapacity:100];
    
    //Collect a series of objects from the ORMTCController
    /*NSArray*  controllerObjs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCController")];
    
    //Initialise the MTCModal
    ORMTCController* aMTCController = [controllerObjs objectAtIndex:0];
    
    NSMutableDictionary * triggerMaskMatricies = [aMTCController getMatriciesFromNib];

    //Unpack all the Matricies from the Nib
    NSMatrix * globalTriggerMaskMatrix = [triggerMaskMatricies objectForKey:@"globalTriggerMaskMatrix"];*/
        
    int i;
	int maskValue = [aMTCcard dbIntByIndex: kGtMask];
    //NSString * triggerOn = @"On";
    //NSString * triggerOff = @"Off";
    
    NSNumber *triggerOn = [NSNumber numberWithInt:1];
    NSNumber *triggerOff = [NSNumber numberWithInt:0];
    
    
    //add each mask to the main gtMask mutableArray §
	for(i=0;i<26;i++){
        NSNumber * maskValueToWrite = [NSNumber numberWithInt:maskValue & (1<<i)];
        if ([maskValueToWrite intValue] > 0){
            [gtMask insertObject:triggerOn atIndex:i];
        }
        else{
            [gtMask insertObject:triggerOff atIndex:i];
        }
        
        //Keep this idea for a future date.
        //This idea is to take the GUI binding titles and read those in as the arguments for the trigger. Perhaps
        //these would change and it would be better to force the user to use bits???? Keep the database constant?

        //Alternative method
        
        /*NSButtonCell * cell = [globalTriggerMaskMatrix cellAtRow:i column:0];
        NSString *cellTitle = [cell title];
        
        if ([maskValueToWrite intValue] > 0){
            [gtMask setObject:@"triggerOn" forKey:cellTitle];
        }
        else{
            [gtMask setObject:@"triggerOff" forKey:cellTitle];
        }*/
        
	}
    
	maskValue = [aMTCcard dbIntByIndex: kGtCrateMask];
	for(i=0;i<25;i++){
        NSNumber * maskValueToWrite = [NSNumber numberWithInt:maskValue & (1<<i)];        
        if ([maskValueToWrite intValue] > 0){
            [gtCrateMask insertObject:triggerOn atIndex:i];
        }
        else{
            [gtCrateMask insertObject:triggerOff atIndex:i];
        }
	}
    
	maskValue = [aMTCcard dbIntByIndex: kPEDCrateMask];
	for(i=0;i<25;i++){
        NSNumber * maskValueToWrite = [NSNumber numberWithInt:maskValue & (1<<i)];        
        if ([maskValueToWrite intValue] > 0){
            [pedCrateMask insertObject:triggerOn atIndex:i];
        }
        else{
            [pedCrateMask insertObject:triggerOff atIndex:i];
        }
	}
    
    
    //TODO: REMOVE THIS AND ABOVE CODE FOR READING TRIGGGER MASK
    //Combine the mutable arrays containing all the triggers into the Dictionary;
    /*[triggerMask setObject:gtMask forKey:@"global_trigger_mask"];
    [triggerMask setObject:gtCrateMask forKey:@"crate_trigger_mask"];
    [triggerMask setObject:pedCrateMask forKey:@"pedestal_trigger_mask"];*/
    
    
    //Fill an array with mtc information 
    NSMutableDictionary * mtcArray = [NSMutableDictionary dictionaryWithCapacity:20];
    [mtcArray setObject:mtcCoarseDelay       forKey:@"coarse_delay"];
    [mtcArray setObject:mtcFineDelay         forKey:@"fine_delay"];
    [mtcArray setObject:mtcPedWidth          forKey:@"ped_width"];
    [mtcArray setObject:mtcGTWordMask        forKey:@"gt_word_mask"];
    [mtcArray setObject:mtcPedestalWidth     forKey:@"pedestal_width"];
    [mtcArray setObject:mtcNhit100LoPrescale forKey:@"nhit100_lo_prescale"];
    [mtcArray setObject:mtcPulserPeriod      forKey:@"pulser_period"];
    [mtcArray setObject:mtcLow10MhzClock     forKey:@"low_10Mhz_clock"];
    [mtcArray setObject:mtcFineSlope         forKey:@"fine_slope"];
    [mtcArray setObject:mtcMinDelayOffset    forKey:@"min_delay_offset"];
    [mtcArray setObject:nhitMtcaArray        forKey:@"mtca_nhit_matrix"];
    [mtcArray setObject:[NSNumber numberWithFloat:[aMTCcard dbFloatByIndex:kLockOutWidth]] forKey:@"lockout_width"];
    [mtcArray setObject:esumArray            forKey:@"mtca_esum_matrix"];
    //[mtcArray setObject:triggerMask forKey:@"trigger_masks"];
    
    [mtcArray setObject:[NSNumber numberWithBool:[aMTCcard isPedestalEnabledInCSR]] forKey:@"is_pedestal_enabled"];
    
    //Trigger masks
    [mtcArray setObject:[NSNumber numberWithInt:[aMTCcard dbIntByIndex: kGtMask]]       forKey:@"gt_mask"];
    [mtcArray setObject:[NSNumber numberWithInt:[aMTCcard dbIntByIndex: kGtCrateMask]]  forKey:@"crate_trigger_mask"];
    [mtcArray setObject:[NSNumber numberWithInt:[aMTCcard dbIntByIndex: kPEDCrateMask]] forKey:@"pedestal_trigger_mask"];
    
    
    //make an MTC document
    NSMutableDictionary* mtcDocDict = [NSMutableDictionary dictionaryWithCapacity:100];
    
    [mtcDocDict setObject:@"mtc"    forKey:@"doc_type"];
    [mtcDocDict setObject:[NSNumber numberWithUnsignedInt:0] forKey:@"version"];
    [mtcDocDict setObject:runNumber forKey:@"run"];
    [mtcDocDict setObject:mtcArray  forKey:@"mtc"];
    
    self.mtcConfigDoc = mtcDocDict;
    
    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRef:self] addDocument:mtcDocDict tag:kMtcRunDocumentAdded];
    }
    
    //FILL information from the Caen
    NSMutableDictionary* caenArray = [NSMutableDictionary dictionaryWithCapacity:100];
    NSArray* caenObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOCaenModel")];
    if([caenObjects count]){
        SNOCaenModel* theCaen        = [caenObjects objectAtIndex:0]; //there is only one Caen object
        NSMutableDictionary* ioArray    = [NSMutableDictionary dictionaryWithCapacity:20];
        [ioArray setObject:[NSNumber numberWithUnsignedLong:[theCaen frontPanelControlMask]] forKey:@"io_bit_mask"];
    
        
        //Build the components of the CAEN from the bitMask
        //These are ordered arrays so DO NOT change the ordering!!!!!!!!!
        NSArray* ioModeArray        = @[@"general_purpose",@"program",@"pattern"];
        NSArray* patternLatchArray  = @[@"internal_trigger",@"external_trigger"];
        NSArray* trigInArray        = @[@"nim",@"ttl"];
        NSArray* trigOutArray       = @[@"low_impedendce",@"high_impedence"];
        NSArray* lvdsArray          = @[@"in",@"out"];
        NSArray* trigOutModeArray   = @[@"normal",@"test_hi",@"test_low"];
        
        //deconstruct the bitMask used to describe the caen IO and recast the unsigned long variables as integer
        int ioMode, patternLatch, trigIn, trigOut, vds0, vds1, vds2, vds3, trigOutMode;
        ioMode       = (int)(([theCaen frontPanelControlMask] >> 6) & 0x3UL);
        patternLatch = (int)(([theCaen frontPanelControlMask] >> 9) & 0x1UL);
        trigIn       = (int)([theCaen frontPanelControlMask] & 0x1UL);
        trigOut      = (int)(([theCaen frontPanelControlMask] >> 1) & 0x1UL);
        trigOutMode  = (int)(([theCaen frontPanelControlMask] >> 14) & 0x3UL);
        
        //write the configuration of the lvdsArray
        vds0 = (int)(([theCaen frontPanelControlMask] >> 2) & 0x1UL);
        vds1 = (int)(([theCaen frontPanelControlMask] >> 3) & 0x1UL);
        vds2 = (int)(([theCaen frontPanelControlMask] >> 4) & 0x1UL);
        vds3 = (int)(([theCaen frontPanelControlMask] >> 5) & 0x1UL);
        
        NSMutableArray * lvdsDictionary = [NSMutableArray arrayWithCapacity:20];
        [lvdsDictionary setObject:[lvdsArray objectAtIndex:vds0] atIndexedSubscript:0];
        [lvdsDictionary setObject:[lvdsArray objectAtIndex:vds1] atIndexedSubscript:1];
        [lvdsDictionary setObject:[lvdsArray objectAtIndex:vds2] atIndexedSubscript:2];
        [lvdsDictionary setObject:[lvdsArray objectAtIndex:vds3] atIndexedSubscript:3];
        
        [ioArray setObject:lvdsDictionary                                   forKey:@"lvds_io_direction"];
        [ioArray setObject:[ioModeArray objectAtIndex:ioMode]               forKey:@"io_mode"];
        [ioArray setObject:[patternLatchArray objectAtIndex:patternLatch]   forKey:@"pattern_latch"];
        [ioArray setObject:[trigInArray objectAtIndex:trigIn]               forKey:@"trigger_clock_input_logic"];
        [ioArray setObject:[trigOutArray objectAtIndex:trigOut]             forKey:@"trigger_clock_output_logic"];
        [ioArray setObject:[trigOutModeArray objectAtIndex:trigOutMode]     forKey:@"trigger_output_mode"];
        [caenArray setObject:ioArray                                        forKey:@"io"];
        
        NSMutableDictionary* bufferInfo = [NSMutableDictionary dictionaryWithCapacity:20];
        [bufferInfo setObject:[NSNumber numberWithInt:(1024*1024./powf(2.,(float)[theCaen eventSize]) / 2)] forKey:@"event_size"];
        [bufferInfo setObject:[NSNumber numberWithUnsignedLong:([theCaen postTriggerSetting] * 4)]          forKey:@"post_trigger_size"];
        [bufferInfo setObject:[NSNumber numberWithUnsignedLong:([theCaen customSize] * 4)]                  forKey:@"custom_size"];
        [bufferInfo setObject:[NSNumber numberWithBool:[theCaen isCustomSize]]                              forKey:@"is_custom_size"];
        [bufferInfo setObject:[NSNumber numberWithBool:[theCaen isFixedSize]]                               forKey:@"fixed_event_size"];
        
        [caenArray setObject:bufferInfo forKey:@"buffer"];
        
        //Fetch the channel configuration information
        NSMutableDictionary* chanConfigInfo = [NSMutableDictionary dictionaryWithCapacity:20];
        int chanConfigToMaskBit[kNumChanConfigBits] = {1,3,4,6,11};
        [chanConfigInfo setObject:[NSNumber numberWithBool:(([theCaen channelConfigMask] >> chanConfigToMaskBit[0] ) & 0x1)] forKey:@"trigger_overlap"];
        [chanConfigInfo setObject:[NSNumber numberWithBool:(([theCaen channelConfigMask] >> chanConfigToMaskBit[1] ) & 0x1)] forKey:@"test_pattern"];
        [chanConfigInfo setObject:[NSNumber numberWithBool:(([theCaen channelConfigMask] >> chanConfigToMaskBit[2] ) & 0x1)] forKey:@"seq_memory_access"];
        [chanConfigInfo setObject:[NSNumber numberWithBool:(([theCaen channelConfigMask] >> chanConfigToMaskBit[3] ) & 0x1)] forKey:@"trig_on_under_threshold"];
        [caenArray setObject:chanConfigInfo forKey:@"channel_configuration"];
        
        //get the run mode of the CAEN ADC, there is a runMode mask which is 00, 01, 10, 11 and corresponds to the four options in the CAEN GUI
        NSArray* runModeArray = @[@"register_controlled",@"s_in_controller",@"s_in_gate",@"multi_board_sync"];
        int acquitionMode = (int)[theCaen acquisitionMode];
        [caenArray setObject:[NSString stringWithFormat:@"%@",[runModeArray objectAtIndex:acquitionMode]] forKey:@"run_mode"];
    
        NSMutableDictionary* channelInfo = [NSMutableDictionary dictionaryWithCapacity:20];
        int l;
        for(l=0;l<[theCaen numberOfChannels];l++){
            NSMutableDictionary* specificChannel = [NSMutableDictionary dictionaryWithCapacity:20];
            [specificChannel removeAllObjects];
            [specificChannel setObject:[NSNumber numberWithBool:(([theCaen enabledMask] >> l) & 0x1)]           forKey:@"enabled"];
            [specificChannel setObject:[NSNumber numberWithUnsignedShort:[theCaen threshold:l]]                 forKey:@"threshold"];
            [specificChannel setObject:[NSNumber numberWithFloat:[theCaen convertDacToVolts:[theCaen dac:l]]]   forKey:@"offset"];
            [specificChannel setObject:[NSNumber numberWithBool:(([theCaen triggerSourceMask] >> l) & 0x1UL)]   forKey:@"trigger_source"];
            [specificChannel setObject:[NSNumber numberWithBool:(([theCaen triggerOutMask] >> l) & 0x1UL)]      forKey:@"trigger_output"];
            [specificChannel setObject:[NSNumber numberWithUnsignedShort:[theCaen overUnderThreshold:l]]        forKey:@"over_under_threshold"];
            [channelInfo setObject:specificChannel                                                              forKey:[NSString stringWithFormat:@"%i",l]];
        }
        [caenArray setObject:channelInfo forKey:@"channels"];
        
        NSMutableDictionary *otherTrigInfo = [NSMutableDictionary dictionaryWithCapacity:20];
        [otherTrigInfo setObject:[NSNumber numberWithBool:(([theCaen triggerSourceMask] >> 30) & 0x1UL)]    forKey:@"external_trigger_enabled"];
        [otherTrigInfo setObject:[NSNumber numberWithBool:(([theCaen triggerSourceMask] >> 31) & 0x1UL)]    forKey:@"software_trigger_enabled"];
        [otherTrigInfo setObject:[NSNumber numberWithBool:(([theCaen triggerOutMask] >> 30) & 0x1UL)]       forKey:@"external_trigger_out"];
        [otherTrigInfo setObject:[NSNumber numberWithBool:(([theCaen triggerOutMask] >> 31) & 0x1UL)]       forKey:@"software_trigger_out"];
        [otherTrigInfo setObject:[NSNumber numberWithBool:[theCaen countAllTriggers]]                       forKey:@"count_all_triggers"];
        [otherTrigInfo setObject:[NSNumber numberWithUnsignedShort:[theCaen coincidenceLevel]]              forKey:@"nhit"];
        
        [caenArray setObject:otherTrigInfo forKey:@"extra_trigger"];

        [caenArray setObject:[NSNumber numberWithUnsignedShort:[theCaen enabledMask]]               forKey:@"enable_mask"];
        [caenArray setObject:[NSNumber numberWithUnsignedLong:[theCaen triggerSourceMask]]          forKey:@"trigger_source_mask"];
        [caenArray setObject:[NSNumber numberWithUnsignedLong:[theCaen triggerOutMask]]             forKey:@"trigger_out_mask"];
        [caenArray setObject:[NSNumber numberWithUnsignedShort:[theCaen coincidenceLevel]]          forKey:@"coincidence_level"];
        [caenArray setObject:[NSNumber numberWithUnsignedShort:[theCaen channelConfigMask]]         forKey:@"channel_config_mask"];
        [caenArray setObject:[NSNumber numberWithUnsignedLong:[theCaen numberBLTEventsToReadout]]   forKey:@"number_blt_events"];
        [caenArray setObject:[NSNumber numberWithBool:[theCaen continuousMode]]                     forKey:@"continuous_mode"];
        
        /*int l;
        for(l=0; l < [theCaen numberOfChannels]; l++){
            [caenArray setObject:[NSNumber numberWithUnsignedShort:[theCaen dac:l]] forKey:[NSString stringWithFormat:@"dac_ch_%d",l]];
            [caenArray setObject:[NSNumber numberWithUnsignedShort:[theCaen threshold:l]] forKey:[NSString stringWithFormat:@"thres_ch_%d",l]];
            [caenArray setObject:[NSNumber numberWithUnsignedShort:[theCaen overUnderThreshold:l]] forKey:[NSString stringWithFormat:@"over_thres_ch_%d",l]];
        }*/
    }
    
    //FILL THE DATA FROM EACH FRONT END CARD HERE !!!!!
    
    //Initialise a Dictionary to fill the Daughter Card information
    NSMutableDictionary * fecCardArray = [NSMutableDictionary dictionaryWithCapacity:200];
    
    //Build an empty array for all Fec32 arrays
    int c;
    for(c =0;c<kNumOfCrates;c++){
        NSMutableDictionary* boardsInSlots = [[NSMutableDictionary alloc] initWithCapacity:100];
        
        int slot;
        for(slot=0;slot<kNumSNOCrateSlots-2;slot++){
            [boardsInSlots setObject:@"" forKey:[NSString stringWithFormat:@"%i",slot]];
        }
        [fecCardArray setObject:boardsInSlots forKey:[NSString stringWithFormat:@"%i",c]];
        [boardsInSlots release];
    }
    
    //Gersende and Chris (Xl3 printing status)
    NSArray* xl3Objects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    
    NSMutableDictionary* allXl3Info = [NSMutableDictionary dictionaryWithCapacity:10];
    
    //loop through all xl3 instances in Orca
    for (id xl3 in xl3Objects) {
        
        NSMutableDictionary * crateXl3Info = [NSMutableDictionary dictionaryWithCapacity:10];
        [crateXl3Info setObject:[NSString stringWithFormat:@"%@",   [xl3 hvASwitch]?@"ON":@"OFF"]   forKey:@"hv_status_a"];
        [crateXl3Info setObject:[NSNumber numberWithUnsignedLong:   [xl3 hvNominalVoltageA]]        forKey:@"hv_nominal_a"];
        [crateXl3Info setObject:[NSNumber numberWithFloat:          [xl3 hvAVoltageReadValue]]      forKey:@"hv_voltage_read_value_a"];
        [crateXl3Info setObject:[NSNumber numberWithFloat:          [xl3 hvACurrentReadValue]]      forKey:@"hv_current_read_value_a"];
        [crateXl3Info setObject:[NSNumber numberWithInt:            [xl3 xl3Mode]]                  forKey:@"xl3_mode"];
        [crateXl3Info setObject:[NSNumber numberWithUnsignedLong:   ([xl3 relayMask]>>32)&0xFFFFFFFF]            forKey:@"hv_relay_high_mask"];
        [crateXl3Info setObject:[NSNumber numberWithUnsignedLong:   [xl3 relayMask]&0xFFFFFFFF]             forKey:@"hv_relay_low_mask"];
        
        if([xl3 crateNumber] == 16) {
            
            [crateXl3Info setObject:[NSString stringWithFormat:@"%@",   [xl3 hvBSwitch]?@"ON":@"OFF"]   forKey:@"hv_status_b"];
            [crateXl3Info setObject:[NSNumber numberWithUnsignedLong:   [xl3 hvNominalVoltageB]]        forKey:@"hv_nominal_b"];
            [crateXl3Info setObject:[NSNumber numberWithFloat:          [xl3 hvBVoltageReadValue]]      forKey:@"hv_voltage_read_value_b"];
            [crateXl3Info setObject:[NSNumber numberWithFloat:          [xl3 hvBCurrentReadValue]]      forKey:@"hv_current_read_value_b"];
            
        }
    
        NSString * crateNumberAsString = [NSString stringWithFormat:@"%i",[xl3 crateNumber]];
        [allXl3Info setObject:crateXl3Info forKey:crateNumberAsString];
    
    }
    
    //Loop over all the FEC cards
    NSArray * fec32ControllerObjs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];
    
    //Count all Fec32 Cards on the DAQ
    //int numberFec32Cards = 2; //PLACE THIS IN LATER: [fec32ControllerObjs count];
    int numberFec32Cards = [fec32ControllerObjs count];
    
    //Iterate through all of the Fec32 Cards
    for(i=0;i<numberFec32Cards;i++){
            
        ORFec32Model * aFec32Card = [fec32ControllerObjs objectAtIndex:i];
        
        //Fec 32 Card Iterator
        NSMutableDictionary* fec32Iterator = [NSMutableDictionary dictionaryWithCapacity:20];
        
        //Get the Mother Board Information
        [fec32Iterator setObject:[aFec32Card pullFecForOrcaDB] forKey:@"mother_board"];
        
        //Variable used to loop through all the current settings
        NSMutableDictionary * daughterCardIterator = [NSMutableDictionary dictionaryWithCapacity:20];
    
        //Get the Fec Daughter Cards associated with the actual
        int j;
        for(j=0;j<kNumSNODaughterCards;j++){
			ORFecDaughterCardModel* dc = [[OROrderedObjManager for:aFec32Card] objectInSlot:j];
    
            //Fill the daughter card iterator
            //daughterCardIterator = [dc pullFecDaughterInformationForOrcaDB];
            
            //[NSString stringWithFormat:@"%i",j]
            NSString* daughterBoardSlot = [NSString stringWithFormat:@"%i",[dc slot]];
            
            //Place the information for each daughter card into the main daughter card array
            [daughterCardIterator setObject:[dc pullFecDaughterInformationForOrcaDB] forKey:daughterBoardSlot];
        }
        
        //Fill the daughter card information into the mother board information
        [fec32Iterator setObject:daughterCardIterator forKey:@"daughter_board"];
        
        //[fecCardArray setObject:fec32Iterator forKey:[NSString stringWithFormat:@"%i",i]];
        //[fecCardArray setObject:fec32Iterator forKey:[fecCardArray valueForKeyPath:crateNumberString]];
        
        //this works but only places in the first slot
        NSString *crateNumberString = [NSString stringWithFormat:@"%i",[aFec32Card crateNumber]];
        NSString *slotNumberString  = [NSString stringWithFormat:@"%i",15-([aFec32Card slot]-1)];
        //[fecCardArray setObject:fec32Iterator forKey:crateNumberString];
        
        //NSLog(@"%@",[fecCardArray objectForKey:crateNumberStringv2]);
        [[fecCardArray objectForKey:crateNumberString] setObject:fec32Iterator forKey:slotNumberString];

    }//end of looping through all the Fec32 Cards
    
    //fetching the svn version used for this DAQ build 
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* svnVersionPath = [[NSBundle mainBundle] pathForResource:@"svnversion"ofType:nil];
    NSMutableString* svnVersion = [NSMutableString stringWithString:@""];
    if([fm fileExistsAtPath:svnVersionPath])svnVersion = [NSMutableString stringWithContentsOfFile:svnVersionPath encoding:NSASCIIStringEncoding error:nil];
    if([svnVersion hasSuffix:@"\n"]){
        [svnVersion replaceCharactersInRange:NSMakeRange([svnVersion length]-1, 1) withString:@""];
    }
    
    //Fill the configuration document with information
    [configDocDict setObject:@"configuration" forKey:@"type"];
    [configDocDict setObject:[NSNumber numberWithDouble:[[self stringDateFromDate:nil] doubleValue]] forKey:@"timestamp"];
    [configDocDict setObject:@"0" forKey:@"config_version"]; //need to add in an update for this
    
     NSNumber * runNumberForConfig = [NSNumber numberWithUnsignedLong:[rc runNumber]];
    [configDocDict setObject:runNumberForConfig forKey:@"run"];
    
    [configDocDict setObject:svnVersion forKey:@"daq_version_build"];
    
    [configDocDict setObject:mtcArray forKey:@"mtc"];

    //add the xl3 information to configuration document
    [configDocDict setObject:allXl3Info forKey:@"xl3s"];

    //reorganise the Fec32 cards to make it easier for couchDB

    //Loop through all the crates in the detector
    /*int c;
    NSMutableDictionary *organisedFec32Information = [[NSMutableDictionary alloc] initWithCapacity:100];
    for(c=0;c<kNumOfCrates;c++){
        
        //String of the crate being used
        NSString * stringValueOfCrate = [NSString stringWithFormat:@"%i",c];
        
        //Loop through all the motherBoards and check to see it this motherboard id is in a given crate number
        NSMutableDictionary *motherBoardsInCrate = [[NSMutableDictionary alloc] initWithCapacity:100];

        for(id key in fecCardArray){
            
            NSNumber *currentCrateNumber = [NSNumber numberWithInt:[[fecCardArray objectForKey:@"mother_board"] objectForKey:@"crate_number"]];
            NSNumber *currentSlotNumber = [NSNumber numberWithInt:[[fecCardArray objectForKey:@"mother_board"]objectForKey:@"slot"]];
            
            NSMutableDictionary * subDictionary = [[NSMutableDictionary alloc] initWithCapacity:100];
            [subDictionary setObject:fecCardArray forKey:key];
            
            NSString *slotIDForMotherBoard = [NSString stringWithFormat:@"%@",[currentSlotNumber stringValue]];
            
            //if this particular mother board is in the current crate in the loop 
            if(c == [currentCrateNumber intValue]){
                [motherBoardsInCrate setObject:subDictionary forKey:slotIDForMotherBoard];
            }
        }
        
        [organisedFec32Information setObject:motherBoardsInCrate forKey:stringValueOfCrate];        
        
    }*/
    
    //NSLog(@"%@",organisedFec32Information);
    
    [configDocDict setObject:fecCardArray forKey:@"fec32_card"];
    [configDocDict setObject:caenArray forKey:@"caen"];
    [configDocDict setObject:[self ECA_type] forKey:@"eca_type"];
    
    //collect the objects that correspond to the CAEN
    
    //add the configuration document
    self.configDocument = configDocDict;
    
    //check to see if this is an offline run 
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRef:self] addDocument:configDocDict tag:kOrcaConfigDocumentAdded];
    }
    //NSLog(@"Adding configuation file \n");
    
    //wait for main thread to receive acknowledgement from couchdb
    /*NSDate* timeoutConfig = [NSDate dateWithTimeIntervalSinceNow:2.0];
    while ([timeoutConfig timeIntervalSinceNow] > 0 && ![self.runDocument objectForKey:@"_id"]) {
        [NSThread sleepForTimeInterval:0.1];
    }*/
    
    //Update to the Orca DB
    //[[self orcaDbRef:self] updateDocument:configDocDict documentId: [configDocDict objectForKey:@"_id"] tag:kOrcaConfigDocumentUpdated];
    

    //if ([objs count]) {
    //    aMTCcard = [objs objectAtIndex:0];
    //}
    
    // array object at 0
    //NSEnumerator* e = [listOfCards objectEnumerator];
    //SNOCaenModel* aCard;
    //while(aCard = [e nextObject]){
    //    if([aCard crateNumber] == crate && [aCard slot] == card){
    //        [actualCards setObject:aCard forKey:aKey];
    //        obj = aCard;
    //        break;
    //    }
   // }

    
    // access to MTC/D object
    
    
    // mtcdDocDict
    
    
    // upload to DB
    
    
    // get doc id, and update run doc
    
    
    
    //crates
    //cable doc should go here...
    
    //order matters

    
    /*
     expert_flag = BooleanProperty()
     mtc_doc = StringProperty()
     hv_doc = StringProperty()
     run_type_doc = StringProperty()
     source_doc = StringProperty()
     crate = ListProperty()
     sub_run_number = IntegerProperty()?
     run_stop = DateTimeProperty()? to be updated with the run status update to "done"
     */
    
    
    // run document links to crate documents (we need doc IDs)
    
    [runDocPool release];
}


- (void) _runEndDocumentWorker:(NSDictionary*)runDoc
{
    NSAutoreleasePool* runDocPool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* runDocDict = [[runDoc mutableCopy] autorelease];

    [runDocDict setObject:@"done" forKey:@"run_status"];
    //[runDocDict setObject:[self stringDateFromDate:nil] forKey:@"run_stop"];
    [runDocDict setObject:[NSNumber numberWithDouble:[[self stringUnixFromDate:nil] doubleValue]] forKey:@"timestamp_end"];
    [runDocDict setObject:[self rfc2822StringDateFromDate:nil] forKey:@"sudbury_time_end"];

    //after run stats
    //alarm logs
    //end of run xl3 logs
    //ellie

    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRef:self] updateDocument:runDocDict
                                   documentId:[runDocDict objectForKey:@"_id"]
                                          tag:kOrcaRunDocumentUpdated];
    }
    
    [runDocPool release];
}

- (void) morcaUpdateDBDict
{
    /*
    if (!morcaDBDict) morcaDBDict = [[NSMutableDictionary alloc] initWithCapacity:20];
    NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    ORXL3Model* xl3;
    for (xl3 in objs) {
        [[self morcaDBRef] getDocumentId:[NSString stringWithFormat:@"_design/xl3_status/_view/xl3_num?descending=True&start_key=%d&end_key=%d&limit=1&include_docs=True",[xl3 crateNumber], [xl3 crateNumber]]
                                     tag:[NSString stringWithFormat:@"%@.%d", kMorcaCrateDocGot, [xl3 crateNumber]]];
    }
     */
    /*
    if ([self morcaIsUpdating]) {
        if ([self morcaUpdateTime] == 0) {
            [self performSelector:@selector(morcaUpdateDB) withObject:nil afterDelay:0.1];
        }
        else {
            [self performSelector:@selector(morcaUpdateDB) withObject:nil afterDelay:[self morcaUpdateTime] - 0.2];
        }
    }
     */
}

- (void) morcaUpdatePushDocs:(unsigned int) crate
{
    /*
    NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    ORXL3Model* xl3;
    for (xl3 in objs) {
        if ([xl3 crateNumber] == crate) break;
    }
        
    BOOL updateDoc = NO;
    if ([[morcaDBDict objectForKey:[NSString stringWithFormat:@"%d",[xl3 crateNumber]]] objectForKey:@"_id"]){
        [[xl3 pollDict] setObject:[[morcaDBDict objectForKey:[NSString stringWithFormat:@"%d",[xl3 crateNumber]]] objectForKey:@"_id"] forKey:@"_id"];
        updateDoc = YES;
    }
    else {
        if ([[xl3 pollDict] objectForKey:@"_id"]) {
            [[xl3 pollDict] removeObjectForKey:@"_id"];
        }
        if ([[xl3 pollDict] objectForKey:@"_rev"]) {
            [[xl3 pollDict] removeObjectForKey:@"_rev"];
        }
    }
    if ([[morcaDBDict objectForKey:[NSString stringWithFormat:@"%d",[xl3 crateNumber]]] objectForKey:@"_rev"]){
        [[xl3 pollDict] setObject:[[morcaDBDict objectForKey:[NSString stringWithFormat:@"%d",[xl3 crateNumber]]] objectForKey:@"_rev"] forKey:@"_rev"];
    }
    [[xl3 pollDict] setObject:[NSNumber numberWithInt:[xl3 crateNumber]] forKey:@"xl3_num"];
    NSDateFormatter* iso = [[NSDateFormatter alloc] init];
    [iso setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    iso.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    //iso.calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    //iso.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
    NSString* str = [iso stringFromDate:[NSDate date]];
    [[xl3 pollDict] setObject:str forKey:@"time_stamp"];
    if (updateDoc) {
        [[self morcaDBRef] updateDocument:[xl3 pollDict] documentId:[[xl3 pollDict] objectForKey:@"_id"] tag:kMorcaCrateDocUpdated];
    }
    else{
        [[self morcaDBRef] addDocument:[xl3 pollDict] tag:kMorcaCrateDocUpdated];
    }
    [iso release];
    iso = nil;
    if (xl3 == [objs lastObject] && [self morcaIsUpdating]) {
        if ([self morcaUpdateTime] == 0) {
            [self performSelector:@selector(morcaUpdateDB) withObject:nil afterDelay:0.2];
        }
        else {
            [self performSelector:@selector(morcaUpdateDB) withObject:nil afterDelay:[self morcaUpdateTime] - 0.2];
        }
    }
     */
}
@end


@implementation SNOPDecoderForRHDR

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
    NSMutableString* dsc = [NSMutableString stringWithFormat: @"RHDR record\n\n"];
    
    [dsc appendFormat:@"date: %ld\n", dataPtr[2]];
    [dsc appendFormat:@"time: %ld\n", dataPtr[3]];
    [dsc appendFormat:@"daq ver: %ld\n", dataPtr[4]];
    [dsc appendFormat:@"run num: %ld\n", dataPtr[5]];
    [dsc appendFormat:@"calib trial: %ld\n", dataPtr[6]];
    [dsc appendFormat:@"src msk: 0x%08lx\n", dataPtr[7]];
    [dsc appendFormat:@"run msk: 0x%016llx\n", (unsigned long long)(dataPtr[8] | (((unsigned long long)dataPtr[12]) << 32))];
    [dsc appendFormat:@"crate mask: 0x%08lx\n", dataPtr[9]];
    
    return [[dsc retain] autorelease];
}
@end

@implementation SNOPDecoderForEPED

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
    NSMutableString* dsc = [NSMutableString stringWithFormat: @"EPED record\n\n"];

    [dsc appendFormat:@"coarse delay: %ld nsec\n", dataPtr[3]];
    [dsc appendFormat:@"fine delay: %ld clicks\n", dataPtr[4]];
    [dsc appendFormat:@"charge amp: %ld clicks\n", dataPtr[5]];
    [dsc appendFormat:@"ped width: %ld nsec\n", dataPtr[2]];
    [dsc appendFormat:@"cal type: 0x%08lx\n", dataPtr[7]];
    [dsc appendFormat:@"step num: %ld\n", dataPtr[6]];
    
    return [[dsc retain] autorelease];
}
@end
