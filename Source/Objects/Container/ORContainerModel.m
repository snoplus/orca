//
//  ORContainerModel.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
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
#import "ORContainerModel.h"

NSString* ORContainerScaleChangedNotification = @"ORContainerScaleChangedNotification";


@implementation ORContainerModel

#pragma mark ¥¥¥initialization

- (void) setUpImage
{
	//---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each container can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"Container"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    
    if([[self orcaObjects] count]){
		NSImage* imageOfObjects = [self imageOfObjects:[self orcaObjects] withTransparency:1.0];
		float xScale = [aCachedImage size].width/[imageOfObjects size].width;
		float yScale = [aCachedImage size].height/[imageOfObjects size].height;
		float scale = MIN(.3,MIN(xScale,yScale));
		float newWidth = [imageOfObjects size].width*scale;
		float newHeight = [imageOfObjects size].height*scale;
		
		[imageOfObjects setSize:NSMakeSize(newWidth-20,newHeight-20)];
		[imageOfObjects compositeToPoint:NSMakePoint(10 + [aCachedImage size].width/2-newWidth/2, 5 + [aCachedImage size].height/2-newHeight/2) operation:NSCompositeSourceAtop];
    }
	
	if([self uniqueIdNumber]){
        NSAttributedString* n = [[NSAttributedString alloc] 
                                initWithString:[NSString stringWithFormat:@"%d",[self uniqueIdNumber]] 
                                    attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:14] forKey:NSFontAttributeName]];
        
        [n drawInRect:NSMakeRect(10,[i size].height-18,[i size].width-20,16)];
        [n release];

    }

    [i unlockFocus];
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
                postNotificationName:OROrcaObjectImageChanged
                              object:self];


}

- (int)scaleFactor 
{
    return scaleFactor;
}

- (void)setScaleFactor:(int)aScaleFactor 
{
    
    if(aScaleFactor < 20)aScaleFactor = 20;
    else if(aScaleFactor>150)aScaleFactor=150;
    
    if(aScaleFactor != scaleFactor){
        [[[self undoManager] prepareWithInvocationTarget:self] setScaleFactor:scaleFactor];
                
        scaleFactor = aScaleFactor;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORContainerScaleChangedNotification
                                                            object:self];
    }
}


//override this because we WANT to use the name of the connector that we are given
- (void) assumeDisplayOf:(ORConnector*)aConnector withKey:(NSString*)aKey
{
    NSEnumerator *e = [[connectors allKeys] objectEnumerator];
    id key;
    while ((key = [e nextObject])) {
        if([connectors objectForKey:key] == aConnector)return;
    }
    if(aConnector){
        [connectors setObject: aConnector forKey:aKey];
        [aConnector setGuardian:self];
    }
}


- (void) makeMainController
{
    [self linkToController:@"ORContainerController"];
}

- (void) positionConnector:(ORConnector*)aConnector
{
}

- (void) addObjects:(NSArray*)someObjects
{
	NSMutableArray* objectList = [NSMutableArray arrayWithArray:someObjects];
	NSMutableArray* forbiddenObjects = [NSMutableArray array];
	NSEnumerator* e = [someObjects objectEnumerator];
	id anObj;
	while(anObj = [e nextObject]){
		if(![anObj acceptsGuardian:self]){
			[forbiddenObjects addObject:anObj];
		}
	}
	[objectList removeObjectsInArray:forbiddenObjects];
	[super addObjects:objectList];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    int value = [decoder decodeIntForKey:@"scaleFactor"];
    if(value == 0)value = 100;
    [self setScaleFactor:value];

    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:scaleFactor forKey:@"scaleFactor"];						
	
}




@end
