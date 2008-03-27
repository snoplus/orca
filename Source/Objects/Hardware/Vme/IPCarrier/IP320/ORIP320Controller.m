//
//  ORIP320Controller.m
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
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


#pragma mark ¥¥¥Imported Files
#import "ORIP320Controller.h"
#import "ORIP320Model.h"
#import "ORIP320Channel.h"


@interface ORIP320Controller (private)
- (void) selectLogFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

@implementation ORIP320Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"IP320"];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    adcValueSize    = NSMakeSize(385,442);
    calibrationSize = NSMakeSize(520,430);
    alarmSize       = NSMakeSize(490,443);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORIP320%d%d%d.selectedtab",[model crateNumber],[model slot],[model slotConv]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	
    [[[valueTable1 tableColumnWithIdentifier:k320ChannelReadEnabled ]dataCell]setControlSize:NSSmallControlSize];
    [[[valueTable2 tableColumnWithIdentifier:k320ChannelReadEnabled ]dataCell]setControlSize:NSSmallControlSize];
	
	
    [[[alarmTable1 tableColumnWithIdentifier:k320ChannelAlarmEnabled ]dataCell]setControlSize:NSSmallControlSize];
    [[[alarmTable2 tableColumnWithIdentifier:k320ChannelAlarmEnabled ]dataCell]setControlSize:NSSmallControlSize];
	
    
    [[[calibrationTable1 tableColumnWithIdentifier:k320ChannelGain ]dataCell]setControlSize:NSSmallControlSize];
    [[[calibrationTable2 tableColumnWithIdentifier:k320ChannelGain ]dataCell]setControlSize:NSSmallControlSize];
    [[[calibrationTable1 tableColumnWithIdentifier:k320ChannelGain ]dataCell]setFont:[NSFont systemFontOfSize:10]];
    [[[calibrationTable2 tableColumnWithIdentifier:k320ChannelGain ]dataCell]setFont:[NSFont systemFontOfSize:10]];
    
    
    int i;
    int val = 1;
    for(i=0;i<4;i++){
        id popupCell = [[calibrationTable1 tableColumnWithIdentifier:k320ChannelGain ]dataCell];
        [popupCell addItemWithTitle:[NSString stringWithFormat:@"%d",val]];
        popupCell = [[calibrationTable2 tableColumnWithIdentifier:k320ChannelGain ]dataCell];
        [popupCell addItemWithTitle:[NSString stringWithFormat:@"%d",val]];
        val *= 2;
	}
		
    [super awakeFromNib];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(pollingStateChanged:)
                         name : ORIP320PollingStateChangedNotification
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(valuesChanged:)
                         name : ORIP320AdcValueChangedNotification
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORVmeCardSlotChangedNotification
                       object : model];
					   
    [notifyCenter addObserver : self
                     selector : @selector(displayRawChanged:)
                         name : ORIP320ModelDisplayRawChanged
						object: model];

   [notifyCenter addObserver : self
                     selector : @selector(modeChanged:)
                         name : ORIP320ModelModeChanged
						object: model];
    [notifyCenter addObserver : self
                     selector : @selector(logToFileChanged:)
                         name : ORIP320ModelLogToFileChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(logFileChanged:)
                         name : ORIP320ModelLogFileChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(shipRecordsChanged:)
                         name : ORIP320ModelShipRecordsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cardJumperSettingChanged:)
                         name : ORIP320ModelCardJumperSettingChanged
						object: model];

}


#pragma mark ¥¥¥Accessors


#pragma mark ¥¥¥Interface Management
- (void) shipRecordsChanged:(NSNotification*)aNote
{
	[shipRecordsButton setIntValue: [model shipRecords]];
}

- (void) logFileChanged:(NSNotification*)aNote
{
	if([model logFile])[logFileTextField setStringValue: [model logFile]];
	else [logFileTextField setStringValue: @"---"];
}

- (void) logToFileChanged:(NSNotification*)aNote
{
	[logToFileButton setIntValue: [model logToFile]];
}

- (void) displayRawChanged:(NSNotification*)aNote
{
	[displayRawCB setIntValue: [model displayRaw]];
	[valueTable1 reloadData];
	[valueTable2 reloadData];
}

- (void) updateWindow
{
    [super updateWindow];
    [self pollingStateChanged:nil];
	[self valuesChanged:nil];
	[self slotChanged:nil];
	[self modeChanged:nil];
	[self displayRawChanged:nil];
	[self logToFileChanged:nil];
	[self logFileChanged:nil];
	[self shipRecordsChanged:nil];
	[self cardJumperSettingChanged:nil];
}

- (void) cardJumperSettingChanged:(NSNotification*)aNotification
{
	[jumperSettingsPU selectItemWithTag:[model cardJumperSetting]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"IP320 (%@)",[model identifier]]];
}

- (void) modeChanged:(NSNotification*)aNotification
{
	[modePopUpButton selectItemWithTag:[model mode]];
}

- (void) valuesChanged:(NSNotification*)aNotification
{
    if(!scheduledToUpdate){
        [self performSelector:@selector(reloadData) withObject:nil afterDelay:1.0];
        scheduledToUpdate = YES;
    }
}

- (void) reloadData
{
    scheduledToUpdate = NO;
	[valueTable1 reloadData];
	[valueTable2 reloadData];
}

- (void) pollingStateChanged:(NSNotification*)aNotification
{
	[pollingButton selectItemAtIndex:[pollingButton indexOfItemWithTag:[model pollingState]]];
}

#pragma mark ¥¥¥Actions
- (IBAction) shipRecordsAction:(id)sender
{
	[model setShipRecords:[sender intValue]];	
}

- (IBAction) enablePollAllAction:(id)sender
{
	[model enablePollAll:YES];
	[valueTable1 reloadData];
	[valueTable2 reloadData];
}

- (IBAction) enablePollNoneAction:(id)sender
{
	[model enablePollAll:NO];
	[valueTable1 reloadData];
	[valueTable2 reloadData];
}


- (IBAction) enableAlarmAllAction:(id)sender
{
	[model enableAlarmAll:YES];
	[alarmTable1 reloadData];
	[alarmTable2 reloadData];
}

- (IBAction) enableAlarmNoneAction:(id)sender
{
	[model enableAlarmAll:NO];
	[alarmTable1 reloadData];
	[alarmTable2 reloadData];
}

- (IBAction) setJumperSettings:(id)sender
{
	[model setCardJumperSetting:[[sender selectedItem] tag]];	
}

- (IBAction) calibrateAction:(id)sender
{
	[model calibrate];
}

- (IBAction) selectFileAction:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Log To File"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[model logFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = @"OrcaScript";
    }
	
    [savePanel beginSheetForDirectory:startingDir
                                 file:defaultFile
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(selectLogFileDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];

 }

- (IBAction) logToFileAction:(id)sender
{
	[model setLogToFile:[sender intValue]];	
}

- (IBAction) displayRawAction:(id)sender
{
	[model setDisplayRaw:[sender intValue]];		
}

- (IBAction) modeAction:(id)sender
{
	[model setMode:[[sender selectedItem] tag]];
}


- (IBAction) readAll:(id)sender
{
    NS_DURING
        [model readAllAdcChannels];
    NS_HANDLER
        NSRunAlertPanel([localException name], @"%@\nRead of", @"OK", nil, nil,
                        localException);
    NS_ENDHANDLER
}
- (IBAction) setPollingAction:(id)sender
{
    [model setPollingState:(NSTimeInterval)[[sender selectedItem] tag]];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:adcValueSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:calibrationSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:alarmSize];
		[[self window] setContentView:tabView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.ORIP320%d%d%d.selectedtab",[model crateNumber],[model slot],[model slotConv]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}


#pragma mark ¥¥¥Data Source
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
	if([model mode] == 1)return YES;
	else {
		if( tableView == valueTable2 || 
			tableView == calibrationTable2 ||
			tableView == alarmTable2 ) {
				return NO;
		}
		else return YES;
	}
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    rowIndex += [aTableView tag];
    //NSParameterAssert(rowIndex >= 0 && rowIndex < kNumIP320Channels);
    ORIP320Channel* obj = [[model chanObjs] objectAtIndex:rowIndex];
	if([[aTableColumn identifier] isEqualToString:k320ChannelValue]){
		if([model displayRaw]){
			return [NSString stringWithFormat:@"0x%x",[obj rawValue]];
		}
		else {
			return [NSString stringWithFormat:@"%.3f",[[obj objectForKey:k320ChannelValue] doubleValue]];
		}
	}
    else return [obj objectForKey:[aTableColumn identifier]];
}


// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return kNumIP320Channels/2;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(anObject!=nil){
		rowIndex += [aTableView tag];
		//NSParameterAssert(rowIndex >= 0 && rowIndex < kNumIP320Channels);
		id obj = [[model chanObjs] objectAtIndex:rowIndex];
		[[[self undoManager] prepareWithInvocationTarget:self] tableView:aTableView setObjectValue:[obj objectForKey:[aTableColumn identifier]] forTableColumn:aTableColumn row:rowIndex];
		[obj setObject:anObject forKey:[aTableColumn identifier]];
		[aTableView reloadData];
	}
}


@end

@implementation ORIP320Controller (private)
- (void)selectLogFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model setLogFile:[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath]];
    }
}
@end

