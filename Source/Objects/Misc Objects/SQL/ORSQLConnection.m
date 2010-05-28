

#import "ORSqlConnection.h"
#import "ORSqlResult.h"


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
	if(mConnection) return YES;
	mConnection = mysql_init (NULL);
	
	if (mConnection == nil){
		NSLog(@"ORSql: mysql_init() failed\n");
		connected = NO;
		return NO;
	}
	
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
	//[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlConnectionChanged object:self];
	if([aDataBase length]){
		[self selectDB:aDataBase];
	}
	return YES;
}


- (void) disconnect
{
    if (connected) {
        mysql_close(mConnection);
        mConnection = NULL;
		connected = NO;
		//[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlConnectionChanged object:self];
    }
    return;
}

- (BOOL) selectDB:(NSString *) dbName
{
    if (dbName == nil) {
        return NO;
    }
    if ([dbName length]  && connected) {
        if (mysql_select_db(mConnection, [dbName UTF8String]) == 0) {
            return YES;
        }
    }
    return NO;
}


- (NSString *) getLastErrorMessage
{
    if (mConnection) return [NSString stringWithCString:mysql_error(mConnection) encoding:NSUTF8StringEncoding];
    else			 return @"No connection initailized yet (MYSQL* still NULL)\n";
}

- (unsigned int) getLastErrorID
{
    if (mConnection) return mysql_errno(mConnection);
    return			 6666;
}

- (BOOL) isConnected
{
    return connected;
}

- (BOOL) checkConnection
{
    return (BOOL)(! mysql_ping(mConnection));
}

- (NSString*) prepareBinaryData:(NSData *) theData
{
    const char*	 theCDataBuffer = [theData bytes];
    unsigned int theLength = [theData length];
    char*		 theCEscBuffer = (char *)calloc(sizeof(char),(theLength*2) + 1);
    NSString*	 theReturn;
	
    mysql_real_escape_string(mConnection, theCEscBuffer, theCDataBuffer, theLength);
    theReturn = [NSString stringWithCString:theCEscBuffer encoding:NSUTF8StringEncoding];
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
    theReturn = [NSString stringWithCString:theCEscBuffer encoding:NSUTF8StringEncoding];
    free (theCEscBuffer);
    return theReturn;    
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
	if (!theObject) {
		return @"NULL";
	}
	if ([theObject isKindOfClass:[NSData class]]) {
		return [NSString stringWithFormat:@"'%@'", [self prepareBinaryData:(NSData *) theObject]];
	}
	if ([theObject isKindOfClass:[NSString class]]) {
		return [NSString stringWithFormat:@"'%@'", [self prepareString:(NSString *) theObject]];
	}
	if ([theObject isKindOfClass:[NSNumber class]]) {
		return [NSString stringWithFormat:@"%@", theObject];
	}
	if ([theObject isKindOfClass:[NSCalendarDate class]]) {
		return [NSString stringWithFormat:@"'%@'", [(NSCalendarDate *)theObject descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S"]];
	}
	if ((nil == theObject) || ([theObject isKindOfClass:[NSNull class]])) {
		return @"NULL";
	}
	// Default : quote as string:
	return [NSString stringWithFormat:@"'%@'", [self prepareString:[theObject description]]];
}


- (ORSqlResult*) queryString:(NSString *) query
{
    ORSqlResult*	theResult = [ORSqlResult alloc];
    const char*	theCQuery = [query UTF8String];
    int         theQueryCode;
    if ((theQueryCode = mysql_query(mConnection, theCQuery)) == 0) {
        if (mysql_field_count(mConnection) != 0) {
            theResult = [theResult initWithMySQLPtr:mConnection];
        }
        else {
            return nil;
        }
    }
    else {
		NSLog (@"Problem in queryString error code is : %d, query is : %s -in ObjC : %@-\n", theQueryCode, theCQuery, query);
		NSLog(@"Error message is : %@\n", [self getLastErrorMessage]);
		theResult = nil;
    }
    if (theResult) {
        [theResult autorelease];
    }
    return theResult;
}

- (unsigned long long) affectedRows
{
    if (connected) {
        return mysql_affected_rows(mConnection);
    }
    return 0;
}


- (unsigned long long) insertId
/*"
 If the last query was an insert in a table having a autoindex column, returns the id (autoindexed field) of the last row inserted.
 "*/
{
    if (connected) {
        return mysql_insert_id(mConnection);
    }
    return 0;
}


- (ORSqlResult *) listDBs
{
    ORSqlResult*  theResult = [ORSqlResult alloc];
    MYSQL_RES*	theResPtr;
	
	if (theResPtr = mysql_list_dbs(mConnection, NULL)) {
		[theResult initWithResPtr: theResPtr];
	}
	else {
		[theResult init];
	}
	if (theResult) {
        [theResult autorelease];
    }
    return theResult;    
}


- (ORSqlResult*) listTables
{
    ORSqlResult* theResult = [ORSqlResult alloc];
    MYSQL_RES* theResPtr;
	
	if (theResPtr = mysql_list_tables(mConnection, NULL)) {
		[theResult initWithResPtr: theResPtr];
	}
	else {
		[theResult init];
	}

    if (theResult) {
        [theResult autorelease];
    }
    return theResult;
}


- (ORSqlResult *) listTablesFromDB:(NSString *) dbName 
{	
	NSString* theQuery   = [NSString stringWithFormat:@"SHOW TABLES FROM %@", dbName];
	ORSqlResult* theResult = [self queryString:theQuery];
    return theResult;
}


- (ORSqlResult*)listFieldsFromTable:(NSString *)tableName
{	
	NSString*  theQuery = [NSString stringWithFormat:@"SHOW COLUMNS FROM %@", tableName];
	ORSqlResult* theResult = [self queryString:theQuery];
    return theResult;
}


- (NSString*) clientInfo
{
    return [NSString stringWithCString:mysql_get_client_info() encoding:NSUTF8StringEncoding];
}


- (NSString *) hostInfo
/*"
 Returns a string giving information on the host of the DB server.
 "*/
{
    return [NSString stringWithCString:mysql_get_host_info(mConnection) encoding:NSUTF8StringEncoding];
}


- (NSString *) serverInfo
{
    if (connected) {
        return [NSString stringWithCString: mysql_get_server_info(mConnection) encoding:NSUTF8StringEncoding];
    }
    return @"";
}


- (NSNumber *) protoInfo
{
    return [NSNumber numberWithUnsignedInt:mysql_get_proto_info(mConnection) ];
}


- (ORSqlResult *) listProcesses
{
    ORSqlResult* theResult = [ORSqlResult alloc];
    MYSQL_RES* theResPtr;
	
    if (theResPtr = mysql_list_processes(mConnection)) {
        [theResult initWithResPtr:theResPtr];
    } else {
        [theResult init];
    }
	
    if (theResult) {
        [theResult autorelease];
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
    int theErrorCode = mysql_kill(mConnection, pid);
    return (theErrorCode) ? NO : YES;
}

@end
