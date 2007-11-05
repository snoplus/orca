//
//  ORScriptInterface.m
//  Orca
//
//  Created by Mark Howe on Oct 8, 2004.
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


#import "ORScriptInterface.h"
#import "ORScriptTaskModel.h"

@implementation ORScriptInterface
-(id)	init
{
    if( self = [super init] ){
        [NSBundle loadNibNamed: @"ScriptInterfaceTask" owner: self];	
        [self setTitle:@"Orca Script"];
    }
    return self;
}

- (void) delloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


- (void) awakeFromNib
{
    [super awakeFromNib];
    [self addExtraPanel:extraView];
}

- (BOOL) okToRun
{
    return YES;
}

- (void) setDelegate:(id)aDelegate
{
	[super setDelegate:aDelegate];
	[self argsChanged:nil];
	[self breakChainChanged:nil];
    [self registerNotificationObservers];
}

- (void) registerNotificationObservers
{	
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(argsChanged:)
                         name : ORScriptTaskArgsChanged
                       object : delegate];

    [notifyCenter addObserver : self
                     selector : @selector(breakChainChanged:)
                         name : ORScriptTaskBreakChainChanged
						object: delegate];	

}

- (void) argsChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kNumScriptArgs;i++){
		[[argsMatrix cellWithTag:i] setObjectValue:[delegate arg:i]];
	}
}

- (void) breakChainChanged:(NSNotification*)aNote
{
	[breakChainButton setState:[delegate breakChain]];
}

#pragma mark ¥¥¥Actions

- (IBAction) argAction:(id)sender
{
	int i = [[sender selectedCell] tag];
	NSDecimalNumber* n;
	NSString* s = [[sender selectedCell] stringValue];
	if([s rangeOfString:@"x"].location != NSNotFound || [s rangeOfString:@"X"].location != NSNotFound){
		unsigned long num = strtoul([s cStringUsingEncoding:NSASCIIStringEncoding],0,16);
		n = (NSDecimalNumber*)[NSDecimalNumber numberWithUnsignedLong:num];
	}
	else n = [NSDecimalNumber decimalNumberWithString:s];
	[delegate setArg:i withValue:n];
}

- (IBAction) editAction:(id)sender
{
	[delegate showMainInterface];
}

- (IBAction) breakChainAction:(id) sender
{
	[delegate setBreakChain:[sender intValue]];
}


#pragma mark ¥¥¥Task Methods
- (void) stopTask
{
	[delegate stopScript];
	[super stopTask];
}

- (void) prepare
{
    [super prepare];
	didStart = NO;
	waitedOnce = NO;
}


- (BOOL)  doWork
{
	if(!didStart){
		[delegate runScript];
		didStart = YES;
	}
	if(waitedOnce){
		if([delegate running])return YES;
		else return NO;
	}
	waitedOnce = YES;
	return YES;
}


- (void) finishUp
{
    [super finishUp];
    
    [self setMessage:@"Idle"];
}

- (void) cleanUp
{
    [self setMessage:@"Idle"];
}

- (void) enableGUI:(BOOL)state
{
    [argsMatrix setEnabled:state];
}


- (NSString*) description
{
    return @"TDB";
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [self registerNotificationObservers];
    [NSBundle loadNibNamed: @"ScriptInterfaceTask" owner: self];

    [[self undoManager] disableUndoRegistration];
 
    [[self undoManager] enableUndoRegistration];    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
    [encoder encodeObject:args forKey:@"args"];
}
@end
