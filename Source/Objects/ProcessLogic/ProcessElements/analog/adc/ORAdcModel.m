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

NSString* ORAdcModelOKConnection     = @"ORAdcModelOKConnection";
NSString* ORAdcModelLowConnection    = @"ORAdcModelLowConnection";
NSString* ORAdcModelHighConnection   = @"ORAdcModelHighConnection";

@implementation ORAdcModel

- (void) dealloc
{
	[lowLimitNub release];
	[highLimitNub release];
	[super dealloc];
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
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"adc"]];
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
			
			
			if(fabs(theConvertedValue-hwValue) >= .1 || theMaxValue!=maxValue || theMinValue!=minValue)updateNeeded = YES;
			hwValue = theConvertedValue;
			maxValue = theMaxValue;
			minValue = theMinValue;
			
			double theLowLimit,theHighLimit;
			[hwObject getAlarmRangeLow:&theLowLimit high:&theHighLimit channel:[self bit]];
			if(theLowLimit!=lowLimit || theHighLimit!=highLimit)updateNeeded = YES;

			lowLimit = theLowLimit;
			highLimit = theHighLimit;

			if(lowLimit>0) valueTooLow  = hwValue<lowLimit;
			else valueTooLow = NO;
			
			if(highLimit>0) valueTooHigh = hwValue>highLimit;
			else valueTooHigh = NO;

		}
		BOOL newState = !(valueTooLow || valueTooHigh);
		
		if((newState == [self state]) && updateNeeded){
			//if the state will not post an update, then do it where.
			[self postStateChange];
		}
		[self setState: newState];
		[self setEvaluatedState: newState];
	}
	return evaluatedState;
}
//--------------------------------

- (void) addOverLay
{
    if(!guardian) return;
    
    NSImage* aCachedImage = [self image];
    NSSize theIconSize = [aCachedImage size];
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    
    if(!hwObject && hwName){
        [[NSColor redColor] set];
        float oldWidth = [NSBezierPath defaultLineWidth];
        [NSBezierPath setDefaultLineWidth:3.];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0.,10.) toPoint:NSMakePoint(theIconSize.width-10.,theIconSize.height)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0.,theIconSize.height) toPoint:NSMakePoint(theIconSize.width-10.,10.)];
        [NSBezierPath setDefaultLineWidth:oldWidth];

    }
    if(hwObject){
        NSBezierPath* path = [NSBezierPath bezierPath];
        if(maxValue-minValue != 0){
            NSPoint theCenter = NSMakePoint((theIconSize.width-10.)/2.+1.,27.);
           if(lowLimit>minValue){
                float lowLimitAngle = 180*(lowLimit-minValue)/(maxValue-minValue);
				if(lowLimitAngle>=0 && lowLimitAngle<=180){
					[path appendBezierPathWithArcWithCenter:theCenter radius:30.
								startAngle:0 endAngle:lowLimitAngle];
					[path lineToPoint:theCenter];
					[path closePath];
					[[NSColor colorWithCalibratedRed:.75 green:0. blue:0. alpha:.3] set];
					[path fill];
					[path removeAllPoints];
				}
            }
            if(highLimit<maxValue){
				float highLimitAngle = 180*(highLimit-minValue)/(maxValue-minValue);
				if(highLimitAngle>=0 && highLimitAngle<=180){

					[path appendBezierPathWithArcWithCenter:theCenter radius:30.
                            startAngle:highLimitAngle endAngle:180.];
					[path lineToPoint:theCenter];
					[path closePath];
					[[NSColor colorWithCalibratedRed:.75 green:0. blue:0. alpha:.3] set];
					[path fill];
					[path removeAllPoints];
				}
            }
            
			NSBezierPath* needlepath = [NSBezierPath bezierPath];
			float needleAngle = 180*(hwValue-minValue)/(maxValue-minValue);
            [needlepath appendBezierPathWithArcWithCenter:theCenter radius:30.
                        startAngle:needleAngle endAngle:needleAngle];
            [needlepath lineToPoint:theCenter];
            [[NSColor redColor] set];
			[NSBezierPath setDefaultLineWidth:1];
            [needlepath stroke];
        }

    }
    
    NSString* label;
    NSFont* theFont;
    NSAttributedString* n;
    
    theFont = [NSFont messageFontOfSize:8];
    NSDictionary* attrib;

    if(hwName)	label = [NSString stringWithFormat:@"%.1f",[self hwValue]];
	else		label = @"--";
	n = [[NSAttributedString alloc] 
		initWithString:label 
			attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
	
	NSSize textSize = [n size];
	[n drawInRect:NSMakeRect((theIconSize.width-10)/2-textSize.width/2,15,textSize.width,textSize.height)];
	[n release];


    if(hwName){
        label = [NSString stringWithFormat:@"%@,%d",hwName,bit];
        attrib = [NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName];
    }
    else {
        label = @"XXXXXXXX";
        attrib = [NSDictionary dictionaryWithObjectsAndKeys:theFont,NSFontAttributeName,[NSColor redColor],NSForegroundColorAttributeName,nil];
        
    }
    n = [[NSAttributedString alloc] initWithString:label attributes:attrib];
    
    textSize = [n size];
    float x = theIconSize.width/2 - textSize.width/2;
    [n drawInRect:NSMakeRect(x,0,textSize.width,textSize.height)];
    [n release];

    if([self uniqueIdNumber]){
        theFont = [NSFont messageFontOfSize:9];
        n = [[NSAttributedString alloc] 
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

