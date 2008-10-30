//
//  ORFecDaughterCardController.m
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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
#import "ORFecDaughterCardController.h"
#import "ORFecDaughterCardModel.h"
#import "ORSNOCard.h"

#pragma mark •••Definitions

@implementation ORFecDaughterCardController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"FecDaughterCard"];
    
    return self;
}



#pragma mark •••Notifications
-(void)registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORSNOCardSlotChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(rp1Changed:)
						 name : ORFec32ModelRp1Changed
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(rp2Changed:)
						 name : ORFec32ModelRp2Changed
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(vliChanged:)
						 name : ORFec32ModelVliChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(vsiChanged:)
						 name : ORFec32ModelVsiChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(vtChanged:)
						 name : ORFec32ModelVtChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(vbChanged:)
						 name : ORFec32ModelVbChanged
					   object : model];
					   					   
    [notifyCenter addObserver : self
					 selector : @selector(ns100widthChanged:)
						 name : ORFec32ModelNs100widthChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(ns20widthChanged:)
						 name : ORFec32ModelNs20widthChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(ns20delayChanged:)
						 name : ORFec32ModelNs20delayChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(tac0trimChanged:)
						 name : ORFec32ModelTac0trimChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(tac1trimChanged:)
						 name : ORFec32ModelTac1trimChanged
					   object : model];					      
 }

#pragma mark •••Interface Management
-(void)updateWindow
{
	[super updateWindow];
	[self slotChanged:nil];
	[self rp1Changed:nil];
	[self rp2Changed:nil];
	[self vliChanged:nil];
	[self vsiChanged:nil];
	[self vtChanged:nil];
	[self vbChanged:nil];	   
	[self ns100widthChanged:nil];			   
	[self ns20widthChanged:nil];   
	[self ns20delayChanged:nil];			   
	[self tac0trimChanged:nil];		   
	[self tac1trimChanged:nil];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"FecDaughterCard (%@)",[model identifier]]];
}

- (void) rp1Changed:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<2;i++) [[rp1Matrix cellWithTag:i] setIntValue:[model rp1:i]];
}

- (void) rp2Changed:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<2;i++) [[rp2Matrix cellWithTag:i] setIntValue:[model rp2:i]];
}

- (void) vliChanged:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<2;i++) [[vliMatrix cellWithTag:i] setIntValue:[model vli:i]];
}

- (void) vsiChanged:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<2;i++) [[vsiMatrix cellWithTag:i] setIntValue:[model vsi:i]];
}

- (void) vtChanged:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<8;i++) [[vtMatrix cellWithTag:i] setIntValue:[model vt:i]];
}

- (void) vbChanged:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<16;i++) [[vbMatrix cellWithTag:i] setIntValue:[model vb:i]];
}
	   
- (void) ns100widthChanged:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<8;i++) [[ns100widthMatrix cellWithTag:i] setIntValue:[model ns100width:i]];
}
			   
- (void) ns20widthChanged:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<8;i++) [[ns20widthMatrix cellWithTag:i] setIntValue:[model ns20width:i]];
} 
  
- (void) ns20delayChanged:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<8;i++) [[ns20delayMatrix cellWithTag:i] setIntValue:[model ns20delay:i]];

}
			   
- (void) tac0trimChanged:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<8;i++) [[tac0trimMatrix cellWithTag:i] setIntValue:[model tac0trim:i]];
}
		   
- (void) tac1trimChanged:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<8;i++) [[tac1trimMatrix cellWithTag:i] setIntValue:[model tac1trim:i]];
}

#pragma mark •••Actions
- (void) rp1Action:(id)sender
{
	int i = [[rp1Matrix selectedCell] tag];
	[model setRp1:i withValue:[sender intValue]];
}

- (void) rp2Action:(id)sender
{
	int i = [[rp2Matrix selectedCell] tag];
	[model setRp2:i withValue:[sender intValue]];
}
 
- (void) vliAction:(id)sender
{
	int i = [[vliMatrix selectedCell] tag];
	[model setVli:i withValue:[sender intValue]];
}
 
- (void) vsiAction:(id)sender
{
	int i = [[vsiMatrix selectedCell] tag];
	[model setVsi:i withValue:[sender intValue]];
}
 
- (void) vtAction:(id)sender
{
	int i = [[vtMatrix selectedCell] tag];
	[model setVt:i withValue:[sender intValue]];
}
 
- (void) vbAction:(id)sender
{
	int i = [[vbMatrix selectedCell] tag];
	[model setVb:i withValue:[sender intValue]];
} 
	   
- (void) ns100widthAction:(id)sender
{
	int i = [[ns100widthMatrix selectedCell] tag];
	[model setNs100width:i withValue:[sender intValue]];
}
			   
- (void) ns20widthAction:(id)sender
{
	int i = [[ns20widthMatrix selectedCell] tag];
	[model setNs20width:i withValue:[sender intValue]];
}
 
- (void) ns20delayAction:(id)sender
{
	int i = [[ns20delayMatrix selectedCell] tag];
	[model setNs20delay:i withValue:[sender intValue]];
}

- (void) tac0trimAction:(id)sender
{
	int i = [[tac0trimMatrix selectedCell] tag];
	[model setTac0trim:i withValue:[sender intValue]];
}
 	   
- (void) tac1trimAction:(id)sender
{
	int i = [[tac0trimMatrix selectedCell] tag];
	[model setTac1trim:i withValue:[sender intValue]];
}

@end
