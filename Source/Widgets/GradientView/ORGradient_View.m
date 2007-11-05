//
//  ORGradient_View.m
//  Orca
//
//  Created by Mark Howe on 6/20/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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

#import "ORGradient_View.h"
#import "CTGradient.h"

@implementation ORGradient_View

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setStartColor:[NSColor whiteColor]];
        [self setEndColor:[NSColor blueColor]];
    }
    return self;
}

- (void) dealloc
{
	[gradient release];
	[startColor release];
	[endColor release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[self addSubview:viewToAdd];
}

- (NSColor*) startColor
{
	return startColor;
}

- (void) setStartColor:(NSColor*)aColor
{
	if(!aColor)aColor = [NSColor whiteColor];
	[aColor retain];
	[startColor release];
	startColor = aColor;
	[self makeGradient];
}

- (NSColor*) endColor
{
	return endColor;
}

- (void) setEndColor:(NSColor*)aColor
{
	if(!aColor)aColor = [NSColor blueColor];
	[aColor retain];
	[endColor release];
	endColor = aColor;
	
	[self makeGradient];
}

- (void) makeGradient
{		
	[gradient release];
	gradient = [[CTGradient gradientWithBeginningColor:startColor endingColor:endColor] retain];

	[self setNeedsDisplay: YES];	
}


- (void)drawRect:(NSRect)rect 
{
    [super drawRect:rect];
	[gradient fillRect:[self bounds] angle:-90.];
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    if([decoder allowsKeyedCoding]){
		[self setStartColor:[decoder decodeObjectForKey:@"startColor"]];
		[self setEndColor:[decoder decodeObjectForKey:@"endColor"]]; 
	}
	else {
        [self setStartColor:[decoder decodeObject]]; 
        [self setEndColor:[decoder decodeObject]]; 
	}
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    if([encoder allowsKeyedCoding]){
		[encoder encodeObject:startColor forKey:@"startColor"];
		[encoder encodeObject:endColor forKey:@"endColor"];
	}
	else {
		[encoder encodeObject:startColor];
        [encoder encodeObject:endColor];
	}
}


@end
