//
//  ORCurve2D.m
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


#import "ORCurve2D.h"
#import "ORPlotter2D.h"
#import "ORAxis.h"
#import "ORColorScale.h"
#import "ORGate2D.h"

#define kMaxNumRects 100

NSString* ORCurve2DActiveGateChanged = @"ORCurve2DActiveGateChanged";


@implementation ORCurve2D
+(id) curve:(int)aDataSetID
{
    return [[[ORCurve2D alloc] initWithCurve:aDataSetID] autorelease];
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

- (void) drawDataInPlot:(ORPlotter2D*)aPlot
{
    float   x, y, xl, yl;
    short   minX, maxX ;
    float   xinc,xsum,yinc,ysum, xfrc,yfrc;
    long    ix,iy,xRng,yRng;
    float   minY, maxY;
    short   xwidth,ywidth;
	id mDataSource = [aPlot dataSource];
	ORAxis*    mXScale = [aPlot xScale];
	ORAxis*    mYScale = [aPlot yScale];
    ORColorScale* colorScale = [aPlot colorScale];
    
    unsigned short numBinsPerSide;
    unsigned short dataXMin,dataXMax,dataYMin,dataYMax;
	unsigned long* data = [mDataSource plotter:aPlot dataSet:dataSetID numberBinsPerSide:&numBinsPerSide];
    [mDataSource plotter:aPlot dataSet:dataSetID xMin:&dataXMin xMax:&dataXMax yMin:&dataYMin yMax:&dataYMax];
    
    if(!data)return;
    xwidth = [aPlot bounds].size.width - 1;
    ywidth = [aPlot bounds].size.height - 1;
    
    [NSBezierPath setDefaultLineWidth:.2];
	
    /* get scale limits */
    minX = MAX(MAX(0,roundToLong([mXScale minValue])),dataXMin);
    maxX = MIN(MIN(roundToLong([mXScale maxValue]),numBinsPerSide),dataXMax);
	
    minY = MAX(MAX(0,roundToLong([mYScale minValue])),dataYMin);
    maxY = MIN(MIN(roundToLong([mYScale maxValue]),numBinsPerSide),dataYMax);
    
    
    /* calculate the number of channels to display */
    xRng = [mXScale valueRange];
    xinc = xwidth / xRng;
    xfrc = xwidth % xRng;
    xsum = -(xRng + 1) / 2.;

    yRng = [mYScale valueRange];
    yinc = ywidth / yRng;
    yfrc = ywidth % yRng;
    ysum = -(yRng + 1) / 2.;

    
    /* initialize x and y values */
    yl = y = [mYScale getPixAbs:minY]-yinc/2;
    /* loop through all data in plot window */
    maxValue = -9E99;
    short rectCount[256];
    memset(rectCount,0,256*sizeof(short));
    NSRect rectList[256][kMaxNumRects];

	BOOL aLog       = [[colorScale colorAxis] isLog];
	BOOL aInt       = [[colorScale colorAxis] integer];
	double aMinPad  = [[colorScale colorAxis] minPad];


    for (iy=minY; iy<=maxY;++iy) {
        
        y += yinc;
        
        /* increment the running sum and check for overflow to next pixel */
        if ((ysum+=yfrc) >= 0) {
            ++y;
            ysum -= yRng;
        }

        xl = x = [mXScale getPixAbs:minX]-xinc/2.;

        for (ix=minX; ix<=maxX;++ix) {	
            x += xinc;
            
            /* increment the running sum and check for overflow to next pixel */
            if ((xsum+=xfrc) >= 0) {
                ++x;
                xsum -= xRng;
            }
            
            /* Get the data value for this point and increment to next point */
            unsigned long z = data[ix + iy*numBinsPerSide];
            if(z){
                int colorIndex = [colorScale getFastColorIndexForValue:z log:aLog integer:aInt minPad:aMinPad];
                rectList[colorIndex][rectCount[colorIndex]] = NSMakeRect(xl,yl,x-xl+1,y-yl+1);
                ++rectCount[colorIndex];
                //[[colorScale getColorForValue:z] set];
                //[NSBezierPath fillRect:NSMakeRect(xl,yl,x-xl+1,y-yl+1)];
                if(rectCount[colorIndex]>=kMaxNumRects){
                    [[colorScale getColorForIndex:colorIndex] set];
                    NSRectFillList(rectList[colorIndex],rectCount[colorIndex]);
                    rectCount[colorIndex] = 0;
                }
            }
            // save previous x and y values
            xl = x;
        }
        yl = y;
    }	
    //flush rects
    long i;
    for(i=0;i<256;i++){
        if(rectCount[i]){
            [[colorScale getColorForIndex:i] set];
            NSRectFillList(rectList[i],rectCount[i]);
        }
    }
	
	if(showActiveGate){
        [gates makeObjectsPerformSelector:@selector(drawGateInPlot:) withObject:aPlot];
    }

}

- (void) drawVector:(ORPlotter2D*)aPlot
{
    float   xl, yl;
    float xValue;
    float yValue;

	id mDataSource = [aPlot dataSource];
	ORAxis*    mXScale = [aPlot xScale];
	ORAxis*    mYScale = [aPlot yScale];
        
    float oldWidth = [NSBezierPath defaultLineWidth];
    [NSBezierPath setDefaultLineWidth:.5];
    
    int i,set;
    int numSets = [mDataSource numberOfDataSetsInPlot:aPlot];
    for(set = 0;set<numSets;set++){
        NSColor* pointColor = [mDataSource plotter:aPlot colorForSet:set];
        [pointColor set];
        int n = [mDataSource plotter:aPlot numPointsInSet:set];
        for(i=0;i<n;i++){
            if([mDataSource plotter:aPlot dataSet:set index:i x:&xValue y:&yValue]){            
                xl = [mXScale getPixAbs:xValue];
                yl = [mYScale getPixAbs:yValue];
                [NSBezierPath fillRect:NSMakeRect(xl-1,yl-1,2,2)];
            }
        }
        if([mDataSource plotter:aPlot dataSet:set crossHairX:&xValue crossHairY:&yValue]){
            xl = [mXScale getPixAbs:xValue];
            yl = [mYScale getPixAbs:yValue];
            short xwidth = [aPlot bounds].size.width - 1;
            short ywidth = [aPlot bounds].size.height - 1;
            [NSBezierPath strokeLineFromPoint:NSMakePoint(0,yl) toPoint:NSMakePoint(xwidth,yl)];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(xl,0) toPoint:NSMakePoint(xl,ywidth)];
        }
    }
    [NSBezierPath setDefaultLineWidth:oldWidth];
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    if([coder allowsKeyedCoding]){
		[coder encodeObject:attributes forKey:@"ORCurve2DAttributes"];
		[coder encodeObject:gates forKey:@"ORCurve2DCurves"];
    }
    else {
		[coder encodeObject:attributes];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if([coder allowsKeyedCoding]){
		[self setAttributes:[coder decodeObjectForKey:@"ORCurve2DAttributes"]];    
		[self setGates:[coder decodeObjectForKey:@"ORCurve2DCurves"]];    
    }
    else {
		[self setAttributes:[coder decodeObject]];    
    }
    return self;
}

- (double) maxValue
{
    return maxValue;
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

- (void) addGate:(ORGate2D*)aGate
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
		[self setActiveGateIndex:activeGateIndex%[gates count]];
		[gates makeObjectsPerformSelector:@selector(postNewGateID) withObject:nil];
    }
}

- (void) clearActiveGate
{
    [[self activeGate] setGateValid:NO];
}

- (void) clearAllGates
{
    [gates makeObjectsPerformSelector:@selector(clearGates) withObject:nil];
}

- (int) gateNumber:(ORGate2D*)aGate
{
    return [gates indexOfObject:aGate];
}
- (BOOL) showActiveGate
{
    return showActiveGate;
}

- (void) setShowActiveGate: (BOOL) flag
{
    showActiveGate = flag;
    ORGate2D* theActiveGate = [self activeGate];
    if(showActiveGate){
       [theActiveGate setGateValid:YES];
    }
    else [theActiveGate setGateValid:NO];

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
- (id) activeGate
{
	if([gates count]) return [gates objectAtIndex:activeGateIndex];
	else return nil;
}

- (int)activeGateIndex 
{
    return activeGateIndex;
}

- (void)setActiveGateIndex:(int)anactiveGateIndex 
{
    activeGateIndex = anactiveGateIndex;
	ORGate2D* aGate = [self activeGate];;
	[[NSNotificationCenter defaultCenter]
        postNotificationName:ORCurve2DActiveGateChanged
                      object: aGate
                    userInfo: nil];

}

- (void) doAnalysis:(ORPlotter2D*)aPlotter
{
	[gates makeObjectsPerformSelector:@selector(analyzePlot:) withObject:aPlotter];	
}

#pragma mark ¥¥¥Mouse Handling
-(void)	mouseDown:(NSEvent*)theEvent  plotter:(ORPlotter2D*)aPlotter
{	
    if(showActiveGate){
       [[self activeGate] mouseDown:theEvent plotter:aPlotter];
    }
//    [self reportMousePosition:theEvent plotter:aPlotter];
}

-(void)	mouseDragged:(NSEvent*)theEvent  plotter:(ORPlotter2D*)aPlotter
{
    if(showActiveGate){
        [[self activeGate] mouseDragged:theEvent plotter:aPlotter];
    }
//    [self reportMousePosition:theEvent plotter:aPlotter];
}


-(void)	mouseUp:(NSEvent*)theEvent  plotter:(ORPlotter2D*)aPlotter
{
    if(showActiveGate){
        [[self activeGate] mouseUp:theEvent plotter:aPlotter];
    }
//    [[NSNotificationCenter defaultCenter]
  //      postNotificationName:ORPlotter2DMousePosition
    //                  object: aPlotter 
      //              userInfo: nil];
}

- (void)flagsChanged:(NSEvent *)theEvent  plotter:(ORPlotter2D*)aPlotter
{
	[[self activeGate] flagsChanged:theEvent plotter:aPlotter];
}

@end
