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
#import "ORFec32Model.h"

#pragma mark •••Definitions

@implementation ORFecDaughterCardController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"FecDaughterCard"];
    
    return self;
}

- (void) dealloc
{
	[valueFormatter release];
	[super dealloc];
}

- (void) awakeFromNib
{
	valueFormatter = [[NSNumberFormatter alloc] init];
	int i;
	for(i=0;i<2;i++){
		[[rp1Matrix cellWithTag:i] setFormatter:valueFormatter];
		[[rp2Matrix cellWithTag:i] setFormatter:valueFormatter];
		[[vliMatrix cellWithTag:i] setFormatter:valueFormatter];
		[[vsiMatrix cellWithTag:i] setFormatter:valueFormatter];
	}
	for(i=0;i<8;i++){
		[[vtMatrix cellWithTag:i] setFormatter:valueFormatter];
	}
	for(i=0;i<16;i++){
		[[vbMatrix cellWithTag:i] setFormatter:valueFormatter];
	}
	[super awakeFromNib];
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
						 name : ORDCModelRp1Changed
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(rp2Changed:)
						 name : ORDCModelRp2Changed
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(vliChanged:)
						 name : ORDCModelVliChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(vsiChanged:)
						 name : ORDCModelVsiChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(vtChanged:)
						 name : ORDCModelVtChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(vbChanged:)
						 name : ORDCModelVbChanged
					   object : model];
					   					   
    [notifyCenter addObserver : self
					 selector : @selector(ns100widthChanged:)
						 name : ORDCModelNs100widthChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(ns20widthChanged:)
						 name : ORDCModelNs20widthChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(ns20delayChanged:)
						 name : ORDCModelNs20delayChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(tac0trimChanged:)
						 name : ORDCModelTac0trimChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(tac1trimChanged:)
						 name : ORDCModelTac1trimChanged
					   object : model];					      
 
     [notifyCenter addObserver : self
					 selector : @selector(cmosRegShownChanged:)
						 name : ORDCModelCmosRegShownChanged
					   object : model];					      

      [notifyCenter addObserver : self
					 selector : @selector(setAllCmosChanged:)
						 name : ORDCModelSetAllCmosChanged
					   object : model];		
					   			      
      [notifyCenter addObserver : self
					 selector : @selector(showVoltsChanged:)
						 name : ORDCModelShowVoltsChanged
					   object : model];	
					   				      
    [notifyCenter addObserver : self
                     selector : @selector(commentsChanged:)
                         name : ORDCModelCommentsChanged
						object: model];

}

#pragma mark •••Interface Management
-(void)updateWindow
{
	[super updateWindow];
	[self showVoltsChanged:nil];
	[self slotChanged:nil];
	[self rp1Changed:nil];
	[self rp2Changed:nil];
	[self vliChanged:nil];
	[self vsiChanged:nil];
	[self vtChanged:nil];
	[self vbChanged:nil];	   
	[self setAllCmosChanged:nil];	   
	[self commentsChanged:nil];

	[self cmosRegShownChanged:nil];
}

- (void) setModel:(OrcaObject*)aModel
{
    [super setModel:aModel];
	[dcNumberField setIntValue:[model slot]];
	[fecNumberField setIntValue:[[model guardian] stationNumber]];
	[crateNumberField setIntValue:[[[model guardian] guardian] crateNumber]];
}

- (void) showVoltsChanged:(NSNotification*)aNote
{
	[showVoltsCB setIntValue: [model showVolts]];
	if([model showVolts])	[valueFormatter setFormat:@"#0.00;0;-#0.00"];
	else					[valueFormatter setFormat:@"#0;0;-#0"];
	[self rp1Changed:nil];
	[self rp2Changed:nil];
	[self vliChanged:nil];
	[self vsiChanged:nil];
	[self vtChanged:nil];
	[self vbChanged:nil];	   
}

- (void) commentsChanged:(NSNotification*)aNote
{
	[commentsTextField setStringValue: [model comments]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"FecDaughterCard (%d,%d,%d)",[[[model guardian] guardian] crateNumber],[[model guardian] stationNumber],[model slot]]];
	[dcNumberField setIntValue:[model slot]];
	[fecNumberField setIntValue:[[model guardian] stationNumber]];
	[crateNumberField setIntValue:[[[model guardian] guardian] crateNumber]];
}

- (void) setAllCmosChanged:(NSNotification*)aNote
{
	[setAllCmosButton setIntValue:[model setAllCmos]];
}

- (void) cmosRegShownChanged:(NSNotification*)aNote 
{
	[cmosRegShownField setIntValue:[model cmosRegShown]];
	[cmosRegShownField1 setIntValue:[model cmosRegShown]];
	[self ns20widthChanged:nil];
	[self ns20delayChanged:nil];
	[self ns100widthChanged:nil];
	[self tac0trimChanged:nil];		   
	[self tac1trimChanged:nil];
}

- (void) rp1Changed:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<2;i++) {
		if([model showVolts])[[rp1Matrix cellWithTag:i] setFloatValue:[model rp1Voltage:i]];
		else				 [[rp1Matrix cellWithTag:i] setIntValue:[model rp1:i]];
	}
}

- (void) rp2Changed:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<2;i++){
		if([model showVolts])	[[rp2Matrix cellWithTag:i] setFloatValue:[model rp2Voltage:i]];
		else					[[rp2Matrix cellWithTag:i] setIntValue:[model rp2:i]];
	}
}

- (void) vliChanged:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<2;i++){
		if([model showVolts])	[[vliMatrix cellWithTag:i] setFloatValue:[model vliVoltage:i]];
		else					[[vliMatrix cellWithTag:i] setIntValue:[model vli:i]];
	}
}

- (void) vsiChanged:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<2;i++){
		if([model showVolts])	[[vsiMatrix cellWithTag:i] setFloatValue:[model vsiVoltage:i]];
		else					[[vsiMatrix cellWithTag:i] setIntValue:[model vsi:i]];
	}
}

- (void) vtChanged:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<8;i++){
		if([model showVolts])	[[vtMatrix cellWithTag:i] setFloatValue:[model vtVoltage:i]];
		else					[[vtMatrix cellWithTag:i] setIntValue:[model vt:i]];
	}
}

- (void) vbChanged:(NSNotification*)aNote 
{
	int i;
	for(i=0;i<16;i++) {
		if([model showVolts])	[[vbMatrix cellWithTag:i] setFloatValue:[model vbVoltage:i]];
		else					[[vbMatrix cellWithTag:i] setIntValue:[model vb:i]];
	}
}
	   
- (void) ns100widthChanged:(NSNotification*)aNote 
{
	int i = [model cmosRegShown];
	[ns100widthField setIntValue:[model ns100width:i]];
}
			   
- (void) ns20widthChanged:(NSNotification*)aNote 
{
	int i = [model cmosRegShown];
	[ns20widthField setIntValue:[model ns20width:i]];
} 
  
- (void) ns20delayChanged:(NSNotification*)aNote 
{
	int i = [model cmosRegShown];
	[ns20delayField setIntValue:[model ns20delay:i]];
}
			   
- (void) tac0trimChanged:(NSNotification*)aNote 
{
	int i = [model cmosRegShown];
	[tac0trimField setIntValue:[model tac0trim:i]];
}
		   
- (void) tac1trimChanged:(NSNotification*)aNote 
{
	int i = [model cmosRegShown];
	[tac1trimField setIntValue:[model tac1trim:i]];
}

#pragma mark •••Actions
- (IBAction) commentsTextFieldAction:(id)sender
{
	[model setComments:[sender stringValue]];	
}

- (void) showVoltsAction:(id)sender
{
	[model setShowVolts:[sender intValue]];	
}

- (IBAction) setAllCmosAction:(id)sender
{
	[model setSetAllCmos:[sender intValue]];
}

- (IBAction) incCmosRegAction:(id)sender
{
	[self endEditing];
	[model setCmosRegShown:[model cmosRegShown]+1];
}

- (IBAction) decCmosRegAction:(id)sender
{
	[self endEditing];
	[model setCmosRegShown:[model cmosRegShown]-1];
}

- (IBAction) incCardAction:(id)sender
{
	[self incModelSortedBy:@selector(globalCardNumberCompare:)];
}

- (IBAction) decCardAction:(id)sender
{
	[self decModelSortedBy:@selector(globalCardNumberCompare:)];
}

- (IBAction) rp1Action:(id)sender
{
	int i = [[rp1Matrix selectedCell] tag];
	if([model showVolts])	[model setRp1Voltage:i withValue:[sender floatValue]];
	else					[model setRp1:i withValue:[sender intValue]];
}

- (IBAction) rp2Action:(id)sender
{
	int i = [[rp2Matrix selectedCell] tag];
	if([model showVolts])	[model setRp2Voltage:i withValue:[sender floatValue]];
	else					[model setRp2:i withValue:[sender intValue]];
}
 
- (IBAction) vliAction:(id)sender
{
	int i = [[vliMatrix selectedCell] tag];
	if([model showVolts])	[model setVliVoltage:i withValue:[sender floatValue]];
	else					[model setVli:i withValue:[sender intValue]];
}
 
- (IBAction) vsiAction:(id)sender
{
	int i = [[vsiMatrix selectedCell] tag];
	if([model showVolts])	[model setVsiVoltage:i withValue:[sender floatValue]];
	else					[model setVsi:i withValue:[sender intValue]];
}
 
- (IBAction) vtAction:(id)sender
{
	int i = [[vtMatrix selectedCell] tag];
	if([model showVolts])	[model setVtVoltage:i withValue:[sender floatValue]];
	else					[model setVt:i withValue:[sender intValue]];
}
 
- (IBAction) vbAction:(id)sender
{
	int i = [[vbMatrix selectedCell] tag];
	if([model showVolts])	[model setVbVoltage:i withValue:[sender floatValue]];
	else					[model setVb:i withValue:[sender intValue]];
} 
	   
- (IBAction) ns100widthAction:(id)sender
{
	int theValue = [sender intValue];
	if([model setAllCmos]) {
		int i;
		for(i=0;i<8;i++){
			[model setNs100width:i withValue:theValue];
		}
	}
	else [model setNs100width:[model cmosRegShown] withValue:theValue];
}
			   
- (IBAction) ns20widthAction:(id)sender
{
	int theValue = [sender intValue];
	if([model setAllCmos]) {
		int i;
		for(i=0;i<8;i++){
			[model setNs20width:i withValue:theValue];
		}
	}
	else [model setNs20width:[model cmosRegShown] withValue:theValue];
}
 
- (IBAction) ns20delayAction:(id)sender
{
	int theValue = [sender intValue];
	if([model setAllCmos]) {
		int i;
		for(i=0;i<8;i++){
			[model setNs20delay:i withValue:theValue];
		}
	}
	else [model setNs20delay:[model cmosRegShown] withValue:theValue];
}

- (IBAction) tac0trimAction:(id)sender
{
	int theValue = [sender intValue];
	if([model setAllCmos]) {
		int i;
		for(i=0;i<8;i++){
			[model setTac0trim:i withValue:theValue];
		}
	}
	else [model setTac0trim:[model cmosRegShown] withValue:theValue];
}
 	   
- (IBAction) tac1trimAction:(id)sender
{
	int theValue = [sender intValue];
	if([model setAllCmos]) {
		int i;
		for(i=0;i<8;i++){
			[model setTac1trim:i withValue:theValue];
		}
	}
	else [model setTac1trim:[model cmosRegShown] withValue:theValue];
}

@end
