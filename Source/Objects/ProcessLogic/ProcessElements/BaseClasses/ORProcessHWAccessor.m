//
//  ORProcessHWAccessor.m
//  Orca
//
//  Created by Mark Howe on Sat Dec 3,2005.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORProcessHWAccessor.h"
#import "ORVmeCard.h"

NSString* ORProcessHWAccessorHwObjectChangedNotification    = @"ORProcessHWAccessorHwObjectChangedNotification";
NSString* ORProcessHWAccessorBitChangedNotification         = @"ORProcessHWAccessorBitChangedNotification";
NSString* ORProcessHWAccessorHwNameChangedNotification      = @"ORProcessHWAccessorHwNameChangedNotification";
NSString* ORHWAccessLock									= @"ORHWAccessLock";

@implementation ORProcessHWAccessor 
- (id) init
{
    self = [super init];
    [self registerNotificationObservers];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [hwName release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
    [super awakeAfterDocumentLoaded];
    [self useHWObjectWithName:hwName]; 
    [self setUpImage];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];
    
    [ notifyCenter addObserver: self
                      selector: @selector( objectsRemoved: )
                          name: ORGroupObjectsRemoved
                        object: nil];
    
    [ notifyCenter addObserver: self
                      selector: @selector( objectsAdded: )
                          name: ORGroupObjectsAdded
                        object: nil];
    
    [ notifyCenter addObserver: self
                      selector: @selector( slotChanged: )
                          name: ORVmeCardSlotChangedNotification
                        object: nil];
}

- (void) setGuardian:(id)aGuardian
{
    [[self undoManager] disableUndoRegistration];
    [super setGuardian:aGuardian];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(aGuardian) {
        [self registerNotificationObservers];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessElementStateChangedNotification object:self];
    }
    else {
        [self setHwObject:nil];
    }
    [[self undoManager] enableUndoRegistration];
}

- (void) slotChanged:(NSNotification*) aNote
{
    //we have a hwName. our obj may have switch slots
    if(hwObject){
        NSArray* validObjs = [self validObjects];  
        id obj;
        NSEnumerator* e = [validObjs objectEnumerator];
        while(obj = [e nextObject]){
            if(obj == hwObject && ![hwName isEqualToString:[obj processingTitle]]){
                [self useHWObjectWithName:[obj processingTitle]];
                break;
            }
        }
    }
}

- (void) viewSource
{
	//subclasses can override
}

- (void) objectsRemoved:(NSNotification*) aNote
{
    if(hwObject && hwName){
        //we have a hwObject. make sure that our hwObj still exists
        NSArray* validObjs = [self validObjects];  
        BOOL stillExists = NO; //assume the worst
        id obj;
        NSEnumerator* e = [validObjs objectEnumerator];
        while(obj = [e nextObject]){
            if(hwObject == obj){
                stillExists = YES;
                break;
            }
        }
        if(!stillExists){
            [self setHwObject:nil];
        }
    }
}

- (void) objectsAdded:(NSNotification*) aNote
{
    if(!hwObject && hwName){
        //we have a hwName but no valid object. try to match up with on of the new objects
        NSArray* validObjs = [self validObjects];  
        id obj;
        NSEnumerator* e = [validObjs objectEnumerator];
        while(obj = [e nextObject]){
            if([hwName isEqualToString:[obj processingTitle]]){
                [self setHwObject:obj];
                break;
            }
        }
    }
}


- (NSString*) fullHwName
{
    if(hwName) return [NSString stringWithFormat:@"%@,%d",hwName,bit];
    else       return @"Not defined";
}

- (BOOL) canImageChangeWithState
{
    return YES;
}

- (NSString*) description:(NSString*)prefix
{
    NSString* s;
    s = [super description:prefix];
    if(hwName) s = [s stringByAppendingFormat:@" [%@]",[self fullHwName]];
    return s;
}


- (void) processIsStarting
{
    [super processIsStarting];
	[hwObject processIsStarting];
	if(!startOnce){
		stopOnce = NO;
		[hwObject processIsStarting];
		startOnce = YES;
	}
}

- (void) processIsStopping
{
    [super processIsStopping];
	if(!stopOnce){
		startOnce = NO;
		[hwObject processIsStopping];
		stopOnce = YES;
	}
}


- (void) addOverLay
{
    if(!guardian) return;
    
    
    
    NSImage* aCachedImage = [self image];
    NSSize theIconSize = [aCachedImage size];
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    
    if(!hwObject && hwName){
        [[NSColor redColor] set];
        float oldWidth = [NSBezierPath defaultLineWidth];
        [NSBezierPath setDefaultLineWidth:3];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0,0) toPoint:NSMakePoint(theIconSize.width,theIconSize.height)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0,theIconSize.height) toPoint:NSMakePoint(theIconSize.width,0)];
        [NSBezierPath setDefaultLineWidth:oldWidth];
    }
    
    NSString* label;
    NSFont* theFont;
    NSAttributedString* n;
    
    theFont = [NSFont messageFontOfSize:8];
    NSDictionary* attrib;
    if(hwName){
        label = [NSString stringWithFormat:@"%@,%d",hwName,bit];
        attrib = [NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName];
    }
    else {
        label = @"XXXXXXXX";
        attrib = [NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor redColor],NSForegroundColorAttributeName,nil];
        
    }
    n = [[NSAttributedString alloc] 
                    initWithString:label 
                        attributes:attrib];
    
    NSSize textSize = [n size];
    float x = theIconSize.width/2 - textSize.width/2;
    [n drawInRect:NSMakeRect(x,0,textSize.width,textSize.height)];
    [n release];
    
    
    if([self uniqueIdNumber]){
        theFont = [NSFont messageFontOfSize:9];
        n = [[NSAttributedString alloc] 
            initWithString:[NSString stringWithFormat:@"%d",[self uniqueIdNumber]] 
                attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
        
        NSSize textSize = [n size];
        [n drawInRect:NSMakeRect(0,20,textSize.width,textSize.height)];
        [n release];
    }
    
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
}

- (NSString*) hwName
{
    return hwName;
}
- (void) setHwName:(NSString*) aName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHwName:hwName];
    [hwName autorelease];
    hwName = [aName copy];
    
    [self postStateChange];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORProcessHWAccessorHwNameChangedNotification
                      object:self];
}


- (id) hwObject
{
    return hwObject;
}

- (void) setHwObject:(id) anObject
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHwObject:hwObject];
    
    hwObject = anObject;
    
    [self postStateChange];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORProcessHWAccessorHwObjectChangedNotification
                      object:self];
    
}

- (int) bit
{
    return bit;
}
- (void) setBit:(int)aBit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBit:bit];
    
    bit = aBit;
    
    [self postStateChange];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORProcessHWAccessorBitChangedNotification
                      object:self];
}


- (NSArray*) validObjects
{
    return [[self document] collectObjectsConformingTo:@protocol(ORBitProcessing)];
}

- (void) useHWObjectWithName:(NSString*)aName
{
    id objectToUse      = nil;
    NSString* nameOfObj = nil;
    NSArray* validObjs = [self validObjects];    
    if([validObjs count]){
        id obj;
        NSEnumerator* e = [validObjs objectEnumerator];
        while(obj = [e nextObject]){
            if([aName isEqualToString:[obj processingTitle]]){
                objectToUse = obj;
                nameOfObj = [obj processingTitle];
                break;
            }
        }
        [self setHwName:nameOfObj];
    }
    [self setHwObject:objectToUse];
}


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setHwName:[decoder decodeObjectForKey:@"hwName"]];
    [self setBit:[decoder decodeIntForKey:@"bit"]];
    
    [[self undoManager] enableUndoRegistration];
    
    [self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:hwName forKey:@"hwName"];
    [encoder encodeInt:bit forKey:@"bit"];
}

@end
