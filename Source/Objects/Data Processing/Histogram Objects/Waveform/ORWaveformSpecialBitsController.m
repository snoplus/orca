//
//  ORWaveformSpecialBitsController.m
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
#import "ORMaskedWaveform.h"
#import "ORPlotView.h"
#import "ORBitStrip.h"
#import "ORWaveformSpecialBitsController.h"

@implementation ORWaveformSpecialBitsController

#pragma mark ¥¥¥Initialization
- (void) awakeFromNib
{
    [super awakeFromNib];
	
	int i;
	NSArray* bitNames = [(ORMaskedIndexedWaveformWithSpecialBits*)model bitNames];
	for(i=0;i<[model numBits];i++){
		ORBitStrip* aPlot = [[ORBitStrip alloc] initWithTag:1+i andDataSource:self];
		if(i<[bitNames count]) [aPlot setBitName:[bitNames objectAtIndex:i]];
		[aPlot setBitNum:i];
		[aPlot setLineColor:[NSColor blueColor]];
		[plotView addPlot: aPlot];
		[aPlot release];
	}
}

#pragma mark ¥¥¥Data Source
- (void) plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y
{
	if([aPlot tag] == 0){
		unsigned long aMask =  [(ORMaskedIndexedWaveformWithSpecialBits*)model mask];
		*y =  [model value:index] & aMask;
		*x = index;
	}
	else {
		int bit;
		for(bit=0;bit<[model numBits];bit++){
			if([aPlot tag] == bit+1){
				unsigned long aMask =  [model firstBitMask];
				unsigned long aValue = [model value:index];
				*y =  ((aValue & (aMask << bit)))!=0;
				*x = index;
				break;
			}
		}
	}
}
@end
