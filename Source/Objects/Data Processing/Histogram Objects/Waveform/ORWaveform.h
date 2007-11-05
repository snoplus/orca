//
//  ORWaveform.h
//  Orca
//
//  Created by Mark Howe on Sun Nov 17 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORDataSetModel.h"

#pragma mark ¥¥¥Forward Declarations
@class ORChannelData;
@class ORWaveformController;
@class ORPlotter;
@class OR1DHisto;

@interface ORWaveform : ORDataSetModel  {
    NSData* 		waveform;
    unsigned long   dataOffset;
	int				unitSize;
	NSRecursiveLock*	dataLock;
    int				baselineValue;
    BOOL			integrate;
	OR1DHisto*		integratedWaveform;
	BOOL			useUnsignedValues;
}

#pragma mark ¥¥¥Accessors 
- (BOOL) integrate;
- (void) setIntegrate:(BOOL)aIntegrate;
- (int) baselineValue;
- (void) setBaselineValue:(int)aBaselineValue;
- (int) unitSize;
- (void) setUnitSize:(int)aUnitSize;
- (unsigned long) dataOffset;
- (void) setDataOffset:(unsigned long)newOffset;
- (int) numberBins;
- (long) value:(unsigned short)channel;
- (void) setWaveform:(NSData*)aWaveform;
- (BOOL) useUnsignedValues;
- (void) setUseUnsignedValues:(BOOL)aState;

#pragma mark ¥¥¥Data Management
- (void) clear;
- (void) incrementTotalCounts;
- (long) integrateWaveform:(int) aBaseLine;
- (void) clearIntegration;

#pragma mark ¥¥¥Data Source Methods
- (id)   name;
- (long) integratedValue:(unsigned short)aChan;
- (BOOL) useDataObject:(id)aPlotter  dataSet:(int)set;
- (unsigned long) startingByteOffset:(id)aPlotter  dataSet:(int)set;
- (unsigned short) unitSize:(id)aPlotter  dataSet:(int)set;
- (NSData*) plotter:(id) aPlotter dataSet:(int)set;

@end

extern NSString* ORWaveformIntegrateChanged;
extern NSString* ORWaveformBaselineValueChanged;
extern NSString* ORWaveformUseUnsignedChanged;

