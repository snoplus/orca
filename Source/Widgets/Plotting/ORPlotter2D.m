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
#import "ORPlotter2D.h"
#import "ORAxis.h"
#import "ORCurve2D.h"
#import "ZFlowLayout.h"
#import "ORColorScale.h"
#import "CTGradient.h"
#import "ORGate2D.h"
#import "ORAnalysisPanel2D.h"

NSString* ORPlotter2DBackgroundColor    = @"ORPlotter2DBackgroundColor";
NSString* ORPlotter2DGridColor          = @"ORPlotter2DGridColor";
NSString* ORPlotter2DataColor           = @"ORPlotter2DataColor";
NSString* ORPlotter2DMousePosition      = @"ORPlotter2DMousePosition";


@interface ORPlotter2D (private)
- (void) drawRectFake:(NSRect) rect;
- (void) windowResizing:(NSNotification*)aNote;
- (void) resetDrawFlag;
- (void) reportMousePosition:(NSEvent*)theEvent;
- (void) tileAnalysisPanels;
@end

@implementation ORPlotter2D

+ (void) initialize
{
    if(self == [ORPlotter2D class]){
        [self setVersion:2];
    }
}

-(id)initWithFrame:(NSRect)aFrame
{
    if(self = [super initWithFrame:aFrame]){
        [self setDefaults];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [gradient release];
	[backgroundImage release];
    [curve release];
    [attributes release];
    [super dealloc];
}



- (void) awakeFromNib
{
    
    [self initCurve];
	[self setDefaults];

    //make sure the scales get drawn first so that the grid arrays have been
    //created before we are drawn.
    ORAxis* xs = [mXScale retain];
    [mXScale removeFromSuperviewWithoutNeedingDisplay];
    [[self superview] addSubview:xs positioned:NSWindowBelow relativeTo:self];
    [xs release];
    
    ORAxis* ys = [mYScale retain];
    [mYScale removeFromSuperviewWithoutNeedingDisplay];
    [[self superview] addSubview:ys positioned:NSWindowBelow relativeTo:self];
    [ys release];
    
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector: @selector( windowResizing: )
               name: NSWindowDidResizeNotification
             object: [self window] ];
    
	[self tileAnalysisPanels];
}


- (void) setDefaults
{
    
    [[self undoManager] disableUndoRegistration];
    if(!attributes){
        [self setAttributes:[NSMutableDictionary dictionary]];
        
        [self setBackgroundColor:[NSColor colorWithCalibratedRed:1. green:1. blue:1. alpha:0]];
        [self setGridColor:[NSColor grayColor]];
		[self  setDrawWithGradient:YES];
    }
    [curve setDefaults];
    [[self undoManager] enableUndoRegistration];
    [self setNeedsDisplay: YES];
}

- (NSUndoManager*) undoManager
{
    return [[[self window] windowController] undoManager];
}

- (void) initCurve
{
    [self setCurve:[ORCurve2D curve:0]];    

    if(mDataSource){
		[self addGateAction:self];
    }
}

- (void) setDrawWithGradient:(BOOL)flag
{
	useGradient = flag;
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
        [coder encodeObject:attributes forKey:@"ORPlotter2DAttributes"];
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
        [self setAttributes:[coder decodeObjectForKey:@"ORPlotter2DAttributes"]];
    }
    else {
        [self setAttributes:[coder decodeObject]];
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

- (ORColorScale*) colorScale
{
    return mColorScale;
}
- (void) setColorScale:(ORColorScale*)newColorScale
{
    [mColorScale autorelease];
    mColorScale=[newColorScale retain];
}

- (ORAxis*) zScale
{
    return mZScale;
}
- (void) setZScale:(ORAxis*)newZScale
{
    [mZScale autorelease];
    mZScale=[newZScale retain];
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

- (ORCurve2D*) curve
{
    return curve;
}
- (void) setCurve:(ORCurve2D*)aCurve
{
    [aCurve retain];
    [curve release];
    curve = aCurve;
}

- (void) setVectorMode:(BOOL)state
{
    vectorMode = state;
}

- (void) setBackgroundImage:(NSImage*)anImage
{
	[anImage retain];
	[backgroundImage release];
	backgroundImage = anImage;
}

- (void) drawRect:(NSRect) rect
{
    
    if(!mYScale && !mXScale){
        [self drawRectFake:rect];
        return;
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

	if(backgroundImage){
		[backgroundImage compositeToPoint:NSMakePoint(0,-1) operation:NSCompositeSourceOver];
	}
    
    
    if(!doNotDraw || ignoreDoNotDrawFlag){
        if(!vectorMode){
            [curve drawDataInPlot:self];
        }
        else {
            [curve drawVector:self];
        }
    }

    if(analysisDrawer && ([analysisDrawer state] == NSDrawerOpenState)){
        [curve doAnalysis:self];
    }

}

- (void)setIgnoreDoNotDrawFlag:(BOOL)aFlag
{
    ignoreDoNotDrawFlag = aFlag;
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
    [self initCurve];
    
    [self setNeedsDisplay: YES];
}

- (void)setBackgroundColor:(NSColor *)aColor
{
    [attributes setObject:[NSArchiver archivedDataWithRootObject:aColor] forKey:ORPlotter2DBackgroundColor];
	[gradient release];
	gradient = nil;
    [self setNeedsDisplay: YES];
}

-(NSColor*)backgroundColor
{
    return [NSUnarchiver unarchiveObjectWithData:[attributes objectForKey:ORPlotter2DBackgroundColor]];
}

-(NSColor*)colorForDataSet:(int) aDataSet
{
    NSMutableDictionary* colorDictionary = [attributes objectForKey:ORPlotter2DataColor];
    NSData* colorData = [colorDictionary objectForKey:[NSNumber numberWithInt:aDataSet]];
    if(!colorData)return [NSColor redColor];
    else return [NSUnarchiver unarchiveObjectWithData:colorData];
}

-(void) setDataColor:(NSColor*)aColor dataSet:(int) aDataSet
{
    NSMutableDictionary* colorDictionary = [attributes objectForKey:ORPlotter2DataColor];
    if(!colorDictionary){
        colorDictionary = [NSMutableDictionary dictionary];
        [attributes setObject:colorDictionary forKey:ORPlotter2DataColor];
    }
    [colorDictionary setObject:[NSArchiver archivedDataWithRootObject:aColor] forKey:[NSNumber numberWithInt:aDataSet]];
}


- (void)setGridColor:(NSColor *)aColor
{
    [attributes setObject:[NSArchiver archivedDataWithRootObject:aColor] forKey:ORPlotter2DGridColor];
    [self setNeedsDisplay: YES];
}

-(NSColor*)gridColor{
    return [NSUnarchiver unarchiveObjectWithData:[attributes objectForKey:ORPlotter2DGridColor]];
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
- (IBAction) zoomIn:(id)sender      { [mXScale zoomIn:self];  [mYScale zoomIn:self];     }
- (IBAction) zoomOut:(id)sender     { [mXScale zoomOut:self];  [mYScale zoomOut:self];     }

- (IBAction) resetScales:(id)sender
{
    int numSets = [mDataSource numberOfDataSetsInPlot:self];
    double maxValue = -9E99;
    int x,y;
    int set;
    unsigned short numberBinsPerSide;
    for(set=0;set<numSets;++set){
        unsigned short dataXMin,dataXMax,dataYMin,dataYMax;
        unsigned long* data = [mDataSource plotter:self dataSet:set numberBinsPerSide:&numberBinsPerSide];
        [mDataSource plotter:self dataSet:set xMin:&dataXMin xMax:&dataXMax yMin:&dataYMin yMax:&dataYMax];

        unsigned short val = 0;
        for (y=dataYMin; y<dataYMax;++y) {	
            for (x=dataXMin; x<dataXMax;++x) {	
                val = data[x+y*numberBinsPerSide];
                if(val>maxValue)maxValue = val;
            }
        }
    }
        
    [mYScale setRngLow:0.0 withHigh:numberBinsPerSide];
    [mXScale setRngLow:0.0 withHigh:numberBinsPerSide];
    [mZScale setRngLow:0.0 withHigh:maxValue];
    
    [mYScale rangingDonePostChange];
    [mXScale rangingDonePostChange];
    [mZScale rangingDonePostChange];
    
}


- (IBAction) autoScale:(id)sender
{
    int numSets = [mDataSource numberOfDataSetsInPlot:self];
    double maxValue = -9E99;
    int x,y;
    int set;
    unsigned short numberBinsPerSide;
    for(set=0;set<numSets;++set){
        unsigned short dataXMin,dataXMax,dataYMin,dataYMax;
        unsigned long* data = [mDataSource plotter:self dataSet:set numberBinsPerSide:&numberBinsPerSide];
        [mDataSource plotter:self dataSet:set xMin:&dataXMin xMax:&dataXMax yMin:&dataYMin yMax:&dataYMax];

        unsigned short val = 0;
        for (y=dataYMin; y<dataYMax;++y) {	
            for (x=dataXMin; x<dataXMax;++x) {	
                val = data[x+y*numberBinsPerSide];
                if(val>maxValue)maxValue = val;
            }
        }
    }
        
    [mZScale setRngLow:0.0 withHigh:maxValue];
    [mZScale rangingDonePostChange];
}

- (IBAction) copy:(id)sender
{	
    //declare our custom type.
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:self];
	NSMutableString* string = [NSMutableString string];
    
	int numberSets = [mDataSource numberOfDataSetsInPlot:self];
	int maxPoints = 0;
	int set;
	int i;
	for(set=0;set<numberSets;set++){
		int n = [mDataSource plotter:self numPointsInSet:set];

		if(n>maxPoints)maxPoints = n;
	}
	
	//make a string with the data
	for(i=0;i<maxPoints;i++){
		[string appendFormat:@"%d ",i];
		for(set=0;set<numberSets;set++){
			float xValue,yValue;

			[mDataSource plotter:self dataSet:set index:i x:&xValue y:&yValue];
			[string appendFormat:@"\t%f\t%f",xValue,yValue];
		}	
		[string appendFormat:@"\n"];
	}
	
    if([string length]){
		[pboard setData:[string dataUsingEncoding:NSASCIIStringEncoding] forType:NSStringPboardType]; 
	}
}

-(void)	mouseDown:(NSEvent*)theEvent
{
	if([theEvent clickCount]>=2){
		//if([mDataSource respondsToSelector:@selector(makeMainController)]){
		//	[mDataSource makeMainController];
		//}
	}
    else if([analysisDrawer state] == NSDrawerOpenState){
        if([theEvent modifierFlags] & NSShiftKeyMask){
            [self addGateAction:self];
        }
        [curve mouseDown:theEvent plotter:self];

    }
}

-(void)	mouseDragged:(NSEvent*)theEvent
{
	if([analysisDrawer state] == NSDrawerOpenState){
        [curve mouseDragged:theEvent plotter:self];
    }
}

-(void)	mouseUp:(NSEvent*)theEvent
{
	if([analysisDrawer state] == NSDrawerOpenState){
        [curve mouseUp:theEvent plotter:self];
    }
}

- (void) setShowActiveGate:(BOOL)flag
{
    [curve setShowActiveGate:flag];
    [self setNeedsDisplay:YES];
    [mYScale setNeedsDisplay:YES];
    [mXScale setNeedsDisplay:YES];
}

- (void) drawerDidOpen:(NSNotification*)aNote
{
    [self setNeedsDisplay:YES];
	
    [self setShowActiveGate:([analysisDrawer state] == NSDrawerOpenState)];

    [curve makeObjectsPerformSelector:@selector(doAnalysis:) withObject:self];
}

- (IBAction) addGateAction:(id)sender
{
	ORGate2D* aGate = [[ORGate2D alloc] initForCurve:curve];
	[curve addGate: aGate];	
	ORAnalysisPanel2D* analysisPanel = [ORAnalysisPanel2D panel];
	[aGate setAnalysis:analysisPanel];
	[analysisPanel setGate:aGate];
	[analysisView addSubview:[analysisPanel view]];
	[aGate release];
	[self tileAnalysisPanels];

}
- (IBAction) removeGateAction:(id)sender
{
    [curve removeActiveGate];	
	[self tileAnalysisPanels];
    [self setNeedsDisplay:YES];
}


- (IBAction) analyze:(id)sender
{
    [curve doAnalysis:self];
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
- (void) flagsChanged:(NSEvent *)theEvent
{
    cmdKeyIsDown = ([theEvent modifierFlags] & NSCommandKeyMask)!=0;
	[curve flagsChanged:theEvent plotter:self];
    [[self window] resetCursorRects];
    
}

- (void) resetCursorRects
{
    if([curve showActiveGate]){	
		
	}
}

@end

@implementation ORPlotter2D (private)

- (void) tileAnalysisPanels
{
    NSArray* subViews   = [analysisView subviews];
    float totalHeightNeeded = 0;
    NSEnumerator*   e   = [subViews objectEnumerator];
    NSView* aView;
    while(aView = [e nextObject]){
        totalHeightNeeded += [aView frame].size.height+5;
    }
    [analysisView setFrameSize: NSMakeSize([analysisView frame].size.width,totalHeightNeeded)];
	
    NSPoint origin = NSMakePoint(0,[analysisView frame].size.height+5);
    e              = [subViews objectEnumerator];
    while(aView = [e nextObject]){
        NSRect viewRect = [aView frame];
        origin.y -= viewRect.size.height+5;
        origin.x = 5;
        [aView setFrameOrigin: origin];
    }
}

- (void) reportMousePosition:(NSEvent*)theEvent
{
    NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if([self mouse:p inRect:[self bounds]]){
        int x = floor([[self xScale] convertPoint:p.x]+.5);
        int y = floor([[self yScale] convertPoint:p.y]+.5);
        [[NSNotificationCenter defaultCenter]
            postNotificationName:ORPlotter2DMousePosition
                          object: self 
                        userInfo: [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:x],@"x",[NSNumber numberWithFloat:y],@"y",nil]];
        
    }
}
//used only so there is some to draw when this object needs to be displayed
//in Interface Builder and there is no data source.
- (void) drawRectFake:(NSRect) rect
{    
    NSRect bounds = [self bounds];
    [[self backgroundColor] set];
    [NSBezierPath fillRect:bounds];
    
    NSImage		*result = nil;
    
    NSString*   path = [ [ NSBundle bundleForClass:[self class] ] pathForImageResource:@"Example2D" ];
    if ( nil != path ){
        // Make the image.
        result = [ [ [ NSImage alloc ] initWithContentsOfFile:path ] autorelease ];
        [result setName:@"Example2D" ];
    }
    [result setScalesWhenResized:YES];
    [result setSize:bounds.size];
    [result compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    
    [[NSColor darkGrayColor] set];
    [NSBezierPath strokeRect:bounds];
    
}

- (BOOL) acceptsFirstResponder
{
    return YES;
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

- (void) keyDown:(NSEvent*)theEvent
{
    //tab will shift to next plot curve -- shift/tab goes backward.
	unsigned short keyCode = [theEvent keyCode];
    if(keyCode == 48){
        if([theEvent modifierFlags] & NSShiftKeyMask){
            [curve decGate];
        }
        else {
            [curve incGate];
        }
                                    
        [self setNeedsDisplay:YES];
        [[self window]resetCursorRects];
    }
    
	else if(keyCode == 0){ //'a'
		[self autoScale:nil];
	}
	else if(keyCode == 15){ //'r'
		[self resetScales:nil];
	}
	else if(keyCode == 51){
        //delete key
        [self removeGateAction:self];
    }
	
	else [super keyDown:theEvent];
}


@end


@implementation NSObject (OR2DPlotDataSource1)
- (BOOL)   	willSupplyColors
{
    return NO;
}

- (int) numberOfDataSetsInPlot:(id)aPlotter
{
    return 1;
}

- (unsigned long*) plotter:(id) aPlotter dataSet:(int)set numberBinsPerSide:(unsigned short*)xValue
{
    return 0;
}
- (void) plotter:(id) aPlotter dataSet:(int)set xMin:(unsigned short*)minX xMax:(unsigned short*)maxX yMin:(unsigned short*)minY yMax:(unsigned short*)maxY
{
    *minX = 0;
    *maxX = 10;
    *minY = 0;
    *maxY = 10;
}

- (unsigned long) plotter:(id)aPlotter numPointsInSet:(int)set
{
    return 0;
}

- (BOOL) plotter:(id)aPlotter dataSet:(int)set index:(unsigned long)index x:(float*)xValue y:(float*)yValue
{
    *xValue = 0;
    *yValue = 0;
    return YES;
}

- (BOOL) plotter:(id)aPlotter dataSet:(int)set crossHairX:(float*)xValue crossHairY:(float*)yValue
{
    *xValue = 0;
    *yValue = 0;
    return NO;
}


- (NSColor*) plotter:(id)aPlotter colorForSet:(int)set

{
    return [NSColor redColor];
}

@end

