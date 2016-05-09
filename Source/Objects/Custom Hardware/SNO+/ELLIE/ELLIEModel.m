//
//  ELLIEModel.m
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
//
//  Revision history:
//  Ed Leming 30/12/2015 - Memory updates and tidy up.
//
//

/*TODO:
        - Check the standard run name doesn't already exsists in the DB
        - read from and write to the local couch DB for both smellie and tellie
        - fix the intensity steps in SMELLIE such that negative values cannot be considered
        - add the TELLIE GUI Information
        - add the sockets for TELLIE to communicate with itself
        - add the AMELLIE GUI
        - make sure old files cannot be overridden 
        - add the configuration files GUI for all the ELLIE systems (LOW PRIORITY)
        - add the Emergency stop button 
        - make the SMELLIE Control functions private (eventually)
*/

#import "ELLIEModel.h"
#import "ORTaskSequence.h"
#import "ORCouchDB.h"
#import "SNOPModel.h"
#import "ORRunModel.h"
#import "SNOPController.h"
#import "ORMTCModel.h"
#import "ORRunController.h"
#import "ORMTC_Constants.h"
#import "SNOP_Run_Constants.h"

//tags to define that an ELLIE run file has been updated
#define kSmellieRunDocumentAdded   @"kSmellieRunDocumentAdded"
#define kSmellieRunDocumentUpdated   @"kSmellieRunDocumentUpdated"
#define kTellieRunDocumentAdded   @"kTellieRunDocumentAdded"
#define kTellieRunDocumentUpdated   @"kTellieRunDocumentUpdated"
#define kAmellieRunDocumentAdded   @"kAmellieRunDocumentAdded"
#define kAmellieRunDocumentUpdated   @"kAmellieRunDocumentUpdated"
#define kSmellieRunHeaderRetrieved   @"kSmellieRunHeaderRetrieved"
#define kSmellieConfigHeaderRetrieved @"kSmellieConfigHeaderRetrieved"

//sub run information tags
#define kSmellieSubRunDocumentAdded @"kSmellieSubRunDocumentAdded"

NSString* ELLIEAllLasersChanged = @"ELLIEAllLasersChanged";
NSString* ELLIEAllFibresChanged = @"ELLIEAllFibresChanged";
NSString* smellieRunDocsPresent = @"smellieRunDocsPresent";
NSString* ORELLIERunFinished = @"ORELLIERunFinished";


@interface ELLIEModel (private)
-(void) _pushEllieCustomRunToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile withDocType:(NSString*)aDocType;
-(void) _pushEllieConfigDocToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile withDocType:(NSString*)aDocType;
-(NSString*) stringDateFromDate:(NSDate*)aDate;
-(void) _pushSmellieRunDocument;
//-(void) _pushSmellieConfigDocument;
@end

@implementation ELLIEModel

@synthesize tellieFireParameters;
@synthesize tellieFibreMapping;
@synthesize ellieFireFlag;
@synthesize smellieRunSettings;
@synthesize exampleTask;
@synthesize smellieRunHeaderDocList;
@synthesize smellieSubRunInfo,
smellieLaserHeadToSepiaMapping,
smellieLaserHeadToGainMapping,
smellieLaserToInputFibreMapping,
smellieFibreSwitchToFibreMapping,
smellieSlaveMode,
smellieConfigVersionNo,
pulseByPulseDelay,
tellieRunDoc,
smellieRunDoc,
currentOrcaSettingsForSmellie,
tellieSubRunSettings,
smellieDBReadInProgress = _smellieDBReadInProgress;



/*********************************************************/
/*                  Class control methods                */
/*********************************************************/
- (id) init
{
    self = [super init];
    if (self){
        _tellieClient = [[XmlrpcClient alloc] initWithHostName:@"daq1" withPort:@"5030"];
        _smellieClient = [[XmlrpcClient alloc] initWithHostName:@"SNODROP2" withPort:@"5020"];
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self){
        _tellieClient = [[XmlrpcClient alloc] initWithHostName:@"daq1" withPort:@"5030"];
        _smellieClient = [[XmlrpcClient alloc] initWithHostName:@"SNODROP2" withPort:@"5020"];
    }
    return self;
}

- (void) setUpImage
{
    [self setSmellieDBReadInProgress:NO];
    [self setImage:[NSImage imageNamed:@"ellie"]];
}

- (void) makeMainController
{
    [self linkToController:@"ELLIEController"];
    
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
}

- (void) sleep
{
	[super sleep];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopTellieRun];
    self.ellieFireFlag = NO;
    [super dealloc];
}

- (void) registerNotificationObservers
{
     NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    //we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
}

/*********************************************************/
/*                    TELLIE Functions                   */
/*********************************************************/
-(void) startTellieRun:(BOOL)scriptFlag
{
    /* 
     Start run using run control object and push initial TELLIE run doc to telliedb.
     
     Possible additions:
        Use SNOPModel to check if tellie run type is masked in
     */

    if(scriptFlag == YES){
        [self pushInitialTellieRunDocument];
    } else {
        //add run control object
        NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
        if(![runModels count]){
            NSException* e = [NSException
                              exceptionWithName:@"noRunModel"
                              reason:@"*** Please add a ORRunModel to the experiment"
                              userInfo:nil];
            [e raise];
        }
        runControl = [runModels objectAtIndex:0];
    
        if(![runControl isRunning]){
            [runControl performSelectorOnMainThread:@selector(startRun) withObject:nil waitUntilDone:YES];
        } else if ([runControl isRunning]) {
            [self pushInitialTellieRunDocument];
        }
    }
}

-(void) stopTellieRun
{
    /*
     Use run control object to stop a tellie run.
    */
    
    //add run control object
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noRunModel"
                          reason:@"*** Please add a ORRunModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    runControl = [runModels objectAtIndex:0];
    
    if([runControl isRunning]){
        [runControl performSelectorOnMainThread:@selector(haltRun) withObject:nil waitUntilDone:YES];
    }
}

-(NSArray*) pollTellieFibre:(double)timeOutSeconds
{
    /*
     Poll the TELLIE hardware using an XMLRPC server and requests the response from the
     hardware. If no response is observed the the hardware is re-polled once every second
     untill a timeout limit has been reached.

     Arguments:
       double timeOutSeconds :  How many seconds to wait before polling is considered a
                                failure and an exception thrown.

    */
    NSArray* pollResponse = [_tellieClient command:@"read_pin_sequence"];
    int count = 0;
    while ([pollResponse isKindOfClass:[NSString class]] && count < timeOutSeconds){
        NSLog(@"Warning: tellie poll has returned nil. Possible sequence hasn't finished. Waiting 1 second and re-polling\n");
        [NSThread sleepForTimeInterval:1.0];
        pollResponse = [_tellieClient command:@"read_pin_sequence"];
        count = count + 1;
    }
    
    // Some checks on the response
    if ([pollResponse isKindOfClass:[NSString class]]){
        NSString* reasonStr = [NSString stringWithFormat:@"*** PIN diode poll returned %@. Likely that the sequence didn't finish before timeout.", pollResponse];
        NSException* e = [NSException
                          exceptionWithName:@"stringPinResponse"
                          reason:reasonStr
                          userInfo:nil];
        [e raise];
        return [NSArray arrayWithObjects:0, 0, nil];
    } else if ([pollResponse count] != 3) {
        NSString* reasonStr = [NSString stringWithFormat:@"*** PIN diode poll returned array of len %i - expected 3", [pollResponse count]];
        NSException* e = [NSException
                          exceptionWithName:@"PinResponseBadArrayLength"
                          reason:reasonStr
                          userInfo:nil];
        [e raise];
        return [NSArray arrayWithObjects:0, 0, nil];
    }
    return pollResponse;
}

-(NSMutableDictionary*) returnTellieFireCommands:(NSString*)fibreName withNPhotons:(NSUInteger)photons withFireFrequency:(NSUInteger)frequency withNPulses:(NSUInteger)pulses
{
    /*
     Calculate the tellie fire commands given certain input parameters
     
     //NEED TO ADD FIBRE DELAY & TRIGGER DELAY READS FROM CALIBRATION FILES
     //CURRENTLY THOSE NUMBERS DON'T EXIST.
    */
    NSNumber* tellieChannel = [self calcTellieChannelForFibre:fibreName];
    NSNumber* pulseWidth = [self calcTellieChannelPulseSettings:[tellieChannel integerValue] withNPhotons:photons withFireFrequency:frequency];
    float pulseSeparation = (1./frequency)*1000; // TELLIE accepts pulse rate in ms

    NSMutableDictionary* settingsDict = [NSMutableDictionary dictionaryWithCapacity:8];
    [settingsDict setValue:fibreName forKey:@"fibre"];
    [settingsDict setValue:tellieChannel forKey:@"channel"];
    [settingsDict setValue:pulseWidth forKey:@"pulse_width"];
    [settingsDict setValue:[NSNumber numberWithFloat:pulseSeparation] forKey:@"pulse_separation"];
    [settingsDict setValue:[NSNumber numberWithInteger:pulses] forKey:@"number_of_shots"];
    //Static settings
    [settingsDict setValue:[NSNumber numberWithInteger:16383] forKey:@"pulse_height"];
    [settingsDict setValue:[NSNumber numberWithInteger:0] forKey:@"fibre_delay"];
    [settingsDict setValue:[NSNumber numberWithInteger:0] forKey:@"trigger_delay"];
    NSLog(@"Tellie settings dict sucessfully created!\n");
    return settingsDict;
}


-(NSNumber*) calcTellieChannelPulseSettings:(NSUInteger)channel withNPhotons:(NSUInteger)photons withFireFrequency:(NSUInteger)frequency
{
    /*
     Calculate the pulse width settings required to return a given intenstity from a specified channel, at a specified rate.
    */
    if(self.tellieFireParameters == nil){
        NSException* e = [NSException
                          exceptionWithName:@"NoTellieFireParameters"
                          reason:@"*** TELLIE fire_parameters doc has not been loaded - you need to callloadTellieStaticsFromDB"
                          userInfo:nil];
        [e raise];
    }
    
    //Frequency check
    if(frequency != 1000){
        //10Hz frequency calibrations not complete.
        [NSException raise:@"Variable exception" format:@"The passed frequency != 1000Hz"];
    }
    
    //Get Calibration parameters
    float a = [[[[self.tellieFireParameters objectForKey:[NSString stringWithFormat:@"Channel_%d",channel]] objectForKey:@"Pars_1kHz"] objectAtIndex:0] floatValue];
    float b = [[[[self.tellieFireParameters objectForKey:[NSString stringWithFormat:@"Channel_%d",channel]] objectForKey:@"Pars_1kHz"] objectAtIndex:1] floatValue];
    float c = [[[[self.tellieFireParameters objectForKey:[NSString stringWithFormat:@"Channel_%d",channel]] objectForKey:@"Pars_1kHz"] objectAtIndex:2] floatValue];

    //Minimum photon settings check
    float min_x = -b / (2*c);
    float min_photons = a + b*min_x + c*(min_x*min_x);
    //If photon output requested is not possible using calibration curve, estimate the low end with linear extrapolation.
    if(photons < min_photons){
        NSLog(@"Channel_%d has a minimum output of %.1f photons...\n",channel,min_photons);
        NSLog(@"Using a linear interpolation of 5ph/IPW from min_photons = %.1f, to estimate requested %d photon settings\n",min_photons,photons);
        float floatPulseWidth = min_x + (min_photons-photons)/5.;
        NSNumber* pulseWidth = [NSNumber numberWithInteger:floatPulseWidth];
        NSLog(@"IPW setting calculated as: %d\n",[pulseWidth intValue]);
        return pulseWidth;
    } else {
        float floatPulseWidth = (-sqrt(-4*a*c + b*b + 4*c*photons)-b) / (2*c);
        NSNumber* pulseWidth = [NSNumber numberWithInteger:floatPulseWidth];
        NSLog(@"IPW setting calculated as: %d\n",[pulseWidth intValue]);
        return pulseWidth;
    }
}

-(NSNumber*) calcTellieChannelForFibre:(NSString*)fibre
{
    /*
     Use patch pannel map loaded from the telliedb to map a given fibre to the correct tellie channel.
    */
    if(self.tellieFibreMapping == nil){
        NSException* e = [NSException
                          exceptionWithName:@"EmptyFibreMappingProperty"
                          reason:@"*** Fibre map has not been loaded from couchdb - you need to call loadTellieStaticsFromDB"
                          userInfo:nil];
        [e raise];
    }
    if(![[self.tellieFibreMapping objectForKey:@"fibres"] containsObject:fibre]){
        NSString* reasonStr = [NSString stringWithFormat:@"*** Fibre map does not include a reference to fibre: %@",fibre];
        NSException* eFibre = [NSException
                               exceptionWithName:@"FibreNotPatched"
                               reason:reasonStr
                               userInfo:nil];
        [eFibre raise];
    }
    NSUInteger fibreIndex = [[self.tellieFibreMapping objectForKey:@"fibres"] indexOfObject:fibre];
    NSUInteger channelInt = [[[self.tellieFibreMapping objectForKey:@"channels"] objectAtIndex:fibreIndex] integerValue];
    NSNumber* channel = [NSNumber numberWithInt:channelInt];
    NSLog(@"Fibre: %@ corresponds to tellie channel %d\n",fibre, channelInt);
    return channel;
}

-(void) fireTellieFibreMaster:(NSMutableDictionary*)fireCommands
{
    /*
     Fire a tellie using hardware settings passed as dictionary. This function
     calls a python script on the DAQ1 machine, passing it command line arguments relating
     to specific tellie channel settings. The called python script relays the commands 
     to the tellie hardware using a XMLRPC server which must be lanuched manually via the
     command line prior to launching ORCA.
     
     Arguments: 
        NSMutableDictionary fireCommands :  A dictionary containing hardware settings to
                                            be relayed to the tellie hardware.
     
    */
    //Set tellieFiring flag
    [self setEllieFireFlag:YES];
    NSLog(@"ELLIE fire flag set to: %@\n",@YES);

    //Add run control object
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noRunModel"
                          reason:@"*** Please add a ORRunModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    runControl = [runModels objectAtIndex:0];

    //TELLIE pin readout is an average measurement of the passed "number_of_shots". If a large number of shots are requested
    //it is useful to split the data into smaller chunks in order to get multiple pin readings.
    NSNumber* loops = [NSNumber numberWithInteger:1];
    int totalShots = [[fireCommands objectForKey:@"number_of_shots"] integerValue];
    float fRemainder = fmod(totalShots, 5e3);
    NSLog(@"fRemainder = %@", fRemainder);
    if( totalShots > 5e3){
        if (fRemainder > 0){
            int iLoops = (totalShots - fRemainder) / 5e3;
            loops = [NSNumber numberWithInteger:(iLoops+1)];
        } else {
            int iLoops = totalShots / 5e3;
            loops =[NSNumber numberWithInteger:iLoops];

        }
    }
    
    for(int i = 0; i<[loops integerValue]; i++){

        //Each loop fires 5e3 identical tellie pulses, except the final one, which fires: (totalRequestedShots % 5e3)
        NSNumber* noShots = [NSNumber numberWithInt:5e3];
        if(i == ([loops integerValue]-1) && fRemainder > 0){
            noShots = [NSNumber numberWithInt:fRemainder];
        }
        //Start a new subrun and ship EPED record. The EPED record flags the subrun boundry in the data structure for a run.
        [runControl performSelectorOnMainThread:@selector(prepareForNewSubRun) withObject:nil waitUntilDone:YES];
        [runControl performSelectorOnMainThread:@selector(startNewSubRun) withObject:nil waitUntilDone:YES];

        // Pass requested tellie settings to tellie server
        if(i == 0){
            NSArray* fireArgs = @[[[fireCommands objectForKey:@"channel"] stringValue],
                                  [noShots stringValue],
                                  [[fireCommands objectForKey:@"pulse_separation"] stringValue],
                                  [[fireCommands objectForKey:@"trigger_delay"] stringValue],
                                  [[fireCommands objectForKey:@"pulse_width"] stringValue],
                                  [[fireCommands objectForKey:@"pulse_height"] stringValue],
                                  [[fireCommands objectForKey:@"fibre_delay"] stringValue],
                                  ];
            NSLog(@"Init-ing tellie with settings\n");
            [_tellieClient command:@"init_channel" withArgs:fireArgs];
        }
        // Set number of pulses to be fired in this sub - run
        NSLog(@"Setting number of pulses\n");
        [_tellieClient command:@"set_pulse_number" withArgs:@[noShots]];

        NSLog(@"***** FIRING %d TELLIE PULSES in Fibre %@ *****\n",[noShots integerValue], [fireCommands objectForKey:@"fibre"]);
        [_tellieClient command:@"fire_sequence"];
        // Wait until sequence has finished
        //NSLog(@"Time to sleep: %@\n Time between shots in us %@", timeToSleep, timeBetweenShotsInMicroSeconds);
        //[NSThread sleepForTimeInterval:timeToSleep];

        // Get pin reading with 5s grace period incase sequence took too
        // long for some reason
        NSLog(@"Polling for tellie pin response...\n");
        NSArray* pinReading = [self pollTellieFibre:6.];
        NSLog(@"Pin response received %@ +/- %@\n", [pinReading objectAtIndex:0], [pinReading objectAtIndex:1]);
        @try {
            [fireCommands setObject:[pinReading objectAtIndex:0] forKey:@"pin_value"];
            [fireCommands setObject:[pinReading objectAtIndex:1] forKey:@"pin_rms"];
        } @catch (NSException *exception) {
            NSLog(@"Unable to add pin readout due to error %@",exception);
        }

        [self updateTellieRunDocument:fireCommands];

        if ([noShots integerValue] == 5000){
            BOOL check = ORRunAlertPanel(@"TELLIE Run Check",@"Would you like to contiune with this fibre?",@"OK",@"No something's up",nil);
            if (check == NO) {
                break;
            }
        }
    }
    [self setEllieFireFlag:NO];
    NSLog(@"ELLIE fire flag set to: %@\n",NO);
}

-(void) stopTellieFibre:(NSArray*)fireCommands
{
    /*
     Call tellie stop script. The script itself is stored on the DAQ1 machine.
    */
    NSString* responseFromTellie = [_tellieClient command:@"stop"];
    NSLog(@"Sent stop command to tellie, received: %@\n",responseFromTellie);
}

-(bool) isELLIEFiring{
    if(self.ellieFireFlag == YES){
        return YES;
    } else {
        return NO;
    }
}

/*****************************/
/*   tellie db interactions  */
/*****************************/
-(void) pushInitialTellieRunDocument
{
    /*
     Create a standard tellie run doc using ELLIEModel / SNOPModel / ORRunModel class
     variables and push up to the telliedb. Additionally, the run doc dictionary set as
     the tellieRunDoc propery, to be updated later in the run.
     */
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:10];
    
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noRunModel"
                          reason:@"*** Please add a ORRunModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    runControl = [runModels objectAtIndex:0];

    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noSNOPModel"
                          reason:@"*** Please add a SNOPModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"tellie_run"];
    NSMutableArray* subRunArray = [NSMutableArray arrayWithCapacity:10];

    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@"%lu",[runControl runNumber]] forKey:@"index"];
    [runDocDict setObject:[self stringUnixFromDate:nil] forKey:@"issue_time_unix"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"issue_time_iso"];

    [runDocDict setObject:[NSMutableArray arrayWithObjects:[NSNumber numberWithUnsignedLong:[runControl runNumber]],[NSNumber numberWithUnsignedLong:[runControl runNumber]], nil] forKey:@"run_range"];

    [runDocDict setObject:subRunArray forKey:@"sub_run_info"];

    [self setTellieRunDoc:runDocDict];

    [[aSnotModel orcaDbRefWithEntryDB:self withDB:@"telliedb"] addDocument:runDocDict tag:kTellieRunDocumentAdded];

    //wait for main thread to receive acknowledgement from couchdb
    NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow:2.0];
    while ([timeout timeIntervalSinceNow] > 0 && ![self.tellieRunDoc objectForKey:@"_id"]) {
        [NSThread sleepForTimeInterval:0.1];
    }
}

- (void) updateTellieRunDocument:(NSDictionary*)subRunDoc
{
    /*
     Update self.tellieRunDoc with subrun information.
     
     Arguments:
     NSDictionary* subRunDoc:  Subrun information to be added to the current self.tellieRunDoc.
     */
    NSMutableDictionary* runDocDict = [self.tellieRunDoc mutableCopy];
    NSMutableDictionary* subRunDocDict = [subRunDoc mutableCopy];

    [subRunDocDict setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];

    NSMutableArray * subRunInfo = [[runDocDict objectForKey:@"sub_run_info"] mutableCopy];
    [subRunInfo addObject:subRunDocDict];
    [runDocDict setObject:subRunInfo forKey:@"sub_run_info"];

    //Update tellieRunDoc property.
    [self setTellieRunDoc:runDocDict];

    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRefWithEntryDB:self withDB:@"telliedb"]
         updateDocument:runDocDict
         documentId:[runDocDict objectForKey:@"_id"]
         tag:kTellieRunDocumentUpdated];
    }
    [subRunInfo release];
    [runDocDict release];
    [subRunDocDict release];
}

-(void) loadTELLIEStaticsFromDB
{
    /*
     Load current tellie channel calibration and patch map settings from telliedb. 
     This function accesses the telliedb and pulls down the most recent fireParameters
     and patchMapping documents. The data is then saved to the member variables 
     tellieFireParameters and tellieFibreMapping.
     */

    // Load the SNOPModel to access orcaDBIPAddress and orcaDBPort variables
    NSArray* snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noSNOPModel"
                          reason:@"*** Please add a SNOPModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    // **********************************
    // Load latest calibration constants
    // **********************************
    NSString* parsUrlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/telliedb/_design/tellieQuery/_view/fetchFireParameters?key=0",[aSnotModel orcaDBUserName], [aSnotModel orcaDBPassword], [aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];
    
    NSString* webParsString = [parsUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL* parsUrl = [NSURL URLWithString:webParsString];
    NSLog(@"Querying : %@\n",parsUrl);
    NSMutableURLRequest* parsUrlRequest = [NSMutableURLRequest requestWithURL:parsUrl
                                                                  cachePolicy:0
                                                              timeoutInterval:20];
    
    // Get data string from URL
    NSError* parsDataError =  nil;
    NSURLResponse* parsUrlResponse;
    NSData* parsData = [NSURLConnection sendSynchronousRequest:parsUrlRequest
                                            returningResponse:&parsUrlResponse
                                                        error:&parsDataError];
    /*
    // Get data string from URL
    NSError* parsDataError =  nil;
    NSData* parsData = [NSData dataWithContentsOfURL:parsUrl
                                             options:NSDataReadingMapped
                                               error:&parsDataError];
    */
    if(parsDataError){
        NSLog(@"\n%@\n\n",parsDataError);
    }
    NSString* parsReturnStr = [[NSString alloc] initWithData:parsData encoding:NSUTF8StringEncoding];
    // Format queried data to dictionary
    NSError* parsDictError =  nil;
    NSMutableDictionary* parsDict = [NSJSONSerialization JSONObjectWithData:[parsReturnStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&parsDictError];
    if(!parsDictError){
        NSLog(@"sucessful query\n");
    }else{
        NSLog(@"Error querying couchDB, please check the connection is correct %@\n",parsDictError);
    }
    [parsReturnStr release];

    NSMutableDictionary* fireParametersDoc =[[[parsDict objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"%TELLIE fire parameters sucessfully loaded!\n");
    self.tellieFireParameters = fireParametersDoc;

    // **********************************
    // Load latest mapping doc.
    // **********************************
    NSString* mapUrlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/telliedb/_design/tellieQuery/_view/fetchCurrentMapping?key=0",[aSnotModel orcaDBUserName], [aSnotModel orcaDBPassword], [aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];

    NSString* webMapString = [mapUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL* mapUrl = [NSURL URLWithString:webMapString];
    NSLog(@"Querying : %@\n",mapUrl);
    NSMutableURLRequest* mapUrlRequest = [NSMutableURLRequest requestWithURL:mapUrl
                                                                 cachePolicy:0
                                                             timeoutInterval:20];

    // Get data string from URL
    NSError* mapDataError =  nil;
    NSURLResponse* mapUrlResponse;
    NSData* mapData = [NSURLConnection sendSynchronousRequest:mapUrlRequest
                                            returningResponse:&mapUrlResponse
                                                        error:&mapDataError];
    /*
    NSData* mapData = [NSData dataWithContentsOfURL:mapUrl
                                            options:NSDataReadingMapped
                                              error:&mapDataError];
    */
     if(mapDataError){
        NSLog(@"\n%@\n\n",mapDataError);
    }
    NSString* mapReturnStr = [[NSString alloc] initWithData:mapData encoding:NSUTF8StringEncoding];
    // Format queried data to dictionary
    NSError* mapDictError =  nil;
    NSMutableDictionary* mapDict = [NSJSONSerialization JSONObjectWithData:[mapReturnStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&mapDictError];
    if(!mapDictError){
        NSLog(@"sucessful query\n");
    }else{
        NSLog(@"Error querying couchDB, please check the connection is correct %@\n",mapDictError);
    }
    [mapReturnStr release];

    NSMutableDictionary* mappingDoc =[[[mapDict objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"TELLIE mapping document sucessfully loaded!\n");
    self.tellieFibreMapping = mappingDoc;
}

/*********************************************************/
/*                  Smellie Functions                    */
/*********************************************************/
-(void)setSmellieSafeStates
{
    [_smellieClient command:@"set_safe_states"];
}

-(void)setLaserSwitch:(NSString*)laserSwitchChannel
{
    NSArray* args = @[laserSwitchChannel];
    [_smellieClient command:@"set_laser_switch" withArgs:args];
}

-(void)setFibreSwitch:(NSString*)fibreSwitchInputChannel withOutputChannel:(NSString*)fibreSwitchOutputChannel
{
    NSArray* args = @[fibreSwitchInputChannel, fibreSwitchOutputChannel];
    [_smellieClient command:@"set_fibre_switch" withArgs:args];
}

-(void)setLaserIntensity:(NSString*)laserIntensity
{
    NSArray* args = @[laserIntensity];
    [_smellieClient command:@"set_laser_intensity" withArgs:args];
}

-(void)setLaserSoftLockOn
{
    [_smellieClient command:@"set_soft_lock_on"];
}

-(void)setLaserSoftLockOff
{
    [_smellieClient command:@"set_soft_lock_off"];
}

//this function kills any external software that will block the functions of a smellie run
-(void)killBlockingSoftware
{
    [_smellieClient command:@"kill_sepia_and_nimax"];
}

-(void)setSmellieMasterMode:(NSString*)triggerFrequency withNumOfPulses:(NSString*)numOfPulses
{
    NSArray* args = @[triggerFrequency, numOfPulses];
    [_smellieClient command:@"pulse_master_mode" withArgs:args];
}

-(void)setGainControlWithGainVoltage:(NSString*)gainVoltage
{
    NSArray* args = @[gainVoltage];
    [_smellieClient command:@"set_gain_control" withArgs:args];
}

-(void)setSuperKSafeStates
{
    [_smellieClient command:@"set_superk_safe_states"];
}
-(void)setSuperKSoftLockOn
{
    [_smellieClient command:@"set_superk_lock_on"];
}

-(void)setSuperKSoftLockOff
{
    [_smellieClient command:@"set_superk_lock_off"];
}

-(void) setSuperKWavelegth:(NSString*)lowBin withHighEdge:(NSString*)highBin
{
    NSArray* args = @[lowBin, highBin];
    [_smellieClient command:@"set_superk_wavelength" withArgs:args];
}

-(void)sendCustomSmellieCmd:(NSString*)customCmd withArgs:(NSArray*)argsArray
{
    [_smellieClient command:customCmd withArgs:argsArray];
}

//complete this after the smellie documents have been recieved
-(void) smellieDocumentsRecieved
{
    /*
     Update smeillieDBReadInProgress property bool.
     */
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(smellieDocumentsRecieved) object:nil];
    if (![self smellieDBReadInProgress]) { //killed already
        return;
    }
    
    [self setSmellieDBReadInProgress:NO];
}

-(void)testFunction
{
    NSArray* runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noRunModel"
                          reason:@"*** Please add a ORRunModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    runControl = [runModels objectAtIndex:0];
    [runControl performSelector:@selector(haltRun)withObject:nil afterDelay:.1];
}

-(void)startSmellieRunInBackground:(NSDictionary*)smellieSettings
{
    [self performSelectorOnMainThread:@selector(startSmellieRun:) withObject:smellieSettings waitUntilDone:NO];
}

-(NSArray*)getSmellieRunLaserArray:(NSDictionary*)smellieSettings
{
    //Extract the lasers to be fired into an array
    NSMutableArray* laserArray = [NSMutableArray arrayWithCapacity:5];
    if([[smellieSettings objectForKey:@"375nm_laser_on"] intValue] == 1){
        [laserArray addObject:@"375nm"];
    } if([[smellieSettings objectForKey:@"405nm_laser_on"] intValue] == 1) {
        [laserArray addObject:@"405nm"];
    } if([[smellieSettings objectForKey:@"440nm_laser_on"] intValue] == 1) {
        [laserArray addObject:@"440nm"];
    } if([[smellieSettings objectForKey:@"500nm_laser_on"] intValue] == 1) {
        [laserArray addObject:@"500nm"];
    } if([[smellieSettings objectForKey:@"superK_laser_on"] intValue] == 1) {
        [laserArray addObject:@"superK"];
    }
    return laserArray;
};

-(NSMutableArray*)getSmellieRunFibreArray:(NSDictionary*)smellieSettings
{
    //Extract the fibres to be fired into an array
    NSMutableArray* fibreArray = [NSMutableArray arrayWithCapacity:12];
    if ([[smellieSettings objectForKey:@"FS007"] intValue] == 1){
        [fibreArray addObject:@"FS007"];
    } if ([[smellieSettings objectForKey:@"FS107"] intValue] == 1){
        [fibreArray addObject:@"FS107"];
    } if ([[smellieSettings objectForKey:@"FS207"] intValue] == 1){
        [fibreArray addObject:@"FS207"];
    } if ([[smellieSettings objectForKey:@"FS025"] intValue] == 1){
        [fibreArray addObject:@"FS025"];
    } if ([[smellieSettings objectForKey:@"FS125"] intValue] == 1){
        [fibreArray addObject:@"FS125"];
    } if ([[smellieSettings objectForKey:@"FS225"] intValue] == 1){
        [fibreArray addObject:@"FS225"];
    } if ([[smellieSettings objectForKey:@"FS037"] intValue] == 1){
        [fibreArray addObject:@"FS037"];
    } if ([[smellieSettings objectForKey:@"FS137"] intValue] == 1){
        [fibreArray addObject:@"FS137"];
    } if ([[smellieSettings objectForKey:@"FS237"] intValue] == 1){
        [fibreArray addObject:@"FS237"];
    } if ([[smellieSettings objectForKey:@"FS055"] intValue] == 1){
        [fibreArray addObject:@"FS055"];
    } if ([[smellieSettings objectForKey:@"FS155"] intValue] == 1){
        [fibreArray addObject:@"FS155"];
    } if ([[smellieSettings objectForKey:@"FS255"] intValue] == 1){
        [fibreArray addObject:@"FS255"];
    }
    return fibreArray;
}

-(NSArray*)getSmellieRunFrequencyArray:(NSDictionary*)smellieSettings
{
    return nil;
}

-(NSMutableArray*)getSmellieRunIntensityArray:(NSDictionary*)smellieSettings
{
    //Extract bounds
    int minIntensity = [[smellieSettings objectForKey:@"min_laser_intensity"] intValue];
    int maxIntensity = [[smellieSettings objectForKey:@"max_laser_intensity"] intValue];
    float noSteps = [[smellieSettings objectForKey:@"num_intensity_steps"] floatValue];

    //Check to see if the maximum intensity is the same as the minimum intensity
    float increment = 0;
    NSMutableArray* intensities = [NSMutableArray arrayWithCapacity:noSteps];
    if(maxIntensity != minIntensity){
        increment = (maxIntensity - minIntensity) / noSteps;
    } else {
        [intensities addObject:[NSNumber numberWithInteger:maxIntensity]];
        return intensities;
    }

    //Create intensities array
    for(int intensityLoopInt = minIntensity;intensityLoopInt <= maxIntensity; intensityLoopInt = intensityLoopInt + increment){
        [intensities addObject:[NSNumber numberWithInt:intensityLoopInt]];
    }

    return intensities;
}

-(NSMutableArray*)getSmellieHighEdgeWavelengthArray:(NSDictionary*)smellieSettings
{
    //Read data
    int wavelengthLow = [[smellieSettings objectForKey:@"superK_wavelength_low"] intValue];
    int wavelengthHigh = [[smellieSettings objectForKey:@"superK_wavelength_high"] intValue];
    int delta = [[smellieSettings objectForKey:@"superK_wavelength_step"] intValue];
    float noSteps = [[smellieSettings objectForKey:@"superK_num_wavelength_steps"] floatValue];

    float increment;
    NSMutableArray* highEdges = [NSMutableArray arrayWithCapacity:noSteps];
    if(wavelengthHigh != 0 && wavelengthHigh - wavelengthLow >= delta){
        increment = (wavelengthHigh - wavelengthLow) / noSteps;
    } else {
        [highEdges addObject:[NSNumber numberWithInteger:wavelengthHigh]];
        return highEdges;
    }

    //Create array
    for(float edge = (wavelengthLow + delta);edge <= wavelengthHigh; edge = edge + increment){
        [highEdges addObject:[NSNumber numberWithInt:edge]];
    }
    return highEdges;
}

-(NSMutableArray*)getSmellieLowEdgeWavelengthArray:(NSDictionary*)smellieSettings
{
    //Read data
    int wavelengthLow = [[smellieSettings objectForKey:@"superK_wavelength_low"] intValue];
    int wavelengthHigh = [[smellieSettings objectForKey:@"superK_wavelength_high"] intValue];
    int delta = [[smellieSettings objectForKey:@"superK_wavelength_step"] intValue];
    float noSteps = [[smellieSettings objectForKey:@"superK_num_wavelength_steps"] floatValue];
    
    float increment;
    NSMutableArray* lowEdges = [NSMutableArray arrayWithCapacity:noSteps];
    if(wavelengthHigh != 0 && wavelengthHigh - wavelengthLow >= delta){
        increment = (wavelengthHigh - wavelengthLow) / noSteps;
    } else {
        [lowEdges addObject:[NSNumber numberWithInteger:wavelengthLow]];
        return lowEdges;
    }
    
    //Create array
    for(float edge = wavelengthLow;edge <= (wavelengthHigh - delta); edge = edge + increment){
        [lowEdges addObject:[NSNumber numberWithInt:edge]];
    }
    return lowEdges;
}

-(void)startSmellieRun:(NSDictionary*)smellieSettings
{
    /*
     Form a smellie run using the passed smellie run file, stored in smellieSettings.
     
     COMMENT:
     I think this method should be implemented as a standard run script, not as an object
     method. I'll look into doing this after the DAQ meeting in Jan - Once I know the tellie
     one works!
     */
    NSLog(@"SMELLIE_RUN:Setting up a SMELLIE Run\n");
    NSLog(@"SMELLIE_RUN:Stopping any Blocking Software on SMELLIE computer(SNODROP)\n");
    [self killBlockingSoftware];
    NSLog(@"SMELLIE_RUN:Setting SMELLIE into Safe States before starting a Run\n");
    [self setSmellieSafeStates];

    //   GET SNOP & MTC MODELS
    //
    //Get the MTC Object (will only be used in Slave Mode)
    NSArray*  mtcModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    if(![mtcModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noMTCModel"
                          reason:@"*** Please add a ORMTCModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    ORMTCModel* theMTCModel = [mtcModels objectAtIndex:0];
    [theMTCModel stopMTCPedestalsFixedRate]; //stop any pedestals that are currently running
    
    //Get the run controller
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noRunModel"
                          reason:@"*** Please add a ORRunModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    runControl = [runModels objectAtIndex:0];

    // FIND AND LOAD RELEVANT CONFIG
    //
    NSNumber* configVersionNo;
    if([smellieSettings objectForKey:@"config_name"]){
        configVersionNo = [self fetchConfigVersionFor:[smellieSettings objectForKey:@"config_name"]];
        NSLogColor([NSColor redColor], @"Loading config file: %@\n", [smellieSettings objectForKey:@"config_name"]);
    } else {
        configVersionNo = [self fetchRecentConfigVersion];
        NSLogColor([NSColor redColor], @"Loading config file: %i\n", [configVersionNo intValue]);
    }
    [self setSmellieConfigVersionNo:configVersionNo];
    [self fetchConfigurationFile:configVersionNo];
    NSLog(@"Config loaded!");

    // STORE MTC SETTINGS
    //
    //Save the current MTC delay / period settings
    NSMutableDictionary* currentMTCSettings = [[NSMutableDictionary alloc] init];
    NSLog(@"SMELLIE_RUN:Mtcd coarse delay set to %f ns\n",[theMTCModel dbFloatByIndex:kCoarseDelay]);
    NSNumber * mtcCoarseDelay = [NSNumber numberWithUnsignedLong:[theMTCModel dbFloatByIndex:kCoarseDelay]];
    [currentMTCSettings setObject:mtcCoarseDelay forKey:@"mtcd_coarse_delay"];

    NSLog(@"SMELLIE_RUN:Mtcd pulser rate set to %f Hz\n",[theMTCModel dbFloatByIndex:kPulserPeriod]);
    NSNumber * mtcPulserPeriod = [NSNumber numberWithFloat:[theMTCModel dbFloatByIndex:kPulserPeriod]];
    [currentMTCSettings setObject:mtcPulserPeriod forKey:@"mtcd_pulser_period"];

    //Set property variable and delete tmpVar.
    [self setCurrentOrcaSettingsForSmellie:currentMTCSettings];
    [currentMTCSettings release];

    // RUN CONTROL
    //
    //Set up run control
    if(![runControl isRunning]){
        //start the run controller
        NSLogColor([NSColor redColor], @"Starting our own run! \n");
        [runControl performSelectorOnMainThread:@selector(startRun) withObject:nil waitUntilDone:YES];
        
    }else{
        //Stop the current run and start a new run
        NSLogColor([NSColor redColor], @"Resetting run! \n");
        [runControl setForceRestart:YES];
        [runControl performSelectorOnMainThread:@selector(stopRun) withObject:nil waitUntilDone:YES];
        [runControl performSelectorOnMainThread:@selector(startRun) withObject:nil waitUntilDone:YES];
    }

    // GET SMELLIE RUN SETTINGS TO LOOP OVER
    //
    NSMutableArray* laserArray = [self getSmellieRunLaserArray:smellieSettings];
    NSMutableArray* fibreArray = [self getSmellieRunFibreArray:smellieSettings];
    NSMutableArray* intensityArray = [self getSmellieRunIntensityArray:smellieSettings];
    NSMutableArray* lowEdgeWavelengthArray = [self getSmellieLowEdgeWavelengthArray:smellieSettings];
    NSMutableArray* highEdgeWavelengthArray = [self getSmellieHighEdgeWavelengthArray:smellieSettings];

    NSString* numOfPulsesInSlaveMode = [NSString stringWithFormat:@"%@",[smellieSettings objectForKey:@"triggers_per_loop"]];
    NSString* triggerFrequencyInSlaveMode = [NSString stringWithFormat:@"%@",[smellieSettings objectForKey:@"trigger_frequency"]];

    // SET MASTER / SLAVE MODE
    //
    NSString *operationMode = [NSString stringWithFormat:@"%@",[smellieSettings objectForKey:@"operation_mode"]];
    if([operationMode isEqualToString:@"Slave Mode"]){
        [self setSmellieSlaveMode:YES];
        NSLog(@"SMELLIE_RUN:Running in SLAVE mode\n");
    }else if([operationMode isEqualToString:@"Master Mode"]){
        [self setSmellieSlaveMode:NO];
        NSLog(@"SMELIE_RUN:Running n MASTER mode\n");
    }else{
        NSException* e = [NSException
                          exceptionWithName:@"badConfigEntry"
                          reason:@"*** Slave / Master mode does not appear to be included in config file"
                          userInfo:nil];
        [e raise];
    }

    //How long do we need to run pulser? - TO BE REPACED AFTER TUBII INTEGRATION
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    float timeToPulse = [[f numberFromString:numOfPulsesInSlaveMode] floatValue]/[[f numberFromString:triggerFrequencyInSlaveMode] floatValue];
    [f release];

    // CREATE AND PUSH SMELLIE RUN DOC
    //
    [self pushInitialSmellieRunDocument];

    // BEGIN LOOPING!
    //
    BOOL endOfRun = NO;
    for(NSString* laserKey in laserArray){

        if(endOfRun == YES){
            break; //if the end of the run is reached then break the run loop
        }

        //Set the laser switch which corresponds to the laserHead mapping to Sepia
        NSLog(@"SMELLIE_RUN:Setting the Laser Switch to Channel:%@ which corresponds to the %@ Laser\n",[NSString stringWithFormat:@"%@",[[self smellieLaserHeadToSepiaMapping] objectForKey:laserKey]],laserKey);
        [self setLaserSwitch:[NSString stringWithFormat:@"%@",[[ self smellieLaserHeadToSepiaMapping] objectForKey:laserKey]]];

        //Set the gain Control
        NSLog(@"SMELLIE_RUN:Setting the gain control to: %f V\n",[[[self smellieLaserHeadToGainMapping] objectForKey:laserKey] floatValue]);
        [self setGainControlWithGainVoltage:[NSString stringWithFormat:@"%@",[[self smellieLaserHeadToGainMapping] objectForKey:laserKey]]];

        //Loop through each Fibre
        for(NSString* fibreKey in fibreArray){

            if(endOfRun == YES){
                break;
            }

            NSString *inputFibreSwitchChannel = [NSString stringWithFormat:@"%@",[[self smellieLaserToInputFibreMapping] objectForKey:laserKey]];

            NSString* popUpMessage = [NSString stringWithFormat:@"About to set the fibre switch:\nInput Channel %@\n, Laser %@, Output Channel %@\n",inputFibreSwitchChannel,laserKey,[NSString stringWithFormat:@"%@",[[self smellieFibreSwitchToFibreMapping] objectForKey:fibreKey]]];
            ORRunAlertPanel(@"SMELLIE HARDWARE WATCH",popUpMessage,@"OK",nil,nil);
            NSLog(@"SMELLIE_RUN:Setting the Fibre Switch to Input Channel:%@ from the %@ Laser and Output Channel %@\n",inputFibreSwitchChannel,laserKey,[NSString stringWithFormat:@"%@",[[self smellieFibreSwitchToFibreMapping] objectForKey:fibreKey]]);
            [self setFibreSwitch:inputFibreSwitchChannel withOutputChannel:[NSString stringWithFormat:@"%@",[[self smellieFibreSwitchToFibreMapping] objectForKey:fibreKey]]];
            [NSThread sleepForTimeInterval:1.0f];

            //Define commands depending on laser type
            int loopLength;
            NSString* softLockOnCommand;
            NSString* softLockOffCommand;
            NSString* masterModeCommand;
            if([laserKey isEqual:@"superK"]){
                loopLength = [lowEdgeWavelengthArray count];
                masterModeCommand = @"pulse_master_mode_sk";
                softLockOnCommand = @"set_superk_lock_on";
                softLockOffCommand = @"set_superk_lock_off";
            } else {
                loopLength = [intensityArray count];
                masterModeCommand = @"pulse_master_mode";
                softLockOnCommand = @"set_soft_lock_on";
                softLockOffCommand = @"set_soft_lock_off";
            }
            //Loop through each intensity of a SMELLIE run
            for(int i=0; i < loopLength; i++){

                if([[NSThread currentThread] isCancelled] || ![runControl isRunning]){
                    endOfRun = YES;
                    break;
                }
                
                //Deactivate software locks
                [self sendCustomSmellieCmd:softLockOffCommand withArgs:nil];

                //Prepare new subrun - will produce a subrun boundrary in the zdab.
                [runControl performSelectorOnMainThread:@selector(prepareForNewSubRun) withObject:nil waitUntilDone:YES];
                [runControl performSelectorOnMainThread:@selector(startNewSubRun) withObject:nil waitUntilDone:YES];

                // SET FINAL SMELLIE SETTINGS
                //
                NSMutableDictionary *valuesToFillPerSubRun = [[NSMutableDictionary alloc] initWithCapacity:100];
                [valuesToFillPerSubRun setObject:laserKey forKey:@"laser"];
                [valuesToFillPerSubRun setObject:fibreKey forKey:@"fibre"];
                [valuesToFillPerSubRun setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];
                if([laserKey isEqual:@"superK"]){
                    NSNumber* lowBin = [lowEdgeWavelengthArray objectAtIndex:i];
                    NSNumber* highBin = [highEdgeWavelengthArray objectAtIndex:i];
                    NSString* lowBinAsString = [NSString stringWithFormat:@"%i", [lowBin intValue]];
                    NSString* highBinAsString = [NSString stringWithFormat:@"%i", [highBin intValue]];
                    NSLog(@"SMELLIE_RUN:Setting the Laser wavelegnth window: %@ - %@ \n", lowBinAsString, highBinAsString);

                    [valuesToFillPerSubRun setObject:[NSNumber numberWithInt:0] forKey:@"intensity"];
                    [valuesToFillPerSubRun setObject:lowBin forKey:@"wavelength_low_edge"];
                    [valuesToFillPerSubRun setObject:highBin forKey:@"wavelength_high_edge"];

                    [self setSuperKWavelegth:lowBinAsString withHighEdge:highBinAsString];
                } else {
                    NSNumber* laserIntensity = [intensityArray objectAtIndex:i];
                    NSString* laserIntensityAsString = [NSString stringWithFormat:@"%i",[laserIntensity intValue]];
                    NSLog(@"SMELLIE_RUN:Setting the Laser Intensity to %@ \n",laserIntensityAsString);
                    
                    [valuesToFillPerSubRun setObject:laserIntensity forKey:@"intensity"];
                    [valuesToFillPerSubRun setObject:[NSNumber numberWithInt:0] forKey:@"wavelength_low_edge"];
                    [valuesToFillPerSubRun setObject:[NSNumber numberWithInt:0] forKey:@"wavelength_high_edge"];
                    
                    [self setLaserIntensity:laserIntensityAsString];
                }

                //this used to be 10.0,  Slave mode in Orca requires time (unknown reason) - Chris J
                [NSThread sleepForTimeInterval:1.0f];

                if([self smellieSlaveMode]){
                    NSLog(@"SMELLIE_RUN:Setting the Pedestal to :%@ Hz \n",triggerFrequencyInSlaveMode);
                    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                    [f setNumberStyle:NSNumberFormatterDecimalStyle];
                    NSNumber * numericTriggerFrequencyInSlaveMode = [f numberFromString:triggerFrequencyInSlaveMode];
                    [f release];

                    NSLog(@"SMELLIE_RUN:Intensity:Firing Pedestals\n");
                    [theMTCModel fireMTCPedestalsFixedRate];

                    float pulserRate = [numericTriggerFrequencyInSlaveMode floatValue];
                    [theMTCModel setThePulserRate:pulserRate];
                 
                    NSLog(@"SMELLIE_RUN: Pulsing at %f Hz for %f seconds \n",[triggerFrequencyInSlaveMode floatValue],timeToPulse);
                    //THIS IS CRAZY - FIND SOME BETTER WAY OF DOING IT USING TUBII COUNTERS
                    [NSThread sleepForTimeInterval:timeToPulse];
                }

                if(![self smellieSlaveMode]){
                    NSString* numOfPulses = [NSString stringWithFormat:@"%@",[smellieSettings objectForKey:@"triggers_per_loop"]];
                    NSString* triggerFrequency = [NSString stringWithFormat:@"%@",[smellieSettings objectForKey:@"trigger_frequency"]];
                    NSLog(@"SMELLIE_RUN:%@ Pulses at %@ Hz \n",numOfPulses,triggerFrequency);
                    [self sendCustomSmellieCmd:masterModeCommand withArgs:@[triggerFrequency, numOfPulses]];
                }

                if([self smellieSlaveMode]){
                    NSLog(@"SMELLIE_RUN:Stopping MTCPedestals\n");
                    [theMTCModel stopMTCPedestalsFixedRate];
                    [self sendCustomSmellieCmd:softLockOnCommand withArgs:nil];
                }

                //Keep record of sub-run settings
                [self updateSmellieRunDocument:valuesToFillPerSubRun];
                [valuesToFillPerSubRun release];

                //Activate software locks
                [self sendCustomSmellieCmd:softLockOnCommand withArgs:nil];

                //Check if run file requests a sleep time between sub_runs
                if([smellieSettings objectForKey:@"sleep_between_sub_run"]){
                    NSTimeInterval sleepTime = [[smellieSettings objectForKey:@"sleep_between_sub_run"] floatValue];
                    [NSThread sleepForTimeInterval:sleepTime];
                } else {
                    [NSThread sleepForTimeInterval:1.0f];
                }
            }//end of looping through each intensity setting on the smellie laser
        }//end of looping through each Fibre
    }//end of looping through each laser

    //stop the pedestals if required
    if([self smellieSlaveMode]){
        NSLog(@"SMELLIE_RUN:Stopping MTCPedestals\n");
        [theMTCModel stopMTCPedestalsFixedRate];
    }

    //Resetting the mtcd to settings before the smellie run
    NSLog(@"SMELLIE_RUN:Returning SMELLIE into Safe States after finishing a Run\n");
    [self setSmellieSafeStates];
    [self setSuperKSafeStates];

    if(!endOfRun){
        //Post a note. on the main thread to request a call to stopSmellieRun
        dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORELLIERunFinished object:self];
        });
    }
}

-(void)stopSmellieRun
{
    /*
     Some sign off / tidy up stuff to be called at the end of a smellie run. Again, I think this
     should be moved to a runscript.
     */
    NSArray*  mtcModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    if(![mtcModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noMTCModel"
                          reason:@"*** Please add a MTCModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    ORMTCModel* theMTCModel = [mtcModels objectAtIndex:0];

    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noRunModel"
                          reason:@"*** Please add a ORRunModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    runControl = [runModels objectAtIndex:0];

    //Set the Mtcd for back to original settings
    [theMTCModel setThePulserRate:[[currentOrcaSettingsForSmellie objectForKey:@"mtcd_pulser_period"] floatValue]];
    [theMTCModel enablePulser];
    NSLog(@"SMELLIE_RUN:Setting the mtcd pulser back to %f Hz\n",[[currentOrcaSettingsForSmellie objectForKey:@"mtcd_pulser_period"] floatValue]);
    [theMTCModel stopMTCPedestalsFixedRate];

    [theMTCModel setupGTCorseDelay:[[currentOrcaSettingsForSmellie objectForKey:@"mtcd_coarse_delay"] intValue]];
    NSLog(@"SMELLIE_RUN:Setting the mtcd coarse delay back to %i \n",[[currentOrcaSettingsForSmellie objectForKey:@"mtcd_coarse_delay"] intValue]);

    [self setSmellieSafeStates];
    [self setSuperKSafeStates];

    if([runControl isRunning]){
        [runControl setForceRestart:YES];
        [runControl performSelectorOnMainThread:@selector(stopRun) withObject:nil waitUntilDone:YES];
        [runControl performSelectorOnMainThread:@selector(startRun) withObject:nil waitUntilDone:YES];
    }

    NSLog(@"SMELLIE_RUN:Stopping SMELLIE Run\n");
}

/*****************************/
/*  smellie db interactions  */
/*****************************/
- (void) fetchSmellieConfigurationInformation
{
    /*
        Get smellie config information from the smelliedb.
    */

    //this is dependant upon the current couchDB view that exsists within the database
    NSString *requestString = [NSString stringWithFormat:@"_design/smellieMainQuery/_view/pullEllieConfigHeaders"];
    
    [[self generalDBRef:@"smellie"] getDocumentId:requestString tag:kSmellieConfigHeaderRetrieved];
    
    [self setSmellieDBReadInProgress:YES];
    // Is there a better way to do this... Do we know it's received after the delay?
    [self performSelector:@selector(smellieDocumentsRecieved) withObject:nil afterDelay:10.0];
}

-(void) smellieDBpush:(NSMutableDictionary*)dbDic
{
    [self _pushEllieCustomRunToDB:@"smellie" runFiletoPush:dbDic withDocType:@"smellie_run_description"];
}

-(void) smellieConfigurationDBpush:(NSMutableDictionary*)dbDic
{
    [self _pushEllieConfigDocToDB:@"smellie" runFiletoPush:dbDic withDocType:@"smellie_run_configuration"];
}

-(void) pushInitialSmellieRunDocument
{
    /*
     Create a standard smellie run doc using ELLIEModel / SNOPModel / ORRunModel class
     variables and push up to the smelliedb. Additionally, the run doc dictionary set as
     the tellieRunDoc propery, to be updated later in the run.
     */
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:10];

    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noRunModel"
                          reason:@"*** Please add a ORRunModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    runControl = [runModels objectAtIndex:0];

    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noSNOPModel"
                          reason:@"*** Please add a SNOPModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"smellie_run"];
    NSMutableArray* subRunArray = [NSMutableArray arrayWithCapacity:15];

    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@"%lu",[runControl runNumber]] forKey:@"index"];
    [runDocDict setObject:[aSnotModel smellieRunNameLabel] forKey:@"run_description_used"];
    [runDocDict setObject:[self stringUnixFromDate:nil] forKey:@"issue_time_unix"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"issue_time_iso"];
    [runDocDict setObject:[self smellieConfigVersionNo] forKey:@"configuration_version"];
    [runDocDict setObject:[NSNumber numberWithInt:[runControl runNumber]] forKey:@"run"];
    [runDocDict setObject:[NSMutableArray arrayWithObjects:[NSNumber numberWithUnsignedLong:[runControl runNumber]],[NSNumber numberWithUnsignedLong:[runControl runNumber]], nil] forKey:@"run_range"];

    [runDocDict setObject:subRunArray forKey:@"sub_run_info"];

    [self setSmellieRunDoc:runDocDict];

    [[aSnotModel orcaDbRefWithEntryDB:self withDB:@"smellie"] addDocument:runDocDict tag:kSmellieRunDocumentAdded];

    //wait for main thread to receive acknowledgement from couchdb
    NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow:5.0];
    while ([timeout timeIntervalSinceNow] > 0 && ![runDocDict objectForKey:@"_id"]) {
        [NSThread sleepForTimeInterval:0.1];
    }
}

- (void) updateSmellieRunDocument:(NSDictionary*)subRunDoc
{
    /*
     Update self.tellieRunDoc with subrun information.
     
     Arguments:
     NSDictionary* subRunDoc:  Subrun information to be added to the current self.tellieRunDoc.
     */
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noSNOPModel"
                          reason:@"*** Please add a SNOPModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSMutableDictionary* runDocDict = [self.smellieRunDoc mutableCopy];
    NSMutableDictionary* subRunDocDict = [subRunDoc mutableCopy];

    [subRunDocDict setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];

    NSMutableArray * subRunInfo = [[runDocDict objectForKey:@"sub_run_info"] mutableCopy];
    [subRunInfo addObject:subRunDocDict];
    [runDocDict setObject:subRunInfo forKey:@"sub_run_info"];

    //Update tellieRunDoc property.
    [self setSmellieRunDoc:runDocDict];

    //check to see if run is offline or not
    [[aSnotModel orcaDbRefWithEntryDB:self withDB:@"smellie"] updateDocument:runDocDict documentId:[runDocDict objectForKey:@"_id"] tag:kTellieRunDocumentUpdated];
    [subRunInfo release];
    [runDocDict release];
    [subRunDocDict release];
}

-(void) _pushSmellieRunDocument
{
    /*
     Creat a standard smellie run doc using ELLIEModel / SNOPModel / ORRunModel class
     variables and push up to the smelliedb.
     */
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:100];

    //Collect a series of objects from the SNOPModel
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noSNOPModel"
                          reason:@"*** Please add a SNOPModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noRunModel"
                          reason:@"*** Please add a ORRunModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    runControl = [runModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"smellie_run"];
    NSString* smellieRunNameLabel = [aSnotModel smellieRunNameLabel];

    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@"%lu",[runControl runNumber]] forKey:@"index"];
    [runDocDict setObject:smellieRunNameLabel forKey:@"run_description_used"];
    [runDocDict setObject:[self stringUnixFromDate:nil] forKey:@"issue_time_unix"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"issue_time_iso"];
    NSNumber *smellieConfigurationVersion = [self smellieConfigVersionNo];
    [runDocDict setObject:smellieConfigurationVersion forKey:@"configuration_version"];
    [runDocDict setObject:[NSNumber numberWithInt:[runControl runNumber]] forKey:@"run"];

    // Sub run info
    if([runDocDict objectForKey:@"sub_run_info"]){
        [runDocDict setObject:smellieSubRunInfo forKey:@"sub_run_info"];
    } else {
        [runDocDict setObject:[NSNumber numberWithInt:0] forKey:@"sub_run_info"];
    }

    [[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:@"smellie"] addDocument:runDocDict tag:kSmellieSubRunDocumentAdded];
}

-(void) _pushEllieConfigDocToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile withDocType:(NSString*)aDocType
{
    /*
     Create and push a smellie config file to couchdb.
     
     Arguments:
     NSString* aCouchDBName:             Name of the couchdb repo the document will be uploaded to.
     NSMutableDictionary customRunFile:  Custom run settings to be uploaded to db.
     NSString* aDocType:                 Name to be used in the 'doc_type' field of the uploaded doc.
     
     */
    NSMutableDictionary* configDocDic = [NSMutableDictionary dictionaryWithCapacity:100];

    //Collect a series of objects from the SNOPModel
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noSNOPModel"
                          reason:@"*** Please add a SNOPModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    //Initialise the SNOPModel
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"%@",aDocType];

    NSLog(@"document_type: %@",docType);

    [configDocDic setObject:docType forKey:@"doc_type"];
    [configDocDic setObject:[self stringDateFromDate:nil] forKey:@"time_stamp"];
    [configDocDic setObject:customRunFile forKey:@"configuration_info"];

    [[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:aCouchDBName] addDocument:configDocDic tag:kSmellieRunDocumentAdded];
}


-(void) _pushEllieCustomRunToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile withDocType:(NSString*)aDocType
{
    /*
     Push custom run information from the GUI to a couchDB database.
     
     Arguments:
     NSString* aCouchDBName            : The couchdb database name.
     NSMutableDictionary* customRunFile: GUI settings stored in a dictionary.
     NSString* aDocType                : Type of document being uploaded.
     */
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:100];

    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    SNOPModel* aSnotModel = [objs objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"%@",aDocType];
    NSLog(@"document_type: %@",docType);

    [runDocDict setObject:docType forKey:@"doc_type"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"time_stamp"];
    [runDocDict setObject:customRunFile forKey:@"run_info"];

    [[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:aCouchDBName] addDocument:runDocDict tag:kSmellieRunDocumentAdded];
}

-(NSNumber*) fetchRecentConfigVersion
{
    /*
     Query smellie config documenets on the smelliedb to find the most recent config versioning
     number.
    */
    //Collect a series of objects from the SNOPModel
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noSNOPModel"
                          reason:@"*** Please add a SNOPModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%u/smellie/_design/smellieMainQuery/_view/fetchMostRecentConfigVersion?descending=True&limit=1",[aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSNumber *currentVersionNumber;
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error =  nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if(!error){
        @try{
            //format the json response
            NSString *stringValueOfCurrentVersion = [NSString stringWithFormat:@"%@",[[[json valueForKey:@"rows"] valueForKey:@"value"]objectAtIndex:0]];
            currentVersionNumber = [NSNumber numberWithInt:[stringValueOfCurrentVersion intValue]];
        }
        @catch (NSException *e) {
            NSLog(@"Error in fetching the SMELLIE CONFIGURATION FILE: %@ . Please fix this before changing the configuration file",e);
        }
    }else{
        NSLog(@"Error querying couchDB, please check the connection is correct %@",error);
    }
    
    return currentVersionNumber;
}

-(NSNumber*) fetchConfigVersionFor:(NSString*)name
{
    /* 
     Find and return the version number of a named config doc
    */
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noSNOPModel"
                          reason:@"*** Please add a SNOPModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString *urlString = [NSString stringWithFormat:@"http://%@:%u/smellie/_design/smellieMainQuery/_view/pullEllieConfigHeaders",[aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error =  nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if(error){
        NSException* e = [NSException
                          exceptionWithName:@"jsonReadError"
                          reason:@"*** Database JSON could not be read properly"
                          userInfo:nil];
        [e raise];
    }
    NSDictionary* entries = [json objectForKey:@"rows"];
    for(NSDictionary* entry in entries){
        if([[entry valueForKey:@"value"] valueForKey:@"config_name"]){
            NSString* configName = [NSString stringWithFormat:@"%@",[[entry valueForKey:@"value"] valueForKey:@"config_name"]];
            if([configName isEqualToString:name]){
                NSString* stringValueOfCurrentVersion = [NSString stringWithFormat:@"%@",[entry valueForKey:@"key"]];
                return [stringValueOfCurrentVersion intValue];
            }
        }
    }
    NSString* reason = [NSString stringWithFormat:@"*** Cannot find a smellie config file with name %@", name];
    NSException* e = [NSException
                      exceptionWithName:@"noConfigForName"
                      reason:reason
                      userInfo:nil];
    [e raise];
    return nil;
}

-(NSMutableDictionary*) fetchConfigurationFile:(NSNumber*)currentVersion
{
    /*
     Fetch the current configuration document of a given version number.
     
     Arguments:
        NSNumber* currentVersion: The version number to be used with the query.
    */
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noSNOPModel"
                          reason:@"*** Please add a SNOPModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString *urlString = [NSString stringWithFormat:@"http://%@:%u/smellie/_design/smellieMainQuery/_view/pullEllieConfigHeaders?key=[%i]&limit=1",[aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort],[currentVersion intValue]];

    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error =  nil;
    NSMutableDictionary *currentConfig = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if(!error){
        NSLog(@"sucessful query");
    }else{
        NSLog(@"Error querying couchDB, please check the connection is correct %@",error);
    }

    [ret release];

    NSMutableDictionary* configForSmellie = [[[[currentConfig objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"] objectForKey:@"configuration_info"];

    //Set laser head to sepia mapping
    NSMutableDictionary *laserHeadToSepiaMapping = [[NSMutableDictionary alloc] initWithCapacity:10];
    for(int laserHeadIndex =0; laserHeadIndex < 6; laserHeadIndex++){
        for (id specificConfigValue in configForSmellie){
            if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput%i",laserHeadIndex]]){
                NSString *laserHeadConnected = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"laserHeadConnected"]];
                [laserHeadToSepiaMapping setObject:[NSString stringWithFormat:@"%i",laserHeadIndex] forKey:laserHeadConnected];
            }
        }
    }
    [self setSmellieLaserHeadToSepiaMapping:laserHeadToSepiaMapping];
    [laserHeadToSepiaMapping release];

    //Set laser head to gain control mapping
    NSMutableDictionary *laserHeadToGainControlMapping = [[NSMutableDictionary alloc] initWithCapacity:10];
    for(int laserHeadIndex =0; laserHeadIndex < 6; laserHeadIndex++){
        for (id specificConfigValue in configForSmellie){
            if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput%i",laserHeadIndex]]){
                NSString *laserHeadConnected = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"laserHeadConnected"]];
                NSString *laserGainControl = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"gainControlFactor"]];
                [laserHeadToGainControlMapping setObject:[NSString stringWithFormat:@"%@",laserGainControl] forKey:laserHeadConnected];
            }
        }
    }
    [self setSmellieLaserHeadToGainMapping:laserHeadToGainControlMapping];
    [laserHeadToGainControlMapping release];

    //Set laser to input fibre mapping
    NSMutableDictionary *laserToInputFibreMapping = [[NSMutableDictionary alloc] initWithCapacity:10];
    for (id specificConfigValue in configForSmellie){

        if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput0"]]
           || [specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput1"]]
           || [specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput2"]]
           || [specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput3"]]
           || [specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput4"]]
           || [specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput5"]]){
            NSString *fibreSwitchInputConnected = [[configForSmellie objectForKey:specificConfigValue] objectForKey:@"fibreSwitchInputConnected"];
            NSString* parsedFibreReference = [fibreSwitchInputConnected stringByReplacingOccurrencesOfString:@"Channel" withString:@""];
            NSString * laserHeadReference = [[configForSmellie objectForKey:specificConfigValue] objectForKey:@"laserHeadConnected"];
            [laserToInputFibreMapping setObject:parsedFibreReference forKey:laserHeadReference];
        }
    }
    [self setSmellieLaserToInputFibreMapping:laserToInputFibreMapping];
    [laserToInputFibreMapping release];

    //Set fibre switch to fibre mapping
    NSMutableDictionary *fibreSwitchOutputToFibre = [[NSMutableDictionary alloc] initWithCapacity:10];
    for(int outputChannelIndex = 1; outputChannelIndex < 15; outputChannelIndex++){
        for (id specificConfigValue in configForSmellie){
            if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"Channel%i",outputChannelIndex]]){
                NSString *fibreReference = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"detectorFibreReference"]];
                [fibreSwitchOutputToFibre setObject:[NSString stringWithFormat:@"%i",outputChannelIndex] forKey:fibreReference];
            }
        }
    }
    [self setSmellieFibreSwitchToFibreMapping:fibreSwitchOutputToFibre];
    [fibreSwitchOutputToFibre release];

    return configForSmellie;
}


/****************************************/
/*        Misc generic methods          */
/****************************************/
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp
{
    /*
     Checks a result returned from a couchdb query for ellie doocument add / retrieval
     tags.
     
     Arguments:
     id aResult:     Object returned by cauchdb query.
     NSString* aTag: The query tag to check against expected cases.
     id anOp:        This doesn't appear to be used??
     */
    @synchronized(self){
        if([aResult isKindOfClass:[NSDictionary class]]){
            NSString* message = [aResult objectForKey:@"Message"];
            if(message){
                [aResult prettyPrint:@"CouchDB Message:"];
            }

            //Look through all of the possible tags for ellie couchDB results

            //This is called when smellie run header is queried from CouchDB
            if ([aTag isEqualToString:kSmellieRunHeaderRetrieved]){
                NSLog(@"Object: %@\n",aResult);
                NSLog(@"result: %@\n",[aResult objectForKey:@"run_name"]);
                //[self parseSmellieRunHeaderDoc:aResult];
            }else if ([aTag isEqualToString:kSmellieConfigHeaderRetrieved]){
                NSLog(@"Smellie configuration file Object: %@\n",aResult);
                //[self parseSmellieConfigHeaderDoc:aResult];
            }else if ([aTag isEqualToString:kTellieRunDocumentAdded]){
                NSMutableDictionary* runDoc = [[self tellieRunDoc] mutableCopy];
                [runDoc setObject:[aResult objectForKey:@"id"] forKey:@"_id"];
                self.tellieRunDoc = runDoc;
                [runDoc release];
            } else if ([aTag isEqualToString:kSmellieRunDocumentAdded]){
                NSMutableDictionary* runDoc = [[self smellieRunDoc] mutableCopy];
                [runDoc setObject:[aResult objectForKey:@"id"] forKey:@"_id"];
                [self setSmellieRunDoc:runDoc];
                [runDoc release];
            }
            //If no tag is found for the query result
            else {
                NSLog(@"No Tag assigned to that query/couchDB View \n");
                NSLog(@"Object: %@\n",aResult);
            }
        }

        else if([aResult isKindOfClass:[NSArray class]]){
            [aResult prettyPrint:@"CouchDB"];
        }else{
            //no docs found 
        }
    }
}

- (ORCouchDB*) orcaDbRefWithEntryDB:(id)aCouchDelegate withDB:(NSString*)entryDB;
{
    /*
     Get an ORCouchDB object pointing to a sno+ couchDB repo.
     
     Arguments:
     id aCouchDelegate:  An ELLIEModel object which will be delgated some functionality during
     ORCouchDB function calls.
     NSString* entryDB:  The SNO+ couchDB repo to be assocated with the ORCouchDB object.
     
     Returns:
     ORCouchDB* result:  An ORCouchDB object pointing to the entryDB repo.
     
     COMMENT:
     I'm not sure why this is here? There is an identical method in SNOPModel. Might be worth
     deleting this method and replacing any reference to it with the SNOPModel version.
     */
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    SNOPModel* aSnotModel = [objs objectAtIndex:0];

    ORCouchDB* result = [ORCouchDB couchHost:aSnotModel.orcaDBIPAddress
                                        port:aSnotModel.orcaDBPort
                                    username:aSnotModel.orcaDBUserName
                                         pwd:aSnotModel.orcaDBPassword
                                    database:entryDB
                                    delegate:self];
    
    if (aCouchDelegate)
        [result setDelegate:aCouchDelegate];
    
    return result;
}

- (ORCouchDB*) generalDBRef:(NSString*)aCouchDb
{
    /*
     Get and return a reference to a couchDB repo.
     
     Arguments:
     NSString* aCouchDb : The database name e.g. telliedb/rat
     */
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];

    //Initialise the SNOPModel
    SNOPModel* aSnotModel = [objs objectAtIndex:0];

    //Commented out for testing
    return [ORCouchDB couchHost:[aSnotModel orcaDBIPAddress]
                           port:[aSnotModel orcaDBPort]
                       username:[aSnotModel orcaDBUserName]
                            pwd:[aSnotModel orcaDBPassword]
                       database:aCouchDb
                       delegate:aSnotModel];
}

- (NSString*) stringDateFromDate:(NSDate*)aDate
{
    /*
     Format date object to a string for inclusion in couchDB files.
     
     Arguments:
     NSDate* aDate : A NSDate object with the current time / date.
     
     Returns:
     NSString* result : The date formatted into a human readable sting.
     */
    NSDateFormatter* snotDateFormatter = [[NSDateFormatter alloc] init];
    [snotDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SS'Z'"];
    snotDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSDate* strDate;
    if (!aDate)
        strDate = [NSDate date];
    else
        strDate = aDate;
    NSString* result = [snotDateFormatter stringFromDate:strDate];
    [snotDateFormatter release];

    return result;
}

- (NSString*) stringUnixFromDate:(NSDate*)aDate
{
    /*
     Format date object to a string with the standard unix format.
     
     Arguments:
     NSDate* aDate : A NSDate object with the current time / date.
     
     Returns:
     NSString* result : The date formatted into a human readable sting.
     */
    NSDate* strDate;
    if(!aDate){
        strDate = [NSDate date];
    }else{
        strDate = aDate;
    }
    NSString* result = [NSString stringWithFormat:@"%f",[strDate timeIntervalSince1970]];
    strDate = nil;

    return result;
}

@end
