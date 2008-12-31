//
//  ORDocument.m
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
#define __CARBONSOUND__ //temp until undated to >10.3
#import <Carbon/Carbon.h>
#import "ORStatusController.h"
#import "ORDocumentController.h"
#import "ORAlarmCollection.h"

//#import "NKDPostgreSQLConnection.h"
#import "ORTaskMaster.h"
#import "ORHWWizardController.h"
#import "ORCommandCenter.h"
#import "ORGateGroup.h"

@implementation ORDocument

#pragma mark ¥¥¥Document ID Strings
static NSString* ORDocumentType       = @"Orca Experiment"; //must == CFBundleTypeName entry in Info.plist file.
static NSString* ORDocumentVersionKey = @"Version";
static int       ORDocumentVersion    = 1;

#pragma mark ¥¥¥External Strings
NSString* ORStatusTextChangedNotification   = @"Status Text Has Changed";
NSString* ORDocumentLoadedNotification      = @"ORDocumentLoadedNotification";
NSString* ORDocumentScaleChangedNotification= @"ORDocumentScaleChangedNotification";
NSString* ORDocumentClosedNotification		=@"ORDocumentClosedNotification";
NSString* ORDocumentLock					= @"ORDocumentLock";

#pragma mark ¥¥¥Initialization
- (id)init
{
    if(self =[super init]){
		[ORStatusController sharedStatusController];
        
        [[NSApp delegate] setDocument:self];
        [self setGroup:[[[ORGroup alloc] init] autorelease]];
        
       	[self setOrcaControllers:[NSMutableArray array]];
        
        NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
        [notifyCenter addObserver : self
                         selector : @selector(windowClosing:)
                             name : NSWindowWillCloseNotification
                           object : nil];
        
        
        [notifyCenter addObserver : self
                         selector : @selector(objectsRemoved:)
                             name : ORGroupObjectsRemoved
                           object : nil];
        
        
        [ORCommandCenter sharedCommandCenter];
    }
    return self;
}

- (void) dealloc
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [statusText release];
	@try {
		[orcaControllers makeObjectsPerformSelector:@selector(close)];
		[orcaControllers release];
	}
	@catch(NSException* localException) {
	}
    [group sleep];
    [group release];
    [self setGateGroup: nil];
	
    [[self undoManager] removeAllActions];
	RestoreApplicationDockTileImage();
    
	[[NSApp delegate] setDocument:nil];
    //[self setDbConnection:nil];
    [super dealloc];
}


#pragma mark ¥¥¥Assessors

- (BOOL) documentCanBeChanged
{
    return ![gSecurity isLocked:ORDocumentLock] && ![gOrcaGlobals runInProgress];
}

- (void)setGroup:(ORGroup *)aGroup
{ 
    [aGroup retain];
    [group release];
    group = aGroup;
}

- (ORGroup*)group
{
    return group;
}


- (NSMutableArray*) orcaControllers
{
    return orcaControllers;
}
- (void) setOrcaControllers:(NSMutableArray*)newOrcaControllers
{
    [newOrcaControllers retain];
    [orcaControllers release];
    orcaControllers = newOrcaControllers;
}


- (int)scaleFactor 
{
    
    return scaleFactor;
}

- (void)setScaleFactor:(int)aScaleFactor 
{
    if(aScaleFactor < 20)aScaleFactor = 20;
    else if(aScaleFactor>150)aScaleFactor=150;
    
    if(abs(aScaleFactor-scaleFactor)>1){
        [[[self undoManager] prepareWithInvocationTarget:self] setScaleFactor:scaleFactor];
		
        scaleFactor = aScaleFactor;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDocumentScaleChangedNotification
                                                            object:self];
    }
}


- (NSString*) statusText
{
    return statusText;
}

- (void) setStatusText:(NSString*)aName
{
    //not undoable..
    
    [statusText autorelease];
    statusText = [aName copy];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORStatusTextChangedNotification
	 object:self];
    
}

/*- (NKDPostgreSQLConnection*) dbConnection
 {
 return dbConnection;
 }
 
 - (void) setDbConnection:(NKDPostgreSQLConnection*)aConnection
 {
 [aConnection retain];
 [dbConnection release];
 dbConnection = aConnection;
 }
 */



- (ORGateGroup *) gateGroup;
{
    if(!gateGroup)[self setGateGroup:[ORGateGroup gateGroup]];
    return gateGroup; 
}

- (void) setGateGroup: (ORGateGroup *) aGateGroup;
{
    [aGateGroup retain];
    [gateGroup release];
    gateGroup = aGateGroup;
}

- (void) assignUniqueIDNumber:(id)objToGetID
{
    if(![objToGetID uniqueIdNumber]){
        NSArray* objects = [self collectObjectsOfClass:[objToGetID class]];
        unsigned long anId = 1;
        do {
            BOOL idAlreadyUsed = NO;
            NSEnumerator* e = [objects objectEnumerator];
            id anObj;
            while(anObj = [e nextObject]){
                if(anObj == objToGetID)continue;
                if([anObj uniqueIdNumber] == anId){
                    anId++;
                    idAlreadyUsed = YES;
                    break;
                }
            }
            if(!idAlreadyUsed){
                [objToGetID setUniqueIdNumber:anId];
                break;
            }
        }while(1);
    }
}

#pragma mark ¥¥¥Window Management
- (void) makeWindowControllers
{
    ORDocumentController* documentController = [[ORDocumentController alloc] init];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartUpMessage"
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:@"Preloading Catalog..." forKey:@"Message"]];
	[documentController preloadCatalog];
	
	
    if(scaleFactor == 0)[self setScaleFactor:100];
    [self addWindowController:documentController];
    [documentController showWindow:self];
	
    [documentController release];
}

- (void) resetAlreadyVisitedInChainSearch
{
	[[self group] resetAlreadyVisitedInChainSearch];
}


- (NSArray*) collectObjectsOfClass:(Class)aClass
{
    return [[self group] collectObjectsOfClass:aClass];
}

- (NSArray*) collectObjectsConformingTo:(Protocol*)aProtocol
{
    return [[self group] collectObjectsConformingTo:aProtocol];
}

- (NSArray*) collectObjectsRespondingTo:(SEL)aSelector
{
    return [[self group] collectObjectsRespondingTo:aSelector];
}

- (id) findObjectWithFullID:(NSString*)aFullID
{
    return [[self group] findObjectWithFullID:aFullID];
}

- (NSMutableDictionary*) fillInHeaderInfo:(NSMutableDictionary*)dictionary
{
	//add in the document parameters
	NSMutableDictionary* docDict = [NSMutableDictionary dictionary];
    [docDict setObject:[self fileName] forKey:@"documentName"];
    [docDict setObject:[[[NSBundle mainBundle] infoDictionary]       objectForKey:@"CFBundleVersion"] forKey:@"OrcaVersion"];
    [docDict setObject:[NSString stringWithFormat:@"%@",[NSDate date]]   forKey:@"date"];
    [dictionary setObject:docDict forKey:@"Document Info"];
	
	//add in any gategroups
    if([gateGroup count])[gateGroup addParametersToDictionary:dictionary];
	
	//have our group add parameters
	//[group addParametersToDictionary:dictionary];
	
	//setup and add Objects to object info list
	NSMutableDictionary* objectInfoDictionary = [NSMutableDictionary dictionary];
	NSMutableArray* allObjects		= (NSMutableArray*)[self collectObjectsOfClass:NSClassFromString(@"OrcaObject")];
	NSMutableArray* crates			= [NSMutableArray array];
	NSMutableArray* dataChain		= [NSMutableArray array];
	NSMutableArray* gpib			= [NSMutableArray array];
	NSMutableDictionary* exp		= [NSMutableDictionary dictionary];
	NSEnumerator* e					= [allObjects objectEnumerator];
	id anObj;
	while(anObj = [e nextObject]){
		if([anObj isKindOfClass:NSClassFromString(@"ORCrate")]){
			if([anObj respondsToSelector:@selector(addObjectInfoToArray:)]){
				[anObj addObjectInfoToArray:crates];
			}
		}
		else if([anObj isKindOfClass:NSClassFromString(@"ORDataChainObject")]){
			if([anObj respondsToSelector:@selector(addObjectInfoToArray:)]){
				[anObj addObjectInfoToArray:dataChain];
			}
		}
		else if([anObj isKindOfClass:NSClassFromString(@"ORGpibDeviceModel")]){
			if([anObj respondsToSelector:@selector(addObjectInfoToArray:)]){
				[anObj addObjectInfoToArray:gpib];
			}
		}
		else if([anObj isKindOfClass:NSClassFromString(@"ORExperimentModel")]){
			if([anObj respondsToSelector:@selector(addParametersToDictionary:)]){
				[anObj addParametersToDictionary:objectInfoDictionary];
			}
		}
	}
	
	
	if([crates count]){
		[objectInfoDictionary setObject:crates forKey:@"Crates"];
	}
	if([dataChain count]){
		[objectInfoDictionary setObject:dataChain forKey:@"DataChain"];
	}
	if([gpib count]){
		[objectInfoDictionary setObject:gpib forKey:@"Gpib"];
	}
	if([exp count]){
		[objectInfoDictionary setObject:exp forKey:@"Experiments"];
	}
	
	//add the Object Info into the dictionary from our argument list.
	if([objectInfoDictionary count]){
		[dictionary setObject:objectInfoDictionary forKey:@"ObjectInfo"];
	}
    return dictionary;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
	return [group addParametersToDictionary:dictionary];
}

#pragma mark ¥¥¥Archival
static NSString* ORGroupKey             = @"ORGroup";
static NSString* ORGateGroupKey         = @"ORGateGroupKey";
static NSString* OROrcaControllers	    = @"OROrcaControllers";
static NSString* ORTaskMasterVisibleKey = @"ORTaskMasterVisibleKey";
static NSString* ORDocumentScaleFactor  = @"ORDocumentScaleFactor";

- (NSData *)dataRepresentationOfType:(NSString *)type
{
	[self performSelector:@selector(saveDefaultFileName) withObject:nil afterDelay:0];
	if ([type isEqualToString:ORDocumentType]) {
		
		NSMutableData *data = [NSMutableData data];
		NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
		
		[[ORGlobal sharedGlobal] saveParams:archiver];
		
		[archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
		
		[archiver encodeInt:ORDocumentVersion forKey:ORDocumentVersionKey];
		
		[archiver encodeObject:[self group] forKey:ORGroupKey];
		
		[archiver encodeObject:[self controllersToSave] forKey:OROrcaControllers];						
		
		[archiver encodeBool:[[[ORTaskMaster sharedTaskMaster] window] isVisible] forKey:ORTaskMasterVisibleKey];
		
		[archiver encodeInt:scaleFactor forKey:ORDocumentScaleFactor];						
        
        [archiver encodeObject: gateGroup forKey: ORGateGroupKey];
		
		[[ORAlarmCollection sharedAlarmCollection] encodeEMailList:archiver];
		[[ORStatusController sharedStatusController] encode:archiver];
		[[ORStatusController sharedStatusController] saveLogBook:nil];
		
		[archiver finishEncoding];
		
		[archiver release];
		
		[[self undoManager] removeAllActions];
		
		[self performSelector:@selector(saveFinished) withObject:nil afterDelay:0];
		
		return data;
	}
    
    return nil;
}

- (void) saveFinished
{
	NSLog(@"Saved Configuration: %@\n",[self fileName]);
	@try {
		[afterSaveTarget performSelector:afterSaveSelector];
	}
	@catch(NSException* localException) {
	}
	afterSaveTarget = nil;
}
- (void) afterSaveDo:(SEL)aSelector withTarget:(id)aTarget
{
	afterSaveTarget = aTarget;
	afterSaveSelector = aSelector;
}


- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartUpMessage"
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:@"Loading Configuration..." forKey:@"Message"]];
	if ([type isEqualToString:ORDocumentType]) {
		[self performSelector:@selector(saveDefaultFileName) withObject:nil afterDelay:0];
		
		
		[[self undoManager] disableUndoRegistration];
		
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		
		[self setGroup:[unarchiver decodeObjectForKey:ORGroupKey]];	    
		[[ORGlobal sharedGlobal] loadParams:unarchiver];
		[self setGateGroup:[unarchiver decodeObjectForKey: ORGateGroupKey]];
		
		[[ORAlarmCollection sharedAlarmCollection] decodeEMailList:unarchiver];
		[[ORStatusController sharedStatusController] decode:unarchiver];
		
		@try {
			if((GetCurrentKeyModifiers() & shiftKey) == 0){
				[self setOrcaControllers:[unarchiver decodeObjectForKey:OROrcaControllers]];
				[self checkControllers];
			}
			else {
				NSLogColor([NSColor redColor], @"Shift Down down....Dialogs NOT loaded.\n");
			}
		}
		@catch(NSException* localException) {
			NSLogColor([NSColor redColor], @"Something wrong with the dialog configuration... Dialogs NOT restored\n");
			NSLogColor([NSColor redColor], @"but model data OK.\n");		
		}
		
		if([unarchiver decodeBoolForKey:ORTaskMasterVisibleKey] == YES){
			[[[ORTaskMaster sharedTaskMaster] window] orderFront:nil];
		}
		
		
		int value = [unarchiver decodeIntForKey:ORDocumentScaleFactor];
		if(value == 0)value = 100;
		[self setScaleFactor:value];
		
		
		[unarchiver finishDecoding];
		[unarchiver release];
		
		[[self undoManager] enableUndoRegistration];
		
		[[self group] wakeUp];
		
		NSEnumerator* e = [orcaControllers objectEnumerator];
		id controller;
		while(controller = [e nextObject]){
			@try {
				[controller showWindow:controller];
			}
			@catch(NSException* localException) {
			}
		}
		
		
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:ORDocumentLoadedNotification
		 object:self];
		
		@try {
			[group awakeAfterDocumentLoaded];
		}
		@catch(NSException* localException) {
		}
		
		[[self undoManager] removeAllActions];
		
		
		return YES;
	}
	return NO;
}

- (NSArray*) controllersToSave
{
	NSMutableArray* controllersToSave = [NSMutableArray array];
    NSEnumerator* e = [orcaControllers objectEnumerator];
    id controller;
    while(controller = [e nextObject]){
        if([controller model] != [[ORCommandCenter sharedCommandCenter] scriptIDEModel]){
            [controllersToSave addObject:controller];
        }
    }
	return controllersToSave;
}

- (void) checkControllers
{
    NSEnumerator* e = [orcaControllers objectEnumerator];
    id controller;
    NSMutableArray* badObjs = [NSMutableArray array];
    while(controller = [e nextObject]){
        if(![controller isKindOfClass:[OrcaObjectController class]]){
            [badObjs addObject:controller];
        }
    }
    [orcaControllers removeObjectsInArray:badObjs];
}


- (void) saveDefaultFileName
{
    [[NSUserDefaults standardUserDefaults] setObject:[self fileName] forKey:ORLastDocumentName];
}

- (void) copyDocumentTo:(NSString*)aPath append:(NSString*)aString
{
    [self saveDocument:self];
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* path = [aPath stringByAppendingPathComponent:[[self fileName] lastPathComponent]];
    NSString* ext = [[self fileName]pathExtension];
    path = [path stringByDeletingPathExtension];
    NSString* finalName = [[path stringByAppendingFormat:@"_%@",aString]stringByAppendingPathExtension:ext];
    if([fm copyPath:[self fileName] toPath:finalName handler:nil]){
        NSLog(@"Saving: %@\n",finalName);
    }
    else {
        NSLogColor([NSColor redColor],@"Error: Configuration file NOT saved with the data\n");
    }
    
}


#pragma mark ¥¥¥Orca Dialog Management
- (void) duplicateDialog:(id)dialog
{
    
    id controller = [[NSClassFromString([dialog className]) alloc] init];
    
    if([controller isKindOfClass:[OrcaObjectController class]]){
        
        [controller setModel:[dialog model]];
        
        if(!orcaControllers){
            [self setOrcaControllers:[NSMutableArray array]];
        }
        
        [orcaControllers addObject:controller];
        [controller showWindow:self];
    }
    [controller release];
}

- (void) makeController:(NSString*)aClassName forObject:(id)aModel
{
    
    BOOL shareDialogs = ![[[NSUserDefaults standardUserDefaults] objectForKey: OROpeningDialogPreferences] intValue];
    
    BOOL optionKeyIsDown = ([[NSApp currentEvent] modifierFlags] & 0x80000)>0;
    
    if(optionKeyIsDown) {
        if(shareDialogs)shareDialogs = NO;
        else shareDialogs = YES;
    }
    
    id controller = nil;
    
    //if a dialog already exists then use it no matter what.
    NSEnumerator* e = [orcaControllers objectEnumerator];
    while(controller = [e nextObject]){
        if([controller model] == aModel){
            [controller showWindow:self];
			[[controller window] makeFirstResponder:[controller window]];
            return;
        }
    }
    
    //ok, the dialog doesn't exist yet....
    if(shareDialogs == YES){
        //try to share one
        NSEnumerator* e = [orcaControllers objectEnumerator];
        while(controller = [e nextObject]){
            if([controller class] == NSClassFromString(aClassName)){
                [controller setModel:aModel];
                [controller showWindow:self];
				[[controller window] makeFirstResponder:[controller window]];
                return;
            }
        }
    }
    
    //if we get here then we'll have to make one.
    controller = [[NSClassFromString(aClassName) alloc] init];
    if([controller isKindOfClass:[OrcaObjectController class]]){
        
        [controller setModel:aModel];
        
        if(!orcaControllers){
            [self setOrcaControllers:[NSMutableArray array]];
        }
        
		[orcaControllers addObject:controller];

        [controller showWindow:self];
		[[controller window] makeFirstResponder:[controller window]];
    }
    [controller release];
    
    
}


- (void)objectsRemoved:(NSNotification*)aNote
{
    
    NSArray* list = [[aNote userInfo] objectForKey:ORGroupObjectList];
    NSEnumerator* objsToRemoveEnumerator = [list objectEnumerator];
    id anObj;
    while(anObj = [objsToRemoveEnumerator nextObject]){
        NSArray* totalList = [anObj familyList];    
        NSEnumerator* e = [totalList objectEnumerator];
        id objToBeRemoved;
		id controllersToRemove;
        while(objToBeRemoved = [e nextObject]){
            controllersToRemove = [self findControllersWithModel:objToBeRemoved];
            [orcaControllers removeObjectsInArray:controllersToRemove];
			//tricky, we also have to worry about objects that have subobjects that have dialogs
			id subObjectsToBeRemoved = [objToBeRemoved subObjectsThatMayHaveDialogs];
			NSEnumerator* e1 = [subObjectsToBeRemoved objectEnumerator];
			id subObjectToBeRemoved;
			while(subObjectToBeRemoved = [e1 nextObject]){
				controllersToRemove = [self findControllersWithModel:subObjectToBeRemoved];
	            [orcaControllers removeObjectsInArray:controllersToRemove];
			}
        }
    }
    
}

- (NSArray*) findControllersWithModel:(id)obj
{ 
    NSMutableArray* list = [NSMutableArray array];
    NSEnumerator* e = [orcaControllers objectEnumerator];
    id controller;
    while(controller = [e nextObject]){
        if([controller model] == obj){
            [list addObject:controller];
        }
    }
    return list;
}

- (void)windowClosing:(NSNotification*)aNote
{
    
    NSEnumerator* e = [orcaControllers objectEnumerator];
    id controller;
    while(controller = [e nextObject]){
        if([controller window] == [aNote object]){
            //[controller retain];
			@try {
				[orcaControllers removeObject:controller];
			}
			@catch(NSException* localException) {
			}
			// [controller performSelector:@selector(release) withObject:nil afterDelay:.1];
            break;
        }
    }
}

- (BOOL)shouldCloseWindowController:(NSWindowController *)windowController 
{
    if([[ORGlobal sharedGlobal] runInProgress]){
        NSRunAlertPanel(@"Run In Progess", @"Experiment can NOT be closed.", nil, nil,nil);
        return NO;
    }
    else if([self isDocumentEdited]){
        NSRunAlertPanel(@"Document Unsaved", @"Experiment can NOT be closed.", nil, nil,nil);
        return NO;
    }
    else {
        int choice = NSRunAlertPanel(@"Closing main window will close this experiment!",@"Is this really what you want?",@"Cancel",@"Close Experiment",nil);
        if(choice == NSAlertAlternateReturn){
            //[[self undoManager] removeAllActions];
            [[NSNotificationCenter defaultCenter]
			 postNotificationName:ORDocumentClosedNotification
			 object:self];
            
            return YES;
        }
        else return NO;
        
    }
}

- (void) windowMovedToFront:(NSWindowController*)aController
{
    if(aController && [orcaControllers containsObject:aController]){
        [aController retain];
        [orcaControllers removeObject:aController];
        [orcaControllers addObject:aController];
        [aController release];
    }
}

@end
