//
//  ORDataPipeModel.m
//  Orca
//
//  Created by Mark Howe on Wed Feb 15, 2017.
//  Copyright (c) 2017 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "ORDataPipeModel.h"
#import "ORDecoder.h"
#import <libproc.h>

static NSString* ORDataPipeConnector           = @"DataPipe Connector";

NSString* ORDataPipeLock                  = @"ORDataPipeLock";
NSString* ORDataPipeReaderPathChanged     = @"ORDataPipeReaderPathChanged";
NSString* ORDataPipeNameChanged           = @"ORDataPipeNameChanged";
NSString* ORDataPipeUpdate                = @"ORDataPipeUpdate";

#define byteCheckPollRate 2

@implementation ORDataPipeModel

#pragma mark •••Initialization

- (id) init //designated initializer
{
	self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [[self undoManager] enableUndoRegistration];
    
    _ignoreMode = YES;
    
	return self;
}

-(void)dealloc
{
    if(fifoFD)close(fifoFD);
    fifoFD = 0;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"DataPipe"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORDataPipeController"];
}

- (NSString*) helpURL
{
	return @"Data_Chain/Broadcaster.html";
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(2,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORDataPipeConnector];
	[aConnector setIoType:kInputConnector];
    [aConnector release];
}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self];
    
    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStop:)
                         name : ORRunAboutToStopNotification
                       object : nil];
}

- (void) runAboutToStop:(NSNotification*) aNote
{
}

- (void) setRunMode:(int)aMode
{
	runMode = aMode;
    [self setUpImage];
}


#pragma mark •••Accessors

- (BOOL) readerIsRunning
{
    return readerIsRunning;
}
- (BOOL) runInProgress
{
   return runInProgress;
}

- (long) numberBytesSent
{
    return numberBytesSent;
}
- (float) sendRate
{
    return sendRate;
}

- (NSString*) readerPath
{
    if(readerPath)return readerPath;
    else return @"";
}

- (void) setReaderPath:(NSString*)aPath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setReaderPath:readerPath];
    
    [readerPath autorelease];
    readerPath = [aPath copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataPipeReaderPathChanged object: self];
}

- (NSString*) pipeName
{
    if(pipeName)    return pipeName;
    else return @"";
}

- (void) setPipeName:(NSString*)aName;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPipeName:pipeName];
    
    [pipeName autorelease];
    pipeName = [aName copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataPipeNameChanged object: self];
}

#pragma mark •••Delegate Methods
- (void) startUpdates
{
    [self postUpdate];
}

- (void) postUpdate
{
    [self checkReader];
    sendRate = numberBytesSent/(float)byteCheckPollRate;
    numberBytesSent = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataPipeUpdate object:self];
    if(runInProgress)[self performSelector:@selector(postUpdate) withObject:nil afterDelay:byteCheckPollRate];
}


- (void) report
{
    NSLog(@"Pipe report\n");
}

- (BOOL) checkReader
{
    int numberOfProcesses = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    pid_t pids[1024];
    bzero(pids, 1024);
    proc_listpids(PROC_ALL_PIDS, 0, pids, sizeof(pids));
    const char* fullPath = [[readerPath stringByExpandingTildeInPath] cStringUsingEncoding:NSASCIIStringEncoding];
    for (int i = 0; i < numberOfProcesses; ++i) {
        if (pids[i] == 0) { continue; }
        char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
        bzero(pathBuffer, PROC_PIDPATHINFO_MAXSIZE);
        proc_pidpath(pids[i], pathBuffer, sizeof(pathBuffer));
        
        if (strlen(pathBuffer) > 0) {
            if(!strcmp(pathBuffer,fullPath)){
                readerIsRunning = YES;
                return YES;
            }
        }
    }
    readerIsRunning = NO;
    return NO;
}


- (void) runTaskStarted:(id)userInfo
{
    runInProgress = YES;
    numberBytesSent = 0;
    
    [self startUpdates];
    
    NSFileManager* fm = [NSFileManager defaultManager];
    const char* cPipeName = [pipeName cStringUsingEncoding:NSASCIIStringEncoding];
    if(![fm fileExistsAtPath:pipeName]) {
        mkfifo(cPipeName, S_IRWXU);
    }
    // Open and use the fifo as you would any file in Cocoa, but remember that it's a FIFO
    fifoFD = open(cPipeName,O_RDWR);
    fcntl(fifoFD, F_SETFL, fcntl(fifoFD, F_GETFL) | O_NONBLOCK);
}

- (void) subRunTaskStarted:(id)userInfo
{
    numberBytesSent = 0;
}

- (void) closeOutRun:(id)userInfo
{
    runInProgress   = NO;
    numberBytesSent = 0;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if(fifoFD)close(fifoFD);
    fifoFD = 0;
    [self postUpdate]; //final update
 }

//--------------------------------------
//needed to obey the protocol
- (void) runTaskBoundary{}
- (void) runTaskStopped:(id)userInfo{}
- (void) preCloseOut:(id)userInfo{}
//--------------------------------------

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setPipeName:     [decoder decodeObjectForKey:   @"pipeName"]];
    [self setReaderPath:   [decoder decodeObjectForKey:   @"readerPath"]];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:readerPath         forKey:@"readerPath"];
    [encoder encodeObject:pipeName           forKey:@"pipeName"];
}

//----------------------------------------------------------------------
//----------------Different Thread
//----------------------------------------------------------------------
#pragma mark •••Data Handling
- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder;
{
    if(([[ORGlobal sharedGlobal] runMode] == kNormalRun) && [self readerIsRunning]){
        for(NSData* d in dataArray){
            @try {
                if(fifoFD){
                    size_t n = write(fifoFD,(const void*)[d bytes],(size_t)[d length]);
                    if(n>0){
                        numberBytesSent += n;
                    }
                }
            }
            @catch(NSException* e){
                
            }
        }
    }
}


@end
