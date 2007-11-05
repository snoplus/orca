//
//  ORGateKeeper.m
//  Orca
//
//  Created by Mark Howe on 1/24/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORGateKeeper.h"
#import "ORGate.h"
#import "ORGateGroup.h"
#import "ORGateKeyController.h"
#import "ORGatedValueController.h"

static ORGateKeeper* sharedInstance = nil;

NSString* ORGateKeeperSettingsLock = @"ORGateKeeperSettingsLock";

@implementation ORGateKeeper

+ (id) sharedGateKeeper
{
    if(!sharedInstance){
        sharedInstance = [[ORGateKeeper alloc] init];
    }
    return sharedInstance;
}

-(id)init
{
    self = [super initWithWindowNibName:@"GateKeeper"];
    [self setWindowFrameAutosaveName:@"GateKeeper"];
    return self;
}


- (void) dealloc
{
    sharedInstance = nil;
    [self setSelectedGate: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self registerNotificationObservers];
    [self updateWindow];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[NSApp delegate] undoManager];
}

#pragma mark ***Accessors

- (ORGateGroup *) gateGroup
{
    return gateGroup; 
}

- (void) setGateGroup: (ORGateGroup *) aGateGroup
{
    gateGroup = aGateGroup;
}

- (ORGate *) selectedGate
{
    return selectedGate; 
}

- (void) setSelectedGate: (ORGate *) aSelectedGate
{
    [aSelectedGate retain];
    [selectedGate release];
    selectedGate = aSelectedGate;
    
    [gateKeyController setModel:[selectedGate gateKey]];
    [gatedValueController setModel:[selectedGate gatedValue]];
    [gatedValueControllerY setModel:[selectedGate gatedValueY]];
}


#pragma mark ***Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[notifyCenter addObserver : self
                      selector: @selector(gateNameChanged:)
                          name: ORGateNameChangedNotification
                       object : nil];
    
	[notifyCenter addObserver : self
                      selector: @selector(selectionChanged:)
                          name: NSTableViewSelectionDidChangeNotification
                       object : gateListView];
    
	[notifyCenter addObserver : self
                      selector: @selector(gateArrayChanged:)
                          name: ORGateArrayChangedNotification
                       object : gateGroup];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORGateKeeperSettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(securityStateChanged:)
                         name : ORGlobalSecurityStateChanged
                        object: nil];
    
	[notifyCenter addObserver : self
                      selector: @selector(dimensionChanged:)
                          name: ORGateTwoDChangedNotification
                       object : nil];


	[notifyCenter addObserver : self
                      selector: @selector(preScaleChanged:)
                          name: ORGatePreScaleChangedNotification
                       object : nil];
                       
	[notifyCenter addObserver : self
                      selector: @selector(twoDSizeChanged:)
                          name: ORGateTwoDSizeChangedNotification
                       object : nil];

	[notifyCenter addObserver : self
                      selector: @selector(ignoreKeyChanged:)
                          name: ORGateIgnoreKeyChangedNotification
                       object : nil];

       
}

- (void) updateWindow
{
    [self selectionChanged:nil];
    [self gateArrayChanged:nil];
    [gateKeyController updateWindow];
    [gatedValueController updateWindow];
    [gatedValueControllerY updateWindow];
    [self securityStateChanged:nil];
    [self settingsLockChanged:nil];
    [self dimensionChanged:nil];
    [self preScaleChanged:nil];
    [self twoDSizeChanged:nil];
    [self ignoreKeyChanged:nil];
}


#pragma mark ***Interface Management

- (void) ignoreKeyChanged:(NSNotification*)aNotification
{
    int index = [gateListView selectedRow];
    if([gateGroup count] && index >= 0){
        ORGate* aGate = [gateGroup objectAtIndex:index];
        if(aNotification == nil || [aNotification object] == aGate){
            [ignoreKeyButton setState:[aGate ignoreKey]];
            [gateKeyController setIgnore:[aGate ignoreKey] && [aGate twoD]];
        }
    }
}

- (void) preScaleChanged:(NSNotification*)aNotification
{
    int index = [gateListView selectedRow];
    if([gateGroup count] && index >= 0){
        ORGate* aGate = [gateGroup objectAtIndex:index];
        if(aNotification == nil || [aNotification object] == aGate){
            [preScaleField setIntValue:[aGate preScale]];
        }
    }
}

- (void) twoDSizeChanged:(NSNotification*)aNotification
{
    int index = [gateListView selectedRow];
    if([gateGroup count] && index >= 0){
        ORGate* aGate = [gateGroup objectAtIndex:index];
        if(aNotification == nil || [aNotification object] == aGate){
            [twoDSizeField setIntValue:[aGate twoDSize]];
        }
    }
}

- (void)windowDidResignMain:(NSNotification *)aNotification
{
    if([aNotification object] == [self window]){
        [self endEditing];
    }
}

- (void) endEditing
{
	//commit all text editing... subclasses should call before doing their work.
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}
}

- (void) securityStateChanged:(NSNotification*)aNotification
{
    [self checkGlobalSecurity];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORGateKeeperSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGateKeeperSettingsLock];
    BOOL locked = [gSecurity isLocked:ORGateKeeperSettingsLock];
    
    [settingLockButton setState: locked];
    
    [gateListView setEnabled:!lockedOrRunningMaintenance];
    [addGateButton setEnabled:!lockedOrRunningMaintenance];
    [removeGateButton setEnabled:!lockedOrRunningMaintenance];
    [gateNameField setEnabled:!lockedOrRunningMaintenance];
    
    [gateKeyController settingsLockChanged:nil];
    [gatedValueController settingsLockChanged:nil];
    [gatedValueControllerY settingsLockChanged:nil];
    
    [removeGateButton setEnabled:!lockedOrRunningMaintenance];

    [ignoreKeyButton setEnabled:!runInProgress && !locked];
    [preScaleField setEnabled:!runInProgress && !locked];
    [twoDSizeField setEnabled:!runInProgress && !locked];
    [dimensionButton setEnabled:!runInProgress && !locked];
    
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORGateKeeperSettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
    
}

- (void) dimensionChanged:(NSNotification*)aNotification
{
    int index = [gateListView selectedRow];
    if([gateGroup count] && index >= 0){
        ORGate* aGate = [gateGroup objectAtIndex:index];
        if(aNotification == nil || [aNotification object] == aGate){
            [dimensionTabView selectTabViewItemAtIndex:[aGate twoD]];
            [dimensionButton selectCellWithTag:[aGate twoD]];
            [gatedValue1DBox setTitle:[aGate twoD]?@"Gated X Value":@"Gated Value"];
        }
    }
}


- (void) gateArrayChanged:(NSNotification*)aNote
{
    if(!aNote || [aNote object] == gateGroup){
        [gateListView reloadData];
    }
}

- (void) selectionChanged:(NSNotification*)aNote
{    
    [self endEditing];
    if([gateGroup count]){
        [gateTabView selectTabViewItemAtIndex:0];
    }
    else {
        [gateTabView selectTabViewItemAtIndex:1];
    }
    
    if(!aNote || [aNote object] == gateListView){
        int index = [gateListView selectedRow];
        if([gateGroup count] && index >= 0){
            ORGate* aGate = [gateGroup objectAtIndex:index];          
            [self setSelectedGate:aGate];
            NSString* aName = [selectedGate gateName];
            if(aName)[gateNameField setStringValue:aName];
            [gateListView reloadData];
        }
        else [gateNameField setStringValue:@"---"];

        [self gateArrayChanged:nil];
        [self securityStateChanged:nil];
        [self settingsLockChanged:nil];
        [self dimensionChanged:nil];
        [self preScaleChanged:nil];
        [self twoDSizeChanged:nil];
        [self ignoreKeyChanged:nil];
        [gateKeyController updateWindow];
        [gatedValueController updateWindow];
        [gatedValueControllerY updateWindow];

    }
}

- (void) gateNameChanged:(NSNotification*)aNote
{
    int index = [gateListView selectedRow];
    
    if([gateGroup count] && index < [gateGroup count]){
        NSString* theName = [[gateGroup objectAtIndex:index] gateName];
        if(theName)[gateNameField setStringValue:theName];
        [gateListView reloadData];
    }
    else [gateNameField setStringValue:@"---"];
}

#pragma mark ***Actions
- (IBAction) addGateAction:(id)sender
{
    [gateGroup newDataGate];
    int lastIndex = [gateListView numberOfRows]-1;
    [gateListView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastIndex] byExtendingSelection:NO];
    
    [gateListView reloadData];
}

- (IBAction) delete:(id)sender
{
    int index = [gateListView selectedRow];
    int lastIndex = [gateListView numberOfRows]-1;
    if(index>=0){
        ORGate* aGate = [gateGroup objectAtIndex:index];
        [gateGroup deleteGate:aGate];
        if(index == lastIndex){
            lastIndex = [gateListView numberOfRows]-1;
            [gateListView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastIndex] byExtendingSelection:NO];
        }
        
        [gateListView reloadData];
        [self selectionChanged:nil];
    }
}


- (IBAction) gateNameAction:(id)sender
{
    int index = [gateListView selectedRow];
    if(index>=0){
        ORGate* aGate = [gateGroup objectAtIndex:index];
        NSString* aName = [gateNameField stringValue];
        if(aName)[aGate setGateName:aName];
        [gateListView reloadData];
    }
}

- (IBAction) saveDocument:(id)sender
{
    [[[NSApp delegate] document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[[NSApp delegate] document] saveDocumentAs:sender];
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGateKeeperSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) dimensionAction:(id)sender;
{
    int index = [gateListView selectedRow];
    if([gateGroup count] && index >= 0){
        ORGate* aGate = [gateGroup objectAtIndex:index];
        [aGate setTwoD:[[sender selectedCell]tag]];
        [gateKeyController setIgnore:[aGate ignoreKey] && [aGate twoD]];
    }
}

- (IBAction) twoDSizeAction:(id) sender
{
    int index = [gateListView selectedRow];
    if([gateGroup count] && index >= 0){
        ORGate* aGate = [gateGroup objectAtIndex:index];
        [aGate setTwoDSize:[sender intValue]];
    }
}
- (IBAction) preScaleAction:(id) sender
{
    int index = [gateListView selectedRow];
    if([gateGroup count] && index >= 0){
        ORGate* aGate = [gateGroup objectAtIndex:index];
        [aGate setPreScale:[sender intValue]];
    }
}

- (IBAction) ignoreKeyAction:(id) sender
{
    int index = [gateListView selectedRow];
    if([gateGroup count] && index >= 0){
        ORGate* aGate = [gateGroup objectAtIndex:index];
        [aGate setIgnoreKey:[sender state]];
    }
}


#pragma mark ***Data Source for Gate Table
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [gateGroup count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    return [[gateGroup objectAtIndex:row] gateName];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if(object){
        ORGate* aGate = [gateGroup objectAtIndex:row];
        [aGate setGateName:object];
    }
}


@end
