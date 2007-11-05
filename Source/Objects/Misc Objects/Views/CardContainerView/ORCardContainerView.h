//
//  ORCardContainerView.h
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


@interface ORCardContainerView : ORGroupView {
}

- (int) maxNumberOfCards;
- (int) cardWidth;
- (BOOL) isHorizontalView;
- (id) cardInSlot:(int)aSlot;

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (NSPoint) suggestPasteLocationFor:(id)anObject;
- (BOOL) slotRangeEmpty:(NSRange)slotRange;
- (NSPoint) constrainLocation:(NSPoint)aPoint;
- (void) drawBackground:(NSRect)aRect;
- (int) slotAtPoint:(NSPoint)aPoint;
- (void) moveObject:(id)obj to:(NSPoint)aPoint;
- (BOOL) canAddObject:(id)obj atPoint:(NSPoint)aPoint;
- (void) contentSizeChanged:(NSNotification*)note;
- (void) moveSelectedObjects:(NSPoint)delta;
- (BOOL) slot:(int) aSlot legalForCard:(id)aCard;
@end
