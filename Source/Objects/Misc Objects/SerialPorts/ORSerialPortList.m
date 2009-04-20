//
//  ORSerialPortList.m
//  ORCA
//
//  Created by Mark Howe on Mon Feb 10 2003.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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

//  Modified from ORSerialPortList.m by Andreas Mayer


#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORStandardEnumerator.h"

#include <termios.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#import "SynthesizeSingleton.h"

@interface ORSerialPortList (Private)
- (NSArray*) oldPortList;
- (void)     setOldPortList:(NSArray*) newOldPortList;
@end


@implementation ORSerialPortList

SYNTHESIZE_SINGLETON_FOR_ORCLASS(SerialPortList);

+ (NSEnumerator*) portEnumerator
{
	return [[[ORStandardEnumerator alloc] initWithCollection:[ORSerialPortList sharedSerialPortList] countSelector:@selector(count) objectAtIndexSelector:@selector(objectAtIndex:)] autorelease];
}


// ---------------------------------------------------------
// - oldPortList:
// ---------------------------------------------------------
- (NSArray*) oldPortList
{
    return oldPortList;
}

// ---------------------------------------------------------
// - setOldPortList:
// ---------------------------------------------------------
- (void)setOldPortList:(NSArray*) newOldPortList
{
    id old = nil;

    if (newOldPortList != oldPortList) {
        old = oldPortList;
        oldPortList = [newOldPortList retain];
        [old release];
    }
}

- (ORSerialPort*) oldPortByPath:(NSString*) bsdPath
{
	ORSerialPort *result = nil;
	ORSerialPort *object;
	NSEnumerator *enumerator;

	enumerator = [oldPortList objectEnumerator];
	while (object = [enumerator nextObject]) {
		if ([[object bsdPath] isEqualToString:bsdPath]) {
			result = object;
			break;
		}
	}
	return result;
}

-(kern_return_t)findSerialPorts:(io_iterator_t*) matchingServices
{
    kern_return_t		kernResult; 
    mach_port_t			masterPort;
    CFMutableDictionaryRef	classesToMatch;

    kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult){
        //printf("IOMasterPort returned %d\n", kernResult);
    }
        
    // Serial devices are instances of class IOSerialBSDClient
    classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    if (classesToMatch == NULL){
        //printf("IOServiceMatching returned a NULL dictionary.\n");
    }
    else
        CFDictionarySetValue(classesToMatch,
                            CFSTR(kIOSerialBSDTypeKey),
                            CFSTR(kIOSerialBSDAllTypes));
    
    kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, matchingServices);    
    if (KERN_SUCCESS != kernResult){
        //printf("IOServiceGetMatchingServices returned %d\n", kernResult);
    }
        
    return kernResult;
}


-(ORSerialPort*) getNextSerialPort:(io_iterator_t)serialPortIterator
{
    io_object_t		serialService;
    ORSerialPort	*result = nil;
    
    if ((serialService = IOIteratorNext(serialPortIterator))){
        CFTypeRef	modemNameAsCFString;
        CFTypeRef	bsdPathAsCFString;

        modemNameAsCFString = IORegistryEntryCreateCFProperty(serialService,
                                                              CFSTR(kIOTTYDeviceKey),
                                                              kCFAllocatorDefault,
                                                              0);
        bsdPathAsCFString = IORegistryEntryCreateCFProperty(serialService,
                                                            CFSTR(kIOCalloutDeviceKey),
                                                            kCFAllocatorDefault,
                                                            0);
        if (modemNameAsCFString && bsdPathAsCFString) {
			result = [self oldPortByPath:(NSString*) bsdPathAsCFString];
			if (result == nil)
				result = [[ORSerialPort alloc] init:(NSString*) bsdPathAsCFString withName:(NSString*) modemNameAsCFString];
		}

        if (modemNameAsCFString)CFRelease(modemNameAsCFString);

        if (bsdPathAsCFString)CFRelease(bsdPathAsCFString);
    
        (void) IOObjectRelease(serialService);
        // We have sucked this service dry of information so release it now.
        return result;
    }
    else
        return NULL;
}


-(id)init
{
    kern_return_t	kernResult; // on PowerPC this is an int (4 bytes)
    /*
     *	error number layout as follows (see mach/error.h):
     *
     *	hi		 		       lo
     *	| system(6) | subsystem(12) | code(14) |
     */
    io_iterator_t	serialPortIterator;
    ORSerialPort	*serialPort;

	if (portList != nil) {
		[self setOldPortList:[NSArray arrayWithArray:portList]];
		[portList removeAllObjects];
	} 
    else {
		[super init];
		portList = [[NSMutableArray array] retain];
	}
		kernResult = [self findSerialPorts:&serialPortIterator];
		do { 
			serialPort = [self getNextSerialPort:serialPortIterator];
			if (serialPort != NULL) {
				//if(	[[serialPort name] rangeOfString:@"Bluetooth"].location == NSNotFound){
					[portList addObject:serialPort];
				//}
			}
		}
		while (serialPort != NULL);
		IOObjectRelease(serialPortIterator);	// Release the iterator.

    return self;
}

-(NSArray*) getPortList;
{
    return [[portList copy] autorelease];
}

-(unsigned)count
{
    return [portList count];
}

-(ORSerialPort*) objectAtIndex:(unsigned)index
{
    return [portList objectAtIndex:index];
}

-(ORSerialPort*) objectWithName:(NSString*) name
{
	ORSerialPort *result = NULL;
	int i;

	for (i=0; i<[portList count]; i++){
        if ([[(ORSerialPort*) [portList objectAtIndex:i] name] isEqualToString:name]){
			result = (ORSerialPort*) [portList objectAtIndex:i];
			break;
		}
    }
	return result;
}


@end
