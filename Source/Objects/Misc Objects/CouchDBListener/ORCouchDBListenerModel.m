//
//  ORCouchDBModel.m
//  Orca
//
//  Created by Thomas Stolz on 05/20/13.
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


#import "ORCouchDBListenerModel.h"
#import "ORCouchDB.h"
#import "Utilities.h"
#import "NSNotifications+Extensions.h"
#import "NSString+Extensions.h"
#import "NSInvocation+Extensions.h"
#import "NSArray+Extensions.h"
#import "NSDictionary+Extensions.h"
#import "ORScriptRunner.h"
#import <YAJL/NSObject+YAJL.h>
#import <YAJL/YAJLDocument.h>

#define kListDB             @"kListDB"
#define kChangesfeed        @"kChangesfeed"
#define kCommandDocCheck    @"kCommandDocCheck"
#define kCmdDocCheck        @"kCmdDocCheck"
#define kCmdUploadDone      @"kCmdUploadDone"
#define kMsgUploadDone      @"kMsgUploadDone"

#define kCouchDBPort 5984

NSString* ORCouchDBListenerModelDatabaseListChanged = @"ORCouchDBListenerModelDatabaseListChanged";
NSString* ORCouchDBListenerModelListeningChanged = @"ORCouchDBListenerModelListeningChanged";
NSString* ORCouchDBListenerModelObjectListChanged = @"ORCouchDBListenerModelObjectListChanged";
NSString* ORCouchDBListenerModelCommandsChanged =@"ORCouchDBListenerModelCommandsChanged";
NSString* ORCouchDBListenerModelStatusLogChanged =@"ORCouchDBListenerModelStatusLogChanged";

@implementation ORCouchDBListenerModel

#pragma mark ***Initialization
- (id) init
{
	self=[super init];
	[self registerNotificationObservers];
    [self setHeartbeat:5000];
    [self setHostName:@"localhost"];
    [self setPortNumber:kCouchDBPort];
    commonMethodsOnly=YES;
    [self setDefaults];
    ignoreNextChanges=0;
    [self setStatusLog:@""];
	return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [databaseName release];
    [userName release];
    [password release];
    [hostName release];
    [objectList release];
    [databaseList release];
    [cmdTableArray release];
    [cmdDict release];
    [cmdUploadDict release];
	[super dealloc];
}

- (void) wakeUp
{
    [super wakeUp];
    
    cmdDocName=@"commands";
    msgDocName=@"messages";
    scriptDocName=@"Orca Scripts";
    commandDoc = @"control";
    runningChangesfeed=nil;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Changesfeed"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCouchDBListenerController"];
}

- (void) registerNotificationObservers
{
//    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
//    
//	[notifyCenter removeObserver:self];
//	
//    [notifyCenter addObserver : self
//                     selector : @selector(applicationIsTerminating:)
//                         name : @"ORAppTerminating"
//                       object : [NSApp delegate]];
	
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqual:@"isFinished"]){
        if([change objectForKey:NSKeyValueChangeNewKey]){ //this means the changesfeed operation has finished
            [runningChangesfeed release];
            runningChangesfeed=nil;
            [self log:@"Changesfeed operation finished"];
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelListeningChanged object:self];
        }
        
    }
}

#pragma mark ***Accessors
- (void) ignoreNextChange
{
    ignoreNextChanges+=1;
}

- (void) changeIgnored
{
    ignoreNextChanges-=1;
}

- (NSString*) statusLog
{
    return statusLogString;
}

- (void) setStatusLog:(NSString *)log
{
    @synchronized(self){
        [statusLogString release];
        statusLogString=[log retain];
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelStatusLogChanged object:self];
    }
}

- (void) log:(NSString *)message
{
    if(message){
        [self setStatusLog:[[NSString stringWithFormat:@"%@: %@\n", [NSDate date], message] stringByAppendingString:statusLogString]];
    }
}
//Couch Config
- (void) setDatabaseName:(NSString*)name{
    [databaseName release];
    databaseName=[name copy];
}

- (void) setHostName:(NSString*)name{

    [hostName release];
    hostName= [name copy];
}

- (void) setPortNumber:(NSUInteger)aPort
{
    portNumber=aPort;
}

- (void) setUserName:(NSString*)name
{
    if ([name length]==0)
    {
        userName=nil;
        [self setPassword:nil];
    }
    else{
        [userName release];
        userName=[name copy];
    }
}

- (void) setPassword:(NSString*)pwd
{
    [password release];
    password=[pwd copy];
}

- (NSArray*) databaseList
{
    return databaseList;
}

- (NSString*) database
{
    return databaseName;
}

- (NSUInteger) heartbeat
{
    return heartbeat;
}

- (NSString*) hostName
{
    if (!hostName) return @"";
    return hostName;
}

- (NSUInteger) portNumber
{
    return portNumber;
}

- (NSString*) userName
{
    if (!userName) return @"";
    return userName;
}

- (NSString*) password
{
    if (!password) return @"";
    return password;
}

- (BOOL) isListening
{
    if(runningChangesfeed){
        return TRUE;
    }
    else{
        return FALSE;
    }
}

- (void) setHeartbeat:(NSUInteger)beat
{
    
    heartbeat=beat;
}


//Command Section
- (void) setCommonMethods:(BOOL)only
{
    commonMethodsOnly=only;
}

- (NSArray*) objectList
{
    return objectList;
}

- (NSArray*) getMethodListForObjectID:(NSString*)objID
{
    NSString* methodString;
    id obj = [[self document] findObjectWithFullID:objID];
    if (commonMethodsOnly) methodString=commonScriptMethodsByObj(obj, YES);
    else methodString= listMethods([obj class]);
    return [methodString componentsSeparatedByString:@"\n"];
}

- (BOOL) commonMethodsOnly
{
    return commonMethodsOnly;
}

- (NSMutableArray*) cmdTableArray
{
	return cmdTableArray;
}

- (NSDictionary*) cmdDict
{
    [self createCmdDict];
    return [NSDictionary dictionaryWithDictionary:cmdDict];
}

//- (void) setCmdDocName:(NSString*) name
//{
//    cmdDocName = [NSString stringWithString:name];
//}

#pragma mark ***DB Access

-(void) startStopSession
{
    if (!runningChangesfeed){
        [self createCmdDict];
        [self createCmdUploadDict];
        [self uploadAllSections];
    }
    else{
        [self log:@"Changesfeed canceled"];
        [runningChangesfeed cancel];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBListenerModelListeningChanged object:self];
    }
    
}

-(void) startChangesfeed
{
    runningChangesfeed=[[[self statusDBRef] changesFeedMode:kContinuousFeed Heartbeat:heartbeat Tag:kChangesfeed] retain];
    [runningChangesfeed addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelListeningChanged object:self];
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp
{
	@synchronized(self){
		if([aResult isKindOfClass:[NSDictionary class]]){
            if([aTag isEqualToString:kChangesfeed]){
//                [aResult prettyPrint:@"CouchDB Changes:"];
                if ([[aResult objectForKey:@"id"] isEqualToString:commandDoc]){
                    [self fetchCommandDocForCheck];
                }
                else if ([[aResult objectForKey:@"id"] isEqualToString:cmdDocName]){
                    if (ignoreNextChanges){
                        [self changeIgnored];
                    }
                    else{
                        [self log:@"Command Section has changed - start processing"];
                        [lastRev release];
                        lastRev = [[[[aResult objectForKey:@"changes"] objectAtIndex:0] objectForKey:@"rev"] retain];
                        [self fetchCmdDocForCheck];
                    }
                }

            }
            else if([aTag isEqualToString:kCommandDocCheck]){
                [self checkCommandDoc:aResult];
            }
            else if([aTag isEqualToString:kCmdDocCheck]){
                [self processCmdDocument:aResult];
            }
            else if([aTag isEqualToString:kCmdUploadDone]){
                if ([aResult objectForKey:@"error"]){
                    [self log:[NSString stringWithFormat:@"Command Section upload failed: %@", [aResult objectForKey:@"reason"]]];
                }
                else if ([aResult objectForKey:@"ok"]){
                    cmdSectionReady=YES;
                    [self sectionReady];
                }
                else [self log:[NSString stringWithFormat:@"Command Section upload failed: %@", aResult]];
            }
            else if([aTag isEqualToString:kMsgUploadDone]){
                if ([aResult objectForKey:@"error"]){
                    [self log:[NSString stringWithFormat:@"Message Section upload failed: %@", [aResult objectForKey:@"reason"]]];
                }
                else if ([aResult objectForKey:@"ok"]){
                    msgSectionReady=YES;
                    [self sectionReady];
                }
                else [self log:[NSString stringWithFormat:@"Message Section upload failed: %@", aResult]];
            }
		}
		else if([aResult isKindOfClass:[NSArray class]]){
			if([aTag isEqualToString:kListDB]){
				//[aResult prettyPrint:@"CouchDB List:"];
                [databaseList release];
                databaseList=[aResult retain];
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelDatabaseListChanged object:self];
            }
            else [self log:[NSString stringWithFormat:@"%@",aResult]];
        }
		else { //here is the issue
			[self log:[NSString stringWithFormat:@"%@",aResult]];
		}
	}

}

- (ORCouchDB*) statusDBRef
{
    return [ORCouchDB couchHost:hostName port:portNumber username:userName pwd:password database:dbName delegate:self];
}

- (void) listDatabases
{
	[[self statusDBRef] listDatabases:self tag:kListDB];
}

- (void) fetchCommandDocForCheck
{
    [[self statusDBRef] getDocumentId:commandDoc tag:kCommandDocCheck];
}

- (void) fetchCmdDocForCheck
{
    [[self statusDBRef] getDocumentId:cmdDocName tag:kCmdDocCheck];
}

- (void) uploadAllSections
{
    cmdSectionReady=NO;
    msgSectionReady=NO;
//    scriptSectionready=NO;
    [self uploadCmdSection];
    [self uploadMsgSection];

    
}

- (void) sectionReady
{
    if (cmdSectionReady && msgSectionReady)    // && scriptSectionReady && prmSectionReady
    {
        [self startChangesfeed];
    }
}

#pragma mark ***Message Section
- (void) uploadMsgSection
{
    [self log:@"Uploading message section..."];
    [messageDict release];
    messageDict=[[NSMutableDictionary alloc] initWithObjectsAndKeys:@"session started", [[NSDate date] description], nil];
    [[self statusDBRef] updateDocument:messageDict documentId:msgDocName tag:kMsgUploadDone informingDelegate:YES];
}

#pragma mark ***Command Section
- (void) updateObjectList
{
    NSMutableArray* temp=[[NSMutableArray alloc] initWithCapacity:100];
    id obj;
    for (obj in [[self guardian] familyList]) {
        [temp addObject:[[[obj fullID] copy] autorelease]];
    }
    [objectList release];
    objectList = [[NSArray alloc] initWithArray:temp];
    [temp release];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelObjectListChanged object:self];
    
}

- (BOOL) checkSyntax:(NSString*) key
{
	BOOL syntaxOK = YES;
    id aCommand = [cmdDict objectForKey:key];
	if(aCommand){
		NSString* objID = [aCommand objectForKey:@"Object"];
		id obj = [[self document] findObjectWithFullID:objID];
		if(obj){
			[aCommand setObject:@"OK" forKey:@"ObjectOK"];
			NSString* s	= [aCommand objectForKey:@"Selector"];
			if([obj respondsToSelector:[NSInvocation makeSelectorFromString:s]]){
				[aCommand setObject:@"OK" forKey:@"SelectorOK"];
			}
			else {
				syntaxOK = NO;
				[aCommand removeObjectForKey:@"SelectorOK"];
			}
		}
		else {
			syntaxOK = NO;
			[aCommand removeObjectForKey:@"ObjectOK"];
		}
	}
	return syntaxOK;
}

- (BOOL) executeCommand:(NSString*) key value:(NSString*)val
{
    [self createCmdDict];
    BOOL goodToGo = NO;
	id aCommand = [cmdDict objectForKey:key];
    if(aCommand){
		NSString* objID = [aCommand objectForKey:@"Object"];
		id obj = [[self document] findObjectWithFullID:objID];
		if(obj){
			@try {
				NSMutableString* setterString	= [[[aCommand objectForKey:@"Selector"] mutableCopy] autorelease];
                NSDecimalNumber* theValue;
                if (val){
                    theValue = [NSDecimalNumber decimalNumberWithString:val];
                }
				else {
                    theValue   = [NSDecimalNumber decimalNumberWithString:[aCommand objectForKey:@"Value"]];
                }
				SEL theSetterSelector			= [NSInvocation makeSelectorFromString:setterString];
				
				//do the setter
				NSMethodSignature*	theSignature	= [obj methodSignatureForSelector:theSetterSelector];
				NSInvocation*		theInvocation	= [NSInvocation invocationWithMethodSignature:theSignature];
				NSArray*			selectorItems	= [NSInvocation argumentsListFromSelector:setterString];
				
				[theInvocation setSelector:theSetterSelector];
				int n = [theSignature numberOfArguments];
				int i;
				int count=0;
				for(i=1;i<n;i+=2){
					if(i<[selectorItems count]){
						id theArg = [selectorItems objectAtIndex:i];
						if([theArg isEqualToString:@"$1"]){
							theArg = theValue;
						}
						[theInvocation setArgument:count++ to:theArg];
					}
				}
				[theInvocation setTarget:obj];
				[theInvocation performSelectorOnMainThread:@selector(invoke)
                                                withObject:nil
                                             waitUntilDone:YES];
                goodToGo = YES;
			}
			@catch(NSException* localException){
				goodToGo = NO;
				NSLogColor([NSColor redColor],@"%@: <%@>\n",[self fullID],[aCommand objectForKey:@"SetSelector"]);
				NSLogColor([NSColor redColor],@"Exception: %@\n",localException);
			}
        }
    }
    return goodToGo;
}

- (void) setCommands:(NSMutableArray*)anArray
{
	[anArray retain];
	[cmdTableArray release];
	cmdTableArray = anArray;
}

- (void) setDefaults
{
    [self setCommands:[NSMutableArray array]];
	[self addCommand];
}

- (NSDictionary*) commandAtIndex:(int)index
{
	if(index < [cmdTableArray count]){
		return [cmdTableArray objectAtIndex:index];
	}
	else return nil;
}

- (NSUInteger) commandCount
{
	return [cmdTableArray count];
}

- (void) addCommand
{
	[cmdTableArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						 @"",@"Object",
						 @"",@"Label",
						 @"",@"Selector",
						 @"",@"Info",
						 nil]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBListenerModelCommandsChanged object:self];
    
}

- (void) removeCommand:(int)index
{
	if(index<[cmdTableArray count] && [cmdTableArray count]>1){
		[cmdTableArray removeObjectAtIndex:index];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBListenerModelCommandsChanged object:self];
}

//DB Interactions

- (void) uploadCmdSection
{
    [self log:@"Uploading commands section..."];
    [[self statusDBRef] updateDocument:cmdUploadDict documentId:cmdDocName tag:kCmdUploadDone informingDelegate:YES];
//    cmdSectionReady=YES;
//    [self sectionReady];
}

- (void) createCmdDict
{
    [cmdDict release];
    cmdDict = [[NSMutableDictionary alloc] initWithCapacity:256];
    for (id cmd in cmdTableArray) {
        NSMutableDictionary* tempdict= [NSMutableDictionary dictionaryWithDictionary:cmd];
        [tempdict removeObjectForKey:@"Label"];
        [cmdDict setObject:tempdict forKey:[cmd objectForKey:@"Label"]];
    }

}
- (void) createCmdUploadDict
{
    [cmdUploadDict release];
    cmdUploadDict = [[NSMutableDictionary alloc] initWithCapacity:256];
    [cmdUploadDict setObject:cmdDict forKey:@"keys"];
    [cmdUploadDict setObject:@"" forKey:@"execute"];
    [cmdUploadDict setObject:@"" forKey:@"value (optional)"];
}

- (void) processCmdDocument:(NSDictionary*) doc
{
    NSString* message;
    NSString* key=[doc valueForKey:@"execute"];
    NSString* val=[NSString stringWithFormat:@"%@",[doc valueForKey:@"value (optional)"]];

    NSDictionary* cmd=[cmdDict objectForKey:key];

    if(cmd){
        if ([self checkSyntax:key]){
            if([self executeCommand:key value:val]){
                message=[NSString stringWithFormat:@"%@: executed command with label '%@'", [NSDate date], key];
            }
            else {
                message=@"failure while trying to execute";
            }
        }
        else{
            message=@"cmd with invalid syntax";
        }
    }
    else {
        message = @"no cmd found for this key";
    }
    [self log:message];
    [messageDict setObject:message forKey:[[NSDate date] description]];
    [[self statusDBRef] updateDocument:messageDict documentId:msgDocName tag:nil];
    if ([[doc objectForKey:@"_rev"] isEqualToString:lastRev]){
        [self ignoreNextChange];
        [[self statusDBRef] updateDocument:cmdUploadDict documentId:cmdDocName tag:kCmdUploadDone];
    }
}

#pragma mark ***Script Section

- (void) checkCommandDoc:(NSDictionary*)doc
{
    if([[doc valueForKey:@"run"] isEqualToString:@"YES"]){
        NSString* new_script=[doc objectForKey:@"script"];
        if(YES){
            [script release];
            script=[new_script copy];
            if([scriptRunner running])
            {
                [scriptRunner stop];
                sleep(0.1);
            }
            if([self runScript:script])[self log:@"parsedOK - script started"];
            else [self log:@"parsing error\n"];
        }
    }
    else if([[doc valueForKey:@"run"] isEqualToString:@"NO"]) {
        if(scriptRunner){
            if([scriptRunner running]){
                [scriptRunner stop];
            }
        }
    }
    else [self log:[NSString stringWithFormat:@"command doc without run statement: %@", doc]];
}

- (BOOL) runScript:(NSString*) aScript
{
    BOOL parsedOK = YES;
    if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
    if(![scriptRunner running]){
        [scriptRunner setScriptName:@"CouchDB_remote_script"];
        //[scriptRunner setInputValue:inputValue];
        [scriptRunner parse:aScript];
        parsedOK = [scriptRunner parsedOK];
        if(parsedOK){
            if([scriptRunner scriptExists]){
                [scriptRunner setFinishCallBack:self selector:@selector(scriptRunnerDidFinish:returnValue:)];
                //if([scriptRunner debugging]){
                //    [scriptRunner setBreakpoints:[self breakpointSet]];
                //}
                [scriptRunner setDebugMode:kRunToBreakPoint];
                //[self shipTaskRecord:self running:YES];
                //if([startMessage length]>0){
                //    NSLog(@"%@\n",startMessage);
                //}
                [scriptRunner run:nil sender:self];
            }
            else {
                [self scriptRunnerDidFinish:YES returnValue:[NSNumber numberWithInt:1]];
            }
        }
    }
    else {
        [scriptRunner stop];
    }
    return parsedOK;
}

-(void) scriptRunnerDidFinish:(BOOL)finished returnValue:(NSNumber*)val{
    [self log:@"CouchDB_remote_script finished"];
}



#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{    
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setHostName: [decoder decodeObjectForKey:@"hostName"]];
    [self setPortNumber: [decoder decodeIntegerForKey:@"port"]];
    [self setDatabaseName:[decoder decodeObjectForKey:@"dbName"]];
    [self setHeartbeat:[decoder decodeIntegerForKey:@"heartbeat"]];
	[self registerNotificationObservers];
    [self setCommands:[decoder decodeObjectForKey:@"cmdTableArray"]];
    [self setCommonMethods:[decoder decodeBoolForKey:@"commonOnly"]];
    [self setStatusLog: [decoder decodeObjectForKey:@"statusLog"]];
    [self setUserName:[decoder decodeObjectForKey:@"userName"]];
    [self setPassword:[decoder decodeObjectForKey:@"password"]];
    //[self setCmdDocName: [decoder decodeObjectForKey:@"cmdDocName"]];
    if(!cmdTableArray){
        [self setDefaults];
    }
   return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:databaseName forKey:@"dbName"];
    [encoder encodeInteger:portNumber forKey:@"port"];
    [encoder encodeObject:hostName forKey:@"hostName"];
    [encoder encodeInteger:heartbeat forKey:@"heartbeat"];
    [encoder encodeObject:cmdTableArray forKey:@"cmdTableArray"];
    [encoder encodeBool:commonMethodsOnly forKey:@"commonOnly"];
    [encoder encodeObject:statusLogString forKey:@"statusLog"];
    [encoder encodeObject:userName forKey:@"userName"];
    [encoder encodeObject:password forKey:@"password"];
    //[encoder encodeObject:cmdDocName forKey:@"cmdDocName"];
}

@end

