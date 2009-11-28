//
//  ORDotImage.m
//  Orca
//
//  Created by Mark Howe on Fri Oct 22, 2004.
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


#import "ORDotImage.h"

static NSImage *shadowImage			= nil;
static NSImage *colorMaskImage		= nil;
static NSImage *refractionMaskImage	= nil;

@implementation ORDotImage
+ (void)initialize 
{
    //defaults in case someone calls initWithColor instead of xxxWithColor methods
    if(!shadowImage)shadowImage					=    [[NSImage imageNamed:@"dotshadow"] retain];
    if(!colorMaskImage)colorMaskImage			=    [[NSImage imageNamed:@"dotcolormask"] retain];
    if(!refractionMaskImage)refractionMaskImage =    [[NSImage imageNamed:@"dottopmask"] retain];
}


+ (ORDotImage *)dotWithColor:(NSColor *)aColor 
{
    if(!shadowImage)shadowImage					 =    [[NSImage imageNamed:@"dotshadow"] retain];
    if(!colorMaskImage)colorMaskImage			 =    [[NSImage imageNamed:@"dotcolormask"] retain];
    if(!refractionMaskImage)refractionMaskImage  =    [[NSImage imageNamed:@"dottopmask"] retain];
    return [[[self alloc] initWithColor:aColor] autorelease];
}

+ (ORDotImage *)bigDotWithColor:(NSColor *)aColor 
{
    if(!shadowImage)shadowImage					 =    [[NSImage imageNamed:@"bigdotshadow"] retain];
    if(!colorMaskImage)colorMaskImage			 =    [[NSImage imageNamed:@"bigdotcolormask"] retain];
    if(!refractionMaskImage)refractionMaskImage  =    [[NSImage imageNamed:@"bigdottopmask"] retain];
    return [[[self alloc] initWithColor:aColor] autorelease];
}

+ (ORDotImage *)vRectWithColor:(NSColor *)aColor 
{
    if(!shadowImage)shadowImage					 =    [[NSImage imageNamed:@"vrectshadow"] retain];
    if(!colorMaskImage)colorMaskImage			 =    [[NSImage imageNamed:@"vrectcolormask"] retain];
    if(!refractionMaskImage)refractionMaskImage  =    [[NSImage imageNamed:@"vrecttopmask"] retain];
    return [[[self alloc] initWithColor:aColor] autorelease];
}
+ (ORDotImage *)hRectWithColor:(NSColor *)aColor 
{
    if(!shadowImage)shadowImage					 =    [[NSImage imageNamed:@"hrectshadow"] retain];
    if(!colorMaskImage)colorMaskImage			 =    [[NSImage imageNamed:@"hrectcolormask"] retain];
    if(!refractionMaskImage)refractionMaskImage  =    [[NSImage imageNamed:@"hrecttopmask"] retain];
    return [[[self alloc] initWithColor:aColor] autorelease];
}

+ (ORDotImage *)smallDotWithColor:(NSColor *)aColor 
{
    if(!shadowImage)shadowImage					 =    [[NSImage imageNamed:@"smalldotshadow"] retain];
    if(!colorMaskImage)colorMaskImage			 =    [[NSImage imageNamed:@"smalldotcolormask"] retain];
    if(!refractionMaskImage)refractionMaskImage  =    [[NSImage imageNamed:@"smalldottopmask"] retain];
    return [[[self alloc] initWithColor:aColor] autorelease];
}

- initWithColor:(NSColor *)aColor 
{
    if (self = [super initWithSize:[refractionMaskImage size]]) {
        NSImage *newColorMaskImage = [colorMaskImage copy];        
        NSRect colorMaskBounds = NSMakeRect(0, 0, [colorMaskImage size].width, [colorMaskImage size].height); 
        
        //do a Shadow
        [self lockFocus];
        [shadowImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy fraction:.7];
        [self unlockFocus];        
        
        //set up the color mask (tint it, then composite it)
        [newColorMaskImage lockFocus];
        [aColor set];
        NSRectFillUsingOperation(colorMaskBounds, NSCompositeSourceAtop);
        [newColorMaskImage unlockFocus];
        [self lockFocus];
        [newColorMaskImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
        
        // setup the refraction mask
        [refractionMaskImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];         
        [self unlockFocus];
        [newColorMaskImage release];
    }
     
    return self;
}
@end
