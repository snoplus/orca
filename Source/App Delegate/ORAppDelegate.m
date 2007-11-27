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
#import "ORCommandCenter.h"
#import "ORGateKeeper.h"
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

NSString* kCrashLogLocation     = @"~/Library/Logs/CrashReporter/Orca.crash.log";
NSString* kLastCrashLogLocation = @"~/Library/Logs/CrashReporter/LastOrca.crash.log";

@implementation ORAppDelegate

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
        [ORGlobal sharedInstance]; 
        [ORSecurity sharedInstance];
    }
}

- (id) init
{
	self = [super init];
	
	theSplashController = [[ORSplashWindowController alloc] init];
	[theSplashController showWindow:self];

	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [alarmCollection release];
    [memoryWatcher release];
    [[ORCommandCenterController sharedCommandCenterController] release];
    [[ORCARootServiceController sharedORCARootServiceController] release];
    [super dealloc];
}    

- (void) awakeFromNib
{
    [self registerNotificationObservers];
    [self setAlarmCollection:[[[ORAlarmCollection alloc] init] autorelease]];
    [self setMemoryWatcher:[[[MemoryWatcher alloc] init] autorelease]];

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


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
	
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[[ORProcessCenter sharedProcessCenter] stopAll:nil];
	[ORTimer delay:0.3];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[ORCommandCenterController sharedCommandCenterController] release];
    [[ORCARootServiceController sharedORCARootServiceController] release];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORAppTerminating" object:self];
}

#pragma mark ¥¥¥Actions

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
    [[[ORHWWizardController sharedInstance] window] orderFront:nil];
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

- (IBAction) showGateKeeper:(id)sender
{
    [[[ORGateKeeper sharedGateKeeper] window] orderFront:nil];
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

- (IBAction) performClose:(id)sender
{
	[[self undoManager] removeAllActions];
    [[NSDocumentController sharedDocumentController] performClose:sender];
}


- (IBAction) terminate:(id)sender
{
	[[ORProcessCenter sharedProcessCenter] stopAll:nil];
	[ORTimer delay:1];
	
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:ORNormalShutDownFlag];    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSApp terminate:sender];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return ![[ORGlobal sharedInstance] runInProgress];
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
    CFBundleRef localInfoBundle = CFBundleGetMainBundle();
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    
    CFBundleGetLocalInfoDictionary( localInfoBundle );
    
    NSString* versionString = [infoDictionary objectForKey:@"CFBundleVersion"];
    
    
	[self showStatusLog:self];
	
    NSLog(@"-------------------------------------------------\n");
    NSLog(@"            Orca (v%@) Has Started               \n",versionString);
    NSNumber* shutdownFlag = [[NSUserDefaults standardUserDefaults] objectForKey:ORNormalShutDownFlag]; 
    if(shutdownFlag && ([shutdownFlag boolValue]==NO)){
        NSLog(@"   (After crash or hard debugger stop)       \n");
    }
    NSLog(@"-------------------------------------------------\n");
    
    if(shutdownFlag && ([shutdownFlag boolValue]==NO)){
        [self mailCrashLog];
    }
    else {
        [self deleteCrashLog];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:ORNormalShutDownFlag];    
    
    
    if(![[NSApp orderedDocuments] count] && ![self applicationShouldOpenUntitledFile:NSApp]){
        NSString* lastFile = [[NSUserDefaults standardUserDefaults] objectForKey: ORLastDocumentName];
        if([[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile: lastFile display:YES] == nil){
			NSLogColor([NSColor redColor],@"Last File Opened By Orca Does Not Exist!\n");
			NSLogColor([NSColor redColor],@"<%@>\n",lastFile);
			[theSplashController close];
			[theSplashController release];
			theSplashController = nil;
			NSRunAlertPanel(@"File Error",@"Last File Opened By Orca Does Not Exist!\n\n<%@>",nil,nil,nil,lastFile);
        }
        else {
            NSLog(@"Opened Configuration: %@\n",lastFile);
        }
        if([[[NSUserDefaults standardUserDefaults] objectForKey: OROrcaSecurityEnabled] boolValue]){
            NSLog(@"Orca global security is enabled.\n");
        }
        else {
            NSLog(@"Orca global security is disabled.\n");
        }
        
    }
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartUpMessage"
															object:self
															userInfo:[NSDictionary dictionaryWithObject:@"Loading LogBook..." forKey:@"Message"]];
	[[ORStatusController sharedStatusController] loadCurrentLogBook];
	
    //make and register the heart beat monitor.
    [[ORCommandCenter sharedInstance] addDestination:[ORHeartBeat sharedInstance]];  
	
	//create an instance of the ORCARoot service and possibly connect    
    [[ORCARootService sharedInstance] connectAtStartUp];    

	[theSplashController close];
	[theSplashController release];
	theSplashController = nil;	
	
	[[self undoManager] removeAllActions];

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
        return ![[ORGlobal sharedInstance] runInProgress];
    }
    if(theAction == @selector(performClose:)){
        return ![[ORGlobal sharedInstance] runInProgress];
    }
    if(theAction == @selector(newDocument:)){
        return documentIsOpen ? NO : YES;
    }
    if(theAction == @selector(openDocument:)){
        return documentIsOpen ? NO : YES;
    }
    
    return YES;
}
- (NSUndoManager*) undoManager
{
    return [document undoManager];
}

- (void) mailCrashLog
{
    if([[[NSUserDefaults standardUserDefaults] objectForKey: ORMailBugReportFlag] boolValue]){
        NSString* address = [[NSUserDefaults standardUserDefaults] objectForKey: ORMailBugReportEMail];
        if(address){
            NSString* crashLogPath = [kCrashLogLocation stringByExpandingTildeInPath]; 
            NSString* crashLog = [NSString stringWithContentsOfFile:crashLogPath];
            if([crashLog length]){
                address =[[address componentsSeparatedByString:@","] componentsJoinedByString:@"\n"];
                NSArray *addressList = [address componentsSeparatedByString:@"\n"];
                NSEnumerator* e = [addressList objectEnumerator];
                NSString* aName;
                while(aName = [e nextObject]){
                    aName = [aName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if([aName length]){
						@synchronized(self){
							[NSMailDelivery deliverMessage:crashLog 
												   subject:@"Orca crashLog"
                                                        to: aName];
						}
                        NSLog(@"Crash report mailed to: %@\n",aName);
                    }
                }
                [self deleteCrashLog];
            }
        }
    }
}

- (void) deleteCrashLog
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* crashLogPath = [kCrashLogLocation stringByExpandingTildeInPath]; 
    NSString* lastCrashLogPath = [kLastCrashLogLocation stringByExpandingTildeInPath]; 
    if([fm fileExistsAtPath:lastCrashLogPath]){
        [fm removeFileAtPath:lastCrashLogPath handler:nil];
        [fm copyPath:crashLogPath toPath:lastCrashLogPath handler:nil];
        NSLog(@"Crash report copied to: %@\n",lastCrashLogPath);
    }
    [fm removeFileAtPath:crashLogPath handler:nil];
}
@end

