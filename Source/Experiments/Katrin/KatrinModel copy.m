//
//  KatrinModel.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//

#pragma mark ¥¥¥Imported Files
#import "KatrinModel.h"
#import "KatrinController.h"
#import "ORAxis.h"
#import "ORDataPacket.h"
#import "ORTimeRate.h"
#import "ORDataTypeAssigner.h"
#import "ORRunModel.h"
#import "ORDetectorSegment.h"


NSString* KatrinModelDisplayTypeChanged				 = @"KatrinModelDisplayTypeChanged";
NSString* KatrinReadMapNotification					 = @"KatrinReadMapNotification";
NSString* KatrinModelVetoMapFileChanged				 = @"KatrinModelVetoMapFileChanged";
NSString* KatrinModelFocalPlaneMapFileChanged		 = @"KatrinModelFocalPlaneMapFileChanged";
NSString* KatrinModelSelectionStringChanged			 = @"KatrinModelSelectionStringChanged";
NSString* KatrinModelFocalPlaneAdcClassNameChanged	 = @"KatrinModelFocalPlaneAdcClassNameChanged";
NSString* KatrinModelVetoAdcClassNameChanged		 = @"KatrinModelVetoAdcClassNameChanged";
NSString* KatrinHardwareCheckChangedNotification     = @"KatrinHardwareCheckChangedNotification";
NSString* KatrinCardCheckChangedNotification         = @"KatrinCardCheckChangedNotification";
NSString* KatrinCaptureDateChangedNotification       = @"KatrinCaptureDateChangedNotification";
NSString* KatrinRateAllDisableChangedNotification    = @"KatrinRateAllDisableChangedNotification";
NSString* KatrinDisplayUpdatedNeeded			 	 = @"KatrinDisplayUpdatedNeeded";
NSString* KatrinCollectedRates						 = @"KatrinCollectedRates";
NSString* KatrinDisplayHistogramsUpdated			 = @"KatrinDisplayHistogramsUpdated";

NSString* KatrinMapLock								 = @"KatrinMapLock";
NSString* KatrinDetectorLock						 = @"KatrinDetectorLock";
NSString* KatrinDetailsLock							 = @"KatrinDetailsLock";

static NSString* KatrinDbConnector = @"KatrinDbConnector";

enum {
    kDisplayTubeLabel = (1 << 0)
};


@interface KatrinModel (private)
- (void) checkCardOld:(NSDictionary*)oldCardRecord new:(NSDictionary*)newCardRecord  check:(SEL)checkSelector exclude:(NSSet*)exclusionSet;
- (void) makeFocalPlaneSegments;
- (void) makeVetoSegments;
- (void) delayedHistogram;
@end


@implementation KatrinModel

#pragma mark ¥¥¥Initialization

- (id) init //designated initializer
{
    self = [super init];
    
    colorAxisFocalPlaneAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithDouble:0],ORAxisMinValue,
        [NSNumber numberWithDouble:10000],ORAxisMaxValue,
        [NSNumber numberWithBool:NO],ORAxisUseLog,
        nil
     ] retain];
    colorAxisVetoAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithDouble:0],ORAxisMinValue,
        [NSNumber numberWithDouble:10000],ORAxisMaxValue,
        [NSNumber numberWithBool:NO],ORAxisUseLog,
        nil
     ] retain];
	[self makeFocalPlaneSegments];
	[self makeVetoSegments];

    ORTimeRate* r = [[ORTimeRate alloc] init];
    [self setFocalPlaneTotalRate:r];
    [r release];
	
    r = [[ORTimeRate alloc] init];
    [self setVetoTotalRate:r];
    [r release];
		    
	int i;
	for (i=0; i<100; i++) {
		focalPlaneThresholdHistogram[i] = 0;
		focalPlaneGainHistogram[i] = 0;
		vetoThresholdHistogram[i] = 0;
		vetoGainHistogram[i] = 0;
	}
			
    return self;
}

-(void)dealloc
{
    [vetoMapFile release];
    [focalPlaneMapFile release];
    [selectionString release];
    [focalPlaneAdcClassName release];
    [vetoAdcClassName release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [colorAxisFocalPlaneAttributes release];
    [colorAxisVetoAttributes release];
    [xAttributes release];
    [yAttributes release];
        
    [failedHardwareCheckAlarm clearAlarm];
    [failedHardwareCheckAlarm release];
 
	[failedCardCheckAlarm clearAlarm];
    [failedCardCheckAlarm release];
   
    [captureDate release];
    [problemArray release];

	[focalPlaneSegments release];
	[vetoSegments release];
    [focalPlaneTotalRate release];
    [vetoTotalRate release];

    [super dealloc];
}


- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
    
    [self configurationChanged:nil];
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
        
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"katrin"]];
}

- (BOOL) solitaryObject
{
    return YES;
}

- (void) makeMainController
{
    [self linkToController:@"KatrinController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - 35,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:KatrinDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
	[ aConnector setConnectorType: 'DB O' ];
	[ aConnector addRestrictedConnectionType: 'DB I' ]; //can only connect to DB Inputs
    [aConnector release];
    
}


- (void) reloadData:(id)obj
{
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
        
    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORDocumentLoadedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runAboutToEnd:)
                         name : ORRunAboutToStopNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORDocumentLoadedNotification
                       object : [self document]];
					   
    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : @"Shaper Online Mask Changed Notification"
                       object : nil];
}

- (void) registerForRates
{
	NSArray* adcObjects = [[self document] collectObjectsOfClass:NSClassFromString(focalPlaneAdcClassName)];
	[focalPlaneSegments makeObjectsPerformSelector:@selector(registerForRates:) withObject:adcObjects];
	
	adcObjects = [[self document] collectObjectsOfClass:NSClassFromString(vetoAdcClassName)];
	[vetoSegments makeObjectsPerformSelector:@selector(registerForRates:) withObject:adcObjects];
}

- (void) configurationChanged:(NSNotification*)aNote
{
	
	NSArray* adcObjects = [[self document] collectObjectsOfClass:NSClassFromString(focalPlaneAdcClassName)];
	[focalPlaneSegments makeObjectsPerformSelector:@selector(configurationChanged:) withObject:adcObjects];

	adcObjects = [[self document] collectObjectsOfClass:NSClassFromString(vetoAdcClassName)];
	[vetoSegments makeObjectsPerformSelector:@selector(configurationChanged:) withObject:adcObjects];
	[self registerForRates];
	
    [[NSNotificationCenter defaultCenter]
        postNotificationName:KatrinDisplayUpdatedNeeded
                      object:self];
}

- (void) runStatusChanged:(NSNotification*)aNote
{
    int running = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
    if(running == eRunStopped){
        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
        //[[self detector] unregisterRates];
    }
    else {
        [self registerForRates];
        [self collectRates];
    }
}

- (void) collectRates
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
	float sum = 0;
	int i;
	for(i=0;i<numFocalPlaneSegments;i++)sum += [[focalPlaneSegments objectAtIndex:i] rate];
    focalPlaneRate = sum;
    [focalPlaneTotalRate addDataToTimeAverage:sum];
	
	sum = 0;
	for(i=0;i<numVetoSegments;i++)sum += [[focalPlaneSegments objectAtIndex:i] rate];
    vetoRate = sum;
    [vetoTotalRate addDataToTimeAverage:sum];
	
    [[NSNotificationCenter defaultCenter]
        postNotificationName:KatrinCollectedRates
                      object:self];

    [self performSelector:@selector(collectRates) withObject:nil afterDelay:1.0];
}

#pragma mark ¥¥¥Focal Plane Accessors
- (void) focalPlaneSegementSelected:(int)index
{
	if(index<0)[self setSelectionString:@"<nothing selected>"];
	else {
		NSString* string = [NSString stringWithString:@"Focal Plane\n"];
		string = [string stringByAppendingFormat:@"Segment  : %d\n",index];
		string = [string stringByAppendingFormat:@"Adc Class: %@\n",focalPlaneAdcClassName];
		string = [string stringByAppendingFormat:@"Slot     : %@\n",[[[focalPlaneSegments objectAtIndex:index] params] objectForKey:@"kCardSlot"]];
		string = [string stringByAppendingFormat:@"Channel  : %@\n",[[[focalPlaneSegments objectAtIndex:index] params] objectForKey:@"kChannel"]];
		string = [string stringByAppendingFormat:@"Threshold: %d\n",[[focalPlaneSegments objectAtIndex:index] threshold]];
		string = [string stringByAppendingFormat:@"Gain     : %d\n",[[focalPlaneSegments objectAtIndex:index] gain]];
		[self setSelectionString:string];
	}
}

- (int) focalPlaneThresholdHistogram:(int) index
{
	return focalPlaneThresholdHistogram[index];
}

- (int) focalPlaneGainHistogram:(int) index;
{
	return focalPlaneGainHistogram[index];
}

- (ORTimeRate*) focalPlaneTotalRate
{
    return focalPlaneTotalRate;
}
- (void) setFocalPlaneTotalRate:(ORTimeRate*)newTotalRate
{
    [focalPlaneTotalRate autorelease];
    focalPlaneTotalRate=[newTotalRate retain];
}

- (BOOL) focalPlaneHWPresent:(int)aChannel
{
	return [[focalPlaneSegments objectAtIndex:aChannel] hwPresent];
}

- (BOOL) focalPlaneOnline:(int)aChannel;
{
	return [[focalPlaneSegments objectAtIndex:aChannel] online];
}

- (NSString*) focalPlaneMapFile
{
    return focalPlaneMapFile;
}

- (void) setFocalPlaneMapFile:(NSString*)aFocalPlaneMapFile
{    
	if(!aFocalPlaneMapFile)aFocalPlaneMapFile = kDefaultFocalPlaneMap;
    [focalPlaneMapFile autorelease];
    focalPlaneMapFile = [aFocalPlaneMapFile copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:KatrinModelFocalPlaneMapFileChanged object:self];
}

- (NSString*) focalPlaneAdcClassName
{
    return focalPlaneAdcClassName;
}

- (void) setFocalPlaneAdcClassName:(NSString*)aFocalPlaneAdcClassName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFocalPlaneAdcClassName:focalPlaneAdcClassName];
    
    [focalPlaneAdcClassName autorelease];
    focalPlaneAdcClassName = [aFocalPlaneAdcClassName copy];    
	[self configurationChanged:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:KatrinModelFocalPlaneAdcClassNameChanged object:self];
}

- (void) setFocalPlaneSegments:(NSMutableArray*)anArray
{
	[anArray retain];
	[focalPlaneSegments release];
	focalPlaneSegments = anArray;
}

- (NSMutableArray*) focalPlaneSegments
{
	return focalPlaneSegments;
}

- (NSMutableDictionary*) colorAxisFocalPlaneAttributes
{
    return colorAxisFocalPlaneAttributes;
}

- (void) setColorAxisFocalPlaneAttributes:(NSMutableDictionary*)newColorAxisFocalPlaneAttributes
{
	[colorAxisFocalPlaneAttributes release];
    colorAxisFocalPlaneAttributes = [newColorAxisFocalPlaneAttributes copy];
}

- (float) focalPlaneRate
{
	return focalPlaneRate;
}

- (float) getFocalPlaneGain:(int) index
{
	id seg = [focalPlaneSegments objectAtIndex:index];
	if([seg hardwarePresent]) return [seg gain];
	else return -1;
}

- (BOOL) getFocalPlaneError:(int) index
{
	return [[focalPlaneSegments objectAtIndex:index] segmentError];
}

- (float) getFocalPlaneThreshold:(int) index
{
	id seg = [focalPlaneSegments objectAtIndex:index];
	if([seg hardwarePresent]) return [seg threshold];
	else return -1;
}
- (float) getFocalPlaneRate:(int) index
{
	return [[focalPlaneSegments objectAtIndex:index] rate];
}

- (void) readFocalPlaneMap
{
    
    NSString* contents = [NSString stringWithContentsOfFile:[focalPlaneMapFile stringByExpandingTildeInPath]];
    NSArray*  lines = [contents componentsSeparatedByString:@"\n"];
    NSEnumerator* e = [lines objectEnumerator];
    NSString* aLine;
        
    while(aLine = [e nextObject]){
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        if([aLine length] && [aLine characterAtIndex:0] != '#'){
			int index = [aLine intValue];
			if(index>=0 && index < numFocalPlaneSegments){
				ORDetectorSegment* aSegment = [focalPlaneSegments objectAtIndex:index];
				[aSegment decodeLine:aLine];
			}
        }
    }
	[self configurationChanged:nil];   
    [[NSNotificationCenter defaultCenter]
        postNotificationName:KatrinReadMapNotification
                      object:self];
    
}

- (void) saveFocalPlaneMapFileAs:(NSString*)newFileName
{
    NSMutableData* theContents = [NSMutableData data];
    NSEnumerator* e = [focalPlaneSegments objectEnumerator];
    ORDetectorSegment* segment;
    while(segment = [e nextObject]){
        [theContents appendData:[[segment paramsAsString] dataUsingEncoding:NSASCIIStringEncoding]];
        [theContents appendData:[@"\n" dataUsingEncoding:NSASCIIStringEncoding]];
    }
    
    NSFileManager* theFileManager = [NSFileManager defaultManager];
    if([theFileManager fileExistsAtPath:newFileName]){
        [theFileManager removeFileAtPath:newFileName handler:nil];
    }
    [theFileManager createFileAtPath:newFileName contents:theContents attributes:nil];
}

- (void) showDialogForFocalPlaneSegment:(int)aSegment
{
	[[focalPlaneSegments objectAtIndex:aSegment] showDialog];
}


#pragma mark ¥¥¥Veto Accessors

- (void) vetoSegementSelected:(int)index
{
	if(index<0)[self setSelectionString:@"<nothing selected>"];
	else {
		NSString* string = [NSString stringWithString:@"Veto\n"];
		string = [string stringByAppendingFormat:@"Segment  : %d\n",index];
		string = [string stringByAppendingFormat:@"Adc Class: %@\n",vetoAdcClassName];
		string = [string stringByAppendingFormat:@"Slot     : %@\n",[[[vetoSegments objectAtIndex:index] params] objectForKey:@"kCardSlot"]];
		string = [string stringByAppendingFormat:@"Channel  : %@\n",[[[vetoSegments objectAtIndex:index] params] objectForKey:@"kChannel"]];
		string = [string stringByAppendingFormat:@"Threshold: %d\n",[[vetoSegments objectAtIndex:index] threshold]];
		string = [string stringByAppendingFormat:@"Gain     : %d\n",[[vetoSegments objectAtIndex:index] gain]];
		[self setSelectionString:string];
	}
}

- (float) getVetoRate:(int) index
{
	return [[vetoSegments objectAtIndex:index] rate];
}
- (float) vetoRate
{
	return vetoRate;
}
- (float) getVetoThreshold:(int) index
{
	id seg = [vetoSegments objectAtIndex:index];
	if([seg hardwarePresent]) return [seg threshold];
	else return -1;
}

- (float) getVetoGain:(int) index
{
	id seg = [vetoSegments objectAtIndex:index];
	if([seg hardwarePresent]) return [seg gain];
	else return -1;}


- (BOOL) getVetoError:(int) index
{
	return [[vetoSegments objectAtIndex:index] segmentError];
}

- (int) vetoThresholdHistogram:(int) index;
{
	return vetoThresholdHistogram[index];
}

- (int) vetoGainHistogram:(int) index;
{
	return vetoGainHistogram[index];
}

- (ORTimeRate*) vetoTotalRate
{
    return vetoTotalRate;
}

- (void) setVetoTotalRate:(ORTimeRate*)newTotalRate
{
    [vetoTotalRate autorelease];
    vetoTotalRate=[newTotalRate retain];
}

- (BOOL) vetoHWPresent:(int)aChannel;
{
	return [[vetoSegments objectAtIndex:aChannel] hwPresent];
}

- (BOOL) vetoOnline:(int)aChannel;
{
	return [[vetoSegments objectAtIndex:aChannel] online];
}

- (NSString*) vetoMapFile
{
    return vetoMapFile;
}

- (void) setVetoMapFile:(NSString*)aVetoMapFile
{    
	if(!aVetoMapFile)aVetoMapFile = kDefaultVetoMap;
    [vetoMapFile autorelease];
    vetoMapFile = [aVetoMapFile copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:KatrinModelVetoMapFileChanged object:self];
}

- (NSString*) vetoAdcClassName
{
    return vetoAdcClassName;
}

- (void) setVetoAdcClassName:(NSString*)aVetoAdcClassName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVetoAdcClassName:vetoAdcClassName];
    
    [vetoAdcClassName autorelease];
    vetoAdcClassName = [aVetoAdcClassName copy];    
	[self configurationChanged:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:KatrinModelVetoAdcClassNameChanged object:self];
}
- (void) setVetoSegments:(NSMutableArray*)anArray
{
	[anArray retain];
	[vetoSegments release];
	vetoSegments = anArray;
}

- (NSMutableArray*) vetoSegments
{
	return vetoSegments;
}

- (NSMutableDictionary*) colorAxisVetoAttributes
{
    return colorAxisVetoAttributes;
}

- (void) setColorAxisVetoAttributes:(NSMutableDictionary*)newColorAxisVetoAttributes
{
	[colorAxisVetoAttributes release];
    colorAxisVetoAttributes = [newColorAxisVetoAttributes copy];
}

- (void) readVetoMap
{
    
    NSString* contents = [NSString stringWithContentsOfFile:[vetoMapFile stringByExpandingTildeInPath]];
    NSArray*  lines = [contents componentsSeparatedByString:@"\n"];
    NSEnumerator* e = [lines objectEnumerator];
    NSString* aLine;
        
    while(aLine = [e nextObject]){
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        if([aLine length] && [aLine characterAtIndex:0] != '#'){
			int index = [aLine intValue];
			if(index>=0 && index < numVetoSegments){
				ORDetectorSegment* aSegment = [vetoSegments objectAtIndex:index];
				[aSegment decodeLine:aLine];
			}
        }
    }
	
	[self configurationChanged:nil];   
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:KatrinReadMapNotification
                      object:self];
    
}

- (void) saveVetoMapFileAs:(NSString*)newFileName
{
    NSMutableData* theContents = [NSMutableData data];
    NSEnumerator* e = [vetoSegments objectEnumerator];
    ORDetectorSegment* segment;
    while(segment = [e nextObject]){
        [theContents appendData:[[segment paramsAsString] dataUsingEncoding:NSASCIIStringEncoding]];
        [theContents appendData:[@"\n" dataUsingEncoding:NSASCIIStringEncoding]];
    }
    
    NSFileManager* theFileManager = [NSFileManager defaultManager];
    if([theFileManager fileExistsAtPath:newFileName]){
        [theFileManager removeFileAtPath:newFileName handler:nil];
    }
    [theFileManager createFileAtPath:newFileName contents:theContents attributes:nil];
}

- (void) showDialogForVetoSegment:(int)aSegment
{
	[[vetoSegments  objectAtIndex:aSegment] showDialog];
}
#pragma mark ¥¥¥Accessors

- (void) compileHistograms
{
	if(!scheduledToHistogram){
		[self performSelector:@selector(delayedHistogram) withObject:nil afterDelay:1];
		scheduledToHistogram = YES;
	}
}

- (int) displayType
{
    return displayType;
}

- (void) setDisplayType:(int)aDisplayType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDisplayType:displayType];
    
    displayType = aDisplayType;

    [[NSNotificationCenter defaultCenter] postNotificationName:KatrinModelDisplayTypeChanged object:self];
}


- (NSString*) selectionString
{
	if(!selectionString)return @"<nothing selected>";
    else return selectionString;
}

- (void) setSelectionString:(NSString*)aSelectionString
{
    [selectionString autorelease];
    selectionString = [aSelectionString copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:KatrinModelSelectionStringChanged object:self];
}

- (BOOL) replayMode
{
	return replayMode;
}

- (void) setReplayMode:(BOOL)aReplayMode
{
	replayMode = aReplayMode;
	//[[Prespectrometer sharedInstance] setReplayMode:aReplayMode];
}

- (NSDictionary*)   xAttributes
{
    return xAttributes;
}

- (NSDictionary*)   yAttributes
{
    return yAttributes;
}

- (void) setYAttributes:(NSDictionary*)someAttributes
{
    [yAttributes release];
    yAttributes = [someAttributes copy];
}

- (void) setXAttributes:(NSDictionary*)someAttributes
{
    [xAttributes release];
    xAttributes = [someAttributes copy];
}


- (int) hardwareCheck
{
    return hardwareCheck;
}

- (void) setHardwareCheck: (int) aState
{
    hardwareCheck = aState;
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:KatrinHardwareCheckChangedNotification
                      object:self];
    
    if(hardwareCheck==NO) {
		if(!failedHardwareCheckAlarm){
			failedHardwareCheckAlarm = [[ORAlarm alloc] initWithName:@"Hardware Check Failed" severity:kSetupAlarm];
			[failedHardwareCheckAlarm setSticky:YES];
		}
		[failedHardwareCheckAlarm setAcknowledged:NO];
		[failedHardwareCheckAlarm postAlarm];
        [failedHardwareCheckAlarm setHelpStringFromFile:@"HardwareCheckHelp"];
    }
    else {
        [failedHardwareCheckAlarm clearAlarm];
    }
    
}


- (int) cardCheck
{
    return cardCheck;
}

- (void) setCardCheck: (int) aState
{
    cardCheck = aState;
    [[NSNotificationCenter defaultCenter]
         postNotificationName:KatrinCardCheckChangedNotification
                       object:self];
    
    if(cardCheck==NO) {
		if(!failedCardCheckAlarm){
			failedCardCheckAlarm = [[ORAlarm alloc] initWithName:@"Card Check Failed" severity:kSetupAlarm];
			[failedCardCheckAlarm setSticky:YES];
		}
		[failedCardCheckAlarm setAcknowledged:NO];
		[failedCardCheckAlarm postAlarm];
        [failedCardCheckAlarm setHelpStringFromFile:@"CardCheckHelp"];
    }
    else {
        [failedCardCheckAlarm clearAlarm];
    }
}

- (void) setCardCheckFailed
{
    [self setCardCheck:NO];
}

- (void) setHardwareCheckFailed
{
    [self setHardwareCheck:NO];
}

- (NSDate *) captureDate
{
    return captureDate; 
}

- (void) setCaptureDate: (NSDate *) aCaptureDate
{
    [aCaptureDate retain];
    [captureDate release];
    captureDate = aCaptureDate;
    
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:KatrinCaptureDateChangedNotification
                      object:self];
    
}
 
#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setDisplayType:[decoder decodeIntForKey:@"KatrinModelDisplayType"]];
    [self setVetoMapFile:[decoder decodeObjectForKey:@"KatrinModelVetoMapFile"]];
    [self setFocalPlaneMapFile:[decoder decodeObjectForKey:@"KatrinModelFocalPlaneMapFile"]];
    [self setFocalPlaneAdcClassName:[decoder decodeObjectForKey:@"KatrinModelFocalPlaneAdcClassName"]];
    [self setVetoAdcClassName:[decoder decodeObjectForKey:@"KatrinModelVetoAdcClassName"]];
    [self setColorAxisFocalPlaneAttributes:[decoder decodeObjectForKey:@"KatrinColorAxisFocalPlaneAttributes"]];
    [self setColorAxisVetoAttributes:[decoder decodeObjectForKey:@"KatrinColorAxisVetoAttributes"]];
    [self setXAttributes:[decoder decodeObjectForKey:@"KatrinXAttributes"]];
    [self setYAttributes:[decoder decodeObjectForKey:@"KatrinYAttributes"]];
    
    [self setCaptureDate:[decoder decodeObjectForKey:@"KatrinCaptureDate"]];
	[self setFocalPlaneSegments:[decoder decodeObjectForKey:@"FocalPlaneSegments"]];
	[self setVetoSegments:[decoder decodeObjectForKey:@"VetoSegments"]];

    [self setFocalPlaneTotalRate:[decoder decodeObjectForKey:@"KatrinFocalPlaneRate"]];
    [self setVetoTotalRate:[decoder decodeObjectForKey:@"KatrinVetoRate"]];

    if(focalPlaneTotalRate==nil){
        ORTimeRate* r = [[ORTimeRate alloc] init];
        [self setFocalPlaneTotalRate:r];
        [r release];
    }
    if(vetoTotalRate==nil){
        ORTimeRate* r = [[ORTimeRate alloc] init];
        [self setVetoTotalRate:r];
        [r release];
    }
	
    [[self undoManager] enableUndoRegistration];
    
	//do some checking and repairing
	if(!focalPlaneSegments)[self makeFocalPlaneSegments];
	if(!vetoSegments)[self makeVetoSegments];

    [self setHardwareCheck:2]; //unknown
    [self setCardCheck:2];


	if(!focalPlaneAdcClassName)[self setFocalPlaneAdcClassName:@"ORAugerFltModel"];
	if(!vetoAdcClassName)[self setVetoAdcClassName:@"ORAugerFltModel"];

    [self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
        
    [encoder encodeInt:displayType forKey:@"KatrinModelDisplayType"];
    [encoder encodeObject:vetoMapFile forKey:@"KatrinModelVetoMapFile"];
    [encoder encodeObject:focalPlaneMapFile forKey:@"KatrinModelFocalPlaneMapFile"];
    [encoder encodeObject:focalPlaneAdcClassName forKey:@"KatrinModelFocalPlaneAdcClassName"];
    [encoder encodeObject:vetoAdcClassName forKey:@"KatrinModelVetoAdcClassName"];
   
    [encoder encodeObject:colorAxisFocalPlaneAttributes forKey:@"KatrinColorAxisFocalPlaneAttributes"];
    [encoder encodeObject:colorAxisVetoAttributes forKey:@"KatrinColorAxisVetoAttributes"];
    [encoder encodeObject:xAttributes forKey:@"KatrinXAttributes"];
    [encoder encodeObject:yAttributes forKey:@"KatrinYAttributes"];
    
    [encoder encodeObject:focalPlaneSegments forKey:@"FocalPlaneSegments"];
    [encoder encodeObject:vetoSegments forKey:@"VetoSegments"];
    [encoder encodeObject:focalPlaneTotalRate forKey:@"KatrinFocalPlaneRate"];
    [encoder encodeObject:vetoTotalRate forKey:@"VetoFocalPlaneRate"];
    
    [encoder encodeObject:captureDate forKey:@"KatrinCaptureDate"];
}


- (void) runAboutToStart:(NSNotification*)aNote
{
    //unsigned long runTypeMask = [[[aNote userInfo] objectForKey:@"RunType"] longValue];
}

- (void) runAboutToEnd:(NSNotification*)aNote
{
}


#define CapturePListFile @"~/Library/Preferences/edu.washington.npl.orca.capture.katrin.plist"

- (NSMutableDictionary*) captureState
{
    NSMutableDictionary* stateDictionary = [NSMutableDictionary dictionary];
    [[self document] captureCurrentState: stateDictionary];
    
    [stateDictionary writeToFile:[CapturePListFile stringByExpandingTildeInPath] atomically:YES];
    
    [self setHardwareCheck:YES];
    [self setCardCheck:YES];
    [self setCaptureDate:[NSDate date]];
    return stateDictionary;
}

- (NSMutableDictionary*) captureCurrentState:(NSMutableDictionary*)aDictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
        
    [aDictionary setObject:objDictionary forKey:@"KatrinModel"];
    return aDictionary;
}


//a highly hardcoded config checker. Assumes things like only one crate, ect.
- (BOOL) preRunChecks
{

	[focalPlaneSegments makeObjectsPerformSelector:@selector(clearSegmentError)];
	[vetoSegments makeObjectsPerformSelector:@selector(clearSegmentError)];
	

    NSMutableDictionary* newDictionary  = [[self document] captureCurrentState: [NSMutableDictionary dictionary]];
    NSDictionary* oldDictionary         = [NSDictionary dictionaryWithContentsOfFile:[CapturePListFile stringByExpandingTildeInPath]];
    
    [problemArray release];
    problemArray = [[NSMutableArray array]retain];
    // --crate presence must be same
    // --number of cards must match
    // --slots must match
    
    //init the checks to 'unknown'
    [self setHardwareCheck:2];
    [self setCardCheck:2];
    
    NSDictionary* newCrateDictionary = [newDictionary objectForKey:@"crate 0"];
    NSDictionary* oldCrateDictionary = [oldDictionary objectForKey:@"crate 0"];
    if(!newCrateDictionary  && oldCrateDictionary){
        [self setHardwareCheck:NO];
        [problemArray addObject:@"Crate has been removed\n"];
    }
    if(!oldCrateDictionary  && newCrateDictionary){
        [self setHardwareCheck:NO];
        [problemArray addObject:@"Crate has been added\n"];
    }
    if(newCrateDictionary && oldCrateDictionary && ![[newCrateDictionary objectForKey:@"count"] isEqualToNumber:[oldCrateDictionary objectForKey:@"count"]]){
        [self setHardwareCheck:NO];
        [problemArray addObject:@"Card count is different\n"];
    }
    
    //first scan for the cards    
    NSArray* newCardKeys = [newCrateDictionary allKeys];        
    NSArray* oldCardKeys = [oldCrateDictionary allKeys];
    NSEnumerator* eNew =  [newCardKeys objectEnumerator];
    id newCardKey;
    while( newCardKey = [eNew nextObject]){ 
        //loop over all cards, comparing old card records to new ones.
        id newCardRecord = [newCrateDictionary objectForKey:newCardKey];
        if(![[newCardRecord class] isSubclassOfClass:NSClassFromString(@"NSDictionary")])continue;
        NSEnumerator* eOld =  [oldCardKeys objectEnumerator];
        id oldCardKey;
        //grab some objects that we'll use more than once below
		NSString* slotKey = @"slot";
		if( ![newCardRecord objectForKey:slotKey]) slotKey = @"station";             
        NSNumber* newSlot           = [newCardRecord objectForKey:slotKey];

        while( oldCardKey = [eOld nextObject]){ 
            id oldCardRecord = [oldCrateDictionary objectForKey:oldCardKey];
            if(![[oldCardRecord class] isSubclassOfClass:NSClassFromString(@"NSDictionary")])continue;
			NSNumber* oldSlot           = [oldCardRecord objectForKey:slotKey];

            if(newSlot && oldSlot && [newSlot isEqualToNumber:oldSlot]){
				[self checkCardOld:oldCardRecord new:newCardRecord   check:@selector(setCardCheckFailed) exclude:[NSSet setWithObjects:@"thresholdAdcs",nil]];
                //found a card so we are done.
                break;
			}
        }
    }
    
    BOOL passed = YES;
    if(hardwareCheck == 2) [self setHardwareCheck:YES];
    else if(hardwareCheck == 0){
        NSLogColor([NSColor redColor],@"Failed Hardware Config Check\n");
        passed = NO;
    }
    
    if(cardCheck == 2)[self setCardCheck:YES];
    else if(cardCheck == 0){
        NSLogColor([NSColor redColor],@"Failed Shaper Config Check\n");
        passed = NO;
    }
            
    if(passed)NSLog(@"Passed Configuration Checks\n");
    else {
        NSEnumerator* e = [problemArray objectEnumerator];
        id s;
        if([problemArray count]){
            NSLog(@"Configuration Check Problem Summary\n");
            while(s = [e nextObject]) NSLog(s);
            NSLog(@"\n");
        }
    }
	[[NSNotificationCenter defaultCenter] postNotificationName:KatrinDisplayUpdatedNeeded object:self];

    return passed;
}

- (void) printProblemSummary
{
    [self preRunChecks];
}

- (void) setSegmentErrorClassName:(NSString*)aClassName card:(int)card channel:(int)channel
{
	int i;
	ORDetectorSegment* aSegment;
	for(i=0;i<numFocalPlaneSegments;i++){
		aSegment = [focalPlaneSegments objectAtIndex:i];
		if([[aSegment hardwareClassName] isEqualToString:aClassName] && [aSegment cardSlot] == card && [aSegment channel] == channel){
			[aSegment setSegmentError];
		}
	}
	for(i=0;i<numVetoSegments;i++){
		aSegment = [vetoSegments objectAtIndex:i];
		if([[aSegment hardwareClassName] isEqualToString:aClassName] && [aSegment cardSlot] == card && [aSegment channel] == channel){
			[aSegment setSegmentError];
		}
	}
}

- (void) initHardware
{
	//collect all the hardware cards involved...
	NSMutableArray* cards = [NSMutableArray array];
	ORDetectorSegment* aSegment;
	NSEnumerator* e = [focalPlaneSegments objectEnumerator];
	while(aSegment = [e nextObject]){
		id<ORAdcInfoProviding> card = [aSegment hardwareCard];
		if(card && ![cards containsObject:card]){
			[cards addObject:card];
		}
	}
	e = [vetoSegments objectEnumerator];
	while(aSegment = [e nextObject]){
		id<ORAdcInfoProviding> card = [aSegment hardwareCard];
		if(card && ![cards containsObject:card]){
			[cards addObject:card];
		}
	}

	@try {
		[cards makeObjectsPerformSelector:@selector(initBoard)];
		NSLog(@"Katrin Focal Plane and Veto Adc cards inited\n");
	}
	@catch (NSException * e) {
		NSLog(@"Katrin Focal Plane and Veto Adc cards init failed\n");
	}
}

@end

@implementation KatrinModel (private)
- (void) makeFocalPlaneSegments
{
	if(!focalPlaneSegments){
		focalPlaneSegments = [[NSMutableArray array] retain];
		int i;
		for(i=0;i<numFocalPlaneSegments;i++){
			ORDetectorSegment* aSegment = [[ORDetectorSegment alloc] init];
			[focalPlaneSegments addObject:aSegment];
			[aSegment setSegmentNumber:[focalPlaneSegments indexOfObject:aSegment]];
			[aSegment release];
		}
	}
}

- (void) makeVetoSegments
{
	if(!vetoSegments){
		vetoSegments = [[NSMutableArray array] retain];
		int i;
		for(i=0;i<numVetoSegments;i++){
			ORDetectorSegment* aSegment = [[ORDetectorSegment alloc] init];
			[vetoSegments addObject:aSegment];
			[aSegment setSegmentNumber:[vetoSegments indexOfObject:aSegment]];
			[aSegment release];
		}
	}
}

- (void) checkCardOld:(NSDictionary*)oldRecord new:(NSDictionary*)newRecord  check:(SEL)checkSelector exclude:(NSSet*)exclusionSet
{
    NSEnumerator* e = [oldRecord keyEnumerator];
    id aKey;
	NSString* slotKey = @"slot";
	if(![oldRecord objectForKey:slotKey])slotKey = @"station";
	BOOL segmentErrorNoted = NO;
    while(aKey = [e nextObject]){
        if(![exclusionSet containsObject:aKey]){
			id oldValues = [oldRecord objectForKey:aKey];
			id newValues =  [newRecord objectForKey:aKey];
            if(![oldValues isEqualTo:newValues]){
                [self performSelector:checkSelector];
                [problemArray addObject:[NSString stringWithFormat:@"%@ slot %@ changed.\n",
                    [oldRecord objectForKey:@"Class Name"],
                    [oldRecord objectForKey:slotKey], aKey]];
                
                [problemArray addObject:[NSString stringWithFormat:@"%@ (at least one changed):\noldValues:%@\nnewValues:%@\n",aKey,oldValues,newValues]];
				
				if(!segmentErrorNoted){
					segmentErrorNoted = YES;
					int numChannels = [newValues count];
					int channel;
					for(channel = 0;channel<numChannels;channel++){
						id newValue = [newValues objectAtIndex:channel];
						id oldValue = [oldValues objectAtIndex:channel];
						if(![newValue  isEqualTo: oldValue ]){
							int card = [[oldRecord objectForKey:slotKey] intValue];
							[self setSegmentErrorClassName:[oldRecord objectForKey:@"Class Name"] card:card channel:channel];
						}
					}
				}
            }
        }
    }
}

- (void) delayedHistogram
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedHistogram) object:nil];
	memset(focalPlaneThresholdHistogram,0,sizeof(int) * 1000);
	memset(focalPlaneGainHistogram,0,sizeof(int) * 1000);
	memset(vetoThresholdHistogram,0,sizeof(int) * 1000);
	memset(vetoGainHistogram,0,sizeof(int) * 1000);
	
	int i;
	for(i=0;i<numFocalPlaneSegments;i++){
		if([[focalPlaneSegments objectAtIndex:i] hwPresent]){
			int thresholdValue = (int)[self getFocalPlaneThreshold:i];
			if(thresholdValue>=0 && thresholdValue<1000)focalPlaneThresholdHistogram[thresholdValue]++;
			int gainValue = (int)[self getFocalPlaneGain:i];
			if(gainValue>=0 && gainValue<1000)focalPlaneGainHistogram[gainValue]++;
		}
	}
	for(i=0;i<numVetoSegments;i++){
		if([[vetoSegments objectAtIndex:i] hwPresent]){
			int thresholdValue = (int)[self getVetoThreshold:i];
			if(thresholdValue>=0 && thresholdValue<1000)vetoThresholdHistogram[thresholdValue]++;
			int gainValue = (int)[self getVetoGain:i];
			if(gainValue>=0 && gainValue<1000)vetoGainHistogram[gainValue]++;
		}
	}
	scheduledToHistogram = NO;

    [[NSNotificationCenter defaultCenter]
        postNotificationName:KatrinDisplayHistogramsUpdated
                      object:self];

}


@end

