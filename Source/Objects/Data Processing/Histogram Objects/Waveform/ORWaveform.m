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
#import "OR1DHisto.h"


NSString* ORWaveformIntegrateChanged	 = @"ORWaveformIntegrateChanged";
NSString* ORWaveformBaselineValueChanged = @"ORWaveformBaselineValueChanged";
NSString* ORWaveformUseUnsignedChanged   = @"ORWaveformUseUnsignedChanged";

@implementation ORWaveform

- (id) init
{
    self = [super init];
	dataLock = [[NSRecursiveLock alloc] init];
    return self;
}

- (void) dealloc
{
	[integratedWaveform release];
	[dataLock release];
    [waveform release];
    waveform = nil;
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

- (BOOL) integrate
{
    return integrate;
}

- (void) setIntegrate:(BOOL)aIntegrate
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIntegrate:integrate];
		
    integrate = aIntegrate;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORWaveformIntegrateChanged object:self];
}

- (void) clearIntegration
{
	[integratedWaveform release];
	integratedWaveform = nil;
}

- (int) baselineValue
{
    return baselineValue;
}

- (void) setBaselineValue:(int)aBaselineValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBaselineValue:baselineValue];
    
    baselineValue = aBaselineValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORWaveformBaselineValueChanged object:self];
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
		[dataLock lock];
		int temp;
		if(unitSize == 0)unitSize = 1;
		temp =  ([waveform length] - dataOffset)/unitSize;
		[dataLock unlock];
		return temp;
	}
    else return 1;
}

- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
    return [self value:x];
}
    
-(long) value:(unsigned short)aChan
{
	[dataLock lock];

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
						else				  theValue =  (long)lptr[aChan];
					}
				break;
			}
		}
		else theValue =  0;
	}

	[dataLock unlock];
	return theValue;
}

- (long) integratedValue:(unsigned short)aChan
{
	return [integratedWaveform value:aChan];
}

#pragma mark ¥¥¥Data Management
-(void)clear
{
	[dataLock lock];
    [waveform release];
    waveform = nil;
	
	[self clearIntegration];

    [self setTotalCounts:0];
	[dataLock unlock];
	
}

- (void) incrementTotalCounts
{
	[super incrementTotalCounts];
	if(integrate && ![self paused]){
		if(!integratedWaveform){
			integratedWaveform = [[OR1DHisto alloc] init];
			[integratedWaveform setNumberBins:65536];
		}
		[integratedWaveform histogram:[self integrateWaveform:baselineValue]];
	}
}

- (long) integrateWaveform:(int) aBaseLine
{
	int i;
	int n = [self numberBins];
	long theValue = 0;
	for(i=0;i<n;i++){
		long dataPoint = [self value:i];
		if(dataPoint > aBaseLine){
			theValue += dataPoint - aBaseLine;
		}
	}
	return theValue;
}

#pragma mark ¥¥¥Data Source Methods

- (id)   name
{
    return [NSString stringWithFormat:@"%@ Waveform  Counts: %d",[self key], [self totalCounts]];
}

- (BOOL) useDataObject:(id)aPlotter  dataSet:(int)set
{
	return YES;
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
- (NSData*) plotter:(id) aPlotter dataSet:(int)set
{
	NSData* temp;
	[dataLock lock];
	[[waveform retain] autorelease];
	temp = waveform;
	[dataLock unlock];
	return temp;
}


- (void) setWaveform:(NSData*)aWaveform
{
	[dataLock lock];
	
	if(![self paused]){
		[aWaveform retain];
		[waveform release];
		waveform = aWaveform;
    }
	
    if(aWaveform)[self incrementTotalCounts];
	[dataLock unlock];

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
    [self setIntegrate:[decoder decodeBoolForKey:@"ORWaveformIntegrate"]];
    [self setBaselineValue:[decoder decodeIntForKey:@"ORWaveformBaselineValue"]];
    [self setDataOffset:[decoder decodeInt32ForKey:ORWaveformDataOffset]];
    [self setUnitSize:[decoder decodeInt32ForKey:ORWaveformUnitSize]];
    [self setUseUnsignedValues:[decoder decodeBoolForKey:@"UseUnsignedValues"]];
    [[self undoManager] enableUndoRegistration];
	
	dataLock = [[NSRecursiveLock alloc] init];
 
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:integrate forKey:@"ORWaveformIntegrate"];
    [encoder encodeInt:baselineValue forKey:@"ORWaveformBaselineValue"];
    [encoder encodeInt32:dataOffset forKey:ORWaveformDataOffset];
    [encoder encodeInt:unitSize forKey:ORWaveformUnitSize];
    [encoder encodeBool:useUnsignedValues forKey:@"UseUnsignedValues"];

}


@end

