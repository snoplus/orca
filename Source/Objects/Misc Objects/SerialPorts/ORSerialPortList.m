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

@implementation ORSerialPortList

SYNTHESIZE_SINGLETON_FOR_ORCLASS(SerialPortList);

+ (NSEnumerator*) portEnumerator
{
	return [[[ORStandardEnumerator alloc] initWithCollection:[ORSerialPortList sharedSerialPortList] countSelector:@selector(count) objectAtIndexSelector:@selector(objectAtIndex:)] autorelease];
}

-(kern_return_t)findSerialPorts:(io_iterator_t*) matchingServices
{
    mach_port_t			masterPort;

    kern_return_t kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult){
        //printf("IOMasterPort returned %d\n", kernResult);
    }
        
    // Serial devices are instances of class IOSerialBSDClient
    CFMutableDictionaryRef classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
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
    ORSerialPort*   aSerialPort = nil;
    
    if ((serialService = IOIteratorNext(serialPortIterator))){
		
        CFTypeRef modemNameAsCFString = IORegistryEntryCreateCFProperty(serialService,
                                                              CFSTR(kIOTTYDeviceKey),
                                                              kCFAllocatorDefault,
                                                              0);
        CFTypeRef bsdPathAsCFString = IORegistryEntryCreateCFProperty(serialService,
                                                            CFSTR(kIOCalloutDeviceKey),
                                                            kCFAllocatorDefault,
                                                            0);
        if (modemNameAsCFString && bsdPathAsCFString) {
			aSerialPort = [[[ORSerialPort alloc] init:(NSString*) bsdPathAsCFString withName:(NSString*) modemNameAsCFString] autorelease];
		}

        if (modemNameAsCFString)CFRelease(modemNameAsCFString);

        if (bsdPathAsCFString)CFRelease(bsdPathAsCFString);
    
        (void) IOObjectRelease(serialService);
        // We have sucked this service dry of information so release it now.
        return aSerialPort;
    }
    else return NULL;
}


-(id)init
{
    /*
     *	error number layout as follows (see mach/error.h):
     *
     *	hi		 		       lo
     *	| system(6) | subsystem(12) | code(14) |
     */
	self = [super init];
	
	portList = [[NSMutableArray array] retain];

    io_iterator_t	serialPortIterator;
	[self findSerialPorts:&serialPortIterator];
	ORSerialPort* serialPort;
	do { 
		serialPort = [self getNextSerialPort:serialPortIterator];
		if (serialPort != NULL) {
			if(	[[serialPort name] rangeOfString:@"Bluetooth"].location == NSNotFound &&
				[[serialPort name] rangeOfString:@"KeySerial"].location == NSNotFound ){
				[portList addObject:serialPort];
			}
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

#pragma mark ¥¥¥Port Aliases
- (NSString*) aliaseForPort:(ORSerialPort*)aPort
{
	return [self aliaseForPortName:[aPort name]];
}

- (NSString*) aliaseForPortName:(NSString*)aPortName
{
	if(!aliaseDictionary)return aPortName;
	NSString* theAliase = [aliaseDictionary objectForKey:aPortName];
	if(!theAliase)return aPortName;
	else return theAliase;
}

- (void) assignAliase:(NSString*)anAliase forPort:(ORSerialPort*)aPort
{
	if(!aliaseDictionary)aliaseDictionary = [[NSMutableDictionary dictionary] retain];
	NSString* thePortName = [aPort name];
	[aliaseDictionary setObject:anAliase forKey:thePortName];
}

@end
