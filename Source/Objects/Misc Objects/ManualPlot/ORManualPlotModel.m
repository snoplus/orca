//
//  ORManualPlotModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright ¬© 2002 CENPA, University of Washington. All rights reserved.
//

#pragma mark •••Imported Files
#import "ORManualPlotModel.h"

NSString* ORManualPlotLock						= @"ORManualPlotLock";
NSString* ORManualPlotDataChanged				= @"ORManualPlotDataChanged";

@implementation ORManualPlotModel

#pragma mark •••initialization
- (id) init 
{
    self = [super init];
    numberBins = 4096;
    overFlow = 0;
    histogram = nil;
	dataSetLock = [[NSLock alloc] init];
    return self;    
}

- (void) dealloc
{
	[dataSetLock release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(histogram)free(histogram);
    histogram = nil;
    [super dealloc];
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

- (void) setValue:(unsigned long)aValue channel:(unsigned short)aChan
{
	[dataSetLock lock];
    if(aChan<numberBins) histogram[aChan] = aValue;
	else overFlow++;
	[self scheduleUpdateOnMainThread];
	[dataSetLock unlock];
}

-(unsigned long) value:(unsigned short)aChan
{
    unsigned long theValue;
	[dataSetLock lock];
    if(aChan<numberBins)theValue = histogram[aChan];
    else theValue = 0;

	[dataSetLock unlock];
    return theValue;
}

- (void) scheduleUpdateOnMainThread
{
	if(!scheduledForUpdate){
		scheduledForUpdate = YES;
		[self performSelector:@selector(postUpdate) withObject:nil afterDelay:1.0];
	}
}

- (void) postUpdate
{
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORManualPlotDataChanged
					  object:self];    
	scheduledForUpdate = NO;
}

#pragma mark ***Accessors

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"ManualPlot"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORManualPlotController"];
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setNumberBins:[decoder decodeIntForKey:@"NumberBins"]];
		
    [[self undoManager] enableUndoRegistration];

	dataSetLock = [[NSLock alloc] init];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:numberBins forKey:@"NumberBins"];
}

-(void)clear
{
	[dataSetLock lock];
    memset(histogram,0,sizeof(unsigned long)*numberBins);
    overFlow = 0;
	[dataSetLock unlock];
}

#pragma mark •••Writing Data
- (void) writeDataToFile:(FILE*)aFile
{
//	[dataSetLock lock];
//    fprintf( aFile, "WAVES/I/N=(%d) '%s'\nBEGIN\n",numberBins,[shortName cStringUsingEncoding:NSASCIIStringEncoding]);
//    int i;
//    for (i=0; i<numberBins; ++i) {
//        fprintf(aFile, "%ld\n",histogram[i]);
//    }
//    fprintf(aFile, "END\n\n");
//	[dataSetLock unlock];
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
    return numberBins;
}

- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
    return [self value:x];
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

}

@end
