//
//  CTBadge.m
//  CTWidgets
//
//  Created by Chad Weider on 1/6/06.
//  Copyright (c) 2006 Cotingent.
//  Some rights reserved: <http://creativecommons.org/licenses/by/2.5/>
//
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

#import "CTBadge.h"

const float CTLargeBadgeSize = 46.;
const float CTSmallBadgeSize = 23.;
const float CTLargeLabelSize = 24.;
const float CTSmallLabelSize = 11.;

@interface CTBadge (Private)
- (NSImage *)badgeMaskOfSize:(float)size length:(unsigned)length;			//return a badge with height of <size> to fit <length> characters
- (NSAttributedString *)labelForValue:(unsigned)value size:(unsigned)size;	//returns appropriately attributed label string
- (CTGradient *)badgeGradient;												//gradient used to fill badge mask
@end

@implementation CTBadge

- (id)init
  {
  self = [super init];
  
  if (self != nil)
	{
	badgeColor = nil;
	labelColor = nil;
	
	[self setBadgeColor:[NSColor redColor]];
	[self setLabelColor:[NSColor whiteColor]];
	}
  return self;
  }

- (void)dealloc
  {
  if(badgeColor != nil)
	[badgeColor release];
  if(labelColor != nil)
    [labelColor release];
  [super dealloc];
  }

+ (CTBadge *)systemBadge
  {
  id newInstance = [[[self class] alloc] init];
  
  return [newInstance autorelease];
  }

+ (CTBadge *)badgeWithColor:(NSColor *)aBadgeColor labelColor:(NSColor *)aLabelColor;
  {
  id newInstance = [[[self class] alloc] init];
  
  [newInstance setBadgeColor:aBadgeColor];
  [newInstance setLabelColor:aLabelColor];
  
  return [newInstance autorelease];
  }


#pragma mark Appearance
- (void)setBadgeColor:(NSColor *)theColor;
  {
  if(badgeColor != nil)
	[badgeColor release];
  
  badgeColor = theColor;
  [badgeColor retain];
  }
- (void)setLabelColor:(NSColor *)theColor;
  {
  if(labelColor != nil)
	[labelColor release];
  
  labelColor = theColor;
  [labelColor retain];
  }

- (NSColor *)badgeColor
  {
  return badgeColor;
  }
- (NSColor *)labelColor
  {
  return labelColor;
  }

#pragma mark -

#pragma mark Drawing
- (NSImage *)smallBadgeForValue:(unsigned)value		//does drawing in it's own special way
  {
  return [self badgeOfSize:CTSmallBadgeSize forValue:value];
  }

- (NSImage *)largeBadgeForValue:(unsigned)value
  {
  return [self badgeOfSize:CTLargeBadgeSize forValue:value];
  }

- (NSImage *)badgeOfSize:(float)size forValue:(unsigned)value
  {
  float scaleFactor = 0.0;
  
  if(size <= 0)
	[NSException raise:NSInvalidArgumentException format:@"%@ - (NSImage *)smallBadgeForValue:(unsigned)value: size (%f) must be positive", [self class], size];
  else if(size <= CTSmallBadgeSize)
	scaleFactor = size/CTSmallBadgeSize;
  else
	scaleFactor = size/CTLargeBadgeSize;
  
  //Label stuff  -----------------------------------------------
  NSAttributedString *label;
  NSSize labelSize;
  
  if(size <= CTSmallBadgeSize)
	label = [self labelForValue:value size:CTSmallLabelSize*scaleFactor];
  else
	label = [self labelForValue:value size:CTLargeLabelSize*scaleFactor];
  
  labelSize = [label size];
  
  //Badge stuff  -----------------------------------------------
  NSImage *badgeImage;	//this the image with the gradient fill
  NSImage *badgeMask ;	//we nock out this mask from the gradient
  
  CTGradient *badgeGradient = [self badgeGradient];
  
  float shadowOpacity,
		shadowOffset,
        shadowBlurRadius;
  
  if(size <= CTSmallBadgeSize)
	{
	shadowOpacity    = .6;
	shadowOffset     = floorf(1*scaleFactor);
	shadowBlurRadius = ceilf(1*scaleFactor);
	}
  else
	{
	shadowOpacity    = .8;
	shadowOffset     = ceilf(1*scaleFactor);
	shadowBlurRadius = ceilf(2*scaleFactor);
	}
  
  badgeMask = [self badgeMaskOfSize:size length:[label length]];
  
  NSSize badgeSize = [badgeMask size];
  NSPoint   origin = NSMakePoint(shadowBlurRadius, shadowBlurRadius+shadowOffset);
  
  badgeImage = [[NSImage alloc] initWithSize:NSMakeSize(badgeSize.width  + 2*shadowBlurRadius,											//sometimes it needs more
														badgeSize.height + 2*shadowBlurRadius - shadowOffset + (size <= CTSmallBadgeSize))];	//space when small
  
  [badgeImage lockFocus];
	[badgeGradient fillRect:NSMakeRect(origin.x, origin.y, floorf(badgeSize.width), floorf(badgeSize.height)) angle:-30];				//apply the gradient
	[badgeMask compositeToPoint:origin operation: NSCompositeDestinationAtop];															//knock out the badge area
	[label drawInRect:NSMakeRect(origin.x, origin.y+floorf((badgeSize.height-labelSize.height)/2), badgeSize.width, labelSize.height)];	//draw label in center
  [badgeImage unlockFocus];
  
  
  //Final stuff   -----------------------------------------------
  NSImage *image = [[NSImage alloc] initWithSize:[badgeImage size]];
  
  [image lockFocus];
	[NSGraphicsContext saveGraphicsState];
	  NSShadow *theShadow = [[NSShadow alloc] init];
	  [theShadow setShadowOffset: NSMakeSize(0,-shadowOffset)];
	  [theShadow setShadowBlurRadius:shadowBlurRadius];
	  [theShadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:shadowOpacity]];
	  [theShadow set];
	  [theShadow release];
	  [badgeImage compositeToPoint:NSZeroPoint operation: NSCompositeSourceOver];
	[NSGraphicsContext restoreGraphicsState];
  [image unlockFocus];
  
  [badgeImage release];
  
  return [image autorelease];
  }


- (NSImage *)badgeOverlayImageForValue:(unsigned)value insetX:(float)dx y:(float)dy
  {
  NSImage *badgeImage = [self largeBadgeForValue:value];
  NSImage *overlayImage = [[NSImage alloc] initWithSize:NSMakeSize(128,128)];
  
  //draw large icon in the upper right corner of the overlay image
  [overlayImage lockFocus];
	  NSSize badgeSize = [badgeImage size];
	  [badgeImage compositeToPoint:NSMakePoint(128-dx-badgeSize.width,128-dy-badgeSize.height) operation:NSCompositeSourceOver];  
  [overlayImage unlockFocus];
  
  return [overlayImage autorelease];
  }

- (void)badgeApplicationDockIconWithValue:(unsigned)value insetX:(float)dx y:(float)dy
  {
  NSImage *appIcon      = [NSImage imageNamed:@"NSApplicationIcon"];
  NSImage *badgeOverlay = [self badgeOverlayImageForValue:value insetX:dx y:dy];
  
  //Put the appIcon underneath the badgeOverlay
  [badgeOverlay lockFocus];
	[appIcon compositeToPoint:NSZeroPoint operation:NSCompositeDestinationOver];
  [badgeOverlay unlockFocus];
  
  [NSApp setApplicationIconImage:badgeOverlay];
  }

#pragma mark -

#pragma mark Misc.
- (CTGradient *)badgeGradient
  {
  return [CTGradient gradientWithBeginningColor:[self badgeColor] endingColor:[[self badgeColor] shadowWithLevel:.2]];
  }

- (NSAttributedString *)labelForValue:(unsigned)value size:(unsigned)size
  {
  //set Attributes to use on String  ---------------------------
  NSFont *labelFont;
  
  if(size <= CTSmallLabelSize)
	labelFont = [NSFont boldSystemFontOfSize:size];
  else
	labelFont = [NSFont fontWithName:@"Helvetica-Bold" size:size];
  
  NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];[pStyle setAlignment:NSCenterTextAlignment];
  NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[self labelColor]   , NSForegroundColorAttributeName,
																		labelFont           , NSFontAttributeName           ,
																		pStyle              , NSParagraphStyleAttributeName , nil];
  [pStyle release];
  
  //Label stuff
  NSAttributedString *label;
    
  if(abs(value) < 100000)
	label = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%i",value] attributes:attributes];
  else
	label = [[NSAttributedString alloc] initWithString:@"*" attributes:attributes];
  
  return [label autorelease];;
  }

- (NSImage *)badgeMaskOfSize:(float)size length:(unsigned)length;
  {
  NSImage *badgeMask;
  
  if(length <=2)
	badgeMask = [NSImage imageNamed:@"1.pdf"];
  else if(length <=3)
	badgeMask = [NSImage imageNamed:@"3.pdf"];
  else if(length <=4)
	badgeMask = [NSImage imageNamed:@"4.pdf"];
  else
	badgeMask = [NSImage imageNamed:@"5.pdf"];
  
  if(size > 0 && size != [badgeMask size].height)
	{
	[badgeMask setName:nil];
	[badgeMask setScalesWhenResized:YES];
	[badgeMask setSize:NSMakeSize([badgeMask size].width*(size/[badgeMask size].height), size)];
	}
  
  return badgeMask;
  }

@end
