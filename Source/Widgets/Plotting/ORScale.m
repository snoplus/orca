#import "ORScale.h"

@implementation ORScale

enum {
	DEF_TEXT_SIZE		= 9,				// default point size for text
	DEF_TEXT_FONT		= kFontIDGeneva,		// default font for scale text
	DEF_TEXT_STYLE		= normal,			// default stylle for scale text
	LBL_WID			= 32,				// pixel width of label
	LBL_HIGH		= 16,				// pixel height of label
	SHORT_TICK		= 1,				// length of short tick
	MED_TICK		= 2,				// length of medium tick
	LONG_TICK		= 3				// length of long tick
};

/*
 * Definitions for text size calculations
 */
#define LONG_LBL			@"1000M"			// longest scale label
#define	XLDX				0			// x-label dx (center)
#define	XLDY				(LONG_TICK + 1)		// x-label dy (top edge)
#define	YLDX				(-LONG_TICK - 3)	// y-label dx (right edge)
#define	YLDY				0			// y-label dy (center)
#define YL_MASK_TOP			(LONG_TICK + 3)		// y-label mask top margin
#define	XSCALE_ROOM_LEFT	(lblWid/2)		// room needed left of x axis
#define	XSCALE_ROOM_RIGHT	(lblWid/2)		// room needed right of x axis
#define	XSCALE_ROOM_BELOW	(lblHigh + XLDY)	// room below x axis
#define	YSCALE_ROOM_LEFT	(lblWid  - YLDX)	// room to left of y axis
#define	YSCALE_ROOM_ABOVE	(lblHigh/2 - 2)		// room above y axis
#define	YSCALE_ROOM_BELOW	(lblHigh/2 - 2)		// room below y axis
#define	XLABEL_SEP			(lblWid * 7 / 4)	// optimal x scale label sep
#define	YLABEL_SEP			(lblHigh * 3)		// optimal y scale label sep
#define PIN_TOL				4			// pixel tolerance for pin cursor

/* other definitions */
#define	FIRST_POW		-15			// first symbol exponent
#define	POW_ZERO		5			// position of zero power symbol
#define	DEF_LOW			0			// default scale range (low end)
#define	DEF_HI			1000		// default scale range (high end)
#define	DEF_MIN_MIN		0			// default absolute scale minimum
#define	DEF_MAX_MAX		1e10		// default absolute scale maximum
#define	DEF_MIN_RNG		1e-13		// default absolute minimum range
//#define LOGMIN		1e-1000		// minimum argument for log()
#define	LOGMIN			1e-100		// minimum argument for log() MAH...to remove overflow error on PCC 
#define	EXPMAX			1000		// maximum argument for exp()
#define LARGE_NUMBER		1e100	// large number for divide by zero result

#define	COMMAND_KEY_CODE	55
#define	SHIFT_KEY_CODE		56
#define	OPTION_KEY_CODE		58

/* static variable initializations */
short		nearPinFlag	= 0;
BOOL		dragFlag	= NO;
BOOL		saveRng		= NO;

static char	symbols[]	= "fpnµm\0kMG";		// symbols for exponents

NSString* ORScaleRangeChangedNotification = @"ORScale Range Changed";
NSString* ORScaleMinValue 	= @"ORScaleMinValue";
NSString* ORScaleMaxValue 	= @"ORScaleMaxValue";
NSString* ORScaleUseLog 	= @"ORScaleUseLog";

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
    self = [super initWithFrame:aFrame];
    /* setup local varables */
    
    mFlags       =0;
    maxMax    	= DEF_MAX_MAX;
    minMin    	= DEF_MIN_MIN;
    minRng		= DEF_MIN_RNG;
    minSav		= DEF_LOW;
    maxSav		= DEF_HI;
    padding   	= 0;
    pinVal    	= 0;
    invertPin 	= NO;

    lblWid    	= LBL_WID;
    lblHigh		= LBL_HIGH;
    
    ignoreMouse = NO;
    allowShifts = YES;
    
    logScale  = NO;
    integer	  = YES;
    
    if (aFrame.size.width > aFrame.size.height) {
        pinned = NO;
        xaxis  = YES; 
        dlbl   = XLABEL_SEP;
    /* else it must be a vertical scale */
    }
    else {
        [self setLog:YES];
        pinned = YES;
        xaxis  = NO;
        dlbl   = YLABEL_SEP;
     }
    
    [self prepareAttributes];
    [self setRngLow];
    [self setRngLow:DEF_LOW withHigh:DEF_HI];
    [self setRngDefaultsLow:DEF_LOW withHigh:DEF_HI];

    [self setColor:[NSColor blackColor]];
    [self setGridArray: [NSMutableArray array]];

	[self setAttributes:[NSMutableDictionary dictionary]];
    
    return self;
}

- (void) dealloc
{
    [gridArray release];
    [mFont release];
    [mColor release];
    [labelAttributes release];
    [attributes release];
    [super dealloc];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void) setColor:(NSColor*)aColor
{
    if(aColor!=mColor){
        [mColor release];
        mColor = [aColor retain];
        [self setNeedsDisplay: YES];
		[mView setNeedsDisplay:YES];;
    }
}
- (void) setTextFont:(NSFont*)font
{
    
    if(font!=mFont){
        [mFont release];
        mFont = [font retain];
        [labelAttributes setObject: mFont
                            forKey: NSFontAttributeName];

        lblWid  = [LONG_LBL sizeWithAttributes:labelAttributes].width;
        lblHigh = [LONG_LBL sizeWithAttributes:labelAttributes].height;


        [self adjustSize];
		[self setNeedsDisplay: YES];
		[mView setNeedsDisplay:YES];;
    }
}

- (void)prepareAttributes
{
    labelAttributes = [[NSMutableDictionary alloc] init];
}

- (void) adjustSize
{

    NSPoint     newOrigin;
    NSSize	newSize;
    short 	dw,dh;
    short	oldWid, oldHigh;
    NSRect      oldFrame = [self frame];

    oldWid = lblWid;
    oldHigh = lblHigh;

    lblWid = [LONG_LBL sizeWithAttributes:labelAttributes].width;
    lblHigh = [LONG_LBL sizeWithAttributes:labelAttributes].height;
        
    /* size the pane to fit the new text */
    if (xaxis) {
        dlbl = XLABEL_SEP;
        dw = lblWid - oldWid;
        newOrigin.x = oldFrame.origin.x - dw/2;
        newSize.width = oldFrame.size.width + dw;
        
        newSize.height = XSCALE_ROOM_BELOW;
        newOrigin.y = oldFrame.origin.y+oldFrame.size.height-newSize.height-9;
    }
    else {
        dlbl = YLABEL_SEP;
        dh = oldHigh/2 - lblHigh/2;
       // dw = lblWid/2 - oldWid/2;
        newOrigin.x = oldFrame.origin.x - dw;
        newOrigin.y = oldFrame.origin.y - dh;
        // newSize.width = oldFrame.size.width + dw;
        newSize.width = YSCALE_ROOM_LEFT;
        newSize.height = oldFrame.size.height + dh;
        newOrigin.x = oldFrame.origin.x+oldFrame.size.width-newSize.width-8;
    }

    [self setFrameOrigin:newOrigin];
    [self setFrameSize:newSize];

}



-(id)initWithCoder:(NSCoder*)coder
{
    if(self = [super initWithCoder:coder]){
       [coder decodeValueOfObjCType:@encode(double) at: &minPad];
        [coder decodeValueOfObjCType:@encode(double) at: &maxPad];
        [coder decodeValueOfObjCType:@encode(double) at: &minVal];
        [coder decodeValueOfObjCType:@encode(double) at: &maxVal];
        [coder decodeValueOfObjCType:@encode(double) at: &minMin];
        [coder decodeValueOfObjCType:@encode(double) at: &maxMax];
        [coder decodeValueOfObjCType:@encode(double) at: &minDef];
        [coder decodeValueOfObjCType:@encode(double) at: &maxDef];
        [coder decodeValueOfObjCType:@encode(double) at: &minSav];
        [coder decodeValueOfObjCType:@encode(double) at: &maxSav];
        [coder decodeValueOfObjCType:@encode(double) at: &minRng];
        [coder decodeValueOfObjCType:@encode(double) at: &pinPix];
        [coder decodeValueOfObjCType:@encode(double) at: &valRng];
        [coder decodeValueOfObjCType:@encode(double) at: &fscl];
        [coder decodeValueOfObjCType:@encode(double) at: &fpos];
        [coder decodeValueOfObjCType:@encode(double) at: &offset];
        [coder decodeValueOfObjCType:@encode(double) at: &padding];
        [coder decodeValueOfObjCType:@encode(double) at: &pinVal];
        [coder decodeValueOfObjCType:@encode(BOOL) 	 at: &xaxis];
        [coder decodeValueOfObjCType:@encode(BOOL)   at: &logScale];
        [coder decodeValueOfObjCType:@encode(BOOL)   at: &integer];
        [coder decodeValueOfObjCType:@encode(BOOL)   at: &pinned];
        [coder decodeValueOfObjCType:@encode(BOOL)   at: &invertPin];
        [coder decodeValueOfObjCType:@encode(BOOL)   at: &ignoreMouse];
        [coder decodeValueOfObjCType:@encode(BOOL)   at: &allowShifts];
        [coder decodeValueOfObjCType:@encode(short)  at: &lblWid];
        [coder decodeValueOfObjCType:@encode(short)  at: &lblHigh];
        [coder decodeValueOfObjCType:@encode(short)  at: &mFlags];
        [coder decodeValueOfObjCType:@encode(short)  at: &dlbl];
        [coder decodeValueOfObjCType:@encode(short)  at: &dpos];
        [coder decodeValueOfObjCType:@encode(short)  at: &lowOffset];
        [coder decodeValueOfObjCType:@encode(short)  at: &highOffset];
        [self prepareAttributes];
        [self setTextFont :[coder decodeObject]];

        [self setGridArray: [NSMutableArray array]];
        [self setRngLow];
        [self setColor:[NSColor blackColor]];

		[self setAttributes:[NSMutableDictionary dictionary]];

    }
    return self;
}

-(void)	encodeWithCoder:(NSCoder*)coder
{
    [super encodeWithCoder:coder];
    [coder encodeValueOfObjCType:@encode(double) at: &minPad];
    [coder encodeValueOfObjCType:@encode(double) at: &maxPad];
    [coder encodeValueOfObjCType:@encode(double) at: &minVal];
    [coder encodeValueOfObjCType:@encode(double) at: &maxVal];
    [coder encodeValueOfObjCType:@encode(double) at: &minMin];
    [coder encodeValueOfObjCType:@encode(double) at: &maxMax];
    [coder encodeValueOfObjCType:@encode(double) at: &minDef];
    [coder encodeValueOfObjCType:@encode(double) at: &maxDef];
    [coder encodeValueOfObjCType:@encode(double) at: &minSav];
    [coder encodeValueOfObjCType:@encode(double) at: &maxSav];
    [coder encodeValueOfObjCType:@encode(double) at: &minRng];
    [coder encodeValueOfObjCType:@encode(double) at: &pinPix];
    [coder encodeValueOfObjCType:@encode(double) at: &valRng];
    [coder encodeValueOfObjCType:@encode(double) at: &fscl];
    [coder encodeValueOfObjCType:@encode(double) at: &fpos];
    [coder encodeValueOfObjCType:@encode(double) at: &offset];
    [coder encodeValueOfObjCType:@encode(double) at: &padding];
    [coder encodeValueOfObjCType:@encode(double) at: &pinVal];
    [coder encodeValueOfObjCType:@encode(BOOL) 	 at: &xaxis];
    [coder encodeValueOfObjCType:@encode(BOOL)   at: &logScale];
    [coder encodeValueOfObjCType:@encode(BOOL)   at: &integer];
    [coder encodeValueOfObjCType:@encode(BOOL)   at: &pinned];
    [coder encodeValueOfObjCType:@encode(BOOL)   at: &invertPin];
    [coder encodeValueOfObjCType:@encode(BOOL)   at: &ignoreMouse];
    [coder encodeValueOfObjCType:@encode(BOOL)   at: &allowShifts];
    [coder encodeValueOfObjCType:@encode(short)  at: &lblWid];
    [coder encodeValueOfObjCType:@encode(short)  at: &lblHigh];
    [coder encodeValueOfObjCType:@encode(short)  at: &mFlags];
    [coder encodeValueOfObjCType:@encode(short)  at: &dlbl];
    [coder encodeValueOfObjCType:@encode(short)  at: &dpos];
    [coder encodeValueOfObjCType:@encode(short)  at: &lowOffset];
    [coder encodeValueOfObjCType:@encode(short)  at: &highOffset];
    [coder encodeObject:mFont];
}

- (void) drawRect:(NSRect) area
{    
    if (logScale) [self drawLogScale];
    else		  [self drawLinScale];
}




/* nearPinpoint - are we near the pin point for the scale */
/* Note: The point must be pre-corrected for the scale start position */
/* Return value: -1=below pin point, 0=at pin point, 1=above pin point */
- (short) nearPinPoint:(NSPoint) where
{
	short	pix, diff;
	
	/* don't yet support shiftable log scales */
	if (logScale) return 1;
	
	/* whole scale causes shift if not pinned */
	if (allowShifts && !(pinned^dragFlag)) return 0;
	
	/* get cursor pixel index */
	if (xaxis) pix = where.x;
	else	   pix = where.y;
	
	/* are we within PIN_TOL pixels of the scale end nearest the pinpoint? */
	if (allowShifts && ((pinVal>=maxVal && pix>dpos-PIN_TOL) || (pinVal<=minVal && pix<PIN_TOL))) {
		return 0;
	}
	
	/* are we within PIN_TOL pixels of the pin point itself? */
	diff = pix - roundPH(pinPix);
	
	if (allowShifts) {
		if (diff > PIN_TOL) return 1;
		if (diff < -PIN_TOL) return -1 ;
	} else {
		if (diff < 0) return -1;
		return YES;
	}
	return NO;
}	


/* setInteger - change the scale integer flag */
- (void) setInteger:(BOOL) isInt
{
    if (isInt != integer) {
        /* set the instance variable */
        integer = isInt;
        
        /* must re-calculate log scaling factors */
        [self calcSci];
        /* redraw the scale */
    }
	[self setNeedsDisplay:YES];
	[mView setNeedsDisplay:YES];;
}



/* ResizeFrame - handle a resize message */
//- (void) ResizeFrame(Rect *delta)
//{
//	CPixMapPanePH::ResizeFrame(delta);
	
//	[self setRngLow];
//}



/* setRngLow - Set Scale size parameters according to size of CPane */
- (void) setRngLow
{

    if (xaxis) {
        lowOffset = XSCALE_ROOM_LEFT;
        highOffset = [self frame].size.width - XSCALE_ROOM_RIGHT - 1;
        dpos = highOffset - lowOffset;
    } else {
        lowOffset = YSCALE_ROOM_BELOW;
        highOffset = [self frame].size.height - YSCALE_ROOM_ABOVE - 1;
        dpos = highOffset-lowOffset;
    }
    /* must re-calculate log scaling factors */
    [self calcSci];
}

/* SetPadding - set scale padding */
- (void) setPadding:(double) pad
{
    if (pad != padding) {
        padding = pad;
        minPad = minVal - padding;
        maxPad = maxVal - padding;
        [self setNeedsDisplay:YES];;
		[mView setNeedsDisplay:YES];;
    }
}


-(BOOL) isLog
{
    return logScale;
}

/* setLog - change from log to linear scales */
- (void) setLog:(BOOL) isLog
{
    if (isLog != logScale) {

        /* set the instance variable */
        logScale = isLog;	
        
        /* must re-calculate log scaling factors */
        [self calcSci];;
        
        /* redraw the scale */
    }
	[self setNeedsDisplay:YES];
	[mView setNeedsDisplay:YES];
}

/* getLblWid - get label width */
- (short) getLblWid
{
    return lblWid ;
}



/* GetLblHigh - get label height */
- (short) getLblHigh
{
    return lblHigh ;
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
    minMin = low;
    maxMax = high;
    
    /* make sure the minimum range value is not silly */
    if (min_rng > maxMax-minMin) {
            minRng = maxMax - minMin;
    } else {
            minRng = min_rng;
    }
    [self setRngLow:minVal withHigh:maxVal];
}



/* setRngDefaultsLow:High - set the default range for this scale */
- (void) setRngDefaultsLow:(double)aLow withHigh:(double)aHigh
{
    [self checkRngLow:&aLow withHigh:&aHigh];
    minDef = aHigh;
    maxDef = aHigh;
}



/* setDefaultRng - reset range to default limits and save current range */
- (short) setDefaultRng
{
    return [self setRngLow:minDef withHigh:maxDef];
}



/* setFullRng - set range to its full scale */
- (short) setFullRng
{
    return [self setRngLow:minMin withHigh:maxMax];
}



/* saveRngOnChange() - cause current range to be saved if next setRngLow changes the scale */
- (void) saveRngOnChange
{
    saveRng = YES;
}



/* saveRng() - save current range */
- (void) saveRng
{
    minSav = minVal;
    maxSav = maxVal;
}

	

/* restoreRng() - restore saved range */
- (short) restoreRng
{
    return [self setRngLow:minSav withHigh:maxSav];
}
	


/* setOrigin - set origin of scale (keeping the same range) */
- (short) setOrigin:(double) low
{
    return [self setRngLow:low withHigh:low+valRng];
}



/* shiftOrigin - shift the scale origin */
- (short) shiftOrigin:(double) delta
{
    return[self setOrigin:minVal + delta];
}



/* calcLogScl - calculate scaling factors and pin pix */
- (void) calcSci;
{
    double	rng;
    
    if (dpos <= 0) {
        fscl = 1;
    } else {
        rng = valRng;
        if (logScale) {
            if (integer) rng += 1;
            if (rng < LOGMIN) rng = LOGMIN;
            fscl = dpos / log(rng);
        } else {
            if (rng < LOGMIN) rng = LOGMIN;
            fscl = dpos / rng;
        }
    }
    
    /* calculate pin pixel value */
    pinPix = (pinVal-minVal) * fscl;
}



/* setRngLow - set the scale limits */
/* All scale changes occur via this routine! */
- (short) setRngLow:(double)aLow withHigh:(double)aHigh
{
    BOOL shouldSave = saveRng;
    
    saveRng = NO;

    [self checkRngLow:&aLow withHigh:&aHigh];
    
    if (aHigh==maxVal && aLow==minVal) return 0;
    
    if (shouldSave) {
            minSav = minVal;
            maxSav = maxVal;
    }
    
    minVal = aLow;
    maxVal = aHigh;
    valRng = aHigh - aLow;
    minPad = aLow  - padding;
    maxPad = aHigh - padding;
    
    [self calcSci];
    
    //[self setNeedsDisplay:YES];;
 	//[mView setNeedsDisplay:YES];;
   return(1);
}



/* checkRngLow - make sure new scale limits are within range */
-(short) checkRngLow:(double *)low withHigh:(double *)high
{
    double	t,dv,v1,v2,cen,newPin;
    BOOL	fixedPin;
	
	if(fabs(*low-*high) <.01){
		*high = 10000;
		*low = 0;
	}
			      
    /* convert to integer if integer scale */
    if (integer) {
        *low = roundPH(*low);
        *high = roundPH(*high);
    }
    v1 = *low;
    v2 = *high;

    /* check scale range */
    if (logScale && !integer) {

        /* protect against divide-by-zero */
        if (v1 < LOGMIN) v1 = LOGMIN;
        if (v2 < LOGMIN) v2 = LOGMIN;
        
        dv = v2 / v1;
        
        if (dv < 1.0) {
            v1 = minMin;
            v2 = maxMax;
            dv = v2 - v1;
        } else if (dv < minRng) {
            dv = minRng;
            /* expand scale, keeping the same center */
            cen = (v1 + v2) / 2;
            t = sqrt(dv);
            v1 = cen / dv;
            v2 = cen * dv;
        }
                    
    } else {

        dv = v2 - v1;

        if (dv < minRng) {
            if (dv < 0) {
                v1 = minMin;
                v2 = maxMax;
                dv = v2 - v1;
            } else {
                /* expand scale, keeping the same center */
                cen = (v1 + v2) / 2;
                v1 = cen - minRng/2;
                v2 = v1  + minRng;
                dv = minRng;
                if (integer) {
                    v1 = roundPH(v1);
                    v2 = roundPH(v2);
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
    if (v2 > maxMax) {
    
        v2 = maxMax;
        if (fixedPin) {
            [self adjustToPinLow:&v1 withHigh:&v2];
        } else if (logScale && !integer) {
            v1 = v2 / dv;
        } else {
            v1 = v2 - dv;
        }
    }
    
    /* check scale minimum */
    if (v1 < minMin) {

        v1 = minMin;
        if (fixedPin) {
            [self adjustToPinLow:&v1 withHigh:&v2];
        } else if (logScale && !integer) {
            v2 = v1 * dv;
        } else {
            v2 = v1 + dv;
        }
        /* make sure we haven't put v2 over the top */
        if (v2 > maxMax) v2 = maxMax;
    }
    
    /* update range limits and return */
    if (v1!=*low || v2!=*high) {
        *low = v1;
        *high = v2;
        return(1);
    } else {
        return(0);
    }
}



/* adjustToPin - adjust scale limits to be consistent with pin-point */
- (void) adjustToPinLow:(double *)low withHigh:(double *)high
{
    double	scl1, scl2;
    
    /* keep the pin-point stationary */
    if (pinPix > 0) {
        scl1 = (pinVal - *low) / pinPix;
    } else {
        scl1 = LARGE_NUMBER;
    }
    if (dpos-pinPix > 0) {
        scl2 = (*high - pinVal) / (dpos - pinPix);
    } else {
        scl2 = LARGE_NUMBER;
    }
    if (scl2 < scl1) scl1 = scl2;

    *low = pinVal - scl1 * pinPix;
    *high = pinVal + scl1 * (dpos - pinPix);
    
    /* make sure we haven't set the scale too small */
    if (*high-*low < minRng) *high = *low + minRng;
}



/* getPixAbs - convert from an absolute scale value to an absolute pixel position */
- (short) getPixAbs:(double) val
{
    double	t;

    if (logScale) {
        if (integer) val += 1;
        else val /= minPad;
        if (val < LOGMIN) val = LOGMIN;
        t = log(val) * fscl;			// get pixel position
    } else {
        t = (val-minPad) * fscl;
    }
    
    return(t>0 ? (short)(t+0.5) : (short)(t-0.5));
}



/* getPixRel - convert from a relative scale value to a pixel position */
- (short) getPixRel:(double) val
{
    double	t;

    if (logScale) {
        if (integer) val += 1;
        if (val < LOGMIN) val = LOGMIN;
        t = log(val) * fscl;			// get pixel position
    } else {
        t = val * fscl;
    }
    return(t>0 ? (short)(t+0.5) : (short)(t-0.5));
}



/* GetValAbs - convert from an absolute pixel position to an absolute scale value */
- (double) getValAbs:(short) pix
{
    double	val;
    
    if (logScale) {
        val = exp(pix / fscl);
        if (integer) val -= 1;
        else val *= minPad;
    } else {
        val = minPad + pix / fscl;
    }
    return(val);
}



/* GetVal - convert from a pixel position to a scale value */
- (double) getValRel:(short) pix
{
    double	val;
    
    if (logScale) {
        val = exp(pix / fscl);
        if (integer) val -= 1;
    } else {
        val = pix / fscl;
    }
    return(val);
}



/* GetMinVal - get scale minimum value */
- (double) getMinVal
{
    return(minVal);
}



/* GetMaxVal - get scale maximum value */
- (double) getMaxVal
{
    return(maxVal);
}



/* GetRng - get scale range */
- (double) getRng
{
    return(valRng);
}



/* GetPadding - get scale padding */
- (double) getPadding
{
    return(padding);
}



/* DoClick - handle mouse clicks for CScalePH */
-(void)	mouseDown:(NSEvent*)theEvent
{
    NSEventType modifierKeys;
    NSPoint mouseLoc;
    if (ignoreMouse) return;
    
    mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    modifierKeys = [theEvent modifierFlags];
    
    if (xaxis) {
        modifierKeys |= XAXIS_FLAG;
        mouseLoc.x -= lowOffset;
    } else {
        modifierKeys |= YAXIS_FLAG;
        mouseLoc.y -= lowOffset;
    }

    /* last chance to set the cursor before a grab */
    dragFlag = !(modifierKeys & NSControlKeyMask);
    nearPinFlag = [self nearPinPoint:mouseLoc];
    //SetTheCursor();

    /* invert the pin if we are grabbing near the pin-point */
    if (pinned == (nearPinFlag==0)) {
        invertPin = YES;
    }
    else {
        invertPin = NO;
    }

    if([self mouse:mouseLoc inRect:[self bounds]]){
        mGrabValue = [self startDrag:mouseLoc];  
    }
}

/* mouseDragged - mouse is being dragged */
-(void)	mouseDragged:(NSEvent*)theEvent
{
    NSPoint mouseLoc;
    if(mDragInProgress){
         mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        [self drag:mouseLoc withGrab:mGrabValue];
    }
}

/* mouseDragged - mouse is being dragged */
-(void)	mouseUp:(NSEvent*)theEvent
{
    if(mDragInProgress){
        [self endDrag];
    }
}

/* StartDrag - start dragging the scale */
/* log scale grab only works for scales starting at zero */
/* Note: The point must be pre-corrected for the scale start position */
-(double)startDrag:(NSPoint) p
{
    double		pix;
    
    if (xaxis) 	pix = p.x;
    else 	pix = p.y;

    mDragInProgress = YES;

    return([self convertPoint:pix] );
}

- (double)convertPoint:(double)pix
{
	double p; 
    if (logScale) p = (pix * log(maxVal+1.0)) / dpos;
    else 	  	  p = minVal + [self getValRel:pix];
	return p;
}


/* Drag - drag the scale */
/* log scale drag only works for pinned scales starting at zero */
-(short)drag:(NSPoint) p withGrab:(double) grabVal
{
    double		pix, tmp;
    double		newMin, newMax;
    
    if (xaxis) pix = p.x;
    else	   pix = p.y;

    if (logScale) {

        newMin = 0;
        if (pix && (tmp=grabVal*dpos/pix)<EXPMAX) {
            newMax = exp(tmp) - 1.0;
        } else {
            newMax = maxMax;
        }
            
    }
    else {
      //  if (pinned^invertPin) {
        if (pinned^invertPin | dragFlag) {
            if (pinPix != pix) {
               newMin = (pinVal*pix - grabVal*pinPix) / (pix - pinPix);
                if (pinPix) newMax = newMin + (pinVal-newMin)*dpos/pinPix;
                else		newMax = newMin + (grabVal-newMin)*dpos/pix;
                
                /* make sure scale range is not too small */
                /* (we do this here instead of letting CheckRng() do it	*/
                /* because we want to keep the pin point at the same	*/
                /* location after we adjust the scale range)			*/
                if (newMax-newMin < minRng) {
            
                    if (newMax >= newMin) {
                        
                        /* set scale to minimum range, keeping pin-point at same spot */
                        newMin = pinVal - pinPix * minRng / dpos;
                        newMax = newMin + minRng;
                        
                    }
                    else {
                        newMin = minMin;
                        newMax = maxMax;
                        [self adjustToPinLow:&newMin withHigh:&newMax];
                    }
                }
            
            }
            else {
					NSLog(@"3\n");

                newMin = minMin;
                newMax = maxMax;
                [self adjustToPinLow:&newMin withHigh:&newMax];
            }
                
        }
        else {
                newMin = grabVal - valRng * pix / dpos;
                newMax = newMin + valRng;
                
        }
    }
    
    /* Only force redraw of scale if range indeed changed */
    if ([self setRngLow:newMin withHigh:newMax]) {
        [self setNeedsDisplay:YES];
        [mView setNeedsDisplay:YES];
        return YES;
    }
    return NO;
}



/* endDrag - Clean up after dragging the scale */
- (void) endDrag
{
    /* uninvert the pin in case we inverted it */
    invertPin = NO;
    mDragInProgress = NO;


	[[NSNotificationCenter defaultCenter]
        postNotificationName:ORScaleRangeChangedNotification
        object:self
        userInfo: nil];    

	[self setNeedsDisplay:YES];
	[mView setNeedsDisplay:YES];

}



/* drawLogScale - draw a logarithmic scale */
/* Note: this routine only works for vertical scales which start at zero */
- (void) drawLogScale
{
    char	buff[20];
    short	i,n,x,y;
    short	label_sep,tick_sep;
    double	val, base, div, tmp;
    NSString*	axisNumberString;
    NSSize 	axisNumberSize;
    NSBezierPath* theAxis 	= [NSBezierPath bezierPath];


    [self setGridArray: [NSMutableArray array]];
        
    if (xaxis) {
        y = [self frame].size.height;
         [theAxis moveToPoint:NSMakePoint(lowOffset,y)];// draw axis line
         [theAxis lineToPoint:NSMakePoint(highOffset,y)];

        --y;
        val = log(11.0)*fscl;
        if      (val <  30) { tick_sep=5;  label_sep=10; }
        else if (val <  45) { tick_sep=2;  label_sep=10; }
        else if (val < 120) { tick_sep=2;  label_sep=10;  }
        else if (val < 240) { tick_sep=1;  label_sep=2;  }
        else		    { tick_sep=1;  label_sep=1;  }

		x = lowOffset;
        [theAxis moveToPoint:NSMakePoint(x,y)];
        [theAxis lineToPoint:NSMakePoint(x,y-LONG_TICK)];				// draw long tick
        if ([gridArray count]<kMaxLongTicks) [gridArray addObject: [NSNumber numberWithLong:0]];
			
        axisNumberString = [NSString stringWithCString:"0"];
        axisNumberSize = [axisNumberString sizeWithAttributes:labelAttributes];
		[axisNumberString drawAtPoint:NSMakePoint(x+XLDX - axisNumberSize.width/2,y-XLDY-1-axisNumberSize.height) withAttributes:labelAttributes];

        i = POW_ZERO;

        val = base = div = 1;

        if (label_sep == 2)	n = 0;						// special case to draw "1" label
        else			n = 1;

        for (;;) {

            if (!(n%tick_sep)) {
                x = lowOffset + (short)(log(val+1)*fscl);		// get pixel position
                [theAxis moveToPoint:NSMakePoint(x,y)];
                if ((!(n%label_sep)) || (n==2 && label_sep==5)) {
                        if (!n) n = 1;
                        [theAxis lineToPoint:NSMakePoint(x,y-LONG_TICK)];	// draw long tick
                        if ([gridArray count]<kMaxLongTicks){
                            [gridArray addObject: [NSNumber numberWithLong:y-lowOffset]];
                        }
            
                        tmp = val / div;
                        if (tmp >= 1000) {
                            div *= 1000;
                            tmp = val / div;
                            ++i;
                        }
                        sprintf(buff,"%d%c",(short)tmp,symbols[i]);
                        axisNumberString = [NSString stringWithCString:buff];
                        axisNumberSize = [axisNumberString sizeWithAttributes:labelAttributes];
						[axisNumberString drawAtPoint:NSMakePoint(x+XLDX - axisNumberSize.width/2,y-XLDY-1-axisNumberSize.height) withAttributes:labelAttributes];
                }
                else {
                    [theAxis lineToPoint:NSMakePoint(x,y-SHORT_TICK)];				// draw short tick
                }
            }
            if (++n > 10) {
                n = 1;
                base *= 10;
/*
** draw tick at 15, 150, etc
*/
                if (label_sep<=5 && (val=base*1.5)<=maxPad) {
                    x = lowOffset + (short)(log(val+1)*fscl);	// get pixel position
                    [theAxis moveToPoint:NSMakePoint(x,y)];
                    [theAxis lineToPoint:NSMakePoint(x,y-SHORT_TICK)];				// draw short tick
                }
                val   = base;
            }
            else {
                val += base;
            }
            if (val > maxPad) break;
        }
	}
	else {
        x = [self frame].size.width - 1;
        [theAxis moveToPoint:NSMakePoint(x,lowOffset-1)];
        [theAxis lineToPoint:NSMakePoint(x,highOffset-2)];
        --x;
        val = log(11.0)*fscl;
        if      (val <  30) { tick_sep=5;  label_sep=10; }
        else if (val <  45) { tick_sep=2;  label_sep=10; }
        else if (val < 120) { tick_sep=1;  label_sep=5;  }
        else if (val < 240) { tick_sep=1;  label_sep=2;  }
        else		    	{ tick_sep=1;  label_sep=1;  }

        [theAxis moveToPoint:NSMakePoint(x,lowOffset)];
        [theAxis lineToPoint:NSMakePoint(x-LONG_TICK,lowOffset)];				// draw long tick
        if ([gridArray count]<kMaxLongTicks) [gridArray addObject: [NSNumber numberWithLong:0]];

        axisNumberString = [NSString stringWithCString:"0"];
        axisNumberSize = [axisNumberString sizeWithAttributes:labelAttributes];
        [axisNumberString drawAtPoint:NSMakePoint(x+YLDX+1 - axisNumberSize.width,lowOffset+YLDY-axisNumberSize.height/2) withAttributes:labelAttributes];

        i = POW_ZERO;

        val = base = div = 1;

        if (label_sep == 2)	n = 0;						// special case to draw "1" label
        else			n = 1;

        for (;;) {

            if (!(n%tick_sep)) {
                y = lowOffset + (short)(log(val+1)*fscl);		// get pixel position
                [theAxis moveToPoint:NSMakePoint(x,y)];
                if ((!(n%label_sep)) || (n==2 && label_sep==5)) {
                        if (!n) n = 1;
                        [theAxis lineToPoint:NSMakePoint(x-LONG_TICK,y)];	// draw long tick
                        if ([gridArray count]<kMaxLongTicks){
                            [gridArray addObject: [NSNumber numberWithLong:y-lowOffset]];
                        }
            
                        tmp = val / div;
                        if (tmp >= 1000) {
                            div *= 1000;
                            tmp = val / div;
                            ++i;
                        }
                        sprintf(buff,"%d%c",(short)tmp,symbols[i]);
                        axisNumberString = [NSString stringWithCString:buff];
                        axisNumberSize = [axisNumberString sizeWithAttributes:labelAttributes];
                        [axisNumberString drawAtPoint:NSMakePoint(x+YLDX+1 - axisNumberSize.width, y+YLDY-axisNumberSize.height/2) withAttributes:labelAttributes];
                }
                else {
                    [theAxis lineToPoint:NSMakePoint(x-SHORT_TICK,y)];				// draw short tick
                }
            }
            if (++n > 10) {
                n = 1;
                base *= 10;
/*
** draw tick at 15, 150, etc
*/
                if (label_sep<=5 && (val=base*1.5)<=maxPad) {
                    y = lowOffset + (short)(log(val+1)*fscl);	// get pixel position
                    [theAxis moveToPoint:NSMakePoint(x,y)];
                    [theAxis lineToPoint:NSMakePoint(x-SHORT_TICK,y)];				// draw short tick
                }
                val   = base;
            }
            else {
                val += base;
            }
            if (val > maxPad) break;
        }	}

    [mColor set];
    [theAxis stroke];
}



/* drawLinScale - draw a linear scale */
- (void) drawLinScale
{
    char		buff[20];			// pointer to label string
    short		i, x, y;			// general variables
    double		val;				// true value of scale units
    short		ival;				// integer mantissa of scale units
    short		sep;				// mantissa of label separation
    short		power;				// exponent of label separation
    short		ticks;				// number of ticks per label
    short		sign = 1;			// sign of scale range
    double		order;				// 10^power
    double		step;				// distance between labels (scale units)
    double		tstep;				// distance between ticks (scale units)
    double		tol;				// tolerance for equality (1/2 pixel)
    double		lim;				// limit for loops
    char		suffix;				// suffix for number
    char		dec = 0;			// flag to print decimal point
    NSSize 		axisNumberSize;
    NSBezierPath* theAxis = [NSBezierPath bezierPath];
    NSString*	axisNumberString;
    
    [self setGridArray: [NSMutableArray array]];
    
    tstep  = [self getValRel:dlbl];

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
    power = floor(log10(tstep));					// exponent part of label sep
    
    if (integer && power<0) power = 0;
    
    i     = 10.0*tstep/(order = pow(10.0,power));	// get first two digits

    if      (i >= 65) { sep = 1; ticks = 5; ++power; order*=10; }
    else if (i >= 35) { sep = 5; ticks = 5; }
    else if (i >= 15) { sep = 2; ticks = 4; }
    else		 	  { sep = 1; ticks = 5; }

    if (!power && integer) ticks = sep;		// no sub-ticks for integer scales
/*
** End of old getSep() routine
*/
    step   = sep  * order;
    ival   = floor(minPad/step);
    val	   = ival * step;			// value for first label below scale
    tstep  = step/ticks;
    ival  *= sep;
    suffix = symbols[(power-FIRST_POW)/3];

    switch ((power-FIRST_POW)%3) {
        case 0:
        break;
        case 1:
            ival *= 10;
            sep  *= 10;
        break;
        case 2:
            if (suffix) {			// a- (void) extra trailing zeros if suffix
                suffix= symbols[(power-FIRST_POW)/3+1];		// next suffix
                dec   = 1;			// use decimal point (/10)
            } else {
                ival *= 100;
                sep  *= 100;
            }
        break;
    }
    tol  = [self getValRel:1]/2;
    lim  = -tol;
    val -= minPad;						// subtract origin (GetPixRel is relative)

    if (val*sign < lim*sign) {
        ival += sep;					// get ival for first label
        for (i=0; val*sign<lim*sign; ++i) {
            val += tstep;				// find first tick on scale
        }
    }
    else i = ticks;					// first tick is at label

    lim  = valRng + tol;				// upper limit for scale value

    if (xaxis) {

         y = [self frame].size.height;
         [theAxis moveToPoint:NSMakePoint(lowOffset,y)];						// draw axis line
         [theAxis lineToPoint:NSMakePoint(highOffset,y)];
        --y;
        for (;;) {
            x = lowOffset + [self getPixRel:val];				// get pixel position
            [theAxis moveToPoint:NSMakePoint(x,y)];
            if (i < ticks) {
                if (ticks==4 && i==2) {
                    [theAxis lineToPoint:NSMakePoint(x,y-MED_TICK)];			// draw medium tick
                }
                else {
                    [theAxis lineToPoint:NSMakePoint(x,y-SHORT_TICK)];			// draw short tick
                }
                ++i;
            }
            else {
                [theAxis lineToPoint:NSMakePoint(x,y-LONG_TICK)];				// draw long tick
                if ([gridArray count]<kMaxLongTicks) {
                    [gridArray addObject: [NSNumber numberWithLong:x-lowOffset]];
                }
                if (!ival) strcpy(buff,"0");
                else if (dec) {
                    if (ival<0) sprintf(buff,"-%.1d.%.1d%c",(-ival)/10,(-ival)%10,suffix);
                    else		sprintf(buff,"%.1d.%.1d%c",ival/10,ival%10,suffix);
                } else			sprintf(buff,"%d%c",ival,suffix);
                axisNumberString = [NSString stringWithCString:buff];
                axisNumberSize = [axisNumberString sizeWithAttributes:labelAttributes];
               [axisNumberString drawAtPoint:NSMakePoint(x+XLDX - axisNumberSize.width/2,y-XLDY-1-axisNumberSize.height) withAttributes:labelAttributes];
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

    } 
	else {

        x = [self frame].size.width;
        [theAxis moveToPoint:NSMakePoint(x,lowOffset-1)];
        [theAxis lineToPoint:NSMakePoint(x,highOffset+3)];								// draw axis line
        --x;
        for (;;) {
            y = lowOffset + [self getPixRel:val];				// get pixel position
            [theAxis moveToPoint:NSMakePoint(x,y)];
            if (i < ticks) {
                if (ticks==4 && i==2) {
                    [theAxis lineToPoint:NSMakePoint(x-MED_TICK,y)];			// draw medium tick
                } else {
                    [theAxis lineToPoint:NSMakePoint(x-SHORT_TICK,y)];			// draw short tick
                }
                ++i;
            }
            else {
                [theAxis lineToPoint:NSMakePoint(x-LONG_TICK,y)];				// draw long tick
                if ([gridArray count]<kMaxLongTicks) {
                    [gridArray addObject: [NSNumber numberWithLong:y-lowOffset]];
                }
                if (!ival) strcpy(buff,"0");
                else if (dec) {
                    if (ival<0) sprintf(buff,"-%.1d.%.1d%c",(-ival)/10,(-ival)%10,suffix);
                    else	sprintf(buff,"%.1d.%.1d%c",ival/10,ival%10,suffix);
                }
                else		sprintf(buff,"%d%c",ival,suffix);
                axisNumberString = [NSString stringWithCString:buff];
                axisNumberSize = [axisNumberString sizeWithAttributes:labelAttributes];

                [axisNumberString drawAtPoint:NSMakePoint(x+YLDX+1 - axisNumberSize.width,y+YLDY-axisNumberSize.height/2) withAttributes:labelAttributes];
                ival += sep;
                i = 1;
            }
            val += tstep;
            if (sign==1) {
                if (val > lim) break;
            } else {
                if (val < lim) break;
            }
        }
    }
    
    [mColor set];
    [theAxis stroke];
}

-(void)	ignoreMouse:(BOOL) ignore
{
    ignoreMouse = ignore;
}

-(void)	allowShifts:(BOOL) allow
{
    allowShifts = allow;
}


-(NSArray*)gridArray
{
    return gridArray;
}

-(void)setGridArray:(NSMutableArray*)anArray
{
    if(anArray!=gridArray){
        [gridArray release];
        gridArray = [anArray retain];
    }
    
}
-(void)setFrame:(NSRect)aFrame
{
    [super setFrame:aFrame];

    xaxis = aFrame.size.width > aFrame.size.height;
    [self setRngLow];
    [self setNeedsDisplay:YES];
    [mView setNeedsDisplay:YES];
}


- (IBAction) setLogScale:(id)sender
{
	[self setLog:[sender intValue]];
}

- (IBAction) shiftLeft:(id)sender
{
    [self doPlotOp:kShiftPlotLeft];
}

- (IBAction) shiftRight:(id)sender
{
    [self doPlotOp:kShiftPlotRight];
}

- (IBAction) zoomIn:(id)sender
{
    [self doPlotOp:kExpandPlot];
}

- (IBAction) zoomOut:(id)sender
{
    [self doPlotOp:kShrinkPlot];
}



- (void) doPlotOp:(int)plotOp
{
    short       range = [self getRng];
    short       amount = range/32;
    if(amount==0)amount = 10;
    /* get the current x range of the slider */
    short xMin = [self getMinVal];
    short xMax = [self getMaxVal];
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
        if(xMax > maxMax)xMax = maxDef;
    }
    else if(plotOp ==kShrinkPlot){
        if(abs(xMax-xMin)>10){
            xMax -= amount;
            xMin += amount;
        }
        
    }
    
    else return;
    
    [self setRngLow:xMin withHigh:xMax];
    [self endDrag]; //same as a drag so just call enddrag.
    
}

- (NSMutableDictionary*) attributes
{
	//this is a quick kludge to pass in groups of attributes. TDB ... move to a system where
	//the attributes are used directly.

	[attributes setObject:[NSNumber numberWithBool:logScale] forKey: ORScaleUseLog];
	[attributes setObject:[NSNumber numberWithDouble:minVal] forKey: ORScaleMinValue];
	[attributes setObject:[NSNumber numberWithDouble:maxVal] forKey: ORScaleMaxValue];

	return [NSMutableDictionary dictionaryWithDictionary:attributes];
}
 

- (void) setAttributes:(NSMutableDictionary*)newAttributes
{
	if(newAttributes!=attributes){
		[attributes release];
		attributes = [[NSMutableDictionary dictionaryWithDictionary:newAttributes] retain];
		//this is a quick kludge to pass in groups of attributes. TDB ... move to a system where
		//the attributes are used directly.
                [self setLog:[[attributes objectForKey:ORScaleUseLog] boolValue]];
                [self setRngLow:[[attributes objectForKey:ORScaleMinValue]doubleValue] withHigh:[[attributes objectForKey:ORScaleMaxValue]doubleValue]];
	}
}


@end


long roundPH(double x)
{
    return(x>0 ? (long)(x+0.5) : (long)(x-0.499999999999));
}


