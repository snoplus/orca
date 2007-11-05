//
//  ORCommandCenter.h
//  Orca
//
//  Created by Mark Howe on Thu Nov 06 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files

#pragma mark •••Forward Declarations
@class NetSocket;
@class ORCommandClient;
@class ORScriptRunner;

#pragma mark •••Definitions
#define kORCommandPort 4667

@interface ORCommandCenter : NSObject
{
    NSMutableDictionary*    destinationObjects;
    int                     socketPort;
    NetSocket*              serverSocket;
    NSMutableArray*         clients;
    NSTimer*				heartBeatTimer;
	NSMutableArray*			args;

	NSString*				script;
	ORScriptRunner*			scriptRunner;
	BOOL					parsedOK;
	NSString*				lastFile;
	
	unsigned				historyIndex;
	NSMutableArray*			history;
}

+ (id) sharedInstance;

- (void) registerNotificationObservers;
- (void) serve;
- (NSUndoManager *)undoManager;

#pragma mark •••Accessors
- (id) arg:(int)index;
- (void) setArg:(int)index withValue:(id)aValue;
- (NSDictionary*) destinationObjects;
- (void) setDestinationObjects:(NSMutableDictionary*)newDestinationObjects;
- (void) addDestination:(id)obj;
- (void) removeDestination:(id)obj;
- (int) socketPort;
- (void) setSocketPort:(int)aPort;
- (void) setClients:(NSMutableArray*)someClients;
- (NSArray*)clients;
- (int) clientCount;
- (void) taskListChanged:(NSNotification*)aNotification;
- (void) documentClosed:(NSNotification*)aNotification;
- (void) objectsAdded:(NSNotification*)aNotification;
- (void) objectsRemoved:(NSNotification*)aNotification;
- (void) runStatusChanged:(NSNotification*)aNotification;
- (void) alarmWasCleared:(NSNotification*)aNotification;
- (void) alarmWasPosted:(NSNotification*)aNotification;
- (void) timeToBeat:(NSTimer*)aTimer;
- (NSString*) script;
- (void) setScript:(NSString*)aString;
- (void) setScriptNoNote:(NSString*)aString;
- (BOOL) parsedOK;
- (ORScriptRunner*) scriptRunner;
- (NSString*) lastFile;
- (void) setLastFile:(NSString*)aFile;

#pragma mark ***Script Methods
- (void) scriptRunnerDidFinish:(BOOL)normalFinish returnValue:(id)aValue;
- (void) parseScript;
- (void) runScript;
- (BOOL) running;
- (void) stopScript;
- (void) loadScriptFromFile:(NSString*)aFilePath;
- (void) saveFile;
- (void) saveScriptToFile:(NSString*)aFilePath;
- (void) moveInHistoryDown;
- (void) moveInHistoryUp;

#pragma mark •••Data Handling
- (void) clientDisconnected:(id)aClient;
- (void) handleCommand:(NSString*)aCommandString fromClient:(id)aClient;
- (void) handleLocalCommand:(NSString*)aCommandString;
- (void) addCommandToHistory:(NSString*)aCommandString;

#pragma mark •••Delegate Methods
- (void) netsocket:(NetSocket*)inNetSocket connectionAccepted:(NetSocket*)inNewNetSocket;
- (void) clientChanged:(id)aClient;

#pragma mark •••Update Methods
- (void) sendCmd:(NSString*)aCmd withString:(NSString*)aStrin;
- (void) sendCurrentAlarms:(ORCommandClient*)client;
- (void) sendCurrentRunStatus:(ORCommandClient*)client;
- (void) sendHeartBeat:(ORCommandClient*)client;
@end

@interface NSObject (ORCommandProtocal)
- (NSString*) commandID;
@end

extern NSString* ORCommandArgsChanged;
extern NSString* ORCommandPortChangedNotification;
extern NSString* ORCommandClientsChangedNotification;
extern NSString* ORCommandScriptChanged;
extern NSString* ORCommandCommandChangedNotification;
extern NSString* ORCommandLastFileChangedNotification;