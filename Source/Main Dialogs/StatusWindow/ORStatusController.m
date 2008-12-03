//----------------------------------------------------------------------------------------------------
//  ORStatusController.h
//  Controlls access to the array of comments in the status window.
//
//  Created by Mark Howe on Wed Jan 02 2002.
//  Copyright  © 2001 CENPA. All rights reserved.
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
#import "ORStatusController.h"
#import "ORDataSet.h"
#import "ORRunModel.h"
#import "ORMailCenter.h"
#import "SynthesizeSingleton.h"

NSString* ORStatusFlushedNotification = @"ORStatusFlushedNotification";
NSString* ORStatusFlushSize	      = @"ORStatusFlushSize";

ORStatusController* theLogger = nil;

@interface ORStatusController (private)
- (void) loadLogBookPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveAsLogBookDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

#define kStatusConnection @"StatusConnection"
#define kMaxTextSize 40000

@implementation ORStatusController

#pragma mark ¥¥¥Initialization

SYNTHESIZE_SINGLETON_FOR_ORCLASS(StatusController);

- (id)init
{
    if (self = [super initWithWindowNibName:@"StatusWindow"]) {
        [self setWindowFrameAutosaveName:@"StatusWindow"];
        theLogger = self;
        if(!dataSet){
            [self setDataSet:[[[ORDataSet alloc]initWithKey:@"Errors" guardian:nil] autorelease] ];
        }
        
    }
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [dataSet release];
    [super dealloc];
}

-(void)awakeFromNib
{
    [statusView setEditable:NO];
    [outlineView setDataSource:self];
    [self showWindow:self];
    
	logBookDirty = NO;
	[saveLogBookButton setEnabled:NO];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSControlTextDidChangeNotification object:logBookField];
	
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[NSApp delegate]  undoManager];
}

#pragma mark ¥¥¥Accessors
- (void) setLogBookFile:(NSString*)aFilePath
{
	[[[[NSApp delegate] undoManager] prepareWithInvocationTarget:self] setLogBookFile:logBookFile];
	
	if(!aFilePath)aFilePath = [@"~/OrcaLogBook.rtfd" stringByExpandingTildeInPath];
	if(![[aFilePath pathExtension] isEqualToString:@"rtfd"]){
		aFilePath = [[aFilePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"rtfd"];
	}
    [logBookFile autorelease];
    logBookFile = [aFilePath copy];
	
	[logBookPathField setStringValue:[logBookFile stringByAbbreviatingWithTildeInPath]];
	
	if([[NSFileManager defaultManager]  fileExistsAtPath:logBookFile]){
		if(![logBookField readRTFDFromFile:logBookFile]){
			NSLogColor([NSColor redColor],@"Couldn't open LogBook <%@>.\n",logBookFile);
		}
	}
	else {
		[logBookField setString:@""];
	}
}

- (oneway void) setDataSet: (ORDataSet *) aDataSet
{
    [aDataSet retain];
    [dataSet release];
    dataSet = aDataSet;
}

- (NSString*) errorSummary
{
    NSMutableString* string = [NSMutableString stringWithCapacity:1024];
    return [NSString stringWithFormat:@"%@",[dataSet summarizeIntoString:string]];
}

-(oneway void) printString: (NSString*)s1
{
	[s1 retain];
    [statusView replaceCharactersInRange:NSMakeRange([self statusTextlength], 0) withString:s1];
    [statusView scrollRangeToVisible: NSMakeRange([self statusTextlength], 0)];
    
    if([self statusTextlength] > kMaxTextSize){
        [[statusView textStorage] deleteCharactersInRange:NSMakeRange(0,kMaxTextSize/3)];
        NSRange endOfLineRange = [[self text] rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];
        int extra = 0;
        if(endOfLineRange.location != NSNotFound){
            [[statusView textStorage] deleteCharactersInRange:NSMakeRange(0,endOfLineRange.location)];
            extra = endOfLineRange.location;
        }
        [[NSNotificationCenter defaultCenter]
		 postNotificationName:ORStatusFlushedNotification
		 object:self
		 userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:kMaxTextSize/3+extra],ORStatusFlushSize,nil]];
    }
    [s1 release];
}

-(void)printString: (NSString*)s1 withColor:(NSColor*)aColor
{
	[s1 retain];
    [self printString:s1];
    int len = [s1 length];
 	[s1 release];
	
    [[statusView textStorage] setAttributes:[NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName ]
                                      range:NSMakeRange([self statusTextlength]-len,16)];
    
    [[statusView textStorage] setAttributes:[NSDictionary dictionaryWithObject:aColor forKey:NSForegroundColorAttributeName ]
                                      range:NSMakeRange([self statusTextlength]-len+16,len-16)];
    
    
}

-(void)printString: (NSString*)s1 withFont:(NSFont*)aFont
{
	[s1 retain];
    [self printString:s1];
    int len = [s1 length];
 	[s1 release];
	
    [[statusView textStorage] setAttributes:[NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName ]
                                      range:NSMakeRange([self statusTextlength]-len,16)];
    
    [[statusView textStorage] setAttributes:[NSDictionary dictionaryWithObject:aFont forKey:NSFontAttributeName ]
                                      range:NSMakeRange([self statusTextlength]-len+16,len-16)];
    
    
}


- (oneway void) logError: (NSString*)anError usingKeyArray:(NSArray*)keys
{
    
    if(!dataSet){
        [self setDataSet:[[[ORDataSet alloc]initWithKey:@"Errors" guardian:nil] autorelease] ];
    }
    
    [dataSet loadGenericData:anError sender:nil usingKeyArray:keys];
    [errorTextField setStringValue:[keys lastObject]];
    
    if(!scheduledToUpdate){
        scheduledToUpdate = YES;
        [self performSelector:@selector(updateErrorDisplay) withObject:nil afterDelay:1.0];
    }
}

- (void) updateErrorDisplay
{
    scheduledToUpdate = NO;
    [outlineView reloadItem:dataSet reloadChildren:YES];
    [errorField setIntValue:[dataSet totalCounts]];
}

- (int) statusTextlength
{
    return [[statusView textStorage] length];
}

- (NSString*) text
{
    return [[statusView textStorage] string];
}

- (IBAction) saveDocument:(id)sender
{
    [[[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[[NSApp delegate]document] saveDocumentAs:sender];
}


#pragma mark ¥¥¥Data Source Methods
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return (item == nil) ? 1  : [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return    (item == nil) ? YES : ([item numberOfChildren] != 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item)   return [item childAtIndex:index];
    else	return dataSet;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return  ((item == nil) ? [self name] : [item name]);
}

- (unsigned)  numberOfChildren
{
    return [dataSet count];
}

- (id)   childAtIndex:(int)index
{
    NSEnumerator* e = [dataSet objectEnumerator];
    id obj;
    id child = nil;
    short i = 0;
    while(obj = [e nextObject]){
        if(i++ == index){
            child = obj;
            break;
        }
    }
    return child;
}

- (id)   name
{
    return @"Errors";
}

#pragma mark ¥¥¥Actions
- (IBAction) expandAction:(id)sender
{
    id selectedObj = [outlineView itemAtRow:[outlineView selectedRow]];
    [outlineView expandItem:selectedObj expandChildren:YES];
}

- (IBAction) clearAllAction:(id)sender
{
    [dataSet clear];
    [outlineView reloadItem:dataSet  reloadChildren:YES];
    [outlineView setNeedsDisplay:YES];
    [errorField setIntValue:[dataSet totalCounts]];
}

- (IBAction)delete:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction)cut:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction)selectAll:(id)sender
{
    [outlineView selectAll:sender];
}

- (IBAction) insertDate:(id)sender
{
	NSString* theDate = [[NSCalendarDate calendarDate] descriptionWithCalendarFormat:@"%m/%d/%y %H:%M"];
	[logBookField insertText:theDate];
}

- (IBAction) insertConfigurationName:(id)sender
{
	NSString* theConfigFile = [NSString stringWithFormat:@"Configuration File: %@",[[[NSApp delegate] document] fileName]];
	[logBookField insertText: theConfigFile];
}

- (IBAction) insertRunNumber:(id)sender
{
	NSArray* runControlObjects = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
	NSString* theRun;
	if([runControlObjects count]){
		theRun = [NSString stringWithFormat:@"Run Number %d",[[runControlObjects objectAtIndex:0] runNumber]];
	}
	else {
		theRun = @"No Run Control Obj";
	}
	[logBookField insertText:theRun];
}

- (IBAction) mailContent:(id)sender
{
	NSString* tabIdentifer = [[tabView selectedTabViewItem]identifier];
	if([tabIdentifer isEqualToString:@"status"]){
		ORMailCenter* theMailCenter = [ORMailCenter mailCenter];
		[theMailCenter showWindow:self];
		[theMailCenter setTextBodyToRTFData:[statusView RTFFromRange:NSMakeRange(0,[[statusView string] length])]];
	}
	else if([tabIdentifer isEqualToString:@"logBook"]){
		ORMailCenter* theMailCenter = [ORMailCenter mailCenter];
		[theMailCenter showWindow:self];
		[self saveLogBook:self];
		[theMailCenter setFileToAttach:logBookFile];
	}
}


- (IBAction) removeItemAction:(id)sender
{ 
    NSArray *selection = [outlineView allSelectedItems];
    NSEnumerator* e = [selection objectEnumerator];
    id item;
    while(item = [e nextObject]){
        [self removeDataSet:item];
    }
    [outlineView deselectAll:self];
    [dataSet recountTotal];
    [errorField setIntValue:[dataSet totalCounts]];
    [outlineView reloadData];
    
}

- (IBAction) saveLogBook:(id)sender
{
	if(!logBookFile)return;
	if(logBookDirty)[[[NSApp delegate] document] updateChangeCount:NSChangeUndone];
	
	if([logBookFile isEqualToString:@"untitled.rtfd"]){
		[self saveAsLogBook:nil];
	}
	else {
		[logBookField writeRTFDToFile:logBookFile atomically:YES];
		logBookDirty = NO;
		[saveLogBookButton setEnabled:NO];
	}
	
}

- (IBAction) saveAsLogBook:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if(logBookFile){
        startDir = [logBookFile stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    [savePanel beginSheetForDirectory:startDir
								 file:nil
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(saveAsLogBookDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}

- (IBAction) loadLogBook:(id)sender
{
    NSString* startDir = NSHomeDirectory(); //default to home
    if(logBookFile){
        startDir = [logBookFile stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Load Log Book"];
    [openPanel beginSheetForDirectory:startDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(loadLogBookPanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
	
}

- (IBAction) newLogBook:(id)sender
{
	int choice = NSRunAlertPanel(@"Starting a new logbook.",@"Is this really what you want?\nAny unsaved changes will be lost!",@"Cancel",@"Yes, Make New LogBook",nil);
	if(choice == NSAlertAlternateReturn){		
		[logBookField setString:@""];
		[self setLogBookFile:@"untitled"];
	}
}

- (void) removeDataSet:(ORDataSet*)item
{
    if([[item name] rangeOfString:[self name]].location != NSNotFound) {
        [self setDataSet:[[[ORDataSet alloc]initWithKey:@"Errors" guardian:nil] autorelease] ];
    }
    else [dataSet removeObject:item];
}

#pragma  mark ¥¥¥Delegate Responsiblities
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}

- (NSString*) substringWithRange:(NSRange)aRange
{
    NSString* text;
    @try {
        text = [[[[self text] substringWithRange:aRange]retain] autorelease];
	}
	@catch(NSException* localException) {
        text = @"";
    }
    return text;
}

- (void) handleInvocation:(NSInvocation*) anInvocation
{
    [anInvocation invoke];
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [outlineView selectedRow] >= 0 ;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [outlineView selectedRow] >= 0;
    }
    else if ([menuItem action] == @selector(selectAll:)) {
        return YES;
    }
	else if([menuItem action] == @selector(mailContent:)){
		NSString* tabIdentifer = [[tabView selectedTabViewItem]identifier];
		if([tabIdentifer isEqualToString:@"status"])			return YES;
		else if([tabIdentifer isEqualToString:@"logBook"])	return YES;
		else return NO;
	}
    else  return [[NSApp delegate] validateMenuItem:menuItem];
}

- (void)textDidChange:(NSNotification *)notification
{
	if([notification object] == logBookField){
		if(!logBookDirty)[[[NSApp delegate] document] updateChangeCount:NSChangeDone];
		logBookDirty = YES;
		[saveLogBookButton setEnabled:YES];
	}
}


#pragma mark ¥¥¥Archival
- (void) decode:(NSCoder*) aDecoder
{
	[[[NSApp delegate] undoManager] disableUndoRegistration];
	[self setLogBookFile:[aDecoder decodeObjectForKey:@"LogBookFile"]];
	[[[NSApp delegate] undoManager] enableUndoRegistration];
}

- (void) encode:(NSCoder*) anEncoder
{
	[anEncoder encodeObject:logBookFile forKey:@"LogBookFile"];
}

- (void) loadCurrentLogBook
{
	if(logBookFile){
		[logBookField readRTFDFromFile:logBookFile];
	}
}


@end

@implementation ORPrintableView
- (IBAction) print:(id)sender
{
	
	// set printing properties
	NSPrintInfo* pInfo = [[[NSApp delegate]document] printInfo];
	[pInfo setHorizontalPagination:NSFitPagination];
	[pInfo setHorizontallyCentered:NO];
	[pInfo setVerticallyCentered:NO];
	[pInfo setLeftMargin:36.0];
	[pInfo setRightMargin:36.0];
	[pInfo setTopMargin:72.0];
	[pInfo setBottomMargin:36.0];
	// create new view just for printing
	NSTextView *printView = [[NSTextView alloc]initWithFrame: [pInfo imageablePageBounds]];
	// copy the textview into the printview
	NSData* textData = [self RTFDFromRange:NSMakeRange(0, [[self textStorage] length])];
	NSRange textViewRange = NSMakeRange(0, 0);
	
	[printView replaceCharactersInRange: textViewRange 
							   withRTFD:textData];
	
    [printView setDrawsBackground:NO];
	
	NSPrintOperation* op = [NSPrintOperation printOperationWithView: printView printInfo: 
							pInfo];
	//[op setShowsProgressPanel: YES];
	[op runOperationModalForWindow:[self window] delegate:nil didRunSelector:nil contextInfo:nil];
	
	
	[printView release];
	
}

@end

@implementation ORPrintableOutlineView
- (IBAction) print:(id)sender
{
	// set printing properties
	NSPrintInfo* pInfo = [[[NSApp delegate]document] printInfo];
	[pInfo setHorizontalPagination:NSFitPagination];
	[pInfo setHorizontallyCentered:NO];
	[pInfo setVerticallyCentered:NO];
	[pInfo setLeftMargin:36.0];
	[pInfo setRightMargin:36.0];
	[pInfo setTopMargin:72.0];
	[pInfo setBottomMargin:36.0];
	// create new view just for printing
	NSPrintOperation* op = [NSPrintOperation printOperationWithView: self printInfo: pInfo];
	//[op setShowsProgressPanel: YES];
	[op runOperationModalForWindow:[self window] delegate:nil didRunSelector:nil contextInfo:nil];
}

@end


#pragma mark ¥¥¥¥¥Log Helper Function
//----------------------------------------------------------------------------------------------------
//logStatus
//	a helper function to redirect a call to logStatus to a logger defined by the NSApp delegate
//----------------------------------------------------------------------------------------------------
void _nsLog(NSString* s,...)
{
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    NSColor* aColor = [NSColor blackColor];
    @try {
        va_list myArgs;
        va_start(myArgs,s);
        
        NSCalendarDate* now  	= [NSCalendarDate calendarDate];
        [now setCalendarFormat:@"%m%d%y %H:%M:%S"];
        
        NSString* s1 = [NSString stringWithFormat:@"%@ %@",now,[[[NSString alloc] initWithFormat:s
                                                                                          locale:nil
                                                                                       arguments:myArgs] autorelease]];
        va_end(myArgs);
        
        NSInvocation *invocation;
        invocation = [NSInvocation invocationWithMethodSignature:[sharedStatusController methodSignatureForSelector:@selector(printString:withColor:)]];
        
        [invocation setTarget:sharedStatusController];
        [invocation setSelector:@selector(printString:withColor:)];
        [invocation setArgument:&s1 atIndex:2];
        [invocation setArgument:&aColor atIndex:3];
        [invocation retainArguments];
        
        [sharedStatusController performSelectorOnMainThread:@selector(handleInvocation:) withObject:invocation waitUntilDone:NO];
        
        
	}
	@catch(NSException* localException) {
	}
	
 	[pool release];
	
}

//----------------------------------------------------------------------------------------------------
//logStatus
//	a helper function to redirect a call to logStatus to a logger defined by the NSApp delegate
//----------------------------------------------------------------------------------------------------
void NSLogColor(NSColor* aColor,NSString* s,...)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        va_list myArgs;
        va_start(myArgs,s);
        
        NSCalendarDate* now  	= [NSCalendarDate calendarDate];
        [now setCalendarFormat:@"%m%d%y %H:%M:%S"];
        
        NSString* s1 = [NSString stringWithFormat:@"%@ %@",now,[[[NSString alloc] initWithFormat:s
                                                                                          locale:nil
                                                                                       arguments:myArgs] autorelease]];
        va_end(myArgs);
        
        NSInvocation *invocation;
        invocation = [NSInvocation invocationWithMethodSignature:[sharedStatusController methodSignatureForSelector:@selector(printString:withColor:)]];
        
        [invocation setTarget:sharedStatusController];
        [invocation setSelector:@selector(printString:withColor:)];
        [invocation setArgument:&s1 atIndex:2];
        [invocation setArgument:&aColor atIndex:3];
        [invocation retainArguments];
        
        [sharedStatusController performSelectorOnMainThread:@selector(handleInvocation:) withObject:invocation waitUntilDone:NO];
        
        
	}
	@catch(NSException* localException) {
	}
	[pool release];
}

//----------------------------------------------------------------------------------------------------
//logStatus
//	a helper function to redirect a call to logStatus to a logger defined by the NSApp delegate
//----------------------------------------------------------------------------------------------------
void NSLogFont(NSFont* aFont,NSString* s,...)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        va_list myArgs;
        va_start(myArgs,s);
        
        NSCalendarDate* now  	= [NSCalendarDate calendarDate];
        [now setCalendarFormat:@"%m%d%y %H:%M:%S"];
        
        NSString* s1 = [NSString stringWithFormat:@"%@ %@",now,[[[NSString alloc] initWithFormat:s
                                                                                          locale:nil
                                                                                       arguments:myArgs] autorelease]];
        va_end(myArgs);
        
        NSInvocation *invocation;
        invocation = [NSInvocation invocationWithMethodSignature:[sharedStatusController methodSignatureForSelector:@selector(printString:withFont:)]];
        
        [invocation setTarget:sharedStatusController];
        [invocation setSelector:@selector(printString:withFont:)];
        [invocation setArgument:&s1 atIndex:2];
        [invocation setArgument:&aFont atIndex:3];
        [invocation retainArguments];
        
        [sharedStatusController performSelectorOnMainThread:@selector(handleInvocation:) withObject:invocation waitUntilDone:NO];
        
        
	}
	@catch(NSException* localException) {
	}
	[pool release];
}

//----------------------------------------------------------------------------------------------------
//LogError
//	a helper function to redirect a call to logError to a logger defined by the NSApp delegate
//----------------------------------------------------------------------------------------------------
void NSLogError(NSString* aString,...)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        va_list myArgs;
        va_start(myArgs,aString);
        
        NSCalendarDate* now = [NSCalendarDate calendarDate];
        [now setCalendarFormat:@"%m/%d %H:%M:%S"];
        
        NSString* s1 = [NSString stringWithFormat:@"%@ %@",now,aString];
        
        NSMutableArray* theArgs = [NSMutableArray arrayWithCapacity:10];
        while(1) {
            id obj = va_arg(myArgs, id);
            if(!obj)break;
            [theArgs addObject:obj];
        }
        va_end(myArgs);
        
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[sharedStatusController methodSignatureForSelector:@selector(logError:usingKeyArray:)]];
        
        [invocation setTarget:sharedStatusController];
        [invocation setSelector:@selector(logError:usingKeyArray:)];
        [invocation setArgument:&s1 atIndex:2];
        [invocation setArgument:&theArgs atIndex:3];
        [invocation retainArguments];
        
        [sharedStatusController performSelectorOnMainThread:@selector(handleInvocation:) withObject:invocation waitUntilDone:NO];
        
	}
	@catch(NSException* localException) {
	}
	[pool release];
}

@implementation ORStatusController (private)
-(void)loadLogBookPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* fileName = [[sheet filenames] objectAtIndex:0];
        [self setLogBookFile:fileName];
    }
}

- (void) saveAsLogBookDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* newPath = [[sheet filenames] objectAtIndex:0];
		
		if(![[newPath pathExtension] isEqualToString:@"rtfd"]){
			newPath = [[newPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"rtfd"];
		}
		[logBookField writeRTFDToFile:newPath atomically:YES];
        [self setLogBookFile:newPath];
		
		logBookDirty = NO;
		[saveLogBookButton setEnabled:NO];
		
    }
}
@end
