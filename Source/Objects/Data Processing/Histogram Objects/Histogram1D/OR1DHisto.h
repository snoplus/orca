//
//  OR1DHisto.h
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
@class OR1DHistoController;

@interface OR1DHisto : ORDataSetModel  {
    unsigned long dataId;
    unsigned long 	overFlow;
    unsigned int 	numberBins;
    unsigned long* 	histogram;
    unsigned long* 	pausedHistogram;
	BOOL			rebin;
	unsigned int	rebinNumber;
}


#pragma mark ¥¥¥Accessors
- (BOOL)rebin;
- (void) setRebin:(BOOL)aFlag;
- (unsigned short) rebinNumber;
- (void) setRebinNumber:(unsigned int)avalue;
- (void) processResponse:(NSDictionary*)aResponse;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void)setNumberBins:(int)aNumberBins;
- (int) numberBins;
- (unsigned long)value:(unsigned short)aBin;
- (unsigned long) overFlow;

#pragma mark ¥¥¥Data Management
- (void) histogram:(unsigned long)aValue;
- (void) histogramWW:(unsigned long)aValue weight:(unsigned long) weight; // ak 6.8.07
- (void) loadData:(NSData*)someData;
- (void) mergeHistogram:(unsigned long*)ptr numValues:(unsigned long)numBins;
- (void) mergeEnergyHistogram:(unsigned long*)ptr numBins:(unsigned long)numBins maxBins:(unsigned long)maxBins
                                                 firstBin:(unsigned long)firstBin   stepSize:(unsigned long)stepSize 
                                                   counts:(unsigned long)counts;
- (void) clear;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;

#pragma mark ¥¥¥Writing Data
- (void) writeDataToFile:(FILE*)aFile;
- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo keys:(NSMutableArray*)aKeyArray;

#pragma mark ¥¥¥Data Source Methods
- (id)   name;
- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x;
@end

extern NSString* OR1DHisotRebinChanged;
extern NSString* OR1DHisotRebinNumberChanged;

