//
//  ORAxisPreferences.m
//  Orca
//
//  Created by Mark Howe on 8/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ORAxisPreferences.h"
#import "ORAxis.h"

static ORAxisPreferences *axisPreferencesInstance = nil;

@implementation ORAxisPreferences
+ (id)  sharedAxisPreferenceController:(id) anAxis
{
    if ( axisPreferencesInstance == nil ) {
        axisPreferencesInstance = [[self alloc] initForAxis:anAxis];
    }
	[axisPreferencesInstance performSelector:@selector(showWindow:) withObject:nil afterDelay:0];
	[axisPreferencesInstance setAxis:anAxis];
	[anAxis setPreferenceController:axisPreferencesInstance];

    return axisPreferencesInstance;
}

- (id) initForAxis:(id)anAxis;
{
     if(self = [super initWithWindowNibName:@"AxisPreferences"]){
        [self setWindowFrameAutosaveName:@"AxisPreferences"];

	}
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) awakeFromNib
{
	[self rangeChanged:nil];
}

- (void) setAxis:(ORAxis*)anAxis
{
	axis = anAxis;
	[self registerForNotifications];
	[self rangeChanged:nil];
}

- (void) registerForNotifications
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter removeObserver:self];
        
    [notifyCenter addObserver : self
                     selector : @selector(rangeChanged:)
                         name : ORAxisRangeChangedNotification
                       object : nil];

}

- (void) rangeChanged:(NSNotification*) aNote
{
	NSMutableDictionary* attributes = [axis attributes];
	[minValueField setIntValue: [[attributes objectForKey:ORAxisMinValue] intValue]];
	[maxValueField setIntValue: [[attributes objectForKey:ORAxisMaxValue] intValue]];
}

- (IBAction) minValueAction:(id)sender
{
	[axis setRngLow:[sender intValue] withHigh:[[[axis attributes] objectForKey:ORAxisMaxValue] intValue]];
}
- (IBAction) maxValueAction:(id)sender
{
	[axis setRngLow:[[[axis attributes] objectForKey:ORAxisMinValue] intValue] withHigh:[sender intValue]];
}

- (IBAction) labelAction:(id)sender
{
	[axis setLabel:[sender stringValue]];
}
@end
