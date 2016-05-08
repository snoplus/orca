//
//  ELLIEModel.h
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//  Revision history:
//  Ed Leming 30/12/2015 - Memory updates and tidy up.
//

#import <Foundation/Foundation.h>
#import "ELLIEController.h"
#import "XmlrpcClient.h"

@class ORCouchDB;
@class ORRunModel;
@class ORRunController;

@interface ELLIEModel :  OrcaObject{
    NSMutableDictionary* smellieRunSettings;
    NSMutableDictionary* currentOrcaSettingsForSmellie;
    NSMutableDictionary* tellieRunDoc;
    NSMutableDictionary* smellieRunDoc;
    NSTask* exampleTask;
    NSMutableDictionary* smellieRunHeaderDocList;
    ORRunModel* runControl;
    ORRunController* theRunController;
    NSMutableArray* smellieSubRunInfo;
    bool _smellieDBReadInProgress;
    float pulseByPulseDelay;

    //Server Clients
    XmlrpcClient* _tellieClient;
    XmlrpcClient* _smellieClient;

    //tellie settings
    NSMutableDictionary* tellieSubRunSettings;
    NSMutableDictionary* tellieFireParameters;
    NSMutableDictionary* tellieFibreMapping;
    BOOL ellieFireFlag;

    //smellie config mappings
    NSMutableDictionary* smellieLaserHeadToSepiaMapping;
    NSMutableDictionary* smellieLaserHeadToGainMapping;
    NSMutableDictionary* smellieLaserToInputFibreMapping;
    NSMutableDictionary* smellieFibreSwitchToFibreMapping;
    NSNumber* smellieConfigVersionNo;
    BOOL smellieSlaveMode;
}

@property (nonatomic,retain) NSMutableDictionary* tellieFireParameters;
@property (nonatomic,retain) NSMutableDictionary* tellieFibreMapping;
@property (nonatomic,retain) NSMutableDictionary* tellieSubRunSettings;
@property (nonatomic,retain) NSMutableDictionary* smellieRunSettings;
@property (nonatomic,retain) NSMutableDictionary* currentOrcaSettingsForSmellie;
@property (nonatomic,retain) NSMutableDictionary* smellieLaserHeadToSepiaMapping;
@property (nonatomic,retain) NSMutableDictionary* smellieLaserHeadToGainMapping;
@property (nonatomic,retain) NSMutableDictionary* smellieLaserToInputFibreMapping;
@property (nonatomic,retain) NSMutableDictionary* smellieFibreSwitchToFibreMapping;
@property (nonatomic,retain) NSNumber* smellieConfigVersionNo;
@property (nonatomic,assign) BOOL smellieSlaveMode;
@property (nonatomic,retain) NSMutableDictionary* tellieRunDoc;
@property (nonatomic,retain) NSMutableDictionary* smellieRunDoc;
@property (nonatomic,assign) BOOL ellieFireFlag;
@property (nonatomic,retain) NSTask* exampleTask;
@property (nonatomic,retain) NSMutableDictionary* smellieRunHeaderDocList;
@property (nonatomic,retain) NSMutableArray* smellieSubRunInfo;
@property (nonatomic,assign) bool smellieDBReadInProgress;
@property (nonatomic,assign) float pulseByPulseDelay;

-(id) init;
-(id) initWithCoder:(NSCoder *)aCoder;
-(void) setUpImage;
-(void) makeMainController;
-(void) wakeUp;
-(void) sleep;
-(void) dealloc;
-(void) registerNotificationObservers;

/************************/
/*   TELLIE Functions   */
/************************/

// TELLIE calc & control functons
-(void) startTellieRun:(BOOL)scriptFlag;
-(void) stopTellieRun;
-(NSArray*) pollTellieFibre:(double)seconds;
-(NSMutableDictionary*) returnTellieFireCommands:(NSString*)fibreName  withNPhotons:(NSUInteger)photons withFireFrequency:(NSUInteger)frequency withNPulses:(NSUInteger)pulses;
-(NSNumber*) calcTellieChannelPulseSettings:(NSUInteger)channel withNPhotons:(NSUInteger)photons withFireFrequency:(NSUInteger)frequency;
-(NSNumber*) calcTellieChannelForFibre:(NSString*)fibre;
-(void) fireTellieFibreMaster:(NSMutableDictionary*)fireCommands;
-(void) stopTellieFibre:(NSArray*)fireCommands;
-(bool)isELLIEFiring;

// TELLIE database interactions
-(void) pushInitialTellieRunDocument;
-(void) updateTellieRunDocument:(NSDictionary*)subRunDoc;
-(void) loadTELLIEStaticsFromDB;

/************************/
/*  SMELLIE Functions   */
/************************/

//SMELLIE Control Functions
-(void) setSmellieSafeStates;
-(void) setLaserSwitch:(NSString*)laserSwitchChannel;
-(void) setFibreSwitch:(NSString*)fibreSwitchInputChannel withOutputChannel:(NSString*)fibreSwitchOutputChannel;
-(void) setLaserIntensity:(NSString*)laserIntensity;
-(void) setLaserSoftLockOn;
-(void) setLaserSoftLockOff;
-(void) setSmellieMasterMode:(NSString*)triggerFrequency withNumOfPulses:(NSString*)numOfPulses;
-(void) setSuperKSafeStates;
-(void) setSuperKSoftLockOn;
-(void) setSuperKSoftLockOff;
-(void) setSuperKWavelegth:(NSString*)lowBin withHighEdge:(NSString*)highBin;
-(void) sendCustomSmellieCmd:(NSString*)customCmd withArgs:(NSArray*)argsArray;

-(NSMutableArray*)getSmellieRunLaserArray:(NSDictionary*)smellieSettings;
-(NSMutableArray*)getSmellieRunFibreArray:(NSDictionary*)smellieSettings;
-(NSMutableArray*)getSmellieRunFrequencyArray:(NSDictionary*)smellieSettings;
-(NSMutableArray*)getSmellieRunIntensityArray:(NSDictionary*)smellieSettings;
-(NSMutableArray*)getSmellieLowEdgeWavelengthArray:(NSDictionary*)smellieSettings;
-(NSMutableArray*)getSmellieHighEdgeWavelengthArray:(NSDictionary*)smellieSettings;
-(void) startSmellieRunInBackground:(NSDictionary*)smellieSettings;
-(void) startSmellieRun:(NSDictionary*)smellieSettings;
-(void) stopSmellieRun;

// SMELLIE database interactions
-(void) fetchSmellieConfigurationInformation;
-(void) pushInitialSmellieRunDocument;
-(void) updateSmellieRunDocument:(NSDictionary*)subRunDoc;
-(void) smellieDBpush:(NSMutableDictionary*)dbDic;
-(void) smellieConfigurationDBpush:(NSMutableDictionary*)dbDic;
-(NSNumber*) fetchRecentConfigVersion;
-(NSNumber*) fetchConfigVersionFor:(NSString*)name;
-(NSMutableDictionary*) fetchConfigurationFile:(NSNumber*)currentVersion;

/*************************/
/* Misc generic methods  */
/*************************/
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp;
- (ORCouchDB*) orcaDbRefWithEntryDB:(id)aCouchDelegate withDB:(NSString*)entryDB;
- (ORCouchDB*) generalDBRef:(NSString*)aCouchDb;
- (NSString*) stringDateFromDate:(NSDate*)aDate;
- (NSString*) stringUnixFromDate:(NSDate*)aDate;

@end

extern NSString* ELLIEAllLasersChanged;
extern NSString* ELLIEAllFibresChanged;
extern NSString* smellieRunDocsPresent;
extern NSString* ORELLIERunFinished;