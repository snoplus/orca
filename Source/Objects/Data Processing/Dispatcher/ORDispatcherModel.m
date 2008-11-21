//
//  ORDispatcherModel.m
//  Orca
//
//  Created by Mark Howe on Mon Nov 18 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORDispatcherModel.h"
#import "NetSocket.h"
#import "ORDataPacket.h"
#import "ORDispatcherClient.h"

static NSString* ORDispatcherConnector 			= @"Dispatcher Connector";

NSString* ORDispatcherPortChangedNotification 	= @"ORDispatcherPortChangedNotification";
NSString* ORDispatcherClientsChangedNotification = @"ORDispatcherClientsChangedNotification";
NSString* ORDispatcherClientDataChangedNotification = @"ORDispatcherClientDataChangedNotification";
NSString* ORDispatcherCheckRefusedChangedNotification = @"ORDispatcherCheckRefusedChangedNotification";
NSString* ORDispatcherCheckAllowedChangedNotification = @"ORDispatcherCheckAllowedChangedNotification";
NSString* ORDispatcherLock                      = @"ORDispatcherLock";

@implementation ORDispatcherModel

#pragma mark ¥¥¥Initialization

- (id) init //designated initializer
{
	self = [super init];
    
    [[self undoManager] disableUndoRegistration];
	[self setSocketPort:kORDispatcherPort];
	[self setClients:[NSMutableArray array]];
    [[self undoManager] enableUndoRegistration];
    
    _ignoreMode = YES;
    
	return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[clients release];
    [allowedList release];
    [refusedList release];
	[serverSocket release];
    [super dealloc];
}

- (void) setUpImage
{
	//---------------------------------------------------------------------------------------------------
	//arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
	//so, we cache the image here so we can draw into it.
	//---------------------------------------------------------------------------------------------------
    
	NSImage* aCachedImage = [NSImage imageNamed:@"Dispatcher"];
	NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
	[i lockFocus];
	[aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    
    if([[ORGlobal sharedGlobal] runMode] == kOfflineRun && !_ignoreMode){
        NSImage* aNoticeImage = [NSImage imageNamed:@"notice"];
        [aNoticeImage compositeToPoint:NSMakePoint([i size].width/2-[aNoticeImage size].width/2 ,[i size].height/2-[aNoticeImage size].height/2) operation:NSCompositeSourceOver];
    }
	[i unlockFocus];
    
    [self setImage:i];
	[i release];
}

- (void) makeMainController
{
    [self linkToController:@"ORDispatcherController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(2,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORDispatcherConnector];
	[aConnector setIoType:kInputConnector];
    [aConnector release];
    
}

- (void) setGuardian:(id)aGuardian
{
    if(aGuardian){
		[self serve];
	}
    else {
		[serverSocket release];
		serverSocket = nil;
	};
    
    [super setGuardian:aGuardian];
}
- (int) clientCount
{
	return [clients count];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(runModeChanged:)
                         name : ORRunModeChangedNotification
                       object : nil];
    
}

- (void) runModeChanged:(NSNotification*)aNotification
{
    [self setUpImage];
}


#pragma mark ¥¥¥Accessors
- (int) socketPort
{
	return socketPort;
}
- (void) setSocketPort:(int)aPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSocketPort:socketPort];
    
    socketPort = aPort;
    
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORDispatcherPortChangedNotification
                              object:self];
}

- (NSArray*)clients
{
	return clients;
}

- (void) setClients:(NSMutableArray*)someClients
{
	[someClients retain];
	[clients release];
	clients = someClients;
}

- (BOOL) checkAllowed
{
    return checkAllowed;
}

- (void) setCheckAllowed: (BOOL) flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCheckAllowed:checkAllowed];
    checkAllowed = flag;
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORDispatcherCheckAllowedChangedNotification
                              object:self];
}

- (BOOL) checkRefused
{
    return checkRefused;
}
- (void) setCheckRefused: (BOOL) flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCheckRefused:checkRefused];
    checkRefused = flag;
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORDispatcherCheckRefusedChangedNotification
                              object:self];
}

- (NSArray *) allowedList
{
    return allowedList; 
}

- (void) setAllowedList: (NSArray *) anAllowedList
{
    [anAllowedList retain];
    [allowedList release];
    allowedList = anAllowedList;
}

- (NSArray *) refusedList
{
    return refusedList; 
}

- (void) setRefusedList: (NSArray *) aRefusedList
{
    [aRefusedList retain];
    [refusedList release];
    refusedList = aRefusedList;
}

- (void) parseAllowedList:(NSString*)aString
{
    [self setAllowedList:[aString componentsSeparatedByString:@"\n"]];
}

- (void) parseRefusedList:(NSString*)aString
{
    [self setRefusedList:[aString componentsSeparatedByString:@"\n"]];
}

- (void)serve
{
	serverSocket = [[NetSocket netsocketListeningOnPort:kORDispatcherPort] retain];
	[serverSocket scheduleOnCurrentRunLoop];
	[serverSocket setDelegate:self];
	
	NSLog( @"Orca Dispatcher: Waiting for connections...\n" );
}

#pragma mark ¥¥¥Delegate Methods

- (void) clientChanged:(id)aClient
{
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORDispatcherClientsChangedNotification
                              object:self];
    
}

- (void) clientDataChanged:(id)aClient
{
    //this is so we don't update too often.
    if(!scheduledForUpdate){
        scheduledForUpdate = YES;
		[self performSelectorOnMainThread:@selector(scheduleUpdateOnMainThread) withObject:nil waitUntilDone:NO];
    }
}

- (void) scheduleUpdateOnMainThread
{
	scheduledForUpdate = YES;
	[self performSelector:@selector(postUpdate) withObject:nil afterDelay:1.0];
}

- (void) postUpdateOnMainThread
{
	[self performSelectorOnMainThread:@selector(postUpdate) withObject:nil waitUntilDone:NO];
    
}

- (void) postUpdate
{
    scheduledForUpdate = NO;
    
    [[NSNotificationCenter defaultCenter]
				postNotificationName:ORDispatcherClientDataChangedNotification
                              object:self];
    
}


- (void)netsocket:(NetSocket*)inNetSocket connectionAccepted:(NetSocket*)inNewNetSocket
{
    
    ORDispatcherClient* client = [[[ORDispatcherClient alloc] initWithNetSocket:inNewNetSocket] autorelease];
    
    if(![self isAlreadyConnected:client]){
        if([self allowConnection:client] && ![self refuseConnection:client]){
            
            [client setDelegate:self];
            
            [client setTimeConnected:[NSDate date]];
            
            if([[ORGlobal sharedGlobal] runInProgress]){
				if(dataHeader){
					[[client socket] writeData:dataHeader];
				}
            }
            
            [clients addObject:client];
            [self clientChanged:client];
            NSLog( @"Broadcaster: New connection established to: %@\n",[[client socket] remoteHost] );
        }
        else {
            NSLogError(@" ",@"Broadcaster",[NSString stringWithFormat:@"connection %@ refused",[[client socket] remoteHost]],nil);
        }
    }
    else {
        NSLogError(@" ",@"Broadcaster",[NSString stringWithFormat:@"duplicate connection from %@ refused",[[client socket] remoteHost]],nil);
    }
}

- (void) checkConnectedClients
{
    NSMutableArray* deleteList = [NSMutableArray array];
    NSEnumerator* e = [clients objectEnumerator];
    ORDispatcherClient* client;
    while(client = [e nextObject]){
        if(![self allowConnection:client]){
            [deleteList addObject:client];
            NSLog(@" Client %@ was disconnected (not allowed).\n",[[client socket] remoteHost]);
        }
        if([self refuseConnection:client]){
            [deleteList addObject:client];
            NSLog(@" Client %@ was disconnected (in refuse list).\n",[[client socket] remoteHost]);
        }
    }
    [clients removeObjectsInArray:deleteList];
}


- (BOOL) allowConnection:(ORDispatcherClient*)aNewClient
{
    if(checkAllowed){
        NSEnumerator* e = [allowedList objectEnumerator];
        NSString* allowedClientHost;
        while(allowedClientHost = [e nextObject]){
            if([allowedClientHost isEqualToString:[[aNewClient socket] remoteHost]]){
                return YES;
            }
        }
        return NO;
        
    }
    else return YES;
}

- (BOOL) refuseConnection:(ORDispatcherClient*)aNewClient
{
    if(checkRefused){
        NSEnumerator* e = [refusedList objectEnumerator];
        NSString* refusedClientHost;
        while(refusedClientHost = [e nextObject]){
            if([refusedClientHost isEqualToString:[[aNewClient socket] remoteHost]]){
                return YES;
            }
        }
        return NO;
        
    }
    else return NO;
}

- (BOOL) isAlreadyConnected:(ORDispatcherClient*)aNewClient
{
    NSEnumerator* e = [clients objectEnumerator];
    ORDispatcherClient* client;
    while(client = [e nextObject]){
        if([[[client socket] remoteHost] isEqualToString:[[aNewClient socket] remoteHost]]){
            return YES;
        }
    }
    return NO;
}

- (void) clientDisconnected:(id)aClient
{
    if([clients containsObject:aClient]){
        NSLog( @"Broadcaster: Client %@ removed\n",[aClient name] );
        [clients removeObject:aClient];
        [self clientChanged:aClient];
    }
}

- (void) report
{
    NSLog(@"Data Broadcaster report\n");
    NSLog(@"Number of clients: %d\n",[clients count]);
    NSEnumerator* e = [clients objectEnumerator];
    ORDispatcherClient* client;
    while(client = [e nextObject]){
        NSLog(@"%d: %@ connected since %@\n",[clients indexOfObject:client]+1,[client name],[client timeConnected]);
    }
    
}

#pragma mark ¥¥¥Data Handling
- (void) processData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
		NSArray* dataArray = [aDataPacket dataArray];
		int i;
		int n = [dataArray count];
		NSMutableData* theData = [[NSMutableData alloc] initWithCapacity:500000];
		for(i=0;i<n;i++)[theData appendData: [dataArray objectAtIndex:i]];
		if([theData length]>0)[clients makeObjectsPerformSelector:@selector(writeData:) withObject:theData];
        [theData release];
	}    
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{		
	dataHeader = [[aDataPacket headerAsData] retain];
	[clients makeObjectsPerformSelector:@selector(writeData:) withObject:dataHeader];
	[clients makeObjectsPerformSelector:@selector(clearCounts)];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}

- (void) closeOutRun:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[dataHeader release];
	dataHeader = nil;
}


#pragma mark ¥¥¥Archival
static NSString *ORDispatcherPortNumber		 	= @"ORDispatcherPortNumber";
static NSString *ORDispatcherCheckAllowed	 	= @"ORDispatcherCheckAllowed";
static NSString *ORDispatcherCheckRefused	 	= @"ORDispatcherCheckRefused";
static NSString *ORDispatcherAllowedList	 	= @"ORDispatcherAllowedList";
static NSString *ORDispatcherRefusedList	 	= @"ORDispatcherRefusedList";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setSocketPort:[decoder decodeIntForKey:ORDispatcherPortNumber]];
    [self setCheckAllowed:[decoder decodeBoolForKey:ORDispatcherCheckAllowed]];
    [self setCheckRefused:[decoder decodeBoolForKey:ORDispatcherCheckRefused]];
    [self setAllowedList:[decoder decodeObjectForKey:ORDispatcherAllowedList]];
    [self setRefusedList:[decoder decodeObjectForKey:ORDispatcherRefusedList]];
    [[self undoManager] enableUndoRegistration];
    
    [self setClients:[NSMutableArray array]];
    
    _ignoreMode = NO;
	[self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:socketPort forKey:ORDispatcherPortNumber];
    [encoder encodeBool:checkAllowed forKey:ORDispatcherCheckAllowed];
    [encoder encodeBool:checkRefused forKey:ORDispatcherCheckRefused];
    [encoder encodeObject:allowedList forKey:ORDispatcherAllowedList];
    [encoder encodeObject:refusedList forKey:ORDispatcherRefusedList];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
	NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:[NSNumber numberWithInt:socketPort] forKey:@"PortNumber"];
    [objDictionary setObject:[NSNumber numberWithInt:checkAllowed] forKey:@"CheckAllowed"];
    [objDictionary setObject:[NSNumber numberWithInt:checkRefused] forKey:@"CheckRefused"];
    if([allowedList count])[objDictionary setObject:allowedList forKey:@"AllowedList"];
    if([refusedList count])[objDictionary setObject:refusedList forKey:@"RefusedList"];
    [dictionary setObject:objDictionary forKey:@"Listener"];
    return objDictionary;
}


@end
