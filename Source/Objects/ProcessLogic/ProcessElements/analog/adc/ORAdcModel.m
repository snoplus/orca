//
//  ORAdcModel.m
//  Orca
//
//  Created by Mark Howe on 11/25/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORAdcModel.h"
#import "ORProcessOutConnector.h"
#import "ORProcessModel.h"
#import "ORProcessThread.h"
#import "ORAdcProcessing.h"
#import "CTGradient.h"

NSString* ORAdcModelViewIconTypeChanged = @"ORAdcModelViewIconTypeChanged";
NSString* ORAdcModelLabelTypeChanged = @"ORAdcModelLabelTypeChanged";
NSString* ORAdcModelCustomLabelChanged = @"ORAdcModelCustomLabelChanged";
NSString* ORAdcModelDisplayFormatChanged = @"ORAdcModelDisplayFormatChanged";
NSString* ORAdcModelMinChangeChanged = @"ORAdcModelMinChangeChanged";
NSString* ORAdcModelOKConnection     = @"ORAdcModelOKConnection";
NSString* ORAdcModelLowConnection    = @"ORAdcModelLowConnection";
NSString* ORAdcModelHighConnection   = @"ORAdcModelHighConnection";

@interface ORAdcModel (private)
- (void) addMeterOverlay:(NSImage*)anImage;
- (void) addAltMeterOverlay:(NSImage*)anImage;
- (void) addHorizontalBarOverlay:(NSImage*)anImage;
- (void) addMeterText:(NSImage*)anImage;
- (void) addAltMeterText:(NSImage*)anImage;
- (void) addAltHorizontalBarText:(NSImage*)anImage;
- (void) addAltValueOverlay:(NSImage*)anImage;
- (void) addAltValueText:(NSImage*)anImage;
@end

@implementation ORAdcModel

- (void) dealloc
{
    [customLabel release];
    [displayFormat release];
	[lowLimitNub release];
	[highLimitNub release];
	[normalGradient release];
	[alarmGradient release];
	[super dealloc];
}

#pragma mark ***Accessors
- (int) viewIconType
{
    return viewIconType;
}

- (void) setViewIconType:(int)aViewIconType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setViewIconType:viewIconType];
    viewIconType = aViewIconType;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAdcModelViewIconTypeChanged object:self];	
    [[NSNotificationCenter defaultCenter] postNotificationName:OROrcaObjectImageChanged object:self];	

}

- (int) labelType
{
    return labelType;
}

- (void) setLabelType:(int)aLabelType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLabelType:labelType];
    labelType = aLabelType;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAdcModelLabelTypeChanged object:self];
}

- (NSString*) customLabel
{
	if(!customLabel)return @"";
    return customLabel;
}

- (void) setCustomLabel:(NSString*)aCustomLabel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCustomLabel:customLabel];
    
    [customLabel autorelease];
    customLabel = [aCustomLabel copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAdcModelCustomLabelChanged object:self];
}

- (NSString*) displayFormat
{
	if(!displayFormat)return @"";
    return displayFormat;
}

- (void) setDisplayFormat:(NSString*)aDisplayFormat
{
	if(![aDisplayFormat length])aDisplayFormat = @"%.1f";
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayFormat:displayFormat];

	[displayFormat autorelease];
	displayFormat = [aDisplayFormat copy];    

	[[NSNotificationCenter defaultCenter] postNotificationName:ORAdcModelDisplayFormatChanged object:self];
}

- (float) minChange
{
    return minChange;
}

- (void) setMinChange:(float)aMinChange
{
	if(aMinChange<0)aMinChange=0;
    [[[self undoManager] prepareWithInvocationTarget:self] setMinChange:minChange];
    minChange = aMinChange;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAdcModelMinChangeChanged object:self];
}

-(void)makeConnectors
{  
    ORProcessOutConnector* aConnector;      
    aConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height-kConnectorSize) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORAdcModelHighConnection];
    [ aConnector setConnectorType: 'LP2 ' ];
    [ aConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [aConnector release];

    aConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height/2 - kConnectorSize/2+5) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORAdcModelOKConnection];
    [ aConnector setConnectorType: 'LP2 ' ];
    [ aConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [aConnector release];

    aConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,10) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORAdcModelLowConnection];
    [ aConnector setConnectorType: 'LP2 ' ];
    [ aConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [aConnector release];
}

- (void) setUpNubs
{
	ORConnector* aConnector;
    if(!lowLimitNub)lowLimitNub = [[ORAdcLowLimitNub alloc] init];
    [lowLimitNub setGuardian:self];
    aConnector = [[self connectors] objectForKey: ORAdcModelLowConnection];
    [aConnector setObjectLink:lowLimitNub];


    if(!highLimitNub)highLimitNub = [[ORAdcHighLimitNub alloc] init];
    [highLimitNub setGuardian:self];
    aConnector = [[self connectors] objectForKey: ORAdcModelHighConnection];
    [aConnector setObjectLink:highLimitNub];
}

- (NSString*) elementName
{
	return @"ADC";
}

- (NSArray*) validObjects
{
    return [[self document] collectObjectsConformingTo:@protocol(ORAdcProcessing)];
}

- (void) makeMainController
{
    [self linkToController:@"ORAdcController"];
}

- (BOOL) canBeInAltView
{
	return YES;
}

- (BOOL) acceptsClickAtPoint:(NSPoint)aPoint
{
	if(![super useAltView]) return [super acceptsClickAtPoint:aPoint];
	else {
		NSRect f = [self frame];
		if(viewIconType == 0)		return NSPointInRect(aPoint,f);
		else if(viewIconType == 1)	return NSPointInRect(aPoint,NSMakeRect(f.origin.x + 152,f.origin.y,f.size.width - 152,f.size.height));
		else if(viewIconType == 2)	return NSPointInRect(aPoint,NSMakeRect(f.origin.x + 157,f.origin.y,f.size.width - 157,f.size.height));
		else						return NSPointInRect(aPoint,f);
	}
}

- (BOOL) intersectsRect:(NSRect) aRect
{
	if(![super useAltView]) return [super intersectsRect:aRect];
	else {
		NSRect f = [self frame];
		if(viewIconType == 0)		return NSIntersectsRect(aRect,f);
		else if(viewIconType == 1)	return NSIntersectsRect(aRect,NSMakeRect(f.origin.x + 152,f.origin.y,f.size.width - 152,f.size.height));
		else if(viewIconType == 2)	return NSIntersectsRect(aRect,NSMakeRect(f.origin.x + 157,f.origin.y,f.size.width - 157,f.size.height));
		else						return NSIntersectsRect(aRect,f);
	}
}

- (NSImage*) altImage
{
	if(viewIconType == 0)return [NSImage imageNamed:@"adcMeter"];
	else if(viewIconType == 1)return [NSImage imageNamed:@"adcText"];
	else if(viewIconType == 2)return [NSImage imageNamed:@"adcHorizontalBar"];
	else return [NSImage imageNamed:@"adcMeter"];
}

- (void) setUpImage
{
	if([self useAltView]){
		[self setImage:[self altImage]];
	}
	else {
		[self setImage:[NSImage imageNamed:@"adc"]];
	}
    [self addOverLay];
}

- (BOOL) valueTooLow
{
	return valueTooLow;
}

- (BOOL) valueTooHigh
{
	return valueTooHigh;
}

- (double) lowLimit
{
	return lowLimit;
}

- (double) highLimit
{
	return highLimit;
}

- (double) hwValue
{
	return hwValue;
}

- (double) maxValue
{
	return maxValue;
}
- (double) minValue
{
	return minValue;
}

- (void) processIsStarting
{
    [super processIsStarting];
    [ORProcessThread registerInputObject:self];
}

- (void) viewSource
{
	[[self hwObject] showMainInterface];
}

//--------------------------------
//runs in the process logic thread
- (int) eval
{
	if(!alreadyEvaluated){
		alreadyEvaluated = YES;
		BOOL updateNeeded = NO;
		if(![guardian inTestMode] && hwObject!=nil){
			double theConvertedValue  = [hwObject convertedValue:[self bit]]; //reads the hw
			double theMaxValue		  = [hwObject maxValueForChan:[self bit]];
			double theMinValue		  = [hwObject minValueForChan:[self bit]];
		
			if(fabs(theConvertedValue-hwValue) >= minChange || theMaxValue!=maxValue || theMinValue!=minValue)updateNeeded = YES;
			hwValue = theConvertedValue;
			maxValue = theMaxValue;
			minValue = theMinValue;
			
			double theLowLimit,theHighLimit;
			[hwObject getAlarmRangeLow:&theLowLimit high:&theHighLimit channel:[self bit]];
			if(theLowLimit!=lowLimit || theHighLimit!=highLimit)updateNeeded = YES;

			lowLimit = theLowLimit;
			highLimit = theHighLimit;

			valueTooLow  = hwValue<lowLimit;
			valueTooHigh = hwValue>highLimit;

		}
		BOOL newState = !(valueTooLow || valueTooHigh);
		
		if((newState == [self state]) && updateNeeded){
			//if the state will not post an update, then do it here.
			[self postStateChange];
		}
		[self setState: newState];
		[self setEvaluatedState: newState];
	}
	return evaluatedState;
}

- (float) evalAndReturnAnalogValue
{
	[self eval];
	return hwValue;
}

//--------------------------------
- (NSString*) iconValue 
{ 
    if(hwName)	{
		NSString* theFormat = @"%.1f";
		if([displayFormat length] != 0)									theFormat = displayFormat;
		if([theFormat rangeOfString:@"%@"].location !=NSNotFound)		theFormat = @"%.1f";
		else if([theFormat rangeOfString:@"%d"].location !=NSNotFound)	theFormat = @"%.0f";
		return [NSString stringWithFormat:theFormat,[self hwValue]];
	}
	else return @"";
}

- (NSString*) iconLabel
{
	if(![self useAltView]){
		if(hwName)	return [NSString stringWithFormat:@"%@,%d",hwName,bit];
		else		return @""; 
	}
	else {
		if(labelType == 1)return @"";
		else if(labelType ==2)return [self customLabel];
		else {
			if(hwName)	return [NSString stringWithFormat:@"%@,%d",hwName,bit];
			else		return @""; 
		}
	}
}

- (void) addOverLay
{
    if(!guardian) return;
    
    NSImage* aCachedImage;
	if(![self useAltView])	aCachedImage = [self image];
	else					aCachedImage = [self altImage];		
	
	if(!aCachedImage || [aCachedImage size].width<1 || [aCachedImage size].height<1)return;
	
    NSSize theIconSize = [aCachedImage size];
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    
    if(!hwObject && hwName && ![self useAltView]){
        [[NSColor redColor] set];
        float oldWidth = [NSBezierPath defaultLineWidth];
        [NSBezierPath setDefaultLineWidth:3.];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0.,10) toPoint:NSMakePoint(theIconSize.width-10,theIconSize.height)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0.,theIconSize.height) toPoint:NSMakePoint(theIconSize.width-10,10)];
        [NSBezierPath setDefaultLineWidth:oldWidth];

    }
    if(hwObject){
		if(![self useAltView])[self addMeterOverlay:aCachedImage];
		else {
			if(viewIconType == 0)		[self addAltMeterOverlay:aCachedImage];
			else if(viewIconType == 1)	[self addAltValueOverlay:aCachedImage];
			else if(viewIconType == 2 )	[self addHorizontalBarOverlay:aCachedImage];
		}
	}

    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setViewIconType:	[decoder decodeIntForKey:@"viewIconType"]];
    [self setLabelType:		[decoder decodeIntForKey:@"labelType"]];
    [self setCustomLabel:	[decoder decodeObjectForKey:@"customLabel"]];
    [self setDisplayFormat:	[decoder decodeObjectForKey:@"displayFormat"]];
    [self setMinChange:		[decoder decodeFloatForKey:@"minChange"]];
    [[self undoManager] enableUndoRegistration];    

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:viewIconType		forKey:@"viewIconType"];
    [encoder encodeInt:labelType		forKey:@"labelType"];
    [encoder encodeObject:customLabel	forKey:@"customLabel"];
    [encoder encodeObject:displayFormat forKey:@"displayFormat"];
    [encoder encodeFloat: minChange		forKey:@"minChange"];
}
@end

@implementation ORAdcModel (private)
- (void) addMeterOverlay:(NSImage*)anImage
{
	//assumes that the focus is locked on a view.
    NSSize theIconSize = [anImage size];
	if(minValue-maxValue != 0){
		NSPoint theCenter = NSMakePoint((theIconSize.width-10)/2.+1,27);
		if(lowLimit>minValue){
			NSBezierPath* path = [NSBezierPath bezierPath];
			float lowLimitAngle = 180*(lowLimit-minValue)/(maxValue-minValue);
			lowLimitAngle =  180-lowLimitAngle;
			if(lowLimitAngle>=0 && lowLimitAngle<=180){
				[path appendBezierPathWithArcWithCenter:theCenter radius:30
											 startAngle:lowLimitAngle endAngle:180];
				[path lineToPoint:theCenter];
				[path closePath];
				[[NSColor colorWithCalibratedRed:.7 green:.4 blue:.4 alpha:.2] set];
				[path fill];
			}
		}
		
		if(highLimit<maxValue){
			float highLimitAngle = 180*(highLimit-minValue)/(maxValue-minValue);
			highLimitAngle = 180-highLimitAngle;
			if(highLimitAngle>=0 && highLimitAngle<=180){
				NSBezierPath* path = [NSBezierPath bezierPath];
				[path appendBezierPathWithArcWithCenter:theCenter radius:30
											 startAngle:0 endAngle:highLimitAngle];
				[path lineToPoint:theCenter];
				[path closePath];
				[[NSColor colorWithCalibratedRed:.7 green:0.4 blue:.4 alpha:.2] set];
				[path fill];
			}
		}
		
		float slope = (180 - 0)/(minValue-maxValue);
		float intercept = 180 - slope*minValue;
		float needleAngle = slope*hwValue + intercept;
		if(needleAngle<0)needleAngle=0;
		if(needleAngle>180)needleAngle=180;
		
		float nA = .0174553*needleAngle;
		[NSBezierPath setDefaultLineWidth:0];
		[[NSColor blackColor] set];
		[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(theCenter.x-2*1,theCenter.y-2*1,4,4)];
		[[NSColor redColor] set];
		[NSBezierPath strokeLineFromPoint:theCenter toPoint:NSMakePoint(theCenter.x + 30.*cosf(nA),theCenter.y + 30.*sinf(nA))];
	}
	[self addMeterText:anImage];
}

- (void) addMeterText:(NSImage*)anImage
{
    NSSize theIconSize = [anImage size];
	NSColor* textColor=[NSColor blackColor];
	NSString* iconValue = [self iconValue];
	if([iconValue length]){		
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:iconValue
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											 [NSFont messageFontOfSize:10],NSFontAttributeName,
											 textColor,NSForegroundColorAttributeName,nil]];
		
		NSSize textSize = [n size];
		float x = theIconSize.width/2 - textSize.width/2- 4;
		float y = 12;
		[n drawInRect:NSMakeRect(x,y,textSize.width,textSize.height)];
	}
	
	NSString* iconLabel = [self iconLabel];
	if([iconLabel length]){
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:iconLabel
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											 [NSFont messageFontOfSize:9],NSFontAttributeName,
											 textColor,NSForegroundColorAttributeName,nil]];
		
		NSSize textSize = [n size];
		float x = theIconSize.width/2 - textSize.width/2;
		float y = 0;
		[n drawInRect:NSMakeRect(x,y,textSize.width,textSize.height)];
	}
	
	if([self uniqueIdNumber]){
		NSFont* theFont = [NSFont messageFontOfSize:9];
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:[NSString stringWithFormat:@"%d",[self uniqueIdNumber]] 
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,textColor,NSForegroundColorAttributeName,nil]];
		
		NSSize textSize = [n size];
		[n drawInRect:NSMakeRect(5,theIconSize.height-textSize.height-2,textSize.width,textSize.height)];
		[n release];
	}
}

- (void) addAltMeterOverlay:(NSImage*)anImage
{
	//assumes that the focus is locked on the view icon.
    NSSize theIconSize = [anImage size];
	if(minValue-maxValue != 0){
		NSPoint theCenter = NSMakePoint((theIconSize.width)/2.,45.);
		if(lowLimit>minValue){
			NSBezierPath* path = [NSBezierPath bezierPath];
			float lowLimitAngle = 195.*(lowLimit-minValue)/(maxValue-minValue);
			lowLimitAngle =  195.-lowLimitAngle;
			if(lowLimitAngle>=-15. && lowLimitAngle<=195.){
				[path appendBezierPathWithArcWithCenter:theCenter radius:60.
											 startAngle:lowLimitAngle endAngle:195.];
				[path lineToPoint:theCenter];
				[path closePath];
				[[NSColor colorWithCalibratedRed:.7 green:.4 blue:.4 alpha:.5] set];
				[path fill];
			}
		}
		
		if(highLimit<maxValue){
			float highLimitAngle = 195.*(highLimit-minValue)/(maxValue-minValue);
			highLimitAngle = 195.-highLimitAngle;
			if(highLimitAngle>=-15. && highLimitAngle<=195.){
				NSBezierPath* path = [NSBezierPath bezierPath];
				[path appendBezierPathWithArcWithCenter:theCenter radius:60.
											 startAngle:-15. endAngle:highLimitAngle];
				[path lineToPoint:theCenter];
				[path closePath];
				[[NSColor colorWithCalibratedRed:.7 green:0.4 blue:.4 alpha:.5] set];
				[path fill];
			}
		}
		
		float slope = (195. + 15.)/(minValue-maxValue);
		float intercept = 195. - slope*minValue;
		float needleAngle = slope*hwValue + intercept;
		if(needleAngle<-15.)needleAngle=-15.;
		if(needleAngle>195.)needleAngle=195.;
		
		float nA = .0174553*needleAngle;
		[NSBezierPath setDefaultLineWidth:3];
		[[NSColor blackColor] set];
		[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(theCenter.x,theCenter.y,4,4)];
		[[NSColor redColor] set];
		[NSBezierPath strokeLineFromPoint:theCenter toPoint:NSMakePoint(theCenter.x + 60.*cosf(nA),theCenter.y + 60.*sinf(nA))];
	}
	[self addAltMeterText:anImage];
}

- (void) addAltMeterText:(NSImage*)anImage
{
	NSColor* textColor=[NSColor whiteColor];
    NSSize theIconSize = [anImage size];	
	NSString* iconValue = [self iconValue];
	if([iconValue length]){
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:iconValue
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											 [NSFont messageFontOfSize:14],NSFontAttributeName,
											 textColor,NSForegroundColorAttributeName,nil]];
		
		NSSize textSize = [n size];
		float x = theIconSize.width/2 - textSize.width/2- 4;
		float y = 15;
		[n drawInRect:NSMakeRect(x,y,textSize.width,textSize.height)];
	}
	
	NSString* iconLabel = [self iconLabel];
	if([iconLabel length]){
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:iconLabel
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											 [NSFont messageFontOfSize:9],NSFontAttributeName,
											 textColor,NSForegroundColorAttributeName,nil]];
		
		NSSize textSize = [n size];
		float x = theIconSize.width/2 - textSize.width/2;
		float y = 3;
		[n drawInRect:NSMakeRect(x,y,textSize.width,textSize.height)];
	}
	
	if([self uniqueIdNumber]){
		NSFont* theFont = [NSFont messageFontOfSize:9];
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:[NSString stringWithFormat:@"%d",[self uniqueIdNumber]] 
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,textColor,NSForegroundColorAttributeName,nil]];
		
		NSSize textSize = [n size];
		[n drawInRect:NSMakeRect(5,theIconSize.height-textSize.height-2,textSize.width,textSize.height)];
		[n release];
	}
}

- (void) addAltValueOverlay:(NSImage*)anImage
{
	[self addAltValueText:anImage];	
}

- (void) addAltValueText:(NSImage*)anImage
{
	float startx = 152;
    NSSize theIconSize = [anImage size];	
	NSString* iconValue = [self iconValue];
	if([iconValue length]){
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:iconValue
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											 [NSFont messageFontOfSize:20],NSFontAttributeName,
											 [NSColor whiteColor],NSForegroundColorAttributeName,nil]];
		
		NSSize textSize = [n size];
		float x = startx + 30;
		float y = 4;
		[n drawInRect:NSMakeRect(x,y,textSize.width,textSize.height)];
	}
	
	NSString* iconLabel = [self iconLabel];
	if([iconLabel length]){
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:iconLabel
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											 [NSFont messageFontOfSize:9],NSFontAttributeName,
											 [NSColor blackColor],NSForegroundColorAttributeName,nil]];
		
		NSSize textSize = [n size];
		float x = startx - textSize.width-4;
		float y = 3;
		[n drawInRect:NSMakeRect(x,y,textSize.width,textSize.height)];
	}
	
	if([self uniqueIdNumber]){
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:[NSString stringWithFormat:@"%d",[self uniqueIdNumber]] 
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											 [NSFont messageFontOfSize:9],NSFontAttributeName,
											 [NSColor whiteColor],NSForegroundColorAttributeName,nil]];
		
		NSSize textSize = [n size];
		[n drawInRect:NSMakeRect(startx+7,theIconSize.height-textSize.height-4,textSize.width,textSize.height)];
		[n release];
	}
}



- (void) addHorizontalBarOverlay:(NSImage*)anImage
{
	if(!normalGradient){
		float red   = 0.0; 
		float green = 1.0; 
		float blue  = 0.0;
	
		normalGradient = [[CTGradient 
						   gradientWithBeginningColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1]
						   endingColor:[NSColor colorWithCalibratedRed:.5*red green:.5*green blue:.5*blue alpha:1]] retain];
	}
	
	if(!alarmGradient){
		float red   = 1.0; 
		float green = 0.0; 
		float blue  = 0.0;
		
		alarmGradient = [[CTGradient 
						   gradientWithBeginningColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:.3]
						   endingColor:[NSColor colorWithCalibratedRed:.5*red green:.5*green blue:.5*blue alpha:.3]] retain];
	}
	
	float w = 231;
	float startx = 157;
	if(maxValue-minValue != 0){
	
		float slope = w/(maxValue-minValue);
		float intercept = w-slope*maxValue;
		float xValue = slope*hwValue + intercept;
		if(xValue<0)xValue=0;
		if(xValue>w)xValue=w;
		[normalGradient fillRect:NSMakeRect(startx,4,xValue,24) angle:270];
		
		if(lowLimit>minValue){
			float lowAlarmx = slope*lowLimit + intercept;
			[alarmGradient fillRect:NSMakeRect(startx,4,lowAlarmx,24) angle:270];
		}
		
		if(highLimit<maxValue){
			float hiAlarmx = slope*highLimit + intercept;
			[alarmGradient fillRect:NSMakeRect(startx+hiAlarmx,4,w-hiAlarmx,24) angle:270];
		}
		
		[[NSColor redColor] set];
		float x1 = MIN(startx + xValue,startx+w-3);
		[NSBezierPath fillRect:NSMakeRect(x1,4,3,24)];
		
	}
	[self addAltHorizontalBarText:anImage];

}
- (void) addAltHorizontalBarText:(NSImage*)anImage
{
	float startx = 152;
	NSColor* textColor=[NSColor blackColor];
    NSSize theIconSize = [anImage size];	
	NSString* iconValue = [self iconValue];
	if([iconValue length]){
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:iconValue
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											 [NSFont messageFontOfSize:14],NSFontAttributeName,
											 textColor,NSForegroundColorAttributeName,nil]];
		
		NSSize textSize = [n size];
		float x = startx - textSize.width- 4;
		float y = 15;
		[n drawInRect:NSMakeRect(x,y,textSize.width,textSize.height)];
	}
	
	NSString* iconLabel = [self iconLabel];
	if([iconLabel length]){
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:iconLabel
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											 [NSFont messageFontOfSize:9],NSFontAttributeName,
											 textColor,NSForegroundColorAttributeName,nil]];
		
		NSSize textSize = [n size];
		float x = startx - textSize.width-4;
		float y = 3;
		[n drawInRect:NSMakeRect(x,y,textSize.width,textSize.height)];
	}
	
	if([self uniqueIdNumber]){
		NSFont* theFont = [NSFont messageFontOfSize:9];
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:[NSString stringWithFormat:@"%d",[self uniqueIdNumber]] 
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor whiteColor],NSForegroundColorAttributeName,nil]];
		
		NSSize textSize = [n size];
		[n drawInRect:NSMakeRect(startx+7,theIconSize.height-textSize.height-4,textSize.width,textSize.height)];
		[n release];
	}
}

@end

//the 'Low' nub
@implementation ORAdcLowLimitNub
- (int) eval
{
	[guardian eval];
	return [guardian valueTooLow];
}

- (int) evaluatedState
{
	return [guardian valueTooLow];
}

@end

//the 'High' nub
@implementation ORAdcHighLimitNub
- (int) eval
{
	[guardian eval];
	return [guardian valueTooHigh];
}
- (int) evaluatedState
{
	return [guardian valueTooHigh];
}

@end

