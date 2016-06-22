//
//  ORRunningAverageGroup
//  Orca
//
//  Created by Wenqin on 5/16/16.
//
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

@class ORRunningAverage;

@interface ORRunningAverageGroup : NSObject {
    bool PrintMymessages;
    NSMutableArray* runningAverages;
    double integrationTime;
    int windowLength;
    int tag;
    int sampled;
    int groupSize;
    float threshold;
    bool triggerOnRatio;
    bool globalSpiked;
    //non-persistant variables
    id objectKeepingRate;
    NSMutableArray* currentRates;
    NSMutableArray* spikes;
//    ORRunningAverage* runAverage;
}
#pragma mark •••Initialization
- (id) initGroup:(int)numberInGroup groupTag:(int)aGroupTag withLength:(int)wl;

#pragma mark •••Accessors
- (id) runningAverageObject:(short)index;
- (NSArray*) runningAverages;
- (NSArray*) getRunningAverageValues; //float array
- (void) setRunningAverages:(NSMutableArray*)newRAs;
- (void) updateWindowLength:(int)newWindowLength;
- (void) setWindowLength:(int)newWindowLength;
- (int) windowLength;
- (void) resetCounters:(float)rate;
- (void) updateRunningAverages:(NSArray*)newdatapoints; //newdatapoints must be array of NSNumbers of float
- (double) integrationTime;
- (void) setIntegrationTime:(double)newIntegrationTime;
- (int)  tag;
- (void) setTag:(int)newTag;
- (int) groupSize;
- (void) setGroupSize:(int)a;
- (void) setSampled:(int)a;
- (int) sampled;
- (void) setPrintMymessages:(bool)b;
- (void) calcRunningAverages;
- (float)getRunningAverageValue:(short)idx; 
- (NSArray*) spikes; //float array
- (void) setSpikes:(NSMutableArray*)newarray;
- (NSArray*) currentRates; //float array
- (void) setCurrentRates:(NSMutableArray*)newarray;
- (void) setTriggerOnRatio: (bool)b;
- (bool) triggerOnRatio;
- (void) setThreshold:(float)a;
- (float) threshold;
-(BOOL) globalSpiked;
- (void) setGlobalSpiked:(BOOL)b;
- (void) start:(id)obj; //obj must provide an array of instant values in the [getRates:Grouptag] method
- (void) quit;
- (void) stop;


@end

extern NSString* ORRunningAverageChangedNotification;


@interface NSObject (ORRunningAverageGroup_Catagory)
- (NSArray*) getRates:(int)aGroupTag;
@end






