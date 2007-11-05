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

NSString* ORPlotter2DBackgroundColor    = @"ORPlotter2DBackgroundColor";
NSString* ORPlotter2DGridColor          = @"ORPlotter2DGridColor";
NSString* ORPlotter2DataColor           = @"ORPlotter2DataColor";
NSString* ORPlotter2DMousePosition      = @"ORPlotter2DMousePosition";


@interface ORPlotter2D (private)
- (void) drawRectFake:(NSRect) rect;
- (void) windowResizing:(NSNotification*)aNote;
- (void) resetDrawFlag;
- (void) reportMousePosition:(NSEvent*)theEvent;
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
    [curve release];
    [attributes release];
    [super dealloc];
}



- (void) awakeFromNib
{
    
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
    
    [self initCurve];
    [self setDefaults];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector: @selector( windowResizing: )
               name: NSWindowDidResizeNotification
             object: [self window] ];
    
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

- (void) drawRect:(NSRect) rect
{
    
    if(!mYScale && !mXScale){
        [self drawRectFake:rect];
        return;
    }
    
    
    NSRect bounds = [self bounds];
    [[self backgroundColor] set];
    [NSBezierPath fillRect:bounds];
    [[NSColor darkGrayColor] set];
    [NSBezierPath strokeRect:bounds];
    
    
    if(!doNotDraw || ignoreDoNotDrawFlag){
        if(!vectorMode){
            [curve drawDataInPlot:self];
        }
        else {
            [curve drawVector:self];
        }
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

-(void)	mouseDown:(NSEvent*)theEvent
{
    [self reportMousePosition:theEvent];
}

-(void)	mouseDragged:(NSEvent*)theEvent
{
    [self reportMousePosition:theEvent];
}

@end

@implementation ORPlotter2D (private)
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
	unsigned short keyCode = [theEvent keyCode];
    
	if(keyCode == 0){ //'a'
		[self autoScale:nil];
	}
	else if(keyCode == 15){ //'r'
		[self resetScales:nil];
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

