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

NSString* ORAdcModelDisplayFormatChanged = @"ORAdcModelDisplayFormatChanged";
NSString* ORAdcModelMinChangeChanged = @"ORAdcModelMinChangeChanged";
NSString* ORAdcModelOKConnection     = @"ORAdcModelOKConnection";
NSString* ORAdcModelLowConnection    = @"ORAdcModelLowConnection";
NSString* ORAdcModelHighConnection   = @"ORAdcModelHighConnection";

@implementation ORAdcModel

- (void) dealloc
{
    [displayFormat release];
	[lowLimitNub release];
	[highLimitNub release];
	[super dealloc];
}

#pragma mark ***Accessors

- (NSString*) displayFormat
{
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

- (NSImage*) altImage
{
	NSImage* anImage = [[NSImage alloc] initWithSize:NSMakeSize(100,75)];
	[anImage lockFocus];
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:NSMakeRect(0,25,100,75)];
	NSPoint theCenter = NSMakePoint(50,25);
	NSBezierPath* path = [NSBezierPath bezierPath];
	[path appendBezierPathWithArcWithCenter:theCenter radius:49.
		startAngle:0
		endAngle:180
		clockwise:NO];
	[path closePath];
	[[NSColor colorWithCalibratedWhite:.95 alpha:.9] set];
	[path fill];
	[[NSColor colorWithCalibratedWhite:.7 alpha:.9] set];
	[path stroke];
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:NSMakeRect(0,25,100,50)];
	[anImage unlockFocus];
	return [anImage autorelease];
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
    if(hwName)	return [NSString stringWithFormat:@"%@,%d",hwName,bit];
    else		return @"";        
}

- (void) addOverLay
{
	
	float kRadius;
	float kConnectorOffset;
	float kPad;
	float kYStart;
    if(!guardian) return;
    
    NSImage* aCachedImage;
	if(![self useAltView]){
		kRadius = 30.;
		kYStart = 27.;
		kPad = 1;
		kConnectorOffset = 10.;
		aCachedImage = [self image];
	}
	else {
		aCachedImage = [self altImage];
		kRadius = 50.;
		kYStart = 25.;
		kPad = 0;
		kConnectorOffset = 0.;
	}
	if(!aCachedImage)return;
	
    NSSize theIconSize = [aCachedImage size];
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    
    if(!hwObject && hwName){
        [[NSColor redColor] set];
        float oldWidth = [NSBezierPath defaultLineWidth];
        [NSBezierPath setDefaultLineWidth:3.];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0.,kConnectorOffset) toPoint:NSMakePoint(theIconSize.width-kConnectorOffset,theIconSize.height)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0.,theIconSize.height) toPoint:NSMakePoint(theIconSize.width-kConnectorOffset,kConnectorOffset)];
        [NSBezierPath setDefaultLineWidth:oldWidth];

    }
    if(hwObject){
        if(maxValue-minValue != 0){
			NSPoint theCenter = NSMakePoint((theIconSize.width-kConnectorOffset)/2.+kPad,kYStart);
			if(lowLimit>minValue){
				NSBezierPath* path = [NSBezierPath bezierPath];
                float lowLimitAngle = 180*(lowLimit-minValue)/(maxValue-minValue);
				lowLimitAngle =  180-lowLimitAngle;
				if(lowLimitAngle>=0 && lowLimitAngle<=180){
					[path appendBezierPathWithArcWithCenter:theCenter radius:kRadius
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
					[path appendBezierPathWithArcWithCenter:theCenter radius:kRadius
                            startAngle:0 endAngle:highLimitAngle];
					[path lineToPoint:theCenter];
					[path closePath];
					[[NSColor colorWithCalibratedRed:.7 green:0.4 blue:.4 alpha:.2] set];
					[path fill];
				}
            }
			
			float needleAngle = 180*(hwValue-minValue)/(maxValue-minValue);
			needleAngle = 180 - needleAngle;
			
			if(needleAngle<0)needleAngle=0;
			if(needleAngle>180)needleAngle=180;
			
			float nA = .0174553*needleAngle;
			[NSBezierPath setDefaultLineWidth:0];
 			[[NSColor blackColor] set];
			[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(theCenter.x-2*kPad,theCenter.y-2*kPad,4,4)];
 			[[NSColor redColor] set];
			[NSBezierPath strokeLineFromPoint:theCenter toPoint:NSMakePoint(theCenter.x + kRadius*cosf(nA),theCenter.y + kRadius*sinf(nA))];
        }
    }
	
 	NSString* iconValue = [self iconValue];
	if([iconValue length]){
        NSFont* theFont = [NSFont messageFontOfSize:10];
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:iconValue
								 attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
		
		NSSize textSize = [n size];
		float x = theIconSize.width/2 - textSize.width/2- 4;
		[[NSColor blackColor] set];
		[n drawInRect:NSMakeRect(x,12,textSize.width,textSize.height)];
	}
	
	NSString* iconLabel = [self iconLabel];
	if([iconLabel length]){
        NSFont* theFont = [NSFont messageFontOfSize:9];
		NSAttributedString* n = [[NSAttributedString alloc] 
								 initWithString:iconLabel
								 attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
		
		NSSize textSize = [n size];
		float x = theIconSize.width/2 - textSize.width/2;
		[[NSColor blackColor] set];
		[n drawInRect:NSMakeRect(x,0,textSize.width,textSize.height)];
	}
	
    if([self uniqueIdNumber]){
        NSFont* theFont = [NSFont messageFontOfSize:9];
        NSAttributedString* n = [[NSAttributedString alloc] 
            initWithString:[NSString stringWithFormat:@"%d",[self uniqueIdNumber]] 
                attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
        
        NSSize textSize = [n size];
        [n drawInRect:NSMakeRect(5,theIconSize.height-textSize.height,textSize.width,textSize.height)];
        [n release];
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
    [self setDisplayFormat:	[decoder decodeObjectForKey:@"displayFormat"]];
    [self setMinChange:		[decoder decodeFloatForKey:@"minChange"]];
    [[self undoManager] enableUndoRegistration];    

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:displayFormat forKey:@"displayFormat"];
    [encoder encodeFloat: minChange		forKey:@"minChange"];
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

