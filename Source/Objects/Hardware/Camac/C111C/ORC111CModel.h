/*
 *  ORCC32Model.cpp
 *  Orca
 *
 *  Created by Mark Howe on Mon Dec 10, 2007.
 *  Copyright (c) 2007 CENPA, University of Washington. All rights reserved.
 *
 */
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

#pragma mark •••Imported Files
#import "ORCC32Model.h"


// class definition
@interface ORC111CModel : ORCC32Model
{
    NSString* ipAddress;
    BOOL isConnected;
    NSCalendarDate*	timeConnected;
	int				socketfd;

}

#pragma mark •••Initialization
- (NSString*) settingsLock;

#pragma mark •••Accessors
- (NSCalendarDate*) timeConnected;
- (void) setTimeConnected:(NSCalendarDate*)newTimeConnected;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aFlag;
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;

#pragma mark ***Utilities
- (void) connect;

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f
							 data:(unsigned short*) data;

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f;
								
- (unsigned short)  camacLongNAF:(unsigned short) n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
							data:(unsigned long*) data;


- (unsigned short)  camacShortNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned short*) data
                                length:(unsigned long)   numWords;
@end

extern NSString* ORC111CSettingsLock;
extern NSString* ORC111CTimeConnectedChanged;
extern NSString* ORC111CConnectionChanged;	
extern NSString* ORC111CIpAddressChanged;
