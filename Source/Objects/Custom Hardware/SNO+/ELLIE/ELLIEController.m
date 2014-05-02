//
//  ELLIEController.m
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//

#import "ELLIEController.h"
#import "ELLIEModel.h"

@implementation ELLIEController

//@synthesize smellieRunSettingsFromGUI;

//smellie maxiumum trigger frequency

//Set up functions
-(id)init
{
    self = [super initWithWindowNibName:@"ellie"];
    
    //Make sure these buttons are working on start up for Smellie
    [smellieNumIntensitySteps setEnabled:YES];
    [smellieMaxIntensity setEnabled:YES];
    [smellieMinIntensity setEnabled:YES];
    [smellieNumTriggersPerLoop setEnabled:YES];
    [smellieOperationMode setEnabled:YES];
    [smellieOperatorName setEnabled:YES];
    [smellieTriggerFrequency setEnabled:YES];
    [smellieRunName setEnabled:YES];
    [smellie405nmLaserButton setEnabled:YES];
    [smellie375nmLaserButton setEnabled:YES];
    [smellie440nmLaserButton setEnabled:YES];
    [smellie500nmLaserButton setEnabled:YES];
    [smellieFibreButtonFS007 setEnabled:YES];
    [smellieFibreButtonFS107 setEnabled:YES];
    [smellieFibreButtonFS207 setEnabled:YES];
    [smellieFibreButtonFS025 setEnabled:YES];
    [smellieFibreButtonFS125 setEnabled:YES];
    [smellieFibreButtonFS225 setEnabled:YES];
    [smellieFibreButtonFS037 setEnabled:YES];
    [smellieFibreButtonFS137 setEnabled:YES];
    [smellieFibreButtonFS237 setEnabled:YES];
    [smellieFibreButtonFS055 setEnabled:YES];
    [smellieFibreButtonFS155 setEnabled:YES];
    [smellieFibreButtonFS255 setEnabled:YES];
    [smellieAllFibresButton setEnabled:YES];
    [smellieAllLasersButton setEnabled:YES];
    [smellieMakeNewRunButton setEnabled:NO];
    
    //NSMutableDictionary *smellieRunInfo = [[NSMutableDictionary alloc] init];
    
    //NSLog(@"Value of smellie %@",[smellieRunInfo objectForKey:@"run_name"]);
    
    //[smellieRunName release];
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void) updateWindow
{
	[super updateWindow];
    
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[super registerNotificationObservers];
    
    //we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(setAllLasersAction:)
						 name : ELLIEAllLasersChanged
					   object : model];
    
    [notifyCenter addObserver : self
					 selector : @selector(setAllFibresAction:)
						 name : ELLIEAllFibresChanged
					   object : model];
    
}

//SMELLIE functions -------------------------

//enables all lasers if the "all lasers" box is enabled 
-(IBAction)setAllLasersAction:(id)sender;
{
    if([smellieAllLasersButton state] == 1){
        //Set the state of all Lasers to 1
        [smellie375nmLaserButton setState:1];
        [smellie405nmLaserButton setState:1];
        [smellie440nmLaserButton setState:1];
        [smellie500nmLaserButton setState:1];
    }
    
}

//enables all fibres if the "all fibres" box is enabled 
-(IBAction)setAllFibresAction:(id)sender;
{
    if([smellieAllFibresButton state] == 1){
        [smellieFibreButtonFS007 setState:1];
        [smellieFibreButtonFS107 setState:1];
        [smellieFibreButtonFS207 setState:1];
        [smellieFibreButtonFS025 setState:1];
        [smellieFibreButtonFS125 setState:1];
        [smellieFibreButtonFS225 setState:1];
        [smellieFibreButtonFS037 setState:1];
        [smellieFibreButtonFS137 setState:1];
        [smellieFibreButtonFS237 setState:1];
        [smellieFibreButtonFS055 setState:1];
        [smellieFibreButtonFS155 setState:1];
        [smellieFibreButtonFS255 setState:1];
    }
}

//removes the tick in case for "all lasers" if any of the lasers and not pressed
-(IBAction)allLaserValidator:(id)sender
{
    if( ([smellie375nmLaserButton state] != 1) || ([smellie405nmLaserButton state] != 1) || ([smellie440nmLaserButton state] != 1) || ([smellie500nmLaserButton state] != 1))
    {
        [smellieAllLasersButton setState:0];
    }
    
}

//removes the tick in case for "all fibres" if any of the lasers and not pressed
-(IBAction)allFibreValidator:(id)sender
{
    if( ([smellieFibreButtonFS007 state] != 1) || ([smellieFibreButtonFS107 state] != 1) || ([smellieFibreButtonFS025 state] != 1) || ([smellieFibreButtonFS125 state] != 1) || ([smellieFibreButtonFS225 state] != 1) || ([smellieFibreButtonFS037 state] != 1) || ([smellieFibreButtonFS137 state] != 1) || ([smellieFibreButtonFS237 state] != 1) || ([smellieFibreButtonFS055 state] != 1) || ([smellieFibreButtonFS155 state] != 1) || ([smellieFibreButtonFS255 state] != 1))
    {
        [smellieAllFibresButton setState:0];
    }
    
}

//Force the string value to be less than 100 and a valid value
-(IBAction)validateLaserMaxIntensity:(id)sender;
{
    NSString* maxLaserIntString = [smellieMaxIntensity stringValue];
    int maxLaserIntensity;
    
    @try{
        maxLaserIntensity  = [maxLaserIntString intValue];
    }
    @catch (NSException *e) {
        maxLaserIntensity = 100;
        [smellieMaxIntensity setIntValue:maxLaserIntensity];
        NSLog(@"SMELLIE_RUN_BUILDER: Maximum Laser intensity is invalid. Setting to 100%% by Default\n");
    }
    
    if((maxLaserIntensity < 0) ||(maxLaserIntensity > 100))
    {
        maxLaserIntensity = 100;
        [smellieMaxIntensity setIntValue:maxLaserIntensity];
        NSLog(@"SMELLIE_RUN_BUILDER: Maximum Laser intensity is too high (or too low). Setting to 100%% by Default\n");
    }
}

-(IBAction)validateLaserMinIntensity:(id)sender;
{
    NSString* minLaserIntString = [smellieMinIntensity stringValue];
    int minLaserIntensity;
    
    @try{
        minLaserIntensity  = [minLaserIntString intValue];
    }
    @catch (NSException *e) {
        minLaserIntensity = 20;
        [smellieMinIntensity setIntValue:minLaserIntensity];
        NSLog(@"SMELLIE_RUN_BUILDER: Minimum Laser intensity is invalid. Setting to 20%% by Default\n");
    }
    
    if((minLaserIntensity < 0) || (minLaserIntensity > 100))
    {
        minLaserIntensity = 0;
        [smellieMinIntensity setIntValue:minLaserIntensity];
        NSLog(@"SMELLIE_RUN_BUILDER: Minimum Laser intensity is too low or high. Setting to 0%% by Default\n");
    }
}

//The number of intensity steps cannot be more than the maximum intensity less minimum intensity 
-(IBAction)validateIntensitySteps:(id)sender;
{
    int numberOfIntensitySteps;
    int maxNumberOfSteps;
    
    @try{
        numberOfIntensitySteps = [smellieNumIntensitySteps intValue];
        maxNumberOfSteps = [smellieMaxIntensity intValue] - [smellieMinIntensity intValue];
    }
    @catch(NSException *e){
        NSLog(@"SMELLIE_RUN_BUILDER: Number of Intensity steps is invalid. Setting the number of steps to 1\n");
        numberOfIntensitySteps = 1;
        [smellieNumIntensitySteps setIntValue:numberOfIntensitySteps];
    }
    
    if( (numberOfIntensitySteps > maxNumberOfSteps)|| (numberOfIntensitySteps < 1)){
        numberOfIntensitySteps = maxNumberOfSteps;
        [smellieNumIntensitySteps setIntValue:maxNumberOfSteps];
        NSLog(@"SMELLIE_RUN_BUILDER: Number of Intensity steps is invalid. Setting the the maximum correct value\n");
    }
    
}

//checks to make sure the trigger frequency isn't too high 
-(IBAction)validateSmellieTriggerFrequency:(id)sender;
{
    int triggerFrequency;
    //maxmium allowed trigger frequency in the GUI
    int maxmiumTriggerFrequency = 1000;
    
    @try{
        triggerFrequency = [smellieTriggerFrequency intValue];
    }
    @catch(NSException *e){
        NSLog(@"SMELLIE_RUN_BUILDER: Trigger Frequency is invalid. Setting the frequency to 10 Hz\n");
        triggerFrequency = 10;
        [smellieTriggerFrequency setIntValue:triggerFrequency];
    }
    
    if( (triggerFrequency > maxmiumTriggerFrequency) || (triggerFrequency < 0)){
        [smellieTriggerFrequency setIntValue:10];
        NSLog(@"SMELLIE_RUN_BUILDER: Trigger Frequency is invalid. Setting the frequency to 10 Hz\n");
    }
}

-(IBAction)validateNumTriggersPerStep:(id)sender;
{
    int numberTriggersPerStep;
    //maxmium allowed number of triggers per loop
    int maximumNumberTriggersPerStep = 100000;
    
    @try{
        numberTriggersPerStep = [smellieNumTriggersPerLoop intValue];
    }
    @catch(NSException *e){
        NSLog(@"SMELLIE_RUN_BUILDER: Triggers per loop is invalid. Setting to 100\n");
        [smellieNumTriggersPerLoop setIntValue:100];
    }
    
    if( (numberTriggersPerStep > maximumNumberTriggersPerStep) || (numberTriggersPerStep < 0)){
        NSLog(@"SMELLIE_RUN_BUILDER: Triggers per loop is invalid. Setting to 100\n");
        [smellieNumTriggersPerLoop setIntValue:100];
    }
}

-(IBAction)validationSmellieRunAction:(id)sender;
{
    //NSLog(@" output: %@",[model callPythonScript:@"/Users/jonesc/testScript.py" withCmdLineArgs:nil]);
    [smellieMakeNewRunButton setEnabled:NO];
    
    //Error messages
    NSString* smellieRunErrorString = [[NSString alloc] initWithString:@"Unable to Validate. Check all fields are entered and see Status and Error Log" ];
    
    NSNumber* validationErrorFlag = [NSNumber numberWithInt:1];
    //validationErrorFlag = [NSNumber numberWithInt:1];
    
    //check the Operator has entered their name 
    if([[smellieOperatorName stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a Operator Name \n");
    }

    //TODO:Check there are no files with the same name (although each will have a unique id)
    //check the Operator has a valid run name 
    else if([[smellieRunName stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a Run Name\n");
    }
    
    //check that an operation mode has been given 
    else if([[smellieOperationMode stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter an Operation Mode \n");
    }
    
    //check the maximum laser intensity is given
    else if([[smellieMaxIntensity stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter an Maxmium Laser Intensity\n");
    }
    
    //check the minimum laser intensity is given
    else if([[smellieMinIntensity stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter an Minimum Laser Intensity\n");
    }
    
    //check the intensity step is given 
    else if([[smellieNumIntensitySteps stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a number of intensity steps\n");
    }
    
    //check the trigger frequency is given 
    else if([[smellieTriggerFrequency stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a trigger frequency\n");
    }
    
    //check the trigger frequency is given
    else if([[smellieNumTriggersPerLoop stringValue] length] == 0){
        NSLog(@"SMELLIE_RUN_BUILDER:Please enter a number of triggers per loop\n");
    }
    
    else{
        validationErrorFlag = [NSNumber numberWithInt:2];
    }
    
    //If any errors has been detected in the validation 
    if([validationErrorFlag intValue] == 1){
        [smellieRunErrorTextField setStringValue:smellieRunErrorString];
        [smellieMakeNewRunButton setEnabled:NO]; //Disable the user from this button
    }
    else if ([validationErrorFlag intValue] == 2){
        [smellieRunErrorTextField setStringValue:@"No Error"];
        [smellieMakeNewRunButton setEnabled:YES]; //Enable the user from this button

        //We need to block out all the textFields until the run has been submitted!
        [smellieNumIntensitySteps setEnabled:NO];
        [smellieMaxIntensity setEnabled:NO];
        [smellieMinIntensity setEnabled:NO];
        [smellieNumTriggersPerLoop setEnabled:NO];
        [smellieOperationMode setEnabled:NO];
        [smellieOperatorName setEnabled:NO];
        [smellieTriggerFrequency setEnabled:NO];
        [smellieRunName setEnabled:NO];
        [smellie405nmLaserButton setEnabled:NO];
        [smellie375nmLaserButton setEnabled:NO];
        [smellie440nmLaserButton setEnabled:NO];
        [smellie500nmLaserButton setEnabled:NO];
        [smellieFibreButtonFS007 setEnabled:NO];
        [smellieFibreButtonFS107 setEnabled:NO];
        [smellieFibreButtonFS207 setEnabled:NO];
        [smellieFibreButtonFS025 setEnabled:NO];
        [smellieFibreButtonFS125 setEnabled:NO];
        [smellieFibreButtonFS225 setEnabled:NO];
        [smellieFibreButtonFS037 setEnabled:NO];
        [smellieFibreButtonFS137 setEnabled:NO];
        [smellieFibreButtonFS237 setEnabled:NO];
        [smellieFibreButtonFS055 setEnabled:NO];
        [smellieFibreButtonFS155 setEnabled:NO];
        [smellieFibreButtonFS255 setEnabled:NO];
        [smellieAllFibresButton setEnabled:NO];
        [smellieAllLasersButton setEnabled:NO];
        
    }
    else{
        NSLog(@"SMELLIE_BUILD_RUN: Unknown invalid Entry or no entries sent\n");
    }
    
    [smellieRunErrorString release];
    
    //Example functions of how this values can be pulled 
    //state 1 is ON, state 0 is OFF for these buttons
    //NSLog(@"375 laser setting %i \n",[smellie375nmLaserButton state]);
    //NSLog(@"Entry into the Operator Field %@ \n",[smellieOperationMode stringValue]);
    
    //[model validationSmellieSettings];
}

-(IBAction)makeNewSmellieRun:(id)sender
{
    NSAutoreleasePool* smellieSettingsPool = [[NSAutoreleasePool alloc] init];
    
    NSMutableDictionary * smellieRunSettingsFromGUI = [NSMutableDictionary dictionaryWithCapacity:100];
    
    //Build Objects to store values
    NSString * smellieOperatorNameString = [NSString stringWithString:[smellieOperatorName stringValue]];
    NSString * smellieRunNameString = [NSString stringWithString:[smellieRunName stringValue]];
    NSString * smellieOperatorModeString = [NSString stringWithString:[smellieOperationMode stringValue]];
    
    NSNumber * smellieMaxIntensityNum = [NSNumber numberWithInt:[smellieMaxIntensity intValue]];
    NSNumber * smellieMinIntensityNum = [NSNumber numberWithInt:[smellieMinIntensity intValue]];
    NSNumber * smellieNumIntensityStepsNum = [NSNumber numberWithInt:[smellieNumIntensitySteps intValue]];
    NSNumber * smellieTriggerFrequencyNum = [NSNumber numberWithInt:[smellieTriggerFrequency intValue]];
    NSNumber * smellieNumTriggersPerLoopNum = [NSNumber numberWithInt:[smellieNumTriggersPerLoop intValue]];
    
    NSNumber * smellie405nmLaserButtonNum = [NSNumber numberWithInteger:[smellie405nmLaserButton state]];
    NSNumber * smellie375nmLaserButtonNum = [NSNumber numberWithInteger:[smellie375nmLaserButton state]];
    NSNumber * smellie440nmLaserButtonNum = [NSNumber numberWithInteger:[smellie440nmLaserButton state]];
    NSNumber * smellie500nmLaserButtonNum = [NSNumber numberWithInteger:[smellie500nmLaserButton state]];
    
    NSNumber * smellieFibreButtonFS007Num = [NSNumber numberWithInteger:[smellieFibreButtonFS007 state]];
    NSNumber * smellieFibreButtonFS107Num = [NSNumber numberWithInteger:[smellieFibreButtonFS107 state]];
    NSNumber * smellieFibreButtonFS207Num = [NSNumber numberWithInteger:[smellieFibreButtonFS207 state]];
    NSNumber * smellieFibreButtonFS025Num = [NSNumber numberWithInteger:[smellieFibreButtonFS025 state]];
    NSNumber * smellieFibreButtonFS125Num = [NSNumber numberWithInteger:[smellieFibreButtonFS125 state]];
    NSNumber * smellieFibreButtonFS225Num = [NSNumber numberWithInteger:[smellieFibreButtonFS225 state]];
    NSNumber * smellieFibreButtonFS037Num = [NSNumber numberWithInteger:[smellieFibreButtonFS037 state]];
    NSNumber * smellieFibreButtonFS137Num = [NSNumber numberWithInteger:[smellieFibreButtonFS137 state]];
    NSNumber * smellieFibreButtonFS237Num = [NSNumber numberWithInteger:[smellieFibreButtonFS237 state]];
    NSNumber * smellieFibreButtonFS055Num = [NSNumber numberWithInteger:[smellieFibreButtonFS055 state]];
    NSNumber * smellieFibreButtonFS155Num = [NSNumber numberWithInteger:[smellieFibreButtonFS155 state]];
    NSNumber * smellieFibreButtonFS255Num = [NSNumber numberWithInteger:[smellieFibreButtonFS255 state]];
    
    
    [smellieRunSettingsFromGUI setObject:smellieOperatorNameString forKey:@"operator_name"];
    [smellieRunSettingsFromGUI setObject:smellieRunNameString forKey:@"run_name"];
    [smellieRunSettingsFromGUI setObject:smellieOperatorModeString forKey:@"operation_mode"];
    [smellieRunSettingsFromGUI setObject:smellieMaxIntensityNum forKey:@"max_laser_intensity"];
    [smellieRunSettingsFromGUI setObject:smellieMinIntensityNum forKey:@"min_laser_intensity"];
    [smellieRunSettingsFromGUI setObject:smellieNumIntensityStepsNum forKey:@"num_intensity_steps"];
    [smellieRunSettingsFromGUI setObject:smellieTriggerFrequencyNum forKey:@"trigger_frequency"];
    [smellieRunSettingsFromGUI setObject:smellieNumTriggersPerLoopNum forKey:@"triggers_per_loop"];
    [smellieRunSettingsFromGUI setObject:smellie375nmLaserButtonNum forKey:@"375nm_laser_on"];
    [smellieRunSettingsFromGUI setObject:smellie405nmLaserButtonNum forKey:@"405nm_laser_on"];
    [smellieRunSettingsFromGUI setObject:smellie440nmLaserButtonNum forKey:@"440nm_laser_on"];
    [smellieRunSettingsFromGUI setObject:smellie500nmLaserButtonNum forKey:@"500nm_laser_on"];
    
    //Fill the SMELLIE Fibre Array information
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS007Num forKey:@"FS007"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS107Num forKey:@"FS107"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS207Num forKey:@"FS207"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS025Num forKey:@"FS025"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS125Num forKey:@"FS125"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS225Num forKey:@"FS225"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS037Num forKey:@"FS037"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS137Num forKey:@"FS137"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS237Num forKey:@"FS237"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS055Num forKey:@"FS055"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS155Num forKey:@"FS155"];
    [smellieRunSettingsFromGUI setObject:smellieFibreButtonFS255Num forKey:@"FS255"];
    
    NSLog(@" operator_name (string) %@\n",[smellieRunSettingsFromGUI objectForKey:@"operator_name"]);
    NSLog(@" max intensity (string) %@\n",[smellieRunSettingsFromGUI objectForKey:@"max_laser_intensity"]);
    NSLog(@" laser state (string) %@\n",[smellieRunSettingsFromGUI objectForKey:@"405nm_laser_on"]);
    
    [model smellieDBpush:smellieRunSettingsFromGUI];
    
    //Re-enable these buttons for editing
    [smellieNumIntensitySteps setEnabled:YES];
    [smellieMaxIntensity setEnabled:YES];
    [smellieMinIntensity setEnabled:YES];
    [smellieNumTriggersPerLoop setEnabled:YES];
    [smellieOperationMode setEnabled:YES];
    [smellieOperatorName setEnabled:YES];
    [smellieTriggerFrequency setEnabled:YES];
    [smellieRunName setEnabled:YES];
    [smellie405nmLaserButton setEnabled:YES];
    [smellie375nmLaserButton setEnabled:YES];
    [smellie440nmLaserButton setEnabled:YES];
    [smellie500nmLaserButton setEnabled:YES];
    [smellieFibreButtonFS007 setEnabled:YES];
    [smellieFibreButtonFS107 setEnabled:YES];
    [smellieFibreButtonFS207 setEnabled:YES];
    [smellieFibreButtonFS025 setEnabled:YES];
    [smellieFibreButtonFS125 setEnabled:YES];
    [smellieFibreButtonFS225 setEnabled:YES];
    [smellieFibreButtonFS037 setEnabled:YES];
    [smellieFibreButtonFS137 setEnabled:YES];
    [smellieFibreButtonFS237 setEnabled:YES];
    [smellieFibreButtonFS055 setEnabled:YES];
    [smellieFibreButtonFS155 setEnabled:YES];
    [smellieFibreButtonFS255 setEnabled:YES];
    [smellieAllFibresButton setEnabled:YES];
    [smellieAllLasersButton setEnabled:YES];
    [smellieMakeNewRunButton setEnabled:NO];
    
    [smellieSettingsPool release];
    
    
}

//Custom Command for Smellie
-(IBAction)executeSmellieCmdDirectAction:(id)sender
{
    NSString * cmd = [[NSString alloc] init];
    NSLog(@"CMD %@",[executeCmdBox stringValue]);
    NSLog(@"CMD %i",[executeCmdBox indexOfSelectedItem]);
    
    int cmdIndex = [executeCmdBox indexOfSelectedItem];
    
    if(cmdIndex == 0){
        cmd = @"10";
    }
    else if (cmdIndex == 1){
        cmd = @"20";
    }
    else if (cmdIndex == 2){
        cmd = @"30";
    }
    else if (cmdIndex == 3){
        cmd = @"2050";
    }
    else if (cmdIndex == 4){
        cmd = @"40";
    }
    else if (cmdIndex == 5){
        cmd = @"50";
    }
    else if(cmdIndex == 6){
        cmd = @"60";
    }
    else if(cmdIndex == 7){
        cmd = @"70";
    }
    else if(cmdIndex == 8){
        cmd = @"80";
    }
    
    
    //NSString * cmd = [NSString stringWithString:[smellieDirectCmd stringValue]];
    NSString * arg1 = [NSString stringWithString:[smellieDirectArg1 stringValue]];
    NSString * arg2 = [NSString stringWithString:[smellieDirectArg2 stringValue]];
    [model sendCustomSmellieCmd:cmd withArgument1:arg1 withArgument2:arg2];
}

//TELLIE functions -------------------------



@end