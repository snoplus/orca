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
#import "SNOPGlobals.h"

NSString* ORSNOPRequestHVStatus = @"ORSNOPRequestHVStatus";

@implementation SNOPController

@synthesize
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
    [self setSnopBlueColor:[NSColor colorWithSRGBRed:153./255. green:204./255. blue:255./255. alpha:1]];
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

    [doggy_icon start_animation];

    [self mtcDataBaseChanged:nil];
    //Update runtype word
    [self runTypeWordChanged:nil];
    //Lock Standard Runs menus at init
    if([model standardRunType] == nil){
        [standardRunPopupMenu setEnabled:false];
        [standardRunVersionPopupMenu setEnabled:false];
    }
    else{
        [self refreshStandardRunsAction:nil];
    }
    if(!doggy_icon)
    {
        doggy_icon = [[RunStatusIcon alloc] init];
    }
    //Pull the information from the SMELLIE DB
    [model getSmellieRunListInfo];
    [super awakeFromNib];
    [self performSelector:@selector(updateWindow)withObject:self afterDelay:0.1];
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
                         name : ORELLIERunFinished
                        object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStatusChanged:)
                         name: ORRunStatusChangedNotification
                       object: nil];
    
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
                         name : ORSNOPRunsLockNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runsECAChanged:)
                         name : ORSNOPModelRunsECAChangedNotification
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(mtcDataBaseChanged:)
                         name : ORMTCModelMtcDataBaseChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateSettings:)
                         name : @"SNOPSettingsChanged"
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

-(IBAction)setTellie:(id)sender
{
    //Collect a series of objects from the ELLIEModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];
    NSArray * setSafeStates = @[@"0",@"0",@"0"]; //30 is the flag for setting smellie to its safe states
    [theELLIEModel callPythonScript:@"/Users/snotdaq/Desktop/orca-python/tellie/tellie_orca_script.py" withCmdLineArgs:setSafeStates];
}

-(IBAction)fireTellie:(id)sender
{
    
}

//Select SR and look for versions
-(void) SRTypeChanged:(NSNotification*)aNote
{
    NSString* standardRun = [model standardRunType];
    if([standardRunPopupMenu numberOfItems] == 0 || standardRun == nil || [standardRun isEqualToString:@""]){
        NSLogColor([NSColor redColor],@"Please refresh the Standard Runs DB. \n");
        return;
    }
    if([standardRunPopupMenu indexOfItemWithObjectValue:standardRun] == NSNotFound){
        NSLogColor([NSColor redColor],@"Standard Run \"%@\" does not exist in DB. \n",standardRun);
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
        NSLogColor([NSColor redColor],@"Please refresh the Standard Runs DB. \n",standardRunVersion);
        return;
    }
    if([standardRunVersionPopupMenu indexOfItemWithObjectValue:standardRunVersion] == NSNotFound){
        NSLogColor([NSColor redColor],@"Standard Run Version \"%@\" does not exist in DB. \n",standardRunVersion);
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
    
    //Make sure we are not running any RunScripts
    [runControl setSelectedRunTypeScript:0];

    //Load selected SR in case the user didn't click enter
    NSString *standardRun = [[standardRunPopupMenu objectValueOfSelectedItem] copy];
    NSString *standardRunVersion = [[standardRunVersionPopupMenu objectValueOfSelectedItem] copy];
    
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
        NSLogColor([NSColor redColor],@"Standard Run Not Set. Select a valid run from the drop down menu \n");
        return;
    }
    if([standardRunVersion isEqualToString:@""] || standardRunVersion == nil){
        NSLogColor([NSColor redColor],@"Standard Run Version Not Set. Select a valid run from the drop down menu \n");
        return;
    }
    
    [model setStandardRunType:standardRun];
    [model setStandardRunVersion:standardRunVersion];

    //Load the standard run and stop run initialization if failed
    [model setLastStandardRunType:[model standardRunType]];
    [model setLastStandardRunVersion:[model standardRunVersion]];
    [model setLastRunTypeWord:[model runTypeWord]];
    NSString* _lastRunTypeWord = [NSString stringWithFormat:@"0x%X",(int)[model runTypeWord]];
    [model setLastRunTypeWordHex:_lastRunTypeWord]; //FIXME: revisit if we go over 32 bits
    if(![model loadStandardRun:standardRun withVersion:standardRunVersion]) return;
    
    //Start or restart the run
    if([runControl isRunning])[runControl restartRun];
    else [runControl startRun];
    
    [standardRun release];
    [standardRunVersion release];
}

- (IBAction)resyncRunAction:(id)sender
{
    /* A resync run does a hard stop and start without the user having to hit
     * stop run and then start run. Doing this resets the GTID, which resyncs
     * crate 9 after it goes out of sync :).
     *
     * Does not load the standard run settings. */
    [model setResync:YES];
    [runControl restartRun];
}


- (IBAction) stopRunAction:(id)sender
{
    [runControl quitSelectedRunScript];
    [self endEditing];
    [runControl performSelector:@selector(haltRun)withObject:nil afterDelay:.1];
}

- (void) runStatusChanged:(NSNotification*)aNotification
{
    [startRunButton setEnabled:true];
    
    if([runControl runningState] == eRunInProgress){
        [startRunButton setTitle:@"RESTART"];
        [lightBoardView setState:kGoLight];
        [runStatusField setStringValue:@"Running"];
        [doggy_icon start_animation];
	}
	else if([runControl runningState] == eRunStopped){
        [startRunButton setTitle:@"START"];
        [lightBoardView setState:kStoppedLight];
        [runStatusField setStringValue:@"Stopped"];
        [doggy_icon stop_animation];
	}
	else if([runControl runningState] == eRunStarting || [runControl runningState] == eRunStopping || [runControl runningState] == eRunBetweenSubRuns){
        if([runControl runningState] == eRunStarting){
            //The run started so update the display
            [runStatusField setStringValue:@"Starting"];
            [startRunButton setEnabled:false];
            [startRunButton setTitle:@"STARTING..."];
        }
        else {
            //Do nothing
        }
        [lightBoardView setState:kCautionLight];
	}

    if ([runControl isRunning] && ([runControl runType] & ECA_RUN)) {
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
- (IBAction) callSmellieSettings:(id)sender
{
    //remove any old smellie file values
    self.smellieRunFileList = nil;
    NSMutableDictionary *tmp = [[NSMutableDictionary alloc] initWithDictionary:[model smellieTestFct]];
    
    //remove all the old items
    [smellieRunFileNameField removeAllItems];
    
    //Fill lthe combo box with information
    for(id key in tmp){
        id loopValue = [tmp objectForKey:key];
        [smellieRunFileNameField addItemWithObjectValue:[NSString stringWithFormat:@"%@",[loopValue objectForKey:@"run_name"]]];
    }
    
    [smellieRunFileNameField setEnabled:YES];
    [smellieLoadRunFile setEnabled:YES];
    
    self.smellieRunFileList = tmp;
    [tmp release];
    
}

-(IBAction)loadSmellieRunAction:(id)sender
{
    if([smellieRunFileNameField objectValueOfSelectedItem]!= nil)
    {
        [smellieStartRunButton setEnabled:YES];
        [smellieStopRunButton setEnabled:YES];
        [smellieEmergencyStop setEnabled:YES];
        
        //Loop through all the smellie files in the run list
        for(id key in self.smellieRunFileList){
            
            id currentRunFile = [self.smellieRunFileList objectForKey:key];
            
            NSString *thisRunFile = [currentRunFile objectForKey:@"run_name"];
            NSString *requestedRunFile = [smellieRunFileNameField objectValueOfSelectedItem];
            
            if( [thisRunFile isEqualToString:requestedRunFile]){
                
                NSLog(@"%", [self smellieRunFile]);
                // If it's an old run file, add superK fields, set to zero
                if(![smellieRunFile objectForKey:@"superK_laser_on"]){
                    [smellieRunFile setValue:0 forKey:@"superK_laser_on"];
                    [smellieRunFile setValue:0 forKey:@"superK_wavelength_low"];
                    [smellieRunFile setValue:0 forKey:@"superK_wavelength_high"];
                    [smellieRunFile setValue:0 forKey:@"superK_wavelength_step"];
                    [smellieRunFile setValue:0 forKey:@"superK_num_wavelength_steps"];
                }
                [self setSmellieRunFile:currentRunFile];

                [loadedSmellieRunNameLabel setStringValue:[smellieRunFile objectForKey:@"run_name"]];
                [model setSmellieRunNameLabel:[NSString stringWithFormat:@"%@",[smellieRunFile objectForKey:@"run_name"]]];
                [loadedSmellieTriggerFrequencyLabel setStringValue:[smellieRunFile objectForKey:@"trigger_frequency"]];
                [loadedSmellieOperationModeLabel setStringValue:[smellieRunFile objectForKey:@"operation_mode"]];
                [loadedSmellieMaxIntensityLaser setStringValue:[smellieRunFile objectForKey:@"max_laser_intensity"]];
                [loadedSmellieMinIntensityLaser setStringValue:[smellieRunFile objectForKey:@"min_laser_intensity"]];
                
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
                laserCounter = laserCounter + [[self.smellieRunFile objectForKey:@"SuperK_laser_on"] intValue];
                
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
                float timePerLaserPerFibrePerIntensity = (1.0/triggerFrequency)*numberTriggersPerLoop + 1.0; //13.0seconds forthe sub run incrementations
                float numberOfIntensities = [[smellieRunFile objectForKey:@"num_intensity_steps"] floatValue];
                float timePerLaserPerFibre = timePerLaserPerFibrePerIntensity*numberOfIntensities;
                float timePerLaser = timePerLaserPerFibre*(1.0*fibreCounter);
                
                //final approx time plus the laser switchover time
                float totalTime = timePerLaser*(1.0*laserCounter) + (30*laserCounter);
                
                //return total approx time in minutes
                totalTime = totalTime/60.0;
                
                [loadedSmellieApproxTimeLabel setStringValue:[NSString stringWithFormat:@"%0.1f",totalTime]];
                [loadedSmellieLasersLabel setStringValue:smellieLaserString];
                
                //unlock the control buttons
                //[smellieCheckInterlock setEnabled:YES];
                [smellieLaserString release];
                
            }
        }
    }
    else{
        //[smellieCheckInterlock setEnabled:NO];
        NSLog(@"Main SNO+ Control:Please choose a Smellie Run File from selection\n");
    }
}

- (IBAction) startSmellieRunAction:(id)sender
{
    [smellieLoadRunFile setEnabled:NO];
    [smellieRunFileNameField setEnabled:NO];
    [smellieStopRunButton setEnabled:YES];
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
    //Method for completing this without a new thread
    //[theELLIEModel startSmellieRun:smellieRunFile];
    
    //if([model isRunTypeMaskedIn:@"Smellie"]){
    
    smellieThread = [[NSThread alloc] initWithTarget:theELLIEModel selector:@selector(startSmellieRun:) object:smellieRunFile];
    [smellieThread start];

    //}
    //else{
    //    NSLog(@"Smellie Run Type is not masked in. Please mask this in and try again \n");
    //}
    //[NSThread detachNewThreadSelector:@selector(startSmellieRun:) toTarget:theELLIEModel withObject:smellieRunFile];
}

- (IBAction) stopSmellieRunAction:(id)sender
{
    [smellieLoadRunFile setEnabled:YES];
    [smellieRunFileNameField setEnabled:YES];
    [smellieStartRunButton setEnabled:YES];
    [smellieStopRunButton setEnabled:NO];
    //[smellieCheckInterlock setEnabled:YES];

    //unassign the run type as a SMELLIE run
    //[model setRunType:kRunUndefined];

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

    //Method for completing this without a new thread
    [theELLIEModel stopSmellieRun];

    [smellieThread cancel];
    NSLog(@"IS THREAD CANCELED? : %@", [[NSThread currentThread] isCancelled]);
    [smellieThread release];
    smellieThread = nil;

    //wait for the current loop to finish
    //move straight to a maintainence run
    //communicate with smellie model
    //TODO:Make a note in the datastream that this happened
}

- (IBAction) emergencySmellieStopAction:(id)sender
{
    [smellieLoadRunFile setEnabled:NO];
    [smellieRunFileNameField setEnabled:NO];
    [smellieStartRunButton setEnabled:NO];
    [smellieStopRunButton setEnabled:YES];
    
    //unassign the run type as a SMELLIE run
    //[model setRunType:kRunUndefined];
    //[smellieCheckInterlock setEnabled:NO];
    //turn the interlock off
    //(if a smellie run is currently operating) start a maintainence run
    //reset the smellie laser system
    //TODO:Make a note in the datastream that this happened
}

- (IBAction) runsLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORSNOPRunsLockNotification to:[sender intValue] forWindow:[self window]];
}

- (IBAction)refreshRunWordLabels:(id)sender
{
    NSArray* theNames = [runControl runTypeNames];
    int n = [theNames count];
    for(int i=1;i<n;i++){
        [[runTypeWordMatrix cellAtRow:i column:0] setTitle:[theNames objectAtIndex:i]];
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
    [startSingleECAButton setEnabled:!lockedOrNotRunningMaintenance];
    [ECApatternPopUpButton setEnabled:!lockedOrNotRunningMaintenance];
    [ECAtypePopUpButton setEnabled:!lockedOrNotRunningMaintenance];
    [TSlopePatternTextField setEnabled:!lockedOrNotRunningMaintenance];
    [ecaNEventsTextField setEnabled:!lockedOrNotRunningMaintenance];
    [ecaPulserRate setEnabled:!lockedOrNotRunningMaintenance];
    [standardRunThresCurrentValues setEnabled:!lockedOrNotRunningMaintenance];
    [standardRunSaveButton setEnabled:!lockedOrNotRunningMaintenance];
    [standardRunLoadButton setEnabled:!lockedOrNotRunningMaintenance];
    [runTypeWordMatrix setEnabled:!lockedOrNotRunningMaintenance];
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
    [lockStatusTextField setStringValue:@"EXPERT MODE"];
    [lockStatusTextField setBackgroundColor:snopRedColor];
    if(lockedOrNotRunningMaintenance){
        if(locked){
            [lockStatusTextField setStringValue:@"OPERATOR MODE"];
            [lockStatusTextField setBackgroundColor:snopBlueColor];
        }
        else{
            [lockStatusTextField setStringValue:@"RUN IN PROGRESS"];
            [lockStatusTextField setBackgroundColor:snopGreenColor];
        }
    }
    else if(runInProgress){
        [lockStatusTextField setStringValue:@"RUNNING IN MAINTENACE"];
        [lockStatusTextField setBackgroundColor:snopOrangeColor];
    }
    
}

- (void) runsECAChanged:(NSNotification*)aNotification
{
    //Refresh values in GUI to match the model
    int index = [model ECA_pattern] -1;
    if(index < 0)
    {
        NSLogColor([NSColor redColor], @"ECA bad index returned\n");
        return;
    }
    [ECApatternPopUpButton selectItemAtIndex:index];
    [ECAtypePopUpButton selectItemWithTitle:[model ECA_type]];
    int integ = [model ECA_tslope_pattern];
    [TSlopePatternTextField setIntValue:integ];
    integ = [model ECA_nevents];
    [ecaNEventsTextField setIntValue:integ];
    [ecaPulserRate setObjectValue:[model ECA_rate]];
}

//ECA RUNS
- (IBAction)ecaPatternChangedAction:(id)sender
{
    int value = (int)[ECApatternPopUpButton indexOfSelectedItem];
    [model setECA_pattern:value+1];
}

- (IBAction)ecaTypeChangedAction:(id)sender
{
    [model setECA_type:[ECAtypePopUpButton titleOfSelectedItem]];
}

- (IBAction)ecaTSlopePatternChangedAction:(id)sender
{
    int value = [TSlopePatternTextField intValue];
    [model setECA_tslope_pattern:value];
}

- (IBAction)ecaNEventsChangedAction:(id)sender
{
    int value = [ecaNEventsTextField intValue];
    [model setECA_nevents:value];
}

- (IBAction)ecaPulserRateAction:(id)sender
{
    [model setECA_rate:[ecaPulserRate objectValue]];
}


- (IBAction)startECAStandardRunAction:(id)sender
{

    NSArray* scriptList = [runControl runScriptList];
    if([scriptList containsObject:@"ECAStandardRun"]){
        if([gOrcaGlobals runInProgress]){
            NSLogColor([NSColor redColor],@"ECA run cannot start with an ongoing run. Stop the run first.\n");
        }
        else{
            [runControl selectRunTypeScriptByName:@"ECAStandardRun"];
            [runControl startRun];
        }
    }
    else{
        NSLogColor([NSColor redColor],@"ECA Standard Run not configured. Please, set the RunScript properly. ECA run won't start. \n");
    }

}

- (IBAction)startECASingleRunAction:(id)sender
{
    
    NSArray* scriptList = [runControl runScriptList];
    if([scriptList containsObject:@"ECASingleRun"]){
        if([gOrcaGlobals runInProgress]){
            NSLogColor([NSColor redColor],@"ECA run cannot start with an ongoing run. Stop the run first.\n");
        }
        else{
            [runControl selectRunTypeScriptByName:@"ECASingleRun"];
            [runControl startRun];
        }
    }
    else{
        NSLogColor([NSColor redColor],@"ECA Single Run not configured. Please, set the RunScript properly. ECA run won't start. \n");
    }

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
    //NHIT100HI
    float nHits;
    float mVolts;
    float dcOffset;
    float mVperNHit;
    float raw;
    if(activeCell == 0) {
        nHits = [[sender cellAtRow:0 column:0] floatValue];
        dcOffset  = [mtcModel dbFloatByIndex:kNHit100HiThreshold + kNHitDcOffset_Offset];
        mVperNHit = [mtcModel dbFloatByIndex:kNHit100HiThreshold + kmVoltPerNHit_Offset];
        raw = [mtcModel NHitsToRaw:nHits dcOffset:dcOffset mVperNHit:mVperNHit];
        [mtcModel setDbFloat: raw forIndex:kNHit100HiThreshold];
    }
    //NHIT100MED
    if(activeCell == 1) {
        nHits = [[sender cellAtRow:1 column:0] floatValue];
        dcOffset  = [mtcModel dbFloatByIndex:kNHit100MedThreshold + kNHitDcOffset_Offset];
        mVperNHit = [mtcModel dbFloatByIndex:kNHit100MedThreshold + kmVoltPerNHit_Offset];
        raw = [mtcModel NHitsToRaw:nHits dcOffset:dcOffset mVperNHit:mVperNHit];
        [mtcModel setDbFloat: raw forIndex:kNHit100MedThreshold];
    }
    //NHIT100LO
    if(activeCell == 2) {
        nHits = [[sender cellAtRow:2 column:0] floatValue];
        dcOffset  = [mtcModel dbFloatByIndex:kNHit100LoThreshold + kNHitDcOffset_Offset];
        mVperNHit = [mtcModel dbFloatByIndex:kNHit100LoThreshold + kmVoltPerNHit_Offset];
        raw = [mtcModel NHitsToRaw:nHits dcOffset:dcOffset mVperNHit:mVperNHit];
        [mtcModel setDbFloat: raw forIndex:kNHit100LoThreshold];
    }
    //NHIT20
    if(activeCell == 3) {
        nHits = [[sender cellAtRow:3 column:0] floatValue];
        dcOffset  = [mtcModel dbFloatByIndex:kNHit20Threshold + kNHitDcOffset_Offset];
        mVperNHit = [mtcModel dbFloatByIndex:kNHit20Threshold + kmVoltPerNHit_Offset];
        raw = [mtcModel NHitsToRaw:nHits dcOffset:dcOffset mVperNHit:mVperNHit];
        [mtcModel setDbFloat: raw forIndex:kNHit20Threshold];
    }
    //NHIT20LO
    if(activeCell == 4) {
        nHits = [[sender cellAtRow:4 column:0] floatValue];
        dcOffset  = [mtcModel dbFloatByIndex:kNHit20LBThreshold + kNHitDcOffset_Offset];
        mVperNHit = [mtcModel dbFloatByIndex:kNHit20LBThreshold + kmVoltPerNHit_Offset];
        raw = [mtcModel NHitsToRaw:nHits dcOffset:dcOffset mVperNHit:mVperNHit];
        [mtcModel setDbFloat: raw forIndex:kNHit20LBThreshold];
    }
    //OWLN
    if(activeCell == 5) {
        nHits = [[sender cellAtRow:5 column:0] floatValue];
        dcOffset  = [mtcModel dbFloatByIndex:kOWLNThreshold + kNHitDcOffset_Offset];
        mVperNHit = [mtcModel dbFloatByIndex:kOWLNThreshold + kmVoltPerNHit_Offset];
        raw = [mtcModel NHitsToRaw:nHits dcOffset:dcOffset mVperNHit:mVperNHit];
        [mtcModel setDbFloat: raw forIndex:kOWLNThreshold];
    }
    //ESUMHI
    if(activeCell == 6) {
        mVolts = [[sender cellAtRow:6 column:0] floatValue];
        raw = [mtcModel mVoltsToRaw:mVolts];
        [mtcModel setDbFloat: raw forIndex:kESumHiThreshold];
    }
    //ESUMLO
    if(activeCell == 7) {
        mVolts = [[sender cellAtRow:7 column:0] floatValue];
        raw = [mtcModel mVoltsToRaw:mVolts];
        [mtcModel setDbFloat: raw forIndex:kESumLowThreshold];
    }
    //OWLEHI
    if(activeCell == 8) {
        mVolts = [[sender cellAtRow:8 column:0] floatValue];
        raw = [mtcModel mVoltsToRaw:mVolts];
        [mtcModel setDbFloat: raw forIndex:kOWLEHiThreshold];
    }
    //OWLELO
    if(activeCell == 9) {
        mVolts = [[sender cellAtRow:9 column:0] floatValue];
        raw = [mtcModel mVoltsToRaw:mVolts];
        [mtcModel setDbFloat: raw forIndex:kOWLELoThreshold];
    }
    //Prescale
    if(activeCell == 10) {
        raw = [[sender cellAtRow:10 column:0] floatValue];
        [mtcModel setDbFloat: raw forIndex:kNhit100LoPrescale];
    }
    //Pulser
    if(activeCell == 11) {
        raw = [[sender cellAtRow:11 column:0] floatValue];
        [mtcModel setDbFloat: raw forIndex:kPulserPeriod];
    }
}

- (void) mtcDataBaseChanged:(NSNotification*)aNotification
{
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
    int gtmask = [mtcModel dbIntByIndex:kGtMask];
    
    //NHIT100HI
    float mVolts = [mtcModel rawTomVolts:[mtcModel dbFloatByIndex:kNHit100HiThreshold]];
    float dcOffset  = [mtcModel dbFloatByIndex:kNHit100HiThreshold + kNHitDcOffset_Offset];
    float mVperNHit = [mtcModel dbFloatByIndex:kNHit100HiThreshold + kmVoltPerNHit_Offset];
    float nHits = [mtcModel mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
    [[standardRunThresCurrentValues cellAtRow:0 column:0] setFloatValue:nHits];
    [[standardRunThresCurrentValues cellAtRow:0 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 2) & 1){
        [[standardRunThresCurrentValues cellAtRow:0 column:0] setTextColor:[self snopGreenColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:0 column:0] setTextColor:[self snopRedColor]];
    }
    //NHIT100MED
    mVolts = [mtcModel rawTomVolts:[mtcModel dbFloatByIndex:kNHit100MedThreshold]];
    dcOffset  = [mtcModel dbFloatByIndex:kNHit100MedThreshold + kNHitDcOffset_Offset];
    mVperNHit = [mtcModel dbFloatByIndex:kNHit100MedThreshold + kmVoltPerNHit_Offset];
    nHits = [mtcModel mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
    [[standardRunThresCurrentValues cellAtRow:1 column:0] setFloatValue:nHits];
    [[standardRunThresCurrentValues cellAtRow:1 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 1) & 1){
        [[standardRunThresCurrentValues cellAtRow:1 column:0] setTextColor:[self snopGreenColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:1 column:0] setTextColor:[self snopRedColor]];
    }
    //NHIT100LO
    mVolts = [mtcModel rawTomVolts:[mtcModel dbFloatByIndex:kNHit100LoThreshold]];
    dcOffset  = [mtcModel dbFloatByIndex:kNHit100LoThreshold + kNHitDcOffset_Offset];
    mVperNHit = [mtcModel dbFloatByIndex:kNHit100LoThreshold + kmVoltPerNHit_Offset];
    nHits = [mtcModel mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
    [[standardRunThresCurrentValues cellAtRow:2 column:0] setFloatValue:nHits];
    [[standardRunThresCurrentValues cellAtRow:2 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 0) & 1){
        [[standardRunThresCurrentValues cellAtRow:2 column:0] setTextColor:[self snopGreenColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:2 column:0] setTextColor:[self snopRedColor]];
    }
    //NHIT20
    mVolts = [mtcModel rawTomVolts:[mtcModel dbFloatByIndex:kNHit20Threshold]];
    dcOffset  = [mtcModel dbFloatByIndex:kNHit20Threshold + kNHitDcOffset_Offset];
    mVperNHit = [mtcModel dbFloatByIndex:kNHit20Threshold + kmVoltPerNHit_Offset];
    nHits = [mtcModel mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
    [[standardRunThresCurrentValues cellAtRow:3 column:0] setFloatValue:nHits];
    [[standardRunThresCurrentValues cellAtRow:3 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 3) & 1){
        [[standardRunThresCurrentValues cellAtRow:3 column:0] setTextColor:[self snopGreenColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:3 column:0] setTextColor:[self snopRedColor]];
    }
    //NHIT20LO
    mVolts = [mtcModel rawTomVolts:[mtcModel dbFloatByIndex:kNHit20LBThreshold]];
    dcOffset  = [mtcModel dbFloatByIndex:kNHit20LBThreshold + kNHitDcOffset_Offset];
    mVperNHit = [mtcModel dbFloatByIndex:kNHit20LBThreshold + kmVoltPerNHit_Offset];
    nHits = [mtcModel mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
    [[standardRunThresCurrentValues cellAtRow:4 column:0] setFloatValue:nHits];
    [[standardRunThresCurrentValues cellAtRow:4 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 4) & 1){
        [[standardRunThresCurrentValues cellAtRow:4 column:0] setTextColor:[self snopGreenColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:4 column:0] setTextColor:[self snopRedColor]];
    }
    //OWLN
    mVolts = [mtcModel rawTomVolts:[mtcModel dbFloatByIndex:kOWLNThreshold]];
    dcOffset  = [mtcModel dbFloatByIndex:kOWLNThreshold + kNHitDcOffset_Offset];
    mVperNHit = [mtcModel dbFloatByIndex:kOWLNThreshold + kmVoltPerNHit_Offset];
    nHits = [mtcModel mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
    [[standardRunThresCurrentValues cellAtRow:5 column:0] setFloatValue:nHits];
    [[standardRunThresCurrentValues cellAtRow:5 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 7) & 1){
        [[standardRunThresCurrentValues cellAtRow:5 column:0] setTextColor:[self snopGreenColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:5 column:0] setTextColor:[self snopRedColor]];
    }
    //ESUMHI
    [[standardRunThresCurrentValues cellAtRow:6 column:0] setFloatValue:[mtcModel rawTomVolts:[mtcModel dbFloatByIndex:kESumHiThreshold]]];
    [[standardRunThresCurrentValues cellAtRow:6 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 6) & 1){
        [[standardRunThresCurrentValues cellAtRow:6 column:0] setTextColor:[self snopGreenColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:6 column:0] setTextColor:[self snopRedColor]];
    }
    //ESUMLO
    [[standardRunThresCurrentValues cellAtRow:7 column:0] setFloatValue:[mtcModel rawTomVolts:[mtcModel dbFloatByIndex:kESumLowThreshold]]];
    [[standardRunThresCurrentValues cellAtRow:7 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 5) & 1){
        [[standardRunThresCurrentValues cellAtRow:7 column:0] setTextColor:[self snopGreenColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:7 column:0] setTextColor:[self snopRedColor]];
    }
    //OWLEHI
    [[standardRunThresCurrentValues cellAtRow:8 column:0] setFloatValue:[mtcModel rawTomVolts:[mtcModel dbFloatByIndex:kOWLEHiThreshold]]];
    [[standardRunThresCurrentValues cellAtRow:8 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 9) & 1){
        [[standardRunThresCurrentValues cellAtRow:8 column:0] setTextColor:[self snopGreenColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:8 column:0] setTextColor:[self snopRedColor]];
    }
    //OWLELO
    [[standardRunThresCurrentValues cellAtRow:9 column:0] setFloatValue:[mtcModel rawTomVolts:[mtcModel dbFloatByIndex:kOWLELoThreshold]]];
    [[standardRunThresCurrentValues cellAtRow:9 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 8) & 1){
        [[standardRunThresCurrentValues cellAtRow:9 column:0] setTextColor:[self snopGreenColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:9 column:0] setTextColor:[self snopRedColor]];
    }
    //Prescale
    [[standardRunThresCurrentValues cellAtRow:10 column:0] setFloatValue:[mtcModel dbFloatByIndex:kNhit100LoPrescale]];
    [[standardRunThresCurrentValues cellAtRow:10 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 11) & 1){
        [[standardRunThresCurrentValues cellAtRow:10 column:0] setTextColor:[self snopGreenColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:10 column:0] setTextColor:[self snopRedColor]];
    }
    //Pulser
    [[standardRunThresCurrentValues cellAtRow:11 column:0] setFloatValue:[mtcModel dbFloatByIndex:kPulserPeriod]];
    [[standardRunThresCurrentValues cellAtRow:11 column:0] setFormatter:thresholdFormatter];
    if((gtmask >> 10) & 1){
        [[standardRunThresCurrentValues cellAtRow:11 column:0] setTextColor:[self snopGreenColor]];
    } else{
        [[standardRunThresCurrentValues cellAtRow:11 column:0] setTextColor:[self snopRedColor]];
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

//Query the DB for the selected Standard Run name and version
//and display the values in the GUI.
-(void) displayThresholdsFromDB
{
    
    //Get MTC model
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtcModel;
    if ([objs count]) {
        mtcModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return;
    }
    
    //If no SR: display null values
    if([model standardRunType] == nil || [[model standardRunType] isEqualToString:@""]){
        for (int i=0; i<[standardRunThresStoredValues numberOfRows];i++) {
            [[standardRunThresStoredValues cellAtRow:i column:0] setStringValue:@"--"];
        }
        for(int ibit=0; ibit<21; ibit++){ //Data quality bits are not stored in the SR
            [[runTypeWordSRMatrix cellAtRow:ibit column:0] setState:0];
        }
        NSLogColor([NSColor redColor],@"Standard Run not set: make sure the DB is accesible and refresh the standard runs. \n");
        return;
    }
    //If no version: display null values and quit
    if([model standardRunVersion] == nil || [[model standardRunVersion] isEqualToString:@""]){
        for (int i=0; i<[standardRunThresStoredValues numberOfRows];i++) {
            [[standardRunThresStoredValues cellAtRow:i column:0] setStringValue:@"--"];
        }
        for(int ibit=0; ibit<21; ibit++){ //Data quality bits are not stored in the SR
            [[runTypeWordSRMatrix cellAtRow:ibit column:0] setState:0];
        }
        NSLogColor([NSColor redColor],@"Test Standard Run not set: make sure the DB is accesible and refresh the standard runs. \n");
        return;
    }
    
    //Fetch DB and display trigger configuration in GUI
    //Query the OrcaDB and get a dictionary with the parameters
    NSString* urlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/%@/_design/standardRuns/_view/getStandardRuns?startkey=[\"%@\",\"%@\",{}]&endkey=[\"%@\",\"%@\",0]&descending=True&include_docs=True",[model orcaDBUserName],[model orcaDBPassword],[model orcaDBIPAddress],[model orcaDBPort],[model orcaDBName],[model standardRunType],[model standardRunVersion], [model standardRunType],[model standardRunVersion]];
    NSString* link = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:link] cachePolicy:0 timeoutInterval:2];
    NSURLResponse* response = nil;
    NSError* error = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *ret = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]autorelease];
    NSDictionary *versionSettings = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    if(error) {
        NSLogColor([NSColor redColor],@"Couldn't retrieve SR VERSION values. Error querying couchDB, please check the connection is correct. Error: \n %@ \n", error);
        return;
    }

    //Get run type word first
    unsigned long dbruntypeword = [[[[[versionSettings valueForKey:@"rows"]     objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"run_type_word"]  unsignedLongValue];

    //Setup format
    NSNumberFormatter *thresholdFormatter = [[[NSNumberFormatter alloc] init] autorelease];;
    [thresholdFormatter setFormat:@"##0.0"];
    
    if([[versionSettings valueForKey:@"rows"] count] == 0){
        for (int i=0; i<[standardRunThresStoredValues numberOfRows];i++) {
            [[standardRunThresStoredValues cellAtRow:i column:0] setStringValue:@"--"];
        }
        NSLogColor([NSColor redColor],@"Cannot display TEST RUN values. There was some problem with the Standard Run DataBase. \n");
    }
    //If in DIAGNOSTIC run: display null threshold values
    else if(dbruntypeword & kDiagnosticRunType){
        for (int i=0; i<[standardRunThresStoredValues numberOfRows];i++) {
            [[standardRunThresStoredValues cellAtRow:i column:0] setStringValue:@"--"];
            [[standardRunThresStoredValues cellAtRow:i column:0] setTextColor:[self snopRedColor]];
        }
        for(int ibit=0; ibit<21; ibit++){ //Data quality bits are not stored in the SR
            [[runTypeWordSRMatrix cellAtRow:ibit column:0] setState:0];
        }
    //If in non-DIAGNOSTIC run: display DB threshold values
    } else {
        int gtmask = [[[[[versionSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"MTC/D,GtMask"] intValue];
        //NHIT100HI
        float mVolts = [mtcModel rawTomVolts:[[[[[versionSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"MTC/A,NHit100Hi,Threshold"] floatValue]];
        float dcOffset  = [mtcModel dbFloatByIndex:kNHit100HiThreshold + kNHitDcOffset_Offset];
        float mVperNHit = [mtcModel dbFloatByIndex:kNHit100HiThreshold + kmVoltPerNHit_Offset];
        float nHits = [mtcModel mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
        [[standardRunThresStoredValues cellAtRow:0 column:0] setFormatter:thresholdFormatter];
        [[standardRunThresStoredValues cellAtRow:0 column:0] setFloatValue:nHits];
        if((gtmask >> 2) & 1){
            [[standardRunThresStoredValues cellAtRow:0 column:0] setTextColor:[self snopGreenColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:0 column:0] setTextColor:[self snopRedColor]];
        }
        //NHIT100MED
        mVolts = [mtcModel rawTomVolts:[[[[[versionSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"MTC/A,NHit100Med,Threshold"] floatValue]];
        dcOffset  = [mtcModel dbFloatByIndex:kNHit100MedThreshold + kNHitDcOffset_Offset];
        mVperNHit = [mtcModel dbFloatByIndex:kNHit100MedThreshold + kmVoltPerNHit_Offset];
        nHits = [mtcModel mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
        [[standardRunThresStoredValues cellAtRow:1 column:0] setFormatter:thresholdFormatter];
        [[standardRunThresStoredValues cellAtRow:1 column:0] setFloatValue:nHits];
        if((gtmask >> 1) & 1){
            [[standardRunThresStoredValues cellAtRow:1 column:0] setTextColor:[self snopGreenColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:1 column:0] setTextColor:[self snopRedColor]];
        }
        //NHIT100LO
        mVolts = [mtcModel rawTomVolts:[[[[[versionSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"MTC/A,NHit100Lo,Threshold"] floatValue]];
        dcOffset  = [mtcModel dbFloatByIndex:kNHit100LoThreshold + kNHitDcOffset_Offset];
        mVperNHit = [mtcModel dbFloatByIndex:kNHit100LoThreshold + kmVoltPerNHit_Offset];
        nHits = [mtcModel mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
        [[standardRunThresStoredValues cellAtRow:2 column:0] setFormatter:thresholdFormatter];
        [[standardRunThresStoredValues cellAtRow:2 column:0] setFloatValue:nHits];
        if((gtmask >> 0) & 1){
            [[standardRunThresStoredValues cellAtRow:2 column:0] setTextColor:[self snopGreenColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:2 column:0] setTextColor:[self snopRedColor]];
        }
        //NHIT20
        mVolts = [mtcModel rawTomVolts:[[[[[versionSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"MTC/A,NHit20,Threshold"] floatValue]];
        dcOffset  = [mtcModel dbFloatByIndex:kNHit20Threshold + kNHitDcOffset_Offset];
        mVperNHit = [mtcModel dbFloatByIndex:kNHit20Threshold + kmVoltPerNHit_Offset];
        nHits = [mtcModel mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
        [[standardRunThresStoredValues cellAtRow:3 column:0] setFormatter:thresholdFormatter];
        [[standardRunThresStoredValues cellAtRow:3 column:0] setFloatValue:nHits];
        if((gtmask >> 3) & 1){
            [[standardRunThresStoredValues cellAtRow:3 column:0] setTextColor:[self snopGreenColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:3 column:0] setTextColor:[self snopRedColor]];
        }
        //NHIT20LO
        mVolts = [mtcModel rawTomVolts:[[[[[versionSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"MTC/A,NHit20LB,Threshold"] floatValue]];
        dcOffset  = [mtcModel dbFloatByIndex:kNHit20LBThreshold + kNHitDcOffset_Offset];
        mVperNHit = [mtcModel dbFloatByIndex:kNHit20LBThreshold + kmVoltPerNHit_Offset];
        nHits = [mtcModel mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
        [[standardRunThresStoredValues cellAtRow:4 column:0] setFormatter:thresholdFormatter];
        [[standardRunThresStoredValues cellAtRow:4 column:0] setFloatValue:nHits];
        if((gtmask >> 4) & 1){
            [[standardRunThresStoredValues cellAtRow:4 column:0] setTextColor:[self snopGreenColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:4 column:0] setTextColor:[self snopRedColor]];
        }
        //OWLN
        mVolts = [mtcModel rawTomVolts:[[[[[versionSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"MTC/A,OWLN,Threshold"] floatValue]];
        dcOffset  = [mtcModel dbFloatByIndex:kOWLNThreshold + kNHitDcOffset_Offset];
        mVperNHit = [mtcModel dbFloatByIndex:kOWLNThreshold + kmVoltPerNHit_Offset];
        nHits = [mtcModel mVoltsToNHits:mVolts dcOffset:dcOffset mVperNHit:mVperNHit];
        [[standardRunThresStoredValues cellAtRow:5 column:0] setFormatter:thresholdFormatter];
        [[standardRunThresStoredValues cellAtRow:5 column:0] setFloatValue:nHits];
        if((gtmask >> 7) & 1){
            [[standardRunThresStoredValues cellAtRow:5 column:0] setTextColor:[self snopGreenColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:5 column:0] setTextColor:[self snopRedColor]];
        }
        //ESUMHI
        mVolts = [mtcModel rawTomVolts:[[[[[versionSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"MTC/A,ESumHi,Threshold"] floatValue]];
        [[standardRunThresStoredValues cellAtRow:6 column:0] setFloatValue:mVolts];
        [[standardRunThresStoredValues cellAtRow:6 column:0] setFormatter:thresholdFormatter];
        if((gtmask >> 6) & 1){
            [[standardRunThresStoredValues cellAtRow:6 column:0] setTextColor:[self snopGreenColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:6 column:0] setTextColor:[self snopRedColor]];
        }
        //ESUMLO
        mVolts = [mtcModel rawTomVolts:[[[[[versionSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"MTC/A,ESumLow,Threshold"] floatValue]];
        [[standardRunThresStoredValues cellAtRow:7 column:0] setFloatValue:mVolts];
        [[standardRunThresStoredValues cellAtRow:7 column:0] setFormatter:thresholdFormatter];
        if((gtmask >> 5) & 1){
            [[standardRunThresStoredValues cellAtRow:7 column:0] setTextColor:[self snopGreenColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:7 column:0] setTextColor:[self snopRedColor]];
        }
        //OWLEHI
        mVolts = [mtcModel rawTomVolts:[[[[[versionSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"MTC/A,OWLEHi,Threshold"] floatValue]];
        [[standardRunThresStoredValues cellAtRow:8 column:0] setFloatValue:mVolts];
        [[standardRunThresStoredValues cellAtRow:8 column:0] setFormatter:thresholdFormatter];
        if((gtmask >> 9) & 1){
            [[standardRunThresStoredValues cellAtRow:8 column:0] setTextColor:[self snopGreenColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:8 column:0] setTextColor:[self snopRedColor]];
        }
        //OWLELO
        mVolts = [mtcModel rawTomVolts:[[[[[versionSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"MTC/A,OWLELo,Threshold"] floatValue]];
        [[standardRunThresStoredValues cellAtRow:9 column:0] setFloatValue:mVolts];
        [[standardRunThresStoredValues cellAtRow:9 column:0] setFormatter:thresholdFormatter];
        if((gtmask >> 8) & 1){
            [[standardRunThresStoredValues cellAtRow:9 column:0] setTextColor:[self snopGreenColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:9 column:0] setTextColor:[self snopRedColor]];
        }
        //Prescale
        mVolts = [[[[[versionSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"MTC/D,Nhit100LoPrescale"] floatValue];
        [[standardRunThresStoredValues cellAtRow:10 column:0] setFloatValue:mVolts];
        [[standardRunThresStoredValues cellAtRow:10 column:0] setFormatter:thresholdFormatter];
        if((gtmask >> 11) & 1){
            [[standardRunThresStoredValues cellAtRow:10 column:0] setTextColor:[self snopGreenColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:10 column:0] setTextColor:[self snopRedColor]];
        }
        //Pulser
        mVolts = [[[[[versionSettings valueForKey:@"rows"] objectAtIndex:0] valueForKey:@"doc"] valueForKey:@"MTC/D,PulserPeriod"] floatValue];
        [[standardRunThresStoredValues cellAtRow:11 column:0] setFloatValue:mVolts];
        [[standardRunThresStoredValues cellAtRow:11 column:0] setFormatter:thresholdFormatter];
        if((gtmask >> 10) & 1){
            [[standardRunThresStoredValues cellAtRow:11 column:0] setTextColor:[self snopGreenColor]];
        } else{
            [[standardRunThresStoredValues cellAtRow:11 column:0] setTextColor:[self snopRedColor]];
        }
    }
    
    //Display runtype word
    for(int ibit=0; ibit<21; ibit++){ //Data quality bits are not stored in the SR
        if((dbruntypeword >> ibit) & 1){
            [[runTypeWordSRMatrix cellAtRow:ibit column:0] setState:1];
            /*
             This is not used anymore but I'll leave it here as an example of how to change
             color of an NSButton (Javi)
             //Changing the color of a NSButton is not simple. You need all the following junk.
             NSDictionary *dictAttr = [NSDictionary dictionaryWithObjectsAndKeys: snopBlackColor, NSForegroundColorAttributeName, nil];
             NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[[runTypeWordMatrix cellAtRow:ibit column:0] title] attributes:dictAttr];
             [[runTypeWordMatrix cellAtRow:ibit column:0] setAttributedTitle:attributedString];
             */
        } else{
            [[runTypeWordSRMatrix cellAtRow:ibit column:0] setState:0];
        }
    }

}


//Reload the standard run from the DB:
//Queries the DB and populate the 'Run Name' popup menu
//with the SR names. It selects automatically the old
//SR if any. SR versions are refreshed as well afterwards.
- (IBAction) refreshStandardRunsAction: (id) sender
{
    NSString *urlString, *link, *ret;
    NSURLRequest *request;
    NSURLResponse *response;
    NSError *error = nil;
    NSData *data;
    
    // Clear stored SRs
    [standardRunPopupMenu deselectItemAtIndex:[standardRunPopupMenu indexOfSelectedItem]];
    [standardRunPopupMenu removeAllItems];
    [standardRunVersionPopupMenu deselectItemAtIndex:[standardRunVersionPopupMenu indexOfSelectedItem]];
    [standardRunVersionPopupMenu removeAllItems];
    
    // Now query DB and fetch the SRs
    urlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/%@/_design/standardRuns/_view/getStandardRuns",[model orcaDBUserName],[model orcaDBPassword],[model orcaDBIPAddress],[model orcaDBPort],[model orcaDBName]];
    link = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    request = [NSURLRequest requestWithURL:[NSURL URLWithString:link] cachePolicy:0 timeoutInterval:2];
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    ret = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSDictionary *standardRunTypes = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    //JSON formatting error
    if (error != nil) {
        NSLogColor([NSColor redColor], @"Error converting JSON response from "
                   "database: %@\n", [error localizedDescription]);
        [model setStandardRunType:@""];
        [model setStandardRunVersion:@""];
        return;
    }

    //SR not found
    if ([[standardRunTypes valueForKey:@"error"] isEqualToString:@"not_found"] || error != nil) {
        [model setStandardRunType:@""];
        [model setStandardRunVersion:@""];
        NSLogColor([NSColor redColor],@"Error querying couchDB, please check the settings are correct and you have connection. \n");
        [standardRunPopupMenu setEnabled:false];
        [standardRunVersionPopupMenu setEnabled:false];
        return;
    }
    
    //Query succeded
    [standardRunPopupMenu setEnabled:true];
    for(id entry in [standardRunTypes valueForKey:@"rows"]){
        NSString *runtype = [entry valueForKey:@"value"];
        if(runtype != (id)[NSNull null]){
            if([standardRunPopupMenu indexOfItemWithObjectValue:runtype]==NSNotFound)[standardRunPopupMenu addItemWithObjectValue:runtype];
        }
    }
    
    //Handle case with empty DB
    if ([standardRunPopupMenu numberOfItems] == 0){
        [model setStandardRunType:@""];
    } else{
        //Check if previous selected run exists
        if([standardRunPopupMenu indexOfItemWithObjectValue:[model standardRunType]] == NSNotFound){
            //Select first item in popup menu
            [standardRunPopupMenu selectItemAtIndex:0];
        }
        else{
            //Recover old run
            [standardRunPopupMenu selectItemWithObjectValue:[model standardRunType]];
        }
        [model setStandardRunType:[standardRunPopupMenu stringValue]];
    }
    
}

//Read the standard run versions from the DB:
//Queries the DB for the specified Standard Run and populate
//the 'Test run' popup menu with the SR versions
- (void) refreshStandardRunVersions
{
    NSString *urlString, *link, *ret;
    NSURLRequest *request;
    NSURLResponse *response;
    NSError *error = nil;
    NSData *data;
    
    // Clear stored Versions
    [standardRunVersionPopupMenu deselectItemAtIndex:[standardRunVersionPopupMenu indexOfSelectedItem]];
    [standardRunVersionPopupMenu removeAllItems];
    
    urlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/%@/_design/standardRuns/_view/getStandardRuns",[model orcaDBUserName],[model orcaDBPassword],[model orcaDBIPAddress],[model orcaDBPort],[model orcaDBName]];
    link = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    request = [NSURLRequest requestWithURL:[NSURL URLWithString:link] cachePolicy:0 timeoutInterval:2];
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    ret = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSDictionary *standardRunVersions = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];

    //JSON formatting error
    if (error != nil) {
        NSLogColor([NSColor redColor], @"Error converting JSON response from "
                   "database: %@\n", [error localizedDescription]);
        [model setStandardRunVersion:@""];
        return;
    }

    //SR not found
    if ([[standardRunVersions valueForKey:@"error"] isEqualToString:@"not_found"] || error != nil)
    {
        [model setStandardRunVersion:@""];
        NSLogColor([NSColor redColor],@"Error querying couchDB, please check the settings are correct and you have connection. \n");
        [standardRunVersionPopupMenu setEnabled:false];
        return;
    }

    //Query succeded
    BOOL optMode	= [gSecurity isLocked:ORSNOPRunsLockNotification]; //expert or operator mode
    [standardRunVersionPopupMenu setEnabled:!optMode];
    for(id entry in [standardRunVersions valueForKey:@"rows"]){
        NSString *runtype = [[entry valueForKey:@"key"] objectAtIndex:0];
        NSString *runversion = [[entry valueForKey:@"key"] objectAtIndex:1];
        if(runversion != (id)[NSNull null]){
            if([runtype isEqualToString:[model standardRunType]])
                if([standardRunVersionPopupMenu indexOfItemWithObjectValue:runversion]==NSNotFound)[standardRunVersionPopupMenu addItemWithObjectValue:runversion];
        }
    }
    
    //Handle case with empty DB
    if([standardRunVersionPopupMenu numberOfItems] == 0) {
        [model setStandardRunVersion:@""];
    } else{
        //Check if old selected run exists
        if([standardRunVersionPopupMenu indexOfItemWithObjectValue:[model standardRunVersion]] == NSNotFound){
            //Select DEFAULT
            if([standardRunVersionPopupMenu indexOfItemWithObjectValue:@"DEFAULT"] == NSNotFound){
                [standardRunVersionPopupMenu selectItemWithObjectValue:@"DEFAULT"];
            }
            //If everything fails, select first item
            else{
                [standardRunVersionPopupMenu selectItemAtIndex:0];
            }
        }else{
            //Recover old run
            [standardRunVersionPopupMenu selectItemWithObjectValue:[model standardRunVersion]];
        }
        NSString *standardRunVersion = [standardRunVersionPopupMenu stringValue];
        if(standardRunVersion != (id)[NSNull null]){
            [model setStandardRunVersion:standardRunVersion];
        }
        else{
            [model setStandardRunVersion:@""];
        }
    }
    
}
@end
