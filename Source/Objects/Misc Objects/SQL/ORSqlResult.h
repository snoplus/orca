
#import "mysql.h"

typedef enum {
    MCPTypeArray = 1,
    MCPTypeDictionary = 2,
    MCPTypeFlippedArray = 3,
    MCPTypeFlippedDictionary = 4
} MCPReturnType;

@interface ORSqlResult : NSObject {
@protected
	MYSQL_RES*		mResult;	/*"The MYSQL_RES structure of the C API"*/
	NSArray*		mNames;	/*"An NSArray holding the name of the columns"*/
    NSDictionary*	mMySQLLocales;	/*"A Locales dictionary to define the locales of MySQL"*/
    unsigned int    mNumOfFields;	/*"The number of fields in the result"*/
}

- (id) initWithMySQLPtr:(MYSQL*) mySQLPtr;
- (id) initWithResPtr:(MYSQL_RES*) mySQLResPtr;
- (id) init;
- (void) dealloc;
- (unsigned long long) numOfRows;
- (unsigned int) numOfFields;
- (void) dataSeek:(unsigned long long) row;
- (id) fetchRowAsType:(MCPReturnType) aType;
- (NSArray *) fetchRowAsArray;
- (NSDictionary *) fetchRowAsDictionary;
- (NSArray *) fetchFieldsName;
- (id) fetchTypesAsType:(MCPReturnType) aType;
- (NSArray *) fetchTypesAsArray;
- (NSDictionary*) fetchTypesAsDictionary;
- (unsigned int) fetchFlagsAtIndex:(unsigned int) index;
- (unsigned int) fetchFlagsForKey:(NSString *) key;
- (BOOL) isBlobAtIndex:(unsigned int) index;
- (BOOL) isBlobForKey:(NSString *) key;
- (NSString *) stringWithText:(NSData *) theTextData;
- (NSString *) description;

@end
