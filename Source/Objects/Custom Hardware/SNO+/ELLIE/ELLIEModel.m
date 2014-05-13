//
//  ELLIEModel.m
//  Orca
//
//  Created by Chris Jones on 01/04/2014.
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

//tags to define that an ELLIE run file has been updated
#define kSmellieRunDocumentAdded   @"kSmellieRunDocumentAdded"
#define kSmellieRunDocumentUpdated   @"kSmellieRunDocumentUpdated"
#define kTellieRunDocumentAdded   @"kTellieRunDocumentAdded"
#define kTellieRunDocumentUpdated   @"kTellieRunDocumentUpdated"
#define kAmellieRunDocumentAdded   @"kAmellieRunDocumentAdded"
#define kAmellieRunDocumentUpdated   @"kAmellieRunDocumentUpdated"
#define kSmellieRunHeaderRetrieved   @"kSmellieRunHeaderRetrieved"

//sub run information tags
#define kSmellieSubRunDocumentAdded @"kSmellieSubRunDocumentAdded"

NSString* ELLIEAllLasersChanged = @"ELLIEAllLasersChanged";
NSString* ELLIEAllFibresChanged = @"ELLIEAllFibresChanged";
NSString* smellieRunDocsPresent = @"smellieRunDocsPresent";
NSString* ORELLIERunFinished = @"ORELLIERunFinished";


@interface ELLIEModel (private)
-(void) _pushEllieCustomRunToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile;
-(NSString*) stringDateFromDate:(NSDate*)aDate;
-(void) _pushSmellieRunDocument;
@end

@implementation ELLIEModel

@synthesize smellieRunSettings;
@synthesize exampleTask;
@synthesize smellieRunHeaderDocList;
@synthesize smellieSubRunInfo;

- (void) setUpImage
{
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
    //[super registerNotificationObservers];
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    //we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    
    
}

- (ORCouchDB*) generalDBRef:(NSString*)aCouchDb
{
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    
    //Initialise the SNOPModel
    SNOPModel* aSnotModel = [objs objectAtIndex:0];
    
	return [ORCouchDB couchHost:[aSnotModel orcaDBIPAddress]
                           port:[aSnotModel orcaDBPort]
                       username:[aSnotModel orcaDBUserName]
                            pwd:[aSnotModel orcaDBPassword]
                       database:aCouchDb
                       delegate:aSnotModel];
}

//This calls a python script but can only take two command line arguments 
-(NSString*)callPythonScript:(NSString*)pythonScriptFilePath withCmdLineArgs:(NSArray*)commandLineArgs
{
    if([commandLineArgs count] != 3){
        NSLog(@"Three command line arguments are required!");
        return nil;
    }
    
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/python"]; // Tell the task to execute the ssh command
    [task setArguments: [NSArray arrayWithObjects: pythonScriptFilePath, [commandLineArgs objectAtIndex:0],[commandLineArgs objectAtIndex:1],[commandLineArgs objectAtIndex:2],nil]];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSFileHandle *file;
    file = [pipe fileHandleForReading]; // This file handle is a reference to the output of the ssh command
    
    @try{
        [task launch];
    }
    @catch (NSException *e) {
        NSLog(@"SMELLIE Connection Error: %@",e);
    }
    @finally {
        //do something here
    }
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *responseFromCmdLine;
    responseFromCmdLine = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]; // This string now contains the entire output of the ssh command.
    
    [task release];
    return [responseFromCmdLine autorelease];
}


//used to create the timestamp in the couchDB files 
- (NSString*) stringDateFromDate:(NSDate*)aDate
{
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
    strDate = nil;
    return [[result retain] autorelease];
}

//Push the information from the GUI into a couchDB database
-(void) _pushEllieCustomRunToDB:(NSString*)aCouchDBName runFiletoPush:(NSMutableDictionary*)customRunFile
{
    NSAutoreleasePool* runDocPool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:100];
    
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    
    //Initialise the SNOPModel
    SNOPModel* aSnotModel = [objs objectAtIndex:0];
    
    NSString* docType = [NSMutableString stringWithFormat:@"%@%@",aCouchDBName,@"_run"];
    
    NSLog(@"document_type: %@",docType);
    
    [runDocDict setObject:docType forKey:@"doc_type"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"time_stamp"];
    [runDocDict setObject:customRunFile forKey:@"run_info"];
            
    //self.runDocument = runDocDict;
    [[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:aCouchDBName] addDocument:runDocDict tag:kSmellieRunDocumentAdded];
    
    [runDocPool release];
}

-(void) _pushSmellieRunDocument
{
    NSAutoreleasePool* runDocPool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary* runDocDict = [NSMutableDictionary dictionaryWithCapacity:100];
    
    //Collect a series of objects from the SNOPModel
    NSArray*  objs = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];
    SNOPModel* aSnotModel = [objs objectAtIndex:0];
    
    NSArray*  objs3 = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    runControl = [objs3 objectAtIndex:0];
    
    NSString* docType = [NSMutableString stringWithFormat:@"smellie_run_information"];

    [runDocDict setObject:docType forKey:@"doc_type"];
    [runDocDict setObject:[self stringDateFromDate:nil] forKey:@"time_stamp"];
    [runDocDict setObject:[NSNumber numberWithInt:[runControl runNumber]] forKey:@"run_number"];
    [runDocDict setObject:smellieSubRunInfo forKey:@"sub_run_info"];
    
    //self.runDocument = runDocDict;
    [[aSnotModel orcaDbRefWithEntryDB:aSnotModel withDB:@"smellie"] addDocument:runDocDict tag:kSmellieSubRunDocumentAdded];
    
    [runDocPool release];
}

/*-(void) _pushSmellieConfigDocument
{
    NSAutoreleasePool *configDocPool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary *configDocDict = [NSMutableDictionary dictionaryWithCapacity:100];
    NSArray *objs = [[[NSApp delegate] document] collectConnectedObjectsOfClass:NSClassFromString(@"SNOPModel")];
    SNOPModel *aSnotModel  = [objs objectAtIndex:0];
    NSString * docType = @"smellie_config_doc";
    
    [configDocDict setObject:docType forKey:@"doc_type"];
    [configDocDict setObject:[self stringDateFromDate:nil] forKey:@"time_stamp"];
    
    //fill in information from the GUI
    
    //[[aSnotModel orcaDBConnectionHistor]]
    
    [configDocPool release];
}*/

-(void) smellieDBpush:(NSMutableDictionary*)dbDic
{
    [self _pushEllieCustomRunToDB:@"smellie" runFiletoPush:dbDic];
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp
{
	@synchronized(self){
		if([aResult isKindOfClass:[NSDictionary class]]){
			NSString* message = [aResult objectForKey:@"Message"];
			if(message){
				[aResult prettyPrint:@"CouchDB Message:"];
			}
            
            //Look through all of the possible tags for ellie couchDB results 
            
            //This is called when smellie run header is queried from CouchDB
            if ([aTag isEqualToString:kSmellieRunHeaderRetrieved])
            {
                NSLog(@"here\n");
                NSLog(@"Object: %@\n",aResult);
                NSLog(@"result: %@\n",[aResult objectForKey:@"run_name"]);
                //[self parseSmellieRunHeaderDoc:aResult];
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
        
		else {
			//no docs found 
		}
	}
}

-(void)startSmellieRunInBackground:(NSDictionary*)smellieSettings
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self performSelectorOnMainThread:@selector(startSmellieRun:) withObject:smellieSettings waitUntilDone:NO];
    [pool release];
    
}

//SMELLIE Control Functions
-(void)setSmellieSafeStates
{
    NSArray * setSafeStates = @[@"30",@"0",@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:setSafeStates];
}

-(void)setLaserSwitch:(NSString*)laserSwitchChannel
{
    NSArray * setLaserSwitchFlagAndArgument = @[@"2050",laserSwitchChannel,@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:setLaserSwitchFlagAndArgument];
}

-(void)setFibreSwitch:(NSString*)fibreSwitchInputChannel withOutputChannel:(NSString*)fibreSwitchOutputChannel
{
    NSString * argumentStringFS = [NSString stringWithFormat:@"%@s%@",fibreSwitchInputChannel,fibreSwitchOutputChannel];
    //NSLog(@"fibre switch argument %@",argumentStringFS);
    NSArray * setFibreSwitchFlagAndArgument = @[@"40",argumentStringFS,@"0"];
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:setFibreSwitchFlagAndArgument];
}

-(void)setLaserIntensity:(NSString*)laserIntensity
{
    NSArray * setLaserIntensityFlagAndArgument = @[@"50",laserIntensity,@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:setLaserIntensityFlagAndArgument];
}

-(void)setLaserSoftLockOn
{
    NSArray * softLockOnFlag = @[@"60",@"0",@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:softLockOnFlag];
}

-(void)setLaserSoftLockOff
{
    NSArray * softLockOffFlag = @[@"70",@"0",@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:softLockOffFlag];
}

-(void)setLaserFrequency20Mhz
{
    NSArray * frequencyTestingModeFlag = @[@"90",@"0",@"0"]; 
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:frequencyTestingModeFlag];
}

-(void)setSmellieMasterMode:(NSString*)triggerFrequency withNumOfPulses:(NSString*)numOfPulses
{
    NSString * argumentString = [NSString stringWithFormat:@"%@s%@",triggerFrequency,numOfPulses];
    NSArray * smellieMasterModeFlag = @[@"80",argumentString,@"0"]; //30 is the flag for setting smellie to its safe states
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:smellieMasterModeFlag];
}

-(void)sendCustomSmellieCmd:(NSString*)customCmd withArgument1:(NSString*)customArgument1 withArgument2:(NSString*)customArgument2
{
    //Make sure all the arguments default to a safe value if not specified
    if([customCmd isEqualToString:nil]){
        customCmd = @"0";
    }
    
    if([customArgument1 isEqualToString:nil] || [customArgument1 isEqualToString:@""]){
        customArgument1 = @"0";
    }
    
    if([customArgument2 isEqualToString:nil] || [customArgument2 isEqualToString:@""]){
        customArgument2 = @"0";
    }
        
    NSArray * smellieCustomCmd = @[customCmd,customArgument1,customArgument2];
    [self callPythonScript:@"/Users/snotdaq/Desktop/orca-python/smellie/smellieConnection.py" withCmdLineArgs:smellieCustomCmd];
    
}

-(void)testFunction
{
    NSArray*  objs3 = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    runControl = [objs3 objectAtIndex:0];
    
    [runControl performSelector:@selector(haltRun)withObject:nil afterDelay:.1];
    
    
}

-(void)startSmellieRun:(NSDictionary*)smellieSettings
{
    //Deconstruct runFile into indiviual subruns ------------------
    
    NSLog(@"Starting SMELLIE Run\n");
    
    NSLog(@"Checking Connection to SMELLIE\n");
    
    //NSLog(@"Output from connection check: %@",[self])
    
    NSLog(@"Setting SMELLIE into Safe States before starting a Run\n");
    //[self performSelector:@selector(setSmellieSafeStates) withObject:nil waitUntilDone:YES];
    [self setSmellieSafeStates];
    
    //Extract the number of intensity steps
    //NSNumber * numIntStepsObj = [smellieSettings objectForKey:@"num_intensity_steps"];
    //int numIntSteps = [numIntStepsObj intValue];
    
    //Extract the min intensity
    NSNumber * minLaserObj = [smellieSettings objectForKey:@"min_laser_intensity"];
    int minLaserIntensity = [minLaserObj intValue];
    
    //Extract the min intensity
    NSNumber * maxLaserObj = [smellieSettings objectForKey:@"max_laser_intensity"];
    int maxLaserIntensity = [maxLaserObj intValue];
    //NSLog(@"min laser intensity %i",minLaserIntensity);
    //NSLog(@"max laser intensity %i",maxLaserIntensity);
    
    //DO THE MAPPING HERE!!!!
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
    
    //get the MTC Object
    NSArray*  objsMTC = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* theMTCModel = [objsMTC objectAtIndex:0];
    
    //get the run controller
    NSArray*  objs3 = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    runControl = [objs3 objectAtIndex:0];

    [runControl performSelectorOnMainThread:@selector(startRun) withObject:nil waitUntilDone:YES];

    //fire some pedestals
    [theMTCModel fireMTCPedestalsFixedRate];
 
    BOOL endOfRun = NO;
    
    ///Loop through each Laser
    int laserLoopInt = 0;
    for(id laserKey in laserArray){
    //for(int laserLoopInt = 0;laserLoopInt < [laserArray count];laserLoopInt++){
        
        if(endOfRun == YES){
            break;
        }
        
        //NSLog(@"laser key: %@",laserKey);
        //Only loop through lasers that are included in the run 
        /*if([[laserArray objectAtIndex:laserLoopInt] intValue] != 1){
            continue;
        }*/
        
        //TODO:Read in the configuration Map
        
        //Only loop through fibres that are included in the run
        if([[laserArray objectForKey:laserKey] intValue] != 1){
            continue;
        }
        
        
        //NSLog(@"%@",[[laserArray objectAtIndex:laserLoopInt] key]);
        
        if([laserKey isEqual:@"375nm"]){
            continue;
            //Current unconnected for repair
            //[self performSelector:@selector(setLaserSwitch:) withObject:@"1" afterDelay:.1];
            //[self setLaserSwitch:@"1"]; //whichever channel the 375 is connected to
        }
        else if ([laserKey isEqual:@"405nm"]){
            //[self performSelectorOnMainThread:@selector(setLaserSwitch:) withObject:@"2" waitUntilDone:YES];
            //[self performSelector:@selector(setLaserSwitch:) withObject:@"2" afterDelay:.1];
            [self setLaserSwitch:@"2"]; //whichever channel the 405 is connected to
            
        }
        else if ([laserKey isEqual:@"440nm"]){
            //[self performSelectorOnMainThread:@selector(setLaserSwitch:) withObject:@"3" waitUntilDone:YES];
            //[self performSelector:@selector(setLaserSwitch:) withObject:@"3" afterDelay:.1];
            [self setLaserSwitch:@"3"]; //whichever channel the 440 is connected to
            //[NSThread sleepForTimeInterval:35.0f];
        }
        else if ([laserKey isEqual:@"500nm"]){
            //[self performSelector:@selector(setLaserSwitch:) onThread:[NSThread currentThread] withObject:@"4" waitUntilDone:YES modes:kCFRunLoopDefaultMode];
            //[self performSelectorOnMainThread:@selector(setLaserSwitch:) withObject:@"4" waitUntilDone:YES];
            //[self performSelector:@selector(setLaserSwitch:) withObject:@"4" afterDelay:.1];
            //[self performSelector:@selector(setLaserSwitch:) onThread:[NSThread currentThread] withObject:@"4" waitUntilDone:YES];
            
            [self setLaserSwitch:@"4"]; //whichever channel the 500 is connected to
            //[NSThread sleepForTimeInterval:35.0f];
            
        }
        else{
            NSLog(@"SMELLIE RUN:No laser selected for this iteration\n");
        }
        
        
        //REMOVE THIS LATER
        //[NSThread sleepForTimeInterval:1.0f];
        //[self setLaserFrequency20Mhz];
        //[NSThread sleepForTimeInterval:1.0f];
        
        //Loop through each Fibre
        for(id fibreKey in fibreArray){
        //for(int fibreLoopInt = 0; fibreLoopInt < [fibreArray count];fibreLoopInt++){
        
            if(endOfRun == YES){
                break;
            }
            
            //Only loop through fibres that are included in the run 
            if([[fibreArray objectForKey:fibreKey] intValue] != 1){
                continue;
            }
            
            //which laser is connected to which input channel
            //labelling on fibre switch is one above normal
            NSString *inputFibneSwitchChannel = [NSString stringWithFormat:@"%i",laserLoopInt+1];
            //NSLog(@"inputFibreSwitch :%@",inputFibneSwitchChannel);
            
            //For the moment always go through switch 5 (for the moment)
            [self setFibreSwitch:inputFibneSwitchChannel withOutputChannel:@"5"];
            [NSThread sleepForTimeInterval:1.0f];
            
            //NSArray *dataArray = [NSArray arrayWithObjects:inputFibneSwitchChannel,@"5",nil];
            //[self performSelector:@selector(setFibreSwitch:withOutputChannel:) withObject:dataArray afterDelay:.1];
            //[self performSelectorOnMainThread:@selector(setFibreSwitch:withOutputChannel:) withObject:dataArray waitUntilDone:YES];
            
            //Loop through each intensity of a SMELLIE run 
            for(int intensityLoopInt = minLaserIntensity;intensityLoopInt < maxLaserIntensity; intensityLoopInt++){
            
                //NSLog(@"intensity value %i",intensityLoopInt);
                //Start a new subrun
                //[theRunModel startNewSubRun];
                if([[NSThread currentThread] isCancelled]){
                    endOfRun = YES;
                    break;
                }
                
                //start a new subrun
                [runControl performSelectorOnMainThread:@selector(prepareForNewSubRun) withObject:nil waitUntilDone:YES];
                [runControl performSelectorOnMainThread:@selector(startNewSubRun) withObject:nil waitUntilDone:YES];
                
                NSString * laserIntensityAsString = [NSString stringWithFormat:@"%i",intensityLoopInt];
                [self setLaserIntensity:laserIntensityAsString];
                [NSThread sleepForTimeInterval:1.0f];
                
                //[self performSelector:@selector(setLaserSoftLockOff) withObject:nil afterDelay:.1];
                [self setLaserSoftLockOff];
                
                //[runControl performSelector:@selector(stopRun)withObject:nil afterDelay:.1];
                //TODO: Delay the thread for a certain amount of time depending on the mode (slave/master)
                [NSThread sleepForTimeInterval:10.0f];
                
                NSMutableDictionary *valuesToFillPerSubRun = [[NSMutableDictionary alloc] initWithCapacity:100];
                [valuesToFillPerSubRun setObject:laserKey forKey:@"laser"];
                [valuesToFillPerSubRun setObject:fibreKey forKey:@"fibre"];
                [valuesToFillPerSubRun setObject:[NSNumber numberWithInt:intensityLoopInt] forKey:@"intensity"];
                [valuesToFillPerSubRun setObject:[NSNumber numberWithInt:[runControl subRunNumber]] forKey:@"sub_run_number"];
                
                [smellieSubRunInfo addObject:valuesToFillPerSubRun];
                [valuesToFillPerSubRun release];
                
                //Call the smellie system here 
                NSLog(@" Laser:%@ ", laserKey);
                NSLog(@" Fibre:%@ ",fibreKey);
                NSLog(@" Intensity:%i \n",intensityLoopInt);
                //[self performSelector:@selector(setLaserSoftLockOn) withObject:nil afterDelay:.1];
                [self setLaserSoftLockOn];
                [NSThread sleepForTimeInterval:1.0f];
                
                
            }//end of looping through each intensity setting on the smellie laser
            
        }//end of looping through each Fibre
        
        laserLoopInt = laserLoopInt + 1;
    }//end of looping through each laser
    
    //End the run
    
    //[smellieSubRun release];
    [fibreArray release];
    [laserArray release];
    
    //[theMTCModel stopMTCPedestalsFixedRate];
    NSLog(@"Returning SMELLIE into Safe States after finishing a Run\n");
    [self setSmellieSafeStates];
    
    //don't know if I need this??? called in stop smellie run ???
    //[runControl performSelectorOnMainThread:@selector(haltRun) withObject:nil waitUntilDone:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORELLIERunFinished object:self];
    
}

-(void)stopSmellieRun
{
    //Even though this is stopping in Orca it can still contine on SNODROP!
    //Need a stop run command here
    //TODO: add a try and except statement here
    NSArray*  objsMTC = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* theMTCModel = [objsMTC objectAtIndex:0];
    [theMTCModel stopMTCPedestalsFixedRate];
    
    //removed this to stop splurgingb
    NSArray*  objs3 = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    runControl = [objs3 objectAtIndex:0];
    
    [self _pushSmellieRunDocument];
    
    [runControl performSelectorOnMainThread:@selector(haltRun) withObject:nil waitUntilDone:YES];
    
    //end the run correctly if it is still running
    
    
    //[runControl haltRun];
    //TODO: Send stop smellie run notification 
    NSLog(@"Stopping SMELLIE Run\n");
}


@end
