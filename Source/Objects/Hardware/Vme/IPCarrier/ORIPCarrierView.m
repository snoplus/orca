//
//  ORIPCarrierView.m
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


#import "ORIPCarrierView.h"
#import "ORVmeCard.h"

@implementation ORIPCarrierView
- (int) maxNumberOfCards
{
    return 4;  
}

- (int) cardWidth
{
    return 58;
}

- (int)slotAtPoint:(NSPoint)aPoint 
{
	float x = aPoint.x;
	float w = [self bounds].size.width;
	int cardWidth = [self cardWidth];
	
	if(x>=0 && x<cardWidth)						return 0;
	else if(x>cardWidth && x<cardWidth*2)		return 1;
	else if(x>=w-cardWidth*2 && x<w-cardWidth)	return 2;
	else if(x>=w-cardWidth && x<w)				return 3;
	else										return -1;
}

- (BOOL) dropPositionOK:(NSPoint)aPoint
{
    short w = [self bounds].size.width;
	int cardWidth = [self cardWidth];
    short x = aPoint.x;
    if(x >= 0 &&  x < cardWidth*2)		   return YES;
    else if(x >= w - cardWidth*2-5 && x < w) return YES;
    else								   return NO;
}

- (NSPoint) constrainLocation:(NSPoint)aPoint
{
    NSPoint validPoint = aPoint; //default to nonsense
	validPoint.x = -10000;
    short w = [self bounds].size.width;
    short x = aPoint.x;
	int cardWidth = [self cardWidth];
    if(x<cardWidth)validPoint.x = 0;
    else if(x>cardWidth && x<cardWidth*2)validPoint.x = cardWidth+1;
    
    else if(x > w-cardWidth*2 && x<w - cardWidth)validPoint.x = w - cardWidth*2;
    else if(x >= w-cardWidth && x<=w)validPoint.x = 1 + w - cardWidth;
    validPoint.y = 0;
    return validPoint;
}

- (NSPoint) suggestPasteLocationFor:(id)aCard
{
    int slot;    
	for(slot=[aCard tagBase];slot<=[self maxNumberOfCards];slot++){
        if([self slotRangeEmpty:NSMakeRange(slot,[aCard numberSlotsUsed])]){
            NSPoint aPoint;
			aPoint.y = 0;
			switch(slot){
				case 0:  aPoint.x = 5; break;
				case 1:  aPoint.x = [self cardWidth]+5; break;
				case 2:  aPoint.x = [self bounds].size.width - 2*[self cardWidth]+5;  break;
				default: aPoint.x = [self bounds].size.width - [self cardWidth]+5;	break;
			}
            return [self constrainLocation:aPoint];
        }
    }
    return NSMakePoint(-1,-1);
}

- (void) moveSelectedObjects:(NSPoint)delta
{
	if(delta.y != 0) return;
	int slotInc = delta.x<0?-1:+1;
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
			float w = [self bounds].size.width;
			int cardWidth = [self cardWidth];
			float newX;
			switch(newSlot){
				case 0: newX = 5; break;
				case 1: newX = [self cardWidth]+5; break;
				case 2: newX = w - 2*cardWidth+5; break;
				default: newX = w - cardWidth+5; break;
			}
			[self moveObject:obj to:[self constrainLocation:NSMakePoint(newX,0)]];
		}		
	}
}


@end
