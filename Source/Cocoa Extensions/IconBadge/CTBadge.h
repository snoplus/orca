//
//  CTBadge.h
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


#import "CTGradient.h"

@interface CTBadge : NSObject
  {
  NSColor *badgeColor;
  NSColor *labelColor;
  }

+ (CTBadge *)systemBadge;			//classic white on red badge
+ (CTBadge *)badgeWithColor:(NSColor *)badgeColor labelColor:(NSColor *)labelColor;

- (NSImage *)smallBadgeForValue:(unsigned)value;				//Image to use during drag operations
- (NSImage *)largeBadgeForValue:(unsigned)value;				//For dock icons, etc
- (NSImage *)badgeOfSize:(float)size forValue:(unsigned)value;	//A badge of arbitrary size,
																//	<size> is the size in pixels of the badge
																//	not counting the shadow effect
																//	(image returned will be larger than <size>)

- (void)badgeApplicationDockIconWithValue:(unsigned)value insetX:(float)dx y:(float)dy;		//Badges the Application's icon with <value>
																							//	and puts it on the dock
- (NSImage *)badgeOverlayImageForValue:(unsigned)value insetX:(float)dx y:(float)dy;		//Returns a transparent 128x128 image
																							//  with Large badge inset dx/dy from the upper right

- (void)setBadgeColor:(NSColor *)theColor;					//Sets the color used on badge
- (void)setLabelColor:(NSColor *)theColor;					//Sets the color of the label

- (NSColor *)badgeColor;									//Color currently being used on the badge
- (NSColor *)labelColor;									//Color currently being used on the label

@end
