//
//  ORSNORackModel.m
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

#pragma mark •••Imported Files
#import "ORSNORackModel.h"
#import "ORSNOCard.h"
#import "ORSNOCrateModel.h"

@implementation ORSNORackModel

#pragma mark •••initialization
- (void) makeConnectors
{	
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"SNORack"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:5 yBy:27];
        [transform scaleXBy:1 yBy:1];
        [transform concat];
        NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
        OrcaObject* anObject;
        while(anObject = [e nextObject]){
            BOOL oldHighlightState = [anObject highlighted];
            [anObject setHighlighted:NO];
            if([self guardian]){
				[anObject drawSelf:NSMakeRect(0,0,500,[aCachedImage size].height) withTransparency:1];
			}
			else {
				[anObject drawIcon:NSMakeRect(0,0,500,[aCachedImage size].height) withTransparency:1];
			}
            [anObject setHighlighted:oldHighlightState];
        }
    }
    [i unlockFocus];
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
                postNotificationName:OROrcaObjectImageChanged
                              object:self];
}

- (void) makeMainController
{
    [self linkToController:@"ORSNORackController"];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
		   
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORSNOCrateSlotChanged
                       object : nil];

	   [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORSNOCardSlotChanged
                       object : nil];
}

- (int) rackNumber
{
	return [self uniqueIdNumber];
}

- (void) viewChanged:(NSNotification*)aNotification
{
    [self setUpImage];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"SNO Rack %d",[self rackNumber]];
}

- (NSComparisonResult)sortCompare:(OrcaObject*)anObj
{
    return [self uniqueIdNumber] - [anObj uniqueIdNumber];
}
@end
