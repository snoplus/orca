/* ORScale */

#import <Cocoa/Cocoa.h>

#define		kMaxLongTicks	100

long roundPH(double x);

/* Modifier flags special internal codes */
enum {
    XAXIS_FLAG			= 0x1000,
    YAXIS_FLAG			= 0x2000,
    SCALE_FLAG			= XAXIS_FLAG | YAXIS_FLAG
};

enum {
    LOG_SCALE			= 0x01,
    INTEGER_SCALE		= 0x02
};

@interface ORScale : NSView <NSCoding>
{
    IBOutlet NSView*		mView;
    NSFont*		mFont;
    NSColor*	mColor;
    NSMutableArray*		 gridArray;	// array for storing long tick locations
    NSMutableDictionary* labelAttributes;
    double		minPad,maxPad;		// scale value limits including padding
    double		minVal,maxVal;		// scale limits without padding
    double		minMin,maxMax;		// absolute maximum and minimum values
    double		minDef,maxDef;		// default minimum and maximum values
    double		minSav,maxSav;		// minimum and maximum scales of SaveRng()
    double		minRng;				// absolute minimum scale range
    double		valRng;				// maxPad - minPad
    double		fscl;				// scaling factor
    double		fpos;				// pixel offset to start of scale
    double		offset;				// log scale offset
    double		padding;			// padding outside regular scale limits
    double		pinVal;				// scale value at pin point
    double		pinPix;				// pixel position of pointpoint during grab
    short		lowOffset;				// pixel position of scale start
    short		highOffset;				// pixel position of scale end
    short		dpos;				// highOffset - lowOffset
    short		dlbl;				// optimal label separation (pixels)
    BOOL		xaxis;				// flag for x scale (1=x, 0=y)
    BOOL		logScale;			// flag for log scale
    BOOL		integer;			// flag for integer scale
    BOOL		pinned;				// flag for scale pinned
    BOOL		invertPin;			// flag to invert the sense of pinned flag
    BOOL		ignoreMouse;			// ignore mouse (disables scale changes)
    BOOL		allowShifts;			// flag to allow shifting of scale (as well as growing)
    short		lblWid, lblHigh;	// width and height of LONG_LBL label in pixels
    short		nearPinFlag;// -1/0/1 = below/at/above pin point for cursor
    BOOL		dragFlag;	// flag pressed if option is down during drag
    BOOL		saveRng;
    short 		mFlags;
    double      mGrabValue;
    BOOL		mDragInProgress;
	
	//tdb.. move to a full attribute system MAH
	NSMutableDictionary* attributes;
	
}
-(id) initWithFrame:(NSRect)aFrame;

-(void) dealloc;
-(void)	drawRect:(NSRect)rect;
-(void)	mouseDown:(NSEvent*)theEvent;
-(void)	mouseDragged:(NSEvent*)theEvent;
-(void)	mouseUp:(NSEvent*)theEvent;
//-(void)	ResizeFrame(Rect *delta);
//-(void)	SetTheCursor;
- (void)prepareAttributes;
-(id)	initWithCoder:(NSCoder*)coder;
-(void)	encodeWithCoder:(NSCoder*)coder;
-(void)	ignoreMouse:(BOOL) ignore;
-(void)	allowShifts:(BOOL) allow;
	/** Scale specific methods **/
-(short) checkRngLow:(double *)low withHigh:(double *)high;
-(short) setRngLow:(double)low withHigh:(double) high;
-(short) setDefaultRng;
-(short) setFullRng;
- (void) setTextFont:(NSFont*) font;
- (void) setColor:(NSColor*)aColor;
-(void)	 saveRng;
-(short) restoreRng;
-(short) setOrigin:(double) low;
-(short) shiftOrigin:(double) delta;
-(void)	setRngLimitsLow:(double)low withHigh:(double) high withMinRng:(double) min_rng;
-(void) setRngDefaultsLow:(double)aLow withHigh:(double)aHigh;
-(void)	setLog:(BOOL)isLog;
-(BOOL) isLog;
-(void)	setPadding:(double) p;
-(void)	setPin:(double) p;
-(void)	clearPin;
-(void)	setInteger:(BOOL) isInt;
-(short) getLblWid;
-(short)getLblHigh;
-(double)getMinVal;
-(double)getMaxVal;
-(double)getRng;
-(double)getPadding;
-(short)getPixAbs:(double) val;		// convert absolute value to pixel position
-(short)getPixRel:(double) val;		// convert relative value to pixel position
-(double)getValAbs:(short) pix;		// convert from pixel disp. to absolute value
-(double)getValRel:(short) pix;		// convert from pixel disp. to relative value
-(double)startDrag:(NSPoint) p;		// start drag procedure and return grab value
-(short)drag:(NSPoint)p withGrab:(double) val;	// drag scale
-(void)	endDrag;			// end drag procedure
-(void)	saveRngOnChange;		// save current range if next setRngLow() changes it
//@private
-(void) adjustToPinLow:(double *)low withHigh:(double *)high;
-(void)	setRngLow;			// set scale parameters from CPane object size
-(void)	calcSci;				// calculate scaling factors
-(void)	drawLogScale;			// draw a log scale
-(void)	drawLinScale;			// draw a linear scale
-(short)nearPinPoint:(NSPoint) where;	// is a point near the pin point?
-(NSArray*)gridArray;
-(void)setGridArray:(NSMutableArray*)anArray;
- (void) adjustSize;
- (double)convertPoint:(double)pix;
- (void) doPlotOp:(int)plotOp;


- (IBAction) setLogScale:(id)sender;
- (IBAction) shiftLeft:(id)sender;
- (IBAction) shiftRight:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;

- (NSMutableDictionary*) attributes;
- (void) setAttributes:(NSMutableDictionary*)newAttributes;


@end

extern NSString* ORScaleRangeChangedNotification;
extern NSString* ORScaleMinValue;
extern NSString* ORScaleMaxValue;
extern NSString* ORScaleUseLog;

