

#import "mysql.h"

@class ORSqlResult;

@interface ORSqlConnection : NSObject {
	@protected
		MYSQL* mConnection;
		BOOL   connected;	
}

- (id) init;
- (void) dealloc;
- (BOOL) connectToHost:(NSString*)aHostName userName:(NSString*)aUserName passWord:(NSString*)aPassWord dataBase:(NSString*)aDataBase;
- (void) disconnect;
- (BOOL) selectDB:(NSString *) dbName;
- (NSString*) getLastErrorMessage;
- (unsigned int) getLastErrorID;
- (BOOL) isConnected;
- (BOOL) checkConnection;
- (NSString*) prepareBinaryData:(NSData *) theData;
- (NSString *) prepareString:(NSString *) theString;
- (NSString *) quoteObject:(id) theObject;
- (ORSqlResult*) queryString:(NSString *) query;
- (unsigned long long) affectedRows;
- (unsigned long long) insertId;
- (ORSqlResult *)listDBs;
- (ORSqlResult*) listTables;
- (ORSqlResult*) listTablesFromDB:(NSString *) dbName;
- (ORSqlResult*) listFieldsFromTable:(NSString *)tableName;
- (NSString*)  clientInfo;
- (NSString*)  hostInfo;
- (NSString*)  serverInfo;
- (NSNumber*)  protoInfo;
- (ORSqlResult*) listProcesses;
//- (BOOL)createDBWithName:(NSString *)dbName;
//- (BOOL)dropDBWithName:(NSString *)dbName;
- (BOOL) killProcess:(unsigned long) pid;
@end

