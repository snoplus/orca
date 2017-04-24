//
//  ECARun.m
//  Orca
//
//  Created by Javier Caravaca on 1/12/17.
//
//

#import "ECARun.h"
#import "SNOPModel.h"
#import "ORMTCModel.h"
#import "ORXL3Model.h"
#import "ORFec32Model.h"
#import "ECAPatterns.h"
#import "ORMTC_Constants.h"

//Notifications
NSString* ORECARunChangedNotification = @"ORECARunChangedNotification";
NSString* ORECARunStartedNotification = @"ORECARunStartedNotification";
NSString* ORECARunFinishedNotification = @"ORECARunFinishedNotification";

//Definitions
#define ECA_COARSE_DELAY 150 //ns
#define ECA_FINE_DELAY 0 //ps
#define ECA_PEDESTAL_WIDTH 50 //ns

@implementation ECARun

- (id) init
{
    self = [super init];
    ECAThread = [[NSThread alloc] init]; //Init empty
    start_eca_run = FALSE;
    isFinishing = FALSE;
    [self registerNotificationObservers];
    return self;

}

- (void) dealloc
{
    [ECAThread release];
    [super dealloc];
}

- (void) registerNotificationObservers
{

    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(setPulserRate:)
                         name : ORRunSecondChanceForWait
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(launchECAThread:)
                         name : ORRunStartedNotification
                       object : nil];

}


- (void) start
{
    if([ECAThread isExecuting]){
        //Do nothing
        NSLogColor([NSColor redColor], @"ECA Run already ongoing!");
    }
    else{

        //Get SNO+ model
        NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
        if ([objs count]) {
            aSNOPModel = [objs objectAtIndex:0];
        } else {
            NSLogColor([NSColor redColor], @"ECARun: couldn't find SNO+ model. \n");
            return;
        }

        //Store previous runs to rollover at the end
        previousSR = [[aSNOPModel lastStandardRunType] copy];
        previousSRVersion = [[aSNOPModel lastStandardRunVersion] copy];
        start_new_run = [gOrcaGlobals runRunning];

        //Set ECA Standard Run and start run:
        /* This needs to be outside the new thread since it will
         stop/start a new run, which would cancel the thread and
         exit after the first step... */
        [aSNOPModel startStandardRun:@"ECA" withVersion:ECA_type];

        /* Enable the action of method 'launchECAThread' which
         is called when the run is about to start. This is done
         is this way since we need to ensure that the ECAThread
         is launched AFTER run stop, to not cancel the Thread. */
        start_eca_run = TRUE;

    }
}

- (void) stop
{
    /*User intervention to stop the ECA run */

    //Hold the current run until the ECAs are done
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"waiting for ECA run to finish", @"Reason",
                              nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object: self userInfo: userInfo];

    /*Set Thread to be cancelled. Only the thread itself can exit.
     This is done by checking the 'cancel' condition within the
     loop of the thread itself. */
    start_eca_run = FALSE;
    [ECAThread cancel];

}

- (BOOL) isExecuting
{
    return [ECAThread isExecuting];
}

- (BOOL) isFinished
{
    return [ECAThread isFinished];
}

- (BOOL) isFinishing
{
    return isFinishing;
}

- (void) setPulserRate:(NSNotification*)aNote
{

    if(start_eca_run){

        /* If we starting an ECA run we have to set the pulser
         rate enter by the operator, not the standard run one*/
        //MTC model
        NSArray *objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
        if ([objs count]) {
            anMTCModel = [objs objectAtIndex:0];
            [anMTCModel setPgtRate:[[self ECA_rate] floatValue]]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
            [anMTCModel loadPulserRateToHardware]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
        }
    }

}

- (void) launchECAThread:(NSNotification*)aNote
{

    if(start_eca_run){

        start_eca_run = FALSE;
        isFinishing = FALSE;

        //Launch ECA thread
        [ECAThread release];
        ECAThread = [[NSThread alloc] initWithTarget:self selector:@selector(doECAs) object:nil];
        [ECAThread start];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORECARunStartedNotification object:self];

    }

}

- (void) doECAs
{
    @autoreleasepool {

        /* Get models */
        //MTC model
        NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
        if ([objs count]) {
            anMTCModel = [objs objectAtIndex:0];
        } else {
            NSLogColor([NSColor redColor], @"ECARun: couldn't find MTC model. \n");
            goto stop;
        }

        //XL3 models
        anXL3Model = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
        if (![anXL3Model count]) {
            NSLogColor([NSColor redColor], @"ECARun: couldn't find XL3 model. \n");
            goto stop;
        }

        //FEC models
        aFECModel = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];
        if (![aFECModel count]) {
            NSLogColor([NSColor redColor], @"ECARun: couldn't find FEC model. \n");
            goto stop;
        }

        /* Disable channel triggers and stop if it fails */
        if(![self triggersOFF]){
            goto stop;
        }

        /* Get previous settings */
        prev_coarsedelay = [anMTCModel coarseDelay];
        prev_finedelay = [anMTCModel fineDelay];
        prev_pedwidth = [anMTCModel pedestalWidth];

        /* Set MTC correct settings for ECAs */
        dispatch_sync(dispatch_get_main_queue(), ^{
            [anMTCModel stopMTCPedestalsFixedRate];
            [anMTCModel setCoarseDelay:ECA_COARSE_DELAY]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
            [anMTCModel loadCoarseDelayToHardware]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
            [anMTCModel setFineDelay:ECA_FINE_DELAY]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
            [anMTCModel loadFineDelayToHardware]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
            [anMTCModel setPedestalWidth:ECA_PEDESTAL_WIDTH]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
            [anMTCModel loadPedWidthToHardware]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
        });

        NSLog(@"************************* \n");
        NSLog(@"Starting ECA Run \n");
        NSLog(@"------------------------- \n");
        NSLog(@" Events per cell: %d \n", ECA_nevents);
        NSLog(@" Pattern: %d \n", ECA_pattern);
        NSLog(@" TSlope: %d \n", ECA_tslope_pattern);
        NSLog(@" Type: %@ \n", ECA_type);
        NSLog(@" Rate: %@ \n", ECA_rate);
        NSLog(@" SubRun Time: %f seconds \n", [self ECA_subruntime]);
        NSLog(@"************************* \n");

        //Do ECAs
        if([ECA_type isEqualToString:@"PDST"]){
            /*Check whether PED EXT bit is enabled. Otherwise the GT will latch the 10MHz
             clock and cause a 20ns uncertainty in the TAC measurements*/
            if(([anMTCModel gtMask] & MTC_EXT_8_MASK) || !([anMTCModel gtMask] & MTC_PULSE_GT_MASK)){
                NSLogColor([NSColor redColor], @" Enable PGT and disable EXT PED bit in the MTC trigger mask. Stopping ECAs... \n");
                goto stop;
            }

            if(![self doPedestals]) {
                // User stopped manually
                start_new_run = false;
                goto stop;
            }
        }
        else if([ECA_type isEqualToString:@"TSLP"]){

            /*Check whether PED EXT bit is enabled. Otherwise the GT will latch the 10MHz
             clock and cause a 20ns uncertainty in the TAC measurements*/
            if(!([anMTCModel gtMask] & MTC_EXT_8_MASK)){
                NSLogColor([NSColor redColor], @" Enable EXT PED bit in the MTC trigger mask. Stopping ECAs... \n");
                goto stop;
            }

            if(![self doTSlopes]) {
                // User stopped manually
                start_new_run = false;
                goto stop;
            }
        }
        else{
            NSLogColor([NSColor redColor],@"Unknown ECA type: %@ \n",ECA_type);
            goto stop;
        }

    stop:

        isFinishing = TRUE;
        NSLog(@"************************* \n");
        NSLog(@"Finishing ECA Run \n");
        NSLog(@"************************* \n");

        //Unset settings
        dispatch_sync(dispatch_get_main_queue(), ^{
            [aSNOPModel zeroPedestalMasks];
            [anMTCModel setCoarseDelay:prev_coarsedelay]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
            [anMTCModel loadCoarseDelayToHardware]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
            [anMTCModel setFineDelay:prev_finedelay]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
            [anMTCModel loadFineDelayToHardware]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
            [anMTCModel setPedestalWidth:prev_pedwidth]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
            [anMTCModel loadPedWidthToHardware]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
        });

        //Turn triggers back ON
        if(![self triggersON]){
            NSLogColor([NSColor redColor], @"*************************************************** \n");
            NSLogColor([NSColor redColor], @" Some triggers couldn't be enabled: The GUI status  \n");
            NSLogColor([NSColor redColor], @" might not show the real state of the detector      \n");
            NSLogColor([NSColor redColor], @"*************************************************** \n");
            start_new_run = FALSE;
        }

        //Rollover to previous run, if any. Otherwise stop run.
        if(start_new_run){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];
                [aSNOPModel startStandardRun:previousSR withVersion:previousSRVersion];
                [[NSNotificationCenter defaultCenter] postNotificationName:ORECARunFinishedNotification object:self];
                //Don't leak memory
                [previousSR release];
                [previousSRVersion release];
            });
        } else{
            dispatch_sync(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];
                if(![ECAThread isCancelled]) [aSNOPModel stopRun]; //no user intervention -> we need to stop the run
                [[NSNotificationCenter defaultCenter] postNotificationName:ORECARunFinishedNotification object:self];
                //Don't leak memory
                [previousSR release];
                [previousSRVersion release];
            });
        }

    }//end autoreleasepool

}

- (BOOL) doPedestals
{

    NSLog(@"Starting ECA Pedestal Run... \n");

    unsigned long coarse_delay = [anMTCModel coarseDelay];
    unsigned long fine_delay = [anMTCModel fineDelay];
    unsigned long pedestal_width = [anMTCModel pedestalWidth];

    //EPED headers
    [aSNOPModel updateEPEDStructWithCoarseDelay:coarse_delay fineDelay:fine_delay chargePulseAmp:0x0 pedestalWidth:pedestal_width calType:10 + (ECA_pattern+1)];

    //Inject pedestals
    int eca_pattern_num_steps = getECAPatternNSteps(ECA_pattern);
    NSMutableArray* pedestal_mask = getECAPattern(ECA_pattern);
    if (pedestal_mask == nil) {
        NSLogColor([NSColor redColor], @"ECA: Error loading pedestal mask for pattern: %d \n", ECA_pattern);
        return false;
    }
    else if([pedestal_mask count] == 0){
        [pedestal_mask release];
        NSLogColor([NSColor redColor], @"ECA: Error loading pedestal mask for pattern: %d \n", ECA_pattern);
        return false;
    }

    for (int step=0; step < eca_pattern_num_steps; step++) {

        NSLog(@"************************* \n");
        NSLog(@"ECA Pedestals: STEP %d/%d \n",step+1,eca_pattern_num_steps);
        NSLog(@"************************* \n");
        //Update Pedestal mask
        [self changePedestalMask:[pedestal_mask objectAtIndex:step]];

        [aSNOPModel updateEPEDStructWithStepNumber:step];

        //Ship EPED Headers
        dispatch_sync(dispatch_get_main_queue(), ^{
            [aSNOPModel shipEPEDRecord];
        });

        //Fire pedestals at the pulser rate during a time=sub_run_time
        dispatch_sync(dispatch_get_main_queue(), ^{
            [anMTCModel continueMTCPedestalsFixedRate];
        });
        usleep([self ECA_subruntime] * 1e6);

        //End of sub-run
        dispatch_sync(dispatch_get_main_queue(), ^{
            [anMTCModel stopMTCPedestalsFixedRate];
        });

        //Check if user has cancelled ECAs and quit in that case
        if([ECAThread isCancelled]) {
            NSLog(@"ECA cancelled by user... \n");
            start_eca_run = FALSE;
            [pedestal_mask release];
            return false;
        }

    } // end ECA steps

    //OK run
    [pedestal_mask release];
    return true;

}

- (BOOL) doTSlopes
{
    NSLog(@"Starting ECA TSlope Run... \n");

    unsigned long coarse_delay = [anMTCModel coarseDelay];
    unsigned long fine_delay = [anMTCModel fineDelay];
    unsigned long pedestal_width = [anMTCModel pedestalWidth];

    //Get time delays
    const int tslope_nsteps = 50; //Hardcoded to 50 for the time being
    NSMutableArray *tslope_delays_coarse = [[[NSMutableArray alloc] initWithCapacity:tslope_nsteps] autorelease];
    NSMutableArray *tslope_delays_fine = [[[NSMutableArray alloc] initWithCapacity:tslope_nsteps] autorelease];
    for (int ipoint=0; ipoint<tslope_nsteps; ipoint++) {
        [tslope_delays_coarse addObject:[NSNumber numberWithInt:ipoint*10 + 10]];
        [tslope_delays_fine addObject:[NSNumber numberWithInt:0]];
    }

    //EPED headers
    [aSNOPModel updateEPEDStructWithCoarseDelay:coarse_delay fineDelay:fine_delay chargePulseAmp:0x0 pedestalWidth:pedestal_width calType:20 + (ECA_pattern+1)];

    //Inject pedestals
    int eca_pattern_num_steps = getECAPatternNSteps(ECA_pattern);
    NSMutableArray* pedestal_mask = getECAPattern(ECA_pattern);
    if (pedestal_mask == nil) {
        NSLogColor([NSColor redColor], @"ECA: Error loading pedestal mask for pattern: %d \n", ECA_pattern);
        return false;
    }
    else if([pedestal_mask count] == 0){
        [pedestal_mask release];
        NSLogColor([NSColor redColor], @"ECA: Error loading pedestal mask for pattern: %d \n", ECA_pattern);
        return false;
    }

    @try{
        for (int step=0; step < eca_pattern_num_steps; step++) {

            //Update Pedestal mask
            [self changePedestalMask:[pedestal_mask objectAtIndex:step]];

            for (int ipoint=0; ipoint<tslope_nsteps; ipoint++) {

                [aSNOPModel updateEPEDStructWithStepNumber:step];

                unsigned long current_coarse_delay = [[tslope_delays_coarse objectAtIndex:ipoint] unsignedLongValue];
                unsigned long current_fine_delay = [[tslope_delays_fine objectAtIndex:ipoint] unsignedLongValue];
                NSLog(@"************************* \n");
                NSLog(@"ECA TSlope: STEP %d/%d - Point %d/%d \n",step+1,eca_pattern_num_steps, ipoint+1,tslope_nsteps);
                NSLog(@"------------------------- \n");
                NSLog(@" Coarse delay: %d\n",current_coarse_delay);
                NSLog(@" Fine delay: %d\n",current_fine_delay);
                NSLog(@"************************* \n");

                dispatch_sync(dispatch_get_main_queue(), ^{
                    [anMTCModel setCoarseDelay:current_coarse_delay]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
                    [anMTCModel loadCoarseDelayToHardware]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
                    [anMTCModel setFineDelay:current_fine_delay]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
                    [anMTCModel loadFineDelayToHardware]; //UNCOMMENT THIS LINE BEFORE COMMISSIONING
                });

                [aSNOPModel updateEPEDStructWithCoarseDelay:current_coarse_delay fineDelay:current_fine_delay chargePulseAmp:0x0 pedestalWidth:pedestal_width calType:20 + (ECA_pattern+1)];

                //Ship EPED Headers
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [aSNOPModel shipEPEDRecord];
                });

                //Fire pedestals at the pulser rate during a time=sub_run_time
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [anMTCModel continueMTCPedestalsFixedRate];
                });
                usleep([self ECA_subruntime] * 1e6);

                //End of sub-run
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [anMTCModel stopMTCPedestalsFixedRate];
                });

                //Check if user has cancelled ECAs and quit in that case
                if([ECAThread isCancelled]) {
                    NSLog(@"ECA cancelled by user... \n");
                    //Don't leak memory
                    [pedestal_mask release];
                    return false;
                }

            }

        } // end ECA steps
    }
    @catch(...){
        //Don't leak memory
        [pedestal_mask release];
        return false;
    }

    [pedestal_mask release];

    //OK run
    return true;

}

- (void) changePedestalMask:(NSMutableArray*)pedestal_mask
{

    //Set pedestal mask in FEC: this does not load it yet
    for (ORFec32Model *fec in aFECModel) {
        int crate_number = [fec crateNumber];
        if(crate_number == 19) crate_number = 0; //hack for the teststand
        int card_number = [fec stationNumber];
        int mask = [[[pedestal_mask objectAtIndex:crate_number] objectAtIndex:card_number] intValue];
        //NSLog(@"PEDESTAL MASK: %d, %d, %x \n",crate_number,card_number,mask);
        dispatch_async(dispatch_get_main_queue(), ^{
            [fec setPedEnabledMask:mask];
        });
    }

    //Load pedestal mask
    for (ORXL3Model *xl3 in anXL3Model) {
        //NSLog(@"Set pedestal for XL3 %d \n", [xl3 crateNumber]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [xl3 setPedestalInParallel];
        });
    }

    //Check the pedestal mask changes have finished
    for (ORXL3Model *xl3 in anXL3Model) {
        NSDate* aDate = [[NSDate alloc] init];
        while ([xl3 changingPedMask]) {
            usleep(1e3); //sleep 1ms
            //Timeout after 3s
            if ([aDate timeIntervalSinceNow] < -3) {
                NSLogColor([NSColor redColor], @" Pedestal mask couldn't change. \n");
            }
        }
        [aDate release];
    }

}

- (BOOL) triggersOFF
{
    BOOL triggersSetOK = TRUE;

    for (ORXL3Model *xl3 in anXL3Model) {
        if([[xl3 xl3Link] isConnected]){
            @try {
                [xl3 disableTriggers];
            }
            @catch (NSException *exception) {
                NSLogColor([NSColor redColor], @"ECA: triggers could not be disabled for crate %d \n",[xl3 crateNumber]);
                triggersSetOK = FALSE;
            }
        }
        else{
            NSLog(@"ECA: triggers could not be disabled for crate %d because XL3 is not connected\n",[xl3 crateNumber]);
        }
    }
    return triggersSetOK;
}

- (BOOL) triggersON
{
    BOOL triggersSetOK = TRUE;

    for (ORXL3Model *xl3 in anXL3Model) {
        if([[xl3 xl3Link] isConnected]){
            @try {
                [xl3 loadTriggers];
            }
            @catch (NSException *exception) {
                NSLogColor([NSColor redColor], @"ECA: triggers could not be enabled for crate %d \n",[xl3 crateNumber]);
                triggersSetOK = FALSE;
            }
        }
        else{
            NSLog(@"ECA: triggers could not be enabled for crate %d because XL3 is not connected\n",[xl3 crateNumber]);
        }
    }
    return triggersSetOK;
}

- (double)ECA_subruntime
{
    return (double)ECA_nevents*16/[ECA_rate doubleValue];
}

- (int)ECA_pattern
{
    return ECA_pattern;
}

- (void) setECA_pattern:(int)aValue
{
    ECA_pattern = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORECARunChangedNotification object:self];
}

- (NSString*)ECA_type
{
    return [NSString stringWithFormat:@"%@",ECA_type];
}

- (void) setECA_type:(NSString*)aValue
{
    if(aValue != ECA_type)
    {
        NSString* temp = ECA_type;
        ECA_type = [aValue retain];
        [temp release];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORECARunChangedNotification object:self];
    }
}

- (int)ECA_tslope_pattern
{
    return ECA_tslope_pattern;
}

- (void) setECA_tslope_pattern:(int)aValue
{
    ECA_tslope_pattern = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORECARunChangedNotification object:self];
}

- (int)ECA_nevents
{
    return ECA_nevents;
}

- (void) setECA_nevents:(int)aValue
{
    if(aValue <= 0) aValue = 1;
    ECA_nevents = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORECARunChangedNotification object:self];
}

- (NSNumber*)ECA_rate
{
    return ECA_rate;
}

- (void) setECA_rate:(NSNumber*)aValue
{
    if(aValue != ECA_rate){

        NSNumber* temp = ECA_rate;

        double new_ECA_rate = [aValue doubleValue];
        NSNumber* ECA_rate_limit = [[NSNumber alloc] initWithDouble:1000.];

        if([aValue doubleValue] < 1){
            new_ECA_rate = 1;
            NSLogColor([NSColor redColor], @" ECA: Pulser rate should be greater than 1. \n");
        }
        else if([aValue doubleValue] > [ECA_rate_limit doubleValue]){
            new_ECA_rate = [ECA_rate_limit doubleValue];
            NSLogColor([NSColor redColor], @" ECA: Not allowed to go above 1kHz. \n");
        }

        ECA_rate = [[NSNumber alloc] initWithDouble:new_ECA_rate];
        [ECA_rate_limit release];
        [temp release];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORECARunChangedNotification object:self];
    }
}


@end
