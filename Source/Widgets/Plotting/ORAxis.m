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
#import "ORAxis.h"
#import <math.h>
#import "ORAxisPreferences.h"

@interface ORAxis (private)
- (double) startDrag:(NSPoint) p;		// start drag procedure and return grab value
- (int) drag:(NSPoint)p withGrab:(double) val;// drag scale
- (void) adjustToPinLow:(double *)low withHigh:(double *)high;
- (void) calcFrameOffsets;				// set scale parameters from CPane object size
- (void) calcSci;				// calculate scaling factors
- (void) drawLogScale;				// draw a log scale
- (void) drawLinScale;				// draw a linear scale
- (int)nearPinPoint:(NSPoint) where;		// is a point near the pin point?
- (void) adjustSize:(NSDictionary*)oldLabelAttributes;
- (BOOL) dragScaleToLow:(double)aLow withHigh:(double)aHigh;
- (void) doAxisOp:(int)plotOp;
@end


@implementation ORAxis

enum {
    kDefFontSize	= 12,		    // default point size for text
    kShortTickLength	= 1,		    // length of short tick
    kMediumTickLength   = 2,		    // length of medium tick
    kLongTickLength     = 3		    // length of long tick
};
NSString* kDefFont = @"Helvetica";
/*
 * Definitions for text size calculations
 */
#define kLongestNumber	    @"1000M"				// longest scale label
#define	kXNumberCenter		    0				// x-label dx (center)
#define	kXNumberTopEdge		    (kLongTickLength + 1)       // x-label dy (top edge)
#define	kYNumberRightEdge	    (-kLongTickLength - 3)	// y-label dx (right edge)
#define	kYNumberCenter		    0				// y-label dy (center)
#define	kXAxisRoomLeft		    ([kLongestNumber sizeWithAttributes:labelAttributes].width/2)		// room needed left of x axis
#define	kXAxisRoomRight		    ([kLongestNumber sizeWithAttributes:labelAttributes].width/2)		// room needed right of x axis
#define	kYAxisRoomAbove		    ([kLongestNumber sizeWithAttributes:labelAttributes].height/2-2)       // room above y axis
#define	kYAxisRoomBelow		    ([kLongestNumber sizeWithAttributes:labelAttributes].height/2-2)       // room below y axis
#define	kXNumberOptimalSeparation   ([kLongestNumber sizeWithAttributes:labelAttributes].width * 7/4)      // optimal x scale label sep
#define	kYNumberOptimalSeparation   ([kLongestNumber sizeWithAttributes:labelAttributes].height * 3)		// optimal y scale label sep
#define kPixelTolerancePinCursor    4				// pixel tolerance for pin cursor

/* other definitions */
#define	kFirstSymbolExponent			-15	    // first symbol exponent
#define	kPositionOfZeroPowerSymbol		5	    // position of zero power symbol
#define	kDefaultScaleRangeLow			0	    // default scale range (low end)
#define	kDefaultScaleRangeHigh			1000	// default scale range (high end)
#define	kDefaultAbsoluteScaleMin		-5e9	// default absolute scale minimum
#define	kDefaultAbsoluteScaleMax		5e9	    // default absolute scale maximum
#define	kDefaultAbsoluteMinRange		1e-13   // default absolute minimum range
#define	kMinArgumentForLog				1e-100  // minimum argument for log()
#define	kMaxArgumentForExp				1000	// maximum argument for exp()
#define kBigNumber						1e100	// large number for divide by zero result

static char	symbols[]	= "fpnµm\0kMG";		// symbols for exponents

//notifications
NSString* ORAxisRangeChangedNotification    = @"ORAxis Range Changed";

//attributes
NSString* ORAxisMinValue 	= @"ORAxisMinValue";
NSString* ORAxisMaxValue 	= @"ORAxisMaxValue";
NSString* ORAxisMinLimit 	= @"ORAxisMinLimit";
NSString* ORAxisMaxLimit 	= @"ORAxisMaxLimit";
NSString* ORAxisUseLog		= @"ORAxisUseLog";
NSString* ORAxisColor		= @"ORAxisColor";
NSString* ORAxisIsOpposite	= @"ORAxisIsOpposite";
NSString* ORAxisDefaultRangeHigh = @"ORAxisDefaultRangeHigh";
NSString* ORAxisDefaultRangeLow  = @"ORAxisDefaultRangeLow";
NSString* ORAxisMinimumRange     = @"ORAxisMinimumRange";
NSString* ORAxisInteger		= @"ORAxisInteger";
NSString* ORAxisIgnoreMouse = @"ORAxisIgnoreMouse";
NSString* ORAxisMinPad		= @"ORAxisMinPad";
NSString* ORAxisMaxPad		= @"ORAxisMaxPad";
NSString* ORAxisPadding		= @"ORAxisPadding";
NSString* ORAxisMinSave		= @"ORAxisMinSave";
NSString* ORAxisMaxSave		= @"ORAxisMaxSave";
NSString* ORAxisAllowShifts = @"ORAxisAllowShifts";
NSString* ORAxisFont		= @"ORAxisFont";
NSString* ORAxisLabel		= @"ORAxisLabel";
NSString* kMarker			= @"kMarker";

NSString* kDefaultXAxisPrefs = @".xaxis";
NSString* kDefaultYAxisPrefs = @".yaxis";

enum {
    kShrinkPlot,
    kExpandPlot,
    kShiftPlotLeft,
    kShiftPlotRight
};

/* methods */

/* IScale - initialization method */
-(id) initWithFrame:(NSRect)aFrame;
{
    self = [super initWithFrame:aFrame];    /* setup local varables */
    
    pinVal    	= 0;
    invertPin 	= NO;

    [self setDefaults];
    return self;
}

- (void) dealloc
{
    [attributes release];
    [labelAttributes release];
	[[preferenceController window] close];
	[preferenceController release];

    [super dealloc];
}

- (void) awakeFromNib
{
    isMinPadCached  = NO;
    isLogCached     = NO;
    isIntegerCached = NO;
    
    [self setDefaults];
	[self setNeedsDisplay:YES];
}

- (void) setPreferenceController:(id)aController
{
	[aController retain];
	[preferenceController release];
	preferenceController = aController; 
}

- (BOOL)mouseDownCanMoveWindow
{
    return NO;
}

- (BOOL) dragInProgress
{
    return mDragInProgress;
}

- (void) setDefaults
{
    
    //[[self undoManager] disableUndoRegistration];
    if(!attributes)[self setAttributes:[NSMutableDictionary dictionary]];
    
    pinVal    	= 0;
    invertPin 	= NO;
    
    
    [self setAllowShifts:YES];
    [self setTextFont:[NSFont fontWithName:kDefFont size:kDefFontSize]];
    [self setInteger:YES];
    [self setIgnoreMouse:NO];
    
    [self setRngLimitsLow:0 withHigh:70000 withMinRng:10];
    [self setRngLow:kDefaultScaleRangeLow withHigh:kDefaultScaleRangeHigh];
    [self setRngDefaultsLow:kDefaultScaleRangeLow withHigh:kDefaultScaleRangeHigh];
        
    [self calcFrameOffsets];

    [self setColor:[NSColor blackColor]];    
    
   // [[self undoManager] enableUndoRegistration];
    
    [self setNeedsDisplay: YES];
    [viewToScale setNeedsDisplay:YES];;
}


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}
- (NSColor*) color
{
	NSData* theColorData = [attributes objectForKey:ORAxisColor];
	if(theColorData) return [NSUnarchiver unarchiveObjectWithData:theColorData];
	else {
		return [NSColor blackColor];
	}
}

- (void) setColor:(NSColor*)aColor
{
    [attributes setObject:[NSArchiver archivedDataWithRootObject:aColor] forKey:ORAxisColor];
    [self setNeedsDisplay: YES];
    [viewToScale setNeedsDisplay:YES];;
}

- (BOOL) oppositePosition
{
	return [[attributes objectForKey:ORAxisIsOpposite] boolValue];
}


- (void) setOppositePosition:(BOOL)state
{
    [attributes setObject:[NSNumber numberWithBool:state] forKey:ORAxisIsOpposite];
    [self setNeedsDisplay: YES];
}

- (NSFont*) textFont
{
    return [NSUnarchiver unarchiveObjectWithData:[attributes objectForKey:ORAxisFont]];
}
- (void) setTextFont:(NSFont*)font
{
    [attributes setObject:[NSArchiver archivedDataWithRootObject:font] forKey:ORAxisFont];
    NSDictionary* oldLabelAttributes = [labelAttributes copy];
    if(!labelAttributes)labelAttributes = [[NSMutableDictionary dictionary] retain];
    [labelAttributes setObject:font forKey:NSFontAttributeName];
    [self adjustSize:oldLabelAttributes];
    [oldLabelAttributes release];
    [self setNeedsDisplay: YES];
    [viewToScale setNeedsDisplay:YES];;
}

- (void) drawRect:(NSRect) area
{
	[self drawTitle];
    if ([self isLog]) [self drawLogScale];
    else			  [self drawLinScale];
}


- (BOOL) integer
{
    if(isIntegerCached)return cachedInteger;
    return [[attributes objectForKey:ORAxisInteger] boolValue];
}

- (void) setInteger:(BOOL) isInt
{
    [attributes setObject:[NSNumber numberWithBool:isInt] forKey:ORAxisInteger];
    [self calcSci];
    cachedInteger = isInt;
    isIntegerCached = YES;
    [self setNeedsDisplay:YES];
    [viewToScale setNeedsDisplay:YES];;
}

-(BOOL) log
{
    if(isLogCached)return cachedIsLog;
    return [[attributes objectForKey:ORAxisUseLog] boolValue];
}

-(BOOL) isLog
{
    if(isLogCached)return cachedIsLog;
    return [[attributes objectForKey:ORAxisUseLog] boolValue];
}

- (void) setLog:(BOOL) isLog
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setLog:[self isLog]];
    /* set the instance variable */
    [attributes setObject:[NSNumber numberWithBool:isLog] forKey:ORAxisUseLog];
    cachedIsLog = isLog; 
    isLogCached = YES;   
    /* must re-calculate log scaling factors */
    [self calcSci];
    [self rangingDonePostChange];
}


/* SetPin - set pin point for scale */
- (void) setPin:(double) p
{
    pinned = YES;
    pinVal = p;
    
    /* calculate pin pixel location */
    [self calcSci];
}



/* clearPin - set pin point for scale */
- (void) clearPin
{
    pinned = NO;
}



/* setRngLimits - set the extreme limits for the scale */
/* Note: for non-integer log scales min_rng is a ratio, not a difference */
-(void)	setRngLimitsLow:(double)low withHigh:(double) high withMinRng:(double) min_rng;
{
    [self setMinLimit:low];
    [self setMaxLimit:high];
    [self setMinimumRange:min_rng];
    [self setRngLow:[self minValue] withHigh:[self maxValue]];
}


/* setRngDefaultsLow:High - set the default range for this scale */
- (void) setRngDefaultsLow:(double)aLow withHigh:(double)aHigh
{
    [self checkRngLow:&aLow withHigh:&aHigh];
    [self setDefaultRangeLow:aLow];
    [self setDefaultRangeHigh:aHigh];
}



/* setDefaultRng - reset range to default limits and save current range */
- (int) setDefaultRng
{
    return [self setRngLow:[self defaultRangeLow] withHigh:[self defaultRangeHigh]];
}



/* setFullRng - set range to its full scale */
- (int) setFullRng
{
    return [self setRngLow:[self minLimit] withHigh:[self maxLimit]];
}



/* saveRngOnChange() - cause current range to be saved if next setRngLow changes the scale */
- (void) saveRngOnChange
{
    saveRng = YES;
}



/* saveRng() - save current range */
- (void) saveRng
{
    [self setMinSave:[self minValue]];
    [self setMaxSave:[self maxValue]];
}



/* restoreRng() - restore saved range */
- (int) restoreRng
{
    return [self setRngLow:[self minSave] withHigh:[self maxSave]];
}



/* setOrigin - set origin of scale (keeping the same range) */
- (int) setOrigin:(double) low
{
    return [self setRngLow:low withHigh:low+[self valueRange]];
}



/* shiftOrigin - shift the scale origin */
- (int) shiftOrigin:(double) delta
{
    return[self setOrigin:[self minValue] + delta];
}

/* setRngLow - set the scale limits */
/* All scale changes occur via this routine! */
- (BOOL) setRngLow:(double)aLow withHigh:(double)aHigh
{
    BOOL shouldSave = saveRng;
    
    saveRng = NO;
    
    [self checkRngLow:&aLow withHigh:&aHigh];
    
    if (aHigh==[self maxValue] && aLow==[self minValue]) return NO;
    
    if (shouldSave) {
        [self setMinSave:[self minValue]];
        [self setMaxSave:[self maxValue]];
    }
    
    [self setMinValue:aLow];
    [self setMaxValue:aHigh];
    [self setPadding:0];
    [self setMinPad:aLow  - [self padding]];
    [self setMaxPad:aHigh - [self padding]];
    
    [self calcSci];
    
    return YES;
}

- (double) valueRange
{
    return [self maxValue] - [self minValue];
}

/* checkRngLow - make sure new scale limits are within range */
-(BOOL) checkRngLow:(double *)low withHigh:(double *)high
{
    double	t,dv,v1,v2,cen,newPin;
    BOOL	fixedPin;
    
    if(fabs(*low-*high) <.01){
        *high = 10000;
        *low = 0;
    }
    
    /* convert to integer if integer scale */
    if ([self integer]) {
        *low = roundToLong(*low);
        *high = roundToLong(*high);
    }
    v1 = *low;
    v2 = *high;
    
    /* check scale range */
    if ([self isLog] && ![self integer]) {
        
        /* protect against divide-by-zero */
        if (v1 < kMinArgumentForLog) v1 = kMinArgumentForLog;
        if (v2 < kMinArgumentForLog) v2 = kMinArgumentForLog;
        
        dv = v2 / v1;
        
        if (dv < 1.0) {
            v1 = [self minLimit];
            v2 = [self maxLimit];
            dv = v2 - v1;
        } 
        else if (dv < [self minimumRange]) {
            dv = [self minimumRange];
            /* expand scale, keeping the same center */
            cen = (v1 + v2) / 2;
            t = sqrt(dv);
            v1 = cen / dv;
            v2 = cen * dv;
        }
        
    } 
    else {
        
        dv = v2 - v1;
        
        if (dv < [self minimumRange]) {
            if (dv < 0) {
                v1 = [self minLimit];
                v2 = [self maxLimit];
                dv = v2 - v1;
            } 
            else {
                /* expand scale, keeping the same center */
                //cen = (v1 + v2) / 2;
                //v1 = cen - [self minimumRange]/2;
                v2 = v1  + [self minimumRange];
                dv = [self minimumRange];
                if ([self integer]) {
                    v1 = roundToLong(v1);
                    v2 = roundToLong(v2);
                }
            }
        }
    }
    
    /* decide whether to keep the scale pinPoint fixed in case scale needs adjusting */
    fixedPin = NO;
    if (pinned^invertPin) {
        newPin = (pinVal-v1) * dpos / dv;
        if (fabs(newPin-pinPix) < 0.5) fixedPin = YES;
    }
    
    /* check scale maximum */
    if (v2 > [self maxLimit]) {
        
        v2 = [self maxLimit];
        if (fixedPin) {
            [self adjustToPinLow:&v1 withHigh:&v2];
        } 
        else if ([self isLog] && ![self integer]) {
            v1 = v2 / dv;
        } 
        else {
            v1 = v2 - dv;
        }
    }
    
    /* check scale minimum */
    if (v1 < [self minLimit]) {
        
        v1 = [self minLimit];
        if (fixedPin) {
            [self adjustToPinLow:&v1 withHigh:&v2];
        } 
        else if ([self isLog] && ![self integer]) {
            v2 = v1 * dv;
        } 
        else {
            v2 = v1 + dv;
        }
        /* make sure we haven't put v2 over the top */
        if (v2 > [self maxLimit]) v2 = [self maxLimit];
    }
    
    /* update range limits and return */
    if (v1!=*low || v2!=*high) {
        *low = v1;
        *high = v2;
        return YES;
    } 
    else {
        return NO;
    }
}

- (float) getPixAbsFast:(double)val log:(BOOL)aLog integer:(BOOL)aInt minPad:(double)aMinPad;
{
	//same as getPixAbs without the slow dictionary lookups
    float	t;
    
    if (aLog) {
        if (aInt) val += 1;
        else val /= aMinPad;
        if (val < kMinArgumentForLog) val = kMinArgumentForLog;
        t = log(val) * fscl;			// get pixel position
    } 
    else {
        t = (val-aMinPad) * fscl;
    }
    if(t>0)return (t+0.5);
    else   return (t-0.5);
	
}



/* getPixAbs - convert from an absolute scale value to an absolute pixel position */
- (float) getPixAbs:(double) val
{
    float	t;
    
    if ([self isLog]) {
        if ([self integer]) val += 1;
        else val /= [self minPad];
        if (val < kMinArgumentForLog) val = kMinArgumentForLog;
        t = log(val) * fscl;			// get pixel position
    } 
    else {
        t = (val-[self minPad]) * fscl;
    }
    if(t>0.0)return (t+0.5f);
    else   return (t-0.5f);
}



/* getPixRel - convert from a relative scale value to a pixel position */
- (float) getPixRel:(double) val
{
    float	t;
    
    if ([self isLog]) {
        if ([self integer]) val += 1;
        if (val < kMinArgumentForLog) val = kMinArgumentForLog;
        t = log(val) * fscl;			// get pixel position
    } 
    else {
        t = val * fscl;
    }
    if(t>0.0)return (t+0.5f);
    else   return (t-0.5f);
}



/* GetValAbs - convert from an absolute pixel position to an absolute scale value */
- (double) getValAbs:(int) pix
{
    double	val;
    
    if ([self isLog]) {
        val = exp(pix / fscl);
        if ([self integer]) val -= 1;
        else val *= [self minPad];
    } 
    else {
        val = [self minPad] + pix / fscl;
    }
    return(val);
}



/* GetVal - convert from a pixel position to a scale value */
- (double) getValRel:(int) pix
{
    double	val;
    
    if ([self isLog]) {
        val = exp(pix / fscl);
        if ([self integer]) val -= 1;
    } 
    else {
        val = pix / fscl;
    }
    return(val);
}

- (double) minPad
{
    if(isMinPadCached)return cachedMinPad;
    return  [[attributes objectForKey:ORAxisMinPad] doubleValue];
}

-(void)setMinPad:(double)aValue
{
    cachedMinPad = aValue;
    isMinPadCached = YES;
    [attributes setObject:[NSNumber numberWithDouble:aValue] forKey:ORAxisMinPad];
    isMinPadCached = YES;
    cachedMinPad = aValue;
}
- (double) maxPad
{
    return  [[attributes objectForKey:ORAxisMaxPad] doubleValue];
}

-(void)setMaxPad:(double)aValue
{
    [attributes setObject:[NSNumber numberWithDouble:aValue] forKey:ORAxisMaxPad];
}


- (double) minSave
{
    return  [[attributes objectForKey:ORAxisMinSave] doubleValue];
}

-(void) setMinSave:(double)aValue
{
    [attributes setObject:[NSNumber numberWithDouble:aValue] forKey:ORAxisMinSave];
}
- (double) maxSave
{
    return  [[attributes objectForKey:ORAxisMaxSave] doubleValue];
}

-(void) setMaxSave:(double)aValue
{
    [attributes setObject:[NSNumber numberWithDouble:aValue] forKey:ORAxisMaxSave];
}

- (void) setLabel:(NSString*)aString
{
	if(!aString)aString = @"";
    [attributes setObject:aString forKey:ORAxisLabel];
	[self adjustSize:labelAttributes];
	[self setNeedsDisplay:YES]; 
}

- (NSString*) label
{
	NSString* theLabel = [attributes objectForKey:ORAxisLabel];
	if(!theLabel)return @"";
	else return theLabel;
}

- (long) axisMinLimit
{
	return (long)[self minLimit];
}

- (void) setAxisMinLimit:(long)aValue
{
	double dv = (double)aValue;
	[self setMinLimit:dv];
	//[self setRngLow:dv withHigh:[self maxLimit]]; 
    [self calcSci];
 	[self setNeedsDisplay:YES];
}

- (long) axisMaxLimit
{
	return (long)[self maxLimit];
}
- (void) setAxisMaxLimit:(long)aValue
{
	double dv = (double)aValue;
	[self setMaxLimit:dv];
	//[self setRngLow:[self minLimit] withHigh:dv];   	
    [self calcSci];
  	[self setNeedsDisplay:YES];
}

/* GetMinVal - get scale minimum value */
- (double) minValue
{
    return  [[attributes objectForKey:ORAxisMinValue] doubleValue];
}

-(void)setMinValue:(double)aValue
{
    [attributes setObject:[NSNumber numberWithDouble:aValue] forKey:ORAxisMinValue];
}

- (double) minLimit
{
    return  [[attributes objectForKey:ORAxisMinLimit] doubleValue];
}

-(void)setMinLimit:(double)aValue
{
    [attributes setObject:[NSNumber numberWithDouble:aValue] forKey:ORAxisMinLimit];
}

-(void)setMinimumRange:(double)aValue
{
    /* make sure the minimum range value is not silly */
    if (aValue > [self maxLimit]-[self minLimit]) {
        [attributes setObject:[NSNumber numberWithDouble:[self maxLimit] - [self minLimit]] forKey:ORAxisMinimumRange];
    } 
    else {
        [attributes setObject:[NSNumber numberWithDouble:aValue] forKey:ORAxisMinimumRange];
    }
}

- (double) minimumRange
{
    return  [[attributes objectForKey:ORAxisMinimumRange] doubleValue];
}

- (double) defaultRangeLow
{
    return  [[attributes objectForKey:ORAxisDefaultRangeLow] doubleValue];
}

-(void)setDefaultRangeLow:(double)aValue
{
    [attributes setObject:[NSNumber numberWithDouble:aValue] forKey:ORAxisDefaultRangeLow];
}

- (double) defaultRangeHigh
{
    return  [[attributes objectForKey:ORAxisDefaultRangeHigh] doubleValue];
}

-(void)setDefaultRangeHigh:(double)aValue
{
    [attributes setObject:[NSNumber numberWithDouble:aValue] forKey:ORAxisDefaultRangeHigh];
}

/* GetMaxVal - get scale maximum value */
- (double) maxValue
{
    return[[attributes objectForKey:ORAxisMaxValue] doubleValue];
}

-(void)setMaxValue:(double)aValue
{
    [attributes setObject:[NSNumber numberWithDouble:aValue] forKey:ORAxisMaxValue];
}

- (double) maxLimit
{
    return[[attributes objectForKey:ORAxisMaxLimit] doubleValue];
}

-(void)setMaxLimit:(double)aValue
{
    [attributes setObject:[NSNumber numberWithDouble:aValue] forKey:ORAxisMaxLimit];
}

/* GetPadding - get scale padding */
- (double) padding
{
    return[[attributes objectForKey:ORAxisPadding] doubleValue];
}

/* SetPadding - set scale padding */
- (void) setPadding:(double) aValue
{
    [attributes setObject:[NSNumber numberWithDouble:aValue] forKey:ORAxisPadding];
    [self setMinPad:[self minValue] - aValue];
    [self setMaxPad:[self maxValue] - aValue];
    [self setNeedsDisplay:YES];;
    [viewToScale setNeedsDisplay:YES];;
    
}

-(void)	mouseDown:(NSEvent*)theEvent
{
    if ([self ignoreMouse]) return;
	
	NSEventType modifierKeys = [theEvent modifierFlags];
    NSPoint mouseLoc         = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	NSNumber* markerNumber = [attributes objectForKey:kMarker];

	if(markerNumber){
	
		float markerPixel = [self getPixAbs:[markerNumber floatValue]];
		float checkValue;
		
		if([self isXAxis])	checkValue = mouseLoc.x-lowOffset;
		else				checkValue = mouseLoc.y-lowOffset;
		
		if(checkValue <= (markerPixel+20) && checkValue>=(markerPixel-20)){
			if(modifierKeys & NSCommandKeyMask){
				[attributes removeObjectForKey:kMarker];
				[[self window] resetCursorRects];
				[viewToScale setNeedsDisplay:YES];
				[self setNeedsDisplay:YES];
				return;
			}
			else {
				mMarkerDragInProgress = YES;
				[[NSCursor closedHandCursor] push];
			}
		}		
	}
	if(!mMarkerDragInProgress){
		firstDrag = YES;   
		

	//	if ([theEvent clickCount] == 2){
	//		[ORAxisPreferences sharedAxisPreferenceController:self];
	//		return;
	//	}

		if(modifierKeys & NSCommandKeyMask)  [self markClick:mouseLoc];
		else {
			if(!(modifierKeys & NSControlKeyMask)) [[NSCursor closedHandCursor] push];

			
			if ([self isXAxis]) mouseLoc.x -= lowOffset;
			else				mouseLoc.y -= lowOffset;
			
			
			/* last chance to set the cursor before a grab */
			dragFlag = !(modifierKeys & NSControlKeyMask);
			nearPinFlag = [self nearPinPoint:mouseLoc];
			
			/* invert the pin if we are grabbing near the pin-point */
			if (pinned == (nearPinFlag==0)) invertPin = YES;
			else							invertPin = NO;
			
			if([self mouse:mouseLoc inRect:[self bounds]]){
				mGrabValue = [self startDrag:mouseLoc];
			}
		}
	}
}

/* mouseDragged - mouse is being dragged */
-(void)	mouseDragged:(NSEvent*)theEvent
{
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    if(mDragInProgress){
        [self drag:mouseLoc withGrab:mGrabValue];
    }
	else if(mMarkerDragInProgress){
		[self markClick:mouseLoc];
	}
}

-(void)	mouseUp:(NSEvent*)theEvent
{
    if(mDragInProgress){
        [self rangingDonePostChange];
       /* NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        if(NSPointInRect(mouseLoc,[self bounds])){
            if([theEvent modifierFlags] & NSControlKeyMask){
                if([self isXAxis])[[NSCursor resizeLeftRightCursor]set];
                else[[NSCursor resizeUpDownCursor]set];
            }
            else [[NSCursor openHandCursor]set];
        }
        else [[NSCursor arrowCursor]set];
		*/
    }
	mDragInProgress = NO;
	mMarkerDragInProgress = NO;
	
	[[self window] resetCursorRects];
	
	[NSCursor pop];
}

- (double)convertPoint:(double)pix
{
    double p;
    if ([self isLog]) p = (pix * log([self maxValue]+1.0)) / dpos;
    else 	  	  p = [self minValue] + [self getValRel:pix];
    return p;
}

- (void) markClick:(NSPoint)mouseLoc
{
	float markValue;
	if([self isXAxis])	markValue = [self getValAbs:mouseLoc.x-lowOffset];
	else				markValue = [self getValAbs:mouseLoc.y-lowOffset];
	
	if(markValue <= [self minValue])	 markValue = [self minValue];
	else if(markValue >=[self maxValue]) markValue = [self maxValue];
	
	[attributes setObject:[NSNumber numberWithFloat:markValue] forKey:kMarker];
	[viewToScale setNeedsDisplay:YES];
	[self setNeedsDisplay:YES];
}

//- (NSUndoManager*) undoManager
//{
//    return [[[self window] windowController] undoManager];
//}

- (double) optimalLabelSeparation
{
    if([self isXAxis])return kXNumberOptimalSeparation;
    else return kYNumberOptimalSeparation;
    
}

- (void) setIgnoreMouse:(BOOL) ignore 
{
    [attributes setObject:[NSNumber numberWithBool:ignore] forKey:ORAxisIgnoreMouse];
}

- (BOOL) ignoreMouse
{
    return [[attributes objectForKey:ORAxisIgnoreMouse] boolValue];
}

-(void)	setAllowShifts:(BOOL) allow
{
    [attributes setObject:[NSNumber numberWithBool:allow] forKey:ORAxisAllowShifts];
}

-(BOOL)	allowShifts
{
    return [[attributes objectForKey:ORAxisAllowShifts] boolValue];
}


-(void)setFrame:(NSRect)aFrame {
    
    [super setFrame:aFrame];
    
    [self calcFrameOffsets];
    [self setNeedsDisplay:YES];
    [viewToScale setNeedsDisplay:YES];
}

- (BOOL) isXAxis
{
    NSRect aFrame = [self frame];
    return aFrame.size.width > aFrame.size.height;
}

- (IBAction) doubleClick:(id)sender
{
}

- (IBAction) setLogScale:(id)sender 
{ 
    [self setLog:[sender intValue]];
}

- (IBAction) shiftLeft:(id)sender   { [self doAxisOp:kShiftPlotLeft];   }
- (IBAction) shiftRight:(id)sender  { [self doAxisOp:kShiftPlotRight];  }
- (IBAction) zoomIn:(id)sender      { [self doAxisOp:kExpandPlot];      }
- (IBAction) zoomOut:(id)sender     { [self doAxisOp:kShrinkPlot];      }

- (void) setAttributes:(NSMutableDictionary*)someAttributes
{
	if(someAttributes){
		someAttributes = [[someAttributes mutableCopy] autorelease];
	   
		[someAttributes retain];
		[attributes release];
		attributes = someAttributes;

		if(![attributes objectForKey:ORAxisMinimumRange]){
			[self setDefaults];
		}
	}
	else {
		[self setDefaults];
	}
	
	isMinPadCached  = NO;
	isLogCached     = NO;
	isIntegerCached = NO;

	pinned= [self isLog];
	
    [self calcSci];
}

- (NSMutableDictionary*) attributes
{
    return attributes;
}
- (NSMutableDictionary*) labelAttributes
{
    return labelAttributes;
}
- (void) setLabelAttributes:(NSMutableDictionary*)someAttributes
{
    [someAttributes retain];
    [labelAttributes release];
    labelAttributes = someAttributes;
}

-(id)initWithCoder:(NSCoder*)coder
{
    if(self = [super initWithCoder:coder]){

        if([coder allowsKeyedCoding]){
            [self setAttributes:[coder decodeObjectForKey:@"ORAxisAttributes"]];
            [self setLabelAttributes:[coder decodeObjectForKey:@"ORAxisLabelAttributes"]];
        }
        else {
            [self setAttributes:[[[coder decodeObject] mutableCopy]autorelease]];
            [self setLabelAttributes:[[[coder decodeObject] mutableCopy]autorelease]];
        }
        if(!attributes) [self setDefaults];
        [self calcFrameOffsets];
    }
    return self;
}

-(void)	encodeWithCoder:(NSCoder*)coder
{
    [super encodeWithCoder:coder];
    if([coder allowsKeyedCoding]){
        [coder encodeObject:attributes forKey:@"ORAxisAttributes"];
        [coder encodeObject:labelAttributes forKey:@"ORAxisLabelAttributes"];
    }
    else {
        [coder encodeObject:attributes];
        [coder encodeObject:labelAttributes];
    }
}

- (void) drawMarkInFrame:(NSRect)aFrame usingColor:(NSColor*)aColor
{
	NSNumber* markerNumber = [attributes objectForKey:kMarker];
	if(markerNumber){
		float oldLineWidth = [NSBezierPath defaultLineWidth];
		[NSBezierPath setDefaultLineWidth:.5];
		[aColor set];
		float val = [markerNumber floatValue];
		val = [self getPixAbs:val];
		if([self isXAxis]){
			[NSBezierPath strokeLineFromPoint:NSMakePoint(val,0) 
									toPoint:NSMakePoint(val,aFrame.size.height-1)];
		}
		else {
			[NSBezierPath strokeLineFromPoint:NSMakePoint(0,val) 
								  toPoint:NSMakePoint(aFrame.size.width-1,val)];
		}

		[NSBezierPath setDefaultLineWidth:oldLineWidth];
	}
}

- (void) drawGridInFrame:(NSRect)aFrame usingColor:(NSColor*)aColor
{    
	float oldLineWidth = [NSBezierPath defaultLineWidth];
    [NSBezierPath setDefaultLineWidth:.5];
    [aColor set];
    int i;
    if([self isXAxis]){
        for(i=0;i<gridCount;i++){
			float val = gridArray[i];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(val,0) 
									  toPoint:NSMakePoint(val,aFrame.size.height-1)];
        }
    }
    else {
        for(i=0;i<gridCount;i++){
			float val = gridArray[i];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(0,val) 
								      toPoint:NSMakePoint(aFrame.size.width-1,val)];
        }
    }
    [NSBezierPath setDefaultLineWidth:oldLineWidth];
    
}

- (void) resetCursorRects
{
    NSRect aRect = NSMakeRect(0,0,[self frame].size.width,[self frame].size.height);
	NSNumber* markerNumber = [attributes objectForKey:kMarker];
	NSRect lowRect;
	NSRect highRect;
	NSRect markerRect;
	NSImage* cursorImage;
	NSCursor* cursor;
	
	if([self isXAxis]){
		if([self oppositePosition]) cursorImage = [NSImage imageNamed:@"xAxisMarkerOpposite"];
		else						cursorImage = [NSImage imageNamed:@"xAxisMarker"];
	}
	else {
		if([self oppositePosition]) cursorImage = [NSImage imageNamed:@"yAxisMarkerOpposite"];
		else						cursorImage = [NSImage imageNamed:@"yAxisMarker"];
	}
	NSSize cursorSize = [cursorImage size];
	cursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(cursorSize.width/2,cursorSize.height/2)];
	float markerPixel = [self getPixAbs:[markerNumber floatValue]]+lowOffset;
	if([self isXAxis]){
		lowRect    = NSMakeRect(0,0,markerPixel-cursorSize.width/2,[self frame].size.height);
		markerRect = NSMakeRect(markerPixel-cursorSize.width/2,0,cursorSize.width,[self frame].size.height);
		highRect   = NSMakeRect(markerPixel+cursorSize.width/2,0,[self frame].size.width-markerPixel-cursorSize.width/2,[self frame].size.height);
	}
	else {
		lowRect    = NSMakeRect(0,0,[self frame].size.width,markerPixel-cursorSize.height/2);
		markerRect = NSMakeRect(0,markerPixel-cursorSize.height/2,[self frame].size.width,cursorSize.height);
		highRect   = NSMakeRect(0,markerPixel+cursorSize.height/2,[self frame].size.height-markerPixel-cursorSize.height/2,[self frame].size.width);
	}
	
	
    if([[NSApp currentEvent] modifierFlags] & NSControlKeyMask){
		if([self isXAxis])[self addCursorRect:aRect cursor:[NSCursor resizeLeftRightCursor]];
		else [self addCursorRect:aRect cursor:[NSCursor resizeUpDownCursor]];
	}
    else if([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask){
		if(markerNumber){
			[self addCursorRect:lowRect cursor:cursor];
			[self addCursorRect:markerRect cursor:[NSCursor disappearingItemCursor]];
			[self addCursorRect:highRect cursor:cursor];
		}
		else {
			[self addCursorRect:aRect cursor:cursor];
		}
	}
	else {
		if(markerNumber){
			[self addCursorRect:lowRect cursor:[NSCursor openHandCursor]];
			if([self isXAxis])	[self addCursorRect:markerRect cursor:[NSCursor resizeLeftRightCursor]];
			else				[self addCursorRect:markerRect cursor:[NSCursor resizeUpDownCursor]];
			[self addCursorRect:highRect cursor:[NSCursor openHandCursor]];
		}
		else [self addCursorRect:aRect cursor:[NSCursor openHandCursor]];
    } 
	[cursor release];
   
}

/* rangingDonePostChange - Clean up after dragging the scale */
- (void) rangingDonePostChange 
{
    
    /* uninvert the pin in case we inverted it */
    invertPin = NO;
    
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORAxisRangeChangedNotification
                      object:self
                    userInfo: nil];
    
    [self setNeedsDisplay:YES];
    [viewToScale setNeedsDisplay:YES];
    
}
- (void) drawTitle
{
	[[NSColor blackColor] set];
	NSString* label = [self label];
	NSSize labelSize = [label sizeWithAttributes:labelAttributes];
	BOOL isOpposite = [self oppositePosition];
	if([self isXAxis]){
		float xc = [self frame].size.width/2;
		if(isOpposite) [label drawAtPoint:NSMakePoint(xc - labelSize.width/2,[self frame].size.height - labelSize.height) withAttributes:labelAttributes];
		else [label drawAtPoint:NSMakePoint(xc - labelSize.width/2,0) withAttributes:labelAttributes];
	}
	else {
		float labelAndTic = kLongTickLength + [@"300M" sizeWithAttributes:labelAttributes].width;
		float totalWidth = labelAndTic + labelSize.height;
		float x =  [self frame].size.height/2 - labelSize.width/2;
		NSAffineTransform *transform = [NSAffineTransform transform];
		NSGraphicsContext *context   = [NSGraphicsContext currentContext];
		
		[transform translateXBy:totalWidth yBy:0];
		[transform rotateByDegrees:90];
		
		[context saveGraphicsState];
		[transform concat];
		
		if(isOpposite)[label drawAtPoint:NSMakePoint(x,labelSize.height-20) withAttributes:labelAttributes];
		else          [label drawAtPoint:NSMakePoint(x,labelAndTic) withAttributes:labelAttributes];
		
		[context restoreGraphicsState];


	}
}
@end

@implementation ORAxis (private)

/* StartDrag - start dragging the scale */
/* log scale grab only works for scales starting at zero */
/* Note: The point must be pre-corrected for the scale start position */
-(double)startDrag:(NSPoint) p
{
    double		pix;
    
    if ([self isXAxis]) 	pix = p.x;
    else 	pix = p.y;
    
    mDragInProgress = YES;
    
    return([self convertPoint:pix] );
}

/* Drag - drag the scale */
/* log scale drag only works for pinned scales starting at zero */
-(int)drag:(NSPoint) p withGrab:(double) grabVal
{
    double		pix, tmp;
    double		newMin, newMax;
    
    if ([self isXAxis]) pix = p.x;
    else	   pix = p.y;
    
    if ([self isLog]) {
        
        newMin = 0;
        if (pix && (tmp=grabVal*dpos/pix)<kMaxArgumentForExp) {
            newMax = exp(tmp) - 1.0;
        } 
        else {
            newMax = [self maxLimit];
        }
        
    }
    else {
        if (pinned^invertPin | dragFlag) {
            if (pinPix != pix) {
                newMin = (pinVal*pix - grabVal*pinPix) / (pix - pinPix);
                if (pinPix) newMax = newMin + (pinVal-newMin)*dpos/pinPix;
                else		newMax = newMin + (grabVal-newMin)*dpos/pix;
                
                /* make sure scale range is not too small */
                /* (we do this here instead of letting CheckRng() do it	*/
                /* because we want to keep the pin point at the same	*/
                /* location after we adjust the scale range)			*/
                if (newMax-newMin < [self minimumRange]) {
                    
                    if (newMax >= newMin) {
                        
                        /* set scale to minimum range, keeping pin-point at same spot */
                        newMin = pinVal - pinPix * [self minimumRange] / dpos;
                        newMax = newMin + [self minimumRange];
                        
                    }
                    else {
                        newMin = [self minLimit];
                        newMax = [self maxLimit];
                        [self adjustToPinLow:&newMin withHigh:&newMax];
                    }
                }
                
            }
            else {		
                newMin = [self minLimit];
                newMax = [self maxLimit];
                [self adjustToPinLow:&newMin withHigh:&newMax];
            }
            
        }
        else {
            newMin = grabVal - [self valueRange] * pix / dpos;
            newMax = newMin + [self valueRange];
            
        }
    }
    
    /* Only force redraw of scale if range indeed changed */
    if ([self dragScaleToLow:newMin withHigh:newMax]) {
        [self setNeedsDisplay:YES];
        [viewToScale setNeedsDisplay:YES];
        return YES;
    }
    return NO;
}



- (void) doAxisOp:(int)plotOp 
{
    int       range = [self valueRange];
    int       amount = range/32;
    if(amount==0)amount = 10;
    /* get the current x range of the slider */
    int xMin = [self minValue];
    int xMax = [self maxValue];
    if(plotOp == kShiftPlotRight){
        xMin -= amount;
        xMax -= amount;
    }
    else if(plotOp == kShiftPlotLeft){
        xMin += amount;
        xMax += amount;
    }
    else if(plotOp == kExpandPlot){
        xMin -= amount;
        xMax += amount;
        if(xMin<=0)xMin =0;
        if(xMax > [self maxLimit])xMax = [self maxLimit];
    }
    else if(plotOp ==kShrinkPlot){
        if(abs(xMax-xMin)>10){
            xMax -= amount;
            xMin += amount;
        }
        
    }
    
    else return;
    
    [self setRngLow:xMin withHigh:xMax];
    [self rangingDonePostChange]; //same as a drag so just call rangingDonePostChange.
    
}

/* nearPinpoint - are we near the pin point for the scale */
/* Note: The point must be pre-corrected for the scale start position */
/* Return value: -1=below pin point, 0=at pin point, 1=above pin point */
- (int) nearPinPoint:(NSPoint) where
{
    int	pix, diff;
    
    /* don't yet support shiftable log scales */
    if ([self isLog]) return 1;
    
    /* whole scale causes shift if not pinned */
    if ([self allowShifts] && !(pinned^dragFlag)) return 0;
    
    /* get cursor pixel index */
    if ([self isXAxis]) pix = where.x;
    else	   pix = where.y;
    
    /* are we within kPixelTolerancePinCursor pixels of the scale end nearest the pinpoint? */
    if ([self allowShifts] && ((pinVal>=[self maxValue] && pix>dpos-kPixelTolerancePinCursor) || (pinVal<=[self minValue] && pix<kPixelTolerancePinCursor))) {
        return 0;
    }
    
    /* are we within kPixelTolerancePinCursor pixels of the pin point itself? */
    diff = pix - roundToLong(pinPix);
    
    if ([self allowShifts]) {
        if (diff > kPixelTolerancePinCursor) return 1;
        if (diff < -kPixelTolerancePinCursor) return -1 ;
    }
    else {
        if (diff < 0) return -1;
        return YES;
    }
    return NO;
}

/* adjustToPin - adjust scale limits to be consistent with pin-point */
- (void) adjustToPinLow:(double *)low withHigh:(double *)high
{
    double	scl1, scl2;
    
    /* keep the pin-point stationary */
    if (pinPix > 0) {
        scl1 = (pinVal - *low) / pinPix;
    } 
    else {
        scl1 = kBigNumber;
    }
    if (dpos-pinPix > 0) {
        scl2 = (*high - pinVal) / (dpos - pinPix);
    } 
    else {
        scl2 = kBigNumber;
    }
    if (scl2 < scl1) scl1 = scl2;
    
    *low = pinVal - scl1 * pinPix;
    *high = pinVal + scl1 * (dpos - pinPix);
    
    /* make sure we haven't set the scale too small */
    if (*high-*low < [self minimumRange]) *high = *low + [self minimumRange];
}

/* calcFrameOffsets - Set Scale size parameters according to size of CPane */
- (void) calcFrameOffsets
{
    
    if ([self isXAxis]) {
        lowOffset = kXAxisRoomLeft;
        highOffset = [self frame].size.width - kXAxisRoomRight - 1;
    } 
    else {
        lowOffset = kYAxisRoomBelow;
        highOffset = [self frame].size.height - kYAxisRoomAbove - 1;
    }
    dpos = highOffset - lowOffset;
    /* must re-calculate log scaling factors */
    [self calcSci];
}

/* calcLogScl - calculate scaling factors and pin pix */
- (void) calcSci;
{
    double	rng;
    
    if (dpos <= 0) {
        fscl = 1;
    }
    else {
        rng = [self valueRange];
        if ([self isLog]) {
            if ([self integer]) rng += 1;
            if (rng < kMinArgumentForLog) rng = kMinArgumentForLog;
            fscl = dpos / log(rng);
        }
        else {
            if (rng < kMinArgumentForLog) rng = kMinArgumentForLog;
            fscl = dpos / rng;
        }
    }
    
    /* calculate pin pixel value */
    pinPix = (pinVal-[self minValue]) * fscl;
}

- (void) drawMarker:(float)val axisPosition:(int)axisPosition
{
	NSImage*	markerImage;
    BOOL isX = [self isXAxis];
	BOOL isOpposite = [self oppositePosition];
	if (isX) {
		if(isOpposite)	markerImage = [NSImage imageNamed:@"xAxisMarkerOpposite"];
		else			markerImage = [NSImage imageNamed:@"xAxisMarker"];
	}
	else {
		if(isOpposite)	markerImage = [NSImage imageNamed:@"yAxisMarkerOpposite"];
		else			markerImage = [NSImage imageNamed:@"yAxisMarker"];
	}
	NSRect sourceRect = NSMakeRect(0,0,[markerImage size].width,[markerImage size].height);
	int imageOffset;
	NSSize imageSize = [markerImage size];
	if(isX){
		if(isOpposite) imageOffset = imageSize.height;
		else           imageOffset = -imageSize.height;
	}
	else {
		if(isOpposite) imageOffset = imageSize.width;
		else           imageOffset = -imageSize.width;
	}
	
	val = [self getPixAbs:val];
	NSPoint p;
	if(isX)p = NSMakePoint(val+imageSize.width/2-1,axisPosition+imageOffset);
	else   p = NSMakePoint(axisPosition+imageOffset,val-imageSize.height/2+lowOffset);
	
	[markerImage drawAtPoint:p fromRect:sourceRect operation:NSCompositeSourceOver fraction:.5];

}


/* drawLogScale - draw a logarithmic scale */
/* Note: this routine only works for vertical scales which start at zero */
- (void) drawLogScale {
    	
    NSBezierPath*	theAxis 	= [NSBezierPath bezierPath];
	gridCount = 0;
    BOOL isX = [self isXAxis];
	
 	int			axisStartX,axisStartY;
	int			axisEndX,axisEndY;
	int			axisPosition;
	int			shortTicEndX,shortTicEndY;
	int			ticStartX,ticStartY;
	int			longTicEndX,longTicEndY;
	int			gridPosition;
	BOOL isOpposite = [self oppositePosition];

    if (isX) {
		if(isOpposite)	axisPosition  = 0;
		else			axisPosition  = [self frame].size.height;
		axisStartX    = lowOffset-1;
		axisStartY    = axisPosition;
		axisEndX	  = highOffset+1;
		axisEndY	  = axisPosition;
		ticStartX	  = lowOffset;
		ticStartY	  = axisPosition;
		longTicEndX   = lowOffset;
	}
    else {
		if(isOpposite)	axisPosition  = 0;
		else			axisPosition  = [self frame].size.width;
		axisStartX    = axisPosition;
		axisStartY    = lowOffset-1;
		axisEndX	  = axisPosition;
		axisEndY	  = highOffset+1;
		ticStartX	  = axisPosition;
		ticStartY	  = lowOffset;
		longTicEndY   = lowOffset;
	}    

	NSNumber* markerNumber = [attributes objectForKey:kMarker];
	if(markerNumber){	
		[self drawMarker:[markerNumber floatValue] axisPosition:axisPosition];
	}

	[theAxis moveToPoint:NSMakePoint(axisStartX,axisStartY)];// draw axis line
	[theAxis lineToPoint:NSMakePoint(axisEndX,axisEndY)];

    int			label_sep,tick_sep;
	--axisPosition;
	double val = log(11.0)*fscl;
	if      (val <  30) { tick_sep=5;  label_sep=10; }
	else if (val <  45) { tick_sep=2;  label_sep=10; }
	else if (val < 120) { tick_sep=2;  label_sep=10;  }
	else if (val < 240) { tick_sep=1;  label_sep=2;  }
	else		        { tick_sep=1;  label_sep=1;  }
            
	//setup the variables that don't change in the loop to come....
    if (isX) {
		ticStartY = axisPosition;	
		if(isOpposite){
			shortTicEndY =  kShortTickLength+1;
			longTicEndY =  kLongTickLength+1;
		}
		else {
			shortTicEndY = axisPosition - kShortTickLength;
			longTicEndY = axisPosition - kLongTickLength;
		}
	}
    else {
		ticStartX = axisPosition;
		if(isOpposite){
			ticStartX	  = axisPosition+2;
			shortTicEndX  = kShortTickLength+1;
			longTicEndX   =  kLongTickLength+1;
		}
		else {
			ticStartX	  = axisPosition;
			shortTicEndX  = axisPosition - kShortTickLength;
			longTicEndX   = axisPosition - kLongTickLength;
		}
	}    
	
	[theAxis moveToPoint:NSMakePoint(ticStartX,ticStartY)];
	[theAxis lineToPoint:NSMakePoint(longTicEndX,longTicEndY)];				// draw long tick
	if (gridCount<kMaxLongTicks) gridArray[gridCount++] =0;
            
	NSString* axisNumberString = @"0";
	NSSize axisNumberSize = [axisNumberString sizeWithAttributes:labelAttributes];

	NSPoint labelPoint;
	if(isX){
		if(isOpposite)labelPoint = NSMakePoint(lowOffset+kXNumberCenter - axisNumberSize.width/2,axisPosition+kLongTickLength+3);
		else labelPoint = NSMakePoint(lowOffset+kXNumberCenter - axisNumberSize.width/2,axisPosition-kXNumberTopEdge-1-axisNumberSize.height);
	}
	else {
		if(isOpposite) labelPoint = NSMakePoint(axisPosition+kLongTickLength+3,lowOffset+kYNumberCenter-axisNumberSize.height/2);
		else labelPoint = NSMakePoint(axisPosition+kYNumberRightEdge+1 - axisNumberSize.width,lowOffset+kYNumberCenter-axisNumberSize.height/2);
	}
	[axisNumberString drawAtPoint:labelPoint withAttributes:labelAttributes];

	int i = kPositionOfZeroPowerSymbol;
            
	double base = 1;
	double div  = 1;
	val  = 1;
            
	int n;
	if (label_sep == 2)	n = 0;						// special case to draw "1" label
	else				n = 1;
			
	for (;;) {

		// get pixel position;
		if(isX) ticStartX	 = lowOffset + (int)(log(val+1)*fscl);		
		else    ticStartY	 = lowOffset + (int)(log(val+1)*fscl);

		if (!(n%tick_sep)) {
			if(isX){
				longTicEndX	 = ticStartX;
				shortTicEndX = ticStartX;
				gridPosition = ticStartX-lowOffset;
			}
			else {
				longTicEndY  = ticStartY;
				shortTicEndY = ticStartY;
				gridPosition = ticStartY-lowOffset;

			}
			
			[theAxis moveToPoint:NSMakePoint(ticStartX,ticStartY)];
			if ((!(n%label_sep)) || (n==2 && label_sep==5)) {
				if (!n) n = 1;
				[theAxis lineToPoint:NSMakePoint(longTicEndX,longTicEndY)];	// draw long tick
				if (gridCount<kMaxLongTicks){
					gridArray[gridCount++] = gridPosition;
				}
				
				double tmp = val / div;
				if (tmp >= 1000) {
					div *= 1000;
					tmp = val / div;
					++i;
				}
				
				axisNumberString = [NSString stringWithFormat:@"%d%c",(int)tmp,symbols[i]];
				axisNumberSize = [axisNumberString sizeWithAttributes:labelAttributes];
				
				if(isX){
					if(isOpposite) [axisNumberString drawAtPoint:NSMakePoint(ticStartX+kXNumberCenter - axisNumberSize.width/2,axisPosition + kLongTickLength+3) withAttributes:labelAttributes];
					else [axisNumberString drawAtPoint:NSMakePoint(ticStartX+kXNumberCenter - axisNumberSize.width/2,axisPosition-kXNumberTopEdge-1-axisNumberSize.height) withAttributes:labelAttributes];
				}
				else {
					if(isOpposite)[axisNumberString drawAtPoint:NSMakePoint(axisPosition + kLongTickLength+4,ticStartY+1-axisNumberSize.height/2) withAttributes:labelAttributes];
					else [axisNumberString drawAtPoint:NSMakePoint(axisPosition-kXNumberCenter - axisNumberSize.width - kLongTickLength-2,ticStartY+1-axisNumberSize.height/2) withAttributes:labelAttributes];
				}
			}
			else {
				[theAxis lineToPoint:NSMakePoint(shortTicEndX,shortTicEndY)];				// draw short tick
			}
		}
		if (++n > 10) {
			n = 1;
			base *= 10;
			/*
			 ** draw tick at 15, 150, etc
			 */
			if (label_sep<=5 && (val=base*1.5)<=[self maxPad]) {
				if(isX){
					ticStartX	 = lowOffset + (int)(log(val+1)*fscl);// get pixel position;		
					shortTicEndX = ticStartX;
					shortTicEndY = axisPosition - kShortTickLength;
				}
				else {
					ticStartY	 = lowOffset + (int)(log(val+1)*fscl);		// get pixel position
					shortTicEndX = axisPosition - kShortTickLength;
					shortTicEndY = ticStartY;
				}

				[theAxis moveToPoint:NSMakePoint(ticStartX,ticStartY)];
				[theAxis lineToPoint:NSMakePoint(shortTicEndX,shortTicEndY)];				// draw short tick
			}
			val   = base;
		}
		else {
			val += base;
		}
		if (val > [self maxPad]) break;
	}
        
    [theAxis setLineWidth:1];
    [[self color] set];
    [theAxis stroke];   
}



/* drawLinScale - draw a linear scale */
- (void) drawLinScale {
    
	
	BOOL isX =	[self isXAxis];
    NSBezierPath* theAxis = [NSBezierPath bezierPath];
    
	gridCount = 0;
	BOOL isOpposite = [self oppositePosition];
    
    double tstep  = [self getValRel:[self optimalLabelSeparation]]; // distance between ticks (scale units)
    
    int		sign = 1;			// sign of scale range
    if (tstep < 0) {
        sign = -1;
        tstep *= sign;
    }
    /*
     ** Old getSep() Routine:  Determine axis labelling strategies.
     **
     ** Input:	tstep = number of units between optimally spaced labels
     ** Output:	tick  = number of units between ticks
     **          sep   = number of units between labels
     */
    int power = floor(log10(tstep));					// exponent part of label sep
    
    if ([self integer] && power<0) power = 0;

    double order = pow(10.0,power);
    int i        = 10.0*tstep/order;	// get first two digits
    
	int sep,ticks;
    if      (i >= 65) { sep = 1; ticks = 5; ++power; order*=10; }
    else if (i >= 35) { sep = 5; ticks = 5; }
    else if (i >= 15) { sep = 2; ticks = 4; }
    else		 	  { sep = 1; ticks = 5; }
    
    if (!power && [self integer]) ticks = sep;		// no sub-ticks for integer scales
    /*
     ** End of old getSep() routine
     */
    double step  = sep  * order;   //dis between two digits
    int   ival   = floor([self minPad]/step);
    double val	 = ival * step;			// value for first label below scale
    tstep  = step/ticks;
    ival  *= sep;
    char suffix = symbols[(power-kFirstSymbolExponent)/3];
 
	char dec = 0;			// flag to print decimal point
    
    switch ((power-kFirstSymbolExponent)%3) {
        case 0:
		break;
        case 1:
            ival *= 10;
            sep  *= 10;
		break;
        case 2:
            if (suffix) {			// a- (void) extra trailing zeros if suffix
                suffix= symbols[(power-kFirstSymbolExponent)/3+1];		// next suffix
                dec   = 1;			// use decimal point (/10)
            } 
            else {
                ival *= 100;
                sep  *= 100;
            }
		break;
    }
	
    double tol  = [self getValRel:1]/2;			// tolerance for equality (1/2 pixel)
    double lim  = -tol;							// limit for loops
    val -= [self minPad];						// subtract origin (GetPixRel is relative)
    
    if (val*sign < lim*sign) {
        ival += sep;					// get ival for first label
        for (i=0; val*sign<lim*sign; ++i) {
            val += tstep;				// find first tick on scale
        }
    }
    else i = ticks;					// first tick is at label
    
    lim  = [self valueRange] + tol;				// upper limit for scale value
 	int			axisStartX,axisStartY;
	int			axisEndX,axisEndY;
	int			axisPosition;
	int			shortTicEndX,shortTicEndY;
	int			ticStartX,ticStartY;
	int			longTicEndX,longTicEndY;
	int			mediumTicEndX,mediumTicEndY;
	int			gridPosition;
	
    if (isX) {
		if(isOpposite)	axisPosition  = 0;
		else			axisPosition  = [self frame].size.height;
		axisStartX    = lowOffset-2;
		axisStartY    = axisPosition;
		axisEndX	  = highOffset+1;
		axisEndY	  = axisPosition;
		ticStartX	  = lowOffset;
		ticStartY	  = axisPosition;
		longTicEndX   = lowOffset;
	}
    else {
		if(isOpposite)	axisPosition  = 0;
		else			axisPosition  = [self frame].size.width;
		axisStartX    = axisPosition;
		axisStartY    = lowOffset-2;
		axisEndX	  = axisPosition;
		axisEndY	  = highOffset+1;
		ticStartX	  = axisPosition;
		ticStartY	  = lowOffset;
		longTicEndY   = lowOffset;
	}    

	
	NSNumber* markerNumber = [attributes objectForKey:kMarker];
	if(markerNumber){	
		[self drawMarker:[markerNumber floatValue] axisPosition:axisPosition];
	}

	[theAxis moveToPoint:NSMakePoint(axisStartX,axisStartY)];						// draw axis line
	[theAxis lineToPoint:NSMakePoint(axisEndX,axisEndY)];
	
	--axisPosition;

	//setup the variables that don't change in the loop to come....
    if (isX) {
		ticStartY = axisPosition;	
		if(isOpposite){
			shortTicEndY =  kShortTickLength+1;
			mediumTicEndY =  kMediumTickLength+1;
			longTicEndY =  kLongTickLength+1;
		}
		else {
			shortTicEndY = axisPosition - kShortTickLength;
			mediumTicEndY = axisPosition - kMediumTickLength;
			longTicEndY = axisPosition - kLongTickLength;
		}
	}
    else {
		ticStartX = axisPosition;
		if(isOpposite){
			ticStartX	  = axisPosition+2;
			shortTicEndX  = kShortTickLength+1;
			mediumTicEndX = kMediumTickLength+1;
			longTicEndX   =  kLongTickLength+1;
		}
		else {
			ticStartX	  = axisPosition;
			shortTicEndX  = axisPosition - kShortTickLength;
			mediumTicEndX = axisPosition - kMediumTickLength;
			longTicEndX   = axisPosition - kLongTickLength;
		}
	}    

	for (;;) {
		if(isX){
			ticStartX = lowOffset + [self getPixRel:val];				// get pixel position
			mediumTicEndX = ticStartX;
			shortTicEndX = ticStartX;
			longTicEndX = ticStartX;
			gridPosition = ticStartX-lowOffset;
		}
		else {
			ticStartY = lowOffset + [self getPixRel:val];				// get pixel position
			mediumTicEndY = ticStartY;
			shortTicEndY = ticStartY;
			longTicEndY = ticStartY;
			gridPosition = ticStartY-lowOffset;
		}
	
		[theAxis moveToPoint:NSMakePoint(ticStartX,ticStartY)];
		if (i < ticks) {
			if (ticks==4 && i==2) {
				[theAxis lineToPoint:NSMakePoint(mediumTicEndX,mediumTicEndY)];			// draw medium tick
			}
			else {
				[theAxis lineToPoint:NSMakePoint(shortTicEndX,shortTicEndY)];			// draw short tick
			}
			++i;
		}
		else {
			[theAxis lineToPoint:NSMakePoint(longTicEndX,longTicEndY)];				// draw long tick
			if (gridCount<kMaxLongTicks) {
				gridArray[gridCount++] = gridPosition;
			}
			NSString* axisNumberString;
			if (!ival) axisNumberString = @"0";
			else if (dec) {
				if (ival<0) axisNumberString = [NSString stringWithFormat:@"-%.1d.%.1d%c",(-ival)/10,(-ival)%10,suffix];
				else		axisNumberString = [NSString stringWithFormat:@"%.1d.%.1d%c",ival/10,ival%10,suffix];
			} else			axisNumberString = [NSString stringWithFormat:@"%d%c",ival,suffix];
			NSSize axisNumberSize = [axisNumberString sizeWithAttributes:labelAttributes];
			if(isX){
				if(isOpposite) [axisNumberString drawAtPoint:NSMakePoint(ticStartX+kXNumberCenter - axisNumberSize.width/2,axisPosition + kLongTickLength+3) withAttributes:labelAttributes];
				else [axisNumberString drawAtPoint:NSMakePoint(ticStartX+kXNumberCenter - axisNumberSize.width/2,axisPosition-kXNumberTopEdge-1-axisNumberSize.height) withAttributes:labelAttributes];
			}
			else {
				if(isOpposite)[axisNumberString drawAtPoint:NSMakePoint(axisPosition + kLongTickLength+4,ticStartY+1-axisNumberSize.height/2) withAttributes:labelAttributes];
				else [axisNumberString drawAtPoint:NSMakePoint(axisPosition-kXNumberCenter - axisNumberSize.width - kLongTickLength-2,ticStartY+1-axisNumberSize.height/2) withAttributes:labelAttributes];
			}
			ival += sep;
			i = 1;
		}
		val += tstep;
		if (sign==1) {
			if (val > lim) break;
		}
		else {
			if (val < lim) break;
		}
	}
    
    [theAxis setLineWidth:1];
    [[self color] set];
    [theAxis stroke];
}


- (void) adjustSize:(NSDictionary*)oldLabelAttributes
{
    NSPoint newOrigin;
    NSSize	newSize;
    NSRect  oldFrame = [self frame];
    
	int titleHeight		= [[self label] sizeWithAttributes:oldLabelAttributes].height;
    int oldLabelHeight	= [kLongestNumber sizeWithAttributes:oldLabelAttributes].height;
    int oldLabelWidth	= [kLongestNumber sizeWithAttributes:oldLabelAttributes].width;
	BOOL isOpposite = [self oppositePosition];

    /* size the pane to fit the new text */
    if ([self isXAxis]) {
		float dw = oldLabelWidth-[kLongestNumber sizeWithAttributes:labelAttributes].width;
		newOrigin.x = oldFrame.origin.x + dw/2;     //1/2 to each end.
		float totalHeight = kLongTickLength + oldLabelHeight + titleHeight + 5;
		if(!isOpposite){
			float upperLeftY = oldFrame.origin.y + oldFrame.size.height;
			newOrigin.y = upperLeftY - totalHeight;
		}
		else {
			newOrigin.y = oldFrame.origin.y;
		}
		newSize.width = oldFrame.size.width - dw;
		newSize.height = totalHeight;
    }
    else {
		float dh = oldLabelHeight-[kLongestNumber sizeWithAttributes:labelAttributes].height;
		float totalWidth = kLongTickLength + oldLabelWidth;// + titleHeight;
		newOrigin.y = oldFrame.origin.y - dh/2; //1/2 to each end.
		if(!isOpposite){
			float upperRightX = oldFrame.origin.x + oldFrame.size.width;
			newOrigin.x = upperRightX - totalWidth;     
		}
		else {
			newOrigin.x = oldFrame.origin.x;     
		}
		newSize.height = oldFrame.size.height + dh;
		newSize.width = totalWidth;

    }
    
    [self setFrameOrigin:newOrigin];
    [self setFrameSize:newSize];
    [self calcFrameOffsets];
    
}


- (BOOL) dragScaleToLow:(double)aLow withHigh:(double)aHigh
{
    if(firstDrag || !mDragInProgress){
        //[[[self undoManager] prepareWithInvocationTarget:self] dragScaleToLow:[self minValue] withHigh:[self maxValue]];
        firstDrag = NO;
    }
    return [self setRngLow:aLow withHigh:aHigh];
}

@end //private


long roundToLong(double x)
{
    return(x>0 ? (long)(x+0.5) : (long)(x-0.499999999999));
}


