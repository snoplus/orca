//
//  ORMemoryMapView.h
//  Orca
//
//  Created by Mark Howe on 3/30/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ORAxis;

@interface ORMemoryMapView : NSView {
    IBOutlet ORAxis*		mYScale;
    IBOutlet  id            mDataSource; 
}
- (id)initWithFrame:(NSRect)frame;
- (void) drawRect:(NSRect)aRect;

- (IBAction) resetLimits:(id)sender;
- (IBAction) autoScale:(id)sender;

@end

#pragma mark •••Map Protocol (Informal)
@interface NSObject (MemoryMapDataSource)
- (id) memoryMap;
@end
