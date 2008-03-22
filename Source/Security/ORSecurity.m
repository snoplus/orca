//
//  ORSecurity.m
//  Orca
//
//  Created by Mark Howe on Thu Feb 19 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORValidatePassword.h"

NSString*   ORSecurityNumberLockPagesChanged = @"ORSecurityNumberLockPagesChanged";

ORSecurity* gSecurity = nil;
static ORSecurity* sharedInstance = nil;

@interface ORSecurity (private)
- (void) _validatePWDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
@end

@implementation ORSecurity
+ (id) sharedInstance
{
    if(!sharedInstance){
        sharedInstance = [[ORSecurity alloc] init];
        gSecurity = sharedInstance;
    }
    return sharedInstance;
}


//don't call this unless you're using this class in a special, non-global way.
-(id)init
{
    self = [super init];
    return self;
}

-(void)dealloc
{
    [locks release];
    [super dealloc];
}

- (NSDictionary *)locks {
    return locks; 
}

- (void)setLocks:(NSMutableDictionary *)aLocks {
    [aLocks retain];
    [locks release];
    locks = aLocks;
}

- (int) numberItemsUnlocked
{
    return [locks count];
}

- (void) tryToSetLock:(NSString*)aLockName to:(BOOL)aState forWindow:(NSWindow*)aWindow
{
    if(aState == NO){
        if([self isLocked:aLockName]){
            //to unlock requires a password.
            NSDictionary* contextInfo = [NSDictionary dictionaryWithObject:aLockName forKey:@"LockName"];
            passWordPanel = [[ORValidatePassword validateForWindow:aWindow 
                                    modalDelegate:self 
                                   didEndSelector:@selector(_validatePWDidEnd:returnCode:contextInfo:) 
                                      contextInfo:contextInfo] retain];
        }
        else {
            //already unlocked, nothing to do.
        }
    }
    else {
        [self setLock:aLockName to:YES]; //can always lock it.
    }
}

- (void) setLock:(NSString*)aLockName to:(BOOL)aState
{
    //note that an entry in the locks dictionary means that the item is UNLOCKED.
    if(!locks)[self setLocks:[NSMutableDictionary dictionary]];
    
    if(aState)[locks removeObjectForKey:aLockName];
    else [locks setObject:[NSNumber numberWithLong:0] forKey:aLockName];
    
    [[NSNotificationCenter defaultCenter]
         postNotificationName:aLockName
                       object:self];
    
    [[NSNotificationCenter defaultCenter]
         postNotificationName:ORSecurityNumberLockPagesChanged
                       object:self];
    
    
    
}

- (BOOL) isLocked:(NSString*)aLockName
{
    return [locks objectForKey:aLockName]==nil;
}

- (BOOL) globalSecurityEnabled
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey: OROrcaSecurityEnabled] boolValue];
}

- (BOOL) runInProgressOrIsLocked:(NSString*)aLockName
{
    return [self isLocked:aLockName] || [gOrcaGlobals runInProgress]; 
}

- (BOOL) runInProgressButNotType:(unsigned long)aMask orIsLocked:(NSString*)aLockName;
{
    if([self isLocked:aLockName])return YES;
    else if([gOrcaGlobals runInProgress]){
        if(!([gOrcaGlobals runType] & aMask))return YES;
        else return NO;
    }
    else return NO;
}

- (void) lockAll
{
    NSEnumerator* e = [locks keyEnumerator];
    id key;
    while(key=[e nextObject]){
        [self setLock:key to:YES];
    }
}


@end

@implementation ORSecurity (private)

- (void) _validatePWDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
    //set the lock according to the result.
    NSString* lockName = [userInfo objectForKey:@"LockName"];
    if(returnCode == kGoodPassword){
        [self setLock:lockName to:NO];
    }
    else {
        [self setLock:lockName to:YES];
    }
	[passWordPanel release];
	passWordPanel = nil;
}

@end
