//
//  ORWaveformController.h
//  Orca
//
//  Created by Mark Howe on Mon Jan 06 2003.
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
#import "ORDataController.h"

@class ORPlotter1D;

@interface ORWaveformController : ORDataController {
	IBOutlet NSButton*		useUnsignedValuesButton;
	IBOutlet NSButton*		differentiateButton;
	IBOutlet NSTextField*	differentiateText;
	IBOutlet NSTextField*	integratingText;
	IBOutlet NSTextField*	averageWindowField;
	IBOutlet NSButton*		integrateButton;
	IBOutlet NSTextField*	baselineValueField;
}

- (id)init;
- (void) awakeFromNib;

- (void) differentiateChanged:(NSNotification*)aNote;
- (void) averageWindowChanged:(NSNotification*)aNote;
- (void) integrateChanged:(NSNotification*)aNote;
- (void) baselineValueChanged:(NSNotification*)aNote;
- (void) useUnsignedValuesChanged:(NSNotification*)aNote;

- (IBAction) useUnsignedValuesAction:(id)sender;
- (IBAction) differentiateAction:(id)sender;
- (IBAction) averageWindowAction:(id)sender;
- (IBAction) integrateAction:(id)sender;
- (IBAction) baselineValueAction:(id)sender;

#pragma mark ¥¥¥Data Source
- (BOOL) useUnsignedValues;
- (BOOL) useDataObject:(id)aPlotter  dataSet:(int)set;
- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (float) plotter:(id) aPlotter  dataSet:(int)set dataValue:(int) x;

@end
