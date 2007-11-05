//
//  ORManualPlotModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright Â© 2002 CENPA, University of Washington. All rights reserved.
//

#pragma mark ¥¥¥Imported Files
#import "ORManualPlotModel.h"

NSString* ORManualPlotLock							 = @"ORManualPlotLock";

@implementation ORManualPlotModel

#pragma mark ¥¥¥initialization

#pragma mark ***Accessors

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"ManualPlot"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORManualPlotController"];
}


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
		
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
}

@end
