//
//  ORAppDelegate.m
//  Orca
//
//  Created by Mark Howe on Tue Dec 03 2002.
//  Copyright  © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORHeartBeat.h"
#import "ORAutoTester.h"
#import "ORCommandCenter.h"
#import "ORHWWizardController.h"
#import "ORStatusController.h"
#import "ORAlarmController.h"
#import "ORCommandCenterController.h"
#import "ORCatalogController.h"
#import "ORPreferencesController.h"
#import "ORTaskMaster.h"
#import "MemoryWatcherController.h"
#import "MemoryWatcher.h"
#import "ORAlarmCollection.h"
#import "ORSplashWindowController.h"
#import "ORProcessCenter.h"
#import "ORWindowListController.h"
#import "ORCARootService.h"
#import "ORCARootServiceController.h"
#import "ORMailer.h"
#import "OrcaObjectController.h"
#import "ORWindowSaveSet.h"
#import "ORArchive.h"

#import <WebKit/WebKit.h>
#import "ORHelpCenter.h"

#import <sys/sysctl.h>

NSString* kCrashLogDir  = @"~/Library/Logs/CrashReporter";
NSString* kLastCrashLog = @"~/Library/Logs/CrashReporter/LastOrca.crash.log";

#define kORSplashScreenDelay 1

@implementation ORAppDelegate
+ (BOOL)isMacOSX10_5
{
	unsigned major, minor, bugFix;
    [[NSApplication sharedApplication] getSystemVersionMajor:&major minor:&minor bugFix:&bugFix];
	
	return (minor >= 5);
}

+ (BOOL)isMacOSX10_4 
{
	unsigned major, minor, bugFix;
    [[NSApplication sharedApplication] getSystemVersionMajor:&major minor:&minor bugFix:&bugFix];
	
	return (minor >= 4);
}


+ (void) initialize
{	
    
    static BOOL initialized = NO;
    if ( !initialized ) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *initialUserDefaults = [NSMutableDictionary dictionaryWithObject: [NSNumber numberWithBool:YES] forKey:OROpeningDocPreferences];
        [initialUserDefaults setObject:dataForColor([NSColor whiteColor])  forKey:ORBackgroundColor];
        [initialUserDefaults setObject:dataForColor([NSColor blackColor])  forKey:ORLineColor];
        [initialUserDefaults setObject:[NSNumber numberWithInt:0] forKey:ORLineType];
        
        [initialUserDefaults setObject:[NSNumber numberWithInt:0] forKey:OROpeningDialogPreferences];
        [initialUserDefaults setObject:[NSNumber numberWithBool:NO] forKey:OROrcaSecurityEnabled];
        
        [initialUserDefaults setObject:[NSNumber numberWithBool:NO] forKey:ORMailBugReportFlag];
        [initialUserDefaults setObject:@"" forKey:ORMailBugReportEMail];
        
        [initialUserDefaults setObject:dataForColor([NSColor whiteColor])  forKey:ORScriptBackgroundColor];
        [initialUserDefaults setObject:dataForColor([NSColor redColor])  forKey:ORScriptCommentColor];
        [initialUserDefaults setObject:dataForColor([NSColor greenColor])  forKey:ORScriptStringColor];
        [initialUserDefaults setObject:dataForColor([NSColor blueColor])  forKey:ORScriptIdentifier1Color];
        [initialUserDefaults setObject:dataForColor([NSColor grayColor])  forKey:ORScriptIdentifier2Color];
        [initialUserDefaults setObject:dataForColor([NSColor orangeColor])  forKey:ORScriptConstantsColor];
        
		[initialUserDefaults setObject:[NSNumber numberWithBool:YES]  forKey:ORHelpFilesUseDefault];
		[initialUserDefaults setObject:@"" forKey:ORHelpFilesPath];
		
        [defaults registerDefaults:initialUserDefaults];
        initialized = YES;
        
        //make some globals
        [ORGlobal sharedGlobal]; 
        [ORSecurity sharedSecurity];
    }
}

- (id) init
{
	self = [super init];
	theSplashController = [[ORSplashWindowController alloc] init];
	[theSplashController showWindow:self];
	
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
	NSString* noKill				 = [standardDefaults stringForKey:@"startup"];
	if(![noKill isEqualToString:@"NoKill"]){
		NSString* myName = [[NSProcessInfo processInfo] processName];
		int myPid        = [[NSProcessInfo processInfo] processIdentifier];
		NSArray* launchedApps = [[NSWorkspace sharedWorkspace] launchedApplications];
		for(id anApp in launchedApps){
			NSString* otherProcessName = [anApp objectForKey:@"NSApplicationName"];
			int otherProcessPid = [[anApp objectForKey:@"NSApplicationProcessIdentifier"] intValue];
			
			if([otherProcessName isEqualToString:myName] && otherProcessPid != myPid){
				[NSApp terminate:self];
			}
		}
	}
	 
	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [alarmCollection release];
    [memoryWatcher release];
	[ethernetHardwareAddress release];
    [super dealloc];
}    

- (void) awakeFromNib
{
    [self registerNotificationObservers];
    [self setAlarmCollection:[[[ORAlarmCollection alloc] init] autorelease]];
    [self setMemoryWatcher:[[[MemoryWatcher alloc] init] autorelease]];
}

- (ORHelpCenter*) helpCenter
{
	return helpCenter;
}

- (MemoryWatcher*) memoryWatcher
{
    return memoryWatcher;
}

- (void) setMemoryWatcher:(MemoryWatcher*)aWatcher
{
	[aWatcher retain];
	[memoryWatcher release];
	memoryWatcher = aWatcher;
}

- (ORAlarmCollection*) alarmCollection
{
	return alarmCollection;
}

- (void) setAlarmCollection:(ORAlarmCollection*)someAlarms
{
	[someAlarms retain];
	[alarmCollection release];
	alarmCollection = someAlarms;
}
- (NSString*) ethernetHardwareAddress
{
	if(![ethernetHardwareAddress length]){
		ethernetHardwareAddress = macAddress();
		[ethernetHardwareAddress retain];
	}
	return ethernetHardwareAddress;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
}

- (void) applicationWillTerminate:(NSNotification *)aNotification
{
	[[ORProcessCenter sharedProcessCenter] stopAll:nil];
	[ORTimer delay:0.3];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORAppTerminating" object:self];
}

#pragma mark ¥¥¥Actions
- (IBAction) showArchive:(id)sender
{
    [[ORArchive sharedArchive] showWindow:self];
}

- (IBAction) restoreToCmdOneSet:(id)sender
{
	[windowSaveSet restoreToCmdOneSet:sender];
}

- (IBAction) showTemplates:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORShowTemplates" object:self];	
}

- (IBAction) showWindowList:(id)sender
{
    [[[ORWindowListController sharedWindowListController] window] orderFront:nil];
}

- (IBAction) showStatusLog:(id)sender
{
    [[[ORStatusController sharedStatusController] window] orderFront:nil];
}

- (IBAction) showCommandCenter:(id)sender
{
    [[[ORCommandCenterController sharedCommandCenterController] window] orderFront:nil];
}

- (IBAction) showAutoTester:(id)sender
{
    [[[ORAutoTester sharedAutoTester] window] orderFront:nil];
}

- (IBAction) showORCARootServiceController:(id)sender
{
    [[[ORCARootServiceController sharedORCARootServiceController] window] orderFront:nil];
}

- (IBAction) showMemoryWatcher:(id)sender
{
    MemoryWatcherController* watcher = [MemoryWatcherController sharedMemoryWatcherController];
    [watcher setMemoryWatcher:memoryWatcher];
    [[watcher window] orderFront:nil];
    
}

- (IBAction) showProcessCenter:(id)sender
{
    [[[ORProcessCenter sharedProcessCenter] window] orderFront:nil];
}

- (IBAction) showTaskMaster:(id)sender
{
    [[[ORTaskMaster sharedTaskMaster] window] orderFront:nil];
}

- (IBAction) showHardwareWizard:(id)sender
{
    [[[ORHWWizardController sharedHWWizardController] window] orderFront:nil];
}

- (IBAction) showAlarms:(id)sender
{
    [[[ORAlarmController sharedAlarmController] window] orderFront:nil];
}

- (IBAction) showCatalog:(id)sender
{
    [[[ORCatalogController sharedCatalogController] window] orderFront:nil];
}

- (IBAction) showPreferences:(id)sender
{
    [[[ORPreferencesController sharedPreferencesController] window] orderFront:nil];
}

- (IBAction) newDocument:(id)sender
{
    //we implement this method ONLY so we can do the validation of the menu item
    [[NSDocumentController sharedDocumentController] newDocument:sender];
	[[self undoManager] removeAllActions];
}

- (IBAction) openDocument:(id)sender
{
    //we implement this method ONLY so we can do the validation of the menu item
    [[NSDocumentController sharedDocumentController] openDocument:sender];
}

- (IBAction) openRecentDocument:(id)sender
{
    //we implement this method ONLY so we can do the validation of the menu item
	//nothing to do... everything is in the submenu and handled by the doc controller
}

- (IBAction) performClose:(id)sender
{
	[[self undoManager] removeAllActions];
    [[NSDocumentController sharedDocumentController] performClose:sender];
}

- (IBAction) terminate:(id)sender
{
	BOOL okToQuit = YES;
	int runningProcessCount = [[ORProcessCenter sharedProcessCenter] numberRunningProcesses];
	if(runningProcessCount>0){
		NSString* s = [NSString stringWithFormat:@"Quitting will stop %d Running Process%@!",runningProcessCount,runningProcessCount>1?@"es":@""];		
		int choice = NSRunAlertPanel(s,@"Is this really what you want?",@"Cancel",@"Stop Processes and Quit",nil);
		if(choice == NSAlertAlternateReturn){
			okToQuit = YES;
		}
		else okToQuit = NO;
	}
	if(okToQuit){
		[[ORCommandCenter sharedCommandCenter] closeScriptIDE];
		[[ORProcessCenter sharedProcessCenter] stopAllAndNotify];
		[ORTimer delay:1];
		
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:ORNormalShutDownFlag];    
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		[NSApp terminate:sender];
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return ![[ORGlobal sharedGlobal] runInProgress];
}

#pragma mark ¥¥¥Accessors

- (id) document
{
	return document;
}
- (void) setDocument:(id)aDocument
{
	if(aDocument && document){
		NSRunAlertPanel(@"Experiment Already Open",@"Only one experiment can be active at a time.",nil,nil,nil,nil);
		[NSException raise:@"Document already open" format:@""];
	}
	document = aDocument;
}


#pragma mark ¥¥¥Notification Methods
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
	[self showStatusLog:self];

    NSLog(@"-------------------------------------------------\n");
    NSLog(@"   Orca (v%@) Has Started                    \n",fullVersion());
    NSNumber* shutdownFlag = [[NSUserDefaults standardUserDefaults] objectForKey:ORNormalShutDownFlag]; 
    if(shutdownFlag && ([shutdownFlag boolValue]==NO)){
		NSLog(@"   (After crash or hard debugger stop)           \n");
    }
    NSLog(@"-------------------------------------------------\n");

	unsigned major, minor, bugFix;
    [[NSApplication sharedApplication] getSystemVersionMajor:&major minor:&minor bugFix:&bugFix];
    NSLog(@"Running MacOS %u.%u.%u %@\n", major, minor, bugFix,minor>=5?@"":@"(Note: some ORCA features require 10.5. Please update)");
    NSLog(@"Mac Address: %@\n",[self ethernetHardwareAddress]);
	NSString* theAppPath = appPath();
	if(theAppPath)	NSLog(@"Launch Path: %@\n",theAppPath);

    if(shutdownFlag && ([shutdownFlag boolValue]==NO)){
        [self mailCrashLogs];
    }
	else {
        [self deleteCrashLogs];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:ORNormalShutDownFlag];    
   
    NSError* fileOpenError = nil;
	@try {
		if(![[NSApp orderedDocuments] count] && ![self applicationShouldOpenUntitledFile:NSApp]){
			NSString* lastFile = [[NSUserDefaults standardUserDefaults] objectForKey: ORLastDocumentName];
			if(lastFile){
				NSLog(@"Trying to open: %@\n",lastFile);
				NSURL* asURL = [NSURL fileURLWithPath:lastFile];
				if(![[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:asURL display:YES error:&fileOpenError]){
					[self closeSplashWindow];
					NSLogColor([NSColor redColor],@"Last File Opened By Orca Does Not Exist!\n");
					NSLogColor([NSColor redColor],@"<%@>\n",lastFile);
					NSRunAlertPanel(@"File Error",@"Last File Opened By Orca Does Not Exist!\n\n<%@>",nil,nil,nil,lastFile);
				}
				else {
					NSLog(@"Opened Configuration: %@\n",lastFile);
				}
			}
			if([[[NSUserDefaults standardUserDefaults] objectForKey: OROrcaSecurityEnabled] boolValue]){
				NSLog(@"Orca global security is enabled.\n");
			}
			else {
				NSLog(@"Orca global security is disabled.\n");
			}
			
		}
	}
	@catch(NSException* localException) {
		NSLogColor([NSColor redColor],@"There was an exception thrown during load... configuration may not be complete!\n");
		if(fileOpenError)[NSApp presentError:fileOpenError];
		[self setDocument:nil];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartUpMessage"
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:@"Loading LogBook..." forKey:@"Message"]];
	[[ORStatusController sharedStatusController] loadCurrentLogBook];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartUpMessage"
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:@"Finishing..." forKey:@"Message"]];
    //make and register the heart beat monitor.
    [[ORCommandCenter sharedCommandCenter] addDestination:[ORHeartBeat sharedHeartBeat]];  
	
	//create an instance of the ORCARoot service and possibly connect    
    [[ORCARootService sharedORCARootService] connectAtStartUp];    
	
	[self performSelector:@selector(closeSplashWindow) withObject:self afterDelay:kORSplashScreenDelay];
	
	[[self undoManager] removeAllActions];

	int     count  = [[ORGlobal sharedGlobal] cpuCount];
	if(count==1){
		[self closeSplashWindow];
		NSLogColor([NSColor redColor],@"Number Processors: %d\n",count);
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"IgnoreSingleCPUWarning"] == nil){
			int result = NSRunInformationalAlertPanel(@"Single CPU Warning",@"ORCA runs best on machines with multiple processors!",@"OK",nil,@"OK/Don't remind me",nil);
			if(result == -1){
				[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"IgnoreSingleCPUWarning"];    
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
		}
	}
	else NSLog(@"Number Processors: %d\n",count);
	
	if(getenv("NSZombieEnabled") || getenv("NSAutoreleaseFreedObjectCheckEnabled")) {
		NSLogColor([NSColor redColor],@"==============================================================================\n");
		NSLogColor([NSColor redColor],@"NSZombieEnabled/NSAutoreleaseFreedObjectCheckEnabled enabled!\n");
		NSLogColor([NSColor redColor],@"They are meant to be enabled for debugging only!\n");
		NSLogColor([NSColor redColor],@"ORCA will be slow, leak memory like crazy, and eventually bring the machine to its knees!\n");
		NSLogColor([NSColor redColor],@"==============================================================================\n");
	}
}

- (void) closeSplashWindow
{
	[theSplashController close];
	[theSplashController release];
	theSplashController = nil;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey: OROpeningDocPreferences] intValue];
}

#pragma mark ¥¥¥Menu Management
- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    BOOL documentIsOpen = [[NSApp orderedDocuments] count]>0;
    SEL theAction = [menuItem action];
    if(theAction == @selector(terminate:)){
        return ![[ORGlobal sharedGlobal] runInProgress];
    }
    if(theAction == @selector(performClose:)){
        return ![[ORGlobal sharedGlobal] runInProgress];
    }
    if(theAction == @selector(newDocument:)){
        return documentIsOpen ? NO : YES;
    }
    if(theAction == @selector(openDocument:)){
        return documentIsOpen ? NO : YES;
    }
    if(theAction == @selector(openRecentDocument:)){
        return documentIsOpen ? NO : YES;
    }
    if(theAction == @selector(showTemplates:)){
		if(![self document])return NO;
		else if([[[self document] group] count]==0 && ![[self document] isDocumentEdited])return YES;
        else return documentIsOpen ? NO : YES;
    }
	
    if(theAction == @selector(restoreToCmdOneSet:)){
		NSString* theSaveSetName = [[NSUserDefaults standardUserDefaults] objectForKey:@"CmdOneWindowSaveSet"]; 
		if(![theSaveSetName length])return NO;
		
		NSString* tempFolder = [[ApplicationSupport sharedApplicationSupport] applicationSupportFolder:@"WindowSets"];
		NSString* windowSetFile = [tempFolder stringByAppendingPathComponent:theSaveSetName];
		NSFileManager* fm = [NSFileManager defaultManager]; 
		if([fm fileExistsAtPath:windowSetFile])return YES;
		else return NO;
    }
	
	
    return YES;
}
- (NSUndoManager*) undoManager
{
    return [document undoManager];
}

- (void) mailCrashLogs
{
    if([[[NSUserDefaults standardUserDefaults] objectForKey: ORMailBugReportFlag] boolValue]){
        NSString* address = [[NSUserDefaults standardUserDefaults] objectForKey: ORMailBugReportEMail];
        if(address){
			NSString *filePath;
			NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: [kCrashLogDir stringByExpandingTildeInPath]];
			// iterate over all the log files
			while (filePath = [dirEnum nextObject]){
				if([filePath hasPrefix:@"Orca"]){
					NSString* contents = [NSString stringWithContentsOfFile:[[kCrashLogDir stringByExpandingTildeInPath] stringByAppendingPathComponent:filePath]encoding:NSASCIIStringEncoding error:nil];
					if(contents){
						NSAttributedString* crashLog = [[NSAttributedString alloc] initWithString:contents];
						//the address may be a list... if so it must be a comma separated list... try to make it so...
						NSMutableString* finalAddressList = [[[[address componentsSeparatedByString:@"\n"] componentsJoinedByString:@","] mutableCopy] autorelease];
						[finalAddressList replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[address length])];
						[finalAddressList replaceOccurrencesOfString:@",," withString:@"," options:NSLiteralSearch range:NSMakeRange(0,[address length])];
						ORMailer* mailer = [ORMailer mailer];
						[mailer setTo:finalAddressList];
						[mailer setSubject:@"ORCA Crash Log"];
						[mailer setBody:crashLog];
						[mailer send:self];
						[crashLog release];
					}
				}
			}		
        }
		[self deleteCrashLogs];
    }
}

- (void) mailSent:(NSString*)address
{
	NSLog(@"The last ORCA crash log was sent to: %@\n",address);
}

- (void) deleteCrashLogs
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* lastCrashLogPath = [kLastCrashLog stringByExpandingTildeInPath]; 
	NSString *filePath;
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: [kCrashLogDir stringByExpandingTildeInPath]];
	// iterate over all the log files
	while (filePath = [dirEnum nextObject]){
		if([filePath hasPrefix:@"Orca"]){
			NSString* fullPath = [[kCrashLogDir stringByExpandingTildeInPath] stringByAppendingPathComponent:filePath];
			if([fm fileExistsAtPath:lastCrashLogPath]){
				[fm removeItemAtPath:lastCrashLogPath error:nil];
			}
			[fm copyItemAtPath:fullPath toPath:lastCrashLogPath error:nil];
			NSLog(@"Old crash report copied to: %@\n",lastCrashLogPath);
			[fm removeItemAtPath:fullPath error:nil];
		}
	}	
}
@end

@implementation NSApplication (SystemVersion)

- (void)getSystemVersionMajor:(unsigned *)major
                        minor:(unsigned *)minor
                       bugFix:(unsigned *)bugFix;
{
    OSErr err;
    SInt32 systemVersion, versionMajor, versionMinor, versionBugFix;
    if ((err = Gestalt(gestaltSystemVersion, &systemVersion)) != noErr) goto fail;
    if (systemVersion < 0x1040)
    {
        if (major) *major = ((systemVersion & 0xF000) >> 12) * 10 +
            ((systemVersion & 0x0F00) >> 8);
        if (minor) *minor = (systemVersion & 0x00F0) >> 4;
        if (bugFix) *bugFix = (systemVersion & 0x000F);
    }
    else
    {
        if ((err = Gestalt(gestaltSystemVersionMajor, &versionMajor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionMinor, &versionMinor)) != noErr) goto fail;
        if ((err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix)) != noErr) goto fail;
        if (major) *major = versionMajor;
        if (minor) *minor = versionMinor;
        if (bugFix) *bugFix = versionBugFix;
    }
    
    return;
    
fail:
    NSLog(@"Unable to obtain system version: %ld", (long)err);
    if (major) *major = 10;
    if (minor) *minor = 0;
    if (bugFix) *bugFix = 0;
}

@end
