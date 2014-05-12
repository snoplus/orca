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
    //check to see if actual values have been given
    if(([crateSelect stringValue] != nil) && ([cardSelect stringValue] != nil) && ([channelSelect stringValue] != nil)){
        
        int crateNumber = [[crateSelect stringValue] intValue];
        int cardNumber = [[cardSelect stringValue] intValue];
        int channelNumber = [[channelSelect stringValue] intValue];
        NSLog(@"value: %i %i %i",crateNumber,cardNumber,channelNumber);
        
        [loadingFromDbWheel setHidden:NO];
        [loadingFromDbWheel startAnimation:nil];
        [model queryResistorDb:crateNumber withCard:cardNumber withChannel:channelNumber];
        //[currentResistorStatus setValue:]
    }
}

-(NSString*) parseStatusFromResistorDb:(NSString*)aKey withTrueStatement:(NSString*)aTrueStatement withFalseStatement:(NSString*)aFalseStatement
{
    //NSString * falseString = [NSString stringWithFormat:@"0"];
    
    if([[[[model currentQueryResults] objectForKey:aKey] stringValue] isEqualToString:@"0"]){
        return aFalseStatement;
    }
    else if([[[[model currentQueryResults] objectForKey:aKey] stringValue] isEqualToString:@"1"]){
        return aTrueStatement;
    }
    else{
        return @"Unknown State";
    }
}

-(void)resistorDbQueryLoaded
{
    //NSLog(@"in here");
    [loadingFromDbWheel setHidden:YES];
    [loadingFromDbWheel stopAnimation:nil];
    NSLog(@"model value %@",[model currentQueryResults]);
    
    //Values to load
    NSString *resistorStatus;
    NSString *SNOLowOccString;
    NSString *pmtRemovedString;
    NSString *pmtReinstalledString;
    NSString *badCableString;
    NSString *pulledCableString;
    
    @try{
        resistorStatus = [self parseStatusFromResistorDb:@"rPulled" withTrueStatement:@"Pulled" withFalseStatement:@"Not Pulled"];
        SNOLowOccString = [self parseStatusFromResistorDb:@"SnoLowOcc" withTrueStatement:@"True" withFalseStatement:@"False"];
        pmtRemovedString = [self parseStatusFromResistorDb:@"PmtRemoved" withTrueStatement:@"True" withFalseStatement:@"False"];
        pmtReinstalledString = [self parseStatusFromResistorDb:@"PmtReInstalled" withTrueStatement:@"True" withFalseStatement:@"False"];
        badCableString = [self parseStatusFromResistorDb:@"BadCable" withTrueStatement:@"True" withFalseStatement:@"False"];
        pulledCableString = [self parseStatusFromResistorDb:@"pulledCable" withTrueStatement:@"True" withFalseStatement:@"False"];
        
        //load the values to the screen
        [currentResistorStatus setValue:resistorStatus];
        [currentSNOLowOcc setValue:SNOLowOccString];
        [currentPulledCable setValue:pulledCableString];
        [currentPMTReinstallled setValue:pmtReinstalledString];
        [currentPMTRemoved setValue:pmtRemovedString];
        [currentBadCable setValue:badCableString];
    }
    
    @catch(NSException *e){
        NSLog(@"CouchDb Parse Error %@",e);
    }
    
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
