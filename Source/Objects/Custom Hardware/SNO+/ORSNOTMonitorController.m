//
//  ORSNOTMonitorController.m
//  Orca
//
//  Created by Christopher Jones 24/02/2014
//
//

#import "ORSNOTMonitorController.h"

@implementation ORSNOTMonitorController

-(id)init
{
    NSLog(@"initilizing with Nib Name");
    self = [super initWithWindowNibName:@"snotMonitoring"];
    return self;
}

- (void) awakeFromNib
{
    //blankView = [[NSView alloc] init];
    
    NSLog(@"updating the window");
    [super updateWindow];
    
    NSLog(@"awaking from nib");
    [super awakeFromNib];
    
    
    
}

@end
