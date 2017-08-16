//
//  ECARun.h
//  Orca
//
//  Created by Javier Caravaca on 1/12/17.
//
//  Class that handles ECA or electronic ADC calibrations.
//

#import <Foundation/Foundation.h>

@interface ECARun : NSObject {

@private
    //ECA Variables
    int ECA_pattern;
    NSString* ECA_type;
    int ECA_tslope_pattern;
    int ECA_nevents;
    NSNumber* ECA_rate;

    //Other objects
    id anMTCModel;
    id aSNOPModel;
    NSArray *anXL3Model;
    NSArray *aFECModel;
    //Previous run
    NSString *previousSR;
    NSString *previousSRVersion;
    bool start_eca_run;
    bool start_new_run;
    int prev_coarsedelay;
    int prev_finedelay;
    uint16_t prev_pedwidth;

    //ECA thread
    NSThread *ECAThread;
    bool isFinishing;
}

- (int) ECA_pattern;
- (NSString*) ECA_type;
- (int) ECA_tslope_pattern;
- (int) ECA_nevents;
- (NSNumber*) ECA_rate;
- (double) ECA_subruntime;
- (void) setECA_pattern:(int)aValue;
- (void) setECA_type:(NSString*)aValue;
- (void) setECA_tslope_pattern:(int)aValue;
- (void) setECA_nevents:(int)aValue;
- (void) setECA_rate:(NSNumber*)aValue;
- (BOOL) isExecuting;
- (BOOL) isFinished;
- (BOOL) isFinishing;
- (void) start;
- (void) stop;
- (void) registerNotificationObservers;
- (void) setPulserRate:(NSNotification*)aNote;
- (void) launchECAThread:(NSNotification*)aNote;
- (void) doECAs;
- (BOOL) doPedestals;
- (BOOL) doTSlopes;
- (void) changePedestalMask:(NSMutableArray*)pedestal_mask;
- (BOOL) triggersOFF;
- (BOOL) triggersON;

//Notifications
extern NSString* ORECARunChangedNotification;
extern NSString* ORECARunStartedNotification;
extern NSString* ORECARunFinishedNotification;

@end
