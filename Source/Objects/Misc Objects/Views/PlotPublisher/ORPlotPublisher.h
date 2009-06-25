//  ORPlotPublisher.h
//  Orca
//
//  Created by Mark Howe on June 25, 2009.
//  Copyright 2009 UNC. All rights reserved.
//
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

@class ORPlotter;

@interface ORPlotPublisher : NSWindowController 
{
	IBOutlet NSButton*		cancelButton;
	IBOutlet NSButton*		applyButton;
	
	ORPlotter*				plotter;
	NSMutableDictionary*    oldAttributes;
}

+ (void) publishPlot:(id)aPlot;

- (id) initWithPlot:(id)aPlot;
- (void) beginSheet;
- (void) publishPlot;

- (IBAction) publish:(id)sender;
- (IBAction) cancel:(id)sender;
@end


@interface NSObject (ORPlotPublisher)
- (NSView*) viewForPDF;
- (NSMutableDictionary*) attributes;
- (void)setAttributes:(NSMutableDictionary *)anAttributes;
@end
