#import "ORPlotter.h"
#import "ORScale.h"

NSString* ORPlotROIValidChangedNotification = @"ORPlotROIValidChangedNotification";
NSString* ORPlotROIMinChangedNotification 	= @"ORPlotROIMinChangedNotification";
NSString* ORPlotROIMaxChangedNotification 	= @"ORPlotROIMaxChangedNotification";
NSString* ORPlotAverageChangedNotification 	= @"ORPlotAverageChangedNotification";
NSString* ORPlotCentroidChangedNotification = @"ORPlotCentroidChangedNotification";
NSString* ORPlotSigmaChangedNotification 	= @"ORPlotSigmaChangedNotification";
NSString* ORPlotTotalSumChangedNotification = @"ORPlotTotalSumChangedNotification";




@interface ORPlotter (private)
- (void) drawRectFake:(NSRect) rect;
@end;

@implementation ORPlotter

+ (void) initialize
{
	if(self == [ORPlotter class]){
		[self setVersion:2];		
	}
}

-(id)initWithFrame:(NSRect)aFrame
{
    if(self = [super initWithFrame:aFrame]){
        [self setBackgroundColor:[NSColor whiteColor]];
        [self setGridColor:[NSColor grayColor]];
        [self setDataColor:[NSColor blackColor]];
        [self setRoiColor:[NSColor lightGrayColor]];
    }
    return self;
}

-(void)dealloc
{
    [gridColor release];
    [dataColor release];
    [backgroundColor release];
    [roiColor release];
    [super dealloc]; 
}

- (void) awakeFromNib
{

	//make sure the scales get drawn first so that the grid arrays have been 
	//created before we are drawn.
	ORScale* xs = [mXScale retain];
	[mXScale removeFromSuperviewWithoutNeedingDisplay];
	[[self superview] addSubview:xs positioned:NSWindowBelow relativeTo:self]; 
	[xs release];

	ORScale* ys = [mYScale retain];
	[mYScale removeFromSuperviewWithoutNeedingDisplay];
	[[self superview] addSubview:ys positioned:NSWindowBelow relativeTo:self]; 
	[ys release];
        [self setNeedsDisplay:YES];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:backgroundColor];
    [coder encodeObject:gridColor];
    [coder encodeObject:dataColor];
    [coder encodeObject:roiColor];
    [coder encodeObject:[NSNumber numberWithBool:roiValid]];
    [coder encodeObject:[NSNumber numberWithInt:roi1]];
    [coder encodeObject:[NSNumber numberWithInt:roi2]];
}

- (id)initWithCoder:(NSCoder *)coder
{
    int version;
    [super initWithCoder:coder];
    [self setBackgroundColor:[coder decodeObject]]; 
    version = [coder versionForClassName:@"ORPlotter"];   
    [self setGridColor:[coder decodeObject]];    
    [self setDataColor:[coder decodeObject]];
    if(version>=1){
        [self setRoiColor:[coder decodeObject]];
    }
    if(version>=2){
        roiValid = [[coder decodeObject] boolValue];
        roi1 = [[coder decodeObject] intValue];
        roi2 = [[coder decodeObject] intValue];
        [self setRoiMinChannel:MIN(roi1,roi2)];
        [self setRoiMaxChannel:MAX(roi1,roi2)];
    }

    return self;
}
- (ORScale*) xScale
{
	return mXScale;
}
- (void) setXScale:(ORScale*)newXScale
{
	[mXScale autorelease];
	mXScale=[newXScale retain];
}

- (ORScale*) yScale
{
	return mYScale;
}
- (void) setYScale:(ORScale*)newYScale
{
	[mYScale autorelease];
	mYScale=[newYScale retain];
}


- (void) drawRect:(NSRect) rect
{
    short				x, y, xl, yl;
    short				minX, maxX, xRng, inc, frc, sum, ht, width;
    long				ix;
    double				valY, minY, maxY;

	if(!mYScale && !mXScale){
		[self drawRectFake:rect];
		return;
	}

	
    NSRect bounds = [self bounds];
    [backgroundColor set];
    [NSBezierPath fillRect:bounds];
    [[NSColor darkGrayColor] set];
    [NSBezierPath strokeRect:bounds];

	ht = bounds.size.height - 1;
	width = bounds.size.width - 1;

    //draw the Grid
    NSBezierPath* theGrid = [NSBezierPath bezierPath];
	[theGrid setLineWidth:.5];
    ht = [self frame].size.height;        
        
    NSEnumerator * enumerator = [[mXScale gridArray] objectEnumerator];
    NSNumber* aNumber;
    while ((aNumber = [enumerator nextObject])) {
        [theGrid moveToPoint:NSMakePoint([aNumber longValue],0)];
        [theGrid relativeLineToPoint:NSMakePoint(0,ht)];
    }
    
    width = [self frame].size.width;
    enumerator = [[mYScale gridArray] objectEnumerator];
    while ((aNumber = [enumerator nextObject])) {
        [theGrid moveToPoint:NSMakePoint(0,[aNumber longValue])];
        [theGrid relativeLineToPoint:NSMakePoint(width,0)];
    }

// Draw the plot data, errors, and region of interest


	
	[gridColor set];
	[theGrid setLineWidth:.5];
	[theGrid stroke];

	short startRoi 	= 0;
	short endRoi 	= 0;
	int n = [mDataSource numberOfDataSetsInPlot:self];
	short line ;
	for(line = 0 ; line <n ; ++line){
		
		/* get scale limits */
		minX = roundPH([mXScale getMinVal]);
		maxX = roundPH([mXScale getMaxVal]);
		minY = [mYScale getMinVal];
		maxY = [mYScale getMaxVal];
			/* make sure x-axis is within the data array */
		if (minX < 0) minX = 0;
		if (maxX > [mDataSource numberOfPointsInPlot:self dataSet:line]) maxX = [mDataSource numberOfPointsInPlot:self dataSet:line];
		if (minX >= maxX) return;
	
	
		/* calculate the number of channels to display */
		xRng = [mXScale getRng];
		inc = width / xRng;
		frc = width % xRng;
		sum = -(xRng + 1) / 2;
	
		/* initialize x and y values */
		yl = -1;
		xl = x = [mXScale getPixAbs:minX]-inc/2;
	
		//do the roi
		if(line == 0 ){
			
			if(roiValid){
				if(roi1 <= roi2){
					startRoi = roi1;
					endRoi	 = roi2;
				}
				else {
					startRoi = roi2;
					endRoi	 = roi1;
				}
				startRoi = [mXScale getPixAbs:startRoi]-inc/2;
				endRoi = [mXScale getPixAbs:endRoi]-inc/2;
			
			}

		}
		//----------------

		NSBezierPath* theDataPath = [NSBezierPath bezierPath];
	
		/* loop through all data in plot window */
		for (ix=minX; ix<maxX;) {
			
			x += inc;
			
			/* increment the running sum and check for overflow to next pixel */
			if ((sum+=frc) >= 0) {
				++x;
				sum -= xRng;
			}
			
			/* Get the data value for this point and increment to next point */
			valY = [mDataSource plotter:self dataSet:line dataValue:ix ];
			if (valY > maxY)		y = ht;
			else if (valY < minY) 	y = 0;
			else 					y = [mYScale getPixAbs:valY];
	
			[theDataPath moveToPoint:NSMakePoint(xl,yl)];
			[theDataPath lineToPoint:NSMakePoint(xl,y)];
			[theDataPath lineToPoint:NSMakePoint(x,y)];
	
			if(roiValid && xl>=startRoi && xl<endRoi){
				[roiColor set];
				[NSBezierPath fillRect:NSMakeRect(xl,0,x-xl+1,y)]; 
			}
	
	
			// save previous x and y values
			xl = x;
			yl = y;
			++ix;
		}
		
		if([mDataSource willSupplyColors]){
			[[mDataSource colorForDataSet:line] set];
		}
		else {
			[dataColor set];
		}
		[theDataPath setLineWidth:.5];
		[theDataPath stroke];
		
	}
	if(roiValid){
		[[NSColor yellowColor] set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(startRoi,0) toPoint:NSMakePoint(startRoi,ht)];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(endRoi+1,0) toPoint:NSMakePoint(endRoi+1,ht)];
	}

	[self analyze:self];

}

- (BOOL)isOpaque
{
    return YES;
}
- (id)dataSource
{
    return mDataSource;
}

- (void)setDataSource:(id)d
{
    [d retain];
    [mDataSource release];
    mDataSource = d;
    [self setNeedsDisplay: YES];
}

- (void)setBackgroundColor:(NSColor *)c
{
    [c retain];
    [backgroundColor release];
    backgroundColor = c;
    [self setNeedsDisplay: YES];
}

-(NSColor*)backgroundColor{
    return backgroundColor;
}

- (void)setGridColor:(NSColor *)c
{
    [c retain];
    [gridColor release];
    gridColor = c;
    [self setNeedsDisplay: YES];
}

-(NSColor*)gridColor{
    return gridColor;
}

- (void)setDataColor:(NSColor *)c
{
    [c retain];
    [dataColor release];
    dataColor = c;
    [self setNeedsDisplay: YES];
}

-(NSColor*)dataColor{
    return dataColor;
}

- (void)setRoiColor:(NSColor *)c
{
    [c retain];
    [roiColor release];
    roiColor = c;
    [self setNeedsDisplay: YES];
}

-(NSColor*)roiColor{
    return roiColor;
}


-(void)setFrame:(NSRect)aFrame
{
    [super setFrame:aFrame];
    [self setNeedsDisplay:YES];
}

- (void)savePDF:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setRequiredFileType:@"pdf"];
    [panel beginSheetForDirectory: nil
                             file: nil
                   modalForWindow: [self window]
                    modalDelegate: self
                   didEndSelector:
        @selector(didEnd:returnCode:contextInfo:)
                      contextInfo: nil];
}

- (void)didEnd:(NSSavePanel *)sheet
    returnCode:(int)code
   contextInfo:(void *)contextInfo
{
    NSRect r;
    NSData *data;

    if (code == NSOKButton) {
        r = [[self superview] bounds];
        data = [[self superview] dataWithPDFInsideRect: r];
        [data writeToFile: [sheet filename] atomically: YES];
    }
}

- (IBAction) resetScales:(id)sender
{
    int numSets = [mDataSource numberOfDataSetsInPlot:self];
    double maxValue = -9E99;
    double minValue = 9E99;
    double maxN  = 0;
    double val;
    int i;
    int set;
    for(set=0;set<numSets;++set){
        int n = [mDataSource numberOfPointsInPlot:self dataSet:set];
        if(n > maxN)maxN = n;
        for(i = 0 ; i <n ; ++i){
            val = [mDataSource plotter:self dataSet:set dataValue:i];
            if(val>maxValue)maxValue = val;
            if(val<minValue)minValue = val;
        }
    }
    
    minValue -= fabs(.1*minValue);
    maxValue += fabs(.1*maxValue);
    
    [mYScale setRngLimitsLow:minValue*-10 withHigh:maxValue*10 withMinRng:10];
    [mXScale setRngLow:0.0 withHigh:maxN];
    [mYScale setRngLow:minValue withHigh:maxValue];
    
    [mXScale endDrag];
    [mYScale endDrag];
}

//**************************************************************************************
// Function:	CenterOnPeak
// Description: Center on the highest data value if data exists
//**************************************************************************************
- (IBAction) centerOnPeak:(id)sender
{
    double maxN  = 0;

    int n = [mDataSource numberOfPointsInPlot:self dataSet:0];
    if(n > maxN)maxN = n;
    /* determine the maximum value of the data */
    short i;
    double maxX = 0;
    double maxY = 0;
    double minPlotX = 0;
    double maxPlotX = [mDataSource numberOfPointsInPlot:self dataSet:0];

    if((maxPlotX < minPlotX) || (maxPlotX-minPlotX) < 1)return;
    for (i=minPlotX; i<maxPlotX; ++i) {
        double val = [mDataSource plotter:self dataSet:0 dataValue:i];
        if (val > maxY) {
            maxY = val;
            maxX = i;
        }
    }
    
    short rgn = maxPlotX-minPlotX;
    short new_lowX  = maxX - rgn/3;
    short new_highX = maxX + rgn/3;
    new_lowX  = new_lowX<=minPlotX?minPlotX:new_lowX;
    new_highX = new_highX>=maxPlotX?maxPlotX:new_highX;
    
    [mXScale setRngLow:new_lowX withHigh:new_highX];
    [self setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
   
}

- (IBAction) autoScale:(id)sender
{
    unsigned long	i;
    short           minX, maxX;
    double          t, minY, maxY, rngY;
    
    /* determine the maximum value of the data */
    minX = 0;
    maxX = [mDataSource numberOfPointsInPlot:self dataSet:0];

    minY = maxY = [mDataSource plotter:self dataSet:0 dataValue:minX];
 
    if(maxX < minX || (maxX-minX) < 1)return;
    
    for (i=minX+1; i<maxX; ++i) {
            t = [mDataSource plotter:self dataSet:0 dataValue:i];
            if (t > maxY) maxY = t;
            if (t < minY) minY = t;
    }
    rngY = maxY - minY;
    if(rngY<10)rngY = 10;

    /* set the scale to 20% beyond extremes */
    double mmx = maxY+0.2*rngY;
    mmx = mmx>250?mmx:250;
    double mmin = 0;
    if(minY<0)mmin = -250 - 0.2*rngY;
    maxX = [mDataSource numberOfPointsInPlot:self dataSet:0];
    [mYScale setRngLimitsLow:mmin withHigh:mmx withMinRng:25];
    [mYScale setRngLow:minY withHigh:maxY+0.2*rngY];
    [mXScale setRngLimitsLow:minX withHigh:maxX withMinRng:100];
    [mXScale setRngLow:0 withHigh:maxX];
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
}


- (IBAction) clearROI:(id)sender
{
    [self setRoiValid:NO];
    [self setNeedsDisplay:YES];
}

- (IBAction) analyze:(id)sender
{

    double		val, sumVal, sumValX, sumValX2;
    double		minVal, maxVal;
                    
    if(roiValid && analyze){
                       
        /* calculate various parameters */
        [self setRoiMinChannel:MIN(roi1,roi2)];
        [self setRoiMaxChannel:MAX(roi1,roi2)];

        sumVal = sumValX = sumValX2 = 0.0;
        //tdb implement for multiple datasets
        minVal = maxVal = [mDataSource plotter:self dataSet:0 dataValue:MIN(roi1,roi2)];
        
        long		x;
        for (x=roiMinChannel; x<roiMaxChannel; ++x) {
                val = [mDataSource plotter:self dataSet:0 dataValue:x];
                sumVal += val;
                sumValX += val * x;
                sumValX2 += val * x * x;
                if (val < minVal) minVal = val;
                if (val > maxVal) maxVal = val;
        }
        if (sumVal) {
                [self setCentroid:sumValX / sumVal];
                double t = sumValX2 * sumVal - sumValX * sumValX;
                if (t > 0) [self setSigma:sqrt(t) / sumVal];
                else [self setSigma:0];
        } else {
                [self setCentroid:0];
                [self setSigma:0];
        }
        
        if(roiMaxChannel != roiMinChannel){
                [self setAverage: sumVal / (roiMaxChannel - roiMinChannel)];
        }
        else {
                [self setAverage: sumVal];
        }

        [self setTotalSum:sumVal];


    }
}


- (BOOL) roiValid
{
	return roiValid;
}
- (void) setRoiValid:(BOOL)newRoiValid
{
	
	roiValid=newRoiValid;

	[[NSNotificationCenter defaultCenter]
			postNotificationName:ORPlotROIValidChangedNotification
			object:self
			userInfo: nil];    
}

- (double) roiMinChannel
{
	return roiMinChannel;
}
- (void) setRoiMinChannel:(double)newRoiMinChannel
{
	roiMinChannel=newRoiMinChannel;
	[[NSNotificationCenter defaultCenter]
			postNotificationName:ORPlotROIMinChangedNotification
			object:self
			userInfo: nil];    
}

- (double) roiMaxChannel
{
	return roiMaxChannel;
}
- (void) setRoiMaxChannel:(double)newRoiMaxChannel
{
	roiMaxChannel=newRoiMaxChannel;
	[[NSNotificationCenter defaultCenter]
			postNotificationName:ORPlotROIMaxChangedNotification
			object:self
			userInfo: nil];    
}

- (double) average
{
	return average;
}
- (void) setAverage:(double)newAverage
{
	average=newAverage;
	[[NSNotificationCenter defaultCenter]
			postNotificationName:ORPlotAverageChangedNotification
			object:self
			userInfo: nil];    
}


- (double) centroid
{
	return centroid;
}
- (void) setCentroid:(double)newCentroid
{
	centroid=newCentroid;
	[[NSNotificationCenter defaultCenter]
			postNotificationName:ORPlotCentroidChangedNotification
			object:self
			userInfo: nil];    
}

- (double) sigma
{
	return sigma;
}
- (void) setSigma:(double)newSigma
{
	sigma=newSigma;
	[[NSNotificationCenter defaultCenter]
			postNotificationName:ORPlotSigmaChangedNotification
			object:self
			userInfo: nil];    
}

- (double) totalSum
{
	return totalSum;
}
- (void) setTotalSum:(double)newTotalSum
{
	totalSum=newTotalSum;
	[[NSNotificationCenter defaultCenter]
			postNotificationName:ORPlotTotalSumChangedNotification
			object:self
			userInfo: nil];    
}

- (BOOL) analyze
{
	return analyze;
}
- (void) setAnalyze:(BOOL)newAnalyze
{
	analyze=newAnalyze;
	if(analyze)[self analyze:self];
}


@end

@implementation ORPlotter (private)

- (void) drawRectFake:(NSRect) rect
{
    short				x, y;
    NSBezierPath* theGrid;
    NSBezierPath* theDataPath;
    NSBezierPath* theROIPath;

    NSRect bounds = [self bounds];
    [backgroundColor set];
    [NSBezierPath fillRect:bounds];
    [[NSColor darkGrayColor] set];
    [NSBezierPath strokeRect:bounds];

	float ht = bounds.size.height - 1;
	float width = bounds.size.width - 1;


    //draw the Grid
    theGrid = [NSBezierPath bezierPath];
	[theGrid setLineWidth:.75];
    ht = [self frame].size.height;

	for(x=0;x<=width;x = x+width/10.){
		[theGrid moveToPoint:NSMakePoint(x,0)];
        [theGrid relativeLineToPoint:NSMakePoint(0,ht)];
    }

    width = [self frame].size.width;
	for(y=0;y<=ht;y = y+ht/10.){
        [theGrid moveToPoint:NSMakePoint(0,y)];
        [theGrid relativeLineToPoint:NSMakePoint(width,0)];
    }

    theDataPath = [NSBezierPath bezierPath];
    theROIPath = [NSBezierPath bezierPath];
	[theDataPath moveToPoint:NSMakePoint(0,0)];
    for (x=0;x<=width;x++) {
		float y = (x*x)/250.;
        [theDataPath lineToPoint:NSMakePoint(x,y)];
		if(x>=width/2 && x<=width/2+20){
			[theROIPath moveToPoint:NSMakePoint(x,0)];
			[theROIPath lineToPoint:NSMakePoint(x,y)];
		}
    }

    [gridColor set];
    [theGrid setLineWidth:.5];
    [theGrid stroke];


    [roiColor set];
    [theROIPath setLineWidth:.5];
    [theROIPath stroke];

    [dataColor set];
    [theDataPath setLineWidth:.5];
    [theDataPath stroke];


}


-(void)	mouseDown:(NSEvent*)theEvent
{
    NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if([self mouse:p inRect:[self bounds]]){
		roi1 = floor([mXScale convertPoint:p.x]+.5);
		roi2 = roi1;

		[self setRoiValid:YES];
	
		dragInProgress = YES;
        [self setNeedsDisplay:YES];
	}
}

-(void)	mouseDragged:(NSEvent*)theEvent
{
    if(dragInProgress){
        NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];

		roi2 = ceil([mXScale convertPoint:p.x]+.5);
		if(roi2<0)roi2=0;	
        [self setNeedsDisplay:YES];
    }
}


-(void)	mouseUp:(NSEvent*)theEvent
{
    if(dragInProgress){
        NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		roi2 = ceil([mXScale convertPoint:p.x]+.5);
		if(roi2<0)roi2=0;
					
        [self setNeedsDisplay:YES];
		[self analyze:self];
	}
}

- (unsigned long)  	secondsPerUnit:(id) aPlotter
{
	return [mDataSource secondsPerUnit:self];
}

@end

//
// Makes an NSArray work as an NSTableDataSource.
@implementation NSArray (NSTableDataSource)

// just returns the item for the right row
- (id)     tableView:(NSTableView *) aTableView
objectValueForTableColumn:(NSTableColumn *) aTableColumn
				 row:(int) rowIndex
{
	return [self objectAtIndex:rowIndex];
}

// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [self count];
}
@end

@implementation NSArray (OR1DPlotDataSource)
- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	return [self count];
}
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x
{
	return [[self objectAtIndex:x]floatValue];
}

- (unsigned long)  	secondsPerUnit:(id) aPlotter
{
	return 100;	 //default
}
@end


@implementation NSObject (OR1DPlotDataSource)
- (BOOL)   	willSupplyColors
{
	return NO;
}

- (NSColor*) colorForDataSet:(int)set
{
	return [NSColor redColor];
}


- (int) numberOfDataSetsInPlot:(id)aPlotter
{
	return 1;
}

- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	return 0;
}
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x
{
	return 0.0;
}

- (unsigned long)  	secondsPerUnit:(id) aPlotter
{
	return 100;	 //default
}

@end

