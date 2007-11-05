//
//  ORPciBit3View.m
//  Orca
//
//  Created by Mark Howe on Mon Dec 09 2002.
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


#import "ORPciBit3View.h"
#import "ORDualPortLAMModel.h"

@implementation ORPciBit3View

- (int) maxNumberOfCards
{
    return 10;
}

- (int) cardWidth
{
    return 16;
}

- (BOOL) isHorizontalView
{
	return NO; 
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
	[[NSColor blackColor]set];
	[NSBezierPath strokeRect:[self bounds]];

    float x1 = [self bounds].origin.x;
    float x2 = x1+[self bounds].size.width;
    float y = [self bounds].origin.y;
    for(;y<[self bounds].size.height;y+=[self cardWidth]){
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y) toPoint:NSMakePoint(x2,y)];
    }
}

- (int)slotAtPoint:(NSPoint)aPoint
{
    return [self maxNumberOfCards] - 1 - floor(((int)aPoint.y)/[self cardWidth]);
}

- (NSPoint) suggestPasteLocationFor:(id)aCard
{
    int slot;
    for(slot=[aCard tagBase];slot<=[self maxNumberOfCards];slot++){
        if([self slotRangeEmpty:NSMakeRange(slot,[aCard numberSlotsUsed])]){
            NSPoint aPoint;
			aPoint.x = 0;
			aPoint.y = ([self maxNumberOfCards] - slot - 1)*[self cardWidth];
            return [self constrainLocation:aPoint];
        }
    }
    return NSMakePoint(-1,-1);
}


- (BOOL) mouseDownCanMoveWindow
{
    return NO;
}

- (void) moveSelectedObjects:(NSPoint)delta
{
	if(delta.x != 0) return;
	int deltaY = delta.y > 0  ? [self cardWidth] : -[self cardWidth];
	NSArray* sortedSelection = [[[self group] selectedObjects] sortedArrayUsingSelector:@selector(sortCompare:)];
	id obj;
	NSEnumerator* e;
	//First, can they -all- be moved?
	BOOL moveOK = YES;
	if(deltaY<0) e = [sortedSelection objectEnumerator];
	else		 e = [sortedSelection reverseObjectEnumerator];
	while(obj = [e nextObject]){
		int testSlot;
		if(deltaY<0) testSlot = [obj slot] + 1;
		else testSlot = [obj slot] - 1;
		if(!([self slotRangeEmpty:NSMakeRange(testSlot,1)] || [[self cardInSlot:testSlot] highlighted])){
			moveOK = NO;
			break;
		}
	}

	if(moveOK){		
		e = [sortedSelection objectEnumerator];
		while(obj = [e nextObject]){
			[self moveObject:obj to:NSMakePoint(0,[obj frame].origin.y+deltaY)];
		}		
	}
}

@end
