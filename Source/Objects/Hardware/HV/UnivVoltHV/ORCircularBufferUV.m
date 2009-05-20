//
//  ORCircularBufferUV.m
//  Orca
//
//  Created by Jan Wouters on 4/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ORCircularBufferUV.h"


@implementation ORCircularBufferUV
- (id) init
{
    mTailIndex = 0;
	mHeadIndex = 0;
	mFWrapped = NO;
	mKeys = [NSArray arrayWithObjects: @"Time", @"HVValue", nil];
	[mKeys retain];
	
	// what is going on.
	NSDate* timeObj = [mKeys objectAtIndex: 0];
	NSString* hvStr = [mKeys objectAtIndex: 1];
	NSLog( @"Time key: %@\n", timeObj );
	NSLog( @"Value key: %@\n", hvStr );
	[mKeys retain];
	
    return self;
}

- ( void ) dealloc
{
	[mStorageArray dealloc];
	[super dealloc];
}

- ( void ) setSize: (long) aSizeCB
{
	mSize = aSizeCB;
	mStorageArray = [NSMutableArray arrayWithCapacity: mSize];
//	NSNumber* numObj = [NSNumber numberWithFloat: 0.0];
//	[mStorageArray insertObject: numObj atIndex: 0];
	NSLog( @"Size of array: %d\n", [mStorageArray count] );
}

- ( long ) size
{
	return( [mStorageArray count] );
}

- ( NSArray *) mKeys
{
	return( mKeys );
}

- (void) insertHVEntry: (NSDate *) aDateOfAquistion hvValue: (NSNumber*) anHVEntry
{
	int i;
	@try
	{
		NSLog( @"Date: %@, HV Value: %f\n", aDateOfAquistion, anHVEntry );
		NSArray* tmpTimePoint = [NSArray arrayWithObjects: aDateOfAquistion, anHVEntry, nil];
		NSDictionary* dictObj = [NSDictionary dictionaryWithObjects: tmpTimePoint forKeys: mKeys];
	
	 
		if ( mFWrapped == YES )
		{
			[mStorageArray removeObjectAtIndex: mTailIndex];
		}
		[mStorageArray insertObject: dictObj atIndex: mTailIndex];
/*	}
	else
	{
		[mStorageArray addObject: dictObj];
		NSDictionary* checkObj = [mStorageArray objectAtIndex: mTailIndex];
	}
*/
//	NSLog( @"insert: %f at index: %d, size: %d\n", anHVEntry, mTailIndex, [mStorageArray count] );
//	NSLog( @"Entry after insertion ( %d ): %f\n", mTailIndex, [[mStorageArray objectAtIndex: mTailIndex] floatValue] );
		mTailIndex += 1;
		if ( mTailIndex >= mSize ) {
			mTailIndex = 0;
			mFWrapped = YES;
		}
	
		for( i = 0; i < 5; i++ )
		{
			NSDictionary* timeDataPoint = [mStorageArray objectAtIndex: i];
			NSLog( @"Entry ( %d ) - Time %@ value: %f\n", i, [timeDataPoint objectForKey: [mKeys objectAtIndex: 0]], 
				[[timeDataPoint objectForKey: [mKeys objectAtIndex: 1]] floatValue] );
		}
		NSLog( @"-----Count: %d\n\n\n", [mStorageArray count] );
	}
	@catch( NSException* e )
	{
		NSLog( @"Caught expception '@'.", [e reason] );
	}
}

- (NSDictionary *) HVEntry: (long) anOffsetFromMostRecent
{
	long index = mTailIndex - 1 + anOffsetFromMostRecent; // -1 present because mTailIndex points to next position where new entry will be placed.
	if ( index < 0 ) index += [mStorageArray count];
	if ( index >= [mStorageArray count] ) index -= [mStorageArray count];
	
	NSDictionary* dictObj = [[mStorageArray objectAtIndex: index] autorelease];
	return( dictObj );
}


- (NSDictionary *) HVEntry
{
	NSDictionary* dictObj = [[mStorageArray objectAtIndex: mHeadIndex] autorelease];
	NSNumber* numObj = [dictObj objectForKey: [mKeys objectAtIndex: 1]];
	NSDate* dateObj = [dictObj	objectForKey: [mKeys objectAtIndex: 0]];
	float tmpFloat = [numObj floatValue];
	NSLog( @"returned for date: %@, Value: %f, for index %d\n", dateObj, tmpFloat, mHeadIndex );
	
	// Set up index for next call to this routine.
	mHeadIndex += 1;
	if ( mHeadIndex >= mSize ) {
		mHeadIndex = 0;		
	}
	return( dictObj );
}
@end
