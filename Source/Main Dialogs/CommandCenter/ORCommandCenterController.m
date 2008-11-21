//
//  ORCommandCenterController.m
//  Orca
//
//  Created by Mark Howe on Thu Nov 06 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORCommandCenterController.h"
#import "ORCommandCenter.h"
#import "ORScriptRunner.h"
#import "ORScriptView.h"
#import "Utilities.h"
#import "SynthesizeSingleton.h"

@interface ORCommandCenterController (private)
- (void)_processFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) loadFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

@implementation ORCommandCenterController

SYNTHESIZE_SINGLETON_FOR_ORCLASS(CommandCenterController);

-(id)init
{
    self = [super initWithWindowNibName:@"CommandCenter"];
    [self setWindowFrameAutosaveName:@"CommandCenter"];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) awakeFromNib
{
	
    [self registerNotificationObservers];
	[panelView addSubview:argsView];
	NSString*   path = [[NSBundle mainBundle] pathForResource: @"OrcaScriptGuide" ofType: @"rtf"];
	[helpView readRTFDFromFile:path];
    [self updateWindow];
	[cmdField setDelegate:self];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[self commandCenter]  undoManager];
}


#pragma mark •••Accessors
- (ORCommandCenter*) commandCenter
{
    return [ORCommandCenter sharedCommandCenter];
}

- (NSString *)lastPath {
    return lastPath;
}

- (void)setLastPath:(NSString *)aLastPath {
    [lastPath autorelease];
    lastPath = [aLastPath copy];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(portChanged:)
                         name : ORCommandPortChangedNotification
                       object : [self commandCenter]];
    
    [notifyCenter addObserver : self
                     selector : @selector(clientsChanged:)
                         name : ORCommandClientsChangedNotification
                       object : [self commandCenter]];
    

    [notifyCenter addObserver : self
                     selector : @selector(commandChanged:)
                         name : ORCommandCommandChangedNotification
                       object : [self commandCenter]];

    
    [notifyCenter addObserver : self
                     selector : @selector(portChanged:)
                         name : ORDocumentLoadedNotification
                       object : [self commandCenter]];
    
    [notifyCenter addObserver : self
                     selector : @selector(argsChanged:)
                         name : ORCommandArgsChanged
						object: [self commandCenter]];	


	[notifyCenter addObserver: self 
					 selector: @selector(scriptChanged:) 
						 name: ORCommandScriptChanged 
					   object: [self commandCenter]];
	
    [notifyCenter addObserver : self
                     selector : @selector(runningChanged:)
                         name : ORScriptRunnerRunningChanged
						object: [[self commandCenter] scriptRunner]];	

    [notifyCenter addObserver : self
                     selector : @selector(errorChanged:)
                         name : ORScriptRunnerParseError
						object: [[self commandCenter] scriptRunner]];	


    [notifyCenter addObserver : self
                     selector : @selector(textDidChange:)
                         name : NSTextDidChangeNotification
						object: scriptView];	

    [notifyCenter addObserver : self
                     selector : @selector(lastFileChanged:)
                         name : ORCommandLastFileChangedNotification
						object: [self commandCenter]];	

	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];

}
- (void) endEditing
{
	//commit all text editing... subclasses should call before doing their work.
	//id oldFirstResponder = [[self window] firstResponder];
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}
	//[[self window] makeFirstResponder:oldFirstResponder];
}


#pragma mark •••Actions

- (IBAction) cancelLoadSaveAction:(id)sender
{
	[loadSaveView orderOut:self];
	[[NSApplication sharedApplication]  endSheet:loadSaveView];
}

- (IBAction) parseScript:(id) sender
{
	[statusField setStringValue:@""];	
	[self endEditing];
	[[self commandCenter] setScript:[scriptView string]];
	[[self commandCenter] parseScript];
	if([[self commandCenter] parsedOK])[statusField setStringValue:@"Parsed OK"];
	else [statusField setStringValue:@"ERRORS"];
}
	
- (IBAction) runScript:(id) sender
{
	[statusField setStringValue:@""];	
	[self endEditing];
	[[self commandCenter] setScript:[scriptView string]];
	BOOL showError;
	if(![[self commandCenter] running]) showError = YES;
	else showError = NO;
	[[self commandCenter] runScript];
	if(showError){
		if([[self commandCenter] parsedOK])[statusField setStringValue:@"Parsed OK"];
		else [statusField setStringValue:@"ERRORS"];
	}
}

- (IBAction) setPortAction:(id) sender;
{
    if([sender intValue] != [[self commandCenter] socketPort]){
        [[self commandCenter] setSocketPort:[sender intValue]];
        [[self commandCenter] serve];
    }
}


- (IBAction) doCmdAction:(id) sender
{
    [self performSelector:@selector(sendCommand:) withObject:[cmdField stringValue] afterDelay:.01];
}

- (IBAction) processFileAction:(id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Select"];
    [openPanel beginSheetForDirectory:[self lastPath]
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(_processFilePanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (IBAction) loadSaveAction:(id)sender
{
	[[NSApplication sharedApplication] beginSheet:loadSaveView
								   modalForWindow:[self window]
									modalDelegate:self
								   didEndSelector:NULL
									  contextInfo:NULL];
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
	NSString* fullPath = [[[self commandCenter] lastFile] stringByExpandingTildeInPath];
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


- (IBAction) saveFileAction:(id) sender
{
	[loadSaveView orderOut:self];
	[[NSApplication sharedApplication]  endSheet:loadSaveView];
	if(![[self commandCenter] lastFile]){
		[self saveAsFileAction:nil];
	}
	else [[self commandCenter] saveFile];
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
    
	NSString* fullPath = [[[self commandCenter] lastFile] stringByExpandingTildeInPath];
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
                       didEndSelector:@selector(saveFileDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
}

- (IBAction) listMethodsAction:(id) sender
{
	NSString* theClassName = [classNameField stringValue];
	if([theClassName length]){
		NSLog(@"\n%@\n",listMethods(NSClassFromString(theClassName)));
	}
}

- (void) sendCommand:(NSString*)aCmd
{
    [[self commandCenter] handleLocalCommand:aCmd];
}

- (IBAction) saveDocument:(id)sender
{
    [[[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[[NSApp delegate]document] saveDocumentAs:sender];
}

- (IBAction) argAction:(id) sender
{
	int i = [[sender selectedCell] tag];
	NSDecimalNumber* n;
	NSString* s = [[sender selectedCell] stringValue];
	if([s rangeOfString:@"x"].location != NSNotFound || [s rangeOfString:@"X"].location != NSNotFound){
		unsigned long num = strtoul([s cStringUsingEncoding:NSASCIIStringEncoding],0,16);
		n = (NSDecimalNumber*)[NSDecimalNumber numberWithUnsignedLong:num];
	}
	else n = [NSDecimalNumber decimalNumberWithString:s];
	[[self commandCenter] setArg:i withValue:n];
}

#pragma mark •••Interface Management
- (void) updateWindow
{
    [self portChanged:nil];
    [self clientsChanged:nil];
	[self scriptChanged:nil];
	[self runningChanged:nil];
	[self argsChanged:nil];
	[self lastFileChanged:nil];
}

- (void) lastFileChanged:(NSNotification*)aNote
{
	[lastFileField setStringValue:[[[self commandCenter] lastFile] stringByAbbreviatingWithTildeInPath]];
	[lastFileField1 setStringValue:[[[self commandCenter] lastFile] stringByAbbreviatingWithTildeInPath]];
}

- (void) commandChanged:(NSNotification*)aNote
{
	NSString* aCommand = [[aNote userInfo] objectForKey:ORCommandCommandChangedNotification];
	if(aCommand){
		[cmdField setStringValue:aCommand];
	}
}

- (void) argsChanged:(NSNotification*)aNote;
{
	int i;
	for(i=0;i<5;i++){
		[[argsMatrix cellWithTag:i] setObjectValue:[[self commandCenter] arg:i]];
	}
}

- (void) portChanged:(NSNotification*)aNotification;
{
    if(aNotification==nil  || [aNotification object]== [self commandCenter]){
        [portField setIntValue: [[self commandCenter] socketPort]];
    }
}

- (void) clientsChanged:(NSNotification*)aNotification
{
    if(aNotification==nil  || [aNotification object]== [self commandCenter]){
        [clientListView reloadData];
        [portField setEnabled:[[self commandCenter] clientCount]==0];
		[clientCountField setIntValue:[[self commandCenter] clientCount]];
    }
}

- (void) textDidChange:(NSNotification*)aNote
{
	[[self commandCenter] setScriptNoNote:[scriptView string]];
}

- (void) scriptChanged:(NSNotification*)aNote
{
	[scriptView setString:[[self commandCenter] script]];
}

- (void) errorChanged:(NSNotification*)aNote
{
	int lineNumber = [[[aNote userInfo] objectForKey:@"ErrorLocation"] intValue];
	[scriptView goToLine:lineNumber];
}

- (void) runningChanged:(NSNotification*)aNote
{
	if([[self commandCenter] running]){
		[statusField setStringValue:@"Running"];
		[runButton setImage:[NSImage imageNamed:@"Stop"]];
		[runButton setAlternateImage:[NSImage imageNamed:@"Stop"]];
		[loadSaveButton setEnabled:NO];
	}
	else {
		[statusField setStringValue:@""];
		[runButton setImage:[NSImage imageNamed:@"Play"]];
		[runButton setAlternateImage:[NSImage imageNamed:@"Play"]];
		[loadSaveButton setEnabled:YES];
	}
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	if ((command == @selector(moveDown:))) {
		[[self commandCenter] moveInHistoryDown];
		return YES;
	}
	if ((command == @selector(moveUp:))) {
		[[self commandCenter] moveInHistoryUp];	
		return YES;
	}
	return NO;
}



#pragma mark •••Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    id obj = [[[self commandCenter] clients]  objectAtIndex:rowIndex];
    return [obj valueForKey:[aTableColumn identifier]];
}

// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[[self commandCenter] clients] count];
}

@end

@implementation ORCommandCenterController (private)
- (void)_processFilePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* path = [[sheet filenames] objectAtIndex:0];
        [self setLastPath:[path stringByDeletingLastPathComponent]];
        [self sendCommand:[NSString stringWithContentsOfFile:path]];
    }
}

- (void)loadFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [[self commandCenter] loadScriptFromFile:[[[sheet filenames] objectAtIndex:0]stringByAbbreviatingWithTildeInPath]];
    }
}

- (void)saveFileDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [[self commandCenter] saveScriptToFile:[sheet filename]];
    }
}
@end

