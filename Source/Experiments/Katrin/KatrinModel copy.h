//
//  KatrinModel.h
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//

#pragma mark ¥¥¥Imported Files
#import "ORDataTaker.h"

#define numFocalPlaneSegments	145
#define numRings				 12
#define numSegmentsPerRing		 12
#define numVetoSegments			 64

#define kDefaultFocalPlaneMap @"~/FocalPlaneMap"
#define kDefaultVetoMap		  @"~/VetoMap"

@class ORDataPacket;
@class ORTimeRate;

@interface KatrinModel :  OrcaObject
{
    @private
        NSDictionary*			xAttributes;
        NSDictionary*			yAttributes;
        int hardwareCheck;
        int cardCheck;
        NSDate* captureDate;
        NSMutableArray* problemArray;
        ORAlarm*    failedHardwareCheckAlarm;
        ORAlarm*    failedCardCheckAlarm;
		BOOL replayMode;
		NSString* selectionString;
		int		displayType;
		BOOL scheduledToHistogram;
		
		//focal plane 
        NSMutableDictionary*	colorAxisFocalPlaneAttributes;
		int				focalPlaneThresholdHistogram[1000];
		int				focalPlaneGainHistogram[1000];
		NSMutableArray* focalPlaneSegments;
		NSString*		focalPlaneAdcClassName;
		NSString*		focalPlaneMapFile;
		float			focalPlaneRate;
		ORTimeRate*		focalPlaneTotalRate;

		//veto
        NSMutableDictionary*	colorAxisVetoAttributes;
		int				vetoThresholdHistogram[1000];
		int				vetoGainHistogram[1000];
		NSMutableArray* vetoSegments;
		NSString*		vetoAdcClassName;
		NSString*		vetoMapFile;
		float			vetoRate;
		ORTimeRate*		vetoTotalRate;
		
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) configurationChanged:(NSNotification*)aNote;
- (void) runStatusChanged:(NSNotification*)aNote;
- (void) registerForRates;

#pragma mark ¥¥¥Accessors
- (void) compileHistograms;
- (int) displayType;
- (void) setDisplayType:(int)aDisplayType;
- (NSString*) selectionString;
- (void) setSelectionString:(NSString*)aSelectionString;
- (BOOL) replayMode;
- (void) setReplayMode:(BOOL)aReplayMode;
- (NSDictionary*)   xAttributes;
- (void) setYAttributes:(NSDictionary*)someAttributes;
- (NSDictionary*)   yAttributes;
- (void) setXAttributes:(NSDictionary*)someAttributes;
- (void) collectRates;
- (NSDate *) captureDate;
- (void) setCaptureDate: (NSDate *) aCaptureDate;
- (int) hardwareCheck;
- (void) setHardwareCheck: (int) HardwareCheck;
- (int) cardCheck;
- (void) setCardCheck: (int) cardCheck;
- (void) setCardCheckFailed;
- (void) setHardwareCheckFailed;

#pragma mark ¥¥¥Focal Plane Accessors
- (int) focalPlaneThresholdHistogram:(int) index;
- (int) focalPlaneGainHistogram:(int) index;
- (ORTimeRate*) focalPlaneTotalRate;
- (void) setFocalPlaneTotalRate:(ORTimeRate*)newTotalRate;
- (NSString*) focalPlaneMapFile;
- (void) setFocalPlaneMapFile:(NSString*)aFocalPlaneMapFile;
- (NSString*) focalPlaneAdcClassName;
- (void) setFocalPlaneAdcClassName:(NSString*)aFocalPlaneAdcClassName;
- (void) setFocalPlaneSegments:(NSMutableArray*)anArray;
- (NSMutableArray*) focalPlaneSegments;
- (BOOL) focalPlaneHWPresent:(int)aChannel;
- (BOOL) focalPlaneOnline:(int)aChannel;
- (NSMutableDictionary*) colorAxisFocalPlaneAttributes;
- (void) setColorAxisFocalPlaneAttributes:(NSMutableDictionary*)newcolorAxisFocalPlaneAttributes;
- (float) focalPlaneRate;
- (float) getFocalPlaneThreshold:(int) index;
- (float) getFocalPlaneRate:(int) index;
- (BOOL) getFocalPlaneError:(int) index;
- (void) showDialogForFocalPlaneSegment:(int)aSegment;
- (float) getFocalPlaneGain:(int) index;
- (void) focalPlaneSegementSelected:(int)index;
- (void) readFocalPlaneMap;
- (void) saveFocalPlaneMapFileAs:(NSString*)newFileName;

#pragma mark ¥¥¥Veto Accessors
- (int) vetoThresholdHistogram:(int) index;
- (int) vetoGainHistogram:(int) index;
- (ORTimeRate*) vetoTotalRate;
- (void) setVetoTotalRate:(ORTimeRate*)newTotalRate;
- (NSString*) vetoMapFile;
- (void) setVetoMapFile:(NSString*)aVetoMapFile;
- (NSString*) vetoAdcClassName;
- (void) setVetoAdcClassName:(NSString*)aVetoAdcClassName;
- (void) setVetoSegments:(NSMutableArray*)anArray;
- (NSMutableArray*) vetoSegments;
- (BOOL) vetoHWPresent:(int)aChannel;
- (BOOL) vetoOnline:(int)aChannel;
- (NSMutableDictionary*) colorAxisVetoAttributes;
- (void) setColorAxisVetoAttributes:(NSMutableDictionary*)newColorAxisVetoAttributes;
- (float) vetoRate;
- (float) getVetoRate:(int) index;
- (float) getVetoThreshold:(int) index;
- (float) getVetoGain:(int) index;
- (BOOL) getVetoError:(int) index;
- (void) showDialogForVetoSegment:(int)aSegment;
- (void) readVetoMap;
- (void) saveVetoMapFileAs:(NSString*)newFileName;
- (void) vetoSegementSelected:(int)index;



- (NSMutableDictionary*) captureState;
- (NSMutableDictionary*) captureCurrentState:(NSMutableDictionary*)aDictionary;
- (BOOL) preRunChecks;
- (void) printProblemSummary;

- (void) runAboutToStart:(NSNotification*)aNote;
- (void) runAboutToEnd:(NSNotification*)aNote;
- (void) setSegmentErrorClassName:(NSString*)aClassName card:(int)card channel:(int)channel;

- (void) initHardware;

#pragma mark ¥¥¥Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* KatrinCollectedRates;
extern NSString* KatrinModelDisplayTypeChanged;
extern NSString* KatrinReadMapNotification;
extern NSString* KatrinModelVetoMapFileChanged;
extern NSString* KatrinModelFocalPlaneMapFileChanged;
extern NSString* KatrinModelSelectionStringChanged;
extern NSString* KatrinModelFocalPlaneAdcClassNameChanged;
extern NSString* KatrinModelVetoAdcClassNameChanged;
extern NSString* KatrinHardwareCheckChangedNotification;
extern NSString* KatrinCardCheckChangedNotification;
extern NSString* KatrinDisplayHistogramsUpdated;

extern NSString* KatrinMapLock;
extern NSString* KatrinDetectorLock;
extern NSString* KatrinDetailsLock;
extern NSString* KatrinCaptureDateChangedNotification;
extern NSString* KatrinRateAllDisableChangedNotification;
extern NSString* KatrinDisplayUpdatedNeeded;

