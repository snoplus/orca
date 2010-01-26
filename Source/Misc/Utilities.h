//--------------------------------------------------------------------------------
/*!\file	Utilities
 * \brief	This class contains useful functions 
 * \functions
 *			\li \b 	convertTimeLongToChar		- Convert standard UNIX time to standard 
 *												  time string.
 *			\li \b	convertTimeCharToLong		- Convert standard time string to UNIX
 *												  time.
 *			\li \b	ORKeyFromId					- convert an obj pointer value into an NSNumber.
 * \note	
 *			
 * \author	Jan M. Wouters
 * \history	2003-05-08 (jmw) - Original.
 */
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

#import <IOKit/IOKitLib.h>

long 	convertTimeCharToLong( char* aTime );
void	convertTimeLongToChar( time_t aTime, char *pTime );
id		ORKeyFromId(id anObj);
int		random_range(int lowest_number, int highest_number);
io_service_t rootService();
NSString* listMethods(Class aClass);
NSString* listMethodWithOptions(Class aClass,BOOL verbose,BOOL showSuperClass);
NSString* hexToString(unsigned long aHexValue);
const char* decodeType(const char* aType);