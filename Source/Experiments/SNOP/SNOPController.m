//
//  SNOPController.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//Washington at the Center for Experimental Nuclear Physics and
//Astrophysics (CENPA) sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#pragma mark ¥¥¥Imported Files
#import "SNOPController.h"
#import "SNOPModel.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORDetectorSegment.h"
#import "ORXL3Model.h"
#import "ORSNOCrateModel.h"
#import "ELLIEModel.h"
#import "ORCouchDB.h"
#import "ORRunModel.h"
#import "ORMTC_Constants.h"
#import "ORMTCModel.h"
#import "SNOP_Run_Constants.h"
#import "SNOCaenModel.h"
#import "RunTypeWordBits.hh"
#import "ECARun.h"

NSString* ORSNOPRequestHVStatus = @"ORSNOPRequestHVStatus";

#define UNITS_UNDECIDED 0
#define UNITS_RAW       1
#define UNITS_CONVERTED 2

// This holds the map between thresholds as ordered by the
// window and as indexed by the MTC model
const int view_model_map[10] = {
    MTC_N100_HI_THRESHOLD_INDEX,
    MTC_N100_MED_THRESHOLD_INDEX,
    MTC_N100_LO_THRESHOLD_INDEX,
    MTC_N20_THRESHOLD_INDEX,
    MTC_N20LB_THRESHOLD_INDEX,
    MTC_OWLN_THRESHOLD_INDEX,
    MTC_ESUMH_THRESHOLD_INDEX,
    MTC_ESUML_THRESHOLD_INDEX,
    MTC_OWLEHI_THRESHOLD_INDEX,
    MTC_OWLELO_THRESHOLD_INDEX};

// The following defines the map between view ordering of triggers and gt mask ordering
const int view_mask_map[10] = {2,1,0,3,4,7,6,5,9,8};

@implementation SNOPController

@synthesize
tellieStandardSequenceFlag,
tellieFireSettings,
smellieRunFileList,
smellieRunFile,
snopBlueColor,
snopRedColor,
snopOrangeColor,
snopBlackColor,
snopGrayColor,
snopGreenColor;

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"SNOP"];

    hvMask = 0;
    doggy_icon = [[RunStatusIcon alloc] init];
    [self initializeUnits];
    return self;
}
- (void) dealloc
{
    [smellieRunFileList release];
    [smellieRunFile release];
    [snopBlueColor release];
    [snopGreenColor release];
    [snopOrangeColor release];
    [snopRedColor release];
    [doggy_icon stop_animation];
    [doggy_icon release];
    
    [super dealloc];
}

- (IBAction) orcaDBTestAction:(id)sender {
    [[NSWorkspace sharedWorkspace]
     openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@:%d",
                                   [model orcaDBUserName], [model orcaDBPassword],
                                   [model orcaDBIPAddress], [model orcaDBPort]]]];
}

- (IBAction) testMTCServer:(id)sender
{
    int port = [mtcPort intValue];
    NSString *host = [mtcHost stringValue];
    
    RedisClient *r = [[RedisClient alloc] initWithHostName:host withPort:port];
    
    @try {
        [r connect];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"failed to connect: %@\n", [e reason]);
        [r release];
        return;
    }
    
    [r release];
    
    NSLog(@"connected ok!\n");
}

- (IBAction) testXL3Server:(id)sender
{
    int port = [xl3Port intValue];
    NSString *host = [xl3Host stringValue];
    
    RedisClient *r = [[RedisClient alloc] initWithHostName:host withPort:port];
    
    @try {
        [r connect];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"failed to connect: %@\n", [e reason]);
        [r release];
        return;
    }
    
    [r release];
    
    NSLog(@"connected ok!\n");
}

- (IBAction) testDataServer:(id)sender
{
    int port = [dataPort intValue];
    NSString *host = [dataHost stringValue];
    
    RedisClient *r = [[RedisClient alloc] initWithHostName:host withPort:port];
    
    @try {
        [r connect];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"failed to connect: %@\n", [e reason]);
        [r release];
        return;
    }
    
    [r release];
    
    NSLog(@"connected ok!\n");
}

- (IBAction) testLogServer:(id)sender
{
    int port = [logPort intValue];
    NSString *host = [logHost stringValue];
    
    RedisClient *r = [[RedisClient alloc] initWithHostName:host withPort:port];
    
    @try {
        [r connect];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"failed to connect: %@\n", [e reason]);
        [r release];
        return;
    }
    
    [r release];
    
    NSLog(@"connected ok!\n");
}

- (IBAction) settingsChanged:(id)sender {
    /* Settings tab changed. Set the model variables in SNOPModel. */
    [model setMTCPort:[mtcPort intValue]];
    [model setMTCHost:[mtcHost stringValue]];
    
    [model setXL3Port:[xl3Port intValue]];
    [model setXL3Host:[xl3Host stringValue]];
    
    [model setDataServerPort:[dataPort intValue]];
    [model setDataServerHost:[dataHost stringValue]];
    
    [model setLogServerPort:[logPort intValue]];
    [model setLogServerHost:[logHost stringValue]];
}

- (void) updateSettings: (NSNotification *) aNote
{
    [mtcHost setStringValue:[model mtcHost]];
    [mtcPort setIntValue:[model mtcPort]];
    
    [xl3Host setStringValue:[model xl3Host]];
    [xl3Port setIntValue:[model xl3Port]];
    
    [dataHost setStringValue:[model dataHost]];
    [dataPort setIntValue:[model dataPort]];
    
    [logHost setStringValue:[model logHost]];
    [logPort setIntValue:[model logPort]];
}

-(void)windowDidLoad
{

}


- (NSString*) defaultPrimaryMapFilePath
{
    return @"~/SNOP";
}

-(void) awakeFromNib
{
    detectorSize		= NSMakeSize(1200,700);
    detailsSize		= NSMakeSize(1200,700);//NSMakeSize(450,589);
    focalPlaneSize		= NSMakeSize(1200,700);//NSMakeSize(450,589);
    couchDBSize		= NSMakeSize(1200,700);//(620,595);//NSMakeSize(450,480);
    hvMasterSize		= NSMakeSize(1200,700);
    runsSize		= NSMakeSize(1200,700);
    
    blankView = [[NSView alloc] init];
    [tabView setFocusRingType:NSFocusRingTypeNone];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

    //Custom colors
    [self setSnopBlueColor:[NSColor colorWithSRGBRed:30./255. green:144./255. blue:255./255. alpha:1]];
    [self setSnopRedColor:[NSColor colorWithSRGBRed:255./255. green:102./255. blue:102./255. alpha:1]];
    [self setSnopGreenColor:[NSColor colorWithSRGBRed:0./255. green:150./255. blue:0./255. alpha:1]];
    [self setSnopOrangeColor:[NSColor colorWithSRGBRed:255./255. green:178./255. blue:102./255. alpha:1]];
    [self setSnopBlackColor:[NSColor colorWithSRGBRed:0./255. green:0./255. blue:0./255. alpha:1]];
    [self setSnopGrayColor:[NSColor colorWithSRGBRed:0./255. green:0./255. blue:0./255. alpha:0.5]];

    //Update conection settings
    [self updateSettings:nil];
    //Sync runnumber with main RunControl
    [self updateRunInfo:nil];
    [self findRunControl:nil];
    [runControl getCurrentRunNumber]; //this should be done by the base class... but it is not
    //Sync SR with MTC

    //Update XL3 state
    [self updatexl3Mode:nil];

    [doggy_icon start_animation];

    [self initializeUnits];
    [self mtcDataBaseChanged:nil];
    //Update runtype word
    [self refreshRunWordLabels:nil];
    [self runTypeWordChanged:nil];
    //Lock Standard Runs menus at init
    if([model standardRunType] == nil){
        [standardRunVersionPopupMenu setEnabled:false];
    }
    else{
        [model refreshStandardRunsFromDB];
    }

    if(!doggy_icon)
    {
        doggy_icon = [[RunStatusIcon alloc] init];
    }
    //Pull the information from the SMELLIE DB
    [super awakeFromNib];
    [self performSelector:@selector(updateWindow)withObject:self afterDelay:0.1];
}
- (void) initializeUnits {
    for(int i=0;i<10;i++) {
        displayUnitsDecider[i] = UNITS_UNDECIDED;
    }
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(dbOrcaDBIPChanged:)
                         name : ORSNOPModelOrcaDBIPAddressChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(dbDebugDBIPChanged:)
                         name : ORSNOPModelDebugDBIPAddressChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(hvStatusChanged:)
                         name : ORXL3ModelHvStatusChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(hvStatusChanged:)
                         name : ORXL3ModelHVNominalVoltageChanged
                        object: nil];
    
    [notifyCenter addObserver :self
                     selector : @selector(stopSmellieRunAction:)
                         name : ORSMELLIERunFinished
                        object: nil];
    
    [notifyCenter addObserver :self
                     selector : @selector(startTellieRunNotification:)
                         name : ORTELLIERunStart
                        object: nil];
    
    
    [notifyCenter addObserver :self
                     selector : @selector(stopTellieRunAction:)
                         name : ORTELLIERunFinished
                        object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStatusChanged:)
                         name: ORRunStatusChangedNotification
                       object: nil];
    
    [notifyCenter addObserver:self
                     selector:@selector(standardRunsCollectionChanged:)
                         name:ORSNOPModelSRCollectionChangedNotification
                         object:nil];

    [notifyCenter addObserver:self
                     selector:@selector(SRTypeChanged:)
                         name:ORSNOPModelSRChangedNotification
                       object:nil];
    
    [notifyCenter addObserver:self
                     selector:@selector(SRVersionChanged:)
                         name:ORSNOPModelSRVersionChangedNotification
                       object:nil];
    
    [notifyCenter addObserver :self
                     selector :@selector(runTypeWordChanged:)
                         name :ORRunTypeChangedNotification
                       object :nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runsLockChanged:)
                         name : ORSecurityNumberLockPagesChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runsLockChanged:)
                         name : ORSNOPRunsLockNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runsECAChanged:)
                         name : ORECARunChangedNotification
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(runsECAChanged:)
                         name : ORECARunStartedNotification
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runsECAChanged:)
                         name : ORECARunFinishedNotification
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(mtcDataBaseChanged:)
                         name : ORMTCAThresholdChanged
                        object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(mtcDataBaseChanged:)
                         name : ORMTCAConversionChanged
                        object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(mtcDataBaseChanged:)
                         name : ORMTCABaselineChanged
                        object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(mtcDataBaseChanged:)
                         name : ORMTCPulserRateChanged
                        object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(mtcDataBaseChanged:)
                         name : ORMTCSettingsChanged
                        object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(mtcDataBaseChanged:)
                         name : ORMTCGTMaskChanged
                        object: nil];
    [notifyCenter addObserver : self
                     selector : @selector(updateSettings:)
                         name : @"SNOPSettingsChanged"
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(fetchRunFilesFinish:)
                         name : @"SmellieRunFilesLoaded"
                        object: nil];
    
}

- (void) updateWindow
{
    [super updateWindow];
    [self hvStatusChanged:nil];
    [self dbOrcaDBIPChanged:nil];
    [self dbDebugDBIPChanged:nil];
    [self runStatusChanged:nil];
    [self SRTypeChanged:nil];
    [self SRVersionChanged:nil];
    [self runsLockChanged:nil];
    [self runsECAChanged:nil];
    [self runTypeWordChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORSNOPRunsLockNotification to:secure];
    [runsLockButton setEnabled:secure];
}

-(void) SRTypeChanged:(NSNotification*)aNote
{

    NSString* standardRun = [model standardRunType];
    if([standardRunPopupMenu numberOfItems] == 0 || standardRun == nil || [standardRun isEqualToString:@""]){
        return;
    }
    if([standardRunPopupMenu indexOfItemWithObjectValue:standardRun] == NSNotFound){
        NSLogColor([NSColor redColor],@"Standard Run \"%@\" does not exist. \n", standardRun);
        return;
    }
    else{
        [standardRunPopupMenu selectItemWithObjectValue:standardRun];
        [self refreshStandardRunVersions];
    }

}

//Update the SR diplay when SR changes
-(void) SRVersionChanged:(NSNotification*)aNote
{

    NSString* standardRunVersion = [model standardRunVersion];
    if([standardRunVersionPopupMenu numberOfItems] == 0 || standardRunVersion == nil || [standardRunVersion isEqualToString:@""]){
        return;
    }
    if([standardRunVersionPopupMenu indexOfItemWithObjectValue:standardRunVersion] == NSNotFound){
        NSLogColor([NSColor redColor],@"Standard Run Version \"%@\" does not exist. \n",standardRunVersion);
        return;
    }
    else{
        [standardRunVersionPopupMenu selectItemWithObjectValue:standardRunVersion];
    }
    
    [self displayThresholdsFromDB];
    [self runTypeWordChanged:nil];

}

- (IBAction) startRunAction:(id)sender
{

    //Load selected SR in case the user didn't click enter
    //fixed memory leak in the next two lines -- don't 'copy without a matching release MAH 03/8/2017
    NSString *standardRun = [standardRunPopupMenu objectValueOfSelectedItem];
    NSString *standardRunVersion = [standardRunVersionPopupMenu objectValueOfSelectedItem];
    
    //Load selected version run:
    //If we are in operator mode we ALWAYS load the DEFAULTs
    //The expert mode has the freedom to load any test run. This is dangerous
    //but hopefully we won't need to run in expert mode for physics data and in any
    //case the expert will know this!
    BOOL locked = [gSecurity isLocked:ORSNOPRunsLockNotification];
    if(locked) { //Operator Mode
        standardRunVersion = @"DEFAULT";
    } else{ //Expert Mode
        //Nothing
    }

    //Handle no SR cases
    if([standardRun isEqualToString:@""] || standardRun == nil){
        NSLogColor([NSColor redColor],@"Standard Run not set. Enter a valid name. \n");
        return;
    }
    if([standardRunVersion isEqualToString:@""] || standardRunVersion == nil){
        NSLogColor([NSColor redColor],@"Standard Run Version not set. Enter a valid name. \n");
        return;
    }
    
    [model startStandardRun:standardRun withVersion:standardRunVersion];
    [standardRun release];
    [standardRunVersion release];
}

- (IBAction)resyncRunAction:(id)sender
{
    /* A resync run does a hard stop and start without the user having to hit
     * stop run and then start run. Doing this resets the GTID, which resyncs
     * crate 9 after it goes out of sync :). */

    //Load the standard run and stop run initialization if failed
    if(![model loadStandardRun:[model standardRunType] withVersion:[model standardRunVersion]]) return;

    [model setResync:YES];

    if ([[model document] isDocumentEdited]) {
        [[model document] afterSaveDo:@selector(restartRun) withTarget:runControl];
        [[model document] saveDocument:nil];
    } else {
        [runControl restartRun];
    }
}


- (IBAction) stopRunAction:(id)sender
{

    [self endEditing];
    [model stopRun];

}

- (void) runStatusChanged:(NSNotification*)aNotification
{
    [startRunButton setEnabled:true];

    if([runControl runningState] == eRunInProgress){
        [startRunButton setTitle:@"RESTART"];
        [lightBoardView setState:kGoLight];
        [runStatusField setStringValue:@"Running"];
        [resyncRunButton setEnabled:true];
        [doggy_icon start_animation];
	}
	else if([runControl runningState] == eRunStopped){
        [startRunButton setTitle:@"START"];
        [lightBoardView setState:kStoppedLight];
        [runStatusField setStringValue:@"Stopped"];
        [resyncRunButton setEnabled:false];
        [doggy_icon stop_animation];
	}
	else if([runControl runningState] == eRunStarting || [runControl runningState] == eRunStopping || [runControl runningState] == eRunBetweenSubRuns){
        if([runControl runningState] == eRunStarting){
            //The run started so update the display
            [runStatusField setStringValue:@"Starting"];
            [startRunButton setEnabled:false];
            [resyncRunButton setEnabled:false];
            [startRunButton setTitle:@"STARTING..."];
        }
        else {
            //Do nothing
        }
        [lightBoardView setState:kCautionLight];
	}

    if ([runControl isRunning] && ([runControl runType] & kECARun)) {
        /* Disable the ping crates button if we are in an ECA run. */
        [pingCratesButton setEnabled:FALSE];
    } else {
        [pingCratesButton setEnabled:TRUE];
    }
}

- (IBAction) pingCratesAction: (id) sender
{
    [model pingCrates];
}

- (void) dbOrcaDBIPChanged:(NSNotification*)aNote
{
    [orcaDBIPAddressPU setStringValue:[model orcaDBIPAddress]];
}

- (void) dbDebugDBIPChanged:(NSNotification*)aNote
{
    [debugDBIPAddressPU setStringValue:[model debugDBIPAddress]];
}

- (void) hvStatusChanged:(NSNotification*)aNote
{
    if (!aNote) {
        //collect all instances of xl3 objects in Orca
        NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
        
        // bit wise mask of xl3s
        unsigned long xl3Mask = 0x7ffff;
        
        //loop through all xl3 instances in Orca
        for (id xl3 in xl3s) {
            
            xl3Mask ^= 1 << [xl3 crateNumber];
            int mRow;
            int mColumn;
            bool found;
            
            found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:[xl3 crateNumber]]];
            if (found) {
                //Individual HV status
                [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[xl3 hvASwitch]?@"ON":@"OFF"];
                if ([xl3 hvASwitch]) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
		    hvMask |= (1 << [xl3 crateNumber]);
                }
                else {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
		    hvMask &= ~(1 << [xl3 crateNumber]);
                }
                [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvNominalVoltageA]]];
                [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvAVoltageReadValue]]];
                [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:
                 [NSString stringWithFormat:@"%3.1f mA",[xl3 hvACurrentReadValue]]];
            }
            if ([xl3 crateNumber] == 16) {//16B
                int mRow;
                int mColumn;
                bool found;
                found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:19]];
                if (found) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[xl3 hvBSwitch]?@"ON":@"OFF"];
                    if ([xl3 hvBSwitch]) {
                        [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
			hvMask |= (1 << 19);
                    }
                    else {
                        [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
			hvMask &= ~(1 << 19);
                    }
                    [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:
                     [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvNominalVoltageB]]];
                    [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
                     [NSString stringWithFormat:@"%d V",(unsigned int)[xl3 hvBVoltageReadValue]]];
                    [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:
                     [NSString stringWithFormat:@"%3.1f mA",[xl3 hvBCurrentReadValue]]];
                }
            }
        }
        unsigned short crate_num;
        if (xl3Mask & 1 << 16) {//16B needs an extra care
            xl3Mask |= 1 << 19;
        }
        for (crate_num=0; crate_num<20; crate_num++) {
            if (xl3Mask & 1 << crate_num) {
                int mRow;
                int mColumn;
                bool found;
                found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:crate_num]];
                if (found) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:@"???"];
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
                    [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:@"??? V"];
                    [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:@"??? V"];
                    [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:@"??? mA"];
                }
            }
        }
    }
    else { //update from a notification
        int mRow;
        int mColumn;
        bool found;
        found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:
                 [hvStatusMatrix cellWithTag:[[aNote object] crateNumber]]];
        
        if (found) {
            [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[[aNote object] hvASwitch]?@"ON":@"OFF"];
            if ([[aNote object] hvASwitch]) {
                [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
		hvMask |= (1 << [[aNote object] crateNumber]);
            }
            else {
                [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
		hvMask &= ~(1 << [[aNote object] crateNumber]);
            }
            [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:
             [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvNominalVoltageA]]];
            [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
             [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvAVoltageReadValue]]];
            [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:
             [NSString stringWithFormat:@"%3.1f mA",[[aNote object] hvACurrentReadValue]]];
        }
        if ([[aNote object] crateNumber] == 16) {//16B
            int mRow;
            int mColumn;
            bool found;
            found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:19]];
            if (found) {
                [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[[aNote object] hvBSwitch]?@"ON":@"OFF"];
                if ([[aNote object] hvBSwitch]) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
		    hvMask |= (1 << 19);
                }
                else {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
		    hvMask &= ~(1 << 19);
                }
                [[hvStatusMatrix cellAtRow:mRow column:2] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvNominalVoltageB]]];
                [[hvStatusMatrix cellAtRow:mRow column:3] setStringValue:
                 [NSString stringWithFormat:@"%d V",(unsigned int)[[aNote object] hvBVoltageReadValue]]];
                [[hvStatusMatrix cellAtRow:mRow column:4] setStringValue:
                 [NSString stringWithFormat:@"%3.1f mA",[[aNote object] hvBCurrentReadValue]]];
            }
        }
    }

    // Detector worldwide HV status
    if(hvMask){
        [detectorHVStatus setStringValue:@"PMT HV is ON"];
        [detectorHVStatus setBackgroundColor:snopRedColor];
        [panicDownButton setEnabled:1];
    } else{
        [detectorHVStatus setStringValue:@"PMT HV is OFF"];
        [detectorHVStatus setBackgroundColor:snopBlueColor];
        [panicDownButton setEnabled:0];
    }
}


#pragma mark ¥¥¥Interface Management
- (IBAction) orcaDBIPAddressAction:(id)sender
{
    [model setOrcaDBIPAddress:[sender stringValue]];
}

- (IBAction) debugDBIPAddressAction:(id)sender
{
    [model setDebugDBIPAddress:[sender stringValue]];
}

- (IBAction) orcaDBClearHistoryAction:(id)sender
{
    [model clearOrcaDBConnectionHistory];
}

- (IBAction) debugDBClearHistoryAction:(id)sender
{
    [model clearDebugDBConnectionHistory];
}

- (IBAction) orcaDBFutonAction:(id)sender
{
    
    NSString *url = [NSString stringWithFormat:@"http://%@:%@@%@:%d/_utils/database.html?%@",[model orcaDBUserName],[model orcaDBPassword],[model orcaDBIPAddress],[model orcaDBPort],[model orcaDBName]];
    NSString* urlScaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlScaped]];
}

- (IBAction) debugDBFutonAction:(id)sender
{
    
    NSString *url = [NSString stringWithFormat:@"http://%@:%@@%@:%d/_utils/database.html?%@", [model debugDBUserName], [model debugDBPassword],[model debugDBIPAddress],[model debugDBPort], [model debugDBName]];
    NSString* urlScaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlScaped]];
}

- (IBAction) debugDBTestAction:(id)sender
{
    [[NSWorkspace sharedWorkspace]
     openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@:%d",
                                   [model debugDBUserName], [model debugDBPassword],
                                   [model debugDBIPAddress], [model debugDBPort]]]];
}


- (IBAction) orcaDBPingAction:(id)sender
{
    [model orcaDBPing];
}

- (IBAction) debugDBPingAction:(id)sender
{
    [model debugDBPing];
}

- (IBAction)hvMasterPanicAction:(id)sender
{

    BOOL cancel = ORRunAlertPanel(@"Panic Down the entire detector",@"Is this really what you want?",@"Cancel",@"Yes",nil);
    if(cancel) return;

    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(hvPanicDown)];
    NSLogColor([NSColor redColor],@"Detector wide panic down started\n");
}

- (IBAction)panicDownSingleCrateAction:(id)sender
{

    NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    int crateNumber = [sender selectedRow];

    //Handle crates 17 and 18
    if(crateNumber > 16) crateNumber--;
    
    //Confirm
    BOOL cancel = ORRunAlertPanel([NSString stringWithFormat:@"Panic Down Crate %i?",crateNumber],@"Is this really what you want?",@"Cancel",@"Yes",nil);
    if (cancel) return;
    for (id xl3 in xl3s) {

        if ([xl3 crateNumber] != crateNumber) continue;
        
        [xl3 hvPanicDown];
        return;

    }

    NSLogColor([NSColor redColor],@"XL3 %i not found. Unable to Panic Down. \n",crateNumber);
    
}

- (IBAction)updatexl3Mode:(id)sender
{
    int i =0;
    NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    for (id xl3 in xl3s) {
        ORXL3Model * anXl3 = xl3;
        //[xl3 xl3Mode];
        NSString *xl3ModeDescription;
        if([anXl3 xl3Mode] == 1)        xl3ModeDescription = [NSString stringWithFormat:@"init"];
        else if ([anXl3 xl3Mode] == 2)  xl3ModeDescription = [NSString stringWithFormat:@"normal"];
        else if ([anXl3 xl3Mode] == 3)  xl3ModeDescription = [NSString stringWithFormat:@"CGT"];
        else                            xl3ModeDescription = [NSString stringWithFormat:@"unknown"];
        
        if([anXl3 crateNumber] == 16){
            i++;
            [[globalxl3Mode cellAtRow:16 column:0] setStringValue:xl3ModeDescription];
            if(i>0){
                [[globalxl3Mode cellAtRow:17 column:0] setStringValue:xl3ModeDescription];
            }
        }
        else if ([anXl3 crateNumber] > 16){
            [[globalxl3Mode cellAtRow:([anXl3 crateNumber]+1) column:0] setStringValue:xl3ModeDescription];
        }
        else{
            [[globalxl3Mode cellAtRow:[anXl3 crateNumber] column:0] setStringValue:xl3ModeDescription];
        }
        //setStringValue:[xl3 xl3Mode] stringValue]];
        /*if([anXl3 crateNumber] >= 16); //skip for 16B
         {
         [[globalxl3Mode cellAtRow:[anXl3 crateNumber] column:0] setStringValue:xl3ModeDescription];
         }*/
    }
}

- (IBAction) reportAction:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"https://github.com/snoplus/orca/issues/new"];
    NSString* urlScaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlScaped]];
}

- (IBAction) logAction:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"http://snopl.us/shift/"];
    NSString* urlScaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlScaped]];
}

- (IBAction) opManualAction:(id)sender
{
    NSString *url = [NSString stringWithFormat:@"http://snopl.us/detector/operator_manual/operator_manual.html"];
    NSString* urlScaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlScaped]];
}

- (IBAction)hvMasterTriggersOFF:(id)sender
{
    BOOL cancel = ORRunAlertPanel(@"Disabling Channel Triggers",@"Is this really what you want?",@"Cancel",@"Yes",nil);
    if(cancel) return;

    [model hvMasterTriggersOFF];
}

- (IBAction)hvMasterStatus:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPRequestHVStatus object:self];
}

#pragma mark ¥¥¥Table Data Source

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
    
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
        //StandardRuns
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:runsSize];
        [[self window] setContentView:snopView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
        //HV
        [self resizeWindowToSize:hvMasterSize];
        [[self window] setContentView:blankView];
        [[self window] setContentView:snopView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
        //State
        [[detectorState mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://snopl.us/monitoring/state"] ] ];
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:detectorSize];
        [[self window] setContentView:snopView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
        //Settings
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:detailsSize];
        [[self window] setContentView:snopView];
    }

    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.SNOPController.selectedtab"];
}

#pragma mark ¥¥¥ComboBox Data Source
- (NSInteger) numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    if (aComboBox == orcaDBIPAddressPU) {
        return [[model orcaDBConnectionHistory] count];
    }
    else if (aComboBox == debugDBIPAddressPU) {
        return [[model debugDBConnectionHistory] count];
    }
    
    return 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    if (aComboBox == orcaDBIPAddressPU) {
        return [model orcaDBConnectionHistoryItem:index];
    }
    else if (aComboBox == debugDBIPAddressPU) {
        return [model debugDBConnectionHistoryItem:index];
    }
    
    return nil;
}

//smellie functions ----------------------------------------------

//this fetches the smellie run file information
- (IBAction) fetchRunFiles:(id)sender
{
    // Temporarily disable drop down list and remove old items
    [smellieRunFileNameField addItemWithObjectValue:@""];
    [smellieRunFileNameField selectItemWithObjectValue:@""];
    [smellieRunFileNameField setEnabled:NO];
    [smellieRunFileNameField removeAllItems];
    [smellieStartRunButton setEnabled:NO];
    [smellieStopRunButton setEnabled:NO];
    [smellieEmergencyStop setEnabled:NO];
    
    // Set the smellieRunFileList to nil
    [self setSmellieRunFileList:nil];
    
    // Call getSmellieRunFiles from the model. This queries the DB and sets the smellieRunFiles
    // property. This function runs asyncronously so we have to wait for a notification to be
    // posted back before we can fill and re-activate the dropdown list (see below).
    [model getSmellieRunFiles];
}

-(void) fetchRunFilesFinish:(NSNotification *)aNote
{
   // When we get a noticication that the database read has finished, set local variables
    NSMutableDictionary *runFileDict = [[NSMutableDictionary alloc] initWithDictionary:[model smellieRunFiles]];
    
    //Fill lthe combo box with information
    for(id key in runFileDict){
        id loopValue = [runFileDict objectForKey:key];
        [smellieRunFileNameField addItemWithObjectValue:[NSString stringWithFormat:@"%@",[loopValue objectForKey:@"run_name"]]];
    }
    
    [smellieRunFileNameField setEnabled:YES];
    [smellieLoadRunFile setEnabled:YES];
    
    [self setSmellieRunFileList:runFileDict];
    [runFileDict release];
}

-(IBAction)loadSmellieRunAction:(id)sender
{
    if([smellieRunFileNameField objectValueOfSelectedItem]!= nil)
    {
        //Loop through all the smellie files in the run list
        for(id key in [self smellieRunFileList]){
            
            id currentRunFile = [[self smellieRunFileList] objectForKey:key];
            
            NSString *thisRunFile = [currentRunFile objectForKey:@"run_name"];
            NSString *requestedRunFile = [smellieRunFileNameField objectValueOfSelectedItem];
            
            if( [thisRunFile isEqualToString:requestedRunFile]){
                
                [self setSmellieRunFile:currentRunFile];
                [loadedSmellieRunNameLabel setStringValue:[smellieRunFile objectForKey:@"run_name"]];
                [model setSmellieRunNameLabel:[NSString stringWithFormat:@"%@",[smellieRunFile objectForKey:@"run_name"]]];
                [loadedSmellieTriggerFrequencyLabel setStringValue:[smellieRunFile objectForKey:@"trigger_frequency"]];
                [loadedSmellieOperationModeLabel setStringValue:[smellieRunFile objectForKey:@"operation_mode"]];
                
                //counters of fibres and Lasers
                int fibreCounter=  0;
                int laserCounter = 0;
                
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS007"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS107"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS207"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS025"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS125"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS225"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS037"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS137"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS237"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS055"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS155"] intValue];
                fibreCounter = fibreCounter + [[self.smellieRunFile objectForKey:@"FS255"] intValue];
                
                laserCounter = laserCounter + [[self.smellieRunFile objectForKey:@"375nm_laser_on"] intValue];
                laserCounter = laserCounter + [[self.smellieRunFile objectForKey:@"405nm_laser_on"] intValue];
                laserCounter = laserCounter + [[self.smellieRunFile objectForKey:@"440nm_laser_on"] intValue];
                laserCounter = laserCounter + [[self.smellieRunFile objectForKey:@"500nm_laser_on"] intValue];
                laserCounter = laserCounter + [[self.smellieRunFile objectForKey:@"superK_laser_on"] intValue];
                
                [loadedSmellieFibresLabel setStringValue:[NSString stringWithFormat:@"%i",fibreCounter]];
                
                //Concatenate the laser string
                NSMutableString * smellieLaserString = [[NSMutableString alloc] init];
                
                //see if the 375nm laser is on
                if([[self.smellieRunFile objectForKey:@"375nm_laser_on"] intValue] == 1){
                    [smellieLaserString appendString:@" 375nm "];
                }
                
                //see if the 405nm laser is on
                if([[self.smellieRunFile objectForKey:@"405nm_laser_on"] intValue] == 1){
                    [smellieLaserString appendString:@" 405nm "];
                }
                
                //see if the 440nm laser is on
                if([[self.smellieRunFile objectForKey:@"440nm_laser_on"] intValue] == 1){
                    [smellieLaserString appendString:@" 440nm "];
                }
                
                //see if the 500nm laser is on
                if([[self.smellieRunFile objectForKey:@"500nm_laser_on"] intValue] == 1){
                    [smellieLaserString appendString:@" 500nm "];
                }

                //see if the 500nm laser is on
                if([[self.smellieRunFile objectForKey:@"superK_laser_on"] intValue] == 1){
                    [smellieLaserString appendString:@" superK "];
                }
                
                //Calculate the approximate time of the run
                float triggerFrequency = [[smellieRunFile objectForKey:@"trigger_frequency"] floatValue];
                float numberTriggersPerLoop = [[smellieRunFile objectForKey:@"triggers_per_loop"] floatValue];
                // superK time
                float superKTimeScale = (1 * fibreCounter * [[self.smellieRunFile objectForKey:@"superK_wavelength_no_steps"] intValue] *
                                     [[self.smellieRunFile objectForKey:@"superK_intensity_no_steps"] intValue] *
                                     [[self.smellieRunFile objectForKey:@"superK_gain_no_steps"] intValue]);
                // Fixed wavelength time
                float numberIntensityLoops = (([[self.smellieRunFile objectForKey:@"375nm_intensity_no_steps"] intValue] +
                                          [[self.smellieRunFile objectForKey:@"405nm_intensity_no_steps"] intValue] +
                                          [[self.smellieRunFile objectForKey:@"440nm_intensity_no_steps"] intValue] +
                                          [[self.smellieRunFile objectForKey:@"500nm_intensity_no_steps"] intValue]) / 4.);
                float numberGainLoops = (([[self.smellieRunFile objectForKey:@"375nm_gain_no_steps"] intValue] +
                                     [[self.smellieRunFile objectForKey:@"405nm_gain_no_steps"] intValue] +
                                     [[self.smellieRunFile objectForKey:@"440nm_gain_no_steps"] intValue] +
                                     [[self.smellieRunFile objectForKey:@"500nm_gain_no_steps"] intValue]) / 4.);
                float numberFixedlasers = ([[self.smellieRunFile objectForKey:@"375nm_laser_on"] intValue] +
                                           [[self.smellieRunFile objectForKey:@"405nm_laser_on"] intValue] +
                                           [[self.smellieRunFile objectForKey:@"440nm_laser_on"] intValue] +
                                           [[self.smellieRunFile objectForKey:@"500nm_laser_on"] intValue]);
                float fixedTimeScale = (numberFixedlasers * fibreCounter * numberIntensityLoops * numberGainLoops);
                float totalTime = ((superKTimeScale + fixedTimeScale)*numberTriggersPerLoop) / (triggerFrequency*60);
                [loadedSmellieApproxTimeLabel setStringValue:[NSString stringWithFormat:@"%0.1f",totalTime]];
                [loadedSmellieLasersLabel setStringValue:smellieLaserString];
                
                //unlock the control buttons
                //[smellieCheckInterlock setEnabled:YES];
                [smellieLaserString release];
            }
        }
        //Activate run buttons
        [smellieStartRunButton setEnabled:YES];
        [smellieStopRunButton setEnabled:NO];
        [smellieEmergencyStop setEnabled:NO];
    }
    else{
        //[smellieCheckInterlock setEnabled:NO];
        NSLog(@"Main SNO+ Control:Please choose a Smellie Run File from selection\n");
    }
}

- (IBAction) startSmellieRunAction:(id)sender
{
    //////////////////
    // Check if a run is already ongoing
    // If so tell the user and ignore this
    // button press
    if([smellieThread isExecuting]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: A Smellie fire sequence is already on going. Cannot launch a new one until current sequence has finished\n");
        return;
    }
    
    if(![[model lastStandardRunType] isEqualToString:@"SMELLIE"]){
        ORRunAlertPanel(@"The SMELLIE standard run is not loaded.",@"You must load a SMELLIE standard run and start a new run before starting a fire sequence",@"OK",nil,nil);
        return;
    }
    
    [smellieLoadRunFile setEnabled:NO];
    [smellieRunFileNameField setEnabled:NO];
    [smellieStopRunButton setEnabled:YES];
    [smellieEmergencyStop setEnabled:YES];
    [smellieStartRunButton setEnabled:NO];
    
    //assign the run type as a SMELLIE run
    //[model setRunType:kRunSmellie];

    //Collect a series of objects from the ELLIEModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![objs count]) {
      NSString* reasonStr = @"ELLIE model not available, add an ELLIE model to your experiment";
      NSException* e = [NSException
			exceptionWithName:@"NoEllieModel"
			reason:reasonStr
			userInfo:nil];
      [e raise];
    }
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];
    
    smellieThread = [[NSThread alloc] initWithTarget:theELLIEModel selector:@selector(startSmellieRun:) object:smellieRunFile];
    [smellieThread start];
}

- (IBAction) stopSmellieRunAction:(id)sender
{
    [smellieLoadRunFile setEnabled:YES];
    [smellieRunFileNameField setEnabled:YES];
    [smellieStopRunButton setEnabled:NO];
    //[smellieCheckInterlock setEnabled:YES];

    //////////////////////
    // Check if the thread is still running,
    // if not cancel the thread and let the
    // catch statements in [ellieModel startSmellieRun]
    // cause a goto err;
    if(![smellieThread isCancelled]){
        [smellieThread cancel];
        return;
    }
    
    //Collect a series of objects from the ELLIEModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![objs count]) {
        NSString* reasonStr = @"ELLIE model not available, add an ELLIE model to your experiment";
        NSException* e = [NSException
                          exceptionWithName:@"NoEllieModel"
                          reason:reasonStr
                          userInfo:nil];
        [e raise];
    }
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];

    //Call stop smellie run method to tidy up SMELLIE's hardware state
    @try{
        [theELLIEModel stopSmellieRun];
    } @catch(NSException* e){
        [e raise];
    }

    ////////////
    // Roll over into maintinance run
    if([[model lastStandardRunType] isEqualToString:@"SMELLIE"]){
        [model setStandardRunType:@"MAINTENANCE"];
        [self loadStandardRunFromDBAction:self];
        [self startRunAction:self];
    }
}

- (IBAction) emergencySmellieStopAction:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SMELLIEEmergencyStop" object:self];
    [smellieLoadRunFile setEnabled:NO];
    [smellieRunFileNameField setEnabled:NO];
    [smellieStartRunButton setEnabled:NO];
    [smellieStopRunButton setEnabled:YES];
    
}

-(void)startTellieRunNotification:(NSNotification *)note;
{
    [self setTellieFireSettings:[note userInfo]];
    [self startTellieRunAction:nil];
}

-(IBAction)startTellieRunAction:(id)sender
{
    //////////////////
    // Check if a run is already ongoing
    // If so tell the user and ignore this
    // button press
    if([tellieThread isExecuting]){
        NSLogColor([NSColor redColor], @"[TELLIE]: A tellie fire sequence is already on going. Cannot launch a new one until current sequence has finished\n");
        return;
    }
    
    if(![[model lastStandardRunType] isEqualToString:@"TELLIE"]){
        ORRunAlertPanel(@"The TELLIE standard run is not loaded.",@"You must load a TELLIE standard run and start a new run before starting a fire sequence",@"OK",nil,nil);
        return;
    }
    
    //////////////////
    // Get ellie model and launch a fire
    // sequence
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![objs count]) {
        NSString* reasonStr = @"ELLIE model not available, add an ELLIE model to your experiment";
        NSException* e = [NSException
                          exceptionWithName:@"NoEllieModel"
                          reason:reasonStr
                          userInfo:nil];
        [e raise];
    }
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];
    
    // Handle if this came from an ELLIE GUI call
    if(!sender){
        [self setTellieStandardSequenceFlag:NO];
        tellieThread = [[NSThread alloc] initWithTarget:theELLIEModel selector:@selector(startTellieRun:) object:[self tellieFireSettings]];
        [tellieThread start];
        return;
    }
}

- (IBAction) stopTellieRunAction:(id)sender
{
    //////////////////////
    // Check if the thread has been cancelled,
    // if not cancel the thread and let the
    // catch statements in [ellieModel startTellieRun]
    // cause a goto err;
    if(![tellieThread isCancelled]){
        [tellieThread cancel];
        return;
    }

    //Collect a series of objects from the ELLIEModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![objs count]) {
        NSString* reasonStr = @"ELLIE model not available, add an ELLIE model to your experiment";
        NSException* e = [NSException
                          exceptionWithName:@"NoEllieModel"
                          reason:reasonStr
                          userInfo:nil];
        [e raise];
    }
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];
    
    //Call stop smellie run method to tidy up TELLIE's hardware state
    @try{
        [theELLIEModel stopTellieRun];
    } @catch(NSException* e){
        [e raise];
    }
    
    ////////////
    // Handle end of run sqeuencing
    if([[model lastStandardRunType] isEqualToString:@"TELLIE"]){
        // If user was running a TELLIE standard sequence, roll over into maintinance run
        if([self tellieStandardSequenceFlag]){
            [model setStandardRunType:@"MAINTENANCE"];
            [self loadStandardRunFromDBAction:self];
            [self startRunAction:self];
        // If user is using the ellie gui simply start a new run as they'll likely need to run
        // more sequences. Reasonable as this is an 'expert' level operation. Proceedures
        // will dictate the user should start a new standard run manualy when they're finished
        } else {
            [self startRunAction:self];
        }
    }
    
    [self setTellieFireSettings:nil];
}

- (IBAction) runsLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORSNOPRunsLockNotification to:[sender intValue] forWindow:[self window]];
}

- (IBAction)refreshRunWordLabels:(id)sender
{
    for(int ibit=0;ibit<32;ibit++){
        NSString *aName = [NSString stringWithUTF8String:RunTypeWordBitNames[ibit]];
        [[runTypeWordMatrix cellAtRow:ibit column:0] setTitle:aName];
    }
}

- (IBAction)runTypeWordAction:(id)sender
{
    short bit = [sender selectedRow];
    BOOL state  = [[sender selectedCell] state];
    unsigned long currentRunMask = [model runTypeWord];
    if(state) currentRunMask |= (1L<<bit);
    else      currentRunMask &= ~(1L<<bit);
    //Unset bits for the mutually exclusive part so that it's impossible to mess up with it
    if(bit<11){
        for(int i=0; i<11; i++){
            currentRunMask &= ~(1L<<i);
        }
        if(state) currentRunMask |= (1L<<bit);
        else      currentRunMask &= ~(1L<<bit);
    }

    [runControl setRunType:currentRunMask];
}

- (void) runsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:ORSNOPRunsLockNotification];
    BOOL lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSNOPRunsLockNotification];
    
    //[softwareTriggerButton setEnabled: !locked && !runInProgress];
    [runsLockButton setState: locked];
    
    //Select default standard run if in operator mode
    if(locked
       && [standardRunPopupMenu numberOfItems] != 0
       && ![[model standardRunVersion] isEqualToString:@"DEFAULT"]) [model setStandardRunVersion:@"DEFAULT"];
    
    //Enable or disable fields
    [standardRunThresCurrentValues setEnabled:!lockedOrNotRunningMaintenance];
    [standardRunSaveButton setEnabled:!lockedOrNotRunningMaintenance];
    [standardRunLoadButton setEnabled:!lockedOrNotRunningMaintenance];
    //Do not lock detector state bits to the operator
    for(int irow=0;irow<21;irow++){
        [[runTypeWordMatrix cellAtRow:irow column:0] setEnabled:!lockedOrNotRunningMaintenance];
    }
    [standardRunVersionPopupMenu setEnabled:!locked && [standardRunVersionPopupMenu numberOfItems]>0]; //allow to change version when in expert mode
    [timedRunCB setEnabled:!runInProgress];
    [timeLimitField setEnabled:!lockedOrNotRunningMaintenance];
    [repeatRunCB setEnabled:!lockedOrNotRunningMaintenance];
    [orcaDBIPAddressPU setEnabled:!lockedOrNotRunningMaintenance];
    [debugDBIPAddressPU setEnabled:!lockedOrNotRunningMaintenance];
    [mtcPort setEnabled:!lockedOrNotRunningMaintenance];
    [mtcHost setEnabled:!lockedOrNotRunningMaintenance];
    [xl3Port setEnabled:!lockedOrNotRunningMaintenance];
    [xl3Host setEnabled:!lockedOrNotRunningMaintenance];
    [dataPort setEnabled:!lockedOrNotRunningMaintenance];
    [dataHost setEnabled:!lockedOrNotRunningMaintenance];
    [logPort setEnabled:!lockedOrNotRunningMaintenance];
    [logHost setEnabled:!lockedOrNotRunningMaintenance];
    [orcaDBUser setEnabled:!lockedOrNotRunningMaintenance];
    [orcaDBPswd setEnabled:!lockedOrNotRunningMaintenance];
    [orcaDBName setEnabled:!lockedOrNotRunningMaintenance];
    [orcaDBPort setEnabled:!lockedOrNotRunningMaintenance];
    [orcaDBClearButton setEnabled:!lockedOrNotRunningMaintenance];
    [debugDBUser setEnabled:!lockedOrNotRunningMaintenance];
    [debugDBPswd setEnabled:!lockedOrNotRunningMaintenance];
    [debugDBName setEnabled:!lockedOrNotRunningMaintenance];
    [debugDBPort setEnabled:!lockedOrNotRunningMaintenance];
    [debugDBClearButton setEnabled:!lockedOrNotRunningMaintenance];    
    
    //Display status
    if(![gSecurity numberItemsUnlocked]){
        [lockStatusTextField setStringValue:@"OPERATOR MODE"];
        [lockStatusTextField setBackgroundColor:snopBlueColor];
    }
    else if(runInProgress){
        [lockStatusTextField setStringValue:@"RUN IN PROGRESS"];
        [lockStatusTextField setBackgroundColor:snopGreenColor];

        if([runControl runType] & kMaintenanceRun){
            [lockStatusTextField setStringValue:@"RUN IN MAINTENANCE"];
            [lockStatusTextField setBackgroundColor:snopOrangeColor];
        }
        else if ([runControl runType] & kDiagnosticRun){
            [lockStatusTextField setStringValue:@"DIAGNOSTIC RUN"];
            [lockStatusTextField setBackgroundColor:snopOrangeColor];
        }

    }
    else{
        [lockStatusTextField setStringValue:@"EXPERT MODE"];
        [lockStatusTextField setBackgroundColor:snopRedColor];
    }
    
}

- (void) runsECAChanged:(NSNotification*)aNotification
{

    //Refresh values in GUI to match the model
    int index = [[model anECARun] ECA_pattern];
    if(index < 0)
    {
        NSLogColor([NSColor redColor], @"ECA bad index returned\n");
        return;
    }
    [ECApatternPopUpButton selectItemAtIndex:index];
    [ECAtypePopUpButton selectItemWithTitle:[[model anECARun] ECA_type]];
    int integ = [[model anECARun] ECA_tslope_pattern];
    [TSlopePatternTextField setIntValue:integ];
    integ = [[model anECARun] ECA_nevents];
    [ecaNEventsTextField setIntValue:integ];
    [ecaPulserRate setObjectValue:[[model anECARun] ECA_rate]];

    if([[aNotification name] isEqualTo:ORECARunStartedNotification]) [startSingleECAButton setEnabled:false];
    else if([[aNotification name] isEqualTo:ORECARunFinishedNotification]) [startSingleECAButton setEnabled:true];

}

//ECA RUNS
- (IBAction)ecaPatternChangedAction:(id)sender
{
    int value = (int)[ECApatternPopUpButton indexOfSelectedItem];
    [[model anECARun] setECA_pattern:value];
}

- (IBAction)ecaTypeChangedAction:(id)sender
{
    [[model anECARun] setECA_type:[ECAtypePopUpButton titleOfSelectedItem]];
}

- (IBAction)ecaTSlopePatternChangedAction:(id)sender
{
    int value = [TSlopePatternTextField intValue];
    [[model anECARun] setECA_tslope_pattern:value];
}

- (IBAction)ecaNEventsChangedAction:(id)sender
{
    int value = [ecaNEventsTextField intValue];
    [[model anECARun] setECA_nevents:value];
}

- (IBAction)ecaPulserRateAction:(id)sender
{
    [[model anECARun] setECA_rate:[ecaPulserRate objectValue]];
}


- (IBAction)startECAStandardRunAction:(id)sender
{

    NSLogColor([NSColor redColor],@"Not implemented yet. Use the Start Single ECA Run button below. \n");

}

- (IBAction)startECASingleRunAction:(id)sender
{
    
    [model startECARunInParallel];

}


//STANDARD RUNS
- (IBAction)standardRunNewValueAction:(id)sender
{
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtcModel;
    if ([objs count]) {
        mtcModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return;
    }

    int activeCell = [sender selectedRow];
    float raw;
    int threshold_index;
    float threshold_value;
    int units;
    switch (activeCell) {
        //NHIT100HI
        case 0:
            threshold_value = [[sender cellAtRow:0 column:0] floatValue];
            threshold_index = MTC_N100_HI_THRESHOLD_INDEX;
            break;
        //NHIT100MED
        case 1:
            threshold_value = [[sender cellAtRow:1 column:0] floatValue];
            threshold_index = MTC_N100_MED_THRESHOLD_INDEX;
            break;
        //NHIT100LO
        case 2:
            threshold_value = [[sender cellAtRow:2 column:0] floatValue];
            threshold_index = MTC_N100_LO_THRESHOLD_INDEX;
            break;
        //NHIT20
        case 3:
            threshold_value = [[sender cellAtRow:3 column:0] floatValue];
            threshold_index = MTC_N20_THRESHOLD_INDEX;
            break;
        //NHIT20LO
        case 4:
            threshold_value = [[sender cellAtRow:4 column:0] floatValue];
            threshold_index = MTC_N20LB_THRESHOLD_INDEX;
            break;
        //OWLN
        case 5:
            threshold_value = [[sender cellAtRow:5 column:0] floatValue];
            threshold_index = MTC_OWLN_THRESHOLD_INDEX;
            break;
        //ESUMHI
        case 6:
            threshold_value = [[sender cellAtRow:6 column:0] floatValue];
            threshold_index = MTC_ESUMH_THRESHOLD_INDEX;
            break;
        //ESUMLO
        case 7:
            threshold_value = [[sender cellAtRow:7 column:0] floatValue];
            threshold_index = MTC_ESUML_THRESHOLD_INDEX;
            break;
        //OWLEHI
        case 8:
            threshold_value = [[sender cellAtRow:8 column:0] floatValue];
            threshold_index = MTC_OWLEHI_THRESHOLD_INDEX;
            break;
        //OWLELO
        case 9:
            threshold_value = [[sender cellAtRow:9 column:0] floatValue];
            threshold_index = MTC_OWLELO_THRESHOLD_INDEX;
            break;
        //Prescale
        case 10:
            raw = [[sender cellAtRow:10 column:0] floatValue];
            [mtcModel setPrescaleValue:raw];
            return;
            break;
        //Pulser
        case 11:
            raw = [[sender cellAtRow:11 column:0] floatValue];
            [mtcModel setPgtRate:raw];
            return;
            break;
    }
    @try{
        units = [self decideUnitsToUseForRow:activeCell usingModel:mtcModel];
        [mtcModel setThresholdOfType:threshold_index fromUnits:units toValue:threshold_value];
    }
    @catch(NSException *excep) {
        NSLogColor([NSColor redColor], @"Error while trying to set the MTC threshold, reason: %@\n",[excep reason]);
    }
}
- (BOOL) isRowNHit: (int) row {
    return row<6; // All the NHit type thresholds are the first 7...i realize this is a bit weird but it works
    // ...for now
}

- (int) decideUnitsToUseForRow: (int) row usingModel:(id) mtcModel {
    int units;
    if(displayUnitsDecider[row] == UNITS_UNDECIDED)
    {
        if([mtcModel ConversionIsValidForThreshold:view_model_map[row]]) {
            NSString* label = [self isRowNHit:row] ? @"NHits" : @"mV";
            units = [self isRowNHit:row] ? MTC_NHIT_UNITS : MTC_mV_UNITS;
            [[standardRunThreshLabels cellAtRow:row column:0] setStringValue:label];
            displayUnitsDecider[row] = UNITS_CONVERTED;
        }
        else {
            units=  MTC_RAW_UNITS;
            [[standardRunThreshLabels cellAtRow:row column:0] setStringValue:@"Raw DAC Counts"];
            displayUnitsDecider[row] = UNITS_RAW;
        }
    }
    else if (displayUnitsDecider[row] == UNITS_CONVERTED) {
        units = [self isRowNHit:row] ? MTC_NHIT_UNITS : MTC_mV_UNITS;
    }
    else {
        units = MTC_RAW_UNITS;
    }
    return units;
}

-(void) updateThresholdDisplayAt:(int) row isInMask:(BOOL) inMask usingModel:(id) mtcModel andFormatter:(NSFormatter*) formatter
{
    int units = [self decideUnitsToUseForRow:row usingModel:mtcModel];
    float value = [mtcModel getThresholdOfType:view_model_map[row] inUnits:units];

    [[standardRunThresCurrentValues cellAtRow:row column:0] setFloatValue:value];
    [[standardRunThresCurrentValues cellAtRow:row column:0] setFormatter:formatter];

    if(inMask) {
        [[standardRunThresCurrentValues cellAtRow:row column:0] setTextColor:[self snopBlueColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:row column:0] setTextColor:[self snopRedColor]];
    }
}

- (void) mtcDataBaseChanged:(NSNotification*)aNotification
{
    if(aNotification && [[aNotification name] isEqualToString:ORMTCAConversionChanged])
    {
        [self initializeUnits];
    }
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtcModel;
    if ([objs count]) {
        mtcModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return;
    }

    //Setup format
    NSNumberFormatter *thresholdFormatter = [[[NSNumberFormatter alloc] init] autorelease];;
    [thresholdFormatter setFormat:@"##0.0"];

    //GTMask
    int gtmask = [mtcModel gtMask];

    for(int i=0;i<10;i++)
    {
        @try {
            BOOL inMask = ((1<<view_mask_map[i]) & gtmask) !=0;
            [self updateThresholdDisplayAt:i isInMask:inMask usingModel:mtcModel andFormatter:thresholdFormatter];
        } @catch (NSException *exception) {
            NSLogColor([NSColor redColor], @"Error while displaying threshold. Reason:%@\n.",[exception reason]);
        }
    }

    //Prescale
    [[standardRunThresCurrentValues cellAtRow:10 column:0] setFloatValue:[mtcModel prescaleValue]];
    [[standardRunThresCurrentValues cellAtRow:10 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 11) & 1){
        [[standardRunThresCurrentValues cellAtRow:10 column:0] setTextColor:[self snopBlueColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:10 column:0] setTextColor:[self snopRedColor]];
    }
    //Pulser
    [[standardRunThresCurrentValues cellAtRow:11 column:0] setFloatValue:[mtcModel pgtRate]];
    [[standardRunThresCurrentValues cellAtRow:11 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 10) & 1){
        [[standardRunThresCurrentValues cellAtRow:11 column:0] setTextColor:[self snopBlueColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:11 column:0] setTextColor:[self snopRedColor]];
    }
    if(aNotification && [[aNotification name] isEqualToString:ORMTCAConversionChanged])
    {
        [self redisplayThresholdValuesUsingModel:mtcModel];
    }
    
}

- (IBAction)loadStandardRunFromDBAction:(id)sender
{
    
    NSString *standardRun = [standardRunPopupMenu objectValueOfSelectedItem];
    NSString *standardRunVer = [standardRunVersionPopupMenu objectValueOfSelectedItem];

    [model loadStandardRun:standardRun withVersion: standardRunVer];
    [model loadSettingsInHW];
    
}

- (IBAction)saveStandardRunToDBAction:(id)sender
{
    
    NSString *standardRun = [standardRunPopupMenu objectValueOfSelectedItem];
    NSString *standardRunVer = [standardRunVersionPopupMenu objectValueOfSelectedItem];
    
    [model saveStandardRun:standardRun withVersion:standardRunVer];
    [self displayThresholdsFromDB];
    
}

// Create a new SR item if doesn't exist, set the runType string value and query the DB to display the trigger configuration
- (IBAction)standardRunPopupAction:(id)sender
{
    
    NSString *standardRun = [[standardRunPopupMenu stringValue] uppercaseString];
    [standardRunPopupMenu setStringValue:standardRun];
    //Create new SR if does not exist
    if ([standardRunPopupMenu indexOfItemWithObjectValue:standardRun] == NSNotFound && [standardRun isNotEqualTo:@""]){
        BOOL cancel = ORRunAlertPanel([NSString stringWithFormat:@"Creating new Standard Run: \"%@\"", standardRun],@"Is this really what you want?",@"Cancel",@"Yes, Make New Standard Run",nil);
        if(cancel){
            [standardRunPopupMenu selectItemWithObjectValue:[model standardRunType]];
            [standardRunVersionPopupMenu selectItemWithObjectValue:[model standardRunVersion]];
            return;
        }
        else{
            [standardRunPopupMenu addItemWithObjectValue:standardRun];
            [standardRunVersionPopupMenu addItemWithObjectValue:@"DEFAULT"];
            [model saveStandardRun:standardRun withVersion:@"DEFAULT"];
        }
    }
    
    //Set run type name
    if(![[model standardRunType] isEqualToString:standardRun]){
        [model setStandardRunType:standardRun];
    }
    
}

- (IBAction)standardRunVersionPopupAction:(id)sender {
    
    NSString *standardRun = [[standardRunPopupMenu stringValue] uppercaseString];
    NSString *standardRunVer = [[standardRunVersionPopupMenu stringValue] uppercaseString];
    [standardRunVersionPopupMenu setStringValue:standardRunVer];

    //Create new SR version if does not exist
    if ([standardRunVersionPopupMenu indexOfItemWithObjectValue:standardRunVer] == NSNotFound && [standardRunVer isNotEqualTo:@""]){

        if([standardRun isEqualToString:@"DIAGNOSTIC"]){
            NSLog(@"You cannot create a version for a DIAGNOSTIC run.\n");
            return;
        }

        BOOL cancel = ORRunAlertPanel([NSString stringWithFormat:@"Creating new Version: \"%@\" of Standard Run: \"%@\"", standardRunVer, standardRun], @"Is this really what you want?",@"Cancel",@"Yes, Make New Version",nil);
        if(cancel){
            [standardRunVersionPopupMenu selectItemWithObjectValue:[model standardRunVersion]];
        }
        else{
            [standardRunVersionPopupMenu addItemWithObjectValue:standardRunVer];
            [standardRunVersionPopupMenu selectItemWithObjectValue:standardRunVer];
            [model saveStandardRun:standardRun withVersion:standardRunVer];
        }
    }
    
    //Set run type name
    if(![[model standardRunVersion] isEqualToString:standardRunVer]){
        [model setStandardRunVersion:standardRunVer];
    }
}

//Run Type Word
-(void) runTypeWordChanged:(NSNotification*)aNote
{
    
    unsigned long currentRunWord = [runControl runType];

    [model setRunTypeWord:currentRunWord];
    //Update display
    for(int i=0;i<32;i++){
        [[runTypeWordMatrix cellAtRow:i column:0] setState:(currentRunWord &(1L<<i))!=0];
    }
    
}

- (void) redisplayThresholdValuesUsingModel: (id)mtcModel {
    int units;
    float value;
    for(int i=0; i<10; i++) {
        if(thresholdsFromDB[i] > 0) {
            units = [self decideUnitsToUseForRow:i usingModel:mtcModel];
            value = [mtcModel convertThreshold:thresholdsFromDB[i] OfType:view_model_map[i] fromUnits:MTC_RAW_UNITS toUnits:units];
            [[standardRunThresStoredValues cellAtRow:i column:0] setFloatValue:value];
        }
    }
}

- (void) updateSingleDBThresholdDisplayForRow:(int) row inMask:(BOOL) inMask withModel:(id) mtcModel withFormatter:(NSFormatter*) formatter toValue:(float) raw {
    float value;
    int units;
    @try {
        units = [self decideUnitsToUseForRow:row usingModel:mtcModel];
        value = [mtcModel convertThreshold:raw OfType:view_model_map[row] fromUnits:MTC_RAW_UNITS toUnits:units];
    } @catch (NSException *excep) {
        NSLogColor([NSColor redColor], @"Failed to convert the thresholds from raw units. Reason: %@\n",[excep reason]);
    }
    [[standardRunThresStoredValues cellAtRow:row column:0] setFormatter:formatter];
    [[standardRunThresStoredValues cellAtRow:row column:0] setFloatValue:value];
    if(inMask) {
        [[standardRunThresStoredValues cellAtRow:row column:0] setTextColor:[self snopBlueColor]];
    } else{
        [[standardRunThresStoredValues cellAtRow:row column:0] setTextColor:[self snopRedColor]];
    }
    thresholdsFromDB[row] = raw;
}

//Query the DB for the selected Standard Run name and version
//and display the values in the GUI.
-(void) displayThresholdsFromDB
{

    /* Get models */
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtcModel;
    if ([objs count]) {
        mtcModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return;
    }

    NSMutableDictionary* runSettings = [[[model standardRunCollection] objectForKey:[model standardRunType]] objectForKey:[model standardRunVersion]];
    if(runSettings == nil){
        NSLogColor([NSColor redColor], @"An error occurred: Refresh manually standard runs. \n");
        for (int i=0; i<[standardRunThresStoredValues numberOfRows];i++) {
            [[standardRunThresStoredValues cellAtRow:i column:0] setStringValue:@"--"];
            [[standardRunThresStoredValues cellAtRow:i column:0] setTextColor:[self snopRedColor]];
            if(i <10){
                thresholdsFromDB[i] = -1;
            }
        }
        for(int ibit=0; ibit<21; ibit++){ //Data quality bits are not stored in the SR
            [[runTypeWordSRMatrix cellAtRow:ibit column:0] setState:0];
        }
        return;
    }

    //Get run type word first
    unsigned long dbruntypeword = [[runSettings valueForKey:@"run_type_word"] unsignedLongValue];

    //Setup format
    NSNumberFormatter *thresholdFormatter = [[[NSNumberFormatter alloc] init] autorelease];;
    [thresholdFormatter setFormat:@"##0.0"];
    
    //If in DIAGNOSTIC run: display null threshold values
    if([[model standardRunType] isEqualToString:@"DIAGNOSTIC"]){
        for (int i=0; i<[standardRunThresStoredValues numberOfRows];i++) {
            [[standardRunThresStoredValues cellAtRow:i column:0] setStringValue:@"--"];
            [[standardRunThresStoredValues cellAtRow:i column:0] setTextColor:[self snopRedColor]];
            if(i <10){
                thresholdsFromDB[i] = -1;
            }
        }
        for(int ibit=0; ibit<21; ibit++){ //Data quality bits are not stored in the SR
            [[runTypeWordSRMatrix cellAtRow:ibit column:0] setState:0];
        }
    //If in non-DIAGNOSTIC run: display DB threshold values
    } else {
        float mVolts;
        int gtmask = [[runSettings valueForKey:GTMaskSerializationString] intValue];
        
        for(int i=0;i<10;i++) {
            float raw = [[runSettings valueForKey:[mtcModel stringForThreshold:view_model_map[i]]] floatValue];
            BOOL inMask = ((1<< view_mask_map[i]) & gtmask) != 0;
            [self updateSingleDBThresholdDisplayForRow:i inMask:inMask withModel:mtcModel withFormatter:thresholdFormatter toValue:raw];
        }

        //Prescale
        mVolts = [[runSettings valueForKey:PrescaleValueSerializationString] floatValue];
        [[standardRunThresStoredValues cellAtRow:10 column:0] setFloatValue:mVolts];
        [[standardRunThresStoredValues cellAtRow:10 column:0] setFormatter:thresholdFormatter];
        if((gtmask >> 11) & 1){
            [[standardRunThresStoredValues cellAtRow:10 column:0] setTextColor:[self snopBlueColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:10 column:0] setTextColor:[self snopRedColor]];
        }
        //Pulser
        mVolts = [[runSettings valueForKey:PulserRateSerializationString] floatValue];
        [[standardRunThresStoredValues cellAtRow:11 column:0] setFloatValue:mVolts];
        [[standardRunThresStoredValues cellAtRow:11 column:0] setFormatter:thresholdFormatter];
        if((gtmask >> 10) & 1){
            [[standardRunThresStoredValues cellAtRow:11 column:0] setTextColor:[self snopBlueColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:11 column:0] setTextColor:[self snopRedColor]];
        }
    }
    
    //Display runtype word
    for(int ibit=0; ibit<21; ibit++){ //Data quality bits are not stored in the SR
        if((dbruntypeword >> ibit) & 1){
            [[runTypeWordSRMatrix cellAtRow:ibit column:0] setState:1];
        } else{
            [[runTypeWordSRMatrix cellAtRow:ibit column:0] setState:0];
        }
    }

}

- (IBAction) refreshStandardRunsAction:(id)sender
{
    [model refreshStandardRunsFromDB];
}

-(void) standardRunsCollectionChanged:(NSNotification*)aNote
{
    // Clear popup menus
    [standardRunPopupMenu removeAllItems];
    [standardRunVersionPopupMenu removeAllItems];

    //Populate run type popup menu
    for(NSString* aStandardRunType in [model standardRunCollection]){
        [standardRunPopupMenu addItemWithObjectValue:aStandardRunType];
    }
}

-(void) refreshStandardRunVersions
{

    [standardRunVersionPopupMenu deselectItemAtIndex:[standardRunVersionPopupMenu indexOfSelectedItem]];
    [standardRunVersionPopupMenu removeAllItems];

    NSString* standardRunVersion = [model standardRunVersion];
    //Populate run version popup menu
    for(NSString* aStandardRunVersion in [[model standardRunCollection] objectForKey:[model standardRunType]]){
        [standardRunVersionPopupMenu addItemWithObjectValue:aStandardRunVersion];
    }

    if([standardRunVersionPopupMenu numberOfItems] == 0 || standardRunVersion == nil || [standardRunVersion isEqualToString:@""]){
        return;
    }
    if([standardRunVersionPopupMenu indexOfItemWithObjectValue:standardRunVersion] == NSNotFound){
        [standardRunVersionPopupMenu selectItemWithObjectValue:standardRunVersion];
        return;
    }
    else{
        [standardRunVersionPopupMenu selectItemWithObjectValue:standardRunVersion];
    }

}
@end
