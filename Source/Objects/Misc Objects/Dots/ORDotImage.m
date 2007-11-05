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

static NSImage *shadowImage, *colorMaskImage, *refractionMaskImage;

@implementation ORDotImage
+ (void)initialize 
{
    //defaults in case someone calls initWithColor instead of xxxWithColor methods
    shadowImage         =    [NSImage imageNamed:@"dotshadow"];
    colorMaskImage      =    [NSImage imageNamed:@"dotcolormask"];
    refractionMaskImage =    [NSImage imageNamed:@"dottopmask"];
}


+ (ORDotImage *)dotWithColor:(NSColor *)aColor 
{
    shadowImage         =    [NSImage imageNamed:@"dotshadow"];
    colorMaskImage      =    [NSImage imageNamed:@"dotcolormask"];
    refractionMaskImage =    [NSImage imageNamed:@"dottopmask"];
    return [[[self alloc] initWithColor:aColor] autorelease];
}

+ (ORDotImage *)bigDotWithColor:(NSColor *)aColor 
{
    shadowImage         =    [NSImage imageNamed:@"bigdotshadow"];
    colorMaskImage      =    [NSImage imageNamed:@"bigdotcolormask"];
    refractionMaskImage =    [NSImage imageNamed:@"bigdottopmask"];
    return [[[self alloc] initWithColor:aColor] autorelease];
}

+ (ORDotImage *)vRectWithColor:(NSColor *)aColor 
{
    shadowImage         =    [NSImage imageNamed:@"vrectshadow"];
    colorMaskImage      =    [NSImage imageNamed:@"vrectcolormask"];
    refractionMaskImage =    [NSImage imageNamed:@"vrecttopmask"];
    return [[[self alloc] initWithColor:aColor] autorelease];
}
+ (ORDotImage *)hRectWithColor:(NSColor *)aColor 
{
    shadowImage         =    [NSImage imageNamed:@"hrectshadow"];
    colorMaskImage      =    [NSImage imageNamed:@"hrectcolormask"];
    refractionMaskImage =    [NSImage imageNamed:@"hrecttopmask"];
    return [[[self alloc] initWithColor:aColor] autorelease];
}

+ (ORDotImage *)smallDotWithColor:(NSColor *)aColor 
{
    shadowImage         =    [NSImage imageNamed:@"smalldotshadow"];
    colorMaskImage      =    [NSImage imageNamed:@"smalldotcolormask"];
    refractionMaskImage =    [NSImage imageNamed:@"smalldottopmask"];
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
