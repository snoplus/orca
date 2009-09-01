//
//  ORVmeAdapter.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 25 2009.
//  Copyright © 2009 University of North Carolina. All rights reserved.
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

#pragma mark •••Imported Files

#import "ORVmeTests.h"
#import "ORVmeIOCard.h"
#import "ORVmeCrate.h"

#define kReadWrite 0
#define kReadOnly  1
#define kWriteOnly 2

@implementation ORVmeReadWriteTest
+ (id) test:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize validMask:(unsigned long)aValidMask name:(NSString*)aName
{
	return [[[ORVmeReadWriteTest alloc] initWith:anOffset length:aLength wordSize:aWordSize validMask:aValidMask name:aName] autorelease];
}

- (id) initWith:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize validMask:(unsigned long)aValidMask name:(NSString*)aName
{
	self = [super initWithName:aName];
	type = kReadWrite;
	theOffset	= anOffset;
	length		= aLength;
	validMask	= aValidMask;
	wordSize = aWordSize;
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) runTest:(id)anObj
{
	unsigned long patterns[4]={
		0x55555555,
		0xAAAAAAAA,
		0x00000000,
		0xFFFFFFFF
	};
	@try {
		int i;
		unsigned long  theAddress  = [anObj baseAddress] + theOffset;
		unsigned short theModifier = [anObj addressModifier];
		id theController = [anObj adapter];
		
		for(i=0;i<4;i++){
			unsigned long theWriteValue = patterns[i] & validMask;
			unsigned long theReadValue = 0;
			if(wordSize == sizeof(long)){
				if(type == kReadWrite || type == kWriteOnly) [theController writeLongBlock:&theWriteValue atAddress:theAddress numToWrite:1 withAddMod:theModifier usingAddSpace:0x01];
				if(type == kReadWrite || type == kReadOnly)  [theController readLongBlock: &theReadValue  atAddress:theAddress numToRead:1  withAddMod:theModifier usingAddSpace:0x01];
			}
			else if(wordSize == sizeof(short)){
				unsigned short shortWriteValue = (unsigned short)theWriteValue;
				unsigned short shortReadValue = 0;
				if(type == kReadWrite || type == kWriteOnly)[theController writeWordBlock:&shortWriteValue atAddress:theAddress numToWrite:1 withAddMod:theModifier usingAddSpace:0x01];
				if(type == kReadWrite || type == kReadOnly)[theController readWordBlock: &shortReadValue  atAddress:theAddress numToRead:1  withAddMod:theModifier usingAddSpace:0x01];
				theReadValue = shortReadValue;
			}
			else if(wordSize == sizeof(char)){
				unsigned char charWriteValue = (unsigned char)theWriteValue;
				unsigned char charReadValue = 0;
				if(type == kReadWrite || type == kWriteOnly)[theController writeByteBlock:&charWriteValue atAddress:theAddress numToWrite:1 withAddMod:theModifier usingAddSpace:0x01];
				if(type == kReadWrite || type == kReadOnly)[theController readByteBlock: &charReadValue  atAddress:theAddress numToRead:1  withAddMod:theModifier usingAddSpace:0x01];
				theReadValue = charReadValue;
			}			
			if(type == kReadWrite) {				
				theReadValue &=  validMask;
			
				if(theWriteValue != theReadValue) {
					[self addFailureLog:[NSString stringWithFormat:@"R/W Error: 0x%08x: 0x%0x != 0x%0x\n",[anObj baseAddress] + theOffset,theWriteValue,theReadValue]];
				}
			}
		}
	}
	@catch(NSException* e){
		[self addFailureLog:[NSString stringWithFormat:@"Exception: 0x%08x\n",[anObj baseAddress] + theOffset]];
	}
}
@end

@implementation ORVmeReadOnlyTest
+ (id) test:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize name:(NSString*)aName
{
	return [[[ORVmeReadOnlyTest alloc] initWith:anOffset length:aLength wordSize:aWordSize name:aName] autorelease];
}
- (id) initWith:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize name:(NSString*)aName
{
	self = [super initWith:anOffset length:aLength wordSize:aWordSize validMask:0xFFFFFFFF name:aName];
	type = kReadOnly;
	return self;
}

@end

@implementation ORVmeWriteOnlyTest
- (id) initWith:(unsigned long) anOffset length:(unsigned long)aLength wordSize:(short)aWordSize validMask:(unsigned long)aValidMask name:(NSString*)aName
{
	self = [super initWith:anOffset length:aLength wordSize:aWordSize validMask:aValidMask name:aName];
	type = kWriteOnly;
	return self;
}
@end
