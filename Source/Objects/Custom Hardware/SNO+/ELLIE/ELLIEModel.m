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

@synthesize smellieRunSettings;
@synthesize exampleTask;
@synthesize smellieRunHeaderDocList;
@synthesize smellieSubRunInfo,
pulseByPulseDelay,
tellieRunDoc,
currentOrcaSettingsForSmellie,
tellieSubRunSettings,
smellieDBReadInProgress = _smellieDBReadInProgress;

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
	[super dealloc];
}

- (void) registerNotificationObservers
{
     NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    //we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
}

/**************************************/
/*          TELLIE Functions          */
/**************************************/
-(void) startTellieRun
{
    /* 
     Start run using run control object and push initial TELLIE run doc to telliedb.
     
     Possible additions:
        Use SNOPModel to check if tellie run type is masked in
     */
    
    //add run control object
    NSArray*  runControlObjsArray = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    runControl = [runControlObjsArray objectAtIndex:0];
    
    if(![runControl isRunning]){
        [runControl performSelectorOnMainThread:@selector(startRun) withObject:nil waitUntilDone:YES];
    } else if ([runControl isRunning]) {
        [self _pushInitialTellieRunDocument];
    }
}

-(void) stopTellieRun
{
    /*
     Use run control object to stop a tellie run.
    */
    
    //add run control object
    NSArray*  runControlObjsArray = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    runControl = [runControlObjsArray objectAtIndex:0];
    
    if([runControl isRunning]){
        [runControl performSelectorOnMainThread:@selector(haltRun) withObject:nil waitUntilDone:YES];
    }
}

-(void) pollTellieFibre
{
    /*
     Poll the TELLIE hardware using an XMLRPC server and requests the response from the
     hardware.
    */
    
    NSString* responseFromTellie =[self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/tellie/tellie_readout_script.py" withCmdLineArgs:nil];
    NSLog(@"Response from Tellie: %@\n",responseFromTellie);
}

-(void) fireTellieFibreMaster:(NSMutableDictionary*)fireCommands
{
    /*
     Fire a tellie channel - which maps to an optical fibre in the detector. This function
     calls a python script on the DAQ1 machine, passing it command line arguments relating
     to specific tellie channel settings. The called python script relays the commands 
     to the tellie hardware using a XMLRPC server which must be lanuched manually via the
     command line prior to launching ORCA.
     
     Arguments: 
        NSMutableDictionary fireCommands :  A dictionary containing hardware settings to
                                            be relayed to the tellie hardware.
     
    */
    
    //add run control object
    NSArray*  runControlObjsArray = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    runControl = [runControlObjsArray objectAtIndex:0];
    
    //start a new subrun
    [runControl performSelectorOnMainThread:@selector(prepareForNewSubRun) withObject:nil waitUntilDone:YES];
    [runControl performSelectorOnMainThread:@selector(startNewSubRun) withObject:nil waitUntilDone:YES];
    
    //TODO:Add this back in
    //Post to the Database what is about to happen
    __block NSString * responseFromTellie = [[NSString alloc] init];
    NSArray * nullCommandArguments = @[@"-c",[[fireCommands objectForKey:@"channel"] stringValue],@"-n",[[fireCommands objectForKey:@"number_of_shots"] stringValue],@"-d",[[fireCommands objectForKey:@"pulse_rate"] stringValue],@"-t",[[fireCommands objectForKey:@"trigger_delay"] stringValue],@"-w",[[fireCommands objectForKey:@"pulse_width"] stringValue],@"-z",[[fireCommands objectForKey:@"pulse_height"] stringValue],@"-x",[[fireCommands objectForKey:@"fibre_delay"] stringValue]];
    
    double numberOfShots = [[fireCommands objectForKey:@"number_of_shots"] doubleValue];
    double timeBetweenShotsInMicroSeconds = [[fireCommands objectForKey:@"pulse_rate"] doubleValue]/(1000.0);
    if(pulseByPulseDelay < 0.1){
        NSLog(@"Pulse by pulse delay is too small. Setting to 0.1");
        pulseByPulseDelay = 0.1;
    }
    else if (pulseByPulseDelay > 25.0)
    {
        NSLog(@"Pulse by pulse delay is too small. Setting to 25.0");
        pulseByPulseDelay = 25.0;
    }
    else{
        //do nothing 
    }
    
    //reduce the pulse by pulse delay to a percentage
    pulseByPulseDelay = pulseByPulseDelay/100.0;
    
    double timeToSleep = (1.0+pulseByPulseDelay)*numberOfShots*timeBetweenShotsInMicroSeconds; //20% grace period for each shot
    
    //hold the fire command on this thread
    // This line is depreciated - bring it up with the working group, see if they have
    // a preferred solution.*
    dispatch_sync(dispatch_get_current_queue(), ^{
        responseFromTellie =[self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/tellie/tellie_fire_script.py" withCmdLineArgs:nullCommandArguments];
        NSLog(@"Response from Tellie FIRE command: %@\n",responseFromTellie);
    });

    //NSLog(@"in here");
    [NSThread sleepForTimeInterval:timeToSleep];
    
    //[NSThread sleepForTimeInterval:1.0];
    __block NSString * responseFromPoll = [[NSString alloc] init];
    // * same as above.
    dispatch_sync(dispatch_get_current_queue(), ^{
        responseFromPoll = [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/tellie/tellie_readout_script.py" withCmdLineArgs:nil];
        NSLog(@"Response from Tellie READ command: %@\n",responseFromPoll);
    });
    
    @try {
        [fireCommands setObject:[NSNumber numberWithInt:[responseFromPoll intValue]] forKey:@"pin_readout"];
    }
    @catch (NSException *exception) {
        NSLog(@"Unable to add pin readout due to error %@",exception);
    }
    
    [responseFromTellie release];
    [self updateTellieDocument:fireCommands];
}

-(void) stopTellieFibre:(NSArray*)fireCommands
{
    /*
     Call tellie stop script. The script itself is stored on the DAQ1 machine.
    */
    NSString *responseFromTellie =[self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/tellie/tellie_stop_script.py" withCmdLineArgs:nil];
    NSLog(@"Response from Tellie: %@\n",responseFromTellie);
}

/***************************************/
/*          Smellie Functions         */
/***************************************/
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

//complete this after the smellie documents have been recieved
-(void)smellieDocumentsRecieved
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
    
	return [ORCouchDB couchHost:[aSnotModel orcaDBIPAddress]
                           port:[aSnotModel orcaDBPort]
                       username:[aSnotModel orcaDBUserName]
                            pwd:[aSnotModel orcaDBPassword]
                       database:aCouchDb
                       delegate:aSnotModel];
}

-(NSString*)callPythonScript:(NSString*)pythonScriptFilePath withCmdLineArgs:(NSArray*)commandLineArgs
{
    /*
     Call a python script on the DAQ1 machine. Currently three cases are hardcoded into
     this function, defined by the size of the commandLineArgs array variable. Smellie
     commands take three args, tellie fire commands take fourteen and poll requests take
     none.
     
     Arguments: 
      NSString* pythonScriptFilePath : Path to the script to be called (on DAQ1). 
      NSArray* commandLineArgs       : Arguments to be passed to the script.
     
     Returns:
      NSString* responseFromCmdLine  : The text response returned by the called script.
    */
    
    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/python"]; // Tell the task to execute the ssh command
    
    if([commandLineArgs count] == 3){ //this is the case for smellie commands 
        [task setArguments: [NSArray arrayWithObjects:pythonScriptFilePath,[commandLineArgs objectAtIndex:0],[commandLineArgs objectAtIndex:1],[commandLineArgs objectAtIndex:2], nil]];
    }
    else if ([commandLineArgs count] == 14){ //this is the case for the fire tellie commands
        [task setArguments: [NSArray arrayWithObjects:pythonScriptFilePath,[commandLineArgs objectAtIndex:0],[commandLineArgs objectAtIndex:1],[commandLineArgs objectAtIndex:2],[commandLineArgs objectAtIndex:3],[commandLineArgs objectAtIndex:4],[commandLineArgs objectAtIndex:5],[commandLineArgs objectAtIndex:6],[commandLineArgs objectAtIndex:7],[commandLineArgs objectAtIndex:8],[commandLineArgs objectAtIndex:9],[commandLineArgs objectAtIndex:10],[commandLineArgs objectAtIndex:11],[commandLineArgs objectAtIndex:12],[commandLineArgs objectAtIndex:13], nil]];
    }
    else if ([commandLineArgs count] == 0){  //this is for the tellie poll script
        [task setArguments:[NSArray arrayWithObjects:pythonScriptFilePath, nil]];
    }
    else{
        return @"unable to call python script with correct number of arguments";
    }
    
    NSPipe* pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSFileHandle* file = [pipe fileHandleForReading]; // This file handle is a reference to the output of the ssh command
    
    @try{
        [task launch];
    }
    @catch (NSException *e) {
        NSLog(@"ELLIE Connection Error calling script %@: %@",pythonScriptFilePath,e);
    }
    @finally {
        //do something here
    }

    NSData* data = [file readDataToEndOfFile];
    NSString* responseFromCmdLine = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease]; // This string now contains the entire output of the ssh command.
    
    [task release];
    return responseFromCmdLine;
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
            
    //self.runDocument = runDocDict;
    [[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:aCouchDBName] addDocument:runDocDict tag:kSmellieRunDocumentAdded];
}

-(void) _pushSmellieRunDocument
{
    /*
     Creat a standard smellie run doc using ELLIEModel / SNOPModel / ORRunModel class 
     variables and push up to the smelliedb.
    */
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:100];
    
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    SNOPModel* aSnotModel = [objs objectAtIndex:0];
    
    //Collect objects from ORRunModel
    NSArray*  objs3 = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    runControl = [objs3 objectAtIndex:0];
    
    NSString* docType = [NSMutableString stringWithFormat:@"smellie_run"];
    NSString* smellieRunNameLabel = [aSnotModel smellieRunNameLabel];
    
    [runDocDict setObject:docType forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@"%lu",[runControl runNumber]] forKey:@"index"];
    [runDocDict setObject:smellieRunNameLabel forKey:@"run_description_used"];
    [runDocDict setObject:[self stringUnixFromDate:nil] forKey:@"issue_time_unix"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"issue_time_iso"];
    NSNumber *smellieConfigurationVersion = [self fetchRecentVersion];
    [runDocDict setObject:smellieConfigurationVersion forKey:@"configuration_version"];
    [runDocDict setObject:[NSNumber numberWithInt:[runControl runNumber]] forKey:@"run"];
    [runDocDict setObject:smellieSubRunInfo forKey:@"sub_run_info"];
    
    [[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:@"smellie"] addDocument:runDocDict tag:kSmellieSubRunDocumentAdded];
}

-(void) _pushInitialTellieRunDocument
{
    /* Creates and uploads an initial run document to the CouchDB. A dictionary
     * repesenting the doc is additionally saved as a memeber variable, this
     * dict is updated with subrun info as it becomes availbale. If the
     * document fails to upload, raises an exception */
    
    // Get run control object
    NSArray*  objs3 = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    runControl = [objs3 objectAtIndex:0];

    // Build dictionary
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:10];
    NSMutableArray* subRunArray = [NSMutableArray arrayWithCapacity:10];
    [runDocDict setObject:@"tellie_run" forKey:@"type"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"version"];
    [runDocDict setObject:[NSString stringWithFormat:@"%i",0] forKey:@"pass"];
    [runDocDict setObject:[NSNumber numberWithBool:YES] forKey:@"Production"];
    [runDocDict setObject:[NSString stringWithFormat:@""] forKey:@"Comment"];
    [runDocDict setObject:[NSString stringWithFormat:@"%lu",[runControl runNumber]] forKey:@"index"];
    [runDocDict setObject:[self stringUnixFromDate:nil] forKey:@"issue_time_unix"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"issue_time_iso"];
    [runDocDict setObject:[NSMutableArray arrayWithObjects:[runControl runNumber],[runControl runNumber], nil] forKey:@"run_range"];
    [runDocDict setObject:subRunArray forKey:@"sub_run_info"];

    // Use tellieRunDoc property's autogenerated setter to set tellieRunDoc.
    // The tellieRunDoc property was instantiated with the release property so
    // getter and setter methods will automatically handle memory creation /
    // retention / release.
    self.tellieRunDoc = runDocDict;
    
    // Post and update kTellieRunDocumentAdded bool
    [[self orcaDbRefWithEntryDB:self withDB:@"tellie"] addDocument:runDocDict tag:kTellieRunDocumentAdded];
    
    // wait for main thread to receive acknowledgement from couchdb
    NSInteger timeoutLimit = 2;
    NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow:timeoutLimit];
    while (![self.tellieRunDoc objectForKey:@"_id"]) {
        [NSThread sleepForTimeInterval:0.1];
        if ([timeout timeIntervalSinceNow] > 0) {
            [NSException raise:@"Timeout exception" format:@"Initial tellieRunDoc took > %d s to post", timeoutLimit];
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

- (void) updateTellieDocument:(NSDictionary*)subRunDoc
{
    /*
     Update self.tellieRunDoc with subrun information.
     
     Arguments:
        NSDictionary* subRunDoc:  Subrun information to be added to the current self.tellieRunDoc.
    */
    NSMutableDictionary* runDocDict = [self.tellieRunDoc mutableCopy];
    NSMutableDictionary* subRunDocDict = [self.tellieSubRunSettings mutableCopy];
    
    [subRunDocDict setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];
    @try{
        [subRunDocDict setObject:[NSNumber numberWithInt:[[subRunDoc objectForKey:@"pin_readout"] intValue]] forKey:@"pin_readout"];
    }
    @catch (NSException *e) {
        NSLog(@"Error in pin readout %@",e);
    }
    NSMutableArray * subRunInfo = [[runDocDict objectForKey:@"sub_run_info"] mutableCopy];
    [subRunInfo addObject:subRunDocDict];
    [runDocDict setObject:subRunInfo forKey:@"sub_run_info"];
    
    //Update tellieRunDoc property.
    self.tellieRunDoc = runDocDict;
    
    //check to see if run is offline or not
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        [[self orcaDbRefWithEntryDB:self withDB:@"tellie"]
                            updateDocument:runDocDict
                                documentId:[runDocDict objectForKey:@"_id"]
                                       tag:kTellieRunDocumentUpdated];
    }
    [subRunInfo release];
    [runDocDict release];
    [subRunDocDict release];
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
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    
    //Initialise the SNOPModel
    SNOPModel* aSnotModel = [objs objectAtIndex:0];
    
    NSString* docType = [NSMutableString stringWithFormat:@"%@",aDocType];
    
    NSLog(@"document_type: %@",docType);
    
    [configDocDic setObject:docType forKey:@"doc_type"];
    [configDocDic setObject:[self stringDateFromDate:nil] forKey:@"time_stamp"];
    [configDocDic setObject:customRunFile forKey:@"configuration_info"];

    //self.runDocument = runDocDict;
    [[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:aCouchDBName] addDocument:configDocDic tag:kSmellieRunDocumentAdded];
}

-(void) smellieDBpush:(NSMutableDictionary*)dbDic
{
    [self _pushEllieCustomRunToDB:@"smellie" runFiletoPush:dbDic withDocType:@"smellie_run_description"];
}

-(void) smellieConfigurationDBpush:(NSMutableDictionary*)dbDic
{
    [self _pushEllieConfigDocToDB:@"smellie" runFiletoPush:dbDic withDocType:@"smellie_run_configuration"];
}

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

-(void)startSmellieRunInBackground:(NSDictionary*)smellieSettings
{
    [self performSelectorOnMainThread:@selector(startSmellieRun:) withObject:smellieSettings waitUntilDone:NO];
}

/****************************************/
/*      SMELLIE Control Functions       */
/****************************************/
-(void)setSmellieSafeStates
{
    NSArray * setSafeStates = @[@"30",@"0",@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection_V2.py" withCmdLineArgs:setSafeStates];
}

-(void)setLaserSwitch:(NSString*)laserSwitchChannel
{
    NSArray * setLaserSwitchFlagAndArgument = @[@"2050",laserSwitchChannel,@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection_V2.py" withCmdLineArgs:setLaserSwitchFlagAndArgument];
}

-(void)setFibreSwitch:(NSString*)fibreSwitchInputChannel withOutputChannel:(NSString*)fibreSwitchOutputChannel
{
    NSString * argumentStringFS = [NSString stringWithFormat:@"%@s%@",fibreSwitchInputChannel,fibreSwitchOutputChannel];
    //NSLog(@"fibre switch argument %@",argumentStringFS);
    NSArray * setFibreSwitchFlagAndArgument = @[@"40",argumentStringFS,@"0"];
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection_V2.py" withCmdLineArgs:setFibreSwitchFlagAndArgument];
}

-(void)setLaserIntensity:(NSString*)laserIntensity
{
    NSArray * setLaserIntensityFlagAndArgument = @[@"50",laserIntensity,@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection_V2.py" withCmdLineArgs:setLaserIntensityFlagAndArgument];
}

-(void)setLaserSoftLockOn
{
    NSArray * softLockOnFlag = @[@"60",@"0",@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection_V2.py" withCmdLineArgs:softLockOnFlag];
}

//this function kills any external software that will block the functions of a smellie run 
-(void)killBlockingSoftware
{
    NSArray * killBS = @[@"110",@"0",@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection_V2.py" withCmdLineArgs:killBS];
}

-(void)setLaserSoftLockOff
{
    NSArray * softLockOffFlag = @[@"70",@"0",@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection_V2.py" withCmdLineArgs:softLockOffFlag];
}

-(void)setLaserFrequency20Mhz
{
    NSArray * frequencyTestingModeFlag = @[@"90",@"0",@"0"]; 
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection_V2.py" withCmdLineArgs:frequencyTestingModeFlag];
}

-(void)setSmellieMasterMode:(NSString*)triggerFrequency withNumOfPulses:(NSString*)numOfPulses
{
    NSString * argumentString = [NSString stringWithFormat:@"%@s%@",triggerFrequency,numOfPulses];
    NSArray * smellieMasterModeFlag = @[@"80",argumentString,@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection_V2.py" withCmdLineArgs:smellieMasterModeFlag];
}

-(void)setGainControlWithGainVoltage:(NSString*)gainVoltage
{
    NSArray * gainControlFlag = @[@"22110",gainVoltage,@"0"]; //gain control settings with gain voltage
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection_V2.py" withCmdLineArgs:gainControlFlag];
}

-(void)sendCustomSmellieCmd:(NSString*)customCmd withArgument1:(NSString*)customArgument1 withArgument2:(NSString*)customArgument2
{
    //Make sure all the arguments default to a safe value if not specified
    if([customCmd length]==0){
        customCmd = @"0";
    }
    
    if(([customArgument1 length]==0) || [customArgument1 isEqualToString:@""]){
        customArgument1 = @"0";
    }
    
    if(([customArgument2 length]==0) || [customArgument2 isEqualToString:@""]){
        customArgument2 = @"0";
    }
        
    NSArray* smellieCustomCmd = @[customCmd,customArgument1,customArgument2];
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection_V2.py" withCmdLineArgs:smellieCustomCmd];
}

-(void)testFunction
{
    NSArray* objs3 = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    runControl = [objs3 objectAtIndex:0];
    
    [runControl performSelector:@selector(haltRun)withObject:nil afterDelay:.1];
}

-(NSNumber*) fetchRecentVersion
{
    /*
     Query smellie config documenets on the smelliedb to find the most recent config versioning
     number.
    */
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    //Initialise the SNOPModel
    SNOPModel* aSnotModel = [objs objectAtIndex:0];
    
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
            NSLog(@"parsedNumber%@",currentVersionNumber);
            NSLog(@"valueforkey2=%@", [[json valueForKey:@"rows"] valueForKey:@"value"]);
        }
        @catch (NSException *e) {
            NSLog(@"Error in fetching the SMELLIE CONFIGURATION FILE: %@ . Please fix this before changing the configuration file",e);
        }
    }else{
        NSLog(@"Error querying couchDB, please check the connection is correct %@",error);
    }
    
    return currentVersionNumber;
}

-(NSMutableDictionary*) fetchCurrentConfigurationForVersion:(NSNumber*)currentVersion
{
    /*
     Fetch the current configuration document of a given version number.
     
     Arguments:
        NSNumber* currentVersion: The version number to be used with the query.
    */
    NSArray*  objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    SNOPModel* aSnotModel = [objs objectAtIndex:0];
    
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
    return [[[[currentConfig objectForKey:@"rows"]  objectAtIndex:0] objectForKey:@"value"] objectForKey:@"configuration_info"];
}

-(void)startSmellieRun:(NSDictionary*)smellieSettings
{
    /*
     Start a smellie run. 
     
     COMMENT:
        I think this method should be implemented as a standard run script, not as an object 
        method. I'll look into doing this after the DAQ meeting in Jan - Once I know the tellie
        one works!
    */
    //stop any current runs and go into a maintainence run 
    //[runControl performSelectorOnMainThread:@selector(stopRun) withObject:nil waitUntilDone:YES];
    //[runControl performSelectorOnMainThread:@selector(startRun) withObject:nil waitUntilDone:YES];
    
    //Set the Run Type to a SMELLIE run -- Not sure if this should be commented back in?
    //NSArray*  objsSNOP = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    //SNOPModel* theSNOPModel = [objsSNOP objectAtIndex:0];
    //[theSNOPModel setRunType:kRunSmellie]; //sets the run_type to a smellie run type
    
    NSLog(@"SMELLIE_RUN:Setting up a SMELLIE Run\n");
    
    NSLog(@"SMELLIE_RUN:Stopping any Blocking Software on SMELLIE computer(SNODROP)\n");
    [self killBlockingSoftware];

    NSNumber* currentConfigurationVersion = [self fetchRecentVersion];
    
    //fetch the data associated with the current configuration
    NSMutableDictionary *configForSmellie = [[self fetchCurrentConfigurationForVersion:currentConfigurationVersion] mutableCopy];
    
    NSMutableDictionary *laserHeadToSepiaMapping = [[NSMutableDictionary alloc] initWithCapacity:10];
    int laserHeadIndex =0;
    for(laserHeadIndex =0; laserHeadIndex < 6; laserHeadIndex++){
        
        for (id specificConfigValue in configForSmellie){
            if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput%i",laserHeadIndex]]){
                
                NSString *laserHeadConnected = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"laserHeadConnected"]];
                
                [laserHeadToSepiaMapping setObject:[NSString stringWithFormat:@"%i",laserHeadIndex] forKey:laserHeadConnected];
            }
        }
    } //end of looping through each laserHeadIndex
    
    NSMutableDictionary *laserHeadToGainControlMapping = [[NSMutableDictionary alloc] initWithCapacity:10];
    for(laserHeadIndex =0; laserHeadIndex < 6; laserHeadIndex++){
        
        for (id specificConfigValue in configForSmellie){
            if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"laserInput%i",laserHeadIndex]]){
                
                NSString *laserHeadConnected = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"laserHeadConnected"]];
                
                NSString *laserGainControl = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"gainControlFactor"]];
                
                [laserHeadToGainControlMapping setObject:[NSString stringWithFormat:@"%@",laserGainControl] forKey:laserHeadConnected];
            }
        }
    } //end of looping through each laserHeadIndex
    
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
                
                //NSString* updatedFibreReference = [fibreSwitchInputConnected stringByReplacingOccurrencesOfString:@"Channel" withString:@""];
                
                //[specificConfigValue objectForKey:@"fibreSwitchInputConnected"];
                
            //if([[specificConfigValue objectForKey:@"fibreSwitchInputConnected"] isEqualToString:[NSString stringWithFormat:@"laserInput%i",inputChannelIndex]]){
                
                //NSString *fibreSwitchInputConnected = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"fibreSwitchInputConnected"]];
                
                //NSString* updatedFibreReference = [fibreSwitchInputConnected stringByReplacingOccurrencesOfString:@"Channel" withString:@""];
                
                /*NSString* laserHeadReference = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"laserHeadConnected"]];

                [laserToInputFibreMapping setObject:[NSString stringWithFormat:@"%i",inputChannelIndex] forKey:laserHeadReference];*/
    }
       // }

    }
    
    NSMutableDictionary *fibreSwitchOutputToFibre = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    int outputChannelIndex = 0;
    for(outputChannelIndex = 1; outputChannelIndex < 15; outputChannelIndex++){
        
        for (id specificConfigValue in configForSmellie){
            if([specificConfigValue isEqualToString:[NSString stringWithFormat:@"Channel%i",outputChannelIndex]]){
                
                NSString *fibreReference = [NSString stringWithFormat:@"%@",[[configForSmellie objectForKey:specificConfigValue] objectForKey:@"detectorFibreReference"]];
                
                [fibreSwitchOutputToFibre setObject:[NSString stringWithFormat:@"%i",outputChannelIndex] forKey:fibreReference];
            }
        }
    }
    
    BOOL slaveMode,masterMode;
    NSString *operationMode = [NSString stringWithFormat:@"%@",[smellieSettings objectForKey:@"operation_mode"]];
    if([operationMode isEqualToString:@"Slave Mode"]){
        slaveMode = YES;
        masterMode = NO;
    }else if([operationMode isEqualToString:@"Master Mode"]){
        slaveMode = NO;
        masterMode = YES;
    }else{
        slaveMode = NO;
        masterMode = NO;
    }
    
    NSLog(@"SMELLIE_RUN:Running in %@\n",operationMode);
    NSLog(@"SMELLIE_RUN:Checking Connection to SMELLIE\n");
    NSLog(@"SMELLIE_RUN:Setting SMELLIE into Safe States before starting a Run\n");
    [self setSmellieSafeStates];
    
    //Extract the min intensity
    NSNumber * minLaserObj = [smellieSettings objectForKey:@"min_laser_intensity"];
    int minLaserIntensity = [minLaserObj intValue];
    
    //Extract the min intensity
    NSNumber * maxLaserObj = [smellieSettings objectForKey:@"max_laser_intensity"];
    int maxLaserIntensity = [maxLaserObj intValue];
    
    NSNumber * numOfIntensitySteps = [smellieSettings objectForKey:@"num_intensity_steps"];

    //Extract the lasers to be fired into an array
    NSMutableDictionary * laserArray = [[NSMutableDictionary alloc] init];
    [laserArray setObject:[smellieSettings objectForKey:@"375nm_laser_on"] forKey:@"375nm" ];
    [laserArray setObject:[smellieSettings objectForKey:@"405nm_laser_on"] forKey:@"405nm" ];
    [laserArray setObject:[smellieSettings objectForKey:@"440nm_laser_on"] forKey:@"440nm" ];
    [laserArray setObject:[smellieSettings objectForKey:@"500nm_laser_on"] forKey:@"500nm" ];
    
    //Extract the fibres to be fired into an array
    NSMutableDictionary *fibreArray = [[NSMutableDictionary alloc] init];
    [fibreArray setObject:[smellieSettings objectForKey:@"FS007"] forKey:@"FS007" ];
    [fibreArray setObject:[smellieSettings objectForKey:@"FS107"] forKey:@"FS107" ];
    [fibreArray setObject:[smellieSettings objectForKey:@"FS207"] forKey:@"FS207" ];
    [fibreArray setObject:[smellieSettings objectForKey:@"FS025"] forKey:@"FS025" ];
    [fibreArray setObject:[smellieSettings objectForKey:@"FS125"] forKey:@"FS125" ];
    [fibreArray setObject:[smellieSettings objectForKey:@"FS225"] forKey:@"FS225" ];
    [fibreArray setObject:[smellieSettings objectForKey:@"FS037"] forKey:@"FS037" ];
    [fibreArray setObject:[smellieSettings objectForKey:@"FS137"] forKey:@"FS137" ];
    [fibreArray setObject:[smellieSettings objectForKey:@"FS237"] forKey:@"FS237" ];
    [fibreArray setObject:[smellieSettings objectForKey:@"FS055"] forKey:@"FS055" ];
    [fibreArray setObject:[smellieSettings objectForKey:@"FS155"] forKey:@"FS155" ];
    [fibreArray setObject:[smellieSettings objectForKey:@"FS255"] forKey:@"FS255" ];
    
    smellieSubRunInfo = [[NSMutableArray alloc] initWithCapacity:100];
    NSString* numOfPulsesInSlaveMode = [NSString stringWithFormat:@"%@",[smellieSettings objectForKey:@"triggers_per_loop"]];
    NSString* triggerFrequencyInSlaveMode = [NSString stringWithFormat:@"%@",[smellieSettings objectForKey:@"trigger_frequency"]];
    
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    float timeToPulse = [[f numberFromString:numOfPulsesInSlaveMode] floatValue]/[[f numberFromString:triggerFrequencyInSlaveMode] floatValue];
    [f release];
    
    
    //get the MTC Object (but only use in Slave Mode)
    NSArray*  objsMTC = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* theMTCModel = [objsMTC objectAtIndex:0];
    [theMTCModel stopMTCPedestalsFixedRate]; //stop any pedestals that are currently running
    
    //get the run controller
    NSArray*  objs3 = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    runControl = [objs3 objectAtIndex:0];
    
    //Save the current settings of the detector
    NSMutableDictionary* tmpCurrentOrcaSettingsForSmellie  = [[NSMutableDictionary alloc] init];
    NSLog(@"SMELLIE_RUN:Mtcd coarse delay set to %f ns\n",[theMTCModel dbFloatByIndex:kCoarseDelay]);
    NSNumber * mtcCoarseDelay = [NSNumber numberWithUnsignedLong:[theMTCModel dbFloatByIndex:kCoarseDelay]];
    [tmpCurrentOrcaSettingsForSmellie setObject:mtcCoarseDelay forKey:@"mtcd_coarse_delay"];
    
    NSLog(@"SMELLIE_RUN:Mtcd pulser rate set to %f Hz\n",[theMTCModel dbFloatByIndex:kPulserPeriod]);
    NSNumber * mtcPulserPeriod = [NSNumber numberWithFloat:[theMTCModel dbFloatByIndex:kPulserPeriod]];
    [tmpCurrentOrcaSettingsForSmellie setObject:mtcPulserPeriod forKey:@"mtcd_pulser_period"];
    
    //Set property variable and delete tmpVar.
    self.currentOrcaSettingsForSmellie = tmpCurrentOrcaSettingsForSmellie;
    [tmpCurrentOrcaSettingsForSmellie release];
    
    //Set the Mtcd for smellie settings
    //NSLog(@"SMELLIE_RUN:Setting the mtcd coarse delay to 900ns \n",[[NSNumber numberWithUnsignedShort:900] unsignedShortValue]);
    //[theMTCModel setupGTCorseDelay:[[NSNumber numberWithInt:900] intValue]];
    
    if(![runControl isRunning]){
        //start the run controller
        [runControl performSelectorOnMainThread:@selector(startRun) withObject:nil waitUntilDone:YES];
    }else{
        //Stop the current run and start a new run 
        [runControl setForceRestart:YES];
        [runControl performSelectorOnMainThread:@selector(stopRun) withObject:nil waitUntilDone:YES];
        [runControl performSelectorOnMainThread:@selector(startRun) withObject:nil waitUntilDone:YES];
        //[runControl:@selector(stopRun) withObject:nil afterDelay:0];
    }
    
    //fire some pedestals but only in slave mode. The pedestals are used to trigger the SMELLIE lasers
    /*if(slaveMode){

        NSLog(@"SMELLIE_RUN:Setting the Pedestal to :%@ Hz \n",triggerFrequencyInSlaveMode);
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber * numericTriggerFrequencyInSlaveMode = [f numberFromString:triggerFrequencyInSlaveMode];
        [f release];
        
        NSLog(@"SMELLIE_RUN:Intensity:Firing Pedestals\n");
        [theMTCModel fireMTCPedestalsFixedRate];
        
        //We need to set the pulser rate after firing pedestals 
        float pulserRate = [numericTriggerFrequencyInSlaveMode floatValue];
        [theMTCModel setThePulserRate:pulserRate];
    }*/
    
    BOOL endOfRun = NO;
    int laserLoopInt = 0;
    for(id laserKey in laserArray){
        
        if(endOfRun == YES){
            break; //if the end of the run is reached then break the run loop
        }
        
        //Only loop through fibres that are included in the run
        if([[laserArray objectForKey:laserKey] intValue] != 1){
            continue;
        }
        
        //set the laser switch which corresponds to the laserHead mapping to Sepia
        NSLog(@"SMELLIE_RUN:Setting the Laser Switch to Channel:%@ which corresponds to the %@ Laser\n",[NSString stringWithFormat:@"%@",[laserHeadToSepiaMapping objectForKey:laserKey]],laserKey);
        [self setLaserSwitch:[NSString stringWithFormat:@"%@",[laserHeadToSepiaMapping objectForKey:laserKey]]];
        
        //set the gain Control
        NSLog(@"SMELLIE_RUN:Setting the gain control to: %i V\n",[[laserHeadToGainControlMapping objectForKey:laserKey] floatValue]);
        [self setGainControlWithGainVoltage:[NSString stringWithFormat:@"%@",[laserHeadToGainControlMapping objectForKey:laserKey]]];
        
        //Loop through each Fibre
        for(id fibreKey in fibreArray){
        
            if(endOfRun == YES){
                break;
            }
            
            //Only loop through fibres that are included in the run 
            if([[fibreArray objectForKey:fibreKey] intValue] != 1){
                continue;
            }
            
            //NSString *inputFibneSwitchChannel = [NSString stringWithFormat:@"%i",laserLoopInt+1];
            NSString *inputFibneSwitchChannel = [NSString stringWithFormat:@"%@",[laserToInputFibreMapping objectForKey:laserKey]];
            
            NSLog(@"SMELLIE_RUN:Setting the Fibre Switch to Input Channel:%@ from the %@ Laser and Output Channel %@\n",inputFibneSwitchChannel,laserKey,[NSString stringWithFormat:@"%@",[fibreSwitchOutputToFibre objectForKey:fibreKey]]);
            [self setFibreSwitch:inputFibneSwitchChannel withOutputChannel:[NSString stringWithFormat:@"%@",[fibreSwitchOutputToFibre objectForKey:fibreKey]]];
            [NSThread sleepForTimeInterval:1.0f];
            
            
            /* Check to see if the maximum intensity is the same as the minimum intensity */
            int increment;
            if(maxLaserIntensity != minLaserIntensity){
                increment = (maxLaserIntensity - minLaserIntensity)/[numOfIntensitySteps floatValue];
            }else{
                increment = 0;
            }
            //NSNumber *incrementInteger = [NSNUmber numberWithFloat:increment];
            
            //Loop through each intensity of a SMELLIE run
            int intensityLoopInt;
            for(intensityLoopInt = minLaserIntensity;intensityLoopInt <= maxLaserIntensity; intensityLoopInt = intensityLoopInt + increment){
                
                //if run control cancels the run
                /*if(![runControl isRunning]){
                    endOfRun = YES;
                    break;
                }*/
            
                if([[NSThread currentThread] isCancelled]){
                    endOfRun = YES;
                    break;
                }
                
                //start a new subrun
                [runControl performSelectorOnMainThread:@selector(prepareForNewSubRun) withObject:nil waitUntilDone:YES];
                [runControl performSelectorOnMainThread:@selector(startNewSubRun) withObject:nil waitUntilDone:YES];
                
                NSString * laserIntensityAsString = [NSString stringWithFormat:@"%i",intensityLoopInt];
                NSLog(@"SMELLIE_RUN:Setting the Laser Intensity to %@ \n",laserIntensityAsString);
                [self setLaserIntensity:laserIntensityAsString];
                [NSThread sleepForTimeInterval:1.0f];
                
                //this used to be 10.0,  Slave mode in Orca requires time (unknown reason)
                
                NSMutableDictionary *valuesToFillPerSubRun = [[NSMutableDictionary alloc] initWithCapacity:100];
                [valuesToFillPerSubRun setObject:laserKey forKey:@"laser"];
                [valuesToFillPerSubRun setObject:fibreKey forKey:@"fibre"];
                [valuesToFillPerSubRun setObject:[NSNumber numberWithInt:intensityLoopInt] forKey:@"intensity"];
                [valuesToFillPerSubRun setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];
                
                if(slaveMode){
                    [self setLaserSoftLockOff];
                    NSLog(@"SMELLIE_RUN:Setting the Pedestal to :%@ Hz \n",triggerFrequencyInSlaveMode);
                    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                    [f setNumberStyle:NSNumberFormatterDecimalStyle];
                    NSNumber * numericTriggerFrequencyInSlaveMode = [f numberFromString:triggerFrequencyInSlaveMode];
                    [f release];
                    
                    NSLog(@"SMELLIE_RUN:Intensity:Firing Pedestals\n");
                    [theMTCModel fireMTCPedestalsFixedRate];
                    
                    //We need to set the pulser rate after firing pedestals
                    float pulserRate = [numericTriggerFrequencyInSlaveMode floatValue];
                    [theMTCModel setThePulserRate:pulserRate];
                    
                }
                
                [NSThread sleepForTimeInterval:1.0f];
                if(masterMode){
                    NSString* numOfPulses = [NSString stringWithFormat:@"%@",[smellieSettings objectForKey:@"triggers_per_loop"]];
                    NSString* triggerFrequency = [NSString stringWithFormat:@"%@",[smellieSettings objectForKey:@"trigger_frequency"]];
                    NSLog(@"SMELLIE_RUN:%@ Pulses at %@ Hz \n",numOfPulses,triggerFrequency);
                    [self setSmellieMasterMode:triggerFrequency withNumOfPulses:numOfPulses];
                }
                
                if(slaveMode){
                    NSLog(@"SMELLIE_RUN: Pulsing at %f Hz for %f seconds \n",[triggerFrequencyInSlaveMode floatValue],timeToPulse);
                    //Wait a certain amount of time for slave Mode
                    [NSThread sleepForTimeInterval:timeToPulse];
                }
                
                [smellieSubRunInfo addObject:valuesToFillPerSubRun];
                [valuesToFillPerSubRun release];
                
                if(!endOfRun){
                    NSLog(@"Laser:%@ ", laserKey);
                    NSLog(@"Fibre:%@ ",fibreKey);
                    NSLog(@"Intensity:%i \n",intensityLoopInt);
                }
                
                //TODO:only have this in slave mode
                if(slaveMode){
                    NSLog(@"SMELLIE_RUN:Stopping MTCPedestals\n");
                    [theMTCModel stopMTCPedestalsFixedRate];
                    [self setLaserSoftLockOn];
                }
                
                [NSThread sleepForTimeInterval:1.0f];
                
            }//end of looping through each intensity setting on the smellie laser
            
        }//end of looping through each Fibre
        
        laserLoopInt = laserLoopInt + 1;
    }//end of looping through each laser
    
    //End the run
    
    //[smellieSubRun release];
    [fibreArray release];
    [laserArray release];
    
    //stop the pedestals if required 
    if(slaveMode){
        //NSLog(@"SMELLIE_RUN:Stopping MTCPedestals\n");
        [theMTCModel stopMTCPedestalsFixedRate];
    }
    
    //Resetting the mtcd to settings before the smellie run
    
    NSLog(@"SMELLIE_RUN:Returning SMELLIE into Safe States after finishing a Run\n");
    [self setSmellieSafeStates];
    
    //don't know if I need this??? called in stop smellie run ???
    //[runControl performSelectorOnMainThread:@selector(haltRun) withObject:nil waitUntilDone:YES];
    
    if(!endOfRun){
        [[NSNotificationCenter defaultCenter] postNotificationName:ORELLIERunFinished object:self];
    }
    
}

-(void)stopSmellieRun
{
    /*
     Some sign off / tidy up stuff to be called at the end of a smellie run. Again, I think this
     should be moved to a runscript.
    */
    //Even though this is stopping in Orca it can still contine on SNODROP!
    //Need a stop run command here
    //TODO: add a try and except statement here
    NSArray*  objsMTC = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* theMTCModel = [objsMTC objectAtIndex:0];
    
    //removed this to stop splurgingb
    NSArray*  objs3 = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    runControl = [objs3 objectAtIndex:0];
    
    //Set the Mtcd for back to original settings
    [theMTCModel setThePulserRate:[[currentOrcaSettingsForSmellie objectForKey:@"mtcd_pulser_period"] floatValue]];
    [theMTCModel enablePulser];
    NSLog(@"SMELLIE_RUN:Setting the mtcd pulser back to %f Hz\n",[[currentOrcaSettingsForSmellie objectForKey:@"mtcd_pulser_period"] floatValue]);
    [theMTCModel stopMTCPedestalsFixedRate];
    
    [theMTCModel setupGTCorseDelay:[[currentOrcaSettingsForSmellie objectForKey:@"mtcd_coarse_delay"] intValue]];
    NSLog(@"SMELLIE_RUN:Setting the mtcd coarse delay back to %i \n",[[currentOrcaSettingsForSmellie objectForKey:@"mtcd_coarse_delay"] intValue]);
    
    [self _pushSmellieRunDocument];
    
    [runControl setForceRestart:YES]; 
    [runControl performSelectorOnMainThread:@selector(stopRun) withObject:nil waitUntilDone:YES];
    [runControl performSelectorOnMainThread:@selector(startRun) withObject:nil waitUntilDone:YES];
    
    //Set the Run Type to a SMELLIE run
    /*NSArray*  objsSNOP = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    SNOPModel* theSNOPModel = [objsSNOP objectAtIndex:0];*/
    //add
    //[theSNOPModel setRunType:kRunMaintainence]; //sets the run_type to a smellie run type
    //used to be halt run but this now moves straight into a maintainence run 
    //end the run correctly if it is still running
    //[runControl haltRun];
    //TODO: Send stop smellie run notification 
    NSLog(@"SMELLIE_RUN:Stopping SMELLIE Run\n");
}


@end
