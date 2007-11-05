//
//  ORAxisPreferences.h
//  Orca
//
//  Created by Mark Howe on 8/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ORAxis;

@interface ORAxisPreferences : NSWindowController 
{
	ORAxis* axis;
	
	IBOutlet NSTextField* minValueField;
	IBOutlet NSTextField* maxValueField;
	IBOutlet NSTextField* labelField;
}

+ (id)  sharedAxisPreferenceController:(id) anAxis;

- (id)   initForAxis:(id)anAxis;
- (void) dealloc;
- (void) setAxis:(ORAxis*)anAxis; 

- (void) registerForNotifications;
- (void) rangeChanged:(NSNotification*) aNote;

- (IBAction) minValueAction:(id)sender;
- (IBAction) maxValueAction:(id)sender;
- (IBAction) labelAction:(id)sender;

@end
