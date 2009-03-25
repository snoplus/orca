//
//  ORManualPlotModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright ¬© 2002 CENPA, University of Washington. All rights reserved.
//

#pragma mark •••Imported Files
#import "ORManualPlotModel.h"
#import "NSNotifications+Extensions.h"

NSString* ORManualPlotLock						= @"ORManualPlotLock";
NSString* ORManualPlotDataChanged				= @"ORManualPlotDataChanged";

@implementation ORManualPlotModel

#pragma mark •••initialization
- (id) init 
{
    self = [super init];
	dataSetLock = [[NSLock alloc] init];
    return self;    
}

- (void) dealloc
{
	[dataSetLock release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[data release];
    [super dealloc];
}

- (void) clearData
{
	[dataSetLock lock];
	[data release];
	data = nil;
	[dataSetLock unlock];	
}

- (void) addValue1:(float)v1 value2:(float)v2 value3:(float)v3
{
	[dataSetLock lock];
	if(!data) data = [[NSMutableArray array] retain];
	[data addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
					 [NSNumber numberWithFloat:v1],@"0",
					 [NSNumber numberWithFloat:v2],@"1",
					 [NSNumber numberWithFloat:v3],@"2",
					 nil]];
	[dataSetLock unlock];	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORManualPlotDataChanged object:self];

}

#pragma mark ***Accessors
- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"ManualPlot"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORManualPlotController"];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
		
    [[self undoManager] enableUndoRegistration];

	dataSetLock = [[NSLock alloc] init];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
}

-(void)clear
{
	[dataSetLock lock];
	[data release];
	data = nil;
	[dataSetLock unlock];
}

#pragma mark •••Writing Data
- (void) writeDataToFile:(FILE*)aFile
{
}
		
#pragma mark *** delegate methods
-(id) dataAtIndex:(int)i key:(id)aKey
{
	if(i<[data count]){
		return [[data objectAtIndex:i] objectForKey:aKey];
	}
	else return nil;
}

- (unsigned long) numPoints
{
    return [data count];
}



- (BOOL) dataSet:(int)set index:(unsigned long)index x:(float*)xValue y:(float*)yValue
{
	[dataSetLock lock];
	if(index<[data count]){
		id d = [data objectAtIndex:index];
		*xValue = [[d objectForKey:@"0"] floatValue];
		if(set==0) *yValue = [[d objectForKey:@"1"] floatValue]; 
		else	   *yValue = [[d objectForKey:@"2"] floatValue];
	}
	else {
		*xValue = 0;
		*yValue = 0;
	}
	[dataSetLock unlock];
    return YES;    
}

@end
