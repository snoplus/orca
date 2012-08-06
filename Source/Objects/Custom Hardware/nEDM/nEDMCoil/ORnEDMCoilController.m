//
//  ORnEDMCoilController.m
//  Orca
//
//  Created by Michael Marino 15 Mar 2012 
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORnEDMCoilController.h"
#import "ORnEDMCoilModel.h"
#import "ORAdcProcessing.h"
#import "ORTTCPX400DPModel.h"


@interface ORnEDMCoilController (private)
- (void) _buildPopUpButtons;
- (void) _readFile:(id)sender withSelector:(SEL)asel;
@end

@implementation ORnEDMCoilController

- (id) init
{
    self = [super initWithWindowNibName:@"nEDMCoil"];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    
	[groupView setGroup:model];
    
    controlSize		= NSMakeSize(620,595);
    powerSupplySize	= NSMakeSize(450,549);
    adcSize         = NSMakeSize(350,589);
    
    blankView = [[NSView alloc] init];
    //[self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

    [super awakeFromNib];

}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
					   
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(documentLockChanged:)
                         name : ORDocumentLock
                        object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(documentLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];

	[notifyCenter addObserver : self
					 selector : @selector(runRateChanged:)
						 name : ORnEDMCoilPollingFrequencyChanged
					   object : nil];   
    
    [notifyCenter addObserver : self
					 selector : @selector(runStatusChanged:)
						 name : ORnEDMCoilPollingActivityChanged
					   object : nil];

    [notifyCenter addObserver : self
					 selector : @selector(modelADCListChanged:)
						 name : ORnEDMCoilADCListChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(channelMapChanged:)
						 name : ORnEDMCoilHWMapChanged
					   object : nil];   
    
    [notifyCenter addObserver : self
					 selector : @selector(objectsAdded:)
						 name : ORGroupObjectsAdded
					   object : nil];   
    
    [notifyCenter addObserver : self
					 selector : @selector(objectsAdded:)
						 name : ORGroupObjectsRemoved
					   object : nil];   
    
    [notifyCenter addObserver : self
					 selector : @selector(debugRunningChanged:)
						 name : ORnEDMCoilDebugRunningHasChanged
					   object : nil];      
    
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSSize temp;
    switch ([tabView indexOfTabViewItem:tabViewItem]) {
        case 0:
            temp = controlSize;
            break;
        case 1:
            temp = powerSupplySize;
            break;
        case 2:
            temp = adcSize;
            break;            
        default:
            return;
    }
    [[self window] setContentView:blankView];
    [self resizeWindowToSize:temp];
    [[self window] setContentView:tabView];
    
	
    NSString* key = @"orca.nEDMExperiment%d.selectedtab";
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

- (void) runRateChanged:(NSNotification *)aNote
{
    [runRateField setFloatValue:[model pollingFrequency]];
}

- (void) runStatusChanged:(NSNotification *)aNote
{
    if ([model isRunning]) [startStopButton setTitle:@"Stop Process"];
    else [startStopButton setTitle:@"Start Process"];
}

- (void) viewChanged:(NSNotification*)aNotification
{
    [model performSelector:@selector(setUpImage) withObject:nil afterDelay:0];
}

- (void) debugRunningChanged:(NSNotification*)aNote
{
    [debugModeButton setState:[model debugRunning]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self populateListADCs];
    [self _buildPopUpButtons];
    [self modelADCListChanged:nil];
    [self channelMapChanged:nil];    
    //[self documentLockChanged:nil];
	[self viewChanged:nil];
	[self runRateChanged:nil];    
	[self runStatusChanged:nil];
    [self debugRunningChanged:nil];
    [groupView setNeedsDisplay:YES];
}

- (void) documentLockChanged:(NSNotification*)aNotification
{
    if([gSecurity isLocked:ORDocumentLock]) [lockDocField setStringValue:@"Document is locked."];
    else if([gOrcaGlobals runInProgress])   [lockDocField setStringValue:@"Run In Progress"];
    else				    [lockDocField setStringValue:@""];
}

- (void) modelADCListChanged:(NSNotification*)aNote
{
    [listOfRegisteredADCs reloadData];
    [self populateListADCs];
}

- (void) channelMapChanged:(NSNotification*)aNote
{
    [hardwareMap reloadData];
}

#pragma mark •••Table View protocol

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == listOfRegisteredADCs) return [[model listOfADCs] count];
    if (aTableView == hardwareMap) return [model numberOfChannels];    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if (aTableView == listOfRegisteredADCs) return [[[model listOfADCs] objectAtIndex:rowIndex] processingTitle];
    if (aTableView == hardwareMap) {
        NSString* ident = [aTableColumn identifier];
        if ([ident isEqualToString:@"kSegmentNumber"]) return [NSNumber numberWithInt:rowIndex];
        if ([ident isEqualToString:@"kCardSlot"]) return [NSNumber numberWithInt:rowIndex];
        if ([ident isEqualToString:@"kChannel"]) return [NSNumber numberWithInt:[model mappedChannelAtChannel:rowIndex]];
    }
    return @"";
}

#pragma mark •••Accessors
- (ORGroupView *)groupView
{
    return groupView;
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [groupView setGroup:(ORGroup*)model];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];

}

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[model setUpImage];
		[self updateWindow];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	return [groupView validateMenuItem:menuItem];
}

#pragma mark •••Interface Management
- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) objectsAdded:(NSNotification*)aNote
{
    [self populateListADCs];
    [self _buildPopUpButtons];
}

- (void) populateListADCs
{
    [listOfAdcs removeAllItems];
    [listOfAdcs addItemWithTitle:@"Not Used"];
    NSArray* validObjs = [model validObjects];    
    id obj, obj1;
    NSEnumerator* e = [validObjs objectEnumerator];
    while(obj = [e nextObject]){
        NSEnumerator* alreadyIn = [[model listOfADCs] objectEnumerator];        
        BOOL objectExists = NO;
        while(obj1 = [alreadyIn nextObject]){        
            if ([[obj1 processingTitle] isEqualToString:[obj processingTitle]]) {
                objectExists = YES;
                break;
            }
        }
        if (!objectExists) [listOfAdcs addItemWithTitle:[obj processingTitle]];
    }

}

- (void) isNowKeyWindow:(NSNotification*)aNotification
{
	[[self window] makeFirstResponder:(NSResponder*)groupView];
}

- (void) runAction:(id)sender
{
    [model toggleRunState];
}

- (void) runRateAction:(id)sender
{
    [model setPollingFrequency:[sender floatValue]];
}

- (void) addADCAction:(id)sender
{
    NSString* adcName = [[listOfAdcs selectedItem] title];
    NSArray* validObjs = [model validObjects];    
    id obj;
    NSEnumerator* e = [validObjs objectEnumerator];
    while(obj = [e nextObject]){
        if ([adcName isEqualToString:[obj processingTitle]]) {
            [model addADC:obj];
            break;
        }
    }    
    
}

- (void) _readFile:(id)sender withSelector:(SEL)asel
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	//NSString* fullPath = [[[model segmentGroup:0] mapFile] stringByExpandingTildeInPath];
    //if(fullPath){
    //    startingDir = [fullPath stringByDeletingLastPathComponent];
    //}
    //else {
    startingDir = NSHomeDirectory();
    //}
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model performSelector:asel withObject:[[openPanel URL] path]];
        }
    }];
#endif
    
}

// import feedback matrix
- (IBAction) readPrimaryMapFileAction:(id)sender
{
    [self _readFile:sender withSelector:@selector(initializeConversionMatrixWithPlistFile:)];
}

// import magnetometer channel map
- (IBAction) readPrimaryMagnetometerMapFileAction:(id)sender
{
    [self _readFile:sender withSelector:@selector(initializeMagnetometerMapWithPlistFile:)];    
}

// import magnetometer channel map
- (IBAction) readPrimaryOrientationMatrixFileAction:(id)sender
{
    [self _readFile:sender withSelector:@selector(initializeOrientationMatrixWithPlistFile:)];    
}

- (IBAction) sendCommandAction:(id)sender
{
    [self endEditing];
    int cmd = [[commandPopUp selectedItem] tag];
    int output = [[outputNumberPopUp selectedItem] tag];
    float input = [inputValueText floatValue];
    NSEnumerator* anEnum = [[self groupView] objectEnumerator];
    for (id aPowerSupply in anEnum) {    
        [aPowerSupply writeCommand:cmd withInput:input withOutputNumber:output];
    }
    //[sendCommandButton setEnabled:NO];
}

- (IBAction) debugCommandAction:(id)sender
{
    [model setDebugRunning:[debugModeButton state]];
}

- (IBAction) connectAllAction:(id)sender
{
    [model connectAllPowerSupplies];
}

//---------------------------------------------------------------
//these last actions are here only to work around a strange 
//first responder problem that occurs after cut followed by undo
//- (IBAction)delete:(id)sender   { [groupView delete:sender]; }
//- (IBAction)cut:(id)sender      { [groupView cut:sender]; }
//- (IBAction)paste:(id)sender    { [groupView paste:sender]; }
//- (IBAction)selectAll:(id)sender{ [groupView selectAll:sender]; }
//-----------------------------------------------------------------

- (void) _buildPopUpButtons
{
    
    if ([[[self groupView] group] count] == 0) {
        [commandPopUp removeAllItems];            
        return;
    }
    id aPowerSupply = [[[self groupView] group] objectAtIndex:0];
    if ([commandPopUp numberOfItems] == [aPowerSupply numberOfCommands]) return;
    [commandPopUp removeAllItems];            
    int i;
    for (i=0; i<[aPowerSupply numberOfCommands]; i++) {
        [commandPopUp addItemWithTitle:[aPowerSupply commandName:i]];
        [[commandPopUp itemAtIndex:i] setTag:i];
    }    
    // Get out of the iteration, we just need to do this during the first iteration
    return;

}

@end
