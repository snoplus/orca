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
    
    //NSLog(@"value %@",[[model currentQueryResults] objectForKey:aKey]);
    
    if([[[model currentQueryResults] objectForKey:aKey] isEqualToString:@"0"]){
        return aFalseStatement;
    }
    else if([[[model currentQueryResults] objectForKey:aKey] isEqualToString:@"1"]){
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
    NSLog(@"model value pulled Cable %@",[[model currentQueryResults] objectForKey:@"pulledCable"]);
    NSLog(@"model results %@",[model currentQueryResults]);
    
    //Values to load
    NSString *resistorStatus;
    NSString *SNOLowOccString;
    NSString *pmtRemovedString;
    NSString *pmtReinstalledString;
    NSString *badCableString;
    NSString *pulledCableString;
    
    @try{
        resistorStatus = [self parseStatusFromResistorDb:@"rPulled" withTrueStatement:@"Pulled" withFalseStatement:@"Not Pulled"];
        SNOLowOccString = [self parseStatusFromResistorDb:@"SnoLowOcc" withTrueStatement:@"YES" withFalseStatement:@"NO"];
        pmtRemovedString = [self parseStatusFromResistorDb:@"PmtRemoved" withTrueStatement:@"YES" withFalseStatement:@"NO"];
        pmtReinstalledString = [self parseStatusFromResistorDb:@"PmtReInstalled" withTrueStatement:@"YES" withFalseStatement:@"NO"];
        badCableString = [self parseStatusFromResistorDb:@"BadCable" withTrueStatement:@"YES" withFalseStatement:@"NO"];
        
        //pulledCable isn't a string but an integer!!!
        if([[[[model currentQueryResults] objectForKey:@"pulledCable"] stringValue] isEqualToString:@"0"]){
            pulledCableString = @"YES";
        }
        else if([[[[model currentQueryResults] objectForKey:@"pulledCable"] stringValue] isEqualToString:@"1"]){
            pulledCableString = @"NO";
        }
        else{
            pulledCableString = @"Unknown Cable State";
        }
        
        
        //load the values to the screen
        [currentResistorStatus setStringValue:resistorStatus];
        [currentSNOLowOcc setStringValue:SNOLowOccString];
        [currentPulledCable setStringValue:pulledCableString];
        [currentPMTReinstallled setStringValue:pmtReinstalledString];
        [currentPMTRemoved setStringValue:pmtRemovedString];
        [currentBadCable setStringValue:badCableString];
        
        [updateResistorStatus setStringValue:resistorStatus];
        [updateSnoLowOcc setStringValue:SNOLowOccString];
        [updatePulledCable setStringValue:pulledCableString];
        [updatePmtReinstalled setStringValue:pmtReinstalledString];
        [updatePmtRemoved setStringValue:pmtRemovedString];
        [updateBadCable setStringValue:badCableString];
    
        //reasonbox
        NSString *reasonString = [[model currentQueryResults] objectForKey:@"reason"];
        if([reasonString isEqualToString:NULL]){
            reasonString = @"";
        }
        [updateReasonBox setStringValue:reasonString];
        
        //infoBox
        NSString *infoString = [[model currentQueryResults] objectForKey:@"info"];
        if([infoString isEqualToString:NULL]){
            infoString = @"";
        }
        [updateInfoForPull setStringValue:infoString];
        [self updateWindow];
        
        
    }
    
    @catch(NSException *e){
        NSLog(@"CouchDb Parse Error %@",e);
    }
    
}

-(IBAction)updatePmtDatabase:(id)sender
{
    
    //Perform an update of the current Pmt Database 
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
