//
//  ORTimeScale.h
//  Orca
//
//  Created by Mark Howe on Tue Sep 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ORScale.h"
#import "ORPlotter.h"

@interface ORTimeScale : ORScale {
	unsigned long secondsPerUnit;
}
- (unsigned long) secondsPerUnit;
- (void) setSecondsPerUnit:(unsigned long)newSecondsPerUnit;


- (void) drawLogScale;			// draw a Log scale (calls drawLinScale)
- (void) drawLinScale;			// draw a linear scale

@end
