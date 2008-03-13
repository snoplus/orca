//
//  OrcaObject.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 29 2002.
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
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#pragma mark ¥¥¥Notification Strings
NSString* OROrcaObjectMoved         = @"OrcaObject Moved Notification";
NSString* OROrcaObjectDeleted       = @"OrcaObject Deleted Notification";
NSString* ORTagChangedNotification  = @"ORTagChangedNotification";
NSString* ORObjPtr                  = @"OrcaObject Pointer";
NSString* ORMovedObject             = @"OrcaObject That Moved";
NSString* ORForceRedraw             = @"ORForceRedraw";
NSString* OROrcaObjectImageChanged  = @"OROrcaObjectImageChanged";
NSString* ORIDChangedNotification   = @"ORIDChangedNotification";
NSString* ORObjArrayPtrPBType       = @"ORObjArrayPtrPBType";
NSString* ORWarningPosted			= @"WarningPosted";
NSString* ORMiscAttributesChanged   = @"ORMiscAttributesChanged";
NSString* ORMiscAttributeKey		= @"ORMiscAttributeKey";

#pragma mark ¥¥¥Inialization
@implementation OrcaObject 

- (id) init //designated initializer
{
    self = [super init];
    [self setConnectors:[NSMutableDictionary dictionary]];
    return self;
}


- (id) copyWithZone:(NSZone*)zone
{
    id obj = [[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]] retain];
    [obj setUniqueIdNumber:0];
    return obj;
}

-(void)dealloc
{
	[highlightedImage release];
    [image release];
    [connectors release];
	[miscAttributes release];
    [super dealloc];
}

- (void) setImage:(NSImage*)anImage
{
    [anImage retain];
    [image release];
    image = anImage;
    
    if(image){
        NSSize aSize = [image size];
        frame.size.width = aSize.width;
        frame.size.height = aSize.height;
        bounds.size.width = aSize.width;
        bounds.size.height = aSize.height;
    }
    else {
        frame.size.width 	= 50;
        frame.size.height 	= 50;
        bounds.size.width 	= 50;
        bounds.size.height 	= 50;
    }  
	
	if(image){
		NSRect sourceRect = NSMakeRect(0,0,[image size].width,[image size].height);
		[highlightedImage release];
		highlightedImage = [[NSImage alloc] initWithSize:[image size]];
		[highlightedImage lockFocus];
		[image dissolveToPoint:NSZeroPoint fraction:1];
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
		NSRectFillUsingOperation(sourceRect, NSCompositeSourceAtop);
		[highlightedImage unlockFocus];
	}
	else {
		[highlightedImage release];
		highlightedImage = nil;
	}
}


#pragma mark ¥¥¥Accessors
- (NSString*) description
{
    return [NSString stringWithFormat: @"Class: <%@ %ld>\nRetainCount: %d\nFrame: %.0f %.0f %.0f %.0f\n",
        NSStringFromClass([self class]),(long)self,
        [self retainCount],
        [self frame].origin.x,
        [self frame].origin.y,
        [self frame].size.width,
        [self frame].size.height];
}

- (int)	x
{
    return [self frame].origin.x;
}

- (int) y
{
    return [self frame].origin.y;
}

- (id) guardian
{
    return guardian;
}

- (void) setGuardian:(id)aGuardian
{
    //note the children do NOT retain their guardians to avoid retain cycles.
    guardian = aGuardian;
}

- (NSComparisonResult)sortCompare:(OrcaObject*)anObj
{
    return [[self className] caseInsensitiveCompare:[anObj className]];
}

- (id)document;
{
    return [[NSApp delegate]document];
}

- (void) wakeUp {aWake = YES;}
- (void) sleep 	{aWake = NO;}
- (BOOL) aWake	{return aWake;}

- (void) setConnectors:(NSMutableDictionary*)someConnectors;
{
    [someConnectors retain];
    [connectors release];
    connectors = someConnectors;
}

- (NSMutableDictionary*) connectors;
{
    return connectors;
}


- (NSUndoManager *)undoManager
{
    return [[self document] undoManager];
}


- (NSRect) defaultFrame
{
    return NSMakeRect(0,0,50,50);
}

- (void) setFrame:(NSRect)aValue
{
    frame = aValue;
    bounds.size = frame.size;
}

- (NSRect) frame
{
    return frame;
}

- (void) setBounds:(NSRect)aValue
{
    bounds = aValue;
}

- (NSRect) bounds
{
    return bounds;
}

- (void) setFrameOrigin:(NSPoint)aPoint
{
    [self moveTo:aPoint];
}


- (void) setOffset:(NSPoint)aPoint
{
    offset = aPoint;
}

- (NSPoint)offset
{
    return offset;
}

- (BOOL) highlighted
{
    return highlighted;
}

- (void) setHighlighted:(BOOL)state
{
    if([self selectionAllowed])highlighted = state;
    else highlighted = NO;
}

- (BOOL) insideSelectionRect;
{
    return insideSelectionRect;
}

- (BOOL) skipConnectionDraw
{
    return skipConnectionDraw;
}

- (void) setSkipConnectionDraw:(BOOL)state
{
    skipConnectionDraw = state;
}

- (void) setInsideSelectionRect:(BOOL)state
{
    insideSelectionRect = state;
}

- (BOOL) rectIntersectsIcon:(NSRect)aRect
{
    return NSIntersectsRect(aRect,frame);
}

- (void) makeMainController
{
    //subclasses will override
}


- ( NSMutableArray*)children
{
    return nil;
}

- (NSMutableArray*) familyList
{
    return [NSMutableArray arrayWithObject:self];
}

- (int) tag
{
    return tag;
}

- (void) setTag:(int)aTag
{
    tag = aTag;
    
    [[NSNotificationCenter defaultCenter]
         postNotificationName:ORTagChangedNotification
                       object:self];
}

- (int) tagBase
{
    //some objects, i.e. CAMAC start at 1 instead of 0. those object will override this method.
    return 0;
}

- (NSString*) fullID
{
    return [NSString stringWithFormat:@"%@,%d",NSStringFromClass([self class]),[self uniqueIdNumber]];
}

- (void) askForUniqueIDNumber
{
    [[self document] assignUniqueIDNumber:self];
}

- (void) setUniqueIdNumber:(unsigned long)anIdNumber
{
    uniqueIdNumber = anIdNumber;
    
    [[NSNotificationCenter defaultCenter]
         postNotificationName:ORIDChangedNotification
                       object:self];
}
- (unsigned long) uniqueIdNumber
{
    return uniqueIdNumber;
}

- (BOOL) selectionAllowed
{
    //default is to allow selection. subclasses can override.
    return YES;
}

- (BOOL) changesAllowed
{
    //default is to allow changes. subclasses can override.
    return YES;
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

#pragma mark ¥¥¥ID Helpers
//----++++----++++----++++----++++----++++----++++----++++----++++
//  These methods are used when objects are displayed in tables
//----++++----++++----++++----++++----++++----++++----++++----++++
- (NSString*) objectName
{
    NSString* theName =  NSStringFromClass([self class]);
	if([theName hasPrefix:@"OR"])theName = [theName substringFromIndex:2];
	if([theName hasSuffix:@"Model"])theName = [theName substringToIndex:[theName length]-5];
	return theName;
}
- (NSString*) isDataTaker
{
    return [self conformsToProtocol:@protocol(ORDataTaker)]?@"YES":@" NO";
}

- (NSString*) supportsHardwareWizard
{
    return [self conformsToProtocol:@protocol(ORHWWizard)]?@"YES":@" NO";
}

- (NSString*) identifier
{
    return @"";
}
//----++++----++++----++++----++++----++++----++++----++++----++++


#pragma mark ¥¥¥Undoable Actions
-(void)moveTo:(NSPoint)aPoint
{
    [[[self undoManager] prepareWithInvocationTarget:self] moveTo:[self frame].origin];
    frame.origin = aPoint;
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:self forKey: ORMovedObject];
    
    [[NSNotificationCenter defaultCenter]
                        postNotificationName:OROrcaObjectMoved
                                      object:self
                                    userInfo: userInfo];
}

-(void)move:(NSPoint)aPoint
{
    [self moveTo:NSMakePoint(frame.origin.x+aPoint.x,frame.origin.y+aPoint.y)];
}

-(void)showMainInterface
{
    [self makeMainController];
}

-(void)linkToController:(NSString*)controllerClassName
{
    [[self document] makeController:controllerClassName forObject:self];
}




#pragma mark ¥¥¥Positioning
- (void) offsetFrameFromPoint:(NSData*)pointData
{
    NSPoint aPoint = [pointData pointValue];
    [self  setFrameOrigin:NSMakePoint(aPoint.x + [self offset].x,aPoint.y + [self offset].y) ];
}

- (void) offsetFrameBy:(NSPoint)aPoint
{
    [self setOffset:NSMakePoint(aPoint.x + [self offset].x,aPoint.y + [self offset].y) ];
    frame.origin = [self offset];
}


#pragma mark ¥¥¥Drawing

- (void) drawSelf:(NSRect)aRect
{
    [self drawSelf:aRect withTransparency:1.0];
}


- (void) drawSelf:(NSRect)aRect withTransparency:(float)aTransparency
{
	//a workaround for a case where image hasn't been made yet.. don't worry--it will get made below if need be.
	if(aRect.size.height == 0)aRect.size.height = 1;
	if(aRect.size.width == 0)aRect.size.width = 1;
	
    if(NSIntersectsRect(aRect,[self frame])){
		
		NSShadow* theShadow = nil;
		if([self guardian]){
			[NSGraphicsContext saveGraphicsState]; 
			
			// Create the shadow below and to the right of the shape.
			theShadow = [[NSShadow alloc] init]; 
			[theShadow setShadowOffset:NSMakeSize(3.0, -3.0)]; 
			[theShadow setShadowBlurRadius:3.0]; 
			
			// Use a partially transparent color for shapes that overlap.
			[theShadow setShadowColor:[[NSColor blackColor]
				 colorWithAlphaComponent:0.3]]; 
			
			[theShadow set];
		}
		// Draw.
		
		
        if(!image){
            [self setUpImage];
        }
        if(image){
			NSImage* imageToDraw;
			if([self highlighted])imageToDraw = highlightedImage;
			else imageToDraw = image;
			
			NSRect sourceRect = NSMakeRect(0,0,[imageToDraw size].width,[imageToDraw size].height);
			[imageToDraw drawAtPoint:frame.origin fromRect:sourceRect operation:NSCompositeSourceOver fraction:aTransparency];
            
        }
        else {
            //no icon so fake it with just a square
            if([self highlighted]){
                [[NSColor redColor]set];
            }
            else {
                [[NSColor blueColor]set];
            }
            NSFrameRect(frame);
            NSAttributedString* s = [[NSAttributedString alloc] initWithString:@"No Icon"];
            [s drawAtPoint:frame.origin];
            [s release];
        }
        
		if([self guardian]){
			[NSGraphicsContext restoreGraphicsState];
			[theShadow release]; 
		}        
   }
	[self drawConnections:aRect withTransparency:aTransparency];
		

}

- (void) drawConnections:(NSRect)aRect withTransparency:(float)aTransparency
{
    
    NSEnumerator *enumerator = [connectors keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        id aConnector = [connectors objectForKey:key];
        [aConnector drawSelf:aRect withTransparency:aTransparency];
        if(![self skipConnectionDraw]){
            [aConnector drawConnection:aRect];
        }
    }
}



- (void) drawImageAtOffset:(NSPoint)anOffset withTransparency:(float)aTransparency
{
    BOOL saveState = [self highlighted];
    NSRect oldFrame = frame;
    NSRect aFrame = frame;
    aFrame.origin.x += anOffset.x;
    aFrame.origin.y += anOffset.y;
    [self setFrame:aFrame];
    [self setHighlighted:NO];
    [self setSkipConnectionDraw:YES];
    [self drawSelf:frame withTransparency:aTransparency];
    [self setSkipConnectionDraw:NO];
    [self setOffset:NSMakePoint(frame.origin.x,frame.origin.y)];
    [self setFrame:oldFrame];
    
    [self setHighlighted:saveState];
}


#pragma mark ¥¥¥Mouse Events

- (void) doDoubleClick:(id)sender
{
    [self showMainInterface];
}

- (void) doCmdClick:(id)sender
{
}

- (ORConnector*) requestsConnection: (NSPoint)aPoint
{
	ORConnector* theConnector = [self connectorAt:aPoint];
    if(![theConnector hidden])return theConnector;
	else return nil;
}


- (NSImage*)image
{
    return image;
}


#pragma mark ¥¥¥Archival
static NSString *OROrcaObjectFrame		= @"OROrcaObject Frame";
static NSString *OROrcaObjectOffset 		= @"OROrcaObject Offset";
static NSString *OROrcaObjectBounds 		= @"OROrcaObject Bounds";
static NSString *OROrcaObjectConnectors		= @"OROrcaOjbect Connectors";
static NSString *OROrcaObjectTag            = @"OROrcaOjbect Tag";
static NSString* OROrcaObjectUniqueIDNumber = @"OROrcaObjectUniqueIDNumber";
//static NSString *OROrcaObjectLocks		= @"OROrcaObject Locks";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setFrame:[[decoder decodeObjectForKey:OROrcaObjectFrame] rectValue]];
    [self setOffset:[[decoder decodeObjectForKey:OROrcaObjectOffset] pointValue]];
    [self setBounds:[[decoder decodeObjectForKey:OROrcaObjectBounds] rectValue]];
    [self setConnectors:[decoder decodeObjectForKey:OROrcaObjectConnectors]];
    [self setTag:[decoder decodeIntForKey:OROrcaObjectTag]];
    [self setUniqueIdNumber:[decoder decodeInt32ForKey:OROrcaObjectUniqueIDNumber]];
    miscAttributes = [[decoder decodeObjectForKey:@"miscAttributes"] retain];
	
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:[NSData dataWithNSRect:[self frame]] forKey:OROrcaObjectFrame];
    [encoder encodeObject:[NSData dataWithNSPoint:[self offset]] forKey:OROrcaObjectOffset];
    [encoder encodeObject:[NSData dataWithNSRect:[self bounds]] forKey:OROrcaObjectBounds];
    [encoder encodeObject:connectors forKey:OROrcaObjectConnectors];
    [encoder encodeInt:[self tag] forKey:OROrcaObjectTag];
    [encoder encodeInt32:uniqueIdNumber forKey:OROrcaObjectUniqueIDNumber];
	[encoder encodeObject:miscAttributes forKey:@"miscAttributes"];
}

- (void) awakeAfterDocumentLoaded
{
}

#pragma mark ¥¥¥General

- (void) setHighlightedYES
{
    [self setHighlighted:YES];
}

- (void) setHighlightedNO
{
    [self setHighlighted:NO];
}

- (void) resetAlreadyVisitedInChainSearch
{
	alreadyVisitedInChainSearch = NO;
}

- (BOOL) isObjectInConnectionChain:(id)anObject
{
	if(alreadyVisitedInChainSearch) return NO;
	else alreadyVisitedInChainSearch = YES;
	
	BOOL result = NO;
    NSEnumerator *enumerator = [connectors keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        ORConnector* aConnector = [connectors objectForKey:key];
		result |= [[aConnector objectLink] isObjectInConnectionChain:anObject];
    }
	
	return result;
}

- (NSArray*) collectObjectsOfClass:(Class)aClass
{
    if([self isKindOfClass:aClass]){
        return [NSArray arrayWithObject:self];
    }
    else return nil;
}

- (BOOL) loopChecked
{
	return loopChecked;
}

- (void) setLoopChecked:(BOOL)aFlag
{
	loopChecked = aFlag;
}
- (void) clearLoopChecked
{
	loopChecked = NO;
}

- (NSArray*) collectConnectedObjectsOfClass:(Class)aClass
{
    NSMutableArray* collection = [NSMutableArray arrayWithCapacity:256];
	[self setLoopChecked:YES];
	NSEnumerator* e = [connectors objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		id connectedObject = [obj connectedObject];
		if(![connectedObject loopChecked]){
			[connectedObject setLoopChecked:YES];
			if([self isKindOfClass:aClass]){
				[collection addObject:self];
			}
			[collection addObjectsFromArray:[connectedObject collectConnectedObjectsOfClass:aClass]];
		}
	}
	return collection;
}



- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    //subclass responsibility
    return nil;
}


- (NSArray*) collectObjectsConformingTo:(Protocol*)aProtocol
{
    if([self conformsToProtocol:aProtocol]){
        return [NSArray arrayWithObject:self];
    }
    else return nil;
}

- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector
{
    if([self respondsToSelector:aSelector]){
        return [NSArray arrayWithObject:self];
    }
    else return nil;
}

- (NSArray*) subObjectsThatMayHaveDialogs
{
	//subclasses can override as needed.
	return nil;
}


- (id) findObjectWithFullID:(NSString*)aFullID;
{
    if([aFullID isEqualToString:[self fullID]])return self;
    else return nil;
}


#pragma mark ¥¥¥Methods To Override
- (void) setUpImage
{
    [self setImage:nil];
    //subclasses will override. DON'T call super
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return  [aGuardian isMemberOfClass:NSClassFromString(@"ORGroup")]           || 
	[aGuardian isMemberOfClass:NSClassFromString(@"ORContainerModel")];
}


- (BOOL) solitaryObject
{
    return NO;
}

- (NSMutableDictionary*) miscAttributesForKey:(NSString*)aKey
{
	return [miscAttributes objectForKey:aKey];
}

- (void) setMiscAttributes:(NSMutableDictionary*)someAttributes forKey:(NSString*)aKey
{

	if(!miscAttributes)  miscAttributes = [[NSMutableDictionary alloc] init];
	
	NSMutableDictionary* oldAttrib = [miscAttributes objectForKey:aKey];
	if(oldAttrib){
		[[[self undoManager] prepareWithInvocationTarget:self] setMiscAttributes:[[oldAttrib copy] autorelease] forKey:aKey];
	}
	[miscAttributes setObject:someAttributes forKey:aKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMiscAttributesChanged 
														object:self
														userInfo:[NSDictionary dictionaryWithObject:aKey forKey:ORMiscAttributeKey]];    
}


#pragma mark ¥¥¥Connection Management

- (id) objectConnectedTo:(id)aConnectorName
{
    return [[[connectors objectForKey:aConnectorName] connector] objectLink];
}

- (id) connectorOn:(id)aConnectorName
{
    return [[connectors objectForKey:aConnectorName] connector];
}


- (id) connectorAt:(NSPoint)aPoint
{
    NSEnumerator *enumerator = [connectors keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        ORConnector* aConnector = [connectors objectForKey:key];
        if([aConnector pointInRect:aPoint])return aConnector;
    }
    return nil;
}

- (void) disconnect
{
    NSEnumerator *enumerator = [connectors keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        ORConnector* aConnector = [connectors objectForKey:key];
        [aConnector disconnect];
    }
}


- (void) removeConnectorForKey:(NSString*)key
{
    if(key){
        [[connectors objectForKey:key] disconnect];
        [connectors removeObjectForKey:key];
    }
}


- (void) connectionChanged
{
    //do nothing , subclasses can override
}

- (void) assumeDisplayOf:(ORConnector*)aConnector
{
    //remove all entries of aConnector and add aConnector back in under a new key.
    NSEnumerator *e = [[connectors allKeys] objectEnumerator];
    id key;
    while ((key = [e nextObject])) {
        if([connectors objectForKey:key] == aConnector)return;
    }
    if(aConnector){
        //find name not being used
        int index = 0;
        NSString* unusedKey;
        for(;;){
            unusedKey = [NSString stringWithFormat:@"OwnedConnection_%d",index];
            if([connectors objectForKey:unusedKey]){
                index++;
            }
            else break;
        }
        [connectors setObject: aConnector forKey:unusedKey];
        [aConnector setGuardian:self];
    }
}

- (void) removeDisplayOf:(ORConnector*)aConnector
{
    NSEnumerator *e = [[connectors allKeys] objectEnumerator];
    id key;
    while ((key = [e nextObject])) {
        if([connectors objectForKey:key] == aConnector){
            [aConnector disconnect];
            [connectors removeObjectForKey:key];
            [aConnector setGuardian:nil];
            break;
        }
    }    
}

- (void) postWarning:(NSString*)warningString
{
    [[NSNotificationCenter defaultCenter] 
		postNotificationName:ORWarningPosted 
					object:self 
					userInfo:[NSDictionary dictionaryWithObjectsAndKeys:warningString,@"WarningMessage",nil]];
}
@end

@implementation OrcaObject (cardSupport)
- (short) numberSlotsUsed
{
	return 0;
}
@end

@implementation OrcaObject (scriptingAdditions)
//this is just to help with the scriting stuff
- (long) longValue
{
	return 1;
}
@end

@implementation NSObject (OrcaObject_Catagory)
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)aDataPacket forChannel:(int)aChannel
{
    //subclasses will override.
    return nil;
}


- (void) runTaskBoundary:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
}


- (void) makeConnectors
{
    //subclasses will override.
}
- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
    //subclasses will override.
}
@end

