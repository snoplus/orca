//
//  ORContainerModel.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright Â© 2002 CENPA, University of Washington. All rights reserved.
//

@interface ORManualPlotModel : OrcaObject  
{
    int			textSize;
}

#pragma mark ***Accessors

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORManualPlotLock;
