//
//  OROrderedObjManager.m
//  Orca
//
//  Created by Mark Howe on 11/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
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
#import "OROrderedObjManager.h"
#import "ORCard.h"

@implementation OROrderedObjManager

+ (id) for:(id<OROrderedObjHolding>)aContainerObj
{
	return [[[OROrderedObjManager alloc] initForContainer:aContainerObj] autorelease];
}

- (id) initForContainer:(id<OROrderedObjHolding>)aContainerObj
{
	self = [super init];
	containerObj = aContainerObj;
	return self;
}

- (NSPoint) suggestLocationFor:(id)aCard
{	
    int slot;
	NSRange legalRange = [containerObj legalSlotsForCard:aCard];
    for(slot=0;slot<=[containerObj maxNumberOfCards];slot++){
		if([containerObj slot:slot excludedFor:aCard])continue;
		NSRange testRange = NSMakeRange(slot,[aCard numberSlotsUsed]);
        if([self slotRangeEmpty:testRange] && NSUnionRange(testRange, legalRange).length <= legalRange.length){
            return [containerObj pointForSlot:slot];
        }
    }
    return NSMakePoint(-1,-1);
}

- (BOOL) dropPositionOK:(NSPoint)aPoint
{
	int slot =  [containerObj slotAtPoint:aPoint];
	return [self slotRangeEmpty:NSMakeRange(slot,1)];
}

- (void) moveObject:(id)obj to:(NSPoint)aPoint
{
	int aSlot = [containerObj slotAtPoint:aPoint];
	if(aSlot >=0 && aSlot < [containerObj maxNumberOfCards]){
		[containerObj place:obj intoSlot:aSlot];
	}
}


- (id) cardInSlot:(int)aSlot
{
    NSEnumerator* e = [containerObj  objectEnumerator];
    id anObj;
    while(anObj = [e nextObject]){
		if(NSIntersectionRange(NSMakeRange([anObj slot],[anObj numberSlotsUsed]),NSMakeRange(aSlot,1)).length) return anObj;
	}
	return nil;
}

- (BOOL) slotRangeEmpty:(NSRange)slotRange
{
	if(slotRange.location < 0)return NO;
	if(slotRange.location > [containerObj maxNumberOfCards])return NO;
	if(slotRange.location+slotRange.length > [containerObj maxNumberOfCards])return NO;
	
    NSEnumerator* e = [containerObj objectEnumerator];
    id anObj;
    while(anObj = [e nextObject]){
		if(NSIntersectionRange(slotRange,NSMakeRange([anObj slot],[anObj numberSlotsUsed])).length != 0)return NO;
    }
    return YES;
}

- (BOOL) canAddObject:(id)obj atPoint:(NSPoint)aPoint
{
	int aSlot = [containerObj slotAtPoint:aPoint];	
	if(aSlot > [containerObj maxNumberOfCards]-1 || aSlot<0){
		NSBeep();
		NSLog(@"Rejected attempt to place card out of bounds\n");
		return NO;
	}
	else {
		if([containerObj slot:aSlot excludedFor:obj])return NO;
		NSRange testRange = NSMakeRange(aSlot,[obj numberSlotsUsed]);
		NSRange legalRange = [containerObj legalSlotsForCard:obj];
		if(NSIntersectionRange(legalRange,testRange).length!=[obj numberSlotsUsed]){
			NSLog(@"Slot %d is illegal for that card\n",[containerObj stationForSlot:aSlot]);
			return NO;
		}
        if(![self slotRangeEmpty:testRange]) {
			NSLog(@"Rejected attempt to place multiple cards in slot %d\n",[containerObj stationForSlot:aSlot]);
			return NO;
		}
	}
	return YES;
}

- (void) moveSelectedObjects:(NSPoint)delta
{
	int deltaSlot = ((delta.x > 0) || (delta.y >0))  ? 1 : -1;
	NSArray* sortedSelection = [[containerObj selectedObjects] sortedArrayUsingSelector:@selector(sortCompare:)];
	id obj;
	NSEnumerator* e;
	//First, can they -all- be moved?
	BOOL moveOK = YES;
	if(deltaSlot<0) e = [sortedSelection objectEnumerator];
	else			e = [sortedSelection reverseObjectEnumerator];
	while(obj = [e nextObject]){
		int testSlot;
		testSlot = [obj slot] + deltaSlot;
		if([containerObj slot:testSlot excludedFor:obj]){
			moveOK = NO;
			break;
		}
		if(!([self slotRangeEmpty:NSMakeRange(testSlot,1)] || [[self cardInSlot:testSlot] highlighted])){
			moveOK = NO;
			break;
		}
	}
	
	if(moveOK){		
		e = [sortedSelection objectEnumerator];
		while(obj = [e nextObject]){
			[containerObj place:obj intoSlot:[obj slot]+deltaSlot];
		}		
	}
}

@end
