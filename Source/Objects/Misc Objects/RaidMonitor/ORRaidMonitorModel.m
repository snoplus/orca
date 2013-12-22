//-------------------------------------------------------------------------
//  ORRaidMonitorModel.m
//
//  Created by Mark Howe on Saturday 12/21/2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
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

#pragma mark ***Imported Files
#import "ORRaidMonitorModel.h"
#import "ORFileGetterOp.h"

NSString* ORRaidMonitorModelResultStringChanged = @"ORRaidMonitorModelResultStringChanged";
NSString* ORRaidMonitorModelLocalPathChanged    = @"ORRaidMonitorModelLocalPathChanged";
NSString* ORRaidMonitorModelRemotePathChanged   = @"ORRaidMonitorModelRemotePathChanged";
NSString* ORRaidMonitorIpAddressChanged         = @"ORRaidMonitorIpAddressChanged";
NSString* ORRaidMonitorPasswordChanged          = @"ORRaidMonitorPasswordChanged";
NSString* ORRaidMonitorUserNameChanged          = @"ORRaidMonitorUserNameChanged";
NSString* ORRaidMonitorLock                     = @"ORRaidMonitorLock";

@implementation ORRaidMonitorModel

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    return self;
}

- (void) dealloc 
{
    [resultString release];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:nil object:nil];
    [localPath release];
    [remotePath release];
    [ipAddress release];
    [password release];
    [userName release];
    [fileQueue cancelAllOperations];
    [fileQueue release];
    [allOutput release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"RaidMonitor"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORRaidMonitorController"];
}

#pragma mark ***Accessors

- (NSString*) resultString
{
    if(!resultString)return @"";
    else return resultString;
}

- (void) setResultString:(NSString*)aResultString
{
    [resultString autorelease];
    resultString = [aResultString copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRaidMonitorModelResultStringChanged object:self];
}

- (NSString*) localPath
{
    if(!localPath)return @"";
    else return localPath;
}

- (void) setLocalPath:(NSString*)aLocalPath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLocalPath:localPath];
    
    [localPath autorelease];
    localPath = [aLocalPath copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRaidMonitorModelLocalPathChanged object:self];
}

- (NSString*) remotePath
{
    if(!remotePath)return @"";
    else return remotePath;
}

- (void) setRemotePath:(NSString*)aRemotePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRemotePath:remotePath];
    
    [remotePath autorelease];
    remotePath = [aRemotePath copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRaidMonitorModelRemotePathChanged object:self];
}

- (NSString*) ipAddress
{
    if(!ipAddress)return @"";
    else return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
    
    [ipAddress autorelease];
    ipAddress = [aIpAddress copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRaidMonitorIpAddressChanged object:self];
}

- (NSString*) password
{
    if(!password)return @"";
    else return password;
}

- (void) setPassword:(NSString*)aPassword
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
    
    [password autorelease];
    password = [aPassword copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRaidMonitorPasswordChanged object:self];
}

- (NSString*) userName
{
    if(!userName)return @"";
    else return userName;
}

- (void) setUserName:(NSString*)aUserName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUserName:userName];
    
    [userName autorelease];
    userName = [aUserName copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRaidMonitorUserNameChanged object:self];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setLocalPath: [decoder decodeObjectForKey:@"localPath"]];
    [self setRemotePath:[decoder decodeObjectForKey:@"remotePath"]];
    [self setIpAddress: [decoder decodeObjectForKey:@"ipAddress"]];
    [self setPassword:  [decoder decodeObjectForKey:@"password"]];
    [self setUserName:  [decoder decodeObjectForKey:@"userName"]];
    [[self undoManager] enableUndoRegistration];    

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:localPath  forKey:@"localPath"];
    [encoder encodeObject:remotePath forKey:@"remotePath"];
    [encoder encodeObject:ipAddress  forKey:@"ipAddress"];
    [encoder encodeObject:password   forKey:@"password"];
    [encoder encodeObject:userName   forKey:@"userName"];
}
#pragma mark •••scp 

-(void) getStatus
{
    if(!fileQueue){
        fileQueue = [[NSOperationQueue alloc] init];
        [fileQueue setMaxConcurrentOperationCount:1];
        [fileQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    }


    ORFileGetterOp* mover = [[[ORFileGetterOp alloc] init] autorelease];
    mover.delegate     = self;

    [mover setParams:remotePath localPath:localPath ipAddress:ipAddress userName:userName passWord:password];

    [fileQueue addOperation:mover];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == fileQueue && [keyPath isEqual:@"operations"]) {
        if([fileQueue operationCount]==0){
        }
//        [[NSNotificationCenter defaultCenter] postNotificationName:ORDataFileQueueRunningChangedNotification object: self];
    }
}
- (void) fileGetterIsDone
{
    NSString* fullLocalPath = [localPath stringByExpandingTildeInPath];
    NSStringEncoding* en=nil;
    NSString* contents = [NSString stringWithContentsOfFile:fullLocalPath usedEncoding:en error:nil];
    [self setResultString: contents];

    NSMutableDictionary* resultDict = [NSMutableDictionary dictionary];
    NSArray* lines = [contents componentsSeparatedByString:@"\n"];
    int lineNumber = 0;
    for(id aLine in lines){
        lineNumber++;
        if(lineNumber == 2) continue;
        if(lineNumber == 3) continue;
        if([aLine rangeOfString:@"Usage"].location      != NSNotFound) continue;
        if([aLine rangeOfString:@"Filesystem"].location != NSNotFound) continue;
        if([aLine rangeOfString:@""].location           != NSNotFound) continue;
        aLine = [aLine removeExtraSpaces];
        if([aLine length]==0)continue;

        if(lineNumber ==1){
            //must be the time
            [resultDict setObject:aLine forKey:@"Time"];
        }
        else if(lineNumber == [lines count]-1){
            NSArray* parts = [aLine componentsSeparatedByString:@" "];
            if([parts count] == 6){
                [resultDict setObject:[parts objectAtIndex:0] forKey:@"Filesystem"];
                [resultDict setObject:[parts objectAtIndex:1] forKey:@"Size"];
                [resultDict setObject:[parts objectAtIndex:2] forKey:@"Used"];
                [resultDict setObject:[parts objectAtIndex:3] forKey:@"Avail"];
                [resultDict setObject:[parts objectAtIndex:4] forKey:@"Used"];
                [resultDict setObject:[parts objectAtIndex:5] forKey:@"Mounted Point"];
            }
        }
        else {
            NSArray* parts = [aLine componentsSeparatedByString:@":"];
            if([parts count] == 2){
                [resultDict setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
            }
         }
    }
    NSLog(@"Debugging Info:\n");
    NSLog(@"%@\n",resultDict);
}


@end
