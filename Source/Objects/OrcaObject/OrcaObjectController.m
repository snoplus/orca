//
//  OrcaObjectController.m
//  Orca
//
//  Created by Mark Howe on Sun Dec 08 2002.
//  Copyright © 2002 CENPA, Univsersity of Washington. All rights reserved.
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
#import "ORTimedTextField.h"

NSString* ORModelChangedNotification = @"ORModelChangedNotification";

@implementation OrcaObjectController

#pragma mark ¥¥¥Initialization
- (id) initWithWindowNibName:(NSString*)aNibName
{
    if(self = [super initWithWindowNibName:aNibName]){
        [self setWindowFrameAutosaveName:aNibName];
		[self setShouldCloseDocument:NO];
    }
    return self;
}

- (void) dealloc
{
	[[self window] close];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self registerNotificationObservers];
    [self updateWindow];	
}

- (void) close
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self setModel:nil];
	[[self window] close];
}

#pragma mark ¥¥¥Undo Management
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [model undoManager];
}

#pragma mark ¥¥¥Accessors
- (id)model
{
	return model;
}

- (void) setModel:(id)aModel
{
    
    if(aModel!=model){
        id oldModel = model;
        model =  aModel;
        if(oldModel!=nil){
            // [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:self];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:oldModel];
            if(model){
				[self registerNotificationObservers];
				[self updateWindow];
            }
			[[NSNotificationCenter defaultCenter]
			 postNotificationName:ORModelChangedNotification
			 object: self 
			 userInfo: nil];
        }
    }
}

#pragma mark ¥¥¥Notifications
- (void) documentClosing:(NSNotification*)aNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];	
	[[self window] close];
}

#pragma mark ¥¥¥Messages From Delegate
- (BOOL)windowShouldClose:(id)sender
{
    return YES;
}

#pragma mark ¥¥¥Interface Management

- (void) isNowKeyWindow:(NSNotification*)aNotification
{
	//do nothing... subclassed can override
}


- (void) endAllEditing:(NSNotification*)aNotification
{
	[self endEditing];
}

- (void) endEditing
{
	//commit all text editing... subclasses should call before doing their work.
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[notifyCenter removeObserver:self];
	
    [notifyCenter addObserver : self
                     selector : @selector(securityStateChanged:)
                         name : ORGlobalSecurityStateChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(documentClosing:)
                         name : ORDocumentClosedNotification
                       object : nil];
	
//    [notifyCenter addObserver : self
//                     selector : @selector(endAllEditing:)
//                         name : NSWindowDidResignKeyNotification
//                       object : [self window]];
	
    [notifyCenter addObserver : self
                     selector : @selector(isNowKeyWindow:)
                         name : NSWindowDidBecomeKeyNotification
                       object : [self window]];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(uniqueIDChanged:)
                         name : ORIDChangedNotification
                       object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(warningPosted:)
						 name : ORWarningPosted
					   object : model];
	
	
}


- (void)flagsChanged:(NSEvent*)inEvent
{
	[[self window] resetCursorRects];
}

- (void) warningPosted:(NSNotification*)aNotification
{
	[warningField setStringValue:[[aNotification userInfo] objectForKey:@"WarningMessage"]];
}

- (void) uniqueIDChanged:(NSNotification*)aNotification
{
    //subclasses should override as needed.
}
- (void) securityStateChanged:(NSNotification*)aNotification
{
    [self checkGlobalSecurity];
}

- (void) checkGlobalSecurity
{
    //subclasses should override as needed.
}

- (void) updateWindow
{
    [self securityStateChanged:nil];
}

- (NSUndoManager*) undoManager
{
	return [model undoManager];
}

- (NSArray*) collectObjectsOfClass:(Class)aClass
{
	return [[[NSApp delegate] document] collectObjectsOfClass:aClass];
}

- (NSArray*) collectObjectsConformingTo:(Protocol*)aProtocol
{
	return [[[NSApp delegate] document] collectObjectsConformingTo:aProtocol];
}


#pragma mark INTERFACE MANAGEMENT - Generic updaters

- (void) incModelSortedBy:(SEL)aSelector
{
	[self endEditing];
	NSMutableArray* allModels = [[[[NSApp delegate] document] collectObjectsOfClass:[model class]] mutableCopy];
	[allModels sortUsingSelector:aSelector];
	int index = [allModels indexOfObject:model] + 1;
	if(index>[allModels count]-1) index = 0;
	[self setModel:[allModels objectAtIndex:index]];
 	[allModels release];
}

- (void) decModelSortedBy:(SEL)aSelector
{
	[self endEditing];
	NSMutableArray* allModels = [[[[NSApp delegate] document] collectObjectsOfClass:[model class]] mutableCopy];
	[allModels sortUsingSelector:aSelector];
	int index = [allModels indexOfObject:model] - 1;
	if(index<0) index = [allModels count]-1;
	[self setModel:[allModels objectAtIndex:index]];
 	[allModels release];
}

- (void)updateTwoStateCheckbox:(NSButton *)control setting:(BOOL)value
{ 
    if (value != [control state]) {
        [control setState:(value ? NSOnState : NSOffState)];
    }
}

- (void)updateMixedStateCheckbox:(NSButton *)control setting:(int)inValue
{ 
	// The inValue parameter must be one of NSOnState, NSOffState, or NSMixedState.
    if (inValue != [control state]) {
        [control setState:inValue];
    }
}

- (void)updateRadioCluster:(NSMatrix *)control setting:(int)inValue
{ 
	// The inValue parameter must be an integer.
    if (inValue != [control selectedTag]) {
        [control selectCellWithTag:inValue];
    }
}

- (void)updatePopUpButton:(NSPopUpButton *)control setting:(int)inValue
{
	// Updates a pop-up button. The inValue parameter must be an integer.
    if (inValue != [control indexOfSelectedItem]) {
        [control selectItemAtIndex:inValue];
    }
}

- (void)updateSlider:(NSSlider *)control setting:(int)inValue
{ 
	// Updates a slider. The inValue parameter must be a int.
    if (inValue != [control intValue]) {
        [control setIntValue:inValue];
    }
}

- (void)updateStepper:(NSStepper *)control setting:(int)inValue
{
	// Updates a slider. The inValue parameter must be a int.
    if (inValue != [control intValue]) {
        [control setIntValue:inValue];
    }
}
- (void)updateIntText:(NSTextField *)control setting:(int)inValue
{
	// Updates a slider. The inValue parameter must be a int.
    if (inValue != [control intValue]) {
        [control setIntValue:inValue];
    }
}

- (void)resizeWindowToSize:(NSSize)newSize
{
    NSRect aFrame;
    
    float newHeight = newSize.height;
    float newWidth = newSize.width;
    
    aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] 
                                     styleMask:[[self window] styleMask]];
    
    aFrame.origin.y += aFrame.size.height;
    aFrame.origin.y -= newHeight;
    aFrame.size.height = newHeight;
    aFrame.size.width = newWidth;
    
    aFrame = [NSWindow frameRectForContentRect:aFrame 
                                     styleMask:[[self window] styleMask]];
    
    [[self window] setFrame:aFrame display:YES animate:YES];
}

- (NSMutableDictionary*) miscAttributesForKey:(NSString*)aKey
{
	return [model miscAttributesForKey:aKey];
}

- (void) setMiscAttributes:(NSMutableDictionary*)someAttributes forKey:(NSString*)aKey
{
	[model setMiscAttributes:someAttributes forKey:aKey];
}


#pragma mark ¥¥¥Archival

static NSString *OROrcaObjectControllerFrame 	= @"OROrcaObjectControllerFrame";
static NSString *OROrcaObjectControllerModel	= @"OROrcaObjectControllerModel";
static NSString *OROrcaObjectControllerNibName	= @"OROrcaObjectControllerNibName";

- (id)initWithCoder:(NSCoder*)decoder
{
    NSString* nibName = @"??";
    @try {
        nibName = [decoder decodeObjectForKey:OROrcaObjectControllerNibName];
        self = [super initWithWindowNibName:nibName];
        [self setWindowFrameAutosaveName:nibName];
        [self setModel:[decoder decodeObjectForKey:OROrcaObjectControllerModel]];
        [[self window] setFrameFromString:[decoder decodeObjectForKey:OROrcaObjectControllerFrame]];
	}
	@catch(NSException* localException) {
        NSLog(@"Failed loading: %@\n",nibName);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:[self windowNibName] forKey:OROrcaObjectControllerNibName];
    [super encodeWithCoder:encoder];
    [encoder encodeObject:model forKey:OROrcaObjectControllerModel];
    [encoder encodeObject:[[self window] stringWithSavedFrame] forKey:OROrcaObjectControllerFrame];
    
}

#pragma mark ¥¥¥Actions
- (IBAction) copy:(id)sender
{
	[[[NSApp delegate] document] duplicateDialog:self];
}


- (IBAction) incDialog:(id)sender
{
	NSArray* models = [self collectObjectsOfClass:[model class]];
	if([models count]>1){
		NSEnumerator* e = [models objectEnumerator];
		id obj;
		while(obj = [e nextObject]){
			if(obj == model){
				obj = [e nextObject];
				if(obj)[self setModel:obj];
				else [self setModel:[models objectAtIndex:0]];
			}
		}
	}
}

- (IBAction) decDialog:(id)sender
{
	NSArray* models = [self collectObjectsOfClass:[model class]];
	if([models count]>1){
		NSEnumerator* e = [models reverseObjectEnumerator];
		id obj;
		while(obj = [e nextObject]){
			if(obj == model){
				obj = [e nextObject];
				if(obj)[self setModel:obj];
				else [self setModel:[models lastObject]];
			}
		}
	}
}



- (IBAction) saveDocument:(id)sender
{
    [[model document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[model document] saveDocumentAs:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	NSArray* models = [self collectObjectsOfClass:[model class]];
    if ([menuItem action] == @selector(decDialog:)) {
		return [models count] > 1;
	}
    else if ([menuItem action] == @selector(incDialog:)) {
		return [models count] > 1;
    }
	else return YES;
}

@end

