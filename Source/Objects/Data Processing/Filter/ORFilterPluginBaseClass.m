//
//  ORFilterPluginBaseClass.m
//  Orca
//
//  Created by Mark Howe on 3/27/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ORFilterPluginBaseClass.h"

@implementation ORFilterPluginBaseClass

- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;	//never retain a delegate
	return self;
}

- (void) dealloc
{
	[symTable release];
	[super dealloc];
}

- (unsigned long*) ptr:(const char*)aKey
{
	filterData data;
	[symTable getData:&data forKey:aKey];
	return data.val.pValue;
}



- (unsigned long) value:(const char*)aKey
{
	filterData data;
	[symTable getData:&data forKey:aKey];
	return data.val.lValue;
}

- (void) setSymbolTable:(ORFilterSymbolTable*)aTable
{
	[aTable retain];
	[symTable release];
	symTable = aTable;
}

- (void) start
{
	//subclass will need to override
}
- (void) filter:(unsigned long*) currentRecordPtr length:(unsigned long)aLen
{
	//subclass will need to override
}

- (void) finish
{
	//subclass will need to override
}

@end
