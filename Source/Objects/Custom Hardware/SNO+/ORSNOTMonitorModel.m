//
//  ORSNOTMonitorModel.m
//  Orca
//
//  Created by Christopher Jones 24/02/2014
//
//

#import "ORSNOTMonitorModel.h"


@implementation ORSNOTMonitorModel

- (id) init //designated initializer
{
    NSLog(@"Initilizing");
    self = [super init];
    return self;
}

- (void) dealloc
{
    NSLog(@"deallocating");
    [super dealloc];
}

- (void) setUpImage
{
    NSLog(@"setting up image");
    [self setImage:[NSImage imageNamed:@"snotMonitoring"]];
}

- (void) makeMainController
{
    NSLog(@"linking to main controller");
    [self linkToController:@"ORSNOTMonitorController"];

}


- (void) wakeUp
{
    NSLog(@"waking up");
    if(![self aWake]){
        NSLog(@"This object isnt awake");
    }
    [super wakeUp];
}

- (BOOL) solitaryObject
{
    return YES;
}

@end
