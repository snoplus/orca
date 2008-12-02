//-------------------------------------------------------------------------
//  RunScriptController.h
//
//  Created by Mark A. Howe on Tuesday 12/26/2006.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import <Cocoa/Cocoa.h>
#import "ORRunScriptController.h"
#import "ORRunScriptModel.h"
#import "ORScriptRunner.h"
#import "ORTimedTextField.h"
#import "ORScriptView.h"

@interface ORRunScriptController (private)
- (void) loadFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

@implementation ORRunScriptController
-(id)init
{
    self = [super initWithWindowNibName:@"RunScript"];
    return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[commentsView setAllowsUndo:YES];
	[statusField setTimeOut:1.5];
	NSString*   path = [[NSBundle mainBundle] pathForResource: @"OrcaScriptGuide" ofType: @"rtf"];
	[helpView readRTFDFromFile:path];
}

- (void) setModel:(id)aModel
{
	[scriptView setSelectedRange: NSMakeRange(0,0)];
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Run Script: %@",[model identifier]]];
	[[self window] makeFirstResponder:scriptView];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunScriptLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
	[notifyCenter addObserver: self 
					 selector: @selector(scriptChanged:) 
						 name: ORRunScriptScriptChanged 
					   object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(runningChanged:)
                         name : ORScriptRunnerRunningChanged
						object: [model scriptRunner]];	

    [notifyCenter addObserver : self
                     selector : @selector(errorChanged:)
                         name : ORScriptRunnerParseError
						object: [model scriptRunner]];	

    [notifyCenter addObserver : self
                     selector : @selector(nameChanged:)
                         name : ORRunScriptNameChanged
						object: model];	

	[notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : inputVariablesTableView];
	
    [notifyCenter addObserver : self
                     selector : @selector(textDidChange:)
                         name : NSTextDidChangeNotification
						object: scriptView];	

    [notifyCenter addObserver : self
                     selector : @selector(lastFileChanged:)
                         name : ORRunScriptLastFileChangedChanged
						object: model];	
	
	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    [notifyCenter addObserver : self
                     selector : @selector(showSuperClassChanged:)
                         name : ORRunScriptModelShowSuperClassChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(commentsChanged:)
                         name : ORRunScriptModelCommentsChanged
						object: model];
}

- (void) updateWindow
{
	[super updateWindow];
	[self scriptChanged:nil];
	[self runningChanged:nil];
	[self nameChanged:nil];
	[self lastFileChanged:nil];
	[self showSuperClassChanged:nil];
	[self commentsChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORRunScriptLock to:secure];
    [lockButton setEnabled:secure];
	[self lockChanged:nil];
}

#pragma mark •••Interface Management

- (void) commentsChanged:(NSNotification*)aNote
{
	[commentsView setString: [model comments]];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORRunScriptLock];
    [lockButton setState: locked];
	
    [addInputButton setEnabled:!locked];
	[removeInputButton setEnabled:!locked && ([[inputVariablesTableView selectedRowIndexes] count] > 0)];
}

- (void) displayValuesChanged:(NSNotification*)aNote
{
	[outputVariablesTableView reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self checkGlobalSecurity];
}

- (void) showSuperClassChanged:(NSNotification*)aNote
{
	[showSuperClassButton setIntValue: [model showSuperClass]];
}

- (void) lastFileChanged:(NSNotification*)aNote
{
	[lastFileField setStringValue:[[model lastFile] stringByAbbreviatingWithTildeInPath]];
	[lastFileField1 setStringValue:[[model lastFile] stringByAbbreviatingWithTildeInPath]];
}

- (void) textDidChange:(NSNotification*)aNote
{
	[model setScriptNoNote:[scriptView string]];
}

- (void) scriptChanged:(NSNotification*)aNote
{
	[scriptView setString:[model script]];
}

- (void) nameChanged:(NSNotification*)aNote
{
	[nameField setStringValue:[model scriptName]];
}


- (void) errorChanged:(NSNotification*)aNote
{
	int lineNumber = [[[aNote userInfo] objectForKey:@"ErrorLocation"] intValue];
	[scriptView goToLine:lineNumber];
}

- (void) runningChanged:(NSNotification*)aNote
{
	if([model running]){
		[statusField setStringValue:@"Started"];
		[runStatusField setStringValue:@"Running"];
		
		[runButton setImage:[NSImage imageNamed:@"Stop"]];
		[runButton setAlternateImage:[NSImage imageNamed:@"Stop"]];
		[loadSaveButton setEnabled:NO];
	}
	else {
		[statusField setStringValue:@""];
		[runStatusField setStringValue:@""];
		[runButton setImage:[NSImage imageNamed:@"Play"]];
		[runButton setAlternateImage:[NSImage imageNamed:@"Play"]];
		[loadSaveButton setEnabled:YES];
	}
}

#pragma mark •••Actions

- (void) commentsAction:(id)sender
{
	[model setComments:[sender stringValue]];	
}
- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORRunScriptLock to:[sender intValue] forWindow:[self window]];
}
- (void) showSuperClassAction:(id)sender
{
	[model setShowSuperClass:[sender intValue]];	
}

- (IBAction) listMethodsAction:(id) sender
{
	NSString* theClassName = [classNameField stringValue];
	if([theClassName length]){
		NSLog(@"\n%@\n",listMethodWithOptions(NSClassFromString(theClassName),YES,[model showSuperClass]));
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
	
- (IBAction) runScript:(id) sender
{
	[statusField setStringValue:@""];	
	[self endEditing];
	[model setScript:[scriptView string]];
	BOOL showError;
	if(![model running]) showError = YES;
	else showError = NO;
	[model runScript];
	if(showError){
		if([model parsedOK])[statusField setStringValue:@"Parsed OK"];
		else [statusField setStringValue:@"ERRORS"];
	}
}

- (IBAction) nameAction:(id) sender
{
	[model setScriptName:[sender stringValue]];
	[[self window] setTitle:[NSString stringWithFormat:@"Run Script: %@",[model scriptName]]];
}


- (IBAction) loadSaveAction:(id)sender
{
	[[NSApplication sharedApplication] beginSheet:loadSaveView
								   modalForWindow:[self window]
									modalDelegate:self
								   didEndSelector:NULL
									  contextInfo:NULL];
	[lastFileField setStringValue:[[model lastFile] stringByAbbreviatingWithTildeInPath]];
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
                                types:nil
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
        defaultFile = @"Untitled";
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


- (int)numberOfRowsInTableView:(NSTableView *)aTable
{
	if(aTable == inputVariablesTableView) return ([[model inputValues] count]);
	else  return 0;
}

- (id) tableView:(NSTableView *)aTable objectValueForTableColumn:(NSTableColumn *)aCol row:(int)aRow
{
	id anArray;
	if(aTable == inputVariablesTableView) anArray= [model inputValues];
	else								  anArray= nil;
	return [[anArray objectAtIndex:aRow] objectForKey:[aCol identifier]];
}

- (void) tableView:(NSTableView*)aTable setObjectValue:(id)aData forTableColumn:(NSTableColumn*)aCol row:(int)aRow
{
	if(aTable == inputVariablesTableView) {
		[[[model inputValues] objectAtIndex:aRow] setObject: aData forKey:[aCol identifier]];	
	}
}

@end

@implementation ORRunScriptController (private)
- (void)loadFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model loadScriptFromFile:[[[sheet filenames] objectAtIndex:0]stringByAbbreviatingWithTildeInPath]];
    }
}

- (void)saveFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model saveScriptToFile:[sheet filename]];
    }
}
@end

