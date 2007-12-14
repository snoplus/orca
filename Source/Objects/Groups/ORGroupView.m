//
//  ORGroupView.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 27, 2002.
//  Copyright  © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORSelectionTask.h"
#import "ORConnectionTask.h"
#import "ORScaleTask.h"
#import "ORReadOutList.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "CTGradient.h"

@interface ORGroupView (ExperimentViewPrivateMethods)
- (BOOL) _canTakeValueFromPasteboard:(NSPasteboard *)pb;
- (void) _startDrag:(NSEvent*)event;
- (BOOL) _doDragOp:(NSString *)op atPoint:(NSPoint)aPoint;
@end


@implementation ORGroupView

#pragma mark ¥¥¥Initialization
- (id)initWithFrame:(NSRect)frame {
    NSArray *typeArray;
    self = [super initWithFrame:frame];
    if (self) {       
        typeArray = [NSArray arrayWithObject:ORObjArrayPtrPBType];
        [self registerForDraggedTypes:typeArray];
        dragSessionInProgress = NO;
        goodObjectsInDrag = NO;
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter  defaultCenter] removeObserver:self];
    [self setBackgroundColor:nil];
    [mouseTask release];
    [super dealloc];
}

- (void) awakeFromNib
{
    NSColor* color = colorForData([[NSUserDefaults standardUserDefaults] objectForKey: ORBackgroundColor]);
    [self setBackgroundColor:(color!=nil?color:[NSColor whiteColor])];
    
    NSNotificationCenter* defaultCenter = [NSNotificationCenter  defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(backgroundColorChanged:)
                          name:ORBackgroundColorChangedNotification
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(lineColorChanged:)
                          name:ORLineColorChangedNotification
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(lineTypeChanged:)
                          name:ORLineTypeChangedNotification
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(contentSizeChanged:)
                          name:ORGroupObjectsAdded
                        object:group];
    
    [defaultCenter addObserver:self
                      selector:@selector(contentSizeChanged:)
                          name:ORGroupObjectsRemoved
                        object:group];
    
    [defaultCenter addObserver:self
                      selector:@selector(contentSizeChanged:)
                          name:OROrcaObjectMoved
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(imageChanged:)
                          name:OROrcaObjectImageChanged
                        object:nil];
    
    
    [self backgroundColorChanged:nil];
    [self setNeedsDisplay:YES];
}

#pragma mark ¥¥¥Accessors
- (void) setGroup:(ORGroup*)aModel
{
    group = aModel;
}

- (ORGroup*) group
{
    return group;
}

- (NSColor*) backgroundColor
{
    return backgroundColor;
}

- (void) setBackgroundColor:(NSColor*)aColor
{
    [aColor retain];
    [backgroundColor release];
    backgroundColor = aColor;
    [self setNeedsDisplay:YES];
}

- (NSEnumerator*) objectEnumerator
{
    return [group objectEnumerator];
}

#pragma mark ¥¥¥Graphics

- (void) drawBackground:(NSRect)aRect
{
	NSRect bounds = [self bounds];
	float red,green,blue,alpha;
	NSColor* color = [[self backgroundColor] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	[color getRed:&red green:&green blue:&blue alpha:&alpha];

	red *= .75;
	green *= .75;
	blue *= .75;
	//alpha = .75;

	NSColor* endingColor = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];

	CTGradient* gradient = [CTGradient gradientWithBeginningColor:color endingColor:endingColor];

	[gradient fillRect:bounds angle:270.];

}

- (void)drawRect:(NSRect)rect
{
	[self drawBackground:rect];
    [self drawContents:rect];
    [mouseTask drawRect:rect];
}

- (void) drawContents:(NSRect)aRect
{

    [group drawContents:aRect];	
}

- (BOOL) isOpaque
{
    return NO;
}

//-------------------------------------------------------------------------------
// backgroundColorChanged
// invoded when the preference panel announces a background color change.
//-------------------------------------------------------------------------------
-(void)backgroundColorChanged:(NSNotification*)note
{
    NSUserDefaults* 	defaults;
    NSData*		colorAsData;
    defaults 	= [NSUserDefaults standardUserDefaults];
    colorAsData = [defaults objectForKey: ORBackgroundColor];
    [self setBackgroundColor:colorForData(colorAsData)];
    NSScrollView*   sv = [self enclosingScrollView];
    [sv setDrawsBackground:YES];
    [sv setBackgroundColor:[self backgroundColor]];
}

- (void)lineColorChanged:(NSNotification*)note
{
    [self setNeedsDisplay:YES];
}

- (void)lineTypeChanged:(NSNotification*)note
{
    [self setNeedsDisplay:YES];
}

- (void) imageChanged:(NSNotification*)note
{
    if(note == nil || (ORGroup*)[[note object] guardian] == group){
        [self setNeedsDisplay:YES];
    }
}

- (void) contentSizeChanged:(NSNotification*)note
{
    if(note == nil || (ORGroup*)[note object] == group || (ORGroup*)[[note object] guardian] == group){
        float scaleFactor = [self scalePercent]/100.;
        NSRect  box = [group rectEnclosingObjects:[group orcaObjects]];
        box.size.width *= scaleFactor;
        box.size.height *= scaleFactor;
        
        NSScrollView*   sv = [self enclosingScrollView];
        NSRect          svRect = [[sv contentView]frame];
        
        int x = box.origin.x;//*scaleFactor;
            int y = box.origin.y;//*scaleFactor;
                
                if(x<0 || y<0){
                    //origins must be 0,0 so we have to do a bit of adjustment here
                    if(x<0){
                        box.origin.x = 0;
                        box.size.width += fabs(x) * scaleFactor;
                    }
                    if(y<0){
                        box.origin.y = 0;
                        box.size.height += fabs(y) * scaleFactor;
                    }
                    NSEnumerator* e = [[group orcaObjects] objectEnumerator];
                    OrcaObject* obj;
                    while(obj = [e nextObject]){
                        NSRect aFrame = [obj frame];
                        if(x<0)aFrame.origin.x += fabs(x);
                        if(y<0)aFrame.origin.y += fabs(y);
                        [obj setFrame:aFrame];
                    }
                    
                    svRect = [[sv contentView]frame];
                    svRect.size.width *= scaleFactor;
                    svRect.size.height *= scaleFactor;
                    
                    box = [group rectEnclosingObjects:[group orcaObjects]];
                    box.size.width *= scaleFactor;
                    box.size.height *= scaleFactor;
                }
                
                box = NSUnionRect(box,svRect);
                [self setFrame:box];
                
    }
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize
{
    [super resizeWithOldSuperviewSize:oldSize];
    [self contentSizeChanged:nil];
}

- (NSRect) resizeView:(NSRect)aNewRect
{
    float dx = aNewRect.origin.x;
    float dy = aNewRect.origin.y;
    NSRect newRect = aNewRect;
    newRect.origin.x = 0;
    newRect.origin.y = 0;
    newRect.size.width += dx;
    newRect.size.height += dy;
    
    return newRect;
}

- (NSRect) normalized
{
    float scaleFactor = [self scalePercent]/100.;
    NSRect  box = [group rectEnclosingObjects:[group orcaObjects]];
	
	NSRect windowFrame = [[self window] frame];
    NSScrollView*   sv = [self enclosingScrollView];
	NSRect viewFrame   = [[sv contentView]  frame];
    
	float verticalSpace   = windowFrame.size.height - viewFrame.size.height;
	float horizontalSpace = windowFrame.size.width - viewFrame.size.width;
	
    int x = box.origin.x - 20;
    int y = box.origin.y - 20;
	
    NSEnumerator* e = [[group orcaObjects] objectEnumerator];
    OrcaObject* obj;
    while(obj = [e nextObject]){
        NSRect aFrame = [obj frame];
        aFrame.origin.x -= fabs(x);
        aFrame.origin.y -= fabs(y);
        [obj setFrame:aFrame];
    }
    
    box = [group rectEnclosingObjects:[group orcaObjects]];
    box.origin.x = 0;
    box.origin.y = 0;
    box.size.width += 40;
    box.size.height += 40;
    box.size.width *= scaleFactor;
    box.size.height *= scaleFactor;
    
    [self setFrame:box];
    
	NSSize minSize = [[self window] minSize];
	windowFrame.size.width  = MAX(box.size.width+horizontalSpace,minSize.width);
	windowFrame.size.height = MAX(box.size.height+verticalSpace,minSize.height);
	
	[self setNeedsDisplay:YES];
	
	return windowFrame;
}

#pragma mark ¥¥¥Mouse Events
- (void)mouseDown:(NSEvent*)event
{
    [[self window] makeFirstResponder:self];
    
    BOOL shiftKeyDown = ([event modifierFlags] & NSShiftKeyMask)!=0;
    BOOL cmdKeyDown   = ([event modifierFlags] & NSCommandKeyMask)!=0;
    BOOL cntrlKeyDown = ([event modifierFlags] & NSControlKeyMask)!=0;
	
    NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    
    NSEnumerator* e  = [[group orcaObjects] reverseObjectEnumerator];
    OrcaObject* obj1;
    OrcaObject* obj2;
    BOOL somethingHit 			= NO;
    ORConnector* connectorRequestingConnection = nil;
    BOOL hitObjectHighlighted;
	if(!cntrlKeyDown){
		while (obj1 = [e nextObject]) {                     //loop thru all icons
			if(![obj1 selectionAllowed]){
				if([event clickCount]>=2){
					[obj1 doDoubleClick:obj1];
				}                
				continue;
			}
			if( NSPointInRect(localPoint,[obj1 frame])){    //obj1 is hit?
				if(!cmdKeyDown){
					somethingHit = YES;
					connectorRequestingConnection = [obj1 requestsConnection:localPoint];
					if(connectorRequestingConnection == nil){
						//obj1 has been clicked on
						hitObjectHighlighted = [obj1 highlighted];
						if(shiftKeyDown){ 					//shift key down so..
							[obj1 setHighlighted:![obj1 highlighted]];		//flip the highlight state
						}
						else [obj1 setHighlighted:YES];                         //shift key NOT down so highligth
																				//[self setNeedsDisplayInRect:[obj1 frame]];
						[self setNeedsDisplay:YES];
						
						//next handle the response of the other objects
						if(!shiftKeyDown){                                      //shift key NOT down
							e  = [[group orcaObjects] objectEnumerator];
							while (obj2 = [e nextObject]){			//loop thru all icons
								if(obj2 != obj1 && !hitObjectHighlighted){	//skip the obj1 and if obj1 was NOT highlighted...
									[obj2 setHighlighted:NO];			//unhighlight obj2
								}
							}
						}
						
						if([event clickCount]>=2){
							[[group allSelectedObjects] makeObjectsPerformSelector:@selector(doDoubleClick:) withObject:self];
						}                
					}
					break;
				}
				else {
					[obj1 setHighlighted:NO]; 
					[obj1 doCmdClick:obj1];
				}
			}      
		}
    }
    //something else must be done..
    if(!somethingHit){
		id theMouseTask;
		if(cntrlKeyDown){
			theMouseTask = [ORScaleTask getTaskForEvent:event inView:self];
		}
		else {
			[self clearSelections:shiftKeyDown];
			theMouseTask = [ORSelectionTask getTaskForEvent:event inView:self];
		}
		[self setMouseTask:theMouseTask];
        [[self mouseTask] mouseDown:event];
        
    }
    else if(connectorRequestingConnection != nil && [group changesAllowed]){
        id theTask = [ORConnectionTask getTaskForEvent:event inView:self];
        [self setMouseTask:theTask];
        [[self mouseTask] mouseDown:event];
        if([connectorRequestingConnection connector] != nil) {
            [[self mouseTask] setStartLoc: [[connectorRequestingConnection connector]centerPoint]];
            [[self mouseTask] setCurrentLoc:[self convertPoint:[event locationInWindow] fromView:nil]];
            [connectorRequestingConnection disconnect];
        }
    }
    //[self setNeedsDisplay:YES];
}

//-------------------------------------------------------------------------------
// mouseDragged
// Handle a mouse dragged event. If a selection drag is in progress, handle the
// selection/deselection of icons as they enter/leave the selection rect. Otherwise
// start a drag of any selected objects.
//-------------------------------------------------------------------------------
- (void)mouseDragged:(NSEvent *)event
{
    if(mouseTask){
        [mouseTask mouseDragged:event];       
    }
    else if([group changesAllowed]){
        [self _startDrag:event];
    }
}

//-------------------------------------------------------------------------------
// mouseUp
// Handle a mouse up event. Just terminate any selection drag in progress and mark
// the display for update.
//-------------------------------------------------------------------------------
- (void)mouseUp:(NSEvent *)event
{
    [mouseTask mouseUp:event];
    [self setMouseTask:nil];        
    //[self setNeedsDisplay:YES];
}


//-------------------------------------------------------------------------------
// setMouseTask
// assign a mouse task. mouse tasks may reassign the task based on what's going on.
//-------------------------------------------------------------------------------
- (void)setMouseTask:(id)aTask
{
    if(![group changesAllowed]){
        [mouseTask release];
        mouseTask = nil;
    }
    else {
        [aTask retain];
        [mouseTask release];
        mouseTask = aTask;		
    }
}

- (id)mouseTask
{
    return mouseTask;
}

-(BOOL) acceptsFirstMouse:(NSEvent*)event
{
    return YES;
}

- (BOOL) shouldDelayWindowOrderingforEvent:(NSEvent*)theEvent
{
    return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    
    int selectedCount = [[group selectedObjects]count];
    BOOL changesAllowed = [group changesAllowed];
    if ([menuItem action] == @selector(paste:)) {
        NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
        if(!changesAllowed)return NO;
        else return [self _canTakeValueFromPasteboard:pb];
    }
    else if ([menuItem action] == @selector(copy:)) {
        if(!changesAllowed)return NO;
        else return selectedCount>0;
    }
    else if ([menuItem action] == @selector(cut:)) {
        if(!changesAllowed)return NO;
        else return selectedCount>0;
    }
    else if ([menuItem action] == @selector(delete:)) {
        if(!changesAllowed)return NO;
        else return selectedCount>0;
    }
    
    return YES;
}


- (void) clearSelections:(BOOL)shiftKeyDown
{
    [group clearSelections:shiftKeyDown];
    [self setNeedsDisplay:YES];
}

- (void) checkSelectionRect:(NSRect)aRect inView:(NSView*)aView
{
    [group checkSelectionRect:aRect inView:aView];
}

- (void) checkRedrawRect:(NSRect)aRect inView:(NSView*)aView
{
    [group checkRedrawRect:aRect inView:aView];
}


#pragma mark ¥¥¥Actions
- (IBAction)copy:(id)sender
{
    [savedObjects release];
    savedObjects = nil;
    savedObjects = [[group selectedObjects] retain];
    
    //declare our custom type.
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:ORGroupPasteBoardItem, nil] owner:self];
    
    // the actual data doesn't matter since We're not really putting anything on the pasteboard. We are
    //using it to control the process. We save the objects locally and will provide them on request.
    [pboard setData:[NSData data] forType:ORObjArrayPtrPBType]; 
}

- (IBAction)delete:(id)sender
{
    [group removeSelectedObjects];
    [self setNeedsDisplay:YES];
}

- (IBAction)cut:(id)sender
{
    [self copy:nil];
    [group removeSelectedObjects];
    
    [self setNeedsDisplay:YES];
}

- (IBAction)paste:(id)sender
{
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    
    NSData* data = [pb dataForType:ORGroupPasteBoardItem];
    if(data) {
        [group unHighlightAll];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        id objectList = [unarchiver decodeObjectForKey:ORObjArrayPtrPBType];
        [unarchiver finishDecoding];
        [unarchiver release];
        
        NSEnumerator* e = [objectList objectEnumerator];
        NSNumber* aPointer;
        while(aPointer = [e nextObject]){
            OrcaObject* anObject = (OrcaObject*)[aPointer longValue];
            OrcaObject* newObject = [anObject copy]; 
            NSPoint newLocation =   [self suggestPasteLocationFor:newObject];
            if(newLocation.x != -1 && newLocation.y != -1){
                [self moveObject:newObject to:newLocation];
                [newObject setHighlightedYES]; 
                NSMutableArray* newObjects = [NSMutableArray array];
                [newObjects addObject:newObject];
                [group addObjects:newObjects];
            }
            [newObject release];
        }
        
        [self  copy:nil];
    }
    [self setNeedsDisplay:YES];
}


- (IBAction)selectAll:(id)sender
{
    [group highlightAll];
    [self setNeedsDisplay:YES];
}

#pragma mark ¥¥¥Drap and Drop
- (NSPoint) constrainLocation:(NSPoint)aPoint
{
    return aPoint;
}

- (NSPoint) suggestPasteLocationFor:(id)anObject
{
    NSPoint aPoint = [anObject frame].origin;
    aPoint.x += 5;
    aPoint.y += 5;
    [self constrainLocation:aPoint];
    return aPoint;
}

- (BOOL) dropPositionOK:(NSPoint)aPoint
{
    return YES;
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{	// return bitwise OR of all operations we support
    return NSDragOperationCopy | NSDragOperationMove;
}

- (BOOL)ignoreModifierKeysWhileDragging
{
    return NO;
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
    
    
    NSEnumerator* e;
    BOOL ok = YES;
    if([type isEqualToString:ORGroupPasteBoardItem])e = [savedObjects objectEnumerator];
    else if([type isEqualToString:ORGroupDragBoardItem])e = [draggedObjects objectEnumerator];
    else ok = NO;
    
    if(ok){
        //load the saved objects pointers into the paste board.
        NSMutableArray* pointerArray = [NSMutableArray array];
        id obj;
        while(obj = [e nextObject]){
            [pointerArray addObject:[NSNumber numberWithLong:(unsigned long)obj]];
        }
        
        NSMutableData *itemData = [NSMutableData data];
        NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:itemData];
        [archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
        [archiver encodeObject:pointerArray forKey:ORObjArrayPtrPBType];
        [archiver finishEncoding];
        [archiver release];
        
        [sender setData:itemData forType:type];
    }
    
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    //check with the object(s) to make sure it can be dropped here.
    NSPasteboard *pb = [sender draggingPasteboard];
    NSData* data = [pb dataForType:ORGroupDragBoardItem];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    id obj = [unarchiver decodeObjectForKey:ORObjArrayPtrPBType];
    [unarchiver finishDecoding];
    [unarchiver release];
    
    goodObjectsInDrag = YES;
    NSEnumerator* e = [obj objectEnumerator];
    NSNumber* aPointer;
    while(aPointer = [e nextObject]){
        OrcaObject* anObject = (OrcaObject*)[aPointer longValue];
        if(![anObject acceptsGuardian:group]){
            goodObjectsInDrag = NO;
            break;
        }
    }
    
    if(!goodObjectsInDrag) return NO;
    else return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    // make sure we can accept the drag.  If so, then turn on the highlight.
    NSPasteboard *pboard = [sender draggingPasteboard];
    unsigned int mask = [sender draggingSourceOperationMask];
    unsigned int ret = NSDragOperationNone;
    
    if(goodObjectsInDrag){
        
        if([sender draggingSource] != self){
            ret = NSDragOperationCopy;
        }
        else {
            if(mask == NSDragOperationCopy){ 			//option key down so..
                if ([[pboard types] indexOfObject:ORGroupDragBoardItem] != NSNotFound) {
                    ret = NSDragOperationCopy;
                }
            }
            else {
                if ([[pboard types] indexOfObject:ORGroupDragBoardItem] != NSNotFound) {
                    ret = NSDragOperationMove;
                }
            }
            if (ret != NSDragOperationNone) {
                dragSessionInProgress = YES;
            }
            
        }
    }
    return ret;
    
}


- (void)draggingExited:(id <NSDraggingInfo>)sender
{	// turn off highlight if mouse not overhead anymore
    dragSessionInProgress = NO;
    goodObjectsInDrag = NO;
    [self setNeedsDisplay:YES];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{	// no prep needed, but we do want to proceed...
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPoint localImagePoint = [self convertPoint:[sender draggedImageLocation] fromView:nil];
    localImagePoint = [self constrainLocation:localImagePoint];
    if([sender draggingSourceOperationMask] == NSDragOperationCopy){
        return [self _doDragOp:@"drop" atPoint:localImagePoint];
    }
    else return [self _doDragOp:@"move" atPoint:localImagePoint];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{	// clean up from drag
    dragSessionInProgress = NO;
    goodObjectsInDrag = NO;
    [self setNeedsDisplay:YES];
}

- (void) moveObject:(id)obj to:(NSPoint)aPoint
{
    [obj moveTo:aPoint];
}

#pragma mark ¥¥¥Connection Management
-(void)doConnectionFrom:(NSPoint)pt1 to:(NSPoint)pt2
{
    ORConnector* c1 = nil;
    ORConnector* c2 = nil;
    
    //get connector at pt1
    NSEnumerator* e  = [[group orcaObjects] reverseObjectEnumerator];
    OrcaObject* anObject;
    while (anObject = [e nextObject]) {
        if(c1 = [anObject connectorAt:pt1])break;
    }
    
    if(c1!= nil){
        e  = [[group orcaObjects] reverseObjectEnumerator];
        while (anObject = [e nextObject]) {
            if(c2 = [anObject connectorAt:pt2])break;
        }
    }
    
    [c1 connectTo:c2];
    
}

- (BOOL) canAddObject:(id) obj atPoint:(NSPoint)aPoint
{
    return YES; 
}

- (id) dataSource
{
    return self;
}

- (NSArray*)draggedNodes
{ 
    return draggedNodes; 
}
- (void) dragDone
{
    [draggedNodes release];
    draggedNodes = nil;
}

- (void)keyDown:(NSEvent *)event
{
	NSString *input = [event characters];

	if([input isEqual:[NSString stringWithFormat:@"%C", NSUpArrowFunctionKey]]){
		[self moveSelectedObjectsUp:event];
	}
	else if([input isEqual:[NSString stringWithFormat:@"%C", NSDownArrowFunctionKey]]){
		[self moveSelectedObjectsDown:event];
	}
	else if([input isEqual:[NSString stringWithFormat:@"%C", NSLeftArrowFunctionKey]]){
		[self moveSelectedObjectsLeft:event];
	}
	else if([input isEqual:[NSString stringWithFormat:@"%C", NSRightArrowFunctionKey]]){
		[self moveSelectedObjectsRight:event];
	}
	else if([input isEqual:@"="]){
		[group changeSelectedObjectsLevel:NO];
		[self setNeedsDisplay:YES];
	}
	else if([input isEqual:@"-"]){
		[group changeSelectedObjectsLevel:YES];
		[self setNeedsDisplay:YES];
	}
	else [super keyDown:event];
}


- (void) moveSelectedObjectsUp:(NSEvent*)event
{
    BOOL shiftKeyDown = ([event modifierFlags] & NSShiftKeyMask)!=0;
	float delta = shiftKeyDown?1:5;
	[self moveSelectedObjects:NSMakePoint(0,delta)];
}


- (void) moveSelectedObjectsDown:(NSEvent*)event
{
    BOOL shiftKeyDown = ([event modifierFlags] & NSShiftKeyMask)!=0;
	float delta = shiftKeyDown?1:5;
	[self moveSelectedObjects:NSMakePoint(0,-delta)];
}

- (void) moveSelectedObjectsLeft:(NSEvent*)event
{
    BOOL shiftKeyDown = ([event modifierFlags] & NSShiftKeyMask)!=0;
	float delta = shiftKeyDown?1:5;
	[self moveSelectedObjects:NSMakePoint(-delta,0)];
}

- (void) moveSelectedObjectsRight:(NSEvent*)event
{
    BOOL shiftKeyDown = ([event modifierFlags] & NSShiftKeyMask)!=0;
	float delta = shiftKeyDown?1:5;
	[self moveSelectedObjects:NSMakePoint(delta,0)];
}

- (void) moveSelectedObjects:(NSPoint)delta
{
	NSArray* objects = [group selectedObjects];
	id obj;
	NSEnumerator* e = [objects objectEnumerator];
	while(obj = [e nextObject]){
		NSPoint p = [obj frame].origin;
		[obj moveTo:NSMakePoint(p.x+delta.x,p.y+delta.y)];
	}
}

@end

@implementation ORGroupView (private)

- (BOOL)_canTakeValueFromPasteboard:(NSPasteboard *)pb
{
    NSArray *typeArray = [NSArray arrayWithObjects:ORObjArrayPtrPBType,ORGroupPasteBoardItem,ORGroupDragBoardItem,nil];
    NSString *type = [pb availableTypeFromArray:typeArray];
    if (!type) {
        return NO;
    }
    return YES;
}


-(void)_startDrag:(NSEvent*)event
{
    NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    
    NSEnumerator* e  = [[group orcaObjects] reverseObjectEnumerator];
    OrcaObject* anObject;
    while (anObject = [e nextObject]) {								//loop thru all icons
        if( NSPointInRect(localPoint,[anObject frame])){				//icon is hit?
                        
            [NSApp preventWindowOrdering];
            
            [draggedObjects release];
            draggedObjects = nil;
            draggedObjects = [[group selectedObjects] retain];
			
		
            if([draggedObjects count]){
                				
				//declare our custom type.
                NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
                [pboard declareTypes:[NSArray arrayWithObjects:ORGroupDragBoardItem, @"ORDataTaker Drag Item",NSStringPboardType,nil] owner:self];
                
                // the actual data doesn't matter since We're not really putting anything on the pasteboard. We are
                //using it to control the process. We save the objects locally and will provide them on request.
                [pboard setData:[NSData data] forType:ORObjArrayPtrPBType]; 
                
                
                //also add the objects as readoutobjects on a per object basis so that they can be 
                //dragged into a readoutlist or a ramperlist view.
                draggedNodes = [[NSMutableArray array] retain]; 
                NSEnumerator* ee = [draggedObjects objectEnumerator];
                id o;
                while(o=[ee nextObject]){
                    if([o conformsToProtocol:@protocol(ORDataTaker)] || [o conformsToProtocol:@protocol(ORHWWizard)]){
                        ORReadOutObject* itemWrapper = [[ORReadOutObject alloc] initWithObject:o];
                        [draggedNodes addObject:itemWrapper];
                        [itemWrapper release];
                    }
					if([draggedObjects count] == 1){
						[pboard setString:[o fullID]  forType:NSStringPboardType];
					}
                }

                if([draggedNodes count] == 0){
                    [draggedNodes release];
                    draggedNodes = nil;
                }
                else {
                    [pboard setData:[NSData data] forType:@"ORDataTaker Drag Item"]; 
                    [pboard setData:[NSData data] forType:@"ORHardwareWizardItem"]; 
                }
                
                //create the image to drag and start the process.
                NSImage* theImage = [[group imageOfObjects:draggedObjects withTransparency:0.4] retain];
                NSSize theSize = [theImage size];
                if([self scalePercent] == 0) [self setScalePercent:100];
                theSize.width  *= [self scalePercent]/100.;
                theSize.height *= [self scalePercent]/100.;
                [theImage setSize:theSize];
                [self dragImage : theImage
                             at : [group originOfObjects:draggedObjects]
                         offset : NSMakeSize(0.0, 0.0)
                          event : event
                     pasteboard : pboard
                         source : self
                      slideBack : YES];
                
                [theImage release];
            }
            break;
        }
    }
}




- (BOOL)_doDragOp:(NSString *)op atPoint:(NSPoint)aPoint
{
    NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSDragPboard];
    NSData* data = [pb dataForType:ORGroupDragBoardItem];
    if(data){
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        id objectList = [unarchiver decodeObjectForKey:ORObjArrayPtrPBType];
        [unarchiver finishDecoding];
        [unarchiver release];
        
        NSEnumerator* e = [objectList objectEnumerator];
        NSNumber* aPointer;
        
        
        if(op == @"drop"){
            [group unHighlightAll];
            NSMutableArray* newObjects = [NSMutableArray array];
            while(aPointer = [e nextObject]){
                OrcaObject* anObject  = (OrcaObject*)[aPointer longValue];
                NSPoint     anOffset  = [anObject offset];
                NSPoint		newPoint  = NSMakePoint(aPoint.x + anOffset.x,aPoint.y + anOffset.y);
                BOOL okToDrop = YES;
                if([anObject solitaryObject]){
                    NSArray* existingObjects = [[[NSApp delegate]document] collectObjectsOfClass:[anObject class]];
                    if([existingObjects count]){
                        okToDrop = NO;
                        NSBeep();
                        NSLog(@"Ooops, you can not have two %@ objects in the configuration\n",NSStringFromClass([anObject class]));
                    }
                } 
                if([self canAddObject:anObject atPoint:newPoint] && okToDrop){
                    OrcaObject* newObject = [anObject copy];
                    [self moveObject:newObject to:newPoint];
                    [newObject setHighlighted:YES]; 
                    [newObjects addObject:newObject];
                    [newObject release];
                }
                else return NO;
            }
            [group addObjects:newObjects];
            return YES;
            
        }
        else if(op == @"move"){	
            while(aPointer = [e nextObject]){
                OrcaObject* anObject = (OrcaObject*)[aPointer longValue];
                NSPoint     anOffset = [anObject offset];
                NSPoint		newPoint  = NSMakePoint(aPoint.x + anOffset.x,aPoint.y + anOffset.y);
                if([self canAddObject:anObject atPoint:newPoint]){
                    [self moveObject:anObject to:NSMakePoint(aPoint.x + anOffset.x,aPoint.y + anOffset.y)];
                }
                else return NO;
            }
            return YES;
        }
    }
    return NO;
}


@end
