//
//  ORICS8065Model.m
//  Orca
//
//  Created by Mark Howe on Friday, June 20, 2008.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#include <stdio.h>
#import "ORICS8065Model.h"

#pragma mark ***Defines
#define k8065CorePort 5555

NSString*	ORICS8065Connection					= @"ICS865OutputConnector";
NSString*	ORICS8065TestLock					= @"ORICS8065TestLock";
NSString*	ORGpib1MonitorNotification			= @"ORGpib1MonitorNotification";
NSString*	ORGpib1Monitor						= @"ORGpib1Monitor";
NSString*	ORGPIB1BoardChangedNotification		= @"ORGPIB1BoardChangedNotification";
NSString*	ORICS8065ModelIsConnectedChanged	= @"ORICS8065ModelIsConnectedChanged";
NSString*	ORICS8065ModelIpAddressChanged		= @"ORICS8065ModelIpAddressChanged";

@implementation ORICS8065Model
#pragma mark ***Initialization
- (void) commonInit
{
    short 	i;
    
	theHWLock = [[NSRecursiveLock alloc] init];    
    
    mErrorMsg = [[ NSMutableString alloc ] initWithFormat: @"" ];
    
    for ( i = 0; i < kMaxGpibAddresses; i++ ){
        memset(&mDeviceLink[i],0,sizeof(Create_LinkResp));
        mDeviceSecondaryAddress[ i ] = 0;
    } 
    
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
	if(rpcClient)clnt_destroy(rpcClient);
    [noDriverAlarm clearAlarm];
    [noDriverAlarm release];
    [noPluginAlarm clearAlarm];
    [noPluginAlarm release];
    [iCS8065Instance release];
    [theHWLock release];
    [ mErrorMsg release ];
    [ super dealloc ];
}

- (NSString*) pluginName
{
    return @"EduWashingtonNplOrcaNi488PlugIn.plugin";
}

- (void) awakeAfterDocumentLoaded
{
	NS_DURING
		[self connect];
		[self connectionChanged];
	NS_HANDLER
	NS_ENDHANDLER
}

//--------------------------------------------------------------------------------
/*! \method		setUpImage
*  \brief		Draws image on screen for this object.
*	\note		
*/
//--------------------------------------------------------------------------------
- (void) setUpImage
{
    NSImage* aCachedImage = [NSImage imageNamed:@"ICS8065Box"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
    
    if(![self isEnabled]){
        NSBezierPath* path = [NSBezierPath bezierPath];
        [path moveToPoint:NSZeroPoint];
        [path lineToPoint:NSMakePoint([self frame].size.width,[self frame].size.height)];
        [path moveToPoint:NSMakePoint([self frame].size.width,0)];
        [path lineToPoint:NSMakePoint(0,[self frame].size.height)];
        [path setLineWidth:2];
        [[NSColor redColor] set];
        [path stroke];
    }
    [i unlockFocus];
    
    [ self setImage:i];
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
	ORConnector* connectorObj = [[ ORConnector alloc ] initAt: NSMakePoint([ self frame ].size.width - kConnectorSize, 20 ) withGuardian: self];
	[ connectorObj setConnectorType: 'GPI2' ];
	[ connectorObj addRestrictedConnectionType: 'GPI1' ]; //can only connect to gpib inputs
	[[ self connectors ] setObject: connectorObj forKey: ORICS8065Connection ];
	[ connectorObj release ];
}

- (void) makeMainController
{
    [self linkToController: @"ORICS8065Controller"];
}


#pragma mark ***Accessors
- (BOOL) isEnabled
{
    return YES;
}

- (CLIENT*) rpcClient
{
	return rpcClient;
}

- (void) setRpcClient:(CLIENT*)anRpcClient
{
	if(rpcClient)clnt_destroy(rpcClient);
	
	rpcClient = anRpcClient;
}

- (void) setIsConnected:(BOOL)aFlag
{
    isConnected = aFlag;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORICS8065ModelIsConnectedChanged object:self];
}

- (NSString*) ipAddress
{
    return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
	if(!aIpAddress)aIpAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
    
    [ipAddress autorelease];
    ipAddress = [aIpAddress copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORICS8065ModelIpAddressChanged object:self];
}


- (void) connect
{
	if(!isConnected){
		CLIENT* aClient = clnt_create((char*)[ipAddress cStringUsingEncoding:NSASCIIStringEncoding],DEVICE_CORE,DEVICE_CORE_VERSION, "TCP");
		[self setRpcClient:aClient];	
        [self setIsConnected: aClient!=nil];
	}
	else {
		[self setRpcClient:nil];	
        [self setIsConnected:rpcClient!=nil ];
	}
}

- (BOOL) isConnected
{
	return isConnected;
}


- (NSMutableString*) errorMsg
{
    return( mErrorMsg );
}

#pragma mark ***gpib Methods
- (int) ibsta
{
    if ( [ self isEnabled ]) {
        return( [iCS8065Instance ibsta] );
    }
    return 0;
}

- (int) iberr
{
    if ( [ self isEnabled ]) {
        return( [iCS8065Instance iberr] );
    }
    return 0;
}

- (long) ibcntl
{
    if ( [ self isEnabled ]) {
        return( [iCS8065Instance ibcntl] );
    }
    return 0;
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
    if ( ! [ self isEnabled ]) return;
    NS_DURING
        [theHWLock lock];   //-----begin critical section
        [ self checkDeviceThrow: anOldPrimaryAddress ];
        [ self checkDeviceThrow: aNewPrimaryAddress checkSetup: false ];
		
		memcpy(&mDeviceLink[aNewPrimaryAddress],&mDeviceLink[anOldPrimaryAddress],sizeof(Create_LinkResp));
		memset(&mDeviceLink[anOldPrimaryAddress],0,sizeof(Create_LinkResp));
        
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
/*    if ( ! [ self isEnabled ]) return;
    NS_DURING
        [theHWLock lock];   //-----begin critical section
        short deviceState = 0;
        
        // Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Change device state.
        if ( aState ) deviceState = 1;
        [iCS8065Instance ibonl:mDeviceLink[ aPrimaryAddress ] v:deviceState];
        if ([iCS8065Instance ibsta] & [iCS8065Instance err] ) {
            [ mErrorMsg setString:  @"***Error: ibonl" ];
            [ self GpibError: mErrorMsg ];
            
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        }
        [theHWLock unlock];   //-----end critical section
    NS_HANDLER
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    NS_ENDHANDLER
*/
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
    if ( ! [ self isEnabled ]) return bRetVal;
    NS_DURING
        [theHWLock lock];   //-----begin critical section
        
        // Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress checkSetup: false ];
        
        // Check if device has been setup.
        if ( mDeviceLink[aPrimaryAddress].lid != 0 ){
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
    if ( ! [ self isEnabled ]) return;
    NS_DURING
        [ theHWLock lock ];   //-----begin critical section
                              // Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Deactivate the device
		destroy_link_1(&mDeviceLink[aPrimaryAddress].lid,rpcClient);
       
		 if ( 0){
            [ mErrorMsg setString: @"***Error: deactivate" ];
            [ self gpibError: mErrorMsg number:-1];
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
/*    if ( ! [ self isEnabled ]) return;
    // Make sure that device is initialized.
    NS_DURING
        [ theHWLock lock ];   //-----begin critical section
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        [iCS8065Instance ibeot:mDeviceLink[ aPrimaryAddress ] v:state];
        if ( (int)[iCS8065Instance ibsta] & (unsigned short)[iCS8065Instance err] ){
            [ mErrorMsg setString: [NSString stringWithFormat:@"***Error: ibeot (%d)",state] ];
            [ self GpibError: mErrorMsg ];
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        } 
        [ theHWLock unlock ];   //-----end critical section
    NS_HANDLER
        [ theHWLock unlock ];   //-----end critical section
        [ localException raise ];
    NS_ENDHANDLER
   */ 
}



- (void) resetDevice: (short) aPrimaryAddress
    //--------------------------------------------------------------------------------
    /*" Reset the device to start receiving data.
    _{#aPrimaryAddress	- The primary address for the GPIB device.}
    "*/
    //--------------------------------------------------------------------------------
{
/*
    if ( ! [ self isEnabled ]) return;
    NS_DURING
        [theHWLock lock];   //-----begin critical section
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Clear device.
        [iCS8065Instance ibclr:mDeviceLink[ aPrimaryAddress ]];
        if ( [iCS8065Instance ibsta] & [iCS8065Instance err] ) {
            [ mErrorMsg setString: @"***Error: ibclr" ];
            [ self GpibError: mErrorMsg ];
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        }
        [ theHWLock unlock ];   //-----end critical section
    NS_HANDLER
        [ theHWLock unlock ];   //-----end critical section
        [ localException raise ];
    NS_ENDHANDLER
*/
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
    if ( ! [ self isEnabled ]) return;
    NS_DURING
        // Check device number.
        [theHWLock lock];   //-----begin critical section
       // [ self checkDeviceThrow: aPrimaryAddress checkSetup: false ];
        
        mDeviceSecondaryAddress[ aPrimaryAddress ] = aSecondaryAddress;

		Create_LinkParms crlp;
		crlp.clientId = (long)rpcClient;
		crlp.lockDevice = 0;
		crlp.lock_timeout = 3000;
		char device[64];
		sprintf(device,"gpib0,%d",aPrimaryAddress);
		crlp.device = device;
		memcpy(&mDeviceLink[aPrimaryAddress], create_link_1(&crlp, rpcClient),sizeof(Create_LinkResp));
	            
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

    if ( ! [ self isEnabled ]) return -1;
    long	nReadBytes = -1;
    
    NS_DURING
        // Make sure that device is initialized.
        [ theHWLock lock ];   //-----begin critical section
        [ self checkDeviceThrow: aPrimaryAddress ];
        
	    //double t0 = [NSDate timeIntervalSinceReferenceDate];
	    //while([NSDate timeIntervalSinceReferenceDate]-t0 < .01);
        
        // Perform the read.				
		Device_ReadParms  dwrp; 
		Device_ReadResp*  dwrr; 
		dwrp.lid = mDeviceLink[aPrimaryAddress].lid; 
		dwrp.requestSize = aMaxLength;
		dwrp.io_timeout = 3000; 
		dwrp.lock_timeout = 3000;
		dwrp.flags = 0;
		dwrp.termChar = '\n';
		dwrr = device_read_1(&dwrp, rpcClient); 
		
		//To do: There has to be some serious error checking put in here, asap.....
		memcpy(aData,dwrr->data.data_val,dwrr->data.data_len);
        if (dwrr->error != 0) {
            [ mErrorMsg setString:  @"***Error: read" ];
            [ self gpibError: mErrorMsg number:dwrr->error]; 
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        }
        
        // Successful read.
        else {
            nReadBytes = dwrr->data.data_len;
			aData[nReadBytes] = '\0';
          
            // Allow monitoring of commands.
            if ( mMonitorRead ) {
                NSMutableDictionary* userInfo = [ NSMutableDictionary dictionary ];	
                NSString* dataStr = [[ NSString alloc ] initWithBytes: aData length: nReadBytes encoding: NSASCIIStringEncoding ];
                [ userInfo setObject: [ NSString stringWithFormat: @"Read - Address: %d length: %d data: %@\n", 
                    aPrimaryAddress, nReadBytes, dataStr ] 
                              forKey: ORGpib1Monitor ]; 
                
                [[ NSNotificationCenter defaultCenter ]
				postNotificationName: ORGpib1MonitorNotification
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

    return( 0 );
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
    if ( ! [ self isEnabled ]) return;
    NS_DURING
        [ theHWLock lock ];   //-----begin critical section
                              // Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Allow monitoring of commands.
        if ( mMonitorWrite ) {
            NSMutableDictionary* userInfo = [ NSMutableDictionary dictionary ];
            [ userInfo setObject: [ NSString stringWithFormat: @"Write - Address: %d Comm: %s\n", aPrimaryAddress, [ aCommand cStringUsingEncoding:NSASCIIStringEncoding ]] 
                          forKey: ORGpib1Monitor ]; 
            
            [[ NSNotificationCenter defaultCenter ]
		    postNotificationName: ORGpib1MonitorNotification
			              object: self
					    userInfo: userInfo ];
        }
        
        //	printf( "Command %s\n", [ aCommand cString ] );
        
        // Write to device.
				
		Device_WriteParms  dwrp; 
		Device_WriteResp*  dwrr; 
		dwrp.lid = mDeviceLink[aPrimaryAddress].lid; 
		dwrp.io_timeout = 3000; 
		dwrp.lock_timeout = 3000;
		dwrp.flags = 0;
		if(![aCommand hasSuffix:@"\n"])aCommand = [aCommand stringByAppendingString:@"\n"];
		dwrp.data.data_len = [aCommand length];
		dwrp.data.data_val = (char *)[ aCommand cStringUsingEncoding:NSASCIIStringEncoding ];
		dwrr = device_write_1(&dwrp, rpcClient); 
		
        if (dwrr &&  dwrr->error != 0 ) {
            [ mErrorMsg setString:  @"***Error: write" ];
            [ self gpibError: mErrorMsg number: dwrr->error]; 
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
    if ( ! [ self isEnabled ]) return -1;
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
/*    if ( ! [ self isEnabled ]) return;
    NS_DURING
        [theHWLock lock];   //-----begin critical section
                            // Make sure that device is initialized.
        [ self checkDeviceThrow: aPrimaryAddress ];
        
        // Wait for specified events.
        [ iCS8065Instance ibwait:mDeviceLink[ aPrimaryAddress ] mask:aWaitMask ];
        if ( [ iCS8065Instance ibsta ] & [ iCS8065Instance err ] ) {
            [ mErrorMsg setString:  @"***Error: ibwait" ];
            [ self GpibError: mErrorMsg ]; 
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        }
        [theHWLock unlock];   //-----end critical section
    NS_HANDLER
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    NS_ENDHANDLER
*/
}


#pragma mark ***Support Methods
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
    if ( ! [ self isEnabled ]) return;
    NS_DURING
        [theHWLock lock];   //-----begin critical section
        if ( aPrimaryAddress < 0 || aPrimaryAddress > kMaxGpibAddresses ){
            [ mErrorMsg setString: [ NSString stringWithFormat: @"***Error: Bad GPIB Address %d\n", aPrimaryAddress ]];
            [ NSException raise: OExceptionGpibError format: mErrorMsg ];
        }
        else if ( aState ){
            if ( mDeviceLink[ aPrimaryAddress ].lid == 0 ){
                [ mErrorMsg setString: [ NSString stringWithFormat: 
                                                        @"***Error: Device at address %d not found.\n", aPrimaryAddress ]];
                [ NSException raise: OExceptionGpibError format: mErrorMsg ];
            }
            
            // Now test if device is actually present.
            else {
                short		listen = 1;
                
                //[ iCS8065Instance ibln:mDeviceLink[ aPrimaryAddress ] 
                  //      pad:aPrimaryAddress 
                    //    sad:mDeviceSecondaryAddress[ aPrimaryAddress ] 
                      //  listen:&listen ];
                
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


- (void) gpibError: (NSMutableString*) aMsg number:(int)anErrorNum
    //--------------------------------------------------------------------------------
    /*" Set the address for the GPIB device.  Send notification of change. 
    _{#aMsg	- Message passed from calling routine as to what initiated the failure.}
-{#Return - The full message about what failed.}
    "*/
    //--------------------------------------------------------------------------------
{
    if ( ! [ self isEnabled ]) return;
    NS_DURING
        // Handle the master error register and extract error.
        [theHWLock unlock];   //-----end critical section
        [ aMsg appendString: [ NSString stringWithFormat:  @" e = %d < ", anErrorNum ]];
        
        NSMutableString *errorType = [[ NSMutableString alloc ] initWithFormat: @"" ];
        
        if (anErrorNum == 4 )  [ errorType appendString: @" invalid link identifier " ];
        else if (anErrorNum == 11 )  [ errorType appendString: @" device locked by another link " ];
        else if (anErrorNum == 15 )  [ errorType appendString: @" I/O timeout " ];
        else if (anErrorNum == 17 )  [ errorType appendString: @" I/O error " ];
        else if (anErrorNum == 23 )  [ errorType appendString: @" abort " ];
        
        [ aMsg appendString: errorType ];
        [ errorType release ];
        
		
        [theHWLock unlock];   //-----end critical section
                              // Call ibonl to take the device and interface offline
                              //    ibonl( Device, 0 );
                              //    ibonl( BoardIndex, 0 );
    NS_HANDLER
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    NS_ENDHANDLER
    
}

#pragma mark •••Archival
- (id) initWithCoder: (NSCoder*) decoder
{
    self = [ super initWithCoder: decoder ];
    
    [[ self undoManager ] disableUndoRegistration ];
    [ self commonInit ];
 	[self setIpAddress:		[decoder decodeObjectForKey:@"ipAddress"]];
   
    [[ self undoManager ] enableUndoRegistration ];
    
    return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
    [ super encodeWithCoder: encoder ];
	    [encoder encodeObject:ipAddress	forKey: @"ipAddress"];

}


@end

