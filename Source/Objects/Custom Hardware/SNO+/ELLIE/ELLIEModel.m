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
#import "ORRunModel.h"
#import "SNOPModel.h"
#import "ORMTCModel.h"
#import "TUBiiModel.h"
#import "TUBiiController.h"
#import "ORRunController.h"
#import "ORMTC_Constants.h"
#import "SNOP_Run_Constants.h"
#import "RunTypeWordBits.hh"

//tags to define that an ELLIE run file has been updated
#define kSmellieRunDocumentAdded   @"kSmellieRunDocumentAdded"
#define kSmellieRunDocumentUpdated   @"kSmellieRunDocumentUpdated"
#define kSmellieConigVersionRetrieved @"kSmellieConfigVersionRetrieved"
#define kSmellieConigRetrieved @"kSmellieConfigRetrieved"

#define kTellieRunDocumentAdded   @"kTellieRunDocumentAdded"
#define kTellieRunDocumentUpdated   @"kTellieRunDocumentUpdated"
#define kTellieParsRetrieved @"kTellieParsRetrieved"
#define kTellieMapRetrieved @"kTellieMapRetrieved"
#define kTellieNodeRetrieved @"kTellieNodeRetrieved"
#define kTellieRunPlansRetrieved @"kTellieRunPlansRetrieved"

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
@synthesize tellieRunNames = _tellieRunNames;
@synthesize tellieRunDoc = _tellieRunDoc;
@synthesize tellieSubRunSettings = _tellieSubRunSettings;

@synthesize smellieRunSettings = _smellieRunSettings;
@synthesize smellieRunHeaderDocList = _smellieRunHeaderDocList;
@synthesize smellieSubRunInfo = _smellieSubRunInfo;
@synthesize smellieLaserHeadToSepiaMapping = _smellieLaserHeadToSepiaMapping;
@synthesize smellieLaserToInputFibreMapping = _smellieLaserToInputFibreMapping;
@synthesize smellieFibreSwitchToFibreMapping = _smellieFibreSwitchToFibreMapping;
@synthesize smellieSlaveMode = _smellieSlaveMode;
@synthesize smellieConfigVersionNo = _smellieConfigVersionNo;
@synthesize smellieRunDoc = _smellieRunDoc;
@synthesize smellieDBReadInProgress = _smellieDBReadInProgress;

@synthesize tellieHost = _tellieHost;
@synthesize smellieHost = _smellieHost;
@synthesize interlockHost = _interlockHost;
@synthesize telliePort = _telliePort;
@synthesize smelliePort = _smelliePort;
@synthesize interlockPort = _interlockPort;

@synthesize tellieClient = _tellieClient;
@synthesize smellieClient = _smellieClient;
@synthesize interlockClient = _interlockClient;

@synthesize ellieFireFlag = _ellieFireFlag;
@synthesize tellieMultiFlag = _tellieMultiFlag;
@synthesize exampleTask = _exampleTask;
@synthesize pulseByPulseDelay = _pulseByPulseDelay;
@synthesize currentOrcaSettingsForSmellie = _currentOrcaSettingsForSmellie;

@synthesize tellieThread = _tellieThread;
@synthesize smellieThread = _smellieThread;

/*********************************************************/
/*                  Class control methods                */
/*********************************************************/
- (id) init
{
    self = [super init];
    return self;
}

-(id) initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self){
        [self registerNotificationObservers];
        
        //Settings
        [self setTellieHost:[decoder decodeObjectForKey:@"tellieHost"]];
        [self setTelliePort:[decoder decodeObjectForKey:@"telliePort"]];

        [self setSmellieHost:[decoder decodeObjectForKey:@"smellieHost"]];
        [self setSmelliePort:[decoder decodeObjectForKey:@"smelliePort"]];

        [self setInterlockHost:[decoder decodeObjectForKey:@"interlockHost"]];
        [self setInterlockPort:[decoder decodeObjectForKey:@"interlockPort"]];

        /* Check if we actually decoded the various server hostnames
         * and ports. decodeObjectForKey() will return NULL if the
         * key doesn't exist, and decodeIntForKey() will return 0. */
        if ([self tellieHost] == NULL) [self setTellieHost:@""];
        if ([self smellieHost] == NULL) [self setSmellieHost:@""];
        if ([self interlockHost] == NULL) [self setInterlockHost:@""];

        if ([self telliePort] == NULL) [self setTelliePort:@"5030"];
        if ([self smelliePort] == NULL) [self setSmelliePort:@"5020"];
        if ([self interlockPort] == NULL) [self setInterlockPort:@"5021"];

        XmlrpcClient* tellieCli = [[XmlrpcClient alloc] initWithHostName:[self tellieHost] withPort:[self telliePort]];
        XmlrpcClient* smellieCli = [[XmlrpcClient alloc] initWithHostName:[self smellieHost] withPort:[self smelliePort]];
        XmlrpcClient* interlockCli = [[XmlrpcClient alloc] initWithHostName:[self interlockHost] withPort:[self interlockPort]];

        [self setTellieClient:tellieCli];
        [self setSmellieClient:smellieCli];
        [self setInterlockClient:interlockCli];
        [[self tellieClient] setTimeout:100];
        [[self smellieClient] setTimeout:360];
        [[self interlockClient] setTimeout:10];

        [tellieCli release];
        [smellieCli release];
        [interlockCli release];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];

    //Settings
    [encoder encodeObject:[self tellieHost] forKey:@"tellieHost"];
    [encoder encodeObject:[self telliePort] forKey:@"telliePort"];

    [encoder encodeObject:[self smellieHost] forKey:@"smellieHost"];
    [encoder encodeObject:[self smelliePort] forKey:@"smelliePort"];

    [encoder encodeObject:[self interlockHost] forKey:@"interlockHost"];
    [encoder encodeObject:[self interlockPort] forKey:@"interlockPort"];
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
    
    // Server Clients
    [_tellieClient release];
    [_smellieClient release];
    
    // tellie settings
    [_tellieSubRunSettings release];
    [_tellieFireParameters release];
    [_tellieFibreMapping release];
    
    // smellie config mappings
    [_smellieLaserHeadToSepiaMapping release];
    [_smellieLaserToInputFibreMapping release];
    [_smellieFibreSwitchToFibreMapping release];
    [_smellieConfigVersionNo release];
    
    [_tellieRunNames release];
    [_interlockPort release];
    [_tellieHost release];
    [_tellieThread release];
    [_telliePort release];
    [_interlockClient release];
    [_smellieHost release];
    [_smellieThread release];
    [_tellieNodeMapping release];
    [_smelliePort release];
    [_interlockHost release];
    
    [super dealloc];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(checkAndTidyELLIEThreads:)
                         name : ORRunAboutToStopNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(checkAndTidyELLIEThreads:)
                         name : OROrcaAboutToQuitNotice
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(killKeepAlive:)
                         name : @"SMELLIEEmergencyStop"
                        object: nil];
}

-(void)checkAndTidyELLIEThreads:(NSNotification *)aNote
{
    /*
     Check to see if an ELLIE fire sequence has been running. If so, the stop*ellieRun methods of
     the ellieModel will post the run wait notification and launch a thread that waits for the smellieThread
     to stop executing before tidying up and, finally, releasing the run wait.
     */
    if([[self tellieThread] isExecuting]){
        [self stopTellieRun];
    }
    if([[self smellieThread] isExecuting]){
        [self stopSmellieRun];
    }
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
        // Check the thread hasn't been cancelled
        if([[NSThread currentThread] isCancelled]){
            return blankResponse;
        }
        [NSThread sleepForTimeInterval:1.0];
        pollResponse = [[self tellieClient] command:@"read_pin_sequence"];
        count = count + 1;
    }
    
    // Some checks on the response
    if ([pollResponse isKindOfClass:[NSString class]]){
        NSLogColor([NSColor redColor], @"[TELLIE]: PIN diode poll returned %@. Likely that the sequence didn't finish before timeout.\n", pollResponse);
        return blankResponse;
    } else if ([pollResponse count] != 3) {
        NSLogColor([NSColor redColor], @"[TELLIE]: PIN diode poll returned array of len %i - expected 3\n", [pollResponse count]);
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
        NSLogColor([NSColor redColor], @"[TELLIE]: TELLIE_FIRE_PARMETERS doc has not been loaded from telliedb - you need to call loadTellieStaticsFromDB");
        return 0;
    }
    
    // Run photon intensity check
    bool safety_check = [self photonIntensityCheck:photons atFrequency:frequency];
    if(safety_check == NO){
        NSLogColor([NSColor redColor], @"[TELLIE]: The requested number of photons (%lu), is not detector safe at %lu Hz. This setting will not be run.\n", photons, frequency);
        return [NSNumber numberWithInt:-1];
    }
    
    // Frequency check
    if(frequency != 1000){
        NSLogColor([NSColor orangeColor], @"[TELLIE]: CAUTION calibrations are only valid at 1kHz. Photon output may vary from requested setting\n");
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
        NSLog(@"[TELLIE]: Calibration curve for channel %lu does not go as low as %lu photons\n", channel, photons);
        NSLog(@"[TELLIE]: Using a linear interpolation of -5ph/IPW from min_photons = %.1f to estimate requested %d photon settings\n",min_photons,photons);
        float intercept = min_photons - (-5.*min_x);
        float floatPulseWidth = (photons - intercept)/(-5.);
        NSNumber* pulseWidth = [NSNumber numberWithInteger:floatPulseWidth];
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
        NSLog(@"[TELLIE]: Requested IPW is larger than any value in the calibration curve.\n");
        NSLog(@"[TELLIE]: Using a linear interpolation of 5ph/IPW from min_photons = %.1f (IPW = %d) to estimate photon output at requested setting\n",min_photons, max_ipw);
        float intercept = min_photons - (-5.*max_ipw);
        float photonsFloat = (-5.*ipw) + intercept;
        if(photonsFloat < 0){
            photonsFloat = 0.;
        }
        NSNumber* photons = [NSNumber numberWithFloat:photonsFloat];
        return photons;
    }
    
    /////////////
    // If requested photon output is within range, find xy points above and below threshold.
    // Appropriate setting will be estiamated with a linear interpolation between these points.
    int index = 0;
    for(NSNumber* val in IPW_values){
        index = index + 1;
        if([val intValue] > ipw){
            break;
        }
    }
    index = index - 1;
    
    float x1 = [[IPW_values objectAtIndex:(index-1)] floatValue];
    float x2 = [[IPW_values objectAtIndex:(index)] floatValue];
    float y1 = [[photon_values objectAtIndex:(index-1)] floatValue];
    float y2 = [[photon_values objectAtIndex:(index)] floatValue];
    
    // Calculate gradient and offset for interpolation.
    float dydx = (y1 - y2)/(x1 - x2);
    float intercept = y1 - dydx*x1;
    float photonsFloat = (dydx*ipw) + intercept;
    NSNumber* photons = [NSNumber numberWithInteger:photonsFloat];
    
    return photons;
}

-(BOOL)photonIntensityCheck:(NSUInteger)photons atFrequency:(NSUInteger)frequency
{
    /*
     A detector safety check. At high frequencies the maximum tellie output must be small
     to avoid pushing too much current through individual channels / trigger sums. Use a
     loglog curve to define what counts as detector safe.
     */
    
    /*
     Currently the predicted nPhotons does not correlate with reality so this check is defunct.
     it might be worth adding it back eventually once our understanding has improved. For now
     make do with a simple rate check (below).
    float safe_gradient = -1;
    float safe_intercept = 1.05e6;
    float max_photons = safe_intercept*pow(frequency, safe_gradient);
    if(photons > max_photons){
        return NO;
    } else {
        return YES;
    }
     */
    if(frequency > 1.01e3)
        return NO;
    return YES;
}

-(NSString*)calcTellieFibreForNode:(NSUInteger)node{
    /*
     Use node-to-fibre map loaded from the telliedb to find the priority fibre on a node.
     */
    if(![[self tellieNodeMapping] objectForKey:[NSString stringWithFormat:@"panel_%d",node]]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Node map does not include a reference to node: %d",node);
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
        NSLogColor([NSColor redColor], @"[TELLIE]: fibre map has not been loaded from couchdb - you need to call loadTellieStaticsFromDB\n");
        return [NSNumber numberWithInt:-1];
    }
    if(![[[self tellieFibreMapping] objectForKey:@"fibres"] containsObject:fibre]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Patch map does not include a reference to fibre: %@\n",fibre);
        return [NSNumber numberWithInt:-2];
    }
    NSUInteger fibreIndex = [[[self tellieFibreMapping] objectForKey:@"fibres"] indexOfObject:fibre];
    NSUInteger channelInt = [[[[self tellieFibreMapping] objectForKey:@"channels"] objectAtIndex:fibreIndex] integerValue];
    NSNumber* channel = [NSNumber numberWithInt:channelInt];
    return channel;
}

-(NSString*) calcTellieFibreForChannel:(NSUInteger)channel
{
    /*
     Use patch pannel map loaded from the telliedb to map a given fibre to the correct tellie channel.
     */
    if([self tellieFibreMapping] == nil){
        NSLogColor([NSColor redColor], @"[TELLIE]: fibre map has not been loaded from couchdb - you need to call loadTellieStaticsFromDB\n");
        return nil;
    }

    NSUInteger channelIndex;
    @try{
        channelIndex = [[[self tellieFibreMapping] objectForKey:@"channels"] indexOfObject:[NSString stringWithFormat:@"%d",channel]];
    }@catch(NSException* e) {
        channelIndex = [[[self tellieFibreMapping] objectForKey:@"channels"] indexOfObject:channel];
    }
    NSString* fibre = [[[self tellieFibreMapping] objectForKey:@"fibres"] objectAtIndex:channelIndex];
    return fibre;
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

-(void)startTellieRunThread:(NSDictionary*)fireCommands
{
    /*
     Launch a thread to host the tellie run functionality.
    */

    //////////////////////
    // Start tellie thread
    [self setTellieThread:[[NSThread alloc] initWithTarget:self selector:@selector(startTellieRun:) object:fireCommands]];
    [[self tellieThread] start];
}

-(void)startTellieMultiRunThread:(NSArray*)fireCommandArray
{
    /*
     Launch a thread to host the tellie multi run functionality.
     */

    //////////////////////
    // Start tellie thread
    [self setTellieThread:[[NSThread alloc] initWithTarget:self selector:@selector(startTellieMultiRun:) object:fireCommandArray]];
    [[self tellieThread] start];
}

-(void) startTellieMultiRun:(NSArray*)fireCommandArray
{
    /*
     Fire light down one or more fibres using fireCommands given in the passed array.
     Calls startTellieRun on each element in the array.

     Arguments:
     NSMutableDictionary fireCommandArray :     An a array of dictionaries containing
                                                hardware settings to be passed to the
                                                tellie hardware.
     */
    //////////////////////////////
    // Set a flag so startTellieRun
    // knows not to finish the run
    // on completion.
    [self setTellieMultiFlag:YES];

    //////////////////////////////
    // Loop over all objects in
    // passed array
    for(NSDictionary* fireCommands in fireCommandArray){
        if([[NSThread currentThread] isCancelled]){
            goto err;
        }
        [self startTellieRun:fireCommands];
    }

err:
{
    ////////////////////////////
    // Reset flag and tidy
    [self setTellieMultiFlag:NO];

    ////////////
    // If thread errored we need to post a note to
    // call the formal stop proceedure. If the thread
    // was canelled we must already be in a 'stop'
    // button push, so don't need to post.
    if(![[NSThread currentThread] isCancelled]){
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ORTELLIERunFinished object:self];
        });
    }
    [[NSThread currentThread] cancel];
}
}

-(void) startTellieRun:(NSDictionary*)fireCommands
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
        goto err;
    }
    TUBiiModel* theTubiiModel = [tubiiModels objectAtIndex:0];

    ///////////////
    //Add run control object
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Couldn't find ORRunModel please add one to the experiment\n");
        goto err;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];
    
    ///////////////
    //Add SNOPModel object
    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE]: Couldn't find SNOPModel\n");
        goto err;
    }
    SNOPModel* snopModel = [snopModels objectAtIndex:0];

    ///////////////////////
    // Check TELLIE run type is masked in
    if(!([snopModel lastRunTypeWord] & kTELLIERun)){
        NSLogColor([NSColor redColor], @"[TELLIE]: TELLIE bit is not masked into the run type word.\n");
        NSLogColor([NSColor redColor], @"[TELLIE]: Please load the TELLIE standard run type.\n");
        goto err;
    }

    ///////////////////////
    // Check trigger is being sent to asyncronus port of the MTC/D (EXT_A)
    NSUInteger asyncTrigMask;
    @try{
        asyncTrigMask = [theTubiiModel asyncTrigMask];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"[TELLIE]: Error requesting asyncTrigMask from Tubii.\n");
        goto err;
    }
    if(!(asyncTrigMask & 0x400000)){
        NSLogColor([NSColor redColor], @"[TELLIE]: Triggers as not being sent to asynchronous MTC/D port\n");
        NSLogColor([NSColor redColor], @"[TELLIE]: Please amend via the TUBii GUI (triggers tab)\n");
        goto err;
    }

    //////////////
    // Get run mode boolean
    BOOL isSlave = YES;
    if([[fireCommands objectForKey:@"run_mode"] isEqualToString:@"Master"]){
        isSlave = NO;
    }
    
    //////////////
    // TUBii has two possible slave mode configurations.
    // 0 [@NO]:  Trigger path = TUBii->TELLIE->TUBii->MTC/D
    // 1 [@YES]: Trigger path = TUBii->TELLIE
    //                          TUBii->MTC/D
    //
    // In the first case a single signal propagates in sequence through the entire chain of hardware. This
    // has a disadvantage that significant attenuation can be picked up on the long paths between TUBii
    // and tellie (approx 20m each).
    // In the second case TUBii first sends a trigger to TELLIE, then independently, after some delay, sends
    // a trigger onto the MTC/D in anticipation that the TELLIE trigger would have been properly received.
    // This has the advantage that the trigger paths are much better controlled.
    //
    // The second case was added as the trigger efficiency of the first arrangement proved to be extremely
    // poor (<50%). Hence we want to force this method to be used by default.
    if(isSlave){
        BOOL mode = YES;
        if([fireCommands objectForKey:@"TUBii_slave_setting"]){
            mode = [[fireCommands objectForKey:@"TUBii_slave_setting"] boolValue];
        }
        @try{
            [theTubiiModel setTellieMode:mode];
        } @catch(NSException* e){
            NSLogColor([NSColor redColor], @"[TELLIE]: Problem setting correct slave mode behaviour at TUBii, reason: %@\n", [e reason]);
            goto err;
        }
    }
    
    /////////////
    // Final settings check
    NSNumber* photonOutput = [self calcPhotonsForIPW:[[fireCommands objectForKey:@"pulse_width"] integerValue] forChannel:[[fireCommands objectForKey:@"channel"] integerValue] inSlave:isSlave];
    float rate = 1000.*(1./[[fireCommands objectForKey:@"pulse_separation"] floatValue]);
    NSLog(@"---------------------------Single Fibre Settings Summary-------------------------\n");
    NSLog(@"[TELLIE]: Fibre: %@\n", [fireCommands objectForKey:@"fibre"]);
    NSLog(@"[TELLIE]: Channel: %i\n", [[fireCommands objectForKey:@"channel"] intValue]);
    if (isSlave){
        NSLog(@"[TELLIE]: Mode: slave\n");
    } else {
        NSLog(@"[TELLIE]: Mode: master\n");
    }
    NSLog(@"[TELLIE]: IPW: %d\n", [[fireCommands objectForKey:@"pulse_width"] integerValue]);
    NSLog(@"[TELLIE]: Trigger delay: %1.1f ns\n", [[fireCommands objectForKey:@"trigger_delay"] floatValue]);
    NSLog(@"[TELLIE]: Fibre delay: %1.2f ns\n", [[fireCommands objectForKey:@"fibre_delay"] floatValue]);
    NSLog(@"[TELLIE]: No. triggers %d\n", [[fireCommands objectForKey:@"number_of_shots"] integerValue]);
    NSLog(@"[TELLIE]: Rate %1.1f Hz\n", rate);
    NSLog(@"[TELLIE]: Expected photon output: %i photons / pulse\n", [photonOutput integerValue]);
    NSLog(@"------------\n");
    NSLog(@"[TELLIE]: Estimated excecution time %1.1f mins\n", (([[fireCommands objectForKey:@"number_of_shots"] integerValue] / rate) + 10) / 60.);
    NSLog(@"---------------------------------------------------------------------------------------------\n");

    BOOL safety_check = [self photonIntensityCheck:[photonOutput integerValue] atFrequency:rate];
    if(safety_check == NO){
        NSLogColor([NSColor redColor], @"[TELLIE]: The requested number of photons (%lu), is not detector safe at %f Hz. This setting will not be run.\n", [photonOutput integerValue], rate);
        goto err;
    }
    
    /////////////
    // TELLIE pin readout is an average measurement of the passed "number_of_shots".
    // If a large number of shots are requested it is useful to split the data into smaller chunks,
    // this way we get multiple pin readings.
    NSNumber* loops = [NSNumber numberWithInteger:1];
    int totalShots = [[fireCommands objectForKey:@"number_of_shots"] integerValue];
    float fRemainder = fmod(totalShots, 5e3);
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
    if([runControl isRunning]){
        @try{
            [self pushInitialTellieRunDocument];
        }@catch(NSException* e){
            NSLogColor([NSColor redColor],@"[TELLIE]: Problem pushing initial tellie run description document: %@\n", [e reason]);
            goto err;
        }
    }
    
    ///////////////
    // Fire loop! Pass variables to the tellie server.
    for(int i = 0; i<[loops integerValue]; i++){
        if(![self ellieFireFlag] || [[NSThread currentThread] isCancelled]){
            //errorString = @"ELLIE fire flag set to @NO";
            goto err;
        }

        /////////////////
        // Calculate how many shots to fire in this loop
        NSNumber* noShots = [NSNumber numberWithInt:5e3];
        if(i == ([loops integerValue]-1) && fRemainder > 0){
            noShots = [NSNumber numberWithInt:fRemainder];
        }
        
        //////////////////////
        // Set loop independent tellie channel settings
        if(i == 0){

            ////////
            // Send stop command to ensure buffer is clear
            @try{
                [[self tellieClient] command:@"stop"];
            } @catch(NSException* e){
                // This should only ever be called from the main thread so can raise
                NSLogColor([NSColor redColor], @"[TELLIE]: Problem with tellie server interpreting stop command!\n");
            }
            
            ////////
            // Init channel using fireCommands
            NSArray* fireArgs = @[[[fireCommands objectForKey:@"channel"] stringValue],
                                  [noShots stringValue],
                                  [[fireCommands objectForKey:@"pulse_separation"] stringValue],
                                  [NSNumber numberWithInt:0], // Trigger delay now handled by TUBii
                                  [[fireCommands objectForKey:@"pulse_width"] stringValue],
                                  [[fireCommands objectForKey:@"pulse_height"] stringValue],
                                  [[fireCommands objectForKey:@"fibre_delay"] stringValue],
                                  ];
            
            NSLog(@"[TELLIE]: Init-ing tellie with settings\n");
            @try{
                [[self tellieClient] command:@"init_channel" withArgs:fireArgs];
            } @catch(NSException *e){
                errorString = [NSString stringWithFormat:@"[TELLIE]: Problem init-ing channel on server: %@\n", [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }
            
            @try{
                [theTubiiModel setTellieDelay:[[fireCommands objectForKey:@"trigger_delay"] intValue]];
            } @catch(NSException* e) {
                errorString = [NSString stringWithFormat:@"[TELLIE]: Problem setting trigger delay at TUBii: %@\n", [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }
            
        }

        //////////////////
        // Start a new subrun
        [runControl performSelectorOnMainThread:@selector(prepareForNewSubRun) withObject:nil waitUntilDone:YES];
        [runControl performSelectorOnMainThread:@selector(startNewSubRun) withObject:nil waitUntilDone:YES];
        
        ////////////////////
        // Init can take a while. Make sure no-one hit
        // a stop button
        if([[NSThread currentThread] isCancelled]){
            goto err;
        }
        
        /////////////////////
        // Set loop dependent tellie channel settings
        @try{
            [[self tellieClient] command:@"set_pulse_number" withArgs:@[noShots]];
        } @catch(NSException* e) {
            errorString = @"[TELLIE]: Problem setting pulse number on server.\n";
            NSLogColor([NSColor redColor], errorString);
            goto err;
        }
        
        ///////////////
        // Make a temporary directoy to add sub_run fields being run in this loop
        NSMutableDictionary* valuesToFillPerSubRun = [NSMutableDictionary dictionaryWithCapacity:100];
        [valuesToFillPerSubRun setDictionary:fireCommands];
        [valuesToFillPerSubRun setObject:noShots forKey:@"number_of_shots"];
        [valuesToFillPerSubRun setObject:photonOutput forKey:@"photons"];
        
        NSLog(@"[TELLIE]: Firing fibre %@: %d pulses, %1.0f Hz\n", [fireCommands objectForKey:@"fibre"], [noShots integerValue], rate);
        
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
                errorString = [NSString stringWithFormat:@"[TELLIE]: Problem setting pulse number on server: %@\n", [e reason]];
                NSLogColor([NSColor redColor], errorString);
                goto err;
            }
            ////////////
            // Set the tubii model aand ask it to fire
            @try{
                [theTubiiModel fireTelliePulser_rate:rate pulseWidth:100 NPulses:[noShots intValue]];
            } @catch(NSException* e){
                errorString = [NSString stringWithFormat:@"[TELLIE]: Problem setting TUBii parameters: %@\n", [e reason]];
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
                errorString = [NSString stringWithFormat: @"[TELLIE]: Problem requesting tellie master to fire: %@\n", [e reason]];
                NSLogColor([NSColor redColor],errorString);
                goto err;
            }
        }

        //////////////////
        // Before we poll, check thread is still alive.
        // polling can take a while so worth doing here first.
        if([[NSThread currentThread] isCancelled]){
            goto err;
        }
        //////////////////
        // Poll tellie for a pin reading. Give the sequence a 3s grace period to finish
        // long for some reason
        float pollTimeOut = (1./rate)*[noShots floatValue] + 3.;
        NSArray* pinReading = nil;
        @try{
            pinReading = [self pollTellieFibre:pollTimeOut];
        } @catch(NSException* e){
            errorString = [NSString stringWithFormat:@"[TELLIE] Problem polling for pin: %@\n", [e reason]];
            NSLogColor([NSColor redColor], errorString);
            goto err;
        }
        NSLog(@"[TELLIE]: Pin response received %i +/- %1.1f\n", [[pinReading objectAtIndex:0] integerValue], [[pinReading objectAtIndex:1] floatValue]);
        @try {
            [valuesToFillPerSubRun setObject:[pinReading objectAtIndex:0] forKey:@"pin_value"];
            [valuesToFillPerSubRun setObject:[pinReading objectAtIndex:1] forKey:@"pin_rms"];
        } @catch (NSException *e) {
            errorString = [NSString stringWithFormat:@"[TELLIE]: Unable to add pin readout to sub_run file due to error: %@\n",[e reason]];
            NSLogColor([NSColor redColor], errorString);
            goto err;
        }
        
        ////////////
        // Update run document
        if([runControl isRunning]){
            @try{
                [self updateTellieRunDocument:valuesToFillPerSubRun];
            } @catch(NSException* e){
                NSLogColor([NSColor redColor],@"[TELLIE]: Problem updating tellie run description document: %@\n", [e reason]);
                goto err;
            }
        }
    }

    ////////////
    // Release pooled memory
    [pool release];
    [self setEllieFireFlag:NO];

    NSLog(@"[TELLIE]: TELLIE fire sequence completed\n");
    if(![self tellieMultiFlag]){
        ////////////
        // Finish and tidy up
        [[NSThread currentThread] cancel];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ORTELLIERunFinished object:self];
        });

    }
    return;

err:
    {
        [pool release];
        [self setEllieFireFlag:NO];
        [self setTellieMultiFlag:NO];
        
        //Resetting the mtcd to settings before the smellie run
        NSLog(@"[TELLIE]: Killing requested flash sequence\n");
        
        //Make a dictionary to push into sub-run array to indicate error.
        //NSMutableDictionary* errorDict = [NSMutableDictionary dictionaryWithCapacity:10];
        //[errorDict setObject:errorString forKey:@"tellie_error"];
        //[self updateTellieRunDocument:errorDict];

        ////////////
        // If thread errored we need to post a note to
        // call the formal stop proceedure. If the thread
        // was canelled we must already be in a 'stop'
        // button push, so don't need to post.
        if(![[NSThread currentThread] isCancelled]){
            dispatch_sync(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:ORTELLIERunFinished object:self];
            });
        }
        [[NSThread currentThread] cancel];

    }
}

-(void)stopTellieRun
{
    /*
     Before we perform any tidy-up actions, we want to make sure the run thread has stopped
     executing. If the run has not been ended using the tellie specific 'stop fibre' button,
     but instead the user has simply hit the main run stop button on the SNOPController, we
     need to make sure TELLIE has properly cleaned up before we roll into a new run.
     Fortunately there is a handy wait notification that gets picked up by the run control.

     Here we post the run wait notification and launch a thread that waits for the tellieThread
     to stop executing before tidying up and, finally, releasing the run wait.
     */

    [[self tellieThread] cancel];

    // Post a notification telling the run control to wait until the thread finishes
    NSDictionary* userInfo  = [NSDictionary dictionaryWithObjectsAndKeys:@"waiting for tellie run to finish", @"Reason", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object:self userInfo:userInfo];

    // Detatch thread to monitor smellie run thread
    [NSThread detachNewThreadSelector:@selector(waitForTellieRunToFinish) toTarget:self withObject:nil];
}

-(void)waitForTellieRunToFinish
{
    @autoreleasepool {
        while ([[self tellieThread] isExecuting]) {
            [NSThread sleepForTimeInterval:0.1];
        }
        [self tellieTidyUp];
    }
}

-(void) tellieTidyUp
{
    /*
     Stop TELLIE firing, tidy up and ensure system is in a well defined state.
     */

    //////////////////////
    // Set fire flag to no. If a run sequence is currently underway, this will stop
    [self setEllieFireFlag:NO];
    [self setTellieMultiFlag:NO];

    /////////////
    // This may run in a thread so add release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    //////////////////////
    // Send stop command to tellie hardware
    @try{
        NSString* responseFromTellie = [[self tellieClient] command:@"stop"];
        NSLog(@"[TELLIE]: Sent stop command to tellie, received: %@\n",responseFromTellie);
    } @catch(NSException* e){
        // This should only ever be called from the main thread so can raise
        NSLogColor([NSColor redColor], @"[TELLIE]: Problem with tellie server interpreting stop command!\n");
        [pool release];
        return;
    }

    ///////////////////
    // Incase of slave, also get a Tubii object so we can stop Tubii sending pulses
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
        [pool release];
        return;
    }

    // Tell run control it can stop the run.
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];
    });

    NSLog(@"[TELLIE]: Stop commands sucessfully sent to TELLIE and TUBii\n");
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
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:10];
    
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE_UPLOAD]: Couldn't find ORRunModel\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"TELLIE_RUN"];
    NSMutableArray* subRunArray = [NSMutableArray arrayWithCapacity:10];

    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@""] forKey:@"index"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"timestamp"];

    [runDocDict setObject:[NSMutableArray arrayWithObjects:[NSNumber numberWithUnsignedLong:[runControl runNumber]],[NSNumber numberWithUnsignedLong:[runControl runNumber]], nil] forKey:@"run_range"];

    [runDocDict setObject:subRunArray forKey:@"sub_run_info"];

    [self setTellieRunDoc:runDocDict];

    [[self couchDBRef:self withDB:@"telliedb"] addDocument:runDocDict tag:kTellieRunDocumentAdded];
    [pool release];
}

- (void) updateTellieRunDocument:(NSDictionary*)subRunDoc
{
    /*
     Update [self tellieRunDoc] with subrun information.
     
     Arguments:
     NSDictionary* subRunDoc:  Subrun information to be added to the current [self tellieRunDoc].
     */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // Get run control
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[TELLIE_UPLOAD]: Couldn't find ORRunModel\n");
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
        [[self couchDBRef:self withDB:@"telliedb"]
         updateDocument:runDocDict
         documentId:[runDocDict objectForKey:@"_id"]
         tag:kTellieRunDocumentUpdated];
    }

    [runDocDict release];
    [subRunDocDict release];
    [subRunInfo release];
    [pool release];
}

-(void) loadTELLIEStaticsFromDB
{
    /*
     Load current tellie channel calibration and patch map settings from telliedb.
     This function accesses the telliedb and pulls down the most recent fireParameters,
     fibreMapping and nodeMapping documents. The data is then saved to the member variables
     tellieFireParameters, tellieFibreMapping and tellieNodeMapping.
     */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    //Set all to be nil
    [self setTellieFireParameters:nil];
    [self setTellieFibreMapping:nil];
    [self setTellieNodeMapping:nil];

    NSString* parsString = [NSString stringWithFormat:@"_design/tellieQuery/_view/fetchFireParameters?descending=False&limit=1"];
    NSString* mapString = [NSString stringWithFormat:@"_design/tellieQuery/_view/fetchCurrentMapping?key=2147483647"];
    NSString* nodeString = [NSString stringWithFormat:@"_design/mapping/_view/node_to_fibre?descending=True&limit=1"];

    // Make requests
    [[self couchDBRef:self withDB:@"telliedb"] getDocumentId:parsString tag:kTellieParsRetrieved];
    [[self couchDBRef:self withDB:@"telliedb"] getDocumentId:mapString tag:kTellieMapRetrieved];
    [[self couchDBRef:self withDB:@"telliedb"] getDocumentId:nodeString tag:kTellieNodeRetrieved];
    [self loadTELLIERunPlansFromDB];
    [pool release];
}

-(void) loadTELLIERunPlansFromDB
{
    [self setTellieRunNames:nil];
    NSString* runPlansString = [NSString stringWithFormat:@"_design/runs/_view/run_plans"];
    [[self couchDBRef:self withDB:@"telliedb"] getDocumentId:runPlansString tag:kTellieRunPlansRetrieved];
}

-(void)parseTellieFirePars:(id)aResult
{
    NSMutableDictionary* fireParametersDoc =[[[aResult objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"[TELLIE_DATABASE]: channel calibrations sucessfully loaded\n");
    [self setTellieFireParameters:fireParametersDoc];
}

-(void)parseTellieFibreMap:(id)aResult
{
    NSMutableDictionary* mappingDoc =[[[aResult objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"[TELLIE_DATABASE]: mapping document sucessfully loaded\n");
    [self setTellieFibreMapping:mappingDoc];
}

-(void)parseTellieNodeMap:(id)aResult
{
    NSMutableDictionary* nodeDoc =[[[aResult objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"];
    NSLog(@"[TELLIE_DATABASE]: node mapping document sucessfully loaded\n");
    [self setTellieNodeMapping:nodeDoc];
}

-(void)parseTellieRunPlans:(id)aResult
{
    NSArray* rows = [aResult objectForKey:@"rows"];
    NSMutableArray* names = [NSMutableArray arrayWithCapacity:[rows count]];
    for(NSDictionary* row in rows){
        [names addObject:[[row objectForKey:@"value"] objectForKey:@"name"]];
    }
    NSLog(@"[TELLIE_DATABASE]: run plan lables sucessfully loaded\n");
    [self setTellieRunNames:names];
}

/*********************************************************/
/*                  Smellie Functions                    */
/*********************************************************/
-(void) setSmellieNewRun:(NSNumber *)runNumber{
    NSArray* args = @[runNumber];
    id result = [[self smellieClient] command:@"new_run" withArgs:args];
    if([result isKindOfClass:[NSString class]]){
        NSException* e = [NSException
                          exceptionWithName:@"SMELLIE EXCEPTION"
                          reason:result
                          userInfo:nil];
        [e raise];
    }
}

-(void) deactivateSmellie
{
    id result = [[self smellieClient] command:@"deactivate"];
    if([result isKindOfClass:[NSString class]]){
        NSException* e = [NSException
                          exceptionWithName:@"SMELLIE EXCEPTION"
                          reason:result
                          userInfo:nil];
        [e raise];
    }
}

-(void)setSmellieLaserHeadMasterMode:(NSNumber*)laserSwitchChan withIntensity:(NSNumber*)intensity withRepRate:(NSNumber*)rate withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withNPulses:(NSNumber*)noPulses withGainVoltage:(NSNumber *)gain
{
    /*
    Run the SMELLIE system in Master Mode (NI Unit provides the trigger signal for both the lasers and the detector) using the PicoQuant Laser Heads
    
    :param ls_chan: the laser switch channel
    :param intensity: the laser intensity in per mil
    :param rep_rate: the repition rate of requested laser sequence
    :param fs_input_channel: the fibre switch input channel
    :param fs_output_channel: the fibre switch output channel
    :param n_pulses: the number of pulses
    :param gain: the gain setting to be applied at the MPU
    */
    NSArray* args = @[laserSwitchChan, intensity, rate, fibreInChan, fibreOutChan, noPulses, gain];
    id result = [[self smellieClient] command:@"laserheads_master_mode" withArgs:args];
    if([result isKindOfClass:[NSString class]]){
        NSException* e = [NSException
                          exceptionWithName:@"SMELLIE EXCEPTION"
                          reason:result
                          userInfo:nil];
        [e raise];
    }
}

-(void)setSmellieLaserHeadSlaveMode:(NSNumber*)laserSwitchChan withIntensity:(NSNumber*)intensity withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withTime:(NSNumber*)time withGainVoltage:(NSNumber*)gain
{
    /*
    Run the SMELLIE system in Slave Mode (SNO+ MTC/D provides the trigger signal for both the lasers and the detector) using the PicoQuant Laser Heads

    :param ls_chan: the laser switch channel
    :param intensity: the laser intensity in per mil
    :param fs_input_channel: the fibre switch input channel
    :param fs_output_channel: the fibre switch output channel
    :param n_pulses: the number of pulses
    :param time: time until SNODROP exits slave mode
    :param gain: the gain setting to be applied at the MPU
    */
    NSArray* args = @[laserSwitchChan, intensity, fibreInChan, fibreOutChan, time, gain];
    id result = [[self smellieClient] command:@"laserheads_slave_mode" withArgs:args];
    if([result isKindOfClass:[NSString class]]){
        NSException* e = [NSException
                          exceptionWithName:@"SMELLIE EXCEPTION"
                          reason:result
                          userInfo:nil];
        [e raise];
    }
}

-(void)setSmellieSuperkMasterMode:(NSNumber*)intensity withRepRate:(NSNumber*)rate withWavelengthLow:(NSNumber*)wavelengthLow withWavelengthHi:(NSNumber*)wavelengthHi withFibreInput:(NSNumber*)fibreInChan withFibreOutput:(NSNumber*)fibreOutChan withNPulses:(NSNumber*)noPulses withGainVoltage:(NSNumber *)gain
{
    /*
     Run the SMELLIE superK laser in Master Mode
     
     :param intensity: the laser intensity in per mil
     :param rep_rate: the repetition rate of requested laser sequence
     :param wavelength_low: the low edge of the wavelength window
     :param wavelength_hi: the high edge of the wavelength window
     :param fs_input_channel: the fibre switch input channel
     :param fs_output_channel: the fibre switch output channel
     :param n_pulses: the number of pulses
     :param gain: the gain setting to be applied at the MPU
     */
    NSArray* args = @[intensity, rate, wavelengthLow, wavelengthHi, fibreInChan, fibreOutChan, noPulses, gain];
    id result = [[self smellieClient] command:@"superk_master_mode" withArgs:args];
    if([result isKindOfClass:[NSString class]]){
        NSException* e = [NSException
                          exceptionWithName:@"SMELLIE EXCEPTION"
                          reason:result
                          userInfo:nil];
        [e raise];
    }
}

-(void) startInterlockThread;
{
    /*
     Launch a thread to host the keep alive pulsing.
     */

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    //////////////
    //Get the run controller
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find ORRunModel. Please add it to the experiment and restart the run.\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];
    
    NSArray* args = @[[NSNumber numberWithInteger:[runControl runNumber]]];
    @try {
        [[self interlockClient] command:@"new_run" withArgs:args];
        [[self interlockClient] command:@"set_arm"];
    }
    @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"[SMELLIE]: Problem activating interlock server, reason: %@\n", [e reason]);
        [self setEllieFireFlag:NO];
        [pool release];
        return;
    }
    
    //////////////////////
    // Start interlock thread
    interlockThread = [[NSThread alloc] initWithTarget:self selector:@selector(pulseKeepAlive:) object:nil];
    [interlockThread start];
    [pool release];
}


-(void)killKeepAlive:(NSNotification*)aNote
{
    /*
     Stop pulsing the keep alive and disarm the interlock
    */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [interlockThread cancel];
    @try {
        [[self interlockClient] command:@"set_disarm"];
    }
    @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"[SMELLIE]: Problem disarming interlock server, reason: %@\n", [e reason]);
    }
    [self setEllieFireFlag:NO];
    NSLog(@"[SMELLIE]: Smellie laser interlock server disarmed\n");
    [pool release];
}

-(void)pulseKeepAlive:(id)passed
{
    /*
     A fuction to be run in a thread, continually sending keep alive pulses to the interlock server
    */
    while (![interlockThread isCancelled]) {
        @try{
            [[self interlockClient] command:@"send_keepalive"];
        } @catch(NSException* e) {
            NSLogColor([NSColor redColor], @"[SMELLIE]: Problem sending keep alive to interlock server, reason: %@\n", [e reason]);
            [self setEllieFireFlag:NO];
            return;
        }
        [NSThread sleepForTimeInterval:0.05];
    }
    NSLog(@"[SMELLIE]: Stopped sending keep-alive to interlock server\n");
}

-(void)startSmellieRunInBackground:(NSDictionary*)smellieSettings
{
    [self performSelectorOnMainThread:@selector(startSmellieRun:) withObject:smellieSettings waitUntilDone:NO];
}

-(NSNumber*)estimateSmellieRunTime:(NSDictionary *)smellieSettings
{
    /*
        Use a dictionary of run settings to estimate the execution time of a smellie sequence
    */

    ////////////////////////////
    // Globals
    float triggerFrequency = [[smellieSettings objectForKey:@"trigger_frequency"] floatValue];
    float numberTriggersPerLoop = [[smellieSettings objectForKey:@"triggers_per_loop"] floatValue];

    ////////////////////////////
    // Fixed wavelength pars and time calc

    // Get laser / fibre arrays
    NSArray* smellieLaserArray = [self getSmellieRunLaserArray:smellieSettings];
    NSArray* smellieFibreArray = [self getSmellieRunFibreArray:smellieSettings];

    int numberIntensityLoops = 0;
    for(NSString* laser in smellieLaserArray){
        NSString* intensityString = [NSString stringWithFormat:@"%@_intensity_no_steps", laser];
        numberIntensityLoops = numberIntensityLoops + [[smellieSettings objectForKey:intensityString] intValue];
    }

    int numberGainLoops = 0;
    for(NSString* laser in smellieLaserArray){
        NSString* gainString = [NSString stringWithFormat:@"%@_gain_no_steps", laser];
        numberGainLoops = numberGainLoops + [[smellieSettings objectForKey:gainString] intValue];
    }

    int numberFixedLasers = 0;
    for(NSString* laser in smellieLaserArray){
        if([laser isEqualToString:@"superK"]){
            continue;
        }
        NSString* laserString = [NSString stringWithFormat:@"%@_laser_on", laser];
        numberFixedLasers = numberFixedLasers + [[smellieSettings objectForKey:laserString] intValue];
    }

    // Fixed wavelength laser time
    int fibreCounter = [smellieFibreArray count];
    float fixedTimeScale = (numberFixedLasers * fibreCounter * numberIntensityLoops * numberGainLoops);

    ///////////////////
    // superK time
    float superKTimeScale = (1 * fibreCounter * [[smellieSettings objectForKey:@"superK_wavelength_no_steps"] intValue] *
                             [[smellieSettings objectForKey:@"superK_intensity_no_steps"] intValue] *
                             [[smellieSettings objectForKey:@"superK_gain_no_steps"] intValue]);

    //////////////////////
    // Define some parameters for overheads calculation
    float changeIntensity = 0.5;
    float changeFibre = 0.1;
    float changeFixedLaser = 45;
    float changeSKWavelength = 1;
    float changeGain = 0.5;

    float laserOverhead = numberFixedLasers*changeFixedLaser;
    float fibreOverhead = fibreCounter*changeFibre;
    float wavelengthOverhead = [[smellieSettings objectForKey:@"superK_gain_no_steps"] intValue]*changeSKWavelength;
    float intensityOverhead = numberIntensityLoops*changeIntensity;
    float gainOverhead = numberGainLoops*changeGain;
    float totalOverhead = laserOverhead + fibreOverhead + wavelengthOverhead + intensityOverhead + gainOverhead;

    float totalTime = (((superKTimeScale + fixedTimeScale)*numberTriggersPerLoop) + totalOverhead)/ (triggerFrequency*60);
    return [NSNumber numberWithFloat:totalTime];
}

-(NSArray*)getSmellieRunLaserArray:(NSDictionary*)smellieSettings
{
    //Extract the lasers to be fired into an array
    NSMutableArray* laserArray = [NSMutableArray arrayWithCapacity:5];
    if([[smellieSettings objectForKey:@"PQ375_laser_on"] intValue] == 1){
        [laserArray addObject:@"PQ375"];
    } if([[smellieSettings objectForKey:@"PQ405_laser_on"] intValue] == 1) {
        [laserArray addObject:@"PQ405"];
    } if([[smellieSettings objectForKey:@"PQ440_laser_on"] intValue] == 1) {
        [laserArray addObject:@"PQ440"];
    } if([[smellieSettings objectForKey:@"PQ495_laser_on"] intValue] == 1) {
        [laserArray addObject:@"PQ495"];
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
    } if ([[smellieSettings objectForKey:@"powerMeter"] intValue] == 1){
        [fibreArray addObject:@"powerMeter"];
    }
    return fibreArray;
}

-(NSMutableArray*)getSmellieLowEdgeWavelengthArray:(NSDictionary*)smellieSettings
{
    //Read data
    int wavelengthLow = [[smellieSettings objectForKey:@"superK_wavelength_start"] intValue];
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
    float minIntensity = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_gain_minimum",laser]] floatValue];
    float increment = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_gain_increment",laser]] floatValue];
    int noSteps = [[smellieSettings objectForKey:[NSString stringWithFormat:@"%@_gain_no_steps",laser]] intValue];
    
    //Check to see if the maximum intensity is the same as the minimum intensity
    NSMutableArray* gains = [NSMutableArray arrayWithCapacity:noSteps];
    
    //Create intensities array
    for(int i=0; i < noSteps; i++){
        [gains addObject:[NSNumber numberWithFloat:(minIntensity + increment*i)]];
    }
    
    return gains;
}

-(void) startSmellieRunThread:(NSDictionary*)smellieSettings;
{
    /*
     Launch a thread to host the smellie run functionality.
    */

    //////////////////////
    // Start tellie thread
    [self setSmellieThread:[[NSThread alloc] initWithTarget:self selector:@selector(startSmellieRun:) object:smellieSettings]];
    [[self smellieThread] start];
}

-(void)startSmellieRun:(NSDictionary*)smellieSettings
{
    /*
     Form a smellie run using the passed smellie run file, stored in smellieSettings dictionary.
    */
    NSLog(@"[SMELLIE]:Setting up a SMELLIE Run\n");

    //////////////
    // This will likely run in thread so make an auto release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    //////////////
    //   GET TUBii & RunControl MODELS
    //////////////
    //Get a Tubii object
    NSArray*  tubiiModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    if(![tubiiModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find Tubii model.\n");
        goto err;
    }
    TUBiiModel* theTubiiModel = [tubiiModels objectAtIndex:0];

    //////////////
    //Get the run controller
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find ORRunModel. Please add it to the experiment and restart the run.\n");
        goto err;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    ///////////////
    // RUN CONTROL
    ///////////////////////
    // Check SMELLIE run type is masked in
    if(!([runControl runType] & kSMELLIERun)){
        NSLogColor([NSColor redColor], @"[SMELLIE] SMELLIE bit is not masked into the run type word\n");
        NSLogColor([NSColor redColor], @"[SMELLIE]: Please load the SMELLIE standard run type.\n");
        goto err;
    }

    ///////////////////////
    // Check trigger is being sent to asyncronus port (EXT_A)
    NSUInteger asyncTrigMask;
    @try{
        asyncTrigMask = [theTubiiModel asyncTrigMask];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"[SMELLIE]: Error requesting asyncTrigMask from Tubii.\n");
        goto err;
    }
    if(!(asyncTrigMask & 0x800000)){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Triggers as not being sent to asynchronous MTC/D port\n");
        NSLogColor([NSColor redColor], @"[SMELLIE]: Please amend via the TUBii GUI (triggers tab)\n");
        goto err;
    }

    ////////////////////////
    // SET MASTER / SLAVE MODE
    NSString *operationMode = [NSString stringWithFormat:@"%@",[smellieSettings objectForKey:@"operation_mode"]];
    if([operationMode isEqualToString:@"Slave Mode"]){
        [self setSmellieSlaveMode:YES];
        NSLog(@"[SMELLIE]: Running in SLAVE mode\n");
    }else if([operationMode isEqualToString:@"Master Mode"]){
        [self setSmellieSlaveMode:NO];
        NSLog(@"[SMELLIE]: Running in MASTER mode\n");
    }else{
        NSLogColor([NSColor redColor], @"[SMELLIE]: Slave / master mode could not be read in run plan file.\n");
        goto err;
    }
    
    /////////////////////
    // GET SMELLIE LASERS AND FIBRES TO LOOP OVER
    // Wavelengths, intensities and gains variables
    // for each fibre are generated within the laser
    // loop.
    //
    NSMutableArray* laserArray = [self getSmellieRunLaserArray:smellieSettings];
    NSMutableArray* fibreArray = [self getSmellieRunFibreArray:smellieSettings];

    // Make a dictionary to hold settings for pushing upto database
    NSMutableDictionary *valuesToFillPerSubRun = [[NSMutableDictionary alloc] initWithCapacity:100];
    
    //////////////////////
    // Define some parameters for overheads calculation
    NSNumber* changeIntensity = [NSNumber numberWithFloat:0.5];
    NSNumber* changeFibre = [NSNumber numberWithFloat:0.1];
    NSNumber* changeFixedLaser = [NSNumber numberWithFloat:45];
    NSNumber* changeSKWavelength = [NSNumber numberWithFloat:1];
    NSNumber* changeGain = [NSNumber numberWithFloat:0.5];
    
    /////////////////////
    // Create and push initial smellie run doc and tell smellie which run we're in
    [self setEllieFireFlag:YES];

    if([runControl isRunning]){
        @try{
            [self setSmellieNewRun:[NSNumber numberWithUnsignedLong:[runControl runNumber]]];
        } @catch(NSException* e) {
            NSLogColor([NSColor redColor], @"[SMELLIE]: Problem with server request: %@\n", [e reason]);
            goto err;
        }
        
        @try{
            [self pushInitialSmellieRunDocument];
        } @catch(NSException* e){
            NSLogColor([NSColor redColor],@"[SMELLIE]: Problem pushing initial run log: %@\n", [e reason]);
            goto err;
        }
    }
    
    // ***********************
    // BEGIN LOOPING!
    // laser loop
    //
    for(NSString* laserKey in laserArray){
        if([self ellieFireFlag] == NO || [[NSThread currentThread] isCancelled]){
            NSLogColor([NSColor redColor], @"[SMELLIE]: thread has been cancelled, killing sequence.\n");
            goto err;
        }
        NSLog(@"[SMELLIE]: Fire sequence requested for laser: %@\n", laserKey);
        
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
        NSNumber* rate = [smellieSettings objectForKey:@"trigger_frequency"];

        // ***********
        // Fibre loop
        //
        for(NSString* fibreKey in fibreArray){
            if([self ellieFireFlag] == NO || [[NSThread currentThread] isCancelled]){
                NSLogColor([NSColor redColor], @"[SMELLIE]: thread has been cancelled, killing sequence.\n");
                goto err;
            }
            NSLog(@"[SMELLIE]: Fire sequence requested for fibre: %@\n", fibreKey);

            // Add fibre to the subRun file
            [valuesToFillPerSubRun setObject:fibreKey forKey:@"fibre"];
            
            // ***************
            // Wavelength loop
            //
            for(NSNumber* wavelength in lowEdgeWavelengthArray){
                if([self ellieFireFlag] == NO || [[NSThread currentThread] isCancelled]){
                    NSLogColor([NSColor redColor], @"[SMELLIE]: thread has been cancelled, killing sequence.\n");
                    goto err;
                }
                
                // By default set the wavelength window to nil in rundoc
                NSNumber* wavelengthLowEdge = [NSNumber numberWithInt:0];
                NSNumber* wavelengthHighEdge = [NSNumber numberWithInt:0];
                
                // If this is the superK loop, make sure the wavelength window is set apropriately
                if([laserKey isEqualToString:@"superK"]){
                    wavelengthLowEdge = wavelength;
                    wavelengthHighEdge = [NSNumber numberWithInt:([wavelength integerValue] + [[smellieSettings objectForKey:@"superK_wavelength_bandwidth"] integerValue])];
                }

                [valuesToFillPerSubRun setObject:wavelengthLowEdge forKey:@"wavelength_low_edge"];
                [valuesToFillPerSubRun setObject:wavelengthHighEdge forKey:@"wavelength_high_edge"];
                
                // **************
                // Intensity loop
                //
                for(NSNumber* intensity in intensityArray){
                    if([self ellieFireFlag] == NO || [[NSThread currentThread] isCancelled]){
                        NSLogColor([NSColor redColor], @"[SMELLIE]: thread has been cancelled, killing sequence.\n");
                        goto err;
                    }
                    
                    // Add intensity value into runDoc
                    [valuesToFillPerSubRun setObject:intensity forKey:@"intensity"];
                    
                    // **************
                    // Gain loop
                    //
                    for(NSNumber* gain in gainArray){
                        if([self ellieFireFlag] == NO || [[NSThread currentThread] isCancelled]){
                            NSLogColor([NSColor redColor], @"[SMELLIE]: thread has been cancelled, killing sequence.\n");
                            goto err;
                        }
                        
                        ///////////////////////
                        // Inner most loop.
                        // Need to begin a new
                        // subrun and tell hardware
                        // what it should be running
                        //
                        
                        //////////////////////
                        // GET FINAL SMELLIE SETTINGS
                        [valuesToFillPerSubRun setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];
                        [valuesToFillPerSubRun setObject:gain forKey:@"gain"];
                        [valuesToFillPerSubRun setObject:[smellieSettings objectForKey:@"trigger_frequency"] forKey:@"pulse_rate"];
                        [valuesToFillPerSubRun setObject:[smellieSettings objectForKey:@"triggers_per_loop"] forKey:@"number_of_shots"];

                        NSNumber* laserSwitchChannel = [[self smellieLaserHeadToSepiaMapping] objectForKey:laserKey];
                        NSNumber* fibreInputSwitchChannel = [[self smellieLaserToInputFibreMapping] objectForKey:laserKey];
                        NSNumber* fibreOutputSwitchChannel = [[self smellieFibreSwitchToFibreMapping] objectForKey:fibreKey];
                        NSNumber* numOfPulses = [smellieSettings objectForKey:@"triggers_per_loop"];
                        
                        //////////////////////
                        // Calculate how long we expect this run loop to take
                        // Active firing time
                        float fireTime = [rate floatValue]*[numOfPulses floatValue];
                        // Overheads
                        // Assuption is that at the start of a new outer loop, all the inner
                        // loops must start from the first object in their array.
                        float overheads = [changeGain floatValue];
                        if([gain isEqualTo:[gainArray firstObject]]){ // New intensity
                            overheads = overheads + [changeIntensity floatValue];
                            if([intensity isEqualTo:[intensityArray firstObject]]){ // New wavelength
                                if([laserKey isEqualTo:@"superK"]){ // only important for superK
                                    overheads = overheads + [changeSKWavelength floatValue];
                                }
                                if([wavelength isEqualTo:[lowEdgeWavelengthArray firstObject]]){ // New fibre
                                    overheads = overheads + [changeFibre floatValue];
                                    if([fibreKey isEqualTo:[fibreArray firstObject]]){ // New laser
                                        if(![laserKey isEqualTo:@"superK"]){ // Only changing fixed lasers takes time
                                            overheads = overheads + [changeFixedLaser floatValue];
                                        }
                                    }
                                }
                            }
                        }
                        NSNumber* sequenceTime = [NSNumber numberWithFloat:(fireTime+overheads)];
                        
                        //////////////
                        // Slave mode
                        if([self smellieSlaveMode]){
                            if([laserKey isEqualTo:@"superK"]){
                                NSLogColor([NSColor redColor], @"[SMELLIE]: SuperK laser cannot be run in slave mode\n");
                            } else {
                                @try{
                                    [theTubiiModel setSmellieDelay:[[smellieSettings objectForKey:@"delay_fixed_wavelength"] intValue]];
                                } @catch(NSException* e) {
                                    NSLogColor([NSColor redColor], @"[SMELLIE]: Problem setting trigger delay at TUBii: %@\n", [e reason]);
                                    goto err;
                                }
                                @try{
                                    [self setSmellieLaserHeadSlaveMode:laserSwitchChannel withIntensity:intensity withFibreInput:fibreInputSwitchChannel withFibreOutput:fibreOutputSwitchChannel withTime:sequenceTime withGainVoltage:gain];
                                } @catch(NSException* e){
                                    NSLogColor([NSColor redColor], @"[SMELLIE]: Problem with smellie server request: %@\n", [e reason]);
                                    goto err;
                                }
                            }

                            //// **NOTE** ////
                            // May have to include a delay
                            // here to ensure smellie
                            // hardware is properly set
                            // before TUBii sends triggers
                            
                            //Set up tubii to send triggers
                            @try{
                                //Fire trigger pulses!
                                [theTubiiModel fireSmelliePulser_rate:[rate floatValue] pulseWidth:100 NPulses:numOfPulses];
                            } @catch(NSException* e) {
                                NSLogColor([NSColor redColor], @"[SMELLIE]: Problem with TUBii server request: %@\n", [e reason]);
                                goto err;
                            }

                        //////////////
                        // Master mode
                        } else {

                            //Set SMELLIE settings
                            if([laserKey isEqualTo:@"superK"]){
                                @try{
                                    [theTubiiModel setSmellieDelay:[[smellieSettings objectForKey:@"delay_superK"] intValue]];
                                } @catch(NSException* e) {
                                    NSLogColor([NSColor redColor], @"[SMELLIE]: Problem setting trigger delay at TUBii: %@\n", [e reason]);
                                    goto err;
                                }

                                @try{
                                    [self setSmellieSuperkMasterMode:intensity withRepRate:rate withWavelengthLow:wavelengthLowEdge withWavelengthHi:wavelengthHighEdge withFibreInput:fibreInputSwitchChannel withFibreOutput:fibreOutputSwitchChannel withNPulses:numOfPulses withGainVoltage:gain];
                                } @catch(NSException* e){
                                    NSLogColor([NSColor redColor], @"[SMELLIE]: Problem with smellie server request: %@\n", [e reason]);
                                    goto err;
                                }
                            } else {
/*
                                @try{
                                    [theTubiiModel setSmellieDelay:[[smellieSettings objectForKey:@"delay_fixed_wavelength"] intValue]];
                                } @catch(NSException* e) {
                                    NSLogColor([NSColor redColor], @"[SMELLIE]: Problem setting trigger delay at TUBii: %@\n", [e reason]);
                                    goto err;
                                }
*/
                                @try{
                                    [self setSmellieLaserHeadMasterMode:laserSwitchChannel withIntensity:intensity withRepRate:rate withFibreInput:fibreInputSwitchChannel withFibreOutput:fibreOutputSwitchChannel withNPulses:numOfPulses withGainVoltage:gain];
                                } @catch(NSException* e){
                                    NSLogColor([NSColor redColor], @"[SMELLIE]: Problem with smellie server request: %@\n", [e reason]);
                                    goto err;
                                }
                            }
                            
                        }

                        //////////////////
                        //Push record of sub-run settings to db
                        if([runControl isRunning]){
                            @try{
                                [self updateSmellieRunDocument:valuesToFillPerSubRun];
                            } @catch(NSException* e){
                                NSLogColor([NSColor redColor], @"[SMELLIE]: Problem updating couchdb run file: %@\n", [e reason]);
                                goto err;
                            }
                        }
                        
                        //////////////////
                        //Check if run file requests a sleep time between sub_runs
                        if([smellieSettings objectForKey:@"sleep_between_sub_run"]){
                            NSTimeInterval sleepTime = [[smellieSettings objectForKey:@"sleep_between_sub_run"] floatValue];
                            [NSThread sleepForTimeInterval:sleepTime];
                        }
                        
                        //////////////////
                        // RUN CONTROL
                        //Prepare new subrun - will produce a subrun boundrary in the zdab.
                        if([runControl isRunning]){
                            [runControl performSelectorOnMainThread:@selector(prepareForNewSubRun) withObject:nil waitUntilDone:YES];
                            [runControl performSelectorOnMainThread:@selector(startNewSubRun) withObject:nil waitUntilDone:YES];
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
    [[NSThread currentThread] cancel];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSMELLIERunFinished object:self];
    });
    return;

err:
{
    //Resetting the mtcd to settings before the smellie run
    NSLogColor([NSColor redColor], @"[SMELLIE]: Sent to err statement. Stopping fire sequence.\n");
    [pool release];

    ////////////
    // If thread errored we need to post a note to
    // call the formal stop proceedure. If the thread
    // was canelled we must already be in a 'stop'
    // button push, so don't need to post.
    if(![[NSThread currentThread] isCancelled]){
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ORSMELLIERunFinished object:self];
        });
    }
    [[NSThread currentThread] cancel];
}
}

-(void)stopSmellieRun
{
    /*
     Before we perform any tidy-up actions, we want to make sure the run thread has stopped
     executing. If the run has not been ended using the tellie specific 'stop fibre' button,
     but instead the user has simply hit the main run stop button on the SNOPController, we
     need to make sure SMELLIE has properly cleaned up before we roll into a new run.
     Fortunately there is a handy wait notification that gets picked up by the run control.

     Here we post the run wait notification and launch a thread that waits for the smellieThread
     to stop executing before tidying up and, finally, releasing the run wait.
     */

    [[self smellieThread] cancel];

    // Post a notification telling the run control to wait until the thread finishes
    NSDictionary* userInfo  = [NSDictionary dictionaryWithObjectsAndKeys:@"waiting for smellie run to finish", @"Reason", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object:self userInfo:userInfo];

    // Detatch thread to monitor smellie run thread
    [NSThread detachNewThreadSelector:@selector(waitForSmellieRunToFinish) toTarget:self withObject:nil];
}

-(void)waitForSmellieRunToFinish
{
    @autoreleasepool {
        while ([[self smellieThread] isExecuting]) {
            [NSThread sleepForTimeInterval:0.1];
        }
        [self smellieTidyUp];
    }
}

-(void)smellieTidyUp
{
    /*
     Some sign off / tidy up stuff to be called at the end of a smellie run.
     */

    ///////////
    // This could be run in a thread, so set-up an auto release pool
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    @try{
        [self deactivateSmellie];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"[SMELLIE]: Deactivate command could not be sent to the SMELLIE server, reason: %@\n", [e reason]);
    }

    // Kill the keepalive
    [self killKeepAlive:nil];

    // Get a Tubii object
    NSArray*  tubiiModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    if(![tubiiModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find TUBii model. Please add it to the experiment and restart the run.\n");
        goto err;
    }
    TUBiiModel* theTubiiModel = [tubiiModels objectAtIndex:0];
    @try{
        [theTubiiModel stopSmelliePulser];
    } @catch(NSException* e){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Problem sending stop command to the SMELLIE pulsar.\n");
        goto err;
    }

    // Tell run control it can stop waiting
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];
    });

    NSLog(@"[SMELLIE]: Run sequence stopped.\n");
    [pool release];
    return;

err:
    // Tell run control it can stop waiting
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];
    });

    [pool release];
    NSLog(@"[SMELLIE]: Run sequence stopped - TUBii is in an undefined state (may still be sending triggers).\n");
}

/*****************************/
/*  smellie db interactions  */
/*****************************/
-(void) pushInitialSmellieRunDocument
{
    /*
     Create a standard smellie run doc using ELLIEModel / SNOPModel / ORRunModel class
     variables and push up to the smelliedb. Additionally, the run doc dictionary set as
     the tellieRunDoc propery, to be updated later in the run.
     */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:10];

    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find ORRunModel. Please add one to the experiment and restart the run.\n");
        return;
    }
    ORRunModel* runControl = [runModels objectAtIndex:0];

    NSArray*  snopModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    if(![snopModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find SNOPModel. Please add one to the experiment and restart the run.\n");
        return;
    }
    SNOPModel* aSnotModel = [snopModels objectAtIndex:0];

    NSString* docType = [NSMutableString stringWithFormat:@"SMELLIE_RUN"];
    NSMutableArray* subRunArray = [NSMutableArray arrayWithCapacity:15];

    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@""] forKey:@"index"];
    [runDocDict setObject:[aSnotModel smellieRunNameLabel] forKey:@"run_description_used"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"timestamp"];
    [runDocDict setObject:[self smellieConfigVersionNo] forKey:@"configuration_version"];
    [runDocDict setObject:[NSNumber numberWithInt:[runControl runNumber]] forKey:@"run"];
    [runDocDict setObject:[NSMutableArray arrayWithObjects:[NSNumber numberWithUnsignedLong:[runControl runNumber]],[NSNumber numberWithUnsignedLong:[runControl runNumber]], nil] forKey:@"run_range"];

    [runDocDict setObject:subRunArray forKey:@"sub_run_info"];

    [self setSmellieRunDoc:runDocDict];

    [[self couchDBRef:self withDB:@"smellie"] addDocument:runDocDict tag:kSmellieRunDocumentAdded];
    [pool release];
}

- (void) updateSmellieRunDocument:(NSDictionary*)subRunDoc
{
    /*
     Update [self smellieRunDoc] with subrun information.
     
     Arguments:
     NSDictionary* subRunDoc:  Subrun information to be added to the current [self tellieRunDoc].
     */
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray*  runModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runModels count]){
        NSLogColor([NSColor redColor], @"[SMELLIE]: Couldn't find ORRunModel. Please add it to the experiment and restart the run.\n");
        return;    }
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
    [[self couchDBRef:self withDB:@"smellie"] updateDocument:runDocDict documentId:[runDocDict objectForKey:@"_id"] tag:kSmellieRunDocumentUpdated];

    [runDocDict release];
    [subRunDocDict release];
    [subRunInfo release];
    [pool release];
}

-(void) fetchCurrentSmellieConfig
{
    /*
     Query smellie config documenets on the smelliedb to find the most recent config versioning
     number.
    */
    NSString *requestString = [NSString stringWithFormat:@"_design/smellieMainQuery/_view/fetchMostRecentConfigVersion?descending=True&limit=1"];
    // Set config version number to be nil
    [self setSmellieConfigVersionNo:nil];
    [[self couchDBRef:self withDB:@"smellie"] getDocumentId:requestString tag:kSmellieConigVersionRetrieved];
}

-(void) parseCurrentConfigVersion:(id)aResult
{
    /*
     Parse the relavent information from the couch result given by fetchRecentSmellieConfig (above).
    */
    NSNumber* configVersion  = [[[aResult objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"key"];
    [self setSmellieConfigVersionNo:configVersion];
    
    // Now we have the most recent version number, go get the relavent file.
    [self fetchConfigurationFile:configVersion];
}

-(void) fetchConfigurationFile:(NSNumber*)currentVersion
{
    /*
     Fetch the current configuration document of a given version number.
     
     Arguments:
        NSNumber* currentVersion: The version number to be used with the query.
    */
    NSString *requestString = [NSString stringWithFormat:@"_design/smellieMainQuery/_view/pullEllieConfigHeaders?key=[%i]&limit=1",
                               [currentVersion intValue]];

    [[self couchDBRef:self withDB:@"smellie"] getDocumentId:requestString tag:kSmellieConigRetrieved];
}

-(void) parseConfigurationFile:(id)aResult
{
    /*
     Use the result returned by the couchdb querey prouced in fetchConfigurationFile (above) to
     fill dictionaries defining smellie's hardware configuration.
    */
    NSMutableDictionary* configForSmellie = [[[[aResult objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"] objectForKey:@"configuration_info"];

    //Set laser head to 'sepia' laser switch mapping
    NSMutableDictionary *laserHeadDict = [configForSmellie objectForKey:@"laserSwitchChannels"];
    NSMutableDictionary *laserHeadToSepiaMapping = [[NSMutableDictionary alloc] initWithCapacity:10];
    for (NSString* laserChannel in laserHeadDict){
        NSNumber* laserHeadIndex = [NSNumber numberWithInt:[[self extractNumberFromText:laserChannel] intValue]];
        NSString *laserHeadConnected = [NSString stringWithFormat:@"%@",[laserHeadDict objectForKey:laserChannel]];
        [laserHeadToSepiaMapping setObject:laserHeadIndex forKey:laserHeadConnected];
    }
    [self setSmellieLaserHeadToSepiaMapping:laserHeadToSepiaMapping];

    //Set laser to input fibre mapping
    NSMutableDictionary *fibreSwitchDict = [configForSmellie objectForKey:@"fibreSwitchChannels"];
    NSMutableDictionary *laserToInputFibreMapping = [[NSMutableDictionary alloc] initWithCapacity:10];
    NSMutableDictionary *fibreSwitchOutputToFibre = [[NSMutableDictionary alloc] initWithCapacity:10];
    for (NSString* switchChannel in fibreSwitchDict){
        NSString* firstChar = [switchChannel substringWithRange:NSMakeRange(0, 1)];
        NSNumber* numInString = [NSNumber numberWithInt:[[self extractNumberFromText:switchChannel] intValue]];
        if ([firstChar isEqualToString:@"i"]) { // Input channels
            NSString *laserHeadConnected = [NSString stringWithFormat:@"%@",[fibreSwitchDict objectForKey:switchChannel]];
            [laserToInputFibreMapping setObject:numInString forKey:laserHeadConnected];
        } else if ([firstChar isEqualToString:@"o"]) { // Output channels
            NSString *fibreConnected = [NSString stringWithFormat:@"%@",[fibreSwitchDict objectForKey:switchChannel]];
            [fibreSwitchOutputToFibre setObject:numInString forKey:fibreConnected];
        }
    }
    [self setSmellieLaserToInputFibreMapping:laserToInputFibreMapping];
    [self setSmellieFibreSwitchToFibreMapping:fibreSwitchOutputToFibre];

    [laserHeadToSepiaMapping release];
    [laserToInputFibreMapping release];
    [fibreSwitchOutputToFibre release];
    
    NSLog(@"[SMELLIE] config file (version %i) sucessfully loaded\n", [[self smellieConfigVersionNo] intValue]);
}

/*********************************************************/
/*              General Database Functions               */
/*********************************************************/
- (ORCouchDB*) couchDBRef:(id)aCouchDelegate withDB:(NSString*)entryDB;
{
    /*
     Get an ORCouchDB object pointing to a sno+ couchDB repo.
     
     Arguments:
     id aCouchDelegate:  An OrcaObject which will be delgated some functionality during
     ORCouchDB function calls. This is used to select which model
     handels the returned result via a couchDBResult method.
     NSString* entryDB:  The SNO+ couchDB repo to be assocated with the ORCouchDB object.
     
     Returns:
     ORCouchDB* result:  An ORCouchDB object pointing to the entryDB repo.
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

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp
{
    /*
     A delagate function which catches the result of couchdb queries.
     The relavent follow up function (normally to parse the returned data)
     is called based on the tag that was sent with the request.
     
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
            } else if ([aTag isEqualToString:kSmellieConigVersionRetrieved]){
                [self parseCurrentConfigVersion:aResult];
            } else if ([aTag isEqualToString:kSmellieConigRetrieved]){
                [self parseConfigurationFile:aResult];
            } else if ([aTag isEqualToString:kTellieParsRetrieved]){
                [self parseTellieFirePars:aResult];
            } else if ([aTag isEqualToString:kTellieMapRetrieved]){
                [self parseTellieFibreMap:aResult];
            } else if ([aTag isEqualToString:kTellieNodeRetrieved]){
                [self parseTellieNodeMap:aResult];
            } else if ([aTag isEqualToString:kTellieRunPlansRetrieved]){
                [self parseTellieRunPlans:aResult];
            }

            //If no tag is found for the query result
            else {
                NSLog(@"No Tag assigned to that query/couchDB View \n");
                NSLog(@"Object: %@\n",aResult);
            }
        }

        else if([aResult isKindOfClass:[NSArray class]]){
            [aResult prettyPrint:@"CouchDB"];
        }
        else{
            //no docs found 
        }
    }
}

/****************************************/
/*        Misc generic methods          */
/****************************************/

- (NSString *)extractNumberFromText:(NSString *)text
{
    NSCharacterSet *nonDigitCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [[text componentsSeparatedByCharactersInSet:nonDigitCharacterSet] componentsJoinedByString:@""];
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

/****************************************/
/*            Server settings           */
/****************************************/
- (void) setTelliePort: (NSString*) port
{
    /* Set the port number for the tellie server XMLRPC client. */
    if ([port isEqualToString:[self telliePort]]) return;

    _telliePort = port;
    [[self tellieClient] setPort:port];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ELLIEServerSettingsChanged" object:self];
}

- (void) setSmelliePort: (NSString*) port
{
    /* Set the port number for the smellie server XMLRPC client. */
    if ([port isEqualToString:[self smelliePort]]) return;

    _smelliePort = port;
    [[self smellieClient] setPort:port];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ELLIEServerSettingsChanged" object:self];
}

- (void) setInterlockPort: (NSString*) port
{
    /* Set the port number for the interlock server XMLRPC client. */
    if ([port isEqualToString:[self interlockPort]]) return;

    _interlockPort = port;
    [[self interlockClient] setPort:port];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ELLIEServerSettingsChanged" object:self];
}

- (void) setTellieHost: (NSString*) host
{
    /* Set the host for the tellie server XMLRPC client. */
    if (host == [self tellieHost]) return;

    _tellieHost = host;
    [[self tellieClient] setHost:host];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ELLIEServerSettingsChanged" object:self];
}

- (void) setSmellieHost: (NSString*) host
{
    /* Set the host for the smellie server XMLRPC client. */
    if (host == [self smellieHost]) return;

    _smellieHost = host;
    [[self smellieClient] setHost:host];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ELLIEServerSettingsChanged" object:self];
}

- (void) setInterlockHost: (NSString*) host
{
    /* Set the host for the interlock server XMLRPC client. */
    if (host == [self interlockHost]) return;

    _interlockHost = host;
    [[self interlockClient] setHost:host];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ELLIEServerSettingsChanged" object:self];
}

-(BOOL)pingTellie
{
    @try{
        [[self tellieClient] command:@"test"];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"Could not ping tellie server, reason: %@\n", [e reason]);
        return NO;
    }
    return YES;
}

-(BOOL)pingSmellie
{
    @try{
        [[self smellieClient] command:@"is_connected"];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"Could not ping smellie server, reason: %@\n", [e reason]);
        return NO;
    }
    return YES;
}

-(BOOL)pingInterlock
{
    @try{
        [[self interlockClient] command:@"is_connected"];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor], @"Could not ping interlock server, reason: %@\n", [e reason]);
        return NO;
    }
    return YES;
}



@end
