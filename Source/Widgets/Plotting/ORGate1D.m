//
//  ORGate1D.m
//  testplot
//
//  Created by Mark Howe on Fri May 14 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORGate1D.h"
#import "ORPlotter1D.h"
#import "ORAxis.h"
#import "ORCurve1D.h"
#import "ORAnalysisPanel1D.h"
#import "ORGate.h"
#import "ORGateKey.h"
#import "ORGateGroup.h"
#import "ORCalibration.h"
#import "ORCARootServiceDefs.h"
#import "NSDictionary+Extensions.h"


NSString* ORGate1DValid	    = @"ORGate1DValid";
NSString* ORGate1DMin	    = @"ORGate1DMin";
NSString* ORGate1DMax	    = @"ORGate1DMax";

NSString* ORGateValidChangedNotification            = @"ORGateValidChangedNotification";
NSString* ORGateMinChangedNotification              = @"ORGateMinChangedNotification";
NSString* ORGateMaxChangedNotification              = @"ORGateMaxChangedNotification";
NSString* ORGateAverageChangedNotification          = @"ORGateAverageChangedNotification";
NSString* ORGateCentroidChangedNotification         = @"ORGateCentroidChangedNotification";
NSString* ORGateSigmaChangedNotification            = @"ORGateSigmaChangedNotification";
NSString* ORGateTotalSumChangedNotification         = @"ORGateTotalSumChangedNotification";
NSString* ORGateCurveNumberChangedNotification      = @"ORGateCurveNumberChangedNotification";
NSString* ORGateNumberChangedNotification           = @"ORGateNumberChangedNotification";
NSString* ORGateDisplayGateChangedNotification      = @"ORGateDisplayGateChangedNotification";
NSString* ORGateDisplayedGateChangedNotification    = @"ORGateDisplayedGateChangedNotification";
NSString* ORForcePlotUpdateNotification             = @"ORForcePlotUpdateNotification";
NSString* ORGatePeakXChangedNotification            = @"ORGatePeakXChangedNotification";
NSString* ORGatePeakYChangedNotification            = @"ORGatePeakYChangedNotification";
NSString* ORGateFitChanged							= @"ORGateFitChanged";

const float kGateAlpha = .2;
const float kGateAlpha2 = .1;

@interface ORGate1D (private)
- (void) registerForGateChanges;
@end

@implementation ORGate1D
+ (void) initialize
{
    if(self == [ORGate1D class]){
        [self setVersion:2];
    }
}

+ (id) gateForCurve:(ORCurve1D*)aCurve plot:(ORPlotter1D*)aPlot
{
    return [[[ORGate1D alloc] initForCurve:aCurve plot:aPlot]autorelease];
}

-(id)initForCurve:(ORCurve1D*)aCurve plot:(ORPlotter1D*)aPlot
{
    if(self = [super init]){
        mCurve = aCurve;
		mPlot  = aPlot;
        [self setAttributes:[NSMutableDictionary dictionary]];
		fitLableAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Geneva" size:10],NSFontAttributeName,nil] retain];
        [self setDefaults];
        [self registerNotificationObservers];
		RemoveORCARootWarnings; //a #define from ORCARootServiceDefs.h 
    }
    return self;
}


-(id)init
{
    self = [self initForCurve:nil plot:nil];
    return self;
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [attributes release];
    [fitLableAttributes release];
    [analysis release];
    [displayedGateName release];
	[fitString release];
	[fit release];
    [super dealloc];
}

- (NSUndoManager *)undoManager
{
    return [[NSApp delegate] undoManager];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver: self
                     selector: @selector(gateNameChanged:)
                         name: @"ORGateNameChangedNotification"
                       object: nil];
}


- (void) adjustAnalysisPanels
{
	[analysis adjustSize];
}

- (void) gateNameChanged:(NSNotification*)aNote
{
    if([[[aNote userInfo] objectForKey:@"oldGateName"] isEqualToString: displayedGateName]){
        [self setDisplayedGateName:[[aNote object] gateName]];
    }
}

- (void) lowValueChanged:(NSNotification*)aNote
{
    if(displayGate){
        ORGateKey* aGateKey = [aNote object];
        if([[[aGateKey gate] gateName] isEqualToString:displayedGateName]){
            gate1 = MIN([aGateKey lowAcceptValue],[aGateKey highAcceptValue]);
            [self setGateMinChannel:gate1];
            
            [[NSNotificationCenter defaultCenter]
                postNotificationName:ORForcePlotUpdateNotification
							  object:self
							userInfo: [NSDictionary dictionaryWithObject: self
																  forKey:@"OrcaObject Notification Sender"]];

        }
   }
}

- (void) highValueChanged:(NSNotification*)aNote
{
    if(displayGate){
        ORGateKey* aGateKey = [aNote object];
        if([[[aGateKey gate]gateName] isEqualToString:displayedGateName]){
            gate2 = MAX([aGateKey lowAcceptValue],[aGateKey highAcceptValue]);
            [self setGateMaxChannel:gate2];
            [[NSNotificationCenter defaultCenter]
                postNotificationName:ORForcePlotUpdateNotification
							  object:self
							userInfo: [NSDictionary dictionaryWithObject: self
																  forKey:@"OrcaObject Notification Sender"]];
        }
   }
}




- (void) setDefaults
{
    [self setAttributes:[NSMutableDictionary dictionary]];
    [self setGateValid:YES];
}


- (ORAnalysisPanel1D *)analysis 
{
    return analysis; 
}

- (void)setAnalysis:(ORAnalysisPanel1D *)anAnalysis 
{
    [anAnalysis retain];
    [analysis release];
    analysis = anAnalysis;
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

- (NSString *) displayedGateName
{
    return displayedGateName; 
}

- (void) setDisplayedGateName: (NSString *) aDisplayedGateName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDisplayedGateName:displayedGateName];
    
    [displayedGateName autorelease];
    displayedGateName = [aDisplayedGateName copy];
    
    [[NSNotificationCenter defaultCenter]
                postNotificationName:ORGateDisplayedGateChangedNotification
							  object:self
							userInfo: [NSDictionary dictionaryWithObject: self
																  forKey:@"OrcaObject Notification Sender"]];

    [self registerForGateChanges];

}

- (BOOL) displayGate
{
    return displayGate;
}

- (void) setDisplayGate: (BOOL) flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDisplayGate:displayGate];
	
    displayGate = flag;
    
    [[NSNotificationCenter defaultCenter]
                postNotificationName:ORGateDisplayGateChangedNotification
							  object:self
							userInfo: [NSDictionary dictionaryWithObject: self
																  forKey:@"OrcaObject Notification Sender"]];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORForcePlotUpdateNotification
                      object:self
                    userInfo: [NSDictionary dictionaryWithObject: self
                                                          forKey:@"OrcaObject Notification Sender"]];


    [self registerForGateChanges];

}



- (void) analyzePlot:(ORPlotter1D*)aPlot
{
    
    float		val, sumVal, sumValX;
    float		minVal, maxVal;
    
    if([self gateValid] /*&& analyze*/){
        
        id mDataSource = [aPlot dataSource];
        int dataSet = [mCurve dataSetID];
        
        
        /* calculate various parameters */
        [self setGateMinChannel:MIN(gate1,gate2)];
        [self setGateMaxChannel:MAX(gate1,gate2)];
        
        sumVal = sumValX  = 0.0;
        minVal = 3.402e+38;
		maxVal = -3.402e+38;
        
        int	x;
        int maxValX = 0;
		int xStart = [self gateMinChannel];
		int xEnd = [self gateMaxChannel];
		
		int totalNum = xEnd - xStart+1;
		
		if([mDataSource useXYPlot]){
			int index;
			int numPoints = [mDataSource numberOfPointsInPlot:aPlot dataSet:dataSet];
			for (index=0; index<numPoints; ++index) {
				float x;
				if([mDataSource plotter:aPlot dataSet:dataSet index:index  x:&x y:&val]){
					if(x>=xStart && x<=xEnd){
						sumVal += val;
					}
				}
			}
        }
		else {
			x=xStart;
			do {
				val = [mDataSource plotter:aPlot dataSet:dataSet dataValue:x];
				sumVal += val;
				++x;
			} while(x<=xEnd);
		}
		
		double aveVal = 0;
		if(totalNum>0) {
			aveVal = sumVal/(double)totalNum;
			
			float sum_x_minus_xBar_squared = 0;
			if([mDataSource useXYPlot]){
				int index;
				int numPoints = [mDataSource numberOfPointsInPlot:aPlot dataSet:dataSet];
				int n=0;
				for (index=0; index<numPoints; ++index) {
					float x;
					if([mDataSource plotter:aPlot dataSet:dataSet index:index  x:&x y:&val]){
						if(x>=xStart && x<=xEnd){
							n++;
							sumValX += val * x;
							if (val < minVal) minVal = val;
							if (val > maxVal) {
								maxVal = val;
								maxValX = x;
							}
						}
					}
				}
				if(n)[self setAverage: sumVal / (float)n];
				else [self setAverage: 0];
			}
			else {
				x = xStart;
				do {
					val = [mDataSource plotter:aPlot dataSet:dataSet dataValue:x];
					sum_x_minus_xBar_squared += (val - aveVal) * (val-aveVal);
					
					sumValX += val * x;
					if (val < minVal) minVal = val;
					if (val > maxVal) {
						maxVal = val;
						maxValX = x;
					}
					++x;
				} while(x<=xEnd);
				[self setAverage: sumVal / (double) totalNum];
			}
			[self setPeakx:maxValX];
			[self setPeaky:maxVal];
			
			if (sumVal) {
				[self setCentroid:sumValX / sumVal];
				[self setSigma:sqrt((sum_x_minus_xBar_squared) / (double)totalNum)];
			} 
			else {
				[self setCentroid:0];
				[self setSigma:0];
			}
			
			[self setTotalSum:sumVal];
		}
	}
}

- (BOOL) gateValid
{
    return [[attributes objectForKey:ORGate1DValid] boolValue];
}

- (void) setGateValid:(BOOL)newGateValid
{
    [attributes setObject:[NSNumber numberWithBool:newGateValid] forKey:ORGate1DValid];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORGateValidChangedNotification
                      object:self
                    userInfo: nil];
}

- (int) gateMinChannel
{
    return [[attributes objectForKey:ORGate1DMin] intValue];
}
- (void) setGateMinChannel:(int)newGateMinChannel
{
    [attributes setObject:[NSNumber numberWithInt:newGateMinChannel] forKey:ORGate1DMin];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORGateMinChangedNotification
                      object:self
                    userInfo: nil];
}

- (float) gateMaxValue
{
	int val = [self gateMaxChannel];
	id theCalibration = [[mPlot xScale] calibration];
	if(theCalibration && [theCalibration useCalibration])return [theCalibration convertedValueForChannel:val];
	else return val;
}

- (float) gateMinValue
{
	int val = [self gateMinChannel];
	id theCalibration = [[mPlot xScale] calibration];
	if(theCalibration && [theCalibration useCalibration])return [theCalibration convertedValueForChannel:val];
	else return val;
}

- (float) gatePeakValue
{
	float val = [self peakx];
	id theCalibration = [[mPlot xScale] calibration];
	if(theCalibration && [theCalibration useCalibration])return [theCalibration convertedValueForChannel:val];
	else return val;
}

- (float) gateCentroid
{
	float val = [self centroid];
	id theCalibration = [[mPlot xScale] calibration];
	if(theCalibration && [theCalibration useCalibration])return [theCalibration convertedValueForChannel:val];
	else return val;
}

- (float) gateSigma
{
	float val = [self sigma];
	id theCalibration = [[mPlot xScale] calibration];
	if(theCalibration && [theCalibration useCalibration])return [theCalibration convertedValueForChannel:val];
	else return val;
}

- (int) gateMaxChannel
{
    return [[attributes objectForKey:ORGate1DMax] intValue];
}
- (void) setGateMaxChannel:(int)newGateMaxChannel
{
    [attributes setObject:[NSNumber numberWithInt:newGateMaxChannel] forKey:ORGate1DMax];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORGateMaxChangedNotification
                      object:self
                    userInfo: nil];
}


- (void) setDefaultMin:(double)aMin max:(double)aMax
{
    [self setGateMinChannel:aMin];
    [self setGateMaxChannel:aMax];
    gate1 = aMin;
    gate2 = aMax;
	[mPlot setNeedsDisplay:YES];
}

- (double) average
{
    return average;
}
- (void) setAverage:(double)newAverage
{
    average=newAverage;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORGateAverageChangedNotification
                      object:self
                    userInfo: nil];
}


- (double) centroid
{
    return centroid;
}
- (void) setCentroid:(double)newCentroid
{
    centroid=newCentroid;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORGateCentroidChangedNotification
                      object:self
                    userInfo: nil];
}

- (double) sigma
{
    return sigma;
}
- (void) setSigma:(double)newSigma
{
    sigma=newSigma;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORGateSigmaChangedNotification
                      object:self
                    userInfo: nil];
}

- (void) setPeakx:(int)aValue
{
    peakx = aValue;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORGatePeakXChangedNotification
                      object:self
                    userInfo: nil];
}

- (int)  peakx
{
    return peakx;
}

- (void) setPeaky:(int)aValue
{
    peaky = aValue;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORGatePeakYChangedNotification
                      object:self
                    userInfo: nil];
}

- (int)  peaky
{
    return peaky;
}

- (double) totalSum
{
    return totalSum;
}
- (void) setTotalSum:(double)newTotalSum
{
    totalSum=newTotalSum;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORGateTotalSumChangedNotification
                      object:self
                    userInfo: nil];
}

- (BOOL) analyze
{
    return analyze;
}
- (void) setAnalyze:(BOOL)newAnalyze
{
    analyze=newAnalyze;
}

- (int) curveNumber
{
    return [mCurve dataSetID]; 
}

- (int) gateNumber
{
    return [mCurve gateNumber:self]; 
}

- (BOOL) gateIsActive
{
	return ([mPlot activeCurve] == mCurve) && ([mCurve activeGate] == self);
}
- (ORPlotter1D*) plotter
{
	return mPlot;
}

- (void) drawGateInPlot:(ORPlotter1D*)aPlot
{
    if([self gateValid]){
    
        ORAxis* yAxis = [aPlot yScale];
        ORAxis* xAxis = [aPlot xScale];
        id mDataSource = [aPlot dataSource];
        int dataID = [mCurve dataSetID];
       
        int minX = MAX(0,roundToLong([xAxis minValue]));
        int maxX = roundToLong([xAxis maxValue]);
        
        BOOL curveIsActive = [aPlot activeCurve] == mCurve;
        BOOL gateIsActive  = [mCurve activeGate] == self;
        NSColor* gateColor = [aPlot colorForDataSet:dataID];
        [NSBezierPath setDefaultLineWidth:.5];
		
		double inc = [aPlot channelWidth];
		
		
        if(curveIsActive && gateIsActive)	[[gateColor colorWithAlphaComponent:kGateAlpha]set];
        else								[[gateColor colorWithAlphaComponent:kGateAlpha2]set];
		
		if([aPlot useXYPlot]){
			short startGate = [self gateMinChannel];
			short endGate   = [self gateMaxChannel];
			int numPoints = [mDataSource numberOfPointsInPlot:aPlot dataSet:dataID];
			BOOL aLog = [yAxis isLog];
			BOOL aInt = [yAxis integer];
			double aMinPad = [yAxis minPad];
			
			float xl  = [xAxis getPixAbs:minX];
			
			if(curveIsActive && gateIsActive)	[[gateColor colorWithAlphaComponent:kGateAlpha]set];
			else								[[gateColor colorWithAlphaComponent:kGateAlpha2]set];
			
			int i;
			float xValue,yValue;
			BOOL first = YES;
			BOOL lastPtInROI = NO;
			BOOL gotData = NO;
			NSBezierPath* theDataPath = [NSBezierPath bezierPath];
			for (i=0; i<numPoints;++i) {
				
				if([mDataSource plotter:aPlot dataSet:dataID index:i x:&xValue y:&yValue]){
					float x = [xAxis getPixAbs:xValue];
					float y = [yAxis getPixAbsFast:yValue log:aLog integer:aInt minPad:aMinPad];
					if(xValue>=startGate && xValue<=endGate){
						if(first){
							[theDataPath moveToPoint:NSMakePoint(x,0)];
							[theDataPath lineToPoint:NSMakePoint(x,y)];
							first = NO;
						}
						else {
							[theDataPath lineToPoint:NSMakePoint(x,y)];
							gotData = YES;
						}
					}
					else if(xValue>=endGate && gotData){
						[theDataPath lineToPoint:NSMakePoint(xl,y)];
						[theDataPath lineToPoint:NSMakePoint(xl,0)];
						lastPtInROI = YES;
						break;
					}
					// save previous x and y values
					xl = x;
				}
			}
			if(!lastPtInROI && gotData){
				[theDataPath lineToPoint:NSMakePoint(xl,0)];
			}
			if(gotData)[theDataPath fill];
		}
		else {
			int startGate = [self gateMinChannel];
			int endGate   = [self gateMaxChannel];
			long  ix;
			for (ix=minX; ix<maxX;++ix) {
				if(ix>=startGate && ix<=endGate){
					float x = [xAxis getPixAbs:ix]-inc/2.;
					float y = [yAxis getPixAbs:[mDataSource plotter:aPlot dataSet:dataID dataValue:ix ]];
					[NSBezierPath fillRect:NSMakeRect(x,0,inc,y)];
				}
				if(ix > endGate)break;
			}
		}
		if(curveIsActive && gateIsActive){
			float startGatef;
			float endGatef;
			if([aPlot useXYPlot]){
				startGatef = [xAxis getPixAbs:[self gateMinChannel]];
				endGatef   = [xAxis getPixAbs:[self gateMaxChannel]];
			}
			else {
				startGatef = [xAxis getPixAbs:[self gateMinChannel]]-inc/2.;
				endGatef   = [xAxis getPixAbs:[self gateMaxChannel]]+inc/2.;
			}
			float height = [aPlot plotHeight];
			[[NSColor redColor] set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(startGatef,0) toPoint:NSMakePoint(startGatef,height)];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(endGatef,0) toPoint:NSMakePoint(endGatef,height)];
			[[gateColor colorWithAlphaComponent:kGateAlpha]set];
			
           // if([mCurve gateCount]>1){
                NSString* label;
                if(displayGate){
                   if(displayedGateName) label = [NSString stringWithFormat:@"Gate: %@",displayedGateName];
                   else label = @"Gate: ????";
                }
                else {
                    label = [NSString stringWithFormat:@"%d,%d",dataID,[mCurve activeGateIndex]];
                }
                int labelWidth = [label sizeWithAttributes:[xAxis labelAttributes]].width;

                [label drawAtPoint:NSMakePoint(startGatef+(endGatef-startGatef)/2-labelWidth/2,height-20) withAttributes:[xAxis labelAttributes]];

            //}
			int fitLabelHeight = [fitString sizeWithAttributes:fitLableAttributes].height;
			[fitString drawAtPoint:NSMakePoint(20,height-10-fitLabelHeight) withAttributes:fitLableAttributes];
        }
        
    }
}

- (void) keyDown:(NSEvent*)theEvent
{
    gate1 = [self gateMinChannel];
    gate2 = [self gateMaxChannel];
    
    if([theEvent keyCode] == 123){
        //left arrow
        if(gate1>0 && gate2>0){
            gate1--;
            gate2--;
            [self setGateMinChannel:gate1];
            [self setGateMaxChannel:gate2];
        }
    }
    else if([theEvent keyCode] == 124){
        //right arrow
        gate1++;
        gate2++;
        [self setGateMinChannel:gate1];
        [self setGateMaxChannel:gate2];
        
    }
}


-(void)	mouseDown:(NSEvent*)theEvent  plotter:(ORPlotter1D*)aPlotter
{
    if(displayGate){
        ORGateGroup* gateGroup = [[[NSApp delegate] document] gateGroup];
        cachedGate = [[gateGroup gateWithName:displayedGateName] gateKey];
        //remove our notifications to prevent conflicts while moving the mouse
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ORGateLowValueChangedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ORGateHighValueChangedNotification" object:nil];
    }

    NSPoint p = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
    if([aPlotter mouse:p inRect:[aPlotter bounds]]){
        ORAxis* xScale = [aPlotter xScale];
        int mouseChan = floor([xScale convertPoint:p.x]+.5);
        startChan = mouseChan;
        
        if(([theEvent modifierFlags] & NSAlternateKeyMask) || (gate1 == 0 && gate2 == 0)){
            dragType = kInitialDrag;
            gate1 = mouseChan;
            gate2 = gate1;
            [self setGateMinChannel:MIN(gate1,gate2)];
            [self setGateMaxChannel:MAX(gate1,gate2)];
        }
        else if(!([theEvent modifierFlags] & NSCommandKeyMask)){
            if(fabs([xScale getPixAbs:startChan]-[xScale getPixAbs:[self gateMinChannel]])<3){
                dragType = kMinDrag;
                gate1 = [self gateMaxChannel];
                gate2 = [self gateMinChannel];
            }
            else if(fabs([xScale getPixAbs:startChan]-[xScale getPixAbs:[self gateMaxChannel]])<3){
                dragType = kMaxDrag;
                gate1 = [self gateMinChannel];
                gate2 = [self gateMaxChannel];
            }
            else if([xScale getPixAbs:startChan]>[xScale getPixAbs:[self gateMinChannel]] && [xScale getPixAbs:startChan]<[xScale getPixAbs:[self gateMaxChannel]]){
                dragType = kCenterDrag;
            }
            else dragType = kNoDrag;
        }
        else if(([theEvent modifierFlags] & NSCommandKeyMask) &&
                ([xScale getPixAbs:startChan]>=[xScale getPixAbs:[self gateMinChannel]] && [xScale getPixAbs:startChan]<=[xScale getPixAbs:[self gateMaxChannel]])){
            dragType = kCenterDrag;
        }
        else dragType = kNoDrag;
        
        if(dragType!=kNoDrag){
			[[NSCursor closedHandCursor] push];
		}
        [self setGateValid:YES];        
        dragInProgress = YES;
        [aPlotter setNeedsDisplay:YES];
    }
}

-(void)	mouseDragged:(NSEvent*)theEvent  plotter:(ORPlotter1D*)aPlotter
{
    [self doDrag:theEvent plotter:aPlotter];
}


-(void)	mouseUp:(NSEvent*)theEvent  plotter:(ORPlotter1D*)aPlotter
{
    [self doDrag:theEvent plotter:aPlotter];
    
    if(displayGate){
        //restore our registration for gate changes.
        
        [self registerForGateChanges];
    }
    dragInProgress = NO;
    cachedGate = nil;
}

- (void) doDrag:(NSEvent*)theEvent  plotter:(ORPlotter1D*)aPlotter
{
    
    if(dragInProgress){
        ORAxis* xScale = [aPlotter xScale];
        NSPoint p = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
        int delta;
        int mouseChan = ceil([xScale convertPoint:p.x]+.5);
        switch(dragType){
            case kInitialDrag:
                gate2 = mouseChan;
                if(gate2<0)gate2=0;
                [self setGateMinChannel:MIN(gate1,gate2)];
                [self setGateMaxChannel:MAX(gate1,gate2)];
            break;
            
            case kMinDrag:
                gate2 = mouseChan;
                if(gate2<0)gate2=0;
                [self setGateMinChannel:MIN(gate1,gate2)];
                [self setGateMaxChannel:MAX(gate1,gate2)];
            break;
            
            case kMaxDrag:
                gate2 = mouseChan;
                if(gate2<0)gate2=0;
                [self setGateMinChannel:MIN(gate1,gate2)];
                [self setGateMaxChannel:MAX(gate1,gate2)];
            break;
            
            case kCenterDrag:
                delta = startChan-mouseChan;
                int new1 = gate1 - delta;
                int new2 = gate2 - delta;
                int w = abs(new1-new2-1);
                if(new1<0){
                    new1 = 0;
                    new2 = new1 + w;
                }
                else if(new2<0){
                    new2 = 0;
                    new1 = new2 + w;
                }
                else {
                    startChan = mouseChan;
                    gate1 = new1;
                    gate2 = new2;
                    [self setGateMinChannel:MIN(gate1,gate2)];
                    [self setGateMaxChannel:MAX(gate1,gate2)];
                }
            break;
        }

        if(displayGate && cachedGate){
            [cachedGate setLowAcceptValue:MIN(gate1,gate2)];
            [cachedGate setHighAcceptValue:MAX(gate1,gate2)];
        }
        
        [aPlotter setNeedsDisplay:YES];
        
    }
}


- (void) clearGate
{
    [self setGateValid:NO];
}

- (void) postNewGateID
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORGateCurveNumberChangedNotification
                      object:self
                    userInfo: nil];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORGateNumberChangedNotification
                      object:self
                    userInfo: nil];
    
}

- (BOOL) fitExists
{
	return (fit!=nil) && ([fit count] > 0);
}

- (void) setFit:(NSArray*)anArray
{
	[anArray retain];
	[fit release];
	fit = anArray;
	[mPlot setNeedsDisplay:YES];
	
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORGateFitChanged
                      object:self
                    userInfo: nil];
	
}

- (void) setFitString:(NSString*)aString
{
    [fitString autorelease];
    fitString = [aString copy];
	[mPlot setNeedsDisplay:YES];
}

- (int) fitMinChannel 
{
	return fitMinChannel;
}

- (int) fitMaxChannel 
{
	return fitMaxChannel;
}

- (void) doFFT:(id)userInfo
{
	[mPlot doFFT:userInfo];
}


- (void) doFit:(id)userInfo
{
	NSArray* dataPoints;
	if([[mPlot dataSource] useXYPlot])	dataPoints = [mCurve dataPointArray:mPlot range:NSMakeRange([self gateMinChannel],[self gateMaxChannel])];
	else						dataPoints = [mCurve dataPointArray:mPlot range:NSMakeRange(0,[self gateMaxChannel])];
	
	if([dataPoints count]){
		NSMutableDictionary* serviceRequest = [NSMutableDictionary dictionary];
		[serviceRequest setObject:@"OROrcaRequestFitProcessor" forKey:@"Request Type"];
		[serviceRequest setObject:@"Normal"					 forKey:@"Request Option"];
		
		NSMutableDictionary* requestInputs = [NSMutableDictionary dictionary];
		fitMinChannel = [self gateMinChannel];
		fitMaxChannel = [self gateMaxChannel];
		if([[mPlot dataSource] useXYPlot]){
			[requestInputs setObject:[NSNumber numberWithInt:0] forKey:@"FitLowerBound"];
			[requestInputs setObject:[NSNumber numberWithInt:[dataPoints count]] forKey:@"FitUpperBound"];
		}
		else {
			[requestInputs setObject:[NSNumber numberWithInt:fitMinChannel] forKey:@"FitLowerBound"];
			[requestInputs setObject:[NSNumber numberWithInt:fitMaxChannel] forKey:@"FitUpperBound"];
		}
		
		NSString* fitFunction = kORCARootFitShortNames[[[userInfo objectForKey:ORCARootServiceFitFunctionKey] intValue]];
		if([fitFunction hasPrefix:@"pol"]){
			int order = [[userInfo objectForKey:ORCARootServiceFitOrderKey] intValue];
			fitFunction = [fitFunction stringByAppendingFormat:@"%d",order];
		}
		else if([fitFunction hasPrefix:@"arb"]){
			fitFunction = [userInfo objectForKey:ORCARootServiceFitFunction];
		}
		[requestInputs setObject:fitFunction forKey:@"FitFunction"];
		[requestInputs setObject:[NSArray array] forKey:@"FitParameters"];
		[requestInputs setObject:@"" forKey:@"FitOptions"];
		[requestInputs setObject:dataPoints forKey:@"FitYValues"];
		
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
		if([[aResponse objectForKey:@"Request Type"] isEqualToString: @"OROrcaRequestFitProcessor"]){
			NSArray* fitParams		= [aResponse nestedObjectForKey:@"Request Outputs",@"FitOutputParameters",nil];
			NSArray* fitParamNames	= [aResponse nestedObjectForKey:@"Request Outputs",@"FitOutputParametersNames",nil];
			NSArray* fitParamErrors = [aResponse nestedObjectForKey:@"Request Outputs",@"FitOutputErrorParameters",nil];
			NSNumber* chiSquare		= [aResponse nestedObjectForKey:@"Request Outputs",@"FitChiSquare",nil];
			NSLog(@"----------------------------------------\n");
			NSLog(@"Fit done on %@\n",[[[mPlot dataSource] window] title]);
			NSLog(@"Data curve: %d roi: %d\n",[mCurve dataSetID],[mCurve activeGateIndex]);
			NSLog(@"Channels %d to %d\n",[self gateMinChannel],[self gateMaxChannel]);
			NSLog(@"Fit Equation: %@\n",[aResponse nestedObjectForKey:@"Request Outputs",@"FitEquation",nil]);
			int n = [fitParams count];
			int i;
			NSString* s = [NSString stringWithFormat:@"Data curve: %d roi: %d\n",[mCurve dataSetID],[mCurve activeGateIndex]];
			s = [s stringByAppendingFormat:@"Fit Equation: %@\n",[aResponse nestedObjectForKey:@"Request Outputs",@"FitEquation",nil]];
			for(i=0;i<n;i++){
				NSLog(@"%@ = %.5G +/- %.5G\n",[fitParamNames objectAtIndex:i], [[fitParams objectAtIndex:i] floatValue],[[fitParamErrors objectAtIndex:i] floatValue]);
				s = [s stringByAppendingFormat:@"%@ = %.5G +/- %.5G\n",[fitParamNames objectAtIndex:i], [[fitParams objectAtIndex:i] floatValue],[[fitParamErrors objectAtIndex:i] floatValue]];
			}
			NSLog(@"Chi Square = %@\n",chiSquare);
			s = [s stringByAppendingFormat:@"Chi Square = %.5G\n",[chiSquare floatValue]];
			[self setFitString:s];
			[self setFit:[aResponse nestedObjectForKey:@"Request Outputs",@"FitOutputYValues",nil]];
			NSLog(@"----------------------------------------\n");
		}
	}
	else {
		[self setFit: nil];
		NSLog(@"----------------------------------------\n");
		NSLog(@"Error returned for Fit on %@\n",[[[mPlot dataSource] window] title]);
		NSLog(@"Error message: %@\n",[aResponse objectForKey:@"Request Error"]);
		NSLog(@"----------------------------------------\n");
	}
}

- (void) removeFit
{
	[self setFitString:@""];
	[self setFit:nil];
}

- (int)	numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
		return [fit count];
}

- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x
{
	if(x>[fit count])return 0.0;
	else return [[fit objectAtIndex:x] floatValue];
}


static NSString *ORGateDisplayedGateName     = @"ORGateDisplayedGateName";
static NSString *ORGateDisplayGate           = @"ORGateDisplayGate";

- (void)encodeWithCoder:(NSCoder *)coder
{
    if([coder allowsKeyedCoding]){
        [coder encodeObject:attributes forKey:@"ORGate1DAttributes"];
        [coder encodeObject:mCurve forKey:@"ORGate1DCurve"];
        [coder encodeObject: displayedGateName forKey: ORGateDisplayedGateName];
        [coder encodeBool: displayGate forKey: ORGateDisplayGate];
    }
    else {
        [coder encodeObject:attributes];
        [coder encodeObject:mCurve];
        [coder encodeObject:displayedGateName];
        [coder encodeValueOfObjCType:@encode(BOOL)   at: &displayGate];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if([coder allowsKeyedCoding]){
        [self setAttributes:[coder decodeObjectForKey:@"ORGate1DAttributes"]];    
        mCurve = [coder decodeObjectForKey:@"ORGate1DCurve"];    
        [self setDisplayedGateName:[coder decodeObjectForKey: ORGateDisplayedGateName]];
        [self setDisplayGate:[coder decodeBoolForKey: ORGateDisplayGate]];
    }
    else {
        unsigned version = [coder versionForClassName:@"ORGate1D"];
        [self setAttributes:[coder decodeObject]];    
        mCurve = [coder decodeObject]; 
        if(version>1){
            [self setDisplayedGateName:[coder decodeObject]];
            [coder decodeValueOfObjCType:@encode(BOOL)   at: &displayGate];

        }   
    }
    
    [self registerNotificationObservers];

    return self;
}

@end

@implementation ORGate1D (private)
- (void) registerForGateChanges
{
    if(!displayGate){
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ORGateLowValueChangedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ORGateHighValueChangedNotification" object:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter]  addObserver: self
                     selector: @selector(lowValueChanged:)
                         name: @"ORGateLowValueChangedNotification"
                       object: nil];
    
        [[NSNotificationCenter defaultCenter]  addObserver: self
                     selector: @selector(highValueChanged:)
                         name: @"ORGateHighValueChangedNotification"
                       object: nil];

        
        ORGateGroup* gateGroup = [[[NSApp delegate] document] gateGroup];
        ORGateKey* aGateKey = [[gateGroup gateWithName:[self displayedGateName]]gateKey];
        
        NSNotification* aNote;
         aNote = [NSNotification notificationWithName:@"ORGateLowValueChangedNotification" object:aGateKey];
        [self lowValueChanged:aNote];
        
        aNote = [NSNotification notificationWithName:@"ORGateHighValueChangedNotification" object:aGateKey];
        [self highValueChanged:aNote];
    }
}
@end

