//
//  ORProcessModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
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
#import "ORProcessElementModel.h"
#import "ORProcessModel.h"
#import "ORProcessThread.h"
#import "ORProcessCenter.h"

NSString* ORProcessModelSampleRateChanged			= @"ORProcessModelSampleRateChanged";
NSString* ORProcessTestModeChangedNotification      = @"ORProcessTestModeChangedNotification";
NSString* ORProcessRunningChangedNotification       = @"ORProcessRunningChangedNotification";
NSString* ORProcessModelCommentChangedNotification  = @"ORProcessModelCommentChangedNotification";
NSString* ORProcessModelShortNameChangedNotification= @"ORProcessModelShortNameChangedNotification";
NSString* ORProcessModelUseAltViewChanged			= @"ORProcessModelUseAltViewChanged";

@implementation ORProcessModel

#pragma mark ¥¥¥initialization
- (id) init
{
	self = [super init];
	sampleRate = 10;
	[self registerNotificationObservers];
	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[comment release];
	[shortName release];
	[testModeAlarm clearAlarm];
    [testModeAlarm release];
	[super dealloc];
}

- (NSString*) helpURL
{
	return @"Process_Control/Process_Container.html";
}

- (void) awakeAfterDocumentLoaded
{
	[super awakeAfterDocumentLoaded];
	if(wasRunning){
		[self startRun];
	}
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(setUpImage)
                         name : ORProcessEmailOptionsChangedNotification
                       object : nil];
    
}

#pragma mark ***Accessors
- (void) setProcessIDs
{
	for(OrcaObject* obj in [self orcaObjects]){
		[self assignProcessID:obj];
	}
}

- (void)assignProcessID:(id)objToGetID
{
	if(![objToGetID processID]){
		unsigned long anId = 1;
		do {
			BOOL idAlreadyUsed = NO;
			for(id anObj in [self orcaObjects]){
				if(anObj == objToGetID)continue;
				if([anObj processID] == anId){
					anId++;
					idAlreadyUsed = YES;
					break;
				}
			}
			if(!idAlreadyUsed){
				[objToGetID setProcessID:anId];
				break;
			}
		}while(1);
	}
}

- (BOOL) useAltView
{
	return useAltView;
}

- (void) setUseAltView:(BOOL)aState
{
	BOOL deselectIcons = NO;
	if(aState != useAltView)deselectIcons = YES;
	useAltView = aState;
	for(OrcaObject* obj in [self orcaObjects]){
		if([obj respondsToSelector:@selector(setUseAltView:)]){
			[obj setUseAltView:useAltView];
			if(deselectIcons)[obj setHighlighted:NO];
		}
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelUseAltViewChanged object:self];
}

- (float) sampleRate
{
    return sampleRate;
}

- (void) setSampleRate:(float)aSampleRate
{
	
	if(aSampleRate<=0.001)aSampleRate = 0.001;
	else if(aSampleRate>10)  aSampleRate = 10;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleRate:sampleRate];
    
    sampleRate = aSampleRate;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelSampleRateChanged object:self];
}

- (NSString*) elementName
{
	if([shortName length])return [self shortName];
	else return [NSString stringWithFormat:@"Process %d",[self uniqueIdNumber]];
}


- (id) stateValue
{
    NSString* stateString = @"Idle";
    if(processRunning){
        if(inTestMode)stateString = @"Testing";
        else stateString = @"Running";
    }
    return stateString;
}

- (NSString*) fullHwName
{
    return @"";
}

- (NSString*) shortName
{
	return shortName;
}
- (void) setShortName:(NSString*)aComment
{
    if(!aComment)aComment = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setShortName:shortName];
    
    [shortName autorelease];
    shortName = [aComment copy];
    [self setUpImage];
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORProcessModelShortNameChangedNotification
                              object:self];
}


- (NSString*)comment
{
    return comment;
}
- (void) setComment:(NSString*)aComment
{
    if(!aComment)aComment = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setComment:comment];
    
    [comment autorelease];
    comment = [aComment copy];
    
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORProcessModelCommentChangedNotification
                              object:self];
    
}

- (BOOL) processRunning
{
    return processRunning;
}
- (void) setProcessRunning:(BOOL)aState
{
    [self setHighlighted:NO];
	
    processRunning = aState;

    [self setUpImage];
	
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORProcessRunningChangedNotification
					  object:self];
}

- (void) putInTestMode
{
	[[self undoManager] disableUndoRegistration];
	[self setInTestMode:YES];
	[[self undoManager] enableUndoRegistration];
}

- (void) putInRunMode
{
	[[self undoManager] disableUndoRegistration];
	[self setInTestMode:NO];
	[[self undoManager] enableUndoRegistration];
}

- (BOOL) inTestMode
{
    return inTestMode;
}

- (void) setInTestMode:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInTestMode:inTestMode];

	
    inTestMode = aState;

    [self setUpImage];
	
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORProcessTestModeChangedNotification
					  object:self];
    

	if(!inTestMode && processRunning)		[self clearTestAlarm];
	else if(inTestMode && processRunning)	[self postTestAlarm];

}

- (void) postTestAlarm
{
	if(inTestMode){
		if(!testModeAlarm){
			testModeAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Process %d in TestMode",[self uniqueIdNumber]] severity:kInformationAlarm];
			[testModeAlarm setHelpString:@"The Process is in test mode. This means that hardware will NOT be touched. Input relays can be switched by a Cmd-Click"];

		}
		[testModeAlarm postAlarm];
	}
}

- (void) clearTestAlarm
{
	[testModeAlarm clearAlarm];
	[testModeAlarm release];
	testModeAlarm = nil;
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each Process can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"Process"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    
	
    if([self uniqueIdNumber]){
        NSString* stateString = @"Idle";
        if(processRunning){
            if(inTestMode)stateString = @"Testing";
            else stateString = @"Running";
        }
				
        NSAttributedString* n = [[NSAttributedString alloc] 
                                initWithString:[NSString stringWithFormat:@"%d %@",[self uniqueIdNumber],stateString] 
                                    attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:12] forKey:NSFontAttributeName]];
        
        [n drawInRect:NSMakeRect(10,[i size].height-18,[i size].width-20,16)];
        [n release];

    }

    if([shortName length]){
        NSAttributedString* n = [[NSAttributedString alloc] 
                                initWithString:shortName
                                    attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:12] forKey:NSFontAttributeName]];
        
		NSSize theIconSize = [[self image] size];
        NSSize textSize = [n size];
        float x = theIconSize.width/2 - textSize.width/2;
        [n drawInRect:NSMakeRect(x,5,textSize.width,textSize.height)];
		[n release];
    }



    if(processRunning && inTestMode){
        NSImage* aNoticeImage = [NSImage imageNamed:@"notice"];
        [aNoticeImage compositeToPoint:NSMakePoint(0,0)operation:NSCompositeSourceOver];
    }
    if(processRunning){
        NSImage* aLockedImage = [NSImage imageNamed:@"smallLock"];
        [aLockedImage compositeToPoint:NSMakePoint([self frame].size.width - [aLockedImage size].width,0)operation:NSCompositeSourceOver];
    }
	
	if([[ORProcessCenter sharedProcessCenter] heartbeatTimeIndex] == 0){
        NSImage* noHeartbeatImage = [NSImage imageNamed:@"noHeartbeat"];
        [noHeartbeatImage compositeToPoint:NSMakePoint(0,0) operation:NSCompositeSourceOver];
	}
	

    [i unlockFocus];
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
                postNotificationName:OROrcaObjectImageChanged
                              object:self];

}

- (void) makeMainController
{
    [self linkToController:@"ORProcessController"];
}

- (int) compareStringTo:(id)anElement usingKey:(NSString*)aKey
{
    NSString* ourKey   = [self valueForKey:aKey];
    NSString* theirKey = [anElement valueForKey:aKey];
    if(!ourKey && theirKey)         return 1;
    else if(ourKey && !theirKey)    return -1;
    else if(!ourKey || !theirKey)   return 0;
    return [ourKey compare:theirKey];
}

- (void) startRun
{
	NSArray* outputNodes = [self collectObjectsRespondingTo:@selector(isTrueEndNode)];
    //NSArray* outputNodes = [self collectObjectsOfClass:NSClassFromString(@"ORProcessEndNode")];
	if([outputNodes count] == 0){
		NSLog(@"%@ has no output nodes. Process NOT started... nothing to do!\n",shortName);
		return;
	}
	
    if(![[ORProcessThread  sharedProcessThread] nodesRunning:outputNodes]){
		[[ORProcessThread  sharedProcessThread] startNodes:outputNodes];
		[self setProcessRunning:YES];
		NSString* t = inTestMode?@"(Test Mode)":@"";
		if([shortName length])NSLog(@"%@ Started %@\n",shortName,t);
		else NSLog(@"Process %d Started %@\n",[self uniqueIdNumber],t);

		if(inTestMode){
			[self postTestAlarm];
		}
		else {
			[[ORProcessCenter sharedProcessCenter] performSelector:@selector(sendStartNotice:) withObject:self afterDelay:1];
		}
	}
}

- (void) stopRun
{
	NSArray* outputNodes = [self collectObjectsRespondingTo:@selector(isTrueEndNode)];
	//NSArray* outputNodes = [self collectObjectsOfClass:NSClassFromString(@"ORProcessEndNode")];
    if([[ORProcessThread  sharedProcessThread] nodesRunning:outputNodes]){
		[self clearTestAlarm];
		[[ORProcessThread  sharedProcessThread] stopNodes:outputNodes];
		[self setProcessRunning:NO];
		NSString* t = inTestMode?@"(Test Mode)":@"";
		if([shortName length])NSLog(@"%@ Stopped %@\n",shortName,t);
		else NSLog(@"Process %d Stopped %@\n",[self uniqueIdNumber],t);
		
		if(!inTestMode){
			[[ORProcessCenter sharedProcessCenter] sendStopNotice:self];
		}
	}
}

- (void) startStopRun
{
	NSArray* outputNodes = [self collectObjectsRespondingTo:@selector(isTrueEndNode)];
//    NSArray* outputNodes = [self collectObjectsOfClass:NSClassFromString(@"ORProcessEndNode")];
    if([[ORProcessThread  sharedProcessThread] nodesRunning:outputNodes]){
		[self clearTestAlarm];
		[self stopRun];
    }
    else {
		if(inTestMode){
			[self postTestAlarm];
		}
		[self startRun];
    }
}

//- (BOOL) selectionAllowed
//{
//    return ![self processRunning];
//}

- (BOOL) changesAllowed
{
    return ![gSecurity isLocked:ORDocumentLock] && ![self processRunning];
}

- (Class) guardianClass 
{
    return NSClassFromString(@"ORGroup");
}
- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return [aGuardian isMemberOfClass:NSClassFromString(@"ORGroup")] ||
		   [aGuardian isMemberOfClass:NSClassFromString(@"ORContainerModel")];
}

- (void) setUniqueIdNumber :(unsigned long)aNumber
{
    [super setUniqueIdNumber:aNumber];
    [self setUpImage];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORForceRedraw
                      object: self];
}


#pragma mark ¥¥¥Sample Timing Control
- (BOOL) sampleGateOpen
{
	return sampleGateOpen;
}

- (void)processIsStarting
{
	//force first sample at start
	[lastSampleTime release];
	lastSampleTime = [[NSDate date] retain];
	sampleGateOpen = YES;
}

- (void) startProcessCycle
{
	if(!sampleGateOpen){
		NSDate* now = [NSDate date];
		if([now timeIntervalSinceDate:lastSampleTime] >= 1.0/sampleRate){
			sampleGateOpen  = YES;
		}
	}
}

- (void) endProcessCycle
{
	if(sampleGateOpen){
		[lastSampleTime release];
		lastSampleTime = [[NSDate date] retain];
	}
	sampleGateOpen = NO;
}

- (id) description
{
	NSString* s =  [NSString stringWithFormat:@"\nProcess %@ ",[self shortName]];
	if(processRunning){
		s = [s stringByAppendingString:@"[Running]\n"];
		s = [s stringByAppendingFormat:@"Sample Rate: %.1f\n",sampleRate];
		for(id anObj in [self orcaObjects]){
			if([anObj isKindOfClass:NSClassFromString(@"ORProcessHWAccessor")]){
				s = [s stringByAppendingFormat:@"%@\n",anObj];
			}
		}
	}
	else {
		s = [s stringByAppendingString:@"[NOT RUNNING]\n"];
	}
	s = [s stringByAppendingString:@"\n"];
	return s;
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
	//after the document is loaded we use this flag to autostart
	wasRunning = [decoder decodeBoolForKey:@"wasRunning"];
	
    float aSampleRate = [decoder decodeFloatForKey:@"ORProcessModelSampleRate"];\
	if(aSampleRate == 0)aSampleRate = 10;
    [self setSampleRate:aSampleRate];
    [self setInTestMode:[decoder decodeIntForKey:@"inTestMode"]];
    [self setComment:[decoder decodeObjectForKey:@"comment"]];
    [self setShortName:[decoder decodeObjectForKey:@"shortName"]];
    [self setUseAltView:[decoder decodeBoolForKey:@"useAltView"]];
	
    [[self undoManager] enableUndoRegistration];
	[self registerNotificationObservers];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:sampleRate forKey:@"ORProcessModelSampleRate"];
    [encoder encodeInt:inTestMode forKey:@"inTestMode"];
    [encoder encodeObject:comment forKey:@"comment"];
    [encoder encodeObject:shortName forKey:@"shortName"];
    [encoder encodeBool:useAltView forKey:@"useAltView"];
	//store the running flag so we can auto start next time
    [encoder encodeBool:processRunning forKey:@"wasRunning"];
}

@end
