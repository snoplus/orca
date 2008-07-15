//--------------------------------------------------------------------------------
// Class:		HP4405AModel
// brief:		Oscilloscope data.
// Author:		J. A. Formaggio
// History:		2008-07-15 (jaf) - Original
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORGpibEnetModel.h"
#import "ORGpibDeviceModel.h"
#import "ORHP4405AModel.h"
#import "ORDataTypeAssigner.h"

@implementation ORHP4405AModel

NSString* ORHP4405ALock      = @"ORHP4405ALock";
NSString* ORHP4405AGpibLock  = @"ORHP4405AGpibLock";

#pragma mark ***initialization

//--------------------------------------------------------------------------------
/*!\method  init
 * \brief	Called first time class is initialized.  Used to set basic
 *			default values first time object is created.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) init
{
    self = [ super init ];

	[[self undoManager] disableUndoRegistration];

    mRunInProgress = false;

	[[self undoManager] enableUndoRegistration];

    return self;
}

//--------------------------------------------------------------------------------
/*!\method  dealloc
 * \brief	Deletes anything on the heap.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) dealloc
{
    short i;
    for ( i = 0; i < kMaxOscChnls; i++ ){
        [ mDataObj[ i ] release ];
    } 	

    [ super dealloc ];
}

//--------------------------------------------------------------------------------
/*!\method  setUpImage
 * \brief	Sets the image used by this device.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) setUpImage
{
    [ self setImage: [ NSImage imageNamed: @"HP4405ASpectralAnalyzer" ]];
}

//--------------------------------------------------------------------------------
/*!\method  makeMainController
 * \brief	Makes the controller object that interfaces between the GUI and
 *			this model.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) makeMainController
{
    [ self linkToController: @"ORHP4405AController" ];
}


#pragma mark ***Hardware - General
//--------------------------------------------------------------------------------
/*!\method  oscScopeId
 * \brief	get the scope id and set internal variable.
 * \return	Number indicating which kind of scope is present.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (short) oscScopeId
{
    mScopeVersion = 0;

    [ self getID ];

    if ( [ mIdentifier rangeOfString: @"4405" ].location != NSNotFound )
    {
        mID = ORHP4405A;
        mScopeType = 4405;
        mScopeVersion = ' ';
    }
    else
    {
        mID = ORHP4405A;
        mScopeType = 4405;
        mScopeVersion = ' '; 
    }
    
    return( mID );
}

//--------------------------------------------------------------------------------
/*!\method  doNothing
 * \brief	This is a place holder for empty commands
 * \error	None.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) doNothing
{
}


//--------------------------------------------------------------------------------
/*!\method  oscBusy
 * \brief	Check if the oscilloscope is busy executing a previous command
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (bool) oscBusy
{
	long	inr;
    char	theDataOsc[ 8 ];
    						
    // Write the command.
    long lengthReturn = [ mController writeReadDevice: mPrimaryAddress 
                                         command: @"OPC?"
                                            data: theDataOsc
                                       maxLength: 6 ];
                                   
    // Check the return value. If first bit is set in INR then have data from acquisition.
    if ( lengthReturn > 0 ) 
	{
		inr = [ self convertStringToLong: theDataOsc withLength: lengthReturn ];
		if ( inr & 0x0001 )
			return false;
		else
			return true;
//        if ( !strncmp( theDataOsc, "1", 1 ) ) 
//			return true;
//        else if ( !strncmp( theDataOsc, "0", 1 ) ) 
//			return false;
//        else 
//			return true;
    }
    else 
		return true;
}


//--------------------------------------------------------------------------------
/*!\method  oscResetOscilloscope
 * \brief	Tell the oscilloscope to reconfigure itself.  Then read in the
 *			new parameters into the model.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscResetOscilloscope
{
    NSTimeInterval t0;
    
    [ self writeToGPIBDevice: @"*CLS" ];
    [ self writeToGPIBDevice: @"*RST" ];
    t0 = [ NSDate timeIntervalSinceReferenceDate ];
    while ( [NSDate timeIntervalSinceReferenceDate ] - t0 < 15 );
    BOOL savedstate = [ self doFullInit ];
    [ self setDoFullInit: YES ];
    [ self oscSetStandardSettings ];
    [ self setDoFullInit: savedstate ];
}

//--------------------------------------------------------------------------------
/*!\method  oscSetDateTime
 * \brief	Set the date and time of the oscilloscope.
 * \param	aDateTime			- The date/time the oscilloscope will be set to.
 * \error	Raises error if command fails.
 * \note	1) See routine oscGetDateTime for description of date/time format.
 */
//--------------------------------------------------------------------------------
- (void) oscSetDateTime: (time_t) aDateTime
{
	char				sDateTime[ 30 ];
//	NSMutableString*	dateString;
//	NSMutableString*	timeString;
		
// Convert time to struct tm format.
	struct tm* timeStruct = localtime( &aDateTime );
	
// Build the time string
	sprintf( sDateTime, "%d,%d,%d,%d,%d,%d", timeStruct->tm_mday, timeStruct->tm_mon,
	         (timeStruct->tm_year + 1900), 
			 timeStruct->tm_hour, timeStruct->tm_min, timeStruct->tm_sec );	
	        
// Set date and time
    [ self writeToGPIBDevice: [ NSString stringWithFormat: @"SYST:DATE \"%s\"", sDateTime ]];
}

//--------------------------------------------------------------------------------
/*!\method  oscLockPanel
 * \brief	Lock or unlock the oscilloscope front controls.
 * \param	aFlag			- True - lock the panel otherwise unlock it.
 * \error	Raises error if command fails.
 * \note		
 */
//--------------------------------------------------------------------------------
- (void) oscLockPanel: (bool) aFlag
{
//    NSString*	command;
    
    if ( aFlag )
    {
//        command = @"DISPLAY OFF";
    }
    else{
//        command = @"DISPLAY ON";
    }
    
//    [ self writeToGPIBDevice: command ];
}

//-----------------------------------------------------------------------------
/*!\method  oscSendTextMessage
 * \brief 	Write message to screen of oscilloscope. 
 * \error	Raises error if command fails.
 * \note		
 */
//--------------------------------------------------------------------------------
- (void) oscSendTextMessage: (NSString*) aMsg
{
    [ self writeToGPIBDevice: [ NSString stringWithFormat: @"MESSAGE '%s'", [ aMsg cStringUsingEncoding:NSASCIIStringEncoding ]]];
}

//--------------------------------------------------------------------------------
/*!\method  oscSetQueryFormat
 * \brief	Determine the format the oscilloscope will use to return all queries
 * \param	aFormat			- The format to use.
 * \error	Raises error if command fails.
 * \note	1) Possible options for format are:
 *				kNoLabel - Return does not include label, just response.
 *				kShortLabel - Return includes abbreviated version of query command.
 *				kLongLabel - Return includes full query command.
 */
//--------------------------------------------------------------------------------
-(void) oscSetQueryFormat: (short) aFormat
{
    switch ( aFormat){
    
        case kNoLabel:
            [ self writeToGPIBDevice: @"COMM_HEADER OFF" ];
        break;
        
        case kShortLabel:
            [ self writeToGPIBDevice: @"FORM:DATA: INT,32" ];
        break;
    
        case kLongLabel:
            [ self writeToGPIBDevice: @"FORM:DATA: REAL,32" ];
        break;

        default:
            [ self writeToGPIBDevice: @"FORM:DATA: REAL,32" ];
        break;
    }

    NSLog( @"Agilent: Data query format sent to Agilent.\n" );
}

//--------------------------------------------------------------------------------
/*!\method  oscSetScreenDisplay
 * \brief	Turn the oscilloscope display on or off.
 * \param	aDisplayOn			- True - turn display on, otherwise turn it off.
 * \error	Raises error if command fails.
 * \note	Turning display off speeds up acquisition.	
 */
//--------------------------------------------------------------------------------
- (void) oscSetScreenDisplay: (bool) aDisplayOn
{
    NSString *command;
    if ( aDisplayOn ) 	
		command = @"DISP:ENAB 1";
    else 		
		command = @"DISP:ENAB 0";
		
    [ self writeToGPIBDevice: command ];
}

#pragma mark ***Hardware - Channel
//--------------------------------------------------------------------------------
/*!\method  oscGetChnlAcquire
 * \brief	Checks if channel has been turned on.
 * \param	aChnl				- The channel to check - 0 based.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscGetChnlAcquire: (short) aChnl
{
	NSString*   acquireOn;
    long		returnLength;		// Length of string returned by oscilloscope.
    
// Make sure that channel is valid
	if ( [ self checkChnlNum: aChnl ] )
	{
		returnLength = [ self writeReadGPIBDevice: [ NSString stringWithFormat: @"TRAC:DATA? TRACE%d?", aChnl + 1 ]
                                             data: mReturnData maxLength: kMaxGPIBReturn ];
        
		acquireOn = [ NSString stringWithCString: mReturnData ];
		if ( [ acquireOn rangeOfString: @"ON" 
								 options: NSBackwardsSearch ].location != NSNotFound )
        {
            [ self setChnlAcquire: aChnl setting: true ];
        }
        else
        {
            [ self setChnlAcquire: aChnl setting: false ];
        }
    }
}

//--------------------------------------------------------------------------------
/*!\method  oscSetChnlAcquire
 * \brief	Turns on or off a particular channel
 * \param	aChnl				- The channel to check - 0 based.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscSetChnlAcquire
{
    int i;
    for ( i = 0; i < kMaxOscChnls; i++ ) // Select channels on display
	{ 
        if ( [ self checkChnlNum: i ] )
		{
            if ( [ self chnlAcquire: i ] )
			{
                    [ self writeToGPIBDevice: [ NSString stringWithFormat: @"TRAC:DATA? TRACE%d ON", i + 1 ]];
            }
            else {
                [ self writeToGPIBDevice: [ NSString stringWithFormat: @"TRAC:DATA? TRACE%d OFF", i + 1 ]];
            }
        }
    }
}

//--------------------------------------------------------------------------------
/*!\method  oscGetChnlScale
 * \brief	Get the vertical scale for the specified channel.  Volts / division.
 * \param	aChnl				- The channel to check - 0 based.
 * \error	Raises error if command fails.
 * \note	
 */
//--------------------------------------------------------------------------------

//-----------------------------------------------------------------------------
/*!\method	oscGetWaveformRecordLength
 * \brief	Gets the record length of the waveform from the oscilloscope.  
 * \error	Raises error if command fails.
 * \note	1) Format of return from WAVEFORM_SETUP command is:
 *				SP,<sp>,NP,<np>,FP,<fp>,SN,<sn>
 *			   where
 *				SP - Sparsing parameter - each ith wave point is returned.
 *				NP - Number of wavepointers to return.
 *				FP - First data point returned. 0 is first data point in waveform.
 *				SN - Segment to return.
 */
//-----------------------------------------------------------------------------
- (void) oscGetWaveformRecordLength
{
	NSString*   waveformParams;
	NSString*   recordLengthStr;
    long		returnLength;
   
    returnLength = [ self writeReadGPIBDevice: @"WAVEFORM_SETUP?"
                                         data: mReturnData
                                    maxLength: kMaxGPIBReturn ];
									
// Have to parse the return
    if ( returnLength > 0 )
	{
		waveformParams = [ NSString stringWithCString: &mReturnData[ 0 ] ];
		NSArray* waveformValues = [ waveformParams componentsSeparatedByString: @"," ];
				
		recordLengthStr = [ waveformValues objectAtIndex: 3 ];		
		strcpy( &mReturnData[ 0 ], [ recordLengthStr cStringUsingEncoding:NSASCIIStringEncoding ] );

		[ self setWaveformLength: [ self convertStringToLong: mReturnData withLength: returnLength ]];;
	}
}


//--------------------------------------------------------------------------------
/*!\method  oscSetWaveformRecordLength
 * \brief	Sets the record length used to acquire the data.
 * \error	Raises error if command fails.
 * \note	The oscilloscope always acquires ORLCMaxRecSize internally.  If we acquire
 *			less then to acquire full display we have to acquire only a subset of
 *			the data points - the sparsing factor.  
 */
//--------------------------------------------------------------------------------
- (void) oscSetWaveformRecordLength
{
//	float captureInt;
//	float memoryUsed;
	long waveformLength;
	waveformLength = [ self waveformLength ];
//	captureInt = 10 * [ self horizontalScale ];
//	memoryUsed = captureInt / 1.25e-10 + 0.5;
//	printf( "Rec size 1 %f\n", memoryUsed );
//	if ( memoryUsed > ORLCMaxRecSize ) memoryUsed = ORLCMaxRecSize;
//	printf( "Rec size 2 %f\n", memoryUsed );
//	long sparsing = memoryUsed / [ self waveformLength ];
	long sparsing = 1;
	

	NSLog(@"Record length: %d Sparsing factor: %d  scale factor: %e\n", waveformLength, sparsing, [ self horizontalScale ] );
	[ self writeToGPIBDevice: [ NSString stringWithFormat: @"WAVEFORM_SETUP NP,%d,SP,%d", waveformLength, sparsing ]];
	//if ( waveformLength == 15000 ) waveformLength = 25000;	
	[ self writeToGPIBDevice: [ NSString stringWithFormat: @"MEMORY_SIZE %d", waveformLength ] ];
}

#pragma mark ***Hardware - Trigger
//--------------------------------------------------------------------------------
/*!\method  oscGetHeader
 * \brief	This routine gets the header data associated with the waveform from the oscilloscope.
 * \param	aDataObj			- Object holding data for scope.
 * \error	Raises error if command fails.
 * \note    See the object T754OscData.h which gives a complete breakdown of what is in the data header for a waveform.
 * \note   	This routine then calls the oscGetWaveform method to return the waveform.
 */
//--------------------------------------------------------------------------------
- (void) oscGetHeader
{
	static HP4405ADefHeaderStruct	headerInfo;
	char						*theHeader;
//	size_t						theLength;
	long						numBytes;
	short						i;

    NS_DURING
        if( [ self isConnected ] )
        {
            for ( i = 0; i < kMaxOscChnls; i++)
            {
                if ( mChannels[ i ].chnlAcquire )
                {
                    theHeader = [ mDataObj[ i ] rawHeader ];

                    // Send command to retrieve header information.
                    [ self writeToGPIBDevice:
                    [ NSString stringWithFormat: @"TRAC:DATA? TRACE%d?", i + 1 ]];

                    // Read header information
					[ mController readFromDevice: mPrimaryAddress data: (char*)&headerInfo maxLength: sizeof( headerInfo ) ];
                     numBytes = atoi( headerInfo.mDataLength );							// length of pulse in chnls	
//					 printf( "Header length: %d\n", numBytes );
					 					
                    memset( theHeader, 0, sizeof( struct HP4405AHeader ) );
                    [ self readFromGPIBDevice: theHeader maxLength: sizeof( struct HP4405AHeader ) ];
												
//					printf( "Header: %s\n", theHeader );
//					printf( "Channels: %d vGain %e\n", ((struct L950Header*)theHeader)->mWaveArrayCount,
//					        ((struct L950Header*)theHeader)->mVerticalGain );
                }
            }
        }
                
    NS_HANDLER
    NS_ENDHANDLER
}
			

//--------------------------------------------------------------------------------
/*!\method  oscGetWaveform
 * \brief	This routine gets the actual data from the oscilloscope.
 * \error	Raises error if command fails.
 * \note	1) The Tektronix does not use a communication header that is read in
 *             as one item.  Instead it has 3 pieces, where the first describes
 *            the second and the second describes the third.  The structure
 *            of this header is as follows.
 * 
 *            #<x><yyy...><data><newline>
 *            x: number of bytes in y
 *            y: number of data in data.
 */
//--------------------------------------------------------------------------------
- (void) oscGetWaveform: (unsigned short) aMask
{
	char*							theData;			// Temporary pointer to data storage location.
	static struct HP4405ADefHeader	headerInfo;
	int								i;
	long							numBytes;
//	long							j, l;

    NS_DURING
        if( [ self isConnected ] )
		{
                    
            // Read in all the data at once.
            for ( i = 0; i < kMaxOscChnls; i++ ) 
			{
                if ( mChannels[ i ].chnlAcquire && ( aMask & ( 1 << i ) ) ) 
				{
                    theData = [ mDataObj[ i ] createDataStorage ];

					// Issue command to read data for a single channel.
					[ mController writeToDevice: mPrimaryAddress command: [ NSString stringWithFormat: @"TRAC:DATA? TRACE%d?", i + 1 ]];
					
                    // Read header information
					[ mController readFromDevice: mPrimaryAddress data: (char*)&headerInfo maxLength: sizeof( headerInfo ) ];
                     numBytes = atoi( headerInfo.mDataLength );							// length of pulse in chnls	
					 NSLog(@"Waveform points: %d\n", numBytes );					
				
                    // read the actual data.
                    [ mDataObj[ i ] setActualWaveformSize: ( numBytes >= [ mDataObj[ i ] maxWaveformSize ] ) ? 
                                       [ mDataObj[ i ] maxWaveformSize ] : numBytes ];  // Read in the smaller size
                                       
                    [ mDataObj[ i ] setActualWaveformSize: [ mController readFromDevice: mPrimaryAddress 
                                                                                   data: theData 
                                                                              maxLength: [ mDataObj[ i ] actualWaveformSize ] ] ];
																			  
																			  
//					for ( j = 0; j < numBytes; j += 10 )
//					{
//						printf( "\nWave: %d -", j );
//						for ( l = 0; l < 10; l++ )
//							printf( " %d", theData[ j + l ] );
//					}
				}
            }
        }
        
// Bad connection so don't execute instruction
        else
        {
            NSString *errorMsg = @"Must establish GPIB connection prior to issuing command\n";
            [ NSException raise: OExceptionGPIBConnectionError format: errorMsg ];
        }
        
    NS_HANDLER
    NS_ENDHANDLER

}

//--------------------------------------------------------------------------------
/*!\method  oscGetWaveformTime
 * \brief	This routine gets the time associated with the waveform.
 * \error	Raises error if command fails.
 */
//--------------------------------------------------------------------------------
- (void) oscGetWaveformTime: (unsigned short) aMask
{
    unsigned long long	timeInSecs;
	char				*theTimeData;				// Temporary pointer to data storage location.
	char				timeRaw[ 64 ];
	bool				fNoTime = true;
    
// Initialize memory.
//    memset( &theTimeStr[ 0 ], '\0', 128 );
    
    theTimeData = [ mDataObj[ 0 ] createTimeStorage ];
                                    
// Get time from oscilloscope for last waveform.
    if ( mID == ORHP4405A )
    {
		unsigned short i = 0;
		while( fNoTime )
		{
			if ( mChannels[ i ].chnlAcquire && ( aMask & (1<<i) ) ) 
			{
				[ mController writeReadDevice: mPrimaryAddress 
                                      command: [ NSString stringWithFormat: @"C%d:INSPECT? 'TRIGGER_TIME'", i + 1 ]
                                         data: timeRaw
									maxLength: sizeof( timeRaw ) ];
        
				fNoTime = false; 
			}
			i++;
		}
    }
                                                                
// Convert the time
    [ self oscHP4405AConvertTime: &timeInSecs timeToConvert: &timeRaw[ 0 ] ];
    memcpy( theTimeData, &timeInSecs, 2*sizeof(long) );
}


//--------------------------------------------------------------------------------
/*!\method  oscRunOsc
 * \brief	Starts the oscilloscope up.
 * \param	aStartMsg			- A starting message to write out to the screen.
 * \error	Throws error if any command fails.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscRunOsc: (NSString*) aStartMsg
{
//    NSRange		range = { NSNotFound, 0 };
    
// Get scope ready.
    [ self clearStatusReg ];
    [ self oscScopeId ];
    
// Acquire data.  Places scope in single waveform acquisition mode.
	if ( mRunInProgress ){
	   // time_t	theTime;
	  //  struct tm	*theTimeGMTAsStruct;
	  //  time( &theTime );
	  //  theTimeGMTAsStruct = gmtime( &theTime );
	   // [ self oscSetDateTime: mktime( theTimeGMTAsStruct ) ];
	    [ self oscInitializeForDataTaking: aStartMsg ];
	    [ self oscArmScope ];
	}

// Place oscilloscope in free running mode.
	else{
	    [ self oscSetAcqMode: kNormalTrigger ];
//	    [ self writeToGPIBDevice: @"ACQUIRE:STATE RUN"];
	    [ self oscLockPanel: false ];
	}
}


//--------------------------------------------------------------------------------
/*!\method  oscSetAcqMode
 * \brief	Sets the acquisition mode for the oscilloscope. Either free running
 *			or one event at a time.
 * \param	aMode		- Either kNormalTrigger or kSingleWaveform.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscSetAcqMode: (short) aMode
{
    
	switch( aMode )
	{
		case kNormalTrigger:
			[ self setTriggerMode: kTriggerNormal ];
//			command = @"TRIG_MODE NORM";
			break;
		case kSingleWaveform:
			[ self setTriggerMode: kTriggerSingle ];
//			command = @"TRIG_MODE SINGLE";
			break;
	 	default:
			[ self setTriggerMode: kTriggerNormal ];
//			command = @"TRIG_MODE NORM";
	}
	
	[ self oscSetTriggerMode ];
//	[ self writeToGPIBDevice: command ];
}

//--------------------------------------------------------------------------------
/*!\method  oscSetDataReturnMode
 * \brief	Sets the parameters for how the data is retrieved from the oscilloscope
 * \note	
 */
//--------------------------------------------------------------------------------

//--------------------------------------------------------------------------------
/*!\method  oscStopAcquisition
 * \brief	Stops the oscilloscope from taking data.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) oscStopAcquisition
{
    [ self writeToGPIBDevice: @"ABOR"];
    NSLog( @"HP4405A: Data acquisition stopped.\n" );
}
		


#pragma mark ***DataTaker

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORHP4405ADecoderForScopeData",             @"decoder",
        [NSNumber numberWithLong:dataId],           @"dataId",
        [NSNumber numberWithBool:YES],              @"variable",
        [NSNumber numberWithLong:-1],               @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"ScopeData"];

    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORHP4405ADecoderForScopeGTID",             @"decoder",
        [NSNumber numberWithLong:gtidDataId],       @"dataId",
        [NSNumber numberWithBool:NO],               @"variable",
        [NSNumber numberWithLong:IsShortForm(gtidDataId)?1:2],   @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"ScopeGTID"];

   aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORHP4405ADecoderForScopeTime",             @"decoder",
        [NSNumber numberWithLong:clockDataId],      @"dataId",
        [NSNumber numberWithBool:NO],               @"variable",
        [NSNumber numberWithLong:3],   @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"ScopeTime"];

    return dataDictionary;
}

//--------------------------------------------------------------------------------
/*!\method  runTaskStarted
 * \brief	Beginning of run.  Prepare this object to take data.  Write out hardware settings
 *			to data stream.
 * \param	aDataPacket				- Object where data is written.
 * \param   anUserInfo				- Data from other objects that are needed by oscilloscope.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) runTaskStarted: (ORDataPacket*) aDataPacket userInfo: (id) anUserInfo
{
    short		i;
    bool		bRetVal = false;

// Call base class method that initializes _cancelled conditional lock.
    [ super runTaskStarted: aDataPacket userInfo: anUserInfo ];
    
// Handle case where device is not connected.
    if( ![ self isConnected ] ){
	    [ NSException raise: @"Not Connected" format: @"You must connect to a GPIB Controller." ];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORHP4405AModel"]; 


                                                                                
// Get the controller so that it is cached
    bRetVal = [ self cacheTheController ];
    if ( !bRetVal )
    {
        [ NSException raise: @"Not connected" format: @"Could not cache the controller." ];
    }
    
// Initialize the scope correctly.
    firstEvent = YES;
    
// Set up memory structures for data
    for ( i = 0; i < kMaxOscChnls; i++ )
    {
        mDataObj[ i ] = [[ ORHP4405AData alloc ] initWithWaveformModel: self channel: i ];
    } 
    
// Start the oscilloscope
    NSNumber* initValue = [ anUserInfo objectForKey: @"doinit" ];
    if ( initValue ) [ self setDoFullInit: [ initValue intValue ]];
    else [ self setDoFullInit: YES ];

// Initialize the oscilloscope settings and start acquisition using a run configuration.
    mRunInProgress = true;
	[ self oscSetStandardSettings ];	
}

//--------------------------------------------------------------------------------
/*!\method  takeDataTask
 * \brief	Thread that is repeatedly called to actually acquire the data. 
 * \param	anUserInfo				- Dictionary holding information from
 *										outside this task that is needed by
 *										this task.
 * \note	first 32 bits data		- 5 bits data type - deviceIndex -> deviceType	
 *									  4 bits oscilloscope number
 *									  4 bits channel
 *									  3 bits spare
 *									 16 bits size of following waveform
 * \note	first 32 bits time		- 5 bits data type - deviceIndex -> deviceType
 *									  3 bits channel number
 *									 24 bits high portion of time.
 * \history	2003-11-12 (jmw)	- Fixed output record when multiple channels fire.
 *								  Only one GTID written at beginning of record.
 */
//--------------------------------------------------------------------------------
- (void) 	takeDataTask: (id) notUsed 
{
	ORDataPacket* aDataPacket = nil;
    do {
        
        mDataThreadRunning = YES;
        
		[_okToGo lockWhenCondition:YES];
    
		// -- Do some basic initialization prior to acquiring data ------------------
		// Threads are responsible to manage their own autorelease pools
		NSAutoreleasePool *thePool = [[ NSAutoreleasePool alloc ] init ];
		
		BOOL processedAnEvent = NO;
		BOOL readOutError      = NO;

		//extract the data packet to use.
		if(aDataPacket)[aDataPacket release];
		aDataPacket 	= [ threadParams objectForKey: @"ThreadData" ];

		// Set which channels to read based on the mask - If not available read all channels.
		unsigned char mask;
		NSNumber* theMask = [ threadParams objectForKey: @"ChannelMask" ];
		if ( theMask ) 
			mask  = [ theMask charValue ];
		else 
			mask = 0xff;

		// Get the GTID
		NSNumber* gtidNumber    = [ threadParams objectForKey: @"GTID" ];
		NSTimeInterval t0       = [ NSDate timeIntervalSinceReferenceDate ];
		NSString* errorLocation = @"?"; // Used to determine at what point code stops if it stops.
		
	// -- Basic loop that reads the data -----------------------------------
		while ( ![self cancelled])
		{   
			// If we are not in standalone mode then gtid will be set.
			// In that case break out of this loop in a reasonable amount of time.
			if( gtidNumber && ( [ NSDate timeIntervalSinceReferenceDate ] - t0 > 1.0 ) )
			{
				NSLogError( @"", @"Scope Error", [ NSString stringWithFormat: @"Thread timeout, no data for scope (%d)", 
							[ self primaryAddress ]], nil );
					readOutError = YES;
				break;
			}
		
			// Start section that reads data.
			NS_DURING
				short i;
				
				// Scope is not busy so read it out
				errorLocation = @"oscBusy";
			   if ( ![ self oscBusy ] )
			   {

					// Read the header only for the first event.  We assume that scope settings will not change.
					if ( firstEvent ) 
					{
						//set the channel mask temporarily to read the headers for all channels.
	//                    errorLocation = @"oscSetWaveformAcq";
	//                    [ self oscSetWaveformAcq: 0xff ];
						errorLocation = @"oscGetHeader";
						[ self oscGetHeader ];
						
						for ( i = 0; i<kMaxOscChnls; i++ ){
							if ( mChannels[ i ].chnlAcquire ) [ mDataObj[ i ] convertHeader ];
						}
					}
							
					// Get data
					errorLocation = @"oscGetWaveform";
					[ self oscGetWaveform: mask ];			// Get the actual waveform data.
					
					errorLocation = @"oscGetWaveformTime";
					[ self oscGetWaveformTime: mask ];		// Get the time.
					
				   // Rearm the oscilloscope.
				   // [self clearStatusReg];
					errorLocation = @"oscArmScope";
					[ self oscArmScope ];   
				   
					// Place data in array where other parts of ORCA can grab it.
					for ( i = 0; i < kMaxOscChnls; i++ )
					{
						if ( mChannels[ i ].chnlAcquire && ( mask & ( 1 << i ) ))
						{
							[ mDataObj[ i ] setGtid: gtidNumber ? [ gtidNumber longValue ] : 0 ];
				
							//Note only mDataObj[ 0 ] has the timeData.
							NSData* theTimeData = [ mDataObj[ 0 ] timePacketData: aDataPacket channel: i ];
										
							//note that the gtid is shipped only with the first data set.
							[ mDataObj[ i ] setDataPacketData: aDataPacket timeData: theTimeData includeGTID: !processedAnEvent ];
							processedAnEvent = YES;                    
                            [self incEventCount:i];                   
						}
					}
				}
				
				// Oscilloscope was busy - Loop for a short while and then try again.
				else 
				{
					NSTimeInterval t1 = [ NSDate timeIntervalSinceReferenceDate ];
					while([ NSDate timeIntervalSinceReferenceDate ] - t1 < .1 );
				}
			
			NS_HANDLER
				readOutError = YES;
			NS_ENDHANDLER
			
			// Indicate that we have processed our first event.
			if( processedAnEvent )
				firstEvent = NO;
		
			// If we have the data or encountered an error break out of while.
			if( processedAnEvent || readOutError )
				break;
		}

	// -- Handle any errors encountered during read -------------------------------
		if( readOutError )
		{
			NSLogError( @"", @"Scope Error", [ NSString stringWithFormat: @"Exception: %@ (%d)", 
											   errorLocation, [ self primaryAddress ] ], nil );

			//we must rearm the scope. Since there was an error we will try a rearm again just to be sure.
			int errorCount = 0;
			while( 1 )
			{
				NS_DURING
					[ self clearStatusReg ];
					[ self oscArmScope ];
				NS_HANDLER
					errorCount++;
				NS_ENDHANDLER
				
				if( errorCount == 0 ) 
					break;
				else if( errorCount > 2 ) {
					NSLogError( @"", @"Scope Error", [NSString stringWithFormat: @"Rearm failed (%d)", [ self primaryAddress ] ], nil );
					break;
				}
			}
		}

		if(aDataPacket)[aDataPacket release];
		aDataPacket = nil;
		
		[_okToGo unlockWithCondition:NO];
		[ thePool release ];
		
	} while(![self cancelled]);
    mDataThreadRunning = NO;
	
    // Exit this thread
    [ NSThread exit ];
}

//--------------------------------------------------------------------------------
/*!\method  runInProgress
 * \brief	Informs calling routine whether task is running.
 * \return	True - task is running.				
 * \note	
 */
//--------------------------------------------------------------------------------
- (BOOL) runInProgress
{
    return mDataThreadRunning && [_okToGo condition];
}



//--------------------------------------------------------------------------------
/*!\method  runTaskStopped
 * \brief	Resets the oscilloscope so that it is in continuous acquisition mode.
 * \param	aDataPacket			- Data from most recent event.
 * \param   anUserInfo			- Data from other objects that are needed by oscilloscope.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) runTaskStopped: (ORDataPacket*) aDataPacket userInfo: (id) anUserInfo
{
    short i;
    
// Cancel the task.
    [ super runTaskStopped: aDataPacket userInfo: anUserInfo ];
        	   
// Stop running and place oscilloscope in free running mode.
    mRunInProgress = false;
    [ self oscRunOsc: nil ];
    
    
// Release memory structures used for data taking
    for ( i = 0; i < kMaxOscChnls; i++ )
    {
        [ mDataObj[ i ] release ];
        mDataObj[ i ] = nil;
    } 	
}

#pragma mark ¥¥¥Archival
//--------------------------------------------------------------------------------
/*!\method  initWithCoder  
 * \brief	Initialize object using archived settings.
 * \param	aDecoder			- Object used for getting archived internal parameters.
 * \note	
 */
//--------------------------------------------------------------------------------
- (id) initWithCoder: (NSCoder*) aDecoder
{
    self = [ super initWithCoder: aDecoder ];

    [[ self undoManager ] disableUndoRegistration ];
    
    [[ self undoManager ] enableUndoRegistration];
    return self;
}

//--------------------------------------------------------------------------------
/*!\method  encodeWithCoder  
 * \brief	Save the internal settings to the archive.  OscBase saves most
 *			of the settings.
 * \param	anEncoder			- Object used for encoding.
 * \note	
 */
//--------------------------------------------------------------------------------
- (void) encodeWithCoder: (NSCoder*) anEncoder
{
    [ super encodeWithCoder: anEncoder ];
}

#pragma mark ***Support

//--------------------------------------------------------------------------------
/*!\method  oscHP4405AConvertTime  
 * \brief	Convert the LeCroy time to an equivalent 10MHz clock starting at
 *			1/1/1970.
 * \param	a10MHzTime			- long long that stores 10 MHz time.
 * \param	aCharTime			- Tektronix time.
 * \note	Time is returned as follows:
 *				"TRIGGER_TIME       : Date = MAY 27, 2004, Time = 11:22:25.1401"
 */
//--------------------------------------------------------------------------------
- (void) oscHP4405AConvertTime: (unsigned long long*) a10MHzTime timeToConvert: (char*) aCharTime
{
    const char*					stdMonths[] = { "JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", 
                                                "OCT", "NOV", "DEC" };
    struct tm					unixTime;
//    struct tm*					tmpStruct;
    unsigned long				baseTime;
	unsigned long long			fracSecs;
    const unsigned long long	mult = 10000000;
	const unsigned long long	mult1 = 1000;
//    char*						dateString;
	short						i;
	
	NSCharacterSet* equalSet = [ NSCharacterSet characterSetWithCharactersInString: @"=" ];
	NSCharacterSet* spaceSet = [ NSCharacterSet characterSetWithCharactersInString: @" " ];
	NSCharacterSet* commaSet = [ NSCharacterSet characterSetWithCharactersInString: @"," ];
	
// Set date/time reference to Greenwich time zone - no daylight savings time.
    unixTime.tm_isdst = 0;
    unixTime.tm_gmtoff = 0;
	
//	printf( "Raw time: %s\n", aCharTime );

// Get the month
	for ( i = 0; i < 12; i++ )
    {
        if ( strstr( aCharTime, stdMonths[ i ] ) )
        {
            unixTime.tm_mon = i;
            break;
        }
    }

    NSString* dateAsString = [ NSString stringWithFormat: @"%s", aCharTime ];
	NSScanner* scanner = [ NSScanner scannerWithString: dateAsString ];

// Get date
	NSString*   tmpString;
	[ scanner scanUpToCharactersFromSet: equalSet intoString: nil ]; // find =
	[ scanner setScanLocation: [ scanner scanLocation ] +2 ];		
	[ scanner scanUpToCharactersFromSet: spaceSet intoString: nil ];  // find space
	[ scanner setScanLocation: [ scanner scanLocation ] +1 ];
	if ( [ scanner scanUpToCharactersFromSet: commaSet intoString: &tmpString ] )
	{
		unixTime.tm_mday = [ tmpString intValue ];
	}
	
// Get year
	[ scanner setScanLocation: [ scanner scanLocation ] +2 ];
	[ scanner scanInt: &(unixTime.tm_year) ];
	unixTime.tm_year -= 1900;
	
// Get time
	[ scanner scanUpToCharactersFromSet: equalSet intoString: nil ]; // find =
	[ scanner setScanLocation: [ scanner scanLocation ] +2 ];	
	[ scanner scanInt: &(unixTime.tm_hour) ];	

	[ scanner setScanLocation: [ scanner scanLocation ] +1 ];		
	[ scanner scanInt: &(unixTime.tm_min) ];	
	
	[ scanner setScanLocation: [ scanner scanLocation ] +1 ];		
	[ scanner scanInt: &(unixTime.tm_sec) ];	
	
	[ scanner setScanLocation: [ scanner scanLocation ] +1 ];
	int fracSecsInt;
	[ scanner scanInt: &fracSecsInt ];
	
// convert fractions seconds to MHz.
	fracSecs = ( unsigned long long )(fracSecsInt * mult1);
	
//	printf( "Fraction: %d\n", fracSecsInt );	
//	printf( "Year: %d, mon: %d, day %d\n", unixTime.tm_year, unixTime.tm_mon, unixTime.tm_mday );
//	printf( "Hour: %d, min: %d, sec %d\n", unixTime.tm_hour, unixTime.tm_min, unixTime.tm_sec );
	    
// Get base time in seconds
    baseTime = timegm( &unixTime ); // Have to use timegm because mktime forces the time to
                                    // local time and then does conversion to gmtime    
                          
// Convert to 10 Mhz Clock
    *a10MHzTime = (unsigned long long)baseTime * mult + fracSecs;
//	printf( "HP4405A - converted: %lld\n", *a10MHzTime );	
}
@end

@implementation ORHP4405ADecoderForScopeData
//just use the base class decodedata
@end

@implementation ORHP4405ADecoderForScopeGTID
- (unsigned long) decodeData: (void*) aSomeData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet: (ORDataSet*) aDataSet
{
    return [self decodeGtId:aSomeData fromDataPacket:aDataPacket intoDataSet:aDataSet];
} 
- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    return [self dataGtIdDescription:ptr];
}
@end

@implementation ORHP4405ADecoderForScopeTime
- (unsigned long) decodeData: (void*) aSomeData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet: (ORDataSet*) aDataSet
{
    return [self decodeClock:aSomeData fromDataPacket:aDataPacket intoDataSet:aDataSet];
} 
- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    return [self dataClockDescription:ptr];
}
@end














