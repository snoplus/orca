//
//  ORHeaderExplorerController.m
//  Orca
//
//  Created by Mark Howe on Tue Feb 26.
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


#pragma mark •••Imported Files
#import "ORHeaderExplorerController.h"
#import "ORHeaderExplorerModel.h"
#import "ORHeaderItem.h"
#import "ORDataSet.h"
#import "CTGradient.h"

@interface ORHeaderExplorerController (private)
- (void) openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) saveListDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) loadListDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) addDirectoryContents:(NSString*)path toArray:(NSMutableArray*)anArray;
- (void) processFileList:(NSArray*)filenames;
@end

@implementation ORHeaderExplorerController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"HeaderExplorer"];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    [fileListView registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	[runSummaryTextView setFont:[NSFont fontWithName:@"Monaco" size:10]];
	[progressIndicatorBottom setIndeterminate:NO];
    [super awakeFromNib];    
}


#pragma  mark •••Actions
- (IBAction) selectButtonAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setPrompt:@"Choose"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model lastFilePath]){
        startDir = [[model lastFilePath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    
    [openPanel beginSheetForDirectory:startDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
    
}

- (IBAction)delete:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction)cut:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction) removeItemAction:(id)sender
{ 
	NSIndexSet* selectedSet = [fileListView selectedRowIndexes];
	[fileListView deselectAll:self];

    [model removeFilesWithIndexes:selectedSet];
    
    [fileListView reloadData];
}


- (IBAction) replayButtonAction:(id)sender
{
    if(![model isReplaying]){
        [model readHeaders];
        [selectButton setEnabled:NO];
    }
    else {
        [model stopReplay];
    }
}

- (IBAction) saveListAction:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model lastListPath]){
        startDir = [[model lastListPath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    [savePanel beginSheetForDirectory:startDir
								 file:nil
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(saveListDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
    
}

- (IBAction) loadListAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setPrompt:@"Choose"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model lastListPath]){
        startDir = [[model lastListPath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    
    [openPanel beginSheetForDirectory:startDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(loadListDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
	
}

- (IBAction) selectionDateAction:(id)sender
{
	[model setSelectionDate:[sender intValue]];
}

#pragma mark •••Interface Management
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(fileListChanged:)
                         name : ORHeaderExplorerListChangedNotification
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(started:)
                         name : ORHeaderExplorerRunningNotification
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stopped:)
                         name : ORHeaderExplorerParseEndedNotification
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(selectionDateChanged:)
                         name : ORHeaderExplorerParseEndedNotification
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(reading:)
                         name : ORHeaderExplorerReadingNotification
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(selectionDateChanged:)
                         name : ORHeaderExplorerSelectionDateNotification
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(runSelectionChanged:)
                         name : ORHeaderExplorerRunSelectionChanged
                        object: model];

}

- (void) updateWindow
{
    [self fileListChanged:nil];
    [self selectionDateChanged:nil];
    [self runSelectionChanged:nil];
	
	[workingOnField setStringValue:@""];
}


- (void)started:(NSNotification *)aNotification
{
	[fileListView setEnabled:NO];
	[replayButton setEnabled:YES];
	[selectButton setEnabled:NO];
	[replayButton setTitle:@"Stop"];
	[progressIndicator startAnimation:self];
	[progressField setStringValue:@"In Progress"];
	[progressIndicatorBottom startAnimation:self];
}

- (void)stopped:(NSNotification *)aNotification
{
	[fileListView setEnabled:YES];
	[replayButton setEnabled:YES];
	[selectButton setEnabled:YES];
	[replayButton setTitle:@"Process"];
	[progressIndicator stopAnimation:self];
	[progressField setStringValue:@""];
	[workingOnField setStringValue:@""];
	[progressIndicatorBottom setDoubleValue:0.0];
	[progressIndicatorBottom setIndeterminate:NO];
	[progressIndicatorBottom stopAnimation:self];
	[runTimeView setNeedsDisplay:YES];
	
	unsigned long absStart = [model minRunStartTime];
	unsigned long absEnd   = [model maxRunEndTime];
	if(absStart>0 && absEnd>0){
		NSCalendarDate* d = [NSCalendarDate dateWithTimeIntervalSince1970:absStart];
		[runStartField setObjectValue:d];
		d = [NSCalendarDate dateWithTimeIntervalSince1970:absEnd];
		[runEndField setObjectValue:d];
	}

}

- (void) reading:(NSNotification *)aNotification
{
	NSString* theFileName = [model fileToReplay];
	if(theFileName)[workingOnField setStringValue:[NSString stringWithFormat:@"Reading:%@",[theFileName stringByAbbreviatingWithTildeInPath]]];
	else [workingOnField setStringValue:@""];

	unsigned long total = [model total];
    if(total>0)[progressIndicatorBottom setDoubleValue:100. - (100.*[model numberLeft]/(double)total)];
}

#pragma mark •••Interface Management
- (void) selectionDateChanged:(NSNotification*)note
{
	[selectionDateSlider setIntValue:[model selectionDate]];
	unsigned long absStart		= [model minRunStartTime];
	unsigned long absEnd		= [model maxRunEndTime];
	unsigned long selectionDate	= absStart + ((absEnd - absStart) * [model selectionDate]/1000.);
	NSCalendarDate* d = [NSCalendarDate dateWithTimeIntervalSince1970:selectionDate];
	[selectionDateField setObjectValue:d];

}

- (void) runSelectionChanged:(NSNotification*)note
{
	unsigned long absStart		= [model minRunStartTime];
	unsigned long absEnd		= [model maxRunEndTime];
	if(absStart>0 && absEnd>0 && [model selectedRunIndex]>=0){
		NSDictionary* runDictionary = [model runDictionaryForIndex:[model selectedRunIndex]];
		if(runDictionary){
			NSString* units = @"Bytes";
			float fileSize = [[runDictionary objectForKey:@"FileSize"] floatValue];
			if(fileSize>1000000){
				fileSize /= 1000000.;
				units = @"MBytes";
			}
			else if(fileSize>1000){
				fileSize /=1000.;
				units = @"KBytes";
			}
			NSString* s = [NSString stringWithFormat:@"Run Summary:\nRun Number: %@\n",[runDictionary objectForKey:@"RunNumber"]];
			NSCalendarDate* startTime = [NSCalendarDate dateWithTimeIntervalSince1970:[[runDictionary objectForKey:@"RunStart"] unsignedLongValue]];
			s = [s stringByAppendingFormat:@"Started   : %@\n",startTime];
			s = [s stringByAppendingFormat:@"Run Length: %@ sec\n",[runDictionary objectForKey:@"RunLength"]];
			s = [s stringByAppendingFormat:@"File Size : %.2f %@",fileSize,units];
			[runSummaryTextView setString:s];
		}
		else [runSummaryTextView setString:@"no valid selection"];
	}
	else [runSummaryTextView setString:@"no valid selection"];
	[runTimeView setNeedsDisplay:YES];
	[headerView reloadData];
}

- (void) fileListChanged:(NSNotification*)note
{
	[fileListView reloadData];
}


#pragma mark •••Data Source Methods

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item 
{
    if(outlineView == headerView){
        if(!item) return [[model header] count];
        else      return [item count]; 
    }
    else return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item 
{
    if(outlineView == headerView){
        if(!item) return [[model header] count]>0;
        else      return [item count]>0;
    }
    else return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item 
{
    if(outlineView == headerView){
        if(!item) return [[model header] childAtIndex:index];
        else      return [item childAtIndex:index];
    }
    else return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
    if(outlineView == headerView){
        if([[tableColumn identifier] isEqualToString:@"LevelName"]){
            if(item==0) return [[model header] name];
            else        return [item name];
        }
        else if([[tableColumn identifier] isEqualToString:@"Value"]){
            if(item==0){
                return [[NSAttributedString alloc] 
                        initWithString:[NSString stringWithFormat:@"%d key/value pairs",[[model header] count]] 
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,nil]];
            }
            else {
                if([item isLeafNode]){
                    return [NSString stringWithFormat:@"%@",[item object]];
                }
                else {
                    return [[NSAttributedString alloc] 
                        initWithString:[NSString stringWithFormat:@"%d key/value pairs",[item count]] 
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,nil]];            
                }
            }
        }
        
        else return nil;
    }
    else return nil;
}



- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    if([[model filesToReplay] count]){
        id obj = [[model filesToReplay]  objectAtIndex:rowIndex];
        return [obj stringByAbbreviatingWithTildeInPath];
    }
    else return nil;
}

// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    
    return [[model filesToReplay] count];
}


- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
    [headerView setNeedsDisplay:YES];
    return YES;
}

- (NSDragOperation) tableView:(NSTableView *) tableView validateDrop:(id <NSDraggingInfo>) info proposedRow:(int) row proposedDropOperation:(NSTableViewDropOperation) operation
{
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard* pb = [info draggingPasteboard];
    NSData* data = [pb dataForType:NSFilenamesPboardType];
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm createFileAtPath:@"OrcaJunkTemp" contents:data attributes:nil];
    [self processFileList:[NSArray arrayWithContentsOfFile:@"OrcaJunkTemp"]];
    [fm removeFileAtPath:@"OrcaJunkTemp" handler:nil];
    return YES;
}

#pragma mark •••Data Source
- (unsigned long) minRunStartTime {return [model minRunStartTime];}
- (unsigned long) maxRunEndTime	  {return [model maxRunEndTime];}
- (long) numberRuns {return [model numberRuns];}
- (id) run:(int)index objectForKey:(id)aKey { return [model run:index objectForKey:aKey]; }
- (int) selectedRunIndex { return [model selectedRunIndex]; }

- (void) moveSliderTo:(long)aValue
{
	[model setSelectionDate:aValue];
}
@end

@implementation ORHeaderExplorerController (private)
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* filePath = [[sheet filenames] objectAtIndex:0];
        [model setLastFilePath:filePath];
        [self processFileList:[sheet filenames]];
    }
}

-(void) processFileList:(NSArray*)filenames
{
    NSMutableArray* theFinalList = [NSMutableArray array];
    NSFileManager* fm = [NSFileManager defaultManager];
    NSEnumerator* e = [filenames objectEnumerator];
    BOOL isDirectory;
    id fileName;
    while(fileName = [e nextObject]){
        [fm fileExistsAtPath:fileName isDirectory:&isDirectory];
        if(!isDirectory){
            //just a file
            if([fileName rangeOfString:@"Run"].location != NSNotFound){
                [theFinalList addObject:fileName];
            }
        }
        else {
            //it's a directory
            [self addDirectoryContents:fileName toArray:theFinalList];
        }
    }
	
    [model addFilesToReplay:theFinalList];
    [fileListView reloadData];
}

- (void) addDirectoryContents:(NSString*)aPath toArray:(NSMutableArray*)anArray
{
    BOOL isDirectory;
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm fileExistsAtPath:aPath isDirectory:&isDirectory];
    if(isDirectory){
        NSDirectoryEnumerator* e = [fm enumeratorAtPath:aPath];
        NSString *file;
        while (file = [e nextObject]) {
            [fm fileExistsAtPath:file isDirectory:&isDirectory];
            if(!isDirectory){
                //just a file
                if([file rangeOfString:@"Run"].location != NSNotFound){
                    [anArray addObject:[NSString stringWithFormat:@"%@/%@",aPath,file]];
                }
            }
            else {
                //it's a directory
                [self addDirectoryContents:file toArray:anArray];
            }
			
        }
    }
}


- (void) saveListDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* listPath = [[sheet filenames] objectAtIndex:0];
        [model setLastListPath:listPath];
        [[model filesToReplay] writeToFile:listPath atomically:YES];
    }
}

- (void) loadListDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        NSString* listPath = [[sheet filenames] objectAtIndex:0];
        NSMutableArray* theList = [NSMutableArray arrayWithContentsOfFile:listPath];
        if(theList){
            [model removeAll];
            [model addFilesToReplay:theList];
            [fileListView reloadData];
        }
        else NSLog(@"<%@> replay list is empty\n",listPath);
    }
}

@end

@implementation ORRunTimeView

- (void) dealloc
{
	[selectedGradient release];
	[backgroundGradient release];
	[normalGradient release];
	[super dealloc];
}

- (void) awakeFromNib
{
	float red,green,blue;
	red = 0; green = 1; blue = 0;
	normalGradient = [[CTGradient 
						gradientWithBeginningColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1]
						               endingColor:[NSColor colorWithCalibratedRed:.5*red green:.5*green blue:.5*blue alpha:1]] retain];


	red = 1; green = 0; blue = 0;
	selectedGradient = [[CTGradient 
						gradientWithBeginningColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1]
						               endingColor:[NSColor colorWithCalibratedRed:.5*red green:.5*green blue:.5*blue alpha:1]] retain];


	float gray = 1.0;
	backgroundGradient = [[CTGradient 
						gradientWithBeginningColor:[NSColor colorWithCalibratedRed:gray green:gray blue:gray alpha:1]
						               endingColor:[NSColor colorWithCalibratedRed:.7*gray green:.7*gray blue:.7*gray alpha:1]] retain];

}

- (void) drawRect:(NSRect)aRect
{
	[NSBezierPath setDefaultLineWidth:1];
	[backgroundGradient fillRect:[self bounds] angle:0];
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:[self bounds]];
		
	unsigned long absStart = [dataSource minRunStartTime];
	unsigned long absEnd   = [dataSource maxRunEndTime];
	long n = [dataSource numberRuns];
	long selectedRunIndex = [dataSource selectedRunIndex];
	int i;
	for(i=0;i<n;i++){
	
		unsigned long start = [[dataSource run:i objectForKey:@"RunStart"] unsignedLongValue];
		unsigned long end   = [[dataSource run:i objectForKey:@"RunEnd"] unsignedLongValue];

		if(start && end){
			float h = [self bounds].size.height;
			float y1 = h*(start-absStart)/(float)(absEnd-absStart);
			float y2 = h*(end-absStart)/(float)(absEnd-absStart);
			NSRect aRect = NSMakeRect(0,y1,[self bounds].size.width,y2-y1);
			if(i==selectedRunIndex)[selectedGradient fillRect:aRect angle:0];
			else [normalGradient fillRect:aRect angle:0];
			[[NSColor blackColor] set];
			[NSBezierPath strokeRect:aRect];
		}
	}
}

- (void) mouseDown:(NSEvent*)anEvent
{
    NSPoint mouseLoc =  [self convertPoint:[anEvent locationInWindow] fromView:nil];
	unsigned long selectedPoint = (mouseLoc.y/[self bounds].size.height)*1000.;
	[dataSource moveSliderTo:selectedPoint];
}

@end

