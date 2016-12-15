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
#import "TUBiiModel.h"
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
NSString* ORSMELLIERunFinished = @"ORSMELLIERunFinished";
NSString* ORTELLIERunFinished = @"ORTELLIERunFinished";



///////////////////////////////
// Define private methods
@interface ELLIEModel (private)
-(void) _pushEllieCustomRunToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile withDocType:(NSString*)aDocType;
-(void) _pushEllieConfigDocToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile withDocType:(NSString*)aDocType;
-(NSString*) stringDateFromDate:(NSDate*)aDate;
-(void) _pushSmellieRunDocument;
//-(void) _pushSmellieConfigDocument;
@end


//////////////////////////////
// Begin implementation
@implementation ELLIEModel

// Use synthesize to generate all our setters and getters.
// Be explicit about which instance variables to associate
// with each.
@synthesize tellieFireParameters = _tellieFireParameters;
@synthesize tellieFibreMapping = _tellieFibreMapping;
@synthesize tellieNodeMapping = _tellieNodeMapping;
@synthesize tellieRunDoc = _tellieRunDoc;
@synthesize tellieSubRunSettings = _tellieSubRunSettings;

@synthesize smellieRunSettings = _smellieRunSettings;
@synthesize smellieRunHeaderDocList = _smellieRunHeaderDocList;
@synthesize smellieSubRunInfo = _smellieSubRunInfo;
@synthesize smellieLaserHeadToSepiaMapping = _smellieLaserHeadToSepiaMapping;
@synthesize smellieLaserHeadToGainMapping = _smellieLaserHeadToGainMapping;
@synthesize smellieLaserToInputFibreMapping = _smellieLaserToInputFibreMapping;
@synthesize smellieFibreSwitchToFibreMapping = _smellieFibreSwitchToFibreMapping;
@synthesize smellieSlaveMode = _smellieSlaveMode;
@synthesize smellieConfigVersionNo = _smellieConfigVersionNo;
@synthesize smellieRunDoc = _smellieRunDoc;
@synthesize smellieDBReadInProgress = _smellieDBReadInProgress;

@synthesize tellieClient = _tellieClient;
@synthesize smellieClient = _smellieClient;

@synthesize ellieFireFlag = _ellieFireFlag;
@synthesize exampleTask = _exampleTask;
@synthesize pulseByPulseDelay = _pulseByPulseDelay;
@synthesize currentOrcaSettingsForSmellie = _currentOrcaSettingsForSmellie;


/*********************************************************/
/*                  Class control methods                */
/*********************************************************/
- (id) init
{
    self = [super init];
    if (self){
        XmlrpcClient* tellieCli = [[XmlrpcClient alloc] initWithHostName:@"builder1" withPort:@"5030"];
        XmlrpcClient* smellieCli = [[XmlrpcClient alloc] initWithHostName:@"0.0.0.0" withPort:@"5020"];
        [self setTellieClient:tellieCli];
        [self setSmellieClient:smellieCli];
        [[self tellieClient] setTimeout:10];
        [[self smellieClient] setTimeout:20];
        [tellieCli release];
        [smellieCli release];
    }
    return self;
}

-(id) initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];
    if (self){
        XmlrpcClient* tellieCli = [[XmlrpcClient alloc] initWithHostName:@"builder1" withPort:@"5030"];
        XmlrpcClient* smellieCli = [[XmlrpcClient alloc] initWithHostName:@"0.0.0.0" withPort:@"5020"];
        [self setTellieClient:tellieCli];
        [self setSmellieClient:smellieCli];
        [[self tellieClient] setTimeout:10];
        [[self smellieClient] setTimeout:20];
        [tellieCli release];
        [smellieCli release];
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

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Release all NSObject member vairables
    [_smellieRunSettings release];
    [_currentOrcaSettingsForSmellie release];
    [_tellieRunDoc release];
    [_smellieRunDoc release];
    [_exampleTask release];
    [_smellieRunHeaderDocList release];
    [_smellieSubRunInfo release];
    
    //Server Clients
    [_tellieClient release];
    [_smellieClient release];
    
    //tellie settings
    [_tellieSubRunSettings release];
    [_tellieFireParameters release];
    [_tellieFibreMapping release];
    
    //smellie config mappings
    [_smellieLaserHeadToSepiaMapping release];
    [_smellieLaserHeadToGainMapping release];
    [_smellieLaserToInputFibreMapping release];
    [_smellieFibreSwitchToFibreMapping release];
    [_smellieConfigVersionNo release];
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
    NSArray* blankResponse = [NSArray arrayWithObjects:[NSNumber numberWithInt:0], [NSNumber numberWithInt:0], nil];
    NSArray* pollResponse = [[self tellieClient] command:@"read_pin_sequence"];
    int count = 0;
    NSLog(@"[TELLIE]: Will poll for pin response for the next %1.1f s\n", timeOutSeconds);
    while ([pollResponse isKindOfClass:[NSString class]] && count < timeOutSeconds){
        [NSThread sleepForTimeInterval:1.0];
        pollResponse = [[self tellieClient] command:@"read_pin_sequence"];
        count = count + 1;
    }
    
    // Some checks on the response
    if ([pollResponse isKindOfClass:[NSString class]]){
        NSString* reasonStr = [NSString stringWithFormat:@"*** PIN diode poll returned %@. Likely that the sequence didn't finish before timeout.", pollResponse];
        NSException* e = [NSException
                          exceptionWithName:@"stringPinResponse"
                          reason:reasonStr
                          userInfo:nil];
        NSLogColor([NSColor redColor], @"[TELLIE]: %@\n", [e reason]);
        return blankResponse;
    } else if ([pollResponse count] != 3) {
        NSString* reasonStr = [NSString stringWithFormat:@"*** PIN diode poll returned array of len %i - expected 3", [pollResponse count]];
        NSException* e = [NSException
                          exceptionWithName:@"PinResponseBadArrayLength"
                          reason:reasonStr
                          userInfo:nil];
        NSLogColor([NSColor redColor], @"[TELLIE]: %@\n", [e reason]);
        return blankResponse;
    }
    return pollResponse;
}

-(NSMutableDictionary*) returnTellieFireCommands:(NSString*)fibre withNPhotons:(NSUInteger)photons withFireFrequency:(NSUInteger)frequency withNPulses:(NSUInteger)pulses withTriggerDelay:(NSUInteger)delay inSlave:(BOOL)mode
{
    /*
     Calculate the tellie fire commands given certain input parameters
    */
    NSNumber* tellieChannel = [self calcTellieChannelForFibre:fibre];
    if([tellieChannel intValue] < 0){
        return nil;
    }

    NSNumber* pulseWidth = [self calcTellieChannelPulseSettings:[tellieChannel integerValue] withNPhotons:photons withFireFrequency:frequency inSlave:mode];
    if([pulseWidth intValue] < 0){
        return nil;
    }
    
    NSString* modeString;
    if(mode == YES){
        modeString = @"Slave";
    } else {
        modeString = @"Master";
    }
    float pulseSeparation = 1000.*(1./frequency); // TELLIE accepts pulse rate in ms
    NSNumber* fibre_delay = [[[self tellieFireParameters] objectForKey:[NSString stringWithFormat:@"channel_%d",[tellieChannel intValue]]] objectForKey:@"fibre_delay"];
    
    NSMutableDictionary* settingsDict = [NSMutableDictionary dictionaryWithCapacity:100];
    [settingsDict setValue:fibre forKey:@"fibre"];
    [settingsDict setValue:tellieChannel forKey:@"channel"];
    [settingsDict setValue:modeString forKey:@"run_mode"];
    [settingsDict setValue:[NSNumber numberWithInteger:photons] forKey:@"photons"];
    [settingsDict setValue:pulseWidth forKey:@"pulse_width"];
    [settingsDict setValue:[NSNumber numberWithFloat:pulseSeparation] forKey:@"pulse_separation"];
    [settingsDict setValue:[NSNumber numberWithInteger:pulses] forKey:@"number_of_shots"];
    [settingsDict setValue:[NSNumber numberWithInteger:delay] forKey:@"trigger_delay"];
    [settingsDict setValue:[NSNumber numberWithFloat:[fibre_delay floatValue]] forKey:@"fibre_delay"];
    [settingsDict setValue:[NSNumber numberWithInteger:16383] forKey:@"pulse_height"];
    NSLog(@"Tellie settings dict sucessfully created!\n");
    return settingsDict;
}

-(NSNumber*) calcTellieChannelPulseSettings:(NSUInteger)channel withNPhotons:(NSUInteger)photons withFireFrequency:(NSUInteger)frequency inSlave:(BOOL)mode
{
    /*
     Calculate the pulse width settings required to return a given intenstity from a specified channel, 
     at a specified rate.
    */
    // Check if fire parameters have been successfully loaded
    if([self tellieFireParameters] == nil){
        NSException* e = [NSException
                          exceptionWithName:@"NoTellieFireParameters"
                          reason:@"*** TELLIE_FIRE_PARMETERS doc has not been loaded from telliedb - you need to call loadTellieStaticsFromDB"
                          userInfo:nil];
        NSLogColor([NSColor redColor], @"[TELLIE]: %@\n", [e reason]);
        return 0;
    }
    
    // Run photon intensity check
    bool safety_check = [self photonIntensityCheck:photons atFrequency:frequency];
    if(safety_check == NO){
        NSLogColor([NSColor redColor], @"[TELLIE] The request number of photons (%lu), is not detector safe at %lu Hz. This setting will not be run.\n", photons, frequency);
        return [NSNumber numberWithInt:-1];
    }
    
    // Frequency check
    if(frequency != 1000){
        NSLogColor([NSColor redColor], @"[TELLIE] CAUTION: calibrations are only valid at 1kHz. Photon output may not be vary from requested setting\n");
    }
    
    // Used modality to define a string prefix for reading from database file
    NSString* prefix;
    if(mode == YES){
        prefix = @"slave";
    } else {
        prefix = @"master";
    }
    
    // Get Calibration parameters
    NSArray* IPW_values = [[[self tellieFireParameters] objectForKey:[NSString stringWithFormat:@"channel_%d",channel]] objectForKey:[NSString stringWithFormat:@"%@_IPW",prefix]];
    NSArray* photon_values = [[[self tellieFireParameters] objectForKey:[NSString stringWithFormat:@"channel_%d",channel]] objectForKey:[NSString stringWithFormat:@"%@_photons",prefix]];

    ////////////
    // Find minimum calibration point. If request is below minimum, estiamate the IPW
    // setting and inform the user.
    float min_photons = [[photon_values valueForKeyPath:@"@min.self"] floatValue];
    int min_x = [[IPW_values objectAtIndex:[photon_values indexOfObject:[photon_values valueForKeyPath:@"@min.self"]]] intValue];
    if(photons < min_photons){
        NSLog(@"Calibration curve for channel %lu does not go as low as %lu photons\n", channel, photons);
        NSLog(@"Using a linear interpolation of 5ph/IPW from min_photons = %.1f to estimate requested %d photon settings\n",min_photons,photons);
        float intercept = min_photons - (-5.*min_x);
        float floatPulseWidth = (min_photons - intercept)/(-5.);
        NSNumber* pulseWidth = [NSNumber numberWithInteger:floatPulseWidth];
        NSLog(@"IPW setting calculated as: %d\n",[pulseWidth intValue]);
        return pulseWidth;
    }
    
    /////////////
    // If requested photon output is within range, find xy points above and below threshold.
    // Appropriate setting will be estiamated with a linear interpolation between these points.
    int index = 0;
    for(NSNumber* val in photon_values){
        if([val floatValue] < photons){
            break;
        }
        index = index + 1;
    }
    float x1 = [[IPW_values objectAtIndex:(index-1)] floatValue];
    float x2 = [[IPW_values objectAtIndex:(index)] floatValue];
    float y1 = [[photon_values objectAtIndex:(index-1)] floatValue];
    float y2 = [[photon_values objectAtIndex:(index)] floatValue];
    
    // Calculate gradient and offset for interpolation.
    float dydx = (y1 - y2)/(x1 - x2);
    float intercept = y1 - dydx*x1;
    float floatPulseWidth = (photons - intercept) / dydx;
    NSNumber* pulseWidth = [NSNumber numberWithInteger:floatPulseWidth];
    NSLog(@"IPW setting calculated as: %d\n",[pulseWidth intValue]);

    return pulseWidth;
}

-(NSNumber*)calcPhotonsForIPW:(NSUInteger)ipw forChannel:(NSUInteger)channel inSlave:(BOOL)inSlave
{
    /*
     Calculte what photon output will be produced for a given IPW
     */
    
    /////////////
    // Used modality to define a string prefix for reading from database file
    NSString* prefix;
    if(inSlave == YES){
        prefix = @"slave";
    } else {
        prefix = @"master";
    }
    
    //////////////
    // Get Calibration parameters
    NSArray* IPW_values = [[[self tellieFireParameters] objectForKey:[NSString stringWithFormat:@"channel_%d",channel]] objectForKey:[NSString stringWithFormat:@"%@_IPW",prefix]];
    NSArray* photon_values = [[[self tellieFireParameters] objectForKey:[NSString stringWithFormat:@"channel_%d",channel]] objectForKey:[NSString stringWithFormat:@"%@_photons",prefix]];
    
    ////////////
    // Find minimum calibration point. If request is below minimum, estiamate the IPW
    // setting and inform the user.
    float min_photons = [[photon_values valueForKeyPath:@"@min.self"] floatValue];
    int max_ipw = [[IPW_values objectAtIndex:[photon_values indexOfObject:[photon_values valueForKeyPath:@"@min.self"]]] intValue];
    if(ipw > max_ipw){
        NSLog(@"Requested IPW is larger than any value in the calibration curve.\n");
        NSLog(@"Using a linear interpolation of 5ph/IPW from min_photons = %.1f (IPW = %d) to estimate photon output at requested setting\n",min_photons, max_ipw);
        float intercept = min_photons - (-5.*max_ipw);
        float photonsFloat = (-5.*ipw) + intercept;
        if(photonsFloat < 0){
            photonsFloat = 0.;
        }
        NSNumber* photons = [NSNumber numberWithFloat:photonsFloat];
        NSLog(@"Photons output calculated as: %1.2f\n",[photons floatValue]);
        return photons;
    }
    
    /////////////
    // If requested photon output is within range, find xy points above and below threshold.
    // Appropriate setting will be estiamated with a linear interpolation between these points.
    int index = 0;
    for(NSNumber* val in IPW_values){
        if([val intValue] > ipw){
            break;
        }
        index = index + 1;
    }
    float x1 = [[IPW_values objectAtIndex:(index-1)] floatValue];
    float x2 = [[IPW_values objectAtIndex:(index)] floatValue];
    float y1 = [[photon_values objectAtIndex:(index-1)] floatValue];
    float y2 = [[photon_values objectAtIndex:(index)] floatValue];
    
    // Calculate gradient and offset for interpolation.
    float dydx = (y1 - y2)/(x1 - x2);
    float intercept = y1 - dydx*x1;
    float photonsFloat = (dydx*ipw) + intercept;
    NSNumber* photons = [NSNumber numberWithInteger:photonsFloat];
    NSLog(@"Photon output calculated as: %1.1f\n",[photons floatValue]);
    
    return photons;
}

-(BOOL)photonIntensityCheck:(NSUInteger)photons atFrequency:(NSUInteger)frequency
{
    /*
     A detector safety check. At high frequencies the maximum tellie output must be small
     to avoid pushing too much current through individual channels / trigger sums.
     */
    float safe_gradient = -1e3;
    float safe_intercept = 1.0011e6;
    float max_photons = safe_gradient*frequency + safe_intercept;
    if(photons > max_photons){
        return NO;
    } else {
        return YES;
    }
}

-(NSString*)calcTellieFibreForNode:(NSUInteger)node{
    /*
     Use node-to-fibre map loaded from the telliedb to find the priority fibre on a node.
     */
    if(![[self tellieNodeMapping] objectForKey:[NSString stringWithFormat:@"panel_%d",node]]){
        NSString* reasonStr = [NSString stringWithFormat:@"*** Node map does not include a reference to node: %d",node];
        NSException* eNode = [NSException
                               exceptionWithName:@"NoFibresFoundOnNode"
                               reason:reasonStr
                               userInfo:nil];
        NSLogColor([NSColor redColor], @"[TELLIE] %@\n", [eNode reason]);
        return nil;
    }
    
    // Read panel info into local dictionary
    NSMutableDictionary* nodeInfo = [[self tellieNodeMapping] objectForKey:[NSString stringWithFormat:@"panel_%d",node]];
    
    //***************************************//
    // Select appropriate fibre for this node.
    //***************************************//
    NSMutableArray* goodFibres = [[NSMutableArray alloc] init];
    NSMutableArray* lowTransFibres = [[NSMutableArray alloc] init];
    NSMutableArray* brokenFibres = [[NSMutableArray alloc] init];
    // Find which fibres are good / bad etc.
    for(NSString* key in nodeInfo){
        if([[nodeInfo objectForKey:key] intValue] ==  0){
            [goodFibres addObject:key];
        } else if([[nodeInfo objectForKey:key] intValue] ==  1){
            [lowTransFibres addObject:key];
        } else if([[nodeInfo objectForKey:key] intValue] ==  2){
            [brokenFibres addObject:key];
        }
    }
    
    NSString* selectedFibre = @"";
    if([goodFibres count] > 0){
        selectedFibre = [self selectPriorityFibre:goodFibres forNode:node];
    } else if([lowTransFibres count] > 0){
        selectedFibre = [self selectPriorityFibre:lowTransFibres forNode:node];
        NSLogColor([NSColor redColor], @"[TELLIE]: Selected low trasmission fibre %@\n", selectedFibre);
    } else if([brokenFibres count] > 0){
        selectedFibre = [self selectPriorityFibre:brokenFibres forNode:node];
        NSLogColor([NSColor redColor], @"[TELLIE]: Selected broken fibre %@\n", selectedFibre);
    }
    
    [goodFibres release];
    [lowTransFibres release];
    [brokenFibres release];

    return selectedFibre;
}

-(NSNumber*) calcTellieChannelForFibre:(NSString*)fibre
{
    /*
     Use patch pannel map loaded from the telliedb to map a given fibre to the correct tellie channel.
    */
    if([self tellieFibreMapping] == nil){
        NSException* e = [NSException
                          exceptionWithName:@"EmptyFibreMappingProperty"
                          reason:@"*** Fibre map has not been loaded from couchdb - you need to call loadTellieStaticsFromDB"
                          userInfo:nil];
        NSLogColor([NSColor redColor], @"[TELLIE]: %@\n", [e reason]);
        return [NSNumber numberWithInt:-1];
    }
    if(![[[self tellieFibreMapping] objectForKey:@"fibres"] containsObject:fibre]){
        NSString* reasonStr = [NSString stringWithFormat:@"*** Patch map does not include a reference to fibre: %@",fibre];
        NSException* eFibre = [NSException
                               exceptionWithName:@"FibreNotPatched"
                               reason:reasonStr
                               userInfo:nil];
        NSLogColor([NSColor redColor], @"[TELLIE]: %@\n", [eFibre reason]);
        return [NSNumber numberWithInt:-2];
        //[eFibre raise];
    }
    NSUInteger fibreIndex = [[[self tellieFibreMapping] objectForKey:@"fibres"] indexOfObject:fibre];
    NSUInteger channelInt = [[[[self tellieFibreMapping] objectForKey:@"channels"] objectAtIndex:fibreIndex] integerValue];
    NSNumber* channel = [NSNumber numberWithInt:channelInt];
    NSLog(@"Fibre: %@ corresponds to tellie channel %d\n",fibre, channelInt);
    return channel;
}

-(NSString*)selectPriorityFibre:(NSArray*)fibres forNode:(NSUInteger)node{
    /*
     Select appropriate fibre based on naming convensions for the node at
     which they were installed.
     */
    
    //First find if primary / secondary fibres exist.
    NSString* primaryFibre = [NSString stringWithFormat:@"FT%03dA", node];
    NSString* secondaryFibre = [NSString stringWithFormat:@"FT%03dB", node];
    
    if([fibres indexOfObject:primaryFibre] != NSNotFound){
        return [fibres objectAtIndex:[fibres indexOfObject:primaryFibre]];
    }
    if([fibres indexOfObject:secondaryFibre] != NSNotFound){
        return [fibres objectAtIndex:[fibres indexOfObject:secondaryFibre]];
    }
    
    // If priority fibres don't exist, sort others into A/B arrays
    NSMutableArray* aFibres = [[NSMutableArray alloc] init];
    NSMutableArray* bFibres = [[NSMutableArray alloc] init];
    for(NSString* fibre in fibres){
        if([fibre rangeOfString:@"A"].location != NSNotFound){
            [aFibres addObject:fibre];
        } else if([fibre rangeOfString:@"B"].location != NSNotFound){
            [bFibres addObject:fibre];
        }
    }
    
    // Select from available fibes, with a preference for A type
    NSString* returnFibre = @"";
    if([aFibres count] > 0){
        returnFibre = [aFibres objectAtIndex:0];
    } else if ([bFibres count] > 0){
        returnFibre = [bFibres objectAtIndex:0];
    }
    [aFibres release];
    [bFibres release];
    return returnFibre;
}

-(void) startTellieRun:(NSMutableDictionary*)fireCommands
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
    ///////////
    //Set tellieFiring flag
    [self setEllieFireFlag:YES];
    NSLog(@"ELLIE fire flag set to: %@\n",@YES);

    //////////
    /// This will likely be run in a thread so set-up an auto release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    ///////////
    // Make a sting accessable inside err; incase of error.
    NSString* errorString;

    //////////////
    //Get a Tubii object
    NSArray*  tubiiModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    if(![tubiiModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Couldn't find Tubii model.\n");
        [pool release];
        return;
    }
    TUBiiModel* theTubiiModel = [tubiiModels objectAtIndex:0];
 
    //Add run control object
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noRunModel"
                          reason:@"*** Please add a ORRunModel to the experiment"
                          userInfo:nil];
        NSLogColor([NSColor redColor], @"[TELLIE]: Couldn't find ORRunModel %@\n", [e reason]);
        [pool release];
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];
    
    // RUN CONTROL
    //
    //Set up run control
    // This is temporarily commented out as it needs to be replaced with a check on standard run type.
    // We need to make sure that we're in a tellie run (run type word properly set etc) else exit.
    /*
    if(![runControl isRunning]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Starting our own run! \n");
        [runControl performSelectorOnMainThread:@selector(startRun) withObject:nil waitUntilDone:YES];
    }else{
        NSLogColor([NSColor redColor], @"[SMELLIE]: Restarting run! \n");
        [runControl performSelectorOnMainThread:@selector(restartRun) withObject:nil waitUntilDone:YES];
    }
    */
    
    //////////////
    // Get run mode boolean
    BOOL isSlave = YES;
    NSLog(@"Run mode: %@\n", [fireCommands objectForKey:@"run_mode"]);
    if([[fireCommands objectForKey:@"run_mode"] isEqualToString:@"Master"]){
        isSlave = NO;
    }
    
    /////////////
    // Final settings check
    NSLog(@"Pulse sep: %1.1f ms\n", [[fireCommands objectForKey:@"pulse_separation"] floatValue]);
    NSLog(@"Pulse width: %d\n", [[fireCommands objectForKey:@"pulse_width"] integerValue]);
    NSNumber* photonOutput = [self calcPhotonsForIPW:[[fireCommands objectForKey:@"pulse_width"] integerValue] forChannel:[[fireCommands objectForKey:@"channel"] integerValue] inSlave:isSlave];
    float rate = 1000.*(1./[[fireCommands objectForKey:@"pulse_separation"] floatValue]);
    NSLog(@"photon Output: %i photons / pulse\n", [photonOutput integerValue]);
    NSLog(@"Rate: %1.1f Hz\n", rate);
    BOOL safety_check = [self photonIntensityCheck:[photonOutput integerValue] atFrequency:rate];
    if(safety_check == NO){
        NSLogColor([NSColor redColor], @"[TELLIE] The request number of photons (%lu), is not detector safe at %f Hz. This setting will not be run.\n", [photonOutput integerValue], rate);
        return;
    }
    
    /////////////
    // TELLIE pin readout is an average measurement of the passed "number_of_shots".
    // If a large number of shots are requested it is useful to split the data into smaller chunks,
    // this way we get multiple pin readings.
    NSNumber* loops = [NSNumber numberWithInteger:1];
    int totalShots = [[fireCommands objectForKey:@"number_of_shots"] integerValue];
    float fRemainder = fmod(totalShots, 5e3);
    //NSLog(@"fRemainder = %@\n", fRemainder);
    if( totalShots > 5e3){
        if (fRemainder > 0){
            int iLoops = (totalShots - fRemainder) / 5e3;
            loops = [NSNumber numberWithInteger:(iLoops+1)];
        } else {
            int iLoops = totalShots / 5e3;
            loops =[NSNumber numberWithInteger:iLoops];

        }
    }
    
    ///////////////
    // Now set-up is done, push initial run document
    [self pushInitialTellieRunDocument];
    
    ///////////////
    // Fire loop! Pass variables to the tellie server.
    NSLog(@"Firing in %@ loops\n", loops);
    for(int i = 0; i<[loops integerValue]; i++){
        if([self ellieFireFlag] == NO){
            errorString = @"ELLIE fire flag set to @NO";
            goto err;
        }

        /////////////////
        // Calculate how many shots to fire in this loop
        NSNumber* noShots = [NSNumber numberWithInt:5e3];
        if(i == ([loops integerValue]-1) && fRemainder > 0){
            noShots = [NSNumber numberWithInt:fRemainder];
        }

        NSLog(@"***** FIRING %d TELLIE PULSES in Fibre %@ *****\n",[noShots integerValue], [fireCommands objectForKey:@"fibre"]);
        
        //////////////////
        //Start a new subrun
        [runControl performSelectorOnMainThread:@selector(prepareForNewSubRun) withObject:nil waitUntilDone:YES];
        [runControl performSelectorOnMainThread:@selector(startNewSubRun) withObject:nil waitUntilDone:YES];
        
        //////////////////////
        // Set loop independent tellie channel settings
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
            @try{
                [[self tellieClient] command:@"init_channel" withArgs:fireArgs];
                [NSThread sleepForTimeInterval:7.0f];
            } @catch(NSException *e){
                errorString = [NSString stringWithFormat:@"[TELLIE]: Problem init-ing channel on server: %@\n", [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }
        }
        
        /////////////////////
        // Set loop dependent tellie channel settings
        @try{
            [[self tellieClient] command:@"set_pulse_number" withArgs:@[noShots]];
            [NSThread sleepForTimeInterval:1.0f];
        } @catch(NSException* e) {
            errorString = @"[TELLIE] Problem setting pulse number on server.\n";
            NSLogColor([NSColor redColor], errorString);
            goto err;
        }
        
        ///////////////
        // Make a temporary directoy to add sub_run fields being run in this loop
        NSMutableDictionary* valuesToFillPerSubRun = [NSMutableDictionary dictionaryWithCapacity:100];
        [valuesToFillPerSubRun setDictionary:fireCommands];
        [valuesToFillPerSubRun setObject:noShots forKey:@"number_of_shots"];
        [valuesToFillPerSubRun setObject:photonOutput forKey:@"photons"];
        
        ///////////////
        // Handle master / slave mode firing
        //////////////
        // SLAVE MODE
        if([[fireCommands objectForKey:@"run_mode"] isEqualToString:@"Slave"]){
            ///////////
            // Tell tellie to accept a sequence of external triggers
            @try{
                [[self tellieClient] command:@"trigger_averaged"];
            } @catch(NSException* e) {
                errorString = [NSString stringWithFormat:@"[TELLIE] Problem setting pulse number on server: %@\n", [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }
            ////////////
            // Set the tubii model as ask it to fire
            @try{
                [theTubiiModel setTellieRate:rate];
                [theTubiiModel setTelliePulseWidth:100e-9];
                [theTubiiModel setTellieNPulses:[noShots intValue]];
                //[theTubiiModel fireTelliePulser];
                //noShots = [NSNumber numberWithInteger:[noShots intValue] + 5000];
                [theTubiiModel fireTelliePulser_rate:rate pulseWidth:200e-9 NPulses:[noShots intValue]];
            } @catch(NSException* e){
                errorString = [NSString stringWithFormat:@"[TELLIE] Problem setting tubii parameters: %@\n", [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }
        //////////////
        // MASTER MODE
        } else {
            /////////////
            // Tell tellie to fire a master mode sequence
            @try{
                [[self tellieClient] command:@"fire_sequence"];
            } @catch(NSException* e){
                errorString = [NSString stringWithFormat: @"[TELLIE] Problem requesting tellie master to fire: %@\n", [e reason]];
                NSLogColor([NSColor redColor],errorString);
                goto err;
            }
        }

        //////////////////
        // Poll tellie for a pin reading. Give the sequence a 3s grace period to finish
        // long for some reason
        NSLog(@"Polling for tellie pin response...\n");
        float pollTimeOut = (1./rate)*[noShots floatValue] + 3.;
        NSArray* pinReading = nil;
        @try{
            pinReading = [self pollTellieFibre:pollTimeOut];
        } @catch(NSException* e){
            errorString = [NSString stringWithFormat:@"[TELLIE] Problem polling for pin: %@\n", [e reason]];
            NSLogColor([NSColor redColor], errorString);
            goto err;
        }
        NSLog(@"Pin response received %@ +/- %@\n", [pinReading objectAtIndex:0], [pinReading objectAtIndex:1]);
        @try {
            [valuesToFillPerSubRun setObject:[pinReading objectAtIndex:0] forKey:@"pin_value"];
            [valuesToFillPerSubRun setObject:[pinReading objectAtIndex:1] forKey:@"pin_rms"];
        } @catch (NSException *e) {
            errorString = [NSString stringWithFormat:@"[TELLIE] Unable to add pin readout to sub_run file due to error: %@\n",[e reason]];
            NSLogColor([NSColor redColor], errorString);
            goto err;
        }
        
        ////////////
        // Update run document
        [self updateTellieRunDocument:valuesToFillPerSubRun];
    }

    ////////////
    // Release pooled memory
    [pool release];
    
    ////////////
    // Finish and tidy up
    NSLog(@"[TELLIE]: End of TELLIE Run\n");
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORTELLIERunFinished object:self];
    });
    return;

err:
    {
        [pool release];
        //Resetting the mtcd to settings before the smellie run
        NSLog(@"[TELLIE]: ERROR encountered. Killing TELLIE run.\n");
        
        //Make a dictionary to push into sub-run array to indicate error.
        //NSMutableDictionary* errorDict = [NSMutableDictionary dictionaryWithCapacity:10];
        //[errorDict setObject:errorString forKey:@"tellie_error"];
        //[self updateTellieRunDocument:errorDict];
      
        //Post a note. on the main thread to request a call to stopTellieRun
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ORTELLIERunFinished object:self];
        });
    }
}

-(void) stopTellieRun
{
    /*
     Make tellie stop firing
    */

    //////////////////////
    // Set fire flag to no. If a run sequence is currently underway, this will stop
    [self setEllieFireFlag:NO];
    
    /////////////
    // This may run in a thread so add release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    //////////////////////
    // Send stop command to tellie hardware
    @try{
        NSString* responseFromTellie = [[self tellieClient] command:@"stop"];
        NSLog(@"Sent stop command to tellie, received: %@\n",responseFromTellie);
    } @catch(NSException* e){
        // This should only ever be called from the main thread so can raise
        NSLogColor([NSColor redColor], @"[TELLIE]: Problem with tellie server interpreting stop command!\n");
    }

    ///////////////////
    //Incase of slave, also get a Tubii object so we can stop Tubii sending pulses
    NSArray*  tubiiModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    if(![tubiiModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Couldn't find TUBii model in stopRun.\n");
        [pool release];
        return;
    }
    TUBiiModel* theTubiiModel = [tubiiModels objectAtIndex:0];
    @try{
        [theTubiiModel stopTelliePulser];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"[TELLIE]: Problem stopping TUBii pulser!\n");
    }
    
    // How we want to handle run transtions is currently unclear. It's best not affect the run without the operators
    // express understanding of what that is doing to the detector state. For now I'll comment out this line. That
    // leaves the operator to handle run control themselves .
    /*
    if([runControl isRunning]){
        [runControl performSelectorOnMainThread:@selector(restartRun) withObject:nil waitUntilDone:YES];
    }
    */
    NSLog(@"[TELLIE]: Run finished\n");
    [pool release];
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
        NSLogColor([NSColor redColor], @"[TELLIE]: Couldn't find ORRunModel\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE] Couldn't find SNOPModel\n");
        return;
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"TELLIE_RUN"];
    NSMutableArray* subRunArray = [NSMutableArray arrayWithCapacity:10];

    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@"%lu",[runControl runNumber]] forKey:@"index"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"timestamp"];

    [runDocDict setObject:[NSMutableArray arrayWithObjects:[NSNumber numberWithUnsignedLong:[runControl runNumber]],[NSNumber numberWithUnsignedLong:[runControl runNumber]], nil] forKey:@"run_range"];

    [runDocDict setObject:subRunArray forKey:@"sub_run_info"];

    [self setTellieRunDoc:runDocDict];

    [[aSnotModel orcaDbRefWithEntryDB:self withDB:@"telliedb"] addDocument:runDocDict tag:kTellieRunDocumentAdded];

    //wait for main thread to receive acknowledgement from couchdb
    NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow:2.0];
    while ([timeout timeIntervalSinceNow] > 0 && ![[self tellieRunDoc] objectForKey:@"_id"]) {
        [NSThread sleepForTimeInterval:0.1];
    }
}

- (void) updateTellieRunDocument:(NSDictionary*)subRunDoc
{
    /*
     Update [self tellieRunDoc] with subrun information.
     
     Arguments:
     NSDictionary* subRunDoc:  Subrun information to be added to the current [self tellieRunDoc].
     */
    
    // Get run control
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE] Couldn't find ORRunModel\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];
    
    NSMutableDictionary* runDocDict = [[self tellieRunDoc] mutableCopy];
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
        NSLogColor([NSColor redColor], @"[TELLIE]: Couldn't find SNOPModel %@\n");
        return;
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    // **********************************
    // Load latest calibration constants
    // **********************************
    NSString* parsUrlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/telliedb/_design/tellieQuery/_view/fetchFireParameters?descending=False&limit=1",[aSnotModel orcaDBUserName], [aSnotModel orcaDBPassword], [aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];
    
    NSString* webParsString = [parsUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL* parsUrl = [NSURL URLWithString:webParsString];
    NSMutableURLRequest* parsUrlRequest = [NSMutableURLRequest requestWithURL:parsUrl
                                                                  cachePolicy:0
                                                              timeoutInterval:20];
    
    // Get data string from URL
    NSError* parsDataError =  nil;
    NSURLResponse* parsUrlResponse;
    NSData* parsData = [NSURLConnection sendSynchronousRequest:parsUrlRequest
                                            returningResponse:&parsUrlResponse
                                                        error:&parsDataError];

    if(parsDataError){
        NSLog(@"\n%@\n\n",parsDataError);
    }
    NSString* parsReturnStr = [[NSString alloc] initWithData:parsData encoding:NSUTF8StringEncoding];
    // Format queried data to dictionary
    NSError* parsDictError =  nil;
    NSMutableDictionary* parsDict = [NSJSONSerialization JSONObjectWithData:[parsReturnStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&parsDictError];
    if(parsDictError){
        NSLog(@"Error querying couchDB, please check the connection is correct %@\n",parsDictError);
    }
    [parsReturnStr release];

    NSMutableDictionary* fireParametersDoc =[[[parsDict objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"%TELLIE channel calibrations sucessfully loaded!\n");
    [self setTellieFireParameters:fireParametersDoc];

    // **********************************
    // Load latest fibre-channel mapping doc.
    // **********************************
    NSString* mapUrlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/telliedb/_design/tellieQuery/_view/fetchCurrentMapping?key=0",[aSnotModel orcaDBUserName], [aSnotModel orcaDBPassword], [aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];

    NSString* webMapString = [mapUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL* mapUrl = [NSURL URLWithString:webMapString];
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
    if(mapDictError){
        NSLog(@"Error querying couchDB, please check the connection is correct %@\n",mapDictError);
    }
    [mapReturnStr release];

    NSMutableDictionary* mappingDoc =[[[mapDict objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"TELLIE mapping document sucessfully loaded!\n");
    [self setTellieFibreMapping:mappingDoc];
    
    // **********************************
    // Load latest node-fibre mapping doc.
    // **********************************
    NSString* nodeUrlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/telliedb/_design/mapping/_view/node_to_fibre?descending=True&limit=1",[aSnotModel orcaDBUserName], [aSnotModel orcaDBPassword], [aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];
    
    NSString* webNodeString = [nodeUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL* nodeUrl = [NSURL URLWithString:webNodeString];
    NSMutableURLRequest* nodeUrlRequest = [NSMutableURLRequest requestWithURL:nodeUrl
                                                                  cachePolicy:0
                                                              timeoutInterval:20];
    
    // Get data string from URL
    NSError* nodeDataError =  nil;
    NSURLResponse* nodeUrlResponse;
    NSData* nodeData = [NSURLConnection sendSynchronousRequest:nodeUrlRequest
                                             returningResponse:&nodeUrlResponse
                                                         error:&nodeDataError];
    if(nodeDataError){
        NSLog(@"\n%@\n\n",nodeDataError);
    }
    NSString* nodeReturnStr = [[NSString alloc] initWithData:nodeData encoding:NSUTF8StringEncoding];
    
    // Format queried data to dictionary
    NSError* nodeDictError =  nil;
    NSMutableDictionary* nodeDict = [NSJSONSerialization JSONObjectWithData:[nodeReturnStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&nodeDictError];
    if(nodeDictError){
        NSLog(@"Error querying couchDB, please check the connection is correct %@\n",nodeDictError);
    }
    
    NSMutableDictionary* nodeDoc =[[[nodeDict objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"TELLIE node mapping document sucessfully loaded!\n");
    [self setTellieNodeMapping:nodeDoc];
    
    [nodeReturnStr release];
}

/*********************************************************/
/*                  Smellie Functions                    */
/*********************************************************/
-(void)setSmellieSafeStates
{
    [[self smellieClient] command:@"set_safe_states"];
}

-(void)setLaserSwitch:(NSNumber*)laserSwitchChannel
{
    NSArray* args = @[laserSwitchChannel];
    [[self smellieClient] command:@"set_laser_switch" withArgs:args];
}

-(void)setFibreSwitch:(NSNumber*)fibreSwitchInputChannel withOutputChannel:(NSNumber*)fibreSwitchOutputChannel
{
    NSArray* args = @[fibreSwitchInputChannel, fibreSwitchOutputChannel];
    [[self smellieClient] command:@"set_fibre_switch" withArgs:args];
}

-(void)setLaserIntensity:(NSNumber*)laserIntensity
{
    NSArray* args = @[laserIntensity];
    [[self smellieClient] command:@"set_laser_intensity" withArgs:args];
}

-(void)setPMTGain:(NSNumber *)gainVoltage
{
    //Currently do nothing
}

-(void)setLaserSoftLockOn
{
    [[self smellieClient] command:@"set_soft_lock_on"];
}

-(void)setLaserSoftLockOff
{
    [[self smellieClient] command:@"set_soft_lock_off"];
}

//this function kills any external software that will block the functions of a smellie run
-(void)killBlockingSoftware
{
    [[self smellieClient] command:@"kill_sepia_and_nimax"];
}

-(void)setSmellieMasterMode:(NSNumber*)triggerFrequency withNumOfPulses:(NSNumber*)numOfPulses
{
    NSArray* args = @[triggerFrequency, numOfPulses];
    [[self smellieClient] command:@"pulse_master_mode" withArgs:args];
}

-(void)setSuperKSafeStates
{
    [[self smellieClient] command:@"set_superk_safe_states"];
}

-(void)setSuperKSoftLockOn
{
    [[self smellieClient] command:@"set_superk_lock_on"];
}

-(void)setSuperKSoftLockOff
{
    [[self smellieClient] command:@"set_superk_lock_off"];
}

-(void) setSuperKWavelegth:(NSNumber*)lowBin withHighEdge:(NSNumber*)highBin
{
    NSArray* args = @[lowBin, highBin];
    [[self smellieClient] command:@"set_superk_wavelength" withArgs:args];
}

-(void)setGainControlWithGainVoltage:(NSNumber*)gainVoltage
{
    NSArray* args = @[gainVoltage];
    [[self smellieClient] command:@"set_gain_control" withArgs:args];
}

-(void)setSmellieLaserHeadMasterMode:(NSNumber*)laserSwitchChan withIntensity:(NSNumber*)intensity withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withNPulses:(NSNumber*)noPulses withGainVoltage:(NSNumber *)gain
{
    /*
    Run the SMELLIE system in Master Mode (NI Unit provides the trigger signal for both the lasers and the detector) using the PicoQuant Laser Heads
    
    :param ls_chan: the laser switch channel
    :param intensity: the laser intensity in per mil
    :param fs_input_channel: the fibre switch input channel
    :param fs_output_channel: the fibre switch output channel
    :param n_pulses: the number of pulses
    */
    NSArray* args = @[laserSwitchChan, intensity, fibreInChan, fibreOutChan, noPulses];
    [[self smellieClient] command:@"laserheads_master_mode" withArgs:args];
}

-(void)setSmellieLaserHeadSlaveMode:(NSNumber*)laserSwitchChan withIntensity:(NSNumber*)intensity withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withNPulses:(NSNumber*)noPulses withGainVoltage:(NSNumber*)gain
{
    /*
    Run the SMELLIE system in Slave Mode (SNO+ MTC/D provides the trigger signal for both the lasers and the detector) using the PicoQuant Laser Heads

    :param ls_chan: the laser switch channel
    :param intensity: the laser intensity in per mil
    :param fs_input_channel: the fibre switch input channel
    :param fs_output_channel: the fibre switch output channel
    :param n_pulses: the number of pulses
    :param time: time until SNODROP exits slave mode
    */
    NSArray* args = @[laserSwitchChan, intensity, fibreInChan, fibreOutChan, noPulses, gain];
    [[self smellieClient] command:@"laserheads_slave_mode" withArgs:args];
}

-(void)setSmellieSuperkMasterMode:(NSNumber*)laserSwitchChan withIntensity:(NSNumber*)intensity withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withNPulses:(NSNumber*)noPulses withGainVoltage:(NSNumber *)gain
{
    /*
     Run the SMELLIE superK laser in Master Mode
     
     :param ls_chan: the laser switch channel
     :param intensity: the laser intensity in per mil
     :param fs_input_channel: the fibre switch input channel
     :param fs_output_channel: the fibre switch output channel
     :param n_pulses: the number of pulses
     */
    NSArray* args = @[laserSwitchChan, intensity, fibreInChan, fibreOutChan, noPulses, gain];
    [[self smellieClient] command:@"superK_master_mode" withArgs:args];
}


-(void)sendCustomSmellieCmd:(NSString*)customCmd withArgs:(NSArray*)argsArray
{
    [[self smellieClient] command:customCmd withArgs:argsArray];
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
    } if ([[smellieSettings objectForKey:@"FS093"] intValue] == 1){
        [fibreArray addObject:@"FS093"];
    } if ([[smellieSettings objectForKey:@"FS193"] intValue] == 1){
        [fibreArray addObject:@"FS193"];
    } if ([[smellieSettings objectForKey:@"FS293"] intValue] == 1){
        [fibreArray addObject:@"FS293"];
    }
    return fibreArray;
}

-(NSArray*)getSmellieRunFrequencyArray:(NSDictionary*)smellieSettings
{
    return nil;
}

-(NSMutableArray*)getSmellieLowEdgeWavelengthArray:(NSDictionary*)smellieSettings
{
    //Read data
    int wavelengthLow = [[smellieSettings objectForKey:@"superK_wavelength_start"] intValue];
    //int bandwidth = [[smellieSettings objectForKey:@"superK_wavelength_bandwidth"] intValue];
    int stepSize = [[smellieSettings objectForKey:@"superK_wavelength_step_length"] intValue];
    float noSteps = [[smellieSettings objectForKey:@"superK_wavelength_no_steps"] floatValue];
    
    NSMutableArray* lowEdges = [NSMutableArray arrayWithCapacity:noSteps];
    if(wavelengthLow == 0 || noSteps == 0){
        [lowEdges addObject:[NSNumber numberWithInteger:wavelengthLow]];
        return lowEdges;
    }
    
    //Create array
    for(int i=0;i<noSteps;i++){
        int edge = wavelengthLow + i*stepSize;
        [lowEdges addObject:[NSNumber numberWithInt:edge]];
    }
    return lowEdges;
}

-(NSMutableArray*)getSmellieRunIntensityArray:(NSDictionary*)smellieSettings forLaser:(NSString *)laser
{
    //Extract bounds
    int minIntensity = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_intensity_minimum",laser]] intValue];
    int increment = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_intensity_increment",laser]] intValue];
    int noSteps = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_intensity_no_steps",laser]] intValue];

    //Check to see if the maximum intensity is the same as the minimum intensity
    NSMutableArray* intensities = [NSMutableArray arrayWithCapacity:noSteps];

    //Create intensities array
    for(int i=0; i < noSteps; i++){
        [intensities addObject:[NSNumber numberWithInt:(minIntensity + increment*i)]];
    }
    
    return intensities;
}

-(NSMutableArray*)getSmellieRunGainArray:(NSDictionary*)smellieSettings forLaser:(NSString *)laser
{
    //Extract bounds
    float minIntensity = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_gain_minimum",laser]] intValue];
    float increment = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_gain_increment",laser]] intValue];
    int noSteps = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_gain_no_steps",laser]] intValue];
    
    //Check to see if the maximum intensity is the same as the minimum intensity
    NSMutableArray* gains = [NSMutableArray arrayWithCapacity:noSteps];
    
    //Create intensities array
    for(int i=0; i < noSteps; i++){
        [gains addObject:[NSNumber numberWithFloat:(minIntensity + increment*i)]];
    }
    
    return gains;
}

-(void)startSmellieRun:(NSDictionary*)smellieSettings
{
    /*
     Form a smellie run using the passed smellie run file, stored in smellieSettings dictionary.
    */
    NSLog(@"%@",smellieSettings);
    NSLog(@"SMELLIE_RUN:Setting up a SMELLIE Run\n");

    //////////////
    // This will likely run in thread so make an auto release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    //   GET TUBii, MTC & RunControl MODELS
    //
    //Get a Tubii object
    NSArray*  tubiiModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    if(![tubiiModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        goto err;
    }
    TUBiiModel* theTubiiModel = [tubiiModels objectAtIndex:0];

    //Get the run controller
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find ORRunModel. Please add it to the experiment and restart the run.\n");
        goto err;
    } 
    ORRunModel* runControl = [runModels objectAtIndex:0];

    // FIND AND LOAD RELEVANT CONFIG
    //
    NSNumber* configVersionNo;
    if([smellieSettings objectForKey:@"config_name"]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Loading config file: %@\n", [smellieSettings objectForKey:@"config_name"]);
        configVersionNo = [self fetchConfigVersionFor:[smellieSettings objectForKey:@"config_name"]];
    } else {
        configVersionNo = [self fetchRecentConfigVersion];
        NSLogColor([NSColor redColor], @"[SMELLIE]: Loading config file: %i\n", [configVersionNo intValue]);
    }
    [self setSmellieConfigVersionNo:configVersionNo];
    [self fetchConfigurationFile:configVersionNo];
    NSLog(@"Config loaded!\n");

    // RUN CONTROL
    //
    //Set up run control
    // As with tellie this should be replaced with a check to see if we are in a smellie run. Issue #205.
    /*
    if(![runControl isRunning]){
        //start the run controller
        NSLogColor([NSColor redColor], @"[SMELLIE]: Starting our own run! \n");
        [runControl performSelectorOnMainThread:@selector(startRun) withObject:nil waitUntilDone:YES];
        
    }else{
        //Stop the current run and start a new run
        NSLogColor([NSColor redColor], @"[SMELLIE]: Restarting run! \n");
        [runControl performSelectorOnMainThread:@selector(restartRun) withObject:nil waitUntilDone:YES];
    }
    */

    // SET MASTER / SLAVE MODE
    //
    NSString *operationMode = [NSString stringWithFormat:@"%@",[smellieSettings objectForKey:@"operation_mode"]];
    if([operationMode isEqualToString:@"Slave Mode"]){
        [self setSmellieSlaveMode:YES];
        NSLog(@"SMELLIE_RUN:Running in SLAVE mode\n");
    }else if([operationMode isEqualToString:@"Master Mode"]){
        [self setSmellieSlaveMode:NO];
        NSLog(@"SMELIE_RUN:Running in MASTER mode\n");
    }else{
        NSLogColor([NSColor redColor], @"[SMELLIE]: Slave / master mode could not be read in config file.\n");
        goto err;
    }
    
    // CREATE AND PUSH SMELLIE RUN DOC
    //
    [self pushInitialSmellieRunDocument];
    
    // GET SMELLIE LASERS AND FIBRES TO LOOP OVER
    // Wavelengths, intensities and gains variables
    // for each fibre are generated within the laser
    // loop.
    //
    NSMutableArray* laserArray = [self getSmellieRunLaserArray:smellieSettings];
    NSMutableArray* fibreArray = [self getSmellieRunFibreArray:smellieSettings];

    // Make a dictionary to hold settings for pushing upto database
    NSMutableDictionary *valuesToFillPerSubRun = [[NSMutableDictionary alloc] initWithCapacity:100];
    
    // ***********************
    // BEGIN LOOPING!
    // laser loop
    //
    BOOL endOfRun = NO;
    for(NSString* laserKey in laserArray){
        if(endOfRun == YES){
            break; //if the end of the run is reached then break the run loop
        }
        
        // Add laser to the subrun file
        [valuesToFillPerSubRun setObject:laserKey forKey:@"laser"];
 
        ////////////////////////////
        // Do some additional array
        // building to define the
        // inner loops for this laser
        
        // Create wavelength, intensity and gain arrays for this laser
        NSMutableArray* intensityArray = [self getSmellieRunIntensityArray:smellieSettings forLaser:laserKey];
        NSMutableArray* gainArray = [self getSmellieRunGainArray:smellieSettings forLaser:laserKey];
        NSMutableArray* lowEdgeWavelengthArray = [NSMutableArray arrayWithObject:[NSNumber numberWithInt:0]]; // Make an array with single entry
        if([laserKey isEqual:@"superK"]){
            lowEdgeWavelengthArray = [self getSmellieLowEdgeWavelengthArray:smellieSettings];
        }

        // ***********
        // Fibre loop
        //
        for(NSString* fibreKey in fibreArray){
            if(endOfRun == YES){
                break;
            }

            // Add fibre to the subRun file
            [valuesToFillPerSubRun setObject:fibreKey forKey:@"fibre"];
            
            // ***************
            // Wavelength loop
            //
            for(NSNumber* wavelength in lowEdgeWavelengthArray){
                if(([[NSThread currentThread] isCancelled])){// || ![runControl isRunning]){
                    endOfRun = YES;
                    break;
                }
                
                // By defauly set the wavelength window to nil in rundoc
                [valuesToFillPerSubRun setObject:@0 forKey:@"wavelength_low_edge"];
                [valuesToFillPerSubRun setObject:@0 forKey:@"wavelength_high_edge"];
                
                // If this is the superK loop, make sure the wavelength window is set
                if([laserKey isEqualToString:@"superK"]){
                    NSNumber* wavelengthLowEdge = [wavelength integerValue];
                    NSNumber* wavelengthHighEdge = [wavelengthLowEdge intValue] + [[smellieSettings objectForKey:@"superK_wavelength_bandwidth"] intValue];
                    
                    // Add superK wavelength values to run doc
                    [valuesToFillPerSubRun setObject:wavelengthLowEdge forKey:@"wavelength_low_edge"];
                    [valuesToFillPerSubRun setObject:wavelengthHighEdge forKey:@"wavelength_high_edge"];
                }
                
                // **************
                // Intensity loop
                //
                for(NSNumber* intensity in intensityArray){
                    if(([[NSThread currentThread] isCancelled])){// || ![runControl isRunning]){
                        endOfRun = YES;
                        break;
                    }
                    
                    // Add intensity value into runDoc
                    [valuesToFillPerSubRun setObject:intensity forKey:@"intensity"];
                    
                    // **************
                    // Gain loop
                    //
                    for(NSNumber* gain in gainArray){
                        if(([[NSThread currentThread] isCancelled])){// || ![runControl isRunning]){
                            endOfRun = YES;
                            break;
                        }
                        
                        ///////////////////////
                        // Inner most loop.
                        // Need to begin a new
                        // subrun and tell hardware
                        // what it should be running
                        //
                        
                        // RUN CONTROL
                        //Prepare new subrun - will produce a subrun boundrary in the zdab.
                        [runControl performSelectorOnMainThread:@selector(prepareForNewSubRun) withObject:nil waitUntilDone:YES];
                        [runControl performSelectorOnMainThread:@selector(startNewSubRun) withObject:nil waitUntilDone:YES];

                        //////////////////////
                        // GET FINAL SMELLIE SETTINGS
                        [valuesToFillPerSubRun setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];
                        
                        NSNumber* laserSwitchChannel = [[self smellieLaserHeadToSepiaMapping] objectForKey:laserKey];
                        NSNumber* fibreInputSwitchChannel = [[self smellieLaserToInputFibreMapping] objectForKey:laserKey];
                        NSNumber* fibreOutputSwitchChannel = [[self smellieFibreSwitchToFibreMapping] objectForKey:fibreKey];
                        NSNumber* numOfPulses = [smellieSettings objectForKey:@"triggers_per_loop"];
                        NSNumber* triggerFrequency = [smellieSettings objectForKey:@"trigger_frequency"];

                      
                        //////////////
                        // Slave mode
                        if([self smellieSlaveMode]){

                            //Set tubii up for sending correct triggers
                            [theTubiiModel setSmellieRate:[triggerFrequency floatValue]];
                            [theTubiiModel setSmelliePulseWidth:100];
                            [theTubiiModel setSmellieNPulses:numOfPulses];

                            //Set SMELLIE settings
                            if([laserKey isEqualTo:@"superK"]){
                                NSLogColor([NSColor redColor], @"[SMELLIE]: SuperK laser cannot be run in slave mode\n");
                            } else {
                                [self setSmellieLaserHeadSlaveMode:laserSwitchChannel withIntensity:intensity withFibreInput:fibreInputSwitchChannel withFibreOutput:fibreOutputSwitchChannel withNPulses:numOfPulses withGainVoltage:gain];
                            }

                            //// **NOTE** ////
                            // May have to include a delay
                            // here to ensure smellie
                            // hardware is properly set
                            // before TUBii sends triggers
                            
                            //Fire trigger pulses!
                            [theTubiiModel fireSmelliePulser];

                        //////////////
                        // Master mode
                        } else {

                            //Set SMELLIE settings
                            if([laserKey isEqualTo:@"superK"]){
                                [self setSmellieSuperkMasterMode:laserSwitchChannel withIntensity:intensity withFibreInput:fibreInputSwitchChannel withFibreOutput:fibreOutputSwitchChannel withNPulses:numOfPulses withGainVoltage:gain];
                            } else {
                                [self setSmellieLaserHeadMasterMode:laserSwitchChannel withIntensity:intensity withFibreInput:fibreInputSwitchChannel withFibreOutput:fibreOutputSwitchChannel withNPulses:numOfPulses withGainVoltage:gain];
                            }
                            
                        }

                        //Push record of sub-run settings to db
                        [self updateSmellieRunDocument:valuesToFillPerSubRun];

                        //Check if run file requests a sleep time between sub_runs
                        if([smellieSettings objectForKey:@"sleep_between_sub_run"]){
                            NSTimeInterval sleepTime = [[smellieSettings objectForKey:@"sleep_between_sub_run"] floatValue];
                            [NSThread sleepForTimeInterval:sleepTime];
                        } else {
                            [NSThread sleepForTimeInterval:1.0f];
                        }
                    }//end of GAIN loop
                }//end of INTENSITY loop
            }//end of WAVELENGTH loop
        }//end of FIBRE loop
    }//end of LASER loop

    //Release dict holding sub-run info
    [valuesToFillPerSubRun release];
    [pool release];
    
    //Post a note. on the main thread to request a call to stopSmellieRun
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSMELLIERunFinished object:self];
    });
    return;

err:
{
    //Resetting the mtcd to settings before the smellie run
    NSLogColor([NSColor redColor], @"[SMELLIE]: Error occurred in run sequence. Stopping smellie run\n");
    [pool release];
    
    //Post a note. on the main thread to request a call to stopSmellieRun
    dispatch_sync(dispatch_get_main_queue(), ^{
	    [[NSNotificationCenter defaultCenter] postNotificationName:ORSMELLIERunFinished object:self];
    });
}
}

-(void)stopSmellieRun
{
    /*
     Some sign off / tidy up stuff to be called at the end of a smellie run. 
    
     The key operation is to set the safestates.
    */

    ///////////
    // This could be run in a thread, so set-up an auto release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [self setSmellieSafeStates];
    [self setSuperKSafeStates];
    
    //Get a Tubii object
    NSArray*  tubiiModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    if(![tubiiModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        goto err;
    }
    TUBiiModel* theTubiiModel = [tubiiModels objectAtIndex:0];
    [theTubiiModel stopSmelliePulser];
    
    
    // How we want to handle run transtions is currently unclear. It's best not affect the run without the operators
    // express understanding of what that is doing to the detector state. For now I'll comment out this line. That
    // leaves the operator to handle run control themselves .
    /*
     if([runControl isRunning]){
     [runControl performSelectorOnMainThread:@selector(restartRun) withObject:nil waitUntilDone:YES];
     }
     */
    NSLog(@"SMELLIE_RUN:Stopping SMELLIE Run\n");
    [pool release];
    return;
    
err:
    [pool release];
    NSLog(@"SMELLIE_RUN:Error stopping run\n");
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
    ORRunModel* runControl = [runModels objectAtIndex:0];

    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noSNOPModel"
                          reason:@"*** Please add a SNOPModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"SMELLIE_RUN"];
    NSMutableArray* subRunArray = [NSMutableArray arrayWithCapacity:15];

    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@"%lu",[runControl runNumber]] forKey:@"index"];
    [runDocDict setObject:[aSnotModel smellieRunNameLabel] forKey:@"run_description_used"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"timestamp"];
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
     Update [self tellieRunDoc] with subrun information.
     
     Arguments:
     NSDictionary* subRunDoc:  Subrun information to be added to the current [self tellieRunDoc].
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

    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSException* e = [NSException
                          exceptionWithName:@"noRunModel"
                          reason:@"*** Please add a ORRunModel to the experiment"
                          userInfo:nil];
        [e raise];
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];
    
    NSMutableDictionary* runDocDict = [[self smellieRunDoc] mutableCopy];
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
    ORRunModel* runControl = [runModels objectAtIndex:0];

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
        [runDocDict setObject:[self smellieSubRunInfo] forKey:@"sub_run_info"];
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
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/smellie/_design/smellieMainQuery/_view/fetchMostRecentConfigVersion?descending=True&limit=1",[aSnotModel orcaDBUserName],[aSnotModel orcaDBPassword],[aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSNumber *currentVersionNumber;
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error =  nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if(error){
        NSLog(@"Error querying couchDB, please check the connection is correct %@",error);
    }

    @try{
        //format the json response
        NSString *stringValueOfCurrentVersion = [NSString stringWithFormat:@"%@",[[[json valueForKey:@"rows"] valueForKey:@"value"]objectAtIndex:0]];
        currentVersionNumber = [NSNumber numberWithInt:[stringValueOfCurrentVersion intValue]];
    }
    @catch (NSException *e) {
        NSLog(@"Error in fetching the SMELLIE CONFIGURATION FILE: %@ . Please fix this before changing the configuration file",e);
        return @-1;
    }
    NSLog(@"SMELLIE config version sucessfully loaded!\n");
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

    NSString *urlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/smellie/_design/smellieMainQuery/_view/pullEllieConfigHeaders",[aSnotModel orcaDBUserName],[aSnotModel orcaDBPassword],[aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *ret = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
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
                NSString* stringValueOfCurrentVersion = [NSString stringWithFormat:@"%@",[[[entry valueForKey:@"value"] valueForKey:@"configuration_info"] valueForKey:@"configuration_version"]];
                return [NSNumber numberWithInt:[stringValueOfCurrentVersion intValue]];
            }
        }
    }
    NSLogColor([NSColor redColor], @"[SMELLIE]: WARNING No config file found for %@\n", name);
    return [self fetchRecentConfigVersion];
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

    NSString *urlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/smellie/_design/smellieMainQuery/_view/pullEllieConfigHeaders?key=[%i]&limit=1",[aSnotModel orcaDBUserName],[aSnotModel orcaDBPassword],[aSnotModel orcaDBIPAddress],[aSnotModel orcaDBPort],[currentVersion intValue]];

    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSError *error =  nil;
    NSMutableDictionary *currentConfig = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if(error){
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
                [laserHeadToSepiaMapping setObject:[NSNumber numberWithInt:laserHeadIndex] forKey:laserHeadConnected];
            }
        }
    }
    //NSLog(@"setSmellieLaserHeadToSepiaMapping: %@\n", laserHeadToSepiaMapping);
    [self setSmellieLaserHeadToSepiaMapping:laserHeadToSepiaMapping];
    [laserHeadToSepiaMapping release];

    //Set laser head to gain control mapping
    NSMutableDictionary *laserHeadToGainControlMapping = [[NSMutableDictionary alloc] initWithCapacity:10];
    for(int laserHeadIndex =0; laserHeadIndex < 6; laserHeadIndex++){
        for (id specificConfigValue in configForSmellie){
            if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput%i",laserHeadIndex]]){
                NSString *laserHeadConnected = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"laserHeadConnected"]];
                NSNumber *laserGainControl = [NSNumber numberWithFloat:[[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"gainControlFactor"] floatValue]];
                [laserHeadToGainControlMapping setObject:laserGainControl forKey:laserHeadConnected];
            }
        }
    }
    //NSLog(@"setSmellieLaserHeadToGainMapping: %@\n", laserHeadToGainControlMapping);
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
            NSNumber* parsedFibreReference = [NSNumber numberWithInt:[[fibreSwitchInputConnected stringByReplacingOccurrencesOfString:@"Channel" withString:@""] intValue]];
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
                [fibreSwitchOutputToFibre setObject:[NSNumber numberWithInt:outputChannelIndex] forKey:fibreReference];
            }
        }
    }
    [self setSmellieFibreSwitchToFibreMapping:fibreSwitchOutputToFibre];
    [fibreSwitchOutputToFibre release];
    
    NSLog(@"SMELLIE config file (version %i) sucessfully loaded!\n", [currentVersion intValue]);
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
                [self setTellieRunDoc:runDoc];
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
