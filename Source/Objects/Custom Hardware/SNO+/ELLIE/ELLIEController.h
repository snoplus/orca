//
//  ELLIEController.h
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//

#import <Foundation/Foundation.h>

@interface ELLIEController : OrcaObjectController {
    
    //SMELLIE interface --------------------------------------
    
    //Storage of run information
    //NSMutableDictionary* smellieRunSettingsFromGUI;
    
    //check box buttons for lasers
    IBOutlet NSButton* smellie375nmLaserButton;    //check box for 375nm Laser
    IBOutlet NSButton* smellie405nmLaserButton;    //check box for 405nm Laser
    IBOutlet NSButton* smellie440nmLaserButton;    //check box for 440nm Laser
    IBOutlet NSTextField *smellieDirectArg1;
    IBOutlet NSButton *smellieDirectExecuteCmd;
    IBOutlet NSTextFieldCell *smellieDirectArg2;
    IBOutlet NSTextField *smellieDirectCmd;
    IBOutlet NSButton* smellie500nmLaserButton;    //check box for 500nm Laser
    IBOutlet NSButton* smellieAllLasersButton;     //check box for all Lasers set
    
    //check box buttons for fibres (fibre id is in variable name)
    IBOutlet NSButton* smellieFibreButtonFS007;
    IBOutlet NSButton* smellieFibreButtonFS107;
    IBOutlet NSButton* smellieFibreButtonFS207;
    IBOutlet NSButton* smellieFibreButtonFS025;
    IBOutlet NSButton* smellieFibreButtonFS125;
    IBOutlet NSButton* smellieFibreButtonFS225;
    IBOutlet NSButton* smellieFibreButtonFS037;
    IBOutlet NSButton* smellieFibreButtonFS137;
    IBOutlet NSButton* smellieFibreButtonFS237;
    IBOutlet NSButton* smellieFibreButtonFS055;
    IBOutlet NSButton* smellieFibreButtonFS155;
    IBOutlet NSButton* smellieFibreButtonFS255;
    IBOutlet NSButton* smellieAllFibresButton;    
    
    //More Run Information
    IBOutlet NSTextField* smellieOperatorName;      //Operator Name Field
    IBOutlet NSTextField* smellieRunName;           //Run Name Field
    IBOutlet NSComboBox* smellieOperationMode;      //Operation mode (master or slave)
    IBOutlet NSTextField* smellieMaxIntensity;      //maximum intensity of lasers in run
    IBOutlet NSTextField* smellieMinIntensity;      //minimum intensity of lasers in run
    IBOutlet NSTextField* smellieNumIntensitySteps;     //number of intensities to step through
    IBOutlet NSTextField* smellieTriggerFrequency;  //trigger frequency of SMELLIE in Hz
    IBOutlet NSTextField* smellieNumTriggersPerLoop;    //number of triggers to be sent per iteration
    
    IBOutlet NSComboBox *executeCmdBox;
    //Control Button
    IBOutlet NSButton* smellieMakeNewRunButton; //make a new smellie run 
    
    //Error Fields
    IBOutlet NSTextField* smellieRunErrorTextField; //new run error text field 
    
    
    //SMELLIE Configuration Fields
    
    IBOutlet NSComboBox *smellieConfigSepiaInputChannel;
    IBOutlet NSComboBox* smellieConfigLaserHeadField;
    IBOutlet NSComboBox* smellieConfigAttenuatorField;
    IBOutlet NSComboBox* smellieConfigFsInputCh;
    IBOutlet NSComboBox* smellieConfigFsOutputCh;
    IBOutlet NSComboBox* smellieConfigDetectorFibreRef;
    IBOutlet NSTextField* smellieConfigSelfTestNoOfPulses;
    IBOutlet NSTextField* smellieConfigSelfTestNoOfPulsesPerLaser;
    IBOutlet NSTextField* smellieConfigSelfTestNiTriggerOutputPin;
    IBOutlet NSTextField* smellieConfigSelfTestNiTriggerInputPin;
    IBOutlet NSTextField* smellieConfigSelfTestLaserTriggerFreq;
    IBOutlet NSTextField* smellieConfigSelfTestPmtSampleRate;
    IBOutlet NSTextField *smellieConfigAttenutationFactor;
    
    IBOutlet NSButton *smellieConfigSubmitButton;
    IBOutlet NSTextField *smellieConfigGainControl;
    
    
    
    //TELLIE interface ------------------------------------------
    
    IBOutlet NSTextField *tellieChannelTf;
    IBOutlet NSTextField *telliePhotonsTf;
    IBOutlet NSTextField *telliePulseRateTf;
    IBOutlet NSTextField *telliePulseHeightTf;
    IBOutlet NSTextField *telliePulseWidthTf;
    IBOutlet NSTextField *tellieValidationStatusLabel;
    IBOutlet NSTextField *tellieRunStatusLabel;
    IBOutlet NSButton *tellieFireFibreButton;
    IBOutlet NSButton *telliePollButton;
    IBOutlet NSButton *tellieStopButton;    
    IBOutlet NSTextField *tellieFibreDelayTf;
    IBOutlet NSTextField *tellieTriggerDelayTf;
    
    IBOutlet NSButton *tellieValidateSettingsButton;
    
    IBOutlet NSButton *startTellieRunButton;
    IBOutlet NSButton *stopTellieRunButton;
    NSTextField *automaticallyChangeTellieTriggerInput;
    
    IBOutlet NSTextField * tellieNumofShots;
    
    IBOutlet NSTextField * tellieVariableDelay;
    
    NSThread *tellieThread;
}


//@property (nonatomic,retain) NSMutableDictionary* smellieRunSettingsFromGUI;
-(id)init;
-(void)dealloc;
-(void) updateWindow;
-(void) registerNotificationObservers;
-(BOOL) isNumeric:(NSString *)s;

//SMELLIE functions ----------------------------

//Button clicked to validate the new run type settings for smellie 
-(IBAction)setAllLasersAction:(id)sender;
-(IBAction)setAllFibresAction:(id)sender;
-(IBAction)validateLaserMaxIntensity:(id)sender;
-(IBAction)validateLaserMinIntensity:(id)sender;
-(IBAction)validateIntensitySteps:(id)sender;
-(IBAction)validateSmellieTriggerFrequency:(id)sender;
-(IBAction)validateNumTriggersPerStep:(id)sender;
-(IBAction)validationSmellieRunAction:(id)sender;
-(IBAction)allLaserValidator:(id)sender;
-(IBAction)makeNewSmellieRun:(id)sender;
-(IBAction)executeSmellieCmdDirectAction:(id)sender;

//TELLIE functions -----------------------------

-(IBAction)fireTellieFibreAction:(id)sender;
-(IBAction)pollTellieFibreAction:(id)sender;
-(IBAction)stopTellieFibreAction:(id)sender;
-(IBAction)validateTellieSettingsAction:(id)sender;
-(IBAction)startTellieRunAction:(id)sender;
-(IBAction)stopTellieRunAction:(id)sender;

-(BOOL) areTellieSettingsValid;
-(BOOL) isTellieRunning;
-(void) initialiseTellie;

@end

