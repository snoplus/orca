//
//  ORWaveform.m
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

#import "ORWaveform.h"
#import "OR1dRoi.h"

NSString* ORWaveformUseUnsignedChanged   = @"ORWaveformUseUnsignedChanged";

@implementation ORWaveform

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [waveform release];
    waveform = nil;
 	[rois release];
	[super dealloc];
}

#pragma mark ¥¥¥Accessors
- (BOOL) useUnsignedValues
{
	return useUnsignedValues;
}

- (void) setUseUnsignedValues:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseUnsignedValues:useUnsignedValues];
    useUnsignedValues = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORWaveformUseUnsignedChanged object:self];
}

- (int) unitSize
{
	return unitSize;
}

- (void) setUnitSize:(int)aUnitSize
{
    if(aUnitSize==0)aUnitSize = 1;
	unitSize = aUnitSize;
}

- (unsigned long) dataOffset
{
	return dataOffset;
}

- (void) setDataOffset:(unsigned long)newOffset
{
	dataOffset=newOffset;
}

-(int) numberBins
{
    if(waveform){
		[dataSetLock lock];
		int temp;
		if(unitSize == 0)unitSize = 1;
		temp =  ([waveform length] - dataOffset)/unitSize;
		[dataSetLock unlock];
		return temp;
	}
    else return 64*1024;
}

-(long) value:(unsigned long)aChan
{
  return [self value:aChan callerLockedMe:false];
}

-(long) value:(unsigned long)aChan callerLockedMe:(BOOL)callerLockedMe
{
    if(!callerLockedMe) [dataSetLock lock];

    long theValue = 0;
	const char* cptr = (const char*)[waveform bytes];
	if(cptr){
		cptr += dataOffset;
			
		if( aChan < ([waveform length] - dataOffset)/unitSize){
			switch(unitSize){
				case 1:
					if(useUnsignedValues) theValue =  (unsigned long)((unsigned char*)cptr)[aChan];
					else				  theValue =  (long)cptr[aChan];
				break;

				case 2:
					{
						const short* sptr = (const short*)cptr;
						if(useUnsignedValues) theValue =  (unsigned long)((unsigned short*)sptr)[aChan];
						else				  theValue =  (long)sptr[aChan];
					}
				break;

				case 4:
					{
						const long* lptr = (const long*)cptr;
						if(useUnsignedValues) theValue =  (unsigned long)((unsigned long*)lptr)[aChan];
						else				  theValue =  lptr[aChan];
					}
				break;
			}
		}
		else theValue =  0;
	}

	if(!callerLockedMe) [dataSetLock unlock];
	return theValue;
}

- (double) getTrapezoidValue:(unsigned int)channel rampTime:(unsigned int)ramp gapTime:(unsigned int)gap
{
    // Average two regions of waveform, each of duration [ramp], separated
    // by a region of duration [gap], with the first region starting at
    // [channel], and return the difference divided by the ramp time.

    if(channel+2*ramp+gap >= [self numberBins]) return 0;

    [dataSetLock lock];
    double value = 0;
    unsigned int ch;
    for(ch = 0; ch < ramp; ch++) {
      value += [self value:(channel + ch + ramp + gap) callerLockedMe:true];
      value -= [self value:(channel + ch) callerLockedMe:true];
    }
    [dataSetLock unlock];

    return value / ramp;
}

#pragma mark ¥¥¥Data Management
- (void) clear
{
	[dataSetLock lock];
    [waveform release];
    waveform = nil;
	
    [self setTotalCounts:0];
	[dataSetLock unlock];
	
}

#pragma mark ¥¥¥Data Source Methods
- (id) name
{
    return [NSString stringWithFormat:@"%@ Waveform  Counts: %lu",[self key], [self totalCounts]];
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
    return [self numberBins];
}

- (unsigned long) startingByteOffset:(id)aPlotter  dataSet:(int)set
{
	return dataOffset;
}

- (unsigned short) unitSize:(id)aPlotter  dataSet:(int)set
{
	return unitSize;
}

- (void) setWaveform:(NSData*)aWaveform
{
	[dataSetLock lock];
	
	if(![self paused]){
		[aWaveform retain];
		[waveform release];
		waveform = aWaveform;
    }
	
    if(aWaveform)[self incrementTotalCounts];
	[dataSetLock unlock];

}

- (NSData*) rawData
{
	NSData* theRawData;
	[dataSetLock lock];
	theRawData =  [waveform retain];
	[dataSetLock unlock];
	return [theRawData autorelease];
}

- (BOOL) canJoinMultiPlot
{
    return YES;
}

#pragma  mark ¥¥¥Actions
- (void) makeMainController
{
    [self linkToController:@"ORWaveformController"];
}

#pragma mark ¥¥¥Archival
static NSString *ORWaveformDataOffset 	= @"Waveform Data Offset";
static NSString *ORWaveformUnitSize 	= @"Waveform Data Unit Size";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setDataOffset:[decoder decodeInt32ForKey:ORWaveformDataOffset]];
    [self setUnitSize:[decoder decodeInt32ForKey:ORWaveformUnitSize]];
    [self setUseUnsignedValues:[decoder decodeBoolForKey:@"UseUnsignedValues"]];
	rois = [[decoder decodeObjectForKey:@"rois"] retain];
    [[self undoManager] enableUndoRegistration];
	 
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt32:dataOffset forKey:ORWaveformDataOffset];
    [encoder encodeInt:unitSize forKey:ORWaveformUnitSize];
    [encoder encodeBool:useUnsignedValues forKey:@"UseUnsignedValues"];
    [encoder encodeObject:rois forKey:@"rois"];

}

#pragma mark ¥¥¥Data Source
- (NSMutableArray*) rois
{
	if(!rois){
		rois = [[NSMutableArray alloc] init];
		[rois addObject:[[[OR1dRoi alloc] initWithMin:20 max:30] autorelease]];
	}
	return rois;
}

- (int) numberPointsInPlot:(id)aPlot
{
	return [self numberBins];
}

- (void) plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y
{
	*y =  [self value:index];
	*x = index;
}

//subclasses will override these
- (unsigned long) mask
{
	return 0;
}
- (unsigned long) specialBitMask
{
	return 0;
}

@end

