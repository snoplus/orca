//
//  ORMacView.m
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


#import "ORMacView.h"
#import "ORPciCard.h"

#define kNumPCISlots 4

@implementation ORMacView

- (int) maxNumberOfCards
{
    return 4;      //default...subclasses can override
}

- (int) cardWidth
{
    return 20; //default...subclasses can override
}

- (BOOL) isHorizontalView
{
	return NO; //default. override if needed.
}

- (void) drawRect:(NSRect)aRect
{
	short i;
	NSBezierPath* line = [NSBezierPath bezierPath];
	int cardWidth = [self cardWidth];
	for(i=cardWidth;i<[self frame].size.width;i+=cardWidth){
		[line moveToPoint:NSMakePoint(0,i)];
		[line lineToPoint:NSMakePoint([self frame].size.width,i)];
	}
	[[NSColor blackColor] set];
	[line stroke];
	NSFrameRect([self bounds]);
	[super drawContents:aRect];
    [mouseTask drawRect:aRect];
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
		if(deltaY<0) testSlot = [obj slot] - 1;
		else testSlot = [obj slot] + 1;
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
