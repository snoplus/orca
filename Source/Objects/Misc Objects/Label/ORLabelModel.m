//
//  ORLabelModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
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


#pragma mark ¥¥¥Imported Files
#import "ORLabelModel.h"

NSString* ORLabelModelTextSizeChanged			 = @"ORLabelModelTextSizeChanged";
NSString* ORLabelModelLabelChangedNotification   = @"ORLabelModelLabelChangedNotification";
NSString* ORLabelLock							 = @"ORLabelLock";

@implementation ORLabelModel

#pragma mark ¥¥¥initialization


- (NSString*) label
{
	return label;
}

- (NSString*) elementName
{
	return @"Text Label";
}

- (int) state
{
	return 0;
}
- (NSString*) comment
{
	return label;
}

- (void) setComment:(NSString*)aComment
{
	[self setLabel:aComment];
}

- (NSString*) description:(NSString*)prefix
{
    return [NSString stringWithFormat:@"%@%@ %d",prefix,[self elementName],[self uniqueIdNumber]];
}


- (id) stateValue
{
	return 0;
}

- (NSString*) fullHwName
{
    return @"N/A";
}

- (int) compareStringTo:(id)anElement usingKey:(NSString*)aKey
{
    NSString* ourKey   = [self valueForKey:aKey];
    NSString* theirKey = [anElement valueForKey:aKey];
    if(!ourKey && theirKey)         return 1;
    else if(ourKey && !theirKey)    return -1;
    else if(!ourKey || !theirKey)   return 0;
    return [ourKey compare:theirKey];
}


#pragma mark ***Accessors

- (int) textSize
{
    return textSize;
}

- (void) setTextSize:(int)aTextSize
{
	if(aTextSize==0)aTextSize = 16;
	else if(aTextSize<9)aTextSize = 9;
	else if(aTextSize>36)aTextSize = 36;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setTextSize:textSize];
    
    textSize = aTextSize;
	
    [self setUpImage];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabelModelTextSizeChanged object:self];

}

- (void) setLabel:(NSString*)aLabel
{
    if(!aLabel)aLabel = @"Text Box";
    [[[self undoManager] prepareWithInvocationTarget:self] setLabel:label];
    
    [label autorelease];
    label = [aLabel copy];
    [self setUpImage];
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORLabelModelLabelChangedNotification
                              object:self];
}

- (void) setLabelNoNotify:(NSString*)aLabel
{
    if(!aLabel)aLabel = @"Text Box";
    [label autorelease];
    label = [aLabel copy];
    [self setUpImage];
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return  [aGuardian isMemberOfClass:NSClassFromString(@"ORGroup")]           || 
			[aGuardian isMemberOfClass:NSClassFromString(@"ORProcessModel")]	||
            [aGuardian isMemberOfClass:NSClassFromString(@"ORContainerModel")];
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each Label can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
	if(label){
		NSAttributedString* n = [[NSAttributedString alloc] 
								initWithString:[label length]?label:@"Text Label"
									attributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Geneva"  size:textSize] forKey:NSFontAttributeName]];
		
		NSSize theSize = [n size];

		NSImage* i = [[NSImage alloc] initWithSize:theSize];
		[i lockFocus];
		
			
		[n drawInRect:NSMakeRect(0,0,theSize.width,theSize.height)];
		[n release];
		[i unlockFocus];
		[self setImage:i];
		[i release];
    }
	else {
		[self setImage:[NSImage imageNamed:@"Label"]];
	}
    [[NSNotificationCenter defaultCenter]
                postNotificationName:OROrcaObjectImageChanged
                              object:self];

}

- (void) setImage:(NSImage*)anImage
{
	[super setImage:anImage];

	if(anImage){
		[highlightedImage release];
		highlightedImage = [[NSImage alloc] initWithSize:[anImage size]];
		[highlightedImage lockFocus];
		NSAttributedString* n = [[NSAttributedString alloc] 
								initWithString:[label length]?label:@"Text Label"
									attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Geneva"  size:textSize],NSFontAttributeName,
									[NSColor colorWithCalibratedRed:.5 green:.5 blue:.5 alpha:.3],NSBackgroundColorAttributeName,nil]];
		NSSize theSize = [n size];
		[n drawInRect:NSMakeRect(0,0,theSize.width,theSize.height)];
		[n release];
		[highlightedImage unlockFocus];
	}

}


- (void) makeMainController
{
    [self linkToController:@"ORLabelController"];
}


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setLabel:[decoder decodeObjectForKey:@"label"]];
    [self setTextSize:[decoder decodeIntForKey:@"textSize"]];
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:label forKey:@"label"];
    [encoder encodeInt:textSize forKey:@"textSize"];
}

@end
