//
//  ORSNOCrateView.m
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


#import "ORSNOCrateView.h"
#import "ORCard.h"

#define kNumSNOCrateSlots 18

@implementation ORSNOCrateView

- (int) maxNumberOfCards
{
    return kNumSNOCrateSlots;
}

- (int) cardWidth
{
    return 12;
}

//unfortunately, we have to duplicate a number of methods for a SNO crate because the slots count from right to left.

- (NSPoint) suggestPasteLocationForSNO:(id)aCard
{
    int slot;
    for(slot=1;slot<kNumSNOCrateSlots;slot++){
        if([self slotRangeEmpty:NSMakeRange(slot,[aCard numberSlotsUsed])]){
            NSPoint aPoint;
			aPoint.y = 0;
			aPoint.x = slot*[self cardWidth];
            return [self constrainLocation:aPoint];
        }
    }
    return NSMakePoint(-1,-1);
}

- (NSPoint) suggestPasteLocationFor:(id)aCard
{
	NSRange legalXL2Range = NSMakeRange(kNumSNOCrateSlots-1,1);
	NSRange legalCTCRange = NSMakeRange(0,1);
	if( [aCard isKindOfClass:NSClassFromString(@"ORXL2Model")]){
		if([self slotRangeEmpty:legalXL2Range]){
            return [self constrainLocation:NSMakePoint((kNumSNOCrateSlots-1)*[self cardWidth],0)];
		}
		else return NSMakePoint(-1,-1);
	}
	else if( [aCard isKindOfClass:NSClassFromString(@"ORCTCModel")]){
		if([self slotRangeEmpty:legalCTCRange]){
            return [self constrainLocation:NSMakePoint((kNumSNOCrateSlots-1)*[self cardWidth],0)];
		}
		else return NSMakePoint(-1,-1);
	}
	else {
		NSPoint aPoint = [self suggestPasteLocationForSNO:aCard];
		if(aPoint.x != -1 && aPoint.y != -1){
			NSRange cardRange = NSMakeRange([self slotAtPoint:aPoint],[aCard numberSlotsUsed]);
			if(	NSIntersectionRange(legalXL2Range,cardRange).length != 0 ||
				NSIntersectionRange(legalCTCRange,cardRange).length != 0 ) {
					return NSMakePoint(-1,-1);
			}
		}
		return aPoint;
	}
}

- (BOOL) slot:(int) aSlot legalForCard:(id)aCard
{
	NSRange objRange	  = NSMakeRange(aSlot,[aCard numberSlotsUsed]);
	NSRange legalXL2Range = NSMakeRange(kNumSNOCrateSlots-1,1);
	NSRange legalCTCRange = NSMakeRange(0,1);
	
	//last check.. SNO restricts the last slot for the XL2 and first slot for Trigger card
	if([aCard isKindOfClass:NSClassFromString(@"ORXL2Model")]){
		if(!NSEqualRanges(legalXL2Range,objRange))	return NO;
	}
	else if([aCard isKindOfClass:NSClassFromString(@"ORCTCModel")]){
		if(!NSEqualRanges(legalCTCRange,objRange))	return NO;
	}
	else if( NSIntersectionRange(legalXL2Range,objRange).length != 0 || 
			 NSIntersectionRange(legalCTCRange,objRange).length != 0) {
				return NO;
	}
	return YES;
}

- (BOOL) canAddObject:(id)obj atPoint:(NSPoint)aPoint
{
	int aSlot = [self slotAtPoint:aPoint];

	if(aSlot > kNumSNOCrateSlots-1 || aSlot<0){
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
					NSLog(@"Rejected attempt to place multiple cards in slot %d\n",kNumSNOCrateSlots-1-aSlot);
					return NO;
				}
			}
		}
	}
	if([super canAddObject:obj atPoint:aPoint]){
		int aSlot = [self slotAtPoint:aPoint];
		
		NSRange objRange			 = NSMakeRange(aSlot,[obj numberSlotsUsed]);
		NSRange legalXL2Range = NSMakeRange(kNumSNOCrateSlots-1,1);
		NSRange legalCTCRange = NSMakeRange(0,1);
		
	//last check.. SNO restricts the last slot for the XL2 and first slot for Trigger card
		if( [obj isKindOfClass:NSClassFromString(@"ORXL2Model")]){
			if(!NSEqualRanges(legalXL2Range,objRange)){
				NSLog(@"Rejected attempt to place XL2 in wrong slot\n");
				return NO;
			}
		}
		else if( [obj isKindOfClass:NSClassFromString(@"ORCTCModel")]){
			if(!NSEqualRanges(legalCTCRange,objRange)){
				NSLog(@"Rejected attempt to place CTC in wrong slot\n");
				return NO;
			}
		}
		else if( NSIntersectionRange(legalXL2Range,objRange).length != 0 || 
			 NSIntersectionRange(legalCTCRange,objRange).length != 0) {				
				NSLog(@"Rejected attempt to card in illegal slot\n");
				return NO;
		}
		return YES;
	}
	return NO;
}

@end

