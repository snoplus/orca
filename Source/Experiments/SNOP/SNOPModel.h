//
//  SNOPModel.h
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
#import "ORExperimentModel.h"
#import "ORVmeCardDecoder.h"
#import "RedisClient.h"

@class ORDataPacket;
@class ORDataSet;
@class ORCouchDB;
@class ORRunModel;

@protocol snotDbDelegate <NSObject>
@required
- (ORCouchDB*) orcaDbRef:(id)aCouchDelegate;
- (ORCouchDB*) debugDBRef:(id)aCouchDelegate;
- (ORCouchDB*) orcaDbRefWithEntryDB:(id)aCouchDelegate withDB:(NSString*)entryDB;
@end

#define kUseTubeView	0
#define kUseCrateView	1
#define kUsePSUPView	2
#define kNumTubes	20 //XL3s
#define kNumOfCrates 19 //number of Crates in SNO+

@interface SNOPModel: ORExperimentModel <snotDbDelegate>
{
	int viewType;

    NSString* _orcaDBUserName;
    NSString* _orcaDBPassword;
    NSString* _orcaDBName;
    unsigned int _orcaDBPort;
    NSString* _orcaDBIPAddress;
    NSMutableArray* _orcaDBConnectionHistory;
    NSUInteger _orcaDBIPNumberIndex;
    NSTask*	_orcaDBPingTask;
    
    NSString* _debugDBUserName;
    NSString* _debugDBPassword;
    NSString* _debugDBName;
    NSString* _smellieRunNameLabel;
    unsigned int _debugDBPort;
    NSString* _debugDBIPAddress;
    NSMutableArray* _debugDBConnectionHistory;
    NSUInteger _debugDBIPNumberIndex;
    NSTask*	_debugDBPingTask;
    
    unsigned long	_epedDataId;
    unsigned long	_rhdrDataId;
    
    struct {
        unsigned long coarseDelay;
        unsigned long fineDelay;
        unsigned long chargePulseAmp;
        unsigned long pedestalWidth;
        unsigned long calType; // pattern ID (1 to 4) + 10 * (1 ped, 2 tslope, 3 qslope)
        unsigned long stepNumber;
        unsigned long nTSlopePoints;
    } _epedStruct;
    
    struct {
        unsigned long date;
        unsigned long time;
        unsigned long daqCodeVersion;
        unsigned long runNumber;
        unsigned long calibrationTrialNumber;
        unsigned long sourceMask;
        unsigned long long runMask;
        unsigned long gtCrateMask;
    } _rhdrStruct;
    
    NSDictionary* _runDocument;
    NSDictionary* _configDocument;
    NSDictionary* _mtcConfigDoc;
    NSMutableDictionary* _runTypeDocumentPhysics;
    NSMutableDictionary* smellieRunHeaderDocList;
    
    bool _smellieDBReadInProgress;
    bool _smellieDocUploaded;
    NSMutableDictionary * snopRunTypeMask;
    NSNumber * runTypeMask;
    NSString * standardRunType;
    NSString * standardRunVersion;
    
    NSThread * eStopThread;
    
    bool isEmergencyStopEnabled;
    bool isEStopPolling;

    bool rolloverRun;

    NSString *mtcHost;
    int mtcPort;

    NSString *xl3Host;
    int xl3Port;

    NSString *dataHost;
    int dataPort;

    NSString *logHost;
    int logPort;

    RedisClient *mtc_server;
    RedisClient *xl3_server;

    @private
        //ECA stuff
        int ECA_pattern;
        int ECA_type;
        int ECA_tslope_pattern;
        double ECA_subrun_time;
    
}

@property (nonatomic,retain) NSMutableDictionary* smellieRunHeaderDocList;
@property (nonatomic,retain) NSMutableDictionary* snopRunTypeMask;
@property (nonatomic,retain) NSNumber* runTypeMask;

@property (nonatomic,copy) NSString* orcaDBUserName;
@property (nonatomic,copy) NSString* orcaDBPassword;
@property (nonatomic,copy) NSString* orcaDBName;
@property (nonatomic,assign) unsigned int orcaDBPort;
@property (nonatomic,copy) NSString* orcaDBIPAddress;
@property (nonatomic,retain) NSMutableArray* orcaDBConnectionHistory;
@property (nonatomic,assign) NSUInteger orcaDBIPNumberIndex;
@property (nonatomic,retain) NSTask* orcaDBPingTask;

@property (nonatomic,copy) NSString* debugDBUserName;
@property (nonatomic,copy) NSString* debugDBPassword;
@property (nonatomic,copy) NSString* debugDBName;
@property (nonatomic,copy) NSString* smellieRunNameLabel;
@property (nonatomic,assign) unsigned int debugDBPort;
@property (nonatomic,copy) NSString* debugDBIPAddress;
@property (nonatomic,retain) NSMutableArray* debugDBConnectionHistory;
@property (nonatomic,assign) NSUInteger debugDBIPNumberIndex;
@property (nonatomic,retain) NSTask* debugDBPingTask;

@property (nonatomic,assign) unsigned long epedDataId;
@property (nonatomic,assign) unsigned long rhdrDataId;

@property (nonatomic,assign) bool smellieDBReadInProgress;
@property (nonatomic,assign) bool smellieDocUploaded;
@property (nonatomic,assign) bool isEmergencyStopEnabled;
@property (nonatomic,assign) bool isEStopPolling;

@property (copy,setter=setDataServerHost:) NSString *dataHost;
@property (setter=setDataServerPort:) int dataPort;

@property (copy,setter=setLogServerHost:) NSString *logHost;
@property (setter=setLogServerPort:) int logPort;

@property (copy) NSDictionary* runDocument;
@property (copy) NSDictionary* configDocument;
@property (copy) NSDictionary* mtcConfigDoc;


- (id) init;

- (void) setMTCPort: (int) port;
- (int) mtcPort;

- (void) setMTCHost: (NSString *) host;
- (NSString *) mtcHost;

- (void) setXL3Port: (int) port;
- (int) xl3Port;

- (void) setXL3Host: (NSString *) host;
- (NSString *) xl3Host;

- (void) initSmellieRunDocsDic;
- (void) initOrcaDBConnectionHistory;
- (void) clearOrcaDBConnectionHistory;
- (id) orcaDBConnectionHistoryItem:(unsigned int)index;
- (void) orcaDBPing;

- (void) initDebugDBConnectionHistory;
- (void) clearDebugDBConnectionHistory;
- (id) debugDBConnectionHistoryItem:(unsigned int)index;
- (void) debugDBPing;

- (void) taskFinished:(NSTask*)aTask;
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp;

#pragma mark ¥¥orcascript helpers
- (void) zeroPedestalMasks;
- (void) updatePedestalMasks:(unsigned int)pattern;
- (void) hvMasterTriggersOFF;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

- (void) runInitialization:(NSNotification*)aNote;
- (void) runAboutToStart:(NSNotification*)aNote;
- (void) runStarted:(NSNotification*)aNote;
- (void) runAboutToStop:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;

- (void) _waitForBuffers;

- (void) runStateChanged:(NSNotification*)aNote;
- (void) subRunStarted:(NSNotification*)aNote;
- (void) subRunEnded:(NSNotification*)aNote;

- (void) updateEPEDStructWithCoarseDelay: (unsigned long) coarseDelay
                               fineDelay: (unsigned long) fineDelay
                          chargePulseAmp: (unsigned long) chargePulseAmp
                           pedestalWidth: (unsigned long) pedestalWidth
                                 calType: (unsigned long) calType;
- (void) updateEPEDStructWithStepNumber: (unsigned long) stepNumber;
- (void) shipEPEDRecord;
- (void) updateRHDRSruct;
- (void) shipRHDRRecord;

-(BOOL) eStopPoll;
-(void) eStopPolling;

#pragma mark ¥¥¥Accessors
- (void) setViewType:(int)aViewType;
- (int) viewType;
- (NSString*) standardRunType;
- (NSString*) standardRunVersion;
- (void) setStandardRunType:(NSString*)aValue;
- (void) setStandardRunVersion:(NSString*)aValue;
- (int) ECA_pattern;
- (int) ECA_type;
- (int) ECA_tslope_pattern;
- (double) ECA_subrun_time;
- (void) setECA_pattern:(int)aValue;
- (void) setECA_type:(int)aValue;
- (void) setECA_tslope_pattern:(int)aValue;
- (void) setECA_subrun_time:(double)aValue;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups;

#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock;
- (NSString*) experimentDetectorLock;
- (NSString*) experimentDetailsLock;

#pragma mark ¥¥¥DataTaker
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (NSDictionary*) dataRecordDescription;

#pragma mark ¥¥¥SnotDbDelegate
- (ORCouchDB*) orcaDbRef:(id)aCouchDelegate;
- (ORCouchDB*) debugDBRef:(id)aCouchDelegate;
- (ORCouchDB*) orcaDbRefWithEntryDB:(id)aCouchDelegate withDB:(NSString*)entryDB;

//run type definition functions
- (void) setSnopRunTypeMask:(NSMutableDictionary*)aRunType;
- (NSMutableDictionary*) getSnopRunTypeMask;

//smellie functions -------
- (void) getSmellieRunListInfo;
- (NSMutableDictionary*)smellieTestFct;
-(BOOL)isRunTypeMaskedIn:(NSString*)aRunType;
-(void) testerHv;

//Standard runs functions
-(BOOL) loadStandardRun:(NSString*)runTypeName withVersion:(NSString*)runVersion;
-(BOOL) loadStandardRunToHW:(NSString*)runTypeName;
-(BOOL) saveStandardRun:(NSString*)runTypeName withVersion:(NSString*)runVersion;

@end

@interface SNOPDecoderForRHDR : ORVmeCardDecoder {
}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

@interface SNOPDecoderForEPED : ORVmeCardDecoder {
}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end

extern NSString* ORSNOPModelViewTypeChanged;
extern NSString* ORSNOPModelOrcaDBIPAddressChanged;
extern NSString* ORSNOPModelDebugDBIPAddressChanged;
extern NSString* SNOPRunTypeChangedNotification;
extern NSString* ORSNOPRunsLockNotification;
extern NSString* ORSNOPModelRunsECAChangedNotification;
extern NSString* ORSNOPModelSRChangedNotification;
extern NSString* ORSNOPModelSRVersionChangedNotification;
