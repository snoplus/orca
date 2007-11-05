//
//  ORcPCICrateView.m
//  Orca
//
//  Created by Mark Howe on Mon Feb 6, 2006
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


#import "ORcPCICrateView.h"
#import "ORcPCICard.h"


#define kNumcPCICrateSlots 8


@implementation ORcPCICrateView

- (int) maxNumberOfCards
{
    return kNumcPCICrateSlots;
}

- (int) cardWidth
{
    return 12;
}

- (NSPoint) suggestPasteLocationFor:(id)aCard
{
	if( [aCard isKindOfClass:NSClassFromString(@"ORcPCIControllerCard")]){
		if([self slotRangeEmpty:NSMakeRange(0,[aCard numberSlotsUsed])]){
            return [self constrainLocation:NSMakePoint(0,0)];
		}
		else return NSMakePoint(-1,-1);
	}
	else {
		NSPoint aPoint = [super suggestPasteLocationFor:aCard];
		if(aPoint.x != -1 && aPoint.y != -1){
			if([self slotAtPoint:aPoint] >= [self maxNumberOfCards]) return NSMakePoint(-1,-1);
		}
		return aPoint;
	}
}


- (BOOL) slotRangeEmpty:(NSRange)slotRange
{
    NSEnumerator* e = [[self group] objectEnumerator];
    id anObj;
    while(anObj = [e nextObject]){
        if(slotRange.location == [anObj slot])return NO;
        else {
            if(slotRange.length==2){
                if(slotRange.location+1 == [anObj slot])return NO;
            }
        }
        if([anObj numberSlotsUsed] == 2){
            if(slotRange.location-1 == [anObj slot])return NO;
        }
    }
    return YES;
}


- (BOOL) canAddObject:(id)obj atPoint:(NSPoint)aPoint
{
	if([super canAddObject:obj atPoint:aPoint]){
		int aSlot = [self slotAtPoint:aPoint];
		//last check.. cPCI restricts the last two slots for the controller
		if( [obj isKindOfClass:NSClassFromString(@"ORcPCIControllerCard")]){
			if(aSlot!=0){
				NSLog(@"Rejected attempt to place cPCI controller in non-controller slot\n");
				return NO;
			}
		}
		else {
			if(aSlot == 0) {
				NSLog(@"Rejected attempt to place cPCI card in controller slot.\n");
				return NO;
			}
		}
		return YES;
	}
	else return NO;
}

@end
