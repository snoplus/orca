//-------------------------------------------------------------------------
//  ORCouchDBModel.h
//
//  Created by Mark A. Howe on Wednesday 10/18/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

#pragma mark ***Imported Files

@interface ORCouchDBModel : OrcaObject
{
@private
	NSString*	hostName;
    NSString*	userName;
    NSString*	password;
    NSString*	dataBaseName;
	BOOL		stealthMode;
	NSDictionary* dBInfo;
}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) applicationIsTerminating:(NSNotification*)aNote;
- (void) runStatusChanged:(NSNotification*)aNote;
- (void) alarmsChanged:(NSNotification*)aNote;

#pragma mark ***Accessors
- (BOOL) stealthMode;
- (void) setStealthMode:(BOOL)aStealthMode;
- (NSString*) dataBaseName;
- (void) setDataBaseName:(NSString*)aDataBaseName;
- (NSString*) password;
- (void) setPassword:(NSString*)aPassword;
- (NSString*) userName;
- (void) setUserName:(NSString*)aUserName;
- (NSString*) hostName;
- (void) setHostName:(NSString*)aHostName;
- (id) nextObject;
- (NSString*) machineName;
- (void) setDBInfo:(NSDictionary*)someInfo;
- (NSDictionary*) dBInfo;

#pragma mark ***DB Access
- (void) createDatabase;
- (void) deleteDatabase;
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag;
//test functions
- (void) databaseInfo:(BOOL)toStatusWindow;
- (void) listDatabases;
- (void) updateFunction;
- (void) compactDatabase;
- (void) updateDatabaseStats;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORCouchDBDataBaseNameChanged;
extern NSString* ORCouchDBPasswordChanged;
extern NSString* ORCouchDBUserNameChanged;
extern NSString* ORCouchDBHostNameChanged;
extern NSString* ORCouchDBModelStealthModeChanged;
extern NSString* ORCouchDBModelDBInfoChanged;
extern NSString* ORCouchDBLock;



