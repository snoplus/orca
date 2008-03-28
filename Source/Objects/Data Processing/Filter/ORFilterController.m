//
//  ORFilterController.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORFilterController.h"
#import "ORFilterModel.h"
#import "ORTimedTextField.h"
#import "ORScriptView.h"
#import "ORScriptRunner.h"
#import "ORPlotter1D.h"

@interface ORFilterController (private)
- (void) pluginPathSelectDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) loadFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end


@implementation ORFilterController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Filter"];
	return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[statusField setTimeOut:1.5];
	NSString*   path = [[NSBundle mainBundle] pathForResource: @"FilterScriptGuide" ofType: @"rtf"];
	[helpView readRTFDFromFile:path];
	[scriptView setSyntaxDefinitionFilename:@"FilterSyntaxDefinition"];
	[scriptView recolorCompleteFile:self];
}


#pragma mark •••Accessors

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];

	[notifyCenter addObserver: self 
					 selector: @selector(scriptChanged:) 
						 name: ORFilterScriptChanged 
					   object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(nameChanged:)
                         name : ORFilterNameChanged
						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(argsChanged:)
                         name : ORFilterArgsChanged
						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(textDidChange:)
                         name : NSTextDidChangeNotification
						object: scriptView];	

    [notifyCenter addObserver : self
                     selector : @selector(lastFileChanged:)
                         name : ORFilterLastFileChangedChanged
						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORFilterLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
					   
   [notifyCenter addObserver : self
                     selector : @selector(displayValuesChanged:)
                         name : ORFilterDisplayValuesChanged
                       object : model];
					   
   [notifyCenter addObserver : self
                     selector : @selector(timerEnabledChanged:)
                         name : ORFilterTimerEnabledChanged
                       object : model];

   [notifyCenter addObserver : self
                     selector : @selector(updateTiming:)
                         name : ORFilterUpdateTiming
                       object : model];

   [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : inputVariablesTableView];

   [notifyCenter addObserver : self
                     selector : @selector(pluginPathChanged:)
                         name : ORFilterModelPluginPathChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pluginValidChanged:)
                         name : ORFilterModelPluginValidChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(usePluginChanged:)
                         name : ORFilterModelUsePluginChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];
	[self scriptChanged:nil];
	[self lastFileChanged:nil];
	[self timerEnabledChanged:nil];
	[self pluginPathChanged:nil];
	[self pluginValidChanged:nil];
	[self usePluginChanged:nil];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self checkGlobalSecurity];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORFilterLock to:secure];
    [lockButton setEnabled:secure];
	[removeInputButton setEnabled:[[inputVariablesTableView selectedRowIndexes] count] >0];
}


#pragma mark •••Interface Management

- (void) usePluginChanged:(NSNotification*)aNote
{
	[usePluginMatrix selectCellWithTag: [model usePlugin]];
	[self setLabelFields];
}

- (void) setLabelFields
{
	if([model usePlugin]){
		[typeField setStringValue:@"Plugin:"];
		[lastFileField setStringValue:[[[model pluginPath] lastPathComponent] stringByDeletingPathExtension]];
	}
	else {
		[typeField setStringValue:@"Script:"];
		[lastFileField setStringValue:[[model lastFile] stringByAbbreviatingWithTildeInPath]];
	}

}

- (void) pluginValidChanged:(NSNotification*)aNote
{
	[pluginValidField setStringValue: [model pluginValid]?@"YES":@"NO"];
	[pluginValidField setTextColor:[model pluginValid] ? 
												[NSColor colorWithCalibratedRed:0 green:.5 blue:0 alpha:1] :
												[NSColor colorWithCalibratedRed:.5 green:0 blue:0 alpha:1]];
}

- (void) pluginPathChanged:(NSNotification*)aNote
{
	[pluginPathField setStringValue: [[[model pluginPath] stringByAbbreviatingWithTildeInPath] stringByDeletingLastPathComponent]];
	[pluginNameField setStringValue: [[[model pluginPath] lastPathComponent] stringByDeletingPathExtension]];
	[self setLabelFields];
}


- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORFilterLock];
    [lockButton setState: locked];
    
}

- (void) updateTiming:(NSNotification*)aNote
{
	[timePlot setNeedsDisplay:YES];
}

- (void) lastFileChanged:(NSNotification*)aNote
{
	[self setLabelFields];
}

- (void) textDidChange:(NSNotification*)aNote
{
	[model setScriptNoNote:[scriptView string]];
}

- (void) timerEnabledChanged:(NSNotification*)aNote
{
	[timerEnabledCB setState:[model timerEnabled]];
	[timePlot setNeedsDisplay:YES];
}

- (void) scriptChanged:(NSNotification*)aNote
{
	[scriptView setString:[model script]];
}

- (void) displayValuesChanged:(NSNotification*)aNote
{
	[outputVariablesTableView reloadData];
}

#pragma mark •••Actions

- (IBAction) usePluginAction:(id)sender
{
	[model setUsePlugin:[[sender selectedCell] tag]];	
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORFilterLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) addInput:(id)sender
{
	[model addInputValue];
	[inputVariablesTableView reloadData];
}

- (IBAction) removeInput:(id)sender
{
	NSIndexSet* indexSet = [inputVariablesTableView selectedRowIndexes];
	int i;
	int last = [indexSet lastIndex];
	for(i=last;i!=NSNotFound;i = [indexSet indexLessThanIndex:i]){
		[model removeInputValue:i];
	}
	[inputVariablesTableView reloadData];
}

- (IBAction) selectPluginPath:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[model pluginPath] stringByExpandingTildeInPath];
    if(fullPath) startingDir = [fullPath stringByDeletingLastPathComponent];
    else		 startingDir = NSHomeDirectory();

    [openPanel beginSheetForDirectory:startingDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(pluginPathSelectDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];

}

- (IBAction) enableTimer:(id)sender
{
	[model setTimerEnabled:[sender state]];
}

- (IBAction) listMethodsAction:(id) sender
{
	NSString* theClassName = [classNameField stringValue];
	if([theClassName length]){
		NSLog(@"\n%@\n",listMethods(NSClassFromString(theClassName)));
	}
}

- (IBAction) cancelLoadSaveAction:(id)sender
{
	[loadSaveView orderOut:self];
	[[NSApplication sharedApplication]  endSheet:loadSaveView];
}

- (IBAction) parseScript:(id) sender
{
	[statusField setStringValue:@""];	
	[self endEditing];
	[model setScript:[scriptView string]];
	[model parseScript];
	if([model parsedOK])[statusField setStringValue:@"Parsed OK"];
	else [statusField setStringValue:@"ERRORS"];
}
	
- (IBAction) nameAction:(id) sender
{
	[model setScriptName:[sender stringValue]];
	[[self window] setTitle:[NSString stringWithFormat:@"Script: %@",[sender stringValue]]];
}

- (IBAction) loadSaveAction:(id)sender
{
	[[NSApplication sharedApplication] beginSheet:loadSaveView
								   modalForWindow:[self window]
									modalDelegate:self
								   didEndSelector:NULL
									  contextInfo:NULL];
	[self setLabelFields];
}


- (IBAction) loadFileAction:(id) sender
{
	[loadSaveView orderOut:self];
	[[NSApplication sharedApplication]  endSheet:loadSaveView];
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[model lastFile] stringByExpandingTildeInPath];
    if(fullPath) startingDir = [fullPath stringByDeletingLastPathComponent];
    else		 startingDir = NSHomeDirectory();

    [openPanel beginSheetForDirectory:startingDir
                                 file:nil
                                types:[NSArray arrayWithObjects:@"fs",nil]
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(loadFileDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (IBAction) saveAsFileAction:(id) sender
{
	[loadSaveView orderOut:self];
	[[NSApplication sharedApplication]  endSheet:loadSaveView];
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[model lastFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = @"Untitled.fs";
    }
	
    [savePanel beginSheetForDirectory:startingDir
                                 file:defaultFile
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(saveFileDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (IBAction) saveFileAction:(id) sender
{
	[loadSaveView orderOut:self];
	[[NSApplication sharedApplication]  endSheet:loadSaveView];
	if(![model lastFile]){
		[self saveAsFileAction:nil];
	}
	else [model saveFile];
}

- (int) numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
    return kFilterTimeHistoSize;
}

- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x
{
	return [model processingTimeHist:x];
}


- (int)numberOfRowsInTableView:(NSTableView *)aTable
{
	if(aTable == inputVariablesTableView) return ([[model inputValues] count]);
	else  return ([[model outputValues] count]);
}

- (id) tableView:(NSTableView *)aTable objectValueForTableColumn:(NSTableColumn *)aCol row:(int)aRow
{
	id anArray;
	if(aTable == inputVariablesTableView) anArray= [model inputValues];
	else								  anArray= [model outputValues];
	return [[anArray objectAtIndex:aRow] objectForKey:[aCol identifier]];
}

- (void) tableView:(NSTableView*)aTable setObjectValue:(id)aData forTableColumn:(NSTableColumn*)aCol row:(int)aRow
{
	if(aTable == inputVariablesTableView) {
		[[[model inputValues] objectAtIndex:aRow] setObject: aData forKey:[aCol identifier]];	
	}
}


@end

@implementation ORFilterController (private)

- (void) pluginPathSelectDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model setPluginPath:[[[sheet filenames] objectAtIndex:0]stringByAbbreviatingWithTildeInPath]];
		[model loadPlugin]; 
    }
}


- (void) loadFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model loadScriptFromFile:[[[sheet filenames] objectAtIndex:0]stringByAbbreviatingWithTildeInPath]];
    }
}

- (void) saveFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
		NSString* path = [[sheet filename] stringByDeletingPathExtension];
		path = [path stringByAppendingPathExtension:@"fs"];
        [model saveScriptToFile:path];
    }
}
@end
