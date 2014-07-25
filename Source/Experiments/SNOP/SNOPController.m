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
#import "ELLIEModel.h"
#import "ORCouchDB.h"

NSString* ORSNOPRequestHVStatus = @"ORSNOPRequestHVStatus";

@implementation SNOPController

@synthesize
runStopImg = _runStopImg,
smellieRunFileList,
smellieRunFile;

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"SNOP"];
    return self;
}


- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/SNOP";
}


-(void) awakeFromNib
{
	detectorSize		= NSMakeSize(620,595);
	//detailsSize		= NSMakeSize(450,589);
    detailsSize		= NSMakeSize(620,595);
	//focalPlaneSize		= NSMakeSize(450,589);
	focalPlaneSize		= NSMakeSize(620,595);
    //couchDBSize		= NSMakeSize(450,480);
	couchDBSize		= NSMakeSize(620,595);
    hvMasterSize		= NSMakeSize(620,595);
	runsSize		= NSMakeSize(620,595);
	
	blankView = [[NSView alloc] init];
    [tabView setFocusRingType:NSFocusRingTypeNone];
	[self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
    
    //pull the information from the SMELLIE DB
    [model getSmellieRunListInfo];
    
    
	[super awakeFromNib];
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];

    [notifyCenter addObserver : self
                     selector : @selector(viewTypeChanged:)
                         name : ORSNOPModelViewTypeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(dbOrcaDBIPChanged:)
                         name : ORSNOPModelOrcaDBIPAddressChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dbDebugDBIPChanged:)
                         name : ORSNOPModelDebugDBIPAddressChanged
                        object: model];

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
}

- (void) updateWindow
{
	[super updateWindow];
	[self viewTypeChanged:nil];
    [self hvStatusChanged:nil];
    [self dbOrcaDBIPChanged:nil];
    [self dbDebugDBIPChanged:nil];
}

- (void) viewTypeChanged:(NSNotification*)aNote
{
	[viewTypePU selectItemAtIndex:[model viewType]];
	[detectorView setViewType:[model viewType]];
	[detectorView makeAllSegments];	
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
    if (!aNote) {//pull from XL3s
        NSArray* xl3s = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
        unsigned long xl3Mask = 0x7ffff;
        for (id xl3 in xl3s) {
            xl3Mask ^= 1 << [xl3 crateNumber];
            int mRow;
            int mColumn;
            bool found;
            found = [hvStatusMatrix getRow:&mRow column:&mColumn ofCell:[hvStatusMatrix cellWithTag:[xl3 crateNumber]]];
            if (found) {
                [[hvStatusMatrix cellAtRow:mRow column:1] setStringValue:[xl3 hvASwitch]?@"ON":@"OFF"];
                if ([xl3 hvASwitch]) {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor redColor]];
                }
                else {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
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
                    }
                    else {
                        [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
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
            }
            else {
                [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
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
                }
                else {
                    [[hvStatusMatrix cellAtRow:mRow column:1] setTextColor:[NSColor blackColor]];
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
}

#pragma mark ¥¥¥Interface Management
- (IBAction) viewTypeAction:(id)sender
{
	[model setViewType:[sender indexOfSelectedItem]];
}

- (IBAction) orcaDBIPAddressAction:(id)sender {
    [model setOrcaDBIPAddress:[sender stringValue]];
}

- (IBAction) debugDBIPAddressAction:(id)sender {
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

- (IBAction) orcaDBFutonAction:(id)sender {
    [[NSWorkspace sharedWorkspace]
     openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@:%d/_utils/database.html?%@",
                                   [model orcaDBUserName], [model orcaDBPassword], [model orcaDBIPAddress],
                                   [model orcaDBPort], [model orcaDBName]]]];
}

- (IBAction) debugDBFutonAction:(id)sender {
    [[NSWorkspace sharedWorkspace]
     openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@:%d/_utils/database.html?%@",
                                   [model debugDBUserName], [model debugDBPassword], [model debugDBIPAddress],
                                   [model debugDBPort], [model debugDBName]]]];
}

- (IBAction) orcaDBTestAction:(id)sender {
    [[NSWorkspace sharedWorkspace]
     openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@:%d",
                                   [model orcaDBUserName], [model orcaDBPassword],
                                   [model orcaDBIPAddress], [model orcaDBPort]]]];
}

- (IBAction) debugDBTestAction:(id)sender {
    [[NSWorkspace sharedWorkspace]
     openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@%@:%d",
                                   [model debugDBUserName], [model debugDBPassword],
                                   [model debugDBIPAddress], [model debugDBPort]]]];
}

- (IBAction) orcaDBPingAction:(id)sender {
    [model orcaDBPing];
}

- (IBAction) debugDBPingAction:(id)sender {
    [model debugDBPing];
}

- (IBAction)hvMasterPanicAction:(id)sender
{
    
    [[[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(hvPanicDown)];
/*
    NSArray* xl3s = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    for (id xl3 in xl3s) {
        [model hvPanicDown];
    }
 */
    NSLog(@"Detector wide panic down started\n");
}

- (IBAction)hvMasterTriggersOFF:(id)sender
{
    [[[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(hvTriggersOFF)];
}

- (IBAction)hvMasterTriggersON:(id)sender
{
    [[[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(hvTriggersON)];
}

- (IBAction)hvMasterStatus:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPRequestHVStatus object:self];
}

- (void) specialUpdate:(NSNotification*)aNote
{
	[super specialUpdate:aNote];
	[detectorView makeAllSegments];
}

- (void) setDetectorTitle
{	
	switch([model displayType]){
		case kDisplayRates:		[detectorTitle setStringValue:@"Detector Rate"];	break;
		case kDisplayThresholds:	[detectorTitle setStringValue:@"Thresholds"];		break;
		case kDisplayTotalCounts:	[detectorTitle setStringValue:@"Total Counts"];		break;
		default: break;
	}
}

#pragma mark ¥¥¥Details Interface Management
- (void) detailsLockChanged:(NSNotification*)aNotification
{
	[super detailsLockChanged:aNotification];
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetailsLock]];
	BOOL locked = [gSecurity isLocked:[model experimentDetailsLock]];

	[detailsLockButton setState: locked];
	[initButton setEnabled: !lockedOrRunningMaintenance];
}

#pragma mark ¥¥¥Table Data Source

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detectorSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 5){
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:runsSize];
        [[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detailsSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:focalPlaneSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 4){
	    [[self window] setContentView:blankView];
	    [self resizeWindowToSize:couchDBSize];
	    [[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 5){
	    [[self window] setContentView:blankView];
	    [self resizeWindowToSize:hvMasterSize];
	    [[self window] setContentView:tabView];
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
        //Loop through all the smellie files in the run list 
        for(id key in self.smellieRunFileList){
            
            id loopValue = [self.smellieRunFileList objectForKey:key];
            
            NSString *string1 = [loopValue objectForKey:@"run_name"];
            NSString *string2 = [smellieRunFileNameField objectValueOfSelectedItem];
            
            if( [string1 isEqualToString:string2]){
                self.smellieRunFile = loopValue;
                
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
                [smellieCheckInterlock setEnabled:YES];
                [smellieLaserString release];
                
            }
        }
    }
    else{
        [smellieCheckInterlock setEnabled:NO];
        NSLog(@"Main SNO+ Control:Please choose a Smellie Run File from selection\n");
    }
}

- (IBAction) checkSmellieInterlockAction:(id)sender
{
    //Check interlock with them model here
    [smellieStartRunButton setEnabled:YES];
    [smellieStopRunButton setEnabled:YES];
    [smellieEmergencyStop setEnabled:YES];
}

- (IBAction) startSmellieRunAction:(id)sender
{
    [smellieLoadRunFile setEnabled:NO];
    [smellieRunFileNameField setEnabled:NO];
    [smellieStopRunButton setEnabled:YES];
    [smellieStartRunButton setEnabled:NO];
    [smellieCheckInterlock setEnabled:NO];
    
    //start different sub runs as the laser runs through
    //communicate with smellie model
    
    //Collect a series of objects from the ELLIEModel
    NSArray*  objs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    
    //get the ELLIE Model object
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];
    
    //Method for completing this without a new thread 
    //[theELLIEModel startSmellieRun:smellieRunFile];
    
    smellieThread = [[NSThread alloc] initWithTarget:theELLIEModel selector:@selector(startSmellieRun:) object:smellieRunFile];
    [smellieThread start];
    
    
    //[NSThread detachNewThreadSelector:@selector(startSmellieRun:) toTarget:theELLIEModel withObject:smellieRunFile];
    
    //[theELLIEModel release];
    
}

- (IBAction) stopSmellieRunAction:(id)sender
{
    [smellieLoadRunFile setEnabled:YES];
    [smellieRunFileNameField setEnabled:YES];
    [smellieStartRunButton setEnabled:YES];
    [smellieStopRunButton setEnabled:NO];
    [smellieCheckInterlock setEnabled:YES];
   
    //Collect a series of objects from the ELLIEModel
    NSArray*  objs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    
    //get the ELLIE Model object
    ELLIEModel* theELLIEModel = [objs objectAtIndex:0];
    
    /*[NSThread detachNewThreadSelector:@selector(startSmellieRun:)
                             toTarget:theELLIEModel
                           withObject:[smellieRunFile autorelease]];*/
    
    /*[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startSmellieRun:) object:smellieRunFile];*/
    //cancel the smellie thread
    [smellieThread cancel];
    [smellieThread release];
    smellieThread = nil;
    
    //Method for completing this without a new thread
    [theELLIEModel stopSmellieRun];
    
    
    //[theELLIEModel release];
    
    //wait for the current loop to finish
    //move straight to a maintainence run
    //communicate with smellie model
    //TODO:Make a note in the datastream that this happened
}

- (IBAction) emergencySmellieStopAction:(id)sender
{
    [smellieLoadRunFile setEnabled:YES];
    [smellieRunFileNameField setEnabled:YES];
    [smellieStartRunButton setEnabled:NO];
    [smellieStopRunButton setEnabled:NO];
    [smellieCheckInterlock setEnabled:NO];
    //turn the interlock off
    //(if a smellie run is currently operating) start a maintainence run
    //reset the smellie laser system
    //TODO:Make a note in the datastream that this happened 
}


@end
