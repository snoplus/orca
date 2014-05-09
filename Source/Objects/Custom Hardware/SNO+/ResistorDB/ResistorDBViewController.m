//
//  ResistorDBViewController.m
//  Orca
//
//  Created by Chris Jones on 28/04/2014.
//
//

#import "ResistorDBViewController.h"
#import "ResistorDBModel.h"

@interface ResistorDBViewController ()
@property (assign) IBOutlet NSProgressIndicator *loadingFromDbWheel;

@end

@implementation ResistorDBViewController
@synthesize loadingFromDbWheel;

-(id)init
{
    self = [super initWithWindowNibName:@"ResistorDBWindow"];
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void) updateWindow
{
	[super updateWindow];
    
}

-(IBAction)queryResistorDB:(id)sender
{
    if(([crateSelect value] != nil) && ([cardSelect value] != nil) && ([channelSelect value] != nil)){
        [loadingFromDbWheel setHidden:NO];
        [loadingFromDbWheel startAnimation:nil];
        [model queryResistorDb:[crateSelect value] withCard:[cardSelect value] withChannel:[channelSelect value]];
    }
}

-(void)resistorDbQueryLoaded
{
    NSLog(@"in here");
    [loadingFromDbWheel setHidden:YES];
    [loadingFromDbWheel stopAnimation:nil];
}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];
    
    [super registerNotificationObservers];
    
	[notifyCenter addObserver : self
                     selector : @selector(resistorDbQueryLoaded)
                         name : resistorDBQueryLoaded
                        object: model];
}

@end
