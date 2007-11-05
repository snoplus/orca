// -----------------------------------------------------------------------------------
// NKDPostgreSQLConnection.m
// -----------------------------------------------------------------------------------
//  Created by Jeff LaMarche on Sat Jul 13 2002.
//  ©2002 Naked Software. All rights reserved.
// -----------------------------------------------------------------------------------
// THIS	SOURCE CODE IS PROVIDED AS-IS WITH NO WARRANTY OF ANY KIND
// -----------------------------------------------------------------------------------
// You may use and redistribute this source code without the following limitations
// -----------------------------------------------------------------------------------
 
#import "NKDPostgreSQLConnection.h"


@implementation NKDPostgreSQLConnection
// -----------------------------------------------------------------------------------
+(id)connectionWithHost: (NSString *)inHost
            HostAddress: (NSString *)inHostAddress
                   Port: (NSString *)inPort
           DatabaseName: (NSString *)inDBName
                   User: (NSString *)inUser
               Password: (NSString *)inPassword
// -----------------------------------------------------------------------------------
{
    // *** TO DO: escape out forward slashes and single quotes in any NSString values
    NKDPostgreSQLConnection 	*sConn = 	[[NKDPostgreSQLConnection alloc] init];
    NSMutableString 		*connInfo = 	[NSMutableString stringWithString: @""];

    if (inHost != nil)
        [connInfo appendString:[NSString stringWithFormat:@"host='%@' ", inHost]];

    if (inHostAddress != nil)
        [connInfo appendString:[NSString stringWithFormat:@"hostaddr='%@' ", inHostAddress]];

    if (inPort != nil)
        [connInfo appendString:[NSString stringWithFormat:@"port='%@' ", inPort]];

    if (inDBName != nil)
        [connInfo appendString:[NSString stringWithFormat:@"dbname='%@'", inDBName]];

    if (inUser != nil)
        [connInfo appendString:[NSString stringWithFormat:@"user='%@'", inUser]];

    if (inPassword != nil)
        [connInfo appendString:[NSString stringWithFormat:@"password='%@'", inPassword]];


    [sConn _setConn: PQconnectdb([connInfo cString])];
    return [sConn autorelease];

}
// -----------------------------------------------------------------------------------
+(id)connectionWithDatabaseName: (NSString *)inDBName
                           User: (NSString *)inUser
                       Password: (NSString *)inPassword
// -----------------------------------------------------------------------------------
{
    return [self connectionWithHost: nil
                        HostAddress: nil
                               Port: nil
                       DatabaseName: inDBName
                               User: inUser
                           Password: inPassword];
}
// -----------------------------------------------------------------------------------
+(id)connectionWithHost: (NSString *)inHost
           DatabaseName: (NSString *)inDBName
                   User: (NSString *)inUser
               Password: (NSString *)inPassword
// -----------------------------------------------------------------------------------
{
    return [self connectionWithHost: inHost
                        HostAddress: nil
                               Port: nil
                       DatabaseName: inDBName
                               User: inUser
                           Password: inPassword];
}
// -----------------------------------------------------------------------------------
+(id)connectionWithHostAddress: (NSString *)inHostAddress
                          Port: (NSString *)inPort
                  DatabaseName: (NSString *)inDBName
                          User: (NSString *)inUser
                      Password: (NSString *)inPassword
// -----------------------------------------------------------------------------------
{
    return [self connectionWithHost: nil
                        HostAddress: inHostAddress
                               Port: inPort
                       DatabaseName: inDBName
                               User: inUser
                           Password: inPassword];
}
// -----------------------------------------------------------------------------------
-(PGconn *)_conn
// -----------------------------------------------------------------------------------
{
    return conn;
}
// -----------------------------------------------------------------------------------
-(void)_setConn:(PGconn *)inConn
// -----------------------------------------------------------------------------------
{
    conn = inConn;
}
// -----------------------------------------------------------------------------------
-(NSString *)host
// -----------------------------------------------------------------------------------
{
    return [NSString stringWithCString: PQhost(conn)];
}
// -----------------------------------------------------------------------------------
-(NSString *)port
// -----------------------------------------------------------------------------------
{
    return [NSString stringWithCString: PQport(conn)];
}
// -----------------------------------------------------------------------------------
-(NSString *)databaseName
// -----------------------------------------------------------------------------------
{
    return [NSString stringWithCString: PQdb(conn)]; 
}
// -----------------------------------------------------------------------------------
-(NSString *)user
// -----------------------------------------------------------------------------------
{
    return [NSString stringWithCString: PQuser(conn)];
}
// -----------------------------------------------------------------------------------
-(NSString *)password
// -----------------------------------------------------------------------------------
{
    return [NSString stringWithCString: PQpass(conn)];
}
// -----------------------------------------------------------------------------------
-(BOOL)isConnected
// -----------------------------------------------------------------------------------
{
    return PQstatus(conn) == CONNECTION_OK;
}
// -----------------------------------------------------------------------------------
-(BOOL)isConnectionBad
// -----------------------------------------------------------------------------------
{
    return PQstatus(conn) == CONNECTION_BAD;
}
// -----------------------------------------------------------------------------------
-(NSString *)errorMessage
// -----------------------------------------------------------------------------------
{
    return [NSString stringWithCString: PQerrorMessage(conn)];
}
// -----------------------------------------------------------------------------------
-(NKDPostgreSQLResult *)executeQuery: (NSString *)query
// -----------------------------------------------------------------------------------
{
    PGresult *result = PQexec(conn, [query cString]);
    ExecStatusType status = PQresultStatus(result);
    NKDPostgreSQLResult *ret = nil;
    
     if (status == PGRES_TUPLES_OK)
		 ret = [NKDPostgreSQLResult resultWithPGresult:result];
     else
		 [[NSException exceptionWithName:@"PostgreSQL TUPLES Error Exception"
				 reason:@"Database gave error"
			       userInfo:[NSString stringWithCString:PQresultErrorMessage(result)]] raise];
    
    return ret;
}
// -----------------------------------------------------------------------------------
-(void)executeUpdate: (NSString *)query
// -----------------------------------------------------------------------------------
{
    PGresult *result = PQexec(conn, [query cString]);
    ExecStatusType status = PQresultStatus(result);

    switch (status)
    {
	case PGRES_FATAL_ERROR:
	    [[NSException exceptionWithName:@"PostgreSQL Fatal Error Exception"
				     reason:@"Database system gave fatal error"
				   userInfo:[NSString stringWithCString:PQresultErrorMessage(result)]] raise];
	    break;
	case PGRES_BAD_RESPONSE:
	    [[NSException exceptionWithName:@"PostgreSQL Bad Response Exception"
				     reason:@"Database system gave bad response"
				   userInfo:[NSString stringWithCString:PQresultErrorMessage(result)]] raise];
	    break;
	case PGRES_NONFATAL_ERROR:
	    [[NSException exceptionWithName:@"PostgreSQL Non-Fatal Error Exception"
				     reason:@"Database system gave non-fatal error"
				   userInfo:[NSString stringWithCString:PQresultErrorMessage(result)]] raise];
	    break;
	default:
	    // nothing
	    break;
    }

	    

}
// -----------------------------------------------------------------------------------
-(void)dealloc
// -----------------------------------------------------------------------------------
{
    PQfinish(conn);
	[super dealloc];
}
@end
