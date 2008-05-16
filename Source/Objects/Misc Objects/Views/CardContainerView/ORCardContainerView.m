//
//  ORCardContainerView.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 27, 2002.
//  Copyright  © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORCardContainerView.h"
#import "ORCard.h"

@implementation ORCardContainerView

- (int) maxNumberOfCards
{
    return 10;      //default...subclasses can override
}

- (int) cardWidth
{
    return 10; //default...subclasses can override
}

- (BOOL) isHorizontalView
{
	return YES; //default. override if needed.
}

- (BOOL) validateLayoutItems:(NSMenuItem*)menuItem
{
	return NO;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{	
    return [self dropPositionOK:[sender draggedImageLocation]];
}

- (NSPoint) suggestPasteLocationFor:(id)aCard
{
    int slot;
    for(slot=[aCard tagBase];slot<=[self maxNumberOfCards];slot++){
        if([self slotRangeEmpty:NSMakeRange(slot-[aCard tagBase],[aCard numberSlotsUsed])]){
            NSPoint aPoint;
			if([self isHorizontalView]){
				aPoint.y = 0;
				aPoint.x = (slot-[aCard tagBase])*[self cardWidth];
			}
			else {
				aPoint.x = 0;
				aPoint.y = (slot-[aCard tagBase])*[self cardWidth];
			}
            return [self constrainLocation:aPoint];
        }
    }
    return NSMakePoint(-1,-1);
}
    
- (id) cardInSlot:(int)aSlot
{
    NSEnumerator* e = [[self group] objectEnumerator];
    ORCard* anObj;
    while(anObj = [e nextObject]){
		if(NSIntersectionRange(NSMakeRange([anObj slot],[anObj numberSlotsUsed]),NSMakeRange(aSlot,1)).length) return anObj;
	}
	return nil;
}
            
- (BOOL) slotRangeEmpty:(NSRange)slotRange
{
	if(slotRange.location < 0)return NO;
	if(slotRange.location > [self maxNumberOfCards])return NO;
	if(slotRange.location+slotRange.length > [self maxNumberOfCards])return NO;
	
    NSEnumerator* e = [[self group] objectEnumerator];
    id anObj;
    while(anObj = [e nextObject]){
        if(slotRange.location == [anObj slot])return NO;
        else {
            if(slotRange.length==2){
                if(slotRange.location+1 == [anObj slot])return NO;
            }
        }
    }
    return YES;
}


- (NSPoint) constrainLocation:(NSPoint)aPoint
{
	NSPoint validPoint;
	if([self isHorizontalView]){
		validPoint.y = 0;
		validPoint.x = [self cardWidth] * floor(((int)aPoint.x)/[self cardWidth]);
	}
	else {
		validPoint.x = 0;
		validPoint.y = [self cardWidth] * floor(((int)aPoint.y)/[self cardWidth]);
	}
    return validPoint;
}

- (void) drawBackground:(NSRect)aRect
{
	//don't want any background
}

- (int)slotAtPoint:(NSPoint)aPoint 
{
	if([self isHorizontalView]){
		return floor(((int)aPoint.x)/[self cardWidth]);
	}
	else {
		return floor(((int)aPoint.y)/[self cardWidth]);
	}
}

- (void) moveObject:(id)obj to:(NSPoint)aPoint
{
	int aSlot = [self slotAtPoint:aPoint];
	if(aSlot >=0 && aSlot < [self maxNumberOfCards]){
		if([self isHorizontalView]){
			[obj setSlot: aSlot];
		}
		else {
			[obj setSlot: aSlot];
		}
		[obj moveTo:aPoint];
	}
}

- (BOOL) canAddObject:(id)obj atPoint:(NSPoint)aPoint
{
	int aSlot = [self slotAtPoint:aPoint];

	if(aSlot > [self maxNumberOfCards]-1 || aSlot<0){
		NSBeep();
		NSLog(@"Rejected attempt to place card out of bounds\n");
		return NO;
	}
	else {
		NSEnumerator* e = [[self group] objectEnumerator];
		NSRange newCardSlotRange = NSMakeRange(aSlot, [obj numberSlotsUsed]);
		id anObj;
		while(anObj = [e nextObject]){
			NSRange existingCardSlotRange = NSMakeRange([anObj slot],[anObj numberSlotsUsed]);
			if(NSIntersectionRange(newCardSlotRange,existingCardSlotRange).length != 0){
				if(anObj != obj){
					NSBeep();
					NSLog(@"Rejected attempt to place multiple cards in slot %d\n",aSlot);
					return NO;
				}
			}
		}
	}
	return YES;
}

- (void) contentSizeChanged:(NSNotification*)note
{
}

- (void) moveSelectedObjects:(NSPoint)delta
{
	if(delta.y != 0) return;
	int deltaX = delta.x > 0  ? [self cardWidth] : -[self cardWidth];
	NSArray* sortedSelection = [[[self group] selectedObjects] sortedArrayUsingSelector:@selector(sortCompare:)];
	id obj;
	NSEnumerator* e;
	//First, can they -all- be moved?
	BOOL moveOK = YES;
	if(deltaX<0) e = [sortedSelection objectEnumerator];
	else		 e = [sortedSelection reverseObjectEnumerator];
	while(obj = [e nextObject]){
		int testSlot;
		int requiredEmptySlot;
		if(deltaX<0) {
			testSlot = [obj slot] - 1;
			requiredEmptySlot = testSlot;
		}
		else {
			testSlot = [obj slot] + 1;
			requiredEmptySlot = [obj slot] + [obj numberSlotsUsed];
		}
		if(requiredEmptySlot<0){
			moveOK = NO;
			break;
		}
		if(!([self slotRangeEmpty:NSMakeRange(requiredEmptySlot,1)] || [[self cardInSlot:requiredEmptySlot] highlighted])){
			moveOK = NO;
			break;
		}
		if(!([self slot:testSlot legalForCard:obj])){
			moveOK = NO;
			break;
		}
	}

	if(moveOK){		
		e = [sortedSelection objectEnumerator];
		while(obj = [e nextObject]){
			[self moveObject:obj to:NSMakePoint([obj frame].origin.x+deltaX,0)];
		}		
	}
}

- (BOOL) slot:(int) aSlot legalForCard:(id)aCard
{
	return YES; //default. subclasses can override
}

@end
