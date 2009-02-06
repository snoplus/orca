//
//  OR2DHisto.m
//  Orca
//
//  Created by Mark Howe on Thurs Dec 23 2004.
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


#import "OR2DHisto.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"
#import <math.h>
@implementation OR2DHisto

- (id) init 
{
    self = [super init];
    numberBinsPerSide = 512;
    histogram = nil;
    return self;    
}



- (void) dealloc
{
    [self freeHistogram];
    [super dealloc];
}

- (void) freeHistogram
{
    if(histogram) {
        free(histogram);
        histogram = 0;
    }
}

#pragma mark ¥¥¥Accessors

- (void) setKey:(NSString*)aKey
{
    [key autorelease];
    key = [aKey copy];
}

- (NSString*)key
{
    return key;
}


-(unsigned short) numberBinsPerSide
{
    return numberBinsPerSide;
}

- (void) setNumberBinsPerSide:(unsigned short)bins
{
	[dataSetLock lock];
    numberBinsPerSide = bins;
    [self freeHistogram];
    histogram = (unsigned long*)malloc(numberBinsPerSide*numberBinsPerSide*sizeof(unsigned long));
	[dataSetLock unlock];
    [self clear];
}

- (unsigned long)valueX:(unsigned short)aXBin y:(unsigned short)aYBin
{
	unsigned long theResult = 0;
	[dataSetLock lock];
    aXBin = aXBin % numberBinsPerSide;   // Error Check Our x Value
    aYBin = aYBin % numberBinsPerSide;   // Error Check Our y Value
    theResult =  histogram[aXBin + aYBin*numberBinsPerSide];
	[dataSetLock unlock];
	return theResult;
}
- (unsigned long) dataId
{
    return dataId;
}
- (void) setDataId: (unsigned long) aDataId
{
    dataId = aDataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

#pragma mark ¥¥¥Data Management
- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"OR2DHistoDecoder",                        @"decoder",
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
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"2DHisto"];

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
	if(allKeys && ![allKeys hasPrefix:@"Final"]){
		allKeys = [@"Final/" stringByAppendingString:allKeys];
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
		
		[dataSetLock lock];
		unsigned long theSize = numberBinsPerSide*numberBinsPerSide;
		[dataToShip appendBytes:&theSize length:4];            //length of the histogram
		[dataToShip appendBytes:histogram length:theSize*4]; //note size in number bytes--not longs
		[dataSetLock unlock];
		
		//go back and fill in the total length
		unsigned long *ptr = (unsigned long*)[dataToShip bytes];
		unsigned long totalLength = [dataToShip length]/4; //num of longs
		*ptr |= (kLongFormLengthMask & totalLength);
		[aDataPacket addData:dataToShip];
	}
}

-(void)clear
{
	[dataSetLock lock];
    if(histogram){
        memset(histogram,0,numberBinsPerSide*numberBinsPerSide*sizeof(long));
    }
    minX = numberBinsPerSide;
    maxX = 0;
    minY = numberBinsPerSide;
    maxY = 0;
	[dataSetLock unlock];
    
    [self setTotalCounts:0];
}

#pragma mark ¥¥¥Writing Data
- (void) writeDataToFile:(FILE*)aFile
{
    //not implemented yet....
/*    fprintf( aFile, "WAVES/I/N=(%d) '%s'\nBEGIN\n",numberBins,[shortName cStringUsingEncoding:NSASCIIStringEncoding]);
    int i;
    for (i=0; i<numberBins; ++i) {
        fprintf(aFile, "%ld\n",histogram[i]);
    }
    fprintf(aFile, "END\n\n");
*/
}


#pragma mark ¥¥¥Data Source Methods
- (unsigned long*) getDataSetAndNumBinsPerSize:(unsigned short*)value
{
    *value = numberBinsPerSide;
    return histogram;
    
}

- (void) getXMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY
{
    *aMinX = minX;
    *aMaxX = maxX;
    *aMinY = minY;
    *aMaxY = maxY;
}

- (id)   name
{
    return [NSString stringWithFormat:@"%@ 2D Histogram Events: %d",key, [self totalCounts]];
}

- (void) mergeHistogram:(unsigned long*)ptr numValues:(unsigned long)num
{
    if(!histogram || (numberBinsPerSide*numberBinsPerSide) != num){
        [self setNumberBinsPerSide:(unsigned short)pow((double)num,.5)];
    }
	[dataSetLock lock];
    int i;
    for(i=0;i<num;i++){
        histogram[i] += ptr[i];
        if(histogram[i]){
            unsigned short y = i/numberBinsPerSide;
            unsigned short x = i%numberBinsPerSide;
            
            if(x<minX)minX = x;
            if(x>maxX)maxX = x;
            if(y<minY)minY = y;
            if(y>maxY)maxY = y;
        }
    }
	[dataSetLock unlock];
    [self incrementTotalCounts];
}

- (void) load:(unsigned long*)ptr numValues:(unsigned long)num
{
    if(!histogram || (numberBinsPerSide*numberBinsPerSide) != num){
        [self setNumberBinsPerSide:(unsigned short)pow((double)num,.5)];
    }
	[dataSetLock lock];
    int i;
    for(i=0;i<num;i++){
        histogram[i] = ptr[i];
        if(histogram[i]){
            unsigned short y = i/numberBinsPerSide;
            unsigned short x = i%numberBinsPerSide;
            
            if(x<minX)minX = x;
            if(x>maxX)maxX = x;
            if(y<minY)minY = y;
            if(y>maxY)maxY = y;
        }
    }
	[dataSetLock unlock];
    [self incrementTotalCounts];
}


- (void) histogramX:(unsigned short)aXValue y:(unsigned short)aYValue;
{
    if(!histogram){
        [self setNumberBinsPerSide:512]; //default
    }
	[dataSetLock lock];
    if(aXValue >= numberBinsPerSide) aXValue = numberBinsPerSide-1;
    if(aYValue >= numberBinsPerSide) aYValue = numberBinsPerSide-1;
    //aXValue = aXValue % numberBinsPerSide;   // Error Check Our x Value
    //aYValue = aYValue % numberBinsPerSide;   // Error Check Our y Value
    ++histogram[aXValue+aYValue*numberBinsPerSide];
    [self incrementTotalCounts];
    if(aXValue<minX)minX = aXValue;
    if(aXValue>maxX)maxX = aXValue;
    if(aYValue<minY)minY = aYValue;
    if(aYValue>maxY)maxY = aYValue;
	[dataSetLock unlock];
    
}
- (void) loadX:(unsigned short)aXValue y:(unsigned short)aYValue z:(unsigned short)aZValue
{
    if(!histogram){
        [self setNumberBinsPerSide:512]; //default
    }
	[dataSetLock lock];
    if(aXValue >= numberBinsPerSide) aXValue = numberBinsPerSide-1;
    if(aYValue >= numberBinsPerSide) aYValue = numberBinsPerSide-1;
    //aXValue = aXValue % numberBinsPerSide;   // Error Check Our x Value
    //aYValue = aYValue % numberBinsPerSide;   // Error Check Our y Value
    histogram[aXValue+aYValue*numberBinsPerSide] = aZValue;
    [self incrementTotalCounts];
    if(aXValue<minX)minX = aXValue;
    if(aXValue>maxX)maxX = aXValue;
    if(aYValue<minY)minY = aYValue;
    if(aYValue>maxY)maxY = aYValue;
	[dataSetLock unlock];
    
}


#pragma  mark ¥¥¥Actions
- (void) makeMainController
{
    [self linkToController:@"OR2DHistoController"];
}

#pragma mark ¥¥¥Archival
static NSString *OR2DHistoNumberXBins	= @"OR2DHistoNumberXBins";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    
    [self setNumberBinsPerSide:[decoder decodeIntForKey:OR2DHistoNumberXBins]];
    
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:numberBinsPerSide forKey:OR2DHistoNumberXBins];
}


@end
