//
//  ORCouchDBListenerModel.m
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
#define kCmdUploadDone      @"kCmdUploadDone"
#define kDesignUploadDone   @"kDesignUploadDone"

#define kCouchDBPort 5984

NSString* ORCouchDBListenerModelDatabaseListChanged    = @"ORCouchDBListenerModelDatabaseListChanged";
NSString* ORCouchDBListenerModelListeningChanged       = @"ORCouchDBListenerModelListeningChanged";
NSString* ORCouchDBListenerModelObjectListChanged      = @"ORCouchDBListenerModelObjectListChanged";
NSString* ORCouchDBListenerModelCommandsChanged        =@"ORCouchDBListenerModelCommandsChanged";
NSString* ORCouchDBListenerModelStatusLogChanged       =@"ORCouchDBListenerModelStatusLogChanged";
NSString* ORCouchDBListenerModelHostChanged            = @"ORCouchDBListenerModelHostChanged";
NSString* ORCouchDBListenerModelPortChanged            = @"ORCouchDBListenerModelPortChanged"; 
NSString* ORCouchDBListenerModelDatabaseChanged        = @"ORCouchDBListenerModelDatabaseChanged";
NSString* ORCouchDBListenerModelUsernameChanged        = @"ORCouchDBListenerModelUsernameChanged";
NSString* ORCouchDBListenerModelPasswordChanged            = @"ORCouchDBListenerModelPasswordChanged";
NSString* ORCouchDBListenerModelListeningStatusChanged = @"ORCouchDBListenerModelListeningStatusChanged";
NSString* ORCouchDBListenerModelHeartbeatChanged       = @"ORCouchDBListenerModelHeartbeatChanged";

@interface ORCouchDB (private)
- (void) _uploadCmdDesignDocument;
- (void) _fetchDocument:(NSString*)docName;
- (void) _uploadCmdSection;
- (void) _createCmdDict;
- (void) _processCmdDocument:(NSDictionary*) doc;
- (void) _uploadAllSections;
- (void) statusDBRef;
- (BOOL) checkSyntax:(NSString*) key;
@end

@implementation ORCouchDBListenerModel (private)

- (void) _uploadCmdDesignDocument
{
    
    [self log:@"Uploading _design/orcacommand document..."];
    NSString* filterString = @"function (doc, req)"
                              "{"
                              "   if (doc.type && doc.type == 'command' && !doc.response) { return true; }"
                              "   return false;"
                              "}";
    NSDictionary* filterDict = [NSDictionary dictionaryWithObjectsAndKeys:filterString,@"execute_commands", nil];
    NSDictionary* dict=[NSDictionary dictionaryWithObjectsAndKeys:filterDict,@"filters",nil];
    
    [[self statusDBRef] updateDocument:dict
                            documentId:@"_design/orcacommand"
                                   tag:kDesignUploadDone
                     informingDelegate:YES];
}

- (void) _fetchDocument:(NSString*)docName
{
    [[self statusDBRef] getDocumentId:docName tag:kCommandDocCheck];
}

//DB Interactions

- (void) _uploadCmdSection
{
    [self log:@"Uploading commands section..."];
    [[self statusDBRef] updateDocument:[NSDictionary dictionaryWithObjectsAndKeys:cmdDict,@"keys",nil]
                            documentId:cmdDocName
                                   tag:kCmdUploadDone
                     informingDelegate:YES];
}

- (void) _createCmdDict
{
    [cmdDict release];
    cmdDict = [[NSMutableDictionary alloc] initWithCapacity:256];
    for (id cmd in cmdTableArray) {
        NSMutableDictionary* tempdict= [NSMutableDictionary dictionaryWithDictionary:cmd];
        [tempdict removeObjectForKey:@"Label"];
        [cmdDict setObject:tempdict forKey:[cmd objectForKey:@"Label"]];
    }
    
}

- (void) _processCmdDocument:(NSDictionary*) doc
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
    } else if([[doc valueForKey:@"run"] isEqualToString:@"NO"]) {
        if(scriptRunner){
            if([scriptRunner running]){
                [scriptRunner stop];
            }
        }
    } else {
        
        NSString* message;
        NSString* key=[doc valueForKey:@"execute"];
        NSString* val=[NSString stringWithFormat:@"%@",[doc valueForKey:@"arguments"]];
        
        NSDictionary* cmd=[cmdDict objectForKey:key];
        
        if(cmd){
            if ([self checkSyntax:key]){
                if([self executeCommand:key value:val]){
                    message=[NSString stringWithFormat:@"executed command with label '%@'",key];
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
        NSMutableDictionary* returnDic = [NSMutableDictionary dictionaryWithDictionary:doc];
        [returnDic setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                              message,@"content",
                              [[NSDate date] description],@"timestamp",nil] forKey:@"response"];
        [[self statusDBRef] updateDocument:returnDic
                                documentId:[returnDic objectForKey:@"_id"]
                                       tag:nil];
    }
}

- (void) _uploadAllSections
{
    cmdSectionReady=NO;
    //    scriptSectionready=NO;
    [self _uploadCmdDesignDocument];
    [self _uploadCmdSection];
}

- (ORCouchDB*) statusDBRef
{
    NSString* dbName = [databaseName stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    return [ORCouchDB couchHost:hostName port:portNumber username:userName pwd:password database:dbName delegate:self];
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

@end

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
	[super dealloc];
}

- (void) wakeUp
{
    [super wakeUp];
    
    cmdDocName=@"commands";
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
	
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqual:@"isFinished"]){
        if([change objectForKey:NSKeyValueChangeNewKey]){ //this means the changesfeed operation has finished
            [runningChangesfeed release];
            runningChangesfeed=nil;
            [self log:@"Changesfeed operation finished"];
            [[NSNotificationCenter defaultCenter]
             postNotificationOnMainThreadWithName:ORCouchDBListenerModelListeningChanged
             object:self];
        }
        
    }
}

#pragma mark ***Accessors
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
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelDatabaseChanged object:self];
}

- (void) setHostName:(NSString*)name{

    [hostName release];
    hostName= [name copy];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelHostChanged object:self];
}

- (void) setPortNumber:(NSUInteger)aPort
{
    portNumber=aPort;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelPortChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelUsernameChanged object:self];
}

- (void) setPassword:(NSString*)pwd
{
    [password release];
    password=[pwd copy];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelPasswordChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelHeartbeatChanged object:self];
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

- (NSDictionary*) cmdDict
{
    [self _createCmdDict];
    return [NSDictionary dictionaryWithDictionary:cmdDict];
}

#pragma mark ***DB Access

-(void) startStopSession
{
    if (!runningChangesfeed){
        [self _createCmdDict];
        [self _uploadAllSections];
    }
    else{
        [self log:@"Changes feed cancelled"];
        [runningChangesfeed cancel];
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelListeningChanged object:self];
    }
    
}

-(void) startChangesfeed
{
    runningChangesfeed=[[[self statusDBRef] changesFeedMode:kContinuousFeed
                                                  heartbeat:heartbeat
                                                        tag:kChangesfeed
                                                     filter:@"orcacommand/execute_commands"] retain];
    [runningChangesfeed addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelListeningChanged object:self];
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp
{
	@synchronized(self){
		if([aResult isKindOfClass:[NSDictionary class]]){
            if([aTag isEqualToString:kChangesfeed]){
                [self _fetchDocument:[aResult objectForKey:@"id"]];
            }
            else if([aTag isEqualToString:kCommandDocCheck]){
                [self _processCmdDocument:aResult];
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


- (void) listDatabases
{
	[[self statusDBRef] listDatabases:self tag:kListDB];
}


- (void) sectionReady
{
    if (cmdSectionReady)    // && scriptSectionReady && prmSectionReady
    {
        [self startChangesfeed];
    }
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

- (BOOL) executeCommand:(NSString*) key value:(NSString*)val
{
    [self _createCmdDict];
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


#pragma mark ***Script Section

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
}

@end

