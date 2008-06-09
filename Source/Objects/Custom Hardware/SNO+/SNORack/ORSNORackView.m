//
//  ORSNORackView.m
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
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


#import "ORSNORackView.h"
#import "ORSNOCrateModel.h"

@implementation ORSNORackView

- (int) maxNumberOfCards
{
    return 2;
}

- (BOOL) isHorizontalView
{
	return NO; //default. override if needed.
}

- (int) cardWidth
{
    return 56;
}
- (NSPoint) suggestPasteLocationFor:(id)aCard
{
    int slot;    
	for(slot=0;slot<=[self maxNumberOfCards];slot++){
        if([self slotRangeEmpty:NSMakeRange(slot,1)]){
            NSPoint aPoint;
			aPoint.y = 0;
			switch(slot){
				case 0:  aPoint.y = 5; break;
				case 1:  aPoint.y = [self bounds].size.height - [self cardWidth]+1;  break;
			}
            return [self constrainLocation:aPoint];
        }
    }
    return NSMakePoint(-1,-1);
}

- (int) slotAtPoint:(NSPoint)aPoint 
{
	if(aPoint.y>=0 && aPoint.y<[self cardWidth]) return 0;
	else if(aPoint.y > [self cardWidth]) return 1;
	else return -1;
}

- (NSPoint) constrainLocation:(NSPoint)aPoint
{
    NSPoint validPoint = aPoint; //default to nonsense
	validPoint.y = -10000;
    short h = [self bounds].size.height;
    short y = aPoint.y;
	int cardWidth = [self cardWidth];
    if(y<cardWidth)		  validPoint.y = 3;
    else if(y>=cardWidth) validPoint.y = h-cardWidth+1;
    validPoint.x = 0;
    return validPoint;
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
		int requiredEmptySlot;
		if(deltaY<0) {
			testSlot = [obj slot] - 1;
			requiredEmptySlot = testSlot;
		}
		else {
			testSlot = [obj slot] + 1;
			requiredEmptySlot = [obj slot] + 1;
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
			NSPoint p = [self constrainLocation:NSMakePoint(0,[obj frame].origin.y+deltaY)];
			[self moveObject:obj to:p];
		}		
	}
}




- (void) drawContents:(NSRect)aRect
{
    [group drawIcons:aRect];	
}

@end
