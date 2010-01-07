//
//  ORCurve1D.m
//  testplot
//
//  Created by Mark Howe on Mon May 17 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORCurve1D.h"
#import "ORGate1D.h"
#import "ORPlotter1D.h"
#import "ORTimeLine.h"
#import "ORCalibration.h"

NSString* ORPlotter1DMousePosition = @"ORPlotter1DMousePosition";
NSString* ORCurve1DActiveGateChanged = @"ORCurve1DActiveGateChanged";

@implementation ORCurve1D
+(id) curve:(int)aDataSetID
{
    return [[[ORCurve1D alloc] initWithCurve:aDataSetID] autorelease];
}

- (id) initWithCurve:(int)aDataSetID
{
    self = [super init];
    dataSetID = aDataSetID;
    [self setDefaults];
    return self;    
}

- (id) init
{
    return [self initWithCurve:0];
}

-(void)dealloc
{
    [attributes release];
    [gates release];
    [super dealloc];
}

- (void) setDefaults
{
    [self setAttributes:[NSMutableDictionary dictionary]];
}
- (int) dataSetID
{
    return dataSetID;
}

- (void)setDataSetID:(int)aDataSetID {
    dataSetID = aDataSetID;
}

- (id) activeGate
{
    return [gates objectAtIndex:activeGateIndex];
}

- (int)activeGateIndex 
{
    return activeGateIndex;
}

- (void)setActiveGateIndex:(int)anactiveGateIndex 
{
    activeGateIndex = anactiveGateIndex;
	[[NSNotificationCenter defaultCenter]
        postNotificationName:ORCurve1DActiveGateChanged
                      object: [gates objectAtIndex:activeGateIndex] 
                    userInfo: nil];

}

- (int) gateCount
{
    return [gates count];
}
- (BOOL) incGate
{
    BOOL rollOver = NO;
    int index = activeGateIndex+1;
    if(index>=[gates count]){
		index = 0;
		rollOver = YES;
    }
	[self setActiveGateIndex:index];
    return rollOver;
}

- (BOOL) decGate
{
    BOOL rollOver = NO;
    int index = activeGateIndex-1;
    if(index<0){
		index = [gates count]-1;
		rollOver = YES;
    }
	[self setActiveGateIndex:index];
    return rollOver;
}

- (void) adjustAnalysisPanels
{
	[gates makeObjectsPerformSelector:@selector(adjustAnalysisPanels)];
}


- (NSMutableDictionary *)attributes 
{
    return attributes; 
}

- (void)setAttributes:(NSMutableDictionary *)anAttributes 
{
    [anAttributes retain];
    [attributes release];
    attributes = anAttributes;
}


- (NSArray*) gates
{
    return gates;
}

- (void) setGates:(NSMutableArray*)anArray
{
    [anArray retain];
    [gates release];
    gates = anArray;
}

- (void) addGate:(ORGate1D*)aGate
{
    if(!gates)[self setGates:[NSMutableArray array]];
    [gates addObject:aGate];
    [self setActiveGateIndex:[gates indexOfObject:aGate]];
    [gates makeObjectsPerformSelector:@selector(postNewGateID) withObject:nil];
}

- (void) removeActiveGate
{
    if([gates count]>1){
		[gates removeObject:[self activeGate]];
		if(activeGateIndex>=[gates count])activeGateIndex=0;
		[self setActiveGateIndex:activeGateIndex];
		[gates makeObjectsPerformSelector:@selector(postNewGateID) withObject:nil];
    }
}

- (void) clearActiveGate
{
    [[self activeGate] setGateValid:NO];
	showActiveGate = NO;
}

- (void) clearAllGates
{
    [gates makeObjectsPerformSelector:@selector(clearGate) withObject:nil];
	showActiveGate = NO;
}

- (int) gateNumber:(ORGate1D*)aGate
{
    return [gates indexOfObject:aGate];
}

- (void) drawDataInPlot:(ORPlotter1D*)aPlot
{
	if([[aPlot dataSource] useXYPlot])[self drawXYPlot:aPlot];
	else if([[aPlot dataSource] useXYTimePlot])[self drawXYTimePlot:aPlot];
	else [self drawSequencialPlot:aPlot];
	if(showActiveGate) [self drawFit:aPlot];

}

- (void) drawSequencialPlot:(ORPlotter1D*)aPlot
{
	id mDataSource = [aPlot dataSource];
	ORAxis*    mXScale = [aPlot xScale];
	ORAxis*    mYScale = [aPlot yScale];

	if(showActiveGate){
        [gates makeObjectsPerformSelector:@selector(drawGateInPlot:) withObject:aPlot];
    }
	
	int numPoints = [mDataSource numberOfPointsInPlot:aPlot dataSet:dataSetID];
    if(numPoints == 0) return;

    int width = [aPlot bounds].size.width - 1;
    
    [NSBezierPath setDefaultLineWidth:.2];
	
	BOOL differentiate		= [aPlot differentiate];
	double averageWindow	= [aPlot averageWindow];
	BOOL useUnsignedValues  = [mDataSource useUnsignedValues];
	
    /* get scale limits */
	int minX = MAX(0,roundToLong([mXScale minValue]));
    int maxX = MIN(roundToLong([mXScale maxValue]),numPoints);
	if(differentiate){
		minX += averageWindow/2;
		maxX -= averageWindow/2;
		numPoints -= averageWindow;
	}
    minX = MAX(0,minX);
    maxX = MIN(maxX,numPoints);
    
    /* calculate the number of channels to display */
    float xRng = [mXScale valueRange];
    float inc = width / xRng;
    
    /* initialize x and y values */
    float x = [mXScale getPixAbs:minX]-inc/2;
 	float xl = x;
    float yl = -1;
   
    NSBezierPath* theDataPath = [NSBezierPath bezierPath];
    
	BOOL aLog = [mYScale isLog];
	BOOL aInt = [mYScale integer];
	double aMinPad = [mYScale minPad];
	double aMinPadx = [mXScale minPad];
    maxValue = -9E99;

	BOOL firstTime = YES;
	double forwardSum = 0;
	double backwardSum = 0;
	int n = averageWindow/2;
	double dn = (double)n;		
	char*  cPtr = nil;
	short* sPtr = nil;
	long*  lPtr = nil;
	NSData* theData = nil;
	unsigned long offset = 0;
	unsigned short unitSize;
	double theValue;
	
	if([mDataSource useDataObject:aPlot dataSet:dataSetID]){
		theData = [mDataSource plotter:aPlot dataSet:dataSetID];
		if(!theData)return;
		unitSize = [mDataSource unitSize:aPlot dataSet:dataSetID];
		offset	= [mDataSource startingByteOffset:aPlot dataSet:dataSetID];
	}
	else {
		unitSize = -1;
	}
	
	if(useUnsignedValues){
		switch(unitSize){
			case 1: cPtr = (char*) [theData bytes] + offset; theValue = (unsigned)cPtr[minX]; break;
			case 2: sPtr = (short*)[theData bytes] + offset; theValue = (unsigned)sPtr[minX]; break;
			case 4: lPtr = (long*) [theData bytes] + offset; theValue = (unsigned)lPtr[minX]; break;
			default:theValue = (unsigned)[mDataSource plotter:aPlot dataSet:dataSetID dataValue:minX]; break;
		}
	}
	else {
		switch(unitSize){
			case 1: cPtr = (char*) [theData bytes] + offset; theValue = cPtr[minX]; break;
			case 2: sPtr = (short*)[theData bytes] + offset; theValue = sPtr[minX]; break;
			case 4: lPtr = (long*) [theData bytes] + offset; theValue = lPtr[minX]; break;
			default:theValue = [mDataSource plotter:aPlot dataSet:dataSetID dataValue:minX]; break;
		}
	}
	
	yl   = [mYScale getPixAbs:theValue];
	long ix;
	for (ix=minX; ix<maxX;++ix) {		
		/* Get the data value for this point and increment to next point */
		if(!differentiate){
			if(useUnsignedValues){
				switch (unitSize){
					case 1: if(cPtr)theValue = (unsigned char)cPtr[ix]; break;
					case 2: if(sPtr)theValue = (unsigned short)sPtr[ix]; break;
					case 4: if(lPtr)theValue = (unsigned long)lPtr[ix]; break;
					default: theValue = (unsigned)[mDataSource plotter:aPlot dataSet:dataSetID dataValue:ix]; break;
				}
			}
			else {
				switch (unitSize){
					case 1: if(cPtr)theValue = cPtr[ix]; break;
					case 2: if(sPtr)theValue = sPtr[ix]; break;
					case 4: if(lPtr)theValue = lPtr[ix]; break;
					default: theValue = [mDataSource plotter:aPlot dataSet:dataSetID dataValue:ix]; break;
				}
			}
		}
		else {
			if(!firstTime){
				//if not first time just adjust the average using the new location	
				if(useUnsignedValues){
					switch (unitSize){
						case 1: if(cPtr){forwardSum  += ((unsigned char)cPtr[ix+n] - (unsigned char)cPtr[ix-1]); backwardSum += ((unsigned char)cPtr[ix-1] - (unsigned char)cPtr[ix-n-1]);} break;
						case 2: if(sPtr){forwardSum  += ((unsigned short)sPtr[ix+n] - (unsigned short)sPtr[ix-1]); backwardSum += ((unsigned short)sPtr[ix-1] - (unsigned short)sPtr[ix-n-1]); }break;
						case 4: if(lPtr){forwardSum  += ((unsigned long)lPtr[ix+n] - (unsigned long)lPtr[ix-1]); backwardSum += ((unsigned long)lPtr[ix-1] - (unsigned long)lPtr[ix-n-1]); }break;
						default:
							forwardSum  +=  ((unsigned)[mDataSource plotter:self dataSet:dataSetID dataValue:ix+n]/dn - (unsigned)[mDataSource plotter:self dataSet:dataSetID dataValue:ix-1]/dn);
							backwardSum +=  ((unsigned)[mDataSource plotter:self dataSet:dataSetID dataValue:ix-1]/dn - (unsigned)[mDataSource plotter:self dataSet:dataSetID dataValue:ix-n-1]/dn);
						break;
					}
				}
				else {
					switch (unitSize){
						case 1: if(cPtr){forwardSum  += (cPtr[ix+n] - cPtr[ix-1]); backwardSum += (cPtr[ix-1] - cPtr[ix-n-1]); }break;
						case 2: if(sPtr){forwardSum  += (sPtr[ix+n] - sPtr[ix-1]); backwardSum += (sPtr[ix-1] - sPtr[ix-n-1]); }break;
						case 4: if(lPtr){forwardSum  += (lPtr[ix+n] - lPtr[ix-1]); backwardSum += (lPtr[ix-1] - lPtr[ix-n-1]); }break;
						default:
							forwardSum  +=  ([mDataSource plotter:self dataSet:dataSetID dataValue:ix+n]/dn - [mDataSource plotter:self dataSet:dataSetID dataValue:ix-1]/dn);
							backwardSum +=  ([mDataSource plotter:self dataSet:dataSetID dataValue:ix-1]/dn - [mDataSource plotter:self dataSet:dataSetID dataValue:ix-n-1]/dn);
						break;
					}
				}
			}
			else {
				//first time thru do the full average
				firstTime = NO;
				int i;
				if(useUnsignedValues){
					for(i = 0;i<n;i++) {
						switch (unitSize){
							case 1: if(cPtr){forwardSum  += (unsigned char)cPtr[ix+i]; backwardSum += (unsigned char)cPtr[ix-i-1]; }break;
							case 2: if(sPtr){forwardSum  += (unsigned short)sPtr[ix+i]; backwardSum += (unsigned short)sPtr[ix-i-1];}  break;
							case 4: if(lPtr){forwardSum  += (unsigned long)lPtr[ix+i]; backwardSum += (unsigned long)lPtr[ix-i-1]; } break;
							default: 
								forwardSum  += (unsigned)[mDataSource plotter:self dataSet:dataSetID dataValue:ix+i];
								backwardSum += (unsigned)[mDataSource plotter:self dataSet:dataSetID dataValue:ix-i];
							break;
						}
					}
				}
				else {
					for(i = 0;i<n;i++) {
						switch (unitSize){
							case 1: if(cPtr){forwardSum  += cPtr[ix+i]; backwardSum += cPtr[ix-i-1];} break;
							case 2: if(sPtr){forwardSum  += sPtr[ix+i]; backwardSum += sPtr[ix-i-1];}  break;
							case 4: if(lPtr){forwardSum  += lPtr[ix+i]; backwardSum += lPtr[ix-i-1];}  break;
							default: 
								forwardSum  += [mDataSource plotter:self dataSet:dataSetID dataValue:ix+i];
								backwardSum += [mDataSource plotter:self dataSet:dataSetID dataValue:ix-i];
							break;
						}
					}
				}
			}
			theValue = forwardSum/dn - backwardSum/dn;
		}
		float y = [mYScale getPixAbsFast:theValue log:aLog integer:aInt minPad:aMinPad];
		if(y>maxValue)maxValue = y;
		x = [mXScale getPixAbsFast:ix log:NO integer:YES minPad:aMinPadx] + inc/2.;
		if(differentiate &&  ix == minX){
			xl = x;
			yl = y;	
			continue;
		}
		
		[theDataPath moveToPoint:NSMakePoint(xl,yl)];
		[theDataPath lineToPoint:NSMakePoint(xl,y)];
		[theDataPath lineToPoint:NSMakePoint(x,y)];
		
		// save previous x and y values
		xl = x;
		yl = y;
	
	}

	NSColor* curveColor = [aPlot colorForDataSet:dataSetID];
	
	if([aPlot setAllLinesBold]){
		[curveColor set];
	}
	else {
		if([aPlot activeCurve] == self)[curveColor set];
		else [[curveColor highlightWithLevel:.4]set];
	}
	[theDataPath setLineWidth:.5];
	[theDataPath stroke];
}

- (void) drawXYPlot:(ORPlotter1D*)aPlot
{
    float   x, y, xl, yl;
    int   minX;
	id mDataSource = [aPlot dataSource];
	ORAxis*    mXScale = [aPlot xScale];
	ORAxis*    mYScale = [aPlot yScale];
	
	if(showActiveGate){
        [gates makeObjectsPerformSelector:@selector(drawGateInPlot:) withObject:aPlot];
    }
	
	int numPoints = [mDataSource numberOfPointsInPlot:aPlot dataSet:dataSetID];
    if(numPoints == 0) return;

    [NSBezierPath setDefaultLineWidth:.2];
		
    /* get scale limits */
    minX = MAX(0,roundToLong([mXScale minValue]));
    //maxX = MIN(roundToLong([mXScale maxValue]),roundToLong([mDataSource plotterMinX:aPlot]));
	
    //minY = [mYScale minValue];
   // maxY = [mYScale maxValue];
        	
    
    NSBezierPath* theDataPath = [NSBezierPath bezierPath];
    
	BOOL aLog = [mYScale isLog];
	BOOL aInt = [mYScale integer];
	double aMinPad = [mYScale minPad];
	double theValue = 0;

	yl   = [mYScale getPixAbs:theValue];
	xl	 = [mXScale getPixAbs:minX];

	int i;
	float xValue,yValue;
	if([aPlot drawSymbols]){
		for (i=0; i<numPoints;++i) {
			[mDataSource plotter:aPlot dataSet:dataSetID index:i x:&xValue y:&yValue];
			y = [mYScale getPixAbsFast:yValue log:aLog integer:aInt minPad:aMinPad];
			x = [mXScale getPixAbs:xValue];			
			NSColor* curveColor = [aPlot colorForDataSet:dataSetID];
			if([aPlot activeCurve] == self)[curveColor set];
			else [[curveColor highlightWithLevel:.4]set];
			[NSBezierPath fillRect:NSMakeRect(x-1,y-1,2,2)];
		}
	}
	else {
		for (i=0; i<numPoints;++i) {
							
			[mDataSource plotter:aPlot dataSet:dataSetID index:i x:&xValue y:&yValue];
			y = [mYScale getPixAbsFast:yValue log:aLog integer:aInt minPad:aMinPad];
			x = [mXScale getPixAbs:xValue];
			
			if(i>0){
				[theDataPath moveToPoint:NSMakePoint(xl,yl)];
				[theDataPath lineToPoint:NSMakePoint(x,y)];
			}
			
			// save previous x and y values
			xl = x;
			yl = y;
			
		}
	
		NSColor* curveColor = [aPlot colorForDataSet:dataSetID];
		
		if([aPlot activeCurve] == self)[curveColor set];
		else [[curveColor highlightWithLevel:.4]set];
		[theDataPath setLineWidth:.5];
		[theDataPath stroke];
	}
	
}

- (void) drawXYTimePlot:(ORPlotter1D*)aPlot
{
    float   x, y, xl, yl;
    int   minX;
	id mDataSource = [aPlot dataSource];
	ORAxis*    mXScale = [aPlot xScale];
	ORAxis*    mYScale = [aPlot yScale];
	int numPoints = [mDataSource numberOfPointsInPlot:aPlot dataSet:dataSetID];
    if(numPoints == 0) return;

    [NSBezierPath setDefaultLineWidth:.2];
		
    /* get scale limits */
    minX = MAX(0,roundToLong([mXScale minValue]));
   // maxX = MIN(roundToLong([mXScale maxValue]),roundToLong([mDataSource plotterMinX:aPlot]));
	
   // minY = [mYScale minValue];
   // maxY = [mYScale maxValue];
        	
    NSTimeInterval startTime = [mDataSource plotterStartTime:aPlot];
	[(ORTimeLine*)mXScale setStartTime: startTime];
    NSBezierPath* theDataPath = [NSBezierPath bezierPath];
    
	BOOL aLog = [mYScale isLog];
	BOOL aInt = [mYScale integer];
	double aMinPad = [mYScale minPad];
	double theValue = 0;

	if(!aLog)	yl = [mYScale getPixAbs:theValue];
	else		yl = [mYScale getPixAbs:1];
	xl	 = [mXScale getPixAbs:minX];

	int i;
	unsigned long xValue;
	float yValue;
	for (i=0; i<numPoints;++i) {
						
		[mDataSource plotter:aPlot dataSet:dataSetID index:i time:&xValue y:&yValue];
		y = [mYScale getPixAbsFast:yValue log:aLog integer:aInt minPad:aMinPad];
		x = [mXScale getPixAbs:(double)(xValue - startTime)];
		
		[theDataPath moveToPoint:NSMakePoint(xl,yl)];
		[theDataPath lineToPoint:NSMakePoint(x,yl)];
		[theDataPath lineToPoint:NSMakePoint(x,y)];
		
		// save previous x and y values
		xl = x;
		yl = y;
		
	}

	NSColor* curveColor = [aPlot colorForDataSet:dataSetID];
	
	if([aPlot activeCurve] == self)[curveColor set];
	else [[curveColor highlightWithLevel:.4]set];
	[theDataPath setLineWidth:.5];
	[theDataPath stroke];

}

- (void) drawFit:(ORPlotter1D*)aPlot
{
	int numGates = [gates count];
	int i;
	for(i=0;i<numGates;i++){
		ORGate1D* theGate = [gates objectAtIndex:i];
		if([theGate fitExists] && [theGate gateIsActive]){
			int numPoints = [theGate numberOfPointsInPlot:aPlot dataSet:dataSetID];
			if(numPoints == 0) return;
												
			/* get scale limits */
			ORAxis* mXScale = [aPlot xScale];
			ORAxis* mYScale = [aPlot yScale];
			
			//cache some stuff
			BOOL aLogY		= [mYScale isLog];
			BOOL aIntY		= [mYScale integer];
			double aMinPadY = [mYScale minPad];
			BOOL aLogX		= [mXScale isLog];
			BOOL aIntX		= [mXScale integer];
			double aMinPadX = [mXScale minPad];
			
														
			NSBezierPath* theDataPath = [NSBezierPath bezierPath];
			if([aPlot useXYPlot]){
				int minX		= [theGate fitMinChannel];
				float theFitValue	= [theGate plotter:aPlot dataSet:dataSetID dataValue:0];
				float y			= [mYScale getPixAbsFast:theFitValue log:aLogY integer:aIntY minPad:aMinPadY];
				float x			= [mXScale getPixAbsFast:minX log:aLogX integer:aIntX minPad:aMinPadX];
				[theDataPath moveToPoint:NSMakePoint(x,y)];
				
				int numPoints = [[aPlot dataSource] numberOfPointsInPlot:aPlot dataSet:dataSetID];
				int i;
				int fitIndex = 0;
				for(i=0;i<numPoints;i++){
					[[aPlot dataSource] plotter:aPlot dataSet:dataSetID index:i x:&x y:&y];
					if(x >= [theGate fitMinChannel] && x <= [theGate fitMaxChannel]){
						theFitValue = [theGate plotter:aPlot dataSet:dataSetID dataValue:fitIndex++];
						y = [mYScale getPixAbsFast:theFitValue log:aLogY integer:aIntY minPad:aMinPadY];
						x = [mXScale getPixAbsFast:x log:aLogX integer:aIntX minPad:aMinPadX];
						[theDataPath lineToPoint:NSMakePoint(x,y)];
					}
				}
			}
			else {
				int minX		= MAX(0,MAX([theGate fitMinChannel],roundToLong([mXScale minValue])));
				int maxX		= MIN(numPoints,MIN(roundToLong([mXScale maxValue]),[theGate fitMaxChannel]));
				float theValue	= [theGate plotter:aPlot dataSet:dataSetID dataValue:minX];
				float y			= [mYScale getPixAbsFast:theValue log:aLogY integer:aIntY minPad:aMinPadY];
				float x			= [mXScale getPixAbsFast:minX log:aLogX integer:aIntX minPad:aMinPadX];
				
				[theDataPath moveToPoint:NSMakePoint(x,y)];
				//float halfBinWidth = ([aPlot bounds].size.width - 1) / (float)[mXScale valueRange]/2.;

				long    ix;
				for (ix=minX; ix<maxX;++ix) {
					theValue = [theGate plotter:aPlot dataSet:dataSetID dataValue:ix];
					y = [mYScale getPixAbsFast:theValue log:aLogY integer:aIntY minPad:aMinPadY];
					x = [mXScale getPixAbsFast:ix log:aLogX integer:aIntX minPad:aMinPadX];// + halfBinWidth;
					[theDataPath lineToPoint:NSMakePoint(x,y)];
				}
			}
			[[NSColor blackColor] set];
			[theDataPath setLineWidth:1];
			[theDataPath stroke];
		}
	}
}

- (void) doAnalysis:(ORPlotter1D*)aPlotter
{
	[gates makeObjectsPerformSelector:@selector(analyzePlot:) withObject:aPlotter];
	
}

- (NSArray*) dataPointArray:(ORPlotter1D*)aPlot range:(NSRange)aRange
{
	id mDataSource = [aPlot dataSource];
	int numPoints = [mDataSource numberOfPointsInPlot:aPlot dataSet:dataSetID];
    if(numPoints == 0) return nil;
	
	BOOL useUnsignedValues  = [mDataSource useUnsignedValues];
	
 	char*  cPtr;
	short* sPtr;
	long*  lPtr;
	NSData* theData = nil;
	unsigned long offset = 0;
	unsigned short unitSize = -1;
	double theValue;
	
	NSMutableArray* dataPointArray = [NSMutableArray arrayWithCapacity:numPoints];
	if([mDataSource useXYPlot]){
		int index;
		int numPoints = [mDataSource numberOfPointsInPlot:aPlot dataSet:dataSetID];
		for (index=0; index<numPoints; ++index) {
			float x;
			float val;
			[mDataSource plotter:aPlot dataSet:dataSetID index:index  x:&x y:&val];
			if(x>=aRange.location && x<=aRange.length){
				[dataPointArray addObject:[NSNumber numberWithDouble:val]];
			}
		}
	}
	else {
		
		int end = aRange.location + aRange.length;
		if([mDataSource useDataObject:aPlot dataSet:dataSetID]){
			theData = [mDataSource plotter:aPlot dataSet:dataSetID];
			if(!theData)return nil;
			unitSize = [mDataSource unitSize:aPlot dataSet:dataSetID];
			offset	= [mDataSource startingByteOffset:aPlot dataSet:dataSetID];
		}
		else unitSize = -1;
		int ix;
		for(ix=aRange.location;ix<end;ix++){
			if(useUnsignedValues){
				switch(unitSize){
					case 1: cPtr = (char*) [theData bytes] + offset; theValue = (unsigned)cPtr[ix]; break;
					case 2: sPtr = (short*)[theData bytes] + offset; theValue = (unsigned)sPtr[ix]; break;
					case 4: lPtr = (long*) [theData bytes] + offset; theValue = (unsigned)lPtr[ix]; break;
					default:theValue = (unsigned)[mDataSource plotter:aPlot dataSet:dataSetID dataValue:ix]; break;
				}
			}
			else {
				switch(unitSize){
					case 1: cPtr = (char*) [theData bytes] + offset; theValue = cPtr[ix]; break;
					case 2: sPtr = (short*)[theData bytes] + offset; theValue = sPtr[ix]; break;
					case 4: lPtr = (long*) [theData bytes] + offset; theValue = lPtr[ix]; break;
					default:theValue = [mDataSource plotter:aPlot dataSet:dataSetID dataValue:ix]; break;
				}
			}
			[dataPointArray addObject:[NSNumber numberWithDouble:theValue]];
		}
	}
	return dataPointArray;
}


- (BOOL) analyze
{
    return analyze;
}
- (void) setAnalyze:(BOOL)newAnalyze
{
    analyze=newAnalyze;
    //if(analyze)[self analyze:self];
}

- (void) keyDown:(NSEvent*)theEvent
{
    if(showActiveGate){
        [[self activeGate]keyDown:theEvent];
    }
}

- (void) reportMousePosition:(NSEvent*)theEvent plotter:(ORPlotter1D*)aPlotter
{
	NSEventType modifierKeys = [theEvent modifierFlags];
	if(modifierKeys & NSCommandKeyMask){
		NSPoint p = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
		if([aPlotter mouse:p inRect:[aPlotter bounds]]){
			ORAxis* xScale = [aPlotter xScale];
			int x = floor([xScale convertPoint:p.x]+.5);
			id theCalibration = [[[aPlotter dataSource] model] calibration];
			float finalX = x;
			if(theCalibration && [theCalibration useCalibration]){
				finalX = [theCalibration convertedValueForChannel:x];
			}
			float y = [[aPlotter dataSource] plotter:aPlotter dataSet:dataSetID dataValue:x ];
			[[NSNotificationCenter defaultCenter]
				postNotificationName:ORPlotter1DMousePosition
							  object: aPlotter 
							userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithFloat:finalX],	@"x",
									[NSNumber numberWithFloat:y],		@"y",
									[NSNumber numberWithFloat:x],		@"plotx",
									[NSNumber numberWithFloat:y],		@"ploty",
									nil]];
		}
	}
}

-(void)	mouseDown:(NSEvent*)theEvent  plotter:(ORPlotter1D*)aPlotter
{
    if(showActiveGate){
        [[gates objectAtIndex:activeGateIndex] mouseDown:theEvent plotter:aPlotter];
    }
    [self reportMousePosition:theEvent plotter:aPlotter];
}

-(void)	mouseDragged:(NSEvent*)theEvent  plotter:(ORPlotter1D*)aPlotter
{
    if(showActiveGate){
        [[gates objectAtIndex:activeGateIndex] mouseDragged:theEvent plotter:aPlotter];
    }
    [self reportMousePosition:theEvent plotter:aPlotter];
}


-(void)	mouseUp:(NSEvent*)theEvent  plotter:(ORPlotter1D*)aPlotter
{
    if(showActiveGate){
        [[gates objectAtIndex:activeGateIndex] mouseUp:theEvent plotter:aPlotter];
    }
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORPlotter1DMousePosition
                      object: aPlotter 
                    userInfo: nil];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    if([coder allowsKeyedCoding]){
		[coder encodeInt:dataSetID forKey:@"ORCurve1DDataSetID"];
		[coder encodeInt:activeGateIndex forKey:@"ORCurve1DActiveGateIndex"];
		[coder encodeObject:attributes forKey:@"ORCurve1DAttributes"];
		[coder encodeObject:gates forKey:@"ORCurve1DCurves"];
    }
    else {
		[coder encodeObject:attributes];
		[coder encodeObject:gates];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if([coder allowsKeyedCoding]){
		[self setDataSetID:[coder decodeIntForKey:@"ORCurve1DDataSetID"]];    
		[self setActiveGateIndex:[coder decodeIntForKey:@"ORCurve1DActiveGateIndex"]];    
		[self setAttributes:[coder decodeObjectForKey:@"ORCurve1DAttributes"]];    
		[self setGates:[coder decodeObjectForKey:@"ORCurve1DCurves"]];    
    }
    else {
		[self setAttributes:[coder decodeObject]];    
		[self setGates:[coder decodeObject]];    
    }
    return self;
}

- (double) maxValue
{
    return maxValue;
}

- (BOOL) showActiveGate
{
    return showActiveGate;
}

- (void) setShowActiveGate: (BOOL) flag plotter:(ORPlotter1D*)aPlotter
{
    showActiveGate = flag;
    ORGate1D* theActiveGate = [self activeGate];
    if(showActiveGate){        
        if([theActiveGate gateMinChannel] == 0 && [theActiveGate gateMaxChannel]==0){
            //OK never been shown before... set some defaults
            double range = [[aPlotter xScale] maxValue]-[[aPlotter xScale] minValue];
            double center = range/2.;
            [theActiveGate setDefaultMin:center - range/10. max:center + range/10.];
        }
        
        [theActiveGate setGateValid:YES];
    }
    else [theActiveGate setGateValid:NO];

}

@end
