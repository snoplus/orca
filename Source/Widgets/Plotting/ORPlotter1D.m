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
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORCurve1D.h"
#import "ORGate1D.h"
#import "ORAnalysisPanel1D.h"
#import "ZFlowLayout.h"
#import "ORCARootServiceDefs.h"
#import "CTGradient.h"

NSString* ORPlotter1DDifferentiate		= @"ORPlotter1DDifferentiate";
NSString* ORPlotter1DAverageWindow		= @"ORPlotter1DAverageWindow";
NSString* ORPlotter1DBackgroundColor	= @"ORPlotter1DBackgroundColor";
NSString* ORPlotter1DGridColor			= @"ORPlotter1DGridColor";
NSString* ORPlotter1DataColor			= @"ORPlotter1DataColor";
NSString* ORPlotter1DActiveCurveChanged = @"ORPlotter1DActiveCurveChanged";
NSString* ORPlotter1DDifferentiateChanged = @"ORPlotter1DDifferentiateChanged";
NSString* ORPlotter1DAverageWindowChanged = @"ORPlotter1DAverageWindowChanged";


@interface ORPlotter1D (private)
- (void) drawRectFake:(NSRect) rect;
@end;

@implementation ORPlotter1D

+ (void) initialize
{
    if(self == [ORPlotter1D class]){
        [self setVersion:2];
    }
}

-(id)init
{
    if(self = [super init]){
		if(kORCARootFitNames[0] != nil){} //just to get rid of stupid compiler warning
		if(kORCARootFitShortNames[0] != nil){} //just to get rid of stupid compiler warning
		if(kORCARootFFTWindowOptions[0] != nil){} //just to get rid of stupid compiler warning
		if(kORCARootFFTWindowNames[0] != nil){} //just to get rid of stupid compiler warning
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [curves release];
    [attributes release];
    [gradient release];
	
    curves = nil;
    attributes = nil;
    
    [super dealloc];
}



- (void) awakeFromNib
{
    
    [self initCurves];
    
    //make sure the scales get drawn first so that the grid arrays have been
    //created before we are drawn.
	if(mXScale){
		ORAxis* xs = [mXScale retain];
		[mXScale removeFromSuperviewWithoutNeedingDisplay];
		[[self superview] addSubview:xs positioned:NSWindowBelow relativeTo:self];
		[xs release];
	}
	if(mYScale){
		ORAxis* ys = [mYScale retain];
		[mYScale removeFromSuperviewWithoutNeedingDisplay];
		[[self superview] addSubview:ys positioned:NSWindowBelow relativeTo:self];
		[ys release];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector: @selector( windowResizing: )
               name: NSWindowDidResizeNotification
             object: [self window] ];
    
    [nc addObserver:self
           selector: @selector( forcedUpdate: )
               name: ORForcePlotUpdateNotification
             object: nil ];

    //[self forcedUpdate:nil];
}

- (void) setDefaults
{
    
    [[self undoManager] disableUndoRegistration];
    if(!attributes){
        [self setAttributes:[NSMutableDictionary dictionary]];
        
        [self setBackgroundColor:[NSColor whiteColor]];
        [self setGridColor:[NSColor grayColor]];
        [self setDataColor:[NSColor redColor] dataSet:0];
        [self setDataColor:[NSColor greenColor] dataSet:1];
        [self setDataColor:[NSColor blueColor] dataSet:2];
        [self setDataColor:[NSColor yellowColor] dataSet:3];
        [self setDataColor:[NSColor brownColor] dataSet:4];
        [self setDataColor:[NSColor blackColor] dataSet:5];
    }
    [curves makeObjectsPerformSelector:@selector(setDefaults)];
    [[self undoManager] enableUndoRegistration];
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
}


- (void) setDrawWithGradient:(BOOL)flag
{
	useGradient = flag;
}

- (NSUndoManager*) undoManager
{
    return [[[self window] windowController] undoManager];
}

- (void) initCurves
{
    [self setCurves:[NSMutableArray array]];
    
    if(mDataSource){
        int n = [mDataSource numberOfDataSetsInPlot:self];
        int i;
        for(i=0;i<n;i++){
            ORCurve1D* aCurve = [ORCurve1D curve:i];
            [curves addObject: aCurve];
            activeCurveIndex = i;
            [self addGateAction:self];
        } 
    }
    activeCurveIndex = 0;
}

- (id) activeCurve
{
	if([curves count]){
		return [curves objectAtIndex:activeCurveIndex];
	}
	else return nil;
}

- (int)activeCurveIndex 
{
    return activeCurveIndex;
}

- (void)setActiveCurveIndex:(int)anactiveCurveIndex 
{
    activeCurveIndex = anactiveCurveIndex;
    
    [[NSNotificationCenter defaultCenter]
            postNotificationName:ORPlotter1DActiveCurveChanged
                          object: self 
                        userInfo: nil];
                        
    [self setShowActiveGate:([analysisDrawer state] == NSDrawerOpenState)];
}


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
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


- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    if([coder allowsKeyedCoding]){
        [coder encodeObject:attributes forKey:@"ORPlotter1DAttributes"];
    }
    else {
        [coder encodeObject:attributes];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    self =  [super initWithCoder:coder];
    [[self undoManager] disableUndoRegistration];
    if([coder allowsKeyedCoding]){
        [self setAttributes:[coder decodeObjectForKey:@"ORPlotter1DAttributes"]];
    }
    else {
        [self setAttributes:[coder decodeObject]];
    }
	if(!attributes)    [self setDefaults];
	if([self averageWindow]==0){
		[self setAverageWindow:10];
	}
	
    [[self undoManager] enableUndoRegistration];
    return self;
}
- (ORAxis*) xScale
{
    return mXScale;
}
- (void) setXScale:(ORAxis*)newXScale
{
    [mXScale autorelease];
    mXScale=[newXScale retain];
}

- (ORAxis*) yScale
{
    return mYScale;
}
- (void) setYScale:(ORAxis*)newYScale
{
    [mYScale autorelease];
    mYScale=[newYScale retain];
}

- (double) plotHeight
{
    return [self bounds].size.height-1;
}

- (double) plotWidth
{
    return [self bounds].size.width-1;
}

- (double) channelWidth
{
    return ([self bounds].size.width - 1) / [mXScale valueRange];
}

- (NSArray*) curves
{
    return curves;
}
- (void) setCurves:(NSMutableArray*)anArray
{
    [anArray retain];
    [curves release];
    curves = anArray;
}

- (void) drawRect:(NSRect) rect
{
    if(!mYScale && !mXScale && !mDataSource){
        [self drawRectFake:rect];
        return;
    }
    if(!curves){
		[self initCurves];
	}
    
    NSRect bounds = [self bounds];

	if(useGradient){
		if(!gradient){
			float red,green,blue,alpha;
			NSColor* color = [self backgroundColor];
			[color getRed:&red green:&green blue:&blue alpha:&alpha];
		
			red *= .75;
			green *= .75;
			blue *= .75;
			//alpha = .75;
		
			NSColor* endingColor = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
		
			[gradient release];
			gradient = [[CTGradient gradientWithBeginningColor:color endingColor:endingColor] retain];
		}
		[gradient fillRect:bounds angle:270.];
	}
	else {
		[[self backgroundColor] set];
		[NSBezierPath fillRect:bounds];
	}
	[[NSColor darkGrayColor] set];
	[NSBezierPath strokeRect:bounds];
    
    
    //draw the Grid
    [mXScale drawGridInFrame:[self frame] usingColor:[self gridColor]];
    [mYScale drawGridInFrame:[self frame] usingColor:[self gridColor]];
    [mXScale drawMarkInFrame:[self frame] usingColor:[NSColor blackColor]];
    [mYScale drawMarkInFrame:[self frame] usingColor:[NSColor blackColor]];
    
    if(!doNotDraw || ignoreDoNotDrawFlag){
            [curves makeObjectsPerformSelector:@selector(drawDataInPlot:) withObject:self];
    }
        
    if(analysisDrawer && ([analysisDrawer state] == NSDrawerOpenState)){
        [curves makeObjectsPerformSelector:@selector(doAnalysis:) withObject:self];
    }

}
- (void) xAndYAutoScale
{
	long theMin;
	long theMax;
	[self getNonZeroAxisRangeMin:&theMin max:&theMax];
	if(theMin != theMax){
		long tempRange = theMax - theMin;
		long theCenter = theMin + tempRange/2;
		tempRange = tempRange + tempRange*.2;
		long theRange = MAX(tempRange , 50);
	
		[mXScale setRngLow:theCenter - theRange/2 withHigh:theCenter + theRange/2];
	}
	[self autoScale:nil];    
}

- (void) getNonZeroAxisRangeMin:(long*)xMin max:(long*)xMax
{
	*xMin = 0;
	*xMax = 0;
	unsigned  long tempXMin = 0xffffffff;
	unsigned long tempXMax = 0;
	int numDataSets = [mDataSource numberOfDataSetsInPlot:self];
	int set;
	for(set = 0;set<numDataSets;set++){
		int numPoints = [mDataSource numberOfPointsInPlot:self dataSet:set];
		if(numPoints == 0) continue;
		else {
			int i;
			for(i=0;i<numPoints;i++){
				double val = [mDataSource plotter:self dataSet:set dataValue:i];
				if(val != 0){
					if(i <= tempXMin)tempXMin = i; //remember, we're storing the min and max indexes NOT the values
					if(i >= tempXMax)tempXMax = i;
				}
			}
		}
	}
	if(tempXMin != 0xffffffff)*xMin = tempXMin;
	if(tempXMax != 0)		  *xMax = tempXMax;
}

- (void) drawerDidOpen:(NSNotification*)aNote
{
    [self setNeedsDisplay:YES];
    [curves makeObjectsPerformSelector:@selector(doAnalysis:) withObject:self];
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
    mDataSource = d;
    if(d){  
        [self initCurves];
    
        [self setNeedsDisplay:YES];
        [mYScale setNeedsDisplay:YES];
        [mXScale setNeedsDisplay:YES];
        doNotDraw = NO;
    }
    else {
        [self setCurves:nil];
        doNotDraw = YES;
    }
}

- (void)setDifferentiate:(BOOL)state
{
    [attributes setObject:[NSNumber numberWithBool:state] forKey:ORPlotter1DDifferentiate];
    [[NSNotificationCenter defaultCenter]
            postNotificationName:ORPlotter1DDifferentiateChanged
                          object: self 
                        userInfo: nil];
	
	[self setNeedsDisplay:YES];
}

- (BOOL) differentiate
{
	return [[attributes objectForKey:ORPlotter1DDifferentiate] intValue];
}

- (void) setAverageWindow:(int)size
{
	if(size<1)size = 1;
	if(size>1000)size = 1000;
	
    [attributes setObject:[NSNumber numberWithInt:size] forKey:ORPlotter1DAverageWindow];
    [[NSNotificationCenter defaultCenter]
            postNotificationName:ORPlotter1DAverageWindowChanged
                          object: self 
                        userInfo: nil];
	
	[self setNeedsDisplay:YES];
}

- (int) averageWindow
{
	return [[attributes objectForKey:ORPlotter1DAverageWindow] intValue];
}


- (void)setBackgroundColor:(NSColor *)aColor
{
    [attributes setObject:[NSArchiver archivedDataWithRootObject:aColor] forKey:ORPlotter1DBackgroundColor];
	[gradient release];
	gradient = nil;
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
}

-(NSColor*)backgroundColor
{
    return [NSUnarchiver unarchiveObjectWithData:[attributes objectForKey:ORPlotter1DBackgroundColor]];
}

-(NSColor*)colorForDataSet:(int) aDataSet
{

	if([mDataSource willSupplyColors])  return [mDataSource colorForDataSet:aDataSet];
	else {
        NSMutableDictionary* colorDictionary = [attributes objectForKey:ORPlotter1DataColor];
        NSData* colorData = [colorDictionary objectForKey:[NSNumber numberWithInt:aDataSet]];
        if(!colorData)return [NSColor redColor];
        else return [NSUnarchiver unarchiveObjectWithData:colorData];
    }
}

-(void) setDataColor:(NSColor*)aColor dataSet:(int) aDataSet
{
    NSMutableDictionary* colorDictionary = [attributes objectForKey:ORPlotter1DataColor];
    if(!colorDictionary){
        colorDictionary = [NSMutableDictionary dictionary];
        [attributes setObject:colorDictionary forKey:ORPlotter1DataColor];
    }
    [colorDictionary setObject:[NSArchiver archivedDataWithRootObject:aColor] forKey:[NSNumber numberWithInt:aDataSet]];
	[self setNeedsDisplay:YES];
}

- (void)setIgnoreDoNotDrawFlag:(BOOL)aFlag
{
    ignoreDoNotDrawFlag = aFlag;
}

- (void)setGridColor:(NSColor *)aColor
{
    [attributes setObject:[NSArchiver archivedDataWithRootObject:aColor] forKey:ORPlotter1DGridColor];
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
}

-(NSColor*)gridColor{
    return [NSUnarchiver unarchiveObjectWithData:[attributes objectForKey:ORPlotter1DGridColor]];
}

-(void)setFrame:(NSRect)aFrame
{
    [super setFrame:aFrame];
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
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


- (IBAction) addGateAction:(id)sender
{
    ORGate1D* aGate = [ORGate1D gateForCurve:[self activeCurve] plot:self];
    [[self activeCurve] addGate: aGate];	
    ORAnalysisPanel1D* analysisPanel = [ORAnalysisPanel1D panel];
    [aGate setAnalysis:analysisPanel];
    [analysisPanel setGate:aGate];
    [analysisView setSizing:ZMakeFlowLayoutSizing( [[analysisPanel view] frame].size, 10, 0, NO )];
    [analysisView addSubview:[analysisPanel view]];
    
}
- (IBAction) removeGateAction:(id)sender
{
    [[self activeCurve] removeActiveGate];	
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
}

- (IBAction) differentiateAction:(id)sender
{
	[self setDifferentiate:[sender intValue]];
}

- (IBAction) averageWindowAction:(id)sender
{
	[self setAverageWindow:[sender intValue]];
}

- (IBAction) resetScales:(id)sender
{
    int          i, minX, maxX;
    double          t, minY, maxY;
    double	    rngY = 0;
    
    /* determine the maximum value of the data */
    minX = 0;
    maxX = [mDataSource numberOfPointsInPlot:self dataSet:activeCurveIndex];
    minY = 1e100;
    maxY = -1e100;
	
    for (i=minX+1; i<maxX; ++i) {
        t = [mDataSource plotter:self dataSet:activeCurveIndex dataValue:i];
        if (t > maxY) maxY = t;
        if (t < minY) minY = t;
    }
    rngY = maxY - minY;
    if(rngY<10)rngY = 10;
    
    
    if(maxX < minX || (maxX-minX) < 1)return;
    
    /* set the scale to 20% beyond extremes */
    double mmax = maxY+0.2*rngY;
    mmax = mmax>250?mmax:250;
    double mmin = 0;
    if(minY<0)mmin = -250 - 0.2*rngY;
    
    [mYScale setRngLimitsLow:MIN(mmin,0) withHigh:5E9 withMinRng:25];
    [mYScale setRngLow:MIN(mmin,0) withHigh:maxY+0.2*rngY];
    [mXScale setRngLimitsLow:minX withHigh:maxX withMinRng:100];
    [mXScale setRngLow:0 withHigh:maxX];
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
    
    [mYScale rangingDonePostChange];
    [mXScale rangingDonePostChange];
    
}

//**************************************************************************************
// Function:	CenterOnPeak
// Description: Center on the highest data value if data exists
//**************************************************************************************
- (IBAction) centerOnPeak:(id)sender
{
    
    double maxX = 0;
    double maxY = -1e100;
    double minPlotX = 0;
    double maxPlotX = 0;
    int xMin = [mXScale minValue];
    int xMax = [mXScale maxValue];
    int oldCenter = xMin+(xMax-xMin)/2;
    
    minPlotX = 0;
    maxPlotX = MAX(maxPlotX,[mDataSource numberOfPointsInPlot:self dataSet:activeCurveIndex]);    
    
    int i;
    for (i=minPlotX; i<maxPlotX; ++i) {
        double val = [mDataSource plotter:self dataSet:activeCurveIndex dataValue:i];
        if (val > maxY) {
            maxY = val;
            maxX = i;
        }
    }
    //maxX is now the channel containing the maxY value of this plot.
    double dx = oldCenter-maxX;
    int new_lowX  = xMin - dx;
    int new_highX = xMax - dx;
    
    [mXScale setRngLow:new_lowX withHigh:new_highX];
    [self setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
    
    [mXScale rangingDonePostChange];
    
}

- (IBAction) xAndYAutoScale:(id)sender
{
	BOOL useTime = [mDataSource useXYTimePlot];
	if(!useTime)[self autoScale:nil];
	[self autoScaleXAxis];
}

- (void) autoScaleXAxis
{

	//only makes sense to call if using XYPlot
	if(![mDataSource useXYTimePlot] && ![mDataSource useXYPlot])return;
	int numPoints = [mDataSource numberOfPointsInPlot:self dataSet:activeCurveIndex];
	int i;
	float xValue,yValue;
	double minXValue = 9.99E99;
	double maxXValue = -9.99E99;
	BOOL useTime = [mDataSource useXYTimePlot];
	for (i=0; i<numPoints;++i) {
		if(!useTime){
			[mDataSource plotter:self dataSet:activeCurveIndex index:i x:&xValue y:&yValue];
		}
		else {
			unsigned long theTime;
			[mDataSource plotter:self dataSet:activeCurveIndex index:i time:&theTime y:&yValue];
			xValue = (double)theTime;
			NSLog(@"%d %d %f\n",i,theTime,xValue);
		}
		if(xValue<minXValue)minXValue = xValue;
		if(xValue>maxXValue)maxXValue = xValue;
	}
    [mXScale setRngLimitsLow:minXValue withHigh:maxXValue+5000 withMinRng:100];
    [mXScale setOrigin:minXValue];
    [self setNeedsDisplay:YES];
    [mXScale rangingDonePostChange];
}


- (IBAction) autoScale:(id)sender
{
    int          i, minX, maxX;
    double          t, minY, maxY;
    double	    rngY = 0;
    
    /* determine the maximum value of the data */
    minX = [mXScale minValue];
    maxX = MIN([mDataSource numberOfPointsInPlot:self dataSet:activeCurveIndex],[mXScale maxValue]);
	BOOL differentiate		= [self differentiate];
	double averageWindow	= [self averageWindow];
	if(differentiate){
		minX += averageWindow/2;
		maxX -= averageWindow/2;
	}
    minY = 1e100;
    maxY = -1e100;
	
	double forwardSum = 0;
	double backwardSum = 0;
	int n = averageWindow/2;
	double dn = (double)n;
	
	BOOL firstTime = YES;
	if(dn!=0){
		for (i=minX+1; i<maxX; ++i) {
			if(!differentiate){
				t = [mDataSource plotter:self dataSet:activeCurveIndex dataValue:i];
			}
			else {
				if(!firstTime){
					firstTime = NO;
					int j;
					for(j = 0;j<n;j++) forwardSum  += [mDataSource plotter:self dataSet:activeCurveIndex dataValue:i+j];
					for(j = 1;j<n;j++) backwardSum += [mDataSource plotter:self dataSet:activeCurveIndex dataValue:i-j];
				}
				else {
					//if not first time just adjust the average using the new location	
					forwardSum  = forwardSum  - [mDataSource plotter:self dataSet:activeCurveIndex dataValue:i-1]/dn + [mDataSource plotter:self dataSet:activeCurveIndex dataValue:i+n-1]/dn;
					backwardSum = backwardSum + [mDataSource plotter:self dataSet:activeCurveIndex dataValue:i-1]/(dn-1) - [mDataSource plotter:self dataSet:activeCurveIndex dataValue:i-n]/(dn-1);
				}
				t = forwardSum/dn - backwardSum/(dn-1);
			}
			if (t > maxY) maxY = t;
			if (t < minY) minY = t;
		}
	}
    rngY = maxY - minY;
    if(rngY<10)rngY = 10;
    
    
    if(maxX < minX || (maxX-minX) < 1)return;
    
    /* set the scale to 20% beyond extremes */
    double mmax = maxY+0.2*rngY;
    //double mmin = minY - 0.2*rngY;
    //mmax = mmax>250?mmax:250;
   // double mmin = 0;
   // if(minY<0)mmin = -250 - 0.2*rngY;
    
    [mYScale setRngLimitsLow:-5E6 withHigh:5E9 withMinRng:25];
    [mYScale setRngLow:MAX(0,minY) withHigh:mmax];
    //[mXScale setRngLimitsLow:minX withHigh:maxX withMinRng:100];
    //[mXScale setRngLow:0 withHigh:maxX];
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
   // [mXScale setNeedsDisplay:YES];
    
    [mYScale rangingDonePostChange];
   // [mXScale rangingDonePostChange];
    
}


- (void)setShowActiveGate:(BOOL)flag
{
    [[self activeCurve] setShowActiveGate:flag plotter:self];
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
}


- (IBAction)copy:(id)sender
{
	if([mDataSource useXYPlot])return;
	
    //declare our custom type.
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:self];
	NSMutableString* string = [NSMutableString string];
    
	int numberSets = [mDataSource numberOfDataSetsInPlot:self];
	int maxPoints = 0;
	int set;
	int i;
	for(set=0;set<numberSets;set++){
		int n = [mDataSource numberOfPointsInPlot:self dataSet:set];
		if(n>maxPoints)maxPoints = n;
	}
	
	//make a string with the data
	float data;
	for(i=0;i<maxPoints;i++){
		[string appendFormat:@"%d ",i];
		for(set=0;set<numberSets;set++){
			if([mDataSource useDataObject:self dataSet:set]){
				unsigned long offset = [mDataSource startingByteOffset:self dataSet:set];
				char* p = (char*)[[mDataSource plotter:self dataSet:set] bytes] + offset;
				switch([mDataSource unitSize:self dataSet:set]){
					case 1: data = *((char*)p + i);  break;
					case 2: data = *((short*)p + i); break;
					case 4: data = *((long*)p + i);  break;
				}
				[string appendFormat:@"\t%f",data];
			}
			else {
				if([mDataSource useXYTimePlot]){
					unsigned long secs;
					[mDataSource plotter:self dataSet:set index:i time:&secs y:&data];
					NSCalendarDate* theDate = [NSCalendarDate dateWithTimeIntervalSince1970:secs];
					[theDate setCalendarFormat:@"%m/%d %H:%M:%S"];
					[string appendFormat:@"\t%@\t%f",theDate,data];
				}
				else {
					data =  [mDataSource plotter:self dataSet:set dataValue:i];
					[string appendFormat:@"\t%f",data];
				}
			}
		}	
		[string appendFormat:@"\n"];
	}
	

    if([string length]){
		[pboard setData:[string dataUsingEncoding:NSASCIIStringEncoding] forType:NSStringPboardType]; 
	}
}

- (IBAction) clearActiveGate:(id)sender
{
    [[self activeCurve] clearActiveGate];
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
}

- (IBAction) clearActiveCurveGates:(id)sender
{
    [[self activeCurve] clearAllGates];
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
}

- (IBAction) clearAllGates:(id)sender
{
    [curves makeObjectsPerformSelector:@selector(clearAllGates) withObject:nil];
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
}

- (IBAction) analyze:(id)sender
{
    [curves makeObjectsPerformSelector:@selector(doAnalysis:) withObject:self];
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

- (void) forcedUpdate:(NSNotification*)aNote
{
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
}

- (void) windowResizing:(NSNotification*)aNote
{
    if(!ignoreDoNotDrawFlag){
        doNotDraw = YES;
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self setNeedsDisplay:YES];
        [self performSelector:@selector(resetDrawFlag) withObject:nil afterDelay:0];
    }
}

- (void) resetDrawFlag
{
    doNotDraw = NO; 
    [self setNeedsDisplay:YES];
}

- (void) setXLabel:(NSString*)xLabel yLabel:(NSString*)yLabel
{
	[mXScale setLabel:xLabel];
	[mYScale setLabel:yLabel];
}
	
- (void) doFFT:(id)userInfo
{
	NSRange dataFFTRange = NSMakeRange([[[self activeCurve] activeGate] gateMinChannel],abs([[[self activeCurve] activeGate] gateMaxChannel] - [[[self activeCurve] activeGate] gateMinChannel]));
	NSArray* dataPoints = [[curves objectAtIndex:activeCurveIndex] dataPointArray:self range:dataFFTRange];
	if([dataPoints count]){
		NSMutableDictionary* serviceRequest = [NSMutableDictionary dictionary];
		[serviceRequest setObject:@"OROrcaRequestFFTProcessor" forKey:@"Request Type"];
		[serviceRequest setObject:@"Normal"					 forKey:@"Request Option"];
		
			NSMutableDictionary* requestInputs = [NSMutableDictionary dictionary];
			[requestInputs setObject:dataPoints forKey:@"Waveform"];
			NSString* fftOption = kORCARootFFTNames[[[userInfo objectForKey:ORCARootServiceFFTOptionKey] intValue]];
			int i = [[userInfo objectForKey:ORCARootServiceFFTWindowKey] intValue];
			if(i>0){
				fftOption = [fftOption stringByAppendingString:@","];
				fftOption = [fftOption stringByAppendingString:kORCARootFFTWindowOptions[i]];
			}
			[requestInputs setObject:fftOption forKey:@"FFTOptions"];
			
		[serviceRequest setObject:requestInputs	forKey:@"Request Inputs"];

		//we do this via a notification so that this object (which is a widget) is decoupled from the ORCARootService object.
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:serviceRequest forKey:ServiceRequestKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServiceRequestNotification object:self userInfo:userInfo];
	}
}

- (void) processResponse:(NSDictionary*)aResponse
{
	BOOL responseOK = ([aResponse objectForKey:@"Request Error"] == nil);
	if(responseOK){
		//do this with a notification so this plotter widget doesn't have any extra dependencies
		NSMutableDictionary* reponseInfo = [NSMutableDictionary dictionaryWithObject:aResponse forKey:ORCARootServiceResponseKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServiceReponseNotification object:self userInfo:reponseInfo];
	}
	else {
		NSLog(@"----------------------------------------\n");
		NSLog(@"Error returned for Fit on %@\n",[[[self dataSource] window] title]);
		NSLog(@"Error message: %@\n",[aResponse objectForKey:@"Request Error"]);
		NSLog(@"----------------------------------------\n");
	}
}

@end

@implementation ORPlotter1D (private)

//used only so there is some to draw when this object needs to be displayed
//in Interface Builder and there is no data source.
- (void) drawRectFake:(NSRect) rect
{
    double   x, y;
    NSBezierPath* theGrid;
    NSBezierPath* theDataPath;
    NSBezierPath* theGatePath;
    
    NSRect bounds = [self bounds];

    [[NSColor whiteColor] set];
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
    theGatePath = [NSBezierPath bezierPath];
    [theDataPath moveToPoint:NSMakePoint(0,0)];
    for (x=0;x<=width;x++) {
        float y = (x*x)/250.;
        [theDataPath lineToPoint:NSMakePoint(x,y)];
        if(x>=width/2 && x<=width/2+20){
            [theGatePath moveToPoint:NSMakePoint(x,0)];
            [theGatePath lineToPoint:NSMakePoint(x,y)];
        }
    }
    
    [[NSColor lightGrayColor] set];
    [theGrid setLineWidth:.5];
    [theGrid stroke];
    
    
    [[NSColor lightGrayColor] set];
    [theGatePath setLineWidth:.5];
    [theGatePath stroke];
    
    [[NSColor greenColor] set];
    [theDataPath setLineWidth:.5];
    [theDataPath stroke];
    
    
}
- (BOOL) acceptsFirstResponder
{
    return YES;
}

- (void) keyDown:(NSEvent*)theEvent
{
    //tab will shift to next plot curve -- shift/tab goes backward.
	unsigned short keyCode = [theEvent keyCode];
    if(keyCode == 48){
        int index = activeCurveIndex;
        if([theEvent modifierFlags] & NSShiftKeyMask){
            if([[self activeCurve] decGate]){
                --index;
                if(index<0)index = [curves count]-1;
            }
        }
        else {
            if([[self activeCurve] incGate]){
                index = (index+1)%[curves count];
            }
        }
        [self setActiveCurveIndex:index];
                                    
        [self setNeedsDisplay:YES];
        [mYScale setNeedsDisplay:YES];
        [mXScale setNeedsDisplay:YES];
        [[self window]resetCursorRects];
    }
    
    
    else if(keyCode == 51){
        //delete key
        [self removeGateAction:self];
    }
    
	else if(keyCode == 0){ //'a'
		[self autoScale:nil];
	}
	else if(keyCode == 15){ //'r'
		[self resetScales:nil];
	}
	else if(keyCode == 8){ //'c'
		[self centerOnPeak:nil];
	}
	
    else {
        [[self activeCurve] keyDown:theEvent];
        [self setNeedsDisplay:YES];
        [mYScale setNeedsDisplay:YES];
        [mXScale setNeedsDisplay:YES];
    }
}

-(void)	mouseDown:(NSEvent*)theEvent
{
    if(analysisView){
        if([theEvent modifierFlags] & NSShiftKeyMask){
            [self addGateAction:self];
            
        }
        [[self activeCurve] mouseDown:theEvent plotter:self];

    }
}

-(void)	mouseDragged:(NSEvent*)theEvent
{
    if(analysisView){
        [[self activeCurve] mouseDragged:theEvent plotter:self];
    }
}

- (void)flagsChanged:(NSEvent *)theEvent
{
    shiftKeyIsDown = ([theEvent modifierFlags] & NSShiftKeyMask)!=0;
    [[self window] resetCursorRects];
    
}


-(void)	mouseUp:(NSEvent*)theEvent
{
	[NSCursor pop];
    [[self activeCurve] mouseUp:theEvent plotter:self];
    if(([theEvent modifierFlags] & NSShiftKeyMask)==0){
        [[self window] resetCursorRects];   
    }
}

- (unsigned long) secondsPerUnit:(id) aPlotter
{
    return [mDataSource secondsPerUnit:self];
}

- (void) resetCursorRects
{
    if([[self activeCurve] showActiveGate]){
        if(!shiftKeyIsDown){
            NSRect aRect;
            float x1 = [mXScale getPixAbs:[[[self activeCurve] activeGate] gateMinChannel]];
            float x2 = [mXScale getPixAbs:[[[self activeCurve] activeGate] gateMaxChannel]];
            
            aRect = NSMakeRect(x1-2,0,4,[self plotHeight]);
            [self addCursorRect:aRect cursor:[NSCursor resizeLeftRightCursor]];
            
            aRect = NSMakeRect(x1+1,0,x2-x1-4,[self plotHeight]);
            [self addCursorRect:aRect cursor:[NSCursor openHandCursor]];
            
            aRect = NSMakeRect(x2-2,0,4,[self plotHeight]);
            [self addCursorRect:aRect cursor:[NSCursor resizeLeftRightCursor]];
            
            aRect = NSMakeRect(x1-2,0,x2-x1+4,[self plotHeight]);
            [self addCursorRect:aRect cursor:[NSCursor arrowCursor]];
            
        }
		else {
            [self addCursorRect:[self bounds] cursor:[NSCursor arrowCursor]];
		}
    }
}


- (void) setXLabel:(NSString*)xLabel yLabel:(NSString*)yLabel
{
	[mXScale setLabel:xLabel];
	[mYScale setLabel:yLabel];
}	


@end


@implementation NSArray (OR1DPlotDataSource1)
- (int) numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
    return [self count];
}
- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x
{
    return [[self objectAtIndex:x]floatValue];
}

- (unsigned long) secondsPerUnit:(id) aPlotter
{
    return 100;	 //default
}
@end


@implementation NSObject (OR1DPlotDataSource1)
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

- (unsigned long) secondsPerUnit:(id) aPlotter
{
    return 100;	 //default
}

//if the datasource will supply data as an NSData object.... 
- (BOOL) useDataObject:(id)aPlotter  dataSet:(int)set
{
	return NO;
}
- (NSData*) plotter:(id) aPlotter dataSet:(int)set 
{
	return nil;
}

- (unsigned long) startingByteOffset:(id)aPlotter  dataSet:(int)set
{
	return 0;
}
- (unsigned short) unitSize:(id)aPlotter  dataSet:(int)set
{
	return sizeof(char);
}

//if the datasource will supply data piece by piece....
- (int) numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
    return 0;
}
- (float) plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x
{
    return 0.0;
}
- (BOOL) useXYPlot
{
	return NO;
}

- (BOOL) useXYTimePlot
{
	return NO;
}

- (float) plotterMaxX:(id)aPlotter
{
	return 0;
}
- (float) plotterMinX:(id)aPlotter
{
 return 0;
}

- (NSTimeInterval) plotterStartTime:(id)aPlotter
{
	return [[NSDate date] timeIntervalSince1970];
}

- (void)  plotter:(id) aPlotter dataSet:(int)set index:(int)i x:(float*)x y:(float*)y
{
	*x = 0;
	*y = 0;
}
- (void)  plotter:(id) aPlotter dataSet:(int)set index:(int)i time:(unsigned long*)x y:(float*)y
{
	*x = 0;
	*y = 0;
}

- (BOOL) useUnsignedValues
{
	return NO;
}

@end

