//
//  ORArchive.m
//  Orca
//
//  Created by Mark Howe on Thu Nov 28 2002.
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
#import "ORArchive.h"
#import "SynthesizeSingleton.h"
#import "ORTimedTextField.h"

#define kOldBinaryPath @"~/OldOrcaBinaries"
#define kDefaultSrcPath @"~/Dev/Orca"

NSString*  ArchiveLock = @"ArchiveLock";

@implementation ORArchive

#pragma mark ¥¥¥Inialization

SYNTHESIZE_SINGLETON_FOR_ORCLASS(Archive);

-(id)init
{
    self = [super initWithWindowNibName:@"Archive"];
    if (self) {
        [self setWindowFrameAutosaveName:@"Archive"];
    }
    return self;
}
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[queue cancelAllOperations];
	[queue release];
	[super dealloc];
}

- (void) awakeFromNib 
{
    [self registerNotificationObservers];
	[self securityStateChanged:nil];
	[self lockChanged:nil];
	[archivePathField setStringValue:[kOldBinaryPath stringByAbbreviatingWithTildeInPath]];
	if(!queue){
		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:1]; //can only do one at a time
	}
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    	
	[notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ArchiveLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(securityStateChanged:)
                         name : ORGlobalSecurityStateChanged
                        object: nil];
	
	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[[NSApp delegate]document]  undoManager];
}

- (void) securityStateChanged:(NSNotification*)aNote
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ArchiveLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNote
{
    BOOL locked			= [gSecurity isLocked:ArchiveLock];
	BOOL runInProgress	= [gOrcaGlobals runInProgress];
	int busy			= [queue operationCount]!=0;
	[lockButton setState: locked];
	[runStatusField setStringValue:runInProgress?@"Run In Progress":@""];
	[archiveOrcaButton setEnabled: !locked & !runInProgress & !busy];
	[unarchiveRestartButton setEnabled:!locked & !runInProgress & !busy];
	[updateButton setEnabled:!locked & !runInProgress & !busy];
}

- (IBAction) updateWithSvn:(id)sender
{
	
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* dir = [kDefaultSrcPath stringByExpandingTildeInPath];
	if([fm fileExistsAtPath:dir]){
		[self deferedSvnUpdate:kDefaultSrcPath];
	}
	else {	
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setCanChooseFiles:NO];
		[openPanel setAllowsMultipleSelection:NO];
		[openPanel setPrompt:@"Choose ORCA Location"];
		
		[openPanel beginSheetForDirectory: [@"~" stringByExpandingTildeInPath]
									 file: nil
									types: nil
						   modalForWindow: [self window]
							modalDelegate: self
						   didEndSelector: @selector(updateWithSvnPanelDidEnd:returnCode:contextInfo:)
							  contextInfo: NULL];
	}
}
		 
- (void) updateWithSvnPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
		[self performSelector:@selector(deferedSvnUpdate:) withObject:[[sheet filenames] objectAtIndex:0] afterDelay:0];
    }
}

- (void) deferedSvnUpdate:(NSString *)anUpdatePath
{
	if([self checkOldBinariesFolder]){
		[self archiveCurrentBinary];
	}
	ORUpdateOrcaWithSvnOp* anOp = [[ORUpdateOrcaWithSvnOp alloc] initAtPath:anUpdatePath delegate:self];
	[queue addOperation:anOp];
	[anOp release];
	[self checkQueueBusy];
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:AutoTesterLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) saveDocument:(id)sender
{
    [[[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[[NSApp delegate]document] saveDocumentAs:sender];
}

- (IBAction) archiveThisOrca:(id)sender
{
	if([self checkOldBinariesFolder]){
		[self archiveCurrentBinary];
	}
	[self checkQueueBusy];
}

- (IBAction) startOldOrca:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Choose"];
	
	[openPanel beginSheetForDirectory: [kOldBinaryPath stringByExpandingTildeInPath]
								 file: nil
								types: nil
					   modalForWindow: [self window]
						modalDelegate: self
					   didEndSelector: @selector(startOldOrcaPanelDidEnd:returnCode:contextInfo:)
						  contextInfo: NULL];
}

- (void) updateStatus:(NSString*)aString
{
	[operationStatusField performSelectorOnMainThread:@selector(setStringValue:) withObject:aString waitUntilDone:YES];
}

- (void) startOldOrcaPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
		[self performSelector:@selector(deferedStartOldOrca:) withObject:[[sheet filenames] objectAtIndex:0] afterDelay:0];
    }
}

- (void) deferedStartOldOrca:(NSString*)anOldOrcaPath
{
	[[[NSApp delegate] document] saveDocument:self];
	if([self checkOldBinariesFolder]){
		[self archiveCurrentBinary];
		[self unArchiveBinary:anOldOrcaPath];
		[self restart];
	}		
	[self checkQueueBusy];
}

- (void) checkQueueBusy
{
	[self lockChanged:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkQueueBusy) object:nil];
	if([queue operationCount]){
		[self performSelector:@selector(checkQueueBusy) withObject:nil afterDelay:.1];
	}
}

- (BOOL) checkOldBinariesFolder
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* dir = [kOldBinaryPath stringByExpandingTildeInPath];
	if(![fm fileExistsAtPath:dir]){
		NSError* error;
		if(![fm createDirectoryAtPath:dir withIntermediateDirectories:NO attributes:nil error:&error]){
			NSLogColor([NSColor redColor],@"Unable to access/create %@\n",dir);
			NSLogColor([NSColor redColor],@"%@\n",error);
			return NO;
		}
	}
	return YES;
}

- (void) archiveCurrentBinary
{
	ORArchiveOrcaOp* anOp = [[ORArchiveOrcaOp alloc] initWithDelegate:self];
	[queue addOperation:anOp];
	[anOp release];
}

- (void) unArchiveBinary:(NSString*)fileToUnarchive
{
	ORUnarchiveOrcaOp* anOp = [[ORUnarchiveOrcaOp alloc] initWithFile:fileToUnarchive delegate:self];
	[queue addOperation:anOp];
	[anOp release];
}

- (void) restart
{
	ORRestartOrcaOp* anOp = [[ORRestartOrcaOp alloc] initWithDelegate:self];
	[queue addOperation:anOp];
	[anOp release];
}
@end

@implementation ORArchiveOrcaOp
- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
    return self;
}

- (void) main
{
	@try {
		NSString* binPath = appPath();
		NSString* dir = [kOldBinaryPath stringByExpandingTildeInPath];
		if(binPath){
			NSString* archivePath = [dir stringByAppendingPathComponent:[@"Orca" stringByAppendingFormat:@"%@.tar",fullVersion()]];
			NSTask* task = [[NSTask alloc] init];
			[task setCurrentDirectoryPath:[binPath stringByDeletingLastPathComponent]];
			[task setLaunchPath: @"/usr/bin/tar"];
			NSArray* arguments = [NSArray arrayWithObjects: @"czf", 
								  archivePath, 
								  [[binPath lastPathComponent] stringByAppendingPathExtension:@"app"],
								  nil];
			
			[task setArguments: arguments];
			
			NSPipe* pipe = [NSPipe pipe];
			[task setStandardOutput: pipe];
			
			NSFileHandle* file = [pipe fileHandleForReading];
			[delegate updateStatus:@"Archiving this ORCA"];
			[task launch];

			NSData* data = [file readDataToEndOfFile];
			if(data){
				NSString* result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
				if([result length]) NSLog(@"tar returned:\n%@", result);
			}
			[delegate updateStatus:@"Archiving Done"];
			NSLog(@"Archived ORCA to: %@\n",archivePath);
			[task release];
		}
	}
	@catch(NSException* e){
	}
}
@end

@implementation ORUnarchiveOrcaOp
- (id) initWithFile:(NSString*)aFile delegate:(id)aDelegate
{
	self = [super init];
	[fileToUnarchive autorelease];
	fileToUnarchive = [aFile copy];
	delegate = aDelegate;
    return self;
}
- (void) dealloc
{
	[fileToUnarchive release];
	[super dealloc];
}

- (void) main
{
	@try {
		NSTask* task = [[NSTask alloc] init];
		NSString* binPath = appPath();
		[task setCurrentDirectoryPath:[[binPath stringByExpandingTildeInPath] stringByDeletingLastPathComponent]];
		[task setLaunchPath: @"/usr/bin/tar"];
		NSArray* arguments = [NSArray arrayWithObjects: @"xzf", 
							  [fileToUnarchive stringByExpandingTildeInPath],
							  nil];
		
		[task setArguments: arguments];
		
		NSPipe* pipe = [NSPipe pipe];
		[task setStandardOutput: pipe];
		
		NSFileHandle* file = [pipe fileHandleForReading];
		
		[delegate updateStatus:[NSString stringWithFormat:@"Unarchiving: %@",[fileToUnarchive stringByAbbreviatingWithTildeInPath]]];
		[task launch];
		
		NSData* data = [file readDataToEndOfFile];
		if(data){
			NSString* result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
			if([result length]) NSLog(@"tar returned:\n%@", result);
		}
		[delegate updateStatus:@"Archiving Done"];
		[task release];
	}
	@catch(NSException* e){
	}
}
@end

@implementation ORRestartOrcaOp
- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
    return self;
}

- (void) main
{
	@try {
		[[ORGlobal sharedGlobal] prepareForForcedHalt];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:ORNormalShutDownFlag];    
		[[NSUserDefaults standardUserDefaults] synchronize];

		NSTask* task = [[NSTask alloc] init];
		NSString* binPath = launchPath();
		[task setCurrentDirectoryPath:[[binPath stringByExpandingTildeInPath] stringByDeletingLastPathComponent]];
		[task setLaunchPath: binPath];
		NSArray* arguments = [NSArray arrayWithObjects: @"-startup",@"NoKill", 
							  nil];
		
		[task setArguments: arguments];
		
		[delegate updateStatus:@"Relaunching"];
		[task launch];
		[task release];
		[NSApp terminate:self]; 
		
	}
	@catch(NSException* e){
	}
}
@end

@interface NSObject (ORUpdateCenter)
- (void) updateStatus:(NSString*)aString;
@end

@implementation ORUpdateOrcaWithSvnOp
- (id) initAtPath:(NSString*)aPath delegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
	[srcPath autorelease];
	srcPath = [[aPath stringByDeletingLastPathComponent] copy];
    return self;
}

- (void) dealloc
{
	[srcPath release];
	[super dealloc];
}

- (void) main
{
	@try {
		if(srcPath){
			NSTask* task = [[NSTask alloc] init];
			[task setCurrentDirectoryPath:[srcPath stringByExpandingTildeInPath]];
			[task setLaunchPath: @"/usr/bin/svn"];
			NSArray* arguments = [NSArray arrayWithObjects: @"update", 
								  @"Orca",
								  nil];
			
			[task setArguments: arguments];
			
			NSPipe* pipe = [NSPipe pipe];
			[task setStandardOutput: pipe];
			
			NSFileHandle* file = [pipe fileHandleForReading];
			[delegate updateStatus:[NSString stringWithFormat:@"Updating Src Tree %@",srcPath]];
			[task launch];
			
			NSData* data = [file readDataToEndOfFile];
			if(data){
				NSString* result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
				if([result length]) NSLog(@"svn returned:\n%@", result);
			}
			[delegate updateStatus:@"Update Finished"];
			[task release];
		}
	}
	@catch(NSException* e){
	}
}
@end


