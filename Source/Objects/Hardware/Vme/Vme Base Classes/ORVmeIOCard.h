//
//  ORVmeIOCard.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files

#import "ORVmeCard.h"

#pragma mark ¥¥¥Definitions
#define	kAccessRemoteIO			0x01
#define	kAccessRemoteRAM		0x02
#define	kAccessRemoteDRAM		0x03


@interface ORVmeIOCard : ORVmeCard {

	@protected
	id	controller; //use to cache the controller for abit more speed. use with care!
    unsigned long 	baseAddress;
    unsigned short  addressModifier;
    unsigned long	exceptionCount;
}

#pragma mark ¥¥¥Accessors
- (void) 			setBaseAddress:(unsigned long) anAddress;
- (unsigned long) 	baseAddress;
- (void)			setAddressModifier:(unsigned short)anAddressModifier;
- (unsigned short)  addressModifier;
- (id)				adapter;
- (unsigned long)   exceptionCount;
- (void)			incExceptionCount;
- (void)			clearExceptionCount;
- (NSRange)			memoryFootprint;
- (BOOL)			memoryConflictsWith:(NSRange)aRange;

@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORVmeIOCardBaseAddressChangedNotification;
extern NSString* ORVmeIOCardExceptionCountChanged;