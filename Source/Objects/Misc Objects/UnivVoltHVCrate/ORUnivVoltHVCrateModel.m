//
//  ORUnivVoltHVCrateModel.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
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


#pragma mark •••Imported Files
#import "ORUnivVoltHVCrateModel.h"
#import "ORCamacCard.h"
#import "ORCamacBusProtocol.h"
#import "ORMacModel.h"

NSString* ORUnivVoltHVUSBConnector		    = @"ORUnivVoltHVUSBConnector";

@implementation ORUnivVoltHVCrateModel

#pragma mark •••initialization

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"UnivVoltHVCrateSmall"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    if([self powerOff]){
        NSAttributedString* s = [[[NSAttributedString alloc] initWithString:@"No Pwr"
                                                                 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                     [NSColor redColor],NSForegroundColorAttributeName,
                                                                     [NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,
                                                                     nil]] autorelease]; 
        [s drawAtPoint:NSMakePoint(35,10)];
    }
    
    if([[self orcaObjects] count]){
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:5 yBy:10];
        [transform scaleXBy:.3 yBy:.25];
        [transform concat];
        NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
        OrcaObject* anObject;
        while(anObject = [e nextObject]){
            BOOL oldHighlightState = [anObject highlighted];
            [anObject setHighlighted:NO];
            [anObject drawSelf:NSMakeRect(0,0,500,[[self image] size].height)];
            [anObject setHighlighted:oldHighlightState];
        }
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
    [self linkToController:@"ORUnivVoltHVCrateController"];
}

- (id) usbController
{
	return [[self objectConnectedTo:ORUnivVoltHVUSBConnector] getUSBController];
}

- (void) makeConnectors
{
	//since CAMAC can have usb or pci adapters, we let the controllers make the connectors
}

- (void) connectionChanged
{
	ORConnector* controllerConnector = [[self connectors] objectForKey:[self crateAdapterConnectorKey]];
	ORConnector* usbConnector = [[self connectors] objectForKey:ORUnivVoltHVUSBConnector];
	if(![usbConnector isConnected] && ![controllerConnector isConnected]){
		[usbConnector setHidden:NO];
		[controllerConnector setHidden:NO];
		if(cratePowerAlarm){
			[self setPowerOff:NO];
		    [cratePowerAlarm clearAlarm];
			[cratePowerAlarm release];
			cratePowerAlarm = nil;
			[self viewChanged:nil];
			[[NSNotificationCenter defaultCenter]
                postNotificationName:ORForceRedraw
                              object:self];

		}
	}
	else {
		if([usbConnector isConnected]){
			usingUSB = YES;
			[controllerConnector setHidden:YES];
		}
		else {
			usingUSB = NO;
			[usbConnector setHidden:YES];
		}
	}
}

#pragma mark •••Accessors
- (NSString*) adapterArchiveKey
{
	return @"UnivVoltHV Adapter";
}

//------------------------------------
//depreciated (11/29/06) remove someday
- (NSString*) crateAdapterConnectorKey
{
	return @"UnivVoltHV Crate Adapter Connector";
}
//------------------------------------


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORCamacCardSlotChangedNotification
                       object : nil];

    
    [notifyCenter addObserver : self
                     selector : @selector(powerFailed:)
                         name : @"UnivVoltHVPowerFailedNotification"
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(powerRestored:)
                         name : @"UnivVoltHVPowerRestoredNotification"
                       object : nil];
}

- (void) powerFailed:(NSNotification*)aNotification
{
    if([aNotification object] == [self controllerCard] || [[aNotification object] guardian] == self){
        if(!cratePowerAlarm){
            cratePowerAlarm = [[ORAlarm alloc] initWithName:@"No UnivVoltHV Crate Power" severity:kHardwareAlarm];
            [cratePowerAlarm setSticky:YES];
            [cratePowerAlarm setHelpStringFromFile:@"NoUnivVoltHVCratePowerHelp"];
            [cratePowerAlarm postAlarm];
        } 
        [self setPowerOff:YES];
    }
}

- (void) powerRestored:(NSNotification*)aNotification
{
    if([aNotification object] == [self controllerCard] || [[aNotification object] guardian] == self){
        if(cratePowerAlarm){
            [cratePowerAlarm clearAlarm];
            [cratePowerAlarm release];
            cratePowerAlarm = nil;
		}
		
		if([self powerOff])[[self adapter] executeZCycle];
        [self setPowerOff:NO];
    }
}

- (void) pollCratePower
{
	if(usingUSB){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollCratePower) object:nil];
		NS_DURING
			//if(![[ORGlobal sharedInstance] runInProgress]){
			[[self controllerCard] checkCratePower];
			//}
		NS_HANDLER
		NS_ENDHANDLER
		[self performSelector:@selector(pollCratePower) withObject:nil afterDelay:10];
	}
	else [super pollCratePower];
}


- (id) controllerCard
{
	if(usingUSB){
		return [self adapter];
	}
	else {
		return [self objectConnectedTo:[self crateAdapterConnectorKey]];
	}
}

- (void) runAboutToStart:(NSNotification*)aNote
{
	[[self controllerCard] checkCratePower];
	
    [[self adapter] setCrateInhibit:YES];
    NSLog(@"Inhibit Set on UnivVoltHV Crate %d\n",[self crateNumber]);
    //[[self adapter] executeZCycle];
    //NSLog(@"Z-Cycle UnivVoltHV Crate %d\n",[self crateNumber]);
    //[[self adapter] executeCCycle];
    //NSLog(@"C-Cycle UnivVoltHV Crate %d\n",[self crateNumber]);
    
}

- (void) runStarted:(NSNotification*)aNote
{
    [[self adapter] setCrateInhibit:NO];
    NSLog(@"Inhibit Released on UnivVoltHV Crate %d\n",[self crateNumber]);
}

- (void) runAboutToStop:(NSNotification*)aNote
{
    [[self adapter] setCrateInhibit:YES];    
    NSLog(@"Inhibit Set on UnivVoltHV Crate %d\n",[self crateNumber]);
}

- (void) doNoPowerAlert:(NSException*)exception action:(NSString*)message
{
    NSLogColor([NSColor redColor],@"****** CC32 Not Available          ******\n");
	[super doNoPowerAlert:exception action:message];
}

@end
