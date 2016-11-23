//
//  ORPQResult.m
//
//  2016-06-01 Created by Phil Harvey (Based on ORSqlResult.m by M.Howe)
//
// Ref: https://www.postgresql.org/docs/9.0/static/libpq-exec.html
//

#import "ORPQConnection.h"
#import "ORPQResult.h"

// (constants are from postgresql/src/include/catalog/pg_type.h,
//  but that header doesn't compile, so define them here instead - PH)
enum {
    kPQTypeBool = 16,   // 8 bit boolean
    kPQTypeString = 17, // variable-length string
    kPQTypeChar = 18,   // single 8 bit character
    kPQTypeName = 19,   // 63-byte name
    kPQTypeInt64 = 20,  // 8-byte integer
    kPQTypeInt16 = 21,  // 2-byte integer
    kPQTypeArray16 = 22,// array of 2-byte integers
    kPQTypeInt32 = 23,  // 4-byte integer
};

NSDate* MCPYear0000;

@implementation ORPQResult

- (id) initWithResPtr:(PGresult *) PQResPtr
{
    self = [super init];
    mResult = PQResPtr;
    if (mResult) {
        mNumOfFields = PQnfields(mResult);
        mNumOfRows = PQntuples(mResult);
    }
    else {
        mNumOfFields = mNumOfRows = 0;
    }
    return self;    
}

- (id) init
{
    self = [super init];
    mNumOfFields = mNumOfRows = 0;
    return self;    
}

- (unsigned long long) numOfRows
{
    if (mResult) {
        return mNumOfRows = PQntuples(mResult);
    }
    return mNumOfRows = 0;
}

- (unsigned int) numOfFields
{
    if (mResult) {
        return mNumOfFields = PQnfields(mResult);
    }
    return mNumOfFields = 0;
}

- (id) fetchRowAsType:(MCPReturnType) aType
{

return nil;
/* DO STUFF HERE
 PQTEST_ROW		theRow;
 unsigned long*	theLengths;
 PQTEST_FIELD*	theField;
 int				i;
 id				theReturn;

 if (mResult == NULL) {
        return nil;
    }

    theRow = PQTEST_fetch_row(mResult);
    if (theRow == NULL) {
        return nil;
    }

    switch (aType) {
        case MCPTypeArray:
            theReturn = [NSMutableArray arrayWithCapacity:mNumOfFields];
            break;
        case MCPTypeDictionary:
            if (mNames == nil) {
                [self fetchFieldsName];
            }
            theReturn = [NSMutableDictionary dictionaryWithCapacity:mNumOfFields];
            break;
        default :
            NSLog (@"Unknown type : %d, will return an Array!\n", aType);
            theReturn = [NSMutableArray arrayWithCapacity:mNumOfFields];
            break;
    }

    theLengths = PQTEST_fetch_lengths(mResult);
    theField = PQTEST_fetch_fields(mResult);
    for (i=0; i<mNumOfFields; i++) {
        id	theCurrentObj;

        if (theRow[i] == NULL) {
            theCurrentObj = [NSNull null];
        }
        else {
            char*	theData = calloc(sizeof(char),theLengths[i]+1);
            memcpy(theData, theRow[i],theLengths[i]);
            theData[theLengths[i]] = '\0';

            switch (theField[i].type) {
                case FIELD_TYPE_TINY:
                case FIELD_TYPE_SHORT:
                case FIELD_TYPE_INT24:
                case FIELD_TYPE_LONG:
                    theCurrentObj = (theField[i].flags & UNSIGNED_FLAG) ? [NSNumber numberWithUnsignedLong:strtoul(theData, NULL, 0)] : [NSNumber numberWithLong:strtol(theData, NULL, 0)];
						 break;
                case FIELD_TYPE_LONGLONG:
                   theCurrentObj = (theField[i].flags & UNSIGNED_FLAG) ? [NSNumber numberWithUnsignedLongLong:strtoull(theData, NULL, 0)] : [NSNumber numberWithLongLong:strtoll(theData, NULL, 0)];
                    break;
                case FIELD_TYPE_DECIMAL:
                case FIELD_TYPE_FLOAT:
                case FIELD_TYPE_DOUBLE:
                    theCurrentObj = [NSNumber numberWithDouble:atof(theData)];
                    break;
                case FIELD_TYPE_TIMESTAMP:
                    theCurrentObj = [NSDate dateFromString:[NSString stringWithUTF8String:theData] calendarFormat:@"%Y%m%d%H%M%S"];
                    [theCurrentObj setCalendarFormat:@"%Y-%m-%d %H:%M:%S"];
                    break;
                case FIELD_TYPE_DATE:
                    theCurrentObj = [NSDate dateFromString:[NSString stringWithUTF8String:theData] calendarFormat:@"%Y-%m-%d"];
                    [theCurrentObj setCalendarFormat:@"%Y-%m-%d"];
                    break;
                case FIELD_TYPE_TIME:
                    theCurrentObj = [NSString stringWithUTF8String:theData];
				    break;
                case FIELD_TYPE_DATETIME:
                    theCurrentObj = [NSDate dateFromString:[NSString stringWithCString:theData encoding:NSISOLatin1StringEncoding] calendarFormat:@"%Y-%m-%d %H:%M:%S"];
                    [theCurrentObj setCalendarFormat:@"%Y-%m-%d %H:%M:%S"];
                    break;
                case FIELD_TYPE_YEAR:
                    theCurrentObj = [NSDate dateFromString:[NSString stringWithCString:theData encoding:NSISOLatin1StringEncoding] calendarFormat:@"%Y"];
                    [theCurrentObj setCalendarFormat:@"%Y"];
                    if (! theCurrentObj) {
                        theCurrentObj = MCPYear0000;
                    }
                    break;
                case FIELD_TYPE_VAR_STRING:
                case FIELD_TYPE_STRING:
					theCurrentObj = [NSString stringWithCString:theData encoding:NSISOLatin1StringEncoding];
                    break;
                case FIELD_TYPE_TINY_BLOB:
                case FIELD_TYPE_BLOB:
                case FIELD_TYPE_MEDIUM_BLOB:
                case FIELD_TYPE_LONG_BLOB:
                    theCurrentObj = [NSString stringWithUTF8String:theData];
                   if (!(theField[i].flags & BINARY_FLAG)) { 
                      theCurrentObj = [self stringWithText:theCurrentObj];
                   }
                    break;
                case FIELD_TYPE_SET:
					theCurrentObj = [NSString stringWithCString:theData encoding:NSISOLatin1StringEncoding];
                    break;
                case FIELD_TYPE_ENUM:
					theCurrentObj = [NSString stringWithCString:theData encoding:NSISOLatin1StringEncoding];
                    break;
                case FIELD_TYPE_NULL:
				   theCurrentObj = [NSNull null];
                    break;
                case FIELD_TYPE_NEWDATE:
					theCurrentObj = [NSString stringWithCString:theData encoding:NSISOLatin1StringEncoding];
                    break;
                default:
                    NSLog (@"in fetchRowAsDictionary : Unknown type : %d for column %d, send back a NSData object", (int)theField[i].type, (int)i);
                    theCurrentObj = [NSData dataWithBytes:theData length:theLengths[i]];
                    break;
            }
            free(theData);
            if (theCurrentObj == nil) {
                theCurrentObj = [NSNull null];
            }
        }
        switch (aType) {
            case MCPTypeArray :
                [theReturn addObject:theCurrentObj];
                break;
            case MCPTypeDictionary :
                [theReturn setObject:theCurrentObj forKey:[mNames objectAtIndex:i]];
                break;
            default :
                [theReturn addObject:theCurrentObj];
                break;
        }
    }
 return theReturn;
*/
}


- (NSArray *) fetchRowAsArray
{
    NSMutableArray		*theArray = [self fetchRowAsType:MCPTypeArray];
    if (theArray) {
        return [NSArray arrayWithArray:theArray];
    }
    else {
        return nil;
    }
}


- (NSDictionary *) fetchRowAsDictionary
{
    NSMutableDictionary		*theDict = [self fetchRowAsType:MCPTypeDictionary];
    if (theDict) {
        return [NSDictionary dictionaryWithDictionary:theDict];
    }
    else {
        return nil;
    }
}


- (NSArray *) fetchFieldsName
{
    unsigned int	theNumFields;
    int				i;
    NSMutableArray	*theNamesArray;

    if (mNames) {
        return mNames;
    }
    if (mResult == NULL) {
// If no results, give an empty array. Maybe it's better to give a nil pointer?
        return (mNames = [[NSArray array] retain]);
    }
    
    theNumFields = [self numOfFields];
    theNamesArray = [NSMutableArray arrayWithCapacity: theNumFields];
    for (i=0; i<theNumFields; i++) {
        NSString	*theName = [NSString stringWithCString:PQfname(mResult, i) encoding:NSISOLatin1StringEncoding];
        if ((theName) && (![theName isEqualToString:@""])) {
            [theNamesArray addObject:theName];
        }
        else {
            [theNamesArray addObject:[NSString stringWithFormat:@"Column %d", i]];
        }
    }
    
    return (mNames = [[NSArray arrayWithArray:theNamesArray] retain]);
}

- (int32_t) getInt32atRow:(int)aRow column:(int)aColumn;
{
    int32_t val;
    if (mResult && aRow<mNumOfRows && aColumn<mNumOfFields) {
        Oid type = PQftype(mResult,aColumn);
        char *pt = PQgetvalue(mResult,aRow,aColumn);
        switch (type) {
            case kPQTypeChar:
            case kPQTypeInt64:
            case kPQTypeInt16:
            case kPQTypeInt32:
                val = (int32_t)atol(pt);
                break;
            case kPQTypeBool:
                if (*pt == 'f') {
                    val = 0;
                } else if (*pt == 't') {
                    val = 1;
                } else {
                    val = -1;
                }
                break;
            default:
                val = -1;
                break;
        }
    } else {
        val = -1;
    }
    return val;
}

- (id) fetchTypesAsType:(MCPReturnType) aType
{
    int				i;
    id				theTypes;

    if (mResult == NULL) {
        return nil;
    }

    switch (aType) {
        case MCPTypeArray:
            theTypes = [NSMutableArray arrayWithCapacity:mNumOfFields];
            break;
        case MCPTypeDictionary:
            if (mNames == nil) {
                [self fetchFieldsName];
            }
            theTypes = [NSMutableDictionary dictionaryWithCapacity:mNumOfFields];
            break;
        default :
            NSLog (@"Unknown type : %d, will return an Array!\n", aType);
            theTypes = [NSMutableArray arrayWithCapacity:mNumOfFields];
            break;
    }
    for (i=0; i<mNumOfFields; i++) {
        NSString	*theType;
        Oid ftype = PQftype(mResult,i);
        switch (ftype) {
            case kPQTypeBool:
                theType = @"bool";
                break;
            case kPQTypeString:
                theType = @"byte";
                break;
            case kPQTypeChar:
                theType = @"char";
                break;
            case kPQTypeName:
                theType = @"name";
                break;
            case kPQTypeInt64:
                theType = @"int8";
                break;
            case kPQTypeInt16:
                theType = @"int2";
                break;
            default:
                theType = @"unknown";
                NSLog (@"in fetchTypesAsArray : Unknown type for column %d of the ORPQResult, type = %d", (int)i, (int)ftype);
                break;
        }
        switch (aType) {
            case MCPTypeArray :
                [theTypes addObject:theType];
                break;
            case MCPTypeDictionary :
                [theTypes setObject:theType forKey:[mNames objectAtIndex:i]];
                break;
            default :
                [theTypes addObject:theType];
                break;
        }
    }

    return theTypes;
}


- (NSArray *) fetchTypesAsArray
{
    NSMutableArray		*theArray = [self fetchTypesAsType:MCPTypeArray];
    if (theArray) {
        return [NSArray arrayWithArray:theArray];
    }
    else {
        return nil;
    }
}


- (NSDictionary*) fetchTypesAsDictionary
{
    NSMutableDictionary		*theDict = [self fetchTypesAsType:MCPTypeDictionary];
    if (theDict) {
        return [NSDictionary dictionaryWithDictionary:theDict];
    }
    else {
        return nil;
    }
}


- (NSString *) stringWithText:(NSData *) theTextData
{
    if (theTextData == nil) return nil;
    NSString* theString = [[NSString alloc] initWithData:theTextData encoding:NSISOLatin1StringEncoding];				
    return [theString autorelease];
}


- (NSString *) description
{
    if (mResult == NULL) {
        return @"This is an empty ORPQResult\n";
    }
    else {
        NSMutableString		*theString = [NSMutableString stringWithCapacity:0];
        int			i, j;

        [theString appendFormat:@"ORPQResult: (%ld fields)\n",(long)mNumOfFields];
        [self fetchFieldsName];
        for (i=0; i<(mNumOfFields-1); i++) {
            [theString appendFormat:@"%@\t", [mNames objectAtIndex:i]];
        }
        [theString appendFormat:@"%@\n", [mNames objectAtIndex:i]];
        for (i=0; i<PQntuples(mResult); ++i) {
            for (j=0; j<(mNumOfFields - 1); ++j) {
                [theString appendFormat:@"%s\t", PQgetvalue(mResult, i, j)];
            }
            [theString appendFormat:@"%s\n", PQgetvalue(mResult, i, j)];
        }
        return theString;
    }
}

- (Boolean) isOK
{
    return (mResult && PQresultStatus(mResult) == PGRES_COMMAND_OK);
}

- (void) dealloc
{
    if (mResult) {
        PQclear(mResult);
        mResult = nil;
    }
	
    if (mNames) {
        [mNames autorelease];
    }
    
    [super dealloc];
    return;
}
@end
