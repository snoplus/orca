//
//  ORManualPlotModel.m
//  Orca
//
//  Created by Mark Howe on Fri Apr 27 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORManualPlotModel.h"
#import "NSNotifications+Extensions.h"
#import "ORDataSet.h"
#import "ORCARootServiceDefs.h"

NSString* ORManualPlotModelCol2TitleChanged = @"ORManualPlotModelCol2TitleChanged";
NSString* ORManualPlotModelCol1TitleChanged = @"ORManualPlotModelCol1TitleChanged";
NSString* ORManualPlotModelCol0TitleChanged = @"ORManualPlotModelCol0TitleChanged";
NSString* ORManualPlotModelColKeyChanged	= @"ORManualPlotModelColKeyChanged";
NSString* ORManualPlotLock					= @"ORManualPlotLock";
NSString* ORManualPlotDataChanged			= @"ORManualPlotDataChanged";

@implementation ORManualPlotModel

#pragma mark •••initialization
- (id) init 
{
    self = [super init];
	dataSetLock = [[NSLock alloc] init];
	if(kORCARootFitNames[0] != nil){} //just to get rid of stupid compiler warning
	if(kORCARootFFTNames[0] != nil){} //just to get rid of stupid compiler warning
	if(kORCARootFitShortNames[0] != nil){} //just to get rid of stupid compiler warning
	if(kORCARootFFTWindowOptions[0] != nil){} //just to get rid of stupid compiler warning
	if(kORCARootFFTWindowNames[0] != nil){} //just to get rid of stupid compiler warning
    return self;    
}

- (void) dealloc
{
	[fftDataSet release];
    [col2Title release];
    [col1Title release];
    [col0Title release];
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
	[data addObject:[NSArray arrayWithObjects:
					 [NSNumber numberWithFloat:v1],
					 [NSNumber numberWithFloat:v2],
					 [NSNumber numberWithFloat:v3],
					 nil]];
	[dataSetLock unlock];	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORManualPlotDataChanged object:self];

}

#pragma mark ***Accessors
- (void) postUpdate
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotDataChanged object:self];    
}

- (id) calibration
{
	return calibration;
}

- (void) setCalibration:(id)aCalibration
{
	[aCalibration retain];
	[calibration release];
	calibration  = aCalibration;
}

- (NSString*) col2Title
{
    return col2Title;
}

- (void) setCol2Title:(NSString*)aCol2Title
{
    [col2Title autorelease];
    col2Title = [aCol2Title copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelCol2TitleChanged object:self];
}

- (NSString*) col1Title
{
    return col1Title;
}

- (void) setCol1Title:(NSString*)aCol1Title
{
    [col1Title autorelease];
    col1Title = [aCol1Title copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelCol1TitleChanged object:self];
}

- (NSString*) col0Title
{
    return col0Title;
}

- (void) setCol0Title:(NSString*)aCol0Title
{
    [col0Title autorelease];
    col0Title = [aCol0Title copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelCol0TitleChanged object:self];
}

- (int) col2Key;
{
    return col2Key;
}

- (void) setCol2Key:(int)aCol2Key;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCol2Key:col2Key];
    col2Key = aCol2Key;    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelColKeyChanged object:self];
}

- (int) col1Key;
{
    return col1Key;
}

- (void) setCol1Key:(int)aCol1Key;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCol1Key:col1Key];
    col1Key = aCol1Key;    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelColKeyChanged object:self];
}

- (int) col0Key
{
    return col0Key;
}

- (void) setCol0Key:(int)aCol0Key;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCol0Key:col0Key];
    col0Key = aCol0Key;    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORManualPlotModelColKeyChanged object:self];
}

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
    [self setCol2Key:[decoder decodeIntForKey:@"ORManualPlotModelCol2Key"]];
    [self setCol1Key:[decoder decodeIntForKey:@"ORManualPlotModelCol1Key"]];
    [self setCol0Key:[decoder decodeIntForKey:@"ORManualPlotModelCol0Key"]];
	[self setCalibration:[decoder decodeObjectForKey:@"calibration"]];
	if(col0Key==0 && col1Key==0 && col2Key==0){
		[self setCol0Key:0]; 
		[self setCol1Key:1];		
	}
    [[self undoManager] enableUndoRegistration];

	dataSetLock = [[NSLock alloc] init];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:col2Key forKey:@"ORManualPlotModelCol2Key"];
    [encoder encodeInt:col1Key forKey:@"ORManualPlotModelCol1Key"];
    [encoder encodeInt:col0Key forKey:@"ORManualPlotModelCol0Key"];
    [encoder encodeObject:calibration forKey:@"calibration"];
}

-(void)clear
{
	[dataSetLock lock];
	[data release];
	data = nil;
	[dataSetLock unlock];
}

- (NSString*) fullName
{
	return [self fullID];
}

- (NSString*) fullNameWithRunNumber
{
	//fake out so we can inherit
	return [self fullID];
}

#pragma mark •••Writing Data
- (void) writeDataToFile:(NSString*)aFileName
{
	[dataSetLock lock];
	
	NSString* fullFileName = [aFileName stringByExpandingTildeInPath];
	FILE* aFile = fopen([fullFileName cStringUsingEncoding:NSASCIIStringEncoding],"w"); 
	if(aFile){
		NSLog(@"Writing Manual Plot File: %@\n",fullFileName);
		NSEnumerator* e = [data objectEnumerator];
		NSArray* row;
		while(row=[e nextObject]){
			fprintf(aFile, "%f\t%f\t%f\n",[[row objectAtIndex:0] floatValue],[[row objectAtIndex:1] floatValue],[[row objectAtIndex:2] floatValue]);
		}
		fclose(aFile);
	}
	
	[dataSetLock unlock];
}

- (void) processResponse:(NSDictionary*)aResponse
{
	NSString* title = [aResponse objectForKey:ORCARootServiceTitleKey];
	NSMutableArray* keyArray = [NSMutableArray arrayWithArray:[title componentsSeparatedByString:@","]];
	[keyArray insertObject:@"FFT" atIndex:0];
	NSArray* complex = [aResponse nestedObjectForKey:@"Request Outputs",@"FFTComplex",nil];
	NSArray* real    = [aResponse nestedObjectForKey:@"Request Outputs",@"FFTReal",nil];
	if(!fftDataSet)fftDataSet = [[ORDataSet alloc] initWithKey:@"fftSet" guardian:nil];
	[fftDataSet loadFFTReal:real imaginary:complex withKeyArray:keyArray];
}

#pragma mark *** delegate methods
-(id) dataAtRow:(int)r column:(int)c
{
	if(r<[data count]){
		NSArray* row =  [data objectAtIndex:r];
		if(c<[row count]){
			return [row objectAtIndex:c];
		}
	}
	return nil;
}


- (unsigned long) numPoints
{
    return [data count];
}

- (BOOL) dataSet:(int)set index:(unsigned long)index x:(float*)xValue y:(float*)yValue
{
	BOOL valid = YES;
	[dataSetLock lock];
	
	if(index<[data count]){
		id d = [data objectAtIndex:index];
		if(col0Key <= 2) *xValue = [[d objectAtIndex:col0Key] floatValue];
		else *xValue = index;
		if(set==0) {
			if(col1Key <= 2) *yValue = [[d objectAtIndex:col1Key] floatValue];
			else *yValue=0;
		}
		else {
			if(col2Key <= 2) *yValue = [[d objectAtIndex:col2Key] floatValue];
			else *yValue=0;
		}
	}
	else {
		valid = NO;
		*xValue = 0;
		*yValue = 0;
	}
	[dataSetLock unlock];
    return valid;    
}


@end
