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


#import </usr/include/objc/objc-class.h>
#import </usr/include/objc/Protocol.h>

//-----------------------------------------------------------------------------
/*!\func	convertTimeCharToLong
 * \brief	Converts a date/time string in standard format to a long.
 * \param	aTime			- Pointer to char holding time as characters
 * \note 	Long is assumed to use time_t format. aTime is assumed to be in the format
 *          yyyy/mm/dd hh:mm:ss given mm: 1-12, dd: 1-31, and hh as 0-24.
 *  		asTime has to be 20 chars wide.
 */
//-----------------------------------------------------------------------------
long 	convertTimeCharToLong( char* aTime )
{
// set the tm structure using the character format
    NSString*	timeStr;
	struct tm	timeStruct;
    char		tmpStorage[ 16 ];
    
    timeStr = [ NSString stringWithCString: aTime ];
	
	[[timeStr substringWithRange:NSMakeRange( 0, 4 )] getCString:tmpStorage maxLength:4 encoding:NSASCIIStringEncoding];
	timeStruct.tm_year = atoi( tmpStorage ) - 1900;
    
	[[timeStr substringWithRange:NSMakeRange( 5,2 )] getCString:tmpStorage maxLength:4 encoding:NSASCIIStringEncoding];
	timeStruct.tm_mon = atoi( tmpStorage );
    
	[[timeStr substringWithRange:NSMakeRange( 8,2 )] getCString:tmpStorage maxLength:4 encoding:NSASCIIStringEncoding];
    timeStruct.tm_mday = atoi( tmpStorage );

	[[timeStr substringWithRange:NSMakeRange( 11,2 )] getCString:tmpStorage maxLength:4 encoding:NSASCIIStringEncoding];
	timeStruct.tm_hour = atoi( tmpStorage );

	[[timeStr substringWithRange:NSMakeRange( 14,2 )] getCString:tmpStorage maxLength:4 encoding:NSASCIIStringEncoding];
	timeStruct.tm_min = atoi( tmpStorage );

	[[timeStr substringWithRange:NSMakeRange( 17,2 )] getCString:tmpStorage maxLength:4 encoding:NSASCIIStringEncoding];
	timeStruct.tm_sec = atoi( tmpStorage );	
	
	return( mktime( &timeStruct ) );	

}

//-----------------------------------------------------------------------------
/*!\func 	convertTimeLongToChar
 * \brief	Convert a standard unix time to the standard char format.
 * \note 	Long is assumed to use time_t format.  psTime will be in the format
 *        	yyyy/mm/dd hh:mm:ss given mm: 1-12, dd: 1-31, and hh as 0-24.
 *		  	psTime has to be 20 chars wide.
 */
//-----------------------------------------------------------------------------
void convertTimeLongToChar( time_t anTime, char *asTime )
{
	struct tm *timeStruct = localtime( &anTime );
	strftime( asTime, 20, "%Y/%m/%d %H:%M:%S", timeStruct ); 
}

//-----------------------------------------------------------------------------
/*!\func 	ORKeyFromId
 * \brief	Returns an NSNumber that contains an Objects pointer value. Useful 
 *			when storing an obj keyed to itself in a dictionary.
 */
//-----------------------------------------------------------------------------
id		ORKeyFromId(id anObj)
{
	return [NSNumber numberWithLong:(long)anObj];
}

int random_range(int lowest_number, int highest_number)
{
    if(lowest_number > highest_number){
		int temp = lowest_number;
		lowest_number = highest_number;
		highest_number = temp;
	}

    int range = highest_number - lowest_number + 1;
	return rand() % range + lowest_number;
   // return lowest_number + (int)(range * rand()/(RAND_MAX + 1.0));
}

//-----------------------------------------------------------------------------
/*!\func 	rootService
 * \brief	Returns the service associated with the master IO port.
 */
//-----------------------------------------------------------------------------
io_service_t rootService()
{
	static io_service_t gRootService = 0 ;

	if (!gRootService)
	{
		// get registry root
		mach_port_t		masterPort ;
		IOReturn		err = IOMasterPort( MACH_PORT_NULL, & masterPort ) ;
		if ( err )
			[ NSException raise:@"" format:@"%s %u: couldn't get master port", __FILE__, __LINE__ ] ;

		gRootService 	= IORegistryGetRootEntry( masterPort );
	}

	return gRootService ;
}

NSString* listMethods(Class aClass)
{
	return listMethodWithOptions(aClass,YES); 
}

NSString* listMethodWithOptions(Class aClass,BOOL verbose)
{
	NSMutableString* resultString = [NSMutableString stringWithString:@""];
    struct objc_class *class = aClass;
	if(!aClass)return @"Class Not Found!\n";
    const char *name = class->name;
    int k;
    void *iterator = 0;
    struct objc_method_list *mlist;
    
	if(verbose){
		[resultString appendFormat: @"Deconstructing class %s, version %d\n",name, class->version];
		[resultString appendFormat: @"%s size: %d\n", name,class->instance_size];
		if (class->ivars == nil) [resultString appendFormat: @"%s has no instance variables\n", name];
		else {
			[resultString appendFormat: @"%s has %d ivar%c\n", name, class->ivars->ivar_count, ((class->ivars->ivar_count == 1)?' ':'s')];
			for (k = 0; k < class->ivars->ivar_count; k++){
				[resultString appendFormat: @"%s ivar #%d: %s\n", name, k, class->ivars->ivar_list[k].ivar_name];
			}
		}
	}
    mlist = class_nextMethodList(aClass, &iterator);
    if (mlist == nil && verbose) [resultString appendFormat: @"%s has no methods\n", name];
    else do {
        for (k = 0; k < mlist->method_count; k++){
			if(verbose) [resultString appendFormat: @"%s implements %@\n", name, NSStringFromSelector(mlist->method_list[k].method_name)];
			else [resultString appendFormat: @"%@\n", NSStringFromSelector(mlist->method_list[k].method_name)];
        }
    } while ( mlist = class_nextMethodList(aClass, &iterator) );
    
    if (class->super_class == nil && verbose) [resultString appendFormat: @"%s has no superclass\n", name];
    else {
        if(verbose)[resultString appendFormat: @"\n%s superclass: %s\n", name, class->super_class->name];
        [resultString appendString: listMethodWithOptions( class->super_class,verbose)];
    }
	return resultString;
}