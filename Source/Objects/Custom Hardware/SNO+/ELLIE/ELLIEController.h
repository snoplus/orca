//
//  ELLIEController.h
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//  Revision history:
//  Ed Leming 04/01/2016 -  Removed global variables to move logic to
//                          ELLIEModel
//

#import <Foundation/Foundation.h>

@interface ELLIEController : OrcaObjectController <NSTextFieldDelegate>{

    //TAB Views
    IBOutlet NSTabView *ellieTabView;
    IBOutlet NSTabView *tellieTabView;
    IBOutlet NSTabView *tellieOperatorTabView;
    //TabViewItems
    IBOutlet NSTabViewItem *tellieTViewItem;
    IBOutlet NSTabViewItem *smellieTViewItem;
    IBOutlet NSTabViewItem *amellieTViewItem;
    //TabViewItems
    IBOutlet NSTabViewItem *tellieFireFibreTViewItem;
    IBOutlet NSTabViewItem *tellieBuildConfigTViewItem;
    IBOutlet NSTabViewItem *tellieGeneralOpTViewItem;
    IBOutlet NSTabViewItem *tellieExpertOpTViewItem;
    
    //SMELLIE interface --------------------------------------
    //Storage of run information
    //NSMutableDictionary* smellieRunSettingsFromGUI;
    
    //check box buttons for lasers
    IBOutlet NSButton* smellieSuperkLaserButton;   //check box for superK
    IBOutlet NSButton* smellie375nmLaserButton;    //check box for 375nm Laser
    IBOutlet NSButton* smellie405nmLaserButton;    //check box for 405nm Laser
    IBOutlet NSButton* smellie440nmLaserButton;    //check box for 440nm Laser
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
    
    // Run settings
    IBOutlet NSTextField* smellieOperatorName;          //Operator Name Field
    IBOutlet NSTextField* smellieRunName;               //Run Name Field
    IBOutlet NSComboBox* smellieOperationMode;          //Operation mode (master or slave)
    IBOutlet NSTextField* smellieMaxIntensity;          //maximum intensity of lasers in run
    IBOutlet NSTextField* smellieMinIntensity;          //minimum intensity of lasers in run
    IBOutlet NSTextField* smellieNumIntensitySteps;     //number of intensities to step through
    IBOutlet NSTextField* smellieMinWavelength;         //Bottom edge of the shortest wavelength window
    IBOutlet NSTextField* smellieNumWavelengthSteps;    //Number of steps from shortest wavelength window
    IBOutlet NSTextField* smellieWavelengthStepSize;    //Step size from bottom edge of one window to the bottom edge of the next
    IBOutlet NSTextField* smellieWavelengthWinWidth;    //Width of a wavelength window (top_edge - bottom_edge)
    IBOutlet NSTextField* smellieNumTriggersPerLoop;
    IBOutlet NSTextField* smellieTriggerFrequency;      //trigger frequency of SMELLIE in Hz
    // Not sure about these...
    IBOutlet NSTextField *smellieDirectArg1;
    IBOutlet NSButton *smellieDirectExecuteCmd;
    IBOutlet NSTextFieldCell *smellieDirectArg2;
    IBOutlet NSTextField *smellieDirectCmd;
    IBOutlet NSComboBox *executeCmdBox;
    //Control Button
    IBOutlet NSButton* smellieMakeNewRunButton;         //make a new smellie run

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
    
    ////////////////////
    //General interface
    IBOutlet NSTextField* tellieGeneralNodeTf;
    IBOutlet NSTextField* tellieGeneralPhotonsTf;
    IBOutlet NSTextField* tellieGeneralTriggerDelayTf;
    IBOutlet NSTextField *tellieGeneralNoPulsesTf;
    IBOutlet NSTextField *tellieGeneralFreqTf;

    IBOutlet NSPopUpButton* tellieGeneralFibreSelectPb;
    IBOutlet NSPopUpButton* tellieGeneralOperationModePb; //Operation mode (master or slave)
    
    IBOutlet NSButton *tellieGeneralFireButton;
    IBOutlet NSButton *tellieGeneralStopButton;
    IBOutlet NSButton *tellieGeneralValidateSettingsButton;
    
    IBOutlet NSTextField *tellieGeneralValidationStatusTf;
    IBOutlet NSTextField *tellieGeneralRunStatusTf;
    
    ////////////////////
    //Expert interface
    IBOutlet NSTextField *tellieChannelTf;
    IBOutlet NSTextField *telliePulseWidthTf;
    IBOutlet NSTextField *telliePulseFreqTf;
    IBOutlet NSTextField *telliePulseHeightTf;
    IBOutlet NSTextField *tellieFibreDelayTf;
    IBOutlet NSTextField *tellieTriggerDelayTf;
    IBOutlet NSTextField *tellieNoPulsesTf;
    IBOutlet NSTextField *telliePhotonsTf;
    
    IBOutlet NSTextField *tellieExpertNodeTf;
    IBOutlet NSPopUpButton *tellieExpertFibreSelectPb;
    IBOutlet NSPopUpButton *tellieExpertOperationModePb; //Operation mode (master or slave)
    
    IBOutlet NSTextField *tellieExpertValidationStatusTf;
    IBOutlet NSTextField *tellieExpertRunStatusTf;
    
    IBOutlet NSButton *tellieExpertFireButton;
    IBOutlet NSButton *tellieExpertStopButton;
    IBOutlet NSButton *tellieExpertValidateSettingsButton;
   
    // Instance variables
    NSThread *tellieThread;
    NSButton *tellieExpertConvertAction;
    NSWindowController* _nodeMapWC;
    NSMutableDictionary* _guiFireSettings;
    NSThread* _tellieThread;
    NSThread* _smellieThread;
}

// Properties
@property (nonatomic,strong) NSWindowController* nodeMapWC;
@property (nonatomic,strong) NSMutableDictionary* guiFireSettings;
@property (nonatomic, strong) NSThread* tellieThread;
@property (nonatomic, strong) NSThread* smellieThread;

-(id)init;
-(void)dealloc;
-(void)updateWindow;
-(void)registerNotificationObservers;
-(void)awakeFromNib;
-(BOOL)isNumeric:(NSString *)s;

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

//General tab
-(IBAction)tellieGeneralValidateSettingsAction:(id)sender;
-(IBAction)tellieGeneralFireAction:(id)sender;
-(IBAction)tellieGeneralStopAction:(id)sender;
-(IBAction)tellieNodeMapAction:(id)sender;
-(IBAction)tellieGeneralFibreNameAction:(NSPopUpButton *)sender;
-(IBAction)tellieGeneralModeAction:(NSPopUpButton *)sender;


//Expert tab
-(IBAction)tellieExpertFireAction:(id)sender;
-(IBAction)tellieExpertStopAction:(id)sender;
-(IBAction)tellieExpertValidateSettingsAction:(id)sender;
-(IBAction)tellieExpertAutoFillAction:(id)sender;
-(IBAction)tellieExpertFibreNameAction:(NSPopUpButton *)sender;
-(IBAction)tellieExpertModeAction:(NSPopUpButton *)sender;

//Vaidation functions
-(NSString*)validateGeneralTellieNode:(NSString *)currentText;
-(NSString*)validateGeneralTelliePhotons:(NSString *)currentText;
-(NSString*)validateGeneralTellieTriggerDelay:(NSString *)currentText;
-(NSString*)validateGeneralTellieNoPulses:(NSString *)currentText;
-(NSString*)validateGeneralTelliePulseFreq:(NSString *)currentText;
//Expert gui
-(NSString*)validateTellieChannel:(NSString *)currentText;
-(NSString*)validateTelliePulseWidth:(NSString *)currentText;
-(NSString*)validateTelliePulseFreq:(NSString *)currentText;
-(NSString*)validateTelliePulseHeight:(NSString *)currentText;
-(NSString*)validateTellieFibreDelay:(NSString *)currentText;
-(NSString*)validateTellieTriggerDelay:(NSString *)currentText;
-(NSString*)validateTellieNoPulses:(NSString *)currentText;

//-(void)validateTellieGeneralSettings:(NSNotification *)note;
//-(void)validateTellieExpertSettings:(NSNotification *)note;
-(void)tellieRunStarted:(NSNotification *)aNote;
-(void)tellieRunFinished:(NSNotification *)aNote;
-(BOOL)isTellieRunning;
-(void)initialiseTellie;

@end

extern NSString* ORTELLIERunStart;
extern NSString* ORSMELLIERunFinished;
extern NSString* ORTELLIERunFinished;

