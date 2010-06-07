//
//  ORSqlConnection.m
//  Orca
//
//  Created by Mark Howe on 10/18/06.
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


#import "ORSqlConnection.h"
#import "ORSqlResult.h"

@interface ORSqlConnection (private)
- (NSString*) prepareBinaryData:(NSData *) theData;
- (NSString*) prepareString:(NSString *) theString;
@end

@implementation ORSqlConnection

- (id) init
{   
	self = [super init];
	connected = NO;
	return self;
}

- (void) dealloc
{
	[self disconnect];
	[super dealloc];
}

- (BOOL) connectToHost:(NSString*)aHostName userName:(NSString*)aUserName passWord:(NSString*)aPassWord dataBase:(NSString*)aDataBase
{
	@synchronized(self){
		if(!mConnection){
			mConnection = mysql_init (NULL);
			if(mConnection){
			
				if (mysql_real_connect (mConnection,			[aHostName UTF8String], 
										[aUserName UTF8String], [aPassWord UTF8String],
										[aDataBase UTF8String], 0, nil, 0) == nil){
					
					NSLog(@"mysql_real_connect() failed: %u\n",mysql_errno (mConnection));
					NSLog(@"Error: (%s)\n",mysql_error (mConnection));
					[self disconnect];
					return NO;
				}
				connected = YES;
				NSLog(@"Connected to DataBase %@ on %@\n",aDataBase,aHostName);
				if([aDataBase length]){
					[self selectDB:aDataBase];
				}
			}
			else {
				NSLog(@"ORSql: mysql_init() failed\n");
				connected = NO;				
			}
		}
	}
	return mConnection!=nil;
}


- (void) disconnect
{
	@synchronized(self){
		if (connected) {
			mysql_close(mConnection);
			mConnection = NULL;
			connected = NO;
		}
	}
}

- (BOOL) selectDB:(NSString *) dbName
{
	BOOL result = NO;
	@synchronized(self){
		if(connected){
			if ([dbName length]) {
				if (mysql_select_db(mConnection, [dbName UTF8String]) == 0) {
					result =  YES;
				}
			}
		}
	}

    return result;
}


- (NSString *) getLastErrorMessage
{
	NSString* result = @"";
	@synchronized(self){
		if (mConnection) result= [NSString stringWithCString:mysql_error(mConnection) encoding:NSISOLatin1StringEncoding];
		else			 result= @"No connection initailized yet (MYSQL* still NULL)\n";
	}
	return result;
}

- (unsigned int) getLastErrorID
{
	unsigned int result = 666;
	@synchronized(self){
		if (mConnection) result =  mysql_errno(mConnection);
	}
	return result;
}

- (BOOL) isConnected
{
    return connected;
}

- (BOOL) checkConnection
{
	BOOL result = NO;
	@synchronized(self){
		result = mysql_ping(mConnection);
	}
	return result;
}

- (NSString *) quoteObject:(id) theObject
/*" Use the class of the theObject to know how it should be prepared for usage with the database.
 If theObject is a string, this method will put single quotes to both its side and escape any necessary
 character using prepareString: method. If theObject is NSData, the prepareBinaryData: method will be
 used instead.
 For NSNumber object, the number is just quoted, for calendar dates, the calendar date is formatted in
 the preferred format for the database.
 "*/
{
	NSString* result;
	@synchronized(self){
		if (!theObject) {
			return @"NULL";
		}
		if ([theObject isKindOfClass:[NSData class]]) {
			result = [NSString stringWithFormat:@"'%@'", [self prepareBinaryData:(NSData *) theObject]];
		}
		if ([theObject isKindOfClass:[NSString class]]) {
			result = [NSString stringWithFormat:@"'%@'", [self prepareString:(NSString *) theObject]];
		}
		if ([theObject isKindOfClass:[NSNumber class]]) {
			result = [NSString stringWithFormat:@"%@", theObject];
		}
		if ([theObject isKindOfClass:[NSCalendarDate class]]) {
			result = [NSString stringWithFormat:@"'%@'", [(NSCalendarDate *)theObject descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S"]];
		}
		if ((nil == theObject) || ([theObject isKindOfClass:[NSNull class]])) {
			result = @"NULL";
		}
		// Default : quote as string:
		else result = [NSString stringWithFormat:@"'%@'", [self prepareString:[theObject description]]];
	}
	return result;
}


- (ORSqlResult*) queryString:(NSString *) query
{
	ORSqlResult*	theResult = nil;
	@synchronized(self){
		const char*	theCQuery = [query UTF8String];
		int         theQueryCode;
		if ((theQueryCode = mysql_query(mConnection, theCQuery)) == 0) {
			if (mysql_field_count(mConnection) != 0) {
				theResult = [[[ORSqlResult alloc] initWithMySQLPtr:mConnection]autorelease];
			}
		}
		else {
			NSLog(@"Problem in queryString error code is : %d, query is : %s -in ObjC : %@-\n", theQueryCode, theCQuery, query);
			NSLog(@"Error message is : %@\n", [self getLastErrorMessage]);
		}
	}
    return theResult ;
}

- (unsigned long long) affectedRows
{
	unsigned long long num = 0;
	@synchronized(self){
		if (connected) {
			num = mysql_affected_rows(mConnection);
		}
	}
    return num;
}


- (unsigned long long) insertId
/*"
 If the last query was an insert in a table having a autoindex column, returns the id (autoindexed field) of the last row inserted.
 "*/
{
	unsigned long long num = 0;
	@synchronized(self){
		if (connected) {
			num = mysql_insert_id(mConnection);
		}
	}
    return num;
}

- (ORSqlResult *) listDBs
{
    ORSqlResult*  theResult = nil;
	@synchronized(self){
		MYSQL_RES*	theResPtr;
	
		if (theResPtr = mysql_list_dbs(mConnection, NULL)) {
			theResult = [[[ORSqlResult alloc]initWithResPtr: theResPtr]autorelease];
		}	
	}
    return theResult;    
}


- (ORSqlResult*) listTables
{
    ORSqlResult* theResult = nil;
 	@synchronized(self){
		MYSQL_RES* theResPtr;
	
		if (theResPtr = mysql_list_tables(mConnection, NULL)) {
			theResult = [[[ORSqlResult alloc] initWithResPtr: theResPtr]autorelease];
		}
	}
    return theResult;
}


- (ORSqlResult *) listTablesFromDB:(NSString *) dbName 
{	
	ORSqlResult* theResult = nil;
	@synchronized(self){
		NSString* theQuery   = [NSString stringWithFormat:@"SHOW TABLES FROM %@", dbName];
		theResult = [self queryString:theQuery];
	}
    return theResult;
}


- (ORSqlResult*)listFieldsFromTable:(NSString *)tableName
{	
	ORSqlResult* theResult = nil;
	@synchronized(self){
		NSString*  theQuery = [NSString stringWithFormat:@"SHOW COLUMNS FROM %@", tableName];
		theResult = [self queryString:theQuery];
	}
    return theResult;
}


- (NSString*) clientInfo
{
	NSString* result = nil;
	@synchronized(self){
		result =  [NSString stringWithCString:mysql_get_client_info() encoding:NSISOLatin1StringEncoding];
	}
	return result;
}

- (NSString *) hostInfo
/*"
 Returns a string giving information on the host of the DB server.
 "*/
{
	NSString* result = nil;
	@synchronized(self){
		if (connected) {
			result = [NSString stringWithCString:mysql_get_host_info(mConnection) encoding:NSISOLatin1StringEncoding];
		}
	}
	return result;
}


- (NSString *) serverInfo
{
 	NSString* result = nil;
	@synchronized(self){
		if (connected) {
			result = [NSString stringWithCString: mysql_get_server_info(mConnection) encoding:NSISOLatin1StringEncoding];
		}
	}
    return result;
}

- (NSNumber*) protoInfo
{
	NSNumber* result = nil;
 	@synchronized(self){
		if (connected) {
			result= [NSNumber numberWithUnsignedInt:mysql_get_proto_info(mConnection) ];
		}
	}
	return result;
}


- (ORSqlResult *) listProcesses
{
    ORSqlResult* theResult = nil;
	@synchronized(self){
		MYSQL_RES* theResPtr;
	
		if (theResPtr = mysql_list_processes(mConnection)) {
			theResult = [[[ORSqlResult alloc] initWithResPtr:theResPtr] autorelease];
		}
	}
    return theResult;
}

/*
 - (BOOL)createDBWithName:(NSString *)dbName
 {
 const char	*theDBName = [dbName UTF8String];
 if ((connected) && (! mysql_create_db(mConnection, theDBName))) {
 return YES;
 }
 return NO;
 }
 
 - (BOOL)dropDBWithName:(NSString *)dbName
 {
 const char	*theDBName = [dbName UTF8String];
 if ((connected) && (! mysql_drop_db(mConnection, theDBName))) {
 return YES;
 }
 return NO;
 }
 */

- (BOOL) killProcess:(unsigned long) pid
{	
    int theErrorCode = 0; 
	@synchronized(self){
		theErrorCode = mysql_kill(mConnection, pid);
	}
    return (theErrorCode) ? NO : YES;
}

@end

@implementation ORSqlConnection (private)

- (NSString*) prepareBinaryData:(NSData *) theData
{
	const char*	 theCDataBuffer = [theData bytes];
	unsigned int theLength = [theData length];
	char*		 theCEscBuffer = (char *)calloc(sizeof(char),(theLength*2) + 1);
	
	mysql_real_escape_string(mConnection, theCEscBuffer, theCDataBuffer, theLength);
	NSString* theReturn = [NSString stringWithCString:theCEscBuffer encoding:NSISOLatin1StringEncoding];
	free (theCEscBuffer);
	
    return theReturn;
}


- (NSString *) prepareString:(NSString *) theString
{
    const char*	 theCStringBuffer = [theString UTF8String];
    unsigned int theLength;
    char*		 theCEscBuffer;
    NSString*    theReturn;
	
    if ([theString length]==0) {
        return @"";
    }
    theLength = strlen(theCStringBuffer);
    theCEscBuffer = (char *)calloc(sizeof(char),(theLength * 2) + 1);
    mysql_real_escape_string(mConnection, theCEscBuffer, theCStringBuffer, theLength);
    theReturn = [NSString stringWithCString:theCEscBuffer encoding:NSISOLatin1StringEncoding];
    free (theCEscBuffer);
    return theReturn;    
}
@end
