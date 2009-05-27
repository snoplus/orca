//-------------------------------------------------------------------------
//  ORSciptTaskModel.m
//
//  Created by Mark A. Howe on Tuesday 12/26/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORRunScriptModel.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORScriptRunner.h"

@implementation ORRunScriptModel

- (NSString*) helpURL
{
	return @"Data_Chain/Run_Scripts.html";
}

#pragma mark ***Initialization
- (void) registerNotificationObservers
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(runningChanged:)
                         name : ORScriptRunnerRunningChanged
						object: nil];	
}

- (void) runningChanged:(NSNotification*)aNote
{
	[self setUpImage];
}

- (void) setUpImage
{
	
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"RunScript"];
	
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	NSSize imageSize = [aCachedImage size];
	NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSFont labelFontOfSize:12], NSFontAttributeName,
								nil];		
	[[self identifier] drawInRect:NSMakeRect(30,-4, imageSize.width,imageSize.height) 
				   withAttributes:attributes];

	if([self running]){
		NSImage* runningImage = [NSImage imageNamed:@"ScriptRunning"];
		[runningImage setSize:NSMakeSize(40,40)];
		NSSize imageSize = [runningImage size];
		NSSize ourSize = [self frame].size;
        [runningImage compositeToPoint:NSMakePoint(ourSize.width - imageSize.width,-16) operation:NSCompositeSourceOver];
    }
	
	[i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
}


- (void) setUniqueIdNumber:(unsigned long)anIdNumber
{
	[super setUniqueIdNumber:anIdNumber];
	[self setUpImage];
}



- (void) setSelectorOK:(SEL)aSelectorOK bad:(SEL)aSelectorBAD withObject:(id)anObject target:(id)aTarget
{
	selectorOK	= aSelectorOK;
	selectorBAD	= aSelectorBAD;
	anArg		= [anObject retain];
	target		= [aTarget retain];
}

- (void) scriptRunnerDidFinish:(BOOL)normalFinish returnValue:(id)aValue
{
	[super scriptRunnerDidFinish:normalFinish returnValue:aValue];
	if(normalFinish){
		if([aValue intValue]!=0) [target performSelector:selectorOK withObject:anArg];
		else					 [target performSelector:selectorBAD withObject:nil];
	}
	else {
		[target performSelector:selectorBAD withObject:nil];
	}
	[anArg release];
	anArg = nil;
	[target release];
	target = nil;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	[self registerNotificationObservers];
    return self;
}


@end

