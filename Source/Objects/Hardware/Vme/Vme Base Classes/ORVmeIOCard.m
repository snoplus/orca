//
//  ORVmeIOCard.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORVmeIOCard.h"
#import "ORVmeBusProtocol.h"


#pragma mark ¥¥¥Notification Strings
NSString* ORVmeIOCardBaseAddressChangedNotification = @"Vme IO Card Base Address Changed";
NSString* ORVmeIOCardExceptionCountChanged 			= @"ORVmeIOCardExceptionCountChanged";



@implementation ORVmeIOCard


#pragma mark ¥¥¥Accessors
- (void) setAddressModifier:(unsigned short)anAddressModifier
{
    addressModifier = anAddressModifier;
}

- (unsigned short)  addressModifier
{
    return addressModifier;
}

- (void) setBaseAddress:(unsigned long) address
{
	[[[self undoManager] prepareWithInvocationTarget:self] setBaseAddress:[self baseAddress]];
    baseAddress = address;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORVmeIOCardBaseAddressChangedNotification
					   object:self]; 
    
}

- (unsigned long) baseAddress
{
    return baseAddress;
}

- (NSRange)	memoryFootprint
{
	//subclasses should overide to provide an accurate memory range
	return NSMakeRange(baseAddress,1*sizeof(long));
}

- (BOOL) memoryConflictsWith:(NSRange)aRange
{
	return NSIntersectionRange(aRange,[self memoryFootprint]).length != 0;
}

- (id)	adapter
{
	id anAdapter = [guardian adapter];
	if(anAdapter)return anAdapter;
	else [NSException raise:@"No adapter" format:@"You must place a VME adaptor card into the crate (i.e. a SBS Bit3)."];
	return nil;
}

- (unsigned long)   exceptionCount
{
    return exceptionCount;
}

- (void)clearExceptionCount
{
    exceptionCount = 0;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORVmeIOCardExceptionCountChanged
					   object:self]; 
    
}

- (void)incExceptionCount
{
    ++exceptionCount;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORVmeIOCardExceptionCountChanged
					   object:self]; 
}


#pragma mark ¥¥¥Archival
static NSString *ORVmeCardBaseAddress 		= @"Vme Base Address";
static NSString *ORVmeCardAddressModifier 	= @"vme Address Modifier";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
	[[self undoManager] disableUndoRegistration];
    
	[self setBaseAddress:[decoder decodeInt32ForKey:ORVmeCardBaseAddress]];
	[self setAddressModifier:[decoder decodeIntForKey:ORVmeCardAddressModifier]];
    
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInt32:[self baseAddress] forKey:ORVmeCardBaseAddress];
	[encoder encodeInt:[self addressModifier] forKey:ORVmeCardAddressModifier];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithLong:baseAddress] forKey:@"baseAddress"];
    return objDictionary;
}



@end
