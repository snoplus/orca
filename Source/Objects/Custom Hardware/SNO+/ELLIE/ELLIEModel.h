//
//  ELLIEModel.h
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//

#import <Foundation/Foundation.h>
#import <ELLIEController.h>

@class ORCouchDB;
@class ORRunModel;
@class ORRunController;

@interface ELLIEModel :  OrcaObject{
    NSMutableDictionary* smellieRunSettings;
    NSMutableDictionary* currentOrcaSettingsForSmellie;
    NSMutableDictionary* tellieRunDoc;
    NSTask* exampleTask;
    NSMutableDictionary* smellieRunHeaderDocList;
    ORRunModel* runControl;
    ORRunController* theRunController;
    NSMutableArray *smellieSubRunInfo;
    bool _smellieDBReadInProgress;
    float pulseByPulseDelay;
    
    //tellie settings
    NSMutableDictionary * tellieSubRunSettings;
    
}

@property (nonatomic,retain) NSMutableDictionary* tellieSubRunSettings;
@property (nonatomic,retain) NSMutableDictionary* smellieRunSettings;
@property (nonatomic,retain) NSMutableDictionary* currentOrcaSettingsForSmellie;
@property (nonatomic,retain) NSMutableDictionary* tellieRunDoc;
@property (nonatomic,retain) NSTask* exampleTask;
@property (nonatomic,retain) NSMutableDictionary* smellieRunHeaderDocList;
@property (nonatomic,retain) NSMutableArray* smellieSubRunInfo;
@property (nonatomic,assign) bool smellieDBReadInProgress;
@property (nonatomic,assign) float pulseByPulseDelay;

-(void) setUpImage;
-(void) makeMainController;
-(void) wakeUp;
-(void) sleep;
-(void) dealloc;
-(void) registerNotificationObservers;
- (ORCouchDB*) generalDBRef:(NSString*)aCouchDb;

//This is called by ORCouchDB.h class as a returning delegate
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp;

/*This function calls a python script: 
    pythonScriptFilePath - this is the python script file path
    withCmdLineArgs - these are the arguments for the python script*/
-(NSString*)callPythonScript:(NSString*)pythonScriptFilePath withCmdLineArgs:(NSArray*)commandLineArgs;

//starts a SMELLIE run with given parameters and submits the smellie run file to the database
-(void) startSmellieRun:(NSDictionary*)smellieSettings;
-(void) stopSmellieRun;
-(void) smellieDBpush:(NSMutableDictionary*)dbDic;
-(void) smellieConfigurationDBpush:(NSMutableDictionary*)dbDic;
-(void)startSmellieRunInBackground:(NSDictionary*)smellieSettings;

//SMELLIE Control Functions
-(void)setSmellieSafeStates;
-(void)setLaserSwitch:(NSString*)laserSwitchChannel;
-(void)setFibreSwitch:(NSString*)fibreSwitchInputChannel withOutputChannel:(NSString*)fibreSwitchOutputChannel;
-(void)setLaserIntensity:(NSString*)laserIntensity;
-(void)setLaserSoftLockOn;
-(void)setLaserSoftLockOff;
-(void)setSmellieMasterMode:(NSString*)triggerFrequency withNumOfPulses:(NSString*)numOfPulses;
-(void)sendCustomSmellieCmd:(NSString*)customCmd withArgument1:(NSString*)customArgument1 withArgument2:(NSString*)customArgument2;
-(void)testFunction;
-(void)setLaserFrequency20Mhz;
-(void)fetchSmellieConfigurationInformation;

//TELLIE Control Functions
-(void) pollTellieFibre;
-(void) fireTellieFibre:(NSMutableDictionary*)fireCommands;
-(void) stopTellieFibre:(NSArray*)fireCommands;
-(void) startTellieRun;
-(void) stopTellieRun;


@end

extern NSString* ELLIEAllLasersChanged;
extern NSString* ELLIEAllFibresChanged;
extern NSString* smellieRunDocsPresent;
extern NSString* ORELLIERunFinished;