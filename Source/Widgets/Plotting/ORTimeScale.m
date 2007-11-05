//
//  ORTimeScale.m
//  Orca
//
//  Created by Mark Howe on Tue Sep 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ORTimeScale.h"


@implementation ORTimeScale

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
#define	YLDY				3			// y-label dy (center)
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

static char	symbols[]	= "fpnµm\0kMG";		// symbols for exponents


-(id) initWithFrame:(NSRect)aFrame
{
    self = [super initWithFrame:aFrame];
    return self;
}

- (unsigned long) secondsPerUnit
{
    return secondsPerUnit;
}
- (void) setSecondsPerUnit:(unsigned long)newSecondsPerUnit
{
    secondsPerUnit=newSecondsPerUnit;
}

- (void) drawLogScale
{
    [self setLog:NO];
    [self drawLinScale];
}

-(void)	drawLinScale
{
    
    short		i, x, y;			// general variables
    double		val;				// true value of scale units
    long		ival;				// integer mantissa of scale units
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
    NSSize 			axisNumberSize;
    NSString*		axisNumberString = @"";
    NSBezierPath* 	theAxis = [NSBezierPath bezierPath];
    NSBezierPath* 	theAxisColoredTicks = [NSBezierPath bezierPath];
    [theAxisColoredTicks setLineWidth:3];
    
    secondsPerUnit = [mView secondsPerUnit:mView];
    
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
            if (suffix) {			// avoid extra trailing zeros if suffix
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
    } else i = ticks;					// first tick is at label
    
    lim  = valRng + tol;				// upper limit for scale value
    
    if (xaxis) {
        unsigned short nthTick = 0;
        
        y = [self frame].size.height;
        [theAxis moveToPoint:NSMakePoint(lowOffset-2,y)];						// draw axis line
        [theAxis lineToPoint:NSMakePoint(highOffset+1,y)];
        --y;
        for (;;) {
            x = lowOffset + [self getPixRel:val];				// get pixel position
            [theAxis moveToPoint:NSMakePoint(x,y)];
            if (i < ticks) {
                if (ticks==4 && i==2) {
                    [theAxis lineToPoint:NSMakePoint(x,y-MED_TICK)];			// draw medium tick
                    } else {
                    [theAxis lineToPoint:NSMakePoint(x,y-SHORT_TICK)];			// draw short tick
                }
                ++i;
                } else {
                if ((nthTick % 4) == 0) {
                    [theAxisColoredTicks moveToPoint:NSMakePoint(x,y)];
                    [theAxisColoredTicks lineToPoint:NSMakePoint(x,y-LONG_TICK)];			// draw long tick
                    
                    } else {
                    [theAxis lineToPoint:NSMakePoint(x,y-LONG_TICK)];			// draw long tick
                }
                if ([gridArray count]<kMaxLongTicks) {
                    [gridArray addObject: [NSNumber numberWithLong:x-lowOffset]];
                }
                if (!ival) {
                    axisNumberString = [NSString stringWithString:@"Now"];
                }
                else if ((nthTick % 4) == 0) {
                    NSCalendarDate *aDate = [[NSCalendarDate date] dateByAddingYears:0 months:0 days:0 hours:0 minutes:0 seconds:-(ival*secondsPerUnit)];
                    axisNumberString = [aDate descriptionWithCalendarFormat:@"%m/%d %H:%M:%S"];
                    nthTick = 0;
                }
                
                axisNumberSize = [axisNumberString sizeWithAttributes:labelAttributes];
                
                if ((nthTick % 4) == 0) {
                    [axisNumberString drawAtPoint:NSMakePoint(x+YLDX+3 - axisNumberSize.width/2,y-YLDY-axisNumberSize.height) withAttributes:labelAttributes];
                }
                
                nthTick++;
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
        
        } else {
        // Do nothing, should not be Y axis.
    }
    [mColor set];
    [theAxis setLineWidth:1];
    [theAxis stroke];
    [[NSColor blueColor] set];
    [theAxisColoredTicks stroke];
}


@end
