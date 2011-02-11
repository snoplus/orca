//
//  ORPxiAdapterModel.h
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark ¥¥¥Imported Files
#import "ORMPodMiniCrateModel.h"
#import "ORMPodCard.h"

@implementation ORMPodMiniCrateModel

#pragma mark ¥¥¥initialization
- (void) makeConnectors
{	
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"MPodMiniCrateSmall"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    if(powerOff){
        NSAttributedString* s = [[[NSAttributedString alloc] initWithString:@"No Pwr"
                                                                 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [NSColor redColor],NSForegroundColorAttributeName,
                                                                     [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
                                                                     nil]] autorelease]; 
        [s drawAtPoint:NSMakePoint(90,0)];
    }
    
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:3 yBy:65];
        [transform scaleXBy:.46 yBy:.46];
        [transform concat];
        NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
        OrcaObject* anObject;
        while(anObject = [e nextObject]){
            BOOL oldHighlightState = [anObject highlighted];
            [anObject setHighlighted:NO];
            [anObject drawSelf:NSMakeRect(0,0,500,[[self image] size].height)];
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
    [self linkToController:@"ORMPodMiniCrateController"];
}

//- (NSString*) helpURL
//{
//	return @"Pxi/Crates.html";
//}

- (void) connected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(connected)];
}

- (void) disconnected
{
	[[self orcaObjects] makeObjectsPerformSelector:@selector(disconnected)];
}

#pragma mark ¥¥¥Accessors
- (NSString*) adapterArchiveKey
{
	return @"MPod Adapter";
}

- (NSString*) crateAdapterConnectorKey
{
	return @"MPod Crate Adapter Connector";
}

- (void) setAdapter:(id)anAdapter
{
	[super setAdapter:anAdapter];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[super registerNotificationObservers];
	   
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORMPodCardSlotChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(powerFailed:)
                         name : @"MPodPowerFailedNotification"
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(powerRestored:)
                         name : @"MPodPowerRestoredNotification"
                       object : nil];
}

- (id) controllerCard
{
	return adapter;
}


- (void) pollCratePower
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollCratePower) object:nil];
    @try {
        if(polledOnce)[[self controllerCard] checkCratePower];
		polledOnce = YES;
    }
	@catch(NSException* localException) {
    }
    [self performSelector:@selector(pollCratePower) withObject:nil afterDelay:1];
}

- (void) powerFailed:(NSNotification*)aNotification
{
    if([aNotification object] == [self controllerCard]){
        [self setPowerOff:YES];
		if(!cratePowerAlarm){
			cratePowerAlarm = [[ORAlarm alloc] initWithName:@"No MPod Crate Power" severity:0];
			[cratePowerAlarm setSticky:YES];
			[cratePowerAlarm setHelpStringFromFile:@"NoMPodCratePowerHelp"];
			[cratePowerAlarm postAlarm];
		} 
    }
}

- (void) powerRestored:(NSNotification*)aNotification
{
    if([aNotification object] == [self controllerCard]){
        [self setPowerOff:NO];
		[cratePowerAlarm clearAlarm];
		[cratePowerAlarm release];
		cratePowerAlarm = nil;
    }
}
@end


@implementation ORMPodMiniCrateModel (OROrderedObjHolding)
- (int) slotAtPoint:(NSPoint)aPoint 
{
	//fist slot is special and half width
	if(aPoint.x<15)	return 0;
	else			return floor(((int)aPoint.x - 15)/[self objWidth]) + 1;
}

- (NSPoint) pointForSlot:(int)aSlot 
{
	if(aSlot==0) return NSMakePoint(0,0);
	else		 return NSMakePoint((aSlot-1)*[self objWidth] + 15,0);
}


- (NSRange) legalSlotsForObj:(id)anObj
{
	if( [anObj isKindOfClass:NSClassFromString(@"ORMPodCModel")]){
		return NSMakeRange(0,1);
	}
	else {
		return  NSMakeRange(1,[self maxNumberOfObjects]);
	}
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj 
{ 
	if(![anObj isKindOfClass:NSClassFromString(@"ORMPodCModel")] && (aSlot==0)){
		return YES;
	}
	else return NO;
}

- (int) maxNumberOfObjects	{ return 5; }
- (int) objWidth			{ return 30; }
@end
