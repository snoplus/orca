//
//  MajoranaModel.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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

#pragma mark ¥¥¥Imported Files
#import "MajoranaModel.h"
#import "MajoranaController.h"
#import "ORSegmentGroup.h"
#import "ORDetectorSegment.h"
#import "ORMJDSegmentGroup.h"
#import "ORRemoteSocketModel.h"
#import "SynthesizeSingleton.h"
#import "ORMPodCrateModel.h"
#import "ORiSegHVCard.h"
#import "ORAlarm.h"
#import "ORTimeRate.h"
#import "ORMJDInterlocks.h"
#import "ORVME64CrateModel.h"
#import "ORMJDSource.h"
#import "ORDataProcessing.h"
#import "ORGretina4MModel.h"
#import "ORMJDPreAmpModel.h"
#import "ORRunningAverage.h"
#import "OROnCallListModel.h"
#import "ORRunModel.h"
#import "ORCouchDBModel.h"

NSString* MajoranaModelIgnorePanicOnBChanged            = @"MajoranaModelIgnorePanicOnBChanged";
NSString* MajoranaModelIgnorePanicOnAChanged            = @"MajoranaModelIgnorePanicOnAChanged";
NSString* MajoranaModelIgnoreBreakdownPanicOnAChanged   = @"MajoranaModelIgnoreBreakdownPanicOnAChanged";
NSString* MajoranaModelIgnoreBreakdownPanicOnBChanged   = @"MajoranaModelIgnoreBreakdownPanicOnBChanged";
NSString* MajoranaModelIgnoreBreakdownCheckOnAChanged   = @"MajoranaModelIgnoreBreakdownCheckOnAChanged";
NSString* MajoranaModelIgnoreBreakdownCheckOnBChanged   = @"MajoranaModelIgnoreBreakdownCheckOnBChanged";
NSString* ORMajoranaModelViewTypeChanged                = @"ORMajoranaModelViewTypeChanged";
NSString* ORMajoranaModelPollTimeChanged                = @"ORMajoranaModelPollTimeChanged";
NSString* ORMJDAuxTablesChanged                         = @"ORMJDAuxTablesChanged";
NSString* ORMajoranaModelLastConstraintCheckChanged     = @"ORMajoranaModelLastConstraintCheckChanged";
NSString* ORMajoranaModelUpdateSpikeDisplay             = @"ORMajoranaModelUpdateSpikeDisplay";
NSString* ORMajoranaModelMaxNonCalibrationRate          = @"ORMajoranaModelMaxNonCalibrationRate";

static NSString* MajoranaDbConnector		= @"MajoranaDbConnector";

#define MJDStringMapFile(aPath)		[NSString stringWithFormat:@"%@_StringMap",	aPath]
#define MJDSpecialMapFile(aPath)    [NSString stringWithFormat:@"%@_SpecialMap",aPath]

@interface  MajoranaModel (private)
- (void)     checkConstraints;
- (void)     validateStringMap;
- (void)     validateSpecialMap;
- (NSArray*) linesInFile:(NSString*)aPath;
@end

@implementation MajoranaModel

#pragma mark ¥¥¥Initialization
- (void) dealloc
{
    int i;
    for(i=0;i<2;i++){
        [mjdInterlocks[i] setDelegate:nil];
        [mjdInterlocks[i] stop];
        [mjdInterlocks[i] release];
        
        [rateSpikes release];
        [baselineSpikes release];
        
        [rampHVAlarm[i]   clearAlarm];
        [rampHVAlarm[i]   release];
        
        [breakdownAlarm[i]   clearAlarm];
        [breakdownAlarm[i]   release];

        [mjdSource[i] setDelegate:nil];
        [mjdSource[i] release];
        
    }
    
    for(i=0;i<3;i++)[scheduledToSendRateReport[i] release];
    
    [highRateChecker release];
    [anObjForCouchID release];
    [stringMap release];
    [specialMap release];
    [breakDownDictionary release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
    [self getRunType:nil];
    [super awakeAfterDocumentLoaded];
}

- (void) getRunType:(ORRunModel*)rc
{
    if(!rc){
        NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
        if([objs count]){
            runType = [[objs objectAtIndex:0] runType];
        }
        else runType = 0x0;
    }
    else {
        runType = [rc runType];
    }
}

- (void) wakeUp
{
    [super wakeUp];
	if(pollTime){
        [self checkConstraints];
	}
}

- (void) sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super sleep];
}

- (void) setUpImage {
    [self setImage:[NSImage imageNamed:@"Majorana"]];
}

- (void) makeMainController
{
    [self linkToController:@"MajoranaController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:MajoranaDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[aConnector setConnectorType: 'DB O' ];
	[aConnector addRestrictedConnectionType: 'DB I' ]; //can only connect to DB outputs
    [aConnector release];
}

//- (NSString*) helpURL
//{
//	return @"Majorana/Index.html";
//}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(hvInfoRequest:)
                         name : ORiSegHVCardRequestHVMaxValues
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(customInfoRequest:)
                         name : ORiSegHVCardRequestCustomInfo
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStarted:)
                         name : ORRunStartedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateSpike:)
                         name : ORGretina4MModelRateSpiked
                       object : nil]; //object is the sender of the notification
    
    [notifyCenter addObserver : self
                     selector : @selector(baselineSpike:)
                         name : ORMJDPreAmpModelRateSpiked
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runTypeChanged:)
                         name : ORRunTypeChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(awakeAfterDocumentLoaded)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(awakeAfterDocumentLoaded)
                         name : ORGroupObjectsRemoved
                       object : nil];


}
- (void) runStatusChanged:(NSNotification*)aNote
{
    [super runStatusChanged:aNote];
    int running     = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
    int runTypeMask = [[[aNote userInfo] objectForKey:ORRunTypeMask] intValue];
    if((running == eRunInProgress) && !(runTypeMask & 0x00010018)){
        if(!highRateChecker){
            highRateChecker = [[ORHighRateChecker alloc] init:@"Sustained High Rate" timeFrame:60*10];
        }
    }
    else if((running == eRunStopped) || (running == eRunStopping)){
        [highRateChecker release];
        highRateChecker = nil;
    }

}

- (void) runTypeChanged:(NSNotification*) aNote
{
    [self getRunType:[aNote object]];
}

- (void) runStarted:(NSNotification*) aNote
{
//    if(!anObjForCouchID) anObjForCouchID = [[ORMJDHeaderRecordID alloc] init];
//    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
//                          [anObjForCouchID fullID],                     @"name",
//                          @"MJDHeader",                                 @"title",
//                          [[aNote userInfo] objectForKey:kHeader],      kHeader,
//                          [[aNote userInfo] objectForKey:kRunNumber],   kRunNumber,
//                          [[aNote userInfo] objectForKey:kSubRunNumber],kSubRunNumber,
//                          [[aNote userInfo] objectForKey:kRunMode],     kRunMode,
//                          nil];
//
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:anObjForCouchID userInfo:info];
//
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddHistoryAdcRecord" object:anObjForCouchID userInfo:info];
}

- (void) collectRates
{
    [super collectRates];
    highRateChecker.maxValue = maxNonCalibrationRate;
    if(maxNonCalibrationRate!=0)[highRateChecker checkRate:[[self segmentGroup:0] rate]];
}

- (void) customInfoRequest:(NSNotification*)aNote
{
    if([[aNote object] isKindOfClass:NSClassFromString(@"ORiSegHVCard")]){
        ORiSegHVCard* anHVCard = [aNote object];
        id userInfo     = [aNote userInfo];
        int aCrate      = [[userInfo objectForKey:@"crate"]     intValue];
        int aCard       = [[userInfo objectForKey:@"card"]      intValue];
        int aChannel    = [[userInfo objectForKey:@"channel"]   intValue];
        BOOL foundIt    = NO;
        int aSet;
        for(aSet =0;aSet<2;aSet++){
            ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
            int numSegments = [self numberSegmentsInGroup:aSet];
            int i;
            for(i = 0; i<numSegments; i++){
                NSDictionary* params = [[segmentGroup segment:i]params];
                if(!params)break;
                if([[params objectForKey:@"kHVCrate"]intValue] != aCrate)continue;
                if([[params objectForKey:@"kHVCard"]intValue] != aCard)continue;
                if([[params objectForKey:@"kHVChan"]intValue] != aChannel)continue;
                id preAmpChan       = [params objectForKey:@"kPreAmpChan"];
                id preAmpDigitizer  = [params objectForKey:@"kPreAmpDigitizer"];
                //get here and it's a match
                if(preAmpChan && preAmpDigitizer){
                    [anHVCard setCustomInfo:aChannel string:[NSString stringWithFormat:@"PreAmp: %d,%d",[preAmpDigitizer intValue],[preAmpChan intValue]]];
                }
                foundIt = YES;
                break;
            }
        }
        if(!foundIt){
            [anHVCard setCustomInfo:aChannel string:@""];
        }
    }
}

- (void) hvInfoRequest:(NSNotification*)aNote
{
    if([[aNote object] isKindOfClass:NSClassFromString(@"ORiSegHVCard")]){
        ORiSegHVCard* anHVCard = [aNote object];
        id userInfo     = [aNote userInfo];
        int aCrate      = [[userInfo objectForKey:@"crate"]     intValue];
        int aCard       = [[userInfo objectForKey:@"card"]      intValue];
        int aChannel    = [[userInfo objectForKey:@"channel"]   intValue];
        BOOL foundIt    = NO;
        int aSet;
        for(aSet =0;aSet<2;aSet++){
            ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
            int numSegments = [self numberSegmentsInGroup:aSet];
            int i;
            for(i = 0; i<numSegments; i++){
                NSDictionary* params = [[segmentGroup segment:i]params];
                if(!params)break;
                if([[params objectForKey:@"kHVCrate"]intValue] != aCrate)continue;
                if([[params objectForKey:@"kHVCard"]intValue] != aCard)continue;
                if([[params objectForKey:@"kHVChan"]intValue] != aChannel)continue;
                id maxVoltNum = [params objectForKey:@"kMaxVoltage"];
                //get here and it's a match
                if(maxVoltNum){
                    //only if there is an entry for max voltage do we set it
                    [anHVCard setMaxVoltage:aChannel withValue:[maxVoltNum intValue] ];
                    [anHVCard setChan:aChannel name:[params objectForKey:@"kDetectorName"]];
                }
                foundIt = YES;
                break;
            }
        }
        if(!foundIt){
            [anHVCard setChan:aChannel name:@""];
            [anHVCard setMaxVoltage:aChannel withValue:0 ];
        }
    }
}

- (void) updateBreakdownDictionary:(NSDictionary*)dic
{
    if(!dic)return; //shouldn't happen, but if it does then no sense in continuing
    
    int aCrate = [[dic objectForKey:@"crate"]intValue];
    //the two Spike dicationaries come from notifications from the digitizers and the preamps.
    //They hold location info and a dictionary with the spike info. If they exist, there was an excursion in the running average
    if(baselineSpikes || rateSpikes){
        [self setupBreakDownDictionary]; //place to store a table of info for each channel with problems
    
        //have to match up the baseline and detectors. Easiest to do it in reverse and do it
        //for each detector and see if they exist in one of the spike lists
        ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:0];
        for(id item in stringMap){
            int i;
            for(i=0;i<5;i++){
                NSString* detIndexString = [item objectForKey:[@"kDet" stringByAppendingFormat:@"%d",i]];
                NSString* stringName     = [item objectForKey:@"kStringName"];
                
                if([detIndexString length]==0 || [detIndexString rangeOfString:@"-"].location!=NSNotFound)continue;
                
                int detIndex = [detIndexString intValue]*2; //x2 because the stringMap hi/low gains get expanded into a bigger table
                
                NSString* detectorName = [aGroup segment:detIndex objectForKey:@"kDetectorName"];
                if([detectorName length]==0 || [detectorName rangeOfString:@"-"].location!=NSNotFound)continue;
                
                int crate = [[aGroup segment:detIndex objectForKey:@"kVME"]intValue];
                int card  = [[aGroup segment:detIndex objectForKey:@"kCardSlot"]intValue];
                int chan  = [[aGroup segment:detIndex objectForKey:@"kChannel"]intValue];
                
                if(aCrate != crate)continue; //only worry about our crate
                
                int preAmpDig  = [[aGroup segment:detIndex objectForKey:@"kPreAmpDigitizer"]intValue];
                int preAmpChan = [[aGroup segment:detIndex objectForKey:@"kPreAmpChan"]intValue];
                
                int hvCrate     = [[aGroup segment:detIndex objectForKey:@"kHVCrate"]  intValue];
                int hvCard      = [[aGroup segment:detIndex objectForKey:@"kHVCard"]   intValue];
                int hvChannel   = [[aGroup segment:detIndex objectForKey:@"kHVChan"]   intValue];
                
                //extract the running ave excursion (spike) dictionaries
                NSString*     aChannelKey   = [NSString stringWithFormat:@"%d,%d,%d",crate,card,chan];
                NSDictionary* rateEntry     = [[rateSpikes objectForKey:aChannelKey] objectForKey:@"spikeInfo"];
                
                NSString*     aPreAmpKey    = [NSString stringWithFormat:@"%d,%d,%d",crate,preAmpDig,preAmpChan];
                NSDictionary* baseLineEntry = [[baselineSpikes objectForKey:aPreAmpKey] objectForKey:@"spikeInfo"];
                
                if(rateEntry || baseLineEntry){
                    NSMutableDictionary* detectorEntries = [breakDownDictionary objectForKey:@"detectorEntries"];
                    NSMutableDictionary* detectorEntry   = [detectorEntries objectForKey:detectorName];
                    
                    if(!detectorEntry){
                        [detectorEntries setObject:[NSMutableDictionary dictionary] forKey:detectorName];
                        detectorEntry = [detectorEntries objectForKey:detectorName];
                    }
                    
                    if(rateEntry && ![detectorEntry objectForKey:@"rateInfo"]){
                        if(![self calibrationRun:aCrate]){
                            [detectorEntry setObject:rateEntry forKey:@"rateInfo"];
                            [breakDownDictionary setObject:@"YES" forKey:@"changed"];
                            if(!scheduledToSendRateReport[aCrate]){
                                scheduledToSendRateReport[aCrate] = [[NSDate date] retain];
                                //the actual send will happen when the constraint check is finished
                            }
                        }
                    }
                    
                    if(baseLineEntry && ![detectorEntry objectForKey:@"baselineInfo"]){
                        [detectorEntry setObject:baseLineEntry forKey:@"baselineInfo"];
                        [breakDownDictionary setObject:@"YES" forKey:@"changed"];
                        if(!scheduledToSendBaselineReport){
                            scheduledToSendBaselineReport = YES;
                            [self performSelector:@selector(sendRateBaselineReport) withObject:nil afterDelay:15];
                        }
                   }
                    
                    [detectorEntry setObject:stringName                          forKey:@"stringName"];
                    [detectorEntry setObject:detectorName                        forKey:@"detectorName"];
                    [detectorEntry setObject:[NSNumber numberWithInt:hvCrate]    forKey:@"hvCard"];
                    [detectorEntry setObject:[NSNumber numberWithInt:hvCard]     forKey:@"hvCrate"];
                    [detectorEntry setObject:[NSNumber numberWithInt:hvChannel]  forKey:@"hvChannel"];
                    [detectorEntry setObject:[NSNumber numberWithInt:crate]      forKey:@"crate"];
                    [detectorEntry setObject:[NSNumber numberWithInt:card]       forKey:@"card"];
                    [detectorEntry setObject:[NSNumber numberWithInt:chan]       forKey:@"chan"];
                    [detectorEntry setObject:[NSNumber numberWithInt:hvChannel]  forKey:@"channel"];
                    [detectorEntry setObject:[NSNumber numberWithInt:preAmpDig]  forKey:@"preAmpDig"];
                    [detectorEntry setObject:[NSNumber numberWithInt:preAmpChan] forKey:@"preAmpChan"];
                    
                }
            }
        }
    }
    
    if(!rateSpikes){
        //no ratespikes exist.. remove spikes from all detectors
        NSMutableDictionary* detectorEntries = [breakDownDictionary objectForKey:@"detectorEntries"];
        for(id aKey in detectorEntries){
            NSMutableDictionary* anEntry = [detectorEntries objectForKey:aKey];
            [anEntry removeObjectForKey:@"rateInfo"];
        }
    }
    if(!baselineSpikes){
        //no baselineSpikes exist.. remove spikes from all detectors
        NSMutableDictionary* detectorEntries = [breakDownDictionary objectForKey:@"detectorEntries"];
        for(id aKey in detectorEntries){
            NSMutableDictionary* anEntry = [detectorEntries objectForKey:aKey];
            [anEntry removeObjectForKey:@"baselineInfo"];
       }
    }
    if(!rateSpikes && !baselineSpikes){
        [breakDownDictionary release];
        breakDownDictionary = nil;
    }
    //force constraint checker to run but limit how often
    if(pollTime){
        if(!scheduledToRunCheckBreakdown){
            scheduledToRunCheckBreakdown = YES;
            [self performSelector:@selector(forceConstraintCheck) withObject:nil afterDelay:15];
        }
    }
}

- (void) sendRateSpikeReportForCrate:(int)aCrate
{
    if(aCrate!=1 && aCrate!=2) return;

    if(!scheduledToSendRateReport[aCrate])return; //not scheduled at all
    
    //have to ensure that the AMI has had enough time to have polled the valve states
    NSTimeInterval dt = [[NSDate date] timeIntervalSinceDate:scheduledToSendRateReport[aCrate]];
    int lnPollingTime = [self pollingTimeForLN:aCrate-1];
    if(dt < lnPollingTime)return; //not enough time, it's OK since we'll be called again later
    
    [scheduledToSendRateReport[aCrate] release];
    scheduledToSendRateReport[aCrate] = nil;
    
    if(![self fillingLN:aCrate-1]){

        //send out text to experts
        OROnCallListModel* onCallObj = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"OROnCallListModel,1"];
        NSMutableDictionary* detectorEntries = [breakDownDictionary objectForKey:@"detectorEntries"];
        NSMutableString* report = [NSMutableString stringWithString:@""];
        for(id aKey in detectorEntries){
            NSMutableDictionary* anEntry = [detectorEntries objectForKey:aKey];
            ORRunningAveSpike* rateInfo  = [anEntry objectForKey:@"rateInfo"];
            if(rateInfo){
                int crateKey = [[anEntry objectForKey:@"crate"] intValue];
                if(crateKey != aCrate)                      continue;
                
                if(crateKey == 1 && ignoreBreakdownCheckOnB)continue;
                if(crateKey == 1 && [self fillingLN:0])     continue;
                
                if(crateKey == 2 && ignoreBreakdownCheckOnA)continue;
                if(crateKey == 2 && [self fillingLN:1])     continue;
                
                //ok, append this detector
                [report appendFormat:@"Detector: %@ (%@,%@,%@)\n",[anEntry objectForKey:@"detectorName"],[anEntry objectForKey:@"crate"],[anEntry objectForKey:@"card"],[anEntry objectForKey:@"chan"]];
                [report appendFormat:@"Ave: %.1f  Spiked: %.1f (%@ MT)\n",[rateInfo ave],[rateInfo spikeValue],[[rateInfo spikeStart] stdDescription]];
            }
        }
        //make sure there is something to send
        if([report length]>0){
            NSString* s1 = [NSString stringWithFormat:@"Rate Spikes Reported\n%@",report];
            [onCallObj broadcastMessage:s1];
        }
    }
    //don't care anymore
    NSMutableDictionary* detectorEntries = [breakDownDictionary objectForKey:@"detectorEntries"];
    for(id aKey in [detectorEntries allKeys]){
        NSMutableDictionary* anEntry = [detectorEntries objectForKey:aKey];
        ORRunningAveSpike* rateInfo  = [anEntry objectForKey:@"rateInfo"];
        if(rateInfo){
            int crateKey = [[anEntry objectForKey:@"crate"] intValue];
            if(crateKey != aCrate)                      continue;
            [anEntry removeObjectForKey:@"rateInfo"];
            if([anEntry allKeys] == 0){
                //no baseline entry either, so remove the entry all together
                [detectorEntries removeObjectForKey:aKey];
            }
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelUpdateSpikeDisplay" object:self];

}

- (void) sendRateBaselineReport
{
    scheduledToSendBaselineReport = NO;
    //send out text to experts
    OROnCallListModel* onCallObj = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"OROnCallListModel,1"];
    NSMutableDictionary* detectorEntries = [breakDownDictionary objectForKey:@"detectorEntries"];
    NSMutableString* report = [NSMutableString stringWithString:@""];
    for(id aKey in detectorEntries){
        NSMutableDictionary* anEntry = [detectorEntries objectForKey:aKey];
        ORRunningAveSpike* rateInfo  = [anEntry objectForKey:@"baselineInfo"];
        if(rateInfo){
            if([[anEntry objectForKey:@"crate"] intValue] == 1 && ignoreBreakdownCheckOnB)continue;
            if([[anEntry objectForKey:@"crate"] intValue] == 2 && ignoreBreakdownCheckOnA)continue;
            //ok, append this detector
            [report appendFormat:@"Detector: %@ (%@,%@,%@)\n",[anEntry objectForKey:@"detectorName"],[anEntry objectForKey:@"crate"],[anEntry objectForKey:@"card"],[anEntry objectForKey:@"chan"]];
            [report appendFormat:@"Ave: %.1f  Spiked: %.1f (%@ MT)\n",[rateInfo ave],[rateInfo spikeValue],[[rateInfo spikeStart] stdDescription]];
        }
    }
    //make sure there is something to send
    if([report length]>0){
        NSString* s1 = [NSString stringWithFormat:@"Baseline Excursions Reported\n%@",report];
        [onCallObj broadcastMessage:s1];
    }
    
    //don't care anymore
    for(id aKey in [detectorEntries allKeys]){
        NSMutableDictionary* anEntry = [detectorEntries objectForKey:aKey];
        ORRunningAveSpike* rateInfo  = [anEntry objectForKey:@"baselineInfo"];
        if(rateInfo){
            [anEntry removeObjectForKey:@"baselineInfo"];
            if([anEntry allKeys] == 0){
                //no rate spike entry either, so remove the entry all together
                [detectorEntries removeObjectForKey:aKey];
            }
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelUpdateSpikeDisplay" object:self];
}

- (BOOL) calibrationRun:(int)aCrate
{
    if(aCrate == 1) return runType &= (0x1<<3);
    else            return runType &= (0x1<<4);
}

- (void) forceConstraintCheck
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceConstraintCheck) object:nil];
    scheduledToRunCheckBreakdown = NO;
    [self checkConstraints];
}

- (NSString*) checkForBreakdown:(int)aCrate vacSystem:(int)aVacSystem
{
    //report, but only if something has changed
    if([breakDownDictionary objectForKey:@"changed"]){
        [breakDownDictionary removeObjectForKey:@"changed"];
        
        NSMutableString* report = [NSMutableString stringWithString:@""];
        NSDictionary* detectorEntries = [breakDownDictionary objectForKey:@"detectorEntries"];
        BOOL concerns = NO;
        for(id aDetectorKey in [detectorEntries allKeys]){
            if([self breakdownConditionsMet:aDetectorKey]){
                NSDictionary* detectorEntry   = [detectorEntries objectForKey:aDetectorKey];
                [report appendString:[self breakdownReportFor:detectorEntry]];
                concerns = YES;
            }
        }
        
        if(concerns){
            NSLog(@"%@\n",report);
            
            //send out text to experts
            OROnCallListModel* onCallObj = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"OROnCallListModel,1"];
            NSString* textMessage = [NSString stringWithFormat:@"The following problems will cause the HV to be ramped down in a few minutes on some channels\nAn Alarm has been posted. Acknowledge it to prevent the ramp down.%@",report];
            [onCallObj broadcastMessage:textMessage];

            //Post Alarm
            int alarmIndex = aCrate-1;
            if(alarmIndex>=0 && alarmIndex<2){
                if(!breakdownAlarm[alarmIndex]){
                    breakdownAlarm[alarmIndex] = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Breakdown M%d Vac%c",aCrate,'A'+aVacSystem] severity:(kEmergencyAlarm)];
                }
                
                if(![breakdownAlarm[alarmIndex] isPosted]){
                    [breakdownAlarm[alarmIndex] setSticky:NO];
                    [breakdownAlarm[alarmIndex] setHelpString:[NSString stringWithFormat:@"Suggest ramping down HV of Module %d because Vac %c spiked and event rate spiked and baseline jumped.\nAcknowledging this alarm will prevent an automatic ramp down 20 minutes after if was posted.",aCrate, 'A'+aVacSystem]];
                    [breakdownAlarm[alarmIndex] postAlarm];
                    BOOL vacSpike  = [[self mjdInterlocks:alarmIndex] vacuumSpike];
                    if(vacSpike){
                        NSLogColor([NSColor redColor], @"HV should be ramped down on Module %d because Vac %c spiked and event rate spiked and baseline jumped.\n",aCrate,
                               'A'+aVacSystem);
                    }
                    else {
                        NSLogColor([NSColor redColor],@"Event rate spiked and baseline jumped on Module %d.\n",aCrate);
                        NSLogColor([NSColor redColor],@"However there is NO vacuum spike on Vac %c\n",'A'+aVacSystem);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelUpdateSpikeDisplay" object:self];
               }
            }
        }
    }

    if(!breakDownDictionary) {
        int alarmIndex = aCrate-1;
        if(alarmIndex>=0 && alarmIndex<2){
            [breakdownAlarm[alarmIndex] clearAlarm];
            [breakdownAlarm[alarmIndex] release];
            breakdownAlarm[alarmIndex] = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelUpdateSpikeDisplay" object:self];
        }
    }
    
    [self rampDownChannelsWithBreakdown:aCrate vac:aVacSystem];
    if(breakdownAlarm[aCrate-1])    return @"Breakdown";
    else if(breakDownDictionary)    return @"Concerns";
    else                            return @"No Issues";
}

- (void) printBreakdownReport
{
    NSMutableString* report = [NSMutableString stringWithString:@""];
    NSDictionary* detectorEntries = [breakDownDictionary objectForKey:@"detectorEntries"];
    for(id aDetectorKey in [detectorEntries allKeys]){
        NSDictionary* detectorEntry   = [detectorEntries objectForKey:aDetectorKey];
        [report appendString:[self breakdownReportFor:detectorEntry]];
    }
    if([report length]){
        NSLog(@"%@\n",report);
    }
    else NSLog(@"No breakdown issues to report\n");
}

- (NSString*) breakdownReportFor:(NSDictionary*)detectorEntry
{
    NSMutableString* report = [NSMutableString stringWithString:@""];
    
    ORRunningAveSpike* rateInfo         = [detectorEntry objectForKey:@"rateInfo"];
    ORRunningAveSpike* baselineInfo     = [detectorEntry objectForKey:@"baselineInfo"];
    
    NSString* crate         = [detectorEntry objectForKey:@"crate"];
    NSString* card          = [detectorEntry objectForKey:@"card"];
    NSString* chan          = [detectorEntry objectForKey:@"chan"];
    NSString* preAmpDig     = [detectorEntry objectForKey:@"preAmpDig"];
    NSString* preAmpChan    = [detectorEntry objectForKey:@"preAmpChan"];
    
    NSString* stringName    = [detectorEntry objectForKey:@"stringName"];
    NSString* detectorName  = [detectorEntry objectForKey:@"detectorName"];
    
    if(rateInfo){
        [report appendFormat:@"\nRate Spike on %@ string: %@\n",detectorName,stringName];
        [report appendFormat:@"Digitizer Crate: %@ Card: %@ Chan: %@\n",crate,card,chan];
        [report appendFormat:@"Spike detected at: %@\n",[[rateInfo spikeStart]stdDescription]];
        [report appendFormat:@"Ave Rate: %.3f  Spike Rate: %.3f\n",rateInfo.ave,rateInfo.spikeValue];
    }
    
    if(baselineInfo){
        [report appendFormat:@"\nBaseline jump on %@ string: %@\n",detectorName,stringName];
        [report appendFormat:@"Crate: %@ PreAmp Digitizer: %@ PreAmp Chan: %@\n",crate,preAmpDig,preAmpChan];
        [report appendFormat:@"Jump detected at: %@\n",[[baselineInfo spikeStart]stdDescription]];
        [report appendFormat:@"Ave Voltage: %.3f Voltage Change: %.3f\n",baselineInfo.ave,baselineInfo.spikeValue];
    }
    return report;
}

- (BOOL) breakdownAlarmPosted:(int)alarmIndex
{
    if(alarmIndex>=0 && alarmIndex<2)return [breakdownAlarm[alarmIndex] isPosted];
    else return NO;
}

- (void) setupBreakDownDictionary
{
    if(!breakDownDictionary){
        breakDownDictionary = [[NSMutableDictionary dictionary]retain];
        [breakDownDictionary setObject:[NSMutableDictionary dictionary] forKey:@"detectorEntries"];
    }
}

- (NSDictionary*)breakDownDictionary { return breakDownDictionary; }

- (BOOL) vacuumSpike:(int)i
{
    if(i>=0 && i<2)return[[self mjdInterlocks:i] vacuumSpike];
    else return NO;
}


- (BOOL) fillingLN:(int)i
{
    if(i>=0 && i<2)return[[self mjdInterlocks:i] fillingLN];
    else return NO;
}
                          
- (int) pollingTimeForLN:(int)i
{
    if(i>=0 && i<2)return[[self mjdInterlocks:i] pollingTimeForLN];
    else return 0;
}
                          
- (BOOL) breakdownConditionsMet:(id)aDetectorKey
{
    NSDictionary* detectorEntries   = [breakDownDictionary objectForKey:@"detectorEntries"];
    NSMutableDictionary* anEntry    = [detectorEntries objectForKey:aDetectorKey];
    ORRunningAveSpike* rateInfo     = [anEntry objectForKey:@"rateInfo"];
    ORRunningAveSpike* baselineInfo = [anEntry objectForKey:@"baselineInfo"];
    
    int crate = [[anEntry objectForKey:@"crate"] intValue];
    BOOL fillingLN = NO;
    BOOL vacSpike  = NO;
    if(crate>=1 && crate<=2){
        fillingLN = [[self mjdInterlocks:crate-1] fillingLN];
        vacSpike  = [[self mjdInterlocks:crate-1] vacuumSpike];
    }
    
    if([self calibrationRun:crate]){
        return (baselineInfo && !fillingLN && vacSpike);
    }
    else return (rateInfo && baselineInfo && !fillingLN && vacSpike);
}

- (void) rampDownChannelsWithBreakdown:(int)aCrate vac:(int)aVacSystem
{
    if(aVacSystem==0 && ignorePanicOnA)return;
    if(aVacSystem==1 && ignorePanicOnB)return;
    
    if((aCrate == 2) && ignoreBreakdownCheckOnA)return;
    if((aCrate == 1) && ignoreBreakdownCheckOnB)return;

    if((aCrate == 2) && ignoreBreakdownPanicOnA)return;
    if((aCrate == 1) && ignoreBreakdownPanicOnB)return;
    
    //use the breakDownDictionary to determine which HV to panic
    int alarmIndex = aCrate-1;
    if(![breakdownAlarm[alarmIndex] acknowledged] && [breakdownAlarm[alarmIndex] timeSincePosted] >= 20*60){
        //OK, we know something has breakdown or there wouldn't be an alarm. Figure out which one(s) to ramp
        for(id aDetectorKey in breakDownDictionary){
            if([self breakdownConditionsMet:aDetectorKey]){
                NSMutableDictionary* anEntry = [breakDownDictionary objectForKey:aDetectorKey];
                int hvCrate             = [[anEntry objectForKey:@"hvCrate"]    intValue];
                int hvCard              = [[anEntry objectForKey:@"hvCard"]     intValue];
                int hvChannel           = [[anEntry objectForKey:@"hvChannel"]  intValue];
                NSString* stringName    = [anEntry  objectForKey:@"stringName"];
                NSString* detectorName  = [anEntry  objectForKey:@"detectorName"];
                    
                NSLogColor([NSColor redColor],@"Breakdown detected on string %@ Detector %@\n",stringName,detectorName);
                
                ORMPodCrateModel* hvCrateObj = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:[NSString stringWithFormat:@"ORMPodCrateModel,%d",hvCrate]];
                
                ORiSegHVCard* theHVCard = [hvCrateObj cardInSlot:hvCard];
                float target = [theHVCard target:hvChannel];
                float newTarget = .80*target;
                [theHVCard setTarget:hvChannel withValue:newTarget];
                [theHVCard commitTargetToHwGoal:hvChannel];
                [theHVCard loadValues:hvChannel];
                NSLogColor([NSColor redColor],@"Ramping %@,%d from %.2f to %.2f\n",[theHVCard fullID],hvChannel,target,newTarget);

                //[[hvCrateObj cardInSlot:hvCard] panic:hvChannel];
            }
        }
    }
}

- (BOOL) validateSegmentParam:(NSString*)aParam
{
    if([aParam length]==0 || [aParam rangeOfString:@"-"].location!=NSNotFound)return NO;
    else return YES;
}

- (void) rateSpike:(NSNotification*) aNote
{
    NSDictionary* dic = [aNote userInfo];
   
    //either a spike happened or a spike cleared
    ORRunningAveSpike* spikeInfo = [dic objectForKey:@"spikeInfo"];
    NSString* aKey = [NSString stringWithFormat:@"%@,%@,%@",
                      [dic objectForKey:@"crate"],
                      [dic objectForKey:@"card"],
                      [dic objectForKey:@"channel"]];
    BOOL spiked = [spikeInfo spiked];
    if(spiked){
        int aCrate = [[dic objectForKey:@"crate"]intValue];
        if((aCrate == 2) &&  ignoreBreakdownCheckOnA)return;
        if((aCrate == 1) &&  ignoreBreakdownCheckOnB)return;
        //a spike happened..
        if(![rateSpikes objectForKey:aKey]){
            //not noticed before, so store it
            if(!rateSpikes)rateSpikes = [[NSMutableDictionary dictionary] retain];
            [rateSpikes setObject:dic forKey:aKey]; //<<<--note, dictionary stored has spike and crate,card, chan info
        }
    }
    else {
        //the spike has ended
        NSDictionary* spikeDic = [rateSpikes objectForKey:aKey];
        if(spikeDic){
            ORRunningAveSpike* oldSpikeInfo = [spikeDic objectForKey:@"spikeInfo"];

            //post to the data base history using the staring spike stored earlier
            NSMutableDictionary* record = [NSMutableDictionary dictionary];
            NSDate*   started   = [oldSpikeInfo spikeStart];
            NSNumber* startTime = [NSNumber numberWithDouble:[started timeIntervalSince1970]];
            NSNumber* endTime   = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
            
            //-------------------------
            NSString* iden = [NSString stringWithFormat:@"RateConcernCrate%@",[dic objectForKey:@"crate"]];
            [record setObject:iden                          forKey:@"name"];
            [record setObject:iden                          forKey:@"title"];
            [record setObject:[dic objectForKey:@"crate"]   forKey:@"crate"];
            [record setObject:[dic objectForKey:@"card"]    forKey:@"card"];
            [record setObject:[dic objectForKey:@"channel"] forKey:@"chan"];
    
            [record setObject:[NSNumber numberWithFloat:oldSpikeInfo.ave]             forKey:@"ave"];
            [record setObject:[NSNumber numberWithFloat:oldSpikeInfo.duration]        forKey:@"duration"];
            [record setObject:[NSNumber numberWithFloat:oldSpikeInfo.spikeValue]      forKey:@"spikeValue"];
            
            [record setObject:[oldSpikeInfo.spikeStart stdDescription]                forKey:@"timeOfSpike"];
            
            [record setObject:startTime                     forKey:@"startTime"];
            [record setObject:endTime                       forKey:@"endTime"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddHistoryAdcRecord" object:self userInfo:record];
            //-------------------------

            [rateSpikes removeObjectForKey:aKey];
            if([[rateSpikes allKeys] count] == 0){
                [rateSpikes release];
                rateSpikes = nil;
            }
        }
    }
    [self updateBreakdownDictionary:dic];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelUpdateSpikeDisplay" object:self];
}

- (void) baselineSpike:(NSNotification*) aNote
{
    //either a spike happened or a spike cleared
    NSDictionary* dic = [aNote userInfo];
    ORRunningAveSpike* spikeInfo = [dic objectForKey:@"spikeInfo"];
    NSString* aKey = [NSString stringWithFormat:@"%@,%@,%@",
                      [dic objectForKey:@"crate"],
                      [dic objectForKey:@"card"],
                      [dic objectForKey:@"channel"]];
    BOOL spiked = [spikeInfo spiked];
    if(!spikeInfo.spikeStart)return;
    if(spiked){
        int aCrate = [[dic objectForKey:@"crate"]intValue];
        if((aCrate == 2) &&  ignoreBreakdownCheckOnA)return;
        if((aCrate == 1) &&  ignoreBreakdownCheckOnB)return;
        
        if(![baselineSpikes objectForKey:aKey]){
            if(!baselineSpikes)baselineSpikes = [[NSMutableDictionary dictionary] retain];
            [baselineSpikes setObject:dic forKey:aKey];
        }
    }
    else {
        if([baselineSpikes objectForKey:aKey]){
            
            //-------------------------
            //this means the spike has ended.
            //post to the data base history using the staring spike stored earlier
            NSMutableDictionary* record = [NSMutableDictionary dictionary];
            NSDate*   started   = [spikeInfo spikeStart];
            NSNumber* startTime = [NSNumber numberWithDouble:[started timeIntervalSince1970]];
            NSNumber* endTime   = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
            
            NSString* iden = [NSString stringWithFormat:@"BaselineConcernCrate%@",[dic objectForKey:@"crate"]];
            [record setObject:iden                          forKey:@"name"];
            [record setObject:iden                          forKey:@"title"];
            [record setObject:[dic objectForKey:@"crate"]   forKey:@"crate"];
            [record setObject:[dic objectForKey:@"card"]    forKey:@"card"];
            [record setObject:[dic objectForKey:@"channel"] forKey:@"chan"];
            [record setObject:[NSNumber numberWithFloat:spikeInfo.duration]        forKey:@"duration"];
            [record setObject:[NSNumber numberWithFloat:spikeInfo.ave]             forKey:@"ave"];
            [record setObject:[NSNumber numberWithFloat:spikeInfo.spikeValue]      forKey:@"spikeValue"];
            [record setObject:[spikeInfo.spikeStart stdDescription]                                 forKey:@"timeOfSpike"];
            [record setObject:startTime                     forKey:@"startTime"];
            [record setObject:endTime                       forKey:@"endTime"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddHistoryAdcRecord" object:self userInfo:record];
            //-------------------------

            
            
            [baselineSpikes removeObjectForKey:aKey];
            if([[baselineSpikes allKeys] count] == 0){
                [baselineSpikes release];
                baselineSpikes = nil;
            }
        }
    }
    [self updateBreakdownDictionary:dic];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelUpdateSpikeDisplay" object:self];
}

- (NSDictionary*) rateSpikes
{
    return rateSpikes;
}

- (NSDictionary*) baselineSpikes
{
    return baselineSpikes;
}

- (float) maxNonCalibrationRate
{
    return maxNonCalibrationRate;
}

- (void) setMaxNonCalibrationRate:(float)aValue
{
    if(aValue>3000)aValue=3000;
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxNonCalibrationRate:maxNonCalibrationRate];
    maxNonCalibrationRate = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORMajoranaModelMaxNonCalibrationRate" object:self];
}

#pragma mark ***Accessors
- (NSDate*) lastConstraintCheck
{
    return lastConstraintCheck;
}

- (void) setLastConstraintCheck:(NSDate*)aDate
{
    [aDate retain];
    [lastConstraintCheck release];
    lastConstraintCheck = aDate;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMajoranaModelLastConstraintCheckChanged object:self];
}

- (BOOL) ignorePanicOnB
{
    return ignorePanicOnB;
}

- (void) setIgnorePanicOnB:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnorePanicOnB:ignorePanicOnB];
    
    if(ignorePanicOnB != aState){
        ignorePanicOnB = aState;
        if(ignorePanicOnB){
            NSLogColor([NSColor redColor],@"WARNING: HV checks will ignore HV Ramp Action on Module 1\n");
        }
        else {
            NSLog(@"HV checks will NOT ignore HV ramp action on Module 1\n");
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnorePanicOnBChanged object:self];
}

- (BOOL) ignorePanicOnA
{
    return ignorePanicOnA;
}

- (void) setIgnorePanicOnA:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnorePanicOnA:ignorePanicOnA];
    
    if(ignorePanicOnA != aState){
        ignorePanicOnA = aState;
        if(ignorePanicOnA){
            NSLogColor([NSColor redColor],@"WARNING: HV checks will ignore HV Ramp Action on Module 2\n");
        }
        else {
            NSLog(@"HV checks will NOT ignore HV ramp action on Module 2\n");
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnorePanicOnAChanged object:self];
}

- (BOOL) ignoreBreakdownCheckOnB
{
    return ignoreBreakdownCheckOnB;
}

- (void) setIgnoreBreakdownCheckOnB:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnoreBreakdownCheckOnB:ignoreBreakdownCheckOnB];
    
    if(ignoreBreakdownCheckOnB!= aState){
        ignoreBreakdownCheckOnB = aState;
        if(ignoreBreakdownCheckOnB){
            NSLogColor([NSColor redColor],@"WARNING: Breakdown check will be SKIPPED on Module 1\n");
            [breakdownAlarm[0] clearAlarm];
            [breakdownAlarm[0] release];
            breakdownAlarm[0] = nil;
        }
        else {
            NSLog(@"Breakdown checks on Module 1\n");
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnoreBreakdownCheckOnBChanged object:self];
}

- (BOOL) ignoreBreakdownCheckOnA
{
    return ignoreBreakdownCheckOnA;
}

- (void) setIgnoreBreakdownCheckOnA:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnoreBreakdownCheckOnA:ignoreBreakdownCheckOnA];
    
    if(ignoreBreakdownCheckOnA!= aState){
        ignoreBreakdownCheckOnA = aState;
        if(ignoreBreakdownCheckOnA){
            NSLogColor([NSColor redColor],@"WARNING: Breakdown check will be SKIPPED on Module 2\n");
            [breakdownAlarm[1] clearAlarm];
            [breakdownAlarm[1] release];
            breakdownAlarm[1] = nil;
        }
        else {
            NSLog(@"Breakdown checks on Module 2\n");
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnoreBreakdownCheckOnAChanged object:self];
}

- (BOOL) ignoreBreakdownPanicOnB
{
    return ignoreBreakdownPanicOnB;
}

- (void) setIgnoreBreakdownPanicOnB:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnoreBreakdownPanicOnB:ignoreBreakdownPanicOnB];
    
    if(ignoreBreakdownPanicOnB!= aState){
        ignoreBreakdownPanicOnB = aState;
        if(ignoreBreakdownPanicOnB){
            NSLogColor([NSColor redColor],@"WARNING: Breakdowns on Module 1 will be checked, but HV will NOT ramp down\n");
            [breakdownAlarm[0] clearAlarm];
            [breakdownAlarm[0] release];
            breakdownAlarm[0] = nil;
        }
        else {
            NSLog(@"Breakdown panic enabled on Module 1\n");
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnoreBreakdownPanicOnBChanged object:self];
}

- (BOOL) ignoreBreakdownPanicOnA
{
    return ignoreBreakdownPanicOnA;
}

- (void) setIgnoreBreakdownPanicOnA:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnoreBreakdownPanicOnA:ignoreBreakdownPanicOnA];
    
    if(ignoreBreakdownPanicOnA!= aState){
        ignoreBreakdownPanicOnA = aState;
        if(ignoreBreakdownPanicOnA){
            NSLogColor([NSColor redColor],@"WARNING: Breakdowns on Module 2 will be checked, but HV will NOT ramp down\n");
            [breakdownAlarm[1] clearAlarm];
            [breakdownAlarm[1] release];
            breakdownAlarm[1] = nil;
        }
        else {
            NSLog(@"Breakdown panic enabled on Module 2\n");
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MajoranaModelIgnoreBreakdownPanicOnAChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMajoranaModelPollTimeChanged object:self];
	
	if(pollTime){
		[self performSelector:@selector(checkConstraints) withObject:nil afterDelay:.2];
	}
	else {
        int i;
        for(i=0;i<2;i++){
            [mjdInterlocks[i] reset:NO];
        }
        NSLog(@"HV interlocks have been turned OFF\n");
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkConstraints) object:nil];
	}
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)aDictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
	
	[[segmentGroups objectAtIndex:0] addParametersToDictionary:objDictionary useName:@"DetectorGeometry" addInGroupName:NO];
	[[segmentGroups objectAtIndex:1] addParametersToDictionary:objDictionary useName:@"VetoGeometry" addInGroupName:NO];
    
    NSString* stringMapContents = [self stringMapFileAsString];
    if([stringMapContents length]){
        stringMapContents = [stringMapContents stringByAppendingString:@"\n"];
        [objDictionary setObject:stringMapContents forKey:@"StringGeometry"];
    }
    NSString* specialMapContents = [self specialMapFileAsString];
    if([specialMapContents length]){
        specialMapContents = [specialMapContents stringByAppendingString:@"\n"];
        [objDictionary setObject:specialMapContents forKey:@"SpecialStrings"];
    }

    [aDictionary setObject:objDictionary forKey:[self className]];

    return aDictionary;
}


- (NSMutableArray*) setupMapEntries:(int) groupIndex
{
    [self setCrateIndex:1];
    [self setCardIndex:2];
    [self setChannelIndex:3];
    
    NSMutableArray* mapEntries = [NSMutableArray array];
    if(groupIndex == 0){
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber",     @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kVME",               @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kCardSlot",          @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",           @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreAmpChan",        @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVCrate",           @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVCard",            @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVChan",            @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kMaxVoltage",        @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kDetectorName",      @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kDetectorType",      @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreAmpDigitizer",   @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
     }
    else if(groupIndex == 1){
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber", @"key", [NSNumber numberWithInt:0], @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kVME",			@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kCardSlot",      @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",       @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVCrate",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVCard",        @"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kHVChan",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
    }
	return mapEntries;
}

- (void) postCouchDBRecord
{    
    NSMutableDictionary*  values  = [NSMutableDictionary dictionary];
    int aSet;
    int numGroups = [segmentGroups count];
    for(aSet=0;aSet<numGroups;aSet++){
        NSMutableDictionary* aDictionary= [NSMutableDictionary dictionary];
        NSMutableArray* thresholdArray  = [NSMutableArray array];
        NSMutableArray* totalCountArray = [NSMutableArray array];
        NSMutableArray* rateArray       = [NSMutableArray array];
        NSMutableArray* onlineArray     = [NSMutableArray array];
        
        ORSegmentGroup* segmentGroup = [self segmentGroup:aSet];
        int numSegments = [self numberSegmentsInGroup:aSet];
        int i;
        for(i = 0; i<numSegments; i++){
            [thresholdArray     addObject:[NSNumber numberWithFloat:[segmentGroup getThreshold:i]]];
            [totalCountArray    addObject:[NSNumber numberWithFloat:[segmentGroup getTotalCounts:i]]];
            [rateArray          addObject:[NSNumber numberWithFloat:[segmentGroup getRate:i]]];
            [onlineArray        addObject:[NSNumber numberWithFloat:[segmentGroup online:i]]];
        }
        
        NSArray* mapEntries = [[segmentGroup paramsAsString] componentsSeparatedByString:@"\n"];
        
        if([thresholdArray count])  [aDictionary setObject:thresholdArray   forKey: @"thresholds"];
        if([totalCountArray count]) [aDictionary setObject:totalCountArray  forKey: @"totalcounts"];
        if([rateArray count])       [aDictionary setObject:rateArray        forKey: @"rates"];
        if([onlineArray count])     [aDictionary setObject:onlineArray      forKey: @"online"];
        if([mapEntries count])      [aDictionary setObject:mapEntries       forKey: @"geometry"];
        
        NSArray* totalRateArray = [[[self segmentGroup:aSet] totalRate] ratesAsArray];
        if(totalRateArray)[aDictionary setObject:totalRateArray forKey:@"totalRate"];

        [values setObject:aDictionary forKey:[segmentGroup groupName]];
    }
    
    NSMutableDictionary* aDictionary= [NSMutableDictionary dictionary];
    NSArray* stringMapEntries = [[self stringMapFileAsString] componentsSeparatedByString:@"\n"];
    [aDictionary setObject:stringMapEntries forKey: @"geometry"];
    [values setObject:aDictionary           forKey:@"Strings"];
  
    aDictionary= [NSMutableDictionary dictionary];
    NSArray* specialMapEntries = [[self specialMapFileAsString] componentsSeparatedByString:@"\n"];
    [aDictionary setObject:specialMapEntries forKey: @"list"];
    [values setObject:aDictionary           forKey:@"SpecialChannels"];

    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
}

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups
{
    ORMJDSegmentGroup* group = [[ORMJDSegmentGroup alloc] initWithName:@"Detectors" numSegments:kNumDetectors mapEntries:[self setupMapEntries:0]];
	[self addGroup:group];
	[group release];
    
    ORSegmentGroup* group2 = [[ORSegmentGroup alloc] initWithName:@"Veto" numSegments:kNumVetoSegments mapEntries:[self setupMapEntries:1]];
	[self addGroup:group2];
	[group2 release];
}

- (int)  maxNumSegments
{
	return kNumDetectors;
}

- (int) numberSegmentsInGroup:(int)aGroup
{
	if(aGroup == 0) return kNumDetectors;
	else			return kNumVetoSegments;
}
- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		NSString* crateName  = [aGroup segment:index objectForKey:@"kVME"];
		NSString* cardName = [aGroup segment:index objectForKey:@"kCardSlot"];
		NSString* chanName = [aGroup segment:index objectForKey:@"kChannel"];
        
        
        
		if(cardName && chanName && ![cardName hasPrefix:@"-"] && ![chanName hasPrefix:@"-"]){
			ORDataSet* aDataSet = nil;
			[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
			NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
			if([objs count]){
				NSArray* arrayOfHistos = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
				if([arrayOfHistos count]){
                    
                    NSString* cardObjectName = [self objectNameForCrate:crateName andCard:cardName];
                    //have to get the class name of the card in question. First look for the crate
 
                    
                    if(cardObjectName){
                    
                        id histoObj = [arrayOfHistos objectAtIndex:0];
                        aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:cardObjectName, @"Energy",
															[NSString stringWithFormat:@"Crate %2d",[crateName intValue]],
															[NSString stringWithFormat:@"Card %2d",[cardName intValue]],
															[NSString stringWithFormat:@"Channel %2d",[chanName intValue]],
															nil]];
					
                        [aDataSet doDoubleClick:nil];
                    }
				}
			}
		}
	}
}

- (NSString*) objectNameForCrate:(NSString*)aCrateName andCard:(NSString*)aCardName
{
    NSArray* crates = [[self document] collectObjectsOfClass:NSClassFromString(@"ORVme64CrateModel")];
    for(ORVme64CrateModel* aCrate in crates){
        if([aCrate crateNumber] == [aCrateName intValue]){
            //OK, got the crate. Get the card
            NSArray* cards = [aCrate orcaObjects];
            for(id aCard in cards){
                if([aCard slot] == [aCardName intValue]){
                    NSString* cardObjectName  = [[aCard className] stringByReplacingOccurrencesOfString:@"OR" withString:@""];
                    return [cardObjectName stringByReplacingOccurrencesOfString:@"Model" withString:@""];
                }
            }
        }
    }
    return nil;
}

- (NSString*) dataSetNameGroup:(int)aGroup segment:(int)index
{
	ORSegmentGroup* theGroup = [segmentGroups objectAtIndex:aGroup];
	
	NSString* crateName = [theGroup segment:index objectForKey:@"kCrate"];
	NSString* cardName  = [theGroup segment:index objectForKey:@"kCardSlot"];
	NSString* chanName  = [theGroup segment:index objectForKey:@"kChannel"];
	
	return [NSString stringWithFormat:@"Gretina4M,Energy,Crate %2d,Card %2d,Channel %2d",[crateName intValue],[cardName intValue],[chanName intValue]];
}

- (id) mjdInterlocks:(int)index
{
    if(!mjdInterlocks[index]){
        mjdInterlocks[index] = [[ORMJDInterlocks alloc] initWithDelegate:self slot:index];
    }
    return mjdInterlocks[index];
}

- (id) mjdSource:(int)index
{
    if(index>=0 && index<2){
        if(!mjdSource[index]){
            mjdSource[index] = [[ORMJDSource alloc] initWithDelegate:self slot:index];
        }
        return mjdSource[index];
    }
    else return nil;
}

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock     { return @"MajoranaMapLock";      }
- (NSString*) vetoMapLock           { return @"MajoranaVetoMapLock";  }
- (NSString*) experimentDetectorLock{ return @"MajoranaDetectorLock"; }
- (NSString*) experimentDetailsLock	{ return @"MajoranaDetailsLock";  }
- (NSString*) calibrationLock       { return @"MajoranaCalibrationLock";  }

- (void) setViewType:(int)aViewType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setViewType:aViewType];
	viewType = aViewType;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMajoranaModelViewTypeChanged object:self userInfo:nil];
}

- (int) viewType { return viewType; }

- (ORRemoteSocketModel*) remoteSocket:(int)anIndex
{
    for(id obj in [self orcaObjects]){
        if([obj tag] == anIndex)return obj;
    }
    return nil;
}

- (BOOL) anyHvOnVMECrate:(int)aVmeCrate
{
    //tricky .. we have to location the HV crates based on the hv map using the VME crate (detector group 0).
    //But we don't care about the Veto system (group 1).
    ORMPodCrateModel* hvCrateObj[2] = {nil,nil}; //will check for up to two HV crates (should just be one)
    hvCrateObj[0] = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,0"];
    hvCrateObj[1] = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,1"];

    ORSegmentGroup* group = [self segmentGroup:0]; //detector group
    int n = [group numSegments]; //both DAQ and Veto on the same HV supply for now
    int i;
    for(i=0;i<n;i++){
        ORDetectorSegment* seg =  [group segment:i];                    //get a segment from the group
		int vmeCrate = [[seg objectForKey:@"kVME"] intValue];           //pull out the crate
        if(vmeCrate == aVmeCrate){
            int hvCrate = [[seg objectForKey:@"kHVCrate"]intValue];    //pull out the crate
            int hvCard  = [[seg objectForKey:@"kHVCard"]intValue];    //pull out the card
            if(hvCrate<2){
                ORiSegHVCard* card = [hvCrateObj[hvCrate] cardInSlot:hvCard];
                if([card hvOnAnyChannel])return YES;
            }
        }
    }
    return NO;
}

- (void) setVmeCrateHVConstraint:(int)aVmeCrate state:(BOOL)aState
{
    if(aVmeCrate>=2)return;
    //tricky .. we have to location the HV crates based on the hv map using the VME crate (group 0).
    //But we don't care about the Veto system (group 1).
    ORMPodCrateModel* hvCrateObj[2] = {nil,nil};
    hvCrateObj[0] = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,0"];
    hvCrateObj[1] = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,1"];
    
    ORSegmentGroup* group = [self segmentGroup:0];
    int n = [group numSegments];    //both DAQ and Veto on the same HV supply now
    int i;
    for(i=0;i<n;i++){
        ORDetectorSegment* seg =  [group segment:i];        //get a segment from the group
		int vmeCrate = [[seg objectForKey:@"kVME"] intValue];           //pull out the crate
        if(vmeCrate == aVmeCrate){
            int hvCrate = [[seg objectForKey:@"kHVCrate"]intValue];    //pull out the crate
            int hvCard  = [[seg objectForKey:@"kHVCard"]intValue];     //pull out the card
            if(hvCrate<2){
                if(aState) {
                    [[hvCrateObj[hvCrate] cardInSlot:hvCard] addHvConstraint:@"MJD Vac" reason:[NSString stringWithFormat:@"HV (%d) Card (%d) mapped to VME %d and Vacuum Is Bad or Vacuum system is not communicating",hvCrate,hvCard,aVmeCrate]];
                }
                else {
                    [[hvCrateObj[hvCrate] cardInSlot:hvCard] removeHvConstraint:@"MJD Vac"];
                    [rampHVAlarm[aVmeCrate] setAcknowledged:NO];
                }
            }
        }
    }
}

- (void) rampDownHV:(int)aCrate vac:(int)aVacSystem
{
    if(aVacSystem==0 && ignorePanicOnA)return;
    if(aVacSystem==1 && ignorePanicOnB)return;
    
    if(!rampHVAlarm[aVacSystem]){
        rampHVAlarm[aVacSystem] = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Panic HV (Vac %c)",'A'+aVacSystem] severity:(kEmergencyAlarm)];
        [rampHVAlarm[aVacSystem] setSticky:NO];
        [rampHVAlarm[aVacSystem] setHelpString:[NSString stringWithFormat:@"HV was ramped down on Module %d because Vac %c failed interlocks\nThe alarm can be cleared by acknowledging it.",aCrate, 'A'+aVacSystem]];
        NSLogColor([NSColor redColor], @"HV was ramped down on Module %d because Vac %c failed interlocks\n",aCrate,
                   'A'+aVacSystem);
    }
    
    if(![rampHVAlarm[aVacSystem] acknowledged]){
       [rampHVAlarm[aVacSystem] postAlarm];
    }
    
    
    [[NSNotificationCenter defaultCenter]
            postNotificationName:ORRequestRunHalt
                          object:self
                        userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"HV Panic",@"Reason",nil]];
    
    //tricky .. we have to location the HV crates based on the hv map using the VME crate (group 0).
    //But we don't care about the Veto system (group 1).
    ORMPodCrateModel* hvCrateObj[2] = {nil,nil};
    hvCrateObj[0] = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,0"];
    hvCrateObj[1] = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORMPodCrateModel,1"];
    
    ORSegmentGroup* group = [self segmentGroup:0];
    //both DAQ and Veto on the same HV supply now
    int n = [group numSegments];
    int i;
    for(i=0;i<n;i++){
        ORDetectorSegment* seg = [group segment:i];                    //get a segment from the group
		int vmeCrate = [[seg objectForKey:@"kVME"] intValue];           //pull out the crate
        if(vmeCrate == aCrate){
            int hvCrate   = [[seg objectForKey:@"kHVCrate"]intValue];     //pull out the crate
            int hvCard    = [[seg objectForKey:@"kHVCard"]intValue];     //pull out the card
            if(hvCrate<2){
                [[hvCrateObj[hvCrate] cardInSlot:hvCard] panicAllChannels];
            }
        }
    }
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setIgnorePanicOnB:[decoder decodeBoolForKey:@"ignorePanicOnB"]];
    [self setIgnorePanicOnA:[decoder decodeBoolForKey:@"ignorePanicOnA"]];
    [self setIgnoreBreakdownCheckOnB:[decoder decodeBoolForKey:@"ignoreBreakdownCheckOnB"]];
    [self setIgnoreBreakdownCheckOnA:[decoder decodeBoolForKey:@"ignoreBreakdownCheckOnA"]];
    [self setIgnoreBreakdownPanicOnB:[decoder decodeBoolForKey:@"ignoreBreakdownPanicOnB"]];
    [self setIgnoreBreakdownPanicOnA:[decoder decodeBoolForKey:@"ignoreBreakdownPanicOnA"]];
    [self setViewType:[decoder decodeIntForKey:@"viewType"]];
    int i;
    for(i=0;i<2;i++){
        mjdInterlocks[i] = [[ORMJDInterlocks alloc] initWithDelegate:self slot:i];
        mjdSource[i] = [[ORMJDSource alloc] initWithDelegate:self slot:i];
    }
    pollTime   = [decoder  decodeIntForKey:	@"pollTime"];
    stringMap  = [[decoder decodeObjectForKey:@"stringMap"] retain];
    specialMap = [[decoder decodeObjectForKey:@"specialMap"] retain];

    [self validateStringMap];
    [self validateSpecialMap];
    [self setDetectorStringPositions];
    
    float maxCalRate = [decoder decodeFloatForKey:@"maxNonCalibrationRate"];
    if(maxCalRate==0)maxCalRate = 1000;
    [self setMaxNonCalibrationRate:maxCalRate];
	[[self undoManager] enableUndoRegistration];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:ignorePanicOnB forKey:@"ignorePanicOnB"];
    [encoder encodeBool:ignorePanicOnA forKey:@"ignorePanicOnA"];
    [encoder encodeBool:ignoreBreakdownCheckOnB forKey:@"ignoreBreakdownCheckOnB"];
    [encoder encodeBool:ignoreBreakdownCheckOnA forKey:@"ignoreBreakdownCheckOnA"];
    [encoder encodeBool:ignoreBreakdownPanicOnB forKey:@"ignoreBreakdownPanicOnB"];
    [encoder encodeBool:ignoreBreakdownPanicOnA forKey:@"ignoreBreakdownPanicOnA"];
    [encoder encodeInt:viewType        forKey: @"viewType"];
	[encoder encodeInt:pollTime		   forKey: @"pollTime"];
    [encoder encodeObject:stringMap	   forKey: @"stringMap"];
    [encoder encodeObject:specialMap   forKey: @"specialMap"];
    [encoder encodeFloat:maxNonCalibrationRate   forKey: @"maxNonCalibrationRate"];
}

- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
	if([aString length] == 0)return @"Not Mapped";
	if(aSet==0){
        NSString* finalString = @"";
        NSArray* parts = [aString componentsSeparatedByString:@"\n"];
        
        NSString* gainType = [self getValueForPartStartingWith: @" GainType"   parts:parts];
        if([gainType length]==0)return @"Not Mapped";
        if([gainType intValue]==0)gainType = @"LG";
        else gainType = @"HG";
 
        NSString* detType = [self getValueForPartStartingWith: @" DetectorType"   parts:parts];
        if([detType length]==0)return @"Not Mapped";
        if([detType intValue]==0)    detType = @" BeGe";
        else if([detType intValue]==2)detType = @" Enriched";
        else detType = @"";

        
        finalString = [finalString stringByAppendingFormat: @"%@\n",[parts objectAtIndex:0]];
        finalString = [finalString stringByAppendingFormat: @"%@%@\n",[self getPartStartingWith:    @" DetectorName"   parts:parts],detType];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" VME"       parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" CardSlot"  parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@ (%@)\n\n",[self getPartStartingWith: @" Channel"   parts:parts],gainType];
        
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" PreAmpDigitizer"   parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" PreAmpChan"   parts:parts]];

        finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:      @" HVCrate"  parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" HVCard"   parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" HVChan"   parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith:      @" Threshold" parts:parts]];
        
        return finalString;
    }
    else if(aSet==1){
        NSString* finalString = @"";
        NSArray* parts = [aString componentsSeparatedByString:@"\n"];
        if([parts count]<6)return @"Not Mapped";
        
        finalString = [finalString stringByAppendingFormat:@"%@\n",[parts objectAtIndex:0]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" Segment"   parts:parts]];
        finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith: @" VME"       parts:parts]       ];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" CardSlot"  parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" Channel"   parts:parts]];
 
        finalString = [ finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith: @" HVCrate" parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" HVCard"  parts:parts]];
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" HVChan"  parts:parts]];
        
        finalString = [finalString stringByAppendingFormat: @"%@\n",[self getPartStartingWith: @" Threshold" parts:parts]];

        return finalString;
    }
    else return @"Not Mapped";
}

- (NSString*) getPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound) return aLine;
	}
	return @"";
}

- (NSString*) getValueForPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound){
            NSArray* subParts = [aLine componentsSeparatedByString:@":"];
            if([subParts count]>=2){
                return [subParts objectAtIndex:1];
            }
        }
	}
	return @"";
}

- (void) readAuxFiles:(NSString*)aPath
{
    NSFileManager* fm = [NSFileManager defaultManager];
	NSString* path = MJDStringMapFile([aPath stringByDeletingPathExtension]);
    
	if([fm fileExistsAtPath:path]){
		NSArray* lines  = [self linesInFile:path];
		for(id aLine in lines){
			if([aLine length] && [aLine characterAtIndex:0] != '#'){ //skip comments
				NSArray* parts =  [aLine componentsSeparatedByString:@","];
				if([parts count]>=3){
                    
                    if([[parts objectAtIndex:0] rangeOfString:@"S"].location != NSNotFound)continue;
                    
					int index = [[parts objectAtIndex:0] intValue];
					if(index<14){
						NSMutableDictionary* dict = [stringMap objectAtIndex:index];
                        [dict setObject:[parts objectAtIndex:0] forKey:@"kStringNum"];
						[dict setObject:[parts objectAtIndex:1] forKey:@"kDet1"];
						[dict setObject:[parts objectAtIndex:2] forKey:@"kDet2"];
						[dict setObject:[parts objectAtIndex:3] forKey:@"kDet3"];
						[dict setObject:[parts objectAtIndex:4] forKey:@"kDet4"];
                        [dict setObject:[parts objectAtIndex:5] forKey:@"kDet5"];
                        //added....
                        if([parts objectAtIndex:6])[dict setObject:[parts objectAtIndex:6] forKey:@"kStringName"];
                        else [dict setObject:@"-" forKey:@"kStringName"];
					}
				}
			}
		}
	}
    
    path = MJDSpecialMapFile([aPath stringByDeletingPathExtension]);
    
    if([fm fileExistsAtPath:path]){
        NSArray* lines  = [self linesInFile:path];
        for(id aLine in lines){
            if([aLine length] && [aLine characterAtIndex:0] != '#'){ //skip comments
                NSArray* parts =  [aLine componentsSeparatedByString:@","];
                if([parts count]>=9){
                    
                    int index = [[parts objectAtIndex:0] intValue];
                    NSMutableDictionary* dict = [specialMap objectAtIndex:index];
                    [dict setObject:[parts objectAtIndex:0] forKey:@"kIndex"];
                    [dict setObject:[parts objectAtIndex:1] forKey:@"kDescription"];
                    [dict setObject:[parts objectAtIndex:2] forKey:@"kVME"];
                    [dict setObject:[parts objectAtIndex:3] forKey:@"kCard"];
                    [dict setObject:[parts objectAtIndex:4] forKey:@"kChannel"];
                    [dict setObject:[parts objectAtIndex:5] forKey:@"kPreAmpDigitizer"];
                    [dict setObject:[parts objectAtIndex:6] forKey:@"kPreAmpChan"];
                    [dict setObject:[parts objectAtIndex:7] forKey:@"kCableLabel"];
                    [dict setObject:[parts objectAtIndex:8] forKey:@"kSpecialType"];
                }
            }
        }
    }
    else {
        [specialMap release];
        specialMap = nil;
        [self validateSpecialMap];
    }
}

- (void) saveAuxFiles:(NSString*)aPath
{
    NSFileManager*   fm       = [NSFileManager defaultManager];

	NSString* stringMapPath = MJDStringMapFile([aPath stringByDeletingPathExtension]);
	if([fm fileExistsAtPath: stringMapPath])[fm removeItemAtPath:stringMapPath error:nil];
	NSData* data = [[self stringMapFileAsString] dataUsingEncoding:NSASCIIStringEncoding];
	[fm createFileAtPath:stringMapPath contents:data attributes:nil];

    NSString* specialMapPath = MJDSpecialMapFile([aPath stringByDeletingPathExtension]);
    if([fm fileExistsAtPath: specialMapPath])[fm removeItemAtPath:specialMapPath error:nil];
    data = [[self specialMapFileAsString] dataUsingEncoding:NSASCIIStringEncoding];
    [fm createFileAtPath:specialMapPath contents:data attributes:nil];
}

- (NSString*) stringMapFileAsString
{
   	NSMutableString* stringRep = [NSMutableString string];
    [stringRep appendFormat:@"Index,Det1,Det2,Det3,Det4,Det5,Name\n"];
    for(id item in stringMap){
        //special, handle the lastest additions
        NSString* name = [item objectForKey:@"kStringName"];
        if([name length]==0)name = @"-";
        
        [stringRep appendFormat:@"%@,%@,%@,%@,%@,%@,%@\n",
                              [item objectForKey:@"kStringNum"],
                              [item objectForKey:@"kDet1"],
                              [item objectForKey:@"kDet2"],
                              [item objectForKey:@"kDet3"],
                              [item objectForKey:@"kDet4"],
                              [item objectForKey:@"kDet5"],
                              name
                              ];
    }
    [stringRep deleteCharactersInRange:NSMakeRange([stringRep length]-1,1)];
    return stringRep;
}

- (NSString*) specialMapFileAsString
{
   	NSMutableString* stringRep = [NSMutableString string];
    [stringRep appendFormat:@"Index,Description,VME,Slot,Chan,PADig,PAChan,Cable,Type\n"];
    for(id item in specialMap){
        
        [stringRep appendFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
         [item objectForKey:@"kIndex"],
         [item objectForKey:@"kDescription"],
         [item objectForKey:@"kVME"],
         [item objectForKey:@"kCard"],
         [item objectForKey:@"kChannel"],
         [item objectForKey:@"kPreAmpDigitizer"],
         [item objectForKey:@"kPreAmpChan"],
         [item objectForKey:@"kCableLabel"],
         [item objectForKey:@"kSpecialType"]
         ];
    }
    [stringRep deleteCharactersInRange:NSMakeRange([stringRep length]-1,1)];
    return stringRep;
}


#pragma mark ¥¥¥String Map Access Methods

- (BOOL) validateDetector:(int)aDetectorIndex
{
    int numSegments = [self numberSegmentsInGroup:0];
    if(aDetectorIndex>=0 && aDetectorIndex<numSegments){
        ORSegmentGroup* segmentGroup = [self segmentGroup:0];
        NSDictionary* params = [[segmentGroup segment:aDetectorIndex]params];
        if(!params)return NO;
        NSString* aCrate = [params objectForKey:@"kVME"];
        if([aCrate length]==0 || [aCrate rangeOfString:@"-"].location!=NSNotFound)return NO;

        NSString* aCard = [params objectForKey:@"kCardSlot"];
        if([aCard length]==0 || [aCard rangeOfString:@"-"].location!=NSNotFound)return NO;
                                 
         NSString* aChannel = [params objectForKey:@"kChannel"];
         if([aChannel length]==0 || [aChannel rangeOfString:@"-"].location!=NSNotFound)return NO;

        NSString* aName = [params objectForKey:@"kDetectorName"];
        if([aName length]==0 || [aName rangeOfString:@"-"].location!=NSNotFound)return NO;

        return YES;
    }
    
    return NO;
}

- (id) stringMap:(int)i objectForKey:(id)aKey
{
    if(i>=0 && i<kMaxNumStrings){
        return [[stringMap objectAtIndex:i] objectForKey:aKey];
    }
    else return @"";
}
- (void) stringMap:(int)i setObject:(id)anObject forKey:(id)aKey
{
	if(i>=0 && i<kMaxNumStrings){
		id entry = [stringMap objectAtIndex:i];
		id oldValue = [self stringMap:i objectForKey:aKey];
		if(oldValue)[[[self undoManager] prepareWithInvocationTarget:self] stringMap:i setObject:oldValue forKey:aKey];
		[entry setObject:anObject forKey:aKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDAuxTablesChanged object:self userInfo:nil];
		
	}
}

- (id) specialMap:(int)i objectForKey:(id)aKey
{
    if(i>=0 && i<kNumSpecialChannels){
        return [[specialMap objectAtIndex:i] objectForKey:aKey];
    }
    else return @"";
}
- (void) specialMap:(int)i setObject:(id)anObject forKey:(id)aKey
{
    if(i>=0 && i<kNumSpecialChannels){
        id entry = [specialMap objectAtIndex:i];
        id oldValue = [self specialMap:i objectForKey:aKey];
        if(oldValue)[[[self undoManager] prepareWithInvocationTarget:self] specialMap:i setObject:oldValue forKey:aKey];
        [entry setObject:anObject forKey:aKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDAuxTablesChanged object:self userInfo:nil];
    }
}


#pragma mark ¥¥¥CardHolding Protocol
- (int) maxNumberOfObjects              { return 3; }
- (int) objWidth                        { return 50; }	//In this case, this is really the obj height.
- (int) groupSeparation                 { return 0; }
- (NSString*) nameForSlot:(int)aSlot    { return [NSString stringWithFormat:@"Slot %d",aSlot]; }
- (int) slotForObj:(id)anObj            { return [anObj tag]; }
- (int) numberSlotsNeededFor:(id)anObj  { return 1;           }
- (int) slotAtPoint:(NSPoint)aPoint     { return floor(((int)aPoint.y)/[self objWidth]); }
- (NSPoint) pointForSlot:(int)aSlot     { return NSMakePoint(0,aSlot*[self objWidth]); }

- (NSRange) legalSlotsForObj:(id)anObj
{
	if([anObj isKindOfClass:NSClassFromString(@"ORRemoteSocketModel")])			return NSMakeRange(0,3);
    else return NSMakeRange(0,0);
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj
{
	if([anObj isKindOfClass:NSClassFromString(@"ORRemoteSocketModel")])	return NO;
    else return YES;
}

- (void) place:(id)anObj intoSlot:(int)aSlot
{
    [anObj setTag:aSlot];
	NSPoint slotPoint = [self pointForSlot:aSlot];
	[anObj moveTo:slotPoint];
}

- (void) openDialogForComponent:(int)i
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj tag] == i){
			[anObj makeMainController];
			break;
		}
	}
}

- (void) setDetectorStringPositions
{
    //first must reset all positions
    ORSegmentGroup* segmentGroup = [self segmentGroup:0];
    int numSegments = [self numberSegmentsInGroup:0];
    int i;
    for(i = 0; i<numSegments; i++){
        [segmentGroup setSegment:i object:@"-" forKey:@"kStringName"];
    }
    
    for(i=0;i<14;i++){
        int j;
        for(j=0;j<5;j++){
            NSString* detectorNum = [self stringMap:i objectForKey:[NSString stringWithFormat:@"kDet%d",j+1]];
            NSString* stringName  = [self stringMap:i objectForKey:@"kStringName"];
            if([detectorNum rangeOfString:@"-"].location == NSNotFound && [detectorNum length]!=0){
                int detIndex = [detectorNum intValue];
                [segmentGroup setSegment:detIndex*2 object:[NSNumber numberWithInt:i] forKey:@"kStringNum"];
                [segmentGroup setSegment:detIndex*2 object:[NSNumber numberWithInt:j] forKey:@"kPosition"];
                [segmentGroup setSegment:detIndex*2 object:stringName                 forKey:@"kStringName"];
            }
        }
    }
}
- (NSString*) detectorLocation:(int)index
{
    ORMJDSegmentGroup* segmentGroup = (ORMJDSegmentGroup*)[self segmentGroup:0];
    return [segmentGroup segmentLocation:index];
}

- (void) deploySource:(int)index
{
    if(index>=0 && index<2)[mjdSource[index] startDeployment];
}

- (void) retractSource:(int)index
{
    if(index>=0 && index<2)[mjdSource[index] startRetraction];
}

- (void) stopSource:(int)index
{
    if(index>=0 && index<2)[mjdSource[index] stopSource];
}

- (void) checkSourceGateValve:(int)index
{
    if(index>=0 && index<2)[mjdSource[index] checkGateValve];
}

- (void) initDigitizers
{
    @try {
        [[[segmentGroups objectAtIndex:0]hwCards] makeObjectsPerformSelector:@selector(initBoard)];
        NSLog(@"%@ Digitizers inited\n",[self className]);
    }
    @catch (NSException * e) {
        NSLogColor([NSColor redColor],@"%@ Digitizers init failed\n",[self className]);
    }
}

- (void) initVeto
{
    @try {
        [[[segmentGroups objectAtIndex:1]hwCards] makeObjectsPerformSelector:@selector(initBoard)];
        NSLog(@"%@ Veto inited\n",[self className]);
    }
    @catch (NSException * e) {
        NSLogColor([NSColor redColor],@"%@ Veto init failed\n",[self className]);
    }
}

- (void) constraintCheckFinished:(int)aCrate
{
    [self sendRateSpikeReportForCrate:aCrate];
}

@end

@implementation MajoranaModel (private)
- (void) checkConstraints
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkConstraints) object:nil];
    int i;
    
    if(pollTime){
        [self performSelector:@selector(checkConstraints) withObject:nil afterDelay:pollTime*60];
        for(i=0;i<2;i++){
            if([self remoteSocket:i])[mjdInterlocks[i] start];
        }
        [self setLastConstraintCheck:[NSDate date]];
    }
    else {
       for(i=0;i<2;i++){
           if([self remoteSocket:i])[mjdInterlocks[i] stop];
       }
       
    }
}



- (void) validateStringMap
{
    if(!stringMap){
        stringMap = [[NSMutableArray array] retain];
        int i;
        for(i=0;i<kMaxNumStrings;i++){
            [stringMap addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:i], @"kStringNum",
                                  @"-",						 @"kDet1",
                                  @"-",						 @"kDet2",
                                  @"-",						 @"kDet3",
                                  @"-",						 @"kDet4",
                                  @"-",						 @"kDet5",
                                  @"-",                      @"kStringName",
                                  nil]];
        }
    }
}

- (void) validateSpecialMap
{
    if([specialMap count]<kNumSpecialChannels){
        [specialMap release];
        specialMap = nil;
    }
    if(!specialMap){
        specialMap = [[NSMutableArray array] retain];
        int i;
        for(i=0;i<kNumSpecialChannels;i++){
            [specialMap addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:i], @"kIndex",
                                  @"-",						 @"kDescription",
                                  @"-",						 @"kVME",
                                  @"-",						 @"kCard",
                                  @"-",						 @"kChannel",
                                  @"-",						 @"kPreAmpDigitizer",
                                  @"-",                      @"kPreAmpChan",
                                  @"-",                      @"kCableLabel",
                                  @"-",                      @"kSpecialType",
                                  nil]];
        }
    }
}

- (NSArray*) linesInFile:(NSString*)aPath
{
	NSString* contents = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
	contents = [[contents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
	contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
    return [contents componentsSeparatedByString:@"\n"];
}

@end

@implementation ORMJDHeaderRecordID
- (NSString*) fullID
{
   return @"MJDDataHeader";
}
@end

