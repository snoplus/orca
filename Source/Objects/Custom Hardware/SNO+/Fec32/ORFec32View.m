//
//  ORFec32View.m
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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


#import "ORFec32View.h"
#import "ORSNOCard.h"

@implementation ORFec32View
- (int) maxNumberOfCards
{
    return 4;  
}

- (int) cardWidth
{
    return 39;
}

- (int)slotAtPoint:(NSPoint)aPoint 
{
	float y = aPoint.y;
	float h = [self frame].size.height;
	int cardWidth = [self cardWidth];
	
	if(y>=0 && y<cardWidth)						return 0;
	else if(y>cardWidth && y<cardWidth*2)		return 1;
	else if(y>=h-cardWidth*2 && y<h-cardWidth)	return 2;
	else if(y>=h-cardWidth && y<h)				return 3;
	else										return -1;
}

- (BOOL) dropPositionOK:(NSPoint)aPoint
{
	aPoint = [self convertPoint:aPoint fromView:nil];

    short h = [self frame].size.height;
	int cardWidth = [self cardWidth];
    short y = aPoint.y;
	BOOL dropStatus = NO;
    if((y >= 0) &&  (y < cardWidth*2))				dropStatus = YES;
    else if((y >= (h - cardWidth*2)) && (y < h))	dropStatus = YES;
	return dropStatus;
}

- (NSPoint) constrainLocation:(NSPoint)aPoint
{
    NSPoint validPoint = aPoint; //default to nonsense
	validPoint.y = -10000;
    short h = [self frame].size.height;
    short y = aPoint.y;
	int cardWidth = [self cardWidth];
    if(y<cardWidth)validPoint.y = 0;
    else if(y>cardWidth && y<cardWidth*2)validPoint.y = cardWidth+1;
    
    else if(y > h-cardWidth*2 && y<h - cardWidth)validPoint.y = h - cardWidth*2;
    else if(y >= h-cardWidth && y<=h)validPoint.y = 1 + h - cardWidth;
    validPoint.x = 0;
    return validPoint;
}

- (NSPoint) suggestPasteLocationFor:(id)aCard
{
    int slot;    
	for(slot=[aCard tagBase];slot<=[self maxNumberOfCards];slot++){
        if([self slotRangeEmpty:NSMakeRange(slot,[aCard numberSlotsUsed])]){
            NSPoint aPoint;
			aPoint.x = 0;
			switch(slot){
				case 0:  aPoint.y = 5; break;
				case 1:  aPoint.y = [self cardWidth]+5; break;
				case 2:  aPoint.y = [self frame].size.height - 2*[self cardWidth]+5;  break;
				default: aPoint.y = [self frame].size.height - [self cardWidth]+5;	break;
			}
            return [self constrainLocation:aPoint];
        }
    }
    return NSMakePoint(-1,-1);
}

- (void) moveSelectedObjects:(NSPoint)delta
{
	if(delta.x != 0) return;
	int slotInc = delta.y<0?-1:+1;
	NSArray* sortedSelection = [[[self group] selectedObjects] sortedArrayUsingSelector:@selector(sortCompare:)];
	id obj;
	NSEnumerator* e;
	//First, can they -all- be moved?
	BOOL moveOK = YES;
	if(slotInc<0) e = [sortedSelection objectEnumerator];
	else		  e = [sortedSelection reverseObjectEnumerator];
	while(obj = [e nextObject]){
		int testSlot = [obj slot] + slotInc;
		if(testSlot<0){
			moveOK = NO;
			break;
		}
		if(!([self slotRangeEmpty:NSMakeRange(testSlot,1)] || [[self cardInSlot:testSlot] highlighted])){
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
			int newSlot = [obj slot] + slotInc;
			float h = [self frame].size.height;
			int cardWidth = [self cardWidth];
			float newY;
			switch(newSlot){
				case 0: newY = 5; break;
				case 1: newY = [self cardWidth]+5; break;
				case 2: newY = h - 2*cardWidth+5; break;
				default: newY = h - cardWidth+5; break;
			}
			[self moveObject:obj to:[self constrainLocation:NSMakePoint(0,newY)]];
		}		
	}
}


@end
