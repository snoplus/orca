//-------------------------------------------------------------------------
//  ORSqlModel.h
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

@class ORSqlConnection;

@interface ORSqlModel : OrcaObject
{
@private
	NSOperationQueue* queue;
	ORSqlConnection* sqlConnection;
	BOOL		connectionValid;
	NSString*	hostName;
    NSString*	userName;
    NSString*	password;
    NSString*	dataBaseName;
	NSMutableArray* dataMonitors;
    BOOL		stealthMode;
}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;

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
- (void) logQueryException:(NSException*)e;
- (id) nextObject;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***SQL Access
- (BOOL) testConnection;
- (BOOL) connectionValid;
- (void) disconnect;
@end

extern NSString* ORSqlModelStealthModeChanged;
extern NSString* ORSqlDataBaseNameChanged;
extern NSString* ORSqlPasswordChanged;
extern NSString* ORSqlUserNameChanged;
extern NSString* ORSqlHostNameChanged;
extern NSString* ORSqlConnectionValidChanged;
extern NSString* ORSqlLock;

@interface ORSqlOperation : NSOperation
{
	ORSqlConnection* sqlConnection;
	id delegate;
}

- (id)	 initWithSqlConnection:(ORSqlConnection*)aSqlConnection delegate:(id)aDelegate;
- (void) dealloc;
@end

@interface ORPostMachineNameOp : ORSqlOperation
- (void) main;
@end

@interface ORDeleteMachineNameOp : ORSqlOperation
- (void) main;
@end

@interface ORPostRunStateOp : ORSqlOperation
{
	int runState;
	int runNumber;
	int subRunNumber;
	int elapsedTime;
	NSString* experimentName;
}
- (void) setExperimentName:(NSString*)anExperiment;
- (void) setRunState:(NSNotification*)aNote;
- (void) main;
@end

@interface ORPostDataOp : ORSqlOperation
{
	NSArray* dataMonitors;
}
- (void) setDataMonitors:(id)someMonitors;
- (void) main;
@end


@interface ORPostExperimentOp : ORSqlOperation
{
	id experiment;
}
- (void) dealloc;
- (void) setExperiment:(id)anExperiment;
- (void) main;
@end

#define kClear 0
#define kPost  1
@interface ORPostAlarmOp : ORSqlOperation
{
	BOOL opType;
	id alarm;
}
- (void) dealloc;
- (void) postAlarm:(id)anAlarm;
- (void) clearAlarm:(id)anAlarm;
- (void) main;
@end

@interface ORPostSegmentMapOp : ORSqlOperation
{
	int monitor_id;
}
- (void) dealloc;
- (void) setDataMonitorId:(int)anID;
- (void) main;
@end


@interface NSObject (ORSqlModel)
- (int) maxNumSegments;
- (NSMutableData*) thresholdDataForSet:(int)aSet;
- (NSMutableData*) gainDataForSet:(int)aSet;
- (NSMutableData*) rateDataForSet:(int)aSet;
@end


