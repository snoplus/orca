//
//  OR1DHisto.m
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


#import "OR1DHisto.h"
#import "ORPlotter1D.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"

NSString* OR1DHisotRebinChanged			= @"OR1DHisotRebinChanged";
NSString* OR1DHisotRebinNumberChanged	= @"OR1DHisotRebinNumberChanged";


@implementation OR1DHisto

- (id) init 
{
    self = [super init];
    numberBins = 4096;
    overFlow = 0;
    histogram = nil;
    return self;    
}



- (void) dealloc
{
    if(histogram)free(histogram);
    histogram = nil;
    [super dealloc];
}


#pragma mark ¥¥¥Accessors
- (unsigned long) dataId
{
    return dataId;
}
- (void) setDataId: (unsigned long) aDataId
{
    dataId = aDataId;
}

- (BOOL)rebin
{
	return rebin;
}

- (void) setRebin:(BOOL)aFlag
{
	[[[self undoManager] prepareWithInvocationTarget:self] setRebin:rebin];
    
	rebin = aFlag;
	[[NSNotificationCenter defaultCenter]
		postNotificationName:OR1DHisotRebinChanged
                      object:self];
}

- (unsigned short) rebinNumber
{
	if(rebinNumber==0)rebinNumber = 1;
	return rebinNumber;
}

- (void) setRebinNumber:(unsigned int)avalue
{
	[[[self undoManager] prepareWithInvocationTarget:self] setRebinNumber:rebinNumber];
    
	if(avalue<1)avalue=1;
	rebinNumber = avalue;
    
	[[NSNotificationCenter defaultCenter]
		postNotificationName:OR1DHisotRebinNumberChanged
                      object:self];
}

-(void)setNumberBins:(int)aNumberBins
{
	[dataSetLock lock];
    if(histogram) {
        free(histogram);
        histogram = 0;
    }
    numberBins = aNumberBins;
    histogram = malloc(numberBins*sizeof(unsigned long));
    if(histogram)memset(histogram,0,numberBins*sizeof(unsigned long));
	[dataSetLock unlock];
}

-(int) numberBins
{
    return numberBins;
}

-(unsigned long) overFlow
{
    return overFlow;
}


-(unsigned long)value:(unsigned short)aChan
{
    unsigned long theValue;
	[dataSetLock lock];
	
	if(!rebin || rebinNumber == 0){
		if(aChan<numberBins)theValue = histogram[aChan];
		else theValue = 0;
	}
	else {
		int i;
		theValue =0;
		int start = aChan*rebinNumber;
		for(i=0;i<rebinNumber;i++){
			theValue += histogram[start+i];
		}
	}
	
	[dataSetLock unlock];
    return theValue;
}

#pragma mark ¥¥¥Data Management
-(void)clear
{
	[dataSetLock lock];
    memset(histogram,0,sizeof(unsigned long)*numberBins);
    overFlow = 0;
    [self setTotalCounts:0];
	[dataSetLock unlock];
}

#pragma mark ¥¥¥Writing Data
- (void) writeDataToFile:(FILE*)aFile
{
	[dataSetLock lock];
    fprintf( aFile, "WAVES/I/N=(%d) '%s'\nBEGIN\n",numberBins,[shortName cStringUsingEncoding:NSASCIIStringEncoding]);
    int i;
    for (i=0; i<numberBins; ++i) {
        fprintf(aFile, "%ld\n",histogram[i]);
    }
    fprintf(aFile, "END\n\n");
	[dataSetLock unlock];
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	if(rebin && rebinNumber>1)return numberBins/rebinNumber;
    else return numberBins;
}

- (NSString*) fullName
{
	if(rebin && rebinNumber>=2){
		return [NSString stringWithFormat:@"%@ (%d->1)",[super fullName],rebinNumber];
	}
	else return [super fullName];
}

- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
	if(!rebin || rebinNumber == 0){
		return [self value:x];
	}
	else {
		int i;
		long sum =0;
		int start = x*rebinNumber;
		for(i=0;i<rebinNumber;i++){
			sum += [self value:start+i];
		}
		return sum;
	}
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"OR1DHistoDecoder",                        @"decoder",
        [NSNumber numberWithLong:dataId],           @"dataId",
        [NSNumber numberWithBool:YES],              @"variable",
        [NSNumber numberWithLong:-1],               @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Histograms"];
    return dataDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"1DHisto"];

}

- (void) processResponse:(NSDictionary*)aResponse
{
	[dataSet processResponse:aResponse];
}

#pragma mark ¥¥¥Data Source Methods

- (id)   name
{
    return [NSString stringWithFormat:@"%@ 1D Histogram Events: %d",[self key], [self totalCounts]];
}


- (void) histogram:(unsigned long)aValue
{
    if(!histogram){
        [self setNumberBins:4096];
    }
	[dataSetLock lock];
    if(aValue>=numberBins){
        ++overFlow;
        ++histogram[numberBins-1];
    }
    else {
        ++histogram[aValue];
    }
	[dataSetLock unlock];
	[self incrementTotalCounts];

}

// ak, 6.8.07
- (void) histogramWW:(unsigned long)aValue weight:(unsigned long)aWeight
{
    if(!histogram){
        [self setNumberBins:4096];
    }
	[dataSetLock lock];
    if(aValue>=numberBins){
        overFlow += aWeight;
        histogram[numberBins-1] += aWeight;
    }
    else {
        histogram[aValue] += aWeight;
    }
	[dataSetLock unlock];
	[self incrementTotalCounts];

}

- (void) mergeHistogram:(unsigned long*)ptr numValues:(unsigned long)numBins
{
    if(!histogram || numberBins != numBins){
        [self setNumberBins:numBins];
    }
	[dataSetLock lock];
    int i;
    for(i=0;i<numBins;i++){
        histogram[i] += ptr[i];
    }
	[dataSetLock unlock];
    [self incrementTotalCounts];
}


- (void) packageData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo keys:(NSMutableArray*)aKeyArray
{
    NSMutableData* dataToShip = [NSMutableData data];
    unsigned long dataWord;
    
    //first the id
    dataWord = dataId; //note we don't know the length yet--we'll fill it in later
    [dataToShip appendBytes:&dataWord length:4];

    //append the keys
    NSString* allKeys = [aKeyArray componentsJoinedByString:@"/"];
    const char* p = [allKeys UTF8String];
    unsigned long allKeysLengthWithTerminator = strlen(p)+1;
    unsigned long paddedKeyLength = 4*((unsigned long)(allKeysLengthWithTerminator+4)/4);
    unsigned long paddedKeyLengthLong = paddedKeyLength/4;
    [dataToShip appendBytes:&paddedKeyLengthLong length:4];
    [dataToShip appendBytes:p length:allKeysLengthWithTerminator];

    //pad to the long word boundary
    int i;
    for(i=0;i< paddedKeyLength-allKeysLengthWithTerminator;i++){
        char null = '\0';
        [dataToShip appendBytes:&null length:1];
    }
    
    [dataToShip appendBytes:&numberBins length:4];            //length of the histogram
    [dataToShip appendBytes:histogram length:numberBins*4]; //note size in number bytes--not longs
    
    //go back and fill in the total length
    unsigned long *ptr = (unsigned long*)[dataToShip bytes];
    unsigned long totalLength = [dataToShip length]/4; //num of longs
    *ptr |= (kLongFormLengthMask & totalLength);
    [aDataPacket addData:dataToShip];
}

- (BOOL) canJoinMultiPlot
{
    return YES;
}

#pragma  mark ¥¥¥Actions
- (void) makeMainController
{
    [self linkToController:@"OR1DHistoController"];
}

#pragma mark ¥¥¥Archival
static NSString *OR1DHistoNumberBins	= @"1D Histogram Number Bins";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    
    [self setNumberBins:[decoder decodeIntForKey:OR1DHistoNumberBins]];
    
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:numberBins forKey:OR1DHistoNumberBins];
}


@end
