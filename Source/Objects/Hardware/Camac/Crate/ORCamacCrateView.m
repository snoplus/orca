//
//  ORCamacCrateView.m
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


#import "ORCamacCrateView.h"
#import "ORCamacCard.h"

@implementation ORCamacCrateView

- (int) maxNumberOfCards
{
    return 25;
}

- (int) cardWidth
{
    return 16;
}

- (NSPoint) suggestPasteLocationFor:(id)aCard
{
	NSRange legalControllerRange = NSMakeRange([self maxNumberOfCards]-2,2);
	if( [aCard isKindOfClass:NSClassFromString(@"ORCamacControllerCard")]){
		if([self slotRangeEmpty:legalControllerRange]){
            return [self constrainLocation:NSMakePoint(([self maxNumberOfCards]-2)*[self cardWidth],0)];
		}
		else return NSMakePoint(-1,-1);
	}
	else {
		NSPoint aPoint = [super suggestPasteLocationFor:aCard];
		if(aPoint.x != -1 && aPoint.y != -1){
			NSRange cardRange = NSMakeRange([self slotAtPoint:aPoint],[aCard numberSlotsUsed]);
			if(NSIntersectionRange(legalControllerRange,cardRange).length != 0) return NSMakePoint(-1,-1);
		}
		return aPoint;
	}
}


- (BOOL) slotRangeEmpty:(NSRange)slotRange
{	
    NSEnumerator* e = [[self group] objectEnumerator];
    id anObj;
    while(anObj = [e nextObject]){
		if(NSIntersectionRange(slotRange,NSMakeRange([anObj slot],[anObj numberSlotsUsed])).length != 0)return NO;
    }
    return YES;
}


- (BOOL) slot:(int) aSlot legalForCard:(id)aCard
{
	NSRange objRange			 = NSMakeRange(aSlot,[aCard numberSlotsUsed]);
	NSRange legalControllerRange = NSMakeRange([self maxNumberOfCards]-2,2);
	
	//last check.. Camac restricts the last two slots for the controller
	if([aCard isKindOfClass:NSClassFromString(@"ORCamacControllerCard")]){
		if(!NSEqualRanges(legalControllerRange,objRange))	return NO;
	}
	else if(NSIntersectionRange(legalControllerRange,objRange).length != 0) return NO;
	return YES;
}

- (BOOL) canAddObject:(id)obj atPoint:(NSPoint)aPoint
{
	if([super canAddObject:obj atPoint:aPoint]){
		int aSlot = [self slotAtPoint:aPoint];
		
		NSRange objRange			 = NSMakeRange(aSlot,[obj numberSlotsUsed]);
		NSRange legalControllerRange = NSMakeRange([self maxNumberOfCards]-2,2);
		
		//last check.. Camac restricts the last two slots for the controller
		if( [obj isKindOfClass:NSClassFromString(@"ORCamacControllerCard")]){
			if(!NSEqualRanges(legalControllerRange,objRange)){
				NSLog(@"Rejected attempt to place Camac controller in non-controller slot\n");
				return NO;
			}
		}
		else {
			if(NSIntersectionRange(legalControllerRange,objRange).length != 0) {
				NSLog(@"Rejected attempt to place Camac card in controller slot.\n");
				return NO;
			}
		}
		return YES;
	}
	else return NO;
}

@end
