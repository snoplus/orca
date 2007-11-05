//--------------------------------------------------------------------------------
// Class:	ORGpibEnetModel
// Notes:	ibsta - Global provided by NI library indicating status of all commands.
//			iberr - Global, If ibsta & ERR then iberr contains detailed error information.
//			ibctnl - Global containing number of bytes read or written.
// History:	2003-02-15 (jmw)
// Author:	Jan M. Wouters
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
#pragma mark ***Imported Files
#include <NI488/ni488.h>
#include <stdio.h>

#include "ORGpibEnetModel.h"
#include "StatusLog.h"

#pragma mark ***Defines
static NSString *mBoardNames[ kNumBoards ] = {
    @"GPIB0",
    @"GPIB1"
};

static NSString*	ORGpibEnetConnection		= @"GPIB Enet Connector";
NSString*			ORGpibEnetTestLock			= @"ORGpibEnetTestLock";

NSString*			ORGpibMonitorNotification   = @"ORGpibMonitorNotification";
NSString*			ORGpibMonitor				= @"ORGpibMonitor";
NSString*			ORGPIBBoardChangedNotification = @"ORGpibBoardChangedNotification";

@implementation ORGpibEnetModel
#pragma mark ***Initialization
//--------------------------------------------------------------------------------
/*! \method		commonInit
*  \brief		Initializes error message with blank string.  Sets all devices
*				to not initialized.
*	\note		This class uses two arrays to keep track of which GPIB devices
*				are initialized.
*/
//--------------------------------------------------------------------------------
- (void) commonInit
{
    short 	i;
    
	theHWLock = [[NSRecursiveLock alloc] init];    
    
    mErrorMsg = [[ NSMutableString alloc ] initWithFormat: @"" ];
    
    for ( i = 0; i < kMaxGpibAddresses; i++ )
    {
        mDeviceUnit[ i ] = kNotInitialized;
        mDeviceSecondaryAddress[ i ] = 0;
    } 
    
    [ self setBoardIndex: kDefaultGpibPort ];
    
}

//--------------------------------------------------------------------------------
/*! \method		init
*	\note		
*/
//--------------------------------------------------------------------------------
- (id) init
{
    self = [ super init];
    
    [ self commonInit ];
    
    return self;   
}


//--------------------------------------------------------------------------------
/*! \method		dealloc
*  \brief		Deallocs the error message string.
*	\note		
*/
//--------------------------------------------------------------------------------
- (void) dealloc
{
    [theHWLock release];
    [ mErrorMsg release ];
    [ super dealloc ];
}

//--------------------------------------------------------------------------------
/*! \method		setUpImage
*  \brief		Draws image on screen for this object.
*	\note		
*/
//--------------------------------------------------------------------------------
- (void) setUpImage
{
    [ self setImage: [NSImage imageNamed: @"GpibEnetBox" ]];
}

//--------------------------------------------------------------------------------
/*! \method		makeConnectors
*  \brief		Draws the connectors for the object so that one can connect
*				GPIB objects to the controller.
*	\note		
*/
//--------------------------------------------------------------------------------
- (void) makeConnectors
{
	ORConnector* connectorObj = [[ ORConnector alloc ] 
                                initAt: NSMakePoint( [ self x ] + [ self frame ].size.width 
                                                     - kConnectorSize, [ self y ] )
                            withGuardian: self];
	[ connectorObj setConnectorType: 'GPI2' ];
	[ connectorObj addRestrictedConnectionType: 'GPI1' ]; //can only connect to gpib inputs
	[[ self connectors ] setObject: connectorObj forKey: ORGpibEnetConnection ];
	[ connectorObj release ];
}

//--------------------------------------------------------------------------------
/*! \method		makeMainController
*  \brief		Makes the controller object used to control this object from
*				the user interface.
*	\note		
*/
//--------------------------------------------------------------------------------
- (void) makeMainController
{
    [self linkToController: @"ORGpibEnetController"];
}


#pragma mark ***Accessors
- (short) boardIndex
{
    return( mBoardIndex );
}


//--------------------------------------------------------------------------------
/*! \method		setBoardIndex
*  \brief		Sets the board index and sends notification about change.
*	\note		
*/
//--------------------------------------------------------------------------------
- (void) setBoardIndex: (short) anIndex
{
    mBoardIndex = anIndex;
	
	[[ NSNotificationCenter defaultCenter ]
		postNotificationName: ORGPIBBoardChangedNotification
		              object: self];
}


- (NSMutableString*) errorMsg
{
    return( mErrorMsg );
}

- (int) ibsta
{
    return( ibsta );
}

- (int) iberr
{
    return( iberr );
}

- (long) ibcntl
{
    return( ibcntl );
}


#pragma mark ***Basic commands
//--------------------------------------------------------------------------------
/*! \method		changePrimaryAddress
*  \brief		Change the primary GPIB address of the device.
*  \param		anOldPrimaryAddress		- The original primary address of the device.
*	\param		aNewPrimaryAddress		- The new primary address
*	\return		True if reset of address is successful.
*	\note		
*/
//--------------------------------------------------------------------------------
- (void) changePrimaryAddress: (short) anOldPrimaryAddress newAddress: (short) aNewPrimaryAddress
{
    // Make sure that device is initialized and that new address is valid.
    
    NS_DURING
        [theHWLock lock];   //-----begin critical section
        [ self checkDeviceThrow: anOldPrimaryAddress ];
        [ self checkDeviceThrow: aNewPrimaryAddress checkSetup: false ];
        
        ibpad( mDeviceUnit[ anOldPrimaryAddress ], aNewPrimaryAddress );
        if ( ibsta & ERR ) {
            [ mErrorMsg setString: @"***Error: ibpad" ];
            [ self GpibError: mErrorMsg ];
            
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        } 
        [theHWLock unlock];   //-----end critical section
    NS_HANDLER
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    NS_ENDHANDLER
}


- (void) changeState: (short) aPrimaryAddress online: (BOOL) aState
    //--------------------------------------------------------------------------------
    /*" Places the device either on or offline.
    _{#aPrimaryAddress	- The primary address for the GPIB device.}
    _{#aState			- True - place board online otherwise place it offline.}
    _{#Error			- Raises exception if low level call fails.}
    "*/
    //--------------------------------------------------------------------------------
{
    NS_DURING
        [theHWLock lock];   //-----begin critical section
        short deviceState = 0;
        
        // Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Change device state.
        if ( aState ) deviceState = 1;
        ibonl( mDeviceUnit[ aPrimaryAddress ], deviceState );
        if ( ibsta & ERR ) {
            [ mErrorMsg setString:  @"***Error: ibonl" ];
            [ self GpibError: mErrorMsg ];
            
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        }
        [theHWLock unlock];   //-----end critical section
    NS_HANDLER
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    NS_ENDHANDLER
    
}


//--------------------------------------------------------------------------------
/*! \method		checkAddress
*  \brief		Returns true if device at specified address is initialized.
*	\param		aPrimaryAddress		- Primary address of the device.
*	\note		
*/
//--------------------------------------------------------------------------------
- (BOOL) checkAddress: (short) aPrimaryAddress
{
    BOOL  bRetVal = false;
    
    NS_DURING
        [theHWLock lock];   //-----begin critical section
        
        // Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress checkSetup: false ];
        
        // Check if device has been setup.
        if ( mDeviceUnit[ aPrimaryAddress ] > kNotInitialized ){
            bRetVal = true;
        }
        [theHWLock unlock];   //-----end critical section
    NS_HANDLER
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    NS_ENDHANDLER
    
    return( bRetVal );    
}


//--------------------------------------------------------------------------------
/*! \method		deactivateAddress
*  \brief		Deactivates the device.
*	\param		aPrimaryAddress		- Primary address of the device.
*	\note		
*/
//--------------------------------------------------------------------------------
- (void) deactivateAddress: (short) aPrimaryAddress
{
    NS_DURING
        [ theHWLock lock ];   //-----begin critical section
                              // Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Deactivate the device
        ibonl( mDeviceUnit[ aPrimaryAddress ], 0 );
        if ( ibsta & ERR )
        {
            [ mErrorMsg setString: @"***Error: ibonl (deactivate)" ];
            [ self GpibError: mErrorMsg ];
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        }    
        [ theHWLock unlock ];   //-----end critical section
    NS_HANDLER
        [ theHWLock unlock ];   //-----end critical section
        [ localException raise ];
    NS_ENDHANDLER
    
}

- (void) enableEOT:(short)aPrimaryAddress state: (BOOL) state
{
    // Make sure that device is initialized.
    NS_DURING
        [ theHWLock lock ];   //-----begin critical section
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        ibeot( mDeviceUnit[ aPrimaryAddress ], state );
        if ( ibsta & ERR ){
            [ mErrorMsg setString: [NSString stringWithFormat:@"***Error: ibeot (%d)",state] ];
            [ self GpibError: mErrorMsg ];
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        } 
        [ theHWLock unlock ];   //-----end critical section
    NS_HANDLER
        [ theHWLock unlock ];   //-----end critical section
        [ localException raise ];
    NS_ENDHANDLER
    
}



- (void) resetDevice: (short) aPrimaryAddress
    //--------------------------------------------------------------------------------
    /*" Reset the device to start receiving data.
    _{#aPrimaryAddress	- The primary address for the GPIB device.}
    "*/
    //--------------------------------------------------------------------------------
{
    NS_DURING
        [theHWLock lock];   //-----begin critical section
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Clear device.
        ibclr( mDeviceUnit[ aPrimaryAddress ] );
        if ( ibsta & ERR ) {
            [ mErrorMsg setString: @"***Error: ibclr" ];
            [ self GpibError: mErrorMsg ];
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        }
        [ theHWLock unlock ];   //-----end critical section
    NS_HANDLER
        [ theHWLock unlock ];   //-----end critical section
        [ localException raise ];
    NS_ENDHANDLER
    
}

//--------------------------------------------------------------------------------
/*!\method: setGPIBMonitorRead
* \brief   Turn on and off monitoring of GPIB commands.
* \param   aMonitor			- True - turn on monitor.
*								  False - turn off monitor.
*/
//--------------------------------------------------------------------------------
- (void) setGPIBMonitorRead: (bool) aMonitorRead
{
	mMonitorRead = aMonitorRead;
}
//--------------------------------------------------------------------------------
/*!\method: setGPIBMonitorWrite
* \brief   Turn on and off monitoring of read data.
* \param   aMonitor			- True - turn on monitor.
*								  False - turn off monitor.
*/
//--------------------------------------------------------------------------------
- (void) setGPIBMonitorWrite: (bool) aMonitorWrite
{
	mMonitorWrite = aMonitorWrite;
}

- (void) setupDevice: (short) aPrimaryAddress secondaryAddress: (short) aSecondaryAddress
    //--------------------------------------------------------------------------------
    /*" Sets up communication with the GPIB device. 
    _{#aPrimaryAddress	- The primary address for the GPIB device.}
    _{#aSecondaryAddress - Normally not used.  Set to 0 if not used.}
    "*/
    //--------------------------------------------------------------------------------
{  
    NS_DURING
        // Check device number.
        [theHWLock lock];   //-----begin critical section
        [ self checkDeviceThrow: aPrimaryAddress checkSetup: false ];
        
        mDeviceSecondaryAddress[ aPrimaryAddress ] = aSecondaryAddress;
	    
        // Perform the initialization.
        mDeviceUnit[ aPrimaryAddress ] = ibdev( mBoardIndex, 		// (GPIB0, GPIB1, ... )
                                                aPrimaryAddress, 
                                                aSecondaryAddress,
                                                T3s,   			// Timeout setting (Txs = x secs)
                                                1,			// Assert EOI line at end of write.
                                                0 );			// EOS termination mode.
        
        // Check for an error
        if ( ibsta & ERR ) {
            [ mErrorMsg setString:  @"***Error: ibdev" ];
            [ self GpibError: mErrorMsg ]; 
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        }
        
        // Check that a device is actually present.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Clear the device.
        [ self resetDevice: aPrimaryAddress ];
        [theHWLock unlock];   //-----end critical section
    NS_HANDLER
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    NS_ENDHANDLER
    
}


- (long) readFromDevice: (short) aPrimaryAddress data: (char*) aData maxLength: (long) aMaxLength
    //--------------------------------------------------------------------------------
    /*" Write to a gpib device 
    _{#aPrimaryAddress	- The GPIB primary address of the device.}
    _{#aData			- Pointer to array that can receive data.}
    _{#aMaxLength		- Maximum amount of data that can be returned.  aData must be
    aMaxLength + 1 to contain the "\0". }
    _{#Return - Number of bytes read in.  -1 if read failed.}
    "*/
    //--------------------------------------------------------------------------------
{
    long	nReadBytes = -1;
    
    NS_DURING
        // Make sure that device is initialized.
        [ theHWLock lock ];   //-----begin critical section
        [ self checkDeviceThrow: aPrimaryAddress ];
        
	    //double t0 = [NSDate timeIntervalSinceReferenceDate];
	    //while([NSDate timeIntervalSinceReferenceDate]-t0 < .01);
        
        // Perform the read.
        ibrd( mDeviceUnit[ aPrimaryAddress ], aData, aMaxLength );
        if ( ibsta & ERR ) {
            [ mErrorMsg setString:  @"***Error: ibrd" ];
            [ self GpibError: mErrorMsg ]; 
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        }
        
        // Successful read.
        else
        {
            nReadBytes = ibcntl;
            
            // Allow monitoring of commands.
            if ( mMonitorRead )
            {
                NSMutableDictionary* userInfo = [ NSMutableDictionary dictionary ];			
                NSString* dataStr = [[ NSString alloc ] initWithBytes: aData length: nReadBytes encoding: NSASCIIStringEncoding ];
                [ userInfo setObject: [ NSString stringWithFormat: @"Read - Address: %d length: %d data: %@\n", 
                    aPrimaryAddress, nReadBytes, dataStr ] 
                              forKey: ORGpibMonitor ]; 
                
                [[ NSNotificationCenter defaultCenter ]
				postNotificationName: ORGpibMonitorNotification
			                  object: self
					        userInfo: userInfo ];
                [ dataStr release ];
            }
            
        }
        [ theHWLock unlock ];   //-----end critical section
    NS_HANDLER
        [ theHWLock unlock ];   //-----end critical section
        [ localException raise ];
    NS_ENDHANDLER
    
    return( nReadBytes );
}



//--------------------------------------------------------------------------------
/*! \method		writeToDevice
*  \brief		Writes single command line to GPIB device.
*  \param		aPrimaryAddress			- The primary address of the device.
*	\param		aCommand				- The command string to write.
*	\note		Commands that can be written will depend on each GPIB device.
*/
//--------------------------------------------------------------------------------
- (void) writeToDevice: (short) aPrimaryAddress command: (NSString*) aCommand
{
    NS_DURING
        [ theHWLock lock ];   //-----begin critical section
                              // Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Allow monitoring of commands.
        if ( mMonitorWrite )
        {
            NSMutableDictionary* userInfo = [ NSMutableDictionary dictionary ];
            [ userInfo setObject: [ NSString stringWithFormat: @"Write - Address: %d Comm: %s\n", aPrimaryAddress, [ aCommand cString ]] 
                          forKey: ORGpibMonitor ]; 
            
            [[ NSNotificationCenter defaultCenter ]
		    postNotificationName: ORGpibMonitorNotification
			              object: self
					    userInfo: userInfo ];
        }
        
        //	printf( "Command %s\n", [ aCommand cString ] );
        
        // Write to device.
        ibwrt( mDeviceUnit[ aPrimaryAddress ], (char *)[ aCommand cString ], [ aCommand length ] );
        if ( ibsta & ERR ) {
            [ mErrorMsg setString:  @"***Error: ibwrt" ];
            [ self GpibError: mErrorMsg ]; 
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        }  
        [ theHWLock unlock ];   //-----end critical section
    NS_HANDLER
        [ theHWLock unlock ];   //-----end critical section
        [ localException raise ];
    NS_ENDHANDLER  
}


- (long) writeReadDevice: (short) aPrimaryAddress command: (NSString*) aCommand data: (char*) aData
               maxLength: (long) aMaxLength
    //--------------------------------------------------------------------------------
    /*" Write to gpib device and then read results
    _{#aPrimaryAddress	- The GPIB primary address of the device.}
    _{#aCommand			- The command to write to the device.}
    _{#aData			- Pointer to array that can receive data.}
    _{#aMaxLength		- Maximum amount of data that can be returned.  aData must be
    aMaxLength + 1 to contain the "\0". }
    _{#Return - Number of bytes read in.  -1 if read failed.}
    "*/
    //--------------------------------------------------------------------------------
{
    long retVal = 0;
    NS_DURING
        
        [theHWLock lock];   //-----begin critical section
        [ self writeToDevice: aPrimaryAddress command: aCommand ];
        retVal = [ self readFromDevice: aPrimaryAddress data: aData maxLength: aMaxLength ];
        
        [theHWLock unlock];   //-----end critical section
    NS_HANDLER
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    NS_ENDHANDLER
    
    return( retVal );
}

- (void) wait: (short) aPrimaryAddress mask: (short) aWaitMask
    //--------------------------------------------------------------------------------
    /*" Set the address for the GPIB device.  Send notification of change. 
    _{#aPrimaryAddress	- The GPIB primary address of the device.}
    _{#aWaitMask		- The following bits can be set for device:
        TIMO - Wait for time out
        END - Wait for END or EOS
        RQS - Device requested service
        CMPL - I/O is completed.  
        "*/
    //--------------------------------------------------------------------------------
{
    NS_DURING
        [theHWLock lock];   //-----begin critical section
                            // Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Wait for specified events.
        ibwait( mDeviceUnit[ aPrimaryAddress ], aWaitMask );
        if ( ibsta & ERR ) {
            [ mErrorMsg setString:  @"***Error: ibwait" ];
            [ self GpibError: mErrorMsg ]; 
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        }
        [theHWLock unlock];   //-----end critical section
    NS_HANDLER
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    NS_ENDHANDLER
    
}


#pragma mark ***Support Methods
- (NSString*) boardNames: (short) anIndex
{
    if ( anIndex > -1 && anIndex < kNumBoards )
        return mBoardNames[ anIndex ];
    
    return( mBoardNames[ 0 ] );
}


//--------------------------------------------------------------------------------
/*! \method		checkDeviceThrow
*  \brief		Checks if device address is valid and whether it really is present.
*  \param		aPrimaryAddress			- The primary address of the device.
*	\error		Throws error if check fails.
*	\note		
*/
//--------------------------------------------------------------------------------
- (void) checkDeviceThrow: (short) aPrimaryAddress
{
    [ self checkDeviceThrow: aPrimaryAddress checkSetup: true ];
}


//--------------------------------------------------------------------------------
/*! \method		checkDeviceThrow
*  \brief		Checks if device address is valid and optionally whether it
*				has been initialized.
*  \param		aPrimaryAddress			- The primary address of the device.
*	\param		aState					- True - Check if device is initialized.
*	\error		Throws error if check fails.
*	\note		
*/
//--------------------------------------------------------------------------------
- (void) checkDeviceThrow: (short) aPrimaryAddress checkSetup: (BOOL) aState
{
    NS_DURING
        [theHWLock lock];   //-----begin critical section
        if ( aPrimaryAddress < 0 || aPrimaryAddress > kMaxGpibAddresses ){
            [ mErrorMsg setString: [ NSString stringWithFormat: @"***Error: Bad GPIB Address %d\n", aPrimaryAddress ]];
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        }
        else if ( aState ){
            if ( mDeviceUnit[ aPrimaryAddress ] == kNotInitialized ){
                [ mErrorMsg setString: [ NSString stringWithFormat: 
                                                        @"***Error: Device at address %d not found.\n", aPrimaryAddress ]];
                [ NSException raise: OExceptionGpibError format: mErrorMsg ];
            }
            
            // Now test if device is actually present.
            else {
                short		listen;
                
                ibln( mDeviceUnit[ aPrimaryAddress ], aPrimaryAddress, 
                      mDeviceSecondaryAddress[ aPrimaryAddress ], &listen );
                
                // Deviced is not present so throw error.
                if ( !listen ) {
                    [ mErrorMsg setString: [ NSString stringWithFormat:
                                                            @"***Error: No device present at address %d\n", aPrimaryAddress ]];
                    [ NSException raise: OExceptionGpibError format: mErrorMsg ];
                }
            }
        }
        [theHWLock unlock];   //-----end critical section
    NS_HANDLER
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    NS_ENDHANDLER
    
}


//--------------------------------------------------------------------------------
/*!\method  getGpibController 
* \brief	Called by objects looking for a gpib controller
* \return	self
* \note	
*/
//--------------------------------------------------------------------------------
- (id) getGpibController
{
	return self;
}


- (void) GpibError: (NSMutableString*) aMsg
    //--------------------------------------------------------------------------------
    /*" Set the address for the GPIB device.  Send notification of change. 
    _{#aMsg	- Message passed from calling routine as to what initiated the failure.}
-{#Return - The full message about what failed.}
    "*/
    //--------------------------------------------------------------------------------
{
    NS_DURING
        // Handle the master error register and extract error.
        [theHWLock unlock];   //-----end critical section
        [ aMsg appendString: [ NSString stringWithFormat:  @" ibsta = 0x%x < ", ibsta ]];
        
        NSMutableString *errorType = [[ NSMutableString alloc ] initWithFormat: @"" ];
        
        if (ibsta & ERR )  [ errorType appendString: @" ERR " ];
        if (ibsta & TIMO)  [ errorType appendString: @" TIMO " ];
        if (ibsta & END )  [ errorType appendString: @" END " ];
        if (ibsta & SRQI)  [ errorType appendString: @" SRQI " ];
        if (ibsta & RQS )  [ errorType appendString: @" RQS " ];
        if (ibsta & CMPL)  [ errorType appendString: @" CMPL " ];
        if (ibsta & LOK )  [ errorType appendString: @" LOK " ];
        if (ibsta & REM )  [ errorType appendString: @" REM " ];
        if (ibsta & CIC )  [ errorType appendString: @" CIC " ];
        if (ibsta & ATN )  [ errorType appendString: @" ATN " ];
        if (ibsta & TACS)  [ errorType appendString: @" TACS " ];
        if (ibsta & LACS)  [ errorType appendString: @" LACS " ];
        if (ibsta & DTAS)  [ errorType appendString: @" DTAS " ];
        if (ibsta & DCAS)  [ errorType appendString: @" DCAS " ];
        
        [ aMsg appendString: errorType ];
        [ errorType release ];
        
        // Handle the actual error message.  This message expands on what ibsta found.  Only
        // valid if ibsta & ERR is true.
        [ aMsg appendString: [ NSString stringWithFormat: @"\niberr = %d", iberr ]];
        
        NSMutableString *errorMsg = [[ NSMutableString alloc ] initWithFormat: @"" ];
        
        if (iberr == EDVR) [ errorMsg appendString: @" EDVR <DOS Error>\n" ];
        if (iberr == ECIC) [ errorMsg appendString: @" ECIC <Not Controller-In-Charge>\n" ];
        if (iberr == ENOL) [ errorMsg appendString: @" ENOL <No Listener>\n" ];
        if (iberr == EADR) [ errorMsg appendString: @" EADR <Address error>\n" ];
        if (iberr == EARG) [ errorMsg appendString: @" EARG <Invalid argument>\n" ];
        if (iberr == ESAC) [ errorMsg appendString: @" ESAC <Not System Controller>\n" ];
        if (iberr == EABO) [ errorMsg appendString: @" EABO <Operation aborted>\n" ];
        if (iberr == ENEB) [ errorMsg appendString: @" ENEB <No GPIB board>\n" ];
        if (iberr == EOIP) [ errorMsg appendString: @" EOIP <Async I/O in progress>\n" ];
        if (iberr == ECAP) [ errorMsg appendString: @" ECAP <No capability>\n" ];
        if (iberr == EFSO) [ errorMsg appendString: @" EFSO <File system error>\n" ];
        if (iberr == EBUS) [ errorMsg appendString: @" EBUS <Command error>\n" ];
        if (iberr == ESTB) [ errorMsg appendString: @" ESTB <Status byte lost>\n" ];
        if (iberr == ESRQ) [ errorMsg appendString: @" ESRQ <SRQ stuck on>\n" ];
        if (iberr == ETAB) [ errorMsg appendString: @" ETAB <Table Overflow>\n" ];
        
        [ aMsg appendString: errorMsg ];
        //	printf( "4th Message: %s\n", [ mErrorMsg cString ] );
        
        [ errorMsg release ];
        
        [ aMsg appendString: [ NSString stringWithFormat: @"ibcntl = %ld\n", ibcntl ]];
        
        [theHWLock unlock];   //-----end critical section
                              // Call ibonl to take the device and interface offline
                              //    ibonl( Device, 0 );
                              //    ibonl( BoardIndex, 0 );
    NS_HANDLER
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    NS_ENDHANDLER
    
}

#pragma mark ¥¥¥Archival
static NSString	*ORBoardIndex			= @"GPIB-ENET Board Index";

- (id) initWithCoder: (NSCoder*) decoder
{
    self = [ super initWithCoder: decoder ];
    
    [[ self undoManager ] disableUndoRegistration ];
    [ self commonInit ];
    [ self setBoardIndex: [ decoder decodeIntForKey: ORBoardIndex ]];
    
    [[ self undoManager ] enableUndoRegistration ];
    
    return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
    [ super encodeWithCoder: encoder ];
    [ encoder encodeInt: mBoardIndex forKey: ORBoardIndex ];
}


@end

